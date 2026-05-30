---
phase: 70-geofencing-backend-integration
plan: 02
subsystem: api
tags: [postgres, pool, tiger, geofencing, districts, representatives, jurisdiction]

# Dependency graph
requires:
  - phase: 70-01
    provides: connect.user_districts table populated by cache_user_districts on location writes
  - phase: 70-03
    provides: essentials.recache_user_districts_for_user(uuid) RPC for opportunistic backfill
provides:
  - GET /api/essentials/representatives/me Path 0 fast path via TIGER user_districts cache
  - Opportunistic backfill from Path 1.5 that self-promotes pre-Phase-70 users to Path 0
affects: [phase 71, any phase that modifies representatives/me handler]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Path 0 before Path 1: try/catch fast path that falls through on any failure — never short-circuits to 204"
    - "Both-column join: tiger_geoid AND district_type required together to avoid cross-SLDL/SLDU collisions"
    - "districtRows hoist: let outside try/catch so downstream code (Path 1.5) can read the count"
    - "Fire-and-forget backfill: void pool.query(...).catch() after res.json(), guarded by districtRows.length === 0"

key-files:
  created: []
  modified:
    - backend/src/routes/essentials.ts

key-decisions:
  - "Path 0 uses districtRows.length === 0 guard on backfill — if the user had ANY cached rows (even for unknown layers like county), skip recache to avoid redundant work"
  - "j?.jurisdiction_city uses optional chain in Path 0 because Inform users may have user_districts (from location-hint) but no connected_profiles row"
  - "JurisdictionGeoIds imported as type-only import to satisfy strict TypeScript without runtime overhead"
  - "recache_user_districts_for_user used instead of cache_user_districts(uuid, lat, lng) — lat/lng not in JS scope at Path 1.5 (SECURITY DEFINER keeps coords inside RPC body)"

patterns-established:
  - "GEO-12 acceptance pattern: pool.query on connect.user_districts + essentials.districts join = zero live PostGIS lookups for cached users"

# Metrics
duration: 1min
completed: 2026-05-09
---

# Phase 70 Plan 02: Geofencing Backend Integration — Representatives Me Path 0 Summary

**Path 0 TIGER fast path added to GET /representatives/me: reads connect.user_districts, joins essentials.districts on (tiger_geoid, district_type), serves politicians without any live PostGIS lookup; Path 1.5 gains opportunistic backfill so pre-Phase-70 users self-promote on next call**

## Performance

- **Duration:** 1 min
- **Started:** 2026-05-09T21:45:56Z
- **Completed:** 2026-05-09T21:47:11Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Path 0 inserted before Path 1 in GET /api/essentials/representatives/me — reads `connect.user_districts`, joins `essentials.districts` on both `(tiger_geoid, district_type)` to prevent cross-SLDL/SLDU contamination, resolves JurisdictionGeoIds, and calls existing `getRepresentativesByJurisdiction()` + `getLocalOfficialsByUserId()` merge pattern
- `districtRows` hoisted to handler scope as `let` before the Path 0 try/catch, making it visible to Path 1.5 for the backfill guard
- Path 1.5 gains fire-and-forget `recache_user_districts_for_user` after `res.status(200).json(merged)` guarded by `districtRows.length === 0` — pre-Phase-70 users with encrypted coords + no geo_ids self-promote to Path 0 on their next request without any migration script
- GEO-12 requirement closed: no call to `resolve_user_jurisdiction` from Path 0; lat/lng never appear in Node scope

## Task Commits

1. **Task 1: Add Path 0 (TIGER user_districts cache) + opportunistic backfill from Path 1.5** - `a6f5e5e` (feat)

**Plan metadata:** (docs commit to follow)

## Files Created/Modified

- `backend/src/routes/essentials.ts` — Added `JurisdictionGeoIds` type import; inserted 90-line Path 0 block between connected_profiles read and Path 1; added 13-line fire-and-forget backfill block in Path 1.5 success branch

## Decisions Made

- `districtRows.length === 0` guard on backfill (not `=== null`) — any non-zero count means user has at least a partial cache, so skip recache. Handles edge case where user has only a `county` layer row (not known to Path 0) without triggering redundant work.
- `j?.jurisdiction_city` optional chain in Path 0 — Inform users can reach Path 0 via user_districts from location-hint flow without having a connected_profiles row; `j` would be undefined and a non-optional access would crash.
- Used `essentials.recache_user_districts_for_user(uuid)` for backfill instead of `cache_user_districts(uuid, lat, lng)` — the Path 1.5 RPC (`resolve_user_jurisdiction`) deliberately keeps plaintext coords inside a SECURITY DEFINER body; they are not returned to the caller and therefore are not in JS scope at the fire-and-forget site.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- GEO-12 closed. Path 0 is live; any user who has gone through the Phase 70-01 location write flow (set-location or location-hint) will hit Path 0 on next representatives/me call.
- Phase 70-04 (frontend wiring) can now rely on Path 0 being available server-side.
- Phase 71 (school districts) should extend the `layerTypeMap` in Path 0 when the `school_district` layer is added to `connect.user_districts`.

---
*Phase: 70-geofencing-backend-integration*
*Completed: 2026-05-09*
