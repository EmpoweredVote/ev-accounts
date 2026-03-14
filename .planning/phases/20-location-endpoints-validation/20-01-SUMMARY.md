---
phase: 20-location-endpoints-validation
plan: 01
subsystem: api
tags: [geocoding, google-maps, env-validation, tiger-line, la-county, postgis]

# Dependency graph
requires:
  - phase: 19-location-schema-rpcs
    provides: "upsert_user_location and resolve_user_jurisdiction RPCs; district_boundaries table; Vault encryption key"
provides:
  - "geocodeAddress(address) — server-side Google Maps geocoding with PO Box rejection and confidence filter"
  - "GeocodingError class with 4 error codes (PO_BOX_REJECTED, ADDRESS_NOT_FOUND, LOW_CONFIDENCE, GEOCODING_API_ERROR)"
  - "GOOGLE_MAPS_API_KEY required env var added to startup validation schema"
  - "LA County TIGER/Line load commands in RUNBOOK-TIGER-LOAD.md"
affects:
  - 20-02-PLAN (POST /account/location calls geocodeAddress)
  - 20-03-PLAN (GET /account/jurisdiction calls geocodeAddress indirectly)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "PO Box rejection fires before any network call — guard at service layer, not HTTP layer"
    - "Confidence filter on geocode result: ROOFTOP and RANGE_INTERPOLATED accepted; GEOMETRIC_CENTER and APPROXIMATE rejected"
    - "Privacy contract: lat/lng never logged, never returned in API responses, only passed to RPC"

key-files:
  created:
    - backend/src/lib/geocodingService.ts
  modified:
    - backend/src/lib/env.ts
    - docs/RUNBOOK-TIGER-LOAD.md

key-decisions:
  - "fetch() built-in (Node 18+) used — no axios or node-fetch dependency"
  - "GeocodingError extends Error with code discriminated union — typed error handling without third-party libs"
  - "GOOGLE_MAPS_API_KEY required (not optional) — missing key exits process at startup, not silently at call time"
  - "LA County: county boundary only — congressional/state_senate/state_house/school_district null is expected Alpha behavior"
  - "ogr2ogr WHERE clause inside -sql string, not standalone -where flag — matches Indiana runbook convention"

patterns-established:
  - "geocodingService pattern: validate input → guard → external API call → status check → confidence filter → return"
  - "RUNBOOK-TIGER-LOAD.md: append new coverage areas as new H2 sections after existing state sections"

# Metrics
duration: 3min
completed: 2026-03-13
---

# Phase 20 Plan 01: Geocoding Service Summary

**Google Maps geocoding service with PO Box rejection, confidence filter, and LA County TIGER/Line runbook section — foundation for Plan 02 and 03 location endpoints**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-14T00:29:25Z
- **Completed:** 2026-03-14T00:32:20Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Created `geocodingService.ts` with structured GeocodingError types, PO Box rejection before any HTTP call, Google Maps API integration, and ROOFTOP/RANGE_INTERPOLATED confidence filter
- Added `GOOGLE_MAPS_API_KEY` as required env var — missing key exits process at startup
- Appended LA County TIGER/Line load section to runbook with ogr2ogr command (COUNTYFP='037' inside -sql), verification query, and Culver City smoke test

## Task Commits

Each task was committed atomically:

1. **Task 1: geocodingService.ts — PO Box rejection, Google Maps call, confidence filter** - `1b0ddac` (feat)
2. **Task 2: env.ts — add GOOGLE_MAPS_API_KEY to startup validation** - `62a60f6` (feat)
3. **Task 3: RUNBOOK-TIGER-LOAD.md — append LA County boundary load section** - `1c03f3f` (docs)

**Plan metadata:** (see final commit)

## Files Created/Modified

- `backend/src/lib/geocodingService.ts` - geocodeAddress(), GeocodingError class, PO Box pattern, Google Maps API call with confidence filter
- `backend/src/lib/env.ts` - GOOGLE_MAPS_API_KEY added as z.string().min(1) required field
- `docs/RUNBOOK-TIGER-LOAD.md` - LA County section appended with ogr2ogr command, verification SQL, and Culver City smoke test

## Decisions Made

- Used built-in `fetch()` (Node 18+) — no new dependencies introduced
- `GOOGLE_MAPS_API_KEY` is required, not optional: a geocoding call with a missing key would produce a confusing GEOCODING_API_ERROR at runtime; startup validation fails fast instead
- LA County only needs the county boundary — `resolve_user_jurisdiction` returns null for congressional/state_senate/state_house/school_district for CA addresses; this is documented in the runbook as expected Alpha behavior

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

**External services require manual configuration.** Before Plan 02 can be tested end-to-end:

1. Create a Google Cloud project and enable the Geocoding API (Google Cloud Console → APIs & Services → Library → "Geocoding API" → Enable)
2. Create an API key (Google Cloud Console → APIs & Services → Credentials → Create credentials → API key)
3. Restrict the key to the Geocoding API only
4. Add to `.env`: `GOOGLE_MAPS_API_KEY=<your-key>`

## Next Phase Readiness

- `geocodeAddress()` and `GeocodingError` are exported and ready to import in Plan 02 (POST /account/location) and Plan 03 (GET /account/jurisdiction)
- `env.GOOGLE_MAPS_API_KEY` available at runtime once the key is provisioned
- LA County boundary load ready to execute once operator sets DATABASE_URL — same ogr2ogr workflow as Indiana

---
*Phase: 20-location-endpoints-validation*
*Completed: 2026-03-13*
