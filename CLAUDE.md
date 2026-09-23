# ev-accounts — working notes

Conventions that are not obvious from the code and that are expensive to get wrong. Keep this short;
if something needs a page, put it in `docs/` or an ADR and link it here.

## How to report

When working on business tasks, only report to me in **ASD-STE100 Simplified Technical
English**. Write clearly and prioritize readability over strict adherence to STE.

In practice: short sentences, one idea per sentence. Active voice. Approved-sense
vocabulary, one meaning per word. No idioms, no metaphors, no filler. Where plain
readability and a strict STE rule disagree, readability wins.

This controls chat replies only. It does not control the style of the files you write —
docs, code comments, commit messages, and page copy follow this repo's own conventions.

## Officeholder occupancy — read this before seeding anyone

**`essentials.offices` is a SEAT** — district + chamber + title. It holds **no occupant**.
`offices.politician_id` was **dropped** (ADR 0002 phase 5, migration 1463). Occupancy is a dated row
in **`essentials.office_terms`**, resolved at read time.

Full rationale: [`docs/adr/0002-temporal-officeholder-terms.md`](docs/adr/0002-temporal-officeholder-terms.md).

### Reading

Join the view in whichever direction you need — but 🔴 **the two directions do NOT carry the same
guarantee**, and this line used to say they did:

```sql
JOIN essentials.office_current_holder och ON och.office_id     = o.id   -- who holds this seat
JOIN essentials.office_current_holder och ON och.politician_id = p.id   -- what seat does this person hold
```

The view is **exactly one row per office** (guaranteed by `office_terms`' exclusion constraint), so
the **first** join cannot fan a result set out. **The second one can.** That constraint forbids two
people on one office; it **cannot see one person on two** — and people do hold two, whether a
duplicate row from a discovery sweep or a genuine second seat. So a politician-rooted join returns
one row **per office that person holds**, and needs a `DISTINCT ON (p.id)` or a deliberately chosen
office.

⚠ **This is not hypothetical.** `GET /api/essentials/politicians?q=` carried the old claim as a
comment and no `DISTINCT`, and returned **two** Aaron Freemans until `CC_0103` deleted the duplicate
office (2026-09-12). `getPoliticianById` has the same shape and takes `rows[0]` with no `ORDER BY`,
so it reports an arbitrary one of the two as the person's office.

For history, `essentials.office_holders_as_of(date)` answers "who represented me in 2019". It **skips
terms whose `source` carries `| unverified <slot>`** (CA_0171): placeholder terms an audit kept because it
could not disprove them (CA_0156, CA_0159), all with `term_start` NULL — unguarded, they answered every
past date. Read `office_terms` directly to see them. An audit that keeps an unverifiable term should use the
same tag.

**Never cache "current" in a column.** No trigger fires merely because the calendar advanced — that
is the whole reason this model exists.

### Writing

An office with **no `office_terms` row is invisible**: no holder, so the official never appears in
Essentials, stance research, coverage or campaign finance — and **nothing errors**. This is the one
failure mode CI cannot catch. Watch `essentials.offices_missing_terms` (baseline at migration 1464:
857 rows, 158 legitimately flagged `is_vacant`, 699 unknown-occupancy predating the backfill — treat
a count above 699 unflagged as new drift).

Use the helpers rather than hand-rolling the two-step:

```sql
-- Seat someone from a date. Closes the predecessor's term the day before. Idempotent.
SELECT essentials.seat_officeholder(office_id, politician_id, term_start, source);

-- Close a term with no successor, as of the first VACANT day. Syncs is_vacant/vacant_since.
SELECT essentials.vacate_office(office_id, first_vacant_day, source);
```

Seating is a **two-step by design**: an open-ended term (`term_end IS NULL`) is an *infinite* range
that overlaps every future span, so the predecessor must be closed before a successor can be
inserted. That is a feature — it makes "when did the last term end?" a required answer instead of a
silent overwrite.

Honesty rules that the schema enforces:

- **Don't invent dates.** If a source says only "2017", pass `2017-01-01` with
  `start_precision => 'year'`. If the start is genuinely unknown, write an open-ended term with
  `start_precision => 'unknown'` (what the phase-2 backfill did) — not a guess.
- **A vacancy is a fact about a span**, so `office_terms.politician_id` is nullable. But do **not**
  write a vacancy span whose start date you don't know — set `offices.is_vacant` and leave the span
  unwritten.
- **`politicians.valid_from` / `valid_to` are DEPRECATED** — wrong entity (dates belong to a tenure,
  and people hold two offices). Don't read them in new code. `politicians.office_id` is a legacy
  point-in-time snapshot with the same flaw; prefer the view.

### The `is_vacant` trap

If a query filters `AND o.is_vacant = false`, that condition must constrain the **match**, not a
downstream join. Some offices carry a current term while still flagged `is_vacant`; filtering after
the match emits a **spurious all-NULL office row** for their holder. Use a derived join — see
`backend/src/lib/campaignFinanceSearchService.ts` for the worked example.

### Guard

```bash
npm run check:occupancy --prefix backend
```

Runs in CI on PRs. Catches references to the dropped column; it cannot catch a missing term row.

## Migrations

- Live in `backend/migrations/`, numbered `NNNN_snake_case.sql`.
- 🟢 **ASK THE ALLOCATOR FOR THE NUMBER. DO NOT COUNT.**

  ```bash
  npm run steward --prefix backend -- slot CC --purpose "what this migration does"
  #  -> CC_0073
  ```

  It reserves the slot atomically in `steward.migration_slots`, whose `PRIMARY KEY
  (namespace, num)` makes double allocation *impossible*; callers serialise on an advisory
  lock. Proven on prod: two simultaneous calls returned `CC_0071` and `CC_0072`.
  **Name the file that number straight away.** The old `CC_wip_` draft-then-rename-then-recount
  dance existed only because counting was unreliable. It is no longer needed.
- 🔴 **COUNTING BY HAND IS NOT A FALLBACK — IT IS THE BUG.** A number another session has
  *decided* to use is invisible until it pushes, so no scan can ever see it. That is the 1681
  collision, and on 2026-09-04 two of Cantrell's sessions came within one step of it **twice**
  with the correct procedure followed both times. If the allocator is unreachable, **stop and
  fix that** rather than reading the max.
  Design: [`docs/superpowers/specs/2026-09-04-steward-coordination-design.md`](docs/superpowers/specs/2026-09-04-steward-coordination-design.md).
- 🔴 **CI NOW FAILS A MIGRATION WHOSE SLOT NOBODY RESERVED** — job "migration reservations",
  `npm run check:reservations --prefix backend`. Every migration file added on a branch must sit
  in a slot reserved by *its own author*; reserved by someone else is the collision, caught
  before merge.
  - **This applies to the shared `NNNN_` sequence too.** Ask for one with
    `npm run steward --prefix backend -- slot shared --purpose "..."`. The line that used to say
    "keep taking the next free number there exactly as before" is gone: 1681 happened *in that
    sequence*, so exempting it would be enforcement theatre.
  - **Slots at or below these ceilings are grandfathered** and need no reservation:
    `shared 1852 · CA 103 · CC 72`. They are `max(num)` per namespace at the moment of the seed,
    so everything above them was numbered while the allocator was available. **The ceilings do
    not move** — raising one grandfathers a number somebody took by hand.
  - An **abandoned** slot is not reusable: ask for a fresh one. A number nobody can explain the
    abandonment of is worse than a hole, and holes are free.
  - It **skips green without `DATABASE_URL`** (forks) and **degrades green** if the steward is
    unreachable, printing why in both cases. The ref scan below still runs, and needs no database.
- **`npm run steward --prefix backend -- sync` keeps the board honest.** Read-only; `--apply`
  writes. It promotes a reservation to `written` once its file exists on a ref — without it a
  used reservation shows as outstanding for ever, which is how `CC_0074` sat on the board while
  its migration was already on master. Worth running after a merge.
  - It **reports and never writes** three things: a reservation over 14 days old with no file,
    a filename that disagrees with git, and 🔴 **a file occupying an `abandoned` slot** — someone
    reused a dead number. `check:reservations` only sees files *added on a branch*, so that last
    one is the path CI cannot watch.
  - Nothing is abandoned on a timer. 14 days is a **reporting** threshold; long branches are
    normal here, and a wrong write costs a migration.
- 🔴 **`state` TRACKS THE SLOT, NOT THE MIGRATION — there is deliberately no `applied` state.**
  The CHECK allows exactly `reserved`, `written`, `abandoned`, and **`written` is TERMINAL**: it
  means *the file exists*, never *the SQL ran*. `CC_0070_steward_schema.sql` says why in the table
  comment — this repo has **no `schema_migrations` table and no ordered runner**, each migration is
  applied once by hand, so nothing can observe that one ran and a column claiming to track it
  would always be stale.
  - **So the board cannot answer "has this been applied?" — only the data can.** Measured
    2026-09-21: `CC_0125`-`CC_0130` (SC slice 7) read `written`, which says nothing either way;
    querying production for SC's 240 offices is what established they had actually run.
  - ⚠ **Do not report a `written` slot as drift or as an un-applied migration.** It is the correct
    resting state of every used slot — 1,958 of them at the time of writing. This note exists
    because that reading was made once and it looked like a real finding.
- Reserving a number you never use is harmless — set its `state` to `abandoned`. The number is a
  filename label for humans, not a dense sequence, so holes cost nothing.
- **`npm run check:migrations --prefix backend` is still the auditor**, still CI-enforced, and is
  deliberately kept: it scans every local and remote ref, catches anyone who bypassed the
  allocator, and needs no database — so it still works when the steward does not.
  - 🔴 **`git fetch origin` before trusting it.** A stale worktree is the single most common
    source of a collision: one has read 1424 when upstream was at 1464, and 1825 when it was at
    1848. It compares against **every remote-tracking ref**, not just the base branch, so a
    number claimed on a colleague's pushed-but-unmerged branch fails too — but only if you have
    fetched it. `--list-duplicates` also reports slots claimed by different filenames on
    different refs.
- **There is no `schema_migrations` table and no number-ordered runner.** Each migration is applied
  **once, ad hoc**; the number is a filename label for humans. Migrations are never replayed by a
  deploy — so a column drop cannot break historical migrations, but nothing re-applies them either.
- Write them **idempotent** anyway (`IF NOT EXISTS`, `NOT EXISTS` guards, guarded `UPDATE`s) and end
  with a `DO $$ ... $$` **post-verify gate** that `RAISE EXCEPTION`s on a wrong count. This is the
  house style; match it.
- **Dry-run against prod first** by wrapping the body `BEGIN; ... ROLLBACK;` — and confirm the
  rollback actually reverted before trusting it.
- Numbers collide constantly because branches are long-lived. When renumbering, three things drift:
  filenames, cross-references in comments, **and migration numbers embedded in data already written
  to prod** (`source` columns, `COMMENT`s).
- 🔴 **Per-author namespaces are IN USE. Chris Cantrell's migrations are `CC_NNNN_snake_case.sql`.**
  Two authors both taking the next free number *before either pushes* is not observable from any
  repo state — fetching does not help; this is the 1681 collision. So the shared sequence is now
  one namespace among several: `CA_1` and `1` are different slots, and each author counts only
  within their own.
  - 🔴 **NEVER RESOLVE A NAMESPACE BY THE FIRST NAME "CHRIS" — TWO PEOPLE HERE ARE CALLED CHRIS.**
    Chris **Cantrell** (`Kades`, chris@empowered.vote) and Chris **Andrews** (`chrisandrewsedu`).
    This line used to read "Chris → `CA_`" and was unresolvable; the initials read as Andrews while
    the usage was mostly Cantrell's.
  - **Chris Cantrell → `CC_`**. Allocated, not counted: `steward slot CC`.
  - **Chris Andrews → `CA_`**, counting from `CA_0020` upward. Decision 2026-08-27, superseding the
    "closed to new work" line that stood here before — see below for what that line got wrong.
  - ⚠ **`CA_`'s EXISTING SLOTS ARE HISTORICALLY MIXED. Its FUTURE slots are Andrews'.** Measured
    2026-08-26: Andrews wrote `CA_0001-0003`, `CA_0011`, `CA_0012`, `CA_0015`, `CA_0016`; Cantrell
    wrote `CA_0004-CA_0010` (the NC wave) and `CA_0017-CA_0019` (compass seasons). Nothing is
    retro-renamed — `CA_0012` is embedded in 44 `compass_topic_revisions` rows and one column
    comment, so its number is load bearing. **Read an existing `CA_` slot as "whoever the git
    history says"; do not infer an author.** From `CA_0020` on, `CA_` means Andrews.
  - 🔴 **DECIDE THE AUTHOR BEFORE THE NUMBER** — it is the namespace argument you pass the
    allocator (`slot CC` vs `slot CA`), so getting it wrong still puts your migration in
    someone else's sequence. The mixture above happened because Cantrell's
    sessions reached for `CA_` while Andrews' did too. The namespace is chosen by *who is doing the
    work*, not by what the last migration in the directory happened to be called. If you cannot
    establish which Chris you are working for, ask — do not read `ls` and copy the prefix.
  - This block previously read "`CA_` IS CLOSED TO NEW WORK" while also telling Andrews nothing
    about where to write instead. That gap is what sent a session looking for a prefix to copy.
    Both authors now have a named, open namespace; neither needs to infer one.
  - **The plain `NNNN_` sequence stays open** to everyone else — but it is **allocated now, not
    counted**: `npm run steward --prefix backend -- slot shared --purpose "..."`. This
    superseded "keep taking the next free number there exactly as before" on 2026-09-04, when CI
    began failing unreserved slots. That sequence is where the 1681 collision happened and it is
    still live (1852 was taken 2026-08-31), so it gets the same allocator as `CC_` and `CA_`.
  - Zero-pad `CA_` to four digits so `ls` sorts correctly. Leading zeros are stripped when
    comparing, so `CA_0001` and `CA_1` are the *same* slot — the checker prints the stripped form
    (`CA_1`) in collision messages, the same way it prints `47` for `047`.
  - **Always cite the full slot, namespace included** (`CA_0001`, never "migration 1"). Numbers get
    embedded in prod data and comments, and `CA_0001` vs a legacy `0001` is only unambiguous if the
    namespace travels with it.
  - Duplicates inside a namespace are still caught, by both checks.
  - Do **not** retro-rename anything into `CC_` (or out of `CA_`). Renaming an applied migration desyncs the filename
    from its apply order and from numbers already written to prod. The namespace starts now and
    applies going forward only.
  - Namespaced files sort after every numeric one. Harmless: nothing globs the directory
    (`applyMigrations.ts` carries a hardcoded 026–038 list) and migrations are applied one at a time
    by hand, so apply order is unaffected.
- 🔴 **Deleting from `inform.politician_answers` obliges you to decide what happens to the matching
  `inform.politician_context` row, in the same migration.** Removing the answer removes the chair; the
  reasoning that argued for that chair survives, still asserting a position, attached to nothing. It
  is not published while the pair has no answer — but write an answer for that pair later and
  `Citations.jsx` renders the old prose verbatim under "Why this position?".
  Paste the guard from `backend/migrations/_templates/answer_delete_context_guard.sql` and state a
  `-- @context-decision:` line; `npm run check:answer-delete-guards --prefix backend` enforces it
  (CI job "answer-delete context guards"). Seven passes skipped this on 2026-08-12/13 and took `ORPHAN_CONTEXT`
  from 50 to 224.
  ⚠ **A guard asserting the context SURVIVED is not this guard** — 1735 had one and passed green while
  creating 117 violations. The test is whether the surviving context is still a *gate-visible orphan*.
  ⚠ Two dispositions, and they are opposites: if the ladder asks about a role the person neither holds
  nor seeks, **delete** the context (a blank would assert an untested absence); if the topic genuinely
  applies and the record was read, **rewrite it as a documented blank**. Never make rows fall out by
  widening the carve-out regex in `check-stance-sources.mjs`.

## Working alongside other sessions

Several sessions and machines write into this repo at once, and two of the four ways they
collide cannot be fixed by any convention — those are the steward's job (migration slots, and
jurisdiction claims). The other two need a shared working directory to happen, so they are
rules. All four are described in the design linked above; these are the two you must follow.

**The board tells you where everyone is.** `steward who` runs on session start, so you begin
knowing what is claimed. Before working a jurisdiction, take the lease:

```bash
npm run steward --prefix backend -- claim place:0642468 --label "Lomita occupancy"
npm run steward --prefix backend -- release place:0642468        # when you are done
npm run steward --prefix backend -- extend  place:0642468 --hours 4
```

- Scopes are `place:<geoid>` · `county:<fips>` · `state:<usps>`. A lease is **24 hours** —
  **measured, not chosen**: across 52 real session transcripts, an 8h lease expired during
  **60%** of working sessions (median span 10.2h, p90 18.8h). 24h expires during 6%; 48h would
  no longer be "shorter than a weekend". Constants and the method:
  `backend/scripts/lib/steward-lease.mjs`.
  - 🔴 **A LEASE THAT LAPSES MID-SESSION FAILS SILENTLY** — the row simply stops matching and
    nobody is warned. So the residual 6% is made loud instead: `who` prints
    **`⏳ EXPIRES IN 39m — extend it`** while you can still act, and keeps a lapsed claim on the
    board for 12h as **`✗ LAPSED 40m ago — free to take, check first`**. `claim` repeats that
    warning for the scope you are taking. **A lapsed lease never blocks** — it has freed the
    scope, and blocking would stall an `--if-held skip` queue behind a session that ended
    yesterday.
  - `extend` **RENEWS from now**; it does not add to the old expiry. Adding made a lease
    unbounded — three calls put it three days out, straight through the weekend bound.
- ⚠ **CLAIMS ARE ADVISORY, AND ONLY THE EXACT STRING IS STRUCTURAL.** The database refuses two
  live claims on one scope. It cannot see that `place:0642468` sits inside `county:06037` —
  the strings differ — so **containment is a WARNING**, printed at claim time. Read it. The LA
  County audit covered 88 cities plus the county; a second session taking one of those cities
  would have been told nothing before this existed.
- `--if-held warn` (default) **names the holder and claims nothing** — it does not steal the
  lease. `--takeover` is the deliberate act and is recorded on the row it displaces.
  `--if-held fail` stops; `--if-held skip <scope> <scope> …` takes the first free candidate and
  **prints every one it passed over** (exit 3 when all are held).
- 🔴 **A LEASE BELONGS TO (EMAIL, MACHINE), NOT TO A PERSON.** One author's desktop and laptop
  are as likely to collide with each other as with a second person, so your desktop cannot
  `release` or `extend` your laptop's lease without `--force`.
- Unreachable steward ⇒ **warns and continues** for every claim command. The exception is
  `claim --if-held fail`, whose whole purpose is not to guess.

- 🔴 **ONE SESSION OWNS A WORKTREE.** If you are going to commit, work in your own:
  `git worktree add -b <branch> /c/ev-accounts-<topic> origin/master`. It costs seconds. On
  2026-09-04 it was the entire reason two concurrent sessions never touched.
  - **Never `checkout` or `switch` in a worktree you did not create.** Moving HEAD under a
    running session is the failure — `C:\EV-Accounts` changed branch three times under one
    session that day, and again the same evening. If you need another branch, make another
    worktree.
  - 🟢 **THE BOARD NOW WATCHES THIS RULE.** The SessionStart hook runs `steward worktree`,
    which records the directory and branch and then tells you what moved:
    **`🔴 HEAD MOVED in <path> — it was on X …, and is now on Y`**, or **`⚠ another session was
    last seen in <path> at T`**. Read those two lines before you touch anything.
    - ⚠ **A WORKTREE ROW IS A MARKER, NOT A LEASE.** Nothing releases it when a terminal
      closes, so it means *a session started here at T* — never *a session is running here*.
      That is why `who` lists it under `~` and prints **seen**, not "expires". Registering
      takes the marker over unconditionally; the displaced session is reported, not protected.
      This is the opposite of a jurisdiction claim, because the fact is different.
- 🔴 **COMMIT WITH AN EXPLICIT PATHSPEC**: `git commit -F msg -- <path>`. Staging carefully is
  not enough, because it is the *other* session's `git add -A` that sweeps your files in.
  - 🟢 **A PRE-COMMIT HOOK NOW WATCHES THIS.** Install it once per clone:
    `npm run install:hooks --prefix backend` (sets `core.hooksPath` to `.githooks`).
    It grades the warning, because rule 3 only matters when rule 1 is broken: a note when you
    are alone, and **`🔴 COMMITTED WITHOUT A PATHSPEC IN A SHARED WORKTREE`**, naming the other
    session, when someone else has been in this checkout in the last 12 hours.
  - ⚠ **IT NEVER BLOCKS A COMMIT**, on any path, including a dead database or its own crash.
    A hook that can wedge a commit gets deleted, and then the rule has no observer at all.
    A hook cannot be pushed to anyone — it is opt-in per clone, so a colleague who has not run
    the installer is unobserved.
  - ⚠ **Until 2026-09-23 it never ran on macOS or Linux**: it was committed without its exec bit,
    and git there skips such a hook with only a `hint:` line (Git for Windows ignores the bit). CI
    step "git hooks are executable" now fails on any `.githooks/` file that is not mode 100755.
    🔴 **Linked worktrees run the MAIN checkout's copy**: their `config.worktree` sets an absolute
    `core.hooksPath` to `<main clone>/.githooks`, so the hook runs only once the main checkout's
    branch carries the 100755 file. Check with `git rev-parse --git-path hooks`.
- **Before deleting a worktree or branch**, run the four checks — as **one command**:

  ```bash
  npm run check:deletable --prefix backend -- /c/ev-accounts-<topic>
  #   exit 0 = safe, and it prints the exact removal commands
  #   exit 1 = do not delete, with every blocker named
  ```

  It checks: fully merged into `origin/master`; merged content byte-identical **for the paths
  this branch touched** (a whole-repo diff would report everyone else's merges); stash count
  unchanged (pass `STASH_BASELINE=<n>`; stashes are shared and usually someone else's); and
  nothing untracked that exists **nowhere else**.
  - ⚠ **"Untracked count is zero" can never be true here** — every worktree carries
    `node_modules` and a `.env` copy. The check asks what the rule *means*: `node_modules` is
    regenerable, and a `.env` is a copy **only once it has been byte-compared**. An unverified
    `.env` counts as unique, because it could hold a credential that exists nowhere else.
  - 🔴 **It plants its own positive control** — writes a file, confirms its scan sees it,
    removes it — and **refuses to give a verdict if the scan came back blind**. That is not
    ceremony: on its first run the scan was blind, because `git status --ignored` returns
    ~1.4 MB here and overflowed `execFileSync`'s 1 MB default with `ENOBUFS`, which the error
    handler swallowed into an empty result. Without the control it would have said
    **"0 untracked, SAFE TO DELETE"** for a worktree full of files.
  - 🔴 **Run a positive control on any detector that reports "nothing found"** — the rule this
    encodes. Two detectors were silently broken on 2026-09-04 and only a control exposed them:
    a file-mtime scan whose threshold predated the checkout, and a `curl` sweep where the host
    had begun 403-ing every request, turning "this file does not exist" into "you are being
    blocked".

## Repo facts worth knowing

- Party affiliation is **antipartisan** by design: party lives on `races.primary_party` (which ballot
  a voter requests), never on `race_candidates`.
- `geofence_boundaries.state` holds **2-digit FIPS**, not USPS codes.
- The `essentials` frontend never queries `essentials.*` tables directly — it goes through this API.
- **Not every seat is residency-based or full-voting.** Maine seats three non-voting *tribal*
  representatives; the territories and DC send non-voting delegates.
  [`docs/adr/0003-non-residency-representation.md`](docs/adr/0003-non-residency-representation.md)
  splits those into `districts.representation_basis` (`residency` | `membership`) and
  `offices.voting_powers` (`full` | `committee_only` | `non_voting`). Live since migration 1718
  (Maine's three tribal seats) and 1719 (**all six territory/DC non-voting House seats** — PR, VI, GU,
  AS, MP, DC — plus DC's two shadow senators, who hold no seat in Congress at all).
  - **A `membership` district must never carry a `geo_id`.** Enrollment is not inferable from an
    address, so these seats are *additional and explained*, never assigned. `check:reachability`
    fails on a membership district with geometry, and excludes them from address expectations.
  - `offices.representation_note` is **required** whenever `voting_powers <> 'full'` (a CHECK) or
    `representation_basis <> 'residency'` (post-verify + read path — a CHECK can't cross tables).
    **The read path must not render such a seat without the note.**

## Compass chairs are five distinct stances, not a polarity rating

**To seat a politician in a chair you need evidence describing THAT chair, with sources.** The five
options are five distinct stances along a spectrum; the chair is a voter-facing claim about what
this person holds, not a rating of how strongly they lean.

- Evidence that establishes only the **direction** (pro/anti) under-determines *which* of the two or
  three chairs on that side applies. Seating anyway is an unevidenced claim — the same defect class
  as a composed citation, expressed as a number.
- A bill citation proves direction. It does **not** automatically prove magnitude: "supports
  progressive taxation to fund public services" cannot distinguish *significantly raise taxes on the
  wealthy* (1) from *moderately raise* (2).
- ⚠ **"The least extreme option the reasoning supports" is a TIEBREAKER, not evidence.** Reaching
  for it is the signal that the row is not yet evidenced.
- The honest alternative to a guessed chair is a **blank spoke**. A blank spoke is correct.
- **Never assume polarity.** Read each ladder from `inform.compass_stances`. The corpus convention is
  chair 1 = maximum government action, but **AI Oversight and Tariffs run the other way**, and
  Residential Zoning, Growth and Development Pace and Government Deference are off-axis entirely
  (the deregulatory and the progressive position sit at the same end). See
  [`.planning/todos/2026-08-12-ladder-orientation-and-consumers.md`](.planning/todos/2026-08-12-ladder-orientation-and-consumers.md).
- A re-sourcing pass that cites **sponsorship** must refuse any row at the anti pole — the new
  citation would contradict the displayed position.

**Gate:** `node scripts/audit-chair-evidence.mjs --check <rollback.json>` fails if any row it lists
carries reasoning that names no instrument, act or vote. Run it before committing any migration that
sets a chair.

### A blank is `value = 0`, and `-- @zero-scope:` records who counts it

When a ladder changes so that no rung states what a politician holds, the answer is **blanked**
rather than guessed or deleted: the row stays, carrying `value = 0`. Season 1 keeps the old rung as
history; the new season shows a blank spoke. (Ruling 2026-09-02: *"If there is nowhere for them to
go, they can be blanked. We will remember the difference between seasons 1 and 2."*)

So **every read of `politician_answers.value` has to decide what a 0 means to it**, and the two
right answers point opposite ways:

- **Anything that displays or averages a position must exclude it.** A 0 is not rung 0. Left in, it
  scores as maximum disagreement in `compareWithPoliticians`, opens a bar no ladder text can label
  in the stats distribution, and makes `has_stance` true with nothing to name.
- **Anything asking whether research HAPPENED must keep it.** Blanking says the ladder moved out
  from under a position, not that the reading was undone — the coverage rollups would otherwise
  report a loss no editor caused.

A site that keeps blanks says so in the query, in the same shape as `-- @season-scope:`:

```sql
-- @zero-scope: counts-blanks — coverage is "ever researched", and the research happened.
```

**⚠ Unlike `@season-scope`, this marker is NOT enforced by a gate.** It is documentation, and
`grep -rn "@zero-scope" backend/src` is how you find every site that has been judged. A read with no
marker has not necessarily been thought about — check it before trusting it.

**Guard placement is the part that goes wrong.** Put the filter OUTSIDE the newest-season collapse,
never inside it. Inside, a blank in the newest season is skipped and the query silently falls back
to an older season's rung — serving a position the politician no longer holds, against a ladder it
was never an answer to. That is the same failure the season collapse exists to prevent, one layer
down, and it is what the tests in `compassService.test.ts` pin.

### Rewording a chair that already holds seated politicians (ruling 2026-08-28, Chris Andrews)

- A **clarifying** rewording — same position, clearer words — keeps existing seats. Nothing re-audits.
- A **material** rewrite — a double-barrel split, a narrowed or widened claim — means the seats' evidence
  was gathered against a sentence that no longer exists. Those rows need a **re-audit against the new
  wording** (`audit-chair-evidence.mjs` is the tool), not a silent text update. State the seated-row
  count in the proposal's rationale so the reviewer prices the re-audit before approving.
- Seasons carry the mechanics: a season's pin never moves once open, so Season 1 rows keep asserting
  exactly the wording they were evidenced against. The re-audit question is about what carries forward
  into the NEXT season's research, not about rewriting history.

### Scope is a per-rung question, not a per-topic one (ruling 2026-08-28, Chris Andrews)

**A ladder is only valid at a level where its rungs are things an officeholder there can actually
do.** Scopes were originally assigned per topic and never re-checked rung by rung — `voting-rights`
fails 4 of 5 rungs at `local` (NC wave 2b memo). Before adding a `compass_topic_roles` row for a
level, read every rung and ask: does an officeholder at this level hold a lever on this? A chair
that can only be evidenced by opinion at that level is the exact shape the evidence standard refuses.
