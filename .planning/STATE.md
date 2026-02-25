# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 3 — Alpha Enrollment

## Current Position

Phase: 2 of 8 (Auth Routes and Account Core) — COMPLETE
Plan: 2 of 2 in Phase 2
Status: Phase 02 complete, ready for Phase 03
Last activity: 2026-02-25 — Phase 2 complete, human verification approved

Progress: [████░░░░░░] 24% (4/17 plans)

## Performance Metrics

**Velocity:**
- Total plans completed: 4
- Average duration: ~22 min
- Total execution time: ~90 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2/2 COMPLETE | ~45 min | ~23 min |
| 02-auth-routes | 2/3 in progress | ~45 min | ~22 min |

**Recent Trend:**
- Last 5 plans: 01-01 (~25 min), 01-02 (~20 min), 02-01 (~20 min), 02-02 (~25 min)
- Trend: stable, ~20-25 min per plan

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
- [02-01]: authService.ts in lib/ is the permitted boundary for supabaseAdmin auth calls — not middleware/, not routes/
- [02-01]: Login response returns minimal profile stub (tier: inform, account_standing: active) — GET /api/account/me is authoritative
- [02-01]: signOut always returns 200 even if Supabase call fails — access token TTL is natural expiry fallback
- [02-01]: INVALID_CREDENTIALS for both wrong email and wrong password — OWASP enumeration protection
- [02-02]: tolerance_rating nested in connected_profile, never at root — structural privacy enforcement beyond RLS
- [02-02]: legal_name nested in empowered_profile, never at root — same structural enforcement
- [02-02]: PATCH /api/account/me returns 200 with body (not 204) — client needs server-computed updated_at
- [02-02]: Zod .object() without .strict() for PATCH — unknown fields stripped silently, not rejected
- [02-02]: display_name synced across public.users and connected_profiles on PATCH — two single-table updates acceptable for Alpha

### Pending Todos

- Run `cd C:/EV-Accounts/backend && npm install` to install dependencies
- Run `cd C:/EV-Accounts/backend && npx tsc --noEmit` to verify TypeScript compilation
- Copy `backend/.env.example` to `backend/.env` and fill with real Supabase credentials
- Run `supabase gen types --linked --lang typescript --schema public,connect,empower,inform > backend/src/types/database.types.ts` after applying migrations
- Run pending git commits for 02-01 and 02-02 (Bash tool non-functional — see SUMMARY files for exact commands)
- Run `git add ".planning/phases/03-alpha-enrollment/03-CONTEXT.md" && git commit -m "docs(03): capture phase context"` to commit Phase 3 context

### Blockers/Concerns

- [Bash tool]: Bash tool has been completely non-functional in both Phase 1 sessions and both Phase 2 sessions due to EINVAL on temp directory writes. All files created successfully via Write tools; git commits are pending manual execution. This pattern will persist until the underlying temp directory issue is resolved.
- [Phase 3 planning]: home_address field required during Connect flow — verify it exists in connect.connected_profiles schema before 03-01 planning begins.
- [Phase 7 planning]: Notification delivery channel for day-25 warning and day-30 demotion events is TBD — email or in-app. Must be resolved before Phase 7 is implemented.

## Session Continuity

Last session: 2026-02-25
Stopped at: Completed 02-02-PLAN.md (account routes, requireVerified middleware, integration tests)
Resume file: None
