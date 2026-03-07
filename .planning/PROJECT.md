# Empowered Accounts

## What This Is

The foundational account infrastructure for Empowered Vote. A three-tier system (Inform → Connected → Empowered) that every other platform feature attaches to. It operationalizes the platform's core values: pseudonymous civic participation, earned trust, and radical transparency for civic leaders — enforced at the database level, not as application-layer policies.

**v1.0 shipped 2026-02-28.** Complete from schema through public API: auth, enrollment, compass, empowerment, social graph, admin tool, and public candidate pages.

**v1.1 shipped 2026-03-04.** Unified XP ledger and leveling system: append-only ledger, atomic award RPC, tiered level calculation, public XP profile endpoint, and admin ledger view. Any feature repo can now award and read XP with idempotency guarantees.

**v1.2 shipped 2026-03-07.** CompassV2 backend compatibility, alpha hardening (clean types, JWT revocation, 90 clean tests), and full compass admin backend + React UI.

## Core Value

Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.

## Requirements

### Validated

- ✓ Supabase schema with RLS policies for all three tiers (public, connect, empower, inform schemas) — v1.0
- ✓ Full migration set via Supabase CLI — no manual schema changes, ever — v1.0
- ✓ `public.users` extending Supabase Auth, `connect.connected_profiles`, `empower.empowered_profiles` as additive child tables — v1.0
- ✓ Compass tables: `inform.compass_topics`, `inform.compass_stances`, `inform.compass_responses`, `inform.compass_change_history`, `inform.compass_topic_roles` — v1.0
- ✓ Connections, follows, roles, gems ledger, and verification session tables — v1.0
- ✓ Full backend API (all endpoints from API shape in design doc) — Express/TypeScript on Render — v1.0
- ✓ Atomic empowerment transaction: create empowered_profiles + batch visibility update + slug generation in a single DB transaction with full rollback on failure — v1.0
- ✓ Atomic demotion transaction: set is_active = false + batch compass visibility back to private — v1.0
- ✓ Calibration lapse enforcement: scheduled job notifies Empowered Accounts of new topics, demotes at 31-day mark (day-25 warning, day-30 final, day-31 demotion), re-empowers on request after completion — v1.0
- ✓ Invite-based Alpha enrollment: invite codes, invite chain tracking, inviter Tolerance Rating impact when invitee is sanctioned — v1.0
- ✓ `tolerance_rating` never returned in any API response to any user other than the account owner — v1.0
- ✓ `legal_name` never surfaced for Connected users; only after empowerment — v1.0
- ✓ Anonymous compass import flow: localStorage → database migration on Connect, with topic version mismatch handling — v1.0
- ✓ Admin tool (internal React app): invite management, account review, manual verification approvals, account standing, pilot cohort enrollment, invite chain visibility — v1.0
- ✓ `GET /api/health` endpoint — v1.0

- ✓ Append-only XP ledger table with source attribution (ctc_game, ctc_perfect_bonus, validation_quest, extensible) — v1.1
- ✓ Level calculation RPC: tiered thresholds — 2k XP × 3 levels, 3k × 6 levels, 4k × 20 levels, 5k × all thereafter — v1.1
- ✓ `POST /api/xp/award` — feature repos call this to grant XP; idempotent with transaction key — v1.1
- ✓ XP + current level returned on `GET /account/me` — v1.1
- ✓ `GET /api/xp/:userId` — public XP profile (level + total XP, no full ledger) — v1.1
- ✓ Admin tool: XP ledger tab on account detail page (source, amount, timestamp per entry) — v1.1

- ✓ Alpha hardening: database.types.ts regenerated, TypeScript strict mode 0 errors across backend + admin, JWT revocation integration-tested (blocklisted token rejected on next request), 90 architecture tests with 0 skips — v1.2
- ✓ CompassV2 backend compatibility: DELETE /api/compass/answers/me (soft-delete reset with deleted_at filter on all reads), GET /api/essentials/politicians (unauthenticated), POST /connect/compass-import extended for selected_topics — v1.2
- ✓ Compass admin backend: 12 routes for topic/stance/politician/category management, admin_create_topic_with_stances atomic RPC, migrations 026–029 — v1.2
- ✓ Compass admin React UI: Topics, Politicians, Categories pages with full CRUD, stance editor, live toggle, and per-topic answers + context — v1.2

### Active

<!-- v1.3 requirements — see REQUIREMENTS.md (created for next milestone) -->

### Still Deferred

- [ ] COMP-05: User-to-user compass compare (infrastructure in place; politician compare only in v1)
- [ ] CIVIC-02: Gem reserve cap (deferred for Alpha per CONTEXT.md)

### Out of Scope

- End-user frontend (Framer components) — user-facing UI lives in feature repos that call this API
- Third-party identity verification service (Stripe Identity, Persona, etc.) — deferred post-Alpha; invite chain is the v1 trust mechanism
- Phone carrier / SMS OTP verification — deferred; not needed while invite-only
- Communal Council suspension mechanics — accounts system exposes `account_standing` field; Council feature implements the logic
- Demotion public record handling (Symposium posts, Empowered Bills attribution) — per-feature downstream; accounts system sets `is_active = false` only
- Compass issue weighting (`weight` field on compass_responses) — future state, schema can accommodate later
- Multi-candidate compass overlay — rendering concern, no schema changes needed
- Gem per-feature closed economies and cross-feature transfer rules — gem ledger is built; economy rules are per-feature

## Context

Part of the Empowered Vote platform — a civic infrastructure project aimed at reducing political polarization and improving democratic participation.

**Current state (v1.2):** ~13,334 lines of TypeScript (backend/src + admin/src). 16 phases, 38 plans total. Backend: Express 4.x, Supabase, Upstash Redis, pg. Admin: Vite + React + Tailwind v4. Compass admin UI complete; migrations 026–029 pending apply to live DB; CompassV2 frontend API contract updates (CV2-01 through CV2-05) pending in CompassV2 repo.

**Pilot:** Bloomington, Indiana (Monroe County). Alpha cohort is small, invite-only, likely IU students and local civic participants. Data is manually curated at pilot scale.

**Platform philosophy constraints that affect implementation:**
- Tier is determined by presence of child record, never a status flag on a wide table
- RLS is primary defense; application checks are a second layer
- Equity of Opportunity: it will never cost money to Connect or Empower
- Memory over moderation: the invite chain is a permanent record
- Empowered users appear under legal names — the trade is explicit and non-negotiable

**Design doc:** `empowered-accounts-design.md` in repo root. Contains full data model SQL, API shape, user journeys, and open questions. Read before planning any phase.

**Primer:** `empowered-vote-primer.md` in repo root. Platform philosophy, schema conventions, infrastructure setup, and development principles. Read before writing any code.

## Constraints

- **Tech Stack**: TypeScript everywhere, strict typing, no `any` without justification — non-negotiable
- **Database**: Supabase (single project, schema-based separation). Migrations only via Supabase CLI. RLS always on.
- **Backend**: Express on Render. All routes `/api/` prefixed. `process.env.PORT` always. Health check required.
- **Cache**: Upstash Redis with in-memory fallback — Redis down must never crash the API
- **Auth**: Supabase Auth only. No custom auth. Service role key server-side only, never client-exposed.
- **Cost**: Unfunded nonprofit. Free tiers first. No paid verification services in v1. Minimize operational cost.
- **Security**: Privacy by default. Collect only what is necessary. tolerance_rating, legal_name, verification_method are internal-only fields — enforced at RLS and API layers.
- **Repo**: `empowered-accounts` on GitHub. `main` is production. `.env.example` always included.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Additive child tables (not status flags) | Tier is unambiguous — row exists or it doesn't. No invalid states possible. | ✓ Good — eliminated all tier ambiguity, single JOIN to confirm tier |
| Invite-only Alpha enrollment | Bot farm prevention without invasive verification. Human accountability chain. Scales to real verification later without schema change. | ✓ Good — worked as designed; invite chain + TR adjustment RPC shipped |
| Inviter Tolerance Rating impacted by invitee sanctions | Mechanical skin in the game. Referrers who don't vet invite people with intention, not convenience. | ✓ Good — adjust_inviter_tolerance_rating RPC shipped, one level only |
| Empowerment is atomic transaction or full rollback | Partial empowerment is never a valid state. A civic leader's public record must be complete or not exist. | ✓ Good — execute_empowerment RPC + preflight pattern works cleanly |
| Demotion public record deferred to downstream features | Accounts system sets is_active = false only. Symposiums, Bills, Awareness Exchange each decide attribution policy in their own context. | ✓ Good — correct boundary, no downstream coupling |
| Admin tool in this repo (not a separate repo) | Pilot-scale admin needs are tightly coupled to accounts. One repo keeps auth, RLS, and admin logic co-located. Separate later if admin grows. | ✓ Good — tight coupling was an asset at this scale |
| No end-user frontend in this repo | User-facing flows live in feature repos (Essentials, Compass, etc.) that consume this API. Keeps accounts scope clean and avoids Framer complexity here. | ✓ Good — clean API boundary maintained throughout |
| JWKS-based JWT verification (not static secret) | ES256-compatible with Supabase post May 2025 key rotation. No per-request network call via cached JWKS. | ✓ Good — works correctly, no production issues |
| supabaseAdmin banned from src/routes/ via architecture test | Prevents privilege escalation bugs in route files. Service role writes go through service layer only. | ✓ Good — caught pre-existing debt in compass/auth/connect/social routes |
| pg Pool for atomic transactions | Supabase JS client cannot issue BEGIN/COMMIT. Raw pg required for multi-table atomic writes. | ✓ Good — used in invite claim, empower flow, block user — all correct |
| Upstash Redis (@upstash/redis HTTP) not ioredis | Upstash requires HTTP client; ioredis TCP incompatible. In-memory fallback never crashes API. | ✓ Good — Redis failures transparent to users |
| Calibration lapse cron: day-31 demotion (override from day-30) | CONTEXT.md override to give users one extra day. Idempotency via ON CONFLICT (run_date) DO NOTHING. | ✓ Good — idempotency proven in code review |
| Role system: lookup table not ENUM | New roles added by INSERT (no DDL migration required). ENUM dropped after Phase 6 migration. | ✓ Good — flexible, tested via grant/revoke service layer |
| Social relationships: unified table with idx_social_rel_accepted partial index | Single EXISTS join in friends RLS covers all peer contexts. Mandatory for O(log n) policy performance. | ✓ Good — friends visibility enforced via RLS |
| Gem balance denormalized on connected_profiles | O(1) balance reads without ledger sum query. RPCs maintain atomically with advisory lock. | ✓ Good — correct tradeoff for Alpha scale |
| candidateService.ts uses supabaseAdmin (architecture test whitelist) | Public candidate pages need service-role select for cross-schema joins without user JWT. Explicit whitelist exception. | ✓ Good — documented, bounded exception |
| getAdminMe returns id + email (v1.0 gap fix) | Admin UI auth store needs user.id to be non-empty for future admin-scoped operations. | ✓ Good — non-crashing, LOW priority fix shipped before milestone close |
| XP ledger mirrors gem ledger: append-only, advisory lock, denormalized balance | Single write path (award_xp RPC) prevents double-award; O(1) balance reads on connected_profiles. | ✓ Good — consistent pattern across all ledgers in the system |
| calculate_level as IMMUTABLE LANGUAGE sql function | Pure arithmetic with CTE pattern; IMMUTABLE enables Postgres caching/inlining. plpgsql not usable with IMMUTABLE. | ✓ Good — no duplicated tier arithmetic anywhere in application layer |
| award_xp idempotency at DB layer (UNIQUE constraint + RPC pre-check) | Callers can safely retry on network failure without double-awarding; duplicate returns 200 with is_duplicate flag. | ✓ Good — no error responses on retry; calling services don't need retry guard logic |
| Service-key auth: per-key permittedSources, 422 on scope mismatch | Valid key + wrong source is a caller usage error, not an auth failure. SERVICE_KEY_MAP built at module load (not per-request). | ✓ Good — 422 gives precise signal; startup evaluation avoids per-request secret lookup |
| account/me xp field: object not integer (breaking change accepted) | Structured { total, level, xp_in_level, xp_to_next_level } enables frontend progress bar without extra call. Legacy integer removed. | ✓ Good — correct shape; CompassV2 frontend breaking change coordinated |
| calculate_level column name bug: .current_level → .level (audit fix) | award_xp returns current_level; calculate_level returns level. Silent zero-level bug caught by milestone audit before ship. | ✓ Good — audit process proved its value; permanent test guard not feasible (IMMUTABLE fn) |
| Soft-delete via deleted_at on compass_responses (not hard delete) | Preserves calibration data for recovery; reset_compass_answers sets deleted_at = now(); re-import sets deleted_at = NULL. All reads must filter with .is('deleted_at', null). | ✓ Good — reversible reset; filter pattern enforced in Phase 16 gap closure |
| SET search_path = '' on all new SECURITY DEFINER functions | Prevents search_path injection; all table references must be fully qualified (schema.table). Established as project standard in Phase 13. | ✓ Good — consistent across all Phase 13+ RPCs |
| is_active excluded from compass_topics INSERT | GENERATED ALWAYS AS (is_live) STORED — inserting it causes Postgres error. Must never appear in INSERT column list for compass_topics. | ✓ Good — caught during Phase 14; documented as project gotcha |
| .is('deleted_at', null) not .eq() for PostgREST null comparisons | PostgREST generates IS NULL for .is(); .eq(null) does not correctly produce IS NULL in generated SQL. | ✓ Good — Phase 16 gap closure; affects any future soft-delete query |
| Two-pass validation in admin atomic RPCs | Full input validation loop before any writes — guarantees all-or-nothing atomicity without partial state. Established in admin_create_topic_with_stances (Phase 14). | ✓ Good — pattern to reuse for any future multi-row admin RPC |

---
*Last updated: 2026-03-07 after v1.2 milestone*
