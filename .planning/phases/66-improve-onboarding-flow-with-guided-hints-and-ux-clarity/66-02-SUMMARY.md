---
phase: 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity
plan: "02"
subsystem: CompassV2
tags: [onboarding, guided-tour, coach-mark, calibration, ux]
dependency_graph:
  requires: ["66-01"]
  provides: ["post-calibration-tour", "write-in-hint", "celebration-manual-dismiss"]
  affects: ["Compass.jsx", "CalibrationOverlay.jsx", "Layout.jsx"]
tech_stack:
  added: []
  patterns:
    - "Post-calibration 4-step guided tour using CoachMark with localStorage persistence"
    - "Inline text hint on first calibration question for write-in awareness"
    - "Callback ref pattern (el => { ref1.current = el; ref2.current = el; }) for shared DOM targets"
    - "DOM query via document.querySelector for help button outside React tree (tour step 3)"
key_files:
  created: []
  modified:
    - CompassV2/src/pages/Compass.jsx
    - CompassV2/src/components/CalibrationOverlay.jsx
    - CompassV2/src/components/Layout.jsx
decisions:
  - "Reuse chartContainerRef for spokeRef (both target same chart div) via callback ref"
  - "Keep existing compare deep-dive tour code untouched (added in 66-03 by prior session)"
  - "Inline text hint rather than CoachMark spotlight for write-in awareness (per plan spec: subtle)"
  - "Remove 3-second auto-dismiss from celebration screen so user clicks manually before tour fires"
metrics:
  duration: "~6 minutes"
  completed: "2026-03-05"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 3
---

# Phase 66 Plan 02: Post-Calibration Guided Tour and Write-In Hint Summary

**One-liner:** 4-step guided tour fires after calibration celebration dismiss via CoachMark spotlights on spoke/compare/library/help, with subtle inline write-in awareness hint on first question.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add post-calibration guided tour to Compass page | `01f6700` | `Compass.jsx` |
| 2 | Add write-in awareness hint + remove auto-dismiss timer | `f2c978e` | `CalibrationOverlay.jsx`, `Layout.jsx` |

## What Was Built

### Task 1 — Post-calibration guided tour (Compass.jsx)

- **Removed** `SpokeHint` component function (lines 12-29 in original) — the old floating tooltip hinting users to click spokes
- **Removed** `showSpokeHint` state and `dismissSpokeHint` handler
- **Removed** both `{showSpokeHint && <SpokeHint>}` render calls from desktop and mobile chart areas
- **Added** `tourStep` state (`-1` = inactive, `0-3` = active step), initialized from `useState(-1)`
- **Added** tour target refs: `spokeRef`, `compareRef`, `backToLibRef`, `helpBtnRef`
- **Added** `tourMessages` array with 4 contextual strings per tour step
- **Added** `advanceTour()` — increments step or dismisses + sets `onboarding_postCalTour` on last step
- **Added** `skipTour()` — immediately sets `onboarding_postCalTour` and resets step
- **Added** `useEffect` watching `tourStep === 3` to capture the help button DOM node via `document.querySelector('[aria-label="Help"]')` (button is in Layout.jsx, outside Compass tree)
- **Attached refs:**
  - `backToLibRef` on the "Back to Library" button
  - `compareRef` on the Compare button inside `ActionButtons()`
  - Desktop chart div uses callback ref: `ref={(el) => { chartContainerRef.current = el; spokeRef.current = el; }}`
- **Modified `onComplete` handler** to trigger `setTimeout(() => setTourStep(0), 500)` after calibration completes, only when `onboarding_postCalTour` is not set
- **Added CoachMark render** at end of compass div: conditionally renders when `tourStep >= 0`, selects correct targetRef per step, shows Next/Skip All tour UI

### Task 2 — Write-in awareness hint + auto-dismiss removal (CalibrationOverlay.jsx, Layout.jsx)

- **Removed** the 3-second auto-dismiss `useEffect` from the "complete" step — celebration screen now requires manual "View My Compass" click (no `setTimeout` with `onComplete()`)
- **Added** `writeInHintShown` state (`useState(() => !!localStorage.getItem("onboarding_writeInHint"))`)
- **Added** `useEffect` watching `currentIndex`: sets `onboarding_writeInHint` and marks hint shown when user advances past first question
- **Added** write-in button `onClick` handler extension: dismisses hint when "Write your own..." is clicked
- **Added** inline hint text: `<p className="text-xs text-gray-400 text-center mt-1">You can always write your own stance if none of these fit</p>` — rendered only when `currentIndex === 0 && !writeInHintShown && !showWriteIn`
- **Layout.jsx** `handleClearCompass`: added `localStorage.removeItem("onboarding_postCalTour")` and `localStorage.removeItem("onboarding_writeInHint")` alongside existing cleanup

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Scope Observations

The file already contained a compare deep-dive tour (`compareTourStep`, `compareTourMessages`, `advanceCompareTour`, `skipCompareTour`, `getCompareTourRef`, `chartContainerRef`) added by a prior session (66-03). This code was preserved intact. The post-calibration tour (`tourStep`) was added alongside it as a separate system, using `spokeRef` sharing `chartContainerRef`'s target via the callback ref pattern.

Layout.jsx already had `onboarding_compareTour` and `onboarding_libraryTour` in the clear list — only the two new flags were added.

## Verification

- `npm run build` succeeds with no errors (only pre-existing chunk size warning)
- `SpokeHint` function no longer exists in `Compass.jsx` (grep returns no results)
- `tourStep`, `tourMessages`, `advanceTour`, `skipTour` present and wired correctly
- `writeInHintShown` state initialized from localStorage, rendered conditionally on first question
- Celebration screen has no `setTimeout` — only "View My Compass" button triggers `onComplete`
- `onboarding_postCalTour` and `onboarding_writeInHint` cleared in `handleClearCompass`

## Self-Check: PASSED

All modified files exist and build cleanly. Commits verified:
- `01f6700` — Task 1 post-calibration tour
- `f2c978e` — Task 2 write-in hint + auto-dismiss removal
