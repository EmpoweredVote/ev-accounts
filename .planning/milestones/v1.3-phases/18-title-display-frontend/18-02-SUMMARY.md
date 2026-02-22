---
phase: 18-title-display-frontend
plan: 02
subsystem: ui
tags: [react, tailwind, compass, topic-display, tension-title, quiz, compare-panel]

# Dependency graph
requires:
  - phase: 18-title-display-frontend
    plan: 01
    provides: parseTensionTitle helper and two-line tension title layout on Library cards and calibration pick-step cards
affects:
  - 19-calibration-flow (calibration UX improvements depend on accurate topic names in all views)

provides:
  - LibraryDrawer header shows two-line tension title (name + poles) instead of short_title in uppercase
  - LibraryDrawer QuestionText italic prompt between title and stances
  - CalibrationOverlay answer step shows two-line tension title + centered italic QuestionText prompt
  - Quiz full mode and curated mode show two-line tension title + italic QuestionText above stances
  - ComparePanel dropdown shows topic name from tension title (not short_title)
  - ComparePanel tension title heading + italic QuestionText between title and stances
  - Zero start_phrase references in CompassV2 src/ (broken field removed from all views)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-line tension title with IIFE inline in JSX: { name, poles } = parseTensionTitle(topic); render name as heading, poles as muted line, skip when null"
    - "Conditional QuestionText: only rendered when getQuestionText returns non-empty string"
    - "Italic QuestionText styling: italic font-medium text-gray-600 text-sm — consistent across all stance-showing views"

key-files:
  created: []
  modified:
    - CompassV2/src/components/LibraryDrawer.jsx
    - CompassV2/src/components/CalibrationOverlay.jsx
    - CompassV2/src/pages/Quiz.jsx
    - CompassV2/src/components/ComparePanel.jsx

key-decisions:
  - "Admin TopicEditor placeholder 'Where do you stand on...' left unchanged — it is placeholder attribute guidance text in an admin form, not a user-facing display fallback; out of scope"
  - "IIFE pattern used consistently in JSX to call parseTensionTitle without extracting variables outside map/render scope"
  - "stanceContent in Quiz.jsx no longer has a start_phrase heading — stances now follow directly after the title+QuestionText block in both full and curated modes"
  - "ComparePanel dropdown value stays as short_title (data key) while display text uses tension title name — backward compatible"

patterns-established:
  - "Tension title heading pattern for drawer/overlay/panel headers: text-base font-semibold text-neutral-800 for name, text-sm text-gray-500 font-normal for poles"
  - "Italic QuestionText bridge: placed between tension title and stances, skipped entirely when getQuestionText returns empty string"

requirements-completed: [TITLE-02, TITLE-03]

# Metrics
duration: 1min
completed: 2026-02-21
---

# Phase 18 Plan 02: Title Display Frontend Summary

**Two-line tension title + italic QuestionText bridge applied to LibraryDrawer, CalibrationOverlay answer step, Quiz (full and curated modes), and ComparePanel dropdown; start_phrase removed from all user-facing surfaces**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-02-21T04:17:31Z
- **Completed:** 2026-02-21T04:18:49Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Updated LibraryDrawer header to use two-line tension title (name line 1, poles line 2) replacing the old `short_title` in uppercase tracking-wide text; QuestionText now appears as italic prompt between title and stances
- Updated CalibrationOverlay answer step: two-line tension title heading + centered italic QuestionText prompt; removed broken `start_phrase` heading that was rendering "undefined..." since Phase 17 dropped that field
- Updated Quiz.jsx both modes (full and curated): two-line tension title + italic QuestionText replaces the old `getQuestionText` h1; removed `start_phrase` heading from shared `stanceContent`
- Updated ComparePanel dropdown to display topic name from `parseTensionTitle` instead of raw `short_title`; added tension title heading + italic QuestionText between title and stances
- Verified: zero `start_phrase` references remain in CompassV2 `src/`; build succeeds; all five surfaces (Library cards, calibration pick/answer, quiz, compare panel, library drawer) use the same `parseTensionTitle` helper

## Task Commits

Each task was committed atomically in the CompassV2 repo:

1. **Task 1: Update LibraryDrawer and CalibrationOverlay answer step** - `a9b62a8` (feat)
2. **Task 2: Update Quiz.jsx and ComparePanel.jsx** - `22ebfb2` (feat)

## Files Created/Modified
- `CompassV2/src/components/LibraryDrawer.jsx` - Imports parseTensionTitle; header now shows two-line tension title; QuestionText italic between title and stances
- `CompassV2/src/components/CalibrationOverlay.jsx` - Answer step: two-line tension title + centered italic QuestionText; start_phrase h2 removed
- `CompassV2/src/pages/Quiz.jsx` - Imports parseTensionTitle; both modes use two-line tension title + italic QuestionText; start_phrase h2 removed from stanceContent
- `CompassV2/src/components/ComparePanel.jsx` - Imports parseTensionTitle; dropdown shows tension title names; tension title heading + conditional QuestionText added

## Decisions Made
- Admin TopicEditor placeholder text "Where do you stand on...?" was found in `src/components/admin/TopicEditor.jsx` as a `placeholder` attribute on a form input — this is guidance text for admins entering data, not a user-facing display fallback, and was correctly left unchanged
- IIFE pattern (immediately-invoked function expression) used consistently in JSX to call `parseTensionTitle` without extracting variables outside render scope — keeps transformation co-located with output
- `stanceContent` in Quiz.jsx is shared between full and curated modes; the `start_phrase` heading was at the top of that shared block, so removing it cleans both modes simultaneously

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- The plan's verification check `grep -rn "Where do you stand" CompassV2/src/` returns one match in `src/components/admin/TopicEditor.jsx` — a `placeholder` attribute hint for admin data entry, not a user-facing fallback. This is out of scope (admin tool, not user-facing surface) and correctly left unchanged.
- CompassV2 is a separate git repo (has its own `.git` directory), not tracked by the workspace root repo. Commits were made directly to the CompassV2 repo.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All five user-facing surfaces (Library cards, calibration pick/answer, quiz, compare panel, library drawer) now show consistent topic names via `parseTensionTitle`
- Phase 18 is complete — both plans executed; tension title display standardized across the full CompassV2 frontend
- Phase 19 (calibration flow improvements) can proceed with accurate topic display as its foundation

---
*Phase: 18-title-display-frontend*
*Completed: 2026-02-21*

## Self-Check: PASSED

- FOUND: CompassV2/src/components/LibraryDrawer.jsx
- FOUND: CompassV2/src/components/CalibrationOverlay.jsx
- FOUND: CompassV2/src/pages/Quiz.jsx
- FOUND: CompassV2/src/components/ComparePanel.jsx
- FOUND: .planning/phases/18-title-display-frontend/18-02-SUMMARY.md
- FOUND commit a9b62a8: feat(18-02): update LibraryDrawer and CalibrationOverlay answer step with tension titles
- FOUND commit 22ebfb2: feat(18-02): update Quiz and ComparePanel with tension titles and QuestionText
