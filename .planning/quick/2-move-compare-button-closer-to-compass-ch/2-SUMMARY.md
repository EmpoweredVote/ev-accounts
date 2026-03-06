---
phase: quick-2
plan: 01
subsystem: ui
tags: [react, tailwind, compass, mobile, layout]

requires: []
provides:
  - Compare button repositioned directly below radar chart with minimal gap (mt-1)
  - Main page container bottom padding (pb-16) prevents fixed save banner from overlapping content
  - Mobile Graph tab chart max-height reduced (100dvh-280px) to keep Compare button in viewport
affects: [CompassV2]

tech-stack:
  added: []
  patterns:
    - "Use pb-16 on page container when fixed bottom banners are present to avoid overlap"
    - "Mobile chart max-height offset should account for tab bar + action buttons below chart"

key-files:
  created: []
  modified:
    - CompassV2/src/pages/Compass.jsx

key-decisions:
  - "mt-1 (4px) chosen over mt-0 to keep slight visual breathing room while still feeling close to chart"
  - "pb-16 (64px) provides ~12px clearance above the ~52px save banner"
  - "Mobile max-height offset increased from 240px to 280px (40px reclaim) to fit Compare button in typical mobile viewport without chart becoming too small"

requirements-completed: [QUICK-2]

duration: 5min
completed: 2026-03-05
---

# Quick Task 2: Move Compare Button Closer to Compass Chart Summary

**Compare button moved to mt-1 below chart, pb-16 page padding prevents save banner overlap, mobile chart height tightened to keep button in viewport**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-05T22:30:00Z
- **Completed:** 2026-03-05T22:35:00Z
- **Tasks:** 1 of 2 complete (Task 2 is human-verify checkpoint)
- **Files modified:** 1

## Accomplishments
- Reduced gap between radar chart and Compare button from 16px (mt-4) to 4px (mt-1)
- Added pb-16 to main page container so the fixed-position SavePromptModal does not cover the Compare button
- Removed `aspect-square` from both desktop and mobile chart containers — eliminated large dead space below the SVG polygon
- Moved ActionButtons inside chart fragment for consistent centering with the radar chart
- Reverted mobile chart max-height to `calc(100dvh-240px)` (earlier attempt had shrunk it)
- Added Vite resolve alias to use local ev-ui source during development
- Fixed RadarChartCore symmetric horizontal padding so chart center aligns with SVG center

## Task Commits

1. **Task 1: Initial repositioning** - `3895d94` (CompassV2: mt, pb, mobile max-h)
2. **Task 2: Centering and dead space fix** - `005c970` (CompassV2: remove aspect-square, Vite alias, ActionButtons placement)
3. **Task 3: Symmetric viewBox padding** - `3c260bf` (ev-ui: RadarChartCore symmetric padding)

## Files Created/Modified
- `CompassV2/src/pages/Compass.jsx` - Layout fixes for button positioning and centering
- `CompassV2/vite.config.js` - Local ev-ui alias for development
- `ev-ui/src/RadarChartCore.jsx` - Symmetric horizontal padding in viewBox computation

## Decisions Made
- Used pb-16 rather than a conditional padding approach — the save banner always appears for guests after 1.5s, so unconditional padding is simpler
- Removed aspect-square instead of using negative margins — the SVG viewBox isn't square so the forced square ratio created wasted space
- Fixed centering at the source (ev-ui RadarChartCore) using symmetric padding rather than CSS hacks in Compass.jsx
- Used Vite alias to resolve local ev-ui during development until the package is republished

## Note
- The ev-ui symmetric padding fix needs to be published (`npm run build && npm publish`) for production builds
- The Vite alias in vite.config.js should be removed after ev-ui is published with the fix

---
*Phase: quick-2*
*Completed: 2026-03-05*
