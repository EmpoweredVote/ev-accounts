# ev-accounts — working notes

Conventions that are not obvious from the code and that are expensive to get wrong. Keep this short;
if something needs a page, put it in `docs/` or an ADR and link it here.

## How to report

Report in plain English. Readers are smart non-developers.

- Lead with the answer or result. Then give only the detail needed to act on it.
- Short sentences, one idea per sentence, active voice. No idioms, metaphors, or filler.
- Use a plain word instead of a technical term when one exists. When you must use
  a technical term, define it in a few words the first time.
- Make each reply as long as the question needs, and no longer. Do not repeat
  what you already said.

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

⚠ **This is not hypothetical** — a list query without the `DISTINCT` once returned two Aaron
Freemans. Both politician-rooted reads in `backend/src/lib/essentialsService.ts` now show the two
fixes: the `?q=` list wraps a `DISTINCT ON (p.id)`, and `getPoliticianById` takes `LIMIT 1` under an
`ORDER BY` that prefers a held seat over a sought one. Give a new politician-rooted query one or the
other.

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
failure mode CI cannot catch. Watch `essentials.offices_missing_terms`.

🔴 **IT IS A THREE-PART MEASUREMENT, AND ONLY THE THIRD NUMBER IS THE BASELINE.** The view's own
`count(*)` is NOT the metric. Always measure all three:

```sql
SELECT count(*) AS total,
       count(*) FILTER (WHERE o.is_vacant)     AS flagged,
       count(*) FILTER (WHERE NOT o.is_vacant) AS unflagged   -- ← the baseline
  FROM essentials.offices_missing_terms m
  JOIN essentials.offices o ON o.id = m.office_id;
```

**Measured 2026-10-26: `295 / 57 / 238`** (was `433 / 194 / 239` on 2026-10-20; the 136 that left
are all 17 Maine cities being seated — `CC_0282` Augusta, `CC_0283` Westbrook, `CC_0291` Bath,
`CC_0292` the nine all-at-large, `CC_0293` the final five). The Knight trackers report it in
exactly this `total / flagged / unflagged` form — see `.planning/knight-foundation/fl.md`
§"Flagging is load-bearing twice over". **Baseline, LOWERED to 238 UNFLAGGED by `CC_0296` on
2026-10-26** (239 from 2026-09-29 until then). **Treat a count above 238 unflagged as new drift.**
A flagged seat is a *declared vacancy* and is deliberately not drift.

⚠ **ONLY THE UNFLAGGED NUMBER IS A BASELINE — THE OTHER TWO ARE DATED OBSERVATIONS.** Seating a
city moves `total` and `flagged` and must leave the baseline alone. It has, across every Maine
wave: a wave that seats *flagged* seats shrinks the flagged bucket, never the baseline.

🟢 **THE BASELINE FALLS ONLY ONE HONEST WAY: BY SEATING A SEAT THAT WAS UNFLAGGED AND UNSEATED.**
That is what `CC_0296` did — Indiana's real Comptroller office sat empty inside the 239 while a
duplicate office row held the officer, so merging the two seated it and took the baseline to 238.
🔴 **That is the only reason to move it down. Never lower it to match a number you measured, and
never raise it at all** — a lower baseline is a tighter net, and raising one hides the drift it
was put there to catch.

⚠ **THE OTHER TWO NUMBERS MOVE UNDER YOU BETWEEN SESSIONS.** `CC_0295` measured `297 / 58 / 239`
and `CC_0296`, hours later, measured `296 / 57 / 239` before writing anything — another session had
resolved one flagged seat and dated two more in between. Neither migration caused it and neither
was wrong. ▶ **Gate a migration on the DELTA it creates, captured in its own transaction, not on a
total somebody else can move while you write the file.** `CC_0296`'s post-verify shows the shape.

⚠ **READING THE TOTAL AGAINST THE BASELINE RAISES A FALSE ALARM**, and has: on 2026-10-20 a
session reported "433 against a baseline of 239, +194 of drift". The +194 it had found was the
flagged population itself — the metric was intact and nothing was wrong.

The St. Louis city Sheriff seat (`CC_0178`) is unseated and unflagged by ruling and is counted in
that 238; it is not drift. Lower this number whenever a change shrinks it — a stale, high baseline
hides drift, and 🔴 **never raise it to clear a red.**

⚠ **THE FLAGGED BUCKET IS NOT AUDITED, AND IT HIDES THINGS.** Measured 2026-10-26, across every
`is_vacant` office and not just those in the view: **65 flagged, 40 dated, 25 undated** (was
65 / 24 / 41 before `CC_0298`). An undated flag asserts a vacancy to voters and keeps the row out
of the drift metric. **Do not read a stable 238 as "occupancy is clean".**

🔴 **AN UNDATED FLAG CANNOT TELL YOU WHICH KIND OF THING IT IS, AND THERE ARE FOUR KINDS.**
`CC_0298` classified all 41 undated flags one at a time, and only 16 of them wanted a date:

| kind | n | what it needs |
| --- | --- | --- |
| real vacancy, date citable | 16 | the date — `CC_0298` wrote these |
| real vacancy, date not published | 1 | **nothing.** Richland County SC SWCD says so in its `description`; that is the correct shape |
| **not vacant, a holder exists** | 1 | seat the person (Cornelius OR — the city lists four councillors, we hold three) |
| **not vacant, awaiting its FIRST election** | 20 | explain it (`CC_0299`), then seat the winner |
| unseeded, emptiness unproven | 3 | a roster check, not a date |

🔴🔴 **A SEAT AWAITING ITS FIRST ELECTION LOOKS EXACTLY LIKE A VACANCY. ASK WHAT IS ON THE BALLOT.**
Eight Los Angeles County bodies carry BOTH legacy `At-Large` office rows and newer by-district
rows, because they are part-way through a **staggered** by-district conversion under the
California Voting Rights Act. The at-large rows are the last holdovers and are still legitimately
in office; the empty district rows are their successors. One set is replacing the other on a
published schedule — Azusa elected Districts 2, 4 and 5 in November 2024 and elects 1 and 3 in
November 2026, which is exactly which of its rows are seated and which are empty.

⚠ **`CC_0298` CALLED THESE "DUPLICATE SEATS" AND THAT WAS WRONG** — wrong in a way that would have
justified deleting real offices. The counting argument it used ("at-large + seated-district = the
body's size") was TRUE and still pointed at the wrong conclusion. 🔴 **A COUNT CAN BE RIGHT AND
MEAN SOMETHING ELSE.** What settled it was one query against data we already held: all 20 empty
offices carry exactly one race, every one dated 2026-11-03, with candidates already filed.
▶ **Before deciding what an empty seat is, read its races.** Then the chamber count tells you
whether the body is whole, which is a different question.

🔴 **A COMPLETE, FULLY-SEATED CHAMBER IS THE SIGNATURE OF A REAL VACANCY.** The 19 non-California
undated flags all sat in rosters that were whole except for exactly the flagged seats (MO House
163 offices / 155 seated / 8 flagged; MA House 160 / 158 / 2). That shape says the loader found
everyone there was to find.

🔴 **DO NOT CLEAR `is_vacant` ON AN UNSEATED OFFICE TO HIDE IT FROM ADDRESS SEARCH.** It works —
unseated and unflagged is invisible — and it turns the **master-only** reachability gate red on
whoever merges next. `check-address-reachability.mjs` reports DEAD_GEOGRAPHY for a district with
`active_holders = 0 AND vacant_offices = 0`, so the flag is the only thing keeping such an office
out of it, and the gate fires on **any new bucket**. Check `address-reachability-baseline.json`
before clearing a flag in bulk.

▶ **December 2026:** seat the 20 winners, retire the at-large holdovers in the bodies whose
conversion completes, and **delete the `CC_0299` descriptions** — they name a past election and
go false the moment a winner is seated.

**Date a vacancy at the moment you establish it**, or the next session re-derives which kind it was.

🟢 **MAINE IS FINISHED AND CLOSED (2026-10-26).** It was the bulk of this bucket: 138 municipal
offices across 17 cities, 100% flagged-undated, none ever seated, plus one real state-level
vacancy. **Not one Maine office at any level — city, school or state — is now flagged without a
date** (`CC_0294` gates that statewide). The three that remain flagged are all dated and real:
Brewer's council seat, South Portland Public Schools', and the Penobscot Nation's tribal seat,
empty since 2015-05-27. Rules, sources and the dated follow-ups:
`backend/data/seed-me-municipal-2026/ROSTERS.md` — **open it before any Maine work.**
▶ **2026-12-02**: the 133rd Legislature convenes and PL 2026 c.705 gives the Mi'kmaq Nation a
fourth tribal seat. Create it then, not before.

🔴 **THE DATED VACANCIES BARELY MOVE WHILE THE UNDATED FELL 181 → 43.** Every seat a wave seats
comes out of the undated pile, so that gap is the Maine backlog draining — not the audited
vacancies being resolved. **Read the two sub-buckets separately, or a falling flagged total will
look like progress on something it has not touched.** (13 → 15 are the two real additions, and
they are different acts: Brewer's At-Large 5, `CC_0292` — a councillor who resigned in July 2026,
so a wave can CREATE a documented vacancy as well as clear undated ones — and the Penobscot
Nation's tribal seat, `CC_0294`, which was not created but **moved out of the undated pile by
being dated**. That second kind changes no total and is the whole point of the sub-buckets.)

🟢 **FIXED 2026-10-26 — A FLAGGED-VACANT OFFICE USED TO COME BACK AS A NAMELESS ROW.**
`office_current_holder` LEFT JOINs from `offices`, so the read path emits an empty seat as a row
whose `p.*` columns are all NULL. `PoliticianFlatRecord.id` was typed `string` and the mapper cast
that NULL through with `as string`, so **the type told every consumer each row is a person** and a
voter got a blank card. Measured live: a Santa Clarita address returned two of them. The row now
says what it is:
- **`id` is `string | null`.** The type no longer lies, and TypeScript found all seven mappers and
  every `imageMap.get(p.id)` that assumed otherwise.
- **`office_id` is on every politician row.** Before this the whole surface carried NO office
  identity: a held row could be keyed on the person and a vacancy could be keyed on *nothing*.
- **`seat_status: 'held' | 'vacant'`** — 🔴 **derived from whether a holder resolved, NEVER from
  `is_vacant`.** Those answer different questions: `is_vacant` is an assertion on the office (see
  **The `is_vacant` trap** below), `seat_status` is "is there a name in this row". ⚠ They agree on
  every row in prod today — measured, zero flagged-and-held offices repo-wide — because the seating
  migrations gate it to zero. That is a reason to keep them separate, not to collapse them: the
  moment one flagged-and-held row appears, the collapsed version is wrong and silent.

⚠ **THE DATA HALF IS STILL OPEN.** 40 of the 57 flagged offices carry no `vacant_since`, so they
render as "vacant, date unknown" — honest about the record and still wrong about the world in most
cases, because `is_vacant` was used to mean "not seeded". 21 of the 40 are Los Angeles County
school boards and special districts; 8 are Missouri House seats. Each needs research, not a
read-path change.
⚠ **A `membership`-basis seat is the exception and is NOT affected** — it has no `geo_id` by
design (ADR 0003) and `check:reachability` fails if one ever acquires geometry, so Maine's
vacant Penobscot tribal seat is never returned for an address at all. Its
`representation_note` is the only place a reader learns it exists.

🟢 **FIXED 2026-10-26 — ADDRESS SEARCH USED TO RETURN AT MOST ONE SEAT PER PERSON.** The shared
district query de-duplicated on `COALESCE(p.id, o.id)` — the PERSON — so someone holding two seats
reachable from one address collapsed to one row and the voter never saw the second. `27` active
people hold two or more current seats. The key is now **`OFFICE_DEDUP_KEY = 'o.id'`** in
`src/lib/districtQueries.ts`: **one row per OFFICE**, which is what the endpoint means.
- 🔴 **The DISTINCT itself is load-bearing and stays.** Several geofence rows can share a `geo_id`
  and map to the same district type, so the join really does return an office twice: measured,
  Indianapolis 129 raw rows for 89 offices. Removing it lets duplicates reach the response.
- 🔴 **The INVERSE still applies to politician-rooted reads** (`?q=` list, `getPoliticianById`,
  everything in `essentialsBrowseService.ts`): those fan out one row per office a person holds and
  need `DISTINCT ON (p.id)`. See **Reading** above — the two join directions do NOT carry the same
  guarantee, and the right key is opposite in each.
- ⚠ **A de-dup keyed on the wrong column LAUNDERS the rows it keeps.** Keyed on the person, two
  duplicate OFFICE rows held by one person showed as one and looked fine: Indiana's Secretary of
  State and Treasurer each existed twice for four years, invisibly. `CC_0295` retired them, and its
  post-verify gates at zero repo-wide the condition that would make this visible again.
  ▶ When you fix a de-duplication, **diff the rows, not the count** — the rows it adds that should
  not be there are the finding.
- 🔴 **A DUPLICATE OFFICE CAN HIDE FOR THE OPPOSITE REASON, AND THE DE-DUP KEY HAS NOTHING TO DO
  WITH IT.** `CC_0295`'s own gate then found a THIRD Indiana duplicate, `Comptroller x2`, split
  the other way: the race-carrying copy was empty and the duplicate held the officer. `CC_0295`'s
  PR reasoned from the de-dup key that both already showed, and **that was wrong** — measured
  against the live endpoint, only one ever did, because `buildStatewideQuery` ends with
  `AND (p.is_active = true OR o.is_vacant = true)` and an unseated, unflagged office satisfies
  neither arm. That is the **Writing** rule above (*an office with no term is invisible*) wearing
  a different hat. `CC_0296` merged it. ▶ **REASONING ABOUT A READ PATH IS NOT MEASURING IT** —
  ask the live endpoint before you write down what a voter sees.
- 🔴 **MERGING TWO OFFICE ROWS IS NOT DELETING ONE.** When the term sits on one copy and the race
  on the other, move the term first, then delete: `office_terms.office_id` is `ON DELETE CASCADE`,
  so deleting the held copy eats the term and silently unseats the officer. And repoint the
  deprecated `politicians.office_id` snapshot in the same migration — **it has NO foreign key**, so
  the delete leaves it dangling without complaint. Both hazards were confirmed by running `CC_0296`
  with each step removed and watching its gates fail.

Use the helpers rather than hand-rolling the two-step:

```sql
-- Seat someone from a date. Closes the predecessor's term the day before. Idempotent.
SELECT essentials.seat_officeholder(office_id, politician_id, term_start, source);

-- Close a term with no successor, as of the first VACANT day. Syncs is_vacant/vacant_since.
SELECT essentials.vacate_office(office_id, first_vacant_day, source);
```

🔴 **`vacant_since` IS THE FIRST DAY THE SEAT WAS EMPTY, NOT THE DAY THE MEMBER LEFT.** The helper
defines it: it writes `vacant_since = p_as_of` and closes the predecessor at `term_end = p_as_of - 1`.
Almost every source publishes the *departure* date instead, so **a date copied straight off a
source is one day early.** Ballotpedia's state-legislative tables head that column "DATE OF
VACANCY", which reads like the same thing and is not: it gives Missouri Senate 10 as 2026-05-15,
and the Missouri Senate's own page says "Senator Fitzwater resigned his seat on 05-15-2026".
Departure + 1 also reproduces five of this repo's nine comparable existing rows exactly.
⚠ **The column is already internally inconsistent** — four other rows (CA Senate 10, CA Assembly 3,
VA House 20, TX Senate 22) disagree with that rule by one or two days, from earlier passes. Known,
not new; do not "fix" one without re-sourcing it.

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
- 🔴 **Set `politicians.is_incumbent` explicitly on every insert** — `true` when you seat the person,
  `false` for a candidate or former officeholder. It is a cached flag the incumbents-only reads filter
  on. It defaulted to `true` until `CA_0188`, and that created **1,817 active "incumbents" with no
  seat** (cleared by `CA_0181`-`CA_0187`). It defaults to `false` now, so a seated person inserted
  without it is **hidden** from address search. `check:occupancy` fails an INSERT that omits it.
- **`politicians.valid_from` / `valid_to` are DEPRECATED** — wrong entity (dates belong to a tenure,
  and people hold two offices). Don't read them in new code. `politicians.office_id` is a legacy
  point-in-time snapshot with the same flaw; prefer the view.

### Sourcing a seat from a roster or an election result

Four rules the municipal seeding waves paid for, each after getting a real seat wrong:

- 🔴 **A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT.** It records who won an
  election. Taking office is a separate, later event, and people decline, resign, die or are
  appointed in between. Seat from a source about the *officeholder*, not about the count.
- 🔴 **A SOURCE CAN BE AUTHORITATIVE FOR ONE FIELD AND STALE FOR ANOTHER.** A city's own council
  page is the authority on who sits there and can still show term dates that expired two years
  ago. Judge a page field by field, never as a whole.
- 🔴 **"FIRST ELECTED" IS NOT A TERM START.** A roster label like that says how someone ARRIVED,
  not when the current term began. Write an open-ended term with `start_precision => 'unknown'`
  rather than reusing the number that happens to be printed.
- 🔴 **A DEPARTED OFFICIAL'S URL CAN SERVE THEIR SUCCESSOR**, with no redirect and no error.
  Assert that the page NAMES the person before you record it as their source.
- 🔴 **THE CHAMBER'S OWN ROSTER OUTRANKS EVERY AGGREGATOR, AND THEY DO DISAGREE.** On 2026-10-26 a
  web search reported the Missouri House as having five vacancies against our eight, which read
  like stale data on our side; `house.mo.gov`'s member grid listed exactly our eight. For three of
  them Ballotpedia still showed the member *sitting*. **A search summary is a lead. Open the
  roster.**
- 🟢 **WHEN THE AGGREGATORS DISAGREE, THE LEGISLATIVE JOURNAL SETTLES IT.** Those three Missouri
  seats appear in no vacancy table anywhere, and the resignation letters are printed verbatim —
  name, district, and the hour the resignation took effect — in the House Journal for the day they
  were read in (`documents.house.mo.gov/billtracking/bills261/jrnpdf/jrnNNN.pdf`). A Wikipedia
  infobox citation is often the fastest way to find the right journal number. Most chambers
  publish the equivalent; reach for it before recording a date as unobtainable.

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
- 🔴 **NEVER CREATE A TABLE OR VIEW IN `public`.** Put it in the EV schema it belongs to (`inform`,
  `treasury`, `connect`, `civic`, `civic_spaces`, `empower`, `validation_quests`, `essentials`).
  From 2026-10-30 Supabase gives new `public` tables **no automatic Data API grants**
  ([discussion #45329](https://github.com/orgs/supabase/discussions/45329)).
  - **The migration that creates a table or view also, in the same file:** grants explicit
    privileges — only to the roles that need them (`anon`, `authenticated`, `service_role`, `ev_api`),
    only for the actions they need; runs `enable row level security`; and creates its policies.
    A `serial`/`bigserial` column also needs `grant usage` on its sequence; an identity column does
    not. A view needs its own grants
    and `security_invoker = on`.
  - ⚠ **PostgREST `42501 permission denied` means a grant is missing.** It is not a reason to loosen
    RLS.
  - 🔴 **Never fix a 42501 with a bulk `grant ... on all tables in schema ...`.** That also exposes
    every table in the schema whose RLS is off. Grant the one object, to the one role.

## Working alongside other sessions

Several sessions and machines write into this repo at once, and two of the four ways they
collide cannot be fixed by any convention — those are the steward's job (migration slots, and
jurisdiction claims). The other two need a shared working directory to happen, so they are
rules. All four are described in the design linked above; these are the two you must follow.

🔴 **THERE IS A FIFTH, AND IT IS THE ONE THE OTHER FOUR CANNOT SEE: TWO BRANCHES EDITING THE SAME
FILE.** The steward's scopes describe the **world** — which place, which migration number. This
one is in the **repo**. Measured 2026-09-26: Knight slices 11 (MI) and 12 (ND) held *disjoint*
jurisdiction claims, took *distinct* slot ranges, and worked in *separate* worktrees — every
mechanism did its job — and both edited `backend/scripts/load-state-tiger-boundaries.ts`, because
every state's geography load does. PR #797 sat **64 commits behind master with 2 conflicting
files for two days** and nothing said so.
- ⚠ **A JURISDICTION CLAIM CANNOT KNOW WHICH FILES THAT JURISDICTION TOUCHES.** Claiming
  `state:nd` says nothing about the generic loader, or `PROGRAM.md`, which every slice appends to.
  Expect to conflict in those two; they are the hot files.
- 🟢 **`steward who` NOW REPORTS BRANCH DRIFT** for every worktree in the checkout, at session
  start: how far behind the base each branch is, and **which files already conflict**. It is
  read-only (`git merge-tree`, computed in memory — it never touches another session's worktree),
  it never fetches, and **it prints even when the steward's database is down**, because it is git
  alone. It stays silent when nothing is wrong.
- ▶ **A CONFLICTING BRANCH DOES NOT GET BETTER BY WAITING.** Merge the base into it early, and do
  it **in that branch's own worktree** — never by moving HEAD in a worktree you did not create.

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
  - ⚠ **Both steward hooks (this one and SessionStart) used to skip SILENTLY without
    `backend/node_modules`** — 10 of 17 worktrees on 2026-09-23, so most sessions got no board, no
    worktree marker and no pathspec check. They now run through
    `backend/scripts/lib/main-checkout-fallback.mjs`, which borrows the main checkout's
    `node_modules` and `.env`, and print one "skipped" line when neither checkout has them.
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
  - 🔴 **Run a positive control on any detector that reports "nothing found."** Two detectors were
    silently broken on 2026-09-04 and only a control exposed them: a file-mtime scan whose
    threshold predated the checkout, and a `curl` sweep where the host had begun 403-ing every
    request, turning "this file does not exist" into "you are being blocked". The general form of
    this rule, and the part about watching the control FAIL first, is in **Verification rules**
    below.

## Verification rules that each cost a real failure

Every rule here is in the file because skipping it broke something. They are about *checking* —
they belong to no one subsystem, so they sit on their own rather than inside the section where
each was first learned.

- 🔴🔴 **A UNIFORM ANSWER IS A BROKEN DETECTOR UNTIL A POSITIVE CONTROL PASSES — AND THE CONTROL
  MUST BE WATCHED FAILING FIRST.** A control that has only ever passed proves nothing: it can pass
  for the wrong reason, an earlier gate can shadow the one you meant to test, and a tamper that
  cannot trip the comparison tests nothing at all. Plant the fault, see the detector go red, then
  remove it and see it go green.
  - ⚠ **A control proves a verifier CAN fail. It does not prove the verifier reads the RIGHT
    ROWS** — for that, check the count it actually examined.
  - 🔴 **A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, AND IT LOOKS LIKE A PASS.**
    On 2026-10-26 a `sed` that built a tamper file failed on a quoting error, left a **0-byte**
    file, and `dry-run-migration.mjs` reported **`DRY RUN OK`** on it — an empty migration passes
    every gate it does not contain. **Assert the tamper is PRESENT in the file before running it**
    (grep for a marker, or build it in a script that exits non-zero when the replacement misses).
  - 🔴 **A CONTROL CAN FAIL CORRECTLY, FOR THE WRONG PROPERTY, AND STILL MISS THE DEFECT.**
    `ev-jobs-legiscan` died of heap exhaustion; the fix shipped a real control proving a repeat
    read re-parses — that nothing is **retained** — and the job died again, because the defect was
    **allocation on the first read** (26,707 entries inflated back to back to read one integer).
    Removing retention is not removing allocation. **Ask what the defect's MECHANISM is and pin
    that**, not the nearest property that is easy to assert.
  - Change one thing per tamper. A tamper that trips three assertions at once tells you the suite
    is alive but not which guard holds which claim.
- 🔴🔴 **A PREDICATE READS THE SHAPE OF A VALUE, NEVER WHAT THE VALUE IS.** Before naming or acting
  on the class some `WHERE` clause catches, `GROUP BY` the discriminating field and read a sample
  of real rows. **Deleting raises that bar, it does not lower it.** ⚠ A lookalike key can be a
  clean permutation of a real one, so "this looks malformed" is a hypothesis, not a finding.
- 🔴🔴 **GREEN CI IS NOT "THE SERVER BOOTS".** Four deploys have gone out green and failed to
  start. Boot the built artifact against a **dead** `DATABASE_URL` and watch it come up; and note
  that `npm install` passing is not `npm ci` passing — the lockfile is what the deploy resolves.
- 🔴🔴 **PUT THE DIAGNOSTIC WHERE THE PROCESS CAN STILL REACH IT.** A summary printed after the
  loop teaches a crash nothing. Log the size before, and progress from inside. For memory,
  `heapUsed`, `external` and `rss` are three different answers — print all three, because the one
  that grows tells you which thing is leaking.
  ⚠ **A green run can be a no-op.** Read what it says it did, not just its exit code.
- 🔴🔴 **`WebFetch` FABRICATES NAMES AND DATES AND FORMATS THEM AS QUOTATIONS.** It once invented
  four officeholder names and three district labels and presented them as quoted text from the
  page. Use it to LOCATE a document; never source a **name, a date or a count** from it. A web
  search summary is a lead, not evidence — open the page and read it.
- 🔴 **A WAF REJECTION CAN BE HTTP 200 OR 202, so never judge a fetch by `r.ok`.** F5 WAFs on
  government hosts reject Node's `fetch` on its TLS fingerprint and answer 200 with a challenge
  body; `curl` and Python `requests` get through. A 403 that persists even with a browser
  `User-Agent` means **fetch it in Playwright**. Wikimedia 429s a generic UA. ⚠ The inverse
  happens too, and a challenge may cover **pages** while leaving **files** open.
- 🔴 **ONE DENIED COMMAND IS NOT A BLOCKED PATH.** Try a different shape before reporting a
  capability as unavailable — and **never print a secret's value** while doing it. ⚠ An
  unexplained break from the normal workflow usually means "I am doing this wrong", not "the
  environment changed".
- ⚠ **A WORKAROUND SIZED IN UNITS OF A BUG OUTLIVES THE BUG FIX.** When a constant is chosen to
  dodge a defect, write down what it is dodging, or it becomes permanent and nobody can say why
  it is that number. 🔴 Render instance of the same thing: **`NODE_OPTIONS` applies to the BUILD**,
  so a heap flag meant for a job belongs on that job's START command.
- **Image sourcing is measured, not eyeballed.** A no-monochrome rule that is not enforced in code
  is not enforced — unenforced it cost 156 frames. **A badge is portrait-shaped: look at the image
  before accepting it as a headshot.** **A bare CDN URL is not the original** — both the resize and
  the quality loss can be hiding in the query string.

## Repo facts worth knowing

- Party affiliation is **antipartisan** by design: party lives on `races.primary_party` (which ballot
  a voter requests), never on `race_candidates`.
- `geofence_boundaries.state` holds **2-digit FIPS**, not USPS codes.
- 🔴 **`districts.geo_id` IS A LOOKUP KEY, SO AN EMPTY ONE IS A KEY NOTHING CAN EVER MATCH.** A
  district with `geo_id = ''` is invisible to every `geo_id`-keyed read — today that is the
  `government_bodies` join in `DISTRICT_SELECT_FIELDS`, which simply never fires for it. The seats
  still answer an address, because the statewide branch admits by `district_type` + `state`, so
  nothing looks broken. `gen-state-exec-seed.mjs` already RAISEs on an empty `STATE_EXEC` geo_id
  for the states it covers; `CC_0297` fixed the last multi-office one outside that list (Indiana's,
  10 offices). ⚠ One single-office case is left on purpose — California's Board of Equalization
  seat, which needs a BOE-district geo_id, not the state FIPS.
  - ⚠ **A SHARED DISTRICT HOLDING SEVERAL OFFICES IS A LEGITIMATE VARIANT, NOT A DEFECT.** Measured
    across all 51 jurisdictions: 48 give each statewide executive its own district; CA (17 offices),
    OR (5) and IN (10) share one. Do not "normalise" one of those into per-office districts — check
    whether its key is wrong before deciding its shape is.
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

**Gate:** `node backend/scripts/audit-chair-evidence.mjs --check <rollback.json>` fails if any row it lists
carries reasoning that names no instrument, act or vote. Run it before committing any migration that
sets a chair.

### Pre-staging research into a DRAFT season (`--season`)

Every stance-research step takes `--season open|draft|<uuid>` (default `open`, unchanged): bundle
(`build-stance-topic-bundle.ts`), `code-stance-batch.ts`, `queue-coded-batch.ts`,
`verify-stance-research.ts`, `export-written-ledger.ts`, and `gold-desk/build_batch.py`. Pass the SAME
value to each step: a non-open bundle writes `<dir>/season.json`, and a step run against another
season exits 2. A **closed** season is always refused.
- The draft ladder is the draft season's pin, served as ADR 0006 will serve it once it opens — so an
  `approved`, not-yet-published revision counts (`servedRevisionLateral(..., {includeApprovedWhen})`).
  The open season's served text still means published/superseded only.
- Writes carry the draft season's id (`UPSERT_*_IN_SEASON_SQL`, evidence via `accumulateEvidence(..., {seasonId})`).
  A review-queue row whose `season_id` is a draft season approves into THAT season (`resolveResearchReview`).
- 🔴 **Voters must not see it.** Every reader of `politician_answers` / `politician_context` /
  `politician_context_evidence` excludes draft (`SEASON_IS_PUBLISHED`) or declares `@draft-reads: ADMIN-ONLY`;
  `draftSeasonWrites.test.ts` scans for a new unguarded one. A draft run does not stamp
  `last_stances_researched_at`.

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

### Scope decides the evidence, not whether a position exists (ruling 2026-10-06, Chris Andrews, option B)

This replaces the 2026-08-28 ruling "Scope is a per-rung question, not a per-topic one", which said a
chair evidenced only by opinion at a level is "the exact shape the evidence standard refuses". The
operator's reason: *"I would want to know whether my local mayor thinks the 2020 election was stolen or
her position on abortion, even if she can't change the laws on that."* Memo:
`.planning/todos/2026-10-06-positions-without-a-lever.md` (workspace root).

- **Which topics a level is ASKED** — every topic, at federal, state and local, unless there is a good
  reason not to. Named exclusions: judges keep the judicial topics only and judicial topics stay
  judge-only; **school boards keep the school topics only** (the 2026-09-24 rung-by-rung school ruling
  stands, for now); local-only topics ("your community") are not asked of federal or state officials
  until their question text reads at every level. Recorded in `compass_topic_roles` (CA_0302).
- **What evidence can seat a chair** — still a per-rung question. **A record needs a lever**: a rung no
  officeholder at this level can act on cannot be evidenced at this level by a record. **The person's
  own words can** (codebook V2 "No-lever level"). `compass_topic_roles.evidence_basis` marks a
  (topic, level) `own-words` when no rung has a lever there.
- **Before adding a topic or a level**, still read every rung and ask whether an officeholder there
  holds a lever on it. The answer now sets the evidence basis, not whether the level is asked.
- **Voters see no label** — they see the sources (the evidence chain). An own-words chair is compared
  with the voter's view like any other chair.
- 🔴 **An own-words chair is a separate reliability stratum.** A certification measured on `record` rows
  never covers it; own-words rows go to review until that stratum has its own blind gold.
- The election-cycle rule for statements (codebook V5, Q4) applies unchanged.
- **What a voter sees is decided by the lenses, not by `compass_topic_roles`.** The essentials compass
  draws its spokes from the active lens's curated topic list (or the voter's own compass), and with no
  lens the stance breakdown lists every topic the official answered. `applies_*` only narrows the pool
  under the Local Lens, and drives tier badges, coverage counts and the stance-research gate.
- ⚠ **Legacy out-of-scope chairs exist and are already visible** in that breakdown (Season 1 research at
  levels that were not asked, e.g. local `taxes`, `deportation`, `same-sex-marriage`). They are owed a
  re-audit under the codebook; adding a role row does not change whether they show.
