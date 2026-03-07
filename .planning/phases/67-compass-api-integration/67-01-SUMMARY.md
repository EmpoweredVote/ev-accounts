---
phase: 67-compass-api-integration
plan: 01
subsystem: auth, api
tags: [go, cookies, session, javascript, fetch, compass]

# Dependency graph
requires: []
provides:
  - Cookie Domain ".empowered.vote" set in production for cross-app session sharing
  - fetchUserAnswers() in essentials/src/lib/compass.js
  - fetchSelectedTopics() in essentials/src/lib/compass.js
  - fetchPoliticiansWithStances() in essentials/src/lib/compass.js
affects:
  - 68-guest-compass-data
  - any phase wiring compass data into Essentials UI

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cookie Domain branching: empty in local dev (PORT empty/5050), '.empowered.vote' in production"
    - "Graceful 401 handling in session-protected fetch calls: return [] instead of throwing"

key-files:
  created: []
  modified:
    - EV-Backend/internal/auth/handlers.go
    - essentials/src/lib/compass.js

key-decisions:
  - "Cookie Domain is branched on PORT env var — same condition already used for Secure/SameSite, no new detection logic needed"
  - "fetchUserAnswers and fetchSelectedTopics explicitly check res.status === 401 before the generic !res.ok throw, so logged-out users get [] without console errors"
  - "fetchPoliticiansWithStances uses credentials: include even though it is a public endpoint — consistent with the existing file pattern and harmless"

patterns-established:
  - "Compass fetch pattern: try/catch around fetch, explicit 401 check for session-protected endpoints, return [] on any error"

requirements-completed: [DATA-01, DATA-03]

# Metrics
duration: 8min
completed: 2026-03-07
---

# Phase 67 Plan 01: Compass API Integration Foundation Summary

**Cookie Domain `.empowered.vote` added for cross-app sessions; three compass fetch functions (fetchUserAnswers, fetchSelectedTopics, fetchPoliticiansWithStances) added to Essentials with graceful 401 handling**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-07T08:27:00Z
- **Completed:** 2026-03-07T08:35:48Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Backend sessionCookie() now sets Domain ".empowered.vote" in production so compass.empowered.vote and essentials.empowered.vote share the session cookie with api.empowered.vote
- Local dev behavior preserved (no Domain, Secure=false, SameSite=Lax) — no regression to existing workflow
- Essentials gains three new compass API fetch helpers that are safe to call regardless of login state (return [] instead of throwing)

## Task Commits

Each task was committed atomically (in each project's own repo):

1. **Task 1: Add cookie Domain branching for cross-app sessions** - `d55d730` in EV-Backend (feat)
2. **Task 2: Add compass API fetch functions to Essentials** - `a158c93` in essentials (feat)

## Files Created/Modified
- `EV-Backend/internal/auth/handlers.go` - Extended sessionCookie() with Domain field: ".empowered.vote" in production, "" in local dev
- `essentials/src/lib/compass.js` - Added fetchUserAnswers(), fetchSelectedTopics(), fetchPoliticiansWithStances() exports

## Decisions Made
- Cookie Domain branching reuses the existing PORT env var condition — no new detection logic, stays DRY
- 401 is checked explicitly before the generic `!res.ok` guard in session-protected fetch functions so unauthenticated users receive `[]` silently (no console error on expected 401)
- fetchPoliticiansWithStances uses `credentials: "include"` for consistency with the rest of the file even though the endpoint is public

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The workspace-level git repo does not track project subdirectories (each project has its own repo), so commits were made to EV-Backend and essentials repos individually. This is the correct behavior for this workspace setup.

## User Setup Required

None - no external service configuration required. The Domain change takes effect automatically when deployed to production (where PORT is not 5050).

## Next Phase Readiness

- Phase 68 can import fetchUserAnswers and fetchSelectedTopics to wire compass data into Essentials UI components
- fetchPoliticiansWithStances ready to cross-reference politicians returned by address search against those with stances

---
*Phase: 67-compass-api-integration*
*Completed: 2026-03-07*

## Self-Check: PASSED

- FOUND: .planning/phases/67-compass-api-integration/67-01-SUMMARY.md
- FOUND: EV-Backend/internal/auth/handlers.go
- FOUND: essentials/src/lib/compass.js
- FOUND commit: d55d730 (EV-Backend)
- FOUND commit: a158c93 (essentials)
