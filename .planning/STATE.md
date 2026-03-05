# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-04 after v1.1 milestone start)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 10 in progress — XP API Routes (plan 1 of 2 complete)

## Current Position

Phase: 10 of 11 (XP API Routes) — In progress
Plan: 1 of 2 in phase 10 complete
Status: In progress
Last activity: 2026-03-05 — Completed 10-01-PLAN.md (XP award endpoint: service-key middleware, xpService, POST /api/xp/award)

Progress: ████░░░░░░ 48% (v1.1 in progress — 3/5 plans complete)

## Performance Metrics

**Velocity (v1.0 reference):**
- Total plans completed: 18 (v1.0)
- Total phases: 8 (v1.0)

**v1.1 progress:**
- Plans completed: 3 (09-01, 09-02, 10-01)
- Plans remaining: 2 (10-02 + Phase 11)

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

From 10-01 execution:
- Service keys optional in Zod env schema: avoids breaking existing integration tests that don't set service key env vars
- `SERVICE_KEY_MAP` built at module load time (not per-request): env vars static after process launch
- Per-key source authorization returns 422 (not 403): valid key + unauthorized source = caller usage error
- `XP_SOURCES` const array satisfies both `z.enum(XP_SOURCES)` and `typeof XP_SOURCES[number]` — single source of truth
- `award_xp` RPC row fields `id` and `current_level` remapped to `transaction_id` and `level` in `AwardXpResult`

### Pending Todos

- Run `supabase gen types` after Phase 9 migrations land (still pending — do before Phase 10 routes consume types)
- Copy `backend/.env.example` to `backend/.env` and fill with real Supabase credentials
- Run `tests/rls/xp_transactions.sql` against local Supabase when Docker available

### Open Blockers

None blocking Phase 10.

## Session Continuity

Last session: 2026-03-05T01:27:56Z
Stopped at: Completed 10-01-PLAN.md — XP award endpoint committed (7cd4a47, a006c9e)
Resume: Execute 10-02-PLAN.md
