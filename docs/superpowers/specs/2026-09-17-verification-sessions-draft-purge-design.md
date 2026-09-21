# Design — Purge `verification_sessions` identity drafts after enrollment

**Status:** Design, awaiting review (2026-09-17, Chris Andrews).
**Follows:** `docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md` (Phase A, merged in PR #528).
**Source finding:** whole-branch review of the Connect identity vault — a plaintext identity store the Phase A build did not address.
**Data model:** `docs/PRIVACY-DATA-MODEL.md` §5.
**Repo:** ev-accounts.

---

## 1. The finding

`connect.verification_sessions.legal_name_draft` and `connect.verification_sessions.home_address_draft`
hold the member's **plaintext real name and raw street address** during enrollment, and **retain both
after enrollment completes**. `complete_connect_flow` (`backend/migrations/060_drop_home_address.sql`,
last touched by `CA_0120`) reads the drafts, creates the profile, and sets `step_reached='complete'` —
it **never clears them**. Migration 060 deliberately left `home_address_draft` in place
("ephemeral enrollment state — intentionally NOT removed here").

These rows are readable by the `BYPASSRLS` `ev_api` role, so the vault's stated goal — the real name
and raw street address are *"readable never by the running app, the database, or any single person"* —
**is not met while the drafts persist**. This is a **hard blocker** before the identity vault is
switched on (Phase B/C). It is out of scope of the Phase A PR (which ships gated-off).

`docs/PRIVACY-DATA-MODEL.md` §5 already states the intended disposition — the drafts are to be
*"deleted the moment districts are resolved"* — and the vault spec §4.4 already **intended** the draft
address to be *"seal[ed] into the vault … then discard[ed]."* Both intentions went unimplemented. This
design implements them.

---

## 2. Scope — what actually writes the drafts

Traced in `backend/src` this session:

- **Only the multi-step path writes drafts.** `POST /api/connect/start` + `PATCH /api/connect/step`
  populate `legal_name_draft` / `home_address_draft`; `POST /api/connect/complete` →
  `complete_connect_flow` consumes them. **This is the only path that creates drafts.**
- **The signup path creates no drafts.** `routes/auth.ts` `POST /signup` with `invite_code` + `legal_name`
  calls `connect.signup_with_invite`, which writes `connect.connected_profiles` **directly** and never
  touches `verification_sessions` (verified against `085_signup_with_invite_yellow_transfer.sql`, the
  live definition). It also carries **no address at all**. So the signup path has **nothing to purge** —
  recorded here as a by-inspection finding, not a code change. The task's "both paths" framing is
  satisfied by covering `/complete` and confirming the signup path is clean.
- **`home_address_draft` is never geocoded server-side.** District resolution happens in the separate
  `POST /api/connect/set-location`, which reads a **fresh** `address` from the request body
  (`app/src/pages/onboarding/steps/LocationStep.tsx` composes it from street/city/state/zip), **not**
  from the draft. The draft address is therefore a leftover artifact once `/complete` has run; nothing
  downstream reads it. `set-location` already seals its body-param address into the vault
  (`sealAddressIfEnabled`, spec §4.4 / Task 8).
- **Only the two sensitive columns are in scope.** `display_name_draft` (the public username, synced to
  `public.users`) and `region_draft` (coarse) are not identity secrets and are left untouched, matching
  data-model §5, which names only `legal_name_draft` and `home_address_draft`.

---

## 3. Decisions locked for this build

| # | Decision | Rationale |
|---|---|---|
| P1 | **Seal-then-null the draft address at `/complete`.** When the vault is enabled, seal `home_address_draft` into `id_vault` **before** the drafts are nulled. | Task step 2; spec §4.4 ("seal … then discard the transient draft"); D5 (raw address belongs in the vault). Break-glass can retrieve the enrollment address even if `set-location` is delayed or never called. Confirmed by Chris Andrews, 2026-09-17. |
| P2 | **The address seal is fatal when the vault is enabled** — a seal failure aborts `/complete`, so a draft is never nulled before it is safely sealed. | Mirrors the existing name-seal fail-safe ordering (§4.4). The alternative — non-fatal, as in `set-location` — is wrong *here* because `/complete` is about to destroy the only copy. |
| P3 | **Drafts are nulled atomically inside `complete_connect_flow`**, in the same `UPDATE` that sets `step_reached='complete'`. | The RPC already holds `SELECT … INTO v_session FOR UPDATE`; nulling there is atomic with profile creation. An app-side `UPDATE` after the RPC could fail post-commit and orphan the drafts (the retry hits `ALREADY_CONNECTED` and skips cleanup). |
| P4 | **Draft nulling is unconditional** (vault on or off); **sealing is conditional** (vault on only). | The drafts are a plaintext leak regardless of vault state — nulling is hygiene owed either way. Sealing needs the public key, which only exists post-ceremony. |
| P5 | **Existing completed rows are plain-purged, not sealed.** | Phase A has no production key to seal with, and the vault is gated off. Those addresses were never vaulted and are unrecoverable elsewhere (060 dropped the column; the §4.7 backfill does names only), so a plain purge completes what §5 always intended. Safe to apply immediately — no key, no ceremony dependency. |

---

## 4. Components

Each unit has one purpose, a defined interface, and is testable alone.

### 4.1 App — seal name **and** address before the RPC (`routes/connect.ts`, `lib/connectService.ts`)

- **New `connectService.getEnrollmentDrafts(userId)`** → `{ legalName: string | null; homeAddress: string | null }`,
  one `SELECT legal_name_draft, home_address_draft FROM connect.verification_sessions WHERE user_id = $1`.
  Replaces the single-column `getLegalNameDraft`, whose only production caller is `resolveCompleteConnectSeal`
  (verified this session) — fold it into `getEnrollmentDrafts` and update the `connectService` mock in
  `connect.idVault.test.ts` accordingly.
- **Broaden `resolveCompleteConnectSeal(userId): Promise<boolean>`** (in `routes/connect.ts`): when
  `isVaultEnabled()`, read both drafts once and seal the present parts in a **single** idempotent
  `upsertSeal(userId, { name?, address? })`. `upsertSeal` COALESCEs, so a missing part leaves the other
  column untouched. Still returns the `p_seal_name` flag for the RPC. Any seal failure **propagates**
  (fatal — the `/complete` handler's catch turns it into a 500; the RPC never runs; drafts survive for
  retry). The route handler body is otherwise unchanged — it already calls `resolveCompleteConnectSeal`
  then `complete_connect_flow`.

Edge cases: name draft null but vault on → seal address only, `p_seal_name` still true (the RPC writes
`NULL` for `legal_name`, which is correct — there is no name). Both drafts null → skip `upsertSeal`,
flag still true. Vault off → seal nothing, flag false, RPC writes the plaintext name as today (until the
Phase C null migration `CA_0119`).

### 4.2 Migration #1 (CA slot) — `complete_connect_flow` nulls the drafts

Supersede the `CA_0120` function body. Copy it byte-for-byte (2-arg `(p_user_id uuid, p_seal_name boolean
DEFAULT false)` signature, the `CASE WHEN p_seal_name THEN NULL ELSE v_session.legal_name_draft END`
INSERT, the `service_role`-only ACL, the `to_regprocedure` post-verify gate) and add two assignments to
the existing "advance session to complete" `UPDATE`:

```sql
UPDATE connect.verification_sessions
SET step_reached      = 'complete',
    legal_name_draft  = NULL,
    home_address_draft = NULL,
    updated_at        = now()
WHERE user_id = p_user_id;
```

Ordering inside the function is safe: `SELECT … INTO v_session FOR UPDATE` captures the drafts first, the
`MISSING_REQUIRED_FIELDS` guard and the INSERT still use `v_session.*`, and only the trailing UPDATE
nulls the stored columns. `DROP FUNCTION IF EXISTS public.complete_connect_flow(uuid, boolean);` then
`CREATE OR REPLACE` (per the CA_0120 note on overload identity). Re-apply the `REVOKE ALL … FROM PUBLIC`
/ `GRANT EXECUTE … TO service_role` ACL. Keep the CA_0120 post-verify `DO $$…$$` gate; add nothing that
needs table data (the gate stays schema-only, so it is safe on an empty/any database).

Safe to apply in Phase A: it changes only future completions; existing rows are untouched by it.

### 4.3 Migration #2 (CA slot) — retroactive purge of existing completed rows

Guarded, idempotent `UPDATE`:

```sql
UPDATE connect.verification_sessions
SET legal_name_draft = NULL,
    home_address_draft = NULL,
    updated_at = now()
WHERE step_reached = 'complete'
  AND (legal_name_draft IS NOT NULL OR home_address_draft IS NOT NULL);
```

- **`step_reached = 'complete'` is load-bearing:** in-progress sessions (`invite` / `profile` / `review`)
  must keep their drafts so the member can resume; only completed enrollments carry drafts as pure
  leftover.
- **`DO $$…$$` post-verify gate:** `RAISE EXCEPTION` unless zero rows satisfy
  `step_reached='complete' AND (legal_name_draft IS NOT NULL OR home_address_draft IS NOT NULL)`.
- Plain purge, no seal (P5). Needs no key; **safe to apply now**, independent of the ceremony — it
  closes the existing exposure immediately.

Both migrations use per-author `CA_` slots, **reserved via the steward** at build time (`steward slot CA
--purpose …`), zero-padded to four digits, named to the reserved number straight away. Dry-run each body
`BEGIN; … ROLLBACK;` against prod first (house style), and confirm the rollback reverted.

### 4.4 Docs (task step 4)

- **Vault spec §4.4:** correct the address-change description — `set-location` seals a body-param address,
  not `home_address_draft` — and add the `/complete` draft disposition. Add an explicit note naming
  `verification_sessions` drafts as an **in-scope plaintext source**, with the seal-then-null disposition
  and a pointer to migration 060's now-superseded "intentionally NOT removed" comment.
- **`docs/PRIVACY-DATA-MODEL.md` §5:** update the "deleted the moment districts are resolved" line to cite
  the two migrations and state the disposition (name sealed, address sealed-then-purged, both drafts
  nulled atomically at completion by the RPC; existing rows purged retroactively).

---

## 5. Data flow (the `/complete` path, after this build)

**Vault enabled:**
1. `resolveCompleteConnectSeal(userId)` reads both drafts → `upsertSeal(userId, { name, address })`
   (fatal on failure) → returns `true`.
2. `complete_connect_flow(userId, true)` → INSERT profile with `legal_name = NULL` → advance step **and
   null both drafts** → sync `display_name`.
3. Later, on first `set-location`, the fresh geocoded address re-seals (idempotent; last write wins).

**Vault disabled (current prod):**
1. `resolveCompleteConnectSeal` seals nothing, returns `false`.
2. `complete_connect_flow(userId, false)` → INSERT profile with the plaintext name (as today) → advance
   step **and null both drafts** → sync `display_name`.

The retroactive purge (migration #2) closes the drafts on rows that completed before this build.

---

## 6. Error handling / failure modes

| Situation | Behaviour |
|---|---|
| Vault on, address (or name) seal fails at `/complete` | `upsertSeal` throws → 500 → RPC not called → drafts **survive** → retry re-seals and completes. No draft is nulled unsealed. |
| RPC fails after a successful seal | Vault row written; no profile; drafts survive; retry hits the idempotent seal + RPC. |
| Vault off at `/complete` | Name written plaintext (as today, until CA_0119); drafts nulled; no address retained anywhere. |
| In-progress session during migration #2 | Not matched (`step_reached <> 'complete'`); drafts preserved for resume. |
| Migration #2 leaves a stray non-null draft | Post-verify gate `RAISE EXCEPTION`s; migration fails loudly. |

---

## 7. Testing — acceptance mapped to checks

1. **`resolveCompleteConnectSeal` seals both parts (vault on).** Reads both drafts, calls `upsertSeal`
   once with `{ name, address }`; returns `true`. *(extend `connect.idVault.test.ts`)*
2. **Address-only when the name draft is null (vault on).** `upsertSeal` called with `{ address }`; flag
   still `true`.
3. **Vault off seals nothing.** No draft read, no `upsertSeal`; flag `false`.
4. **Seal failure is fatal.** A rejecting `upsertSeal` propagates out of `resolveCompleteConnectSeal`.
5. **RPC nulls the drafts.** Migration #1's `DO $$…$$` post-verify gate (schema-level) + a prod
   `BEGIN; … ROLLBACK;` dry-run confirming a completed session's drafts read `NULL` after the call.
6. **Retroactive purge is complete and scoped.** Migration #2's post-verify gate asserts zero completed
   rows with a non-null draft; the dry-run confirms in-progress rows are untouched.

`getEnrollmentDrafts` is added to the `connectService` mock in `connect.idVault.test.ts`.

---

## 8. Rollout fit

- **Migration #1** (function change) and **migration #2** (retroactive purge) are both safe to apply in
  **Phase A** — neither needs the production key. Applying migration #2 promptly closes the existing
  leak; migration #1 makes every future completion self-cleaning.
- Sealing remains gated on `ID_VAULT_PUBLIC_KEY` (unset in prod until Phase B), so with the vault off the
  only observable change is that drafts stop persisting — pure hygiene, no behaviour change for members.
- Per repo convention, this session **writes** the migrations; applying to prod is done by hand (Chris),
  dry-run first.

---

## 9. Do NOT

- Do not null `display_name_draft` / `region_draft` — out of scope, and `display_name` syncs to
  `public.users`.
- Do not null drafts for non-complete sessions — it breaks resume.
- Do not make the `/complete` address seal non-fatal — it would let a draft be destroyed before it is
  sealed.
- Do not attempt to seal existing rows in a migration — no key exists in Phase A.
- Do not add cleanup code to the signup path — it creates no drafts.
