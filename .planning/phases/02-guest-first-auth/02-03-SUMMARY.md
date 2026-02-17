---
phase: 02-guest-first-auth
plan: "03"
subsystem: ui
tags: [react, framer-motion, localStorage, registration, guest-first]

# Dependency graph
requires:
  - phase: 02-guest-first-auth
    provides: guest_state field on /auth/register endpoint (02-01), isLoggedIn/setIsLoggedIn in CompassContext (02-02)
provides:
  - SavePromptModal component with inline registration and localStorage dismiss tracking
  - Dismissible bottom banner (appears after modal dismiss, max 2 times)
  - Login page toast notification "Your saved answers have been restored" for server-wins merge UX
affects: [03-visual-polish, 05-candidates]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inline modal registration: send guest_state with short_title-to-UUID conversion in component"
    - "localStorage dismiss tracking: MODAL_KEY flag + BANNER_KEY counter (max 2)"
    - "Server-wins on login: clear localStorage answers/writeIns, show toast, navigate after 2s"

key-files:
  created:
    - CompassV2/src/components/SavePromptModal.jsx
  modified:
    - CompassV2/src/pages/Compass.jsx
    - CompassV2/src/pages/Login.jsx

key-decisions:
  - "Used inline form in modal (not ev-ui AuthForm) — AuthForm is full-page and unsuitable for embedding in a modal overlay"
  - "Toast uses bg-[#00657c] literal color — Tailwind custom color ev-muted-blue may not resolve in JIT without safelist; literal hex is safe"
  - "Banner links to /register (not inline form) — reduces friction of the persistent nudge without re-embedding full form"

patterns-established:
  - "SavePromptModal: self-contained guest detection via isLoggedIn from CompassContext"
  - "guest_state assembly: always convert short_title keys to topic UUIDs before sending to server"

requirements-completed: [AUTH-04, AUTH-05]

# Metrics
duration: 2min
completed: 2026-02-17
---

# Phase 2 Plan 03: Save Prompt Modal Summary

**Save prompt modal with inline registration, dismissible banner, and login page server-wins toast using Framer Motion and localStorage persistence**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-17T22:29:36Z
- **Completed:** 2026-02-17T22:31:39Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Created SavePromptModal component: appears 1.5s after guest views results, contains inline registration form (username/password/confirm), sends guest_state with UUIDs to /auth/register
- Modal dismiss flow: modal dismissed once (MODAL_KEY) → banner appears; banner dismissed up to 2 times (BANNER_KEY counter) → permanently gone
- Login page shows "Your saved answers have been restored" toast for 2 seconds when returning user has server answers that override local state; localStorage cleared after login

## Task Commits

Each task was committed atomically:

1. **Task 1: SavePromptModal component + Compass.jsx integration** - `8391492` (feat)
2. **Task 2: Login.jsx server-wins merge notification toast** - `0af44c6` (feat)

## Files Created/Modified
- `CompassV2/src/components/SavePromptModal.jsx` - New component with modal overlay, inline registration form, dismissible bottom banner, and localStorage dismiss tracking
- `CompassV2/src/pages/Compass.jsx` - Added SavePromptModal import and render at end of JSX (alongside other modals)
- `CompassV2/src/pages/Login.jsx` - Added showRestoredToast state, localStorage check after login, 2-second toast with Framer Motion, context updates for isLoggedIn and username

## Decisions Made
- Used inline form in modal instead of ev-ui AuthForm — AuthForm is a full-page component not suitable for embedding in a modal overlay
- Used `bg-[#00657c]` literal hex for toast color instead of `bg-ev-muted-blue` — Tailwind JIT may not resolve custom color aliases from config in all contexts; literal is always safe
- Banner "Sign up" link goes to /register page (not another inline form) — the persistent banner is intentionally lower friction than the modal

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- CompassV2 has its own git repository separate from the workspace root repo. Commits targeted the CompassV2 repo at `/Users/chrisandrews/Documents/GitHub/CompassV2`.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 2 complete: all 3 plans executed (backend guest_state, frontend ungating, save prompt modal)
- Phase 3 (visual polish) can begin; depends on Phase 1 only
- Guest-first auth flow fully functional: guests can explore → see results → register inline → become logged-in users without page navigation

## Self-Check: PASSED

- FOUND: CompassV2/src/components/SavePromptModal.jsx
- FOUND: CompassV2/src/pages/Compass.jsx
- FOUND: CompassV2/src/pages/Login.jsx
- FOUND: .planning/phases/02-guest-first-auth/02-03-SUMMARY.md
- FOUND commit: 8391492 (Task 1)
- FOUND commit: 0af44c6 (Task 2)

---
*Phase: 02-guest-first-auth*
*Completed: 2026-02-17*
