---
phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
plan: 08
subsystem: database
tags: [postgres, essentials-schema, house-candidates, ma, headshots, wikipedia-pageimages]

# Dependency graph
requires:
  - phase: 160-field-resolution-stance-gap-diagnostic
    provides: 160-race-preexistence-audit.csv (MA existing_race_id + Clark/Pressley pre-wired rows), 160-field-table-p161.csv (MA field), 160-incumbent-map.csv (incumbent pids)
  - phase: 161-06
    provides: prior wave migration-number high-water mark (161-MIGRATION-COLLISION-NOTE.md)
provides:
  - 18 new MA U.S. House politician records + 24 race_candidates (18 new + 6 renominated incumbents) wired onto the 9 PRE-EXISTING MA races
  - MA-6 (Moulton retired) open-seat field with 7 new declared candidates, no incumbent row
  - 2 new headshots (Tram Nguyen, Dan Koh) + 16 documented honest-skips
affects: [161-10 (MA federal-24 stances), Phase 167 (MA late-independent reconciliation, filing deadline 2026-08-25)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "MA races-reuse pattern: candidates-only migration wiring race_candidates onto pre-existing races via existing_race_id, guarded by NOT EXISTS on (race_id, politician_id) rather than lower(full_name) -- stronger dedup guard than the VA-159-03 precedent since it directly matches the natural key"

key-files:
  created:
    - backend/scripts/161-ma-generate.mts
    - backend/migrations/1202_seed_ma_2026_house_candidates.sql
    - backend/scripts/seed-ma-house-headshots.py
    - backend/data/seed-ma-2026-house/161-08-ma-reconciliation.csv
  modified: []

key-decisions:
  - "Used migration number 1202 (re-checked live high-water mark per 161-MIGRATION-COLLISION-NOTE.md; 1193 assumed in plan frontmatter was stale/taken)"
  - "race_candidates dedup guard uses NOT EXISTS on (race_id, politician_id) tuple, not lower(full_name), for a stronger structural guarantee against duplicating Clark/Pressley"
  - "Seeded only the 18 declared-so-far candidates in 160-field-table-p161.csv's new_records_needed column (MA independent filing stays open to 2026-08-25); no additional filtering needed since the field table was already curated to declared-so-far"

requirements-completed: [USHC3-02, USHC3-03, USHC3-04]

duration: ~25min
completed: 2026-07-03
---

# Phase 161 Plan 08: MA CANDIDATES-ONLY Seed Summary

**18 new MA U.S. House candidates + 6 renominated-incumbent race_candidates rows wired onto the 9 pre-existing MA races (no new elections/races), Clark/Pressley protected from duplication, 2/18 headshots uploaded.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-07-03T22:53:00-07:00 (approx)
- **Completed:** 2026-07-03T23:11:00-07:00
- **Tasks:** 3/3 completed
- **Files modified:** 4 created, 0 modified

## Accomplishments
- Authored `161-ma-generate.mts` and generated a candidates-only migration wiring 18 new MA politicians + 24 active `race_candidates` (18 new + 6 renominated incumbents: Neal/McGovern/Trahan/Auchincloss/Lynch/Keating) onto the 9 PRE-EXISTING MA races, with zero `essentials.races`/`essentials.elections` INSERTs
- Ran migration `1202_seed_ma_2026_house_candidates.sql` on prod (`kxsdzaojfaibhuzmclfq`); verified Clark (MA-5) and Pressley (MA-7) each have exactly ONE `race_candidates` row (not duplicated), 0 NULL `politician_id` and 0 duplicate `full_name` across the 9 US House races, MA race count unchanged at 9, and a re-run inserted 0 rows (idempotent)
- Ran `seed-ma-house-headshots.py` (clone of `seed-mi-house-headshots.py`) scoped to the new `-250902..-250101` MA band; uploaded 2 headshots (Tram Nguyen, Dan Koh), documented 16 honest-skips

## Task Commits

Each task was committed atomically:

1. **Task 1: Author 161-ma-generate.mts and emit the MA candidates-only migration** - `6d2ae8e2` (feat)
2. **Task 2 + 3: Run the MA migration on prod, verify no duplication, headshots** - `396cc6f8` (feat)

_Note: Task 2 involved no code changes (running an already-committed migration + verification queries), so it was folded into the Task 3 commit per the task_commit_protocol (nothing to stage after Task 2 alone)._

## Files Created/Modified
- `backend/scripts/161-ma-generate.mts` - Generator: emits the MA field, external_id assignment (`-(25*10000 + cd*100 + seq)`), the migration SQL, and the reconciliation CSV
- `backend/migrations/1202_seed_ma_2026_house_candidates.sql` - Candidates-only migration: UPDATE 9 races to PROVISIONAL description, INSERT 18 new politicians, INSERT 24 race_candidates (all guarded by NOT EXISTS)
- `backend/scripts/seed-ma-house-headshots.py` - Headshot pipeline clone with one MA BANDS entry over the new external_id band only
- `backend/data/seed-ma-2026-house/161-08-ma-reconciliation.csv` - Full reconciliation: 18 NEW rows + 6 REUSE-ADD-ROW incumbent rows + 2 ALREADY-WIRED-SKIP rows (Clark/Pressley) + 1 RETIRED-NO-ROW row (Moulton)

## Decisions Made
- Migration numbered 1202 after re-checking `ls backend/migrations | sort | tail -5` live (high-water mark was 1201, not the plan's assumed 1193)
- Used `NOT EXISTS (... rc.race_id = X AND rc.politician_id = p.id)` guards throughout rather than the VA-precedent's `lower(full_name)` guard, since the (race_id, politician_id) tuple is the actual natural key and gives a stronger structural duplication guarantee for the Clark/Pressley protection
- No additional filtering of the field table's `new_records_needed` column was needed for the Aug-25 independent-filing gate (Pitfall 3): the 160-field-table-p161.csv MA rows were already curated to declared-so-far candidates (18 total matched the plan's ceiling exactly)

## Deviations from Plan

None - plan executed exactly as written. Migration number (1202 vs the plan's placeholder 1193) was already flagged as an expected re-check in the plan's `<critical_migration_number>` instructions, not a deviation.

## Issues Encountered

None. The pre-migration collision re-check (`SELECT external_id FROM essentials.politicians WHERE external_id BETWEEN -250999 AND -250001`) returned 0 rows, confirming the band was collision-free before authoring.

One incidental finding during the NULL-politician_id verification query: 4 pre-existing `race_candidates` rows with NULL `politician_id` exist on MA state-legislative district `25D27` (created 2026-05-17, unrelated to this migration and out of scope for this plan — logged here for visibility, not modified).

## Known Stubs

None. All 18 new candidates have `race_candidates` rows on their correct district; the 16 headshot honest-skips are documented in `backend/scripts/_ma-house-headshot-results.json` (gitignored per `backend/scripts/_*` convention) with specific skip reasons (no-Wikipedia-candidate-page, historical-homonym, image-too-small, description-not-political).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- MA's 9 races now surface their declared-so-far field (Neal/Whalen/Milleron on MA-1; McGovern alone on MA-2; Trahan/Grossi on MA-3; Auchincloss/Poulos/Stalcup on MA-4; Clark/Samman/Paz on MA-5; the 7-candidate MA-6 open-seat field with no incumbent; Pressley alone on MA-7; Lynch/Roath/Burke on MA-8; Keating/Swallow/MacAllister on MA-9) — ready for federal-24 stance research in 161-10
- MA independent filing remains open to 2026-08-25; Phase 167's MA cluster (week of Aug 31 - Sep 6) must reconcile any late-declared independents not covered by this candidates-only slice
- No blockers for downstream plans

---
*Phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca*
*Completed: 2026-07-03*

## Self-Check: PASSED

All created files verified present on disk; both task commits (`6d2ae8e2`, `396cc6f8`) verified present in git log.
