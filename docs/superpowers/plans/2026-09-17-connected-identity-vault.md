# Connect Identity Vault — Phase A Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the full software surface of the two-key identity vault so a Connect member's real name and raw address are sealed on write and readable only by two of four board members offline — with the vault path gated off until the offline key ceremony runs.

**Architecture:** Envelope encryption. The app holds only an X25519 **public key** and seals name/address with libsodium `crypto_box_seal` into an isolated `id_vault` schema it can write but never read. The matching private key is split 2-of-4 with Shamir (`secrets.js-grempe`) and lives only offline. An offline break-glass CLI reconstructs the key from any two shares to decrypt one user, requiring a logged `--reason`. All write paths are gated on an `ID_VAULT_PUBLIC_KEY` env var: unset ⇒ today's behaviour.

**Tech Stack:** TypeScript (ESM), Node 26, Express, Postgres (`pg` pool + supabase-js `adminRpc`), vitest (DB mocked via `vi.mock`), `libsodium-wrappers`, `secrets.js-grempe`, `tsx` for `.mts` scripts.

**Spec:** [`docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md`](../specs/2026-09-17-connected-identity-vault-design.md). Read it first.

## Global Constraints

- **ESM only.** `"type": "module"`; imports use `.js` extensions for local TS (e.g. `import { pool } from './db.js'`).
- **Migration steward, CA namespace = Andrews.** Never count by hand. `npm run steward --prefix backend -- slot CA --purpose "…"` for each migration; name the file that number immediately. `git fetch origin` before `npm run check:migrations --prefix backend`.
- **Migration house style.** Idempotent (`IF NOT EXISTS`, guards); end with a `DO $$ … $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count; dry-run `BEGIN; … ROLLBACK;` against prod before trusting.
- **Own worktree + pathspec commits.** Work in the `feat/connect-identity-vault` worktree (Setup). Every commit uses an explicit pathspec: `git commit -F <msg> -- <paths>`. Never `git add -A`/`.` at any level.
- **Secret material never online.** No private key or Shamir share in an env var, the DB, a committed file, or this repo. The app config holds only `ID_VAULT_PUBLIC_KEY` (safe) + `ID_VAULT_KEY_VERSION`.
- **`legal_name` is nullable** — passing `NULL` and nulling the column need no constraint change.
- **Do NOT** build the uniqueness/nullifier here; put no share/private key online; write no names into WorkOS.
- Commit message trailer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

## File structure

**Create:**
- `backend/src/lib/idVaultCrypto.ts` — pure crypto primitives (seal, open, keygen, Shamir split/combine). Imported by the app lib, the CLIs, and tests. No env, no DB.
- `backend/src/lib/idVaultCrypto.test.ts` — seal/open round-trip, keygen, 2-of-4 split/combine.
- `backend/src/lib/idVault.ts` — app-facing seal lib: `isVaultEnabled`, `sealName`, `sealAddress`, `upsertSeal`. Imports only `sealTo` + `env`. **No open/decrypt.**
- `backend/src/lib/idVault.test.ts` — gating, seal, `upsertSeal` (mocked pool), and the "app holds no secret key / no decrypt export" assertion.
- `backend/scripts/id-vault-keygen.mts` — offline: generate keypair, print public key + version, split private key to four share files.
- `backend/scripts/id-vault-keygen.test.ts` — keygen `run()` produces 4 shares that reconstruct + a working public key.
- `backend/scripts/id-vault-backfill.mts` — offline: seal existing `legal_name` rows into the vault (idempotent, `--dry-run` default). Written, not run.
- `backend/scripts/id-vault-backfill.test.ts` — seals fetched rows, idempotent, dry-run writes nothing.
- `backend/scripts/id-vault-break-glass.mts` — offline: combine ≥2 shares, decrypt one user, require `--reason`, append audit log.
- `backend/scripts/id-vault-break-glass.test.ts` — pure `breakGlass()` core: 2 shares decrypt; 1 fails; refuses without reason; writes audit line.
- `backend/scripts/README-id-vault.md` — custody, two-person rule, ceremony, drill, phase runbook.
- `backend/migrations/CA_<schema>_id_vault_schema.sql` — schema, table, grants, RLS, post-verify gate.
- `backend/migrations/CA_<null>_null_connected_legal_name.sql` — null the column (written, applied only in Phase C).

**Modify:**
- `backend/package.json` — add `libsodium-wrappers`, `secrets.js-grempe` (+ types/shim).
- `backend/src/lib/env.ts` — add `ID_VAULT_PUBLIC_KEY`, `ID_VAULT_KEY_VERSION`.
- `backend/src/routes/auth.ts` (~314–355) — gated seal-on-signup.
- `backend/src/routes/connect.ts` (`/set-location`, ~590–612) — gated seal-on-address.
- `backend/src/lib/empowerService.ts` (`runPreflight`, `confirmEmpowerment`) — optional confirmed name, DB fallback.
- `backend/src/routes/empower.ts` (`ConfirmSchema`, `/confirm`, `/preflight`) — accept optional `legal_name`.
- `backend/src/lib/adminService.ts` (`getAccountDetail`) — strip `legal_name`.
- `backend/src/routes/admin.ts` (~291) — drop `legal_name` from `viewed_fields`.

---

## Setup (before Task 1)

- [ ] **S1: Create the worktree off a fresh master**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts
git fetch origin
git worktree add -b feat/connect-identity-vault /Users/chrisandrews/Documents/GitHub/ev-accounts-idvault origin/master
```

- [ ] **S2: Bring the spec + this plan into the worktree and commit them first**

```bash
mkdir -p /Users/chrisandrews/Documents/GitHub/ev-accounts-idvault/docs/superpowers/{specs,plans}
cp docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md \
   /Users/chrisandrews/Documents/GitHub/ev-accounts-idvault/docs/superpowers/specs/
cp docs/superpowers/plans/2026-09-17-connected-identity-vault.md \
   /Users/chrisandrews/Documents/GitHub/ev-accounts-idvault/docs/superpowers/plans/
cd /Users/chrisandrews/Documents/GitHub/ev-accounts-idvault
npm --prefix backend install   # sanity: deps resolve in the new worktree
git commit -m "docs(privacy): identity-vault spec + Phase A plan" -- docs/superpowers/
```

All later paths are relative to the worktree root `/Users/chrisandrews/Documents/GitHub/ev-accounts-idvault`.

---

## Task 1: Dependencies + env vars

**Files:**
- Modify: `backend/package.json`
- Modify: `backend/src/lib/env.ts`
- Test: `backend/src/lib/env.test.ts` (create if absent)

**Interfaces:**
- Produces: `env.ID_VAULT_PUBLIC_KEY: string | undefined`, `env.ID_VAULT_KEY_VERSION: number | undefined`.

- [ ] **Step 1: Install the crypto libraries**

```bash
npm --prefix backend install libsodium-wrappers secrets.js-grempe
npm --prefix backend install -D @types/libsodium-wrappers
```

- [ ] **Step 2: If `@types/secrets.js-grempe` is unavailable, add a shim**

Create `backend/src/types/secrets.js-grempe.d.ts`:

```ts
declare module 'secrets.js-grempe' {
  export function share(secretHex: string, numShares: number, threshold: number, padLength?: number): string[];
  export function combine(shares: string[]): string;
  export function random(bits: number): string;
  export function str2hex(str: string): string;
  export function hex2str(hex: string): string;
}
```

- [ ] **Step 3: Add the vault env vars to the zod schema**

In `backend/src/lib/env.ts`, inside `envSchema = z.object({ … })`, add:

```ts
  // Identity vault (ev-cto decision 0022). PUBLIC key only — safe to hold.
  // Absent = vault disabled: name/address keep today's storage. Set after the
  // offline key ceremony (Phase B) to switch writes to the sealed vault.
  ID_VAULT_PUBLIC_KEY: z.string().optional(),
  ID_VAULT_KEY_VERSION: z.coerce.number().int().positive().optional(),
```

- [ ] **Step 4: Write the failing test**

`backend/src/lib/env.test.ts`:

```ts
import { describe, it, expect } from 'vitest';

describe('env — identity vault vars', () => {
  it('exposes the vault vars as optional (undefined when unset)', async () => {
    const { env } = await import('./env.js');
    expect('ID_VAULT_PUBLIC_KEY' in env).toBe(true);
    // In the test environment they are unset:
    expect(env.ID_VAULT_KEY_VERSION === undefined || typeof env.ID_VAULT_KEY_VERSION === 'number').toBe(true);
  });
});
```

- [ ] **Step 5: Run it**

Run: `npm --prefix backend test -- src/lib/env.test.ts`
Expected: PASS (fields present, optional).

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(id-vault): add libsodium + secrets.js deps and vault env vars" -- \
  backend/package.json backend/package-lock.json backend/src/lib/env.ts \
  backend/src/lib/env.test.ts backend/src/types/secrets.js-grempe.d.ts
```

---

## Task 2: `id_vault` schema migration

> **REVISED 2026-09-17 (see spec §4.1).** Probing prod showed `ev_api` is `BYPASSRLS` (so RLS can't
> constrain it) and `ON CONFLICT DO UPDATE` requires SELECT. The migration therefore uses a
> **SECURITY DEFINER function `id_vault.seal_upsert(...)`** owned by the superuser migration role, with
> `ev_api` granted EXECUTE and **no direct table privilege**. The grant+RLS sketch in the steps below is
> superseded by the committed file `backend/migrations/CA_0118_id_vault_schema.sql` — treat that file
> (verified against prod: `ev_api` seals via the function; direct SELECT/INSERT both denied) as the
> source of truth. Slot **CA_0118** is already reserved by the controller (skip Step 1).

**Files:**
- Create: `backend/migrations/CA_0118_id_vault_schema.sql`

**Interfaces:**
- Produces: schema `id_vault`; table `id_vault.sealed_identities(user_id uuid PK → public.users(id) ON DELETE CASCADE, sealed_name bytea, sealed_address bytea, key_version smallint NOT NULL, sealed_at timestamptz)`; function `id_vault.seal_upsert(uuid, bytea, bytea, smallint)` (SECURITY DEFINER); `ev_api` has USAGE on the schema + EXECUTE on the function and **no direct table privilege**.

- [ ] **Step 1: Reserve the slot**

```bash
npm run steward --prefix backend -- slot CA --purpose "id_vault schema + sealed_identities table + grants"
# -> e.g. CA_0116 ; name the file that number immediately
```

- [ ] **Step 2: Write the migration** (`CA_0116_id_vault_schema.sql`, substitute the real number)

```sql
-- CA_0116 — Identity vault store (ev-cto decision 0022, spec 2026-09-17).
-- App can WRITE (seal) but never READ ciphertext; decryption is off-DB.
BEGIN;

CREATE SCHEMA IF NOT EXISTS id_vault;

CREATE TABLE IF NOT EXISTS id_vault.sealed_identities (
  user_id        uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  sealed_name    bytea,
  sealed_address bytea,
  key_version    smallint NOT NULL,
  sealed_at      timestamptz NOT NULL DEFAULT now()
);

-- Lock it down: nobody reads ciphertext through the app roles.
REVOKE ALL ON SCHEMA id_vault FROM PUBLIC;
REVOKE ALL ON id_vault.sealed_identities FROM PUBLIC;
GRANT USAGE ON SCHEMA id_vault TO ev_api;

-- ev_api seals (writes) and may check existence/version/time — never the bytea.
GRANT INSERT, UPDATE, DELETE ON id_vault.sealed_identities TO ev_api;
GRANT SELECT (user_id, key_version, sealed_at) ON id_vault.sealed_identities TO ev_api;

-- Default-deny RLS; a single policy lets ev_api write its rows. No SELECT policy.
ALTER TABLE id_vault.sealed_identities ENABLE ROW LEVEL SECURITY;
ALTER TABLE id_vault.sealed_identities FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ev_api_write ON id_vault.sealed_identities;
CREATE POLICY ev_api_write ON id_vault.sealed_identities
  FOR ALL TO ev_api USING (true) WITH CHECK (true);

-- Post-verify gate.
DO $$
DECLARE
  v_has_schema boolean;
  v_has_table  boolean;
  v_select_cols int;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'id_vault')
    INTO v_has_schema;
  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'id_vault' AND table_name = 'sealed_identities')
    INTO v_has_table;
  -- ev_api must NOT hold SELECT on the ciphertext columns.
  SELECT count(*) INTO v_select_cols
    FROM information_schema.column_privileges
    WHERE grantee = 'ev_api' AND table_schema = 'id_vault'
      AND table_name = 'sealed_identities' AND privilege_type = 'SELECT'
      AND column_name IN ('sealed_name', 'sealed_address');
  IF NOT v_has_schema OR NOT v_has_table THEN
    RAISE EXCEPTION 'id_vault schema/table missing after migration';
  END IF;
  IF v_select_cols <> 0 THEN
    RAISE EXCEPTION 'ev_api must not have SELECT on sealed_% columns (found %)', v_select_cols;
  END IF;
END $$;

COMMIT;
```

- [ ] **Step 3: Dry-run against prod**

Wrap the body `BEGIN; … ROLLBACK;` (swap the `COMMIT`), run it against prod, confirm the post-verify gate does not raise and the schema is gone after `ROLLBACK`. Then restore `COMMIT`.

- [ ] **Step 4: Reservation + duplicate checks**

```bash
git fetch origin
npm run check:migrations --prefix backend
npm run check:reservations --prefix backend
```
Expected: both green.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(id-vault): CA_0116 id_vault schema, write-only grants, default-deny RLS" -- \
  backend/migrations/CA_0116_id_vault_schema.sql
```

---

## Task 3: Crypto primitives (`idVaultCrypto.ts`)

**Files:**
- Create: `backend/src/lib/idVaultCrypto.ts`
- Test: `backend/src/lib/idVaultCrypto.test.ts`

**Interfaces:**
- Produces:
  - `sealTo(publicKey: Uint8Array, message: string): Buffer`
  - `openSealed(publicKey: Uint8Array, secretKey: Uint8Array, sealed: Uint8Array): string`
  - `generateKeypair(): Promise<{ publicKeyB64: string; secretKeyHex: string; publicKey: Uint8Array; secretKey: Uint8Array }>`
  - `publicKeyFromB64(b64: string): Uint8Array`
  - `sodiumReady(): Promise<void>`

- [ ] **Step 1: Write the failing test**

`backend/src/lib/idVaultCrypto.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { generateKeypair, sealTo, openSealed, publicKeyFromB64 } from './idVaultCrypto.js';

describe('idVaultCrypto — seal/open round-trip', () => {
  it('seals with only the public key and opens only with the secret key', async () => {
    const kp = await generateKeypair();
    const sealed = sealTo(publicKeyFromB64(kp.publicKeyB64), 'Ada Lovelace');
    expect(Buffer.isBuffer(sealed)).toBe(true);
    const opened = openSealed(kp.publicKey, kp.secretKey, sealed);
    expect(opened).toBe('Ada Lovelace');
  });

  it('cannot open with the wrong secret key', async () => {
    const a = await generateKeypair();
    const b = await generateKeypair();
    const sealed = sealTo(a.publicKey, '123 Main St');
    expect(() => openSealed(a.publicKey, b.secretKey, sealed)).toThrow();
  });
});
```

- [ ] **Step 2: Run it**

Run: `npm --prefix backend test -- src/lib/idVaultCrypto.test.ts`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement**

`backend/src/lib/idVaultCrypto.ts`:

```ts
/**
 * idVaultCrypto — pure sealing/keysplit primitives for the identity vault.
 * No env, no DB. The APP imports only sealTo/publicKeyFromB64 (public key only).
 * openSealed/split/combine are used by the OFFLINE CLIs and tests; they are
 * inert without a secret key, which never enters app config, env, or the DB.
 */
import _sodium from 'libsodium-wrappers';

let ready: Promise<void> | null = null;
export function sodiumReady(): Promise<void> {
  if (!ready) ready = _sodium.ready;
  return ready;
}

/** Seal a UTF-8 message to a recipient public key. Anyone with the public key can do this. */
export function sealTo(publicKey: Uint8Array, message: string): Buffer {
  const cipher = _sodium.crypto_box_seal(_sodium.from_string(message), publicKey);
  return Buffer.from(cipher);
}

/** Open a sealed box. Requires the secret key — throws on the wrong key or tampering. */
export function openSealed(publicKey: Uint8Array, secretKey: Uint8Array, sealed: Uint8Array): string {
  const plain = _sodium.crypto_box_seal_open(new Uint8Array(sealed), publicKey, secretKey);
  return _sodium.to_string(plain);
}

export async function generateKeypair(): Promise<{
  publicKeyB64: string; secretKeyHex: string; publicKey: Uint8Array; secretKey: Uint8Array;
}> {
  await sodiumReady();
  const kp = _sodium.crypto_box_keypair();
  return {
    publicKey: kp.publicKey,
    secretKey: kp.privateKey,
    publicKeyB64: _sodium.to_base64(kp.publicKey, _sodium.base64_variants.ORIGINAL),
    secretKeyHex: Buffer.from(kp.privateKey).toString('hex'),
  };
}

export function publicKeyFromB64(b64: string): Uint8Array {
  return _sodium.from_base64(b64, _sodium.base64_variants.ORIGINAL);
}
```

> The test imports before `sodiumReady()`; call `await generateKeypair()` first in each test (it awaits readiness). `sealTo`/`openSealed` assume sodium is ready — always reached via a prior `generateKeypair()` or an explicit `await sodiumReady()`.

- [ ] **Step 4: Run it**

Run: `npm --prefix backend test -- src/lib/idVaultCrypto.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(id-vault): libsodium seal/open primitives" -- \
  backend/src/lib/idVaultCrypto.ts backend/src/lib/idVaultCrypto.test.ts
```

---

## Task 4: Shamir 2-of-4 split/combine

**Files:**
- Modify: `backend/src/lib/idVaultCrypto.ts`
- Test: `backend/src/lib/idVaultCrypto.test.ts`

**Interfaces:**
- Produces:
  - `splitSecretKey(secretKeyHex: string): string[]` — 4 shares, threshold 2.
  - `combineSecretKey(shares: string[]): string` — reconstructs the hex secret key.

- [ ] **Step 1: Add the failing tests**

Append to `backend/src/lib/idVaultCrypto.test.ts`:

```ts
import { splitSecretKey, combineSecretKey } from './idVaultCrypto.js';

describe('idVaultCrypto — 2-of-4 split', () => {
  it('any two of four shares reconstruct the key; the round-trip still opens', async () => {
    const kp = await generateKeypair();
    const shares = splitSecretKey(kp.secretKeyHex);
    expect(shares).toHaveLength(4);
    const sealed = sealTo(kp.publicKey, 'Grace Hopper');
    // pick shares 2 and 4
    const recoveredHex = combineSecretKey([shares[1], shares[3]]);
    const recovered = Uint8Array.from(Buffer.from(recoveredHex, 'hex'));
    expect(openSealed(kp.publicKey, recovered, sealed)).toBe('Grace Hopper');
  });

  it('a single share cannot reconstruct the key', async () => {
    const kp = await generateKeypair();
    const shares = splitSecretKey(kp.secretKeyHex);
    const wrong = combineSecretKey([shares[0]]); // below threshold -> garbage, not the key
    expect(wrong).not.toBe(kp.secretKeyHex);
  });
});
```

- [ ] **Step 2: Run — expect FAIL** (`splitSecretKey` undefined).

- [ ] **Step 3: Implement** — add the import at the TOP of `idVaultCrypto.ts` (with the other imports), and append the functions below

```ts
// top of file, alongside `import _sodium from 'libsodium-wrappers';`
import secrets from 'secrets.js-grempe';
```

```ts
// appended below the Task 3 exports:
const SHARES = 4;
const THRESHOLD = 2;

/** Split the 32-byte (64 hex char) secret key into 4 shares; any 2 reconstruct it. */
export function splitSecretKey(secretKeyHex: string): string[] {
  return secrets.share(secretKeyHex, SHARES, THRESHOLD);
}

/** Reconstruct the secret key hex from >= 2 shares. Fewer than 2 yields non-key output. */
export function combineSecretKey(shares: string[]): string {
  return secrets.combine(shares);
}
```

- [ ] **Step 4: Run — expect PASS.**

Run: `npm --prefix backend test -- src/lib/idVaultCrypto.test.ts`

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(id-vault): Shamir 2-of-4 split/combine over the private key" -- \
  backend/src/lib/idVaultCrypto.ts backend/src/lib/idVaultCrypto.test.ts
```

---

## Task 5: App seal library (`idVault.ts`)

**Files:**
- Create: `backend/src/lib/idVault.ts`
- Test: `backend/src/lib/idVault.test.ts`

**Interfaces:**
- Consumes: `sealTo`, `publicKeyFromB64`, `sodiumReady` (Task 3); `env` (Task 1); `pool` (`./db.js`).
- Produces:
  - `isVaultEnabled(): boolean`
  - `sealName(name: string): Promise<Buffer>`
  - `sealAddress(raw: string): Promise<Buffer>`
  - `upsertSeal(userId: string, parts: { name?: string; address?: string }): Promise<void>`

- [ ] **Step 1: Write the failing test**

`backend/src/lib/idVault.test.ts`:

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

const poolQueryMock = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({ pool: { query: poolQueryMock } }));

describe('idVault — gating', () => {
  beforeEach(() => { poolQueryMock.mockReset(); });

  it('isVaultEnabled reflects presence of a public key + version', async () => {
    vi.resetModules();
    vi.doMock('./env.js', () => ({ env: { ID_VAULT_PUBLIC_KEY: undefined, ID_VAULT_KEY_VERSION: undefined } }));
    const off = await import('./idVault.js');
    expect(off.isVaultEnabled()).toBe(false);
  });

  it('the app module exports no decrypt/open function', async () => {
    const mod = await import('./idVault.js');
    expect(Object.keys(mod).some((k) => /open|decrypt|unseal/i.test(k))).toBe(false);
  });

  it('upsertSeal writes ciphertext via ON CONFLICT and never SELECTs sealed_*', async () => {
    vi.resetModules();
    const { generateKeypair } = await import('./idVaultCrypto.js');
    const kp = await generateKeypair();
    vi.doMock('./env.js', () => ({ env: { ID_VAULT_PUBLIC_KEY: kp.publicKeyB64, ID_VAULT_KEY_VERSION: 1 } }));
    poolQueryMock.mockResolvedValue({ rows: [], rowCount: 1 });
    const { upsertSeal, isVaultEnabled } = await import('./idVault.js');
    expect(isVaultEnabled()).toBe(true);
    await upsertSeal('11111111-1111-1111-1111-111111111111', { name: 'Ada' });
    const [sql, params] = poolQueryMock.mock.calls[0];
    expect(sql).toMatch(/id_vault\.seal_upsert/);   // writes via the SECURITY DEFINER function
    expect(Buffer.isBuffer(params[1])).toBe(true);  // sealed_name is a Buffer
    expect(params[2]).toBeNull();                    // address not provided -> null (function COALESCEs)
    expect(params[3]).toBe(1);                       // key_version
  });
});
```

- [ ] **Step 2: Run — expect FAIL** (module not found).

- [ ] **Step 3: Implement**

`backend/src/lib/idVault.ts`:

```ts
/**
 * idVault — app-facing sealing. Holds ONLY the public key (env). Can seal
 * (write) any time; can NEVER open (no secret key, no open function here).
 * Gated: when no public key is configured the caller keeps today's behaviour.
 */
import { env } from './env.js';
import { pool } from './db.js';
import { sealTo, publicKeyFromB64, sodiumReady } from './idVaultCrypto.js';

export function isVaultEnabled(): boolean {
  return Boolean(env.ID_VAULT_PUBLIC_KEY && env.ID_VAULT_KEY_VERSION);
}

function requirePublicKey(): Uint8Array {
  if (!env.ID_VAULT_PUBLIC_KEY) throw new Error('ID_VAULT_PUBLIC_KEY not configured');
  return publicKeyFromB64(env.ID_VAULT_PUBLIC_KEY);
}

export async function sealName(name: string): Promise<Buffer> {
  await sodiumReady();
  return sealTo(requirePublicKey(), name);
}

export async function sealAddress(raw: string): Promise<Buffer> {
  await sodiumReady();
  return sealTo(requirePublicKey(), raw);
}

/**
 * Seal the given parts for this user via the SECURITY DEFINER function
 * id_vault.seal_upsert. ev_api holds EXECUTE on that function and NO direct table
 * privilege, so it can seal but cannot read the ciphertext. A null part leaves the
 * other column untouched (the function COALESCEs). Idempotent. See CA_0118 + spec §4.1.
 */
export async function upsertSeal(
  userId: string,
  parts: { name?: string; address?: string }
): Promise<void> {
  const sealedName = parts.name !== undefined ? await sealName(parts.name) : null;
  const sealedAddress = parts.address !== undefined ? await sealAddress(parts.address) : null;
  await pool.query(
    `SELECT id_vault.seal_upsert($1, $2, $3, $4)`,
    [userId, sealedName, sealedAddress, env.ID_VAULT_KEY_VERSION]
  );
}
```

- [ ] **Step 4: Run — expect PASS.**

Run: `npm --prefix backend test -- src/lib/idVault.test.ts`

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(id-vault): app seal library (public-key-only, no decrypt)" -- \
  backend/src/lib/idVault.ts backend/src/lib/idVault.test.ts
```

---

## Task 6: Key-generation / split CLI

**Files:**
- Create: `backend/scripts/id-vault-keygen.mts`
- Test: `backend/scripts/id-vault-keygen.test.ts`

**Interfaces:**
- Consumes: `generateKeypair`, `splitSecretKey`, `combineSecretKey`, `sealTo`, `openSealed`, `publicKeyFromB64` (Task 3/4).
- Produces: `runKeygen(outDir: string): Promise<{ publicKeyB64: string; keyVersion: number; shareFiles: string[] }>` — writes 4 share files, returns the public key. Never writes the whole secret key to disk.

- [ ] **Step 1: Write the failing test**

`backend/scripts/id-vault-keygen.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { runKeygen } from './id-vault-keygen.mjs';
import { combineSecretKey, sealTo, openSealed, publicKeyFromB64 } from '../src/lib/idVaultCrypto.js';

describe('id-vault-keygen', () => {
  it('writes 4 shares whose any-two reconstruct a key that opens a seal', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'idvault-'));
    const { publicKeyB64, shareFiles } = await runKeygen(dir);
    expect(shareFiles).toHaveLength(4);
    const s2 = readFileSync(shareFiles[1], 'utf8').trim();
    const s3 = readFileSync(shareFiles[2], 'utf8').trim();
    const skHex = combineSecretKey([s2, s3]);
    const sk = Uint8Array.from(Buffer.from(skHex, 'hex'));
    const sealed = sealTo(publicKeyFromB64(publicKeyB64), 'ceremony test');
    expect(openSealed(publicKeyFromB64(publicKeyB64), sk, sealed)).toBe('ceremony test');
  });
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement**

`backend/scripts/id-vault-keygen.mts`:

```ts
#!/usr/bin/env tsx
/**
 * id-vault-keygen — OFFLINE ceremony tool. Generates the vault keypair, prints
 * the PUBLIC key (safe to hold) + version, and splits the private key 2-of-4
 * into four share files for offline distribution. It does NOT persist the whole
 * private key. Run on an offline machine; destroy the reassembled key after.
 *
 * Usage: tsx scripts/id-vault-keygen.mts <out-dir> [--key-version N]
 */
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { generateKeypair, splitSecretKey } from '../src/lib/idVaultCrypto.js';

export async function runKeygen(
  outDir: string,
  keyVersion = 1
): Promise<{ publicKeyB64: string; keyVersion: number; shareFiles: string[] }> {
  const kp = await generateKeypair();
  const shares = splitSecretKey(kp.secretKeyHex);
  const shareFiles = shares.map((share, i) => {
    const f = join(outDir, `id-vault-share-${i + 1}-of-4.txt`);
    writeFileSync(f, `${share}\n`, { mode: 0o600 });
    return f;
  });
  return { publicKeyB64: kp.publicKeyB64, keyVersion, shareFiles };
}

// CLI entry (not run under vitest import)
if (import.meta.url === `file://${process.argv[1]}`) {
  const outDir = process.argv[2];
  if (!outDir) { console.error('usage: id-vault-keygen <out-dir> [--key-version N]'); process.exit(2); }
  const vIdx = process.argv.indexOf('--key-version');
  const keyVersion = vIdx > -1 ? Number(process.argv[vIdx + 1]) : 1;
  runKeygen(outDir, keyVersion).then(({ publicKeyB64, shareFiles }) => {
    console.log('\n=== id_vault key ceremony ===');
    console.log('Set in prod env (Phase B):');
    console.log(`  ID_VAULT_PUBLIC_KEY=${publicKeyB64}`);
    console.log(`  ID_VAULT_KEY_VERSION=${keyVersion}`);
    console.log('\nDistribute ONE share file to EACH board member, offline:');
    shareFiles.forEach((f) => console.log(`  ${f}`));
    console.log('\nThen DELETE the share files from this machine and destroy the reassembled key.\n');
  });
}
```

- [ ] **Step 4: Run — expect PASS.**

Run: `npm --prefix backend test -- scripts/id-vault-keygen.test.ts`

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(id-vault): offline keygen + 2-of-4 split CLI" -- \
  backend/scripts/id-vault-keygen.mts backend/scripts/id-vault-keygen.test.ts
```

---

## Task 7: Seal on signup (gated)

**Files:**
- Modify: `backend/src/routes/auth.ts` (~314–355)
- Test: `backend/src/routes/auth.idVault.test.ts` (create)

**Interfaces:**
- Consumes: `isVaultEnabled`, `upsertSeal` (Task 5).

- [ ] **Step 1: Write the failing test**

`backend/src/routes/auth.idVault.test.ts`:

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

const isEnabled = vi.hoisted(() => vi.fn());
const upsertSeal = vi.hoisted(() => vi.fn());
vi.mock('../lib/idVault.js', () => ({ isVaultEnabled: isEnabled, upsertSeal }));

// A tiny extracted helper keeps this unit-testable without booting Express.
import { resolveSignupLegalName } from './auth.js';

describe('signup name routing', () => {
  beforeEach(() => { isEnabled.mockReset(); upsertSeal.mockReset(); });

  it('vault ON: seals the name and passes NULL to the RPC', async () => {
    isEnabled.mockReturnValue(true);
    const rpcName = await resolveSignupLegalName('user-1', 'Ada Lovelace');
    expect(upsertSeal).toHaveBeenCalledWith('user-1', { name: 'Ada Lovelace' });
    expect(rpcName).toBeNull();
  });

  it('vault OFF: passes the real name to the RPC and seals nothing', async () => {
    isEnabled.mockReturnValue(false);
    const rpcName = await resolveSignupLegalName('user-1', 'Ada Lovelace');
    expect(upsertSeal).not.toHaveBeenCalled();
    expect(rpcName).toBe('Ada Lovelace');
  });
});
```

- [ ] **Step 2: Run — expect FAIL** (`resolveSignupLegalName` not exported).

- [ ] **Step 3: Implement**

In `backend/src/routes/auth.ts`, add the import and an exported helper near the top:

```ts
import { isVaultEnabled, upsertSeal } from '../lib/idVault.js';

/**
 * Seal-first name routing for Connected signup. When the vault is enabled we
 * seal the real name and hand the RPC NULL (legal_name is nullable); otherwise
 * we keep today's behaviour and pass the name through to the profile row.
 * Returns the value to pass as p_legal_name.
 */
export async function resolveSignupLegalName(userId: string, legalName: string): Promise<string | null> {
  if (isVaultEnabled()) {
    await upsertSeal(userId, { name: legalName }); // seal FIRST, before the RPC
    return null;
  }
  return legalName;
}
```

Then in the `if (invite_code && legal_name)` block (~314), replace the RPC's `p_legal_name`:

```ts
      const rpcLegalName = await resolveSignupLegalName(userId, legal_name);
      const { data: rpcResult, error: rpcError } = await adminRpc(
        'signup_with_invite',
        {
          p_user_id: userId,
          p_legal_name: rpcLegalName,
          p_invite_code: invite_code,
          p_display_name: display_name,
        },
        'connect'
      );
```

- [ ] **Step 4: Run — expect PASS.**

Run: `npm --prefix backend test -- src/routes/auth.idVault.test.ts`

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(id-vault): gated seal-on-signup, NULL to the RPC when enabled" -- \
  backend/src/routes/auth.ts backend/src/routes/auth.idVault.test.ts
```

---

## Task 8: Seal on address change (gated)

**Files:**
- Modify: `backend/src/routes/connect.ts` (`/set-location`, after a successful `upsert_user_location`, ~596)
- Test: `backend/src/routes/connect.idVault.test.ts` (create)

**Interfaces:**
- Consumes: `isVaultEnabled`, `upsertSeal` (Task 5).

- [ ] **Step 1: Write the failing test**

`backend/src/routes/connect.idVault.test.ts`:

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

const isEnabled = vi.hoisted(() => vi.fn());
const upsertSeal = vi.hoisted(() => vi.fn());
vi.mock('../lib/idVault.js', () => ({ isVaultEnabled: isEnabled, upsertSeal }));

import { sealAddressIfEnabled } from './connect.js';

describe('set-location address sealing', () => {
  beforeEach(() => { isEnabled.mockReset(); upsertSeal.mockReset(); });

  it('vault ON: seals the raw address', async () => {
    isEnabled.mockReturnValue(true);
    await sealAddressIfEnabled('user-1', '742 Evergreen Terrace');
    expect(upsertSeal).toHaveBeenCalledWith('user-1', { address: '742 Evergreen Terrace' });
  });

  it('vault OFF: seals nothing', async () => {
    isEnabled.mockReturnValue(false);
    await sealAddressIfEnabled('user-1', '742 Evergreen Terrace');
    expect(upsertSeal).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement**

In `backend/src/routes/connect.ts`, add near the top:

```ts
import { isVaultEnabled, upsertSeal } from '../lib/idVault.js';

/** Seal the raw street address into the vault when enabled. Coords stay under
 *  the existing single key (spec D5); this only adds the sealed raw address. */
export async function sealAddressIfEnabled(userId: string, rawAddress: string): Promise<void> {
  if (isVaultEnabled()) {
    await upsertSeal(userId, { address: rawAddress });
  }
}
```

In the `/set-location` handler, right after the `upsert_user_location` RPC succeeds (before/around district resolution, ~600), add:

```ts
    // Seal the raw address (public key only — no ceremony). Non-fatal: a seal
    // failure must not block district resolution the site needs to place them.
    try {
      await sealAddressIfEnabled(userId, address);
    } catch (sealErr) {
      console.error('[connect/set-location] id_vault seal failed (non-fatal):', sealErr);
    }
```

(`address` is the geocoded input already in scope; `userId` from `requireAuth`.)

- [ ] **Step 4: Run — expect PASS.**

Run: `npm --prefix backend test -- src/routes/connect.idVault.test.ts`

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(id-vault): gated seal-on-address in set-location" -- \
  backend/src/routes/connect.ts backend/src/routes/connect.idVault.test.ts
```

---

## Task 9: Promotion confirm-name (backend)

**Files:**
- Modify: `backend/src/lib/empowerService.ts` (`runPreflight`, `confirmEmpowerment`)
- Modify: `backend/src/routes/empower.ts` (`ConfirmSchema`, `/preflight`, `/confirm`)
- Test: `backend/src/lib/empowerService.confirmName.test.ts` (create)

**Interfaces:**
- `runPreflight(userId: string, confirmedLegalName?: string)` — uses the confirmed name for the slug when given, else the DB value.
- `confirmEmpowerment(userId: string, consentedItems: string[], confirmedLegalName?: string)` — passes the confirmed name to `execute_empowerment`, else the DB value.

- [ ] **Step 1: Write the failing test**

`backend/src/lib/empowerService.confirmName.test.ts`:

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

const rpc = vi.hoisted(() => vi.fn());
const from = vi.hoisted(() => vi.fn());
vi.mock('./supabase.js', () => ({
  adminRpc: rpc,
  supabaseAdmin: { schema: () => ({ from, rpc }) },
}));
const cacheGet = vi.hoisted(() => vi.fn());
const cacheSet = vi.hoisted(() => vi.fn());
const cacheDel = vi.hoisted(() => vi.fn());
vi.mock('./cache.js', () => ({ cache: { get: cacheGet, set: cacheSet, del: cacheDel } }));
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('./compassService.js', () => ({ getCompassCompleteness: vi.fn() }));

import { confirmEmpowerment } from './empowerService.js';

describe('confirmEmpowerment — confirmed name', () => {
  beforeEach(() => { rpc.mockReset(); from.mockReset(); cacheGet.mockReset(); });

  it('prefers the confirmed name over the (null) DB value for execute_empowerment', async () => {
    cacheGet.mockResolvedValue('ada-lovelace-a3b4');
    // supabaseAdmin.schema('connect').from('connected_profiles')… returns null legal_name
    from.mockReturnValue({
      select: () => ({ eq: () => ({ single: () => Promise.resolve({ data: { id: 'cp-1', legal_name: null }, error: null }) }) }),
    });
    rpc.mockResolvedValue({ data: { id: 'ep-1' }, error: null });

    await confirmEmpowerment('user-1', ['legal_name_public'], 'Ada Lovelace');

    const call = rpc.mock.calls.find((c) => c[0] === 'execute_empowerment');
    expect(call?.[1].p_legal_name).toBe('Ada Lovelace');
  });
});
```

> Adjust the `from`/`rpc` mock shape to match the exact supabase-js chain in `confirmEmpowerment` (it calls `supabaseAdmin.schema('empower').rpc('execute_empowerment', …)` and `supabaseAdmin.schema('connect').from('connected_profiles').select(...).eq(...).single()`). Keep the assertion: `p_legal_name === 'Ada Lovelace'`.

- [ ] **Step 2: Run — expect FAIL** (arg not accepted / DB value used).

- [ ] **Step 3: Implement**

In `empowerService.ts`, change `confirmEmpowerment`'s signature and the RPC arg:

```ts
export async function confirmEmpowerment(
  userId: string,
  consentedItems: string[],
  confirmedLegalName?: string
): Promise<{ empowered_profile: Record<string, unknown> }> {
```

and (at the `execute_empowerment` call, ~292):

```ts
      p_legal_name: confirmedLegalName ?? connectedProfile.legal_name ?? '',
```

In `runPreflight`, accept the optional name and prefer it for the slug + summary:

```ts
export async function runPreflight(userId: string, confirmedLegalName?: string): Promise<PreflightResult> {
```
and where the fresh slug is generated (~196) and the summary built (~203):

```ts
    const nameForSlug = confirmedLegalName ?? connected.legal_name ?? '';
    slugPreview = await reserveSlug(userId, nameForSlug);
```
```ts
      legal_name: confirmedLegalName ?? connected.legal_name ?? '',
```

In `routes/empower.ts`, extend `ConfirmSchema` with an optional name and thread it:

```ts
// in ConfirmSchema (z.object): add
  legal_name: z.string().min(1).max(200).optional(),
```
```ts
// /confirm handler:
      const result = await confirmEmpowerment(
        authReq.userId,
        ['legal_name_public', 'compass_stances_public', 'platform_terms'],
        parsed.data.legal_name
      );
```

For `/preflight`, accept an optional body name and pass it — **treat empty/whitespace as absent** (an
unfilled form field must fall back to the DB name, not defeat the `??` chain and produce a bad slug):

```ts
      const rawName = req.body?.legal_name;
      const confirmedName = typeof rawName === 'string' && rawName.trim().length > 0 ? rawName : undefined;
      const result = await runPreflight(authReq.userId, confirmedName);
```

Defense-in-depth: `runPreflight`/`confirmEmpowerment` also normalize a blank `confirmedLegalName` to
absent internally (e.g. `const confirmed = confirmedLegalName?.trim() ? confirmedLegalName : undefined;`
then `confirmed ?? connected.legal_name ?? ''`), so no caller can slip an empty string past the fallback.

- [ ] **Step 4: Run — expect PASS.**

Run: `npm --prefix backend test -- src/lib/empowerService.confirmName.test.ts`

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(id-vault): promotion accepts a confirmed name, falls back to DB" -- \
  backend/src/lib/empowerService.ts backend/src/routes/empower.ts \
  backend/src/lib/empowerService.confirmName.test.ts
```

> **Phase-C prerequisite (out of scope here):** the promotion UI (in `admin/`, not `app/src`) must send `legal_name` to `/preflight` and `/confirm` before the column is nulled. Track it before Phase C.

---

## Task 10: Drop the name from the admin view

**Files:**
- Modify: `backend/src/lib/adminService.ts` (`getAccountDetail`, ~113–139)
- Modify: `backend/src/routes/admin.ts` (~291)
- Test: `backend/src/lib/adminService.legalName.test.ts` (create)

- [ ] **Step 1: Write the failing test**

`backend/src/lib/adminService.legalName.test.ts`:

```ts
import { describe, it, expect, vi } from 'vitest';

const rpc = vi.hoisted(() => vi.fn());
vi.mock('./supabase.js', () => ({ adminRpc: rpc, supabaseAdmin: {} }));
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));

import { getAccountDetail } from './adminService.js';

describe('getAccountDetail — name stays vaulted', () => {
  it('strips legal_name from the nested connected_profile', async () => {
    // admin_get_account_detail nests the Connect legal_name under `connected_profile`
    // (row_to_json of connect.connected_profiles). The public empowered_profile name stays.
    rpc.mockImplementation((fn: string) =>
      fn === 'admin_get_account_detail'
        ? Promise.resolve({ data: {
            user_id: 'u1',
            connected_profile: { legal_name: 'Ada Lovelace', tolerance_rating: 3 },
            empowered_profile: { legal_name: 'Ada Lovelace' }, // public — must remain
          }, error: null })
        : Promise.resolve({ data: [], error: null })
    );
    const detail = await getAccountDetail('u1') as Record<string, any>;
    expect('legal_name' in (detail.connected_profile ?? {})).toBe(false); // vaulted name gone
    expect(detail.connected_profile.tolerance_rating).toBe(3);            // other fields kept
    expect(detail.empowered_profile.legal_name).toBe('Ada Lovelace');     // public name kept
  });
});
```

- [ ] **Step 2: Run — expect FAIL** (nested legal_name still present).

- [ ] **Step 3: Implement**

In `getAccountDetail`, before `return result;` — strip the name from the NESTED `connected_profile`
(a top-level `delete result.legal_name` is a no-op; the RPC returns the name at
`result.connected_profile.legal_name`). Leave `empowered_profile.legal_name` — that name is public.

```ts
  // The real Connect name is vaulted (ev-cto 0022). No admin read path exposes it —
  // only the offline two-person break-glass. The RPC nests it under connected_profile
  // (row_to_json of connect.connected_profiles), so strip it there.
  const cp = (result as Record<string, unknown>).connected_profile;
  if (cp && typeof cp === 'object') {
    delete (cp as Record<string, unknown>).legal_name;
  }
```

In `routes/admin.ts` (~291), drop `'legal_name'` from `viewed_fields`:

```ts
      viewed_fields: ['tolerance_rating', 'roles', 'audit_log'],
```

- [ ] **Step 4: Run — expect PASS.**

Run: `npm --prefix backend test -- src/lib/adminService.legalName.test.ts`

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(id-vault): remove legal_name from admin account detail + audit log" -- \
  backend/src/lib/adminService.ts backend/src/routes/admin.ts \
  backend/src/lib/adminService.legalName.test.ts
```

---

## Task 11: Backfill script (written, not run)

**Files:**
- Create: `backend/scripts/id-vault-backfill.mts`
- Test: `backend/scripts/id-vault-backfill.test.ts`

**Interfaces:**
- Produces: `backfillSeal(rows: {user_id: string; legal_name: string|null}[], seal: (u: string, name: string)=>Promise<void>, opts: {dryRun: boolean}): Promise<{ sealed: number; skipped: number }>` — pure over an injected sealer, so it is testable without a DB.

- [ ] **Step 1: Write the failing test**

`backend/scripts/id-vault-backfill.test.ts`:

```ts
import { describe, it, expect, vi } from 'vitest';
import { backfillSeal } from './id-vault-backfill.mjs';

describe('id-vault-backfill', () => {
  it('seals rows with a non-null name; skips null names', async () => {
    const seal = vi.fn().mockResolvedValue(undefined);
    const res = await backfillSeal(
      [{ user_id: 'a', legal_name: 'Ada' }, { user_id: 'b', legal_name: null }],
      seal, { dryRun: false }
    );
    expect(seal).toHaveBeenCalledTimes(1);
    expect(seal).toHaveBeenCalledWith('a', 'Ada');
    expect(res).toEqual({ sealed: 1, skipped: 1 });
  });

  it('dry-run seals nothing', async () => {
    const seal = vi.fn();
    const res = await backfillSeal([{ user_id: 'a', legal_name: 'Ada' }], seal, { dryRun: true });
    expect(seal).not.toHaveBeenCalled();
    expect(res).toEqual({ sealed: 0, skipped: 0 });
  });
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement**

`backend/scripts/id-vault-backfill.mts`:

```ts
#!/usr/bin/env tsx
/**
 * id-vault-backfill — Phase C, run ONCE on prod AFTER the ceremony sets the
 * production ID_VAULT_PUBLIC_KEY. Seals every existing connected_profiles
 * legal_name into id_vault. Idempotent (upsertSeal). --dry-run is the default;
 * pass --apply to write.
 */
import { pool } from '../src/lib/db.js';
import { upsertSeal, isVaultEnabled } from '../src/lib/idVault.js';

export async function backfillSeal(
  rows: { user_id: string; legal_name: string | null }[],
  seal: (userId: string, name: string) => Promise<void>,
  opts: { dryRun: boolean }
): Promise<{ sealed: number; skipped: number }> {
  let sealed = 0, skipped = 0;
  for (const r of rows) {
    if (!r.legal_name) { skipped++; continue; }
    if (opts.dryRun) continue;
    await seal(r.user_id, r.legal_name);
    sealed++;
  }
  return { sealed, skipped };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const dryRun = !process.argv.includes('--apply');
  (async () => {
    if (!isVaultEnabled()) { console.error('ID_VAULT_PUBLIC_KEY not set — run the ceremony first.'); process.exit(2); }
    const { rows } = await pool.query<{ user_id: string; legal_name: string | null }>(
      `SELECT user_id, legal_name FROM connect.connected_profiles WHERE legal_name IS NOT NULL`
    );
    const res = await backfillSeal(rows, (u, name) => upsertSeal(u, { name }), { dryRun });
    console.log(`[backfill] ${dryRun ? 'DRY-RUN' : 'APPLIED'} rows=${rows.length} sealed=${res.sealed} skipped=${res.skipped}`);
    await pool.end();
  })();
}
```

- [ ] **Step 4: Run — expect PASS.**

Run: `npm --prefix backend test -- scripts/id-vault-backfill.test.ts`

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(id-vault): backfill script (idempotent, dry-run default, unrun)" -- \
  backend/scripts/id-vault-backfill.mts backend/scripts/id-vault-backfill.test.ts
```

---

## Task 12: Null-column migration (written, unapplied)

**Files:**
- Create: `backend/migrations/CA_<null>_null_connected_legal_name.sql`

- [ ] **Step 1: Reserve the slot**

```bash
npm run steward --prefix backend -- slot CA --purpose "null connect.connected_profiles.legal_name after id_vault backfill"
# -> e.g. CA_0117 ; name the file that number immediately
```

- [ ] **Step 2: Write the migration** (`CA_0117_null_connected_legal_name.sql`)

```sql
-- CA_0117 — Null connect.connected_profiles.legal_name after the id_vault backfill.
-- APPLY ONLY IN PHASE C: after the ceremony (Phase B) AND a verified backfill.
-- Guard: refuse to null unless every non-null name is already sealed in the vault.
BEGIN;

DO $$
DECLARE
  v_unsealed int;
BEGIN
  SELECT count(*) INTO v_unsealed
    FROM connect.connected_profiles cp
    WHERE cp.legal_name IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM id_vault.sealed_identities v
        WHERE v.user_id = cp.user_id AND v.sealed_name IS NOT NULL
      );
  IF v_unsealed <> 0 THEN
    RAISE EXCEPTION 'Refusing to null: % profiles have a name not yet sealed in id_vault', v_unsealed;
  END IF;
END $$;

UPDATE connect.connected_profiles
   SET legal_name = NULL
 WHERE legal_name IS NOT NULL;

-- Post-verify gate: zero non-null names remain.
DO $$
DECLARE v_remaining int;
BEGIN
  SELECT count(*) INTO v_remaining FROM connect.connected_profiles WHERE legal_name IS NOT NULL;
  IF v_remaining <> 0 THEN
    RAISE EXCEPTION 'legal_name null-out incomplete: % remain', v_remaining;
  END IF;
END $$;

COMMIT;
```

- [ ] **Step 3: Reservation + duplicate checks**

```bash
git fetch origin
npm run check:migrations --prefix backend
npm run check:reservations --prefix backend
```
Expected: green. (Do NOT apply this migration now — Phase C only.)

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(id-vault): CA_0117 null legal_name after backfill (Phase C, guarded, unapplied)" -- \
  backend/migrations/CA_0117_null_connected_legal_name.sql
```

---

## Task 13: Break-glass CLI + README

**Files:**
- Create: `backend/scripts/id-vault-break-glass.mts`
- Create: `backend/scripts/README-id-vault.md`
- Test: `backend/scripts/id-vault-break-glass.test.ts`

**Interfaces:**
- Consumes: `combineSecretKey`, `openSealed`, `publicKeyFromB64` (Task 3/4).
- Produces:
  - `breakGlass(input: { shares: string[]; publicKeyB64: string; sealedName: Buffer|null; sealedAddress: Buffer|null; reason: string; members: string[] }): { name: string|null; address: string|null }` — throws if `shares.length < 2` or `!reason`.
  - `appendAuditLine(logPath: string, entry: {members: string[]; user_id: string; reason: string; at: string}): void`

- [ ] **Step 1: Write the failing test**

`backend/scripts/id-vault-break-glass.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { breakGlass, appendAuditLine } from './id-vault-break-glass.mjs';
import { generateKeypair, splitSecretKey, sealTo } from '../src/lib/idVaultCrypto.js';

async function fixture() {
  const kp = await generateKeypair();
  const shares = splitSecretKey(kp.secretKeyHex);
  const sealedName = sealTo(kp.publicKey, 'Ada Lovelace');
  const sealedAddress = sealTo(kp.publicKey, '742 Evergreen Terrace');
  return { kp, shares, sealedName, sealedAddress };
}

describe('breakGlass', () => {
  it('two shares + reason decrypt one user', async () => {
    const f = await fixture();
    const out = breakGlass({
      shares: [f.shares[0], f.shares[2]], publicKeyB64: f.kp.publicKeyB64,
      sealedName: f.sealedName, sealedAddress: f.sealedAddress,
      reason: 'court order 2026-11', members: ['alice', 'bob'],
    });
    expect(out).toEqual({ name: 'Ada Lovelace', address: '742 Evergreen Terrace' });
  });

  it('one share fails', async () => {
    const f = await fixture();
    expect(() => breakGlass({
      shares: [f.shares[0]], publicKeyB64: f.kp.publicKeyB64,
      sealedName: f.sealedName, sealedAddress: null, reason: 'x', members: ['a', 'b'],
    })).toThrow();
  });

  it('refuses without a reason', async () => {
    const f = await fixture();
    expect(() => breakGlass({
      shares: [f.shares[0], f.shares[1]], publicKeyB64: f.kp.publicKeyB64,
      sealedName: f.sealedName, sealedAddress: null, reason: '', members: ['a', 'b'],
    })).toThrow(/reason/i);
  });

  it('appends an audit line', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'bg-'));
    const log = join(dir, 'break-glass.log');
    appendAuditLine(log, { members: ['a', 'b'], user_id: 'u1', reason: 'r', at: '2026-09-17T00:00:00Z' });
    expect(readFileSync(log, 'utf8')).toMatch(/"user_id":"u1"/);
  });
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement**

`backend/scripts/id-vault-break-glass.mts`:

```ts
#!/usr/bin/env tsx
/**
 * id-vault-break-glass — OFFLINE two-person unmask. Never a route. Combines >=2
 * board-member shares, decrypts ONE user's sealed identity, and REQUIRES a
 * co-signed --reason, which it appends to an append-only audit log.
 *
 * Usage (offline machine):
 *   tsx scripts/id-vault-break-glass.mts \
 *     --pubkey <base64> --user <uuid> --reason "<case>" \
 *     --member alice --member bob \
 *     --share <file1> --share <file2> \
 *     --db "<privileged connection string>" --log ./break-glass.log
 */
import { appendFileSync, readFileSync } from 'node:fs';
import { combineSecretKey, openSealed, publicKeyFromB64, sodiumReady } from '../src/lib/idVaultCrypto.js';

export function breakGlass(input: {
  shares: string[]; publicKeyB64: string;
  sealedName: Buffer | null; sealedAddress: Buffer | null;
  reason: string; members: string[];
}): { name: string | null; address: string | null } {
  if (!input.reason || !input.reason.trim()) throw new Error('A --reason is required for a break-glass unmask.');
  if (input.shares.length < 2) throw new Error('At least two shares are required.');
  const skHex = combineSecretKey(input.shares);
  const sk = Uint8Array.from(Buffer.from(skHex, 'hex'));
  const pk = publicKeyFromB64(input.publicKeyB64);
  const name = input.sealedName ? openSealed(pk, sk, input.sealedName) : null;
  const address = input.sealedAddress ? openSealed(pk, sk, input.sealedAddress) : null;
  return { name, address };
}

export function appendAuditLine(
  logPath: string,
  entry: { members: string[]; user_id: string; reason: string; at: string }
): void {
  appendFileSync(logPath, JSON.stringify(entry) + '\n', { flag: 'a' });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const arg = (k: string) => { const i = process.argv.indexOf(k); return i > -1 ? process.argv[i + 1] : undefined; };
  const args = (k: string) => process.argv.reduce<string[]>((a, v, i) => (process.argv[i - 1] === k ? [...a, v] : a), []);
  const pubkey = arg('--pubkey'); const userId = arg('--user'); const reason = arg('--reason');
  const members = args('--member'); const shareFiles = args('--share'); const db = arg('--db');
  const log = arg('--log') ?? './break-glass.log';
  if (!pubkey || !userId || !reason || members.length < 2 || shareFiles.length < 2 || !db) {
    console.error('Missing required args (need --pubkey --user --reason, two --member, two --share, --db).');
    process.exit(2);
  }
  (async () => {
    await sodiumReady(); // openSealed/publicKeyFromB64 need libsodium ready
    const { Pool } = await import('pg');
    const pool = new Pool({ connectionString: db });
    const { rows } = await pool.query<{ sealed_name: Buffer | null; sealed_address: Buffer | null }>(
      `SELECT sealed_name, sealed_address FROM id_vault.sealed_identities WHERE user_id = $1`, [userId]
    );
    await pool.end();
    if (rows.length === 0) { console.error('No sealed identity for that user.'); process.exit(1); }
    const shares = shareFiles.map((f) => readFileSync(f, 'utf8').trim());
    const out = breakGlass({ shares, publicKeyB64: pubkey!, sealedName: rows[0].sealed_name, sealedAddress: rows[0].sealed_address, reason: reason!, members });
    appendAuditLine(log, { members, user_id: userId!, reason: reason!, at: new Date().toISOString() });
    console.log(JSON.stringify(out, null, 2));
    console.log(`\nLogged to ${log}. Destroy any reassembled key material now.`);
  })();
}
```

- [ ] **Step 4: Write the README**

`backend/scripts/README-id-vault.md` — cover: what the vault is (link the spec); the four scripts and when each runs; the **2-of-4, offline, two-people** rule; the Phase B ceremony (run `id-vault-keygen`, distribute one share per board member, set `ID_VAULT_PUBLIC_KEY`/`ID_VAULT_KEY_VERSION` in prod, destroy the reassembled key); the Phase C backfill→null order; the break-glass procedure and where the audit log lives; a periodic **drill**; and the rule to re-split when a board member changes.

- [ ] **Step 5: Run — expect PASS.**

Run: `npm --prefix backend test -- scripts/id-vault-break-glass.test.ts`

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(id-vault): offline break-glass CLI (2-of-4, --reason, audit log) + README" -- \
  backend/scripts/id-vault-break-glass.mts backend/scripts/id-vault-break-glass.test.ts \
  backend/scripts/README-id-vault.md
```

---

## Task 14: Full suite + grep gate + PR

**Files:** none (verification).

- [ ] **Step 1: Full backend test run**

Run: `npm --prefix backend test`
Expected: green, including every new `idVault*` / `id-vault-*` test.

- [ ] **Step 2: Typecheck / build**

Run: `npm --prefix backend run build`
Expected: no TS errors (confirms the `secrets.js-grempe` shim, `.mjs` import specifiers, and route edits typecheck).

- [ ] **Step 3: Confirm no NEW live read of `connected.legal_name`**

Run: `grep -rn "legal_name" backend/src | grep -iv "empowered_profiles\|legal_name_draft\|// \|/\*\|database.types"`
Expected: the only remaining `connected`-side reads are the promotion fallback (Task 9) and the seal routing (Task 7) — no admin read, no other consumer. (`empowered_profiles.legal_name` is the public name; leave it.)

- [ ] **Step 4: Migration integrity**

Run: `git fetch origin && npm run check:migrations --prefix backend && npm run check:reservations --prefix backend`
Expected: green.

- [ ] **Step 5: Open the PR** (per superpowers:finishing-a-development-branch)

```bash
git push -u origin feat/connect-identity-vault
```
PR body: link the spec; state that Phase A ships gated-off (no behaviour change until `ID_VAULT_PUBLIC_KEY` is set); list Phases B (ceremony) and C (backfill→null) as follow-ups; note the Phase-C frontend prerequisite (Task 9). End with the required `🤖 Generated with [Claude Code]` trailer.

---

## Self-review notes (spec coverage)

- Spec §4.1 vault store → Task 2. §4.2 key material/keygen → Task 6. §4.3 seal lib → Task 5 (crypto in Tasks 3–4). §4.4 seal-on-write → Tasks 7 (signup) + 8 (address). §4.5 promotion → Task 9. §4.6 admin drop → Task 10. §4.7 backfill+null → Tasks 11 + 12. §4.8 break-glass → Task 13.
- Acceptance checks (§7): (1) app-cannot-decrypt → Task 5 "no decrypt export" + Task 3 wrong-key test; (2) seal with public key alone → Tasks 3/5; (3) 2-of-4 / 1-share → Tasks 4/13; (4) column null + no live read → Tasks 12 + 14 §3; (5) districts resolve with sealed address → unchanged path + Task 8 leaves coords alone; (6) break-glass reason + log → Task 13.
- Phase boundaries: Tasks 1–10, 13 ship enabled-but-gated; Tasks 11–12 written, applied only in Phase C.
- Not in this plan (by design): the production key ceremony (Phase B, humans); the promotion frontend name field (Phase-C prerequisite); the uniqueness/nullifier (separate task).
