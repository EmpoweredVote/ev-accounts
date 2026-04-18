---
phase: 121-county-council-d1-d4-geofence-repair
plan: 01
subsystem: database
tags: [postgis, geofence, monroe-county, county-council, diagnosis, gis]

# Dependency graph
requires:
  - phase: 112-geofence-smoke-test
    provides: audit-112-geofence.ts smoke test script with Kirkwood coordinate
provides:
  - Read-only diagnostic script for MCC geofence wiring state (diagnose-121-mcc-state.ts)
  - Captured dev-DB state at phase start (evidence/diagnosis.csv)
  - MCC exclusivity assertion in audit-112-geofence.ts ([121-geo] PASS/FAIL signal)
  - Ground-truth attestation confirming Kirkwood=D4 from two authoritative GIS sources
affects: [121-02, 121-03, 121-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Read-only diagnostic scripts with section-tagged CSV output (BOUNDARIES/OFFICES/KIRKWOOD)"
    - "External GIS FeatureServer attestation preserved as evidence markdown"

key-files:
  created:
    - ev-accounts/backend/scripts/diagnose-121-mcc-state.ts
    - .planning/phases/121-county-council-d1-d4-geofence-repair/evidence/diagnosis.csv
    - .planning/phases/121-county-council-d1-d4-geofence-repair/evidence/ground-truth-attestation.md
  modified:
    - ev-accounts/backend/scripts/audit-112-geofence.ts

key-decisions:
  - "Dev DB already has sub-district MCC polygons (D1-D4, mtfcc=X0001) — Wave 0 diagnosis shows kirkwood_mcc_count=1 (PASS), not 4 as the research hypothesis predicted"
  - "All 4 MCC Council offices still point to county-wide geo_id=18105 (COUNTY geofence) — the fix is partial: geofence_boundaries has D1-D4 polygons but districts/offices are not yet re-linked"
  - "Kirkwood resolves to D4 because geofence_boundaries now has 1810500004 polygon that covers Kirkwood, but offices query joins through districts which still use geo_id=18105"
  - "GAP-REPORT.md PATTERN-004 wording 'should resolve to D1' is incorrect — D4 is confirmed correct by Monroe County GIS and IN statewide FeatureServer"

patterns-established:
  - "Phase 121: GIS attestation pattern — curl FeatureServer URLs and embed raw JSON in evidence markdown for reviewer sign-off"

requirements-completed: [GEO-01, GEO-02]

# Metrics
duration: 45min
completed: 2026-04-16
---

# Phase 121 Plan 01: Wave 0 Diagnosis + Smoke-Test Hardening Summary

**Read-only MCC diagnostic capturing dev-DB state reveals sub-district polygons already exist but offices still link to county-wide geo_id=18105; Kirkwood resolves to D4 (1 race, PASS) via geofence_boundaries but not yet via district re-linking.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-16T00:00:00Z
- **Completed:** 2026-04-16T00:45:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Created read-only diagnostic script `diagnose-121-mcc-state.ts` that queries three aspects of MCC geofence wiring and writes section-tagged CSV evidence
- Extended `audit-112-geofence.ts` with `[121-geo]` exclusivity assertion for the Kirkwood coordinate (Monroe County Council races must return exactly 1)
- Captured dev-DB state at phase start in `evidence/diagnosis.csv` — reveals the sub-district polygons were already imported before this phase
- Preserved ground-truth attestation (two authoritative GIS FeatureServer queries) confirming Kirkwood = Monroe County Council District 4

## Diagnostic Output — Key Metrics

| Metric | Expected (Hypothesis) | Actual (Dev DB) | Assessment |
|--------|----------------------|-----------------|------------|
| `boundaries_18105_count` | 1 (county-wide only) | 22+ (includes D1-D4 sub-districts) | Sub-district polygons already present |
| `mcc_offices_linked_to_18105` | 4 offices → geo_id=18105 | 4 offices → geo_id=18105 | CONFIRMED — offices not yet re-linked |
| `kirkwood_mcc_count` | 4 (bug: all districts match) | 1 (Monroe County Council District 4) | Bug already partially fixed via geofence_boundaries |

**Finding:** The research hypothesis that `kirkwood_mcc_count=4` was based on the assumption that no sub-district MCC polygons existed. The dev DB has since been updated with D1-D4 polygons (`geo_id` values `1810500001`–`1810500004`, `mtfcc=X0001`). As a result:
- The Kirkwood geofence lookup already returns 1 race (D4) — the visible bug is resolved for ST_Covers-based lookups
- However, the `essentials.offices` and `essentials.districts` tables still link all 4 MCC offices to the county-wide `geo_id=18105` district — the data model re-linking (Wave 2) has not been completed

The `[121-geo]` assertion currently shows **PASS** (kirkwood_mcc_count=1). This is good news but means Wave 1 polygon import is already done. Plans 02–04 should verify whether Wave 2 (district/office re-linking) is also complete or still needed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create read-only diagnostic script** - `a394f79` (feat)
2. **Task 2: Extend audit-112-geofence.ts with MCC exclusivity assertion** - `3e5cd53` (feat)
3. **Task 3: Record ground-truth attestation** - `3894610` (docs)

## Files Created/Modified

- `ev-accounts/backend/scripts/diagnose-121-mcc-state.ts` — Read-only diagnostic: dumps MCC geofence_boundaries, districts, offices state + Kirkwood ST_Covers result
- `ev-accounts/backend/scripts/audit-112-geofence.ts` — Extended with `[121-geo] PASS/FAIL` exclusivity assertion for Kirkwood (Monroe County Council races)
- `.planning/phases/121-county-council-d1-d4-geofence-repair/evidence/diagnosis.csv` — Captured dev-DB state at phase start (section-tagged: BOUNDARIES, OFFICES, KIRKWOOD)
- `.planning/phases/121-county-council-d1-d4-geofence-repair/evidence/ground-truth-attestation.md` — Two-source GIS attestation confirming Kirkwood = D4

## Decisions Made

- **Research hypothesis revised:** The plan assumed `kirkwood_mcc_count=4` would confirm the bug. Actual value is 1 — the geofence_boundaries table already has the D1-D4 sub-district polygons, imported before this phase. Wave 1 may be redundant.
- **D4 confirmed correct:** Both Monroe County GIS FeatureServer (CountyCouncil="4", Council="Council 4", Rep="Jennifer Crossley") and IN statewide FeatureServer (dsplayname="Council 4") independently confirm D4 is the correct district for Kirkwood.
- **GAP-REPORT.md PATTERN-004 is incorrect:** It states "should resolve to D1" — this is wrong. D4 is the authoritative answer. Will be corrected in Plan 04 as specified.

## Deviations from Plan

None — plan executed exactly as written. The only surprise was the empirical finding that the dev DB is ahead of the research hypothesis (sub-district polygons already imported). This is documented as a finding, not a deviation from plan execution.

The `[121-geo]` assertion currently shows PASS rather than the expected FAIL (kirkwood_mcc_count=1, not 4). This is recorded as a key finding. Plans 02–04 should be scoped accordingly.

## Issues Encountered

None — all scripts ran cleanly, both GIS FeatureServer endpoints returned valid responses, and the TypeScript type check passed.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Wave 0 complete: diagnostic evidence captured, smoke test hardened, ground truth attested
- **Critical finding for planner:** Sub-district geofence polygons (D1-D4) already exist in dev DB. Wave 1 polygon import (Plan 02) may be a no-op or near-no-op — planner should run the diagnostic against prod DB to see if prod is behind dev
- The `offices` → `districts` re-linking (Wave 2) still needs verification: OFFICES section shows all 4 MCC offices pointing to `geo_id=18105` (county-wide), not to their respective sub-district `geo_id` values
- Plans 02–04 should be reviewed against actual DB state before executing additional writes

---
*Phase: 121-county-council-d1-d4-geofence-repair*
*Completed: 2026-04-16*

## Self-Check

### Files exist:
- `ev-accounts/backend/scripts/diagnose-121-mcc-state.ts` — FOUND
- `.planning/phases/121-county-council-d1-d4-geofence-repair/evidence/diagnosis.csv` — FOUND
- `.planning/phases/121-county-council-d1-d4-geofence-repair/evidence/ground-truth-attestation.md` — FOUND
- `ev-accounts/backend/scripts/audit-112-geofence.ts` — FOUND (modified)

### Commits exist:
- `a394f79` feat(121-01): add read-only MCC geofence diagnostic script + capture evidence CSV — FOUND
- `3e5cd53` feat(121-01): extend audit-112-geofence.ts with MCC exclusivity assertion — FOUND
- `3894610` docs(121-01): record ground-truth attestation Kirkwood=D4 from two authoritative GIS sources — FOUND

## Self-Check: PASSED
