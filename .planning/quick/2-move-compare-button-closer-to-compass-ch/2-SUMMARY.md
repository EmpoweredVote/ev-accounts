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
- Added pb-16 to main page container so the fixed-position SavePromptModal does not cover the Compare button or other bottom content
- Tightened mobile Graph tab chart max-height offset by 40px so the Compare button fits within a typical mobile viewport without scrolling

## Task Commits

1. **Task 1: Reposition Compare button and add save-banner padding** - `3895d94` (feat)

## Files Created/Modified
- `CompassV2/src/pages/Compass.jsx` - Three targeted Tailwind class changes: mt-4->mt-1 on ActionButtons, added pb-16 to outer container, max-h calc offset 240->280px on mobile chart

## Decisions Made
- Used pb-16 rather than a conditional padding approach — the save banner always appears for guests after 1.5s, so unconditional padding is simpler and more robust
- Did not touch desktop chart container dimensions as planned — desktop has ample vertical space

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Task 2 is a human-verify checkpoint — user should open the Compass page on mobile and desktop to confirm the Compare button is visible below the chart and the save banner does not overlap it
- After verification, this quick task is fully complete
- Awaiting checkpoint approval before marking QUICK-2 done

---
*Phase: quick-2*
*Completed: 2026-03-05*
