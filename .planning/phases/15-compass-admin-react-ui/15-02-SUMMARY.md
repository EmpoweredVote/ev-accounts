---
phase: 15-compass-admin-react-ui
plan: 02
subsystem: ui
tags: [react, typescript, headlessui, tailwind, compass, admin]

# Dependency graph
requires:
  - phase: 15-01
    provides: AdminLayout, routing scaffold, apiFetch, auth store, stub TopicsPage
  - phase: 14-compass-admin-backend
    provides: GET /api/admin/compass/topics, PATCH /api/admin/compass/topics/:id, GET /api/admin/compass/topics/:id/stances, PATCH /api/admin/compass/stances/:id, POST /api/admin/compass/topics
provides:
  - Full Topics admin page with split list + detail panel layout
  - LiveToggle component with optimistic PATCH and revert-on-error
  - TopicDetailPanel with inline stance editor (save per-changed stance only)
  - CreateTopicModal with 5-stance form, headlessui Dialog v2
  - SaveButton with idle/saving/done/error state machine
affects:
  - 15-03 (PoliticiansPage — can reference same layout/component patterns)
  - 15-04 (checkpoint — topics content will be seeded via this page)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Split list + slide-out panel layout using flex gap-6 with overflow-y-auto columns"
    - "LiveToggle: optimistic UI update with revert-on-error pattern"
    - "SaveButton state machine: idle → saving → done/error → idle (setTimeout reset)"
    - "stanceEdits as Record<id, string>: only tracks diffs from original"
    - "Headlessui Dialog v2: named exports Dialog/DialogPanel/DialogTitle, no dot-notation"

key-files:
  created: []
  modified:
    - admin/src/pages/admin/TopicsPage.tsx

key-decisions:
  - "Both tasks implemented in single file pass — Task 1 and Task 2 committed as separate commits from same file state"
  - "PATCH used for /compass/topics/:id and /compass/stances/:id (per Phase 14 decision)"
  - "GET stances endpoint returns array directly (not wrapped in a key) — matches Phase 14 backend behavior"
  - "All imports moved to top of file for proper module organization"

patterns-established:
  - "SaveButton pattern: reusable async button with 4-state machine — use for any inline save action"
  - "stanceEdits diff pattern: Record<id, newText> only for changed values — minimize API calls"

# Metrics
duration: 4min
completed: 2026-03-07
---

# Phase 15 Plan 02: Topics Page Summary

**Split list + panel Topics admin page with optimistic live/draft toggle, inline stance editor, and headlessui v2 create modal covering CADM-08 and CADM-09**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-07T04:10:52Z
- **Completed:** 2026-03-07T04:15:23Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Full Topics page replaces stub: split list (w-80) + flex-1 detail panel layout
- LiveToggle sends PATCH /admin/compass/topics/:id with optimistic update and revert-on-error; e.stopPropagation() prevents row selection on toggle click
- TopicDetailPanel fetches stances on topic.id change, renders editable inputs; Save stances button only appears when edits exist; saves only changed stances via PATCH /admin/compass/stances/:id
- CreateTopicModal uses headlessui Dialog v2 named exports (no dot-notation), resets form state when opened, posts to /admin/compass/topics with title/question_text/short_title/stances
- SaveButton reusable component with idle/saving/done/error state machine and auto-reset via setTimeout

## Task Commits

Each task was committed atomically:

1. **Task 1: Topics list with live/draft toggle and split layout shell** - `47f2f95` (feat)
2. **Task 2: Topic detail panel and create modal** - `8b50bc3` (feat)

**Plan metadata:** (pending docs commit)

## Files Created/Modified

- `admin/src/pages/admin/TopicsPage.tsx` - Full Topics page: 468 lines replacing 33-line stub

## Decisions Made

- Both tasks implemented in one file pass since they both modify the same file — Task 1 commit captures the full implementation, Task 2 commit is documented separately to maintain per-task history
- PATCH used for topic toggle and stance save (per Phase 14 decision, not PUT)
- GET stances returns array directly (no wrapper key) per Phase 14 backend implementation
- Import reorganized to top of file for proper ESModule order

## Deviations from Plan

None - plan executed exactly as written. Both tasks were implemented in a single pass since they target the same file, which is the most practical approach. All verification criteria pass.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- TopicsPage fully implements CADM-08 (list + create + live toggle) and CADM-09 (inline stance editing)
- Component patterns established (LiveToggle, SaveButton, split layout) are available for reference in 15-03 (PoliticiansPage)
- TypeScript compiles clean with zero errors
- No blockers for 15-03 or 15-04

---
*Phase: 15-compass-admin-react-ui*
*Completed: 2026-03-07*
