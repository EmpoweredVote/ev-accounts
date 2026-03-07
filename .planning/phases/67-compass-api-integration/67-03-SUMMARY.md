---
phase: 67-compass-api-integration
plan: 03
subsystem: ui
tags: [react, radar-chart, tooltip, popover, ev-ui, compass, politician-cards]

requires:
  - phase: 67-02
    provides: CompassContext with politicianIdsWithStances Set, allTopics, userAnswers, selectedTopics

provides:
  - CompassPreview component (mini radar chart tooltip/popover)
  - Compass badge on Results page politician cards (only for politicians with stance data)
  - Click-to-open mini radar chart popover showing politician stances + optional user overlay

affects: [68-compass-guest-data, profile-page-compass-integration]

tech-stack:
  added: []
  patterns:
    - "createPortal to document.body for fixed-position popovers — avoids overflow/z-index clipping"
    - "data-pol-id attribute on card wrappers + querySelector to get compass button ref after render"
    - "useCompass() closure pattern — renderPoliticianCard moved inside component for access to context state"

key-files:
  created:
    - essentials/src/components/CompassPreview.jsx
  modified:
    - essentials/src/pages/Results.jsx

key-decisions:
  - "Used click-to-toggle (not hover) for compass badge interaction — PoliticianCard from ev-ui doesn't expose onMouseEnter on its internal compass button, making hover impractical without modifying ev-ui"
  - "renderPoliticianCard moved inside Results component (from module-level) to access politicianIdsWithStances and setPreviewPol via closure — avoids prop-drilling"
  - "CompassPreview positions with position:fixed + getBoundingClientRect — portal to document.body, outside any overflow:hidden containers"
  - "Arrow caret flips above/below badge based on viewport space detection at render time"
  - "pointerdown outside + scroll event both dismiss the preview, with a 50ms delay on pointerdown to prevent immediate re-open from the badge click itself"

patterns-established:
  - "Portal popover pattern: createPortal(popover, document.body) + position:fixed from anchor rect"
  - "Compass badge only rendered (onCompassClick prop) when politicianIdsWithStances.has(pol.id)"

requirements-completed: [DATA-03]

duration: 3min
completed: 2026-03-07
---

# Phase 67 Plan 03: Compass Badge + Preview Summary

**CompassPreview popover with mini RadarChartCore on politician cards — badges show only for the 23 politicians with stance data, click opens a fixed-position tooltip with optional user overlay**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-07T08:42:12Z
- **Completed:** 2026-03-07T08:45:00Z
- **Tasks:** 2 of 3 executed (Task 3 is human-verify checkpoint)
- **Files modified:** 2

## Accomplishments
- Created `CompassPreview.jsx` — a portal-based popover component that fetches and renders a mini `RadarChartCore` (size=180) for a politician, with the user's compass data as a blue overlay when logged in
- Updated `Results.jsx` to consume `useCompass()`, conditionally pass `onCompassClick` to `PoliticianCard` only for politicians in `politicianIdsWithStances`, and render `CompassPreview` on badge click
- Build passes with zero errors — all 65 modules transform cleanly

## Task Commits

1. **Task 1: Create CompassPreview popover component** - `050d31e` (feat)
2. **Task 2: Wire compass badge into Results page PoliticianCards** - `a8f96ee` (feat)

## Files Created/Modified
- `essentials/src/components/CompassPreview.jsx` - Portal-based mini radar chart popover with fetch, positioning, and dismiss logic
- `essentials/src/pages/Results.jsx` - CompassPreview + useCompass integration, renderPoliticianCard moved inside component

## Decisions Made
- Used click-to-toggle instead of hover for compass badge — the `PoliticianCard` ev-ui component doesn't expose `onMouseEnter` on its internal compass button, making hover impractical without forking ev-ui
- Moved `renderPoliticianCard` from module-level function to inside the `Results` component to get closure access to `politicianIdsWithStances` and `setPreviewPol` without prop drilling
- `CompassPreview` uses `createPortal(popover, document.body)` + `position:fixed` — avoids z-index and overflow:hidden clipping in the scrollable main panel
- Popover dismiss uses `pointerdown` (not `click`) outside listener with 50ms delay to prevent badge click from immediately re-opening the preview

## Deviations from Plan

None - plan executed exactly as written. The one noted change (click-to-toggle vs. hover) was pre-acknowledged in the plan itself as the pragmatic approach.

## Issues Encountered
- `acorn` parser rejected JSX as expected (it's not a JSX parser) — verified correctness via `npx vite build` instead, which succeeded cleanly
- `&apos;` HTML entity in JSX was replaced with string concatenation `{politicianName + "'s Compass"}` for proper JSX rendering

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Task 3 (human-verify checkpoint) awaits user verification in browser
- Full Phase 67 integration ready to test: auth indicator, compass badges on cards, mini radar preview
- Phase 68 (guest compass data) can proceed once verification passes

---
*Phase: 67-compass-api-integration*
*Completed: 2026-03-07*
