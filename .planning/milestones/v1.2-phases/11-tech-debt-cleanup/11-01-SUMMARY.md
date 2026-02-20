---
phase: 11-tech-debt-cleanup
plan: 01
subsystem: ui
tags: [react, vite, ev-ui, compassv2, refactor]

# Dependency graph
requires: []
provides:
  - Clean 7-line RadarChart.jsx wrapper (no dead code)
  - ev-ui dependency aligned to ^0.1.19 across CompassV2 and essentials
  - Shared getQuestionText helper in util/topic.js
  - question_text fallback consolidated to single source of truth
affects: [compass-onboarding, compassv2-ux, future-compassv2-plans]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - CompassV2/src/util/topic.js
  modified:
    - CompassV2/src/components/RadarChart.jsx
    - CompassV2/package.json
    - CompassV2/package-lock.json
    - CompassV2/src/pages/Library.jsx
    - CompassV2/src/components/ComparePanel.jsx
    - CompassV2/src/components/LibraryDrawer.jsx

key-decisions:
  - "Preserve getQuestion local alias in Library.jsx (delegates to getQuestionText) rather than doing a global rename — avoids churn in a large file"
  - "TopicEditor.jsx placeholder text left unchanged — it is a UI hint string, not the runtime fallback, and not part of this duplication"

patterns-established:
  - "util/topic.js pattern: small named-export helper modules in CompassV2/src/util/ (following util/name.js convention)"

requirements-completed:
  - DEBT-01
  - DEBT-02
  - DEBT-03

# Metrics
duration: 7min
completed: 2026-02-19
---

# Phase 11 Plan 01: Tech Debt Cleanup Summary

**RadarChart dead code removed (256 lines), ev-ui aligned to ^0.1.19, and question_text fallback consolidated into a single getQuestionText helper imported by 3 consumers**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-02-19T01:47:14Z
- **Completed:** 2026-02-19T01:54:30Z
- **Tasks:** 2
- **Files modified:** 6 (+ 1 created)

## Accomplishments
- Deleted 256 lines of commented-out SVG radar chart code from RadarChart.jsx — file is now a clean 7-line wrapper
- Updated CompassV2 ev-ui dependency from ^0.1.16 to ^0.1.19, matching the essentials project and resolving version drift
- Created `util/topic.js` with `getQuestionText` helper that handles null topic and missing question_text
- Replaced 3 independent copies of the fallback template string with imports of the shared helper
- CompassV2 builds successfully with no errors

## Task Commits

Each task was committed atomically (inside CompassV2 repo):

1. **Task 1: Remove RadarChart dead code and update ev-ui version** - `36586a0` (chore)
2. **Task 2: Consolidate question_text fallback into shared helper** - `307b855` (refactor)

**Plan metadata:** committed via workspace repo (docs)

## Files Created/Modified
- `CompassV2/src/components/RadarChart.jsx` - Reduced from 263 lines to 7; only the active RadarChartCore wrapper remains
- `CompassV2/package.json` - ev-ui version bumped from ^0.1.16 to ^0.1.19
- `CompassV2/package-lock.json` - Updated lock file after npm install
- `CompassV2/src/util/topic.js` - New shared helper: `getQuestionText(topic)` returns "" for null, question_text or template string otherwise
- `CompassV2/src/pages/Library.jsx` - Added import, replaced local arrow function with `const getQuestion = getQuestionText`
- `CompassV2/src/components/ComparePanel.jsx` - Added import, replaced inline template literal with `getQuestionText(selectedTopic)`
- `CompassV2/src/components/LibraryDrawer.jsx` - Added import, replaced 3-line ternary with `getQuestionText(topic)`

## Decisions Made
- Kept `const getQuestion = getQuestionText` alias in Library.jsx rather than renaming all call sites — preserves the file's internal naming convention without unnecessary churn
- Left `TopicEditor.jsx` unchanged — its match of "What should the government do about" is a static HTML input placeholder for admin UI, not the runtime fallback logic

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- CompassV2 is a separate git repository (`CompassV2/.git`) — the workspace root git repo cannot stage CompassV2 files directly. Task commits were made inside the CompassV2 repo using `cd CompassV2 && git add ... && git commit`. This is the correct and expected pattern for this multi-repo workspace.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CompassV2 codebase is cleaner and ready for onboarding and UX phases
- ev-ui version is now consistent across CompassV2 and essentials
- Shared `util/topic.js` pattern established for future topic-related helpers
- No blockers or concerns

## Self-Check: PASSED

- FOUND: `CompassV2/src/util/topic.js`
- FOUND: `.planning/phases/11-tech-debt-cleanup/11-01-SUMMARY.md`
- FOUND: commit `36586a0` (Task 1 — chore: remove dead code, update ev-ui)
- FOUND: commit `307b855` (Task 2 — refactor: consolidate getQuestionText helper)

---
*Phase: 11-tech-debt-cleanup*
*Completed: 2026-02-19*
