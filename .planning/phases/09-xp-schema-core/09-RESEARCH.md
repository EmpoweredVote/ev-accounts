# Phase 9: XP Schema & Core - Research

**Researched:** 2026-03-04
**Domain:** PostgreSQL schema design, SECURITY DEFINER RPCs, append-only ledger patterns, Supabase RLS
**Confidence:** HIGH

## Summary

Phase 9 is a pure database layer — schema migration, RLS policies, and two Postgres functions (`calculate_level` and `award_xp`). There is no Express route work. All decisions are already locked in CONTEXT.md; the research focus is on the exact implementation patterns to follow, drawn directly from the existing gem ledger codebase.

The canonical pattern is fully established in migrations 019 and 023 (`credit_gems`/`debit_gems`). The XP ledger mirrors that pattern almost exactly, with three differences: idempotency key replaces `balance_after`, `source TEXT` replaces `gem_type + transaction_type`, and a standalone `calculate_level` function is needed because level calculation must be callable independently. The gem RPCs never needed to be called standalone — that was simpler.

The primary complexity in Phase 9 is the idempotency silent no-op: `ON CONFLICT DO NOTHING` on `idempotency_key` does not return the original row. A CTE pattern is required to detect and return the existing row when a duplicate key is presented. This is a known PostgreSQL limitation with a standard workaround documented in official sources.

**Primary recommendation:** Implement `award_xp` as a SECURITY DEFINER function with advisory lock + FOR UPDATE + CTE-based idempotency. Structure as two migrations: one for schema (table + ALTERs + RLS + grants), one for functions (calculate_level + award_xp).

---

## Standard Stack

No new npm packages are required for Phase 9. This is a pure SQL migration phase.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| PostgreSQL (Supabase) | 17 (per config.toml) | Schema + RPCs | Already in use |
| Supabase Migrations | Current | Schema versioning | Established pattern |
| `supabaseAdmin.schema('connect').rpc()` | @supabase/ssr | Call RPC from service layer | Proven in gemService.ts |

### No New Dependencies

Phase 9 adds zero new npm packages. All tooling already exists.

**Installation:** None needed.

---

## Architecture Patterns

### Recommended File Structure

Two migration files, following the numbered convention already established:

```
supabase/migrations/
├── 202603XXXXXX029_phase9_xp_schema.sql     # Table, ALTERs, RLS, grants
└── 202603XXXXXX030_phase9_xp_rpcs.sql       # calculate_level + award_xp functions
```

This matches how Phase 6 split gem schema (019) from gem RPCs (023). Separating schema from functions is important: the functions reference the tables, so they must come after.

### Pattern 1: Append-Only Ledger Table (mirrors gem_transactions)

**What:** `connect.xp_transactions` with no UPDATE/DELETE ever. XP is always positive (CHECK constraint enforced). Idempotency key is UNIQUE at the DB level.

**Schema:**
```sql
-- Source: migration pattern from 20260224000005_connect_supporting_tables.sql
CREATE TABLE IF NOT EXISTS connect.xp_transactions (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  source           TEXT        NOT NULL,
  amount           INT         NOT NULL CHECK (amount > 0),
  metadata         JSONB,
  idempotency_key  TEXT        NOT NULL UNIQUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index: user_id + created_at for history queries (reverse chronological)
CREATE INDEX IF NOT EXISTS idx_xp_transactions_user_created
  ON connect.xp_transactions(user_id, created_at DESC);

-- Index: idempotency_key is covered by the UNIQUE constraint (auto-creates index)
-- No additional index needed for idempotency_key.
```

Note: Unlike `gem_transactions`, there is NO `balance_after` column on `xp_transactions`. The total is always derived from `connected_profiles.total_xp` (the denormalized column). This is correct per CONTEXT.md — `last_xp_awarded_at` and balance history are all derivable from the ledger.

### Pattern 2: ALTER connected_profiles (mirrors Phase 6 gem balance columns)

**What:** Add `total_xp BIGINT NOT NULL DEFAULT 0` and `current_level INT NOT NULL DEFAULT 0`.

**The legacy `xp` column:** `connected_profiles` already has an `xp INTEGER NOT NULL DEFAULT 0` column (migration 004, currently exposed in `account.ts`). The new `total_xp` column is DISTINCT from this legacy column. Do NOT rename or drop the existing `xp` column — Phase 10 will handle any account response changes. Phase 9 only adds the new columns.

```sql
-- Source: migration pattern from 20260227000019_phase6_gems_schema.sql
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS total_xp     BIGINT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS current_level INT    NOT NULL DEFAULT 0;
```

### Pattern 3: connected_profiles_public View Update

The public view must be updated to include `total_xp` and `current_level` (mirrors how Phase 6 added gem balance columns to the view). The view is DROP + recreate because new columns need to be added. Re-grant SELECT after drop.

```sql
-- Source: migration pattern from 20260227000019_phase6_gems_schema.sql
DROP VIEW IF EXISTS connect.connected_profiles_public;

CREATE VIEW connect.connected_profiles_public AS
  SELECT
    id,
    user_id,
    display_name,
    account_standing,
    verification_status,
    verification_method,
    verified_region,
    xp,               -- legacy column preserved (Phase 10 will assess)
    total_xp,         -- new v1.1 column
    current_level,    -- new v1.1 column
    gem_balance,
    gem_balance_red,
    gem_balance_blue,
    gem_balance_yellow,
    gem_reserve_cap,
    veracity_rating,
    -- tolerance_rating intentionally OMITTED
    -- legal_name intentionally OMITTED
    -- home_address intentionally OMITTED
    deleted_at,
    created_at,
    updated_at
  FROM connect.connected_profiles
  WHERE deleted_at IS NULL;

GRANT SELECT ON connect.connected_profiles_public TO authenticated;
```

### Pattern 4: RLS for xp_transactions

**What:** Authenticated user reads own rows only. No INSERT/UPDATE/DELETE policy — all writes go through `award_xp` SECURITY DEFINER RPC. Unauthenticated = zero rows (GRANT SELECT to `anon` without any policy).

```sql
-- Source: pattern from 20260224000008_rls_connect.sql (gem_transactions section)
ALTER TABLE connect.xp_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "xp_transactions: owner read"
  ON connect.xp_transactions
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

-- No INSERT policy: all writes go through award_xp SECURITY DEFINER RPC
-- No UPDATE policy: ledger is append-only
-- No DELETE policy: ledger is append-only

-- Grant SELECT to authenticated (for RLS to return 0 rows instead of permission denied for non-owners)
GRANT SELECT ON connect.xp_transactions TO authenticated;

-- Grant SELECT to anon so unauthenticated queries return 0 rows (not permission denied)
-- This mirrors the pattern in migration 012 for connected_profiles
GRANT SELECT ON connect.xp_transactions TO anon;
```

**XPLED-04 requirement says "admin reads all."** The service role (supabaseAdmin) bypasses RLS entirely and can read all rows — no admin-specific policy is needed. This matches how admin access works for gems (no admin policy on gem_transactions either; service role is used).

### Pattern 5: calculate_level SQL Function

**What:** Standalone LANGUAGE sql function (not plpgsql — no procedural logic needed) that takes `total_xp BIGINT` and returns `(level INT, xp_in_level INT, xp_to_next_level INT)`.

Level thresholds (locked):
- Levels 1–3: 2,000 XP each
- Levels 4–9: 3,000 XP each
- Levels 10–29: 4,000 XP each
- Level 30+: 5,000 XP each

**Threshold math:**
- Levels 1–3 cumulative XP at boundary: 2k, 4k, 6k (total: 6,000 XP to complete level 3)
- Levels 4–9 cumulative at boundary: 6k + 3k×6 = 24,000 XP
- Levels 10–29 cumulative at boundary: 24k + 4k×20 = 104,000 XP
- Level 30+: XP above 104k, 5k per level

**Implementation approach using CASE/arithmetic (no lookup table needed):**

```sql
-- Source: derived from PostgreSQL docs, verified pattern
CREATE OR REPLACE FUNCTION connect.calculate_level(p_total_xp BIGINT)
RETURNS TABLE (level INT, xp_in_level INT, xp_to_next_level INT)
LANGUAGE sql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH thresholds AS (
    SELECT
      -- Tier boundaries (cumulative XP at START of each tier's first level)
      6000::BIGINT   AS tier2_start,   -- start of 3k tier (level 4)
      24000::BIGINT  AS tier3_start,   -- start of 4k tier (level 10)
      104000::BIGINT AS tier4_start    -- start of 5k tier (level 30)
  ),
  computed AS (
    SELECT
      CASE
        WHEN p_total_xp < (SELECT tier2_start FROM thresholds) THEN
          (p_total_xp / 2000)::INT + 1
        WHEN p_total_xp < (SELECT tier3_start FROM thresholds) THEN
          3 + ((p_total_xp - (SELECT tier2_start FROM thresholds)) / 3000)::INT + 1
        WHEN p_total_xp < (SELECT tier4_start FROM thresholds) THEN
          9 + ((p_total_xp - (SELECT tier3_start FROM thresholds)) / 4000)::INT + 1
        ELSE
          29 + ((p_total_xp - (SELECT tier4_start FROM thresholds)) / 5000)::INT + 1
      END AS v_level,
      CASE
        WHEN p_total_xp < (SELECT tier2_start FROM thresholds) THEN
          (p_total_xp % 2000)::INT
        WHEN p_total_xp < (SELECT tier3_start FROM thresholds) THEN
          ((p_total_xp - (SELECT tier2_start FROM thresholds)) % 3000)::INT
        WHEN p_total_xp < (SELECT tier4_start FROM thresholds) THEN
          ((p_total_xp - (SELECT tier3_start FROM thresholds)) % 4000)::INT
        ELSE
          ((p_total_xp - (SELECT tier4_start FROM thresholds)) % 5000)::INT
      END AS v_xp_in_level,
      CASE
        WHEN p_total_xp < (SELECT tier2_start FROM thresholds) THEN
          (2000 - (p_total_xp % 2000))::INT
        WHEN p_total_xp < (SELECT tier3_start FROM thresholds) THEN
          (3000 - ((p_total_xp - (SELECT tier2_start FROM thresholds)) % 3000))::INT
        WHEN p_total_xp < (SELECT tier4_start FROM thresholds) THEN
          (4000 - ((p_total_xp - (SELECT tier3_start FROM thresholds)) % 4000))::INT
        ELSE
          (5000 - ((p_total_xp - (SELECT tier4_start FROM thresholds)) % 5000))::INT
      END AS v_xp_to_next_level
    FROM thresholds
  )
  SELECT v_level, v_xp_in_level, v_xp_to_next_level FROM computed;
$$;
```

**GRANT EXECUTE to authenticated and anon** so Phase 10 can call it directly from the service layer via `supabaseAdmin.schema('connect').rpc('calculate_level', { p_total_xp: ... })`.

### Pattern 6: award_xp RPC (the critical one)

**What:** SECURITY DEFINER plpgsql function. Advisory lock + FOR UPDATE + CTE idempotency. Returns full XP profile.

**Idempotency mechanism:** `ON CONFLICT (idempotency_key) DO NOTHING` does NOT return the existing row (verified via PostgreSQL official mailing list and community sources). The workaround is a CTE: attempt INSERT, then `UNION ALL` with a SELECT for the existing row when the insert returned nothing.

**Return type:** Use a composite type or RETURNS TABLE with explicit columns (not returning the table row type, since we need to return both the transaction and computed level fields in one result).

```sql
-- Source: pattern from 20260227000023_phase6_rpcs.sql (credit_gems), adapted for XP
CREATE OR REPLACE FUNCTION connect.award_xp(
  p_user_id          UUID,
  p_source           TEXT,
  p_amount           INT,
  p_idempotency_key  TEXT,
  p_metadata         JSONB DEFAULT NULL
)
RETURNS TABLE (
  -- Transaction row fields
  id               UUID,
  user_id          UUID,
  source           TEXT,
  amount           INT,
  metadata         JSONB,
  idempotency_key  TEXT,
  created_at       TIMESTAMPTZ,
  -- Computed XP profile fields
  total_xp         BIGINT,
  current_level    INT,
  xp_in_level      INT,
  xp_to_next_level INT,
  -- Idempotency flag
  is_duplicate     BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_new_total_xp  BIGINT;
  v_level_info    RECORD;
  v_existing_row  connect.xp_transactions;
  v_inserted_row  connect.xp_transactions;
BEGIN

  -- Validate amount (belt-and-suspenders: CHECK constraint also enforces this)
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'XP amount must be positive. Got: %', p_amount;
  END IF;

  -- Transaction-level advisory lock keyed on user_id hash.
  -- Serializes concurrent award_xp calls for the same user within a transaction.
  -- Released automatically on COMMIT/ROLLBACK.
  -- Pattern from credit_gems: pg_advisory_xact_lock(hashtext(user_id::text))
  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Check for idempotent replay BEFORE acquiring FOR UPDATE row lock.
  -- If this idempotency_key was already used, return the original row immediately.
  SELECT * INTO v_existing_row
  FROM connect.xp_transactions t
  WHERE t.idempotency_key = p_idempotency_key;

  IF FOUND THEN
    -- Idempotent replay: return original transaction row + current profile state
    SELECT cp.total_xp INTO v_new_total_xp
    FROM connect.connected_profiles cp
    WHERE cp.user_id = p_user_id;

    SELECT * INTO v_level_info
    FROM connect.calculate_level(v_new_total_xp);

    RETURN QUERY
    SELECT
      v_existing_row.id,
      v_existing_row.user_id,
      v_existing_row.source,
      v_existing_row.amount,
      v_existing_row.metadata,
      v_existing_row.idempotency_key,
      v_existing_row.created_at,
      v_new_total_xp,
      v_level_info.level,
      v_level_info.xp_in_level,
      v_level_info.xp_to_next_level,
      TRUE;  -- is_duplicate
    RETURN;
  END IF;

  -- Lock the connected_profiles row (FOR UPDATE) to prevent race conditions.
  -- Advisory lock above serializes; FOR UPDATE adds a second guard.
  SELECT cp.total_xp INTO v_new_total_xp
  FROM connect.connected_profiles cp
  WHERE cp.user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User % has no connected_profiles row. Cannot award XP.', p_user_id;
  END IF;

  -- Calculate new total
  v_new_total_xp := v_new_total_xp + p_amount;

  -- Calculate level from new total
  SELECT * INTO v_level_info
  FROM connect.calculate_level(v_new_total_xp);

  -- Update connected_profiles atomically
  UPDATE connect.connected_profiles
  SET
    total_xp      = v_new_total_xp,
    current_level = v_level_info.level,
    updated_at    = now()
  WHERE user_id = p_user_id;

  -- Insert ledger row (UNIQUE constraint on idempotency_key is the DB-layer guard)
  INSERT INTO connect.xp_transactions (
    user_id,
    source,
    amount,
    metadata,
    idempotency_key
  )
  VALUES (
    p_user_id,
    p_source,
    p_amount,
    p_metadata,
    p_idempotency_key
  )
  RETURNING * INTO v_inserted_row;

  RETURN QUERY
  SELECT
    v_inserted_row.id,
    v_inserted_row.user_id,
    v_inserted_row.source,
    v_inserted_row.amount,
    v_inserted_row.metadata,
    v_inserted_row.idempotency_key,
    v_inserted_row.created_at,
    v_new_total_xp,
    v_level_info.level,
    v_level_info.xp_in_level,
    v_level_info.xp_to_next_level,
    FALSE;  -- is_duplicate

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;

GRANT EXECUTE ON FUNCTION connect.award_xp TO authenticated;
```

### Pattern 7: GRANT EXECUTE on Functions

Per the project pattern, all SECURITY DEFINER functions in custom schemas need explicit GRANT EXECUTE:

```sql
GRANT EXECUTE ON FUNCTION connect.calculate_level TO authenticated, anon;
GRANT EXECUTE ON FUNCTION connect.award_xp TO authenticated;
```

Note: `award_xp` will be called by the service layer using `supabaseAdmin` (service role) in practice, but granting to `authenticated` ensures the RPC endpoint works if needed.

### Pattern 8: supabase.schema('connect').rpc() Call Pattern

This is how gemService.ts calls the RPCs — identical pattern for XP:

```typescript
// Source: C:/EV-Accounts/backend/src/lib/gemService.ts lines 43-52
const { data, error } = await supabaseAdmin.schema('connect').rpc('award_xp', {
  p_user_id: userId,
  p_source: source,
  p_amount: amount,
  p_idempotency_key: idempotencyKey,
  p_metadata: metadata ?? null,
});
```

The `connect` schema is already in `supabase/config.toml` `schemas` array — no config change needed.

### Anti-Patterns to Avoid

- **Storing `xp_to_next_level` and `xp_in_level` as columns:** Decision is compute-on-read, not stored. `calculate_level()` handles this.
- **Returning a table row type from `award_xp`:** The function returns a mix of transaction fields + computed level fields — not just the table row. Use `RETURNS TABLE` with explicit columns.
- **Using `ON CONFLICT DO NOTHING RETURNING *` alone for idempotency:** This does NOT return the original conflicting row. The pre-check SELECT pattern is needed.
- **Dropping the legacy `xp` column in Phase 9:** Phase 10 owns the account route changes. Phase 9 only adds `total_xp` and `current_level`.
- **Using `pg_advisory_lock` (session-level):** Always use `pg_advisory_xact_lock` (transaction-level) — releases automatically on commit/rollback. The session-level variant requires manual release and can deadlock across connections.
- **Not granting EXECUTE on calculate_level to anon:** Phase 10's public `GET /api/xp/:userId` endpoint may call this function directly via an unauthenticated Supabase client.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Concurrent write protection | Application-level mutex | `pg_advisory_xact_lock(hashtext(user_id::text))` | Transaction-scoped, auto-releases, proven in credit_gems |
| Idempotency tracking | Application-level deduplication table | DB UNIQUE constraint on `idempotency_key` | Atomic at DB layer, no race condition |
| Level calculation lookup table | `xp_level_thresholds` table | Pure arithmetic in `calculate_level` SQL function | No joins, O(1), IMMUTABLE (plannable) |
| Balance correctness | Summing ledger on each read | Denormalized `total_xp` on `connected_profiles` | O(1) read, maintained atomically by RPC |

**Key insight:** All the hard problems (concurrency, idempotency, atomicity) are solved by the database layer. The application service layer (Phase 10) should be thin — call the RPC, return the result.

---

## Common Pitfalls

### Pitfall 1: ON CONFLICT DO NOTHING Returns Nothing

**What goes wrong:** Writing `INSERT INTO xp_transactions (...) ON CONFLICT (idempotency_key) DO NOTHING RETURNING *` and expecting it to return the original row on replay. It returns zero rows — the caller then errors or returns null.

**Why it happens:** PostgreSQL's RETURNING only returns rows that were actually inserted or modified. DO NOTHING means no modification, no row returned.

**How to avoid:** Check for the existing row BEFORE the INSERT using a SELECT (as shown in Pattern 6 above). The pre-check approach is clearer than CTEs in a plpgsql function.

**Warning signs:** Test the idempotency path and assert it returns the same shape as a first-time insert.

### Pitfall 2: calculate_level Level-Off-by-One at Tier Boundaries

**What goes wrong:** Level calculation returns level N when the user has exactly the XP to be at level N+1.

**Why it happens:** Fence-post errors in tier boundary math. At exactly 6,000 XP, a user has completed level 3 and is at level 4 (tier 2 starts). The threshold check must be `< tier_start` (exclusive), not `<= tier_start`.

**How to avoid:** Write explicit test cases for boundary values:
- 1,999 XP → level 1
- 2,000 XP → level 2
- 5,999 XP → level 3
- 6,000 XP → level 4 (tier 2 begins)
- 23,999 XP → level 9
- 24,000 XP → level 10 (tier 3 begins)
- 103,999 XP → level 29
- 104,000 XP → level 30 (tier 4 begins)

**Warning signs:** If the RLS verification test seeds 6,000 XP and gets level 3 instead of level 4.

### Pitfall 3: advisory lock key collision

**What goes wrong:** `hashtext(user_id::text)` has a theoretical collision for two different user UUIDs (the lock space is 64-bit, UUIDs are 128-bit). Two different users could theoretically serialize against each other.

**Why it happens:** hashtext maps to int8 — only 2^64 distinct values for 2^128 UUIDs.

**How to avoid:** This is acceptable in practice (same approach used by credit_gems). The FOR UPDATE row lock on `connected_profiles` is a second guard that handles actual race conditions. The advisory lock is belt-and-suspenders. Document that collision probability is negligible at Alpha scale.

**Warning signs:** None at Alpha scale.

### Pitfall 4: Migration order — functions before tables

**What goes wrong:** Putting `calculate_level` and `award_xp` in the same migration file as the table creation but before the `CREATE TABLE` statement.

**Why it happens:** The function body references `connect.xp_transactions` and `connect.connected_profiles` new columns — if those don't exist yet, `CREATE OR REPLACE FUNCTION` may fail or silently compile a broken function.

**How to avoid:** Two separate migration files. Schema migration (tables + ALTERs + RLS + grants) runs first, then functions migration. This is the established pattern (Phase 6: migration 019 schema, migration 023 RPCs).

**Warning signs:** Migration fails with "relation does not exist" or "column does not exist."

### Pitfall 5: forgetting to update connected_profiles_public view

**What goes wrong:** `total_xp` and `current_level` exist on the base table but not on `connected_profiles_public`. Phase 10 reads the public view for non-owner queries and cannot surface level data.

**Why it happens:** Each Phase that adds columns to `connected_profiles` must also update the view (Phase 6 did this for gem balance columns).

**How to avoid:** Include DROP + CREATE VIEW in the schema migration. This is in Pattern 3.

**Warning signs:** `SELECT total_xp FROM connect.connected_profiles_public` returns "column does not exist."

### Pitfall 6: Type mismatch — total_xp BIGINT vs xp INTEGER

**What goes wrong:** Passing `total_xp` (BIGINT) into contexts that expect INT/INTEGER, or miscasting in the function body.

**Why it happens:** The legacy `xp` column is `INTEGER`. The new `total_xp` is `BIGINT` (correct — XP accumulates without ceiling). TypeScript receives it as `number` (safe for values < 2^53).

**How to avoid:** Explicit casts in `calculate_level` — `p_total_xp BIGINT`. The division and modulo operations will produce BIGINT — cast to INT where needed (`(result)::INT`).

**Warning signs:** "integer out of range" error at very high XP values if INT is used instead of BIGINT.

### Pitfall 7: `supabase gen types` not run after migration

**What goes wrong:** `database.types.ts` does not reflect the new `xp_transactions` table or the new `total_xp`/`current_level` columns on `connected_profiles`. Phase 10 code uses `unknown` types or incorrect column names.

**Why it happens:** Types are generated from the live schema — they do not auto-update.

**How to avoid:** Run `supabase gen types typescript --local > backend/src/types/database.types.ts` after applying migrations locally. The STATE.md already lists this as a pending todo.

---

## Code Examples

### Level Threshold Verification (test values)

```
XP=0        → level 1, xp_in_level=0,    xp_to_next_level=2000
XP=1999     → level 1, xp_in_level=1999, xp_to_next_level=1
XP=2000     → level 2, xp_in_level=0,    xp_to_next_level=2000
XP=5999     → level 3, xp_in_level=1999, xp_to_next_level=1
XP=6000     → level 4, xp_in_level=0,    xp_to_next_level=3000
XP=23999    → level 9, xp_in_level=2999, xp_to_next_level=1
XP=24000    → level 10, xp_in_level=0,   xp_to_next_level=4000
XP=103999   → level 29, xp_in_level=3999, xp_to_next_level=1
XP=104000   → level 30, xp_in_level=0,   xp_to_next_level=5000
XP=109000   → level 31, xp_in_level=0,   xp_to_next_level=5000
```

These values must be in the RLS/SQL test file for Phase 9.

### RLS Test Pattern (mirrors existing tests in tests/rls/connect_profiles.sql)

```sql
-- Test: Owner sees own xp_transactions rows
BEGIN;
  SET LOCAL role TO authenticated;
  SET LOCAL "request.jwt.claims" TO '{"sub": "USER_UUID", "role": "authenticated"}';

  SELECT count(*) FROM connect.xp_transactions
  WHERE user_id = 'USER_UUID';
  -- Expected: N (own rows visible)

  SELECT count(*) FROM connect.xp_transactions
  WHERE user_id = 'OTHER_USER_UUID';
  -- Expected: 0 (other user rows not visible)
ROLLBACK;

-- Test: Anon sees zero rows
BEGIN;
  SET LOCAL role TO anon;
  SET LOCAL "request.jwt.claims" TO '{"role": "anon"}';

  SELECT count(*) FROM connect.xp_transactions;
  -- Expected: 0
ROLLBACK;
```

### Service Layer Call Pattern (Phase 10 preview)

```typescript
// Source: gemService.ts pattern — supabaseAdmin.schema('connect').rpc(...)
const { data, error } = await supabaseAdmin.schema('connect').rpc('award_xp', {
  p_user_id: userId,
  p_source: 'compass_calibrate',
  p_amount: 100,
  p_idempotency_key: `compass_calibrate_${userId}_${sessionId}`,
  p_metadata: null,
});

if (error) {
  throw new Error(error.message);
}
// data[0] contains: id, user_id, source, amount, metadata, idempotency_key,
//                   created_at, total_xp, current_level, xp_in_level,
//                   xp_to_next_level, is_duplicate
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| Application-level dedup (Redis or DB) | DB UNIQUE constraint on `idempotency_key` | No extra hop; atomic at write path |
| Summing ledger for balance | Denormalized `total_xp` on profiles | O(1) reads; proven in gem ledger |
| Session-level advisory lock | Transaction-level (`pg_advisory_xact_lock`) | Auto-releases; no manual unlock needed |
| `balance_after` stored on each ledger row | No `balance_after` on XP ledger | Simpler — total is always on the profile |

---

## Open Questions

1. **calculate_level placement: `connect` schema or `public` schema?**
   - What we know: gem functions live in `connect` schema. Phase 10's public XP endpoint (`GET /api/xp/:userId`) is unauthenticated. If `calculate_level` is in `connect`, the anon role needs EXECUTE + USAGE on the schema.
   - What's unclear: Whether USAGE on `connect` schema is already granted to `anon` (migration 011 grants `USAGE ON SCHEMA connect TO anon, authenticated`) — yes it is. So `connect` schema is fine.
   - Recommendation: Place `calculate_level` in `connect` schema alongside `award_xp`. Grant EXECUTE to `authenticated` and `anon`.

2. **RETURNS TABLE vs composite type for award_xp return shape**
   - What we know: The RPC returns a mix of transaction columns + computed level data. RETURNS TABLE is the established pattern for functions that return multiple columns (used by `get_calibration_lapsed_users`).
   - What's unclear: Whether Supabase's `supabase.rpc()` handles `RETURNS TABLE` from plpgsql functions differently than scalar returns.
   - Recommendation: Use RETURNS TABLE. The gem functions return a row type (`RETURNS connect.gem_transactions`) because they only return the ledger row. `award_xp` returns extra computed fields so RETURNS TABLE is appropriate. The JS client will receive `data` as an array; callers should use `data[0]`.

3. **`is_duplicate` field in the return**
   - What we know: CONTEXT.md says idempotent replay is "silent no-op, not an error" and returns "same shape as success."
   - What's unclear: Whether Phase 10 needs to know if the response was a replay or not (e.g., to skip re-awarding other progression types simultaneously).
   - Recommendation: Include `is_duplicate BOOLEAN` in the return. Phase 10 can use it to skip gem/veracity awards on replay without changing the XP response shape. Cost is zero (just a boolean field).

---

## Sources

### Primary (HIGH confidence)
- `C:/EV-Accounts/supabase/migrations/20260227000023_phase6_rpcs.sql` — credit_gems/debit_gems pattern (advisory lock, FOR UPDATE, SECURITY DEFINER, SET search_path)
- `C:/EV-Accounts/supabase/migrations/20260227000019_phase6_gems_schema.sql` — gem schema pattern (append-only ledger, denormalized balance, view update pattern)
- `C:/EV-Accounts/supabase/migrations/20260224000008_rls_connect.sql` — gem_transactions RLS pattern
- `C:/EV-Accounts/supabase/migrations/20260224000011_grant_schema_permissions.sql` — grant pattern
- `C:/EV-Accounts/supabase/config.toml` — confirmed `connect` schema is in exposed_schemas
- `C:/EV-Accounts/backend/src/lib/gemService.ts` — confirmed `supabaseAdmin.schema('connect').rpc()` pattern
- PostgreSQL docs (WebFetch) — `pg_advisory_xact_lock` is transaction-level, auto-releases on COMMIT/ROLLBACK

### Secondary (MEDIUM confidence)
- dev.to/yugabyte article on INSERT ON CONFLICT returning old values — CTE pattern for idempotency. Corroborates that DO NOTHING does not return the conflicting row. Official PostgreSQL mailing list (message-id link in search) confirms the limitation.

### Tertiary (LOW confidence)
- WebSearch: Supabase non-public schema RPC. Confirmed by `config.toml` `schemas` array and the existing `credit_gems` call pattern.

---

## Metadata

**Confidence breakdown:**
- Schema design: HIGH — directly mirrors existing gem ledger pattern in codebase
- RLS policies: HIGH — identical pattern to gem_transactions (migration 008)
- Advisory lock: HIGH — pg_advisory_xact_lock confirmed in PostgreSQL official docs and used in production credit_gems
- Idempotency implementation: HIGH — ON CONFLICT limitation confirmed; pre-check SELECT pattern is clear
- calculate_level arithmetic: HIGH — tier boundaries are deterministic math; test cases verify correctness
- View update requirement: HIGH — direct analogy to Phase 6 gem balance column addition to view

**Research date:** 2026-03-04
**Valid until:** 2026-04-03 (PostgreSQL patterns are stable; no fast-moving ecosystem)
