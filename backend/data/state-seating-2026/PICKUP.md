# PICKUP — start here after a context clear

Rewritten 2026-11-24, after **Nebraska** (13 offices across four bodies, and a ledger section whose
own reasoning was wrong in three places while its answer was right).
▶▶ **CONNECTICUT IS NEXT AND IS SOURCED** — 5 offices in the register, 6 in law, one clause,
**2027-01-06**. See "Connecticut is the next one up" below before step 1.
**Read `REGISTER.md` first** (the queue, the recipe, the template corrections, Rulings A and B),
then this. `SOURCING.md` is the handbook and the host table; `DATES.md` is the per-state ledger.

🟢 **NOTHING IS HALF-DONE. THE LAST SESSION CLOSED CLEANLY.** Every migration through `CC_0508` is
**applied to production and verified**; the working tree is clean apart from the untracked
`backend/_q.mjs` scratch query runner, which predates this work.

🔴 **BUT NEBRASKA'S PR IS OPEN, NOT MERGED — [#1602](https://github.com/EmpoweredVote/ev-accounts/pull/1602),
branch `feat/state-seating-ne`, four commits, CI green on its head `9c90cd50d` (checked against the
run's own `headSha`, nine checks, zero failures).** ⚠ **So master does NOT yet contain `CC_0507` or
`CC_0508`, although production does.** That is the ordinary state of this pass between waves and
nothing is wrong — but **read it before you are confused by a master checkout that has neither
file while the database has both.** ▶ **Branch off master anyway** (migrations are independent
files and the allocator already knows `CC_0508`); merge #1602 when you get to it.

▶ **Take a fresh branch off master, claim the state, and start at step 1.**

---

## Where the pass stands

**39 bodies · 153 offices still to do.** Nothing is overdue. Seventeen states are written:

| state | dated | people | seated |
|---|---|---|---|
| WI | `CC_0445` | — | `CC_0462` (121) |
| IN — House | `CC_0463` | — | `CC_0464` (3) |
| NV | `CC_0465` (52) | `CC_0466` (12 created, 1 linked) | `CC_0467` (52, **2026-11-04**) |
| HI | `CC_0469` (5) | — | `CC_0470` (2 OHA, **2026-11-03**) · `CC_0471` (Gov + Lt Gov, **2026-12-07**) |
| ME | `CC_0473` (184) | `CC_0474` (59 created, 18 linked) | `CC_0475` (183, **2026-12-01**) · `CC_0476` (Governor, **2027-01-06**) |
| CA | `CC_0477` (99) | — none needed | `CC_0478` (92, **2026-12-07**) · `CC_0479` (7, **2027-01-04**) |
| MA | `CC_0481` (204) | `CC_0482` (18 created, 3 linked) | `CC_0483` (199, **2027-01-06**) · `CC_0484` (2, **2027-01-07**) · `CC_0485` (3, **2027-01-20**) |
| WA | `CC_0487` (118) | — none needed | `CC_0488` (118, **2027-01-11**) |
| UT | `CC_0489` (50) | — none needed | `CC_0490` (50, **2027-01-01**) · ⚠ 6 Board of Education seats REFUSED, still undated |
| OR | `CC_0491` (75) | `CC_0492` (13 created, 2 linked) | `CC_0493` (75, **2027-01-11**) · ⚠ the Governor REFUSED — ORS 176.010 names an event |
| MD | `CC_0494` (**178**, not 114) | `CC_0495` (**60 linked**, 25 created) | `CC_0496` (178, **2027-01-13**) |
| MD — Governor | `CC_0499` (1) | — | `CC_0500` (1, **2027-01-20**) · ⚠ the AG and Comptroller REMAIN REFUSED |
| AZ | `CC_0497` (**94**, not 65) | — none needed | `CC_0498` (93, **2027-01-04**) · ⚠ the Corporation Commission and the State Mine Inspector REFUSED |
| AL | `CC_0501` (13, **both bodies**) | — none needed | `CC_0502` (13, **2027-01-18**) · 🟢 nothing refused |
| ID | `CC_0503` (7) | — none needed | `CC_0504` (7, **2027-01-04**) · 🔴 **7 of 7 are RE-ELECTIONS** |
| NM | `CC_0505` (11, **both bodies**) | — none needed | `CC_0506` (11, **2027-01-01**) · 🟢 nothing refused |
| **NE** | `CC_0507` (13, **FOUR bodies / EIGHT chambers**) | — **none needed, the fifth state** | `CC_0508` (13, **2027-01-07**) · 🟢 nothing refused — **three register rows left the queue at once, the most so far** |

Plus `CC_0472`, a one-off that widened `office_swearing_in_after_election` from `>` to `>=`.
🔴 **That file is DDL and `ev_api` cannot run it** — DDL goes through the owner connection (the
Supabase MCP), and both the apply tool and the chain rehearser fail it with *"must be owner of
table office_swearing_in"*.

**Next slot to reserve: after `CC_0508`.** Always ask the allocator
(`npm run steward --prefix backend -- slot CC --purpose "..."`), never count.

### 🔴🔴 HOW MUCH IS ACTUALLY LEFT — THE REGISTER'S "39 BODIES" IS NOT 39 BODIES OF WORK

Measured 2026-11-24. The generated table counts every body with an unscheduled seat, which mixes
three completely different things. **Split them before planning anything:**

| | states | bodies | offices | what it needs |
|---|---|---|---|---|
| 🟢 **SOURCED AND READY TO WRITE** | **3** | 8 | **37** | nothing — start at step 3 |
| 🔴 **REFUSED** | 10 | 12 | **47** | an external event, not effort |
| ⚠ **NOT SOURCED AT ALL** | **20** | 19 | **69** | step 2, from scratch |
| | **33** | **39** | **153** | |

- 🟢 **READY: `CT` (5), `TX` (14, two bodies), `CO` (18, five bodies).** Their `DATES.md` sections
  are green and need no new research. **That is the whole writable backlog** — three states.
- 🔴 **REFUSED, and each one is waiting on the world rather than on us:** `GA` 10 (all ten, the
  only state where nothing could be dated) · `AR` 7 (five refused with a cited window, two still
  open) · `NV` 6 (terms begin at qualification) · `UT` 6 (Board of Education, no commencement in
  law) · `SD` 6 (five refused with a window) · `NH` 6 (all six, and the **only refusal in the pass
  with no upper bound in law**) · `MD` 2 (AG and Comptroller) · `AZ` 2 (Corporation Commission and
  State Mine Inspector) · `OR` 1 (the Governor — ORS 176.010 names an **event**) · `HI` 1 (the OHA
  At-large block, which **Ruling A** refuses). ▶ **None of these is a day's work; each needs a
  `published` qualification date recorded when it happens, or a sourced per-seat term table.**
  🔴 **Do not estimate them as if they were ordinary states, and do not let the register's sort
  order put `HI` or `GA` at the top of your queue** — `HI`'s is the one dated body left, so it
  sorts first and is **not writable**.
- ⚠ **UNSOURCED — 20 states and 69 offices, and this is where the real remaining time is.** Every
  one is small (1–5 offices: `VT` `SC` `RI` `OK` `ND` `MI` `IL` 5 each · `WY` `MN` `IA` `FL` 4 ·
  `NY` `IN` `DE` 3 · `PA` `OH` `LA` 2 · `TN` `MO` `KS` 1). **The cost is step 2, not the seating**
  — the writing is an afternoon once a date is sourced, and the sourcing is what has taken a day
  per state all pass.

🟢 **NINE STATES ARE COMPLETELY DONE** and have nothing in the table at all: `WI`, `MA`, `ME`,
`WA`, `CA`, `AL`, `ID`, `NM`, `NE`. Eight more are **partly** done with only a refused remainder
(`MD`, `AZ`, `NV`, `UT`, `OR`, `HI`, and `SD`/`AR` where part is refused and part open).

⚠ **AND THE STATE TIER IS NOT THE PROGRAMME.** Wave 4 is 1,326 races: **1,076 `term_recorded` +
61 `in_office`**, 153 `called` (the table above) and 36 never looked at. **Waves 1 and 2 (the
federal tier) are complete.** Wave 3 is 328 with **268 not looked at** and wave 5 is 179 with
**162 not looked at** — those are the December and remaining LOCAL waves, a different programme,
and they are far larger than anything left here. 🔴 **"The seating pass is nearly done" is true of
the STATE tier and false of the transition.**

---

## 🔴🔴 TWO FILES ARE WRITTEN AND NOT APPLIED. EACH COMES DUE ON ITS OWN DAY.

Both are committed and rehearsed; **neither is applied, and each refuses to run early.**

| file | what it does | due |
|---|---|---|
| `CC_0480` | clear `is_vacant` on CA Assembly District 3 and State Senate District 10 | **2026-12-07** |
| `CC_0486` | clear `is_vacant` on MA 1st Franklin District and 17th Middlesex District | **2027-01-06** |

- **Why they wait:** each of those four seats is genuinely empty, and each is the only office in
  its district. Clearing the flag before the winner is seated makes the district read
  `offices > 0 AND active_holders = 0 AND vacant_offices = 0` — verbatim `DEAD_GEOGRAPHY` in a
  **master-only** gate, which would then fail on somebody else's pull request. The seating files
  therefore seat the winners and leave the flag alone.
- **They cannot be applied early.** Each one's P3 refuses unless the office already has a term
  covering *today*, which becomes true on the handover day by itself. It is an interlock, not a
  reminder.
- ▶ **ON THE DAY: rehearse, then apply.**

      cd backend && node scripts/rehearse-migration-chain.mjs migrations/<the file>
      node scripts/apply-migration-file.mjs migrations/<the file>

- ⚠ **The positive path of each is unrehearsable before its day by construction** — P3 wants a
  term covering today and P4 wants that term to start on the handover date, and only on the day
  are both true. Each body was rehearsed with `CURRENT_DATE` read as the handover date and passed
  assertions 1–5; **assertion 6 reads `office_current_holder`, whose own clock is out of reach, so
  it runs for the first time on the day.**
- The federal pair (TX-23, FL-20) is the same shape and `CC_0455` clears them on 2027-01-03.

---

## 🔴 NEXT: THERE IS NO LARGE BODY LEFT. THE QUEUE IS 39 SMALL ONES, AND MOST ARE UNDATED.

**153 offices across 39 bodies, and only ONE carries a cited start date** (`HI STATE_EXEC`, the
OHA At-large block, which Ruling A refuses — see below). Every other body in the table needs step 2
of the recipe before anything else. The three biggest are:

| # | body | offices | what `DATES.md` already says |
|---|---|---|---|
| 1 | `GA STATE_EXEC` | 10 | 🔴 **ALL TEN REFUSED, 2026-11-22** — the first state in the pass where no office could be dated. Re-read the section before spending a day on it. |
| 2 | `AR STATE_EXEC` | 7 | 🔴 five refused with a cited window, two still open. |
| 3 | `TX STATE_BOARD_EDUCATION` + `TX STATE_EXEC` | 7 + 7 | ✅ sourced — two bodies in one state, like New Mexico. |

▶ **The register sorts dated bodies first and sinks undated ones below them, largest first.** With
one dated body left that ordering has stopped doing useful work: read the table as "39 bodies, pick
a state whose `DATES.md` section is already green". **`CT`, `TX` and `CO` are sourced and
unwritten** — those are the next waves, and none of them needs new research.

### ▶▶ CONNECTICUT IS THE NEXT ONE UP, AND IT IS READY — MEASURED 2026-11-24

**5 offices, one chamber each, all on 2027-01-06** — `CT STATE_EXEC`. `DATES.md` § CT is green and
needs no new research.

`derive-seating-wave.mjs --state ct --type STATE_EXEC`, run 2026-11-24: **5 winners · 5 offices ·
5 re-elections · 0 handovers · 5 called**, digest `b7a9627439a50a18740bf79de2a3735d`, and the
**only blocker is `no_date` ×5** — so step 2 is done and the wave starts at step 3.

🔴🔴 **IT COMBINES THE TWO WORST SHAPES THE PASS HAS FOUND, AND BOTH ARE ON ONE DAY.**

- **IDAHO'S SHAPE: 5 of 5 ARE RE-ELECTIONS, so no Connecticut seat changes hands.** The
  current-holder map is unchanged, the winner map is identical to it, and **a file that wrote
  nothing at all would pass every "who holds this seat?" check.** ▶ Step 9's "probe a seat that
  CHANGES HANDS" is **unsatisfiable** — read `incoming_on`, never `incoming_holder_name` — and
  `P6`'s "a handover's predecessor is not the winner" arm is **unreachable by construction**.
  Record that rather than counting it as tested.
- **NEW MEXICO'S SHAPE, AND IT IS THE REAL ONE THIS TIME: THE ABSENT BODY'S DAY *IS* THE WAVE'S
  OWN DAY.** Measured 2026-11-24: Connecticut holds **0 `STATE_UPPER` and 0 `STATE_LOWER` office
  rows**, and `DATES.md` § CT already records that `art. III, § 10` commences **legislators'**
  terms on the very same Wednesday — 2027-01-06. Nebraska escaped this (its unicameral sits one
  day earlier); **Connecticut does not.** ▶ Gate on the absence in both files, and say in the
  header that a seeding job must give those seats their own `rule_id` even though the day is
  shared.
- 🔴🔴 **AND IT WOULD BE THE THIRD STATE ON 2027-01-06, WHICH ALREADY CARRIES 200 ROWS AND 200
  TERMS** — Massachusetts' 199 legislators under `ma-const-amend-64-s1-legislators` and the Maine
  Governor under `me-const-art5-pt1-s2-first-wed-after-first-tue-january`. A gate reading the total
  would see 205 and call it success. **Every count about the day is a delta that names BOTH.**
  ⚠ **Maine's rule is the same sentence as Connecticut's** — *the Wednesday following the first
  Monday* against *the first Wednesday after the first Tuesday* — which agree in every year
  January 1st is not a Tuesday. Two states, one square, two unrelated clauses, nearly one
  sentence.
- ⚠ **THE SECRETARY OF THE STATE HAS NO WINNER AND THE OFFICE EXISTS** — 6 `STATE_EXEC` office
  rows, 5 pending. `DATES.md` records it; `art. IV, § 1` puts all six on the 2026 ballot as a
  matter of law (2026 − 1974 = 52, divisible by four), so that seat is **certainly** a missing
  result, not an off-cycle seat. 🔴 **But the dates file must still decide whether to date five or
  six.** Maryland and Arizona date the ASSIGNED offices; here there is no Ruling A, so dating the
  five that can be seated is right — and the sixth needs its refusal pinned, not left silent.
- 🔴 **READ `DATES.md` § CT's OWN TRAP BEFORE OPENING THE PDF.** The document contains ARTICLE
  FOURTH **twice** and the superseded 1965 version comes first, naming five officers and no
  Attorney General. Stopping at the first heading manufactures exactly the shape of South Dakota's
  *real* missing-office finding. **Search for the LAST occurrence, or for the word CODIFIED.**

After Connecticut: **`TX`** (two bodies, 14 offices, sourced) and **`CO`** (four bodies, 18
offices, sourced). Neither needs new research.

### ▶▶ AND THE ONE THING TO DO DIFFERENTLY

🔴🔴 **READ THE STATE'S `DATES.md` SECTION FOR ITS OWN ADMISSIONS BEFORE TRUSTING IT — AND WHEN ITS
ANSWER IS RIGHT, CHECK ITS *REASONS* SEPARATELY.** New Mexico's section flagged its own weakest
claim and sweeping it found a third instrument. **Nebraska's did the same and the sweep found
something different and more useful: the answer was right and three of the reasons were wrong.**

- Its bound — *"proved undisplaced against 4 constitutional provisions and 5 statutes"* — was a
  check of the clauses that **govern those bodies**, which is not a check for an overriding
  provision elsewhere. The wider sweep (234 constitutional sections, all 488 of Chapter 32) found
  eight more candidates, all dead or confirming.
- It said the Legislature has *"its own constitutional commencement"*. **It does not** — the three
  sections it cites name no day, and neither does the statute its own table skipped. A **statute**
  carves them out, which moved the absent body's day off the wave's day.
- It never noticed that one of the three pending Regent seats is not on its statute's cycle at all.

▶ **A section whose ANSWER is corroborated can still have a reason that will mislead the next
reader.** Three of Nebraska's would have: one would have sent a seeding job to the wrong day, one
would have left a vacancy seat looking like a fresh six-year term, and one was a statute nobody
had opened. **The date was never in doubt; the reasons were, and they are what gets reused.**

🔴🔴 **AND THE NEW TRAP THIS STATE ADDED: A WRONG RULE CAN BE RIGHT IN THE CYCLE YOU ARE WRITING,
AND THEN NOTHING IN YOUR OWN DATA CAN REFUSE IT.** *"The first Thursday in January"* is the
shorthand for Nebraska's clause and gives the correct day in 2027 — and the state's one dated term
lands on it under both readings. **Four rival rules were separated by our data and the fifth was
not.** Only the Secretary of State's canvass book, a *document*, broke the tie.
▶ **When the in-data control and the right rule agree, list what else agrees with them**, and if a
wrong rule survives, say so in the file as an assertion that must PASS — then put a control on
that assertion. `CC_0507`'s 3d and control C5 are the worked example, and it is the second time
after Idaho that a check kept in order to pass has needed one.

### Also outstanding, and small

- ⚠ **Utah's 6 Board of Education seats and Oregon's Governor remain refused**, as recorded.
- ⚠ **Maryland's Attorney General and Comptroller remain refused**, and so do **Arizona's
  Corporation Commission and State Mine Inspector**. Each needs a `published` qualification date,
  recorded when it happens — not an estimate.
- 🟢 **FIVE STATES NOW PROVE THE PEOPLE FILE IS NOT AUTOMATIC** — Arizona, Alabama, Idaho, New
  Mexico and **Nebraska** needed none at all; Maryland needed 60 links and 25 creations where the
  column said 85 creations. ▶ **Sweep `politicians` before writing one, and size it from the
  sweep**, checking each winner on **both** (full_name) and (first_name, last_name). Nebraska had
  exactly one collision — two active `Mike Foley` rows, colliding on **both keys at once**, so the
  database's own duplicate-name trigger could not have told them apart either. 🟢 The wave pointed
  at the sourced row and `CC_0508`'s `P4` pins both halves. ⚠ **The orphan is still there** and is
  a separate cleanup.
- 🔴 **THE CROWDED SQUARES, RE-MEASURED 2026-11-24 AFTER NEBRASKA.** `2027-01-04` **241 rows / 229
  terms** (Wisconsin, Arizona, California, Idaho — still the most crowded) · `2027-01-06` **200 /
  200** (Massachusetts 199, Maine 1 — **and Connecticut would be the third, on its own day**) ·
  `2027-01-07` **15 / 15** (Massachusetts 2, Nebraska 13) · `2027-01-01` **61 / 61** (Utah 50,
  New Mexico 11). Every count about any of them is a delta that must name the other states' rules.

---

## 🔴🔴 TWO LIEUTENANT GOVERNORS ARE MISSING IN OPPOSITE DIRECTIONS, AND NEITHER IS SEATING'S JOB

This pass found the same hole twice in one day, from two different sides. **Hold them together —
separately, each reads as a one-state oddity.**

| state | what exists | what is missing | takes office |
|---|---|---|---|
| **AZ** | a winner, on the Governor's ticket | **the OFFICE ROW** — Arizona holds eleven `STATE_EXEC` rows and no Lieutenant Governor, and no candidate row either | 2027-01-04 |
| **MD** | the office row, held by Aruna Miller | **the ELECTION** — no pending winner and NO 2026 race row at all | 2027-01-20 |

- Both are constitutional joint-ticket offices: Ariz. Const. Art. V § 1(C) and Md. Const. Art. II
  § 1B, which says the election of a Governor *"shall constitute the election **for the same
  term**"* of the Lieutenant Governor.
- 🔴 **Both are invisible to every occupancy count.** Arizona's is `CLAUDE.md`'s *an office with no
  term is invisible and nothing errors*, reached from the seeding side; Maryland's is Utah's
  **"no race row at all"** third class, which looks identical to an unrecorded result from the seat.
- 🔴 **CREATING ARIZONA'S OFFICE IS AN OCCUPANCY ACT** — it must be created **and seated** in one
  file, or the unflagged drift baseline rises — and we hold nobody to seat. ▶ Neither file invented
  a row. `CC_0497` assertion 3e pins Arizona's absence; `CC_0499` P5 and `CC_0500` P7 pin
  Maryland's. **Both belong to the results and seeding programme.**

---

## The traps this pass has paid for, in one screen

**On dates**

- 🔴🔴 **A WRONG RULE CAN BE RIGHT IN THE CYCLE YOU ARE WRITING, AND THEN NOTHING IN YOUR OWN DATA
  CAN REFUSE IT — ONLY A DOCUMENT CAN.** Nebraska's Art. XVII-5 says *the first Thursday AFTER the
  first Tuesday*; the obvious shorthand is *the first Thursday in January*, and in 2027 **both give
  2027-01-07**. A file written from the shorthand produces the right date and passes every count.
  🔴 **And the state's one dated term, 2023-01-05, lands on it under BOTH readings** — so the
  in-data control separated the clause from four rivals (two Wednesday rules, the first Monday, the
  first Tuesday, all zero) and was **blind to the fifth**. The uniformity was in the **calendar**,
  not in the rows. The Secretary of State's 2024 canvass book broke the tie: **twelve `Term Start`
  blocks at January 9, 2025 against the shorthand's January 2.** ▶ **List what ELSE agrees with
  your in-data control, and when a wrong rule survives it, write that into the file as an assertion
  that must PASS — then put a control on that assertion.** `CC_0507`'s 3d and control C5.
- 🔴🔴 **A LEDGER SECTION CAN HAVE THE RIGHT ANSWER AND THE WRONG REASONS, AND THE REASONS ARE WHAT
  GET REUSED.** Nebraska's § NE was right about 2027-01-07 and wrong three times about why:
  its "proved undisplaced" bound was a sample of the clauses governing those bodies rather than a
  sweep; it said the Legislature has *"its own constitutional commencement"* when the three
  sections it cites name no day and a **statute** (`§ 32-122` with Art. III-10) is what carves it
  out; and it never noticed that one of three pending Regent seats is not on its statute's cycle at
  all. ▶ **Check a corroborated answer's reasons separately.** One of those would have sent a
  seeding job to the wrong day and one would have left a vacancy seat looking like a full term.
- 🔴🔴 **A BODY'S STATUTE CAN PARTITION IT EXHAUSTIVELY AND STILL NOT ACCOUNT FOR A SEAT YOU HOLD,
  AND THE EXTRA SEAT IS A VACANCY ELECTION.** `§ 32-510` puts only Regent Districts 1 and 2 on
  Nebraska's 2026 ballot; we hold three. The third is `§ 32-573(2)(a)`, filling the unexpired
  remainder of a 2024 term after a resignation — and `CC_0375` had already written the whole
  answer into that seat's own `source` from the body's roster, **naming the wave's day**.
  ▶ **When a cycle partition leaves a seat over, look for the vacancy statute before doubting the
  partition — and grep your own `source` columns first.** 🔴 **And an unexpired remainder has a
  different END and no column records it**: `seat_officeholder` writes no `term_end`, so it belongs
  in that one row's `source`, asserted to be on that seat **and no other**.
- 🔴🔴 **A RESIDUAL CLAUSE MUST BE QUOTED WITH ITS OWN ESCAPE HATCH ATTACHED, AND A CITATION THAT
  DROPS IT IS INVISIBLE TO EVERY NUMBER.** *"Unless otherwise provided by this Constitution or by
  law"* is six words that decide whether the rule reaches the next body somebody seeds. Dropping
  them left every row, date, delta and count byte-for-byte identical in `CC_0507` — only the
  authority TEXT changes. ⚠ **And "or by law" is the WIDER form**: New Mexico's residual yielded
  only to the constitution, so a sweep of the constitution was enough there and **is not enough in
  a state whose hatch a statute can walk through.**
- 🔴🔴 **A LEDGER ENTRY THAT FLAGS ITS OWN REASONING AS UNTESTED IS TELLING YOU WHERE THE FINDING
  IS — GO AND SWEEP IT.** New Mexico's `DATES.md` discharged Art. V § 1's *"unless otherwise
  provided in the constitution of New Mexico"* by argument and said so. The sweep — **24 articles,
  270 section titles** — found **Art. XX § 3(A)**, a general clause commencing *"every state,
  county or district officer"* on the first day of January, which **agrees, reaches BOTH bodies at
  once, and is exactly what the carve-out yields to**. ▶ A sweep that confirms the existing answer
  is not wasted: it turned the state's weakest claim into its strongest.
- 🔴🔴 **READ THE ESCAPE HATCH TO ITS FULL STOP — IT CAN CLOSE FOR ONE BODY AND STAY OPEN FOR THE
  OTHER IN A SINGLE SENTENCE.** Art. XX § 3(C) lets a law adjust a term to stagger elections
  (Oregon's shape) and ends **"No statewide elective office may be adjusted pursuant to this
  subsection"** — shut for the seven executives, open for the districted Commission, **and HB 9 is
  the law that walks through it and keeps January 1 anyway**. One clause answered both bodies in
  opposite directions.
- 🔴🔴 **A MISSING BODY WHOSE DAY IS *THE WAVE'S OWN DAY* CANNOT BE SEEN BY ANY DELTA.** New
  Mexico's 70 absent House seats take 2027-01-01 — what `CC_0505` wrote — because Art. IV § 4
  names no commencement and Art. XX § 3(A) covers them. Alabama's 140 sat on a day already past
  and Idaho's 105 on a different article's different day, so both would have stood out; these
  would be **absorbed into the day the wave itself created**. ▶ **Count the state's office rows by
  `district_type` AND work out which day the absent body would take.** A seeding job must give it
  its own `rule_id` even when the day is shared.
- 🔴🔴 **A HOST'S REFUSAL CAN TURN FROM A 403 INTO A 200 SHELL IN TWO DAYS, AND THE 200 IS WORSE.**
  `nmonesource.com` was on file as 403-with-239-bytes against a complete browser header set; two
  days later it served **HTTP 200, 13,604 bytes, the right `<title>` and zero section text**. A
  403 announces itself; a shell clears a "the title is right" guard. **The conclusion was unchanged
  and only the evidence moved** — which is the thing a later reader gets backwards.
- ⚠ **A STAGGERING CLAUSE HAS TWO HALVES, AND THE SECOND ONE TURNS A SUSPICION INTO A
  MEASUREMENT.** HB 9 § 3(C) names five PEC districts and § 3(D) the other five; 5 + 5 = 10 is the
  constitution's own membership number, so the partition is **exhaustive** and the shortfall is
  *exactly one seat*. Without § 3(D), "we hold four of five" leaves open how many of the other six
  were up. ▶ **Read both halves and check they partition the body.**
- 🔴🔴 **AN ANCHOR-YEAR RULE IS STILL A CITATION, AND IT IS THE SHAPE MOST LIKELY TO BE MISREAD AS
  "NO RULE".** All three Arizona provisions name a **specific past date** plus a term length and
  leave the recurrence implied — *"shall hold office until the first Monday in January, 1913"*,
  *"beginning on the first Monday of January, 1971"*, *"initial two-year terms beginning on the
  first Monday in January, 2003"*. ⚠ And the legislative one is **titled "Term limits of members
  of state legislature"**, so a search for a term-START clause never reaches it. Read the title
  last.
- 🔴🔴 **THE DATE EVERY SOURCE PUBLISHES IS OFTEN THE CONVENING, NOT THE TERM START.** Maine's
  term begins 2026-12-01 and the Legislature convenes 2026-12-02. One day, 183 seats. ⚠ **AND THE
  OPPOSITE IS ALSO TRUE** — California convenes at noon on the same Monday the terms begin — so
  "the convening date is wrong" is not a rule either. Read what the source's date is a date OF.
  The seating file must **read** the date from `office_swearing_in`; a literal agrees with itself
  however wrong it is.
- 🔴🔴 **AN ORDINAL-WEEKDAY SHORTHAND FOR A COUNTED RULE CAN BE RIGHT SEVEN CYCLES OUT OF EIGHT.**
  Alabama's day is *the first Monday after the second Tuesday in January*, which coincides with the
  **third** Monday in 2003, 2007, 2011, 2015, 2023, 2027 and 2031 — and with the **second** in
  2019, when January 1st was itself a Tuesday (2019-01-14, the day Alabama inaugurated, against the
  shorthand's 2019-01-21). ▶ **Compute the rule from the thing it counts FROM, and compute the
  look-alike beside it in a year where they DISAGREE.** A control run only in the cycle being
  written is satisfied by any rule that lands there.
- 🔴🔴 **THE MISSING-LEGISLATURE SHAPE COMES IN TWO OPPOSITE FORMS, AND THE SECOND IS THE URGENT
  ONE.** Alabama's 140 legislative offices **do not exist**, on a day that had **already passed**.
  Idaho holds **all 105 of its own — 35 Senate, 70 House, every one held and dated — with ZERO 2026
  races**, and Art. III § 3 gives them two years *"from and after the first day of December next
  following the general election"*: **2026-12-01, seven days out**, with the rule already
  corroborated in our data across five cycles. ▶ **Count a state's office rows by `district_type`
  AND its 2026 race rows separately.** "No pending seat" is a statement about the seats we hold a
  RESULT for, and a seeded, dated, unraced chamber is invisible to it.
  - 🔴 **AND READ THE PREPOSITION BEFORE WRITING THAT DAY.** *"From and after the first day of
    December"* is not plainly "on December 1st". Our 72 seeded Idaho rows carry December 1 from
    **Ballotpedia's "assumed office"**, not from the clause — so the seeded day may be one day
    early and nothing in our data would show it. Maine's trap in the opposite direction.
- 🔴🔴 **A STATE CAN RETURN ITS ENTIRE DEPARTMENT, AND THEN NOTHING ABOUT THE PAGE CHANGES.** All
  seven Idaho executives were re-elected, so **no seat in the state changes hands**: the
  current-holder map is unchanged, the winner map is identical to it, and **a file that wrote
  nothing at all would pass every "who holds this seat?" check.** The day's term delta is the only
  thing that separates them. ▶ **Step 9's "probe a seat that CHANGES HANDS" can be unsatisfiable —
  then read `incoming_on`, never `incoming_holder_name`**, and say in the file which of the two
  carries the information. ⚠ It also makes a gate unreachable by construction (a handover's
  predecessor is not the winner); record that rather than counting it as tested.
- 🔴🔴 **A STATE CAN HAVE A FOURTH RULE WHOSE DAY IS ALREADY PAST, FOR A BODY WE DO NOT HOLD.**
  Ala. Const. § 46(a) commences every senator's and representative's term *"on the day after the
  general election"* — 2026-11-04 — and elects all of them every fourth year from 1906, so 35 + 105
  seats were on this ballot as a matter of law. **We hold zero Alabama `STATE_UPPER` and zero
  `STATE_LOWER` office rows.** Arizona was missing one office; Alabama is missing 140, and nothing
  errors. ▶ **Count the state's office rows by `district_type` before believing its pending set is
  the whole state**, and write the absent body's own clause into the file so nobody borrows the
  wrong day later.
- 🔴 **A TERM CAN BEGIN ON ELECTION DAY** (`HRS § 13D-5`) or the day after (`Nev. Const. art. 4
  §§ 3, 4`; `Ind. Const. art. 4 § 3`). "The date is in the future" is an assumption.
- 🔴 **READ THE PREPOSITION.** Nevada and Indiana count forward — *"the day next **after** their
  election"*. Maine counts back — *"the day next **preceding** the first Wednesday in December"*.
- 🔴🔴 **LOOK FOR THE CONSTITUTION'S GENERAL TERM-COMMENCEMENT CLAUSE BEFORE CONCLUDING AN OFFICE
  HAS NONE.** California's `art. II, § 20` dates all seven of its statewide offices and lives in
  the **voting** article — reading articles IV, V and XIII in order never reaches it.
- 🔴🔴 **THE NEAR MISS IS USUALLY A LIVE DATE SOMEWHERE, AND SOMETIMES IN THE SAME STATE ON THE
  SAME PAGE.** Maryland's Governor is one week past its General Assembly — **178 live rows** —
  and Arizona's second Monday is both its own SESSION convening day *and* the term start of 118
  Washington and 75 Oregon seats. Reaching one week too far produces another office's correct
  answer, never an absurd one. ▶ **Compute the wrong rule beside the right one and assert it
  carries NOTHING.**
- 🔴🔴 **AND RUN THE RULES OVER A CYCLE THE FILE DOES NOT WRITE.** Arizona's three cycles in our
  own data read **80 terms on a first Monday and ZERO on either wrong rule** (`CC_0497` 3d);
  Washington's seven biennia agree with the second Monday 5/6/7/12/16/23/25 times and with the
  first Monday **zero times in all seven** (`CC_0487` 3). ⚠ **A control that only asks "does the
  computed day carry the recorded cluster?" is satisfied by any rule that lands there.**
  ▶ `CC_0497` 3d also **refuses to report if a cycle has no rows at all** — a control that has
  lost its fixture proves nothing.
- 🔴 **WHERE THE LAW SAYS QUALIFICATION, THE TERM START IS THE OATH** and there may be no date at
  all — Nevada's six executives are refused with a sourced `window_end_date` of 2027-01-04.
- 🔴🔴 **READ A TERM CLAUSE TO ITS FULL STOP — THE ESCAPE HATCH IS USUALLY AT THE END.** Oregon's
  Art. IV § 4(1) ends *"unless a different commencing day for such terms shall have been appointed
  by law"*. ⚠ **And a tail is not always an escape hatch**: Maryland's Art. II § 1 ends in a
  **term-limit** provision, which is why `CC_0499` says so out loud rather than leaving the reader
  to re-read it.
- 🔴🔴 **THE SAME DAY CAN NAME THE TERM AND THE QUALIFICATION, AND NO COUNT CAN TELL THEM APART.**
  Md. Art. II § 1 is the term; § 3 names the **same day** for the qualification and then lets it
  slip — *"or as soon thereafter as may be practicable"*. Washington is the three-citation version
  of this. ▶ **A gate must read the `authority` TEXT**, or the defect surfaces only when a person
  does, which may be never.
- 🔴🔴 **A STATE CAN BE THE THIRD ON A CALENDAR DAY, AND A RIVAL'S rule_id MAY EVEN SHARE ITS
  WORDS.** 140 rows were on 2027-01-04 before Arizona — Wisconsin 123 under
  `wi-legislature-first-monday`, California 17 — so a gate asking "how many start on the first
  Monday?" reads 234 and calls it success. ▶ **Pin the before-image, assert the delta, and require
  every row on the day to belong to a NAMED rule.**
- ⚠ **A DATE ROUNDED TO JANUARY 1 LOOKS EXACTLY LIKE A TERM THAT BEGAN ON JANUARY 1.** 27 of
  Washington's rows read `01-01` because the Ballotpedia half of their source knew only the year.
  🔴 And the converse is live: **Utah's real date IS January 1st**.
- 🔴🔴 **TWO ELECTED BODIES IN ONE STATE NEED NOT SHARE A BOUNDARY, AND THE REFUSED BODY'S OWN
  STATUTE MAY BE THE ONLY EVIDENCE.** Utah's legislature begins on the first **day** of January;
  its Board of Education has no commencement in law. ▶ **Refuse the body and PIN the evidence.**
- 🔴🔴 **A "THE SECTION NUMBER IS PRESENT" GUARD PASSES ON A JAVASCRIPT SHELL.** `le.utah.gov`
  answers `curl` with HTTP 200, ~26.6 KB of navigation, no section text. ⚠ Two different sections
  at an *identical byte count* is the tell. 🟢 **And look for the non-browser route before reaching
  for Playwright twice.** ⚠ Arizona's `azleg.gov` is the opposite and worth knowing: it serves real
  section text to plain `curl` at 973–13,810 bytes, and **does NOT soft-404** — five wrong
  spellings of a section URL return a true 404 at 79,330 bytes.

**On people**

- 🔴🔴 **`winner_no_record` MEANS "NO RECORD IN THIS RACE", NEVER "NO RECORD ANYWHERE".** Nevada:
  1 of 13. Maine: 18 of 77. **Maryland: 60 of 85** — 55 of them the sitting holder of the very
  seat they had just won. 🟢 **And Arizona needed NO people file at all**, which was swept for
  rather than read off the column. ▶ **Sweep the whole `politicians` table before creating
  anybody, and size the people file from the sweep.**
- 🟢 **ANCHOR A LINK ON A SEAT, NOT ON A NAME — IT NARROWS THE CANDIDATES TO THREE.** The person
  must be the current holder of an office inside **that race's own eligible set**.
- 🔴 **`essentials.politicians` HAS ITS OWN DUPLICATE-NAME TRIGGER AND IT IS RIGHT BY DEFAULT.**
  Take `essentials.allow_duplicate_name` **for one row, in a statement of its own**.
- 🔴🔴 **A NAME THAT MATCHES IS NOT A PERSON THAT MATCHES — PRINT THE FIELD THAT DISCRIMINATES.**
  Two active "Chad Perkins" rows; one holds **Missouri** House District 40, one **Maine** House 31.
- ⚠ **PEOPLE MOVE BETWEEN SEATS, AND TWO CAN SIMPLY SWAP.** Arizona's Districts 19 and 20 are
  straight **exchanges** (Gowan↔Griffin, Gonzales↔Hernandez); California's Ma and Kounalakis
  exchange Treasurer and Lieutenant Governor. The incumbency guard's scope must be a UNION of
  winners and predecessors, because **no per-office count can see somebody left holding two seats**.
- ⚠ **A GAP BETWEEN TWO OFFICES IS NOT A DEFECT.** Mike Gipson's Assembly term closes 2026-12-06
  and his Board of Equalization term opens 2027-01-04. Two clauses, two days, 28 days out.
- ✅ **`party` IS NOT A GAP TO FILL.** *"Parties are not something we celebrate anywhere on our
  platform."* A NULL party is finished work.

**On vacancies**

- 🔴🔴 **A CORRECT `is_vacant` FLAG IS NOT A BLOCKER, AND CLEARING IT EARLY IS THE MISTAKE.** Name
  the expected flags in the pre-check, seat the winner future-dated, and clear the flag **on the
  handover day** in its own file with a data interlock (`CC_0480`).
- 🔴 **THE REASON IS A MASTER-ONLY GATE.** One office in its district, flag cleared while empty,
  and the district reads `DEAD_GEOGRAPHY`, failing on the next innocent pull request.
- 🟢 **A vacancy renders correctly meanwhile.** Assembly District 3 answers
  `seat_status=vacant, incoming=Dom Belza, on=2026-12-07`.

**On the register's blind spots**

- 🔴🔴 **AN OFFICE WITH A RACE AND NO RECORDED RESULT IS EXACTLY AS INVISIBLE AS AN OFFICE WITH NO
  RACE — AND "NO RACE ROW AT ALL" IS A THIRD CLASS AGAIN.** All three look identical from the seat.
  Found so far: NV Assembly 22; ME House 86, 96 and Senate 18; CA's five un-raced Assembly
  districts, Superintendent and Insurance Commissioner; WA's four `advanced`-only seats; UT's 2
  blank-result and **31 no-race-row** seats; MD's ten Delegate seats and its **Lieutenant
  Governor**; **AZ's State House District 27** and its **missing Lieutenant Governor office**;
  **NM's Public Education Commission District 7** — no race row at all, the seat changed hands
  (Frederick Walton Parker over John Foreman, 178 of 178 precincts), and **Patricia Gipson is left
  holding it on our pages**. 🟢 That one is the best-evidenced of the set, because HB 9 §§ 3(C)
  and 3(D) partition the body 5 + 5 and so prove the shortfall is *exactly one seat*.
- 🔴 **READ `result` AND `result_source` BEFORE CALLING A SEAT UNDECIDED.** Washington's four and
  Arizona's District 27 all carry `result = 'advanced'`, which is the **August top-two primary**
  result, not a November one still being counted. ⚠ Arizona's two sitting members, Lisa Fink and
  Tony Rivero, are themselves two of the three candidates.
- 🔴 **READ THE BODY'S OWN TERM CLAUSE TO LEARN HOW MANY SHOULD HAVE BEEN UP.** Ariz. Art. IV,
  Pt. 2 § 21 gives every member two years and § 1(1) elects two Representatives from each of thirty
  districts, so all 60 were on the ballot **as a matter of law** and District 27's two are
  *certainly* missing. The constitution turns "probably missing" into "certainly missing", which is
  what makes a gap actionable.
- 🔴 **A MISSING RESULT CAN LEAVE ONE PERSON HOLDING TWO SEATS, AND TIDYING IT IS THE MISTAKE.**
  Maryland's Nicholaus Kipke and Utah's Doug Fiefia. `seat_officeholder` closes the predecessor on
  the seat it SEATS and nothing else. **The fix is the result.**
- 🔴 **A CHAMBER CAN HOLD SEATS ITS CONSTITUTION'S MEMBERSHIP NUMBER DOES NOT COUNT.** Maine: 154
  House offices against a constitutional 151, because three are tribal seats filled by their
  nations.
- 🔴 **AN INNER JOIN TO `essentials.chambers` DROPS A `STATE_BOARD` SEAT**, whose `chamber_id` is
  NULL. Join chambers LEFT, or not at all.

**On Ruling A — a multi-member seat**

- 🔴🔴 **THE SELECTION IS BUILT ON THE *ASSIGNED* OFFICE, AND SO IS THE DATES FILE.** Maryland
  dated **178** offices although only 114 carry a race; Arizona dated **94** against 65. Dating the
  race-carrying ones alone aborts the seating file at its P4 **after** the first terms are written.
- 🔴🔴 **THE EQUALITY CLAUSE IS THE WHOLE OF THE GATE, AND ARIZONA IS WHERE IT EARNED ITS KEEP.**
  The **Corporation Commission** passes every interchangeability clause — five identical office
  rows — and carries 2 winners against 5 eligible seats with **neither winner holding any of
  them**. Under "at least", nothing anchors and the fall-through picks two of five outright.
  🔴 Control C13b measured the cost of the weaker wording: the staggered body walks through `P2a`
  and the only gate that notices is the **bijection count**, reporting *"the assignment produced
  92 rows for 93 winners"* — which sends the operator looking for a lost winner.
- 🔴🔴 **RULING A'S GATE GOES ABOVE THE PIN.** Below it, every realistic tamper is caught two gates
  earlier by the digest, so the clause carrying the real-world cost has no control of its own.
- 🔴 **THE PIN MUST BE CAPTURED AFTER THE PEOPLE FILE, BECAUSE THE ASSIGNMENT ITSELF MOVES.**
  ⚠ Arizona has no people file and still captured the pin by rehearsing `dates + a probe`: the
  dates file must exist before P4 can read a date.
- ⚠ **"RULING A" BELONGS IN THE `source` OF A *FILL*, NOT OF EVERY HANDOVER.** A fill is a
  non-anchored winner of a **multi-seat** race. Maryland wrote it on all 30 non-anchored seats;
  Arizona writes it on 24 of 39 and gates in both directions.
- 🟢 **CHECK THE BODY'S SIZE AGAINST ITS CONSTITUTION, NOT AGAINST ITSELF.** Md. Art. III § 3 gives
  every district one Senator and three Delegates (141 + 47 = 188); Ariz. Art. IV, Pt. 2 § 1(1)
  gives thirty districts one Senator and two Representatives (30 + 60 = 90). A district holding one
  too many would let a fill claim a seat nobody elected.

**On the tooling**

- 🔴🔴 **THE DIGEST CAN COVER FEWER ROWS THAN THE COUNTS CLAIM.** `is_reelection` is **NULL** on a
  seat with no current holder, `'…' || NULL` is NULL, and `string_agg` **skips** it. Add
  `AND och.politician_id IS NOT NULL` and a gate counting `count(<the expression>)`. ⚠ With a
  one-row selection it empties the digest entirely. 🔴 **KEEP THE COVERAGE GATE EVEN WHERE THE
  DEFECT CANNOT OCCUR** — a control proved the two gates are complementary, not redundant.
- 🔴🔴 **A ONE-OFFICE WAVE IS WHERE A GATE PASSES VACUOUSLY.** Every count is 1 or 0, and a count
  of 1 is true of whoever is in the selection. ▶ **The controls that matter keep the size and
  change WHICH** — which office, which person, which day, which clause. `CC_0500`'s suite is the
  worked example.
- 🔴🔴 **A ZERO NEEDS A POSITIVE CONTROL.** Arizona's "nobody holds two seats" is zero, so `P9`
  counts the six chamber switchers and asserts each one's seat is **inside** the wave, and control
  C20 plants the Kipke shape and watches `P8` go red. 🔴 **AND THE FIXTURE CAN CROSS TIERS AND BE A
  SINGLE PERSON**: Alabama's is **Tommy Tuberville, a sitting U.S. Senator who won the
  Governorship**, whose Senate term the federal programme had already closed at 2027-01-02. `P9`
  names both dates, **C12 reopens the term and C13 removes the fixture outright**, so the zero
  cannot go vacuous unnoticed. ⚠ The fifteen days in which he holds nothing are correct — **a gap
  between two offices is not a defect.**
- 🟢🟢 **A CONTROL KEPT IN ORDER TO *PASS* NEEDS A CONTROL OF ITS OWN.** Idaho's three dated
  executive terms are 2019-01-07, 2023-01-02 and **2012-10-15 — all three Mondays** — and the third
  is a mid-term **appointment in October**, so a check shaped "are these Mondays?" admits all three
  and counts an appointment as evidence for an elected-term formula. **The discriminating field is
  the MONTH.** `CC_0503`'s assertion 3d therefore runs BOTH tests and requires the weak one to pass
  on 3 while the strong one passes on 2 — and **control C4 breaks the WEAK test's expectation**,
  because if it ever stopped admitting all three the control would quietly stop demonstrating the
  trap it exists to record, with every number in the file still green. ▶ **When you keep a weak
  check in order to show what it lets through, assert what it lets through.**
- 🟢 **TWO GATES OVER ONE VALUE CAN BE COMPLEMENTARY, AND ONLY A TAMPER THAT LEAVES THE *SHAPE*
  INTACT SEPARATES THEM.** Moving Brad Little's 2019-01-07 fired the **dates** file's 3d, not the
  seating file's `P6` — the right order, since that row is the corroboration 3d reads. Moving
  Woolf's appointment to **another October Monday** left all three of 3d's counts unchanged and
  reached `P6`, which asserts the value is one of three KNOWN DATES rather than one of the right
  shape. ▶ **Ask which of your two gates reads the value and which reads its shape**, then aim a
  tamper at each.
- 🔴🔴 **A ZERO CAN HAVE NO NATURAL FIXTURE AT ALL, AND A PLANTED ONE PROVES LESS.** Arizona's
  "nobody holds two seats" had six real chamber switchers and Alabama's had Tommy Tuberville;
  **Idaho has nobody — not one winner holds an office outside the wave.** So the gate was tested
  with a **planted** second term (C12). ▶ **A planted fixture proves the gate FIRES; it does not
  prove the gate reads the rows a real double-holder would occupy.** Say which you have, and assert
  the absence itself (`P8b`) so the next reader inherits a measurement rather than an assumption.
  - 🟢🟢 **AND WHEN THE FIXTURE IS REAL, IT NEEDS A CONTROL THAT TAKES IT AWAY.** New Mexico's is
    **Stephanie Garcia Richard**, who leaves Commissioner of Public Lands for the Lieutenant
    Governorship with both legs inside the wave on one day — her old term closes *only* because
    Juan Sanchez III is seated into the seat she leaves (Oregon's Helfrich; Utah's Fiefia is the
    same shape with the successor's result missing, **the difference is a result, not a rule**).
    `CC_0506`'s `P9` asserts the fixture EXISTS, and **control C21 removes it and watches `P9`
    report a vacuous zero.** Without C21 the fixture could quietly vanish and leave the post-write
    zero meaning nothing, with every number in both files still green.
- 🔴🔴 **P8 ASKS WHETHER A WINNER HOLDS MORE THAN ONE OFFICE, SO ONLY SOMEBODY WITH A SEAT ALREADY
  CAN TEST IT.** New Mexico's C19 first planted its second term on a winner who holds nothing;
  she ended with exactly one seat, `P8` passed **honestly**, and a later gate fired instead. The
  fixture has to be a re-elected incumbent. ⚠ **And a term with `term_start IS NULL` has an
  UNBOUNDED daterange**, so `office_terms_no_overlap` rejects any second term on that office —
  C20 died on the constraint and printed an `(unparsed)` green RED until the rival term was
  **deleted** rather than closed. ⚠ **And deleting a predecessor to remove a fixture trips the
  "one predecessor per seat" count two gates early** — reassign it instead. Three fixtures, three
  rebuilds, all in one suite that had already reported 28 of 28 red.
- 🔴🔴 **A STATE CAN HAVE NO IN-DATA DATE CONTROL AT ALL, AND THAT IS A FINDING.** Arizona had 80
  terms across three cycles and Washington seven biennia; **Alabama has 17 of 18 state terms with
  `term_start IS NULL`**, and its one dated term is Kay Ivey's 2017-04-10 **accession** on a
  resignation — a succession, not a cycle start, so it corroborates nothing. The strongest control
  available was the Legislature's own arithmetic: § 37-1-3(b)(2) writes *"initial terms beginning
  January 18, 2027"* in words. ▶ **Look for the statute computing its own cycle before concluding a
  state cannot be controlled** — and record the unavailable check beside the ones that passed.
- 🟢 **`scripts/run-migration-controls.mjs` IS THE DRIVER.** It refuses a non-unique needle,
  re-reads each file to prove the replacement landed, **runs the untampered chain FIRST as a
  negative control**, and records the gate each tamper ACTUALLY fired on. `--check` validates a
  spec without a database; `--self-test` proves the tool itself goes red on a planted fault.
  🔴 **ONE TAMPER PER STEP — A STEP IS A FILE, NOT AN EDIT.** Two `{tamper: X}` steps run file X
  **twice**; Arizona's C13b did that and died on the seating file's own "applied before" gate.
  Put the second change in the DATA.
- 🔴🔴 **READ THE MESSAGE, NOT THE COLOUR.** Five controls in three days went red for the wrong
  reason: two Maryland tampers died on a **database CHECK constraint**, Arizona's C5 died on
  `column "id" does not exist` and printed a green RED with the gate shown as **`(unparsed)`**, and
  **Alabama's C12 did it twice in a row** — first on the `office_terms_no_overlap` EXCLUSION
  constraint (reopening a closed term collides with the successor the federal programme already
  seated), then, after deleting that successor's term instead, on the *dates* file's `P2`, because
  the seat fell back into `office_pending_winner` and the state then had 14 pending seats, not 13.
  🟢 **Both of those were real gates doing real work and neither tested the gate aimed at.**
  ▶ Moving the successor's term forward, rather than removing it, was what finally reached `P9`.
  **A fixture that has to be built out of live rows needs as much reading as the gate does.**
  ⚠ **And a tamper that did not APPLY looks exactly like a pass** — Arizona's C18 looked for a
  `result IS NULL` row that does not exist, and the chain simply passed. The harness reported
  **DID NOT FIRE**, which is the whole reason it re-reads what it built.
- 🟢 **`scripts/rehearse-migration-chain.mjs`** runs several migrations in ONE transaction against
  prod and always rolls back. 🔴 **Rehearsing a chain file-by-file proves nothing and fails in the
  direction that reads as success.** `--verify <query.sql>` is how a pin is captured.
- ⚠ **Put `P1`/`P2` (already applied?) ABOVE the row-count checks.** On a second run the seats have
  left `office_pending_winner`, so a count check fires first and blames the data.
- ⚠ **Capture the predecessor pre-image, and expect it to be SMALLER than the seat count when a
  seat is vacant.** ⚠ **And expect it to be DATED in some states**: 89 of Arizona's 93 predecessors
  carry a real `term_start`, against 1 of Maryland's 178 — and Arizona's are the very rows its date
  control reads, so the file asserts not one of them moved.
- 🔴 **A FILE THAT PINS ITS SELECTION BY DIGEST MAKES ITS LATER NAMED GATES UNREACHABLE BY ANY
  REALISTIC TAMPER.** Recorded as **backstops, not tested gates**: `CC_0471` assertion 4,
  `CC_0473` 4–6, `CC_0474` P5, `CC_0479` P8 and assertion 6, and `CC_0500` assertion 3c — whose
  discriminating arm reads the **same single row** as the corroboration arm, so no tamper can
  separate them.
- 🔴🔴 **A CONTROL WHOSE FIXTURE THE PROGRAMME WILL MOVE PAST HAS A SHELF LIFE.**
  `control-election-transition-status.mjs` was **red for six days** because it asserted a literal
  the pass had moved past. ▶ **A control locates its fixture by MEASUREMENT and refuses to report
  when it has none left.**

---

## Housekeeping

- 🟢 **NEBRASKA SHIPPED ON `feat/state-seating-ne`** (`CC_0507`, `CC_0508`, the control suite and
  these three documents), applied to production 2026-11-24 and committed with an explicit
  pathspec. Open its PR, or continue from master once it has merged.
- 🔴 **THE `(unparsed)` GREEN RED CAME BACK, AND THE FILE THAT WALKED INTO IT WARNED ABOUT IT.**
  Nebraska's control C16 inserted a second term on a held office and died on the
  `office_terms_no_overlap` EXCLUSION constraint — a term with `term_start IS NULL` has an
  **unbounded** daterange, so nothing can sit beside it. That is verbatim New Mexico's C20, named
  in this suite's own header two screens above the control that repeated it. ▶ **To plant a
  second-seat fixture, REASSIGN an existing term, never insert one**: reassigning leaves the
  digest, the predecessor pre-image and `offices_missing_terms` all untouched, so no other gate
  fires first. 🔴 **And read the message, not the colour** — 25 of 25 red still had one control
  proving nothing.
- 🟢🟢 **PR #1578 IS MERGED (2026-11-24, squashed as `b0fde547c`) AND `feat/state-seating` IS DONE.**
  It carried `CC_0461`-`CC_0506` — sixteen states. **Master CI is green on the merge commit**,
  including the prod-reading gates that run only on push, so the applied migrations and master's
  code agree. ▶ **START THE NEXT WAVE ON A FRESH BRANCH FROM MASTER**, in its own worktree:
  `git worktree add -b feat/<topic> /c/ev-accounts-<topic> origin/master`. Commit with an explicit
  pathspec. **Do not add to `feat/state-seating`** — it is merged and its PR is closed.
- 🔴🔴 **CI WAS RED FOR FIVE WAVES AND NOBODY LOOKED — INCLUDING ME, WHO READ A STALE RUN AND
  REPORTED IT GREEN.** `static guards` had failed since `CC_0496` because
  `check-office-terms-incumbency-guards.mjs` wants every branch-added migration that writes
  `essentials.office_terms` to carry a `-- @incumbency-decision: <gated|no-effect> — why` line, and
  **none of the six seating files had one**. All six already carried the real gate, so what was
  missing was the *declaration*, not the measurement. ▶ **`gh pr checks` can hand you a run for an
  older SHA — check the run's `headSha` against your own HEAD before believing it.** ▶ And **add
  that line to every new seating file**; the six existing ones are the worked examples. 🟢 Green
  on Nebraska's `CC_0507`/`CC_0508` with the line present, checked against the run's own `headSha`.
  - 🔴🔴 **`gh pr checks --json` RETURNS AN EMPTY ARRAY HERE AND EXITS 0, WHILE THE PLAIN FORM
    WORKS.** Measured 2026-11-24 on PR #1602: `gh pr checks 1602` printed 24 rows and
    `gh pr checks 1602 --json name,bucket` printed **nothing**, exit code 0. A watcher built on
    the JSON form therefore saw "no checks yet" forever and **sat silent for thirty minutes while
    CI had already finished green** — a detector whose "nothing found" path is indistinguishable
    from "still waiting", which is this file's own uniform-answer rule wearing a different hat.
    ▶ **Poll the PLAIN form and parse its columns**, and make any CI watcher emit something on an
    *empty* result rather than looping on it.
- 🟢 **`control-election-transition-status.mjs` RE-RUN AFTER NEBRASKA AND GREEN** (2026-11-24):
  2,303 races examined, states `{1:473, 2:170, 4:1599, 5:61}`, fixture located by measurement,
  both rollbacks reverted. 🟢 **Its histogram is an independent corroboration of the wave** —
  state 2 → 4 moved by exactly 13 against New Mexico's `{1:473, 2:183, 4:1586, 5:61}`. **It is not
  in CI**, so it runs only when somebody runs it; run it after any wave that moves a lot of rows.
- **Env:** the worktree has no `.env`. Prefix commands with
  `set -a && . /c/EV-Accounts/backend/.env >/dev/null 2>&1; set +a`.
- **Steward:** jurisdiction leases are 24h and expire on their own. `state:nm` was taken for this
  work and lapses 2026-11-25. **Claim the next state's scope before starting it.**
- **Live tracker artifact:** `https://claude.ai/artifact/68XRWM6MpNd2W6Phit4QNo` — refresh it as
  part of finishing each state (`node scripts/build-transition-dataset.mjs`, upload the three
  CSVs, update the three `datasets/*` docs **in place**, and re-read the hand-kept `assignments`
  file against them).
  - 🟢🟢 **THE TRACKER ASKS THE SEATING QUESTION OVER THE OFFICES A RACE CAN FILL**, not over the
    single office the race hangs on. A row is a RACE and a seating is an OFFICE; a multi-seat
    contest seats its winners across the **sibling** offices of the same district, chamber and
    title. ⚠ **The cancelled-election blindness stays and must**: 102 seats with no winner to read
    is a fact about the race, not the office.
  - 🔴 **RE-READ THE HAND-KEPT `assignments` FILE FROM THE ARTIFACT, NOT FROM THE REPO.** On
    2026-11-24 the repo copy was three refreshes stale, and refreshing from it would have
    re-uploaded words the operator had already corrected on the page. **Check the file the page
    actually serves.** It is the only dataset the builder does not compute, so it goes stale on
    its own, and the status word is the operator's to change.
    - 🟢 **THE TWO COPIES ARE STILL BYTE-IDENTICAL, RE-VERIFIED AFTER ALABAMA (2026-11-24)** by
      downloading the served blob and hashing both: `84adb2fc…5a42a2` on each side. **That closes
      the incident and not the rule** — it can drift
      again the moment either side is edited alone. ▶ **Run the page's own colour regex over the
      five status words, with a positive control first**: `/block/i` → RED, `/progress/i` →
      AMBER, anything else grey, and *"Blocked on certification"* must paint RED before a green
      result means anything. Last read: four `In progress`, one `Barely started`, nothing red,
      and `blocked` 0 in all five waves.
- **Step 9 is not done until a real address goes through `api.empowered.vote`.** Reasoning about a
  read path is not measuring it. Pick an address in a seat that CHANGES HANDS, and one in a seat
  that is vacant if the state has one — a re-election renders the same whether the file worked or
  not. 🔴 **The probe must refuse to report if it finds NO incoming holder anywhere**: the fields
  are `incoming_holder_name` / `incoming_on`, and a uniform "no incoming" is a broken detector.
