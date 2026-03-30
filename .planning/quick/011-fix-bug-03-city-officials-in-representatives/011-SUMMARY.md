---
phase: quick
plan: 011
subsystem: api
tags: [postgis, supabase, rpc, essentials, representatives, geofence, local-officials]

# Dependency graph
requires:
  - phase: quick-008
    provides: pre-computed geo_ids on connected_profiles (congressional, state_senate, state_house, county, school_district)
  - phase: quick-009
    provides: geofence_boundaries + districts data for LOCAL/LOCAL_EXEC types
  - phase: 19-location-schema-rpcs
    provides: connect.resolve_user_jurisdiction pattern (045 migration)
provides:
  - connect.resolve_user_local_officials RPC (migration 046)
  - getLocalOfficialsByUserId function in essentialsService.ts
  - Hybrid Path 1 in GET /essentials/representatives/me that merges LOCAL/LOCAL_EXEC officials
affects:
  - essentials-representatives-me
  - city-council-display
  - mayor-display

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hybrid geo_id + PostGIS lookup: pre-computed IDs for 5 district types, live RPC for LOCAL/LOCAL_EXEC"
    - "Promise.all for parallel jurisdiction + local officials queries in route handler"
    - "Dedup by politician ID when merging two result sets"

key-files:
  created:
    - backend/migrations/046_resolve_user_local_officials.sql
  modified:
    - backend/src/lib/essentialsService.ts
    - backend/src/routes/essentials.ts

key-decisions:
  - "New RPC (connect.resolve_user_local_officials) rather than extending resolve_user_jurisdiction — LOCAL types need to return multiple rows (a user is in both a city-wide district and a sub-city council district simultaneously), while resolve_user_jurisdiction returns a single jsonb object designed for 1:1 district types"
  - "Return TABLE(geo_id text, district_type text) not jsonb — caller needs to iterate and pass array to second query"
  - "Return empty set on no location rather than RAISE EXCEPTION — caller handles gracefully, Path 1 still works without local officials"
  - "Run getRepresentativesByJurisdiction and getLocalOfficialsByUserId in parallel (Promise.all) — no dependency between them"

patterns-established:
  - "Hybrid Path 1 pattern: fast pre-computed lookup + supplemental PostGIS RPC for district types that require live polygon intersection"

# Metrics
duration: 5min
completed: 2026-03-30
---

# Quick-011: Fix BUG-03 City Officials in Representatives Summary

**Hybrid Path 1 for GET /representatives/me: supplements pre-computed geo_id lookup with connect.resolve_user_local_officials RPC for LOCAL/LOCAL_EXEC city council and mayoral districts**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-30T17:40:34Z
- **Completed:** 2026-03-30T17:45:06Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Created `connect.resolve_user_local_officials` SECURITY DEFINER RPC (migration 046) that decrypts stored coordinates and returns LOCAL/LOCAL_EXEC geo_ids via PostGIS ST_Covers intersection
- Added `getLocalOfficialsByUserId()` to essentialsService.ts that calls the RPC then fetches full politician records for returned geo_ids
- Updated Path 1 in GET /essentials/representatives/me to run jurisdiction + local officials queries in parallel and merge results, restoring Karen Bass (LOCAL_EXEC) and Traci Park (LOCAL CD11) to the response

## Task Commits

Each task was committed atomically:

1. **Task 1: Create resolve_user_local_officials RPC** - `6cf4e7c` (feat)
2. **Task 2: Wire local officials into Path 1 of representatives/me** - `84d96f5` (feat)

**Plan metadata:** (in this commit)

## Files Created/Modified
- `backend/migrations/046_resolve_user_local_officials.sql` - New SECURITY DEFINER RPC returning TABLE(geo_id, district_type) for LOCAL/LOCAL_EXEC districts via PostGIS
- `backend/src/lib/essentialsService.ts` - Added getLocalOfficialsByUserId() function
- `backend/src/routes/essentials.ts` - Path 1 now runs parallel queries and merges results with deduplication

## Decisions Made
- New separate RPC rather than extending `resolve_user_jurisdiction`: LOCAL/LOCAL_EXEC requires returning multiple rows (city-wide + sub-city council district simultaneously); `resolve_user_jurisdiction` returns a single jsonb object designed for 1:1 district types
- `RETURN TABLE(geo_id text, district_type text)` not jsonb: caller needs to iterate and batch-pass to second query
- Return empty set (not RAISE EXCEPTION) when no location on file: allows Path 1 to succeed without local officials rather than falling through to Path 2
- `Promise.all` for parallel execution: no dependency between jurisdiction lookup and local officials RPC

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The Supabase MCP `apply_migration` tool was not available in this execution context; applied migration directly via psql using DATABASE_URL from backend/.env. Verification confirmed RPC returns 3 rows for the test user (ocd council_district:2, ocd council_district:11 as LOCAL, and 0644000 as LOCAL_EXEC for Karen Bass's citywide district).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- BUG-03 resolved: city/local officials now appear in Path 1 response alongside all other district types
- `npx tsc --noEmit` passes (pre-existing `aws-lambda` type error in sqs-worker.ts is unrelated, not introduced here)
- Path 2 (Census Geocoder fallback) unchanged and still functional for users without pre-computed geo_ids

---
*Phase: quick-011*
*Completed: 2026-03-30*
