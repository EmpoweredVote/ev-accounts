---
phase: 13-topic-selection-enforcement
plan: 01
subsystem: ui
tags: [react, compass, library, topic-selection, ux]

# Dependency graph
requires:
  - phase: 12-quick-ux-fixes
    provides: Library.jsx with showAll toggle, CompassContext with selectedTopics/setSelectedTopics
provides:
  - Library page counter badge showing X/8 selected topics
  - On-compass card visual indicator (ev-light-blue border)
  - Add/remove toggle buttons on each Library card
  - Confirmation popover before topic removal
  - Below-3 topic warning in removal popover
  - 8-topic cap enforced via disabled add button
affects: [13-02-PLAN.md, quiz-flow]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inline popover with removeConfirm state for lightweight confirmation UX"
    - "stopPropagation on nested action buttons inside card containers"
    - "Reactive counter badge from context state (no extra state needed)"

key-files:
  created: []
  modified:
    - CompassV2/src/pages/Library.jsx

key-decisions:
  - "Tasks 1 and 2 committed together (single file, naturally cohesive implementation)"
  - "Popover dismissal on card click: if removeConfirm is open, card click closes it (not open drawer) — prevents accidental drawer open while confirming"
  - "wouldDropBelow3 check uses <= 3 (current count), since removing drops it by 1"

patterns-established:
  - "removeConfirm: null | topic.id pattern for single-active-popover UX"
  - "isOnCompass derived inline per card from selectedTopics.includes(topic.id)"

requirements-completed: [TSEL-01, TSEL-03]

# Metrics
duration: 2min
completed: 2026-02-19
---

# Phase 13 Plan 01: Topic Selection Enforcement — Library Indicators Summary

**Library page updated with X/8 counter badge, ev-light-blue card borders for on-compass topics, and add/remove toggle buttons with confirmation popover for topic removal**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-19T03:39:37Z
- **Completed:** 2026-02-19T03:41:03Z
- **Tasks:** 2 (implemented together in one commit)
- **Files modified:** 1

## Accomplishments
- Counter badge "X/8" added inline with the "Or, pick your own topics" heading — live-updates as topics are added/removed
- On-compass cards display ev-light-blue (#59b0c4) border with subtle sky-50/50 background tint; off-compass cards unchanged
- Toggle button on each card: "+" (gray) when not on compass, "X" (blue) when on compass
- Add button disabled and grayed when selectedTopics.length >= 8 (max cap enforced without toast)
- Confirmation popover with "Remove from compass?" + Yes/Cancel appears before any removal
- Below-3 topic amber warning text in popover when removing would drop count under 3
- Removal only removes from selectedTopics — answers and answeredTopicIDs preserved

## Task Commits

Each task was committed atomically (Tasks 1 and 2 combined as single cohesive change):

1. **Tasks 1 + 2: Counter badge, card indicators, add/remove toggle, confirmation popover** - `df788bc` (feat)

**Plan metadata:** committed below (docs)

## Files Created/Modified
- `CompassV2/src/pages/Library.jsx` - Counter badge, on-compass border logic, toggle buttons, confirmation popover with below-3 warning

## Decisions Made
- Tasks 1 and 2 implemented and committed together — both operate on the same file with no natural seam between them; splitting would be artificial
- Card click while popover is open: dismisses popover without opening drawer (prevents misclick-to-drawer scenario)
- `wouldDropBelow3` check uses `selectedTopics.length <= 3` (current count before removal) — if length is 3, removing drops to 2 which is below the 3-topic minimum

## Deviations from Plan

None — plan executed exactly as written. Both tasks implemented exactly per spec.

## Issues Encountered

CompassV2 has its own nested git repository (separate from the workspace root). Committed within `CompassV2/` git context rather than the parent workspace.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness
- Library card UX complete — ready for Phase 13 Plan 02 (quiz flow topic enforcement and max-8 cap in Quiz page)
- selectedTopics sync to server already handled in CompassContext — no backend changes needed for this plan

## Self-Check: PASSED

- Library.jsx: FOUND
- 13-01-SUMMARY.md: FOUND
- Commit df788bc: FOUND

---
*Phase: 13-topic-selection-enforcement*
*Completed: 2026-02-19*
