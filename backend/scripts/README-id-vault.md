# The identity vault — scripts and operator runbook

**Spec:** [`docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md`](../../docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md)
**Decision:** `ev-cto/knowledge/decisions/0022-connected-identity-vault.md`
**Schema migration:** `backend/migrations/CA_0118_id_vault_schema.sql`
**Null-column migration (Phase C, unapplied until the backfill is verified):**
`backend/migrations/CA_0119_null_connected_legal_name.sql`

Read this before you run any of the four scripts below. It explains what the vault is, when
each script runs, and — most importantly — the ceremony and break-glass procedures, which are
**human processes**, not just commands.

## 1. What the vault is, in one paragraph

A Connect member's real name and raw street address are sealed (`crypto_box_seal`, libsodium)
with a public key the app holds. The matching private key is split 2-of-4 (Shamir's secret
sharing, `secrets.js-grempe`) across four board members and never exists whole except briefly,
offline, during a break-glass. The running app, the database, and any single person can seal
data in; **no one person, and nothing online, can read it back out.** Reading requires two board
members, offline, with a stated reason. Everything else about the member — district, XP, gems,
compass answers, posts — stays keyed by their user id as before; only the name and raw address
move behind this second lock.

## 2. The four scripts, and when each one runs

| Script | Runs | Purpose |
|---|---|---|
| `id-vault-keygen.mts` | **Once**, offline, at ceremony time (Phase B) | Generates the vault keypair and splits the private key into four share files. |
| `id-vault-backfill.mts` | **Once**, on prod, after Phase B | Seals every existing `connect.connected_profiles.legal_name` with the production public key. |
| *(null-column migration)* | **Once**, on prod, after the backfill is verified (Phase C) | `CA_0119_null_connected_legal_name.sql` — not a script, but the step that follows the backfill. Nulls `legal_name` once every row has a sealed counterpart. |
| `id-vault-break-glass.mts` | **As needed**, offline, two people at a time | The only read path. Reconstructs the private key from two share files and decrypts one named user's identity. |

Three of these (`keygen`, `backfill`, `break-glass`) are `.mts` files run with `tsx`. The fourth
step is a guarded SQL migration, applied the normal way once its precondition (a fully-sealed
backfill) holds.

## 3. The 2-of-4, offline, two-people rule

- The vault's private key is split into **four shares**, one per board member.
- **Any two** shares reconstruct the key (`secrets.combine`); **one share is not enough** — the
  library and the break-glass CLI both refuse.
- The reassembled key must **never** be written to disk, committed, emailed, or left on a
  machine that touches the network while assembled. It is regenerated in memory for the
  duration of one break-glass run and then it is gone.
- This is a **two-person control by construction**, not by policy: the math requires two share
  holders to act together. No single board member — and no engineer, no admin, no on-call
  responder — can unmask a member alone.

## 4. Phase B — the key ceremony (humans, offline; run once)

This step produces the **production** keypair. It cannot be done in CI, in a PR, or by one
person acting alone online — do it on a machine with no network connection, ideally in the same
room as the board members who will hold the shares.

1. On an offline machine, run:
   ```bash
   tsx scripts/id-vault-keygen.mts <out-dir> --key-version 1
   ```
   This prints the public key and writes four files,
   `id-vault-share-{1..4}-of-4.txt`, into `<out-dir>`.
2. **Distribute one share file to each of the four board members**, offline (e.g. on a USB
   drive handed over in person, or a password manager entry only that member can open — never a
   shared channel, never email, never Slack).
3. Set the two printed values in the **production** environment:
   ```
   ID_VAULT_PUBLIC_KEY=<the printed base64 public key>
   ID_VAULT_KEY_VERSION=1
   ```
   Setting these is what turns sealing on (`isVaultEnabled()` — see `src/lib/idVault.ts`); until
   they are set in prod, signups and address changes keep behaving exactly as they do today.
4. **Delete the four share files and destroy the reassembled key** from the ceremony machine —
   wipe the out-dir, and if the machine's disk isn't otherwise trusted, consider it compromised
   for this purpose going forward. The only place a share should exist afterward is with the
   board member it was handed to.
5. Confirm each board member can locate their share before ending the ceremony. A share that no
   one can find later is as good as lost.

Do this once per keypair. It is repeated only when the key is rotated (§7).

## 5. Phase C — backfill, then null (in that order, only after B)

Run these only after Phase B has set the production public key, and only in this order:

1. **Backfill** every existing plaintext name into the vault:
   ```bash
   tsx scripts/id-vault-backfill.mts --apply
   ```
   Without `--apply` it dry-runs and reports counts only. It is idempotent — safe to re-run.
2. **Verify** the backfill: every `connect.connected_profiles` row with a non-null `legal_name`
   must have a matching sealed row in `id_vault.sealed_identities`. The null-column migration's
   own guard checks this and refuses to proceed if any row is unsealed — but check it yourself
   first with a count query before applying the migration.
3. **Only then** apply `CA_0119_null_connected_legal_name.sql`. It nulls
   `connect.connected_profiles.legal_name` for every row and asserts (post-verify gate) that zero
   non-null rows remain. `display_name` and username are untouched — members keep their visible
   identity on the site; only the legal name and raw address move behind the vault.

**Never reverse this order.** Nulling the column before the backfill is verified would destroy
the only plaintext copy of a name that was never sealed — permanently.

## 6. Break-glass — the only read path

`id-vault-break-glass.mts` is **never a route**. It does not run in the API, is not reachable
over HTTP, and has no code path that a request handler could call. It is a script two board
members run together, offline, when there is a real reason to unmask one member's real name and
address (for example: a court order, a safety escalation, a legal request).

### Procedure

1. Two board members meet (in person or on a call), each bringing their own share file. Do not
   consolidate both shares onto one person's machine ahead of time — the whole point is that
   the assembly step itself requires both people present.
2. Agree the reason. It should be specific enough to stand on its own in an audit log — "court
   order 2026-11" or "safety escalation, case #204," not "checking something."
3. Run, on an offline or otherwise trusted machine:
   ```bash
   tsx scripts/id-vault-break-glass.mts \
     --pubkey <production public key> \
     --user <target user id> \
     --reason "<the agreed reason>" \
     --member <name-1> --member <name-2> \
     --share <path-to-share-1> --share <path-to-share-2> \
     --db "<privileged direct connection string>" \
     --log <path-to-audit-log>
   ```
   The `--db` connection is a **privileged, direct** connection string — not the `ev_api` role.
   `ev_api` has no read privilege on `id_vault.sealed_identities` at all (§4.1 of the design
   spec); reading the ciphertext out requires the same elevated access used for migrations.
4. The tool refuses (exit code 2) if `--reason` is missing or blank, or if fewer than two
   `--share` / `--member` values are given. It refuses (throws) if the two shares don't
   reconstruct a valid key.
5. On success it prints the decrypted name and address for **that one user only** — the tool
   has no facility for bulk or list decryption — and appends one line to the audit log.
6. **Destroy the reassembled key material immediately after** — close the terminal, clear
   scrollback, and do not save the printed output anywhere it would persist plaintext identity
   data outside this one-time review.

### Where the audit log lives

The audit log is an **append-only** JSON-lines file, one line per break-glass run:

```json
{"members":["alice","bob"],"user_id":"...","reason":"court order 2026-11","at":"2026-09-17T00:00:00Z"}
```

`appendAuditLine` opens the file in append mode (`flag: 'a'`) and never rewrites or truncates it
— there is no code path in this tool that deletes or edits a prior entry. Store this file
somewhere durable and outside normal deploy/rollback cycles (it is operational history, not
application data): a locked-down shared drive location, or committed to a private
ops-only record, is fine as long as it survives independently of the app's database and of any
one person's laptop. Treat every append to it as a permanent record of who looked at what, and
why.

### A drill, periodically

Run a break-glass drill on a **test** keypair and a **test** user on a regular cadence (annually
is a reasonable floor; tie it to a board or ops calendar item so it doesn't get skipped). The
drill exists to catch, before a real incident:

- a board member who can no longer find their share file;
- a `--db` connection string or privileged credential that has rotted since the last real use;
- confusion about the procedure itself — who calls whom, what reason gets logged, where the
  audit log actually lives.

A drill should use the test fixtures pattern in `id-vault-break-glass.test.ts` (a throwaway
keypair, `generateKeypair()` + `splitSecretKey()`) or a dedicated non-production keypair — never
run a drill against the production key or a real member's data.

## 7. Re-split (rotate) when a board member changes

The 2-of-4 split is tied to the four people who held shares at ceremony time. When a board
member leaves, is added, or a share is suspected lost or exposed:

1. Generate a **new** keypair with `id-vault-keygen.mts` (a fresh `ID_VAULT_KEY_VERSION`, e.g.
   incrementing from `1` to `2`), and hold a new ceremony (§4) distributing shares to the
   **current** board.
2. Set the new `ID_VAULT_PUBLIC_KEY` / `ID_VAULT_KEY_VERSION` in prod. New seals (signups,
   address changes) start using the new key immediately; existing rows keep their original
   `key_version` and are still readable with the old shares.
3. Re-sealing existing rows under the new key is not automatic — it happens by natural churn
   (a member's next address change re-seals under the new key) or, if a full migration off the
   old key is required, a one-off script that runs a break-glass-style open under the old shares
   and a fresh seal under the new public key, for every row still on the old `key_version`.
4. **Once every row is off the retired key**, the old shares are no longer useful and the board
   members who held them may destroy them. Until then, keep old shares available — some rows may
   still need them.
5. Do this **promptly** on a board departure — a departing member's retained share is a standing
   risk (they now hold one of only two things needed, alongside any other single share, to
   reconstruct the key) until the rotation completes.
