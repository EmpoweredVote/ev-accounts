---
phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
plan: 02
subsystem: database
tags: [postgres, supabase, elections, house-candidates, headshots, wikipedia]

# Dependency graph
requires:
  - phase: 160-field-resolution-stance-gap-diagnostic
    provides: 160-field-table-p161.csv (AZ field), 160-negative-id-audit.csv (0-collision confirmation)
provides:
  - AZ 2026 Statewide General election + 9 provisional U.S. House races, wired to existing NATIONAL_LOWER offices
  - 32 new AZ politicians + 39 active race_candidates (7 incumbents reused, 2 open seats)
  - 4 new AZ candidate headshots (28 documented honest-skips)
affects: [161-03 (AZ stances), 166 (consolidated gate)]

# Tech tracking
tech-stack:
  added: []
  patterns: [per-state .mts generator -> migration SQL, external_id -(fips*10000+cd*100+seq) for new challengers, BANDS-parameterized headshot script]

key-files:
  created:
    - backend/scripts/161-az-generate.mts
    - backend/migrations/1187_seed_az_2026_house_elections_races.sql
    - backend/migrations/1188_seed_az_2026_house_candidates.sql
    - backend/scripts/seed-az-house-headshots.py
    - backend/data/seed-az-2026-house/161-02-az-reconciliation.csv
  modified: []

key-decisions:
  - "AZ new-challenger external_id band: -(4*10000+cd*100+seq), range -40101..-40901; live collision re-check against prod confirmed 0 collisions before authoring (per 160-01 'never trust a computed band' lesson)"
  - "AZ-1 (Schweikert) and AZ-5 (Biggs) retired -> REUSE-NO-ROW: politician record untouched, no active race_candidates row created (open-seat convention, mirrors MI-10/MI-11 from Phase 159)"
  - "Migration numbers 1187/1188 selected after re-checking ls backend/migrations (max was 1186; no collision with parallel sessions)"

patterns-established:
  - "AZ headshot BANDS entry: (-40901, -40101, 'Arizona', 'AZ 2026 Statewide General') — brackets exactly the new-challenger band, excludes incumbents -4001..-4009"

requirements-completed: [USHC3-02, USHC3-03, USHC3-04]

# Metrics
duration: 32min
completed: 2026-07-03
---

# Phase 161 Plan 02: AZ End-to-End Seeding Summary

**AZ 2026 US House field seeded end-to-end (migrations 1187/1188): 9 provisional races, 32 new politicians, 39 active race_candidates, 4 headshots — live on prod before the Jul-21 primary (D-02 hard target met).**

## Performance

- **Duration:** ~32 min
- **Started:** 2026-07-03T11:03:40-07:00 (branch base)
- **Completed:** 2026-07-03T11:35:22-07:00
- **Tasks:** 3 completed
- **Files created:** 5

## Accomplishments
- Authored `161-az-generate.mts`, cloned from the proven `159-mi-generate.mts` pattern, producing two idempotent migrations from a typed field array validated against `160-field-table-p161.csv`
- Applied both migrations to production (`kxsdzaojfaibhuzmclfq`): 1 election, 9 races, 32 new politicians, 39 active race_candidates — re-ran both migrations to confirm 0-row idempotent re-apply
- Ran the AZ headshot pipeline (clone of `seed-mi-house-headshots.py`), uploading 4 new headshots and documenting 28 honest-skips with reasons in `_az-house-headshot-results.json`

## Task Commits

Each task was committed atomically:

1. **Task 1: Author 161-az-generate.mts and emit the two AZ migrations** - `9dd87524` (feat)
2. **Task 2: Run the AZ migrations on prod and verify surfacing** - no file changes (pure DB execution; verified inline, see below)
3. **Task 3: Headshots for the 32 new AZ candidates** - `a9337962` (feat)

_Note: Task 2 produced no new/modified files (migration execution + read-only SQL verification against prod), so there is no separate commit for it — its results are documented below and were verified live against production._

## Files Created/Modified
- `backend/scripts/161-az-generate.mts` - deterministic AZ field -> migration SQL generator; self-check prints dup/collision/per-district counts
- `backend/migrations/1187_seed_az_2026_house_elections_races.sql` - AZ 2026 Statewide General election + 9 provisional races
- `backend/migrations/1188_seed_az_2026_house_candidates.sql` - 32 new politicians + 39 active race_candidates
- `backend/scripts/seed-az-house-headshots.py` - clone of `seed-mi-house-headshots.py` with AZ `BANDS` entry
- `backend/data/seed-az-2026-house/161-02-az-reconciliation.csv` - full 41-row decision table (32 NEW, 7 REUSE, 2 REUSE-NO-ROW)

## Decisions Made
- External_id scheme confirmed collision-free live (0 collisions across all 32 candidates) immediately before authoring, per the standing "never trust a computed band" discipline from Phase 160-01.
- Migration numbers 1187/1188 chosen after a fresh `ls backend/migrations | sort` re-check (max was 1186 at author time; matches the plan's pre-assigned numbers exactly, no parallel-session collision).
- Incumbent names for REUSE rows taken from `160-field-table-p161.csv`'s `incumbent_name` column (the canonical DB `full_name` values) rather than the shorter names used in some `general_candidates` listings (e.g., "Elijah Crane" not "Eli Crane"), to keep the `race_candidates.full_name` snapshot consistent with the existing `politicians` record.

## Deviations from Plan

None - plan executed exactly as written. One environment-setup note (not a plan deviation): this worktree had no `backend/.env` or `backend/node_modules` (both gitignored, not present in a fresh worktree checkout). A symlink to the main repo's `node_modules` and a copy of the main repo's `.env` were created locally to run the generator/migration/headshot scripts — both remain untracked (confirmed via `git status`) and were not committed.

## Issues Encountered
- Headshot find-rate was low (4/32 = 12.5%): most of AZ's down-ballot primary challengers have no dedicated Wikipedia biographical page yet (the search resolver falls back to the general "2026 United States House of Representatives elections in Arizona" article, which the wrong-person guard correctly rejects as `not-candidate-person-page`). Two additional notable-but-skipped cases: Jay Feely (former NFL kicker; Wikipedia describes him as "football player and sportscaster", not politically-keyword-matched) and Zuhdi Jasser / Kai Newkirk (described as "activist"/"doctor", not politically-keyword-matched). Per the plan's explicit instruction ("do NOT weaken the first-name-mismatch rejection... guard intact"), these were left as honest-skips rather than loosening `POLITICAL_KW` — consistent with the project's standing headshot-guard discipline (Bouchard wrong-person lesson).

## User Setup Required

None - no external service configuration required. (Production DB writes only; no new environment variables.)

## Next Phase Readiness

- AZ elections + races + candidates + headshots are live on prod, verified idempotent, ready for 161-03 (AZ stances).
- `essentials.offices.politician_id` was never touched for AZ — reps feed unaffected by this plan (only `elections`/`races`/`politicians`/`race_candidates` were written).
- 28 AZ candidates still need a headshot decision at gate time (161-XX gate script should treat them as pinned honest-skips per `_az-house-headshot-results.json`, not re-attempt automatically without new evidence).

---
*Phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca*
*Completed: 2026-07-03*
