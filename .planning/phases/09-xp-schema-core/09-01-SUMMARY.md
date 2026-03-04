---
phase: 09-xp-schema-core
plan: 01
subsystem: database
tags: [postgres, supabase, rls, migrations, xp, ledger, connect-schema]

# Dependency graph
requires:
  - phase: 06-gems-roles-social
    provides: gem_transactions ledger pattern and connected_profiles_public view that this phase extends
  - phase: 01-foundation
    provides: public.users table and connect schema that xp_transactions references
provides:
  - connect.xp_transactions append-only ledger table with idempotency enforcement
  - total_xp (BIGINT) and current_level (INT) columns on connected_profiles
  - Updated connected_profiles_public view exposing total_xp and current_level
  - RLS owner-read policy on xp_transactions (no write policies — all writes via award_xp RPC)
  - GRANT SELECT to authenticated and anon on xp_transactions
affects:
  - 09-02 (award_xp RPC depends on this table and connected_profiles columns)
  - 10-xp-api-routes (all Phase 10 routes read from xp_transactions and connected_profiles)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Append-only ledger with idempotency_key UNIQUE constraint (mirrors gem_transactions)"
    - "Denormalized balance columns (total_xp, current_level) for O(1) reads — atomically updated by SECURITY DEFINER RPC"
    - "anon GRANT SELECT with no anon RLS policy = empty set instead of permission-denied"
    - "DROP + recreate view pattern when adding columns to existing view"

key-files:
  created:
    - supabase/migrations/20260304000029_phase9_xp_schema.sql
  modified: []

key-decisions:
  - "Legacy xp column on connected_profiles left untouched — Phase 10 handles migration and removal"
  - "No write RLS policies on xp_transactions — all writes go through award_xp() SECURITY DEFINER RPC (migration 030)"
  - "anon role granted SELECT on xp_transactions with no RLS policy → returns empty set, not permission denied"
  - "total_xp stored as BIGINT (not INT) to handle high-volume XP accrual without overflow"
  - "xp_in_level and xp_to_next_level are computed on read, not stored as columns"

patterns-established:
  - "XP ledger mirrors gem ledger: append-only rows, denormalized balance, advisory lock in RPC"
  - "DROP + GRANT pattern: any view DROP must be followed by re-GRANT SELECT after CREATE"

# Metrics
duration: 15min
completed: 2026-03-04
---

# Phase 9 Plan 01: XP Schema Migration Summary

**append-only `xp_transactions` ledger with idempotency_key UNIQUE, `total_xp`/`current_level` columns on `connected_profiles`, updated `connected_profiles_public` view, and owner-read-only RLS**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-04T22:53:00Z
- **Completed:** 2026-03-04T23:08:00Z
- **Tasks:** 1 of 1
- **Files modified:** 1

## Accomplishments

- Created `connect.xp_transactions` append-only ledger table with all required columns, CHECK constraint (amount > 0), UNIQUE idempotency_key, and FK to `public.users` with ON DELETE CASCADE
- Added `total_xp BIGINT NOT NULL DEFAULT 0` and `current_level INT NOT NULL DEFAULT 0` to `connect.connected_profiles` (legacy `xp` column untouched)
- Dropped and recreated `connect.connected_profiles_public` view to include `total_xp` and `current_level` while continuing to omit `tolerance_rating`, `legal_name`, and `home_address`
- Enabled RLS with a single owner-read policy; both `authenticated` and `anon` granted SELECT (anon returns empty set via no-policy RLS)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create XP schema migration file** - `d1b3981` (feat)

**Plan metadata:** (pending — will be committed with docs commit)

## Files Created/Modified

- `supabase/migrations/20260304000029_phase9_xp_schema.sql` - XP ledger table, connected_profiles columns, view update, RLS policies, grants (7 sections, 147 lines)

## Decisions Made

- Legacy `xp` column on `connected_profiles` is intentionally preserved. Phase 10 will decide whether to migrate data from `xp` into `total_xp` and remove the legacy column. No migration risk in Phase 9.
- `total_xp` is `BIGINT` rather than `INT` to prevent overflow for power users accumulating large amounts across many events over time.
- The `anon` role receives a GRANT SELECT on `xp_transactions` even though no anon RLS policy exists. This matches the convention used elsewhere: anon gets an empty result set rather than a permission-denied error, making API behavior predictable.
- `idempotency_key` is a column-level UNIQUE constraint, not a separate table constraint, which auto-creates a btree index — no additional index is needed for idempotency lookups.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Docker Desktop is not installed on this machine, so `supabase db reset` could not be run to verify the migration applies cleanly. The local PostgreSQL 18 instance (running as a Windows service) had an unknown password, preventing direct psql verification.

Verification approach used instead: thorough manual SQL review against all must_haves, plus regex confirmation of key constraint patterns (`REFERENCES public.users(id)`, `idempotency_key TEXT NOT NULL UNIQUE`, `CREATE TABLE IF NOT EXISTS connect.xp_transactions`). The migration follows established patterns from migrations 008, 011, and 019 exactly, reducing risk of syntax errors.

When Docker is available, `supabase db reset` should be run to confirm:
- No migration errors
- `\d connect.xp_transactions` shows all columns and constraints
- `\d connect.connected_profiles` includes `total_xp` and `current_level`
- `SELECT column_name FROM information_schema.columns WHERE table_schema='connect' AND table_name='connected_profiles_public'` includes `total_xp`, `current_level`, does NOT include `tolerance_rating`
- `SELECT polname FROM pg_policies WHERE tablename='xp_transactions'` shows exactly one policy

## User Setup Required

None - no external service configuration required. This is a pure database migration.

## Next Phase Readiness

- `connect.xp_transactions` table ready for `award_xp()` SECURITY DEFINER RPC (Plan 09-02)
- `total_xp` and `current_level` columns on `connected_profiles` ready for atomic update by award_xp RPC
- `connected_profiles_public` view updated — frontend can read XP data for any non-deleted connected user
- No blockers for Plan 09-02

---
*Phase: 09-xp-schema-core*
*Completed: 2026-03-04*
