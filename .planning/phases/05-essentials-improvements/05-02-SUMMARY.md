---
phase: 05-essentials-improvements
plan: "02"
subsystem: ui
tags: [react, ev-ui, component-library, npm, github-packages]

# Dependency graph
requires: []
provides:
  - PoliticianCard component with optional badge prop (coral pill label)
  - ev-ui 0.1.17 published to GitHub npm registry
affects:
  - essentials (candidate card display — ESST-02)
  - 05-03-PLAN.md (card rendering in dashboard)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Badge as absolute-positioned child inside relative card container — avoids overflow:hidden clipping"
    - "Conditional JSX render: {badge && <span>} pattern for optional decorative elements"

key-files:
  created: []
  modified:
    - ev-ui/src/PoliticianCard.jsx
    - ev-ui/package.json

key-decisions:
  - "Badge rendered inside card (not outside) — card has overflow:hidden so external absolute positioning would be clipped"
  - "Badge uses zIndex:1 to render above image wrapper in both horizontal and vertical variants"

patterns-established:
  - "Optional badge prop pattern: falsy omission leaves card visually unchanged"

requirements-completed:
  - ESST-02

# Metrics
duration: 2min
completed: 2026-02-18
---

# Phase 5 Plan 02: PoliticianCard Badge Prop Summary

**Added coral pill badge prop to ev-ui PoliticianCard and published as version 0.1.17 to GitHub npm registry**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-18T17:00:27Z
- **Completed:** 2026-02-18T17:01:31Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `badge` string prop to PoliticianCard that renders an EV coral (#ff5740) pill in the top-right corner
- Badge is absolutely positioned inside the card's relative container — unaffected by `overflow: hidden`
- Updated JSDoc to document the new prop
- Built and published ev-ui 0.1.17 to GitHub npm registry (npm.pkg.github.com)

## Task Commits

Each task was committed atomically in the ev-ui repo:

1. **Task 1: Add badge prop to PoliticianCard** - `9d1b04b` (feat)
2. **Task 2: Bump version and publish ev-ui 0.1.17** - `4047cd9` (chore)

## Files Created/Modified
- `ev-ui/src/PoliticianCard.jsx` - Badge prop added: destructured, styled with evCoral, conditionally rendered after opening card div
- `ev-ui/package.json` - Version bumped from 0.1.16 to 0.1.17

## Decisions Made
- Badge rendered inside the card's `<div>` to respect `overflow: hidden` on the card boundary — external absolute positioning would be clipped by the card container
- Used `zIndex: 1` on badge to ensure it renders above the imageWrapper in both horizontal and vertical variants

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

ev-ui is its own git repository (not tracked by the workspace root git). Commits were made to the ev-ui repo directly rather than the workspace repo. This is expected behavior given the workspace structure.

## User Setup Required

None - no external service configuration required beyond the existing GitHub npm registry authentication.

## Next Phase Readiness
- ev-ui 0.1.17 is published and installable via `npm install @chrisandrewsedu/ev-ui@0.1.17`
- Downstream consumers (essentials app) can pass `badge="Candidate"` to PoliticianCard to show the coral pill label
- Ready for Phase 5 Plan 03 which will use this badge in the candidate display

---
*Phase: 05-essentials-improvements*
*Completed: 2026-02-18*
