---
phase: quick-004
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - backend/src/routes/vq.ts
  - backend/src/lib/vqService.ts
  - tests/integration/vq.test.ts
  - docs/ONBOARDING-VQ.md
autonomous: true

must_haves:
  truths:
    - "VQ service can POST /api/vq/adjust-vr with a user_id, delta, and idempotency_key to adjust a user's verification_rating"
    - "VR is clamped to [0, 100] after adjustment (not 150 like confirm-stance — Yellow quests use normal range)"
    - "When VR hits 0, vq_hold_until is set to now + 30 days"
    - "Duplicate idempotency_key returns the original result with replayed: true"
    - "Auth requires VQ_SERVICE_KEY via X-Service-Key header (same gemServiceKey middleware, no gem type check needed)"
  artifacts:
    - path: "backend/src/routes/vq.ts"
      provides: "POST /api/vq/adjust-vr route handler"
    - path: "backend/src/lib/vqService.ts"
      provides: "adjustVerificationRating service function"
    - path: "tests/integration/vq.test.ts"
      provides: "Auth rejection + validation tests for adjust-vr"
  key_links:
    - from: "backend/src/routes/vq.ts"
      to: "backend/src/lib/vqService.ts"
      via: "adjustVerificationRating function call"
    - from: "backend/src/lib/vqService.ts"
      to: "connect.connected_profiles"
      via: "pool.query UPDATE with VR clamping"
    - from: "backend/src/lib/vqService.ts"
      to: "connect.vq_confirmation_results"
      via: "Idempotency cache read/write via pool.query"
---

<objective>
Implement POST /api/vq/adjust-vr — a service-to-service endpoint that allows Validation Quests to apply a verification_rating delta to a user after Yellow quest immediate grading (correct/incorrect). Simpler than confirm-stance: no gems, no politician stance upsert, just VR adjustment with idempotency.

Purpose: Yellow quests grade immediately (unlike Red quests that wait for resolution). VQ needs to adjust VR on the spot without the full confirm-stance ceremony.
Output: Working endpoint with auth, validation, idempotency, clamping, vq_hold enforcement, and integration tests.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@backend/src/routes/vq.ts
@backend/src/lib/vqService.ts
@backend/src/middleware/gemServiceKeyAuth.ts
@backend/src/lib/db.js
@tests/integration/vq.test.ts
@supabase/migrations/20260315000038_phase28_vq_confirm_stance.sql
</context>

<tasks>

<task type="auto">
  <name>Task 1: Implement adjust-vr service function and route</name>
  <files>backend/src/lib/vqService.ts, backend/src/routes/vq.ts</files>
  <action>
**In `backend/src/lib/vqService.ts`:**

1. Import `pool` from `./db.js` (same pattern as connectService, adminService, etc.).

2. Add types:
```typescript
export interface AdjustVrParams {
  userId: string;
  delta: number;       // positive or negative integer
  idempotencyKey: string;
  reason?: string;     // optional context (e.g., "yellow_quest_correct", "yellow_quest_incorrect")
}

export interface AdjustVrResult {
  user_id: string;
  old_rating: number;
  new_rating: number;
  delta_applied: number;  // actual delta after clamping (may differ from requested)
  vq_hold_set: boolean;   // true if vq_hold_until was set/reset because rating hit 0
  replayed?: boolean;
}
```

3. Add `adjustVerificationRating` function:
   - **Idempotency pre-check**: `SELECT result_json FROM connect.vq_confirmation_results WHERE idempotency_key = $1`. If found, return parsed result with `replayed: true`. Reuse the existing `vq_confirmation_results` table — it is a general idempotency cache for VQ operations.
   - **Read current VR**: `SELECT verification_rating, vq_hold_until FROM connect.connected_profiles WHERE user_id = $1 FOR UPDATE` via `pool.query`. If no row, throw error with `code: 'USER_NOT_FOUND'`.
   - **Compute new rating**: `Math.max(0, Math.min(100, currentRating + delta))`. Note: 100 cap for Yellow quests (not 150 like Red quest confirm-stance). Compute `deltaApplied = newRating - currentRating`.
   - **Determine vq_hold**: If `newRating === 0`, set `vq_hold_until = NOW() + INTERVAL '30 days'`. Otherwise leave it unchanged.
   - **Update**: `UPDATE connect.connected_profiles SET verification_rating = $1, vq_hold_until = CASE WHEN $2 = 0 THEN NOW() + INTERVAL '30 days' ELSE vq_hold_until END WHERE user_id = $3` via `pool.query`.
   - **Cache result**: `INSERT INTO connect.vq_confirmation_results (idempotency_key, result_json) VALUES ($1, $2)` via `pool.query`.
   - **Return** the `AdjustVrResult` object.
   - All queries should be in a single transaction: `BEGIN` / `COMMIT` / `ROLLBACK` on error. Use `const client = await pool.connect(); try { await client.query('BEGIN'); ... await client.query('COMMIT'); } catch { await client.query('ROLLBACK'); throw; } finally { client.release(); }`.
   - CRITICAL: Use `pool.query` (direct postgres), NOT PostgREST — non-public schema writes fail via PostgREST (see MEMORY.md critical production pattern).

**In `backend/src/routes/vq.ts`:**

1. Import `adjustVerificationRating` from `../lib/vqService.js`.

2. Add Zod schema:
```typescript
const AdjustVrBodySchema = z.object({
  user_id: z.string().uuid(),
  delta: z.number().int().min(-100).max(100),  // reasonable bounds
  idempotency_key: z.string().min(1).max(255),
  reason: z.string().max(255).optional(),
});
```

3. Add route `POST /adjust-vr` using `requireGemServiceKey` middleware (same auth as confirm-stance — VQ_SERVICE_KEY is in GEMS_SERVICE_KEYS map). No gem type permission check needed (this endpoint does not award gems). The route:
   - Validates body with Zod schema, returns 422 on failure.
   - Calls `adjustVerificationRating(body)`.
   - Returns 200 with result.
   - Catches `USER_NOT_FOUND` error, returns 404.
   - Catches all other errors, logs and returns 500.
  </action>
  <verify>
Run `npx tsc --noEmit` from `backend/` — no type errors. Visually confirm route is registered and reachable (vq router is already mounted at `/api/vq` in index.ts, so the new route will be at `/api/vq/adjust-vr`).
  </verify>
  <done>
POST /api/vq/adjust-vr compiles, is wired into the existing vq router, uses pool.query for all connect schema writes, clamps VR to [0,100], handles idempotency via vq_confirmation_results, and sets vq_hold_until when VR hits 0.
  </done>
</task>

<task type="auto">
  <name>Task 2: Add integration tests and update VQ onboarding doc</name>
  <files>tests/integration/vq.test.ts, docs/ONBOARDING-VQ.md</files>
  <action>
**In `tests/integration/vq.test.ts`:**

Add a new `describe('POST /api/vq/adjust-vr')` block with these tests (no live DB needed — auth/validation only):

1. **401 without X-Service-Key header** — POST to `/api/vq/adjust-vr` with valid body but no auth header. Expect 401.

2. **401 with invalid service key** — POST with `X-Service-Key: bad-key`. Expect 401.

3. **422 on missing required fields** — POST with valid auth but empty body. Expect 422 with `VALIDATION_ERROR`.

4. **422 on invalid delta** — POST with `delta: 999` (exceeds max 100). Expect 422.

5. **422 on non-UUID user_id** — POST with `user_id: "not-a-uuid"`. Expect 422.

Use `TEST_VQ_KEY` for valid auth (already set up in the test file's env setup — it has `['yellow', 'blue', 'red']` permissions). Use `X-Service-Key` header (not Authorization Bearer — match the actual middleware pattern from gemServiceKeyAuth.ts which reads `req.headers['x-service-key']`).

**In `docs/ONBOARDING-VQ.md`:**

Add a new section after "Stance Confirmation" (before "Reading User State") documenting the adjust-vr endpoint:

```markdown
## Verification Rating Adjustment (Yellow Quests)

For Yellow quest immediate grading, use this lighter endpoint to adjust a user's
verification_rating without the full stance confirmation ceremony (no gems, no
politician stance upsert).

### Endpoint

\```
POST /api/vq/adjust-vr
X-Service-Key: <VQ_SERVICE_KEY>
Content-Type: application/json
\```

### Request Body

| Field | Type | Required | Constraints | Notes |
|-------|------|----------|-------------|-------|
| `user_id` | string (UUID) | Yes | Valid UUID | The user whose VR is being adjusted |
| `delta` | number | Yes | Integer -100 to 100 | Positive = correct, negative = incorrect |
| `idempotency_key` | string | Yes | max 255 chars | Unique per grading event |
| `reason` | string | No | max 255 chars | Context string (e.g., "yellow_quest_correct") |

### Response (200)

\```typescript
interface AdjustVrResult {
  user_id: string;
  old_rating: number;
  new_rating: number;
  delta_applied: number;  // actual delta after clamping (may differ from requested)
  vq_hold_set: boolean;   // true if vq_hold_until was set because rating hit 0
  replayed?: boolean;      // present and true on idempotent replay
}
\```

### Side Effects

- VR clamped to [0, 100] (Yellow quest range, not the [0, 150] Red quest range)
- If VR reaches 0, `vq_hold_until` is set to now + 30 days
- On idempotent replay: no writes, original result returned with `replayed: true`

### Error Responses

| Status | Body | Cause |
|--------|------|-------|
| 401 | `{ "error": "Missing or invalid X-Service-Key" }` | Bad or missing key |
| 404 | `{ "error": "USER_NOT_FOUND" }` | No connected_profile for this user_id |
| 422 | `{ "error": "VALIDATION_ERROR", "issues": [...] }` | Zod validation failure |
```

Also update the "Two separate keys" note near the top to mention adjust-vr:
- `VQ_SERVICE_KEY` — for `POST /api/vq/confirm-stance` and `POST /api/vq/adjust-vr`

And add a row to the "What Accounts Provides" table:
| VR adjustment (Yellow quests) | Accounts | `POST /api/vq/adjust-vr` with service key |
  </action>
  <verify>
Run `npx vitest run tests/integration/vq.test.ts` — all tests pass (existing confirm-stance tests + new adjust-vr tests). Check that ONBOARDING-VQ.md has the new section with correct endpoint path and field documentation.
  </verify>
  <done>
5 new integration tests cover auth rejection and validation for adjust-vr. ONBOARDING-VQ.md documents the endpoint contract so VQ developers know how to call it.
  </done>
</task>

</tasks>

<verification>
1. `npx tsc --noEmit` in backend/ — no type errors
2. `npx vitest run tests/integration/vq.test.ts` — all tests pass
3. Manual check: `grep -n 'adjust-vr' backend/src/routes/vq.ts` confirms route exists
4. Manual check: `grep -n 'adjustVerificationRating' backend/src/lib/vqService.ts` confirms service function exists
5. Manual check: docs/ONBOARDING-VQ.md contains "adjust-vr" section
</verification>

<success_criteria>
- POST /api/vq/adjust-vr exists, authenticates via VQ_SERVICE_KEY (gemServiceKey middleware)
- VR delta applied with clamping to [0, 100]
- vq_hold_until set when VR hits 0
- Idempotency via vq_confirmation_results table
- All writes use pool.query (not PostgREST)
- Integration tests pass for auth rejection and validation
- ONBOARDING-VQ.md documents the endpoint contract
</success_criteria>

<output>
After completion, create `.planning/quick/004-implement-post-api-vq-adjust-vr-endpoin/004-SUMMARY.md`
</output>
