---
phase: 04-compass-ux-enhancements
plan: "03"
subsystem: ui
tags: [react, jsx, compass, library, compare-panel, question-text, level-badges]

# Dependency graph
requires:
  - phase: 04-01
    provides: question_text and level fields on compass.topics API and admin UI
provides:
  - Library.jsx renders question text as primary card label with auto-generated fallback
  - Library.jsx shows federal/state/local level badges at card bottom
  - Library.jsx search also matches question_text content
  - ComparePanel.jsx shows question header above stance list when topic selected
affects: [04-04, any future Library or ComparePanel work]

# Tech tracking
tech-stack:
  added: []
  patterns: [getQuestion helper with fallback pattern for question_text, LEVEL_CONFIG icon registry pattern]

key-files:
  created: []
  modified:
    - CompassV2/src/pages/Library.jsx
    - CompassV2/src/components/ComparePanel.jsx

key-decisions:
  - "getQuestion helper defined at module level (not inside component) — pure function, stable reference, no re-creation on render"
  - "LEVEL_CONFIG uses inline SVG elements (not img/emoji) — consistent with EV design system color control and sizing"
  - "Category sub-label removed from cards — category heading above grid already provides context, sub-label was redundant"

patterns-established:
  - "getQuestion(topic): canonical pattern for resolving question text with auto-generated fallback across all components"
  - "LEVEL_CONFIG registry: icon + label keyed by level string for level badge rendering"

requirements-completed: [QUIZ-01, QUIZ-02, QUIZ-09]

# Metrics
duration: 2min
completed: 2026-02-18
---

# Phase 4 Plan 03: Library Question Text and Level Badges Summary

**Library cards now display question prompts as primary text with federal/state/local badges; ComparePanel shows question header above stance columns**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-18T01:36:35Z
- **Completed:** 2026-02-18T01:38:17Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Library issue cards display `question_text` (or auto-generated fallback) as the primary label instead of bare `short_title`
- Level badges with icons (federal/state/local) appear at card bottom; cards with no level set show nothing
- Search filter now matches against `question_text` in addition to `short_title`
- ComparePanel renders the question text as a bold header above the legend and stance list when a topic is selected

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace card titles with question text and add level badges in Library.jsx** - `52b0fb0` (feat)
2. **Task 2: Add question header in ComparePanel above stance list** - `6e3b2a2` (feat)

## Files Created/Modified
- `CompassV2/src/pages/Library.jsx` - Added LEVEL_CONFIG constant, getQuestion helper, replaced card primary text, replaced category sub-label with conditional level badge, extended search filter
- `CompassV2/src/components/ComparePanel.jsx` - Added question header `<p>` before legend div inside topicSelected block

## Decisions Made
- `getQuestion` defined at module scope rather than inside the component — it's a pure function with no closure over component state, so module-level definition is cleaner and avoids re-creation on each render
- LEVEL_CONFIG uses inline SVG paths rather than emoji or image assets for consistent color control and sizing via Tailwind
- The category sub-label (`category.title` below each card title) was removed since the `<h3>` category heading above each card grid already provides that context — removing it reduces visual noise and gives the level badge a clean footer slot

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- CompassV2 is its own nested git repository within the workspace. Initial `git add` targeted the workspace root repo (which sees CompassV2 as untracked). Resolved by using `git -C /path/to/CompassV2` for all commits. No code changes required.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- QUIZ-01, QUIZ-02, QUIZ-09 requirements fully satisfied
- Library and ComparePanel are ready for Plan 04 (any remaining UX enhancements in phase 04)
- The `getQuestion` helper pattern is established and can be reused in Quiz.jsx or any future component that needs to display topic questions

---
*Phase: 04-compass-ux-enhancements*
*Completed: 2026-02-18*

## Self-Check: PASSED

- FOUND: CompassV2/src/pages/Library.jsx
- FOUND: CompassV2/src/components/ComparePanel.jsx
- FOUND: .planning/phases/04-compass-ux-enhancements/04-03-SUMMARY.md
- FOUND: commit 52b0fb0 (Task 1)
- FOUND: commit 6e3b2a2 (Task 2)
