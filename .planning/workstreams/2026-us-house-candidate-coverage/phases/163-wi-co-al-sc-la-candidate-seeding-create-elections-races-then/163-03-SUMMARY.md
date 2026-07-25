---
phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then
plan: 03
subsystem: elections-data-seeding
tags: [colorado, us-house-2026, candidate-seeding, headshots, pure-data, incumbent-lost-primary]
dependency-graph:
  requires: [160-field-resolution-stance-gap-diagnostic]
  provides: [co-2026-house-election, co-2026-house-races, co-2026-house-candidates, co-headshot-pipeline]
  affects: [163-08-co-stances, 166-consolidated-verify]
tech-stack:
  added: []
  patterns: ["vanilla single-election new-election seed (clone of 163-wi-generate.mts)", "incumbent-lost-primary REUSE-NO-ROW transition (new variant of the retired/different-office REUSE-NO-ROW pattern)", "band-scoped headshot ingestion (clone of seed-wi-house-headshots.py)"]
key-files:
  created:
    - backend/scripts/163-co-generate.mts
    - backend/migrations/1222_seed_co_2026_house_elections_races.sql
    - backend/migrations/1223_seed_co_2026_house_candidates.sql
    - backend/scripts/seed-co-house-headshots.py
    - backend/data/seed-co-2026-house/163-03-co-reconciliation.csv
  modified: []
decisions:
  - "Diana DeGette (CO-1, lost her June-30 primary to Melat Kiros) treated as REUSE-NO-ROW: her politicians/offices rows and 19 existing stances are left completely untouched, but she is NOT wired into the new CO-1 race_candidates row — a third distinct incumbent-transition pattern (retired / different-office / lost-primary), all resolved via vacate:true rather than the raw office->politician_id join"
  - "CO's general field authored as decided (no PROVISIONAL prefix) since CO's primaries were held 2026-06-30 — description text follows the 162-07 IN 'Confirmed nominees' convention, not the WI/AZ/WA/MN 'PROVISIONAL: ...' convention"
requirements-completed: [USHC3-02, USHC3-03, USHC3-04]
metrics:
  duration: ~20min
  completed: 2026-07-05
---

# Phase 163 Plan 03: Colorado 2026 US House Seed Summary

Seeded Colorado's full 2026 US House field (8 districts, 9 new candidate records) onto prod via the vanilla single-election pattern (CO is not redistricted, no withholding, decided field), correctly excluding incumbent Diana DeGette from CO-1 after her June-30 primary loss while leaving her existing record and stance history untouched.

## Performance

- **Duration:** ~20 min
- **Tasks:** 3 completed
- **Files modified:** 5 created

## Accomplishments
- 1 `essentials.elections` row ("CO 2026 Statewide General", 2026-11-03, decided/no-PROVISIONAL) + 8 `essentials.races` rows wired to CO's existing NATIONAL_LOWER US House offices (geo_ids 0801-0808), all `office_id NOT NULL`
- 9 new `essentials.politicians` records (external_id band -80101..-80801) + 16 active `essentials.race_candidates` rows (9 new + 7 renominated incumbents reused by external_id)
- CO-1's special case handled correctly: Diana DeGette (lost her primary to Melat Kiros) excluded entirely from the new race's candidate set; CO-1's general field is exactly Melat Kiros (D) + Christy Peterson (R), 2 candidates, both NEW records
- Headshot ingestion: 2 verified free-license uploads (Manny Rutinel CO-8, Melat Kiros CO-1), 7 documented honest-skips

## Task Commits

Each task was committed atomically:

1. **Task 1: Fresh FIPS-08 collision check + DeGette exclusion confirmation** - no commit (pure verification task, matches WI-02/MN-05 precedent)
2. **Task 2: Generate + apply CO elections/races + candidates migrations** - `2f2657f5` (feat)
3. **Task 3: CO headshots (band-scoped)** - `70862744` (feat)

## Files Created/Modified
- `backend/scripts/163-co-generate.mts` - Deterministic field->SQL generator (clone of 163-wi-generate.mts); FIPS=08, 8 districts, INC_EXT map with DeGette vacate:true, 9-record FIELD array
- `backend/migrations/1222_seed_co_2026_house_elections_races.sql` - CO 2026 Statewide General election + 8 races on existing offices, decided-field description (no PROVISIONAL prefix)
- `backend/migrations/1223_seed_co_2026_house_candidates.sql` - 9 new politicians + 16 active race_candidates (9 new + 7 reused incumbents; DeGette excluded)
- `backend/scripts/seed-co-house-headshots.py` - Band-scoped headshot ingestion (clone of seed-wi-house-headshots.py), BANDS={'CO': (-80899, -80101, 'Colorado')}, all guards intact incl. the 163-02 foreign-nationality guard
- `backend/data/seed-co-2026-house/163-03-co-reconciliation.csv` - Full 17-row CO candidate reconciliation (9 NEW, 7 REUSE, 1 REUSE-NO-ROW = DeGette)

## Decisions Made

- **DeGette's lost-primary transition (Pitfall 3 from research):** Used the field table's `nominee_status=lost-primary` signal (not the raw `office.politician_id` join, which still points at DeGette as the sitting Rep) to drive `vacate:true` on CO-1's incumbent row. This produces the same `REUSE-NO-ROW` mechanic already proven for retirements (WI-7 Tiffany, AZ-1/5) and different-office moves (MN-2 Craig), extending it to a third transition type: incumbent lost their own primary but remains in office until the term ends. DeGette's `essentials.politicians`/`essentials.offices` rows and her 19 `inform.politician_answers` rows were verified untouched before and after the migration (19/19).
- **Decided-field description text:** Followed the 162-07 IN "Confirmed nominees" convention (`'Confirmed nominees (primary decided 2026-06-30)'`) rather than the PROVISIONAL-prefixed convention used for WI/AZ/WA/MN, since CO's primary is already fully decided (per 163-RESEARCH.md's Per-State Audit Table).

## Deviations from Plan

None - plan executed exactly as written. Both migrations applied cleanly on the first attempt, all verification queries matched expected counts, and headshot ingestion required no guard changes (the WI-established `_FOREIGN_NATIONALITY` guard was carried forward unchanged with no new incidents).

## Known Stubs

None — all 9 new candidate records are fully wired into `race_candidates` with real names/sources; headshots are either a verified upload or a documented honest-skip (no placeholder/empty values).

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced. The DeGette exclusion is the plan's own named threat (T-163-03-02) and was mitigated exactly as specified (vacate:true driven by the field-table signal, verified via the 163-11 gate's future assertion).

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification Results

- CO races: 8 total under "CO 2026 Statewide General", all `office_id NOT NULL` (verify query returned `0|2` — 0 null office_ids, 2 CO-1 active candidates)
- CO-1 race_candidates: exactly 2 rows, Melat Kiros + Christy Peterson, both `is_incumbent=false`; DeGette absent
- DeGette (610bb358-bae9-4ce8-beaf-a33a27d5ba49): `inform.politician_answers` count unchanged at 19 (verified before and after migration)
- 9 new politicians confirmed in the -80899..-80101 band; 0 duplicate `full_name` across all 16 active CO race_candidates
- Re-running both migrations (1222, 1223) confirmed idempotent (0-row no-op on every INSERT)
- Headshots: 2 politician_images rows in the CO new-candidate band (Rutinel, Kiros); 7 documented honest-skips in `_co-house-headshot-results.json` (gitignored)

## Next Phase Readiness

CO's full 2026 House field is seeded on prod, decided general field surfacing on `/elections`, DeGette correctly excluded from CO-1 while her record stays intact — ready for 163-08 (CO stance research, 9 new-candidate targets).

---
*Phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then*
*Completed: 2026-07-05*

## Self-Check: PASSED

- FOUND: backend/scripts/163-co-generate.mts
- FOUND: backend/migrations/1222_seed_co_2026_house_elections_races.sql
- FOUND: backend/migrations/1223_seed_co_2026_house_candidates.sql
- FOUND: backend/scripts/seed-co-house-headshots.py
- FOUND: backend/data/seed-co-2026-house/163-03-co-reconciliation.csv
- FOUND commit 2f2657f5 (CO seed migrations)
- FOUND commit 70862744 (CO headshots)
