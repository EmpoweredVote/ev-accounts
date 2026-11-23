# Showing the incoming officeholder, and seating the 2026 state winners

**Status:** design, awaiting approval
**Author:** Chris Cantrell (with Claude)
**Date:** 2026-11-21
**Measurements in this document were taken against production on 2026-11-21.** Re-measure before
quoting any of them; several move daily as other waves land.

---

## 1. Intent, and why now

A voter who looks up their address today sees the person who is leaving, and only that person.

Measured on the live API this morning, at Los Angeles City Hall (`POST
/api/essentials/coordinate-lookup`, 498 seats returned): **five of those seats already have a known
successor in our database, and the website shows none of them.**

| Seat | Today | Incoming | Takes office |
| --- | --- | --- | --- |
| Mayor, Los Angeles | Karen Ruth Bass | Nithya Raman | 2026-12-14 |
| City Attorney, Los Angeles | Hydee Feldstein Soto | Marissa Roy | 2026-12-14 |
| US Representative | Jimmy Gomez | Angela Gonzales-Torres | 2027-01-03 |
| Judge, LA Superior Court Office 2 | Robert S. Draper | Tal K. Valbuena | 2027-01-05 |
| School Board Seat 4 | Sara Hernandez | Darryn Harris | 2026-12-11 |

The Mayor of Los Angeles changes in 23 days. The page does not say so.

This is not a data gap. `CC_0341` added `incoming_holder_id`, `incoming_holder_name` and
`incoming_on` to the address and coordinate read paths, and they are populated and correct. The
Essentials frontend contains **zero references to any of those three fields** (searched across the
whole repository on 2026-11-21). The API computes the answer and the page discards it.

**Nationally, 638 offices carry a future-dated term right now** and every one of them is invisible:
172 change hands, 451 re-elect the sitting officeholder, 15 fill a seat that is empty today.

The operator's framing, which is the goal statement for this work:

> Someone who shows up today wondering who their new Mayor/Rep/Senator is will only see the old one
> until the swear-in date, and I'd prefer to show the old and new — much more useful information,
> along with the date they take office.

Behind that sits the larger programme. 1,286 state-tier offices have a recorded 2026 winner and no
term row at all, so even after the display is fixed they would show nothing. Those need dates
sourced and terms written. The two halves are described together here because the second feeds the
first, but they ship independently and in that order.

## 2. Goals

1. An address or coordinate lookup shows, for every seat where we know it, who holds it now, who is
   arriving, and the date the new term begins.
2. Where we know who won but not when they take office, the page still names them — labelled as an
   election result, never as a term.
3. A multi-seat body shows its outgoing group and its incoming group together, rather than
   scattering the fact across sibling seats that each know part of it.
4. The politician profile page and the address page agree. They currently cannot, because the browse
   read path blanks these fields deliberately.
5. Seat the 1,286 state winners, per state, in waves ordered by when each body convenes — so the
   December states land before December.

## 3. Non-goals

- **The swearing-in date.** The page says *takes office*, which is the term start. The oath is a
  separate event with its own table (`essentials.office_swearing_in`). This work never conflates
  them and never renders a swearing-in date as a term start.
- **Local races.** 428 local races still have no result recorded. They are a separate thread; the
  display handles them correctly by showing nothing, which is honest.
- **The 233 winners with no politician record.** The display names them from the race row and does
  not need a person record. Creating those records is seating-pass work, tracked separately.
- **Backfilling history.** Nothing here changes a past term.

## 4. Anti-goals — what would make this a failure even if it worked

- **Asserting that someone holds an office they do not hold.** The page must never read as though
  the incoming person is in office. This is the single way this feature can mislead a voter, and it
  is worse than showing nothing.
- **Naming a successor for a seat we cannot identify.** In a three-seat district with three winners,
  we know the group and not the mapping. Claiming a particular person takes a particular seat would
  be fabrication dressed as precision.
- **Making an existing field mean something new without changing its name.** Three endpoints already
  read `office_next_term` and rely on it meaning *a dated term exists*.

## 5. Constraints

These are repository rules that bind the design. Each has cost a real failure before.

- 🔴 **A certified result is not a fact about who holds the seat.** Taking office is a separate,
  later event; people decline, resign and die in between. This is why option B's wording is
  *"Won the November 3 election"* and never *"will be your representative"*.
  ⚠ **A *called* result is weaker still, and today almost every result is called.** Measured
  2026-11-21: of the 1,945 November winners, **1,943 are `called` and 2 are `certified`.** The copy
  says which it is — §7.2.
- 🔴 **A term start is not a swearing-in.** Different events, different sources.
- 🔴 **An office with no race is invisible, not incomplete.** A sibling seat in a multi-seat district
  that carries no race row must not read as "nobody is coming".
- 🔴 **`current_office_holders` treats a null `term_start` as currently in office.** Its predicate is
  `WHERE (term_start IS NULL OR term_start <= CURRENT_DATE)`. See the rejected approach in §6.
- 🔴 **A race can have more than one winner**, and multi-seat races attach all their winners to one
  office row.
- 🔴 **Never create a table or view in `public`.** These views belong in `essentials`, with RLS and
  explicit grants in the same migration — and on `essentials`, `ALTER DEFAULT PRIVILEGES` already
  grants `anon` SELECT before any migration runs, so RLS is the only belt.
- 🔴 **Migration numbers are allocated, never counted** (`steward slot CC`), and this is Cantrell's
  work, so the namespace is `CC_`.
- 🔴 **`districts.state` is mixed case.** Always `lower(d.state)`. This already cost one wrong count
  in the recon for this document: 42 states read as 55 before the fold.

## 6. Approaches considered

### A — Widen `office_next_term` to fall back to the race winner

One view change. Every consumer inherits the behaviour for free, because the address lookup,
coordinate lookup and `/politicians` already join it.

**Rejected.** The view currently means *a dated term exists*, and three endpoints assert that
meaning. Widening it changes what they claim with no code change for a reviewer to see. It would
also start returning `incoming_on = NULL`, which a consumer cannot distinguish from "nobody is
coming", and it has nowhere to express the multi-seat case.

### B — A second view beside it, carrying the election result *(chosen)*

`essentials.office_pending_winner` is built from the race result and is only consulted where no
dated term exists. The API returns it in fields of its own. A dated term stays a dated term; an
election result is labelled an election result; the page renders two different sentences because
they are two different claims.

**Cost:** one more view, more fields on the response, and the join must be added to four read paths
rather than inherited by one.

**Chosen because** the entire reason this is worth building is that a term and a result are
different facts, and A makes them the same field.

### C — Do it in the frontend from race data

Rejected. The page does not receive races, and the join logic would be duplicated in JavaScript,
where none of the repository's gates can see it.

### D — Write the terms now with no start date

Rejected, and recorded here because it is the approach a later session will find attractive.

`essentials.current_office_holders` selects `WHERE (term_start IS NULL OR term_start <=
CURRENT_DATE)`. **A term written with a null start makes that person the current holder
immediately.** Writing 1,286 undated terms would replace sitting officials across 42 states today,
in the one failure mode CI cannot catch. It also breaks the repository's standing rule against
inventing dates.

## 7. The design

### 7.1 The view

`essentials.office_pending_winner` — one row per office, from `race_candidates.result = 'won'`
joined through `races` and `elections`, restricted to offices with no row in `office_next_term`.

🔴 **The election filter is on `elections.election_type`, never on a hard-coded date.** A naive
`result = 'won'` sweeps in primaries: measured 2026-11-21, the 2026-08-11 primaries alone would add
132 offices and 252 winner rows, the 2026-06-23 primaries another 72, and a primary winner is a
nominee, not an officeholder-elect. The view admits `election_type IN ('general', 'special')` and
takes, per office, the **most recent** qualifying election by `election_date`. A hard-coded
`2026-11-03` would be correct today and silently wrong at the next special — see §11.

🔴 **`result = 'runoff'` is not a win.** Louisiana's December runoff rows carry it, and a runoff
contender is a candidate still running. Only `'won'` reaches this view.

It carries: `office_id`, the election date, the number of seats on the race, the recorded winners
(id where a politician record exists, name always), **`result_certainty`** (`called` or `certified`
— the column is on `race_candidates`, not on `races`), and a resolution flag described below. Winner
names come from `race_candidates`, so the 233 winners with no politician record are still named.

The migration creates the view in `essentials`, sets `security_invoker = on`, enables RLS where
applicable, and grants only what the API role needs — per §5.

### 7.2 What the voter sees

Four cases. The counts are offices with a recorded 2026-11-03 winner, measured 2026-11-21.

**(a) A dated term, one seat — 638 offices.** Current holder, arrow, incoming holder, and the date.

```
  Mayor · Los Angeles
  ┌──────────────────────────────────────────────┐
  │ [photo]  Karen Ruth Bass          current    │
  │    ↓     Takes office Dec 14, 2026           │
  │ [photo]  Nithya Raman            incoming    │
  └──────────────────────────────────────────────┘
```

When the incoming person *is* the current holder — 451 of the 638 — there is **no arrow**. An arrow
from someone to themselves reads as a bug. The card shows the sitting officeholder with one quiet
line: *Re-elected — next term begins Jan 3, 2027.*

**(b) A result only, and the district holds exactly this one seat — 1,119 offices.** Unambiguous:
this winner takes this seat, and we do not yet know when.

🔴 **The card states the result as firmly as the count allows, and no firmer.** §5's first
constraint is the repository's own rule that a *certified* result is not a fact about who holds the
seat. A *called* one is weaker again — calls are reversed in canvasses — and measured 2026-11-21,
**1,943 of the 1,945 November winners are called and 2 are certified.** So the sentence is keyed on
`result_certainty`, and each card upgrades itself on the day its state certifies:

```
  State Senator · District 14                      ← certified
  ┌──────────────────────────────────────────────┐
  │ [photo]  Jane Doe                 current    │
  │          Won the November 3 election:        │
  │          Sam Rivera                          │
  └──────────────────────────────────────────────┘

  State Senator · District 14                      ← called (today: 1,943 of 1,945)
  ┌──────────────────────────────────────────────┐
  │ [photo]  Jane Doe                 current    │
  │          Declared winner, November 3:        │
  │          Sam Rivera                          │
  │          Count not yet certified             │
  └──────────────────────────────────────────────┘
```

No arrow and no date. The absence of a date is the honest state, not a rendering gap. Certification
already arrives in waves — Maine on 2026-11-23, Alaska on 2026-11-25, Los Angeles County around
2026-11-27 — so the hedge drains on its own over the following weeks, with no further work and no
second pass over the copy.

**(b-ii) The winner is the person already sitting in the seat — 914 offices, the majority of case
(b).** Measured 2026-11-21 across the whole result-only population: **914 re-elections, 270
handovers, 233 winners with no person record, 2 empty seats.** Rendered as written above, the single
most common card in the feature would read *"Jane Doe … Declared winner, November 3: Jane Doe"* —
the same self-pointing output the no-arrow rule already removes from case (a). It takes case (a)'s
treatment instead: one name, one quiet line.

```
  State Senator · District 14
  ┌──────────────────────────────────────────────┐
  │ [photo]  Jane Doe                 current    │
  │          Re-elected November 3 — date of     │
  │          the new term not yet confirmed      │
  └──────────────────────────────────────────────┘
```

That turns the most common card in the whole feature from apparent noise into the piece of news it
actually is: this representative is staying. The certainty distinction applies here too —
*Declared re-elected* until the count is certified.

**(c) A result only, and the whole body turns over cleanly — 68 districts.** The operator's
group-to-group case. The arrow is between the body's outgoing members and its incoming members,
which is a claim we can support even though the seat-by-seat mapping is not.

```
  House Delegates · Maryland District 13  (3 seats)
  ┌──────────────────────────────────────────────┐
  │ [photo] [photo] [photo]           current    │
  │  Guzzone  Brooks  Moreno                     │
  │                    ↓                          │
  │          Won the November 3 election          │
  │ [photo] [photo] [photo]          incoming    │
  │  Moreno  Guzzone  Brooks                     │
  └──────────────────────────────────────────────┘
```

🔴 **The group arrow is permitted only when all three numbers agree**: the number of office rows in
the district equals the number of recorded winners equals the number of people seated there today.
68 of the 76 multi-seat districts satisfy this. The rule exists because a staggered body — five
members with three seats up — would otherwise draw an arrow from five people to three and imply the
body is shrinking.

**(d) A result only, and the picture is incomplete — 124 offices.** Either the district holds several
seats and only one winner is recorded (116), or it is staggered or mismatched (8). The body-level
result line, with no arrow and no claim about who replaces whom:

```
  │          Two seats elected Nov 3:            │
  │          Greg Wims · Lesley J. Lopez         │
```

Cases (c) and (d) carry the same certainty distinction as (b): *Won the November 3 election* once
certified, *Declared winners, November 3 — count not yet certified* until then. A group is certified
only when **every** winner in it is; one called row holds the whole group at the weaker wording,
because a group sentence is a claim about all of them.

### 7.3 Read paths

The join is added to the address lookup, the coordinate lookup, `/politicians`, and the browse and
detail paths in `essentialsBrowseService.ts`, which today hard-code these fields to null. All five
must land together: the repository has already shipped the failure where two endpoints returned
contradictory transition state for the same seat, and the null was indistinguishable from "nobody is
coming".

**The incoming person's own profile page is in scope.** 136 of the people in `office_next_term` hold
no current seat, so `getPoliticianById` resolves no office for them and their page reads as though
they are nobody — which is exactly the page a voter reaches by clicking the incoming name. With the
join in place it reads *"Takes office as Mayor of Los Angeles on December 14, 2026."* Goal 4 requires
the two pages to agree. ⚠ The 233 winners with no politician record have no page to reach, so their
names render as text and not as links — see §11.

🔴 **The group payload (cases c and d) repeats on every sibling office row.** The address response
is flat and one row per office, and the group rule needs three district-level numbers that no single
office record holds: office rows in the district, recorded winners, people seated there today. Each
office row therefore carries the group block plus a `district_group_id`, and the frontend collapses
rows sharing that id into one card. A separate top-level `groups` array would need a second lookup
path through a response shape that has none. The browse and profile paths get the per-person fields
only and never the group block: they are rooted on a person, which is the join direction that fans
out (CLAUDE.md, *Officeholder occupancy → Reading*).

### 7.4 The grouping key

Sibling seats are grouped by `(district_id, chamber_id)`. The existing per-office de-duplication
(`OFFICE_DEDUP_KEY = 'o.id'`) stays exactly as it is — grouping happens at render, never by changing
the de-duplication key. Keying de-duplication on anything but the office has twice hidden real rows
in this repository.

### 7.5 When a result-only card outlives its own term start

A case (b) card says *"Declared winner, November 3"* — past tense, about an event that happened. It
does not go **false** on the day the new term begins. It goes **incomplete**: by then the real answer
is that this person is in office, and we never wrote the term.

That is the existing `offices_missing_terms` failure wearing a new hat, and it is just as silent. So
the check belongs to the seating waves (§8), not to a standing alarm: once a body's convening date
has passed, no office in that body may still be served from `office_pending_winner`. A wave that
cites a date is the one place that can assert the date was honoured, and it already runs — see §11.

## 8. The state seating pass

Sequencing, decided: **per state, sliced by convening date** — each state ships the day its date is
cited, and the January states wait while the December ones go first.

### 8.1 The real shape of the work

This is not the federal pass repeated. `CC_0453` seated 461 offices at one constitutional date. Here:

- 1,286 state offices need a term. **121 carry a cited `office_swearing_in` row; 1,165 carry
  nothing.**
- Only **15 of 204 chambers** carry `inauguration_rules`.
- A convening date is a fact about a **body**, not a seat, so the research unit is **73 (state,
  district_type) pairs across 42 states** — an average of 18 seats per citation.

**Sourcing and citing ~73 dates is the job.** The write is a day's work once they exist.

### 8.2 The standard for a date

The body's own publication — constitution, statute, or the chamber's own convening notice. A
legislative journal settles a disagreement between aggregators. `WebFetch` may locate a document and
may never be the source of a date. Each wave's migration records its source per body.

**May the 121 existing `office_swearing_in` rows serve as `term_start`?** Per body, and only where
that body's own law says so. The repository rule is 🔴 *read what a source's date is a date OF
before adjusting it*, and states genuinely differ: some define the term as beginning on a fixed
calendar date, with the oath taken at some point after it; others define it as beginning **on
qualification**, which is the oath. Where the law says qualification, the cited oath date *is* the
term start and the existing row is usable unchanged. Where it names a calendar date, the oath is a
different event and §3's non-goal forbids rendering it as a term start — source the calendar date
instead. This is decided once per body while sourcing that body's date, and recorded in the wave's
migration header beside the citation. It is the single largest unknown in how much research §8 is:
if most states qualify on the oath, 121 of the dates are already in hand.

### 8.3 Order

Waves run by convening date, soonest first, so no wave is ever late for its own state. The 178
winner-office pairs whose winner has no politician record need that record created in the same wave —
you cannot seat a person who does not exist.

### 8.4 Gating

Each wave's migration gates on **the delta it creates, inside its own transaction** — never on a
repository-wide total, which other sessions move between sessions. The 238-unflagged
`offices_missing_terms` baseline must not move: these offices are unseated but not in that bucket's
unflagged population, and no wave may raise the baseline to accommodate itself.

### 8.5 How this relates to the existing transition programme

This **is** Wave 4 — State, re-cut. `backend/data/transition-tracker/waves.csv` already carries
"Wave 4 — State" at 1,326 seats / 1,286 called: the same population, as one undated block. §8
replaces that single row with per-state slices ordered by convening date, because a wave with no
deadline is a wave that never runs, and this one has 42 different deadlines inside it.

Each slice takes a steward claim on `state:<usps>` before any work — the programme's existing
mechanism, and the one thing that stops two sessions seating the same state. The live tracker
artifact is refreshed **as part of finishing each slice**, never saved for the end: that is the
standing rule for this programme, and it is how the next session learns which states are done.

## 9. Order of work

1. **The display** (§7). Independent of all date research; makes the existing 638 visible, including
   172 handovers. One backend PR (view, migration, five read paths), one Essentials frontend PR.
2. **The state seating waves** (§8), by convening date. Each wave adds its state's winners to the
   display built in step 1 — moving them from case (b) to case (a).

## 10. Left to the builder

- Exact column names on the new view and the response fields, following the naming already set by
  `incoming_holder_id` / `incoming_holder_name` / `incoming_on`.
- Card markup and styling in the Essentials frontend, within the existing card component.
- Date formatting and the responsive behaviour of a three-photo group on a narrow screen.
- Whether the group card collapses the sibling seats into one card or renders one card with a group
  block — a presentation decision, provided the voter sees each fact once.

🔴 **The production render is shown to the operator before this ships** — the live baseline beside
the new card, measured rather than eyeballed. That is a standing preference for visual work here,
not a courtesy.

---

## 11. Calls I made while writing this

A builder's review of the draft raised eight questions. Two of them changed what a voter reads, so
they went to the operator, who approved both: the certainty-keyed wording in §7.2, and the
re-election card in §7.2 (b-ii). The other six were mine to settle. They are listed here so that a
reviewer can overturn any one of them without re-deriving the reasoning.

1. **The view filters on `election_type`, not on a date** (§7.1). A hard-coded `2026-11-03` is right
   today and silently wrong at the next special election. *Cost if wrong:* with `IN ('general',
   'special')`, a later special-election winner displaces an earlier general-election winner on the
   same office — which is correct, and is what the most-recent-per-office ordering is for, but it
   means the view's answer can change without anyone writing a term.
2. **`result = 'runoff'` shows nothing** (§7.1). A Louisiana runoff contender has not won anything
   yet. *Cost if wrong:* those seats show nothing until December instead of naming two contenders.
3. **An oath date may be a `term_start` only where that state's law defines the term as beginning at
   qualification** (§8.2) — decided per body, not once for all 73. *Cost if wrong:* either 121
   already-sourced dates go unused, or a term is recorded as starting on the wrong day.
4. **The incoming person's profile page is in scope** (§7.3). Goal 4 already requires the pages to
   agree, and the profile is where the incoming name links. *Cost if wrong:* one more read path in
   PR 1 than is strictly needed to make the address page work.
5. **The group payload repeats on every sibling office row** (§7.3), rather than becoming a new
   top-level array. *Cost if wrong:* a few duplicated fields on the wire for the 76 multi-seat
   districts.
6. **Staleness is checked by the seating waves, not by a standing alarm** (§7.5). *Cost if wrong:* a
   state whose wave never runs keeps showing a result-only card after its term has begun — the same
   silence `offices_missing_terms` already has, and no worse.
