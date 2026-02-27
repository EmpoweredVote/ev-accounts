---
phase: 07-admin-tool-and-calibration-cron
plan: 01
subsystem: api
tags: [express, postgres, supabase, zod, admin, rls, audit-log, invite-tree, react-flow]

# Dependency graph
requires:
  - phase: 06-gems-roles-social-graph
    provides: roleService.ts with grantRole/revokeRole ready for admin HTTP endpoints
  - phase: 05-empower-flow
    provides: executeDemotion RPC callable by admin demote endpoint
  - phase: 04-compass-routes
    provides: inform schema (compass_topics, stances, politicians) for admin compass CRUD
  - phase: 03-alpha-enrollment
    provides: invite_codes, invite_chains tables for admin invite management
  - phase: 01-foundation
    provides: admin_audit_log scaffolded (migration 003), dual Supabase client pattern
provides:
  - requireAdmin middleware: checks admin_users table, returns 403 for non-admins
  - adminService.ts: 20 exported data access functions for all admin operations
  - admin.ts routes: 25 admin endpoints at /api/admin/* with requireAuth + requireAdmin
  - Phase 7 schema migration: admin_users, notifications, calibration_lapse_runs tables
  - get_calibration_lapsed_users RPC replacement: timestamp-aware with went_live_at
  - Phase 4 deferred compass admin routes: topics/stances/politicians CRUD
  - Phase 6 deferred role admin routes: grant/revoke with CIVIC-02 compliance
affects:
  - 07-02: calibration cron uses cronService.ts (whitelisted) and calibration_lapse_runs table
  - 07-03: admin React UI consumes all /api/admin/* endpoints built here

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "router.use(requireAuth, requireAdmin) — single middleware application covers all routes"
    - "logAdminAction() called before every mutation return — ADMN-05 audit compliance"
    - "adminService in lib/ — all data access isolated from routes/ (architecture constraint)"
    - "pg pool for all SQL reads/writes; supabaseAdmin in lib/ only for RPC calls"
    - "went_live_at transition detection — adminUpdateTopic sets went_live_at on is_live flip"

key-files:
  created:
    - supabase/migrations/20260227000024_phase7_admin_schema.sql
    - backend/src/middleware/requireAdmin.ts
    - backend/src/lib/adminService.ts
    - backend/src/routes/admin.ts
  modified:
    - backend/src/index.ts
    - tests/integration/architecture.test.ts

key-decisions:
  - "admin_audit_log column mismatch resolved: migration 003 used target_id/metadata; Phase 7 adds target_user_id/details as new columns via ALTER TABLE — old columns retained for backward compat"
  - "actorId helper uses any cast in routes — consistent with existing codebase pattern (req as any).userId to avoid Express generic type conflicts"
  - "Architecture test comment rule: admin.ts doc comment must not contain the word supabaseAdmin even in prohibition context — string match is literal"
  - "getInviteTree returns React Flow-compatible flat arrays (nodes/edges) with position {x:0,y:0} — dagre layout applied client-side by admin UI"
  - "cronService.ts whitelisted in architecture test proactively (07-02 will create it)"

patterns-established:
  - "requireAdmin pattern: supabaseAdmin.from('admin_users').maybeSingle() — returns 403 on miss, identical shape to requireConnected/requireEmpowered"
  - "Admin mutation pattern: await action() then await logAdminAction() then res.json() — audit before response"
  - "Route param order: /invites/tree before /invites/:codeId — prevents 'tree' being captured as codeId"

# Metrics
duration: 7min
completed: 2026-02-27
---

# Phase 7 Plan 1: Admin Backend Infrastructure Summary

**Express admin API layer with 25 endpoints, requireAdmin middleware, 20-function adminService data layer, and Phase 7 schema migration — delivers all deferred Phase 4/6 admin routes and complete audit logging**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-27T20:59:20Z
- **Completed:** 2026-02-27T21:06:47Z
- **Tasks:** 3
- **Files modified:** 6 (4 created, 2 modified)

## Accomplishments

- Complete /api/admin/* route layer (25 endpoints) with router-level auth+admin middleware — every route automatically protected
- adminService.ts with 20 data access functions: accounts (list/detail/suspend/unsuspend/demote), invites (list/create/revoke/tree), roles (grant/revoke), compass admin (topics/stances/politicians), dashboard stats, cron log
- Phase 7 schema migration: admin_users, notifications, calibration_lapse_runs tables + timestamp-aware get_calibration_lapsed_users RPC replacement
- ADMN-05 compliance: 17 logAdminAction() calls across mutation routes — every admin write action logged
- Architecture test passes with new files whitelisted (lib/adminService.ts, lib/cronService.ts, middleware/requireAdmin.ts)

## Task Commits

Each task was committed atomically:

1. **Task 1: Phase 7 schema migration** - `23bf8d6` (feat)
2. **Task 2: requireAdmin middleware + adminService data layer** - `9d89f2e` (feat)
3. **Task 3: Admin routes + index.ts mount + architecture test update** - `81cda6c` (feat)

**Plan metadata:** (created after this summary)

## Files Created/Modified

- `supabase/migrations/20260227000024_phase7_admin_schema.sql` — admin_users, ALTER admin_audit_log (add target_user_id/details), notifications (with RLS owner SELECT), calibration_lapse_runs, get_calibration_lapsed_users replacement
- `backend/src/middleware/requireAdmin.ts` — checks admin_users table via supabaseAdmin, 403 for non-admins
- `backend/src/lib/adminService.ts` — 20 exported async functions covering full admin data access layer
- `backend/src/routes/admin.ts` — 25 admin routes, router.use middleware, Zod validation on all POST/PUT
- `backend/src/index.ts` — added adminRouter import and mount at /api/admin
- `tests/integration/architecture.test.ts` — whitelist lib/adminService.ts, lib/cronService.ts, middleware/requireAdmin.ts

## Decisions Made

- **admin_audit_log column mismatch:** Migration 003 created the table with `target_id` and `metadata` columns. Phase 7 plan specifies `target_user_id` (FK) and `details` (JSONB NOT NULL). Resolution: ALTER TABLE to add the new columns alongside old ones. logAdminAction() uses the new column names. Old columns retained as-is (historical records, no migration).
- **Architecture test string match:** The test uses `content.includes('supabaseAdmin')` — even comments mentioning the name fail the test. Resolved by removing the word from admin.ts comments entirely and using neutral phrasing.
- **actorId helper typed as any:** Express parameterizes req with route params type, making `req as AuthenticatedRequest` fail type checking in parameterized routes. Used `any` cast in actorId helper — consistent with the plan's suggested `(req as any).userId` pattern.
- **cronService.ts whitelisted proactively:** 07-02 will create this file and it will use supabaseAdmin. Added to whitelist now to prevent test failure when that file appears.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed supabaseAdmin mention from admin.ts comment**
- **Found during:** Task 3 (architecture test run)
- **Issue:** Admin routes file comment block contained the phrase "supabaseAdmin" in a prohibition statement. Architecture test uses literal string match — comment triggered violation.
- **Fix:** Replaced prohibitive comment with neutral description of pattern used
- **Files modified:** backend/src/routes/admin.ts
- **Verification:** Architecture test passes (2/2 green)
- **Committed in:** 81cda6c (Task 3 commit)

**2. [Rule 1 - Bug] Fixed actorId type cast for parameterized routes**
- **Found during:** Task 3 (TypeScript compilation check)
- **Issue:** `(req as AuthenticatedRequest)` fails when Express parameterizes req with route params (e.g., `Request<{userId: string}>`) — insufficient type overlap for direct cast
- **Fix:** Changed actorId helper parameter to `any`, added internal cast. Changed router.use() casts to `as any`
- **Files modified:** backend/src/routes/admin.ts
- **Verification:** `npx tsc --noEmit` shows no errors in routes/admin.ts
- **Committed in:** 81cda6c (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 - Bug)
**Impact on plan:** Both fixes necessary for correctness (architecture test compliance and TypeScript compilation). No scope creep.

## Issues Encountered

- Pre-existing TypeScript errors in codebase (cache.ts, inviteService.ts, routes/account.ts, routes/social.ts, middleware/auth.ts) — not caused by this plan, verified by checking only new file errors
- Pre-existing auth.test.ts failures for "requires Supabase connectivity" tests — not caused by this plan

## Next Phase Readiness

- All /api/admin/* endpoints ready for consumption by admin React UI (07-03)
- calibration_lapse_runs table and get_calibration_lapsed_users RPC ready for cron service (07-02)
- cronService.ts whitelisted in architecture test — 07-02 can create it without test update
- Notifications table ready for cron to write day-25/30/31 warning records

---
*Phase: 07-admin-tool-and-calibration-cron*
*Completed: 2026-02-27*
