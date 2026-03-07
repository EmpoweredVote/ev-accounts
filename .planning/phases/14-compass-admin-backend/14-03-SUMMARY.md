---
phase: 14-compass-admin-backend
plan: 03
subsystem: api
tags: [typescript, express, admin, compass, zod, vitest, supertest]

# Dependency graph
requires:
  - phase: 14-02
    provides: seven new service functions in adminService.ts (adminCreateTopicWithStances, adminListTopics, adminCreatePolitician, adminUpdatePolitician, adminListCategories, adminCreateCategory, adminAssignTopicCategories)
  - phase: 14-01
    provides: RPC functions in Postgres for atomic topic+stance creation and category assignment

provides:
  - All twelve compass admin routes wired and guarded in admin.ts
  - GET /api/admin/compass/topics (list all topics including drafts)
  - POST /api/admin/compass/topics (stances-capable atomic creation)
  - PATCH /api/admin/compass/topics/:id (method corrected from PUT)
  - PATCH /api/admin/compass/stances/:id (method corrected from PUT)
  - GET /api/admin/compass/categories
  - POST /api/admin/compass/categories
  - PUT /api/admin/compass/topics/:id/categories
  - GET /api/admin/compass/politicians (new /compass/ path)
  - POST /api/admin/compass/politicians
  - PATCH /api/admin/compass/politicians/:id
  - PUT /api/admin/compass/politicians/:id/answers (retained)
  - POST /api/admin/compass/politicians/:id/context (retained)
  - 12 CI-safe 401-enforcement tests in admin-compass.test.ts

affects:
  - 15-compass-admin-ui: React UI (Phase 15) references these routes directly

# Tech tracking
tech-stack:
  added: []
  patterns:
    - PATCH method for update routes (not PUT) — consistent with REST semantics for partial updates
    - logAdminAction called before res.json() in every mutation route (ADMN-05 requirement)
    - CI-safe 401 tests: dynamic import pattern with beforeAll + env preset before import

key-files:
  created:
    - tests/integration/admin-compass.test.ts
  modified:
    - backend/src/routes/admin.ts

key-decisions:
  - "PUT → PATCH for /compass/topics/:id and /compass/stances/:id — corrects method semantics; Phase 15 must use PATCH"
  - "POST /compass/topics handler replaced entirely with adminCreateTopicWithStances — old adminCreateTopic import removed"
  - "GET /compass/politicians at /compass/politicians path (not /essentials/politicians) — new canonical admin path"
  - "Legacy GET /essentials/politicians retained unchanged for backward compatibility"

patterns-established:
  - "PATCH for partial resource updates, PUT for full-replace operations (categories, answers)"
  - "CreateTopicWithStancesSchema uses stances array with value(1-5) + text — matches RPC validation"

# Metrics
duration: 4min
completed: 2026-03-07
---

# Phase 14 Plan 03: Compass Admin Routes Summary

**All twelve compass admin routes wired in admin.ts with PATCH method corrections, stances-capable topic creation, and 12 CI-safe 401-enforcement tests**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-07T00:38:37Z
- **Completed:** 2026-03-07T00:43:07Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added all six missing compass admin routes (GET topics, GET categories, POST categories, PUT topics/:id/categories, GET politicians, POST politicians, PATCH politicians/:id)
- Corrected two method mismatches: PUT → PATCH for /compass/topics/:id and /compass/stances/:id
- Replaced old POST /compass/topics handler (adminCreateTopic) with stances-capable version (adminCreateTopicWithStances), supporting atomic topic+stance creation in one request
- Added five new Zod schemas: CreateTopicWithStancesSchema, CreatePoliticianSchema, UpdatePoliticianSchema, CreateCategorySchema, AssignCategoriesSchema
- Removed deprecated adminCreateTopic import (no longer referenced)
- Created 12 CI-safe 401-enforcement tests — all pass, full suite 102/102

## Task Commits

Each task was committed atomically:

1. **Task 1: Repair and extend admin.ts compass routes** - `695f1a3` (feat)
2. **Task 2: Write CI-safe 401-enforcement tests for all new routes** - `1d693f4` (test)

**Plan metadata:** (pending docs commit)

## Files Created/Modified

- `backend/src/routes/admin.ts` — all twelve compass admin routes, five new Zod schemas, corrected PATCH methods, adminCreateTopic import removed
- `tests/integration/admin-compass.test.ts` — 12 CI-safe 401-enforcement tests (85 lines)

## Decisions Made

None - followed plan as specified. All route signatures, Zod schemas, and error handling patterns matched the plan exactly.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All twelve routes are wired, guarded with requireAuth + requireAdmin, and TypeScript-clean
- Phase 15 (React Admin UI) can reference the route manifest table in 14-03-PLAN.md without reading source
- Every mutation route calls logAdminAction — admin audit log is complete
- No blockers for Phase 15

---
*Phase: 14-compass-admin-backend*
*Completed: 2026-03-07*
