---
phase: 23-ux-cleanup
plan: "02"
subsystem: ui
tags: [react, tailwind, compass, library, calibration, quiz]

# Dependency graph
requires:
  - phase: 23-01
    provides: Library and Compass pages with simplified controls
provides:
  - LibraryDrawer with question-text-first hierarchy (no poles)
  - Quiz page (full and curated) with question-text-first hierarchy (no poles)
  - Library topic cards with topic name + question text subtitle (no poles)
  - CalibrationOverlay answer step with question-text-first hierarchy (no poles)
  - CalibrationOverlay pick step cards with topic name + question text subtitle (no poles)
affects: [CompassV2, ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Question-text-first hierarchy: getQuestionText(topic) || parseTensionTitle(topic).name as primary, topic name as secondary"

key-files:
  created: []
  modified:
    - CompassV2/src/components/LibraryDrawer.jsx
    - CompassV2/src/pages/Quiz.jsx
    - CompassV2/src/pages/Library.jsx
    - CompassV2/src/components/CalibrationOverlay.jsx

key-decisions:
  - "Use getQuestionText(topic) || parseTensionTitle(topic).name as title — falls back to topic name when no question text exists, prevents empty title"
  - "Tension poles removed from all views — users engage with questions not abstract pole descriptions"
  - "Hide subtitle when fallback is used — avoids showing identical topic name twice as both title and subtitle"

patterns-established:
  - "Question-first pattern: question text as primary content, topic name as secondary label across all stance selection views"

requirements-completed:
  - UX-04

# Metrics
duration: 2min
completed: 2026-02-22
---

# Phase 23 Plan 02: Text Hierarchy Restructure Summary

**Question text promoted to primary content in all four compass views (LibraryDrawer, Quiz, Library, CalibrationOverlay) with tension poles removed entirely**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-22T15:42:04Z
- **Completed:** 2026-02-22T15:44:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- LibraryDrawer header now shows question text as title and topic name as subtitle; removed separate italic question text block that previously duplicated content below the header
- Quiz page (full mode and curated mode) both now show question text as h1 with topic name as muted subtitle — tension poles removed from both title blocks
- Library topic cards now show topic name as card title and question text as card subtitle — replaced IIFE that rendered name + poles
- CalibrationOverlay answer step now shows question text as the large title and topic name as subtitle; CalibrationOverlay pick step cards now show topic name + question text subtitle (replacing name + poles IIFE pattern)

## Task Commits

Each task was committed atomically (in CompassV2 repo):

1. **Task 1: Restructure text hierarchy in LibraryDrawer and Quiz page** - `2a5a811` (feat)
2. **Task 2: Restructure text hierarchy in Library cards and CalibrationOverlay** - `abb1457` (feat)

**Plan metadata:** _(docs commit in planning repo)_

## Files Created/Modified
- `CompassV2/src/components/LibraryDrawer.jsx` - Header replaced: question text as title, topic name as subtitle; removed separate italic question paragraph
- `CompassV2/src/pages/Quiz.jsx` - Full mode and curated mode title blocks restructured: question text as h1, topic name as subtitle, poles removed
- `CompassV2/src/pages/Library.jsx` - Topic card text area replaced: IIFE with name+poles swapped for direct render of name + getQuestionText subtitle
- `CompassV2/src/components/CalibrationOverlay.jsx` - Answer step title block and pick step card text area both updated to question-text-first pattern

## Decisions Made
- Fall back to `parseTensionTitle(topic).name` when `getQuestionText(topic)` is empty — prevents blank titles for topics that have no question_text field
- Suppress subtitle when fallback is used — avoids showing the same topic name as both title and subtitle
- Remove tension poles entirely rather than demote — poles like "Open Borders & Expanded Entry — Closed Borders & Restricted Entry" are jargon that obscures the actual question

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- CompassV2/ is tracked in its own git repository (separate from the planning repo). Committed code changes in the CompassV2 repo and plan metadata in the planning repo separately.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All four views now use consistent question-text-first hierarchy
- Tension poles are fully eliminated from the UI
- Ready for any additional UX polish tasks in this phase

---
*Phase: 23-ux-cleanup*
*Completed: 2026-02-22*

## Self-Check: PASSED

- FOUND: CompassV2/src/components/LibraryDrawer.jsx
- FOUND: CompassV2/src/pages/Quiz.jsx
- FOUND: CompassV2/src/pages/Library.jsx
- FOUND: CompassV2/src/components/CalibrationOverlay.jsx
- FOUND: .planning/phases/23-ux-cleanup/23-02-SUMMARY.md
- FOUND: commit 2a5a811 (Task 1)
- FOUND: commit abb1457 (Task 2)
