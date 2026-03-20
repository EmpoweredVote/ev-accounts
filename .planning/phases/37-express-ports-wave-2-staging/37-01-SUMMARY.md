---
phase: 37-express-ports-wave-2-staging
plan: 01
subsystem: api
tags: [express, middleware, postgres, roles, staging, pool-query]

# Dependency graph
requires:
  - phase: 34-database-schema-migration
    provides: staging schema tables with RLS; public.roles, public.user_roles tables
  - phase: 36-express-ports-wave-1
    provides: pool.query() pattern confirmed for non-public schemas
provides:
  - staging_reviewer role seeded in public.roles (connected tier)
  - status DEFAULT 'pending' on staging.politicians, staging.stances, staging.building_photos
  - requireStagingReviewer middleware — dual-path access gate (admin OR staging_reviewer)
affects: [37-02, 37-03, 37-04, 38-express-ports-wave-3]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dual-path middleware: admin fast path (no JOIN) + role slug JOIN with revoked_at guard"
    - "pool.query() exclusively in middleware — no supabaseAdmin in requireStagingReviewer"

key-files:
  created:
    - backend/src/middleware/requireStagingReviewer.ts
  modified: []

key-decisions:
  - "Admin fast path uses public.admin_users direct lookup (no JOIN) — keeps consistent with requireAdmin.ts pattern"
  - "staging_reviewer slug is stable identifier; slug JOIN preferred over id JOIN for readability"
  - "revoked_at IS NULL on user_roles ensures only active grants are evaluated"
  - "No CHECK constraint added on staging status columns — legacy 'draft'/'needs_review' rows must remain valid"

patterns-established:
  - "Dual-path middleware pattern: check admin first, then specific role — reusable for future role-gated routes"

# Metrics
duration: 5min
completed: 2026-03-20
---

# Phase 37 Plan 01: Staging Role and Middleware Foundation Summary

**staging_reviewer role seeded in public.roles and requireStagingReviewer middleware created with dual-path admin-or-role access control using pool.query() only**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-20T15:53:51Z
- **Completed:** 2026-03-20T15:59:03Z
- **Tasks:** 2 of 2
- **Files modified:** 1

## Accomplishments

- staging_reviewer role inserted into public.roles (connected tier, is_active=true) — queryable and assignable
- Status defaults normalized to 'pending' on all three staging tables (politicians, stances, building_photos)
- requireStagingReviewer middleware created: admin fast path + staging_reviewer role check with revoked_at guard

## Task Commits

Each task was committed atomically:

1. **Task 1: Apply staging migrations** - `f319251` (chore — database-only, empty commit)
2. **Task 2: Create requireStagingReviewer middleware** - `9c527ae` (feat)

**Plan metadata:** (see below — docs commit)

## Files Created/Modified

- `backend/src/middleware/requireStagingReviewer.ts` — Role-gate middleware exports `requireStagingReviewer`; checks admin_users first, then user_roles JOIN roles on slug='staging_reviewer'

## Decisions Made

- Admin fast path uses a single `SELECT 1 FROM public.admin_users WHERE user_id = $1` — no JOIN, consistent with requireAdmin.ts convention
- staging_reviewer role check JOINs `user_roles` with `roles` on `r.id = ur.role_id` with `revoked_at IS NULL` — only active grants count
- No CHECK constraints added on status columns — existing rows may have 'draft' or 'needs_review'; service layer enforces state machine for new records
- No existing rows updated — legacy statuses are fine; they won't be processable through new review flow until manually updated

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- `npx tsc --noEmit` consistently OOMed (exit code 134, "Zone Allocation failed") across all invocation methods (npx, direct node call, npm run build). This is an environmental constraint on Node v24 + Windows in this session — the same tsc check passed successfully in Phase 36 sessions. Manual static analysis confirmed correct import paths, types, and patterns. The file follows the exact same structure as requireAdmin.ts with only the query logic changed.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- requireStagingReviewer is ready for import in Plan 04's route file
- staging_reviewer role can be assigned to users via public.user_roles INSERT
- Plan 02 (staging service layer) and Plan 03 (staging RPC) are unblocked
- Plan 04 (staging routes) can wire requireStagingReviewer as middleware

---
*Phase: 37-express-ports-wave-2-staging*
*Completed: 2026-03-20*
