---
phase: 53-service-layer-requirerole-middleware
plan: 02
subsystem: api
tags: [express, roles, cache, redis, typescript, contributor]

# Dependency graph
requires:
  - phase: 53-01
    provides: roleService exports (getCachedUserRoles, checkRole, invalidateRoleCache, UserRoleGrant, CheckRoleScope)
provides:
  - GET /api/contributor/me — returns authenticated user's active role grants as bare array
  - POST /api/roles/check — checks role+scope permission, returns { permitted: boolean }
  - Cache invalidation wired into admin grant/revoke (immediate effect)
  - contributorRouter mounted at /api/contributor in index.ts
affects: [CTC, Civic Spaces, Contributor Portal, future requireRole middleware integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Contributor endpoint returns bare array (no { roles: [...] } wrapper) — matches CTC/Civic Spaces contract"
    - "POST /roles/check body: feature_scope IS the role slug — documented in CONTEXT.md"
    - "NULL-safe scope semantics: null jurisdiction_geoid/resource_id = unrestricted (passes any scope check)"
    - "Cache invalidation called AFTER RPC succeeds, BEFORE logAdminAction — safe ordering"

key-files:
  created:
    - backend/src/routes/contributor.ts
  modified:
    - backend/src/routes/roles.ts
    - backend/src/routes/admin.ts
    - backend/src/index.ts

key-decisions:
  - "GET /contributor/me returns bare array, not { roles: [...] } — matches external consumer contract"
  - "POST /roles/check body field named feature_scope but semantically IS the role slug per CONTEXT.md"
  - "invalidateRoleCache placed after RPC success, before logAdminAction — ensures cache is fresh before audit record"

patterns-established:
  - "Contributor router mounted between roles and social in index.ts"
  - "Cache invalidation is fire-and-forget safe (internally try/catch) — never throws"

# Metrics
duration: 3min
completed: 2026-04-03
---

# Phase 53 Plan 02: Service Layer + requireRole Middleware Summary

**GET /api/contributor/me and POST /api/roles/check wired up via roleService, with immediate cache invalidation on admin grant/revoke**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-03T15:43:40Z
- **Completed:** 2026-04-03T15:46:12Z
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- Created `contributor.ts` with GET /me returning bare array of active role grants mapped to `[{ role_slug, feature_scope, jurisdiction_geoid, resource_id }]`
- Added POST /check to `roles.ts` with `feature_scope` validation, getCachedUserRoles, NULL-safe scope building, and `{ permitted: boolean }` response
- Wired `invalidateRoleCache(user_id)` into admin grant/revoke after RPC success — grants/revokes take effect immediately
- Mounted contributor router at `/api/contributor` in `index.ts`
- All 12 Plan 01 unit tests still passing

## Task Commits

Each task was committed atomically:

1. **Task 1: Create GET /api/contributor/me and POST /api/roles/check endpoints** - `487939d` (feat)
2. **Task 2: Wire cache invalidation into admin grant/revoke and mount contributor router** - `e99aada` (feat)

**Plan metadata:** _(docs commit follows)_

## Files Created/Modified

- `backend/src/routes/contributor.ts` — New router: GET /me returns bare array of active role grants
- `backend/src/routes/roles.ts` — Added POST /check endpoint with requireAuth, feature_scope validation, scope-aware checkRole call
- `backend/src/routes/admin.ts` — Added invalidateRoleCache import + two call sites (grant, revoke handlers)
- `backend/src/index.ts` — Added contributorRouter import and mount at /api/contributor

## Decisions Made

- GET /contributor/me returns a bare array (not `{ roles: [...] }`) to match the contract CTC and Civic Spaces expect
- POST /roles/check body field `feature_scope` acts as the role slug — naming per CONTEXT.md
- Cache invalidation is placed after the RPC succeeds and before `logAdminAction` to ensure the audit record is written after the cache is cleared (safe ordering)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 53 is complete. The role enforcement layer is fully wired:
- `roleService.ts` — data + logic layer (Plan 01)
- `requireRole.ts` — Express middleware factory (Plan 01)
- `contributor.ts` — GET /me external API surface (Plan 02)
- `roles.ts` — POST /check external API surface (Plan 02)
- `admin.ts` — cache invalidated on grant/revoke (Plan 02)

Ready for downstream consumers (CTC, Civic Spaces, Contributor Portal) to integrate against `/api/contributor/me` and `/api/roles/check`.

---
*Phase: 53-service-layer-requirerole-middleware*
*Completed: 2026-04-03*
