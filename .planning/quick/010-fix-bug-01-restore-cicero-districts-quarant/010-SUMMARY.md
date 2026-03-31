---
phase: quick-010
plan: 01
subsystem: database
tags: [essentials, politicians, districts, cicero, cal_access, geofence, postgresql]

# Dependency graph
requires:
  - phase: quick-009
    provides: district staleness cron (context for why districts matter)
provides:
  - "76,332 CAL Access committee records quarantined (is_active = false)"
  - "43 essentials.districts rows restored, resolving FK orphans for 54 CA Cicero politicians"
  - "All 54 politicians visible to geofence queries again"
affects: [essentials-service, representatives/me, candidates/search, geofence queries]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Soft quarantine: set is_active = false filtered by source column, never touch other sources"
    - "District restoration: insert rows using the orphaned UUID (offices reference it), populate geo_id from geofence_boundaries FIPS code"

key-files:
  created:
    - backend/scripts/restore-districts.sql
  modified: []

key-decisions:
  - "Quarantine filter: source = 'cal_access_discovery' only — NOT data_source IS NULL (1,302 legit politicians also have null data_source)"
  - "District geo_id: use city FIPS code (G4110 geofence boundary) not OCD division string — all 15 affected cities have G4110 boundaries loaded"
  - "Huntington Beach: no prior LOCAL district existed in essentials.districts; created new row with geo_id 0636000 (confirmed G4110 boundary exists)"
  - "Hector Sosa (Downey Mayor): office title is Mayor so district_type set to LOCAL_EXEC, matching pattern of other Mayors in districts table"
  - "Multiple district UUIDs per city: Cicero created one district row per council member (not one per city); all reference the same city geo_id so geofence intersection works correctly"

patterns-established:
  - "Data-only bug fix: production SQL via DATABASE_URL psql, no application code changes"
  - "restore-districts.sql committed to backend/scripts/ as permanent audit trail"

# Metrics
duration: 10min
completed: 2026-03-30
---

# Quick Task 010: BUG-01 Fix — CAL Access Quarantine + Cicero District Restoration Summary

**76,332 CAL Access committee records quarantined and 43 deleted district rows restored, making 54 CA city council politicians visible to geofence queries again**

## Performance

- **Duration:** 10 min
- **Started:** 2026-03-30T16:49:36Z
- **Completed:** 2026-03-30T16:59:49Z
- **Tasks:** 2
- **Files modified:** 1 (restore-districts.sql created)

## Accomplishments

- Quarantined 76,332 `cal_access_discovery` politicians (set `is_active = false`); zero remain active
- Identified 54 active Cicero politicians across 15 CA cities with orphaned `offices.district_id` FKs
- Inserted 43 district rows using the exact orphaned UUIDs, mapped to correct city FIPS geo_ids
- All 54 politicians now join through `essentials.districts` and appear in geofence intersection queries
- Huntington Beach gets its first LOCAL district entry (geo_id `0636000`, boundary confirmed)

## Task Commits

1. **Task 1: Quarantine CAL Access committee records** - `b0eb18b` (fix)
2. **Task 2: Restore deleted district rows for 54 Cicero politicians** - `82146cf` (fix)

**Plan metadata:** [pending docs commit]

## Files Created/Modified

- `backend/scripts/restore-districts.sql` — 43-row INSERT statement; permanent audit trail of the restoration

## Decisions Made

- **Quarantine filter**: `source = 'cal_access_discovery'` only — the plan explicitly warned against `data_source IS NULL` because 1,302 legitimate politicians also have null data_source. Strict source filter used.
- **geo_id selection**: Used city FIPS codes (`0636000` for Huntington Beach, `0608954` for Burbank, etc.) rather than OCD division strings. All 15 cities confirmed to have `G4110` geofence boundaries loaded. OCD-based geo_ids (like Glendale's `ocd-division/.../council_district:0`) don't have corresponding geofence boundaries, so FIPS is the correct choice.
- **Huntington Beach**: No existing LOCAL district in `essentials.districts`. Geo_id `0636000` confirmed in `geofence_boundaries` with `G4110` mtfcc. Created new row — this is not a guess, it's a confirmed boundary.
- **Hector Sosa (Downey Mayor)**: His orphaned district UUID `22ebdde5` was set to `district_type = 'LOCAL_EXEC'` since his title is "Mayor", matching the pattern of other mayoral districts (e.g., `Downey Mayor` row with `LOCAL_EXEC`). Other Downey council members were set to `LOCAL`.
- **Multiple UUIDs per city**: Cicero creates one district row per politician (not one per city). This results in multiple distinct UUIDs for the same city. All are restored with the same geo_id — geofence intersection correctly returns all politicians for that boundary.

## Deviations from Plan

None — plan executed exactly as written. The investigative approach (inspect schema → audit → infer → insert → verify) was followed in full sequence.

## Issues Encountered

- Shell quoting prevented inline multi-line `psql -c` with single quotes in SQL values. Resolved by writing SQL to `backend/scripts/restore-districts.sql` and executing with `psql -f`.
- Huntington Beach has no pre-existing LOCAL district — the plan's Step 4b approach (cross-reference existing districts for same state+type) could not supply a reference UUID. However, geo_id was reliably inferred from geofence_boundaries directly (`0636000` confirmed with `G4110` boundary).

## District Restoration Map

| City | geo_id | Orphaned UUIDs | Politicians |
|------|--------|----------------|-------------|
| Burbank | 0608954 | 1 | 3 |
| Downey | 0619766 | 3 | 3 |
| El Monte | 0622230 | 2 | 2 |
| Glendale | 0630000 | 1 | 4 |
| Huntington Beach | 0636000 | 1 | 7 |
| Inglewood | 0636546 | 4 | 4 |
| Lancaster | 0640130 | 1 | 1 |
| Long Beach | 0643000 | 8 | 8 |
| Norwalk | 0652526 | 1 | 1 |
| Palmdale | 0655156 | 3 | 3 |
| Pasadena | 0656000 | 5 | 5 |
| Pomona | 0658072 | 3 | 3 |
| Santa Clarita | 0669088 | 3 | 3 |
| Torrance | 0680000 | 4 | 4 |
| West Covina | 0684200 | 3 | 3 |
| **Total** | | **43** | **54** |

## Unresolvable Cases

None. All 43 district UUIDs were resolved. All 15 cities have confirmed G4110 geofence boundaries. No politicians were flagged or skipped.

## Next Phase Readiness

- BUG-01 is fully resolved. Production essentials schema is now clean.
- CAL Access data can be re-ingested with a proper deduplication/matching strategy in the future (the quarantined rows are preserved, not deleted).
- The `restore-districts.sql` file serves as documentation if this pattern recurs during future Cicero imports.
- Remaining known gap: CA geofence boundaries for NATIONAL_LOWER, STATE_LOWER, COUNTY, SCHOOL still incomplete (separate issue tracked in STATE.md).

---
*Phase: quick-010*
*Completed: 2026-03-30*
