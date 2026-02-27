# Phase 3: Alpha Enrollment - Research

**Researched:** 2026-02-25
**Domain:** Invite system (atomic code claim, chain storage, TR cascade), Connect verification flow (multi-step session, connected_profiles creation, compass import)
**Confidence:** HIGH — primary sources: project codebase, official PostgreSQL docs, project CONTEXT.md decisions

---

## Summary

Phase 3 builds two interlocked systems on top of the existing Express/Supabase/pg foundation. The invite system controls entry: invite codes (format `A3B7-XK29`) are generated, stored, claimed atomically via PostgreSQL `FOR UPDATE`, and chain-linked. When an invitee is later suspended, a Postgres RPC function adjusts the inviter's Tolerance Rating by -0.10 (on the 0.00–10.00 scale) with an auto-suspend floor trigger. The Connect flow controls enrollment: a multi-step `verification_sessions` record tracks progress, required profile fields are collected, and completing the flow creates a `connected_profiles` record.

The most important technical constraint is atomicity on two separate operations: (1) invite code claim — two concurrent requests for the same code must not both succeed; (2) connected_profiles creation — must be idempotent (a user cannot complete the flow twice). Both require Postgres-level solutions. The `pg` pool is already in `lib/db.ts` and is the correct tool for raw `BEGIN/COMMIT` transactions — the Supabase JS client cannot span multi-statement transactions.

A critical schema gap exists: `connected_profiles` (migration 004) does not have `legal_name` or `home_address` columns, both required by the CONTEXT.md decisions. The `verification_sessions` table (migration 005) does not have draft columns for `legal_name` or `home_address`, and lacks an `invite_code_id` reference. New tables `connect.invite_codes` and `connect.invite_chains` do not exist at all. Phase 3 must ship a new migration before any routes are written.

**Primary recommendation:** Ship migration 014 first (new tables + schema columns), then write the invite RPC functions, then write the Connect flow routes. The schema must be correct before any application code touches it.

---

## Standard Stack

The established libraries/tools for this domain:

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `pg` | `^8.13.0` | Raw Postgres driver | Already installed; required for `BEGIN/COMMIT` atomic transactions that Supabase JS client cannot do — established project pattern from `lib/db.ts` |
| `@supabase/supabase-js` | `^2.45.0` | Supabase client for RLS-enforced reads | Already installed; `supabaseAdmin.rpc()` for SECURITY DEFINER functions, `createUserClient()` for user-facing reads |
| `zod` | `^3.23.0` | Request body validation | Already installed; all route handlers validate before any DB call |
| `express-rate-limit` | `^7.4.0` | Rate limiting invite sends per user_id | Already installed; `keyGenerator` option enables user-based limits |
| `crypto` | Node.js built-in | Cryptographically secure code generation | `crypto.randomBytes()` — no install required; already available in Node 22 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `vitest` + `supertest` | Already installed | Integration testing | Same pattern as auth.test.ts and account.test.ts |
| `winston` | `^3.17.0` | Structured logging | Already installed; log TR adjustments at INFO level |

### No New Packages Required

All dependencies for Phase 3 are already in `backend/package.json`. No `npm install` needed.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `crypto.randomBytes()` for code generation | `nanoid` | nanoid has a cleaner API for custom alphabets but adds a dependency; `crypto.randomBytes()` with a simple base-32 filter is sufficient for 8-char codes — no new package needed |
| `pg` pool for atomic claim | Supabase JS `rpc()` SECURITY DEFINER | The RPC approach works but adds PL/pgSQL complexity for a simple lock pattern; direct SQL via `pg` pool is more readable and already established in the project |
| `email-normalizer` npm package | Manual regex | The INVT-04 requirement (strip plus-addressing, lowercase) is simple enough to implement manually — one regex line, no new dependency |

---

## Architecture Patterns

### Recommended Project Structure

New files for Phase 3:

```
supabase/migrations/
└── 20260225000014_phase3_invite_connect_schema.sql  # New tables + columns

backend/src/
├── lib/
│   ├── inviteService.ts    # invite code generation, claim, chain storage
│   └── enrollService.ts    # TR adjustment RPC caller, email normalization
├── routes/
│   ├── invites.ts          # POST /api/invites/send, POST /api/invites/claim
│   └── connect.ts          # POST /api/connect/start, PATCH /api/connect/step,
│                           # POST /api/connect/complete, GET /api/connect/status,
│                           # POST /api/connect/compass-import
└── middleware/
    (no new middleware — requireAuth + requireConnected already cover what's needed)

tests/integration/
├── invites.test.ts
└── connect.test.ts
```

### Pattern 1: Atomic Invite Code Claim via pg Pool

**What:** Two concurrent requests for the same invite code must not both succeed. The `pg` pool executes a `BEGIN` / `SELECT FOR UPDATE` / `UPDATE` / `COMMIT` block as a single atomic transaction. If the row is already locked by another transaction, the second request blocks briefly and then sees the already-claimed code.

**When to use:** Every time a user claims an invite code (the `POST /api/invites/claim` handler, called during the Connect flow).

**Why not Supabase JS:** The Supabase JS client communicates via PostgREST (HTTP), which does not support `BEGIN/COMMIT` across requests. Multi-statement transactions require the raw `pg` driver — already established in `lib/db.ts`.

```typescript
// Source: PostgreSQL docs (explicit-locking) + project lib/db.ts pattern
// In lib/inviteService.ts

import { pool } from './db.js';

export async function claimInviteCode(
  code: string,
  claimantUserId: string
): Promise<{ success: boolean; inviterId: string | null; error?: string }> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Lock the row exclusively — second concurrent caller blocks here until we COMMIT
    const result = await client.query(
      `SELECT id, created_by, is_claimed, expires_at
       FROM connect.invite_codes
       WHERE code = $1
       FOR UPDATE`,
      [code]
    );

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return { success: false, inviterId: null, error: 'INVALID_CODE' };
    }

    const row = result.rows[0];

    if (row.is_claimed) {
      await client.query('ROLLBACK');
      return { success: false, inviterId: null, error: 'CODE_ALREADY_CLAIMED' };
    }

    if (row.expires_at && new Date(row.expires_at) < new Date()) {
      await client.query('ROLLBACK');
      return { success: false, inviterId: null, error: 'CODE_EXPIRED' };
    }

    // Self-invitation check (inviter cannot claim their own code)
    if (row.created_by === claimantUserId) {
      await client.query('ROLLBACK');
      return { success: false, inviterId: null, error: 'SELF_INVITE_BLOCKED' };
    }

    // Atomic claim
    await client.query(
      `UPDATE connect.invite_codes
       SET is_claimed = true, claimed_by = $1, claimed_at = now(), updated_at = now()
       WHERE id = $2`,
      [claimantUserId, row.id]
    );

    await client.query('COMMIT');
    return { success: true, inviterId: row.created_by };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
```

**Key insight:** `FOR UPDATE` (without `NOWAIT` or `SKIP LOCKED`) is the correct choice for invite codes. The second concurrent request should block and wait, then see the already-claimed code and return an error. `SKIP LOCKED` skips the row entirely (queue behavior) — wrong semantics for invite claim. `NOWAIT` raises a Postgres error immediately instead of a user-friendly claim failure — requires error handling translation.

### Pattern 2: invite_codes Table Schema

The `invite_codes` table does not exist. It must be created in migration 014.

```sql
-- Source: project conventions from migration 004 and 005
CREATE TABLE IF NOT EXISTS connect.invite_codes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code         TEXT NOT NULL UNIQUE,          -- 'A3B7-XK29' format
  created_by   UUID REFERENCES public.users(id),  -- NULL = admin-created
  claimed_by   UUID REFERENCES public.users(id),  -- NULL until claimed
  is_claimed   BOOLEAN NOT NULL DEFAULT false,
  claimed_at   TIMESTAMPTZ,
  expires_at   TIMESTAMPTZ,                   -- NULL = no expiry (admin codes can be permanent)
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invite_codes_code ON connect.invite_codes(code);
CREATE INDEX IF NOT EXISTS idx_invite_codes_created_by ON connect.invite_codes(created_by);
```

**Design notes:**
- `created_by = NULL` for admin-created codes (Phase 7 POST /api/admin/invites). The data model must support this now.
- `expires_at` is nullable — admin codes may have longer or no expiry; Connected user codes expire 30 days from creation.
- `code` is the human-readable format `A3B7-XK29`, stored uppercase, not a cryptographic hash.

### Pattern 3: invite_chains Table Schema

The invite chain record must be permanent (INVT-02: never deleted). Store it separately from invite_codes so the accountability record survives even if codes are ever purged.

```sql
CREATE TABLE IF NOT EXISTS connect.invite_chains (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_id   UUID NOT NULL REFERENCES public.users(id),   -- who sent the invite
  invitee_id   UUID NOT NULL REFERENCES public.users(id),   -- who claimed it
  invite_code_id UUID NOT NULL REFERENCES connect.invite_codes(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (invitee_id)   -- one chain record per invitee; cannot be invited twice
);

CREATE INDEX IF NOT EXISTS idx_invite_chains_inviter ON connect.invite_chains(inviter_id);
CREATE INDEX IF NOT EXISTS idx_invite_chains_invitee ON connect.invite_chains(invitee_id);
```

**Design notes:**
- `UNIQUE (invitee_id)` — a user can only ever be invited once. This enforces the "no repeat enrollment" business rule at the DB layer.
- `inviter_id` may be different from `invite_codes.created_by` in the future (admin creates codes, assigns to users to distribute). For Alpha, they are the same.

### Pattern 4: connected_profiles Schema Gap — legal_name and home_address

Migration 004 (`connect.connected_profiles`) does not have `legal_name` or `home_address` columns. CONTEXT.md decisions require both. Migration 014 must `ALTER TABLE` to add them.

```sql
-- Add to connect.connected_profiles in migration 014
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS legal_name   TEXT,       -- required for Connect; stored here, not just on empowered_profiles
  ADD COLUMN IF NOT EXISTS home_address TEXT;        -- required for Connect; internal-only field
```

**Privacy enforcement:** `legal_name` on `connected_profiles` is separate from `legal_name` on `empowered_profiles`. The Connected-tier legal_name is internal (used for identity verification at Alpha) and must NEVER appear in `connected_profiles_public` view. The view already excludes `tolerance_rating` — the same approach applies: update the view definition to also exclude `legal_name` and `home_address`.

**Update migration 014 to update the connected_profiles_public view:**
```sql
CREATE OR REPLACE VIEW connect.connected_profiles_public AS
  SELECT
    id, user_id, display_name, account_standing, verification_status,
    verification_method, verified_region, xp, gem_balance, gem_reserve_cap,
    veracity_rating,
    -- tolerance_rating intentionally OMITTED (internal)
    -- legal_name intentionally OMITTED (internal)
    -- home_address intentionally OMITTED (internal)
    deleted_at, created_at, updated_at
  FROM connect.connected_profiles
  WHERE deleted_at IS NULL;
```

### Pattern 5: verification_sessions Schema Gap

Migration 005 created `verification_sessions` with: `step_reached`, `display_name_draft`, `verification_method`, `region_draft`, `expires_at`. Missing for Phase 3: `legal_name_draft`, `home_address_draft`, `invite_code_id`.

```sql
-- Add to connect.verification_sessions in migration 014
ALTER TABLE connect.verification_sessions
  ADD COLUMN IF NOT EXISTS legal_name_draft   TEXT,
  ADD COLUMN IF NOT EXISTS home_address_draft TEXT,
  ADD COLUMN IF NOT EXISTS invite_code_id     UUID REFERENCES connect.invite_codes(id);
```

**Step state machine:** The CONTEXT.md decision defines resumption semantics: "completed steps are not repeated." The `step_reached` column stores the current step name. Recommended step names for the flow:

```
'invite'      → Invite code entry and validation
'profile'     → display_name, legal_name, location, home_address collection
'review'      → Show collected data for confirmation
'complete'    → Flow done; connected_profiles created
```

A user with `step_reached = 'profile'` who abandons resumes at the beginning of profile collection (not at invite — that step is already complete). A user with `step_reached = 'complete'` is blocked from restarting.

### Pattern 6: Invite Code Generation

**Format:** `A3B7-XK29` — 8 alphanumeric chars split by hyphen. Uppercase, excludes visually ambiguous characters (0/O, 1/I/l).

```typescript
// Source: Node.js crypto module (built-in, no install)
// In lib/inviteService.ts

import { randomBytes } from 'crypto';

// Unambiguous alphanumeric characters (excludes 0, O, I, 1, l)
const CHARSET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export function generateInviteCode(): string {
  // Need 8 chars from a 32-char alphabet
  // randomBytes(8) gives us 8 bytes (0-255), we map each to CHARSET
  // Using rejection sampling to avoid modulo bias
  let result = '';
  while (result.length < 8) {
    const bytes = randomBytes(16);
    for (const byte of bytes) {
      if (result.length >= 8) break;
      // Accept bytes that map cleanly into CHARSET length (32)
      // 256 / 32 = 8 — every byte value maps to 32 options
      // 32 evenly divides 256, so no bias: byte % 32 is perfectly uniform
      result += CHARSET[byte % 32];
    }
  }
  return `${result.slice(0, 4)}-${result.slice(4, 8)}`;
}
```

**Why no modulo bias:** 256 / 32 = 8 exactly. Every byte value maps uniformly to a CHARSET index. No rejection sampling needed, but including it is defensive and matches standard practice.

**Collision risk:** With 8 chars from 32-char alphabet, there are 32^8 ≈ 1 trillion combinations. For Alpha scale (hundreds of users × 5 codes each = thousands of codes), collision probability is negligible. Add a DB-level UNIQUE constraint and retry on conflict.

### Pattern 7: Email Normalization (INVT-04)

Email normalization before uniqueness check: lowercase + strip plus-addressing. No npm package needed — one regex line.

```typescript
// Source: project conventions + RFC 5233 (plus addressing standard)
// In lib/enrollService.ts

export function normalizeEmail(email: string): string {
  const lower = email.toLowerCase().trim();
  const [local, domain] = lower.split('@');
  // Strip plus-addressing: user+anything@domain.com → user@domain.com
  const normalizedLocal = local.split('+')[0];
  return `${normalizedLocal}@${domain}`;
}
```

**Scope:** Normalization applies to the uniqueness check before creating an invite record. The invite record stores the original email. The check query uses `normalizeEmail(targetEmail) = normalizeEmail(existingEmail)` or equivalent.

### Pattern 8: Tolerance Rating Adjustment (RPC Function)

The Tolerance Rating is `NUMERIC(4,2)` (range: 0.00 to 99.99, but the practical range for this column is 0.00 to 10.00). A decrement of **-0.10** per invitee suspension is appropriate on a 0–10 scale (1% of full range per sanction, meaningful but not catastrophic).

The TR adjustment must be a `SECURITY DEFINER` RPC function, not chained JS awaits, per the established project constraint. The function must:
1. Look up the inviter from `invite_chains`
2. Decrement their `tolerance_rating` by 0.10, floored at 0.00
3. If new TR = 0.00 AND it was previously > 0, trigger auto-suspend
4. Emit a notification event (for Alpha: insert a record into a `notification_events` table or log — exact notification delivery is Phase 7)

```sql
-- Source: project conventions from migration 010 (execute_empowerment pattern)
-- To be created in migration 014

CREATE OR REPLACE FUNCTION connect.adjust_inviter_tolerance_rating(
  p_invitee_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_inviter_id      UUID;
  v_current_tr      NUMERIC(4,2);
  v_new_tr          NUMERIC(4,2);
BEGIN
  -- Look up the direct inviter (one level only — does not cascade further)
  SELECT inviter_id INTO v_inviter_id
    FROM connect.invite_chains
    WHERE invitee_id = p_invitee_id;

  -- If no invite chain record (e.g., admin-created direct enrollment), do nothing
  IF v_inviter_id IS NULL THEN
    RETURN;
  END IF;

  -- Get current tolerance_rating with row lock
  SELECT tolerance_rating INTO v_current_tr
    FROM connect.connected_profiles
    WHERE user_id = v_inviter_id
    FOR UPDATE;

  -- If inviter has no connected_profiles (shouldn't happen but be safe), do nothing
  IF v_current_tr IS NULL THEN
    RETURN;
  END IF;

  -- Decrement by 0.10, floor at 0.00
  v_new_tr := GREATEST(0.00, v_current_tr - 0.10);

  UPDATE connect.connected_profiles
    SET
      tolerance_rating = v_new_tr,
      updated_at       = now()
    WHERE user_id = v_inviter_id;

  -- Auto-suspend if TR hit floor (only if it wasn't already 0)
  IF v_new_tr = 0.00 AND v_current_tr > 0.00 THEN
    UPDATE connect.connected_profiles
      SET
        account_standing = 'suspended',
        updated_at       = now()
      WHERE user_id = v_inviter_id
        AND account_standing = 'active';  -- Only suspend if currently active
  END IF;

  -- Notification: insert a notification event for the inviter
  -- Phase 7 wires delivery; for Alpha this record is the event source
  -- NOTE: notification_events table must be created in migration 014
  INSERT INTO public.notification_events (
    user_id,
    event_type,
    metadata
  ) VALUES (
    v_inviter_id,
    'tolerance_rating_adjusted',
    jsonb_build_object(
      'reason', 'invitee_suspended',
      'invitee_id', p_invitee_id,
      'adjustment', -0.10,
      'new_value', v_new_tr
    )
  );

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

**Calling this RPC from Express:** The TR adjustment is triggered by an admin suspension action (Phase 7). However, the RPC function itself is created in Phase 3. Phase 7 will call it via `supabaseAdmin.rpc('adjust_inviter_tolerance_rating', { p_invitee_id: userId })`.

### Pattern 9: Connect Flow — Route Design

The Connect flow requires multiple HTTP endpoints because it is a multi-step, resumable flow. Each step writes to `verification_sessions`.

```
POST /api/connect/start          → validate invite code, create/resume verification_session
PATCH /api/connect/step          → update current step's draft data
POST /api/connect/complete       → validate all fields, create connected_profiles record
GET  /api/connect/status         → return current verification_status (CONN-02)
POST /api/connect/compass-import → import compass data from localStorage (CONN-04)
```

**Idempotency — complete step:** `POST /api/connect/complete` must check for an existing `connected_profiles` row before creating one. If one exists (verification_status = 'verified'), return 200 with the existing profile — do not create a second row.

**Idempotency — start step:** `POST /api/connect/start` must check for an existing `verification_sessions` row. If one exists with `step_reached != 'complete'`, return the current step (resumption). If `step_reached = 'complete'`, return 409 — flow already completed.

### Pattern 10: Compass Import (CONN-04)

The compass import endpoint receives an array of topic responses from the client. The client detects localStorage data and sends it. Version mismatches (where a topic's version doesn't match the current DB version) must be flagged for confirmation.

```typescript
// Request shape for POST /api/connect/compass-import
interface CompassImportItem {
  topic_id: string;
  stance_index: number;     // 0-4 (which of 5 stances)
  inverted: boolean;
  topic_version: number;    // client-side version from localStorage
}

// Response shape
interface CompassImportResponse {
  imported: number;
  mismatched: Array<{       // Topics where version doesn't match current DB
    topic_id: string;
    client_version: number;
    current_version: number;
  }>;
  requires_confirmation: boolean;  // true if any mismatches exist
}
```

**Two-phase import:** The endpoint first validates and identifies mismatches, returning them to the client for confirmation. On second call with `confirmed: true`, it writes the mismatched items. This avoids silent data corruption from stale calibration data.

**Phase scope:** Phase 3 creates the server-side import endpoint only. The compass_responses table (in the `inform` schema) is created in Phase 4. Phase 3's import endpoint must be designed to either (a) defer writing compass data until Phase 4's tables exist, or (b) write to a staging structure. **Recommendation:** Create the compass_responses table schema in Phase 4 but design the import endpoint API contract in Phase 3. The Phase 3 endpoint returns a validation response; Phase 4 wires the actual write. This is cleaner than a staging table.

**Alternative approach:** Create `inform.compass_responses` in Phase 3's migration since the import endpoint needs it. Check the Phase 1 migration to see if inform schema was created.

### Pattern 11: Notification Events Table

The TR adjustment RPC writes notification events. A `public.notification_events` table must exist. Phase 7 will read and deliver them. Migration 014 should create this table.

```sql
CREATE TABLE IF NOT EXISTS public.notification_events (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.users(id),
  event_type TEXT NOT NULL,       -- e.g. 'tolerance_rating_adjusted'
  metadata   JSONB,
  read_at    TIMESTAMPTZ,         -- NULL = unread
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notification_events_user_id
  ON public.notification_events(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_events_unread
  ON public.notification_events(user_id)
  WHERE read_at IS NULL;
```

### Pattern 12: Rate Limiting Invite Sends Per User (INVT-04)

The invite send endpoint must be rate-limited per `user_id`, not per IP. `express-rate-limit` supports custom `keyGenerator`:

```typescript
// Source: express-rate-limit docs (github.com/express-rate-limit/express-rate-limit)
import rateLimit from 'express-rate-limit';
import type { AuthenticatedRequest } from '../middleware/auth.js';

const inviteSendLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000, // 24 hours
  max: 10,                         // 10 invite sends per user per day
  keyGenerator: (req) => {
    // Rate limit by user ID (set by requireAuth middleware)
    return (req as AuthenticatedRequest).userId ?? req.ip ?? 'unknown';
  },
  message: {
    code: 'RATE_LIMIT_EXCEEDED',
    message: 'Too many invite requests. Please try again tomorrow.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});
```

**Note on keyGenerator timing:** `requireAuth` sets `req.userId` before the rate limiter runs if the limiter is applied as route-level middleware AFTER `requireAuth`. Apply in this order: `router.post('/send', requireAuth, requireConnected, inviteSendLimiter, handler)`.

### Anti-Patterns to Avoid

- **Chained JS awaits for invite claim:** Do NOT call `supabaseAdmin.from('invite_codes').select()` then `supabaseAdmin.from('invite_codes').update()` as separate awaits. Race condition: two requests can both pass the check and both write the claim. Use `pool.connect()` + `BEGIN` / `FOR UPDATE` / `COMMIT`.

- **supabaseAdmin in route files:** The architecture test will fail. Invite service functions go in `lib/inviteService.ts` or `lib/enrollService.ts`, not in `routes/invites.ts`.

- **Creating connected_profiles with Supabase JS client user-scoped client:** The `createUserClient(accessToken)` approach is correct for reads (RLS enforced). For the final `connected_profiles` write (POST /api/connect/complete), use `supabaseAdmin` via a service layer. The RLS policy for `INSERT` on `connected_profiles` needs checking — migration 008 only has `SELECT` and `UPDATE` policies for the owner; INSERT is not granted to authenticated. This means INSERT must go through `supabaseAdmin` (permitted for trusted writes per architecture pattern).

- **Tolerance Rating on 0-1 scale:** The column is `NUMERIC(4,2)` which supports values 0.00 to 99.99. Using a 0-1 scale would mean all values are `0.xx` with no room for the 2 decimal places to be meaningful (0.10 = 10% is reasonable but 0.01 per sanction is too small and 0.10 per sanction means 10 sanctions = floor). On a 0–10 scale, -0.10 per sanction means 100 sanctions to reach floor — appropriate accountability depth. Use 0.00–10.00 range. New Connected users should be initialized with `tolerance_rating = 10.00`.

- **Re-using verification_sessions step_reached as status:** The `step_reached` value is draft state, not the same as `connected_profiles.verification_status`. Do not conflate them. `verification_status` on `connected_profiles` is `'pending' | 'verified' | 'suspended'`. `step_reached` in `verification_sessions` is the flow step name.

- **Storing plus-addressed email as-is for uniqueness check:** INVT-04 requires normalized email for uniqueness. Supabase Auth normalizes email on its own for auth purposes. The invite-specific check (has this email already been invited?) needs manual normalization before the DB query.

---

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic invite code claim | JS-layer check-then-update with Supabase JS client | `pg` pool + `BEGIN` / `SELECT FOR UPDATE` / `UPDATE` / `COMMIT` | Race condition between check and update is a real concurrency hazard; Postgres row locks are the correct solution |
| Cryptographic randomness for codes | `Math.random()` | `crypto.randomBytes()` (built-in) | `Math.random()` is not cryptographically secure; predictable codes are a security vulnerability for invite systems |
| TR adjustment as route handler | `await supabase.from('connected_profiles').update({ tolerance_rating: newVal })` | `SECURITY DEFINER` RPC function | Multi-table operation (update TR + possibly set account_standing) must be atomic; chained awaits are explicitly forbidden by project architecture |
| Email uniqueness check for invites | String comparison on raw email | `normalizeEmail()` before query | Plus-addressing exploits (`user+1@gmail.com`, `user+2@gmail.com`) allow repeat invites; normalization closes this |
| Flow resumption logic | Client-side state management | Server-side `verification_sessions` table | Session state must survive browser close, device switch, and network interruption; localStorage is not reliable |

**Key insight:** Phase 3 has three distinct atomicity requirements (invite claim, TR adjustment, connected_profiles creation). All three require Postgres-level solutions — none can be safely done with chained JS awaits.

---

## Common Pitfalls

### Pitfall 1: Missing connected_profiles INSERT Policy

**What goes wrong:** `POST /api/connect/complete` calls `createUserClient(accessToken).schema('connect').from('connected_profiles').insert(...)`. Supabase returns `42501: permission denied`.

**Why it happens:** Migration 008 (`rls_connect.sql`) created only a `SELECT` policy and an `UPDATE` policy for `connected_profiles`. No `INSERT` policy was created. Migration 011 granted `SELECT` but not `INSERT` to the `authenticated` role. The existing RLS pattern for privileged writes is to use `supabaseAdmin` (service role bypasses RLS).

**How to avoid:** `connected_profiles` INSERT must go through `supabaseAdmin` (called from a service layer, not from a route handler). Add an INSERT policy to migration 014 OR keep the `supabaseAdmin` approach (consistent with the "trusted writes use service role" project pattern). The project decision in MEMORY.md is: "service role for trusted writes only" — use `supabaseAdmin` for the `connected_profiles` insert, via a service function.

**Architecture test impact:** The INSERT call goes in `lib/enrollService.ts` (or equivalent), not in `routes/connect.ts`.

### Pitfall 2: verification_sessions UNIQUE Constraint Missing

**What goes wrong:** A user calls `POST /api/connect/start` multiple times. Multiple `verification_sessions` rows are created for the same user. The resume logic fails or picks the wrong row.

**Why it happens:** Migration 005 has no UNIQUE constraint on `(user_id)` for `verification_sessions`. Multiple rows can exist for the same user.

**How to avoid:** Migration 014 should add `UNIQUE (user_id)` to `verification_sessions`. Use `INSERT ... ON CONFLICT (user_id) DO UPDATE SET step_reached = EXCLUDED.step_reached, ...` (upsert) in the start handler. Alternatively, enforce uniqueness at the application layer by using `supabaseAdmin.upsert()` with a conflict target.

**Warning signs:** `GET /api/connect/status` returns inconsistent step if multiple rows exist.

### Pitfall 3: invite_codes RLS Grants Missing

**What goes wrong:** The new `connect.invite_codes` and `connect.invite_chains` tables are created in migration 014 but the grant migration (equivalent of migration 011) is not updated. `authenticated` role cannot SELECT, INSERT, or UPDATE these tables at all.

**How to avoid:** Migration 014 must include `GRANT` statements for the new tables. Pattern from migration 011:
```sql
GRANT SELECT, INSERT ON connect.invite_codes TO authenticated;
GRANT SELECT ON connect.invite_chains TO authenticated;
-- INSERT for invite_chains via supabaseAdmin only (trusted write)
```

Also add RLS policies for the new tables in migration 014.

### Pitfall 4: Self-Invite Check Missing from DB Layer

**What goes wrong:** The self-invite check (`if (row.created_by === claimantUserId)`) exists in application code but not enforced at DB level. If the check is bypassed (e.g., direct DB call, future admin tool), self-invites succeed.

**How to avoid:** Add a CHECK constraint or trigger on `invite_chains` that prevents `inviter_id = invitee_id`. For Alpha this is belt-and-suspenders defense.

### Pitfall 5: tolerance_rating Starting Value Undefined

**What goes wrong:** A newly Connected user has `tolerance_rating = NULL` (the column default). The TR adjustment function does `GREATEST(0.00, v_current_tr - 0.10)` — but if `v_current_tr IS NULL`, the expression returns NULL (Postgres arithmetic with NULL propagates NULL). The update sets TR to NULL instead of 9.90.

**How to avoid:** New `connected_profiles` rows should have `tolerance_rating = 10.00` set on insert. Either set this as a column default or ensure the `POST /api/connect/complete` handler always sets it. Migration 014 should update the column to have `DEFAULT 10.00`.

**Warning signs:** `tolerance_rating` is NULL after Connect completion. TR adjustment produces NULL result.

### Pitfall 6: connect.invite_codes Not Accessible via Supabase JS Client

**What goes wrong:** The `connect` schema is already exposed in Supabase's API config (migration 011 granted `USAGE` to `authenticated`). New tables added in migration 014 inherit schema access but need explicit table-level GRANTs.

**How to avoid:** Every new table in migration 014 needs both an RLS policy AND a GRANT statement. Check that migration 014 includes both for `invite_codes`, `invite_chains`, and `notification_events`.

### Pitfall 7: Compass Import Writes to Non-Existent Tables

**What goes wrong:** `POST /api/connect/compass-import` tries to write to `inform.compass_responses` but that table doesn't exist until Phase 4.

**Why it happens:** Phase 3 only creates the API endpoint for compass import; Phase 4 creates the `inform` schema tables.

**How to avoid:** The Phase 3 compass-import endpoint validates the import payload and returns a `requires_confirmation` response but does NOT write to `compass_responses`. Writing compass data is wired in Phase 4. Phase 3 stores the raw import payload in the `verification_sessions` record (add a `compass_import_draft JSONB` column to `verification_sessions`). Phase 4's routes pick up from there.

**Alternative:** If creating `inform.compass_responses` in Phase 3's migration is acceptable (it's just a table, not Phase 4 routes), create it now and let the import endpoint write directly. This is cleaner but slightly out-of-phase-boundary. Recommend creating the table in Phase 3 migration to avoid the JSONB staging hack.

### Pitfall 8: Architecture Test Must Be Updated for New Service Files

**What goes wrong:** New service files (`lib/inviteService.ts`, `lib/enrollService.ts`) use `supabaseAdmin`. The architecture test checks `supabaseAdmin exists only in expected files`. Test fails.

**How to avoid:** When creating `lib/inviteService.ts` or `lib/enrollService.ts`, add them to the `allowedFiles` array in `tests/integration/architecture.test.ts`. The `lib/db.ts` pattern (raw pg) does not use supabaseAdmin, so `inviteService.ts` may use the `pool` directly without triggering the architecture test.

---

## Code Examples

Verified patterns from official sources:

### FOR UPDATE atomic claim (pg pool)

```typescript
// Source: PostgreSQL docs (explicit-locking.html) + project lib/db.ts pattern
import { pool } from './db.js';

const client = await pool.connect();
try {
  await client.query('BEGIN');
  const { rows } = await client.query(
    'SELECT id, created_by, is_claimed, expires_at FROM connect.invite_codes WHERE code = $1 FOR UPDATE',
    [code]
  );
  // ... validate, then UPDATE, then COMMIT
  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK');
  throw err;
} finally {
  client.release(); // Always release back to pool
}
```

### Invite code generation (crypto, no bias)

```typescript
// Source: Node.js crypto module (built-in)
import { randomBytes } from 'crypto';

const CHARSET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 32 chars, no ambiguous chars

export function generateInviteCode(): string {
  let result = '';
  while (result.length < 8) {
    const bytes = randomBytes(16);
    for (const byte of bytes) {
      if (result.length >= 8) break;
      result += CHARSET[byte % 32]; // 256/32=8: no modulo bias
    }
  }
  return `${result.slice(0, 4)}-${result.slice(4, 8)}`;
}
```

### Email normalization (plus-addressing)

```typescript
// Source: project conventions + RFC 5233
export function normalizeEmail(email: string): string {
  const [local, domain] = email.toLowerCase().trim().split('@');
  return `${local.split('+')[0]}@${domain}`;
}
```

### RPC call for TR adjustment

```typescript
// Source: project MEMORY.md + Supabase JS client docs
// Called by Phase 7 admin suspension action
const { error } = await supabaseAdmin.rpc('adjust_inviter_tolerance_rating', {
  p_invitee_id: suspendedUserId,
});
if (error) {
  console.error('[TR adjustment] RPC failed:', error);
  // Non-fatal: log and continue; TR adjustment failure should not block suspension
}
```

### express-rate-limit with user-based keyGenerator

```typescript
// Source: express-rate-limit docs (github.com/express-rate-limit/express-rate-limit)
import rateLimit from 'express-rate-limit';
import type { AuthenticatedRequest } from '../middleware/auth.js';

export const inviteSendLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000,
  max: 10,
  keyGenerator: (req) => (req as AuthenticatedRequest).userId ?? req.ip ?? 'unknown',
  message: { code: 'RATE_LIMIT_EXCEEDED', message: 'Invite limit reached for today' },
  standardHeaders: true,
  legacyHeaders: false,
});
```

### Supabase upsert for verification_sessions (start step idempotency)

```typescript
// Source: @supabase/supabase-js docs + project supabaseAdmin pattern
// Upsert: create session if none exists, or return existing session
const { data, error } = await supabaseAdmin
  .schema('connect')
  .from('verification_sessions')
  .upsert(
    {
      user_id: userId,
      step_reached: 'invite',
      invite_code_id: inviteCodeId,
      updated_at: new Date().toISOString(),
    },
    {
      onConflict: 'user_id',
      ignoreDuplicates: false, // Update the row if it already exists
    }
  )
  .select()
  .single();
```

---

## Schema Changes Required (Migration 014 Checklist)

This is the complete list of DB changes Phase 3 must ship before any routes are written:

### New Tables
- [ ] `connect.invite_codes` — code, created_by (nullable), claimed_by, is_claimed, claimed_at, expires_at
- [ ] `connect.invite_chains` — inviter_id, invitee_id, invite_code_id; UNIQUE(invitee_id)
- [ ] `public.notification_events` — user_id, event_type, metadata JSONB, read_at

### Column Additions
- [ ] `connect.connected_profiles`: ADD `legal_name TEXT`, `home_address TEXT`, update `tolerance_rating` DEFAULT to 10.00
- [ ] `connect.verification_sessions`: ADD `legal_name_draft TEXT`, `home_address_draft TEXT`, `invite_code_id UUID`, `compass_import_draft JSONB`
- [ ] `connect.verification_sessions`: ADD UNIQUE constraint on `user_id`

### View Updates
- [ ] `connect.connected_profiles_public`: Recreate to also exclude `legal_name` and `home_address`

### RLS Policies
- [ ] `connect.invite_codes`: SELECT (owner sees own created codes), INSERT (authenticated can create — via service layer), UPDATE (no direct user update — claim via RPC only)
- [ ] `connect.invite_chains`: SELECT (inviter and invitee can see their own chain records)
- [ ] `public.notification_events`: SELECT (owner sees own notifications)

### Grants
- [ ] `GRANT USAGE ON SCHEMA public TO authenticated` (already exists via Supabase default)
- [ ] `GRANT SELECT, INSERT ON connect.invite_codes TO authenticated`
- [ ] `GRANT SELECT ON connect.invite_chains TO authenticated`
- [ ] `GRANT SELECT ON public.notification_events TO authenticated`

### RPC Functions
- [ ] `connect.adjust_inviter_tolerance_rating(p_invitee_id UUID)` — SECURITY DEFINER, TR decrement + auto-suspend floor
- [ ] (Optional) `connect.create_connected_profile(p_user_id UUID, p_display_name TEXT, p_legal_name TEXT, p_location TEXT, p_home_address TEXT, p_invite_code_id UUID)` — atomic connected_profiles INSERT + verification_session cleanup

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Invite via long random token (64 chars, INVT-01 original) | Short human-readable code `A3B7-XK29` | CONTEXT.md decision (2026-02-25) | CONTEXT.md overrides REQUIREMENTS.md; implementation must use 8-char format |
| JS-layer check-then-update for atomicity | `pg` pool `FOR UPDATE` transaction | Project MEMORY.md decision | Chained JS awaits are explicitly forbidden for multi-table atomic writes |
| `@supabase/auth-helpers-*` | `@supabase/ssr` | 2023 | Project already uses correct package |
| `supabaseAdmin` in routes | Service layer pattern | Phase 1 architecture decision | Architecture test enforces this automatically |

**Deprecated/outdated:**
- INVT-01 (64-char cryptographic token): Overridden by CONTEXT.md decision — use 8-char human-readable format instead
- Any approach that uses `Supabase JS client` for `BEGIN/COMMIT`: Not supported via PostgREST HTTP API

---

## Open Questions

1. **inform.compass_responses table in Phase 3 vs Phase 4**
   - What we know: `POST /api/connect/compass-import` needs to eventually write compass data; Phase 4 creates the compass routes; the inform schema exists (migration 001 created schemas)
   - What's unclear: Should Phase 3 create `inform.compass_responses` now (to avoid JSONB staging) or defer to Phase 4?
   - Recommendation: Create `inform.compass_responses` table structure in Phase 3's migration 014, but do NOT write any data to it from Phase 3's import endpoint. Store the raw import JSON in `verification_sessions.compass_import_draft`. Phase 4 routes will read from there and write to `compass_responses` properly. This keeps Phase boundaries clean.

2. **connected_profiles INSERT — RLS policy vs supabaseAdmin**
   - What we know: No INSERT RLS policy exists for `connected_profiles`; `supabaseAdmin` is the established pattern for trusted writes
   - What's unclear: Whether to add an INSERT RLS policy (allowing `createUserClient` to insert) or keep it as supabaseAdmin-only
   - Recommendation: Keep as `supabaseAdmin` only. The connected_profiles creation is a privileged operation (it changes tier). Adding an INSERT RLS policy would allow any authenticated user to create their own connected_profiles row without going through the validated flow. Trust the service layer.

3. **invite_codes for admin-created codes (Phase 7)**
   - What we know: `created_by` should be nullable for admin codes (CONTEXT.md: Phase 7 handles POST /api/admin/invites); Phase 3 only needs to support admin-created codes in the data model
   - What's unclear: Should admin-created codes skip the 5-code-per-user limit?
   - Recommendation: Yes — admin-created codes have `created_by = NULL` and are not subject to per-user limits. The rate limiter (INVT-04) applies only to Connected user invite sends, not admin code creation.

4. **Tolerance Rating initial value**
   - What we know: Column is `NUMERIC(4,2)`, currently no DEFAULT; CONTEXT.md says decrement is fixed (Claude decides value)
   - Decision: `DEFAULT 10.00` for new Connected users. TR adjustment = -0.10. This means 100 invitee suspensions to reach floor — appropriate accountability depth for Alpha.

---

## Sources

### Primary (HIGH confidence)

- `C:\EV-Accounts\supabase\migrations\20260224000004_connect_connected_profiles.sql` — confirms missing `legal_name`, `home_address` columns; confirms `tolerance_rating NUMERIC(4,2)` scale
- `C:\EV-Accounts\supabase\migrations\20260224000005_connect_supporting_tables.sql` — confirms `verification_sessions` columns present and missing; confirms no `invite_codes` or `invite_chains` tables
- `C:\EV-Accounts\supabase\migrations\20260224000008_rls_connect.sql` — confirms no INSERT RLS policy on `connected_profiles`; confirms `verification_sessions` owner-only policies
- `C:\EV-Accounts\supabase\migrations\20260224000010_rpc_functions.sql` — confirms SECURITY DEFINER pattern, `SET search_path = ''`, full rollback on EXCEPTION
- `C:\EV-Accounts\backend\src\lib\db.ts` — confirms `pool` (pg) is available for raw transactions
- `C:\EV-Accounts\backend\src\lib\authService.ts` — confirms service layer pattern for supabaseAdmin usage
- `C:\EV-Accounts\tests\integration\architecture.test.ts` — confirms allowedFiles list that must be updated for new service files
- `https://www.postgresql.org/docs/current/explicit-locking.html` — confirmed FOR UPDATE blocking semantics; second transaction blocks until first commits

### Secondary (MEDIUM confidence)

- `https://github.com/express-rate-limit/express-rate-limit` — confirmed `keyGenerator` API for user-based rate limiting
- `https://supabase.com/docs/reference/javascript/rpc` — confirmed `supabase.rpc('name', { param: value })` call pattern
- `https://www.postgresql.org/docs/current/sql-select.html` — confirmed FOR UPDATE vs FOR UPDATE NOWAIT vs SKIP LOCKED semantics

### Tertiary (LOW confidence)

- WebSearch: email plus-addressing normalization patterns (multiple sources agree on `local.split('+')[0]` approach)
- WebSearch: PostgreSQL SKIP LOCKED vs NOWAIT for queue vs claim use cases (multiple sources agree; confirmed against official docs)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already in package.json; no new installs needed
- Architecture (service layer, RPC functions): HIGH — based on actual project code and established patterns
- Schema gaps: HIGH — directly verified from reading all migration files
- RPC function design (TR adjustment): HIGH — pattern follows existing migration 010 functions exactly
- Atomic invite claim (FOR UPDATE): HIGH — verified against official PostgreSQL docs
- Invite code generation algorithm: HIGH — crypto.randomBytes is Node.js built-in, modulo math verified
- Compass import deferral recommendation: MEDIUM — design judgment call, not prescribed by official docs
- Notification events table design: MEDIUM — placeholder for Phase 7; schema may need revision

**Research date:** 2026-02-25
**Valid until:** 2026-03-25 (Supabase JS and pg APIs are stable; PostgreSQL locking semantics do not change)
