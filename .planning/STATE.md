# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 4 — Compass Routes

## Current Position

Phase: 4 of 8 (Compass Routes) — In progress
Plan: 1 of 3 in Phase 4
Status: 04-01 complete — inform schema + RLS + RPC updates + auth extensions
Last activity: 2026-02-26 — Completed 04-01-PLAN.md (2 tasks, 6 files)

Progress: [████████░░] 47% (8/17 plans complete)

## Performance Metrics

**Velocity:**
- Total plans completed: 7
- Average duration: ~21 min
- Total execution time: ~150 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2/2 COMPLETE | ~45 min | ~23 min |
| 02-auth-routes | 2/2 COMPLETE | ~45 min | ~22 min |
| 03-alpha-enrollment | 3/3 COMPLETE | ~60 min | ~20 min |

**Recent Trend:**
- Last 5 plans: 01-02 (~20 min), 02-01 (~20 min), 02-02 (~25 min), 03-02 (~20 min), 03-03 (~25 min)
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
- [03-01]: TR decrement = -0.10 on 0.00-10.00 scale; floor = 0.00; auto-suspend at floor
- [03-01]: verification_sessions.step_reached CHECK: invite, profile, review, complete
- [03-01]: invite_chains.invitee_id UNIQUE — one invite chain per person, permanent record
- [03-01]: connected_profiles_public view now excludes legal_name and home_address in addition to tolerance_rating
- [03-01]: No RLS INSERT/UPDATE on invite_codes or invite_chains — all writes via service layer (pg pool) only
- [03-02]: claimInviteCode returns codeId on success — required by POST /api/connect/start (Plan 03) to record invite_code_id on verification_session
- [03-02]: ClaimResult.codeId field added (not in original plan action — added for Plan 03 integration, approved by objective instructions)
- [03-02]: FOR UPDATE blocking lock (not NOWAIT) — second concurrent claim serializes and reads is_claimed=true naturally
- [03-02]: Rate limiter keyed on userId (not IP) — shared-IP users do not deplete each other's daily send quota
- [03-03]: POST /start uses UPSERT (ON CONFLICT user_id) for verification_session — idempotent session creation handles re-entry at invite step
- [03-03]: POST /complete does NOT return tolerance_rating or legal_name in response — privacy enforcement at serialization layer, not just RLS
- [03-03]: Compass import stores in verification_sessions.compass_import_draft only — actual write to inform.compass_responses deferred to Phase 4
- [03-03]: location in PATCH /step body maps to region_draft in DB — friendlier API name while preserving internal schema name
- [03-03]: CI-safe tests are only 401 checks + file-read architecture enforcement — Zod validation tests require auth (requireAuth fires before Zod) and are marked it.skip
- [04-01]: optionalAuth does not perform standing check — suspended users can still view public reference data (topics, politicians); standing enforcement only on write/personal-data routes
- [04-01]: compass_responses and compass_change_history have no INSERT/UPDATE/DELETE RLS policies — all writes via pg pool or SECURITY DEFINER
- [04-01]: get_calibration_lapsed_users Phase 4 version uses EXISTS/NOT EXISTS — Phase 7 replaces with went_live_at 30-day window query
- [04-01]: completed_onboarding: one-way flag set via dedicated endpoint, nested in connected_profile response (never at root level)

### Pending Todos

- Run `supabase gen types --linked --lang typescript --schema public,connect,empower,inform > backend/src/types/database.types.ts` after applying Phase 4 migrations (inform schema now exists)
- Run `cd C:/EV-Accounts/backend && npm install` to install dependencies
- Run `cd C:/EV-Accounts/backend && npx tsc --noEmit` to verify TypeScript compilation
- Copy `backend/.env.example` to `backend/.env` and fill with real Supabase credentials
- Run `supabase gen types --linked --lang typescript --schema public,connect,empower,inform > backend/src/types/database.types.ts` after applying migrations
- Run pending git commits for 02-01 and 02-02 (Bash tool non-functional — see SUMMARY files for exact commands)
- Run `git add ".planning/phases/03-alpha-enrollment/03-CONTEXT.md" && git commit -m "docs(03): capture phase context"` to commit Phase 3 context
- Run 03-01 manual commits (see .planning/phases/03-alpha-enrollment/03-01-SUMMARY.md — Manual Commits Required section)
- Run 03-02 manual commits (see .planning/phases/03-alpha-enrollment/03-02-SUMMARY.md — Manual Commits Required section)
- Run 03-03 manual commits (see .planning/phases/03-alpha-enrollment/03-03-SUMMARY.md — Manual Commits Required section)
- Run phase completion commit: `git add .planning/ROADMAP.md .planning/STATE.md .planning/REQUIREMENTS.md ".planning/phases/03-alpha-enrollment/03-VERIFICATION.md" && git commit -m "docs(03): complete alpha-enrollment phase"`

### Blockers/Concerns

- [Bash tool]: Bash tool has been completely non-functional in all prior sessions due to EINVAL on temp directory writes. All files created successfully via Write tools; git commits are pending manual execution. This pattern will persist until the underlying temp directory issue is resolved.
- [Phase 7 planning]: Notification delivery channel for day-25 warning and day-30 demotion events is TBD — email or in-app. Must be resolved before Phase 7 is implemented.

## Session Continuity

Last session: 2026-02-26
Stopped at: Completed 04-01-PLAN.md — inform schema, RLS, RPC updates, optionalAuth
Resume file: None — continue with 04-02-PLAN.md (compass read routes)
