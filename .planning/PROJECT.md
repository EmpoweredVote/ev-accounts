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

### Validated (v2.19)

**Milestone: v2.19 Local Civic Coverage** (Phases 145–147, inline-executed) — shipped 2026-06-23.

- ✓ LCC-01..05: full-stack local coverage for Falls Church VA (17 officials), Greene County MO (13), and Springfield MO (16) — 46 records, 4 geofence boundaries, 118 evidence-only stances (0 unsourced), 46 headshots, 3 essentials coverage entries; each on an established blueprint (Alexandria / LA County / city+school), national topics correctly skipped, honest blanks where source-walled — Phases 145–147

### Validated (v2.18)

**Milestone: v2.18 State Leaders** (Phases 141–144) — shipped 2026-06-22.

- ✓ SEXR-01..04: authoritative elected-Big-5 roster locked + idempotent gap seed across all 50 states — 209 in-scope offices (gov 50 / lt-gov 43 / AG 43 / SoS 35 / treasurer 38), deduped on `(STATE_EXEC, state, role_canonical)`, `role_canonical` populated, uppercase state + non-empty geo_id, every newly-seeded exec with a headshot — Phase 141
- ✓ SEXS-01..02: office-type evidence guidance in the researcher prompt, then sourced compass stances for all in-scope execs lacking them across two waves (Gov+AG, then SoS+Treasurer+LtGov) — 199 covered + 10 documented whole-record honest-skips, 0 unsourced, never inferred from party — Phases 142–143
- ✓ SEXR-05 + SEXS-03: consolidated read-only gate `verify-phase-141-144.sql` — 11 labeled assertions (records, dedup, headshots, state-code hygiene, per-role coverage, 10-id honest-skip pin, zero-unsourced) plus a SEXR-05 feed-surfacing SQL simulation for NC/WA/CO — all PASS against production — Phase 144

### Validated (v2.17)

**Milestone: v2.17 National House Rep Stances (Tier 2 continuation)** (Phases 132–140) — shipped 2026-06-20.

- ✓ USHS-06..13: sourced compass stances for all in-scope US House reps in the remaining 38 states, researched largest-delegation-first in 8 waves (OH+NC, GA+MI, NJ+WA+AZ, TN+CO+MN+MO, WI+AL+SC+KY, LA+CT+IN+OK+AR+IA, KS+MS+NV+NE+NM, 12 single/low-rep states) — 212 reps, 211 covered + McDowell NC-6 documented honest-skip, every answer paired with a real-sourced context row — Phases 132–139
- ✓ USHS-14: consolidated read-only gate `verify-phase-132-140.sql` — all USHS-06..14 labeled assertions PASS against production (per-wave coverage + 211/212 with the sole gap pinned to −37006 + 0 unsourced) — Phase 140

### Validated (v2.16)

**Milestone: v2.16 National House Rep Stances (Tier 2)** (Phases 127–131) — shipped 2026-06-18.

- ✓ USHS-01..04: sourced compass stances for FL (27), NY (26), PA (17), IL (17) US House reps — 87 reps, 1,338 sourced answers, 0 unsourced — Phases 127–130
- ✓ USHS-05: consolidated gate `verify-phase-127-131.sql` passes (87/87 covered, 0 unsourced) — Phase 131

### Validated (v2.15)

**Milestone: v2.15 National House Rep Seeding (Tier 1)** (Phases 125–126) — shipped 2026-06-16.

- ✓ USHR-01: 299 US House reps seeded (politician + office), FK-linked to `NATIONAL_LOWER` districts via `tiger_geoid`; linked reps 137→436 — Phase 125
- ✓ USHR-02: idempotent, unseeded-only ingestion; 0 orphans; clean no-op re-run; 137 pre-existing reps untouched — Phase 125
- ✓ USHR-03: party normalized `Democrat→Democratic`; at-large/territory/vacancy edge cases handled — Phase 125
- ✓ USHR-04: headshots 299/299 (292 canonical congress photos + 7 Wikimedia official portraits) — Phase 126
- ✓ USHR-05: consolidated gate `verify-phase-125-126.sql` passes; Path 0 verified across 5 states + at-large + DC — Phase 126

### Validated (v2.10 - in progress)

**Milestone: v2.10 Virginia Coverage + LA County Finance** — Phase 111 complete 2026-06-10.

- ✓ VAST-02: 182 sourced stances for 35/40 VA state senators (5 honest-skipped with no documentable record); migrations 326–330 applied — Phase 111
- ✓ VAST-05 (Phase 111 portion): All 182 VA senator stance rows have paired `inform.politician_context` rows with real source URLs — 0 unsourced — Phase 111

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

**Current state (v2.16 complete — next: v2.17 Tier 2 continuation):** ~80,000 lines of TypeScript (project-wide). 131 phases shipped. FL/NY/PA/IL US House reps (87) now have sourced compass stances (1,338 answers, 0 unsourced; gate verify-phase-127-131.sql). Backend: Express 4.x, Supabase, Upstash Redis, pg, PostGIS. Admin: Vite + React + Tailwind v4 (dark mode, login.empowered.vote). App: Vite + React (`app.empowered.vote` — includes contributor portal at `/contributor`). Migrations 026–769 applied to production. 21 live compass topics, ~1,500+ politicians with data, full role system live. **All 435 US House districts now resolve to a sitting rep (436 linked offices, all with headshots) — Tier 1 done; stances pending (Tier 2).** CA (52 us_house + 80 assembly + 40 senate + 975 school) + DC (8 wards) + VA (100 SLDL + 40 SLDU) + MA (160 SLDL + 40 SLDU) + all 435 US House TIGER geofencing live. VA: 40 state senators + 100 delegates + 11 federal House reps + state execs with stances in DB. MA: 7 cities (Boston, Cambridge, Worcester, Springfield, Lowell, Brockton, Quincy) with 512 stances across 71 officials. FEC finance data live for all reachable federal politicians; NATIONAL_UPPER NULL count: 1 (Armstrong OK). Elections Central page live at `/elections` with Utah 2026 Primary seeded. LA County: 27 cities with full elected governing bodies; 192 officials with CAL-ACCESS finance data.

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
| Federal rep ingestion: script GENERATES a reviewable SQL migration (not direct insert) | Preserves the project's auditable-migration convention for record data; dry-run coverage report before any production write. | ✓ Good — migration 739 reviewed then applied; v2.15 |
| Bulk-seed strategy: iterate the GAP (unseeded districts), not the roster | Auto-handles already-seeded states, territories (no district rows), and surfaces genuine vacancies explicitly instead of dropping them. | ✓ Good — cleanly excluded 3 real vacancies + dup DC row; v2.15 |
| `external_id = -(state_fips*1000 + cd)` for seeded federal reps | Deterministic, collision-free negative-id scheme (verified 0 collisions); enables idempotent ON CONFLICT + scoped office_id backfill. | ✓ Good — v2.15 |
| Pre-flight guards "districts loaded ≥435", not "unseeded ≥N" | Orphan-prevention intent without blocking re-runs; combined with ON CONFLICT + NOT EXISTS makes the migration a clean re-run no-op. | ✓ Good — fixed mid-execution; v2.15 |
| Congress headshots via `unitedstates.github.io/.../225x275/{bioguide}.jpg` | Authoritative bulk source matching existing 148 federal photos; HEAD-validate, find-headshots fallback for repo lag. | ✓ Good — 299/299 covered; v2.15 |
| SECURITY DEFINER RPCs are service_role-only; never add `auth.uid()` guards | Backend calls via `adminRpc`(service_role)/`pool.query` where `auth.uid()` is NULL; identity verified at Express layer. Accidental PUBLIC EXECUTE grant is the only risk → REVOKE `authenticated`. | ✓ Good — documented for EV-Backend IDOR audit; v2.15 |

## Current State

**v2.19 shipped 2026-06-23 (formalized retroactively)** — three new local jurisdictions are fully covered: Falls Church VA (17 officials), Greene County MO (13), and Springfield MO (16). 46 records, 4 geofence boundaries, **118 evidence-only stances (0 unsourced)**, 46 headshots, and 3 essentials coverage entries (migrations 1047–1049). A Springfield resident now sees city + SPS school district + Greene County + Missouri statewide execs at one address. Executed inline (not GSD-phased); CA-city siblings (Burbank/Norwalk/Bellflower) and the Nevada work (essentials team) ran the same week but are out of this milestone's scope. Git range `a488232a` → `ef1a364f`.

**v2.18 shipped 2026-06-22** — every state's elected Big 5 statewide executives are now in the platform across all 50 states. **209 elected offices seeded** (gov 50 / lt-gov 43 / AG 43 / SoS 35 / treasurer 38) with headshots, **199 stance-covered** (gov 50 / AG 42 / SoS 34 / treasurer 34 / lt-gov 39) + 10 documented whole-record honest-skips, **0 unsourced**. The consolidated production gate `backend/scripts/verify-phase-141-144.sql` (11 labeled assertions incl. the SEXR-05 feed-surfacing simulation) passes read-only against prod. No backend code shipped — `STATE_EXEC` was already wired into the feed query. AZ Lt Gov deferred (Prop 131, eff. Jan 2027). Prior coverage layers remain: national House (`verify-phase-127-131.sql` + `verify-phase-132-140.sql`).

**Next:** Next milestone TBD — continue local civic coverage (more cities/counties; CA-city builds available to fold in) or pivot.

---

## Previous Milestone: v2.19 Local Civic Coverage (Phases 145–147, shipped 2026-06-23)

**Goal:** Full-stack local coverage for three new jurisdictions — Falls Church VA, Greene County MO, and Springfield MO — so each resident sees their full slate of locally-elected officials (council, constitutional/county officers, school board) in the feed, with sourced compass alignment, headshots, and geofence + essentials-coverage plumbing.

**Delivered:** All 5 requirements closed (LCC-01..05), executed inline (no plan dirs), formalized retroactively. **46 elected officials** seeded — Falls Church VA (17, Alexandria template), Greene County MO (13, LA County template), Springfield MO (16, city + SPS R-XII board) — on correct government → chamber → district structures with collision-checked `-(geo_id||seq)` external_ids. **4 geofence boundaries** imported (FC coterminous school G5420; Greene County G4020 from TIGERweb; Springfield place G4110 + non-coterminous school G5420). **118 evidence-only stances** (FC 55 / Greene 26 / Springfield 37), every answer paired to a real fetched source URL, **0 unsourced**, honest blanks where source-walled. **46 headshots** (clean-sourcing pass on Springfield). **3 essentials coverage entries** (FC + Springfield COVERAGE_STATES purple; Greene County COVERAGE_COUNTIES search-only). Migrations 1047–1049; git range `a488232a` → `ef1a364f`. **Key lesson:** `essentials.chambers.slug` is a generated column that collides across same-named cities (Springfield MO silently bound to Springfield MA) — scope chamber lookups by government name, never slug. Out of scope: CA-city siblings (phases 154–156) and Nevada (phases 158–159, essentials team).

---

## Previous Milestone: v2.18 State Leaders (Phases 141–144, shipped 2026-06-22)

**Goal:** Every US resident sees their state's elected Big 5 executives — Governor, Lt. Governor, Attorney General, Secretary of State, and Treasurer (whichever of the five their state actually elects) — in the representatives feed with sourced compass alignment, across all 50 states.

**Delivered:** All 8 requirements closed (SEXR-01..05, SEXS-01..03); 34 plans across 4 phases. **209 in-scope elected offices seeded** across all 50 states (deduped on `(STATE_EXEC, state, role_canonical)` — never title string — with `role_canonical` populated, uppercase state codes, non-empty `geo_id`, and a collision-free `-(state_fips*100000+seq)` external_id scheme), each newly-seeded exec given a headshot (incl. `.gov`-recovered hard cases). **199 execs stance-covered** (gov 50 / AG 42 / SoS 34 / treasurer 34 / lt-gov 39), every answer paired to a real fetched source URL, **0 unsourced**, with office-type evidence guidance (Gov=signings/vetoes/EOs, AG=lawsuits/amicus/coalitions, Treasurer=fund actions, SoS=election-admin, LtGov=honest-partial). **10 documented whole-record honest-skips** pinned by exact external_id in the gate (OH AG; SC SoS; 4 treasurers; 4 lt-govs) — genuinely narrow-record offices where honest-skip beat inference; SSM=5 kept only on documented anti-recognition litigation/votes/amendments. Single consolidated read-only gate `verify-phase-141-144.sql` (11 assertions, all PASS, psql exit 0; gsd-verifier 6/6). AZ Lt Gov deferred (Prop 131). Execution lesson: never add a NULL-`role_canonical`-by-title heuristic to a records gate — it false-fails on legitimately-out-of-scope offices (legislature-selected, appointed) and legacy duplicate rows; exact per-role counts already guard a missing canonical row.

---

## Previous Milestone: v2.17 National House Rep Stances (Tier 2 continuation) (Phases 132–140, shipped 2026-06-20)

**Goal:** Complete national US House stance coverage — give the remaining 212 seeded US House reps (across all 38 not-yet-covered states) sourced compass alignment, so every US resident's sitting House rep shows up with compass data, not just the 87 in FL/NY/PA/IL.

**Delivered:** All 9 requirements closed (USHS-06..14); 45 plans across 9 phases. **212 in-scope reps: 211 covered + 1 documented honest-skip (McDowell NC-6), 0 unsourced.** Researched largest-delegation-first in 8 waves (OH/NC → GA/MI → NJ/WA/AZ → TN/CO/MN/MO → WI/AL/SC/KY → LA/CT/IN/OK/AR/IA → KS/MS/NV/NE/NM → 12 single/low-rep states), then a consolidated gate (`verify-phase-132-140.sql`, all assertions PASS). Chair-philosophy / evidence-over-party held throughout: ~23 caucus/committee-membership and "overall-record" proxy rows dropped at review, refining the rule that caucus membership counts only with a published platform directly on the topic. Reused the v2.16 pipeline verbatim at 3-concurrency (shared `_TOPIC_SCALE.txt`, per-rep CSV → `_merge.ts` → external_id-keyed `_push.ts`, 0 surname leaks). Added a standing one-try-per-URL agent efficiency rule after a 6.5h WebFetch stall in 137. Two roster traps caught by querying prod before authoring: IN's non-contiguous in-scope set (137) and the at-large `-{fips}000` external_ids (139).

---

## Previous Milestone: v2.16 National House Rep Stances (Tier 2) (Phases 127–131, shipped 2026-06-18)

**Goal:** The newly-seeded US House reps show sourced compass alignment in the representatives feed — bounded first chunk: the 4 largest delegations (FL 27, NY 26, PA 17, IL 17 = 87 reps).

**Delivered:** All 5 requirements closed (USHS-01..05); 9 plans. **87/87 in-scope reps covered, 1,338 sourced answers, 0 unsourced** (FL 394 + NY 412 + PA 262 + IL 270). Every stance backed by a real fetched URL in `inform.politician_context`; evidence-over-party throughout (verified RFMA votes, purple-district deportation calibrations, no party-inference). Consolidated gate `backend/scripts/verify-phase-127-131.sql` — all USHS-01..05 assertions PASS against production. 3 genuine vacancies (FL-20/GA-13/TX-23) and 137 pre-existing reps correctly excluded. Methodology validated at 3-concurrency: shared `_TOPIC_SCALE.txt` (25 federal topics), external_id→UUID push, canonical CSV re-parse/re-stringify before merge. Remaining ~212 reps → v2.17+.

---

## Previous Milestone: v2.15 National House Rep Seeding (Tier 1) (Phases 125–126, shipped 2026-06-16)

**Goal:** Every US resident who enters their address sees their actual sitting US House representative — turn the already-complete national congressional geofencing (Phase 116/v2.11) into a usable feature.

**Delivered:** 299 missing US House reps seeded from `unitedstates/congress-legislators`, FK-linked to existing `NATIONAL_LOWER` districts via `tiger_geoid` (linked reps 137→436); idempotent `seed-national-house-reps.ts` + migration 739; headshots 299/299 (292 canonical congress photos via migration 769 + 7 official Wikimedia portraits via `find-headshots`); consolidated gate `verify-phase-125-126.sql` (USHR-01..05 all pass, Path 0 verified WY(at-large)/NY/TX/OH/IL + DC). 3 genuine House vacancies (FL-20/GA-13/TX-23) excluded by design; stance research deferred to v2.16 (Tier 2).

---

## Previous Milestone: v2.14 MA City Expansion Wave 2 (Phases 120–124, shipped 2026-06-16)

**Goal:** Full civic data layer for 7 remaining MA cities — districts, officials, stances, and per-ward geofencing for Newton, Somerville, Lynn, Fall River, Waltham, Medford, and New Bedford.

**Delivered:** All 21 requirements closed (MAOF-01..07, MAST-01..07, MAGE-16..22); 16 plans; consolidated phase gate `verify-phase-120-124.sql` (44 assertions, all pass); Path 0 human-approved for all 7 cities.

---

## Previous Milestone: v2.13 MA City Council District Geofencing (Phase 119, shipped 2026-06-15)

**Goal:** Per-ward Path 0 city council geofencing for the 6 MA cities seeded in v2.12.

**Delivered:** Boston (9 ward polygons + 2 citywide, MAGE-10), Worcester (5 ward polygons, MAGE-11), Springfield/Lowell/Brockton/Quincy (29 polygons total, MAGE-12..15); migrations 659–664; all MAGE-10..15 gates pass; Path 0 human-approved for all 6 cities.

---

## Previous Milestone: v2.12 MA Expansion (Phases 117–118, shipped 2026-06-15)

**Goal:** Full Massachusetts civic data layer — sourced stances for 7 MA cities + MA TIGER state legislative geofencing for Path 0.

**Delivered:** 512 stances across 71 officials in 7 MA cities (migrations 574–597); 200 MA state legislative districts tiger_geoid backfilled (migrations 619, 622); Medford geo_id corrected; all MAGE-00..05 gates pass; Path 0 verified for Porter Square Cambridge.

---

## Previous Milestone: v2.9 LA County Expansion (Phase 108, shipped 2026-06-08)

**Goal:** Full elected governing bodies for 27 LA County cities across 4 waves.

**Delivered:** 14 Tier 1 gap-fills (Long Beach, Glendale, Pasadena, Burbank, Downey, El Monte, Inglewood, Lancaster, Norwalk, Palmdale, Pomona, Santa Clarita, Torrance, West Covina); Beverly Hills + Santa Monica structure completion + LA City Controller Kenneth Mejia + Clerk Patrice Lattimore; 10 new cities (South Gate, Compton, Carson, Hawthorne, Whittier, Alhambra, Gardena, Culver City, West Hollywood, El Segundo); 8-assertion phase gate SQL script. Phase 109 (LA County Finance) deferred to v2.10.

---

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
*Last updated: 2026-06-22 — after v2.18 State Leaders milestone (Phases 141–144 shipped). 209 elected Big-5 offices seeded across 50 states + headshots; 199 stance-covered + 10 honest-skips, 0 unsourced; consolidated gate verify-phase-141-144.sql all-PASS. All 8 reqs (SEXR-01..05, SEXS-01..03) closed. Next: planning next milestone.*
