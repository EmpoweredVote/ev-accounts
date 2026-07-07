---
phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
plan: 06
subsystem: database
tags: [postgres, supabase, elections, house-candidates, headshots, wikipedia, redistricting, tennessee]

# Dependency graph
requires:
  - phase: 160-field-resolution-stance-gap-diagnostic
    provides: 160-field-table-p161.csv (TN field), 160-incumbent-map.csv (TN incumbent politician_ids)
  - phase: 161-01
    provides: 161-tn-correspondence-audit.md (severe geo_id list, 4704/4705/4706/4708/4709)
  - phase: 161-04
    provides: migration numbers 1189/1190 already claimed (WA) -- TN claims 1196/1197 next (live ls re-check found max 1195)
provides:
  - TN 2026 Statewide General election + a dedicated, non-general, past-dated "TN 2026 Congressional Redistricting - Polygon Pending" election
  - 9 severity-routed provisional U.S. House races (4 general, 5 withheld), all wired to existing NATIONAL_LOWER offices, office_id never null
  - 73 new TN politicians + 80 active race_candidates (7 incumbents reused, TN-6 Rose retired + TN-9 Cohen redistricted -> REUSE-NO-ROW)
  - 3 new TN candidate headshots (70 documented honest-skips)
affects: [161-07 (TN stances), 166 (consolidated gate), 164.1 (future polygon-refresh phase that flips the withheld election_id back to general once new-map polygons land)]

# Tech tracking
tech-stack:
  added: []
  patterns: [per-state .mts generator -> migration SQL, external_id -(fips*10000+cd*100+seq) for new challengers, BANDS-parameterized headshot script, election_id-substitution withholding for stale-polygon districts]

key-files:
  created:
    - backend/scripts/161-tn-generate.mts
    - backend/migrations/1196_seed_tn_2026_house_elections_races.sql
    - backend/migrations/1197_seed_tn_2026_house_candidates.sql
    - backend/scripts/seed-tn-house-headshots.py
    - backend/data/seed-tn-2026-house/161-06-tn-reconciliation.csv
  modified: []

key-decisions:
  - "Severe geo_id set consumed verbatim from 161-tn-correspondence-audit.md: 4704, 4705, 4706, 4708, 4709 (5 of 9 TN districts) -- larger than the RESEARCH.md's working assumption of possibly-just-TN-9"
  - "Withholding mechanism: severe races' election_id points at a dedicated 'TN 2026 Congressional Redistricting - Polygon Pending' election (election_type='special', election_date='2026-05-07', >30 days in the past as of 2026-07-03) so electionService.ts's ELECTION_VISIBILITY_WINDOW evaluates false for them. office_id is NEVER null -- always the district's existing old-CD NATIONAL_LOWER office. essentials.offices is never touched by either migration."
  - "race_candidates inserts join by district geo_id directly (not by election name), so one code path correctly wires both severe and non-severe race_candidates without duplicated insert logic"
  - "TN-6 John W. Rose (RETIRED) and TN-9 Steve Cohen (REDISTRICTED/withdrew) -> REUSE-NO-ROW: politician records untouched, no active race_candidates row created (mirrors AZ-1/AZ-5, WA-4 convention)"
  - "TN new-challenger external_id band: -(47*10000+cd*100+seq), range -470910..-470101; live collision re-check against prod confirmed 0 collisions before authoring"
  - "Headshot script scopes targets by external_id BAND ONLY (no election-name join) -- unlike prior single-election states, TN has two elections, and severe-district candidates still need headshots even though their race is currently withheld from /elections (seeding is complete regardless of surfacing)"
  - "Migration numbers 1196/1197 selected after a fresh ls backend/migrations re-check (max was 1195, climbed past the plan's originally-assumed 1191/1192 by a parallel session's stance migrations); no collision"

patterns-established:
  - "election_id-substitution withholding: point a subset of races at a deliberately non-general, >30-day-past-dated election row to make them invisible via ELECTION_VISIBILITY_WINDOW while keeping office_id populated -- reusable for any future stale-polygon redistricting scenario"
  - "TN headshot BANDS entry: (-470910, -470101, 'Tennessee') -- band-scoped query with no election-name filter, needed whenever a state has more than one election row for its House field"

requirements-completed: [USHC3-02, USHC3-03, USHC3-04]

# Metrics
duration: ~55min
completed: 2026-07-03
---

# Phase 161 Plan 06: TN End-to-End Seeding (Severity-Routed Withholding) Summary

**TN's full 2026 US House field seeded end-to-end (migrations 1196/1197): 9 races severity-routed by the 161-01 audit (4 surface via the general election, 5 seeded-but-withheld via a dedicated past-dated "Polygon Pending" election), 73 new politicians, 80 active race_candidates, 3 headshots -- verified live that exactly the 4 non-severe districts surface on /elections and the 5 severe districts return zero, with essentials.offices/the reps feed untouched throughout.**

## Performance

- **Duration:** ~55 min
- **Tasks:** 3 completed

## Accomplishments

- Authored `161-tn-generate.mts`, cloned from the proven `161-az-generate.mts`/`161-wa-generate.mts` pattern, producing two idempotent migrations from a typed 82-row field array (9 incumbents + 73 new) validated against `160-field-table-p161.csv` TN rows and `160-incumbent-map.csv`
- Implemented the D-01b severe-district withholding mechanism exactly as specified in `161-RESEARCH.md` Pitfall 1: a second, non-general, past-dated "TN 2026 Congressional Redistricting - Polygon Pending" election row absorbs the `election_id` for the 5 severe districts' races, while `office_id` stays on the normal old-CD office for all 9 races
- Live-re-checked the computed external_id band (-470101..-470910) against prod immediately before authoring migration SQL: 0 collisions; also confirmed 0 pre-existing TN 2026 elections/races/offices state before writing anything
- Applied both migrations to production (`kxsdzaojfaibhuzmclfq`): 2 elections, 9 races (4 general + 5 withheld), 73 new politicians, 80 active race_candidates -- re-ran both migrations to confirm 0-row idempotent re-apply (identical counts on second run)
- Ran a direct SQL replica of `electionService.ts`'s `ELECTION_VISIBILITY_WINDOW` against all 9 TN races: exactly geo_id 4701/4702/4703/4707 (the 4 non-severe districts) return a visible race; geo_id 4704/4705/4706/4708/4709 (the 5 severe districts) return zero -- confirming the withholding mechanism works end-to-end
- Confirmed every TN `essentials.offices.politician_id` is byte-for-byte unchanged from the pre-migration incumbent map (reps feed untouched)
- Ran the TN headshot pipeline (clone of `seed-mi-house-headshots.py`, band-scoped instead of election-scoped since TN has two elections), uploading 3 new headshots and documenting 70 honest-skips with reasons in `_tn-house-headshot-results.json`

## Task Commits

Each task was committed atomically:

1. **Task 1: Author 161-tn-generate.mts and emit the two TN migrations** - `3663df2e` (feat)
2. **Task 2: Run the TN migrations on prod and verify severity-routed withholding** - no file changes (pure DB execution + read-only SQL verification; documented below)
3. **Task 3: Headshots for the 73 new TN candidates** - `30543f91` (feat)

_Note: Task 2 produced no new/modified repo files (migration execution against prod + read-only SQL verification, including a direct replica of the ELECTION_VISIBILITY_WINDOW SQL), so there is no separate commit for it -- matching the 161-02 (AZ) and 161-04 (WA) precedent._

## Files Created/Modified

- `backend/scripts/161-tn-generate.mts` - deterministic TN field -> migration SQL generator; self-check prints dup/collision/per-district severity-routing summary
- `backend/migrations/1196_seed_tn_2026_house_elections_races.sql` - TN 2026 Statewide General election + withheld "Polygon Pending" election + 9 severity-routed races
- `backend/migrations/1197_seed_tn_2026_house_candidates.sql` - 73 new politicians + 80 active race_candidates (geo_id-joined, works identically for severe and non-severe races)
- `backend/scripts/seed-tn-house-headshots.py` - clone of `seed-mi-house-headshots.py` with a band-scoped (not election-scoped) TN `BANDS` entry
- `backend/data/seed-tn-2026-house/161-06-tn-reconciliation.csv` - full 82-row decision table (73 NEW, 7 REUSE, 2 REUSE-NO-ROW) with a severity column

## Decisions Made

- Severe geo_id set taken verbatim from the 161-01 audit's authoritative line ("Severe geo_id list: 4704, 4705, 4706, 4708, 4709") -- no re-derivation, no independent severity judgment made in this plan.
- Withholding mechanism implemented exactly per `161-RESEARCH.md` Pitfall 1: election_id substitution, never `office_id IS NULL`. Verified against a direct SQL replica of `electionService.ts`'s `ELECTION_VISIBILITY_WINDOW` expression rather than trusting the mechanism by inspection alone.
- race_candidates inserts join by district `geo_id` directly rather than by election name, because each TN district has exactly one race regardless of which of the two elections it's wired to -- this let one insert-generation code path correctly reach both severe and non-severe rows without branching.
- Migration numbers 1196/1197 chosen after a fresh `ls backend/migrations | sort` re-check found the live high-water mark at 1195 (a parallel session's stance migrations had climbed past the plan's originally-assumed 1191/1192) -- confirmed via the prompt's explicit warning and verified with a fresh listing before authoring.
- Headshot script departs from the AZ/WA/MI precedent by scoping strictly on external_id band with no election-name join, because TN (uniquely so far) has two elections for one state's House field and severe-district candidates must still be attempted for headshots even though their race doesn't currently surface.

## Deviations from Plan

None - plan executed exactly as written, including the exact migration numbers called out in the prompt's `<critical_migration_numbers>` guidance (1196/1197, confirmed free via live `ls` re-check). One environment-setup note (not a plan deviation, matches 161-02/161-04 precedent): this worktree had no `backend/.env` or `backend/node_modules` (both gitignored, not present in a fresh worktree checkout). A symlink to the main repo's `node_modules` and a copy of the main repo's `.env` were created locally to run the generator/migration/headshot scripts -- both remain untracked (confirmed via `git status`) and were not committed.

## Issues Encountered

- Headshot find-rate was low (3/73 = 4%): the vast majority of TN's down-ballot late-primary challengers (both general and severe-district) have no dedicated Wikipedia biographical page yet -- the search resolver falls back to generic pages like "2026 United States House of Representatives elections in Tennessee" or "John Rose (Tennessee politician)" (a different person's incumbent bio page, correctly rejected by the `not-candidate-person-page` guard). Two historical-homonym rejections correctly caught: Harold "Rocky" Jones and Richard G. Baker both resolved to pre-1940-adjacent dead historical namesakes ("american politician and businessman (1924-2008)", "american politician and diplomat (1925-2014)") and were skipped via the existing historical-year check. A few desc-not-political rejections correctly caught unrelated historical namesakes (Thomas E. Davis -> Confederate President Jefferson Davis's namesake page; Henry J. Ward, III -> unrelated US President page; James A. Johnson -> unrelated US President page). The 3 successful uploads (Justin J. Pearson, London Lamar -- both sitting TN state legislators running in the severe/withheld TN-9; Vincent Dixie -- a sitting TN state legislator running in non-severe TN-7) all have well-maintained Wikipedia biographical pages with free (CC-BY / CC-BY-SA) licensed portraits. Per the plan's explicit instruction (guard intact, do not weaken), all 70 non-matches were left as documented honest-skips rather than loosening `POLITICAL_KW` or the historical-year threshold.

## User Setup Required

None - no external service configuration required. (Production DB writes only; no new environment variables.)

## Next Phase Readiness

- TN elections + races + candidates + headshots are live on prod, verified idempotent (re-ran both migrations, identical row counts on second pass), ready for 161-07 (TN stances).
- `essentials.offices.politician_id` was never touched for TN -- reps feed unaffected by this plan (only `elections`/`races`/`politicians`/`race_candidates` were written); verified all 9 TN offices still point at their pre-migration incumbent politician_id.
- Withholding verified end-to-end: a direct SQL replica of `electionService.ts`'s `ELECTION_VISIBILITY_WINDOW` returns exactly 4 visible TN races (geo_id 4701/4702/4703/4707) and 0 for the 5 severe districts (geo_id 4704/4705/4706/4708/4709). 161-11's gate/coordinate-smoke assertions should find this state already correct.
- 70 TN candidates still need a headshot decision at gate time (161-XX gate script should treat them as pinned honest-skips per `_tn-house-headshot-results.json`, not re-attempt automatically without new evidence).
- **Phase 164.1 breadcrumb (polygon refresh):** once new-map TN district polygons/geofences land in `essentials.districts`/`essentials.geofence_boundaries`, the 5 severe races' `election_id` should be flipped from the withheld "Polygon Pending" election back to (or a fresh) "TN 2026 Statewide General" row -- a one-line `UPDATE essentials.races SET election_id = ... WHERE id IN (...)` per the plan's success criteria. No other data needs to change (office_id, race_candidates, headshots all already correct for the new map).

---
*Phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca*
*Completed: 2026-07-03*

## Self-Check: PASSED

All 5 created files verified present on disk; both task commits (`3663df2e`, `30543f91`) verified present in git log.
