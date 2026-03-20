---
phase: 39-compass-additions
plan: "03"
subsystem: api
tags: [express, compass, admin, audit, zod, typescript]

# Dependency graph
requires:
  - phase: 39-01
    provides: "admin_update_politician_answers full-replacement RPC (NUMERIC value, DELETE + upsert)"
provides:
  - "Admin-gated compass routes at Go-compatible /api/compass/* URL paths"
  - "7 mutation endpoints: topic CRUD (create/update/delete/categories), stance update, politician answers replace, politician context"
  - "ADMN-05 audit coverage: all 7 mutations write to admin_audit_log via logAdminAction()"
affects: [40-frontend-auth-updates, 43-integration-documentation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dual-router pattern: two routers mounted at same prefix (/api/compass) — Express falls through from public router to admin router"
    - "POST /topics/create uses same adminCreateTopicWithStances service function as /api/admin/compass/topics"
    - "DELETE /topics/delete/:id: pool.query() COUNT guard before deletion, topic_categories explicit delete before topic"
    - "PUT /politicians/:id/answers: adminRpc('admin_update_politician_answers') with JSON.stringify payload"

key-files:
  created:
    - "backend/src/routes/compassAdmin.ts"
  modified:
    - "backend/src/index.ts"

key-decisions:
  - "Dual-router mount: compassAdminRouter after compassRouter at /api/compass — no route collisions, public routes unblocked"
  - "DELETE /topics/delete/:id returns 422 TOPIC_HAS_RESPONSES when responses exist — admin must archive with is_live=false"
  - "topic_categories deleted explicitly before topic (stances cascade via FK, topic_categories may not)"
  - "POST /politicians/context registered before PUT /politicians/:id/answers — prevents 'context' being captured as :id param"
  - "value field on PoliticianAnswersSchema: z.number().multipleOf(0.5).min(0.5).max(5.5) — matches NUMERIC(3,1) half-step CHECK from Plan 01"

patterns-established:
  - "compassAdminRouter blanket middleware: router.use(requireAuth as any, requireAdmin as any)"
  - "actorId(req) helper: same pattern as admin.ts"
  - "All 7 routes call logAdminAction() before returning success (ADMN-05)"

# Metrics
duration: 2min
completed: 2026-03-20
---

# Phase 39 Plan 03: Compass Admin — Go-URL Parity Routes Summary

**7 admin-gated compass mutation routes at /api/compass/* paths via dual-router Express pattern, all ADMN-05 audit-logged**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-20T21:51:11Z
- **Completed:** 2026-03-20T21:53:32Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `compassAdmin.ts` with 7 admin-only routes at Go-compatible URL paths that CompassV2 expects
- Full replacement politician answers via `admin_update_politician_answers` RPC (Plan 01 DDL)
- Topic deletion guard: 422 blocked when user responses exist, 204 on success with explicit category cleanup
- Dual-router mount in `index.ts`: public compass routes unaffected, admin routes fall-through correctly

## Task Commits

1. **Task 1: Create compassAdmin.ts with 7 admin compass routes** - `5244499` (feat)
2. **Task 2: Mount compassAdminRouter in index.ts** - `004c447` (feat)

## Files Created/Modified

- `backend/src/routes/compassAdmin.ts` — New router with all 7 admin compass mutations; blanket requireAuth+requireAdmin middleware; logAdminAction on every route
- `backend/src/index.ts` — Import and mount compassAdminRouter at `/api/compass` after compassRouter

## Decisions Made

- **Dual-router pattern** — two routers share `/api/compass` prefix; Express tries compassRouter first (public routes), falls through to compassAdminRouter for admin mutations. No URL+method collisions exist.
- **topic_categories explicit delete** — `DELETE FROM inform.compass_topic_categories WHERE topic_id = $1` run before topic delete to ensure cleanup regardless of FK CASCADE behavior
- **Route ordering within compassAdmin** — `POST /politicians/context` registered before `PUT /politicians/:id/answers` to prevent Express matching "context" as an `:id` param value

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 39 now has 2 of 3 plans complete (01 DDL, 03 admin routes)
- Plan 02 (compare endpoint + verdicts routes) running in parallel — unblocked by Plan 01
- CompassV2 admin CRUD at Go-compatible paths is now live: POST /topics/create, PATCH /topics/update, DELETE /topics/delete/:id, PATCH /topics/categories/update, PATCH /stances/update, PUT /politicians/:id/answers, POST /politicians/context

---
*Phase: 39-compass-additions*
*Completed: 2026-03-20*
