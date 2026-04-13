# Phase 114: UX Walkthrough - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-12
**Phase:** 114-ux-walkthrough
**Areas discussed:** Persona & journey depth, Gap classification schema, Scope per app + cross-app, Env + output structure

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Persona & journey depth | Who is the first-time voter, how deep per app | ✓ |
| Gap classification schema | How to tag friction so Phase 115 can sort Tier 1 vs Tier 2 | ✓ |
| Scope per app + cross-app | Treasury special case + cross-app integration audit | ✓ |
| Env + output structure | Production vs local dev + per-app files vs unified doc | ✓ |

All four areas selected.

---

## Persona & Journey Depth

### Q1: Who is the first-time voter persona for the walkthrough?

| Option | Description | Selected |
|--------|-------------|----------|
| Single primary voter | One persona: naive Monroe County voter at 200 W Kirkwood Ave. Keeps walkthrough focused and comparable to 113's matrix which scored against the same address. | ✓ |
| Primary + 1 student persona | Kirkwood voter + an IU student (on-campus address). | |
| Three personas | Kirkwood city voter + IU student + rural township voter. | |

**User's choice:** Single primary voter (recommended default)
**Notes:** Matches 112 and 113 primary address for controlled comparison; additional personas deferred.

### Q2: How deep should the walkthrough go per app?

| Option | Description | Selected |
|--------|-------------|----------|
| Every screen the voter can reach | Full reachable-screen walkthrough — captures mid-flow friction. Matches phase goal wording. | ✓ |
| Key decision screens only | Only opinion-forming or dead-end screens. Faster but risks missing mid-flow friction. | |
| Entry + sampled deep dive | Full Essentials walkthrough + sampled touch points elsewhere. | |

**User's choice:** Every screen the voter can reach (recommended default)
**Notes:** Phase goal explicitly says "reviewing each screen" — taken literally. Empty/loading/error states are in scope.

---

## Gap Classification Schema

### Q1: How should gaps/friction be tagged so Phase 115 can sort Tier 1 vs Tier 2?

| Option | Description | Selected |
|--------|-------------|----------|
| Severity + Type | Two orthogonal axes (blocker/confusing/minor × data/feature/content/ux-friction). | ✓ |
| Severity only | Just blocker/confusing/minor. Loses data-vs-feature distinction. | |
| Type only | Just data/feature/content/ux-friction. Loses severity. | |

**User's choice:** Severity + Type (recommended default)
**Notes:** Phase 115 needs both axes — severity for tier cutoff, type for intentional-omissions separation.

### Q2: How should each gap be recorded — what minimum fields per entry?

| Option | Description | Selected |
|--------|-------------|----------|
| ID + screen + description + severity + type + evidence | Stable gap ID + URL + one-liner + severity + type + screenshot/console pointer. | ✓ |
| Description + severity + type only | Lighter but Phase 115 can't cite back to anything concrete. | |
| Free-form narrative per app | Fastest but loses the tiered report's ability to count and classify. | |

**User's choice:** ID + screen + description + severity + type + evidence (recommended default)
**Notes:** `baseline_ref` added as optional field for data-type gaps tying back to `BALLOT-BASELINE-2026-05-05.md`.

---

## Scope Per App + Cross-App

### Q1: How should Treasury be assessed — it's a relevance check, not an obvious voter journey?

| Option | Description | Selected |
|--------|-------------|----------|
| Relevance check first, walkthrough only if data exists | Step 1: does any Monroe/Bloomington data exist? Step 2 conditional walkthrough. | ✓ |
| Full walkthrough regardless | Walk Treasury like the others even if Monroe data is absent. | |
| Skip Treasury walkthrough, data check only | Query schema, log result, no UI walk. | |

**User's choice:** Relevance check first, walkthrough only if data exists (recommended default)
**Notes:** Absence of data is itself the finding — log one top-level gap and stop.

### Q2: Should cross-app links be audited, or treat each app independently?

| Option | Description | Selected |
|--------|-------------|----------|
| Each app independent + one cross-app integration pass | Primary: per-app UX-01..04. Secondary: short pass following stitching links. | ✓ |
| Each app fully independent | Strict UX-01..04, no cross-app. | |
| Fully integrated voter journey | One continuous flow address → Essentials → profile → compass → readrank → treasury. | |

**User's choice:** Each app independent + one cross-app integration pass (recommended default)
**Notes:** Mapped to `cross-app.md` file; covers SiteHeader nav, profile→CompassCard, profile→Read & Rank verdict badges, Compass politician picker → candidate records.

---

## Env + Output Structure

### Q1: Which environment should the walkthrough run against?

| Option | Description | Selected |
|--------|-------------|----------|
| Production | Live `*.empowered.vote` domains. Honest baseline for what must ship before May 5. | ✓ |
| Local dev | npm run dev against each app. Shows unreleased work but undercounts shipped gaps. | |
| Production primary + local dev deltas noted | Prod walkthrough + "fixed locally" notes. More work, more complete. | |

**User's choice:** Production (recommended default)
**Notes:** Unreleased-but-merged work deliberately not credited — Phase 115 is about ship-before-primary.

### Q2: How should outputs be laid out?

| Option | Description | Selected |
|--------|-------------|----------|
| Per-app files + aggregated GAPS.md | Per-app narratives + flat GAPS.md (+ gaps.csv) + screenshots subfolder. Mirrors 113 layout. | ✓ |
| Single unified WALKTHROUGH.md | One long doc with all four apps as sections. No flat gap list. | |
| Per-app files only (no aggregated GAPS.md) | Per-app narrative, gaps inline only. Phase 115 has to re-collect. | |

**User's choice:** Per-app files + aggregated GAPS.md (recommended default)
**Notes:** GAPS.md is Phase 115's primary input. gaps.csv mirrors 113's matrix.csv convention.

---

## Claude's Discretion

- Exact screen ordering within each app walkthrough (bounded by "every reachable screen")
- Screenshot filenames and count per screen
- Narrative depth per screen (where to linger vs summarize)
- Whether gaps.csv is a direct mirror of GAPS.md or normalized long-form
- Exact set of cross-app links to follow (bounded by SiteHeader, profile→CompassCard, profile→Read & Rank verdict badges)
- How to handle ambiguous severity calls — document inline in GAPS.md with a one-line reason

## Deferred Ideas

- Additional personas (IU student, rural township) — future phase if Kirkwood walkthrough exposes district/demographic friction
- Local dev vs production diff pass — rejected to keep scope tight; deploy-cadence concern not UX concern
- Fully integrated single-session voter journey — rejected in favor of per-app + cross-app pass for cleaner UX-01..04 mapping
