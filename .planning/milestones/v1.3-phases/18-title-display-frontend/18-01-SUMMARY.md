---
phase: 18-title-display-frontend
plan: 01
subsystem: ui
tags: [react, tailwind, compass, topic-display, tension-title]

# Dependency graph
requires:
  - phase: 17-title-standardization-backend
    provides: canonical tension titles in "Topic: Pole A — Pole B" format stored in DB
provides:
  - parseTensionTitle helper that splits tension title at colon into { name, poles }
  - Two-line tension title layout on Library topic cards (name on line 1, poles on line 2)
  - Two-line tension title layout on calibration pick-step cards (identical layout)
  - getQuestionText fallback cleaned — no more "Where do you stand on..." prefix
affects:
  - 18-02-PLAN.md (quiz answer step tension title display)
  - 19-calibration-flow (calibration UX improvements depend on topic name display)

# Tech tracking
tech-stack:
  added: []
  patterns: [two-line tension title layout with topic name as primary read and poles as muted supporting context]

key-files:
  created: []
  modified:
    - CompassV2/src/util/topic.js
    - CompassV2/src/pages/Library.jsx
    - CompassV2/src/components/CalibrationOverlay.jsx

key-decisions:
  - "parseTensionTitle splits at first colon only — topic name is everything before the colon, poles is everything after (trimmed)"
  - "getQuestionText fallback removed entirely — returns empty string rather than prohibited prefix; Phase 17 made server data canonical so fallback should never fire"
  - "Poles line uses text-xs text-gray-500 font-normal — smaller and muted to make topic name the primary read"
  - "Library and calibration pick cards use identical two-line layout per user decision"
  - "IIFE pattern (immediately-invoked function expression) used inline in JSX to call parseTensionTitle without extracting to a separate variable outside the map"

patterns-established:
  - "Two-line tension title: <p className='text-sm md:text-base font-medium leading-snug'>{name}</p> + {poles && <p className='text-xs text-gray-500 font-normal mt-0.5'>{poles}</p>}"
  - "parseTensionTitle returns { name, poles } — poles is null when no colon present, allowing conditional rendering"

requirements-completed: [TITLE-02, TITLE-03]

# Metrics
duration: 2min
completed: 2026-02-21
---

# Phase 18 Plan 01: Title Display Frontend Summary

**parseTensionTitle helper splits tension titles into two-line layout — topic name on line 1, poles on line 2 — on Library cards and calibration pick-step cards; getQuestionText "Where do you stand on" fallback removed**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-21T04:13:59Z
- **Completed:** 2026-02-21T04:15:16Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added `parseTensionTitle(topic)` to `topic.js` — splits `topic.title` at first colon into `{ name, poles }`, falls back to `short_title` when no colon present
- Cleaned `getQuestionText` — removed "Where do you stand on..." fallback, now returns `topic.question_text || ""`
- Updated Library topic cards to display topic name on line 1 and poles on line 2 in muted text (`text-xs text-gray-500 font-normal`)
- Updated calibration pick-step cards with identical two-line layout, replacing `getQuestionText` call
- Updated Library search filter to also search `topic.title` so full tension titles are searchable
- Removed `const getQuestion = getQuestionText` alias from Library.jsx (no longer needed)
- Verified: build succeeds, no "Where do you stand on..." prefix in any user-facing surface

## Task Commits

Each task was committed atomically in the CompassV2 repo:

1. **Task 1: Add parseTensionTitle helper and clean getQuestionText fallback** - `a82049c` (feat)
2. **Task 2: Update Library cards and Calibration pick step with two-line tension title** - `9131364` (feat)

## Files Created/Modified
- `CompassV2/src/util/topic.js` - Added `parseTensionTitle` export; removed "Where do you stand" fallback from `getQuestionText`
- `CompassV2/src/pages/Library.jsx` - Imports `parseTensionTitle`; two-line layout on topic cards; updated search filter; removed alias
- `CompassV2/src/components/CalibrationOverlay.jsx` - Imports `parseTensionTitle`; two-line layout on pick-step cards

## Decisions Made
- Used an IIFE pattern inline in JSX to call `parseTensionTitle` without needing to extract to a variable outside the `.map()` callback — keeps the transformation co-located with the render
- `getQuestionText` is still imported in both files (used in other contexts like the answer step title in CalibrationOverlay) — only the pick-step card text was replaced in this plan

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- CompassV2 is a separate git repo (has its own `.git` directory), not tracked by the workspace root repo. Commits were made to the CompassV2 repo directly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `parseTensionTitle` is ready for use by Phase 18 Plan 02 (quiz answer step) — same import pattern, same `{ name, poles }` return shape
- Library and calibration pick cards are updated; answer step still shows `getQuestionText` output (addressed in 18-02)

---
*Phase: 18-title-display-frontend*
*Completed: 2026-02-21*

## Self-Check: PASSED

- FOUND: CompassV2/src/util/topic.js
- FOUND: CompassV2/src/pages/Library.jsx
- FOUND: CompassV2/src/components/CalibrationOverlay.jsx
- FOUND: .planning/phases/18-title-display-frontend/18-01-SUMMARY.md
- FOUND commit a82049c: feat(18-01): add parseTensionTitle helper and clean getQuestionText fallback
- FOUND commit 9131364: feat(18-01): update Library and calibration pick step with two-line tension title layout
