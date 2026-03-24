---
phase: 45-profile-hub-ctc-silent-sso
plan: 01
subsystem: auth
tags: [sso, cookie, profile-hub, react, fetch, credentials]

# Dependency graph
requires:
  - phase: 44-accounts-api-sso-infrastructure
    provides: GET /api/auth/session endpoint + ev_session cookie infrastructure + POST /api/auth/logout with cookie clearing
provides:
  - Silent SSO session inheritance in Profile Hub (app/src/App.tsx) — reads ev_session cookie on mount, authenticates without login prompt
  - SSO-aware logout in DashboardPage.tsx — POST /api/auth/logout clears shared ev_session cookie before local clearAuth
affects: [phase-46, phase-47, phase-48]

# Tech tracking
tech-stack:
  added: []
  patterns: [silentSsoCheck inline async function, 150ms spinner delay, credentials include fetch, 500ms toast-before-clearAuth pattern]

key-files:
  created: []
  modified: [app/src/App.tsx, app/src/pages/DashboardPage.tsx]

key-decisions:
  - "Raw fetch with credentials: 'include' for SSO check (not apiFetch which prepends /api — would double-prefix)"
  - "500ms delay before clearAuth so toast is visible before AuthGuard redirect triggers"
  - "150ms spinner delay prevents flash on fast SSO checks — setLoading(false) immediately, re-enable after 150ms if still pending"
  - "Always clear local state on logout catch — network errors must not block user from signing out"
  - "accessToken included as Bearer header on logout — enables Supabase session revocation via requireAuth middleware"

patterns-established:
  - "SSO check pattern: raw fetch to /api/auth/session with credentials include, 3s AbortController timeout, single 5xx retry"
  - "Toast-before-redirect: show toast, delay 500ms, then clearAuth — AuthGuard will redirect after state clears"

# Metrics
duration: 1min
completed: 2026-03-24
---

# Phase 45 Plan 01: Profile Hub Silent SSO Summary

**Silent SSO cookie check on App.tsx mount + logout that clears ev_session cookie via POST /api/auth/logout with 'You've been signed out' toast**

## Performance

- **Duration:** ~1 min (continuation — Task 1 was pre-completed)
- **Started:** 2026-03-24T20:15:02Z
- **Completed:** 2026-03-24T20:16:03Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Profile Hub now silently inherits sessions from accounts.empowered.vote via ev_session cookie on page load
- Logout clears the shared ev_session cookie via POST /api/auth/logout before clearing local auth state
- 150ms spinner delay prevents visible flash on fast SSO checks
- "You've been signed out" toast appears for 500ms before AuthGuard redirect fires

## Task Commits

Each task was committed atomically:

1. **Task 1: Add silent SSO check to App.tsx mount useEffect** - `115a965` (feat)
2. **Task 2: Upgrade DashboardPage logout with cookie clearing and toast** - `871d36c` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified
- `app/src/App.tsx` - Silent SSO check in mount useEffect else-branch; three-branch pattern: (1) hash fragment, (2) stored token, (3) SSO check with 150ms spinner delay
- `app/src/pages/DashboardPage.tsx` - handleLogout replaces bare clearAuth onClick; POST /api/auth/logout with credentials: 'include' + Bearer token; toast state; toast rendered at fixed bottom-center

## Decisions Made
- **Raw fetch vs apiFetch for SSO check**: Used raw `fetch` directly because `apiFetch` in `lib/api.ts` prepends `/api` to the path — using it for `/api/auth/session` would produce `/api/api/auth/session`. Raw fetch with full path avoids this.
- **500ms delay before clearAuth**: AuthGuard redirects immediately when `isAuthenticated` becomes false. The toast would be invisible without a brief delay. 500ms is short enough to feel instant but registers visually.
- **accessToken in logout headers**: Included `Authorization: Bearer {token}` so the `requireAuth` middleware on the logout route can revoke the Supabase session, not just clear the cookie.
- **Always clear on catch**: Any network or API error during logout still clears local state. Users must always be able to sign out.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Profile Hub silent SSO complete — users with valid ev_session cookies arrive authenticated
- Phase 45 Plan 02 (CTC silent SSO) follows the same pattern established here
- Phases 46–47 (CompassV2, Essentials SSO) can use App.tsx pattern as reference
- No blockers

---
*Phase: 45-profile-hub-ctc-silent-sso*
*Completed: 2026-03-24*
