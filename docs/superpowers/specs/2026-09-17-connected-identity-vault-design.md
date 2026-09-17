# Design — The two-key identity vault for Connect

**Status:** Design, awaiting review (2026-09-17, Chris Andrews).
**Source decision:** `ev-cto/knowledge/decisions/0022-connected-identity-vault.md` (accepted 2026-09-17).
**Data model:** `docs/PRIVACY-DATA-MODEL.md` §5, §8a, §10.
**Founder shape:** `ev-cto/knowledge/PRIVACY-ARCHITECTURE.md` properties A/B/C + the 2026-09-15/16/17 clarifications.
**Repo:** ev-accounts (the CTO repo only advises).

---

## 1. Goal

A Connect member's real **name and raw street address** become readable only by **two of four board
members acting together, offline** — never by the running app, the database, or any single person.
The site keeps working normally: districts stay resolved under the username, so the member is placed
without re-entering anything.

This implements decision 0022 (Option 1: *write-anytime, read-needs-two-people*) and the escrowed
break-glass of `docs/PRIVACY-DATA-MODEL.md` §8a.

---

## 2. Decisions locked for this build

| # | Decision | Source |
|---|---|---|
| D1 | **Option 1** — envelope-seal on write; split the read key. | 0022 recommendation |
| D2 | **2-of-4 Shamir** over the private key, one share per board member, no backup. | 0022 §Founder choices |
| D3 | **Procedural isolation** (base design): break-glass reconstructs the private key offline and decrypts one named user. Cryptographic threshold decryption is a documented future option; it changes only the read mechanism and does not block this build. | 0022 §Founder choices (still open, base = procedural) |
| D4 | **Crypto stack:** `libsodium-wrappers` sealed boxes (`crypto_box_seal`) for the seal; `secrets.js-grempe` for the 2-of-4 split of the 32-byte X25519 secret key. | This session |
| D5 | **Location scope = name + raw address only.** Precise coordinates stay under the existing single `location_encryption_key` so districts can be re-derived on boundary changes. This narrows task step 5 ("raw address/coords into the vault") to just the raw address — a deliberate scope choice made this session to keep batch district re-derivation operational. | This session |
| D6 | **Posts stay public.** No second pseudonym, no post vault. | 0022 Context; data model §6c |
| D7 | **Offline break-glass CLI**, never a route; a `--reason` is required and appended to an append-only log. | 0022 recommendation §3 |

### Task inconsistency resolved

The task file's step 2 says "the three holders" and "start 2-of-3"; the accepted decision 0022 and its
goal both say **2-of-4 across four board members**. This build follows **2-of-4** (D2). The "three"
wording is a leftover from the earlier draft in data model §8a ("start 2-of-3, expandable"); 0022
supersedes it.

---

## 3. What is buildable now vs. the human ceremony

The private key and its shares must never touch anything the running app, this session, or the
database can reach. So the build splits cleanly:

**Buildable and testable this session (software), with a throwaway DEV keypair:**
- the `id_vault` schema, table, grants;
- the seal library (public-key-only writes);
- the seal-on-write wiring (gated — see §9);
- the promotion and admin-view changes;
- the key-generation / split tooling;
- the break-glass CLI + README;
- the backfill script and the null-column migration (written, **not applied**);
- all tests, run against the dev key.

**Not doable in software — a human, offline ceremony (Phase B, §9):**
- generating the **production** keypair;
- splitting the private key 2-of-4 and handing one share to each board member offline;
- destroying the reassembled private key.

Until that ceremony produces the production **public** key, the seal-on-write path stays gated off in
prod and the backfill/null steps cannot run. This is by design, not a gap.

---

## 4. Components

Each unit has one purpose, a defined interface, and is testable alone.

### 4.1 Vault store — `id_vault` schema

A new isolated schema `id_vault`, one table `sealed_identities`:

| Column | Type | Notes |
|---|---|---|
| `user_id` | `uuid` PK | FK → `public.users(id)` `ON DELETE CASCADE` (GDPR erasure removes the seal with the account). |
| `sealed_name` | `bytea` | `crypto_box_seal(name)`. Nullable (a seal may hold only an address, or vice-versa, during transitions). |
| `sealed_address` | `bytea` | `crypto_box_seal(raw street address)`. Nullable. |
| `key_version` | `smallint` NOT NULL | Which keypair sealed this row. Enables rotation. |
| `sealed_at` | `timestamptz` NOT NULL `DEFAULT now()` | Last seal write. |

**Access model — the app can write (seal) but never read (revised 2026-09-17 after probing prod).**
Two facts drove this to a SECURITY DEFINER function rather than table grants + RLS:
1. The API's runtime role **`ev_api` is `BYPASSRLS`** (migration 1386, the trusted-backend tier), so
   **RLS cannot constrain it** — GRANTS are its only control.
2. `INSERT … ON CONFLICT DO UPDATE` **requires SELECT** privilege (verified against prod). Granting
   `ev_api` SELECT to make an upsert work would also let it read ciphertext.

So the model is:
- `REVOKE ALL` on the schema and table from `PUBLIC`.
- `GRANT USAGE ON SCHEMA id_vault TO ev_api` — enough to call the function, nothing more.
- **`ev_api` gets NO privilege on the table** — no SELECT/INSERT/UPDATE/DELETE. It cannot read or
  even write the table directly (both verified denied against prod).
- The one write path is **`id_vault.seal_upsert(p_user_id, p_sealed_name, p_sealed_address,
  p_key_version)`**, a `SECURITY DEFINER` function owned by the (superuser) migration role,
  `SET search_path = ''`. It performs the partial upsert, preserving the column not being sealed via
  `COALESCE` — safe because the function runs as its owner (which may read), never as `ev_api`.
  `GRANT EXECUTE` to `ev_api`; `REVOKE` from `PUBLIC`.
- **RLS enabled** on the table as defense-in-depth against any *non-BYPASSRLS* role (e.g. a future
  PostgREST exposure) — deny-by-default, no policies. It is not `ev_api`'s control.
- The post-verify gate asserts: table exists; `ev_api` holds **zero** direct table privilege
  (table- and column-level); `ev_api` **can** EXECUTE `seal_upsert`.

Break-glass reads the ciphertext out-of-band (a privileged direct connection, not `ev_api`);
ciphertext is useless without the key. There is no `SECURITY DEFINER` **read** function — the definer
function only *writes*. This is the deliberate difference from the location model (§6 of the data
model), whose `SECURITY DEFINER` RPCs *decrypt* on demand with a DB-held key.

### 4.2 Key material + ceremony (offline)

- `crypto_box_keypair()` → X25519 keypair. The **public key** is safe to hold; it goes in app config
  as `ID_VAULT_PUBLIC_KEY` (base64) with a matching `ID_VAULT_KEY_VERSION`.
- The **private key** (32 bytes) is split: `secrets.share(hexSecretKey, 4, 2)` → four shares. One per
  board member, offline. `secrets.combine([any two])` reconstructs it.
- The reassembled private key is destroyed after splitting; it exists again only briefly, offline,
  during a break-glass.
- **Tooling (`backend/scripts/id-vault-keygen.mts`):** generates a keypair, prints the public key +
  version, splits the private key, and writes each share to a separate file for offline distribution.
  Used with a **dev** key for tests here; run for real by the board during Phase B.
- **Custody** (who holds which of the four shares) is a founder decision made at ceremony time and
  recorded outside the repo. Not needed to write the code.

### 4.3 Seal library — `backend/src/lib/idVault.ts`

Public-key-only. Depends on `libsodium-wrappers` and the `ID_VAULT_PUBLIC_KEY` config.

- `isVaultEnabled(): boolean` — true when a public key + version are configured.
- `sealName(name: string): Buffer` — `crypto_box_seal`.
- `sealAddress(raw: string): Buffer`.
- `upsertSeal(userId, { name?, address? })` — seals the provided part(s) and calls
  `SELECT id_vault.seal_upsert($1,$2,$3,$4)` with `(userId, sealedName|null, sealedAddress|null,
  keyVersion)`. The definer function does the partial upsert; a `null` part leaves the other column
  untouched. The app never touches the table directly. Idempotent.
- No open/decrypt function exists in the app. Attempting one is impossible: `crypto_box_seal_open`
  needs the secret key, which the app never holds.

### 4.4 Seal-on-write — signup and address change

**Signup** (`routes/auth.ts` + `connect.signup_with_invite` RPC):
- **Gating lives in the app — no RPC migration needed.** `connected_profiles.legal_name` is already
  nullable (admin promotion inserts without it), so when the vault is enabled the route seals the name
  and calls `signup_with_invite` with `p_legal_name = NULL`; when disabled it passes the real name
  (current behaviour). The RPC keeps its 4-arg signature and stays atomic.
- **Ordering (fail-safe):** the `user_id` (auth.users UUID) exists before `signup_with_invite` is
  called, so **seal first, then call the RPC**. This guarantees no state where a Connected profile
  exists without a vaulted name. A seal written before an RPC that then fails leaves an idempotent,
  overwritable orphan row — acceptable and self-healing on retry.

**Address change** (verification / district re-derivation flow):
- The raw street address is present transiently (`verification_sessions.home_address_draft`). Seal it
  into the vault (public key only, no ceremony), then re-derive districts via the existing path, then
  discard the transient draft.
- **New retention, made explicit:** today the raw address is discarded once districts resolve
  (migration 060). This build begins **retaining it, sealed**, because it is the break-glass payload
  named in data model §8a. The precise coordinates continue under the existing single key (D5).

### 4.5 Empowerment promotion — confirm, don't unseal

`lib/empowerService.ts` today reads `connected.legal_name` to build the candidate slug and fill the
**public** `empowered_profiles.legal_name`. After vaulting, that column is `NULL`.

- Resolve by having the member **confirm their real name at promotion** — they are going public
  anyway. Promotion takes the name from that confirmed input, uses it for the slug and the public
  profile.
- **Not** a vault read, **not** a break-glass. A routine promotion must never need two officers.
- **Backend (this plan):** `runPreflight` and `confirmEmpowerment` accept an optional confirmed name;
  they prefer it and fall back to `connected.legal_name` when absent, so promotion keeps working
  across the cutover.
- **Frontend (Phase-C prerequisite, out of this plan):** the promotion UI (in the `admin/` app, not
  `app/src`) must send the confirmed name before the column is nulled, or promotion has no name to
  use. Tracked as a prerequisite of Phase C, planned once the component is located.

### 4.6 Admin account detail — drop the name

`lib/adminService.ts` + `routes/admin.ts` return `legal_name` and log `viewed_fields:
['tolerance_rating','legal_name',…]`. This is exactly the single-admin visibility the vault removes.

- Strip `legal_name` from the object `getAccountDetail` returns, and remove it from `viewed_fields`.
  (The `admin_get_account_detail` RPC still computes it; that is harmless and an optional later
  cleanup — the API response no longer carries it.)
- After the vault, no admin can see the name; only the offline two-person break-glass can.

### 4.7 Backfill + null (staged, held for Phase C)

- **Backfill script** (`backend/scripts/id-vault-backfill.mts`): reads every
  `connect.connected_profiles` row with a non-null `legal_name`, seals it with the **production**
  public key, upserts into the vault. Idempotent; re-runnable.
- **Verify:** every non-null `legal_name` has a corresponding sealed row (count gate).
- **Null-column migration** (guarded, steward number, `DO $$ … $$` post-verify gate in house style):
  sets `connect.connected_profiles.legal_name = NULL` for all rows, asserts zero non-null remain.
  Keeps `display_name` / username untouched.
- Both are **written this session, applied only in Phase C** (after the ceremony + a verified
  backfill on prod).

### 4.8 Break-glass CLI — `backend/scripts/id-vault-break-glass.mts`

Offline, never wired to a route.

- **Inputs:** at least two of the four share files, a target `user_id`, and a required
  `--reason "<case>"`. Refuses to run without `--reason`.
- **Does:** `secrets.combine` → private key in memory; reads the target's `sealed_*` ciphertext;
  `crypto_box_seal_open` → prints the name + address for **that one user**; appends
  `{participating members, timestamp, user_id, reason}` to an append-only audit log; wipes the key
  from memory.
- **Isolation:** decrypts exactly the one requested `user_id` (procedural, D3).
- **`README`** beside it: custody, the two-person rule, how to assemble shares, where the log lives,
  and the drill.

---

## 5. Data flow

- **Signup (Connect):** name → `sealName` → `upsertSeal(user_id)` → `signup_with_invite`
  (profile row, `legal_name = NULL`). District resolution unchanged.
- **Address change:** raw address → `sealAddress` → `upsertSeal(user_id)`; coords encrypted under the
  existing single key; districts re-derived; transient draft discarded.
- **Promotion to Empowered:** member confirms real name → public `empowered_profiles.legal_name` +
  slug. Vault untouched.
- **Admin view:** no name shown; `viewed_fields` no longer lists it.
- **Break-glass (rare):** two members + reason, offline → one user's name + address; logged.

Districts, XP, gems, compass, posts — all continue keyed by the user id under the username. No
behaviour re-keying (the founders judged that overkill; data model §7 defers it).

---

## 6. Error handling / failure modes

| Situation | Behaviour |
|---|---|
| `ID_VAULT_PUBLIC_KEY` unset (pre-ceremony) | `isVaultEnabled()` false → current behaviour (name still written to profile). No broken intermediate state. |
| Seal write fails after seal-first, before RPC | Orphan idempotent vault row; RPC not run; retry overwrites. Account not created. |
| RPC fails after a successful seal | Vault row for an account that stayed Inform tier; harmless, overwritten on retry. |
| Lost key shares | 2-of-4 survives losing up to two holders. Re-split when a member leaves. Sealed data is unrecoverable only if 3+ shares are lost — documented risk, drill required. |
| App attempts to decrypt | Impossible — no secret key in app config; proven by test (§7). |
| Break-glass without `--reason` | Refuses; no output, no log line. |

---

## 7. Testing — acceptance checks mapped to tests

1. **App cannot decrypt with what it holds.** With only the public key configured, the app has no
   `crypto_box_seal_open` path; a test asserts no secret key is reachable and that opening requires a
   secret key. *(0022 test 5a; task acceptance 1)*
2. **Seal works with the public key alone.** `sealName` / `sealAddress` produce blobs that open only
   with the dev secret key. *(task acceptance 2)*
3. **2-of-4 reconstruction.** Any two of four dev shares reconstruct the key and open a sealed blob;
   **one share fails.** *(task acceptance 3)*
4. **Column is null and unread.** Post-backfill: the null migration's post-verify gate asserts zero
   non-null `legal_name`; a repo check + `grep` confirms no live read path remains. *(task acceptance 4)*
5. **Districts still resolve** for a member whose raw address is sealed — existing district read-path
   tests stay green + a targeted test. *(task acceptance 5)*
6. **Break-glass** refuses without `--reason` and writes the audit line when given one. *(task
   acceptance 6)*

---

## 8. Migrations + steward

CA_ namespace = Andrews. Two slots, **reserved at build time** (not now). No signup-RPC migration —
signup gating is in the app (§4.4).

```bash
npm run steward --prefix backend -- slot CA --purpose "id_vault schema + sealed_identities table + grants"
npm run steward --prefix backend -- slot CA --purpose "null connect.connected_profiles.legal_name after backfill"
```

Each migration idempotent (`IF NOT EXISTS`, guards) with a `DO $$ … $$` post-verify gate, dry-run
`BEGIN; … ROLLBACK;` against prod first, per the repo's migration house style.

---

## 9. Rollout — three phases, safe at every step

**Phase A — software (this build, one PR, mergeable):**
- add deps; `id_vault` schema migration (safe to apply — empty table);
- seal library; keygen/split tooling; break-glass CLI + README; backfill script (unrun);
- seal-on-write wiring **gated on `ID_VAULT_PUBLIC_KEY`** (unset ⇒ current behaviour);
- promotion confirm-name change; admin-view drop; null-column migration (unapplied);
- tests green with a dev key.

**Phase B — ceremony (humans, offline; ops runbook, not code):**
- board generates the production keypair, splits 2-of-4, distributes shares, destroys the whole key;
- set `ID_VAULT_PUBLIC_KEY` + `ID_VAULT_KEY_VERSION` in prod → new signups/address changes now seal.

**Phase C — backfill + null (after B):**
- run the backfill script on prod with the production public key; verify counts;
- apply the null-column migration; confirm the post-verify gate; `grep`/check clean.

Phases B and C are documented here and in the CLI README; this session executes neither (they need
the board and prod).

---

## 10. Open questions (none block Phase A)

- **Isolation level** — procedural (built) vs cryptographic threshold. Founder-open in 0022; base is
  procedural. Threshold would change only §4.8's read mechanism.
- **Share custody** — which board member holds which of the four shares. Ceremony-time founder
  decision; not needed for code.
- **New retention of sealed street addresses** — the build starts retaining raw addresses (sealed).
  **Acknowledged (Chris Andrews, 2026-09-17):** intended per §8a as the break-glass payload; proceed.
- **Key rotation on a board change** — new `key_version` for new/updated seals; old shares retained
  until old rows re-seal (via natural churn or a one-off break-glass re-seal). Documented, deferred.

---

## 11. Do NOT (from 0022 / task)

- No one-person-one-account fingerprint / nullifier here (property C, separate task).
- No private key or share online, in an env var, or in the database.
- No names into WorkOS.
- No behaviour-table re-keying into separate rooms.
