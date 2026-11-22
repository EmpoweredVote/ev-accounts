# Custom lenses must be recoverable, and hard to destroy

**Date:** 2026-11-22
**Status:** proposed, reviewed
**Repo:** EV-Accounts (backend + migrations + CI). The CompassV2 change it implies
is already done — see §5.

---

## Intent, and the why

A user's custom lenses could be destroyed with no record and no way back. On
2026-11-22 that was measured against production: three lenses stored, a one-lens
`PUT /api/compass/my-lenses`, one survivor, HTTP 200, no warning. An empty
payload took all three.

The immediate hole is closed. ev-accounts#1584 made a deletion something the
caller must NAME in `delete_keys`; CompassV2#152 stopped the client rendering a
failed fetch as an empty set. Both are live, and the before/after was re-measured
against prod.

That guard stops the path we found. It does nothing about the next one, and it
leaves no way back when something does get through.

**Chris, 2026-11-22:** *"I'd like to know it happens so that if I need to
rollback on Github or launching a previous supabase memory, I know something
catastrophic has happened so I have time to fix it. Also, I don't want
catastrophic things to easily happen."*

The deeper reason is trust. These are early adopters who sat down and did real
work. Losing it silently is how one of them doesn't come back. We should be able
to tell any user exactly what happened to their data — and for lenses, we cannot.

### What that gap already cost

Auditing whether any non-Chris user had been burned, the only available evidence
was that `smor225500@aol.com`'s lens has `created_at = updated_at` to the
microsecond, 7m45s after signup, so no rewrite ever touched it. That is inference
from a timestamp, not a record. One scenario stays unprovable: a user whose
blanked client CREATED a lens, destroying earlier ones, leaves a survivor that
looks freshly inserted. With a change log it would have been a lookup.

---

## Goals

1. **Nothing is silently gone.** Every change to a user's lenses is recorded,
   deletions included, by a mechanism app code cannot bypass.
2. **Chris finds out within a day, and cannot miss it** by looking away.
3. **A single request cannot cause a catastrophe**, whatever the caller believes.
4. **Recovery is surgical** — restore one user's rows, never a whole-database
   rollback.

## Non-goals

- **The personal compass itself.** `compass_responses` has `deleted_at`, and
  `compass_change_history` holds 4,638 rows across all 14 users. Answers are
  soft-deleted and logged; lenses are neither.

  ⚠ **But that history has a gap of its own** — see "where the precedent stops".
  Closing it for answers is out of scope here and deserves its own work.
- **A pager.** Nightly is fast enough against a 7-day window (decided).
- **A generic audit table over every user-authored table.** The right eventual
  shape, deferred: answers are already partly covered, database size is a live
  problem in this repo *right now*, and one table does not justify the
  abstraction. Revisit when a third table needs it.
- **Undo in the UI.** Recovery here is an operator action.

## Anti-goals

Failure even if it technically ships:

- **A check that can be satisfied without being true.** `check-answer-delete-guards`
  exists because migration 1735 shipped a guard asserting the OPPOSITE property
  and passed green. A tripwire that goes green while lenses vanish is worse than
  none — it buys false confidence.
- **History the app writes.** If the service writes its own audit rows, a
  migration or a hand-run statement destroys data unrecorded. The trigger is the
  point.
- **Nightly noise.** A check that cries wolf gets ignored, and then the real
  event is ignored too. **This one nearly happened** — see §4.

---

## Constraints

### Recovery window

- **Supabase Pro. PITR is OFF — confirmed by Chris, 2026-11-22, deliberately: it
  is too expensive for this project.** The floor is **daily backups, 7-day
  retention**, and that is the real deadline.
- **Nightly detection fits, with ~6 days to spare.** Worst case ~24h from event
  to the 13:00 UTC run. If retention ever drops below ~2 days, revisit the
  immediate alarm from approach C.
- 🔴 **A restore is blunter than it sounds with no PITR.** You cannot land between
  snapshots, only on a daily boundary. Recovering one user's lenses by restoring
  would discard up to 24h of every other user's answers, with no way to take
  less. **This is the strongest argument for in-table history:** not a nicety on
  top of the backup, but the only surgical option that exists.
- ⚠ **What history does NOT protect against.** It lives in the same database, so
  it is no defence against the database being lost or corrupted. That is the
  backup's job, and it remains the floor. Different failures; neither replaces
  the other.

### Privilege model — measured against prod, 2026-11-22

🔴 **The first draft of this document got this wrong in a way that would have
broken production, twice. Both facts below are verified, not assumed.**

| fact | value |
|---|---|
| `inform.compass_user_lenses` ACL | `postgres=arwdDxtm/postgres \| ev_api=arwd/postgres` |
| `inform.compass_change_history` ACL | `… \| anon=r \| authenticated=r \| service_role=arwdDxtm \| ev_api=arwd` |
| `ev_api` `rolbypassrls` | **true** |
| `supabase_auth_admin` superuser / bypassrls / USAGE on `inform` | **false / false / false** |

Consequences the design must respect:

1. **`compass_user_lenses` is NOT grantless.** `ev_api` holds `arwd`, which is
   how the API reads it at all; RLS-on-with-no-policies does not stop `ev_api`
   because it bypasses RLS. The service file's own comment — *"RLS-on with no
   policies and no grants"* — **is wrong**, and this document inherited the error
   from it. **The builder must not `REVOKE` anything from `ev_api`**; doing so
   makes every lens save 500. `ALTER DEFAULT PRIVILEGES IN SCHEMA inform` already
   grants `arwd` to `ev_api` on new tables created by `postgres`, so the history
   table gets the right grant by doing nothing. *(Fixing the stale comment is a
   one-line change this work should carry.)*
2. **The trigger MUST be `SECURITY DEFINER`.** `auth.users → public.users →
   compass_user_lenses` cascades on account deletion, and that cascade runs
   inside GoTrue as `supabase_auth_admin`. Foreign-key RI triggers bypass
   permission checks; **a user-defined trigger does not** — it runs as the
   invoking role. `supabase_auth_admin` cannot even `USAGE` the `inform` schema,
   so an `INVOKER` trigger would raise `permission denied` and **abort the whole
   account deletion.** The function is `SECURITY DEFINER SET search_path TO ''`,
   owned by `postgres`, following the `CC_0046` convention.

### Other

- **`owner_id` is `references public.users(id) on delete cascade`.** Account
  deletion hard-deletes lenses. Legitimate; must be recorded, not blocked.
- **`key` is globally unique**, so a lens key can become a share link unchanged.
- **Migration numbers come from the steward** (`check:reservations`), and the
  compass work uses the **`CC_` namespace** (1849 is bare-numbered; the sequences
  are per-namespace).
- **The database is over its size limit right now** — see
  `ACCOUNTS-REPLY-database-size-overage-2026-11-18.md`, with a `contributions`
  rebuild in flight. Write volume is a real constraint here, not a theoretical
  one (§2).

---

## Approaches

Chris picked **A, plus the cap from C**, on 2026-11-22.

### A — Soft delete plus trigger-written history, and a nightly tripwire *(chosen)*

- **For:** recovery becomes surgical; the nightly schedule exists; the trigger
  cannot be bypassed by app code, a migration run as `postgres`, or the SQL
  editor.
- **Against:** up to 24h to notice; it is a **new** mechanism here, not a proven
  one (below).

#### Where the precedent stops

🔴 **Checked against the live database.** `inform.compass_responses` carries three
triggers — `compass_responses_assign_season`,
`compass_responses_closed_season_immutable`, `compass_responses_stamp_revision` —
and **none writes history.** `compass_change_history` is populated by explicit
`INSERT`s inside `SECURITY DEFINER` RPCs (`upsert_compass_answer`,
`promote_compass_import_draft`, migration 025). That is exactly the "history the
app writes" shape listed above as an anti-goal.

Two further ways it does not support what this design wants:

- `compass_change_history.new_value` is **`NOT NULL`** — it structurally cannot
  record a deletion. Goal 1's "deletions included" is not something it does.
- `compass_change_history.user_id` is `ON DELETE CASCADE` — that history **is**
  destroyed with its subject. §2 below deliberately does the opposite.

So the trigger here is **stronger than what answers have**, and must be justified
on its own merits rather than as an extension. It is: the failure we are
defending against is a write path nobody anticipated, and only the table itself
sees all of them. The real precedent in this codebase is
`closed_season_is_immutable` — a trigger enforcing a property no caller may
violate. That is a precedent for *enforcement*, not for logging.

### B — One generic audit table over every user-authored table

**For:** solves the class. **Against:** materially bigger; overlaps
`compass_change_history`; database size is a live problem. **Deferred.**

### C — Prevention only: hard caps and an immediate alarm

**For:** no lag. **Against:** recovers nothing already lost; misses a slow bleed.
**The cap is taken from here. The alarm is not.**

---

## The design

### 1. Soft delete

Add `deleted_at timestamptz` to `inform.compass_user_lenses`.
`replaceUserLenses` sets `deleted_at = now()` instead of issuing a `DELETE`.

Reads in `compassUserLensService` gain `AND deleted_at IS NULL` — **with one
exception, and the exception is load-bearing:**

🔴 **`findKeysOwnedByOthers` must still see soft-deleted rows.** It is a read, so
a builder applying the rule mechanically would filter it and silently remove the
protection §1 exists to provide. Because soft-deleted rows stay under the global
unique index, the upsert's `DO UPDATE … WHERE owner_id = $1` predicate fails
against *another owner's soft-deleted row* — and the service's existing comment
says what happens next: *"updates nothing AND inserts nothing, with no error and
row_count = 0 … the caller gets 200 and a lens list quietly missing a lens, which
reads as data loss."* **This exception needs its own test.**

⚠ **The `SELECT key … FOR UPDATE` read added by #1584 also needs the filter.**
Without it, a user's own soft-deleted keys count as "stored", so every later PUT
409s forever on lenses they already deleted. Note that with the filter
`FOR UPDATE` no longer locks those rows, slightly weakening #1584's concurrency
comment — which should be updated rather than left to contradict the code.

**The unique index stays as it is**, covering soft-deleted rows. A share link
that pointed at a deleted lens must never resolve to a different user's lens.
*(The rejected alternative — a partial index on live rows — also could not be
inferred by `ON CONFLICT (key)` without naming the predicate.)*

**Re-creating a key you own resurrects it:** the conflict path also sets
`deleted_at = NULL`. Without this, deleting and remaking the same key is a silent
no-op — the shape of the bug this document exists about.

- A resurrection is recorded as a distinct **`restore`** op, not an `update`.
- `created_at` is still preserved on resurrection, matching the existing upsert.
  A key deleted in March and remade in November displays as a March lens. Noted,
  accepted.

### 2. Trigger-written history

`inform.compass_user_lens_history`:

| column | type | note |
|---|---|---|
| `id` | uuid pk | |
| `owner_id` | uuid not null | 🔴 **no FK, no cascade** |
| `lens_key` | text not null | |
| `op` | text not null | `insert` \| `update` \| `restore` \| `soft_delete` \| `hard_delete` |
| `before` | jsonb | whole row; null on insert |
| `after` | jsonb | whole row; null on hard delete |
| `created_at` | timestamptz not null default now() | |

- **`AFTER INSERT OR UPDATE OR DELETE FOR EACH ROW`**, `SECURITY DEFINER SET
  search_path TO ''`, owned by `postgres` — see the privilege model above. This
  is not optional and is not a builder's detail.
- **`soft_delete`** is derived as `OLD.deleted_at IS NULL AND NEW.deleted_at IS
  NOT NULL`; **`restore`** is the reverse; anything else on an UPDATE is
  `update`. `TG_OP = 'DELETE'` is `hard_delete`.
- 🔴 **`owner_id` must NOT cascade.** The parent cascades, so a deleted user's
  lenses are hard-deleted — and if history cascaded too, the record of that
  deletion would be destroyed by the same statement. History outliving its
  subject is the point, and is a deliberate departure from
  `compass_change_history`.
- **Grants: do nothing.** Default privileges give `ev_api=arwd` automatically.
  Do not `REVOKE`. RLS on, no policies — which, with `ev_api` bypassing RLS,
  means the API can write it and PostgREST cannot see it. *(Unlike
  `compass_change_history`, this table gets no `anon`/`authenticated` read.)*
- **`WHEN (OLD.* IS DISTINCT FROM NEW.*)`** on the UPDATE trigger, so a no-op
  save writes nothing. This matters: the client PUTs the **whole set** on every
  save, so without it one rename writes a history row per lens, each carrying two
  full JSONB copies. In a database already over its size limit, that is the
  difference between negligible and not.
- **Also an `AFTER TRUNCATE` statement-level trigger that raises.** Row triggers
  do not fire on `TRUNCATE`, and that is a one-line hole to close. `ALTER TABLE …
  DISABLE TRIGGER` remains available to `postgres` and is not defended against —
  so goal 1 says "app code cannot bypass", not "nothing can".
- **Retention unbounded for now**, with the `WHEN` clause keeping volume honest.
  Revisit with B.

### 3. The cap

A single `PUT /api/compass/my-lenses` may delete **at most one** lens.

- **Enforced in the route, not in zod.** `delete_keys` keeps `.max(20)` as the
  payload guard; the route returns a named code in the existing family
  (`DUPLICATE_LENS_KEYS`, `CONTRADICTORY_LENS_KEYS`,
  `LENS_DELETE_NOT_ACKNOWLEDGED`). A zod `.max(1)` would surface as a generic
  `VALIDATION_ERROR` and put two limits on one rule.
- **Why one.** `deleteActiveLens` is the only caller in the product that deletes,
  and it names exactly one key; guest promotion never deletes. So a two-deletion
  request cannot be produced by the application as it exists, which makes 1 the
  honest blast radius and "delete everything in one shot" structurally impossible
  rather than merely guarded. A named constant, not a literal.

*(Proposed as my call, **confirmed by Chris**: "cap of one is right". If bulk
delete is ever a feature, this is the line that changes, and changing it is the
decision — not an implementation detail of that feature.)*

### 4. The nightly tripwire

`backend/scripts/check-lens-durability.mjs`, wired as `check:lens-durability`.

**It fails when, in the last 24 hours:**

1. **any single owner had more than one lens removed** (soft or hard); or
2. **any `hard_delete` appears whose owner's account still exists** — the only
   legitimate hard delete is the account-deletion cascade, so any other is a
   write path that bypassed the service, which is the event this whole document
   is about.

Each failure names the owner id, the keys and the timestamps, so *what did we
lose and whose was it* is answered by the failure message, not a follow-up query.

🔴 **A third condition was proposed and dropped, and why matters.** The draft also
fired when an owner "went from having lenses to having none". Measured against
prod: there are **2 lenses across 2 owners — each holds exactly one.** That
condition would therefore have fired on the only deletion either of them can
legitimately perform. It would have shipped as a tripwire that goes red on
ordinary use — the "nightly noise" anti-goal, violated by this document's own
numbers. *(Chris's call: drop it. Every such event is still recorded in history;
we lose the alarm, not the evidence.)*

⚠ **Condition 1 must not double-count.** A `soft_delete` followed by the cascade
`hard_delete` of the same row is two history rows for one lens. Count distinct
`lens_key`, and exclude owners whose account no longer exists — that is
condition 2's business.

⚠ **Neither condition is computable from history alone** — condition 2 joins
`public.users`. History is the source of *events*; the join is fine. What it must
not do is consult a committed baseline file, which would be a second source of
truth able to disagree with the first.

**Going red stays red until acknowledged.** *(Chris's call.)* A small
`inform.compass_lens_alert_acks` table records which history rows have been
looked at; the check ignores acknowledged ones and fails on the rest, every
night, until someone acks. A 24h self-healing window was rejected precisely
because a destruction could age out unseen while the restore window was still
open — which defeats the stated purpose.

**Operational details:**
- **No `DATABASE_URL` → skip, exit 0**, matching `check-migration-reservations`.
  Forks get no secrets and must not hit a red wall.
- **It is its own CI job**, gated on
  `github.event_name == 'schedule' || workflow_dispatch`, like every other
  scheduled check — *there is no shared nightly job to add it to.* `ci.yml`'s
  header requires a cost statement before adding a job; this would be roughly the
  25th, and the plan must include that statement.
- Schedule-only jobs are not in `ci-ok`'s `needs`, so a red nightly blocks no
  merges. Consistent with the "no pager" non-goal.

🔴 **The check must be proven able to fail**, per the anti-goal: destroy a
throwaway row deliberately and watch it go red, then ack and watch it go green.
Observing it green proves nothing.

### 5. The smoke suite — already done

`clearServerLenses` PUT `{ lenses: [] }` and threw on non-ok, so it began failing
the moment #1584 deployed. Fixed in **CompassV2#153**: it now deletes one lens
per request, naming each key — the shape that also survives the cap in §3.

---

## What is left to the builder

- The migration slot — reserve via the steward, `CC_` namespace.
- Whether `before`/`after` use `to_jsonb(OLD)` directly or a column whitelist.
- The ack mechanism's ergonomics (a `--ack` flag on the script versus a
  hand-inserted row), following whatever neighbouring scripts do.
- Whether the nightly writes a summary artifact, following the other nightlies.
- Test shape, following `compassUserLensService.test.ts`.

## Verification

Re-runnable against the throwaway account `compass-smoke@empowered.vote` —
**never a real account** (`scratchpad/lens-measure/`). After this lands:

- delete a lens; confirm the row survives with `deleted_at` set and a
  `soft_delete` history row exists;
- confirm a two-deletion request is refused with the named code;
- confirm a no-op save writes **no** history row (the `WHEN` clause);
- confirm resurrecting a deleted key produces a `restore` op and keeps
  `created_at`;
- confirm a second owner cannot claim a soft-deleted key (the
  `findKeysOwnedByOthers` exception);
- **confirm account deletion still works** — the `SECURITY DEFINER` check, and
  the one that would otherwise have been found in production;
- confirm the nightly goes **red** for a deliberate destruction, stays red the
  next run, and goes green only after an ack.
