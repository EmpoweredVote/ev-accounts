---
phase: 19-calibration-flow-fixes
plan: 02
subsystem: ui
tags: [react, calibration, radar-chart, tailwind, ev-ui]

# Dependency graph
requires:
  - phase: 19-01-calibration-flow-fixes
    provides: CalibrationOverlay resumeMode, exit gating, Compass auto-routing logic
  - phase: 18-calibration-flow-fixes
    provides: tension title parsing (parseTensionTitle) used throughout calibration UI
provides:
  - Gray dashed unanswered spoke rendering in RadarChartCore via unansweredSpokes prop
  - Compass.jsx chartData and unansweredSpokesMap memos for complete chart data pipe
  - BelowThresholdChart component: grayed RadarChart with overlay CTA (replaces MinimumProgress)
  - startAtPick prop on CalibrationOverlay: enters pick step with existing topics pre-selected
  - Manual Next flow in calibration (auto-advance removed)
  - Completion loop fix: skips celebration when finalAnsweredCount < 3
affects: [compass-page, calibration-overlay, radar-chart]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "startAtPick vs resumeMode distinction: startAtPick goes to pick step, resumeMode skips to answer step"
    - "Below-threshold: render real chart at opacity-25 with overlay card instead of replacing chart area"
    - "handleStartCalibrationFromBelow3: separate handler that avoids clearing localStorage keys"

key-files:
  created: []
  modified:
    - CompassV2/src/components/CalibrationOverlay.jsx
    - CompassV2/src/pages/Compass.jsx

key-decisions:
  - "startAtPick is a separate prop from resumeMode: startAtPick=pick step, resumeMode=answer step"
  - "Below-3 overlay uses opacity-25 + pointer-events-none RadarChart, not a blank replacement"
  - "handleStartCalibrationFromBelow3 does NOT clear localStorage — preserves calibration_completed and calibration_skipped"
  - "Completion with <3 answered topics calls onComplete directly, skipping 'Your compass is ready' celebration"
  - "Pick step back button calls onSkip() in startAtPick mode (no welcome to return to)"
  - "Auto-advance after stance selection removed entirely; user clicks Next manually"

patterns-established:
  - "Calibration entry paths: welcome->pick->answer (first time), resumeMode->answer (unanswered topics), startAtPick->pick (below-3 path)"

requirements-completed: [CALIB-02]

# Metrics
duration: 20min
completed: 2026-02-21
---

# Phase 19 Plan 02: Calibration Flow Fixes (CALIB-02/03) Summary

**Gray dashed unanswered spokes on radar chart, grayed below-3 overlay with startAtPick calibration entry, manual Next (no auto-advance), and completion loop fix for sub-3-topic sessions**

## Performance

- **Duration:** ~20 min (continuation agent — fixing CALIB-03 issues from human verification)
- **Started:** 2026-02-21T19:00:00Z
- **Completed:** 2026-02-21T19:12:52Z
- **Tasks:** 2 (Task 1 from prior agent + CALIB-03 fix in this agent)
- **Files modified:** 2

## Accomplishments

- Removed 300ms auto-advance timer from `handleSelectStance` — users now click Next/Finish manually
- Replaced `MinimumProgress` (blank replacement) with `BelowThresholdChart`: real RadarChart at opacity-25 with centered overlay card showing "Answer X more topics" message and Start Calibration CTA
- Added `startAtPick` prop to `CalibrationOverlay`: opens directly at pick step with existing `selectedTopics` pre-selected — used from the below-3 overlay path without resetting any localStorage keys
- Added `handleStartCalibrationFromBelow3` in Compass.jsx: does not clear `calibration_completed` or `calibration_skipped` from localStorage; just sets `startAtPick=true` and activates overlay
- Fixed completion loop: `handleFinish` skips "Your compass is ready" celebration when `finalAnsweredCount < 3`, calling `onComplete` directly instead — user sees grayed chart with below-3 overlay
- Fixed pick step back button behavior in `startAtPick` mode: calls `onSkip()` to dismiss overlay instead of navigating to non-existent welcome step

## Task Commits

Each task was committed atomically:

1. **Task 1: Add gray dashed spoke rendering to RadarChartCore and update data pipe** - `760e6ca` (feat) [ev-ui], `57dad4d` (feat) [CompassV2]
2. **Task 2 (CALIB-03 fix): Manual Next, grayed chart overlay, startAtPick, completion loop** - `c289dc6` (fix)

**Plan metadata:** *(this commit)*

## Files Created/Modified

- `CompassV2/src/components/CalibrationOverlay.jsx` - Added `startAtPick` prop, `getInitialState` startAtPick branch, removed auto-advance setTimeout, fixed `handleFinish` completion threshold, fixed pick step back button
- `CompassV2/src/pages/Compass.jsx` - Added `BelowThresholdChart` component (replaces `MinimumProgress`), added `startAtPick` state and `handleStartCalibrationFromBelow3`, updated both desktop and mobile chart-or-below rendering blocks, passed `startAtPick` to `CalibrationOverlay`

## Decisions Made

- `startAtPick` is a separate prop from `resumeMode`: `startAtPick` goes to pick step (user can change topics), `resumeMode` jumps straight to answer step for unanswered topics. They serve distinct entry points.
- Below-3 display uses the real `RadarChart` at `opacity-25` and `pointer-events-none` instead of a blank state. This shows the user what they're building toward and feels more intentional.
- `handleStartCalibrationFromBelow3` does NOT clear `calibration_completed` or `calibration_skipped` — the user has already calibrated (or skipped). They just need to add more topics from the pick screen.
- Auto-advance removed entirely: too surprising for users who want to review their selection before moving on.
- Completion celebration skipped when `finalAnsweredCount < 3`: "Your compass is ready!" when the compass literally won't render is misleading; better to drop straight to the grayed overlay.

## Deviations from Plan

The plan as written only covered Task 1 (gray dashed spokes). Task 2 was a checkpoint that generated user feedback identifying five CALIB-03 issues. All five were fixed in this continuation agent:

1. **[Rule 1 - Bug] Auto-advance removed** — Found: 300ms setTimeout in `handleSelectStance` was surprising UX. Fix: removed entirely.
2. **[Rule 1 - Bug] Completion loop with <3 topics** — Found: `handleFinish` always showed "compass ready" celebration even when chart wouldn't render. Fix: check `finalAnsweredCount < MIN_TOPICS` and call `onComplete` directly.
3. **[Rule 2 - Missing Critical] Below-3 grayed chart overlay** — `MinimumProgress` replaced chart area with a blank state. Fixed with `BelowThresholdChart` that overlays message on real chart at reduced opacity.
4. **[Rule 2 - Missing Critical] startAtPick path** — Below-3 Start Calibration needed to open pick step without state reset. Added `startAtPick` prop and `handleStartCalibrationFromBelow3`.
5. **[Rule 1 - Bug] Pick back button in startAtPick mode** — Back button navigated to welcome which doesn't exist in startAtPick flow. Fixed to call `onSkip()`.

---

**Total deviations:** 5 auto-fixed (2 bugs, 3 missing critical UX behavior)
**Impact on plan:** All fixes directly address user-reported issues from checkpoint verification. No scope creep.

## Issues Encountered

None beyond the reported CALIB-03 issues.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 19 complete — all three CALIB scenarios addressed
- Phase 20 (final phase) can proceed
- CompassV2 build passing cleanly

---
*Phase: 19-calibration-flow-fixes*
*Completed: 2026-02-21*
