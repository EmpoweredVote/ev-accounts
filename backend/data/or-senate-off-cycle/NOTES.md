# The 15 Oregon senate races that were never on the 2026 ballot (CC_0419)

Measured and written 2026-11-13. This closes the last item of the 641-race unseeded-legislative
backlog — not by seeding it, but by establishing that it was never a backlog.

## What was wrong

Production held a 2026-11-03 race for **all 30 Oregon State Senate districts**. Oregon elects half
its Senate at a time, so 15 of those races asserted an election that did not take place. They had
existed since 2026-05-30, each with zero candidates, and after the MA/ME/MD/OR/NV seeding wave they
were the entire remaining "blocked" count on the transition board.

## Why it happened

`backend/migrations/generate_or_legislative_races.ps1` states the assumption in its own header:

```
# 30 Senate districts x 1 election + 60 House districts x 1 election = 90 rows
for ($n = 1; $n -le 30; $n++) {
```

It fans out **one race per seat in the chamber** and has no notion of which seats are up. The House
loop is correct — all 60 Oregon House seats are elected every two years. The Senate loop is wrong by
exactly half.

> **A seat is not a contest.** Before scaffolding races for a chamber, ask which seats are on that
> ballot and take the list from the state, not from the size of the body. A staggered upper chamber
> is the common case, not the exception.

Both that generator and migration 239 now carry a warning header. 239's SQL is unchanged — comments
only, proved by hashing both versions with comment lines stripped — because rewriting an applied
migration desyncs it from what ran.

## The evidence: three independent sources, none of them an absence

| | source | what it says |
| --- | --- | --- |
| **the rule** | Oregon Constitution, art. IV § 4, as published at `oregonlegislature.gov/bills_laws/Pages/OrConst.aspx` | *"(1) The Senators shall be elected for the term of four years … (2) … one-half, as nearly as possible, of the number of Senators shall be elected biennially."* |
| **the 2024 ballot** | Secretary of State, *2024 November General Election Official Results*, `records.sos.state.or.us` RecordViewer `uri=13735458`, 35pp | State Senator contests for districts **1, 2, 5, 9, 12, 14, 18, 21, 22, 23, 25, 27, 28, 29, 30** |
| **the 2026 ballot** | AP's race feed and the SoS **Legislative Export** (CC_0416) | State Senator contests for districts **3, 4, 6, 7, 8, 10, 11, 13, 15, 16, 17, 19, 20, 24, 26** |

The two ballots **partition the chamber**: 15 + 15 = 30, no district on both, none on neither. That
is a positive finding about which election each seat had — not an inference from AP's silence.

A fourth check fell out for free: the 2024 abstract's winners are **the same fifteen people we seat
today**, name for name, including SD 30's Mike McLane, whom I had wrongly doubted.

## 🔴 The reader of the 2024 abstract had to be controlled, and the control caught it twice

`parse-2024-abstract.mjs` answers a **set** question, not an arithmetic one.

- **The vote counts in the PDF conversion are mangled and are never read.** `pdftotext -layout`
  drifts the county columns exactly as it did on the Massachusetts city PDFs — Sherman County
  (≈1,800 people) prints 325,927 in the presidential table. Only contest headings are taken.
- **The control is the House.** All 60 Oregon House seats and all 6 congressional seats are elected
  every two years, so a reader that does not return 60 and 6 is blind and its senate answer means
  nothing. It earned its keep immediately:
  1. The first version required a heading to be alone on its line and returned **40 of 60** House
     districts and **5 of 6** congressional — the converter merges a heading into the candidate row
     below it (`10th District  **Gomberg  Misc.`). Read uncontrolled, a parser gap would have passed
     for a calendar fact.
  2. The fix introduced a CRLF bug that made every contest regex miss, and the reader returned
     **zero of everything** — caught on the next run, before the senate answer could be believed.
- `", Position N"` after a district is a **judicial** contest (circuit-court district and seat), not
  a legislative one, and is excluded by shape.

## What the migration does, and what it deliberately does not

`CC_0419` archives the 15 rows into `essentials._retired_cc0419_races` and deletes them.

- 🔴 **The target is an explicit list of districts, not a `WHERE` on "has no candidates".** A
  predicate reads the shape of a value, never what it is: "no candidates" is also the shape of a
  race nobody has seeded yet, and production holds **50 such local rows today** (34 Oregon city, 6
  Oregon city-executive, 2 Oregon county, 4+2 Arizona, 2 Wisconsin county). The zero-candidate
  condition is asserted as a *guard* on top of the list, so a district that turns out to carry a
  candidacy aborts the run.
- **Nobody is unseated.** All 30 offices stay, all 30 keep their holder, and the gate counts
  `och.politician_id` rather than `count(*)`, because `office_current_holder` LEFT JOINs from
  `offices` and a vacancy would pass vacuously.
- These seats leave the race-keyed reads — the transition tracker, the headshot and stance counts,
  `check:incumbency`. That is correct: they are not in the 2026 transition.

## 🔴 A new table in `essentials` is anon-readable by default

The archive came up carrying `anon` and `authenticated` SELECT although the migration's `GRANT`
names only `ev_api`. The cause is an `ALTER DEFAULT PRIVILEGES … IN SCHEMA essentials` that grants
`anon=r, authenticated=r, ev_api=arwd` on **every** new table; the same default sits on `civic`,
`connect`, `meetings`, `treasury` and `transparent_motivations`.

> This is the **inverse** of the `public`-schema rule in CLAUDE.md, and it is easy to read the wrong
> way round. In `public`, Supabase gives a new table no Data API grants. In these EV schemas it
> gives one automatically, and enabling RLS with no policy is the only thing standing between a new
> table and the Data API. The migration revokes explicitly and gates on the end state.

## Controls — 9, all behaved

`controls.mjs` plants one fault at a time and requires the migration to stop with the message that
names the gate. Run **V0 is the untampered file and must pass**, so a suite failing for an unrelated
reason is visible at once. Every replacement asserts its anchor matched and that the text changed —
a tamper that did not apply is a control that proved nothing and looks like a pass.

| | gate under test |
| --- | --- |
| V0 | the untampered file passes |
| V1 | the candidate guard — district 17, which *did* hold a 2026 election, swapped onto the delete list |
| V2 | the precondition count — the list one district short |
| V3 | the end-state set — the `DELETE` quietly skips a row |
| V4 | the archive gate — rows deleted without being recorded |
| V5 | the dependents gate — a `discovered_sources` row (`ON DELETE SET NULL`, severed in silence) |
| V6 | the occupancy gate — a sitting senator loses their term row |
| V7 | the drift baseline — **shadowed**; the Oregon chamber gate fires on the same fault first and was neutralised for that run only, which is stated rather than hidden |
| V8 | the archive's RLS/grant gate — run through the privileged connection, since granting `anon` needs table ownership; the planted grant is rolled back by the control's own exception |

⚠ **V1 is swapped in, not added.** Appending a sixteenth district would have made the *count* gate
fire first and shadowed the candidate guard entirely.

⚠ **V5 first failed for the wrong reason** — `discovered_via` is CHECK-constrained to
watchlist/search/agent/hub and the control invented a value, so the run stopped on the constraint
instead of on the gate. A control can fail correctly, for the wrong property, and prove nothing.

## Measured before and after, through the live endpoint

`POST https://api.empowered.vote/api/essentials/coordinate-lookup` — the anonymous route a voter's
browser calls, not a hand-rolled query. ⚠ Its fields are `lat`/`lng`; the first probe sent
`latitude`/`longitude`, got `INVALID_COORDINATES` and **reported zero politicians for every point**,
which reads exactly like a dead database.

| point | district | expectation |
| --- | --- | --- |
| Kenton Park, N Portland | SD 22, Lew Frederick | a race deleted here — he must still be returned |
| Portland City Hall | SD 17, Lisa Reynolds | a race that stays — the control for "nothing else moved" |
| Nashville, TN | SD 21, Jeff Yarbro | the negative control, a different state |

## ▶ Left open

- **50 empty local races** remain for 2026-11-03 (Oregon, Arizona, Wisconsin). Each needs the same
  question asked of it — *was this seat on that ballot?* — and the answer may differ row by row.
  Portland's council seats are the ones to read first: that charter staggers its districts.
- Nothing here seats anybody. Oregon's senators elected in 2024 hold terms that run to the second
  Monday in January 2029 (art. IV § 4(1)); the seats deleted here next appear on a ballot in 2028.
