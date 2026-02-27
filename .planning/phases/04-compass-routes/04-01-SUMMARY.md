---
phase: 04-compass-routes
plan: 01
subsystem: database
tags: [postgres, rls, supabase, migrations, rpc, plpgsql, express, typescript]

# Dependency graph
requires:
  - phase: 03-alpha-enrollment
    provides: connect.connected_profiles base table, verification_sessions with compass_import_draft, empower schema with RPC stubs
  - phase: 01-foundation
    provides: inform schema namespace, public.users, empower.empowered_profiles, pg pool, JWKS middleware pattern
provides:
  - inform schema with 9 tables (compass_categories, compass_topics, compass_topic_categories, compass_topic_roles, compass_stances, compass_responses, compass_change_history, politicians, politician_answers, politician_context)
  - RLS policies and grants for all 10 inform tables (8 public-read, 2 owner-only SELECT)
  - execute_empowerment and execute_demotion RPCs updated with compass visibility logic
  - get_calibration_lapsed_users with real Phase 4 query (Phase 7 adds timestamps)
  - POST /api/auth/complete-onboarding endpoint (idempotent, pg pool)
  - completed_onboarding in GET /me and PATCH /me response (connected_profile object)
  - optionalAuth middleware for unauthenticated-compatible routes
affects:
  - 04-02 (compass read routes depend on inform schema + optionalAuth)
  - 04-03 (compass write routes depend on inform schema + compass_responses table)
  - 05-empower-flow (execute_empowerment/execute_demotion now have real compass logic)
  - 07-admin-tool (get_calibration_lapsed_users will be replaced with timestamp-aware query)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "optionalAuth middleware: attaches identity if valid JWT present, never rejects — used for public-compatible routes"
    - "GENERATED ALWAYS AS (is_live) STORED: computed column for Phase 3 backward compat without data duplication"
    - "composite PK (user_id, topic_id) serves dual purpose as UNIQUE for ON CONFLICT upserts"
    - "append-only table pattern: compass_change_history has no updated_at column, never mutated after insert"
    - "phase stub replacement: CREATE OR REPLACE updates RPC bodies while preserving function signatures and grants"

key-files:
  created:
    - supabase/migrations/20260226000015_inform_schema.sql
    - supabase/migrations/20260226000016_inform_rls_grants.sql
    - supabase/migrations/20260226000017_rpc_updates_phase4.sql
  modified:
    - backend/src/routes/auth.ts
    - backend/src/routes/account.ts
    - backend/src/middleware/auth.ts

key-decisions:
  - "optionalAuth does not perform standing check — suspended users can still view public reference data (topics, politicians)"
  - "compass_responses and compass_change_history have no INSERT/UPDATE/DELETE RLS policies — all writes via pg pool or SECURITY DEFINER"
  - "GRANT SELECT on ALL TABLES IN inform grants table-level permission; RLS further restricts compass_responses and compass_change_history to owner-only rows"
  - "get_calibration_lapsed_users Phase 4 version uses EXISTS/NOT EXISTS — Phase 7 replaces with went_live_at timestamp window"

patterns-established:
  - "optionalAuth pattern: no 401 on missing/invalid token, attaches identity if valid, proceeds as guest otherwise"
  - "inform schema public-read RLS: USING (true) for reference tables, TO anon, authenticated"
  - "completed_onboarding: one-way flag set via dedicated endpoint, never returned at root level (nested in connected_profile)"

# Metrics
duration: 25min
completed: 2026-02-26
---

# Phase 4 Plan 01: Compass Schema Foundation Summary

**inform schema (9 tables) + RLS/grants + execute_empowerment/demotion compass visibility + optionalAuth middleware for unauthenticated compass access**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-02-26T00:00:00Z
- **Completed:** 2026-02-26T00:25:00Z
- **Tasks:** 2
- **Files modified:** 6 (3 created migrations, 3 updated backend files)

## Accomplishments

- Created all 9 inform schema tables with correct columns, constraints, FK dependencies, and indexes. compass_topics has is_active (GENERATED ALWAYS AS is_live STORED) for Phase 3 backward compat, version INT DEFAULT 1, and went_live_at for Phase 7 lapse window.
- Established RLS: 8 reference tables with public-read policies (anon + authenticated, USING (true)), 2 personal data tables (compass_responses, compass_change_history) with owner-only SELECT, no INSERT/UPDATE/DELETE policies on either. GRANT USAGE + SELECT on inform schema for both roles.
- Updated execute_empowerment and execute_demotion RPCs to atomically set compass_responses visibility = 'public' on empowerment and visibility = 'private' on demotion. Replaced get_calibration_lapsed_users placeholder with a real EXISTS/NOT EXISTS query.
- Added POST /api/auth/complete-onboarding (idempotent, uses pg pool, 403 NOT_CONNECTED for non-Connected users). GET /me and PATCH /me now include completed_onboarding in connected_profile response object.
- Exported optionalAuth middleware from middleware/auth.ts — attaches identity if valid JWT present, never returns 401, enables Plan 02 compass routes to serve both authenticated and unauthenticated users.

## Task Commits

Each task was committed atomically:

1. **Task 1: Inform schema migration + ALTER connected_profiles** - `db6dbed` (feat)
2. **Task 2: RPC updates + auth extensions + optionalAuth middleware** - `309cfdc` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `supabase/migrations/20260226000015_inform_schema.sql` - 9 inform tables + indexes + ALTER connected_profiles (completed_onboarding, selected_topic_ids)
- `supabase/migrations/20260226000016_inform_rls_grants.sql` - RLS enable on all 10 tables, 8 public-read + 2 owner-only SELECT policies, GRANT USAGE/SELECT on inform schema
- `supabase/migrations/20260226000017_rpc_updates_phase4.sql` - execute_empowerment + execute_demotion with compass_responses visibility updates, get_calibration_lapsed_users with real query
- `backend/src/routes/auth.ts` - Added pool import + POST /complete-onboarding endpoint
- `backend/src/routes/account.ts` - Added completed_onboarding to connected_profiles SELECT and response builder (both GET /me and PATCH /me)
- `backend/src/middleware/auth.ts` - Added optionalAuth export after requireAuth

## Decisions Made

- **optionalAuth skips standing check:** Suspended users can still view public reference data (topics, politicians). Standing enforcement only applies to routes that write or read personal data. This avoids an unnecessary DB query for every unauthenticated guest request.
- **No write RLS on compass_responses/compass_change_history:** All writes go through pg pool (service layer, bypasses RLS) or SECURITY DEFINER RPCs. This is consistent with the pattern established for invite_codes and invite_chains in Phase 3.
- **GRANT SELECT on ALL TABLES IN SCHEMA:** Table-level SELECT grant combined with RLS achieves correct result: anon gets the grant but RLS USING ((select auth.uid()) = user_id) returns nothing (auth.uid() is null for anon). Authenticated users see only their own rows on personal tables, all rows on reference tables.
- **Phase 4 simplified get_calibration_lapsed_users:** Returns any Empowered user missing any live topic response. Phase 7 will replace with timestamp-aware query using went_live_at for the 30-day window. Documented in migration comment.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. Migrations apply to the existing Supabase project. Backend code changes compile against existing types (database.types.ts regeneration noted as pending todo in STATE.md).

## Next Phase Readiness

- inform schema fully established — Plan 02 (compass read routes) can proceed immediately
- optionalAuth exported — Plan 02 compass routes can import it from middleware/auth.ts
- completed_onboarding in /me response — CompassV2 frontend onboarding flow can check this flag
- execute_empowerment and execute_demotion updated — Phase 5 Empower Flow will work correctly with compass visibility

Blockers/concerns for downstream phases:
- database.types.ts needs regeneration after migrations are applied: `supabase gen types --linked --lang typescript --schema public,connect,empower,inform > backend/src/types/database.types.ts`
- Bash tool non-functional in prior sessions (EINVAL on temp writes) — all commits in this plan completed successfully via git Bash

---
*Phase: 04-compass-routes*
*Completed: 2026-02-26*
