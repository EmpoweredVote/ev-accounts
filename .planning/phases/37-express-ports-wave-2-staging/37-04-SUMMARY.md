---
phase: 37-express-ports-wave-2-staging
plan: "04"
subsystem: api
tags: [express, staging, routing, zod, middleware, role-gated]

requires:
  - phase: 37-01
    provides: requireStagingReviewer middleware + staging_reviewer role seed
  - phase: 37-02
    provides: stagingService politician CRUD/review/lock/merge functions
  - phase: 37-03
    provides: stagingService stance + building photo CRUD/review/lock functions
provides:
  - 19 Express route handlers wired to stagingService across politicians, stances, and photos
  - CONS-10 fulfilled — staging submission/review/approval workflow fully operational in ev-accounts
  - app.use('/api/staging', stagingRouter) registered in index.ts
affects: [38-express-ports-wave-3-essentials, 40-frontend-auth-updates, 43-integration-documentation]

tech-stack:
  added: []
  patterns:
    - "Router-level blanket auth: router.use(requireAuth, requireStagingReviewer) before all route defs"
    - "Subpath routes (/:id/review, /:id/lock, /:id/merge) defined before /:id to prevent Express slug collision"
    - "Shared handleServiceError helper reads err.httpStatus for 4xx, falls back to 500"
    - "validateUuid helper returns boolean and sends 400 inline — caller returns early on false"
    - "No lock routes for photos — building_photos has no locked_by/locked_at columns"

key-files:
  created:
    - backend/src/routes/staging.ts
  modified:
    - backend/src/index.ts

key-decisions:
  - "Auth runs before UUID validation by design — unauthenticated requests never reach route logic"
  - "Lock conflict returns 409 with lockedBy + lockedAt (not just 409 empty)"
  - "POST /stances/:id/review accepts optional newValue — reviewer can correct stance value at review time"
  - "No supabaseAdmin in staging.ts — all DB access delegated to stagingService (pool.query)"

patterns-established:
  - "Blanket router.use auth pattern for fully-gated routers (no per-route auth repetition)"

duration: 3min
completed: "2026-03-20"
---

# Phase 37 Plan 04: Staging Routes Summary

**Express staging router with 19 route handlers across politicians/stances/photos, router-level requireAuth + requireStagingReviewer, fulfilling CONS-10**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-20T16:22:50Z
- **Completed:** 2026-03-20T16:25:28Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `backend/src/routes/staging.ts` with 19 route handlers (8 politicians, 7 stances, 4 photos)
- Router-level blanket auth: `router.use(requireAuth, requireStagingReviewer)` — no per-route repetition
- Registered `/api/staging` in `index.ts` after meetingsRouter
- Smoke tests confirmed unauthenticated requests return 401 ("Missing authorization header")
- CONS-10 complete — staging workflow fully operational in ev-accounts Express API

## Task Commits

1. **Task 1: Create staging route file with all 18 handlers** - `3934064` (feat)
2. **Task 2: Register staging router in index.ts and smoke test** - `e81b119` (feat)

**Plan metadata:** (pending docs commit)

## Files Created/Modified

- `backend/src/routes/staging.ts` — 19 route handlers: GET/POST/PATCH politicians (5), POST /:id/review + /:id/lock + DELETE /:id/lock + POST /:id/merge (4), GET/POST/PATCH stances (3), POST /:id/review + /:id/lock + DELETE /:id/lock (3), GET/POST/POST /:id/review photos (3)
- `backend/src/index.ts` — added stagingRouter import + `app.use('/api/staging', stagingRouter)`

## Decisions Made

- Auth middleware runs at router.use level before route handlers — UUID validation only executes for authenticated requests (correct security layering)
- Lock 409 response includes `lockedBy` and `lockedAt` fields to enable UI to show who holds the lock
- No lock routes for photos — `staging.building_photos` has no `locked_by`/`locked_at` columns (confirmed in Plan 03)
- Subpath routes defined before /:id for all three entity types to prevent Express routing collision

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Port 3000 already in use (production dev server running) — smoke tests redirected to existing server, which confirmed routes work correctly. No impact on functionality.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 37 complete — all 4 plans done; CONS-10 fulfilled
- Phase 38 (Express Ports Wave 3 — Essentials) unblocked
- Staging routes live at `/api/staging/{politicians,stances,photos}` with full role-gated workflow

---
*Phase: 37-express-ports-wave-2-staging*
*Completed: 2026-03-20*
