# StyleStack — CLAUDE.md

## Global Rules (load first)
CLAUDE-RULES Drive ID: 1Gtco10Gd-ft_vzS0oVqFEgpTrrxnUg6Xlx7c_zWQtSU
CLAUDE-PROFILE Drive ID: 126im6XV_ZOYsueDr_cQ4LpsSMTQOlGigaWXvVYOL7I4

Confirmed rules: concise outputs · push back on unclear scope · flag assumptions ·
use skills for repetition · try before asking · no transient Drive files ·
doc format routing (data → Sheet, narrative → Google Doc)

---

## Karpathy Coding Guidelines
Source: https://github.com/forrestchang/andrej-karpathy-skills

1. **Think before coding** — state assumptions explicitly; if multiple interpretations exist, present them; push back when warranted; stop and ask if unclear
2. **Simplicity first** — minimum code that solves the problem; no features beyond what was asked; no premature abstraction; if you write 200 lines and it could be 50, rewrite it
3. **Surgical changes** — touch only what you must; match existing style; don't "improve" adjacent code; remove only imports/variables YOUR changes made unused
4. **Goal-driven execution** — define success criteria before starting; loop until verified; for multi-step tasks, state a brief plan with verify steps

---

## Aakash Gupta PM Skills
Source: https://github.com/aakashg/pm-claude-skills
5 core skills — each encodes a specific PM workflow for consistency:

idea-validator — test product hypotheses against data; surface gaps before building
linkedin-post-writer — turn product updates into shareable posts
product-designer — structured approach to feature design with tradeoffs
prompt-engineer — meta-skill for writing better prompts to Claude
status-update-writer — weekly/monthly recap format with context, wins, blockers

Most relevant for StyleStack: idea-validator (hypothesis testing), status-update-writer (validation recap).
Install when Claude Code is live:
git clone https://github.com/aakashg/pm-claude-skills.git ~/pm-claude-skills
mkdir -p .claude/skills
cp -r ~/pm-claude-skills/skills/* .claude/skills/

---

## Pawel Huryn PM Skills
Source: https://github.com/phuryn/pm-skills
Install when Claude Code is live: `/plugin marketplace add phuryn/pm-skills`

Covers: product discovery, strategy, execution, market research, analytics, GTM.
Most relevant for StyleStack: `/discover` (assumption mapping), `/research` (interview synthesis), `/strategy` (competitive positioning).

---

## StyleStack-Specific Rules

### Phase
Validation. Do not build features. Test cheaply. Assumptions must be explicit.

### Core Bet
StyleStack is a trend-native closet management tool: upload photos → get outfit suggestions informed by current fashion trends + season. Core hypothesis: if friction to upload is low and suggestions feel trend-aware, users will engage and return.

### Source of Truth
- Shireen = source of truth on user experience and ICP (plus 5 alpha testers, not just Shireen)
- 00-context in Drive (folder 1qPKN4ipFJuR5dpnoKHtlK7eYetgwJGUw) = project status
- DECISIONS.md in Drive = all decisions with rationale
- MVP-SCOPE = scope boundary + amendment criteria
- MEASUREMENT-FRAMEWORK = validation targets + kill conditions

### Tech Stack (decided)
React Native (Expo) + TypeScript strict · Supabase (auth + Postgres + storage) ·
Anthropic API (classification + outfit logic) · Photoroom (background removal) ·
Zustand (state) · Expo Router (navigation)

### Drive Folder IDs
- 00-Context:  1qPKN4ipFJuR5dpnoKHtlK7eYetgwJGUw
- 01-Strategy: 1UtUg_8GCf9gfuaQiSkcKNZ7BYaOxDzs8
- 02-Research: 1QStOnjQPCtatz5h6BbZidumcAw_2gHYC
- 03-Technical: 1hZwP72IzhwRLWXE2NGm-lSb4BxUJ1GMq
- 04-Shireen:  1CPPwv0I59MX0DvYWJr76v82bNFTWWuwq

### Document Format Routing (mandatory)
- Narrative docs (specs, briefs, strategy, reports) → Google Doc via Drive MCP (text/plain → auto-converts)
- Data / trackers → Google Sheet via Drive MCP
- Do NOT use docx-js or openpyxl pipelines for Drive uploads — they produce broken files
- Friday: paste session recap into DECISIONS.md in Drive

---

## Phase 1 Validation Architecture (Weeks 1–6)

### The 4 Critical Unknowns Being Tested
- **U1: Upload Friction** — Can users upload 20+ items without dropout?
- **U2: Suggestion Quality** — Do ≥70% of suggestions rate 3+ on a 1–5 scale?
- **U3: Trend Sourcing** — Can we source/curate trends cost-effectively + accurately?
- **U4: Vision API Accuracy** — Does automatic tagging catch colors/styles correctly?

See MEASUREMENT-FRAMEWORK (01-Strategy folder) for targets, acceptable thresholds, and kill conditions.

### MVP Scope
See MVP-SCOPE (01-Strategy folder) for:
- Core flows (photo upload → closet → outfit suggestions → trend display)
- Deferred features (multi-user closets, brand tagging, ML suggestions, social, mobile app)
- Feature amendment criteria (≥50% mention unprompted + blocks core job + <8 hour implementation)

### False Positives to Watch
- Shireen enthusiasm ≠ product value (watch the 5 friends, not Shireen)
- Completion ≠ low friction (also track time per item)
- Early adopter novelty (test Week 2 retention, not just Week 1)
- "It's cool" ≠ "I'll use it" (measure behaviour, not praise)
- 1 great suggestion ≠ success (need ≥70% threshold across all suggestions)

---

## Weekly Ritual (Every Friday 9 AM)
Full protocol in Cowork task "Weekly Review + Learning". StyleStack-specific addition: devil's advocate pass (see Step 8 in that task).

**Step 1 (20 min): Debrief with Shireen**
- Upload counts, time per item, pain points, exact quotes
- Suggestion ratings, trend relevance feedback
- Any unexpected moments (positive or negative)

**Step 2 (20 min): Devil's Advocate Pass with Claude**
- Bias check, assumption challenge, interpretation check, kill condition alert
- See Cowork task Step 8 for the four question templates

**Step 3 (10 min): Decision & Documentation**
- Update 00-context with Week X Summary
- Confidence level per unknown (High/Medium/Low)
- Escalate any kill condition risk to DECISIONS.md immediately

---

## Error Protocol (critical)
If stuck or hitting an error building a file/document:
1. STOP after 1 failed attempt
2. Report the specific error in one sentence
3. Skip to next task immediately
Never spend more than 1 retry on the same error. Token waste from retry loops is not acceptable.

---

## Session Template (Claude Code)

Start of every session:
```
Read CLAUDE.md first.
Phase: Validation — no feature building.
Task: [specific task]
Success criteria: [how will we know this is done?]
```

End of every session:
- Note any new architectural decisions or assumptions introduced
- Commit if relevant
- Link any open questions to DECISIONS.md

---

## Git Integration
- .claude/CLAUDE.md in the repo is the working copy during dev sessions
- This Drive copy is the reference; sync manually ~1x/week
- GitHub is primary for skills, decisions, and version history

