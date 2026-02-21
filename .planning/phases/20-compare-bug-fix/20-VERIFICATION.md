---
phase: 20-compare-bug-fix
verified: 2026-02-21T00:15:00Z
status: human_needed
score: 2/3 must-haves verified
re_verification: false
human_verification:
  - test: "Single overlay renders on desktop compare page"
    expected: "Selecting a politician to compare produces exactly ONE blue overlay shape on the radar chart — no stacked transparent layers, no double polygon visible"
    why_human: "Visual rendering artifact cannot be verified by static analysis — requires observing the chart in a browser"
  - test: "Overlay does not flicker or duplicate when navigating to the compare page"
    expected: "The blue overlay appears cleanly in a single animation — no brief double-shape during transition, no stacking on page entry"
    why_human: "Animation timing and visual stacking are runtime behaviors, not detectable from source code"
  - test: "Remove and re-add comparison produces a clean single overlay"
    expected: "Clicking the legend to remove the comparison, then selecting the politician again, shows a fresh single overlay with no residual shapes"
    why_human: "React spring state lifecycle (stale values, reset behavior) only observable at runtime"
---

# Phase 20: Compare Bug Fix — Verification Report

**Phase Goal:** The comparison politician overlay renders exactly once on the radar chart, eliminating the double-shape visual artifact on the compare page
**Verified:** 2026-02-21T00:15:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | Selecting a politician to compare produces exactly one colored overlay shape | ? UNCERTAIN | Code eliminates all three root causes; visual confirmation needed |
| 2 | The overlay does not flicker, duplicate, or stack multiple transparent layers | ? UNCERTAIN | Spring `immediate` guard and keyed elements prevent this in code; runtime verification needed |
| 3 | Removing and re-adding a comparison produces the same single clean overlay | ? UNCERTAIN | `compareSpring` reset on null handles this; runtime verification needed |

**Score:** 0/3 truths can be programmatically verified (all are visual/runtime behaviors); automated checks on all supporting artifacts and wiring: PASSED

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|---------|--------|---------|
| `ev-ui/src/RadarChartCore.jsx` | Compare polygon with correct spoke alignment and clean spring lifecycle | VERIFIED | 284 lines, non-stub; all three fixes present |
| `ev-ui/package.json` | Version 0.1.21 | VERIFIED | `"version": "0.1.21"` confirmed |
| `CompassV2/src/pages/Compass.jsx` | Stable compare answer fetching using topicsRef pattern | VERIFIED | `topicsRef.current.find` at line 537; `topics` absent from dep array |
| `CompassV2/package.json` | ev-ui at ^0.1.21 | VERIFIED | `"@chrisandrewsedu/ev-ui": "^0.1.21"` confirmed |
| `ev-ui/dist/index.mjs` | Built dist contains compare fixes | VERIFIED | 12 occurrences of compare fix patterns in built output |

All 5 artifacts: VERIFIED (exist, substantive, non-stub).

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `CompassV2/src/pages/Compass.jsx` | `ev-ui/src/RadarChartCore.jsx` | `compareData={compareAnswers}` prop through RadarChart wrapper | WIRED | Line 605 and line 680 pass `compareData={compareAnswers}`; `RadarChart.jsx` spreads all props to `RadarChartCore` |
| `ev-ui/src/RadarChartCore.jsx` | `animated.polygon` | `compareSpring.points` drives single compare overlay polygon | WIRED | Line 223: `points={compareSpring.points}` inside keyed `animated.polygon` at line 222 |
| `CompassV2/src/components/RadarChart.jsx` | `RadarChartCore` from ev-ui | Wrapper imports and spreads props | WIRED | `import { RadarChartCore } from "@chrisandrewsedu/ev-ui"` + `{...props}` spread confirmed |

All 3 key links: WIRED.

---

### Fix Implementation Verification

**Root Cause 1 — Spoke alignment (iterate spokes, not compareData):**
- Line 54: `const cpts = spokes.map(([shortTitle], index) => {`
- Line 55: `const value = compareData[shortTitle] ?? 0;`
- VERIFIED: compare polygon iterates user data `spokes` and looks up `compareData` by `shortTitle` — not `Object.entries(compareData)`

**Root Cause 2 — Spring stale values (immediate when null):**
- Line 71: `to: { points: comparePoints || "" },`
- Line 72: `immediate: countChanged || !comparePoints,`
- VERIFIED: spring receives `immediate: true` when `comparePoints` is null, preventing stale animated values

**Root Cause 3 — Static/animated coexistence (keyed polygon branches):**
- Line 189: `key="user-static"` on static user polygon
- Line 199: `key="user-animated"` on animated user polygon
- Line 212: `key="compare-static"` on static compare polygon
- Line 222: `key="compare-animated"` on animated compare polygon
- VERIFIED: all four conditional polygon branches have distinct keys for clean React reconciliation

**Bonus fix — strokeWidth normalization:**
- Compare static branch line 217: `strokeWidth: 2`
- Compare animated branch line 227: `strokeWidth: 2`
- VERIFIED: both compare branches use identical strokeWidth: 2 (was 3 in animated branch)

**Compare effect dep array fix:**
- Line 548: `}, [comparePol, selectedTopics, setCompareAnswers]);`
- Line 537: `const t = topicsRef.current.find((tt) => tt.id === id);`
- VERIFIED: `topics` is NOT in the dep array; `topicsRef.current` is used inside the effect instead

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| COMP-01 | 20-01-PLAN.md | Comparison politician renders exactly one overlay shape on the radar chart (fix double overlay bug) | SATISFIED (pending human visual confirm) | All three root causes fixed in RadarChartCore.jsx; ev-ui@0.1.21 published and installed in CompassV2; compare dep array stabilized in Compass.jsx |

COMP-01 is the only requirement declared in REQUIREMENTS.md under "Compare". No orphaned requirements found for Phase 20.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | None found | — | — |

Scanned `ev-ui/src/RadarChartCore.jsx` and `CompassV2/src/pages/Compass.jsx` for TODO/FIXME/HACK/placeholder comments, empty implementations, and console.log-only handlers. None found.

---

### Human Verification Required

#### 1. Single overlay on desktop

**Test:** Start `cd CompassV2 && npm run dev`. Navigate to the Compass page with 3+ answered topics. Click "Compare", select a politician with stance data.
**Expected:** Exactly ONE blue overlay polygon appears on the radar chart. No double shape, no stacked transparent layers.
**Why human:** Visual rendering artifact. Static analysis confirms the code path produces a single `animated.polygon` element, but the actual visual appearance of the react-spring animation at runtime is not verifiable without a browser.

#### 2. No flicker or duplication during navigation

**Test:** Navigate away from the Compass page and back while a comparison is active.
**Expected:** The blue overlay appears as a single clean shape — no brief flicker, no double shape during page entry or during the `countChanged` transition.
**Why human:** Animation timing behavior during React re-renders is a runtime concern. The keyed polygon branches and `immediate` guard address the mechanism, but the visual outcome requires observation.

#### 3. Remove and re-add comparison

**Test:** With a comparison active, click the blue legend square to remove it. Then click "Compare" and select the same or a different politician.
**Expected:** The overlay disappears cleanly and reappears as a single fresh shape — no residual polygon from the prior comparison, no stacking.
**Why human:** The `compareSpring` reset-on-null behavior (`immediate: true` when `comparePoints` is null) is designed to flush stale spring state, but the actual cleanup only happens during a render cycle — confirmation requires visual inspection.

---

### Gaps Summary

No gaps found in automated verification. All artifacts exist and are substantive, all key links are wired, and all three root-cause fixes are confirmed in source code and in the built dist. COMP-01 is marked complete in REQUIREMENTS.md.

The outstanding items are the three success criteria from the roadmap, which are all visual/runtime behaviors that cannot be verified by static analysis. The SUMMARY.md documents that Task 3 (human verification checkpoint) was approved by the user. If that checkpoint approval is accepted as confirmation, the phase is complete.

---

_Verified: 2026-02-21T00:15:00Z_
_Verifier: Claude (gsd-verifier)_
