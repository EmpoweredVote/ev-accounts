---
phase: 70-geofencing-backend-integration
plan: "04"
subsystem: api
tags: [express, typescript, geocoding, geofencing, postgres, inform-tier, tiger-districts]

# Dependency graph
requires:
  - phase: 70-01
    provides: "cache_user_districts wired into set-location (Connected) + location-hint (Inform); GET /api/account/districts; requireInform middleware already imported in account.ts"
  - phase: 66-inform-profiles-backend-foundation
    provides: "inform.inform_profiles table with last_essentials_location JSONB column + upsert pattern"
provides:
  - "POST /api/account/set-location — Inform-tier address-entry endpoint with server-side geocoding, JSONB persist, and district cache wiring"
affects:
  - "71-geofencing-frontend-integration — Accounts app (login.empowered.vote) can now call POST /api/account/set-location to let Inform users set their address"
  - "Any future plan that reads inform_profiles.last_essentials_location for Inform-tier users"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inform-tier geocoding pattern: geocodeAddress() + upsert to inform.inform_profiles.last_essentials_location + fail-open essentials.cache_user_districts (mirrors Connected set-location)"
    - "Security: response body is exactly { ok: true } — no lat/lng/address echo from set-location endpoints (both tiers)"
    - "GeocodingError code mapping: ADDRESS_NOT_FOUND/PO_BOX_REJECTED -> 400, GEOCODER_UNAVAILABLE -> 503, fallthrough -> 500"

key-files:
  created: []
  modified:
    - "backend/src/routes/account.ts"

key-decisions:
  - "Response body is exactly { ok: true } — no address/coordinate echo, matching the Connected endpoint security decision from plan 70-01"
  - "essentials.cache_user_districts called via pool.query (not adminRpc) — essentials schema is not in PostgREST exposed schema list"
  - "District cache is fail-open via nested inner try/catch — a PostGIS error never aborts an already-committed inform_profiles upsert"
  - "PO_BOX_REJECTED treated as 400 (same branch as ADDRESS_NOT_FOUND) — it is a client input error, not a server/geocoder error"

patterns-established:
  - "Inform set-location pattern: geocodeAddress -> upsert inform_profiles.last_essentials_location -> fail-open cache_user_districts -> { ok: true }"

# Metrics
duration: 3min
completed: 2026-05-10
---

# Phase 70 Plan 04: Geofencing Backend Integration Summary

**POST /api/account/set-location added to Inform tier — server-side geocoding via US Census API, JSONB persist to inform_profiles, fail-open TIGER district cache wiring, { ok: true } security-only response**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-10T04:26:21Z
- **Completed:** 2026-05-10T04:29:25Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Added `POST /api/account/set-location` gated by `requireAuth + requireInform` — Connected users receive 403
- Geocodes address via `geocodeAddress()` with GeocodingError code-to-HTTP-status mapping (400/503/500)
- Upserts `{ lat, lng, city, state, matchedAddress }` JSONB to `inform.inform_profiles.last_essentials_location` via `pool.query`
- Calls `essentials.cache_user_districts($1, $2, $3)` fail-open in inner try/catch — inform_profiles write commits even if district cache throws
- Response body is exactly `{ ok: true }` — no coordinate or address data echoed (security parity with Connected endpoint)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add POST /api/account/set-location endpoint** - `c140cab` (feat)

**Plan metadata:** (see final commit below)

## Files Created/Modified
- `backend/src/routes/account.ts` - Added `geocodeAddress`/`GeocodingError` import + `POST /set-location` handler (108 lines inserted)

## Decisions Made
- None — plan specified all implementation details precisely. Followed as written.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `POST /api/account/set-location` is live. Phase 71 (frontend integration) can now wire the Accounts app's address-entry form to this endpoint.
- `GET /api/account/districts` (plan 70-01) returns district data after a successful `set-location` call — the full Inform location flow is backend-complete.
- No blockers for Phase 71.

---
*Phase: 70-geofencing-backend-integration*
*Completed: 2026-05-10*
