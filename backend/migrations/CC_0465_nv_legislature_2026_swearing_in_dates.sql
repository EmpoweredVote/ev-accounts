-- CC_0465 — Nevada Assembly and Senate: the start date for all 52 seats won on 2026-11-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THIS DATE IS IN THE PAST. THE 52 MEMBERS HAVE HELD THEIR SEATS SINCE 2026-11-04.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Every other state sourced in this pass starts in December 2026 or January 2027. Nevada's
-- legislature started THE DAY AFTER THE ELECTION, so our pages have been naming the
-- predecessors as current for nineteen days and nothing has said so. This file records the
-- date; CC_0466 creates the twelve people who do not exist; CC_0467 writes the terms.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE AUTHORITY — ONE QUEUE ROW, TWO PROVISIONS, AND THEY ARE NOT THE SAME CLAUSE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Nev. Const. art. 4 § 3(1) — the Assembly:
--   "The members of the Assembly shall be chosen biennially by the qualified electors of their
--    respective districts, on the Tuesday next after the first Monday in November and THEIR TERM
--    OF OFFICE SHALL BE TWO YEARS FROM THE DAY NEXT AFTER THEIR ELECTION."
--
-- Nev. Const. art. 4 § 4(1) — the Senate:
--   "Senators shall be chosen at the same time and places as members of the Assembly by the
--    qualified electors of their respective districts, and THEIR TERM OF OFFICE SHALL BE FOUR
--    YEARS FROM THE DAY NEXT AFTER THEIR ELECTION."
--
-- Election 2026-11-03 → "the day next after" → 2026-11-04, for both chambers.
--
-- 🔴 THE TWO CHAMBERS CARRY DIFFERENT `authority` TEXT, NOT ONE SHARED STRING. The dates agree;
--    the provisions do not. A Senate seat dated on the Assembly's clause would cite a provision
--    that does not govern it, and nothing downstream would ever notice. They share a `rule_id`
--    because they are one rule of construction, applied twice.
--
-- 🟢 THIS IS INDIANA'S CLAUSE IN DIFFERENT WORDS, AND THIS REPO HAS ALREADY RULED ON IT.
--    CC_0463 read Ind. Const. art. 4 § 3 — "from the day next after their general election" — as
--    2026-11-04, and CC_0464 seated three members on it. Assertion 3 below re-measures that
--    agreement from inside this transaction rather than asserting it in a comment.
--
-- ⚠ CONTRAST MAINE, WHICH USES THE OPPOSITE PREPOSITION FOR THE OPPOSITE EFFECT: "two years from
--   the day next PRECEDING the first Wednesday in December". Nevada and Indiana count forward
--   from the election; Maine counts back from the meeting. Three states in this pass hinge on
--   "the day next X" and X is not the same word.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- TERM START OR SWEARING-IN? — TERM START. THEY ARE DIFFERENT EVENTS HERE AND THE STATUTE SAYS SO
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The clause names a calendar day computed from the election and says nothing about an oath.
-- NRS 282.010(1) still requires members to take the oath "before entering upon the duties" of
-- the office — the familiar split — and it does not move the term start.
--
-- 🟢 THE CARVE-OUT IN NRS 282.010(2) IS THE CONTROL ON THAT READING, FROM THE OPPOSITE
--    DIRECTION. That subsection makes every elected officer qualify "prior to the Tuesday after
--    the first Monday in January ensuing their election" — and it EXCLUDES "Senators and members
--    of the Assembly" by name. The exclusion only makes sense because their terms already began
--    in November under art. 4. The statute and the constitution agree, from opposite ends.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE SIX NEVADA EXECUTIVES GET NO ROW, AND THAT IS A FINDING, NOT AN OMISSION
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Nev. Const. art. 5 § 2 gives the Governor four years "FROM THE TIME OF HIS INSTALLATION";
-- art. 5 §§ 17 and 19(1) give the Lieutenant Governor, Secretary of State, Treasurer, Controller
-- and Attorney General "the same term as is prescribed for the Governor"; and NRS 282.010(4)
-- says the term of all officers "shall BEGIN FROM THE TIME OF THEIR QUALIFICATION".
--
-- So those six begin on the day each person qualifies — an EVENT, not a calendar date, and one
-- that has not happened yet. `basis = 'estimated'` would be the wrong answer twice over: it may
-- not seat anybody, and it would assert a day nobody has observed. They are refused, with a
-- sourced upper bound (NRS 282.010(2): prior to 2027-01-05, so `window_end_date = 2027-01-04`),
-- and that row is written when the qualification happens. Assertion 4 below asserts this file
-- wrote nothing for them.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS FILE WRITES NO TERM AND SEATS NOBODY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- It records a date so CC_0467 can READ one rather than carry a literal. A date written into a
-- seating file agrees with itself however wrong it is — which is the whole reason this pass
-- separates the two.
--
-- Overwrites nothing: P1 refuses if any of the 52 already carries a row for this election, so
-- there is no prior value for this file to record.
--
-- Sources, fetched and read 2026-11-22 and re-read 2026-11-23:
--   https://www.leg.state.nv.us/Const/NvConst.html         (HTTP 200, 431,607 bytes)
--   https://www.leg.state.nv.us/NRS/NRS-282.html
--   https://www.leg.state.nv.us/NRS/NRS-223.html
-- all three the Legislative Counsel Bureau's own publications.

BEGIN;

CREATE TEMP TABLE cc0465_sel ON COMMIT DROP AS
SELECT o.id AS office_id, d.district_type, d.label AS seat
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'nv'
   AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0465_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in) AS rows_all;

DO $$
DECLARE n bigint;
BEGIN
  -- P1 — exactly the body this file was written against: 41 Assembly + 11 Senate.
  SELECT count(*) INTO n FROM cc0465_sel;
  IF n <> 52 THEN
    RAISE EXCEPTION 'P1: % Nevada legislative seats are pending, expected 52. The data moved '
                    'under this file.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0465_sel WHERE district_type = 'STATE_LOWER';
  IF n <> 41 THEN
    RAISE EXCEPTION 'P1: % Assembly seats, expected 41.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0465_sel WHERE district_type = 'STATE_UPPER';
  IF n <> 11 THEN
    RAISE EXCEPTION 'P1: % Senate seats, expected 11.', n;
  END IF;

  -- P2 — this file has not already been applied, asked BEFORE anything that could be read as
  -- the data having moved. On a second apply the 52 would still be pending (this file writes no
  -- term), so P1 would pass and this is the gate that stops it.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0465_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 52 already carry a swearing-in row for this election. This '
                    'file would overwrite a date it has not recorded.', n;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2026-11-04',
       'statute',
       'nv-const-art4-day-next-after-election',
       CASE c.district_type
         WHEN 'STATE_LOWER' THEN
           'Nev. Const. art. 4 § 3(1) — members of the Assembly are chosen "on the Tuesday next '
             || 'after the first Monday in November and their term of Office shall be two years '
             || 'from the day next after their election". The clause names the day the TERM '
             || 'begins; the oath required by NRS 282.010(1) is a separate event and does not '
             || 'move it.'
         ELSE
           'Nev. Const. art. 4 § 4(1) — senators "shall be chosen at the same time and places as '
             || 'members of the Assembly … and their term of Office shall be four years from the '
             || 'day next after their election". The clause names the day the TERM begins; the '
             || 'oath required by NRS 282.010(1) is a separate event and does not move it.'
       END,
       'https://www.leg.state.nv.us/Const/NvConst.html — the Legislative Counsel Bureau''s own '
         || 'publication of the Nevada Constitution, fetched and read 2026-11-22 (HTTP 200, '
         || '431,607 bytes). Corroborated from the opposite direction by NRS 282.010(2), '
         || 'https://www.leg.state.nv.us/NRS/NRS-282.html, which sets a January qualification '
         || 'deadline for elected officers and EXCLUDES "Senators and members of the Assembly" '
         || 'by name — an exclusion that only makes sense because their terms began in November. '
         || 'The membership was cross-read against the Legislature''s own roster at '
         || 'https://www.leg.state.nv.us/App/Legislator/A/{Assembly,Senate}/Current/, which had '
         || 'already rolled to Session/84th2027 and names the 2026 winners as the CURRENT '
         || 'members of all 42 Assembly and 21 Senate districts (read 2026-11-22, re-read '
         || '2026-11-23).',
       'Written by CC_0465 so CC_0467 can read the date rather than carry a literal. Nevada''s '
         || 'six state executives are deliberately NOT in this file: Nev. Const. art. 5 § 2 and '
         || 'NRS 282.010(4) begin their terms at QUALIFICATION, an event that has not happened. '
         || 'Their sourced upper bound is 2027-01-04 (NRS 282.010(2)).'
  FROM cc0465_sel c;

DO $$
DECLARE n bigint; b record;
BEGIN
  SELECT * INTO b FROM cc0465_before;

  -- 1. Exactly 52 rows, on the 52 selected offices, carrying the day after the election.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0465_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-11-04';
  IF n <> 52 THEN
    RAISE EXCEPTION '1: % of 52 seats carry the date.', n;
  END IF;

  -- 2. Repo-wide, exactly 52 rows were added — no other office was swept in.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 52 THEN
    RAISE EXCEPTION '2: office_swearing_in went % -> %, a delta of %, expected 52.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 3. 🔴 NEVADA AND INDIANA READ "FROM THE DAY NEXT AFTER THEIR ELECTION" THE SAME WAY. Indiana
  --    was dated by CC_0463 from its own constitution, independently of this file, and 24 more
  --    Indiana House terms written by CA_0374 and CA_0396 already start on that day. If this
  --    file had read the construction differently, the repo would hold two answers for one form
  --    of words and nothing would have said so. This measures the agreement instead of asserting
  --    it in a comment.
  SELECT count(DISTINCT s.swearing_in_date) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE s.election_date = DATE '2026-11-03'
     AND ((lower(d.state) = 'in' AND d.district_type = 'STATE_LOWER')
          OR (lower(d.state) = 'nv' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')));
  IF n <> 1 THEN
    RAISE EXCEPTION '3: Nevada and Indiana together carry % distinct dates for the same form of '
                    'words ("from the day next after their election"), expected 1.', n;
  END IF;

  -- 4. 🔴 THE SIX NEVADA EXECUTIVES WERE NOT SWEPT IN. Their terms begin at qualification
  --    (Nev. Const. art. 5 § 2; NRS 282.010(4)), which is an event nobody has observed. A row
  --    for them would be a date this file cannot source.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nv' AND d.district_type = 'STATE_EXEC'
     AND s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % Nevada STATE_EXEC seat(s) were dated. Their terms begin at '
                    'qualification and this file may not claim a day for them.', n;
  END IF;

  -- 5. The Assembly cites art. 4 § 3 and the Senate cites art. 4 § 4 — not one shared string.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0465_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND ((c.district_type = 'STATE_LOWER' AND s.authority NOT LIKE '%art. 4 § 3(1)%')
       OR (c.district_type = 'STATE_UPPER' AND s.authority NOT LIKE '%art. 4 § 4(1)%'));
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % seat(s) cite the other chamber''s provision.', n;
  END IF;

  -- 6. No term was written. That is CC_0467's job, from the date this file just recorded.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0465_sel c ON c.office_id = t.office_id
   WHERE t.term_start = DATE '2026-11-04';
  IF n <> 0 THEN
    RAISE EXCEPTION '6: % term(s) were written. This file records a date and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0465 OK: 52 Nevada legislative seats (41 Assembly, 11 Senate) dated '
               '2026-11-04 per Nev. Const. art. 4 §§ 3(1), 4(1); the 6 state executives left '
               'undated because their terms begin at qualification; no terms written.';
END $$;

COMMIT;
