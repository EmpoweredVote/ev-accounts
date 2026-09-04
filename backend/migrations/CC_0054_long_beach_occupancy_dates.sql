-- CC_0054_long_beach_occupancy_dates.sql
--
-- Long Beach, CA — replace 13 undated occupancy rows with dated, sourced ones.
-- Wave CA-1 of the Knight Foundation cities program. Apply AFTER
-- CC_0053_long_beach_council_district_geometry.sql.
--
-- Spec:    docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
-- Roster:  backend/data/seed-long-beach-2026/ROSTERS.md
-- Tracker: .planning/knight-foundation/PROGRAM.md
--
-- ── WHAT IS WRONG ──────────────────────────────────────────────────────────────────────────────
-- All 13 Long Beach office_terms rows read:
--
--     term_start NULL, start_precision 'unknown',
--     source 'backfill from essentials.offices.politician_id (ADR 0002 phase 2)'
--
-- and essentials.politician_occupancy_evidence classes every one of them 'undated_term'. The names
-- came from a vendor snapshot (politician_source 'cicero' on seven of the nine councilmembers,
-- 'longbeach.gov' on four, blank on two) that was never change-checked. The people are right — the
-- change-check below re-established that from the city's own sources — but nothing recorded WHEN
-- any of them took office, and nothing recorded that anyone had looked.
--
-- ── THE CHANGE-CHECK, WHICH IS THE POINT OF THIS MIGRATION ─────────────────────────────────────
-- 🔴🔴 A CHANGE-CHECK ASKS "HAS THIS PERSON LEFT?", NOT "DO MY SOURCES AGREE?"
--
-- Long Beach held its Primary Nominating Election on 2026-06-02 and it is certified. Seven of the
-- thirteen seats were on that ballot and every one was decided outright. NONE of those winners is
-- in office. Charter Sec. 1901 commences the terms on the third Tuesday of December — 2026-12-15 —
-- and the City Clerk's own 2026 candidate packet prints that date. Today is 2026-09-02.
--
--   🔴 DISTRICT 7 TURNS OVER ON 2026-12-15. Roberto Uranga is term-limited; the candidate packet
--      prints "Not eligible to run for an additional term due to term limits" against his name.
--      Vivian Malauulu won the seat outright with 74.12%. She is NOT written here. Writing her now
--      would be the Columbus error in a new dress: a certified result is not a fact about who holds
--      the seat.
--
-- City Attorney and City Prosecutor are absent from the results file because LBMC 1.15.150 lets the
-- Council APPOINT a sole nominee and cancel the contest; both resolutions are on file and both
-- appoint for the term commencing 2026-12-15. That is a cancelled election, not a missing result.
--
-- No other change was found. The council roster page, the nine district pages, the site navigation
-- and the city's own GIS layer all carry the same thirteen names, and Legistar shows no end date
-- before 2026-12-15 for any of them.
--
-- ── WHERE THE DATES COME FROM ──────────────────────────────────────────────────────────────────
-- Legistar — the city's OWN legislative system — publishes day-precision office records:
--   webapi.legistar.com/v1/longbeach/bodies/{1,29,30,31}/officeRecords  and  /persons/2449/...
-- Read 2026-09-02. Its chains are gapless by one day (Burroughs ends 2006-06-30, Doud starts
-- 2006-07-18; Parkin ends 2022-12-19, McIntosh starts 2022-12-20), and its turnover dates confirm
-- the charter rule independently: 2010-07-20 and 2014-07-15 under the old third-Tuesday-in-July
-- rule, then 2020-12-15, 2022-12-20 and 2024-12-17 under the current third-Tuesday-in-December one.
--
-- 🔴 term_start is the start of CONTINUOUS OCCUPANCY BY THAT PERSON OF THAT OFFICE, not the start
--    of the current term. Re-election does not end an occupancy. Two consequences here:
--      * Rex Richardson's Mayor occupancy starts 2022-12-20. He held District 9 from 2014-07-15,
--        but that is a different seat.
--      * Tunua Thrash-Ntuk LOST District 8 in 2020 (43.23% to Al Austin) and won it in 2024. Her
--        occupancy starts 2024-12-17 and is NOT continuous from 2020. A roster read without the
--        certified results would have got this wrong in the safe-looking direction.
--
-- Two of the thirteen dates are DERIVED rather than stated, and both are recorded as such in
-- ROSTERS.md and in the per-row source below:
--
--   Doug Haubert, City Prosecutor — Legistar starts him on 2010-04-13, which is the date of the
--     Primary Nominating Election he won, while his predecessor Thomas M. Reeves' record ends
--     2010-07-19. Taken literally the two rows assert both men held the office for three months.
--     Written here as 2010-07-20: the day after Reeves ends, the third Tuesday in July 2010, and
--     the same date Legistar gives every councilmember elected in that cycle.
--
--   Tunua Thrash-Ntuk, District 8 — no Legistar officeRecords row starts after 2024-12-17, so the
--     December 2024 cohort is simply absent from that table. Written here as 2024-12-17, from Al
--     Austin's District 8 record ENDING on that day, her outright win in the 2024-03-05 Primary
--     Nominating Election, and the charter rule. All three agree.
--
-- ⚠ THE CITY CLERK'S OWN ELECTIONS FAQ IS STALE AND WOULD HAVE DATED EVERY ONE OF THESE ROWS FOUR
--   TO FIVE MONTHS EARLY. It still quotes the pre-2020 Sec. 1901: April primary, June general,
--   "assume such office on the third Tuesday in July". It is used here for the pre-2020 rule alone
--   (Doud 2006, Haubert 2010, Uranga 2014) and for nothing else. A stale page on the authoritative
--   site is more dangerous than a missing one, because it is consistent enough to look right.
--
-- ── WHAT THIS DOES NOT DO ──────────────────────────────────────────────────────────────────────
-- No term_end is written anywhere. Every one of these thirteen people holds office until at least
-- 2026-12-15, and a future term_end makes a seat silently self-vacate on the day it arrives. The
-- District 7 handover is a note for the next wave, not a row.
--
-- No office is created, no person is created, no row is deleted. Thirteen UPDATEs against thirteen
-- existing open-ended term rows. Narrowing an open-ended range cannot collide with the
-- office_terms_no_overlap exclusion constraint, because each office has exactly one term row.
--
-- Idempotent: the post-verify gate asserts the END STATE, so a re-run is a no-op that still proves
-- the end state.

BEGIN;

-- ── Preconditions ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_offices integer;
  v_seated  integer;
  v_terms   integer;
BEGIN
  -- 1. Thirteen offices, thirteen seated holders.
  --    🔴 count(och.politician_id), never count(*) -- office_current_holder LEFT JOINs from
  --    offices, so a vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(o.id), count(och.politician_id) INTO v_offices, v_seated
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'ca'
     AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:long_beach%'
     AND d.district_type IN ('LOCAL','LOCAL_EXEC');
  IF v_offices <> 13 OR v_seated <> 13 THEN
    RAISE EXCEPTION 'long beach occupancy: expected 13 offices and 13 seated holders, found % offices and % seated', v_offices, v_seated;
  END IF;

  -- 2. Exactly one term row per office. Two would mean this UPDATE picks one arbitrarily.
  SELECT count(*) INTO v_terms
    FROM (SELECT o.id
            FROM essentials.districts d
            JOIN essentials.offices o ON o.district_id = d.id
            JOIN essentials.office_terms ot ON ot.office_id = o.id
           WHERE lower(d.state) = 'ca'
             AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:long_beach%'
             AND d.district_type IN ('LOCAL','LOCAL_EXEC')
           GROUP BY o.id
          HAVING count(*) <> 1) s;
  IF v_terms <> 0 THEN
    RAISE EXCEPTION 'long beach occupancy: % office(s) carry more than one term row', v_terms;
  END IF;
END $$;

-- ── Write the dates ────────────────────────────────────────────────────────────────────────────
-- Each row is matched on (district label, office title, politician full_name) TOGETHER. Matching on
-- full_name alone seats the wrong person on a homonym; matching on the office alone would write a
-- date against whoever happens to sit there. Requiring all three means a roster change since
-- 2026-09-02 makes the UPDATE miss, and the post-verify gate then fails loudly instead of writing a
-- date against a stranger.
UPDATE essentials.office_terms ot
   SET term_start      = v.term_start,
       start_precision = 'day',
       how_started     = 'elected',
       source          = v.src
  FROM essentials.offices o,
       essentials.districts d,
       essentials.politicians p,
       (VALUES
        -- district label                 office title       full name            term_start    source
        ('Long Beach Mayor',            'Mayor',           'Rex Richardson',     DATE '2022-12-20', 'Long Beach Legistar persons/2449/officeRecords (Mayor''s Office), read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        ('Long Beach City Attorney',    'City Attorney',   'Dawn McIntosh',      DATE '2022-12-20', 'Long Beach Legistar bodies/29/officeRecords, read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        ('Long Beach City Auditor',     'City Auditor',    'Laura Doud',         DATE '2006-07-18', 'Long Beach Legistar bodies/30/officeRecords, read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        -- DERIVED: Legistar starts Haubert on the election date 2010-04-13 while Reeves' record
        -- ends 2010-07-19. See the header.
        ('Long Beach City Prosecutor',  'City Prosecutor', 'Doug Haubert',       DATE '2010-07-20', 'derived: Long Beach Legistar bodies/31/officeRecords (predecessor Reeves ends 2010-07-19) + Charter Sec. 1901 third Tuesday in July, read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        ('District 1',                  'Councilmember',   'Mary Zendejas',      DATE '2019-12-03', 'Long Beach Legistar bodies/1/officeRecords, read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        ('District 2',                  'Councilmember',   'Cindy Allen',        DATE '2020-12-15', 'Long Beach Legistar bodies/1/officeRecords, read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        ('District 3',                  'Councilmember',   'Kristina Duggan',    DATE '2022-12-20', 'Long Beach Legistar bodies/1/officeRecords, read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        ('District 4',                  'Councilmember',   'Daryl Supernaw',     DATE '2015-04-27', 'Long Beach Legistar bodies/1/officeRecords, read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        ('District 5',                  'Councilmember',   'Megan Kerr',         DATE '2022-12-20', 'Long Beach Legistar bodies/1/officeRecords, read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        ('District 6',                  'Councilmember',   'Suely Saro',         DATE '2020-12-15', 'Long Beach Legistar bodies/1/officeRecords, read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        ('District 7',                  'Councilmember',   'Roberto Uranga',     DATE '2014-07-15', 'Long Beach Legistar bodies/1/officeRecords, read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        -- DERIVED: Legistar holds no officeRecords row starting after 2024-12-17. See the header.
        ('District 8',                  'Councilmember',   'Tunua Thrash-Ntuk',  DATE '2024-12-17', 'derived: Long Beach Legistar bodies/1/officeRecords (predecessor Austin ends 2024-12-17) + City Clerk certified 2024-03-05 Primary Nominating Election, read 2026-09-02 -- migration CC_0054 (Knight CA-1)'),
        ('District 9',                  'Councilmember',   'Joni Ricks-Oddie',   DATE '2022-12-20', 'Long Beach Legistar bodies/1/officeRecords, read 2026-09-02 -- migration CC_0054 (Knight CA-1)')
      ) AS v(label, title, full_name, term_start, src)
 WHERE ot.office_id = o.id
   AND ot.politician_id = p.id
   AND d.id = o.district_id
   AND lower(d.state) = 'ca'
   AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:long_beach%'
   AND d.label = v.label
   AND o.title = v.title
   AND p.full_name = v.full_name;

-- ── Post-verify: the END STATE, not the delta ──────────────────────────────────────────────────
DO $$
DECLARE
  v_n        integer;
  v_min      date;
  v_max      date;
  v_bad      text;
BEGIN
  -- 1. Thirteen dated, day-precision term rows, none with a term_end.
  SELECT count(*) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE lower(d.state) = 'ca'
     AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:long_beach%'
     AND d.district_type IN ('LOCAL','LOCAL_EXEC')
     AND ot.term_start IS NOT NULL
     AND ot.start_precision = 'day'
     AND ot.term_end IS NULL;
  IF v_n <> 13 THEN
    RAISE EXCEPTION 'long beach occupancy: expected 13 dated open-ended term rows at day precision, found %', v_n;
  END IF;

  -- 2. NOTHING is left undated. Separate from (1) on purpose: a fourteenth row would satisfy (1).
  SELECT count(*) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE lower(d.state) = 'ca'
     AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:long_beach%'
     AND d.district_type IN ('LOCAL','LOCAL_EXEC')
     AND (ot.term_start IS NULL OR ot.start_precision <> 'day');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'long beach occupancy: % term row(s) are still undated or not at day precision', v_n;
  END IF;

  -- 3. Every date is plausible: on or after Doud's 2006-07-18 and strictly in the past. A date in
  --    the future would mean a 2026 winner was seated early, which is the exact error this wave
  --    exists to avoid.
  SELECT min(ot.term_start), max(ot.term_start) INTO v_min, v_max
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE lower(d.state) = 'ca'
     AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:long_beach%'
     AND d.district_type IN ('LOCAL','LOCAL_EXEC');
  IF v_min <> DATE '2006-07-18' OR v_max >= CURRENT_DATE THEN
    RAISE EXCEPTION 'long beach occupancy: term_start range is % .. %, expected 2006-07-18 .. a past date', v_min, v_max;
  END IF;

  -- 4. The right people are still in the right seats. If the roster had moved under us the UPDATE
  --    would have missed those rows and (2) would already have fired -- this names the seat so the
  --    failure is readable rather than a count.
  SELECT string_agg(d.label || ' / ' || o.title || ' = ' || COALESCE(p.full_name, '(vacant)'), '; ' ORDER BY d.label)
    INTO v_bad
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_terms ot ON ot.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE lower(d.state) = 'ca'
     AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:long_beach%'
     AND d.district_type IN ('LOCAL','LOCAL_EXEC')
     AND (d.label, o.title, COALESCE(p.full_name, '')) NOT IN (
       ('Long Beach Mayor','Mayor','Rex Richardson'),
       ('Long Beach City Attorney','City Attorney','Dawn McIntosh'),
       ('Long Beach City Auditor','City Auditor','Laura Doud'),
       ('Long Beach City Prosecutor','City Prosecutor','Doug Haubert'),
       ('District 1','Councilmember','Mary Zendejas'),
       ('District 2','Councilmember','Cindy Allen'),
       ('District 3','Councilmember','Kristina Duggan'),
       ('District 4','Councilmember','Daryl Supernaw'),
       ('District 5','Councilmember','Megan Kerr'),
       ('District 6','Councilmember','Suely Saro'),
       ('District 7','Councilmember','Roberto Uranga'),
       ('District 8','Councilmember','Tunua Thrash-Ntuk'),
       ('District 9','Councilmember','Joni Ricks-Oddie'));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'long beach occupancy: the roster has moved since 2026-09-02 -- %; re-run the change-check in backend/data/seed-long-beach-2026/ROSTERS.md', v_bad;
  END IF;

  -- 5. Nobody carries a term_end. A future term_end makes a seat silently self-vacate on the day
  --    it arrives, and District 7 does not hand over until 2026-12-15.
  SELECT count(*) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE lower(d.state) = 'ca'
     AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:long_beach%'
     AND d.district_type IN ('LOCAL','LOCAL_EXEC')
     AND ot.term_end IS NOT NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'long beach occupancy: % term row(s) carry a term_end; none should', v_n;
  END IF;

  RAISE NOTICE 'long beach occupancy: 13 term rows dated at day precision, 2006-07-18 .. 2024-12-17, no term_end written; District 7 hands over to Vivian Malauulu on 2026-12-15 and is NOT written here';
END $$;

COMMIT;
