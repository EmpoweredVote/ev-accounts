---
phase: quick
plan: 015
subsystem: auth
tags: [session-polling, cross-app-logout, sso, ev_session, fetch, useEffect]

# Dependency graph
requires:
  - phase: quick-014
    provides: GET /api/auth/session endpoint that returns 401 when ev_session cookie absent
provides:
  - Session polling useEffect in all 5 locally-available EV apps
  - Cross-app logout sync within 60 seconds
  - Hidden-tab polling guard (visibilityState check)
affects: [all EV frontend apps, SSO login/logout behavior]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Session polling pattern: setInterval 60s, credentials:include, 401=clear auth, catch=ignore"
    - "visibilityState guard: skip fetch when tab is hidden to avoid unnecessary background traffic"

key-files:
  created: []
  modified:
    - app/src/App.tsx
    - /c/EV-CompassV2/src/components/CompassContext.jsx
    - /c/Validation Quests/frontend/src/contexts/AuthContext.tsx
    - /c/Civic Spaces/src/hooks/useAuth.ts
    - /c/read-rank/src/hooks/useAuthState.ts

key-decisions:
  - "60-second interval chosen: fast enough for UX, slow enough to avoid hammering API"
  - "visibilityState check prevents sleeping/hidden tabs from polling at all"
  - "Network errors silently ignored — transient failures must not cause false logouts"
  - "Each app uses its own logout function (clearAuth, clearToken+setState, signOut, etc.) — no new abstraction needed"

patterns-established:
  - "Session polling: useEffect guarded on auth state, 60s interval, 401=logout, catch=noop, cleanup on unmount"

# Metrics
duration: 2min
completed: 2026-04-09
---

# Quick Task 015: Session Polling Cross-App Logout Sync Summary

**60-second session polling added to all 5 EV apps so any app logout is detected platform-wide within 60 seconds via ev_session cookie invalidation**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-04-09T08:23:45Z
- **Completed:** 2026-04-09T08:25:55Z
- **Tasks:** 5 completed
- **Files modified:** 5 (across 5 separate repos)

## Accomplishments

- Added identical-in-shape session polling useEffect to all 5 locally-available EV apps
- Each app detects ev_session cookie cleared by any other EV app within 60 seconds
- Hidden and background tabs skip polling entirely (visibilityState guard)
- Network errors silently ignored — no false logouts on transient failures

## Task Commits

Each task was committed atomically to its own repo:

1. **Task 1: EV-Accounts/app — App.tsx** - `aca7af1` (feat) — EV-Accounts repo
2. **Task 2: EV-CompassV2 — CompassContext.jsx** - `05a5b11` (feat) — EV-CompassV2 repo
3. **Task 3: Validation Quests — AuthContext.tsx** - `9cf5df3` (feat) — Validation Quests repo
4. **Task 4: Civic Spaces — useAuth.ts** - `52be38d` (feat) — Civic Spaces repo
5. **Task 5: read-rank — useAuthState.ts** - `14fa928` (feat) — read-rank repo

## Files Modified

- `/c/EV-Accounts/app/src/App.tsx` - useEffect polls `/api/auth/session`; 401 calls `clearAuth()`
- `/c/EV-CompassV2/src/components/CompassContext.jsx` - useEffect polls `/api/auth/session`; 401 calls `clearToken()` + `setIsLoggedIn(false)` + `setUsername(null)`
- `/c/Validation Quests/frontend/src/contexts/AuthContext.tsx` - useEffect polls `/api/auth/session`; 401 calls `signOut()` (clears both ev_session cookie and Supabase session)
- `/c/Civic Spaces/src/hooks/useAuth.ts` - useEffect polls `ACCOUNTS_SESSION_URL`; 401 removes `cs_token` and resets `authState`
- `/c/read-rank/src/hooks/useAuthState.ts` - useEffect polls `/api/auth/session`; 401 calls `clearToken()` + resets `state` to logged-out

## Decisions Made

- **No backend changes needed.** `GET /api/auth/session` already returns 401 when ev_session cookie is absent. The entire feature was frontend-only.
- **VQ uses `signOut()` rather than a raw state clear** — because VQ authenticates via Supabase, `signOut()` handles both the ev_session cookie DELETE and `supabase.auth.signOut()`, triggering the `onAuthStateChange` handler for full cleanup.
- **Not covered:** CTC, Essentials, Treasury Tracker — not locally available. Same pattern applies when those repos are accessible.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

- All 5 apps now participate in cross-app logout sync
- Pattern is established and documented for applying to CTC, Essentials, Treasury Tracker when those repos are available
- No blockers for v2.0 planning

---
*Phase: quick-015*
*Completed: 2026-04-09*
