---
phase: 160-field-resolution-stance-gap-diagnostic
plan: 01
subsystem: database
tags: [postgres, diagnostic, read-only, pg, tsx, essentials-schema]

# Dependency graph
requires:
  - phase: 154-field-resolution-stance-gap-diagnostic
    provides: diag-154-incumbent-stance-gap.ts scaffold (dotenv/pool bootstrap, csvField RFC-4180 helper, hard row-count guard, main().catch wrapper) — cloned and rescaled for Wave-3
provides:
  - 178-row incumbent map (160-incumbent-map.csv) keyed by (NATIONAL_LOWER, geo_id) with stance counts + top-up tiers
  - 16-row negative external_id collision audit (160-negative-id-audit.csv) with per-district safe_start_seq
  - Full-column pre-existing race/candidate audit (160-race-preexistence-audit.csv, 59 rows) covering ANY election_date across all 38 states
affects: [161-field-resolution-wa-az-tn-ma, 162-field-resolution-in-md-mn-mo, 163-field-resolution-wi-co-al-sc-la, 164-field-resolution-ky-or-ct-ok-ar-ia-ks-ms, 165-field-resolution-17-small-states, 166-consolidated-verification-gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Read-only diagnostic scripts cloned from a proven analog (diag-154), rescaled constants only, no new architecture"
    - "Never trust a computed negative external_id band as collision-free — always run a live per-computed-value SELECT check"
    - "Sweep race/race_candidates on ANY election_date, not just the target election, to catch stale primary-era rows that inform the general-nominee resolution"
    - "Explicitly list rc.* columns instead of using rc.* in a SELECT alongside r.id AS race_id — duplicate column names (race_candidates.race_id vs the alias) silently collapse to the last value in node-postgres row parsing"

key-files:
  created:
    - backend/scripts/diag-160-incumbent-stance-gap.ts
    - backend/scripts/diag-160-external-id-collision.ts
    - backend/scripts/diag-160-race-preexistence-audit.ts
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/160-incumbent-map.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/160-negative-id-audit.csv
    - .planning/phases/160-field-resolution-stance-gap-diagnostic/160-race-preexistence-audit.csv
  modified: []

key-decisions:
  - "KY-CD1 and OK-CD1 are hardcoded (not just threshold-derived) to safe_start_seq=200 per the plan's explicit Critical-Finding-6 instruction, even though OK-CD1's raw free-slot count (56 remaining) wouldn't trigger the saturation heuristic on its own"
  - "160-negative-id-audit.csv colliding_seqs field renders as a compact range (e.g. '1-98') when the collision set is contiguous, else a comma list — kept RFC-4180 quoted either way since commas are possible"
  - "160-race-preexistence-audit.csv full-column dump uses LEFT JOIN race_candidates so 0-candidate pre-scaffolded races (MD's 8, OR's 6) still emit one audit row with existing_race_id populated and candidate fields blank"

patterns-established:
  - "Read-only diagnostic banner text must avoid literal INSERT/UPDATE/DELETE tokens even in explanatory prose, since downstream verification greps the script source for those tokens expecting 0 matches"

requirements-completed: [USHC3-01]

# Metrics
duration: 10min
completed: 2026-07-03
---

# Phase 160 Plan 01: Wave-3 DB Diagnostics Summary

**Three read-only diagnostic scripts against production (kxsdzaojfaibhuzmclfq) producing the 178-district incumbent map, a 16-district negative-external_id collision audit, and a 59-row full-column pre-existing race/candidate audit — the DB baseline every Wave-3 seeding phase (161-165) depends on.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-07-02T21:25:07-07:00 (Task 1 commit)
- **Completed:** 2026-07-02T21:34:31-07:00 (final fix-up commit)
- **Tasks:** 3 completed
- **Files modified:** 6 (3 scripts + 3 CSV artifacts)

## Accomplishments

- `diag-160-incumbent-stance-gap.ts` reproduced the researched baseline exactly: 178 mapped incumbents, 0 vacancies (Query C empty), tier split 13 zero / 154 partial / 11 done — all 38 states OK on the per-state district tally, TOTAL 178.
- `diag-160-external-id-collision.ts` reproduced the 16/178 collision finding across KY/OR/OK/KS/NV/NM/NE/ME/NH/MT, with KY-CD1 (98/99 slots) and OK-CD1 (43/99 slots) both flagged for the alternate 200+ sub-band per an explicit `ALTERNATE SUB-BAND REQUIRED` console warning naming both districts. 0 UNRESOLVED collisions.
- `diag-160-race-preexistence-audit.ts` swept ANY election_date (not just 2026-11-03) across all 38 states, confirmed the 29-district ME(2)/MD(8)/MA(9)/NV(4)/OR(6) pre-existing-race baseline with `existing_race_id` populated per district, and flagged the IN-9 incumbent-flag bug (5 rows) + NV-2 NULL-politician_id anomaly (1 row) as explicit "MUST fix, not propagate/recreate" console warnings for Phases 162 and 165 respectively. The full-column dump (59 rows, all `race_candidates` columns) resolves RESEARCH Open Question 2.

## Task Commits

Each task was committed atomically:

1. **Task 1: diag-160-incumbent-stance-gap.ts + 160-incumbent-map.csv** - `bd6ab8ae` (feat)
2. **Task 2: diag-160-external-id-collision.ts + 160-negative-id-audit.csv** - `4a231916` (feat)
3. **Task 3: diag-160-race-preexistence-audit.ts + 160-race-preexistence-audit.csv** - `1777a02c` (feat)

**Fix-up (Rule 1, applied during Task 1/2/3 verification):** `9881ed7f` (fix) — see Deviations below.

_Note: this plan has no TDD tasks; all three are single-commit `feat` tasks._

## Files Created/Modified

- `backend/scripts/diag-160-incumbent-stance-gap.ts` - Query A (178-row incumbent map) + Query B (per-state stance-gap) + Query C (holder invariant) + CSV emit with hard 178-row guard
- `backend/scripts/diag-160-external-id-collision.ts` - Per-district collision audit of `-(fips*10000+cd*100+seq)` against live negative external_ids; CSV emit with safe_start_seq
- `backend/scripts/diag-160-race-preexistence-audit.ts` - ANY-election_date summary sweep + per-race/candidate detail query; full-column CSV dump with anomaly flags
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-incumbent-map.csv` - 178 data rows (179 lines incl. header)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-negative-id-audit.csv` - 16 data rows (17 lines incl. header)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-race-preexistence-audit.csv` - 59 data rows (60 lines incl. header)

## Decisions Made

- Hardcoded KY-CD1 and OK-CD1 to `safe_start_seq=200` per the plan's explicit instruction (rather than relying purely on a saturation-threshold heuristic), since OK-CD1's raw collision count (43/99) would not have tripped an automatic ">=90 collisions" rule on its own.
- Used `LEFT JOIN essentials.race_candidates` (not `INNER JOIN`) in the pre-existence detail query so 0-candidate pre-scaffolded races (MD's 8, OR's 6) still surface a full-column audit row with `existing_race_id` populated and candidate fields blank, rather than being silently dropped.
- Explicitly enumerated every `race_candidates` column in the detail query instead of `rc.*`, to avoid a duplicate-column-name collision with `r.id AS race_id` (race_candidates has its own `race_id` FK column) — see Deviations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `rc.*` silently overwrote `r.id AS race_id` via duplicate column name**
- **Found during:** Task 3 (diag-160-race-preexistence-audit.ts) — verification step
- **Issue:** The plan's suggested detail query used `r.id AS race_id, rc.*`. Since `essentials.race_candidates` has its own `race_id` column, node-postgres collapses duplicate result-column names to the last one parsed — for 0-candidate races (MD/OR), `rc.race_id` is `NULL` and silently overwrote the `r.id` alias, leaving `existing_race_id` blank for every MD/OR row (a `nov3 existing-race states` assertion of `{'MA','ME','NV'}` instead of the required `{'ME','MD','MA','NV','OR'}`).
- **Fix:** Replaced `rc.*` with an explicit column list (`rc.id AS rc_id, rc.politician_id, rc.full_name, ...` — every `race_candidates` column except its own `race_id`), eliminating the name collision entirely.
- **Files modified:** `backend/scripts/diag-160-race-preexistence-audit.ts`
- **Verification:** Re-ran the script; `existing_race_id` now populates for all 29 ME/MD/MA/NV/OR Nov-3 rows; the plan's exact verification assertion (`states=={'ME','MD','MA','NV','OR'}`) passes.
- **Committed in:** `1777a02c` (part of Task 3 commit — caught before commit, not a follow-up fix)

**2. [Rule 3 - Blocking] Read-only banner prose contained literal INSERT/UPDATE/DELETE tokens, failing the plan's own grep-based write-free check**
- **Found during:** Tasks 1-3 verification — the plan's acceptance criteria for Tasks 2/3 run `grep -Ec "INSERT|UPDATE|DELETE" <script>` and require 0 matches; the overall plan `<verification>` section applies the same check to all three scripts.
- **Issue:** Each script's top-of-file comment banner (following the diag-154 analog's own wording) stated "Never INSERT/UPDATE/DELETE" in prose — a literal, harmless comment, but one that trips a naive token grep looking for accidental write statements.
- **Fix:** Reworded all three banners to "No write statements of any kind, ever" — same read-only guarantee communicated, now grep-clean.
- **Files modified:** `backend/scripts/diag-160-incumbent-stance-gap.ts`, `backend/scripts/diag-160-external-id-collision.ts`, `backend/scripts/diag-160-race-preexistence-audit.ts`
- **Verification:** `grep -Ec "INSERT|UPDATE|DELETE"` returns `0` for all three scripts.
- **Committed in:** `4a231916` and `1777a02c` (inline, before those tasks' commits) plus a small standalone fix-up commit `9881ed7f` for the already-committed Task 1 script.

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking-verification)
**Impact on plan:** Both fixes were caught during this plan's own verification steps before/immediately after the affected task's commit. No scope creep — no behavior changed beyond making the scripts' output/verification correct.

## Issues Encountered

None beyond the two auto-fixed deviations above.

## User Setup Required

None - no external service configuration required. All three scripts run against the existing `DATABASE_URL` in `backend/.env` (Session pooler, already configured).

## Next Phase Readiness

- `160-incumbent-map.csv`, `160-negative-id-audit.csv`, and `160-race-preexistence-audit.csv` are all git-tracked and ready for the field-resolution research waves (Plans 02-06) and the merge/gate (Plan 07) to consume.
- Phases 162 (IN) and 165 (NV) each have an explicit, documented anomaly to fix during seeding (not before) — the IN-9 incumbent-flag bug and the NV-2 NULL-politician_id row — carried via this plan's console warnings and CSV `anomaly` column, not fixed here (this phase is write-free by design).
- Phase 164 (KY, OK in scope) must consult `160-negative-id-audit.csv`'s `safe_start_seq=200` guidance for KY-CD1 and OK-CD1 before authoring any new challenger external_id in those two districts.
- No blockers for Plan 02.

---
*Phase: 160-field-resolution-stance-gap-diagnostic*
*Completed: 2026-07-03*

## Self-Check: PASSED

All 7 created files confirmed present on disk; all 5 referenced commit hashes (`bd6ab8ae`, `4a231916`, `1777a02c`, `9881ed7f`, `40275c52`) confirmed present in `git log`.
