# Phase 1: Foundation - Research

**Researched:** 2026-02-24
**Domain:** Supabase schema design, RLS policies, Postgres RPC functions, Express/TypeScript server bootstrap
**Confidence:** HIGH (primary sources: official Supabase docs, project design documents, prior verified stack research)

---

## Summary

Phase 1 is the database and server foundation on which all 8 phases build. It has two discrete deliverables: (1) the complete Supabase schema — all tables across 4 schemas, all RLS policies, all atomic RPC functions — and (2) the Express server bootstrap — project structure, dual Supabase client pattern, JWT middleware, Zod env validation, and the health endpoint. Routes and user flows are explicitly out of scope.

The technical work in this phase is SQL-heavy. The migration files are the primary artifact. The design document (`empowered-accounts-design.md`) and CONTEXT.md provide the exact table definitions, making this research a verification and augmentation exercise — confirming patterns, catching gaps, and documenting implementation-ready SQL. The project's prior stack and architecture research (STACK.md, ARCHITECTURE.md, PITFALLS.md) is comprehensive and largely verified; key updates are noted below.

The most important discovery in this research: **Supabase projects created after May 1, 2025 use ES256 (asymmetric) JWT signing by default.** This changes the JWT middleware pattern. The `jsonwebtoken` + `jwks-rsa` approach in STACK.md still works but the current Supabase-recommended pattern is `jose` (`jwtVerify` + `createRemoteJWKSet`). The JWKS endpoint is `https://<project_ref>.supabase.co/auth/v1/.well-known/jwks.json`.

**Primary recommendation:** Build schema migrations first (completely, with all RLS policies and RPC functions verified via SQL impersonation tests), then bootstrap the Express server. The schema is the contract; the server is the consumer.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@supabase/supabase-js` | ^2.45.x | Supabase client — DB, Auth, RPC calls | Official v2 client; fully typed; `.rpc()` for function calls |
| `@supabase/ssr` | ^0.5.x | Server-side auth helpers (cookie/JWT handling) | Replaces deprecated `@supabase/auth-helpers-*` |
| `express` | ^4.19.x | HTTP server | Express 5.x still RC — stay on 4.x |
| `typescript` | ^5.5.x | Type system | Strict mode required |
| `jose` | ^5.x | JWT verification via JWKS | Supabase's own documented approach for asymmetric JWT verification; works with ES256 and RS256; replaces `jsonwebtoken` + `jwks-rsa` for new projects using asymmetric keys |
| `zod` | ^3.23.x | Env var validation + request validation | Standard TypeScript-first validation |
| `pg` | ^8.12.x | Raw Postgres driver | For atomic transactions — Supabase JS client has no BEGIN/COMMIT |
| `@upstash/redis` | ^1.31.x | Redis client | HTTP-based; required for Upstash — NOT `ioredis` |
| `supabase` CLI | latest | Migration authoring, type generation | `supabase migration new`, `supabase db push`, `supabase gen types` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `node-cron` | ^3.0.x | In-process scheduled jobs | Calibration lapse enforcement (Phase 7 uses this, scaffolded in Phase 1) |
| `winston` | ^3.13.x | Structured logging | JSON transport in production |
| `helmet` | ^7.1.x | HTTP security headers | One-line security posture |
| `cors` | ^2.8.x | CORS middleware | Required for Framer frontend origin |
| `express-rate-limit` | ^7.3.x | Rate limiting | Auth endpoints |
| `dotenv` | ^16.4.x | Env loading | Import at process entry point only |
| `tsx` | ^4.17.x | TypeScript dev execution | Replaces `ts-node`; faster, no config friction |
| `vitest` | ^2.x | Testing | Unit + integration tests |
| `supertest` | ^7.x | HTTP integration testing | Test Express routes without a live server |

### Alternatives Considered (Locked — Do Not Revisit)

| Instead of | Could Use | Why Standard Wins |
|------------|-----------|-------------------|
| `jose` | `jsonwebtoken` + `jwks-rsa` | Both work; `jose` is Supabase's current documented recommendation and natively handles ES256/RS256 via JWKS without extra library |
| `jose` | `supabase.auth.getUser()` per request | `getUser()` is a network round-trip per request — too slow for middleware hot path |
| `@upstash/redis` | `ioredis` | Upstash exposes HTTP, not TCP; `ioredis` will fail to connect |
| `@supabase/ssr` | `@supabase/auth-helpers-*` | `auth-helpers-*` officially deprecated |
| Raw `pg` | Prisma, Drizzle | Prisma conflicts with Supabase CLI migration ownership; Drizzle adds a layer that fights Supabase's typed client |
| Express 4.x | Express 5.x | Express 5 still in RC as of research date |

### Installation

```bash
# Backend
npm install \
  @supabase/supabase-js \
  @supabase/ssr \
  express \
  jose \
  zod \
  pg \
  @upstash/redis \
  node-cron \
  winston \
  helmet \
  cors \
  express-rate-limit \
  dotenv

npm install -D \
  typescript \
  @types/express \
  @types/node \
  @types/pg \
  @types/cors \
  @types/node-cron \
  tsx \
  vitest \
  supertest \
  @types/supertest \
  eslint \
  @typescript-eslint/eslint-plugin \
  @typescript-eslint/parser \
  prettier \
  eslint-config-prettier

# Supabase CLI
npm install -D supabase
```

---

## Architecture Patterns

### Recommended Project Structure

```
C:/EV-Accounts/
├── supabase/
│   ├── migrations/              # ALL schema changes go here — never Studio
│   │   ├── 20260224_001_create_schemas.sql
│   │   ├── 20260224_002_public_users.sql
│   │   ├── 20260224_003_public_roles_enum.sql
│   │   ├── 20260224_004_public_user_roles.sql
│   │   ├── 20260224_005_connect_connected_profiles.sql
│   │   ├── 20260224_006_connect_peer_connections.sql
│   │   ├── 20260224_007_connect_account_follows.sql
│   │   ├── 20260224_008_connect_gem_transactions.sql
│   │   ├── 20260224_009_connect_verification_sessions.sql
│   │   ├── 20260224_010_empower_empowered_profiles.sql
│   │   ├── 20260224_011_admin_audit_log.sql
│   │   ├── 20260224_012_rls_public.sql
│   │   ├── 20260224_013_rls_connect.sql
│   │   ├── 20260224_014_rls_empower.sql
│   │   └── 20260224_015_rpc_functions.sql
│   └── config.toml
│
├── backend/
│   ├── src/
│   │   ├── lib/
│   │   │   ├── env.ts              # Zod env validation — fail fast at startup
│   │   │   ├── supabase.ts         # supabaseAdmin singleton + createUserClient()
│   │   │   ├── db.ts               # pg Pool for raw transactions
│   │   │   └── cache.ts            # Redis with in-memory fallback
│   │   ├── middleware/
│   │   │   ├── auth.ts             # JWT middleware (jose + JWKS)
│   │   │   └── tierGuards.ts       # requireConnected, requireEmpowered
│   │   ├── routes/
│   │   │   └── health.ts           # GET /api/health
│   │   ├── types/
│   │   │   ├── request.d.ts        # AuthenticatedRequest extends Request
│   │   │   ├── domain.ts           # TierLevel type
│   │   │   └── database.types.ts   # Generated by supabase gen types
│   │   └── index.ts                # App entry — mount routes, listen
│   ├── package.json
│   └── tsconfig.json
│
└── tests/
    ├── rls/                    # SQL SET LOCAL impersonation tests
    │   ├── public_users.sql
    │   ├── connect_profiles.sql
    │   └── empower_profiles.sql
    └── integration/            # supertest integration tests
        ├── health.test.ts
        └── rls.test.ts         # Assert tolerance_rating absent from responses
```

### Pattern 1: Migration File Structure

**What:** Every migration is a standalone, transaction-wrapped SQL file. DDL first, then indexes, then any DML. Naming uses timestamp prefix to prevent collision.

**When to use:** Every schema change without exception.

```sql
-- 20260224_005_connect_connected_profiles.sql

BEGIN;

CREATE TABLE connect.connected_profiles (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL UNIQUE REFERENCES public.users(id),
  display_name          TEXT NOT NULL,
  account_standing      TEXT NOT NULL DEFAULT 'active'
    CHECK (account_standing IN ('active', 'suspended', 'quarantined')),
  verification_status   TEXT NOT NULL DEFAULT 'pending'
    CHECK (verification_status IN ('pending', 'verified', 'suspended')),
  verification_method   TEXT,
  verified_region       TEXT,
  xp                    INTEGER NOT NULL DEFAULT 0,
  gem_balance           INTEGER NOT NULL DEFAULT 0,
  gem_reserve_cap       INTEGER NOT NULL DEFAULT 1000,
  veracity_rating       NUMERIC(4,2),
  tolerance_rating      NUMERIC(4,2),   -- NEVER returned to non-owning users
  deleted_at            TIMESTAMPTZ,    -- soft delete propagated from public.users
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

-- Index every FK column — PostgreSQL does NOT auto-index FK columns
CREATE INDEX idx_connected_profiles_user_id ON connect.connected_profiles(user_id);
CREATE INDEX idx_connected_profiles_deleted_at ON connect.connected_profiles(deleted_at)
  WHERE deleted_at IS NULL;  -- partial index — active records only

COMMIT;
```

### Pattern 2: Dual Supabase Client

**What:** Two clients — one with service role (trusted writes, bypasses RLS), one per-request with user JWT (RLS enforced). The split is architectural, not optional.

```typescript
// backend/src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';
import { env } from './env';

// Admin client — bypasses RLS. Used ONLY for trusted server writes.
// NEVER used for reads that return data to users.
export const supabaseAdmin = createClient<Database>(
  env.SUPABASE_URL,
  env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

// Per-request client — user JWT injected, RLS enforced.
// Call inside route handlers after auth middleware has run.
export function createUserClient(accessToken: string) {
  return createClient<Database>(
    env.SUPABASE_URL,
    env.SUPABASE_ANON_KEY,
    {
      global: {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      },
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );
}
```

### Pattern 3: JWT Middleware Using `jose` (UPDATED — New Projects Use ES256)

**What:** JWKS-based local JWT verification using `jose`. Does not call `supabase.auth.getUser()` on every request. The JWKS endpoint is cached by `createRemoteJWKSet`. Also checks `account_standing` on every authenticated request to enforce suspensions within the 1-hour JWT window.

**Critical:** Supabase projects created after May 1, 2025 use ES256 (asymmetric) by default. The JWKS endpoint only returns keys for asymmetric signing. If the project uses the legacy HS256 (symmetric) secret, use `jose.jwtVerify(token, new TextEncoder().encode(env.SUPABASE_JWT_SECRET))` instead.

```typescript
// backend/src/middleware/auth.ts
import { jwtVerify, createRemoteJWKSet, type JWTPayload } from 'jose';
import { Request, Response, NextFunction } from 'express';
import { env } from '../lib/env';
import { supabaseAdmin } from '../lib/supabase';

// JWKS is fetched once and cached — no network call per request
const JWKS = createRemoteJWKSet(
  new URL(`${env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`)
);

export interface AuthenticatedRequest extends Request {
  userId: string;
  accessToken: string;
}

export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing authorization header' });
    return;
  }

  const token = authHeader.slice(7);

  try {
    const { payload } = await jwtVerify(token, JWKS, {
      issuer: `${env.SUPABASE_URL}/auth/v1`,
      audience: 'authenticated',
    });

    const userId = payload.sub;
    if (!userId) {
      res.status(401).json({ error: 'Invalid token: missing sub' });
      return;
    }

    // Standing check — enforces suspension within JWT validity window.
    // Queries connected_profiles because that is where account_standing lives.
    const { data: profile } = await supabaseAdmin
      .from('connected_profiles')
      .select('account_standing')
      .eq('user_id', userId)
      .maybeSingle();

    // Profile absence = Inform tier (no connected_profiles row) — still allowed
    // through to routes; tier guards handle elevation requirements.
    if (profile && profile.account_standing !== 'active') {
      res.status(403).json({ error: 'Account suspended' });
      return;
    }

    (req as AuthenticatedRequest).userId = userId;
    (req as AuthenticatedRequest).accessToken = token;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}
```

### Pattern 4: RLS Policy Authoring

**What:** All RLS policies use `(select auth.uid())` (wrapped in SELECT for query plan caching), specify the `TO` role, and are `USING`/`WITH CHECK` as appropriate. Sensitive columns (`tolerance_rating`, `legal_name`) are never returned via any RLS-accessible path.

**Note on column-level security:** PostgreSQL column-level security (GRANT/REVOKE on columns) is not used here. Instead, RLS policies control row access at the table level, and application-layer serialization enforces column projection. Both layers are required per the project contract.

```sql
-- 20260224_012_rls_public.sql
BEGIN;

-- public.users: RLS enabled, deny by default
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Owners see their own record (all columns)
CREATE POLICY "users: owner select"
  ON public.users
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = id AND deleted_at IS NULL);

-- public record for authenticated users: display_name and tier-derived fields only.
-- Sensitive columns (email, account_standing, created_at) excluded via
-- application-layer serialization — not via a separate policy, since PostgreSQL
-- row-level security cannot restrict columns per-policy. Serialization layer
-- must whitelist columns for public-facing responses.

-- Only service role may INSERT/UPDATE (user creation via trigger, updates via admin)
-- No INSERT/UPDATE/DELETE policies for anon or authenticated roles.

-- public.user_roles: only service role reads/writes (admin operations)
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
-- No policies for non-service-role users — service role bypasses RLS

COMMIT;
```

```sql
-- 20260224_013_rls_connect.sql
BEGIN;

ALTER TABLE connect.connected_profiles ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can check whether a connected_profile exists for a user
-- (tier status is public — CONTEXT.md: "tier status (existence of record) is public").
-- BUT: tolerance_rating and verification_method are never in the select list.
-- Application layer projects only safe columns for non-owner reads.
CREATE POLICY "connected_profiles: authenticated read (existence check)"
  ON connect.connected_profiles
  FOR SELECT
  TO authenticated
  USING (deleted_at IS NULL);

-- Owner also sees suspended/quarantined (so they know why they're blocked)
-- The above policy covers this. Standing is NOT a filter here — owner needs
-- to see their own record regardless of standing.

-- Only service role may INSERT/UPDATE connected_profiles
-- No INSERT/UPDATE policies for authenticated role

ALTER TABLE connect.verification_sessions ENABLE ROW LEVEL SECURITY;

-- Owner only — verification session contains PII draft data
CREATE POLICY "verification_sessions: owner only"
  ON connect.verification_sessions
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

ALTER TABLE connect.peer_connections ENABLE ROW LEVEL SECURITY;

-- Either party in the connection can read it
CREATE POLICY "peer_connections: participant read"
  ON connect.peer_connections
  FOR SELECT
  TO authenticated
  USING (
    (select auth.uid()) = requester_id
    OR (select auth.uid()) = addressee_id
  );

ALTER TABLE connect.account_follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "account_follows: follower read own follows"
  ON connect.account_follows
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = follower_id);

CREATE POLICY "account_follows: followed sees who follows them"
  ON connect.account_follows
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = followed_id);

ALTER TABLE connect.gem_transactions ENABLE ROW LEVEL SECURITY;

-- Owner only — gem ledger is private
CREATE POLICY "gem_transactions: owner read"
  ON connect.gem_transactions
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

COMMIT;
```

```sql
-- 20260224_014_rls_empower.sql
BEGIN;

ALTER TABLE empower.empowered_profiles ENABLE ROW LEVEL SECURITY;

-- Anonymous users can read public-facing fields (supports Phase 8 public candidate pages).
-- CONTEXT.md: "anonymous users can read public-facing fields (slug, candidate page metadata)"
-- legal_name IS exposed here (it's the public name of an Empowered civic leader),
-- but tolerance_rating is NEVER exposed in any non-service-role policy.
CREATE POLICY "empowered_profiles: public read active"
  ON empower.empowered_profiles
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Owners also read their own inactive profile (so they can see demotion state)
CREATE POLICY "empowered_profiles: owner read own"
  ON empower.empowered_profiles
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

-- No INSERT/UPDATE for non-service-role — empowerment and demotion are RPC functions only

COMMIT;
```

### Pattern 5: RPC Function Structure (SECURITY DEFINER)

**What:** All multi-table atomic operations live as Postgres functions in the `empower` schema, called via `supabase.rpc()`. Functions use `SECURITY DEFINER` with an empty `search_path`. Every function has `EXCEPTION WHEN OTHERS THEN RAISE` to ensure any error propagates and triggers a rollback.

**Critical Supabase requirement:** `SECURITY DEFINER` functions MUST set `search_path = ''` — Supabase requires this to prevent schema injection attacks.

```sql
-- 20260224_015_rpc_functions.sql
BEGIN;

-- execute_empowerment: atomic empowerment transaction
-- Called via: supabase.rpc('execute_empowerment', { p_user_id, p_legal_name, p_connected_profile_id })
CREATE OR REPLACE FUNCTION empower.execute_empowerment(
  p_user_id               UUID,
  p_legal_name            TEXT,
  p_connected_profile_id  UUID
)
RETURNS empower.empowered_profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_slug   TEXT;
  v_suffix TEXT;
  v_result empower.empowered_profiles;
BEGIN
  -- Generate slug with 4-char random suffix (per MEMORY.md: "john-smith-a3b4")
  v_suffix := substring(md5(gen_random_uuid()::text) FROM 1 FOR 4);
  v_slug := lower(
    regexp_replace(p_legal_name, '[^a-zA-Z0-9]+', '-', 'g')
  ) || '-' || v_suffix;

  -- Step 1: Insert empowered profile
  INSERT INTO empower.empowered_profiles (
    user_id,
    connected_profile_id,
    legal_name,
    candidate_page_slug,
    empowered_at
  ) VALUES (
    p_user_id,
    p_connected_profile_id,
    p_legal_name,
    v_slug,
    now()
  )
  RETURNING * INTO v_result;

  -- Step 2: Batch compass responses to public
  -- (inform.compass_responses not yet created in Phase 1 — this UPDATE is a no-op
  --  until Phase 4 creates the table. Kept here for structural completeness.)
  UPDATE inform.compass_responses
    SET visibility = 'public', updated_at = now()
    WHERE user_id = p_user_id;

  RETURN v_result;

EXCEPTION WHEN OTHERS THEN
  RAISE;  -- Re-raise causes implicit rollback of the whole function
END;
$$;

-- execute_demotion: atomic demotion transaction
CREATE OR REPLACE FUNCTION empower.execute_demotion(
  p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE empower.empowered_profiles
    SET is_active = false, updated_at = now()
    WHERE user_id = p_user_id AND is_active = true;

  UPDATE inform.compass_responses
    SET visibility = 'private', updated_at = now()
    WHERE user_id = p_user_id;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;

-- get_calibration_lapsed_users: query for cron job
-- Returns user_ids of Empowered Accounts with uncalibrated topics > 30 days
CREATE OR REPLACE FUNCTION public.get_calibration_lapsed_users()
RETURNS TABLE (user_id UUID)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT DISTINCT ep.user_id
  FROM empower.empowered_profiles ep
  WHERE ep.is_active = true
    AND EXISTS (
      SELECT 1
      FROM inform.compass_topics ct
      WHERE ct.status = 'live'
        AND ct.created_at < now() - INTERVAL '30 days'
        AND NOT EXISTS (
          SELECT 1
          FROM inform.compass_responses cr
          WHERE cr.user_id = ep.user_id
            AND cr.topic_id = ct.id
        )
    );
$$;

COMMIT;
```

### Pattern 6: RLS Testing via SQL Impersonation

**What:** Before any migration goes to production, RLS policies are verified by impersonating users in SQL using `SET LOCAL` within a transaction block. Run against the local Supabase dev environment.

```sql
-- tests/rls/connect_profiles.sql

-- Test 1: User A cannot see User B's tolerance_rating via any RLS-accessible path
BEGIN;
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "user-b-uuid", "role": "authenticated"}';

  -- Should return a row (existence is public) but tolerance_rating must be
  -- excluded by application-layer serialization. Test RLS grants row access:
  SELECT COUNT(*) FROM connect.connected_profiles
  WHERE user_id = 'user-a-uuid';
  -- Expected: 1 row returned (existence visible)

  -- Confirm tolerance_rating is a real column (schema test)
  SELECT column_name FROM information_schema.columns
  WHERE table_schema = 'connect'
    AND table_name = 'connected_profiles'
    AND column_name = 'tolerance_rating';
  -- Expected: 1 row (column exists — serialization layer must exclude it)

ROLLBACK;

-- Test 2: Suspended user cannot pass the standing check
-- (This is tested in integration tests, not SQL impersonation — see tests/integration/auth.test.ts)

-- Test 3: empowered_profiles — anonymous user sees active profiles
BEGIN;
  SET LOCAL role TO anon;
  SET LOCAL "request.jwt.claims" TO '{}';

  SELECT COUNT(*) FROM empower.empowered_profiles
  WHERE is_active = true;
  -- Expected: N rows (whatever is active)

  SELECT COUNT(*) FROM empower.empowered_profiles
  WHERE is_active = false;
  -- Expected: 0 rows (inactive hidden from anon)

ROLLBACK;
```

### Pattern 7: Soft Delete Cascade

**What:** `public.users.deleted_at` is the canonical soft-delete signal. When an admin sets this, child record `deleted_at` fields are cascaded. Connected and empowered profile records are preserved (invite chain integrity) but their `deleted_at` is also stamped to exclude them from normal queries.

**Recommendation (Claude's discretion — cascade `deleted_at`):** Cascade `deleted_at` to child records in a `SECURITY DEFINER` function called by an admin trigger or RPC. Records remain for invite chain accountability; all normal queries filter `WHERE deleted_at IS NULL`. This is simpler than a separate "is this account deleted?" join and prevents accidentally surfacing deleted users in queries that forget the join.

```sql
-- Cascade function (called by admin route, not a DB trigger — admin-only per CONTEXT.md)
CREATE OR REPLACE FUNCTION public.soft_delete_user(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.users
    SET deleted_at = now(), updated_at = now()
    WHERE id = p_user_id AND deleted_at IS NULL;

  UPDATE connect.connected_profiles
    SET deleted_at = now(), updated_at = now()
    WHERE user_id = p_user_id AND deleted_at IS NULL;

  -- empowered_profiles: set is_active = false AND stamp deleted_at
  -- Preserves invite tree; deactivates candidate page.
  UPDATE empower.empowered_profiles
    SET is_active = false, deleted_at = now(), updated_at = now()
    WHERE user_id = p_user_id AND deleted_at IS NULL;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

### Pattern 8: Zod Env Validation

**What:** All required env vars validated at process start via Zod. Service role key validated as present but never logged. Fail fast with descriptive errors.

```typescript
// backend/src/lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().default('3000'),
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().optional(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('[startup] Missing or invalid environment variables:');
  console.error(JSON.stringify(parsed.error.flatten().fieldErrors, null, 2));
  process.exit(1);
}

// Service role key: never logged, never returned in responses
export const env = parsed.data;

// Startup assertion — if this ever appears in logs it is a security incident
if (process.env.SUPABASE_SERVICE_ROLE_KEY &&
    process.env.SUPABASE_SERVICE_ROLE_KEY.length < 10) {
  console.error('[startup] SUPABASE_SERVICE_ROLE_KEY appears invalid — exiting');
  process.exit(1);
}
```

### Pattern 9: Health Endpoint

```typescript
// backend/src/routes/health.ts
import { Router } from 'express';

const router = Router();

router.get('/', (_req, res) => {
  res.json({ status: 'ok', timestamp: Date.now() });
});

export default router;

// backend/src/index.ts (mount)
app.use('/api/health', healthRouter);
```

### Anti-Patterns to Avoid

- **Tier flag on `public.users`:** Never add a `tier` column. Tier = child record existence. Enforced structurally.
- **`supabaseAdmin` for user-facing reads:** Service role bypasses all RLS. Any read that returns data to a user must use `createUserClient(accessToken)`.
- **`SELECT *` on tables with sensitive columns:** Always project columns explicitly. `tolerance_rating` must never appear in a non-admin response column list.
- **SECURITY DEFINER without `SET search_path = ''`:** Supabase requires this; omitting it is a security vulnerability.
- **RLS policies without tests:** Untested policies may have typos, wrong operator precedence, or fail when `auth.uid()` is NULL. Test via SQL impersonation before shipping.
- **Chained `await` calls for multi-table writes:** Any failure between steps leaves partial state. All multi-table writes are RPC functions.
- **`supabase.auth.getUser(token)` in middleware:** Network call per request — use JWKS-based local verification.
- **Migrations that mix DDL and DML without transaction wrapping:** Partial migrations leave the schema in an unknown state.

---

## Complete Table Schema

All tables derived from `empowered-accounts-design.md` and augmented with Phase 1 CONTEXT.md decisions.

### Schema 1: `public`

```sql
-- public.users: extension of auth.users
-- CONTEXT: soft delete via deleted_at; deleted user preserved in invite chain
CREATE TABLE public.users (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  deleted_at  TIMESTAMPTZ,              -- soft delete; NULL = active
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- role_type enum (defined in public schema — used across features)
CREATE TYPE public.role_type AS ENUM (
  'maven', 'journo', 'arbiter', 'moderator',
  'juror', 'educator', 'guide', 'scribe'
);

-- user_roles: junction table — multi-role support, soft revocation
CREATE TABLE public.user_roles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.users(id),
  role_type   public.role_type NOT NULL,
  granted_at  TIMESTAMPTZ DEFAULT now(),
  revoked_at  TIMESTAMPTZ,             -- NULL = currently active
  UNIQUE (user_id, role_type)
);
CREATE INDEX idx_user_roles_user_id ON public.user_roles(user_id);

-- admin_audit_log: scaffolded now; populated by admin routes in Phase 7
-- FOUND-08: table exists in Phase 1 schema
CREATE TABLE public.admin_audit_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    UUID NOT NULL REFERENCES public.users(id),
  action      TEXT NOT NULL,
  target_id   UUID,                    -- user or resource being acted upon
  metadata    JSONB,
  created_at  TIMESTAMPTZ DEFAULT now()
);
-- append-only: no UPDATE/DELETE policies on this table
CREATE INDEX idx_admin_audit_log_actor_id ON public.admin_audit_log(actor_id);
CREATE INDEX idx_admin_audit_log_created_at ON public.admin_audit_log(created_at);
```

### Schema 2: `connect`

```sql
-- connected_profiles: exists when Connect verification complete
-- CONTEXT: account_standing ('active','suspended','quarantined') on THIS table
-- CONTEXT: visible to any authenticated user (tier status is public)
-- CONTEXT: tolerance_rating blocked at RLS + serialization layer
CREATE TABLE connect.connected_profiles (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL UNIQUE REFERENCES public.users(id),
  display_name          TEXT NOT NULL,
  account_standing      TEXT NOT NULL DEFAULT 'active'
    CHECK (account_standing IN ('active', 'suspended', 'quarantined')),
  verification_status   TEXT NOT NULL DEFAULT 'pending'
    CHECK (verification_status IN ('pending', 'verified', 'suspended')),
  verification_method   TEXT,          -- NEVER returned to clients
  verified_region       TEXT,
  xp                    INTEGER NOT NULL DEFAULT 0,
  gem_balance           INTEGER NOT NULL DEFAULT 0,
  gem_reserve_cap       INTEGER NOT NULL DEFAULT 1000,
  veracity_rating       NUMERIC(4,2),
  tolerance_rating      NUMERIC(4,2),  -- NEVER returned to non-owning users
  deleted_at            TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_connected_profiles_user_id ON connect.connected_profiles(user_id);
CREATE INDEX idx_connected_profiles_standing
  ON connect.connected_profiles(account_standing)
  WHERE account_standing != 'active';  -- partial index for suspension queries

-- peer_connections: mutual connection requests between Connected users
CREATE TABLE connect.peer_connections (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id    UUID NOT NULL REFERENCES public.users(id),
  addressee_id    UUID NOT NULL REFERENCES public.users(id),
  status          TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE (requester_id, addressee_id)
);
CREATE INDEX idx_peer_connections_requester ON connect.peer_connections(requester_id);
CREATE INDEX idx_peer_connections_addressee ON connect.peer_connections(addressee_id);

-- account_follows: 1-way follow (Connected → Empowered, no approval needed)
CREATE TABLE connect.account_follows (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id     UUID NOT NULL REFERENCES public.users(id),
  followed_id     UUID NOT NULL REFERENCES public.users(id),
  created_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE (follower_id, followed_id)
);
CREATE INDEX idx_account_follows_follower ON connect.account_follows(follower_id);
CREATE INDEX idx_account_follows_followed ON connect.account_follows(followed_id);

-- gem_transactions: append-only ledger (positive = credit, negative = debit)
CREATE TABLE connect.gem_transactions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES public.users(id),
  amount            INTEGER NOT NULL,
  transaction_type  TEXT NOT NULL,
  feature_context   TEXT,
  reference_id      UUID,
  balance_after     INTEGER NOT NULL,
  created_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_gem_transactions_user_id ON connect.gem_transactions(user_id);

-- verification_sessions: resumable Connect flow state
CREATE TABLE connect.verification_sessions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES public.users(id),
  step_reached          TEXT NOT NULL,
  display_name_draft    TEXT,
  verification_method   TEXT,
  region_draft          TEXT,
  expires_at            TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_verification_sessions_user_id ON connect.verification_sessions(user_id);
```

### Schema 3: `empower`

```sql
-- empowered_profiles: exists when Empower activated (requires connected_profiles)
-- CONTEXT: legal_name is here — only post-empowerment, public on candidate page
-- CONTEXT: tolerance_rating is on connected_profiles, not here — access via service role only
CREATE TABLE empower.empowered_profiles (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL UNIQUE REFERENCES public.users(id),
  connected_profile_id  UUID NOT NULL REFERENCES connect.connected_profiles(id),
  legal_name            TEXT NOT NULL,   -- public post-empowerment (civic leader)
  empowered_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active             BOOLEAN NOT NULL DEFAULT true,
  candidate_page_slug   TEXT UNIQUE,
  deleted_at            TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_empowered_profiles_user_id ON empower.empowered_profiles(user_id);
CREATE INDEX idx_empowered_profiles_slug ON empower.empowered_profiles(candidate_page_slug)
  WHERE candidate_page_slug IS NOT NULL;
CREATE INDEX idx_empowered_profiles_active ON empower.empowered_profiles(is_active)
  WHERE is_active = true;
```

### Schema 4: `inform`

```sql
-- CONTEXT.md (locked): Phase 1 creates the inform schema namespace ONLY.
-- No tables. Compass tables (topics, stances, responses, change_history) deferred to Phase 4.
-- The schema namespace must exist for RPC functions that reference inform.compass_responses.
-- The UPDATE in execute_empowerment/execute_demotion is a no-op until Phase 4 creates the table.
CREATE SCHEMA IF NOT EXISTS inform;
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JWT verification | Custom decode/verify logic | `jose` with `createRemoteJWKSet` | Handles key rotation, caching, ES256/RS256 correctly; algorithm confusion attacks are real |
| Atomic multi-table writes | Chained `await` service calls | Postgres RPC functions | Supabase JS client has no transaction control; partial state on any failure is unrecoverable |
| Env var validation | Hand-coded `if (!process.env.X)` | Zod schema with `safeParse` | Type inference, descriptive errors, fail-fast pattern in one call |
| Redis fallback | Complex try/catch per usage | Shared `CacheClient` abstraction with `InMemoryFallback` | Redis down cannot crash API; abstraction hides implementation |
| Schema migrations | Studio schema edits | Supabase CLI `supabase migration new` | Studio edits create unreproducible schema drift |
| Type generation | Hand-written Supabase table types | `supabase gen types --linked --lang typescript` | Auto-generated from live schema; always in sync; single source of truth |
| Slug collision prevention | Application-side uniqueness check | `UNIQUE` constraint on `candidate_page_slug` + random suffix | DB constraint is the only reliable uniqueness gate; random 4-char suffix per MEMORY.md |
| Soft delete filtering | Application-layer `if (!user.deleted_at)` everywhere | `WHERE deleted_at IS NULL` in all queries + partial indexes | Partial indexes on `deleted_at IS NULL` make these queries cheap; application forgetting to filter is a data leak |

---

## Common Pitfalls

### Pitfall 1: `inform.compass_responses` Table Missing for RPC Functions

**What goes wrong:** `execute_empowerment` and `execute_demotion` both reference `inform.compass_responses` which is NOT created in Phase 1. The RPC function will fail to compile if the table doesn't exist.

**Why it happens:** The RPC function code references a Phase 4 table in a Phase 1 migration.

**How to avoid:** The `inform` schema must exist before these functions compile. The `UPDATE inform.compass_responses ...` statement inside the RPC functions will fail at function creation time if the table does not exist.

**Two options:**
1. Create stub `inform.compass_responses` table in Phase 1 with minimal columns (user_id, visibility) so the RPC functions compile — Phase 4 adds the full structure via ALTER TABLE.
2. Create the RPC functions without the compass_responses UPDATE in Phase 1, and recreate them in Phase 4 with the full body.

**Recommendation:** Option 2 — create minimal Phase 1 RPC functions that document what will be added in Phase 4 via comments. This keeps Phase 1 self-contained and avoids stub tables that create schema drift between phases.

**Revised Phase 1 RPC bodies:** Remove the `UPDATE inform.compass_responses` lines from `execute_empowerment` and `execute_demotion`. Phase 4 will `CREATE OR REPLACE FUNCTION` with the full bodies when the inform schema tables exist.

### Pitfall 2: SECURITY DEFINER Without `search_path`

**What goes wrong:** Supabase's documentation explicitly requires `SET search_path = ''` on all `SECURITY DEFINER` functions. Without it, a malicious schema injection can cause the function to use wrong table paths.

**Why it happens:** Developers omit the search_path clause when copying function templates from older docs.

**How to avoid:** Every `SECURITY DEFINER` function in every migration must include `SET search_path = ''`. All table references inside the function must use fully qualified schema-prefix notation (e.g., `empower.empowered_profiles`, not just `empowered_profiles`).

### Pitfall 3: JWT Algorithm Mismatch

**What goes wrong:** If the Supabase project was created before May 1, 2025, it likely uses HS256 (symmetric) by default. The JWKS-based `jose` pattern only works for asymmetric keys (RS256/ES256). An HS256 project's JWKS endpoint returns no keys, causing every JWT verification to fail.

**Why it happens:** The transition from HS256 to asymmetric happened at a specific date; existing projects may not have been migrated.

**How to avoid:** Check the Supabase project's Auth settings → JWT Configuration. If HS256 is configured, use `jose.jwtVerify(token, new TextEncoder().encode(env.SUPABASE_JWT_SECRET))` instead of `createRemoteJWKSet`. If asymmetric (ES256/RS256), use the JWKS approach. Document which algorithm the project uses in a comment in `auth.ts`.

**For new projects (post-May 2025):** ES256 with JWKS is the default — use `createRemoteJWKSet`.

### Pitfall 4: RLS Policy Tests Never Run

**What goes wrong:** RLS policies are written correctly in SQL but never verified. The policies may have `auth.uid()` referenced incorrectly, column names misspelled, or operator precedence errors. The system appears to work in happy-path tests but leaks data in edge cases.

**Why it happens:** Teams treat RLS as "configuration" not "code" and skip testing.

**How to avoid:** Every table with sensitive data requires a SQL impersonation test (`SET LOCAL role TO authenticated; SET LOCAL "request.jwt.claims" TO '{"sub": "..."}';`) AND an application-layer integration test that asserts the field is absent from the HTTP response body. Both tests must be written in Phase 1 and must pass before migrations are considered done.

### Pitfall 5: `account_standing` on Wrong Table

**What goes wrong:** The CONTEXT.md decision places `account_standing` on `connect.connected_profiles`. If it's accidentally placed on `public.users` instead (a common intuition), the enforcement logic doesn't match the data model. Routes that query `public.users` to check standing would "work" but the suspension system would not be integrated with tier detection.

**Why it happens:** `account_standing` feels like a property of "the user" rather than "the connected tier".

**How to avoid:** Per CONTEXT.md and FOUND-09: `account_standing` is a column on `connect.connected_profiles` with values `('active', 'suspended', 'quarantined')`. The auth middleware queries `connected_profiles.account_standing` to enforce suspension. Inform-tier users (no `connected_profiles` row) are not subject to `account_standing` checks — they're anonymous.

### Pitfall 6: Slug Uniqueness Race Condition

**What goes wrong:** Two users with identical legal names empower at the same moment. Both generate the same base slug. The `UNIQUE` constraint on `candidate_page_slug` will reject the second insert.

**Why it happens:** The slug generation uses the legal name as input. Identical names produce identical base slugs before the random suffix is applied.

**How to avoid:** The MEMORY.md specifies a 4-char alphanumeric suffix (e.g., `john-smith-a3b4`). The `UNIQUE` constraint on `candidate_page_slug` is the final guard. If the RPC function gets a uniqueness violation, the exception propagates up (`RAISE;`), the transaction rolls back, and the application retries. Application layer must catch `duplicate key` errors from `execute_empowerment` and retry with a different slug (or present an error to the user). A `DO ... LOOP` in the SQL function could handle this, but simplest is to handle retry at the service layer.

### Pitfall 7: `deleted_at` Not Indexed

**What goes wrong:** Every query that filters `WHERE deleted_at IS NULL` does a full table scan on large tables.

**Why it happens:** Developers add the column and the filter but forget the index.

**How to avoid:** Add a **partial index** on each `deleted_at` column: `CREATE INDEX idx_<table>_deleted_at ON <table>(deleted_at) WHERE deleted_at IS NULL`. Partial indexes are much smaller than full column indexes since most records are not deleted.

---

## Code Examples

### Server Entry Point

```typescript
// backend/src/index.ts
import 'dotenv/config';  // Must be first import
import { env } from './lib/env';  // Validates env vars — exits if invalid
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import healthRouter from './routes/health';

const app = express();

app.use(helmet());
app.use(cors({ origin: env.NODE_ENV === 'development' ? '*' : ['https://your-framer-domain.com'] }));
app.use(express.json());

// Routes
app.use('/api/health', healthRouter);
// Phase 2+ routes mounted here

const port = parseInt(env.PORT, 10);
app.listen(port, () => {
  console.info(`[server] listening on port ${port}`);
  console.info(`[server] environment: ${env.NODE_ENV}`);
  // startAllCronJobs() — Phase 7
});
```

### Supabase CLI Type Generation

```bash
# After every schema migration
supabase gen types --linked --lang typescript --schema public,connect,empower,inform \
  > backend/src/types/database.types.ts

# Access generated types
import type { Database } from '../types/database.types';
type ConnectedProfile = Database['connect']['Tables']['connected_profiles']['Row'];
```

### Integration Test Pattern for Sensitive Field Absence

```typescript
// tests/integration/rls.test.ts
import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import app from '../../backend/src/index';

describe('RLS: tolerance_rating must never leak', () => {
  it('is absent from connected_profiles GET response for non-owner', async () => {
    // Authenticate as User B
    const { accessToken } = await authenticateTestUser('user-b@test.com');

    // Request User A's profile (which exists but is not User B's)
    const res = await request(app)
      .get('/api/account/user-a-id')  // Phase 2 endpoint — test structure established now
      .set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body).not.toHaveProperty('tolerance_rating');
    // Note: assert ABSENT, not null. A null value would still be a policy gap.
  });
});
```

### Supabase CLI Migration Workflow

```bash
# Initialize once
supabase init
supabase link --project-ref <your-project-ref>

# Create new migration
supabase migration new create_connected_profiles
# Edits: supabase/migrations/<timestamp>_create_connected_profiles.sql

# Apply to linked remote project
supabase db push

# Generate types after migration
supabase gen types --linked --lang typescript > backend/src/types/database.types.ts

# Never: supabase db reset on production
# Never: schema edits in Studio on linked project
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| `@supabase/auth-helpers-*` | `@supabase/ssr` | ~2023–2024 | `auth-helpers-*` deprecated; all server-side auth must use `@supabase/ssr` |
| HS256 symmetric JWT (default) | ES256 asymmetric (default for new projects) | May 1, 2025 | New projects use JWKS; `jose` + `createRemoteJWKSet` replaces `jsonwebtoken` + shared secret |
| `ts-node` for TypeScript dev | `tsx` | ~2023 | `tsx` is faster, no CJS/ESM config friction, community standard |
| `jsonwebtoken` + `jwks-rsa` | `jose` | 2025 (Supabase guidance) | `jose` handles both RS256 and ES256; Supabase's own docs show `jose` pattern |
| Sequential `await` for multi-table writes | Postgres RPC functions via `supabase.rpc()` | Platform decision (pre-Phase 1) | Atomicity guaranteed by Postgres, not application-layer optimism |

**Deprecated/outdated:**
- `@supabase/auth-helpers-express`, `@supabase/auth-helpers-nextjs`: officially deprecated, no further updates — use `@supabase/ssr`
- `ioredis` with Upstash: Upstash HTTP API, not TCP socket — use `@upstash/redis`
- Studio schema edits for production: creates migration drift — use `supabase migration new` + `supabase db push`

---

## Open Questions

1. **JWT algorithm for this specific Supabase project**
   - What we know: New projects (post-May 2025) default to ES256 asymmetric; JWKS-based verification is the documented approach
   - What's unclear: Whether this specific project was created before or after May 1, 2025, and whether it has been migrated to asymmetric keys
   - Recommendation: Check Auth settings in Supabase dashboard before writing auth middleware. If HS256, use symmetric verification pattern. Document the algorithm in `auth.ts` as a comment.

2. **`inform.compass_responses` dependency in RPC functions**
   - What we know: `execute_empowerment` and `execute_demotion` both need to batch-update compass visibility; that table doesn't exist in Phase 1
   - What's unclear: Best approach — stub table vs. simplified Phase 1 RPC functions
   - Recommendation: Create Phase 1 RPC functions WITHOUT the compass_responses UPDATE. Document clearly that Phase 4 will `CREATE OR REPLACE FUNCTION` with the full body. This keeps phases self-contained.

3. **Supabase project `config.toml` and local dev setup**
   - What we know: `supabase init` creates `config.toml`; `supabase start` runs local Docker stack; `supabase db push` applies migrations to linked remote
   - What's unclear: Whether local dev with Docker is already set up for this project
   - Recommendation: Planning should include a `supabase init` + `supabase link` step at the top of Plan 01-01.

---

## Sources

### Primary (HIGH confidence)
- `C:/EV-Accounts/empowered-accounts-design.md` — Complete data model SQL, API shape, user journeys (project source of truth)
- `C:/EV-Accounts/empowered-vote-primer.md` — Platform philosophy, schema conventions, infrastructure setup
- `C:/EV-Accounts/.planning/phases/01-foundation/01-CONTEXT.md` — User decisions, locked choices, Claude's discretion areas
- `C:/EV-Accounts/.planning/research/STACK.md` — Verified stack with versions and patterns
- `C:/EV-Accounts/.planning/research/ARCHITECTURE.md` — System architecture, migration numbering, data flows
- `C:/EV-Accounts/.planning/research/PITFALLS.md` — 10 critical pitfalls with prevention code
- Supabase RLS documentation (https://supabase.com/docs/guides/auth/row-level-security) — Current policy syntax, `(select auth.uid())` optimization, `WITH CHECK` vs `USING`
- Supabase database functions documentation (https://supabase.com/docs/guides/database/functions) — `SECURITY DEFINER` requirements, `search_path = ''` mandate, RPC calling pattern

### Secondary (MEDIUM confidence)
- Supabase JWT signing keys documentation (https://supabase.com/docs/guides/auth/signing-keys) — ES256 default for new projects, JWKS endpoint pattern
- Supabase JWKS endpoint pattern (`https://<project_ref>.supabase.co/auth/v1/.well-known/jwks.json`) — verified via official docs WebFetch
- `jose` library as current recommendation for JWT verification — verified via Supabase's own JWT docs showing `jwtVerify` + `createRemoteJWKSet` pattern
- Supabase CLI `supabase gen types` command options — verified via official CLI reference

### Tertiary (LOW confidence)
- May 1, 2025 asymmetric JWT default date — WebSearch result; confirmed in Supabase GitHub discussion #29289 but not cross-verified with an official changelog entry

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — drawn from prior verified research (STACK.md) plus official Supabase docs for JWT algorithm update
- Architecture: HIGH — drawn from official Supabase documentation + project design documents
- SQL schema: HIGH — directly from `empowered-accounts-design.md` (project source of truth) + CONTEXT.md decisions
- RLS policies: HIGH — syntax verified against current Supabase RLS docs
- RPC functions: HIGH — syntax verified against Supabase functions docs; `search_path` requirement confirmed
- JWT middleware pattern: MEDIUM-HIGH — `jose` pattern verified from Supabase official JWT docs; algorithm (HS256 vs ES256) for this specific project unconfirmed (see Open Questions)
- Pitfalls: HIGH — sourced from PITFALLS.md (project-specific analysis) + Phase 1 CONTEXT.md decisions

**Research date:** 2026-02-24
**Valid until:** 2026-03-24 (30 days — stable domain; re-verify `jose` version on npm before locking)
