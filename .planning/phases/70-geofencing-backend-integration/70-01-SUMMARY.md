---
phase: 70-geofencing-backend-integration
plan: 01
subsystem: api
tags: [postgis, tiger, geofencing, districts, pool.query, essentials]

# Dependency graph
requires:
  - phase: 69-tiger-schema-data-import
    provides: "essentials.cache_user_districts RPC, connect.user_districts table, essentials.geo_districts with 172-row TIGER import"
provides:
  - "POST /api/connect/set-location calls essentials.cache_user_districts after jurisdiction write (fail-open)"
  - "PATCH /api/account/location-hint calls essentials.cache_user_districts after upsert with defensive lat/lng extraction (fail-open)"
  - "GET /api/account/districts returns { ca_assembly, ca_senate, us_house } grouped from connect.user_districts JOIN essentials.geo_districts"
affects: [70-02, 70-03, phase-71, politicians-representing-me, frontend-district-display]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fail-open cache pattern: try/catch around non-critical side-effects that must never abort the primary response"
    - "Defensive JSONB type narrowing: cast z.unknown() to Record<string, unknown> | null, check typeof before use"
    - "pool.query for all essentials.* calls — essentials schema is NOT in PostgREST exposed schema list"
    - "204 No Content for empty result sets where frontend treats absence of data differently from empty data"

key-files:
  created: []
  modified:
    - backend/src/routes/connect.ts
    - backend/src/routes/account.ts

key-decisions:
  - "All essentials.* RPC calls must use pool.query — never adminRpc (essentials not in PostgREST exposed schema list)"
  - "GET /api/account/districts gated by requireAuth only — both Inform and Connected tiers allowed; Essentials is foundational"
  - "204 returned for zero user_districts rows so frontend can distinguish 'no location set' from 'location set, no districts matched'"
  - "location-hint handler keeps z.unknown() on location field — defensive extraction at call site, not schema change"

patterns-established:
  - "Fail-open district cache: cache call wrapped in try/catch, logs and continues; location write commits regardless"
  - "essentials schema access: always pool.query(); never supabase.schema('essentials') or adminRpc to essentials.*"
  - "GET /api/account/districts response shape: { ca_assembly, ca_senate, us_house } with each being null or { district_number, name, tiger_geoid }"

# Metrics
duration: 2min
completed: 2026-05-10
---

# Phase 70 Plan 01: Geofencing Backend Integration Summary

**cache_user_districts wired into both location-write flows and GET /api/account/districts added — every authenticated user can now write and read TIGER-backed district data**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-10T04:17:43Z
- **Completed:** 2026-05-10T04:19:54Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- POST /api/connect/set-location now calls `essentials.cache_user_districts(userId, lat, lng)` via `pool.query` after the jurisdiction write — fail-open, never blocks the 200 response
- PATCH /api/account/location-hint defensively extracts `lat`/`lng` from the opaque JSONB payload and calls `cache_user_districts` — skips silently when coords are absent
- GET /api/account/districts returns `{ ca_assembly, ca_senate, us_house }` grouped from `connect.user_districts` LEFT JOIN `essentials.geo_districts`; 204 when no rows; gated by `requireAuth` only (both tiers)

## Task Commits

All three tasks committed atomically in a single feature commit (2 files, tightly coupled):

1. **Task 1: Wire cache_user_districts into POST /api/connect/set-location** - `92a92aa` (feat)
2. **Task 2: Wire cache_user_districts into PATCH /api/account/location-hint** - `92a92aa` (feat)
3. **Task 3: Add GET /api/account/districts endpoint** - `92a92aa` (feat)

## Files Created/Modified
- `backend/src/routes/connect.ts` - Added fail-open `cache_user_districts` call after jurisdiction write in set-location handler (lines 640–650)
- `backend/src/routes/account.ts` - Added fail-open `cache_user_districts` call in location-hint handler + new `GET /districts` endpoint (lines 686–704, 713–771)

## Decisions Made
- **pool.query required**: essentials schema is NOT in PostgREST exposed schema list — `adminRpc('cache_user_districts', ...)` would silently fail at runtime. All essentials.* calls use `pool.query` directly.
- **requireAuth only on GET /districts**: Both Inform (location-hint) and Connected (set-location) users produce rows in `user_districts`. The read endpoint must not discriminate by tier — both need to read their own districts.
- **204 vs 200+nulls**: Frontend treats 204 as "user has no location set yet" — meaningful signal distinct from "location set, matched zero districts (out-of-CA)". Returning `{ca_assembly:null,...}` on 200 would lose this distinction.
- **No schema change on location-hint**: `location: z.unknown()` stays. The Essentials frontend passes `{ lat, lng, ... }` but the contract doesn't enforce it. Defensive extraction at call site (`typeof loc.lat === 'number'`) is the correct pattern.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. TypeScript compiled cleanly on first pass.

## User Setup Required

None - no external service configuration required. The `essentials.cache_user_districts` RPC was deployed in Phase 69 (migration 090).

## Next Phase Readiness

- GEO-10 + GEO-11 complete. Every location write (Connected + Inform paths) now populates `connect.user_districts`.
- `GET /api/account/districts` is live and ready for frontend consumption.
- Ready for Plan 70-02: politicians-representing-me query using `tiger_geoid` join (GEO-12).
- No blockers.

---
*Phase: 70-geofencing-backend-integration*
*Completed: 2026-05-10*
