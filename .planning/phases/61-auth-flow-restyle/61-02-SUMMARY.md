---
phase: 61-auth-flow-restyle
plan: 02
subsystem: ui
tags: [react, react-router, tailwind, auth, welcome]

# Dependency graph
requires:
  - phase: 60-design-foundation
    provides: AuthCard, PrimaryButton, SecondaryButton, AppNav components
provides:
  - WelcomeScreen page component at app/src/pages/WelcomeScreen.tsx
  - Public /welcome route registered in App.tsx
affects: [61-auth-flow-restyle, 62-onboarding-restyle, 64-inform-landing]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Public route registration: add Route before AuthGuard block in App.tsx"
    - "Redirect param forwarding: useSearchParams + redirectSuffix variable pattern"
    - "Link-wrapping a button: Link to={...} className='block' > PrimaryButton/SecondaryButton"

key-files:
  created:
    - app/src/pages/WelcomeScreen.tsx
  modified:
    - app/src/App.tsx

key-decisions:
  - "Continue exploring links to / (not /inform-landing) — Phase 64 will replace AuthGuard redirect at / with InformLanding"
  - "bg-ev-navy (#020618) as page background — NOT bg-ev-black (#1c1c1c), these two tokens are visually similar but distinct"

patterns-established:
  - "Redirect forwarding: const redirectSuffix = redirect ? `?redirect=${encodeURIComponent(redirect)}` : ''"
  - "WelcomeScreen copy style: invitational, no conversion pressure, explore-first framing"

# Metrics
duration: 2min
completed: 2026-04-25
---

# Phase 61 Plan 02: WelcomeScreen Summary

**Public /welcome entry page with trust-first invitational copy, three equal-weight CTAs, and ?redirect= forwarding to /signup and /login**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-25T20:48:54Z
- **Completed:** 2026-04-25T20:50:57Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created WelcomeScreen.tsx using AuthCard + AppNav + PrimaryButton + SecondaryButton from Phase 60
- Registered `/welcome` as a public route in App.tsx outside the AuthGuard block
- Implemented ?redirect= query param forwarding to both /signup and /login via `redirectSuffix`
- Used invitational copy ("welcome to explore freely — and if a topic moves you, you can join the conversation") with no pressure language

## Task Commits

Each task was committed atomically:

1. **Task 1: Create WelcomeScreen page component** - `d74c91a` (feat)
2. **Task 2: Register /welcome public route** - `b4f895e` (feat)

**Plan metadata:** `[see below]` (docs: complete plan)

## Files Created/Modified
- `app/src/pages/WelcomeScreen.tsx` - New public WelcomeScreen page with three CTAs and redirect forwarding
- `app/src/App.tsx` - Added WelcomeScreen import and /welcome public Route

## Decisions Made
- "Continue exploring" links to `/` — Phase 64 will replace the AuthGuard redirect at `/` with InformLanding for unauthenticated users. Until then, unauthenticated visitors clicking "Continue exploring" will land at `login.empowered.vote/login` via AuthGuard. This is documented expected behavior, not a bug.
- Page background is `bg-ev-navy` (`#020618`), not `bg-ev-black` (`#1c1c1c`). The two tokens look nearly identical but are distinct — ev-navy is the v2.0 primary surface color for all Phase 61 auth pages.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- AUTH-01 requirement satisfied: WelcomeScreen exists as a public invitational entry point
- Phase 61 plans 03–06 can proceed (LoginPage restyle, SignupPage restyle, etc.)
- Phase 62 (Onboarding Restyle) dependency on WelcomeScreen existence is now met
- Phase 64 (InformLanding) will update the "Continue exploring" link destination from `/` to `/` (already correct — Phase 64 changes what `/` renders for unauthenticated users, not the link target)

---
*Phase: 61-auth-flow-restyle*
*Completed: 2026-04-25*
