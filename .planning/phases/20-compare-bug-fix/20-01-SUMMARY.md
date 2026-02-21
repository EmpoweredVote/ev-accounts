---
phase: 20-compare-bug-fix
plan: 01
subsystem: ui
tags: [react, react-spring, radar-chart, ev-ui, compass, compare]

# Dependency graph
requires:
  - phase: 19-calibration-flow-fixes
    provides: unansweredSpokes gray rendering in RadarChartCore used as baseline for compare fix
provides:
  - ev-ui@0.1.21 with correct single-polygon compare overlay rendering
  - CompassV2 stable compare answer fetching without spurious topic-metadata re-renders
affects: [CompassV2, ev-ui, any consumer of RadarChartCore compareData prop]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Compare polygon iterates user data spokes (not compareData keys) to guarantee correct angle alignment"
    - "topicsRef.current pattern for useEffect deps — avoids re-firing on topic metadata changes"
    - "key props on conditional polygon branches (user-static/user-animated, compare-static/compare-animated) for clean React reconciliation"

key-files:
  created: []
  modified:
    - ev-ui/src/RadarChartCore.jsx
    - ev-ui/package.json
    - CompassV2/src/pages/Compass.jsx
    - CompassV2/package.json
    - CompassV2/package-lock.json

key-decisions:
  - "Compare polygon vertices calculated by iterating spokes (user data order) and looking up compareData[shortTitle], not iterating compareData independently — guarantees spoke alignment regardless of key order"
  - "compareSpring receives immediate:true when comparePoints is null to prevent stale spring animation from previous comparison"
  - "strokeWidth on compare animated polygon normalized to 2 (matching static branch) — was incorrectly 3 in the original animated branch"
  - "topics removed from compare answer useEffect deps — topicsRef.current used instead, mirroring user answer fetch pattern"

patterns-established:
  - "topicsRef.current pattern: keep ref in sync (topicsRef.current = topics) and use in effects that shouldn't re-fire on metadata changes"
  - "Keyed ternary polygons: when switching between static and animated polygon elements, apply distinct key to force clean React reconciliation"

requirements-completed: [COMP-01]

# Metrics
duration: 2min
completed: 2026-02-21
---

# Phase 20 Plan 01: Compare Bug Fix Summary

**Fixed double-overlay radar chart bug: compare polygon now uses user spoke order for angle alignment, spring cleaned on null, and keyed polygon branches prevent React reconciliation artifacts — published ev-ui@0.1.21 and installed in CompassV2**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-21T00:02:13Z
- **Completed:** 2026-02-21T00:04:00Z
- **Tasks:** 2 of 3 complete (Task 3 is human verification checkpoint)
- **Files modified:** 5

## Accomplishments
- Fixed root cause 1: compare polygon now iterates `spokes` (user data) for angle calculation instead of `Object.entries(compareData)`, ensuring spoke alignment regardless of key order
- Fixed root cause 2: `compareSpring` receives `immediate: true` when `comparePoints` is null, preventing stale animated values from prior comparisons
- Fixed root cause 3: Added `key` props to all conditional polygon branches (`user-static`/`user-animated`, `compare-static`/`compare-animated`) for clean React reconciliation when `countChanged` flips
- Also normalized compare polygon `strokeWidth` to 2 across both static and animated branches (was inconsistently 3 in the animated branch)
- Published ev-ui@0.1.21 to GitHub npm registry
- Installed ev-ui@0.1.21 in CompassV2
- Stabilized compare answer useEffect: replaced `topics.find(...)` with `topicsRef.current.find(...)` and removed `topics` from dep array — prevents spurious re-renders when topic metadata is edited

## Task Commits

Each task was committed atomically (in their respective repos):

1. **Task 1: Fix RadarChartCore compare polygon rendering and publish ev-ui** - `c5132cd` (feat) — ev-ui repo
2. **Task 2: Stabilize compare answer fetching and install updated ev-ui in CompassV2** - `12b7431` (feat) — CompassV2 repo
3. **Task 3: Verify single compare overlay on radar chart** - PENDING human verification

## Files Created/Modified
- `ev-ui/src/RadarChartCore.jsx` - Three compare overlay bug fixes (spoke alignment, spring cleanup, keyed polygons)
- `ev-ui/package.json` - Version bumped 0.1.20 -> 0.1.21
- `CompassV2/src/pages/Compass.jsx` - topicsRef.current in compare effect, topics removed from deps
- `CompassV2/package.json` - ev-ui updated to ^0.1.21
- `CompassV2/package-lock.json` - lockfile updated

## Decisions Made
- Compare polygon iterates `spokes` (not `compareData` keys) — guarantees correct angle alignment regardless of which topics the politician has stances for
- `compareSpring` uses `immediate: true` when `comparePoints` is null — prevents the spring from briefly showing a stale shape when comparison is cleared
- `strokeWidth` on compare animated polygon normalized to 2 (was 3, matching only the static branch) — consistency fix caught during implementation
- `topicsRef` pattern mirrors the exact approach used for user answer fetching at line 415 — consistent pattern across both effects

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalized compare polygon strokeWidth to 2 across both branches**
- **Found during:** Task 1 (reviewing compare polygon code)
- **Issue:** Static polygon branch had `strokeWidth: 2` but animated polygon branch had `strokeWidth: 3` — visual inconsistency and likely contributor to the "double overlay" appearance (different widths made two coincident shapes visible)
- **Fix:** Changed animated polygon `strokeWidth` from 3 to 2 to match the static branch
- **Files modified:** ev-ui/src/RadarChartCore.jsx
- **Verification:** Build passes; both branches now render with identical strokeWidth: 2
- **Committed in:** c5132cd (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minor visual consistency fix. No scope creep.

## Issues Encountered
- Both ev-ui and CompassV2 are separate git repos nested under the workspace root, which is also a git repo. Had to commit to each repo individually (ev-ui repo and CompassV2 repo) rather than the workspace root.

## User Setup Required
None — no external service configuration required beyond running the dev server for verification.

## Next Phase Readiness
- ev-ui@0.1.21 published and installed in CompassV2
- CompassV2 build passes
- Awaiting human verification (Task 3 checkpoint) that single overlay renders correctly on desktop and mobile
- After human approval, COMP-01 requirement will be fully satisfied

---
*Phase: 20-compare-bug-fix*
*Completed: 2026-02-21*
