# Project Milestones: Empowered Accounts

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
