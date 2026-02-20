---
phase: 14-guided-onboarding-flow
plan: "02"
subsystem: ui
tags: [react, compass, library-drawer, settings-menu, reset]

# Dependency graph
requires:
  - phase: 13-topic-selection-enforcement
    provides: LibraryDrawer with remove-from-compass action and compassTopicCount prop
  - phase: 14-guided-onboarding-flow
    plan: "01"
    provides: Compass page with calibration language and MinimumProgress state
provides:
  - Compass page spoke clicks open LibraryDrawer (instead of ReplaceTopicModal)
  - Stance changes via drawer update compass chart immediately
  - Settings gear icon with Reset compass menu on Compass page
  - Reset compass clears topics/answers/write-ins/inversions from localStorage and server
affects:
  - 14-03-PLAN (onboarding overlay — reset triggers MinimumProgress state that plan 03 wires to overlay)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "spoke-click-to-drawer: onReplaceTopic callback now resolves shortTitle to topic object and opens LibraryDrawer"
    - "settings-menu pattern: gear icon + fixed backdrop overlay + absolute dropdown, z-indexed above content"
    - "reset pattern: clear localStorage keys + reset context state + optional server DELETE for logged-in users"

key-files:
  created: []
  modified:
    - CompassV2/src/pages/Compass.jsx

key-decisions:
  - "Tasks 1 and 2 committed together — single Compass.jsx file, cohesive implementation, no natural commit seam"
  - "onReplaceTopic receives shortTitle (string) from RadarChartCore — must look up full topic object via topics.find()"
  - "Reset clears onboarding_spokeFlip from localStorage so spoke hint reappears after fresh start"

patterns-established:
  - "Drawer handlers co-located with Compass page state — same pattern as Library.jsx but scoped to Compass"

requirements-completed: [ONBD-04]

# Metrics
duration: 3min
completed: 2026-02-19
---

# Phase 14 Plan 02: Compass Spoke-Click-to-Drawer and Reset Menu Summary

**Compass spoke clicks now open LibraryDrawer (replacing ReplaceTopicModal), with a settings gear icon providing a Reset compass option that clears all user data**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-19T15:39:44Z
- **Completed:** 2026-02-19T15:43:00Z
- **Tasks:** 2 (committed together)
- **Files modified:** 1

## Accomplishments
- Replaced spoke-click-to-swap (ReplaceTopicModal) with spoke-click-to-drawer (LibraryDrawer) on both desktop and mobile RadarChart instances
- Added drawer handler functions (getAnswer, handleDrawerSelect, handleDrawerWriteIn, handleDrawerCancelWriteIn) enabling stance changes directly from the compass page
- Added settings gear icon next to "Back to Library" button with dropdown menu
- Implemented handleResetCompass that clears all compass data (localStorage + context state + server DELETE for logged-in users) after confirmation dialog

## Task Commits

Both tasks committed together (single file, cohesive implementation):

1. **Tasks 1 + 2: Spoke-click-to-drawer + Reset compass menu** - `9966466` (feat)

**Plan metadata:** `ca9eef5` (docs: complete plan)

## Files Created/Modified
- `CompassV2/src/pages/Compass.jsx` - Replaced ReplaceTopicModal with LibraryDrawer integration; added settings gear icon and handleResetCompass; removed showReplaceModal, replacingTopic, handleReplace state/function

## Decisions Made
- Tasks 1 and 2 committed together — single Compass.jsx file, cohesive implementation, no natural commit seam between them
- `onReplaceTopic` prop on RadarChartCore receives `shortTitle` (string), so the callback resolves it to a full topic object via `topics.find()` before calling `setDrawerTopic`
- Reset handler clears `onboarding_spokeFlip` localStorage key so the spoke hint reappears for users starting fresh

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Compass page now has spoke-click-to-drawer wired up and a reset pathway
- Plan 03 (onboarding overlay) can hook into the MinimumProgress state that appears after reset
- No blockers for Plan 03 execution

---
*Phase: 14-guided-onboarding-flow*
*Completed: 2026-02-19*

## Self-Check: PASSED
- FOUND: CompassV2/src/pages/Compass.jsx
- FOUND: .planning/phases/14-guided-onboarding-flow/14-02-SUMMARY.md
- FOUND: commit 9966466 (feat: spoke-click-to-drawer + reset menu)
- FOUND: commit ca9eef5 (docs: plan metadata)
