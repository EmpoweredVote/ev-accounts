---
phase: 85-readrank-header-auth
plan: 01
subsystem: ui
tags: [react, typescript, auth, ev-ui, readrank, header, profileMenu]

# Dependency graph
requires:
  - phase: 83-ev-ui-siteheader-urls
    provides: ev-ui 0.1.49 with SiteHeader profileMenu support and correct production URLs
provides:
  - useAuthState hook returning isLoggedIn, userName, loading, and logout()
  - Conditional profileMenu wired into SiteHeader in EV-ReadRank App.tsx
  - ReadRank header shows username + Sign out when logged in, Sign in link when logged out
affects: [85-readrank-header-auth, ev-readrank]

# Tech tracking
tech-stack:
  added: ["@chrisandrewsedu/ev-ui@0.1.49 (upgraded from 0.1.41)"]
  patterns: ["useAuthState hook fetches /auth/me on mount, parses JSON, exposes userName and logout()", "profileMenu undefined during loading to prevent Sign in flash for logged-in users"]

key-files:
  created: []
  modified:
    - EV-ReadRank/src/hooks/useAuthState.ts
    - EV-ReadRank/src/App.tsx
    - EV-ReadRank/package.json

key-decisions:
  - "ev-ui 0.1.49 ships no .d.ts files — profileMenu prop passed via spread cast ({ profileMenu } as any) to satisfy TypeScript without patching the library"
  - "profileMenu is undefined during loading state so SiteHeader renders no profile button, preventing a Sign in flash for logged-in users"
  - "Sign in href points to compass.empowered.vote/login (consistent with Essentials header)"

patterns-established:
  - "Auth hook pattern: fetch /auth/me on mount, parse JSON on res.ok only, expose userName and logout(), never persist auth in Zustand"
  - "profileMenu loading gate: pass undefined during in-flight auth check so profile button is hidden until state is known"

requirements-completed: [RR-01, RR-02, RR-03]

# Metrics
duration: 15min
completed: 2026-03-13
---

# Phase 85 Plan 01: ReadRank Header Auth Summary

**useAuthState extended with userName and logout(), profileMenu wired into EV-ReadRank SiteHeader with loading-gate to prevent Sign in flash**

## Performance

- **Duration:** 15 min
- **Started:** 2026-03-13T01:30:26Z
- **Completed:** 2026-03-13T01:44:56Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Upgraded ev-ui from ^0.1.41 to ^0.1.49 in EV-ReadRank
- Extended useAuthState to parse /auth/me JSON and expose userName and logout()
- Wired conditional profileMenu into SiteHeader: hidden during load, username + Sign out when logged in, Sign in link when logged out

## Task Commits

Each task was committed atomically:

1. **Task 1: Upgrade ev-ui and extend useAuthState** - `215d611` (feat)
2. **Task 2: Wire profileMenu into App.tsx SiteHeader** - `2c926d2` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified
- `EV-ReadRank/src/hooks/useAuthState.ts` - Extended with userName field, JSON parsing of /auth/me, and logout() function
- `EV-ReadRank/src/App.tsx` - MainApp now calls useAuthState, builds conditional profileMenu, passes to SiteHeader
- `EV-ReadRank/package.json` - ev-ui bumped to ^0.1.49

## Decisions Made
- ev-ui 0.1.49 ships without `.d.ts` type declarations, so `profileMenu` is not in `SiteHeaderProps`. Fixed by spreading profileMenu via `as any` cast — runtime behavior is correct, TypeScript satisfied without patching the library.
- profileMenu is set to `undefined` during loading (not a Sign-in state) so that logged-in users never see a Sign in flash while the auth check is in flight.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TypeScript compile error due to missing ev-ui type declarations**
- **Found during:** Task 2 (Wire profileMenu into App.tsx SiteHeader)
- **Issue:** ev-ui 0.1.49 dist/ contains only JS bundles with no .d.ts files. TypeScript rejected `profileMenu` prop with "Property 'profileMenu' does not exist on type 'IntrinsicAttributes & SiteHeaderProps'".
- **Fix:** Spread profileMenu via `{...({ profileMenu } as any)}` on SiteHeader — the prop is passed at runtime, TypeScript compile error eliminated without altering plan logic.
- **Files modified:** EV-ReadRank/src/App.tsx
- **Verification:** `npm run build` exits 0 with no TypeScript errors.
- **Committed in:** 2c926d2 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Fix required for TypeScript compile to pass. No behavioral scope creep — runtime profileMenu behavior matches plan exactly.

## Issues Encountered
- ev-ui 0.1.49 does not include TypeScript declarations — profileMenu prop required a type cast workaround. This is a known gap in the ev-ui library (pure JS package).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ReadRank header auth complete. RR-01, RR-02, RR-03 requirements fulfilled.
- Phase 85 is the last phase in milestone v2026.3.5 Unified Navigation Header.
- Milestone complete when this plan's docs commit is made.

## Self-Check: PASSED

- FOUND: EV-ReadRank/src/hooks/useAuthState.ts
- FOUND: EV-ReadRank/src/App.tsx
- FOUND: .planning/phases/85-readrank-header-auth/85-01-SUMMARY.md
- FOUND: 215d611 (Task 1 commit in EV-ReadRank repo)
- FOUND: 2c926d2 (Task 2 commit in EV-ReadRank repo)

---
*Phase: 85-readrank-header-auth*
*Completed: 2026-03-13*
