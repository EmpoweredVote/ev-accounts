# Phase 103: State Remediation — CA + MD - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-05
**Phase:** 103-state-remediation-ca-md
**Areas discussed:** CA triage scope, CA politician scope, Plan structure, MD topics, Source update policy

---

## CA Triage Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full triage | Run fresh query for all CA politicians — unsourced AND weak-source detection. Mirrors Phase 101/102. | ✓ |
| Skip triage, use known 9 | Remediate the 9 already on Phase 100 target list directly. Faster but misses weak-source-only issues. | |
| Full triage but unsourced only | Fresh query for unsourced stances only — no weak-source check. | |

**User's choice:** Full triage (recommended)
**Notes:** Plan 01 runs the same dual-scope pattern as Phase 101/102 — both unsourced and homepage-only weak-source detection for ALL CA politicians in the DB.

---

## CA Politician Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Strict CA legislators only | Filter to STATE_LOWER + STATE_UPPER district types. Newsom excluded. | |
| All CA state politicians | Triage covers Assembly, Senate, and statewide executives (governor etc.). Newsom included. | ✓ |
| You decide | Follow district type mapping in DB — include if tied to a CA district. | |

**User's choice:** All CA state politicians (recommended)
**Notes:** Gavin Newsom appears on Phase 100 target list with 4 unsourced stances. Including statewide executives is the practical choice since they're already flagged.

---

## Plan Structure

| Option | Description | Selected |
|--------|-------------|----------|
| 3 plans | Plan 01: CA triage. Plan 02: CA research + migration + deletion log. Plan 03: MD research + migration + deletion log appendix. | ✓ |
| 2 plans | Plan 01: CA triage. Plan 02: CA + MD remediation combined. | |
| 4 plans | Plan 01: CA triage. Plan 02: CA research + migration. Plan 03: MD research. Plan 04: MD migration + finalize deletion log. | |

**User's choice:** 3 plans (recommended)
**Notes:** Clean separation of the two tracks. Planner may split Plan 02 if CA triage reveals >25 target politicians (following Phase 101 size thresholds).

---

## MD Topics

| Option | Description | Selected |
|--------|-------------|----------|
| All live topics | research-stances runs all live compass topics; only outputs stances where evidence is found. Consistent with Phase 78 city officials approach. | ✓ |
| Curated subset only | Pre-select high-probability topics for MD state executives. Faster but risks missing evidence. | |

**User's choice:** All live topics — "all 44 topics for MD - and everyone we can"
**Notes:** User indicated there may be 44 live topics (not the original 21). Planner must verify live count with `SELECT COUNT(*) FROM inform.compass_topics WHERE is_live = true` before writing Plan 03.

---

## Source Update Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Append new to existing | ARRAY_CAT new real URLs onto existing sources array. Preserves prior source history. | ✓ |
| Replace with new only | Overwrite sources[] with newly found URLs. Simpler migration but loses prior sources. | |

**User's choice:** Append new to existing (recommended)
**Notes:** User explicitly asked "if we find more valid sources, can we add them to a list, rather than just take the newest?" — confirmed accumulation policy. Migration uses `sources = sources || ARRAY['new_url']` for existing context rows.

---

## Claude's Discretion

- Plan 02 batching: Planner decides how to split CA research batches based on triage output (≤10 = 1 batch, 11–25 = 2 batches, 26+ = 3 batches — following Phase 101 thresholds)
- Migration number: Planner must verify current max migration version from DB before writing next migration

## Deferred Ideas

None — discussion stayed within phase scope.
