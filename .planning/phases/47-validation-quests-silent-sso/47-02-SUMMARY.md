---
phase: 47-validation-quests-silent-sso
plan: 02
subsystem: auth
tags: [sso, logout, ev_session, cookie, fetch, supabase, vite, react]

# Dependency graph
requires:
  - phase: 47-validation-quests-silent-sso plan 01
    provides: isAuthChecking state, initSso() SSO session inheritance, VITE_ACCOUNTS_API_URL usage pattern
  - phase: 46-essentials-compassv2-silent-sso
    provides: POST /api/auth/logout endpoint on ev-accounts API (clears ev_session cookie)
provides:
  - VQ signOut() upgraded to POST /api/auth/logout with credentials:include before supabase.auth.signOut()
  - Logout coordination — logging out from VQ propagates to all EV apps on their next visit
  - Network-failure-safe logout (try/catch ensures local signOut always executes)
affects:
  - future-sso-phases
  - ctc-logout-coordination

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Logout coordination: POST /api/auth/logout with credentials:include before supabase.auth.signOut()"
    - "Fire-and-forget with catch: POST that fails must never block local signOut"
    - "VITE_ACCOUNTS_API_URL for accounts API (separate from VITE_API_URL for VQ backend)"

key-files:
  created: []
  modified:
    - "C:/Validation Quests/frontend/src/contexts/AuthContext.tsx"

key-decisions:
  - "POST (not GET) to /api/auth/logout — matches ev-accounts endpoint contract"
  - "credentials: include is mandatory — cross-origin cookie transport requires it"
  - "No Authorization header — endpoint reads ev_session cookie, not bearer token"
  - "try/catch around the POST — network failure must never hang or prevent local signOut"
  - "supabase.auth.signOut() runs unconditionally after the POST block"

patterns-established:
  - "Logout coordination pattern: POST cookie-clear endpoint → local Supabase signOut"

# Metrics
duration: 5min
completed: 2026-03-24
---

# Phase 47 Plan 02: Logout Coordination Summary

**VQ signOut() now POSTs to /api/auth/logout (with credentials:include) before supabase.auth.signOut(), propagating logout to all EV apps via the shared ev_session cookie**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-24T21:44:00Z
- **Completed:** 2026-03-24T21:49:44Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- signOut() now calls POST /api/auth/logout with credentials:include before local Supabase signOut
- Network failure is caught silently — local signOut always completes regardless
- VITE_ACCOUNTS_API_URL is checked for existence before fetch (handles unconfigured envs)
- TypeScript compiled with zero errors; Vite build clean
- Header.tsx signOut call unchanged — no callers modified

## Task Commits

Each task was committed atomically:

1. **Task 1: Upgrade signOut to clear ev_session cookie before Supabase signOut** - `231eb6c` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `C:/Validation Quests/frontend/src/contexts/AuthContext.tsx` - signOut() upgraded with cookie-clear POST before supabase.auth.signOut()

## Decisions Made
- POST (not GET) to /api/auth/logout — matches the ev-accounts endpoint contract established in Phase 46
- No Authorization header on the POST — the endpoint identifies the user via the ev_session cookie, not a bearer token
- try/catch around fetch — any network failure logs `[SSO] logout cookie clear failed` and continues to local signOut
- supabase.auth.signOut() is always called — the POST is advisory (best-effort cookie clear)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required. VITE_ACCOUNTS_API_URL is already present in VQ frontend config from Plan 47-01.

## Next Phase Readiness
- Phase 47 logout coordination complete. VQ now participates fully in the cross-app SSO lifecycle (session inherit on load + cookie clear on logout).
- No blockers. Phase 47 is complete if no further VQ SSO tasks are planned.

---
*Phase: 47-validation-quests-silent-sso*
*Completed: 2026-03-24*
