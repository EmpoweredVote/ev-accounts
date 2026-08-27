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

Join the view, in whichever direction you need. It is **exactly one row per office** (guaranteed by
`office_terms`' exclusion constraint), so it cannot fan a result set out:

```sql
JOIN essentials.office_current_holder och ON och.office_id     = o.id   -- who holds this seat
JOIN essentials.office_current_holder och ON och.politician_id = p.id   -- what seat does this person hold
```

For history, `essentials.office_holders_as_of(date)` answers "who represented me in 2019".

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

- Live in `backend/migrations/`, numbered `NNNN_snake_case.sql`. **Take the next free number** and
  verify with `npm run check:migrations --prefix backend` (also CI-enforced on PRs).
- 🔴 **`git fetch origin` before you read the max.** A stale worktree is the single most common
  source of a collision: one has read 1424 when upstream was at 1464, and 1825 when it was at 1848.
  The check compares against **every remote-tracking ref**, not just the base branch, so a number
  claimed on a colleague's pushed-but-unmerged branch fails too — but only if you have fetched it.
  `--list-duplicates` also reports slots claimed by different filenames on different refs.
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
  - **Chris Cantrell → `CC_`**, counting from `CC_0001` upward. He never reads the shared max again.
  - **`CA_` IS HISTORICALLY MIXED AND IS CLOSED TO NEW WORK.** Measured 2026-08-26: Andrews wrote
    `CA_0001-0003`, `CA_0011`, `CA_0012`, `CA_0015`, `CA_0016`; Cantrell wrote `CA_0004-CA_0010`
    (the NC wave) and `CA_0017-CA_0019` (compass seasons). Nothing is retro-renamed — `CA_0012` is
    embedded in 44 `compass_topic_revisions` rows and one column comment, so its number is load
    bearing. Read an existing `CA_` slot as "whoever the git history says"; do not infer an author.
  - **The plain `NNNN_` sequence stays as it is** for everyone else; keep taking the next free
    number there exactly as before.
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
