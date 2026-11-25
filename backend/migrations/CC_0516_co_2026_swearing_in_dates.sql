-- CC_0516 — Colorado: the start dates for the 19 state offices covered by the 2026-11-03 election.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- TWO DAYS, FIVE BODIES, FOUR INSTRUMENTS — AND THE FIRST `published` BASIS IN THIS PASS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-11 (Mon)  State House Districts 14, 16, 17, 18, 20, 56        (6)
--                     State Senate Districts 9, 11, 35                   (3)
--                                                              (9)  Colo. Const. Art. V, § 7
--                                                                   + C.R.S. § 2-2-303.5(3)
--                                                                   + HOUSE JOINT RESOLUTION 26-1031
--   2027-01-12 (Tue)  Governor · Secretary of State · Treasurer ·
--                     Attorney General                                   (4)
--                     Lieutenant Governor  (DATED, NOT SEATED)           (1)
--                                                              (5)  Colo. Const. Art. IV, § 1(1)
--                     State Board of Education Districts 1, 7            (2)  C.R.S. § 22-2-105(1)
--                     University of Colorado Regent, Districts 2, 6, 7   (3)  C.R.S. § 23-20-105(2)
--                                                             (10)
--
-- Sourced 2026-11-22 and RE-READ IN FULL 2026-11-25; the write-up is in
-- backend/data/state-seating-2026/DATES.md § CO. This file writes the dates and seats nobody:
-- CC_0517 seats the nine on 2027-01-11, CC_0518 seats the nine on 2027-01-12.
--
-- 🔴🔴 **NINETEEN OFFICES, NOT EIGHTEEN, AND THE NINETEENTH IS THE LIEUTENANT GOVERNOR.** The
--   ledger says "⚠ Only four executives are pending and that is correct — Colorado's Lieutenant
--   Governor runs on the Governor's ticket (Art. IV, § 3), so it is the ticket case, not a gap."
--   **The ticket fact is right and the conclusion is wrong.** Measured in production 2026-11-25:
--   we hold a `Colorado Lieutenant Governor` office row, a 2026-11-03 race row on it, and
--   **SEVEN candidates, every one of whom carries `result IS NULL`** — not `advanced`, not
--   `lost`, blank. The pending set is four because a RESULT is missing, not because the office
--   has no contest. ▶ Art. IV § 1(1) names the Lieutenant Governor in the same sentence as the
--   other four and gives it the same commencement, so **this file dates it and CC_0518 does not
--   seat it.** That is Arizona's Corporation Commission shape — dated, unseatable — and the row
--   is a queue entry rather than an acceptance.
--   ⚠ **And the ticket pairing is not in our data either.** Art. IV § 3 makes the Governor and
--   Lieutenant Governor "chosen jointly by the casting by each voter of a single vote applicable
--   to both offices", so in law the winner is determined entirely by the Governor's result. But
--   no column links a Lieutenant Governor candidate to a Governor candidate: both races hold
--   seven candidates and `external_id` is NULL on all fourteen. **Equal counts are not a
--   pairing** — Texas's *a count is not a name*, in the one place where the law supplies the
--   answer and the data cannot express it. Seating from an inferred pairing is what this pass
--   refuses.
--
-- 🔴🔴 **THE LEDGER'S CITATION FOR THE STATE BOARD OF EDUCATION IS WRONG BY ONE SECTION.**
--   DATES.md attributes the five "second Tuesday in January" anchors to **C.R.S. § 22-2-104(1)**.
--   § 22-2-104 is **"Offices and positions - nature"** — which positions in the department are
--   exempt from the state personnel system — and contains **no date of any kind**. Every word
--   quoted is in **§ 22-2-105(1), "State board of education - composition"**, verbatim, including
--   all five anchors (1983, 1985, 1987, 2003, 2023). 🔴 The quote was right and the section
--   number was not, and **the day it produces is unaffected**, so no count, digest or view can
--   see it — CLAUDE.md's *a citation can be right about the date and wrong about the law*, which
--   is now the third state running to supply an instance (Nebraska, Texas, Colorado).
--
-- 🟢 **NO PEOPLE FILE, AND COLORADO IS THE EIGHTH SUCH STATE** (after AZ, AL, ID, NM, NE, CT, TX).
--   All 18 winner rows carry a politician_id, all 18 are `is_active`, and **none collides with
--   any other row on (full_name) OR on (first_name, last_name)** — swept across the whole
--   `politicians` table, not read off the register's "no record" column, which counts race rows.
--   ⚠ Three names differ between the race row and the person row — "Tony Exum Sr"/"Tony Exum",
--   "Amy T Paschal"/"Amy Paschal", and our "Ilana Spiegel" against the Regents' own
--   "Ilana Dubin Spiegel". All three are seat-anchored (a re-election of the sitting holder, or
--   District 6), which is the rule: a name match is not an identity.
--
-- 🟢 **NO RULING A.** All 18 pending races are single-seat with exactly one winner, so no office
--   row carries two winners and the winner-to-seat mapping is in the data throughout. ⚠ Both
--   boards ARE staggered — Arizona's Corporation Commission and Texas's Railroad Commission shape
--   — so the selection is taken from `office_pending_winner` and never by title; see P6 and P7.
--
-- 🔴 **SEVEN OF THE EIGHTEEN SEATS CHANGE HANDS, AND THREE OF THEM FORM A CHAIN.** Phil Weiser
--   leaves the Attorney General's office for the Governorship, Jena Griswold leaves the Secretary
--   of State's office for his, and Amanda Gonzalez takes hers — **three links, all on one day, all
--   three seats inside CC_0518**, so the chain resolves itself. That is New Mexico's Garcia
--   Richard case two links deeper, and it is the longest in this pass.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- GROUP A — THE TERM BEGINS ON AN EVENT, AND THE EVENT'S DAY IS DESIGNATED BY A DOCUMENT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Colo. Const. Art. V, § 7 — General assembly - shall meet when - term of members - committees**,
-- read in full from the constitution as printed in the Colorado Revised Statutes 2024, Title 00:
--
--   "The general assembly shall meet in regular session at 10 a. m. NO LATER THAN the second
--    Wednesday of January of each year. … The term of service of the members of the general
--    assembly SHALL BEGIN ON THE CONVENING of the first regular session of the general assembly
--    next after their election. The committees of the general assembly, UNLESS OTHERWISE PROVIDED
--    BY THE GENERAL ASSEMBLY, shall expire on the convening of the first regular session after a
--    general election. Regular sessions of the general assembly shall not exceed one hundred
--    twenty calendar days."
--
-- 🔴🔴 **THE ESCAPE HATCH IN THIS SECTION BELONGS TO A DIFFERENT SENTENCE, AND THAT IS A NEW
--   TRAP.** "Unless otherwise provided by the general assembly" governs the expiry of
--   **committees**, not the term of **members**. The term sentence carries no residual at all.
--   ▶ Oregon's lesson was *read the clause to its full stop, the hatch is at the end*; Colorado is
--   the inverse — **there is a hatch three words from the term clause and it is not the term
--   clause's hatch.** A reader grepping the section for "unless" finds one and attaches it to the
--   wrong subject. This is the fourth clause in the pass with no hatch on the term itself, after
--   Connecticut's Art. IV § 2, Texas's § 601.003 and Colorado's own Art. IV § 1 below.
--
-- 🟢 **AND THE TERM CLAUSE DOES NOT NEED A HATCH, BECAUSE IT NAMES AN EVENT RATHER THAN A DAY.**
--   The term begins "on the convening"; the convening must happen "no later than" the second
--   Wednesday. **"No later than" is a deadline, not a date** — it is the constitution authorising
--   an earlier day, which is what C.R.S. § 2-2-303.5 then supplies the machinery for. So the chain
--   is constitution → statute → resolution, three instruments, each naming the one above it.
--
-- **C.R.S. § 2-2-303.5 — Time for convening regular sessions - procedure for convening earlier**,
-- read in full from Colorado Revised Statutes 2024, Title 02:
--
--   (1) The provisions of this section are enacted IN FURTHERANCE OF SECTION 7 OF ARTICLE V of
--       the state constitution, which provides that the general assembly shall meet in regular
--       session at 10 a.m. no later than the second Wednesday of January of each year.
--   (2) UNLESS A DIFFERENT DATE IS ESTABLISHED in accordance with subsection (3) or (4) of this
--       section, the general assembly shall meet in regular session at 10 a.m. on the second
--       Wednesday of January of each year.
--   (3) The general assembly, ACTING BY JOINT RESOLUTION, may designate the date of convening the
--       next regular session of the general assembly. Any date designated pursuant to this
--       subsection (3) shall be a date ON OR AFTER JANUARY 1 BUT PRIOR TO the date specified in
--       subsection (2) of this section.
--   (4) In the event the general assembly DOES NOT ACT DURING THE REGULAR SESSION pursuant to
--       subsection (3) of this section, the executive committee of the legislative council, after
--       the regular session but NO LATER THAN NOVEMBER 1, may designate the date of convening the
--       next regular session … [the same window applies]
--
-- 🔴 **A CORRECTION TO THE LEDGER'S CLOSURE ARGUMENT, WHICH IS RIGHT FOR A REASON IT DOES NOT
--   GIVE.** DATES.md says "subsection (3) requires action during a regular session". **(3) says no
--   such thing** — it names no time limit at all. It is **(4)**'s opening words, "in the event the
--   general assembly does not act *during the regular session* pursuant to subsection (3)", that
--   confine (3) to the session. A reader checking (3) alone would not find the limit.
--   🟢 **And (4) was never reachable in this cycle on its own terms**: the General Assembly DID act
--   under (3), so (4)'s condition was never satisfied — quite apart from its 2026-11-01 deadline,
--   which also passed.
--
-- 🟢🟢 **AND THERE IS A STRONGER FACT THAN EITHER CLOSURE ARGUMENT, BECAUSE IT BOUNDS THE ERROR
--   INSTEAD OF ARGUING ABOUT IT: (3) AND (4) BOTH CONFINE ANY DESIGNATED DAY TO "ON OR AFTER
--   JANUARY 1 BUT PRIOR TO" THE SECOND WEDNESDAY.** For 2027 that window is
--   **[2027-01-01 .. 2027-01-12]** and the default itself is 2027-01-13. So **no lawful
--   designation, past or future, can put this term outside a twelve-day window**, and the only day
--   any rival rule produces outside it is the default. Asserted at 3a.
--
-- **HOUSE JOINT RESOLUTION 26-1031**, the signed enrolled act, read in full 2026-11-22 and re-read
-- 2026-11-25 (265,766 bytes, sha256
-- 103b34fc3672c61bca0af02a25bfde4958bb5243f991dbbaf9342635f0a50256 — byte-identical to the copy
-- the ledger recorded three days earlier):
--
--   "CONCERNING THE DESIGNATION OF THE CONVENING DATE FOR THE FIRST REGULAR SESSION OF THE
--    SEVENTY-SIXTH GENERAL ASSEMBLY …
--    WHEREAS, Section 2-2-303.5 (3), Colorado Revised Statutes, authorizes the General Assembly to
--    designate the convening date for regular sessions by joint resolution; now, therefore, …
--    That, pursuant to section 2-2-303.5 (3), Colorado Revised Statutes, the General Assembly
--    designates MONDAY, JANUARY 11, 2027, as the convening date for the First Regular Session of
--    the Seventy-sixth General Assembly."
--
-- 🟢🟢 **THE RESOLUTION CARRIES ITS OWN POSITIVE CONTROL, AND THE LEDGER USED ONE CELL OF IT.**
--   DATES.md quotes a single line of the attached deadline schedule ("1ST DAY (MONDAY 01/11/27)").
--   The schedule prints **28 (ordinal day, weekday, calendar date) triples** — from "5 DAYS PRIOR
--   TO 1ST DAY (WEDNESDAY 01/06/27)" through "120TH DAY (MONDAY 05/10/27)". Computed from a 1st
--   day of **Monday 2027-01-11, all 28 agree**; computed from the statutory default of Wednesday
--   2027-01-13, **0 of 28 agree**. ▶ A transcription error in the convening date would have to be
--   accompanied by twenty-eight consistent errors in the schedule. This control lives **entirely
--   inside the document** and touches none of our data, which is what makes it worth having for a
--   `published` basis.
--
-- 🔴🔴 **BASIS IS `published`, AND IT IS THE FIRST IN THE PASS. THE STATUTORY DEFAULT WOULD HAVE
--   BEEN TWO DAYS WRONG** — 2027-01-13 — **which is the Maryland General Assembly's live day, 178
--   rows.** A file written from "the second Wednesday" produces a date that is not merely wrong
--   but lands inside another state's cluster. 🟢 `published` may seat (the seating files' P4
--   accepts `statute` or `published`); only `estimated` may not.
--
-- 🔴🔴🔴 **AND THE RIVAL THAT SURVIVES OUR OWN DATA GIVES THE RIGHT ANSWER IN 2027 FOR THE WRONG
--   REASON — NEBRASKA'S TRAP, SITTING ON THE SAME CALENDAR SQUARE.** Nine rules were computed from
--   what each one counts FROM, over five cycles of our own `office_terms` (assertion 3d):
--
--       2 / 5   the second Wednesday  (the STATUTORY DEFAULT, § 2-2-303.5(2)) — 2021, 2025
--       2 / 5   the second Monday                                            — 2023, 2027
--       0 / 5   first Wednesday · first Monday · second Tuesday · first Tuesday · third Monday ·
--               "first Monday after the second Tuesday" (Alabama's) · January 1st (Utah's)
--
--   **No rule reproduces more than two of the five cycles, and that is itself the evidence that the
--   day is designated rather than computed.** But "the second Monday" is right in **2023 and
--   2027** — so in the cycle this file writes it is indistinguishable from the truth. 🔴 **And
--   2027-01-11 already carries 193 rows under two `rule_id`s that literally contain the words
--   `second-monday-january`**: `or-const-art4-s4-second-monday-january` (75) and
--   `wa-rcw-44-04-021-second-monday-january` (118). Arizona's warning was that *a rival's rule_id
--   may even share its words*; Colorado's rival shares the words, the day **and** the year.
--   ▶ **Only a document refuses it, and the documents are below.**
--
-- 🟢🟢 **THE SECOND AND THIRD CYCLES CAME FROM DOCUMENTS OF THE SAME KIND, AND EACH REPRODUCES OUR
--   OWN DATA EXACTLY.** The designation mechanism was checked in the two previous gubernatorial
--   cycles, both fetched and read 2026-11-25:
--
--     • **HOUSE JOINT RESOLUTION 18-1021** (123,841 bytes) — "the General Assembly designates
--       **FRIDAY, JANUARY 4, 2019**, as the convening date for the First Regular Session of the
--       Seventy-second General Assembly." Our `office_terms` carries **6 Colorado legislative
--       terms starting 2019-01-04**.
--     • **HOUSE JOINT RESOLUTION 22-1025** (158,893 bytes) — "the General Assembly designates
--       **MONDAY, JANUARY 9, 2023**, as the convening date for the First Regular Session of the
--       Seventy-fourth General Assembly." Our `office_terms` carries **37 Colorado legislative
--       terms starting 2023-01-09**.
--
--   🟢🟢 **2019 IS THE CYCLE THAT DOES THE WORK, AND IT IS A FRIDAY.** No ordinal-weekday rule in
--   the Monday/Tuesday/Wednesday family can produce a Friday, so **2019 alone refutes every
--   weekday rival at once**, the second Monday included; 2023 refutes the statutory default; and
--   2021 and 2025 show the default being *used* when no resolution displaced it. Three
--   resolutions, three cycles, and the only rule that fits all five is "whatever the General
--   Assembly designated".
--
-- 🟢🟢 **AND A FOURTH DOCUMENT EXPLAINS *WHY* THE DAY MOVES IN GUBERNATORIAL YEARS, WHICH THE
--   LEDGER ASSERTS WITHOUT A SOURCE.** **HOUSE JOINT RESOLUTION 23-1001** (83,224 bytes, read
--   2026-11-25) resolves "That a Joint Session … be held in the House Chambers on **Monday,
--   January 9, 2023**, at a time to be announced by both houses **upon completion of
--   organizational procedures**, for the purpose of **canvassing the votes for certain officials**
--   at the election held Tuesday, November 8, 2022." That is Art. IV § 3's canvass — which requires
--   the Speaker to open and publish the returns for Governor and Lieutenant Governor "immediately,
--   upon the organization of the house, and before proceeding to other business" — happening **on
--   the convening day itself**. ▶ The legislature must therefore convene **before** the executives'
--   terms begin, which is asserted at 3c as a relation between this file's own two groups and which
--   holds in all three gubernatorial cycles (4 days apart in 2019, 1 in 2023, 1 in 2027).
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- GROUP B — ONE ANCHOR-YEAR CLAUSE FOR FIVE OFFICERS, AND TWO STATUTES FOR THE TWO BOARDS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Colo. Const. Art. IV, § 1(1) — Officers - terms of office**, read in full:
--
--   "The executive department shall include the governor, LIEUTENANT GOVERNOR, secretary of state,
--    state treasurer, and attorney general, each of whom shall hold his office for the term of four
--    years, COMMENCING ON THE SECOND TUESDAY OF JANUARY IN THE YEAR 1967, AND EACH FOURTH YEAR
--    THEREAFTER. They shall perform such duties as are prescribed by this constitution or by law."
--
-- 🟢🟢 **NO ESCAPE HATCH, AND ITS TAIL IS A TERM LIMIT — MARYLAND'S SHAPE, REACHED AGAIN.** The
--   sentence ends at "each fourth year thereafter"; the next sentence is about duties, and § 1(2)
--   is a two-consecutive-term limit. ⚠ Md. Art. II § 1 ends the same way, which is why `CC_0499`
--   said so out loud rather than leaving the reader to re-read it. Said out loud here too.
--
-- 🟢 **AN ANCHOR-YEAR RULE, WHICH IS ARIZONA'S SHAPE** — a specific past date plus a term length,
--   with the recurrence implied. 1967 + 4n: 2027 − 1967 = 60 = 4 × 15, so 2027 is on the cycle
--   (asserted at 3b). The second Tuesday of January 2027 is **2027-01-12**.
--
-- 🟢🟢 **AND THE ONE DATED COLORADO EXECUTIVE TERM IN THE DATABASE REPRODUCES IT EXACTLY.**
--   `office_terms` carries Jared Polis's Governorship starting **2019-01-08**, and the second
--   Tuesday of January 2019 is 2019-01-08. One row, and it is the only dated state executive term
--   Colorado has — Connecticut's and Texas's position. Assertion 3e asserts the count IS exactly
--   one, so the control cannot go vacuous unnoticed, and that the row did not move.
--
-- **C.R.S. § 22-2-105(1) — State board of education - composition** (NOT § 22-2-104; see above),
-- read in full from Colorado Revised Statutes 2024, Title 22. Five independent anchors, every one
-- of them on the same weekday-of-month:
--
--   "… all such terms commencing on the SECOND TUESDAY IN JANUARY 1983 … all such terms commencing
--    on the SECOND TUESDAY IN JANUARY 1985 … all such terms commencing on the SECOND TUESDAY IN
--    JANUARY 1987 … a six-year term commencing on the SECOND TUESDAY IN JANUARY 2003 … both terms
--    commencing on the SECOND TUESDAY IN JANUARY 2023."
--   "(3) Except as provided in subsection (1) of this section, members shall be elected for terms
--    of six years."
--
-- 🟢 Colo. Const. Art. IX, § 1(1) leaves the terms to be elected "in such manner and for such terms
--   as may be by law prescribed", and fixes the membership at one member per congressional district
--   plus one at large when the district count is even — Colorado has eight, so **nine**.
--
-- **C.R.S. § 23-20-105(2)**, read in full from Colorado Revised Statutes 2024, Title 23 — and this
-- is **the weakest citation in Colorado**, flagged by the ledger and flagged again here rather than
-- smoothed over. Colo. Const. Art. IX, § 12 gives "nine regents … elected in the manner prescribed
-- by law for terms of six years each"; **§ 23-20-102 prescribes the manner and the cycle and names
-- no commencement at all.** The only commencement evidence is a **1973 transitional provision**
-- about filling vacancies:
--
--   "(2) The governor shall appoint, effective July 1, 1973, three persons to fill vacancies on the
--    board of regents … one such appointment to be of a qualified elector of the state for a term
--    EXPIRING ON THE SECOND TUESDAY IN JANUARY, 1975, one … EXPIRING ON THE SECOND TUESDAY IN
--    JANUARY, 1977, and one … EXPIRING ON THE SECOND TUESDAY IN JANUARY, 1979. Their respective
--    successors in office shall be elected from the state at large, as provided in section
--    23-20-102."
--
-- 🔴 **That is transitional text, which is exactly what made Utah's Board of Education a REFUSAL.
--   The difference, stated so the inconsistency is not silent:** in Utah the transitional dates
--   pointed at a boundary **different** from the legislature's, so they were evidence *against*
--   borrowing. In Colorado they point at the **same** boundary as the executives (a current
--   constitutional clause) and the State Board of Education (a current statute with five anchors),
--   so they corroborate rather than contradict. The Regents are therefore dated, not refused.
--
-- 🔴 **AND THE SWEEP THE LEDGER'S OWN FLAG INVITED CAME BACK EMPTY, WHICH IS ITSELF THE FINDING.**
--   New Mexico's flagged weakness was repaired by a general constitutional commencement clause
--   (Art. XX § 3(A), "every state, county or district officer"). **Colorado has no such clause.**
--   All 29 articles were scanned for commencement language and the constitution contains exactly
--   **two** term-commencement provisions — Art. IV § 1(1) and Art. V § 7, the two this file is
--   built on. Every other hit is eligibility ("qualifications"), the Governor's message ("the
--   commencement of each session"), or a criminal-trial provision. ▶ So the Regents' day rests on
--   statute alone and the transitional provision is the whole of it. **A sweep that fails to repair
--   a weak claim is still a measurement, and it is recorded beside the ones that passed.**
--
-- 🟢🟢 **BUT THE SWEEP FOUND SOMETHING THE LEDGER DID NOT HAVE, AND IT ANSWERS STEP 2's OATH
--   QUESTION FOR THE WHOLE STATE IN ONE INSTRUMENT.** § 23-20-103 says only "The members of the
--   board of regents shall take an oath or affirmation **in accordance with section 24-12-101**" —
--   a pointer the ledger never followed. **C.R.S. § 24-12-101** provides: "When a person is
--   required to take an oath or affirmation **BEFORE THE PERSON ENTERS UPON THE DISCHARGE** of a
--   public office or position …"; its form recites "the office … **upon which I am about to
--   enter**"; and (2)(c) requires it "Taken, signed, administered, and filed … **before the person
--   enters upon the public office or position**". **Colo. Const. Art. XII, § 8** says the same
--   constitutionally: "Every civil officer … shall, **before he enters upon the duties of his
--   office**, take and subscribe an oath". ▶ **The oath is a PRECONDITION to the term, not the
--   event that starts it** — the opposite of Nevada's qualification states — and because
--   § 24-12-101 and Art. XII § 8 are general, they settle the question for all five bodies at
--   once, including the one body whose own statute names no commencement. ⚠ Art. XII § 10
--   ("refusal to qualify - vacancy") is the clause most likely to be misread as a
--   qualification-start rule: it makes the office vacant, it does not date the term.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE RESULTS GAPS — ONE OF THEM CERTAIN, EVIDENCED THREE TIMES, AND NOT TIDIED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴🔴 **STATE BOARD OF EDUCATION DISTRICT 3 WAS ON THE 2026 BALLOT AND WE HOLD NO RACE ROW OF ANY
--   YEAR.** Three independent instruments say so, which is the Utah/Arizona standard for turning
--   "probably missing" into "certainly missing", met three times over:
--
--     1. **§ 22-2-105(1)'s own arithmetic.** The 1984 general election set District 1 and
--        District 3 on six-year terms commencing the second Tuesday in January 1985; 1985 + 6n
--        reaches **2027**. With District 7 (2003 + 6n → 2027) the statute puts **three** seats on
--        this boundary and the other six on 2029 or 2031.
--     2. **Colo. Const. Art. XII, § 11.** "The term of office of any officer **elected to fill a
--        vacancy** shall terminate at the **expiration of the term during which the vacancy
--        occurred**." Sherri Wright was elected in November 2024 to the remainder of Stephen
--        Varela's term, so her term ends on District 3's own 2027 boundary and not six years later.
--     3. **The body's own publication.** Colorado Department of Education news release, 8 January
--        2025, "Colorado State Board of Education welcomes four new members" (read 2026-11-25):
--        *"Board member **Sherri Wright** (R) represents the 3rd Congressional District and **her
--        term of office runs through January 2027**."* The same release gives the other three new
--        members' terms as "through January 2031", which is § 22-2-105(1)'s other cohort — so the
--        release corroborates four of the nine seats, not just this one.
--
--   ▶ **So the 2026 cohort is THREE and we hold TWO. The shortfall is exactly one seat, it is
--   District 3, and Sherri Wright will be left holding it on our pages past the expiry of her own
--   term.** That is New Mexico's Public Education Commission District 7 shape. **The fix is the
--   result, not a closure here** — an unsourced `term_end` is what this pass refuses. P7 gates on
--   the absence *staying* absent, so if the race arrives the wave is larger and the pin is stale.
--
-- 🟢🟢 **THE BOARD OF REGENTS, BY CONTRAST, HAS NO GAP AT ALL, AND THE PROOF IS COMPLETE.**
--   § 23-20-102(2) partitions the nine seats into three cohorts of three — (a)(II) 2022 + 6n for
--   CDs 1, 4 and 8; (b) 1976 + 6n for CDs 3, 5 and at-large; (c)(II) 2002 + 6n for CDs 2, 6 and 7 —
--   and **2002 + 6n reaches 2020, so that cohort's terms run 2021–2027 and it was up in 2026.** The
--   body's own roster (regents.cu.edu/meet-the-regents, read 2026-11-25) prints a "Current Term"
--   range against every member and **all nine agree with the statute**: Rennison (CD 2), Dubin
--   Spiegel (CD 6) and Chavez (CD 7) read **2021-27**; James (CD 1), McNulty (CD 4) and VanDriel
--   (CD 8) read 2023-29; Scott (CD 3), Montera (CD 5) and Hood (at-large) read 2025-31. **Three of
--   nine are up, they are exactly our three, and nine of nine reconcile.**
--
-- 🔴🔴 **THE LEGISLATURE IS THE LARGE GAP, AND ART. V §§ 3 AND 5 MAKE MOST OF IT CERTAIN.**
--   Colorado holds **65 `STATE_LOWER` and 35 `STATE_UPPER` office rows**, which is the
--   constitutional membership, and **9 House and 3 Senate race rows for 2026-11-03**, of which 6
--   and 3 carry a winner. Art. V § 3(1): "Senators shall be elected for the term of four years and
--   **representatives for the term of two years**", so **all 65 House seats were on the 2026 ballot
--   as a matter of law** and 59 of them are unaccounted for. Art. V § 5: "The senate shall be
--   divided so that **one-half of the senators, as nearly as practicable**, may be chosen
--   biennially" — 17 or 18 of 35 — so roughly 14 Senate races are missing too.
--   ⚠ **And the gap comes in two shapes that look identical from the seat**: House Districts 15, 21
--   and 22 carry a 2026 race whose candidates all have `result IS NULL` (an unrecorded result),
--   while 56 House and 32 Senate seats carry **no race row of any year** (the third class).
--   🟢 All twelve legislative races we do hold come from one source — the Colorado Secretary of
--   State's 2026 general election candidate list — and cover House 14–22 and 56 and Senate 9, 11 and
--   35, which is El Paso County plus three. So this is a **partial load of a statewide publication**
--   rather than a sparse source, which is the more hopeful of the two diagnoses.
--
-- ⚠ **State House District 32 is flagged `is_vacant` and is not in this wave** — no 2026 race of
--   any kind, so there is no winner to seat and no flag to clear. California's and Massachusetts'
--   lesson is that a correct `is_vacant` flag is not a blocker; this one is simply untouched, and
--   no file in this wave names it except to assert it stayed that way.
--
-- ⚠ **TWO WINNERS WILL HOLD TWO SEATS, AND ONLY ONE OF THEM IS A RESULTS GAP — WHICH IS NEW.**
--   **Jeff Bridges** takes the Treasurer's office and keeps **State Senate District 26**, a seat
--   that is genuinely **not up in 2026** (last elected 2024, running to 2029), so the absence of a
--   successor is correct and is not a gap. **Amanda Gonzalez** takes the Secretary of State's
--   office and keeps **Jefferson County Clerk and Recorder**, which carries no 2026 race in our data
--   at all. ▶ Texas's five dual holders were all results gaps; Colorado has one of each kind, and
--   **they are indistinguishable from the seat**. "A dual holder implies a missing result" is
--   therefore false. Both are pinned by name in CC_0518's P8b and neither is tidied: we hold no
--   resignation and no effective date for one, and a `term_end` is a legal fact.
--   ⚠ Colo. Const. Art. V § 8 ("No senator or representative shall, while serving as such, be
--   appointed to any civil office under this state") bears on Bridges's position. **This file takes
--   no view**: the office he takes is elective, not appointive, and an unsourced closure is what
--   this pass refuses.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SQUARES — AND EVERY ONE OF THE FOUR IS BUSY IN THE COLUMN NOBODY CHECKS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Measured in production 2026-11-25, before this file:
--
--   | day        | `term_start`                         | `term_end`                           |
--   |------------|--------------------------------------|--------------------------------------|
--   | 2027-01-10 | 0                                    | **193**  (Oregon 75, Washington 118)  |
--   | 2027-01-11 | **193**  (Oregon 75, Washington 118)  | 0                                    |
--   | 2027-01-12 | 0                                    | **178**  (Maryland)                   |
--   | 2027-01-13 | **178**  (Maryland)                  | 0                                    |
--
-- 🔴🔴🔴 **COLORADO'S TWO GROUPS INTERLEAVE WITH TWO OTHER STATES' CLUSTERS SO THAT EACH OF ITS
--   FOUR RELEVANT DAYS IS OCCUPIED IN ONE COLUMN AND EMPTY IN THE OTHER.** Group A starts
--   2027-01-11, so its predecessors close on **2027-01-10, where 193 rows already end** — Texas's
--   68 in a bigger form, and a "nothing else ends here" **total** would report every one of them as
--   a fault. Group B starts 2027-01-12, so its predecessors close on **2027-01-11, which is Group
--   A's own start day and 193 strangers' start day, and where 0 rows end.** ▶ **The two mistakes
--   are one column apart**: a `term_start` gate on 2027-01-12 reads 0 and discriminates nothing,
--   while a `term_end` gate on the same day reads 178 and looks like an invasion. CC_0517 and
--   CC_0518 pin the before-image of **both** columns on **all four** days and assert deltas, never
--   totals.
--
-- ⚠ **2027-01-12 CARRIES NO `office_swearing_in` ROW AND NO TERM AT ALL, SO COLORADO IS FIRST THERE
--   AND A "NO STRANGERS" GATE ON IT DISCRIMINATES NOTHING.** Said here rather than offered as a
--   measurement, exactly as Texas's 2027-01-19 was.
--
-- 🔴 **A CORRECTION TO PICKUP.md's HANDOFF: "Idaho's Ada County is scheduled for it too" IS FALSE.**
--   Measured 2026-11-25: 2027-01-11 carries 193 `office_swearing_in` rows from **exactly two
--   states**, Oregon and Washington. Idaho's only forward-dated rows are its seven state executives
--   on 2027-01-04 and three federal seats on 2027-01-03; **no Idaho office carries any row on
--   2027-01-11**, and no Ada County office carries one at all. The handoff's conclusion (the square
--   is crowded) is right and one of its three reasons is not — Nebraska's class of error, and the
--   handoff itself said to re-measure before writing.
--
-- 🟢 **THE CONSTITUTION PRINTS EACH ARTICLE EXACTLY ONCE.** Connecticut's document carried ARTICLE
--   FOURTH twice with the superseded copy first, and the cycle arithmetic passed on both copies.
--   Colorado's printing was checked for that: 29 article headings, 29 distinct numerals, no
--   repetition — so the trap does not apply here, which is worth a line because the check is cheap
--   and its absence is invisible.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT IS WRITTEN
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   19 rows in `essentials.office_swearing_in`, under FOUR rule_ids:
--     2027-01-11  `co-hjr26-1031-convening`                 basis `published`  (9 rows)
--     2027-01-12  `co-const-art4-s1-second-tuesday-january`  basis `statute`    (5 rows)
--     2027-01-12  `co-crs-22-2-105-second-tuesday-january`   basis `statute`    (2 rows)
--     2027-01-12  `co-crs-23-20-105-second-tuesday-january`  basis `statute`    (3 rows)
--
-- ⚠ **FOUR rule_ids for two days, and the five Art. IV § 1(1) officers share one.** The Lieutenant
--   Governor is dated by the **same sentence** as the other four, so merging it with them is correct
--   here — unlike Texas, where Art. IV § 4 named only the Governor and the two offices had to be
--   kept apart. The two boards reach the same day by **different statutes** and are kept apart,
--   which is Connecticut's warning against a later reader merging clauses that merely agree.
--
-- 🔴 **This file OVERWRITES NOTHING.** No Colorado office **in this file's selection** carries an
--   `office_swearing_in` row for 2026-11-03 (P0 asserts it). No value is replaced, so there is no
--   old value to record.
--
-- 🔴🔴 **BUT COLORADO ALREADY CARRIES NINE ROWS FOR THIS VERY ELECTION, AND `lower(d.state) = 'co'`
--   SELECTS THEM.** They are the **federal tier** — the eight U.S. House seats and the U.S. Senate
--   seat, all on **2027-01-03** under U.S. Const. Amend. XX § 1, written by the federal programme
--   — because a U.S. Representative's district carries its state. A gate caught this: assertion 6
--   was first written as a total and reported *"Colorado rows for 2026-11-03 went 9 -> 28, expected
--   19"*. ▶ **Texas's equivalent gate said "the 39 Texas rows that exist belong to other elections
--   AND other tiers" and so never met this case**: here the other tier shares the **election date**,
--   and only `district_type` separates them. Assertion 6 is now a delta, and the nine federal rows
--   are asserted untouched **by their own tier** rather than by subtraction.

BEGIN;

-- ── The selection: every office this wave will DATE, with the group it belongs to. ────────────
--
-- 🔴 TAKEN FROM `office_pending_winner`, NEVER BY TITLE — except the Lieutenant Governor, which is
--    not in that view precisely because its result is missing, and which is therefore identified by
--    title and then PROVED to be the right row by P5 (it carries a 2026 race and that race has no
--    winner). Both boards are staggered, so a title-based selection of the others would date
--    members whose terms run on: six of nine Regents and seven of nine Board of Education members.
-- 🔴 NO SIBLING EXPANSION ANYWHERE IN THIS FILE.
CREATE TEMP TABLE cc0516_sel ON COMMIT DROP AS
SELECT o.id            AS office_id,
       o.title         AS title,
       d.label         AS label,
       d.district_type AS district_type,
       CASE WHEN d.district_type IN ('STATE_LOWER', 'STATE_UPPER')  THEN 'A'
            WHEN d.district_type = 'STATE_BOARD_EDUCATION'          THEN 'SBE'
            WHEN d.district_type = 'STATE_BOARD'                    THEN 'REG'
            ELSE 'EXEC' END                                         AS grp
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'co'
   AND d.district_type IN ('STATE_EXEC', 'STATE_LOWER', 'STATE_UPPER',
                           'STATE_BOARD', 'STATE_BOARD_EDUCATION')
   AND w.election_date = DATE '2026-11-03'
UNION ALL
-- The Lieutenant Governor: dated under the same sentence of Art. IV § 1(1), seated by nobody.
SELECT o.id, o.title, d.label, d.district_type, 'LTGOV'
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'co'
   AND d.district_type = 'STATE_EXEC'
   AND o.title = 'Lieutenant Governor';

-- The Lieutenant Governor's race, so P5 can speak about WHICH row it is rather than how many.
-- 🔴 `has_winner` IS THE LOAD-BEARING COLUMN. Texas's lesson: a gate that counts to one is a
--    different claim from a gate that names the right seat. This office is selected by title, which
--    is the one thing this file does by title, so it carries the strictest check in the file.
CREATE TEMP TABLE cc0516_ltgov ON COMMIT DROP AS
SELECT o.id AS office_id,
       EXISTS (SELECT 1 FROM essentials.races r
                 JOIN essentials.elections e ON e.id = r.election_id
                WHERE r.office_id = o.id AND e.election_date = DATE '2026-11-03') AS carries_race,
       (SELECT count(*) FROM essentials.races r
          JOIN essentials.elections e ON e.id = r.election_id
          JOIN essentials.race_candidates rc ON rc.race_id = r.id
         WHERE r.office_id = o.id AND e.election_date = DATE '2026-11-03')        AS candidates,
       (SELECT count(*) FROM essentials.races r
          JOIN essentials.elections e ON e.id = r.election_id
          JOIN essentials.race_candidates rc ON rc.race_id = r.id
         WHERE r.office_id = o.id AND e.election_date = DATE '2026-11-03'
           AND rc.result = 'won')                                                AS winners
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_EXEC'
   AND o.title = 'Lieutenant Governor';

CREATE TEMP TABLE cc0516_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                            AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'co' AND s.election_date = DATE '2026-11-03')          AS rows_co_this_election,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'co')                                                 AS rows_co_all_elections,
       -- 🔴🔴 COLORADO IS THE THIRD STATE ON 2027-01-11, so assertion 4 is a DELTA and never a
       --    total: Oregon 75 and Washington 118 are already there, and both their rule_ids
       --    literally say "second-monday-january", which is the rival this state's own data
       --    cannot refuse.
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-11')                                  AS rows_jan11,
       -- ⚠ Empty before this file. A gate here discriminates nothing and says so.
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-12')                                  AS rows_jan12,
       -- The live near miss: the STATUTORY DEFAULT is Maryland's General Assembly day.
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-13')                                  AS rows_jan13,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-04')                                  AS rows_jan4,
       (SELECT count(*) FROM essentials.office_pending_winner w
          JOIN essentials.offices o   ON o.id = w.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'co' AND w.election_date = DATE '2026-11-03'
           AND d.district_type NOT IN ('STATE_EXEC', 'STATE_LOWER', 'STATE_UPPER',
                                       'STATE_BOARD', 'STATE_BOARD_EDUCATION'))       AS pending_outside;

DO $$
DECLARE n bigint; b record; lg record;
BEGIN
  SELECT * INTO b  FROM cc0516_before;
  SELECT * INTO lg FROM cc0516_ltgov;

  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. On a second
  --      apply the selection is still full (dating does not empty office_pending_winner), so P0 is
  --      reachable here — but it is kept first anyway, because in CC_0461/CC_0462 the equivalent
  --      gate sat below a row count and a re-run was reported as "the data moved".
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0516_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n > 0 THEN
    RAISE EXCEPTION 'P0: % of the 19 already carry a swearing-in row for 2026-11-03. This file has '
                    'already been applied, or something else dated these seats. It writes nothing '
                    'twice.', n;
  END IF;

  -- P1 — the selection is the size and the shape this file was written against.
  SELECT count(*) INTO n FROM cc0516_sel;
  IF n <> 19 THEN
    RAISE EXCEPTION 'P1: the selection holds % offices, expected 19 (9 legislative + 4 executives + '
                    '1 Lieutenant Governor + 2 State Board of Education + 3 Regents). Re-derive '
                    'before writing — derive-seating-wave.mjs --state co --type STATE_EXEC --type '
                    'STATE_LOWER --type STATE_UPPER --type STATE_BOARD --type '
                    'STATE_BOARD_EDUCATION.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0516_sel WHERE grp = 'A';
  IF n <> 9 THEN
    RAISE EXCEPTION 'P1: Group A holds % offices, expected 9 — 6 House and 3 Senate seats. Art. V '
                    '§ 7 dates these and nothing else in this state.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0516_sel WHERE grp = 'A' AND district_type = 'STATE_LOWER';
  IF n <> 6 THEN
    RAISE EXCEPTION 'P1: % House seats are in Group A, expected 6 (Districts 14, 16, 17, 18, 20, '
                    '56). Districts 15, 21 and 22 carry a 2026 race with no recorded result and '
                    'must NOT be here.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0516_sel WHERE grp = 'A' AND district_type = 'STATE_UPPER';
  IF n <> 3 THEN
    RAISE EXCEPTION 'P1: % Senate seats are in Group A, expected 3 (Districts 9, 11, 35).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0516_sel WHERE grp IN ('EXEC', 'LTGOV', 'SBE', 'REG');
  IF n <> 10 THEN
    RAISE EXCEPTION 'P1: Group B holds % offices, expected 10 — 4 executives + the Lieutenant '
                    'Governor + 2 Board of Education + 3 Regents.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0516_sel WHERE grp = 'EXEC';
  IF n <> 4 THEN
    RAISE EXCEPTION 'P1: % pending executives, expected exactly 4 — Governor, Secretary of State, '
                    'Treasurer and Attorney General. Art. IV § 1(1) names FIVE officers; the fifth '
                    'is the Lieutenant Governor, which has a race and no result and is handled as '
                    'its own group.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0516_sel WHERE grp = 'LTGOV';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P1: % Colorado Lieutenant Governor office row(s) matched, expected exactly 1. '
                    'This is the one office this file selects BY TITLE, so its identity is proved '
                    'by P5 rather than assumed.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0516_sel WHERE grp = 'SBE';
  IF n <> 2 THEN
    RAISE EXCEPTION 'P1: % State Board of Education seats are pending, expected 2 (Districts 1 and '
                    '7). 🔴 § 22-2-105(1) puts THREE on this boundary — District 3 is the third and '
                    'we hold no race row for it at all; see P7.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0516_sel WHERE grp = 'REG';
  IF n <> 3 THEN
    RAISE EXCEPTION 'P1: % Regent seats are pending, expected 3 (Districts 2, 6 and 7). '
                    '§ 23-20-102(2)(c)(II) puts exactly these three on the 2002 + 6n cohort and the '
                    'body''s own roster agrees on all nine.', n;
  END IF;

  -- P2 — nothing else in Colorado is pending for this election. A sixth body would mean the wave is
  --      larger than the file and the pin is stale.
  IF b.pending_outside <> 0 THEN
    RAISE EXCEPTION 'P2: % Colorado seat(s) are pending for 2026-11-03 outside the five bodies this '
                    'file dates. The wave is larger than this file.', b.pending_outside;
  END IF;

  -- P3 — every pending race is single-seat with exactly one winner, so Ruling A is not engaged.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0516_sel c ON c.office_id = w.office_id
   WHERE w.election_date = DATE '2026-11-03'
     AND NOT (w.winner_count = 1 AND w.seats = 1);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % of the 18 pending races are not single-seat with exactly one winner. '
                    'Ruling A is not engaged by this wave and this file is not written for it — '
                    'both Colorado boards are staggered, which is the shape Ruling A REFUSES.', n;
  END IF;

  -- P4 — every winner is a real, active person. No people file is needed and this is what proves it.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN cc0516_sel c ON c.office_id = w.office_id
    CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
   WHERE w.election_date = DATE '2026-11-03'
     AND ((win.value ->> 'id') IS NULL
          OR NOT EXISTS (SELECT 1 FROM essentials.politicians p
                          WHERE p.id = (win.value ->> 'id')::uuid AND p.is_active));
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 18 winners have no politicians row or are not active. This wave '
                    'ships without a people file and that claim is measured here, not assumed.', n;
  END IF;

  -- P5 — the Lieutenant Governor row is the RIGHT row, and it is unseatable for the reason stated.
  -- 🔴 THREE CLAIMS, NOT ONE COUNT. Texas's C22 proved that "exactly one of N selected" passes
  --    while the wrong row is dated. This office is selected by title, so it must carry the 2026
  --    race, that race must have candidates, and it must have NO winner — otherwise either the
  --    wrong row was matched or the result has arrived and CC_0518 is too small.
  IF NOT lg.carries_race THEN
    RAISE EXCEPTION 'P5: the Colorado Lieutenant Governor office row carries NO 2026-11-03 race. '
                    'Either the wrong row was matched by title, or the premise of this file is '
                    'wrong: the office is dated here BECAUSE it has a contest whose result is '
                    'missing, not because it has no contest.';
  END IF;
  IF lg.candidates <> 7 THEN
    RAISE EXCEPTION 'P5: the Lieutenant Governor''s 2026 race holds % candidate(s), expected 7. The '
                    'Governor''s race holds 7 as well, which is consistent with Art. IV § 3''s joint '
                    'ticket — but equal counts are NOT a pairing and no column records one.',
                    lg.candidates;
  END IF;
  IF lg.winners <> 0 THEN
    RAISE EXCEPTION 'P5: the Lieutenant Governor''s 2026 race now records % winner(s), expected 0. '
                    'The result has ARRIVED since this file was written: the office is no longer '
                    'merely dateable, it is seatable, and CC_0518 must seat it. Re-derive the wave.',
                    lg.winners;
  END IF;

  -- P6 — the bodies are the size their own constitutions say, checked against the document and not
  --      against themselves. A body holding one row too many would let a later sibling expansion
  --      claim a seat nobody elected.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_LOWER';
  IF n <> 65 THEN
    RAISE EXCEPTION 'P6: Colorado holds % STATE_LOWER office rows, expected 65 — the House''s '
                    'membership. Art. V § 3(1) gives every representative a two-year term, so all '
                    '65 were on the 2026 ballot as a matter of law.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_UPPER';
  IF n <> 35 THEN
    RAISE EXCEPTION 'P6: Colorado holds % STATE_UPPER office rows, expected 35 — the Senate''s '
                    'membership. Art. V § 5 puts one-half "as nearly as practicable" on each '
                    'biennial ballot, so 17 or 18 were up in 2026.', n;
  END IF;

  -- 🔴 THE AT-LARGE SEAT OF EACH BOARD IS FILED UNDER `STATE_EXEC`, NOT UNDER ITS OWN BODY. So a
  --    count by district_type UNDERSTATES both boards by one and OVERSTATES the executive
  --    department by two. Both numbers are asserted in the shape the data actually has, and the
  --    constitutional total is checked separately — otherwise "Colorado has 7 state executives"
  --    reads as true and Art. IV § 1(1) names five.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_BOARD_EDUCATION';
  IF n <> 8 THEN
    RAISE EXCEPTION 'P6: Colorado holds % STATE_BOARD_EDUCATION office rows, expected 8 — the eight '
                    'congressional-district seats. The ninth, the at-large member, is filed as '
                    'STATE_EXEC ("Colorado State Board of Education At-Large"), so 8 + 1 = 9, which '
                    'is Art. IX § 1(1)''s membership for an even number of districts.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_BOARD';
  IF n <> 8 THEN
    RAISE EXCEPTION 'P6: Colorado holds % STATE_BOARD office rows, expected 8 — the eight '
                    'congressional-district Regents. The ninth, the at-large Regent, is filed as '
                    'STATE_EXEC, so 8 + 1 = 9, which is Art. IX § 12''s "nine regents".', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_EXEC';
  IF n <> 7 THEN
    RAISE EXCEPTION 'P6: Colorado holds % STATE_EXEC office rows, expected 7 — the FIVE officers '
                    'Art. IV § 1(1) names, PLUS the two at-large board seats filed under this type. '
                    'It is not seven executives, and a reader counting this column will think it '
                    'is.', n;
  END IF;

  -- The five Art. IV § 1(1) officers must all exist, by title, or the clause does not reach what
  -- this file says it reaches.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_EXEC'
     AND o.title IN ('Governor', 'Lieutenant Governor', 'Secretary of State', 'Treasurer',
                     'Attorney General');
  IF n <> 5 THEN
    RAISE EXCEPTION 'P6: % of Art. IV § 1(1)''s five named officers exist as office rows, expected '
                    '5. The clause dates exactly these five and this file cites it for five rows.',
                    n;
  END IF;

  -- P7 — the results gaps are what this file says they are, and they must STAY that way. If one of
  --      them gains a winner the wave is larger and the pin is stale.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_LOWER'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_pending_winner w
                      WHERE w.office_id = o.id AND w.election_date = DATE '2026-11-03');
  IF n <> 59 THEN
    RAISE EXCEPTION 'P7: % Colorado House seats have no 2026 winner, expected 59 (3 with a race and '
                    'a blank result — Districts 15, 21, 22 — and 56 with no race row of any year). '
                    'Art. V § 3(1) put all 65 on the ballot, so every one of the 59 is certainly '
                    'missing data.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_UPPER'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_pending_winner w
                      WHERE w.office_id = o.id AND w.election_date = DATE '2026-11-03');
  IF n <> 32 THEN
    RAISE EXCEPTION 'P7: % Colorado Senate seats have no 2026 winner, expected 32, all of them with '
                    'no race row of any year. Art. V § 5 put 17 or 18 of the 35 on the ballot.', n;
  END IF;

  -- 🔴🔴 THE ONE CERTAIN BOARD GAP, NAMED. Not a count of "how many Board seats are unpending" —
  --    this asks whether DISTRICT 3 specifically still has no race, because that is the seat three
  --    instruments put on the 2026 ballot.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_BOARD_EDUCATION'
     AND d.label = 'Colorado State Board of Education District 3'
     AND EXISTS (SELECT 1 FROM essentials.races r WHERE r.office_id = o.id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: State Board of Education District 3 now carries % race row(s), expected 0 '
                    'of any year. Its 2026 result has arrived since this file was written — the '
                    'Board''s 2026 cohort is THREE seats (§ 22-2-105(1): 1985 + 6n for Districts 1 '
                    'and 3, 2003 + 6n for District 7) and this file dates two. Re-derive the wave.',
                    n;
  END IF;

  -- And the vacant House seat is named rather than counted, for the same reason.
  -- 🔴 SCOPED TO THE STATE TIER, AND A GATE CAUGHT THE FIRST VERSION NOT BEING. Written as a count
  --    over ALL Colorado offices it read 2 and failed, because Boulder's citywide Council Member
  --    row is also flagged — a LOCAL seat that has nothing to do with this wave. The claim this
  --    gate makes is about the bodies this file dates, so its scope has to be those bodies.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND o.is_vacant
     AND d.district_type IN ('STATE_EXEC', 'STATE_LOWER', 'STATE_UPPER',
                             'STATE_BOARD', 'STATE_BOARD_EDUCATION');
  IF n <> 1 THEN
    RAISE EXCEPTION 'P7: % Colorado STATE-TIER offices are flagged is_vacant, expected exactly 1 — '
                    'State House District 32, which has no 2026 race and is untouched by this '
                    'wave. ⚠ Colorado carries one other flagged row, Boulder''s citywide Council '
                    'Member, which is LOCAL and outside every body this file touches.', n;
  END IF;

  -- And the one seat this file dates must not be flagged, because a vacant seat in the selection
  -- would be California's shape and would need its own handover-day file.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN cc0516_sel c ON c.office_id = o.id
   WHERE o.is_vacant;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: % of the 19 offices this file dates are flagged is_vacant, expected 0. A '
                    'vacant seat inside the wave is California''s and Massachusetts'' shape and '
                    'needs a handover-day file of its own (CC_0480, CC_0486) — this wave has '
                    'none.', n;
  END IF;

  -- P8 — the before-image of every square this file's deltas are measured against.
  IF b.rows_jan11 <> 193 OR b.rows_jan12 <> 0 OR b.rows_jan13 <> 178 THEN
    RAISE EXCEPTION 'P8: a pinned square moved — 2027-01-11 % (expected 193: Oregon 75 + Washington '
                    '118, BOTH under a rule_id containing "second-monday-january"), 2027-01-12 % '
                    '(expected 0, so Colorado is first there and no "strangers" gate on it '
                    'discriminates anything), 2027-01-13 % (expected 178: the Maryland General '
                    'Assembly, which is where this state''s STATUTORY DEFAULT would have put its '
                    'legislature). The deltas below are measured against these.',
                    b.rows_jan11, b.rows_jan12, b.rows_jan13;
  END IF;
END $$;

-- ── Group A: nine legislative offices, 2027-01-11, designated by HJR26-1031. ──────────────────
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-11',
       'published',
       'co-hjr26-1031-convening',
       'Colo. Const. Art. V, § 7 with C.R.S. § 2-2-303.5(3) and HOUSE JOINT RESOLUTION 26-1031. '
         || 'Art. V § 7: "The general assembly shall meet in regular session at 10 a. m. NO LATER '
         || 'THAN the second Wednesday of January of each year. … The term of service of the '
         || 'members of the general assembly SHALL BEGIN ON THE CONVENING of the first regular '
         || 'session of the general assembly next after their election." 🔴 THE TERM ATTACHES TO AN '
         || 'EVENT AND "NO LATER THAN" IS A DEADLINE RATHER THAN A DATE, so the constitution itself '
         || 'authorises an earlier convening and the day is not computable from the constitution '
         || 'alone. C.R.S. § 2-2-303.5 supplies the machinery: (2) makes the second Wednesday the '
         || 'default "UNLESS A DIFFERENT DATE IS ESTABLISHED in accordance with subsection (3) or '
         || '(4)"; (3) lets the general assembly "ACTING BY JOINT RESOLUTION" designate a day "ON '
         || 'OR AFTER JANUARY 1 BUT PRIOR TO" the default. HJR26-1031 designates it: "That, '
         || 'pursuant to section 2-2-303.5 (3), Colorado Revised Statutes, the General Assembly '
         || 'designates MONDAY, JANUARY 11, 2027, as the convening date for the First Regular '
         || 'Session of the Seventy-sixth General Assembly." 🔴🔴 THE STATUTORY DEFAULT WOULD HAVE '
         || 'BEEN TWO DAYS WRONG — 2027-01-13 — WHICH IS THE MARYLAND GENERAL ASSEMBLY''S LIVE DAY, '
         || '178 ROWS. 🔴🔴 AND THE ESCAPE HATCH IN ART. V § 7 BELONGS TO A DIFFERENT SENTENCE: '
         || '"unless otherwise provided by the general assembly" governs the expiry of COMMITTEES, '
         || 'not the term of MEMBERS, which carries no residual at all. A reader grepping the '
         || 'section for "unless" finds one and attaches it to the wrong subject — the inverse of '
         || 'Oregon''s trap, where the hatch really was at the end of the term clause. 🟢 THE '
         || 'OATH IS NOT THIS DATE AND THE STATE SETTLES IT GENERALLY: Colo. Const. Art. XII § 8 '
         || 'requires every civil officer to swear "BEFORE he enters upon the duties of his '
         || 'office" and C.R.S. § 24-12-101 requires the oath "Taken, signed, administered, and '
         || 'filed … BEFORE the person enters upon the public office or position", so the oath is '
         || 'a precondition to the term rather than its start — the opposite of a qualification '
         || 'state. ⚠ Art. V § 7 attaches the term to the CONVENING, which is an organisational '
         || 'event and not a swearing-in: members are sworn after the body convenes. That is why '
         || 'basis is `published` while the oath question still answers no.',
       'Colorado General Assembly, Office of Legislative Legal Services, "Colorado Revised '
         || 'Statutes 2024" — Title 00 (which IS the constitution; '
         || 'leg.colorado.gov/sites/default/files/images/olls/crs2024-title-00.pdf, HTTP 200, '
         || 'application/pdf, 1,727,714 bytes) and Title 02 (…crs2024-title-02.pdf, 1,609,505 '
         || 'bytes), read in full 2026-11-22 and re-fetched 2026-11-25 at identical byte counts. '
         || 'The resolution: leg.colorado.gov/bill_files/117079/download, the signed enrolled act, '
         || '265,766 bytes, sha256 '
         || '103b34fc3672c61bca0af02a25bfde4958bb5243f991dbbaf9342635f0a50256, read in full '
         || '2026-11-25. ⚠ crs2025- and crs2026-title-00.pdf do not exist; 2024 is the current '
         || 'printout and is marked "Uncertified Printout". 🟢🟢 THE RESOLUTION CARRIES ITS OWN '
         || 'POSITIVE CONTROL: its attached Joint Rule 22B deadline schedule prints 28 (ordinal '
         || 'day, weekday, calendar date) triples, from "5 DAYS PRIOR TO 1ST DAY (WEDNESDAY '
         || '01/06/27)" through "120TH DAY (MONDAY 05/10/27)". Computed from a 1st day of Monday '
         || '2027-01-11 ALL 28 AGREE; computed from the statutory default of Wednesday 2027-01-13, '
         || 'ZERO of 28 agree. 🟢🟢 SECOND AND THIRD CYCLES, FROM DOCUMENTS OF THE SAME KIND, both '
         || 'read 2026-11-25: HJR18-1021 (123,841 bytes) designates "FRIDAY, JANUARY 4, 2019" and '
         || 'our office_terms carries 6 Colorado legislative terms starting 2019-01-04; HJR22-1025 '
         || '(158,893 bytes) designates "MONDAY, JANUARY 9, 2023" and our office_terms carries 37 '
         || 'starting 2023-01-09. 🟢🟢 AND A FOURTH DOCUMENT GIVES THE REASON THE DAY MOVES IN A '
         || 'GUBERNATORIAL YEAR: HJR23-1001 (83,224 bytes) sets a Joint Session for "Monday, '
         || 'January 9, 2023 … upon completion of organizational procedures, for the purpose of '
         || 'canvassing the votes for certain officials", which is Art. IV § 3''s canvass of the '
         || 'Governor and Lieutenant Governor returns happening on the convening day itself.',
       'CC_0516 — Colorado Group A, 9 of 19. Written 2026-11-25. 🔴🔴 THE FIRST `published` BASIS '
         || 'IN THIS PASS, and the first body whose day is DESIGNATED rather than computed. '
         || '🔴🔴🔴 THE RIVAL THAT SURVIVES OUR OWN DATA IS RIGHT IN 2027 FOR THE WRONG REASON: '
         || 'nine rules were computed from what each counts FROM over five cycles of our own '
         || 'office_terms, and the scoreboard is the statutory default 2/5 (2021, 2025), THE '
         || 'SECOND MONDAY 2/5 (2023, 2027), and 0/5 for the first Wednesday, first Monday, second '
         || 'Tuesday, first Tuesday, third Monday, Alabama''s "first Monday after the second '
         || 'Tuesday" and Utah''s January 1st. NO RULE REPRODUCES MORE THAN TWO OF FIVE, which is '
         || 'itself the evidence that the day is designated — but the second Monday gives '
         || '2027-01-11, so nothing in 2027 can separate it from the truth. 🔴 AND 2027-01-11 '
         || 'ALREADY CARRIES 193 ROWS UNDER TWO rule_ids THAT LITERALLY CONTAIN '
         || '"second-monday-january" (or-const-art4-s4-second-monday-january 75, '
         || 'wa-rcw-44-04-021-second-monday-january 118) — Arizona warned that a rival''s rule_id '
         || 'may share its words; this one shares the words, the day and the year. ONLY THE THREE '
         || 'RESOLUTIONS REFUSE IT, and 2019 does the work because it is a FRIDAY, which no '
         || 'ordinal-weekday rule in the Monday/Tuesday/Wednesday family can produce. 🟢 THE '
         || 'ERROR IS ALSO BOUNDED WITHOUT ANY OF THAT: § 2-2-303.5(3) and (4) confine every '
         || 'lawful designation to "on or after January 1 but prior to" the second Wednesday, so '
         || 'for 2027 the day cannot lie outside [2027-01-01 .. 2027-01-12] however the designation '
         || 'went. ⚠ BOTH WINDOWS ARE NOW CLOSED, and the ledger''s reason for that is wrong: (3) '
         || 'names no time limit at all — it is (4)''s own opening words ("in the event the general '
         || 'assembly does not act DURING THE REGULAR SESSION pursuant to subsection (3)") that '
         || 'confine it, and (4) was never reachable because the assembly DID act. 🔴 THE '
         || 'LEGISLATIVE RESULTS GAP IS LARGE AND MOSTLY CERTAIN: 65 House and 35 Senate office '
         || 'rows, 9 and 3 race rows, 6 and 3 winners. Art. V § 3(1) gives representatives two-year '
         || 'terms so ALL 65 House seats were up; 59 are unaccounted for — Districts 15, 21 and 22 '
         || 'carry a race with a blank result and 56 carry no race row of any year. Art. V § 5 puts '
         || '17 or 18 Senate seats on each biennial ballot; 32 carry no race row. All twelve races '
         || 'we hold come from one source, the Secretary of State''s 2026 candidate list, covering '
         || 'House 14-22 and 56 and Senate 9, 11 and 35 — El Paso County plus three — so this is a '
         || 'PARTIAL LOAD of a statewide publication rather than a sparse source.'
  FROM cc0516_sel c
 WHERE c.grp = 'A';

-- ── The four pending executives: 2027-01-12, Colo. Const. Art. IV, § 1(1). ────────────────────
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-12',
       'statute',
       'co-const-art4-s1-second-tuesday-january',
       'Colo. Const. Art. IV, § 1(1) (Officers - terms of office) — "The executive department '
         || 'shall include the governor, LIEUTENANT GOVERNOR, secretary of state, state treasurer, '
         || 'and attorney general, each of whom shall hold his office for the term of four years, '
         || 'COMMENCING ON THE SECOND TUESDAY OF JANUARY IN THE YEAR 1967, AND EACH FOURTH YEAR '
         || 'THEREAFTER. They shall perform such duties as are prescribed by this constitution or '
         || 'by law." An ANCHOR-YEAR rule, which is Arizona''s shape: a specific past date plus a '
         || 'term length, with the recurrence implied. 1967 + 4n reaches 2027 (2027 − 1967 = 60 = '
         || '4 × 15) and the second Tuesday of January 2027 is 2027-01-12. 🟢🟢 NO ESCAPE HATCH: '
         || 'the sentence ends at "each fourth year thereafter" and the next sentence is about '
         || 'duties. ⚠ ITS TAIL IS A TERM LIMIT, NOT A HATCH — § 1(2) caps consecutive service at '
         || 'two terms — which is verbatim Md. Const. Art. II § 1''s shape, and is said out loud '
         || 'here for the same reason CC_0499 said it. 🟢 AND NO GENERAL COMMENCEMENT CLAUSE '
         || 'EXISTS TO DISPLACE IT: all 29 articles of the constitution were scanned and it '
         || 'contains exactly TWO term-commencement provisions, this one and Art. V § 7. There is '
         || 'no equivalent of New Mexico''s Art. XX § 3(A). 🟢 THE OATH IS NOT THIS DATE: Art. XII '
         || '§ 8 requires the oath "BEFORE he enters upon the duties of his office" and C.R.S. '
         || '§ 24-12-101 requires it filed "before the person enters upon the public office or '
         || 'position", so it is a precondition to the term. ⚠ Art. XII § 10 ("refusal to qualify '
         || '- vacancy") makes an office vacant if the officer does not qualify in time; it does '
         || 'NOT date the term, and it is the clause most likely to be misread as if it did.',
       'Colorado General Assembly, Office of Legislative Legal Services, "Colorado Revised '
         || 'Statutes 2024" Title 00, which IS the constitution '
         || '(leg.colorado.gov/sites/default/files/images/olls/crs2024-title-00.pdf, HTTP 200, '
         || 'application/pdf, 1,727,714 bytes), read in full 2026-11-22 and re-fetched 2026-11-25 '
         || 'at an identical byte count; marked "Uncertified Printout". The oath statute from '
         || '…crs2024-title-24.pdf (25,427,802 bytes), read 2026-11-25. 🟢 THE DOCUMENT PRINTS '
         || 'EACH ARTICLE EXACTLY ONCE — 29 headings, 29 distinct numerals, no repetition — so '
         || 'Connecticut''s superseded-duplicate-article trap, where the cycle arithmetic passed on '
         || 'both copies and only the officer LIST discriminated, does not apply here. Checked '
         || 'because the check is cheap and its absence is invisible.',
       'CC_0516 — the four pending Colorado executives, 4 of 19. Written 2026-11-25. 🟢🟢 THE '
         || 'IN-DATA CONTROL IS EXACT AND IT IS ONE ROW: office_terms carries Jared Polis''s '
         || 'Governorship starting 2019-01-08, and the second Tuesday of January 2019 is '
         || '2019-01-08. It is the ONLY dated Colorado state executive term in the database — '
         || 'Connecticut''s and Texas''s position — so assertion 3e asserts the count IS exactly '
         || 'one, and that the row did not move, rather than letting a vacuous zero pass. '
         || '🔴 THE NEAR MISS IS LIVE AND IT IS INSIDE THIS FILE: the second Monday of January '
         || '2027 is 2027-01-11, which is Group A''s own day, so a misapplication of either '
         || 'group''s rule lands on the other group''s date and the error never leaves this wave. '
         || 'That is why assertion 2 counts each group separately and no gate in this file counts '
         || 'a total across the two days. 🔴 SEVEN OF THE EIGHTEEN SEATS CHANGE HANDS AND THREE OF '
         || 'THEM FORM A CHAIN: Phil Weiser leaves the Attorney General''s office for the '
         || 'Governorship, Jena Griswold leaves the Secretary of State''s office for his, and '
         || 'Amanda Gonzalez takes hers — three links, one day, all three seats inside CC_0518, so '
         || 'the chain resolves itself. New Mexico''s Garcia Richard case two links deeper, and the '
         || 'longest in this pass. ⚠ TWO WINNERS WILL HOLD TWO SEATS AND ONLY ONE IS A RESULTS '
         || 'GAP: Jeff Bridges keeps State Senate District 26, which is genuinely not up until '
         || '2028, and Amanda Gonzalez keeps Jefferson County Clerk and Recorder, which carries no '
         || '2026 race in our data. They are indistinguishable from the seat, so "a dual holder '
         || 'implies a missing result" is false. Neither is tidied.'
  FROM cc0516_sel c
 WHERE c.grp = 'EXEC';

-- ── The Lieutenant Governor: 2027-01-12, the SAME sentence of Art. IV § 1(1). DATED, NOT SEATED. ──
--
-- 🔴🔴 THE SAME rule_id AS THE OTHER FOUR, AND THAT IS DELIBERATE. Art. IV § 1(1) names all five
--    officers in one sentence with one commencement, so merging them is correct — unlike Texas,
--    where Art. IV § 4 named only the Governor and § 16(a) had to carry the Lieutenant Governor
--    under a rule_id of its own. The difference between the two states is in the documents, not in
--    a convention, and it is why both files say which it is.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-12',
       'statute',
       'co-const-art4-s1-second-tuesday-january',
       'Colo. Const. Art. IV, § 1(1) — the Lieutenant Governor is named in the same sentence as '
         || 'the other four executives and takes the same commencement: "The executive department '
         || 'shall include the governor, LIEUTENANT GOVERNOR, secretary of state, state treasurer, '
         || 'and attorney general, each of whom shall hold his office for the term of four years, '
         || 'COMMENCING ON THE SECOND TUESDAY OF JANUARY IN THE YEAR 1967, AND EACH FOURTH YEAR '
         || 'THEREAFTER." Second Tuesday of January 2027 = 2027-01-12. 🔴🔴 THIS ROW IS DATED AND '
         || 'WILL NOT BE SEATED, AND THE REASON IS A MISSING RESULT RATHER THAN A MISSING '
         || 'CONTEST. We hold this office row, a 2026-11-03 race row on it, and SEVEN candidates '
         || 'every one of whom carries `result IS NULL` — not "advanced", not "lost", blank. So '
         || 'the office is absent from office_pending_winner and CC_0518 cannot seat it. '
         || '⚠ Art. IV § 3 makes the answer knowable in law and not in our data: "The governor and '
         || 'the lieutenant governor shall be CHOSEN JOINTLY by the casting by each voter of a '
         || 'SINGLE VOTE APPLICABLE TO BOTH OFFICES. … The joint candidates having the highest '
         || 'number of votes cast for governor and lieutenant governor … shall be declared duly '
         || 'elected." The winner is therefore determined entirely by the Governor''s result — but '
         || 'NO COLUMN RECORDS THE TICKET PAIRING. Both races hold seven candidates and '
         || 'external_id is NULL on all fourteen, and equal counts are not a pairing. Seating from '
         || 'an inferred pairing is what this pass refuses, so this row is a QUEUE ENTRY and not '
         || 'an acceptance.',
       'Colorado General Assembly, Office of Legislative Legal Services, "Colorado Revised '
         || 'Statutes 2024" Title 00 (the constitution; 1,727,714 bytes), Art. IV §§ 1 and 3, read '
         || 'in full 2026-11-25. The absence of a result is measured in production on the same '
         || 'day: essentials.race_candidates holds 7 rows for this office''s 2026-11-03 race, all '
         || 'with result IS NULL and candidate_status = ''active'', sourced from the "Colorado '
         || 'Secretary of State, 2026 General Election Unofficial Candidate" list — the same '
         || 'source that supplied the four executives whose results ARE recorded, so the gap is in '
         || 'the result load and not in the candidate load.',
       'CC_0516 — the Colorado Lieutenant Governor, 1 of 19, DATED AND NOT SEATED. Written '
         || '2026-11-25. 🔴🔴 THIS CORRECTS DATES.md § CO, which says "Only four executives are '
         || 'pending and that is correct — Colorado''s Lieutenant Governor runs on the Governor''s '
         || 'ticket (Art. IV, § 3), so it is the ticket case, not a gap." The ticket fact is right '
         || 'and the conclusion is wrong: the pending set is four because a RESULT is missing, not '
         || 'because the office has no contest. 🟢 Arizona''s Corporation Commission is the '
         || 'precedent for dating a seat that cannot be seated (CC_0497), and the row is kept so '
         || 'the gap is a written-down defect rather than a silence — CLAUDE.md''s "a defect filed '
         || 'as an acceptance is a defect nobody will ever fix". 🔴 THIS IS THE FOURTH FORM OF THE '
         || 'LIEUTENANT-GOVERNOR HOLE IN THIS PASS AND THE MOST COMPLETE: Arizona has a winner and '
         || 'NO OFFICE ROW; Maryland has an office row and NO RACE AT ALL; Colorado has the office, '
         || 'the race, the candidates and no RESULT. Each reads as a one-state oddity on its own. '
         || 'P5 gates on the absence staying absent: if a winner arrives, the office is seatable '
         || 'and CC_0518 is too small. ⚠ Creating or seating anything here is an occupancy act and '
         || 'belongs to the results programme, not to seating.'
  FROM cc0516_sel c
 WHERE c.grp = 'LTGOV';

-- ── The two State Board of Education seats: 2027-01-12, C.R.S. § 22-2-105(1). ─────────────────
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-12',
       'statute',
       'co-crs-22-2-105-second-tuesday-january',
       'C.R.S. § 22-2-105(1) (State board of education - composition) — Colo. Const. Art. IX, § 1(1) '
         || 'leaves the members to be elected "in such manner and for such terms as may be BY LAW '
         || 'PRESCRIBED", and § 22-2-105(1) prescribes them, anchoring every cohort on the same '
         || 'weekday-of-month: "… all such terms commencing on the SECOND TUESDAY IN JANUARY 1983 '
         || '… all such terms commencing on the SECOND TUESDAY IN JANUARY 1985 … all such terms '
         || 'commencing on the SECOND TUESDAY IN JANUARY 1987 … a six-year term commencing on the '
         || 'SECOND TUESDAY IN JANUARY 2003 … both terms commencing on the SECOND TUESDAY IN '
         || 'JANUARY 2023", with "(3) Except as provided in subsection (1) of this section, members '
         || 'shall be elected for terms of six years." FIVE INDEPENDENT ANCHORS, the most recent '
         || 'from 2023, all on the second Tuesday in January; second Tuesday of January 2027 = '
         || '2027-01-12. 🔴🔴 DATES.md CITES THIS AS § 22-2-104(1) AND THAT SECTION IS "Offices and '
         || 'positions - nature", about which departmental positions are exempt from the state '
         || 'personnel system; it contains NO DATE OF ANY KIND. The quoted words are all in '
         || '§ 22-2-105(1), verbatim. The quote was right and the section number was not, and '
         || 'because the DAY is unaffected no count, digest or view can see it. 🟢🟢 AND THE '
         || 'STATUTE CLOSES AN ARITHMETIC NO DATE SOURCE COULD: its anchors give every one of the '
         || 'nine seats a term-end year — 1985 + 6n reaches 2027 for Districts 1 and 3, 2003 + 6n '
         || 'reaches 2027 for District 7, 1983 + 6n reaches 2025 then 2031 for Districts 2 and 4, '
         || '1987 + 6n reaches 2023 then 2029 for Districts 5 and 6, and the 2022 election set '
         || 'District 8 on a two-year term then six and the at-large seat on six, both from 2023. '
         || 'So THREE seats fall on this boundary and six do not.',
       'Colorado General Assembly, Office of Legislative Legal Services, "Colorado Revised '
         || 'Statutes 2024" Title 22 '
         || '(leg.colorado.gov/sites/default/files/images/olls/crs2024-title-22.pdf, HTTP 200, '
         || 'application/pdf, 7,499,629 bytes) and Title 00 for Art. IX § 1, both read in full '
         || '2026-11-22 and re-fetched 2026-11-25 at identical byte counts. CORROBORATED BY THE '
         || 'BODY''S OWN PUBLICATION for four of the nine seats: Colorado Department of Education '
         || 'news release, 8 January 2025, "Colorado State Board of Education welcomes four new '
         || 'members" (ed.cde.state.co.us/newsbureau/news-release-state-board-four-new-members, '
         || 'HTTP 200, 51,886 bytes, read 2026-11-25), which gives Kristi Burton Brown (CD 4), '
         || 'Kathy Gebhardt (CD 2) and Yazmin Navarro (CD 8) terms "through January 2031" and '
         || 'Sherri Wright (CD 3) a term "through January 2027" — the statute''s two cohorts, in '
         || 'the body''s own words. ⚠ The board''s roster page (www.cde.state.co.us/cdeboard, '
         || '148,487 bytes) lists all nine members and their districts and carries NO term dates '
         || 'at all, so the roster alone cannot date this body; the news release can.',
       'CC_0516 — the two pending Colorado State Board of Education seats, 2 of 19. Written '
         || '2026-11-25. 🔴🔴 THE 2026 COHORT IS THREE SEATS AND WE HOLD TWO. District 3 was on the '
         || 'ballot and we have NO RACE ROW FOR IT OF ANY YEAR, which is the third and worst class '
         || 'of results gap. Three independent instruments say the seat was up: (1) § 22-2-105(1)''s '
         || 'own arithmetic, 1985 + 6n → 2027, which is District 1''s cohort and District 3 is in '
         || 'it; (2) Colo. Const. Art. XII § 11, "The term of office of any officer ELECTED TO FILL '
         || 'A VACANCY shall terminate at the EXPIRATION OF THE TERM DURING WHICH THE VACANCY '
         || 'OCCURRED" — Sherri Wright won the November 2024 election for the remainder of Stephen '
         || 'Varela''s term, so her term ends on District 3''s own 2027 boundary and not six years '
         || 'later; and (3) the Department''s own release, which states in words that her "term of '
         || 'office runs through January 2027". ▶ So Sherri Wright will be left holding District 3 '
         || 'on our pages past the expiry of her own term — New Mexico''s Public Education '
         || 'Commission District 7 shape. THE FIX IS THE RESULT, NOT A CLOSURE HERE: an unsourced '
         || 'term_end is what this pass refuses. P7 gates on District 3 having no race row BY NAME, '
         || 'so if the result arrives this file''s premise is reported rather than absorbed. '
         || '🟢 NO SIBLING EXPANSION: the board is staggered and seven of its nine members are not '
         || 'leaving, so a title-based selection would have dated seven seats whose terms run on.'
  FROM cc0516_sel c
 WHERE c.grp = 'SBE';

-- ── The three Regent seats: 2027-01-12, C.R.S. § 23-20-105(2). THE WEAKEST CITATION HERE. ─────
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-12',
       'statute',
       'co-crs-23-20-105-second-tuesday-january',
       'C.R.S. § 23-20-105(2) — AND THIS IS THE WEAKEST CITATION IN COLORADO, FLAGGED RATHER THAN '
         || 'SMOOTHED OVER. Colo. Const. Art. IX, § 12 gives "nine regents of the university of '
         || 'Colorado who shall be elected in the manner prescribed by law FOR TERMS OF SIX YEARS '
         || 'EACH" — a length, not a commencement. § 23-20-102 prescribes the manner and the cycle '
         || 'and NAMES NO COMMENCEMENT AT ALL. The only commencement evidence in Colorado law is a '
         || '1973 TRANSITIONAL PROVISION about filling vacancies: "(2) The governor shall appoint, '
         || 'effective July 1, 1973, three persons to fill vacancies on the board of regents … one '
         || 'such appointment to be of a qualified elector of the state for a term EXPIRING ON THE '
         || 'SECOND TUESDAY IN JANUARY, 1975, one … EXPIRING ON THE SECOND TUESDAY IN JANUARY, '
         || '1977, and one … EXPIRING ON THE SECOND TUESDAY IN JANUARY, 1979. Their respective '
         || 'successors in office shall be elected from the state at large, as provided in section '
         || '23-20-102." 🔴 TRANSITIONAL TEXT IS EXACTLY WHAT MADE UTAH''S BOARD OF EDUCATION A '
         || 'REFUSAL (CC_0489), AND THE DIFFERENCE IS STATED SO THE INCONSISTENCY IS NOT SILENT: in '
         || 'Utah the transitional dates pointed at a boundary DIFFERENT from the legislature''s, '
         || 'so they were evidence AGAINST borrowing; in Colorado they point at the SAME boundary '
         || 'as the executives (a current constitutional clause) and the State Board of Education '
         || '(a current statute with five anchors), so they corroborate rather than contradict. '
         || '🔴 AND THE SWEEP THAT MIGHT HAVE REPAIRED THIS CAME BACK EMPTY: all 29 articles of the '
         || 'constitution were scanned and it holds exactly TWO term-commencement provisions, '
         || 'Art. IV § 1(1) and Art. V § 7. There is no general clause of New Mexico''s Art. XX '
         || '§ 3(A) kind to reach this body, so the transitional provision is the whole of the '
         || 'day-evidence. A sweep that fails to repair a weak claim is still a measurement. '
         || '🟢🟢 THE SWEEP DID FIND SOMETHING ELSE: § 23-20-103 provides only that "The members of '
         || 'the board of regents shall take an oath or affirmation IN ACCORDANCE WITH SECTION '
         || '24-12-101", and § 24-12-101 requires the oath "Taken, signed, administered, and filed '
         || '… BEFORE the person enters upon the public office or position" — so for the one body '
         || 'whose own statute names no commencement, the general oath rule still establishes that '
         || 'a term-start day is the right thing to record and that the oath is not it.',
       'Colorado General Assembly, Office of Legislative Legal Services, "Colorado Revised '
         || 'Statutes 2024" Title 23 '
         || '(leg.colorado.gov/sites/default/files/images/olls/crs2024-title-23.pdf, HTTP 200, '
         || 'application/pdf, 4,425,919 bytes), Title 00 for Art. IX § 12, and Title 24 '
         || '(25,427,802 bytes) for § 24-12-101, all read in full 2026-11-25; Titles 23 and 00 were '
         || 'also read 2026-11-22 and re-fetched at identical byte counts. 🟢🟢 THE BODY''S OWN '
         || 'ROSTER RECONCILES WITH THE STATUTE ON ALL NINE SEATS: regents.cu.edu/meet-the-regents '
         || '(HTTP 200, 113,842 bytes, read 2026-11-25) prints a "Current Term" range against each '
         || 'member — Callie Rennison (2nd CD), Ilana Dubin Spiegel (6th CD) and Nolbert Chavez '
         || '(7th CD) read "2021-27"; Wanda James (1st), Frank McNulty (4th) and Mark VanDriel '
         || '(8th) read "2023-29"; Ken Montera (5th), Ray Scott (3rd) and Elliott Hood (at large) '
         || 'read "2025-31" — which is precisely § 23-20-102(2)''s three cohorts: (c)(II) 2002 + 6n '
         || 'for CDs 2, 6 and 7, (a)(II) 2022 + 6n for CDs 1, 4 and 8, and (b) 1976 + 6n for CDs 3, '
         || '5 and at-large. ⚠ The roster writes the 6th district member as "Ilana Dubin Spiegel" '
         || 'where our politicians row says "Ilana Spiegel"; the match is anchored on the SEAT, not '
         || 'on the name.',
       'CC_0516 — the three pending University of Colorado Regent seats, 3 of 19. Written '
         || '2026-11-25. 🟢🟢 THIS BODY HAS NO RESULTS GAP AND THE PROOF IS COMPLETE — the rare '
         || 'case in this pass. § 23-20-102(2) partitions the nine seats into three cohorts of '
         || 'three and 2002 + 6n reaches 2020, so CDs 2, 6 and 7 ran 2021-2027 and were up in 2026; '
         || 'the body''s own roster agrees on all nine seats; three of nine are pending and they '
         || 'are exactly those three. ⚠ NO IN-DATA CONTROL EXISTS FOR THIS BODY OR FOR THE STATE '
         || 'BOARD OF EDUCATION: all 8 Regent rows and all 8 Board rows in office_terms carry '
         || 'term_start NULL, sourced from the bodies'' own rosters by CC_0366 with how_started '
         || '"unknown". So the ONLY in-data corroboration for 2027-01-12 anywhere in this group is '
         || 'the Governor''s 2019-01-08, which belongs to the executives'' clause. That absence is '
         || 'asserted at 3e rather than left unsaid, in Utah''s and Alabama''s shape. 🟢 NO SIBLING '
         || 'EXPANSION: six of the nine Regents are not leaving, and the three identical-looking '
         || 'cohorts are exactly the staggered-body shape Ruling A refuses to assign — reached here '
         || 'from the DATING side, which is Texas''s Railroad Commission lesson in a second state.'
  FROM cc0516_sel c
 WHERE c.grp = 'REG';

-- ── Post-verify. Read the output, not the exit code. ──────────────────────────────────────────
DO $$
DECLARE
  n             bigint;
  b             record;
  -- 🔴 ONE COPY OF EACH EXPECTATION, shared by the condition and its message. Oregon, Connecticut
  --    and Texas each shipped a gate whose condition and message held their own copies and printed
  --    a self-contradiction; only a control ever makes those copies disagree.
  grp_a_day     CONSTANT date := DATE '2027-01-11';
  grp_b_day     CONSTANT date := DATE '2027-01-12';
  dflt_day      CONSTANT date := DATE '2027-01-13';
  exp_grp_a     CONSTANT int  := 9;
  exp_grp_b     CONSTANT int  := 10;
  exp_total     CONSTANT int  := 19;
  exp_jan11_pre CONSTANT int  := 193;
  exp_jan13_pre CONSTANT int  := 178;
  win_lo        CONSTANT date := DATE '2027-01-01';
  win_hi        CONSTANT date := DATE '2027-01-12';
  -- the rules, each computed from what IT counts from
  r_2nd_wed     date;
  r_2nd_mon     date;
  r_2nd_tue     date;
  r_1st_mon     date;
  cyc           record;
  agree_dflt    int := 0;
  agree_2nd_mon int := 0;
BEGIN
  SELECT * INTO b FROM cc0516_before;

  -- 1. Every one of the 19 carries its group's day.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0516_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date = CASE WHEN c.grp = 'A' THEN grp_a_day ELSE grp_b_day END;
  IF n <> exp_total THEN
    RAISE EXCEPTION '1: % of % seats carry their group''s day (% for Group A, % for Group B).',
                    n, exp_total, grp_a_day, grp_b_day;
  END IF;

  -- 2. Exactly two distinct dates, and each group's own count. 🔴 COUNTED PER GROUP AND NEVER AS A
  --    TOTAL, because the two groups are ONE DAY APART and are each other's near miss: the second
  --    Monday of January 2027 is Group A's day and the second Tuesday is Group B's, so a
  --    misapplication of either rule lands on the other group's date and a total of 19 would not
  --    move.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s JOIN cc0516_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 2 THEN
    RAISE EXCEPTION '2: % distinct swearing-in dates were written, expected exactly 2 — % for the '
                    'legislature and % for the executives and both boards.', n, grp_a_day, grp_b_day;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0516_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp = 'A' AND s.swearing_in_date = grp_a_day;
  IF n <> exp_grp_a THEN
    RAISE EXCEPTION '2: % of % Group A seats carry %.', n, exp_grp_a, grp_a_day;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0516_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp <> 'A' AND s.swearing_in_date = grp_b_day;
  IF n <> exp_grp_b THEN
    RAISE EXCEPTION '2: % of % Group B seats carry %.', n, exp_grp_b, grp_b_day;
  END IF;

  -- 3a. Group A's day is the designated one, it is a Monday, and it lies inside the window
  --     § 2-2-303.5(3) and (4) confine every lawful designation to. 🟢 THE WINDOW IS THE PART THAT
  --     BOUNDS THE ERROR: whatever happened, the day cannot be outside it.
  IF to_char(grp_a_day, 'Dy') <> 'Mon' THEN
    RAISE EXCEPTION '3a: % is not a Monday. HJR26-1031 designates "MONDAY, JANUARY 11, 2027".',
                    grp_a_day;
  END IF;
  IF grp_a_day < win_lo OR grp_a_day > win_hi THEN
    RAISE EXCEPTION '3a: % lies outside [% .. %], the window C.R.S. § 2-2-303.5(3) and (4) confine '
                    'every designated convening date to ("on or after January 1 but prior to" the '
                    'second Wednesday). A day outside it could not have been lawfully designated.',
                    grp_a_day, win_lo, win_hi;
  END IF;

  -- 3b. Group B's day is the second Tuesday, and 2027 is on Art. IV § 1(1)'s anchor cycle.
  SELECT (DATE '2027-01-01'
          + ((2 - EXTRACT(dow FROM DATE '2027-01-01')::int + 7) % 7) + 7)::date INTO r_2nd_tue;
  IF r_2nd_tue <> grp_b_day THEN
    RAISE EXCEPTION '3b: the second Tuesday of January 2027 computes as %, not % — the arithmetic '
                    'behind every other gate in this file is broken.', r_2nd_tue, grp_b_day;
  END IF;
  IF to_char(grp_b_day, 'Dy') <> 'Tue' THEN
    RAISE EXCEPTION '3b: % is not a Tuesday.', grp_b_day;
  END IF;
  IF (2027 - 1967) % 4 <> 0 THEN
    RAISE EXCEPTION '3b: 2027 is not on Art. IV § 1(1)''s four-year cycle from 1967, so the clause '
                    'does not reach this election at all.';
  END IF;

  -- 3c. 🔴🔴 THE ORDER GATE, AND NO SINGLE-GROUP FILE COULD EXPRESS IT. Art. IV § 3 requires the
  --     Speaker to open and publish the returns for Governor and Lieutenant Governor "immediately,
  --     upon the organization of the house, and before proceeding to other business", and
  --     HJR23-1001 shows that canvass happening ON the convening day. So the legislature must
  --     convene BEFORE the executives' terms begin. True in all three gubernatorial cycles: 4 days
  --     apart in 2019, 1 day in 2023, 1 day in 2027.
  IF NOT (grp_a_day < grp_b_day) THEN
    RAISE EXCEPTION '3c: Group A (%) does not precede Group B (%). Colo. Const. Art. IV § 3 requires '
                    'the General Assembly to canvass the returns for Governor and Lieutenant '
                    'Governor "immediately, upon the organization of the house, and before '
                    'proceeding to other business", so the legislature convenes BEFORE the '
                    'executives take office. If these two dates have swapped, one group''s rule has '
                    'been applied to the other group.', grp_a_day, grp_b_day;
  END IF;

  -- 3d. 🔴🔴🔴 THE RIVALS, RUN OVER CYCLES THIS FILE DOES NOT WRITE — AND THE POINT IS THAT NO RULE
  --     FITS. A `published` basis is the claim that the day comes from a document rather than a
  --     formula, so the evidence for it is that every formula FAILS. Two rules reproduce two of the
  --     five cycles each and nothing reproduces more; the second Monday is one of them and it is
  --     RIGHT IN 2027, which is exactly Nebraska's trap.
  SELECT (DATE '2027-01-01'
          + ((3 - EXTRACT(dow FROM DATE '2027-01-01')::int + 7) % 7) + 7)::date INTO r_2nd_wed;
  SELECT (DATE '2027-01-01'
          + ((1 - EXTRACT(dow FROM DATE '2027-01-01')::int + 7) % 7) + 7)::date INTO r_2nd_mon;
  SELECT (DATE '2027-01-01'
          + ((1 - EXTRACT(dow FROM DATE '2027-01-01')::int + 7) % 7))::date      INTO r_1st_mon;

  IF r_2nd_wed <> dflt_day THEN
    RAISE EXCEPTION '3d: the statutory default (the second Wednesday of January 2027) computes as '
                    '%, not % — the rival arithmetic is broken and the comparisons below mean '
                    'nothing.', r_2nd_wed, dflt_day;
  END IF;
  IF r_2nd_mon <> grp_a_day THEN
    RAISE EXCEPTION '3d: the second Monday of January 2027 computes as %, not % — this rival is '
                    'supposed to COINCIDE with the designated day, and the fact that it does is '
                    'the reason this file cites a resolution rather than a formula.',
                    r_2nd_mon, grp_a_day;
  END IF;
  IF r_1st_mon = grp_a_day OR r_1st_mon = grp_b_day THEN
    RAISE EXCEPTION '3d: the first Monday of January 2027 (%) coincides with one of this file''s '
                    'days, so that rival cannot be refused here.', r_1st_mon;
  END IF;

  -- The five cycles, from our own office_terms. 🔴 REFUSES TO REPORT IF A CYCLE HAS NO ROWS — a
  -- control that has lost its fixture proves nothing (CC_0497's 3d).
  FOR cyc IN
    SELECT y,
           (SELECT to_char(ot.term_start, 'YYYY-MM-DD')
              FROM essentials.office_terms ot
              JOIN essentials.offices o   ON o.id = ot.office_id
              JOIN essentials.districts d ON d.id = o.district_id
             WHERE lower(d.state) = 'co'
               AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
               AND ot.term_start >= make_date(y, 1, 1) AND ot.term_start < make_date(y, 2, 1)
             GROUP BY ot.term_start ORDER BY count(*) DESC, ot.term_start LIMIT 1) AS observed,
           (SELECT count(*)
              FROM essentials.office_terms ot
              JOIN essentials.offices o   ON o.id = ot.office_id
              JOIN essentials.districts d ON d.id = o.district_id
             WHERE lower(d.state) = 'co'
               AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
               AND ot.term_start >= make_date(y, 1, 1) AND ot.term_start < make_date(y, 2, 1)) AS rows_in_jan
      FROM unnest(ARRAY[2019, 2021, 2023, 2025]) AS y
  LOOP
    IF cyc.rows_in_jan = 0 THEN
      RAISE EXCEPTION '3d: January % holds no Colorado legislative term at all, so this control has '
                      'lost its fixture and proves nothing. It refuses to report rather than '
                      'passing vacuously.', cyc.y;
    END IF;
    IF cyc.observed = to_char((make_date(cyc.y, 1, 1)
         + ((3 - EXTRACT(dow FROM make_date(cyc.y, 1, 1))::int + 7) % 7) + 7)::date, 'YYYY-MM-DD')
    THEN agree_dflt := agree_dflt + 1; END IF;
    IF cyc.observed = to_char((make_date(cyc.y, 1, 1)
         + ((1 - EXTRACT(dow FROM make_date(cyc.y, 1, 1))::int + 7) % 7) + 7)::date, 'YYYY-MM-DD')
    THEN agree_2nd_mon := agree_2nd_mon + 1; END IF;
  END LOOP;

  -- Over 2019/2021/2023/2025 the default reproduces 2021 and 2025, and the second Monday
  -- reproduces 2023 only; 2027 is this file's own cycle and is counted separately above.
  IF agree_dflt <> 2 THEN
    RAISE EXCEPTION '3d: the statutory default (the second Wednesday) reproduces % of the four prior '
                    'cycles, expected exactly 2 — 2021-01-13 and 2025-01-08, the two cycles in '
                    'which no joint resolution displaced it. It must FAIL in 2019 and 2023, which '
                    'is what makes "the day is designated" a measurement rather than a claim.',
                    agree_dflt;
  END IF;
  IF agree_2nd_mon <> 1 THEN
    RAISE EXCEPTION '3d: the second-Monday rival reproduces % of the four prior cycles, expected '
                    'exactly 1 — 2023-01-09 only. 🔴 THIS GATE IS KEPT GREEN ON PURPOSE AND IT '
                    'RECORDS A RIVAL THAT SURVIVES: the second Monday also gives 2027-01-11, this '
                    'file''s own Group A day, so nothing in 2027 can separate it from the truth, '
                    'and 2027-01-11 already carries % rows under two rule_ids that literally say '
                    '"second-monday-january". What refuses it is 2019-01-04, a FRIDAY, which no '
                    'ordinal-weekday rule can produce — and that day is in HJR18-1021 in words.',
                    agree_2nd_mon, exp_jan11_pre;
  END IF;

  -- 3e. The one in-data control for Group B, asserted to EXIST before it is relied on, and asserted
  --     not to have moved. ⚠ And the absence of any control for the two boards is asserted too.
  SELECT count(*) INTO n
    FROM essentials.office_terms ot
    JOIN essentials.offices o   ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_EXEC' AND ot.term_start IS NOT NULL;
  IF n <> 1 THEN
    RAISE EXCEPTION '3e: Colorado carries % dated state-executive term(s), expected exactly 1 — '
                    'Jared Polis''s Governorship from 2019-01-08, which is the second Tuesday of '
                    'January 2019 and the ONLY in-data corroboration Group B has. A count of 0 '
                    'would make this control vacuous; a count above 1 means a row this file did not '
                    'expect now bears on the rule.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms ot
    JOIN essentials.offices o   ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type = 'STATE_EXEC'
     AND ot.term_start = DATE '2019-01-08';
  IF n <> 1 THEN
    RAISE EXCEPTION '3e: the Colorado Governor''s 2019-01-08 term start is gone or duplicated (% '
                    'rows). That row IS the control for Art. IV § 1(1), so if it moves the clause '
                    'has no in-data corroboration left in this state.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms ot
    JOIN essentials.offices o   ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type IN ('STATE_BOARD', 'STATE_BOARD_EDUCATION')
     AND ot.term_start IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '3e: % Colorado board term(s) now carry a term_start, expected 0. All 8 Regent '
                    'and all 8 Board of Education rows were term_start NULL (CC_0366, from the '
                    'bodies'' own rosters, how_started "unknown"), which is why NEITHER BOARD HAS '
                    'ANY IN-DATA CONTROL and both rest on documentary evidence alone. A new dated '
                    'row would be new evidence and this file''s reasoning should be re-read, not '
                    'routed around.', n;
  END IF;

  -- 3f. No Colorado seat outside this file's 19 carries one of this file's days.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co'
     AND s.swearing_in_date IN (grp_a_day, grp_b_day)
     AND s.office_id NOT IN (SELECT office_id FROM cc0516_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION '3f: % Colorado office(s) outside this file''s 19 carry % or %. This file dates '
                    'nineteen seats and nothing else in the state.', n, grp_a_day, grp_b_day;
  END IF;

  -- 4. The delta on 2027-01-11, which is a THIRD state's arrival on that square, and every row on
  --    it must belong to a NAMED rule so a fourth is caught rather than absorbed.
  SELECT count(*) INTO n FROM essentials.office_swearing_in WHERE swearing_in_date = grp_a_day;
  IF n <> exp_jan11_pre + exp_grp_a THEN
    RAISE EXCEPTION '4: rows on % went % -> %, a delta of %, expected %.',
                    grp_a_day, exp_jan11_pre, n, n - exp_jan11_pre, exp_grp_a;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in
   WHERE swearing_in_date = grp_a_day
     AND rule_id NOT IN ('or-const-art4-s4-second-monday-january',
                         'wa-rcw-44-04-021-second-monday-january',
                         'co-hjr26-1031-convening');
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % row(s) on % belong to a rule this file does not know. That day is shared '
                    'by Oregon (75, its constitution) and Washington (118, RCW 44.04.021) and now '
                    'Colorado (9, HJR26-1031) — three states, three unrelated instruments, and '
                    'TWO of the three rule_ids contain the words "second-monday-january" while '
                    'Colorado''s day is DESIGNATED and merely coincides. Every count about this '
                    'square is a delta and a fourth state must be reported, never absorbed.',
                    n, grp_a_day;
  END IF;

  -- 5. The delta on 2027-01-12. ⚠ AN EMPTY DAY DISCRIMINATES NOTHING AND THIS SAYS SO.
  SELECT count(*) INTO n FROM essentials.office_swearing_in WHERE swearing_in_date = grp_b_day;
  IF n <> exp_grp_b THEN
    RAISE EXCEPTION '5: rows on % went 0 -> %, expected %. Colorado is the FIRST state on that day, '
                    'so this is a count of this file''s own rows and nothing else — a "no '
                    'strangers here" gate on an empty square measures nothing and is not offered '
                    'as a measurement.', grp_b_day, n, exp_grp_b;
  END IF;
  IF b.rows_jan12 <> 0 THEN
    RAISE EXCEPTION '5: % already carried % row(s) before this file. Colorado was the first state '
                    'there, and it no longer is — so the gate above has stopped being a count of '
                    'this file''s own rows.', grp_b_day, b.rows_jan12;
  END IF;

  -- 5b. The near miss is a LIVE DAY in another state, and it must still carry nothing of ours.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0516_sel c ON c.office_id = s.office_id
   WHERE s.swearing_in_date = dflt_day;
  IF n <> 0 THEN
    RAISE EXCEPTION '5b: % of this file''s rows carry %, the STATUTORY DEFAULT this state did not '
                    'use. That day is the Maryland General Assembly''s live start date, so the '
                    'error would hide inside another state''s cluster rather than looking absurd.',
                    n, dflt_day;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_swearing_in WHERE swearing_in_date = dflt_day;
  IF n <> exp_jan13_pre THEN
    RAISE EXCEPTION '5b: % carries % row(s), expected % — the Maryland General Assembly, untouched. '
                    'This file must not add to the day its own statutory default would have '
                    'produced.', dflt_day, n, exp_jan13_pre;
  END IF;

  -- 6. Table totals and the state's own rows.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + exp_total THEN
    RAISE EXCEPTION '6: office_swearing_in went % -> %, a delta of %, expected %.',
                    b.rows_all, n, n - b.rows_all, exp_total;
  END IF;

  -- 🔴🔴 A DELTA, NOT A TOTAL, AND A GATE CAUGHT THE FIRST VERSION BEING A TOTAL. Written as
  --    `n <> exp_total` this read "9 -> 28, expected 19" and failed, because COLORADO ALREADY
  --    CARRIED NINE ROWS FOR THIS VERY ELECTION — the eight U.S. House seats and the U.S. Senate
  --    seat, on 2027-01-03 under U.S. Const. Amend. XX § 1, written by the federal programme.
  --    ▶ `lower(d.state) = 'co'` SELECTS THE FEDERAL TIER TOO, because a U.S. Representative's
  --    district carries its state. Texas's equivalent gate said "the 39 Texas rows that exist
  --    belong to other elections and other tiers" and so never met this: in Colorado the other
  --    tier shares the ELECTION DATE, and only the tier separates them.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_co_this_election + exp_total THEN
    RAISE EXCEPTION '6: Colorado rows for 2026-11-03 went % -> %, a delta of %, expected %. The % '
                    'already there are the FEDERAL tier for the same election — 8 U.S. House seats '
                    'and the U.S. Senate seat on 2027-01-03 under Amend. XX § 1 — so this count is '
                    'a delta and the state filter alone does not separate the two tiers.',
                    b.rows_co_this_election, n, n - b.rows_co_this_election, exp_total,
                    b.rows_co_this_election;
  END IF;

  -- And the nine federal rows are untouched, named by their own tier rather than by subtraction.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND d.district_type LIKE 'NATIONAL%';
  IF n <> 9 THEN
    RAISE EXCEPTION '6: Colorado now carries % federal swearing-in row(s), expected 9 — 8 U.S. '
                    'House seats and the U.S. Senate seat, all on 2027-01-03. This file touches the '
                    'state tier only.', n;
  END IF;

  -- ⚠ VACUOUS BY CONSTRUCTION AND SAID SO: Colorado carries no swearing-in row for any election
  --    other than 2026-11-03, so this arm compares 0 with 0. It is kept because it would stop being
  --    vacuous the moment an earlier or later election is dated, and a reader should not mistake
  --    its green for a measurement.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'co' AND s.election_date <> DATE '2026-11-03';
  IF n <> b.rows_co_all_elections - b.rows_co_this_election THEN
    RAISE EXCEPTION '6: Colorado rows for other elections went % -> %, expected no change. This '
                    'file touches one election.',
                    b.rows_co_all_elections - b.rows_co_this_election, n;
  END IF;

  -- 7. Every row reads back with its group's basis, rule_id and a NULL window_end_date, and the
  --    authority OPENS with its own instrument. 🔴 CHECKED BY POSITION, NEVER BY SUBSTRING — Texas's
  --    assertion 7 asked whether a citation appeared ANYWHERE in the field and was satisfied by the
  --    sentence explaining the distinction it existed to enforce. Three of these four authorities
  --    mention Art. IV § 1(1) or Art. IX somewhere in their body, so a substring test would pass on
  --    any permutation of them.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0516_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.window_end_date IS NULL
     AND s.basis = CASE WHEN c.grp = 'A' THEN 'published' ELSE 'statute' END
     AND s.rule_id = CASE c.grp
                       WHEN 'A'     THEN 'co-hjr26-1031-convening'
                       WHEN 'EXEC'  THEN 'co-const-art4-s1-second-tuesday-january'
                       WHEN 'LTGOV' THEN 'co-const-art4-s1-second-tuesday-january'
                       WHEN 'SBE'   THEN 'co-crs-22-2-105-second-tuesday-january'
                       WHEN 'REG'   THEN 'co-crs-23-20-105-second-tuesday-january' END;
  IF n <> exp_total THEN
    RAISE EXCEPTION '7: % of % rows read back with their group''s basis, their group''s rule_id and '
                    'a NULL window_end_date. 🔴 Group A is `published` and the other four groups '
                    'are `statute`; `estimated` may not seat anybody, so the basis is asserted here '
                    'rather than trusted from the INSERT.', n, exp_total;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0516_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.authority LIKE CASE c.grp
                            WHEN 'A'     THEN 'Colo. Const. Art. V, § 7 with C.R.S. § 2-2-303.5(3)%'
                            WHEN 'EXEC'  THEN 'Colo. Const. Art. IV, § 1(1) (Officers%'
                            WHEN 'LTGOV' THEN 'Colo. Const. Art. IV, § 1(1) — the Lieutenant%'
                            WHEN 'SBE'   THEN 'C.R.S. § 22-2-105(1) (State board of education%'
                            WHEN 'REG'   THEN 'C.R.S. § 23-20-105(2) —%' END;
  IF n <> exp_total THEN
    RAISE EXCEPTION '7: % of % authorities do not OPEN with their own instrument. The Board of '
                    'Education''s must begin "C.R.S. § 22-2-105(1)" — DATES.md cites § 22-2-104(1), '
                    'which is "Offices and positions - nature" and contains no date of any kind — '
                    'and the Regents'' must begin "C.R.S. § 23-20-105(2)", the 1973 transitional '
                    'provision that is the only commencement evidence this state has for that '
                    'body. ⚠ Checked by POSITION because every one of these fields discusses the '
                    'other instruments in its own body, so a substring test passes on any '
                    'permutation of the four.', exp_total - n, exp_total;
  END IF;

  -- 8. This file records dates and seats nobody.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0516_sel c ON c.office_id = t.office_id
   WHERE t.source LIKE '%CC_0516%';
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % term(s) were written. This file records dates and seats nobody — CC_0517 '
                    'seats the nine on % and CC_0518 seats the nine on %.', n, grp_a_day, grp_b_day;
  END IF;

  RAISE NOTICE 'CC_0516 OK — 19 Colorado offices dated across two days and four rule_ids: 9 '
               'legislative seats on % under Art. V § 7 + C.R.S. § 2-2-303.5(3) + HJR26-1031 '
               '(basis PUBLISHED, the first in this pass), and 10 on % — 4 executives and the '
               'LIEUTENANT GOVERNOR under Art. IV § 1(1), 2 Board of Education seats under C.R.S. '
               '§ 22-2-105(1), 3 Regent seats under C.R.S. § 23-20-105(2). 🔴🔴 NINETEEN, NOT THE '
               'LEDGER''S EIGHTEEN: the Lieutenant Governor is DATED AND NOT SEATED, because it has '
               'a 2026 race with SEVEN candidates and ZERO recorded results — the pending set is '
               'four because a RESULT is missing, not because the office has no contest, which '
               'corrects DATES.md''s "it is the ticket case, not a gap". Art. IV § 3 makes the '
               'winner knowable in law (one vote for the pair) and our data records no pairing at '
               'all, so an inferred seating is refused. 🔴🔴 THE LEDGER''S BOARD OF EDUCATION '
               'CITATION IS § 22-2-104(1) AND THAT SECTION HOLDS NO DATE — the five "second '
               'Tuesday" anchors are all in § 22-2-105(1); the quote was right and the number was '
               'not, and the day it produces is unaffected, so nothing mechanical could see it. '
               '🔴🔴🔴 THE DAY IS DESIGNATED, NOT COMPUTED, AND THAT IS WHY NO FORMULA FITS: over '
               'the four prior cycles the statutory default reproduces exactly 2 (2021, 2025) and '
               'the second Monday exactly 1 (2023), and nothing reproduces more. THE SECOND MONDAY '
               'ALSO GIVES 2027-01-11, so in this cycle it is indistinguishable from the truth — '
               'and that square already carried % rows under TWO rule_ids containing the words '
               '"second-monday-january" (Oregon 75, Washington 118). What refuses it is '
               '2019-01-04, a FRIDAY, named in HJR18-1021; HJR22-1025 names 2023-01-09 and our own '
               'rows carry 6 and 37 terms on those two days. 🟢 The resolution also carries its own '
               'control: 28 of 28 printed (day, weekday, date) triples agree with a 1st day of '
               'Monday 2027-01-11 and 0 of 28 with the default. 🟢 And § 2-2-303.5(3)/(4) bound '
               'every lawful designation to [% .. %], so the error is bounded whatever happened. '
               '🔴 THE STATUTORY DEFAULT IS 2027-01-13, THE MARYLAND GENERAL ASSEMBLY''S LIVE DAY '
               '(% rows), so a formula-written file would have landed inside another state''s '
               'cluster. ⚠ 2027-01-12 carried NOTHING before this file, so Colorado is first there '
               'and no "strangers" gate on it discriminates anything. 🔴 A CORRECTION TO '
               'PICKUP.md: Idaho''s Ada County is NOT on 2027-01-11 — that square is Oregon and '
               'Washington alone, and Idaho''s only forward rows are seven executives on '
               '2027-01-04. 🔴🔴 RESULTS GAPS, ONE CERTAIN AND NAMED: State Board of Education '
               'DISTRICT 3 was on the 2026 ballot and has NO RACE ROW OF ANY YEAR — proved three '
               'ways, by § 22-2-105(1)''s 1985+6n arithmetic, by Art. XII § 11''s vacancy rule, and '
               'by the Department''s own release stating Sherri Wright''s term "runs through '
               'January 2027" — so the Board''s cohort is THREE and this file dates TWO. 59 House '
               'seats and 32 Senate seats also have no 2026 winner, and Art. V §§ 3 and 5 put all '
               '65 House seats and 17-18 Senate seats on that ballot. 🟢 THE REGENTS HAVE NO GAP '
               'AT ALL: § 23-20-102(2) partitions nine seats into three cohorts of three, 2002+6n '
               'reaches 2020 so CDs 2, 6 and 7 ran 2021-2027, and the body''s own roster '
               'reconciles on ALL NINE. ⚠ NEITHER BOARD HAS ANY IN-DATA CONTROL — all 16 board '
               'term rows are term_start NULL — so the only in-data corroboration in Group B is '
               'the Governor''s 2019-01-08, asserted to exist and not to have moved.',
               grp_a_day, grp_b_day, exp_jan11_pre, win_lo, win_hi, exp_jan13_pre;
END $$;

COMMIT;
