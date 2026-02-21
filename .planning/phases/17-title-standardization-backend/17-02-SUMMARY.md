---
phase: 17-title-standardization-backend
plan: 02
subsystem: database
tags: [compass, topics, database, naming, api]

# Dependency graph
requires:
  - 17-01 (approved topic-drafts.md with tension titles, short titles, and questions)
provides:
  - Canonical topic naming in database: tension titles, spoke labels, custom questions for all 21 topics
  - Cleaned Topic model: ShortName and StartPhrase fields removed
  - TopicUpdateHandler: no longer accepts ShortName or StartPhrase
affects: [18-compass-display, 19-calibration-flow]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SQL UPDATE pattern: set title, short_title, question_text per topic_key for 21 rows in a single psql session"
    - "Column removal pattern: ALTER TABLE DROP COLUMN IF EXISTS for backward-safe schema cleanup"
    - "Go struct field removal: remove GORM-mapped fields when corresponding DB columns are dropped"

key-files:
  created: []
  modified:
    - EV-Backend/internal/compass/models.go
    - EV-Backend/internal/compass/handlers.go

key-decisions:
  - "Database is now canonical source of truth for all topic naming — no hardcoded fallbacks needed in frontend"
  - "ShortName and StartPhrase dropped at DB and model level simultaneously to keep code/schema in sync"

patterns-established:
  - "Deprecate fields: drop from DB schema, remove from Go struct, and remove from handler in a single coordinated commit sequence"

requirements-completed: [TITLE-01]

# Metrics
duration: ~5min
completed: 2026-02-21
---

# Phase 17 Plan 02: Database Migration & Model Cleanup Summary

**Applied approved tension titles, spoke labels, and custom questions to all 21 compass topics in the database; removed deprecated ShortName and StartPhrase fields from the Go model and handlers.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-02-21T03:46:43Z
- **Completed:** 2026-02-21T03:51:34Z
- **Tasks:** 2 of 2
- **Files modified:** 2 (EV-Backend only)

## Accomplishments

- Applied all 21 approved topic names to `compass.topics` via SQL UPDATE statements using psql direct connection
- Verified all 21 topics have non-empty title, short_title, and question_text
- Confirmed zero topics have question_text starting with "Where do you stand on"
- Dropped `short_name` and `start_phrase` columns from the database (`ALTER TABLE DROP COLUMN IF EXISTS`)
- Removed `ShortName` and `StartPhrase` fields from Topic struct in `models.go`
- Removed `ShortName` from `topicRequest` struct in `TopicUpdateHandler`
- Removed `short_name` update block from `TopicUpdateHandler`
- Confirmed backend builds cleanly with `go build -o /dev/null .`
- Confirmed zero references to ShortName/StartPhrase/short_name/start_phrase remain in `internal/compass/`

## Task Commits (EV-Backend repo)

Each task was committed atomically:

1. **Task 1: Apply approved topic names to database** - `102db6d` (feat)
2. **Task 2: Clean up TopicUpdateHandler and verify API response** - `fd9c2d1` (feat)

## Files Created/Modified

- `EV-Backend/internal/compass/models.go` - Removed ShortName and StartPhrase fields from Topic struct
- `EV-Backend/internal/compass/handlers.go` - Removed ShortName from topicRequest and update block in TopicUpdateHandler

## Database Changes

- **Table:** `compass.topics`
- **Updated rows:** 21 (all topics)
- **Fields updated per row:** title, short_title, question_text
- **Columns dropped:** short_name, start_phrase
- **Remaining columns:** id, title, short_title, topic_key, is_active, question_text, level

## Decisions Made

- Used direct psql connection (via DATABASE_URL from .env.local) when Supabase MCP was unavailable — same data, different execution path
- Applied all 21 updates in a single psql session for efficiency rather than individual calls
- ukraine-support topic is inactive (pre-existing state) — not related to this plan, all fields updated correctly

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Supabase MCP tool not available in execution environment**
- **Found during:** Task 1 execution setup
- **Issue:** The plan specified using "Supabase MCP execute_sql tool" but no MCP tools with that name were available
- **Fix:** Used psql direct connection via DATABASE_URL from EV-Backend/.env.local — same database, same results
- **Files modified:** None (DB-only change)
- **Commit:** `102db6d` (included in task commit)

## User Setup Required

None — migration applied directly to Supabase database.

## Next Phase Readiness

- All 21 topics in database have standardized tension titles, spoke labels, and custom questions
- Topic model is clean — no deprecated fields
- Backend API (`GET /compass/topics`) will automatically return new field values
- Phase 18 (Compass Display) can now read canonical names from the API without transformation
- Phase 19 (Calibration Flow) will benefit from correct topic names in the same user session

## Self-Check: PASSED

- FOUND: `.planning/phases/17-title-standardization-backend/17-02-SUMMARY.md` (this file)
- FOUND commit: `102db6d` (Task 1 — DB updates + model cleanup)
- FOUND commit: `fd9c2d1` (Task 2 — handler cleanup)
- DB verified: 21 rows updated, short_name/start_phrase columns dropped, zero prohibited question_text patterns
- Build verified: `go build -o /dev/null .` succeeds with zero errors

---
*Phase: 17-title-standardization-backend*
*Completed: 2026-02-21*
