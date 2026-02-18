---
phase: 04-compass-ux-enhancements
plan: 01
subsystem: api, ui
tags: [go, gorm, react, compass, admin, topics]

# Dependency graph
requires: []
provides:
  - "compass.topics table with question_text (TEXT) and level (VARCHAR) columns via GORM AutoMigrate"
  - "PATCH /compass/topics/update accepts question_text and level fields"
  - "GET /compass/topics response includes question_text and level for each topic"
  - "Admin TopicEditor has question textarea and level dropdown"
affects: [04-02, 04-03, 04-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "New fields on PATCH endpoint use snake_case JSON keys, legacy fields keep PascalCase for backward compat"
    - "Pointer types (*string) in topicRequest struct distinguish omitted fields from empty strings"

key-files:
  created: []
  modified:
    - EV-Backend/internal/compass/models.go
    - EV-Backend/internal/compass/handlers.go
    - CompassV2/src/components/admin/TopicEditor.jsx
    - CompassV2/src/components/admin/TopicAccordion.jsx

key-decisions:
  - "New PATCH fields (question_text, level) use snake_case JSON tags; existing fields (Title, ShortTitle) keep PascalCase for backward compatibility"
  - "QuestionText and Level use empty string zero-value (not nullable pointer) in Topic struct — GORM stores empty strings, omitempty suppresses from JSON when blank"
  - "TopicAccordion handleEditClick explicitly initializes question_text and level from topic data to ensure editedFields is complete"

patterns-established:
  - "Question text field: allows admin to override the topic title displayed on quiz cards"
  - "Level field: federal/state/local classification stored per topic for future filter/display logic"

requirements-completed: [QUIZ-01, QUIZ-09]

# Metrics
duration: 2min
completed: 2026-02-18
---

# Phase 4 Plan 01: Topic Question Text and Level Fields Summary

**Added question_text and level columns to compass.topics with PATCH endpoint support and admin UI controls for both fields.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-18T01:32:21Z
- **Completed:** 2026-02-18T01:34:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Extended Topic GORM model with QuestionText and Level fields (omitempty JSON, GORM AutoMigrate handles schema)
- Extended TopicUpdateHandler to accept question_text and level via pointer-typed request struct fields
- Added Question textarea (rows=2) and Level dropdown (federal/state/local) to admin TopicEditor form
- Updated TopicAccordion handleEditClick to seed question_text and level into editedFields from topic data

## Task Commits

Each task was committed atomically:

1. **Task 1: Add QuestionText and Level to Topic model and handler** - `a40a8b7` (feat) — EV-Backend repo
2. **Task 2: Add question textarea and level dropdown to TopicEditor** - `8062c3e` (feat) — CompassV2 repo

**Plan metadata:** (workspace repo commit below)

## Files Created/Modified
- `EV-Backend/internal/compass/models.go` - Added QuestionText and Level fields to Topic struct
- `EV-Backend/internal/compass/handlers.go` - Extended topicRequest and updates map with question_text and level
- `CompassV2/src/components/admin/TopicEditor.jsx` - Added question textarea, level dropdown, and updated handleSave payload
- `CompassV2/src/components/admin/TopicAccordion.jsx` - Updated handleEditClick to initialize question_text and level fields

## Decisions Made
- New PATCH fields use snake_case JSON tags while existing fields (Title, ShortTitle) retain PascalCase — preserves backward compatibility with any existing callers
- Topic struct uses empty string zero-value (not *string pointer) — GORM serializes all fields, `omitempty` suppresses from JSON only when blank, AutoMigrate creates columns as nullable TEXT/VARCHAR
- TopicAccordion handleEditClick explicitly sets `question_text: topic.question_text || ""` and `level: topic.level || ""` to ensure the fields round-trip correctly even when the API returns null/undefined for existing topics

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added question_text and level initialization in TopicAccordion**
- **Found during:** Task 2 (TopicEditor UI)
- **Issue:** Plan noted the parent component may need updating if it explicitly picks fields — confirmed TopicAccordion explicitly lists fields in handleEditClick and did not include question_text or level
- **Fix:** Added `question_text: topic.question_text || ""` and `level: topic.level || ""` to the setEditedFields call in handleEditClick
- **Files modified:** CompassV2/src/components/admin/TopicAccordion.jsx
- **Verification:** Fields present in grep output; CompassV2 build passes
- **Committed in:** 8062c3e (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 — missing initialization; plan anticipated this case)
**Impact on plan:** Fix is exactly what the plan prescribed as a conditional action. No scope creep.

## Issues Encountered
- The workspace git repo only tracks `.planning/` files; EV-Backend and CompassV2 are separate git repos. Committed task changes to their respective repos (EV-Backend and CompassV2) rather than the workspace repo.

## User Setup Required
None — GORM AutoMigrate adds `question_text` and `level` columns automatically on next server start. No manual migration needed.

## Next Phase Readiness
- Backend columns and API support are live; frontend plans (04-02 through 04-04) can use question_text and level fields immediately
- GET /compass/topics already returns both fields (GORM serializes all struct fields); no additional backend work needed for read path
- Admin can begin setting question text and level per topic via the editor

---
*Phase: 04-compass-ux-enhancements*
*Completed: 2026-02-18*
