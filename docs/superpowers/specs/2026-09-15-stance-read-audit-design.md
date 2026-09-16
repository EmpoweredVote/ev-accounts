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
2. **No new reader appeared.** The set of roles holding `SELECT` on
   `inform.compass_responses` matches an expected allowlist — `information_schema.role_table_grants`.

Both fail loudly on the two ways this decays silently: someone turns logging off, or someone
grants a new role access to the table.

## 5. What this deliberately does not do

- **It does not prevent a staff read.** ADR 0007 §4 permits it; §5 asks only that it be
  visible. A design that blocked it would contradict the ADR it implements.
- **It does not cover data that leaves the database** — a restored backup, an export, a
  replica. Out of scope here, and worth naming so nobody mistakes this for complete.
- **It does not make the API's own reads auditable.** `profileService.ts:265` reads arbitrary
  users' stances by design; that path is governed by the visibility-gate test (#508), not by
  this.

## 6. Retention, which is not a technical question

Logs nobody reads are not an audit; they are a liability with a storage bill. Two things need
deciding, and neither is derivable from the code:

- **How long** stance-read logs are kept.
- **Who looks**, and on what cadence.

Recommend both be written into ADR 0007 §5 when this lands, because they are the difference
between an audit and the appearance of one.

## 7. Could not be verified from the repo — check before applying

1. **That no application path still connects as `postgres`.** `env.ts` exposes `DATABASE_URL`,
   `CIVIC_SPACES_DATABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`; the repo does not reveal which
   role each connection string resolves to in production. Stage 1's cheapness depends entirely
   on `postgres` being human-only — if an app path still uses it, Stage 1 becomes a firehose.
2. **Whether the Supabase dashboard's SQL editor runs as `postgres`** or as a separate
   platform role. If separate, that role needs the same treatment or the most likely human
   path stays unlogged.
3. **That Supabase surfaces role-level `log_statement` output**, and does not reset role
   settings across platform maintenance.
4. **Supabase's log retention window** — it bounds §6 regardless of what policy is chosen.

Items 1 and 2 are load bearing. If either is false, Stage 1 needs rethinking rather than
tuning, so check them first.
