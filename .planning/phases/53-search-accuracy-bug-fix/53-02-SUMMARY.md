---
phase: 53-search-accuracy-bug-fix
plan: "02"
subsystem: ui
tags: [react, javascript, google-places, vite, hooks]

# Dependency graph
requires:
  - phase: 53-search-accuracy-bug-fix
    provides: Area-intersection search path via ST_Intersects for city/ZIP/county queries
provides:
  - Simplified usePoliticianData hook routing all queries through single POST search endpoint
  - searchKey mechanism forcing re-fetch on results page even when query text is unchanged
  - Area label display ("Showing representatives for {formattedAddress}") for non-point queries
  - Removal of warming/retry/polling frontend logic
affects:
  - essentials frontend search UX

# Tech tracking
tech-stack:
  added: []
  patterns:
    - All search queries (ZIP, city, address) go through unified POST /essentials/politicians/search
    - searchKey state increments on each handleAddressSearch call, passed as key option to hook
    - key option in effect dependency array forces re-fetch independent of query text changes

key-files:
  created: []
  modified:
    - essentials/src/hooks/usePoliticianData.js
    - essentials/src/lib/api.jsx
    - essentials/src/pages/Results.jsx

key-decisions:
  - "Single search path: removed ZIP vs address branching — all queries go through searchPoliticians(query)"
  - "searchKey pattern: state counter incremented on each search triggers hook re-fetch even for same query text, solving same-location re-search edge case"
  - "key option in usePoliticianData deps: cleaner than query-with-key string concatenation — avoids polluting URL params or API call shape"
  - "Deprecated fetchPoliticiansOnce and fetchPoliticiansProgressive with comments rather than deleting — they may be used by other callers"

patterns-established:
  - "Re-fetch forcing pattern: pass key state as option to data-fetching hook, include in effect dep array"
  - "Phase simplification: removing warming phase from hook keeps state machine minimal (idle/loading/fresh/error)"

requirements-completed: [SRCH-01, SRCH-02]

# Metrics
duration: 5min
completed: 2026-02-28
---

# Phase 53 Plan 02: Search Accuracy Bug Fix — Frontend Simplification Summary

**All search queries unified through POST search endpoint, warming/retry loop removed, re-search-from-results-page bug fixed with searchKey counter, area label added.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-28T23:22:55Z
- **Completed:** 2026-02-28T23:27:55Z
- **Tasks:** 2 of 3 (Task 3 is human-verify checkpoint)
- **Files modified:** 3

## Accomplishments

- Rewrote `usePoliticianData` hook to remove ZIP vs address branching — all queries call `searchPoliticians(query)` directly
- Removed warming/retry loop (202 polling logic) entirely; phase values simplified to idle/loading/fresh/error
- Added `key` option to hook's effect dependency array, enabling forced re-fetch without query text change
- Fixed re-search bug on Results page via `searchKey` state counter incremented on each `handleAddressSearch` call
- Added area label display ("Showing representatives for {formattedAddress}") in Results.jsx
- Removed all `phase === 'warming'` references from Results.jsx
- Added `@deprecated` comments to `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` in api.jsx

## Task Commits

Each task was committed atomically:

1. **Task 1: Simplify usePoliticianData and api.jsx to use single synchronous search path** - `15459a3` (feat)
2. **Task 2: Fix re-search bug on Results page and add area label display** - `60b893c` (feat)

**Plan metadata:** (docs commit follows after human-verify checkpoint)

## Files Created/Modified

- `essentials/src/hooks/usePoliticianData.js` - Complete rewrite: single searchPoliticians() path, key option added to effect deps, warming phase removed
- `essentials/src/lib/api.jsx` - Added @deprecated comments to fetchPoliticiansOnce and fetchPoliticiansProgressive
- `essentials/src/pages/Results.jsx` - Added searchKey state/counter, key: searchKey passed to hook, area label JSX, removed warming phase checks

## Decisions Made

- **Single search path:** Removed the `isZip` branch entirely. ZIP codes are valid query strings for the POST search endpoint since Plan 01 removed the ZIP early-return shortcut from the backend.
- **searchKey pattern:** Rather than modifying the query string with a timestamp suffix, using a separate `key` state keeps the API call payload clean and the URL params unchanged.
- **Deprecation over deletion:** `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` get `@deprecated` comments rather than deletion since they might be referenced elsewhere and removal would break builds.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None. Both Vite builds passed on first attempt.

## User Setup Required

None — no external service configuration required. Changes are frontend-only; no new env vars or dependencies.

## Checkpoint Status

Task 3 (`checkpoint:human-verify`) requires human verification of search behavior. See checkpoint message for verification steps.

## Next Phase Readiness

- Backend area-intersection search (Plan 01) and frontend unified search path (Plan 02) are both complete
- Effectiveness depends on `geofence_boundaries` table being populated with city/ZIP boundary polygons
- If boundaries are present: city searches return all overlapping district representatives, area label shows
- If boundaries absent for an area: silent fallback to point-in-polygon on geocoded center

---
*Phase: 53-search-accuracy-bug-fix*
*Completed: 2026-02-28*
