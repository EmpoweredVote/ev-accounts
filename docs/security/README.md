# Security handoffs

Records from the June 2026 Supabase prod security audit (RLS disabled on public tables,
then an audit of every `SECURITY DEFINER` function reachable through PostgREST).

The audit found 44 functions that accept a caller-supplied user id (`p_user_id`, …) but
never check `auth.uid()`. Accounts/Essentials fixed its 34 directly. The other teams'
functions were handed off with the docs below.

| Doc | Team | Outcome (resolved on prod, 2026-06-17) |
|---|---|---|
| [listening-rpc-exposure-handoff.md](listening-rpc-exposure-handoff.md) | Listening / Debates | 7 functions revoked; `current_user_is_participant` kept (RLS dependency). App connects as `postgres` (owner), unaffected. |
| [validation-quests-rpc-exposure-handoff.md](validation-quests-rpc-exposure-handoff.md) | Validation Quests | Option A: 3 functions revoked, schema default-privilege safeguard added (`empowered-validation-quests` migration `20260617000001_revoke_vq_rpc_public_execute.sql`). |

The handoff docs are kept as written at the time; they read as open requests, but both are
closed. They were first proposed in the now-archived EV-Backend repo (EV-Backend#1).
