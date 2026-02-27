---
phase: 04-compass-routes
plan: 02
subsystem: api
tags: [express, typescript, postgres, supabase, rls, compass, politicians]

# Dependency graph
requires:
  - phase: 04-01
    provides: inform schema (9 tables), RLS policies, optionalAuth middleware, pg pool
  - phase: 03-alpha-enrollment
    provides: connect.verification_sessions with compass_import_draft, connected_profiles with selected_topic_ids
provides:
  - All compass read routes (9 endpoints) mounted at /api/compass
  - compassService.ts with promoteCompassImportDraft and getCompassCompleteness
  - Lazy import draft promotion from Phase 3 compass-import flow into inform.compass_responses
  - Calibration completeness calculation with optional role scope filtering
affects:
  - 04-03 (compass write routes build on same router file and service layer patterns)
  - 07-admin-tool (getCompassCompleteness used by admin completeness views)
  - 05-empower-flow (compass visibility already set by execute_empowerment RPC from 04-01)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "pg pool for optionalAuth/public routes — no RLS benefit from createUserClient on public reference tables"
    - "createUserClient for requireAuth/owner routes — RLS enforces user_id = auth.uid() on compass_responses"
    - "Lazy import promotion: non-fatal try/catch with ROLLBACK, draft preserved on error for automatic retry"
    - "ON CONFLICT DO NOTHING guards manual calibrations from being overwritten by import draft"
    - "UUID_REGEX validation on parameterized :id routes before DB query"

key-files:
  created:
    - backend/src/lib/compassService.ts
    - backend/src/routes/compass.ts
  modified:
    - backend/src/index.ts

key-decisions:
  - "pg pool used for all optionalAuth reads — topics, categories, politicians are public reference data with no user-specific RLS"
  - "promoteCompassImportDraft is non-fatal: ROLLBACK on error, draft preserved, never re-throws — GET /answers always succeeds even when promotion fails"
  - "ON CONFLICT (user_id, topic_id) DO NOTHING: manual calibrations take precedence over imported draft, no false audit entries on skipped rows"
  - "getCompassCompleteness uses pg pool directly (not createUserClient) — server-side computation, not a user-facing data read"

patterns-established:
  - "compassService pattern: lib/ service functions take userId as string, use pool directly, return typed results"
  - "Lazy promotion pattern: side-effect before primary read, non-fatal, idempotent (draft cleared on success)"

# Metrics
duration: ~2min
completed: 2026-02-27
---

# Phase 4 Plan 02: Compass Read Routes Summary

**9 compass read-side endpoints (topics, categories, own answers, batch, selected topics, progress, politicians, politician answers/context) with lazy import draft promotion from Phase 3**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-27T07:21:04Z
- **Completed:** 2026-02-27T07:23:50Z
- **Tasks:** 2
- **Files modified:** 3 (2 created, 1 updated)

## Accomplishments

- Created `compassService.ts` with `promoteCompassImportDraft` (atomic transaction, non-fatal, ON CONFLICT DO NOTHING) and `getCompassCompleteness` (optional role scope filtering via compass_topic_roles join).
- Created `compass.ts` with all 9 read routes: 5 optionalAuth (topics, categories, politicians, politicians/:id/answers, politicians/:id/:topicId/context) using pg pool, and 4 requireAuth (answers, answers/batch, selected-topics, progress) using createUserClient.
- Mounted compassRouter at `/api/compass` in `index.ts`.
- Architecture constraint maintained: zero `supabaseAdmin` references in `routes/compass.ts`.

## Task Commits

Each task was committed atomically:

1. **Task 1: compassService.ts — import promotion + completeness** - `f792ce7` (feat)
2. **Task 2: Compass read routes + router registration** - `2ae45b7` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `backend/src/lib/compassService.ts` — `promoteCompassImportDraft` and `getCompassCompleteness` using pg pool; no supabaseAdmin
- `backend/src/routes/compass.ts` — 9 read routes with correct auth middleware; 426 lines
- `backend/src/index.ts` — Added compassRouter import and mount at `/api/compass`

## Decisions Made

- **pg pool for all optionalAuth reads:** Topics, categories, and politicians are public reference data. Using createUserClient for unauthenticated reads would require supabaseAdmin (banned from routes/), and RLS adds no value here. pg pool is simpler and correct.
- **promoteCompassImportDraft is non-fatal:** If the import promotion fails (e.g., DB transient error), GET /answers still returns the user's current responses. The draft is preserved for retry on the next call. This prevents a Phase 3 import issue from blocking the entire Compass feature.
- **ON CONFLICT DO NOTHING (not DO UPDATE):** Manual calibrations must not be overwritten by imported draft data. rowCount check before history insert prevents false audit entries when the upsert is a no-op.
- **getCompassCompleteness uses pool directly:** This is a server-side computation (admin/progress), not a user-facing data read that needs RLS enforcement. Pool access is appropriate here.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. All routes are code-only changes mounting to the existing Express server.

## Next Phase Readiness

- All compass read routes available — CompassV2 frontend can fetch topics, categories, politicians, and own calibrations
- compassService.ts provides the service layer foundation for Plan 04-03 write routes
- `promoteCompassImportDraft` is live — Phase 3 connect/compass-import data will be promoted transparently on first GET /answers
- Architecture test constraint maintained throughout: zero supabaseAdmin in routes/

---
*Phase: 04-compass-routes*
*Completed: 2026-02-27*
