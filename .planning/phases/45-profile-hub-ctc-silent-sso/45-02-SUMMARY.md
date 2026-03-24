---
phase: 45-profile-hub-ctc-silent-sso
plan: 02
subsystem: auth
tags: [sso, cookie, ctc, react]
requires:
  - phase: 44-accounts-api-sso-infrastructure
    provides: GET /api/auth/session endpoint + ev_session cookie infrastructure
provides:
  - Silent SSO session inheritance in CTC (AuthInitializer.tsx)
  - ssoSessionCheck utility function in accountsApi.ts
  - SSO-aware logout in Header.tsx with shared cookie clearing
affects: [phase-46, phase-47, phase-48]
tech-stack:
  added: []
  patterns: [ssoSessionCheck exported function, 150ms spinner delay, credentials include fetch, fall-through to existing exchange logic]
key-files:
  created: []
  modified:
    - C:/Project Test/frontend/src/services/accountsApi.ts
    - C:/Project Test/frontend/src/components/AuthInitializer.tsx
    - C:/Project Test/frontend/src/components/layout/Header.tsx
key-decisions:
  - "ssoSessionCheck writes ev_refresh_token to localStorage on success, then falls through to existing exchangeRefreshToken path"
  - "SSO check skipped entirely when ev_refresh_token already exists — existing sessions not disrupted"
  - "navigate('/login') removed from logout — user stays on current page"
completed: 2026-03-24
---

# Phase 45 Plan 02: CTC Silent SSO Summary

**One-liner:** CTC silently inherits ev_session cookie via GET /api/auth/session on page load; logout clears shared cookie via POST /api/auth/logout with credentials: include.

## What Was Built

### ssoSessionCheck in accountsApi.ts (already present, confirmed)

`ssoSessionCheck()` was already present in `accountsApi.ts` from a prior session. The function:
- Fetches `GET ${ACCOUNTS_API_URL}/api/auth/session` with `credentials: 'include'`
- 3000ms AbortController timeout
- Returns `{ access_token, refresh_token }` on success, `null` on 401 or error
- Single retry after 1s on 5xx responses

### SSO Check in AuthInitializer.tsx

`AuthInitializer.tsx` now attempts silent SSO when no `ev_refresh_token` exists in localStorage:

1. If `ev_refresh_token` present: skip SSO check entirely, use existing exchange flow (no disruption to active sessions)
2. If absent: call `ssoSessionCheck()` with a 150ms spinner delay to prevent flash for fast checks
3. SSO success: write `refresh_token` to localStorage, set `storedRefresh`, fall through to existing `exchangeRefreshToken()` path
4. SSO failure/null: `clearAuth()`, `setTierResolved(true)`, resolve as unauthenticated

This pattern means the SSO path reuses the entire existing tier/admin resolution pipeline — no code duplication.

### Upgraded Logout in Header.tsx

`handleLogout` now:
- POSTs to `${ACCOUNTS_API_URL}/api/auth/logout` with `credentials: 'include'` (clears ev_session cookie)
- Sends `Authorization: Bearer {token}` when access token is available
- Always calls `clearAuth()` regardless of fetch outcome
- Shows "You've been signed out" toast for 3 seconds (fixed bottom-center)
- Does NOT navigate to `/login` — user stays on current page
- Header return wrapped in Fragment to render toast outside `<header>` element

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 6cf179f | feat(45-02): add ssoSessionCheck and wire into AuthInitializer |
| Task 2 | 762d9bd | feat(45-02): upgrade CTC logout with shared cookie clearing and toast |

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| SSO check only when no ev_refresh_token | Preserves all existing CTC sessions — only new/logged-out visitors hit the cookie endpoint |
| 150ms spinner delay | Prevents loading flash for users with valid ev_session cookie on fast connections |
| Fall-through to exchangeRefreshToken after SSO | Reuses full tier/admin resolution pipeline; avoids code duplication |
| Stay on page after logout | User may be on a public page; forcing /login redirect is disorienting for SSO scenarios |
| credentials: include on logout | Required to send the ev_session httpOnly cookie to the server for clearing |

## Deviations from Plan

None — plan executed exactly as written. Note: `ssoSessionCheck` was already present in `accountsApi.ts` from a prior session; Task 1 Part A was a no-op verification rather than a write.

## Next Phase Readiness

SSO-05 and SSO-06 are fulfilled. Phase 45 Plan 03 (Profile Hub SSO) can proceed using the same `ssoSessionCheck` pattern established here.
