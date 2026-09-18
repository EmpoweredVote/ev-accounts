# Design — fail-safe legal-name guard on Empower promotion

**Status:** Design, awaiting review (2026-09-18, Chris Andrews).
**Context:** Readiness gap for the connected identity vault (decision 0022). See
`docs/superpowers/specs/2026-09-17-connected-identity-vault-design.md` §4.5.
**Repo:** ev-accounts (`backend/`).

---

## 1. The gap

Enabling the vault (Phase B) makes a new Connect member's `connect.connected_profiles.legal_name`
**NULL** — the real name is sealed into `id_vault` instead. Promotion to Empowered publishes a name.
Today the promotion path resolves the name as `confirmed ?? DB legal_name ?? ''` in three spots:

- `runPreflight` — `nameForSlug` (empowerService.ts:202) and `summary.legal_name` (:209)
- `confirmEmpowerment` — `p_legal_name` to `execute_empowerment` (:304)

So with the vault on and no confirmed name supplied, promotion **silently publishes an empty legal
name and a bare `-<suffix>` slug** to the public `empower.empowered_profiles`. This is a silent
data-integrity failure, and it is the concrete risk the "frontend confirmed-name" readiness item was
guarding against.

The member-facing promotion UI **does not exist yet** in either `app/` or `admin/` (no caller of
`/api/empower/preflight` or `/confirm`), so the readiness fix cannot be "add a field to the UI." The
fix is a **backend fail-safe**: refuse to promote without a usable name, rather than writing `''`.
When the promotion UI is later built, it supplies the confirmed name and this guard is its safety net.

Scope note: the backend already **accepts** a confirmed name on both routes (`ConfirmSchema.legal_name`,
`runPreflight(userId, confirmedLegalName?)`), landed in Phase A. This design only adds the refuse-when-empty
guard; it does not build a UI, change schema, or add an RPC.

---

## 2. Decisions

| # | Decision |
|---|---|
| G1 | **Refuse, don't default.** Promotion must never call `execute_empowerment` with an empty (or whitespace-only) `p_legal_name`. |
| G2 | **Two guard points** (defense-in-depth): a hard refuse in `confirmEmpowerment` (authoritative), and an `eligible:false` failure in `runPreflight` (upfront signal). |
| G3 | **Error code `NO_LEGAL_NAME`**, surfaced as HTTP **422** on `/confirm` and as a preflight `failures[]` entry (200) on `/preflight`. |
| G4 | **Whitespace-only counts as empty** — resolve with `.trim()`, consistent with the existing `confirmedLegalName?.trim()` normalization. |
| G5 | Guard covers **both** the fresh and the re-empowerment (demoted) preflight branches, so a returning member cannot blank an existing public name with `''`. |

---

## 3. Components

### 3.1 `confirmEmpowerment` — authoritative refuse (`backend/src/lib/empowerService.ts`)

After fetching `connectedProfile`, resolve the name once and refuse when blank, **before** the
`execute_empowerment` call:

```ts
const legalNameForRpc = confirmed ?? connectedProfile.legal_name ?? '';
if (!legalNameForRpc.trim()) {
  const err = new Error('A legal name is required to publish an Empowered profile.');
  (err as NodeJS.ErrnoException).code = 'NO_LEGAL_NAME';
  throw err;
}
```

Then pass `p_legal_name: legalNameForRpc` (guaranteed non-empty) instead of the current
`confirmed ?? connectedProfile.legal_name ?? ''`. `confirmed` is already the trimmed-non-empty value
or `undefined` (existing normalization at the top of the function). This is the true fail-safe: it
holds even if preflight was bypassed or a stale slug reservation exists — the RPC is never reached
with an empty name.

### 3.2 `runPreflight` — upfront structured failure (`backend/src/lib/empowerService.ts`)

After the `run_empower_preflight` RPC returns `eligible: true`, and **before** the fresh-vs-demoted
slug branch (i.e. right after `const connected = result.connected_profile!`), add:

```ts
const resolvedName = confirmed ?? connected.legal_name ?? '';
if (!resolvedName.trim()) {
  return {
    eligible: false,
    failures: [{ code: 'NO_LEGAL_NAME', message: 'Confirm your legal name to go public as an Empowered profile.' }],
    ...(result.demotion_context ? { demotion_context: result.demotion_context } : {}),
  };
}
```

The existing `nameForSlug` / `summary.legal_name` lines below are then reached only with a non-empty
name, so their `?? ''` tails become dead but are left as-is (harmless, and TS-friendly).

### 3.3 Route mapping (`backend/src/routes/empower.ts`)

In `POST /confirm`'s catch, map the new error before the generic 500 (mirroring `PREFLIGHT_EXPIRED`):

```ts
if (errMessage.includes('NO_LEGAL_NAME') || errCode === 'NO_LEGAL_NAME') {
  res.status(422).json({
    code: 'NO_LEGAL_NAME',
    message: 'A legal name is required to publish an Empowered profile.',
  });
  return;
}
```

`/preflight` needs no route change — it already serializes `runPreflight`'s `eligible:false` result at
200, so the `NO_LEGAL_NAME` failure surfaces in `failures[]`.

---

## 4. Data flow

- **Vault off / DB name present:** `resolvedName` non-empty → guard passes → unchanged behaviour.
- **Vault on, new member, no confirmed name:** preflight → `eligible:false NO_LEGAL_NAME` (200);
  confirm → **422 NO_LEGAL_NAME**, `execute_empowerment` never called. No empty profile published.
- **Confirmed name supplied:** flows through to the slug and the RPC exactly as today.

---

## 5. Testing (extend `backend/src/lib/empowerService.confirmName.test.ts` — existing mock pattern)

1. `confirmEmpowerment` throws `NO_LEGAL_NAME` and does **not** call `execute_empowerment` when the
   confirmed name is empty/absent and the DB `legal_name` is null.
2. `confirmEmpowerment` still passes the confirmed name to `execute_empowerment` when one is given
   (DB null) — regression guard on the happy path.
3. `runPreflight` returns `eligible:false` with a `NO_LEGAL_NAME` failure when confirmed empty + DB null.
4. `runPreflight` stays `eligible:true` (name flows to slug + summary) when a confirmed name is given
   with a null DB name — regression guard.
5. **Route:** `POST /api/empower/confirm` returns **422 `NO_LEGAL_NAME`** when the guard trips. Add a
   focused test; if no empower route test file exists, create `backend/src/routes/empower.test.ts`
   with the route's standard module-mock pattern (mock `empowerService`, assert the mapping).

---

## 6. Out of scope / Do NOT

- No promotion UI. No `app/` or `admin/` changes. (Tracked separately as a future feature.)
- No schema change, no new migration, no `execute_empowerment` RPC change.
- Do not trim/rewrite the stored name beyond the empty check — pass the resolved value through
  unchanged when non-empty (keeps the stored name and the preflight slug consistent).
- Do not touch the demotion path or the consent validation.
