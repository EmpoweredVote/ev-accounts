# Steward — coordinating concurrent work in ev-accounts

**Status:** approved design, 2026-09-04
**Scope:** coordination between concurrent sessions, machines and people working in
`ev-accounts`. Two contended resources: **migration slot numbers** and **jurisdiction work
areas**. One new `steward` schema, one CLI, one session-start hook, and one new CI check.

> **As built (2026-09-04):** the last item is a *new* script and job, `check:reservations`, not a
> change to `check:migrations` — that one runs in the dependency-free `static guards` job and
> cannot open a database connection. `check:migrations` is untouched. See §5 and §6.
**Out of scope:** cross-repo coordination (Read & Rank and the other product repos stay
untouched), database-level write blocking, a web interface, and hierarchical scope containment
in the constraint. Onboarding Chris Andrews to Essentials data entry is separate work that this
design unblocks; it is not part of the build.

---

## 1. The problem, measured

Three people-shaped workstreams — Treasury Tracker, Compass, the Sign In pages — plus a growing
number of concurrent Claude sessions all write into this one repository and one production
database. Today they avoid each other by **social protocol**: Chris Andrews works in other
repos, and the second machine stays switched off. That protocol is the constraint this design
removes.

The target state is explicit: **Chris Cantrell and Chris Andrews both doing Essentials data
entry at the same time**, plus a laptop running long stance scans, without anyone stumbling.

### 1.1 Four collisions, only some of which share a fix

| | Collision | Crosses machines? | Fixed by | Observed |
| --- | --- | --- | --- | --- |
| **A** | Two sessions take the same migration slot | yes | the allocator, §3.1 | 2 near-misses, 2026-09-04 |
| **B** | A shared worktree's HEAD moves under a running session | no — local | rules, §9 | twice, 2026-09-04 |
| **C** | Two sessions write the same data in production | yes | claims, §3.2 | anticipated, not yet seen |
| **D** | Two sessions stage or commit each other's files | no — local | rules, §9 | recorded in prior sessions |

**The steward solves A and C** — the two that cross machines, and therefore the two that no
local convention can reach. **B and D are both machine-local**: they require a shared working
directory, so they are rules problems, not database problems. They are in scope for this design
only as §9.

### 1.2 Why the existing tooling cannot close the gap

`backend/scripts/check-migration-numbers.mjs` is thorough. It scans `refs/heads/` and
`refs/remotes/` and reports every slot claimed anywhere the repo can see — roughly 1,850 slots
across ~155 refs. Both figures move constantly: they read 1,843 / 155, then 1,849 / 157, then
1,851 / 154 over the few hours this document was drafted, as branches were pushed and deleted.
That volatility is the problem, not a rounding detail. Its own header documents the hole:

> Two authors both taking the next free number *before either pushes* is not observable from any
> repo state.

Per-author namespaces (`CC_`, `CA_`) were the mitigation. They fail exactly when **one author
runs several concurrent sessions**, which is now the normal case: on 2026-09-04 two of Chris
Cantrell's sessions came within one step of colliding twice in a single afternoon. The first
near-miss was caught because a `CC_wip_` draft was re-counted before renaming; the second
because the ceiling was re-counted immediately before taking a number, having already moved
from `CC_0065` to `CC_0067` unannounced.

**Being careful is not a fix.** The correct procedure was followed both times and the collision
was still only narrowly avoided. The state has to become observable.

### 1.3 The unit of contention is a jurisdiction

Two people filling out Essentials do not collide because they are both writing
`essentials.politicians`. They collide when they are both writing **Lomita**. Divide by
jurisdiction and the same tables are safe to share.

This matches existing practice: seed directories are per-jurisdiction
(`backend/data/seed-la-county-2026/`), and the Knight tracker is per-city. The steward makes an
existing habit explicit rather than imposing a new one.

---

## 2. Approach: a table in the production database

Three substrates were considered.

| | Claims live in | Atomic | New infrastructure | Survives DB outage |
| --- | --- | --- | --- | --- |
| **A — chosen** | a `steward` schema in Supabase | yes, natively | none | no |
| **B** | a file on an orphan `steward` git branch | yes — push rejection is the lock | none | partly |
| **C** | a small Render service | yes | a service to build and run | no |

**C was rejected** as the most work for no capability the others lack, plus a new component that
can fail at night.

**B is genuinely elegant** — git already solves distributed atomic writes, and a non-fast-forward
rejection *is* the "someone beat you to it" signal, with a free audit log. It was rejected on
ergonomics: every claim and release is a fetch-commit-push round trip, slow enough that people
will skip it, and it adds git operations to a workflow where git confusion is already collision
**B** and **D**.

**A was chosen** because:

1. Migration slots need a real allocator, and a `PRIMARY KEY` makes double-allocation
   *impossible* rather than unlikely.
2. Every session, every machine and CI already hold the credentials and connectivity.
3. Reading the board is a `SELECT`, cheap enough to run on every session start.
4. `btree_gist` is already installed, so overlapping claims can be excluded structurally using
   the same mechanism as `essentials.office_terms_no_overlap`.

Its cost is a production dependency in a development workflow. §7 contains the failure design
that makes that cost survivable.

---

## 3. Data model

New schema `steward`. Creating it is DDL, so it goes through the Supabase MCP or `psql` as
`postgres`; `ev_api` cannot create objects.

### 3.1 `steward.migration_slots` — the authoritative allocator

```sql
CREATE TABLE steward.migration_slots (
  namespace   text        NOT NULL,          -- 'CC', 'CA', '' for the plain numeric sequence
  num         integer     NOT NULL,
  state       text        NOT NULL DEFAULT 'reserved'
                          CHECK (state IN ('reserved','written','abandoned')),
  claimed_by  text        NOT NULL,          -- git config user.email
  machine     text,                          -- hostname; two of one author's boxes differ
  purpose     text        NOT NULL,
  branch      text,
  filename    text,                          -- set when the file appears on a ref
  claimed_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (namespace, num)
);
```

The primary key is the whole point: two sessions cannot both hold `('CC', 68)`.

**There is no `applied` state, deliberately.** This repo has no `schema_migrations` table and no
ordered runner — each migration is applied once, by hand. Nothing can observe that a migration
ran, so a field claiming to track it would always be stale.

Allocation goes through one function:

```sql
steward.claim_migration_slot(p_namespace text, p_who text, p_purpose text, p_branch text)
  RETURNS integer
```

It takes `pg_advisory_xact_lock(hashtext('steward:migration:' || p_namespace))`, reads
`max(num)` within the namespace, inserts, and returns. Concurrent callers serialise; the loser
waits and receives the next number.

**Seeding is mandatory and is the step most likely to be skipped.** The table must be populated
from a scan of every ref before the allocator is used — roughly 1,850 rows, `state='written'`,
`claimed_by='(historical)'`. Take the count at seed time; do not hard-code the figure above.
Without the seed, the first call returns `CC_0001`.

### 3.2 `steward.claims` — the jurisdiction notice board

```sql
CREATE TABLE steward.claims (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  scope        text        NOT NULL,     -- 'place:0642468' | 'county:06037' | 'state:CA'
  label        text,                     -- free text for humans: 'LA County headshots'
  holder       text        NOT NULL,
  machine      text        NOT NULL,
  session_ref  text,
  started_at   timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL DEFAULT now() + interval '8 hours',
  released_at  timestamptz,
  notes        text,
  CONSTRAINT claims_dates_sane CHECK (expires_at > started_at),
  EXCLUDE USING gist (
    scope WITH =,
    tstzrange(started_at, COALESCE(released_at, expires_at), '[)') WITH &&
  )
);
```

Claims are **leases**. The default eight-hour expiry means an abandoned session does not hold
Lomita forever. Releasing early is one command; taking over an expired claim is ordinary;
taking over a live one is possible and records who did it.

`scope` is a plain string and is not a foreign key, because `geo_id` is **not unique** —
5,790 distinct values across 7,684 `essentials.districts` rows as of 2026-09-04.

**Known limit, stated rather than hidden:** the exclusion constraint catches *exact* scope
collisions only. `county:06037` and `place:0642468` overlap in reality — Lomita sits inside Los
Angeles County — but the strings differ, so the database will not stop you. Containment is
handled as a **warning computed at claim time** from `geofence_boundaries` using `ST_Covers`,
the same query shape that derived the 88-city LA scope. Structural for exact matches, advisory
for hierarchical ones.

### 3.3 Grants

`ev_api` gets `SELECT`, `INSERT`, `UPDATE` on both tables and `EXECUTE` on the function, because
that is the credential CI and some sessions actually carry. This is coordination metadata, not
user data; the blast radius is small. Recorded here so it is an agreed decision rather than a
surprise found in a migration.

---

## 4. Interface

### 4.1 Reading is automatic

A `SessionStart` hook in `.claude/settings.json` runs `steward who` and prints the board before
anything else happens:

```
Steward · 2 active claims
  place:0642468  Lomita          chris@empowered.vote   desktop   expires 16:40
  state:TN       Nashville seed  candrews@…             mbp-2     expires 21:10
  CC slots reserved: CC_0069 (you, "lomita occupancy")
```

**This one change addresses most of the reported pain.** Andrews does not have to guess where
Cantrell is working, and Cantrell does not have to remember to announce it. The hook must time
out in two to three seconds and warn rather than block if the database is unreachable — a
session that hangs on start is worse than the collision it prevents.

### 4.2 Writing is a small CLI

Following the existing `npm run check:*` convention:

```
npm run steward -- who
npm run steward -- claim place:0642468 --label "Lomita occupancy"
npm run steward -- release place:0642468
npm run steward -- extend place:0642468 --hours 4
npm run steward -- slot CC --purpose "lomita occupancy"      → CC_0069
npm run steward -- sync
```

Identity is `git config user.email` plus hostname, so one author's desktop and laptop are
distinct holders. That matters: those two machines are as likely to collide with each other as
with a second person.

### 4.3 The slot command replaces a failing ritual

Current safe procedure: draft as `CC_wip_`, count across every remote ref, re-count immediately
before renaming, rename, apply, re-count after. It was followed correctly on 2026-09-04 and the
ceiling still moved twice mid-task.

With the allocator: ask for a number, receive `CC_0069`, name the file, done. Reserving a slot
never used is harmless — CLAUDE.md already states the number is a filename label for humans, not
a dense ordering — so an abandoned reservation is marked and left.

### 4.4 `--if-held` is where the laptop requirement lands

| Mode | Behaviour | Use |
| --- | --- | --- |
| `warn` | names the holder, proceeds | default, interactive |
| `fail` | stops | anything scripted that must not guess |
| `skip` | **moves to the next unclaimed jurisdiction** | the stance-scanning laptop |

`skip` is what turns "do not run the laptop while I am working" into "the laptop works around
me automatically."

---

## 5. Enforcement in CI

`check:migrations` gains a second question. Today it asks *does this slot collide with any
ref?* It will also ask *is this slot reserved, and by whom?*

| Situation | Result |
| --- | --- |
| Reserved by the committing author | pass |
| Reserved by someone else | **fail** — the collision, caught before merge |
| Not reserved at all | **fail above the namespace's grandfather ceiling**; pass at or below it |

⚠ **THE LAST ROW SAID "warn during rollout, fail after", AND THAT RAMP WAS NEVER BUILT.** Step 3
shipped the allocator without the warn-mode check, so nothing warned about anything. It went
straight to failing — safely, because the ramp turned out to be the wrong shape: a warning period
does not retire the hand-picked number on a branch cut last week. A per-namespace ceiling does,
because it asks *was the allocator available when this number was chosen?* rather than *what is
the date?* See "What step 5 actually had to resolve" in §6.

`check:migrations` is not the job that asks this. It runs in the dependency-free `static guards`
job — no `npm ci`, so no `pg` — and this question needs the database. It is a separate script and
its own CI job, `check:reservations`. **The existing ref scan is unchanged.**

**The existing ref scan stays.** It is an independent detector: it needs no network and it
catches anyone who bypassed the steward. The steward is the *allocator*; the scan remains the
*auditor*. Keeping both is what stops the new system becoming a single point of failure.

`steward sync` reconciles: reservations that now have a matching file on a ref become
`written`; reservations older than fourteen days with no file are flagged for cleanup.

---

## 6. Rollout

Ordered so value lands early and risk lands late. No step is a cutover.

1. ✅ **Schema, function, seed.** Invisible; no behaviour changes. `CC_0070`, seeded 1,852 rows.
2. ✅ **`steward who` and the SessionStart hook.** Read-only, immediately useful, cannot break
   anything. This step alone would have prevented most of 2026-09-04.
3. ✅ **`steward slot`.** The allocator became available. ⚠ The second half of this step — the
   warn-mode reservation check — was **never built**; see the note under step 5.
4. ✅ **`claim` / `release` for jurisdictions.** The habit forms while the net is soft. Shipped
   with `extend`, `--takeover` and `--if-held warn|fail|skip`.
5. ✅ **Flip `check:migrations` to fail** on unreserved slots. Landed as a separate job and
   script, `check:reservations`, because `check:migrations` runs in the dependency-free
   `static guards` job and this one needs `pg`.
6. ✅ **`worktree:` claims** (§9). It was still worth it — see below.

### What step 5 actually had to resolve

**There was no warn mode to flip.** Step 3 shipped the allocator and stopped; nothing in CI ever
asked whether a slot was reserved. So step 5 was not a switch — the check had to be written, and
the warn-then-fail ramp §5 relies on had never run.

**A calendar flip could not have been safe anyway.** The ramp exists because branches in flight
carry hand-picked numbers, and a branch cut last week still carries one today. Waiting does not
retire them.

So the ramp is **structural instead of temporal**: a per-namespace grandfather ceiling, set to
`max(num)` at the moment of the seed — `shared 1852 · CA 103 · CC 72`. At or below it, a slot
predates the allocator and passes; above it, the author had `steward slot` available. Measured
across every local and remote ref before flipping: **zero slots sat above those ceilings**, so
the flip failed nothing that already existed, and needed no warning period to establish that.

Three things surfaced only by building it:

- **The shared `NNNN_` sequence had no way to be allocated.** Its namespace is the empty string
  and `steward slot ""` failed argument validation, so enforcing it would have been a wall with
  no door. `slot shared` is the door. CLAUDE.md's "keep taking the next free number there
  exactly as before" is superseded — 1681 happened in that sequence.
- **Exact email equality would have shipped a false failure.** A reservation records
  `git config user.email`; the commit CI reads can carry GitHub's noreply form of the same
  person. 171 migration commits in this repo are authored by
  `34817036+chrisandrewsedu@users.noreply.github.com`. `holdersMatch` folds that one domain and
  nothing wider.
- **`test:unit` ran nothing under `scripts/lib/`.** vitest positionals are path substring
  filters, and the script read `src scripts/check-`. Every steward test merged in step 3 — the
  seeder, the slot parser, the ref scanner — had never once run in CI. Found by adding 18 tests
  and watching the count stay at 1,038. Widening it picked up 11 files and 198 tests (1,236 in 96
  files, from 1,038 in 85), all green — after excluding one that needs a live database and had
  never been in `test:unit` either.

### Step 6 was worth it, but not in the form it was written

§6 hedged: `worktree:` claims *"if still worth it by then"*. The evidence arrived unprompted —
while steps 4 and 5 were being built, `C:\EV-Accounts` changed branch again, from
`fix/federal-cohort-definition` to `feat/verify-politician-id-column`. That is collision **B**,
on the same day the rule against it was written into CLAUDE.md, for the fourth time. A rule that
is written down and still broken needs an observer.

**But a `claim worktree:<path>` you must remember to type would have been useless.** Whoever
forgets the §9 rule forgets the command too, and the design's own argument against social
protocol applies to its own commands: being careful is not a fix. So this resolves §10's third
open decision — *whether the SessionStart hook should also record the session's worktree and
branch* — as **yes**, and that is the only form shipped. `steward worktree` runs in the hook, in
0.4s, and nobody has to remember anything.

**The row is the mechanism; the WARNING is the product.** At session start, before anything is
touched:

```
🔴 HEAD MOVED in c:/ev-accounts-steward — it was on fix/federal-cohort-definition when a
   session last started here (2026-09-04 20:22Z), and is now on feat/steward-…
⚠  another session was last seen in c:/ev-accounts at 20:23Z — candrews@… on MBP-2
   (branch knight/ca-2). Do not checkout or switch here; make your own worktree.
```

#### It is a marker, not a lease, and saying otherwise would make the board lie

Nothing releases a worktree row when a terminal closes — there is no hook for that. So a live row
means **"a session started here at T"**, never "a session is running here now". Three consequences,
each deliberate:

- `who` lists these under `~` and prints **seen**, not "expires". An expiry would assert liveness
  the row cannot support.
- Registration **takes the marker over unconditionally**. This inverts the rule governing
  jurisdiction claims, where `--if-held warn` refuses to steal — because the fact is different.
  For a jurisdiction the holder's *work* is what is being protected; here the fact is *who most
  recently started*, so the newest writer is simply correct. What would otherwise be lost is
  reported instead of discarded.
- The 12-hour marker is another guess, and the trade-off runs both ways: too short and a session
  running all day drops off the board, so "nobody is there" becomes wrong; too long and last
  night's finished sessions look present. A working day spans one and clears overnight.

#### Path canonicalisation is the one thing that had to be right

The exclusion constraint compares scope **strings**. Two sessions in one directory registering
`worktree:C:/EV-Accounts` and `worktree:/c/ev-accounts` do not collide, do not warn, and the
feature does nothing while appearing to work. This machine spells its own paths three ways —
Git Bash `/c/ev-accounts`, PowerShell `C:\EV-Accounts`, `git rev-parse --show-toplevel`
`C:/EV-Accounts` — and all three reach the function.

⚠ **Case is folded only for a drive-letter path.** NTFS is case-insensitive, so on Windows two
spellings are one directory. POSIX paths are case-*sensitive*: folding `/home/Chris` and
`/home/chris` together would merge two real worktrees into one scope — the inverse error, and
just as silent.

### Containment is not computed with `ST_Covers`

§3.2 said the hierarchical warning would come from `geofence_boundaries` via `ST_Covers`. It
does not, and the substitution is the better answer rather than a shortcut: state⊃county and
state⊃place fall out of the FIPS prefix with no query at all, and county⊃place is exactly what
`essentials.geofence_child_county` already holds — the persisted result of that same derivation,
with `check:child-county` in CI keeping it from lagging its source. An ad-hoc query would create
a second answer to "which county is this city in", answerable differently from the one the rest
of the repo serves.

A place missing from that mapping reports **`unknown`**, never "unrelated". The matview leaves
`county_geo_id` NULL for children it could not place; answering "you are clear" for a city we
cannot locate is how a broken detector reads as a clean result.

### `--if-held warn` does not steal the lease

§4.4's table says warn "names the holder, proceeds", which reads two ways: proceed to claim, or
proceed with the work. Claiming means writing `released_at` onto somebody else's live row, and a
tool that does that by default makes the board lie about who holds what — the one thing it is
for. So warn names the holder and claims nothing; `--takeover` is the deliberate act, recorded
on the row it displaces.

Relatedly, `skip` is blocked **only by an exact claim**. Treating containment as blocking would
let one `state:CA` claim starve a queue of all 88 LA cities, and the caller would then report
"nothing to do" — indistinguishable from an empty work list.

---

## 7. Failure behaviour

The steward adds a production dependency to a development workflow. `DATABASE_URL` credentials
are known to break periodically — a Supabase password reset rotates `postgres` but not
`ev_api` — so the failure design matters more than usual.

| Component | On steward unreachable |
| --- | --- |
| `slot` | **fail closed.** Never invent a number it cannot verify. |
| `who`, `claim`, `release` | **fail open**, loudly. Worst case is today's behaviour. |
| SessionStart hook | warn and continue, after a 2–3s timeout |
| `check:migrations` in CI | **degrade** to the ref scan and pass with a warning |

CI degrading rather than blocking is deliberate: a credential rotation must not red-wall every
PR in the organisation.

---

## 8. What this does not solve

Stated so nobody expects otherwise.

- **Two people editing the same source file** still produces a merge conflict. Git handles that
  better than this would.
- **Anyone determined to bypass the steward can.** It is a coordination tool, not a permission
  system.
- **It adds a production dependency** to development. That is the price of choosing A over B.
- **Hierarchical scope overlap is a warning, not a constraint** (§3.2).

---

## 9. Worktree and HEAD rules

Collision **B** is machine-local, so it needs rules rather than a database. These were learned
on 2026-09-04, where `C:\EV-Accounts` changed branch three times under a running session.

1. **One session owns a worktree.** If you are going to commit, work in your own.
   `git worktree add` costs seconds and was the entire reason two concurrent sessions never
   touched on 2026-09-04.
2. **Never `checkout` or `switch` in a worktree you did not create.** If you need another
   branch, make another worktree.
3. **Always commit with an explicit pathspec** — `git commit -F msg -- <path>`. Staging
   carefully is not enough; the *other* session's `git add -A` is what catches you.
4. **Verify before deleting a worktree or branch:** untracked-and-ignored count is zero, the
   branch is fully merged into `origin/master`, the merged content is byte-identical, and the
   repo stash count is unchanged. Run a positive control on any detector that reports "nothing
   found" — on 2026-09-04 two such detectors were silently broken and only a control exposed
   them.

These belong in `CLAUDE.md`. The `worktree:` claim scope in §6 step 6 would make them visible
rather than merely written down, which is why it is sequenced last rather than never.

> **As built (2026-09-04):** step 6 shipped, and rule 2 above now has an observer. The
> SessionStart hook records the directory and branch, and reports **`🔴 HEAD MOVED in <path>`**
> or **`⚠ another session was last seen in <path>`** before anything is touched. It is a marker,
> not a lease — see §6. Rules 1, 3 and 4 remain rules; nothing watches them.

---

## 10. Open decisions

- **Lease duration — still a guess, now two of them.** Eight hours for a jurisdiction claim; 12
  for a worktree marker. A lease wants to be longer than a working session and shorter than a
  weekend; §6 states the marker's trade-off, which runs in both directions.
- ✅ **RESOLVED — the caller supplies the candidate list.** *Whether `--if-held=skip` needs a
  jurisdiction work queue.* It takes a list of scopes and returns the first one free, printing
  every one it passed over. No queue exists and none was needed.
- ✅ **RESOLVED, YES — and it is the only form step 6 shipped in.** *Whether the SessionStart
  hook should also record the session's worktree and branch.* A `worktree:` claim you must
  remember to type would be useless: whoever forgets the §9 rule forgets the command too. The
  hook records it in 0.4s and reports what moved. See "Step 6 was worth it, but not in the form
  it was written" in §6.
