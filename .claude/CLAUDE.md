# StyleStack — CLAUDE.md

## Global Rules (load first)
CLAUDE-RULES Drive ID: 1Gtco10Gd-ft_vzS0oVqFEgpTrrxnUg6Xlx7c_zWQtSU
CLAUDE-PROFILE Drive ID: 126im6XV_ZOYsueDr_cQ4LpsSMTQOlGigaWXvVYOL7I4

Confirmed rules: concise outputs · push back on unclear scope · flag assumptions ·
use skills for repetition · try before asking · no transient Drive files ·
doc format routing (data → Sheet, narrative → Doc with H1/H2/H3)

---

## Karpathy Coding Guidelines
Source: https://github.com/forrestchang/andrej-karpathy-skills

1. **Think before coding** — state assumptions explicitly; if multiple interpretations exist, present them; push back when warranted; stop and ask if unclear
2. **Simplicity first** — minimum code that solves the problem; no features beyond what was asked; no premature abstraction; if you write 200 lines and it could be 50, rewrite it
3. **Surgical changes** — touch only what you must; match existing style; don't "improve" adjacent code; remove only imports/variables YOUR changes made unused
4. **Goal-driven execution** — define success criteria before starting; loop until verified; for multi-step tasks, state a brief plan with verify steps

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

### Source of truth
- Shireen = source of truth on user experience and ICP
- 00-context in Drive (folder 1qPKN4ipFJuR5dpnoKHtlK7eYetgwJGUw) = project status
- DECISIONS.md in Drive = all decisions with rationale

### Tech stack (decided)
React Native (Expo) + TypeScript strict · Supabase (auth + Postgres + storage) ·
Anthropic API (classification + outfit logic) · Photoroom (background removal) ·
Zustand (state) · Expo Router (navigation)

### Drive Folder IDs
- 00-Context:  1qPKN4ipFJuR5dpnoKHtlK7eYetgwJGUw
- 01-Strategy: 1UtUg_8GCf9gfuaQiSkcKNZ7BYaOxDzs8
- 02-Research: 1QStOnjQPCtatz5h6BbZidumcAw_2gHYC
- 03-Technical: 1hZwP72IzhwRLWXE2NGm-lSb4BxUJ1GMq
- 04-Shireen:  1CPPwv0I59MX0DvYWJr76v82bNFTWWuwq

### Document format routing (mandatory)
- Narrative → DOCX via docx-js · load /mnt/skills/public/docx/SKILL.md first
- Data → XLSX via openpyxl · load /mnt/skills/public/xlsx/SKILL.md first
- Friday: paste session recap into DECISIONS.md in Drive

---

## Error Protocol (critical)
If stuck or hitting an error building a file/document:
1. STOP after 1 failed attempt
2. Report the specific error in one sentence
3. Skip to next task immediately
Never spend more than 1 retry on the same error. Token waste from retry loops is not acceptable.
