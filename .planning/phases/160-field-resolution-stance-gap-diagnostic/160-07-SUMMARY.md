---
phase: 160-field-resolution-stance-gap-diagnostic
plan: 07
subsystem: data
tags: [csv, postgres, validation, election-data, house-candidates]

# Dependency graph
requires:
  - phase: 160-01
    provides: DB diagnostics (incumbent map, external-id collision audit, race-preexistence audit)
  - phase: 160-02
    provides: WA+AZ+TN+MA field-resolution partial (160-field-table-p161.csv)
  - phase: 160-03
    provides: IN+MD+MN+MO field-resolution partial (160-field-table-p162.csv)
  - phase: 160-04
    provides: WI+CO+AL+SC+LA field-resolution partial (160-field-table-p163.csv)
  - phase: 160-05
    provides: KY+OR+CT+OK+AR+IA+KS+MS field-resolution partial (160-field-table-p164.csv)
  - phase: 160-06
    provides: 17 small-delegation-states field-resolution partial (160-field-table-p165.csv)
provides:
  - Master 178-row 160-field-table.csv (single canonical artifact for seeding phases 161-165)
  - 160-FIELD-TABLE.md human view (88/90 split, AL/LA/RCV special cases, Phase-167 clusters)
  - diag-160-validate-field-table.py CSV shape gate (exits 0)
  - 160-verify.sql write-free DB baseline gate (exits 0 against prod, discovered 29-race baseline)
affects: [161, 162, 163, 164, 165, 166, 167]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Master field-table merge: concatenate N seeding-group CSV partials, sort by geo_id, single canonical artifact filtered by seeding_phase column downstream"
    - "Write-free DB baseline gate asserting a DISCOVERED non-zero baseline (not a blanket-zero claim) when live diagnostics contradict the roadmap's stated assumption"
    - "Row-level (not state-blanket) existing_race_id validation rule for states with partial pre-existing-race coverage patterns"

key-files:
  created:
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/160-FIELD-TABLE.md
    - backend/scripts/diag-160-validate-field-table.py
    - backend/scripts/160-verify.sql
  modified: []

key-decisions:
  - "Sorted master CSV by geo_id (which already encodes state FIPS as its first two characters) rather than a separate two-key sort — geo_id-only sort produces an identical, stable state+district ordering."
  - "Phase-167 primary-date cluster table groups the 90 late-primary districts into 7 calendar-week clusters + LA's own qualifying-window case (8 total trigger groups), per RESEARCH.md's 5-7-cluster practicality recommendation."
  - "160-verify.sql's A2 assertion is a full rewrite of Phase-154's pattern, not a copy: it asserts the DISCOVERED 29-race baseline (ME2/MD8/MA9/NV4/OR6) plus the discovered race_candidates counts (NV=9/MA=2/ME=2/MD=0/OR=0), never a blanket 0-races or 0-candidates claim."

patterns-established:
  - "Pattern: merge-then-validate-then-gate sequence for multi-wave field-resolution phases — CSV merge (Task 1) -> CSV shape validator (Task 2) -> live DB baseline gate (Task 3), each with its own automated verify command."

requirements-completed: [USHC3-01]

# Metrics
duration: 25min
completed: 2026-07-03
---

# Phase 160 Plan 07: Merge + Validate + Gate Summary

**Merged 5 seeding-group CSV partials into the single canonical 178-row `160-field-table.csv`, then authored a CSV shape validator and a write-free DB baseline gate — the latter asserting the DISCOVERED 29 pre-existing races (ME/MD/MA/NV/OR), not a blanket-zero claim — closing out Phase 160 as the phase gate for USHC3-01.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-07-03T08:20:07Z
- **Completed:** 2026-07-03T08:29:37Z
- **Tasks:** 3 completed
- **Files modified:** 4 created

## Accomplishments
- Merged `160-field-table-p161.csv` through `p165.csv` (37+33+36+38+34 = 178 rows) into one canonical `160-field-table.csv`, sorted by `geo_id`, verified exact seeding_phase distribution `{161:37, 162:33, 163:36, 164:38, 165:34}` and the 88-decided/90-late-primary partition.
- Wrote `160-FIELD-TABLE.md` — the human view documenting the 88/90 split, per-state district counts for all 38 states, the AL district-split (AL-3/4/5 decided vs AL-1/2/6/7 late-primary), Louisiana's jungle-primary system change, the AK/ME RCV over-indulgence (D-04a), per-state new-record counts (655 total), the 13 zero-tier incumbents (MD 8 + IN 3 + ME 2), the 29-row pre-existing-race reuse set with the NV-2 NULL-pid and IN-9 incumbent-flag-bug anomaly callouts, and the Phase-167 primary-date cluster table (7 calendar-week clusters + LA's own qualifying-window case).
- Authored `diag-160-validate-field-table.py`, a pure CSV-shape gate cloned from Phase 154's validator: asserts 178 rows across 38 states, the 88/90 partition, all 19 required columns, non-empty `source_url`/`nominee_status`, the row-level ME/MD/MA/NV/OR `existing_race_id` rule (29 UUID-shaped rows, 149 blank), and the AL district-split. Exits 0 against the master CSV; verified it FAILs correctly on a corrupted row count.
- Authored `backend/scripts/160-verify.sql`, a write-free pre-seeding DB baseline gate: A1 asserts the 38-state/178-district count; A2 is a full rewrite of Phase 154's pattern, asserting the DISCOVERED 29-race baseline (not a blanket zero) plus the discovered `race_candidates` counts (NV=9, MA=2, ME=2, MD=0, OR=0); A3 asserts all 178 districts have exactly 1 incumbent holder (no known Wave-3 vacancy this session). Ran read-only against production (`kxsdzaojfaibhuzmclfq`) — all 5 `RAISE NOTICE` PASS lines printed, `ALL ASSERTIONS PASSED (160 baseline)`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Merge the 5 partials into master 160-field-table.csv + write 160-FIELD-TABLE.md** - `ba8ddd99` (docs)
2. **Task 2: Write diag-160-validate-field-table.py** - `53638580` (feat)
3. **Task 3: Write 160-verify.sql** - `7308795f` (feat)

**Plan metadata:** (this commit) `docs(160-07): complete plan`

## Files Created/Modified
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table.csv` - Master 178-row field table (19 columns, sorted by geo_id)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-FIELD-TABLE.md` - Human view: 88/90 split, AL/LA/RCV special cases, per-state new-record counts, Phase-167 cluster table
- `backend/scripts/diag-160-validate-field-table.py` - Read-only CSV shape gate (178 rows, 88/90, AL split, row-level existing_race_id, 19 columns)
- `backend/scripts/160-verify.sql` - Write-free DB baseline gate (discovered 29-race baseline + 178 counts + empty vacancy set)

## Decisions Made
- Merge sort key: `geo_id` alone (already FIPS-prefixed) rather than a compound `(state_fips, geo_id)` sort — identical result, simpler implementation.
- Phase-167 cluster granularity: 7 calendar-week clusters + LA's own qualifying-window row, matching RESEARCH.md's explicit "5-7 clusters" recommendation.
- 160-verify.sql A2 rewritten (not copied) from the 154 template to assert the discovered non-zero baseline, per the plan's explicit instruction and RESEARCH.md Critical Finding 4.

## Deviations from Plan

None - plan executed exactly as written. All three tasks' verify commands and acceptance criteria passed on the first implementation without requiring fixes.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required. `160-verify.sql` was run read-only against the existing production `DATABASE_URL` already configured in `backend/.env`.

## Next Phase Readiness

Phase 160 is now complete and ready for `/gsd:verify-work`. The single canonical `160-field-table.csv` is available for phases 161-165 to filter by `seeding_phase`; the discovered 29-race baseline is confirmed pre-seeding so phases 162 (MD), 161 (MA), 164 (OR), 165 (NV, ME) know to reuse `existing_race_id` rather than re-create races. The two flagged anomalies (NV-2 NULL-`politician_id`, IN-9 incumbent-flag bug) are documented in `160-FIELD-TABLE.md` §8 for phases 165 and 162 respectively to fix in place. Phase 167's per-cluster date-gated plans can be authored directly from the §9 cluster table once each cluster's trigger date arrives.

---
*Phase: 160-field-resolution-stance-gap-diagnostic*
*Completed: 2026-07-03*

## Self-Check: PASSED

All 5 created files verified present on disk; all 3 task commit hashes (`ba8ddd99`,
`53638580`, `7308795f`) verified present in git log.
