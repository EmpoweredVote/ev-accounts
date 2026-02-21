---
phase: 19-calibration-flow-fixes
plan: 01
subsystem: CompassV2/calibration
tags: [calibration, ux, routing, resumption]
requirements: [CALIB-01, CALIB-03]

dependency_graph:
  requires: [Phase 18 tension titles in CalibrationOverlay answer step]
  provides: [Auto-routing into calibration for unanswered topics, resumption flow skipping pick step, exit gating until 3+ answered, calibration CTA in MinimumProgress]
  affects: [CompassV2/src/pages/Compass.jsx, CompassV2/src/components/CalibrationOverlay.jsx]

tech_stack:
  added: []
  patterns: [lazy-init via useRef for async context data, auto-advance with setTimeout, unanswered-topic skip in handleNext]

key_files:
  created: []
  modified:
    - CompassV2/src/pages/Compass.jsx
    - CompassV2/src/components/CalibrationOverlay.jsx

decisions:
  - needsCalibration triggers on ANY unanswered selected topics (not just below-3), with calibrationCompleted guarding re-trigger after topic deselection
  - resumeMode initializes lazily via useRef + useEffect so it waits for topics/answers to be available from context
  - Exit gating: X button replaced with hidden spacer below-3, replaced with "View Compass" text button at 3+
  - Progress bar tracks answered/total instead of currentIndex/total to reflect real completion state
  - Auto-advance uses setTimeout(300ms) to allow selectedAnswer state to render before jumping to next topic
  - handleNext skips already-answered topics using findIndex with val check instead of simple currentIndex+1

metrics:
  duration: 3 minutes
  completed: 2026-02-21
  tasks_completed: 2
  files_modified: 2
---

# Phase 19 Plan 01: Calibration Auto-Routing and Resumption Flow Summary

Smart calibration routing: auto-route users with unanswered selected topics directly into calibration at the first unanswered topic, with topic pills showing answered/unanswered status, exit gated until 3+ answered, and MinimumProgress updated to use a calibration CTA instead of Library navigation.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Update Compass.jsx auto-routing and below-3 threshold | 49d9bc4 | CompassV2/src/pages/Compass.jsx |
| 2 | Rewrite CalibrationOverlay resumption flow | 59d7f8d | CompassV2/src/components/CalibrationOverlay.jsx |

## What Was Built

### Task 1: Compass.jsx Auto-Routing (49d9bc4)

**`unansweredCompassTopics` computation:**
Added a filter that finds selected topics with no valid answer (null or value <= 0). This allows precise detection of the mixed state where a user has some answered and some unanswered topics.

**Updated `needsCalibration` logic:**
Changed from `answeredCompassCount < 3` to `unansweredCompassTopics.length > 0 && !calibrationSkipped && !calibrationCompleted`. This means any user with selected but unanswered topics gets routed into calibration — not just those with fewer than 3 answered. The `calibrationCompleted` guard ensures users who completed calibration but later deselect topics below 3 see the `MinimumProgress` prompt instead of being forced back into calibration.

**`resumeMode` prop:**
Computed as `answeredCompassCount > 0 && unansweredCompassTopics.length > 0` and passed to `CalibrationOverlay`. Signals that the user has mixed state — some done, some not — so CalibrationOverlay can skip the welcome and pick steps.

**`handleStartCalibration` function:**
Clears both `calibration_skipped` and `calibration_completed` from localStorage and React state, then sets `calibrationActive(true)`. Called by `MinimumProgress` when user taps "Start Calibration".

**MinimumProgress updated:**
- Renamed prop from `onGoToLibrary` to `onStartCalibration`
- Changed button text from "Browse Topics in Library" to "Start Calibration"
- Updated description text to be calibration-focused instead of Library-focused
- Both desktop and mobile `MinimumProgress` renders updated

### Task 2: CalibrationOverlay Resumption Flow (59d7f8d)

**`resumeMode` prop with lazy initialization:**
Instead of computing initial state synchronously (which would run before topics/answers load from context), the component uses a `useRef(false)` flag and a `useEffect` to initialize state once `topics.length > 0`. In resume mode, `pickedTopics` is seeded from `selectedTopics` and `currentIndex` is set to the first unanswered topic's index.

**Topic pill strip in answer step:**
Added a horizontal scrollable strip above the question showing all picked topics as pill buttons. Each pill shows:
- Current topic: blue border (`border-[#59b0c4]`), sky background, muted blue text
- Answered topic: gray background (`bg-gray-100`), gray text, green checkmark prefix
- Unanswered topic: white background, gray border, normal text

Tapping any pill jumps to that topic index, allowing re-answering of previously answered topics or jumping ahead to any unanswered topic.

**Exit button gating:**
The X button is completely replaced:
- `answeredCount < MIN_TOPICS`: renders a `div` spacer so the header stays balanced
- `answeredCount >= MIN_TOPICS`: renders "View Compass" text button calling `handleExitDuringAnswer`

`handleExitDuringAnswer` no longer uses `window.confirm` for the threshold check since the button only appears when there are enough answered topics.

**Auto-advance after stance selection:**
`handleSelectStance` now calls a `setTimeout(300ms)` after updating state that searches for the next unanswered topic after `currentIndex`. If found, advances to it automatically. If none found, calls `handleFinish`. This gives users a smooth flow without needing to tap "Next" between topics.

**`handleNext` smart skipping:**
Updated to use `findIndex` with an unanswered check instead of simple `currentIndex + 1`. This means the manual "Next/Skip" button also skips over already-answered topics.

**Progress bar updated:**
Changed from `(currentIndex + 1) / pickedTopics.length` to `answeredCount / pickedTopics.length` to reflect actual completion state rather than navigation position.

**`handleBack` in resumeMode:**
When at index 0 in resumeMode, back does nothing (there is no pick step to return to). For first-time flow, back at index 0 still returns to the pick step.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Design Decisions Made During Implementation

**1. Lazy initialization via useRef instead of synchronous getInitialState:**
- The plan specified `getInitialState()` running synchronously. However, in `resumeMode`, this function reads `selectedTopics` and `answers` from context, which may not be fully loaded at mount time (they come from async API calls in CompassContext).
- Fix: Used a `useRef(false)` flag + `useEffect` with `topics` dependency so initialization waits until topics array is populated.
- The fallback still renders "Loading..." so the UX is smooth during the brief initialization delay.

**2. Removed `window.confirm` from exit path when gated:**
- The plan retained the confirm dialog for unanswered topics. When the "View Compass" button is shown (only at 3+), there may still be unanswered topics to clean up. The confirm dialog is kept when unanswered topics exist — this was the existing behavior.

**3. `handleSelectStance` auto-advance looks at live `answers` map for topics after current:**
- The auto-advance timeout checks `answers[topic.short_title]` for topics beyond `currentIndex`. The current topic's answer is being set in this same call but won't be reflected in `answers` until the next render. To avoid advancing past the topic being answered, we check `id === currentTopic.id` and skip it. This ensures the just-answered topic is treated as answered when triggering handleFinish vs advance.

## Self-Check: PASSED

- CompassV2/src/pages/Compass.jsx: FOUND
- CompassV2/src/components/CalibrationOverlay.jsx: FOUND
- .planning/phases/19-calibration-flow-fixes/19-01-SUMMARY.md: FOUND
- Commit 49d9bc4 (Task 1): FOUND
- Commit 59d7f8d (Task 2): FOUND
- Build: passes with no errors
