---
status: passed
score: 9/9 must-haves verified
---

# Phase 45 Verification

**Phase Goal:** Profile Hub and CTC automatically inherit an active session on load — a user already logged in at accounts.empowered.vote arrives at either app already authenticated without a re-login prompt. Logout at either app clears the shared cookie.

**Verified:** 2026-03-24
**Re-verification:** No — initial verification

## Must-Haves Check

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `app/src/App.tsx` contains `silentSsoCheck` fetching `/api/auth/session` with `credentials: 'include'` | VERIFIED | App.tsx:78 defines `silentSsoCheck`; App.tsx:86-88 issues `fetch(url, { credentials: 'include' })` |
| 2 | `app/src/App.tsx` uses 150ms spinner delay in SSO check branch | VERIFIED | App.tsx:118-119: `setLoading(false)` then `setTimeout(() => setLoading(true), 150)` before awaiting `silentSsoCheck()` |
| 3 | `app/src/pages/DashboardPage.tsx` logout calls `POST /api/auth/logout` with `credentials: 'include'` | VERIFIED | DashboardPage.tsx:166-175: raw `fetch` with `method: 'POST'` and `credentials: 'include'` to `${VITE_API_URL}/api/auth/logout` |
| 4 | `app/src/pages/DashboardPage.tsx` shows "You've been signed out" toast | VERIFIED | DashboardPage.tsx:176: `setShowSignedOutToast(true)`; DashboardPage.tsx:413-416: renders fixed toast with text "You've been signed out" |
| 5 | `C:/Project Test/frontend/src/services/accountsApi.ts` exports `ssoSessionCheck` function | VERIFIED | accountsApi.ts:132: `export async function ssoSessionCheck()` |
| 6 | `ssoSessionCheck` uses `credentials: 'include'` targeting `/api/auth/session` | VERIFIED | accountsApi.ts:136: `url = \`${ACCOUNTS_API_URL}/api/auth/session\``; accountsApi.ts:141-144: `fetch(url, { credentials: 'include' })` |
| 7 | `AuthInitializer.tsx` calls `ssoSessionCheck` only when no `ev_refresh_token` in localStorage | VERIFIED | AuthInitializer.tsx:15: reads `localStorage.getItem('ev_refresh_token')`; line 17: `if (!storedRefresh)` guard before `ssoSessionCheck()` call at line 24 |
| 8 | `Header.tsx` logout uses raw `fetch` with `credentials: 'include'` targeting `/api/auth/logout` | VERIFIED | Header.tsx:24-28: `fetch(\`${ACCOUNTS_API_URL}/api/auth/logout\`, { method: 'POST', credentials: 'include' })` |
| 9 | `Header.tsx` logout does NOT navigate to `/login` | VERIFIED | `handleLogout` (Header.tsx:22-35) calls `clearAuth()` and `setShowSignedOutToast(true)` only — no `navigate('/login')` or redirect |

**Score:** 9/9 must-haves verified

## Summary

All nine must-haves pass. Both sides of the silent SSO handshake are implemented:

- **Profile Hub (app/src):** `App.tsx` has a fully wired `silentSsoCheck` in the no-local-token branch with a 150ms spinner delay. `DashboardPage.tsx` logout posts to `/api/auth/logout` with cookie credentials and surfaces a "You've been signed out" toast before clearing local auth state.

- **CTC (C:/Project Test/frontend):** `accountsApi.ts` exports `ssoSessionCheck` using `credentials: 'include'` against the correct accounts API endpoint. `AuthInitializer.tsx` gates the call behind the `!ev_refresh_token` check, preventing redundant SSO attempts for already-authenticated users. `Header.tsx` logout sends `credentials: 'include'` to clear the shared cookie and shows a toast without redirecting to `/login`, keeping CTC's own auth flow intact.

Phase goal is achieved. The shared `ev_session` cookie path is wired end-to-end for both apps.

---

_Verified: 2026-03-24_
_Verifier: Claude (gsd-verifier)_
