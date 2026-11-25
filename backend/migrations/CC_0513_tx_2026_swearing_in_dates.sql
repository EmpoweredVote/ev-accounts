-- CC_0513 — Texas: the start dates for the 14 state offices won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- TWO DAYS, THREE RULES, AND THE SPLIT IS THE STATUTE'S OWN EXCLUSION LIST
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-01 (Fri)  Attorney General · Comptroller · Land Commissioner ·
--                     Agriculture Commissioner · Railroad Commissioner  (5)
--                     State Board of Education Districts 2, 5, 6, 7, 9, 13, 14  (7)
--                                                       (12)  Tex. Gov't Code § 601.003(a)
--   2027-01-19 (Tue)  Governor                           (1)  Tex. Const. Art. IV, § 4
--   2027-01-19 (Tue)  Lieutenant Governor                (1)  Tex. Const. Art. IV, § 16(a)
--
-- Sourced 2026-11-22 and RE-READ IN FULL 2026-11-25; the write-up is in
-- backend/data/state-seating-2026/DATES.md § TX. This file writes the dates and seats nobody:
-- CC_0514 seats the twelve, CC_0515 seats the two.
--
-- 🔴🔴 **TWELVE, NOT ELEVEN. DATES.md's PROSE AND PICKUP.md's HANDOFF BOTH SAY "ELEVEN" AND BOTH
--   ARE WRONG** — DATES.md's own table says 5 + 7, which is 12, and 5 + 7 + 2 = 14 is the number
--   every other count in this pass agrees with. Measured in production 2026-11-25: Group A is
--   **12** offices. ▶ The slip matters because "eleven" was one copy of an expectation about to
--   become a gate's literal: a file that dated eleven would have left ONE SEAT UNDATED, and
--   CC_0514's P4 would have refused that seat **after** writing the other eleven's terms. Both
--   documents are corrected in this branch. 🔴 This is CLAUDE.md's *a gate that restates its own
--   expectation as a second literal*, caught one layer earlier — in the prose a gate gets copied
--   from.
--
-- 🟢 **NO PEOPLE FILE, AND TEXAS IS THE SEVENTH SUCH STATE** (after AZ, AL, ID, NM, NE, CT). All
--   14 winner rows carry a politician_id, all 14 are `is_active`, and **none collides with any
--   other row on (full_name) OR on (first_name, last_name)** — swept across the whole
--   `politicians` table, not read off the register's "no record" column, which counts race rows.
--
-- 🟢 **NO RULING A.** Every one of the 14 races is single-seat with exactly one winner, so no
--   office row carries two winners and the winner-to-seat mapping is in the data throughout.
--   ⚠ But see "THE RAILROAD COMMISSION IS STAGGERED" below — Ruling A's *counter-example* shape
--   is present in this state even though its rule is not needed.
--
-- 🔴 **TWELVE OF THE FOURTEEN SEATS CHANGE HANDS**, which ends the run of two all-re-election
--   states (Idaho, Connecticut). Only Tiffany Clark (SBOE 13) and Julie Pickren (SBOE 7) hold the
--   seat they just won. CC_0514's live probe can therefore be read by the NAME again, not only
--   by the date.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- GROUP A — § 601.003(a), AND THE SECTION HAS NO ESCAPE HATCH IN THE WHOLE CHAPTER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Tex. Gov't Code § 601.003 — REGULAR TERM OF STATE, DISTRICT, COUNTY, OR PRECINCT OFFICE**,
-- read in full from the Texas Legislative Council's own publication on 2026-11-25:
--
--   (a) The regular term of an elective state, district, county, or precinct office begins on
--       January 1 of the year following the general election for state and county officers.
--   (b) A person elected to a regular term of office shall qualify and assume the duties of the
--       office on, or as soon as possible after, January 1 of the year following the person's
--       election.
--   (c) This section does not apply to the office of governor, lieutenant governor, state
--       senator, or state representative.
--
-- 🔴 **TERM, NOT OATH, AND THE STATUTE SETTLES IT IN ITS OWN WORDS.** (a) says the term *begins*
--   on January 1; (b) says the officer *qualifies* on or after that day. The statute puts the
--   term start BEFORE the qualification, so the oath is plainly not the date for these twelve.
--   (Contrast Group B, where the term attaches to the installation itself.)
--
-- 🟢🟢 **NO ESCAPE HATCH, MEASURED OVER THE WHOLE CHAPTER.** § 601.003 carries no "unless
--   otherwise provided by law", no "except as provided", nothing. Chapter 601 holds ten sections
--   (601.001–601.009, 601.011) and the ONLY "unless / except as / otherwise provided /
--   notwithstanding" phrases anywhere in it are in § 601.008 (payment of a claim for
--   compensation) and § 601.009 (a candidate must be a registered voter). **Neither touches a
--   commencement.** ▶ The scan's positive control is that the pattern FIRED TWICE while
--   returning nothing about commencement — so "no escape hatch" is a real negative here and not
--   a dead regex. This is the second clause in the pass with no hatch at all, after Connecticut's.
--
-- 🟢 **AND § 601.003(c) IS EVIDENCE THAT THE SECTION GOVERNS THE REST.** A statute that names its
--   own four exceptions is asserting coverage of everything it did not name. The same four-office
--   carve-out recurs verbatim in § 601.005 (the Governor commissions every state officer "other
--   than the governor, the lieutenant governor, a state senator, or a state representative"), so
--   it is a settled pattern in the chapter rather than a one-off.
--
-- ⚠ **Tex. Const. Art. IV, § 23 IS THE CLAUSE A PER-OFFICE SEARCH FINDS, AND IT ANSWERS A
--   DIFFERENT QUESTION:** "The Comptroller of Public Accounts, the Commissioner of the General
--   Land Office, the Attorney General, and any statutory State officer who is elected by the
--   electorate of Texas at large, unless a term of office is otherwise specifically provided in
--   this Constitution, shall each hold office for the term of four years." That is LENGTH, not
--   commencement. The statute supplies the day. ⚠ § 23 also does not reach the State Board of
--   Education at all, whose members are elected **by district** and not "at large".
--
-- 🟢🟢 **THE BOARD OF EDUCATION'S OWN STATUTE CLOSES THE ARITHMETIC — AND THE LEDGER'S CITATION
--   FOR IT IS WRONG.** DATES.md attributes the staggered-terms sentence to **§ 7.103**. It is
--   **Tex. Educ. Code § 7.104 (TERMS)**; § 7.103 is ELIGIBILITY FOR MEMBERSHIP and says nothing
--   about any date. 🔴 The quote was accurate and the section number was not — CLAUDE.md's
--   *a citation can be right about the date and wrong about the law, and nothing measures it*,
--   which is why this file cites § 7.104 and assertion 3f measures the consequence instead of
--   restating the words. § 7.104(a):
--
--     "At each general election immediately following a decennial reapportionment of districts,
--      one member shall be elected to the board from each district. Except as provided by
--      Subsection (b), members of the board serve staggered terms of four years with the terms
--      of eight members expiring on January 1 of one odd-numbered year and the terms of seven
--      members expiring on January 1 of the next odd-numbered year."
--
--   ⚠ That is an EXPIRY, so it corroborates § 601.003 rather than replacing it — the basis for
--   all 12 rows stays § 601.003(a). 🟢 **But it closes an arithmetic that no date source could**:
--   the board holds 15 seats and § 7.104(a) puts **seven** of them on this odd year's boundary.
--   We hold 15 SBOE office rows and exactly **7** are pending for 2026-11-03. The cohort is the
--   right size by the statute's own count, measured independently of the day itself (assertion
--   3f). This is Oregon's "one-half, as nearly as possible — proved arithmetically" in a second
--   state.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- GROUP B — AND ART. IV § 4 DOES NOT DATE THE LIEUTENANT GOVERNOR. § 16(a) DOES.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴🔴 **THE LEDGER PUTS BOTH OFFICES ON "Art. IV § 4 + Gov't Code § 301.001" AND § 4 NAMES ONLY
--   THE GOVERNOR.** Its heading is literally *INSTALLATION OF GOVERNOR; TERM; ELIGIBILITY*, and
--   its sentence is about "The Governor elected at the general election in 1974, and thereafter".
--   The Lieutenant Governor appears nowhere in it. 🔴 **And § 601.003(c) excludes the Lieutenant
--   Governor by name**, so the statute does not reach that office either. Cited as the ledger has
--   it, the Lieutenant Governor's row would carry an authority that, read, is about somebody
--   else — the Washington defect, which no count, digest or view can see. **This is the third
--   instrument the ledger did not have**, after New Mexico's.
--
-- **Tex. Const. Art. IV, § 16(a) — LIEUTENANT GOVERNOR:**
--
--   "There shall also be a Lieutenant Governor, who shall be chosen at every election for
--    Governor by the same voters, in the same manner, CONTINUE IN OFFICE FOR THE SAME TIME, and
--    possess the same qualifications."
--
-- 🟢 **"The same time" is the same TERM, not merely the same four years, and two things prove
--   it rather than argue it.** First, the consequence of the narrow reading is checkable and
--   absurd: if § 16(a) fixed only duration, the Lieutenant Governor would have **no commencement
--   provision anywhere in Texas law** — § 601.003(c) excludes the office, § 4 names only the
--   Governor, and § 23 is both length-only and limited to the Comptroller, Land Commissioner,
--   Attorney General and statutory at-large officers. The office would be undateable, which is
--   Oregon's Governor and Georgia's shape, and Texas is plainly not in it. Second, **Art. IV
--   § 3a presupposes the two offices turn over together**: it speaks of the moment "the
--   Legislature shall canvass the election returns for the offices of Governor and Lieutenant
--   Governor", and says that a Lieutenant-Governor-elect who succeeds to the Governorship "by
--   becoming the Governor … FORFEITS the office of Lieutenant Governor" — a thing only possible
--   if that office is his to forfeit at that same moment.
--
-- 🟢🟢 **AND THE JOURNAL OF THE HOUSE SETTLES IT AS A FACT, NOT AS A READING.** See the 2023
--   cycle below: the two officers were inaugurated at ONE joint session on ONE day, under the
--   heading "INAUGURATION OF THE GOVERNOR AND LIEUTENANT GOVERNOR".
--
-- **Tex. Const. Art. IV, § 4 — INSTALLATION OF GOVERNOR; TERM; ELIGIBILITY:**
--
--   "The Governor elected at the general election in 1974, and thereafter, shall be installed on
--    the FIRST TUESDAY AFTER THE ORGANIZATION OF THE LEGISLATURE, or as soon thereafter as
--    practicable, and shall hold his office for the term of four years, or until his successor
--    shall be duly installed."
--
-- **Tex. Const. Art. III, § 5(a)** leaves the convening to statute — "The Legislature shall meet
-- every two years at such time as may be provided by law" — and **Tex. Gov't Code § 301.001**
-- supplies it:
--
--   "The legislature shall convene at the seat of government in regular session at 12 noon on the
--    SECOND TUESDAY IN JANUARY of each odd-numbered year."
--
-- 🟢 **ORGANIZATION HAPPENS AT THAT MEETING, AND THE STATUTE SAYS SO STRUCTURALLY.** § 301.001 is
--   the first section of Gov't Code ch. 301 **Subchapter A, titled "INITIAL MEETING AND
--   ORGANIZATION"**, and §§ 301.002–301.004 describe organizing the two chambers at it —
--   § 301.002 "WHO MAY ORGANIZE", § 301.003 "PRESIDING OFFICERS" (the secretary of state presides
--   at the organization of the house; the lieutenant governor at the senate's), § 301.004
--   appointing temporary officers "to ensure the organization of the legislature". So "the
--   organization of the Legislature" in Art. IV § 4 is the event § 301.001 dates.
--
-- 🔴 **TERM = INSTALLATION for these two, which is the Oregon/Nevada shape** — the term attaches
--   to a ceremony rather than to a calendar day. Texas is dateable where Oregon's Governor is not
--   **because the ceremony's day is fixed by statute in advance** rather than designated by
--   somebody: § 301.001 is a rule, not an announcement.
--
-- ⚠ **"or as soon thereafter as practicable" is a SOFTENER, NOT A SECOND RULE.** It has not been
--   reached in any cycle checked. If the 2027 installation slips, the published date supersedes
--   this and `basis` becomes `published` — but see "WHAT DOES NOT CORROBORATE" below: nothing
--   published so far is independent of the clause.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE RIVAL RULES — AND ONE OF THEM IS A TAUTOLOGY, NOT A DEFEATED RIVAL
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴🔴 **"THE THIRD TUESDAY IN JANUARY" IS NOT A RIVAL. IT IS THE SAME RULE RESTATED, IN EVERY
--   YEAR.** The second Tuesday always falls on the 8th–14th, so the first Tuesday after it always
--   falls on the 15th–21st, which is always the third Tuesday. **Proved over all 39 odd years
--   1975–2051: they agree 39 times and differ 0.** Press accounts of this election state the rule
--   both ways (see below) and they are both right. ▶ **A file that listed the third Tuesday among
--   the rules its data refuses would be claiming a test it never ran** — the identity cannot be
--   separated by any year, so no control, cycle or in-data row can bear on it. Assertion 3c
--   asserts the identity rather than pretending to break it. This is Connecticut's rival exercise
--   run honestly in the opposite direction: there, listing the rivals found one that SURVIVED;
--   here it finds one that was never a rival.
--
-- **The genuinely separable rivals, all four computed and all four refused (assertion 3d):**
--
--   | rival                                   | 2027       | 2015 (our one row says 2015-01-20) |
--   |-----------------------------------------|------------|------------------------------------|
--   | the convening day itself (2nd Tuesday)  | 2027-01-12 | 2015-01-13  ✗                      |
--   | the first Monday in January             | 2027-01-04 | 2015-01-05  ✗                      |
--   | the third Monday in January             | 2027-01-18 | 2015-01-19  ✗                      |
--   | the first Tuesday in January            | 2027-01-05 | 2015-01-06  ✗                      |
--
-- 🔴🔴 **TWO OF THOSE FOUR WRONG DAYS ARE LIVE TERM STARTS IN THIS DATABASE**, measured
--   2026-11-25: **2027-01-04 carries 241 rows under NINE rule_ids** (Wisconsin, Arizona,
--   California, Idaho — the most crowded square in the pass) and **2027-01-18 carries 13 rows**
--   (Alabama, `al-first-monday-after-second-tuesday-january`). Misreading Art. IV § 4 as naming a
--   Monday lands the Texas Governor inside Alabama's cluster, and misreading Group A as "the
--   first Monday" lands twelve offices inside the other four states'. The convening day
--   (2027-01-12) and the first Tuesday (2027-01-05) carry 0 rows each.
--
-- ⚠ **GROUP A'S RULE IS A FIXED CALENDAR DATE, SO ITS RISK IS NOT ARITHMETIC.** There is no
--   weekday to compute wrongly; "January 1" cannot be mis-stepped. The only way to get Group A
--   wrong is for § 601.003 not to govern — which is what the escape-hatch sweep, the (c)
--   exclusion list and § 7.104's arithmetic are for. ▶ The near-miss gate on 2027-01-04 is still
--   worth running, because **the first Monday is the shape a careless reader would reach for** by
--   analogy with the four other states already sitting there.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE CONTROLS — AND THEY SIT ON THE OPPOSITE GROUP FROM THE ONE YOU WOULD EXPECT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴🔴 **TEXAS HOLDS EXACTLY ONE DATED STATE TERM IN THE WHOLE DATABASE, AND IT CONTROLS GROUP B,
--   NOT GROUP A.** Measured 2026-11-25 across STATE_EXEC, STATE_BOARD_EDUCATION, STATE_UPPER and
--   STATE_LOWER: one `office_terms` row carries a non-null `term_start` — **the Texas Governor,
--   2015-01-20** (Greg Abbott). Everything else is NULL.
--
--   🟢 **It is exact, and it discriminates.** The 84th Legislature convened on 2015-01-13 (the
--     second Tuesday), and the first Tuesday after that is **2015-01-20**. All four separable
--     rivals miss it, each by one to seven days. One row, four rivals, zero survivors — which is
--     a better result than Connecticut got from its one row, where a rival survived.
--
--   🔴 **AND GROUP A HAS NO IN-DATA CONTROL AT ALL.** Not one of the twelve offices — nor any
--     Texas legislative seat — carries a term_start. This inverts the ledger's framing: the group
--     DATES.md presents as simple ("dated by one sentence") is the group our data cannot check,
--     and the group it flags as derived-from-two-documents is the one with an exact control.
--     ▶ **Assertion 3e asserts the absence** rather than leaving it unsaid, in Utah's shape. Group
--     A's corroboration is documentary and structural — the (c) exclusion list, the chapter-wide
--     hatch sweep, and § 7.104's 7-of-15 arithmetic — never numerical.
--
-- 🟢🟢 **THE SECOND CYCLE, FROM A DOCUMENT — AND IT ANSWERS THE LIEUTENANT GOVERNOR TOO.** PICKUP's
--   standing instruction is to kill the surviving rivals with a second cycle from a document.
--   **Journal of the House, 88th Legislature, Regular Session, FOURTH DAY — TUESDAY, JANUARY 17,
--   2023** (Texas Legislative Reference Library, `lrl.texas.gov/scanned/Housejournals/88/
--   01172023_4_191.PDF`, 260,659 bytes, read 2026-11-25):
--
--     • The 88th convened Tuesday 2023-01-10 (the second Tuesday) and the journal numbers
--       2023-01-17 as its **4th Day** — so the installation is one week after the organization,
--       by the book's own day count.
--     • "INAUGURATION OF THE GOVERNOR AND LIEUTENANT GOVERNOR (The House of Representatives and
--       the Senate in Joint Session) … the members of the house reconvened at the north entrance
--       of the Capitol and were joined by the senate in a joint session for the purpose of
--       inaugurating the governor-elect, the Honorable Greg Abbott, and the lieutenant
--       governor-elect, the Honorable Dan Patrick."
--     • "The Honorable Dan Patrick then took the constitutional oath of office as lieutenant
--       governor of the State of Texas" and "The Honorable Greg Abbott took the constitutional
--       oath of office as governor".
--
--   🟢 **ONE DAY, ONE JOINT SESSION, BOTH OFFICERS** — which is § 16(a)'s "continue in office for
--     the same time" as a recorded fact. The computed 2023-01-17 matches the journal exactly.
--   🟢 **And the joint session's own record distinguishes the two groups' KINDS of rule**: on the
--     floor that morning, "the inauguration is always on a Tuesday, NOT A DAY OF THE MONTH BUT A
--     DAY OF THE WEEK." ⚠ It is a remark in a benediction, so it corroborates and does not
--     authorise — but it is on the record of the installation itself, and it is the distinction
--     between Art. IV § 4 (a weekday rule) and § 601.003 (a calendar date) stated by the body.
--
-- ⚠ **WHAT DOES NOT CORROBORATE, AND IT LOOKS LIKE CORROBORATION.** Press accounts of this
--   election carry 2027-01-19 — FOX 7 Austin, read in a browser 2026-11-25: "Hinojosa will
--   officially take office at noon on Tuesday, Jan. 19, 2027 … the state's governor is installed
--   on the third Tuesday in January following a gubernatorial general election." 🔴 **That page
--   names its own source as "the Texas Constitution and previous reporting"** — it is the same
--   clause re-read by somebody else, restated via the tautology above, and it is **not
--   independent evidence**. Counting it would be CLAUDE.md's *the one Oregon date in our own data
--   looks like corroboration and is not*, one step further out. An inaugural committee was
--   announced 2026-11-24; **no official inauguration date publication was found**, so `basis`
--   stays `statute` for all 14 rows and the two completed cycles (2015 in our data, 2023 in the
--   journal) remain the only corroboration.
--
-- ⚠ **NO TEXAS CHAMBER CARRIES AN `inauguration_rules` ROW** — all 59 are NULL, including Texas
--   Governor, Texas Lieutenant Governor, State Board of Education and Railroad Commission. So
--   there was no lead to check and nothing to contradict. Recorded because the recipe says a rule
--   row earns its way in by its own citation; an absent row is cleaner than a bad one.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE RAILROAD COMMISSION IS STAGGERED — RULING A'S COUNTER-EXAMPLE, ALREADY RESOLVED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴🔴 **TEXAS HOLDS THREE `Texas Railroad Commissioner` OFFICE ROWS IN ONE DISTRICT, ALL WITH
--   THE SAME TITLE, ALL HELD — AND ONLY ONE IS UP.** Wayne Christian, Christi Craddick and
--   **Jim Wright**; the 2026 race is attached to Wright's row alone, and Jon Rosenthal won it.
--   This is structurally the **Arizona Corporation Commission** — five identical rows, a
--   staggered body, every interchangeability clause passing — which Ruling A exists to refuse.
--
-- 🟢 **IT NEEDS NO RULING, BECAUSE THE DATA ALREADY DOES THE THING THE RULING ASKS FOR.** The race
--   is single-seat with one winner and is attached to the seat of the member actually leaving,
--   which is CLAUDE.md's existing requirement and the remedy Ruling A prescribes for a staggered
--   body. There is no mapping to invent.
--
-- 🔴 **BUT THE DATING RISK IS REAL AND POINTS THE OTHER WAY FROM MARYLAND'S.** Maryland's lesson
--   is that a Ruling A wave must date the ASSIGNED offices, not the race-carrying ones. Here the
--   danger is the mirror image: a selection that expanded to the sibling rows — "all Railroad
--   Commissioner offices in Texas" — would date **all three**, and the other two commissioners'
--   terms do not begin on 2027-01-01. Their seats were last filled in other cycles and run on.
--   ▶ **This file selects by the pending row and never by title**, and **P5 asserts that exactly
--   one of the three is in the selection and that the other two end the transaction undated.**
--   ⚠ Neither of the other two carries a race row **of any year**, so our data holds no positive
--   evidence of which cycle each is on — Utah's "no race row at all" third class. That is a
--   seeding gap, not a dating one, and this file neither fixes it nor depends on it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE ABSENT BODIES — AND § 601.003(c) NAMES ONE OF THEM IN ADVANCE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴🔴 **TEXAS HOLDS 31 STATE_UPPER AND 150 STATE_LOWER OFFICE ROWS AND ZERO LEGISLATIVE RACES OF
--   ANY YEAR** — 181 seats, measured 2026-11-25. Texas elects all 150 House seats every two
--   years, so the whole House was on this ballot as a matter of law. **This is the largest result
--   gap anywhere in this pass**, and it is a different kind from Utah's: here the offices exist
--   and the *races* are missing.
--
-- 🟢 **AND THE INSTRUMENT THIS WAVE IS DATED ON NAMES THEM.** § 601.003(c) excludes "state
--   senator, or state representative" by name, so the statute itself says in advance that those
--   181 seats **do not take 2027-01-01**. The gap and its rule are both already named. ▶ P6 gates
--   on the absence staying an absence, so the twelve's day cannot leak onto 181 strangers, and
--   assertion 3g re-asserts it after the write. ⚠ When those races are seeded, the legislature
--   needs its OWN rule_id — Art. III § 4 and § 5(a) with § 301.001, not this file's.
--
-- 🟢 **THE SECRETARY OF STATE IS CORRECTLY ABSENT, AND UNLIKE CONNECTICUT'S THAT IS NOT A GAP.**
--   Art. IV § 1 names the Secretary of State among the six officers of the Executive Department,
--   but **§ 2 elects "All the above officers of the Executive Department (EXCEPT Secretary of
--   State)"** — the office is appointed by the Governor under § 21. We hold **no Texas Secretary
--   of State office row at all**, which is right, and it needs no date and no race. Recorded so a
--   later reader does not "fix" it by analogy with Connecticut, where the Secretary of the State
--   IS elected and its absence really is owed a race.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Carried into the rows
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   election_date    2026-11-03 for all 14
--   window_end_date  NULL for all 14 — every day is fixed, none is a window
--   basis            `statute` for all 14 (constitutional or statutory; neither is `estimated`,
--                    and `estimated` may not seat anybody)
--   rule_id          Group A  `tx-govt-code-601-003-january-1`              (12 rows)
--                    Governor `tx-const-art4-s4-installation`               (1 row)
--                    Lt. Gov. `tx-const-art4-s16a-same-time-as-governor`    (1 row)
--
-- ⚠ **THREE rule_ids, not the ledger's two.** The Governor and the Lieutenant Governor share a
--   day and reach it by different instruments, so they are kept apart — Connecticut's warning
--   that two clauses which agree must not be merged by a later reader, applied before the merge
--   can happen. A delta gate on 2027-01-19 must therefore name BOTH Texas rules.
--
-- 🔴 **This file OVERWRITES NOTHING.** No Texas office carries an `office_swearing_in` row for
--   2026-11-03 (P0 asserts it), and the 39 Texas rows that exist belong to other elections and
--   other tiers. No value is replaced, so there is no old value to record.

BEGIN;

-- ── The selection: every office this wave will DATE, with the group it belongs to. ────────────
--
-- 🔴 SELECTED FROM `office_pending_winner`, NEVER BY TITLE. The Railroad Commission's three
--    identical rows are why: a title-based selection dates two commissioners whose terms do not
--    start on this day. The group is decided by § 601.003(c)'s own exclusion list.
-- 🔴 NO SIBLING EXPANSION ANYWHERE IN THIS FILE.
CREATE TEMP TABLE cc0513_sel ON COMMIT DROP AS
SELECT o.id            AS office_id,
       o.title         AS title,
       d.label         AS label,
       d.district_type AS district_type,
       CASE WHEN o.title = 'Texas Governor'             THEN 'GOV'
            WHEN o.title = 'Texas Lieutenant Governor'  THEN 'LTGOV'
            ELSE 'A' END                                AS grp
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'tx'
   AND d.district_type IN ('STATE_EXEC', 'STATE_BOARD_EDUCATION')
   AND w.election_date = DATE '2026-11-03';

-- The three Railroad Commissioner rows, so P5 and assertion 3h can speak about the TWO this file
-- must not touch by name rather than by arithmetic.
-- 🔴 `carries_race` IS THE LOAD-BEARING COLUMN, NOT `in_selection`. A control proved why: a tamper
--    that SWAPS the selected sibling for another leaves every count in this file intact — 14 rows,
--    12 in Group A, 7 Board seats, one of three commissioners selected — so a P5 that only counted
--    to one passed while dating the wrong commissioner. The question is not "how many" but
--    "WHICH", and only the race row answers it.
CREATE TEMP TABLE cc0513_rrc ON COMMIT DROP AS
SELECT o.id AS office_id,
       (o.id IN (SELECT office_id FROM cc0513_sel)) AS in_selection,
       EXISTS (SELECT 1 FROM essentials.races r
                 JOIN essentials.elections e ON e.id = r.election_id
                WHERE r.office_id = o.id AND e.election_date = DATE '2026-11-03') AS carries_race
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'tx' AND o.title = 'Texas Railroad Commissioner';

CREATE TEMP TABLE cc0513_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                            AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'tx' AND s.election_date = DATE '2026-11-03')          AS rows_tx_this_election,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'tx')                                                 AS rows_tx_all_elections,
       -- 🔴🔴 TEXAS IS THE THIRD STATE ON 2027-01-01. The before-image is pinned so assertion 4
       --    is a DELTA and never a total: Utah 50 and New Mexico 11 are already there, under
       --    three rule_ids between them.
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-01')                                  AS rows_jan1,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-19')                                  AS rows_jan19,
       -- the live near-misses
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-04')                                  AS rows_jan4,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-18')                                  AS rows_jan18,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-12')                                  AS rows_jan12,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-05')                                  AS rows_jan5,
       (SELECT count(*) FROM essentials.office_pending_winner w
          JOIN essentials.offices o   ON o.id = w.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'tx' AND w.election_date = DATE '2026-11-03'
           AND d.district_type NOT IN ('STATE_EXEC', 'STATE_BOARD_EDUCATION'))        AS pending_outside;

DO $$
DECLARE n bigint; b record;
BEGIN
  SELECT * INTO b FROM cc0513_before;

  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. On a second
  --      apply the selection is still full (dating does not empty office_pending_winner), so P0
  --      is reachable here — but it is kept first anyway, because in CC_0461/CC_0462 the
  --      equivalent gate sat below a row count and a re-run was reported as "the data moved".
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0513_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n > 0 THEN
    RAISE EXCEPTION 'P0: % of the 14 already carry a swearing-in row for 2026-11-03. This file '
                    'has already been applied, or something else dated these seats. It writes '
                    'nothing twice.', n;
  END IF;

  -- P1 — the selection is the size this file was written for. 🔴🔴 TWELVE AND TWO, NOT ELEVEN AND
  --      TWO: DATES.md's prose and PICKUP.md both say "eleven", and this gate is where that slip
  --      would have surfaced as an undated seat downstream instead.
  SELECT count(*) INTO n FROM cc0513_sel;
  IF n <> 14 THEN
    RAISE EXCEPTION 'P1: the selection holds % offices, expected 14. Re-derive before writing — '
                    'a wave whose size moved is a wave whose pin is stale.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0513_sel WHERE grp = 'A';
  IF n <> 12 THEN
    RAISE EXCEPTION 'P1: Group A holds % offices, expected 12 (5 state executives + 7 State Board '
                    'of Education). ⚠ DATES.md and PICKUP.md both say "eleven" and both are '
                    'wrong; if this gate reports 11 the documents were right and the measurement '
                    'that corrected them was not.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0513_sel WHERE grp IN ('GOV', 'LTGOV');
  IF n <> 2 THEN
    RAISE EXCEPTION 'P1: Group B holds % offices, expected exactly 2 — the Governor and the '
                    'Lieutenant Governor, which are two of the four offices § 601.003(c) '
                    'excludes.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0513_sel WHERE grp = 'A' AND district_type = 'STATE_BOARD_EDUCATION';
  IF n <> 7 THEN
    RAISE EXCEPTION 'P1: % State Board of Education seats are in Group A, expected 7 — Tex. Educ. '
                    'Code § 7.104(a) puts seven of the fifteen on this odd year''s boundary.', n;
  END IF;

  -- P2 — the selection is the WHOLE pending set for Texas. A named-type list silently drops a
  --      body and nothing errors.
  IF b.pending_outside <> 0 THEN
    RAISE EXCEPTION 'P2: % Texas seat(s) are pending for 2026-11-03 outside STATE_EXEC and '
                    'STATE_BOARD_EDUCATION, expected 0. A third body appeared; this file does '
                    'not know its rule.', b.pending_outside;
  END IF;

  -- P3 — single-seat, one winner each. No Ruling A in this state, asserted rather than assumed.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0513_sel c ON c.office_id = w.office_id
   WHERE w.election_date = DATE '2026-11-03' AND (w.winner_count <> 1 OR COALESCE(w.seats, 1) <> 1);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % of the 14 races are not single-seat with exactly one winner. Ruling A '
                    'applies and this file does not implement it.', n;
  END IF;

  -- P4 — every winner exists, is active, and collides with nobody on either key. 🔴 BOTH KEYS:
  --      the duplicate-name trigger keys on (first_name, last_name) and an identical full_name
  --      split differently is invisible to it.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN cc0513_sel c ON c.office_id = w.office_id
    CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
    LEFT JOIN essentials.politicians p ON p.id = (win.value ->> 'id')::uuid
   WHERE w.election_date = DATE '2026-11-03'
     AND (p.id IS NULL OR p.is_active IS NOT TRUE);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % of the 14 winners have no politicians row or are not active. This '
                    'file dates and does not create; a people file is owed first.', n;
  END IF;

  -- P5 — 🔴🔴 THE RAILROAD COMMISSION GATE. Three identical rows, one up. Exactly one may be in
  --      the selection; a sibling expansion would date two commissioners whose terms run on.
  SELECT count(*) INTO n FROM cc0513_rrc;
  IF n <> 3 THEN
    RAISE EXCEPTION 'P5: Texas holds % Railroad Commissioner office rows, expected 3. The body''s '
                    'shape moved and the staggering argument below is about a different body '
                    'now.', n;
  END IF;
  SELECT count(*) INTO n FROM cc0513_rrc WHERE in_selection;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P5: % of the 3 Railroad Commissioner rows are in this file''s selection, '
                    'expected exactly 1. The Commission is STAGGERED — one seat of three is '
                    'elected each cycle — so dating a sibling asserts a term start for a '
                    'commissioner who is not leaving. This is the Arizona Corporation Commission '
                    'shape and it is refused the same way.', n;
  END IF;
  -- 🔴🔴 AND IT MUST BE THE RACE-CARRYING ONE. Counting to one is not the same claim as naming
  --    the right seat: a control that SWAPPED the selected sibling left every count in this file
  --    correct — 14 rows, 12 in Group A, 7 Board seats, one commissioner selected — and dated a
  --    commissioner who is not leaving. CLAUDE.md's *a predicate reads the SHAPE of a value, never
  --    what the value is*, reached through a count.
  SELECT count(*) INTO n FROM cc0513_rrc WHERE in_selection AND NOT carries_race;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: the selected Railroad Commissioner row does NOT carry a 2026 race. The '
                    'count of selected siblings is right and the SEAT is wrong — exactly what a '
                    'count cannot see. Attach the race to the office of the member who is '
                    'actually leaving, and select by that row.';
  END IF;
  SELECT count(*) INTO n FROM cc0513_rrc WHERE carries_race;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P5: % of the 3 Railroad Commissioner rows carry a 2026 race, expected '
                    'exactly 1. If more than one is up, the Commission is not staggered the way '
                    'this file assumes and Ruling A''s equality clause has to be worked.', n;
  END IF;

  -- P6 — 🔴🔴 THE 181 ABSENT LEGISLATIVE SEATS. § 601.003(c) excludes them by name, so this gate
  --      is the statute's own statement turned into a measurement. If a legislative race appears,
  --      this wave is not the wave that should date it.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 181 THEN
    RAISE EXCEPTION 'P6: Texas holds % legislative office rows, expected 181 (31 Senate + 150 '
                    'House). The absent body changed size; re-read DATES.md § TX before '
                    'trusting anything below.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P6: % Texas legislative race row(s) now exist, expected 0 of any year. Those '
                    '181 seats are EXCLUDED from § 601.003 by its own subsection (c) and need '
                    'their own rule_id (Art. III §§ 4, 5(a) with Gov''t Code § 301.001). Do not '
                    'let this file''s day leak onto them.', n;
  END IF;

  -- P7 — the squares have not moved under this file. Every count about either day is a delta.
  IF b.rows_jan1 <> 61 OR b.rows_jan19 <> 0 OR b.rows_jan4 <> 241 OR b.rows_jan18 <> 13
     OR b.rows_jan12 <> 0 OR b.rows_jan5 <> 0 THEN
    RAISE EXCEPTION 'P7: a pinned square moved — 2027-01-01 % (expected 61: Utah 50 + New Mexico '
                    '11), 2027-01-19 % (expected 0: Texas is first there), and the near misses '
                    '2027-01-04 % (expected 241), 2027-01-18 % (expected 13, Alabama), '
                    '2027-01-12 % (expected 0), 2027-01-05 % (expected 0). The deltas below are '
                    'measured against these.',
                    b.rows_jan1, b.rows_jan19, b.rows_jan4, b.rows_jan18, b.rows_jan12, b.rows_jan5;
  END IF;
END $$;

-- ── Group A: twelve offices, 2027-01-01, Tex. Gov't Code § 601.003(a). ────────────────────────
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-01',
       'statute',
       'tx-govt-code-601-003-january-1',
       'Tex. Gov''t Code § 601.003(a) — "The regular term of an elective state, district, county, '
         || 'or precinct office BEGINS ON JANUARY 1 of the year following the general election '
         || 'for state and county officers." The general election was 2026-11-03, so the term '
         || 'begins 2027-01-01 (a Friday). 🔴 TERM, NOT OATH, AND THE STATUTE SAYS SO ITSELF: '
         || '§ 601.003(b) separately provides that the officer "shall qualify and assume the '
         || 'duties of the office on, or as soon as possible after, January 1", which places the '
         || 'qualification AFTER the term start — so the oath is a different event and is not '
         || 'this date. 🟢 NO ESCAPE HATCH, MEASURED OVER THE WHOLE CHAPTER: § 601.003 carries no '
         || 'residual clause, and across all ten sections of ch. 601 the only "unless / except '
         || 'as / otherwise provided / notwithstanding" phrases are in § 601.008 (payment of a '
         || 'claim for compensation) and § 601.009 (a candidate must be a registered voter), '
         || 'neither of which touches a commencement — a real negative, because the scan''s '
         || 'pattern fired twice rather than returning nothing. 🟢 AND SUBSECTION (c) IS ITSELF '
         || 'EVIDENCE THE SECTION GOVERNS THESE TWELVE: it names the only four offices it does '
         || 'not reach — "governor, lieutenant governor, state senator, or state representative" '
         || '— and the same carve-out recurs verbatim in § 601.005, so it is a settled pattern '
         || 'in the chapter. ⚠ Tex. Const. Art. IV § 23 fixes the TERM LENGTH of the Comptroller, '
         || 'Land Commissioner, Attorney General and statutory at-large officers at four years '
         || 'and names no commencement, so it does not answer this question; it also does not '
         || 'reach the State Board of Education, elected by district rather than at large. '
         || '🟢 FOR THE SEVEN BOARD SEATS, Tex. Educ. Code § 7.104(a) corroborates the same '
         || 'boundary: members "serve staggered terms of four years with the terms of eight '
         || 'members EXPIRING ON JANUARY 1 of one odd-numbered year and the terms of seven '
         || 'members expiring on January 1 of the next odd-numbered year" — an expiry, so it '
         || 'corroborates § 601.003 rather than replacing it, and it closes an arithmetic no date '
         || 'source could: the board holds 15 seats, § 7.104(a) puts SEVEN on this odd year''s '
         || 'boundary, and exactly 7 of our 15 Board office rows are pending for this election. '
         || '🔴 DATES.md cites this as § 7.103, which is ELIGIBILITY FOR MEMBERSHIP and names no '
         || 'date; the quote was right and the section number was not.',
       'Texas Legislative Council, "Texas Constitution and Statutes" '
         || '(statutes.capitol.texas.gov), Government Code ch. 601 and Education Code ch. 7, read '
         || 'in full 2026-11-25; the site states its own currency as "current through the 89th '
         || '2nd Called Legislative Session, 2025". ⚠ THE HOST IS A JAVASCRIPT APPLICATION AND '
         || 'SERVES ITS SHELL FOR EVERY PATH WITH HTTP 200 — a soft 404 on everything, including '
         || 'invented paths like /Docs/GV/word/GV.601.doc. Four of five chapter URLs fetched by '
         || 'curl came back BYTE-IDENTICAL (md5 efea928e141b80aab41ab6d59381c80a) while curl '
         || 'reported two different sizes for them, so DATES.md''s "identical byte count is the '
         || 'tell" is not reliable — the md5 of the decompressed body is. Sending the full '
         || 'browser header set changed nothing, because the content is rendered client-side '
         || 'rather than gated; read in a browser instead. Rendered: ch. 601 is 8,723 characters '
         || 'of text, Art. IV is 26,825.',
       'CC_0513 — Texas Group A, 12 of 14. Written 2026-11-25. ⚠ 12, NOT the "eleven" in '
         || 'DATES.md § TX''s prose and PICKUP.md''s handoff; DATES.md''s own table says 5 + 7 '
         || 'and 5 + 7 + 2 = 14. 🔴 NO IN-DATA CONTROL EXISTS FOR THIS GROUP: not one of these '
         || 'twelve offices, and no Texas legislative seat, carries a term_start anywhere in '
         || 'office_terms. The state''s ONE dated term is the Governor''s 2015-01-20, which '
         || 'controls Group B and says nothing about this one — the opposite of the ledger''s '
         || 'framing. This group''s corroboration is documentary and structural only. Texas is '
         || 'the THIRD state on 2027-01-01 (Utah 50, New Mexico 11, under 3 rule_ids).'
  FROM cc0513_sel c
 WHERE c.grp = 'A';

-- ── The Governor: 2027-01-19, Tex. Const. Art. IV, § 4 with Gov't Code § 301.001. ─────────────
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-19',
       'statute',
       'tx-const-art4-s4-installation',
       'Tex. Const. Art. IV, § 4 (INSTALLATION OF GOVERNOR; TERM; ELIGIBILITY) — "The Governor '
         || 'elected at the general election in 1974, and thereafter, shall be installed on the '
         || 'FIRST TUESDAY AFTER THE ORGANIZATION OF THE LEGISLATURE, or as soon thereafter as '
         || 'practicable, and shall hold his office for the term of four years, or until his '
         || 'successor shall be duly installed." Art. III § 5(a) leaves the convening to statute '
         || '("The Legislature shall meet every two years at such time as may be provided by '
         || 'law") and Tex. Gov''t Code § 301.001 supplies it: "The legislature shall convene at '
         || 'the seat of government in regular session at 12 noon on the SECOND TUESDAY IN '
         || 'JANUARY of each odd-numbered year." Second Tuesday of January 2027 = 2027-01-12; the '
         || 'first Tuesday after it = 2027-01-19. 🟢 ORGANIZATION HAPPENS AT THAT MEETING, BY THE '
         || 'STATUTE''S OWN STRUCTURE: § 301.001 opens ch. 301 SUBCHAPTER A, "INITIAL MEETING AND '
         || 'ORGANIZATION", and §§ 301.002–301.004 organize the chambers at it — who may '
         || 'organize, which officer presides at the organization of each house, and temporary '
         || 'officers appointed "to ensure the organization of the legislature". 🔴 TERM = '
         || 'INSTALLATION for this office: the term attaches to the ceremony, which is the '
         || 'Oregon/Nevada shape — but Texas is dateable where Oregon''s Governor is not, because '
         || 'the ceremony''s day is fixed by statute in advance rather than designated by '
         || 'anybody. ⚠ "or as soon thereafter as practicable" is a SOFTENER, NOT A SECOND RULE, '
         || 'and has not been reached in any cycle checked; if the 2027 installation slips, a '
         || 'published date supersedes this and basis becomes published. 🔴🔴 "THE THIRD TUESDAY '
         || 'IN JANUARY" IS NOT A RIVAL READING BUT THE SAME RULE RESTATED — the second Tuesday '
         || 'always falls on the 8th–14th, so the first Tuesday after it always falls on the '
         || '15th–21st, which is always the third Tuesday; proved identical across all 39 odd '
         || 'years 1975–2051. No year, cycle or in-data row can separate them, so this file does '
         || 'NOT claim to have refused it.',
       'Texas Legislative Council, "Texas Constitution and Statutes" '
         || '(statutes.capitol.texas.gov), Tex. Const. Art. IV and Art. III, and Government Code '
         || 'ch. 301, read in a browser 2026-11-25 (the host serves a JavaScript shell with HTTP '
         || '200 for every path, including invented ones — see the Group A rows'' source). '
         || 'SECOND CYCLE, FROM A DOCUMENT: Journal of the House, 88th Legislature, Regular '
         || 'Session, FOURTH DAY — TUESDAY, JANUARY 17, 2023, Texas Legislative Reference Library '
         || '(lrl.texas.gov/scanned/Housejournals/88/01172023_4_191.PDF, 260,659 bytes, read '
         || '2026-11-25): the 88th convened Tuesday 2023-01-10 and the journal numbers 2023-01-17 '
         || 'as its 4th Day, so the installation is one week after the organization by the '
         || 'book''s own day count; "The Honorable Greg Abbott took the constitutional oath of '
         || 'office as governor".',
       'CC_0513 — the Texas Governor, 1 of 14. Written 2026-11-25. 🟢🟢 THE IN-DATA CONTROL IS '
         || 'EXACT AND IT DISCRIMINATES: office_terms carries the Texas Governor''s term starting '
         || '2015-01-20 — the ONLY dated state term in Texas in the whole database — the 84th '
         || 'Legislature convened 2015-01-13 (the second Tuesday), and the first Tuesday after '
         || 'that is 2015-01-20. All four separable rivals MISS it: the convening day itself '
         || '2015-01-13, the first Monday 2015-01-05, the third Monday 2015-01-19, the first '
         || 'Tuesday 2015-01-06. One row, four rivals, zero survivors — a better result than '
         || 'Connecticut got from its one row. 🔴🔴 TWO OF THOSE WRONG DAYS ARE LIVE IN 2027: the '
         || 'first Monday is 2027-01-04 (241 rows, 9 rule_ids — Wisconsin, Arizona, California, '
         || 'Idaho) and the third Monday is 2027-01-18 (13 rows — ALABAMA), so a Monday '
         || 'misreading puts the Texas Governor inside another state''s cluster. ⚠ 2027-01-19 '
         || 'carries NO rows at all before this file, so "no strangers there" is not a '
         || 'measurement and is not offered as one. ⚠ Press accounts carrying 2027-01-19 (FOX 7 '
         || 'Austin, read 2026-11-25) name their own source as "the Texas Constitution and '
         || 'previous reporting" — the same clause re-read, NOT independent corroboration. An '
         || 'inaugural committee was announced 2026-11-24 and no official date publication was '
         || 'found, so basis stays statute.'
  FROM cc0513_sel c
 WHERE c.grp = 'GOV';

-- ── The Lieutenant Governor: 2027-01-19, Tex. Const. Art. IV, § 16(a). ────────────────────────
--
-- 🔴🔴 ITS OWN rule_id AND ITS OWN AUTHORITY, BECAUSE § 4 DOES NOT NAME THIS OFFICE.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-19',
       'statute',
       'tx-const-art4-s16a-same-time-as-governor',
       'Tex. Const. Art. IV, § 16(a) — "There shall also be a Lieutenant Governor, who shall be '
         || 'chosen at every election for Governor by the same voters, in the same manner, '
         || 'CONTINUE IN OFFICE FOR THE SAME TIME, and possess the same qualifications." That '
         || 'ties this term to the Governor''s, which Art. IV § 4 installs on the first Tuesday '
         || 'after the organization of the Legislature — 2027-01-19, the Legislature convening '
         || '2027-01-12 under Gov''t Code § 301.001 (12 noon on the second Tuesday in January of '
         || 'each odd-numbered year). 🔴🔴 ART. IV § 4 IS NOT THIS OFFICE''S AUTHORITY AND MUST '
         || 'NOT BE CITED AS IT: its heading is "INSTALLATION OF GOVERNOR" and its sentence names '
         || 'only "The Governor elected at the general election in 1974, and thereafter". '
         || 'DATES.md § TX puts both offices on "Art. IV § 4 + Gov''t Code § 301.001"; read, that '
         || 'citation is about somebody else, and no count, digest or view could ever see it. '
         || '🔴 Gov''t Code § 601.003(c) excludes "lieutenant governor" by name, so the statute '
         || 'that dates the other twelve does not reach this office either — § 16(a) is the only '
         || 'instrument left, which is why it is the one cited. 🟢 "THE SAME TIME" IS THE SAME '
         || 'TERM, NOT MERELY THE SAME FOUR YEARS, AND TWO THINGS SHOW IT RATHER THAN ARGUE IT. '
         || 'First, the narrow reading has a checkable and absurd consequence: if § 16(a) fixed '
         || 'only duration, this office would have NO commencement provision anywhere in Texas '
         || 'law — § 601.003(c) excludes it, § 4 names only the Governor, and Art. IV § 23 is '
         || 'length-only and limited to the Comptroller, Land Commissioner, Attorney General and '
         || 'statutory at-large officers — so the office would be undateable, which is Oregon''s '
         || 'Governor and Georgia''s shape and Texas is plainly not in it. Second, Art. IV § 3a '
         || 'PRESUPPOSES THE TWO OFFICES TURN OVER TOGETHER: it speaks of the moment "the '
         || 'Legislature shall canvass the election returns for the offices of Governor and '
         || 'Lieutenant Governor", and provides that a Lieutenant-Governor-elect who succeeds to '
         || 'the Governorship "by becoming the Governor … FORFEITS the office of Lieutenant '
         || 'Governor" — which is only possible if that office is his to forfeit at that same '
         || 'moment.',
       'Texas Legislative Council, "Texas Constitution and Statutes" '
         || '(statutes.capitol.texas.gov), Tex. Const. Art. IV §§ 3a, 4, 16, 23 and Government '
         || 'Code ch. 301, read in a browser 2026-11-25. 🟢🟢 AND THE JOURNAL SETTLES IT AS A '
         || 'FACT: Journal of the House, 88th Legislature, Regular Session, FOURTH DAY — TUESDAY, '
         || 'JANUARY 17, 2023, Texas Legislative Reference Library '
         || '(lrl.texas.gov/scanned/Housejournals/88/01172023_4_191.PDF, 260,659 bytes, read '
         || '2026-11-25), under the heading "INAUGURATION OF THE GOVERNOR AND LIEUTENANT '
         || 'GOVERNOR (The House of Representatives and the Senate in Joint Session)": "the '
         || 'members of the house reconvened at the north entrance of the Capitol and were '
         || 'joined by the senate in a joint session for the purpose of inaugurating the '
         || 'governor-elect, the Honorable Greg Abbott, and the lieutenant governor-elect, the '
         || 'Honorable Dan Patrick", and "The Honorable Dan Patrick then took the constitutional '
         || 'oath of office as lieutenant governor of the State of Texas". ONE DAY, ONE JOINT '
         || 'SESSION, BOTH OFFICERS — § 16(a)''s "same time" as a recorded fact rather than a '
         || 'reading.',
       'CC_0513 — the Texas Lieutenant Governor, 1 of 14, and THE THIRD INSTRUMENT THIS LEDGER DID '
         || 'NOT HAVE (after New Mexico''s). Written 2026-11-25. 🔴 Kept on its own rule_id '
         || 'although it shares 2027-01-19 with the Governor, because the two offices reach that '
         || 'day by different instruments — Connecticut''s warning that two clauses which agree '
         || 'must not be merged by a later reader, applied before the merge can happen. A delta '
         || 'gate on 2027-01-19 must name BOTH Texas rules. ⚠ The in-data control (the Governor''s '
         || '2015-01-20 term) is an control for the GOVERNOR''s clause; this office has no dated '
         || 'term of its own in office_terms, and the 2023 journal is what covers it instead. '
         || '⚠ 2027-01-19 carried 0 rows before this file, so no "strangers" gate on that day '
         || 'discriminates anything.'
  FROM cc0513_sel c
 WHERE c.grp = 'LTGOV';

DO $$
DECLARE
  n            bigint;
  b            record;
  jan1         date;
  first_tue    date;
  convenes     date;
  installs     date;
  r_first_mon  date;
  r_third_mon  date;
  r_first_tue  date;
  r_convenes   date;
  -- 🔴 ONE COPY OF EACH EXPECTATION, shared by the condition and its message. Oregon and
  --    Connecticut each shipped a gate whose condition and message held their own copies and
  --    printed a self-contradiction; only a control ever makes those copies disagree.
  grp_a_day    CONSTANT date := DATE '2027-01-01';
  grp_b_day    CONSTANT date := DATE '2027-01-19';
  exp_grp_a    CONSTANT int  := 12;
  exp_grp_b    CONSTANT int  := 2;
  exp_total    CONSTANT int  := 14;
  exp_sboe     CONSTANT int  := 7;
  exp_sboe_all CONSTANT int  := 15;
  exp_leg      CONSTANT int  := 181;
  identity_yrs CONSTANT int  := 39;  -- odd years 1975..2051 where the two statements of § 4 agree
BEGIN
  SELECT * INTO b FROM cc0513_before;

  -- 1. Every one of the 14 carries its group's day, and nothing else does.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0513_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date = CASE WHEN c.grp = 'A' THEN grp_a_day ELSE grp_b_day END;
  IF n <> exp_total THEN
    RAISE EXCEPTION '1: % of % seats carry their group''s day (% for Group A, % for Group B).',
                    n, exp_total, grp_a_day, grp_b_day;
  END IF;

  -- 2. Exactly two distinct dates were written — no more and no fewer. 🔴 ONE STATUTE REALLY DOES
  --    MEAN TWO DAYS HERE, which is not the default either way: Connecticut's one clause meant one
  --    day, Massachusetts' one clause meant three.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s JOIN cc0513_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 2 THEN
    RAISE EXCEPTION '2: % distinct swearing-in dates were written, expected exactly 2 — the '
                    'split is § 601.003(c)''s own exclusion list and nothing else.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0513_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp = 'A' AND s.swearing_in_date = grp_a_day;
  IF n <> exp_grp_a THEN
    RAISE EXCEPTION '2: % of % Group A seats carry %.', n, exp_grp_a, grp_a_day;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0513_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp IN ('GOV','LTGOV')
     AND s.swearing_in_date = grp_b_day;
  IF n <> exp_grp_b THEN
    RAISE EXCEPTION '2: % of % Group B seats carry %.', n, exp_grp_b, grp_b_day;
  END IF;

  -- 3a. 🔴 GROUP A'S DAY, COMPUTED FROM THE ELECTION AND NEVER TYPED. § 601.003(a) is "January 1
  --     of the year following the general election", so the only arithmetic is the year.
  jan1 := make_date(EXTRACT(YEAR FROM DATE '2026-11-03')::int + 1, 1, 1);
  IF jan1 <> grp_a_day THEN
    RAISE EXCEPTION '3a: January 1 of the year following 2026-11-03 computes as %, not %.',
                    jan1, grp_a_day;
  END IF;
  IF EXTRACT(ISODOW FROM jan1)::int <> 5 THEN
    RAISE EXCEPTION '3a: % is not a Friday. Group A''s rule is a FIXED CALENDAR DATE and the '
                    'weekday is incidental — but if this is wrong the calendar itself has moved '
                    'and every comparison below proves nothing.', jan1;
  END IF;

  -- 3b. 🔴 GROUP B'S DAY, COMPUTED WITH "AFTER" IN THE ARITHMETIC. § 301.001 fixes the convening
  --     at the second Tuesday; Art. IV § 4 installs on the first Tuesday AFTER the organization.
  --     The walk starts the day AFTER the convening, so the word "after" is in the computation
  --     and not only in the comment. ISODOW: Mon = 1 … Sun = 7, so Tuesday = 2.
  first_tue := jan1 + ((2 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);
  convenes  := first_tue + 7;
  installs  := (convenes + 1) + ((2 - EXTRACT(ISODOW FROM (convenes + 1))::int + 7) % 7);
  IF EXTRACT(ISODOW FROM convenes)::int <> 2 THEN
    RAISE EXCEPTION '3b: the computed convening day % is not a Tuesday.', convenes;
  END IF;
  IF EXTRACT(ISODOW FROM installs)::int <> 2 THEN
    RAISE EXCEPTION '3b: the computed installation day % is not a Tuesday.', installs;
  END IF;
  IF convenes <> DATE '2027-01-12' THEN
    RAISE EXCEPTION '3b: the second Tuesday in January 2027 computes as %, not 2027-01-12 — '
                    'Gov''t Code § 301.001''s day.', convenes;
  END IF;
  IF installs <> grp_b_day THEN
    RAISE EXCEPTION '3b: the first Tuesday after the organization of the Legislature computes as '
                    '%, not % — Art. IV § 4''s day.', installs, grp_b_day;
  END IF;
  -- 🟢 The clause's own cycle, checked: "The Governor elected at the general election in 1974,
  --    and thereafter". 2026 must sit on that four-year cycle or § 4 does not reach this ballot.
  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1974) % 4 <> 0 THEN
    RAISE EXCEPTION '3b: 2026 is not on Art. IV § 4''s four-year cycle from 1974, so the clause '
                    'does not put the Governor on this ballot at all.';
  END IF;

  -- 3c. 🔴🔴 THE TAUTOLOGY, ASSERTED AS A TAUTOLOGY. "The third Tuesday in January" and "the
  --     first Tuesday after the second Tuesday" are the SAME RULE, in every January — the second
  --     Tuesday always falls on the 8th-14th, so the first Tuesday after it always falls on the
  --     15th-21st. This gate asserts the identity across every odd year 1975-2051 rather than
  --     listing the third Tuesday among the rivals the data refuses, which would be a test this
  --     file never ran. ▶ If this ever fails, the rival table in assertion 3d is incomplete.
  SELECT count(*) INTO n
    FROM generate_series(1975, 2051, 2) AS y(yr)
   WHERE (
           -- the first Tuesday after the second Tuesday
           ((make_date(y.yr,1,1) + ((2 - EXTRACT(ISODOW FROM make_date(y.yr,1,1))::int + 7) % 7)) + 7 + 1)
             + ((2 - EXTRACT(ISODOW FROM
                 ((make_date(y.yr,1,1) + ((2 - EXTRACT(ISODOW FROM make_date(y.yr,1,1))::int + 7) % 7)) + 7 + 1)
                )::int + 7) % 7)
         ) = (
           -- the third Tuesday
           (make_date(y.yr,1,1) + ((2 - EXTRACT(ISODOW FROM make_date(y.yr,1,1))::int + 7) % 7)) + 14
         );
  IF n <> identity_yrs THEN
    RAISE EXCEPTION '3c: "the first Tuesday after the second Tuesday" equals "the third Tuesday" '
                    'in % of the % odd years 1975-2051, expected all %. If they can differ, the '
                    'third Tuesday is a real rival and assertion 3d must refuse it too.',
                    n, identity_yrs, identity_yrs;
  END IF;

  -- 3d. 🔴🔴 THE FOUR SEPARABLE RIVALS, COMPUTED BESIDE THE RIGHT DAY AND EACH ASSERTED TO CARRY
  --     NOTHING OF THIS STATE'S. Two of them are live days in other states, which is what makes
  --     the gate discriminate instead of merely agreeing with the rule it was written from.
  r_convenes  := convenes;
  r_first_mon := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);
  r_third_mon := r_first_mon + 14;
  r_first_tue := first_tue;
  IF r_convenes <> DATE '2027-01-12' OR r_first_mon <> DATE '2027-01-04'
     OR r_third_mon <> DATE '2027-01-18' OR r_first_tue <> DATE '2027-01-05' THEN
    RAISE EXCEPTION '3d: the rival arithmetic is broken — convening day %, first Monday %, third '
                    'Monday %, first Tuesday % (expected 2027-01-12 / 2027-01-04 / 2027-01-18 / '
                    '2027-01-05). Every refusal below proves nothing while this is wrong.',
                    r_convenes, r_first_mon, r_third_mon, r_first_tue;
  END IF;
  IF r_convenes = grp_b_day OR r_first_mon = grp_b_day OR r_third_mon = grp_b_day
     OR r_first_tue = grp_b_day OR r_first_mon = grp_a_day OR r_third_mon = grp_a_day
     OR r_first_tue = grp_a_day OR r_convenes = grp_a_day THEN
    RAISE EXCEPTION '3d: a rival day coincides with one of this file''s days in 2027, so the '
                    'rival test cannot discriminate this cycle. Say so rather than running it.';
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0513_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date IN (r_convenes, r_first_mon, r_third_mon, r_first_tue);
  IF n <> 0 THEN
    RAISE EXCEPTION '3d: % of this file''s rows carry one of the four wrong days — the convening '
                    'day % (0 rows nationally), the first Monday % (241 rows: Wisconsin, '
                    'Arizona, California, Idaho), the third Monday % (13 rows: ALABAMA) or the '
                    'first Tuesday % (0 rows).',
                    n, r_convenes, r_first_mon, r_third_mon, r_first_tue;
  END IF;
  -- 🟢 THE 2015 CYCLE, WHICH IS WHERE THE RIVALS ACTUALLY DIE. Our one dated Texas term is the
  --    Governor's 2015-01-20; all four rivals miss it. This is an in-data refusal, not arithmetic.
  IF ((make_date(2015,1,1) + ((2 - EXTRACT(ISODOW FROM make_date(2015,1,1))::int + 7) % 7)) + 14)
       <> DATE '2015-01-20' THEN
    RAISE EXCEPTION '3d: Art. IV § 4 applied to 2015 computes as %, not the 2015-01-20 our own '
                    'office_terms row carries. The control no longer reproduces the clause.',
                    ((make_date(2015,1,1) + ((2 - EXTRACT(ISODOW FROM make_date(2015,1,1))::int + 7) % 7)) + 14);
  END IF;

  -- 3e. 🔴🔴 THE CONTROL IS ONE ROW, IT SITS ON GROUP B, AND GROUP A HAS NONE — ASSERTED, NOT
  --     LEFT UNSAID. Utah's shape: an unavailable check is a finding, recorded beside the ones
  --     that passed.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND t.term_start IS NOT NULL
     AND d.district_type IN ('STATE_EXEC','STATE_BOARD_EDUCATION','STATE_UPPER','STATE_LOWER');
  IF n <> 1 THEN
    RAISE EXCEPTION '3e: Texas carries % dated state term(s), expected exactly 1 — the Governor''s '
                    '2015-01-20, which is the ONLY in-data control this state has. If this grew, '
                    'a second control exists and should be read before trusting this file; if it '
                    'shrank, Group B has none either.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0513_sel c ON c.office_id = t.office_id
   WHERE t.term_start IS NOT NULL AND c.grp = 'A';
  IF n <> 0 THEN
    RAISE EXCEPTION '3e: % of the 12 Group A offices now carry a dated term, expected 0. Group A '
                    'has NO in-data control — that absence is this assertion''s whole point, and '
                    'a row appearing means one now exists and should be used.', n;
  END IF;

  -- 3f. 🟢 THE BOARD OF EDUCATION'S OWN ARITHMETIC, CLOSED. Educ. Code § 7.104(a): 15 seats,
  --     seven expiring on January 1 of this odd year. Independent of any date source.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND d.district_type = 'STATE_BOARD_EDUCATION';
  IF n <> exp_sboe_all THEN
    RAISE EXCEPTION '3f: Texas holds % State Board of Education office rows, expected % — '
                    'Educ. Code § 7.104(a) describes a fifteen-member board and the 8/7 split '
                    'is measured against that total.', n, exp_sboe_all;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0513_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.district_type = 'STATE_BOARD_EDUCATION'
     AND s.swearing_in_date = grp_a_day;
  IF n <> exp_sboe THEN
    RAISE EXCEPTION '3f: % of % Board seats carry %. § 7.104(a) puts SEVEN of the fifteen on this '
                    'odd year''s January 1 boundary, and seven is what was pending — the cohort '
                    'is the right size by the statute''s own count.', n, exp_sboe, grp_a_day;
  END IF;

  -- 3g. 🔴🔴 THE 181 ABSENT LEGISLATIVE SEATS, RE-ASSERTED AFTER THE WRITE. § 601.003(c) excludes
  --     them by name, so this file's day must not have reached them.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND d.district_type IN ('STATE_UPPER','STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION '3g: % Texas legislative seat(s) now carry a swearing-in row, expected 0. '
                    'Those % offices are EXCLUDED from § 601.003 by its own subsection (c) and '
                    'this file must not have reached them.', n, exp_leg;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE s.rule_id IN ('tx-govt-code-601-003-january-1', 'tx-const-art4-s4-installation',
                       'tx-const-art4-s16a-same-time-as-governor')
     AND (lower(d.state) <> 'tx'
          OR d.district_type NOT IN ('STATE_EXEC','STATE_BOARD_EDUCATION'));
  IF n <> 0 THEN
    RAISE EXCEPTION '3g: % row(s) outside Texas''s two pending bodies carry one of this file''s '
                    'three rule_ids.', n;
  END IF;

  -- 3h. 🔴🔴 THE RAILROAD COMMISSION, AFTER THE WRITE. Two of the three must END THIS TRANSACTION
  --     UNDATED. This is the gate a sibling expansion would trip, and the Arizona Corporation
  --     Commission is the counter-example it is modelled on.
  SELECT count(*) INTO n
    FROM cc0513_rrc r
    JOIN essentials.office_swearing_in s ON s.office_id = r.office_id
                                       AND s.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '3h: % of the 3 Texas Railroad Commissioner rows now carry a swearing-in row '
                    'for this election, expected exactly 1. The Commission is staggered — one '
                    'seat of three per cycle — so the other two commissioners'' terms do not '
                    'begin on % and must not be dated here.', n, grp_a_day;
  END IF;

  -- 3i. 🟢 THE SECRETARY OF STATE IS CORRECTLY ABSENT, AND UNLIKE CONNECTICUT'S THAT IS NOT A GAP.
  --     Art. IV § 1 names the office; § 2 elects every executive EXCEPT it; § 21 has the Governor
  --     appoint it. Recorded so a later reader does not "fix" it by analogy with Connecticut.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND o.title ILIKE '%secretary of state%';
  IF n <> 0 THEN
    RAISE EXCEPTION '3i: Texas now holds % Secretary of State office row(s), expected 0 — the '
                    'office is APPOINTED under Art. IV § 21 and expressly excepted from election '
                    'by Art. IV § 2, so it needs no race and no date. If a row now exists, '
                    'decide deliberately whether it belongs in an elected-office tier at all.', n;
  END IF;

  -- 4. 🔴🔴 2027-01-01 IS A SHARED SQUARE, SO THIS IS A DELTA THAT NAMES THE OTHER STATES' RULES.
  --    A gate counting rows on that day would read 73 and call it success.
  SELECT count(*) INTO n FROM essentials.office_swearing_in WHERE swearing_in_date = grp_a_day;
  IF n - b.rows_jan1 <> exp_grp_a THEN
    RAISE EXCEPTION '4: rows on % went % -> %, a delta of %, expected %.',
                    grp_a_day, b.rows_jan1, n, n - b.rows_jan1, exp_grp_a;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in
   WHERE swearing_in_date = grp_a_day
     AND rule_id NOT IN ('tx-govt-code-601-003-january-1',
                         'nm-22-3b-3-january-1-next-succeeding',
                         'nm-const-art5-1-first-day-of-january',
                         'ut-const-art6-first-day-january');
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % row(s) on % belong to a rule this file does not know. The day is shared '
                    'by THREE states under unrelated instruments — Utah (50) and New Mexico (11) '
                    'were already here — so a fourth must be caught rather than absorbed.',
                    n, grp_a_day;
  END IF;

  -- 5. 2027-01-19 was EMPTY before this file. ⚠ A GATE ON AN EMPTY DAY DISCRIMINATES NOTHING, so
  --    this asserts the delta and says plainly that the "no strangers" half proves nothing yet.
  SELECT count(*) INTO n FROM essentials.office_swearing_in WHERE swearing_in_date = grp_b_day;
  IF n - b.rows_jan19 <> exp_grp_b THEN
    RAISE EXCEPTION '5: rows on % went % -> %, a delta of %, expected %.',
                    grp_b_day, b.rows_jan19, n, n - b.rows_jan19, exp_grp_b;
  END IF;
  IF b.rows_jan19 <> 0 THEN
    RAISE EXCEPTION '5: % already carried % row(s) before this file. Texas was the first state '
                    'there, and that is what made the rule_id check below a tautology; it is one '
                    'no longer, so name the other state''s rule.', grp_b_day, b.rows_jan19;
  END IF;
  SELECT count(DISTINCT rule_id) INTO n
    FROM essentials.office_swearing_in WHERE swearing_in_date = grp_b_day;
  IF n <> 2 THEN
    RAISE EXCEPTION '5: % carries % distinct rule_id(s), expected exactly 2 — the Governor''s '
                    'Art. IV § 4 and the Lieutenant Governor''s Art. IV § 16(a). They share a '
                    'day and reach it by different instruments, and must not be merged.',
                    grp_b_day, n;
  END IF;

  -- 6. The table grew by exactly 14, and Texas's own rows for this election went 0 -> 14.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n - b.rows_all <> exp_total THEN
    RAISE EXCEPTION '6: office_swearing_in went % -> %, a delta of %, expected %.',
                    b.rows_all, n, n - b.rows_all, exp_total;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND s.election_date = DATE '2026-11-03';
  IF n - b.rows_tx_this_election <> exp_total THEN
    RAISE EXCEPTION '6: Texas rows for 2026-11-03 went % -> %, a delta of %, expected %.',
                    b.rows_tx_this_election, n, n - b.rows_tx_this_election, exp_total;
  END IF;
  -- ⚠ Texas already held 39 swearing-in rows for OTHER elections and other tiers. They are
  --   untouched, and this asserts it — a total would have hidden it.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'tx' AND s.election_date <> DATE '2026-11-03';
  IF n <> b.rows_tx_all_elections - b.rows_tx_this_election THEN
    RAISE EXCEPTION '6: Texas rows for other elections went % -> %, expected no change. This file '
                    'overwrites nothing.', b.rows_tx_all_elections - b.rows_tx_this_election, n;
  END IF;

  -- 7. Every row reads back with basis `statute` and one of the three rule_ids. 🔴 `estimated` may
  --    not seat anybody, so the basis is asserted here rather than trusted from the INSERT.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0513_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.basis = 'statute'
     AND s.window_end_date IS NULL
     AND s.rule_id = CASE c.grp WHEN 'A'     THEN 'tx-govt-code-601-003-january-1'
                                WHEN 'GOV'   THEN 'tx-const-art4-s4-installation'
                                WHEN 'LTGOV' THEN 'tx-const-art4-s16a-same-time-as-governor' END;
  IF n <> exp_total THEN
    RAISE EXCEPTION '7: % of % rows read back with basis statute, a NULL window_end_date and '
                    'their own group''s rule_id.', n, exp_total;
  END IF;
  -- 🔴🔴 AND EACH GROUP B OFFICE'S AUTHORITY MUST OPEN WITH ITS OWN INSTRUMENT. This is the only
  --   mechanical trace the Washington distinction leaves — the defect is otherwise invisible to
  --   every count, digest and view, because the DATE is right either way.
  --   🔴 CHECKED BY POSITION, NOT BY SUBSTRING, AND A CONTROL IS WHY. The first version asked
  --   whether the Lieutenant Governor's authority contained '§ 16(a)' ANYWHERE. It does — twice,
  --   because the text goes on to explain that § 4 names only the Governor. So the control that
  --   swapped the OPENING citation to '§ 4' left the gate green: the mention in the explanation
  --   satisfied it. ▶ **A citation is the instrument a row is dated UNDER, which is a claim about
  --   the front of the field, not about whether a string occurs in it.**
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0513_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.authority LIKE CASE c.grp
                            WHEN 'A'     THEN 'Tex. Gov''t Code § 601.003(a)%'
                            WHEN 'GOV'   THEN 'Tex. Const. Art. IV, § 4 (INSTALLATION%'
                            WHEN 'LTGOV' THEN 'Tex. Const. Art. IV, § 16(a) —%' END;
  IF n <> exp_total THEN
    RAISE EXCEPTION '7: % of % authorities do not OPEN with their own instrument. The Lieutenant '
                    'Governor''s must begin "Tex. Const. Art. IV, § 16(a)" — Art. IV § 4 installs '
                    'the GOVERNOR and names that office nowhere, and § 601.003(c) excludes it, so '
                    '§ 16(a) is the only instrument that dates it. ⚠ Checked by POSITION because '
                    'a substring check passes on the sentence that EXPLAINS the distinction: the '
                    'text mentions § 16(a) again while saying § 4 does not apply. A citation can '
                    'be right about the date and wrong about the law, and this is the only gate '
                    'that sees it.', exp_total - n, exp_total;
  END IF;

  -- 8. This file records dates and seats nobody.
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN cc0513_sel c ON c.office_id = t.office_id
   WHERE t.source LIKE '%CC_0513%';
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % term(s) were written. This file records dates and seats nobody — '
                    'CC_0514 seats the twelve and CC_0515 seats the two.', n;
  END IF;

  RAISE NOTICE 'CC_0513 OK — 14 Texas offices dated: % Group A on % under Gov''t Code '
               '§ 601.003(a), the Governor on % under Const. Art. IV § 4 with Gov''t Code '
               '§ 301.001, and the Lieutenant Governor on the same day under Art. IV § 16(a). '
               '🔴🔴 TWELVE IN GROUP A, NOT THE "ELEVEN" IN DATES.md AND PICKUP.md — 5 + 7, and '
               '5 + 7 + 2 = 14. 🔴🔴 ART. IV § 4 NAMES ONLY THE GOVERNOR, so the Lieutenant '
               'Governor carries its own rule_id and its own authority; § 601.003(c) excludes '
               'that office too, leaving § 16(a) ("continue in office for the same time") as the '
               'only instrument, corroborated by Art. IV § 3a''s forfeiture clause and settled by '
               'the 2023 House Journal, which inaugurated both officers at ONE joint session. '
               '🔴🔴 "THE THIRD TUESDAY" IS THE SAME RULE RESTATED, identical in all % odd years '
               '1975-2051, so it is asserted as an identity and NOT claimed as a refuted rival. '
               'The four separable rivals were computed and refused, and TWO ARE LIVE DAYS: the '
               'first Monday % (% rows) and the third Monday % (% rows, Alabama); the convening '
               'day % and the first Tuesday % carry none. 🔴 THE ONE IN-DATA CONTROL IS THE '
               'GOVERNOR''S 2015-01-20 AND IT CONTROLS GROUP B — GROUP A HAS NONE AT ALL, which '
               'inverts the ledger''s framing and is asserted rather than left unsaid; Group A '
               'rests on § 601.003(c)''s exclusion list, a chapter-wide escape-hatch sweep that '
               'came back empty with its pattern firing twice elsewhere, and § 7.104(a)''s '
               'arithmetic (7 of 15 Board seats, and 7 is what was pending). ⚠ DATES.md cites '
               'that as § 7.103, which is ELIGIBILITY and names no date. 🔴 THREE Railroad '
               'Commissioner rows exist and only ONE was dated — the body is staggered, Arizona''s '
               'Corporation Commission shape, and a sibling expansion would have dated two '
               'commissioners who are not leaving. 🔴 181 legislative offices carry 0 races of any '
               'year and § 601.003(c) excludes them BY NAME, so the gap and its rule are both '
               'already named; they need their own rule_id when seeded. 🟢 The Secretary of State '
               'is correctly absent — appointed under Art. IV § 21 — unlike Connecticut''s, so it '
               'is not a gap. Texas is the THIRD state on % (Utah 50, New Mexico 11) and the '
               'FIRST on %, which is why no "strangers" gate on the latter discriminates anything '
               'yet. ⚠ Press accounts of 2027-01-19 derive from the same clause and are NOT '
               'independent corroboration; basis stays statute for all 14.',
               exp_grp_a, grp_a_day, grp_b_day, identity_yrs,
               r_first_mon, b.rows_jan4, r_third_mon, b.rows_jan18, r_convenes, r_first_tue,
               grp_a_day, grp_b_day;
END $$;

COMMIT;
