# Empowered Accounts

## What This Is

The foundational account infrastructure for Empowered Vote. A three-tier system (Inform → Connected → Empowered) that every other platform feature attaches to. It operationalizes the platform's core values: pseudonymous civic participation, earned trust, and radical transparency for civic leaders — enforced at the database level, not as application-layer policies.

## Core Value

Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Supabase schema with RLS policies for all three tiers (public, connect, empower schemas)
- [ ] Full migration set via Supabase CLI — no manual schema changes, ever
- [ ] `public.users` extending Supabase Auth, `connect.connected_profiles`, `empower.empowered_profiles` as additive child tables
- [ ] Compass tables: `inform.compass_topics`, `inform.compass_stances`, `inform.compass_responses`, `inform.compass_change_history`, `inform.compass_topic_roles`
- [ ] Connections, follows, roles, gems ledger, and verification session tables
- [ ] Full backend API (all endpoints from API shape in design doc) — Express/TypeScript on Render
- [ ] Atomic empowerment transaction: create empowered_profiles + batch visibility update + slug generation in a single DB transaction with full rollback on failure
- [ ] Atomic demotion transaction: set is_active = false + batch compass visibility back to private
- [ ] Calibration lapse enforcement: scheduled job notifies Empowered Accounts of new topics, demotes at 30-day mark, re-empowers on request after completion
- [ ] Invite-based Alpha enrollment: invite codes, invite chain tracking, inviter Tolerance Rating impact when invitee is sanctioned
- [ ] `tolerance_rating` never returned in any API response to any user other than the account owner
- [ ] `legal_name` never surfaced for Connected users; only after empowerment
- [ ] Anonymous compass import flow: localStorage → database migration on Connect, with topic version mismatch handling
- [ ] Admin tool (internal React app): invite management, account review, manual verification approvals, account standing, pilot cohort enrollment, invite chain visibility
- [ ] `GET /api/health` endpoint

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

Part of the Empowered Vote platform — a civic infrastructure project aimed at reducing political polarization and improving democratic participation. The accounts system is the prerequisite for every other feature: Connect Pillar (Civil Civics, Equal Slice, Common Grounds), Empower Pillar (Candidates, Bills, Awareness Exchange), and reputation systems (Veracity Rating, Tolerance Rating).

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
| Additive child tables (not status flags) | Tier is unambiguous — row exists or it doesn't. No invalid states possible. | — Pending |
| Invite-only Alpha enrollment | Bot farm prevention without invasive verification. Human accountability chain. Scales to real verification later without schema change. | — Pending |
| Inviter Tolerance Rating impacted by invitee sanctions | Mechanical skin in the game. Referrers who don't vet invite people with intention, not convenience. | — Pending |
| Empowerment is atomic transaction or full rollback | Partial empowerment is never a valid state. A civic leader's public record must be complete or not exist. | — Pending |
| Demotion public record deferred to downstream features | Accounts system sets is_active = false only. Symposiums, Bills, Awareness Exchange each decide attribution policy in their own context. | — Pending |
| Admin tool in this repo (not a separate repo) | Pilot-scale admin needs are tightly coupled to accounts. One repo keeps auth, RLS, and admin logic co-located. Separate later if admin grows. | — Pending |
| No end-user frontend in this repo | User-facing flows live in feature repos (Essentials, Compass, etc.) that consume this API. Keeps accounts scope clean and avoids Framer complexity here. | — Pending |

---
*Last updated: 2026-02-24 after initialization*
