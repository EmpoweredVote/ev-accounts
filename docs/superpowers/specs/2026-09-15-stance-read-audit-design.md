# Stance read audit — making a staff read distinguishable from an API read

- **Date:** 2026-09-15
- **From:** Civic Spaces, with Chris
- **Re:** ADR 0007 §5, which requires the audit but deliberately does not design it
- **Status:** proposed. Nothing here is built.
- **Tracking:** none yet — please assign.

> 🔴 Assembled from read-only passes over `C:\EV-Accounts` on 2026-09-15. §7 lists what could
> **not** be verified from the repo and must be checked live before any of this is applied.
> Treat the rest as a map to re-verify, not as gospel.

## 1. The requirement

ADR 0007 §5: *staff reads of stance data must be distinguishable, after the fact, from
ordinary API reads.* Not prevented — §4's exception permits them — **visible**.

## 2. Why this is not "log the admin endpoint"

There isn't one. Every reader of `inform.compass_responses` in the codebase is a product
path:

| Reader | What it reads |
|---|---|
| `routes/compass.ts:428` | the caller's **own** rows |
| `lib/profileService.ts:265` | an arbitrary `:userId`, gated on `visibility='public'` when `publicOnly` |
| `lib/candidateService.ts:145`, `:223` | candidate stances |

No admin route touches the table — `adminService.ts` never references it. So the staff
exposure is **not** an unlogged endpoint. It is that a human holding a database credential
can query the table directly and nothing records it.

**Therefore the design must distinguish connections, not routes.** Anything built at the
Express layer misses the actual path entirely, which is the trap this section exists to
prevent.

## 3. What connects today

| Identity | Credential | Used by | Bypasses RLS |
|---|---|---|---|
| `ev_api` | `DATABASE_URL` | `pg` Pool — `lib/db.ts`, trivia | yes |
| `service_role` | `SUPABASE_SERVICE_ROLE_KEY` | `supabaseAdmin` (supabase-js) | yes |
| `civic_spaces_app` | `CIVIC_SPACES_DATABASE_URL` | folded slice-assignment | yes, but only 3 tables (CA_0112) |
| `postgres` | dashboard / `psql` | **humans** | yes |

**The fact that makes this cheap: production stopped authenticating as `postgres` on
2026-09-09.** `postgres` is now, in practice, a human-only role. That means it can be logged
without logging the application's firehose — which is the whole difficulty in auditing reads
on a table the product legitimately reads constantly.

## 4. Design

### Stage 1 — per-role statement logging. This is the core of it.

> 🔴 **Amended 2026-09-17 after running the §7 checks.** Both checks passed, but measuring
> production showed **one `ALTER ROLE` is not enough**: five roles can read every stance and
> this logs one of them. The corrected scope is below; the original single statement is kept
> because it is still the first and most important line.

```sql
ALTER ROLE postgres SET log_statement = 'all';
```

Role-level `log_statement` is standard Postgres and applies from the role's next connection.
Statements run by `postgres` land in the Postgres logs; `ev_api`, `service_role` and
`civic_spaces_app` are untouched, so the application generates no new log volume.

That is §5 satisfied in one line: **a stance read by a human appears in the log, and the same
read by the API does not.** No application change, no schema change, nothing to roll back
beyond `RESET`.

State the limits honestly rather than overselling it:

- It logs **statements, not rows**. You learn that a query ran and what it asked for, not
  what came back.
- `postgres` is **shared**, so the log says "postgres", not *which person*. Stage 2 fixes
  that, and until it lands this is an activity log rather than an accountability one.
- Anyone who can set `log_statement` can unset it. Stage 4 is the answer.

#### Stage 1b — the other roles that can read every stance

Measured 2026-09-17. `rolbypassrls` does not grant table access, so the question is who holds
read access, **including by role membership** — which is where the surprise was.

| Role | Full read via | Logged by the statement above? |
|---|---|---|
| `ev_api` | direct grant + `rolbypassrls` | no — **the application, intentionally** |
| `service_role` | direct grant + `rolbypassrls`, assumed via `SET ROLE` from `authenticator` | no — **the application, intentionally** |
| `postgres` | direct grant, `pg_read_all_data`, `rolbypassrls` | **yes** |
| `cli_login_postgres` | **member of `postgres`** | 🔴 **no** |
| `supabase_read_only_user` | **member of `pg_read_all_data`** + `rolbypassrls` | 🔴 **no** |
| `supabase_etl_admin` | **member of `pg_read_all_data`** + `rolbypassrls` | 🔴 **no** |
| `supabase_admin` | superuser | 🔴 **no**, and the platform sets `log_statement=none` on it |

Three things follow, and none was visible from the repo:

1. **`pg_read_all_data` is the actual access path**, not a table grant. Neither
   `supabase_read_only_user` nor `supabase_etl_admin` appears in
   `information_schema.role_table_grants` for `inform.compass_responses`; both read it
   anyway through that predefined role. Any reasoning about who can read stances must follow
   memberships.
2. **Role settings do not inherit.** `rolconfig` applies to the session's *login* role, so
   `cli_login_postgres` stays unlogged even though it is a member of `postgres`. Add it
   explicitly.
3. **Some of these may not be ours to fix.** `postgres` has `CREATEROLE` but is **not**
   superuser and holds no admin option over the `supabase_*` roles, so `ALTER ROLE` on them
   will likely be refused. `supabase_admin` is superuser with `log_statement=none` set by the
   platform.

So the honest scope of Stage 1 is: **log `postgres` and `cli_login_postgres`; attempt
`supabase_read_only_user` and `supabase_etl_admin` and expect to be refused; accept that
`supabase_admin` is unloggable by us.** Whether the platform-managed roles are reachable by a
human at all is a Supabase access-control question, not a Postgres one — if nobody can obtain
those credentials, the residual gap is small. **That is worth confirming rather than
assuming**, because it is the difference between three unlogged paths and none.

### Stage 2 — named human roles, so the log says *who*

Stop sharing `postgres` for ad-hoc access. One login role per human who needs it, modelled
exactly on **CA_0112**: created in an idempotent migration **with no password in git**, the
founder setting each one live and distributing the connection string out of band.

Each such role gets `log_statement = 'all'` at creation, and only the grants it actually
needs — a read-only analyst role should hold `SELECT` and nothing else. CA_0112's reasoning
carries over unchanged: a leaked or buggy credential should be walled off by construction,
not by convention.

This is what turns Stage 1 from "someone queried stances" into an audit.

### Stage 3 — the structural version, deliberately deferred

Revoke direct `SELECT` on `inform.compass_responses` from every role but an owner, and expose
a `SECURITY DEFINER` reader that writes an audit row per call. The audit then lives **in the
database**, is row-level rather than statement-level, and cannot be skipped by anyone lacking
the owner role.

It is the right end state and it should not be built now:

- It touches `profileService`, `candidateService` and the compass routes.
- It interacts with `compass_responses_current` / `compass_responses_effective`, which are
  `security_invoker = on` deliberately (`CC_0046`) — a definer-function layer underneath
  invoker views needs care to avoid re-opening what that flag closed.
- The `pseudonym_id` work in `PRIVACY-DATA-MODEL.md` §4 rewrites these read paths anyway.
  Building the chokepoint first means building it twice.

Recommend revisiting it **with** that work, not before.

### Stage 4 — the guard, because a setting nobody checks is not a control

Two cheap assertions, run wherever the existing smoke scripts run:

1. **Logging is still on.** Every human role still has `log_statement = 'all'` —
   `pg_roles.rolconfig` answers this directly.
2. **No new reader appeared.** The set of roles that can read `inform.compass_responses`
   matches an expected allowlist.

   🔴 **Corrected 2026-09-17. The original version of this check was wrong**: it read
   `information_schema.role_table_grants` alone, which would have reported a clean result
   while `supabase_read_only_user` and `supabase_etl_admin` read every stance through
   `pg_read_all_data`. A grants-only guard misses membership-based access entirely — the
   exact failure it exists to catch.

   The check must union both paths: direct grants **and** membership in any role holding
   read access, `pg_read_all_data` included. `pg_auth_members` is the second half.

Both fail loudly on the two ways this decays silently: someone turns logging off, or someone
gains read access to the table — **by grant or by membership**.

## 5. What this deliberately does not do

- **It does not prevent a staff read.** ADR 0007 §4 permits it; §5 asks only that it be
  visible. A design that blocked it would contradict the ADR it implements.
- **It does not cover data that leaves the database** — a restored backup, an export, a
  replica. Out of scope here, and worth naming so nobody mistakes this for complete.
- **It does not make the API's own reads auditable.** `profileService.ts:265` reads arbitrary
  users' stances by design; that path is governed by the visibility-gate test (#508), not by
  this.

## 6. Retention — SETTLED 2026-09-16, in ADR 0007 §5a–5c

Logs nobody reads are not an audit; they are a liability with a storage bill. This section
originally left retention and review open. Both are now decided, and the policy lives in
**ADR 0007 §5a–5c** — not here. Summarised only so this design is readable on its own:

- **7 days** (§5a) — the **Supabase Pro platform ceiling**, not a chosen number. Longer
  retention needs Stage 3, a log drain, or a plan change; revisit it *with* Stage 3.
- **Weekly review by a named person** (§5b), forced by the 7-day window: a slower cadence
  means evidence expires unseen. Reviewer is **Chris until delegated in the ADR**.
- **Erasure pseudonymises rather than deletes** (§5c) — the record keeps *that* a read
  happened and *who* did it, losing only *whose* stances.

Two consequences land on whoever implements this:

1. **§5b expects an alert, not a checklist.** Expected volume is near zero, and a routine
   that is empty every week is one that stops being performed. Prefer a scheduled query that
   fires only on a non-empty result.
2. **§5c is a Stage 3 requirement.** Statement logs cannot be selectively pseudonymised, so
   at Stage 1 the 7-day expiry is the only erasure story. If Stage 3's in-database audit
   lands, it must support pseudonymising a subject id in place.

## 7. The pre-flight checks — RUN 2026-09-17

Both load-bearing checks were run against production (`kxsdzaojfaibhuzmclfq`) with read-only
metadata queries. **Both passed.** Running them also invalidated part of Stage 1, which is the
point of running checks rather than reasoning about them.

### 1. No application path connects as `postgres` — ✅ PASS

Live connections, `pg_stat_activity`:

| Role | `application_name` | What it is |
|---|---|---|
| `ev_api` | `Supavisor` | the app's `pg` pool |
| `authenticator` | `PostgREST 14.5` | PostgREST; `SET ROLE`s to `anon`/`authenticated`/`service_role` |
| `pgbouncer` | `Supavisor (auth_query)` | pooler internals |
| `postgres` | `mgmt-api` | **the management API — the session running this check** |
| `supabase_admin` | — / `postgres_exporter` | platform |

No application path uses `postgres`. Stage 1 is a scalpel, not a firehose.

⚠ **One correction to §3's table while here:** `service_role` is **not** a login role and does
not appear as a connection. PostgREST connects as `authenticator` and `SET ROLE`s per request.
That matters because `rolconfig` applies at login — a per-role `log_statement` on
`service_role` would not take effect. Irrelevant to this design (we do not log it), but it
would silently defeat any future attempt to.

### 2. The dashboard runs as `postgres` — ✅ PASS

`SELECT current_user` over the management API returns **`postgres`**, `application_name =
'mgmt-api'`, `is_superuser = off`. So logging `postgres` does cover the dashboard path, and
`application_name` additionally separates dashboard/API queries from a `psql` session.

### 3. and 4. — answered

- Supabase **Pro** plan: observability window is **7 days** (Team 28). This is what fixes
  retention in ADR 0007 §5a.
- `postgres` currently has **no** `rolconfig` at all, so Stage 1 adds a setting with nothing
  to conflict with. `supabase_admin`, `supabase_auth_admin` and `supabase_storage_admin`
  already carry `log_statement=none`, set by the platform.

### What the checks changed

**Stage 1 was insufficient as originally written.** See Stage 1b: five roles can read every
stance and the original single `ALTER ROLE` logs one. The access path for two of them is
`pg_read_all_data` membership rather than a table grant — invisible to the grants query this
spec originally proposed as the Stage 4 guard, which is now corrected.

### Still unverified

- **That Supabase does not reset `rolconfig` across platform maintenance.** Stage 4's first
  assertion is what would catch it, which is an argument for building Stage 4 alongside
  Stage 1 rather than after it.
- **Whether a human can obtain `supabase_read_only_user`, `supabase_etl_admin` or
  `supabase_admin` credentials at all.** This is a Supabase access-control question, and it
  decides whether the residual gap in Stage 1b is three real unlogged paths or none.
