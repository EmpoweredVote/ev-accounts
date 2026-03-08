---
phase: 67-compass-api-integration
plan: 03
subsystem: ui
tags: [react, radar-chart, tooltip, popover, ev-ui, compass, politician-cards]

requires:
  - phase: 67-02
    provides: CompassContext with politicianIdsWithStances Set, allTopics, userAnswers, selectedTopics

provides:
  - CompassPreview component (mini radar chart tooltip/popover with CTA mode)
  - Compass badge on Results page politician cards (only for politicians with stance data)
  - Click-to-open mini radar chart popover showing politician stances + optional user overlay
  - CTA mode when user has no compass data (greyed compass icon + Take the Quiz button)

affects: [68-compass-guest-data, profile-page-compass-integration]

tech-stack:
  added: []
  patterns:
    - "createPortal to document.body for fixed-position popovers — avoids overflow/z-index clipping"
    - "data-pol-id attribute on card wrappers + querySelector to get compass button ref after render"
    - "useCompass() closure pattern — renderPoliticianCard moved inside component for access to context state"
    - "CTA mode pattern: show action prompt instead of empty chart when user hasn't provided data"
    - "8-spoke cap on mini RadarChartCore to prevent label crowding in 180px preview"

key-files:
  created:
    - essentials/src/components/CompassPreview.jsx
  modified:
    - essentials/src/pages/Results.jsx
    - ev-ui/src/PoliticianCard.jsx

key-decisions:
  - "Used click-to-toggle (not hover) for compass badge interaction — PoliticianCard from ev-ui doesn't expose onMouseEnter on its internal compass button, making hover impractical without modifying ev-ui"
  - "renderPoliticianCard moved inside Results component (from module-level) to access politicianIdsWithStances and setPreviewPol via closure — avoids prop-drilling"
  - "CompassPreview positions with position:fixed + getBoundingClientRect — portal to document.body, outside any overflow:hidden containers"
  - "Arrow caret flips above/below badge based on viewport space detection at render time"
  - "pointerdown outside + scroll event both dismiss the preview, with a 50ms delay on pointerdown to prevent immediate re-open from the badge click itself"
  - "Compass badge button shrunk from 36px to 28px in PoliticianCard (ev-ui) — user-directed at checkpoint"
  - "CompassPreview CTA mode added — greyed compass icon + Take the Quiz link when user has no answers"
  - "RadarChartCore capped at 8 spokes max in CompassPreview — prevents label crowding in mini chart"

patterns-established:
  - "Portal popover pattern: createPortal(popover, document.body) + position:fixed from anchor rect"
  - "Compass badge only rendered (onCompassClick prop) when politicianIdsWithStances.has(pol.id)"
  - "CTA mode: detect empty userAnswers, render prompt to take quiz instead of partial/empty chart"

requirements-completed: [DATA-03]

duration: ~45min
completed: 2026-03-07
---

# Phase 67 Plan 03: Compass Badge + Preview Summary

**CompassPreview portal-based popover with mini RadarChartCore on politician Results cards — badge shows only for 23 politicians with stance data, click opens fixed-position tooltip with user overlay + CTA mode for unanswered users**

## Performance

- **Duration:** ~45 min (including checkpoint verification and modifications)
- **Started:** 2026-03-07T08:42:12Z
- **Completed:** 2026-03-07
- **Tasks:** 3 (including human-verify checkpoint)
- **Files modified:** 3

## Accomplishments

- Created `CompassPreview.jsx` — a portal-based popover component that fetches and renders a mini `RadarChartCore` (size=180, 8-spoke max) for a politician, with the user's compass data as a blue overlay when logged in; shows CTA mode when user has no answers
- Updated `Results.jsx` to consume `useCompass()`, conditionally pass `onCompassClick` to `PoliticianCard` only for politicians in `politicianIdsWithStances`, and render `CompassPreview` on badge click
- Applied user-requested checkpoint modifications: badge shrunk to 28px in ev-ui `PoliticianCard`, CTA mode added, 8-spoke cap enforced
- Build passes with zero errors

## Task Commits

1. **Task 1: Create CompassPreview popover component** - `050d31e` (feat)
2. **Task 2: Wire compass badge into Results page PoliticianCards** - `a8f96ee` (feat)
3. **Task 3 checkpoint modifications (user-directed post-verify):**
   - `07dd838` - fix: shrink compass badge button from 36px to 28px (ev-ui)
   - `985b4b3` - fix: compass preview CTA mode and 8-spoke cap

## Files Created/Modified

- `essentials/src/components/CompassPreview.jsx` - Portal-based mini radar chart popover with fetch, positioning, dismiss logic, CTA mode, and 8-spoke cap
- `essentials/src/pages/Results.jsx` - CompassPreview + useCompass integration, renderPoliticianCard moved inside component
- `ev-ui/src/PoliticianCard.jsx` - Compass badge button shrunk from 36px to 28px

## Decisions Made

- Used click-to-toggle instead of hover for compass badge — the `PoliticianCard` ev-ui component doesn't expose `onMouseEnter` on its internal compass button, making hover impractical without forking ev-ui
- Moved `renderPoliticianCard` from module-level function to inside the `Results` component to get closure access to `politicianIdsWithStances` and `setPreviewPol` without prop drilling
- `CompassPreview` uses `createPortal(popover, document.body)` + `position:fixed` — avoids z-index and overflow:hidden clipping in the scrollable main panel
- Popover dismiss uses `pointerdown` (not `click`) outside listener with 50ms delay to prevent badge click from immediately re-opening the preview

## Deviations from Plan

### User-Directed Checkpoint Modifications

These three changes were applied after the human-verify checkpoint at user request:

**1. Badge size reduction**
- **Requested at:** Task 3 checkpoint
- **Change:** Compass badge button in `ev-ui/src/PoliticianCard.jsx` shrunk from 36px to 28px
- **Committed in:** `07dd838`

**2. CTA mode for no-compass-data users**
- **Requested at:** Task 3 checkpoint
- **Change:** `CompassPreview.jsx` detects empty `userAnswers` and renders a greyed compass icon + "Take the Quiz" button instead of a partial/empty chart
- **Committed in:** `985b4b3`

**3. 8-spoke cap on mini chart**
- **Requested at:** Task 3 checkpoint
- **Change:** Topics array in `CompassPreview` capped at 8 items max before passing to `RadarChartCore` — prevents label crowding in the 180px preview
- **Committed in:** `985b4b3`

---

**Total deviations:** 3 user-directed modifications at checkpoint approval
**Impact on plan:** All improvements to UX; core integration plan executed as written.

## Issues Encountered

- `acorn` parser rejected JSX as expected (it's not a JSX parser) — verified correctness via `npx vite build` instead, which succeeded cleanly
- `&apos;` HTML entity in JSX was replaced with string concatenation for proper JSX rendering

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Full Phase 67 compass integration complete: cookie domain branching, API functions, CompassContext with auth, AuthIndicator, compass badges on Results cards, mini radar preview with user overlay and CTA mode
- `politicianIdsWithStances` Set is available in CompassContext for profile page badge rendering in future phases
- Phase 68 (guest compass data) is the logical next step — CompassV2 stores localStorage data on its origin; Essentials cannot read it cross-origin

## Self-Check: PASSED

- FOUND: `essentials/src/components/CompassPreview.jsx`
- FOUND: `essentials/src/pages/Results.jsx`
- FOUND: commit `050d31e` (Task 1)
- FOUND: commit `a8f96ee` (Task 2)
- FOUND: commit `07dd838` (checkpoint badge fix, in ev-ui repo)
- FOUND: commit `985b4b3` (checkpoint CTA mode + 8-spoke cap)
- FOUND: commit `d4215a7` (plan metadata)

---
*Phase: 67-compass-api-integration*
*Completed: 2026-03-07*
