---
phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
plan: 04
subsystem: database
tags: [postgres, supabase, elections, house-candidates, headshots, wikipedia, top-two]

# Dependency graph
requires:
  - phase: 160-field-resolution-stance-gap-diagnostic
    provides: 160-field-table-p161.csv (WA field), 160-negative-id-audit.csv (0-collision confirmation)
  - phase: 161-02
    provides: migration numbers 1187/1188 already claimed (AZ) -- WA claims 1189/1190 next
provides:
  - WA 2026 Statewide General election + 10 provisional U.S. House races, wired to existing NATIONAL_LOWER offices
  - 60 new WA politicians + 69 active race_candidates (9 incumbents reused, WA-4 Newhouse retired -> REUSE-NO-ROW)
  - 3 new WA candidate headshots (57 documented honest-skips)
affects: [161-05 (WA stances), 166 (consolidated gate), 167 (WA top-two post-primary cull -- NOT standard nominee-per-party logic, see breadcrumb below)]

# Tech tracking
tech-stack:
  added: []
  patterns: [per-state .mts generator -> migration SQL, external_id -(fips*10000+cd*100+seq) for new challengers, BANDS-parameterized headshot script]

key-files:
  created:
    - backend/scripts/161-wa-generate.mts
    - backend/migrations/1189_seed_wa_2026_house_elections_races.sql
    - backend/migrations/1190_seed_wa_2026_house_candidates.sql
    - backend/scripts/seed-wa-house-headshots.py
    - backend/data/seed-wa-2026-house/161-04-wa-reconciliation.csv
  modified: []

key-decisions:
  - "WA new-challenger external_id band: -(53*10000+cd*100+seq), range -530101..-531005; live collision re-check against prod confirmed 0 collisions before authoring (per 160-01 'never trust a computed band' lesson)"
  - "WA-4 (Dan Newhouse) RETIRED -> REUSE-NO-ROW: politician record untouched, no active race_candidates row created (open-seat convention, mirrors AZ-1/AZ-5 from 161-02 and MI-10/MI-11 from Phase 159)"
  - "WA is top-two ballot_system but seeded EXACTLY like any other late-primary state -- one race per district, ALL qualified candidates from all parties active. No WA-specific top-two logic invented in the generator (161-RESEARCH Pitfall 4); the top-two cull is explicitly Phase 167's concern, flagged as a breadcrumb for that future plan"
  - "Migration numbers 1189/1190 selected after re-checking ls backend/migrations (max was 1188 after 161-02's AZ migrations; no collision with parallel sessions)"

patterns-established:
  - "WA headshot BANDS entry: (-531005, -530101, 'Washington', 'WA 2026 Statewide General') -- brackets exactly the new-challenger band, excludes incumbents -53001..-53010"

requirements-completed: [USHC3-02, USHC3-03, USHC3-04]

# Metrics
duration: 28min
completed: 2026-07-03
---

# Phase 161 Plan 04: WA End-to-End Seeding Summary

**WA 2026 US House field seeded end-to-end (migrations 1189/1190): 10 provisional races, 60 new politicians, 69 active race_candidates, 3 headshots -- live on prod before the Aug-4 top-two primary, seeded as a standard late-primary state (no WA-specific top-two logic).**

## Performance

- **Duration:** ~28 min
- **Tasks:** 3 completed
- **Files created:** 5

## Accomplishments
- Authored `161-wa-generate.mts`, cloned from the proven `161-az-generate.mts` pattern, producing two idempotent migrations from a typed 70-row field array (10 incumbents + 60 new) validated against `160-field-table-p161.csv`
- Live-re-checked the computed external_id band (-530101..-531005) against prod immediately before authoring migration SQL: 0 collisions
- Applied both migrations to production (`kxsdzaojfaibhuzmclfq`): 1 election, 10 races, 60 new politicians, 69 active race_candidates -- re-ran both migrations to confirm 0-row idempotent re-apply (129 `INSERT 0 0` on second run)
- Ran the WA headshot pipeline (clone of `seed-az-house-headshots.py`), uploading 3 new headshots and documenting 57 honest-skips with reasons in `_wa-house-headshot-results.json`

## Task Commits

Each task was committed atomically:

1. **Task 1: Author 161-wa-generate.mts and emit the two WA migrations** - `0700ecb6` (feat)
2. **Task 2: Run the WA migrations on prod and verify surfacing** - no file changes (pure DB execution; verified inline, see below)
3. **Task 3: Headshots for the 60 new WA candidates** - `94d5ec1c` (feat)

_Note: Task 2 produced no new/modified files (migration execution + read-only SQL verification against prod), so there is no separate commit for it -- its results are documented below and were verified live against production, matching the 161-02 (AZ) precedent._

## Files Created/Modified
- `backend/scripts/161-wa-generate.mts` - deterministic WA field -> migration SQL generator; self-check prints dup/collision/per-district counts
- `backend/migrations/1189_seed_wa_2026_house_elections_races.sql` - WA 2026 Statewide General election + 10 provisional races
- `backend/migrations/1190_seed_wa_2026_house_candidates.sql` - 60 new politicians + 69 active race_candidates
- `backend/scripts/seed-wa-house-headshots.py` - clone of `seed-az-house-headshots.py` with WA `BANDS` entry
- `backend/data/seed-wa-2026-house/161-04-wa-reconciliation.csv` - full 70-row decision table (60 NEW, 9 REUSE, 1 REUSE-NO-ROW)

## Decisions Made
- External_id scheme confirmed collision-free live (0 collisions across the full -530101..-531005 band) immediately before authoring, per the standing "never trust a computed band" discipline from Phase 160-01.
- Migration numbers 1189/1190 chosen after a fresh `ls backend/migrations | sort` re-check (max was 1188 at author time -- AZ's 161-02 migrations -- matches the plan's pre-assigned numbers exactly, no parallel-session collision).
- WA is `ballot_system=top-two` per the field table but this plan deliberately does NOT invent any top-two-specific seeding logic -- the full qualified field (all parties, all declared candidates) is seeded exactly like any other late-primary state. This is intentional per 161-RESEARCH Pitfall 4: Phase 167's WA cluster must apply "top two vote-getters advance regardless of party" logic at cull time, NOT the standard "one nominee per party" logic used elsewhere. **Breadcrumb for Phase 167:** do not naively prune to one Democrat + one Republican per WA district; determine the actual top-two finishers from primary results.
- Incumbent names for REUSE rows taken from `160-field-table-p161.csv`'s `incumbent_name` column (canonical DB `full_name` values), consistent with the 161-02 AZ precedent.

## Deviations from Plan

None - plan executed exactly as written. One environment-setup note (not a plan deviation, matches 161-02's precedent): this worktree had no `backend/.env` or `backend/node_modules` (both gitignored, not present in a fresh worktree checkout). A symlink to the main repo's `node_modules` and a copy of the main repo's `.env` were created locally to run the generator/migration/headshot scripts -- both remain untracked (confirmed via `git status`) and were not committed.

## Issues Encountered
- Headshot find-rate was low (3/60 = 5%): most of WA's down-ballot late-primary challengers have no dedicated Wikipedia biographical page yet (the search resolver falls back to the general "2026 United States House of Representatives elections in Washington" article, which the wrong-person guard correctly rejects as `not-candidate-person-page`). Two notable historical-homonym rejections correctly caught by the existing guard: Lawrence Kellogg resolved to a pre-1940 statesman ("american lawyer and statesman (1856-1937)") and was correctly skipped via the historical-year check; Jerrod Sessler and Carmela Conroy resolved to unrelated Wikipedia pages ("american racing driver", "american diplomat") and were correctly skipped via the political-keyword filter. Per the plan's explicit instruction (guard intact, do not weaken), these were left as honest-skips rather than loosening `POLITICAL_KW` or the historical-year threshold.

## User Setup Required

None - no external service configuration required. (Production DB writes only; no new environment variables.)

## Next Phase Readiness

- WA elections + races + candidates + headshots are live on prod, verified idempotent, ready for 161-05 (WA stances).
- `essentials.offices.politician_id` was never touched for WA -- reps feed unaffected by this plan (only `elections`/`races`/`politicians`/`race_candidates` were written).
- 57 WA candidates still need a headshot decision at gate time (161-XX gate script should treat them as pinned honest-skips per `_wa-house-headshot-results.json`, not re-attempt automatically without new evidence).
- **Phase 167 breadcrumb (WA top-two cull):** WA's Aug-4 top-two primary sends the top two vote-getters overall to November, regardless of party. Phase 167's WA cluster plan must NOT apply the standard "confirm each party's nominee" logic used for every other state in this milestone -- it must instead determine and retain the actual top-two finishers per district from official primary results.

---
*Phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca*
*Completed: 2026-07-03*

## Self-Check: PASSED

All created files verified present on disk; both task commits (`0700ecb6`, `94d5ec1c`) verified present in git log.
