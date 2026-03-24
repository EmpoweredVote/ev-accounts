---
phase: 48-compliance-e2e-verification
plan: 02
subsystem: testing
tags: [sso, smoke-test, cross-app, session, logout, graceful-degradation]

# Dependency graph
requires:
  - phase: 47-validation-quests-silent-sso
    provides: VQ SSO implementation (final app in the five-app SSO chain)
  - phase: 46-compassv2-essentials-silent-sso
    provides: CompassV2 + Essentials SSO implementation
  - phase: 45-ctc-profile-hub-silent-sso
    provides: CTC + Profile Hub SSO implementation
  - phase: 44-accounts-sso-foundation
    provides: ev_session cookie + /api/auth/session + /api/auth/logout endpoints
provides:
  - Reusable SSO smoke test script covering all five production apps
  - Test sequences for session inheritance, single logout, and graceful degradation
  - Troubleshooting reference and failure protocol for regression testing
affects: [future SSO regression testing after any auth changes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SSO smoke test template: clear cookies → login at accounts → visit all apps → verify state"
    - "Single-logout test: logout from child app → verify all apps unauthenticated + ev_session absent"
    - "Graceful degradation test: no session → Inform-baseline UI, no redirect loops"

key-files:
  created:
    - docs/SSO-SMOKE-TEST.md
  modified: []

key-decisions:
  - "Smoke test document is the blank template — user fills in results during checkpoint verification"
  - "SSO-02 uses CTC as the logout trigger app (most complex child app, good test signal)"
  - "Failure protocol: document and continue (don't stop on first failure), require clean re-run"

patterns-established:
  - "SSO regression test structure: three scenarios (happy path, logout, degradation) covers all states"

# Metrics
duration: 5min
completed: 2026-03-24
---

# Phase 48 Plan 02: SSO Cross-App Smoke Test Script Summary

**Reusable three-scenario SSO smoke test script covering session inheritance, single logout, and graceful degradation across all five production Empowered Vote apps**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-24T22:22:46Z
- **Completed:** 2026-03-24T22:27:00Z
- **Tasks:** 1 of 2 (Task 2 is a checkpoint awaiting user browser execution)
- **Files modified:** 1

## Accomplishments
- Created `docs/SSO-SMOKE-TEST.md` — reusable SSO smoke test script (116 lines, 25 checkboxes)
- Covers all three required flows: SSO-01 session inheritance, SSO-02 single logout, SSO-03 graceful degradation
- Includes troubleshooting table for five common failure modes
- Includes failure protocol (document inline, continue, create fix tasks, clean re-run required)
- Committed and ready for user to execute in browser

## Task Commits

Each task was committed atomically:

1. **Task 1: Write SSO smoke test script** - `136eb75` (docs)

**Note:** Task 2 is a checkpoint — paused for user browser execution of the smoke test.

## Files Created/Modified
- `docs/SSO-SMOKE-TEST.md` — Three-scenario SSO smoke test script with empty results fields

## Decisions Made
- Test script written as blank template — results filled in by user during checkpoint
- SSO-02 logout triggered from CTC (most complex child app, best regression signal)
- Failure protocol requires full re-run after fixes before Phase 48 is considered complete

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Smoke test script committed and ready for browser execution
- Awaiting user to run SSO-01, SSO-02, SSO-03 in production browser and report results
- If all PASS: Phase 48 complete, v1.7 SSO milestone ready for close
- If any FAIL: Create targeted fix tasks per the failure protocol in the document

---
*Phase: 48-compliance-e2e-verification*
*Completed: 2026-03-24*
