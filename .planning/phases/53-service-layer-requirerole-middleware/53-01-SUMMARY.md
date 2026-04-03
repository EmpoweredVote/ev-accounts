---
phase: 53-service-layer-requirerole-middleware
plan: 01
subsystem: api
tags: [roles, rbac, redis, cache, middleware, express, typescript]

# Dependency graph
requires:
  - phase: 52-role-schema-rpc-migration
    provides: grant_role/revoke_role/get_user_roles RPCs with scope columns, UserRoleGrant shape
  - phase: cache.ts
    provides: Redis-backed cache with in-memory fallback
provides:
  - UserRoleGrant type (exported from roleService.ts)
  - CheckRoleScope type (exported from roleService.ts)
  - checkRole pure function — NULL-safe scope matching with OR slug logic
  - getCachedUserRoles — Redis-cached (90s TTL) role grant lookup, falls through to DB on miss/error
  - invalidateRoleCache — cache.del with swallowed errors
  - requireRole middleware factory — 401/403 gating with opaque error bodies
affects:
  - 53-02: contributor.ts + roles.ts use getCachedUserRoles/checkRole; admin.ts uses invalidateRoleCache
  - 54-58: all downstream phases import requireRole for their protected routes

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "NULL-safe scope matching: NULL grant value = unrestricted — only a non-null grant that differs from requested scope causes a skip"
    - "Redis-as-optimization: all cache.get/set/del wrapped in try/catch; DB is source of truth"
    - "Middleware factory pattern: requireRole(slug, opts?) returns async Express handler"
    - "Opaque error bodies: 401 unauthorized / 403 forbidden / 500 internal server error — no role name or scope leaked"

key-files:
  created:
    - backend/src/middleware/requireRole.ts
  modified:
    - backend/src/lib/roleService.ts
    - tests/integration/requireRole.test.ts

key-decisions:
  - "NULL grant value means unrestricted — passes any scope check. Only non-null grant that differs causes skip."
  - "requireRole self-contains auth check (401 on missing userId) so it's safe to use without stacking requireAuth, but requireAuth is recommended for better error messages"
  - "Dynamic import in test file (beforeAll) required because static imports are hoisted before process.env assignments in ESM"

patterns-established:
  - "checkRole: slug matching + NULL-safe geoid + NULL-safe resourceId + OR array slugs"
  - "getCachedUserRoles: cache key = roles:uid:{userId}, 90s TTL, try/catch on all cache ops"

# Metrics
duration: 5min
completed: 2026-04-03
---

# Phase 53 Plan 01: Service Layer + requireRole Middleware Summary

**Redis-cached role lookup (getCachedUserRoles), NULL-safe scope matching (checkRole), and requireRole middleware factory — the single implementation of role enforcement all downstream phases will import**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-03T15:36:33Z
- **Completed:** 2026-04-03T15:41:15Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Added `UserRoleGrant`, `CheckRoleScope`, `checkRole`, `getCachedUserRoles`, and `invalidateRoleCache` exports to `roleService.ts` — all existing exports unchanged
- Created `requireRole.ts` middleware factory with auth check, Redis-backed role lookup, and NULL-safe scope matching
- 12 checkRole unit tests pass covering all NULL-scope and scope-match combinations from SC5

## Task Commits

Each task was committed atomically:

1. **Task 1: Upgrade roleService with cached lookups, checkRole, and cache invalidation** - `fa85948` (feat)
2. **Task 2: Create requireRole middleware factory** - `1816ba9` (feat)
3. **Task 3: checkRole unit tests — all NULL-scope and scope-match combinations** - `e686a75` (test)

## Files Created/Modified
- `backend/src/lib/roleService.ts` - Added UserRoleGrant type, CheckRoleScope type, checkRole, getCachedUserRoles, invalidateRoleCache
- `backend/src/middleware/requireRole.ts` - New middleware factory; no supabaseAdmin import
- `tests/integration/requireRole.test.ts` - 12 pure-function checkRole unit tests

## Decisions Made
- **Dynamic import in test file**: Static `import { checkRole }` would be hoisted before `process.env` assignments in ESM. Used `beforeAll` + dynamic import pattern (same as other tests in this project) to ensure env setup runs first before `env.ts` validation fires.
- **NULL-safe semantics are in `checkRole`, not the middleware**: The middleware delegates entirely to `checkRole`; scope semantics are centralized in one place.
- **`requireRole` does not import `supabaseAdmin`**: Verified — delegates to `getCachedUserRoles` → `getUserRoles` → `adminRpc` chain. Respects architecture constraint.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

**ESM module hoisting in test file:** Static imports are hoisted before `process.env` assignments, causing `env.ts` to fire before `ADMIN_INGEST_TOKEN` was set. Resolved by using the same `beforeAll` + dynamic import pattern already established in other test files (health.test.ts, xp.test.ts). Not a deviation — this is the established test pattern for this project.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `getCachedUserRoles`, `checkRole`, `invalidateRoleCache`, and `requireRole` are all exported and tested
- Plan 02 (contributor.ts + roles.ts + admin.ts cache invalidation) can proceed immediately
- No blockers

---
*Phase: 53-service-layer-requirerole-middleware*
*Completed: 2026-04-03*
