# **StyleStack — CLAUDE.md**

This file is the working brain for Claude Code on this project. Read it fully at the start of every session before writing any code. Update it when decisions are made or patterns emerge.

---

## **PROJECT CONTEXT**

**What it is:** StyleStack is a mobile app (React Native / Expo) that helps style-forward users discover outfit combinations from clothes they already own. It uses a style graph (not a flat catalog) to model aesthetic preferences and generates suggestions immediately — before the user has uploaded a single item.

**Solo founder:** Curro Casas. Ex-Amazon (Alexa). Based in Spain. \~25hrs/week. Claude Code is the primary engineering tool.

**Co-founder / alpha user:** Shireen Husain. Style \+ feedback. First real user. Her experience is the primary quality signal during validation.

**Current phase:** Pre-build validation \+ Week 1 prototype sprint. Do not build beyond Phase 1 scope until kill conditions are checked.

⚠️ **NAME STATUS:** "StyleStack" is taken on the App Store (id6759152550) and the domain is unavailable. The app name is under review. All references to "StyleStack" in bundle IDs, app.json, and store metadata are placeholders. Do not hardcode the name in user-facing strings — use a config constant (`APP_NAME` in `lib/config.ts`) so renaming requires a single change. Bundle ID placeholder: `com.placeholder.app`.

---

## **THE CORE ARCHITECTURAL BET**

**Old assumption (wrong):** Build catalog first → suggestions follow. **Current assumption:** Deliver suggestions first → catalog builds as a side effect of engagement.

Day 1 value comes from 8 outfit card swipes that seed the style graph with aesthetic priors. Suggestions run immediately against a curated generic catalog. The user's actual closet populates progressively through multiple low-friction layers over 30 days. Value is front-loaded. Data collection is back-loaded.

This is not negotiable. Do not build any flow that requires a populated catalog before showing a suggestion.

---

## **TECH STACK (decided — do not change without logging a decision)**

- **Framework:** React Native with Expo SDK 52+  
- **Language:** TypeScript (strict mode)  
- **State:** Zustand  
- **Backend/DB:** Supabase (Postgres \+ Auth \+ Storage)  
- **Navigation:** Expo Router (file-based)  
- **Image:** expo-image-picker \+ expo-image-manipulator  
- **Vision API:** Anthropic Claude Haiku (clothing attribute extraction)  
- **Background removal:** Photoroom API (fallback: Bria AI)  
- **Vector search:** Supabase pgvector extension (no separate vector DB)  
- **Analytics:** PostHog (cloud, free tier). All product events fire here. Required from Day 1 — kill conditions are unmeasurable without it.  
- **Crash reporting:** Sentry (React Native SDK). Required from Day 1\.  
- **API security layer:** Supabase Edge Functions. ALL calls to Anthropic and Photoroom are proxied through Edge Functions. Never call paid APIs directly from the mobile client. Keys live only in Edge Function environment variables.  
- **Weather:** OpenWeatherMap API — DEFERRED to Phase 4\. Do not implement until Phase 3 gates pass.

---

## **DATA SCHEMA (Supabase — implement exactly as specified)**

\-- Core items table

CREATE TABLE items (

  id UUID PRIMARY KEY DEFAULT gen\_random\_uuid(),

  user\_id UUID REFERENCES auth.users(id),

  source TEXT, \-- 'photo\_picker' | 'daily\_loop' | 'link\_paste' | 'email\_receipt' | 'generic\_catalog'

  is\_generic BOOLEAN DEFAULT false, \-- true \= from curated generic catalog, not user's real item

  image\_url TEXT,

  product\_url TEXT,

  brand TEXT,

  name TEXT,

  price DECIMAL,

  purchase\_date DATE,

  created\_at TIMESTAMPTZ DEFAULT now()

);

\-- Attribute nodes with confidence scores

CREATE TABLE item\_attributes (

  id UUID PRIMARY KEY DEFAULT gen\_random\_uuid(),

  item\_id UUID REFERENCES items(id),

  attribute\_type TEXT, \-- 'color' | 'category' | 'style' | 'occasion' | 'material' | 'silhouette'

  value TEXT,

  confidence\_score DECIMAL, \-- 0.0–1.0. Below 0.6 \= show correction prompt

  source TEXT \-- 'vision\_api' | 'receipt\_parse' | 'user\_corrected' | 'manual'

);

\-- Style graph: user aesthetic scores (seeded by swipe onboarding, updated by behavior)

CREATE TABLE user\_aesthetic\_scores (

  id UUID PRIMARY KEY DEFAULT gen\_random\_uuid(),

  user\_id UUID REFERENCES auth.users(id),

  aesthetic\_label TEXT, \-- 'minimal' | 'streetwear' | 'classic' | 'business' | 'sporty' | 'trendy'

  score DECIMAL, \-- 0.0–1.0

  updated\_at TIMESTAMPTZ DEFAULT now()

);

\-- Generated outfits (must be defined before behavioral\_events)

CREATE TABLE outfits (

  id UUID PRIMARY KEY DEFAULT gen\_random\_uuid(),

  user\_id UUID REFERENCES auth.users(id),

  item\_ids UUID\[\], \-- array of item IDs in this combination

  generation\_method TEXT, \-- 'rules\_based' | 'vector\_similarity'

  occasion TEXT,

  created\_at TIMESTAMPTZ DEFAULT now()

);

\-- Behavioral events: every interaction that updates the graph

CREATE TABLE behavioral\_events (

  id UUID PRIMARY KEY DEFAULT gen\_random\_uuid(),

  user\_id UUID REFERENCES auth.users(id),

  event\_type TEXT, \-- 'outfit\_thumbs\_up' | 'outfit\_thumbs\_down' | 'item\_worn' | 'swipe\_keep' | 'swipe\_skip'

  item\_id UUID REFERENCES items(id),

  outfit\_id UUID REFERENCES outfits(id),

  metadata JSONB,

  created\_at TIMESTAMPTZ DEFAULT now()

);

\-- Wear log (from daily loop)

CREATE TABLE wear\_log (

  id UUID PRIMARY KEY DEFAULT gen\_random\_uuid(),

  user\_id UUID REFERENCES auth.users(id),

  outfit\_id UUID REFERENCES outfits(id),

  worn\_date DATE,

  photo\_url TEXT,

  created\_at TIMESTAMPTZ DEFAULT now()

);

**Schema rules:**

- Never flatten the graph into a single items table with attribute columns. Always use item\_attributes with confidence scores.  
- is\_generic flag is critical. Generic catalog items must never appear in "my wardrobe" view. They are suggestion fill only.  
- behavioral\_events is the most important table. Every user action that signals preference must write here. It drives graph weight updates.

---

## **BUILD SEQUENCE (strict — do not skip phases)**

### **Phase 0 — Context foundation (Week 1, do first)**

- [ ] F02: Supabase schema (tables above, exactly)  
- [ ] F-NEW3: Generic catalog seed (200 items, see spec below)  
- [ ] F00: Swipe onboarding (8 cards → seeds user\_aesthetic\_scores)

**Gate to Phase 1:** Shireen can complete swipe onboarding and see 1 outfit suggestion. No catalog required.

### **Phase 1 — Core loop (Weeks 2–3)**

- [ ] F05: Rules-based outfit matcher (color harmony \+ occasion \+ style coherence)  
- [ ] F04: Outfit suggestion card UI (flat-lay, real images, thumbs up/down)  
- [ ] F07: Behavioral feedback loop (thumbs → behavioral\_events → graph weights)  
- [ ] F-NEW1: Photo picker bootstrapping (iOS selective picker → Vision API)  
- [ ] F13: Value ladder progress bar (item count vs unlock thresholds)

**Gate to Phase 2:** Shireen rates ≥60% of Day 1 suggestions as "would wear." Kill 1 checked.

### **Phase 2 — Daily habit (Week 3–4)**

- [ ] F-NEW2: Daily wear loop ("What are you wearing today?" prompt \+ wear logging)  
- [ ] F-NEW4: Shopping link paste (URL → scrape → add to catalog)  
- [ ] F10: Confidence score display \+ one-tap correction flow  
- [ ] F18: Trend layer (manual curation, 3–5 trends/week)

**Gate to Phase 3:** ≥40% Day 3 return rate. Kill 2 checked.

### **Phase 3 — Transparency \+ retention (Weeks 5–6)**

- [ ] F11: "Why this?" explanation (Claude Haiku on demand)  
- [ ] F12: Visible style profile (radar chart, editable)  
- [ ] F14: Wardrobe utilization stat (requires 30 days of wear data)  
- [ ] F16: Weekly in-app changelog card

### **Phase 4+ — Deferred (do not build until Phase 2 gates pass)**

- F08: Email receipt pipeline (only after warm consent test \>50%)  
- F09: Amazon order history parsing (same gate as F08)  
- F17: Wardrobe gap analysis  
- F19: Style goals / intentional layer  
- F20: Graph API service layer

---

## **GENERIC CATALOG SPEC (F-NEW3)**

200 items across 5 style archetypes × 4 occasions × top 10 item types.

**Style archetypes:** minimal, streetwear, classic, business, sporty **Occasions:** casual, work, evening, weekend **Item types:** tee, shirt, trousers, jeans, blazer, dress, skirt, sneakers, boots, outerwear

**Rules for generic catalog items:**

- `is_generic = true` always  
- Real product images required. Source ONLY from: Unsplash fashion (permissive license), Pexels (permissive license), or original photography by Shireen. Do NOT use retailer product imagery (ASOS, Zara, H\&M, etc.) — this violates retailer ToS and will cause App Store rejection. If image sourcing is insufficient from free sources, commission 20–30 original flat-lay photos from Shireen.  
- Attribute confidence\_score \= 1.0 (manually curated, perfectly tagged)  
- Must cover neutral colorways (white, black, navy, grey, beige) as the backbone  
- 20% accent colors (olive, burgundy, camel, terracotta)  
- Generic items phase out of suggestions as user's real catalog grows (suppress is\_generic items once user has \>10 real items in same category/occasion)

---

## **OUTFIT MATCHER RULES (rules-based MVP — F05)**

Generate combinations of 3–4 items. Apply in order:

1. **Color harmony:** Max 3 colors per outfit. Neutrals (white/black/grey/beige/navy) \+ 1 accent. No 2 pattern pieces together.  
2. **Occasion coherence:** All items must share at least one occasion tag.  
3. **Silhouette balance:** If top is oversized, bottom must be slim/regular (and vice versa).  
4. **Variety enforcement:** Never suggest the same combination twice in a 7-day window per user.  
5. **Graph weighting:** Prioritize items with attributes matching user's top 2 aesthetic\_scores. Down-weight items from outfits that received thumbs\_down in last 30 days.  
6. **Generic fill:** If user has \<10 real items in a category, fill with is\_generic items. Log fill ratio per suggestion.

**Suggestion card format:** Flat-lay. 3–4 items arranged horizontally. Each item shows: image, name (short), confidence badge if \<0.8. Thumbs up / thumbs down inline. No avatar. No model.

---

## **KILL CONDITIONS (check before proceeding to next phase)**

| \# | Condition | Threshold | Action if fired |
| :---- | :---- | :---- | :---- |
| K1 | Day 1 suggestion quality | \<60% of 5 beta users rate ≥1 suggestion "would wear" | STOP. Redesign matcher before any other work. |
| K2 | Day 3 return rate | \<40% of onboarded users return Day 3 | STOP. Redesign daily loop trigger before scaling. |
| K3 | Onboarding completion | \>40% drop before completing 8 swipes | FIX onboarding before adding any feature. |
| K4 | Photo picker conversion | \<30% of users add ≥5 items via photo picker | Investigate UX \+ prompting. Don't invest in email pipeline yet. |
| K5 | Warm email consent | \<50% of engaged users consent post-value | Email pipeline is secondary. Rely on photo \+ daily loop stack. |

Do not build Phase 2+ features if K1 or K3 fires. Fix first.

---

## **WHAT NOT TO BUILD (ever, until explicitly unlocked)**

- Cold Gmail OAuth ask at onboarding — trust not established, grant rate \<25%  
- Manual text entry for item attributes — proven drop-off cause  
- Item-by-item single photo upload as primary method — competitor research confirms adoption killer  
- AR try-on / virtual model — not core to combination value  
- Kids wardrobe — no signal, complicates ICP  
- Automated trend sourcing — manual curation sufficient at MVP scale  
- Social/Instagram scraping — API restrictions, post-MVP only

An unlock happens only if: a kill condition fires and this feature is the fix, OR a beta user requests it in 3+ independent sessions using the same language.

---

## **KNOWLEDGE ARCHITECTURE**

Huryn pattern: observations start as hypotheses. Confirmed across 2+ sessions → promote to rule. Contradicted → demote.

**Source of truth for architectural decisions is the DECISION JOURNAL below.** The confirmed rules here are behavioral rules for Claude Code only (how to write code), not product or architecture decisions.

### **Confirmed rules (do not re-debate)**

- Photo library access grant rate is significantly higher than Gmail OAuth (estimated 60–75% vs 15–25% cold). Design all bootstrapping to use photo picker before email.  
- Suggestion quality must work before catalog completeness. The graph seeds from swipes, not items.  
- Warm consent (post-value) yields 2–3x higher OAuth grant rates than cold consent. Never ask for Gmail access at onboarding.  
- No competitor has solved zero-friction catalog bootstrapping. This is the moat.  
- React Native (Expo) chosen over Flutter. Do not revisit unless performance ceiling hit post-MVP.  
- Supabase chosen over Firebase. Do not revisit.

### **Active hypotheses (testing)**

- H1: 8 swipe cards is enough to generate a useful aesthetic prior (testing in Week 1\)  
- H2: Photo picker will convert \>50% of onboarded users to add ≥1 photo (testing Week 2\)  
- H3: Daily "what are you wearing today?" becomes a genuine habit at \>40% Day 3 rate (testing Week 3\)  
- H4: Generic catalog items are acceptable suggestion fill until 10+ real items per category

### **Knowledge files**

Append session learnings here: `.claude/memory.md` Format: `YYYY-MM-DD: [what] — [why it matters]`

---

## **DECISION JOURNAL**

Huryn pattern: before any significant decision, search here first. If prior decision exists, follow its reasoning unless new data invalidates it. If new decision, log it immediately.

| Date | Decision | Alternatives considered | Why this won | Trade-offs accepted |
| :---- | :---- | :---- | :---- | :---- |
| 2026-05-19 | React Native (Expo) over Flutter | Flutter performance ceiling higher | JS/TS \= best Claude Code support. Expo \= fastest prototype. Solo founder context. | Potential RN performance ceiling post-MVP if animation-heavy |
| 2026-05-19 | Supabase over Firebase | Firebase mature, wider adoption | Postgres \+ pgvector in one service. pgvector enables similarity search without separate infra. | Firebase has better real-time sync primitives |
| 2026-05-27 | Style graph over flat catalog | Flat catalog simpler to build | Graph enables aesthetic inference, confidence scoring, and preference learning that flat catalog cannot | Higher schema complexity upfront |
| 2026-05-28 | Suggestions-first over catalog-first onboarding | Catalog-first feels more "complete" | Competitor research: catalog-first \= adoption killer. Value must come before effort. | Day 1 suggestions use generic catalog — lower personalization until real items added |
| 2026-05-28 | Photo picker over Gmail OAuth as primary bootstrapping | Gmail covers more historical data | Photo grant rate 60–75% vs Gmail 15–25% cold. User has existing outfit photos. Less trust required. | Less historical data coverage vs email receipts |
| 2026-05-28 | Manual trend curation over algorithmic | Algorithmic would scale better | Manual sufficient at \<1K users. Algorithmic sourcing introduces cost \+ noise at MVP scale. | Curro \+ Shireen must curate weekly. Bottleneck at scale. |
| 2026-05-29 | LLC formation before public launch | Sole proprietor | Liability separation. Enables Apple Developer org enrollment. Required for entity-level bank account and contractor payments. | $50–500 formation cost \+ annual state fees. |
| 2026-05-29 | US-first launch, EU deferred | Launch in both simultaneously | GDPR compliance cost and complexity not justified at beta scale. Privacy Policy is CCPA-only at v1.0. EU launch triggers GDPR v2 rewrite. | EU ICP excluded until v2 Privacy Policy is live. |
| 2026-05-29 | App name "StyleStack" is unavailable — rename required | Keep name and fight for it | Existing App Store app (id6759152550) blocks submission. Domain (.com, .ai) taken. App Store rejects on name conflict. | Must resolve name before public-facing assets created. TestFlight builds use placeholder. |
| 2026-05-29 | PostHog free tier for analytics (Sheets automation backup) | Amplitude, Mixpanel, Firebase Analytics, custom Supabase \+ Sheets | Free tier covers 1M events/mo (sufficient through 10K MAU). Sheets automation proven at Arquia scale. Self-host option preserves optionality. | No spend at MVP unless free tier exceeded. Sheets automation carries data analysis load. |
| 2026-05-29 | Sentry for crash reporting | Datadog, Bugsnag, custom logging | Best React Native SDK. Source maps upload works cleanly with EAS. Free tier covers beta. Industry standard. | $26/mo if error volume exceeds free tier. Negligible cost. |
| 2026-05-29 | All paid API calls routed via Supabase Edge Functions | Direct API calls from mobile client | Security: API keys never in mobile bundle. Per-user rate limiting. Cost monitoring. Required by Security Baseline. | Additional latency \~50–100ms. Edge Function cold start acceptable for async photo processing. |
| 2026-05-29 | Gmail CASA assessment deferred until F08 is production-ready | Start CASA Week 1 | F08 is Phase 2+. 100-user cap without CASA acceptable through entire beta. Start CASA when warm consent (K5) passes. Email forwarding workaround: legal review needed before investing in user guide. | F08 cannot exceed 100 Gmail users without CASA. ~~6 week lead time. Legal review cost same as CASA decision (~~$300–500). |
| 2026-05-29 | OpenWeatherMap deferred to Phase 4 | Build in Phase 1 | Weather suggestions require wear log data (F-NEW2). Wear log populates Phase 2+. Feature valueless without retention data. Cost negligible — timing is issue. | Weather removed from MVP scope. Phase 3 gates must pass first. |
| 2026-05-29 | Generic catalog images: Unsplash/Pexels/original only | Retailer product imagery | Retailer imagery violates ToS and causes App Store rejection. Unsplash/Pexels permissive. Shireen can photograph 20–30 pieces if free sources insufficient. | Upfront work sourcing images. Generic items phase out as real catalog grows. |

---

## **QUALITY GATES**

Huryn pattern: concrete, testable criteria. Not "be thorough." Frequent triggers get promoted to automatic checks. Never-triggered criteria get pruned.

Before marking any feature complete:

- [ ] TypeScript strict mode — zero `any` types  
- [ ] Every table insert writes to behavioral\_events if it signals user preference  
- [ ] is\_generic flag is correctly set on all generic catalog items and never shown in "my wardrobe" view  
- [ ] Confidence scores are present on all item\_attributes rows — no nulls  
- [ ] No cold OAuth asks — Gmail/permissions only after value shown  
- [ ] Suggestion variety check: no duplicate outfit combination in 7-day window per user  
- [ ] Kill condition instrumentation — every kill condition has a corresponding metric logged to Supabase before shipping the feature it gates  
- [ ] If new paid API call added: verify it routes through Supabase Edge Function, not direct from client  
- [ ] PostHog event fired for every user action that maps to a kill condition (K1–K5)  
- [ ] No new secret in client bundle — verify with: `npx expo export && grep -r "ANTHROPIC\|PHOTOROOM" dist/`

Before shipping to Shireen:

- [ ] Onboarding completes in \<10 minutes on a real device (time it)  
- [ ] At least 1 outfit suggestion visible within 2 minutes of app open  
- [ ] No crashes on iOS 16+ (Shireen's device)  
- [ ] Generic fill items suppressed if user has \>10 real items in same category  
- [ ] PostHog dashboard shows at least one event from Shireen's device  
- [ ] Sentry shows no unresolved crashes from last build

---

## **MINI-SPEC TEMPLATE**

Before asking Claude Code to build any new feature, write this first (10 lines max):

Feature: \[name\]

What it does: \[one sentence\]

What it doesn't do: \[one sentence\]

User trigger: \[what the user sees / does\]

System response: \[what happens in the backend\]

Data written: \[which tables, which fields\]

Success signal: \[how we know it worked\]

Kill condition it gates: \[K1-K5 or "none"\]

Do not build: \[explicit exclusions\]

Depends on: \[feature IDs that must exist first\]

---

## **MEMORY MANAGEMENT**

When you discover something valuable during a session — architectural decisions, bug fixes, gotchas, environment quirks — immediately append it to `.claude/memory.md`.

Format: `YYYY-MM-DD: [what] — [why it matters]`

Do not wait until session end. Do not wait to be asked.

Read `.claude/memory.md` at the start of every session before reading anything else.

---

## **SESSION STARTUP CHECKLIST**

1. Read `.claude/memory.md`  
2. Check current phase in BUILD SEQUENCE — which phase are we in?  
3. Check if any kill conditions have fired (look at KILL CONDITIONS table)  
4. Check DECISION JOURNAL before proposing any architectural change  
5. Check WHAT NOT TO BUILD before starting any new feature  
6. If uncertain about scope: re-read THE CORE ARCHITECTURAL BET

---

## **CLAUDE.MD VERSIONING PROTOCOL**

### **When it gets updated**

CLAUDE.md is updated when any of the following happen:

- A kill condition fires and the product response changes architecture  
- A Decision Journal entry is added that affects build behavior  
- A new phase gate is passed (new phase begins)  
- A confirmed rule in KNOWLEDGE ARCHITECTURE is promoted or demoted  
- Claude Code hits a recurring pattern that should be a rule (≥2 occurrences)

### **Who triggers it**

Curro triggers it. Claude Code proposes edits inline during a session; Curro reviews and commits.

### **Commit convention**

docs: update CLAUDE.md — \[one-line reason\]

Examples:

docs: update CLAUDE.md — K1 fired, matcher redesign in progress

docs: update CLAUDE.md — Phase 1 gate passed, Phase 2 begins

docs: update CLAUDE.md — app name updated to \[NEW NAME\]

docs: update CLAUDE.md — Edge Function layer confirmed, direct API calls prohibited

### **How to avoid it going stale**

- Every Friday: check if any decision made this week is missing from the Decision Journal. If yes, add it.  
- Every phase gate: re-read CLAUDE.md top to bottom. Remove anything that no longer applies.  
- If Claude Code contradicts CLAUDE.md twice in a row on the same topic, the rule needs to be clearer — rewrite it, don't just repeat it.

### **Anti-patterns to avoid**

- Updating CLAUDE.md mid-session and not committing. The commit is what makes it durable.  
- Adding rules that describe what Claude should think, not what it should do. Rules must be testable.  
- Letting the Decision Journal grow without ever pruning superseded decisions.

