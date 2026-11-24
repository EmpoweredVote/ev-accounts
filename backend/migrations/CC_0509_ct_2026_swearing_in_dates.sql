-- CC_0509 — Connecticut: the start date for the 5 state executive offices won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE WEDNESDAY FOLLOWING THE FIRST MONDAY OF JANUARY — 2027-01-06
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-06  Governor · Lieutenant Governor · Treasurer · Comptroller ·
--               Attorney General                              (5)  Conn. Const. art. IV, § 2
--
-- ONE clause, ONE day, ONE body. Sourced 2026-11-23 and re-read in full 2026-11-24; the write-up
-- is in backend/data/state-seating-2026/DATES.md § CT. This file writes the dates and seats
-- nobody: CC_0510 seats.
--
-- 🟢 **NO PEOPLE FILE AND NO RULING A.** All 5 winner rows already carry a politician_id, all 5
--   rows are active, and none collides with another row on (full_name) or on
--   (first_name, last_name) — swept across the whole table, not read off the "no record" column.
--   Every race is single-seat with exactly one winner.
--
-- 🔴🔴 **AND ALL FIVE ARE RE-ELECTIONS — IDAHO'S SHAPE, A SECOND TIME.** Ned Lamont, Susan
--   Bysiewicz, Erick Russell, Sean Scanlon and William Tong each hold the seat they have just
--   won. **No Connecticut seat changes hands**, so the current-holder map is unchanged, the
--   winner map is identical to it, and a file that wrote nothing at all would pass every "who
--   holds this seat?" check. CC_0510's header says what that costs the live probe.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE AUTHORITY — TWO SECTIONS, AND THE SECOND ONE HAS NO ESCAPE HATCH AT ALL
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Conn. Const. art. IV, § 2** — *Terms of officers*, quoted in full because it is one sentence:
--
--     "Such officers shall hold their respective offices FROM THE WEDNESDAY FOLLOWING THE FIRST
--      MONDAY OF THE JANUARY NEXT SUCCEEDING THEIR ELECTION until the Wednesday following the
--      first Monday of the fifth January succeeding their election and until their successors
--      are duly qualified."
--
-- **Conn. Const. art. IV, § 1** — *State officers, election date* — supplies "such officers":
--
--     "A general election for GOVERNOR, LIEUTENANT-GOVERNOR, SECRETARY OF THE STATE, TREASURER,
--      COMPTROLLER AND ATTORNEY GENERAL shall be held on the Tuesday after the first Monday of
--      November, 1974, and quadrennially thereafter."
--
--   1. **It names six offices and we hold six office rows**, matching on the word. ⚠ Only FIVE
--      are dated here; the sixth, the Secretary of the State, has no 2026 result and is handled
--      below.
--   2. **It fixes the day by FORMULA, not by choice** — the Georgia distinction, where
--      `O.C.G.A. § 45-12-2` lets the legislature *appoint* a day inside a week and an agreeing
--      row therefore proves nothing.
--   3. **It states the cycle, and the cycle checks out**: 2026 − 1974 = 52, divisible by four, so
--      all six were on the 2026 ballot as a matter of law. That is what turns the Secretary of
--      the State's missing result from "probably missing" into "certainly missing".
--
-- The first Monday of January 2027 is the 4th (2027-01-01 is a Friday), so the Wednesday
-- following it is **2027-01-06**. Computed in assertion 3a, never typed.
--
-- 🟢🟢 **§ 2 CARRIES NO RESIDUAL CLAUSE — NOT "UNLESS OTHERWISE PROVIDED BY LAW", NOT "EXCEPT AS
--   OTHERWISE PROVIDED IN THIS CONSTITUTION", NOTHING.** It is the first clause in this pass with
--   no escape hatch to discharge, and that is a stronger position than either of the last two
--   states: Nebraska's Art. XVII-5 yields to "this Constitution or … law" (the wide form) and New
--   Mexico's Art. V § 1 yields to the constitution alone (the narrow one). A constitutional
--   clause that excepts nothing cannot be displaced by a statute, **so no statute sweep was owed
--   here** — the clause's own full stop is the answer to "how far did you look?".
--
-- ▶ **The constitution was still swept, because another CONSTITUTIONAL provision could displace
--   it.** Bounded by the document's own structure rather than by a list of guesses
--   (`CLAUDE.md`: *bound a parse by the document's own structure, never by a blacklist*): the
--   codified constitution is **14 articles and 88 section headings**, every heading listed, and
--   every occurrence of "Wednesday" and of every commencement verb read. **Four instruments name
--   a term or a sitting; none displaces § 2 and all four land on the same day:**
--
--     art. III § 2   the General Assembly's REGULAR SESSION convenes          2027-01-06
--     art. III § 10  LEGISLATORS' terms begin                                 2027-01-06
--     art. IV  § 2   the six EXECUTIVES' terms begin — this file              2027-01-06
--     art. V   § 4   PROBATE JUDGES' terms, "from and after the Wednesday
--                    after the first Monday of the next succeeding January"   2027-01-06
--
--   And the whole document contains exactly **three** "unless otherwise / except as provided"
--   phrases — art. I § 8(10) (victims' rights), art. XI § 2 (compensation of elected officials)
--   and art. XIII § 3 (when an amendment takes effect). **Not one of them touches a term's
--   commencement.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE PDF CONTAINS ARTICLE FOURTH TWICE AND THE SUPERSEDED 1965 VERSION COMES FIRST
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- This is the trap of the state, and stopping at the first heading manufactures a finding.
--
--   line 2006  the 1965 constitution AS ADOPTED — art. IV § 1 names governor,
--              lieutenant-governor, secretary of the state, treasurer AND COMPTROLLER: **five**,
--              🔴 **with no attorney general**, under a footnote reading only
--              "1 Amended by Article I., of the Amendments".
--   line 7478  *CODIFIED CONSTITUTION … INCORPORATING ALL EXTANT AMENDMENTS* — the same five
--              **and attorney general**: six, with the Historical Note that Article I. was
--              adopted on November 25, 1970 and required an attorney general from November 1974.
--
-- 🔴 **Reading the first copy gives a five-officer list and an Attorney General covered by
--   nothing** — precisely the shape of South Dakota's *real* missing-office finding two states
--   earlier. The same reading that was correct there would have been a fabrication here, and the
--   only thing separating them is which copy of the article you landed on. ▶ **Search for the
--   LAST occurrence of an article heading in a document that carries amendments, or for the word
--   CODIFIED.**
--
-- 🔴🔴 **AND THE CHECK YOU WOULD NATURALLY RUN IS BLIND TO WHICH COPY YOU HAVE.** The 1965 § 1
--   anchors its quadrennial cycle on **1966** and the codified § 1 on **1974**. 2026 − 1966 = 60
--   and 2026 − 1974 = 52, and **both are divisible by four** — so the cycle test passes on the
--   superseded text, with five officers, and says nothing. **Only the officer LIST
--   discriminates.** Assertion 3f therefore asserts the membership, not the cycle alone.
--
-- 🟢 **The two-version structure then pays for itself.** § 2 — the clause this file is dated on —
--   is **byte-identical in both copies**: the four body lines hash to
--   18dbc127bad96f8fdbb0340b6c215d3d8f0c54a1d0bd733f36df1b3a5898bc87 on each side. That is direct
--   evidence the term clause has never been amended, and it is stronger than the absence of a
--   footnote.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE CONTROL IS ONE ROW, ONE RIVAL SURVIVES IT, AND A DOCUMENT IS WHAT KILLS THAT RIVAL
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Connecticut holds exactly **one** dated state term: Ned Lamont's Governorship, **2019-01-09**,
-- and its own `source` derives it from the Governor's biography and the NGA — *"first day in
-- office"* — not from art. IV § 2. 🟢 **So the control is independent of the clause it tests**,
-- which is `CLAUDE.md`'s *derive the control independently of the data under test*. The other
-- four offices carry no `term_start` at all (the ADR 0002 phase-2 backfill).
--
-- ▶ **LIST WHAT ELSE AGREES WITH THE IN-DATA CONTROL.** Six rival rules were computed beside the
-- clause across three cycles:
--
--   rule                                              2019        2023        2027
--   art. IV § 2 — Wednesday FOLLOWING the first Mon   2019-01-09  2023-01-04  2027-01-06
--   the FIRST Wednesday in January                    2019-01-02  2023-01-04  2027-01-06  ⚠ =2027
--   the SECOND Wednesday in January                   2019-01-09  2023-01-11  2027-01-13  ⚠ =2019
--   first Wed AFTER the first Tuesday (MAINE's rule)  2019-01-02  2023-01-04  2027-01-06  ⚠ =2027
--   the first MONDAY in January                       2019-01-07  2023-01-02  2027-01-04
--   "from and AFTER" read as the next day             2019-01-10  2023-01-05  2027-01-07
--   the THIRD Wednesday in January                    2019-01-16  2023-01-18  2027-01-20
--
-- 🔴🔴 **NEITHER CYCLE SEPARATES THE CLAUSE ON ITS OWN, AND BOTH TOGETHER DO.** 2019 kills five
--   rivals and leaves **the second Wednesday** standing — which gives **2027-01-13**, a week
--   late, onto a square that already holds **178 live Maryland rows**. 2023 kills the second
--   Wednesday and leaves **two** standing — the first Wednesday and Maine's rule — which give
--   2027-01-06, the right answer for the wrong reason. **The intersection is empty: no rival
--   survives both.** Assertion 3d measures exactly that — 1 survivor of 2019, 2 survivors of
--   2023, 0 of both — so the claim is a count and not a paragraph.
--
-- 🟢🟢 **THE SECOND CYCLE IS A DOCUMENT, BECAUSE OUR DATA HAS NO SECOND ROW.** This is Nebraska's
--   lesson one state later: *a wrong rule can be right in the cycle you are writing, and then
--   nothing in your own data can refuse it.* Here the wrong rule is right in the cycle the
--   **control** sits in, which is the same trap seen from the other end. The tie-break is the
--   **Journal of the Senate of Connecticut for Wednesday, January 4, 2023**, whose first sentence
--   reads *"On Wednesday after the first Monday of January A.D. 2023, the date by the
--   Constitution of the State of Connecticut for the meeting of the General Assembly, the Senate
--   convened"* — and which records, that same day, the **Oath of Office administered to
--   Lieutenant Governor Susan Bysiewicz**, one of the six officers art. IV § 1 names. The second
--   Wednesday of January 2023 was the 11th.
--
-- 🟢 **AND THE JOURNAL SETTLES THE WORDING TOO.** It writes *"Wednesday **after** the first
--   Monday"* where art. III § 2 writes *"Wednesday **following** the first Monday"*, and
--   art. III § 10 uses **both words in one sentence** — "from the Wednesday FOLLOWING the first
--   Monday … until the Wednesday AFTER the first Monday of the third January". So the two
--   phrasings are the same rule in this document's own voice, which is what lets art. V § 4's
--   "Wednesday after" be read as the same formula rather than as a seventh rival.
--
-- ⚠ **ONE in-data row is one row.** It counts for more than Georgia's did, because art. IV § 2
--   names a formula with one answer per cycle rather than a choice — but the honest claim is
--   *one row plus one journal*, and assertion 3d refuses to report if the row is gone.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 CONNECTICUT IS THE THIRD STATE ON 2027-01-06, AND MAINE'S RULE IS NEARLY THIS SENTENCE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Measured 2026-11-24, before this file: **200 rows already carry 2027-01-06**, under two rules —
--
--   ma 199   ma-const-amend-64-s1-legislators                        (Massachusetts legislators)
--   me   1   me-const-art5-pt1-s2-first-wed-after-first-tue-january  (the Maine Governor)
--
-- 🔴 A gate reading the total would see **205** after this file and call it success. P5 pins the
--   before-image, assertion 4 asserts the delta is exactly 5, and every row on the day must
--   belong to a **NAMED** rule_id, so a fourth state is caught rather than absorbed.
--
-- 🔴🔴 **AND MAINE'S IS NOT A DISTANT RULE — IT IS THE OTHER ONE THAT SURVIVES 2023.** *The first
--   Wednesday after the first Tuesday* and *the Wednesday following the first Monday* agree in
--   every year January 1st is not a Tuesday, which is why Maine's single row sits on this square
--   at all. **Two states, one calendar day, two unrelated clauses, and nearly one sentence.** They
--   part in 2019 (Maine's gives January 2nd), and that is the only reason the in-data control can
--   tell them apart. ▶ Do not let a later reader merge them.
--
-- **The near misses, all four live elsewhere:**
--
--   2027-01-04  the first MONDAY — **241 rows**, the most crowded square in the pass
--               (Arizona 94, Wisconsin 123, California 17, Idaho 7)
--   2027-01-07  the "from and after" reading, one day late — **15 rows** (Nebraska 13 under
--               art. XVII-5, the Massachusetts Governor and Lieutenant Governor)
--   2027-01-13  the SECOND Wednesday — **178 rows**, the Maryland General Assembly. 🔴 THIS IS
--               THE RIVAL THE IN-DATA CONTROL CANNOT REFUSE, and it is a live day elsewhere.
--   2027-01-20  the THIRD Wednesday — **4 rows** (the Maryland Governor's day)
--
-- 🔴 **"FROM AND AFTER" IS A REAL HAZARD IN THIS STATE AND NOT A HYPOTHETICAL ONE.** art. V § 4
--   commences probate judges *"from and after the Wednesday after the first Monday"*, and Idaho's
--   art. III § 3 taught this pass that "from and after the first day" is not plainly "on the
--   first day". **Our clause does not say it** — art. IV § 2 says plainly "FROM the Wednesday" —
--   so the preposition trap exists in the Connecticut constitution and does not reach these five
--   offices. Stated so nobody imports it from the neighbouring article.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 CONNECTICUT'S LEGISLATURE IS ABSENT FROM OUR DATA, AND ITS DAY IS THIS WAVE'S OWN DAY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Measured 2026-11-24: Connecticut holds **0 `STATE_UPPER` and 0 `STATE_LOWER` office rows** and
-- **0 legislative race rows**. art. III § 8 elects the whole General Assembly *"on the Tuesday
-- after the first Monday of November, biennially, in the even-numbered years"*, so every seat was
-- on the 2026 ballot as a matter of law.
--
-- 🔴🔴 **AND art. III § 10 PUTS THOSE SEATS ON 2027-01-06 — THE DAY THIS FILE WRITES.** That is
--   New Mexico's shape and it is the real one this time: Alabama's 140 absent seats sat on a day
--   already past and Idaho's 105 on a different article's different day, so both would have stood
--   out in any count. **Connecticut's would be absorbed into the day the wave itself creates, and
--   no delta could see them.** Nebraska escaped this because its unicameral sits one day earlier;
--   Connecticut does not.
--   ▶ **A seeding job must give those seats their own `rule_id`** — art. III § 10 is a different
--   clause from art. IV § 2, with a different END (the third January, not the fifth) — **even
--   though the day is shared.** P4 gates on the absence and says so; assertion 3e re-asserts it
--   after the write, and refuses to let a non-executive row carry this file's rule_id.
--
-- ⚠ **AND THE CONSTITUTION DOES NOT FIX HOW MANY SEATS THAT IS.** art. III § 3 gives the senate
--   "not less than thirty and not more than fifty" members and § 4 the house "not less than one
--   hundred twenty-five and not more than two hundred twenty-five". So unlike Utah, Arizona and
--   Idaho — where the constitution's own membership number turned "probably missing" into
--   "certainly missing" at an exact count — **Connecticut's constitution can say only that the
--   whole body was up, not how large it is.** The size is statutory and is not sourced here.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ THE SIXTH OFFICE: THE SECRETARY OF THE STATE HAS NO RACE ROW, EVER — AND IS NOT DATED HERE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Measured 2026-11-24: the Secretary of the State office row exists and is held by Stephanie
-- Thomas; it carries **0 race rows of any year and 0 candidate rows**. art. IV § 1 puts it on the
-- very same quadrennial ballot as the other five, so this is not an off-cycle seat — it is a
-- **certainly** missing result. It is the register's Shape 2 inside a state the queue calls
-- complete, and the second such find in four states after South Dakota's State Auditor.
-- 🔴 **The difference is instructive: South Dakota is missing the OFFICE, Connecticut the RACE.**
-- Both present identically from the seat, as a state with one fewer office than the law describes.
--
-- 🔴 **THE DECISION, STATED RATHER THAN LEFT SILENT: this file dates FIVE, not six.** Maryland and
--   Arizona dated more offices than carried a race, but those were Ruling A **sibling** seats
--   receiving a winner from a race that exists. Here there is no Ruling A and no result at all, so
--   an `office_swearing_in` row keyed to `election_date = 2026-11-03` would assert a 2026 election
--   for this office that our data does not record, and would pre-authorise a seating against a
--   date a later result might not share. ▶ **The law above covers it the moment a result exists**;
--   the row is written then, by the file that records the winner. Assertion 3g pins the absence so
--   the skip is a measurement rather than an omission.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Term start or oath? — **TERM START**
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- art. IV § 2 runs the term **"from the Wednesday following the first Monday"** — a calendar date
-- — and mentions qualification only at the far end, *"until … and until their successors are duly
-- qualified"*, which extends an incumbent's holding and does not move a successor's start.
-- 🟢 **The constitution says so itself, in the same article.** art. IV § 21 opens *"If, AT THE
-- TIME FIXED FOR THE BEGINNING OF THE TERM of the governor, the governor-elect shall have died or
-- shall have FAILED TO QUALIFY …"* — which only parses if the term's beginning is fixed
-- independently of qualifying. 🟢 And art. XI § 1 makes the oath a condition of entering **on the
-- duties**, not of holding the office: *"all officers, executive and judicial, shall, BEFORE THEY
-- ENTER ON THE DUTIES of their respective offices, take the following oath"*; art. XI § 2 then
-- speaks of compensation "set at the BEGINNING OF SUCH OFFICIAL'S TERM OF OFFICE".
-- 🔴 **So Connecticut is Idaho's shape, not Nevada's**, where Art. 5 § 2 runs the term "from the
-- time of his installation" and NRS 282.010(4) makes installation mean qualification. Here the
-- oath is a separate event and must not be rendered as the term start.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SOURCE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   https://www.cga.ct.gov/asp/Content/constitutions/Constitution_State_CT.pdf
--     *Constitution of the State of Connecticut, Revised to January 1, 2025*, HTTP 200,
--     application/pdf, **572,979 bytes**, sha256
--     db796c2d539337d68d86385d9ad2614bece898517ac981bbfd6bf99e4008a581, read 2026-11-23 and
--     re-fetched 2026-11-24. 8,325 lines of extracted text; the codified constitution begins at
--     line 6855 and ARTICLE FOURTH at line 7478.
--   https://cga.ct.gov/2023/jnl/s/pdf/2023SJL00104-R00-JNL.PDF
--     *Journal of the Senate, Wednesday, January 4, 2023*, HTTP 200, application/pdf,
--     536,476 bytes, read 2026-11-24 — the second cycle, and the only thing that refuses the
--     second-Wednesday rival.
--
-- 🔴🔴 **`www.cga.ct.gov` SERVES A VALID CERTIFICATE WITH A MISSING INTERMEDIATE — `curl` REFUSES
--   AND A BROWSER DOES NOT.** `curl` exits **60**, *"unable to get local issuer certificate"*. The
--   leaf is `CN=*.cga.ct.gov` issued by `Go Daddy Secure Certificate Authority - G2`, which the
--   server never sends; browsers repair this silently by fetching the issuer named in the
--   certificate and `curl` does not.
--   🟢 **The fix, re-run and re-controlled 2026-11-24**: fetch
--   `http://certs.godaddy.com/repository/gdig2.crt` (**follow the redirect** — it 301s to https
--   and is **DER**, not PEM), convert it, concatenate it onto the system bundle and pass the
--   result as `--cacert`. **The unpatched bundle was run FIRST and failed with exit 60**, then the
--   patched one returned 200 — watching the control fail is what separates "my fix worked" from
--   "the server recovered".
--   ▶ **This is a host-failure mode the escalation ladder did not have.** Not a WAF, not a
--   TLS-fingerprint block, not a thin request: sending more headers does nothing. The right answer
--   is to repair trust and keep using `curl`, not to reach for a browser.
-- ⚠ `portal.ct.gov` returns **HTTP 200 with a page titled "404 Error Page"** for a path that does
--   not exist — a textbook soft 404. And the General Assembly's own path is `constitutions.asp`,
--   **plural**; the singular is a real IIS 404.
-- ⚠ **NO CONNECTICUT CHAMBER CARRIES AN `inauguration_rules` ROW** — all six are NULL — so there
--   was no lead to check and nothing to contradict. Recorded because the recipe says a rule row
--   earns its way in by its own citation; an absent row is cleaner than a bad one.
--
-- basis: `statute` for all 5 rows — constitutional, not statutory-by-delegation.
-- rule_id: `ct-const-art4-s2-wed-following-first-monday-january`.

BEGIN;

-- ── The selection: every office this wave will DATE. ──────────────────────────────────────────
--
-- 🟢 ONE CLAUSE, SO ONE GROUP AND NO SIBLING EXPANSION. art. IV § 1 names six offices in one
--    sentence and every race is single-seat; the five with a 2026 result are taken by their own
--    rows. The five titles are listed explicitly and P2 asserts the selection is the WHOLE
--    pending set, because a named list silently drops a sixth office and nothing errors.
-- ⚠ The Secretary of the State is NOT in this list and is NOT pending — it has no race row at
--    all. Assertion 3g measures that rather than letting the omission pass unremarked.
CREATE TEMP TABLE cc0509_sel ON COMMIT DROP AS
SELECT o.id            AS office_id,
       o.title         AS title,
       d.district_type AS district_type
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'ct'
   AND d.district_type = 'STATE_EXEC'
   AND w.election_date = DATE '2026-11-03'
   AND o.title IN ('Governor', 'Lieutenant Governor', 'Treasurer', 'Comptroller',
                   'Attorney General');

CREATE TEMP TABLE cc0509_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                        AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'ct' AND s.election_date = DATE '2026-11-03')      AS rows_ct,
       -- 🔴🔴 CONNECTICUT IS THE THIRD STATE ON THIS DAY. The before-image is pinned so assertion
       -- 4 is a delta, never a total.
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-06')                               AS rows_jan6,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-04')                               AS rows_jan4,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-07')                               AS rows_jan7,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-13')                               AS rows_jan13,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-20')                               AS rows_jan20,
       (SELECT count(*) FROM essentials.office_pending_winner w
          JOIN essentials.offices o   ON o.id = w.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'ct' AND w.election_date = DATE '2026-11-03'
           AND d.district_type <> 'STATE_EXEC')                                    AS pending_outside;

DO $$
DECLARE n bigint; b record;
BEGIN
  SELECT * INTO b FROM cc0509_before;

  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. It writes no
  -- term, so on a second run all 5 seats are still pending and every P1 check below would pass;
  -- the operator would be told the data moved when what happened is that they ran it twice.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0509_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P0: % of the 5 already carry a swearing-in row for this election. This file '
                    'would overwrite a date it has not recorded.', n;
  END IF;

  -- P1 — the body, and the constitution's own membership. 🟢 art. IV § 1 names SIX offices and we
  -- hold six rows; FIVE of them carry a 2026 result. Both numbers are asserted, because they are
  -- different claims and only one of them is this file's size.
  SELECT count(*) INTO n FROM cc0509_sel;
  IF n <> 5 THEN
    RAISE EXCEPTION 'P1: % Connecticut executive seats are reachable from a 2026 race, expected 5 '
                    '(Governor, Lieutenant Governor, Treasurer, Comptroller, Attorney General). '
                    'art. IV § 1 puts SIX on this ballot; the Secretary of the State has no race '
                    'row of any year. If this reads 6, that result has arrived — date it, do not '
                    'let this file absorb it silently.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ct' AND d.district_type = 'STATE_EXEC';
  IF n <> 6 THEN
    RAISE EXCEPTION 'P1: Connecticut holds % STATE_EXEC office rows, expected 6 — the exact '
                    'membership art. IV § 1 names in the CODIFIED text (governor, '
                    'lieutenant-governor, secretary of the state, treasurer, comptroller and '
                    'attorney general). 🔴 THE SUPERSEDED 1965 COPY OF THE SAME SECTION NAMES '
                    'FIVE, WITH NO ATTORNEY GENERAL, and its cycle arithmetic passes just as well '
                    '(2026 − 1966 = 60, divisible by four). A 5 here is the shape that reading '
                    'produces.', n;
  END IF;

  -- P2 — ⚠ AND THE SELECTION IS THE WHOLE PENDING SET. The WHERE clause names five titles
  -- explicitly, so a sixth pending executive would be silently dropped and nothing would error.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ct' AND w.election_date = DATE '2026-11-03'
     AND o.id NOT IN (SELECT office_id FROM cc0509_sel);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % pending Connecticut seat(s) did not reach this file''s selection. '
                    'art. IV § 2 dates the officers art. IV § 1 names and nothing else.', n;
  END IF;
  IF b.pending_outside <> 0 THEN
    RAISE EXCEPTION 'P2: % Connecticut pending seat(s) now sit outside STATE_EXEC, expected 0. '
                    '🔴 A LEGISLATIVE SEAT DOES NOT TAKE THIS FILE''S ROW EVEN THOUGH IT TAKES '
                    'THIS FILE''S DAY: art. III § 10 is a different clause with a different end '
                    '(the third January, not the fifth) and needs its own rule_id. Read this '
                    'file''s header before dating it.', b.pending_outside;
  END IF;

  -- P3 — every selected race is SINGLE-SEAT with exactly one winner, which is what makes "no
  -- Ruling A" a measurement rather than an assumption. ⚠ AND ALL FIVE ARE RE-ELECTIONS, counted
  -- here so CC_0510's probe guidance rests on a number rather than on a recollection.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w JOIN cc0509_sel c ON c.office_id = w.office_id
   WHERE w.election_date = DATE '2026-11-03'
     AND (w.winner_count <> 1 OR w.seats IS DISTINCT FROM 1);
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % of the 5 races are not single-seat with exactly one winner. Ruling A '
                    'would then apply and the SIBLING offices receiving the extra winners would '
                    'need dating too — Maryland dated 178 offices against 114 races and Arizona '
                    '94 against 65 for exactly this reason.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN cc0509_sel c ON c.office_id = w.office_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = c.office_id
   WHERE w.election_date = DATE '2026-11-03'
     AND och.politician_id IS NOT NULL
     AND och.politician_id::text = (w.winners -> 0 ->> 'id');
  IF n <> 5 THEN
    RAISE EXCEPTION 'P3: % of the 5 winners are the sitting holder of the seat they won, expected '
                    '5 — Connecticut returned every executive it elected. If this has fallen, a '
                    'seat changes hands and CC_0510''s header is wrong about what its live probe '
                    'can see.', n;
  END IF;

  -- P4 — 🔴🔴 THE LEGISLATURE: ZERO OFFICE ROWS, ZERO RACES, AND ITS DAY IS THIS FILE'S OWN DAY.
  -- art. III § 8 elects the whole General Assembly biennially in even-numbered years, so every
  -- seat was on this ballot as a matter of law; art. III § 10 commences those terms on the same
  -- Wednesday this file writes. Gated here so a seat arriving stops the file rather than being
  -- absorbed into a day no delta could separate it from.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ct' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: Connecticut now holds % legislative office row(s), expected 0 when this '
                    'file was written. 🔴 THEY TAKE 2027-01-06 TOO, UNDER A DIFFERENT CLAUSE: '
                    'art. III § 10 runs a legislator''s term "from the Wednesday following the '
                    'first Monday of the January next succeeding their election until the '
                    'Wednesday after the first Monday of the THIRD January" — art. IV § 2 says '
                    'the FIFTH. Same day, different rule_id. A seeding job must give them their '
                    'own.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ct' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % Connecticut legislative 2026 race row(s) now exist, expected 0. Read '
                    'this file''s header: the day is shared and the clause is not.', n;
  END IF;

  -- P5 — 🔴 THE DAY'S BEFORE-IMAGE, AND THE FOUR NEAR MISSES THAT ARE ALL LIVE ELSEWHERE.
  IF b.rows_jan6 <> 200 THEN
    RAISE EXCEPTION 'P5: % row(s) already carry 2027-01-06, expected 200 (Massachusetts 199 under '
                    'ma-const-amend-64-s1-legislators, the Maine Governor 1 under '
                    'me-const-art5-pt1-s2-first-wed-after-first-tue-january). Connecticut is the '
                    'THIRD state on this day — a fourth has landed since this file was written, '
                    'and its rule_id must be named before adding 5 to the pile.', b.rows_jan6;
  END IF;
  IF b.rows_jan4 <> 241 OR b.rows_jan7 <> 15 OR b.rows_jan13 <> 178 OR b.rows_jan20 <> 4 THEN
    RAISE EXCEPTION 'P5: the near-miss days have moved — 2027-01-04 (the first MONDAY) carries % '
                    'rows, expected 241; 2027-01-07 (the "from and after" reading, and '
                    'Nebraska''s own day) carries %, expected 15; 2027-01-13 (the SECOND '
                    'Wednesday, and the Maryland General Assembly''s day) carries %, expected '
                    '178; 2027-01-20 (the THIRD Wednesday, and the Maryland Governor''s day) '
                    'carries %, expected 4. They are pinned because EVERY ONE of this clause''s '
                    'near misses is a live term start somewhere else — reaching one week late '
                    'here produces Maryland''s answer, and that is the rival our single in-data '
                    'row cannot refuse.',
      b.rows_jan4, b.rows_jan7, b.rows_jan13, b.rows_jan20;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-06',
       'statute',
       'ct-const-art4-s2-wed-following-first-monday-january',
       'Conn. Const. art. IV, § 2 (codified, incorporating Amendment Art. I) — "Such officers '
         || 'shall hold their respective offices FROM THE WEDNESDAY FOLLOWING THE FIRST MONDAY '
         || 'OF THE JANUARY NEXT SUCCEEDING THEIR ELECTION until the Wednesday following the '
         || 'first Monday of the fifth January succeeding their election and until their '
         || 'successors are duly qualified." art. IV § 1 supplies "such officers": "A general '
         || 'election for governor, lieutenant-governor, secretary of the state, treasurer, '
         || 'comptroller and attorney general shall be held on the Tuesday after the first '
         || 'Monday of November, 1974, and quadrennially thereafter." The first Monday of '
         || 'January 2027 is the 4th (2027-01-01 is a Friday), so the Wednesday following it is '
         || '2027-01-06. 🟢 THE CLAUSE CARRIES NO RESIDUAL AND NO ESCAPE HATCH — not "unless '
         || 'otherwise provided by law", not "except as otherwise provided in this '
         || 'Constitution", nothing — which is the first such clause in this pass and means no '
         || 'statute can displace it, so no statute sweep was owed. THE CONSTITUTION WAS SWEPT '
         || 'ALL THE SAME, bounded by its own structure: 14 articles, 88 section headings, every '
         || 'occurrence of "Wednesday" and of every commencement verb read. Four instruments '
         || 'name a term or a sitting and all four land on this same day — art. III § 2 (the '
         || 'General Assembly''s regular session), art. III § 10 (LEGISLATORS'' terms), this '
         || 'art. IV § 2, and art. V § 4 (probate judges, "from and after the Wednesday after '
         || 'the first Monday"). None displaces § 2. The document''s only three "unless '
         || 'otherwise / except as provided" phrases are art. I § 8(10), art. XI § 2 and '
         || 'art. XIII § 3, and none touches a commencement. 🔴 TERM, NOT OATH: § 2 fixes a '
         || 'calendar day and mentions qualification only at the far end ("and until their '
         || 'successors are duly qualified"), which extends an incumbent''s holding rather than '
         || 'moving a successor''s start. The constitution says so itself — art. IV § 21 opens '
         || '"If, AT THE TIME FIXED FOR THE BEGINNING OF THE TERM of the governor, the '
         || 'governor-elect shall have died or shall have FAILED TO QUALIFY", which only parses '
         || 'if the two are separate; art. XI § 1 makes the oath a condition of entering ON THE '
         || 'DUTIES; art. XI § 2 speaks of compensation "set at the beginning of such official''s '
         || 'term of office". This is Idaho''s shape, not Nevada''s. 🔴 AND THIS DAY IS NOT THESE '
         || 'FIVE OFFICES'' ALONE: art. III § 10 commences every member of the General Assembly '
         || 'on the same Wednesday, with a different END (the third January, not the fifth). We '
         || 'hold ZERO Connecticut legislative office rows, so a seeding job must give them their '
         || 'own rule_id although the day is shared.',
       'https://www.cga.ct.gov/asp/Content/constitutions/Constitution_State_CT.pdf — '
         || '"Constitution of the State of Connecticut, Revised to January 1, 2025", published '
         || 'by the Connecticut General Assembly. HTTP 200, application/pdf, 572,979 bytes, '
         || 'sha256 db796c2d539337d68d86385d9ad2614bece898517ac981bbfd6bf99e4008a581, read '
         || '2026-11-23 and re-fetched 2026-11-24. 🔴🔴 THE DOCUMENT CONTAINS ARTICLE FOURTH '
         || 'TWICE AND THE SUPERSEDED 1965 VERSION COMES FIRST (extracted-text line 2006 against '
         || 'the codified copy at line 7478). The 1965 art. IV § 1 names FIVE officers and NO '
         || 'ATTORNEY GENERAL, under a footnote reading only "1 Amended by Article I., of the '
         || 'Amendments"; stopping there gives an Attorney General covered by nothing, which is '
         || 'exactly the shape of South Dakota''s REAL missing-office finding two states '
         || 'earlier. ⚠ AND THE OBVIOUS CHECK IS BLIND TO WHICH COPY YOU HAVE: the 1965 text '
         || 'anchors the cycle on 1966 and the codified text on 1974, and 2026 is '
         || 'divisible-by-four from BOTH, so the cycle test passes on the superseded article. '
         || 'Only the officer list discriminates. 🟢 § 2 ITSELF IS BYTE-IDENTICAL IN BOTH COPIES '
         || '(sha256 18dbc127bad96f8fdbb0340b6c215d3d8f0c54a1d0bd733f36df1b3a5898bc87 over its '
         || 'four body lines on each side), which is direct evidence the term clause has never '
         || 'been amended. 🔴🔴 www.cga.ct.gov SERVES A VALID CERTIFICATE WITH A MISSING '
         || 'INTERMEDIATE: curl exits 60 ("unable to get local issuer certificate") because the '
         || 'server never sends the Go Daddy Secure Certificate Authority - G2 issuer named in '
         || 'its own leaf, and browsers repair that silently. The fix is to fetch '
         || 'http://certs.godaddy.com/repository/gdig2.crt (follow the redirect; it is DER), '
         || 'convert it, append it to the system bundle and pass --cacert. The UNPATCHED bundle '
         || 'was run first and failed with exit 60 before the patched one returned 200. This is '
         || 'not a WAF, not a TLS-fingerprint block and not a thin request — more headers do '
         || 'nothing. ⚠ portal.ct.gov answers HTTP 200 with a page titled "404 Error Page" for a '
         || 'path that does not exist, and the General Assembly''s own path is '
         || 'constitutions.asp, PLURAL. 🟢🟢 THE SECOND CYCLE IS A DOCUMENT, BECAUSE OUR DATA HAS '
         || 'ONLY ONE ROW: https://cga.ct.gov/2023/jnl/s/pdf/2023SJL00104-R00-JNL.PDF — Journal '
         || 'of the Senate, Wednesday, January 4, 2023 (HTTP 200, 536,476 bytes, read '
         || '2026-11-24), whose first sentence reads "On Wednesday after the first Monday of '
         || 'January A.D. 2023, the date by the Constitution of the State of Connecticut for the '
         || 'meeting of the General Assembly, the Senate convened", and which records the Oath '
         || 'of Office administered that day to Lieutenant Governor Susan Bysiewicz — one of the '
         || 'six officers art. IV § 1 names. ⚠ NO CONNECTICUT CHAMBER CARRIES AN '
         || 'inauguration_rules ROW; all six are NULL, so there was no lead to check and nothing '
         || 'to contradict.',
       '🔴🔴 THE IN-DATA CONTROL IS ONE ROW AND ONE RIVAL SURVIVES IT. Connecticut holds exactly '
         || 'one dated state term — Ned Lamont''s Governorship, 2019-01-09 — and its own source '
         || 'derives it from the Governor''s biography and the NGA ("first day in office"), not '
         || 'from this clause, which is what makes it independent of what it tests. Six rival '
         || 'rules were computed beside art. IV § 2 across three cycles. 2019 kills five of them '
         || 'and leaves THE SECOND WEDNESDAY IN JANUARY standing, which gives 2027-01-13 — a '
         || 'week late, onto a square that already holds 178 live Maryland rows. The Senate '
         || 'Journal of January 4, 2023 kills the second Wednesday and leaves TWO standing, the '
         || 'first Wednesday in January and MAINE''s "first Wednesday after the first Tuesday", '
         || 'both of which give the right answer in 2027 for the wrong reason. NEITHER CYCLE '
         || 'SEPARATES THE CLAUSE ALONE AND BOTH TOGETHER DO: the intersection is empty. '
         || '🔴🔴 CONNECTICUT IS THE THIRD STATE ON 2027-01-06 AND MAINE''S RULE IS NEARLY THIS '
         || 'SENTENCE. 200 rows were already on the day — Massachusetts 199 legislators under '
         || 'ma-const-amend-64-s1-legislators and the Maine Governor under '
         || 'me-const-art5-pt1-s2-first-wed-after-first-tue-january — so a gate reading the '
         || 'total would see 205 and call it success. "The first Wednesday after the first '
         || 'Tuesday" and "the Wednesday following the first Monday" agree in every year January '
         || '1st is not a Tuesday; they part in 2019, and that is the only reason the in-data '
         || 'control can tell them apart. Two states, one calendar day, two unrelated clauses, '
         || 'nearly one sentence. Every count about this day is a DELTA that names the other '
         || 'rules. ⚠ ALL FOUR NEAR MISSES ARE LIVE SOMEWHERE: 2027-01-04 the first Monday (241 '
         || 'rows, Arizona, Wisconsin, California, Idaho — the most crowded square in the pass), '
         || '2027-01-07 the "from and after" reading one day late (15 rows, Nebraska and the two '
         || 'Massachusetts executives), 2027-01-13 the second Wednesday (178, the Maryland '
         || 'General Assembly) and 2027-01-20 the third (4, the Maryland Governor). 🔴 "FROM AND '
         || 'AFTER" IS A REAL HAZARD IN THIS STATE: art. V § 4 commences probate judges "from '
         || 'and after the Wednesday after the first Monday", and Idaho''s art. III § 3 taught '
         || 'this pass that "from and after the first day" is not plainly "on the first day". '
         || 'OUR CLAUSE DOES NOT SAY IT — art. IV § 2 says plainly "FROM the Wednesday" — so the '
         || 'trap exists in this constitution and does not reach these five offices. '
         || '🔴🔴 CONNECTICUT''S LEGISLATURE IS ABSENT AND ITS DAY IS THIS WAVE''S OWN DAY. We '
         || 'hold 0 STATE_UPPER and 0 STATE_LOWER office rows and 0 legislative race rows, and '
         || 'art. III § 8 elects the whole General Assembly biennially in even-numbered years, '
         || 'so every seat was on the 2026 ballot as a matter of law. art. III § 10 puts those '
         || 'terms on 2027-01-06 — THE DAY THIS FILE WRITES — so unlike Alabama''s 140 (a day '
         || 'already past) and Idaho''s 105 (a different article''s different day) they would be '
         || 'absorbed into the day the wave itself creates and no delta could see them. ⚠ And '
         || 'the constitution does NOT fix how many seats that is: art. III § 3 gives the senate '
         || '30 to 50 members and § 4 the house 125 to 225, so unlike Utah, Arizona and Idaho '
         || 'there is no constitutional membership number to turn "probably missing" into an '
         || 'exact count. ⚠ THE SIXTH EXECUTIVE IS NOT DATED HERE: the Secretary of the State '
         || 'office exists, is held by Stephanie Thomas, and carries 0 race rows of any year and '
         || '0 candidate rows, although art. IV § 1 puts it on the same quadrennial ballot. This '
         || 'file dates FIVE deliberately — there is no Ruling A sibling to receive a winner and '
         || 'no result at all, so a row keyed to this election_date would assert a 2026 election '
         || 'our data does not record. South Dakota is missing the OFFICE; Connecticut is '
         || 'missing the RACE; both present identically from the seat. ⚠ ALL FIVE WINNERS ARE '
         || 'RE-ELECTIONS, so a live probe of a Connecticut address CANNOT be read by the '
         || 'incoming NAME — only by the incoming DATE. Written by CC_0509.'
  FROM cc0509_sel c;

DO $$
DECLARE n bigint; b record;
        jan1 date; first_mon date; day_clause date;
        r_first_wed date; r_second_wed date; r_third_wed date; r_maine date;
        r_first_mon date; r_from_after date;
        ctl record; c_rows bigint := 0; c_clause bigint := 0;
        survive_2019 int := 0; survive_2023 int := 0; survive_both int := 0;
        ct_day       CONSTANT date := DATE '2027-01-06';  -- the clause, this file
        ct_jan4      CONSTANT date := DATE '2027-01-04';  -- the first Monday: AZ + WI + CA + ID
        ct_jan7      CONSTANT date := DATE '2027-01-07';  -- "from and after" +1: Nebraska + MA
        ct_jan13     CONSTANT date := DATE '2027-01-13';  -- the SECOND Wednesday: Maryland
        ct_jan20     CONSTANT date := DATE '2027-01-20';  -- the THIRD Wednesday: the MD Governor
        lamont_2019  CONSTANT date := DATE '2019-01-09';  -- the only in-data control
        journal_2023 CONSTANT date := DATE '2023-01-04';  -- the Senate Journal's own day
        -- ⚠ 3d's THREE EXPECTATIONS LIVE HERE AND NOWHERE ELSE, so the condition and the message
        --   share one copy. Oregon shipped two gates whose condition and message each held their
        --   own literal; they agreed in the shipped file and printed nonsense the moment a
        --   control made them disagree — "starts 2023-01-09, expected 2023-01-09". Measured
        --   again here: controls C5, C6 and C7 each printed "1 … expected exactly 1" before this
        --   was pulled into a variable. The defect is invisible until something makes the copies
        --   disagree, and a control is the only thing that ever does.
        exp_2019     CONSTANT int  := 1;  -- the second Wednesday, and nothing else
        exp_2023     CONSTANT int  := 2;  -- the first Wednesday, and Maine's rule
        exp_both     CONSTANT int  := 0;  -- the intersection is empty: that is the argument
BEGIN
  SELECT * INTO b FROM cc0509_before;

  -- 1. All 5 carry the one date.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0509_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = ct_day;
  IF n <> 5 THEN
    RAISE EXCEPTION '1: % of 5 seats carry %.', n, ct_day;
  END IF;

  -- 2. Exactly one distinct date was written. ⚠ One clause really does mean one date here — which
  --    is NOT the default: Massachusetts' Amend. Art. LXIV § 1 is a single sentence-group naming
  --    three days a fortnight apart, and 199 of the rows already on this very square come from it.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s JOIN cc0509_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '2: % distinct swearing-in dates were written, expected exactly 1.', n;
  END IF;

  -- 3a. 🔴 THE CLAUSE EVALUATED AS WRITTEN — the day is COMPUTED and never typed. "The Wednesday
  --     FOLLOWING the first Monday" is read strictly: start the day AFTER the first Monday and
  --     walk forward to a Wednesday, so the word "following" is in the arithmetic and not only in
  --     the comment. ISODOW: Mon = 1 … Sun = 7.
  jan1       := make_date(EXTRACT(YEAR FROM DATE '2026-11-03')::int + 1, 1, 1);
  first_mon  := jan1 + ((1 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);
  day_clause := (first_mon + 1)
                + ((3 - EXTRACT(ISODOW FROM (first_mon + 1))::int + 7) % 7);
  IF EXTRACT(ISODOW FROM first_mon)::int <> 1 THEN
    RAISE EXCEPTION '3a: % is not a Monday. Every comparison below proves nothing while this is '
                    'wrong.', first_mon;
  END IF;
  IF EXTRACT(ISODOW FROM day_clause)::int <> 3 THEN
    RAISE EXCEPTION '3a: % is not a Wednesday.', day_clause;
  END IF;
  IF day_clause <> ct_day THEN
    RAISE EXCEPTION '3a: the Wednesday following the first Monday of the January succeeding '
                    '2026-11-03 computes as %, not %.', day_clause, ct_day;
  END IF;
  -- 🟢 The clause's own cycle, checked: art. IV § 1's "November, 1974, and quadrennially
  --    thereafter". ⚠ THIS TEST CANNOT TELL THE CODIFIED ARTICLE FROM THE SUPERSEDED ONE — the
  --    1965 copy anchors on 1966 and 2026 is divisible-by-four from both. 3f carries the check
  --    that does discriminate.
  IF (EXTRACT(YEAR FROM DATE '2026-11-03')::int - 1974) % 4 <> 0 THEN
    RAISE EXCEPTION '3a: 2026 is not on art. IV § 1''s four-year cycle from 1974, so the clause '
                    'does not put these offices on this ballot at all.';
  END IF;

  -- 3b. 🔴🔴 THE FOUR WRONG DAYS COMPUTED BESIDE THE RIGHT ONE, AND EVERY ONE OF THEM IS A LIVE
  --     TERM START IN ANOTHER STATE.
  r_first_wed  := jan1 + ((3 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);
  r_second_wed := r_first_wed + 7;
  r_third_wed  := r_first_wed + 14;
  r_first_mon  := first_mon;
  r_from_after := day_clause + 1;
  IF r_first_mon <> ct_jan4 OR r_from_after <> ct_jan7
     OR r_second_wed <> ct_jan13 OR r_third_wed <> ct_jan20 THEN
    RAISE EXCEPTION '3b: the near-miss arithmetic is broken — first Monday %, "from and after" %, '
                    'second Wednesday %, third Wednesday %. Expected %, %, % and %.',
      r_first_mon, r_from_after, r_second_wed, r_third_wed,
      ct_jan4, ct_jan7, ct_jan13, ct_jan20;
  END IF;
  IF day_clause IN (r_first_mon, r_from_after, r_second_wed, r_third_wed) THEN
    RAISE EXCEPTION '3b: the candidate days are not distinct (% / % / % / % / %), so the '
                    'comparison below cannot discriminate.',
      day_clause, r_first_mon, r_from_after, r_second_wed, r_third_wed;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0509_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date IN (r_first_mon, r_from_after, r_second_wed, r_third_wed);
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % Connecticut executive seat(s) carry one of the four wrong days — % '
                    '(the first MONDAY, 241 live rows across Arizona, Wisconsin, California and '
                    'Idaho), % (the "from and after" reading one day late, 15 rows in Nebraska '
                    'and Massachusetts — and art. V § 4 of THIS constitution really does say '
                    '"from and after"), % (the SECOND Wednesday, 178 rows, the Maryland General '
                    'Assembly — and the one rival our in-data control cannot refuse) or % (the '
                    'THIRD Wednesday, 4 rows, the Maryland Governor).',
      n, r_first_mon, r_from_after, r_second_wed, r_third_wed;
  END IF;

  -- 3c. 🔴🔴 THE TWO RIVALS THAT COINCIDE WITH THE CLAUSE IN 2027, ASSERTED TO COINCIDE. A gate
  --     that quietly assumed every rival differs would be wrong here, and the coincidence is the
  --     whole reason 3d has to reach back to other cycles. MAINE's rule is one of the two, and it
  --     is already on this calendar day with a row of its own.
  r_maine := jan1 + ((2 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);               -- first Tuesday
  r_maine := (r_maine + 1) + ((3 - EXTRACT(ISODOW FROM (r_maine + 1))::int + 7) % 7);
  IF r_first_wed <> ct_day OR r_maine <> ct_day THEN
    RAISE EXCEPTION '3c: in 2027 the first Wednesday in January computes as % and Maine''s "first '
                    'Wednesday after the first Tuesday" as %, and BOTH were expected to equal '
                    'this clause''s % — they agree whenever January 1st is not a Tuesday. If they '
                    'have stopped agreeing, 3d''s whole argument needs re-reading: the survivor '
                    'counts below are built on which rivals this cycle CANNOT separate.',
      r_first_wed, r_maine, ct_day;
  END IF;

  -- 3d. 🔴🔴 THE RULE RUN OVER CONNECTICUT'S ONE DATED TERM, WITH EVERY RIVAL RUN BESIDE IT — AND
  --     THE SURVIVORS COUNTED RATHER THAN DESCRIBED. Ned Lamont's 2019-01-09 is the only dated
  --     state term in Connecticut, and its own source derives it from the Governor's biography
  --     and the NGA rather than from this clause, so it is independent of what it tests.
  --     ▶ 2019 admits exactly ONE rival (the second Wednesday) and 2023 admits exactly TWO (the
  --     first Wednesday and Maine's), and no rival survives both. The file asserts all three
  --     numbers, because "the control agrees with the clause" is satisfied by any rule that lands
  --     on the same day — Nebraska paid for that one state ago.
  FOR ctl IN
    SELECT t.term_start, o.title, p.full_name,
           ((make_date(EXTRACT(YEAR FROM t.term_start)::int, 1, 1)
             + ((1 - EXTRACT(ISODOW FROM make_date(EXTRACT(YEAR FROM t.term_start)::int,1,1))::int
                 + 7) % 7)) + 1)
           + ((3 - EXTRACT(ISODOW FROM
                ((make_date(EXTRACT(YEAR FROM t.term_start)::int, 1, 1)
                  + ((1 - EXTRACT(ISODOW FROM make_date(EXTRACT(YEAR FROM t.term_start)::int,1,1))::int
                      + 7) % 7)) + 1))::int + 7) % 7) AS clause_that_jan
      FROM essentials.office_terms t
      JOIN essentials.offices o    ON o.id = t.office_id
      JOIN essentials.districts dd ON dd.id = o.district_id
      LEFT JOIN essentials.politicians p ON p.id = t.politician_id
     WHERE lower(dd.state) = 'ct' AND dd.district_type = 'STATE_EXEC'
       AND t.term_start IS NOT NULL AND t.start_precision = 'day'
     ORDER BY t.term_start
  LOOP
    c_rows := c_rows + 1;
    IF ctl.term_start = ctl.clause_that_jan THEN c_clause := c_clause + 1; END IF;
    RAISE NOTICE '3d: % (%, %) — the Wednesday following the first Monday of that January is %; '
                 'clause test %.',
      ctl.term_start, ctl.title, coalesce(ctl.full_name, '(unnamed)'), ctl.clause_that_jan,
      CASE WHEN ctl.term_start = ctl.clause_that_jan THEN 'PASS' ELSE 'fail' END;
  END LOOP;
  IF c_rows <> 1 THEN
    RAISE EXCEPTION '3d: % dated Connecticut executive term(s), expected exactly 1 — Ned '
                    'Lamont''s 2019-01-09. 🔴 A CONTROL THAT HAS LOST OR GAINED ITS FIXTURE '
                    'PROVES NOTHING. The other four offices carry no term_start at all (the ADR '
                    '0002 phase-2 backfill); if a second has appeared, read it, because two '
                    'cycles in our own data would retire the journal this file leans on.', c_rows;
  END IF;
  IF c_clause <> 1 THEN
    RAISE EXCEPTION '3d: the one dated Connecticut executive term does not equal the Wednesday '
                    'following the first Monday of its own January. Lamont''s 2019-01-09 is the '
                    'only in-data evidence art. IV § 2 has.';
  END IF;
  -- The six rivals, evaluated for 2019 and for 2023, and counted. 2019-01-01 is a Tuesday and
  -- 2023-01-01 a Sunday, which is why the two cycles admit different rivals.
  SELECT count(*) FILTER (WHERE v2019 = lamont_2019),
         count(*) FILTER (WHERE v2023 = journal_2023),
         count(*) FILTER (WHERE v2019 = lamont_2019 AND v2023 = journal_2023)
    INTO survive_2019, survive_2023, survive_both
    FROM (
      SELECT rule,
             CASE rule
               WHEN 'first_wed'  THEN fw19
               WHEN 'second_wed' THEN fw19 + 7
               WHEN 'third_wed'  THEN fw19 + 14
               WHEN 'first_mon'  THEN fm19
               WHEN 'from_after' THEN ((fm19 + 1)
                                       + ((3 - EXTRACT(ISODOW FROM (fm19 + 1))::int + 7) % 7)) + 1
               WHEN 'maine'      THEN (ft19 + 1)
                                       + ((3 - EXTRACT(ISODOW FROM (ft19 + 1))::int + 7) % 7)
             END AS v2019,
             CASE rule
               WHEN 'first_wed'  THEN fw23
               WHEN 'second_wed' THEN fw23 + 7
               WHEN 'third_wed'  THEN fw23 + 14
               WHEN 'first_mon'  THEN fm23
               WHEN 'from_after' THEN ((fm23 + 1)
                                       + ((3 - EXTRACT(ISODOW FROM (fm23 + 1))::int + 7) % 7)) + 1
               WHEN 'maine'      THEN (ft23 + 1)
                                       + ((3 - EXTRACT(ISODOW FROM (ft23 + 1))::int + 7) % 7)
             END AS v2023
        FROM (
          SELECT unnest(ARRAY['first_wed','second_wed','third_wed','first_mon',
                              'from_after','maine']) AS rule,
                 DATE '2019-01-01' + ((3 - EXTRACT(ISODOW FROM DATE '2019-01-01')::int + 7) % 7) AS fw19,
                 DATE '2019-01-01' + ((1 - EXTRACT(ISODOW FROM DATE '2019-01-01')::int + 7) % 7) AS fm19,
                 DATE '2019-01-01' + ((2 - EXTRACT(ISODOW FROM DATE '2019-01-01')::int + 7) % 7) AS ft19,
                 DATE '2023-01-01' + ((3 - EXTRACT(ISODOW FROM DATE '2023-01-01')::int + 7) % 7) AS fw23,
                 DATE '2023-01-01' + ((1 - EXTRACT(ISODOW FROM DATE '2023-01-01')::int + 7) % 7) AS fm23,
                 DATE '2023-01-01' + ((2 - EXTRACT(ISODOW FROM DATE '2023-01-01')::int + 7) % 7) AS ft23
        ) x
    ) y;
  RAISE NOTICE '3d: of 6 rival rules — % reproduce Lamont''s % and % reproduce the Senate '
               'Journal''s %; % reproduce both.',
    survive_2019, lamont_2019, survive_2023, journal_2023, survive_both;
  IF survive_2019 <> exp_2019 THEN
    RAISE EXCEPTION '3d: % of the 6 rival rules reproduce Lamont''s %, expected exactly % — THE '
                    'SECOND WEDNESDAY IN JANUARY, which gives 2027-01-13 and is the Maryland '
                    'General Assembly''s live day. That survivor is why this file needs a second '
                    'cycle from a document, and if the count has changed the argument below is '
                    'no longer the one that was measured.', survive_2019, lamont_2019, exp_2019;
  END IF;
  IF survive_2023 <> exp_2023 THEN
    RAISE EXCEPTION '3d: % of the 6 rival rules reproduce the Senate Journal''s %, expected '
                    'exactly % — the first Wednesday in January and MAINE''s "first Wednesday '
                    'after the first Tuesday", both of which also give 2027-01-06 and are '
                    'therefore right in this cycle for the wrong reason.',
      survive_2023, journal_2023, exp_2023;
  END IF;
  IF survive_both <> exp_both THEN
    RAISE EXCEPTION '3d: % rival rule(s) reproduce BOTH % and %, expected %. The whole argument '
                    'for this day is that neither cycle separates art. IV § 2 on its own and the '
                    'two together leave nothing standing. A survivor here means the date rests '
                    'on the clause''s words alone.',
      survive_both, lamont_2019, journal_2023, exp_both;
  END IF;

  -- 3e. 🔴🔴 THE LEGISLATURE IS STILL ABSENT, AND ITS DAY IS THE DAY THIS FILE JUST WROTE. Pinned
  --     after the write so the next reader finds this header rather than re-deriving art. III
  --     § 10 — and so that a seeding job cannot quietly let those seats inherit this rule_id.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ct' AND dd.district_type IN ('STATE_UPPER', 'STATE_LOWER');
  IF n <> 0 THEN
    RAISE EXCEPTION '3e: Connecticut now holds % legislative office row(s). art. III § 10 '
                    'commences them on 2027-01-06 — THIS FILE''S OWN DAY — under a clause with a '
                    'different end, so no delta can distinguish them and they must carry their '
                    'own rule_id.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ct'
     AND s.rule_id = 'ct-const-art4-s2-wed-following-first-monday-january'
     AND dd.district_type <> 'STATE_EXEC';
  IF n <> 0 THEN
    RAISE EXCEPTION '3e: % non-executive Connecticut row(s) carry this file''s rule_id. art. IV '
                    '§ 2 dates the six officers of art. IV § 1 and nobody else.', n;
  END IF;

  -- 3f. 🔴 THE MEMBERSHIP, WHICH IS THE ONLY TEST THAT SEPARATES THE CODIFIED ARTICLE FROM THE
  --     SUPERSEDED ONE. Six office rows by title; the cycle check in 3a passes on both copies.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ct' AND dd.district_type = 'STATE_EXEC'
     AND o.title IN ('Governor', 'Lieutenant Governor', 'Secretary of the State', 'Treasurer',
                     'Comptroller', 'Attorney General');
  IF n <> 6 THEN
    RAISE EXCEPTION '3f: % of the six offices the CODIFIED art. IV § 1 names are present by '
                    'title, expected 6. The superseded 1965 copy of the same section names five '
                    'and omits the ATTORNEY GENERAL, and its cycle arithmetic passes just as '
                    'well — this count is the only thing that separates the two readings.', n;
  END IF;

  -- 3g. ⚠ THE SIXTH OFFICE IS STILL UNRACED AND STILL UNDATED, DELIBERATELY. Measured rather than
  --     omitted, so the decision not to date it is a finding and not a silence.
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.offices o    ON o.id = r.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ct' AND dd.district_type = 'STATE_EXEC'
     AND o.title = 'Secretary of the State';
  IF n <> 0 THEN
    RAISE EXCEPTION '3g: the Secretary of the State now carries % race row(s), expected 0 OF ANY '
                    'YEAR. 🟢 THE LAW ABOVE ALREADY COVERS IT — art. IV § 1 puts it on the same '
                    'quadrennial ballot and art. IV § 2 dates it 2027-01-06 — so date and seat '
                    'it with the file that records the result, and cite this one.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ct' AND o.title = 'Secretary of the State';
  IF n <> 0 THEN
    RAISE EXCEPTION '3g: the Secretary of the State carries % swearing-in row(s), expected 0 — '
                    'this file dates five offices deliberately, and that row is owed to the file '
                    'that records the missing result.', n;
  END IF;

  -- 3h. 🔴 AND NO CONNECTICUT OFFICE OUTSIDE THIS SELECTION WAS DATED FOR THIS ELECTION, except
  --     the five federal House rows the federal programme put on 2027-01-03.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ct' AND s.election_date = DATE '2026-11-03'
     AND s.office_id NOT IN (SELECT office_id FROM cc0509_sel)
     AND NOT (dd.district_type IN ('NATIONAL_LOWER', 'NATIONAL_UPPER')
              AND s.swearing_in_date = DATE '2027-01-03'
              AND s.rule_id = 'us-const-amend-xx-1');
  IF n <> 0 THEN
    RAISE EXCEPTION '3h: % Connecticut row(s) for this election are neither one of this file''s 5 '
                    'nor one of the 5 federal rows (NATIONAL_LOWER, 2027-01-03, '
                    'us-const-amend-xx-1). Connecticut had no U.S. Senate seat on this ballot.', n;
  END IF;

  -- 4. 🔴 THE 2027-01-06 DELTA, NAMED. Connecticut is the third state on this day.
  SELECT count(*) INTO n FROM essentials.office_swearing_in WHERE swearing_in_date = ct_day;
  IF n <> b.rows_jan6 + 5 THEN
    RAISE EXCEPTION '4: rows on % went % -> %, a delta of %, expected 5.',
      ct_day, b.rows_jan6, n, n - b.rows_jan6;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.swearing_in_date = ct_day
     AND NOT (lower(dd.state) = 'ct'
              AND s.rule_id = 'ct-const-art4-s2-wed-following-first-monday-january')
     AND s.rule_id NOT IN ('ma-const-amend-64-s1-legislators',
                           'me-const-art5-pt1-s2-first-wed-after-first-tue-january');
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % row(s) on % belong to a rule this file does not know. A date shared by '
                    'three states is a coincidence of calendars, never a shared rule — and '
                    'MAINE''S IS THE NEAREST MISS IN THE PASS, agreeing with this clause in every '
                    'year January 1st is not a Tuesday. Name the new one before absorbing it.',
      n, ct_day;
  END IF;

  -- 5. Connecticut rows for this election moved by exactly 5.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ct' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_ct + 5 THEN
    RAISE EXCEPTION '5: Connecticut rows for this election went % -> %, a delta of %, expected 5.',
      b.rows_ct, n, n - b.rows_ct;
  END IF;

  -- 6. Repo-wide, exactly 5 rows were added — no other state was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 5 THEN
    RAISE EXCEPTION '6: office_swearing_in went % -> %, a delta of %, expected 5.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 7. Every one of the 5 reads back as a Connecticut row under this rule, with basis statute,
  --    citing art. IV § 2. ⚠ ONE rule_id and ONE clause here, so unlike Alabama and Arizona there
  --    is no per-group authority split to count — but the citation is still asserted, because a
  --    citation can be right about the date and wrong about the law and no count can see it.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN cc0509_sel c            ON c.office_id = s.office_id
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.election_date = DATE '2026-11-03'
     AND lower(dd.state) = 'ct'
     AND s.basis = 'statute'
     AND s.rule_id = 'ct-const-art4-s2-wed-following-first-monday-january'
     AND s.authority LIKE 'Conn. Const. art. IV, § 2 (codified%';
  IF n <> 5 THEN
    RAISE EXCEPTION '7: % of 5 rows read back as a Connecticut row with basis statute under '
                    'ct-const-art4-s2-wed-following-first-monday-january citing the CODIFIED '
                    'art. IV, § 2.', n;
  END IF;
  -- 7b. ⚠ AND NO ROW IS DATED ON A CLAUSE FOR A BODY IT DOES NOT BELONG TO. art. III § 2,
  --     art. III § 10 and art. V § 4 are quoted INSIDE the authority as corroboration and as
  --     warnings; none of them may be the clause a seat is dated ON.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0509_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND (s.authority LIKE 'Conn. Const. art. III%' OR s.authority LIKE 'Conn. Const. art. V%');
  IF n <> 0 THEN
    RAISE EXCEPTION '7b: % row(s) are dated ON art. III or art. V. § III-2 is the SESSION, '
                    '§ III-10 is the LEGISLATURE''s term and § V-4 is the PROBATE JUDGES'' — all '
                    'three land on this same day and none of them dates any of these five '
                    'offices.', n;
  END IF;

  -- 8. No term was written. CC_0510 seats.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0509_sel c ON c.office_id = t.office_id
   WHERE t.term_start = ct_day;
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0509 OK: 5 Connecticut state executives dated % — THE WEDNESDAY FOLLOWING THE '
               'FIRST MONDAY OF JANUARY, from Conn. Const. art. IV § 2 (codified), a clause with '
               'NO ESCAPE HATCH AT ALL — the first in this pass — so no statute can displace it '
               'and no statute sweep was owed. The constitution was swept anyway, bounded by its '
               'own 14 articles and 88 section headings: four instruments name a term or a '
               'sitting (art. III § 2, art. III § 10, this § 2 and art. V § 4) and ALL FOUR LAND '
               'ON THIS SAME DAY, while the document''s only three "unless otherwise provided" '
               'phrases touch no commencement. 🔴🔴 THE PDF CARRIES ARTICLE FOURTH TWICE AND THE '
               'SUPERSEDED 1965 COPY COMES FIRST, naming five officers and no Attorney General — '
               'and the cycle test passes on BOTH copies (1966 and 1974 are each '
               'divisible-by-four from 2026), so only the membership count separates them. '
               '🟢 § 2 is byte-identical in both, which proves the term clause was never '
               'amended. 🔴🔴 THE IN-DATA CONTROL IS ONE ROW AND ONE RIVAL SURVIVES IT: of six '
               'rivals, exactly % reproduces Lamont''s 2019-01-09 (the SECOND Wednesday, which '
               'gives 2027-01-13 — the Maryland General Assembly''s live day) and exactly % '
               'reproduce the Senate Journal''s 2023-01-04 (the first Wednesday, and MAINE''s '
               'rule). NEITHER CYCLE SEPARATES THE CLAUSE ALONE; TOGETHER THEY LEAVE NOTHING '
               'STANDING. All four distinct near misses were computed and refused — % (the first '
               'Monday, 241 rows), % ("from and after", 15 rows, and art. V § 4 really does say '
               'it), % (the second Wednesday, 178 rows) and % (the third, 4 rows). Connecticut '
               'is the THIRD state on this calendar day; % rows were already here under '
               'Massachusetts and Maine. 🔴🔴 AND THE LEGISLATURE IS ABSENT WITH ITS DAY INSIDE '
               'THIS WAVE''S: we hold 0 STATE_UPPER and 0 STATE_LOWER office rows, art. III § 8 '
               'put the whole General Assembly on the 2026 ballot, and art. III § 10 commences '
               'it on THIS DAY — so those seats would be absorbed into the square this file just '
               'created and need their own rule_id. ⚠ The Secretary of the State is the SIXTH '
               'office art. IV § 1 names, has 0 race rows of any year, and is deliberately NOT '
               'dated here.',
    ct_day, survive_2019, survive_2023, ct_jan4, ct_jan7, ct_jan13, ct_jan20, b.rows_jan6;
END $$;

COMMIT;
