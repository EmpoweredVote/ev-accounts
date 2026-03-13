---
phase: 85-readrank-header-auth
plan: 02
subsystem: ui
tags: [react, auth, verification, readrank, header]

# Dependency graph
requires:
  - phase: 85-readrank-header-auth
    plan: 01
    provides: useAuthState hook and profileMenu wired into SiteHeader
provides:
  - Human-verified auth-aware ReadRank header
  - returnTo URL on Sign in link for post-login redirect
  - Vite proxy for local dev auth cookie handling
affects: [85-readrank-header-auth, ev-readrank]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Vite proxy for /auth/* in dev to solve cross-origin cookie issue", "VITE_COMPASS_URL env var for configurable login redirect", "returnTo query param on Sign in link matching essentials pattern"]

key-files:
  created: []
  modified:
    - EV-ReadRank/src/App.tsx
    - EV-ReadRank/src/hooks/useAuthState.ts
    - EV-ReadRank/vite.config.ts

key-decisions:
  - "Added Vite proxy for /auth/* → localhost:5050 so session cookies work same-origin in local dev (SameSite: Lax cookies aren't sent cross-origin on fetch)"
  - "useAuthState uses relative URLs in dev mode (import.meta.env.DEV) so Vite proxy handles /auth/me and /auth/logout"
  - "Sign in link uses VITE_COMPASS_URL env var with fallback to https://compass.empowered.vote"
  - "returnTo query param added to Sign in link, matching established pattern in essentials Layout.jsx"

patterns-established:
  - "Cross-origin auth in dev: Vite proxy + relative URLs, not SameSite workarounds"
  - "Login redirect: always include ?returnTo=encodeURIComponent(window.location.href)"

requirements-completed: [RR-01, RR-02, RR-03]

# Metrics
duration: 30min
completed: 2026-03-13
---

# Phase 85 Plan 02: Human Verification Summary

**Auth-aware ReadRank header verified end-to-end — two bugs fixed during verification (returnTo URL, cross-origin cookie)**

## Performance

- **Duration:** 30 min
- **Started:** 2026-03-13T01:45:00Z
- **Completed:** 2026-03-13T02:15:00Z
- **Tasks:** 1 (human verification checkpoint)
- **Files modified:** 3 (bug fixes discovered during verification)

## Accomplishments
- Human-verified all three auth states: logged-in shows username + Sign out, logged-out shows Sign in, Sign out clears state immediately
- Fixed missing returnTo URL on Sign in link (user was not redirected back after login)
- Fixed cross-origin cookie issue in local dev by adding Vite proxy for /auth/* endpoints
- Made compass login URL configurable via VITE_COMPASS_URL env var

## Task Commits

1. **Task 1: Human verification + bug fixes** - `7b23e85` (fix)

## Files Created/Modified
- `EV-ReadRank/src/App.tsx` - Sign in href now uses VITE_COMPASS_URL with returnTo param
- `EV-ReadRank/src/hooks/useAuthState.ts` - Uses relative URLs in dev mode for Vite proxy
- `EV-ReadRank/vite.config.ts` - Added server.proxy for /auth → localhost:5050

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing returnTo URL on Sign in link**
- **Found during:** Human verification
- **Issue:** After clicking Sign in on ReadRank, logging in on CompassV2, user was not redirected back to ReadRank
- **Fix:** Added `?returnTo=${encodeURIComponent(window.location.href)}` to Sign in href, matching essentials pattern
- **Files modified:** EV-ReadRank/src/App.tsx
- **Committed in:** 7b23e85

**2. [Rule 1 - Bug] Cross-origin cookie not sent in local dev**
- **Found during:** Human verification
- **Issue:** Backend sets session cookie with SameSite: Lax on localhost:5050, but frontend fetch from localhost:5176 is cross-origin — Lax cookies aren't sent on cross-origin fetch()
- **Fix:** Added Vite proxy for /auth/*, changed useAuthState to use relative URLs in dev mode
- **Files modified:** EV-ReadRank/vite.config.ts, EV-ReadRank/src/hooks/useAuthState.ts
- **Committed in:** 7b23e85

---

**Total deviations:** 2 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Both fixes were necessary for auth to work. No scope creep — fixes directly serve RR-01, RR-02, RR-03.

## Issues Encountered
- Local dev auth requires Vite proxy because backend cookies use SameSite: Lax (correct for production where all apps share .empowered.vote domain)

## Self-Check: PASSED

- VERIFIED: RR-01 (logged-in shows username + Sign out) — human confirmed
- VERIFIED: RR-02 (logged-out shows Sign in link) — human confirmed
- VERIFIED: RR-03 (Sign out clears state immediately) — human confirmed
- FOUND: 7b23e85 (bug fix commit in EV-ReadRank repo)

---
*Phase: 85-readrank-header-auth*
*Completed: 2026-03-13*
