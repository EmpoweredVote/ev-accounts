---
phase: 30-fix-compass-calibration-flow-layout-and-write-in-option
plan: 02
subsystem: ui
tags: [react, dnd-kit, compass, calibration, write-in, drag-and-drop]

# Dependency graph
requires:
  - phase: 30-fix-compass-calibration-flow-layout-and-write-in-option/30-01
    provides: "CalibrationOverlay answer step with 50/50 split, question text anchored above stances"
provides:
  - "CalibrationOverlay write-in drag-and-drop integration reusing Quiz.jsx pattern"
  - "SortableWriteInCard and SortableStanceLabel components in CalibrationOverlay"
  - "Decimal answer values (e.g., 1.5) saved to CompassContext for write-in placement"
affects: [CompassV2]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Write-in DnD pattern: SortableWriteInCard draggable, SortableStanceLabel non-draggable, position as writeInIndex+0.5 decimal"
    - "Topic-change useEffect derives stances inside effect (not outer orderedStances) to avoid stale closures over inverted spoke state"

key-files:
  created: []
  modified:
    - CompassV2/src/components/CalibrationOverlay.jsx

key-decisions:
  - "SortableStanceLabel and SortableWriteInCard copied verbatim from Quiz.jsx — avoids divergence and ensures behavioral parity"
  - "stanceContent rendered inline in JSX (not extracted to variable) to keep CalibrationOverlay's scoped state accessible without prop-threading"
  - "Topic-change useEffect derives stances inside effect using isFlippedInEffect — avoids stale closure over outer orderedStances which depends on currentTopic"
  - "handleSelectStance clears writeIns entry when a predefined stance is selected — ensures write-in doesn't persist when user switches back to standard stance"

patterns-established:
  - "Write-in DnD: writeInIndex + 0.5 decimal as answer value; Math.floor(val) to reconstruct position on restore"
  - "Restoration guard: savedWriteIn && val != null && !Number.isInteger(val) — requires both saved text and a decimal answer before restoring write-in mode"

requirements-completed: []

# Metrics
duration: 2min
completed: 2026-02-23
---

# Phase 30 Plan 02: Add Write-In Stance Option to CalibrationOverlay Summary

**Write-in drag-and-drop stance option added to CalibrationOverlay using dnd-kit, reusing SortableWriteInCard and SortableStanceLabel from Quiz.jsx with decimal answer values persisted to CompassContext**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-23T02:27:24Z
- **Completed:** 2026-02-23T02:30:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Added all dnd-kit imports (DndContext, SortableContext, CSS, restrictToVerticalAxis, PointerSensor, TouchSensor)
- Copied SortableStanceLabel and SortableWriteInCard verbatim from Quiz.jsx with SMOOTH_TRANSITION constant
- Added showWriteIn, writeInText, orderedItems, hasRepositioned state variables plus sensors
- Added writeIns/setWriteIns to useCompass() destructure
- Added selectWriteInPlacement, handleDragEnd, handleWriteInTextChange, handleCancelWriteIn handlers
- Updated topic-change useEffect to restore write-in state on topic navigation (derives stances inside effect to avoid stale closure)
- Replaced static stance buttons with conditional write-in block: stance buttons + "Write your own..." trigger when not in write-in mode, DndContext with sorted items when in write-in mode
- Updated handleSelectStance to clear writeIns when predefined stance selected

## Task Commits

Each task was committed atomically:

1. **Task 1: Add dnd-kit imports, write-in components, and state variables** - `d5bc4d9` (feat)
2. **Task 2: Add write-in handlers, topic-change restoration, and stanceContent JSX** - `9cf1861` (feat)

**Plan metadata:** see final commit below

## Files Created/Modified
- `CompassV2/src/components/CalibrationOverlay.jsx` - Write-in drag-and-drop integration: dnd-kit imports, SortableWriteInCard + SortableStanceLabel components, handlers, topic-change restoration, conditional JSX

## Decisions Made
- SortableStanceLabel and SortableWriteInCard copied verbatim from Quiz.jsx — avoids divergence and ensures behavioral parity with existing write-in UX
- stanceContent rendered inline in JSX rather than extracted to a variable — CalibrationOverlay has significant scoped state (orderedStances, showWriteIn, etc.) that would need prop-threading if extracted
- Topic-change useEffect derives stances inside the effect using a local isFlippedInEffect variable — avoids stale closure over outer orderedStances which depends on currentTopic useMemo
- handleSelectStance clears writeIns entry for the topic when user selects a predefined stance — prevents write-in text persisting in context after user reverts to standard option

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - build passed cleanly on first attempt after each task.

CompassV2 is a separate git repository nested within the workspace. Committed directly within the CompassV2 repo using `git -C /Users/chrisandrews/Documents/GitHub/CompassV2` (same pattern as Phase 30 Plan 01).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 30 complete — both layout fix (Plan 01) and write-in option (Plan 02) shipped
- CalibrationOverlay now has feature parity with Quiz.jsx for write-in stance entry
- Phase 31 (Essentials profile and district data fixes) can proceed

## Self-Check: PASSED

- FOUND: `.planning/phases/30-fix-compass-calibration-flow-layout-and-write-in-option/30-02-SUMMARY.md`
- FOUND: `CompassV2/src/components/CalibrationOverlay.jsx`
- FOUND: commit `d5bc4d9` (feat(30-02): add dnd-kit imports, write-in components, and state)
- FOUND: commit `9cf1861` (feat(30-02): add write-in handlers, topic restoration, and stanceContent JSX)

---
*Phase: 30-fix-compass-calibration-flow-layout-and-write-in-option*
*Completed: 2026-02-23*
