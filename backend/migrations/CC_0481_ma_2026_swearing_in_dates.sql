-- CC_0481 — Massachusetts: the start dates for all 204 state seats won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 ONE CLAUSE, THREE DATES, A FORTNIGHT APART.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   2027-01-06  House of Representatives (159) and Senate (40)
--   2027-01-07  Governor and Lieutenant Governor (2) — at NOON
--   2027-01-20  Attorney General, Treasurer and Receiver-General, Auditor (3)
--
-- The register's queue is built on "one constitutional clause usually dates a state's House,
-- Senate and executives together". For Massachusetts the first half is true and the second is
-- false: a SINGLE sentence-group names three different days, and the gap between the earliest and
-- the latest is fourteen days. 🔴 **A FILE THAT COPIED THE HOUSE'S DATE ONTO THE ATTORNEY
-- GENERAL WOULD PUT HER IN OFFICE TWO WEEKS EARLY.** That is this state's whole hazard, and
-- assertions 1 and 5 are where it is caught.
--
-- Massachusetts was SOURCED on 2026-11-22; the write-up is in
-- backend/data/state-seating-2026/DATES.md § MA. This file writes the rows. It seats nobody.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE AUTHORITY — Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Quoted from the page, in the clause's own order:
--
--   "The terms of the governor and lieutenant-governor SHALL BEGIN AT NOON ON THE THURSDAY NEXT
--    FOLLOWING THE FIRST WEDNESDAY IN JANUARY succeeding their election …
--
--    The terms of the secretary, treasurer and receiver-general, attorney general, and auditor
--    SHALL BEGIN WITH THE THIRD WEDNESDAY IN JANUARY succeeding their election …
--
--    The terms of senators and representatives SHALL BEGIN WITH THE FIRST WEDNESDAY IN JANUARY
--    succeeding their election and shall extend to the first Wednesday in January in the third
--    year following their election and until their successors are chosen and qualified."
--
-- Wednesdays in January 2027 are the 6th, 13th and 20th; the Thursday next following the first is
-- the 7th. All three dates fall out of ONE anchor — the first Wednesday — which is why assertion
-- 3 computes that anchor and derives the other two from it rather than writing three literals.
--
-- ⚠ **TWO SUPERSEDED VERSIONS OF THIS ARTICLE ARE PRINTED ON THE SAME PAGE AND BOTH READ
--   PLAUSIBLY.** Amend. Art. LXIV § 1 as originally adopted (1918) is marked "Superseded by
--   Amendments, Art. LXXX"; Art. LXXX's replacement is marked "Annulled and superseded by
--   Amendments, Art. LXXXII". All three carry the same three-way split, so **a reader who stopped
--   at the first would get the right days for the wrong reason** — but Art. LXXX still has the
--   governor on a TWO-YEAR term and Art. LXIV as adopted has the whole slate biennial. 🔴 **2026
--   is a Massachusetts gubernatorial year only under Art. LXXXII**, so which version is in force
--   is not a pedantic question here: it decides whether the Governor is on this ballot at all.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- TERM START OR OATH? — TERM START, AND THE OATH IS A SEPARATE, LATER EVENT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The clause fixes each term to a CALENDAR DATE ("shall begin at noon on the Thursday next
-- following…", "shall begin with the first Wednesday in January…") and nowhere conditions the
-- start on qualification.
--
-- The oath is Mass. Const. Part 2, Ch. VI, Art. I, read on the same page: every person chosen
-- "shall, BEFORE HE ENTERS ON THE DISCHARGE OF THE BUSINESS of his place or office, take and
-- subscribe the following declaration, and oaths or affirmations". That gates the DISCHARGE OF
-- THE DUTIES, not the beginning of the term. 🔴 So Massachusetts' date is a term start and must
-- not be rendered as a swearing-in.
--
-- ⚠ "…and until their successors are chosen and qualified" is about the PREVIOUS term's END, not
--   this one's start. It extends a sitting member's tenure if no successor has qualified; it does
--   not move the successor's term start. `seat_officeholder` closes each predecessor at
--   `term_start - 1` = 2027-01-05 for the legislature, exactly the day before the successors
--   begin. Nothing to reconcile.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE CONTROLS — AND AN HONEST ACCOUNT OF WHICH ONE IS WEAK
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 1. 🟢🟢 **ONE TERM ALREADY IN OUR DATABASE PINS ALL THREE DATES, BECAUSE ALL THREE COME FROM
--    ONE ANCHOR.** `essentials.office_terms` holds Maura Healey's term starting **2023-01-05**,
--    backfilled by migration 1459 from `offices.politician_id` by a pass that never read this
--    clause. 2023-01-05 is "the Thursday next following the first Wednesday in January 2023" —
--    and it is that date ONLY IF the first Wednesday of January 2023 was the 4th. So a single
--    recorded governor's term measures the first-Wednesday anchor exactly, and the legislative
--    and third-Wednesday dates are that anchor plus 0 and plus 14. Assertion 3c does this.
--
-- 2. 🟢 **THE LEGISLATURE'S OWN JOURNAL, IN ITS OWN WORDS.** `JOURNAL OF THE HOUSE`,
--    https://malegislature.gov/Journal/House/193/hj01042023.pdf (HTTP 200, 473,373 bytes, opened
--    and read 2026-11-22), page 1: "The one hundred and ninety-third General Court of the
--    Commonwealth of Massachusetts convened at the State House in Boston on the FIRST WEDNESDAY
--    OF JANUARY, being the fourth day of the year two thousand twenty-three". The document names
--    both the rule and the day it produced, for a year this file does not write.
--
-- 3. ⚠ **THE THIRD-WEDNESDAY GROUP HAS THE WEAKEST SUPPORT AND IT IS THE LEAST INTUITIVE OF THE
--    THREE.** Andrea Campbell was sworn as Attorney General, and William Galvin and Deborah
--    Goldberg for their own offices, on 2023-01-18 — the third Wednesday of January 2023 — widely
--    datelined (Boston Globe, WGBH, Boston.com, all 2023-01-18). **That is a news dateline, not a
--    document, and it is recorded as the weaker control it is.** 🔴 OUR OWN DATA CANNOT HELP
--    HERE: not one Massachusetts executive other than the Governor carries a `term_start` at all,
--    and no Massachusetts legislative term is recorded with a start date anywhere in the
--    database. Assertion 3d asserts that absence rather than letting a future reader assume a
--    corroboration that was never there.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHAT MUST NOT BE SWEPT IN, AND WHY EACH IS ABSENT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Massachusetts holds 160 House offices, 40 Senate offices and 6 statewide executives; this file
-- dates 159, 40 and 5. Assertions 4 and 6 measure both exclusions.
--
--   • **2nd Plymouth District** carries a 2026 race and NO recorded result, so it is outside
--     `office_pending_winner` — exactly as invisible as having no race. John R. Gaskey holds it.
--     That is the results programme's work, not a dating gap. 🔴 160 ≠ 159 is therefore correct
--     arithmetic, and reading it as a missing office would be Connecticut's fabricated finding
--     again.
--
--   • **The Secretary of the Commonwealth** is elective, is one of the five officers the
--     third-Wednesday sentence names, and has NO 2026 winner recorded. William Francis Galvin
--     holds it. ⚠ Unlike California's Insurance Commissioner, this office WOULD take one of this
--     file's dates — the clause names "the secretary" explicitly — so when its result is recorded
--     the third-Wednesday row covers it. It is left undated here because dating it would assert
--     that this pass had looked at an election it has not.
--
-- ⚠ **"FIVE EXECUTIVES" IS NOT MASSACHUSETTS' WHOLE SLATE.** There are six. Do not read the
--   count as the state's constitutional complement.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS FILE WRITES NO TERM AND SEATS NOBODY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Overwrites nothing: P0 refuses if any of the 204 already carries a row for this election.
-- ⚠ 10 OTHER Massachusetts offices DO carry a 2026-11-03 row already — the congressional and
--   Senate seats, from the federal programme. None is in this selection and assertion 6 pins the
--   Massachusetts total at 10 + 204.
--
-- Source, read in full 2026-11-22 (458,545 bytes, HTTP 200, text/html):
--   https://malegislature.gov/Laws/Constitution — the General Court's own publication of the
--   Constitution of the Commonwealth. The article texts are at "Article LXXXII" in the Articles
--   of Amendment; Part 2, Ch. VI, Art. I (the oath) is on the same page.
--   https://malegislature.gov/Journal/House/193/hj01042023.pdf — the House Journal for the
--   convening of the 193rd General Court, read 2026-11-22.

BEGIN;

CREATE TEMP TABLE cc0481_sel ON COMMIT DROP AS
SELECT o.id AS office_id, d.district_type, o.title, d.label AS seat,
       CASE WHEN d.district_type IN ('STATE_LOWER', 'STATE_UPPER') THEN 'legislature'
            WHEN o.title IN ('Governor', 'Lieutenant Governor')    THEN 'gov-ltgov'
            ELSE 'constitutional-officers' END AS grp
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'ma'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0481_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                        AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'ma' AND s.election_date = DATE '2026-11-03')      AS rows_ma;

DO $$
DECLARE n bigint;
BEGIN
  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT. This file
  -- writes no term, so on a second run all 204 are still pending and every P1 check would pass;
  -- the operator would be told the data moved when what happened is that they ran it twice.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0481_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P0: % of the 204 already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;

  -- P1 — exactly the bodies this file was written against, counted per GROUP, because the three
  -- groups take three different days and a miscount in one of them is this state's whole hazard.
  SELECT count(*) INTO n FROM cc0481_sel;
  IF n <> 204 THEN
    RAISE EXCEPTION 'P1: % Massachusetts state seats are pending, expected 204. The data moved '
                    'under this file.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0481_sel WHERE district_type = 'STATE_LOWER';
  IF n <> 159 THEN
    RAISE EXCEPTION 'P1: % House seats, expected 159 of the 160 (2nd Plymouth District carries a '
                    '2026 race with no recorded result).', n;
  END IF;

  SELECT count(*) INTO n FROM cc0481_sel WHERE district_type = 'STATE_UPPER';
  IF n <> 40 THEN
    RAISE EXCEPTION 'P1: % Senate seats, expected 40 — the whole chamber.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0481_sel WHERE grp = 'gov-ltgov';
  IF n <> 2 THEN
    RAISE EXCEPTION 'P1: % seats in the governor/lieutenant-governor group, expected 2.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0481_sel WHERE grp = 'constitutional-officers';
  IF n <> 3 THEN
    RAISE EXCEPTION 'P1: % seats in the third-Wednesday group, expected 3 (Attorney General, '
                    'Treasurer and Receiver-General, Auditor of the Commonwealth). The Secretary '
                    'of the Commonwealth belongs to this group in law and has no 2026 result.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0481_sel
   WHERE district_type = 'STATE_EXEC'
     AND title NOT IN ('Governor', 'Lieutenant Governor', 'Attorney General',
                       'Treasurer and Receiver-General', 'Auditor of the Commonwealth');
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % pending state executive(s) are not one of the five this file names.',
      n;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       CASE c.grp WHEN 'legislature' THEN DATE '2027-01-06'
                  WHEN 'gov-ltgov'   THEN DATE '2027-01-07'
                  ELSE                    DATE '2027-01-20' END,
       'statute',
       CASE c.grp WHEN 'legislature' THEN 'ma-const-amend-64-s1-legislators'
                  WHEN 'gov-ltgov'   THEN 'ma-const-amend-64-s1-gov-ltgov'
                  ELSE                    'ma-const-amend-64-s1-constitutional-officers' END,
       CASE c.grp
         WHEN 'legislature' THEN
           'Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII — "The terms '
             || 'of senators and representatives shall begin with the first Wednesday in January '
             || 'succeeding their election and shall extend to the first Wednesday in January in '
             || 'the third year following their election and until their successors are chosen '
             || 'and qualified." The first Wednesday in January 2027 is the 6th. The clause names '
             || 'the day the TERM begins; the oath (Part 2, Ch. VI, Art. I) gates the discharge '
             || 'of the duties and is a separate, later event.'
         WHEN 'gov-ltgov' THEN
           'Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII — "The terms '
             || 'of the governor and lieutenant-governor shall begin at noon on the Thursday '
             || 'next following the first Wednesday in January succeeding their election." The '
             || 'first Wednesday in January 2027 is the 6th, so the Thursday next following it '
             || 'is 2027-01-07. 🔴 ONE DAY AFTER THE LEGISLATURE, NOT THE SAME DAY.'
         ELSE
           'Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII — "The terms '
             || 'of the secretary, treasurer and receiver-general, attorney general, and auditor '
             || 'shall begin with the third Wednesday in January succeeding their election." The '
             || 'third Wednesday in January 2027 is the 20th. 🔴 FOURTEEN DAYS AFTER THE '
             || 'LEGISLATURE. The same sentence-group names three different days and this is the '
             || 'latest of them.'
       END,
       'https://malegislature.gov/Laws/Constitution — the General Court''s own publication of '
         || 'the Constitution of the Commonwealth, fetched and read in full 2026-11-22 (458,545 '
         || 'bytes). The text is at "Article LXXXII" in the Articles of Amendment. ⚠ Two '
         || 'SUPERSEDED versions of Art. LXIV § 1 are printed on the same page and read '
         || 'plausibly; Art. LXIV as adopted is marked superseded by Art. LXXX, and Art. LXXX by '
         || 'Art. LXXXII. All three carry the same three-way split, but only Art. LXXXII puts '
         || 'the governor on a four-year term, which is what makes 2026 a gubernatorial year. '
         || CASE c.grp
              WHEN 'legislature' THEN
                'Controlled against a year this file does not write: the House Journal for the '
                  || 'convening of the 193rd General Court '
                  || '(https://malegislature.gov/Journal/House/193/hj01042023.pdf, read '
                  || '2026-11-22) records that it "convened at the State House in Boston on the '
                  || 'first Wednesday of January, being the fourth day of the year two thousand '
                  || 'twenty-three" — the rule and the day it produced, in the body''s own words.'
              ELSE
                'Controlled against a term already in the database: Maura Healey''s governorship '
                  || 'starts 2023-01-05, written by migration 1459 from a pass that never read '
                  || 'this clause. That is the Thursday next following the first Wednesday in '
                  || 'January 2023, and it is that date only if the first Wednesday was the 4th '
                  || '— so one recorded term measures the anchor all three of this file''s dates '
                  || 'are computed from.'
            END,
       CASE c.grp
         WHEN 'legislature' THEN
           '🔴 MASSACHUSETTS DOES NOT DATE ITS STATE TIER TOGETHER. One sentence-group names '
             || 'three days: legislators 2027-01-06, Governor and Lieutenant Governor '
             || '2027-01-07, and the Attorney General, Treasurer and Auditor 2027-01-20. A file '
             || 'that copied this date onto the Attorney General would put her in office two '
             || 'weeks early. Written by CC_0481.'
         WHEN 'gov-ltgov' THEN
           'The clause says "at NOON"; essentials.office_swearing_in carries a date and not a '
             || 'time, so the hour is recorded here and not in the column. 🔴 This is one day '
             || 'AFTER the legislature and thirteen days BEFORE the other three executives. '
             || 'Written by CC_0481.'
         ELSE
           '🔴 THE LEAST INTUITIVE OF MASSACHUSETTS'' THREE DATES, AND THE ONE WITH THE WEAKEST '
             || 'CORROBORATION. Our own data holds no term start for any of these three offices, '
             || 'so the clause stands on its own text plus a news dateline: Campbell, Galvin and '
             || 'Goldberg were sworn on 2023-01-18, the third Wednesday of that January. A '
             || 'dateline is not a document. ⚠ The Secretary of the Commonwealth belongs to this '
             || 'group in law and is undated only because no 2026 result is recorded for it. '
             || 'Written by CC_0481.'
       END
  FROM cc0481_sel c;

DO $$
DECLARE n bigint; b record; first_wed date; d date;
BEGIN
  SELECT * INTO b FROM cc0481_before;

  -- 1. 🔴🔴 THE THREE GROUPS CARRY THREE DIFFERENT DAYS. This is the assertion that stands
  --    between Massachusetts and a two-week error on three named officials.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0481_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp = 'legislature'
     AND s.swearing_in_date = DATE '2027-01-06';
  IF n <> 199 THEN
    RAISE EXCEPTION '1: % of 199 legislative seats carry 2027-01-06.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0481_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp = 'gov-ltgov'
     AND s.swearing_in_date = DATE '2027-01-07';
  IF n <> 2 THEN
    RAISE EXCEPTION '1: % of 2 seats in the governor group carry 2027-01-07.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0481_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND c.grp = 'constitutional-officers'
     AND s.swearing_in_date = DATE '2027-01-20';
  IF n <> 3 THEN
    RAISE EXCEPTION '1: % of 3 third-Wednesday seats carry 2027-01-20.', n;
  END IF;

  -- 2. Exactly three distinct dates were written, and they are these three. A fourth would mean
  --    the CASE fell through somewhere.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s JOIN cc0481_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 3 THEN
    RAISE EXCEPTION '2: % distinct swearing-in dates were written, expected exactly 3.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0481_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date NOT IN (DATE '2027-01-06', DATE '2027-01-07', DATE '2027-01-20');
  IF n <> 0 THEN
    RAISE EXCEPTION '2: % row(s) carry a date that is none of the three.', n;
  END IF;

  -- 3. 🔴🔴 THE CLAUSE EVALUATED AS WRITTEN, FROM ONE ANCHOR, AND CHECKED AGAINST A CYCLE THIS
  --    FILE DOES NOT WRITE. All three dates are the first Wednesday in January plus 0, +1 and
  --    +14, so computing three literals separately would have hidden an error in the anchor.
  --
  --    (a) the first Wednesday in January 2027
  SELECT DATE '2027-01-01' + ((10 - EXTRACT(ISODOW FROM DATE '2027-01-01'))::int % 7)
    INTO first_wed;
  IF first_wed <> DATE '2027-01-06' THEN
    RAISE EXCEPTION '3a: the first Wednesday in January 2027 computes as %, not 2027-01-06.',
      first_wed;
  END IF;

  --    (b) the other two derived from it, as the clause derives them. ⚠ EVERY MESSAGE PRINTS
  --        THE ANCHOR as well as the computed day: these three dates differ only by an offset,
  --        so "the third Wednesday is wrong" and "the anchor is wrong" produce the same symptom
  --        and a message that omits the anchor cannot tell them apart.
  IF first_wed + 1 <> DATE '2027-01-07' THEN
    RAISE EXCEPTION '3b: anchor %, so the Thursday next following computes as %, not '
                    '2027-01-07.', first_wed, first_wed + 1;
  END IF;
  IF first_wed + 14 <> DATE '2027-01-20' THEN
    RAISE EXCEPTION '3b: anchor %, so the third Wednesday computes as %, not 2027-01-20.',
      first_wed, first_wed + 14;
  END IF;

  --        🔴 AND "THIRD" IS PLUS 14, NOT PLUS 7. Off by one Wednesday is 2027-01-13, a real
  --        Wednesday in the right month, so it would look entirely plausible in the column.
  IF first_wed + 7 = DATE '2027-01-20' THEN
    RAISE EXCEPTION '3b: anchor % plus 7 equals 2027-01-20, so this formula is counting the '
                    'SECOND Wednesday and calling it the third.', first_wed;
  END IF;

  --    (c) 🟢🟢 THE SAME ANCHOR FOR THE 2022 CYCLE, AGAINST A TERM ALREADY IN THE DATABASE.
  --        Maura Healey's governorship starts 2023-01-05. That is the Thursday next following
  --        the first Wednesday in January 2023 — and it is that date ONLY IF the anchor is the
  --        4th. One recorded term therefore pins all three of this file's dates.
  SELECT DATE '2023-01-01' + ((10 - EXTRACT(ISODOW FROM DATE '2023-01-01'))::int % 7) INTO d;
  IF d <> DATE '2023-01-04' THEN
    RAISE EXCEPTION '3c: the first Wednesday in January 2023 computes as %, not 2023-01-04 — '
                    'which is the day the House Journal says the 193rd General Court convened. '
                    'The anchor formula is wrong.', d;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ma' AND dd.district_type = 'STATE_EXEC' AND o.title = 'Governor'
     AND t.term_start = d + 1;
  IF n <> 1 THEN
    RAISE EXCEPTION '3c: % Massachusetts governor term(s) start %, expected 1. The clause that '
                    'dates 2027-01-07 should also explain the term already in the database, and '
                    'it does not.', n, d + 1;
  END IF;

  --    (d) ⚠ AND THE CORROBORATION STOPS THERE — ASSERTED, NOT ASSUMED. No Massachusetts
  --        legislative term and no non-Governor executive term carries a start date anywhere in
  --        this database. A future reader must not believe those dates were checked against our
  --        own rows, because they cannot be.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ma' AND dd.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND t.term_start IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '3d: % Massachusetts legislative term(s) now carry a start date. When this '
                    'file was written there were none, so the legislative date had NO '
                    'corroboration in our own data. If rows have appeared, check this file''s '
                    'date against them before trusting it.', n;
  END IF;

  -- 4. 🔴 2nd PLYMOUTH DISTRICT WAS NOT DATED. It carries a 2026 race with no recorded result,
  --    which is exactly as invisible as having no race. Dating it would assert that this pass
  --    had looked at an election it has not.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ma' AND s.election_date = DATE '2026-11-03'
     AND dd.label = '2nd Plymouth District';
  IF n <> 0 THEN
    RAISE EXCEPTION '4: 2nd Plymouth District was dated, and it has no recorded 2026 result.';
  END IF;

  -- 5. 🔴🔴 NOT ONE LEGISLATIVE SEAT CARRIES AN EXECUTIVE DATE, AND NO EXECUTIVE CARRIES THE
  --    LEGISLATURE'S. This is the same claim as assertion 1 read from the other side, and it is
  --    the one that catches a CASE that fell through rather than a count that came up short.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0481_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND ((c.grp = 'legislature'             AND s.swearing_in_date <> DATE '2027-01-06')
       OR (c.grp = 'gov-ltgov'               AND s.swearing_in_date <> DATE '2027-01-07')
       OR (c.grp = 'constitutional-officers' AND s.swearing_in_date <> DATE '2027-01-20'));
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % seat(s) carry a date belonging to another group. Massachusetts'' three '
                    'groups are a fortnight apart at the extremes.', n;
  END IF;

  -- 6. 🔴 THE SECRETARY OF THE COMMONWEALTH WAS NOT DATED, and neither was anything outside the
  --    three state district types. 10 other Massachusetts offices already carried a 2026-11-03
  --    row — the congressional and Senate seats — so the state total must move by exactly 204.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ma' AND s.election_date = DATE '2026-11-03'
     AND o.title = 'Secretary of the Commonwealth';
  IF n <> 0 THEN
    RAISE EXCEPTION '6: the Secretary of the Commonwealth was dated, and no 2026 result is '
                    'recorded for that office.';
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'ma' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_ma + 204 THEN
    RAISE EXCEPTION '6: Massachusetts rows for this election went % -> %, a delta of %, expected '
                    '204.', b.rows_ma, n, n - b.rows_ma;
  END IF;

  -- 7. Repo-wide, exactly 204 rows were added — no other state was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 204 THEN
    RAISE EXCEPTION '7: office_swearing_in went % -> %, a delta of %, expected 204.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 8. No term was written. CC_0483, CC_0484 and CC_0485 seat.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0481_sel c ON c.office_id = t.office_id
   WHERE t.term_start IN (DATE '2027-01-06', DATE '2027-01-07', DATE '2027-01-20');
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % term(s) were written. This file records dates and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0481 OK: 199 Massachusetts legislative seats dated 2027-01-06, the Governor '
               'and Lieutenant Governor 2027-01-07 (noon), and the Attorney General, Treasurer '
               'and Auditor 2027-01-20 — one clause, three days, fourteen apart at the extremes '
               '(Mass. Const. Amend. Art. LXIV §1 as appearing in Amend. Art. LXXXII). The '
               'anchor was computed, not written: first Wednesday in January 2027 = 2027-01-06, '
               'plus 1 and plus 14, controlled against Healey''s recorded 2023-01-05. 2nd '
               'Plymouth District and the Secretary of the Commonwealth left undated; no terms '
               'written.';
END $$;

COMMIT;
