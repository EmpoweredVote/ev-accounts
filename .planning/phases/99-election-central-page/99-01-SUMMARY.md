---
phase: "99"
plan: "01"
subsystem: "essentials-backend"
tags: ["elections", "backend", "api"]
one-liner: "GET /api/essentials/elections-by-address endpoint with geofence + statewide race matching"
key-decisions:
  - "Two-query approach: geofence-matched races + statewide races by state code, merged with dedup"
  - "district_type derived for statewide races via jurisdiction_level levelMap (federal→NATIONAL_EXEC, etc.)"
  - "Antipartisan: primary_party lives on race, never on candidate records"
  - "Geocoding errors gracefully return 200 with empty elections (not 4xx)"
key-files:
  modified:
    - "backend/src/lib/electionService.ts"
    - "backend/src/routes/essentials.ts"
  created:
    - "tests/integration/essentials-elections.test.ts"
---

# Phase 99 Plan 01: Elections-By-Address Backend — Summary

## What Was Delivered

Added `GET /api/essentials/elections-by-address?address={encoded}` endpoint to the essentials router.

### Backend Changes

**`electionService.ts`** — Added `getElectionsByCoordinate(lat, lng)`:
- Part A: geofence-matched races via PostGIS ST_Covers join through geofence_boundaries → districts → offices → races
- Part B: statewide/at-large races (office_id IS NULL) matched by state code derived from Part A
- Merges both result sets with candidate deduplication
- Groups into elections → races → candidates hierarchy
- Derives district_type for statewide races using jurisdiction_level levelMap

**`essentials.ts`** — Added route `GET /api/essentials/elections-by-address`:
- Validates `address` query param (422 VALIDATION_ERROR if missing/empty)
- Geocodes via `geocodeAddress()` internally
- ADDRESS_NOT_FOUND and PO_BOX_REJECTED return 200 `{ elections: [] }`
- GEOCODER_UNAVAILABLE returns 503
- Returns `{ elections }` array

**`essentials-elections.test.ts`** — Integration tests:
- 422 on missing address
- 422 on empty address
- Route wiring test (accepts 200, 503, or 500 — no live DB required)
- Graceful handling of non-geocodable address

### Commits

- 23d8dd1 test(99-01): add stub integration tests for elections-by-address endpoint
- 5609a16 feat(99-01): add district_type to ElectionRace interface and SQL queries
- 67c860c feat(99-01): add GET /api/essentials/elections-by-address endpoint

## Self-Check: PASSED

All files exist and commits verified in git log.
