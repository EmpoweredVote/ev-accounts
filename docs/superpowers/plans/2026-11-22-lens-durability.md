# Lens Durability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a user's custom lenses recoverable after any destruction and hard to destroy in bulk — soft delete, a trigger-written history table app code cannot bypass, a one-deletion-per-request cap, and a nightly tripwire that stays red until acknowledged.

**Architecture:** One `CC_` migration adds `deleted_at` to `inform.compass_user_lenses`, an append-only `inform.compass_user_lens_history` written by a `SECURITY DEFINER` row trigger, an `inform.compass_lens_alert_acks` table, and a statement trigger that refuses `TRUNCATE`. `compassUserLensService` stops issuing `DELETE` and starts setting `deleted_at`, filters soft-deleted rows everywhere except two load-bearing exceptions, and resurrects a key its owner re-creates. The route caps deletions at one. A new schedule-only CI job runs `check-lens-durability`, which reads history, joins `public.users`, ignores acknowledged rows, and proves itself with a rolled-back `--selftest`.

**Tech Stack:** PostgreSQL 17.6 (Supabase), plpgsql, TypeScript/Express (`backend/src`), `pg`, Vitest, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-22-lens-durability-design.md`

---

## Global Constraints

- **Migration namespace is `CC_`.** The slot is reserved through the steward at execution time: `npm run steward --prefix backend -- slot CC --purpose "..."`. Never pick a number by hand. Confirm with `npm run check:migrations` and `npm run check:reservations` before committing.
- **The trigger function is `SECURITY DEFINER SET search_path TO ''`, owned by `postgres`.** Not optional. Account deletion cascades through `auth.users → public.users → compass_user_lenses` as `supabase_auth_admin`, which is **not** superuser, does **not** bypass RLS, and has **no `USAGE` on `inform`**. An `INVOKER` trigger aborts every account deletion.
- **Do not `REVOKE` anything from `ev_api`.** `inform.compass_user_lenses` ACL is `postgres=arwdDxtm/postgres | ev_api=arwd/postgres`, and `ev_api` has `rolbypassrls = true`. That grant is how the API reads the table at all. `ALTER DEFAULT PRIVILEGES IN SCHEMA inform` already gives `ev_api=arwd` on new tables created by `postgres`, so the new tables get the right grant by doing nothing.
- **`owner_id` on the history table has NO foreign key and NO cascade.** History must outlive its subject; the parent cascades on account deletion.
- **The unique index on `key` stays as it is**, covering soft-deleted rows. A share link that pointed at a deleted lens must never resolve to a different user's lens.
- **The deletion cap is `1`**, as a named constant, enforced in the route and not in zod. `delete_keys` keeps its zod `.max(20)`.
- **Destructive testing goes against `compass-smoke@empowered.vote` only — never a real account.** Credentials in `~/.ev-compass-smoke/creds.env`, never committed.
- **The database is over its size limit.** Write volume is a live constraint: a no-op save must write no history row.
- **`ci.yml`'s header requires a cost statement before adding a job.** This is roughly the 25th.

## Review Focus

Five things the spec implies that no task's own happy path exercises. Each has its test pinned to the task that owns the code.

1. **`delete_keys: ['u_a', 'u_a']`** — two entries, one lens. A cap counted on array length refuses a single legitimate deletion with 422. Count distinct. → Task 3.
2. **Re-creating a key you soft-deleted** must resurrect that row (`deleted_at = NULL`, `created_at` preserved, op `restore`), not silently no-op. The global unique index means the `INSERT` always conflicts, and the owner's own soft-deleted row is the one it conflicts with. → Task 2.
3. **Account deletion must still work.** The cascade's `hard_delete` runs the trigger as `supabase_auth_admin`. This is the failure that would otherwise be found in production, by a user deleting their account. → Task 1 (probe) and Task 6 (end to end).
4. **A no-op save must write no history row and must not bump `updated_at`.** The client PUTs the whole set on every save; without this a single rename writes one history row per lens, each carrying two full row copies. The trigger's `WHEN` clause alone does **not** achieve this — see Task 2, Step 5. → Task 2.
5. **The nightly must stay green on ordinary use, and must not double-count.** Both current owners hold exactly one lens, so one legitimate deletion each must not fire; and a `soft_delete` followed by the cascade `hard_delete` of the same row is two history rows for one lens. → Task 4.

## Calls made while planning (not in the spec — check these)

Three places where the spec left a decision that turned out to matter. Each is flagged again at the step that implements it.

- **The alert window is 7 days, not 24 hours.** The spec says "in the last 24 hours" and also "red stays red until acknowledged". Those contradict: a 24h query window *is* the self-healing window the spec rejected. 7 days is the backup retention — exactly as long as the event is still recoverable, and therefore as long as being red is actionable.
- **No `DATABASE_URL` → fail, with `--allow-skip` for local**, following `check-lens-freshness.mjs`, **not** `check-migration-reservations.mjs` as the spec says. The job is schedule-only, so forks never run it and the fork argument does not apply; and a green skip is the "satisfied without being true" anti-goal exactly.
- **The upsert must stop bumping `updated_at` on a no-op.** Without that the trigger's `WHEN (OLD.* IS DISTINCT FROM NEW.*)` clause never suppresses anything, because `updated_at = now()` makes every row distinct. See Task 2, Step 5.

---

## File Structure

| File | Responsibility |
|---|---|
| `backend/migrations/CC_<NNNN>_compass_user_lens_history.sql` | **Create.** `deleted_at`, history table, ack table, trigger function, four triggers. |
| `backend/src/lib/compassUserLensService.ts` | **Modify.** Soft delete, the `deleted_at` filters and their two exceptions, resurrection, the stale grants comment. |
| `backend/src/lib/compassUserLensService.test.ts` | **Modify.** Tests for all of the above. |
| `backend/src/routes/compass.ts` | **Modify.** The one-deletion cap. |
| `backend/scripts/check-lens-durability.mjs` | **Create.** The nightly: SQL, two pure verdict functions, `--ack`, `--selftest`, `--allow-skip`. |
| `backend/scripts/check-lens-durability.test.ts` | **Create.** Unit tests for the two verdict functions. |
| `backend/package.json` | **Modify.** Three npm scripts. |
| `.github/workflows/ci.yml` | **Modify.** One schedule-only job with a cost statement. |

---

### Task 1: The migration

**Files:**
- Create: `backend/migrations/CC_<NNNN>_compass_user_lens_history.sql`
- Test: probe queries against prod (this is SQL; its proof is the probe, and Task 4's `--selftest` is its regression test)

**Interfaces:**
- Produces: `inform.compass_user_lenses.deleted_at timestamptz`; table `inform.compass_user_lens_history (id, owner_id, lens_key, op, before, after, created_at)` with `op ∈ {insert, update, restore, soft_delete, hard_delete}`; table `inform.compass_lens_alert_acks (history_id, acked_at, acked_by, note)`; functions `inform.log_compass_user_lens_change()` and `inform.refuse_compass_user_lens_truncate()`.

- [ ] **Step 1: Reserve the slot**

```bash
npm run steward --prefix backend -- slot CC --purpose "soft delete + trigger-written history + ack table for custom lenses"
```

Use the number it returns. Do not pick one.

- [ ] **Step 2: Write the migration**

One `BEGIN; … COMMIT;`, idempotent throughout (`IF NOT EXISTS`, `CREATE OR REPLACE`). A header comment in the house style saying what this is for, citing the 2026-11-22 measurement and the design doc.

Contents, in order:

1. `ALTER TABLE inform.compass_user_lenses ADD COLUMN IF NOT EXISTS deleted_at timestamptz;`
2. `inform.compass_user_lens_history` exactly as the Interfaces block gives it. `id uuid primary key default gen_random_uuid()`. `owner_id uuid not null` — **no FK**, with the reason in a comment. `op text not null` with a `CHECK` over the five values. `before jsonb`, `after jsonb`, `created_at timestamptz not null default now()`.
3. Two indexes: `(owner_id, created_at DESC)` and `(created_at DESC)` — the second is the nightly's window scan.
4. `inform.compass_lens_alert_acks (history_id uuid primary key references inform.compass_user_lens_history(id), acked_at timestamptz not null default now(), acked_by text not null, note text)`.
5. `ALTER TABLE … ENABLE ROW LEVEL SECURITY` on both new tables, **no policies, no grants** — see Global Constraints.
6. The trigger function, below.
7. `inform.refuse_compass_user_lens_truncate()` — `RETURNS trigger LANGUAGE plpgsql`, body `RAISE EXCEPTION 'compass_user_lenses must not be truncated: it would destroy lenses with no history'`, and the same `SECURITY DEFINER SET search_path TO ''`.
8. Four triggers, using `CREATE OR REPLACE TRIGGER` (PG 14+, so this is idempotent):
   - `compass_user_lenses_history_ins` — `AFTER INSERT … FOR EACH ROW`
   - `compass_user_lenses_history_upd` — `AFTER UPDATE … FOR EACH ROW WHEN (OLD.* IS DISTINCT FROM NEW.*)`
   - `compass_user_lenses_history_del` — `AFTER DELETE … FOR EACH ROW`
   - `compass_user_lenses_no_truncate` — `AFTER TRUNCATE … FOR EACH STATEMENT`
9. `ALTER FUNCTION … OWNER TO postgres;` for both functions.

The trigger function body is given because the branching is not determined by its signature, and getting it wrong is a production incident:

```sql
CREATE OR REPLACE FUNCTION inform.log_compass_user_lens_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE
  v_op text;
BEGIN
  -- 🔴 BRANCHED, NOT COALESCED. In a DELETE trigger plpgsql leaves NEW
  -- unassigned, and touching NEW.owner_id there raises. Likewise OLD on INSERT.
  IF TG_OP = 'DELETE' THEN
    INSERT INTO inform.compass_user_lens_history (owner_id, lens_key, op, before, after)
    VALUES (OLD.owner_id, OLD.key, 'hard_delete', to_jsonb(OLD), NULL);
    RETURN NULL;
  END IF;

  IF TG_OP = 'INSERT' THEN
    INSERT INTO inform.compass_user_lens_history (owner_id, lens_key, op, before, after)
    VALUES (NEW.owner_id, NEW.key, 'insert', NULL, to_jsonb(NEW));
    RETURN NULL;
  END IF;

  IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
    v_op := 'soft_delete';
  ELSIF OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL THEN
    v_op := 'restore';
  ELSE
    v_op := 'update';
  END IF;

  INSERT INTO inform.compass_user_lens_history (owner_id, lens_key, op, before, after)
  VALUES (NEW.owner_id, NEW.key, v_op, to_jsonb(OLD), to_jsonb(NEW));
  RETURN NULL;
END;
$function$;
```

- [ ] **Step 3: Apply it to prod**

Apply as `postgres` (the `supabase-local` MCP server — **it is the production database**). Re-run it once to prove idempotence.

- [ ] **Step 4: Probe what you just created**

Run each and record the output in the commit message:

```sql
-- a. the function is SECURITY DEFINER, owned by postgres, search_path pinned
SELECT p.proname, p.prosecdef, r.rolname AS owner, p.proconfig
  FROM pg_proc p JOIN pg_roles r ON r.oid = p.proowner
 WHERE p.pronamespace = 'inform'::regnamespace
   AND p.proname IN ('log_compass_user_lens_change','refuse_compass_user_lens_truncate');

-- b. all four triggers exist, and the UPDATE one carries a WHEN clause
SELECT tgname, tgtype, pg_get_triggerdef(oid) FROM pg_trigger
 WHERE tgrelid = 'inform.compass_user_lenses'::regclass AND NOT tgisinternal;

-- c. ev_api got arwd on both new tables WITHOUT anyone granting it
SELECT relname, relacl, relrowsecurity FROM pg_class
 WHERE relname IN ('compass_user_lens_history','compass_lens_alert_acks');
```

Expected: `prosecdef = t`, `owner = postgres`, `proconfig = {search_path=""}`; four triggers, the UPDATE one showing `WHEN ((old.* IS DISTINCT FROM new.*))`; `ev_api=arwd` present on both tables and `relrowsecurity = t`.

🔴 **If `ev_api` is NOT on the new tables, stop and say so.** It means default privileges did not apply and the service will 500. Do not fix it by revoking anything.

- [ ] **Step 5: Prove the trigger survives the account-deletion cascade**

This is Review Focus 3, and it is the failure that would otherwise surface in production. In a transaction that you **roll back**, against prod:

1. Pick an existing `public.users` row that holds no lenses (read-only `SELECT`).
2. `SET LOCAL ROLE supabase_auth_admin;`
3. `DELETE FROM public.users WHERE id = <that id>;`
4. Assert it succeeded and that a `hard_delete` row appeared for each lens it cascaded (zero lenses means zero rows — so pick a user who *does* hold a lens if one exists in the smoke account, otherwise insert one as `postgres` first, inside the same transaction).
5. `ROLLBACK;` and re-assert the user is still there.

Expected: no `permission denied for schema inform`. If it raises, the trigger is not `SECURITY DEFINER` — fix before going further.

- [ ] **Step 6: Commit**

```bash
git add backend/migrations/CC_<NNNN>_compass_user_lens_history.sql
git commit -m "feat(compass): record every lens change, and make a deletion reversible

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Soft delete in the service

**Files:**
- Modify: `backend/src/lib/compassUserLensService.ts`
- Test: `backend/src/lib/compassUserLensService.test.ts`

**Interfaces:**
- Consumes: Task 1's `deleted_at` column and trigger.
- Produces: `replaceUserLenses(ownerId: string, lenses: UserLensInput[], deleteKeys?: string[]): Promise<UserLens[]>` — unchanged signature, changed behaviour. `getUserLenses` returns live lenses only.

- [ ] **Step 1: Write the failing tests**

Add to the `describe('replaceUserLenses — a deletion must be named')` block in `compassUserLensService.test.ts`, using the existing `storedKeys()` helper and `clientQueryMock`:

```ts
it('soft-deletes a named lens instead of destroying the row', async () => {
  storedKeys(['u_7f3a91', 'u_aaa001']);
  poolQueryMock.mockResolvedValue({ rows: [] });

  await replaceUserLenses(USER, [LENS], ['u_aaa001']);

  const issued = clientQueryMock.mock.calls.map(c => String(c[0]));
  // 🔴 The row must survive. A DELETE here is the thing this task removed.
  expect(issued.some(q => /DELETE\s+FROM\s+inform\.compass_user_lenses/i.test(q))).toBe(false);
  const soft = clientQueryMock.mock.calls.find(c => String(c[0]).includes('deleted_at = now()'));
  expect(String(soft?.[0])).toContain('owner_id = $1');
  expect(String(soft?.[0])).toContain('key = ANY($2::text[])');
  expect(soft?.[1]).toEqual([USER, ['u_aaa001']]);
});

it('does not count the owner\'s own soft-deleted lenses as stored', async () => {
  // Without the filter, every later PUT 409s forever on a lens they deleted.
  storedKeys(['u_7f3a91']);
  poolQueryMock.mockResolvedValue({ rows: [] });

  await replaceUserLenses(USER, [LENS]);

  const select = clientQueryMock.mock.calls.find(c => String(c[0]).includes('FOR UPDATE'));
  expect(String(select?.[0])).toContain('deleted_at IS NULL');
});

it('still sees ANOTHER owner\'s soft-deleted key as taken', async () => {
  // 🔴 THE LOAD-BEARING EXCEPTION. Soft-deleted rows stay under the global
  // unique index, so the upsert's `WHERE owner_id = $1` predicate fails against
  // them — updating nothing, inserting nothing, 200, and a lens quietly missing.
  poolQueryMock.mockResolvedValue({ rows: [{ key: 'u_7f3a91' }] });

  await expect(replaceUserLenses(USER, [LENS])).rejects.toMatchObject({
    code: 'LENS_KEY_TAKEN',
    keys: ['u_7f3a91'],
  });

  const probe = poolQueryMock.mock.calls.find(c => String(c[0]).includes('owner_id <> $1'));
  expect(String(probe?.[0])).not.toContain('deleted_at');
});

it('resurrects a key its own owner re-creates, keeping created_at', async () => {
  storedKeys([]);
  poolQueryMock.mockResolvedValue({ rows: [] });

  await replaceUserLenses(USER, [LENS]);

  const upsert = clientQueryMock.mock.calls.find(c => String(c[0]).includes('ON CONFLICT'));
  expect(String(upsert?.[0])).toContain('deleted_at = NULL');
  expect(String(upsert?.[0])).not.toContain('created_at = ');
});

it('writes nothing at all when the saved lens is unchanged', async () => {
  // Review Focus 4. The client PUTs the whole set on every save; without this
  // one rename writes a history row per lens, each with two full row copies.
  storedKeys(['u_7f3a91']);
  poolQueryMock.mockResolvedValue({ rows: [] });

  await replaceUserLenses(USER, [LENS]);

  const upsert = clientQueryMock.mock.calls.find(c => String(c[0]).includes('ON CONFLICT'));
  expect(String(upsert?.[0])).toContain('IS DISTINCT FROM');
});
```

And one read test, in its own `describe('getUserLenses — a deleted lens is gone from the read')`:

```ts
it('asks only for live lenses', async () => {
  mockRows([]);
  await getUserLenses(USER);
  expect(String(poolQueryMock.mock.calls[0]?.[0])).toContain('deleted_at IS NULL');
});
```

Import `getUserLenses` at the top of the file alongside the existing imports.

- [ ] **Step 2: Run them to verify they fail**

Run: `npm test --prefix backend -- compassUserLensService`
Expected: the six new tests FAIL; every pre-existing test in the file still PASSES.

⚠ **Two existing tests encode the hard-delete shape and must be updated in Step 5, not deleted.** They are the #1584 regression guards and the behaviour they guard is still required — only the statement changed.

- `it('deletes exactly the keys the caller named, and no others')` asserts on a `DELETE` statement and on `deleteCall[1] === [USER, ['u_aaa001']]`. Repoint it at the `deleted_at = now()` UPDATE, keeping both of its real assertions: the parameter is the **named** keys, and the statement does **not** contain `NOT (key`.
- `it('issues no DELETE at all when nothing was named')` would now pass for the wrong reason. Rename it to say no *soft delete* is issued, and assert on `deleted_at = now()`.

A guard that passes because the thing it watched no longer exists is not a guard.

- [ ] **Step 3: Add the `deleted_at IS NULL` filter to `getUserLenses`**

In `backend/src/lib/compassUserLensService.ts`, the `getUserLenses` query gains `AND deleted_at IS NULL`.

- [ ] **Step 4: Filter the `FOR UPDATE` read, and correct its comment**

The `SELECT key … FOR UPDATE` inside `replaceUserLenses` gains `AND deleted_at IS NULL`.

⚠ Its existing comment claims the lock covers a concurrent insert. With the filter it no longer locks soft-deleted rows, so **rewrite the comment to say what is now true** rather than leaving it to contradict the code: the lock covers the owner's live rows, and a concurrent resurrection of a soft-deleted key is not serialised by it.

- [ ] **Step 5: Replace the `DELETE` with a soft delete, and stop no-op saves from writing**

Two changes in the same function.

The deletion becomes:

```sql
UPDATE inform.compass_user_lenses
   SET deleted_at = now()
 WHERE owner_id = $1 AND key = ANY($2::text[]) AND deleted_at IS NULL
```

The upsert's `ON CONFLICT` clause gains `deleted_at = NULL` in its `SET`, and a second conjunct in its `WHERE`:

```sql
ON CONFLICT (key) DO UPDATE
  SET name       = EXCLUDED.name,
      topic_ids  = EXCLUDED.topic_ids,
      visibility = EXCLUDED.visibility,
      deleted_at = NULL,
      updated_at = now()
  WHERE inform.compass_user_lenses.owner_id = $1
    AND (inform.compass_user_lenses.name,
         inform.compass_user_lenses.topic_ids,
         inform.compass_user_lenses.visibility,
         inform.compass_user_lenses.deleted_at)
        IS DISTINCT FROM
        (EXCLUDED.name, EXCLUDED.topic_ids, EXCLUDED.visibility, NULL::timestamptz)
```

🔴 **The second conjunct is why the trigger's `WHEN` clause does anything.** `updated_at = now()` makes `OLD.* IS DISTINCT FROM NEW.*` true on *every* upsert, so without this the `WHEN` clause suppresses nothing and the whole-set PUT writes a history row per lens on every save. Say that in a comment.

⚠ **This changes observable behaviour:** `updated_at` no longer moves on a save that changed nothing. That is the point, and it is more honest than the old behaviour. Note it in the comment.

⚠ **`row_count = 0` now has a second, benign meaning** — "nothing to change" as well as "not yours". The existing comment above `findKeysOwnedByOthers` explains why `row_count = 0` is not relied on; extend it to say so, so a later reader does not reintroduce a check on it.

- [ ] **Step 6: Mark the exception on `findKeysOwnedByOthers`, loudly**

`findKeysOwnedByOthers` gets **no** `deleted_at` filter. Add a 🔴 comment above it saying why, in the house style: soft-deleted rows stay under the global unique index, so the upsert's ownership predicate fails against another owner's soft-deleted row and the caller gets 200 with a lens quietly missing. Reference the test that guards it.

- [ ] **Step 7: Fix the stale grants comment in the file header**

The header currently says `inform.compass_user_lenses` is *"RLS-on with no policies and no grants"*. **That is wrong** — `ev_api=arwd`, and `ev_api` bypasses RLS. Replace it with what was measured on 2026-11-22: RLS is on with no policies, `ev_api` holds `arwd` and bypasses RLS, which is how the backend pool reads the table; PostgREST (`anon`/`authenticated`) has no grant and cannot see it; `WHERE owner_id = $1` is the enforcement.

Also add a short paragraph to the header on soft delete and the history trigger, pointing at the design doc.

- [ ] **Step 8: Run the tests**

Run: `npm test --prefix backend -- compassUserLensService`
Expected: PASS, all of them.

- [ ] **Step 9: Typecheck and lint**

Run: `npm run build --prefix backend && npm run lint --prefix backend`
Expected: both clean.

- [ ] **Step 10: Commit**

```bash
git add backend/src/lib/compassUserLensService.ts backend/src/lib/compassUserLensService.test.ts
git commit -m "feat(lenses): a deletion is now reversible, and a no-op save writes nothing

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: The one-deletion cap

**Files:**
- Modify: `backend/src/routes/compass.ts`
- Test: `backend/src/routes/compass.lensCap.test.ts` (create — copy the harness from `backend/src/routes/compass.clearAnswer.test.ts`: `express` + `supertest`, `vi.hoisted` mocks for `../lib/supabase.js`, `../lib/compassService.js` and `../lib/compassUserLensService.js`, a fixed `ACCESS_TOKEN` and `USER`)

**Interfaces:**
- Consumes: nothing from Tasks 1–2.
- Produces: HTTP `422 { code: 'TOO_MANY_LENS_DELETIONS', message, delete_keys }` from `PUT /api/compass/my-lenses`; exported `const MAX_LENS_DELETIONS_PER_REQUEST = 1`.

- [ ] **Step 1: Write the failing tests**

Three cases. The third is Review Focus 1. `replaceUserLensesMock` is the mocked
`replaceUserLenses`; `LENS = { key: 'u_7f3a91', name: 'Mine', topic_ids: [] }`.

```ts
it('refuses a request that would delete two lenses', async () => {
  const res = await put({ lenses: [LENS], delete_keys: ['u_aaa001', 'u_bbb002'] });

  expect(res.status).toBe(422);
  expect(res.body.code).toBe('TOO_MANY_LENS_DELETIONS');
  expect(res.body.delete_keys).toEqual(['u_aaa001', 'u_bbb002']);
  // Refused whole: the service is never reached, so neither deletion happens.
  expect(replaceUserLensesMock).not.toHaveBeenCalled();
});

it('allows a request that deletes exactly one', async () => {
  replaceUserLensesMock.mockResolvedValue([]);

  const res = await put({ lenses: [LENS], delete_keys: ['u_aaa001'] });

  expect(res.status).toBe(200);
  expect(replaceUserLensesMock).toHaveBeenCalledWith(USER, [LENS], ['u_aaa001']);
});

it('counts a key named twice as one deletion', async () => {
  // 🔴 Review Focus 1. Array length is 2 and the lens count is 1. A cap counted
  // on length refuses a single legitimate deletion with a 422 the client cannot
  // act on, because nothing about its request was actually too big.
  replaceUserLensesMock.mockResolvedValue([]);

  const res = await put({ lenses: [LENS], delete_keys: ['u_aaa001', 'u_aaa001'] });

  expect(res.status).toBe(200);
});
```

- [ ] **Step 2: Run them to verify they fail**

Run: `npm test --prefix backend -- compass.lensCap`
Expected: the first and third FAIL.

- [ ] **Step 3: Implement the cap in `backend/src/routes/compass.ts`**

Add, near the other lens constants:

```ts
/**
 * How many lenses one PUT may delete.
 *
 * 🔴 ONE, AND RAISING IT IS A DECISION. `deleteActiveLens` is the only caller in
 * the product that deletes and it names exactly one key; guest promotion never
 * deletes. So a two-deletion request cannot be produced by the application as it
 * exists, which makes 1 the honest blast radius and "delete everything in one
 * shot" structurally impossible rather than merely guarded. If bulk delete ever
 * becomes a feature, this line changes — and changing it IS the decision, not an
 * implementation detail of that feature.
 */
export const MAX_LENS_DELETIONS_PER_REQUEST = 1;
```

In the `PUT /my-lenses` handler, **after** the `CONTRADICTORY_LENS_KEYS` check and **before** the `try` block, count distinct keys and return 422 with code `TOO_MANY_LENS_DELETIONS` when it exceeds the constant. The response body carries `delete_keys`.

⚠ **Count `new Set(deleteKeys).size`, not `deleteKeys.length`** — Review Focus 1.

⚠ **422 and not 409**, matching `DUPLICATE_LENS_KEYS` and `CONTRADICTORY_LENS_KEYS`: the body is refused on its own terms, with no reference to what the server holds. Only `LENS_DELETE_NOT_ACKNOWLEDGED` is a 409, because that one *is* about disagreeing with stored state.

⚠ **Do not add `.max(1)` to zod.** `delete_keys` keeps `.max(20)` as the payload guard; a zod cap would surface as a generic `VALIDATION_ERROR` and put two limits on one rule.

Extend the route's header comment to say the cap exists and why.

- [ ] **Step 4: Run the tests**

Run: `npm test --prefix backend -- compass.lensCap`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/compass.ts backend/src/routes/compass.lensCap.test.ts
git commit -m "feat(lenses): one PUT may delete at most one lens

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: The nightly check

**Files:**
- Create: `backend/scripts/check-lens-durability.mjs`
- Create: `backend/scripts/check-lens-durability.test.ts`
- Modify: `backend/package.json`

**Interfaces:**
- Consumes: Task 1's `compass_user_lens_history` and `compass_lens_alert_acks`.
- Produces: two exported pure functions —
  - `findMultiDeleteOwners(rows: RemovalRow[]): { ownerId: string, keys: string[], ids: string[], firstAt: string, lastAt: string }[]`
  - `findOrphanHardDeletes(rows: RemovalRow[]): RemovalRow[]`

  where `RemovalRow = { id, owner_id, lens_key, op, created_at, owner_exists }` and `op ∈ {'soft_delete','hard_delete'}`.
- Produces npm scripts: `check:lens-durability`, `check:lens-durability:selftest`, `check:lens-durability:ack`.

- [ ] **Step 1: Write the failing unit tests**

`backend/scripts/check-lens-durability.test.ts` — pure functions, no database, following `check-answer-season-consumers.test.ts` for shape.

```ts
describe('findMultiDeleteOwners', () => {
  it('is silent when an owner removed exactly one lens', /* Review Focus 5: both
     current owners hold exactly one lens; the only deletion either can make
     must not fire. */);

  it('fires when one owner removed two different lenses', /* → one entry naming
     both keys and both history ids */);

  it('counts a soft_delete and the cascade hard_delete of the SAME key once',
     /* Review Focus 5: two history rows, one lens, so NOT a multi-delete */);

  it('ignores an owner whose account no longer exists', /* owner_exists: false —
     that is condition 2's business, and an account deletion legitimately removes
     every lens at once */);

  it('does not group two different owners together', /* one removal each → empty */);
});

describe('findOrphanHardDeletes', () => {
  it('fires on a hard_delete whose owner still exists', /* the only legitimate
     hard delete is the account-deletion cascade */);

  it('is silent on a hard_delete whose owner is gone', /* the cascade */);

  it('is silent on a soft_delete', /* that is the sanctioned path */);
});
```

- [ ] **Step 2: Run them to verify they fail**

Run: `npm test --prefix backend -- check-lens-durability`
Expected: FAIL, "does not provide an export named".

- [ ] **Step 3: Write `backend/scripts/check-lens-durability.mjs`**

`#!/usr/bin/env node`, `import 'dotenv/config'`, `import pg from 'pg'`. Follow `check-lens-freshness.mjs` and `check-body-completeness.mjs` for structure, header style, and exit codes.

A header comment covering: why this exists (the 2026-11-22 measurement, and that the ev-accounts#1584 guard closes one path and not the next), the two conditions, the third condition that was **dropped and why** (prod holds 2 lenses across 2 owners, each exactly one, so it would have gone red on ordinary use), the window, and the run lines.

**Constants:**

```js
/**
 * How far back an UNACKNOWLEDGED removal keeps this red.
 *
 * 🔴 SEVEN DAYS, NOT TWENTY-FOUR, AND THE DIFFERENCE IS THE POINT. PITR is off;
 * the floor is daily backups with 7-day retention. A 24h query window would let
 * a destruction age out of the alarm while it was still recoverable — which is
 * the self-healing window the design doc rejected, rebuilt as a WHERE clause.
 * Seven days is exactly as long as being red is actionable.
 */
const ALERT_WINDOW_DAYS = 7;
```

**The query** returns one row per removal event in the window that nobody has acknowledged:

```sql
SELECT h.id::text, h.owner_id::text, h.lens_key, h.op, h.created_at,
       (u.id IS NOT NULL) AS owner_exists
  FROM inform.compass_user_lens_history h
  LEFT JOIN public.users u ON u.id = h.owner_id
 WHERE h.op IN ('soft_delete', 'hard_delete')
   AND h.created_at >= now() - ($1 || ' days')::interval
   AND NOT EXISTS (
     SELECT 1 FROM inform.compass_lens_alert_acks a WHERE a.history_id = h.id)
 ORDER BY h.owner_id, h.created_at
```

⚠ **The join on `public.users` is deliberate and is not a second source of truth.** History is the source of *events*; whether the account still exists is a fact only `public.users` holds. What this must never do is read a committed baseline file.

**`findMultiDeleteOwners(rows)`** — keep rows where `owner_exists`, group by `owner_id`, take distinct `lens_key` per owner, return the owners with more than one.

**`findOrphanHardDeletes(rows)`** — rows where `op === 'hard_delete' && owner_exists`.

**Reporting.** Each failure names the owner id, the keys and the timestamps, and the history ids to ack, so *what did we lose and whose was it* is answered by the failure message and not by a follow-up query. Print the ack command line verbatim.

**`--allow-skip` / no `DATABASE_URL`.** Follow `check-lens-freshness.mjs`: without `DATABASE_URL` and without `--allow-skip`, print `🔴 … FAILED — no DATABASE_URL. A tripwire that never runs reads healthy forever. Use --allow-skip locally.` and return 1. With `--allow-skip`, print that **nothing was measured and this is not a pass**, and return 0.

🔴 This departs from the design doc, which says skip-and-exit-0 "matching check-migration-reservations". The job is schedule-only so forks never run it; and a green skip is the "satisfied without being true" anti-goal. Say so in the header comment.

**`--ack <id> [<id>…] [--note "<why>"]`.** Inserts into `inform.compass_lens_alert_acks` with `acked_by` from `git config user.email`; refuse with a clear message if that is empty. `ON CONFLICT (history_id) DO NOTHING`. Print what was acked and exit 0. Refuse an id that is not an unacked removal row in the window, rather than inserting a row that acknowledges nothing.

- [ ] **Step 4: Run the unit tests**

Run: `npm test --prefix backend -- check-lens-durability`
Expected: PASS.

- [ ] **Step 5: Add `--selftest`, and prove the check can go red**

🔴 **The anti-goal in the design doc: a tripwire that goes green while lenses vanish is worse than none. Observing it green proves nothing.**

Follow `check-body-completeness.mjs`'s `selftest(pool)`: open a transaction, plant, assert, **`ROLLBACK`**, assert reverted.

1. Assert the live check is currently green. If it is already red, **stop and say so** — a tamper proves nothing against a red baseline.
2. Read one existing `public.users` id (read-only).
3. Plant **two** `soft_delete` history rows for that owner with throwaway `lens_key`s → assert `findMultiDeleteOwners` now names that owner.
4. Plant one `hard_delete` row for that owner → assert `findOrphanHardDeletes` now names it.
5. Insert acks for all three planted ids → assert the check is green again. **This is the ack path's only proof.**
6. `ROLLBACK`, then assert the planted rows are gone.

⚠ It writes only to `compass_user_lens_history` and `compass_lens_alert_acks`, never to `compass_user_lenses`, so no real lens is touched even transiently — and the history table has no FK on `owner_id`, so nothing cascades.

- [ ] **Step 6: Run the selftest against prod**

Run: `npm run check:lens-durability:selftest --prefix backend`
Expected: three tampers reported `red: true`, the ack step reported green, `ROLLBACK` verified. Paste the output into the commit message.

- [ ] **Step 7: Wire the npm scripts**

In `backend/package.json`, beside `check:lens-freshness`:

```json
"check:lens-durability": "node scripts/check-lens-durability.mjs",
"check:lens-durability:selftest": "node scripts/check-lens-durability.mjs --selftest",
"check:lens-durability:ack": "node scripts/check-lens-durability.mjs --ack",
```

- [ ] **Step 8: Run the check for real**

Run: `npm run check:lens-durability --prefix backend`
Expected: green (prod holds 2 lenses across 2 owners with no removals).

- [ ] **Step 9: Commit**

```bash
git add backend/scripts/check-lens-durability.mjs backend/scripts/check-lens-durability.test.ts backend/package.json
git commit -m "feat(ci): a nightly that notices lenses going missing, and stays red until acked

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: The CI job

**Files:**
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: Task 4's `check:lens-durability` script and `secrets.DATABASE_URL`.

- [ ] **Step 1: Add the job**

Model it on the `spatial-ref-baseline` job. Its own job — a check that talks to the database does not share one, per the rule at the top of the file.

- `if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'`
- `defaults.run.working-directory: backend`
- `actions/checkout@v7`, `actions/setup-node@v7` with `node-version-file: backend/.node-version` and npm cache keyed on `backend/package-lock.json`
- `npm ci`
- `run: npm run check:lens-durability` with `env: DATABASE_URL: ${{ secrets.DATABASE_URL }}`

⚠ **Do not add it to `ci-ok`'s `needs`.** Schedule-only jobs are not required checks, so a red nightly blocks no merges — consistent with the "no pager" non-goal in the design doc.

- [ ] **Step 2: Write the cost statement**

The header requires it. In the job's comment block, state: **schedule only, ~30 billed minutes a month** (one nightly run at the one-minute minimum), and why it cannot be charged per push — a push cannot remove a user's lens; what this measures changes on the calendar, by what users and write paths do in prod. Same reasoning as `spatial-ref-baseline`, `child-county` and `season-corpus-floor`. Note that it is roughly the 25th job.

- [ ] **Step 3: Verify the workflow parses and the job runs**

```bash
gh workflow run ci.yml --ref feat/lens-durability
```

Expected: the `lens durability` job runs and is green. If `workflow_dispatch` on a branch is not available, say so and verify on the first nightly after merge instead — do not claim it passed.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: watch nightly for lenses going missing

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 6: End-to-end verification against the throwaway account

**Files:**
- Create: scratchpad scripts only (`scratchpad/lens-measure/`) — **nothing here is committed**

🔴 **`compass-smoke@empowered.vote` ONLY. Never a real account.** Credentials at `~/.ev-compass-smoke/creds.env`, never committed. This is the user's standing instruction, and the failure mode being tested is permanent deletion.

- [ ] **Step 1: Deploy the backend**

Open the PR, merge after CI, and wait for the Render deploy to finish. Record the deploy id. Everything below runs against the deployed API, not locally.

- [ ] **Step 2: Run the seven checks from the design doc**

Put three lenses on the throwaway account, then verify each, recording the actual response and the actual rows:

1. **Soft delete.** Delete one lens. → `200`; the row survives with `deleted_at` set; a `soft_delete` history row exists; `GET /my-lenses` no longer shows it.
2. **The cap.** PUT naming two deletions. → `422 TOO_MANY_LENS_DELETIONS`, nothing written.
3. **No-op saves are free.** PUT the set unchanged, twice. → `200`; **zero** new history rows; `updated_at` unmoved.
4. **Resurrection.** Re-create the deleted key. → `200`; op `restore`; `created_at` is the original.
5. **The exception.** From a second account, claim the throwaway's soft-deleted key. → `409 LENS_KEY_TAKEN`, not a silent 200 with a missing lens.
6. **Account deletion still works.** Create a *second* throwaway account, give it a lens, delete the account through the normal path. → the deletion succeeds and a `hard_delete` history row survives it. **This is the `SECURITY DEFINER` check** — the one that would otherwise have been found in production.
7. **The nightly bites.** Delete two lenses from the throwaway in separate requests, run `check:lens-durability`. → **red**, naming the owner, both keys and both timestamps. Run it again. → **still red**. Ack the ids. → **green**.

- [ ] **Step 3: Run the smoke suite**

Run: `npm run smoke` in CompassV2 (full run, at the gate — iterating with `--only` is cheaper, and Chrome profiles are expensive on this machine).
Expected: green. `clearServerLenses` already deletes one lens per request, naming each, so it survives the cap — but prove it rather than assume it.

- [ ] **Step 4: Clean up the throwaway account**

Leave `compass-smoke@empowered.vote` with no lenses, so the next smoke run starts from the state it expects.

- [ ] **Step 5: Report**

Write the seven results as a table — what was expected, what happened — and say plainly if any step was skipped or could not be run. A step not run is not a step passed.

---

## Not covered here, deliberately

- **`compass_responses`' own history gap.** `compass_change_history` is written by the sanctioned RPCs, not by a trigger, and its `new_value` is `NOT NULL` so it structurally cannot record a deletion. Closing that for answers is its own piece of work.
- **A generic audit table over every user-authored table** (approach B). Revisit when a third table needs it.
- **Undo in the UI.** Recovery here is an operator action.
- **Retention on the history table.** Unbounded for now; the `WHEN` clause plus Task 2 Step 5 keep the volume honest.
