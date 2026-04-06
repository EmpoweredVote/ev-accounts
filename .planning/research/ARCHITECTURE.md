# Architecture Patterns — v1.9 Delegated Authority / Scoped Roles

**Domain:** Scoped role authorization on top of an existing tier system
**Researched:** 2026-04-02
**Basis:** Direct source inspection (requireAdmin.ts, tierGuards.ts, auth.ts,
roleService.ts, admin.ts routes, phase6 migrations 020/023, phase7 migration 024,
Civic Spaces useAuth.ts + supabase.ts, app/src App.tsx + authStore.ts)

---

## Current State of `public.user_roles`

After migration `20260227000020_phase6_roles_schema.sql`, the table is:

```sql
CREATE TABLE public.user_roles (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role_id    UUID        NOT NULL REFERENCES public.roles(id),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at TIMESTAMPTZ                         -- NULL = active; non-NULL = revoked
);

-- Active-only uniqueness: one active grant per (user, role)
CREATE UNIQUE INDEX idx_user_roles_active_unique
  ON public.user_roles(user_id, role_id) WHERE revoked_at IS NULL;

CREATE INDEX idx_user_roles_user_id ON public.user_roles(user_id);
```

**Important pre-existing gap:** The `grant_role`, `revoke_role`, and `get_user_roles`
RPC functions referenced in `roleService.ts` via `adminRpc()` do not exist in any
migration. They must be created in the v1.9 migration. Until that migration runs,
those `adminRpc` calls will error at runtime. This is a pre-existing gap to close
in v1.9, not a regression introduced by this milestone.

---

## 1. Schema Changes

### 1a. ALTER `public.user_roles` — add scope columns

```sql
-- Migration: phase_XX_scoped_roles_schema.sql

BEGIN;

-- Add feature scope: which sub-system the role grant applies to.
-- NULL = system-wide (no feature restriction). Non-NULL = scoped to one feature.
-- Valid values mirror existing route namespaces.
ALTER TABLE public.user_roles
  ADD COLUMN IF NOT EXISTS feature_scope TEXT
    CHECK (feature_scope IN ('compass', 'ctc', 'essentials', 'civic_spaces', 'vq'));

-- Add jurisdiction geo scope: restricts the role to a specific geo boundary.
-- NULL = unrestricted (all jurisdictions). Non-NULL = one geoid from geo.jurisdictions.
-- IMPORTANT: NULL geo-scope means "all jurisdictions".
-- Middleware MUST use: (ur.jurisdiction_geoid IS NULL OR ur.jurisdiction_geoid = $x)
-- NEVER use bare equality (ur.jurisdiction_geoid = $x) — fails when $x is NULL.
ALTER TABLE public.user_roles
  ADD COLUMN IF NOT EXISTS jurisdiction_geoid TEXT;

-- Add resource scope: restricts the role to a specific record (e.g., one civic space).
-- NULL = no resource restriction.
ALTER TABLE public.user_roles
  ADD COLUMN IF NOT EXISTS resource_id UUID;


-- Drop the old active-only unique index and replace with a scope-aware version.
-- The previous index prevented duplicate (user_id, role_id) active grants globally.
-- With scoping, the same role can be held for different (feature, geoid, resource)
-- combinations — e.g., volunteer in district A AND district B are two valid rows.
DROP INDEX IF EXISTS idx_user_roles_active_unique;

-- Postgres treats NULL as distinct in unique indexes, so two rows where
-- jurisdiction_geoid IS NULL will NOT conflict on this index. That is the
-- desired behavior: one system-wide grant AND one geo-scoped grant are both valid.
CREATE UNIQUE INDEX idx_user_roles_active_scoped
  ON public.user_roles(user_id, role_id, feature_scope, jurisdiction_geoid, resource_id)
  WHERE revoked_at IS NULL;

COMMIT;
```

**Why nullable columns work correctly in the unique index:** Postgres treats NULL
as distinct from every other value (including other NULLs) in unique index
comparisons. This means `(user_id=X, role_id=Y, feature_scope=NULL, geoid=NULL, resource_id=NULL)`
and `(user_id=X, role_id=Y, feature_scope=NULL, geoid='CA-06', resource_id=NULL)`
are considered distinct rows — both can exist simultaneously. This is exactly right:
a system-wide grant and a district-specific grant for the same role can coexist.

### 1b. `grant_role` SQL function — closes pre-existing gap, adds scope params

```sql
CREATE OR REPLACE FUNCTION public.grant_role(
  p_user_id              UUID,
  p_role_slug            TEXT,
  p_feature_scope        TEXT    DEFAULT NULL,
  p_jurisdiction_geoid   TEXT    DEFAULT NULL,
  p_resource_id          UUID    DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_role_id       UUID;
  v_is_active     BOOLEAN;
  v_required_tier TEXT;
BEGIN
  -- Resolve role by slug
  SELECT id, is_active, required_tier
    INTO v_role_id, v_is_active, v_required_tier
    FROM public.roles
   WHERE slug = p_role_slug;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ROLE_NOT_FOUND';
  END IF;

  IF NOT v_is_active THEN
    RAISE EXCEPTION 'ROLE_INACTIVE';
  END IF;

  -- Tier eligibility check
  IF v_required_tier = 'empowered' THEN
    IF NOT EXISTS (
      SELECT 1 FROM empower.empowered_profiles
       WHERE user_id = p_user_id AND is_active = true
    ) THEN
      RAISE EXCEPTION 'TIER_INELIGIBLE';
    END IF;
  ELSIF v_required_tier = 'connected' THEN
    IF NOT EXISTS (
      SELECT 1 FROM connect.connected_profiles
       WHERE user_id = p_user_id
    ) THEN
      RAISE EXCEPTION 'TIER_INELIGIBLE';
    END IF;
  END IF;

  -- Duplicate active grant check (scope-aware, using IS NOT DISTINCT FROM for nullables)
  IF EXISTS (
    SELECT 1 FROM public.user_roles
     WHERE user_id    = p_user_id
       AND role_id    = v_role_id
       AND revoked_at IS NULL
       AND (feature_scope      IS NOT DISTINCT FROM p_feature_scope)
       AND (jurisdiction_geoid IS NOT DISTINCT FROM p_jurisdiction_geoid)
       AND (resource_id        IS NOT DISTINCT FROM p_resource_id)
  ) THEN
    RAISE EXCEPTION 'ROLE_ALREADY_GRANTED';
  END IF;

  INSERT INTO public.user_roles (
    user_id, role_id, feature_scope, jurisdiction_geoid, resource_id
  ) VALUES (
    p_user_id, v_role_id, p_feature_scope, p_jurisdiction_geoid, p_resource_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.grant_role(UUID, TEXT, TEXT, TEXT, UUID)
  TO service_role;
```

### 1c. `revoke_role` SQL function — closes pre-existing gap, adds scope params

```sql
CREATE OR REPLACE FUNCTION public.revoke_role(
  p_user_id              UUID,
  p_role_slug            TEXT,
  p_feature_scope        TEXT    DEFAULT NULL,
  p_jurisdiction_geoid   TEXT    DEFAULT NULL,
  p_resource_id          UUID    DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_role_id UUID;
BEGIN
  SELECT id INTO v_role_id FROM public.roles WHERE slug = p_role_slug;

  -- Idempotent: no error if no matching active grant exists
  UPDATE public.user_roles
     SET revoked_at = now()
   WHERE user_id    = p_user_id
     AND role_id    = v_role_id
     AND revoked_at IS NULL
     AND (feature_scope      IS NOT DISTINCT FROM p_feature_scope)
     AND (jurisdiction_geoid IS NOT DISTINCT FROM p_jurisdiction_geoid)
     AND (resource_id        IS NOT DISTINCT FROM p_resource_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.revoke_role(UUID, TEXT, TEXT, TEXT, UUID)
  TO service_role;
```

### 1d. `get_user_roles` SQL function — closes pre-existing gap, returns scope fields

```sql
CREATE OR REPLACE FUNCTION public.get_user_roles(p_user_id UUID)
RETURNS TABLE (
  role_id              UUID,
  slug                 TEXT,
  name                 TEXT,
  granted_at           TIMESTAMPTZ,
  feature_scope        TEXT,
  jurisdiction_geoid   TEXT,
  resource_id          UUID
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT r.id, r.slug, r.name, ur.granted_at,
         ur.feature_scope, ur.jurisdiction_geoid, ur.resource_id
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
   WHERE ur.user_id    = p_user_id
     AND ur.revoked_at IS NULL
   ORDER BY ur.granted_at;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_roles(UUID)
  TO service_role, authenticated;
```

### 1e. `public.role_audit_log` table

```sql
CREATE TABLE public.role_audit_log (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Who performed the action. NULL for system-initiated future automated grants.
  actor_id             UUID        REFERENCES public.users(id) ON DELETE SET NULL,
  -- Affected user
  target_user_id       UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  -- The role involved (preserved even if role is later deactivated)
  role_id              UUID        NOT NULL REFERENCES public.roles(id),
  -- 'granted' or 'revoked' only — no check logging in v1.9 (too noisy)
  action               TEXT        NOT NULL
    CHECK (action IN ('granted', 'revoked')),
  -- Scope at time of action (matches scope columns on user_roles)
  feature_scope        TEXT,
  jurisdiction_geoid   TEXT,
  resource_id          UUID,
  -- Free-form context: endpoint, reason, UI form fields, etc.
  details              JSONB       NOT NULL DEFAULT '{}',
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1. Per-user audit view (admin account detail page)
CREATE INDEX idx_role_audit_log_target_user
  ON public.role_audit_log(target_user_id, created_at DESC);

-- 2. Global audit dashboard by action type + date
CREATE INDEX idx_role_audit_log_action_created
  ON public.role_audit_log(action, created_at DESC);

-- 3. Role usage report (which role was granted/revoked most)
CREATE INDEX idx_role_audit_log_role_id
  ON public.role_audit_log(role_id, created_at DESC);

-- 4. Actor report (what did admin X do)
CREATE INDEX idx_role_audit_log_actor_id
  ON public.role_audit_log(actor_id, created_at DESC);

ALTER TABLE public.role_audit_log ENABLE ROW LEVEL SECURITY;
-- No user-facing policies. Admin reads via service_role only.

GRANT SELECT, INSERT ON public.role_audit_log TO service_role;
```

**Scope of logging in v1.9:** Log `granted` and `revoked` only. Do NOT log
`check_passed`/`check_failed` — that would create a write on every authenticated
route call and make the table unmanageable. If per-check auditing is needed later,
add it as a sampling or threshold-triggered mechanism.

---

## 2. `requireRole()` Middleware

### File location and supabaseAdmin policy

`src/middleware/requireRole.ts` — in `src/middleware/`, which is excluded from the
architecture enforcement test that bans `supabaseAdmin` in `src/routes/`. However,
this middleware uses `pool.query()` directly, which is the correct choice because:

1. The EXISTS check requires `IS NOT DISTINCT FROM` for nullable scope columns. The
   PostgREST query API does not support this operator — only `eq()`, `is()`, etc.
2. `pool.query()` keeps this consistent with all other non-public schema reads in
   the codebase.
3. `public.user_roles` is in the public schema, but the cross-schema JOIN to `public.roles`
   combined with the nullable comparison logic makes raw SQL the cleaner approach.

### TypeScript signature

```typescript
// src/middleware/requireRole.ts

import { Request, Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { pool } from '../lib/db.js';

/**
 * requireRole — verify the authenticated user holds an active role grant
 * matching the given feature scope, jurisdiction, and resource.
 *
 * Scope matching logic:
 *   - A grant with NULL feature_scope matches ANY feature scope check (unrestricted).
 *   - A grant with NULL jurisdiction_geoid matches ANY geoid check (unrestricted).
 *   - A grant with NULL resource_id matches ANY resource_id check (unrestricted).
 *   - A grant with a specific value matches only that exact value.
 *
 * This means: granting a user the 'volunteer' role with NULL geoid gives them
 * volunteer access everywhere. Granting with geoid='CA-06' gives access only in
 * that district. A NULL-scoped grant is a superset of any specific-scoped grant.
 *
 * Must be used AFTER requireAuth (which attaches req.userId).
 *
 * Usage examples:
 *   router.post('/stances', requireAuth, requireRole('compass'), handler)
 *   router.post('/spaces/:spaceId/post',
 *     requireAuth,
 *     requireRole('civic_spaces', null, (req) => req.params.spaceId),
 *     handler
 *   )
 */
export function requireRole(
  featureScope: string | null,
  jurisdictionGeoid?: string | null,
  resourceIdOrFn?: string | null | ((req: Request) => string | null)
): (req: Request, res: Response, next: NextFunction) => Promise<void>
```

### Implementation body

```typescript
export function requireRole(
  featureScope: string | null,
  jurisdictionGeoid?: string | null,
  resourceIdOrFn?: string | null | ((req: Request) => string | null)
) {
  return async function (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    const authReq = req as AuthenticatedRequest;

    const resolvedResourceId =
      typeof resourceIdOrFn === 'function'
        ? resourceIdOrFn(req)
        : (resourceIdOrFn ?? null);

    const resolvedGeoid   = jurisdictionGeoid ?? null;
    const resolvedFeature = featureScope;

    // The EXISTS query uses:
    //   ur.feature_scope IS NULL       → NULL grant = unrestricted (matches any check)
    //   OR ur.feature_scope IS NOT DISTINCT FROM $2  → exact match for non-NULL check
    //
    // Same pattern for jurisdiction_geoid and resource_id.
    //
    // NEVER use bare equality (ur.jurisdiction_geoid = $3) because:
    //   - If $3 is NULL, the condition is never true (NULL = NULL is NULL, not TRUE)
    //   - IS NOT DISTINCT FROM handles NULL correctly: NULL IS NOT DISTINCT FROM NULL = TRUE
    const { rows } = await pool.query<{ exists: boolean }>(
      `SELECT EXISTS (
         SELECT 1
           FROM public.user_roles ur
          WHERE ur.user_id    = $1
            AND ur.revoked_at IS NULL
            AND (ur.feature_scope      IS NULL OR ur.feature_scope      IS NOT DISTINCT FROM $2)
            AND (ur.jurisdiction_geoid IS NULL OR ur.jurisdiction_geoid IS NOT DISTINCT FROM $3)
            AND (ur.resource_id        IS NULL OR ur.resource_id        IS NOT DISTINCT FROM $4)
       ) AS exists`,
      [authReq.userId, resolvedFeature, resolvedGeoid, resolvedResourceId]
    );

    if (!rows[0]?.exists) {
      res.status(403).json({ error: 'Role required', code: 'ROLE_REQUIRED' });
      return;
    }

    next();
  };
}
```

### Critical correctness: the NULL-scope IS NULL OR IS NOT DISTINCT FROM pattern

This pattern appears in two places and must be written identically in both:
1. The `requireRole` middleware EXISTS query (above)
2. The `grant_role` SQL function duplicate-check (Section 1b)

The two places have opposite semantics that must not be confused:

| Location | What NULL means | Query pattern |
|---|---|---|
| `grant_role` duplicate check | Are these two proposed scope tuples identical? | `IS NOT DISTINCT FROM` only (exact match both sides) |
| `requireRole` EXISTS check | Does this grant cover this request? | `IS NULL OR IS NOT DISTINCT FROM` (NULL = unrestricted) |

The grant function prevents duplicate rows with the same scope. The middleware
checks whether any existing grant covers the current request, with NULL meaning
"covers everything."

---

## 3. Updated `roleService.ts` Signatures

The existing `grantRole` and `revokeRole` call `adminRpc('grant_role', ...)` with
only two params. For v1.9, these are updated to pass scope params. Existing callers
in `adminService.ts` pass no options and continue to get NULL scopes (system-wide):

```typescript
// Updated grantRole
export async function grantRole(
  userId: string,
  roleSlug: string,
  options?: {
    featureScope?: string | null;
    jurisdictionGeoid?: string | null;
    resourceId?: string | null;
  }
): Promise<void>

// Updated revokeRole
export async function revokeRole(
  userId: string,
  roleSlug: string,
  options?: {
    featureScope?: string | null;
    jurisdictionGeoid?: string | null;
    resourceId?: string | null;
  }
): Promise<void>

// Updated getUserRoles return type (adds scope fields)
export async function getUserRoles(userId: string): Promise<Array<{
  role_id: string;
  slug: string;
  name: string;
  granted_at: string;
  feature_scope: string | null;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
}>>
```

Also add a `checkRole` utility (used by both middleware and the new /api/roles/check
endpoint) to avoid duplicating the EXISTS query:

```typescript
export async function checkRole(
  userId: string,
  featureScope: string | null,
  jurisdictionGeoid: string | null,
  resourceId: string | null
): Promise<boolean>
```

`requireRole` middleware should call `checkRole` rather than inlining the SQL,
so the query lives in one place.

---

## 4. Role Audit Log Service Layer

Do NOT write audit log entries inline in route handlers. Create a dedicated
`src/lib/roleAuditService.ts`:

```typescript
// src/lib/roleAuditService.ts

import { pool } from './db.js';

export interface RoleAuditEntry {
  actorId: string | null;           // null for future automated/system grants
  targetUserId: string;
  roleId: string;                   // UUID of the role row
  action: 'granted' | 'revoked';
  featureScope?: string | null;
  jurisdictionGeoid?: string | null;
  resourceId?: string | null;
  details?: Record<string, unknown>;
}

export async function logRoleAction(entry: RoleAuditEntry): Promise<void> {
  await pool.query(
    `INSERT INTO public.role_audit_log
       (actor_id, target_user_id, role_id, action,
        feature_scope, jurisdiction_geoid, resource_id, details)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
    [
      entry.actorId,
      entry.targetUserId,
      entry.roleId,
      entry.action,
      entry.featureScope   ?? null,
      entry.jurisdictionGeoid ?? null,
      entry.resourceId     ?? null,
      JSON.stringify(entry.details ?? {}),
    ]
  );
}
```

**Call site:** `logRoleAction` is called inside `roleService.grantRole()` and
`roleService.revokeRole()` — not in the admin route handlers. This ensures the audit
fires regardless of call origin (admin UI, API partner, future self-service). The
admin route handler still calls `logAdminAction()` (for the admin audit log). Both
logs fire on admin-initiated grants.

**Double logging is intentional:**
- `admin_audit_log`: tracks everything admin X did (who → action → target user)
- `role_audit_log`: tracks every role system event (which role, which scope, which user)

These serve different query patterns. The admin log answers "show me admin X's
actions." The role log answers "show me all grants for the volunteer role in district Y."

---

## 5. New Write Endpoints (5 role-type-specific routes)

Mounted in new route files under `src/routes/`. No `supabaseAdmin` in route handlers.
All non-public schema writes go through `pool.query()` in service layer functions.

```
POST /api/compass/contributor/stances
  requireAuth + requireRole('compass')
  → compassService.createContributorStance(userId, body)

POST /api/ctc/contributor/questions
  requireAuth + requireRole('ctc')
  → ctcService.createContributorQuestion(userId, body)

POST /api/essentials/contributor/facts
  requireAuth + requireRole('essentials')
  → essentialsService.createContributorFact(userId, body)

POST /api/civic-spaces/spaces/:spaceId/volunteer/posts
  requireAuth + requireRole('civic_spaces', null, (req) => req.params.spaceId)
  → civicSpacesService.createVolunteerPost(userId, spaceId, body)

POST /api/vq/contributor/stances
  requireAuth + requireRole('vq')
  → vqService.createContributorStance(userId, body)
```

The `civic_spaces` endpoint is the only one requiring a resource-scoped check — the
`spaceId` from the URL param is passed as the resource_id lambda.

---

## 6. Admin UI Additions

### Role assignment form (updated grant/revoke)

The existing `/api/admin/roles/grant` and `/api/admin/roles/revoke` endpoints take
`user_id` in the request body. For the per-user account detail page, new endpoints
derive `user_id` from the URL:

```
POST /api/admin/accounts/:userId/roles/grant
  body: { role_slug, feature_scope?, jurisdiction_geoid?, resource_id? }

POST /api/admin/accounts/:userId/roles/revoke
  body: { role_slug, feature_scope?, jurisdiction_geoid?, resource_id? }
```

The existing bulk endpoints (`/api/admin/roles/grant`, `/api/admin/roles/revoke`)
are retained for backward compatibility.

### Per-user role audit view

New endpoint consumed by the account detail page:
```
GET /api/admin/accounts/:userId/role-audit?page=1
```

Returns paginated `role_audit_log` rows for that user, newest first.

### Global audit dashboard

New admin route at `/admin/role-audit`. New API endpoint:
```
GET /api/admin/role-audit?action=granted&role_slug=volunteer&page=1
```

Both audit endpoints read `public.role_audit_log` via `pool.query()` in
`roleAuditService.ts`.

---

## 7. Contributor Portal (New Vite + React App)

### Directory structure (mirrors `/app` conventions)

```
contributor/
  index.html
  vite.config.ts
  tsconfig.json
  tsconfig.app.json
  public/
  src/
    main.tsx
    App.tsx                   — Routes + auth init (mirrors app/src/App.tsx)
    index.css                 — Tailwind v4 @theme with ev-* tokens (copy from app/)
    store/
      authStore.ts            — Identical to app/src/store/authStore.ts
                                (same ev_token localStorage key, same User type)
    lib/
      api.ts                  — Identical to app/src/lib/api.ts
                                (same VITE_API_URL pattern, same apiFetch)
    components/
      AuthGuard.tsx           — Same pattern as app/src/components/AuthGuard.tsx
      RoleGuard.tsx           — New: checks /api/roles/me; redirects to /no-role
    pages/
      LoginRedirectPage.tsx   — Redirects to accounts.empowered.vote/login?redirect=...
      DashboardPage.tsx       — Reads /api/roles/me, routes to role-type view
      views/
        ContributorView.tsx   — Shown when user has contributor role
        CandidateView.tsx     — Shown when user has candidate role
        MavenView.tsx         — Shown when user has maven role
        VolunteerView.tsx     — Shown when user has volunteer role (civic_spaces scoped)
      NoRolePage.tsx          — Shown when authenticated but no role assigned yet
```

### Auth flow (identical to `/app`)

1. `App.tsx` checks for `#access_token` in hash fragment (SSO redirect from accounts)
2. Falls back to `localStorage.getItem('ev_token')`
3. Falls back to silent SSO via `GET /api/auth/session` with `credentials: 'include'`
4. On success, calls `GET /api/roles/me` to get the user's active role grants
5. `DashboardPage.tsx` routes to the appropriate role-type view

**The `ev_token` localStorage key is shared with `/app`.** A user already signed in
to `app.empowered.vote` in the same browser will be auto-authenticated in the
contributor portal via the stored token, without a redirect to accounts.

### Role-type routing in `DashboardPage.tsx`

```typescript
// Priority: contributor > candidate > maven > volunteer
// A user with multiple roles sees the highest-priority view + a role switcher in nav.

const primaryView =
  roles.some(r => r.slug === 'contributor') ? 'contributor' :
  roles.some(r => r.slug === 'candidate')   ? 'candidate'   :
  roles.some(r => r.slug === 'maven')       ? 'maven'       :
  roles.some(r => r.slug === 'volunteer')   ? 'volunteer'   :
  'none';
```

### Guard chain

```
App.tsx init
  └── <AuthGuard>            — isAuthenticated? → /login if not
        └── <RoleGuard>      — roles.length > 0? → /no-role if empty
              └── <DashboardPage> — routes to role-specific view
```

`RoleGuard` calls `GET /api/roles/me` once on mount and stores results. It does not
block the render (shows a loading state while the fetch is in flight).

---

## 8. Civic Spaces Integration

### Current Civic Spaces auth pattern (verified from source)

Civic Spaces uses the accounts JWT but stores it as `cs_token` (not `ev_token`).
The Supabase client reads `cs_token` for third-party auth against the Civic Spaces
Supabase project. The `useAuth.ts` hook resolves auth via:
1. `#access_token` hash fragment
2. `localStorage('cs_token')`
3. Silent SSO at `https://accounts-api.empowered.vote/api/auth/session`

Civic Spaces has no existing mechanism to check role grants from ev-accounts. Role
enforcement is currently Supabase RLS only within the Civic Spaces project.

### v1.9 integration point: `/api/roles/check`

New endpoint that Civic Spaces backend calls before allowing privileged writes:

```
POST /api/roles/check
Auth: requireAuth (user JWT from Civic Spaces passes Bearer token)
Body: {
  role_slug: string,
  feature_scope?: string | null,
  jurisdiction_geoid?: string | null,
  resource_id?: string | null
}
Response: { has_role: boolean }
```

Implementation calls `roleService.checkRole()` — the same utility used by
`requireRole` middleware. One query, two consumers.

**Why Option A (API call) over Option B (JWT claim):**
- JWT claims are stale until token expiry (~1h). An admin revokes a role for safety
  reasons; the user's existing token still carries the claim for up to 1 hour.
- API call is real-time. Adds one network round-trip per privileged write, which is
  acceptable — privileged writes are infrequent (posting content, not reading feeds).
- JWT claim embedding deferred to v2 for high-frequency read cases only.

### Civic Spaces call pattern

```typescript
// Civic Spaces backend before processing a volunteer post:
const response = await fetch('https://api.empowered.vote/api/roles/check', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${userJwt}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    role_slug: 'volunteer',
    feature_scope: 'civic_spaces',
    resource_id: spaceId,
  }),
});
const { has_role } = await response.json();
if (!has_role) return res.status(403).json({ error: 'Volunteer role required' });
```

---

## 9. Build Order and Dependency Graph

```
Phase A: Schema foundation (all in one migration, one transaction)
  - ALTER user_roles: add feature_scope, jurisdiction_geoid, resource_id columns
  - DROP old unique index, CREATE new scope-aware index
  - CREATE grant_role, revoke_role, get_user_roles SQL functions
  - CREATE role_audit_log table + 4 indexes
  ↓
Phase B: Service layer (parallel with C)
  - Update roleService.ts: add scope params to grantRole/revokeRole/getUserRoles
  - Add roleService.checkRole() utility (shared by middleware and /check endpoint)
  - Create roleAuditService.ts: logRoleAction()
  - Update roleService.grantRole/revokeRole to call logRoleAction

Phase C: Middleware (parallel with B)
  - Create src/middleware/requireRole.ts
  - Uses checkRole() from roleService.ts (dependency on Phase B checkRole)
  ↓ (B + C both complete)
Phase D: API endpoints
  - POST /api/roles/check endpoint
  - 5 new role-gated write endpoints with requireRole()
  - 2 admin role-audit read endpoints
  ↓
Phase E: Admin UI additions (parallel with F, both depend on D)
  - Role assignment form: scope fields on grant/revoke
  - Per-user role audit view
  - Global audit dashboard

Phase F: Contributor portal (parallel with E)
  - Scaffold /contributor Vite app
  - Copy/adapt auth store + apiFetch from /app
  - Auth flow + AuthGuard + RoleGuard
  - Role-type views (ContributorView, CandidateView, MavenView, VolunteerView)
  ↓ (E + F complete)
Phase G: Civic Spaces integration
  - Civic Spaces backend: call /api/roles/check for volunteer writes
  - Smoke test: grant volunteer role → Civic Spaces write succeeds;
    revoke role → write blocked
```

**Critical path:** A → B+C → D → E+F → G

**Parallelizable pairs:** (B, C) can be developed simultaneously once A is merged.
(E, F) can be developed simultaneously once D is merged.

**Blocking dependency to flag:** Phase C (`requireRole` middleware) depends on
`checkRole()` from Phase B. If Phase B and C are assigned to different developers,
they must agree on the `checkRole()` signature before Phase C begins — or Phase C
can inline the SQL temporarily and refactor to `checkRole()` when Phase B lands.

---

## 10. Constraint Compliance Checklist

| Constraint | How v1.9 Satisfies It |
|---|---|
| `pool.query()` for all non-public schema ops | `requireRole` uses pool.query; new write endpoints delegate to service functions that use pool.query |
| `SECURITY DEFINER` + `SET search_path = ''` | All 3 new SQL functions (grant_role, revoke_role, get_user_roles) include both |
| `supabaseAdmin` banned from `src/routes/` | requireRole lives in src/middleware/ (excluded from test); route handlers delegate to lib/ |
| NULL geo-scope must use IS NULL OR IS NOT DISTINCT FROM | Both middleware EXISTS query and grant_role duplicate check use this pattern |
| Partial unique index for active grants | New index includes scope columns; replaces old idx_user_roles_active_unique |
| Revocation is soft (revoked_at, not DELETE) | revoke_role RPC uses UPDATE SET revoked_at = now() |
| Audit log for every admin mutation | logAdminAction() in admin routes + logRoleAction() in roleService |
| Existing role grants unaffected | New columns are nullable; all existing rows get NULL scopes = system-wide grants; no behavior change |
| No nested SECURITY DEFINER calls | grant_role/revoke_role do not call other SECURITY DEFINER functions |

---

## Sources

All findings from direct source inspection. No training-data assumptions.

- `C:/EV-Accounts/backend/src/middleware/requireAdmin.ts` — middleware pattern (supabaseAdmin in middleware is permitted)
- `C:/EV-Accounts/backend/src/middleware/tierGuards.ts` — tier guard pattern
- `C:/EV-Accounts/backend/src/middleware/auth.ts` — AuthenticatedRequest type, tokenIat/tokenExp
- `C:/EV-Accounts/backend/src/lib/roleService.ts` — current grantRole/revokeRole/getUserRoles (calls adminRpc but SQL functions not yet created)
- `C:/EV-Accounts/backend/src/lib/supabase.ts` — adminRpc wrapper, pool import, client types
- `C:/EV-Accounts/backend/src/lib/db.ts` — Pool configuration
- `C:/EV-Accounts/backend/src/routes/admin.ts` — admin route patterns, logAdminAction usage
- `C:/EV-Accounts/backend/src/routes/roles.ts` — existing /api/roles/me endpoint
- `C:/EV-Accounts/supabase/migrations/20260227000020_phase6_roles_schema.sql` — current user_roles DDL (no scope columns yet)
- `C:/EV-Accounts/supabase/migrations/20260227000023_phase6_rpcs.sql` — SECURITY DEFINER + SET search_path = '' pattern
- `C:/EV-Accounts/supabase/migrations/20260224000003_public_types_and_tables.sql` — original user_roles + admin_audit_log
- `C:/EV-Accounts/supabase/migrations/20260227000024_phase7_admin_schema.sql` — audit log column + index patterns
- `C:/Civic Spaces/src/lib/supabase.ts` — cs_token localStorage key, third-party auth pattern
- `C:/Civic Spaces/src/hooks/useAuth.ts` — Civic Spaces SSO flow (accounts-api.empowered.vote session endpoint)
- `C:/EV-Accounts/app/src/App.tsx` — app auth init, hash fragment pattern, SSO fallback
- `C:/EV-Accounts/app/src/store/authStore.ts` — ev_token localStorage key, User type
- `C:/EV-Accounts/app/src/lib/api.ts` — apiFetch pattern (VITE_API_URL, credentials: include)
- `C:/EV-Accounts/app/src/pages/DashboardPage.tsx` — component structure pattern
