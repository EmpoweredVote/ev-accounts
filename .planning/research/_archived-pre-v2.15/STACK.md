# Technology Stack — v1.9 Roles Milestone

**Project:** ev-accounts
**Milestone:** v1.9 — Delegated Authority / Scoped Roles
**Researched:** 2026-04-02
**Overall confidence:** HIGH — all conclusions drawn from reading actual project code, not from external sources

---

## Summary Verdict

The existing stack handles all three v1.9 requirements with zero new runtime dependencies. One new Vite + React app is needed (the contributor portal), but it is a copy of `app/` with no new packages. The backend needs no new npm packages — `pg`, `express`, `zod`, and `jose` cover everything.

---

## Existing Stack (validated, do not re-research)

| Layer | Technology | Version (package.json) |
|-------|-----------|----------------------|
| Runtime | Node.js / Express | 4.21.x |
| Language | TypeScript strict | 5.6.x |
| Database driver | `pg` (raw pool) | 8.13.x |
| Auth verification | `jose` (JWKS / ES256) | 5.9.x |
| Input validation | `zod` | 3.23.x |
| Rate limiting | `express-rate-limit` | 7.4.x |
| Logging | `winston` | 3.17.x |
| Frontend (app) | React 18 + Vite 5 + Tailwind v4 | as in app/package.json |
| Frontend (admin) | React 18 + Vite 5 + Tailwind v4 | as in admin/package.json |
| State (FE) | Zustand | 5.0.x |
| Routing (FE) | react-router-dom | 6.21.x |
| UI primitives | @headlessui/react | 2.2.x |
| Supabase client | @supabase/supabase-js + @supabase/ssr | 2.45.x / 0.5.x |
| Cache | @upstash/redis (HTTP) | 1.34.x |

---

## What Each New Capability Needs

### 1. Contributor Portal (new Vite + React app)

**Verdict: Copy `app/` as template. No new packages.**

The contributor portal reads auth from the shared `ev_session` cookie using the same pattern already implemented in `app/src/App.tsx`: call `GET /api/auth/session`, store the access token in Zustand, attach as `Authorization: Bearer` on every subsequent `apiFetch` call. This pattern is fully proven and requires no changes to the backend or the cookie infrastructure.

**Setup:**
- Create `contributor/` directory at repo root, parallel to `app/` and `admin/`
- Copy `app/package.json`, rename to `empowered-accounts-contributor`
- Copy `app/vite.config.ts`, change dev port to 5176
- Copy `app/src/lib/api.ts` and `app/src/store/authStore.ts` — both are generic and reusable without modification as a starting point
- Tailwind v4 setup is identical to `app/`: `@tailwindcss/vite` plugin in vite.config, `@import "tailwindcss"` in index.css, same `ev-*` CSS custom properties for brand colors

**What authStore.ts needs extended for the contributor portal:**
The existing `User` interface carries tier and basic profile fields. The contributor portal's authStore needs one additional field: `roles` — an array of the user's active role grants, each with `slug`, `feature_scope`, `jurisdiction_geoid`, and `resource_id`. Fetch from `GET /api/roles/me` immediately after `GET /account/me` during session init. This is a store extension, not a new library.

**Role-aware routing pattern:**
Use react-router-dom `<Routes>` with a `RoleGuard` component (analogous to `AuthGuard` in `app/src/components/`) that checks `useAuthStore().roles` for the required `feature_scope`. Each role-type view lives at its own route (`/compass-editor`, `/ctc-editor`, `/campaign-manager`, etc.). No additional library needed — this is a conditional render pattern using existing tools.

---

### 2. Resource-Scoped Permission Middleware (backend)

**Verdict: No new packages. Extend the existing middleware pattern.**

The existing middleware chain is `requireAuth → [role check] → route handler`. The new middleware slot is `requireRole(featureScope, options?)`, following the exact shape of `requireAdmin.ts` and `tierGuards.ts`.

Implementation queries `public.user_roles` (joined to `public.roles` for the slug/feature_scope lookup) via `pool.query()`. The middleware checks for an active (non-revoked) grant matching `feature_scope`, and optionally validates `jurisdiction_geoid` and `resource_id` against route params.

**Why `pool.query()` not supabaseAdmin:** The new `user_roles` columns (`feature_scope`, `jurisdiction_geoid`, `resource_id`) need to be read together with the role slug in a single JOIN. `pool.query()` is the established pattern for multi-column reads requiring joins and is required for any non-public schema access. It also means the middleware is consistent with how roleService already works internally.

**Middleware signature (conceptual):**
```
requireRole(featureScope: string, opts?: {
  jurisdictionParam?: string;   // req.params key to match against jurisdiction_geoid
  resourceParam?: string;       // req.params key to match against resource_id
})
```

When `jurisdictionParam` is provided, the middleware checks that the user's grant covers the jurisdiction in the request param. When `resourceParam` is provided, it checks `resource_id` matches (e.g., ensuring a Campaign Manager only edits their assigned politician). Mismatch returns 403. This is the same pattern as the existing guards: either call `next()` or return 403.

**Caching:** Role grants change infrequently. Cache the grant lookup in Upstash Redis with a short TTL (60–120 seconds) using the existing `@upstash/redis` client and the in-memory fallback already in place. Key pattern: `roles:uid:{userId}`. Invalidate on grant/revoke. This follows the existing revocation-check cache pattern in `authService.ts`. Keep TTL short — role revocations for high-trust actions (Campaign Manager) should take effect promptly, not after 15 minutes.

---

### 3. Append-Only Audit Log

**Verdict: Postgres table with JSONB before/after columns. Insert via `pool.query()`. No new packages.**

**Table design recommendation:**

```sql
CREATE TABLE public.role_audit_log (
  id                BIGSERIAL    PRIMARY KEY,
  occurred_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  actor_user_id     UUID         NOT NULL REFERENCES auth.users(id),
  target_type       TEXT         NOT NULL,  -- e.g. 'politician', 'compass_topic'
  target_id         TEXT         NOT NULL,  -- resource identifier
  action            TEXT         NOT NULL,  -- e.g. 'update_stance', 'edit_bio'
  role_slug         TEXT         NOT NULL,
  jurisdiction_geoid TEXT,
  before_snapshot   JSONB,
  after_snapshot    JSONB
);
```

NULL `before_snapshot` = create operation. NULL `after_snapshot` = delete operation. Both present = update.

**Why JSONB, not text diff:**
- JSONB is queryable: admins can filter by `before_snapshot->>'field_name'` or compare specific fields
- Text diffs (unified diff format) are human-readable but not queryable and require a diff library
- The domain involves structured records (politician stances, topic answers, bio fields): JSONB captures full record state, which is what auditors need to reconstruct history
- Snapshots are constructed server-side as plain JS objects, JSON-stringified, and passed to `pool.query()` — no library needed

**Append-only enforcement (two layers):**
1. RLS policy: allow INSERT for service role, deny UPDATE and DELETE for all roles
2. Application layer: no route or service ever issues DELETE or UPDATE on this table

The combination is belt-and-suspenders. Document the intent explicitly in the migration file.

**Write helper pattern:** A shared `backend/src/lib/auditLog.ts` module with a `recordAudit(...)` function that does a `pool.query()` INSERT. Called by role-gated route handlers AFTER the primary write succeeds — this ensures the audit record reflects what actually changed, not what was attempted. If the audit INSERT fails, log the error via `winston` but do not roll back the primary write (audit failure should not block content operations; the primary write has already succeeded atomically).

**Indexes:**
- `CREATE INDEX ON public.role_audit_log (actor_user_id, occurred_at DESC)` — "activity by user" admin query
- `CREATE INDEX ON public.role_audit_log (target_type, target_id, occurred_at DESC)` — "history of this resource" query

---

## Schema Changes Required in `public.user_roles`

These are migrations, not new packages. The existing `grant_role` and `revoke_role` SECURITY DEFINER RPCs need updated signatures to accept the new columns. The `get_user_roles` RPC must return them so the contributor portal's authStore can populate the roles array.

```sql
ALTER TABLE public.user_roles
  ADD COLUMN feature_scope       TEXT,
  ADD COLUMN jurisdiction_geoid  TEXT,
  ADD COLUMN resource_id         TEXT;
```

---

## What NOT to Add

| Candidate | Decision | Reason |
|-----------|----------|--------|
| `casl` (authorization library) | DO NOT ADD | Adds an abstraction layer over a simple check already expressed clearly as middleware. The existing guard pattern is sufficient and consistent with how the rest of the codebase works. |
| `diff` / `jest-diff` / `deep-diff` | DO NOT ADD | JSONB snapshots are superior to text diffs for this domain. No diff library needed. |
| `nx` or `turborepo` | DO NOT ADD | Three Vite apps as sibling directories is the established pattern. A monorepo build tool adds overhead with no current benefit for v1.9. |
| `@tanstack/react-query` | DO NOT ADD | Zustand + `apiFetch` covers all data fetching in the existing apps. Introducing a query cache library creates inconsistency across the three apps with no clear gain. |
| Roles baked into Supabase JWT claims | DO NOT DO | Role grants live in `public.user_roles`, not in the JWT. Fetching on session init (one extra API call) is correct — role changes take effect without requiring a new JWT. Baking roles into JWT claims means revocations don't propagate until the token expires (~1 hour). |
| Redis role cache with TTL > 120s | CAUTION | High-trust role actions (Campaign Manager editing politician records) need prompt revocation propagation. Keep TTL at 60–120 seconds maximum. |

---

## Contributor Portal: Directory Structure

Mirror `app/` exactly:

```
contributor/
  package.json          (name: empowered-accounts-contributor)
  tsconfig.json         (copy from app/)
  vite.config.ts        (copy from app/, dev port 5176)
  index.html
  src/
    main.tsx
    App.tsx             (SSO init + role-aware routing)
    index.css           (Tailwind v4 @import "tailwindcss" + ev-* theme vars)
    lib/
      api.ts            (copy from app/src/lib/api.ts — identical)
    store/
      authStore.ts      (extend: add roles[] to User type)
    components/
      AuthGuard.tsx     (copy from app/ — identical)
      RoleGuard.tsx     (new: checks roles[].feature_scope)
    pages/
      (one page per feature_scope: CompassEditorPage, CtcEditorPage, CampaignManagerPage, etc.)
```

---

## Render Deployment

The contributor portal is a static Vite build, same deployment pattern as `app/` and `admin/`. Add a new Render Static Site pointing to `contributor/dist/`. Set `VITE_API_URL=https://api.empowered.vote`. The `ev_session` cookie domain is `.empowered.vote`, which already covers `contributors.empowered.vote` — no cookie configuration changes needed on the backend.

---

## Sources

All findings based on direct code inspection of this repository:

- `backend/src/middleware/requireAdmin.ts` — guard pattern
- `backend/src/middleware/tierGuards.ts` — guard pattern
- `backend/src/middleware/auth.ts` — JWT verification, AuthenticatedRequest type
- `backend/src/lib/roleService.ts` — existing role service pattern
- `backend/src/routes/roles.ts` — existing roles routes
- `app/src/App.tsx` — SSO init pattern, ev_session cookie exchange
- `app/src/store/authStore.ts` — Zustand auth state pattern
- `app/src/lib/api.ts` — apiFetch pattern
- `app/vite.config.ts` — Vite setup
- `app/package.json` — app dependencies
- `admin/package.json` — admin dependencies
- `backend/package.json` — backend dependencies
