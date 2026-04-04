---
phase: 104-compass-first-card-prototype
plan: 01
subsystem: ui
tags: [react, radar-chart, ev-ui, mock-data, compass, prototype, bloomington]

# Dependency graph
requires:
  - phase: 103-essentials-wiring-landing-page
    provides: IconOverlay component with ballot/compass/branch icons
  - phase: 102-ev-ui-foundation-quick-wins
    provides: RadarChartCore, CategorySection, tierColors tokens from ev-ui
provides:
  - mockCompassData.js — 108 politician UUID-keyed mock stances using real topic short_titles
  - CompassFirstCard.jsx — compass-first card with 3 layout variants (A/B/C) + placeholder radar
  - VARIANT_CONFIG named export for Prototype page grid layout access
affects: [104-02-PLAN.md (Prototype page that consumes both artifacts)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "RadarChartCore label suppression: padding=0 + labelOffset=0 collapses viewBox to [0,0,size,size], clipping labels outside polygon"
    - "Mock data file: static JS export keyed by politician UUID, values are short_title maps"
    - "4-profile pattern: progressive/moderate/conservative/mixed assigned round-robin for visual variety"

key-files:
  created:
    - essentials/src/data/mockCompassData.js
    - essentials/src/components/CompassFirstCard.jsx
  modified: []

key-decisions:
  - "Mock data covers all 20 active topics (not just 8) so dual overlay works with any user topic selection"
  - "PlaceholderRadar as inline function in CompassFirstCard — not a separate file per UI-SPEC"
  - "IconOverlay wrapped in nested position:relative div to anchor absolute icon positioning to text content area"
  - "buildAnswerMapByShortTitle called with is_active filter on allTopics to match CompassContext behavior"

patterns-established:
  - "Pattern: VARIANT_CONFIG lookup object controls all variant-specific dimensions in one place, exported for consumer access"
  - "Pattern: Radar in shape-only mode — padding=0 + labelOffset=0 + overflow:hidden container clips labels outside viewBox"

requirements_completed: [PROTO-02]

# Metrics
duration: 5min
completed: 2026-04-04
---

# Phase 104 Plan 01: Compass-First Card Prototype Foundation Summary

**Static mock compass stances for 108 Bloomington politicians (4 distinct radar profiles) and CompassFirstCard with A/B/C variants, dual overlay support, and dashed-polygon placeholder state**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-04T14:59:09Z
- **Completed:** 2026-04-04T15:03:57Z
- **Tasks:** 2
- **Files modified:** 2 (both new)

## Accomplishments

- Created `mockCompassData.js` with 108 Bloomington IN politician entries, each using all 20 active `compass.topics` short_titles (exact case-sensitive strings from live DB query) and one of 4 visually distinct profiles (progressive, moderate, conservative, mixed)
- Built `CompassFirstCard.jsx` with `VARIANT_CONFIG` for A (200px radar / 2-col), B (150px radar / 3-col), C (140px radar / horizontal flex), dual overlay via `buildAnswerMapByShortTitle`, and `PlaceholderRadar` dashed octagon for no-data state
- Verified label suppression approach: `padding=0` + `labelOffset=0` + `overflow:hidden` container clips RadarChartCore labels outside the `0 0 size size` viewBox — no ev-ui changes required

## Task Commits

Each task was committed atomically:

1. **Task 1: Mock compass data file** - `a953911` (feat)
2. **Task 2: CompassFirstCard component** - `c05bb6f` (feat)

**Plan metadata:** (pending final docs commit)

## Files Created/Modified

- `/Users/chrisandrews/Documents/GitHub/essentials/src/data/mockCompassData.js` — 108 politician entries, 20 topics each, 4 profiles, pure static export
- `/Users/chrisandrews/Documents/GitHub/essentials/src/components/CompassFirstCard.jsx` — variant-driven card with RadarChartCore, PlaceholderRadar, dual overlay, keyboard nav, ARIA roles

## Decisions Made

- Mock data covers all 20 active topics rather than just 8, so the dual overlay works regardless of which 8 topics a user has selected in their compass
- `PlaceholderRadar` is an inline function (not a separate file) per UI-SPEC — keeps the component self-contained
- `IconOverlay` wrapped in a nested `position: relative` div inside the text content area to anchor its `position: absolute; bottom: 4; right: 4` to the text area, not the card root (addresses Research Pitfall 4)
- `buildAnswerMapByShortTitle` called with `allTopics.filter(t => t.is_active !== false)` to match server-side active flag (column is `is_active` not `active`)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected active topics filter column name**
- **Found during:** Task 1 (mock data creation)
- **Issue:** Plan references `active` column; actual column is `is_active` in `compass.topics` table
- **Fix:** Used `is_active` in DB query and `t.is_active !== false` in CompassFirstCard filter
- **Files modified:** essentials/src/components/CompassFirstCard.jsx
- **Verification:** DB query `WHERE is_active = true` returned 20 topics correctly
- **Committed in:** c05bb6f (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - column name bug)
**Impact on plan:** Minor correction, no scope change. Dual overlay will work correctly with user's active topics.

## Issues Encountered

- `compass.topics` has no `display_order` column — mock data topic order is alphabetical by short_title. This is acceptable since RadarChartCore uses the `allTopics` order from CompassContext at render time, not the mock data key order.
- DB schema uses `is_active` (not `active`) for the active flag. Fixed inline.

## Known Stubs

None — mock data is intentionally static (this is the prototype, not production). Plan 02 (Prototype page) wires the mock data to the card grid.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Both artifacts ready for Plan 02 (Prototype.jsx page + App.jsx route registration)
- `VARIANT_CONFIG` exported from `CompassFirstCard.jsx` for grid layout access in Prototype page
- `mockCompassData.js` exports default object keyed by politician UUID for direct lookup by politician ID

## Self-Check: PASSED

- FOUND: essentials/src/data/mockCompassData.js
- FOUND: essentials/src/components/CompassFirstCard.jsx
- FOUND: .planning/phases/104-compass-first-card-prototype/104-01-SUMMARY.md
- FOUND commit a953911 (mock compass data)
- FOUND commit c05bb6f (CompassFirstCard component)

---
*Phase: 104-compass-first-card-prototype*
*Completed: 2026-04-04*
