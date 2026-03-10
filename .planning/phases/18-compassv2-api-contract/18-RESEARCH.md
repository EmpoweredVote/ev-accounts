# Phase 18: CompassV2 API Contract - Research

**Researched:** 2026-03-10
**Domain:** Express/TypeScript API contract — auth middleware, schema migration, guest state migration, API documentation
**Confidence:** HIGH (all findings from direct codebase inspection)

## Summary

This phase is a precision API contract alignment job against a well-understood existing codebase. Every piece of this phase touches live, working code with established patterns. The risk is not unknown-unknowns — it is surgical correctness: wrong CHECK constraint bounds, partial atomicity in guest migration, or a missing field at the response root will silently break CompassV2.

The key changes are: (1) `optionalAuth` swap on five compass routes that currently use `requireAuth`, (2) `guest_state` field added to `POST /api/auth/signup` with an atomic RPC for migration, (3) `compass_responses.value` column type change from `INT CHECK (1–5)` to `NUMERIC(3,1) CHECK (0.5–5.5)`, (4) `completed_onboarding: boolean` promoted to the root of `GET /api/account/me`, (5) `GET /api/admin/me` response already returns `{ isAdmin, id, email }` — CV2-05 is already satisfied, (6) Bearer token auth already works for all routes — CV2-01 is already satisfied. The authMiddleware (`requireAuth`) reads `Authorization: Bearer` exclusively; there is no cookie auth path.

**Primary recommendation:** Read the current code precisely before writing a single line. Several requirements are already met; several others require careful schema + RPC changes. The guest state migration RPC is the highest-risk task and must be designed atomically.

---

## Standard Stack

No new libraries needed. All tools required are already in use.

### Core (already installed)
| Tool | Purpose | Already Used In |
|------|---------|-----------------|
| `zod` | Request body validation including `guest_state` shape | auth.ts, compass.ts, account.ts |
| `supabaseAdmin.rpc()` | Atomic RPC calls | compass.ts (`upsert_compass_answer`), account.ts (`calculate_level`) |
| `SECURITY DEFINER` PL/pgSQL | Atomic multi-table writes | migrations 025, 027, 028, 029 |
| `NUMERIC(3,1)` | Postgres type for decimal values | New in this phase |

### No new dependencies required
This phase is pure codebase changes: route middleware swaps, a new schema migration, a new RPC function, and a documentation file. `npm install` is not needed.

---

## Architecture Patterns

### Existing Pattern: Auth Middleware Swap
The codebase already has both `requireAuth` and `optionalAuth` implemented in `backend/src/middleware/auth.ts`. Both verify Bearer JWTs. `optionalAuth` attaches userId if token is valid but never sends 401 — it silently proceeds as unauthenticated on missing or invalid token.

**Current state of target routes:**
- `GET /api/compass/answers` — `requireAuth` → **must change to `optionalAuth`**
- `POST /api/compass/answers/batch` — `requireAuth` → **must change to `optionalAuth`**
- `GET /api/compass/selected-topics` — `requireAuth` → **must change to `optionalAuth`**
- `PUT /api/compass/selected-topics` — `requireAuth` → **must change to `optionalAuth`**
- `POST /api/compass/answers` — `requireAuth` → **must change to `optionalAuth`**
- `GET /api/compass/topics` — already `optionalAuth` (no change needed)
- `GET /api/compass/categories` — already `optionalAuth` (no change needed)
- `GET /api/compass/politicians` — already `optionalAuth` (no change needed)
- `GET /api/compass/politicians/:id/answers` — already `optionalAuth` (no change needed)

**After middleware change:** Each route handler must check `(req as AuthenticatedRequest).userId` — if undefined, return empty array or null (not an error). The pattern is:
```typescript
const authReq = req as AuthenticatedRequest;
if (!authReq.userId) {
  res.status(200).json([]); // or {} or { topic_ids: [] }
  return;
}
// ... existing authenticated logic
```

**Important caveat for `PUT /compass/selected-topics` and `POST /compass/answers`:** These are write routes. An unauthenticated user calling them should get an empty/null response gracefully, not a write attempt. The handler must short-circuit before any DB write if userId is absent.

### Existing Pattern: Atomic RPC
The codebase uses `adminRpc('function_name', params)` from `backend/src/lib/supabase.ts` for all SECURITY DEFINER RPC calls. The `upsert_compass_answer` RPC in `backend/migrations/025_rpc_pool_migration.sql` is the direct model for the new `migrate_guest_compass_state` RPC.

**The guest state migration RPC must:**
1. Accept `p_user_id uuid`, `p_answers jsonb`, `p_selected_topics uuid[]`
2. For each answer in `p_answers`: INSERT INTO `inform.compass_responses` ON CONFLICT DO NOTHING (never overwrite; this handles the case where a user has somehow already answered)
3. Also insert into `compass_change_history` for each answer inserted (not skipped)
4. If `p_selected_topics` is non-empty and user has a `connected_profiles` row: UPDATE `selected_topic_ids`
5. Entire function is `SECURITY DEFINER`, `SET search_path = ''`, wrapped in PL/pgSQL so it is one atomic unit

**Call site:** In `POST /api/auth/signup`, after `signUpWithEmail` returns `data.user`, call `adminRpc('migrate_guest_compass_state', { p_user_id: data.user.id, p_answers: guestAnswers, p_selected_topics: guestTopics })`. This is async and must be awaited before the 201 response.

**Important constraint:** `POST /api/auth/signup` currently uses the `authLimiter` (10 requests per 15 minutes). The `guest_state` addition is purely additive — no change to rate limiting is needed.

### Existing Pattern: Response Shape (GET /api/account/me)
Current `GET /api/account/me` in `backend/src/routes/account.ts` builds `meResponse` as an explicit whitelist object (never spread DB rows). The `completed_onboarding` field currently lives inside `connected_profile` only. The fix is additive: add it at root level as well.

**Current response shape (simplified):**
```typescript
meResponse = {
  id, email, display_name, avatar_url, tier, account_standing, created_at, updated_at,
  connected_profile: { ..., completed_onboarding: boolean, ... }  // only when tier === connected/empowered
}
```

**Required shape (phase 18):**
```typescript
meResponse = {
  id, email, display_name, avatar_url, tier, account_standing, created_at, updated_at,
  completed_onboarding: boolean,   // NEW: at root — from connected_profile if exists, else false
  connected_profile: { ..., completed_onboarding: boolean, ... }  // unchanged
}
```

**Rule:** Inform-tier users (no `connected_profiles` row) get `completed_onboarding: false` at root. The same change must be made in `PATCH /api/account/me` since it returns the identical shape.

### Existing Pattern: Schema Migration Numbering
Migrations in `backend/migrations/` use the pattern `0NN_description.sql`. The last migration is `029_compass_admin_rpcs.sql`. New migrations for this phase: `030_decimal_compass_values.sql`.

The `supabase/migrations/` directory has a parallel set with timestamp prefixes — only `backend/migrations/` is actively maintained for the pool-based migration runner.

### NUMERIC(3,1) Column Type Change
The `value` column on `inform.compass_responses` is currently `INT NOT NULL CHECK (value BETWEEN 1 AND 5)`. The migration must:
1. `ALTER TABLE inform.compass_responses ALTER COLUMN value TYPE NUMERIC(3,1)` — existing integer data (1, 2, 3, 4, 5) is implicitly cast to NUMERIC and stored as 1.0, 2.0, etc. This is safe in Postgres.
2. `ALTER TABLE inform.compass_responses DROP CONSTRAINT` on the old check (Postgres auto-names it, check with `\d inform.compass_responses`).
3. `ALTER TABLE inform.compass_responses ADD CONSTRAINT compass_responses_value_check CHECK (value >= 0.5 AND value <= 5.5)`
4. `compass_stances.value` stays `INT CHECK (1–5)` — no change needed.

**For `compass_change_history`:** The `old_value` and `new_value` columns are currently `INT`. Per Claude's Discretion, update these to `NUMERIC(3,1)` for consistency. The migration should also update the `upsert_compass_answer` RPC to accept `p_value NUMERIC(3,1)` instead of `p_value int`.

**For the `upsert_compass_answer` RPC:** The function signature in `025_rpc_pool_migration.sql` declares `p_value int`. After the column type change, passing a decimal value (e.g., 1.5) will fail with a type error. The RPC must be updated with `CREATE OR REPLACE FUNCTION` to change `p_value int` → `p_value numeric`. This goes in the same migration as the column type change.

### Zod Schema Update (POST /compass/answers)
The current `postAnswerSchema` in `compass.ts` validates:
```typescript
value: z.number().int().min(1).max(5)
```
This must change to:
```typescript
value: z.number().multipleOf(0.5).min(0.5).max(5.5)
```
Note: `z.number().multipleOf(0.5)` validates that the value is a multiple of 0.5. This correctly accepts 1, 1.5, 2, 2.5, etc. while rejecting 1.3 or 2.7.

**Also for the admin route** in `admin.ts`, the `PoliticianAnswersSchema` uses `value: z.number().int().min(1).max(5)` — politician answers stay INT (stances are always whole numbers), so that schema is NOT changed.

### CV2-01: Already Satisfied
The `requireAuth` middleware in `backend/src/middleware/auth.ts` reads `Authorization: Bearer <token>` exclusively. There is no session cookie path. All authenticated routes already work with Bearer tokens. CV2-01 requires no code changes.

### CV2-05: Already Substantially Satisfied
`GET /api/admin/me` at line 74 of `admin.ts` calls `getAdminMe(userId)` which returns `{ isAdmin: true, id: userId, email: data.user?.email ?? '' }`. This already includes `id` and `email`. CV2-05 is fully met with no changes needed.

### COMPASS_CONTRACT.md Location
Per decisions: repo root or `/docs/`. Recommendation: `/docs/COMPASS_CONTRACT.md`. The repo root already has several `.md` files (DEPLOY.md, empowered-accounts-integration-guide.md) and adding another there is consistent. However, a `/docs/` folder keeps contract docs organized — create it.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic guest state migration | JS loop with multiple awaited inserts | Single SECURITY DEFINER RPC | Partial failure leaves orphan answers — breaks the "never redo compass" promise |
| NUMERIC type validation in Zod | Custom `.refine()` checking modulo | `z.number().multipleOf(0.5)` | Zod has built-in multipleOf; hand-rolled version misses floating point edge cases |
| Column type migration | JS data migration script | Postgres `ALTER COLUMN ... TYPE` with implicit cast | Postgres handles INT → NUMERIC safely; no data movement needed |

**Key insight:** This phase's hardest problem is atomicity in guest state migration. Every other task is a precise local change. The RPC is the only place where "almost correct" causes real user harm (lost compass data on signup).

---

## Common Pitfalls

### Pitfall 1: `optionalAuth` on Write Routes Without Short-Circuit
**What goes wrong:** Change `POST /compass/answers` to `optionalAuth` but forget to add `if (!authReq.userId) { res.status(200).json(null); return; }` — the handler proceeds to call `adminRpc('upsert_compass_answer', { p_user_id: undefined, ... })` which writes a row with NULL user_id, violating the FK constraint.
**Why it happens:** Route handler assumes userId is always set because it used to use `requireAuth`.
**How to avoid:** Every route that changes from `requireAuth` to `optionalAuth` must add explicit userId check as the first line of the handler body.
**Warning signs:** Postgres FK violation error in logs when testing unauthenticated POST.

### Pitfall 2: `GET /compass/selected-topics` Returns 403 for Unauthenticated
**What goes wrong:** Change middleware to `optionalAuth` but the handler still checks `if (!data)` after the DB query and returns `403 NOT_CONNECTED` — which is wrong for an unauthenticated user. They should get `{ topic_ids: [] }` or similar, not a 403.
**Why it happens:** The 403 logic was designed for authenticated users without a connected_profile row. Unauthenticated users never have a connected_profile.
**How to avoid:** Short-circuit before DB query if `!authReq.userId`, return `{ topic_ids: [] }`.

### Pitfall 3: Guest State Migration Fails Silently
**What goes wrong:** `migrate_guest_compass_state` RPC fails (e.g., because a topic_id in `guest_state.answers` is invalid), but the signup route has already returned 201 with the new user ID. The user's account exists but their compass answers are lost.
**Why it happens:** RPC error is not surfaced — `guest_state` migration treated as "non-fatal" when it should be "best effort but logged."
**How to avoid:** The decision says migration is atomic (all or nothing), but signup itself should still succeed even if migration fails. Best approach: wrap the RPC call in try/catch, log the error prominently on failure, but still return 201. The user can re-enter answers — this is better than failing signup. The RPC's atomicity ensures no partial state.
**Warning sign:** Test case: invalid topic_id in guest_state should not fail signup but should log an error.

### Pitfall 4: `upsert_compass_answer` RPC Signature Not Updated
**What goes wrong:** Schema migration changes `compass_responses.value` to `NUMERIC(3,1)` but the RPC function still declares `p_value int`. A write of value `1.5` causes: `ERROR: invalid input value for type integer: "1.5"`.
**Why it happens:** The RPC function signature is in `backend/migrations/025_rpc_pool_migration.sql` (already applied to DB). The fix must be a new migration with `CREATE OR REPLACE FUNCTION` to update the signature.
**How to avoid:** Migration 030 must include both the column type change AND the `CREATE OR REPLACE FUNCTION public.upsert_compass_answer(p_value numeric, ...)` update in the same transaction.

### Pitfall 5: Zod's `multipleOf` with Floating Point
**What goes wrong:** `z.number().multipleOf(0.5)` may exhibit floating point imprecision for values like 2.5 (2.5 % 0.5 === 0 but 0.1 % 0.1 is sometimes not exactly 0 in JS).
**Why it happens:** IEEE 754 floating point arithmetic.
**How to avoid:** Test explicitly: `z.number().multipleOf(0.5).min(0.5).max(5.5)` — Zod internally uses a tolerance comparison for `multipleOf` which handles common half-step values correctly. Verify with test cases for all valid values (0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5) and a few invalid ones (1.3, 0.3, 5.7).

### Pitfall 6: `completed_onboarding` Missing from PATCH /me Response
**What goes wrong:** Add `completed_onboarding` at root of GET /me but forget PATCH /me — which builds the same response shape. CompassV2 might call PATCH and get back a response without the field.
**Why it happens:** Two handlers in `account.ts` build the same response shape — easy to update one and miss the other.
**How to avoid:** Both `GET /me` and `PATCH /me` have identical response-building logic. Both must be updated. Consider extracting to a shared `buildMeResponse()` helper function (this avoids the duplication problem permanently).

### Pitfall 7: CORS Not Including CompassV2 Domain
**What goes wrong:** CompassV2 origin is not in `CORS_ORIGIN` env var on production — all cross-origin requests fail with CORS error.
**Why it happens:** Adding a new frontend consumer means adding its origin to production env vars.
**How to avoid:** COMPASS_CONTRACT.md should document that the CompassV2 domain must be added to the `CORS_ORIGIN` environment variable on the accounts server. This is an ops task, not a code task. For development, `CORS_ORIGIN` is `*` which allows all origins.

---

## Code Examples

### optionalAuth Short-Circuit Pattern
```typescript
// Source: direct codebase analysis (middleware/auth.ts + existing compass.ts patterns)
router.get('/answers', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;

  if (!authReq.userId) {
    res.status(200).json([]);
    return;
  }

  // ... existing authenticated logic unchanged
});
```

### guest_state Zod Schema for POST /api/auth/signup
```typescript
// Source: direct codebase analysis (auth.ts existing patterns)
const guestAnswerSchema = z.object({
  topic_id: z.string().uuid(),
  value: z.number().multipleOf(0.5).min(0.5).max(5.5),
  write_in_text: z.string().max(500).optional(),
});

const authBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  guest_state: z.object({
    answers: z.array(guestAnswerSchema).max(200),
    selected_topics: z.array(z.string().uuid()).max(50),
  }).optional(),
});
```

### completed_onboarding at Root of /api/account/me
```typescript
// Source: direct codebase analysis (account.ts lines 106-116)
const meResponse: Record<string, unknown> = {
  id: user.id,
  email: authUser.email,
  display_name: user.display_name,
  avatar_url: user.avatar_url,
  tier,
  ...(empowerment_status !== undefined && { empowerment_status }),
  account_standing: connected?.account_standing ?? 'active',
  completed_onboarding: connected?.completed_onboarding ?? false,  // NEW line
  created_at: user.created_at,
  updated_at: user.updated_at,
};
```

### NUMERIC Migration Pattern
```sql
-- Source: direct codebase analysis (migration 026 ALTER patterns)
BEGIN;

-- 1. Drop old check constraint (find exact name with \d inform.compass_responses)
ALTER TABLE inform.compass_responses
  DROP CONSTRAINT IF EXISTS compass_responses_value_check;

-- 2. Change column type (implicit cast: INT → NUMERIC is lossless)
ALTER TABLE inform.compass_responses
  ALTER COLUMN value TYPE NUMERIC(3,1);

-- 3. Add new check constraint
ALTER TABLE inform.compass_responses
  ADD CONSTRAINT compass_responses_value_check
  CHECK (value >= 0.5 AND value <= 5.5);

-- 4. Update change_history columns (Claude's Discretion: yes, update for consistency)
ALTER TABLE inform.compass_change_history
  ALTER COLUMN old_value TYPE NUMERIC(3,1),
  ALTER COLUMN new_value TYPE NUMERIC(3,1);

-- 5. Update upsert_compass_answer RPC to accept numeric
CREATE OR REPLACE FUNCTION public.upsert_compass_answer(
  p_user_id uuid,
  p_topic_id uuid,
  p_value numeric,  -- changed from int
  p_write_in_text text DEFAULT NULL,
  p_inverted boolean DEFAULT false
)
-- ... rest of function body unchanged, except v_old_value and v_result types
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
...

COMMIT;
```

### migrate_guest_compass_state RPC Skeleton
```sql
-- Source: pattern from public.upsert_compass_answer (migration 025)
CREATE OR REPLACE FUNCTION public.migrate_guest_compass_state(
  p_user_id uuid,
  p_answers jsonb,       -- array of {topic_id, value, write_in_text?}
  p_selected_topics uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_answer jsonb;
  v_topic_id uuid;
  v_value numeric;
  v_write_in_text text;
  v_migrated_count int := 0;
BEGIN
  -- Insert answers — ON CONFLICT DO NOTHING preserves any answers user
  -- may have already saved (safe to call multiple times)
  FOR v_answer IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    v_topic_id    := (v_answer->>'topic_id')::uuid;
    v_value       := (v_answer->>'value')::numeric;
    v_write_in_text := v_answer->>'write_in_text'; -- NULL if absent

    INSERT INTO inform.compass_responses
      (user_id, topic_id, value, write_in_text, updated_at)
    VALUES
      (p_user_id, v_topic_id, v_value, v_write_in_text, now())
    ON CONFLICT (user_id, topic_id) DO NOTHING;

    IF FOUND THEN
      -- Only log to change_history when an insert actually happened
      INSERT INTO inform.compass_change_history
        (user_id, topic_id, old_value, new_value)
      VALUES
        (p_user_id, v_topic_id, NULL, v_value);
      v_migrated_count := v_migrated_count + 1;
    END IF;
  END LOOP;

  -- Save selected topics if provided and user has connected_profiles row
  IF array_length(p_selected_topics, 1) > 0 AND
     EXISTS (SELECT 1 FROM connect.connected_profiles WHERE user_id = p_user_id)
  THEN
    UPDATE connect.connected_profiles
      SET selected_topic_ids = to_jsonb(p_selected_topics),
          updated_at = now()
      WHERE user_id = p_user_id;
  END IF;

  RETURN jsonb_build_object('migrated_count', v_migrated_count);
END;
$$;
```

---

## State of the Art

| Old Approach | Current Approach | Phase | Impact |
|---|---|---|---|
| `requireAuth` on all compass routes | `optionalAuth` on answer/selected-topics routes | Phase 18 | Anonymous compass usage; no 401 for guests |
| `INT CHECK (1–5)` on compass_responses.value | `NUMERIC(3,1) CHECK (0.5–5.5)` | Phase 18 | Write-in answers can express "between" stances |
| `completed_onboarding` inside `connected_profile` only | Also at root of `/api/account/me` | Phase 18 | CompassV2 can read without traversing nested object |
| No guest state on signup | Optional `guest_state` field on POST /signup | Phase 18 | Seamless anonymous → connected migration |

**Already satisfied (no changes needed):**
- CV2-01: Bearer token auth — `requireAuth` is Bearer-only, no cookies. Done.
- CV2-05: `GET /api/admin/me` returns `{ isAdmin, id, email }`. Done.

---

## Open Questions

1. **Exact name of the old CHECK constraint on `compass_responses.value`**
   - What we know: The constraint was created in migration 015 (supabase) and 026 (backend). Postgres auto-names it based on table and column, likely `compass_responses_value_check`.
   - What's unclear: The exact constraint name in the live production database (it was created by migration 015 which was already applied).
   - Recommendation: The migration should use `DROP CONSTRAINT IF EXISTS compass_responses_value_check` and also add a fallback: `ALTER TABLE inform.compass_responses DROP CONSTRAINT IF EXISTS compass_responses_value_check1` (in case Postgres suffixed it). Alternatively, query `pg_constraint` to confirm the name in the live DB before running. The safest approach: use `ALTER TABLE ... DROP CONSTRAINT IF EXISTS` with the expected name; if migration fails in CI, adjust name.

2. **`migrate_guest_compass_state` topic_id validation**
   - What we know: `upsert_compass_answer` raises `TOPIC_NOT_FOUND` if the topic is missing or not live.
   - What's unclear: Should `migrate_guest_compass_state` silently skip invalid topic_ids (ON CONFLICT DO NOTHING handles duplicate user/topic but not invalid topic FK) or raise an error?
   - Recommendation: The RPC should let the FK constraint handle invalid `topic_id` values — if a topic_id doesn't exist, the INSERT fails with a FK violation which Postgres raises. Catch with `EXCEPTION WHEN foreign_key_violation THEN` and skip that answer (log it), continuing the rest. This prevents one bad topic_id from aborting the entire migration.

3. **CORS_ORIGIN for CompassV2 on production**
   - What we know: `CORS_ORIGIN` is a comma-separated env var, `*` in dev. CompassV2 will be on a different domain (likely compassv2.empoweredvote.com or similar).
   - What's unclear: The exact CompassV2 production URL (it's Chris Andrews' domain, not this repo).
   - Recommendation: Document in COMPASS_CONTRACT.md that the CompassV2 domain must be in CORS_ORIGIN. Note in the deployment checklist that this is an ops step.

---

## Sources

### Primary (HIGH confidence)
All findings are from direct codebase inspection — no external library documentation needed for this phase.

- `backend/src/middleware/auth.ts` — `requireAuth` and `optionalAuth` implementations, Bearer-only auth confirmed
- `backend/src/routes/compass.ts` — all compass route handlers, current middleware assignments
- `backend/src/routes/auth.ts` — current `POST /signup` handler, `authBodySchema`, `signUpWithEmail` usage
- `backend/src/routes/account.ts` — `GET /api/account/me` response shape, `connected_profile` structure
- `backend/src/routes/admin.ts` — `GET /api/admin/me` handler, confirms CV2-05 already met
- `backend/src/lib/adminService.ts` — `getAdminMe()` returns `{ isAdmin, id, email }`, confirms CV2-05 done
- `backend/migrations/025_rpc_pool_migration.sql` — `upsert_compass_answer` RPC, `p_value int` signature
- `backend/migrations/026_inform_schema_repair_and_candidates.sql` — `compass_responses.value INT CHECK (1–5)` confirmed, `deleted_at` column pattern
- `backend/src/index.ts` — CORS config, all route mounts

---

## Metadata

**Confidence breakdown:**
- What's already done (CV2-01, CV2-05): HIGH — confirmed by direct code read
- optionalAuth middleware swap: HIGH — pattern exists and is used; change is mechanical
- `completed_onboarding` at root: HIGH — additive field, existing pattern
- NUMERIC column migration: HIGH — standard Postgres INT→NUMERIC cast; well-understood
- `upsert_compass_answer` RPC update: HIGH — `CREATE OR REPLACE` pattern used throughout
- Guest state migration RPC: MEDIUM — new RPC, complex logic, edge cases in topic FK handling
- COMPASS_CONTRACT.md: HIGH — documentation task with clear inputs from codebase
- CHECK constraint name: MEDIUM — likely `compass_responses_value_check` but unverified against live DB

**Research date:** 2026-03-10
**Valid until:** 2026-04-10 (stable codebase, no external dependencies)
