# Project Milestones: Empowered Accounts

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
