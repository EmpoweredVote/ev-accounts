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
- 🔴 **Set `politicians.is_incumbent` explicitly on every insert** — `true` when you seat the person,
  `false` for a candidate or former officeholder. It is a cached flag the incumbents-only reads filter
  on. It defaulted to `true` until `CA_0188`, and that created **1,817 active "incumbents" with no
  seat** (cleared by `CA_0181`-`CA_0187`). It defaults to `false` now, so a seated person inserted
  without it is **hidden** from address search. `check:occupancy` fails an INSERT that omits it.
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
- 🔴🔴 **A DUPLICATED REGISTRATION IS NOT A TEXT CONFLICT, SO NEITHER THE MERGE NOR THE DRIFT
  REPORT CAN SEE IT.** Two branches that add the same `vi.mock`, import, route or handler **in
  different places** merge cleanly, and the later copy silently wins. Measured 2026-11-10: merging
  master into `feat/fc-seasons-api` left master's `roleService` mock followed by this branch's
  older copy of the same mock, so `getCachedUserRoles` returned `[]` for every caller and **five
  curation tests answered 403 instead of 200** — in a file git had auto-merged without a murmur.
  ▶ **RUN THE TESTS AFTER A MERGE GIT CALLED CLEAN.** And read `steward who`'s conflict list as a
  floor: it names the files that collide as *text*, never the ones that collide as *meaning*.

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
- 🔴🔴 **BEFORE ANY `git worktree remove`, SCAN FOR A `node_modules` JUNCTION — REMOVAL DELETES
  STRAIGHT THROUGH IT.** A junction planted to save a reinstall is followed by the delete, and it
  has **emptied the main checkout's `node_modules` twice**. ⚠ **`check:deletable` is silent on
  this** — it is not one of the four checks. Look with PowerShell (`Get-ChildItem -Directory` and
  read `LinkType`), and `rmdir` a junction you made yourself as a control before trusting the scan.
  ▶ **Do not plant junctions**; run tooling from the main checkout with an absolute `--dir`.
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
- 🔴🔴 **A GATE NO CONTROL REACHES IS A GATE NOBODY HAS TESTED, AND TWO GATES CATCHING ONE FAULT
  IS WHAT HIDES IT.** Gates run in order, so a tamper stopped by an earlier one says nothing about
  a later one — and the earlier gate firing looks like success. `CC_0376` planted three label-swap
  tampers before one reached its point-to-member chain gate: the first was stopped by an
  incumbent-consistency check, the second by a gate the first tamper had just bought. Only a
  tamper that leaves every other table correct and self-consistent tests the last gate in a chain.
  ▶ **Track which gate each control fires on, not just that it went red.** A gate with no control
  of its own is untested however many controls the file has.
- 🔴🔴 **A UNION OR COVERAGE GATE CANNOT SEE WHICH VERSION OF A MAP IT HAS, AND ITS NUMBER WILL NOT
  EVEN WOBBLE.** Two complete partitions of the same area have *identical* unions by construction,
  so every coverage, overlap and bounding-box measure agrees to the last decimal. Measured: New
  Hampshire's superseded 2012 councilor map covers the TIGER state outline to **99.6836%, the same
  figure as the 2022 map to four decimal places**, and differs from it on 66 of 259 towns.
  ▶ Only evidence about **which district a NAMED PLACE belongs to** separates two vintages. Where
  a statute names places (New Hampshire names all 259), that is the strongest anchor available —
  stronger than a county composition, and it leaves no district unpinned.
- 🔴🔴 **A FLAT CONTROL TESTS NOTHING, AND A CONTROL DERIVED FROM THE DATA UNDER TEST MOVES WITH
  THE DEFECT.** A blank grey frame proves a detector can return "nothing"; it proves nothing about
  what the detector does with real input. Worse, a threshold or baseline computed *from the same
  rows you are checking* shifts when they shift, so the check silently follows the fault instead of
  catching it. **Derive the control independently of the data under test.**
- 🔴🔴 **A CONTROL SET THAT IS UNIFORM IN A PROPERTY THE DETECTOR DEPENDS ON CANNOT TEST THAT
  PROPERTY — AND IT PASSES WHILE A WHOLE CLASS OF INPUT WALKS THROUGH.** This is the companion to
  "a uniform ANSWER is a broken detector", with the uniformity sitting in the *controls* instead of
  the output. `check-portrait-framing.mjs` had two fixtures, a **green** matte and a **white**
  matte, and a centre test that asked "is the middle the same colour as the surround". Neither
  colour can occur in a human subject, so no fixture had ever exercised a **dark** surround — and a
  pure-black border passed the gate, because dark hair, a dark jacket and shadow are near-black in
  every portrait, so **the subject itself voted the frame innocent**. Both controls were green
  throughout. ▶ **List what your fixtures hold constant, and add one that varies it.** A second
  fixture of the same kind is coverage of nothing.
  - 🔴 **TWO DETECTORS CAN BE COMPLEMENTARY RATHER THAN REDUNDANT, AND GEOMETRY DECIDES WHICH.**
    The same gate could not see a rectangular frame *structurally*: a disc of full width touches
    the left and right edges at their midpoints, so **no side of a disc image is flat along its
    whole length**. A per-side test sees a letterbox and a corner-and-diagonal test sees a disc,
    and neither can be made to see the other by moving a threshold. **Ask whether the shape you
    missed is reachable by the measurement you have before you retune it.**
  - 🔴 **A PREDICATE OF SEVERAL `&&` CONDITIONS FAILS FOR EXACTLY ONE REASON, AND NOTHING PRINTS
    IT.** That gate reported only its flagged rows, so a passing row produced **no numbers at all**
    and the verdict was readable while the evidence for it was not. ▶ **Print every row a detector
    scanned, not only its hits** — otherwise "why did this pass?" costs a re-implementation.
- 🔴🔴 **A COUNT OF EVENTS THROWS AWAY THE MEASUREMENT OF THE EVENTS, AND THE MEASUREMENT IS
  USUALLY THE ANSWER.** `check-portrait-framing.mjs` walked the four corner diagonals of an image
  and asked **how many** of them left the matte. A circular crop answers four. A person cut out on
  plain white answers four as well — so over the 9,481 published headshots the gate flagged 44 and
  **33 of them were real photographs**. The number it already had and discarded was **how far
  along each diagonal** the surround ended: a disc is round, so all four are the same, while a
  person ends at their hair on the top two and their shoulders on the bottom two. The three
  positive fixtures read 0, 1 and 3; every real manufactured surround in the corpus read 0–2; the
  nearest real photograph read 8. One term, 44 flags down to 12. ▶ **When a detector counts
  occurrences, ask what it measured to find them and whether that number discriminates.**
  - ⚠ **A TUNING PASS NEEDS THE WHOLE CORPUS, NOT THE SET THAT PROMPTED IT.** The repair before
    this one was measured over 36 images and reported **zero false positives**; the first 500
    random published headshots produced one, and all 9,481 produced 33. The 36 were the batch
    being worked on, so they were uniform in exactly the thing that was wrong. **Nothing about a
    detector's error rate is known until it has been run over the population it will police.**
  - 🔴 **TWO GATES OVER ONE CORPUS ARE NOT REDUNDANT WHEN THEY ASK DIFFERENT QUESTIONS, AND THE
    SECOND ONE'S FINDINGS ARE INVISIBLE TO THE FIRST.** Every one of the 11 real framing defects
    had **passed** `check-headshot-faces.py` — two of them are the **State Seal of Washington** and
    the **Great Seal of North Carolina**, which contain a portrait, so a face detector clears them
    honestly and correctly. "We already check the headshots" is not an answer to "do we check
    *this*".
  - 🔴 **A FLAGGING GATE NEEDS ITS BACKLOG WRITTEN DOWN AS DEFECTS, NOT AS ACCEPTANCES.**
    `data/headshot-framing-known.json` keys on **(url, sha256)** like `headshot-accepted-flags.json`
    — the hash is the load-bearing half, because our storage overwrites a file **in place** at the
    same URL — and every entry must declare which of two opposite things it is: a **defect** that
    is still published and still owed a re-source, or an **accepted** row the gate reads wrong,
    with the reason. Both suppress the red; only one is a queue. **A defect filed as an acceptance
    is a defect nobody will ever fix.**
- ⚠ **A UNIFORM PROBE RESULT CAN BE A PROPERTY OF YOUR SAMPLE, NOT OF THE DATA.** Before concluding
  "they are all like this", check that the sample was not itself selected by the thing you are
  measuring.
- ⚠ **A PERCENTAGE COLUMN MAY BE COUNTING BLANKS IN ITS DENOMINATOR** — a reported 47.5% was really
  58.2%. Ask what the denominator contains before quoting a rate.
- 🔴 **A MASTER-ONLY GATE CANNOT VET THE MERGE THAT TRIPS IT.** It reads production data and runs
  after the merge, so it fails on *the next* PR and names an innocent author. Carry the check into
  the migration's own post-verify, as a delta, if you need it to block the guilty change.
  - 🔴🔴 **AND APPLYING A MIGRATION BEFORE ITS READ-PATH CODE MERGES HOLDS THAT GATE RED FOR
    EVERYONE, FOR AS LONG AS THE BRANCH STAYS OPEN.** The gate reads **production data with
    MASTER's code**, and those two are different things that can disagree for days.
    `CC_0366`-`CC_0372` created Colorado's and Louisiana's board districts in production while
    the `X-ST-BOARD` line that makes them readable sat unmerged in `districtQueries.ts` and
    `geoIdGuard.ts`. `check:reachability` reported **`UNREACHABLE` 20 against a baseline of 7**
    — new buckets `co|STATE_BOARD` 8 and `la|STATE_BOARD` 5 — and failed **four consecutive
    master runs**, every one of them somebody else's merge. Merging the PR took it straight back
    to 7 with no baseline change: the gate was right the whole time and the branch was late.
    🔴 **So do not raise the baseline to clear this red** — see § Officeholder occupancy, *never
    raise it at all*. ▶ **A districted body on a new `X…` layer is not safe to apply to
    production until its registration is on master.** Land the migration and those two code
    lines together, or merge the same day you apply.
- 🔴🔴 **A TRUNCATED DISPLAY MANUFACTURES FINDINGS, AND IT BIASES THEM TOWARDS LOOKING LIKE
  DUPLICATES.** Cutting a column to fit makes distinct values collapse onto one another, and that
  collision is exactly the shape of a real defect, so the artefact reads as a discovery. On
  2026-11-02 a report column formatted a district label with `.slice(0, 24)` — and
  `"Congressional District "` is exactly 23 characters — so every two-digit district printed as
  its first digit alone. Two different candidates appeared to share one implausible district,
  which was reported as a race-mapping bug and was retracted: both were mapped correctly.
  ▶ **Print the field at FULL WIDTH before believing a pattern in it, or read the stable key
  beside it.** `ocd_id` carried the right answer throughout and was never displayed.
  - 🔴 **A NORMALISATION STEP MANUFACTURES THE SAME SHAPE, AND IT LOOKS LIKE TWO SOURCES
    DISAGREEING.** `CC_0377` cross-checked LA County's JSON against the same county's
    server-rendered page and three candidates came back "absent from the text page" — a
    disagreement about who was on the ballot. The pages write accents as numeric entities
    (`LA CA&#xD1;ADA`, `ERIK PE&#xD1;A`) and the parser did not decode them. ▶ **Before
    reporting a mismatch between two readings, ask what your own pipeline does to the field —
    and give the comparison a positive control that names a row it must be able to see.**
- 🔴🔴 **BOUND A PARSE BY THE DOCUMENT'S OWN STRUCTURE, NEVER BY A BLACKLIST OF WHAT ELSE MIGHT
  BE IN IT.** A section reader that stops at a list of headings you thought of cannot see the
  heading you did not, and everything after it is read as part of the section before — with a
  plausible value, not an error. Nebraska's 2024 canvass book prints "Judge of the District
  Court", "District 3", "Lancaster" a few pages past the Board of Regents, so a blacklist that
  had not thought of judges would have recorded Lancaster County as part of **Regents District
  3**. Take each section's page range and stop-title from the book's **own table of contents**
  instead (`backend/data/state-exec-2026-results/parse-ne-canvass-counties.mjs`).
  ▶ It applies to any delimiter you supply from outside the document: ask what the document
  itself says its parts are.
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
- 🔴 **A CLEAN HTTP 200 LIES IN AT LEAST FIVE WAYS**, and each one reads as success: an ACS or API
  host returning an **HTML error page**; **TIGERweb layer 0** answering for a layer that holds
  nothing; a **parked domain**; a **truncated body** — check `Content-Length` against what you
  received; and a **soft 404**, a "not found" page served as 200. Assert on the *content* you
  expected, never on the status code alone.
- 🔴 **A WAF REJECTION CAN BE HTTP 200 OR 202, so never judge a fetch by `r.ok`.** F5 WAFs on
  government hosts reject Node's `fetch` on its TLS fingerprint and answer 200 with a challenge
  body; `curl` and Python `requests` get through. A 403 that persists even with a browser
  `User-Agent` means **fetch it in Playwright**. Wikimedia 429s a generic UA. ⚠ The inverse
  happens too, and a challenge may cover **pages** while leaving **files** open.
- ⚠ **READ THE BODY OF A 503 BEFORE CALLING A HOST DEAD.** Government sites commonly answer 503
  with "site is being rebuilt" or a maintenance notice — a temporary state with a successor URL in
  it, not an outage to retry forever.
- ⚠ **A PUBLISHER'S OWN HUB CAN SERVE A SUPERSEDED MAP**, with the same district count over the
  same area and different answers per address. A plausible count is not evidence of the right
  vintage — check which map legally governs.
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
- `geofence_boundaries.state` holds **2-digit FIPS**, not USPS codes — ⚠ **EXCEPT ON THE `G4000`
  STATE-OUTLINE LAYER, WHERE IT HOLDS USPS.** Measured 2026-11-08: of its 53 rows, 52 carry
  `'NH'`, `'CA'`, … , one carries `'72'` and one is NULL. So a state-outline lookup written the
  way this line used to read — `mtfcc = 'G4000' AND state = '33'` — returns **nothing**, and an
  empty result reads as "we hold no outline for this state", which silently SKIPS a coverage gate
  rather than failing it. 🔴 **Key the state outline on `geo_id`** (`geo_id = '33'`), as the
  tier-3 loaders do.
- 🔴 **`geo_id` IS NOT UNIQUE — THE KEY IS THE PAIR `(mtfcc, geo_id)`.** Measured: **1,159
  collisions across 13 states**, because a place and a county subdivision can share a number.
  `geoIdGuard.ts` enforces the pair on the production write path; **ad-hoc SQL does not**, so a
  hand-written join on `geo_id` alone silently matches the wrong geography. ⚠ **`ocd_id` ROLLS UP,
  `geo_id` LOOKS UP** — they answer different questions and are not interchangeable.
- 🔴🔴 **A CITY CAN BE FULLY SEEDED, ANSWER EVERY ADDRESS, AND STILL BE INVISIBLE ON THE MAIN
  PAGE.** The landing chip keys on **`governments.geo_id`**, which address search never touches, so
  the two surfaces fail independently and neither one's success implies the other's. 🔴 **THE ONLY
  RELIABLE DETECTOR IS END-TO-END: does a city-hall point return a council member?**
  `check:reachability` runs on master-push and cron — **not on PRs** — and takes no probe list, so
  **green does not mean your districts were swept.**
- 🔴🔴 **SUPABASE STORAGE NEEDS BOTH `apikey` AND `Authorization` HEADERS** (key `sb_secret_…`). A
  lone Bearer is refused as **HTTP 400 with a body saying 403 "Invalid Compact JWS"**, which reads
  like a missing object and sends you looking in the wrong place.
  - 🔴🔴 **STORAGE ANSWERS ON TWO HOSTNAMES** — `<ref>.storage.supabase.co` *and* `<ref>.supabase.co`.
    **Match on the PATH `%supabase.co/storage/v1/object/public/%`, never on the host:** a host-based
    `LIKE` once classified **1,279 of our own mirrored headshots as "hotlinked"**.
- 🔴🔴 **PROD AUTHENTICATES AS `ev_api`, AND A SUPABASE PASSWORD RESET ROTATES `postgres` ONLY.** So
  the break you will see is a **mismatched username**, not an expired secret. **Test a credential
  against a DATA endpoint** — `/api/health` touches no data and passes with a dead database.
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
- 🔴 **`districts.district_type` IS A ROUTING KEY TOO, NOT A TAXONOMY LABEL — PICK IT BY WHAT READS
  IT.** `buildStatewideQuery` admits a seat **by type**, and the list is closed:
  `NATIONAL_UPPER`, `NATIONAL_EXEC`, `STATE_EXEC`, `NATIONAL_JUDICIAL`, `JUDICIAL` (plus DC's two
  at-large `geo_id`s). **`STATE_BOARD` and `STATE_BOARD_EDUCATION` are not in it.** Those reach a
  voter only through the geofence join, keyed on a particular `mtfcc` — `X0003` (Utah SBOE),
  `X-CA-SBOE` (California BOE), `G5220` (DC) — because every board filed under them is
  **districted**. ▶ **A board elected STATEWIDE AT LARGE belongs on `STATE_EXEC` with the state
  FIPS**, which is what Arizona's Corporation Commission already is.
  ⚠ `CC_0364` nearly filed Michigan's elected State Board of Education under
  `STATE_BOARD_EDUCATION` because that is the name that fits. It has no sub-state polygon, so all
  eight members would have been **unreachable from every Michigan address and nothing would have
  errored** — the same failure as an empty `geo_id`, reached from the other direction.
  - 🔴 **A DISTRICT IN A SEAT'S TITLE IS A CLAIM ABOUT THE CANDIDATE, NOT NECESSARILY ABOUT THE
    ELECTORATE. READ WHO VOTES.** Georgia's Public Service Commissioners each *reside* in a
    numbered district and are **chosen statewide**; Hawaii's OHA "Maui Resident Trustee" is elected
    by the whole state; Alabama's PSC "Place 1" and "Place 2" are ballot positions on an at-large
    commission. All three read as districted and none of them is, and all three were in the
    inventory of seats "blocked on real geometry" until somebody read the enabling text
    (`CC_0364`, `CC_0366`).
  - 🟢 **BEFORE IMPORTING A POLYGON, ASK WHETHER THE BODY REUSES ONE WE HOLD.** Colorado's State
    Board of Education and CU Regents are elected by **congressional district**, so `CC_0366`
    copied the eight `G5200` polygons inside the database — no download, no reprojection, and the
    CRS hazard cannot arise. A gate asserts each copy `ST_Equals` the district it claims to be;
    a point-in-polygon check is **not** enough, because a consistent permutation passes it.
  - ⚠ **A NEW `X…` LAYER NEEDS AN EXPLICIT LINE IN BOTH `districtQueries.ts` AND `geoIdGuard.ts`**
    unless its district type is `LOCAL`, `COUNTY` or `JUDICIAL`, which is all the `X%` catch-all
    admits. `X0003` → `STATE_BOARD_EDUCATION` is **not state-scoped**, so any state's K-12 board
    can use it as-is. ⚠ **`geofence_boundaries.mtfcc` is `varchar(10)`** — a longer layer name
    fails only at INSERT time, after every other gate has passed.
  - 🔴🔴 **TWO BODIES CAN SHARE ONE CUSTOM LAYER INSIDE ONE STATE, SO SCOPE EVERY QUERY BY THE
    `geo_id` PREFIX AS WELL.** Nebraska's Public Service Commission and its Board of Regents are
    **both** `(X-ST-BOARD, STATE_BOARD)` in state `31`. Louisiana's commission and Colorado's
    regents sit on that layer too, but in **different states** — so `(mtfcc, state)` was a unique
    key by accident, everywhere, until Nebraska. A row count, a coverage test, or a "does this
    body already exist" pre-gate keyed on `(mtfcc, state)` alone silently reads the two bodies as
    one: without the prefix the `CC_0373`-`CC_0375` loader reports **13 rows where 8 are
    expected**, and `CC_0375` refuses to run once `CC_0373` has been applied. ▶ The prefix is the
    body — `ocd-division/country:us/state:ne/regents:%` — and controls on both the loader and the
    migration prove the scoping is load-bearing.
- 🔴 **A MULTI-MEMBER STATEWIDE BODY IS ONE CHAMBER, ONE SHARED DISTRICT, N UNNUMBERED OFFICES, AND
  ONE RACE CARRYING `seats = N`.** Arizona's Corporation Commission is the pattern (5 offices all
  titled `Commissioner`); `CC_0364` built seven more on it — HI's Office of Hawaiian Affairs (9),
  Michigan's State Board of Education (8) and MSU's trustees (8), and the ND, OK, SD and TX
  commissions (3 each). **Create the whole body, not the seats that were up**: `chambers.official_count`
  states the size, so a chamber short of it reads as a vacancy that is not there — and every office
  you create must be seated, or the 238 drift baseline rises. ▶ **Attach the race to the office of
  the member who is actually leaving**, sourced from the body's own term table; that office is what
  a seating pass replaces.
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
  never covers it; own-words rows go to review until that stratum has its own blind gold. **Passed for
  `voting-rights`** (Season 3, 2026-10-31: blind check run 4, 35 of 35 against a pre-set 34; `.claude/skills/
  season-topic-prep/RULINGS.md` "Own-words seats: the hold ends after a blind check"), and for **`gun-policy`**
  (Season 3, 2026-11-04: blind check run 1, 24 of 24 against a pre-set 23), so their own-words seats are approved
  like any other row. Every other topic keeps the hold until its own blind check passes.
- The election-cycle rule for statements (codebook V5, Q4) applies unchanged.
- **What a voter sees is decided by the lenses, not by `compass_topic_roles`.** The essentials compass
  draws its spokes from the active lens's curated topic list (or the voter's own compass), and with no
  lens the stance breakdown lists every topic the official answered. `applies_*` only narrows the pool
  under the Local Lens, and drives tier badges, coverage counts and the stance-research gate.
- ⚠ **Legacy out-of-scope chairs exist and are already visible** in that breakdown (Season 1 research at
  levels that were not asked, e.g. local `taxes`, `deportation`, `same-sex-marriage`). They are owed a
  re-audit under the codebook; adding a role row does not change whether they show.

## Render settings live in ev-infra

This repo's Render services (`ev-accounts-api`, `ev-accounts` (admin), `empowered-vote-app` and the seven `ev-jobs-*` cron jobs) are managed by the Render Blueprint in
[`EmpoweredVote/ev-infra`](https://github.com/EmpoweredVote/ev-infra) (`render.yaml`).

- Build and start commands, rewrites, headers, custom domains, plans, cron
  schedules and build filters change **only through a PR to ev-infra**. Render
  syncs its `main` branch automatically.
- A setting changed in the Render dashboard is **undone on the next sync**.
- Env var **values** are the exception: set them in the Render dashboard. Add a
  new variable's name to ev-infra (with `sync: false`) so the record stays complete.
- Do not add a `render.yaml` to this repo. Render does not read it.
