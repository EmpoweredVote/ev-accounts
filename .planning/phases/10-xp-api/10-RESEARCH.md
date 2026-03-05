# Phase 10: XP API - Research

**Researched:** 2026-03-04
**Domain:** Express route layer over Phase 9 XP schema — service-key auth, idempotency enforcement, paginated history, public level lookup, and GET /account/me extension
**Confidence:** HIGH

## Summary

Phase 10 is a pure API surface phase. No new schema or migrations are required — Phase 9 delivered `connect.xp_transactions`, `connect.award_xp`, and `connect.calculate_level`. This phase adds four Express routes (`POST /api/xp/award`, `GET /api/xp/me/history`, `GET /api/xp/:userId`, and an extension to `GET /account/me`) plus a new `src/lib/xpService.ts` service module.

The codebase has deeply established patterns. The XP routes must follow them precisely or the architecture enforcement test (`tests/integration/architecture.test.ts`) will fail. That test bans `supabaseAdmin` from any file in `src/routes/`, enforces a hardcoded allowlist of files permitted to use the service-role client, and will need `lib/xpService.ts` added to that allowlist. Every route in this codebase follows the pattern: route handler calls a service function, service function holds all DB access.

The `award_xp` RPC already handles idempotency, advisory locking, and atomic balance updates. The route layer's job is to validate inputs, enforce service-key authorization, call `adminRpc('award_xp', ...)`, and shape the response. No idempotency logic needs to be implemented in TypeScript — the DB RPC is the enforcement point.

**Primary recommendation:** Create `src/lib/xpService.ts` (using `supabaseAdmin`/`adminRpc` for writes and reads), create `src/routes/xp.ts` (using only service functions), add the route to `src/index.ts`, update the architecture allowlist in `architecture.test.ts`, add service-key env vars to `src/lib/env.ts`, update `GET /account/me` in `src/routes/account.ts`, and write an integration test file `tests/integration/xp.test.ts`.

---

## Standard Stack

No new dependencies are required. All tools are already installed and in use.

### Core (already installed)
| Library | Version | Purpose | Role in Phase 10 |
|---------|---------|---------|-----------------|
| express | ^4.21.0 | HTTP routing | Route handler framework |
| zod | ^3.23.0 | Schema validation | Body/query param validation |
| @supabase/supabase-js | ^2.45.0 | DB client | `adminRpc`, `supabaseAdmin` queries |
| vitest | ^2.1.0 | Test runner | Integration test suite |
| supertest | ^7.0.0 | HTTP testing | Route-level integration tests |

### No new installations needed
All required packages are present in `backend/package.json`. Phase 10 adds no new dependencies.

---

## Architecture Patterns

### Established Project Structure (relevant to Phase 10)
```
backend/src/
├── routes/
│   ├── xp.ts              # NEW — XP route handlers (no supabaseAdmin here)
│   └── account.ts         # MODIFY — add xp object to GET /me response
├── lib/
│   ├── xpService.ts       # NEW — all XP DB access (supabaseAdmin allowed here)
│   └── supabase.ts        # EXISTING — adminRpc(), supabaseAdmin, createUserClient
├── middleware/
│   └── auth.ts            # EXISTING — requireAuth, optionalAuth
└── index.ts               # MODIFY — register /api/xp router
tests/integration/
├── xp.test.ts             # NEW — integration tests
└── architecture.test.ts   # MODIFY — add xpService to allowlist
```

### Pattern 1: Route → Service Separation (MANDATORY)

Every route file in this codebase delegates all DB access to a service in `src/lib/`. Route files may NOT import `supabaseAdmin`. The architecture enforcement test (`architecture.test.ts`) bans it.

**What:** Route handlers call named service functions. Service functions own all client references.
**When to use:** Always — every route in the codebase follows this.

```typescript
// src/routes/xp.ts — correct pattern (mirrors src/routes/gems.ts)
import { awardXp, getXpHistory, getPublicXpProfile } from '../lib/xpService.js';

router.post('/award', serviceKeyAuth('any'), async (req, res) => {
  try {
    const result = await awardXp({ userId, source, amount, idempotencyKey, metadata });
    res.status(200).json(result);
  } catch (err) {
    // ...
  }
});
```

```typescript
// src/lib/xpService.ts — correct pattern (mirrors src/lib/gemService.ts)
import { supabaseAdmin, adminRpc } from './supabase.js';

export async function awardXp(params: AwardXpParams): Promise<AwardXpResult> {
  const { data, error } = await adminRpc('award_xp', {
    p_user_id: params.userId,
    p_source: params.source,
    p_amount: params.amount,
    p_idempotency_key: params.idempotencyKey,
    p_metadata: params.metadata ?? null,
  });
  if (error) throw new Error(error.message);
  // Map first row of RETURNS TABLE result
  const row = Array.isArray(data) ? data[0] : data;
  if (!row) throw new Error('award_xp returned no rows');
  return {
    transaction_id: row.id,
    user_id: row.user_id,
    source: row.source,
    amount: row.amount,
    created_at: row.created_at,
    level: row.current_level,
    total_xp: row.total_xp,
    xp_in_level: row.xp_in_level,
    xp_to_next_level: row.xp_to_next_level,
    is_duplicate: row.is_duplicate,
  };
}
```

**Critical note:** `adminRpc` is defined in `src/lib/supabase.ts`. It accepts `fn: string` and `args?: Record<string, unknown>`. Use it for `award_xp` since new RPC functions are not yet reflected in `database.types.ts`. The `award_xp` function returns `RETURNS TABLE` — Supabase JS returns the table rows as an array in `data`.

### Pattern 2: Service Key Auth Middleware

The CONTEXT.md specifies a hardcoded mapping of env var keys to permitted sources. This is new middleware not present in the codebase — implement it following the style of `requireAdmin` in `src/middleware/requireAdmin.ts`.

```typescript
// src/middleware/serviceKeyAuth.ts — new file modeled on requireAdmin.ts
import { Request, Response, NextFunction } from 'express';
import { env } from '../lib/env.js';

// Hardcoded source-to-key mapping (locked decision from CONTEXT.md)
const SERVICE_KEY_SOURCES: Record<string, string[]> = {
  [env.QUEST_SERVICE_KEY ?? '']: ['validation_quest_completion'],
  [env.TRIVIA_SERVICE_KEY ?? '']: ['civic_trivia_championship_score'],
  [env.ADMIN_SERVICE_KEY ?? '']: ['admin_gift'],
};

// Middleware factory: validates X-Service-Key and optionally checks source permission
export function requireServiceKey(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const key = req.headers['x-service-key'] as string | undefined;
  if (!key || !SERVICE_KEY_SOURCES[key]) {
    res.status(401).json({ error: 'Missing or invalid X-Service-Key' });
    return;
  }
  // Attach permitted sources so route can check at body-parse time
  (req as ServiceKeyRequest).permittedSources = SERVICE_KEY_SOURCES[key];
  next();
}

export interface ServiceKeyRequest extends Request {
  permittedSources: string[];
}
```

**HTTP code for missing/invalid service key:** Use **401** — matching the pattern in `requireAuth` (`res.status(401).json({ error: '...' })`). The `requireAdmin` and `requireConnected` middlewares use 403 for "authenticated but unauthorized" — 401 is correct for missing/invalid credentials (the service key is the credential here).

### Pattern 3: Zod Validation with 422 on Failure

The codebase consistently uses `422` for validation failures on body/query parsing. See `src/routes/gems.ts` (`TransactionQuerySchema`) and `src/routes/account.ts` (`PatchMeSchema`).

```typescript
// Body validation for POST /api/xp/award
const AwardXpBodySchema = z.object({
  user_id: z.string().uuid(),
  source: z.enum(['validation_quest_completion', 'civic_trivia_championship_score', 'admin_gift']),
  amount: z.number().int().positive(),
  idempotency_key: z.string().min(1).max(255),
  metadata: z.record(z.unknown()).optional(),
});

// Query validation for GET /api/xp/me/history
const HistoryQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});
```

**Pagination defaults** (Claude's Discretion): Match the gem transactions pattern exactly — `default(50)` and `max(100)`. The gem route already sets this precedent with `limit: z.coerce.number().min(1).max(100).default(50)`.

### Pattern 4: Error Response Shape

Two shapes coexist in the codebase, both acceptable:
- `{ error: '...' }` — used in admin routes and middleware
- `{ code: 'ERROR_CODE', message: '...' }` — used in auth/account/gems routes

For XP routes (Claude's Discretion): use `{ error: '...' }` for simple cases (missing key, unknown source) and `{ code: 'VALIDATION_ERROR', message: '...' }` from Zod failures, matching the gems route pattern. The critical rule is never use both inconsistently within a single route.

### Pattern 5: award_xp RPC Result Mapping

The `award_xp` RPC uses `RETURNS TABLE` — Supabase JS client returns the result as an **array** of rows in `data`, not a single object. The route must access `data[0]`. The RPC column name for level is `current_level` in the DB but the CONTEXT.md specifies `level` in the response — map explicitly.

The response shape specified in CONTEXT.md:
```json
{
  "transaction_id": "...",   // maps from data[0].id
  "user_id": "...",
  "source": "...",
  "amount": 100,
  "created_at": "...",
  "level": 3,               // maps from data[0].current_level
  "total_xp": 7200,
  "xp_in_level": 200,
  "xp_to_next_level": 3800,
  "is_duplicate": false
}
```

### Pattern 6: Public Endpoint (GET /api/xp/:userId)

The public XP profile endpoint needs no auth. `calculate_level` was granted to `anon` in Phase 9 specifically for this. Read `total_xp` and `current_level` from `connected_profiles` via `supabaseAdmin`, then call `calculate_level` if `xp_in_level` / `xp_to_next_level` are needed.

Alternatively, read the denormalized columns directly and call `adminRpc('calculate_level', { p_total_xp: totalXp })` to get the computed fields. The response shape requires `xp_in_level` and `xp_to_next_level` per CONTEXT.md.

**Route ordering caution:** Express matches routes top-to-bottom. `GET /api/xp/me/history` (literal `me`) must be registered BEFORE `GET /api/xp/:userId` (param capture). If `:userId` is registered first, Express will treat "me" as a userId. This is the same issue documented in `src/routes/admin.ts` for `/invites/tree` vs `/invites/:codeId`.

### Pattern 7: GET /account/me Extension

The `GET /account/me` handler in `src/routes/account.ts` already reads `total_xp` and `current_level` from `connected_profiles` (those columns appear in the SELECT at line 59: `'id, display_name, account_standing, verification_status, tolerance_rating, xp, gem_balance, completed_onboarding, created_at'`). The select string needs `total_xp, current_level` added.

The new `xp` object must be added inside the `if (connected)` block, nested in `connected_profile`:
```typescript
// Extension to src/routes/account.ts — inside if (connected) block
meResponse.connected_profile = {
  display_name: connected.display_name,
  verification_status: connected.verification_status,
  tolerance_rating: connected.tolerance_rating,
  xp: connected.xp,           // legacy column — kept for compatibility
  gem_balance: connected.gem_balance,
  completed_onboarding: connected.completed_onboarding,
  created_at: connected.created_at,
  // Phase 10 additions:
  xp: {                        // ← CONFLICT: xp already used above for legacy column
    total: connected.total_xp,
    level: connected.current_level,
    xp_in_level: computed.xp_in_level,   // from calculate_level or stored
    xp_to_next_level: computed.xp_to_next_level,
  },
};
```

**Critical naming conflict:** The existing `connected_profile.xp` is the legacy integer column. XPAPI-04 requires an `xp` object with `{ total, level, xp_in_level, xp_to_next_level }`. These cannot share the key name. The legacy `xp` column must be renamed in the response (e.g., `legacy_xp`) or removed, or the new xp object must use a different key. **Recommended approach:** Replace `xp: connected.xp` with the new structured `xp` object entirely. The legacy column is explicitly noted as "to be migrated/removed in Phase 10" in the migration comments.

The XPAPI-04 requirement says `total, level, xp_in_level, xp_to_next_level`. `xp_in_level` and `xp_to_next_level` are computed — either call `calculate_level` within the account/me handler (adds a DB call) or derive from the `current_level` and `total_xp` in TypeScript using the same tier thresholds. Given that `calculate_level` is already a SECURITY DEFINER RPC callable server-side, call `adminRpc('calculate_level', { p_total_xp: connected.total_xp })` within the `/me` handler flow.

**Note on `account.ts` using `createUserClient`:** The `GET /me` handler uses `createUserClient(accessToken)` for RLS-enforced reads. But `calculate_level` is a SECURITY DEFINER function — it works with any role. The user client can call it too, because `calculate_level` was granted to `authenticated`. Import and call `adminRpc` for this, or use the user's DB client: `db.schema('connect').rpc('calculate_level', { p_total_xp: connected.total_xp })`.

### Pattern 8: Architecture Test Update (MANDATORY)

`tests/integration/architecture.test.ts` maintains a hardcoded allowlist of files permitted to use `supabaseAdmin`. Creating `src/lib/xpService.ts` requires adding it to both:
1. The `allowedFiles` array in the "supabaseAdmin exists only in expected files" test
2. No change needed to the routes test (xpService is in `lib/`, not `routes/`)

```typescript
// architecture.test.ts — add to allowedFiles array:
path.join(BACKEND_SRC, 'lib/xpService.ts'),
```

### Pattern 9: env.ts Extension

The three service keys must be added to the Zod env schema in `src/lib/env.ts`:

```typescript
// Add to envSchema in src/lib/env.ts:
QUEST_SERVICE_KEY: z.string().min(1),
TRIVIA_SERVICE_KEY: z.string().min(1),
ADMIN_SERVICE_KEY: z.string().min(1),
```

These are required (not optional) since the service key auth middleware must compare against them. If they are `.optional()`, the middleware can't distinguish "key not configured" from "key not provided".

### Pattern 10: Route Registration in index.ts

```typescript
// src/index.ts — add after gemsRouter:
import xpRouter from './routes/xp.js';
app.use('/api/xp', xpRouter);
```

### Anti-Patterns to Avoid

- **Direct `supabaseAdmin` in route handler:** The architecture enforcement test bans this. Always delegate to `xpService.ts`.
- **`/:userId` route before `/me/history`:** Express will match "me" as a userId. Register the literal path first.
- **Calling `award_xp` via `supabaseAdmin.rpc()` with typed generics:** The XP RPC is not in `database.types.ts` yet. Use `adminRpc('award_xp', params)` instead — this bypasses the type union constraint on `.rpc()`.
- **Spreading DB rows into responses:** The explicit whitelist pattern is mandatory. Never `res.json(data[0])`. Always build a typed response object.
- **Returning 422 for missing service key:** The codebase returns 401 for missing/invalid authentication credentials. Service key is a credential. Use 401.
- **Treating `data` from `RETURNS TABLE` RPC as a single object:** It's an array. Access `data[0]`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| XP idempotency deduplication | Custom Redis or JS-level key check | `award_xp` RPC's built-in idempotency | DB has UNIQUE constraint + pre-check as atomic backstop |
| Level arithmetic in TypeScript | Duplicate tier threshold constants | `connect.calculate_level` via `adminRpc` | Single source of truth; RPC is IMMUTABLE/cached |
| Concurrent award serialization | Optimistic locking or JS mutex | `pg_advisory_xact_lock` in `award_xp` | DB-level advisory lock already handles this |
| Source type validation | Hardcoded string checks | Zod `z.enum([...])` schema | Type-safe, consistent with rest of codebase |
| Pagination math | Custom slice/count logic | Supabase `.range(offset, offset + limit - 1)` with `{ count: 'exact' }` | Same pattern as `gemService.getTransactionHistory` |

**Key insight:** The Phase 9 RPC handles all write-path complexity. The TypeScript layer's job is input validation and response shaping only.

---

## Common Pitfalls

### Pitfall 1: Route Order — me/history Before :userId
**What goes wrong:** `GET /api/xp/me/history` never matches; Express resolves "me" as a `userId` and calls the public profile handler, which returns 404 for a non-UUID "me" string.
**Why it happens:** Express param routes match before literal routes if registered first.
**How to avoid:** Register `/me/history` before `/:userId` in `src/routes/xp.ts`. This is documented explicitly in `src/routes/admin.ts` for the same issue.
**Warning signs:** Integration test for `/api/xp/me/history` returns 404.

### Pitfall 2: award_xp Returns Array, Not Object
**What goes wrong:** `data.id` is `undefined`; response is `{ transaction_id: undefined, ... }`.
**Why it happens:** `RETURNS TABLE` in Postgres → Supabase JS returns `data` as an array of row objects.
**How to avoid:** Always access `data[0]` after calling `adminRpc('award_xp', ...)`. Add a null check: if `!data || !data[0]`, throw an internal error.
**Warning signs:** `transaction_id` is `undefined` in the award response.

### Pitfall 3: source Enum Mismatch Between TypeScript and Postgres
**What goes wrong:** TypeScript allows `validation_quest_completion` but the Postgres enum uses different naming; award succeeds in JS layer but the DB raises a constraint error.
**Why it happens:** CONTEXT.md locked the source type names. The Postgres enum in Phase 9 must use the same names.
**How to avoid:** Verify the Phase 9 migration source column is `TEXT NOT NULL` (not a Postgres enum), so the DB backstop is the UNIQUE constraint on `idempotency_key`, not a type check. Looking at migration 029: `source TEXT NOT NULL` — confirmed TEXT, no Postgres enum. The TypeScript enum (Zod) is the primary guard; DB has no enum type for source.
**Warning signs:** 500 error on award with a type complaint.

### Pitfall 4: Architecture Test Fails for xpService.ts
**What goes wrong:** CI fails with "supabaseAdmin found in unexpected files" for `lib/xpService.ts`.
**Why it happens:** `architecture.test.ts` maintains a hardcoded allowlist; new service files must be added manually.
**How to avoid:** Add `path.join(BACKEND_SRC, 'lib/xpService.ts')` to the `allowedFiles` array in `architecture.test.ts` in the same PR as creating the file.
**Warning signs:** `architecture.test.ts` second test case fails.

### Pitfall 5: Legacy `xp` Key Collision in /account/me
**What goes wrong:** `connected_profile.xp` returns the legacy integer column instead of the new structured object; XPAPI-04 requirement fails.
**Why it happens:** The existing `GET /me` handler explicitly reads and returns `xp: connected.xp` (the legacy column); adding `xp: { total, level, ... }` alongside it either causes a TS error or overwrites.
**How to avoid:** Remove `xp: connected.xp` from the `connected_profile` object and replace with the new structured `xp: { total: connected.total_xp, level: connected.current_level, xp_in_level: ..., xp_to_next_level: ... }`. The legacy column is explicitly scheduled for removal in Phase 10 per migration 029 comments.
**Warning signs:** `connected_profile.xp` is an integer, not an object, in the response.

### Pitfall 6: Non-Connected userId on Award → Wrong Error Code
**What goes wrong:** Calling `award_xp` for a user with no `connected_profiles` row raises a Postgres exception: `'User X has no connected_profiles row. Cannot award XP.'`. If the route doesn't inspect the error message, it returns 500.
**Why it happens:** `award_xp` raises the exception with RAISE EXCEPTION in step 4. Supabase JS surfaces it as `error.message`.
**How to avoid:** In `xpService.awardXp`, catch the error and check `error.message.includes('no connected_profiles row')` — return 404 to the route. This mirrors how `gemService.getBalance` maps `PGRST116` to `PROFILE_NOT_FOUND`.
**Warning signs:** Service call for non-Connected user returns 500 instead of 404.

### Pitfall 7: Service Key Env Vars Not in env.ts Schema
**What goes wrong:** App starts but service key comparison fails because `env.QUEST_SERVICE_KEY` is `undefined`.
**Why it happens:** New env vars must be registered in the Zod schema in `src/lib/env.ts`; unregistered vars are stripped by the `envSchema.safeParse(process.env)`.
**How to avoid:** Add `QUEST_SERVICE_KEY`, `TRIVIA_SERVICE_KEY`, `ADMIN_SERVICE_KEY` to `envSchema` in `env.ts` before implementing the middleware. Add them as `.min(1)` (required) not `.optional()`.
**Warning signs:** All service-key authenticated requests return 401 even with valid key.

---

## Code Examples

### Calling award_xp via adminRpc (verified against migration 030 signature)
```typescript
// Source: supabase/migrations/20260304000030_phase9_xp_rpcs.sql
// RPC signature: award_xp(UUID, TEXT, INT, TEXT, JSONB DEFAULT NULL)
// Returns TABLE with columns: id, user_id, source, amount, metadata, idempotency_key,
//   created_at, total_xp, current_level, xp_in_level, xp_to_next_level, is_duplicate

const { data, error } = await adminRpc('award_xp', {
  p_user_id: userId,
  p_source: source,
  p_amount: amount,
  p_idempotency_key: idempotencyKey,
  p_metadata: metadata ?? null,
});
if (error) {
  if (error.message.includes('no connected_profiles row')) {
    throw Object.assign(new Error('User not found or not Connected'), { code: 'NOT_CONNECTED' });
  }
  if (error.message.includes('must be positive')) {
    throw Object.assign(new Error('Amount must be positive'), { code: 'INVALID_AMOUNT' });
  }
  throw new Error(error.message);
}
// data is an array (RETURNS TABLE) — take first row
const row = Array.isArray(data) ? data[0] : data;
```

### Reading XP history (verified against gemService.getTransactionHistory pattern)
```typescript
// Source: src/lib/gemService.ts — getTransactionHistory function
// xp_transactions columns: id, user_id, source, amount, metadata, idempotency_key, created_at

const limit = Math.min(options?.limit ?? 50, 100);
const offset = options?.offset ?? 0;

const { data, count, error } = await supabaseAdmin
  .schema('connect')
  .from('xp_transactions')
  .select('id, source, amount, metadata, created_at', { count: 'exact' })
  .eq('user_id', userId)
  .order('created_at', { ascending: false })
  .range(offset, offset + limit - 1);

if (error) throw new Error(error.message);
return { transactions: data ?? [], total: count ?? 0, limit, offset };
```

### Reading public XP profile (verified against connected_profiles_public view)
```typescript
// Source: supabase/migrations/20260304000029_phase9_xp_schema.sql
// connected_profiles_public view includes: total_xp, current_level

const { data: profile, error: profileError } = await supabaseAdmin
  .schema('connect')
  .from('connected_profiles')
  .select('total_xp, current_level')
  .eq('user_id', userId)
  .maybeSingle();

if (profileError) throw new Error(profileError.message);
if (!profile) return null;  // user not found or not Connected

// Get computed level fields
const { data: levelData, error: levelError } = await adminRpc('calculate_level', {
  p_total_xp: profile.total_xp,
});
if (levelError) throw new Error(levelError.message);
const levelRow = Array.isArray(levelData) ? levelData[0] : levelData;
```

### Service key auth middleware (following requireAdmin.ts pattern)
```typescript
// Source: src/middleware/requireAdmin.ts (pattern model)
import { Request, Response, NextFunction } from 'express';
import { env } from '../lib/env.js';

// Built at module load time — env vars are resolved once at startup
const SERVICE_KEY_MAP: Record<string, string[]> = {};
if (env.QUEST_SERVICE_KEY) {
  SERVICE_KEY_MAP[env.QUEST_SERVICE_KEY] = ['validation_quest_completion'];
}
if (env.TRIVIA_SERVICE_KEY) {
  SERVICE_KEY_MAP[env.TRIVIA_SERVICE_KEY] = ['civic_trivia_championship_score'];
}
if (env.ADMIN_SERVICE_KEY) {
  SERVICE_KEY_MAP[env.ADMIN_SERVICE_KEY] = ['admin_gift'];
}

export function requireServiceKey(req: Request, res: Response, next: NextFunction): void {
  const key = req.headers['x-service-key'] as string | undefined;
  if (!key || !SERVICE_KEY_MAP[key]) {
    res.status(401).json({ error: 'Missing or invalid X-Service-Key' });
    return;
  }
  (req as ServiceKeyRequest).permittedSources = SERVICE_KEY_MAP[key];
  next();
}
```

### Zod source enum (locked values from CONTEXT.md)
```typescript
// Source: 10-CONTEXT.md — locked decision
export const XP_SOURCES = ['validation_quest_completion', 'civic_trivia_championship_score', 'admin_gift'] as const;
export type XpSource = typeof XP_SOURCES[number];

const AwardXpBodySchema = z.object({
  user_id: z.string().uuid(),
  source: z.enum(XP_SOURCES),
  amount: z.number().int().positive(),
  idempotency_key: z.string().min(1).max(255),
  metadata: z.record(z.unknown()).optional(),
});
```

### Integration test structure (following health.test.ts pattern)
```typescript
// Source: tests/integration/health.test.ts (pattern model)
import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';

process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-role-key';
process.env['DATABASE_URL'] = 'postgresql://postgres:password@localhost:5432/postgres';
process.env['QUEST_SERVICE_KEY'] = 'test-quest-key';
process.env['TRIVIA_SERVICE_KEY'] = 'test-trivia-key';
process.env['ADMIN_SERVICE_KEY'] = 'test-admin-key';

let app: Express;
beforeAll(async () => {
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Legacy `xp` integer on connected_profiles | `total_xp` BIGINT + `current_level` INT + computed `xp_in_level`/`xp_to_next_level` | Phase 9 (2026-03-04) | Legacy column still exists but Phase 10 replaces it in API responses |
| No XP ledger | `connect.xp_transactions` append-only with idempotency_key | Phase 9 (2026-03-04) | Phase 10 reads from this table |
| No level system | `connect.calculate_level(BIGINT)` IMMUTABLE SQL function | Phase 9 (2026-03-04) | Phase 10 calls this for computed level fields |

**Deprecated/outdated:**
- `connected_profiles.xp`: Legacy integer column from Phase 6 placeholder. Phase 10 removes it from API surface (replace with structured `xp` object using `total_xp`/`current_level`). Column remains in DB until explicit migration removes it.

---

## Open Questions

1. **`supabase gen types` status**
   - What we know: Phase 9 added `xp_transactions` table, `total_xp`/`current_level` columns, `award_xp` and `calculate_level` functions. `database.types.ts` has not been regenerated since Phase 9.
   - What's unclear: Whether `database.types.ts` reflects Phase 9 changes. The `adminRpc` helper bypasses type checking for RPCs, so this is not a blocker for `award_xp` or `calculate_level` calls. Table queries via `supabaseAdmin.schema('connect').from('xp_transactions')` may produce untyped results.
   - Recommendation: Run `supabase gen types typescript --local > backend/src/types/database.types.ts` as the first task of Phase 10 (noted as pending in Phase 9 `additional_context`). If Docker is unavailable, use `as unknown as` type assertions for new column reads and document this as a known debt.

2. **`GET /account/me` xp_in_level/xp_to_next_level — extra DB call**
   - What we know: These fields are computed, not stored. Getting them requires calling `calculate_level(total_xp)`.
   - What's unclear: Whether to call `calculate_level` inline in `account.ts` (adds one adminRpc call per `/me` request) or derive it in TypeScript using duplicated tier constants.
   - Recommendation: Call `adminRpc('calculate_level', { p_total_xp: connected.total_xp })` within the `/me` handler when `connected` is non-null. Single source of truth; no duplicated tier arithmetic in TypeScript. The DB function is IMMUTABLE so Postgres may cache it.

3. **userId validation on `POST /api/xp/award` — pre-check vs RPC error**
   - What we know: `award_xp` raises `RAISE EXCEPTION 'User X has no connected_profiles row'` if the user doesn't exist or isn't Connected.
   - What's unclear: Whether to pre-validate `userId` exists and is Connected before calling `award_xp`, or let the RPC error surface.
   - Recommendation: Let `award_xp` raise the exception, catch it in `xpService.awardXp`, and map it to a 404 response. This avoids an extra DB query on the happy path. HTTP code: **404** ("User not found or not Connected tier") per CONTEXT.md Claude's Discretion guidance.

---

## Sources

### Primary (HIGH confidence)
- `supabase/migrations/20260304000030_phase9_xp_rpcs.sql` — exact RPC signature, RETURNS TABLE columns, advisory lock pattern, GRANT statements
- `supabase/migrations/20260304000029_phase9_xp_schema.sql` — xp_transactions columns, connected_profiles additions, view definition
- `backend/src/lib/gemService.ts` — pagination pattern with `{ count: 'exact' }` and `.range()`, service module structure
- `backend/src/routes/gems.ts` — Zod validation, 422 responses, route structure, service delegation pattern
- `backend/src/middleware/auth.ts` — 401 for missing credentials pattern, `AuthenticatedRequest` interface extension pattern
- `backend/src/middleware/requireAdmin.ts` — middleware structure for non-JWT auth checks, 403 pattern
- `backend/src/routes/account.ts` — GET /me handler, `connected_profile` object construction, existing `xp` key
- `backend/src/routes/admin.ts` — route ordering comment for literal vs param segments
- `backend/src/lib/supabase.ts` — `adminRpc` function signature and purpose
- `backend/src/lib/env.ts` — Zod env schema, how to add new required vars
- `tests/integration/architecture.test.ts` — hardcoded `allowedFiles` array that must include xpService.ts
- `.planning/phases/09-xp-schema-core/09-VERIFICATION.md` — Phase 9 completion status and what was actually built
- `.planning/phases/10-xp-api/10-CONTEXT.md` — locked decisions (source names, HTTP shape, service key mapping)

### Secondary (MEDIUM confidence)
- `tests/integration/health.test.ts` — test file boilerplate and env var setup pattern (consistent across all test files reviewed)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all existing
- Architecture: HIGH — verified against actual source files; all patterns read directly from codebase
- Pitfalls: HIGH — identified from reading actual implementation files and cross-referencing them against the phase requirements
- RPC mapping: HIGH — verified against the exact SQL in migration 030

**Research date:** 2026-03-04
**Valid until:** 2026-04-03 (stable codebase, no fast-moving dependencies)
