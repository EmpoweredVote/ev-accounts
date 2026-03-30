---
phase: quick
plan: 008
subsystem: database, api
tags: [postgis, supabase, geofence, representatives, jurisdiction, sql, rpc]

# Dependency graph
requires:
  - phase: quick-007
    provides: admin access requests panel
  - phase: 19-location-schema-rpcs
    provides: connect.upsert_user_location, resolve_user_jurisdiction, connected_profiles location columns
provides:
  - Rewritten connect.resolve_user_jurisdiction querying live essentials geometry data
  - Non-null geo_ids and district names for user 4e6dde8f (and all backfilled users)
  - X-Formatted-Address returns street-level address in Path 1
affects:
  - GET /essentials/representatives/me — now returns precise politicians using stored geo_ids
  - Any consumer reading connected_profiles geo_id or district_name columns

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "PostGIS prefix in SECURITY DEFINER RPCs: public.ST_* (not extensions.*) — PostGIS installs into public schema; pgcrypto into extensions"
    - "MTFCC-to-district_type join guard prevents cross-matching in geofence queries"

key-files:
  created:
    - backend/migrations/045_fix_resolve_user_jurisdiction.sql
  modified:
    - backend/src/routes/essentials.ts

key-decisions:
  - "PostGIS functions (ST_Covers, ST_MakePoint, ST_SetSRID) must use public. prefix in SECURITY DEFINER fns — they live in public schema, not extensions"
  - "Geometry type variable declared as public.geometry in SECURITY DEFINER fn (not extensions.geometry)"
  - "MTFCC mapping in RPC narrowed to 5 district types only — LOCAL/LOCAL_EXEC/JUDICIAL excluded intentionally"
  - "District name backfill ran in two passes: geo_ids first (WHERE congressional_geo_id IS NULL), then names (WHERE congressional_district_name IS NULL)"

patterns-established:
  - "PostGIS in SECURITY DEFINER: use public.ST_* and public.geometry type declaration"

# Metrics
duration: 7min
completed: 2026-03-30
---

# Quick Task 008: Fix representatives/me to Return Precise Results

**Rewrote connect.resolve_user_jurisdiction to query live essentials.geofence_boundaries geometry instead of empty inform.district_boundaries, backfilled all user geo_ids and district names, and fixed X-Formatted-Address to prefer street-level homeAddress**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-30T03:59:40Z
- **Completed:** 2026-03-30T04:06:47Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- `connect.resolve_user_jurisdiction` now returns 10-key jsonb with geo_ids + district name labels from live PostGIS geometry data
- User 4e6dde8f (Chris): congressional=0636 (District 36), state_senate=06028, state_house=06055 (Assembly 55), county=06037 (LA County), school_district=0622710 (LA Unified)
- All existing users with stored coordinates and null geo_ids backfilled — including district name columns
- X-Formatted-Address header in Path 1 now returns the user's actual street address, not just "Los Angeles, CA"

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite resolve_user_jurisdiction RPC** - `f542946` (feat)
2. **Task 2: Fix X-Formatted-Address header and backfill existing users** - `b909fa4` (fix)

**Plan metadata:** see final commit below

## Files Created/Modified
- `backend/migrations/045_fix_resolve_user_jurisdiction.sql` - Rewrites resolve_user_jurisdiction to query essentials.geofence_boundaries + essentials.districts via ST_Covers point-in-polygon; returns 10-key jsonb with geo_ids and district labels
- `backend/src/routes/essentials.ts` - Path 1 X-Formatted-Address now prefers homeAddress (street-level) over jurisdiction_city/state fallback

## Decisions Made
- **PostGIS prefix discovery:** The plan specified `extensions.ST_*` following the original migration 032 convention, but PostGIS is actually installed in the `public` schema on this Supabase project (only pgcrypto is in `extensions`). Updated the RPC and migration to use `public.ST_*`. The original migration 032 had this wrong too but the function was never actually called against real coordinates.
- **Geometry type:** `v_point` declared as `public.geometry` (not `extensions.geometry`) — the type must also be schema-qualified in the correct schema.
- **MTFCC mapping narrowed:** Only the 5 district types the RPC returns (NATIONAL_LOWER, STATE_UPPER, STATE_LOWER, COUNTY, SCHOOL). LOCAL/LOCAL_EXEC/JUDICIAL intentionally excluded unlike essentialsService.ts which handles full coverage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PostGIS functions are in public schema, not extensions schema**
- **Found during:** Task 1 (applying migration and running verification)
- **Issue:** Plan specified `extensions.ST_MakePoint` / `extensions.ST_SetSRID` / `extensions.ST_Covers` following original migration 032 conventions. Runtime error: "function extensions.st_makepoint does not exist"
- **Fix:** Verified schema via `pg_proc` query — PostGIS installs into `public`, pgcrypto into `extensions`. Updated all PostGIS calls to `public.ST_*` and geometry type declaration to `public.geometry`
- **Files modified:** backend/migrations/045_fix_resolve_user_jurisdiction.sql
- **Verification:** Migration applied successfully; RPC returns full jsonb with non-null values
- **Committed in:** f542946 (Task 1 commit)

**2. [Rule 2 - Missing Critical] Backfill district name columns (not just geo_id columns)**
- **Found during:** Task 2 post-backfill verification
- **Issue:** First backfill pass (WHERE congressional_geo_id IS NULL) populated geo_ids but not district name columns for users who already had geo_ids set. District names (congressional_district_name, state_senate_district_name, etc.) were empty strings.
- **Fix:** Added second pass targeting users WHERE congressional_district_name IS NULL AND congressional_geo_id IS NOT NULL — calls RPC and fills all name columns
- **Files modified:** no files — SQL executed directly via psql
- **Verification:** User 4e6dde8f shows "District 36", "State Senate District 28", "Assembly District 55", "Los Angeles County", "Los Angeles Unified Board"
- **Committed in:** b909fa4 (Task 2 commit, database change via direct SQL)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical)
**Impact on plan:** Bug fix was necessary for the RPC to compile. Name backfill ensures the route returns proper district names without a second RPC call. No scope creep.

## Issues Encountered
- `db.kxsdzaojfaibhuzmclfq.supabase.co` direct connection host not DNS-resolvable from this environment. Used the session pooler (port 5432) which supports DDL/SECURITY DEFINER function creation.

## User Setup Required
None - no external service configuration required. Migration was applied directly. Backfill ran as a one-time SQL block.

## Next Phase Readiness
- GET /representatives/me now returns precise results for any Connected user within loaded geofence boundaries
- Karen Bass and Traci Park should appear in results for user 4e6dde8f (congressional district 36, LA city)
- Future users: geo_ids will be set at set-location time via the fixed RPC — no further backfills needed
- Pattern confirmed: PostGIS functions use `public.` prefix in SECURITY DEFINER RPCs

---
*Phase: quick-008*
*Completed: 2026-03-30*
