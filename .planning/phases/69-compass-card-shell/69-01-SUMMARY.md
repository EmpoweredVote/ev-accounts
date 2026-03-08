---
phase: 69-compass-card-shell
plan: 01
subsystem: ui
tags: [react, tailwind, compass, essentials, profile]

requires:
  - phase: 67-compass-context
    provides: "CompassProvider with politicianIdsWithStances Set and useCompass hook"
  - phase: 68-guest-data-bridge
    provides: "Guest compass data via URL fragment bridge and localStorage cache"
provides:
  - "CompassCard shell component with gating, skeleton layout, and CTA fallback"
  - "Profile page integration rendering CompassCard after PoliticianProfile"
affects: [70-radar-chart, 71-stance-breakdown]

tech-stack:
  added: []
  patterns: ["Self-gating component pattern — CompassCard returns null internally when data unavailable"]

key-files:
  created:
    - essentials/src/components/CompassCard.jsx
  modified:
    - essentials/src/pages/Profile.jsx

key-decisions:
  - "CompassCard uses useLocation for return URL construction (same pattern as CompassPreview)"
  - "Fragment wrapper added in Profile.jsx ternary to support sibling JSX elements"

patterns-established:
  - "Self-gating card pattern: component handles own visibility via useCompass context — parent passes props, child decides rendering"

requirements-completed: [CARD-01, CARD-02]

duration: 2min
completed: 2026-03-08
---

# Phase 69 Plan 01: Compass Card Shell Summary

**CompassCard shell with politician stance gating, 2-column skeleton layout for chart/breakdown zones, and CTA fallback for uncalibrated users**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-08T02:13:32Z
- **Completed:** 2026-03-08T02:15:36Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created CompassCard component that gates on politicianIdsWithStances and compassLoading
- Two-column skeleton grid with pulse-animated placeholders for Phase 70 (radar chart) and Phase 71 (stance breakdown)
- CTA fallback with greyed compass SVG icon and "Take the Quiz" button linking to CompassV2 with return URL
- Integrated into Profile.jsx as sibling after PoliticianProfile with fragment wrapper

## Task Commits

Each task was committed atomically:

1. **Task 1: Create CompassCard component** - `b538843` (feat)
2. **Task 2: Integrate CompassCard into Profile.jsx** - `d067f3a` (feat)

## Files Created/Modified
- `essentials/src/components/CompassCard.jsx` - CompassCard shell with gating, skeleton, and CTA
- `essentials/src/pages/Profile.jsx` - Import and render CompassCard after PoliticianProfile

## Decisions Made
- Used `useLocation()` from react-router-dom (same pattern as CompassPreview) for constructing the return URL in the CTA link
- Added fragment wrapper (`<>...</>`) in Profile.jsx ternary to support PoliticianProfile and CompassCard as siblings

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added JSX fragment wrapper for sibling elements**
- **Found during:** Task 2 (Profile integration)
- **Issue:** Placing CompassCard as sibling to PoliticianProfile inside ternary branch produced invalid JSX (two root elements)
- **Fix:** Wrapped both components in `<>...</>` fragment
- **Files modified:** essentials/src/pages/Profile.jsx
- **Verification:** `npx vite build` succeeds
- **Committed in:** d067f3a (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Standard JSX requirement, no scope creep.

## Issues Encountered
None beyond the fragment wrapper fix above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Left skeleton zone ready for Phase 70 to replace with RadarChartCore
- Right skeleton zone ready for Phase 71 to replace with stance breakdown
- CompassCard already consumes useCompass() context -- Phase 70/71 can add more data consumption inside the same component or child components

---
*Phase: 69-compass-card-shell*
*Completed: 2026-03-08*
