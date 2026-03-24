---
phase: 44-accounts-api-sso-infrastructure
plan: 01
subsystem: auth
tags: [cookie, sso, cors, express, cookie-parser]

# Dependency graph
requires:
  - phase: 40-frontend-auth-updates
    provides: login/logout endpoints and auth middleware already in place
provides:
  - httpOnly ev_session cookie issued on every successful login (write-side of SSO)
  - ev_session cookie cleared on logout unconditionally (even on expired JWT)
  - CORS config upgraded to support credentialed cross-origin requests
  - COOKIE_DOMAIN env var for production .empowered.vote domain scoping
affects:
  - 44-02 (cookie-reader plan — reads ev_session set here)
  - any plan implementing cross-app silent auth (relies on this cookie)

# Tech tracking
tech-stack:
  added: [cookie-parser, @types/cookie-parser]
  patterns:
    - "Shared cookie options helper (evSessionCookieOptions): ensures domain/path match between set and clear"
    - "Pre-requireAuth middleware for cookie clear on logout: cookie removed even when JWT expired"
    - "CORS origin function with exact-match in prod, allow-all in dev, credentials: true"

key-files:
  created: []
  modified:
    - backend/src/lib/env.ts
    - backend/src/index.ts
    - backend/src/routes/auth.ts
    - backend/package.json

key-decisions:
  - "evSessionCookieOptions() helper shared by login set and logout clear — prevents silent ignore if domain/path differ"
  - "Cookie cleared in pre-requireAuth middleware on logout — 401 from expired JWT still clears the cookie"
  - "COOKIE_DOMAIN defaults to empty string (host-only cookie in dev); production sets .empowered.vote"
  - "Login JSON response body unchanged — res.cookie() appends Set-Cookie header without affecting body"
  - "No cookie on signup — data.session is null when email confirmation enabled; cookie issued on first login"

patterns-established:
  - "Pre-auth middleware pattern for unconditional cookie operations on logout"
  - "evSessionCookieOptions() function pattern for consistent cookie attribute sharing"

# Metrics
duration: 3min
completed: 2026-03-24
---

# Phase 44 Plan 01: Accounts API SSO Infrastructure Summary

**httpOnly ev_session cookie (refresh token) issued on login and cleared unconditionally on logout, with credentialed CORS support for cross-origin cookie delivery**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-24T19:17:11Z
- **Completed:** 2026-03-24T19:19:59Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- cookie-parser installed and registered as first middleware after helmet()
- COOKIE_DOMAIN env var added to env schema (optional, empty string default = host-only in dev)
- CORS config replaced: origin function with exact-match in prod / allow-all in dev, credentials: true (enables cross-origin cookie delivery)
- POST /login sets ev_session httpOnly cookie with refresh_token value and 30-day maxAge
- POST /logout clears ev_session cookie unconditionally before requireAuth — expired JWT no longer blocks cookie clear

## Task Commits

Each task was committed atomically:

1. **Task 1: Install cookie-parser, add COOKIE_DOMAIN env var, update CORS config** - `629fab1` (feat)
2. **Task 2: Set ev_session cookie on login, clear on logout (with expired-JWT handling)** - `9aa42e3` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `backend/src/lib/env.ts` - Added COOKIE_DOMAIN optional env var (default '')
- `backend/src/index.ts` - Added cookieParser() middleware, replaced CORS config with credentialed origin function
- `backend/src/routes/auth.ts` - evSessionCookieOptions() helper, cookie set on login, pre-auth cookie clear on logout
- `backend/package.json` - cookie-parser + @types/cookie-parser added

## Decisions Made

- **evSessionCookieOptions() helper**: A shared function (not an inline object) prevents the classic bug where set uses `domain: '.empowered.vote'` and clear omits it — the browser silently ignores a clearCookie that doesn't match the original Set-Cookie attributes.
- **Pre-requireAuth middleware for logout cookie clear**: If clear lived inside requireAuth's success path, an expired JWT would return 401 before the cookie ever got cleared. Moving it to a pre-middleware ensures the cookie is always removed regardless of token validity.
- **No cookie on signup**: data.session is null when Supabase email confirmation is enabled. Cookie is issued on first successful login after email confirmation.
- **COOKIE_DOMAIN defaults to ''**: Empty string → domain attribute omitted → host-only cookie. Correct behavior for localhost dev. Production Render env must set COOKIE_DOMAIN=.empowered.vote.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

**Production environment variable required:**

Add to Render environment for `ev-accounts-api`:

```
COOKIE_DOMAIN=.empowered.vote
```

This scopes the ev_session cookie to all subdomains of empowered.vote, enabling cross-app SSO between accounts.empowered.vote, app.empowered.vote, and any other *.empowered.vote apps.

Do NOT set COOKIE_DOMAIN in development — empty string = host-only cookie (correct for localhost).

## Next Phase Readiness

- Plan 44-02 (cookie-reader) can proceed — ev_session is now being set on every login
- The cookie's value is the Supabase refresh_token; 44-02 will exchange it for a fresh access_token via Supabase token refresh endpoint
- CORS credentials: true is in place — cross-origin apps can receive the Set-Cookie header

---
*Phase: 44-accounts-api-sso-infrastructure*
*Completed: 2026-03-24*
