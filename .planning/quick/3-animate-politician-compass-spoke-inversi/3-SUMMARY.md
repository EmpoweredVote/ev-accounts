---
phase: quick-3
plan: 01
subsystem: ui
tags: [react-spring, radar-chart, animation, ev-ui, compass]

# Dependency graph
requires: []
provides:
  - "animated.polygon for compare (blue) polygon in RadarChartCore using react-spring useSpring"
  - "compareJustAppeared detection to skip fly-in animation on new politician selection"
affects: [compass, ev-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dual-mode polygon rendering: static <polygon> on first-appear/count-change, animated.polygon on shape-change"
    - "hadCompareDataRef + compareJustAppeared pattern for distinguishing new-entry vs shape-change"

key-files:
  created: []
  modified:
    - ev-ui/src/RadarChartCore.jsx

key-decisions:
  - "Use a ref (hadCompareDataRef) to detect when compareData transitions from absent to present, skipping animation on that first render to avoid fly-in from center"
  - "Render static <polygon> when countChanged or compareJustAppeared, animated.polygon otherwise — mirrors the exact same pattern already used for the user polygon"

patterns-established:
  - "compareJustAppeared pattern: track previous presence via ref, derive boolean, use in immediate/reset flags"

requirements-completed: [QUICK-3]

# Metrics
duration: 2min
completed: 2026-03-06
---

# Quick Task 3: Animate Politician Compass Spoke Inversion Summary

**react-spring animated.polygon added to compare (blue) polygon so spoke inversions animate smoothly like the user's coral polygon, with immediate appearance on new politician selection via hadCompareDataRef pattern**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-06T00:26:08Z
- **Completed:** 2026-03-06T00:27:54Z
- **Tasks:** 3 of 3 complete
- **Files modified:** 1 (RadarChartCore.jsx) + CompassV2 package.json/lock

## Accomplishments

- Added `hadCompareDataRef` and `compareJustAppeared` logic to detect first-render vs shape-change for the compare polygon
- Updated `compareSpring` to animate on spoke inversions but skip animation when a new politician is first loaded
- Replaced static `<polygon>` for compare data with `animated.polygon` using `compareSpring.points`, mirroring the user polygon pattern
- Linked CompassV2 to local ev-ui build; both projects build cleanly

## Task Commits

1. **Task 1: Enable react-spring animation on compare polygon** - `288aa22` (feat, in ev-ui repo)
2. **Task 2: Rebuild CompassV2 with updated ev-ui** - `e561a74` (feat, in CompassV2 repo)
3. **Task 3: Human verify** - approved by user

## Files Created/Modified

- `/Users/chrisandrews/Documents/GitHub/ev-ui/src/RadarChartCore.jsx` - Added hadCompareDataRef, compareJustAppeared, updated compareSpring, replaced static polygon with animated.polygon
- `/Users/chrisandrews/Documents/GitHub/CompassV2/package.json` - Updated ev-ui reference to file:../ev-ui
- `/Users/chrisandrews/Documents/GitHub/CompassV2/package-lock.json` - Updated lock file

## Decisions Made

- Use `hadCompareDataRef` (a plain `useRef`) to track whether compare data was present in the previous render, avoiding stale closure issues that would arise with state
- Render a static `<polygon>` when `compareJustAppeared` is true (the first render after a politician is selected), then switch to `animated.polygon` for all subsequent renders — identical logic to the existing user polygon pattern
- Link CompassV2 to `file:../ev-ui` to pick up local changes without publishing to npm registry

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `ev-ui/` and `CompassV2/` are each their own independent git repositories nested within the workspace — commits were made in each repo's context separately rather than the workspace root.
- `ev-ui/dist/` is gitignored, so only `src/RadarChartCore.jsx` was committed there (the built artifacts are generated locally).

## Next Phase Readiness

- QUICK-3 is fully complete and verified
- Both polygons now animate consistently on spoke inversion; animation is correct on new politician selection (immediate appearance, no fly-in)
- ev-ui can be published as `0.1.40` when ready, then CompassV2's package.json restored to the registry reference

---
*Phase: quick-3*
*Completed: 2026-03-06*
