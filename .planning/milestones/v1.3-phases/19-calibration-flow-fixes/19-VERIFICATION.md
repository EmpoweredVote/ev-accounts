---
phase: 19-calibration-flow-fixes
verified: 2026-02-21T19:30:00Z
status: human_needed
score: 4/4 automated must-haves verified
re_verification: false
human_verification:
  - test: "Navigate to /results with unanswered topics — confirm auto-route into calibration at first unanswered topic (no welcome, no pick screen)"
    expected: "CalibrationOverlay opens immediately in answer step, scrolled to the first unanswered topic pill, skipping welcome and pick steps"
    why_human: "Depends on localStorage state and async context load timing; cannot be verified by grep"
  - test: "After answering 3+ topics but with some unanswered, exit calibration — confirm radar shows ALL spokes with unanswered ones as gray dashed lines and shape pinches inward at those positions"
    expected: "Answered spokes solid black, unanswered spokes gray dashed (#9ca3af, strokeDasharray 4 3), coral shape touches center at unanswered positions"
    why_human: "Visual SVG rendering and react-spring animation cannot be verified by static analysis"
  - test: "Click a gray (unanswered) spoke on the compass — confirm calibration opens"
    expected: "handleSpokeClick routes to handleStartCalibration; CalibrationOverlay appears. Clicking an answered (solid) spoke opens LibraryDrawer instead."
    why_human: "Click event routing requires runtime verification"
  - test: "Deselect answered topics until fewer than 3 remain — confirm BelowThresholdChart overlay appears with 'Start Calibration' button and grayed chart, NOT auto-route into calibration"
    expected: "Real RadarChart visible at opacity-25 behind overlay card showing 'Answer X more topics' and Start Calibration button. No auto-calibration trigger because calibration_completed=true in localStorage."
    why_human: "State guard (calibrationCompleted) interaction with UI branch requires runtime verification"
  - test: "Click 'Start Calibration' from BelowThresholdChart overlay — confirm pick step opens with existing topics pre-selected; back button dismisses without resetting localStorage"
    expected: "startAtPick=true opens pick step; existing selectedTopics are pre-checked; back button calls onSkip(); calibration_completed not cleared"
    why_human: "startAtPick vs resumeMode prop interaction requires runtime state verification"
  - test: "Complete calibration from mixed state — confirm compass renders immediately without refresh"
    expected: "After final answer + Finish, 'Your compass is ready' screen appears (if 3+ answered), then auto-transitions to fully rendered compass in 3 seconds"
    why_human: "Completion auto-transition and re-render depends on runtime state sequencing"
---

# Phase 19: Calibration Flow Fixes Verification Report

**Phase Goal:** The compass correctly routes users into calibration whenever they have unanswered topics, handles mixed answered/unanswered state without empty spokes, and never leaves users in a dead end when topic count drops below 3
**Verified:** 2026-02-21T19:30:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User with unanswered topics is auto-routed into calibration at first unanswered topic | VERIFIED (automated) | `needsCalibration = unansweredCompassTopics.length > 0 && !calibrationSkipped && !calibrationCompleted` fires useEffect that sets `calibrationActive(true)`; `resumeMode` skips welcome/pick |
| 2 | Calibration starts at first unanswered topic index, skipping pick/welcome | VERIFIED (automated) | `getInitialState()` in resumeMode runs `selectedTopics.findIndex()` for first unanswered; `initializedRef` guards lazy init |
| 3 | Mixed-state compass shows ALL selected topic spokes (answered solid, unanswered gray dashed) | VERIFIED (automated) | `chartData` useMemo includes all selectedTopics with 0 for unanswered; `unansweredSpokesMap` built and passed; `RadarChartCore` renders gray dashed lines for entries in `unansweredSpokes` |
| 4 | Below-3 answered count shows grayed chart overlay with calibration CTA, not dead end | VERIFIED (automated) | `BelowThresholdChart` component renders real `RadarChart` at `opacity-25 pointer-events-none` with centered overlay card and "Start Calibration" button |

**Automated Score:** 4/4 truths verified at artifact + wiring level

**Human Verification Required:** Visual rendering correctness, runtime routing behavior, and localStorage state interactions (6 items listed in frontmatter)

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `CompassV2/src/pages/Compass.jsx` | Auto-routing logic, BelowThresholdChart, unansweredSpokes data pipe | VERIFIED | Contains `unansweredCompassTopics`, `needsCalibration`, `resumeMode`, `startAtPick`, `handleStartCalibration`, `handleStartCalibrationFromBelow3`, `BelowThresholdChart`, `chartData` useMemo, `unansweredSpokesMap` useMemo, `handleSpokeClick` |
| `CompassV2/src/components/CalibrationOverlay.jsx` | Resumption flow, topic pill strip, exit gating, startAtPick | VERIFIED | Contains `resumeMode`, `startAtPick` props; lazy `useRef` init; horizontal pill strip with answered/unanswered states; `answeredCount >= MIN_TOPICS` guard for "View Compass" exit; `handleFinish` with `finalAnsweredCount < MIN_TOPICS` shortcut |
| `ev-ui/src/RadarChartCore.jsx` | Gray dashed spoke rendering for unanswered topics | VERIFIED | `unansweredSpokes` prop; spoke lines check `isUnanswered` for `stroke="#9ca3af"`, `strokeDasharray="4 3"`, `opacity=0.6`; label fill `#9ca3af`; hitbox routes unanswered clicks to `onReplaceTopic` instead of `onToggleInversion` |
| `CompassV2/src/components/RadarChart.jsx` | Pass-through of `unansweredSpokes` prop | VERIFIED | Uses `{...props}` spread — `unansweredSpokes` forwarded automatically; confirmed by build and bundle check |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Compass.jsx` | `CalibrationOverlay.jsx` | `showCalibration` flag + `resumeMode`/`startAtPick` props | WIRED | Lines 544-564: `{showCalibration ? <CalibrationOverlay resumeMode={resumeMode} startAtPick={startAtPick} ...>` |
| `Compass.jsx` | `RadarChartCore` (via RadarChart) | `data={chartData}` and `unansweredSpokes={unansweredSpokesMap}` | WIRED | Lines 593-604 (desktop) and 668-679 (mobile): both RadarChart renders pass `chartData` and `unansweredSpokesMap` |
| `Compass.jsx` | `BelowThresholdChart` | `onStartCalibration={handleStartCalibrationFromBelow3}` | WIRED | Lines 608-616 (desktop) and 683-691 (mobile): both non-chart branches render `BelowThresholdChart` with correct handler |
| `CalibrationOverlay.jsx` | `CompassContext` | `useCompass()` for `selectedTopics`, `answers` | WIRED | Line 49-60: destructures `topics`, `selectedTopics`, `answers`, `setSelectedTopics` from `useCompass()` |
| `RadarChartCore.jsx` | `onReplaceTopic` callback | Unanswered hitbox fires `onReplaceTopic(shortTitle)` | WIRED | Lines 244-248: `isUnansweredHitbox ? onReplaceTopic(shortTitle) : onToggleInversion(shortTitle)` |
| `handleSpokeClick` in Compass.jsx | calibration entry | Routes unanswered spoke click to `handleStartCalibration()` | WIRED | Lines 338-347: checks `isUnanswered`, calls `handleStartCalibration()` vs `setDrawerTopic(topic)` |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| CALIB-01 | 19-01-PLAN.md | User with unanswered topics auto-routed into calibration at first unanswered topic | SATISFIED | `needsCalibration` triggers on `unansweredCompassTopics.length > 0`; `resumeMode` jumps to first unanswered index via `findIndex` |
| CALIB-02 | 19-02-PLAN.md | Mixed state shows no empty spokes or dead-end | SATISFIED | `chartData` includes all `selectedTopics` with 0 for unanswered; `unansweredSpokesMap` identifies them for gray dashed rendering in `RadarChartCore` |
| CALIB-03 | 19-01-PLAN.md, 19-02-PLAN.md | Below-3 answered count shows calibration entry, not dead end | SATISFIED | `BelowThresholdChart` with real chart at opacity-25 and "Start Calibration" CTA; `handleStartCalibrationFromBelow3` + `startAtPick` prop opens pick step without resetting state |

No orphaned requirements — all three CALIB IDs appear in plan frontmatter and are covered by implementation.

---

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| None | — | — | — |

No stubs, placeholders, TODO/FIXME comments, empty handlers, or console.log-only implementations found in modified files. Legacy patterns removed: `onGoToLibrary`, `Browse Topics in Library`, and `start_phrase` are absent from the codebase.

---

### Build Verification

Both projects build successfully:
- `cd CompassV2 && npm run build` — passed (844ms, no errors)
- ev-ui version 0.1.20 published and installed in `CompassV2/node_modules/@chrisandrewsedu/ev-ui` (version 0.1.20)
- Published bundle (`index.mjs`) contains 4 occurrences of `unansweredSpokes` — confirming gray spoke logic is in the distributed artifact

---

### Implementation Notes — Deviations from Original Plans

The 19-02 plan was partially reworked after a human checkpoint. Key differences that are **already verified in the actual code**:

1. **No auto-advance** — The plan specified a 300ms `setTimeout` auto-advance after stance selection. This was removed. `handleSelectStance` in CalibrationOverlay does NOT contain any `setTimeout` or auto-navigation — user clicks Next manually. This is intentional (user reported it as surprising).

2. **`BelowThresholdChart` instead of `MinimumProgress`** — The original plan used a `MinimumProgress` component that replaced the chart area with a blank state. The actual implementation renders a real `RadarChart` at `opacity-25 pointer-events-none` behind an overlay card. Verified at lines 31-77 in Compass.jsx.

3. **`startAtPick` prop added** — Not in the original 19-01 plan. Added in 19-02 to provide a separate below-3 entry path (pick step) distinct from `resumeMode` (answer step). Both props are present in `CalibrationOverlay` prop signature.

4. **Completion loop fix** — `handleFinish` checks `finalAnsweredCount < MIN_TOPICS` and calls `onComplete()` directly, skipping the "Your compass is ready" screen when the chart won't render anyway.

---

### Human Verification Required

#### 1. Auto-routing at first unanswered topic

**Test:** With at least one answered topic and at least one unanswered selected topic (set up via DevTools: clear `calibration_completed` and `calibration_skipped` from localStorage, ensure some topics have answers and some don't), navigate to `/results`.
**Expected:** CalibrationOverlay opens immediately in answer step — NO welcome screen, NO pick screen. The pill strip scrolls to the first unanswered topic. Already-answered topics show with green checkmark and gray pill style.
**Why human:** Requires correct async context initialization timing (resumeMode lazy init via `useRef`) and specific localStorage state — cannot be simulated by grep.

#### 2. Gray dashed unanswered spokes on radar chart

**Test:** After completing enough calibration to have 3+ answered topics but with some unanswered topics still selected, exit calibration ("View Compass"). View the radar chart.
**Expected:** All selected topics appear as spokes. Answered spokes are solid black lines. Unanswered spokes are gray dashed lines (visually distinct). The coral/red data shape touches the center (value 0) at unanswered spoke positions, creating a "pinch" inward.
**Why human:** SVG rendering and react-spring animation cannot be verified from static code analysis.

#### 3. Spoke click routing (unanswered vs answered)

**Test:** On the compass with mixed state, click a gray dashed spoke label or line. Then click a solid answered spoke.
**Expected:** Clicking a gray spoke opens CalibrationOverlay. Clicking a solid spoke opens LibraryDrawer for that topic.
**Why human:** Event delegation and conditional routing in `handleSpokeClick` requires runtime verification.

#### 4. Below-3 threshold shows overlay (not auto-calibration)

**Test:** Complete calibration (so `calibration_completed=true` in localStorage). Then go to Edit Topics and deselect answered topics until fewer than 3 answered remain.
**Expected:** `BelowThresholdChart` appears — real chart at low opacity behind overlay card with dot progress indicators, "Answer X more topics" message, and "Start Calibration" button. The calibration overlay does NOT auto-open (calibrationCompleted guard prevents re-trigger).
**Why human:** The guard logic depends on the specific state of `calibrationCompleted` in React state vs localStorage — runtime only.

#### 5. startAtPick entry path from below-3 overlay

**Test:** From the BelowThresholdChart overlay, click "Start Calibration". Observe which step opens. Press back/close.
**Expected:** Opens pick step with all currently selected topics pre-checked. Back button (arrow) dismisses the overlay entirely (does not navigate to a welcome screen). `calibration_completed` in localStorage should still be `"true"` after dismissal.
**Why human:** `startAtPick` prop routing and its distinct behavior from `resumeMode` requires runtime verification.

#### 6. Completion from mixed state arrives at working compass

**Test:** Enter calibration with some unanswered topics, answer them all, click Finish.
**Expected:** If final answered count >= 3: "Your compass is ready!" celebration screen appears, then auto-transitions to the full radar chart after 3 seconds. If final answered count < 3: overlay dismisses directly to BelowThresholdChart (no celebration).
**Why human:** Auto-transition timing and the `finalAnsweredCount < MIN_TOPICS` branch require runtime state verification.

---

## Summary

All automated checks pass cleanly. The three required artifacts exist, are substantive, and are correctly wired:

- **CALIB-01**: `Compass.jsx` computes `unansweredCompassTopics`, sets `needsCalibration` on any unanswered selected topics, activates `CalibrationOverlay` via useEffect, and passes `resumeMode=true` when mixed state is detected. `CalibrationOverlay` lazily initializes from the first unanswered topic index.

- **CALIB-02**: `Compass.jsx` builds `chartData` (all selected topics, 0 for unanswered) and `unansweredSpokesMap` (set of unanswered short titles). Both are passed to `RadarChart`, which spreads them to `RadarChartCore`. `RadarChartCore` renders unanswered spokes as gray dashed lines and routes their hitbox clicks to `onReplaceTopic` (calibration) instead of `onToggleInversion`.

- **CALIB-03**: `BelowThresholdChart` replaces the chart area when `answeredCompassCount < 3` AND `showChart` is false. It renders the real `RadarChart` at `opacity-25 pointer-events-none` with an overlay card and "Start Calibration" button. `handleStartCalibrationFromBelow3` sets `startAtPick=true` without clearing localStorage, opening `CalibrationOverlay` at the pick step.

CompassV2 build passes with no errors. ev-ui 0.1.20 is published and installed. No placeholder or stub code found. No legacy dead-end patterns (`onGoToLibrary`, `MinimumProgress`, `start_phrase`) remain.

6 human verification items remain covering visual rendering, runtime routing, and localStorage state interactions. None of these are expected to fail based on code review — they are listed because they cannot be confirmed by static analysis alone.

---

_Verified: 2026-02-21T19:30:00Z_
_Verifier: Claude (gsd-verifier)_
