---
phase: 55-compass-stance-editor-campaign-manager-endpoints
plan: 01
subsystem: database
tags: [postgres, pool, typescript, roles, audit-log, jurisdiction, politicians]

# Dependency graph
requires:
  - phase: 47-role-scope-migration
    provides: user_roles scope columns, role_audit_log table, get_user_roles RPC
  - phase: 35-platform-consolidation
    provides: essentials.politicians canonical table (post-deduplication)
provides:
  - essentials.politicians.home_jurisdiction_geoid (TEXT, nullable)
  - inform.politician_answers.write_in_text (TEXT, nullable)
  - public.role_audit_log.role_grant_id (UUID, nullable, sparse index)
  - get_user_roles RPC returns ur.id (grant row UUID)
  - UserRoleGrant interface includes id: string
  - stanceService.ts with jurisdiction resolution and stance audit helpers
affects:
  - 55-02-stance-editor-routes
  - 55-03-campaign-manager-endpoints

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "stanceService pattern: jurisdiction helpers that use pool.query against essentials.politicians"
    - "Fail-open jurisdiction: politician with NULL home_jurisdiction_geoid matched by any stance editor grant (logged as warning)"
    - "Sparse index on role_audit_log.role_grant_id (WHERE role_grant_id IS NOT NULL)"

key-files:
  created:
    - backend/migrations/049_compass_contributor_schema.sql
    - backend/src/lib/stanceService.ts
  modified:
    - backend/src/lib/roleService.ts

key-decisions:
  - "user_roles.id already existed as UUID — no ALTER TABLE needed; migration documents this as comment"
  - "NULL home_jurisdiction_geoid on politician = fail-open for Alpha (any stance editor can edit, console.warn logged)"
  - "writeStanceAuditLog uses fields_changed (text[]) and snapshot_after (jsonb) as two separate columns, not combined"
  - "role_grant_id in audit log = matchingGrant.id (user_roles row UUID), NOT matchingGrant.role_id (roles definition UUID)"
  - "getUserRoles return type simplified to UserRoleGrant[] after id field added to interface"

patterns-established:
  - "stanceService: pool.query for all essentials/inform schema reads — never PostgREST"
  - "getMatchingGrant pure function: campaign_manager matches resource_id, compass_stance_editor matches jurisdiction"
  - "writeStanceAuditLog accepts PoolClient (open transaction) — caller owns BEGIN/COMMIT"

# Metrics
duration: 18min
completed: 2026-04-03
---

# Phase 55 Plan 01: Compass Contributor Schema Summary

**Schema bootstrap for contributor stance editing: 3 columns added to production, get_user_roles RPC extended with grant row UUID, jurisdiction resolution and audit log helpers in stanceService.ts**

## Performance

- **Duration:** 18 min
- **Started:** 2026-04-03T19:41:10Z
- **Completed:** 2026-04-03T19:59:00Z
- **Tasks:** 2
- **Files modified:** 3 (1 created, 1 new migration, 1 updated service)

## Accomplishments

- Applied migration 049 to production: added `home_jurisdiction_geoid` on `essentials.politicians`, `write_in_text` on `inform.politician_answers`, `role_grant_id` on `public.role_audit_log` (with sparse index)
- Updated `get_user_roles` RPC to return `ur.id` (grant row UUID) so audit log entries can reference the specific grant
- Created `stanceService.ts` with `getPoliticianJurisdiction`, `getMatchingGrant`, `getContributorPoliticians`, `writeStanceAuditLog` — all using `pool.query` against `essentials.politicians`
- Added `id: string` to `UserRoleGrant` interface and simplified `getUserRoles` return type

## Task Commits

Each task was committed atomically:

1. **Task 1: Verify user_roles id column, update get_user_roles RPC, and write migration** - `a13cdb4` (feat)
2. **Task 2: Update UserRoleGrant interface and create stanceService.ts** - `ec9f63e` (feat)

**Plan metadata:** (follows in final commit)

## Files Created/Modified

- `backend/migrations/049_compass_contributor_schema.sql` - Schema additions for contributor stance editing, applied to production
- `backend/src/lib/stanceService.ts` - Jurisdiction resolution and stance audit log helpers
- `backend/src/lib/roleService.ts` - Added `id: string` to UserRoleGrant, simplified getUserRoles return type

## Decisions Made

- **user_roles.id already existed**: Production already had the UUID column from an earlier migration. Migration documents this with a comment rather than adding a no-op ALTER.
- **Fail-open jurisdiction**: Politicians with `NULL home_jurisdiction_geoid` are matched by any `compass_stance_editor` grant. This is intentional for Alpha — logged as `console.warn` with a TODO to tighten once all politicians have geoids assigned.
- **Two separate audit columns**: `fields_changed` (text[]) holds field name strings; `snapshot_after` (jsonb) holds the structured before/after values. These are distinct columns, not conflated.
- **Grant row UUID in audit**: `role_grant_id` = `matchingGrant.id` (the `user_roles` row UUID), not `matchingGrant.role_id` (the `roles` definition UUID). This traces the exact permission row used, not just the role type.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All schema prerequisites for Plans 02 and 03 are live in production
- `stanceService.ts` exports are ready to import in stance editor and campaign manager route files
- `UserRoleGrant.id` is now available throughout the codebase wherever role grants are checked
- Plan 02 (stance editor routes) can proceed immediately

---
*Phase: 55-compass-stance-editor-campaign-manager-endpoints*
*Completed: 2026-04-03*
