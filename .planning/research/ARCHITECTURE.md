# Architecture Patterns — v1.6 Civic Identity & Roles

**Domain:** Scoped roles, compass compare, VR admin dashboard integration into existing Express/Supabase/React app
**Researched:** 2026-03-19
**Confidence:** HIGH — all patterns derived from the actual codebase, not documentation or training data

---

## Context: What Exists Today

Before describing what must be built, here is the current state that every v1.6 component integrates against.

### Current Roles Schema (public schema)

```
public.roles
  id            UUID PK
  name          TEXT UNIQUE
  slug          TEXT UNIQUE
  required_tier TEXT CHECK ('connected' | 'empowered')
  description   TEXT
  is_active     BOOLEAN DEFAULT true
  created_at    TIMESTAMPTZ

public.user_roles
  id          UUID PK
  user_id     UUID FK → public.users(id)
  role_id     UUID FK → public.roles(id)
  granted_by  UUID FK → public.users(id)
  granted_at  TIMESTAMPTZ DEFAULT now()
  revoked_at  TIMESTAMPTZ (null = active)
  UNIQUE INDEX idx_user_roles_active_unique ON (user_id, role_id) WHERE revoked_at IS NULL
```

Roles are in `public` schema (not `connect`). `user_roles` is soft-deleted via `revoked_at`. Re-grant creates a new row; old row is permanent audit history. No geography dimension exists today.

### Current Admin Check

`public.admin_users` is a separate table (not a role). `requireAdmin` middleware checks this table via `supabaseAdmin`. It is entirely independent of `public.user_roles`. Admin users can hold `user_roles` AND be in `admin_users` — these are parallel, not hierarchical.

### Current RPCs for Roles

Three `SECURITY DEFINER` RPCs exist in the public schema:
- `grant_role(p_user_id, p_role_slug)` — enforces tier eligibility and conflict rules
- `revoke_role(p_user_id, p_role_slug)` — soft-revokes via `revoked_at`
- `get_user_roles(p_user_id)` — returns active grants

All called via `adminRpc()` in `roleService.ts`.

### Current Jurisdiction Fields

Jurisdiction is resolved on-the-fly from encrypted coordinates via `connect.resolve_user_jurisdiction()` RPC. The five GEOIDs (congressional, state_senate, state_house, county, school_district) are **not stored as columns** on `connected_profiles` — they are computed from PostGIS at request time. The `GET /api/account/me` and `GET /api/connect/set-location` responses both call this RPC and embed the result in the response body.

There are no `congressional_geoid` columns or similar on `connected_profiles`. The GEOID lives only in `inform.district_boundaries.geoid`.

---

## Component 1: Scoped Roles (ROLES-01)

### What Changes

The existing flat role model has no feature dimension or geography dimension. ROLES-01 adds both. The approach is additive: extend the existing tables, do not replace them.

### Schema Changes

**Extend `public.roles` — add feature dimension:**

```sql
ALTER TABLE public.roles
  ADD COLUMN feature_scope TEXT CHECK (feature_scope IN (
    'ctc_dev', 'quest_dev', 'essentials_dev', 'compass_dev', 'admin', 'general'
  ));
-- NULL = role has no feature scope (general civic roles like 'contributor', 'candidate')
-- Non-NULL = role is scoped to a specific feature integration
```

**Extend `public.user_roles` — add geography dimension:**

```sql
ALTER TABLE public.user_roles
  ADD COLUMN jurisdiction_geoid TEXT;
  -- NULL = national/unrestricted grant
  -- Set = geo-restricted (e.g., '1807' for Indiana's 7th congressional)
  -- No FK to district_boundaries — GEOIDs are string identifiers, not row references
```

**Update the partial unique index to include jurisdiction:**

```sql
DROP INDEX IF EXISTS idx_user_roles_active_unique;
CREATE UNIQUE INDEX idx_user_roles_active_unique
  ON public.user_roles(user_id, role_id, COALESCE(jurisdiction_geoid, ''))
  WHERE revoked_at IS NULL;
-- COALESCE trick: allows NULL geoid to be part of uniqueness without NULLs
-- never being equal. A user can have the same role both nationally (NULL geoid)
-- and for a specific jurisdiction.
```

**Seed the five new feature-scoped roles:**

```sql
INSERT INTO public.roles (name, slug, required_tier, feature_scope, description, is_active) VALUES
  ('CTC Developer',       'ctc_dev',       'connected', 'ctc_dev',       'Civic Trivia Championship service key holder', true),
  ('Quest Developer',     'quest_dev',     'connected', 'quest_dev',     'Validation Quests service key holder',         true),
  ('Essentials Developer','essentials_dev','connected', 'essentials_dev','Essentials service key holder',                true),
  ('Compass Developer',   'compass_dev',   'connected', 'compass_dev',   'CompassV2 service key holder',                 true),
  ('Platform Admin',      'platform_admin','connected', 'admin',         'Platform administration access',               true)
ON CONFLICT (slug) DO NOTHING;
```

### RPC Changes

The existing `grant_role` and `revoke_role` RPCs need a `p_jurisdiction_geoid` parameter added. The RPCs are `SECURITY DEFINER` with `SET search_path = ''`, following the established pattern.

**Updated signature for `grant_role`:**

```sql
CREATE OR REPLACE FUNCTION public.grant_role(
  p_user_id           uuid,
  p_role_slug         text,
  p_jurisdiction_geoid text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
-- Two-pass validation before any writes:
-- 1. Role exists + is_active
-- 2. User meets required_tier
-- 3. No duplicate active grant for (user_id, role_id, jurisdiction_geoid)
-- Then INSERT into public.user_roles with jurisdiction_geoid
$$;
```

**Updated signature for `revoke_role`:**

```sql
CREATE OR REPLACE FUNCTION public.revoke_role(
  p_user_id           uuid,
  p_role_slug         text,
  p_jurisdiction_geoid text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
-- Sets revoked_at = now() on the matching active row
-- Matches on (user_id, role_id, jurisdiction_geoid IS NOT DISTINCT FROM p_jurisdiction_geoid)
$$;
```

`get_user_roles` returns `jurisdiction_geoid` in its result set — add to the output columns.

### New Middleware: `requireRole`

The new `requireRole` middleware replaces the pattern of `requireAdmin` for feature-gated routes. `requireAdmin` itself is NOT removed — it continues to gate the admin UI routes. `requireRole` is a separate, additive middleware.

```typescript
// src/middleware/requireRole.ts

export function requireRole(featureScope: string, jurisdictionGeoid?: string) {
  return async function(req: Request, res: Response, next: NextFunction): Promise<void> {
    const authReq = req as AuthenticatedRequest;
    // Call a new hasRole() function in roleService.ts
    // which does a single pool.query() against public.user_roles + public.roles
    // to check: active grant where roles.feature_scope = featureScope
    // AND (jurisdiction_geoid IS NULL OR jurisdiction_geoid = jurisdictionGeoid)
    // Returns 403 with { code: 'ROLE_REQUIRED', feature: featureScope } if not found
    next();
  };
}
```

The check uses `pool.query()` (not `supabaseAdmin`) because `public.user_roles` is in the public schema but this is a privileged server-side check. The architecture test's allowlist will need `middleware/requireRole.ts` added if it references `supabaseAdmin`. Prefer `pool.query()` to avoid that concern entirely.

### Service Layer Changes

`roleService.ts` needs:
1. `grantRole(userId, roleSlug, jurisdictionGeoid?)` — updated to pass optional param to RPC
2. `revokeRole(userId, roleSlug, jurisdictionGeoid?)` — same
3. `getUserRoles(userId)` — return type adds `jurisdiction_geoid: string | null`
4. New `hasRole(userId, featureScope, jurisdictionGeoid?)` — for `requireRole` middleware

### API Changes

**Existing routes remain unchanged for backwards compatibility.**

Admin role management endpoints at `POST /api/admin/roles/grant` and `POST /api/admin/roles/revoke` need the optional `jurisdiction_geoid` field added to their request body schema.

**New read endpoint:**

```
GET /api/roles/me
```

Already exists. Return type adds `jurisdiction_geoid: string | null` per grant. No breaking change — additive field.

### Backwards Compatibility

- `public.admin_users` and `requireAdmin` are untouched. All existing admin routes keep working.
- Existing `user_roles` rows have `jurisdiction_geoid = NULL` after migration — they remain valid national grants.
- The `idx_user_roles_active_unique` index change is the only destructive migration step. It must DROP the old index and CREATE the new one in a single transaction.
- `grant_role` and `revoke_role` RPCs use `DEFAULT NULL` for the new parameter — existing callers (`roleService.ts`) still compile without changes. Service layer is updated separately to pass the value when available.

---

## Component 2: Compass Compare (COMP-05)

### What Exists

`inform.compass_responses` stores `(user_id, topic_id, value, visibility, deleted_at)`. The `visibility` column controls whether a Connected user's answers are public or private. Empowered users always have public visibility (set atomically during empowerment).

No compare query or endpoint exists today.

### What Must Be Built

**No schema migrations required.** Compass compare is a read-only query against existing tables.

### Query Pattern

The compare query joins two users' responses on `topic_id`. The output must include only topics where BOTH users have a non-deleted response. Visibility rules apply: a user's answers are only included if `visibility = 'public'` (or the viewer IS the owner — the API caller can always see their own answers).

```sql
-- Conceptual query — will live in a SECURITY DEFINER RPC for atomicity
-- and to centralize visibility rule enforcement

SELECT
  ct.id          AS topic_id,
  ct.title,
  ct.short_title,
  a.value        AS user_a_value,
  b.value        AS user_b_value,
  ABS(a.value - b.value) AS divergence
FROM inform.compass_topics ct
JOIN inform.compass_responses a
  ON a.topic_id = ct.id
  AND a.user_id = p_user_a_id
  AND a.deleted_at IS NULL
JOIN inform.compass_responses b
  ON b.topic_id = ct.id
  AND b.user_id = p_user_b_id
  AND b.deleted_at IS NULL
WHERE ct.is_live = true
  -- Visibility enforcement for user B:
  -- Either the requester IS user B (viewing own), OR user B's answer is public
  AND (b.user_id = p_requester_id OR b.visibility = 'public')
  -- Visibility enforcement for user A:
  AND (a.user_id = p_requester_id OR a.visibility = 'public')
ORDER BY ct.title;
```

The divergence field (absolute difference of values) enables CompassV2 and Essentials to render overlap visually without computing it client-side.

### New RPC Signature

```sql
CREATE OR REPLACE FUNCTION public.compare_compass_responses(
  p_requester_id uuid,
  p_user_a_id    uuid,
  p_user_b_id    uuid   -- can equal p_requester_id; can be NULL for politician compare
)
RETURNS TABLE (
  topic_id      uuid,
  title         text,
  short_title   text,
  user_a_value  numeric,
  user_b_value  numeric,
  divergence    numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
-- Two-pass validation: both users exist and have connected profiles (or politicians)
-- Then the JOIN query above
$$;
```

For user-to-politician compare, `p_user_b_id` is a politician UUID and the query joins `inform.politician_answers` instead of `inform.compass_responses`. A single RPC can handle both cases by checking whether `p_user_b_id` matches a row in `inform.politicians`.

### New API Endpoint

```
GET /api/compass/compare/:userId
```

- Auth: `requireAuth` (viewing own vs another user)
- `:userId` can be a user UUID or a politician UUID
- The endpoint calls `compare_compass_responses(requester_id, requester_id, :userId)` — the requester is always user A
- Returns: `{ shared_topics: CompareResult[], agreement_score: number }`

**Response shape (CompassV2 and Essentials both consume this):**

```typescript
interface CompareResult {
  topic_id: string;
  title: string;
  short_title: string;
  my_value: number;     // requester's value
  their_value: number;  // target user/politician value
  divergence: number;   // abs(my_value - their_value); 0 = full agreement
}

interface CompareResponse {
  shared_topics: CompareResult[];
  agreement_score: number;  // percentage: topics with divergence <= 1.0 / total shared topics
  total_shared: number;
}
```

The `agreement_score` is computed server-side from the results — clients never compute this themselves.

### Service Layer

New `compareCompassResponses(requesterId, targetId)` function in `compassService.ts`. Calls the RPC via `adminRpc()`. Returns typed `CompareResponse`. No new service file needed — compass compare belongs in `compassService.ts`.

### Visibility Edge Cases

- If the target user has `visibility = 'private'` on all topics, `shared_topics` is `[]` and `agreement_score` is null (not 0 — 0 would imply complete disagreement).
- If the target is a politician, visibility rules do not apply (politician answers are always public).
- The requester can compare themselves to themselves: returns 100% agreement (self-compare is valid for debugging).

---

## Component 3: VR Admin Dashboard (VR-F01)

### What Exists

`connect.connected_profiles` has:
- `verification_rating` INT DEFAULT 60 NOT NULL
- `vq_hold_until` TIMESTAMPTZ (null = no hold active)

No aggregate view or admin query exists. The existing `updateVerificationRating` in `adminService.ts` does per-user writes via `pool.query()`. No read-across-all-users query for VR exists.

### What Must Be Built

**No schema migrations required.** VR dashboard is purely a new read query + admin endpoint + React admin page.

### Query Pattern

The VR dashboard must paginate — returning all rows is not safe at scale. Two query surfaces are needed:

**1. Distribution aggregate (no pagination needed — bounded result):**

```sql
-- Five VR buckets: 0-29, 30-59, 60-89, 90-119, 120-150
SELECT
  COUNT(*) FILTER (WHERE verification_rating BETWEEN 0   AND 29 ) AS bucket_0_29,
  COUNT(*) FILTER (WHERE verification_rating BETWEEN 30  AND 59 ) AS bucket_30_59,
  COUNT(*) FILTER (WHERE verification_rating BETWEEN 60  AND 89 ) AS bucket_60_89,
  COUNT(*) FILTER (WHERE verification_rating BETWEEN 90  AND 119) AS bucket_90_119,
  COUNT(*) FILTER (WHERE verification_rating BETWEEN 120 AND 150) AS bucket_120_150,
  COUNT(*) FILTER (WHERE vq_hold_until > now())                   AS on_hold_count,
  COUNT(*)                                                         AS total_connected
FROM connect.connected_profiles;
```

**2. Paginated user list with VR data (for outlier review):**

```sql
SELECT
  cp.user_id,
  u.display_name,
  cp.verification_rating,
  cp.vq_hold_until,
  (cp.vq_hold_until IS NOT NULL AND cp.vq_hold_until > now()) AS vq_hold_active
FROM connect.connected_profiles cp
JOIN public.users u ON u.id = cp.user_id
ORDER BY cp.verification_rating ASC  -- or DESC, or by vq_hold_until
LIMIT 25 OFFSET $page_offset;
```

Both queries touch the `connect` schema. Following the established pattern: **these must use `pool.query()`, not PostgREST**. PostgREST fails for `connect` schema writes; reads can be fragile for cross-schema joins. Use `pool.query()` for safety.

### New Admin API Endpoints

Two new endpoints added to `admin.ts` (which already has `router.use(requireAuth, requireAdmin)`):

```
GET /api/admin/vr-dashboard
```

Returns the distribution aggregate. No pagination needed — result is always 7 numbers.

```
GET /api/admin/vr-dashboard/users?sort=asc|desc|hold&page=1
```

Returns paginated user list sorted by VR (ascending = lowest first, for outlier review) or by hold status. Default sort is `asc` (shows lowest-VR users first).

**Response shapes:**

```typescript
interface VRDashboardResponse {
  distribution: {
    bucket_0_29:   number;
    bucket_30_59:  number;
    bucket_60_89:  number;  // default / unverified bucket
    bucket_90_119: number;  // red gem quest unlocked
    bucket_120_150: number; // high trust
  };
  on_hold_count: number;
  total_connected: number;
}

interface VRUserListResponse {
  users: Array<{
    user_id: string;
    display_name: string;
    verification_rating: number;
    vq_hold_active: boolean;
    vq_hold_until: string | null;  // ISO 8601
  }>;
  total: number;
  page: number;
  pages: number;
}
```

### Service Layer

New functions in `adminService.ts`:
- `getVRDashboard()` — runs the aggregate query via `pool.query()`
- `getVRUsers(params: { sort: 'asc' | 'desc' | 'hold'; page: number })` — paginated list via `pool.query()`

No new service file. VR dashboard is an admin read operation; it belongs in `adminService.ts`.

### Admin React UI

New `VRDashboardPage.tsx` in `admin/src/`. Route: `/admin/vr-dashboard`. Two sections:
1. Distribution bar chart or bucket summary (5 buckets + on-hold count)
2. Paginated user table with VR value, hold status, and direct link to `AccountDetailPage` for per-user VR override

Colors follow brand tokens: `ev-teal` for normal range, `ev-yellow` for 90+ (red gem unlocked), `ev-red` for on-hold.

---

## Component 4: Essentials XP Source Provisioning (ESSENTIALS-PROV)

### What Changes

`serviceKeyAuth.ts` already has the `ESSENTIALS_SERVICE_KEY` env var wired and maps it to `['essentials-rep-lookup']`. This was a pre-emptive addition. Verifying the file confirms the mapping is already present (confirmed by code read during research).

**No code change needed in `serviceKeyAuth.ts` — it is already correct.**

The remaining work is:
1. Set `ESSENTIALS_SERVICE_KEY` in the Render environment with a real secret value
2. Update `docs/ESSENTIALS-INTEGRATION.md` to document the correct env var name for `GEMS_SERVICE_KEYS`

This is a 2-file change at most (env config + docs). No migration, no new middleware, no new routes.

---

## Build Order

The four v1.6 components have the following dependency graph:

```
ESSENTIALS-PROV         — no dependencies, can ship standalone
      |
      v
COMP-05                 — no schema dependencies; needs compassService.ts
      |
      v
VR-F01                  — no schema dependencies; needs adminService.ts read queries
      |
      v
ROLES-01                — schema migration required; impacts requireAdmin replacement pattern;
                          must be last because it is the largest and most disruptive
```

**Recommended phase order:**

1. **ESSENTIALS-PROV first** — 2-file change, closes a documented gap, unblocks Essentials team.
2. **COMP-05 second** — read-only, no migrations, self-contained. Proves the compare RPC pattern before roles adds schema complexity.
3. **VR-F01 third** — read-only queries, no migrations. Admin UI work is independent of roles.
4. **ROLES-01 last** — requires schema migration, index change, RPC updates, new middleware. Highest blast radius. Built last so the other three features are not blocked on it.

---

## Component Boundary Summary

| Component | New Files | Modified Files | New Migrations | New RPCs |
|-----------|-----------|----------------|----------------|----------|
| ESSENTIALS-PROV | 0 | 1 (docs only) | 0 | 0 |
| COMP-05 | 0 | `compassService.ts`, `compass.ts` | 1 (RPC only) | 1 (`compare_compass_responses`) |
| VR-F01 | `VRDashboardPage.tsx` | `adminService.ts`, `admin.ts` | 0 | 0 |
| ROLES-01 | `requireRole.ts` | `roleService.ts`, `admin.ts`, `architecture.test.ts` | 2 (schema + RPCs) | 2 (updated `grant_role`, `revoke_role`) |

---

## Patterns That Must Not Change

These are the constraints every v1.6 implementation must follow, derived from the codebase and architecture tests:

1. **`pool.query()` for all non-public schema writes.** `connect.connected_profiles` VR reads should also use `pool.query()` for cross-schema JOIN safety.

2. **`supabaseAdmin` banned from `src/routes/`.** Any new service function that references `supabaseAdmin` must live in `src/lib/`. Architecture test allowlist must be updated when a new lib file is added.

3. **SECURITY DEFINER with `SET search_path = ''`.** All new RPCs must use fully qualified table references (`connect.connected_profiles`, not `connected_profiles`).

4. **Two-pass validation in RPCs.** Validate all inputs before any writes. Applied to `grant_role` update and `compare_compass_responses`.

5. **`requireAdmin` is NOT replaced.** It continues to guard all `/api/admin/*` routes. `requireRole` is additive for external-facing feature routes, not a replacement.

6. **Soft-delete filter on compass reads.** Any query against `inform.compass_responses` must include `.is('deleted_at', null)` or `AND deleted_at IS NULL` in raw SQL. The compare query must enforce this.

7. **Advisory locks in sorted UUID order for any multi-user write.** Compass compare is read-only — advisory locks not needed. If ROLES-01 ever involves multi-user grants in a single RPC, sort UUIDs before locking.

8. **Audit trail required for all admin mutations.** `logAdminAction()` must be called for VR dashboard user-list actions only if they trigger mutations (reads do not require logging). Role grant/revoke already calls `logAdminAction`.

---

## Open Questions (Resolve Before Implementation)

1. **Compass compare — self-compare.** Should `GET /api/compass/compare/:userId` where `:userId` equals the requester's own ID return a 400, or silently return 100% agreement? CompassV2 and Essentials should be consulted before the endpoint is built.

2. **ROLES-01 — migration order for index change.** The `COALESCE` trick in the new unique index is not standard. Validate on a test migration that `COALESCE(jurisdiction_geoid, '')` produces the correct uniqueness behavior for `NULL` geoids before shipping.

3. **VR-F01 — sort options.** The spec says "distribution, holds, outliers." Confirm with product whether the paginated list needs a third sort option for `hold` (sorts by `vq_hold_until DESC NULLS LAST`) before building the React UI.

4. **ROLES-01 — `requireRole` placement in existing routes.** Once `platform_admin` role exists, should `requireAdmin` middleware be deprecated in favor of `requireRole('admin')`? This is an architectural decision about the long-term path. For v1.6, keep both. Decide before v1.7.

---

## Sources

All findings verified against actual codebase files:
- `backend/src/middleware/requireAdmin.ts` — admin check pattern
- `backend/src/middleware/serviceKeyAuth.ts` — service key pattern, ESSENTIALS_SERVICE_KEY confirmed present
- `backend/src/lib/roleService.ts` — existing role RPC wrappers
- `backend/src/lib/adminService.ts` — VR override pattern, pool.query() usage
- `backend/src/routes/compass.ts` — compass endpoint patterns
- `backend/src/types/database.types.ts` — existing RPC signatures
- `supabase/migrations/20260227000020_phase6_roles_schema.sql` — roles table structure
- `supabase/migrations/20260310000032_location_rpcs.sql` — SECURITY DEFINER + SET search_path pattern
- `tests/integration/architecture.test.ts` — architecture enforcement rules
- Confidence: HIGH for all components (all claims derived from live code)
