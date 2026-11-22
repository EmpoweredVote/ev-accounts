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

🔴🔴 **THE ORDERING CONDITION HAS NOW FIRED. MAINE IS OVERDUE-SOON AND GOES FIRST.** This line
used to read *"nothing here is dated yet, so nothing is overdue, and that ordering stands until a
citation turns up a date sooner than 2027-01-01"*. Maine's citation turned up **2026-12-01** —
the day next preceding the first Wednesday of December, nine days after it was sourced, and the
only date in the whole pass that is not in January 2027. ▶ **Work ME before the rest of the
by-size order, and note that its 77 missing `politicians` rows, not its date, are its critical
path.** See [`DATES.md`](./DATES.md) § ME.

## The rules that will bite in this particular task

- 🔴 **`WebFetch` may LOCATE a document and may never be the source of a date.** Open the page and
  read the clause. A search summary is a lead, not evidence.
- 🔴 **Read what the date is a date OF.** Some states fix the term to a calendar date with the oath
  afterwards; others begin the term **on qualification**, which IS the oath. Wisconsin's two events
  fall on one day; Indiana's constitution names only the term. Decide per body, in writing, in the
  migration header.
- 🔴 **`chambers.inauguration_rules` is a lead, not a source** — 15 chambers carry it and the
  quality is uneven. The ones that already compute a 2026 date are marked ▶ below; the ones that
  name no authority are marked ⚠ and must be re-sourced.
- 🔴 **THE CONSTITUTION MAY NOT CARRY THE ANSWER AT ALL — AND THE NEAREST PROVISION THAT DOES CAN
  BE THE WRONG ONE.** Washington's constitution fixes only the *length* of a legislative term
  (Art. II §§ 5–6). The start is `RCW 44.04.021`. ⚠ Art. III § 4 *does* name "the second Monday in
  January" — **for the executives** — and it is the same day, so citing it for a legislator gives
  the right date from a provision about other offices. ▶ **When a constitution names a term length
  and no start, go looking for the statute; do not reach for the nearest date in the document.**
- 🔴 **The chamber's own roster and the legislature's own publication outrank every aggregator.**
  `api.iga.in.gov` is what `CA_0396` used for Indiana. Prefer the state's own site for its
  constitution over any mirror.
- ⚠ **A legislative journal settles a disagreement between aggregators.**
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
| *(nothing else yet)* | | | | |
