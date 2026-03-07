---
phase: 14-compass-admin-backend
plan: 02
subsystem: api
tags: [typescript, supabase, rpc, admin, compass, inform-schema, postgres]

# Dependency graph
requires:
  - phase: 14-01
    provides: admin_create_topic_with_stances RPC, admin_assign_topic_categories RPC, admin_list_politicians RPC (with is_candidate)
  - phase: 4-compass-routes
    provides: inform schema base (compass_topics, compass_stances, compass_categories, politicians)

provides:
  - adminCreateTopicWithStances: atomic topic+stance creation via RPC with VALIDATION_ERROR error code
  - adminListTopics: metadata-only topic listing (no stances, no is_active)
  - adminCreatePolitician: direct insert with is_candidate field support
  - adminUpdatePolitician: update with NOT_FOUND error code on PGRST116
  - adminListCategories: alphabetically sorted category listing
  - adminCreateCategory: insert with DUPLICATE_TITLE error code on unique violation
  - adminAssignTopicCategories: atomic replace-all via RPC with NOT_FOUND error code

affects:
  - 14-03: admin.ts route handlers import all seven new functions from adminService.ts

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Error code objects via Object.assign(new Error(msg), { code: 'CODE' }) — consistent with existing adminUpdateTopic/adminUpdateStance pattern
    - RPC for atomicity (adminCreateTopicWithStances, adminAssignTopicCategories), direct supabaseAdmin for simple CRUD (politicians, categories, topics list)

key-files:
  created: []
  modified:
    - backend/src/lib/adminService.ts

key-decisions:
  - "adminListTopics selects only metadata columns (id, title, short_title, is_live, created_at, updated_at) — no stances, no is_active generated column"
  - "adminCreateCategory maps PostgreSQL error code 23505 to DUPLICATE_TITLE for clean 400 handling in route layer"
  - "All seven functions stay in adminService.ts — architecture.test.ts allowlist does not permit supabaseAdmin in new files"

patterns-established:
  - "VALIDATION_ERROR code for RPC-level stance validation (INVALID_STANCE_VALUE, INVALID_STANCE_TEXT prefix check)"
  - "NOT_FOUND code thrown on PGRST116 (supabase single() returns no row) — matches existing adminUpdateStance pattern"

# Metrics
duration: 3min
completed: 2026-03-07
---

# Phase 14 Plan 02: adminService.ts Compass Admin Functions Summary

**Seven new exported functions in adminService.ts covering atomic RPC calls (topic+stances, category assignment) and direct CRUD for politicians and categories**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-07T00:32:31Z
- **Completed:** 2026-03-07T00:35:11Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added `adminCreateTopicWithStances` calling the two-pass `admin_create_topic_with_stances` RPC — validation errors surfaced as `VALIDATION_ERROR` code
- Added `adminListTopics` with metadata-only select, excluding the `is_active` generated column and any stances join
- Added `adminCreatePolitician` and `adminUpdatePolitician` with full `is_candidate` field support
- Added `adminListCategories` and `adminCreateCategory` with `DUPLICATE_TITLE` error code on unique constraint violation
- Added `adminAssignTopicCategories` calling the atomic `admin_assign_topic_categories` RPC

## Task Commits

Each task was committed atomically:

1. **Task 1: Add new service functions to adminService.ts** - `c129c23` (feat)

**Plan metadata:** (pending docs commit)

## Files Created/Modified

- `backend/src/lib/adminService.ts` — seven new exported functions appended to compass admin section (after adminListPoliticians, before Dashboard section)

## Decisions Made

None - followed plan as specified. All function signatures, error codes, and RPC parameter shapes matched the plan exactly.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All seven service functions are exported and TypeScript-clean
- Plan 14-03 (admin.ts route handlers + tests) can now import: `adminCreateTopicWithStances`, `adminListTopics`, `adminCreatePolitician`, `adminUpdatePolitician`, `adminListCategories`, `adminCreateCategory`, `adminAssignTopicCategories`
- No blockers for Wave 3

---
*Phase: 14-compass-admin-backend*
*Completed: 2026-03-07*
