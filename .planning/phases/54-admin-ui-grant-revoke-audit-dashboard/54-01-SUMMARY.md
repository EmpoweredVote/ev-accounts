---
phase: 54-admin-ui-grant-revoke-audit-dashboard
plan: 01
subsystem: api
tags: [roles, audit-log, express, postgres, typescript, scope, grant, revoke]

requires:
  - phase: 52-role-schema-rpcs
    provides: role_audit_log table, scoped grant_role/revoke_role/get_user_roles RPCs with feature_scope/jurisdiction_geoid/resource_id
  - phase: 53-service-layer-requirerole-middleware
    provides: roleService grantRole/revokeRole wrappers, adminGrantRole/adminRevokeRole in adminService

provides:
  - Scoped grant/revoke: grantRole and revokeRole accept featureScope, jurisdictionGeoid, resourceId and pass to RPCs
  - writeRoleAuditLog: every grant and revoke writes a row to public.role_audit_log via pool.query
  - getRoleAuditLog: paginated, filterable query over role_audit_log with actor/target display_name JOINs
  - Account detail enriched: getAccountDetail replaces roles array with getUserRoles result (scope columns included)
  - GET /api/admin/role-audit-log: paginated, filterable audit log read endpoint
  - POST /api/admin/roles/grant and /roles/revoke: now accept feature_scope, jurisdiction_geoid, resource_id

affects:
  - 54-02-admin-ui-frontend (Plan 02 — reads scoped grant/revoke and audit log endpoints)

tech-stack:
  added: []
  patterns:
    - writeRoleAuditLog uses pool.query (direct postgres) for public schema write — consistent with non-public schema pattern
    - Scope params default to 'platform' / null / null when omitted — safe backward-compatible behavior
    - getAccountDetail calls getUserRoles after admin_get_account_detail RPC and replaces roles key — enriches without breaking existing callers

key-files:
  created: []
  modified:
    - backend/src/lib/roleService.ts
    - backend/src/lib/adminService.ts
    - backend/src/routes/admin.ts

key-decisions:
  - "writeRoleAuditLog uses pool.query not supabaseAdmin — consistent with project pattern for public-schema writes from service layer"
  - "getAccountDetail enriches roles non-fatally: getUserRoles error falls through to admin_get_account_detail result"
  - "resolvedScope defaults to 'platform' in route handlers so existing clients sending no scope param continue to work"
  - "AuditLogQuerySchema caps page_size at 50 to prevent runaway queries from the frontend"

patterns-established:
  - "Audit log writes (writeRoleAuditLog) happen before logAdminAction in the route handler — role audit before general admin audit"
  - "Dynamic WHERE clause built with parameterized conditions array and params array, then composed into single query string"

duration: 18min
completed: 2026-04-03
---

# Phase 54 Plan 01: Backend Scope Threading + Audit Log Summary

**Scoped grant/revoke threaded end-to-end, role_audit_log written on every action, and paginated audit log read endpoint added**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-04-03T16:00:00Z
- **Completed:** 2026-04-03T16:18:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- `grantRole` and `revokeRole` in roleService now accept `featureScope`, `jurisdictionGeoid`, `resourceId` and pass them to the RPCs (migration 047 RPCs already accepted these — the TS layer was the gap)
- `writeRoleAuditLog` added to adminService — inserts actor, target, action, scope fields, and `snapshot_after: { role_slug }` into `public.role_audit_log` via `pool.query`
- `getRoleAuditLog` added to adminService — dynamic parameterized WHERE, COUNT for total, JOIN to `public.users` for display names, ORDER BY created_at DESC, LIMIT/OFFSET pagination
- `getAccountDetail` now replaces its roles array with the result of `getUserRoles` — account detail in the admin UI will show `feature_scope`, `jurisdiction_geoid`, `resource_id` per role
- `GET /api/admin/role-audit-log` added with Zod validation (feature_scope, jurisdiction_geoid, from_date, to_date, page, page_size capped at 50)
- `POST /api/admin/roles/grant` and `/roles/revoke` now accept and propagate scope params; both call `writeRoleAuditLog` before `logAdminAction`

## Task Commits

Each task was committed atomically:

1. **Task 1: Thread scope params through grant/revoke + write role_audit_log** - `38f297f` (feat)
2. **Task 2: Update account detail roles + add audit log read endpoint** - `8891c20` (feat)

## Files Created/Modified

- `backend/src/lib/roleService.ts` — `grantRole` and `revokeRole` updated with 3 optional scope params, passed to RPCs
- `backend/src/lib/adminService.ts` — `adminGrantRole`/`adminRevokeRole` forward scope params; `writeRoleAuditLog` and `getRoleAuditLog` added; `getUserRoles` imported; `getAccountDetail` enriched
- `backend/src/routes/admin.ts` — `RoleActionSchema` extended with scope fields; grant/revoke routes call `writeRoleAuditLog`; `GET /role-audit-log` route added with `AuditLogQuerySchema`

## Decisions Made

- Used `pool.query` for `writeRoleAuditLog` — consistent with the project-wide pattern that all non-public schema and complex writes bypass PostgREST. `public.role_audit_log` is new infrastructure that benefits from direct driver access.
- `getAccountDetail` enrichment is non-fatal: if `getUserRoles` throws, the function falls through to the `admin_get_account_detail` RPC result. This prevents a role service blip from breaking the entire account detail view.
- `resolvedScope = feature_scope ?? 'platform'` in route handlers — existing admin UI calls with no scope param continue to work as platform-wide grants.
- `page_size` capped at 50 in `AuditLogQuerySchema` — prevents accidental large query from frontend pagination components.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None — TypeScript compiled clean after each edit, no import or type issues.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02 (admin UI frontend) can now call `GET /api/admin/role-audit-log` and receive paginated entries with display names
- Grant and revoke UI can send `feature_scope`, `jurisdiction_geoid`, `resource_id` in POST body and they will be persisted and audited
- Account detail response includes scope columns per role — UI can render them without additional requests

---
*Phase: 54-admin-ui-grant-revoke-audit-dashboard*
*Completed: 2026-04-03*
