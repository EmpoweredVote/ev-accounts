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

## ME — Maine · 184 offices · ✅ sourced 2026-11-22 · ✅✅ **RE-DERIVED INDEPENDENTLY 2026-11-23 AND IT AGREES**

🟢🟢 **BOTH DATES WERE RE-SOURCED FROM SCRATCH ON 2026-11-23, BY A READER WHO HAD NOT SEEN THIS
BLOCK, AND LANDED ON THE SAME TWO ANSWERS — 2026-12-01 AND 2027-01-06.** That is a control
this entry could not give itself. It also turned up **three things this block did not have**,
and one of them closes a question the first pass left open. They are at the end, under
*What the 2026-11-23 re-derivation added*.

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

🟢🟢 **AND ON 2026-11-23 THE STATUTE THAT SEARCH SHOULD HAVE FOUND WAS READ DIRECTLY, WHICH
CLOSES THE QUESTION THE BLIND TOOL LEFT OPEN.** `21-A M.R.S. § 725`, titled **Commencement of
term of office**, is the statute book's whole answer on the subject:

> County officials elected at the general election take office on January 1st directly
> following election day. **The terms of other officials commence on the day provided in the
> Constitution of the State of Maine** or the Constitution of the United States.

🔴 **THE LEGISLATURE DECLINED TO RESTATE THE DATE AND NAMED THE CONSTITUTION AS THE ONLY
SOURCE.** So there is no statutory override to go looking for, and the failed full-text search
was not merely uninformative — it was hiding a provision that *expressly defers*. ▶ **A STATUTE
CAN BE AUTHORITY BY DEFERRING**, and a deferral is the strongest possible evidence that the
instrument you are reading is the right one. Found by walking the chapter's own table of
contents (`title21-Ach9sec0.html`) instead of searching — the document's own structure again.
⚠ It also names a **different** rule for COUNTY officials, 1 January. That matters for the
local waves and not for this one.
Source: `https://legislature.maine.gov/statutes/21-A/title21-Asec725.html`, read 2026-11-23.

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

### ✅✅ What the 2026-11-23 re-derivation added

🟢🟢 **1. THE LEGISLATURE'S OWN AGENDA FOR *THIS* CYCLE, WHICH NAMES BOTH DAYS.** The first
pass proved the term-start/oath split from the **2024** House journal. The 133rd Legislature's
**Pre-Legislative Conference & Convening Day Agenda**, published by the Legislative Council of
the 132nd, does it for **2026** and in advance:

> 133rd MAINE LEGISLATURE — Pre-Legislative Conference & Convening of the Legislature,
> **November 30 – December 3, 2026**, Maine State House …
> **Tuesday, December 1st** — Pre-Legislative Conference for All Members …
> **Wednesday, December 2nd** — **Convening of the 133rd Maine Legislature, 10:00 AM**,
> Senate Chamber

🔴 **SO THE MEMBERS-ELECT ARE IN AUGUSTA ON TUESDAY 1 DECEMBER — THE DAY THEIR TERMS BEGIN —
AND THE CHAMBER CONVENES AND SWEARS THEM THE NEXT MORNING.** One document shows both days,
for the cycle being seated, from the body itself. It is the strongest corroboration available
for 2026-12-01 and it did not exist in this block.
Source: `https://legislature.maine.gov/doc/12791` (HTTP 200, `application/pdf`, 347,908 bytes,
read 2026-11-23), linked from *Member Resources*, `https://legislature.maine.gov/9686`.

🟢 **2. `21-A M.R.S. § 725` — see above.** The statute defers to the constitution by name.

🟢🟢 **3. THE CONSTITUTION IS REACHABLE WITHOUT A BROWSER AFTER ALL, AND THIS BLOCK SAID IT WAS
NOT.** The correction matters because "open it in Playwright" is the most expensive rung on
the ladder and this host does not need it. `legislature.maine.gov/const/` really does return a
5,654-byte enable-JavaScript stub — but the application it loads fetches **one static file**,
and that file is the whole constitution:

> `https://legislature.maine.gov/ros/LawsOfMaine/App/views/constitution.html`
> — HTTP 200, 59,063 bytes compressed, **125,817 characters of plain text** to a bare `curl`.

▶ **THE SPA'S OWN VIEW FILE IS STATIC.** It was found by navigating once in Playwright and
reading `browser_network_requests` — the South Dakota method — and the answer was four
requests long: `shell.html`, `nav.html`, **`constitution.html`**, `footer.html`. ⚠ **The
`grep -o` context trap bites here**: the plain text is one enormous line, so
`grep -oE '.{N}pattern.{N}'` counts a hit and prints nothing. Use Python `re.finditer`.

### ⚠ What the re-derivation did NOT add, and the near-miss that could have manufactured a finding

🔴🔴 **THE CONSTITUTION SAYS 151 MEMBERS AND WE HOLD 154 HOUSE OFFICES. THAT IS NOT A DEFECT
AND READING IT AS ONE WOULD HAVE BEEN SOUTH DAKOTA IN REVERSE.** Art. IV, Pt. First, § 2 fixes
the House at **151 members**; three further seats — Penobscot Nation, Passamaquoddy Tribe and
the Houlton Band of Maliseet Indians — are seated under the Legislature's **Joint Rules 206(3)
and 316**, not under the membership clause, and are chosen by their nations rather than at a
general election. The Law and Legislative Reference Library's own history records the practice
from 1823 (Penobscot), 1842 (Passamaquoddy) and the 125th Legislature's adoption of S.P. 13 on
2010-12-17 for the Maliseet seat, first filled 2012-01-04.
Source: `https://legislature.maine.gov/lawlibrary/history-of-tribal-representation-in-maine/9261`,
read 2026-11-23.
▶ **A CHAMBER CAN HOLD SEATS ITS CONSTITUTION'S MEMBERSHIP NUMBER DOES NOT COUNT.** 154 = 151
+ 3, and both numbers are right about different things. This block already had the tribal
seats; what it did not have was the trap — that 154 ≠ 151 reads exactly like Connecticut's
"we hold an office the constitution does not cover", which in Connecticut was a **fabrication**
and in South Dakota was a **real missing office**.

🟢 **The three unrecorded races were re-confirmed as a RESULTS gap and not an RCV one.** State
House 86, State House 96 and State Senate 18 each carry two AP-sourced candidates with
`result` NULL on both. ⚠ Maine runs ranked-choice voting, so "the rounds are not finished" is
the obvious explanation and it is the wrong one: `Me. Const. art. IV, Pt. First, § 5` and
Pt. Second, § 5 decide these seats **by plurality**, which is why RCV does not reach a state
general election here. 🟢 And Senate 18 is explained from our own rows rather than assumed:
its sitting holder **Rick Bennett** appears in the 2026 GOVERNOR'S race with `result = 'lost'`,
so he was never on the Senate 18 ballot and the seat is open. Neither candidate is flagged
incumbent, which agrees.

🟢 **The three executives with no 2026 race are correctly absent, and the clauses say why.**
Secretary of State (`art. V, Pt. Second, § 1`), Treasurer (`art. V, Pt. Third, § 1`) and
Attorney General (`art. IX, § 11`) are each *"chosen biennially … by joint ballot of the
Senators and Representatives in convention"* — by the incoming Legislature, not by the voters.
⚠ **They therefore DO have a term start, and this pass will never see it**, because it is keyed
to a legislative election that is not the 2026-11-03 general. Four `STATE_EXEC` offices, one
popular race.

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

---

## MD — Maryland · 117 offices · ⚠️ 115 sourced, **2 REFUSED**, 2026-11-22

🔴🔴 **MARYLAND'S DEFAULT RULE IS THAT A TERM BEGINS ON ELECTION DAY, AND TWO OF ITS THREE
EXECUTIVES FALL UNDER IT.** Art. XVII, § 4 — which Art. XVII, § 9 makes override every other
provision it conflicts with — says the term of an elected officer *"shall, except in cases
otherwise expressly provided herein, **commence from the time of their Election**"*. The General
Assembly and the Governor are expressly provided for elsewhere and are clean. The **Attorney
General and the Comptroller are not**, and neither is datable from the constitution at all.

| body | offices | winners | start date | authority |
|---|---|---|---|---|
| Senate | 47 | 47 | **2027-01-13** | Art. III, § 6 |
| House of Delegates | 67 | **131** | **2027-01-13** | Art. III, § 6 |
| Governor | 1 | 1 | **2027-01-20** | Art. II, § 1 |
| Attorney General | 1 | 1 | 🔴 **REFUSED** | Art. V, § 1 names no date |
| Comptroller | 1 | 1 | 🔴 **REFUSED** | Art. VI, § 1 names none; falls to Art. XVII, § 4 |

### The authority — the two that are clean

**Md. Const. Art. III, § 6** (both chambers, one sentence):

> A member of the General Assembly shall be elected by the registered voters of the legislative or
> delegate district from which he seeks election, **to serve for a term of four years beginning on
> the second Wednesday of January following his election**.

Second Wednesday of January 2027 = **2027-01-13**. ⚠ Art. III, § 14 puts the General Assembly's
own meeting on the same day — *"The General Assembly shall meet on the second Wednesday of
January, nineteen hundred and seventy-one, and on the same day in every year thereafter"* — so
Maryland is a **same-day** state like Wisconsin and Washington. 🔴 **Cite § 6, not § 14**: § 6 is
the term, § 14 is the meeting, and Maine is the proof they can diverge.

**Md. Const. Art. II, § 1** (Governor):

> The executive power of the State shall be vested in a Governor, **whose term of office shall
> commence on the third Wednesday of January next ensuing his election**, and continue for four
> years, and until his successor shall have qualified.

Third Wednesday of January 2027 = **2027-01-20**. Art. II, § 3 adds that the Governor and
Lieutenant Governor *"shall qualify … on the third Wednesday of January next ensuing his election,
**or as soon thereafter as may be practicable**"* — the term commences on the calendar date; the
qualification is allowed to lag it. **The date is a term start.**

🟢 **Control:** `essentials.office_terms` carries Wes Moore's term starting **2023-01-18**,
backfilled by migration 1459 from `msa.maryland.gov` and never derived from this clause. The third
Wednesday of January 2023 was the 18th.

### 🔴 The two that are refused, and why `estimated` is not an option

**Attorney General — Art. V, § 1:**

> … who shall hold his office **for four years from the time of his election and qualification**,
> and until his successor is elected and qualified …

**Comptroller — Art. VI, § 1:**

> The terms of office of the Comptroller and Treasurer shall be **for four years, and until their
> successors shall qualify** …

Neither names a day. So the residual rule applies — **Art. XVII, § 4**:

> The term of office of all Judges and other officers, for whose election provision is made by this
> Constitution, shall, except in cases otherwise expressly provided herein, **commence from the
> time of their Election**. All such officers shall qualify as soon after their election as
> practicable, and shall **enter upon the duties** of their respective offices immediately upon
> their qualification.

— and **Art. XVII, § 9** makes Article XVII prevail over any provision inconsistent with it.

⚠ **Read literally, both terms began on 2026-11-03 and are already running.** That is not
obviously wrong — Indiana's `CC_0464` was exactly that case. **But it cannot be written here, and
the reason is structural rather than interpretive:**

🔴 **THE LITERAL READING PUTS TWO PEOPLE IN ONE OFFICE AND `office_terms` WOULD REFUSE IT.** The
predecessor holds "until their successor shall qualify" (Art. VI, § 1) or "until his successor is
elected and qualified" (Art. V, § 1). The successor's term "commences from the time of their
Election". Those two spans **overlap** from election day until the oath — by design, so that the
office is never empty. Our model cannot express that: `office_terms` carries an exclusion
constraint that forbids two holders of one office over overlapping ranges, which is the whole
basis of `office_current_holder` being exactly one row per office. So the constitution's own
answer is a date we cannot write, and the date we *can* write — the qualification — is the one the
constitution declines to fix.

▶ **What these two need is a `published` date: the day each officer actually qualifies**, from the
officer's own or the Governor's announcement, recorded when it happens. 🔴 **Not `estimated` —
the register's step 3 says an `estimated` basis may not seat anybody, and the seating migration's
P4 refuses it.** Until then the AG and Comptroller stay out of Maryland's wave, named in its
header, exactly as the four staggered bodies are in Ruling A.

⚠ **Do not reach for "the third Wednesday, like the Governor".** The Maryland Manual's own list of
Attorneys General gives years and no days — *"2007-2015 Douglas F. Gansler · 2015-2023 Brian E.
Frosh · 2023- Anthony G. Brown"* — which is what a state publishes when there is no fixed day to
publish. A single calendar date borrowed from a different officer's article would be a fabrication
dressed as a citation.

### The source

`https://msa.maryland.gov/msa/mdmanual/43const/html/` — the **Maryland Manual On-Line**, the
Maryland State Archives' official publication of the Constitution of Maryland. Articles read in
full 2026-11-22: `02art2.html` (33,410 B), `03art3.html` (70,428 B), `05art5.html` (12,589 B),
`06art6.html` (11,309 B), `17art17.html` (9,931 B), all HTTP 200. Each clause above carries the
Manual's own amendment history, which is how the current text was distinguished from superseded
wording.

🔴🔴 **`mgaleg.maryland.gov` SERVES ITS "NotFound" PAGE WITH HTTP 200, AND THE BODY IS ALWAYS
57,164 BYTES.** `…/Laws/Constitution`, `…/Laws/Constitution?article=gml` and
`…/Session/Index/2026rs` all returned HTTP 200 at exactly that size; opened in a browser, the
first redirects to `/mgawebsite/Error/NotFound?error=404`. **A second official copy of the
Maryland constitution was sought and does not exist at that host.** ▶ Any probe of
mgaleg.maryland.gov must assert on content; `57164` is the tell. This is `CLAUDE.md`'s soft-404,
met in the wild.

### Basis

`statute` for the General Assembly and the Governor. The other two have no row yet.

### Term start or oath? — **term start for all three dated rows**

Art. III, § 6 says "beginning on"; Art. II, § 1 says "shall commence on". Both are calendar dates
and neither is conditioned on qualification — Art. II, § 3 explicitly lets the Governor's
qualification fall *after* the commencement date. For the AG and Comptroller the question is
inverted and is the whole problem: the constitution fixes **no** date and makes qualification the
operative event, which is why those two are refused above rather than guessed.

### Carried into the row

| field | Senate + House of Delegates | Governor |
|---|---|---|
| `election_date` | 2026-11-03 | 2026-11-03 |
| `swearing_in_date` | **2027-01-13** | **2027-01-20** |
| `window_end_date` | NULL | NULL |
| `basis` | `statute` | `statute` |
| `rule_id` | `md-const-art3-s6-second-wed-january` | `md-const-art2-s1-third-wed-january` |

### Four things the next step inherits

- 🔴 **Maryland is the Ruling A state.** 38 of the 67 pending House of Delegates offices carry more
  than one winner — 131 winners across 67 offices. The register's step 6 warning applies in full:
  `WAVE_SELECTION_SQL` keys winners on the **race-carrying** office, Ruling A writes the second and
  third winners to **different** offices, and post-verify 1 joins `office_terms` back on
  `office_id`. **Build Maryland's selection with the ASSIGNED office before copying `CC_0462`**, or
  the file aborts after writing.
- 🔴 **Ruling A's equality clause must be asserted per race, and Maryland is why.** Lettered
  subdistricts (19A, 19B) elect separately. If they arrive as distinct office rows, "fill a
  remaining eligible office" would claim a subdistrict nobody sourced.
- 🔴 **85 winners have no `politicians` row** — the second-largest seeding job after Maine's 77.
- ⚠ **All 117 pending rows carry `certainty = 'called'`, none certified.** Ruling B applies
  unchanged: record the split in the pin block and the header, and carry the slot in every term's
  `source`.
- ⚠ **The Lieutenant Governor and the State Treasurer are correctly NOT pending.** The Lieutenant
  Governor runs on the Governor's ticket, and the Treasurer is chosen "on joint ballot by the two
  Houses of the Legislature" (Art. VI, § 1) rather than by voters. Neither is a gap.

---

## CA — California · 99 offices · ✅ sourced 2026-11-22

🔴🔴 **THE SECOND DECEMBER DEADLINE. CALIFORNIA'S LEGISLATURE STARTS 2026-12-07 — FIFTEEN DAYS
OUT, 92 OFFICES.** With Maine's 2026-12-01 that is **275 of the pass's 1,162 offices due before
2027**, and the by-size queue had both of them in the top five by accident rather than by deadline.

| body | offices | start date | authority |
|---|---|---|---|
| State Assembly | 75 | **2026-12-07** (Mon) | Art. IV, § 2(a)(3) |
| State Senate | 17 | **2026-12-07** (Mon) | Art. IV, § 2(a)(3) |
| Governor · Lt. Governor · Attorney General · Controller · Secretary of State · Treasurer | 6 | **2027-01-04** (Mon) | Art. II, § 20 |
| Board of Equalization, District 3 | 1 | **2027-01-04** (Mon) | Art. II, § 20 |

### The authority — two clauses, and the second one names the first as its exception

**Cal. Const. Art. IV, § 2(a)(3)** — the legislature:

> The terms of a Senator or a Member of the Assembly **shall commence on the first Monday in
> December next following her or his election**.

First Monday in December 2026 = **2026-12-07**. ⚠ Art. IV, § 3(a) puts the organising session on
the same day — *"The Legislature shall convene in regular session at noon on the first Monday in
December of each even-numbered year and each house shall immediately organize"* — so California is
a **same-day** state. 🔴 **Cite § 2(a)(3), not § 3(a).**

**Cal. Const. Art. II, § 20** — everything else the constitution makes elective:

> **Terms of elective offices provided for by this Constitution, other than Members of the
> Legislature, commence on the Monday after January 1 following election.** The election shall be
> held in the last even-numbered year before the term expires.

Monday after January 1, 2027 = **2027-01-04**.

🟢 **This single clause dates all seven non-legislative offices, and it is the one a per-office
search does not find.** Art. V, § 2 gives the Governor office "from the Monday after January 1
following the election"; Art. V, § 11 puts the Lieutenant Governor, Attorney General, Controller,
Secretary of State and Treasurer on "the same term as the Governor"; and Art. XIII, § 17 gives
Board of Equalization members "4-year terms at gubernatorial elections" and **names no
commencement at all**. Without Art. II, § 20 the Board of Equalization would have had to be
refused the way Maryland's Comptroller was. With it, the Board is covered by the same words as
everything else.

▶ **Look for a constitution's GENERAL term-commencement clause before concluding an office has
none.** Art. II, § 20 lives in the *voting* article, not in the executive one, which is why
reading Articles IV, V and XIII in order never reaches it. It was found by a full-text search of
the California codes, and then opened and read on its own page.

### The source

`https://leginfo.legislature.ca.gov/faces/codes_displayText.xhtml?lawCode=CONS&article=IV`
(184,845 B) and `…&article=V` (148,650 B), fetched and read 2026-11-22; Art. II, § 20 and
Art. XIII, § 17 read at
`…/codes_displaySection.xhtml?lawCode=CONS&sectionNum=SEC.%2020.&article=II` and
`…&sectionNum=SEC.%2017.&article=XIII`. All are the Legislative Counsel's own publication of
California law.

⚠ **`leginfo` 403s a third `codes_displayText` fetch from `curl` in quick succession** — the first
two succeeded and Article XIII returned HTTP 403 at 5,643 bytes. A browser session got it
immediately. Not a WAF block on the host; it is rate limiting, and the fix is to slow down or
switch transport rather than to conclude the page is gone.

### Basis

`statute` for both rows — constitutional provisions.

### Term start or oath? — **term start, both rows**

Art. IV, § 2(a)(3) says "shall commence on"; Art. II, § 20 says "commence on". Both name calendar
dates and neither conditions the start on qualification. ⚠ Art. V, § 2 adds that the Governor
holds office "from the Monday after January 1 following the election **until a successor
qualifies**" — that is the *end* of the predecessor's tenure, the same holdover shape as
Massachusetts, and it does not move this term's start.

### Controls — two clusters in our own data, six biennia and two cycles, computed independently

🟢 **The legislature, six for six.** `essentials.office_terms` groups CA legislative term starts
exactly on first Mondays in December:

| cycle | first Monday in December | rows in our data |
|---|---|---|
| 2014 | 2014-12-01 | 2 |
| 2016 | 2016-12-05 | 5 |
| 2018 | 2018-12-03 | 3 |
| 2020 | 2020-12-07 | 4 |
| 2022 | 2022-12-05 | **59** |
| 2024 | 2024-12-02 | **37** |

No biennial cluster sits anywhere else. The remaining rows are `start_precision = 'year'`
placeholders and mid-term appointments.

🟢 **The executives, two for two.** Five `STATE_EXEC` rows start **2019-01-07** and one starts
**2023-01-02** — the Monday after January 1 in each of those years.

⚠ **The Board of Equalization control is PARTLY CIRCULAR and is recorded as such.** Its four rows
(`2019-01-07` ×3, `2023-01-02` ×1) were written by `CA_0205`, whose own `source` says the day came
"from the Wikipedia BOE membership table, the first Monday after January 1" — the Board's own
`Board-Members-Listing.pdf` gives **years only**. So those rows do not independently confirm
Art. II, § 20; what has changed is the direction of support. **`CA_0205` guessed a day from an
aggregator and the guess is now backed by a clause.** The clause is the authority; the rows are
corroboration that the state behaves as it reads.

### ⚠ The `chambers.inauguration_rules` lead was wrong in general and right this cycle

`SOURCING.md` flagged that three California executive rules say *"1st Monday in the new year
following election"* and cite nothing. The constitution says **"the Monday after January 1"**.
🔴 **Those are different rules, and they diverge whenever January 1 is itself a Monday** — in 2024
the first Monday of January was the 1st and the Monday after January 1 was the **8th**, a week
apart. For 2027 January 1 is a Friday and both give 2027-01-04. ▶ **A rule row that happens to
agree this cycle is still not a citation**, which is exactly why the register says a rule row
earns its way in by its own citation or not at all.

### Carried into the row

| field | Assembly + Senate | the 6 executives + BOE D3 |
|---|---|---|
| `election_date` | 2026-11-03 | 2026-11-03 |
| `swearing_in_date` | **2026-12-07** | **2027-01-04** |
| `window_end_date` | NULL | NULL |
| `basis` | `statute` | `statute` |
| `rule_id` | `ca-const-art4-s2a3-first-monday-december` | `ca-const-art2-s20-monday-after-january-1` |

### Five things the next step inherits

- 🔴 **15 days.** 92 California legislative seats and 183 Maine ones both start before this pass's
  next January date. Nothing else in the queue is close.
- ⚠ **The Board of Equalization office is `STATE_BOARD` and has `chamber_id = NULL`.** 🔴 **An
  INNER JOIN to `essentials.chambers` silently drops it** — that happened while measuring this
  state and made California read as 98 offices instead of 99. The register's own
  `WAVE_SELECTION_SQL` does not join chambers, which is why it had the right number.
  ▶ **Join chambers LEFT, or not at all, when counting offices.**
- ⚠ **Only District 3 of the four Board of Equalization seats is up** (Mike Gipson). Districts 1, 2
  and 4 are mid-term. All four carry proper `06-sboe-dN` geo_ids.
- ⚠ **Two statewide executives on the 2026 ballot are NOT in the pending set** — Superintendent of
  Public Instruction and Insurance Commissioner. Result gaps, the same class as Massachusetts'
  Secretary of the Commonwealth. 🔴 **Their dates would not be identical if they were added**: the
  Superintendent is constitutional (Art. IX, § 2, *"first Monday after the first day of January"*)
  and the **Insurance Commissioner is statutory**, so Art. II, § 20 — "provided for by this
  Constitution" — does not reach it and it would need its own citation.
- ⚠ **California's `STATE_EXEC` tier holds 18 office rows, most of them appointed** — Auditor,
  Director of Industrial Relations, five Public Utilities Commissioners, Secretary for Natural
  Resources, Secretary of Agriculture. None is elective and none is pending. **Do not date them**;
  Art. II, § 20 reaches elective offices only.

---

## OR — Oregon · 76 offices · ⚠️ 75 sourced, **1 REFUSED**, 2026-11-22

🔴 **THE PATTERN FROM MARYLAND REPEATS: THE LEGISLATURE IS DATED BY A CALENDAR RULE AND THE
EXECUTIVE IS NOT.** Oregon's constitution hands the Governor's commencement to the Legislature
("at such times as may be prescribed by … law"), and the statute that answers names an **event**,
not a day.

| body | offices | start date | authority |
|---|---|---|---|
| House of Representatives | 60 | **2027-01-11** (Mon) | Or. Const. Art. IV, § 4(1) |
| Senate | 15 | **2027-01-11** (Mon) | Or. Const. Art. IV, § 4(1) |
| Governor | 1 | 🔴 **REFUSED** | ORS 176.010 names an event |

### The authority — the legislature

**Or. Const. Art. IV, § 4(1)** — *Term of office of legislators; classification of Senators*:

> The Senators shall be elected for the term of four years, and Representatives for the term of two
> years. **The term of each Senator and Representative shall commence on the second Monday in
> January following his election**, and shall continue for the full period of four years or two
> years, as the case may be …

Second Monday in January 2027 = **2027-01-11**.

🟢 **Control — a statute written for a different purpose repeats the same day.** **ORS 171.051(6)**,
on filling the back half of a Senate term: *"The remaining two years of the term of office of a
state Senator under subsection (4) of this section will commence on **the second Monday in January
following the general election**."* That is an independent draftsman, in a different code, reaching
for the same boundary. ⚠ Our own `office_terms` offers **no** control here — all 90 Oregon
legislative rows are `term_start NULL`.

⚠ **Oregon's session does NOT convene on that day**, unlike Washington, Wisconsin, Maryland and
California. **ORS 171.010(1)**: the odd-year regular session commences *"on the Tuesday after the
holiday for Martin Luther King, Jr.'s Birthday"* — **2027-01-19**, eight days after the terms
begin. 🔴 **So Oregon is a state where term start and convening genuinely differ**, and reaching
for the session date would be wrong by more than a week.

### 🔴 The Governor is refused, and the reason is an event rather than a silence

**Or. Const. Art. V, § 7** — *Term of office*:

> The official term of the Governor shall be four years; and shall **commence at such times as may
> be prescribed by this constitution, or prescribed by law**.

The law it defers to is **ORS 176.010 — Commencement of term; inauguration**:

> The official term of the Governor shall **commence upon the publication of the returns by the
> Speaker of the House of Representatives**, as provided in section 4, Article V, Oregon
> Constitution; or in case of an election of the Governor by the Legislative Assembly … the
> official term of the Governor shall commence immediately upon such election; and the Governor
> shall be inaugurated by taking the oath of office.

⚠ **This is a different refusal from Maryland's.** Maryland's Comptroller has *no rule*; Oregon's
Governor has a **precise rule about an event that has not happened yet**. The returns are published
by the Speaker, in the presence of both houses (Art. V, § 4) — and there is no Speaker until the
new House has organised, which cannot precede its own members' terms. **ORS 176.110(1)** confirms
the drafters thought of it as a date-bearing event: it lets a Governor-elect act "prior to **the
date the official term of office commences**".

▶ **The prediction, written down so the next pass can confirm it in one read rather than re-derive
it:** the publication has fallen on **the second Monday in January** — the day the legislators'
terms begin — in every recent cycle. `essentials.office_terms` carries Tina Kotek's term starting
**2023-01-09**, which was the second Monday of January 2023. So 2027-01-11 is the expected day.
🔴 **It is expected, not sourced, and it is not written.** The confirming document is the Oregon
House Journal for the organisational day of the 2027 session, which records the Speaker publishing
the returns. Record it then with `basis = 'published'`.

### The source

`https://www.oregonlegislature.gov/bills_laws/Pages/OrConst.aspx` (HTTP 200, 648,772 bytes) for the
constitution, and `https://www.oregonlegislature.gov/bills_laws/ors/ors176.html` (113,138 B),
`…/ors171.html` (487,315 B) for the statutes — the Legislative Assembly's own publications, all
fetched and read 2026-11-22. ⚠ `…/bills_laws/Documents/OrConst.pdf` is a 404; the `.aspx` page
carries the full text.

### Basis

`statute` for the two legislative rows. The Governor has no row.

### Term start or oath? — **term start for the legislature; for the Governor the two are fused**

Art. IV, § 4(1) says "shall commence on" a calendar day, with no mention of an oath, and Oregon's
session convenes eight days later — so for legislators the term start is plainly not a swearing-in.

🔴 **For the Governor the question has no clean answer, which is part of why the office is
refused.** ORS 176.010 commences the term at the publication of the returns and then says the
Governor "shall be inaugurated by taking the oath" — two events on one day, with the term attached
to the first. ⚠ **ORS 176.020 attaches the predecessor's exit to the SECOND**: *"The term of office
of the Governor ceases when the successor … is inaugurated by taking the oath of office."* Read
together they are consistent only because both happen the same morning. **Whoever records this
date must record which of the two events it is**, or the next pass cannot tell.

### Carried into the row

| field | House + Senate |
|---|---|
| `election_date` | 2026-11-03 |
| `swearing_in_date` | **2027-01-11** |
| `window_end_date` | NULL |
| `basis` | `statute` |
| `rule_id` | `or-const-art4-s4-second-monday-january` |

### Three things the next step inherits

- ⚠ **15 of Oregon's 30 Senate seats are pending**, the chamber being staggered (Art. IV, § 4(2),
  "Senators shall be elected biennially"). As in Washington, this is **not** a Ruling A case —
  every pending office carries exactly one winner.
- ⚠ **15 winners have no `politicians` row** — 9 House, 6 Senate.
- ⚠ **Oregon also has non-state-tier pending seats this cycle** — 2 county offices, 7 local council
  offices (two of them multi-winner), 3 mayors and a city auditor. **They are not part of this
  pass** and are dated by their own rules; the `state:or` claim covers them, so do not let a
  state-tier wave select on state alone.

---

## AZ — Arizona · 66 offices · ⚠️ 65 dated, **1 REFUSED**, 2026-11-22 — and 1 of the 65 is not seatable

**One day, 2027-01-04, reached by three separate provisions that each anchor on a past cycle.**

| body | offices | winners | start date | authority |
|---|---|---|---|---|
| Senate | 30 | 30 | **2027-01-04** | Art. IV, Pt. 2, § 21 |
| House of Representatives | 29 | **58** | **2027-01-04** | Art. IV, Pt. 2, § 21 |
| Governor · Secretary of State · Attorney General · Treasurer · Superintendent of Public Instruction | 5 | 5 | **2027-01-04** | Art. V, § 1(A) |
| Corporation Commission | 1 | 2 | **2027-01-04** — ⚠️ **dated but NOT seatable** | Art. XV, § 1(B) |
| State Mine Inspector | 1 | 1 | 🔴 **REFUSED** | Art. XIX names no day |

### 🔴 Arizona states its rule as an ANCHOR YEAR, not as a recurring formula

None of the three provisions says "the first Monday in January following the election". Each names
a **specific past date** and a term length, and the recurrence is implied:

**Art. IV, Pt. 2, § 21** (legislature) — the section is titled *Term limits*, which is why a search
for a term-start clause does not find it:

> The members of the first legislature shall hold office **until the first Monday in January,
> 1913**. The terms of office of the members of succeeding legislatures shall be two years.

**Art. V, § 1(A)** (the executive department):

> The executive department shall consist of the governor, **lieutenant governor**, secretary of
> state, attorney general, state treasurer and superintendent of public instruction, each of whom
> shall hold office for four years **beginning on the first Monday of January, 1971 next after the
> regular general election in 1970**.

**Art. XV, § 1(B)** (Corporation Commission):

> A corporation commission is hereby created to be composed of five persons who shall be elected at
> the general election, and whose term of office shall be four years … The two additional
> commission members shall be elected at the 2002 general election for initial two-year terms
> **beginning on the first Monday in January, 2003**. Thereafter, all terms shall be four-year
> terms.

▶ **An anchor-plus-length rule is still a citation, but it is the shape most likely to be misread
as "no rule".** All three anchors are a first Monday in January, all three lengths are whole
numbers of years, and the cycle lands on 2027. First Monday of January 2027 = **2027-01-04**.

### The source

`https://www.azleg.gov/constitution?article=4`, `…?article=19`, `…?article=22` for the section
indexes, and the section texts at `https://www.azleg.gov/const/4/21.p2.htm`,
`…/const/5/1.htm`, `…/const/15/1.htm`, `…/const/19/0.htm` and `…/const/19/0.1.htm` — the
Legislature's own publication, all fetched and read 2026-11-22. Statutes checked at
`https://www.azleg.gov/ars/…`: `38-295`, `38-291`, `38-321`, `27-101`, `27-121`, `27-122`,
`27-123`.

⚠ **The section URL is `/const/<article>/<section>.htm`, except in Article 4, where Part 2 is
`/const/4/<section>.p2.htm`.** Five plausible spellings of "Article 4, Part 2, Section 21" return
HTTP 404 (correctly, at 79,330 bytes — azleg does **not** soft-404). The working form was taken
from the article index's own links rather than guessed.

### Basis

`statute` for all five rows.

### Term start or oath? — **term start, and Arizona convenes a WEEK LATER**

All three provisions attach the term to a calendar day. ⚠ **Art. IV, Pt. 2, § 3 puts the session
on a different day**: *"The sessions of the legislature shall be held annually at the capitol of
the state, and shall commence on the **second** Monday of January of each year"* — **2027-01-11**.
🔴 **Arizona is the second state in this pass where term start and convening differ** (Oregon is
the other, by eight days). Reaching for the session date would be a week wrong on 59 seats.

### Control — three cycles in our own data, all on first Mondays

`essentials.office_terms`, from the ADR 0002 phase-2 backfill:

| cycle | first Monday in January | rows on that date |
|---|---|---|
| 2021 | 2021-01-04 | 1 |
| 2023 | 2023-01-02 | **52** (33 House + 19 Senate) |
| 2025 | 2025-01-06 | **26** (18 House + 8 Senate) |

🟢 **Three for three, 79 rows, computed independently of the clause.** The one dated `STATE_EXEC`
row is also **2023-01-02**. The remaining rows are `start_precision = 'year'` placeholders.

### 🔴 The State Mine Inspector is refused, and its article is published TWICE

**Art. XIX** establishes the office and gives a term length with **no commencement at all**. Worse,
the constitution carries **two competing versions of the same article**, both from 1992:

- `const/19/0.htm`, *"Version amended by 1992 Proposition 101"*: incumbents *"shall be elected at
  general elections, and shall serve for **four years**. The initial four year term shall be served
  by the mine inspector elected in the general election held in November, 1994."*
- `const/19/0.1.htm`, *"Version amended by 1992 Proposition 107"*: *"shall serve for a term of
  **two years**"*, plus a four-consecutive-term limit.

Neither names a day. ⚠ **They also disagree on the term length**, which means the office's cycle
is not settled by this text either — and the office is on the 2026 ballot, which only the
four-year version explains. `A.R.S.` was searched for a commencement rule and none was found
(`38-295` is the holdover provision: *"Every officer shall continue to discharge the duties of the
office, although the term has expired, until a successor has qualified"*).

▶ **The inference, written down and not written in:** every other Arizona state office starts on
the first Monday in January, so 2027-01-04 is the expected day. **It is not cited and is not
written.** The confirming document is the Secretary of State's canvass or the inspector's own
oath record.

### ⚠ The Corporation Commission is dated here and still cannot be seated

Art. XV, § 1(B) gives it a day, so **it gets an `office_swearing_in` row**. Ruling A refuses the
*seating* for a different reason entirely: the race attaches **2 winners** to one office row while
**5 eligible offices** exist, the body is staggered, and which two seats are up is not in our data.
🔴 **A date and a seat are separate questions, and this office answers one and not the other.**
Measured here: all five `Commissioner` rows exist, all five are `Arizona Corporation Commission`,
and exactly one of them carries the pending winners.

### Carried into the row

| field | all five dated groups |
|---|---|
| `election_date` | 2026-11-03 |
| `swearing_in_date` | **2027-01-04** |
| `window_end_date` | NULL |
| `basis` | `statute` |
| `rule_id` | `az-const-first-monday-january` (cite the per-body article in `authority`) |

### 🔴🔴 Arizona elected a Lieutenant Governor and we hold no office for it

Art. V, § 1(A) names the **lieutenant governor** as part of the executive department, and
§ 1(C) makes it a joint-ticket office: *"each nominee for the office of governor shall name a
lieutenant governor nominee and shall run on a ticket as a joint candidate … a single vote for a
nominee for governor shall constitute a vote for that nominee's ticket, including the nominee for
lieutenant governor."*

**Measured 2026-11-22: Arizona's eleven `STATE_EXEC` office rows are Attorney General, five
Corporation Commissioners, Governor, Secretary of State, State Mine Inspector, Superintendent of
Public Instruction and Treasurer. There is no Lieutenant Governor.**

▶ This is `CLAUDE.md`'s *an office with no term is invisible and nothing errors*, reached from the
seeding side: Arizona's first Lieutenant Governor takes office on **2027-01-04** and no Arizona
address will return them. **Creating that office is an occupancy act** — it must be created and
seated together, or the drift baseline rises. ⚠ **The winner's name is on the Governor's ticket**,
which is the trap the transition tracker already records: *a ticket LG row names the governor*.

### Three things the next step inherits

- 🔴 **Arizona is a Ruling A state alongside Maryland.** All 29 pending House offices carry two
  winners — 58 winners across 29 offices, every pending office multi-winner. The register's step 6
  correction applies: build the selection with the **assigned** office, not the race-carrying one.
- ⚠ **30 of 30 Senate seats are pending** — Arizona's Senate is not staggered, unlike Washington's
  and Oregon's.
- ⚠ **No Arizona chamber carries an `inauguration_rules` row**, so there was no lead to check and
  nothing to re-source.

---

## NV — Nevada · 58 offices · ⚠️ 52 dated, **6 REFUSED**, 2026-11-22 — ✅✅ **ALL 52 SEATED 2026-11-23**

✅✅ **SEATED 2026-11-23 BY `CC_0465` → `CC_0466` → `CC_0467`** — 52 terms from 2026-11-04, 39
re-elections and 13 handovers, 52 predecessors closed at 2026-11-03, 12 politicians created and
Danielle Gallant linked. Verified through the deployed API. The six executives remain refused.

🔴🔴 **NEVADA'S 52 LEGISLATORS HAVE HELD THEIR SEATS SINCE 2026-11-04. THE DATE WAS NOT IN THE
FUTURE — IT WAS NINETEEN DAYS PAST WHEN THIS WAS WRITTEN.** Every other state sourced so far starts in December 2026 or
January 2027. Nevada's legislature started the day after the election, which means our pages have
been naming the *predecessors* as current for eighteen days and nothing has said so.

| body | offices | start date | authority |
|---|---|---|---|
| Assembly | 41 | 🔴 **2026-11-04** (past) | Nev. Const. Art. 4, Sec. 3(1) |
| Senate | 11 | 🔴 **2026-11-04** (past) | Nev. Const. Art. 4, Sec. 4(1) |
| Governor · Lt. Governor · Secretary of State · Attorney General · Treasurer · Controller | 6 | 🔴 **REFUSED** | term begins at **qualification** |

### The authority — the legislature

**Nev. Const. Art. 4, Sec. 3(1)** (Assembly):

> The members of the Assembly shall be chosen biennially by the qualified electors of their
> respective districts, on the Tuesday next after the first Monday in November and **their term of
> Office shall be two years from the day next after their election**.

**Nev. Const. Art. 4, Sec. 4(1)** (Senate):

> Senators shall be chosen at the same time and places as members of the Assembly by the qualified
> electors of their respective districts, and **their term of Office shall be four years from the
> day next after their election**.

Election 2026-11-03 → the day next after = **2026-11-04**.

🟢 **This is Indiana's clause in different words, and this repo has already ruled on it.**
`CC_0463` read `Ind. Const. art. 4 § 3` — *"elected for a term of … two years respectively, from
the day next after their general election"* — as 2026-11-04 and `CC_0464` seated three members on
it. **Same construction, same reading, and the two states now agree.**

⚠ **Contrast Maine, which uses the opposite preposition for the opposite effect**: *"two years
from the day next **preceding** the first Wednesday in December"*. Nevada and Indiana count
forward from the election; Maine counts back from the meeting. 🔴 **Three states in this pass
hinge on "the day next X" and X is not the same word. Read it.**

### 🔴 The six executives are refused: Nevada starts their terms at QUALIFICATION

**Nev. Const. Art. 5, Sec. 2** (Governor):

> The Governor shall be elected by the qualified electors at the time and places of voting for
> members of the Legislature, and shall hold his office for Four Years **from the time of his
> installation**, and until his successor shall be qualified.

**Nev. Const. Art. 5, Sec. 19(1)**: *"A Secretary of State, a Treasurer, a Controller, and an
Attorney General, shall be elected at the same time and places, and in the same manner as the
Governor. **The term of office of each shall be the same as is prescribed for the Governor**."*
Art. 5, Sec. 17 does the same for the Lieutenant Governor.

**NRS 223.020(2)** repeats it — the Governor "shall hold office for the term of 4 years **from the
time of his or her installment**" — and **NRS 282.010** says what that means:

> **4.** The term of office of all officers, elected or appointed, shall **begin from the time of
> their qualification**, unless some other express provision is made by law.
>
> **2.** All officers elected, **except Senators and members of the Assembly**, shall qualify, and
> execute and deliver their official bonds when required, as provided in this section, **prior to
> the Tuesday after the first Monday in January ensuing their election**.

So the six executives' terms begin on the day each one qualifies — an event, like Oregon's
Governor — and that day is **not yet knowable**.

🟢 **But Nevada bounds it, and `office_swearing_in` has the column for that.** Subsection 2 makes
qualification a deadline: **prior to the Tuesday after the first Monday in January 2027**, which is
**prior to 2027-01-05**. ▶ **When these six are dated, `window_end_date = 2027-01-04` is a sourced
value even though `swearing_in_date` is not.** That is the first use this pass has found for the
column.

⚠ **Subsection 2's carve-out is itself the control on the legislative reading.** It excludes
"Senators and members of the Assembly" from the January qualification deadline — which only makes
sense because their terms already began in November under Art. 4. **The statute and the
constitution agree, from opposite directions.**

🟢 **Practice control:** `essentials.office_terms` holds one dated Nevada executive at
**2023-01-02** — the first Monday of January 2023, comfortably prior to that cycle's Tuesday
deadline of 2023-01-03. It is a qualification date, not a rule, and is recorded as such.

### The source

`https://www.leg.state.nv.us/Const/NvConst.html` (HTTP 200, 431,607 bytes) and
`https://www.leg.state.nv.us/NRS/NRS-223.html`, `…/NRS-282.html`, `…/NRS-281.html` — the
Legislative Counsel Bureau's own publications, fetched and read 2026-11-22.

### Basis

`statute` for the 52 legislative rows. The six executives have no row.

### Term start or oath? — **term start for the legislature; for the executives they are the SAME EVENT**

The legislative clause names a calendar day computed from the election and says nothing about an
oath. ⚠ NRS 282.010(1) still requires members to take the oath "before entering upon the duties"
— the familiar split, and it does not move the term start.

🔴 **For the six executives the term start IS the oath**, which is why they are refused rather than
estimated: NRS 282.010(4) attaches the term to qualification and NRS 282.020 makes the oath part of
qualifying. **Whoever records those six must record a qualification date and say so.** This is the
case the register's step 2 warns about — *"others begin the term on qualification, which IS the
oath"* — and Nevada is the first state in the pass to be on that side of the line.

### Carried into the row

| field | Assembly + Senate | the six executives |
|---|---|---|
| `election_date` | 2026-11-03 | 2026-11-03 |
| `swearing_in_date` | 🔴 **2026-11-04** | *unknown — qualification* |
| `window_end_date` | NULL | **2027-01-04** (sourced: NRS 282.010(2)) |
| `basis` | `statute` | `published`, when it happens |
| `rule_id` | `nv-const-art4-day-next-after-election` | `nv-nrs-282-010-on-qualification` |

### Four things the next step inherits

- 🔴🔴 **Nevada's wave is the `CC_0464` shape, not the `CC_0462` shape** — a term that has already
  started. That is the one worked example in the register for this case, and it exists because of
  Indiana. **Use it.**
- 🔴 **The predecessors' terms must close on 2026-11-03**, the day before. `seat_officeholder`
  does that automatically at `term_start - 1`, and the register's step 6 correction applies: the
  closures are **not** recoverable from any file, so capture `(office_id, term_id, term_end,
  how_ended)` for all 52 predecessors in the pre-image and assert `term_end IS NULL` across them.
- 🔴🔴 **12 WINNERS NEED A `politicians` ROW, NOT 13 — ONE OF THEM IS A SITTING MEMBER.**
  `derive-seating-wave.mjs` reports 13 `winner_no_record` blockers, and **Danielle Gallant,
  State Senate District 20, already exists** as `6cffc86c-7d40-4fd9-8690-51d6d33ff1e4`: she is the
  sitting **Assembly District 23** member moving up to the Senate, and her `race_candidates` row
  simply has a NULL `politician_id`. Seeding her would have put a second row on the board for a
  serving official. ▶ **The blocker says "no record in this race", never "no record anywhere"**
  — sweep the whole `politicians` table before creating anybody. Her row needs LINKING; the other
  twelve need creating.
  - ⚠ Her Assembly seat is in the same wave: AD23's winner is **Denise Daniels Fanning**, so the
    one file both closes Gallant's Assembly term and opens her Senate one. The two writes touch
    different offices, so the `office_terms` exclusion constraint is not engaged either way round.
- 🟢🟢 **THE LEGISLATURE'S OWN ROSTER CONFIRMS ALL 52, AND IT HAS ALREADY ROLLED TO THE 84th
  SESSION.** `leg.state.nv.us/App/Legislator/A/{Assembly,Senate}/Current/` serves
  `Session/84th2027` and names the 2026 winners as the CURRENT membership with "Term Ends: 2028",
  read 2026-11-22. All 42 Assembly and all 21 Senate districts are published; **every one of the
  52 seats in this wave names the same person our winner rows do.** The body itself treating these
  seats as already changed hands is the strongest control the 2026-11-04 date has.
  - ⚠ **Two of the 52 differ from the roster in the GIVEN NAME ONLY, and both are benign**: AD26
    "Richard DeLong" is the roster's "DeLong, Rich", SD13 "Richard Daly" is "Daly, Skip". Both
    already hold `politicians` rows, so neither spelling is written by this pass.
  - 🔴 **AD15 IS SPELLED `Dávila` BY THE LEGISLATURE AND `Davila` BY AP.** The chamber's own
    publication outranks the aggregator on how a member's name is spelled, so the new row should
    carry **Miguel Dávila** with AP's spelling noted in its `source`. ⚠ The page writes accents as
    numeric entities (`D&#225;vila`), so a reader that does not decode them manufactures a
    disagreement — and so does writing the decoded name out in the wrong encoding, which is how
    this cross-check first reported 5 mismatches instead of 2.
- 🔴🔴 **TWO NEVADA SEATS ARE WRONG ON OUR PAGES AND NO 2026 WAVE CAN REACH EITHER.** Both were
  found by the roster read, both sit outside `office_pending_winner`, and each needs its own file:
  - **ASSEMBLY DISTRICT 22** — we show **Melissa R. Hardy**; the Legislature shows **Shenea
    Booth**. The 2026 race EXISTS in our data with both candidates present and `result` NULL on
    both, so no winner was ever recorded. ▶ **An office with a race but no RESULT is exactly as
    invisible as an office with no race** — the pending-winner view cannot tell the two apart, and
    the seat count looks complete either way. This is the only one of Nevada's 42 Assembly seats
    missing from the wave, which is why it reads as "41 of 42 were up" rather than as a defect.
  - **STATE SENATE DISTRICT 6** — we show **Nicole J. Cannizzaro**; the Legislature shows the seat
    **VACANT**. SD6 carried no 2026 race at all, so it is correctly outside the wave and
    separately wrong.
- ⚠ **11 of Nevada's 21 Senate seats are pending**, the chamber being staggered on four-year
  terms. One winner per office, so **not** a Ruling A case.

---

## UT — Utah · 56 offices · ⚠️ 50 sourced, **6 REFUSED**, 2026-11-22

**Utah is the first state in this pass whose date is the first day of January itself** — not a
Monday, not a Wednesday, not counted from the election.

| body | offices | start date | authority |
|---|---|---|---|
| House of Representatives | 42 | **2027-01-01** (Fri) | Utah Const. Art. VI, Sec. 3(2) |
| Senate | 8 | **2027-01-01** (Fri) | Utah Const. Art. VI, Sec. 4(2) |
| State Board of Education | 6 | 🔴 **REFUSED** | `20A-14-103` names no commencement |

### The authority — the legislature

**Utah Const. Art. VI, Sec. 3** — *Election of House members – Terms*:

> (1) The members of the House of Representatives shall be chosen biennially on even-numbered
> years by the qualified voters of the respective representative districts, on the first Tuesday
> after the first Monday in November. (2) **Their term of office shall be two years from the first
> day of January next after their election.**

**Utah Const. Art. VI, Sec. 4** — *Election of Senators – Terms*:

> (2) **Their term of office shall be four years from the first day of January next after their
> election.** (3) As nearly one-half as may be practicable shall be elected in each biennium …

The first day of January next after the 2026-11-03 election = **2027-01-01**.

⚠ **2027-01-01 is a Friday and a public holiday, and the clause does not care.** It names a day of
the calendar, not a sitting day. 🔴 **Do not "round" it to the following Monday** — that would be
the same class of error as reaching for a convening date, and Utah's general session does not
begin until the third Tuesday in January in any case.

⚠ **No control is available.** All 119 Utah legislative rows in `essentials.office_terms` carry
`term_start NULL`, so nothing in our data corroborates or contradicts this. The clause is
unusually plain — *"from the first day of January next after their election"* has no inclusive /
exclusive ambiguity of the kind Maine's "from the day next preceding" had — but the reading rests
on the text alone and that is recorded here rather than implied.

### 🔴 The six State Board of Education seats are refused

**Utah Code § 20A-14-103** — *State Board of Education members – Term – Requirements* — fixes the
length and the cycle and **names no start**:

> (1)(a) … voters in the following districts … shall elect a State Board of Education member for a
> term of four years: (i) at the **2022 General Election**, State Board of Education Districts 1,
> 2, 4, 5, 8, 11, and 14; and (ii) at the 2024 General Election, Districts 3, 6, 7, 9, 10, 12, 13,
> and 15 …

🟢 **That subsection does confirm which seats are up.** Our six pending Board offices are Districts
**1, 2, 4, 5, 11 and 14** — six of the seven the statute places on the 2022 cycle, which is the
cycle that renews in 2026. ⚠ **District 8 is the seventh and is NOT in our pending set.** That is
a result gap, not a dating one.

🔴 **The only dates in the section are transitional and they point at a DIFFERENT boundary from
the legislature's.** Subsection (1)(b) gives a realigned member "a term of office that **ends
January 6, 2025**", and (2)(b)(i) lets an incumbent "serve until **January 2, 2023**". Both are
**first Mondays in January** — 2025-01-06 and 2023-01-02 — where the legislature's boundary is the
**first day** of January. ▶ **So the two bodies in this state do not share a boundary, and the
Board's cannot be borrowed from the House's.** If the Board's rule is the first Monday, its 2027
date is **2027-01-04**, three days later than the legislature's.

⚠ **Those two dates sit inside transitional provisions about a 2021 redistricting, not in a general
rule**, so neither can be cited as the Board's recurring commencement. `53E-3-201` sends the
question back to Title 20A, Chapter 14, and Chapter 14 does not answer it. **No control is
available either** — all 15 Utah Board rows in `office_terms` are undated.

▶ **What would settle it:** the Board's own published member roster with term dates, or the
lieutenant governor's certification. Record with `basis = 'published'`. 🔴 **Do not write
2027-01-01 for these six on the strength of the legislature's clause** — the section's own
transitional dates are evidence against it.

### The source

`https://le.utah.gov/xcode/ArticleVI/Article_VI,_Section_3.html` and `…,_Section_4.html` for the
constitution; `https://le.utah.gov/xcode/Title20A/Chapter14/20A-14-S103.html`,
`…/20A-14-S102.html` and `https://le.utah.gov/xcode/Title53E/Chapter3/53E-3-S201.html` for the
statutes — the Legislature's own publication, read 2026-11-22.

⚠ **`le.utah.gov` serves every section as a JavaScript shell.** `curl` returns ~26.6 KB of
navigation and **no section text at all**, and the byte counts are nearly identical across
different sections (26,677 / 26,654 / 26,682), which is the tell. All of the above were read in a
browser. ⚠ **A rendered page can also come back as the shell if it is read too early** —
`20A-14-S104` did exactly that and looked like an empty section rather than a slow one. **Assert
the section number is present in the text before concluding a section is empty or missing.**

### Basis

`statute` for the 50 legislative rows. The six Board seats have no row.

### Term start or oath? — **term start**

Both clauses say "term of office shall be … from the first day of January next after their
election", with no mention of an oath and no condition of qualification. Utah's general session
convenes on the third Tuesday in January, well after, so the two events are plainly distinct here.

### Carried into the row

| field | House + Senate |
|---|---|
| `election_date` | 2026-11-03 |
| `swearing_in_date` | **2027-01-01** |
| `window_end_date` | NULL |
| `basis` | `statute` |
| `rule_id` | `ut-const-art6-first-day-january` |

### Two things the next step inherits

- ⚠ **Only 42 of Utah's 75 House offices are pending**, although Utah elects its whole House every
  two years. 33 carry no recorded winner. Likewise **8 of 29 Senate seats**, where a staggered
  half would be about 14. 🔴 **These are result gaps of a size worth investigating before the wave
  runs** — Utah is the largest such gap found so far in this pass.
- ⚠ **Utah's `STATE_BOARD_EDUCATION` districts are the `X0003` mtfcc case** `CLAUDE.md` names: they
  reach a voter only through the geofence join, never through `buildStatewideQuery`. Nothing in
  this dating pass changes that, but a wave that creates or moves one of these offices must not
  re-type it.

---

## CO — Colorado · 18 offices · ✅ sourced 2026-11-22 (5 bodies, 2 dates)

🔴🔴 **COLORADO'S LEGISLATURE IS THE FIRST BODY IN THIS PASS WHOSE DATE COMES FROM A `published`
SOURCE RATHER THAN A STATUTE — AND THE STATUTORY DEFAULT WOULD HAVE BEEN TWO DAYS WRONG.**

| body | offices | start date | authority | basis |
|---|---|---|---|---|
| House of Representatives | 6 | **2027-01-11** (Mon) | Art. V, § 7 + **HJR26-1031** | `published` |
| Senate | 3 | **2027-01-11** (Mon) | Art. V, § 7 + **HJR26-1031** | `published` |
| Governor · Secretary of State · Treasurer · Attorney General | 4 | **2027-01-12** (Tue) | Art. IV, § 1(1) | `statute` |
| State Board of Education | 2 | **2027-01-12** (Tue) | C.R.S. § 22-2-104(1) | `statute` |
| Board of Regents, University of Colorado | 3 | **2027-01-12** (Tue) | C.R.S. § 23-20-105(2) — ⚠ weaker, see below | `statute` |

### 🔴 The legislature: the term begins on CONVENING, and the convening date is designated

**Colo. Const. Art. V, § 7** — *General assembly – shall meet when – term of members*:

> The general assembly shall meet in regular session at 10 a.m. **no later than the second
> Wednesday of January** of each year. … **The term of service of the members of the general
> assembly shall begin on the convening of the first regular session of the general assembly next
> after their election.**

So the term start is an event — and **"no later than" is a deadline, not a date**.

**C.R.S. § 2-2-303.5** supplies the machinery:

> (2) **Unless a different date is established** in accordance with subsection (3) or (4) …, the
> general assembly shall meet in regular session at 10 a.m. on the second Wednesday of January of
> each year.
> (3) The general assembly, acting by joint resolution, may designate the date of convening the
> next regular session … **on or after January 1 but prior to** the date specified in subsection (2).
> (4) … the executive committee of the legislative council, after the regular session but **no
> later than November 1**, may designate the date …

**Colorado designated one.** `HOUSE JOINT RESOLUTION 26-1031`, signed 2026-06-03, read in full:

> That, pursuant to section 2-2-303.5 (3), Colorado Revised Statutes, the General Assembly
> designates **Monday, January 11, 2027**, as the convening date for the First Regular Session of
> the Seventy-sixth General Assembly.

Its own deadline schedule confirms it: *"1ST DAY (MONDAY 01/11/27)"*.

🔴 **Citing the statutory default would have produced 2027-01-13 and been two days wrong.** Both
windows for moving the date have now closed — subsection (3) requires action during a regular
session, and subsection (4)'s deadline was **2026-11-01**, three weeks ago — so **2027-01-11 is
now fixed**.

🟢🟢 **The control is in our own data and it is decisive, because it shows the default being
departed from.** Colorado legislative term starts in `essentials.office_terms`, sourced from
`leg.colorado.gov/legislators`:

| cycle | our rows | the day | second Wednesday of January | agrees with |
|---|---|---|---|---|
| 2019 | 6 | **2019-01-04** (Fri) | 2019-01-09 | **designated, earlier** |
| 2021 | 7 | **2021-01-13** (Wed) | 2021-01-13 | the default |
| 2023 | **37** | **2023-01-09** (Mon) | 2023-01-11 | **designated, earlier** |
| 2025 | **30** | **2025-01-08** (Wed) | 2025-01-08 | the default |

🔴 **Two of the last four cycles did NOT use the default, and both of those were years a
governor's term began** — which is the reason given for moving it: the General Assembly must
certify the gubernatorial result first. **2027 is a gubernatorial year**, and HJR26-1031 moved it
exactly as 2019 and 2023 were moved. ▶ **A "second Wednesday" rule row for Colorado would have
been right half the time and wrong this time.**

### The executives

**Colo. Const. Art. IV, § 1(1)**:

> The executive department shall include the governor, lieutenant governor, secretary of state,
> state treasurer, and attorney general, each of whom shall hold his office for the term of four
> years, **commencing on the second Tuesday of January in the year 1967, and each fourth year
> thereafter**.

Anchor-plus-cycle, the Arizona shape: 1967 + 4n reaches 2027. Second Tuesday of January 2027 =
**2027-01-12**. 🟢 **Control:** our one dated Colorado executive row starts **2019-01-08**, the
second Tuesday of January 2019.

⚠ **Only four executives are pending and that is correct** — Colorado's Lieutenant Governor runs
on the Governor's ticket (Art. IV, § 3), so it is the ticket case, not a gap.

### The two boards

**State Board of Education** — Art. IX, § 1 leaves the terms to be "by law prescribed", and
**C.R.S. § 22-2-104(1)** prescribes them, anchoring every cohort on the same day:

> … all such terms **commencing on the second Tuesday in January 1983** … **the second Tuesday in
> January 1985** … **the second Tuesday in January 1987** … a six-year term **commencing on the
> second Tuesday in January 2003** … both terms **commencing on the second Tuesday in January
> 2023**. … (3) Except as provided in subsection (1), members shall be elected for terms of six
> years.

Five independent anchors, the most recent from 2023, all on the second Tuesday in January.

**Board of Regents** — ⚠ **this one is the weakest citation in Colorado and is flagged rather than
smoothed over.** Art. IX, § 12 gives "terms of six years each" "in the manner prescribed by law";
**C.R.S. § 23-20-102** prescribes the manner and the cycle and **names no commencement at all**.
The only commencement evidence is **C.R.S. § 23-20-105(2)**, a 1973 transitional provision filling
vacancies, which fixes terms "**expiring on the second Tuesday in January, 1975** … **1977** …
**1979**" and sends their successors to § 23-20-102.

🔴 **That is transitional text, which is exactly what made Utah's Board of Education a refusal.
The difference, stated so the inconsistency is not silent:** in Utah the transitional dates pointed
at a boundary **different** from the legislature's, so they were evidence *against* borrowing. In
Colorado they point at the **same** boundary as the executives and the State Board of Education,
so they corroborate rather than contradict. The Regents are therefore dated, not refused — but
▶ **re-check the three against the Regents' own roster** (`regents.cu.edu/meet-the-regents`, which
`CC_0366` already used for identity) **before the wave runs.** No control exists: all 8 Regent rows
and all 8 State Board rows in `office_terms` carry `term_start NULL`.

### The source

The constitution from `https://leg.colorado.gov/sites/default/files/images/olls/crs2024-title-00.pdf`
(HTTP 200, `application/pdf`, 1,727,714 B — Title 00 of the Colorado Revised Statutes *is* the
constitution), the statutes from `…crs2024-title-02.pdf` (1,609,505 B), `…-title-22.pdf`
(7,499,629 B) and `…-title-23.pdf` (4,425,919 B), and the resolution from
`https://leg.colorado.gov/bill_files/117079/download` (265,766 B, the signed act). All fetched and
read 2026-11-22. ⚠ `crs2025-` and `crs2026-title-00.pdf` do not exist; 2024 is the current
printout and is marked "Uncertified Printout".

### Basis

`published` for the 9 legislative rows — the date comes from a designating resolution, not from
the statutory default. `statute` for the other 9.

### Term start or oath? — **term start for all five bodies**

Art. V, § 7 attaches the legislative term to convening, which is an event but an *organisational*
one, not an oath: members are sworn after the body convenes. Art. IV, § 1(1) and both statutes name
calendar days. 🔴 **Colorado's legislative date is therefore a convening date that IS the term
start** — the one combination this pass has not met before, and the reason `basis` is `published`
while the question "is it an oath?" still answers no.

### Carried into the row

| field | legislature | executives + both boards |
|---|---|---|
| `election_date` | 2026-11-03 | 2026-11-03 |
| `swearing_in_date` | **2027-01-11** | **2027-01-12** |
| `window_end_date` | NULL (the date is fixed, not a window) | NULL |
| `basis` | **`published`** | `statute` |
| `rule_id` | `co-hjr26-1031-convening` | `co-second-tuesday-january` |

---

## TX — Texas · 14 offices · ✅ sourced 2026-11-22 (2 dates, and the split is statutory)

🔴 **Texas has a single statute that dates almost every elected state officer — and it names, in
its own words, the four it does not reach.** That exclusion list is the whole of Texas's
complexity.

| body | offices | start date | authority |
|---|---|---|---|
| Attorney General · Comptroller · Land Commissioner · Agriculture Commissioner · Railroad Commissioner | 5 | **2027-01-01** (Fri) | Tex. Gov't Code § 601.003(a) |
| State Board of Education (Districts 2, 5, 6, 7, 9, 13, 14) | 7 | **2027-01-01** (Fri) | § 601.003(a), corroborated by Tex. Educ. Code § 7.103 |
| **Governor · Lieutenant Governor** | 2 | **2027-01-19** (Tue) | Tex. Const. Art. IV, § 4 + Gov't Code § 301.001 |

### The general rule, and the exclusion that creates the second date

**Tex. Gov't Code § 601.003 — REGULAR TERM OF STATE, DISTRICT, COUNTY, OR PRECINCT OFFICE:**

> (a) The regular term of an elective state, district, county, or precinct office **begins on
> January 1 of the year following the general election** for state and county officers.
> (b) A person elected to a regular term of office shall qualify and assume the duties of the
> office on, or as soon as possible after, January 1 …
> **(c) This section does not apply to the office of governor, lieutenant governor, state senator,
> or state representative.**

So eleven of Texas's fourteen pending offices are dated **2027-01-01** by one sentence, and the
exclusion in (c) is exactly what sends the Governor and Lieutenant Governor somewhere else.

⚠ **Tex. Const. Art. IV, § 23 is the clause a per-office search finds, and it does not answer the
question**: *"The Comptroller of Public Accounts, the Commissioner of the General Land Office, the
Attorney General, and any statutory State officer who is elected by the electorate of Texas at
large … shall each hold office for the term of four years."* Length, not commencement. The statute
supplies the day.

🟢 **The State Board of Education's own statute uses the same boundary**, which is why it is dated
with the five executives rather than separately: **Tex. Educ. Code § 7.103** — *"members of the
board serve staggered terms of four years with the terms of eight members **expiring on January 1**
of one odd-numbered year and the terms of seven members expiring on January 1 of the next
odd-numbered year."* ⚠ That is an *expiry*, so it corroborates § 601.003 rather than replacing it.

### 🔴 The Governor and Lieutenant Governor are INSTALLED, and the date is derived from two documents

**Tex. Const. Art. IV, § 4 — INSTALLATION OF GOVERNOR; TERM; ELIGIBILITY:**

> The Governor elected at the general election in 1974, and thereafter, **shall be installed on the
> first Tuesday after the organization of the Legislature, or as soon thereafter as practicable**,
> and shall hold his office for the term of four years, or until his successor shall be duly
> installed.

**Tex. Const. Art. III, § 5(a)** leaves the convening to statute — *"The Legislature shall meet
every two years at such time as may be provided by law"* — and **Tex. Gov't Code § 301.001**
supplies it:

> The legislature shall convene at the seat of government in regular session at **12 noon on the
> second Tuesday in January of each odd-numbered year**.

Second Tuesday in January 2027 = 2027-01-12; the first Tuesday after it = **2027-01-19**.

🟢🟢 **Control, and it is exact.** `essentials.office_terms` carries the Texas Governor's term
starting **2015-01-20**, written by a pass that never read Art. IV, § 4. The 84th Legislature
convened on 2015-01-13 (the second Tuesday), and the first Tuesday after that is **2015-01-20**.
The same arithmetic gives 2023-01-17, which is when Texas last inaugurated a governor.

⚠ **"or as soon thereafter as practicable" is a softener, not a second rule.** It has not been
needed in the cycles checked. If the 2027 installation slips, the published inauguration date
supersedes this and `basis` becomes `published`. ▶ **Re-check the two against the inauguration
before seating them**; the other twelve need no such check.

### The source

`https://statutes.capitol.texas.gov/Docs/CN/htm/CN.4.htm` and `…/CN.3.htm` for the constitution,
`…/Docs/GV/htm/GV.601.htm` and `…/GV.301.htm` for the Government Code, `…/Docs/ED/htm/ED.7.htm`
for the Education Code — the Legislative Council's own publication, read 2026-11-22.

⚠ **`statutes.capitol.texas.gov` is a JavaScript application and `curl` is useless on it**: every
`Docs/.../*.htm` URL returns **the same 250,874-byte page** containing only the site's navigation
(1,356 characters of text), whatever article is requested. 🔴 **The identical byte count across
different articles is the tell** — it looked like a successful fetch twice. Read in a browser; the
rendered Article IV is 26,357 characters.

### Basis

`statute` for all fourteen. ⚠ The Governor and Lieutenant Governor's date is **derived from two
provisions** rather than read off one, and the `authority` must quote both.

### Term start or oath? — **term start for twelve; INSTALLATION for two**

§ 601.003(a) says the term "begins on January 1" and (b) separately says the officer shall qualify
"on, or as soon as possible after" that day — 🔴 **the statute itself puts the term start before
the qualification, so the oath is plainly not the date for those twelve.**

For the Governor and Lieutenant Governor the term is attached to **installation**, which is the
ceremony. That is the Oregon/Nevada shape — term start and oath are the same event — but unlike
those two, Texas makes the event's date *computable in advance*, because the Legislature's
convening is fixed by statute rather than designated. **That is why these two are dated and
Oregon's Governor is not.**

### Carried into the row

| field | the twelve | Governor + Lt. Governor |
|---|---|---|
| `election_date` | 2026-11-03 | 2026-11-03 |
| `swearing_in_date` | **2027-01-01** | **2027-01-19** |
| `window_end_date` | NULL | NULL |
| `basis` | `statute` | `statute` |
| `rule_id` | `tx-govt-code-601-003-january-1` | `tx-const-art4-s4-installation` |

### 🔴🔴 Texas elected its entire House and half its Senate and we hold no result for any of it

Measured 2026-11-22: Texas has **150 `STATE_LOWER` and 31 `STATE_UPPER` office rows**, every one of
them with `term_start NULL`, and **not one appears in `essentials.office_pending_winner` for
2026-11-03**. Texas elects all 150 House seats every two years.

▶ **This is the largest result gap found anywhere in this pass** — larger than Utah's 33 House
seats, and it is a different kind, because here the offices exist and the *races* are what is
missing. It is seeding work, not dating work, and it is why Texas contributes 14 offices to this
queue instead of about 180. **Do not read "TX: 14 offices" as Texas being nearly done.**

---

## AL — Alabama · 13 offices · ✅ sourced 2026-11-22 — **one date, three provisions, and the statute writes it out in words**

| body | offices | start date | authority |
|---|---|---|---|
| Governor · Lt. Governor · Attorney General · Auditor · Secretary of State · Treasurer · Commissioner of Agriculture and Industries | 7 | **2027-01-18** (Mon) | Ala. Const. 2022, § 116 |
| Public Service Commissioner, Places 1 and 2 | 2 | **2027-01-18** (Mon) | Code of Ala. § 37-1-3(c)(1) |
| State Board of Education, Districts 2, 4, 6, 8 | 4 | **2027-01-18** (Mon) | Code of Ala. § 16-3-1 |

All three say the same thing in nearly the same words: **the first Monday after the second Tuesday
in January** next after the election. Second Tuesday in January 2027 = 2027-01-12; the first Monday
after it = **2027-01-18**.

### The authorities, each quoted

**Ala. Const. 2022, § 116** — *Term of Office; Officers May Succeed Selves for One Additional Term*:

> The governor, lieutenant governor, attorney general, state auditor, secretary of state, state
> treasurer, and commissioner of agriculture and industries, shall hold their respective offices
> for the term of four years **from the first Monday after the second Tuesday in January next
> succeeding their election** and until their successors shall be elected and qualified.

**Code of Alabama § 16-3-1** — *Composition; Election; Term of Office*:

> Each member shall hold office **from the first Monday after the second Tuesday in January next
> after his or her election** and until his or her successor is elected and qualified.

**Code of Alabama § 37-1-3(c)(1)**:

> All commissioners who are elected after June 1, 2026, shall serve terms of six years that **begin
> on the first Monday after the second Tuesday in January following the general election**.

### 🟢🟢 The control is the statute's own arithmetic, written as a date

`§ 37-1-3(b)(2)`, describing the appointments that expand the commission, says the Governor shall
appoint four commissioners **"to serve initial terms beginning January 18, 2027"**.

🔴 **Alabama's legislature computed this cycle's date itself, in words, and it is 2027-01-18** —
the same answer the formula gives. That is a stronger control than any aggregator or any row in
our own data, because it is the same body that wrote the formula applying it to this exact cycle.

### 🟢 The `chambers.inauguration_rules` lead was CORRECT — the first one in this pass that was

`SOURCING.md` flagged Alabama's State Board of Education rule row as a lead to verify: *"Code of
Alabama § 16-3-1: a member holds office from the first Monday after the second Tuesday in January
next after their election. For the 2026 winners that is 2027-01-18."* **Opened and checked against
§ 16-3-1: the citation is right, the paraphrase is right, and the computed date is right.**

⚠ **That does not retire the rule.** California's three executive rules said "1st Monday in the new
year" and cited nothing, and would have been right this cycle for the wrong reason. Alabama's
earns its way in **because it names a section that says what the row says it says**. ▶ The test
stays "does the row carry a citation that checks out", not "has a rule row ever been right".

### The source

`https://alison.legislature.state.al.us/constitution?section=116` and `…?section=114`;
`https://alison.legislature.state.al.us/code-of-alabama?section=16-3-1`, `…?section=37-1-3` —
ALISON, the Alabama Legislature's own system, read 2026-11-22.

⚠ **ALISON is a JavaScript application with no server-rendered law**, and `curl` returns a
59,580-byte navigation page. ⚠ **It is also not addressable by a naive URL until you have been
through the tree once** — the `?section=` parameter only appears in the address bar *after*
clicking Title → Chapter → Section, and a direct `?section=16-3-1` then works. **Click through
once, read the resulting URL, and reuse the pattern.**
⚠ `law.justia.com` returns **HTTP 403** to `curl` for Alabama, and `codes.findlaw.com` answers with
a Cloudflare interstitial (*"Just a moment… Enable JavaScript and cookies to continue"*, 60
characters of text) — **neither would have been usable as a source and neither is the state.**

### Basis

`statute` for all thirteen.

### Term start or oath? — **term start**

All three provisions say the officer "shall hold office from" / "shall serve terms … that begin on"
a computed calendar day. Alabama's oath is a separate requirement (`§ 16-3-6` is the Board's own
oath section, listed beside § 16-3-1 in the chapter). ⚠ § 116 and § 16-3-1 both add "**and until
his or her successor is elected and qualified**", which is the familiar holdover clause attaching
to the *end* of the predecessor's term, not to this one's start.

### Carried into the row

| field | all thirteen |
|---|---|
| `election_date` | 2026-11-03 |
| `swearing_in_date` | **2027-01-18** |
| `window_end_date` | NULL |
| `basis` | `statute` |
| `rule_id` | `al-first-monday-after-second-tuesday-january` (cite the per-body provision in `authority`) |

### 🔴🔴 Alabama's Public Service Commission is mid-restructure, and our model has three seats where it will shortly have seven

`§ 37-1-3(b)(1)`: *"Beginning after June 1, 2026 … **the membership of the commission shall be
expanded so that each commissioner shall represent and serve, and be elected by the qualified
voters of, a geographical district that shall be identical to a corresponding congressional
district**"*, phased so that all seven congressional districts are represented "by the terms
beginning in January 2033".

The schedule, from `(b)(2)` and `(b)(3)`:

| when | what happens |
|---|---|
| by 2026-07-15 | the Governor **appoints four** commissioners, terms beginning **2027-01-18** (two for two years, two for four) |
| Nov 2026 | **two** commissioners elected **in the old statewide manner** — this is our Place 1 and Place 2, and our data is correct for this cycle |
| Nov 2028 | three elected **by congressional district**, including the Seventh |
| Nov 2030 | two elected by district, including the Second |
| Nov 2032 | the remaining unrepresented districts |

**Measured 2026-11-22: we hold three Alabama PSC offices** — `Public Service Commission President`
(not pending; elected 2024, replaced in 2028 per (b)(3)(b)) and `Places 1` and `2` (both pending).
🔴 **On 2027-01-18 the commission will have seven members and we will model three.** The four
appointees are not election winners, so no 2026 wave reaches them — **this is a seeding job with a
dated trigger, exactly like Arizona's missing Lieutenant Governor**, and it has a published start
date in the statute itself.

▶ **Dated follow-up, 2027-01-18:** create the four appointed seats, and plan for `Place 1`/`Place
2` to become district seats across 2028–2032. ⚠ **Do not rename or re-district the two Place
offices now** — (b)(3)(a) says the 2026 pair was elected "in the same manner as commissioners were
elected before June 1, 2026", so for this cycle the at-large shape is the correct one.

---

## NE — Nebraska · 13 offices · ✅ sourced 2026-11-22 — **one residual clause, and the job was proving nothing displaced it**

| body | offices | start date | authority |
|---|---|---|---|
| Governor · Secretary of State · Attorney General · Auditor of Public Accounts · Treasurer | 5 | **2027-01-07** (Thu) | Neb. Const. Art. XVII-5 |
| University of Nebraska Regent, Districts 1, 2, 4 | 3 | **2027-01-07** (Thu) | Neb. Const. Art. XVII-5, restated for this body by `§ 32-573` |
| Public Service Commissioner, District 2 | 1 | **2027-01-07** (Thu) | Neb. Const. Art. XVII-5 |
| State Board of Education, Districts 5, 6, 7, 8 | 4 | **2027-01-07** (Thu) | Neb. Const. Art. XVII-5 |

**All thirteen on one day, from one clause.** First Tuesday in January 2027 = 2027-01-05; the first
Thursday after it = **2027-01-07**.

### 🔴🔴 THE CLAUSE IS A RESIDUAL, SO READING IT IS THE EASY HALF — THE WORK IS PROVING NOTHING OVERRODE IT

**Neb. Const. Art. XVII-5** — *Terms of office of all elected officers*:

> **Unless otherwise provided by this Constitution or by law** the terms of all elected officers
> shall begin on the first Thursday after the first Tuesday in January next succeeding their
> election.

That opening clause is the whole task. A residual rule is only the answer for a body that nothing
else answers for, so **each of the four bodies had to be checked twice** — once in the constitution
and once in the statutes — before this date could be written against it.

**Every one of them gives a term LENGTH and names no day.** In the constitution:

| provision | what it says | names a day? |
|---|---|---|
| `Art. IV-1` (executives) | "shall be chosen at the general election held in November 1974, and in each alternate even-numbered year thereafter, **for a term of four years** and until their successors shall be elected and qualified" | no |
| `Art. IV-20` (PSC) | "**whose term of office shall be six years**" | no |
| `Art. VII-3` (State Board of Education) | "**Their term of office shall be for four years each**" | no |
| `Art. VII-10` (Regents) | "**The terms of office of elected members shall be for six years each**" | no |

And in the statutes — **Chapter 32, Article 5 carries one section per body**, which is how they were
found; the chapter's own index was read rather than a keyword guessed:

| section | what it says | names a day? |
|---|---|---|
| `§ 32-506` Governor and Lieutenant Governor | "elected at the statewide general election in 1994 and each four years thereafter … terms of four years or until their successors are elected and qualified" | no |
| `§ 32-507` Treasurer, Auditor, Secretary of State, Attorney General | same shape, same words | no |
| `§ 32-509` Public service commissioners | "elected for a term of six years", plus which district is up in which year | no |
| `§ 32-510` Board of Regents | "shall serve for terms of six years or until their successors are elected and qualified" | no |
| `§ 32-511` State Board of Education | "shall serve for terms of four years or until their successors are elected and qualified" | no |

🟢 **`§ 32-572(1)` is the lock, because it says out loud that the day lives somewhere else:**

> Every officer elected or appointed for a fixed term shall hold office until his or her successor
> is elected or appointed and is qualified. The fixed term shall end and the successor, whether
> elected or appointed, shall qualify **on the day for taking office as provided by law**.

The Legislature wrote "the day for taking office as provided by law" and provided it nowhere in
these five sections. `Art. XVII-5` is what it is pointing at.

⚠ **`Art. XVII-5`'s own annotation narrows it usefully:** *"This section has reference only to
officers who have a fixed term."* (`Baker v. Moorhead`, 103 Neb. 811 (1919)). All thirteen have a
fixed term — four years for the executives and the Board of Education, six for the PSC and the
Regents — so all thirteen are inside it.

### 🔴🔴 THE ESCAPE HATCH IS NOT THEORETICAL. IT FIRES IN THIS STATE, ONE DAY AWAY, FOR A BODY WE DO NOT HOLD

The Secretary of State's own canvass book dates **Member of the Legislature** to **January 8,
2025** — *not* the January 9 it gives every other state body in the same document — and cites
`Neb. Const. Art. III-10`, `Art. III-8` and `Art. III-9` for it. Nebraska's unicameral has its own
constitutional commencement, and `Art. XVII-5` steps aside for it exactly as its first clause says.

🔴 **So "Nebraska takes office on the first Thursday after the first Tuesday" is FALSE as a
statement about Nebraska**, and true only of the bodies checked above. It is one day wrong for the
Legislature. ▶ **A residual clause must be quoted with its own first six words attached**, or the
next reader will apply it to a body that is carved out of it.

🟢 This wave is not exposed to that, for a reason that is itself worth writing down: **we hold no
Nebraska Legislature offices at all.** Measured 2026-11-22 — Nebraska has no `STATE_UPPER` and no
`STATE_LOWER` district rows, so all 49 seats of the unicameral are absent from our data. The trap
is dormant here rather than avoided, and it arms itself the day those seats are seeded.

### The controls — two cycles, two sources, neither written from this clause

**1. 🟢 The Secretary of State states the result per office, for the previous cycle, in her own
canvass book.** The 2024 General Canvass Book prints a metadata block above each contest, and for
three of this wave's four bodies it names them:

| office, as the book names it | Term Length | Term Start |
|---|---|---|
| Public Service Commissioner | Six years | **January 9, 2025** |
| Member of the State Board of Education | Four years | **January 9, 2025** |
| Member of the Board of Regents of the University of Nebraska | *(not printed)* | **January 9, 2025** |

The formula's answer for that cycle is 2025-01-09 (first Tuesday 2025-01-07, first Thursday after
it 2025-01-09). **It agrees exactly.**

⚠ **The pairing of each date to its office was checked, not assumed.** A canvass book is a PDF and
PDF text has no rows, so each `Term Start:` line was read with the lines above it rather than taken
in stream order — and the printed **Term Length beside it independently corroborates the pairing**:
six years against the PSC matches `Art. IV-20`, four years against the Board of Education matches
`Art. VII-3`. A mis-paired block would have had to agree with the constitution by accident.

⚠ **The four Term Starts in that book that are NOT January 9 are all explained**, which is what
makes the agreement meaningful rather than uniform: President 2025-01-20 (U.S. Const. amend. XX),
U.S. Senate and U.S. House 2025-01-03 (federal), Member of the Legislature 2025-01-08 (above), and
the Metropolitan Utilities District of Omaha 2025-01-07 (a local district with its own rule).

**2. 🟢 Our own data, written by a pass that never read Art. XVII-5.** `essentials.office_terms`
holds exactly one dated Nebraska term for these tiers: **Governor, `term_start` = 2023-01-05, a
Thursday.** The formula's answer for the 2022 cycle is 2023-01-05 (first Tuesday 2023-01-03). It
agrees exactly, and the day of the week is the formula's own signature.

**3. 🟢 The Nebraska Supreme Court said it, about the Governor specifically.** Annotated to
`Art. XVII-5`: *"Governor takes office on first Thursday after first Tuesday in January in
odd-numbered years."* `State ex rel. Johnson v. Hagemeister`, 161 Neb. 475, 73 N.W.2d 625 (1955).
This is the only one of the three controls that reaches the **executives**, and it reaches them
directly — the canvass-book control cannot, because 2024 was not a Nebraska gubernatorial year.

**4. 🟢 `§ 32-573` restates the formula in statute, for the Regents.** The Board of Regents vacancy
section describes the term boundary three times as *"the first Thursday following the first Tuesday
in January following such general election"*. It does not displace `Art. XVII-5` — **it is the
Legislature writing the same day into statute for one of these four bodies**, which is the
strongest possible answer to "did a law provide otherwise".

⚠ **The usual control for this pass — a biennial cluster of prior `term_start`s — is NOT available
for Nebraska.** One dated row is a point, not a cluster. It is reported as a point.

### The source

- `https://nebraskalegislature.gov/laws/articles.php?article=XVII-5` — and `IV-1`, `IV-20`, `VII-3`,
  `VII-10`, the Legislature's own publication of the Constitution, read 2026-11-22.
- `https://nebraskalegislature.gov/laws/statutes.php?statute=32-506` — and `32-507`, `32-509`,
  `32-510`, `32-511`, `32-572`, `32-573`, read 2026-11-22.
- `https://sos.nebraska.gov/sites/default/files/doc/elections/2024/2024%20General%20Canvass%20Book.pdf`
  — Secretary of State, 2024 General Canvass Book (3,223,182 bytes), read 2026-11-22.

🟢 **All of these answer plain `curl` with a browser User-Agent.** Nebraska is on the easy list.

⚠ **The constitution is NOT at `articles.php?article=XVII`** — the article and section are joined
with a hyphen, `article=XVII-5`, and the bare article number returns `Invalid statute number
format: 'XVII'` with **HTTP 200**. 🟢 It says so in words, which is better than most: the body of
the response names the fault instead of serving a navigation page. The per-section URLs are
discoverable from `/laws/browse-constitution.php`.

⚠ **The statute keyword search at `/laws/search_keyword.php` is token-OR and needs a CSRF token**
from `/laws/laws.php` plus the session cookie. It returned interstate licensure compacts for
"Public Service Commission term of office six years" and found none of the five sections that
actually govern. ▶ **The chapter index is what found them** — `browse-chapters.php?chapter=32`,
read as a list of section titles. Bounded by the document's own structure, not by a guessed phrase.

⚠ **The 2022 General Canvass Book carries no `Term Start` block at all** (41 occurrences of "Term",
none of them a label). The per-office metadata block is a 2024 format. So there is no canvass-book
control for the executives, and control 3 above is what covers them instead.

### Basis

`statute` for all thirteen.

### Term start or oath? — **term start**

`Art. XVII-5` says the **terms** "shall begin" on the computed day; it does not mention an oath.
⚠ `§ 32-572(1)` does use the word *qualify* — "the successor … shall qualify on the day for taking
office as provided by law" — but it fixes qualification **to** that day rather than making the term
begin whenever qualification happens. 🔴 **That is the opposite of Nevada**, where
`NRS 282.010(4)` starts the term *at* qualification and the day is therefore unknowable in advance.
Nebraska names the day and requires qualification on it. Read the direction of the sentence.

🟢 `§ 32-572(2)` bounds the slippage if someone fails to qualify: the incumbent holds over and the
swearing in "shall not be more than one calendar month from the day for taking office". That is a
`window_end_date` of 2027-02-07 if it is ever needed; **it is not needed here**, because the term
start is fixed and known.

### Carried into the row

| field | all thirteen |
|---|---|
| `election_date` | 2026-11-03 |
| `swearing_in_date` | **2027-01-07** |
| `window_end_date` | NULL |
| `basis` | `statute` |
| `rule_id` | `ne-const-art17-5-first-thursday-after-first-tuesday-january` |

### 🔴 The queue says three bodies. Nebraska has FOUR, and the fourth is hiding inside a district type

`SOURCING.md` lists Nebraska as `EXEC+BOARD+BOARD_EDUCATION`, and the register's generated table
gives it one `NE | STATE_BOARD | 4` row. **`STATE_BOARD` holds two different bodies**: the
University of Nebraska **Board of Regents** (3 of its 8 seats pending) and the **Public Service
Commission** (1 of its 5). They are separate chambers with separate constitutional articles — one
six-year board under `Art. VII-10`, one six-year commission under `Art. IV-20` — and they happened
to land on the same date.

▶ **`district_type` is not a body.** Count bodies by `chamber_id`, and do it before deciding how
many citations a state needs. Here it cost nothing because both fall to the same residual; in a
state where one of the two had its own commencement, reading the queue row as one body would have
dated it from the other's clause.

### ⚠ Two Nebraska gaps this block records and does not touch

- **LIEUTENANT GOVERNOR — the office exists and carries no winner.** `Art. IV-1`: *"Each candidate
  for Governor shall select a person to be the candidate for Lieutenant Governor on the general
  election ballot. In the general election one vote shall be cast jointly for the candidates for
  Governor and Lieutenant Governor."* The 2022 canvass book shows the ticket form directly — "Jim
  Pillen & Joe Kelly (Republican)". We hold one `Lieutenant Governor` office for Nebraska and
  **zero pending winners for it**, because the winner is recorded against the Governor's race.
  🔴 The date above governs the Lieutenant Governor too — `§ 32-506` covers both officers in one
  sentence — but **no wave reaches the seat until a winner row names its holder.** This is the
  ticket case the transition programme already knows: a ticket LG row names the governor.
- **THE LEGISLATURE — 49 seats, absent entirely.** Not a gap this pass created and not one it can
  close; recorded because the January 8 carve-out above becomes live the moment it is.

---

## NM — New Mexico · 11 offices · ✅ sourced 2026-11-22 — **two instruments, nearly the same words, one day**

| body | offices | start date | authority |
|---|---|---|---|
| Governor · Lieutenant Governor · Secretary of State · State Auditor · Treasurer · Attorney General · Commissioner of Public Lands | 7 | **2027-01-01** (Fri) | N.M. Const. Art. V, § 1 |
| Public Education Commissioner, Districts 2, 3, 5, 6 | 4 | **2027-01-01** (Fri) | Laws 2021 (2nd S.S.), ch. 3 (HB 9), § 3(B), codified NMSA 1978 § 22-3B-3 |

🟢 **The constitution and the statute were written sixty years apart and say the same thing in
nearly the same words** — "beginning on the first day of January next after their election" and
"for terms commencing on January 1 next succeeding their election". Both give **2027-01-01**.

### The authority — the seven executives

**N.M. Const. Art. V, § 1** — *[Composition of department; terms of office of members; residing and
maintaining records at seat of government.]*:

> The executive department shall consist of a governor, lieutenant governor, secretary of state,
> state auditor, state treasurer, attorney general and commissioner of public lands, who shall,
> unless otherwise provided in the constitution of New Mexico, **be elected for terms of four years
> beginning on the first day of January next after their election**. The governor and lieutenant
> governor shall be elected jointly by the casting by each voter of a single vote applicable to
> both offices.

🟢🟢 **That sentence names our seven `STATE_EXEC` offices one by one, and there are exactly seven of
them.** No reading-across, no inference from a sibling officer, no body left to account for. This is
the cleanest executive provision in the pass so far.

⚠ **"Unless otherwise provided in the constitution of New Mexico" is a carve-out and it was read as
one.** It is narrower than Nebraska's `Art. XVII-5` — it yields only to **the constitution**, not to
"or by law", so no statute can displace it. The section's own amendment note explains where the
clause came from: the 1958 amendment "omitted 'superintendent of public instruction' from list of
officers and added 'unless otherwise provided in the constitution of New Mexico' following 'who
shall'". ▶ So the clause exists to cover an office the constitution handles elsewhere, and **all
seven of ours are named in the list that survives**. 🔴 **This is reasoning, not a sweep** — the
constitution was not read end to end looking for an overriding provision. The reasoning is recorded
so the next reader can test it rather than inherit it.

### The authority — the Public Education Commission

**Laws 2021 (2nd Special Session), Chapter 3 (House Bill 9), the "2021 Educational Redistricting
Act", § 3**:

> **A.** Members of the public education commission shall be elected for staggered terms of four
> years.
> **B.** Members shall be elected at the general election **for terms commencing on January 1 next
> succeeding their election**.

🟢 **The `chambers.inauguration_rules` lead was CORRECT, and it is the second verified one in this
pass.** The row read: *"HB 9 (Laws 2021 2nd S.S. Ch. 3) Section 3B: members are elected at the
general election 'for terms commencing on January 1 next succeeding their election', so the 2026
winners take office on 2027-01-01."* **Opened and checked against the enrolled bill: the citation is
right, the quotation is exact, and the computed date is right.** Alabama's board rule was the first.
⚠ The test remains "does the row carry a citation that checks out", not "has a rule row ever been
right" — California's three executives still cite nothing.

### 🔴 The act is from 2021, so the question is whether it is still the law — and it is

A date read out of a five-year-old enrolled bill is a date read out of a **snapshot**. The risk is
not that the bill was misread; it is that something amended or repealed it since. Checked:

- HB 9 § 17 repealed `NMSA 1978 §§ 22-3A-1 through 22-3A-16` — the **2011** act it replaced.
- The current NMSA confirms that: **Chapter 22, ARTICLE 3A "2011 Educational Redistricting
  (Repealed.)"**, with all sixteen sections reading "Repealed."
- And it carries **ARTICLE 3B "2021 Educational Redistricting"**, *not* marked repealed, whose
  sections map one-to-one onto HB 9's: `22-3B-1. Short title.` · **`22-3B-3. Election for staggered
  terms.`** · `22-3B-16. Continuing terms; vacancies.` — the same titles in the same order as the
  bill's §§ 1, 3 and 16.

🔴 **What that establishes and what it does not.** It establishes that the act is **in force and
codified**, which was the actual risk. It does **not** re-read the current text of `22-3B-3` —
nmonesource serves section bodies only on a further click and the page state proved unstable across
calls. ▶ **The wording above is the enrolled bill's; the section's continued existence is the
codification's.** If a date ever turns on a word in `22-3B-3`, read the codified text.

### The control

🟢 **Our own data, written by a pass that never read Art. V § 1.** `essentials.office_terms` holds
exactly one dated New Mexico term for these tiers: **Governor, `term_start` = 2019-01-01.** "The
first day of January next after their election" for the 2018 cycle is 2019-01-01. **It agrees
exactly.**

⚠ **One row is a point, not the biennial cluster this pass usually gets** — the same shape as
Nebraska, and reported the same way. New Mexico holds no other dated term at these tiers.
⚠ **And there is no canvass-book control here.** New Mexico's Secretary of State publishes results,
not the per-office "Term Start" metadata block Nebraska's canvass book carries.

### 🔴🔴 PUBLIC EDUCATION COMMISSION DISTRICT 7 WAS ON THE 2026 BALLOT AND WE HAVE NO RECORD OF IT

Found while reading the Act, because the Act says which seats are up — and the number did not match.

**HB 9 § 3(C)**: *"Members from districts **two, three, five, six and seven** shall be elected …
at the 2022 and subsequent general elections."* **§ 16(D)** repeats the same five-district grouping
for vacancy appointments. So **five** PEC seats were due in 2026. **We hold four.**

**Confirmed against the state's own results**, not inferred: the New Mexico Secretary of State's
2026 general election results publish **five** Public Education Commissioner contests — Districts 2,
3, 5, 6 **and 7**. District 7, 178 of 178 precincts fully reported:

| candidate | party | share | votes |
|---|---|---|---|
| **Frederick Walton Parker** | Democrat | 65% | 38,596 |
| John Foreman | Republican | 35% | 20,355 |

**We hold a `Public Education Commissioner, District 7` office whose current holder is Patricia
Gipson, and no 2026 race for it at all** — not a race with a null result, as Nevada's Assembly
District 22 has, but no race row whatsoever. The seat changes hands and nothing in our data says so.

▶ **This is the Nevada AD22 rule firing again, one state later and in its harsher form.** There the
race existed with `result` NULL; here the race is absent entirely. Both are invisible to
`office_pending_winner`, and both make a chamber's pending count look like ordinary staggering.
🔴 **The Act is what caught it** — the same document that dates the body also says how many of it
were up. **Read that sentence and count against it.**

⚠ **AP cannot catch this one.** AP's New Mexico ballot carries no Public Education Commission
contest at all (checked: 89 distinct office/seat pairs, none of them PEC), so a wave derived from
AP would never know the body exists. The Secretary of State is the only source that has it.

### ⚠ New Mexico's whole legislature is absent too — 112 seats

Measured 2026-11-22: New Mexico has **no `STATE_UPPER` and no `STATE_LOWER` offices**. AP's own 2026
ballot for the state lists **70 State House districts** and a **State Senate District 33 unexpired
term**; the Senate is 42 seats. None of them exist in our data.

🔴 **That is the second state in a row with its entire legislature missing** — Nebraska's 49-seat
unicameral is absent in exactly the same way. ▶ **Worth measuring across the whole pass rather than
noticing one state at a time**: a state whose legislature is absent contributes only executives to
the queue, so it looks like a small, easy state and sorts to the bottom. **The queue's office counts
measure what we hold, not what the state elects.**

### ⚠ The Lieutenant Governor — a joint ticket that DOES carry its own winner

`Art. V § 1`: *"The governor and lieutenant governor shall be elected jointly by the casting by each
voter of a single vote applicable to both offices."* AP lists only "Governor" for New Mexico, with
no separate Lieutenant Governor contest.

🟢 **And yet our `Lieutenant Governor` office carries a pending winner of its own**, so it is seated
by the ordinary wave. 🔴 **That is the opposite of Nebraska**, where the identical joint-ticket rule
left the Lieutenant Governor office with **zero** pending winners and unreachable by any wave.
▶ **The ticket rule does not determine whether we hold a winner row — the ingestion does.** Check
per state; do not infer from the constitution which way it went.

### The source

- `https://nmonesource.com/nmos/c/en/item/5916/index.do` — **Constitution of New Mexico**, Article V
  § 1, on NMOneSource, which describes itself as *"the official legal research tool of the New
  Mexico courts and legislature"* and states that *"New Mexico statutes and court rules are updated
  on their effective dates"*. Read 2026-11-22.
- `https://nmonesource.com/nmos/nmsa/en/item/4368/index.do` — NMSA 1978 Chapter 22, for the
  Article 3A/3B repeal-and-replacement check. Read 2026-11-22.
- `https://www.nmlegis.gov/Sessions/21%20Special2/final/HB0009.pdf` — the enrolled **House Bill 9**,
  2021 2nd Special Session (37,233 bytes), the Legislature's own copy. Read 2026-11-22.
- `https://electionresults.sos.nm.gov/resultsSW.aspx?type=ECX&map=CTY` — Secretary of State,
  **GENERAL 2026** Public Education Commission results, marked *Unofficial Results*, "last updated:
  11/20/2026 4:02 PM MT". Read 2026-11-22.

### 🔴 `nmonesource.com` IS THE FIRST HOST IN THIS PASS THAT A COMPLETE HEADER SET DOES NOT OPEN

It answers **HTTP 403 with a 239-byte body** to plain `curl`, **and to `curl` carrying the whole
browser header set** — `Accept`, `Accept-Language`, `sec-ch-ua`, `sec-ch-ua-mobile`,
`sec-ch-ua-platform`, all four `Sec-Fetch-*` and `Upgrade-Insecure-Requests`. 🟢 **That is what the
header rule is for: it told us to stop escalating by guesswork.** `SOURCING.md` says Playwright is
the answer to a TLS-fingerprint or JS challenge and not to a thin request — **this is the
TLS-fingerprint case, and Playwright opened it immediately.**

⚠ **And then NMOneSource is a JS tree that needs clicking.** The constitution is at
`/nmos/c/en/item/5916/index.do`, articles expand one at a time, and a section's text loads only
after its own click. 🔴 **Its page state does not survive**: a DOM scan that had just read
"ARTICLE 3A … Repealed" returned **zero matches for the same string** on the next call, after an
expand had re-rendered the tree. ▶ **Re-navigate before each scan, and run a positive control on a
scan that returns nothing** — the first "none found" here was the detector being blind, not the
article being absent.

🟢 **`www.nmlegis.gov` serves enrolled bill PDFs to plain `curl`** at
`/Sessions/<YY>%20<Session>/final/HB####.pdf`, and 🟢 **`electionresults.sos.nm.gov` is readable**
(a `.aspx` app; the per-contest numbers come out of the rendered page).
⚠ **`www.nmlegis.gov/Legislation/Constitution` is a 404** — the Legislature does not host the
constitution; it links out to NMOneSource for "New Mexico Law (Statutes)".

### Basis

`statute` for all eleven.

### Term start or oath? — **term start**

Both instruments date the **term** and neither mentions an oath: `Art. V § 1` says the officers are
"elected for terms of four years **beginning on** the first day of January next after their
election", and HB 9 § 3(B) says "for terms **commencing on** January 1 next succeeding their
election". ⚠ New Mexico's oath requirement lives elsewhere and does not move either date.

⚠ **2027-01-01 is a Friday and a public holiday.** The term begins on it regardless — the provisions
name a calendar date, not a working day, and neither carries a "next business day" clause. Any
inauguration ceremony is a separate event and is not what either instrument dates.

### Carried into the row

| field | all eleven |
|---|---|
| `election_date` | 2026-11-03 |
| `swearing_in_date` | **2027-01-01** |
| `window_end_date` | NULL |
| `basis` | `statute` |
| `rule_id` | `nm-const-art5-1-first-day-of-january` (executives) · `nm-22-3b-3-january-1-next-succeeding` (PEC) |

---

## GA — Georgia · 10 offices · 🔴 **ALL TEN REFUSED, 2026-11-22** — the first state in this pass where no office can be dated

| body | offices | start date | why |
|---|---|---|---|
| Governor · Lieutenant Governor · Secretary of State · Attorney General · State School Superintendent · Commissioner of Insurance · Commissioner of Agriculture · Commissioner of Labor | 8 | 🔴 **REFUSED** — but `window_end_date` = **2027-01-16** is sourced | the day is **appointed by joint resolution** within a statutory week, and the resolution does not exist yet |
| Public Service Commissioner, Districts 3 and 5 | 2 | 🔴 **REFUSED** | `O.C.G.A. § 46-2-1.1` governs and **could not be read in full** — see "What stopped this" |

🔴🔴 **GEORGIA'S GOVERNOR DOES NOT TAKE OFFICE ON A DATE. HE TAKES OFFICE AT A CEREMONY, ON A DAY
THE LEGISLATURE PICKS AFTERWARDS.** This is Colorado's shape — a default that a joint resolution
may move — except that in Colorado the resolution had already passed and could be read, and here it
cannot exist until the General Assembly convenes on **2027-01-11**.

### The authority — the eight executives

**Ga. Const. Art. V, Sec. I, Para. I** gives the Governor a term LENGTH and no day:

> There shall be a Governor who shall hold office for **a term of four years and until a successor
> shall be chosen and qualified**.

**Ga. Const. Art. V, Sec. I, Para. II** names the event instead of a date:

> An election for Governor shall be held on Tuesday after the first Monday in November of 1986, and
> **the Governor-elect shall be installed in office at the next session of the General Assembly**.

⚠ **That is the "anchor year plus a formula" shape again** (Arizona's, Nebraska's) — "of 1986 …
quadrennially thereafter" — **and it still names no day**, because the operative words are "at the
next session".

**`O.C.G.A. § 45-12-2` (Inauguration)** is what fills that in, and it is the whole finding:

> The ceremony of inauguration shall take place **during the first week of the first session of the
> General Assembly after the election** and **on such day of that week as the General Assembly, by
> joint resolution, shall appoint**. If the General Assembly fails to appoint the day, the
> inauguration ceremony shall take place at **12:00 Noon on Saturday of that week** unless prevented
> by providential cause. **The Governor shall begin the discharge of his duties from the time of his
> inauguration.**

The other seven ride on the Governor's term, each by its own clause:

- **Lieutenant Governor** — `Art. V, Sec. I, Para. III`: "elected at the same time, **for the same
  term**, and in the same manner as the Governor."
- **Secretary of State, Attorney General, State School Superintendent, Commissioner of Insurance,
  Commissioner of Agriculture, Commissioner of Labor** — `Art. V, Sec. III, Para. I`: "Such
  executive officers shall be elected at the same time and **hold their offices for the same term as
  the Governor**."

🔴 **So all eight hang on one ceremony whose day is not yet appointed.** Georgia is on the
**qualification** side of the pass's line, like Nevada's six executives — the last sentence of
§ 45-12-2 says so outright: the Governor's duties begin "from the time of his inauguration". **The
term start IS the ceremony**, not a calendar date the ceremony happens to follow.

### 🟢 The window IS sourced, and that is what this block delivers

`office_swearing_in` has `window_end_date` for exactly this. Both ends come from law:

| bound | value | from |
|---|---|---|
| earliest | 2027-01-11 | `Ga. Const. Art. III, Sec. IV, Para. I` — the General Assembly "shall meet in regular session on the **second Monday in January** of each year". Second Monday of January 2027 = 2027-01-11. |
| latest | **2027-01-16** | `O.C.G.A. § 45-12-2` — the ceremony is within "the first week" of that session, and absent a joint resolution it falls at **noon on Saturday of that week** = 2027-01-16. |

▶ **`window_end_date = 2027-01-16` is a statutory backstop, not an estimate**, and it is the second
use this pass has found for the column (Nevada's `2027-01-04` was the first). 🔴 **`swearing_in_date`
stays NULL and `basis` stays unwritten until the joint resolution names the day** — then it is
`published`, recorded when it happens.

⚠ **Both bounds carry an escape clause and neither is absolute.** `Art. III, Sec. IV, Para. I` says
"second Monday in January **or otherwise as provided by law**", so a statute could move the session
and the whole window with it; and § 45-12-2's Saturday fallback yields to "providential cause".
▶ **Re-read both before writing the window into a migration**, and check whether the 2027 session
was moved.

### 🔴🔴 THE CONTROL LOOKS LIKE IT WORKS AND IT IS A COINCIDENCE — THIS IS THE ONE-POINT TRAP

`essentials.office_terms` holds exactly one dated Georgia executive term: **Governor,
`term_start` = 2019-01-14, a Monday** — and 2019-01-14 **is** the second Monday in January 2019. A
reader with only that row would conclude Georgia inaugurates on the session's opening day and write
**2027-01-11**.

🔴 **The statute says that is not a rule.** § 45-12-2 permits **any day of that week**, Monday
through Saturday, chosen afresh each cycle by joint resolution. 2019 landing on day one of the week
is one draw from six, not a formula — and a single agreeing data point cannot tell those apart.

▶ **This is why a one-row control is reported as a point and never as a cluster.** Nebraska and New
Mexico each had one row too, and in both of those the *instrument* named a calendar formula, so the
point confirmed a rule that already existed on paper. Here the instrument names **a choice**, so the
point confirms nothing at all. **What a control is worth depends on what the law says, not on
whether the number matched.**

⚠ **Not checked, and it would settle it:** the day appointed for the **2023** inauguration, and the
joint resolution that appointed it. The 2023 session convened 2023-01-09, so its first week ran to
2023-01-14. If 2023's day is not 2023-01-09, the coincidence above is demonstrated outright rather
than argued from the statute. ▶ **Worth one look at the General Assembly's own resolution before
anyone trusts a Georgia date.**

### 🔴 What stopped the Public Service Commission, stated exactly

`O.C.G.A. § 46-2-1(a)` puts five commissioners on the ballot under "the same rules and regulations
as apply to the election of Governor", and then defers: members "**shall serve the terms provided
for in Code Section 46-2-1.1**".

**`O.C.G.A. § 46-2-1.1` — "Elections for Georgia Public Service Commission Districts 2, 3, and 5"**,
enacted by **Ga. L. 2024, p. 36, § 2 / HB 1312, effective April 18, 2024** — subsection (a) read in
full:

> The provisions of this Code section are intended to address the situation created as a result of
> elections for Public Service Commission Districts 2, 3, and 5 **not being conducted in 2022 or
> 2024 pursuant to an injunction issued in *Rose v. Raffensperger*, 619 F. Supp. 3d 1241 (N.D. Ga.,
> 2022)**, and is further intended to preserve the state's interest in ensuring that members of the
> commission are elected in staggered elections and serve staggered terms.

🔴 **Our two pending seats are Districts 3 and 5 — two of the three this section is about.** Their
terms are therefore set by a bespoke remedial statute, not by the general rule, and **subsection (b)
onward is where the dates are.** It begins "Those members of the commission in office on January 1,
2024, as well as any person appointed to fill …" and **the text was cut off at that point by the
publisher's bot check.**

▶ **Do not reach for the Governor's window for these two.** § 46-2-1(a) borrows the Governor's
*election* rules, not his *term*, and § 46-2-1.1 exists precisely because these seats are off the
normal cycle. Dating them from § 45-12-2 would be the Washington error — taking the nearest
provision that mentions a date and applying it to an office it does not govern.

### The source

- `https://sos.ga.gov/sites/default/files/forms/Georgia%20Constitution.pdf` — **Constitution of the
  State of Georgia, Revised July 2025**, the Secretary of State's own electronic edition
  (1,780,352 bytes). Read 2026-11-22. Art. III Sec. IV Para. I; Art. V Sec. I Paras. I–III;
  Art. V Sec. III Para. I.
- `https://advance.lexis.com/container?config=00JAAzZDgzNzU2ZC05MDA0LTRmMDItYjkzMS0xOGY3MjE3OWNlODIKAFBvZENhdGFsb2fcIFfJnJ2IC8XZi1AYM4Ne`
  — the **Official Code of Georgia Annotated**. §§ 45-12-2, 46-2-1, 46-2-1.1. Read 2026-11-22.

🟢 **LexisNexis IS the state's own publisher here, and that is worth knowing before anyone rejects
it as an aggregator.** `www.legis.ga.gov` links out to it for both "Georgia Code" and "Georgia
Constitution", and the site itself states: *"These online legal resources are made available for
public use by the Georgia Code Revision Commission on behalf of the Georgia General Assembly through
a contractual arrangement with LexisNexis, which prepares and maintains this website."* ▶ **That is
a different thing from `law.justia.com` or `codes.findlaw.com`**, which this pass refuses because
they are not the state. Georgia has no other official code.

### ⚠ Georgia's sources, and how each one fails

| host | what happens | what to do |
|---|---|---|
| `www.legis.ga.gov` | an **Angular SPA** serving a 1,492-byte loader to `curl`; every path renders, then redirects to `/error/404` | browser; and it holds no law anyway — it links out |
| `sos.ga.gov` | 🟢 **serves the constitution PDF to plain `curl`** | the best Georgia source in this block |
| `advance.lexis.com` | search-result **snippets render and are readable**; **opening a full document redirects to `/RobotValidation` — "Captcha Validation"** | read what the snippet gives; a section longer than its teaser is not reachable this way |
| `ga.elaws.us` | **hung with no response** until the 120-second command timeout | not retried |

🔴 **A SOFT 404 ON TWO DIFFERENT HOSTS, BOTH HTTP 200.**
`www.legis.ga.gov/api/document/docs/default-source/reference-documents/constitution_2020.pdf`
answers **200 with 1,946 bytes of HTML** whose title is *"The resource cannot be found."*, and
`sos.ga.gov` answers **404 with a 21 KB HTML page** for a missing PDF. ▶ **Neither status code told
the truth about whether a PDF was there; the `Content-Type` did.** `application/pdf` or it is not a
PDF.

### Basis

**None written.** All ten are refused. 🔴 `estimated` is not available — the seating migration's P4
refuses it — and that is the correct outcome here rather than an obstacle to work around.

### Term start or oath? — **they are THE SAME EVENT, which is why this is a refusal**

`O.C.G.A. § 45-12-2`: "The Governor shall begin the discharge of his duties **from the time of his
inauguration**." `O.C.G.A. § 45-12-4` puts the oath in that same ceremony, before the General
Assembly in joint session. So Georgia is Nevada's case, not Alabama's: there is no calendar date
that the oath merely follows. **Whoever records these eight must record an inauguration date and say
that is what it is.**

### Carried into the row

| field | the 8 executives | the 2 PSC seats |
|---|---|---|
| `election_date` | 2026-11-03 | 2026-11-03 |
| `swearing_in_date` | *unknown — a ceremony on a day not yet appointed* | *unknown* |
| `window_end_date` | **2027-01-16** (sourced: `O.C.G.A. § 45-12-2`) | — |
| `basis` | `published`, when the joint resolution names the day | — |
| `rule_id` | `ga-45-12-2-inauguration-week-by-joint-resolution` | — |

▶ **Dated follow-up, on or just after 2027-01-11:** the General Assembly convenes; read the joint
resolution it passes and record the appointed day as `published` for all eight. If none passes, the
day is noon on 2027-01-16 by operation of the statute.

### 🔴🔴 236 GEORGIA LEGISLATIVE SEATS HAVE NO 2026 RACE — THE LARGEST GAP FOUND IN THIS PASS

Measured 2026-11-22: we hold **180 Georgia House** and **56 Georgia Senate** offices, and **not one
of them has a 2026 race row** — `has_2026_race = 0` across all 236. Georgia elects its **entire**
General Assembly every two years, so every one of those seats was on the 2026 ballot.

🔴 **This is the third shape of the same defect in three consecutive states, and it is the worst
one:**

| state | shape | seats |
|---|---|---|
| NV | race exists, `result` NULL on every candidate | 1 (AD22) |
| NM | no race row for a seat the Act puts on the ballot | 1 (PEC District 7) |
| **GA** | **offices exist, no race rows at all, for two entire chambers** | **236** |

⚠ **And it is invisible to this queue by construction.** The register counts *pending winners*, so
Georgia shows as "STATE_EXEC 10" and sorts near the bottom as a small executive-only state —
exactly the way Nebraska and New Mexico do, except that those two are missing the **offices** and
Georgia is missing the **results**. 🔴 **A state can be absent from this pass for three different
reasons and all three look identical from the queue.** ▶ **One query across all 41 states, comparing
offices held against races recorded against each chamber's real size, would separate them.** It has
not been run.

---

## AR — Arkansas · 7 offices · 🔴 **FIVE REFUSED WITH A CITED WINDOW · TWO STILL OPEN**, 2026-11-23

🔴 **Supersedes the "four provisions read, no date" block committed on 2026-11-22.** That block
was right about what it had read and wrong about one thing it inferred — the correction is marked
below. Nothing here dates an Arkansas office; five of the seven now refuse **with a window**, which
is a result, and two remain genuinely open.

| body | offices | start date | state of play |
|---|---|---|---|
| Governor · Secretary of State · Treasurer of State · Auditor of State · Attorney General | 5 | 🔴 **REFUSED — window 2027-01-11 → 2027-01-17** | `Art. 6 § 3`: the Speaker opens and publishes the returns **during the first week of the session** and the winner "shall be declared duly elected thereto". The day is not fixed by any instrument |
| Commissioner of State Lands | 1 | ⏳ **open** | 🟢 **It is a STATUTORY office**, not a constitutional one — `Art. 6 § 1` lets the General Assembly create it. That is why it is excluded from the Schedule and absent from `Art. 6 § 3`. Its commencement is a question for the Code |
| Lieutenant Governor | 1 | ⏳ **open** | 🟢 **The word "Lieutenant" does not occur anywhere in the 1874 Constitution or in Amendments 1–10.** A later amendment created it and that amendment has not been read |

### 🔴 THE CORRECTION: `Schedule § 20` IS TRANSITIONAL, AND IT CANNOT DATE A 2026 OFFICER

The previous block read `Schedule § 20` as a live residual and reasoned that the Lieutenant
Governor, never being excluded from it, would fall inside it and start **within fifteen days of
notification** — a different day from the Governor's. 🔴 **Do not act on that.** Reading the
sections on either side of it, which the teaser never showed, settles it:

> **Sec. 19.** **At said election** the qualified voters of each county and senatorial district …
>
> **Sec. 20.** All officers elected under this Constitution, except the Governor, Secretary of
> State, Auditor of State, Treasurer, Attorney General and Commissioner of State Lands, shall enter
> upon the duties of their several offices when they shall have been declared duly elected **by said
> State Board of Supervisors** and shall have duly qualified …
>
> **Sec. 22.** **The first session of the General Assembly under this Constitution shall commence on
> the first Tuesday after the second Monday in November, 1874.**

⚠ **§ 20's declaring body is "said State Board of Supervisors"**, an 1874 body defined by § 19 and
long gone, and § 22 names the year outright. The Schedule is the instrument's own commissioning
clause. ▶ **This is `CLAUDE.md`'s bound-a-parse rule in a legal document**: a provision read out of
its own structure gave a plausible fifteen-day answer for an office that did not exist when it was
written. **Read the sections around the one you were given.**

### 🟢 `Art. 6 § 3` IN FULL — the sentence the publisher's teaser cut off

> The Governor, Secretary of State, Treasurer of State, Auditor of State and Attorney General shall
> be elected by the qualified electors of the State at large at the time and places of voting for
> members of the General Assembly; the returns of each election therefor shall be sealed up
> separately and transmitted to the seat of government by the returning officers, and directed to
> the Speaker of the House of Representatives, who shall, **during the first week of the session**,
> open and publish the votes cast and given for each of the respective officers hereinbefore
> mentioned, in the presence of both houses of the General Assembly. **The person having the highest
> number of votes for each of the respective offices shall be declared duly elected thereto**; but
> if two or more shall be equal, and highest in votes for the same office, one of them shall be
> chosen by the joint vote of both houses of the General Assembly, and a majority of all the members
> elected shall be necessary to a choice.

🟢 **THE CONTROL, AND IT IS A STRONG ONE.** The text above comes from a scan, not from the
state's publisher. The official publisher's teaser — read on `advance.lexis.com`, the AR Bureau of
Legislative Services source — ends mid-clause at "in the presence". **The two agree word for word
across the whole 90-word overlap**, down to "hereinbefore mentioned". A transcription that matches
the official text for ninety words and then diverges in the ninety-first is not a failure mode worth
positing; and the agreement also says `Art. 6 § 3` **has not been amended since 1874**, because the
current official text still reads as the adopted text does. ⚠ Comma placement differs in two
places, which is what a 1915 printing versus a modern reset looks like, and changes no meaning.

### The window, from both sides

| | date | authority |
|---|---|---|
| session convenes | **2027-01-11**, 12:00 noon | `Ark. Code § 10-2-101(a)` — second Monday in January of each odd-numbered year |
| latest the Speaker may publish | **2027-01-17** (outer bound) | `Art. 6 § 3` — "during the first week of the session". ⚠ **Inferred, not stated** |

🟢 **Why the convening date was not in the Constitution, and why the earlier search failed.**
`Art. 5 § 5` (1874) reads: *"The General Assembly shall meet at the seat of government every two
years on the first Tuesday after the second Monday in **November** until said time be altered by
law."* 🔴 **The Constitution delegates its own convening date to statute, and the date it names is
in November.** The previous session searched the Constitution for `"second Monday in January"`,
found nothing, and concluded Arkansas "words it differently" — the real answer is that the
Constitution does not contain the date at all. ▶ **When a clause ends "until altered by law", stop
searching the instrument and go to the Code.**

The Code's answer is stated by the **Arkansas Bureau of Legislative Research**, the General
Assembly's own agency, in `2027 REGULAR SESSION IMPORTANT DATES AND DEADLINES`:

> **Convening regular session: January 11, 2027.** Arkansas Code § 10-2-101(a) sets 12:00 noon on
> the second Monday in January of each odd-numbered year for the convening of the General Assembly
> in regular session. This rule is derived from Arkansas Constitution, Article 5, § 5, **which
> permits the General Assembly to establish the date**.

🟢 That document does three jobs at once: it gives the date, it names the statute, and it
**confirms that `Art. 5 § 5`'s delegation is still the live mechanism** — which is the part a bare
statute citation would not have proved.

⚠ **`window_end_date` here is weaker than Georgia's.** `O.C.G.A. § 45-12-2` names an explicit
fallback — noon on Saturday of that week — so Georgia's **2027-01-16** is statutory. Arkansas
names no fallback at all, so **2027-01-17** is the seventh day of a session that begins on a Monday
and nothing more. Record it as a bound; do not cite it as a rule.

### 🔴 Arkansas refuses for a DIFFERENT reason from Georgia, and the difference matters

Georgia's term **is** the ceremony: `O.C.G.A. § 45-12-2` says "the Governor shall begin the
discharge of his duties from the time of his inauguration", so the event is the start and only the
day is unknown. **Arkansas says no such thing.** `Art. 6 § 3` says only that the person *is declared
duly elected*; `Amendment 63 § 1` says they *hold their offices for the term of four (4) years, and
until their successors are elected and qualified*. ▶ **So two things are unknown in Arkansas, not
one**: which day in that week, **and whether the start is the declaration or the qualification that
follows it.** The window is sound either way, because both events fall inside it — but a future
session must not write `basis = 'statute'` against a declaration date without settling that.

### ⏳ What is still open

1. **Whether the term begins at the declaration or at qualification.** `Ark. Code` Title 21 (Public
   Officers and Employees) and Title 7 (Elections) are the places to look.
2. **The amendment that created the Lieutenant Governor**, and whether it carries its own
   commencement. ⚠ **It is not Amendment 6** — that one is about sureties on official bonds,
   proclaimed by Governor Jefferson Davis on 1902-02-20. Recorded because 6 is the number a reader
   guesses.
3. **The Commissioner of State Lands' commencement**, now known to be a statutory question.
4. **The `office_terms` control**, still not run — and per the Georgia lesson it proves nothing
   here, because the start is a choice within a week rather than a calendar formula.

### What was read, and from where

| instrument | read in full? | source |
|---|---|---|
| `Art. 6 § 1` (1874 original: five officers, two-year terms, and the Commissioner authorised) | ✅ | archive.org scan |
| `Art. 6 § 3` | ✅ | archive.org scan, controlled against the Lexis teaser |
| `Art. 5 § 5` | ✅ | archive.org scan, confirmed live by the BLR document |
| `Schedule §§ 19–24` | ✅ | archive.org scan |
| `Amendment 63 § 1` | ✅ (§ 1 only) | Lexis teaser, 2026-11-22 |
| `Amendments 1–10` | ✅ | archive.org scan — **no Lieutenant Governor in any of them** |
| `Ark. Code § 10-2-101(a)` | ❌ quoted by the BLR, not read directly | arkleg.state.ar.us |

**The document.** `archive.org/download/constitutionofst00arka/` — *Constitution of the State of
Arkansas, adopted in convention September 7, 1874*, scanned from the **Secretary of State's Biennial
Report** (the running head prints "Biennial Report of Secretary of State" on each page), with
Amendments 1–10 appended. Served as a PDF (3.9 MB) and, more usefully, as `_djvu.txt` (167 KB) to
plain `curl`. ⚠ **It is OCR**: `River` reads `Eiver`, `qualified` reads `quaKfied`. That is exactly
why the overlap control with the official publisher was run before any of it was quoted.

### 🟢 Sourcing notes — what answered, what lied, and one new file route

- 🔴 **A web-search summary named two official-looking Arkansas hosts and NEITHER EXISTS**:
  `ssl-sos-site.ark.org` (offered as "the Secretary of State's PDF of the 1874 Constitution") and
  `digitalheritage.arkansas.gov` (offered as "the Arkansas State Archives, all five constitutions
  transcribed"). Both fail DNS with **Non-existent domain**, while `sos.arkansas.gov` and
  `arkleg.state.ar.us` resolve from the same shell seconds apart. ⚠ The first of the two is even
  cited inside `sos.arkansas.gov`'s own HTML, so it is a stale internal name the search engine
  repeated, not an invention. ▶ **`CLAUDE.md`'s rule — a search summary is a lead, not evidence —
  applies to the HOSTNAME as much as to the fact.**
- 🔴 **`www.sos.arkansas.gov` does not publish the Constitution, and its 404 is a 404.** Its
  `/publications/` page carries **222 links and 15 PDFs** — a notary handbook, capitol tour guides,
  an apostille brochure — and no law. Every missing path returns a stable **57,106-byte** HTML error
  body, which is a usable fingerprint.
- 🔴 **Two more ways a 200 lies, both on that host**: `/search?q=constitution` answers **HTTP 200
  with 0 bytes**, and `/?s=constitution` answers **HTTP 200 with the homepage, byte for byte
  (66,824)** — the query is simply dropped. Neither is a search result and both look like one.
- **`arkleg.state.ar.us` answers plain `curl`**, and its only route to the Constitution is an
  external-link modal whose target is `lexisnexis.com/hottopics/arcode/` — read out of the page, so
  the arkleg route is closed by its own design, not by a block.
- 🟢 **arkleg has an unauthenticated FILE route: `/Home/FTPDocument?path=<url-encoded path>`.**
  That is how the BLR session-dates PDF was obtained. ⚠ There is no listing: `FTPDirectory` and
  `FTPFolder` answer **500**, and `FTPDocument?path=/` answers **200 with a 42-byte `image/gif`** —
  a placeholder, which is a 200 that lies in a sixth way. You must already know the path.
- 🔴 **Lexis's search cannot be driven in Playwright either.** Submitting — by Enter or by
  clicking the Search button, from both the Code and the Constitution entry points — fires an XHR
  that redirects to `signin.lexisnexis.com` and is **blocked by CORS**; the page then silently does
  not navigate and looks unchanged. ▶ **A browser was the right escalation for the Georgia PDF and
  is the wrong one here**: the wall is an unauthenticated API, not a bot check. Reaching the
  Constitution source works (`AR Bureau of Legislative Services | PAW Constitution Main Page`
  loads); only searching it does not.

### Basis

**None written. No Arkansas office is dated.** Five carry a window; two are open.

---

## ID — Idaho · 7 offices · ✅ sourced 2026-11-23 — **one provision says it outright, and the work was proving nothing displaced it**

**All seven start 2027-01-04**, the first Monday in January 2027.

| body | offices | start date | basis |
|---|---|---|---|
| Governor · Lieutenant Governor · Secretary of State · State Controller · Treasurer · Attorney General · Superintendent of Public Instruction | 7 | **2027-01-04** | `statute` — `Idaho Const. Art. IV, § 1` |

### The provision

**`Idaho Const. Art. IV, § 1` — *Executive officers listed — Term of office — Place of residence
— Duties*:**

> The executive department shall consist of a governor, lieutenant governor, secretary of state,
> state controller, state treasurer, attorney general and superintendent of public instruction,
> **each of whom shall hold his office for four years beginning on the first Monday in January next
> after his election, commencing with those elected in the year 1946, except as otherwise provided
> in this Constitution.** The officers of the executive department shall, during their terms of
> office, reside within the state. …

🟢 **It does three jobs in one sentence**, which is why Idaho is the shortest state in this pass:

1. **It names exactly our seven offices**, in our order, with no eighth and no omission. Our
   `Treasurer` is its `state treasurer`; everything else matches on the word. After Arkansas —
   where three provisions named three different memberships — this was checked before anything else.
2. **It fixes the day by formula, not by choice.** "The first Monday in January next after his
   election" is a calendar rule with one answer per cycle. 🔴 **That is the distinction Georgia
   turned on**: `O.C.G.A. § 45-12-2` lets the legislature *appoint* a day within a week, so an
   agreeing row there proves nothing. Idaho leaves nothing to appoint, so its agreeing rows count.
3. **It states the cycle, and the cycle checks out.** "Commencing with those elected in the year
   1946" — and 2026 − 1946 = 80, which is divisible by four. 🟢 So the instrument that dates the
   body also confirms **all seven were up in 2026**, which is the register's count of 7 winners.

**First Monday in January 2027 = 2027-01-04.** 2027-01-01 falls on a Friday, so the 4th is the first
Monday. Computed, not counted by hand.

### 🔴 "EXCEPT AS OTHERWISE PROVIDED IN THIS CONSTITUTION" — discharging that clause WAS the work

A residual that excepts itself is the Texas `§ 601.003(c)` shape and the Arkansas `Schedule § 20`
shape, and in both of those the exception was where the state got hard. ▶ **So the whole
constitution was listed by section title** — 21 articles, **227 sections** — and read for anything
that could give one of these seven a different start. **Two candidates existed. Both are dead.**

| candidate | why it is not an exception |
|---|---|
| `Art. III § 25` — **Oath of office** | 🟢 It binds **"the members of the legislature"** and nobody else, and the oath it prescribes swears the taker to "the duties of senator (or representative)". 🔴 **The Idaho Constitution contains no oath provision for executive officers at all.** |
| `Art. XXI § 13` — **Tenure of office** | "All officers elected **at said election** shall hold their offices until the legislature shall provide by law … for the election of their successors". 🔴 `Art. XXI` is Idaho's **Schedule**: § 5 continues the officers "now holding their offices … **in this territory**", § 7 is "when Constitution takes effect", § 14 is "convention of first legislature". Transitional, 1890. |

🟢 **The second one is the Arkansas lesson firing one state later, and it fired correctly.**
Arkansas's `Schedule § 20` reads as a standing residual and is not one; Idaho's `Art. XXI § 13` reads
the same way and is not one either. **Both were caught by reading the sections around them rather
than the section alone.** ▶ A state's "Schedule" is its commissioning clause until its own
neighbours say otherwise.

### ✅ The oath question, answered in writing

**The date is a date OF THE TERM, and the oath is not it.** `Art. IV § 1` says the officer "shall
hold his office for four years **beginning on** the first Monday in January" — a calendar date
attaching to the office, with no qualification condition anywhere in the sentence. And there is no
executive oath clause in the constitution to compete with it. 🔴 **So Idaho is the opposite of
Nevada**, where `Art. 5 § 2` runs the term "from the time of his installation" and `NRS 282.010(4)`
makes installation mean qualification — there the oath IS the term start. Here it is a separate
event and **must not be rendered as one**.

### 🟢 The controls — two that count, and one that looks like a third and is a trap

| office | `office_terms.term_start` | first Monday that January? | counts? |
|---|---|---|---|
| Governor (Little) | **2019-01-07** | ✅ 2019-01-01 was a Tuesday | ✅ sourced to `gov.idaho.gov/past-governors/` and NGA |
| Superintendent (Critchfield) | **2023-01-02** | ✅ 2023-01-01 was a Sunday | ✅ and its own source note already cites `Art. IV § 1` |
| State Controller (Woolf) | **2012-10-15** | — | 🔴 **NO** |

🔴🔴 **2012-10-15 IS ALSO A MONDAY.** A check shaped "are Idaho's executive term starts
Mondays?" passes on all three rows and proves nothing — and worse, it quietly admits a **mid-term
appointment** as evidence for the elected-term formula. The row is honest about itself: its own
source note says *"a mid-term arrival rather than a first-Monday-in-January one, so how_started is
appointed"*. ▶ **The discriminating field is the MONTH, not the weekday**, and the only reason this
did not become a third agreeing control is that the row was read instead of counted. This is
`CLAUDE.md`'s *a predicate reads the shape of a value, never what the value is*, on a date.

⚠ **Two controls is not many**, and four of the seven offices carry no `office_terms` row at all
(Secretary of State, Treasurer, Attorney General, Lieutenant Governor — all `backfill from
essentials.offices.politician_id`). The two that exist were written by different migrations from
different sources, which is the part that makes them independent of each other.

### The register's own numbers

All seven winners are **returning incumbents** — Little, Bedke, McGrane, Woolf, Ellsworth, Labrador,
Critchfield — and all seven results are `called`, none `certified`. ⚠ Ruling B governs whether that
is enough to seat; it is not a sourcing question and nothing here depends on it.

🟢 **`chambers.inauguration_rules` is NULL for all seven Idaho offices**, so there was no lead to
check and nothing to contradict. Recorded because the recipe says a rule row earns its way in by its
own citation — an absent row is cleaner than a bad one.

### Sourcing notes

- 🟢 **`legislature.idaho.gov` serves the whole constitution to plain `curl`** — no browser, no
  headers beyond the ordinary set, one page per section at
  `/statutesrules/idconst/Art<ROMAN>/Sect<N>/` and an index per article at `/Art<ROMAN>` (**no
  trailing slash on the index links**). After Georgia and Arkansas this is the first state in six
  where the law was simply readable.
- ⚠ **The article index pages carry the section TITLES**, which is what made the 227-section sweep
  cheap. ▶ **Take a document's parts from its own table of contents**, per `CLAUDE.md` — the
  alternative here would have been 227 page fetches.
- 🔴 **The title extractor was off by one line, and a positive control caught it.** The first
  pass printed `Art.I SECTION 1 :: SECTION 2` for every row and a search for `TERM` across all 227
  returned **nothing**. The control was fixed in advance: *`Art.IV SECTION 1`'s title must contain
  "TERM OF OFFICE"*, because that one had already been read by hand. It did not, so the sweep was
  rebuilt rather than believed. ⚠ **A clean "no competing provision found" is exactly what a broken
  scanner returns**, and on this state that answer was the whole deliverable.

### Basis

`basis = 'statute'` — constitutional, not statutory-by-delegation.
`authority = 'Idaho Const. Art. IV, § 1'`.
`source = 'https://legislature.idaho.gov/statutesrules/idconst/ArtIV/Sect1/ (read 2026-11-23)'`.
`window_end_date` is **NULL** — the day is fixed, so there is no window.

---

## SD — South Dakota · 6 offices · ⚠️ **1 DATED, 5 REFUSED WITH A WINDOW**, 2026-11-23 — and the state splits into two waves

🔴 **One `(state, district_type)` row in the register, two different legal rules, two different
days.** `classifyWave` would raise `date_disagrees` on this body and it would be right. **South
Dakota must ship as two waves.**

| body | offices | start date | basis | authority |
|---|---|---|---|---|
| **Public Utilities Commissioner** (1 of 3 seats) | 1 | ✅ **2027-01-05** | `statute` | `SDCL § 49-1-2` — six years "from the first Tuesday after the first Monday in January following his election" |
| Governor · Secretary of State · Attorney General · Treasurer · Commissioner of School and Public Lands | 5 | 🔴 **REFUSED — window 2027-01-04 → 2027-01-24** | — | `SDCL § 3-1-2` — qualify "on the first Monday of January … **or within twenty days thereafter**" |

### 🔴 The constitution gives a term LENGTH and no day — the fourth state in this pass to do it

**`S.D. Const. Art. IV, § 2` — *Qualification, election, and term*** (Governor and Lieutenant
Governor):

> … They shall be **jointly elected for a term of four years** at a general election held in a
> nonpresidential election year. The candidates having the highest number of votes cast jointly for
> them shall be elected. … **The election procedure shall be as prescribed by law.**

**`S.D. Const. Art. IV, § 7` — *Other executive officers — Powers and duties*:**

> There shall be chosen by the qualified electors of the state at the general election of the
> Governor and every four years thereafter the following constitutional officers: **attorney
> general, secretary of state, auditor, treasurer, and commissioner of school and public lands**,
> who shall severally **hold their offices for a term of four years**. …

🟢 **A full-text sweep of all 30 articles confirms the constitution names no commencement day
for anybody.** Every one of the six occurrences of `commenc*` was read in context and **all six are
term-LIMIT clauses** ("Commencing with the 1992 general election, no person may be elected to more
than two consecutive terms …") or unrelated. `begin on`, `beginning on` and `term of office of`
return **zero**. The one `enter upon` is the oath clause.

🟢 **And the oath clause does not reach these officers.** `Art. III § 8` binds "**Members of the
Legislature and officers thereof**" — officers *of the Legislature*. ⚠ Its own catchline says
"Oath required of legislators **and officers**", which reads broader than the text is; the text
governs. Same finding as Idaho one state earlier, reached the same way.

### 🔴 THE MEMBERSHIP CHECK FIRES: WE DO NOT HOLD THE STATE AUDITOR

`Art. IV § 7` names **five** constitutional officers. We hold **four** of them. There is no South
Dakota `Auditor` office anywhere in `essentials.offices`, and `SDCL` Title 1 **Chapter 1-9 is
"State Auditor"**, so the office is real and current. It is elected "at the general election of the
Governor and every four years thereafter" — the same cycle as the four we do hold — so **it was on
the 2026 ballot and is invisible to this pass**.

▶ This is Shape 3 from the cross-state gap query, inside a state the queue calls complete: the
queue counts winners, an office we do not hold has no winner, and nothing anywhere says so.
**Arkansas taught the habit** — list the officers the instrument names before trusting the row
count — and it earned its keep one state later.

⚠ **Our nine SD `STATE_EXEC` rows vs. what the law says:**

| our rows | 2026 winner? | the law |
|---|---|---|
| Governor | ✅ Larry Rhoden | `Art. IV § 2` |
| **Lieutenant Governor** | 🔴 **none** | `Art. IV § 2` — **jointly elected** with the Governor. A ticket, so the result sits on the Governor's race |
| Secretary of State · Attorney General · Treasurer · Commissioner of School and Public Lands | ✅ × 4 | `Art. IV § 7` |
| *(absent)* **Auditor** | — | 🔴 `Art. IV § 7` names it; we have no such office |
| Public Utilities Commissioner × 3 | ✅ 1 of 3 (Don Haggar) | 🟢 `SDCL § 49-1-2`: "**At each general election there shall be elected one** Public Utilities Commissioner" — so 1 of 3 is CORRECT, not a gap |

🟢 **That last row is the instrument confirming the register's count**, which is the check this
file asks for: the statute that dates the body also says how many seats were up.

### ✅ The one office that can be dated — and it is the one nobody would have looked at

**`SDCL § 49-1-2` — *Election of public utilities commissioners — Qualifications and term of office
— Vacancies*:**

> The Public Utilities Commission shall be comprised of three commissioners. … At each general
> election there shall be elected one Public Utilities Commissioner having the qualifications
> prescribed by law. Each commissioner shall hold office for a term of six years **from the first
> Tuesday after the first Monday in January following his election**, until his successor is elected
> and qualified.

First Monday in January 2027 is the 4th, so **the first Tuesday after it is 2027-01-05**.
🟢 A **formula**, fully determined, with no choice in it — so `basis = 'statute'`.

🔴🔴 **THE PUC IS THE "EXCEPT AS OTHERWISE EXPRESSLY PROVIDED" THAT § 3-1-2 WARNS ABOUT, AND IT
IS ONE DAY OFF.** 2027-01-05 against a window that opens 2027-01-04. A single-date wave covering all
six South Dakota offices would be wrong by one day on one seat, and nothing in the register's row
hints that two rules are in play.

### 🔴 The other five: a 21-day window, because the statute offers a CHOICE

**`SDCL § 3-1-2` — *Time of commencement of term of office*:**

> **Except as otherwise expressly provided**, all state, district, and county officers shall
> **qualify and enter upon the duties of their office on the first Monday of January succeeding
> their election or within twenty days thereafter.** However, a state officer **may** qualify and
> enter upon the duties of office **on the Saturday immediately preceding the second Tuesday of
> January** that succeeds the state officer's election.
>
> *Source: CL 1887, § 1380; … SL 2018 (SS), ch 1, § 1, eff. Dec. 12, 2018.*

| the dates this names, for 2027 | |
|---|---|
| first Monday of January | **2027-01-04** ← window opens |
| … or within twenty days thereafter | **2027-01-24** ← `window_end_date` |
| the Saturday immediately preceding the second Tuesday (2027-01-12) | **2027-01-09** — expressly permitted, and inside the window |

🔴 **Two things make this a refusal rather than a date.** First, the statute names **a range and
an alternative**, not a day — Georgia's problem, with a wider window. Second, it dates
**qualification**, not the term: "shall qualify and enter upon the duties of their office". That is
Nevada's shape, where `NRS 282.010(4)` makes installation mean qualification. ▶ **So the start is
an event inside a window, and the event has not happened.**

⚠ **`SL 2018 (SS), ch 1` is a SPECIAL SESSION act effective 2018-12-12** — weeks before the
January 2019 inauguration, and it is what added the Saturday alternative. **A state that amended
this statute once to move an inauguration can do it again.** Read the current text before the
follow-up, not this block.

### ✅ Discharging "except as otherwise expressly provided" — what was actually read

Each officer's own SDCL chapter was fetched and scanned for `commenc`, `term of office`, `enter
upon`, `qualify`, `inaugurat`, `first Monday`, `first Tuesday` and `four years`:

| chapter | | result |
|---|---|---|
| `1-7` | Governor | 2 hits on `qualify`, **both about succession and bond subsidies** — no term rule |
| `1-8` | Secretary of State | **nothing** |
| `1-9` | State Auditor | **nothing** — and note the chapter exists |
| `1-10` | State Treasurer | **nothing** |
| `1-11` | Attorney General | 3 hits on `commenc`, **all "commences an investigation" / "commence legal action"** — no term rule |
| `5-1` | Department of School and Public Lands | **nothing** |
| `3-5` | Official bonds (cross-referenced by `§ 3-1-1`) | **nothing**, 0 occurrences of `commenc` |

🟢 **Every non-zero hit was read rather than counted.** That is the whole point — "2 hits on
qualify" in the Governor's chapter is exactly what a real exception would look like.

### 🔴 There is no usable control row in South Dakota — and one that looks like one

| row | what it actually is |
|---|---|
| Governor — `term_start = 2025-01-25` (a **Saturday**) | 🔴 **Larry Rhoden's mid-term succession**, when Kristi Noem resigned. It is not a January-formula date and not evidence of one. **Idaho's State Controller trap, two states later.** |
| Secretary of State, Treasurer, Attorney General, Lieutenant Governor, all three PUC seats, Commissioner of School and Public Lands | no `office_terms` row at all |

🟢 **The LEGISLATURE supplies the control instead, and it is a NEGATIVE one.** Roughly a hundred
South Dakota legislator rows carry `term_start = 2025-01-14` — and **2025-01-14 is the second
Tuesday of January 2025**, which is `S.D. Const. Art. III § 7`: *"The Legislature shall meet at the
seat of government on the second Tuesday of January at 12 o'clock m."* 🔴 **That is a THIRD distinct
January date**, and it must not be borrowed for an executive — the Washington error this file
already records, in a state that offers three ways to make it:

| 2027 | who |
|---|---|
| **01-04** → 01-24 | the five constitutional executives (`SDCL § 3-1-2`) |
| **01-05** | Public Utilities Commissioner (`SDCL § 49-1-2`) |
| **01-12** | the Legislature convenes (`Art. III § 7`) — **not an executive date** |

### Sourcing notes

- 🔴🔴 **`sdlegislature.gov` IS AN SPA THAT ANSWERS EVERY UNKNOWN PATH WITH HTTP 200 AND A
  2,253-BYTE SHELL — INCLUDING UNDER `/api/`.** Five guessed endpoint shapes
  (`/api/Statutes/3-1`, `/api/Statutes/Codified_Laws/3-1`, `/api/Statutes/Title/3`,
  `/api/Statutes/Constitution/0N-4`, `/api/Statutes/2030111`) each returned **200**, and every one
  was the same HTML page. ⚠ **`Content-Type` is the only discriminator**: `text/html` = miss,
  `application/json` = hit. This is `CLAUDE.md`'s five-ways-a-200-lies list, on a JSON API.
- 🟢 **The way to learn the API is to drive the page once and read the network log.**
  `browser_navigate` to the real page, then `browser_network_requests` — two calls, and the answer
  was `/api/Statutes/Constitution/**4**`, the bare article number. **Guessing had cost five
  requests and would never have got there**, because the two identifiers the payload itself
  advertises (`StatuteId` 2030111 and `Statute` "0N-4") are both wrong for the URL.
  - `/api/Statutes/Constitution/<article number>` — whole article, every section, in `Html`
  - `/api/Statutes/Statute/<chapter>` (e.g. `3-1`, `49-1`, `1-7`) — whole chapter
  - `/api/Statutes/Constitution` — the 31-article index
  - The whole constitution is **30 fetches and 279 KB of text**.
- 🔴 **South Dakota has NO full-text statute search of its own** — the box on `/Statutes` is
  labelled *"Go To:(1-1-1) or Google Search"*. ▶ That is why the exception sweep was done by
  **reading each officer's chapter** rather than searching for "inauguration": there is nothing to
  search.
- 🔴🔴 **A `grep -oE '.{100}pattern.{180}'` CONTEXT WINDOW SILENTLY DROPS MATCHES, AND IT
  NEARLY MANUFACTURED A FINDING.** `grep -o` returns **non-overlapping** matches per line, and this
  file is one enormous line — so a pattern counted **6 times** printed **1 context**, and
  `enter upon`, counted once, printed **nothing at all**. The conclusion on offer was "the South
  Dakota Constitution contains no commencement provision", which happens to be true and was
  **not yet evidenced**. ▶ **Re-extracted with Python `finditer`, which overlaps freely, and read
  all six.** Count and context must come from the same mechanism, or one of them is lying.

### Basis

**PUC (1 office):** `basis = 'statute'`, `swearing_in_date = 2027-01-05`,
`authority = 'SDCL § 49-1-2'`, `window_end_date` NULL.
**The other five:** nothing written. `window_end_date = 2027-01-24`, authority `SDCL § 3-1-2`,
and a dated follow-up when the inauguration is announced.

---

## NH — New Hampshire · 6 offices · 🔴 **ALL SIX REFUSED, 2026-11-23** — and this is the first refusal in the pass with **no upper bound in law**

| body | offices | start date | state of play |
|---|---|---|---|
| Governor | 1 | 🔴 **REFUSED — window opens 2027-01-06, no end** | the term starts at the **inauguration**, and no instrument names its day |
| Executive Councilor, Districts 1–5 | 5 | 🔴 **REFUSED — same window** | sworn in at the same joint convention, by the Governor, immediately after |

### 🔴 THE NEW HAMPSHIRE CONSTITUTION FIXES NO TERM LENGTH AND NO COMMENCEMENT FOR EITHER OFFICE

This is not "a length and no day", which is Nebraska's, New Mexico's, Arkansas's and South
Dakota's shape. New Hampshire gives **neither**.

**`N.H. Const. pt. 2, art. 42`** says only *"The governor shall be chosen **biennially in the month
of November**"*, and then describes what happens to the ballots. Searching the whole Governor
article for `two years`, `until a successor`, `until his successor` returns **zero**. The single
occurrence of `term of` is in `art. 49`, which refers to *"the governor's term of office"* while
defining a **vacancy** — it uses the term's boundaries without ever setting them.

**`art. 60`** does the same for the Council: the county votes are *"received, sorted, counted,
certified, and returned to the secretary's office … to be by the secretary laid before the senate
and house of representatives"*.

### The one date both articles DO name, and what it is a date OF

> … the secretary shall lay the same before the senate and house of representatives, **on the first
> Wednesday following the first Tuesday of January** to be by them examined, and in case of an
> election by a plurality of votes through the state, **the choice shall be by them declared and
> published**. — `art. 42`

🟢 `art. 3` puts the General Court's own assembly on exactly the same day: *"shall assemble
annually on the **first Wednesday following the first Tuesday in January**"*. The session opens and
the ballots arrive together. **For 2027 that day is 2027-01-06.**

🔴🔴 **BUT THAT IS THE DAY THE VOTES ARE LAID BEFORE THE LEGISLATURE — NOT THE DAY ANYBODY
TAKES OFFICE**, and in New Hampshire the two have fallen on **different days in both of the last
two cycles**. This is `REGISTER.md` step 2's *read what the source's date is a date OF* with the
sharpest edge it has had in this pass: the date is a **filing deadline for the Secretary of State**.

### 🟢 TWO INDEPENDENT CYCLES, FROM THE GENERAL COURT'S OWN JOURNALS

| cycle | `art. 3` / `art. 42` Wednesday | what happened | the joint convention |
|---|---|---|---|
| **2023** | Wed **2023-01-04** — House Journal No. 2 | — | Thu **2023-01-05**, Journal No. 3: vote-count report, **inauguration of Gov. Sununu**, oaths of Councilors Kenney, Warmington, Stevens, Gatsas, Wheeler |
| **2025** | Wed **2025-01-08** — Journal No. 2, which records only *"Rep. Bogert moved that the House adjourn. Motion was adopted."* | — | Thu **2025-01-09**, Journal No. 3: vote-count report, **inauguration of Gov. Ayotte**, oaths of Councilors Kenney, Liot Hill, Stevens, Stephen, Wheeler |

🟢 **The convention does three constitutional acts in one sitting**, and the House's own
resolution says so: *"ready to meet in Joint Convention for the purposes of hearing the report of
the Joint Committee appointed to **compare and count the votes for Governor and Executive
Council**, for the **Inauguration of the Governor** and for the **taking of the oath by the
Executive Council**."*

🟢 **So the pattern is real and it is two for two: the day AFTER the constitutional Wednesday.**
🔴 **And it is custom, not law.** Nothing in the constitution or the RSAs requires the Thursday,
and `art. 66` supplies the mechanism for it to slip further: *"whereas the elections, appointed to
be made by this constitution on the first Wednesday of January biennially, by the two houses of the
legislature, **may not be completed on that day, the said elections may be adjourned from day to
day, until the same be completed**."* ▶ **2027-01-07 is the likely day and must not be written as
the date.**

### What the statutes add, and what they do not

| | |
|---|---|
| `RSA 92:2` **Oath Required** | *"No person chosen or appointed to any public office … shall **exercise such office** or perform any act therein until he shall make and subscribe the oath … as prescribed by part 2, article 84."* 🔴 Gates the **exercise** of the office, not its vesting — and so does `art. 84` itself (*"before he proceeds to execute the duties of his office"*). |
| `RSA 92:1` **Tenure** | ⚠ **Does not apply.** It fixes 5-year terms for *"officers hereafter **appointed by the governor and council**"*. The Governor and the Council are elected. A chapter titled "Tenure and Oath of Office" that does not reach the state's two elected executive bodies is exactly the kind of near-miss worth writing down. |
| `RSA 4-A:2` **Definitions** | 🟢 **The closest thing to an answer New Hampshire has.** *"'Governor-elect' … shall apply to such candidate from the day of election certification by the secretary of state **until the day of his inauguration**."* And `4-A:1` pairs *"the **expiration** of the term of office of a governor"* with *"the **inauguration** of a governor-elect"* as one transfer. ▶ **New Hampshire's own statute treats the inauguration as the boundary — and never names its day.** |

### 🔴 Why this refusal has no `window_end_date`

Every earlier refusal in this pass is bounded on both sides by an instrument: Nevada by
`NRS 282.010(2)`'s "prior to 2027-01-05", Georgia by `O.C.G.A. § 45-12-2`'s noon-Saturday fallback,
Arkansas by a session week, South Dakota by "within twenty days thereafter". **New Hampshire has
nothing of the kind.** `art. 66` is the only text about how long the January business may take, and
it says *from day to day, until the same be completed*.

▶ **So the honest record is a window that opens on 2027-01-06 and does not close.**

🟢 **The follow-up is nevertheless the cheapest in the pass, and that matters more than a
synthetic bound.** The answer will be published by the General Court on the day, in a document
whose URL pattern is already confirmed working for two cycles:

```
https://gc.nh.gov/house/calendars_journals/Journals/2027/HJ%2003%20January%20<d>,%202027.PDF
```

Look for the heading **`OATHS OF OFFICE`** under the `HOUSE JOURNAL NO. 3` day-header. Both prior
cycles put it there, in the same place, with the same wording.

### 🟢 What our own data already holds, and why it is right

All six offices carry `term_start = 2025-01-09`, sourced by `CC_0376` to *New Hampshire House
Journal No. 3, 9 January 2025, "OATHS OF OFFICE"*. ✅ **Re-verified from the PDF, and it survives a
trap the citation does not mention** — see below. The district assignments were taken from the same
Journal, which seats the councilors-elect **by district**, and from `council.nh.gov`.

⚠ **One cycle is one control.** It is the 2023 journal, fetched independently, that makes the
day-after pattern a pattern rather than an anecdote — and even two cycles cannot turn a custom into
a rule.

### Sourcing notes

- 🔴🔴 **THE JOURNAL PDF IS DATED ONE DAY AND OPENS WITH THE PREVIOUS DAY'S JOURNAL.**
  `HJ 03 January 9, 2025.PDF` begins **`HOUSE JOURNAL NO. 2 (Cont'd)` — `Wednesday, January 8,
  2025`**, and only at line 18 does `HOUSE JOURNAL NO. 3` — `Thursday, January 9, 2025` begin. The
  `OATHS OF OFFICE` heading is at line 139, **inside the January 9 portion**, so the recorded date
  is correct — but a reader who grepped for the heading and took the filename's date, or who
  assumed the file contains one day, would have been right **by luck**. ⚠ The same file in 2023 has
  the identical two-day structure. ▶ **Find the day-header that precedes your match**, which is
  `CLAUDE.md`'s *bound a parse by the document's own structure*, applied to a legislative journal.
- 🔴 **`gencourt.state.nh.us` IS DEAD FOR THESE PATHS AND THE DOCUMENTS STILL ADVERTISE IT.**
  Every `gencourt.state.nh.us` URL tried returned **404 with a 1,245-byte body**, while the live
  host is **`gc.nh.gov`** — and the 2025 journal's own masthead prints *"Web Site Address:
  www.gencourt.state.nh.us"*. 🟢 **Our own `office_terms.source` note carried the working host**,
  which is the second time this pass that a previous session's citation was the best lead
  available.
- 🟢 **The constitution is on `www.nh.gov/glance/state-constitution`**, split into **12
  part-pages** (`/executive-power-governor`, `/council`, `/general-court`,
  `/oaths-and-subscriptions-exclusion-offices-etc`, …), and `gc.nh.gov` links to it — the
  Georgia test for "is this the publisher". Plain `curl` with the ordinary header set.
- 🟢 **The RSAs are flat HTML on `gc.nh.gov` and a whole chapter comes in one file:**
  `/rsa/html/NHTOC/NHTOC-<TITLE>.htm` for a title's chapter list, then
  `/rsa/html/<TITLE>/<CH>/<CH>-mrg.htm` for the **merged** chapter. `RSA 92` is 4 KB entire.
- ⚠ **The journals directory 403s but the files are open**: `…/Journals/2023/` returns **403**
  while `…/Journals/2023/HJ%2003%20January%205,%202023.PDF` returns **200**. A listing refusal is
  not a file refusal — four probes found both 2023 journals.

### Basis

**None written. No New Hampshire office is dated.**
Window opens **2027-01-06** (`N.H. Const. pt. 2, arts. 3, 42, 60`); `window_end_date` is **NULL and
genuinely unbounded**. Observed practice, two cycles: **the following day**.

---

## CT — Connecticut · 5 offices in the register, **6 in law** · ✅ sourced 2026-11-23 — **2027-01-06**, and one clause covers the whole state

| body | offices | start date | basis |
|---|---|---|---|
| Governor · Lieutenant Governor · Secretary of the State · Treasurer · Comptroller · Attorney General | 6 | **2027-01-06** | `statute` — `Conn. Const. art. IV, § 2` (codified) |

⚠ **The register counts five** because the Secretary of the State has no 2026 winner. The date
below is the law for all six; only five can be seated. See the gap note at the end.

### The provision

**`Conn. Const. art. IV, § 2` — *Terms of officers*, as codified:**

> Such officers shall hold their respective offices **from the Wednesday following the first Monday
> of the January next succeeding their election** until the Wednesday following the first Monday of
> the fifth January succeeding their election and until their successors are duly qualified.

**`art. IV, § 1` — *State officers, election date*, as codified**, supplies "such officers":

> A general election for **governor, lieutenant-governor, secretary of the state, treasurer,
> comptroller and attorney general** shall be held on the Tuesday after the first Monday of
> November, **1974**, and quadrennially thereafter.

🟢 **Exactly our six offices, and the cycle checks**: 2026 − 1974 = 52, divisible by four, so all
six were on the 2026 ballot. First Monday of January 2027 is the 4th, so **the Wednesday following
it is 2027-01-06**.

🟢 **The start is a calendar date; qualification bounds only the END** ("until … and until their
successors are duly qualified"). So this is Idaho's shape, not Nevada's, and the oath is a separate
event that must not be rendered as the term start.

### 🔴🔴 THE PDF CONTAINS ARTICLE FOURTH TWICE, AND THE SUPERSEDED VERSION COMES FIRST

This is the trap of the state and it would have manufactured a finding.

| where | `art. IV, § 1` names | |
|---|---|---|
| **line 2006** — the 1965 constitution as adopted | governor, lieutenant-governor, secretary of the state, treasurer **and comptroller** — **five** | 🔴 **no attorney general**, and a footnote reading only *"1 Amended by Article I., of the Amendments"* |
| **line 7478** — *CODIFIED CONSTITUTION … INCORPORATING ALL EXTANT AMENDMENTS* | the same five **and attorney general** — **six** | 🟢 *"Said Article I., was adopted on November 25, 1970, and required election of an attorney general at the November 1974 election and quadrennially thereafter."* |

🔴 **Stopping at the first `ARTICLE FOURTH` heading gives a five-officer list and an Attorney
General covered by nothing** — which is precisely the shape of South Dakota's *real* missing-office
finding two states ago. ▶ **The same reading that was correct in South Dakota would have been a
fabrication here**, and the only thing separating them is which copy of the article you landed on.
**Search for the LAST occurrence of an article heading in a document that carries amendments, or
better, for the word CODIFIED.**

🟢 **The two-version structure also pays for itself**: `§ 2` is **byte-identical** in both copies,
which is direct evidence that the term clause itself has never been amended. That is a stronger
check than a missing footnote.

### 🟢 Connecticut is the first state in this pass where the legislature's date CAN be borrowed

Three separate clauses, one day:

| clause | what it dates | 2027 |
|---|---|---|
| `art. III, § 2` | the General Assembly's regular session convenes | **2027-01-06** |
| `art. III, § 10` | **legislators'** terms begin | **2027-01-06** |
| `art. IV, § 2` | **executives'** terms begin | **2027-01-06** |

⚠ **The END dates differ** — legislators run to "the Wednesday after the first Monday of the
**third** January", executives to "the **fifth**" — so the clauses are genuinely distinct and
merely agree on the commencement. 🔴 **This is safe only because three instruments say the same
words, not because three numbers matched.** Washington, Utah and South Dakota each punished the
opposite assumption; Connecticut is the state where the assumption happens to hold, and the file
records *why*.

### 🟢 The control

| office | `office_terms.term_start` | the formula |
|---|---|---|
| Governor (Lamont) | **2019-01-09** | first Monday of January 2019 was the 7th → Wednesday following = **the 9th** ✅ |

⚠ **One control, and the other five offices carry no `office_terms` row at all.** It counts for
more than Georgia's did, because `art. IV § 2` names a **formula** with one answer per cycle rather
than a choice — the Idaho distinction. But one row is one row.

🟢 Forward check: the clause's own end date for this term is "the Wednesday following the first
Monday of the fifth January", which computes to **2031-01-08** — consistent with a four-year term
beginning 2027-01-06.

### 🔴 THE GAP: the Secretary of the State has NO RACE ROW, EVER

| office | 2026 race rows | candidate rows | latest race ever |
|---|---|---|---|
| Governor, Lt. Governor, Treasurer, Comptroller, Attorney General | 1 each | 2–3 each | 2026-11-03 |
| **Secretary of the State** | **0** | **0** | **NULL** |

`art. IV § 1` puts it on the same quadrennial ballot as the other five, and it is a seat we hold.
🔴 **This is Shape 2 from the cross-state gap query, inside a state the queue calls complete** —
and it is the second such find in four states, after South Dakota's State Auditor. The difference
is instructive: **South Dakota is missing the OFFICE, Connecticut is missing the RACE.** Both
present identically in the queue, as a state with one fewer office than the law describes.

▶ The date above covers it the moment a result exists. Nothing else here is blocked.

### Sourcing notes

- 🔴🔴 **`www.cga.ct.gov` SERVES A VALID CERTIFICATE WITH A MISSING INTERMEDIATE — `curl` REFUSES
  AND A BROWSER DOES NOT.** `curl` exits **60**, *"unable to get local issuer certificate"*;
  `openssl s_client` says **"Verify return code: 21 (unable to verify the first certificate)"** and
  shows the leaf is `CN=*.cga.ct.gov` issued by `Go Daddy Secure Certificate Authority - G2`, which
  the server never sends. Browsers repair this silently by fetching the issuer named in the
  certificate; `curl` does not.
  - 🟢 **The fix, and it is reusable**: fetch the named intermediate
    (`http://certs.godaddy.com/repository/gdig2.crt` — **follow the redirect**, it 301s to https
    and is **DER**, not PEM), convert it, concatenate it onto the system bundle
    (`/mingw64/etc/ssl/certs/ca-bundle.crt`) and pass the result as `--cacert`.
  - 🟢 **Controlled**: the *unpatched* bundle was re-run against the same URL and **still failed**,
    then the patched one returned **200, `application/pdf`, 572,979 bytes**. Watching the control
    fail first is what distinguishes "my fix worked" from "the server recovered".
  - ▶ **This is a host-failure mode the escalation ladder did not have.** It is **not** a WAF, not a
    TLS-fingerprint block and not a thin request — sending more headers does nothing. A browser is
    the right escalation **for a reason unrelated to request shape**, and the better answer is to
    repair trust and keep using `curl`.
- 🔴 **`portal.ct.gov` returns HTTP 200 with a page titled "404 Error Page"** for a path that does
  not exist — a textbook soft 404, and the sixth distinct way a 200 has lied in this pass.
- ⚠ **The General Assembly's own path is `constitutions.asp`, PLURAL.** `constitution.asp`
  (singular) is a real IIS 404. The page offers *Constitution of the State of Connecticut —
  **Revised to January 1, 2025*** at
  `/asp/Content/constitutions/Constitution_State_CT.pdf`, 573 KB, 8,325 lines of extracted text.
- 🟢 **Connecticut has a real statute search** (`search.cga.state.ct.us`), unlike South Dakota.
  It was not needed: the constitution answers the question outright.

### Basis

`basis = 'statute'` — constitutional.
`authority = 'Conn. Const. art. IV, § 2 (codified, incorporating Amendment Art. I)'`.
`source = 'https://www.cga.ct.gov/asp/Content/constitutions/Constitution_State_CT.pdf (Revised to January 1, 2025), read 2026-11-23'`.
`window_end_date` **NULL** — the day is fixed.
⚠ **Five of the six are seatable**; the Secretary of the State has no result to seat.

---

## HI — Hawaii · 5 offices · ✅ sourced 2026-11-23 — ✅✅ **4 OF 5 WRITTEN 2026-11-23; THE AT-LARGE BLOCK IS STILL RULING A**

✅✅ **WRITTEN 2026-11-23 BY `CC_0469` → `CC_0470` → `CC_0471`** (after `CC_0472` widened a check
constraint that forbade a term beginning on election day). The Maui and Oahu trustees are seated
from 2026-11-03; the Governor and Lieutenant Governor are scheduled for 2026-12-07 and **Sylvia
Luke still holds the seat until that morning**, confirmed through the deployed API.
🔴 **THE AT-LARGE BLOCK IS STILL REFUSED** — 3 winners, 4 offices, Ruling A. It is now the
**first row of the queue**, because it is the only dated body left and its date is past.

🔴🔴 **Hawaii held both the nearest future deadline in the pass and a second deadline that had
already gone by.**

| body | offices | winners | start date | basis | authority |
|---|---|---|---|---|---|
| **Office of Hawaiian Affairs** — Maui Resident Trustee, Oahu Resident Trustee | 2 | 2 | 🔴 **2026-11-03** — **20 DAYS PAST** | `statute` | `HRS § 13D-5` |
| **Office of Hawaiian Affairs** — At-large Trustee | 1 row, **4 offices** | **3** | 🔴 **2026-11-03** — past, **but Ruling A blocks seating** | `statute` | `HRS § 13D-5` |
| **Governor · Lieutenant Governor** | 2 | 2 | ⏰ **2026-12-07** — **14 days away** | `statute` | `Haw. Const. art. V, §§ 1, 2` |

### ⏰ The Governor and Lieutenant Governor — 2026-12-07

**`Haw. Const. art. V, § 1` — *Establishment of the Executive*:**

> The executive power of the State shall be vested in a governor. … **The term of office of the
> governor shall begin at noon on the first Monday in December next following the governor's
> election** and end at noon on the first Monday in December, four years thereafter.

**`art. V, § 2` — *Lieutenant Governor*:**

> There shall be a lieutenant governor … The lieutenant governor shall be elected at the same time,
> **for the same term** and in the same manner as the governor; provided that the votes cast in the
> general election for the nominee for governor shall be deemed cast for the nominee for lieutenant
> governor of the same political party.

The first Monday in December 2026 is **2026-12-07**. 🟢 **"For the same term" carries the
Lieutenant Governor without a second clause** — the Georgia pattern, where the subordinate officers
ride on the Governor's own provision.

⚠ **The constitution says "at noon" and `office_swearing_in.swearing_in_date` is a DATE.** The hour
is not representable and does not need to be: the column records the day a term begins. Say so in
the migration header rather than silently dropping half a sentence.

🟢 **Control, and it is exact.** Governor Green's `office_terms.term_start` is **2022-12-05** —
the first Monday in December 2022. One row, but `art. V § 1` names a **formula**, not a choice, so
it counts (the Idaho distinction).

### 🔴🔴 THE OHA TRUSTEES' TERMS BEGAN ON ELECTION DAY ITSELF

**`HRS § 13D-5` — *Term of office; vacancies*:**

> The term of office of members of the board shall be four years **beginning on the day of the
> general election at which they are elected**, or if elected at a primary election, on the day of
> the general election immediately following the primary election at which they are elected, and
> **ending on the day of the second general election after their election**.

🔴 **So the start date is 2026-11-03 — the election itself.** Not a January date, not a swearing
in, not a canvass. This is the first body in the pass whose term begins **before the result is even
certified**, and the only one so far whose date is in the past at the moment of sourcing.

⚠ **The second limb matters too.** `HRS § 13D-4(e)(3)` lets a primary candidate who takes more
than fifty per cent be "declared … duly and legally elected" without appearing on the general
ballot — and § 13D-5 still starts that person's term **on the day of the following general
election**. ▶ **Both routes land on 2026-11-03 for this cycle**, so the distinction changes nothing
here, but it would in a state where the two dates differ.

🟢 **"Ending on the day of the second general election after their election"** is a four-year term
expressed in elections rather than years, and it closes the arithmetic: 2026-11-03 → the 2030
general election.

### 🟢 The board's composition checks out, and the statute says how many were up

**`HRS § 13D-1`:** *"The board of trustees shall be composed of **nine members** elected at-large by
qualified voters in the State. Of the nine members to be elected one shall reside on the island of
Hawaii; one … Maui; and one … Molokai; one … Kauai; and one … Oahu."*

| | |
|---|---|
| nine seats = **5 island-residency + 4 at-large** | ✅ we hold exactly **9 OHA office rows**, 4 at-large and 5 island |
| `§ 13D-4(f)`: *"Any election with **three available seats without a residency requirement**"* | 🟢 **the statute itself says three at-large seats were up** — and our data has **3 at-large winners**. The instrument that dates the body confirms the count. |

### 🔴 Ruling A blocks the at-large block, and the statute explains why

Our four at-large office rows carry **3 winners on one row** — Brickwood Galuteria, Ikaika Anderson
and Keoni Souza — and nothing in the data says **which three of the four seats** they take. That is
the equality gate failing exactly as `REGISTER.md` describes, and this body is already named in
`SOURCING.md`'s *"Four bodies cannot be seated from our data at all"* table.

🟢 **Sourcing has now made that refusal sharper rather than leaving it vague**: the gap is one
seat, the fourth at-large trustee whose term runs to the 2028 general election. ▶ **The fix is
`CLAUDE.md`'s existing rule** — attach the race to the office of the member actually leaving — and
the document that settles it is OHA's own published roster of trustees and term expirations.
**That is step-3 work; the date is not in doubt.**

| OHA seat | 2026 winner | seatable once dated? |
|---|---|---|
| Maui Resident Trustee | Carmen Hulu Lindsey | ✅ yes |
| Oahu Resident Trustee | Kalei Akaka | ✅ yes |
| At-large × 4 | 3 winners on one row | 🔴 **no — Ruling A** |
| Hawaii Island, Kauai and Niihau, Molokai and Lanai | none | ✅ correct — not up this cycle |

### 🔴 What this means for the programme

| | |
|---|---|
| **2026-11-03** | OHA — **20 days past**. Two trustees are seatable the moment a row is written |
| **2026-12-07** | Governor and Lieutenant Governor — **14 days away**, the nearest FUTURE deadline anywhere in this pass |

⚠ Hawaii joins **Nevada** as a state whose date has already arrived, and unlike Nevada its
executive pair is about to. 🔴 **Nothing in this pass has been written**, so both are currently
late or about to be.

### Sourcing notes

- 🟢 **`lrb.hawaii.gov/constitution/` serves the ENTIRE constitution on one page** — 152,682
  characters of text to a plain header set. The Legislative Reference Bureau is the state's own
  publisher. ⚠ The article links are **in-page anchors** (`#articlev`), not separate URLs, so a
  link-following crawler finds nothing while the text is already in hand.
- 🟢 **The HRS are flat HTML, one file per section**, at
  `capitol.hawaii.gov/hrscurrent/Vol01_Ch0001-0042F/HRS00<CH>/HRS_00<CH>-<NNNN>.htm`, and the
  chapter directory lists its sections. `13D` has exactly five.
- 🔴 **Those files are UTF-8 **with a BOM**, and Python read them as `utf-8` keeps the `\ufeff`,
  which then kills `print` on a cp1252 console.** Read with `encoding='utf-8-sig'` and set
  `PYTHONIOENCODING=utf-8`. ⚠ This is a cousin of the Nevada roster bug already recorded here —
  **an encoding fault on the way IN or the way OUT can masquerade as missing content**.
- ⚠ `capitol.hawaii.gov/docs/HawaiiStateConstitution.pdf` **404s** with a 12 KB HTML body; the
  constitution is not there. Use the LRB.

### Basis

**OHA (5 winners across 3 office rows):** `basis = 'statute'`, `swearing_in_date = 2026-11-03`,
`authority = 'HRS § 13D-5'`, `window_end_date` NULL.
**Governor and Lieutenant Governor:** `basis = 'statute'`, `swearing_in_date = 2026-12-07`,
`authority = 'Haw. Const. art. V, §§ 1, 2'`, `window_end_date` NULL.
🔴 **Two dates in one `(state, district_type)` row — `classifyWave` will raise `date_disagrees`.
Hawaii ships as two waves, like South Dakota.**
