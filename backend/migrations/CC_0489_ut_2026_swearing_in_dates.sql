-- CC_0489 — Utah: the start date for the 50 legislative seats won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE FIRST DAY OF JANUARY ITSELF — NOT A MONDAY, NOT COUNTED FROM THE ELECTION
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-01  House of Representatives (42) and Senate (8)
--
-- Utah is the first state in this pass whose date is a fixed day of the calendar rather than an
-- ordinal weekday. Sourced 2026-11-22; the write-up is in
-- backend/data/state-seating-2026/DATES.md § UT. This file writes the rows and seats nobody.
-- CC_0490 seats.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE AUTHORITY — Utah Const. Art. VI, Secs. 3 and 4, quoted in full
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **Sec. 3. Election of House members -- Terms.**
--   "(1) The members of the House of Representatives shall be chosen biennially on even-numbered
--    years by the qualified voters of the respective representative districts, on the first
--    Tuesday after the first Monday in November.
--    (2) Their term of office shall be two years from the first day of January next after their
--    election."
--
-- **Sec. 4. Election of Senators -- Terms.**
--   "(1) The senators shall be chosen by the qualified voters of the respective senatorial
--    districts, at the same times and places as members of the House of Representatives.
--    (2) Their term of office shall be four years from the first day of January next after their
--    election.
--    (3) As nearly one-half as may be practicable shall be elected in each biennium as the
--    Legislature shall determine by law with each apportionment."
--
-- The first day of January next after 2026-11-03 is **2027-01-01**. Assertion 3 computes it.
--
-- ⚠ **2027-01-01 IS A FRIDAY AND A PUBLIC HOLIDAY, AND THE CLAUSE DOES NOT CARE.** It names a day
--   of the calendar, not a sitting day. 🔴 **Do not round it to the following Monday** — that is
--   the same class of error as reaching for a convening date, and Utah's general session does not
--   begin until the third Tuesday in January in any case.
--
-- 🔴🔴 **AND THE FIRST MONDAY IS A LIVE WRONG ANSWER IN THIS STATE, NOT A HYPOTHETICAL ONE** —
--     see the Board of Education block below. For 2027 the two rules are **three days apart**
--     (2027-01-01 against 2027-01-04). Assertion 3 runs both and refuses the Monday.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE SOURCE SERVES A JAVASCRIPT SHELL TO `curl`, AND THE OBVIOUS GUARD DOES NOT CATCH IT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `le.utah.gov` returns HTTP 200 and ~26.6 KB of navigation with **no section text at all**.
-- Measured for this file on 2026-11-23: Art. VI Sec. 3 and Sec. 4 both came back at **exactly
-- 26,677 bytes**, and neither contained the phrase "first day of January".
--
-- ⚠ **DATES.md SAYS TO "ASSERT THE SECTION NUMBER IS PRESENT BEFORE CONCLUDING A SECTION IS
--   EMPTY", AND THAT GUARD PASSES ON THE SHELL.** The shell carries the section number in its
--   `<title>` ("Utah Constitution Section Article VI, Section 3") and again in a JavaScript
--   variable. ▶ **Assert on a distinctive phrase from the section's BODY**, not on its number.
--
-- 🟢 **TWO INDEPENDENT READS AGREE ON THE TEXT ABOVE:**
--   1. The page rendered in a browser (Playwright, 2026-11-23): 1,510 and 1,594 characters of
--      visible text against the shell's 26,677 bytes of HTML.
--   2. **The XML download, over plain `curl`, with no browser** — HTTP 200, 565 and 709 bytes:
--        https://le.utah.gov/xcode/ArticleVI/UC_AVI_S3_1800010118000101.xml
--        https://le.utah.gov/xcode/ArticleVI/UC_AVI_S4_1800010118000101.xml
--      🔴 **THE XML NAME IS NOT DERIVABLE FROM THE SECTION URL** — swapping `.html` for `.xml`
--      404s. The real name comes from the rendered page's own "Download Options" link, once;
--      after that the text is fetchable without a browser forever. ▶ **That route is the
--      improvement on "it was read in a browser" and should be used for every further Utah
--      section.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ NO CONTROL IS AVAILABLE IN OUR OWN DATA, AND THIS FILE ASSERTS THAT ABSENCE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **All 119 Utah legislative and Board of Education terms in `essentials.office_terms` carry
-- `term_start = NULL`.** Measured 2026-11-23, not assumed. So nothing in this database
-- corroborates or contradicts 2027-01-01, and assertion 3d asserts the zero rather than letting a
-- future reader believe a check was made that could not be made.
--
-- The clause is unusually plain — "from the first day of January next after their election" has
-- none of the inclusive/exclusive ambiguity Maine's "from the day next preceding" had — but the
-- reading rests on the text alone, and that is recorded here rather than implied.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE SIX BOARD OF EDUCATION SEATS ARE REFUSED, AND THE STATUTE'S OWN DATES ARE WHY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `Utah Code § 20A-14-103` fixes the Board's term LENGTH and its cycle and **names no start**.
-- The only dates in the section are transitional: subsection (1)(b) gives a realigned member a
-- term "that ends **January 6, 2025**", and (2)(b)(i) lets an incumbent serve until
-- **January 2, 2023**.
--
-- 🔴🔴 **BOTH OF THOSE ARE FIRST MONDAYS IN JANUARY, AND THE LEGISLATURE'S BOUNDARY IS THE FIRST
--     DAY.** 2023-01-02 is the first Monday of January 2023; 2025-01-06 is the first Monday of
--     January 2025. Assertion 3c computes both and refuses unless they still agree, because it is
--     the only hard evidence available that **the two bodies in this state do not share a
--     boundary**. If the Board's rule is the first Monday, its 2027 date is **2027-01-04**, three
--     days after the legislature's.
--
-- ⚠ Those two dates sit inside transitional provisions about a 2021 realignment, not in a general
--   rule, so neither can be cited as the Board's recurring commencement either. `53E-3-201` sends
--   the question back to Title 20A, Chapter 14, and Chapter 14 does not answer it.
--
-- ▶ **WHAT WOULD SETTLE IT:** the Board's own published roster with term dates, or the lieutenant
--   governor's certification — recorded with `basis = 'published'`. 🔴 **DO NOT WRITE 2027-01-01
--   FOR THESE SIX ON THE STRENGTH OF THE LEGISLATURE'S CLAUSE.** Assertion 4 refuses it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 A CORRECTION TO DATES.md § UT: THE GAP IS MOSTLY MISSING **RACES**, NOT MISSING RESULTS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The ledger says "33 carry no recorded winner" of the House and reads the shortfall as a result
-- gap. Measured against production 2026-11-23, it is two different things and the larger one is
-- not what the ledger describes:
--
--     House   75 offices    42 pending    2 with a 2026 race and no result    31 WITH NO RACE ROW
--     Senate  29 offices     8 pending    1 with a 2026 race and no result    20 WITH NO RACE ROW
--     Board   15 offices     6 pending    2 with a 2026 race and no result     7 with no race row
--
-- 🔴🔴 **UTAH'S CONSTITUTION MAKES THE HOUSE NUMBER A CERTAINTY RATHER THAN A GUESS.** Art. VI
--     Sec. 3(1) elects the WHOLE House "biennially on even-numbered years", so **all 75 House
--     seats were on the 2026 ballot as a matter of law** — and we hold a race row for 44 of them.
--     The 31 are certainly missing data, not seats that were not up. That is a stronger statement
--     than this pass can usually make, and it belongs to the results programme.
--
-- ⚠ **THE SENATE SHORTFALL IS REAL BUT CANNOT BE SIZED FROM THE CONSTITUTION ALONE.** Sec. 4(3)
--   requires "as nearly one-half as may be practicable" — 14 or 15 of 29 — but adds "as the
--   Legislature shall determine by law with each apportionment", so **which** half is statutory
--   and is not in this database. We hold 9. ▶ Read that statute before asserting a number.
--
-- ⚠ **THE THREE LEGISLATIVE SEATS WITH A RACE AND NO RESULT ARE BLANK, NOT PROVISIONAL.** House
--   District 48, House District 61 and Senate District 11 carry candidate rows whose `result` is
--   **NULL** with no `result_source` at all — unlike Washington's four, which at least carried
--   the August primary result. There is nothing here to misread as a call. P2 names all three and
--   refuses if one has acquired a winner, because the wave would then be larger than 50.
--
-- 🔴 **ONE OF THE THREE IS A SEAT THIS WAVE'S OWN WINNER IS VACATING.** Doug Fiefia holds **House
--    District 48** and wins **Senate District 18** here. See CC_0490's header: his House term
--    stays open because nothing in our data says when it ends or who follows him.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS FILE WRITES NO TERM AND SEATS NOBODY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Overwrites nothing: P0 refuses if any of the 50 already carries a row for this election.
-- ⚠ 4 OTHER Utah offices DO carry a 2026-11-03 row already — the congressional seats, from the
--   federal programme. None is in this selection and assertion 6 pins the Utah total at 4 + 50.
--
-- Sources, opened and read 2026-11-23 (and first read 2026-11-22):
--   https://le.utah.gov/xcode/ArticleVI/Article_VI,_Section_3.html  (rendered)
--   https://le.utah.gov/xcode/ArticleVI/Article_VI,_Section_4.html  (rendered)
--   https://le.utah.gov/xcode/ArticleVI/UC_AVI_S3_1800010118000101.xml  (HTTP 200, 565 bytes)
--   https://le.utah.gov/xcode/ArticleVI/UC_AVI_S4_1800010118000101.xml  (HTTP 200, 709 bytes)
--   https://le.utah.gov/xcode/Title20A/Chapter14/20A-14-S103.html, …/20A-14-S102.html and
--   https://le.utah.gov/xcode/Title53E/Chapter3/53E-3-S201.html for the Board statutes.

BEGIN;

CREATE TEMP TABLE cc0489_sel ON COMMIT DROP AS
SELECT o.id AS office_id, d.district_type, o.title, d.label AS seat
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'ut'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

-- The three legislative seats that were on the ballot and whose result is blank, named so a file
-- which refuses can say WHICH one moved rather than only that a count changed.
CREATE TEMP TABLE cc0489_unresulted ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('State House District 48',  'State Representative District 48'),
  ('State House District 61',  'State Representative District 61'),
  ('State Senate District 11', 'State Senator District 11')
) AS v(seat, title);

CREATE TEMP TABLE cc0489_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                        AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'ut' AND s.election_date = DATE '2026-11-03')      AS rows_ut;

DO $$
DECLARE n bigint; v_names text;
BEGIN
  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. This file
  -- writes no term, so on a second run all 50 seats are still pending and every P1 check would
  -- pass; the operator would be told the data moved when what happened is that they ran it twice.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0489_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P0: % of the 50 already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;

  -- P1 — exactly the two bodies this file was written against. One clause each, one date.
  SELECT count(*) INTO n FROM cc0489_sel;
  IF n <> 50 THEN
    RAISE EXCEPTION 'P1: % Utah legislative seats are pending, expected 50. The data moved under '
                    'this file — see P2, which names the three seats most likely to have moved '
                    'it.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0489_sel WHERE district_type = 'STATE_LOWER';
  IF n <> 42 THEN
    RAISE EXCEPTION 'P1: % House seats, expected 42. ⚠ Utah elects its WHOLE 75-seat House every '
                    'two years (Art. VI Sec. 3(1)), so 42 is not a half — it is what we hold a '
                    'recorded winner for. 2 more carry a 2026 race with a blank result and 31 '
                    'have no race row at all.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0489_sel WHERE district_type = 'STATE_UPPER';
  IF n <> 8 THEN
    RAISE EXCEPTION 'P1: % Senate seats, expected 8 of the 29. ⚠ Art. VI Sec. 4(3) puts "as '
                    'nearly one-half as may be practicable" on each biennium, which is 14 or 15 '
                    '— 8 is what we hold a recorded winner for, and the shortfall is a race gap '
                    'belonging to the results programme.', n;
  END IF;

  -- P2 — 🔴 THE THREE BLANK-RESULT SEATS ARE STILL BLANK, AND EACH IS NAMED. If the results
  -- programme has written a winner for one, this wave is bigger than 50 and CC_0490's pinned
  -- digest is stale. That is a GOOD reason to stop, and the message says so.
  SELECT count(*), string_agg(u.seat, '; ' ORDER BY u.seat) INTO n, v_names
    FROM cc0489_unresulted u
    JOIN essentials.districts d ON d.label = u.seat AND lower(d.state) = 'ut'
    JOIN essentials.offices o   ON o.district_id = d.id AND o.title = u.title
   WHERE EXISTS (SELECT 1 FROM essentials.office_pending_winner w
                  WHERE w.office_id = o.id AND w.election_date = DATE '2026-11-03');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the three blank-result seats now carry a 2026 winner: %. That is '
                    'new data, not damage — re-derive the wave (it is no longer 50) and re-pin '
                    'CC_0490 before applying either file.', n, v_names;
  END IF;

  -- P2b — and the three really are the offices this file thinks they are. A label or title that
  -- no longer matches would make the check above vacuously pass.
  SELECT count(*) INTO n
    FROM cc0489_unresulted u
    JOIN essentials.districts d ON d.label = u.seat AND lower(d.state) = 'ut'
    JOIN essentials.offices o   ON o.district_id = d.id AND o.title = u.title;
  IF n <> 3 THEN
    RAISE EXCEPTION 'P2b: % of the three named blank-result seats resolve to an office, expected '
                    '3. P2 above asserted nothing for the ones that did not resolve.', n;
  END IF;

  -- P3 — 🔴 THE SIX PENDING BOARD OF EDUCATION SEATS EXIST AND ARE DELIBERATELY NOT IN THIS
  -- SELECTION. If this count is not 6 the refusal this file documents is about a different set
  -- of seats than the one that is actually there.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ut' AND d.district_type = 'STATE_BOARD_EDUCATION'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 6 THEN
    RAISE EXCEPTION 'P3: % Utah Board of Education seats are pending, expected 6. They are '
                    'REFUSED for dating — 20A-14-103 names no commencement — and this file must '
                    'be refusing the set it was written about.', n;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-01',
       'statute',
       'ut-const-art6-first-day-january',
       CASE c.district_type
         WHEN 'STATE_LOWER' THEN
           'Utah Const. Art. VI, Sec. 3 (Election of House members -- Terms) — "(2) Their term '
             || 'of office shall be two years from the first day of January next after their '
             || 'election." The first day of January next after the 2026-11-03 general election '
             || 'is 2027-01-01.'
         ELSE
           'Utah Const. Art. VI, Sec. 4 (Election of Senators -- Terms) — "(2) Their term of '
             || 'office shall be four years from the first day of January next after their '
             || 'election." The first day of January next after the 2026-11-03 general election '
             || 'is 2027-01-01.'
       END
       || ' 🔴 THE CLAUSE NAMES A FIXED DAY OF THE CALENDAR, NOT AN ORDINAL WEEKDAY AND NOT A '
       || 'SITTING DAY: 2027-01-01 is a Friday and a public holiday, and it is not rounded to '
       || 'the following Monday. Utah''s general session does not convene until the third '
       || 'Tuesday in January, so the term start and any oath are plainly separate events here. '
       || '⚠ THE FIRST MONDAY IS A LIVE WRONG ANSWER IN THIS STATE — see notes.',
       'https://le.utah.gov/xcode/ArticleVI/Article_VI,_Section_3.html and …,_Section_4.html — '
         || 'the Legislature''s own publication of the Utah Constitution, read 2026-11-22 and '
         || 'again 2026-11-23. 🔴 le.utah.gov SERVES EVERY SECTION AS A JAVASCRIPT SHELL: plain '
         || 'curl returns HTTP 200 and ~26.6 KB of navigation with no section text, and both of '
         || 'these sections came back at exactly 26,677 bytes with the phrase "first day of '
         || 'January" absent. ⚠ Asserting the SECTION NUMBER is present does not catch that — '
         || 'the shell carries it in the page title and in a JavaScript variable. Assert on a '
         || 'phrase from the section body instead. The text above was confirmed by two '
         || 'independent reads: the page rendered in a browser (1,510 and 1,594 characters of '
         || 'visible text), and the XML download over plain curl with no browser — '
         || 'https://le.utah.gov/xcode/ArticleVI/UC_AVI_S3_1800010118000101.xml (HTTP 200, 565 '
         || 'bytes) and …/UC_AVI_S4_1800010118000101.xml (HTTP 200, 709 bytes). The XML name is '
         || 'NOT derivable from the section URL; it comes from the rendered page''s own Download '
         || 'Options link. ⚠ NO CONTROL IS AVAILABLE IN OUR OWN DATA: all 119 Utah legislative '
         || 'and Board of Education terms carry term_start = NULL, measured 2026-11-23, so this '
         || 'date rests on the constitutional text alone and nothing here corroborates it.',
       '🔴🔴 UTAH''S TWO ELECTED STATE BODIES DO NOT SHARE A BOUNDARY, AND THE BOARD OF '
         || 'EDUCATION''S OWN STATUTE IS THE EVIDENCE. Utah Code 20A-14-103 fixes the Board''s '
         || 'term length and names no start; its only dates are transitional — a realigned '
         || 'member''s term "ends January 6, 2025" and an incumbent may serve until "January 2, '
         || '2023". BOTH ARE FIRST MONDAYS IN JANUARY, where this clause is the FIRST DAY. So '
         || 'the Board''s six pending seats are REFUSED rather than given this date; if their '
         || 'rule is the first Monday, their 2027 date is 2027-01-04, three days after this one. '
         || '⚠ A GAP IN THIS STATE IS MOSTLY MISSING RACES, NOT MISSING RESULTS: Utah elects its '
         || 'WHOLE 75-seat House every two years (Art. VI Sec. 3(1)), so all 75 were on this '
         || 'ballot as a matter of law — we hold a race row for 44 and a winner for 42. 31 House '
         || 'and 20 Senate offices have NO race row at all, and 3 legislative seats (House 48, '
         || 'House 61, Senate 11) carry a race whose every candidate has a NULL result and no '
         || 'result_source. Those are the results programme''s work and are left undated. '
         || 'Written by CC_0489.'
  FROM cc0489_sel c;

DO $$
DECLARE n bigint; b record; first_day date; first_mon date; d2023 date; d2025 date;
BEGIN
  SELECT * INTO b FROM cc0489_before;

  -- 1. All 50 carry the one date.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0489_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2027-01-01';
  IF n <> 50 THEN
    RAISE EXCEPTION '1: % of 50 seats carry 2027-01-01.', n;
  END IF;

  -- 2. Exactly one distinct date was written. Utah's two chambers have two clauses with the same
  --    words; a second date would mean something outside them reached the selection.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s JOIN cc0489_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 1 THEN
    RAISE EXCEPTION '2: % distinct swearing-in dates were written, expected exactly 1.', n;
  END IF;

  -- 3. 🔴🔴 THE CLAUSE EVALUATED AS WRITTEN, WITH THE WRONG RULE RUN BESIDE IT.
  --
  --    (a) "the first day of January next after their election" — computed, not typed.
  SELECT make_date(EXTRACT(YEAR FROM DATE '2026-11-03')::int + 1, 1, 1) INTO first_day;
  IF first_day <> DATE '2027-01-01' THEN
    RAISE EXCEPTION '3a: the first day of January next after 2026-11-03 computes as %, not '
                    '2027-01-01.', first_day;
  END IF;

  --    (b) 🔴 THE FIRST MONDAY IS THE WRONG RULE AND IT IS THREE DAYS AWAY. Both are real days in
  --        the right month, and in this state the wrong one is not hypothetical — the Board of
  --        Education's own statute uses first Mondays. The two must be shown to differ, and no
  --        seat may carry the Monday.
  SELECT first_day + ((8 - EXTRACT(ISODOW FROM first_day))::int % 7) INTO first_mon;
  IF first_mon <> DATE '2027-01-04' THEN
    RAISE EXCEPTION '3b: the first Monday in January 2027 computes as %, not 2027-01-04. The '
                    'wrong-rule arm of this control is broken, so the comparison below proves '
                    'nothing.', first_mon;
  END IF;
  IF first_day = first_mon THEN
    RAISE EXCEPTION '3b: the first day and the first Monday of January 2027 compute to the same '
                    'day (%), so this control cannot tell the two rules apart.', first_day;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0489_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = first_mon;
  IF n <> 0 THEN
    RAISE EXCEPTION '3b: % seat(s) carry %, the FIRST MONDAY in January — the rule Art. VI Secs. '
                    '3(2) and 4(2) do not state, and the rule the Board of Education''s statute '
                    'appears to use.', n, first_mon;
  END IF;

  --    (c) 🔴🔴 THE BOARD STATUTE'S OWN TWO DATES ARE FIRST MONDAYS, AND THAT IS THE ONLY HARD
  --        EVIDENCE AVAILABLE THAT THE TWO BODIES DO NOT SHARE A BOUNDARY. 20A-14-103(1)(b)
  --        ends a realigned term on "January 6, 2025"; (2)(b)(i) lets an incumbent serve until
  --        "January 2, 2023". Computed here for cycles this file does not write.
  SELECT DATE '2023-01-01' + ((8 - EXTRACT(ISODOW FROM DATE '2023-01-01'))::int % 7) INTO d2023;
  SELECT DATE '2025-01-01' + ((8 - EXTRACT(ISODOW FROM DATE '2025-01-01'))::int % 7) INTO d2025;
  IF d2023 <> DATE '2023-01-02' OR d2025 <> DATE '2025-01-06' THEN
    RAISE EXCEPTION '3c: the first Mondays of January 2023 and 2025 compute as % and %, but '
                    'Utah Code 20A-14-103 names 2023-01-02 and 2025-01-06. If these disagree, '
                    'the reading that the Board uses a first-Monday boundary is wrong and the '
                    'refusal of its six seats needs re-arguing.', d2023, d2025;
  END IF;
  IF d2023 = DATE '2023-01-01' OR d2025 = DATE '2025-01-01' THEN
    RAISE EXCEPTION '3c: a Board transitional date coincides with the first DAY of January, so '
                    'it cannot distinguish the Board''s rule from the legislature''s.';
  END IF;

  --    (d) ⚠ AND THE CORROBORATION STOPS THERE — ASSERTED, NOT ASSUMED. Not one Utah legislative
  --        or Board term carries a start date anywhere in this database, so 2027-01-01 rests on
  --        the constitutional text alone. A future reader must not believe otherwise.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ut'
     AND dd.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_BOARD_EDUCATION')
     AND t.term_start IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '3d: % Utah legislative or Board term(s) now carry a start date. When this '
                    'file was written all 119 were NULL, so this date had NO corroboration in '
                    'our own data. If rows have appeared, check this file''s date against them '
                    'before trusting it.', n;
  END IF;

  -- 4. 🔴🔴 NOT ONE BOARD OF EDUCATION SEAT WAS DATED. 20A-14-103 names no commencement and its
  --    own transitional dates point at a different boundary; borrowing the legislature's day
  --    would assert a rule nobody has read.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ut' AND dd.district_type = 'STATE_BOARD_EDUCATION'
     AND s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % Utah Board of Education seat(s) were dated by this file. They are '
                    'refused: 20A-14-103 fixes the term length and names no start.', n;
  END IF;

  -- 5. 🔴 THE THREE BLANK-RESULT SEATS WERE NOT DATED. Dating one would assert that this pass
  --    had looked at a result it has not.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
    JOIN cc0489_unresulted u     ON u.seat = dd.label AND u.title = o.title
   WHERE lower(dd.state) = 'ut' AND s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % of the three seats with a blank 2026 result were dated.', n;
  END IF;

  -- 6. Utah rows for this election moved by exactly 50, and every row that is NOT one of the 50
  --    is one of the 4 congressional seats the federal programme dated to 2027-01-03 under
  --    `us-const-amend-xx-1`. ⚠ Those carry district_type NATIONAL_LOWER — measured, after a
  --    first draft of this assertion guessed 'CONG%' and the gate caught it.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ut' AND s.election_date = DATE '2026-11-03'
     AND dd.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER')
     AND NOT (dd.district_type = 'NATIONAL_LOWER'
              AND s.swearing_in_date = DATE '2027-01-03'
              AND s.rule_id = 'us-const-amend-xx-1');
  IF n <> 0 THEN
    RAISE EXCEPTION '6: % Utah row(s) for this election are neither one of this file''s 50 nor '
                    'one of the 4 congressional rows the federal programme wrote (NATIONAL_LOWER, '
                    '2027-01-03, us-const-amend-xx-1).', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ut' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_ut + 50 THEN
    RAISE EXCEPTION '6: Utah rows for this election went % -> %, a delta of %, expected 50.',
      b.rows_ut, n, n - b.rows_ut;
  END IF;

  -- 7. Repo-wide, exactly 50 rows were added — no other state was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 50 THEN
    RAISE EXCEPTION '7: office_swearing_in went % -> %, a delta of %, expected 50.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 8. No term was written. CC_0490 seats.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0489_sel c ON c.office_id = t.office_id
   WHERE t.term_start = DATE '2027-01-01';
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0489 OK: 50 Utah legislative seats (42 House, 8 Senate) dated 2027-01-01 — '
               'THE FIRST DAY of January, Utah Const. Art. VI Secs. 3(2) and 4(2), not the first '
               'Monday (2027-01-04) and not rounded off a Friday public holiday. The day was '
               'computed, and the wrong rule computed beside it; the Board of Education''s own '
               'statute uses first Mondays (2023-01-02, 2025-01-06), which is why its six '
               'pending seats are REFUSED rather than given this date. No corroboration exists '
               'in our own data and assertion 3d asserts that zero. Three blank-result '
               'legislative seats left undated.';
END $$;

COMMIT;
