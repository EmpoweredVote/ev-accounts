# Civic Spaces `/assign` 500 — display_name fallback design

- **Date:** 2026-09-13
- **Author:** Chris Andrews (candrews@empowered.vote)
- **Tracking:** ev-cto watchlist #70
- **Branch:** `fix/civic-spaces-display-name-fallback`

## Problem

`POST /api/civic-spaces/assign` returns 500 for a Connected user whose account has no
`display_name`. `getAccountMe` (`backend/src/lib/accountMeService.ts`) returns the top-level
`display_name` straight from `public.users.display_name` with no fallback. The folded
`sliceAssigner.upsertConnectedProfile` writes that value into
`civic_spaces.connected_profiles.display_name`, which is `NOT NULL`, so a null throws and the
request 500s. The frontend fires `/assign` and forgets, so the UI looks fine while assignment
silently fails.

## Findings (grounded against prod `kxsdzaojfaibhuzmclfq`, read-only)

1. **The affected users are not nameless.** Three of 26 users have a null base name in
   `public.users.display_name`, but each already chose a pseudonym stored in
   `connect.connected_profiles.display_name`: `chantrygilbert`, `Explorer`, `TESTING-Info-ev`.
   All three are Connected tier and have never completed `/assign` (no `civic_spaces` profile row).
2. **The invariant is "base name = Connected pseudonym."** For the other 9 Connected users, the
   base name equals the Connected pseudonym exactly. The three broken rows are simply the ones
   where the base name was left null (the WorkOS / older provisioning path) while the pseudonym
   was set.
3. **There is no real name for Inform/Connected.** `display_name` *is* the pseudonym for those
   tiers. `legal_name` exists only for Empowered candidates and is being phased out. So an
   auto-generated pseudonym is a valid identity for a no-name account.
4. **No uniqueness constraint on `display_name` anywhere** — only a non-unique trigram search
   index on `civic_spaces.connected_profiles.display_name`. A number suffix is therefore cosmetic
   for correctness, and uniqueness is a *new* guarantee, not an existing one.
5. **Nullability:** `civic_spaces.connected_profiles.display_name` is `NOT NULL` (the one that
   throws). `public.users.display_name` and `connect.connected_profiles.display_name` are nullable;
   the `connect` copy is non-null for all current Connected users.
6. **No duplicate handles today.** Across all 26 users, no two share a case-insensitive effective
   handle. The data is clean.

### Where the null comes from

- The `on_auth_user_created` trigger inserts `public.users(id)` with `display_name = NULL`.
- Direct `POST /api/auth/signup` requires `display_name` (Zod `min(1)`), so it is never null there.
- The **WorkOS hosted sign-up** path (`workosProvisionService`) only sets `display_name` when
  WorkOS returns a first/last name; a no-name sign-up leaves it null. This is the live source.

## Decisions (agreed with Chris Andrews, 2026-09-13)

- The three affected users show **their own chosen pseudonym** — backfill the base name from the
  Connected pseudonym. Do **not** overwrite a chosen name with a generated one.
- Auto-generated names: random `AdjectiveAnimal`, CamelCase format **`RapidWolverine`**, a number
  appended only when the name is already taken, and **stored**.
- Uniqueness: **best-effort on auto-names** — the generator checks the name is free and numbers it
  if not, so auto-generated names never collide at creation. No database-level unique rule; human
  duplicates stay possible exactly as they are today. (Enforced unique handles is a separate,
  feature-sized follow-up — out of scope.)
- The account contract must **never** return a null or empty `display_name`.

## Design

### 1. Shared helper — `backend/src/lib/displayName.ts`

- Curated, safe `ADJECTIVES` and `ANIMALS` word lists (CamelCase pieces, e.g. `Rapid`,
  `Wolverine`). Curated to avoid unfortunate combinations.
- `firstNonBlank(...values): string | undefined` — first value that is a non-whitespace string.
- `deterministicAutoName(seed: string): string` — hash `seed` (the user id) into one
  `AdjectiveAnimal`. Stable, synchronous, no DB. Used only by the read-time last-resort guard.
- `generateUniqueAutoName(db): Promise<string>` — random `AdjectiveAnimal`; check
  `public.users.display_name` case-insensitively; append `2`, `3`, … until free (bounded
  attempts); return it. Best-effort (documented TOCTOU note — negligible for no-name sign-ups).
  Used by the write path (provisioning).

Both generators share the word lists and the CamelCase format; they differ only in guarantee,
because the read path must stay synchronous and side-effect-free while the write path can check
the DB.

### 2. Account contract — `getAccountMe`

Resolve the top-level `display_name` through a fallback chain (the row already selects
`connected.display_name`):

```
display_name = firstNonBlank(user.display_name, connected?.display_name)
               ?? deterministicAutoName(user.id)
```

- Unchanged for the 9 working Connected users and every user who already has a base name.
- Fixes the 3 by surfacing their Connected pseudonym.
- The deterministic guard makes null/empty impossible for **every** consumer of `/api/account/me`
  (the fold's `fetchAccountData`, the `/me` route, VQ's in-process reads). It only ever shows for a
  user with no name anywhere — after backfill + sign-up enforcement, essentially never.

### 3. Second guard — `sliceAssigner.upsertConnectedProfile`

Coalesce inside the writer so a blank can never reach the `NOT NULL` column, even if a caller
passes one: `firstNonBlank(displayName) ?? deterministicAutoName(userId)`. Belt-and-braces behind
the contract fix.

### 4. Backfill migration (namespace `CA_`, slot from the steward allocator)

Guarded, idempotent `UPDATE` copying the Connected pseudonym into null/empty base names:

```sql
UPDATE public.users u
   SET display_name = btrim(cp.display_name), updated_at = now()
  FROM connect.connected_profiles cp
 WHERE cp.user_id = u.id
   AND (u.display_name IS NULL OR btrim(u.display_name) = '')
   AND cp.display_name IS NOT NULL AND btrim(cp.display_name) <> '';
```

Ends with a `DO $$ … $$` post-verify gate: no Connected user (a `connect.connected_profiles` row)
may have a null/empty base name afterward. A user with no pseudonym anywhere (none today) is left
null and covered by the runtime guard — SQL does not own the word lists, so it does not mint
auto-names. Dry-run against prod with `BEGIN; … ROLLBACK;` first.

### 5. Sign-up enforcement — `workosProvisionService.provisionWorkosUser`

In the `created` branch, when the first/last-name-derived display name is empty, assign
`generateUniqueAutoName(...)` and store it into `public.users.display_name` instead of leaving
null. A new WorkOS user therefore never reaches Connected tier nameless. Scope kept to this single
site; the `on_auth_user_created` trigger and `signUpWorkosFirst` are left alone (the runtime guard
covers the window before provisioning).

## Testing

- **`displayName.test.ts`** (new): `firstNonBlank`; `deterministicAutoName` stable + CamelCase
  `AdjectiveAnimal`; `generateUniqueAutoName` appends a number when the first pick is taken (mock db).
- **`accountMeService`**: base set → base wins; base null + pseudonym → pseudonym; both blank →
  deterministic non-null. (Match the existing test harness for this module.)
- **`sliceAssigner.test.ts`** (extend the ported suite): `upsertConnectedProfile` with a blank
  name inserts a non-null value.
- **Migration**: post-verify gate proves the three rows are fixed and none remain.
- **Live verification:** sign in as a no-name account, `POST /api/civic-spaces/assign`, confirm 200
  and `slice_members` rows written; re-check `postgres_logs` shows no new
  `null value in column "display_name"` errors.

## Out of scope (possible follow-up)

- **Enforced unique handles** — a case-insensitive unique rule on the handle plus "name taken" UX
  in sign-up, profile edit, and the invite flow. The data is clean, so it can be added later.
- Changing the `on_auth_user_created` trigger.
- Per-slice-scoped uniqueness (global uniqueness, when added, is strictly stronger).
