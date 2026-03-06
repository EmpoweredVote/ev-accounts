---
phase: 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity
plan: 03
subsystem: ui
tags: [react, coach-mark, onboarding, compass, library, tour, localStorage, framer-motion]

# Dependency graph
requires:
  - phase: 66-01
    provides: CoachMark.jsx reusable spotlight overlay component with useCoachMark hook

provides:
  - Library.jsx: 2-step coach mark tour on first visit (+ button and Full Calibration CTA targets)
  - Compass.jsx: Compare deep-dive 4-step tour on first compare interaction (politician picker, topic dropdown, overlay, spoke inversion)

affects: [66-04, any future onboarding or compare UX work]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Callback ref pattern: assigns ref to first matching element in a render loop without re-render side effects"
    - "DOM query targeting for child component elements: getCompareTourRef uses document.querySelector for ComparePanel internals not accessible via React refs"
    - "compareTourDismissed.current set on dismiss: prevents tour from firing on subsequent comparePol changes within same session"

key-files:
  created: []
  modified:
    - CompassV2/src/pages/Library.jsx
    - CompassV2/src/pages/Compass.jsx
    - CompassV2/src/components/Layout.jsx

key-decisions:
  - "4-step compare tour consolidated from 8+ spec steps to: picker, topic dropdown, overlay explanation, spoke inversion concept"
  - "Callback ref pattern used for addButtonRef: iterates topic card loop without needing a separate flattened list"
  - "DOM queries for ComparePanel internals: avoids needing to modify ComparePanel.jsx to expose refs"
  - "compareTourDismissed.current updated synchronously on dismiss: prevents re-fire within same session if comparePol changes"

patterns-established:
  - "Tour trigger pattern: useEffect watching trigger condition + 300-600ms setTimeout for DOM readiness"
  - "Tour cleanup pattern: all onboarding_ localStorage keys removed from Layout.jsx handleClearCompass"

requirements-completed: [ONBOARD-03, ONBOARD-06]

# Metrics
duration: 5min
completed: 2026-03-06
---

# Phase 66 Plan 03: Library Tour and Compare Deep-Dive Tour Summary

**Library 2-step coach mark tour (+ button and Full Calibration CTA) and Compare 4-step deep-dive tour (picker, topic, overlay, spoke inversion clarification) using CoachMark.jsx spotlight system**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-06T02:55:08Z
- **Completed:** 2026-03-06T03:00:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Library.jsx: 2-step tour triggers on first visit after `answeredLoaded`; step 1 spotlights the first "+" add button via callback ref, step 2 spotlights the Full Calibration CTA button; persists via `onboarding_libraryTour`
- Compass.jsx: 4-step compare deep-dive tour triggers 600ms after first `comparePol` selection; covers politician picker, topic dropdown, radar overlay explanation, and spoke inversion conceptual clarification; persists via `onboarding_compareTour`
- Layout.jsx: `handleClearCompass` now removes both `onboarding_libraryTour` and `onboarding_compareTour` alongside existing onboarding cleanup flags
- Both tours use Skip All and Next controls, are fully independent of each other and of the post-cal tour, and never repeat after dismissal

## Task Commits

Each task was committed atomically from the CompassV2 repository:

1. **Task 1: Add Library page 2-step coach mark tour** - `748ef45` (feat)
2. **Task 2: Add Compare deep-dive tour on first compare interaction** - `4b59914` (feat)

## Files Created/Modified

- `CompassV2/src/pages/Library.jsx` - Added CoachMark import, libTourStep state, addButtonRef/fullCalRef tour targets, callback ref for first + button, tour trigger useEffect, advanceLibTour/skipLibTour handlers, CoachMark render
- `CompassV2/src/pages/Compass.jsx` - Added CoachMark import, compareTourStep state, compareTourDismissed ref, chartContainerRef, getCompareTourRef DOM query helper, compareTourMessages, advanceCompareTour/skipCompareTour handlers, CoachMark render; also contains 66-02 post-cal tour (committed separately as 01f6700)
- `CompassV2/src/components/Layout.jsx` - Added `onboarding_libraryTour` and `onboarding_compareTour` cleanup in handleClearCompass

## Decisions Made

- 4-step compare tour rather than 8+ steps (per plan discretion note): consolidates picker, topic, overlay, and spoke inversion concepts without overwhelming new users
- Callback ref pattern for `addButtonRef`: avoids needing a pre-flattened topic list; assigns to the first rendered non-compass topic card's `+` button
- DOM queries for ComparePanel internals: `document.querySelector('.bg-white.rounded-2xl.border.border-neutral-200')` targets the panel card; `document.getElementById('topic-dropdown')` targets the dropdown — avoids needing to modify ComparePanel.jsx
- `compareTourDismissed.current` updated synchronously when tour dismissed: prevents tour from re-firing if user switches politicians in the same session

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] 66-02 post-cal tour was already committed (01f6700) by a prior session**
- **Found during:** Task 2 verification (checking git log)
- **Issue:** Compass.jsx had a 66-02 commit (`01f6700`) applied before this plan ran — removing SpokeHint, adding post-cal tour refs, tour trigger in onComplete, CoachMark render for post-cal tour
- **Fix:** Recognized as pre-existing committed work; did not duplicate or revert; the compare tour was added on top of already-present post-cal tour scaffolding cleanly
- **Files modified:** None additional (pre-existing commit)
- **Verification:** Build passes cleanly; both tours coexist without conflict

---

**Total deviations:** 1 (pre-existing commit, no code change needed)
**Impact on plan:** No scope creep; both tours function as specified.

## Issues Encountered

- A prior agent session had already committed the 66-02 post-cal tour changes to Compass.jsx before this plan executed. This meant the CoachMark import, `spokeRef`, `compareRef`, `backToLibRef`, and `helpBtnRef` refs were already present. The compare tour was added cleanly alongside them with no conflicts.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Both Library and Compare tours are live and functional
- All onboarding localStorage keys (`onboarding_libraryTour`, `onboarding_compareTour`, `onboarding_postCalTour`, `onboarding_writeInHint`) cleared by `handleClearCompass`
- 66-04 (any remaining onboarding or UX work) can proceed without blockers

## Self-Check: PASSED

- FOUND: CompassV2/src/pages/Library.jsx (modified with tour code)
- FOUND: CompassV2/src/pages/Compass.jsx (modified with compare tour)
- FOUND: CompassV2/src/components/Layout.jsx (cleanup flags added)
- FOUND commit 748ef45 (Task 1: Library tour)
- FOUND commit 4b59914 (Task 2: Compare deep-dive tour)

---
*Phase: 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity*
*Completed: 2026-03-06*
