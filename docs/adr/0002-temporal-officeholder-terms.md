---
status: proposed
---

# Temporal officeholder terms (`essentials.office_terms`)

An office's occupant changes on a known date, and we cannot currently say so. `essentials.offices`
holds exactly one `politician_id` — a point-in-time snapshot with no temporal dimension — so an
election that has already been decided but whose term has not started is unrepresentable. We
decided to make occupancy a **time series** in a new `essentials.office_terms` table, resolved to
"current" **at read time**, and to skip the intermediate step of putting `term_start`/`term_end`
columns on `offices`.

## Why now

Wisconsin's April 2026 judicial elections were decided months ago and take office on **August 1,
2026**. Chris Taylor (Supreme Court) and Anthony LoCoco (Court of Appeals District II, which covers
Racine County) are certified winners who do not yet hold office. Today there are only two options,
both wrong: publish them early, or publish their predecessors and go stale on a known date. So
migration 1433 seeded only the Racine County Circuit Court, whose ten judges are all currently
sitting, and deferred the other two bodies entirely. That deferral is the cost of this gap, and it
recurs every election cycle in every state.

The same gap loses history we already had in hand while building Racine County:

- **Tom Weatherston** resigned as Caledonia's Village President mid-term.
- **Prescott Balch** won Trustee Seat 2 in April 2026, then moved up to President, leaving Seat 2
  vacant. Two facts about one seat in one year; we can record only the latest.
- **Eugene Bower** was *appointed* to Union Grove Trustee 6 in August 2025 to finish a term, then
  *elected* to it in April 2026. Two tenures, two different `how_started` values.

None of that is expressible. Each transition silently overwrites the last.

## Why not term columns on `offices` first

`offices.term_start` / `term_end` looks like a cheaper first step. It is not a step — it is a
detour:

- **Both designs need the same read-path change.** Resolving "who holds this seat today" means a
  date predicate at query time, in every read path. That is the actual work, and it is identical
  either way. Doing columns first means paying it twice and then discarding the columns.
- **Columns cannot prevent overlap.** With `term_start`/`term_end` on `offices`, two rows for the
  same seat are just two rows; nothing stops two simultaneous occupants. `office_terms` can forbid
  it in the database (below).
- **Columns cannot hold history.** One row per office means one tenure per office.

`politicians.valid_from` / `valid_to` are not the answer either. They are `text`, populated on
~0.8% of rows (701 of 85,018), never filtered on — only `SELECT`ed for display as
`term_start`/`term_end` — and, decisively, they hang off the **person** rather than the tenure.
**28 politicians already hold more than one office** (three of them created by the 1427 dedup
merge), and a single `valid_from` on the person cannot describe two tenures with different
windows. Add real date columns; leave those two alone and deprecate them.

Verified against production before writing this: `btree_gist` is available but not yet installed;
there are **83,186** office rows to backfill, **82,329** of them with an occupant and 857 already
vacant; and **zero** offices would violate the exclusion constraint on a one-term-per-office
backfill.

## Schema

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;   -- required: uuid equality inside a GiST exclusion

CREATE TABLE essentials.office_terms (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id       uuid NOT NULL REFERENCES essentials.offices(id)     ON DELETE CASCADE,
  politician_id   uuid          REFERENCES essentials.politicians(id),  -- NULL = seat vacant for this span
  term_start      date,          -- NULL = unbounded/unknown start
  term_end        date,          -- NULL = open-ended, i.e. current
  start_precision text NOT NULL DEFAULT 'day'
                  CHECK (start_precision IN ('day','month','year','unknown')),
  how_started     text CHECK (how_started IN
                    ('elected','appointed','succeeded','redistricted','unknown')),
  how_ended       text CHECK (how_ended IN
                    ('term_expired','resigned','defeated','retired','died','recalled',
                     'removed','redistricted','unknown')),
  source          text NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT office_terms_dates_sane
    CHECK (term_start IS NULL OR term_end IS NULL OR term_end >= term_start),

  -- One seat cannot have two occupants at the same time. This is the constraint that
  -- columns-on-offices can never express.
  CONSTRAINT office_terms_no_overlap EXCLUDE USING gist (
    office_id WITH =,
    daterange(term_start, term_end, '[]') WITH &&
  )
);

CREATE INDEX office_terms_office_idx     ON essentials.office_terms (office_id);
CREATE INDEX office_terms_politician_idx ON essentials.office_terms (politician_id);
CREATE INDEX office_terms_current_idx    ON essentials.office_terms (office_id)
  WHERE term_end IS NULL;
```

`start_precision` exists because sources routinely give a year and nothing more — Racine County's
own court page says "2017 to Present". Migration 1433 left `date_seated` NULL rather than invent
`2017-01-01`; with `start_precision` the year can be recorded honestly as `2017-01-01` +
`precision='year'`.

`politician_id` is nullable on purpose: a vacancy is a fact about a span of time, not an absent
row. Caledonia Trustee Seat 2 is vacant *from* Balch's elevation *until* it is filled, and that is
a term like any other.

## Resolution

Resolution happens **at query time**. Never cache the current occupant in a column kept fresh by a
trigger: a trigger cannot fire because the calendar advanced, so the August 1 hand-off would not
happen and we would be back to needing a scheduled job. Time-dependence belongs in the predicate.

```sql
CREATE VIEW essentials.current_office_holders AS
SELECT office_id, politician_id, term_start, term_end, how_started
  FROM essentials.office_terms
 WHERE (term_start IS NULL OR term_start <= CURRENT_DATE)
   AND (term_end   IS NULL OR term_end   >= CURRENT_DATE);

CREATE FUNCTION essentials.office_holders_as_of(as_of date)
RETURNS TABLE (office_id uuid, politician_id uuid, term_start date, term_end date)
LANGUAGE sql STABLE AS $$
  SELECT office_id, politician_id, term_start, term_end
    FROM essentials.office_terms
   WHERE (term_start IS NULL OR term_start <= as_of)
     AND (term_end   IS NULL OR term_end   >= as_of);
$$;
```

This mirrors two patterns already working in this codebase: `ELECTION_VISIBILITY_WINDOW` in
`electionService.ts`, and `race_candidates.provisional_until` with
`essentials.stale_provisional_candidates` from migration 1435. In all three, time is a fact about
the row and the read path evaluates it. Nothing has to remember to run.

## Migration path

Incremental, each phase independently shippable and reversible:

1. **Create** the table, extension, constraints, indexes, view and function. Writes nothing else.
2. **Backfill** one open-ended term per existing office row: `politician_id` from
   `offices.politician_id`, `term_start = NULL`, `term_end = NULL`, `start_precision='unknown'`,
   `source='backfill from offices.politician_id'`. Every current holder becomes a current term, so
   `current_office_holders` immediately reproduces today's answers. The exclusion constraint will
   reject any office that somehow has two rows — a useful audit on the way in.
3. **Dual-read**: move read paths onto `current_office_holders` one at a time, keeping
   `offices.politician_id` as fallback. `essentialsService.ts` is the main consumer; the joins in
   `electionService.ts` are unaffected because races link to offices, not to occupants.
4. **Write new data as terms.** Seed Taylor and LoCoco with `term_start = 2026-08-01`; they appear
   on their own.
5. **Drop** `offices.politician_id` once no read path uses it, and deprecate
   `politicians.valid_from`/`valid_to`.

Prerequisite, already done: migration **1434** added the missing
`offices.politician_id → politicians` foreign key and repaired two orphaned office rows. Building
temporal logic on a column with no referential integrity would have inherited the problem.

## Considered options

- **`office_terms` table, resolved at read time (chosen).** Only option that can forbid overlapping
  occupancy in the database, hold history, and represent a vacancy or a future term as ordinary
  data. Cost is the read-path change, which every option needs anyway.
- **`term_start`/`term_end` on `offices`.** Cheaper migration, same read-path cost, and then thrown
  away. Cannot express overlap prevention or history. Rejected as a detour, not a stepping stone.
- **Scheduled job that swaps `offices.politician_id` on the transition date.** No schema change,
  but correctness now depends on a cron firing; a missed run silently serves the wrong
  officeholder, and there is still no history. This is the status quo made explicit, and it is what
  every other option removes.
- **Populate the existing `politicians.valid_from`/`valid_to`.** Wrong entity — dates belong to a
  tenure, not a person, and three politicians already hold two offices each. Also `text`, and
  read paths only display them.

## Consequences

- One person holding two offices with different term windows becomes representable; so do
  vacancies-with-dates, mid-term appointments, and resignations.
- "Who represented this address in 2019?" becomes a query rather than a schema change.
- Election automation stops needing a calendar-driven job: certify the winner, write the term, and
  the hand-off happens on the date.
- Cost is real: every read path that resolves an officeholder must be revisited, and the backfill
  touches 83,186 office rows. Phases 1–2 are safe and additive; phase 3 is the careful one.
- `essentials.offices` becomes what its name implies — a **seat** (district + chamber + title) —
  with occupancy held separately.
