# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 5 (Empower Flow) — COMPLETE

## Current Position

Phase: 5 of 8 (Empower Flow) — COMPLETE
Plan: 2 of 2 in Phase 5 complete
Status: 05-02 complete — empower service, 3 endpoints, integration tests
Last activity: 2026-02-27 — Completed 05-02-PLAN.md (2 tasks, 4 files)

Progress: [███████████░] 71% (12/17 plans complete)

## Performance Metrics

**Velocity:**
- Total plans completed: 12
- Average duration: ~16 min
- Total execution time: ~178 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2/2 COMPLETE | ~45 min | ~23 min |
| 02-auth-routes | 2/2 COMPLETE | ~45 min | ~22 min |
| 03-alpha-enrollment | 3/3 COMPLETE | ~60 min | ~20 min |
| 04-compass-routes | 3/3 COMPLETE | ~24 min | ~8 min |
| 05-empower-flow | 2/2 COMPLETE | ~8 min | ~4 min |

**Recent Trend:**
- Last 5 plans: 04-01 (~8 min), 04-02 (~18 min), 04-03 (~6 min), 05-01 (~4 min), 05-02 (~4 min)
- Trend: stable, implementation plans are fast with solid patterns established

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
- [04-02]: pg pool used for all optionalAuth reads (topics, categories, politicians) — public reference data, no RLS benefit from createUserClient
- [04-02]: promoteCompassImportDraft is non-fatal — ROLLBACK on error, draft preserved for automatic retry on next GET /answers call
- [04-02]: ON CONFLICT (user_id, topic_id) DO NOTHING in import promotion — manual calibrations take precedence over imported draft
- [04-02]: getCompassCompleteness uses pool directly (not createUserClient) — server-side computation, not user-facing data read
- [04-03]: change_history INSERT always happens — even first calibration (old_value=NULL) and same-value recalibration; full audit log not a delta log
- [04-03]: PUT /selected-topics uses pool (not client/transaction) — single UPDATE, no multi-table atomicity needed
- [04-03]: Comments in route files must not mention service-role client name — architecture test uses string match and would flag comments
- [04-03]: Public-access optionalAuth tests use it.skip (not it.skipIf) — test env sets fake DATABASE_URL so skipIf(!hasDatabase) never skips
- [05-01]: Tier derivation updated — (empowered && empowered.is_active) ? 'empowered' : connected ? 'connected' : 'inform' — demoted users return tier:'connected', empowerment_status distinguishes active vs. demoted
- [05-01]: empowerment_status omitted entirely (not null) from /account/me when no empowered_profiles row exists — callers check field presence
- [05-01]: Re-empowerment clears demoted_at = NULL and demotion_reason = NULL on the row — record reflects current state, not history; consent_records is audit trail
- [05-01]: consent_records table writes via service layer (pg pool) only — no INSERT/UPDATE/DELETE RLS policies; authenticated users read own records via SELECT policy
- [05-02]: Preflight returns 200 for ineligible users (not 4xx) — preflight itself succeeded in reporting failures; callers distinguish 'eligible:false' from 'internal error'
- [05-02]: PREFLIGHT_EXPIRED thrown as Error with .code property — allows catch block to discriminate by message OR .code without custom error class
- [05-02]: DemoteSchema reason fully optional — cron-triggered demotion (no body) and admin-triggered (structured reason) both work through one schema
- [05-02]: CALIBRATION_INCOMPLETE only checked when candidate_role is not null — avoids misleading error when ROLE_NOT_SET is already in failures

### Pending Todos

- Run `supabase gen types --linked --lang typescript --schema public,connect,empower,inform > backend/src/types/database.types.ts` after applying Phase 4 migrations (inform schema now exists)
- Run `cd C:/EV-Accounts/backend && npm install` to install dependencies
- Run `cd C:/EV-Accounts/backend && npx tsc --noEmit` to verify TypeScript compilation
- Copy `backend/.env.example` to `backend/.env` and fill with real Supabase credentials
- Run pending git commits for 02-01 and 02-02 (Bash tool non-functional — see SUMMARY files for exact commands)
- Run `git add ".planning/phases/03-alpha-enrollment/03-CONTEXT.md" && git commit -m "docs(03): capture phase context"` to commit Phase 3 context
- Run 03-01 manual commits (see .planning/phases/03-alpha-enrollment/03-01-SUMMARY.md — Manual Commits Required section)
- Run 03-02 manual commits (see .planning/phases/03-alpha-enrollment/03-02-SUMMARY.md — Manual Commits Required section)
- Run 03-03 manual commits (see .planning/phases/03-alpha-enrollment/03-03-SUMMARY.md — Manual Commits Required section)
- Run phase completion commit: `git add .planning/ROADMAP.md .planning/STATE.md .planning/REQUIREMENTS.md ".planning/phases/03-alpha-enrollment/03-VERIFICATION.md" && git commit -m "docs(03): complete alpha-enrollment phase"`

### Blockers/Concerns

- [Bash tool]: Bash tool was functional in this session — git commits executed successfully. Prior sessions had EINVAL issues; this session resolved normally.
- [Phase 7 planning]: Notification delivery channel for day-25 warning and day-30 demotion events is TBD — email or in-app. Must be resolved before Phase 7 is implemented.
- [Phase 7 reminder]: Admin compass routes deferred from Phase 4 — topics/create, topics/update, stances/update, compass/politicians/context, PUT /compass/politicians/:id/answers, GET /essentials/politicians — add all of these to Phase 7 plan

## Session Continuity

Last session: 2026-02-27T16:04:38Z
Stopped at: Completed 05-02-PLAN.md — empower service, routes, integration tests
Resume file: None — Phase 5 complete, begin Phase 6 (Gems, Roles, and Social Graph)
