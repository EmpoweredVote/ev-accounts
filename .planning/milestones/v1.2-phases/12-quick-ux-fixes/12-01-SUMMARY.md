---
phase: 12-quick-ux-fixes
plan: 01
subsystem: ui
tags: [react, go, compass, library, quiz, topic-editor, gorm]

# Dependency graph
requires:
  - phase: 11-tech-debt-cleanup
    provides: getQuestionText helper in util/topic.js established as shared framing source
provides:
  - short_name field on Topic model (backend + PATCH handler)
  - Updated question framing "Where do you stand on [topic]?" across all surfaces
  - Library toggle switch defaulting to "All" topics (replaces checkbox filter)
  - Quiz.jsx uses shared getQuestionText helper instead of inline fallback
  - TopicEditor Radar Chart Label input wired to short_name field
affects:
  - 12-02 (further UX fixes may depend on Library/Quiz framing changes)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Toggle switch UI pattern: bg-gray-300 (inactive) / bg-[#00657c] (active), translate-x-1 / translate-x-6 for knob"
    - "Shared getQuestionText helper is the canonical source of question framing across all surfaces"

key-files:
  created: []
  modified:
    - EV-Backend/internal/compass/models.go
    - EV-Backend/internal/compass/handlers.go
    - CompassV2/src/util/topic.js
    - CompassV2/src/pages/Library.jsx
    - CompassV2/src/pages/Quiz.jsx
    - CompassV2/src/components/admin/TopicEditor.jsx
    - CompassV2/src/components/admin/TopicAccordion.jsx

key-decisions:
  - "short_name has no uniqueIndex constraint — multiple topics could share a radar label, which is acceptable"
  - "Library toggle defaults to showAll=true (All view), with Unanswered as opt-in (inverted from previous hideAnswered=true default)"
  - "TopicAccordion.handleEditClick initializes short_name from topic data so existing values appear in the editor"

patterns-established:
  - "Toggle switch pattern: gray track when default state, ev-muted-blue (#00657c) when filter active, knob slides with translate-x-1/6"

requirements-completed: [LIBR-01, QFRM-01]

# Metrics
duration: 3min
completed: 2026-02-19
---

# Phase 12 Plan 01: Quick UX Fixes — Framing, Library Filter, Short Name Summary

**Short_name backend field, "Where do you stand on" framing across all compass surfaces, and Library toggle switch defaulting to All topics**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-19T02:46:57Z
- **Completed:** 2026-02-19T02:50:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added `short_name` field to Go `Topic` struct and `TopicUpdateHandler` — allows radar chart label independent of short_title
- Updated `getQuestionText` fallback from "What should the government do about..." to "Where do you stand on [topic]?" — now consistent across Library cards, LibraryDrawer, ComparePanel, and Quiz
- Replaced Library checkbox ("Unanswered only") with toggle switch defaulting to "All", using ev-muted-blue accent when Unanswered is active
- Quiz.jsx now imports and uses shared `getQuestionText` helper in both full and curated mode question headings
- TopicEditor gains a "Radar Chart Label" input field for `short_name`, wired to PATCH body and optimistic state update

## Task Commits

Each task was committed atomically (each into its own project repo):

1. **Task 1: Add short_name field to backend Topic model and update PATCH handler** - `06f03ba` (feat) — EV-Backend repo
2. **Task 2: Update question framing, Library toggle switch, and TopicEditor** - `a120a3a` (feat) — CompassV2 repo

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `EV-Backend/internal/compass/models.go` - Added `ShortName string` field with `json:"short_name,omitempty"` to Topic struct
- `EV-Backend/internal/compass/handlers.go` - Added `ShortName *string` to topicRequest struct and conditional update block
- `CompassV2/src/util/topic.js` - Changed fallback from "What should the government do about" to "Where do you stand on"
- `CompassV2/src/pages/Library.jsx` - Renamed state to `showAll` (default true), replaced checkbox with toggle switch
- `CompassV2/src/pages/Quiz.jsx` - Added `getQuestionText` import, replaced inline `question_text || title` in both layouts
- `CompassV2/src/components/admin/TopicEditor.jsx` - Added short_name input (Radar Chart Label), updated PATCH body and optimistic state, updated placeholder text
- `CompassV2/src/components/admin/TopicAccordion.jsx` - Added `short_name` initialization from topic in `handleEditClick`

## Decisions Made
- `short_name` has no uniqueIndex constraint — multiple topics could theoretically share a radar label, which is acceptable (plan specified explicitly)
- Library defaults to `showAll=true` (inverted from previous `hideAnswered=true`) — users see all topics on first visit, can opt-in to Unanswered filter
- TopicAccordion initializes `short_name` from topic data on edit click so existing values are pre-populated in the editor

## Deviations from Plan

None - plan executed exactly as written. TopicAccordion.jsx was updated alongside TopicEditor.jsx as directed by the plan (step 5 note about handleEditClick).

## Issues Encountered

The workspace root git repo (`/Users/chrisandrews/Documents/GitHub`) does not track subdirectory files — each project (EV-Backend, CompassV2) has its own `.git` repo. Commits were made into the project-level repos as appropriate.

## User Setup Required

None - no external service configuration required. The `short_name` column will be auto-migrated by GORM AutoMigrate on next server startup.

## Next Phase Readiness
- Framing changes are live — all compass surfaces now say "Where do you stand on [topic]?"
- Library filter is in correct default state for users discovering the page
- short_name ready for admin use; RadarChart currently uses short_title — a future plan can wire short_name into RadarChartCore labels
- Ready for Plan 02 of Phase 12

## Self-Check: PASSED

- CompassV2/src/util/topic.js — FOUND
- CompassV2/src/pages/Library.jsx — FOUND
- EV-Backend/internal/compass/models.go — FOUND
- .planning/phases/12-quick-ux-fixes/12-01-SUMMARY.md — FOUND
- Commit 06f03ba (EV-Backend) — FOUND
- Commit a120a3a (CompassV2) — FOUND

---
*Phase: 12-quick-ux-fixes*
*Completed: 2026-02-19*
