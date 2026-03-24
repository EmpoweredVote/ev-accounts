---
phase: 44-accounts-api-sso-infrastructure
plan: 02
subsystem: auth
tags: [supabase, express, sso, cookie, refresh-token, token-rotation]

# Dependency graph
requires:
  - phase: 44-accounts-api-sso-infrastructure-01
    provides: evSessionCookieOptions() helper, ev_session cookie write on login, cookie-parser middleware, COOKIE_DOMAIN env var, CORS with credentials

provides:
  - GET /api/auth/session endpoint — cookie-read side of SSO
  - Silent session inheritance for any app that holds the ev_session cookie
  - Refresh token exchange via supabaseAdmin.auth.refreshSession
  - Cookie rotation on every successful /session call

affects:
  - 45-compassv2-sso-frontend
  - 46-essentials-sso-frontend
  - 47-profile-hub-sso-frontend
  - Any Phase 45-47 frontend that needs cookie-to-token SSO

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "No-auth cookie endpoint pattern: router.get without requireAuth for unauthenticated session discovery"
    - "Empty 401 body pattern: res.status(401).end() with no JSON on SSO failure paths"
    - "Mandatory token rotation: always write rotated refresh_token back to cookie after refreshSession"

key-files:
  created: []
  modified:
    - backend/src/routes/auth.ts

key-decisions:
  - "No rate limiter on GET /session -- authLimiter (10/15min) would break apps calling this on every page load"
  - "No requireAuth on GET /session -- the endpoint exists precisely for unauthenticated clients discovering a session via cookie"
  - "Empty body on 401 -- no JSON envelope on session failure; leaks no info, keeps contract minimal"
  - "Cookie rotation is mandatory -- Supabase invalidates old refresh token immediately on use; skip rotation = guaranteed 401 on next call"
  - "clearCookie on invalid token -- stale cookies are actively cleared so browser doesn't keep retrying a dead token"

patterns-established:
  - "SSO read-side pattern: read cookie, call refreshSession, rotate cookie, return tokens -- applied to GET /session"

# Metrics
duration: 2min
completed: 2026-03-24
---

# Phase 44 Plan 02: Accounts API SSO Infrastructure Summary

**GET /api/auth/session reads ev_session httpOnly cookie, exchanges refresh token via Supabase, rotates the cookie, and returns the access/refresh token pair for silent cross-app SSO**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-24T19:22:29Z
- **Completed:** 2026-03-24T19:24:16Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- GET /api/auth/session endpoint added to auth.ts between login and logout handlers (logical order: login → session → logout)
- Cookie missing → 401 empty body (no JSON leak)
- Invalid/expired token → clearCookie + 401 empty body (stale cookie actively removed)
- Valid token → refreshSession exchange, cookie rotated with new refresh_token, 200 with { access_token, refresh_token }
- No rate limiter, no requireAuth — correct for a page-load SSO endpoint

## Task Commits

Each task was committed atomically:

1. **Task 1: Add GET /api/auth/session endpoint with token exchange and cookie rotation** - `fac2d91` (feat)

**Plan metadata:** (see final metadata commit)

## Files Created/Modified

- `backend/src/routes/auth.ts` — GET /session endpoint added (45 lines inserted, no lines removed)

## Decisions Made

- **No authLimiter on /session** — the existing limiter (10 req / 15 min per IP) is designed for credential brute-force, not for a page-load endpoint across 5 apps. Applied only to signup, login, and request-access.
- **No requireAuth on /session** — the entire purpose of this endpoint is to serve clients that have a cookie but no JWT. Applying requireAuth would make it useless.
- **Empty body on 401** — both failure paths (missing cookie, invalid token) return `res.status(401).end()` with no body. Keeps the SSO contract minimal and leaks no information.
- **Mandatory cookie rotation** — Supabase immediately invalidates the old refresh token when `refreshSession` is called. If the rotated token is not written back to the cookie, the next `/session` call will always 401. This is a critical correctness requirement, not optional.
- **Active stale cookie clearing** — when the token exchange fails (expired/revoked), `clearCookie` is called before the 401. This prevents browsers from infinitely retrying a dead refresh token on every page load.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. The COOKIE_DOMAIN env var was established in Plan 01.

## Next Phase Readiness

- Phase 44 complete — both SSO sides are live:
  - Write side: POST /login sets ev_session cookie (Plan 01)
  - Read side: GET /session reads, exchanges, and rotates ev_session cookie (Plan 02)
- Phases 45-47 (frontend SSO integration) are unblocked
- Frontend apps need to call GET /api/auth/session on load (with credentials: 'include'), then use the returned access_token for subsequent API calls

---
*Phase: 44-accounts-api-sso-infrastructure*
*Completed: 2026-03-24*
