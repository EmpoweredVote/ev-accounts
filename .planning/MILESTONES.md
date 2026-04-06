# Project Milestones: Empowered Accounts

## v1.9 Roles (Shipped: 2026-04-06)

**Delivered:** Delegated authority system — geo-scoped and resource-scoped roles, a full audit trail, role-gated contributor endpoints for compass stances / campaign management / essentials editing, and a contributor portal at `app.empowered.vote/contributor`.

**Phases completed:** 51–58 (19 plans total)

**Key accomplishments:**

- Role infrastructure: `feature_scope` + `jurisdiction_geoid` + `resource_id` columns on `public.user_roles`; `grant_role`/`revoke_role`/`get_user_roles` SECURITY DEFINER RPCs; 5 role types seeded; `public.role_audit_log` with full audit field set
- `requireRole()` middleware with NULL-safe jurisdiction check, Redis-backed caching, and `checkRole()` pure function tested across all NULL-scope and scope-match combinations
- Admin UI: grant/revoke modal with role-type dropdown, user typeahead, jurisdiction chips from stored districts; global role audit dashboard filterable by scope/jurisdiction/date
- Role-gated endpoints: `PUT /api/compass/stances/:politicianId` (compass_stance_editor + campaign_manager), `PATCH /api/essentials/politicians/:id` (essentials_data_editor), `GET /api/contributor/me`, `POST /api/roles/check`
- Jurisdiction scoping via live `offices→districts JOIN` — never filter on `home_jurisdiction_geoid` (NULL on all 2,577 `essentials.politicians` rows)
- Contributor portal (Phase 58): dashboard with role grant cards, Compass Editor (jurisdiction-scoped politician list + inline stance editor), Candidate Coordinator (single-politician stance editor), Essentials Editor (field-level bio editor with dirty state tracking)

**Stats:**

- 119 files changed, 18,316 insertions, 150 deletions
- ~62,000 lines of TypeScript (project-wide)
- 8 phases, 19 plans, 17/17 requirements
- 4 days (2026-04-02 → 2026-04-06)

**Git range:** `7eb7e29` → `2355754`

**What's next:** v2.0 — run `/gsd:new-milestone` to define scope

---

## v1.5 Partner Integration & Referrals (Shipped: 2026-03-19)

**Delivered:** Referral dashboard card with locked/waiting/active states, plus two canonical partner integration guides (CompassV2 and Essentials) that fully document auth, jurisdiction, and the Inform-baseline / Connected-enhanced access pattern.

**Phases completed:** 31–33 (3 plans total)

**Key accomplishments:**

- Referral dashboard card — locked (level < 2), waiting (invitee < level 2), and active (code + one-click copy) states; all three driven entirely by `GET /api/referral`; `requireConnected` middleware ensures Inform-tier users never trigger the fetch
- `docs/COMPASSV2-INTEGRATION.md` — 745-line ground-up integration guide: Auth Hub redirect flow, 16 endpoints with TypeScript shapes, tier access rules (Inform/Connected/Empowered), jurisdiction "never ask for address" as a first-class section, 8 inline anti-pattern blockquotes; `COMPASS_CONTRACT.md` hard-deleted
- `docs/ESSENTIALS-INTEGRATION.md` — 654-line integration reference: three-branch `detectUserState()` (no token / 401 / 200 with/without jurisdiction), "Inform is the unconditional baseline" framing, opt-in XP/gem awards as Connected enhancement, all 10 jurisdiction fields with TIGER/Line GEOID formats and production examples
- Integration guide format established as project standard: 10-section structure (quick ref → context → auth → reads → writes → profile → jurisdiction → migration → errors → checklist) with anti-patterns inline at point of relevance

**Stats:**

- 25 files changed (+4,624 / -760 lines across docs and planning)
- ~16,856 lines of TypeScript (no net TS growth — v1.5 was documentation + verification)
- 3 phases, 3 plans, 16 requirements
- 1 day (2026-03-19)

**Git range:** `bf63b22` → `fc3b008`

**What's next:** v1.6 — run `/gsd:new-milestone` to define scope (candidates: scoped roles system, VR admin dashboard, user-to-user compass compare, Essentials XP source provisioning)

---

## v1.4 Profile Hub & Verification Engine (Shipped: 2026-03-17)

**Delivered:** Full civic identity profile page for Alpha users — Verification Rating system with VQ integration, atomic VQ confirmation endpoint, CTC + VQ live smoke tests passed, and a Profile Hub UI showing tier/XP/gems/VR with feature hub cards.

**Phases completed:** 27–30 (7 plans total)

**Key accomplishments:**

- Verification Rating schema — `verification_rating` (INT default 60, max 150) + `vq_hold_until` on `connected_profiles`; server-side derived booleans `vq_hold_active` and `red_gem_quests_unlocked` on `GET /me`; 90 threshold unlocks Red Gem quests; rating 0 sets 30-day hold
- `POST /api/vq/confirm-stance` — atomic `confirm_vq_stance` SECURITY DEFINER RPC with deadlock-safe advisory locks (sorted UUID order), inline gem INSERT + balance UPDATE (no nested SECURITY DEFINER), ±VR adjustments with cap/floor, confirmed stance upsert to `inform.politician_answers`, and idempotent replay via `vq_confirmation_results` pre-check
- Admin VR override controls — `PATCH /api/admin/accounts/:userId/verification-rating` + AccountDetailPage inline editor with draft state, 0–150 range validation, status badges, and hold-clear toggle
- CTC + VQ integrations live smoke-tested on 2026-03-17 — CTC: total_xp 1996→2096, is_duplicate:false, replay confirmed; VQ: new_rating +3, gems_awarded:1, replayed:true on replay
- Profile Hub UI — full civic identity page: tier badge, Level, total XP, yellow/blue/red gem balances, Verification Rating (X/150 + hold warning); location address form → `POST /connect/set-location`; 6 feature hub cards (CTC, VQ, Essentials, Read & Rank, Empowered Compass, Treasury Tracker); Civic Spaces jurisdiction pills; dark mode toggle

**Stats:**

- 19 files changed (backend/admin scope)
- ~17,081 lines of TypeScript (backend/src + admin/src)
- 4 phases, 7 plans, 18 requirements
- 2 days (2026-03-15 → 2026-03-17)

**Git range:** `fd496d9` (feat(27-01): add verification_rating migration) → `3a9d99f`

**What's next:** v1.5 — CompassV2 frontend integration (Accounts side complete in v1.3; CompassV2 repo implements its side using `docs/COMPASS_CONTRACT.md`); Essentials overlay compass data endpoint; user-to-user compass compare (COMP-05)

---

## v1.3 Alpha Launch & Location Infrastructure (Shipped: 2026-03-15)

**Delivered:** Production Alpha live with all migrations deployed; encrypted location infrastructure with PostGIS jurisdiction resolution; three-currency gem system; universal Connected Account signup portal; 21 compass topics, 30 politicians, and 1,000+ stance records seeded to production.

**Phases completed:** 17–26 (26 plans total)

**Key accomplishments:**

- Live Alpha deployment: migrations 026–036 applied to production via SQL Editor; smoke test 4/4 pass; idempotent `applyMigrations.ts` + six-step `DEPLOY.md` cold-start runbook; Windows MINGW64 DNS workaround documented for future reference
- Location privacy infrastructure: `encrypted_lat`/`encrypted_lng` (pgcrypto via Supabase Vault) on `connected_profiles`; Indiana TIGER/Line 2024 PostGIS boundaries (5 types); `upsert_user_location` + `resolve_user_jurisdiction` SECURITY DEFINER RPCs; architecture test enforcing zero coordinate leakage at 0 violations; `POST /connect/set-location` + `GET /me/jurisdiction` API
- CompassV2 API contract: Bearer token auth on all routes (JWKS); NUMERIC(3,1) compass values with decimal support; `completed_onboarding` + structured `xp` object on `GET /me`; `docs/COMPASS_CONTRACT.md` external integration spec
- Multi-currency gem system: yellow/blue/red ledger with idempotency; `POST /api/gems/award` with per-key `permittedTypes`; balance-always-0 bug confirmed fixed via integration test; CTC migration path off direct RPC documented
- Central profile + admin tier promotion: public `GET /profile/:userId`; owner `GET /profile/me`; `Inform→Connected` promotion with `tier_promotion_log` audit trail; admin search-as-you-type, PromotionsPage, global history
- Public Auth Hub + production data: `accounts.empowered.vote` rebranded as universal Connected Account portal; tier-based post-login routing; `signup_with_invite` RPC; `?redirect=` with trusted-domain validation; partner onboarding docs for CTC + VQ; 21 compass topics + 30 politicians + 588 stance values + 500 reasoning rows seeded via `scripts/seedData.ts`

**Stats:**

- 145 files changed (27,343 insertions, 2,051 deletions)
- ~16,010 lines of TypeScript (backend/src + admin/src)
- 10 phases, 26 plans, 33 requirements
- 8 days (2026-03-08 → 2026-03-15)

**Git range:** `fix(account): read total_xp` → `chore(v1.3): final cleanup`

**What's next:** v1.4 — compass data visible to users, set-location UI in accounts portal, CTC + VQ integration verification, compass admin tooling

---

## v1.2 CompassV2 Integration & Alpha Hardening (Shipped: 2026-03-07)

**Delivered:** CompassV2 frontend compatibility, alpha hardening (clean types + JWT revocation + 90 clean tests), and a full compass admin backend + React UI — so the Inform pillar is fully seeded and manageable without touching the database, and real Alpha users can use CompassV2 against this backend.

**Phases completed:** 12–16 (15 plans total)

**Key accomplishments:**

- Regenerated Supabase types and achieved strict TypeScript compilation (0 errors) across backend + admin source tree; 90 architecture tests pass with 0 skips or TODO workarounds; JWT revocation verified end-to-end (blocklisted token rejected on next request, not just at expiry)
- CompassV2 reset flow: `DELETE /api/compass/answers/me` soft-deletes all responses via `reset_compass_answers` RPC; `GET /api/compass/answers` and batch read both filter deleted rows with `.is('deleted_at', null)` — full E2E verified in Phase 16 gap closure
- `GET /api/essentials/politicians` accessible without authentication (uses `supabaseAnon`); `POST /api/connect/compass-import` extended to accept `selected_topics` array stored in `connected_profiles.selected_topic_ids`
- Full compass admin backend: 12 new routes in `admin.ts`, 7 new service functions in `adminService.ts`, `admin_create_topic_with_stances` atomic Postgres RPC (two-pass validation, all-or-nothing), migration 029 with three admin RPCs; 102 total tests
- Compass admin React UI: Topics page (list, create modal, live toggle, stance editor), Politicians page (list, create, detail with per-topic answers and context), Categories page (list, create, topic assignment) — all backed by new admin endpoints
- Gap closure (Phase 16): `GET /admin/compass/topics/:id/stances` added to unblock stance editor; soft-delete filter corrected (`.is()` not `.eq()`); CategoriesPage response shape fixed; `adminCreateTopic` dead code removed; id types corrected to `string` (UUID)

**Stats:**

- 65 files modified (+11,179 / -208 lines)
- ~13,334 lines of TypeScript (backend/src + admin/src)
- 5 phases, 15 plans, 20 requirements
- 2 days (2026-03-06 → 2026-03-07)

**Git range:** Phase 12 start → `97f9c6f`

**What's next:** v1.3 — live Alpha deployment runbook (migrations 026–029 apply), CompassV2 frontend API contract updates (CV2-01 through CV2-05), and Alpha user onboarding

---

## v1.1 XP & Progression (Shipped: 2026-03-04)

**Delivered:** A unified XP and leveling system — append-only ledger, atomic award RPC, tiered level calculation, public XP profile endpoint, and admin ledger view — so any feature repo can award XP with idempotency guarantees.

**Phases completed:** 9–11 (5 plans total)

**Key accomplishments:**

- Built append-only `connect.xp_transactions` ledger with UNIQUE `idempotency_key`, `total_xp`/`current_level` denormalized on `connected_profiles`, and owner-read RLS — mirrors gem ledger pattern; all XP writes are atomic and impossible to double-award
- Implemented `calculate_level` as an IMMUTABLE SQL function with tiered thresholds (2k × 3 levels, 3k × 6, 4k × 20, 5k thereafter) computable from any total XP — plus a 12-test SQL verification suite covering all tier boundaries and RLS isolation
- Delivered `award_xp` SECURITY DEFINER RPC with advisory lock and idempotency pre-check — single atomic write path that updates ledger + profile columns in one transaction; duplicate key returns 200 with original transaction and is_duplicate flag
- Added `POST /api/xp/award` with service-key middleware and per-key source authorization: feature repos authenticate via `X-Service-Key`, per-key `permittedSources` prevents cross-feature XP injection, validated source types enforced at Zod layer
- Exposed XP across three endpoints: `GET /api/xp/:userId` (public level profile), `GET /api/xp/me/history` (auth-gated paginated ledger), and structured `{ total, level, xp_in_level, xp_to_next_level }` replacing the legacy integer on `GET /account/me`
- Added admin tool XP visibility: "Level X · Y XP" summary in account header card + full paginated XP History tab on AccountDetailPage with source, amount, metadata expand/collapse, and reverse-chronological ordering

**Stats:**

- 38 files modified (6,809 net insertions)
- ~11,131 lines of TypeScript (9,265 backend + 1,866 admin React)
- 3 phases, 5 plans
- 1 day (2026-03-04)

**Git range:** `a40c502` → `ab82fdb`

**What's next:** v1.2 — live Alpha deployment hardening (supabase gen types refresh, JWT logout security review, pre-existing TypeScript errors, architecture test debt cleanup)

---

## v1.0 MVP (Shipped: 2026-02-28)

**Delivered:** Complete three-tier civic account infrastructure (Inform → Connected → Empowered) with schema, auth, enrollment, compass, empowerment, social graph, admin tool, and public candidate pages.

**Phases completed:** 1–8 (18 plans total)

**Key accomplishments:**

- Built a 4-schema Supabase database with RLS on every table, SECURITY DEFINER RPCs for atomic empowerment/demotion, and split-visibility views that mask `tolerance_rating` and `legal_name` at the database layer — not the application layer
- Implemented JWT auth (JWKS, ES256) with tier-aware `GET /api/account/me` and field-level privacy enforced at both RLS and serialization layers; `tolerance_rating` never reaches non-owners at any layer
- Shipped invite-only Alpha enrollment: atomic invite claim via `FOR UPDATE` row lock, permanent invite chain, inviter Tolerance Rating adjustment RPC, and resumable Connect verification flow
- Built the full political compass: topic calibration with change history, role-filtered completeness scoring, politician comparison, and anonymous calibration import from localStorage with topic version mismatch handling
- Implemented atomic empowerment and demotion as Postgres RPC transactions — partial state is architecturally impossible; preflight validation returns specific failure reasons; consent records audit trail
- Delivered gem ledger, role system, and social graph: append-only gem ledger with advisory-lock atomicity, soft-revocable roles with tier eligibility, peer connection state machine, and `friends`-visibility RLS enforcement via accepted peer connection join
- Built the admin React UI with dashboard, account detail, invite tree (React Flow), and cron log; daily 2am UTC calibration lapse cron with day-25 warning, day-30 final warning, day-31 demotion, and `ON CONFLICT` idempotency
- Shipped public candidate pages: unauthenticated slug and ZIP lookup with `tolerance_rating` absence enforced at both RLS and serialization layers; demoted slugs return consistent inactive state and are never reassigned

**Stats:**

- 182 files created/modified
- ~10,200 lines of TypeScript (8,487 backend + 1,711 admin React)
- 8 phases, 18 plans
- 4 days (2026-02-24 → 2026-02-28)

**Git range:** `feat(01-01)` → `feat(08-02)`

**What's next:** v1.1 — Live deployment, real user Alpha cohort, post-MVP hardening (JWT logout security review, TypeScript pre-existing errors, pre-existing architecture test debt)

---
