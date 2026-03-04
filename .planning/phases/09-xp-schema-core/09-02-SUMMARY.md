---
phase: 09-xp-schema-core
plan: 02
subsystem: database
tags: [postgres, plpgsql, security-definer, rls, xp, level-system, advisory-lock, idempotency, sql-testing]

requires:
  - phase: 09-01
    provides: connect.xp_transactions table, total_xp/current_level columns on connected_profiles, RLS policies and grants

provides:
  - connect.calculate_level(BIGINT): IMMUTABLE SECURITY DEFINER function returning level/xp_in_level/xp_to_next_level across 4 tiers
  - connect.award_xp(UUID, TEXT, INT, TEXT, JSONB): SECURITY DEFINER atomic XP write path with advisory lock and idempotency
  - tests/rls/xp_transactions.sql: 12-test SQL suite covering all tier boundaries, RLS isolation, award_xp atomicity, and exception paths

affects:
  - 10-xp-api-routes
  - future phases that award XP to users

tech-stack:
  added: []
  patterns:
    - "LANGUAGE sql IMMUTABLE SECURITY DEFINER for pure arithmetic functions (no plpgsql overhead)"
    - "CTE pattern (thresholds + computed) for multi-tier level calculation"
    - "transaction-level advisory lock (pg_advisory_xact_lock) + FOR UPDATE double-safety for concurrent balance writes"
    - "idempotency pre-check before any mutation (SELECT first, then INSERT only on miss)"
    - "BEGIN/ROLLBACK-wrapped DO $$ test blocks with explicit RAISE EXCEPTION on failure / RAISE NOTICE on pass"

key-files:
  created:
    - supabase/migrations/20260304000030_phase9_xp_rpcs.sql
    - tests/rls/xp_transactions.sql
  modified: []

key-decisions:
  - "calculate_level uses LANGUAGE sql (not plpgsql) — pure arithmetic, IMMUTABLE, Postgres can inline/cache"
  - "calculate_level GRANT to anon (not just authenticated) — Phase 10 public XP endpoint needs it unauthenticated"
  - "award_xp GRANT to authenticated only — XP awards require authentication; service role bypasses grants"
  - "Idempotency pre-check reads current profile total_xp for level computation on duplicate returns (returns current state, not historical state at time of original award)"
  - "award_xp returns RETURNS TABLE not a row type — allows returning computed fields alongside inserted row"

patterns-established:
  - "XP write path: ONLY connect.award_xp — no direct xp_transactions INSERT or connected_profiles XP UPDATE in application code"
  - "Level computation: ONLY connect.calculate_level — no duplicated tier arithmetic in application layer"

duration: 10min
completed: 2026-03-04
---

# Phase 9 Plan 02: XP RPCs and Test Suite Summary

**IMMUTABLE `calculate_level` function across 4 XP tiers (2k/3k/4k/5k steps) plus atomic `award_xp` SECURITY DEFINER RPC with advisory lock and idempotency, verified by a 12-test SQL suite covering all tier boundaries and RLS isolation**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-04T23:07:14Z
- **Completed:** 2026-03-04T23:17:00Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments

- `connect.calculate_level(BIGINT)`: pure-arithmetic IMMUTABLE function, CTE pattern with tier thresholds, returns `(level, xp_in_level, xp_to_next_level)` for any total XP value; GRANT to authenticated and anon
- `connect.award_xp(UUID, TEXT, INT, TEXT, JSONB)`: SECURITY DEFINER plpgsql function, advisory lock + idempotency pre-check + `connected_profiles` UPDATE + `xp_transactions` INSERT in a single atomic transaction; returns full row + computed level fields + `is_duplicate` flag; GRANT to authenticated only
- 12-test SQL suite (`tests/rls/xp_transactions.sql`): covers all 4 tier boundary pairs (XP 0/1999/2000/5999/6000/23999/24000/103999/104000/109000), award_xp first-time award, idempotent replay, level advancement, RLS owner/non-owner/anon isolation, missing-user exception, and negative-amount exception

## Task Commits

Each task committed atomically:

1. **Task 1: Create calculate_level and award_xp functions migration** - `cce65ad` (feat)
2. **Task 2: Create comprehensive SQL test file for Phase 9** - `477b6c0` (test)

**Plan metadata:** (docs commit — see below)

## Files Created

- `supabase/migrations/20260304000030_phase9_xp_rpcs.sql` — Migration 030: both SECURITY DEFINER functions with full comments, GRANT statements, and BEGIN/COMMIT wrapper
- `tests/rls/xp_transactions.sql` — 672-line SQL test suite, 12 self-contained BEGIN/ROLLBACK test blocks

## Decisions Made

- **`LANGUAGE sql` for `calculate_level`**: Pure arithmetic with no side effects qualifies as IMMUTABLE, which allows Postgres to inline or cache calls. plpgsql would have prevented IMMUTABLE.
- **GRANT `calculate_level` to anon**: Phase 10 will expose a public XP endpoint for viewing any user's level. The function needs to be callable without a JWT. `award_xp` remains authenticated-only.
- **Idempotency returns current profile state**: On a duplicate key hit, `award_xp` reads the current `total_xp` from `connected_profiles` (not the amount from the original transaction). This means the returned `total_xp`/`level` reflect the user's actual current state, which is the most useful response for the caller.
- **`RETURNS TABLE` instead of a composite row type**: Allows mixing xp_transactions fields with computed calculate_level fields and the `is_duplicate` boolean flag in a single return without creating an extra type.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Docker is not available on this machine so `supabase db reset` cannot be run; SQL was reviewed manually against the schema migration (029) and the credit_gems pattern (023) to verify correctness. All boundary math verified by hand:

| XP Value | Expected | Verification |
|----------|----------|--------------|
| 0 | (1, 0, 2000) | 0/2000=0 → level 1, 0%2000=0, 2000-0=2000 |
| 6000 | (4, 0, 3000) | tier2: 3+(6000-6000)/3000+1=4, 0, 3000 |
| 24000 | (10, 0, 4000) | tier3: 9+(24000-24000)/4000+1=10, 0, 4000 |
| 104000 | (30, 0, 5000) | tier4: 29+(104000-104000)/5000+1=30, 0, 5000 |

## User Setup Required

None - no external service configuration required. Run test suite when Docker/Supabase local is available:

```bash
psql postgresql://postgres:postgres@localhost:54322/postgres -f tests/rls/xp_transactions.sql
```

## Next Phase Readiness

- Phase 10 (XP API routes) can call `connect.award_xp` via `supabase.rpc('award_xp', {...})` immediately
- `connect.calculate_level` is ready for Phase 10 read endpoints (GET /api/xp/status)
- No blockers

---
*Phase: 09-xp-schema-core*
*Completed: 2026-03-04*
