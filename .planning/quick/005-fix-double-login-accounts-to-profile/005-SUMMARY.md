---
phase: quick
plan: 005
subsystem: auth
tags: [sso, hash-fragment, react, token, redirect]

requires: []
provides:
  - Single-sign-on loop between accounts.empowered.vote and profile.empowered.vote
  - Hash-fragment token passing from accounts login to profile app
  - AuthGuard external redirect to accounts auth hub with return URL
affects: [profile-app, auth-hub, any-future-empowered-vote-app]

tech-stack:
  added: []
  patterns:
    - "Hash-fragment token passing: accounts appends #access_token=TOKEN to redirect URLs"
    - "Profile extracts hash token on mount, cleans URL immediately, sets auth state"
    - "AuthGuard external redirect: unauthenticated users sent to accounts.empowered.vote/login?redirect=<encoded-url>"

key-files:
  created: []
  modified:
    - admin/src/pages/Login.tsx
    - app/src/App.tsx
    - app/src/components/AuthGuard.tsx

key-decisions:
  - "Hash fragment (not query string) for token passing — never logged by web servers, matches Supabase magic link pattern"
  - "Profile cleans URL via replaceState immediately after extraction — token never persists in browser history"
  - "Profile's own /login route and LoginPage.tsx retained as fallback for direct navigation"

patterns-established:
  - "SSO loop: profile AuthGuard -> accounts /login?redirect= -> accounts Login appends #access_token= -> profile App.tsx extracts on mount"

duration: 3min
completed: 2026-03-18
---

# Quick Task 005: Fix Double Login (Accounts to Profile) Summary

**Hash-fragment SSO loop: accounts login appends #access_token=TOKEN to redirect URL, profile extracts it on mount and authenticates without a second login**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-18T23:07:33Z
- **Completed:** 2026-03-18T23:10:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Accounts login now appends `#access_token=TOKEN` to all redirect URLs (both `?redirect=` param and default profile URL)
- Profile app extracts token from hash fragment on mount, calls `/account/me`, sets auth state, and cleans the URL — all before falling back to localStorage
- AuthGuard now redirects unauthenticated profile users to `accounts.empowered.vote/login?redirect=<encoded-return-url>` instead of the internal `/login` route
- Both apps pass TypeScript compilation with zero errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Accounts login — append access_token hash fragment to redirect URL** - `a5107c1` (feat)
2. **Task 2: Profile App.tsx — extract token from hash fragment on mount** - `014d7dc` (feat)
3. **Task 3: AuthGuard — redirect to accounts login instead of internal /login** - `7b6be4a` (feat)

## Files Created/Modified

- `admin/src/pages/Login.tsx` - Modified redirect logic to append `#access_token=${token}` to all outbound redirects
- `app/src/App.tsx` - Added hash fragment extraction block at top of auth useEffect, before localStorage fallback
- `app/src/components/AuthGuard.tsx` - Replaced `Navigate to="/login"` with external redirect to accounts.empowered.vote; removed unused `Navigate` import

## Decisions Made

- **Hash fragment over query string**: Tokens in query strings are logged by web servers and appear in browser history. Hash fragments are client-only and match the pattern Supabase already uses for magic links.
- **URL cleanup via `replaceState`**: Token cleaned from URL immediately after extraction so it never appears in browser history or gets copied in shared links.
- **Profile's /login route retained**: `LoginPage.tsx` and `/login` route in `App.tsx` left intact as a direct-access fallback. Only `AuthGuard` was changed — users who navigate directly to `profile.empowered.vote/login` still get the profile login form.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. Both apps are already deployed; changes take effect on next deploy.

## Next Phase Readiness

- SSO loop is complete end-to-end
- Any future `*.empowered.vote` app can use the same pattern: point its auth guard at `accounts.empowered.vote/login?redirect=<url>` and extract the hash fragment on mount
- `admin/src/lib/redirect.ts` already validates `*.empowered.vote` wildcards, so new subdomains are automatically trusted

---
*Phase: quick-005*
*Completed: 2026-03-18*
