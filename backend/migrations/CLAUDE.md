# backend/migrations — occupancy, migrations and jurisdiction claims

Moved here from the root `CLAUDE.md` (2026-11-12) so that only sessions working on data, seeds and migrations
load it. Nothing was cut: the root file keeps a short pointer to each section. `backend/src/CLAUDE.md` imports
this file, because the read path needs the occupancy rules too.

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

🔴🔴 **THE VIEW IS MOSTLY CANDIDATES, NOT OFFICEHOLDERS.** Roughly **84.5k** rows against **~9.7k**
with occupancy evidence (both figures drift). To restrict a read to evidenced holders, filter
`is_placeholder_occupancy = false` on `essentials.politician_occupancy_evidence` — **not** on the
view, which has no such column. ⚠ **Never delete the placeholder people**; they are candidates, and
other subsystems hold them.

🔴 **`office_current_holder` LEFT JOINs FROM `offices`, SO A VACANCY IS A ROW WITH A NULL
`politician_id` — AND `count(*) = 0` PASSES VACUOUSLY.** A gate written as `count(*)` counts the
empty seats too and reports success over a table that seated nobody. **Count `och.politician_id`.**

⚠ **`unaccent` IS NOT INSTALLED ON PROD.** A name comparison that reaches for it works locally and
fails in production; fold accents in the application, or compare on a column you already store.

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

**Measured 2026-10-27: `293 / 55 / 238`** (`CC_0300` seated Cornelius OR and `CC_0301` seated
Caledonia WI; both were in the FLAGGED bucket, so total and flagged each fall and the 238 baseline
does not move; was `295 / 57 / 238` on 2026-10-26, and `433 / 194 / 239` on 2026-10-20; the 136 that left
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
`is_vacant` office and not just those in the view: **63 flagged, 41 dated, 22 undated** (was
65 / 24 / 41 before `CC_0298`, and 64 / 40 / 24 before `CC_0301`). An undated flag asserts a
vacancy to voters and keeps the row out of the drift metric. **Do not read a stable 238 as
"occupancy is clean".**

🔴 **AN UNDATED FLAG CANNOT TELL YOU WHICH KIND OF THING IT IS, AND THERE ARE FOUR KINDS.**
`CC_0298` classified all 41 undated flags one at a time, and only 16 of them wanted a date:

| kind | n | what it needs |
| --- | --- | --- |
| real vacancy, date citable | 16 + 1 | ✅ `CC_0298`; `CC_0301` added Three Valleys MWD Division 3 |
| real vacancy, date not published | 1 + 1 | **nothing but an explanation in `description`** — Richland County SC SWCD, and now Torrance USD Trustee Area D (`CC_0301`). That is the correct shape |
| ~~not vacant, a holder exists~~ | 2 | ✅ `CC_0300` Cornelius OR, `CC_0301` Caledonia WI |
| **not vacant, awaiting its FIRST election** | 20 | explain it (`CC_0299`), then seat the winner |
| ~~unseeded, emptiness unproven~~ | 3 | ✅ `CC_0301` — and the three came out **three different ways** |

🔴 **"UNSEEDED, EMPTINESS UNPROVEN" IS A QUEUE OF SINGLETONS, NOT A BATCH.** The last three rows
of this triage were checked against their own bodies' rosters and no two wanted the same thing:
Three Valleys MWD Division 3 was vacant **with the date published on the district's page**;
Torrance Area D was vacant with **no date published anywhere**; Caledonia WI Seat 2 **was not
vacant at all**. Check them one at a time, against the body's own roster.

🔴 **READ WHAT A SOURCE'S DATE IS A DATE *OF* BEFORE ADJUSTING IT.** `CC_0298` wrote
departure + 1 because Ballotpedia publishes the member's LAST DAY. Three Valleys publishes
"Vacant Effective June 3, 2026" — the date the vacancy TAKES EFFECT, which is already the first
empty day, so it is written unadjusted. Same field, opposite handling, because the sources
measure different events.

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

🔴 **THE TWO HELPERS ARE NOT SYMMETRIC ABOUT THE FLAG, AND THE NAMES SUGGEST THEY ARE.**
`vacate_office` SETS `is_vacant`/`vacant_since`. **`seat_officeholder` DOES NOT CLEAR THEM** — it
only writes `office_terms` and never touches `essentials.offices`. So **seating someone into a
flagged seat leaves it held AND vacant**, which is exactly the `is_vacant` trap below: a filter
applied after the match emits a spurious all-NULL office row for the holder you just seated.
Clear the flag yourself in the same migration and assert it:

```sql
UPDATE essentials.offices SET is_vacant = false, vacant_since = NULL WHERE id = <office>;
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
- 🔴 **`politicians.is_incumbent` WAS DROPPED (CA_0378). Incumbency is derived, never stored.**
  It was a cached copy of `office_terms`: it defaulted to `true` until `CA_0188` (1,817 active
  "incumbents" with no seat, cleared by `CA_0181`-`CA_0187`), then went stale on every seeded
  handover date (Reno, 2026-11-13). Reads use `isIncumbentSql()` / `IS_INCUMBENT_SELECT_SQL` in
  `backend/src/lib/incumbency.ts`; seat someone with `seat_officeholder` and nothing else.
  `check:occupancy` fails an INSERT that still names the column. `race_candidates.is_incumbent` is a
  different, still-live column.
- **`politicians.valid_from` / `valid_to` are DEPRECATED** — wrong entity (dates belong to a tenure,
  and people hold two offices). Don't read them in new code. `politicians.office_id` is a legacy
  point-in-time snapshot with the same flaw; prefer the view.
- 🔴 **`term_end IS NULL` IS NOT "CURRENT".** An open-ended term can also be a row nobody ever
  closed. Ask for **date containment** against the span, which is what the view does; a
  `term_end IS NULL` filter quietly returns stale tenures beside live ones.
- 🔴 **THREE PLACES HAVE NO INBOUND FOREIGN KEY, SO A DELETE CORRUPTS SILENTLY INSTEAD OF
  ERRORING:** `districts` (deleting one **orphans its offices**), `chambers.government_id`, and
  `politicians.office_id`. **Repoint before deleting**, and gate on the END STATE rather than on
  the delete's own row count.
- 🔴 **AN `external_id` COLLISION SEATS THE WRONG PERSON, AND NOTHING ERRORS.** The upsert finds an
  existing row by that id and writes your term onto it. Assert the id is unseen, or that the row it
  matched carries the name you expect, before you write.

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

- 🔴🔴 **NAMESAKES REACH PRODUCTION, AND NOTHING ERRORS.** A full-name match is not an identity —
  this repo has shipped **Mark Harris as NC-8**, and a 2026-11-02 audit found two more live:
  the portrait on Bell CA's **Ali Saleh** was *Ali Abdullah Saleh, the late President of Yemen*,
  and Manhattan Beach's **Joe Franklin** was *the New York talk-show host*. ▶ Check a person
  against **the body's own roster**, not against a name search, and open the image.
- 🔴 **BALLOTPEDIA PUBLISHES BOTH *APPOINTED* AND *ASSUMED OFFICE*, AND ONLY THE SECOND IS A
  `term_start`.** An appointment date precedes the tenure and sometimes by weeks.
- 🔴 **BALLOTPEDIA'S OWN EXPLANATORY NOTE CAN BE STALE WHILE ITS TABLE IS CURRENT — AND THEY
  CONTRADICT EACH OTHER.** Read the data, not the prose above it.
- 🔴 **"SHALL BE ELECTED" DOES NOT MEAN "ELECTED BY VOTERS".** A charter clause often means elected
  *by the body, from among its members* — a rotating chair, not a seat on the ballot. **Read who
  elects** before creating an office or seating a winner.
- ⚠ **WHAT A BODY PUBLISHES IS A FINDING, NOT A SEARCH FAILURE.** When a roster gives photographs
  for 12 of 28 members, that is the body's practice and the answer to the question. Record it;
  do not keep hunting for a completeness that does not exist.

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
- 🔴 **A MIGRATION THAT OVERWRITES A VALUE MUST RECORD THE VALUE IT OVERWROTE, IN ITS OWN HEADER.**
  There is no history table for most columns, and no `schema_migrations` to replay from, so an
  `UPDATE` is final: the previous value exists nowhere the moment it commits.
  - ⚠ **This cost a full production clone on 2026-10-27.** `CA_0335` replaced four
    `users.display_name` values with generated pseudonyms, recording only the new ones. Undoing it
    needed a Supabase "restore to a new project" of the whole database to read back four strings
    — and the clone inherits `pg_cron` and `pg_net`, so it began firing this repo's scheduled jobs
    at **production** the moment it came up (`cron.unschedule` every job before any read).
  - 🔴 **It also destroyed the evidence for its own premise.** `CA_0335` said all four rows showed
    a real name. They did not — two were invented handles. Nobody could check, because the values
    were gone. **Write the old value down and the claim stays testable.**
- 🔴🔴 **THE DRY-RUN AND APPLY TOOLS ALREADY EXIST — `ls backend/scripts/` BEFORE WRITING ONE.**
  `dry-run-migration.mjs` and `apply-migration-file.mjs`. They have been replaced with worse
  hand-rolled copies more than once.
  - 🔴🔴 **`dry-run-migration.mjs` ONCE COMMITTED TO PROD WHILE PRINTING "ROLLED BACK".** It strips
    only the **FIRST** `BEGIN`/`COMMIT` pair, so a file holding two migrations has its second one
    run and committed for real. **ONE MIGRATION PER FILE — NEVER CONCATENATE.** Guarded in #1235;
    the guard does not make the rule optional.
- 🔴 **"APPLIED TO PROD" IS NOT "ON MASTER".** There is no `schema_migrations` table, so **the file
  is the only record that a migration exists**. Data alone cannot tell you whether the file was
  ever merged — a migration can be live in production and absent from the repo. **Check the PR,
  not just the data.**
- 🔴 **`ev_api` CANNOT REACH EVERY SCHEMA — `apply-migration-file.mjs` FAILS ON `civic_spaces`**
  with `permission denied for schema civic_spaces`. That is not a broken credential; it is the
  role. Apply such a migration through the Supabase MCP, which connects privileged.
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
- 🔴 **WRITING A `term_start` RESTATES WHO HELD THAT SEAT ON EVERY ELECTION DAY THE TERM NO LONGER
  COVERS — AND `race_candidates.is_incumbent` IS CACHED AND DOES NOT FOLLOW.** `check:incumbency`
  catches the contradiction, but it runs on **master push and the schedule only, never on a PR**, so
  it fails on the NEXT merge under somebody else's name. That is the master-only-gate rule under
  **Verification rules** (root `CLAUDE.md`), and `CC_0394` paid for it: 290 dates, 6 red rows, a 7th from `CC_0395`, and
  `CC_0396` to settle them three migrations later. Paste the delta gate from
  `backend/migrations/_templates/office_terms_incumbency_guard.sql` into any migration that writes
  `essentials.office_terms` — it fires only on a row **this transaction** moves from agreeing to
  contradicting, so other people's drift cannot fail your merge. State a
  `-- @incumbency-decision: <gated|no-effect> — why` line; `npm run check:office-terms-guards --prefix
  backend` enforces it (CI job "static guards", **which does run on PRs**). 253 applied migrations are
  grandfathered by number — but a file **added on your branch binds whatever its number is**, because
  a slot is reserved long before its file exists and `CC_0340` is sitting reserved, unwritten and
  below every floor for exactly this kind of work.
  ⚠ **Do not answer it with `reconcile-incumbency.mjs --apply`** — it reads only the predicate, and
  on those seven rows it would have published three sitting officeholders as challengers for their
  own seats. ⚠ **The two causes look identical from the row**: a *newcomer* means the date is right
  and the race row is stale; *re-elected* means the race row is right and you have written their
  latest term's start as the start of their whole tenure. `CC_0396`'s header works the split.
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


## Jurisdiction claims (the steward board)

Moved from the root `CLAUDE.md` section "Working alongside other sessions", which keeps the worktree and commit
rules. Take a lease before working a place, a county or a state.

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
