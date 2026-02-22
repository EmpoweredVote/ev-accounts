---
phase: 26-geofence-only-search
plan: 02
subsystem: ui
tags: [react, vite, hooks, api, address-search, formatted-address]

# Dependency graph
requires:
  - phase: 26-geofence-only-search
    plan: 01
    provides: X-Formatted-Address header on address search responses, X-Data-Status no-geofence-data signaling, geofence-only search backend
provides:
  - Frontend reads X-Formatted-Address header and surfaces confirmed address to user
  - Dashboard address-only input (no ZIP-specific routing from UI)
  - "Showing results for [address]" display above tier tabs
  - Calm local empty-state message when geofence coverage unavailable
affects: [28-frontend-address-input, 29-production-deploy]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Response header consumption: read custom X-* headers from fetch response and thread through hook state to UI"
    - "Empty-state gating: show informational message only when activeQuery is truthy (not on initial load)"

key-files:
  created: []
  modified:
    - essentials/src/lib/api.jsx
    - essentials/src/hooks/usePoliticianData.js
    - essentials/src/pages/Dashboard.jsx

key-decisions:
  - "All searches route through ?q= parameter from UI — ZIP strings like '47401' still accepted by backend via isZip5 check server-side"
  - "formattedAddress only populated in address search branch (not ZIP branch) — ZIP branch has no X-Formatted-Address header"
  - "Local empty-state condition includes activeQuery guard so message never appears on initial Dashboard load"

patterns-established:
  - "Pattern 1: Thread backend response headers (X-Formatted-Address) through api.jsx return value → hook state → Dashboard props"

requirements-completed: [BR-01, BR-02]

# Metrics
duration: 1min
completed: 2026-02-22
---

# Phase 26 Plan 02: Frontend Address Input and Formatted Address Display Summary

**Address-only Dashboard input with confirmed address display and calm local empty-state messaging completing the geofence-only search user experience**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-22T20:51:36Z
- **Completed:** 2026-02-22T20:53:11Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Removed ZIP-specific UI routing — all searches go through `?q=` parameter
- Frontend reads `X-Formatted-Address` response header and surfaces confirmed address to user
- "Showing results for [address]" display appears above tier tabs after successful address search
- Local empty-state message updated to calm "Local representative data is not yet available for this area." in both All and Local tab views
- Local empty-state only shows after an active search (not on initial Dashboard load)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add formattedAddress to search API and hook** - `0e6b41d` (feat)
2. **Task 2: Update Dashboard for address-only input, formatted address display, and local empty-state** - `3c11b5c` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `essentials/src/lib/api.jsx` - searchPoliticians now reads X-Formatted-Address header and returns it; error paths include formattedAddress: ""
- `essentials/src/hooks/usePoliticianData.js` - Added formattedAddress state, resets on new search start and when query is cleared, set from address search result, exposed in return value
- `essentials/src/pages/Dashboard.jsx` - onSearchClick always routes through ?q=; placeholder updated to "Enter your address"; formattedAddress destructured from hook; "Showing results for" display added; local empty-state message updated with activeQuery guard in both All and Local tabs

## Decisions Made
- All searches route through `?q=` parameter from the UI — backend's `isZip5` check still handles ZIP-format strings server-side, so "47401" typed in the address field works correctly
- `formattedAddress` is only populated in the address search branch of the hook (ZIP branch does not get this header), which is correct behavior
- Local empty-state condition includes `activeQuery` guard so the message never appears on the initial Dashboard load before any search

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 27 (candidates): Backend changes from Phase 26 Plan 01 are ready; fetchCandidatesFromDB join path from election_records to zip_politicians still needs schema inspection before writing SQL
- Phase 28 (frontend address input): The Dashboard now uses address-only input; Phase 28 can layer on Google Places Autocomplete to enhance the input UX; the formatted address display infrastructure is already in place
- All verification criteria pass: build clean, ?q= routing, X-Formatted-Address consumed, formattedAddress displayed, local empty-state updated

## Self-Check: PASSED

- FOUND: essentials/src/lib/api.jsx
- FOUND: essentials/src/hooks/usePoliticianData.js
- FOUND: essentials/src/pages/Dashboard.jsx
- FOUND: .planning/phases/26-geofence-only-search/26-02-SUMMARY.md
- FOUND commit: 0e6b41d
- FOUND commit: 3c11b5c

---
*Phase: 26-geofence-only-search*
*Completed: 2026-02-22*
