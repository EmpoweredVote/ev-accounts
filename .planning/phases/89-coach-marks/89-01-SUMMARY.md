---
phase: 89-coach-marks
plan: 01
subsystem: ui
tags: [zustand, framer-motion, coach-marks, onboarding, typescript, spotlight, tour]

# Dependency graph
requires:
  - phase: 88-practice-round
    provides: Zustand store at v5 with practiceCompleted migration pattern
provides:
  - Store v6 with coachMarksCompleted flag and completeCoachMarks action
  - CoachMark.tsx TypeScript component with spotlight overlay, SVG mask, 4-rect interactive mode, tour mode
affects:
  - 89-coach-marks (Plan 02 imports CoachMark.tsx and reads coachMarksCompleted from store)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Store version bump with isUpgrade migration: existing users get coachMarksCompleted: true, new users get false"
    - "Zustand partialize persists coachMarksCompleted to localStorage (ev_readrank key)"
    - "CoachMark component uses createPortal to document.body at z-index 60+ to float above all content"
    - "SVG mask cutout for non-interactive spotlight; 4-rect approach for allowSpotlightInteraction mode"
    - "ResizeObserver + scroll/resize listeners keep spotlight rect synchronized"

key-files:
  created:
    - EV-readrank/src/components/CoachMark.tsx
  modified:
    - EV-readrank/src/store/useReadRankStore.ts

key-decisions:
  - "useCoachMark hook intentionally NOT ported from CompassV2 — Zustand store handles persistence (locked decision from phase context)"
  - "CoachMark stays in EV-readrank/src/components/, not published to ev-ui — single consumer, cross-repo overhead unjustified"
  - "EV-readrank has its own git repository — commits go to EV-readrank repo, not the workspace root"

patterns-established:
  - "CoachMark default import pattern: import CoachMark from './CoachMark' (no named exports)"
  - "completeCoachMarks() action sets coachMarksCompleted: true in Zustand store — persisted to localStorage"

requirements-completed: [ONBD-06]

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 89 Plan 01: Coach Marks Foundation Summary

**Zustand store bumped to v6 with coachMarksCompleted migration + full TypeScript port of CompassV2 CoachMark spotlight overlay (447 lines)**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-15T23:02:24Z
- **Completed:** 2026-03-15T23:05:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Store v6 with `coachMarksCompleted: boolean` field, `completeCoachMarks()` action, migration (existing users skip coach marks, new users see them), and localStorage persistence via partialize
- Full TypeScript port of CompassV2 CoachMark.jsx (447 lines) with all features: SVG mask spotlight, 4-rect interactive mode, auto-positioned tooltip with caret, AnimatePresence transitions, ResizeObserver tracking, Escape key handler, scrollIntoView, createPortal
- TypeScript builds with zero errors after both tasks

## Task Commits

Each task was committed atomically (in EV-readrank repo):

1. **Task 1: Store v6 migration with coachMarksCompleted flag** - `1288896` (feat)
2. **Task 2: TypeScript port of CoachMark component** - `01fad0a` (feat)

## Files Created/Modified

- `EV-readrank/src/store/useReadRankStore.ts` - Store bumped to v6: coachMarksCompleted field in interface/initialState, completeCoachMarks action, v6 migrate with isUpgrade logic, partialize includes coachMarksCompleted
- `EV-readrank/src/components/CoachMark.tsx` - TypeScript port of CompassV2 CoachMark.jsx; exports default CoachMark only (no useCoachMark hook)

## Decisions Made

- useCoachMark hook intentionally NOT ported — locked decision from 89-CONTEXT.md; Zustand store handles all persistence
- CoachMark component stays in EV-readrank (not ev-ui) — single consumer, cross-repo overhead unjustified

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- EV-readrank is a separate git repository within the workspace. Commits were made to the EV-readrank repo (not the workspace root). This is expected behavior — workspace root git is for planning files only.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02 can import `CoachMark` from `./CoachMark` immediately
- Plan 02 can read `coachMarksCompleted` and call `completeCoachMarks()` from `useReadRankStore`
- TypeScript build is clean — zero errors

---
*Phase: 89-coach-marks*
*Completed: 2026-03-15*
