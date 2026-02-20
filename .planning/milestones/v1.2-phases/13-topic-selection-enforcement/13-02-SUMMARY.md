---
phase: 13-topic-selection-enforcement
plan: 02
subsystem: ui
tags: [react, compass, library, topic-selection, ux]

# Dependency graph
requires:
  - phase: 13-topic-selection-enforcement
    plan: 01
    provides: Library card add/remove toggle and counter badge (cap enforcement at card level)
provides:
  - Compass page 3-topic minimum gate with progress dots and contextual message
  - LibraryDrawer remove-from-compass action with inline confirmation
  - AddTopicModal 8-topic cap with disabled buttons and X/8 counter
affects:
  - compass-ux
  - topic-selection-enforcement

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Derived boolean gate (showChart) controls conditional rendering of chart vs progress UI"
    - "Inline confirmation panel (not modal) for destructive actions within drawer"
    - "Combined cap check: selectedTopics.length + pending.length >= MAX before adding"

key-files:
  created: []
  modified:
    - CompassV2/src/pages/Compass.jsx
    - CompassV2/src/components/LibraryDrawer.jsx
    - CompassV2/src/components/AddTopicModal.jsx
    - CompassV2/src/pages/Library.jsx

key-decisions:
  - "Compare button hidden (not disabled) when showChart is false — cleaner UX than a disabled state"
  - "compassTopicCount <= 3 shows warning (not > 3) — warning shows when at exactly 3 since removal will break it"
  - "No CTA button to Library in MinimumProgress — bottom nav already provides that navigation path"

patterns-established:
  - "MinimumProgress: reusable component pattern for gated views with dot progress indicator"
  - "Drawer confirmation: inline panel inside drawer (not a popover) consistent with drawer UX"

requirements-completed: [TSEL-01, TSEL-02, TSEL-03]

# Metrics
duration: 3min
completed: 2026-02-19
---

# Phase 13 Plan 02: Topic Selection Enforcement Summary

**3-topic minimum gate on Compass page with progress dots, remove-from-compass in LibraryDrawer with inline confirmation, and 8-topic cap with disabled buttons in AddTopicModal**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-19T03:39:40Z
- **Completed:** 2026-02-19T03:43:36Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Compass page shows "Answer X more topics to see your compass" with 3 dot indicator when fewer than 3 answered compass topics; chart renders only when count >= 3
- Removing a topic that drops the answered count below 3 instantly swaps the chart to the progress view (reactive derived state, no extra logic needed)
- LibraryDrawer shows a "Remove from compass" link for on-compass topics, with an inline confirmation panel that warns when compassTopicCount <= 3
- AddTopicModal enforces 8-topic cap: individual Add buttons are disabled and styled gray when selectedTopics.length + selected.length >= 8; header shows X/8 counter
- Library.jsx wired to pass isOnCompass, onRemoveFromCompass, and compassTopicCount props to LibraryDrawer

## Task Commits

Each task was committed atomically:

1. **Task 1: Enforce 3-topic minimum on Compass page with progress indicator** - `a70f183` (feat)
2. **Task 2: Add "Remove from compass" to LibraryDrawer and enforce cap in AddTopicModal** - `72ff3ba` (feat)

## Files Created/Modified
- `CompassV2/src/pages/Compass.jsx` - Added MinimumProgress component, showChart derived state, gated chart and Compare button behind showChart
- `CompassV2/src/components/LibraryDrawer.jsx` - Added isOnCompass/onRemoveFromCompass/compassTopicCount props, remove button, inline confirmation panel with below-3 warning
- `CompassV2/src/components/AddTopicModal.jsx` - Added isAtCap check in toggleSelect, disabled Add buttons at cap, X/8 counter in header
- `CompassV2/src/pages/Library.jsx` - Passed three new props to LibraryDrawer with inline onRemoveFromCompass callback preserving answers

## Decisions Made
- Compare button is hidden (not disabled) when showChart is false — avoids confusing disabled-button UX when the chart itself isn't visible
- compassTopicCount <= 3 condition shows the below-3 warning (at exactly 3 since removing will break the chart threshold)
- No CTA button to Library in MinimumProgress per locked plan decision — bottom nav already provides that navigation

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- CompassV2 is a separate git repo from the workspace root — commits required `git -C CompassV2/` rather than `git add` from workspace root. Handled automatically.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 13 complete — all topic selection enforcement features implemented across all entry points
- Library cards (Plan 01), LibraryDrawer, AddTopicModal, and BuildCompass all enforce the 8-topic cap
- Compass page enforces 3-topic minimum with graceful progress UI
- Ready for Phase 14

## Self-Check: PASSED

- Compass.jsx: FOUND
- LibraryDrawer.jsx: FOUND
- AddTopicModal.jsx: FOUND
- Library.jsx: FOUND
- 13-02-SUMMARY.md: FOUND
- Commit a70f183: FOUND
- Commit 72ff3ba: FOUND

---
*Phase: 13-topic-selection-enforcement*
*Completed: 2026-02-19*
