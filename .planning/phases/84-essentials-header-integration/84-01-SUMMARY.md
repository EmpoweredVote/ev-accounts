---
phase: 84-essentials-header-integration
plan: 01
subsystem: ui
tags: [react, ev-ui, siteheader, auth, context]

# Dependency graph
requires:
  - phase: 83-ev-ui-siteheader-url-update
    provides: ev-ui v0.1.49 with updated SiteHeader URLs
provides:
  - ev-ui v0.1.49 installed in essentials
  - CompassContext logout() function that POSTs to /auth/logout and resets local state
  - Layout.jsx component wrapping SiteHeader with auth-aware profileMenu
affects:
  - 84-02 (pages that consume Layout)

# Tech tracking
tech-stack:
  added: ["@chrisandrewsedu/ev-ui@0.1.49"]
  patterns: ["Auth-aware header via profileMenu prop", "Logout resets local state without redirect"]

key-files:
  created:
    - essentials/src/components/Layout.jsx
  modified:
    - essentials/package.json
    - essentials/package-lock.json
    - essentials/src/contexts/CompassContext.jsx

key-decisions:
  - "Layout always passes profileMenu to SiteHeader — logged-out users see Sign In link in dropdown rather than no profile button"
  - "logout() resets userAnswers, selectedTopics, verdicts in addition to isLoggedIn and userName"
  - "No useCallback on logout — plain async function in provider scope is sufficient"

patterns-established:
  - "Layout pattern: wraps SiteHeader + children; imported by pages in Plan 02"
  - "profileMenu conditional: isLoggedIn drives label and items array shape"

requirements-completed: [ESS-02, ESS-03, ESS-04]

# Metrics
duration: 2min
completed: 2026-03-13
---

# Phase 84 Plan 01: Essentials Header Integration Foundation Summary

**Auth-aware SiteHeader foundation — ev-ui v0.1.49 installed, CompassContext extended with logout(), Layout.jsx wrapper component ready for page integration**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-13T00:18:34Z
- **Completed:** 2026-03-13T00:19:50Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Upgraded `@chrisandrewsedu/ev-ui` to ^0.1.49 in essentials and ran npm install
- Added `logout()` async function to CompassContext that POSTs to /auth/logout then clears isLoggedIn, userName, userAnswers, selectedTopics, verdicts
- Created `Layout.jsx` that conditionally builds profileMenu (logged-in: username + Sign out; logged-out: Sign in link to compass.empowered.vote/login) and renders SiteHeader above children

## Task Commits

Each task was committed atomically to the essentials sub-repo:

1. **Task 1: Upgrade ev-ui and add logout to CompassContext** - `6cdf664` (feat)
2. **Task 2: Create auth-aware Layout component** - `084e37c` (feat)

## Files Created/Modified
- `essentials/package.json` - ev-ui bumped from ^0.1.48 to ^0.1.49
- `essentials/package-lock.json` - Updated lock file after npm install
- `essentials/src/contexts/CompassContext.jsx` - Added logout async function to provider and value object
- `essentials/src/components/Layout.jsx` - New auth-aware Layout wrapper component

## Decisions Made
- Layout always passes profileMenu to SiteHeader so the profile button always appears; logged-out users see a "Sign in" item that links to compass.empowered.vote/login
- logout() resets the full user state set (answers, topics, verdicts) to match what the app would show a fresh guest visitor
- No useCallback wrapper on logout — unnecessary for this use case; plain async function defined in provider scope

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Layout.jsx is ready for Plan 02 to import and wrap page-level components (Dashboard, Profile)
- Build verified passing with no errors
- All three requirements (ESS-02, ESS-03, ESS-04) foundation is in place

---
*Phase: 84-essentials-header-integration*
*Completed: 2026-03-13*

## Self-Check: PASSED

- Layout.jsx: FOUND
- CompassContext.jsx: FOUND
- SUMMARY.md: FOUND
- Commit 6cdf664: FOUND
- Commit 084e37c: FOUND
