---
phase: 41-vq-and-trivia-migration
plan: 02
subsystem: api
tags: [postgres, role, express, trivia, leaderboard, service-key]

# Dependency graph
requires:
  - phase: 41-01
    provides: "Pre-flight inspection confirming trivia already in ev-accounts; CTC uses direct DATABASE_URL; trivia_service role needed"
  - phase: 30-vq-confirmation
    provides: "requireServiceKey middleware and TRIVIA_SERVICE_KEY already wired in serviceKeyAuth.ts"
provides:
  - "trivia_service Postgres role with LOGIN, BYPASSRLS, search_path=trivia, full DML on trivia schema"
  - "GET /api/trivia/leaderboard-profiles endpoint (service-key gated, returns pseudonym/total_xp/level)"
  - "Migration file documenting role grants (password REDACTED)"
affects:
  - 41-03
  - 41-04

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CROSS JOIN LATERAL for set-based RPC calls: use calculate_level per row inline rather than N separate supabase.rpc() calls"
    - "Leaderboard endpoint shape: user_id, display_name, pseudonym, total_xp, level (no avatars — not yet stored)"

key-files:
  created:
    - "supabase/migrations/20260323000051_phase41_trivia_service_role.sql"
    - "backend/src/routes/trivia.ts"
  modified:
    - "backend/src/index.ts"

key-decisions:
  - "level is computed via CROSS JOIN LATERAL connect.calculate_level (IMMUTABLE) — not stored as column on connected_profiles; avoids N separate RPC calls in leaderboard query"
  - "Management API (POST https://api.supabase.com/v1/projects/{ref}/database/query) used for role DDL — supabase db query --linked not available in CLI 2.75; pooler TCP connections time out from local Windows env"
  - "Migration file stores grants only (idempotent), not CREATE ROLE — role created once via execute_sql with redacted password"
  - "LEFT JOIN connected_profiles with COALESCE: users not yet at Connected tier return total_xp=0, level=1 rather than being excluded from leaderboard"

patterns-established:
  - "Management API DDL pattern: curl POST to /v1/projects/{ref}/database/query with access token for all migrations that can't go through the pooler"

# Metrics
duration: 15min
completed: 2026-03-23
---

# Phase 41 Plan 02: trivia-service-role-and-leaderboard-endpoint Summary

**trivia_service Postgres role (BYPASSRLS, scoped to trivia schema) + GET /api/trivia/leaderboard-profiles endpoint returning pseudonym/XP/level via LATERAL join on calculate_level**

## Performance

- **Duration:** 15 min
- **Started:** 2026-03-23T06:49:17Z
- **Completed:** 2026-03-23T07:04:44Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- trivia_service Postgres role created: LOGIN, BYPASSRLS, search_path=trivia, full DML on existing + future trivia tables (ALTER DEFAULT PRIVILEGES)
- GET /api/trivia/leaderboard-profiles endpoint: service-key gated, up to 100 user_ids per call, returns pseudonym/total_xp/level using single SQL query with CROSS JOIN LATERAL
- TypeScript compiles clean (tsc --noEmit)

## Task Commits

1. **Task 1: Create trivia_service postgres role** - `4b5580c` (feat)
2. **Task 2: Add GET /api/trivia/leaderboard-profiles endpoint** - `1fba3eb` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified

- `supabase/migrations/20260323000051_phase41_trivia_service_role.sql` - Documents role grants (idempotent); CREATE ROLE executed once via management API with redacted password
- `backend/src/routes/trivia.ts` - New router: GET /leaderboard-profiles with requireServiceKey guard
- `backend/src/index.ts` - Registered triviaRouter at /api/trivia

## Decisions Made

- **LATERAL calculate_level over N RPC calls:** `connect.calculate_level` is IMMUTABLE — using `CROSS JOIN LATERAL` in the leaderboard query computes level per row in a single SQL round-trip. The alternative (N individual `adminRpc('calculate_level')` calls) would be O(N) network latency for a leaderboard call.
- **Management API for DDL:** `supabase db query --linked` does not exist in CLI 2.75. Pooler TCP connections time out from local Windows environment. Used `POST https://api.supabase.com/v1/projects/{ref}/database/query` with the access token from `.claude/settings.json` MCP config.
- **Grants-only in migration file:** The migration file contains only `GRANT` statements (idempotent) — no `CREATE ROLE` with password. Role was created once via the management API. This keeps the password out of version history entirely.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed non-existent `cp.level` column reference**

- **Found during:** Task 2 (building leaderboard endpoint)
- **Issue:** Plan's code template used `COALESCE(cp.level, 1)` — but `level` is not a column on `connect.connected_profiles`. It is computed by the `calculate_level` RPC (confirmed by reading account.ts lines 88-101).
- **Fix:** Replaced `cp.level` with `CROSS JOIN LATERAL connect.calculate_level(COALESCE(cp.total_xp, 0)) lv` and referenced `COALESCE(lv.level, 1)`.
- **Files modified:** `backend/src/routes/trivia.ts`
- **Verification:** tsc --noEmit clean; pg_roles query confirms function exists at `connect.calculate_level`
- **Committed in:** `1fba3eb` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Required fix — the query would have thrown a Postgres column-not-found error at runtime. LATERAL join is strictly better (single round-trip, uses existing IMMUTABLE function).

## Issues Encountered

- **Supabase CLI 2.75 missing `db query` subcommand** — `supabase db query --linked` does not exist. Fell back to management API (curl). Pattern documented in STATE.md for future plans.
- **Pooler TCP timeouts from local Windows env** — Both session pooler (5432) and transaction pooler (6543) timed out. Management API is the correct path for local DDL execution.

## Secure Values (do not commit to plaintext files)

The following value was generated during this plan and must be stored securely:

- **trivia_service connection string:** `postgresql://trivia_service:***REMOVED-SECRET***@aws-0-us-west-1.pooler.supabase.com:5432/postgres`

This connection string is needed for **Plan 04** (update CTC's `DATABASE_URL` environment variable on Render). Store in your password manager or Render's environment variable dashboard — do not commit to any file.

## Next Phase Readiness

- Plan 03 (RLS policies for validation_quests and trivia schemas) is fully unblocked
- Plan 04 (CTC DATABASE_URL update on Render) requires the trivia_service connection string above
- No blockers for Plans 03 or 04

---
*Phase: 41-vq-and-trivia-migration*
*Completed: 2026-03-23*
