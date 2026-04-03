# Phase 53: Service Layer + requireRole Middleware - Research

**Researched:** 2026-04-03
**Domain:** Express middleware, Redis caching, TypeScript generics, CORS per-route
**Confidence:** HIGH

## Summary

Phase 53 builds the role enforcement layer on top of the Phase 52 schema. The work breaks into four areas: (1) upgrading `roleService.ts` to add Redis-cached `getUserRoles` with `cache.del` on grant/revoke, (2) creating `requireRole()` as a higher-order Express middleware factory in `src/middleware/requireRole.ts`, (3) creating `checkRole()` as the NULL-safe matching utility that `requireRole()` delegates to, and (4) adding two endpoints — `GET /api/contributor/me` and `POST /api/roles/check`.

The standard patterns are already established in this codebase. `cache.ts` provides a `CacheClient` interface with `get/set/del` and an in-memory fallback — the same pattern used by `authService.ts` for logout revocation. Middleware follows the `requireAdmin` / `requireStagingReviewer` factory pattern. CORS for `POST /api/roles/check` uses the same global `cors` middleware already wired in `index.ts`, but the allowed origins list must include cross-app origins — handled by extending `CORS_ORIGIN` env var, not by adding per-route middleware.

The architecture enforcement test requires that `requireRole.ts` NOT use `supabaseAdmin` directly. Role lookups go through `roleService.getUserRoles()` (which calls `adminRpc`), not raw DB access. If `requireRole.ts` needs DB access it must use `pool.query()` or delegate to the service — matching the `requireStagingReviewer` precedent. Since `requireRole()` uses the cached `getUserRoles` path (not a raw query), no `supabaseAdmin` reference is needed in the middleware file.

**Primary recommendation:** Put `checkRole()` as a module-level export from `src/lib/roleService.ts` alongside `getUserRoles()`. Keep `requireRole()` factory in `src/middleware/requireRole.ts`. The middleware calls `roleService.getUserRoles()` (cached), then `checkRole()` for matching logic. This keeps the matching logic unit-testable in isolation without spinning up Express.

## Standard Stack

No new libraries. All tools are already in the project.

### Core (already in place)
| Tool | Version | Purpose | Why Used |
|------|---------|---------|----------|
| Express 4.x | ^4.21.0 | HTTP server + middleware chain | Project standard |
| `@upstash/redis` | ^1.34.0 | Role grant cache via `cache.ts` | HTTP-compatible Redis, Upstash |
| `vitest` | ^2.1.0 | Unit and integration tests | Project test runner |
| `supertest` | ^7.0.0 | HTTP-level integration tests | Project standard |
| TypeScript strict | ^5.6.0 | Middleware factory generics | Project standard |

### Supporting
| Tool | Purpose |
|------|---------|
| `cors` npm package | Already in use — global CORS in `index.ts` |
| `cache.ts` (project lib) | Existing `CacheClient` with Redis + in-memory fallback |
| `pool` (pg Pool from `db.ts`) | Available if raw DB needed, but not needed for this phase |

**No new npm installs required.**

## Architecture Patterns

### Recommended File Structure
```
backend/src/
├── middleware/
│   └── requireRole.ts          # requireRole() factory — NEW
├── lib/
│   └── roleService.ts          # add getCachedUserRoles() + checkRole() exports — MODIFIED
├── routes/
│   ├── contributor.ts          # GET /api/contributor/me — NEW
│   └── roles.ts                # POST /api/roles/check added here — MODIFIED
tests/
└── integration/
    └── requireRole.test.ts     # checkRole unit tests + integration — NEW
```

### Pattern 1: Higher-Order Middleware Factory

The established project pattern for parameterized middleware. `requireAdmin` is a simple guard function; `requireStagingReviewer` shows DB-backed guards. `requireRole` is a factory that returns a middleware function.

```typescript
// src/middleware/requireRole.ts
// Pattern: higher-order function returning Express RequestHandler

import { Request, Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { getCachedUserRoles, checkRole } from '../lib/roleService.js';

type ScopeResolver = (req: Request) => string | undefined;

interface RequireRoleOptions {
  geoid?: string | ScopeResolver;
  resourceId?: string | ScopeResolver;
}

export function requireRole(
  roleSlugs: string | string[],
  opts?: RequireRoleOptions
): (req: Request, res: Response, next: NextFunction) => Promise<void> {
  const slugArray = Array.from([roleSlugs].flat());

  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    // Handle unauthenticated — requireRole does not require stacking requireAuth
    if (!authReq.userId) {
      res.status(401).json({ error: 'unauthorized' });
      return;
    }

    const geoid = typeof opts?.geoid === 'function'
      ? opts.geoid(req)
      : opts?.geoid;

    const resourceId = typeof opts?.resourceId === 'function'
      ? opts.resourceId(req)
      : opts?.resourceId;

    try {
      const grants = await getCachedUserRoles(authReq.userId);
      const permitted = slugArray.some((slug) =>
        checkRole(grants, slug, { geoid, resourceId })
      );

      if (!permitted) {
        res.status(403).json({ error: 'forbidden' });
        return;
      }

      next();
    } catch (err) {
      console.error('[requireRole] error:', err);
      res.status(500).json({ error: 'internal_error' });
    }
  };
}
```

**Architecture constraint:** `requireRole.ts` must NOT be added to the `supabaseAdmin` allowlist in `architecture.test.ts`. The middleware uses `roleService.getCachedUserRoles()` which internally calls `adminRpc` — the middleware file itself never touches `supabaseAdmin`.

### Pattern 2: Cached Service Method

`cache.ts` already exports a `CacheClient` with `get/set/del`. The project pattern for cache usage (from `authService.ts`) is: try/catch wrapping, fail-open on error, swallow cache errors silently.

```typescript
// Addition to src/lib/roleService.ts

import { cache } from './cache.js';

const ROLE_CACHE_TTL = 90; // seconds — within the 60–120 range from CONTEXT.md

export async function getCachedUserRoles(userId: string): Promise<UserRoleGrant[]> {
  const key = `roles:uid:${userId}`;

  try {
    const cached = await cache.get<UserRoleGrant[]>(key);
    if (cached !== null) return cached;
  } catch (err) {
    console.error('[getCachedUserRoles] cache read failed — querying DB directly:', err);
  }

  // Cache miss or Redis unavailable — fall through to DB
  const grants = await getUserRoles(userId);

  try {
    await cache.set(key, grants, ROLE_CACHE_TTL);
  } catch (err) {
    console.error('[getCachedUserRoles] cache write failed — serving from DB:', err);
  }

  return grants;
}

export async function invalidateRoleCache(userId: string): Promise<void> {
  try {
    await cache.del(`roles:uid:${userId}`);
  } catch (err) {
    console.error('[invalidateRoleCache] cache del failed:', err);
  }
}
```

`grantRole()` and `revokeRole()` in `roleService.ts` must call `invalidateRoleCache(userId)` after each successful RPC call.

### Pattern 3: checkRole() NULL-Safe Matching Logic

This is the most critical correctness surface. The NULL-scope semantics from CONTEXT.md must be implemented precisely.

```typescript
// Addition to src/lib/roleService.ts

export interface UserRoleGrant {
  role_id: string;
  slug: string;
  name: string;
  granted_at: string;
  feature_scope: string;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
}

interface CheckRoleScope {
  geoid?: string;
  resourceId?: string;
}

/**
 * checkRole — NULL-safe role grant matching.
 *
 * NULL-scope semantics (from Phase 53 CONTEXT.md):
 * - NULL jurisdiction_geoid on a grant = unrestricted on geoid dimension
 *   → passes ANY geoid check, including when geoid is specified
 * - NULL resource_id on a grant = unrestricted on resourceId dimension
 *   → passes ANY resourceId check, including when resourceId is specified
 * - Route calls requireRole() with no geoid/resourceId: any active grant passes
 * - Multiple grants for same slug: ANY single matching grant is sufficient (OR)
 */
export function checkRole(
  grants: UserRoleGrant[],
  roleSlug: string,
  scope?: CheckRoleScope
): boolean {
  return grants.some((grant) => {
    if (grant.slug !== roleSlug) return false;

    // Geoid check: NULL on grant = unrestricted (pass any). Non-null = must match.
    if (scope?.geoid !== undefined) {
      if (grant.jurisdiction_geoid !== null && grant.jurisdiction_geoid !== scope.geoid) {
        return false;
      }
    }

    // ResourceId check: NULL on grant = unrestricted (pass any). Non-null = must match.
    if (scope?.resourceId !== undefined) {
      if (grant.resource_id !== null && grant.resource_id !== scope.resourceId) {
        return false;
      }
    }

    return true;
  });
}
```

**Critical:** `checkRole()` operates on already-filtered active grants (the `get_user_roles` RPC returns only non-revoked rows). There is no `revoked_at` check here — the DB/RPC layer handles that.

### Pattern 4: Contributor Route

New router file matching the existing router pattern (see `routes/roles.ts` for comparison):

```typescript
// src/routes/contributor.ts
// GET /api/contributor/me — returns caller's active role grants

import { Router } from 'express';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { getCachedUserRoles } from '../lib/roleService.js';
import type { Request, Response } from 'express';

const router = Router();

router.get(
  '/me',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;
    try {
      const grants = await getCachedUserRoles(authReq.userId);
      // Return only the fields specified in CONTEXT.md response contract
      const roles = grants.map(({ slug, feature_scope, jurisdiction_geoid, resource_id }) => ({
        role_slug: slug,
        feature_scope,
        jurisdiction_geoid,
        resource_id,
      }));
      res.status(200).json({ roles });
    } catch (err) {
      console.error('[GET /contributor/me] error:', err);
      res.status(500).json({ error: 'internal_error' });
    }
  }
);

export default router;
```

Mount in `index.ts`: `app.use('/api/contributor', contributorRouter);`

### Pattern 5: POST /api/roles/check with CORS

The CONTEXT.md decision is `{ permitted: true }` or `{ permitted: false }`. The global CORS in `index.ts` already handles `*.empowered.vote` — no per-route CORS middleware needed if the cross-app origin is added to `CORS_ORIGIN` env var.

However, `POST /api/roles/check` is called by external apps (CTC, Civic Spaces) that pass their own service credentials. The endpoint must authenticate the caller. Looking at the CONTEXT.md: the endpoint requires the user's JWT (to identify whose roles to check). This is a user-facing check endpoint, not a server-to-server endpoint.

```typescript
// Addition to src/routes/roles.ts

router.post(
  '/check',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;
    const body = req.body as {
      feature_scope?: string;
      jurisdiction_geoid?: string;
      resource_id?: string;
    };

    if (!body.feature_scope) {
      res.status(422).json({ error: 'feature_scope required' });
      return;
    }

    try {
      const grants = await getCachedUserRoles(authReq.userId);
      const permitted = checkRole(grants, body.feature_scope, {
        geoid: body.jurisdiction_geoid,
        resourceId: body.resource_id,
      });
      res.status(200).json({ permitted });
    } catch (err) {
      console.error('[POST /roles/check] error:', err);
      res.status(500).json({ error: 'internal_error' });
    }
  }
);
```

### Pattern 6: Architecture Test Update

The architecture test at `tests/integration/architecture.test.ts` has an allowlist for files that may use `supabaseAdmin`. `requireRole.ts` does NOT use `supabaseAdmin` (it goes through `roleService`), so no update is needed to the allowlist. Verify this is true after implementation.

### Anti-Patterns to Avoid

- **Do not use `supabaseAdmin` in `requireRole.ts`** — architecture test will fail. Use `roleService.getCachedUserRoles()` instead.
- **Do not use `=== undefined` to check scope in `checkRole()`** — use `!== undefined` correctly. A scope of `undefined` means "no requirement" (any grant passes). A scope of `''` (empty string) means "explicitly require empty string" — which would be wrong for geoIDs. Treat absent scope params as `undefined`, not as `''`.
- **Do not call `getUserRoles()` directly in `requireRole.ts`** — always use `getCachedUserRoles()` so the cache layer is in the hot path.
- **Do not share the `roles:uid:` cache key between `getCachedUserRoles` and the existing `getUserRoles` call sites** — the cached version returns the same type and replaces the uncached version at all call sites.
- **Do not invalidate cache on failed grant/revoke** — only call `invalidateRoleCache()` after the RPC succeeds (no error returned).
- **Do not add `requireRole` to `index.ts` global middleware** — it's always route-specific.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Redis caching | Custom TTL/invalidation logic | `cache.ts` CacheClient | Already handles Redis + in-memory fallback, error swallowing |
| NULL-safe matching | `==` comparisons | Explicit `=== null` checks in `checkRole()` | TypeScript strict mode + correctness |
| CORS for cross-app endpoint | Per-route `cors()` middleware | Extend `CORS_ORIGIN` env var | Global CORS already wired; per-route middleware creates inconsistency |
| Auth in `requireRole` | Custom JWT parsing | Read `req.userId` set by `requireAuth` | `requireRole` handles unauthenticated (no `req.userId`) by returning 401 directly |

**Key insight:** The cache layer (`cache.ts`) already has the Redis-unavailable fallback built in. `requireRole.ts` doesn't need any Redis awareness — it calls `getCachedUserRoles()` and gets grants back whether Redis is up or not.

## Common Pitfalls

### Pitfall 1: `checkRole()` — Treating Absent Scope as Restrictive

**What goes wrong:** Route calls `requireRole('volunteer', { geoid: '06037' })`. A grant with `jurisdiction_geoid = NULL` (unrestricted) should pass. If the check is `grant.jurisdiction_geoid === scope.geoid`, a NULL grant never matches `'06037'`, rejecting legitimate unrestricted grants.

**Why it happens:** NULL on a grant means unrestricted, but `null === '06037'` is false.

**How to avoid:** The correct check is: if the grant has `jurisdiction_geoid = NULL`, skip the geoid restriction entirely (pass). Only apply the restriction when the grant has a non-null `jurisdiction_geoid`. The implementation in the Pattern 3 code example above is correct.

**Warning signs:** SC3 integration test (`volunteer` grant with NULL jurisdiction + check with specific geoid) returns `{ permitted: false }` — this means the NULL check is wrong.

### Pitfall 2: Cache Invalidation — Wrong Timing

**What goes wrong:** `invalidateRoleCache()` is called before the `adminRpc` returns, or called even when the RPC throws. The next call to `getCachedUserRoles()` re-reads stale data from the DB (because the RPC didn't actually succeed).

**Why it happens:** Misplaced `await cache.del()` call in the `grantRole`/`revokeRole` flow.

**How to avoid:** Call `invalidateRoleCache()` after checking `if (error) throw ...` — only on the success path.

### Pitfall 3: `requireRole` Called Without Prior `requireAuth`

**What goes wrong:** `requireRole` checks `authReq.userId`. If `requireAuth` was not called first, `req.userId` is `undefined`. The middleware returns 401 (correct), but callers may be confused by the 401 coming from `requireRole` when they expected to need `requireAuth` separately.

**Why it happens:** `requireRole` is designed to handle this itself (per CONTEXT.md: "handles unauthenticated requests itself: returns 401 if `req.user` is missing"). This is the intended behavior — do not document it as a bug.

**How to avoid:** This is the correct design. No stacking of `requireAuth` + `requireRole` is required. But routes that also need tier data (e.g., need `userId` for other purposes) may still stack `requireAuth` first for the populated `AuthenticatedRequest` fields. Just don't assume `requireAuth` is always the parent.

### Pitfall 4: `POST /api/roles/check` — Conflating `feature_scope` with `role_slug`

**What goes wrong:** The endpoint body uses `feature_scope` as the field name. The CONTEXT.md success criteria (SC2) and the endpoint description both say `feature_scope`. But the `checkRole()` function takes a `roleSlug` as the second parameter. These are the same value — `feature_scope` in the request body IS the role slug. Do not create a separate lookup.

**Why it happens:** The Phase 53 context uses `feature_scope` as the "what permission do you want to check" field in the API. In the DB, this maps to `roles.slug`. The naming inconsistency is intentional (the public API uses `feature_scope`, the internal function uses `roleSlug`).

**How to avoid:** `checkRole(grants, body.feature_scope, { geoid: body.jurisdiction_geoid, resourceId: body.resource_id })` — pass `body.feature_scope` directly as the `roleSlug` argument.

### Pitfall 5: Architecture Test Failure — `requireRole.ts` added to allowlist

**What goes wrong:** Developer adds `requireRole.ts` to the `supabaseAdmin` allowlist in `architecture.test.ts` because it's in `src/middleware/`.

**Why it happens:** `requireAdmin.ts` and `requireStagingReviewer.ts` ARE in `src/middleware/` and DO use `supabaseAdmin` or `pool`. It's tempting to follow the same pattern.

**How to avoid:** `requireRole.ts` must use `getCachedUserRoles()` from `roleService.ts` — NOT `supabaseAdmin` directly. No allowlist addition needed. `requireStagingReviewer.ts` uses `pool.query()` directly (it's not in the allowlist either, since `pool` ≠ `supabaseAdmin`). Same approach applies here.

### Pitfall 6: TTL Value — Cache Key Conflict with Future Admin Invalidation

**What goes wrong:** A 5-minute TTL means an admin can grant/revoke a role but the change doesn't take effect for 5 minutes (cache still holds old grants).

**Why it happens:** TTL too long without immediate invalidation on grant/revoke.

**How to avoid:** Phase 53 implements immediate cache invalidation on grant/revoke (via `invalidateRoleCache`). TTL is the safety net for cases where invalidation fails or is missed. The 90-second TTL is conservative and correct. Do not set TTL to 300s or more.

## Code Examples

### checkRole() — Comprehensive Test Cases (for integration test)

The success criteria (SC5) requires tests for all NULL-scope and scope-match combinations:

```typescript
// tests/integration/requireRole.test.ts

import { describe, it, expect } from 'vitest';
import { checkRole } from '../../backend/src/lib/roleService.js';
import type { UserRoleGrant } from '../../backend/src/lib/roleService.js';

// Helper: build a minimal grant for testing
function grant(slug: string, geo: string | null = null, res: string | null = null): UserRoleGrant {
  return {
    role_id: 'test-id',
    slug,
    name: slug,
    granted_at: new Date().toISOString(),
    feature_scope: 'jurisdiction',
    jurisdiction_geoid: geo,
    resource_id: res,
  };
}

describe('checkRole — NULL-scope semantics', () => {
  it('no role at all → false', () => {
    expect(checkRole([], 'volunteer', { geoid: '18105' })).toBe(false);
  });

  it('NULL-scope grant + geoid check → true (NULL = unrestricted)', () => {
    expect(checkRole([grant('volunteer', null)], 'volunteer', { geoid: '18105' })).toBe(true);
  });

  it('exact geoid match → true', () => {
    expect(checkRole([grant('volunteer', '18105')], 'volunteer', { geoid: '18105' })).toBe(true);
  });

  it('wrong jurisdiction → false', () => {
    expect(checkRole([grant('volunteer', '06037')], 'volunteer', { geoid: '18105' })).toBe(false);
  });

  it('wrong resourceId → false', () => {
    expect(checkRole([grant('campaign_manager', null, 'pol-A')], 'campaign_manager', { resourceId: 'pol-B' })).toBe(false);
  });

  it('NULL resourceId grant + resourceId check → true', () => {
    expect(checkRole([grant('campaign_manager', null, null)], 'campaign_manager', { resourceId: 'pol-B' })).toBe(true);
  });

  it('scope-blind check (no scope requirement) → true for any active grant', () => {
    expect(checkRole([grant('volunteer', '06037')], 'volunteer')).toBe(true);
  });

  it('wrong role slug → false', () => {
    expect(checkRole([grant('volunteer', null)], 'campaign_manager')).toBe(false);
  });
});
```

### grantRole() — with cache invalidation

```typescript
// src/lib/roleService.ts — updated grantRole with invalidation

export async function grantRole(
  userId: string,
  roleSlug: string,
  options?: { featureScope?: string; jurisdictionGeoid?: string; resourceId?: string }
): Promise<void> {
  const { error } = await adminRpc('grant_role', {
    p_user_id: userId,
    p_role_slug: roleSlug,
    p_feature_scope: options?.featureScope ?? 'platform',
    p_jurisdiction_geoid: options?.jurisdictionGeoid ?? null,
    p_resource_id: options?.resourceId ?? null,
  });

  if (error) {
    // ... existing error mapping ...
    throw new Error(error.message);
  }

  // Invalidate role cache AFTER successful grant only
  await invalidateRoleCache(userId);
}
```

### GET /api/contributor/me — Expected Response Shape

```json
{
  "roles": [
    {
      "role_slug": "volunteer",
      "feature_scope": "jurisdiction",
      "jurisdiction_geoid": "18105",
      "resource_id": null
    }
  ]
}
```

### POST /api/roles/check — Request/Response

```
POST /api/roles/check
Authorization: Bearer <jwt>
Content-Type: application/json

{ "feature_scope": "volunteer", "jurisdiction_geoid": "18105" }

→ 200 { "permitted": true }
→ 200 { "permitted": false }
```

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|-----------------|-------|
| `getUserRoles()` uncached | `getCachedUserRoles()` with `cache.ts` | Phase 52 return type now includes scope fields; cache wraps the same RPC |
| `requireStagingReviewer` (role check via raw `pool.query`) | `requireRole()` (role check via cached service) | Factory pattern with NULL-safe scope logic; no direct DB access in middleware |
| No external role-check endpoint | `POST /api/roles/check` | CTC/Civic Spaces use this to gate volunteer-only content |

**What changed in Phase 52 that unblocks Phase 53:**
- `getUserRoles()` return type now includes `feature_scope`, `jurisdiction_geoid`, `resource_id`
- All active role grants carry scope fields — `checkRole()` can use them immediately
- Migration 047 is live in production — no schema changes needed in this phase

## Open Questions

1. **Does `grantRole()` need scope parameters exposed in the TypeScript API?**
   - What we know: The DB RPC accepts scope params. Phase 54 (admin role management) will call `grantRole()` with explicit scope.
   - What's unclear: Whether Phase 53 needs to update `grantRole()` and `revokeRole()` signatures to accept scope params, or whether Phase 54 does it.
   - Recommendation: Update `grantRole()` and `revokeRole()` signatures in Phase 53 since `invalidateRoleCache()` must be wired there anyway. Phase 54 then just passes the scope params. If Phase 54 is more appropriate, the planner can defer it — but the `invalidateRoleCache()` wiring MUST happen in Phase 53.

2. **Where does `UserRoleGrant` type live — `roleService.ts` or `roles.ts`?**
   - What we know: `roles.ts` has `FEATURE_SCOPES` / `FeatureScope`. `roleService.ts` has the service functions.
   - What's unclear: Whether the shared grant type belongs in `roles.ts` (with `FeatureScope`) or in `roleService.ts` (with `getUserRoles`).
   - Recommendation: Define `UserRoleGrant` in `roleService.ts` and export it. It's a DB-shape type, not a domain constant. `checkRole()` takes it as a parameter, so it's tightly coupled to the service file.

3. **Should `POST /api/roles/check` validate `feature_scope` against `FEATURE_SCOPES`?**
   - What we know: `FEATURE_SCOPES = ['platform', 'jurisdiction', 'resource']`. But the check endpoint takes an arbitrary slug string.
   - What's unclear: Whether `feature_scope` in the check endpoint means "feature scope type" or "role slug" (they are different things — `feature_scope` is the role slug in the API but maps to `roles.slug` in the DB, not to `user_roles.feature_scope`).
   - Recommendation: No validation against `FEATURE_SCOPES` enum. The `feature_scope` field in the request body is the **role slug** (e.g., `"volunteer"`), not a scope type like `"jurisdiction"`. The field name in the CONTEXT.md API spec is confusing but intentional. Validate only that `feature_scope` is a non-empty string.

## Sources

### Primary (HIGH confidence)
- Codebase read: `backend/src/lib/cache.ts` — `CacheClient` interface, Redis + in-memory fallback pattern
- Codebase read: `backend/src/lib/authService.ts` — established `cache.get/set` usage pattern with try/catch fail-open
- Codebase read: `backend/src/middleware/requireAdmin.ts` — Express middleware pattern
- Codebase read: `backend/src/middleware/requireStagingReviewer.ts` — role-checking middleware precedent using `pool.query()`
- Codebase read: `backend/src/middleware/auth.ts` — `AuthenticatedRequest` interface, `req.userId` access pattern
- Codebase read: `backend/src/middleware/tierGuards.ts` — tier guard middleware pattern (DB check → 403)
- Codebase read: `tests/integration/architecture.test.ts` — `supabaseAdmin` allowlist enforcement
- Codebase read: `backend/src/lib/roleService.ts` — current `getUserRoles` return type (Phase 52 updated)
- Codebase read: `backend/src/lib/roles.ts` — `FEATURE_SCOPES` constant
- Codebase read: `backend/vitest.config.ts` — test file location pattern (`../tests/**/*.test.ts`)
- Codebase read: `backend/src/index.ts` — router mount pattern, global CORS setup
- Phase 52 summary: `52-01-SUMMARY.md` — confirms scope fields live on all active grants

### Tertiary (LOW confidence)
- CONTEXT.md CORS requirement: "CORS-enabled for `*.empowered.vote`" — implies extending `CORS_ORIGIN` env var, not verified in env.ts CORS_ORIGIN pattern handling

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in project, no new installs
- Cache pattern: HIGH — `cache.ts` and `authService.ts` cache usage read directly
- `checkRole()` NULL semantics: HIGH — CONTEXT.md is explicit; verified against SC3 test requirement
- `requireRole()` factory: HIGH — `requireAdmin`/`requireStagingReviewer` precedents read directly
- Architecture constraint: HIGH — `architecture.test.ts` allowlist read directly
- CORS for `/roles/check`: MEDIUM — global CORS handles `*.empowered.vote` if in `CORS_ORIGIN`; need to verify Civic Spaces origin is in the allowed list

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (stable patterns — no fast-moving dependencies)
