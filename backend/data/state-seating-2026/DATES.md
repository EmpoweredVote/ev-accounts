# Sourced start dates — the ledger

One block per state. **Read [`REGISTER.md`](./REGISTER.md) for the recipe and the two rulings, and
[`SOURCING.md`](./SOURCING.md) for the queue.** This file is step 2's output and nothing else: it
carries the six things `office_swearing_in` needs, per body, with the clause quoted and the URL
that was opened. A state's date migration is written from its block here, not from memory.

🔴 **Every date below was read off the provision, in a page opened and read.** A search result or a
`WebFetch` summary located some of these documents; none of them is the source of a date.

🔴 **Nothing here is a swearing-in date unless its block says so.** The column is named
`swearing_in_date` and the register's step 2 asks the question explicitly, because states differ:
some fix the term to a calendar date and hold the oath afterwards, some begin the term **on
qualification**, which IS the oath.

---

## MA — Massachusetts · 204 offices · ✅ sourced 2026-11-22

🔴🔴 **ONE CLAUSE, THREE DATES. MASSACHUSETTS DOES NOT DATE ITS STATE TIER TOGETHER.** The queue
in `SOURCING.md` is built on "one constitutional clause usually dates a state's House, Senate and
executives together". For Massachusetts the first half is true and the second is false: a single
sentence-group — Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII — names **three
different days** for the three groups, and the gap between the earliest and the latest is a
fortnight. A state whose House date was copied onto its Attorney General would put her in office
**14 days early**.

| body | offices | start date | group in the clause |
|---|---|---|---|
| House of Representatives | 159 | **2027-01-06** | senators and representatives |
| Senate | 40 | **2027-01-06** | senators and representatives |
| Governor · Lieutenant Governor | 2 | **2027-01-07** (noon) | governor and lieutenant-governor |
| Attorney General · Treasurer and Receiver-General · Auditor of the Commonwealth | 3 | **2027-01-20** | secretary, treasurer, attorney general, auditor |

### The authority

**Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII** (1966). Quoted from the
page, in the clause's own order:

> The terms of the governor and lieutenant-governor shall begin at noon on the Thursday next
> following the first Wednesday in January succeeding their election …
>
> The terms of the secretary, treasurer and receiver-general, attorney general, and auditor shall
> begin with the third Wednesday in January succeeding their election …
>
> The terms of senators and representatives shall begin with the first Wednesday in January
> succeeding their election and shall extend to the first Wednesday in January in the third year
> following their election and until their successors are chosen and qualified.

⚠ **The two superseded versions of this article are still printed on the same page and both read
plausibly.** Amend. Art. LXIV § 1 as originally adopted (1918) is marked *"Superseded by
Amendments, Art. LXXX"*; Art. LXXX's replacement is marked *"Annulled and superseded by
Amendments, Art. LXXXII"*. All three carry the same three-way split, so a reader who stopped at
the first would get the right days for the wrong reason — but Art. LXXX still has the governor on
a **two-year** term and Art. LXIV as adopted has the whole slate biennial, which is why the
quadrennial clause matters: **2026 is a Massachusetts gubernatorial year only under Art. LXXXII.**

### The source

`https://malegislature.gov/Laws/Constitution` — the General Court's own publication of the
Constitution of the Commonwealth. Fetched and read in full 2026-11-22 (458,545 bytes, HTTP 200,
`text/html`); the article texts above are at "Article LXXXII" in the Articles of Amendment.

### Basis

`statute` for all four rows — a constitutional provision, not a convening notice.

### Term start or oath? — **term start, and the oath is a separate, later event**

The clause fixes each term to a **calendar date** ("shall begin at noon on the Thursday next
following…", "shall begin with the first Wednesday in January…"). It nowhere conditions the start
on qualification.

The oath is **Mass. Const. Part 2, Ch. VI, Art. I**, read on the same page: every person chosen
"shall, **before he enters on the discharge of the business** of his place or office, take and
subscribe the following declaration, and oaths or affirmations". That gates the *discharge of the
duties*, not the beginning of the term. 🔴 **So Massachusetts' date is a term start and must not
be written as a swearing-in.**

⚠ **"…and until their successors are chosen and qualified" is about the PREVIOUS term's END, not
this one's start.** It extends a sitting member's tenure if no successor has qualified; it does
not move the successor's term start, and it does not create an overlap in the normal case.
`seat_officeholder` closes each predecessor at `term_start - 1` = **2027-01-05** for the
legislature, which is exactly the day before the successors' terms begin. Nothing to reconcile.

### Controls — the clause read against three facts it did not produce

🔴 A reading of a provision is a reading until something independent agrees with it.

1. **The legislature's own journal, in its own words.** `JOURNAL OF THE HOUSE`,
   `https://malegislature.gov/Journal/House/193/hj01042023.pdf` (HTTP 200, 473,373 bytes, opened
   and read 2026-11-22), page 1: *"The one hundred and ninety-third General Court of the
   Commonwealth of Massachusetts convened at the State House in Boston on the **first Wednesday of
   January**, being the fourth day of the year two thousand twenty-three"* — and the members-elect
   "assembled and were called to order" that day. First Wednesday of January 2023 **was** the 4th.
2. **Our own data, written by a pass that never read this clause.** `essentials.office_terms` holds
   Maura Healey's term starting **2023-01-05**, backfilled by migration 1459 from
   `offices.politician_id`. The Thursday next following the first Wednesday of January 2023 **was**
   the 5th.
3. **The third-Wednesday group, which is the least intuitive of the three and the one most worth
   checking.** Andrea Campbell was sworn in as Attorney General, and William Galvin and Deborah
   Goldberg for their own offices, on **2023-01-18** — the third Wednesday of January 2023 — widely
   datelined (Boston Globe, WGBH, Boston.com, all 2023-01-18). ⚠ **This one is a news dateline, not
   a document**, and it is recorded as the weaker control it is. It is corroboration that the
   clause is applied as written; the clause is the authority.

All three dates reproduce from the arithmetic, checked in code rather than counted by hand:
Wednesdays in January 2023 are 4, 11, **18**; in January 2027 they are **6**, 13, **20**, and the
Thursday next following the first is **the 7th**.

### Carried into the row

| field | House + Senate | Governor + Lt. Governor | AG + Treasurer + Auditor |
|---|---|---|---|
| `election_date` | 2026-11-03 | 2026-11-03 | 2026-11-03 |
| `swearing_in_date` | 2027-01-06 | 2027-01-07 | 2027-01-20 |
| `window_end_date` | NULL | NULL | NULL |
| `basis` | `statute` | `statute` | `statute` |
| `rule_id` | `ma-const-amend-64-s1-legislators` | `ma-const-amend-64-s1-gov-ltgov` | `ma-const-amend-64-s1-constitutional-officers` |

`authority` carries the quoted sentence for that group plus the citation
*"Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII"*; `source` carries the
malegislature.gov URL and the date read; `notes` records that the date is a **term start** and
that Ch. VI Art. I's oath is a separate event.

### Two things the next step inherits

- ⚠ **The Secretary of the Commonwealth is NOT in the pending set.** Massachusetts has six
  statewide executives and `essentials.office_pending_winner` holds five: Governor, Lieutenant
  Governor, Attorney General, Auditor and Treasurer. The Secretary's office exists and
  William Francis Galvin holds it, but no 2026 winner is recorded against it. That is a result or
  seeding gap, not a dating one — the third-Wednesday row above covers the office whenever it is
  filled. **Do not read "5 executives" as Massachusetts' whole slate.**
- ⚠ **159 of the House's 160 offices are pending, and 2 House seats are flagged vacant.** The
  register's `no record` column puts 18 House winners and 3 Senate winners with no `politicians`
  row — step 4 work, against the chamber's own roster.

---

## ME — Maine · 184 offices · ✅ sourced 2026-11-22

🔴🔴 **MAINE IS THE DEADLINE. THE LEGISLATIVE TERM BEGINS 2026-12-01 — NINE DAYS FROM THE DAY
THIS WAS SOURCED.** Every other body in the pass starts in January 2027. The register sorts dated
bodies soonest-first and undated ones below them, so dating Maine moves 183 of its 184 offices
from the bottom of the queue to the top of it. ▶ **Re-sort the register.**

| body | offices | start date | the clause |
|---|---|---|---|
| House of Representatives | 149 pending (of 154) | **2026-12-01** (Tue) | Art. IV, Pt. First, § 2 |
| Senate | 34 pending (of 35) | **2026-12-01** (Tue) | Art. IV, Pt. Second, § 1 |
| Governor | 1 | **2027-01-06** (Wed) | Art. V, Pt. First, § 2 |

### 🔴🔴 The term start is the day BEFORE the Legislature convenes, and every published account gives the convening date

The Legislature convenes **2026-12-02**, the first Wednesday of December (Art. IV, Pt. Third, § 1).
That is the date in `CLAUDE.md`, in `seed-me-municipal-2026/ROSTERS.md`, in the Legislators'
Handbook, and in every news report of a swearing-in. **It is not the term start.** The term start
is `2026-12-01`, and a pass that reached for the number everyone publishes would be one day wrong
on 183 seats.

### The authority

**Me. Const. Art. IV, Pt. First, § 2** (House):

> The House of Representatives shall consist of 151 members, to be elected by the qualified
> electors, and **hold their office 2 years from the day next preceding the first Wednesday in
> December following the general election**.

**Me. Const. Art. IV, Pt. Second, § 1** (Senate) — the Senate has no date of its own and takes the
House's:

> The Senate shall consist of an odd number of Senators, not less than 31 nor more than 35,
> **elected at the same time and for the same term as Representatives** by the qualified electors
> of the districts into which the State shall be from time to time divided.

**Me. Const. Art. V, Pt. First, § 2** (Governor):

> The Governor shall be elected by the qualified electors, and shall **hold the office for 4 years
> from the first Wednesday after the first Tuesday of January next following the election** and
> until the successor to the Governor has been duly elected and qualified.

### The source

`https://legislature.maine.gov/const/` → the Revisor of Statutes' application at
`https://legislature.maine.gov/ros/LawsOfMaine/#Const`, read 2026-11-22. ⚠ **That page is a
JavaScript application: `curl` returns a 5,654-byte "enable JavaScript" stub with no constitution
in it.** It was opened in a browser and the article texts read from the rendered document. Header:
*"CONSTITUTION OF THE STATE OF MAINE (Arranged by the Chief Justice … approved by the Maine State
Legislature, Resolve 2023, chapter 86 …) (Includes CR 2023, c. 1 and CR 2023, c. 2)"* — the
current official arrangement. A PDF of the same text is at `https://legislature.maine.gov/doc/10674`.

### Basis

`statute` for all three rows.

### Term start or oath? — **term start, and here the two are DIFFERENT DAYS**

Maine is the first state in this pass where the answer changes the date.

- **The oath** is Art. IX, § 1: every person elected "shall, **before entering on the discharge of
  the duties** of that place or office, take and subscribe the following oath or affirmation",
  administered to Senators and Representatives **before the Governor**.
- **The House's own record says what the oath is for.** `JOURNAL AND LEGISLATIVE RECORD – HOUSE,
  December 4, 2024` (the equivalent day of the last cycle), opened and read: a committee waits
  upon the Governor "to administer to them the oaths required by the Constitution **to qualify
  them to enter upon the discharge of their official duties**", and then "The Governor, the
  Honorable JANET T. MILLS, entered and administered to the members-elect and they subscribed the
  oaths". The oath qualifies them to act. It does not start the term.
  Source: `https://legislature.maine.gov/house/Repository/Documents/132/LegislativeRecords/63b12a60-3275-4662-a4b0-47bc70c89dff_20241204.pdf`
  (HTTP 200, `application/pdf`, 456,263 bytes, read 2026-11-22).

So the term runs from a calendar date and the oath falls the next morning.

### 🔴 The one-day question, and what settled it

"**hold their office 2 years FROM the day next preceding the first Wednesday in December**" has two
readings, and they differ by exactly one day:

1. **inclusive** — the term begins ON the day next preceding, Tuesday **2026-12-01**;
2. **exclusive** — "2 years from" Tuesday means the term begins the next day, Wednesday
   **2026-12-02**, which is also the convening day and the oath day.

⚠ **Reading 2 is not a straw man.** Art. IX, § 1 contains the phrase "the senior Associate Justice
… present at the State Capitol **on the first day of the term** for which said Senators and
Representatives shall have been elected" — in a fallback about who administers the oath when the
Governor cannot. Read literally beside the oath being administered at the Capitol on the Wednesday,
it says the Wednesday is the first day of the term. And Art. IV, Pt. First, § 5 has the House
"finally determine who are elected" **on** that Wednesday, which makes a Tuesday start read oddly.

**Two independent controls settle it for reading 1.**

🟢 **1. The pre-1975 text of the very same sentence, which names the meeting explicitly.** The
Constitution as amended through 1973 — `https://lldc.mainelegislature.org/Open/Const/Versions/MeConst_1973_Amd.pdf`
(the Law and Legislative Reference Library's own digital collection; HTTP 200, `application/pdf`,
2,652,185 bytes, opened and read 2026-11-22) — gives Art. IV, Pt. First, § 2 as:

> …and **hold their office two years from the day next preceding the biennial meeting of the
> Legislature**.

The 1975 amendment that moved convening to December replaced *"the biennial meeting of the
Legislature"* with *"the first Wednesday in December following the general election"* and **changed
nothing else**. 🔴 **So "the day next preceding" was always measured against the day the
Legislature MEETS, and it exists to put the term start one day EARLIER than the meeting.** Under
reading 2 the phrase would do nothing at all — "two years from the day next preceding the
meeting", exclusive, is just "from the meeting", and the drafters would have written that. A
clause is not read to be surplusage.

🟢 **2. The same construction elsewhere in the same constitution, with a known answer.** Art. V,
Pt. First, § 2 gives the Governor the office "for 4 years **from** the first Wednesday after the
first Tuesday of January" — no "day next preceding". The first Wednesday after the first Tuesday
of January 2019 was **2019-01-02**, and `essentials.office_terms` carries Janet Mills' term
starting exactly `2019-01-02`, sourced by `CA_0352` to `maine.gov/governor/mills/about` and
`nga.org/governors/maine` and read 2026-11-03 — a date written by a pass that never saw this
clause. **So "from X" in this constitution INCLUDES X.** Applied to Art. IV, Pt. First, § 2, "from
the day next preceding" includes the day next preceding: the Tuesday.

Both controls point the same way and neither was derived from the other.

⚠ **Ballotpedia agrees** — Maine legislators "assume office the day before the first Wednesday of
December". Recorded as the aggregator it is. It is not why this is written 2026-12-01.

⚠ **A search of the Maine Revised Statutes returned nothing and PROVED NOTHING.** The Revisor's
full-text search at `legislature.maine.gov/legis/statutes/search.asp` returns an identical,
result-free page for a phrase that certainly exists in Title 3 § 2 ("first Wednesday of December")
and for deliberate nonsense. **The positive control failed, so the tool is blind and its silence
is not evidence.** 3 M.R.S. § 2 was read directly instead: it sets the legislative *salary*
biennium from the first Wednesday of December "until the day before the first Wednesday of
December" two years later — a pay period, not a term, and it is **not** a counter-authority.

### Arithmetic, checked in code rather than counted

| year | first Wed of Dec | day next preceding | first Tue of Jan | first Wed after it |
|---|---|---|---|---|
| 2022 | 2022-12-07 | 2022-12-06 | — | — |
| 2024 | 2024-12-04 | 2024-12-03 | — | — |
| **2026** | **2026-12-02** | **2026-12-01** | — | — |
| 2019 | — | — | 2019-01-01 | **2019-01-02** ← Mills, confirmed |
| 2023 | — | — | 2023-01-03 | 2023-01-04 |
| **2027** | — | — | **2027-01-05** | **2027-01-06** |

### Carried into the row

| field | House + Senate | Governor |
|---|---|---|
| `election_date` | 2026-11-03 | 2026-11-03 |
| `swearing_in_date` | **2026-12-01** | **2027-01-06** |
| `window_end_date` | NULL | NULL |
| `basis` | `statute` | `statute` |
| `rule_id` | `me-const-art4-day-before-first-wed-december` | `me-const-art5-pt1-s2-first-wed-after-first-tue-january` |

`notes` must record that the term start is **one day before** the Legislature convenes and takes
the oath (2026-12-02), because the next reader will meet the convening date first everywhere else.

### Five things the next step inherits

- 🔴 **77 winners have no `politicians` row** — 61 House, 16 Senate, the largest seeding job in the
  pass — and the term starts in nine days. Step 4 against the chamber's own roster is the critical
  path for Maine, not the date.
- ⚠ **Three House offices are tribal and are correctly NOT in the pending set.** Penobscot,
  Passamaquoddy and Houlton Band of Maliseet Indians are `representation_basis = 'membership'`,
  seated by their nations rather than at a general election. The Penobscot seat is flagged vacant
  since 2015-05-27. **A wave must not sweep them in.** See `seed-me-municipal-2026/ROSTERS.md`.
- ⚠ **Three ordinary seats have no recorded winner**: State House District 86, State House
  District 96 and State Senate District 18. None is flagged vacant. That is a result gap, not a
  dating one, and it is why the counts read 149 of 154 and 34 of 35.
- ▶ **2026-12-02 — the Mi'kmaq Nation's fourth tribal seat is created, not before.** The dated
  follow-up already written up in `ROSTERS.md`, with both exits recorded. ⚠ **The citation there
  reads "PL 2026 c. 705"; the Revisor prints it as `PL 2025, c. 705, Pt. A, §1 (AMD)`** on
  `legislature.maine.gov/statutes/3/title3sec1.html` — Maine numbers a public law by the
  legislature's first year, and the law was signed 2026-04-15. Same law; use the Revisor's form in
  anything citable.
- ⚠ **The Governor's 2027-01-06 is the same day as Massachusetts' legislature.** Two different
  clauses in two states; the coincidence means nothing and the rows must not be shared.

---

## WA — Washington · 118 offices · ✅ sourced 2026-11-22

**One date, one citation, and it is a STATUTE rather than the constitution.**

| body | offices | start date | authority |
|---|---|---|---|
| House of Representatives | 95 pending (of 98) | **2027-01-11** (Mon) | RCW 44.04.021 |
| Senate | 23 pending (of 49) | **2027-01-11** (Mon) | RCW 44.04.021 |

### 🔴 The constitution does not answer this, and reading only the constitution would leave Washington undatable

Wash. Const. Art. II fixes the **length** of a legislative term and never its start:

> **SECTION 5 ELECTIONS, WHEN TO BE HELD.** … members of the house of representatives shall be
> elected biennially and their term of office shall be two years …
>
> **SECTION 6 ELECTION AND TERM OF OFFICE OF SENATORS.** … They shall be elected for the term of
> four years, one-half of their number retiring every two years.

⚠ **Art. III, § 4 DOES name a commencement date — for the executives, not the legislature**: *"The
terms of all officers named in section one of this article shall commence on the second Monday in
January after their election until otherwise provided by law."* It is the same day, which is
exactly what makes it dangerous: **citing Art. III § 4 for a legislator gives the right answer from
the wrong provision**, and the provision is about offices this wave does not touch.

### The authority

**RCW 44.04.021 — Commencement of terms of office**, quoted in full:

> The regular term of office of each senator and representative shall commence on the second Monday
> in January following the date of election.
>
> [ 1987 c 13 § 1; 1981 c 288 § 68. Formerly RCW 44.07B.870. ]

Second Monday in January 2027 = **2027-01-11**.

⚠ **The word "regular" is load-bearing and is why the existing data has outliers** — see the
control below. A term filled by appointment is not a regular term and does not start on this day.

### The source

`https://app.leg.wa.gov/RCW/default.aspx?cite=44.04.021` — the Code Reviser's own publication of
the Revised Code of Washington, fetched and read 2026-11-22 (HTTP 200, 107,820 bytes). The chapter
listing that led to it is `?cite=44.04`. The constitutional sections above were read from
`https://leg.wa.gov/media/o3fg0ey1/washington-state-constitution.pdf` (HTTP 200,
`application/pdf`, 1,939,842 bytes, the Code Reviser's current arrangement, footer-dated
2025-12-11).

### Basis

`statute`.

### Term start or oath? — **term start, a calendar date, and the oath falls on the same day**

RCW 44.04.021 names a day of the calendar and attaches no condition to it. The oath is separate
(Wash. Const. Art. I, § 6 governs only the *mode* of administering one).

⚠ **Washington's session convenes on the SAME day** — RCW 44.04.010: *"Regular sessions of the
legislature shall be held annually, commencing on the second Monday of January."* So for
Washington the two events coincide, as they did for Wisconsin in `CC_0462`. 🔴 **That coincidence
is not a reason to cite the session statute.** It is 44.04.021 that says when the term starts;
44.04.010 would still be true if the term began elsewhere, and Maine is the proof that the two can
be different days.

### Control — seven biennia of the Legislature's own member service agree, and nobody consulted this statute to write them

`essentials.office_terms` holds Washington legislative terms sourced from
`wslwebservices.leg.wa.gov SponsorService`, the Legislature's own member web service. Grouping them
by `term_start` puts every biennial cluster **exactly** on the second Monday in January, computed
independently:

| cycle | second Monday in January | rows in our data on that date |
|---|---|---|
| 2013 | 2013-01-14 | 5 |
| 2015 | 2015-01-12 | 6 |
| 2017 | 2017-01-09 | 7 |
| 2019 | 2019-01-14 | 12 |
| 2021 | 2021-01-11 | 16 |
| 2023 | 2023-01-09 | 23 |
| 2025 | 2025-01-13 | 25 |

🟢 **Seven for seven, across 94 rows, with no biennial cluster anywhere else.**

⚠ **The off-dates in that table are not counter-evidence, and checking why matters.** Rows at
2024-12-11, 2025-01-07, 2025-01-21, 2023-08-28, 2022-12-09, 2021-11-02, 2020-05-13 and so on are
**appointments to vacancies**, which in Washington are made by county legislative authorities at
any time of year. RCW 44.04.021 governs the **regular** term only, so these are outside it by the
statute's own words rather than in conflict with it. A run of dates scattered through the calendar
beside a hard biennial spine is the signature of exactly that.

### Carried into the row

| field | House + Senate |
|---|---|
| `election_date` | 2026-11-03 |
| `swearing_in_date` | **2027-01-11** |
| `window_end_date` | NULL |
| `basis` | `statute` |
| `rule_id` | `wa-rcw-44-04-021-second-monday-january` |

### Three things the next step inherits

- ⚠ **23 of Washington's 49 Senate seats are pending, and that is correct.** The Senate is
  staggered — "one-half of their number retiring every two years" (Art. II § 6) — so the other 26
  are mid-term and must not be swept in. 🔴 **This is NOT a Ruling A situation**: each pending
  Senate office carries exactly one winner. Ruling A's refusal is about a multi-seat *race*
  attaching several winners to one office row; a staggered chamber with one winner per office is
  ordinary.
- ⚠ **95 of 98 House offices are pending.** Three carry no recorded winner. No Washington state
  office of any tier is flagged vacant.
- ⚠ **Washington's 9 STATE_EXEC offices are not in this pass** — none was on the 2026 ballot. ⚠ But
  our existing data for them disagrees with Art. III § 4 by two days: two rows read `2025-01-15`
  (backfilled by migration 1459 as "first day in office") where the second Monday of January 2025
  was `2025-01-13`, and one row already reads `2025-01-13`. **Known, out of scope here, and worth
  re-sourcing when Washington's executives next come up** — do not "fix" one of them without
  re-sourcing it, which is the standing rule for the `vacant_since` inconsistencies in `CLAUDE.md`.
