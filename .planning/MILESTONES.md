# Project Milestones: Empowered Accounts

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
