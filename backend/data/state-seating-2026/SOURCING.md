# Sourcing the 69 bodies — the work queue

**Read [`REGISTER.md`](./REGISTER.md) first.** It holds the nine-step recipe, Ruling A
(multi-member seats) and Ruling B (called results), the citation standard, and what the four
shipped waves did. This file is only the queue and the running state of it.

**Sourced dates go in [`DATES.md`](./DATES.md)**, one block per state, in the shape
`office_swearing_in` takes. A state's date migration is written from its block there.

## 🔴 The research unit is the STATE, not the body

69 bodies collapse to **41 states**, because one constitutional clause usually dates a state's
House, Senate and executives together. Wisconsin was three bodies and one citation; Indiana's
clause covers its whole General Assembly. **Source per state, then write one date migration per
state covering every body that clause answers** — and where a body turns out to have its own rule
(a board, a commission), give it its own row and its own citation.

🔴🔴 **ONE CLAUSE IS NOT ONE DATE, AND MASSACHUSETTS — THE FIRST STATE WORKED — IS THE
COUNTER-EXAMPLE.** A single sentence-group of `Mass. Const. Amend. Art. LXIV § 1` gives
legislators the **first** Wednesday in January, the Governor and Lieutenant Governor **noon on the
Thursday next following** it, and the Attorney General, Treasurer and Auditor the **third**
Wednesday — three days spanning a fortnight. Copying a state's House date onto its executives
would have put four Massachusetts officers in office 14 days early. ▶ **Read the clause to its
end and count the groups it names before deciding how many rows the state needs.**

Order below is by offices, because that is value per citation. **The nine largest states are 978 of
the 1,162 offices.**

🔴🔴 **THE ORDERING CONDITION HAS FIRED THREE TIMES, AND ONE OF THEM IS ALREADY OVERDUE.** This
line used to read *"nothing here is dated yet, so nothing is overdue, and that ordering stands
until a citation turns up a date sooner than 2027-01-01"*. Three citations turned one up:

| state | bodies | offices | start date | status on 2026-11-22 |
|---|---|---|---|---|
| **NV** | Assembly + Senate | **52** | 🔴 **2026-11-04** | **18 DAYS PAST** |
| **ME** | House + Senate | **183** | **2026-12-01** | 9 days away |
| **CA** | Assembly + Senate | **92** | **2026-12-07** | 15 days away |

▶ **Work these three before the rest of the by-size order.** Everything else sourced so far starts
in January 2027.
- 🔴 **Nevada is overdue**: 52 seats whose winners took office on 2026-11-04, so our pages are
  naming the predecessors as current right now. It is also the smallest of the three and uses the
  `CC_0464` already-started shape.
- ⚠ **Maine's critical path is not its date** — it is 77 missing `politicians` rows.
- 🟢 **California's 92 need no new people at all**, so it is the cheapest of the three.

## The rules that will bite in this particular task

- 🔴 **`WebFetch` may LOCATE a document and may never be the source of a date.** Open the page and
  read the clause. A search summary is a lead, not evidence.
- 🔴 **Read what the date is a date OF.** Some states fix the term to a calendar date with the oath
  afterwards; others begin the term **on qualification**, which IS the oath. Wisconsin's two events
  fall on one day; Indiana's constitution names only the term. Decide per body, in writing, in the
  migration header.
  - 🔴🔴 **THREE STATES IN THIS PASS TURN ON THE PHRASE "THE DAY NEXT ___" AND THE BLANK IS NOT
    THE SAME WORD.** Nevada and Indiana say *"from the day next **after** their election"* — the
    term began **2026-11-04**. Maine says *"from the day next **preceding** the first Wednesday in
    December"* — **2026-12-01**, counting back from the meeting instead of forward from the poll.
    One preposition, five weeks apart.
- 🔴 **`chambers.inauguration_rules` is a lead, not a source** — 15 chambers carry it and the
  quality is uneven. The ones that already compute a 2026 date are marked ▶ below; the ones that
  name no authority are marked ⚠ and must be re-sourced.
- 🔴🔴 **A STATUTORY DEFAULT IS NOT THE DATE IF THE STATE IS ALLOWED TO MOVE IT — ASK WHETHER IT
  DID.** Colorado's General Assembly convenes "no later than the second Wednesday of January"
  (`Colo. Const. art. V § 7`), its members' terms begin **on the convening**, and
  `C.R.S. § 2-2-303.5(3)` lets a joint resolution name an earlier day. It did: `HJR26-1031`
  designates **Monday, January 11, 2027**, where the default would be the 13th. Our own data shows
  the default being departed from in **two of the last four cycles**, both of them years a
  governor's term began. ▶ **A "no later than" clause is a deadline. Go and find what was
  actually set, and record `basis = 'published'` when a designating document is what answers.**
- 🔴 **THE CONSTITUTION MAY NOT CARRY THE ANSWER AT ALL — AND THE NEAREST PROVISION THAT DOES CAN
  BE THE WRONG ONE.** Washington's constitution fixes only the *length* of a legislative term
  (Art. II §§ 5–6). The start is `RCW 44.04.021`. ⚠ Art. III § 4 *does* name "the second Monday in
  January" — **for the executives** — and it is the same day, so citing it for a legislator gives
  the right date from a provision about other offices. ▶ **When a constitution names a term length
  and no start, go looking for the statute; do not reach for the nearest date in the document.**
- 🔴 **The chamber's own roster and the legislature's own publication outrank every aggregator.**
  `api.iga.in.gov` is what `CA_0396` used for Indiana. Prefer the state's own site for its
  constitution over any mirror.
- 🔴🔴 **A STATE CAN HAVE A RESIDUAL RULE THAT STARTS A TERM ON ELECTION DAY, AND AN OFFICE WITH NO
  DATE AT ALL.** Maryland's Art. XVII § 4 commences every elected term *"from the time of their
  Election"* unless expressly provided otherwise, and § 9 makes Article XVII prevail over anything
  inconsistent. Its Attorney General and Comptroller have no express date, so the constitution's
  own answer is election day — which **overlaps the predecessor**, who holds "until their successor
  shall qualify", and `office_terms`' exclusion constraint refuses two holders of one office.
  ▶ **When a state names no day, say so and refuse the office.** The honest row is a `published`
  qualification date recorded when it happens. 🔴 Never borrow a sibling officer's date, and never
  `estimated` — the seating migration's P4 refuses it.
- 🟢🟢 **LOOK FOR THE CONSTITUTION'S GENERAL TERM-COMMENCEMENT CLAUSE BEFORE DECIDING AN OFFICE
  HAS NONE.** California's `art. II § 20` — *"Terms of elective offices provided for by this
  Constitution, other than Members of the Legislature, commence on the Monday after January 1
  following election"* — dates the Governor, the five other executives **and** the Board of
  Equalization, whose own article (XIII § 17) names no commencement at all. It sits in the
  **voting** article, so reading Articles IV, V and XIII in order never reaches it. ▶ A full-text
  search of the state's codes finds this class of clause; then open the section and read it.
- 🔴 **A STATE MAY STATE ITS RULE AS AN ANCHOR YEAR PLUS A TERM LENGTH, NOT AS A RECURRING
  FORMULA** — and that shape reads like "no rule". All three of Arizona's are: *"until the first
  Monday in January, **1913**"* (legislature), *"four years beginning on the first Monday of
  January, **1971**"* (executives), *"initial two-year terms beginning on the first Monday in
  January, **2003**"* (Corporation Commission). ⚠ Arizona's legislative clause is titled **Term
  limits of members of state legislature**, so a search for a term-*start* provision never reaches
  it. ▶ **Read a body's whole article, not the section whose title matches.**
- 🔴🔴 **AN OFFICE THE STATE CREATED SINCE THE LAST CYCLE MAY NOT EXIST IN OUR DATA AT ALL, AND
  NOTHING ERRORS.** Arizona elected its first **Lieutenant Governor** on 2026-11-03 under
  `Ariz. Const. art. V § 1(C)` (joint ticket with the Governor) and we hold **no office row** for
  it. ▶ **When a constitution's list of executives has a name your pending set does not, stop and
  check.** Creating the office is an occupancy act — create and seat together, or the drift
  baseline rises.
- ⚠ **A legislative journal settles a disagreement between aggregators.**
- ⚠ **A DATE AND A SEAT ARE SEPARATE QUESTIONS.** Arizona's Corporation Commission has an explicit
  date (`art. XV § 1(B)`) and is still refused for *seating* by Ruling A. It gets an
  `office_swearing_in` row and no term.
- ⚠ **COUNT OFFICES WITHOUT AN INNER JOIN TO `essentials.chambers`.** `offices.chamber_id` is
  nullable and California's Board of Equalization seats carry NULL, so an inner join silently drops
  them — it made California read as 98 offices instead of 99 mid-measurement. `WAVE_SELECTION_SQL`
  does not join chambers at all, which is why the register had the right number.
- ⚠ **`leginfo.legislature.ca.gov` RATE-LIMITS `curl` AT ABOUT THREE FETCHES**, answering HTTP 403
  with a 5,643-byte body. A browser session gets the same page immediately. Slow down or switch
  transport; do not conclude the page is gone.
- 🔴 **`mgaleg.maryland.gov` RETURNS HTTP 200 WITH A "NotFound" PAGE FOR ANY UNKNOWN PATH**, body
  always **57,164 bytes**. Three different URLs "succeeded" that way before a browser showed the
  redirect to `/mgawebsite/Error/NotFound?error=404`. Assert on content, not status.
- Take the lease before working a state:
  `npm run steward --prefix backend -- claim state:<usps> --label "<state> seating dates"`.

## The queue

| # | state | bodies | offices | cum | notes |
|---|---|---|---|---|---|
| 1 | MA | LOWER+UPPER+EXEC | 204 | 204 | 21 winners with no politician record |
| 2 | ME | LOWER+UPPER+EXEC | 184 | 388 | **77 no record** — the largest seeding job in the pass |
| 3 | WA | LOWER+UPPER | 118 | 506 | clean |
| 4 | MD | LOWER+UPPER+EXEC | 117 | 623 | **85 no record · 38 multi-seat → Ruling A** |
| 5 | CA | LOWER+UPPER+EXEC+BOARD | 99 | 722 | ⚠ three EXEC rules say "1st Monday in the new year" and cite nothing |
| 6 | OR | LOWER+UPPER+EXEC | 76 | 798 | 15 no record |
| 7 | AZ | LOWER+UPPER+EXEC | 66 | 864 | **30 multi-seat → Ruling A**; see the staggered note below |
| 8 | NV | LOWER+UPPER+EXEC | 58 | 922 | 13 no record |
| 9 | UT | LOWER+UPPER+BOARD_EDUCATION | 56 | 978 | clean |
| 10 | CO | 5 bodies | 18 | 996 | five separate bodies for 18 seats — expect several citations |
| 11 | TX | BOARD_EDUCATION+EXEC | 14 | 1010 | |
| 12 | AL | EXEC+BOARD_EDUCATION | 13 | 1023 | ▶ SBOE rule cites `Code of Alabama § 16-3-1` and computes **2027-01-18** |
| 13 | NE | EXEC+BOARD+BOARD_EDUCATION | 13 | 1036 | ▶ rules cite `Neb. Const. Art. XVII-5` and compute **2027-01-07** |
| 14 | NM | EXEC+BOARD_EDUCATION | 11 | 1047 | ▶ PEC rule cites HB 9 (2021 2nd S.S. Ch. 3) §3B → **2027-01-01** |
| 15 | GA | EXEC | 10 | 1057 | |
| 16 | AR | EXEC | 7 | 1064 | |
| 17 | ID | EXEC | 7 | 1071 | |
| 18 | SD | EXEC | 6 | 1077 | |
| 19 | NH | BOARD+EXEC | 6 | 1083 | ▶ Executive Council rule quotes `N.H. Const. pt. 2, art. 60` |
| 20 | CT | EXEC | 5 | 1088 | |
| 21 | HI | EXEC | 5 | 1093 | **OHA At-large is staggered — see below** |
| 22 | IL | EXEC | 5 | 1098 | |
| 23 | MI | EXEC | 5 | 1103 | **MSU Trustees and State Board of Education are staggered — see below** |
| 24 | ND | EXEC | 5 | 1108 | |
| 25 | OK | EXEC | 5 | 1113 | |
| 26 | RI | EXEC | 5 | 1118 | |
| 27 | SC | EXEC | 5 | 1123 | |
| 28 | VT | EXEC | 5 | 1128 | |
| 29 | FL | EXEC | 4 | 1132 | |
| 30 | IA | EXEC | 4 | 1136 | |
| 31 | MN | EXEC | 4 | 1140 | |
| 32 | WY | EXEC | 4 | 1144 | |
| 33 | DE | EXEC | 3 | 1147 | |
| 34 | IN | EXEC | 3 | 1150 | ▶ three rules say "January 1st of the year following the election" — needs its own authority; the House clause (`art. 4 §3`) does NOT cover executives |
| 35 | NY | EXEC | 3 | 1153 | |
| 36 | LA | BOARD | 2 | 1155 | ▶ PSC rule reasons from the commission's own term table → **2027-01-01** |
| 37 | OH | EXEC | 2 | 1157 | |
| 38 | PA | EXEC | 2 | 1159 | |
| 39 | KS | EXEC | 1 | 1160 | |
| 40 | MO | EXEC | 1 | 1161 | |
| 41 | TN | EXEC | 1 | 1162 | |

**41 states · 69 bodies · 1,162 offices.**

## 🔴 Four bodies cannot be seated from our data at all

Ruling A's equality clause refuses them, correctly: each is **staggered**, electing part of itself
each cycle, so which seats are up is not in our rows.

| body | winners | eligible offices |
|---|---|---|
| AZ Corporation Commission | 2 | 5 |
| HI Office of Hawaiian Affairs — At-large Trustee | 3 | 4 |
| MSU Trustee | 2 | 8 |
| MI State Board of Education Member | 2 | 8 |

**Each needs its winners' offices named from the body's own published term table, cited in the
migration** — `CLAUDE.md`'s existing rule: *attach the race to the office of the member who is
actually leaving*. Until that is done, seat the rest of their state and leave these out, saying so
in the header. They are 7 offices of the 1,162.

## 🔴 Ten more cannot be DATED at all, which is a different refusal

Ruling A refuses the four above because **which seat** a winner takes is not in our data. These
are refused because **no day exists to write yet** — and the running pattern is that it is a
state's **executive**, never its legislature, that fails this way:

| office | why |
|---|---|
| MD Attorney General | Art. V § 1 gives "four years from the time of his election and qualification" — no calendar date |
| MD Comptroller | Art. VI § 1 gives a length only; falls to Art. XVII § 4, "from the time of their Election", which overlaps the predecessor |
| OR Governor | Art. V § 7 defers to statute; `ORS 176.010` commences the term "upon the publication of the returns by the Speaker of the House" — an **event**, which has not happened |
| AZ State Mine Inspector | Art. XIX gives a term length and no day — and the constitution publishes **two competing 1992 versions** of that article that disagree on whether the term is two years or four. No statute supplies a commencement |
| UT State Board of Education (6) | `20A-14-103` fixes the four-year term and the cycle and names no commencement. 🔴 Its only dates are transitional and land on the **first Monday** in January (2023-01-02, 2025-01-06), which is NOT the legislature's "first day of January" — so the House clause must not be borrowed |
| NV Governor, Lt. Governor, Secretary of State, Attorney General, Treasurer, Controller (6) | Art. 5 §§ 2, 17, 19 run the term "from the time of his installation"; `NRS 282.010(4)` makes that **qualification**. 🟢 But `NRS 282.010(2)` bounds it: qualification must happen **prior to 2027-01-05**, so `window_end_date = 2027-01-04` is sourced even though `swearing_in_date` is not |

Each needs a **`published` date recorded when it happens**. See [`DATES.md`](./DATES.md) for the
confirming document named per office. They are 3 offices of the 1,162, and their states' other
190 proceed without them.

## What to record per body, before writing any migration

For each body, a line carrying all of:

1. the **state** and the **body**;
2. the **date**, as `YYYY-MM-DD`, computed for the 2026 cycle;
3. the **authority** — the provision, quoted, in enough words that a reader can check it;
4. the **source** — the URL actually opened and read, with the date read;
5. the **basis** — `statute` for a constitution or statute, `published` for a chamber's own
   convening notice. 🔴 **Never `estimated`; an estimated date may not seat anybody.**
6. **whether the date is a term start or an oath**, and which the body's law makes controlling.

That is exactly the row `office_swearing_in` takes, and `CC_0445` (Wisconsin) and `CC_0463`
(Indiana) are the two worked shapes.

## Progress

| state | sourced | dated | migration | seated |
|---|---|---|---|---|
| WI | ✅ | ✅ `CC_0445` | — | ✅ `CC_0462` (121) |
| IN — House | ✅ | ✅ `CC_0463` | — | ✅ `CC_0464` (3) |
| MA | ✅ [`DATES.md`](./DATES.md) — **three dates**, 2027-01-06 / -01-07 / -01-20 | ⏳ | | |
| ME | ✅ [`DATES.md`](./DATES.md) — 🔴 **2026-12-01** legislature (NOT the 12-02 convening), 2027-01-06 Governor | ⏳ | | |
| WA | ✅ [`DATES.md`](./DATES.md) — **2027-01-11**, one date; the authority is `RCW 44.04.021`, not the constitution | ⏳ | | |
| MD | ⚠️ [`DATES.md`](./DATES.md) — **115 of 117**: 2027-01-13 legislature, 2027-01-20 Governor. 🔴 **AG and Comptroller REFUSED** — the constitution fixes no day for them | ⏳ | | |
| CA | ✅ [`DATES.md`](./DATES.md) — 🔴 **2026-12-07** legislature (15 days), 2027-01-04 for all seven others under one clause, `art. II § 20` | ⏳ | | |
| OR | ⚠️ [`DATES.md`](./DATES.md) — **75 of 76**: 2027-01-11 legislature. 🔴 **Governor REFUSED** — `ORS 176.010` starts the term at an event, not a day | ⏳ | | |
| AZ | ⚠️ [`DATES.md`](./DATES.md) — **65 of 66** on **2027-01-04**. 🔴 **Mine Inspector REFUSED**; Corporation Commission dated but not seatable; 🔴🔴 **no Lieutenant Governor office exists** | ⏳ | | |
| NV | ⚠️ [`DATES.md`](./DATES.md) — **52 of 58** on 🔴 **2026-11-04, ALREADY PAST**. 🔴 **6 executives REFUSED** — term begins at qualification, bounded before 2027-01-05 | ⏳ | | |
| UT | ⚠️ [`DATES.md`](./DATES.md) — **50 of 56** on **2027-01-01**, the first day of January itself. 🔴 **6 State Board of Education seats REFUSED** | ⏳ | | |
| CO | ✅ [`DATES.md`](./DATES.md) — all 18: legislature **2027-01-11** (`basis = published`, HJR26-1031 — the statutory default would be 2 days wrong), everything else **2027-01-12** | ⏳ | | |
| *(nothing else yet)* | | | | |
