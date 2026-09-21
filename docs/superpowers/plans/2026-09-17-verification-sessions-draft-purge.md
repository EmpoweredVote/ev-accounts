# Purge verification_sessions identity drafts — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop `connect.verification_sessions` from retaining the plaintext real name and raw street address after enrollment completes — seal them into the vault when enabled, then null both drafts, and purge the drafts already sitting on completed rows.

**Architecture:** At `POST /api/connect/complete`, the app seals both drafts into `id_vault` (fatal on failure when the vault is enabled) before calling `complete_connect_flow`; the RPC nulls both drafts atomically in the same `UPDATE` that marks the session complete. A second migration retroactively purges drafts from already-completed sessions. The signup path creates no drafts and is unchanged.

**Tech Stack:** TypeScript / Express (`backend/src`), Vitest, PostgreSQL migrations (`backend/migrations`, `CA_` author namespace via the steward allocator), `libsodium`-backed `id_vault` seal library.

**Spec:** [`docs/superpowers/specs/2026-09-17-verification-sessions-draft-purge-design.md`](../specs/2026-09-17-verification-sessions-draft-purge-design.md)

## Global Constraints

- **Report to Chris in ASD-STE100 Simplified Technical English** (chat only; files, comments, commit messages follow repo conventions).
- **Migration numbers come from the steward allocator, never by counting:** `npm run steward --prefix backend -- slot CA --purpose "…"`. Author namespace for this work is **`CA_` = Chris Andrews**. Name the file the returned number immediately, zero-padded to four digits. CI job "migration reservations" fails an unreserved slot.
- **Migrations are idempotent** (`IF NOT EXISTS` / `NOT EXISTS` / guarded `UPDATE`) and end with a `DO $$ … $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count (house style).
- **Dry-run every migration against prod first** by wrapping the body `BEGIN; … ROLLBACK;` and confirming the rollback reverted before trusting it.
- **`git fetch origin` before `npm run check:migrations --prefix backend`** — a stale worktree is the most common source of a number collision.
- **Commit with an explicit pathspec:** `git commit -F <msgfile> -- <path> [<path> …]`. Never `git add -A` / `git add .` / `git commit -a` (shared-worktree rule).
- **This session writes migrations; it does not apply them to prod.** Chris applies, after the dry-run.
- Occupancy guard is unaffected here, but the standard CI suite (`test`, `typecheck`, `lint`, `check:migrations`, `check:reservations`) must stay green.

---

### Task 1: Seal both drafts before the RPC (app + tests)

**Files:**
- Modify: `backend/src/lib/connectService.ts` (replace `getLegalNameDraft` at lines 349-363 with `getEnrollmentDrafts`)
- Modify: `backend/src/routes/connect.ts` (import at line 17; `resolveCompleteConnectSeal` at lines 102-111)
- Test: `backend/src/routes/connect.idVault.test.ts` (mock at lines 19-42; describe block at lines 81-119)

**Interfaces:**
- Consumes: `isVaultEnabled(): boolean`, `upsertSeal(userId: string, parts: { name?: string; address?: string }): Promise<void>` (both from `backend/src/lib/idVault.ts`, unchanged).
- Produces:
  - `connectService.getEnrollmentDrafts(userId: string): Promise<{ legalName: string | null; homeAddress: string | null }>`
  - `resolveCompleteConnectSeal(userId: string): Promise<boolean>` (same signature; now seals name **and** address).

- [ ] **Step 1: Update the test mock to expose `getEnrollmentDrafts`**

In `backend/src/routes/connect.idVault.test.ts`, replace the hoisted `getLegalNameDraft` mock (line 19) and its entry in the `connectService.js` mock (line 22):

```typescript
const getEnrollmentDrafts = vi.hoisted(() => vi.fn());
vi.mock('../lib/connectService.js', () => ({
  getLocationConsent: vi.fn(),
  getEnrollmentDrafts,
  getConnectedProfile: vi.fn(),
  upsertConnectedProfile: vi.fn(),
  setLocationConsent: vi.fn(),
  getDistrictAssignments: vi.fn(),
  completeConnectFlow: vi.fn(),
  getPeerRequests: vi.fn(),
  createPeerRequest: vi.fn(),
  respondToPeerRequest: vi.fn(),
  getConnections: vi.fn(),
  hasConnectedProfile: vi.fn(),
  getConnectedProfileVerificationStatus: vi.fn(),
  getVerificationSession: vi.fn(),
  getVerificationSessionStep: vi.fn(),
  getVerificationSessionId: vi.fn(),
  upsertVerificationSession: vi.fn(),
  updateVerificationSession: vi.fn(),
  validateCompassVersions: vi.fn(),
  saveCompassImportDraft: vi.fn(),
  importCompassCalibrations: vi.fn(),
}));
```

- [ ] **Step 2: Replace the `resolveCompleteConnectSeal` describe block with the new failing tests**

Replace lines 81-119 (the `describe('POST /complete name sealing …')` block) with:

```typescript
describe('POST /complete draft sealing (resolveCompleteConnectSeal)', () => {
  beforeEach(() => {
    isEnabled.mockReset();
    upsertSeal.mockReset();
    getEnrollmentDrafts.mockReset();
  });

  it('vault ON with both drafts: reads them once, seals name+address in a single upsert, flags the RPC', async () => {
    isEnabled.mockReturnValue(true);
    getEnrollmentDrafts.mockResolvedValue({ legalName: 'Ada Lovelace', homeAddress: '742 Evergreen Terrace' });

    const sealName = await resolveCompleteConnectSeal('user-1');

    expect(getEnrollmentDrafts).toHaveBeenCalledWith('user-1');
    expect(upsertSeal).toHaveBeenCalledTimes(1);
    expect(upsertSeal).toHaveBeenCalledWith('user-1', { name: 'Ada Lovelace', address: '742 Evergreen Terrace' });
    expect(sealName).toBe(true);
  });

  it('vault ON with only an address draft: seals the address alone, still flags the RPC', async () => {
    isEnabled.mockReturnValue(true);
    getEnrollmentDrafts.mockResolvedValue({ legalName: null, homeAddress: '742 Evergreen Terrace' });

    const sealName = await resolveCompleteConnectSeal('user-1');

    expect(upsertSeal).toHaveBeenCalledWith('user-1', { address: '742 Evergreen Terrace' });
    expect(sealName).toBe(true);
  });

  it('vault ON with no drafts (edge case): does not call upsertSeal, still flags the RPC', async () => {
    isEnabled.mockReturnValue(true);
    getEnrollmentDrafts.mockResolvedValue({ legalName: null, homeAddress: null });

    const sealName = await resolveCompleteConnectSeal('user-1');

    expect(getEnrollmentDrafts).toHaveBeenCalledWith('user-1');
    expect(upsertSeal).not.toHaveBeenCalled();
    expect(sealName).toBe(true);
  });

  it('vault OFF: never reads drafts or seals, and tells the RPC not to null the column', async () => {
    isEnabled.mockReturnValue(false);

    const sealName = await resolveCompleteConnectSeal('user-1');

    expect(getEnrollmentDrafts).not.toHaveBeenCalled();
    expect(upsertSeal).not.toHaveBeenCalled();
    expect(sealName).toBe(false);
  });

  it('vault ON, seal fails: the error propagates (fatal — the RPC never runs, drafts survive)', async () => {
    isEnabled.mockReturnValue(true);
    getEnrollmentDrafts.mockResolvedValue({ legalName: 'Ada Lovelace', homeAddress: '742 Evergreen Terrace' });
    upsertSeal.mockRejectedValue(new Error('seal boom'));

    await expect(resolveCompleteConnectSeal('user-1')).rejects.toThrow('seal boom');
  });
});
```

- [ ] **Step 3: Run the test file to verify the new tests fail**

Run: `npm test --prefix backend -- src/routes/connect.idVault.test.ts`
Expected: FAIL — `resolveCompleteConnectSeal` still calls `getLegalNameDraft`, so `getEnrollmentDrafts` is never called and the both-drafts assertion fails; the import of `getEnrollmentDrafts` does not yet exist.

- [ ] **Step 4: Add `getEnrollmentDrafts` to `connectService.ts`**

In `backend/src/lib/connectService.ts`, replace the `getLegalNameDraft` function (lines 349-363) with:

```typescript
export interface EnrollmentDrafts {
  legalName: string | null;
  homeAddress: string | null;
}

/**
 * getEnrollmentDrafts
 * Server-side trusted read of the transient identity drafts captured during
 * Connect enrollment (connect.verification_sessions.legal_name_draft /
 * home_address_draft). Used by POST /complete's seal-on-write path (spec §4.4)
 * to seal the real name and raw address into id_vault BEFORE complete_connect_flow
 * nulls both drafts. Returns nulls when there is no session for the user, or a
 * draft is unset.
 */
export async function getEnrollmentDrafts(userId: string): Promise<EnrollmentDrafts> {
  const { rows } = await pool.query<{ legal_name_draft: string | null; home_address_draft: string | null }>(
    `SELECT legal_name_draft, home_address_draft FROM connect.verification_sessions WHERE user_id = $1`,
    [userId]
  );
  return {
    legalName: rows[0]?.legal_name_draft ?? null,
    homeAddress: rows[0]?.home_address_draft ?? null,
  };
}
```

- [ ] **Step 5: Broaden `resolveCompleteConnectSeal` in `connect.ts`**

In `backend/src/routes/connect.ts`, change the import on line 17 from `getLegalNameDraft,` to `getEnrollmentDrafts,`. Then replace `resolveCompleteConnectSeal` (lines 102-111) with:

```typescript
/**
 * Seal-first draft routing for POST /complete. Mirrors resolveSignupLegalName
 * (routes/auth.ts): when the vault is enabled, read the enrollment drafts and
 * seal the real name AND raw address into id_vault BEFORE calling
 * complete_connect_flow (fail-safe ordering — spec §4.4). The seal is FATAL: if
 * it throws, /complete returns 500, the RPC never runs, and the drafts survive
 * for a clean retry — a draft is never nulled before it is safely sealed.
 * complete_connect_flow then nulls both drafts atomically. Returns the p_seal_name
 * flag the RPC uses to NULL connected_profiles.legal_name instead of writing the
 * plaintext draft (CA_0120).
 */
export async function resolveCompleteConnectSeal(userId: string): Promise<boolean> {
  const sealName = isVaultEnabled();
  if (sealName) {
    const { legalName, homeAddress } = await getEnrollmentDrafts(userId);
    const parts: { name?: string; address?: string } = {};
    if (legalName) parts.name = legalName;
    if (homeAddress) parts.address = homeAddress;
    if (Object.keys(parts).length > 0) {
      await upsertSeal(userId, parts);
    }
  }
  return sealName;
}
```

- [ ] **Step 6: Run the test file to verify it passes**

Run: `npm test --prefix backend -- src/routes/connect.idVault.test.ts`
Expected: PASS (all five `resolveCompleteConnectSeal` tests plus the unchanged `set-location` tests).

- [ ] **Step 7: Typecheck and lint**

Run: `npm run typecheck --prefix backend && npm run lint --prefix backend`
Expected: no errors. (If any other file still imports `getLegalNameDraft`, typecheck will flag it — none should; verified this session that `resolveCompleteConnectSeal` is the sole caller.)

- [ ] **Step 8: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/stoic-kilby-30506c
printf '%s\n' \
  'feat(id-vault): seal name+address drafts before /complete, fold getLegalNameDraft into getEnrollmentDrafts' \
  '' \
  'resolveCompleteConnectSeal now reads both enrollment drafts in one query and' \
  'seals the real name AND raw address into id_vault in a single idempotent' \
  'upsert before complete_connect_flow runs (fatal on failure). Prepares the RPC' \
  'to null both drafts (next migration).' \
  '' \
  'Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>' > /tmp/msg1.txt
git commit -F /tmp/msg1.txt -- backend/src/lib/connectService.ts backend/src/routes/connect.ts backend/src/routes/connect.idVault.test.ts
```

---

### Task 2: `complete_connect_flow` nulls both drafts (migration #1)

**Files:**
- Create: `backend/migrations/<CA_SLOT_1>_complete_connect_flow_null_drafts.sql`

**Interfaces:**
- Consumes: nothing from Task 1 at the DB layer (the app seals before this RPC runs).
- Produces: `public.complete_connect_flow(p_user_id uuid, p_seal_name boolean DEFAULT false)` that, in addition to CA_0120's behaviour, sets `legal_name_draft = NULL, home_address_draft = NULL` on the session it marks complete.

- [ ] **Step 1: Reserve the migration slot**

Run: `npm run steward --prefix backend -- slot CA --purpose "complete_connect_flow nulls verification_sessions identity drafts after completion"`
This prints a slot such as `CA_0121`. **Use that exact number wherever `<CA_SLOT_1>` appears below**, in the filename and the header comment. Do not count by hand.

- [ ] **Step 2: Write the migration file**

Create `backend/migrations/<CA_SLOT_1>_complete_connect_flow_null_drafts.sql`. This is CA_0120's body copied verbatim, with the single-line addition of the two `NULL` assignments to the "advance session to complete" `UPDATE` (marked below). Replace `<CA_SLOT_1>` in the header with the reserved number:

```sql
-- <CA_SLOT_1> — complete_connect_flow nulls verification_sessions identity drafts.
--
-- Follow-up to the identity-vault review (spec
-- docs/superpowers/specs/2026-09-17-verification-sessions-draft-purge-design.md).
-- Before this, complete_connect_flow marked the session complete but LEFT
-- legal_name_draft and home_address_draft in place — a plaintext name + raw
-- address readable by the BYPASSRLS ev_api role. The /complete route now seals
-- both into id_vault first (when the vault is enabled); this RPC nulls both
-- drafts in the SAME UPDATE that advances step_reached, atomically with profile
-- creation. Supersedes migration 060's "home_address_draft ... intentionally NOT
-- removed here" comment.
--
-- Body is copied byte-for-byte from CA_0120_complete_connect_flow_seal_parity.sql
-- (the current live definition); the ONLY change is the two NULL assignments in
-- the "advance session to complete" UPDATE. Signature, p_seal_name CASE, ACL and
-- post-verify gate are unchanged.
BEGIN;

DROP FUNCTION IF EXISTS public.complete_connect_flow(uuid, boolean);

CREATE OR REPLACE FUNCTION public.complete_connect_flow(p_user_id uuid, p_seal_name boolean DEFAULT false)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_session connect.verification_sessions;
BEGIN
  -- Lock the verification_session row for this transaction
  SELECT * INTO v_session
  FROM connect.verification_sessions
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SESSION';
  END IF;

  IF v_session.step_reached != 'review' THEN
    RAISE EXCEPTION 'INCOMPLETE_SESSION';
  END IF;

  IF v_session.display_name_draft IS NULL
     OR v_session.legal_name_draft IS NULL
     OR v_session.region_draft IS NULL
     OR v_session.home_address_draft IS NULL
  THEN
    RAISE EXCEPTION 'MISSING_REQUIRED_FIELDS';
  END IF;

  -- Idempotency check
  IF EXISTS (SELECT 1 FROM connect.connected_profiles WHERE user_id = p_user_id) THEN
    RAISE EXCEPTION 'ALREADY_CONNECTED';
  END IF;

  -- Create connected_profiles record (home_address intentionally excluded, per 060).
  -- legal_name is NULLed when the caller has already sealed it into id_vault
  -- (p_seal_name = true); otherwise the draft is written as before.
  INSERT INTO connect.connected_profiles
    (user_id, display_name, legal_name, account_standing, verification_status, tolerance_rating, verified_region)
  VALUES
    (p_user_id, v_session.display_name_draft,
     CASE WHEN p_seal_name THEN NULL ELSE v_session.legal_name_draft END,
     'active', 'verified', 10.00, v_session.region_draft);

  -- Advance session to complete AND purge the transient identity drafts.
  -- v_session captured them above (SELECT INTO), so the INSERT still had them;
  -- nulling here is atomic with profile creation. This is the whole point of the
  -- migration.
  UPDATE connect.verification_sessions
  SET step_reached       = 'complete',
      legal_name_draft   = NULL,
      home_address_draft = NULL,
      updated_at         = now()
  WHERE user_id = p_user_id;

  -- Sync display_name to public.users
  UPDATE public.users
  SET display_name = v_session.display_name_draft, updated_at = now()
  WHERE id = p_user_id;

  RETURN jsonb_build_object(
    'connected', true,
    'verification_status', 'verified',
    'tier', 'connected'
  );
END;
$$;

-- Reproduce the restrictive ACL: service_role only (adminRpc calls this), never
-- PUBLIC. A fresh CREATE re-grants PUBLIC EXECUTE by default, exposing this
-- SECURITY DEFINER function to anon/authenticated via PostgREST.
REVOKE ALL ON FUNCTION public.complete_connect_flow(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_connect_flow(uuid, boolean) TO service_role;

-- Post-verify gate: the 2-arg overload exists with exactly one defaulted arg and
-- the correct arg names, the 1-arg overload is gone, and the ACL is service_role-only.
DO $$
DECLARE
  v_two_arg_oid regprocedure;
  v_pronargdefaults int;
  v_proargnames text[];
BEGIN
  v_two_arg_oid := to_regprocedure('public.complete_connect_flow(uuid, boolean)');
  IF v_two_arg_oid IS NULL THEN
    RAISE EXCEPTION 'public.complete_connect_flow(uuid, boolean) not found after migration';
  END IF;

  SELECT p.pronargdefaults, p.proargnames
    INTO v_pronargdefaults, v_proargnames
    FROM pg_proc p
    WHERE p.oid = v_two_arg_oid::oid;

  IF v_pronargdefaults <> 1 THEN
    RAISE EXCEPTION 'public.complete_connect_flow(uuid, boolean) must have exactly one defaulted arg, found %', v_pronargdefaults;
  END IF;

  IF v_proargnames <> ARRAY['p_user_id', 'p_seal_name'] THEN
    RAISE EXCEPTION 'public.complete_connect_flow(uuid, boolean) arg names must be (p_user_id, p_seal_name), found %', v_proargnames;
  END IF;

  IF to_regprocedure('public.complete_connect_flow(uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'public.complete_connect_flow(uuid) 1-arg overload still present after DROP';
  END IF;

  IF has_function_privilege('public', 'public.complete_connect_flow(uuid, boolean)', 'EXECUTE') THEN
    RAISE EXCEPTION 'complete_connect_flow must not be EXECUTE-able by PUBLIC';
  END IF;
  IF NOT has_function_privilege('service_role', 'public.complete_connect_flow(uuid, boolean)', 'EXECUTE') THEN
    RAISE EXCEPTION 'service_role must have EXECUTE on complete_connect_flow';
  END IF;
END $$;

COMMIT;
```

- [ ] **Step 3: Confirm the ONLY diff from CA_0120 is the UPDATE**

Run:
```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/stoic-kilby-30506c
diff <(sed -n '/^BEGIN;/,/^COMMIT;/p' backend/migrations/CA_0120_complete_connect_flow_seal_parity.sql) \
     <(sed -n '/^BEGIN;/,/^COMMIT;/p' backend/migrations/<CA_SLOT_1>_complete_connect_flow_null_drafts.sql)
```
Expected: the only differences are the two added draft-null lines and the reworded UPDATE comment. If anything else differs, you drifted from the live definition — fix it.

- [ ] **Step 4: Dry-run against prod, then confirm it reverted**

With `DATABASE_URL` pointed at prod (session pooler — see the WorkOS/IPv6 memory note), run the file body wrapped `BEGIN; … ROLLBACK;` (the file already opens `BEGIN;` — replace its trailing `COMMIT;` with `ROLLBACK;` for the dry-run only). Expected: the `DO $$ … $$` gate raises nothing and the transaction rolls back clean. Then confirm the live function is unchanged:
```bash
psql "$DATABASE_URL" -c "SELECT pg_get_functiondef('public.complete_connect_flow(uuid, boolean)'::regprocedure);" | grep -c 'home_address_draft = NULL'
```
Expected: `0` (rollback reverted; the live definition does NOT yet null drafts). If this session cannot reach prod, hand the dry-run to Chris and note it as pending — do not apply.

- [ ] **Step 5: Run the migration guards**

Run:
```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/stoic-kilby-30506c
git fetch origin
npm run check:migrations --prefix backend
npm run check:reservations --prefix backend
```
Expected: both pass — no duplicate number, and `<CA_SLOT_1>` is reserved by this author.

- [ ] **Step 6: Commit**

```bash
printf '%s\n' \
  'feat(id-vault): <CA_SLOT_1> — complete_connect_flow nulls verification_sessions drafts' \
  '' \
  'Adds legal_name_draft/home_address_draft = NULL to the UPDATE that advances the' \
  'session to complete, so the transient plaintext name + raw address no longer' \
  'persist after enrollment. Body otherwise byte-identical to CA_0120.' \
  '' \
  'Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>' > /tmp/msg2.txt
# substitute the real slot number into the message first, then:
git commit -F /tmp/msg2.txt -- backend/migrations/<CA_SLOT_1>_complete_connect_flow_null_drafts.sql
```

---

### Task 3: Retroactive purge of completed rows (migration #2)

**Files:**
- Create: `backend/migrations/<CA_SLOT_2>_purge_completed_verification_drafts.sql`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: a one-shot data migration that nulls `legal_name_draft` / `home_address_draft` on `connect.verification_sessions` rows where `step_reached = 'complete'`.

- [ ] **Step 1: Reserve the migration slot**

Run: `npm run steward --prefix backend -- slot CA --purpose "purge existing completed verification_sessions identity drafts"`
Use the returned number wherever `<CA_SLOT_2>` appears.

- [ ] **Step 2: Write the migration file**

Create `backend/migrations/<CA_SLOT_2>_purge_completed_verification_drafts.sql`:

```sql
-- <CA_SLOT_2> — Retroactive purge of identity drafts on COMPLETED verification sessions.
--
-- Companion to <CA_SLOT_1> (which stops NEW completions retaining drafts). This
-- clears the plaintext name + raw address already sitting on sessions that
-- completed before that fix. Scope is step_reached = 'complete' ONLY: in-progress
-- sessions (invite/profile/review) must keep their drafts so the member can resume.
--
-- Plain purge, no seal: Phase A has no production id_vault key, and those addresses
-- were never vaulted and are unrecoverable elsewhere (060 dropped the column; the
-- §4.7 name backfill does not cover addresses). This completes what
-- docs/PRIVACY-DATA-MODEL.md §5 always intended. Needs no key — safe to apply now.
-- Idempotent: a re-run matches zero rows.
BEGIN;

UPDATE connect.verification_sessions
SET legal_name_draft   = NULL,
    home_address_draft = NULL,
    updated_at         = now()
WHERE step_reached = 'complete'
  AND (legal_name_draft IS NOT NULL OR home_address_draft IS NOT NULL);

-- Post-verify gate: zero completed sessions may still carry an identity draft.
DO $$
DECLARE
  v_leftover int;
BEGIN
  SELECT count(*) INTO v_leftover
  FROM connect.verification_sessions
  WHERE step_reached = 'complete'
    AND (legal_name_draft IS NOT NULL OR home_address_draft IS NOT NULL);
  IF v_leftover <> 0 THEN
    RAISE EXCEPTION '<CA_SLOT_2>: % completed verification_sessions still carry identity drafts', v_leftover;
  END IF;
END $$;

COMMIT;
```

- [ ] **Step 3: Dry-run against prod, then confirm the scope**

With `DATABASE_URL` on prod, first count what will change and confirm in-progress rows are untouched:
```bash
psql "$DATABASE_URL" -c "SELECT step_reached, count(*) FILTER (WHERE legal_name_draft IS NOT NULL OR home_address_draft IS NOT NULL) AS with_drafts FROM connect.verification_sessions GROUP BY step_reached ORDER BY step_reached;"
```
Note the `complete` row's `with_drafts` count. Then run the file body with `COMMIT;` replaced by `ROLLBACK;`. Expected: the gate raises nothing, and after rollback the counts above are unchanged. If this session cannot reach prod, hand the dry-run to Chris and mark it pending.

- [ ] **Step 4: Run the migration guards**

Run:
```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/stoic-kilby-30506c
git fetch origin
npm run check:migrations --prefix backend
npm run check:reservations --prefix backend
```
Expected: both pass.

- [ ] **Step 5: Commit**

```bash
printf '%s\n' \
  'feat(id-vault): <CA_SLOT_2> — purge identity drafts on completed verification sessions' \
  '' \
  'Nulls legal_name_draft/home_address_draft on connect.verification_sessions rows' \
  'where step_reached = complete. In-progress sessions untouched. Plain purge (no' \
  'prod key in Phase A). Post-verify gate asserts zero completed rows retain drafts.' \
  '' \
  'Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>' > /tmp/msg3.txt
# substitute the real slot number into the message first, then:
git commit -F /tmp/msg3.txt -- backend/migrations/<CA_SLOT_2>_purge_completed_verification_drafts.sql
```

---

### Task 4: Record the disposition in the docs + final verification

**Files:**
- Modify: `docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md` (§4.4, the "Address change" block)
- Modify: `docs/PRIVACY-DATA-MODEL.md` (§5, the "Drop" list line about `verification_sessions`)

**Interfaces:**
- Consumes: the reserved slot numbers `<CA_SLOT_1>` and `<CA_SLOT_2>` from Tasks 2 and 3 (cited in the docs).

- [ ] **Step 1: Correct and extend vault spec §4.4**

In `docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md`, replace the **Address change** block (the two bullets beginning "The raw street address is present transiently…" and "New retention, made explicit:") with:

```markdown
**Address change** (`POST /set-location`, district re-derivation flow):
- The address arrives as a **request-body param** (the member re-enters it in the location step;
  `LocationStep.tsx`), not from a draft. Seal it into the vault (public key only, no ceremony), then
  re-derive districts via the existing path. The seal is non-fatal here — it must not block the
  district resolution the site needs to place the member.
- **New retention, made explicit:** today `set-location`'s address was discarded once districts
  resolved (migration 060). This build begins **retaining it, sealed**, because it is the break-glass
  payload named in data model §8a. The precise coordinates continue under the existing single key (D5).

**Enrollment drafts** (`connect.verification_sessions`, in-scope plaintext source — added 2026-09-17):
- `legal_name_draft` and `home_address_draft` hold the plaintext real name and raw street address
  during the multi-step flow and, before this fix, were **retained after completion** — readable by
  the BYPASSRLS `ev_api` role. This is the plaintext store the whole-branch review found; migration
  060's "home_address_draft … intentionally NOT removed here" is **superseded**.
- **Disposition (seal-then-null):** at `POST /complete`, `resolveCompleteConnectSeal` seals both drafts
  into the vault (fatal on failure when enabled) before `complete_connect_flow` nulls both drafts in the
  same atomic UPDATE (migration `<CA_SLOT_1>`). Existing completed rows are purged retroactively
  (migration `<CA_SLOT_2>`). The `signup_with_invite` path creates no drafts, so it needs no change.
  Design: `docs/superpowers/specs/2026-09-17-verification-sessions-draft-purge-design.md`.
```

- [ ] **Step 2: Update data-model §5**

In `docs/PRIVACY-DATA-MODEL.md`, under **Drop**, replace the line:

```markdown
- `verification_sessions.legal_name_draft`, `home_address_draft` — keep only as transient
  enrollment state, deleted the moment districts are resolved.
```

with:

```markdown
- `verification_sessions.legal_name_draft`, `home_address_draft` — transient enrollment state only,
  nulled at completion. At `POST /complete` the real name and raw address are sealed into `id_vault`
  (when enabled), then `complete_connect_flow` nulls both drafts atomically (migration `<CA_SLOT_1>`);
  rows completed before the fix are purged retroactively (migration `<CA_SLOT_2>`). Implemented
  2026-09-17 — the earlier "deleted the moment districts are resolved" intent went unbuilt until then.
```

(Substitute the real slot numbers for `<CA_SLOT_1>` / `<CA_SLOT_2>`.)

- [ ] **Step 3: Final verification — full guard suite green**

Run:
```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/stoic-kilby-30506c
git fetch origin
npm run typecheck --prefix backend \
  && npm run lint --prefix backend \
  && npm test --prefix backend -- src/routes/connect.idVault.test.ts \
  && npm run check:migrations --prefix backend \
  && npm run check:reservations --prefix backend
```
Expected: all pass.

- [ ] **Step 4: Commit**

```bash
printf '%s\n' \
  'docs(id-vault): record verification_sessions drafts as an in-scope plaintext source' \
  '' \
  'Vault spec §4.4 corrected (set-location seals a body-param address, not the' \
  'draft) and extended with the enrollment-draft disposition; data-model §5 cites' \
  'the implementing migrations.' \
  '' \
  'Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>' > /tmp/msg4.txt
git commit -F /tmp/msg4.txt -- docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md docs/PRIVACY-DATA-MODEL.md
```

---

## Notes for the executor

- **Do not apply migrations to prod.** This session writes and dry-runs them; Chris applies after review.
- **The two migrations must ship in the same PR as Task 1** — the app seal (Task 1) and the RPC null (Task 2) are the going-forward pair; splitting them across PRs would, with the vault on, let a draft be nulled before it is sealed. (With the vault off in prod today there is no live risk, but keep them together.)
- **If `getEnrollmentDrafts` gains a second caller later**, give it a dedicated DB-backed test; for now it follows the existing `getLegalNameDraft` pattern (mocked at the route boundary, no standalone unit test).
- **Slot numbers:** never edit `<CA_SLOT_1>` / `<CA_SLOT_2>` by counting. They come only from the steward in Task 2 Step 1 and Task 3 Step 1.
