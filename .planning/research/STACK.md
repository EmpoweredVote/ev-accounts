# Stack Research

**Domain:** Tiered account system — Supabase + Express/TypeScript
**Researched:** 2026-02-24
**Confidence:** MEDIUM-HIGH (based on verified library documentation and patterns through knowledge cutoff; web search unavailable — verify pinned versions against npm before locking)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `@supabase/supabase-js` | ^2.45.x | Supabase client (DB, Auth, Storage queries) | Official client; v2 is stable, fully typed, has ergonomic `.from()` builder + Auth helpers. v1 is EOL. |
| `@supabase/ssr` | ^0.5.x | Server-side Auth helpers (cookie/JWT handling) | Replaces deprecated `@supabase/auth-helpers-*` packages. The correct server-side companion to supabase-js v2. |
| `express` | ^4.19.x | HTTP server framework | Mature, minimal, universal middleware ecosystem. Express 5 is in RC but not production-stable as of research date — stay on 4.x. |
| `typescript` | ^5.5.x | Type system | Strict mode required per project constraints. 5.5+ has improved type narrowing and declaration emit. |
| `@upstash/redis` | ^1.31.x | Redis client for Upstash | HTTP-based Redis client; works in serverless and long-lived processes alike. Native TypeScript types. Not `ioredis` — Upstash exposes HTTP, not TCP. |
| `node` | 20.x LTS | Runtime | LTS; Render's default for new services. Node 22 is available but 20.x has broader ecosystem validation. |
| `supabase` (CLI) | latest | Migration tooling, local dev | The official migration path. `supabase db push` deploys migrations. Never schema edit in Studio for production. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `jsonwebtoken` | ^9.0.x | Decode/verify Supabase JWTs in Express middleware | Use when verifying Supabase-issued access tokens in Express without round-tripping to Supabase on every request. Use `getUser()` for important mutations. |
| `jwks-rsa` | ^3.1.x | Fetch Supabase JWKS for JWT verification | Supabase issues RS256 JWTs; `jwks-rsa` caches the public key from the JWKS endpoint. Pair with `jsonwebtoken`. |
| `zod` | ^3.23.x | Runtime schema validation + TypeScript inference | Validate all incoming request bodies. Generate inferred types from schemas — source of truth for request shape. |
| `pg` | ^8.12.x | Raw PostgreSQL driver | For atomic transactions that span multiple tables. Use `pg` + `BEGIN/COMMIT` directly rather than the Supabase client for empowerment/demotion transactions. |
| `node-cron` | ^3.0.x | In-process scheduled jobs | Calibration lapse enforcement. Render free tier has no separate cron service; `node-cron` runs inside the Express process. |
| `winston` | ^3.13.x | Structured logging | Render's log drain accepts structured logs. Use JSON transport in production (`NODE_ENV=production`), pretty in dev. |
| `helmet` | ^7.1.x | HTTP security headers | One-line default security posture. Always include in Express. |
| `cors` | ^2.8.x | CORS middleware | Required for Framer (external origin) to hit this API. Allowlist origins explicitly. |
| `express-rate-limit` | ^7.3.x | Rate limiting | Auth endpoints especially. Free-tier Redis store (`rate-limit-redis`) optional — in-memory is fine for pilot scale. |
| `dotenv` | ^16.4.x | Environment variable loading | `dotenv/config` import at process entry point. Never use `dotenv.config()` inside modules. |
| `concurrently` | ^8.2.x | Root workspace dev script | Runs backend + frontend dev servers together from root `package.json`. |
| `tsx` | ^4.17.x | TypeScript execution for dev | Replaces `ts-node` for development. Faster, ESM-compatible, no config changes needed. |
| `vite` | ^5.4.x | Admin frontend bundler | The declared stack. Pairs with React 18. |
| `react` / `react-dom` | ^18.3.x | Admin frontend UI | React 18 with concurrent features. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `supabase` CLI | Migration authoring, local dev with `supabase start`, type generation | `supabase gen types typescript --linked` generates TypeScript types from live schema. Run after every migration. |
| `eslint` + `@typescript-eslint/*` | Linting | Use `@typescript-eslint/recommended-type-checked` ruleset — stricter than base. Catches `any` leakage. |
| `prettier` | Formatting | Single source of truth for formatting. Pair with `eslint-config-prettier` to avoid conflicts. |
| `vitest` | Unit + integration testing | Faster than Jest for TypeScript projects; native ESM support. Use for middleware, service, and utility tests. |
| `supertest` | HTTP integration testing | Test Express routes without starting a real server. Pair with vitest. |
| UptimeRobot | Uptime monitoring | Pings `/api/health` every 5 minutes to prevent Render free-tier cold start on real traffic. Free plan sufficient. |

---

## Installation

```bash
# ---- Backend (backend/) ----
npm install \
  @supabase/supabase-js \
  @supabase/ssr \
  express \
  @upstash/redis \
  jsonwebtoken \
  jwks-rsa \
  zod \
  pg \
  node-cron \
  winston \
  helmet \
  cors \
  express-rate-limit \
  dotenv

# Backend dev dependencies
npm install -D \
  typescript \
  @types/express \
  @types/node \
  @types/jsonwebtoken \
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

# ---- Frontend admin tool (frontend/) ----
npm install \
  @supabase/supabase-js \
  react \
  react-dom \
  zod

npm install -D \
  vite \
  @vitejs/plugin-react \
  typescript \
  @types/react \
  @types/react-dom

# ---- Supabase CLI (global or devDep) ----
npm install -D supabase
# or: npx supabase ...
```

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Auth helpers | `@supabase/ssr` | `@supabase/auth-helpers-nextjs`, `@supabase/auth-helpers-express` | The `auth-helpers-*` packages are officially deprecated. `@supabase/ssr` is the replacement. |
| JWT verification | `jsonwebtoken` + `jwks-rsa` | Supabase `auth.getUser(token)` for every request | `getUser()` makes a network call to Supabase on every request — too slow for middleware. Use local JWT verification with JWKS for read-heavy middleware; reserve `getUser()` for auth-sensitive mutations. |
| Atomic transactions | Raw `pg` client | Supabase JS client `.rpc()` with a stored procedure | Both work. Raw `pg` is more transparent and debuggable for the empowerment/demotion flow. Stored procedures are fine too — pick one and be consistent. `pg` is recommended here for clarity of the application-side transaction logic. |
| Cron jobs | `node-cron` (in-process) | Render Cron Jobs (paid), external scheduler | Render Cron Jobs require a paid plan. In-process `node-cron` with UptimeRobot keepalive is sufficient for pilot. Migrate to Render Cron or a separate worker when the platform grows. |
| Rate limiting | `express-rate-limit` (in-memory) | `rate-limit-redis` (Redis-backed) | In-memory is sufficient for a single Render instance. Add Redis store when horizontal scaling is needed. |
| HTTP framework | Express 4.x | Fastify, Hono | Fastify is faster but requires plugins for everything Express has built-in. Hono is excellent for edge but adds complexity on Render. Express 4.x is the right choice for a straightforward REST API at pilot scale. Express 5 deferred — RC status at research time. |
| ORM | None (raw `pg` + Supabase client) | Drizzle ORM, Prisma | Drizzle is tempting and TypeScript-first, but Supabase + raw `pg` already provides typed queries via generated types + `pg`. Prisma conflicts with Supabase's migration model (Prisma wants schema ownership; Supabase CLI owns it here). Avoid adding an ORM layer that fights the migration toolchain. |
| Redis client | `@upstash/redis` | `ioredis` | Upstash exposes an HTTP REST API, not a TCP socket. `ioredis` requires TCP and will not work with Upstash in a serverless/managed context. `@upstash/redis` is the correct client for this setup. |
| Validation | `zod` | `joi`, `yup`, `typebox` | Zod is the standard in TypeScript-first codebases. Static type inference from schemas avoids double-declaration. `typebox` is faster but more complex. `joi` has no TypeScript inference. |
| TypeScript runner (dev) | `tsx` | `ts-node`, `ts-node-esm` | `tsx` is dramatically faster than `ts-node`, has no CommonJS/ESM config friction, and is the current community default. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `@supabase/auth-helpers-*` | Officially deprecated by Supabase team. Will not receive updates. | `@supabase/ssr` |
| Supabase client with service role key on the frontend | Service role key bypasses all RLS. Exposing it client-side destroys every RLS policy. Never. | Service role key stays in `backend/`. Frontend uses anon key only. |
| Prisma | Prisma wants to own the schema and migration lifecycle. Supabase CLI owns it here. The two systems conflict. | Supabase CLI migrations + `supabase gen types` + raw `pg` for transactions |
| `ioredis` with Upstash | Upstash does not expose a TCP Redis socket on the free tier — `ioredis` will fail to connect. | `@upstash/redis` (HTTP-based) |
| Express 5.x | Still in release candidate as of research date. Middleware ecosystem not fully updated. | Express 4.19.x |
| `any` type | Project constraint: TypeScript strict mode. `any` silently removes all type safety downstream. | Proper types or `unknown` + type guards |
| Storing JWTs in localStorage on the admin frontend | XSS risk. Supabase Auth uses httpOnly cookies when using `@supabase/ssr`. | Let Supabase Auth manage session storage via its built-in session persistence |
| Manual schema changes in Supabase Studio for production | Creates schema drift — the CLI migration history diverges from actual schema. Impossible to reproduce. | `supabase migration new` + `supabase db push` every time |
| `process.env` without validation at startup | Crashes at runtime with unhelpful messages. | Validate all required env vars at startup with zod or a custom check function. Fail fast with a descriptive error. |

---

## Supabase-Specific Patterns

### 1. Server-Side Client Construction (Express)

Create two Supabase clients — one with the service role key for admin operations, one per-request using the user's JWT for RLS-enforced queries.

```typescript
// src/lib/supabase.ts

import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types'; // generated by supabase gen types

// Admin client — bypasses RLS. Used ONLY for trusted server operations.
// Never returned to the client, never used for user-facing queries.
export const supabaseAdmin = createClient<Database>(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

// Create a per-request client that injects the user's JWT so RLS applies.
// Call this inside your auth middleware after verifying the JWT.
export function createUserClient(accessToken: string) {
  return createClient<Database>(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_ANON_KEY!,
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

### 2. JWT Verification Middleware (Express)

Do NOT call `supabase.auth.getUser()` on every request — it is a network round-trip. Instead, verify the JWT locally using the Supabase JWKS endpoint and cache the public key.

```typescript
// src/middleware/auth.ts

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

const client = jwksClient({
  jwksUri: `${process.env.SUPABASE_URL}/auth/v1/keys`,
  cache: true,
  cacheMaxAge: 600_000, // 10 minutes
});

function getKey(header: jwt.JwtHeader, callback: jwt.SigningKeyCallback) {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) return callback(err, undefined);
    callback(null, key!.getPublicKey());
  });
}

export interface AuthenticatedRequest extends Request {
  userId: string;
  userEmail: string | undefined;
  accessToken: string;
}

export function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing authorization header' });
    return;
  }

  const token = authHeader.slice(7);

  jwt.verify(token, getKey, { algorithms: ['RS256'] }, (err, decoded) => {
    if (err) {
      res.status(401).json({ error: 'Invalid or expired token' });
      return;
    }

    const payload = decoded as jwt.JwtPayload;
    (req as AuthenticatedRequest).userId = payload.sub!;
    (req as AuthenticatedRequest).userEmail = payload.email as string | undefined;
    (req as AuthenticatedRequest).accessToken = token;
    next();
  });
}

// Tier guards — check DB for child record existence
// Call these AFTER requireAuth when a route needs a specific tier.
```

### 3. Tier Guard Pattern

Tier is determined by the presence of a child record, not a flag. Express middleware should reflect this.

```typescript
// src/middleware/tierGuards.ts

import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth';
import { supabaseAdmin } from '../lib/supabase';

export async function requireConnected(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const { data, error } = await supabaseAdmin
    .from('connected_profiles')
    .select('id, verification_status')
    .eq('user_id', req.userId)
    .maybeSingle();

  if (error || !data) {
    res.status(403).json({ error: 'Connected account required' });
    return;
  }

  if (data.verification_status !== 'verified') {
    res.status(403).json({ error: 'Verified Connected account required' });
    return;
  }

  next();
}

export async function requireEmpowered(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const { data, error } = await supabaseAdmin
    .from('empowered_profiles')
    .select('id, is_active')
    .eq('user_id', req.userId)
    .maybeSingle();

  if (error || !data || !data.is_active) {
    res.status(403).json({ error: 'Active Empowered account required' });
    return;
  }

  next();
}
```

### 4. Atomic Transactions via Raw `pg`

The empowerment and demotion flows require multi-table atomic transactions with full rollback on failure. Use raw `pg` directly — do not use the Supabase JS client for these operations, as it does not expose transaction control.

```typescript
// src/lib/db.ts

import { Pool } from 'pg';

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL, // Supabase DB direct URL
  max: 5, // conservative for free tier
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});

// src/services/empowermentService.ts

import { pool } from '../lib/db';

export async function executeEmpowerment(
  userId: string,
  legalName: string,
  candidateSlug: string
): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query(
      `INSERT INTO empower.empowered_profiles (user_id, legal_name, candidate_page_slug, empowered_at)
       SELECT cp.user_id, $2, $3, now()
       FROM connect.connected_profiles cp
       WHERE cp.user_id = $1 AND cp.verification_status = 'verified'`,
      [userId, legalName, candidateSlug]
    );

    await client.query(
      `UPDATE inform.compass_responses
       SET visibility = 'public', updated_at = now()
       WHERE user_id = $1`,
      [userId]
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
```

**Important:** The Supabase database URL for direct `pg` connections uses port 5432 (direct) or 6543 (pooler). Use the **Session mode pooler** (port 5432 via Supabase's connection pooler, or the direct URL) for long-lived Express processes. Avoid Transaction mode pooler (port 6543) if you use prepared statements or multi-statement transactions, as it resets connection state between queries.

### 5. RLS Policy Authoring Best Practices

**Always enable RLS on every table.** A table without RLS enabled is open to all authenticated users with the service role — or fully open if no policies match.

```sql
-- Pattern: always start with RLS enabled + deny-by-default
ALTER TABLE connect.connected_profiles ENABLE ROW LEVEL SECURITY;

-- Self-read: users can read their own profile
CREATE POLICY "connected_profiles: self read"
  ON connect.connected_profiles
  FOR SELECT
  USING (auth.uid() = user_id);

-- Public read for Empowered profiles (they are public by design)
-- but never expose tolerance_rating or legal identity of Connected users
CREATE POLICY "empowered_profiles: public read active"
  ON empower.empowered_profiles
  FOR SELECT
  USING (is_active = true);

-- Compass responses: visibility-gated reads
CREATE POLICY "compass_responses: self read all"
  ON inform.compass_responses
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "compass_responses: public read public responses"
  ON inform.compass_responses
  FOR SELECT
  USING (
    visibility = 'public'
    AND auth.uid() != user_id
  );

CREATE POLICY "compass_responses: friends read friends responses"
  ON inform.compass_responses
  FOR SELECT
  USING (
    visibility = 'friends'
    AND EXISTS (
      SELECT 1 FROM connect.peer_connections pc
      WHERE pc.status = 'accepted'
        AND (
          (pc.requester_id = auth.uid() AND pc.addressee_id = user_id)
          OR
          (pc.addressee_id = auth.uid() AND pc.requester_id = user_id)
        )
    )
  );

-- Service role bypasses RLS automatically — no policy needed for admin operations
```

**Critical RLS rules for this project:**
- `tolerance_rating` on `connected_profiles`: add a policy that only returns it when `auth.uid() = user_id`. Never return it in a join where the joining user is not the owner. Enforce at both RLS and application layer.
- `legal_name` on `empowered_profiles`: readable on the row, but do NOT create any view or policy that exposes a Connected user's legal name. The legal name is only on `empowered_profiles`, so by the data model it only exists post-empowerment. The risk is in any admin panel accidentally joining and returning it.
- Service role key queries bypass RLS entirely — every use of `supabaseAdmin` in application code is an RLS bypass and must be explicitly audited.

### 6. Upstash Redis with In-Memory Fallback

```typescript
// src/lib/cache.ts

import { Redis } from '@upstash/redis';

interface CacheClient {
  get<T>(key: string): Promise<T | null>;
  set(key: string, value: unknown, ttlSeconds?: number): Promise<void>;
  del(key: string): Promise<void>;
}

class InMemoryFallback implements CacheClient {
  private store = new Map<string, { value: unknown; expiresAt: number | null }>();

  async get<T>(key: string): Promise<T | null> {
    const entry = this.store.get(key);
    if (!entry) return null;
    if (entry.expiresAt && Date.now() > entry.expiresAt) {
      this.store.delete(key);
      return null;
    }
    return entry.value as T;
  }

  async set(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
    this.store.set(key, {
      value,
      expiresAt: ttlSeconds ? Date.now() + ttlSeconds * 1000 : null,
    });
  }

  async del(key: string): Promise<void> {
    this.store.delete(key);
  }
}

function createRedisClient(): CacheClient {
  if (!process.env.REDIS_URL) {
    console.warn('[cache] REDIS_URL not set — using in-memory fallback');
    return new InMemoryFallback();
  }

  try {
    const redis = new Redis({ url: process.env.REDIS_URL });
    return {
      async get<T>(key: string): Promise<T | null> {
        return redis.get<T>(key);
      },
      async set(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
        if (ttlSeconds) {
          await redis.set(key, value, { ex: ttlSeconds });
        } else {
          await redis.set(key, value);
        }
      },
      async del(key: string): Promise<void> {
        await redis.del(key);
      },
    };
  } catch {
    console.warn('[cache] Redis init failed — using in-memory fallback');
    return new InMemoryFallback();
  }
}

export const cache = createRedisClient();
```

### 7. Supabase CLI Migration Workflow

```bash
# Initialize (once, in repo root)
supabase init

# Link to your Supabase project
supabase link --project-ref <your-project-ref>

# Create a new migration
supabase migration new create_connected_profiles

# Edit the generated file in supabase/migrations/
# Then apply locally (requires Docker for local dev)
supabase db push  # applies to linked remote project

# Generate TypeScript types from the live schema
supabase gen types typescript --linked > backend/src/lib/database.types.ts

# Never: supabase db reset in production
# Never: schema edits in Studio on production project
```

**Migration file naming convention:** `supabase/migrations/<timestamp>_<descriptive_name>.sql`

The `supabase/migrations/` directory is the source of truth for schema. Every schema change — including RLS policies — goes in a migration file. Never create RLS policies interactively in Studio unless you immediately capture them in a migration.

### 8. Type Generation Integration

Generate types after every migration that changes the schema. The generated file (`database.types.ts`) is the bridge between the Supabase schema and TypeScript.

```typescript
// Usage after generation:
import type { Database } from './database.types';

// All table types are available:
type ConnectedProfile = Database['public']['Tables']['connected_profiles']['Row'];
type CompassResponse = Database['inform']['Tables']['compass_responses']['Row'];
```

Add `supabase gen types typescript --linked > src/lib/database.types.ts` to your CI/CD pipeline or as a pre-commit hook on migration files.

### 9. In-Process Cron for Calibration Lapse Enforcement

```typescript
// src/jobs/calibrationLapse.ts

import cron from 'node-cron';
import { supabaseAdmin } from '../lib/supabase';
import { pool } from '../lib/db';

// Runs daily at 2am UTC
export function startCalibrationLapseJob(): void {
  cron.schedule('0 2 * * *', async () => {
    console.info('[cron] calibration-lapse check started');
    try {
      await enforceCalibrationLapse();
    } catch (err) {
      console.error('[cron] calibration-lapse check failed', err);
      // Never throw — cron failure must not crash the server
    }
  });
}

async function enforceCalibrationLapse(): Promise<void> {
  // Find Empowered users who have uncalibrated topics older than 30 days
  // Execute atomic demotion for each
  // Notify affected users (notification system TBD)
}

// src/server.ts (entry point)
// startCalibrationLapseJob(); // Call at startup, after server is listening
```

**Render free tier note:** Render free services spin down after 15 minutes of inactivity. UptimeRobot pinging `/api/health` every 5 minutes prevents cold starts and keeps cron jobs alive. This is the documented mitigation for free-tier Render with in-process cron.

### 10. Env Var Validation at Startup

```typescript
// src/lib/env.ts

import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().default('3000'),
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().optional(), // Optional — falls back to in-memory
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('[startup] Missing or invalid environment variables:');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
```

---

## Admin Tool Notes

The internal admin tool (Vite + React in `frontend/`) connects to the same Supabase project using the anon key. Admin users authenticate via Supabase Auth (email/password or magic link). Admin-specific operations that require service role access are proxied through the Express backend — the React frontend never holds the service role key.

**Admin tool auth flow:**
1. Admin logs in via Supabase Auth on the frontend (anon key)
2. Frontend gets a JWT
3. Frontend sends JWT in `Authorization: Bearer` header to Express
4. Express middleware verifies JWT, checks if user has admin role via `public.user_roles`
5. Express performs the admin operation with the service role client

This keeps the service role key on the server side at all times.

---

## Sources

- Supabase JS v2 documentation (`@supabase/supabase-js`) — verified client API, `createClient` options, Auth helpers deprecation notice — MEDIUM (knowledge cutoff Aug 2025; confirm current version on npm)
- `@supabase/ssr` package docs — server-side auth replacement for deprecated `auth-helpers-*` — MEDIUM
- Supabase RLS documentation — policy syntax, `auth.uid()`, `USING`/`WITH CHECK` clauses — HIGH (SQL standards + Supabase docs consistent since 2023)
- Express 4.x documentation — middleware patterns, route handlers — HIGH (stable API, no breaking changes since 4.0)
- `@upstash/redis` documentation — HTTP-based client, `ex` TTL option — MEDIUM (verify current version on npm)
- `jwks-rsa` + `jsonwebtoken` — RS256 JWT verification pattern — HIGH (standard pattern; Supabase uses RS256)
- `node-cron` documentation — cron expression syntax, schedule API — HIGH
- Supabase CLI documentation — `supabase migration new`, `supabase db push`, `supabase gen types` commands — HIGH
- `pg` (node-postgres) documentation — `Pool`, `client.query`, `BEGIN`/`ROLLBACK` pattern — HIGH (stable since v8)
- Render documentation — free tier cold start behavior, `process.env.PORT` requirement — MEDIUM
- Zod v3 documentation — `z.object()`, `.safeParse()`, type inference — HIGH

**Before finalizing package.json:** Run `npm info <package> version` for each pinned package to confirm the latest stable version. Knowledge cutoff is August 2025; patch releases accumulate.
