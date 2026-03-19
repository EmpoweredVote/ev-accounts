# Project Research Summary

**Project:** empowered-accounts
**Domain:** Civic identity platform — permission system, compass analytics, admin tooling
**Researched:** 2026-03-19
**Confidence:** HIGH — all findings grounded in direct codebase inspection

## Executive Summary

v1.6 is a focused milestone with four features: scoped roles (ROLES-01), compass compare (COMP-05), VR admin dashboard (VR-F01), and Essentials XP provisioning (ESSENTIALS-PROV). The defining characteristic of this milestone is that it adds significant new capability without adding a single new npm package or external dependency. Every feature is implementable using the existing Express 4.x / TypeScript / Supabase / pg / Redis stack. ESSENTIALS-PROV is already coded — it requires only env var provisioning and a docs update.

The recommended build order is ESSENTIALS-PROV → COMP-05 → VR-F01 → ROLES-01. This is risk-ordered: the first three features are read-only with no schema migrations, while ROLES-01 requires schema migrations, RPC signature updates, a new partial unique index, and new middleware. Building ROLES-01 last ensures the other three features are never blocked on the highest-blast-radius change. All four features are architecturally independent and can be designed in parallel; only implementation should be sequenced.

The two critical pitfalls that must be locked in before any code is written: (1) the NULL geo-scope pattern for ROLES-01 — every permission check must use `(jurisdiction_geoid IS NULL OR jurisdiction_geoid = $x)`, never a bare equality — and (2) compass compare visibility enforcement — private answers must be filtered inside a SECURITY DEFINER RPC, never via the supabaseAdmin service role client which bypasses RLS entirely. Both pitfalls are silent data exposure risks that integration tests must permanently guard against.

## Key Findings

### Recommended Stack

No new dependencies for v1.6. The existing stack handles all four features without addition. Scoped roles are SQL columns + TypeScript additions in the existing service layer. Compass compare is a TypeScript intersection of two existing query results plus one new SECURITY DEFINER RPC. The VR histogram is a `pool.query()` GROUP BY aggregate rendered as Tailwind proportional divs — no charting library needed at Alpha scale (< 100 users). Essentials XP provisioning is a Render env var.

The one addition is not a library but a pattern: `requireRole(featureScope, geoid?)` middleware in `src/middleware/requireRole.ts`, following the exact same shape as the existing `requireAdmin.ts` and `tierGuards.ts` middleware — a `pool.query()` EXISTS check against `public.user_roles`.

**Core technologies (all existing):**
- `pool.query()` (pg raw driver) — all non-public schema writes and complex aggregates (VR histogram, VR user list)
- SECURITY DEFINER RPCs — new `compare_compass_responses` for visibility enforcement; updated `grant_role` / `revoke_role` for geo-scope
- Tailwind v4 — VR dashboard histogram bars as proportional divs, brand tokens `ev-teal` / `ev-yellow` / `ev-red`
- Zod — feature scope string allowlist validation for ROLES-01 (already in use)

**Do not add:**
- Permissions library (CASL, Casbin) — `user_roles` table IS the permission store; a library layer duplicates it
- Charting library (Recharts, Chart.js) — five static buckets at < 100 users is not a charting problem
- New Postgres extension — no new data types, spatial operations, or encryption needed

See STACK.md for full detail.

### Expected Features

**Must have (table stakes):**
- ROLES-01: `feature_scope` column on `public.roles` + `jurisdiction_geoid` column on `public.user_roles`
- ROLES-01: Updated partial unique index using `COALESCE(jurisdiction_geoid, '')` so national + geo-restricted grants coexist
- ROLES-01: Updated `grant_role` / `revoke_role` RPCs accepting `p_jurisdiction_geoid DEFAULT NULL` (backward-compatible)
- ROLES-01: `requireRole(featureScope, geoid?)` middleware for external feature API access gates
- ROLES-01: Five feature-scoped roles seeded: `ctc_dev`, `quest_dev`, `essentials_dev`, `compass_dev`, `platform_admin`
- ROLES-01: Admin UI grant/revoke form updated to accept `feature_scope` + optional `jurisdiction_geoid`
- COMP-05: `GET /api/compass/compare/:userId` — works for both user UUIDs and politician UUIDs; optional auth
- COMP-05: `compare_compass_responses` SECURITY DEFINER RPC enforcing visibility at DB layer
- COMP-05: Response shape includes `user_a_answered`, `user_b_answered`, `shared_count` for confidence context
- VR-F01: `GET /api/admin/vr-dashboard` — distribution aggregate (7 numbers) via `pool.query()`
- VR-F01: `GET /api/admin/vr-dashboard/users` — paginated user list with VR + hold status
- VR-F01: `VRDashboardPage.tsx` — 5-bucket histogram + on-hold list + AccountDetailPage links
- ESSENTIALS-PROV: `ESSENTIALS_SERVICE_KEY` in Render env + `.env.example` + ESSENTIALS-INTEGRATION.md corrected

**Should have (differentiators):**
- COMP-05: `?topic_ids=` filter to scope compare to user's selected topics
- COMP-05: `unanswered_by_requester` bucket enabling "answer these topics" CTA in Essentials
- COMP-05: `agreement_score` percentage computed server-side
- VR-F01: `hold_days_remaining` integer derived server-side (not raw TIMESTAMPTZ exposed)
- VR-F01: VR = 0 users flagged visually separate from "below threshold"
- ROLES-01: Admin-implies-all runtime check in `hasRole()` logic (not stored as inheritance rows)
- ROLES-01: `GET /api/roles/me` response extended with `feature_scope` + `jurisdiction_geoid` per grant

**Defer to post-v1.6:**
- VR trend history (requires VR audit log table not currently tracked)
- Multi-way compass compare (3+ users)
- Bulk VR adjustment from dashboard
- Role permission caching in Redis
- VR source attribution (CTC vs VQ breakdown)
- Wildcard geo-scope ("all counties in state")
- UI for creating new feature scopes

See FEATURES.md for full detail.

### Architecture Approach

v1.6 is additive at every layer. The existing `public.user_roles` + `public.roles` tables are extended in-place with two new columns. No new tables are created. The compass compare is a new SECURITY DEFINER RPC against existing tables with no schema changes to those tables. The VR dashboard is new read queries against existing columns. ESSENTIALS-PROV is zero code changes.

**Major components:**
1. ROLES-01 schema migration — `ALTER TABLE public.roles ADD feature_scope TEXT CHECK (...)`, `ALTER TABLE public.user_roles ADD jurisdiction_geoid TEXT`, `DROP/CREATE` unique index, five seed inserts, updated `grant_role` / `revoke_role` RPC signatures
2. `requireRole.ts` middleware — factory `requireRole(featureScope, geoid?)` returning Express middleware; `pool.query()` EXISTS check; no supabaseAdmin needed
3. `compare_compass_responses` RPC — SECURITY DEFINER, `SET search_path = ''`, enforces `deleted_at IS NULL` + three-tier visibility (owner / peer / public) + peer connection check via `connect.social_relationships`
4. VR dashboard backend — two `pool.query()` functions in `adminService.ts` + two new routes in `admin.ts`
5. `VRDashboardPage.tsx` — React admin page; proportional div histogram + paginated hold list + AccountDetailPage links

**Patterns that must not change:**
- `pool.query()` for all non-public schema writes AND for complex aggregates PostgREST cannot express (CASE WHEN bucketing, cross-schema JOINs)
- `supabaseAdmin` banned from `src/routes/` — new service functions go in `src/lib/`
- SECURITY DEFINER + `SET search_path = ''` on all new RPCs; fully qualified table references required
- Two-pass validation in RPCs: validate all inputs before any writes
- `requireAdmin` is NOT replaced — it continues to gate `/api/admin/*`; `requireRole` is additive for external feature API routes only
- Soft-delete filter `AND deleted_at IS NULL` required on every `inform.compass_responses` query

See ARCHITECTURE.md for full SQL signatures and component boundary table.

### Critical Pitfalls

1. **NULL geo-scope dropped by naive WHERE clause (ROLES-01)** — `NULL = '18057'` evaluates to NULL (falsy), silently dropping all global grants. Every permission check must use `(jurisdiction_geoid IS NULL OR jurisdiction_geoid = $x)`. Write a test asserting a NULL-geoid grant passes when any real geoid is presented.

2. **Compass compare leaking private responses via supabaseAdmin (COMP-05)** — `supabaseAdmin` bypasses RLS, returning ALL compass answers including `visibility='private'`. The compare endpoint must use a SECURITY DEFINER RPC that applies three-tier visibility inside the DB function. Write a privacy-leakage test before any implementation.

3. **is_admin / admin_users drift from scoped role system (ROLES-01)** — `public.admin_users` + `requireAdmin` gate the internal admin panel; ROLES-01 adds developer feature roles for cross-app API access. These must never compete. Define the boundary before schema work: `admin_users` = admin panel gate; ROLES-01 = external feature API gate.

4. **VR dashboard aggregate silently truncated at Supabase row limit (VR-F01)** — Fetching raw `connected_profiles` rows and counting in JS hits PostgREST's 1,000-row ceiling. Build the distribution aggregate as a `pool.query()` GROUP BY returning bucket counts directly, not raw rows.

5. **Soft-delete filter omitted from compare RPC (COMP-05)** — A new RPC written from scratch will not automatically inherit the `deleted_at IS NULL` filter. Add `AND deleted_at IS NULL` to the RPC SQL and document it in the migration comment explicitly.

See PITFALLS.md for all 12 pitfalls with detection strategies and phase-specific warnings.

## Implications for Roadmap

Based on research, the four features divide cleanly into four phases ordered by risk and blast radius.

### Phase 1: ESSENTIALS-PROV — Essentials XP Provisioning

**Rationale:** Zero code changes. `serviceKeyAuth.ts` already has `ESSENTIALS_SERVICE_KEY` wired at lines 22–24. This closes a documented gap from v1.5, unblocks the Essentials team immediately, and has no failure modes.

**Delivers:** `ESSENTIALS_SERVICE_KEY` set in Render environment, `.env.example` updated, `ESSENTIALS-INTEGRATION.md` corrected on `GEMS_SERVICE_KEYS` env var name.

**Addresses:** ESSENTIALS-PROV feature

**Avoids:** N/A — no pitfalls for this phase.

**Research flag:** Skip — config + docs only.

---

### Phase 2: COMP-05 — Compass Compare API

**Rationale:** Read-only, no schema migrations, self-contained. Proves the SECURITY DEFINER RPC pattern for visibility enforcement before ROLES-01 adds schema complexity. Primary unblock for Essentials app's politician compare view.

**Delivers:** `GET /api/compass/compare/:userId` endpoint (user UUID or politician UUID), `compare_compass_responses` SECURITY DEFINER RPC, response with `shared_topics`, `agreement_score`, `total_shared`, `user_a_answered`, `user_b_answered`.

**Avoids:**
- Pitfall 2 (private response leak) — SECURITY DEFINER RPC enforces visibility at DB layer
- Pitfall 5 (ambiguous overlap) — response shape includes per-user answer counts
- Pitfall 8 (deleted_at omission) — enforced in RPC SQL, documented in migration comment

**Open questions to resolve before planning:**
- Self-compare behavior: 400 or 100% agreement?
- Agreement threshold: exact match (divergence = 0) or near-match (divergence ≤ 0.5)? Start with exact.
- Unauthenticated access: return politician answers only with empty requester bucket, or require auth?

**Research flag:** Skip deeper research. Patterns well-established in this codebase.

---

### Phase 3: VR-F01 — VR Admin Dashboard

**Rationale:** Read-only queries against existing columns, no migrations. Admin UI work is independent of ROLES-01. Delivers admin visibility before the milestone's largest change lands.

**Delivers:** `GET /api/admin/vr-dashboard` (distribution aggregate), `GET /api/admin/vr-dashboard/users` (paginated list with sort), `VRDashboardPage.tsx` with 5-bucket histogram + on-hold list + AccountDetailPage links.

**Avoids:**
- Pitfall 7 (silent row limit truncation) — aggregate computed via `pool.query()` GROUP BY, never raw row scan
- Pitfall 10 (raw vq_hold_until exposure) — API returns `vq_hold_active: boolean` + `hold_expires_at` date string, not raw TIMESTAMPTZ

**Open questions to resolve before planning:**
- Sort options: confirm whether paginated user list needs a `hold` sort (by `vq_hold_until DESC NULLS LAST`) or just `asc`/`desc` on VR value
- VR = 0 panel: separate UI section or bottom of the asc-sorted list?

**Research flag:** Skip deeper research. Standard admin dashboard pattern well-documented in this codebase.

---

### Phase 4: ROLES-01 — Scoped Roles System

**Rationale:** Largest blast radius of the milestone. Requires: two `ALTER TABLE` migrations, `DROP/CREATE` on the partial unique index, updated RPC signatures, five role seed rows, new `requireRole.ts` middleware, service layer additions, updated admin UI forms, and `GET /api/roles/me` response shape update. Built last so the other three phases are never blocked. Must be fully designed before any implementation begins.

**Delivers:** Feature-scoped + geo-scoped role grants on `public.user_roles`, `requireRole(featureScope, geoid?)` middleware, five seeded developer roles, admin UI for granting/revoking scoped roles, `GET /api/roles/me` returning scope dimensions.

**Avoids:**
- Pitfall 1 (NULL geo-scope) — mandatory two-part clause documented in migration comments and tested
- Pitfall 3 (admin_users drift) — boundary defined explicitly before schema work: two parallel systems, not competing
- Pitfall 4 (non-public schema write failure) — `jurisdiction_geoid` added to `public.user_roles`, keeping roles data in public schema where PostgREST works
- Pitfall 6 (residential vs. role-grant geoid confusion) — migration comment documents: `jurisdiction_geoid` on grant row = scope of authority, not user's residential location
- Pitfall 9 (concurrent grant race) — evaluate whether any programmatic grant path exists; add advisory lock if so
- Pitfall 11 (feature scope string not validated) — single constant array drives both Zod enum and DB CHECK constraint

**Open questions to resolve before planning:**
- Does the admin grant UI need a GEOID typeahead from `inform.district_boundaries`, or free-text with server-side validation? Free-text is simpler for v1.6.
- Should `requireAdmin` eventually be deprecated in favor of `requireRole('admin')`? Decision for v1.7 — both coexist in v1.6.
- Validate that `COALESCE(jurisdiction_geoid, '')` in the unique index produces correct uniqueness for NULL geoids. Run against a test migration before plan is finalized.

**Research flag:** This phase warrants careful design review before planning. The index change and RPC signature update have subtle correctness requirements. The plan doc should include the exact SQL for the new index and both RPC signatures before implementation begins. Consider a `/gsd:research-phase` call if the COALESCE uniqueness behavior is uncertain.

---

### Phase Ordering Rationale

- Risk ordering: each phase increases blast radius. ESSENTIALS-PROV cannot break anything; ROLES-01 touches schema, RPCs, middleware, and admin UI.
- No cross-phase dependencies: all four features are architecturally independent. The order is pure risk sequencing.
- Admin panel stability: VR-F01 (Phase 3) delivers admin value before ROLES-01 (Phase 4) introduces schema migration risk.
- Pattern validation: COMP-05 (Phase 2) proves the SECURITY DEFINER RPC pattern with a read-only feature before ROLES-01 uses the same pattern for writes.

### Research Flags

Phases that may need deeper research during planning:
- **Phase 4 (ROLES-01):** The `COALESCE(jurisdiction_geoid, '')` trick in the partial unique index is non-standard. Validate on a test migration that NULL geoids produce correct uniqueness before the plan is finalized. Also confirm `IS NOT DISTINCT FROM` vs `COALESCE` behavior for the `revoke_role` match condition.

Phases with standard patterns (skip research-phase):
- **Phase 1 (ESSENTIALS-PROV):** Config + docs only.
- **Phase 2 (COMP-05):** Read-only RPC following established `compassService.ts` patterns.
- **Phase 3 (VR-F01):** `pool.query()` aggregate + React admin page following established `AdminDashboard.tsx` pattern.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All findings from direct codebase inspection. No external library decisions required. ESSENTIALS-PROV code presence confirmed at exact file lines. |
| Features | HIGH | Feature boundaries derived from live schema and code. Deferred items are clearly non-blocking at Alpha scale (< 100 users). |
| Architecture | HIGH | All component boundaries, query patterns, and file locations verified against actual codebase. SQL signatures exact, not approximate. |
| Pitfalls | HIGH | Critical pitfalls derived from live code patterns and documented production rules (MEMORY.md). External sources used for secondary validation only. |

**Overall confidence:** HIGH

### Gaps to Address

- **Self-compare behavior (COMP-05):** Resolve before the phase plan is written. The endpoint must be designed with a clear answer for `:userId == requester`. Recommend returning 100% agreement with a `is_self_compare: true` flag rather than a 400.
- **Agreement threshold (COMP-05):** Default to exact match (divergence = 0) in v1.6. Document the decision in the phase plan. Relax to ±0.5 in a later milestone based on user feedback.
- **GEOID picker in admin UI (ROLES-01):** Free-text with server-side validation is simpler. A typeahead from `inform.district_boundaries` is more operator-friendly but requires a new admin query. Decide before Phase 4 UI design begins.
- **VR user list sort options (VR-F01):** Confirm `hold` as a third sort option with product before Phase 3 UI is specced.
- **COALESCE uniqueness in partial index (ROLES-01):** Test against a local migration before the plan is finalized. This is the one technically uncertain implementation detail in the milestone.

## Sources

### Primary (HIGH confidence)

- Direct codebase inspection — `backend/src/middleware/requireAdmin.ts`, `tierGuards.ts`, `serviceKeyAuth.ts`
- Direct codebase inspection — `backend/src/lib/roleService.ts`, `adminService.ts`, `compassService.ts`
- Direct codebase inspection — `backend/src/routes/compass.ts`, `admin.ts`
- Direct codebase inspection — `supabase/migrations/20260227000020_phase6_roles_schema.sql` (roles table structure)
- Direct codebase inspection — `supabase/migrations/20260227000022_phase6_rls_and_grants.sql` (visibility policy CRITICAL comment, line 130)
- Direct codebase inspection — `supabase/migrations/20260315000037_phase27_verification_rating.sql` (vq_hold_until privacy pattern)
- Direct codebase inspection — `supabase/migrations/20260315000038_phase28_vq_confirm_stance.sql` (advisory lock pattern)
- Direct codebase inspection — `tests/integration/architecture.test.ts` (architecture enforcement rules)
- `MEMORY.md` — Critical Production Pattern: `pool.query()` for all non-public schema writes

### Secondary (MEDIUM confidence)

- [Common Postgres RLS Footguns](https://www.bytebase.com/blog/postgres-row-level-security-footguns/) — OR-policy combination behavior (validates Pitfall 2)
- [Supabase PostgREST Aggregate Functions](https://supabase.com/blog/postgrest-aggregate-functions) — row limit behavior (validates Pitfall 7)
- [10 RBAC Best Practices 2025](https://www.osohq.com/learn/rbac-best-practices) — scoped vs global roles design patterns (validates Pitfall 6)

---
*Research completed: 2026-03-19*
*Ready for roadmap: yes*
