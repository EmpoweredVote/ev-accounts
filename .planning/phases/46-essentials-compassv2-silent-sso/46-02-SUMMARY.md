---
phase: 46-essentials-compassv2-silent-sso
plan: "02"
subsystem: auth
tags: [sso, cookies, react, context, cross-app]

# Dependency graph
requires:
  - phase: 45-profile-hub-ctc-silent-sso
    provides: "ev_session cookie pattern and /api/auth/session + /api/auth/logout endpoints"
provides:
  - "CompassV2 silently inherits ev_session cookie on mount (SSO-11)"
  - "CompassV2 logout clears shared ev_session cookie via POST with credentials: include (SSO-12)"
  - "authChecking state prevents mid-render flash from guest to authenticated UI"
affects:
  - phase-47-and-beyond
  - any-future-compassv2-auth-work

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SSO silent check: fetch /api/auth/session with credentials: include + 2s AbortController timeout in auth useEffect IIFE"
    - "authChecking gate: initialize true, set false in finally block — fires in ALL code paths (token-present, SSO success, SSO failure)"
    - "Cross-app logout: native fetch with credentials: include + Bearer header, no navigate()"

key-files:
  created: []
  modified:
    - C:/EV-CompassV2/src/components/CompassContext.jsx
    - C:/EV-CompassV2/src/components/Layout.jsx
    - C:/EV-CompassV2/src/pages/Home.jsx

key-decisions:
  - "authChecking initialized to true and only set false in finally block — guarantees no-flash regardless of SSO outcome"
  - "SSO check skipped when local token already present — avoids unnecessary network call"
  - "Logout does not navigate away — user stays on current page; local state always cleared even if API call fails"

patterns-established:
  - "SSO async IIFE in useEffect: extractHashToken → SSO cookie check → publicFetch /account/me → finally setAuthChecking(false)"
  - "Cross-app logout: native fetch with credentials: include, Bearer header optional, state clearing outside try/catch"

# Metrics
duration: 2min
completed: 2026-03-24
---

# Phase 46 Plan 02: CompassV2 Silent SSO Summary

**CompassV2 joins cross-app SSO family: silently inherits ev_session cookie on load via authChecking-gated async IIFE, logout clears shared cookie with credentials: include and no page navigation**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-24T20:55:20Z
- **Completed:** 2026-03-24T20:57:20Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- CompassV2 calls `GET /api/auth/session` with `credentials: include` on mount when no local token exists (SSO-11)
- `authChecking` state (init `true`, cleared in `finally`) prevents flash of "Sign in" before SSO check resolves
- CompassV2 logout calls `POST /api/auth/logout` with `credentials: include` to clear shared ev_session cookie (SSO-12)
- No `navigate("/")` in any logout handler — user stays on current page after logout

## Task Commits

Each task was committed atomically:

1. **Task 1: Add authChecking state and SSO check to CompassContext auth useEffect** - `a041d3c` (feat)
2. **Task 2: Fix logout in Layout.jsx and Home.jsx — credentials include, no navigate** - `a2c3e97` (fix)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `C:/EV-CompassV2/src/components/CompassContext.jsx` — Added `authChecking` state + `setToken` import; replaced sync auth useEffect with async IIFE including SSO check; exported `authChecking` from context value
- `C:/EV-CompassV2/src/components/Layout.jsx` — Replaced `apiFetch` logout with native fetch + `credentials: include`; removed `navigate("/")`; added `authChecking` gate to profile menu; fixed missing `apiFetch` import for `handleClearCompass`
- `C:/EV-CompassV2/src/pages/Home.jsx` — Replaced `apiFetch` logout with native fetch + `credentials: include`; removed `navigate("/")`; added `getToken` import

## Decisions Made
- `authChecking` initialized to `true` so the profile menu renders a neutral placeholder immediately on mount, not "Sign in". Set to `false` only in the `finally` block of the outer try/catch, guaranteeing it fires in token-present, SSO-success, and SSO-failure paths.
- SSO check is skipped when `getToken()` is already truthy — avoids an unnecessary network round-trip for users with a fresh login.
- Local state cleared outside the logout try/catch — guaranteed cleanup even if the API call times out or errors.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored apiFetch import in Layout.jsx**
- **Found during:** Task 2 (Layout.jsx logout fix)
- **Issue:** When replacing `apiFetch` logout with native fetch, removed `apiFetch` from imports — but `handleClearCompass` still calls `apiFetch('/compass/answers/me')`. This would be a runtime ReferenceError.
- **Fix:** Added `apiFetch` back alongside `getToken` and `clearToken` in the auth import
- **Files modified:** C:/EV-CompassV2/src/components/Layout.jsx
- **Verification:** Import verified present in final file read
- **Committed in:** a2c3e97 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Essential catch — would have caused runtime error on "Reset compass" action.

## Issues Encountered
None beyond the import fix above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SSO-11 and SSO-12 satisfied for CompassV2
- Phase 46 plan 01 (Essentials/Profile Hub silent SSO) and plan 02 (CompassV2 silent SSO) both complete
- All three cross-app SSO targets (Profile Hub, CTC, CompassV2) now inherit ev_session on load
- v1.7 Cross-App SSO phase may be complete pending final verification

---
*Phase: 46-essentials-compassv2-silent-sso*
*Completed: 2026-03-24*
