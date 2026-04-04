---
phase: 102-ev-ui-foundation-quick-wins
plan: 01
subsystem: ui
tags: [react, ev-ui, icons, design-tokens, svg, npm-publish]

# Dependency graph
requires: []
provides:
  - BallotIcon, CompassIcon, BranchIcon inline SVG React components exported from ev-ui
  - tierColors design token with federal/state/local keys (teal scale, WCAG AA compliant)
  - CategorySection tier prop wiring tierColors to titlePill
  - imageFocalPoint prop on PoliticianCard and PoliticianProfile (defaults to 'center 20%')
  - ev-ui v0.1.55 published to GitHub npm registry
affects:
  - 103-essentials-visual-polish (consumes BallotIcon, CompassIcon, BranchIcon, tierColors, imageFocalPoint)
  - essentials
  - CompassV2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Inline SVG React components with size/color props (no external icon library in ev-ui)
    - tierColors semantic token referencing colorScales.teal shades for tier-aware theming
    - Optional props with null-safe fallbacks (??) for all new ev-ui additions

key-files:
  created:
    - ev-ui/src/icons.js
  modified:
    - ev-ui/src/tokens.js
    - ev-ui/src/CategorySection.jsx
    - ev-ui/src/PoliticianCard.jsx
    - ev-ui/src/PoliticianProfile.jsx
    - ev-ui/src/index.js
    - ev-ui/package.json

key-decisions:
  - "Icons are inline SVG in ev-ui/src/icons.js — no external icon library (tsup splitting:false blast radius)"
  - "tierColors.local.text uses teal-600 (#005366, 8.1:1 AA), NOT teal-200 which fails contrast"
  - "imageFocalPoint defaults to 'center 20%' to show faces — overridable per politician"

patterns-established:
  - "Pattern 1: Inline SVG icons accept { size, color } with currentColor default — composable with any text color context"
  - "Pattern 2: Tier theming via tierColors[tier]?.bg ?? fallback — null-safe, backward compatible"

requirements-completed: [VIS-03, DATA-03]

# Metrics
duration: 12min
completed: 2026-04-04
---

# Phase 102 Plan 01: ev-ui Foundation Quick Wins Summary

**BallotIcon/CompassIcon/BranchIcon SVG icons, tierColors teal-scale token, CategorySection tier prop, and face-centered imageFocalPoint published as ev-ui v0.1.55**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-04T00:50:00Z
- **Completed:** 2026-04-04T01:02:00Z
- **Tasks:** 2
- **Files modified:** 6 (plus 1 created)

## Accomplishments
- Created ev-ui/src/icons.js with BallotIcon, CompassIcon, BranchIcon inline SVG components
- Added tierColors export to tokens.js with federal/state/local teal-scale values (all WCAG AA text)
- Wired tier prop to CategorySection titlePill with null-safe fallbacks
- Added imageFocalPoint prop to PoliticianCard and PoliticianProfile defaulting to 'center 20%'
- Built and published @chrisandrewsedu/ev-ui@0.1.55 to GitHub npm registry

## Task Commits

Each task was committed atomically:

1. **Task 1: Create icons.js, add tierColors, add tier prop to CategorySection** - `2a8dcf6` (feat)
2. **Task 2: Add imageFocalPoint prop, bump version, build and publish** - `e576866` (feat)

## Files Created/Modified
- `ev-ui/src/icons.js` - BallotIcon, CompassIcon, BranchIcon inline SVG React components
- `ev-ui/src/tokens.js` - tierColors export added (federal/state/local teal-scale)
- `ev-ui/src/CategorySection.jsx` - tier prop + tierColors import, titlePill uses tierStyle
- `ev-ui/src/PoliticianCard.jsx` - imageFocalPoint prop, objectPosition defaults to 'center 20%'
- `ev-ui/src/PoliticianProfile.jsx` - imageFocalPoint prop, objectPosition defaults to 'center 20%'
- `ev-ui/src/index.js` - Added icons export
- `ev-ui/package.json` - Version bumped to 0.1.55

## Decisions Made
- Icons are inline SVG in ev-ui directly — no lucide-react or @heroicons dependency added to ev-ui (tsup splitting:false would include the whole icon library in the bundle)
- tierColors.local.text uses teal-600 (#005366, 8.1:1 on white) rather than teal-200 which is decorative-only (1.8:1 contrast, fails WCAG AA)
- imageFocalPoint defaults to 'center 20%' to favor face region in politician headshots without breaking existing usage

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Phase 103 (essentials visual polish) can now consume all new exports from ev-ui v0.1.55
- BallotIcon, CompassIcon, BranchIcon ready for use as section/feature indicators
- tierColors ready for tier-aware section headers in essentials Results page
- imageFocalPoint available for headshot crop control per politician card/profile

---
*Phase: 102-ev-ui-foundation-quick-wins*
*Completed: 2026-04-04*
