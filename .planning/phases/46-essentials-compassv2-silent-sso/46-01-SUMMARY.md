---
phase: 46-essentials-compassv2-silent-sso
plan: 01
subsystem: auth
tags: [sso, cookie, credentials-include, react-context, fetch, abort-controller]

# Dependency graph
requires:
  - phase: 44-accounts-api-sso-infrastructure
    provides: GET /api/auth/session and POST /api/auth/logout endpoints with ev_session cookie
  - phase: 45-profile-hub-ctc-silent-sso
    provides: established SSO pattern (credentials include, sequential loadAll, silent fallback)

provides:
  - publicFetch export in Essentials auth.js (raw response, no 401 redirect)
  - Silent SSO check in CompassContext.jsx loadAll before auth check
  - Logout clears ev_session cookie via POST /api/auth/logout with credentials include

affects:
  - 46-02 (CompassV2 silent SSO — same pattern, different codebase)
  - Any future Essentials auth work

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "publicFetch: raw response wrapper — no 401 side effects, safe for SSO and auth checks"
    - "SSO check block: AbortController 2s timeout, credentials include, silent catch, sequential before auth"
    - "Logout with credentials include: native fetch (not apiFetch) to clear httpOnly ev_session cookie"

key-files:
  created: []
  modified:
    - "C:/Transparent Motivations/essentials/src/lib/auth.js"
    - "C:/Transparent Motivations/essentials/src/contexts/CompassContext.jsx"

key-decisions:
  - "publicFetch placed in Essentials auth.js (same pattern as CompassV2 — consistent across all EV apps)"
  - "SSO check fires only when getToken() is null — existing sessions never disrupted"
  - "2000ms AbortController timeout (vs 3000ms in CTC) — Essentials is lighter-weight, 2s sufficient"
  - "Logout uses /api/auth/logout URL (Netlify proxy route) not /auth/logout (apiFetch route prefix issue)"
  - "No navigate() or redirectToLogin() after logout — user stays on page (same as Phase 45 decision)"

patterns-established:
  - "publicFetch pattern: all EV frontend apps now have both apiFetch (redirect on 401) and publicFetch (raw response)"
  - "SSO sequential insertion: insert before const token = getToken() in existing loadAll, no race condition"

# Metrics
duration: 2min
completed: 2026-03-24
---

# Phase 46 Plan 01: Essentials Silent SSO Summary

**Silent SSO check in CompassContext.jsx loadAll — ev_session cookie inherited on page load, publicFetch added to auth.js for safe 401 handling, logout fixed to clear shared cookie via credentials include**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-24T20:54:27Z
- **Completed:** 2026-03-24T20:57:32Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `publicFetch` to Essentials auth.js — raw response, no 401 redirect, safe for SSO token validation
- Wired silent SSO check into CompassContext.jsx `loadAll()` — fires before auth check when no local token exists, uses `credentials: 'include'` with 2s AbortController timeout, silently falls through on failure
- Fixed logout to use native `fetch` POST `/api/auth/logout` with `credentials: 'include'` — ev_session cookie is now actually cleared on logout

## Task Commits

Each task was committed atomically:

1. **Task 1: Add publicFetch export to auth.js** - `24bdee6` (feat)
2. **Task 2: Wire SSO check into CompassContext loadAll and fix logout** - `c1303f4` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `C:/Transparent Motivations/essentials/src/lib/auth.js` - Added `publicFetch` export after `apiFetch`; identical signature but returns raw response with no 401 side effects
- `C:/Transparent Motivations/essentials/src/contexts/CompassContext.jsx` - Added SSO check block at step 3 of loadAll (before getToken/auth check), switched /account/me to publicFetch with 401 clearToken path, replaced logout with native fetch + credentials include

## Decisions Made
- `publicFetch` added to Essentials (previously only CompassV2 had it) — consistent pattern across all EV apps
- SSO check uses `/api/auth/session` (Netlify proxy prefix) not `/auth/session` — Essentials uses Netlify proxy like CompassV2
- Logout URL is `/api/auth/logout` (Netlify proxy) not `/auth/logout` (the apiFetch prefix adds `/api` automatically — using apiFetch for logout would double-prefix)
- 2000ms timeout chosen (CTC uses 3000ms) — Essentials is lighter-weight context, 2s is sufficient
- No `console.error` in SSO catch block — silent fallback per established Phase 45 pattern

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 46-02 (CompassV2 silent SSO) is ready — same pattern, same auth.js already has publicFetch (from Phase 45 session hotfix commit 81a5ce3)
- Essentials SSO-07 and SSO-08 complete: silent session inherit on load + logout clears shared cookie
- Pattern fully established for any remaining EV frontend apps

---
*Phase: 46-essentials-compassv2-silent-sso*
*Completed: 2026-03-24*
