# Civic Spaces display_name Fallback — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop `POST /api/civic-spaces/assign` 500ing for a Connected user with no base `display_name`, by making the account contract never return a null/empty name and giving genuinely nameless accounts a stable pseudonym.

**Architecture:** All name-resolution logic lives in one pure, well-tested helper (`lib/displayName.ts`). The three call sites — the account contract (`getAccountMe`), the Civic Spaces writer (`upsertConnectedProfile`), and WorkOS provisioning — become trivial one-line applications of that helper. A guarded, idempotent backfill copies each affected user's already-chosen Connected pseudonym into their null base name.

**Tech Stack:** TypeScript (ESM, `.js` import specifiers), Node, `pg`, Express, Vitest 4, Postgres (Supabase project `kxsdzaojfaibhuzmclfq`).

## Global Constraints

- Report to Chris in **ASD-STE100 Simplified Technical English** (chat only; code/comments/commit messages follow repo convention).
- ESM imports use the `.js` extension even for `.ts` sources.
- Migrations: **allocate the number from the steward allocator, never count.** Namespace `CA_` (Chris Andrews). Cite the full slot (e.g. `CA_0113`).
- Migrations are idempotent and end with a `DO $$ … $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count. Dry-run on prod with `BEGIN; … ROLLBACK;` first.
- Commit with an **explicit pathspec** (`git commit -F msg -- <path>`) — the worktree is shared.
- Name format for auto-generated pseudonyms: **`RapidWolverine`** (CamelCase `AdjectiveAnimal`).
- Uniqueness is **best-effort on auto-names only** (no DB unique constraint; no change to human name flows).
- Branch: `fix/civic-spaces-display-name-fallback` (worktree already created off `origin/master`).
- Prod writes (migration apply) and outward actions (push, PR) are **gated on Chris's explicit go-ahead**.

---

## File Structure

- **Create** `backend/src/lib/displayName.ts` — word lists + `firstNonBlank`, `deterministicAutoName`, `generateUniqueAutoName`. The one home for name logic.
- **Create** `backend/src/lib/displayName.test.ts` — unit tests for the helper.
- **Modify** `backend/src/lib/accountMeService.ts` — resolve top-level `display_name` through the helper (~line 180-184).
- **Modify** `backend/src/civic_spaces/services/sliceAssigner.ts` — coalesce in `upsertConnectedProfile` (~line 182-197).
- **Modify** `backend/src/civic_spaces/services/sliceAssigner.test.ts` — add a pool mock + guard tests.
- **Modify** `backend/src/lib/workosProvisionService.ts` — mint a pseudonym when AuthKit gives no name (~line 99-117).
- **Create** `backend/migrations/CA_00NN_backfill_display_name_from_pseudonym.sql` — backfill (number from allocator).

---

### Task 1: The `displayName` helper (pure logic, fully tested)

**Files:**
- Create: `backend/src/lib/displayName.ts`
- Test: `backend/src/lib/displayName.test.ts`

**Interfaces:**
- Produces:
  - `firstNonBlank(...values: Array<string | null | undefined>): string | undefined`
  - `deterministicAutoName(seed: string): string`
  - `interface Queryable { query<T = unknown>(text: string, params?: unknown[]): Promise<{ rows: T[] }> }`
  - `generateUniqueAutoName(db: Queryable): Promise<string>`

- [ ] **Step 1: Write the failing test**

Create `backend/src/lib/displayName.test.ts`:

```ts
import { describe, it, expect, vi } from 'vitest'
import {
  firstNonBlank,
  deterministicAutoName,
  generateUniqueAutoName,
  type Queryable,
} from './displayName.js'

describe('firstNonBlank', () => {
  it('returns the first non-whitespace string, trimmed', () => {
    expect(firstNonBlank(null, undefined, '  ', '  Explorer  ')).toBe('Explorer')
  })
  it('returns undefined when everything is blank', () => {
    expect(firstNonBlank(null, undefined, '', '   ')).toBeUndefined()
  })
})

describe('deterministicAutoName', () => {
  it('is stable for a given seed', () => {
    expect(deterministicAutoName('user-abc')).toBe(deterministicAutoName('user-abc'))
  })
  it('is a non-empty CamelCase AdjectiveAnimal', () => {
    expect(deterministicAutoName('user-abc')).toMatch(/^[A-Z][a-z]+[A-Z][a-z]+$/)
  })
})

describe('generateUniqueAutoName', () => {
  it('returns the base name when it is free (one DB check)', async () => {
    const db = { query: vi.fn().mockResolvedValue({ rows: [] }) } as unknown as Queryable
    const name = await generateUniqueAutoName(db)
    expect(name).toMatch(/^[A-Z][a-z]+[A-Z][a-z]+$/)
    expect((db.query as ReturnType<typeof vi.fn>)).toHaveBeenCalledTimes(1)
  })
  it('appends a number when the base name is taken', async () => {
    const query = vi.fn()
      .mockResolvedValueOnce({ rows: [{ one: 1 }] }) // base taken
      .mockResolvedValueOnce({ rows: [] })            // base+2 free
    const db = { query } as unknown as Queryable
    const name = await generateUniqueAutoName(db)
    expect(name).toMatch(/2$/)
    expect(query).toHaveBeenCalledTimes(2)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test --prefix backend -- src/lib/displayName.test.ts`
Expected: FAIL — cannot resolve `./displayName.js` (module does not exist yet).

- [ ] **Step 3: Write minimal implementation**

Create `backend/src/lib/displayName.ts`:

```ts
/**
 * displayName — the single home for the account contract's "never null/empty" name guarantee.
 *
 * WHY THIS EXISTS
 * getAccountMe returns a top-level display_name that consumers (the folded Civic Spaces slice
 * assigner among them) write into NOT NULL columns. A null base name (public.users) with the
 * user's chosen pseudonym stranded in connect.connected_profiles produced a 500 on /assign
 * (ev-cto watchlist #70). This module resolves the name, and when there is genuinely none it
 * mints a pseudonym. For Inform/Connected accounts display_name IS the pseudonym — there is no
 * separate real name — so an auto-generated one is a valid identity.
 */

// Curated so no AdjectiveAnimal pair reads as an insult. CamelCase pieces; the joined form is
// e.g. "RapidWolverine" (decision 2026-09-13, Chris Andrews).
const ADJECTIVES = [
  'Amber', 'Autumn', 'Bold', 'Brave', 'Bright', 'Calm', 'Cedar', 'Clever', 'Cobalt', 'Coral',
  'Cosmic', 'Crimson', 'Daring', 'Dawn', 'Eager', 'Ember', 'Fair', 'Gentle', 'Golden', 'Grand',
  'Hazel', 'Humble', 'Indigo', 'Ivory', 'Jade', 'Jolly', 'Keen', 'Kind', 'Lively', 'Loyal',
  'Lunar', 'Mellow', 'Merry', 'Mighty', 'Noble', 'Olive', 'Onyx', 'Placid', 'Quick', 'Quiet',
  'Rapid', 'Ruby', 'Sage', 'Scarlet', 'Silver', 'Solar', 'Spry', 'Stellar', 'Sunny', 'Swift',
  'Teal', 'Tidal', 'Trusty', 'Valiant', 'Vivid', 'Witty',
]

const ANIMALS = [
  'Otter', 'Wolverine', 'Falcon', 'Heron', 'Bison', 'Marten', 'Osprey', 'Lynx', 'Puffin',
  'Badger', 'Beaver', 'Sparrow', 'Finch', 'Marmot', 'Ibis', 'Crane', 'Egret', 'Salmon', 'Sable',
  'Stoat', 'Tapir', 'Vole', 'Wren', 'Gecko', 'Newt', 'Quail', 'Raven', 'Robin', 'Skink', 'Turtle',
  'Vireo', 'Walrus', 'Whale', 'Bittern', 'Dunlin', 'Godwit', 'Kestrel', 'Merlin', 'Plover',
  'Hare', 'Moose', 'Pika',
]

export function firstNonBlank(...values: Array<string | null | undefined>): string | undefined {
  for (const v of values) {
    if (typeof v === 'string') {
      const trimmed = v.trim()
      if (trimmed !== '') return trimmed
    }
  }
  return undefined
}

// FNV-1a 32-bit — a tiny dependency-free stable hash. It only indexes the word lists, so its
// statistical quality is irrelevant; stability across processes is the whole point.
function hash32(seed: string): number {
  let h = 0x811c9dc5
  for (let i = 0; i < seed.length; i++) {
    h ^= seed.charCodeAt(i)
    h = Math.imul(h, 0x01000193)
  }
  return h >>> 0
}

function pair(a: number, b: number): string {
  return ADJECTIVES[a % ADJECTIVES.length] + ANIMALS[b % ANIMALS.length]
}

/**
 * A stable pseudonym derived from a seed (the user id). Same seed → same name forever, with no
 * stored state and no DB round-trip. Used only as the read-time last-resort guard in
 * getAccountMe and the write guard in upsertConnectedProfile — it fires only for an account
 * with no name ANYWHERE, which after the backfill and sign-up enforcement is essentially never.
 * It is NOT uniqueness-checked (a read path cannot be), so it is deliberately not how a name is
 * normally assigned — see generateUniqueAutoName.
 */
export function deterministicAutoName(seed: string): string {
  const h = hash32(seed)
  return pair(h, h >>> 8)
}

export interface Queryable {
  query<T = unknown>(text: string, params?: unknown[]): Promise<{ rows: T[] }>
}

/**
 * A random pseudonym that is free at creation time: pick an AdjectiveAnimal, and if
 * public.users already holds it (case-insensitive) append 2, 3, … until free. Best-effort:
 * there is a negligible TOCTOU window between this check and the caller's insert, acceptable
 * for the only caller (a no-name WorkOS sign-up). Names are not globally unique by constraint;
 * this only stops auto-names from colliding, which is the RapidWolverine concern.
 */
export async function generateUniqueAutoName(db: Queryable): Promise<string> {
  for (let attempt = 0; attempt < 8; attempt++) {
    const h = hash32(`${Date.now()}-${Math.random()}-${attempt}`)
    const base = pair(h, h >>> 8)
    for (let n = 0; n < 50; n++) {
      const candidate = n === 0 ? base : `${base}${n + 1}`
      const { rows } = await db.query<{ one: number }>(
        `SELECT 1 AS one FROM public.users WHERE lower(btrim(display_name)) = lower($1) LIMIT 1`,
        [candidate]
      )
      if (rows.length === 0) return candidate
    }
  }
  // Astronomically unlikely exhaustion — a time-seeded name no check cleared, still non-empty,
  // so the never-null guarantee holds.
  return deterministicAutoName(`${Date.now()}-${Math.random()}`)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test --prefix backend -- src/lib/displayName.test.ts`
Expected: PASS (all cases green).

- [ ] **Step 5: Commit**

```bash
git add -- backend/src/lib/displayName.ts backend/src/lib/displayName.test.ts
git commit -F- -- backend/src/lib/displayName.ts backend/src/lib/displayName.test.ts <<'EOF'
feat(account): displayName helper — resolve, and mint, a never-blank pseudonym

firstNonBlank + deterministicAutoName + generateUniqueAutoName. Pure logic behind the
watchlist #70 fix; the call sites in later commits are one-liners over this.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
```

---

### Task 2: Account contract never returns null/empty

**Files:**
- Modify: `backend/src/lib/accountMeService.ts` (import + the `display_name` line, ~183)

**Interfaces:**
- Consumes: `firstNonBlank`, `deterministicAutoName` (Task 1).
- Produces: `getAccountMe` top-level `display_name` is always a non-blank string.

**Testing note:** `getAccountMe` is not unit-tested in this repo — its import chain calls `getRequestAuthUser`, `requestDb`, `adminRpc`, `isUserAdmin`, `pool`, and `lib/env` (which `process.exit`s under vitest). The resolution *logic* is fully covered by Task 1's helper tests; this task keeps the code change to a single obviously-correct expression and verifies it with `tsc` (Step 3) and the live check in Task 6.

- [ ] **Step 1: Add the import**

In `backend/src/lib/accountMeService.ts`, after the existing `import { isUserAdmin } from './adminService.js';` line, add:

```ts
import { firstNonBlank, deterministicAutoName } from './displayName.js';
```

- [ ] **Step 2: Resolve the name through the helper**

Replace the top-level `display_name: user.display_name,` line (inside the `meResponse` object, ~line 183) with:

```ts
    display_name:
      firstNonBlank(
        user.display_name as string | null | undefined,
        connected?.display_name as string | null | undefined,
      ) ?? deterministicAutoName(user.id as string),
```

(The row already selects `connected.display_name` at line 51, so no query change is needed. This is: base name → Connected pseudonym → deterministic pseudonym.)

- [ ] **Step 3: Type-check**

Run: `npm run build --prefix backend`
Expected: PASS (no TypeScript errors).

- [ ] **Step 4: Commit**

```bash
git commit -F- -- backend/src/lib/accountMeService.ts <<'EOF'
fix(account): getAccountMe never returns a null/empty display_name (watchlist #70)

Resolve the top-level name base → Connected pseudonym → deterministic pseudonym. This is
what surfaces chantrygilbert / Explorer / TESTING-Info-ev, whose base name is null while
their chosen pseudonym sits in connect. Protects every /api/account/me consumer.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
```

---

### Task 3: Second guard in `upsertConnectedProfile`

**Files:**
- Modify: `backend/src/civic_spaces/services/sliceAssigner.ts` (import + `upsertConnectedProfile`)
- Test: `backend/src/civic_spaces/services/sliceAssigner.test.ts` (add a pool mock + two tests)

**Interfaces:**
- Consumes: `firstNonBlank`, `deterministicAutoName` (Task 1).
- Produces: `upsertConnectedProfile` writes a non-blank `display_name` even if handed a blank.

- [ ] **Step 1: Write the failing test**

In `backend/src/civic_spaces/services/sliceAssigner.test.ts`, add a hoisted pool mock. At the very top, immediately after the existing `vi.mock('../../lib/env.js', () => ({ env: {} }))` line, add:

```ts
const { queryMock } = vi.hoisted(() => ({ queryMock: vi.fn() }))
vi.mock('../config/database.js', () => ({ pool: { query: queryMock } }))
```

Add `upsertConnectedProfile` to the existing import from `./sliceAssigner.js` (change the import line to include it), and add `beforeEach` to the vitest import. Then append this block to the end of the file:

```ts
describe('upsertConnectedProfile display_name guard', () => {
  beforeEach(() => queryMock.mockReset())

  it('coalesces a blank name to a non-blank pseudonym', async () => {
    queryMock.mockResolvedValue({ rows: [] })
    await upsertConnectedProfile('user-123', '   ', 'active')
    const params = queryMock.mock.calls[0][1] as unknown[]
    expect(params[1]).toMatch(/^[A-Z][a-z]+[A-Z][a-z]+$/) // deterministic AdjectiveAnimal
  })

  it('passes a real name through unchanged', async () => {
    queryMock.mockResolvedValue({ rows: [] })
    await upsertConnectedProfile('user-123', 'Explorer', 'active')
    const params = queryMock.mock.calls[0][1] as unknown[]
    expect(params[1]).toBe('Explorer')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test --prefix backend -- src/civic_spaces/services/sliceAssigner.test.ts`
Expected: FAIL — the blank name currently passes through, so `params[1]` is `'   '`, not an `AdjectiveAnimal` (and `upsertConnectedProfile` may not yet be imported).

- [ ] **Step 3: Implement the guard**

In `backend/src/civic_spaces/services/sliceAssigner.ts`, add the import near the top (after the existing `AccountData` import):

```ts
import { firstNonBlank, deterministicAutoName } from '../../lib/displayName.js'
```

Replace the body of `upsertConnectedProfile` (keep the signature) so it computes a safe name first:

```ts
async function upsertConnectedProfile(
  userId: string,
  displayName: string,
  accountStanding: string
): Promise<void> {
  // Second guard behind getAccountMe (watchlist #70): the target column is NOT NULL, so a
  // blank must never reach it even if a caller passes one. getAccountMe already guarantees a
  // non-blank name; this makes upsertConnectedProfile safe on its own too.
  const safeName = firstNonBlank(displayName) ?? deterministicAutoName(userId)
  // updated_at is maintained by the trg_connected_profiles_updated_at BEFORE UPDATE trigger,
  // so it is deliberately not set here (matches the standalone's supabase upsert).
  await pool.query(
    `INSERT INTO connected_profiles (user_id, display_name, account_standing)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id) DO UPDATE
       SET display_name = EXCLUDED.display_name,
           account_standing = EXCLUDED.account_standing`,
    [userId, safeName, accountStanding]
  )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test --prefix backend -- src/civic_spaces/services/sliceAssigner.test.ts`
Expected: PASS (existing taxonomy tests still green; the two new guard tests green).

- [ ] **Step 5: Commit**

```bash
git commit -F- -- backend/src/civic_spaces/services/sliceAssigner.ts backend/src/civic_spaces/services/sliceAssigner.test.ts <<'EOF'
fix(civic-spaces): coalesce display_name in upsertConnectedProfile (watchlist #70)

Belt-and-braces: a blank can never reach the NOT NULL connected_profiles.display_name,
even if a caller passes one.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
```

---

### Task 4: Sign-up enforcement in WorkOS provisioning

**Files:**
- Modify: `backend/src/lib/workosProvisionService.ts` (import + the `created` branch, ~99-117)

**Interfaces:**
- Consumes: `generateUniqueAutoName` (Task 1); the module already imports `pool` from `./db.js`.

**Testing note:** `workosProvisionService` has no test harness (it drives live WorkOS `fetch` calls). The generation logic is covered by Task 1; this task keeps the edit minimal and non-fatal, and is exercised end-to-end by the live check in Task 6.

- [ ] **Step 1: Add the import**

In `backend/src/lib/workosProvisionService.ts`, after `import { env } from './env.js';`, add:

```ts
import { generateUniqueAutoName } from './displayName.js';
```

- [ ] **Step 2: Mint a name when AuthKit gives none**

Replace the `if (created) { … }` block (~99-117) with:

```ts
    if (created) {
      // Best-effort display name from the AuthKit signup form. Non-fatal — the profile page
      // can set it later (same policy as the signup route).
      let displayName = [workosUser.first_name, workosUser.last_name]
        .filter(Boolean)
        .join(' ')
        .trim();
      if (!displayName) {
        // No name from AuthKit: mint a best-effort-unique pseudonym so the account never
        // reaches Connected tier nameless (watchlist #70). Non-fatal.
        try {
          displayName = await generateUniqueAutoName(pool);
        } catch (err) {
          console.error('[workosProvision] auto-name generation failed (non-fatal):', err);
        }
      }
      if (displayName) {
        try {
          await pool.query(
            `UPDATE public.users SET display_name = $2, updated_at = now()
             WHERE id = $1 AND display_name IS NULL`,
            [userId, displayName]
          );
        } catch (err) {
          console.error('[workosProvision] display_name update failed (non-fatal):', err);
        }
      }
    }
```

- [ ] **Step 3: Type-check + lint**

Run: `npm run build --prefix backend && npm run lint --prefix backend`
Expected: PASS. (The new `catch` only logs — it does not re-throw — so the `preserve-caught-error` rule does not apply.)

- [ ] **Step 4: Commit**

```bash
git commit -F- -- backend/src/lib/workosProvisionService.ts <<'EOF'
fix(auth): give a no-name WorkOS sign-up an auto pseudonym at provisioning (watchlist #70)

A hosted AuthKit sign-up with no first/last name left public.users.display_name null,
which is the live source of the /assign 500. Mint a best-effort-unique pseudonym instead.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
```

---

### Task 5: Backfill migration (allocate the number — do not count)

**Files:**
- Create: `backend/migrations/CA_00NN_backfill_display_name_from_pseudonym.sql` (NN from the allocator)

- [ ] **Step 1: Reserve the slot**

Run:

```bash
npm run steward --prefix backend -- slot CA --purpose "backfill null/empty public.users.display_name from connect.connected_profiles pseudonym (watchlist #70)"
```

Record the returned slot (e.g. `CA_0113`) and name the file **exactly** that number. Do not count by hand.

- [ ] **Step 2: Write the migration**

Create `backend/migrations/CA_00NN_backfill_display_name_from_pseudonym.sql` (replace `CA_00NN` with the reserved slot):

```sql
BEGIN;

-- =============================================================================
-- CA_00NN: backfill null/empty public.users.display_name from the Connected pseudonym
-- =============================================================================
-- Created 2026-09-13 with Chris Andrews. ev-cto watchlist #70.
--
-- WHY
-- getAccountMe returned a null base name for 3 Connected users whose chosen pseudonym
-- (chantrygilbert / Explorer / TESTING-Info-ev) lives only in connect.connected_profiles.
-- The folded Civic Spaces assigner writes that null into the NOT NULL
-- civic_spaces.connected_profiles.display_name and 500s on /assign. For the other 9
-- Connected users the base name already equals the pseudonym; these 3 are the rows where
-- the base name was left null by the WorkOS/older path. Restore the invariant.
--
-- No migration runner (see CLAUDE.md): applied once, ad hoc. Idempotent — safe to re-run.
-- =============================================================================

UPDATE public.users u
   SET display_name = btrim(cp.display_name),
       updated_at   = now()
  FROM connect.connected_profiles cp
 WHERE cp.user_id = u.id
   AND (u.display_name IS NULL OR btrim(u.display_name) = '')
   AND cp.display_name IS NOT NULL
   AND btrim(cp.display_name) <> '';

-- Post-verify gate: no Connected user may keep a null/empty base name while a usable
-- pseudonym exists. (A user with no pseudonym anywhere — none today — is left null and
-- covered by the runtime guard; SQL does not own the word lists, so it mints no auto-names.)
DO $$
DECLARE
  remaining int;
BEGIN
  SELECT count(*) INTO remaining
    FROM connect.connected_profiles cp
    JOIN public.users u ON u.id = cp.user_id
   WHERE (u.display_name IS NULL OR btrim(u.display_name) = '')
     AND cp.display_name IS NOT NULL
     AND btrim(cp.display_name) <> '';
  IF remaining <> 0 THEN
    RAISE EXCEPTION 'CA_00NN backfill incomplete: % Connected users still lack a base name but have a pseudonym', remaining;
  END IF;
END $$;

COMMIT;
```

- [ ] **Step 3: Dry-run against prod (rolls back)**

Using the Supabase `execute_sql` tool on project `kxsdzaojfaibhuzmclfq`, run the migration body wrapped so it reverts, and confirm the gate does not raise:

```sql
BEGIN;
UPDATE public.users u
   SET display_name = btrim(cp.display_name), updated_at = now()
  FROM connect.connected_profiles cp
 WHERE cp.user_id = u.id
   AND (u.display_name IS NULL OR btrim(u.display_name) = '')
   AND cp.display_name IS NOT NULL AND btrim(cp.display_name) <> '';
-- expect 3 rows updated
SELECT u.id::text, u.display_name
  FROM public.users u
 WHERE u.id IN ('d956ffac-3e60-4cfb-9ede-dbfc29e370e4',
                '9a469231-d594-4cba-8af2-df6326dcc24d',
                '5c0e6906-33ea-4956-8953-a3a1f2297549');
-- expect chantrygilbert / Explorer / TESTING-Info-ev
ROLLBACK;
```

Expected: the three rows now show their pseudonyms; `ROLLBACK` reverts. Confirm afterward the rollback held (re-run the SELECT outside a transaction → still null).

- [ ] **Step 4: Confirm the reservation is recorded**

Run: `npm run steward --prefix backend -- sync`
Expected: the reserved `CA_00NN` slot is listed (no drift warnings against it).

- [ ] **Step 5: Commit the migration file**

```bash
git commit -F- -- backend/migrations/CA_00NN_backfill_display_name_from_pseudonym.sql <<'EOF'
fix(db): CA_00NN backfill null base display_name from the Connected pseudonym (watchlist #70)

Restores base name = pseudonym for the 3 Connected users whose base name was left null.
Guarded, idempotent, post-verify gated.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
```

- [ ] **Step 6: Apply to prod — GATED on Chris**

Do **not** apply automatically. Ask Chris to confirm. On go-ahead, run the committed migration body (with `COMMIT`) via `execute_sql` on `kxsdzaojfaibhuzmclfq`, then verify:

```sql
SELECT count(*) AS still_null
  FROM connect.connected_profiles cp
  JOIN public.users u ON u.id = cp.user_id
 WHERE (u.display_name IS NULL OR btrim(u.display_name) = '')
   AND cp.display_name IS NOT NULL AND btrim(cp.display_name) <> '';
-- expect 0
```

---

### Task 6: Full verification + hand-off

**Files:** none (verification only).

- [ ] **Step 1: Build, lint, and run the touched tests**

Run:
```bash
npm run build --prefix backend
npm run lint --prefix backend
npm run test --prefix backend -- src/lib/displayName.test.ts src/civic_spaces/services/sliceAssigner.test.ts
npm run check:reservations --prefix backend
```
Expected: build + lint clean; all listed tests pass; the reservation check passes (slot reserved by this author).

- [ ] **Step 2: Live check — GATED on Chris (needs an authenticated session)**

After the migration is applied (Task 5 Step 6) and the branch is deployed to a preview/prod, confirm end-to-end:
- The three previously-broken users now resolve a name: re-run the null-name query from Task 5 Step 6 → `0`.
- A no-name account can sign in and `POST /api/civic-spaces/assign` returns **200** with `slice_members` rows written (Chris drives, or use a fresh throwaway WorkOS sign-up with no name).
- Re-check Supabase `postgres_logs` (source `postgres_logs`, filter `display_name`) shows **no new** `null value in column "display_name"` errors.

- [ ] **Step 3: Open the PR — GATED on Chris**

On Chris's go-ahead: push `fix/civic-spaces-display-name-fallback` and open a PR against `master` (repo `chrisandrewsedu`/`ev-accounts`… confirm the remote), body summarizing the fix, linking watchlist #70, and noting the migration was applied to prod. End the PR body with:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

---

## Self-Review

**Spec coverage:**
- Product answer (existing pseudonym; auto-name for the truly nameless) → Tasks 1, 2, 5. ✓
- `getAccountMe` never null/empty → Task 2. ✓
- `upsertConnectedProfile` coalesce → Task 3. ✓
- Backfill the null/empty rows → Task 5. ✓
- Enforce at sign-up / provisioning → Task 4. ✓
- Best-effort unique auto-names → Task 1 (`generateUniqueAutoName`). ✓
- Verification (200 + no null-column errors) → Task 6. ✓
- Out of scope (enforced unique handles, trigger change) → untouched. ✓

**Placeholder scan:** Word lists are written out in full; `CA_00NN` is the required allocator placeholder, resolved in Task 5 Step 1 (not a content gap). No TBD/TODO/"handle edge cases". ✓

**Type consistency:** `firstNonBlank`, `deterministicAutoName`, `generateUniqueAutoName(db: Queryable)`, and `Queryable` are named identically across Tasks 1–4. The `display_name` resolution expression matches the helper signatures. ✓
