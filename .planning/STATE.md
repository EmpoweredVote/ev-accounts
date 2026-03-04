# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-04 after v1.1 milestone start)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 9 complete — beginning Phase 10 (XP API Routes)

## Current Position

Phase: 9 of 11 (XP Schema & Core) — COMPLETE
Plan: 2 of 2 in phase 9 complete
Status: Phase 9 execution complete
Last activity: 2026-03-04 — Completed 09-02-PLAN.md (XP RPCs and test suite)

Progress: ███░░░░░░░ 40% (v1.1 in progress — 2/5 plans complete)

## Performance Metrics

**Velocity (v1.0 reference):**
- Total plans completed: 18 (v1.0)
- Total phases: 8 (v1.0)

**v1.1 progress:**
- Plans completed: 2 (09-01, 09-02)
- Plans remaining: 3 (Phase 10 + Phase 11)

## Accumulated Context

### Decisions

Full key decisions log in PROJECT.md. Recent decisions affecting v1.1:

- XP ledger mirrors gem ledger pattern: append-only, advisory lock, denormalized balance on `connected_profiles`
- `award_xp` RPC is the single write path — no JS-chained awaits for XP writes
- Idempotency enforced at DB layer via unique constraint on `idempotency_key`
- `xp_in_level` and `xp_to_next_level` computed on read, not stored
- Level thresholds: 2k XP × 3 levels, 3k × 6 levels, 4k × 20 levels, 5k per level thereafter

From 09-01 execution:
- Legacy `xp` column on `connected_profiles` left untouched — Phase 10 handles migration/removal
- `total_xp` is BIGINT (not INT) to prevent overflow for power users
- `anon` GRANT SELECT on `xp_transactions` with no RLS policy = empty set, not permission denied

From 09-02 execution:
- `calculate_level` uses `LANGUAGE sql` (not plpgsql) — IMMUTABLE qualifier enables Postgres caching/inlining
- `calculate_level` GRANT to anon — Phase 10 public XP endpoint needs it unauthenticated
- `award_xp` idempotency duplicate returns current profile state (not historical state at original award time)
- `award_xp` uses `RETURNS TABLE` to mix xp_transactions fields, calculate_level output, and is_duplicate flag

### Pending Todos

- Run `supabase gen types` after Phase 9 migrations land (still pending — do before Phase 10 routes consume types)
- Copy `backend/.env.example` to `backend/.env` and fill with real Supabase credentials
- Run `tests/rls/xp_transactions.sql` against local Supabase when Docker available

### Open Blockers

None blocking Phase 10.

## Session Continuity

Last session: 2026-03-04T23:17:00Z
Stopped at: Completed 09-02-PLAN.md — XP RPCs migration and test suite committed
Resume: `/gsd:plan-phase 10`
