-- CC_0499 — Maryland: the Governor's start date for the 2026-11-03 election.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE THIRD WEDNESDAY IN JANUARY — 2027-01-20, ONE OFFICE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- A separate wave from CC_0494, deliberately. That file dated 178 General Assembly seats to the
-- SECOND Wednesday under Art. III § 6 and **refused every Maryland state executive**, because the
-- Governor is a different clause naming a different day and the other two are refused outright.
-- This file writes the one row Art. II § 1 supports. CC_0500 seats.
--
-- 🔴🔴 **THE NEAR MISS HERE IS NOT A HYPOTHETICAL — IT IS 178 LIVE ROWS IN THIS STATE.**
--   CC_0494 wrote 2027-01-13, the SECOND Wednesday, for the whole General Assembly a week ago.
--   Reaching one week short in Maryland does not produce an absurd day; it produces the
--   legislature's correct one, on an office it does not govern. Assertion 2 computes the second,
--   third and fourth Wednesdays and refuses the two this file is not about.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE AUTHORITY — Md. Const. Art. II, § 1, QUOTED TO ITS FULL STOP
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **SECTION 1.** "The executive power of the State shall be vested in a Governor, **whose term of
--   office shall commence on the third Wednesday of January next ensuing his election**, and
--   continue for four years, and until his successor shall have qualified; and a person who has
--   served two consecutive popular elective terms of office as Governor shall be ineligible to
--   succeed himself as Governor for the term immediately following the second of said two
--   consecutive popular elective terms" (amended by Chapter 109, Acts of 1947, ratified Nov. 2,
--   1948; Chapter 161, Acts of 1964, ratified Nov. 3, 1964; Chapter 576, Acts of 1970, ratified
--   Nov. 3, 1970).
--
-- 🟢 **READ TO THE FULL STOP, AND THE TAIL IS A TERM-LIMIT CLAUSE, NOT AN ESCAPE HATCH.** Oregon's
--   Art. IV § 4(1) ends in "unless a different commencing day for such terms shall have been
--   appointed by law" and CC_0491 had to be written around it. Maryland's § 1 runs from "The
--   executive power" to "two consecutive popular elective terms" and then into its own amendment
--   history: nothing in it lets a statute move the day.
--
-- 🔴 **§ 1 IS THE TERM. § 3 IS THE QUALIFICATION, AND IT IS ALLOWED TO LAG.** Art. II § 3 says the
--   Governor and Lieutenant Governor "shall qualify, in the manner herein prescribed, on the third
--   Wednesday of January next ensuing his election, **or as soon thereafter as may be
--   practicable**". The two clauses name the same day and are different facts — the term commences
--   on the calendar date whether or not the oath is taken on it. 🔴 **This file cites § 1.** A
--   citation that is right about the date and wrong about the law is invisible to every count;
--   only a person reading the `authority` text can catch it. (Washington's CC_0487 is the worked
--   case: three citations, one date, one correct.)
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢🟢 THE CORROBORATION IS IN OUR OWN DATA AND WAS NEVER DERIVED FROM THIS CLAUSE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `essentials.office_terms` carries Wes Moore's open Governor term starting **2023-01-18**,
-- backfilled by migration 1459 from `msa.maryland.gov`. The third Wednesday of January 2023 **is**
-- the 18th. Assertion 3 computes it for 2023 — a cycle this file does not write — and compares.
--
-- 🟢 **AND THE WRONG RULE SCORES ZERO IN THAT SAME YEAR.** The second Wednesday of January 2023
--   is the 11th, and no Maryland term begins on it. One row against zero separates the two rules
--   instead of merely agreeing with one. ⚠ Only one Maryland term can take part in this control
--   at all: CC_0494's assertion 3e measured that exactly ONE Maryland legislative term carries a
--   `term_start` (Alexander M. Harlan's 2026-08-03 appointment) and the other 187 are NULL, so
--   the legislature cannot corroborate anything. The Governor's row is the whole corpus.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 MARYLAND IS THE SECOND STATE ON 2027-01-20, SO THE COUNT IS A DELTA
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Measured 2026-11-24, before this file: **3 rows already carry 2027-01-20** — Massachusetts'
-- Attorney General, Auditor of the Commonwealth and Treasurer and Receiver-General, under
-- `ma-const-amend-64-s1-constitutional-officers` (CC_0481/CC_0485). An unrelated rule in an
-- unrelated state landing on the same calendar square. ▶ P4 pins the before-image and names that
-- rule; assertion 4 asserts the delta is exactly 1 and refuses any row belonging to a third rule.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE ATTORNEY GENERAL AND THE COMPTROLLER STAY REFUSED, AND THE REASON HAS NOT CHANGED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   Attorney General  Art. V § 1 — four years "from the time of his election and qualification",
--                     naming no day.
--   Comptroller       Art. VI § 1 — "for four years, and until their successors shall qualify",
--                     naming none.
--
-- Both fall to the residual rule in Art. XVII § 4 — "The term of office of all Judges and other
-- officers … shall, except in cases otherwise expressly provided herein, commence from the time
-- of their Election" — which Art. XVII § 9 makes prevail. 🔴 **READ LITERALLY THAT DATE IS
-- 2026-11-03 AND WE CANNOT WRITE IT**: the predecessor holds "until their successor shall
-- qualify", so the two spans overlap by design, and `office_terms` carries an exclusion
-- constraint forbidding two holders of one office over overlapping ranges. The constitution's own
-- answer is a date our model cannot express, and the date we could express — the qualification —
-- is the one the constitution declines to fix. ▶ Each needs a `published` date recorded when it
-- happens. The Governor is "expressly provided" for in Art. II § 1, which is why this file exists
-- and those two do not have one.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE LIEUTENANT GOVERNOR'S TERM IS THIS SAME DAY AND WE HOLD NO WINNER FOR IT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Art. II § 1B makes the office a joint ticket and says so in the strongest available terms:
--
--   "In any election, including a primary election, candidates for Governor and Lieutenant
--    Governor shall be listed jointly on the ballot, and a vote cast for the candidate for
--    Governor shall also be cast for Lieutenant Governor jointly listed on the ballot with him,
--    and the election of Governor … also shall constitute the election **for the same term** …
--    of the Lieutenant Governor who was listed on the ballot … jointly with him."
--
-- So the Lieutenant Governor's term begins on 2027-01-20 as a matter of law, and the office was
-- on the 2026 ballot as a matter of law. **Measured 2026-11-24: Maryland's Lieutenant Governor
-- office row exists, is held by Aruna Miller, carries NO pending winner and NO 2026 race row at
-- all.**
--
-- 🔴 **THAT IS UTAH'S THIRD CLASS — "NO RACE ROW AT ALL" — NOT AN UNRECORDED RESULT**, and it
--   looks identical from the seat. It is also the mirror of Arizona's missing Lieutenant Governor
--   (CC_0497): there the office does not exist, here it does and has nobody incoming. ▶ This file
--   does NOT date it. A date on an office we hold no winner for schedules nothing and claims the
--   ticket was recorded when it was not. P5 gates on the gap staying exactly as described, so a
--   race arriving stops this wave rather than being absorbed. **It belongs to the results
--   programme.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SOURCE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   https://msa.maryland.gov/msa/mdmanual/43const/html/02art2.html — HTTP 200, 33,410 bytes,
--   fetched with a full browser header set and read as text 2026-11-24. The Maryland Manual
--   On-Line is the Maryland State Archives' own publication of the Constitution of Maryland, and
--   each section carries its amendment history, which is how the current wording was separated
--   from the superseded one.
--
-- 🔴 **`mgaleg.maryland.gov` SERVES ITS "NotFound" PAGE WITH HTTP 200 AT EXACTLY 57,164 BYTES**
--   (measured for CC_0494). No second official copy of the constitution is obtainable there, and
--   any probe of that host must assert on CONTENT.
--
-- Term start or oath? — **TERM START.** § 1 says "shall commence on"; § 3's qualification may lag.
--
-- basis: `statute`.  rule_id: `md-const-art2-s1-third-wed-january`.

BEGIN;

CREATE TEMP TABLE cc0499_sel ON COMMIT DROP AS
SELECT o.id AS office_id, o.title, d.label AS seat
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'md'
   AND d.district_type = 'STATE_EXEC'
   AND o.title = 'Governor'
   AND w.election_date = DATE '2026-11-03';

CREATE TEMP TABLE cc0499_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.office_swearing_in)                        AS rows_all,
       (SELECT count(*) FROM essentials.office_swearing_in s
          JOIN essentials.offices o   ON o.id = s.office_id
          JOIN essentials.districts d ON d.id = o.district_id
         WHERE lower(d.state) = 'md' AND s.election_date = DATE '2026-11-03')      AS rows_md,
       (SELECT count(*) FROM essentials.office_swearing_in
         WHERE swearing_in_date = DATE '2027-01-20')                               AS rows_jan20;

DO $$
DECLARE n bigint; m bigint;
BEGIN
  -- P0 — this file has not already been applied. 🔴 ASKED FIRST, ABOVE EVERY COUNT.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0499_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P0: the Maryland Governor already carries a swearing-in row for this '
                    'election. This file would overwrite a date it has not recorded.';
  END IF;

  -- P1 — exactly one office, and it is the Governor.
  SELECT count(*) INTO n FROM cc0499_sel;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P1: % Maryland Governor office(s) are pending, expected exactly 1.', n;
  END IF;

  -- P2 — 🔴 THE OTHER TWO MARYLAND EXECUTIVES ARE PENDING AND THIS FILE DATES NEITHER.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 3 THEN
    RAISE EXCEPTION 'P2: % Maryland state executive seats are pending, expected 3 (Governor, '
                    'Attorney General, Comptroller).', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
     AND s.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % Maryland state executive seat(s) already carry a date for this '
                    'election, expected 0 — CC_0494 refused all three on purpose.', n;
  END IF;

  -- P3 — 🔴🔴 THE GENERAL ASSEMBLY'S 178 SEATS ARE ALREADY ON THE SECOND WEDNESDAY. That is this
  -- file's near miss, live, in this state, written by CC_0494 a week ago.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o   ON o.id = s.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date = DATE '2027-01-13'
     AND s.rule_id = 'md-const-art3-s6-second-wed-january';
  IF n <> 178 THEN
    RAISE EXCEPTION 'P3: % Maryland General Assembly seats carry 2027-01-13 under Art. III § 6, '
                    'expected 178. CC_0494 must have run before this file: its day is this '
                    'file''s NEAR MISS, and the near miss being live in the same state is the '
                    'whole reason assertion 2 computes three Wednesdays.', n;
  END IF;

  -- P4 — 🔴 MARYLAND IS THE SECOND STATE ON 2027-01-20. Massachusetts got here first under an
  -- unrelated rule, so the before-image is pinned and every existing row must be named.
  SELECT rows_jan20 INTO m FROM cc0499_before;
  IF m <> 3 THEN
    RAISE EXCEPTION 'P4: % row(s) already carry 2027-01-20, expected 3 (Massachusetts'' Attorney '
                    'General, Auditor of the Commonwealth and Treasurer and Receiver-General '
                    'under ma-const-amend-64-s1-constitutional-officers). A third state has '
                    'landed on this day — name its rule_id before adding to the pile.', m;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
   WHERE s.swearing_in_date = DATE '2027-01-20'
     AND s.rule_id <> 'ma-const-amend-64-s1-constitutional-officers';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P4: % row(s) on 2027-01-20 belong to a rule this file does not know. A date '
                    'shared by several states is a coincidence of calendars, never a shared '
                    'rule.', n;
  END IF;

  -- P5 — 🔴🔴 THE LIEUTENANT GOVERNOR, WHOSE TERM IS THIS SAME DAY AND WHOSE ELECTION WE DO NOT
  -- HOLD. Art. II § 1B: the election of the Governor "also shall constitute the election for the
  -- same term … of the Lieutenant Governor". The office exists, is held, and has no race row at
  -- all — Utah's third class, not an unrecorded result. Gated so a race arriving stops the wave.
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND d.district_type = 'STATE_EXEC'
     AND o.title = 'Lieutenant Governor';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P5: Maryland holds % Lieutenant Governor office row(s), expected 1.', n;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND o.title = 'Lieutenant Governor'
     AND w.election_date = DATE '2026-11-03';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: the Maryland Lieutenant Governor now carries a pending winner. Its term '
                    'begins on the SAME DAY as the Governor''s under Art. II § 1B — "the '
                    'election of Governor … also shall constitute the election for the same '
                    'term … of the Lieutenant Governor" — so this wave is larger than one office '
                    'and both files need re-reading.';
  END IF;
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date >= DATE '2026-01-01'
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'md' AND o.title = 'Lieutenant Governor';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P5: % 2026 race row(s) now exist for the Maryland Lieutenant Governor, '
                    'expected 0. When this file was written the gap was "NO RACE ROW AT ALL" — '
                    'Utah''s third class — and not an unrecorded result. Read which it has '
                    'become.', n;
  END IF;
END $$;

INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT c.office_id,
       DATE '2026-11-03',
       DATE '2027-01-20',
       'statute',
       'md-const-art2-s1-third-wed-january',
       'Md. Const. Art. II, § 1 — "The executive power of the State shall be vested in a '
         || 'Governor, whose term of office shall commence on the third Wednesday of January '
         || 'next ensuing his election, and continue for four years, and until his successor '
         || 'shall have qualified; and a person who has served two consecutive popular elective '
         || 'terms of office as Governor shall be ineligible to succeed himself as Governor for '
         || 'the term immediately following the second of said two consecutive popular elective '
         || 'terms" (amended by Chapter 109, Acts of 1947, ratified Nov. 2, 1948; Chapter 161, '
         || 'Acts of 1964, ratified Nov. 3, 1964; Chapter 576, Acts of 1970, ratified Nov. 3, '
         || '1970). The third Wednesday of January following the 2026-11-03 general election is '
         || '2027-01-20. 🟢 THE CLAUSE HAS NO ESCAPE HATCH: read to its full stop, the tail is a '
         || 'TERM-LIMIT provision, not an "unless otherwise provided by law" — unlike Or. Const. '
         || 'Art. IV Sec. 4(1). 🔴 CITED FROM § 1 (THE TERM) AND NOT § 3 (THE QUALIFICATION), '
         || 'which names the same day and then allows it to slip: "shall qualify … on the third '
         || 'Wednesday of January next ensuing his election, OR AS SOON THEREAFTER AS MAY BE '
         || 'PRACTICABLE". The term commences on the calendar date whether or not the oath is '
         || 'taken on it.',
       'https://msa.maryland.gov/msa/mdmanual/43const/html/02art2.html (HTTP 200, 33,410 bytes) '
         || '— the Maryland Manual On-Line, the Maryland State Archives'' own publication of the '
         || 'Constitution of Maryland, fetched with a full browser header set and read as text '
         || '2026-11-24, with the section''s amendment history used to separate the current '
         || 'wording from the superseded one. 🟢🟢 CORROBORATED INSIDE OUR OWN DATA, BY A ROW '
         || 'THAT WAS NEVER DERIVED FROM THIS CLAUSE: essentials.office_terms carries Wes '
         || 'Moore''s open Governor term starting 2023-01-18, backfilled by migration 1459 from '
         || 'msa.maryland.gov — and the third Wednesday of January 2023 IS the 18th. The SECOND '
         || 'Wednesday of that month, 2023-01-11, carries no Maryland term at all, which '
         || 'separates the two rules instead of merely agreeing with one. ⚠ That single row is '
         || 'the whole corpus available: CC_0494 measured that exactly one Maryland LEGISLATIVE '
         || 'term carries a term_start (Alexander M. Harlan''s 2026-08-03 appointment) and the '
         || 'other 187 are NULL. 🔴 mgaleg.maryland.gov serves its "NotFound" page with HTTP 200 '
         || 'at exactly 57,164 bytes, so no second official copy exists there; any probe of that '
         || 'host must assert on content.',
       '🔴🔴 THE NEAR MISS IS 178 LIVE ROWS IN THIS STATE. 2027-01-13 is the SECOND Wednesday and '
         || 'it is the whole General Assembly''s real commencement under Art. III § 6, written '
         || 'by CC_0494 on 2026-11-24. 2027-01-20 is the THIRD, which is this office. 2027-01-27 '
         || 'is the FOURTH and nothing in Maryland law names it. Reaching one week short here '
         || 'does not produce an absurd day; it produces the legislature''s correct one on an '
         || 'office it does not govern. '
         || '🔴 THE ATTORNEY GENERAL AND THE COMPTROLLER REMAIN REFUSED. Art. V § 1 gives the AG '
         || 'four years "from the time of his election and qualification" and Art. VI § 1 gives '
         || 'the Comptroller four years "and until their successors shall qualify"; neither '
         || 'names a day, so both fall to the residual rule in Art. XVII § 4 — "shall … commence '
         || 'from the time of their Election" — which Art. XVII § 9 makes prevail. Read '
         || 'literally both terms began on 2026-11-03 and OVERLAP the predecessors, who hold '
         || 'until their successors qualify; office_terms forbids two holders of one office over '
         || 'overlapping ranges, so the constitution''s own answer is a date our model cannot '
         || 'express. Each needs a published qualification date, recorded when it happens. The '
         || 'GOVERNOR is "expressly provided" for in Art. II § 1, which is why this office has a '
         || 'date and those two do not. '
         || '🔴🔴 THE LIEUTENANT GOVERNOR IS NOT DATED HERE AND ITS TERM IS THIS SAME DAY. Art. '
         || 'II § 1B makes it a joint ticket: "a vote cast for the candidate for Governor shall '
         || 'also be cast for Lieutenant Governor jointly listed on the ballot with him, and the '
         || 'election of Governor … also shall constitute the election FOR THE SAME TERM … of '
         || 'the Lieutenant Governor". So the office was on the 2026 ballot as a matter of law. '
         || 'Measured 2026-11-24: the office row exists, is held by Aruna Miller, and carries NO '
         || 'pending winner and NO 2026 race row at all — Utah''s "no race row" class, not an '
         || 'unrecorded result, and the mirror of Arizona''s missing Lieutenant Governor office '
         || 'in CC_0497. A date on an office we hold no winner for schedules nothing and claims '
         || 'the ticket was recorded when it was not. It belongs to the results programme. '
         || '⚠ MARYLAND IS THE SECOND STATE ON 2027-01-20: three Massachusetts constitutional '
         || 'officers were already here under ma-const-amend-64-s1-constitutional-officers, so '
         || 'every count about this day is a DELTA that names the other state''s rule. '
         || 'Written by CC_0499.'
  FROM cc0499_sel c;

DO $$
DECLARE n bigint; b record; jan1 date; first_wed date; second_wed date; third_wed date;
        fourth_wed date; jan1_2023 date; third_wed_2023 date; second_wed_2023 date;
        moore date;
        md_day        CONSTANT date := DATE '2027-01-20';   -- the third Wednesday, this file
        assembly_day  CONSTANT date := DATE '2027-01-13';   -- the second — CC_0494's 178 seats
        moore_start   CONSTANT date := DATE '2023-01-18';   -- migration 1459, from the Archives
BEGIN
  SELECT * INTO b FROM cc0499_before;

  -- 1. The one row carries the one date.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0499_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03' AND s.swearing_in_date = md_day;
  IF n <> 1 THEN
    RAISE EXCEPTION '1: the Maryland Governor does not carry %.', md_day;
  END IF;

  -- 2. 🔴🔴 THE CLAUSE EVALUATED AS WRITTEN, WITH THE NEAR MISSES COMPUTED BESIDE IT — AND ONE OF
  --    THEM IS 178 LIVE ROWS IN THIS STATE.
  jan1       := make_date(EXTRACT(YEAR FROM DATE '2026-11-03')::int + 1, 1, 1);
  first_wed  := jan1 + ((3 - EXTRACT(ISODOW FROM jan1)::int + 7) % 7);
  second_wed := first_wed + 7;
  third_wed  := first_wed + 14;
  fourth_wed := first_wed + 21;
  IF third_wed <> md_day THEN
    RAISE EXCEPTION '2a: the third Wednesday of January following 2026-11-03 computes as %, not '
                    '%.', third_wed, md_day;
  END IF;
  IF second_wed <> assembly_day THEN
    RAISE EXCEPTION '2b: the second Wednesday computes as %, but CC_0494 wrote % for the whole '
                    'General Assembly. The near-miss arithmetic is broken and the comparison '
                    'below proves nothing while it is.', second_wed, assembly_day;
  END IF;
  IF second_wed = third_wed OR third_wed = fourth_wed OR second_wed = fourth_wed THEN
    RAISE EXCEPTION '2b: the three candidate Wednesdays are not three distinct days (%, %, %).',
      second_wed, third_wed, fourth_wed;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s JOIN cc0499_sel c ON c.office_id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.swearing_in_date IN (second_wed, fourth_wed);
  IF n <> 0 THEN
    RAISE EXCEPTION '2b: the Governor carries one of the two wrong Wednesdays — % (the SECOND, '
                    'which is the whole General Assembly''s real day under Art. III § 6, and is '
                    'live on 178 rows) or % (the fourth, which no Maryland clause names).',
      second_wed, fourth_wed;
  END IF;

  -- 3. 🟢🟢 THE RULE RUN FOR A CYCLE THIS FILE DOES NOT WRITE, AGAINST A ROW THAT WAS NEVER
  --    DERIVED FROM THIS CLAUSE — AND THE WRONG RULE RUN BESIDE IT.
  jan1_2023       := make_date(2023, 1, 1);
  third_wed_2023  := jan1_2023 + ((3 - EXTRACT(ISODOW FROM jan1_2023)::int + 7) % 7) + 14;
  second_wed_2023 := jan1_2023 + ((3 - EXTRACT(ISODOW FROM jan1_2023)::int + 7) % 7) + 7;
  IF third_wed_2023 <> moore_start THEN
    RAISE EXCEPTION '3a: the third Wednesday of January 2023 computes as %, but Wes Moore''s '
                    'recorded Governor term begins %. The clause and the State Archives'' own '
                    'backfill disagree, which means this file''s reading of § 1 is wrong.',
      third_wed_2023, moore_start;
  END IF;
  SELECT t.term_start INTO moore
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'md' AND dd.district_type = 'STATE_EXEC'
     AND o.title = 'Governor' AND t.term_end IS NULL;
  IF moore IS DISTINCT FROM moore_start THEN
    RAISE EXCEPTION '3b: the open Maryland Governor term starts %, expected % (migration 1459, '
                    'backfilled from msa.maryland.gov and NEVER derived from Art. II § 1). It is '
                    'the only corroboration this date has inside our own data — CC_0494 measured '
                    'that the legislature carries exactly one term_start, an appointment. If it '
                    'has changed, re-read the argument.', moore, moore_start;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o    ON o.id = t.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'md' AND t.term_start = second_wed_2023;
  IF n <> 0 THEN
    RAISE EXCEPTION '3c: % Maryland term(s) begin on %, the SECOND Wednesday of January 2023. '
                    'Expected 0 — one row on the third against zero on the second is what '
                    'separates the two rules; agreement with one of them proves nothing.',
      n, second_wed_2023;
  END IF;

  -- 4. 🔴 THE 2027-01-20 DELTA, NAMED. Massachusetts was here first under an unrelated rule.
  SELECT count(*) INTO n FROM essentials.office_swearing_in WHERE swearing_in_date = md_day;
  IF n <> b.rows_jan20 + 1 THEN
    RAISE EXCEPTION '4: rows on % went % -> %, a delta of %, expected 1.',
      md_day, b.rows_jan20, n, n - b.rows_jan20;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.swearing_in_date = md_day
     AND NOT (lower(dd.state) = 'md' AND s.rule_id = 'md-const-art2-s1-third-wed-january')
     AND s.rule_id <> 'ma-const-amend-64-s1-constitutional-officers';
  IF n <> 0 THEN
    RAISE EXCEPTION '4: % row(s) on % belong to neither Maryland''s Art. II § 1 nor '
                    'Massachusetts'' constitutional-officers rule.', n, md_day;
  END IF;

  -- 5. Maryland rows for this election moved by exactly 1, and the other two executives have none.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'md' AND s.election_date = DATE '2026-11-03';
  IF n <> b.rows_md + 1 THEN
    RAISE EXCEPTION '5: Maryland rows for this election went % -> %, a delta of %, expected 1.',
      b.rows_md, n, n - b.rows_md;
  END IF;
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE lower(dd.state) = 'md' AND dd.district_type = 'STATE_EXEC'
     AND s.election_date = DATE '2026-11-03'
     AND o.title IN ('Attorney General', 'Comptroller', 'Lieutenant Governor', 'State Treasurer');
  IF n <> 0 THEN
    RAISE EXCEPTION '5: % Maryland executive seat(s) other than the Governor were dated. The '
                    'Attorney General and the Comptroller are REFUSED (no clause names a day for '
                    'either); the Lieutenant Governor has no recorded election at all; the State '
                    'Treasurer is chosen by the General Assembly and carries no race.', n;
  END IF;

  -- 6. Repo-wide, exactly 1 row was added.
  SELECT count(*) INTO n FROM essentials.office_swearing_in;
  IF n <> b.rows_all + 1 THEN
    RAISE EXCEPTION '6: office_swearing_in went % -> %, a delta of %, expected 1.',
      b.rows_all, n, n - b.rows_all;
  END IF;

  -- 7. The row reads back as a Maryland Governor row under this rule.
  SELECT count(*) INTO n
    FROM essentials.office_swearing_in s
    JOIN cc0499_sel c            ON c.office_id = s.office_id
    JOIN essentials.offices o    ON o.id = s.office_id
    JOIN essentials.districts dd ON dd.id = o.district_id
   WHERE s.election_date = DATE '2026-11-03'
     AND lower(dd.state) = 'md' AND dd.district_type = 'STATE_EXEC' AND o.title = 'Governor'
     AND s.basis = 'statute'
     AND s.rule_id = 'md-const-art2-s1-third-wed-january'
     AND s.authority LIKE 'Md. Const. Art. II, § 1 %';
  IF n <> 1 THEN
    RAISE EXCEPTION '7: the row does not read back as a Maryland Governor row with basis statute '
                    'under md-const-art2-s1-third-wed-january citing Art. II § 1. ⚠ § 3 names '
                    'the SAME DAY for the QUALIFICATION and is the wrong citation; no count can '
                    'see that but this one.';
  END IF;

  -- 8. No term was written. CC_0500 seats.
  SELECT count(*) INTO n FROM essentials.office_terms t
    JOIN cc0499_sel c ON c.office_id = t.office_id
   WHERE t.term_start = md_day;
  IF n <> 0 THEN
    RAISE EXCEPTION '8: % term(s) were written. This file records a date and seats nobody.', n;
  END IF;

  RAISE NOTICE 'CC_0499 OK: the Maryland Governor dated % — THE THIRD WEDNESDAY in January, Md. '
               'Const. Art. II § 1, quoted to its full stop and cited from the TERM clause '
               'rather than § 3''s identical QUALIFICATION day. The day was computed and both '
               'wrong Wednesdays computed beside it: % (the SECOND, which is the whole General '
               'Assembly''s real day under Art. III § 6 and is LIVE on 178 rows written by '
               'CC_0494) and % (the fourth, which no Maryland clause names). The rule was run '
               'again for 2023 and produced %, which is the day our own data says Wes Moore''s '
               'term began — backfilled from the State Archives and never derived from this '
               'clause — while the second Wednesday of that month carries ZERO Maryland terms. '
               'Maryland is the SECOND state on this calendar day: three Massachusetts '
               'constitutional officers were already here. The Attorney General and the '
               'Comptroller REMAIN REFUSED. ⚠ The LIEUTENANT GOVERNOR''s term is this same day '
               'under Art. II § 1B and was NOT dated: the office exists and is held, and we hold '
               'no winner and no race row for it at all.',
    md_day, second_wed, fourth_wed, third_wed_2023;
END $$;

COMMIT;
