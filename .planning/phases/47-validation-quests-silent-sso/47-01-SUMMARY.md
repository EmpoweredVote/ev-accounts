---
phase: 47-validation-quests-silent-sso
plan: 01
subsystem: auth
tags: [sso, supabase, react, typescript, vite, ev-session, cookie]

# Dependency graph
requires:
  - phase: 44-46-essentials-compassv2-silent-sso
    provides: GET /api/auth/session endpoint on ev-accounts API that returns access_token + refresh_token from ev_session cookie
provides:
  - Silent SSO session inheritance in Validation Quests frontend on app load
  - isAuthChecking boolean gate in AuthContext that holds PrivateRoute until SSO check completes
  - Deep link preservation — URLs unchanged while SSO check is in flight
affects:
  - 47-02 (VQ backend / any further VQ SSO work)
  - Any future VQ frontend changes touching AuthContext or PrivateRoute

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SSO check in useEffect: initSso() called fire-and-forget (void) to avoid dead-lock"
    - "isAuthChecking initialized true, cleared ONLY in initSso() finally block — never in onAuthStateChange"
    - "AbortController with 3s timeout for SSO fetch; AbortError silently ignored"
    - "onAuthStateChange SIGNED_IN event handles profile fetch after setSession() — no manual call"
    - "PrivateRoute returns null (not spinner) while isAuthChecking — preserves deep link URL"

key-files:
  created: []
  modified:
    - C:/Validation Quests/frontend/src/types/auth.ts
    - C:/Validation Quests/frontend/src/contexts/AuthContext.tsx
    - C:/Validation Quests/frontend/src/routes/PrivateRoute.tsx

key-decisions:
  - "isAuthChecking cleared only in initSso() finally block — never inside onAuthStateChange callback"
  - "PrivateRoute returns null (not a loading spinner) while checking — URL preserved for deep links"
  - "fetch uses credentials: include and VITE_ACCOUNTS_API_URL (not VITE_API_URL which targets VQ backend)"
  - "401 from /api/auth/session is expected for unauthenticated users — silent fallback, no error UI"
  - "setSession() triggers onAuthStateChange SIGNED_IN — no manual fetchUserProfile() needed after SSO"

patterns-established:
  - "SSO pattern: initSso() inside useEffect, fire-and-forget, finally clears isAuthChecking"
  - "Route gate pattern: return null while isAuthChecking (not redirect) to preserve deep links"

# Metrics
duration: 2min
completed: 2026-03-24
---

# Phase 47 Plan 01: Validation Quests Silent SSO Summary

**Silent SSO session inheritance in VQ frontend via ev_session cookie — isAuthChecking gate holds PrivateRoute until check resolves or times out at 3s, deep links preserved**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-24T21:44:02Z
- **Completed:** 2026-03-24T21:46:11Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added `isAuthChecking: boolean` to `AuthContextValue` interface with JSDoc
- Implemented `initSso()` in AuthContext: checks for existing session, fetches GET /api/auth/session with `credentials: include` and 3s abort timeout, calls `setSession()` with both tokens
- Updated PrivateRoute to return `null` while `isAuthChecking` is true, gating all protected routes until SSO resolves

## Task Commits

Each task was committed atomically:

1. **Task 1: Add isAuthChecking to AuthContextValue type** - `746f191` (feat)
2. **Task 2: Add SSO session check to AuthContext + update PrivateRoute** - `018fc48` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `C:/Validation Quests/frontend/src/types/auth.ts` - Added `isAuthChecking: boolean` field with JSDoc comment to `AuthContextValue` interface
- `C:/Validation Quests/frontend/src/contexts/AuthContext.tsx` - Added `isAuthChecking` state (starts `true`), `initSso()` function with SSO check logic, updated Provider value
- `C:/Validation Quests/frontend/src/routes/PrivateRoute.tsx` - Destructures `isAuthChecking`, returns `null` while checking, then falls through to session check

## Decisions Made
- `isAuthChecking` starts `true` and is set `false` only in `initSso()`'s `finally` block. This guarantees the SSO check always completes (or times out) before any route decision is made — regardless of whether Supabase already had a session.
- `PrivateRoute` returns `null` instead of a loading spinner. This preserves the URL so that when SSO completes and a session is set, the requested deep link renders directly without a redirect cycle.
- Used `VITE_ACCOUNTS_API_URL` (not `VITE_API_URL`) for the SSO fetch — the former targets the ev-accounts API, the latter targets the VQ backend.
- Did not call `fetchUserProfile()` manually after `setSession()` — `onAuthStateChange` fires `SIGNED_IN` which triggers the existing `setTimeout(() => fetchUserProfile(...), 0)` path.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required. `VITE_ACCOUNTS_API_URL` env var must already be set (established in prior phases).

## Next Phase Readiness
- VQ frontend now inherits ev_session on load — authenticated EV users arrive at VQ without re-entering credentials
- Ready for Phase 47-02 (if it covers VQ backend or additional SSO work)
- The pattern established here (initSso + isAuthChecking gate) matches the pattern used in Essentials and CompassV2 (Phases 44-46)

---
*Phase: 47-validation-quests-silent-sso*
*Completed: 2026-03-24*
