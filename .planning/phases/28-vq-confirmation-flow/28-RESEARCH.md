# Phase 28: VQ Confirmation Flow - Research

**Researched:** 2026-03-15
**Domain:** PostgreSQL SECURITY DEFINER RPC (batch write), Express service-key auth, atomic multi-user update
**Confidence:** HIGH — all findings sourced directly from codebase inspection

## Summary

Phase 28 is a single POST endpoint that orchestrates four write operations atomically for a batch of users: gem award, verification rating adjustment, vq_hold_until update, and politician stance upsert. The codebase has strong established patterns for all of these individually (award_gems RPC, SECURITY DEFINER functions, gemServiceKeyAuth middleware). The non-trivial design question is the "replay returns original result" requirement, which differs from existing single-ledger idempotency.

The existing `award_gems` and `award_xp` RPCs handle idempotency by finding the original ledger row and returning it. That works because each call produces exactly one ledger row and one user. This endpoint produces a structured batch result covering N users — there is no single ledger row to replay from. The correct approach is a **result-cache table** (`connect.vq_confirmation_results`) that stores the serialized JSON response keyed by `idempotency_key`. On replay, the RPC reads and returns the cached result without re-executing any writes. This is the established industry pattern for batch-idempotency with complex structured responses.

The Postgres transaction structure should be a single `SECURITY DEFINER` function (`connect.confirm_vq_stance`) called via `adminRpc()`. The function receives all inputs and handles the entire flow: idempotency check first, then per-user rating/gem updates in a loop, then politician_answers upsert, then result cache write. The Express route (`/api/vq/confirm-stance`) validates input, calls the RPC, and returns the result. Auth uses the existing `requireGemServiceKey` middleware (Bearer token, GEMS_SERVICE_KEYS env var), since VQ already has a gem service key — no new middleware needed.

**Primary recommendation:** One migration (038) creates the result-cache table and the `confirm_vq_stance` RPC. One new route file (`src/routes/vq.ts`) with `POST /confirm-stance`. One new service file (`src/lib/vqService.ts`). Registered as `/api/vq` in `index.ts`. Uses `requireGemServiceKey` for auth.

## Standard Stack

No new libraries. This phase uses what is already in the project.

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| `connect.confirm_vq_stance` RPC | New Postgres function | Atomic batch write: ratings + gems + stance | Project convention: all multi-table writes go through SECURITY DEFINER RPCs, never chained JS awaits |
| `connect.vq_confirmation_results` | New table | Idempotency result cache for replay responses | Batch idempotency requires caching the full structured result; no single ledger row to replay from |
| `adminRpc()` from `supabase.ts` | Existing | Call new RPC via service role | Established pattern — all SECURITY DEFINER RPC calls use this helper |
| `requireGemServiceKey` from `gemServiceKeyAuth.ts` | Existing | Bearer token auth for VQ service | VQ already has a gem service key; re-use prevents auth middleware proliferation |
| `zod` | Existing | Request body validation | Project-wide schema validation pattern |

### No New Installs Required

```bash
# No new packages
```

## Architecture Patterns

### Recommended File Changes

```
supabase/migrations/
└── 20260315000038_phase28_vq_confirmation.sql   # new: result table + confirm_vq_stance RPC

backend/src/routes/
└── vq.ts                                         # new: POST /confirm-stance handler

backend/src/lib/
└── vqService.ts                                  # new: confirmVqStance() service function

backend/src/index.ts                              # edit: register /api/vq router
```

### Pattern 1: Result-Cache Table for Batch Idempotency

**What:** A table keyed on `idempotency_key` that stores the serialized JSON response. The RPC checks this table first on every call. On a duplicate key, it deserializes and returns the cached result without executing any writes.

**Why not per-row idempotency like award_gems:** `award_gems` returns the original transaction row — there is always exactly one row per idempotency key. `confirm_vq_stance` produces a batch result across N users. There is no canonical "original row" to return. The result-cache table is the correct solution.

**Table structure:**
```sql
-- Source: established pattern from connect.gem_transactions idempotency_key
CREATE TABLE IF NOT EXISTS connect.vq_confirmation_results (
  idempotency_key  TEXT        PRIMARY KEY,
  result_json      JSONB       NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**Why JSONB not TEXT:** JSONB is indexable and validates JSON at write time. The planner may add queries against the cached results later (e.g., find all confirmations for a given politician).

**Why PRIMARY KEY not UNIQUE INDEX:** Same effect for deduplication, but PRIMARY KEY is cleaner for a table whose sole purpose is keyed lookup.

### Pattern 2: Single SECURITY DEFINER RPC for the Entire Flow

**What:** All writes happen inside one Postgres transaction. The RPC signature receives all inputs: politician_id, topic_id, confirmed_value, correct_user_ids[], incorrect_user_ids[], idempotency_key, gems_amount.

**Precedent:** `connect.promote_to_connected` (migration 035) handles multi-table writes atomically. `connect.award_gems` (migration 034) uses `pg_advisory_xact_lock` + idempotency pre-check + `FOR UPDATE` row lock.

**Key steps the RPC must execute:**
1. Idempotency pre-check on `vq_confirmation_results` — return cached result if found
2. Validate politician/topic pair exists in `inform.politicians` + `inform.compass_topics` — RAISE EXCEPTION if not (404 in the route layer)
3. Advisory lock per-user (or single batch lock) to prevent concurrent processing
4. For each correct user ID: validate connected_profiles row exists (skip if not), award gems via INSERT into `gem_transactions` + UPDATE `gem_balance_red`, increment `verification_rating` by 3 (LEAST 150), build per-user result row
5. For each incorrect user ID: validate connected_profiles row exists (skip if not), decrement `verification_rating` by 10 (GREATEST 0), if new rating = 0 set `vq_hold_until = now() + interval '30 days'`, build per-user result row
6. Upsert `inform.politician_answers` with the confirmed value
7. Build result JSON, INSERT into `vq_confirmation_results`, return

**Function signature:**
```sql
-- Source: established RPC pattern (migrations 030, 034, 035)
CREATE OR REPLACE FUNCTION connect.confirm_vq_stance(
  p_politician_id    UUID,
  p_topic_id         UUID,
  p_confirmed_value  INT,
  p_correct_users    UUID[],
  p_incorrect_users  UUID[],
  p_idempotency_key  TEXT,
  p_gems_amount      INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
```

**Why RETURNS JSONB not RETURNS TABLE:** The result is a variable-length batch report. RETURNS TABLE is awkward when columns vary by content. RETURNS JSONB allows returning the full structured response directly — the route layer passes it through without transformation.

### Pattern 3: Gem Award Inside the Batch RPC (Not Via award_gems)

**Critical design decision:** The RPC cannot call `connect.award_gems` from within the batch RPC because `award_gems` uses its own per-user idempotency_key. The batch confirmation needs ONE idempotency_key for the whole operation. Calling `award_gems` for each user would require generating sub-keys, which is fragile.

**Correct approach:** The RPC directly inserts into `connect.gem_transactions` and updates `gem_balance_red` — the same writes `award_gems` makes, but without the per-transaction idempotency wrapper. The batch-level idempotency (the result-cache table) handles replay protection for the entire operation.

**What this means for the migration:** The RPC must replicate the gem write logic from `award_gems` inline:
```sql
-- Direct gem write (same pattern as award_gems step 7–8, but without idempotency wrapper)
UPDATE connect.connected_profiles
  SET gem_balance_red = gem_balance_red + p_gems_amount,
      updated_at = now()
  WHERE user_id = v_user_id;

INSERT INTO connect.gem_transactions (
  user_id, gem_type, amount, transaction_type, balance_after, reference_id
) VALUES (
  v_user_id, 'red', p_gems_amount, 'validation_quest_confirmation',
  v_new_balance, NULL  -- reference_id can hold the idempotency_key or be NULL
);
```

### Pattern 4: Route Handler Structure

**What:** The route handler is thin — it validates input, calls the service function, handles errors from known exception strings, and returns the result.

**Auth:** Use `requireGemServiceKey` (Bearer token from GEMS_SERVICE_KEYS). The VQ service key already exists in the map with `['red']` gem type permission. The route should verify the key has `'red'` in its permitted gem types before calling the service.

**Precedent:** `src/routes/gems.ts` — `requireGemServiceKey`, Zod validation, service call, error code → HTTP status mapping.

```typescript
// Source: src/routes/gems.ts pattern
import { Router } from 'express';
import { z } from 'zod';
import { requireGemServiceKey, type GemServiceKeyRequest } from '../middleware/gemServiceKeyAuth.js';
import { confirmVqStance } from '../lib/vqService.js';
import type { Request, Response } from 'express';

const router = Router();

const ConfirmStanceSchema = z.object({
  politician_id: z.string().uuid(),
  topic_id: z.string().uuid(),
  confirmed_value: z.number().int().min(1).max(5),
  correct_user_ids: z.array(z.string().uuid()),
  incorrect_user_ids: z.array(z.string().uuid()),
  idempotency_key: z.string().min(1).max(255),
  gems_amount: z.number().int().positive(),
});

router.post(
  '/confirm-stance',
  requireGemServiceKey,
  async (req: Request, res: Response): Promise<void> => {
    const serviceReq = req as GemServiceKeyRequest;

    // VQ service key must permit red gems (it awards red gems to correct answerers)
    if (!serviceReq.permittedGemTypes.includes('red')) {
      res.status(403).json({ error: 'SERVICE_KEY_INSUFFICIENT_PERMISSIONS' });
      return;
    }

    const parsed = ConfirmStanceSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ error: 'VALIDATION_ERROR', issues: parsed.error.issues });
      return;
    }

    try {
      const result = await confirmVqStance(parsed.data);
      res.status(200).json(result);
    } catch (err) {
      const code = (err as { code?: string }).code;
      if (code === 'QUESTION_NOT_FOUND') {
        res.status(404).json({ error: 'QUESTION_NOT_FOUND', message: 'No matching politician/topic pair found' });
        return;
      }
      console.error('[POST /api/vq/confirm-stance] error:', err);
      res.status(500).json({ error: 'INTERNAL_ERROR' });
    }
  }
);

export default router;
```

### Pattern 5: VQ Input Shape (question_id vs politician_id + topic_id)

**CONTEXT.md says:** The endpoint accepts `{ politician_id, topic_id, confirmed_value, correct_user_ids[], incorrect_user_ids[], idempotency_key }`. The response uses `question_id`.

**Implication:** `question_id` in the response is a derived concept — VQ maps a "question" to a `(politician_id, topic_id)` pair. The accounts API does not need a `question_id` column anywhere. The response `question_id` can be constructed as `"${politician_id}:${topic_id}"` or simply return both fields. Recommend returning `politician_id` and `topic_id` instead of a synthetic `question_id` to avoid confusion. Discuss with planner — this is a response shape detail.

### Pattern 6: Input gems_amount vs Fixed Amount

**CONTEXT.md says:** Red Gems amount is "configurable per VQ service key" (VQ-02). This implies the gems_amount should come from the request body (VQ decides how many gems to award per question), not hardcoded. The Zod schema must include `gems_amount: z.number().int().positive()`.

**Alternative:** The gems_amount could be a per-key config in `GEMS_SERVICE_KEYS` env var (extend the map value from `string[]` to `{ gemTypes: string[], vqGemsAmount?: number }`). This is more secure (VQ cannot manipulate the amount), but requires env config changes.

**Recommendation:** Accept `gems_amount` in the request body (consistent with how `amount` works in `POST /api/gems/award`). If security requires server-side amount config, that is a scope extension to address in a future phase.

### Anti-Patterns to Avoid

- **Chained JS awaits for per-user writes:** Never `await awardGems(userId)` in a loop. All writes must happen inside the Postgres RPC in a single transaction. JS-chained awaits cannot be rolled back atomically.
- **Calling award_gems RPC per user:** `award_gems` has its own idempotency key contract. Calling it inside the batch breaks that contract and makes the batch non-atomic.
- **Storing result as TEXT (not JSONB):** TEXT cannot be queried or indexed. JSONB is the correct type for structured cache values.
- **Using X-Service-Key header:** The gems endpoint uses `Authorization: Bearer`, not `X-Service-Key`. Use `requireGemServiceKey`, not `requireServiceKey`, for this endpoint.
- **Skipping advisory lock:** The existing RPC pattern (`award_gems`, `award_xp`) acquires `pg_advisory_xact_lock(hashtext(p_user_id::text))`. For a batch operation over N users, the lock strategy needs thought — see Pitfalls section.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Batch idempotency | JS-layer deduplication via Redis or separate check | `connect.vq_confirmation_results` table (Postgres) | Postgres transaction guarantees atomicity — JS-layer check has a race window between check and write |
| Per-user gem write | Call `award_gems` RPC per user | Direct INSERT/UPDATE inside `confirm_vq_stance` | `award_gems` has its own idempotency contract; calling it inside a batch breaks atomicity |
| Rating boundary clamping | App-layer min/max | `GREATEST(0, ...)` and `LEAST(150, ...)` in Postgres | SQL functions are atomic, no race; database CHECK constraint is the last-line safety net |
| Politician/topic validation | Separate query before RPC | Validate inside RPC with RAISE EXCEPTION | Separate query is a TOCTOU race; validate and write must be in the same transaction |

**Key insight:** The RPC owns the transaction. The Express route is a thin adapter. Any logic that touches the database — validation, writes, idempotency check — belongs inside the RPC.

## Common Pitfalls

### Pitfall 1: Advisory Lock Strategy for Batch

**What goes wrong:** Locking N users serially inside a loop with `pg_advisory_xact_lock(hashtext(user_id))` is correct for preventing concurrent award_gems calls for the same user. But in a batch context, it can cause deadlocks if two concurrent batch calls process users in different orders.

**Why it happens:** Batch A processes [User1, User2]; Batch B processes [User2, User1]. A locks User1, B locks User2. A tries to lock User2 (blocked), B tries to lock User1 (blocked) → deadlock.

**How to avoid:** Sort the user ID array before acquiring locks so all concurrent callers acquire locks in the same order. In Postgres: `SELECT DISTINCT user_id FROM unnest(p_correct_users || p_incorrect_users) ORDER BY 1` then lock in that order.

**Warning signs:** Occasional 500 errors on concurrent calls; Postgres error message mentioning deadlock detection.

### Pitfall 2: Partial Writes on User Not Found

**What goes wrong:** The batch processes User1 successfully (gems awarded, rating updated), then finds User2 does not exist. If the RPC raises an exception, User1's writes are rolled back — but the caller has no idea User1 succeeded.

**Why it happens:** RAISE EXCEPTION inside a transaction rolls back all prior writes in that transaction.

**How to avoid:** Per CONTEXT.md: unknown user IDs are skipped (continue), not failed. Use `SELECT ... INTO ... FROM connect.connected_profiles WHERE user_id = v_user_id` and check `IF NOT FOUND THEN` to add to unresolved_users list and `CONTINUE` rather than RAISE.

**Warning signs:** Valid users losing gems/rating changes because one unrecognized user_id was in the batch.

### Pitfall 3: Confirm Result JSON Structure Mismatch

**What goes wrong:** The result JSON stored in `vq_confirmation_results` does not exactly match the response shape returned to the caller on fresh calls. On replay, the stored result looks different.

**Why it happens:** The RPC builds and stores the JSON, then the JS layer transforms it before returning. The transformation is not applied on replay.

**How to avoid:** The RPC stores the FINAL response JSON — exactly what the route returns. The JS layer must return the JSONB value directly on replay, without any transformation. Design the RPC to produce the exact response shape.

### Pitfall 4: Double-Processing on Retry Without Idempotency Check

**What goes wrong:** The idempotency check queries `vq_confirmation_results` AFTER acquiring advisory locks. If the query is inside the lock, a retry will block until the first call completes — which is correct but slow. If the check is BEFORE the lock, two concurrent calls with the same key can both pass the check and both execute writes.

**How to avoid:** Do the idempotency check BEFORE acquiring any advisory locks (like `award_gems` does: idempotency check at step 4, BEFORE the `FOR UPDATE` row lock at step 5). If the idempotency key already exists, return immediately — no locks acquired.

### Pitfall 5: politician_answers Upsert Using Wrong Column Names

**What goes wrong:** `inform.politician_answers` uses composite PK `(politician_id, topic_id)`. The upsert must be `ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`. Using `ON CONFLICT DO NOTHING` would silently skip overwrite on re-confirmation.

**Why it happens:** Confusing "no double-insert" idempotency with "authoritative overwrite" semantics.

**How to avoid:** Use `INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (...) ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`.

### Pitfall 6: Missing Route Registration in index.ts

**What goes wrong:** `vq.ts` route file created but not imported and mounted in `index.ts`. The endpoint returns 404 in production.

**How to avoid:** Add `import vqRouter from './routes/vq.js'` and `app.use('/api/vq', vqRouter)` to `index.ts` immediately. Verify with a smoke test.

### Pitfall 7: Auth Header Wrong — X-Service-Key vs Bearer

**What goes wrong:** VQ sends `Authorization: Bearer <token>`, but the route uses `requireServiceKey` (which reads `X-Service-Key` header) instead of `requireGemServiceKey` (which reads `Authorization: Bearer`).

**Why it happens:** Two service key middlewares exist in the codebase with different header conventions. `serviceKeyAuth.ts` uses `X-Service-Key`; `gemServiceKeyAuth.ts` uses `Authorization: Bearer`.

**How to avoid:** CONTEXT.md says "follows the Bearer pattern established in Phase 22." Use `requireGemServiceKey` and `Authorization: Bearer`.

### Pitfall 8: confirmed_value Not Validated Against Existing Stances Range

**What goes wrong:** `inform.politician_answers.value` has `CHECK (value BETWEEN 1 AND 5)`. If `p_confirmed_value` is out of range, the INSERT will throw a Postgres check violation rather than a clean 422.

**How to avoid:** Add `IF p_confirmed_value NOT BETWEEN 1 AND 5 THEN RAISE EXCEPTION 'INVALID_CONFIRMED_VALUE' END IF;` at the start of the RPC, before any writes.

## Code Examples

### Migration 038: Result-cache table

```sql
-- Source: established pattern from connect.gem_transactions idempotency design
-- (migration 034)
CREATE TABLE IF NOT EXISTS connect.vq_confirmation_results (
  idempotency_key  TEXT        PRIMARY KEY,
  result_json      JSONB       NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Grant service role access (service role bypasses grants, but explicit is clearer)
-- Authenticated role does NOT get access — this is an internal ledger table
```

### Migration 038: RPC skeleton with idempotency-first pattern

```sql
-- Source: award_gems pattern (migration 034) + promote_to_connected pattern (migration 035)
CREATE OR REPLACE FUNCTION connect.confirm_vq_stance(
  p_politician_id    UUID,
  p_topic_id         UUID,
  p_confirmed_value  INT,
  p_correct_users    UUID[],
  p_incorrect_users  UUID[],
  p_idempotency_key  TEXT,
  p_gems_amount      INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_existing_result  JSONB;
  v_result           JSONB;
  v_user_id          UUID;
  v_current_rating   INT;
  v_new_rating       INT;
  v_new_gem_balance  INT;
  v_users_out        JSONB[] := '{}';
  v_unresolved       UUID[]  := '{}';
  v_correct_count    INT     := 0;
  v_incorrect_count  INT     := 0;
BEGIN
  -- Step 1: Validate confirmed_value range
  IF p_confirmed_value NOT BETWEEN 1 AND 5 THEN
    RAISE EXCEPTION 'INVALID_CONFIRMED_VALUE: % is not between 1 and 5', p_confirmed_value;
  END IF;

  -- Step 2: Idempotency pre-check (BEFORE any locks — same pattern as award_gems)
  SELECT result_json INTO v_existing_result
    FROM connect.vq_confirmation_results
    WHERE idempotency_key = p_idempotency_key;

  IF FOUND THEN
    RETURN v_existing_result || '{"replayed": true}'::JSONB;
  END IF;

  -- Step 3: Validate politician/topic pair exists
  IF NOT EXISTS (
    SELECT 1 FROM inform.politicians p
    JOIN inform.compass_topics t ON t.id = p_topic_id
    WHERE p.id = p_politician_id
  ) THEN
    RAISE EXCEPTION 'QUESTION_NOT_FOUND: politician % topic % pair not found',
      p_politician_id, p_topic_id;
  END IF;

  -- Step 4: Process correct users (sort for deterministic lock order → deadlock prevention)
  FOREACH v_user_id IN ARRAY (
    SELECT ARRAY(SELECT u FROM unnest(p_correct_users || p_incorrect_users) u ORDER BY u)
  ) LOOP
    PERFORM pg_advisory_xact_lock(hashtext(v_user_id::text));
  END LOOP;

  -- Step 5: Award gems and increment rating for each correct user
  FOREACH v_user_id IN ARRAY p_correct_users LOOP
    SELECT verification_rating, gem_balance_red
      INTO v_current_rating, v_new_gem_balance
      FROM connect.connected_profiles
      WHERE user_id = v_user_id
      FOR UPDATE;

    IF NOT FOUND THEN
      v_unresolved := v_unresolved || v_user_id;
      CONTINUE;
    END IF;

    v_new_rating      := LEAST(150, v_current_rating + 3);
    v_new_gem_balance := v_new_gem_balance + p_gems_amount;

    UPDATE connect.connected_profiles
      SET verification_rating = v_new_rating,
          gem_balance_red     = v_new_gem_balance,
          updated_at          = now()
      WHERE user_id = v_user_id;

    INSERT INTO connect.gem_transactions (
      user_id, gem_type, amount, transaction_type, balance_after
    ) VALUES (
      v_user_id, 'red', p_gems_amount, 'validation_quest_confirmation', v_new_gem_balance
    );

    v_users_out := v_users_out || jsonb_build_object(
      'user_id',      v_user_id,
      'result',       'correct',
      'gems_awarded', p_gems_amount,
      'rating_delta', v_new_rating - v_current_rating,
      'new_rating',   v_new_rating
    );
    v_correct_count := v_correct_count + 1;
  END LOOP;

  -- Step 6: Decrement rating for each incorrect user
  FOREACH v_user_id IN ARRAY p_incorrect_users LOOP
    SELECT verification_rating INTO v_current_rating
      FROM connect.connected_profiles
      WHERE user_id = v_user_id
      FOR UPDATE;

    IF NOT FOUND THEN
      v_unresolved := v_unresolved || v_user_id;
      CONTINUE;
    END IF;

    v_new_rating := GREATEST(0, v_current_rating - 10);

    IF v_new_rating = 0 THEN
      UPDATE connect.connected_profiles
        SET verification_rating = 0,
            vq_hold_until       = now() + interval '30 days',
            updated_at          = now()
        WHERE user_id = v_user_id;
    ELSE
      UPDATE connect.connected_profiles
        SET verification_rating = v_new_rating,
            updated_at          = now()
        WHERE user_id = v_user_id;
    END IF;

    v_users_out := v_users_out || jsonb_build_object(
      'user_id',      v_user_id,
      'result',       'incorrect',
      'gems_awarded', 0,
      'rating_delta', v_new_rating - v_current_rating,
      'new_rating',   v_new_rating
    );
    v_incorrect_count := v_incorrect_count + 1;
  END LOOP;

  -- Step 7: Upsert confirmed stance
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
    VALUES (p_politician_id, p_topic_id, p_confirmed_value)
    ON CONFLICT (politician_id, topic_id)
    DO UPDATE SET value = EXCLUDED.value;

  -- Step 8: Build result, cache, return
  v_result := jsonb_build_object(
    'politician_id',    p_politician_id,
    'topic_id',         p_topic_id,
    'confirmed_value',  p_confirmed_value,
    'correct_count',    v_correct_count,
    'incorrect_count',  v_incorrect_count,
    'users',            to_jsonb(v_users_out),
    'unresolved_users', to_jsonb(v_unresolved)
  );

  INSERT INTO connect.vq_confirmation_results (idempotency_key, result_json)
    VALUES (p_idempotency_key, v_result);

  RETURN v_result;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

### vqService.ts: thin wrapper

```typescript
// Source: src/lib/gemService.ts awardGems pattern
import { adminRpc } from './supabase.js';

export interface ConfirmVqStanceParams {
  politician_id: string;
  topic_id: string;
  confirmed_value: number;
  correct_user_ids: string[];
  incorrect_user_ids: string[];
  idempotency_key: string;
  gems_amount: number;
}

export async function confirmVqStance(params: ConfirmVqStanceParams): Promise<unknown> {
  const { data, error } = await adminRpc('confirm_vq_stance', {
    p_politician_id:   params.politician_id,
    p_topic_id:        params.topic_id,
    p_confirmed_value: params.confirmed_value,
    p_correct_users:   params.correct_user_ids,
    p_incorrect_users: params.incorrect_user_ids,
    p_idempotency_key: params.idempotency_key,
    p_gems_amount:     params.gems_amount,
  }, 'connect');

  if (error) {
    if (error.message?.includes('QUESTION_NOT_FOUND')) {
      throw Object.assign(new Error('Question not found'), { code: 'QUESTION_NOT_FOUND' });
    }
    if (error.message?.includes('INVALID_CONFIRMED_VALUE')) {
      throw Object.assign(new Error('Invalid confirmed_value'), { code: 'INVALID_CONFIRMED_VALUE' });
    }
    throw new Error(error.message ?? 'confirm_vq_stance RPC failed');
  }

  // confirm_vq_stance RETURNS JSONB — data is the JSONB value directly (not an array)
  return data;
}
```

### index.ts: route registration

```typescript
// Source: established pattern from index.ts (gem route registration at line 51)
import vqRouter from './routes/vq.js';
// ...
app.use('/api/vq', vqRouter);
```

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| Per-transaction idempotency (award_gems, award_xp) | Batch result-cache table | award_gems returns original row; batch needs full result cached |
| X-Service-Key header (serviceKeyAuth.ts) | Authorization: Bearer (gemServiceKeyAuth.ts) | Two middleware patterns exist; VQ uses Bearer per Phase 22 |

**No deprecated patterns needed in this phase.** All new code follows current codebase conventions.

## Open Questions

1. **Response field: `question_id` vs `politician_id` + `topic_id`**
   - What we know: CONTEXT.md response shape says `question_id` in the outer object. VQ maps questions to politician/topic pairs. Accounts API receives `politician_id` and `topic_id`.
   - What's unclear: Whether `question_id` should be a synthetic string like `"<politician_id>:<topic_id>"` or whether the response should just return `politician_id` and `topic_id` separately.
   - Recommendation: Return `politician_id` and `topic_id` separately. Avoids synthetic ID parsing. The planner should verify this against VQ contract expectations.

2. **gems_amount in request body vs per-key env config**
   - What we know: VQ-02 says "amount configurable per VQ service key." This can mean in the request or in server config.
   - What's unclear: Whether VQ should be trusted to set the amount (request body) or the server should enforce it (env config).
   - Recommendation: Accept in request body for now (consistent with `/api/gems/award` pattern). Document as a future hardening candidate.

3. **Advisory lock scope: per-user or batch-wide**
   - What we know: Deadlock prevention requires sorting user IDs before acquiring locks. The sorted-acquire pattern is standard.
   - What's unclear: Whether a single batch-wide advisory lock (on the `idempotency_key` hash) is simpler and sufficient.
   - Recommendation: Per-user sorted locks. They compose correctly with concurrent gem/XP awards for the same user. A batch-wide lock would serialize all VQ confirmations globally.

4. **Migration number: 038 or next available**
   - What we know: Last migration is `20260315000037`. The next should be `20260315000038`.
   - What's unclear: Whether any other phases shipped migrations today that would shift the sequence number.
   - Recommendation: Use `20260315000038` — today's date + next sequence. Verify before writing the file.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `supabase/migrations/20260315000037_phase27_verification_rating.sql` — schema of `verification_rating` and `vq_hold_until` columns
- Direct codebase inspection: `supabase/migrations/20260314000034_phase22_gems_idempotency.sql` — full `award_gems` RPC implementation and idempotency pattern
- Direct codebase inspection: `supabase/migrations/20260226000015_inform_schema.sql` — `inform.politician_answers` table structure (composite PK, value CHECK 1–5)
- Direct codebase inspection: `backend/src/middleware/gemServiceKeyAuth.ts` — Bearer token auth pattern and `permittedGemTypes`
- Direct codebase inspection: `backend/src/routes/gems.ts` — route handler pattern, Zod validation, `requireGemServiceKey` usage
- Direct codebase inspection: `backend/src/lib/gemService.ts` — `awardGems()` service function and `adminRpc` pattern
- Direct codebase inspection: `backend/src/lib/xpService.ts` — `awardXp()` pattern for RETURNS TABLE handling
- Direct codebase inspection: `backend/src/index.ts` — route registration pattern
- Direct codebase inspection: `backend/src/lib/supabase.ts` — `adminRpc()` helper signature
- Direct codebase inspection: `backend/src/lib/env.ts` — `GEMS_SERVICE_KEYS` env var definition
- Direct codebase inspection: `supabase/migrations/20260304000030_phase9_xp_rpcs.sql` — advisory lock and idempotency pre-check pattern

### No External Sources Required

This phase is entirely within the existing codebase domain. The patterns for SECURITY DEFINER RPCs, service key auth, idempotency, and gem writes are all directly observable in the codebase. No new libraries, frameworks, or external APIs.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries, all existing patterns directly verified in code
- Architecture (RPC transaction structure): HIGH — direct precedents in migrations 030, 034, 035
- Architecture (result-cache table idempotency): HIGH — derived from first principles given the batch result requirement; JSONB result cache is the canonical approach for this pattern
- Pitfalls (advisory lock deadlock): HIGH — classic concurrent-lock ordering problem, well-documented in Postgres literature; the sorted-acquire solution is the standard fix
- Pitfalls (don't call award_gems per-user): HIGH — verified from award_gems source that it has its own idempotency contract that would conflict
- Open questions: MEDIUM — response shape and gems_amount source require product judgment

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable codebase; invalidated if gemServiceKeyAuth.ts or connect.award_gems are modified before planning starts)
