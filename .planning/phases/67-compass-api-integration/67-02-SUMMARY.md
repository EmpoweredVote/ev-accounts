---
phase: 67-compass-api-integration
plan: 02
subsystem: ui
tags: [react, context, auth, compass]

requires:
  - phase: 67-01
    provides: fetchTopics, fetchUserAnswers, fetchSelectedTopics, fetchPoliticiansWithStances in essentials/src/lib/compass.js

provides:
  - CompassProvider and useCompass hook in essentials/src/contexts/CompassContext.jsx
  - AuthIndicator component showing user initials in nav when logged in
  - App.jsx wrapped with CompassProvider for app-wide auth + compass state access

affects:
  - 67-03 (dashboard compass cards can use useCompass hook)
  - 68 (guest compass data problem — CompassProvider ready to receive guest data)

tech-stack:
  added: []
  patterns:
    - "CompassContext: createContext + useMemo for stable context value, cancellation flag in useEffect cleanup"
    - "Parallel fetch on mount: auth check first, then public data, then user-specific data if logged in"
    - "AuthIndicator: returns null when logged out (renders nothing), initials circle when logged in"

key-files:
  created:
    - essentials/src/contexts/CompassContext.jsx
    - essentials/src/components/AuthIndicator.jsx
  modified:
    - essentials/src/App.jsx

key-decisions:
  - "Used fixed-position overlay for AuthIndicator (top: 16, right: 16, zIndex: 1000) because SiteHeader has no rightSlot prop — only profileMenu which renders a generic user icon dropdown"
  - "Auth check and public compass data fetched in parallel; user-specific data fetched only if authRes.ok to avoid 401 noise"
  - "Added cancellation flag in useEffect cleanup to prevent setState on unmounted component"

patterns-established:
  - "useCompass hook: always call useContext(CompassContext) via named hook — do not destructure context directly"
  - "CompassProvider placement: wraps entire app at App.jsx level, not BrowserRouter level"

requirements-completed: [DATA-01, DATA-03]

duration: 2min
completed: 2026-03-07
---

# Phase 67 Plan 02: CompassContext + AuthIndicator Summary

**React Context provider for Essentials that fetches auth state from /auth/me and compass data on mount, with initials-based auth indicator in the nav bar**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-07T08:38:13Z
- **Completed:** 2026-03-07T08:39:47Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- CompassContext provider wraps the entire Essentials app and provides centralized auth state plus compass data to all downstream components
- Auth check (/auth/me) runs on every page load via useEffect; topics and politician stances fetched in parallel
- AuthIndicator renders a 32px teal initials circle in the top-right corner when logged in, renders nothing when not logged in

## Task Commits

Each task was committed atomically:

1. **Task 1: Create CompassContext provider with auth + compass data** - `28f76a6` (feat)
2. **Task 2: Add AuthIndicator component and wrap App with CompassProvider** - `74d62ba` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `essentials/src/contexts/CompassContext.jsx` - CompassContext with useCompass hook and CompassProvider; exports isLoggedIn, userName, userAnswers, selectedTopics, allTopics, politicianIdsWithStances (Set), compassLoading
- `essentials/src/components/AuthIndicator.jsx` - Shows user initials in ev-muted-blue circle when logged in, returns null otherwise
- `essentials/src/App.jsx` - Wrapped Routes with CompassProvider; added fixed-position AuthIndicator overlay

## Decisions Made

- Used fixed-position overlay approach for AuthIndicator (top: 16px, right: 16px, zIndex: 1000). SiteHeader from ev-ui does not have a `rightSlot` prop — it only accepts `profileMenu` which renders a full generic user-icon dropdown. The plan specified this fallback approach.
- Auth check and public compass data fetched concurrently; user-specific data (answers, selected topics) gated on authRes.ok to avoid redundant 401 requests.
- Added cancellation flag (`cancelled`) in useEffect cleanup to prevent setting state on unmounted component.

## Deviations from Plan

None - plan executed exactly as written. Fixed-position overlay was the expected fallback documented in Task 2 when SiteHeader has no rightSlot.

## Issues Encountered

None. Vite build passed first attempt (64 modules, 774ms).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CompassProvider is available app-wide via useCompass hook
- Dashboard cards (Plan 03) can now call useCompass() to access allTopics, userAnswers, selectedTopics, politicianIdsWithStances
- politicianIdsWithStances is a Set for O(1) lookup — ready for profile page badge rendering

---
*Phase: 67-compass-api-integration*
*Completed: 2026-03-07*
