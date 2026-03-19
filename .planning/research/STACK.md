# Technology Stack: v1.6 Civic Identity and Roles

**Project:** empowered-accounts
**Dimension:** Additive stack decisions for v1.6 features
**Researched:** 2026-03-19
**Confidence:** HIGH (all claims grounded in direct codebase inspection; no new external libraries required)

This file covers only additive stack decisions for v1.6. The base stack (Express 4.x, TypeScript strict, supabase-js v2, pg raw driver, Upstash Redis, Vite + React + Tailwind v4) is unchanged and documented in MEMORY.md and prior STACK.md files. Do not restate the base stack.

---

## Feature 1: Scoped Roles System

### What needs to change

The current `public.user_roles` table associates a user with a role (FK to `public.roles`) and records grant/revoke timestamps. It has no `feature` dimension and no `jurisdiction_geoid` column.

The `public.roles` table records named roles (contributor, candidate, maven, etc.) but does not distinguish between "platform admin" roles and "feature-developer API access" roles. The v1.6 scoped roles system introduces a new dimension: roles granted specifically to allow a feature repo (CTC, Quest, Essentials, Compass) to act on behalf of a user within a geographic scope.

### Decision: Extend `public.user_roles` in-place — do NOT create a separate table

**Why:** Creating a `scoped_roles` table would duplicate the grant/revoke lifecycle machinery (partial unique index on active grants, soft-revocation pattern, conflict enforcement, `grant_role` / `revoke_role` / `get_user_roles` RPCs) that already works and is tested. The existing `public.user_roles` infrastructure is the right place for this. The new dimensions (`feature`, `jurisdiction_geoid`) are additive columns — nullable in the current schema upgrade sense, with `feature` defaulting to null for existing civic roles and `jurisdiction_geoid` defaulting to null meaning national scope.

**How:** Add two columns to `public.user_roles`:
- `feature TEXT` — nullable. When set, constrains the grant to a specific feature dimension (e.g., `'ctc'`, `'quest'`, `'essentials'`, `'compass'`, `'admin'`). Null = civic role, not feature-scoped.
- `jurisdiction_geoid TEXT` — nullable. When null, the role has national scope. When set, the role is geo-restricted (e.g., `'18105'` for Monroe County, Indiana). Validated against known GEOID formats; not a FK (GEOIDs are TIGER/Line strings, not rows in this database).

**The partial unique index must be updated:** The current index `idx_user_roles_active_unique` is `UNIQUE (user_id, role_id) WHERE revoked_at IS NULL`. After adding `feature` and `jurisdiction_geoid`, the uniqueness constraint must be `(user_id, role_id, COALESCE(feature, ''), COALESCE(jurisdiction_geoid, '')) WHERE revoked_at IS NULL` — a user can hold the same named role with different feature+jurisdiction combinations simultaneously (e.g., Essentials Dev for Monroe County AND Essentials Dev for Johnson County are two separate active grants).

**Update `grant_role` and `get_user_roles` RPCs** to accept and return the new columns. The `requireAdmin` middleware check against `public.admin_users` is unchanged — it is separate from the roles system. The new `requireFeatureRole` middleware will query `user_roles` for a matching active grant with the caller's `feature` + optional `jurisdiction_geoid`.

### New middleware: `requireFeatureRole`

Located in `src/middleware/featureRoleGuard.ts`. Follows the pattern of existing `requireConnected` — queries `user_roles` via `supabaseAdmin` (middleware is excluded from the architecture test route-scan), checks for an active grant matching `(userId, feature, jurisdiction_geoid)`. Returns 403 if no match.

The middleware factory signature: `requireFeatureRole(feature: string, geoid?: string)` returns an Express middleware function. Routes that need feature-scoped auth use: `router.use(requireAuth, requireFeatureRole('ctc'))`.

No new npm packages needed. The check is a SQL EXISTS query — identical pattern to `requireAdmin` and `requireConnected`.

### No changes to `requireAdmin`

`requireAdmin` checks `public.admin_users`. That table and check remain as-is. The scoped roles system is additive — it adds fine-grained feature access, it does not replace the coarse admin check for admin UI routes.

### TypeScript changes

Add `feature: string | null` and `jurisdiction_geoid: string | null` to the role grant return types in `roleService.ts`. Update `getAllActiveRoles` to return these fields if present on `public.roles`. Add the new columns to `database.types.ts` after regenerating types from the migration (`supabase gen types`).

### Stack impact: none (no new dependencies)

All changes are SQL migrations + TypeScript additions within the existing service/middleware pattern.

---

## Feature 2: Compass Compare API

### What the endpoint needs to do

Given two user IDs (or one user ID + one politician ID), query `inform.compass_responses` for both subjects, find topics answered by both, and return per-topic comparison objects. The response shape is: `{ shared_topics: number, agreement: number, disagreement: number, topics: [{ topic_id, user_a_value, user_b_value, agrees: boolean }] }`.

### Decision: SQL query in `compassService.ts` — no new RPC needed for read-only compare

**Why no new SECURITY DEFINER RPC:** The compare operation is a pure read — two SELECTs and a JOIN in application code. It does not modify any data, so it has no need for atomic multi-table writes (the reason SECURITY DEFINER RPCs exist in this project). The existing `supabaseAdmin` is appropriate here: both users' answers are read server-side only, and the middleware layer enforces that only the requesting user can trigger their own compare.

**The query:** Fetch `inform.compass_responses` for user A filtered by `deleted_at IS NULL` (use `.is('deleted_at', null)` — project convention). Fetch the same for user B. In TypeScript, compute the intersection by topic_id and calculate agreement. This avoids a complex multi-user SQL query and runs fine at Alpha scale (21 live topics maximum per user, O(n) intersection in JS).

**Visibility enforcement:** User B's responses are only included if their visibility for that topic is `'public'` or if the requesting user is in user B's peer connections. At Alpha scale, the simple rule is: only compare on topics where B has `visibility = 'public'`, OR user A and user B are connected (check `connect.social_relationships`). This check uses the existing `supabaseAdmin` pattern for server-side reads.

**For politician compare:** Politician answers are in `inform.politician_answers` (no visibility column — all politician stances are public). This path already exists in `compassService.getPoliticianAnswers`. The compare endpoint reuses this function.

### No new database extension or npm package needed

This is a TypeScript join of two existing query results. No special math library, no new SQL function. The "agreement" calculation is: `user_a_value === user_b_value` (or within a configurable tolerance for NUMERIC(3,1) values — 0.0 tolerance for exact match, project team to decide; start with exact match).

### Stack impact: none (no new dependencies)

Add `compareCompassAnswers(userAId, userBId, requestingUserId)` to `compassService.ts`. Add the endpoint to `compass.ts` route file.

---

## Feature 3: VR Admin Dashboard

### What it needs to render

A React admin page showing:
1. Histogram of verification_rating distribution across all connected users (buckets: 0–29, 30–59, 60–89, 90–119, 120–150)
2. Count of users currently on VQ hold (`vq_hold_until > now()`)
3. Outlier list: users with VR below 30 (at-risk) and users with VR above 120 (exceptionally high)

### Decision: Server-side aggregation via `pool.query()` — no charting library in admin

**Why pool.query():** The VR stats query joins `connect.connected_profiles` with a `CASE WHEN` bucketing expression. This is a `connect` schema write — wait, this is a read. However, the critical pattern established in v1.3 is: `supabaseAdmin.schema('connect').from()` works for reads but not writes. Reads from `connect.connected_profiles` via `supabaseAdmin.schema('connect')` do work. Use `supabaseAdmin` for the aggregate read.

Actually — reassess. The dashboard needs a `GROUP BY` with computed bucket expressions or a multi-bucket COUNT. `supabaseAdmin.schema('connect').from('connected_profiles').select(...)` cannot express `CASE WHEN verification_rating < 30 THEN 'at_risk' ...` bucketing natively in PostgREST. Use `pool.query()` with a direct SQL aggregate for the histogram. This is the correct choice: `pool.query()` for any query that needs SQL features PostgREST cannot express.

The query returns `{ bucket: string, count: number }[]` — small, stable, fast.

**Why no charting library:** The admin app already renders stat cards (AdminDashboard) and tree visualizations (`@xyflow/react` for InviteTree). A histogram at Alpha scale (likely < 100 users) is just a series of bar divs with percentage widths driven by the count values. Tailwind v4 flex + width utilities are sufficient. Installing Recharts or Chart.js for a 5-bucket histogram on an internal admin tool with < 100 users is over-engineering.

**If the team disagrees:** The only reasonable candidate would be `recharts` (MIT, React-native, no D3 peer dependency required separately). It is already in wide use across React admin tools. But it adds ~80KB to the admin bundle for a use case that divs can cover. Recommendation stands: no charting library for v1.6.

### New admin service function: `getVrDashboardStats()`

In `adminService.ts`. Returns:

```typescript
interface VrDashboardStats {
  buckets: Array<{ label: string; min: number; max: number; count: number }>;
  on_hold_count: number;
  at_risk_users: Array<{ user_id: string; display_name: string; verification_rating: number }>;
  high_vr_users: Array<{ user_id: string; display_name: string; verification_rating: number }>;
}
```

The `at_risk_users` and `high_vr_users` lists are capped at 20 rows each — this is an admin diagnostic view, not a paginated list.

### New admin route: `GET /api/admin/vr-dashboard`

Follows existing admin route pattern: `requireAuth` + `requireAdmin` middleware applied via `router.use()`. Returns `VrDashboardStats`. No caching needed at Alpha scale; these are fast aggregate queries on a small table.

### New admin React page: `VrDashboardPage.tsx`

In `admin/src/pages/admin/`. Added to `AdminLayout.tsx` nav and `App.tsx` routes. Follows the `AdminDashboard.tsx` pattern: `apiFetch`, loading skeleton, stat cards. The histogram renders as a list of bar rows with Tailwind `bg-ev-red` fill proportional to each bucket's count as a percentage of the largest bucket.

### Stack impact: none (no new dependencies)

No new npm packages. Backend uses `pool.query()` (already installed). Admin uses Tailwind v4 (already installed). No charting library needed.

---

## Feature 4: Essentials XP Source Provisioning

This is confirmed trivial — `serviceKeyAuth.ts` already has the `ESSENTIALS_SERVICE_KEY` block present (verified in codebase: line 22–24 of `serviceKeyAuth.ts` already adds `'essentials-rep-lookup'` to the key map when `env.ESSENTIALS_SERVICE_KEY` is set). The service key env var just needs to be provisioned in the Render environment and in `.env.example`. No code change required.

---

## No New npm Dependencies for v1.6

This is the key finding. Every v1.6 feature is implementable within the existing stack:

| Feature | Why no new dependency |
|---------|----------------------|
| Scoped roles | New SQL columns + TypeScript additions in existing service layer |
| `requireFeatureRole` middleware | EXISTS query on `user_roles` — same pattern as `requireAdmin` |
| Compass compare | JavaScript Set intersection of two existing query results |
| VR histogram | `pool.query()` with GROUP BY + Tailwind div bars |
| VR admin page | React + `apiFetch` — same pattern as `AdminDashboard.tsx` |
| Essentials XP provisioning | Env var only, code already shipped |

**Do not add:**
- A permissions library (CASL, Casbin, etc.) — the `user_roles` table IS the permission store; an additional library layer would duplicate it and add a learning surface
- A charting library (Recharts, Chart.js, Visx) — five static buckets rendered as proportional divs is not a chart library problem
- A new RPC for compass compare — pure read, no atomicity needed, TypeScript join is correct
- Any new Postgres extension — no new data types, spatial operations, or encryption needed

---

## Integration Points with Existing Patterns

| Pattern | v1.6 Usage |
|---------|------------|
| `pool.query()` for non-public schema writes | `public.user_roles` migration alters a public schema table (PostgREST can handle); VR histogram uses `pool.query()` for GROUP BY |
| `supabaseAdmin` banned from `src/routes/` | New `featureRoleGuard.ts` middleware follows same exception as `requireAdmin.ts` and `tierGuards.ts` |
| SECURITY DEFINER RPC for multi-table atomic writes | Applies to: `grant_role` RPC update (add `p_feature` + `p_jurisdiction_geoid` params). Does NOT apply to compass compare (read-only). |
| Two-pass validation in admin RPCs | Apply to updated `grant_role` RPC: validate feature value against known enum before inserting |
| `logAdminAction()` before every mutation 200 | Required for any new admin route that mutates (VR dashboard is read-only; role grant/revoke already logs) |
| `SET search_path = ''` on all SECURITY DEFINER functions | Required for updated `grant_role` + `revoke_role` RPCs |
| Partial unique index on active grants | Must be updated in migration to include `feature` + `jurisdiction_geoid` dimensions |

---

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| Scoped roles via column extension | HIGH | Direct inspection of migration 020 schema, roleService.ts, and existing partial index definition |
| No new table needed for scoped roles | HIGH | Existing grant/revoke lifecycle machinery is reused; columns are additive |
| Compass compare as TypeScript join | HIGH | inspect compass_responses query patterns in compassService.ts; Alpha scale (21 topics) makes JS join trivially fast |
| VR histogram via pool.query() | HIGH | Established pattern for cross-schema aggregates; PostgREST cannot express CASE WHEN bucketing |
| No charting library needed | HIGH | 5 buckets, < 100 users at Alpha; Tailwind proportional divs are sufficient |
| Essentials XP already shipped | HIGH | serviceKeyAuth.ts lines 22-24 confirmed present in codebase |
| No new npm packages | HIGH | Each feature maps to existing stack primitives |
