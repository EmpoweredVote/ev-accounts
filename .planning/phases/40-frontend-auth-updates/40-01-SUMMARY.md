---
phase: 40-frontend-auth-updates
plan: 01
subsystem: frontend-auth
status: complete
completed: 2026-03-22
duration: ~2 minutes
tags: [react, auth, redirect, hash-fragment, security]
requires: []
provides: [redirect-after-login, re-auth-banner, signup-redirect-passthrough]
affects: [compassv2, essentials, read-and-rank]
tech-stack:
  added: []
  patterns: [hash-fragment-token-delivery, https-redirect-validation, useMemo-mount-parse]
key-files:
  created: []
  modified:
    - app/src/pages/LoginPage.tsx
    - app/src/pages/SignupPage.tsx
decisions:
  - title: useMemo for redirect URL parsing
    choice: Parse ?redirect= once via useMemo on mount
    rationale: Avoids re-parsing URLSearchParams on every render; result is stable
  - title: https:// validation only
    choice: Accept only https:// redirect URLs; fall back to navigate('/') otherwise
    rationale: Simplest open-redirect prevention; all valid calling apps use https
  - title: No re-auth banner on signup
    choice: Banner only on LoginPage, not SignupPage
    rationale: New account flow has no prior session — "log in again" message is confusing
  - title: handleGoToSignIn() for signup done state
    choice: Named function replaces inline navigate('/login') onClick handler
    rationale: Needed to conditionally append redirect param — inline arrow function would be too complex
---

# Phase 40 Plan 01: Auth Hub Redirect-After-Login Summary

**One-liner:** Auth Hub login now redirects calling apps via `#access_token=` hash fragment when `?redirect=` param present; signup passes redirect through to login after email confirmation.

## What Was Built

The Auth Hub login and signup pages now participate in the cross-app SSO redirect flow. Frontend apps (CompassV2, Essentials, Read & Rank) can redirect unauthenticated users to `https://accounts.empowered.vote/login?redirect={returnUrl}`. After login, the Auth Hub redirects back to the calling app with the token in the hash fragment so the app can extract it client-side.

This is the core redirect plumbing for Phase 40's auth migration. It matches the existing hash-fragment extraction pattern already implemented in `app/src/App.tsx` (lines 27-37).

## Tasks Completed

1. **Task 1: Add redirect-after-login to LoginPage.tsx with re-auth banner** — commit `bfd3b6c`
   - Added `getValidatedRedirectUrl()` helper with `https://` validation
   - `useMemo` parses redirect URL once on mount
   - After successful login + `/account/me` fetch: redirects to `{redirectUrl}#access_token={token}` if param present; `navigate('/')` otherwise
   - Re-auth banner renders above the form when `redirectUrl` is truthy

2. **Task 2: Add redirect-after-signup to SignupPage.tsx** — commit `0c2daec`
   - Same `getValidatedRedirectUrl()` helper + `useMemo` pattern
   - Replaced inline `onClick={() => navigate('/login')}` with `handleGoToSignIn()` function
   - On done screen, "Go to sign in" navigates to `/login?redirect={encodedUrl}` if redirect param present; `/login` otherwise
   - No banner added (new account context makes "log in again" nonsensical)

## Files Modified

- `app/src/pages/LoginPage.tsx` — redirect-after-login, https:// validation, re-auth banner
- `app/src/pages/SignupPage.tsx` — redirect pass-through to /login after email confirmation

## Verification

- `cd app && npx tsc --noEmit` passed with zero errors after each task
- LoginPage: `redirect` param read from URL, `#access_token=` in redirect URL, banner conditional on param presence, `https://` validation with navigate('/') fallback
- SignupPage: `redirect` param read, passed through to `/login?redirect=` on done-state navigation

## Deviations

None — plan executed exactly as written.

## Key Technical Notes

- **Hash fragment, not query param** — Token delivered as `#access_token=` to match `App.tsx` extraction pattern (lines 27-37). The receiving app uses `new URLSearchParams(hash.substring(1))` to extract it without the token appearing in server logs.
- **`useMemo` parse is idiomatic** — `window.location.search` is stable after page load; `useMemo` with empty deps array effectively runs once on mount without needing `useEffect` + state.
- **`getValidatedRedirectUrl()` is shared pattern** — Same function signature in both files. Future plans can extract to a shared util if a third page needs it.
- **Signup has no access_token** — Email confirmation flow means no token at signup time. The redirect must be carried as a query param through to login, where it gets consumed after actual authentication.
