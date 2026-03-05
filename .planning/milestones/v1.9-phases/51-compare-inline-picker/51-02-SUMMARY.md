---
phase: 51-compare-inline-picker
plan: "02"
subsystem: ui
tags: [react, compass, compare, inline-picker, radar-chart]

# Dependency graph
requires:
  - phase: 51-compare-inline-picker
    provides: InlinePoliticianPicker component and usePoliticianList hook (Plan A)
provides:
  - ComparePanel header replaced with InlinePoliticianPicker (searchable dropdown trigger)
  - handleSwitchPolitician: sets comparePol without clearing compareAnswers (preserves old radar polygon during fetch)
  - handleClearComparison: clears comparePol and compareAnswers, returns to empty prompt state
  - handleOpenFullModal: re-opens CompareModal from within the inline picker
  - Legend blue-swatch click uses handleClearComparison (centralized)
  - Both desktop and mobile ComparePanel usages wired with all three callbacks
affects:
  - future compare UX phases
  - any phase touching ComparePanel or Compass.jsx

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inline switching pattern: setComparePol without setCompareAnswers({}) keeps old radar polygon visible during API fetch, morph happens when new data arrives via react-spring"
    - "Centralized clear handler: handleClearComparison used by both Legend swatch and InlinePoliticianPicker onClear prop"

key-files:
  created: []
  modified:
    - CompassV2/src/components/ComparePanel.jsx
    - CompassV2/src/pages/Compass.jsx

key-decisions:
  - "Do NOT clear compareAnswers when switching politicians — keeps old polygon visible on radar chart until new data arrives, enabling smooth react-spring morph animation"
  - "handleSwitchPolitician only calls setComparePol(newPol); existing useEffect handles fetch and setCompareAnswers replacement"
  - "dropdownValue (topic selection) intentionally not reset on politician switch — user stays on same topic, sees new politician's stance"

patterns-established:
  - "Keep-old-data-visible pattern: setComparePol triggers re-fetch via useEffect, old compareAnswers remain until fetch resolves"

requirements-completed: [COMP-01]

# Metrics
duration: 2min
completed: 2026-02-28
---

# Phase 51 Plan 02: Integrate Inline Picker into Compare Flow Summary

**InlinePoliticianPicker wired into ComparePanel header with smooth morph switching — old radar polygon stays visible during fetch, topic selection preserved across politician switches**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-28T15:35:43Z
- **Completed:** 2026-02-28T15:37:43Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Replaced the static photo/name header in ComparePanel with InlinePoliticianPicker (searchable dropdown, keyboard nav, clear, browse-all)
- Added three callbacks in Compass.jsx: handleSwitchPolitician (no answer clear), handleClearComparison, handleOpenFullModal
- Wired callbacks to both desktop and mobile ComparePanel usages
- Legend blue-swatch click consolidated to use handleClearComparison (no inline duplication)
- Build passes cleanly (575 kB bundle, 4.39s)

## Task Commits

Each task was committed atomically:

1. **Task B1: Replace ComparePanel header with InlinePoliticianPicker** - `ca928e1` (feat)
2. **Task B2: Wire switching logic in Compass.jsx** - `7b0d476` (feat)

**Plan metadata:** (final commit below)

## Files Created/Modified
- `CompassV2/src/components/ComparePanel.jsx` - Added onSwitchPolitician/onClearComparison/onOpenFullModal props; replaced static header with InlinePoliticianPicker; removed unused placeholder/normalizeOfficeTitle imports
- `CompassV2/src/pages/Compass.jsx` - Added three switching callbacks after comparePol state; updated Legend onClick; passed callbacks to both desktop and mobile ComparePanel usages

## Decisions Made
- handleSwitchPolitician intentionally does not call setCompareAnswers({}) — this is the key behavior that keeps the old radar polygon visible during the API fetch for the new politician's answers. The existing useEffect (line ~530) handles the fetch and replacement, which triggers react-spring's morph animation.
- dropdownValue (topic selection) is never reset during politician switching — user stays on the same topic and sees the new politician's stance on it immediately when data arrives.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The existing useEffect pattern already supported "keep old polygon" behavior — it only clears compareAnswers when comparePol becomes null, not when switching between politicians.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Full compare inline picker flow is complete: initial selection via CompareModal, subsequent switching via InlinePoliticianPicker, clearing returns to "Select a politician" prompt
- Phase 51 (Compare Inline Picker) is complete — both Plan A and Plan B delivered
- Next: Phase 52 (Search Fixes) or Phase 53 per ROADMAP

## Self-Check: PASSED

- CompassV2/src/components/ComparePanel.jsx: FOUND
- CompassV2/src/pages/Compass.jsx: FOUND
- .planning/phases/51-compare-inline-picker/51-02-SUMMARY.md: FOUND
- Commit ca928e1 (Task B1): FOUND
- Commit 7b0d476 (Task B2): FOUND

---
*Phase: 51-compare-inline-picker*
*Completed: 2026-02-28*
