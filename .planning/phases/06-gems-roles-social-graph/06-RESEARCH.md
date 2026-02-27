# Phase 6: Gems, Roles, and Social Graph - Research

**Researched:** 2026-02-27
**Domain:** PostgreSQL ledger design, role management, social graph schema, RLS enforcement
**Confidence:** HIGH (schema archaeology from existing migrations; verified patterns against official Postgres and Supabase docs)

---

## Summary

Phase 6 builds on a codebase where significant social graph and ledger scaffolding was already created in Phase 1 but left minimally functional. The existing schema has `connect.gem_transactions` (single-balance, no gem type), `connect.peer_connections` (state machine already correct), `connect.account_follows` (already correct), and `public.user_roles` (enum-based, not a lookup table). CONTEXT.md decisions require schema evolution for gems (add gem_type per-row) and roles (migrate from enum to lookup table). The social graph decisions require unifying peer_connections and account_follows into a single `social_relationships` table — but the existing separate tables already have correct RLS and grants. The planner must decide whether to migrate the existing tables or introduce a new unified table and deprecate the old ones.

The atomic debit pattern is the most technically demanding piece: the existing `gem_transactions` table has a `balance_after` denormalized column (correct), but debits must be protected with `pg_advisory_xact_lock(hashtext(user_id::text))` inside a SECURITY DEFINER RPC to prevent concurrent race conditions. This pattern is already established for empowerment operations and transfers cleanly to gems.

Compass `visibility: 'friends'` enforcement (SOCL-03) requires a JOIN from `compass_responses` to the `social_relationships` (or peer_connections) table in the RLS SELECT policy — the join must check for `status = 'accepted'` bidirectionally. This is the only genuinely new RLS pattern in Phase 6.

**Primary recommendation:** Use the existing schema tables as the foundation. Extend `gem_transactions` with a `gem_type` column (TEXT CHECK IN), migrate `public.user_roles` to a new lookup pattern by adding a `public.roles` reference table and altering `user_roles` to FK reference it, and introduce `social_relationships` as the canonical Phase 6 table while preserving existing tables for migration compatibility (or migrating data).

---

## Existing Schema — What Already Exists

**CRITICAL: Read before planning any schema tasks.**

The following tables were created in Phase 1 migrations and are production-ready at the schema level. Phase 6 extends/migrates them — it does not start from scratch.

### connect.gem_transactions (Migration 005)

```sql
CREATE TABLE connect.gem_transactions (
  id               UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount           INTEGER NOT NULL,       -- positive = credit, negative = debit
  transaction_type TEXT    NOT NULL,       -- 'stipend', 'vote_cast', etc.
  feature_context  TEXT,
  reference_id     UUID,
  balance_after    INTEGER NOT NULL,       -- denormalized running balance
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**Gap to close:** No `gem_type` column. Balance is a single integer. Phase 6 must add `gem_type TEXT NOT NULL CHECK (gem_type IN ('red', 'blue', 'yellow'))` and the per-type balance tracking.

### connect.peer_connections (Migration 005)

```sql
CREATE TABLE connect.peer_connections (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status       TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (requester_id, addressee_id)
);
```

**Status:** States match CONTEXT.md exactly. RLS and grants already set. This table CAN serve as the `social_relationships` table if renamed/extended with `connection_type`, or a new unified table can be created and old tables deprecated.

### connect.account_follows (Migration 005)

```sql
CREATE TABLE connect.account_follows (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  followed_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (follower_id, followed_id)
);
```

**Status:** Correct structure. Already has RLS and grants.

### public.user_roles (Migration 003)

```sql
CREATE TYPE public.role_type AS ENUM (
  'maven', 'journo', 'arbiter', 'moderator', 'juror', 'educator', 'guide', 'scribe'
);

CREATE TABLE public.user_roles (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role_type  public.role_type NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at TIMESTAMPTZ,
  UNIQUE (user_id, role_type)
);
```

**Gap to close:** CONTEXT.md requires a `roles` lookup table with `(id, name, slug, required_tier, description, is_active)`. The ENUM `role_type` must be replaced. This requires migrating the existing `user_roles` table. See migration strategy in Architecture Patterns.

### connect.connected_profiles (Migration 004)

```sql
-- Has these existing columns (relevant to Phase 6):
xp                INTEGER NOT NULL DEFAULT 0,
gem_balance       INTEGER NOT NULL DEFAULT 0,
gem_reserve_cap   INTEGER NOT NULL DEFAULT 1000,
```

**Gap to close:** Phase 6 must add `xp_total` as a placeholder (XP is different from the existing `xp` column — clarify naming). The existing `gem_balance` is a single-type balance; Phase 6 changes gem balances to per-type via the ledger (the column may be deprecated or repurposed). Reserve cap enforcement is deferred; `gem_reserve_cap` already exists but will not be enforced in Phase 6.

---

## Standard Stack

No new libraries are needed for Phase 6. The existing stack handles all requirements.

### Core (Existing — no new installs)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `pg` | ^8.13.0 | Atomic transactions via BEGIN/COMMIT | Supabase JS client cannot do BEGIN/COMMIT; already in use |
| `@supabase/supabase-js` | ^2.45.0 | supabaseAdmin RPC calls, user client queries | Already established dual-client pattern |
| `zod` | ^3.23.0 | Request body validation | Already in use for all route validation |
| `express` | ^4.21.0 | Route handlers | Established in all prior phases |

### Supporting (Existing)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@upstash/redis` / `cache.ts` | ^1.34.0 | In-memory fallback caching | Rate limiting, slug reservation — NOT used for atomic balance checks |
| `express-rate-limit` | ^7.4.0 | Rate limiting gem grants | Prevent spam requests to award endpoints |

**Installation:** No new packages required.

---

## Architecture Patterns

### Recommended Project Structure

```
backend/src/
├── lib/
│   ├── gemService.ts          # creditGems(), debitGems(), getBalance(), getHistory()
│   ├── roleService.ts         # grantRole(), revokeRole(), getUserRoles()
│   └── socialService.ts       # sendRequest(), acceptRequest(), blockUser(), follow(), unfollow()
├── routes/
│   ├── gems.ts                # GET /gems/balance, GET /gems/transactions
│   ├── roles.ts               # GET /roles, POST /roles/grant, POST /roles/revoke (admin-only)
│   └── social.ts              # POST /social/request, PATCH /social/request/:id, POST /social/follow
└── middleware/
    └── tierGuards.ts          # requireConnected, requireEmpowered (already exists — reuse)

supabase/migrations/
├── 20260227000019_phase6_gems_schema.sql    # ADD gem_type to gem_transactions, per-type balance RPCs
├── 20260227000020_phase6_roles_schema.sql   # CREATE roles table, migrate user_roles from ENUM
├── 20260227000021_phase6_social_schema.sql  # CREATE social_relationships (or extend peer_connections)
├── 20260227000022_phase6_rls_gems.sql       # RLS on updated gem_transactions
├── 20260227000023_phase6_rls_roles.sql      # RLS on roles, user_roles
├── 20260227000024_phase6_rls_social.sql     # RLS on social_relationships, friends visibility
└── 20260227000025_phase6_grants.sql         # GRANT USAGE on any new schemas
```

### Pattern 1: Gem Ledger with Per-Type Atomic Debit

**What:** Single `gem_transactions` table with a `gem_type TEXT CHECK IN ('red', 'blue', 'yellow')` column. A separate `gem_balances` view or denormalized balance columns track current balance per type per user. Debits protected by `pg_advisory_xact_lock`.

**When to use:** All gem credit/debit operations.

**Migration approach for existing `gem_transactions`:**

```sql
-- Migration 019 — extend existing table
ALTER TABLE connect.gem_transactions
  ADD COLUMN gem_type TEXT NOT NULL DEFAULT 'blue'
    CHECK (gem_type IN ('red', 'blue', 'yellow'));

-- Drop the DEFAULT after backfill (existing rows use 'blue' as default)
-- If no existing rows in production, can use NOT NULL without DEFAULT after migration.
```

**Balance tracking — denormalized per-type rows on connected_profiles:**

```sql
-- Migration 019 continued
-- Add three per-type balance columns; existing gem_balance column remains for compatibility
-- but is superseded by these three.
ALTER TABLE connect.connected_profiles
  ADD COLUMN gem_balance_red    INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN gem_balance_blue   INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN gem_balance_yellow INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN xp_total           INTEGER NOT NULL DEFAULT 0;
  -- Note: xp_total is the Phase 6 XP placeholder; existing xp column may be deprecated
```

**`creditGems` RPC (SECURITY DEFINER):**

```sql
-- Source: established project pattern from empower.execute_empowerment
CREATE OR REPLACE FUNCTION connect.credit_gems(
  p_user_id        UUID,
  p_gem_type       TEXT,   -- 'red' | 'blue' | 'yellow'
  p_amount         INTEGER,
  p_transaction_type TEXT,
  p_source_ref     UUID DEFAULT NULL
)
RETURNS connect.gem_transactions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current_balance INTEGER;
  v_new_balance     INTEGER;
  v_result          connect.gem_transactions;
BEGIN
  -- Validate gem_type
  IF p_gem_type NOT IN ('red', 'blue', 'yellow') THEN
    RAISE EXCEPTION 'Invalid gem_type: %', p_gem_type;
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Credit amount must be positive';
  END IF;

  -- Read and update the per-type balance atomically
  -- Uses per-user advisory lock to prevent concurrent balance races
  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Read current per-type balance
  EXECUTE format(
    'SELECT gem_balance_%s FROM connect.connected_profiles WHERE user_id = $1 FOR UPDATE',
    p_gem_type
  ) INTO v_current_balance USING p_user_id;

  v_new_balance := v_current_balance + p_amount;

  -- Update denormalized balance column
  EXECUTE format(
    'UPDATE connect.connected_profiles SET gem_balance_%s = $1, updated_at = now() WHERE user_id = $2',
    p_gem_type
  ) USING v_new_balance, p_user_id;

  -- Append to ledger
  INSERT INTO connect.gem_transactions (user_id, gem_type, amount, transaction_type, reference_id, balance_after)
  VALUES (p_user_id, p_gem_type, p_amount, p_transaction_type, p_source_ref, v_new_balance)
  RETURNING * INTO v_result;

  RETURN v_result;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

**`debitGems` RPC (SECURITY DEFINER):**

```sql
CREATE OR REPLACE FUNCTION connect.debit_gems(
  p_user_id        UUID,
  p_gem_type       TEXT,
  p_amount         INTEGER,
  p_transaction_type TEXT,
  p_source_ref     UUID DEFAULT NULL
)
RETURNS connect.gem_transactions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current_balance INTEGER;
  v_new_balance     INTEGER;
  v_result          connect.gem_transactions;
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Debit amount must be positive';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  EXECUTE format(
    'SELECT gem_balance_%s FROM connect.connected_profiles WHERE user_id = $1 FOR UPDATE',
    p_gem_type
  ) INTO v_current_balance USING p_user_id;

  IF v_current_balance < p_amount THEN
    RAISE EXCEPTION 'INSUFFICIENT_BALANCE: % balance % < debit %', p_gem_type, v_current_balance, p_amount;
  END IF;

  v_new_balance := v_current_balance - p_amount;

  EXECUTE format(
    'UPDATE connect.connected_profiles SET gem_balance_%s = $1, updated_at = now() WHERE user_id = $2',
    p_gem_type
  ) USING v_new_balance, p_user_id;

  INSERT INTO connect.gem_transactions (user_id, gem_type, amount, transaction_type, reference_id, balance_after)
  VALUES (p_user_id, p_gem_type, -p_amount, p_transaction_type, p_source_ref, v_new_balance)
  RETURNING * INTO v_result;

  RETURN v_result;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

**TypeScript `gemService.ts` wrapper:**

```typescript
// Source: established project pattern from empowerService.ts
import { supabaseAdmin } from './supabase.js';

export type GemType = 'red' | 'blue' | 'yellow';

export async function creditGems(
  userId: string,
  gemType: GemType,
  amount: number,
  transactionType: string,
  sourceRef?: string
): Promise<void> {
  const { error } = await supabaseAdmin
    .schema('connect')
    .rpc('credit_gems', {
      p_user_id: userId,
      p_gem_type: gemType,
      p_amount: amount,
      p_transaction_type: transactionType,
      p_source_ref: sourceRef ?? null,
    });

  if (error) throw new Error(error.message);
}

export async function debitGems(
  userId: string,
  gemType: GemType,
  amount: number,
  transactionType: string,
  sourceRef?: string
): Promise<void> {
  const { error } = await supabaseAdmin
    .schema('connect')
    .rpc('debit_gems', {
      p_user_id: userId,
      p_gem_type: gemType,
      p_amount: amount,
      p_transaction_type: transactionType,
      p_source_ref: sourceRef ?? null,
    });

  if (error) {
    if (error.message.includes('INSUFFICIENT_BALANCE')) {
      throw Object.assign(new Error('Insufficient gem balance'), { code: 'INSUFFICIENT_BALANCE' });
    }
    throw new Error(error.message);
  }
}

export async function getBalance(userId: string): Promise<{ red: number; blue: number; yellow: number }> {
  // Use user-scoped client via pool (owner sees their own row)
  // Or service client for trusted server-side balance reads
  const { data, error } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .select('gem_balance_red, gem_balance_blue, gem_balance_yellow')
    .eq('user_id', userId)
    .single();

  if (error || !data) throw new Error('Failed to fetch balance');
  return {
    red: data.gem_balance_red,
    blue: data.gem_balance_blue,
    yellow: data.gem_balance_yellow,
  };
}
```

### Pattern 2: Role System Migration (ENUM → Lookup Table)

**What:** Phase 1 created `public.user_roles` with a `role_type` ENUM. CONTEXT.md requires a `roles` reference table with `required_tier`, `is_active`, and `description`. This requires a migration strategy.

**Migration path:**

```sql
-- Migration 020 — Phase 6 roles schema

-- Step 1: Create the roles lookup table
CREATE TABLE IF NOT EXISTS public.roles (
  id             UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  name           TEXT    NOT NULL UNIQUE,
  slug           TEXT    NOT NULL UNIQUE,
  required_tier  TEXT    CHECK (required_tier IN ('connected', 'empowered')),
  description    TEXT,
  is_active      BOOLEAN NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Step 2: Seed initial roles
INSERT INTO public.roles (name, slug, required_tier, description, is_active) VALUES
  ('Contributor', 'contributor', NULL,        'Data input role; attributed to topics/stances written by this user', true),
  ('Candidate',   'candidate',  NULL,         'Civic/political leader; increases discoverability', true),
  ('Maven',       'maven',      'empowered',  'Empowered civic expert', true),
  ('Educator',    'educator',   'empowered',  'Educational role — placeholder, not yet enforced', false),
  ('Journalist',  'journalist', 'empowered',  'Journalist role — placeholder, not yet enforced', false)
ON CONFLICT (slug) DO NOTHING;

-- Step 3: Add role_id column to user_roles (new FK reference)
ALTER TABLE public.user_roles
  ADD COLUMN role_id UUID REFERENCES public.roles(id);

-- Step 4: Backfill role_id from existing role_type ENUM values
-- Map enum values to role slugs
UPDATE public.user_roles ur
SET role_id = r.id
FROM public.roles r
WHERE r.slug = ur.role_type::text;
-- Note: Some enum values (journo, arbiter, moderator, juror, guide, scribe)
-- have no corresponding role row — these need roles inserted first if they have data,
-- or can be deleted if no production rows exist (Phase 1 just scaffolded the table).

-- Step 5: Make role_id NOT NULL once backfilled
ALTER TABLE public.user_roles ALTER COLUMN role_id SET NOT NULL;

-- Step 6: Drop the UNIQUE constraint on (user_id, role_type) — replace with (user_id, role_id)
ALTER TABLE public.user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_role_type_key;
ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_user_id_role_id_unique UNIQUE (user_id, role_id);

-- Step 7: Drop role_type column and enum (only after verifying no data loss)
-- Phase 6 may keep role_type column temporarily during transition
-- ALTER TABLE public.user_roles DROP COLUMN role_type;
-- DROP TYPE public.role_type;
```

**Why TEXT CHECK over ENUM for `roles.required_tier`:** Adding tier values to an ENUM requires `ALTER TYPE ... ADD VALUE` which takes an `ACCESS EXCLUSIVE` lock and cannot be run inside a transaction. TEXT CHECK constraints modify with `ALTER TABLE ... DROP CONSTRAINT ... ADD CONSTRAINT` — still locks but avoids the "cannot drop enum value" constraint. Since `required_tier` has exactly two values (`connected`, `empowered`) that won't change, a TEXT CHECK is acceptable here. Source: Supabase docs, PostgreSQL official docs.

**`roleService.ts` grant pattern:**

```typescript
// Source: project pattern — mirrors empowerService.ts architecture
import { pool } from './db.js';
import { supabaseAdmin } from './supabase.js';

export async function grantRole(userId: string, roleSlug: string): Promise<void> {
  const client = await pool.connect();
  try {
    // Fetch role definition
    const { rows: roleRows } = await client.query<{
      id: string;
      required_tier: string | null;
      is_active: boolean;
    }>(
      'SELECT id, required_tier, is_active FROM public.roles WHERE slug = $1',
      [roleSlug]
    );

    if (roleRows.length === 0) throw Object.assign(new Error('Role not found'), { code: 'ROLE_NOT_FOUND' });
    const role = roleRows[0]!;

    if (!role.is_active) throw Object.assign(new Error('Role is not active'), { code: 'ROLE_INACTIVE' });

    // Enforce tier eligibility
    if (role.required_tier === 'empowered') {
      const { rows: empRows } = await client.query(
        'SELECT id FROM empower.empowered_profiles WHERE user_id = $1 AND is_active = true',
        [userId]
      );
      if (empRows.length === 0) {
        throw Object.assign(
          new Error(`Role '${roleSlug}' requires Empowered tier`),
          { code: 'TIER_INELIGIBLE' }
        );
      }
    } else if (role.required_tier === 'connected') {
      const { rows: connRows } = await client.query(
        'SELECT id FROM connect.connected_profiles WHERE user_id = $1 AND verification_status = $2',
        [userId, 'verified']
      );
      if (connRows.length === 0) {
        throw Object.assign(
          new Error(`Role '${roleSlug}' requires Connected tier`),
          { code: 'TIER_INELIGIBLE' }
        );
      }
    }

    // Insert new row (never reuse revoked rows — CONTEXT.md decision)
    await client.query(
      'INSERT INTO public.user_roles (user_id, role_id) VALUES ($1, $2)',
      [userId, role.id]
    );
  } finally {
    client.release();
  }
}

export async function revokeRole(userId: string, roleSlug: string): Promise<void> {
  await pool.query(
    `UPDATE public.user_roles ur
     SET revoked_at = now()
     FROM public.roles r
     WHERE ur.role_id = r.id
       AND ur.user_id = $1
       AND r.slug = $2
       AND ur.revoked_at IS NULL`,
    [userId, roleSlug]
  );
}
```

### Pattern 3: Unified `social_relationships` Table

**What:** CONTEXT.md specifies a single `social_relationships` table with `connection_type` column (`'follow'` | `'peer'`). The existing separate tables (`peer_connections`, `account_follows`) must be evaluated for migration.

**Migration decision — extend existing vs. new table:**

The existing `peer_connections` and `account_follows` tables have correct schema, RLS, and grants. Options:

**Option A: Introduce `social_relationships` as canonical table, deprecate old tables.** Safest for clean Phase 6 design. Migrate any existing rows. Old tables removed in a follow-on migration after verification.

**Option B: Keep separate tables, route API through service layer.** Service layer transparently reads/writes both tables behind a unified interface. Less clean but no data migration risk.

**Recommendation: Option A** — Phase 1 tables were scaffolding with no production data yet. A clean migration in Phase 6 is the right time. Create the unified table, migrate any test data if needed, remove old tables.

```sql
-- Migration 021 — social_relationships unified table
-- Schema placement: connect schema (consistent with peer_connections and account_follows)

CREATE TABLE IF NOT EXISTS connect.social_relationships (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id        UUID    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_id       UUID    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  connection_type TEXT    NOT NULL CHECK (connection_type IN ('follow', 'peer')),
  -- Peer-only state machine columns (NULL for follows):
  status          TEXT    CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
  -- Constraint: peer rows must have status; follow rows must not
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_peer_has_status CHECK (
    (connection_type = 'peer' AND status IS NOT NULL) OR
    (connection_type = 'follow' AND status IS NULL)
  ),
  -- For follows: unique (actor_id, target_id, 'follow')
  -- For peers: unique (ordered pair) — handle in application layer + partial index
  UNIQUE (actor_id, target_id, connection_type)
);

CREATE INDEX IF NOT EXISTS idx_social_rel_actor   ON connect.social_relationships(actor_id);
CREATE INDEX IF NOT EXISTS idx_social_rel_target  ON connect.social_relationships(target_id);
CREATE INDEX IF NOT EXISTS idx_social_rel_peers   ON connect.social_relationships(actor_id, target_id)
  WHERE connection_type = 'peer';
CREATE INDEX IF NOT EXISTS idx_social_rel_accepted ON connect.social_relationships(actor_id, target_id)
  WHERE connection_type = 'peer' AND status = 'accepted';
```

**Peer uniqueness constraint note:** For bidirectional peer requests, only ONE row exists per pair (requester = actor_id). The `UNIQUE (actor_id, target_id, connection_type)` prevents duplicates from same actor. Application layer must check for existing relationship in either direction before allowing a new request.

**Block enforcement in RPC (not pure RLS):**

Bidirectional block enforcement (neither can send new request after block) cannot be done purely in RLS because INSERT policies cannot check "does target have a block relationship with actor in the other direction." Enforce in a SECURITY DEFINER `create_peer_request` RPC:

```sql
CREATE OR REPLACE FUNCTION connect.create_peer_request(
  p_actor_id  UUID,
  p_target_id UUID
)
RETURNS connect.social_relationships
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_existing RECORD;
  v_result   connect.social_relationships;
BEGIN
  -- Check for any existing relationship in either direction
  SELECT status, actor_id INTO v_existing
  FROM connect.social_relationships
  WHERE connection_type = 'peer'
    AND (
      (actor_id = p_actor_id AND target_id = p_target_id) OR
      (actor_id = p_target_id AND target_id = p_actor_id)
    )
  LIMIT 1;

  IF FOUND THEN
    IF v_existing.status = 'blocked' THEN
      RAISE EXCEPTION 'BLOCKED: Cannot send request to or from a blocked user';
    ELSIF v_existing.status = 'accepted' THEN
      RAISE EXCEPTION 'ALREADY_CONNECTED: Users are already connected';
    ELSIF v_existing.status = 'pending' THEN
      RAISE EXCEPTION 'PENDING: A request already exists';
    END IF;
  END IF;

  INSERT INTO connect.social_relationships (actor_id, target_id, connection_type, status)
  VALUES (p_actor_id, p_target_id, 'peer', 'pending')
  RETURNING * INTO v_result;

  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

### Pattern 4: COMP-05 Friends Visibility Enforcement (SOCL-03)

**What:** `compass_responses.visibility = 'friends'` must only be visible to accepted peers. This requires an RLS SELECT policy with a subquery join.

**RLS policy approach:**

```sql
-- The existing "compass_responses: owner select" policy (migration 016) covers the owner.
-- Phase 6 adds a SECOND policy for friends visibility:

-- Drop and recreate the compass_responses SELECT policy to include friends visibility
-- OR add a second policy (multiple policies combine with OR in Postgres)

CREATE POLICY "compass_responses: friends select"
  ON inform.compass_responses
  FOR SELECT
  TO authenticated
  USING (
    visibility = 'friends'
    AND EXISTS (
      SELECT 1
      FROM connect.social_relationships sr
      WHERE sr.connection_type = 'peer'
        AND sr.status = 'accepted'
        AND (
          (sr.actor_id  = (select auth.uid()) AND sr.target_id = inform.compass_responses.user_id) OR
          (sr.target_id = (select auth.uid()) AND sr.actor_id  = inform.compass_responses.user_id)
        )
    )
  );

-- Also expose 'public' visibility to authenticated users
CREATE POLICY "compass_responses: public select"
  ON inform.compass_responses
  FOR SELECT
  TO authenticated
  USING (visibility = 'public');
```

**Performance note (verified from Supabase RLS docs):** The `(select auth.uid())` subquery form caches the value per query via `initPlan`. The `EXISTS` subquery with the `idx_social_rel_accepted` index makes the friends check efficient. Without the index on `(actor_id, target_id) WHERE status = 'accepted'`, this policy will table-scan on every compass response read.

### Pattern 5: Social Graph Privacy Model for RLS

**Empowered transparency — follows are public:**

```sql
-- Empowered user's outbound follows are public to authenticated users
CREATE POLICY "social_rel: empowered follows public read"
  ON connect.social_relationships
  FOR SELECT
  TO authenticated
  USING (
    connection_type = 'follow'
    AND EXISTS (
      SELECT 1
      FROM empower.empowered_profiles ep
      WHERE ep.user_id = actor_id
        AND ep.is_active = true
    )
  );
```

**Connected privacy — own relationships only:**

```sql
-- Participants can read their own peer relationships
CREATE POLICY "social_rel: participant read peers"
  ON connect.social_relationships
  FOR SELECT
  TO authenticated
  USING (
    connection_type = 'peer'
    AND (
      (select auth.uid()) = actor_id OR (select auth.uid()) = target_id
    )
  );

-- Users can read their own follows
CREATE POLICY "social_rel: own follows read"
  ON connect.social_relationships
  FOR SELECT
  TO authenticated
  USING (
    connection_type = 'follow'
    AND (select auth.uid()) = actor_id
  );
```

### Anti-Patterns to Avoid

- **Chaining JS awaits for multi-table gem writes:** The debit check + ledger append + balance update must be in a single SECURITY DEFINER RPC. Never check balance in JS and then INSERT in a second await — concurrent requests can pass both checks simultaneously.
- **Reusing revoked role rows:** Insert new rows for re-grants. The `user_roles.revoked_at` history must be preserved intact.
- **Using `ALTER TYPE ... ADD VALUE` inside a transaction:** Postgres does not allow enum value additions inside transactions. Always use TEXT CHECK for values that might change. This is why the `roles` table uses TEXT for `required_tier`.
- **Building a balance view from `SUM(amount)`:** Always compute balance from the denormalized `gem_balance_*` columns on `connected_profiles`, not from summing the ledger. The denormalized column is maintained atomically inside the RPC.
- **Direct supabaseAdmin usage in routes/social.ts:** Architecture test bans `supabaseAdmin` from `src/routes/`. All multi-table writes go through `src/lib/socialService.ts` or equivalent RPCs.
- **Bidirectional peer uniqueness via dual-direction UNIQUE constraint:** The current `UNIQUE (actor_id, target_id, connection_type)` only prevents duplicate rows from the same actor. Application-layer (RPC) must check the reverse direction before inserting.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Concurrent debit race condition | JS mutex / Redis lock | `pg_advisory_xact_lock` inside SECURITY DEFINER RPC | Lock tied to transaction; auto-released on commit/rollback; no leaked locks |
| Balance calculation | `SELECT SUM(amount)` on every request | Denormalized `gem_balance_*` columns updated atomically in RPC | O(1) balance reads; SUM scales linearly with ledger rows |
| Bidirectional block enforcement | Application-side checks in route handler | SECURITY DEFINER `create_peer_request` RPC | Race condition if two requests check simultaneously |
| Friends visibility | Application-side filtering after fetch | RLS policy with EXISTS subquery on `social_relationships` | Bypassing application layer is only blocked at RLS layer |
| UUID → advisory lock key | Custom hash function | `hashtext(user_uuid::text)` | Standard Postgres function; deterministic; established in community |

**Key insight:** Every atomic multi-table write and every concurrent-access protection in this codebase lives in SECURITY DEFINER RPCs. This is established project law — never break it for Phase 6.

---

## Common Pitfalls

### Pitfall 1: Forgetting the Bidirectional Peer Constraint

**What goes wrong:** User A blocked user B (row: actor=A, target=B, status=blocked). User B can then send a NEW request to user A (row: actor=B, target=A, status=pending) because the UNIQUE constraint is `(actor_id, target_id)` not pair-order-independent.

**Why it happens:** Treating the table as unidirectional when peer relationships are bidirectional by nature.

**How to avoid:** The `create_peer_request` RPC checks BOTH directions (`actor=A,target=B` and `actor=B,target=A`) before inserting. This check must be inside the RPC, not the application layer.

**Warning signs:** Peer request succeeds even after a block in the reverse direction.

### Pitfall 2: ENUM Migration Blocking Supabase Migrations

**What goes wrong:** The existing `public.role_type` ENUM is used as the column type on `public.user_roles`. Trying to `DROP TYPE public.role_type` will fail because the column still uses it. Trying to add new values requires `ALTER TYPE ... ADD VALUE` which cannot run in a transaction.

**Why it happens:** ENUMs are schema objects with dependencies; PostgreSQL enforces them strictly.

**How to avoid:** The migration must: (1) add `role_id UUID REFERENCES public.roles(id)` as nullable, (2) backfill from ENUM values, (3) make `role_id` NOT NULL, (4) drop old UNIQUE constraint and add new one, (5) drop `role_type` column, (6) `DROP TYPE public.role_type`. Do this in a single migration file inside a transaction. Verify no production rows with unmapped enum values exist before step 5.

**Warning signs:** Migration fails with "cannot drop type ... because other objects depend on it".

### Pitfall 3: `pg_advisory_xact_lock` hashtext Collision

**What goes wrong:** Two different UUIDs hash to the same bigint via `hashtext()`, causing false serialization (one user's debit blocks another's).

**Why it happens:** `hashtext` is 32-bit internally but pg_advisory_lock accepts bigint. Collisions are extremely rare but possible with millions of users.

**How to avoid:** For Alpha scale, `hashtext(uuid::text)` is sufficient. Document the collision risk in code comments. The consequence of collision is a brief performance delay (not data corruption) — one debit waits for the other to complete.

**Warning signs:** Not detectable in logs; manifests as occasional 50-100ms latency spikes on gem operations.

### Pitfall 4: RLS Policy OR Semantics on `compass_responses`

**What goes wrong:** Adding a second SELECT policy for `'friends'` visibility accidentally exposes `'public'` rows to unauthenticated users, or the `'private'` rows become readable via the friends policy because the `visibility = 'friends'` check was omitted.

**Why it happens:** Multiple RLS policies combine with OR in Postgres. The existing "owner select" policy already covers all rows for the owner. A new "friends select" policy that lacks `visibility = 'friends'` in the USING clause will expose all rows to any accepted peer.

**How to avoid:** The friends policy MUST include `visibility = 'friends'` AND the EXISTS check. Test by asserting that a peer cannot see a `visibility = 'private'` response from the other user.

**Warning signs:** Test shows peer can read responses with `visibility = 'private'`.

### Pitfall 5: Dynamic SQL `EXECUTE format()` for gem_type Column Names

**What goes wrong:** The `credit_gems` and `debit_gems` RPCs use `EXECUTE format('... gem_balance_%s ...', p_gem_type)` to dynamically reference per-type balance columns. If `p_gem_type` is not validated first, SQL injection is possible.

**Why it happens:** Dynamic column names cannot use parameterized queries (`$1`).

**How to avoid:** Validate `p_gem_type IN ('red', 'blue', 'yellow')` before the EXECUTE block, with explicit RAISE EXCEPTION on invalid input. This is shown in the code examples above.

**Warning signs:** Omitting the validation check at the start of the RPC.

### Pitfall 6: GRANT USAGE Missing on Any New Schema

**What goes wrong:** If Phase 6 adds a new schema (e.g., `social` schema instead of using `connect`), queries return "permission denied for schema" even with RLS policies allowing access.

**Why it happens:** PostgreSQL requires explicit `GRANT USAGE ON SCHEMA` for each role (`anon`, `authenticated`). Supabase does NOT auto-grant this for custom schemas.

**How to avoid:** Every migration that creates a new schema must include:
```sql
GRANT USAGE ON SCHEMA [schema_name] TO anon, authenticated;
```
The project already does this correctly in migrations 011, 012, and 016. Replicate the exact pattern.

**Warning signs:** 42501 "permission denied for schema" errors on all queries to new schema.

---

## Code Examples

Verified patterns from official and project sources:

### Advisory Lock for Debit (Postgres Official Docs)

```sql
-- Source: https://www.postgresql.org/docs/current/explicit-locking.html
-- Transaction-level advisory lock — auto-released at COMMIT/ROLLBACK
-- Using hashtext to convert UUID string to integer lock key
PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));
```

### RLS Subquery Performance Optimization (Supabase Docs)

```sql
-- Source: https://supabase.com/docs/guides/troubleshooting/rls-performance-and-best-practices-Z5Jjwv
-- CORRECT: (select auth.uid()) allows the planner to cache via initPlan
USING ((select auth.uid()) = user_id)

-- WRONG: auth.uid() evaluated per-row (no caching)
USING (auth.uid() = user_id)
```

### Reverse Join Logic for RLS (Supabase RLS Best Practices)

```sql
-- Source: https://supabase.com/docs/guides/troubleshooting/rls-performance-and-best-practices-Z5Jjwv
-- CORRECT: query the requesting user's relationships, match against table row
USING (
  EXISTS (
    SELECT 1 FROM connect.social_relationships sr
    WHERE sr.actor_id = (select auth.uid())
      AND sr.target_id = inform.compass_responses.user_id
      AND sr.status = 'accepted'
  )
)

-- WRONG: query the table row's relationships, check if current user is in them
-- This forces a full scan of social_relationships for every row
USING (
  (select auth.uid()) IN (
    SELECT actor_id FROM connect.social_relationships
    WHERE target_id = inform.compass_responses.user_id
  )
)
```

### GRANT Pattern for Custom Schemas (Established Project Pattern)

```sql
-- Source: Migration 011 — established project pattern
GRANT USAGE ON SCHEMA [schema] TO anon, authenticated;
GRANT SELECT ON [schema].[table] TO authenticated;
-- No INSERT for non-service-role on ledger tables
```

### RPC Error Propagation (Established Project Pattern)

```typescript
// Source: empowerService.ts — established project pattern
const { error } = await supabaseAdmin.schema('connect').rpc('credit_gems', { ... });
if (error) throw new Error(error.message);
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `role_type` ENUM on `user_roles` | `roles` lookup table with FK | Phase 6 migration | Adding new roles requires INSERT, not ALTER TYPE migration |
| Single `gem_balance` integer on `connected_profiles` | Three per-type columns (`gem_balance_red`, `gem_balance_blue`, `gem_balance_yellow`) | Phase 6 migration | Per-type atomic debit enforcement; clear ledger attribution |
| Separate `peer_connections` + `account_follows` tables | Unified `social_relationships` table | Phase 6 migration | Single join for friends visibility enforcement in compass RLS |
| `visibility: 'friends'` unenforceable (Phase 4 deferred) | Enforced via RLS EXISTS subquery on `social_relationships` | Phase 6 completes | COMP-05 / SOCL-03 finally closed |

**Deprecated/Outdated:**
- `connect.peer_connections`: Replace with `connect.social_relationships` in Phase 6. Table preserved until migration confirmed clean.
- `connect.account_follows`: Replace with `connect.social_relationships` in Phase 6.
- `public.role_type` ENUM: Dropped in Phase 6 migration after `public.roles` lookup table populated.
- `connect.connected_profiles.gem_balance` (single): Superseded by three per-type columns. May be preserved for backward compatibility but should not be used for new balance reads.

---

## Open Questions

1. **xp_total vs existing xp column naming**
   - What we know: `connected_profiles` has an `xp INTEGER NOT NULL DEFAULT 0` column from Phase 1. Phase 6 adds `xp_total` as XP placeholder.
   - What's unclear: Are `xp` and `xp_total` intended to be the same field, or is `xp_total` a rename? Renaming requires a migration; adding a second column creates confusion.
   - Recommendation: In the migration, add `xp_total` as an alias/synonym column and set `xp_total = xp` in the backfill. Document that `xp_total` is the canonical name going forward. Or simply use the existing `xp` column directly as the Phase 6 XP placeholder without adding a new column.

2. **`social_relationships` schema placement**
   - What we know: CONTEXT.md marks schema placement as "Claude's discretion." The existing peer/follow tables are in `connect` schema. A new `social` schema would require `GRANT USAGE` and `GRANT SELECT` setup.
   - What's unclear: Whether there's a benefit to a separate schema vs. reusing `connect`.
   - Recommendation: Use `connect` schema. It already has USAGE granted to `authenticated`. New schema adds boilerplate without benefit at this scale.

3. **Migrating `connected_profiles_public` view after adding gem_balance_* columns**
   - What we know: The view in migration 008 lists explicit columns. Adding new columns to `connected_profiles` does NOT automatically add them to the view.
   - What's unclear: Should `gem_balance_red/blue/yellow` be exposed on the public view?
   - Recommendation: Update the `connected_profiles_public` view in Phase 6 migration to include the three per-type balance columns. The single `gem_balance` column can be deprecated from the view (it'll return 0 since no Phase 1 code wrote to it).

4. **Follower count on Empowered profiles — materialized or computed?**
   - What we know: CONTEXT.md says follower count on Empowered profiles is public. Counting follows requires a COUNT query.
   - What's unclear: Whether this count should be a denormalized column (maintained in the follow/unfollow RPC) or computed on-demand via `SELECT COUNT(*) FROM social_relationships WHERE target_id = ? AND connection_type = 'follow'`.
   - Recommendation: Compute on-demand in Phase 6 (follower count API endpoint) — denormalized counts add write complexity. Optimize only when follower counts at scale become a problem.

---

## Schema Migration Numbering

The next migration after Phase 5's `20260227000018` should continue the sequence. Phase 6 needs approximately 6-7 migration files:

- `20260227000019_phase6_gems_schema.sql` — extend `gem_transactions`, add per-type balance columns, `xp_total`
- `20260227000020_phase6_roles_schema.sql` — create `roles` table, seed roles, migrate `user_roles`
- `20260227000021_phase6_social_schema.sql` — create `social_relationships`, drop old tables
- `20260227000022_phase6_rls_gems.sql` — RLS for updated `gem_transactions` (verify SELECT policy still holds)
- `20260227000023_phase6_rls_roles.sql` — RLS for `roles` (public read) and `user_roles` (owner read, service write)
- `20260227000024_phase6_rls_social.sql` — RLS for `social_relationships`, update compass_responses friends policy
- `20260227000025_phase6_grants.sql` — any new GRANT statements needed
- `20260227000026_phase6_rpcs.sql` — `credit_gems`, `debit_gems`, `create_peer_request` RPCs

---

## Sources

### Primary (HIGH confidence)
- Project migrations 003-018 (read directly) — existing schema, RLS, RPC patterns
- `backend/src/lib/empowerService.ts` (read directly) — SECURITY DEFINER RPC call pattern
- `backend/src/middleware/tierGuards.ts` (read directly) — tier check pattern
- `https://www.postgresql.org/docs/current/explicit-locking.html` — advisory lock semantics (pg_advisory_xact_lock vs session-level)
- `https://supabase.com/docs/guides/database/postgres/enums` — enum limitations, ALTER TYPE constraints
- `https://supabase.com/docs/guides/troubleshooting/rls-performance-and-best-practices-Z5Jjwv` — RLS subquery optimization, reverse join logic
- `https://supabase.com/docs/guides/api/using-custom-schemas` — GRANT USAGE pattern for custom schemas

### Secondary (MEDIUM confidence)
- `https://www.crunchydata.com/blog/enums-vs-check-constraints-in-postgres` — verified against official ALTER TYPE docs; TEXT CHECK preferred over ENUM for mutable sets
- `https://oneuptime.com/blog/post/2026-01-25-use-advisory-locks-postgresql/view` — hashtext(uuid::text) pattern for advisory lock key; consistent with pg docs
- `https://news.ycombinator.com/item?id=46154892` — lookup tables vs enums consensus; consistent with Supabase docs recommendation

### Tertiary (LOW confidence)
- WebSearch results on PostgreSQL social graph patterns — general guidance, not verified with official docs; treat as directional only

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; existing stack verified from package.json
- Architecture: HIGH — established patterns from prior phase migrations; new patterns verified against Postgres/Supabase official docs
- Schema evolution: HIGH — read all existing migrations directly; gaps identified precisely
- Pitfalls: HIGH — debit race condition, ENUM migration, RLS OR semantics all verified against official sources
- Advisory lock UUID hashing: MEDIUM — hashtext pattern confirmed by community + docs, collision risk documented honestly

**Research date:** 2026-02-27
**Valid until:** 2026-03-27 (stable stack; 30-day estimate)
