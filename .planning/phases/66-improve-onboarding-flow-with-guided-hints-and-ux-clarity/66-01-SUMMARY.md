---
phase: 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity
plan: 01
subsystem: ui
tags: [react, framer-motion, portal, coach-mark, onboarding, compass, tailwind]

# Dependency graph
requires:
  - phase: 65-fix-compass-page-refresh-losing-onboarding-state
    provides: CalibrationOverlay with stable state management

provides:
  - CoachMark.jsx: reusable spotlight overlay system with tour and hint modes
  - useCoachMark hook: localStorage-persisted dismiss state
  - Simplified welcome screen with inline SVG compass illustration

affects: [66-02, 66-03, subsequent plans using CoachMark for guided tours]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CoachMark via createPortal: renders above all content regardless of DOM position"
    - "SVG mask spotlight cutout: full-page dim with transparent cutout hole using SVG mask"
    - "Auto-positioning tooltip: prefer below, fallback above/left/right based on viewport space"
    - "useCoachMark hook: localStorage-persisted dismiss state with storageKey pattern"
    - "ResizeObserver + window events: recalculates spotlight position on resize/scroll"

key-files:
  created:
    - CompassV2/src/components/CoachMark.jsx
  modified:
    - CompassV2/src/components/CalibrationOverlay.jsx

key-decisions:
  - "SVG mask approach for spotlight cutout (vs CSS clip-path) — cleaner rounded hole without polygon math"
  - "Inline SVG compass illustration replaces calibration-demo.gif — no external asset, EV brand colors"
  - "Single concise p tag replaces 4-bullet ul on welcome screen — under 20 words, conversational"

patterns-established:
  - "CoachMark pattern: import CoachMark + useCoachMark from ./CoachMark, provide targetRef and storageKey"
  - "Tour mode detected by presence of onNext prop; single-hint mode is default"

requirements-completed: [ONBOARD-01, ONBOARD-04]

# Metrics
duration: 2min
completed: 2026-03-06
---

# Phase 66 Plan 01: CoachMark Component and Welcome Screen Simplification Summary

**Portal-based spotlight overlay system (CoachMark.jsx) with SVG mask cutout, Framer Motion animations, and simplified welcome screen using inline SVG compass**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-06T02:49:17Z
- **Completed:** 2026-03-06T02:52:27Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created CoachMark.jsx (344 lines) with portal rendering, SVG mask spotlight, auto-positioning tooltip, tour and hint modes, Framer Motion animations
- Exported useCoachMark hook following existing localStorage pattern (same pattern as onboarding_spokeFlip)
- Simplified CalibrationOverlay welcome step: removed GIF import, replaced 4-bullet ul with single p tag, added inline SVG compass illustration using ev-coral/ev-light-blue/ev-yellow brand colors
- Build passes cleanly with no errors

## Task Commits

Each task was committed atomically from the CompassV2 repository:

1. **Task 1: Create reusable CoachMark component** - `5b89692` (feat)
2. **Task 2: Simplify CalibrationOverlay welcome screen** - `414ef75` (feat)

## Files Created/Modified

- `CompassV2/src/components/CoachMark.jsx` - New reusable spotlight overlay component with useCoachMark hook
- `CompassV2/src/components/CalibrationOverlay.jsx` - Welcome step simplified: GIF removed, inline SVG added, bullet list replaced with concise p

## Decisions Made

- SVG mask approach chosen over CSS clip-path for the spotlight cutout: mask element produces cleaner transparent hole with proper rounded corners without needing a complex polygon path calculation
- Inline SVG compass illustration uses three layers: user polygon (ev-coral), comparison polygon (ev-light-blue), and accent dots (ev-yellow) — matches real RadarChart visual language
- Tooltip width fixed at 280px for consistent layout; auto-positions to avoid viewport overflow

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- CompassV2 is a separate git repository (not part of the workspace root git). Commits had to be made from within `/Users/chrisandrews/Documents/GitHub/CompassV2/` — resolved automatically.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CoachMark.jsx is standalone and ready for consumption by 66-02 and subsequent plans
- useCoachMark hook follows existing localStorage key pattern — import and use immediately
- Welcome screen simplification is live; no follow-up needed
- No blockers

## Self-Check: PASSED

- FOUND: CompassV2/src/components/CoachMark.jsx
- FOUND: CompassV2/src/components/CalibrationOverlay.jsx
- FOUND: .planning/phases/66-improve-onboarding-flow-with-guided-hints-and-ux-clarity/66-01-SUMMARY.md
- FOUND commit 5b89692 (Task 1: CoachMark)
- FOUND commit 414ef75 (Task 2: CalibrationOverlay)

---
*Phase: 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity*
*Completed: 2026-03-06*
