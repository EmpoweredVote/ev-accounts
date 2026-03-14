# Phase 22: Multi-Currency Gem System - Research

**Researched:** 2026-03-14
**Domain:** Gem ledger extension — multi-currency schema, idempotent service-to-service award endpoint, API response migration
**Confidence:** HIGH (all findings verified against live codebase)

## Summary

Phase 22 extends an already-partially-built multi-currency gem system. Migration 019 (Phase 6) already added `gem_type TEXT CHECK IN ('red','blue','yellow')` to `gem_transactions` and three denormalized balance columns (`gem_balance_yellow`, `gem_balance_blue`, `gem_balance_red`) to `connected_profiles`. The `credit_gems` and `debit_gems` SECURITY DEFINER RPCs already accept gem_type. The existing `gemService.ts` already reads the three per-type balances.

The work in Phase 22 is:
1. Add `idempotency_key` column to `gem_transactions` so award dedup works at the DB layer (parallel to the XP system's `award_xp` RPC pattern).
2. Update `credit_gems` RPC (or create `award_gems`) to check/store idempotency_key atomically.
3. Wire a new `POST /api/gems/award` endpoint with `Authorization: Bearer <service-key>` auth (NOT the existing `X-Service-Key` pattern).
4. Add `GEMS_SERVICE_KEYS` env var parsing with per-key gem_type permissions.
5. Update `GET /api/account/me` and `PATCH /api/account/me` to return `gems: { yellow, blue, red }` instead of the legacy `gem_balance` integer.
6. Update admin frontend `AccountDetailPage.tsx` to display three labeled balances.

**Critical naming discrepancy discovered:** The CONTEXT.md spec says the database columns will be named `yellow_gem_balance`, `blue_gem_balance`, `red_gem_balance`. The EXISTING columns (from migration 019) are named `gem_balance_yellow`, `gem_balance_blue`, `gem_balance_red`. The planner must resolve which convention to use. The existing `gemService.ts` and `database.types.ts` already use `gem_balance_yellow/blue/red`. Using that existing convention eliminates a schema rename migration. CONTEXT.md's column naming appears to be aspirational — the planner should use the existing column names.

**Primary recommendation:** Extend the existing `credit_gems` RPC or create a new `award_gems` RPC that adds idempotency_key support. Build a new `requireGemServiceKey` middleware that parses `Authorization: Bearer <service-key>` against `GEMS_SERVICE_KEYS` JSON map. The rest of the work is wiring and display updates.

## Standard Stack

No new libraries required for this phase. All dependencies are already installed.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `zod` | already installed | Request body validation | Project standard |
| `express` | 4.x | Route handling | Project standard |
| `@supabase/supabase-js` | already installed | RPC calls to credit_gems | Project standard |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `vitest` + `supertest` | already installed | Integration tests | All endpoint tests in this project |

**Installation:** No new packages needed.

## Architecture Patterns

### Recommended Project Structure

Phase 22 touches these existing files plus adds new ones:

```
backend/src/
├── lib/
│   └── gemService.ts          # add awardGems() function (new export)
├── middleware/
│   └── gemServiceKeyAuth.ts   # NEW — Authorization: Bearer <service-key> parser
├── routes/
│   └── gems.ts                # add POST /award route
├── lib/
│   └── env.ts                 # add GEMS_SERVICE_KEYS env var
└── routes/
    └── account.ts             # replace gem_balance with gems: {yellow,blue,red}

supabase/migrations/
└── 20260314000034_phase22_gems_idempotency.sql  # add idempotency_key col + update credit_gems RPC

admin/src/pages/admin/
└── AccountDetailPage.tsx      # replace gem_balance with three labeled values

tests/integration/
└── gems.test.ts               # NEW — POST /api/gems/award validation tests
```

### Pattern 1: New Middleware — `gemServiceKeyAuth.ts`

The CONTEXT.md requires `Authorization: Bearer <service-key>` (not `X-Service-Key`). The existing `serviceKeyAuth.ts` uses `X-Service-Key` and is used only by the XP award endpoint. A new, separate middleware must be written for gems that:
- Reads `Authorization: Bearer <key>` from the header
- Rejects regular user JWTs (which are also Bearer tokens) with 401
- Parses `GEMS_SERVICE_KEYS` JSON map at startup
- Attaches `permittedGemTypes: string[]` to the request

**Distinguishing service keys from user JWTs:** Service keys are opaque strings. User JWTs are dot-separated Base64 segments. The middleware must NOT call `jwtVerify` — it should just do a direct map lookup. A valid JWT would fail the map lookup (not present as a key) and return 401, which is the correct behavior.

```typescript
// Source: verified against existing serviceKeyAuth.ts and auth.ts patterns
export interface GemServiceKeyRequest extends Request {
  permittedGemTypes: string[];
  serviceKeyId: string;  // for logging
}

// Parsed ONCE at module load (fails fast at startup if malformed)
const GEM_KEY_MAP: Record<string, string[]> = parseGemServiceKeys(env.GEMS_SERVICE_KEYS);

export function requireGemServiceKey(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid Authorization header' });
    return;
  }
  const key = authHeader.slice(7);
  const permitted = GEM_KEY_MAP[key];
  if (!permitted) {
    res.status(401).json({ error: 'Missing or invalid Authorization header' });
    return;
  }
  (req as GemServiceKeyRequest).permittedGemTypes = permitted;
  next();
}
```

**Why 401 for both missing and wrong key:** Matches the existing `requireServiceKey` pattern (XP) and `requireAuth` pattern. The CONTEXT says "regular user JWTs rejected with 401" — this is satisfied because valid user JWTs won't be found in the GEM_KEY_MAP.

### Pattern 2: `GEMS_SERVICE_KEYS` Parsing at Startup

Claude's Discretion: parse and validate at startup, `process.exit(1)` if malformed.

```typescript
// Source: verified against env.ts pattern (GOOGLE_MAPS_API_KEY exits on missing)
function parseGemServiceKeys(raw: string | undefined): Record<string, string[]> {
  if (!raw) return {};  // Optional for dev/test environments

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    console.error('[startup] GEMS_SERVICE_KEYS is not valid JSON');
    process.exit(1);
  }

  // Validate structure: object with string keys, array-of-string values
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    console.error('[startup] GEMS_SERVICE_KEYS must be a JSON object');
    process.exit(1);
  }

  const VALID_GEM_TYPES = new Set(['yellow', 'blue', 'red']);
  const result: Record<string, string[]> = {};

  for (const [key, types] of Object.entries(parsed as Record<string, unknown>)) {
    if (!Array.isArray(types) || !types.every(t => typeof t === 'string' && VALID_GEM_TYPES.has(t))) {
      console.error(`[startup] GEMS_SERVICE_KEYS: key "${key}" has invalid gem_type array`);
      process.exit(1);
    }
    result[key] = types as string[];
  }

  return result;
}
```

**Important:** `GEMS_SERVICE_KEYS` should be `z.string().optional()` in the Zod schema — not required. It being absent = no service keys configured = all award attempts return 401. This is the right dev/test behavior (tests can set it via `process.env`).

### Pattern 3: `award_gems` RPC — Idempotent Credit

The new RPC mirrors `award_xp` (migration 030) but calls into the existing `credit_gems` advisory lock pattern. Claude's Discretion: whether to extend `credit_gems` in-place or create a separate `award_gems` function.

**Recommendation: Create a new `award_gems` RPC.** Reasons:
- `credit_gems` is called from multiple places (cron stipends, future debits); adding idempotency_key there would be a breaking API change (new required parameter)
- `award_gems` can be the service-to-service entry point; `credit_gems` remains the internal (no idempotency) entry point
- Mirrors how `award_xp` is a separate function from the lower-level XP credit operations

```sql
-- Source: verified against award_xp pattern in migration 030
CREATE OR REPLACE FUNCTION connect.award_gems(
  p_user_id         UUID,
  p_gem_type        TEXT,
  p_amount          INTEGER,
  p_transaction_type TEXT,
  p_idempotency_key TEXT,
  p_source_ref      UUID DEFAULT NULL
)
RETURNS TABLE (
  transaction_id    UUID,
  user_id           UUID,
  gem_type          TEXT,
  amount            INTEGER,
  new_balance       INTEGER,
  created_at        TIMESTAMPTZ,
  is_duplicate      BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_existing   connect.gem_transactions;
  v_new_balance INTEGER;
  v_result     connect.gem_transactions;
BEGIN
  -- Validate gem_type (prevents column-name injection in EXECUTE format)
  IF p_gem_type NOT IN ('red', 'blue', 'yellow') THEN
    RAISE EXCEPTION 'Invalid gem_type: %. Must be red, blue, or yellow.', p_gem_type;
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Award amount must be positive. Got: %', p_amount;
  END IF;

  -- Advisory lock: serialize concurrent gem operations for this user
  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Idempotency check: if key already processed, return original with is_duplicate = TRUE
  SELECT * INTO v_existing
    FROM connect.gem_transactions gt
    WHERE gt.idempotency_key = p_idempotency_key;

  IF FOUND THEN
    -- Read current balance for the response
    EXECUTE format(
      'SELECT gem_balance_%s FROM connect.connected_profiles WHERE user_id = $1',
      p_gem_type
    ) INTO v_new_balance USING p_user_id;

    RETURN QUERY SELECT
      v_existing.id,
      v_existing.user_id,
      v_existing.gem_type,
      v_existing.amount,
      v_new_balance,
      v_existing.created_at,
      TRUE;
    RETURN;
  END IF;

  -- Not duplicate: read current balance with FOR UPDATE
  EXECUTE format(
    'SELECT gem_balance_%s FROM connect.connected_profiles WHERE user_id = $1 FOR UPDATE',
    p_gem_type
  ) INTO v_new_balance USING p_user_id;

  IF v_new_balance IS NULL THEN
    RAISE EXCEPTION 'User % has no connected_profiles row. Cannot award gems.', p_user_id;
  END IF;

  v_new_balance := v_new_balance + p_amount;

  -- Update denormalized balance
  EXECUTE format(
    'UPDATE connect.connected_profiles SET gem_balance_%s = $1, updated_at = now() WHERE user_id = $2',
    p_gem_type
  ) USING v_new_balance, p_user_id;

  -- Insert ledger row WITH idempotency_key
  INSERT INTO connect.gem_transactions (
    user_id, gem_type, amount, transaction_type, reference_id, balance_after, idempotency_key
  )
  VALUES (p_user_id, p_gem_type, p_amount, p_transaction_type, p_source_ref, v_new_balance, p_idempotency_key)
  RETURNING * INTO v_result;

  RETURN QUERY SELECT
    v_result.id,
    v_result.user_id,
    v_result.gem_type,
    v_result.amount,
    v_new_balance,
    v_result.created_at,
    FALSE;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

### Pattern 4: `awardGems()` in gemService.ts

New export alongside existing `creditGems`, `debitGems`, `getBalance`:

```typescript
// Source: mirrors awardXp() pattern in xpService.ts
export interface AwardGemsResult {
  transaction_id: string;
  user_id: string;
  gem_type: GemType;
  amount: number;
  new_balance: number;
  created_at: string;
  is_duplicate: boolean;
}

export async function awardGems(
  userId: string,
  gemType: GemType,
  amount: number,
  idempotencyKey: string,
  transactionType: string = 'service_award'
): Promise<AwardGemsResult> {
  const { data, error } = await supabaseAdmin.schema('connect').rpc('award_gems', {
    p_user_id: userId,
    p_gem_type: gemType,
    p_amount: amount,
    p_idempotency_key: idempotencyKey,
    p_transaction_type: transactionType,
  });

  if (error) {
    if (error.message?.includes('no connected_profiles row')) {
      throw Object.assign(new Error('User has no connected profile'), { code: 'NOT_CONNECTED' });
    }
    throw new Error(error.message ?? 'award_gems RPC failed');
  }

  // award_gems uses RETURNS TABLE — data is an array
  const row = Array.isArray(data) ? data[0] : data;
  if (!row) throw new Error('[gemService] award_gems returned no rows');

  return {
    transaction_id: row.transaction_id,
    user_id: row.user_id,
    gem_type: row.gem_type as GemType,
    amount: row.amount,
    new_balance: row.new_balance,
    created_at: row.created_at,
    is_duplicate: row.is_duplicate,
  };
}
```

### Pattern 5: account.ts — gems Object in /me Response

The current code selects `gem_balance` (legacy single int). Change to select the three per-type columns and build a structured object.

**Both GET and PATCH /me need the same update.** Current select string:
```
'id, display_name, account_standing, verification_status, tolerance_rating, total_xp, gem_balance, completed_onboarding, location_consent, created_at'
```

New select string (GET):
```
'id, display_name, account_standing, verification_status, tolerance_rating, total_xp, gem_balance_yellow, gem_balance_blue, gem_balance_red, completed_onboarding, location_consent, created_at'
```

Response structure change in `connected_profile`:
```typescript
// BEFORE:
meResponse.connected_profile = {
  gem_balance: connected.gem_balance,
  // ...
};

// AFTER (Phase 22):
meResponse.connected_profile = {
  gems: {
    yellow: connected.gem_balance_yellow,
    blue: connected.gem_balance_blue,
    red: connected.gem_balance_red,
  },
  // ... (gem_balance removed)
};
```

**PATCH /me has a duplicate connected_profile block** that also selects `gem_balance` — both blocks must be updated.

### Pattern 6: Admin Tool — Three Labeled Balances

The `AccountDetailPage.tsx` shows gem balance in the connected_profile block. The `admin_get_account_detail` RPC uses `SELECT *` from `connected_profiles`, so it already returns `gem_balance_yellow/blue/red` in the JSONB payload — no migration of the admin RPC required.

Changes needed in `AccountDetailPage.tsx`:
1. Update `ConnectedProfile` interface: replace `gem_balance: number` with `gem_balance_yellow: number; gem_balance_blue: number; gem_balance_red: number`
2. Find where `gem_balance` is rendered and replace with inline display:

```tsx
{/* Source: AccountDetailPage.tsx — gem balance display block */}
<div className="flex gap-4 text-sm text-gray-600 mt-1">
  <span>Yellow: {account.connected_profile.gem_balance_yellow}</span>
  <span>Blue: {account.connected_profile.gem_balance_blue}</span>
  <span>Red: {account.connected_profile.gem_balance_red}</span>
</div>
```

**Note:** The existing `AccountDetailPage.tsx` does NOT currently display gem balance at all in the rendered JSX — only the `ConnectedProfile` TypeScript interface declares `gem_balance: number`, but it is never rendered. Phase 22 adds the display of all three values. Search the file for any rendering of `gem_balance` before assuming where to add it.

### Pattern 7: `database.types.ts` Manual Update

Per project convention, `database.types.ts` must be manually updated when migrations add columns. Phase 22 migration adds `idempotency_key TEXT UNIQUE` to `gem_transactions`. Update `gem_transactions.Row`, `Insert`, and `Update` types:

```typescript
// Add to gem_transactions Row/Insert/Update:
idempotency_key: string | null  // nullable for old rows, required for new award_gems inserts
```

The three balance columns (`gem_balance_yellow/blue/red`) are already in `database.types.ts` as `number` with defaults. The CONTEXT decision that they are `number` (not `number | null`) is already correct for the current schema.

### Anti-Patterns to Avoid

- **Reusing `requireServiceKey` middleware for gems:** The XP middleware reads `X-Service-Key`; gems use `Authorization: Bearer`. Different headers, different maps, different permitted-type semantics. Separate files.
- **Extending `credit_gems` with idempotency_key parameter:** This would break the existing cron call path (no idempotency_key available there). Create `award_gems` as a new, separate function.
- **Spreading the DB row into the gems response:** The `connected_profiles` row contains `tolerance_rating` and `legal_name` — always use explicit field selection. Never spread the row object.
- **Adding `idempotency_key` as NOT NULL DEFAULT NULL on gem_transactions:** The constraint must be `UNIQUE` but nullable (existing rows have no key; only `award_gems` inserts with a key). Use `UNIQUE NULLS NOT DISTINCT` or standard unique index — Postgres 15+ handles multiple NULLs in a unique index via `NULLS NOT DISTINCT`. Supabase PG 17.4 supports this.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Advisory lock for concurrent gem writes | Custom application-level lock | `pg_advisory_xact_lock(hashtext(user_id::text))` in the RPC | Already established in credit_gems; automatically released on COMMIT/ROLLBACK |
| Idempotency dedup | Redis TTL-based dedup | Postgres unique index on idempotency_key in gem_transactions | Same pattern as award_xp; permanent, no TTL — matches CONTEXT decision |
| Service key validation | Custom JWT parsing | Direct map lookup against parsed GEMS_SERVICE_KEYS | Service keys are opaque strings, not JWTs — no verification needed |
| JSON env var validation | Runtime errors | Zod-adjacent startup validation with process.exit(1) | Matches GOOGLE_MAPS_API_KEY startup validation pattern |

**Key insight:** The Postgres advisory lock + idempotency_key pattern is already proven in this codebase (award_xp). Copy that pattern exactly rather than inventing a new approach.

## Common Pitfalls

### Pitfall 1: Column Naming Convention Mismatch

**What goes wrong:** CONTEXT.md spec says `yellow_gem_balance` but existing migration 019 created `gem_balance_yellow`. If you write a migration that adds `yellow_gem_balance` columns, you now have BOTH old and new columns and a broken `gemService.ts` that reads the old names.
**Why it happens:** CONTEXT.md was written aspirationally without checking the live schema.
**How to avoid:** Use the existing `gem_balance_yellow/blue/red` convention throughout. Do NOT create a column-rename migration.
**Warning signs:** If you see `yellow_gem_balance` in any new code, stop and check migration 019.

### Pitfall 2: Forgetting PATCH /me Has a Duplicate connected_profile Block

**What goes wrong:** GET /me is updated to return `gems: {...}` but PATCH /me still returns `gem_balance` (it has an identical second connected_profile block at the bottom of the route handler).
**Why it happens:** account.ts has two near-identical response-building blocks for GET and PATCH — easy to update only one.
**How to avoid:** Search for all occurrences of `gem_balance` in account.ts before and after making changes. There are two: lines ~133 (GET) and ~379 (PATCH).
**Warning signs:** The GET test passes but the PATCH still returns `gem_balance`.

### Pitfall 3: `idempotency_key` UNIQUE Constraint Behavior with NULLs

**What goes wrong:** Adding `idempotency_key TEXT UNIQUE` to gem_transactions then inserting two NULL values (existing rows, credit_gems inserts) violates the unique constraint in standard Postgres.
**Why it happens:** Standard UNIQUE constraints treat NULL as distinct in standard SQL — but standard Postgres does NOT, which means two NULL values DO violate a standard UNIQUE constraint by default.
**How to avoid:** Use `CREATE UNIQUE INDEX idx_gem_transactions_idempotency_key ON connect.gem_transactions (idempotency_key) WHERE idempotency_key IS NOT NULL` — a partial unique index that only enforces uniqueness on non-NULL values.
**Warning signs:** Migration fails with "duplicate key value violates unique constraint" immediately on apply.

### Pitfall 4: Bearer Token Ambiguity in `requireGemServiceKey`

**What goes wrong:** A user sends their Supabase JWT in `Authorization: Bearer <jwt>`. The middleware tries to parse it as a service key, fails to find it in the map, and... returns the wrong error or behaves unexpectedly.
**Why it happens:** Both user JWTs and service keys use `Bearer` prefix.
**How to avoid:** The middleware should do a simple map lookup — if the token is not in the map, return 401 (same as XP's requireServiceKey). A valid JWT won't be in the GEMS_SERVICE_KEYS map. No JWT verification step needed.
**Warning signs:** Tests expecting 401 for user JWT get 500 or wrong error codes.

### Pitfall 5: Not Adding `idempotency_key` to the `award_gems` INSERT

**What goes wrong:** The `award_gems` RPC inserts a gem_transactions row but forgets to set `idempotency_key`, so the unique index check in the idempotency pre-check never matches future duplicates.
**Why it happens:** The INSERT into gem_transactions has many columns — idempotency_key is easily omitted.
**How to avoid:** The INSERT in `award_gems` must explicitly include `idempotency_key = p_idempotency_key`.
**Warning signs:** Duplicate awards not detected; balance grows on every call with the same key.

### Pitfall 6: `account.ts` Still Selecting `gem_balance`

**What goes wrong:** The SELECT string for connected_profiles still includes `gem_balance` and the connected_profile TypeScript type includes it. Code works but returns old shape.
**Why it happens:** `gem_balance` is a valid column (per CONTEXT: don't drop it from DB) so no error is thrown.
**How to avoid:** Remove `gem_balance` from the SELECT string entirely in both GET and PATCH /me. Replace with the three per-type columns.
**Warning signs:** Response has `gem_balance: 0` at root or nested instead of `gems: {yellow, blue, red}`.

### Pitfall 7: ALLOWED_ME_KEYS Test Must Be Updated

**What goes wrong:** The `account.test.ts` has an `ALLOWED_ME_KEYS` set and optionally validates response shape. If the test checks that `gem_balance` is absent at root level, that test would still pass. But if any test validates the `connected_profile` shape, it may fail.
**Why it happens:** The test file has comment-documented expectations about what fields appear.
**How to avoid:** Review `account.test.ts` for any assertions about `gem_balance` or the connected_profile structure and update them.
**Warning signs:** Existing tests fail after account.ts changes.

## Code Examples

### Migration: Add idempotency_key to gem_transactions

```sql
-- Source: verified against existing migration 019 + award_xp pattern in migration 030

BEGIN;

-- Add idempotency_key column (nullable — existing rows have no key)
ALTER TABLE connect.gem_transactions
  ADD COLUMN IF NOT EXISTS idempotency_key TEXT;

-- Partial unique index: only enforces uniqueness on non-NULL values
-- (existing rows and credit_gems inserts remain NULL; only award_gems sets this)
CREATE UNIQUE INDEX IF NOT EXISTS idx_gem_transactions_idempotency_key
  ON connect.gem_transactions (idempotency_key)
  WHERE idempotency_key IS NOT NULL;

COMMIT;
```

### env.ts Addition

```typescript
// Source: mirrors GOOGLE_MAPS_API_KEY pattern in env.ts
GEMS_SERVICE_KEYS: z.string().optional(),  // JSON map: {"key": ["yellow","red"]}
```

The GEMS_SERVICE_KEYS value is validated by the middleware at module load time (not at Zod schema level, since Zod can't validate arbitrary JSON structure). Being optional means dev/test environments without gem keys don't fail at startup — they just return 401 for all award attempts.

### Integration Test Pattern (Gem Award Validation)

```typescript
// Source: mirrors xp.test.ts pattern exactly
process.env['GEMS_SERVICE_KEYS'] = JSON.stringify({
  'test-ctc-key': ['yellow'],
  'test-vq-key': ['yellow', 'red'],
});

it('returns 401 when Authorization header is missing', async () => {
  const res = await request(app).post('/api/gems/award').send({ ... });
  expect(res.status).toBe(401);
});

it('returns 401 when Authorization header has invalid key', async () => {
  const res = await request(app)
    .post('/api/gems/award')
    .set('Authorization', 'Bearer not-a-valid-key')
    .send({ ... });
  expect(res.status).toBe(401);
});

it('returns 422 when gem_type is not permitted for this key', async () => {
  const res = await request(app)
    .post('/api/gems/award')
    .set('Authorization', 'Bearer test-ctc-key')
    .send({ user_id: '...uuid...', gem_type: 'red', amount: 10, idempotency_key: 'key-001' });
  expect(res.status).toBe(422);
  expect(res.body).toHaveProperty('error', 'FORBIDDEN_GEM_TYPE');
  expect(res.body).toHaveProperty('permitted', ['yellow']);
});

it('returns 422 when idempotency_key is missing', async () => {
  const res = await request(app)
    .post('/api/gems/award')
    .set('Authorization', 'Bearer test-ctc-key')
    .send({ user_id: '...uuid...', gem_type: 'yellow', amount: 10 });
  expect(res.status).toBe(422);
  expect(res.body).toHaveProperty('code', 'VALIDATION_ERROR');
});
```

**Note:** These tests run without a live DB (same as xp.test.ts). The balance-always-0 bug fix (GEM-06) requires a live integration test — document as a manual test or mark for live environment.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single `gem_balance` integer on `GET /me` | `gems: { yellow, blue, red }` object | Phase 22 | CTC and VQ must update their response parsing |
| Direct `connect.credit_gems` RPC call from CTC | `POST /api/gems/award` service endpoint | Phase 22 | CTC migrates off direct RPC; goes through API |
| `gem_balance` field in admin connected_profile | Three labeled values (yellow/blue/red) | Phase 22 | Admin tool updated |

**Deprecated/outdated:**
- `gem_balance` (legacy single total): column stays in DB but is no longer selected or returned in any API response. Will be a dead column post-Phase 22.
- Direct CTC calls to `connect.credit_gems` via Supabase service role: replaced by `POST /api/gems/award`.

## Open Questions

1. **Does `admin_get_account_detail` RPC need a migration?**
   - What we know: It uses `SELECT * FROM connect.connected_profiles` — which already returns `gem_balance_yellow/blue/red`. The admin frontend `AccountDetailPage.tsx` already has `gem_balance: number` in its TypeScript interface but the JSX does NOT currently render it anywhere visible.
   - What's unclear: Whether the admin backend route's TypeScript types need explicit update (they use `Record<string, unknown>` which is flexible) or if only the frontend interface matters.
   - Recommendation: No RPC migration needed. Only frontend interface + rendering update.

2. **Where does `gem_balance` currently appear in `AccountDetailPage.tsx`?**
   - What we know: It's declared in the `ConnectedProfile` TypeScript interface (line 26). The JSX does not render it in any `div`/`span` — confirmed by grep showing no JSX references.
   - What's unclear: Whether the CONTEXT's "same visual weight as previous single balance" implies there WAS a display that needs replacing or this is a new display.
   - Recommendation: Phase 22 adds the gem balance display for the first time in the admin tool. It was previously declared in the interface but never shown.

3. **Test isolation for `GEMS_SERVICE_KEYS`**
   - What we know: `xp.test.ts` sets `QUEST_SERVICE_KEY` and `TRIVIA_SERVICE_KEY` in `process.env` before importing the app. The gem middleware parses `GEMS_SERVICE_KEYS` at module load time.
   - What's unclear: Whether the existing test files will conflict if `GEMS_SERVICE_KEYS` is parsed at module load but not set in those tests' env setup.
   - Recommendation: Make `GEMS_SERVICE_KEYS` optional (`z.string().optional()`) in env.ts. When absent or empty JSON, the parsed map is `{}` and all award attempts return 401. Set the test value in `gems.test.ts` before importing the app.

## Sources

### Primary (HIGH confidence)
- `/c/EV-Accounts/supabase/migrations/20260227000019_phase6_gems_schema.sql` — existing column names (`gem_balance_yellow/blue/red`), gem_type TEXT CHECK constraint
- `/c/EV-Accounts/supabase/migrations/20260227000023_phase6_rpcs.sql` — credit_gems advisory lock pattern, EXECUTE format SQL injection prevention
- `/c/EV-Accounts/supabase/migrations/20260304000030_phase9_xp_rpcs.sql` — award_xp idempotency pattern (RETURNS TABLE, is_duplicate, advisory lock)
- `/c/EV-Accounts/backend/src/lib/gemService.ts` — existing GemType, creditGems, getBalance exports
- `/c/EV-Accounts/backend/src/middleware/serviceKeyAuth.ts` — existing X-Service-Key pattern
- `/c/EV-Accounts/backend/src/middleware/auth.ts` — Authorization: Bearer JWT pattern
- `/c/EV-Accounts/backend/src/routes/account.ts` — current gem_balance selection (lines 60, 133, 322, 379)
- `/c/EV-Accounts/backend/src/lib/env.ts` — startup validation pattern, process.exit(1) on invalid env
- `/c/EV-Accounts/backend/src/lib/xpService.ts` — awardXp service function pattern
- `/c/EV-Accounts/backend/src/routes/xp.ts` — POST /api/xp/award route pattern (SOURCE_NOT_PERMITTED, 422)
- `/c/EV-Accounts/tests/integration/xp.test.ts` — integration test pattern for service-key endpoints
- `/c/EV-Accounts/admin/src/pages/admin/AccountDetailPage.tsx` — ConnectedProfile interface (gem_balance line 26), JSX (no current gem rendering)
- `/c/EV-Accounts/backend/src/types/database.types.ts` — existing column types confirmed

### Secondary (MEDIUM confidence)
- `/c/EV-Accounts/backend/migrations/025_rpc_pool_migration.sql` — `admin_get_account_detail` uses `SELECT *` from connected_profiles, already returns per-type balances

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries, all existing patterns verified
- Architecture: HIGH — all patterns derived from live codebase, not external research
- Pitfalls: HIGH — discovered by reading actual code, not theoretical

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (stable internal codebase patterns)
