---
phase: 66-inform-profiles-backend-foundation
type: research
date: 2026-04-27
---

# Phase 66 Research: Inform Profiles Backend Foundation

## What Was Investigated

1. Current `inform` schema tables — what exists, what is safe to add
2. DB trigger patterns in the codebase — how to auto-create `inform_profiles` rows
3. The `award_gems` / `awardGems` gem pipeline — exactly what needs to change for Inform-tier routing
4. Tier guard middleware — whether `requireInform` middleware is needed or can be composed inline
5. `signup_with_invite` RPC (migration 071) — exact current state and what atomic transfer requires
6. Migration sequencing and numbering
7. RLS posture on the `inform` schema

---

## Inform Schema: Current Tables

The `inform` schema already exists with the following tables (from migrations 026, 031, 038, 055, 061):

| Table | Created In | Notes |
|-------|-----------|-------|
| `inform.compass_categories` | 026 | |
| `inform.compass_topics` | 026 | |
| `inform.compass_topic_categories` | 026 | |
| `inform.compass_topic_roles` | 026 | |
| `inform.compass_stances` | 026 | |
| `inform.compass_responses` | 026 | Soft-delete via `deleted_at` |
| `inform.compass_change_history` | 026 | Immutable audit log |
| `inform.politicians` | 026 | |
| `inform.politician_answers` | 026 | |
| `inform.politician_context` | 026 | |
| `inform.district_boundaries` | 031 | RLS enabled |
| `inform.compass_verdicts` | 038 | RLS enabled |
| `inform.topic_rewrites` | 061 | |
| `inform.topic_rewrite_stance_proposals` | 061 | |

**`inform.inform_profiles` does not exist yet.** No name collision risk.

**RLS posture:** Most `inform` tables have no RLS (writes via SECURITY DEFINER only per migration 026 comments). Two tables (`district_boundaries`, `compass_verdicts`) have RLS enabled. The new `inform_profiles` table should follow the majority pattern: no RLS, all writes via SECURITY DEFINER, pool.query for all JS reads/writes.

---

## DB Trigger Pattern for IBAK-02

**Confirmed:** No existing migration creates an AFTER INSERT trigger on `public.users`. The codebase uses an explicit pattern: `connect.signup_with_invite` (SECURITY DEFINER RPC) creates the `connected_profiles` row manually, not via trigger. There is only one trigger pattern previously used (migration 055) — a BEFORE INSERT/UPDATE trigger on `inform.compass_topics` to derive `topic_key`.

**Recommended trigger approach for IBAK-02:**

```sql
-- Function: creates inform_profiles row, idempotent via ON CONFLICT DO NOTHING
CREATE OR REPLACE FUNCTION inform.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO inform.inform_profiles (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_create_inform_profile
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION inform.handle_new_user();
```

**Why AFTER INSERT (not BEFORE):** We only need the side-effect insert; the trigger does not modify the row. AFTER is correct for cross-table inserts.

**Why ON CONFLICT DO NOTHING:** The backfill script and the trigger can race on the first run. ON CONFLICT ensures idempotency — safe to run migration multiple times and safe if a row already exists.

**Backfill for existing users:** The migration must also INSERT INTO inform_profiles for all existing public.users rows:

```sql
INSERT INTO inform.inform_profiles (user_id)
SELECT id FROM public.users
ON CONFLICT (user_id) DO NOTHING;
```

This is a one-time backfill in the migration body, before the trigger is created. Existing users in production get their row immediately when the migration runs.

**Important:** In this Supabase project, `public.users` is a mirror table (populated from `auth.users` via a Supabase hook — the standard Supabase pattern). The trigger fires on `public.users` INSERT, which occurs when a new auth user is created. This covers both the Inform signup path (Phase 67, new `signup_inform` flow creates an auth user → public.users row → trigger fires) and the Connected signup path (existing `signup_with_invite` flow creates auth user → public.users row → trigger fires).

---

## Gem Award Routing: IBAK-04 Analysis

**Current `awardGems` flow (gemService.ts):**
1. Calls `connect.award_gems` SECURITY DEFINER RPC via `adminRpc()`
2. RPC checks `connect.connected_profiles` for the user (Step 5: `SELECT gem_balance_X FROM connect.connected_profiles WHERE user_id = $1 FOR UPDATE`)
3. If no row exists: `RAISE EXCEPTION 'User % has no connected_profiles row. Cannot award gems.'`
4. JS layer maps that message to `{ code: 'NOT_CONNECTED' }`
5. Route handler maps `NOT_CONNECTED` to HTTP 404

**What IBAK-04 requires:**
- `gem_type: "yellow"` + Inform-tier user → write to `inform_profiles.yellow_gem_balance`; return the same `AwardGemsResult` shape
- `gem_type: "blue"` or `"red"` + Inform-tier user → return HTTP 422

**Recommended approach: branch in `awardGems()` after a tier check via pool.query**

The `POST /api/gems/award` endpoint uses `requireGemServiceKey`, not `requireAuth` — there is no JWT in scope and no `req.userId` from auth middleware. The user identity comes from `body.user_id`. To determine if the user is Inform-tier:

```typescript
// In gemService.ts awardGems(), before calling adminRpc:
const { rows } = await pool.query(
  `SELECT EXISTS(SELECT 1 FROM connect.connected_profiles WHERE user_id = $1) AS is_connected`,
  [params.userId]
);
const isConnected = rows[0]?.is_connected === true;
```

Then branch:

```typescript
if (!isConnected) {
  // Inform-tier user
  if (params.gemType !== 'yellow') {
    throw Object.assign(new Error('Inform-tier users can only earn yellow gems'), {
      code: 'INFORM_TIER_NO_BLUE_RED',
    });
  }
  // Route to inform_profiles
  return await awardInformYellowGem(params);
}
// Connected+ path: existing award_gems RPC
```

**The `awardInformYellowGem` helper** must be a new SECURITY DEFINER RPC (`inform.award_inform_yellow_gem`) rather than raw pool.query UPDATE, because:
1. It requires idempotency (same idempotency key semantics as Connected gem awards)
2. It requires atomicity (advisory lock + balance update + idempotency record in one transaction)

**New RPC: `inform.award_inform_yellow_gem`**

The RPC mirrors `connect.award_gems` but writes to `inform.inform_profiles.yellow_gem_balance`. Idempotency can be stored on the `inform_profiles` table itself (by adding an `idempotency_keys` JSONB or a separate ledger table), or a simpler approach: add an `inform.inform_gem_events` table as a ledger. However, the simplest correct approach that matches the existing pattern:

Add a separate `inform.yellow_gem_events` table (idempotency ledger for Inform yellow gem awards):

```sql
CREATE TABLE inform.yellow_gem_events (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount           INTEGER     NOT NULL,
  idempotency_key  TEXT        NOT NULL,
  balance_after    INTEGER     NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_yellow_gem_events_idempotency_key
  ON inform.yellow_gem_events (idempotency_key);
```

The RPC then:
1. Validates gem_type = 'yellow' and amount > 0
2. Advisory lock on user_id
3. Idempotency pre-check on `yellow_gem_events`
4. SELECT FOR UPDATE on `inform_profiles.yellow_gem_balance`
5. UPDATE balance + INSERT ledger row
6. RETURN TABLE (same shape as `connect.award_gems`)

**Route handler update:** The existing `NOT_CONNECTED` catch in `gems.ts` route handler currently returns HTTP 404. Phase 66 must add handling for the new `INFORM_TIER_NO_BLUE_RED` error code → HTTP 422. The `NOT_CONNECTED` case may still occur if the user_id does not exist at all (no public.users row), which should remain 404.

---

## Tier Guard for IBAK-05: `requireInform` Middleware

**IBAK-05** requires `PATCH /api/account/location-hint` to:
- Allow Inform-tier users (no connected_profiles row)
- Return 403 for Connected-tier users (they have connected_profiles)

**Current `tierGuards.ts` exports:** `requireConnected` (blocks Inform, allows Connected+) and `requireEmpowered` (blocks non-Empowered).

**There is no `requireInform` middleware.** One must be added to `tierGuards.ts`:

```typescript
export async function requireInform(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authReq = req as AuthenticatedRequest;
  const { data } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .select('id')
    .eq('user_id', authReq.userId)
    .maybeSingle();

  if (data) {
    // User has a connected_profiles row — they are Connected+, not Inform
    res.status(403).json({ error: 'Inform-tier account required' });
    return;
  }
  next();
}
```

**Note:** `supabaseAdmin` is acceptable in `src/middleware/` — this is architecturally blessed per the existing comment in `tierGuards.ts` ("src/middleware/ is excluded by design" from the supabaseAdmin-in-routes ban).

**For `PATCH /api/account/location-hint`**, the middleware chain is: `requireAuth` + `requireInform`. The route writes to `inform.inform_profiles` via `pool.query()` (non-public schema, never PostgREST).

---

## signup_with_invite RPC Update: IBAK-06

**Current RPC state (migration 071):**
- Creates `connect.connected_profiles` row with `gem_balance_yellow` at DB default (0) — the column is not in the INSERT column list
- Does NOT read `inform_profiles.yellow_gem_balance`

**Required change for IBAK-06:**

Add a new migration (084) that is a `CREATE OR REPLACE FUNCTION connect.signup_with_invite(...)` replacement. Within the transaction:

After the `INSERT INTO connect.connected_profiles (...)` (Step 4), add:

```sql
-- Transfer yellow gem balance from inform_profiles to connected_profiles
DECLARE
  v_inform_balance INTEGER;
BEGIN
  -- Read and zero out inform_profiles balance atomically
  UPDATE inform.inform_profiles
  SET yellow_gem_balance = 0
  WHERE user_id = p_user_id
  RETURNING yellow_gem_balance INTO v_inform_balance;
  -- v_inform_balance holds the OLD value before the zero-out
```

Wait — `RETURNING` gives the new value after the update (0 in this case), not the old value. The correct atomic pattern:

```sql
-- Read current balance first (within the same transaction, before zeroing)
SELECT yellow_gem_balance INTO v_inform_balance
FROM inform.inform_profiles
WHERE user_id = p_user_id
FOR UPDATE;  -- Lock the row to prevent concurrent award

-- Zero out inform balance
UPDATE inform.inform_profiles
SET yellow_gem_balance = 0
WHERE user_id = p_user_id;
```

Then insert into connected_profiles with the transferred balance:

```sql
INSERT INTO connect.connected_profiles (
  user_id, legal_name, display_name, account_standing,
  verification_status, verification_method, total_xp,
  completed_onboarding, gem_balance_yellow
) VALUES (
  p_user_id, p_legal_name, p_display_name, 'active',
  'verified', 'invite', 0, false,
  COALESCE(v_inform_balance, 0)
);
```

**Important:** `v_inform_balance` may be NULL if the trigger didn't fire (e.g., the user signed up before migration 084 ran and backfill also somehow didn't create the row). `COALESCE(v_inform_balance, 0)` is the safe default.

**Full transaction is already in a SECURITY DEFINER function with implicit BEGIN/END.** The SELECT FOR UPDATE + UPDATE + INSERT are all atomic within the PL/pgSQL block — correct behavior, no chained JS awaits needed.

---

## GET /api/account/me: IBAK-03

**Current response shape** (source: `backend/src/routes/account.ts` lines 175–235):
- No `inform_profile` key exists yet
- Tier-detection logic already handles `'inform'` tier (line 83)
- Connected-tier and Empowered-tier get their respective nested objects; Inform users get neither

**What to add:** After tier detection (line 83), add a `pool.query` to read `inform_profiles`:

```typescript
// Read inform_profile for ALL tiers (all users have an inform_profiles row after migration 084)
const { rows: informRows } = await pool.query<{
  yellow_gem_balance: number;
  last_essentials_location: unknown;
}>(
  `SELECT yellow_gem_balance, last_essentials_location
   FROM inform.inform_profiles WHERE user_id = $1`,
  [authReq.userId]
);
const informProfile = informRows[0] ?? null;
```

Then in the response object (line 175+):
```typescript
inform_profile: informProfile
  ? {
      yellow_gem_balance: informProfile.yellow_gem_balance ?? 0,
      last_essentials_location: informProfile.last_essentials_location ?? null,
    }
  : null,
```

**For Connected+ users:** Both `inform_profile` (yellow balance from inform_profiles) and `connected_profile.gems` (yellow from connected_profiles) are present. This is intentional — Connected users' yellow gem balance lives in `connected_profiles.gem_balance_yellow` after the IBAK-06 transfer. The `inform_profile.yellow_gem_balance` for Connected users will always be 0 (zeroed on connect). Having it in the response is fine — frontend can ignore or use as intended.

**Must use pool.query (not PostgREST):** `inform` schema is not in the PostgREST exposed schemas list — confirmed by the project architecture rule "All essentials reads AND writes must use pool.query()" (same exclusion applies to inform schema access from JS).

---

## Migration Structure

**Next migration number:** 084

**Recommended: two migrations**

| Migration | Content | Why Separate |
|-----------|---------|--------------|
| `084_inform_profiles.sql` | Table + index + backfill INSERT + trigger function + trigger | Core schema — can be verified standalone |
| `085_signup_with_invite_yellow_transfer.sql` | `CREATE OR REPLACE FUNCTION connect.signup_with_invite(...)` | RPC replacement — isolated, easy to audit |

**Why not one migration:** The table must exist before the RPC can reference it in `signup_with_invite`. Keeping them separate makes rollback reasoning cleaner and matches the established pattern (migration 036 was the original RPC; 071 replaced it; 085 replaces 071 again).

**Migration 084 structure:**
```sql
BEGIN;
-- 1. CREATE TABLE inform.inform_profiles (...)
-- 2. CREATE INDEX on user_id (PK already, so just the FK ref)
-- 3. Backfill: INSERT INTO inform.inform_profiles SELECT id FROM public.users ON CONFLICT DO NOTHING
-- 4. CREATE OR REPLACE FUNCTION inform.handle_new_user() RETURNS TRIGGER ...
-- 5. CREATE TRIGGER trg_create_inform_profile AFTER INSERT ON public.users ...
COMMIT;
```

**Migration 085 structure:**
```sql
BEGIN;
-- Full CREATE OR REPLACE FUNCTION connect.signup_with_invite(...) 
-- with yellow_gem_balance transfer logic added
COMMIT;
```

---

## PATCH /api/account/location-hint Route (IBAK-05)

**Location:** New route in `backend/src/routes/account.ts` (or a new `location.ts` router — but keeping it in `account.ts` is consistent with how `/me/jurisdiction` lives there).

**Middleware:** `requireAuth` + `requireInform`

**Body validation (Zod):**
```typescript
const LocationHintSchema = z.object({
  location: z.record(z.unknown()),  // flexible JSONB — caller defines shape
});
```

The Essentials app will pass whatever location payload it uses (city, state, lat/lng, etc.). Storing as raw JSONB with no schema enforcement is correct — the field is a hint, not a structured query target.

**Write pattern:**
```typescript
await pool.query(
  `UPDATE inform.inform_profiles
   SET last_essentials_location = $2
   WHERE user_id = $1`,
  [authReq.userId, JSON.stringify(body.location)]
);
```

**Response:** HTTP 200 `{ ok: true }` on success. HTTP 403 if Connected-tier (from `requireInform`). HTTP 422 on Zod validation failure.

---

## File Change Map

| File | Change | Requirement |
|------|--------|-------------|
| `backend/migrations/084_inform_profiles.sql` | New migration — table + trigger + backfill | IBAK-01, IBAK-02 |
| `backend/migrations/085_signup_with_invite_yellow_transfer.sql` | Replace `connect.signup_with_invite` RPC | IBAK-06 |
| `backend/src/middleware/tierGuards.ts` | Add `requireInform` export | IBAK-05 |
| `backend/src/lib/gemService.ts` | Branch in `awardGems()` for Inform-tier: pool.query tier check + new `awardInformYellowGem()` helper | IBAK-04 |
| `backend/src/routes/gems.ts` | Add `INFORM_TIER_NO_BLUE_RED` error handler → HTTP 422; rename `NOT_CONNECTED` → HTTP 404 (clarify it's user-not-found) | IBAK-04 |
| `backend/src/routes/account.ts` | 1) Add `inform_profile` to GET /me response; 2) Add `PATCH /me` `inform_profile` to PATCH /me response; 3) New `PATCH /api/account/location-hint` route | IBAK-03, IBAK-05 |

---

## Wave Plan (aligns with roadmap's 3 plan files)

| Wave | Plan File | Covers |
|------|-----------|--------|
| 1 | 66-01-PLAN.md | Migration 084 (table + trigger + backfill) + Migration 085 (signup_with_invite RPC update for IBAK-06) |
| 2 | 66-02-PLAN.md | gemService.ts tier branch + new RPC `inform.award_inform_yellow_gem` + `yellow_gem_events` table (may need migration 086) + GET /me `inform_profile` field + gems.ts error handler update |
| 3 | 66-03-PLAN.md | `requireInform` middleware + `PATCH /api/account/location-hint` endpoint |

**Dependency order:** Wave 1 must execute before Wave 2 (gemService needs `inform_profiles` to exist for the pool.query tier check). Wave 2 and Wave 3 can execute in parallel once Wave 1 is done.

---

## Key Findings & Decisions

### Q1: inform schema conflict?
No conflict. `inform.inform_profiles` does not exist. Safe to create.

### Q2: Trigger approach?
AFTER INSERT ON public.users, SECURITY DEFINER function, ON CONFLICT DO NOTHING. Plus a one-time backfill INSERT in the migration body.

### Q3: Gem routing approach?
**Branch in `awardGems()` via a pool.query tier check** (check `connect.connected_profiles` existence). Inform-tier yellow → new `inform.award_inform_yellow_gem` SECURITY DEFINER RPC. Inform-tier blue/red → throw `INFORM_TIER_NO_BLUE_RED` → HTTP 422. Do NOT modify the existing `connect.award_gems` RPC — it is correct for Connected+ users and changing it risks regression.

The tier check pool.query is one extra query per award for Inform users. Acceptable — Inform users have no connected_profiles row, so the check is a fast EXISTS query.

### Q4: requireInform middleware?
Must be created. Add to `tierGuards.ts`. Blocks users who HAVE a connected_profiles row (Connected+), passes users who do NOT (Inform). Chain: `requireAuth` + `requireInform`.

### Q5: signup_with_invite atomic transfer?
SELECT FOR UPDATE on `inform_profiles` row before UPDATE zero-out. Store old value in DECLARE variable. Pass as `gem_balance_yellow` in the connected_profiles INSERT. All within the existing PL/pgSQL transaction block. COALESCE to 0 if inform_profiles row is somehow absent.

### Q6: Migration structure?
Two migrations: 084 (table + trigger + backfill), 085 (signup_with_invite RPC replacement). If `inform.award_inform_yellow_gem` RPC + `yellow_gem_events` table is included in Wave 2, that becomes migration 086.

### Q7: Tier detection in awardGems without JWT?
Use `pool.query` with `SELECT EXISTS(SELECT 1 FROM connect.connected_profiles WHERE user_id = $1)`. The user_id is trusted input from the validated request body (already UUID-validated by Zod). This is correct — `gemService.ts` already uses `adminRpc` (service role equivalent), so using `pool.query` for the tier check is consistent.

### Q8: RLS on inform schema?
Most `inform` tables have no RLS (all writes via SECURITY DEFINER). Two exceptions: `district_boundaries` and `compass_verdicts` have RLS enabled. The new `inform_profiles` table should have NO RLS (write via SECURITY DEFINER trigger + RPCs; reads via pool.query from service-role context). No GRANT to `authenticated` needed for the trigger function — triggers run as SECURITY DEFINER.

---

## Potential Pitfalls

### inform_profiles row missing for Connected users
If a Connected user signed up before migration 084 runs, the backfill INSERT covers them. But if the migration is applied to a production DB where some users exist, the backfill must run before the `signup_with_invite` RPC update — otherwise the RPC SELECT FOR UPDATE hits a missing row. The two-migration approach (084 before 085) ensures this ordering.

### RETURNING in UPDATE gives new value, not old
A common Postgres pitfall. `UPDATE inform_profiles SET yellow_gem_balance = 0 RETURNING yellow_gem_balance` returns 0 (the new value). Use SELECT FOR UPDATE first to capture the old value, then UPDATE.

### awardGems: double pool.query on every Connected gem award
The tier check adds one pool.query per call. For Connected users, this is a wasted round-trip. Consider: only do the tier check if `connect.award_gems` throws `NOT_CONNECTED` (lazy tier detection). However, this complicates the blue/red 422 case — if the user is Inform-tier and calls for blue gems, we want 422, not 404. The eager check (before calling the RPC) is cleaner and the latency cost is one fast EXISTS query.

### gemService.ts cannot import from routes/
`gemService.ts` lives in `src/lib/`. It can use `pool` (imported from `./db.js`) and `supabaseAdmin`/`adminRpc` (from `./supabase.js`). No circular dependency risk for the tier check.

### Location-hint endpoint: should it upsert or update?
`UPDATE` only works if the row exists. If somehow `inform_profiles` has no row for this user (shouldn't happen post-migration, but defensive coding), the UPDATE silently affects 0 rows. Better: use `INSERT ... ON CONFLICT DO UPDATE` for the location write:

```sql
INSERT INTO inform.inform_profiles (user_id, last_essentials_location)
VALUES ($1, $2)
ON CONFLICT (user_id) DO UPDATE SET last_essentials_location = EXCLUDED.last_essentials_location
```

This is the safest write pattern.

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Schema design (IBAK-01) | HIGH | Codebase conventions fully understood; no conflicts |
| Trigger pattern (IBAK-02) | HIGH | Postgres trigger syntax verified against migration 055; ON CONFLICT pattern standard |
| Gem routing design (IBAK-04) | HIGH | award_gems RPC fully read; branch-in-service-layer is cleanest, least risky change |
| requireInform middleware (IBAK-05) | HIGH | tierGuards.ts fully read; pattern is direct inversion of requireConnected |
| signup_with_invite transfer (IBAK-06) | HIGH | Migration 071 fully read; SELECT FOR UPDATE + zero-out pattern is textbook atomic read-modify |
| GET /me inform_profile (IBAK-03) | HIGH | account.ts fully read; pool.query for inform schema is confirmed mandatory |
| Migration numbering | HIGH | Last migration confirmed as 083; next is 084 |
