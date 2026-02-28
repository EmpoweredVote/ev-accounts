# Empowered Accounts

## What This Is

The foundational account infrastructure for Empowered Vote. A three-tier system (Inform → Connected → Empowered) that every other platform feature attaches to. It operationalizes the platform's core values: pseudonymous civic participation, earned trust, and radical transparency for civic leaders — enforced at the database level, not as application-layer policies.

**v1.0 shipped 2026-02-28.** Complete from schema through public API: auth, enrollment, compass, empowerment, social graph, admin tool, and public candidate pages.

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

### Active

(No active requirements — v1.0 ships all 52 v1 requirements. See v2 and hardening list below.)

### Hardening / v1.1 Targets

- [ ] JWT logout TTL: access token valid ~1h after signOut — security review required before production
- [ ] Pre-existing TypeScript errors in cache.ts, inviteService.ts, auth.ts, tierGuards.ts, account.ts, social.ts — resolve before first real users
- [ ] Pre-existing architecture test flags on routes/auth.ts, compass.ts, connect.ts, social.ts — intentional pattern, needs documented exception or refactor
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

**Current state (v1.0):** ~10,200 lines of TypeScript (8,487 backend + 1,711 admin React). 182 files. 8 phases, 18 plans, 4 days to ship. Backend: Express 4.x, Supabase, Upstash Redis, pg. Admin: Vite + React + Tailwind v4.

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

---
*Last updated: 2026-02-28 after v1.0 milestone*
