---
phase: 06-audit-gap-closure
plan: 01
subsystem: ui
tags: [react, quiz, auth, register, guest-state, ballotready, go]

# Dependency graph
requires:
  - phase: 04-compass-ux-enhancements
    provides: Quiz.jsx with curated/full modes, question_text field on topics
  - phase: 02-guest-first-auth
    provides: Register.jsx, CompassContext auth state (setIsLoggedIn, setUsername, refreshSelectedTopics)
  - phase: 05-essentials-improvements
    provides: CandidateOut DTO and GetCandidatesByZip handler with BallotReady races query
provides:
  - Quiz.jsx h1 headings show question_text prompts (not bare category titles) in both modes
  - Register.jsx sends guest_state in POST body so guest quiz answers persist on registration
  - Register.jsx stays on page post-registration, shows toast, syncs CompassContext auth state
  - CandidateOut.ChamberName populated from BallotReady normalizedPosition.name with position name fallback
affects: [compass-quiz-ux, candidate-classification, frontend-auth-flow]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "guest_state assembly: safeParse localStorage -> map short_title to topic UUID -> POST body"
    - "raceChamberName helper: normalizedPosition.name first, position.name fallback"

key-files:
  created: []
  modified:
    - CompassV2/src/pages/Quiz.jsx
    - CompassV2/src/pages/Register.jsx
    - EV-Backend/internal/essentials/ballotready/types.go
    - EV-Backend/internal/essentials/ballotready/client.go
    - EV-Backend/internal/essentials/handlers.go

key-decisions:
  - "Register.jsx stays on current page after registration — banner disappears because isLoggedIn becomes true"
  - "Toast fires unconditionally on registration success — same toast regardless of merge outcome (locked decision)"
  - "raceChamberName uses normalizedPosition.name first, falls back to position.name — covers all cases without extra API calls"

patterns-established:
  - "Guest state assembly: copy safeParse+buildGuestState pattern from SavePromptModal.jsx for any auth page that converts localStorage to server format"

requirements-completed: [QUIZ-01, AUTH-05]

# Metrics
duration: 2min
completed: 2026-02-18
---

# Phase 06 Plan 01: Audit Gap Closure Summary

**Three precision integration fixes: quiz cards show question prompts, guest register sends localStorage answers, and candidate ChamberName derives from BallotReady normalizedPosition**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-18T18:25:08Z
- **Completed:** 2026-02-18T18:28:24Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Quiz.jsx h1 headings in both full and curated mode now display `question_text || title` instead of bare category title
- Register.jsx assembles and POSTs guest_state (localStorage answers mapped to topic UUIDs) on registration, stays on page, shows confirmation toast
- CandidateOut.ChamberName populated from BallotReady normalizedPosition.name with position name fallback via new `raceChamberName()` helper

## Task Commits

Each task was committed atomically in the respective project repos:

1. **Task 1: Quiz.jsx question_text heading fallback** - `e1d6389` (fix) — CompassV2 repo
2. **Task 2: Register.jsx guest_state submission and toast** - `10bd250` (feat) — CompassV2 repo
3. **Task 3: CandidateOut.ChamberName from BallotReady race position** - `2128d09` (feat) — EV-Backend repo

## Files Created/Modified
- `CompassV2/src/pages/Quiz.jsx` - Both h1 headings: `question_text || title`, font size reduced one step for long text
- `CompassV2/src/pages/Register.jsx` - Added safeParse, buildGuestState, useCompass, guest_state POST, toast, no-navigate pattern
- `EV-Backend/internal/essentials/ballotready/types.go` - Added NormalizedPosition field to RacePositionNode
- `EV-Backend/internal/essentials/ballotready/client.go` - Extended racesByZipQuery to fetch `normalizedPosition { name }`
- `EV-Backend/internal/essentials/handlers.go` - Added raceChamberName() helper, assigned ChamberName in candidate loop

## Decisions Made
- Register.jsx stays on current page after registration. The guest-facing banner disappears naturally because `isLoggedIn` becomes true in CompassContext. No explicit navigate needed.
- Toast fires unconditionally on success ("Your quiz answers have been saved to your account.") — same message regardless of actual merge outcome. Per locked decision from RESEARCH.md.
- raceChamberName() uses `normalizedPosition.name` first (standardized names like "U.S. Senate", "Governor"), falls back to `position.name` (descriptive but sufficient). No new API calls needed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Note: This workspace uses separate git repos per project (CompassV2/, EV-Backend/ each have their own .git). The outer planning repo only tracks .planning/ files. Task commits were made to each project's respective repo rather than the workspace root repo.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All 3 gap closure items from the v1 milestone audit are now closed
- QUIZ-01 (question_text in quiz headings) and AUTH-05 (guest_state on register) requirements satisfied
- ChamberName fix enables classify.js to correctly place executive candidates in their sub-groups
- Phase 6 plan 01 is the only plan in Phase 6 — phase complete

---
*Phase: 06-audit-gap-closure*
*Completed: 2026-02-18*

## Self-Check: PASSED

- FOUND: `.planning/phases/06-audit-gap-closure/06-01-SUMMARY.md`
- FOUND: `e1d6389` (CompassV2 — fix(06-01): render question_text in quiz card headings)
- FOUND: `10bd250` (CompassV2 — feat(06-01): send guest_state on registration, stay on page, show toast)
- FOUND: `2128d09` (EV-Backend — feat(06-01): populate ChamberName from BallotReady normalizedPosition)
