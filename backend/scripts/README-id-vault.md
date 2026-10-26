# The identity vault — scripts and operator runbook

**Spec:** [`docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md`](../../docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md)
**Decision:** `ev-cto/knowledge/decisions/0022-connected-identity-vault.md`
**Schema migration:** `backend/migrations/CA_0118_id_vault_schema.sql`
**Null-column migration (Phase C, unapplied until the backfill is verified):**
`backend/migrations/CA_0119_null_connected_legal_name.sql`

Read this before you run any of the scripts below. It explains what the vault is, when
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
| `id-vault-check-shares.mts` | After the ceremony, offline, two holders | Confirms two shares rebuild the key for the production public key. Opens no record, prints no key. |
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
   shared channel, never email, never Slack). If the board cannot meet in person, follow §4a
   instead.
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

## 4a. Remote distribution (when the board cannot meet)

The board lives in different places, so the in-person handover in §4 is usually not possible.
This section replaces §4 steps 1, 2 and 4 for a remote ceremony. Steps 3 and 5 are unchanged.

**Why remote is acceptable.** One share alone reveals nothing about the key. An attacker has to
obtain **two** shares, from two different people, to read anything. So the goal is not a perfect
channel — it is that no single channel, device or service ever holds two shares, and that no
share is left behind on the ceremony machine.

**Accept two facts before you start:**

- The person who runs the ceremony (the *operator*) sees all four shares. That cannot be
  avoided with a single dealer. The operator must be trusted to destroy them afterwards.
- "Offline" does not need an air-gapped computer. It means the shares never reach a disk that
  syncs, backs up, or keeps deleted files. The steps below get that on an ordinary Mac.

### Before the ceremony

1. Confirm with the founders **which four people** hold shares, and record the assignment
   (share 1 → name, share 2 → name, …) somewhere outside this repo.
2. Each holder installs **Signal** on their phone. Signal messages are end-to-end encrypted:
   only the sender and receiver can read them.
3. On a **phone or video call** with each holder, compare your Signal **safety number** with
   theirs (open the chat → their name → *View safety number*). If the numbers match, no one is
   sitting between you. Do this before any share is sent.
4. In each one-to-one Signal chat, turn on **disappearing messages** (1 hour is enough).
5. On the ceremony Mac, pause **Time Machine** for the session, and do not use a folder inside
   iCloud Drive, Desktop or Documents.

### The ceremony (operator)

1. Turn off Wi-Fi and unplug Ethernet. The machine stays offline while shares exist.
2. Create a RAM disk — a temporary drive that lives only in memory. It is never written to the
   SSD, never synced, never backed up, and it is gone when ejected:
   ```bash
   diskutil erasevolume APFS VaultCeremony $(hdiutil attach -nomount ram://65536)
   ```
3. From `backend/`, generate the keypair into the RAM disk:
   ```bash
   npx tsx scripts/id-vault-keygen.mts /Volumes/VaultCeremony --key-version 1
   ```
4. Copy the two printed lines (`ID_VAULT_PUBLIC_KEY=…`, `ID_VAULT_KEY_VERSION=1`) into a
   note. **These are not secret** — the public key can only seal, never read.
5. Send each share to its holder through **Signal on your phone**, one chat per holder, one
   share per chat. Never put two shares in the same message, chat or file. Re-type each share
   by hand from the screen (the phone never touches the Mac's files), then have the holder read
   back the first and last eight characters on the call to confirm the copy is exact.
   - *Simpler, slightly weaker:* drag each share file into Signal **Desktop**. This is still
     end-to-end encrypted, but the Mac's Signal app then holds every share until the messages
     disappear.
   - Do **not** run the ceremony inside Claude Code or any AI or chat tool — its output leaves
     the machine.
6. Each holder saves their share **offline** — printed on paper, or on a USB stick — stores it
   somewhere safe (a home safe, a safe-deposit box), and confirms back to you. The Signal
   message then deletes itself; ask them to delete it by hand too.
7. Eject the RAM disk (`diskutil eject /Volumes/VaultCeremony`), clear the terminal scrollback,
   and only then turn the network back on.
8. Continue with §4 step 3 (set the two values in prod) and step 5 (confirm every holder can
   find their share).

### Check a pair before anything depends on the shares

Hand-copied shares can carry a typo that the read-back of the first and last characters misses.
Before Phase C clears the plain-text names (§5 step 3), prove that one pair rebuilds the key:

1. Two holders join a call. One sends their share to the other over Signal, as in the remote
   break-glass below.
2. The receiver saves both shares as files on a RAM disk, turns off the network, and runs:
   ```bash
   npx tsx scripts/id-vault-check-shares.mts \
     --pubkey <production public key> \
     --share /Volumes/VaultCeremony/a.txt --share /Volumes/VaultCeremony/b.txt
   ```
3. `MATCH` (exit 0) means the pair rebuilds the production key. `NO MATCH` (exit 1) means it
   does not — try the other share holders before you conclude the ceremony failed, and do
   **not** apply `CA_0119` until a pair matches.
4. Eject the RAM disk. The tool opens no record and writes no audit line, because it reads no
   identity — but the receiver has now seen two shares, the same exposure as a break-glass.


### Low-tech and high-security alternatives

- **Post.** Print each share and mail it in a sealed envelope, one share per envelope, to one
  holder. One lost envelope does no harm, but you cannot tell whether an envelope was opened —
  so if one arrives damaged, rotate (§7).
- **Encrypt each share to its holder's own key.** Each holder installs `age`, runs
  `age-keygen -o key.txt`, and sends you only the public line (`age1…`). You run
  `age -r age1… -o share-N.age id-vault-share-N-of-4.txt`; the `.age` file is then safe to send
  over any channel, even email. This is the strongest option, but every holder must manage a
  command-line tool and a private key file, so it suits a technical board best.

### Remote break-glass

A break-glass needs two shares on one machine. Remotely, that means one holder sends their share
to the other, so the §6 rule "do not consolidate both shares ahead of time" becomes "consolidate
only during the run, with both people on the call":

1. Both holders join a video call and agree the `--reason` (§6 step 2).
2. The holder who will **not** run the tool sends their share over a safety-number-verified
   Signal chat with disappearing messages on, during the call.
3. The runner saves it to a RAM disk (as above), runs §6 step 3, then ejects the RAM disk.
4. The runner has now held a full key, and the sender's share has passed through a second
   person. **Consider rotating (§7) after a real break-glass.** A new key protects everything
   sealed from then on; rows sealed under the old key stay readable with the old key until they
   are re-sealed (§7 step 3).

Note that the break-glass tool needs a `--db` connection to read the sealed rows, so unlike the
ceremony, that machine cannot be fully offline while it runs.

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
