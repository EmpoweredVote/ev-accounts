# Security handoff → Validation Quests team

**From:** Accounts/Essentials (Backend) · **Date:** 2026-06-17
**Project:** Supabase prod `E.V Backend` (ref `kxsdzaojfaibhuzmclfq`)
**Priority:** High — possible IDOR on `validation_quests.*` RPCs
**Owner action needed:** confirm how your app calls these functions, then apply a one-line fix (we can do it for you)

---

## TL;DR
While remediating a Supabase advisor "critical" finding (RLS disabled on public tables), we audited every `SECURITY DEFINER` function reachable through the PostgREST API. We found a systemic pattern where functions take a caller-supplied user id (`p_user_id`) but never check `auth.uid()`, so **any authenticated user can act as/on any other user by passing their UUID**.

We fixed the 34 functions Accounts/Essentials owns. **3 functions in the `validation_quests` schema are yours, and we did *not* touch them** — your app's call path is the deciding factor. This doc has everything you need to decide and fix.

> Note: `validation_quests.confirm_vq_stance` is sometimes assumed to be yours — it actually lives in the `connect` schema, is owned by Accounts (called via `POST /api/vq/confirm-stance`), and we've already locked it. The 3 below are the ones in *your* schema.

## Why this matters for `validation_quests`
All 3 `validation_quests` SECURITY DEFINER functions are executable by **`authenticated`** (not `anon`) via `POST /rest/v1/rpc/<fn>`, and none check `auth.uid()`. So any logged-in user can pass an arbitrary `p_user_id`:

| Function | anon | authenticated | checks `auth.uid()`? | risk if client-callable |
|---|:--:|:--:|:--:|---|
| `get_personalized_feed(uuid,text[],double precision,integer)` | ❌ | ✅ | ❌ | read another user's personalized feed / inputs |
| `get_onboarding_feed(uuid,text[],integer)` | ❌ | ✅ | ❌ | read another user's onboarding feed |
| `record_submission_counts(uuid,text)` | ❌ | ✅ | ❌ | alter another user's submission stats |

`record_submission_counts` is the most concerning (a write that mutates another user's counts).

## The one decision we need from you
**How does the Validation Quests app invoke these functions?**

- **Option A — through a trusted backend (service_role).** Your server verifies the user (JWT), then calls the RPC with the verified id via the `service_role` key. → The `authenticated` grant is just the Postgres default and should be revoked. `service_role` bypasses the grant, so nothing breaks.
- **Option B — directly from the client** (`supabase.rpc(...)` with anon key + user JWT). → Each function needs an in-body `auth.uid()` check; the grant must stay.

For reference, Accounts/Essentials verified Option A in our code (Express `adminRpc()` wraps every call with the service-role client), so revoking `authenticated` was safe for us.

## Remediation

### If Option A (server-side / service_role) — recommended if it matches
```sql
REVOKE EXECUTE ON FUNCTION validation_quests.get_personalized_feed(uuid,text[],double precision,integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION validation_quests.get_onboarding_feed(uuid,text[],integer)                    FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION validation_quests.record_submission_counts(uuid,text)                         FROM PUBLIC, anon, authenticated;
```

### If Option B (direct client calls)
Add an authorization check at the top of each function. **Do not** write `auth.uid() = p_user_id` blindly — if the function is *also* called by `service_role`, `auth.uid()` is `NULL` there and the guard breaks that path. Allow service_role, otherwise enforce identity:
```sql
-- inside each function, right after BEGIN:
IF auth.role() IN ('anon','authenticated') AND auth.uid() <> p_user_id THEN
  RAISE EXCEPTION 'NOT_AUTHORIZED' USING errcode = '42501';
END IF;
```
(For the read feeds, you may instead prefer to drop the `p_user_id` parameter entirely and derive it from `auth.uid()` for client calls.)

## Note: default-privilege safeguard (your schema was excluded)
We set `ALTER DEFAULT PRIVILEGES` on Accounts/Essentials schemas so new functions are `service_role`-only by default (no silent `anon`/`authenticated` exposure). **We deliberately left `validation_quests` untouched** — its current default still grants `anon`/`authenticated` EXECUTE on new functions, which means any function you add is auto-exposed. If you go with Option A, consider opting in:
```sql
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA validation_quests REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon, authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA validation_quests GRANT  EXECUTE ON FUNCTIONS TO service_role;
```

## How to verify after you apply
```sql
SELECT p.oid::regprocedure::text AS func,
       has_function_privilege('anon', p.oid, 'EXECUTE')          AS anon_exec,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') AS auth_exec,
       has_function_privilege('service_role', p.oid, 'EXECUTE')  AS service_exec
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'validation_quests' AND p.prosecdef
ORDER BY p.proname;
```

## Want us to do it?
If you confirm Option A, we'll apply the revoke migration for you and verify — just reply on the thread. If Option B, we can pair on the guard pattern. All changes are reversible (`GRANT EXECUTE … TO authenticated`).
