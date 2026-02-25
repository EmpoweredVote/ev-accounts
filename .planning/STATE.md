# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 2 — Auth Routes and Account Core

## Current Position

Phase: 1 of 8 (Foundation) — COMPLETE
Plan: 2 of 2 in Phase 1
Status: Phase 01-foundation complete, ready for Phase 02
Last activity: 2026-02-24 — Completed 01-02-PLAN.md (Server Bootstrap)

Progress: [██░░░░░░░░] 12% (2/17 plans)

## Performance Metrics

**Velocity:**
- Total plans completed: 2
- Average duration: ~23 min
- Total execution time: ~45 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2/2 COMPLETE | ~45 min | ~23 min |

**Recent Trend:**
- Last 5 plans: 01-01 (~25 min), 01-02 (~20 min)
- Trend: stable baseline established

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Pre-Phase 1]: Tier determined by child record presence, never status flag — eliminates invalid states by construction
- [Pre-Phase 1]: RLS is primary defense; Express middleware is second layer — neither is optional
- [Pre-Phase 1]: Empowerment and demotion are Postgres RPC functions only — chained JS awaits are explicitly forbidden
- [Pre-Phase 1]: service role key used for trusted writes only, never for reads that return data to users
- [01-01]: tolerance_rating masked via split-visibility view (connected_profiles_public) that structurally omits the column — tests assert ABSENCE not NULL
- [01-01]: account_standing: ('active','suspended','quarantined') — all 3 values in schema now (REQUIREMENTS.md FOUND-09 updated)
- [01-01]: Non-owning users access connected_profiles via connected_profiles_public view; base table is owner-only
- [01-01]: soft_delete_user cascades deleted_at AND sets is_active=false on empowered_profiles for immediate candidate page takedown
- [01-02]: JWKS-based JWT verification via createRemoteJWKSet — ES256-compatible (Supabase post May 2025 default), no per-request network call
- [01-02]: supabaseAdmin banned from src/routes/ — architecture test enforces this automatically on every test run
- [01-02]: Cache failure (Redis unavailable) falls back to in-memory without crashing API
- [01-02]: app exported from index.ts with conditional listen — enables supertest integration tests without port conflicts

### Pending Todos

- Run git commits manually for 01-01 AND 01-02 (Bash tool was non-functional in both sessions; exact commands in each SUMMARY.md Notes section)
- Run `cd C:/EV-Accounts/backend && npm install` to install dependencies
- Run `cd C:/EV-Accounts/backend && npx tsc --noEmit` to verify TypeScript compilation
- Copy `backend/.env.example` to `backend/.env` and fill with real Supabase credentials
- Run `supabase gen types --linked --lang typescript --schema public,connect,empower,inform > backend/src/types/database.types.ts` after applying migrations

### Blockers/Concerns

- [Bash tool]: Bash tool has been completely non-functional in both Phase 1 sessions due to EINVAL on temp directory writes. All files created successfully via Write tools; git commits are pending manual execution. This pattern will persist until the underlying temp directory issue is resolved.
- [Phase 3 planning]: Tolerance Rating cascade depth (one level vs. full chain) must be confirmed before invite schema is finalized.
- [Phase 7 planning]: Notification delivery channel for day-25 warning and day-30 demotion events is TBD — email or in-app. Must be resolved before Phase 7 is implemented.

## Session Continuity

Last session: 2026-02-24
Stopped at: Completed 01-02-PLAN.md (all files written; git commits pending manual execution)
Resume file: None
