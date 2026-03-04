# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-04 after v1.1 milestone start)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 9 — XP Schema & Core (v1.1)

## Current Position

Phase: 9 of 11 (XP Schema & Core)
Plan: 0 of 2 in current phase
Status: Ready to plan
Last activity: 2026-03-04 — v1.1 roadmap created (Phases 9–11)

Progress: ░░░░░░░░░░ 0% (v1.1 in progress — 0/5 plans complete)

## Performance Metrics

**Velocity (v1.0 reference):**
- Total plans completed: 18 (v1.0)
- Total phases: 8 (v1.0)

*v1.1 metrics will be tracked as plans complete.*

## Accumulated Context

### Decisions

Full key decisions log in PROJECT.md. Recent decisions affecting v1.1:

- XP ledger mirrors gem ledger pattern: append-only, advisory lock, denormalized balance on `connected_profiles`
- `award_xp` RPC is the single write path — no JS-chained awaits for XP writes
- Idempotency enforced at DB layer via unique constraint on `idempotency_key`
- `xp_in_level` and `xp_to_next_level` computed on read, not stored
- Level thresholds: 2k XP × 3 levels, 3k × 6 levels, 4k × 20 levels, 5k per level thereafter

### Pending Todos

- Run `supabase gen types` after Phase 9 migrations land
- Copy `backend/.env.example` to `backend/.env` and fill with real Supabase credentials

### Open Blockers

None blocking Phase 9.

## Session Continuity

Last session: 2026-03-04T00:00:00Z
Stopped at: v1.1 roadmap created — ready to plan Phase 9
Resume: `/gsd:plan-phase 9`
