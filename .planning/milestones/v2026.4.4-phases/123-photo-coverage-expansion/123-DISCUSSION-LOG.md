# Phase 123: Photo Coverage Expansion - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 123-photo-coverage-expansion
**Areas discussed:** Population Scope, Phase 120 Priority C handoff, Sourcing Strategy, Execution Model

---

## Population Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Audit first | Run audit-112-headshots.ts at phase start; DB is ground truth | ✓ |
| Non-contested May 5 only | Strictly uncontested May 5 2026 IN candidates | |
| All linked politicians missing photos | Any politician_id-linked record DB-wide | |

**User's choice:** Audit first (recommended)

**Follow-up — cap or attempt all:**

| Option | Description | Selected |
|--------|-------------|----------|
| Attempt all gaps found | Try to source photos for everything the audit surfaces | ✓ |
| Cap at ~62, defer extras | Stop at 62 if audit reveals significantly more | |

**User's choice:** Attempt all gaps found

**Notes:** The "62" in the roadmap is an estimate; the audit will establish the real number.

---

## Phase 120 Priority C Handoff

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, absorb them | Fold 17 deferred contested-race township candidates into Phase 123 | ✓ |
| No, keep separate | Leave Priority C as a separate cleanup tracked under Phase 120 | |

**User's choice:** Yes, absorb them

**Notes:** The audit will surface them anyway; cleaner to close all photo gaps in one phase.

---

## Sourcing Strategy

**Depth before accepting "no photo":**

| Option | Description | Selected |
|--------|-------------|----------|
| 2-source check then fallback | Ballotpedia + one web/social search; accept fallback after | ✓ |
| Full source priority sweep | Try all 4 tiers from Phase 120 methodology | |
| Ballotpedia-only, then fallback | Fastest; Ballotpedia covers most Indiana local candidates | |

**User's choice:** 2-source check then fallback

**Who researches:**

| Option | Description | Selected |
|--------|-------------|----------|
| Claude researches all, user reviews | Same Phase 120 pattern — REVIEW-DATA table, user approves before import | ✓ |
| Claude batches by race tier | Waves by state/federal then local | |
| User provides photo URLs | User finds URLs, Claude handles upload pipeline | |

**User's choice:** Claude researches all, user reviews

---

## Execution Model

**Review table approach:**

| Option | Description | Selected |
|--------|-------------|----------|
| Single table, single import run | One REVIEW-DATA table, one approval, one import | ✓ |
| Waves (e.g., 20 at a time) | Incremental review checkpoints | |
| Separate tables by source type | Split by photo source tier | |

**User's choice:** Single table, single import run

**Import script:**

| Option | Description | Selected |
|--------|-------------|----------|
| New Phase 123 script | import-123-photo-expansion.ts, photo-only, sibling to Phase 120 script | ✓ |
| Extend Phase 120 script | Add --phase=123 mode to existing import script | |
| Claude's discretion | Planner decides | |

**User's choice:** New Phase 123 script

---

## Claude's Discretion

- Exact audit query scope (extend audit-112 for all elections vs. run as-is)
- REVIEW-DATA table column layout
- Import script structure (follow import-120 as template)

## Deferred Ideas

None
