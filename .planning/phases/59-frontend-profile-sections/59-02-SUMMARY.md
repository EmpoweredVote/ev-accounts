---
phase: 59-frontend-profile-sections
plan: "02"
subsystem: ui
tags: [react, vite, ev-ui, legislative-record, routing, api-fetch]

# Dependency graph
requires:
  - phase: 59-01
    provides: LegislativeInlineSummary and LegislativeRecord components in ev-ui@0.1.37
  - phase: 55-56-57-58
    provides: backend API endpoints for committees, leadership, bills, votes, legislative-summary
provides:
  - Five legislative fetch functions in essentials/src/lib/api.jsx (all return defaults on error)
  - LegislativeRecordPage at /politician/:id/record with parallel data fetching
  - Profile.jsx now fetches legislative summary in parallel with politician data
  - LegislativeSummary and politicianId props wired into PoliticianProfile
  - Route /politician/:id/record registered as sibling route in App.jsx
affects: [future-ui-phases, essentials-app]

# Tech tracking
tech-stack:
  added: ["@chrisandrewsedu/ev-ui@0.1.37 (upgrade from 0.1.36)"]
  patterns:
    - "Legislative fetch functions return empty arrays/objects on error — never throw to UI layer"
    - "Parallel fetch with Promise.all in useEffect for profile + summary data"
    - "Sibling flat route pattern for /politician/:id/record alongside /politician/:id"
    - "LegislativeRecordPage fetches limit=200 bills and votes to enable client-side year filtering"

key-files:
  created:
    - essentials/src/pages/LegislativeRecord.jsx
  modified:
    - essentials/src/lib/api.jsx
    - essentials/src/pages/Profile.jsx
    - essentials/src/App.jsx
    - essentials/package.json
    - essentials/package-lock.json

key-decisions:
  - "Legislative fetch functions silently return empty defaults on error — profile page always renders even if legislative API is unavailable"
  - "bills and votes fetched with limit=200 to support year filter and show-all without extra API calls — ev-ui component caps display internally"
  - "Flat sibling route /politician/:id/record (not nested) — Profile.jsx has no Outlet"

patterns-established:
  - "All legislative API functions: try/catch, credentials: include, return [] or {} on error"
  - "LegislativeRecordPage is a thin page shell (Header + data fetch) wrapping the headless ev-ui LegislativeRecord content component"

requirements-completed: [UI-01, UI-02, UI-03, UI-04, UI-05]

# Metrics
duration: 2min
completed: 2026-03-03
---

# Phase 59 Plan 02: Frontend Profile Sections — Wiring Summary

**essentials app wired to ev-ui legislative components: 5 API functions, LegislativeRecordPage at /politician/:id/record, Profile.jsx fetches inline summary in parallel, new route registered**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-03T06:58:41Z
- **Completed:** 2026-03-03T07:00:45Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added 5 legislative fetch functions to api.jsx — all return safe defaults on error, ensuring the profile page renders even when legislative endpoints are unavailable
- Created LegislativeRecordPage with parallel Promise.all fetch of politician, committees, leadership, bills (limit=200), and votes (limit=200), rendering the ev-ui LegislativeRecord component
- Modified Profile.jsx to fetch legislative summary in parallel with politician data and pass legislativeSummary and politicianId to PoliticianProfile
- Registered /politician/:id/record as a flat sibling route in App.jsx
- npm run build succeeds with 0 errors

## Task Commits

Each task was committed atomically (within the essentials/ sub-repo):

1. **Task 1: Add legislative API fetch functions and update ev-ui dependency** - `370cc77` (feat)
2. **Task 2: Create LegislativeRecordPage and wire Profile.jsx + App.jsx** - `403ece9` (feat)

## Files Created/Modified

- `essentials/src/lib/api.jsx` - Added fetchLegislativeSummary, fetchLegislativeCommittees, fetchLegislativeLeadership, fetchLegislativeBills, fetchLegislativeVotes (all silent-fail)
- `essentials/src/pages/LegislativeRecord.jsx` - New page: Header + parallel fetch + LegislativeRecord component render
- `essentials/src/pages/Profile.jsx` - Parallel fetch of legislative summary; passes legislativeSummary and politicianId props
- `essentials/src/App.jsx` - Added LegislativeRecord import and /politician/:id/record route
- `essentials/package.json` - Upgraded @chrisandrewsedu/ev-ui from ^0.1.36 to ^0.1.37
- `essentials/package-lock.json` - Updated lock file

## Decisions Made

- Legislative fetch functions return empty arrays/objects on error rather than throwing. This ensures Profile.jsx always renders even if the legislative-summary endpoint is down or returns 404 (e.g., for local politicians with no legislative data).
- Bills and votes fetched with limit=200 so the year dropdown and "Show all" feature in ev-ui have enough data client-side without additional API calls. The ev-ui component handles the 25-item default display cap internally.
- Flat sibling route (not nested route with Outlet). Research confirmed Profile.jsx renders no Outlet, so /politician/:id/record must be a standalone page.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- The workspace top-level git repo treats essentials/ as an untracked directory (essentials has its own .git). Commits were made inside the essentials/ sub-repo as intended.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Complete pipeline is wired: backend API endpoints (phases 55-58) → fetch functions (api.jsx) → display components (ev-ui@0.1.37) → page routes (essentials app)
- Federal politicians with legislative data will see inline summary on profile page and full record at /politician/:id/record
- Local politicians with no legislative data see unchanged profile (guard in ev-ui LegislativeInlineSummary returns null for empty data)
- No further blockers — phase 59 is complete

---
*Phase: 59-frontend-profile-sections*
*Completed: 2026-03-03*
