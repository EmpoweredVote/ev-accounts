# Empowered Accounts

## What This Is

The foundational account infrastructure for Empowered Vote. A three-tier system (Inform → Connected → Empowered) that every other platform feature attaches to. It operationalizes the platform's core values: pseudonymous civic participation, earned trust, and radical transparency for civic leaders — enforced at the database level, not as application-layer policies.

**v1.0 shipped 2026-02-28.** Complete from schema through public API: auth, enrollment, compass, empowerment, social graph, admin tool, and public candidate pages.

**v1.1 shipped 2026-03-04.** Unified XP ledger and leveling system: append-only ledger, atomic award RPC, tiered level calculation, public XP profile endpoint, and admin ledger view. Any feature repo can now award and read XP with idempotency guarantees.

**v1.2 shipped 2026-03-07.** CompassV2 backend compatibility, alpha hardening (clean types, JWT revocation, 90 clean tests), and full compass admin backend + React UI.

**v1.3 shipped 2026-03-15.** Production Alpha live; encrypted location infrastructure (pgcrypto Vault + PostGIS); three-currency gem system; universal Connected Account signup portal; 21 compass topics + 30 politicians + 1,000+ stance records seeded to production.

**v1.4 shipped 2026-03-17.** Full civic identity profile page for Alpha users; Verification Rating system (VQ accuracy tracking, Red Gem Quest gating, 30-day hold enforcement); atomic `POST /api/vq/confirm-stance` with deadlock-safe RPCs; CTC + VQ integrations live-tested end-to-end; Profile Hub UI with feature cards, Civic Spaces jurisdiction display, and dark mode.

**v1.5 shipped 2026-03-19.** Referral dashboard card (locked/waiting/active states driven by `GET /api/referral`); `docs/COMPASSV2-INTEGRATION.md` — 745-line canonical CompassV2 reference replacing COMPASS_CONTRACT.md; `docs/ESSENTIALS-INTEGRATION.md` — 654-line integration guide covering Inform-baseline / Connected-enhanced pattern with jurisdiction detection, XP/gem opt-in, and TIGER/Line GEOID formats.

**v1.9 shipped 2026-04-06.** Delegated authority system: geo-scoped and resource-scoped roles (`compass_stance_editor`, `campaign_manager`, `essentials_data_editor`, `ctc_content_editor`, `volunteer`); `requireRole()` middleware with NULL-safe jurisdiction check and Redis caching; full admin grant/revoke UI with typeahead and audit dashboard; role-gated contributor endpoints with jurisdiction enforcement via live `offices→districts` JOIN; contributor portal at `app.empowered.vote/contributor`; `POST /api/roles/check` gate endpoint for Civic Spaces integration.

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

- ✓ Live Alpha deployment — migrations 026–036 applied to production; idempotent `applyMigrations.ts`; six-step `DEPLOY.md` cold-start runbook; smoke test 4/4 pass — v1.3
- ✓ CompassV2 API contract — Bearer token auth (JWKS) on all routes; NUMERIC(3,1) compass values; `completed_onboarding` + structured `xp` on GET /me; `docs/COMPASS_CONTRACT.md` — v1.3
- ✓ Location infrastructure — encrypted lat/lng on `connected_profiles` (pgcrypto via Supabase Vault); PostGIS Indiana TIGER/Line boundaries; `upsert_user_location` + `resolve_user_jurisdiction` RPCs; zero-leakage architecture test; `POST /connect/set-location` + `GET /me/jurisdiction` — v1.3
- ✓ empowered_profiles politician schema — 9 new columns on `inform.politicians`; full district/jurisdiction/vacancy field set; `GET /api/essentials/politicians` returns all new fields; 30 politicians + 588 stance values + 500 reasoning rows seeded — v1.3
- ✓ Multi-currency gem system — yellow/blue/red ledger with `gem_type` enum; `POST /api/gems/award` with per-key `permittedTypes`; balance-always-0 bug fixed; CTC migration documented — v1.3
- ✓ Central profile page — `GET /api/account/profile/:userId` (public) + `GET /api/account/profile/me` (owner); `Inform→Connected` promotion with audit log; admin search + PromotionsPage — v1.3
- ✓ Public Auth Hub — `accounts.empowered.vote` rebranded as universal Connected Account portal; tier-based routing; `signup_with_invite` RPC; `?redirect=` with trusted-domain validation; CTC + VQ onboarding docs — v1.3

- ✓ Verification Rating schema — `verification_rating` (INT default 60, max 150) + `vq_hold_until` on `connected_profiles`; `vq_hold_active` + `red_gem_quests_unlocked` derived booleans on `/me`; 90 threshold unlocks Red Gem Quests; rating 0 sets 30-day hold — v1.4
- ✓ `POST /api/vq/confirm-stance` — atomic `confirm_vq_stance` SECURITY DEFINER RPC; advisory locks (sorted UUID, deadlock-safe); Red Gems to correct answerers; ±VR adjustments with cap/floor; confirmed stance upsert to `inform.politician_answers`; idempotent replay via `vq_confirmation_results` — v1.4
- ✓ Admin VR override controls — `PATCH /api/admin/accounts/:userId/verification-rating` + AccountDetailPage inline editor; Zod cross-field validation; audit trail via `logAdminAction` — v1.4
- ✓ CTC + VQ integrations live-tested 2026-03-17 — CTC: XP +100, is_duplicate:false, replay confirmed; VQ: VR +3, Red Gem awarded, replayed:true on replay — v1.4
- ✓ Profile Hub UI — full civic identity page: tier/level/XP/gems/VR; location address form → `POST /connect/set-location`; 6 feature hub cards; Civic Spaces jurisdiction pills; dark mode toggle; accessible at `accounts.empowered.vote/profile` — v1.4

- ✓ Referral dashboard card — locked (level < 2), waiting (invitee < level 2), active (code + one-click copy); all three states driven by `GET /api/referral`; `requireConnected` middleware gates Inform-tier users — v1.5
- ✓ `docs/COMPASSV2-INTEGRATION.md` — 745-line canonical CompassV2 integration reference: Auth Hub redirect flow, 16 endpoints with TypeScript shapes, tier access rules, jurisdiction "never ask for address" (first-class Section 7), 8 inline anti-patterns; `COMPASS_CONTRACT.md` hard-deleted — v1.5
- ✓ `docs/ESSENTIALS-INTEGRATION.md` — 654-line integration reference: three-branch `detectUserState()` (inform / connected_with_jurisdiction / connected_no_jurisdiction), "Inform is the unconditional baseline" principle, opt-in XP/gem award endpoints, all 10 jurisdiction fields with TIGER/Line GEOID formats and production examples — v1.5

- ✓ `ESSENTIALS_SERVICE_KEY` provisioned in Render + `.env.example` updated; `POST /api/xp/award` smoke-tested HTTP 200 with `"essentials-rep-lookup"` source — v1.9

- ✓ TIGER 2024 PostGIS geofencing pipeline — `essentials.geo_districts` (GIST-indexed), `connect.user_districts` (per-user cache), `resolve_user_districts` + `cache_user_districts` RPCs; 172 CA legislative polygons (80 Assembly + 40 Senate + 52 US House CD119) + 975 school district polygons (unified/elementary/secondary) — v2.2
- ✓ Path 0 in `GET /representatives/me` — `tiger_geoid` join on `(tiger_geoid, district_type)`; eliminates live PostGIS on hot path for cached users; fire-and-forget self-promotion from Path 1.5 — v2.2
- ✓ Geofencing wired fail-open into both location-write flows — `POST /connect/set-location` (Connected) + `PATCH /account/location-hint` (Inform); `GET /api/account/districts` + `GET /api/account/school-district` endpoints; Inform `POST /account/set-location` — v2.2
- ✓ Profile Location tab — tier-aware on `login.empowered.vote/profile`; `SchoolDistrictSection` with Google search links; City Council display; recalibration controls; operator recache CLI (`--dry-run/--before/--user`) — v2.2
- ✓ Role infrastructure: `feature_scope` + `jurisdiction_geoid` + `resource_id` on `public.user_roles`; `grant_role`/`revoke_role`/`get_user_roles` SECURITY DEFINER RPCs; `public.role_audit_log` table; 5 role types seeded — v1.9
- ✓ `requireRole()` middleware factory with NULL-safe jurisdiction check (`IS NULL OR IS NOT DISTINCT FROM`) and Redis-backed caching; `checkRole()` pure function tested across all scope combinations; `GET /api/contributor/me` + `POST /api/roles/check` endpoints — v1.9
- ✓ Admin grant/revoke UI — role assignment form with user typeahead, jurisdiction chips from stored districts, politician picker for campaign_manager; global audit dashboard filterable by feature_scope/jurisdiction/date — v1.9
- ✓ `PUT /api/compass/stances/:politicianId` — compass_stance_editor and campaign_manager gated; jurisdiction-scoped via live `offices→districts` JOIN; appends to `role_audit_log` — v1.9
- ✓ `PATCH /api/essentials/politicians/:id` — essentials_data_editor gated; restricted field whitelist (bio, office_title, photo_origin_url, preferred_name); fail-CLOSED on NULL politician geoid — v1.9
- ✓ CTC + Civic Spaces integration: `GET /api/roles/me` (unfiltered) and `POST /api/roles/check` as canonical gate endpoints; `GET /api/contributor/me` filters to 3 contributor roles only — v1.9
- ✓ Contributor portal at `app.empowered.vote/contributor`: dashboard with role grant cards, Compass Editor (jurisdiction-scoped), Candidate Coordinator (single-politician), Essentials Editor (field-level bio editor) — v1.9

### Validated (v2.6)

**Milestone: v2.6 Data Quality & Elections** (Phases 87–90, 99) — shipped 2026-06-05.

- ✓ SACC-01: Stance accuracy audit covering all ~1,049 politicians — 255 flagged, three priority tiers — Phase 87
- ✓ SACC-02: All confirmed-inversion politicians individually re-researched and corrected with real sources — Phase 88
- ✓ SACC-03: Party string normalized — Democrat → Democratic, 775 rows, SELECT DISTINCT party clean — Phase 88
- ✓ SACC-04: Five-chairs framing baked into researcher agent (research-stances SKILL.md) — Phase 87
- ✓ GAPF-01: Gap-fill audit — 440 politicians with < 10 stances, all classified (Tier 1/2/3) — Phase 89
- ✓ GAPF-02: Missing stances ingested for all 50 Tier 1 politicians; every stance has context + source — Phase 89
- ✓ FINA-01: finance_summary JSONB column on essentials.politicians (migration 268) — Phase 90
- ✓ FINA-02: FEC ingestion for 209/258 federal politicians (44 no FEC ID, 5 persistent timeouts) — Phase 90
- ✓ FINA-03: GET /api/essentials/politicians returns finance_summary; null for non-federal — Phase 90
- ✓ ELEC-01: Elections page human-verified via Playwright (SLC address: Local + State + Federal races) — Phase 99
- ✓ ELEC-02: All verification issues resolved (zero issues found in Wave 1) — Phase 99
- ✓ ELEC-03: Elections feature declared shipped; MILESTONES.md updated — Phase 99

### Deferred to v2.0

- [ ] VR-F01: VR admin dashboard — visualize Verification Rating distribution, holds, outliers
- [ ] COMP-05: User-to-user compass compare API — endpoint comparing two accounts' responses on shared topics

### Still Deferred

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

**Current state (v2.8):** ~80,000 lines of TypeScript (project-wide). 107 phases, 110+ plans total. Backend: Express 4.x, Supabase, Upstash Redis, pg, PostGIS. Admin: Vite + React + Tailwind v4 (dark mode, login.empowered.vote). App: Vite + React (`app.empowered.vote` — includes contributor portal at `/contributor`). Migrations 026–291 applied to production. 21 live compass topics, ~1,076 politicians with stance data (100 senators + 43 2026 candidates + 39 CA city officials + 27 DC officials + state/local officials), full role system live. CA + DC TIGER geofencing live (8 DC ward polygons added via dc_ward layer). inform.inform_profiles live, yellow Inform profile page live. FEC finance data live on 209/258 federal politicians + Eleanor Holmes Norton. Elections Central page live at `/elections` with Utah 2026 Primary seeded.

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
- **Repo**: `empowered-accounts` on GitHub. `master` is production. `.env.example` always included.

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
| verification_rating default 60 + 90 Red Gem threshold | Baseline "unverified" score; 90 threshold gives achievable unlock without rewarding luck. Floor 0 triggers 30-day hold. | ✓ Good — calibrated defaults; live-tested v1.4 |
| No nested SECURITY DEFINER calls in confirm_vq_stance | Gem INSERT + balance UPDATE done inline rather than calling credit_gems RPC — nested SECURITY DEFINER unreliable in Postgres. | ✓ Good — established as project rule for all future atomic RPCs |
| Advisory locks on combined user set in sorted UUID order | All users (correct + incorrect) locked before any writes; sorted order prevents deadlocks in concurrent calls. | ✓ Good — Phase 28; mandatory pattern for any future multi-user atomic RPC |
| Per-user idempotency sub-key: main_key:uid | Prevents double-crediting when a user appears in multiple concurrent VQ confirmation calls sharing the same parent key. | ✓ Good — Phase 28; apply whenever a single idempotency key covers multiple rows |
| Idempotency pre-check before lock acquisition | Cached replay result returned immediately before any advisory locks — cheapest possible path for duplicate calls. | ✓ Good — Phase 28; pattern to apply to all future idempotent RPCs |
| Admin app dual-purpose (/admin/* + /profile, /login, /signup) | Profile Hub served from admin app for Alpha; Framer is production end-user frontend. Acceptable at pilot scale. | ⚠ Revisit — separate /profile to Framer or dedicated frontend for production |
| Integration guide format: 10-section structure | Quick ref → context → auth → reads → writes → profile → jurisdiction → migration → errors → checklist. Established with COMPASSV2-INTEGRATION.md and ESSENTIALS-INTEGRATION.md. | ✓ Good — consistent structure across both guides; easy for AI/devs to navigate |
| Anti-patterns inline at point of relevance | 8 blockquotes in CompassV2 guide placed at exact endpoint/pattern where mistake would occur — not consolidated at bottom. | ✓ Good — prevents AI from making the mistake at the point of the relevant implementation decision |
| COMPASS_CONTRACT.md hard-deleted (no symlink) | Described wrong auth pattern (direct POST /auth/login). Replacement is structurally different; any pointer would cause confusion. | ✓ Good — clean break; one canonical reference |
| Inform is the unconditional baseline for partner features | Partner apps must be fully functional for anonymous users; Connected enhances, never gates. Established in ESSENTIALS-INTEGRATION.md. | ✓ Good — correct platform philosophy enforced at documentation layer |
| Never prompt for location consent in partner apps | Accounts app owns location consent exclusively. Essentials/CompassV2 read jurisdiction if present; show address input if null. | ✓ Good — single consent owner prevents double-prompting |
| Numeric TIGER/Line GEOIDs as canonical format | `"1807"` for Indiana's 7th congressional district, not state-abbreviation notation. Documented with production examples. | ✓ Good — eliminates format ambiguity for Essentials/partner implementors |
| NULL-safe role jurisdiction check: `IS NULL OR IS NOT DISTINCT FROM` | NULL-scope grants match any jurisdiction (global). IS NOT DISTINCT FROM handles NULL equality; standard `=` fails for NULLs. | ✓ Good — single `checkRole()` function handles all NULL-scope and scope-match cases; v1.9 |
| District-join for jurisdiction lookup, never `home_jurisdiction_geoid` | `home_jurisdiction_geoid` is NULL on all 2,577 essentials.politicians rows. Always JOIN through `essentials.offices → essentials.districts` to get geo_id. | ✓ Good — Phase 58-05 fixed all scoped queries; `getDistrictGeoidForPolitician` is canonical helper; v1.9 |
| fail-open for compass_stance_editor, fail-CLOSED for essentials_data_editor | Compass has console.warn + null return when politician geoid is missing (Alpha acceptable). Essentials returns 403 always on NULL geoid — bio edits are higher-stakes. Different security profiles for different risk levels. | ✓ Good — intentional asymmetry documented; backport to compass is v2.0 tech debt; v1.9 |
| Contributor portal embedded in app/ (not standalone Vite app) | Alpha has app/ already running; separate contributors.empowered.vote would require new Render service, DNS, and CI. Acceptable for pilot scale. | ⚠ Revisit — standalone domain (contributors.empowered.vote) if portal grows beyond Alpha; v1.9 |
| GET /api/contributor/me filters to 3 contributor roles only | Portal only serves compass_stance_editor, campaign_manager, essentials_data_editor. CTC (ctc_content_editor) and Civic Spaces (volunteer) use GET /api/roles/me or POST /api/roles/check. Prevents portal from becoming a catch-all. | ✓ Good — clean separation; integration guide documents correct endpoints per consumer; v1.9 |
| PostGIS calls in SECURITY DEFINER must use `public.` prefix | `SET search_path = ''` means no implicit schema; all PostGIS functions must be `public.ST_Contains`, `public.ST_SetSRID`, etc. | ✓ Good — established as geospatial standard; v2.2 |
| `tiger_geoid` non-unique — always join on `(tiger_geoid, district_type)` | SLDL and SLDU share geoid format (06NNN); assembly D20 + senate D20 both have `tiger_geoid='06020'`. Single-column join silently drops rows. | ✓ Good — mandatory dual-column join; documented in Path 0 implementation; v2.2 |
| `DROP FUNCTION IF EXISTS` before changing function arity | `CREATE OR REPLACE` does not remove old arity overloads — creates ambiguous set that PostgreSQL refuses to resolve. Migration 094 fixed 093 silently-failing overload. | ✓ Good — added as migration checklist item; v2.2 |
| Layer discriminator pattern for geo_districts | Single table with `layer TEXT NOT NULL` + `UNIQUE(layer, geoid)` — adding new district types (school districts) requires no schema change. | ✓ Good — school districts added in Phase 71 with zero schema change; v2.2 |
| Fire-and-forget backfill after res.json() | `void pool.query(...).catch(e => console.warn(...))` after response sent; `districtRows.length === 0` guard prevents re-backfilling warm users. | ✓ Good — response latency unaffected; v2.2 |

## Previous Milestone: v2.8 District of Columbia Coverage (Phases 105–107, shipped 2026-06-08)

**Goal:** Full civic profiles for DC government — 27 officials across every DC body, sourced stances, ward-level geofencing, and FEC finance data for Eleanor Holmes Norton.

**Delivered:** DC government stub + 19 district records; 8 TIGER ward polygons (dc_ward layer) via DC GIS MapServer; 27 politician + office records; 33-row Mayor/Council/AG stance migration + Jain/EHN gap-fill; DC OCF assessed (non-machine-readable, DCFI-02 closed with finding); EHN FEC finance_summary confirmed in DB (source=FEC, 2026, $53,774.80).

---
## Previous Milestone: v2.7 Source Integrity (Phases 100–104, shipped 2026-06-07)

**Goal:** Audit every existing politician stance for real source URL coverage, re-research unsourced stances using the Chair methodology, correct incorrect values, and delete any stance that cannot be backed by a real primary source.

---
## Previous Milestone: v1.9 Roles (Phases 51–58, shipped 2026-04-06)

**Goal:** Delegated authority system — geo-scoped and resource-scoped roles, full audit trail, role-gated contributor endpoints, and contributor portal at `app.empowered.vote/contributor`.

---
## Previous Milestone: v1.8 Location Identity (Phases 49–50, complete 2026-04-01)

**Goal:** Store district GEO IDs on `connected_profiles` so every app reads jurisdiction from `/account/me` without geocoding; Path 1.5 serves pre-Phase-49 users via stored coordinates.

---
## Previous Milestone: v1.7 Cross-App SSO (Phases 44–48, shipped 2026-03-25)

**Goal:** Log in once at any Empowered Vote app and remain authenticated across all apps for the duration of the session — via a shared httpOnly session cookie on `.empowered.vote`.

## Previous Milestone: v2.6 Data Quality & Elections (Phases 87–90, 99, shipped 2026-06-05)

**Goal:** Full stance accuracy audit with individual reassessment per flagged politician, close coverage gaps across existing politicians, add a campaign finance summary layer, and ship the elections page end-to-end.

**Delivered:**
- Stance accuracy — 255 flagged politicians audited; 8 confirmed inversions corrected with real sources; party strings normalized (Democrat → Democratic, 775 rows); five-chairs framing baked into researcher agent
- Gap-fill — 440 politicians with < 10 stances audited; all 50 Tier 1 politicians brought to >= 10 stances or documented as evidence-floor
- Campaign finance — `finance_summary` JSONB on `essentials.politicians`; FEC ingestion for 209/258 federal politicians; surfaced on all API endpoints (null for non-federal)
- Elections Central — `/elections` page with geofenced race data, antipartisan headers, address-based auto-fetch; Utah 2026 Primary seeded (138 races, 171 candidates)

## Previous Milestone: v2.5 City Officials Expansion (Phases 77–78, shipped 2026-06-02)

**Goal:** Expand local government coverage to four CA cities (San Jose, San Diego, Berkeley, Fremont) with full city council + key roles and sourced stance data for all new officials. Phases 79 (gap-fill) and 80 (campaign finance) carried forward into v2.6.

## Previous Milestone: v2.4 2026 Senate Candidates (Phases 75–76, shipped 2026-05-22)

**Goal:** Full national coverage of all declared candidates in all 34 Class 2 Senate races — incumbents reuse existing politician records (flagged as candidates), non-incumbents get new politician records, and stances are researched for all notable candidates via the research-stances skill. Primaries are ongoing; catalog now and update nominees post-primary.

## Previous Milestone: v2.3 US Senate Coverage (Phases 72–74, shipped 2026-05-21)

**Goal:** Complete civic profiles for all 100 sitting US Senators — state infrastructure, politician records, office links, photos, and full sourced stance data across all applicable CompassV2 topics — so any user in any US state sees their senators in the Representatives feed with complete compass data.

## Previous Milestone: v2.2 TIGER District Geofencing (Phases 69–71, shipped 2026-05-10)

**Goal:** Full CA TIGER district geofencing pipeline — PostGIS schema, polygon import, per-user district cache, Path 0 fast path in representatives feed, Profile Location tab with school districts.

## Previous Milestone: v2.1 Inform Account Tier (Phases 66–68, shipped 2026-04-27)

**Goal:** Make the Inform tier a first-class experience — yellow-themed account, low-friction signup, yellow profile page, and an invitational path toward Connected.

## Previous Milestone: v2.0 Civic Account Experience (Phases 60–65, partially shipped)

**Goal:** Replace the functional-but-unstyled user-facing flows with a fully designed experience matching the colleague Figma — dark navy, blue CTAs, trust-first copy.

**Status:** v2.6 complete — all 12 requirements closed (SACC-01/02/03/04, GAPF-01/02, FINA-01/02/03, ELEC-01/02/03). Next milestone: planning phase.

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-08 — v2.8 complete: District of Columbia Coverage shipped*
