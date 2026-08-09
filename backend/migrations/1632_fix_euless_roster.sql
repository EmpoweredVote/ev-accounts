-- 1632: correct the City of Euless, Texas, US council roster seeded by 1628.
--
-- RENUMBERED from 1631. A concurrent session pushed 1631_seed_ca_county_batch2.sql
-- with the same number; this file moved because it landed first and was already
-- applied, so moving it disturbs no in-flight work. Content is unchanged.
--
-- WHAT WAS WRONG
-- 1628 seeded 4 of 7 Euless seats VACANT and put Tim Stinneford on Council Member
-- Place 1. Against the city's own roster page, five of seven rows were wrong:
--
--   seat     1628 seeded          actually holds (eulesstx.gov, verified 2026-08-08)
--   Mayor    vacant               Tim Stinneford            (term expires May 2029)
--   Place 1  Tim Stinneford       Zariyan Stark             (term expires May 2028)
--   Place 2  vacant               Jeremy Tompkins           (term expires May 2029)
--   Place 3  Eddie Price          Eddie Price          OK   (term expires May 2028)
--   Place 4  vacant               Perry Bynum, Mayor Pro Tem(term expires May 2029)
--   Place 5  vacant               Annabel Eads              (term expires May 2027)
--   Place 6  Tika Paudel          Tika Paudel          OK   (term expires May 2027)
--
-- ROOT CAUSE, worth not repeating: 1628 derived occupancy from published Tarrant
-- County ELECTION RESULTS. Texas cities cancel an election when a candidate is
-- unopposed, so an unopposed winner leaves no results row at all -- and 1628 read
-- that absence as a vacancy. Its own header says the missing seats "appear in NO
-- published Tarrant County election ... the signature of unopposed candidates whose
-- election was cancelled", then seeded them vacant anyway. Election results are a
-- lower-tier source than the jurisdiction's own roster page; seed from the roster.
--
-- Headshots are NOT touched. politician_images keys on politician_id, so the three
-- existing portraits stayed attached to the right people even while Stinneford sat
-- on the wrong office row. The four new members have no image yet -- that is a
-- follow-up /find-headshots run, and their portraits are on the per-seat pages.
--
-- Source: https://www.eulesstx.gov/city-hall/euless-city-council (+ per-seat pages)

BEGIN;

-- Pre-flight: fail loudly if the DB is not in the exact shape this migration expects,
-- so a re-run or a roster that changed under us cannot half-apply.
DO $$
DECLARE
  v_gov uuid;
  v_p1  uuid;
  v_may uuid;
  v_vac int;
BEGIN
  SELECT g.id INTO v_gov FROM essentials.governments g
    WHERE g.name = 'City of Euless, Texas, US';
  IF v_gov IS NULL THEN
    RAISE EXCEPTION 'Pre-flight FAILED: City of Euless government row not found';
  END IF;

  SELECT o.id INTO v_p1 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE c.government_id = v_gov AND o.title = 'Council Member Place 1';
  SELECT o.id INTO v_may FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE c.government_id = v_gov AND o.title = 'Mayor';

  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms
                  WHERE office_id = v_p1
                    AND politician_id = '79268918-17a1-4698-8307-51d795e4d315') THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Stinneford is not on Place 1 - already fixed?';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.office_terms WHERE office_id = v_may) THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Mayor seat already has a term row';
  END IF;

  SELECT count(*) INTO v_vac FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE c.government_id = v_gov AND o.is_vacant;
  IF v_vac <> 4 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 4 vacant Euless seats, found %', v_vac;
  END IF;
END $$;

-- 1. Move Stinneford from Place 1 to Mayor. Both the office_terms row (which drives
--    occupancy via current_office_holders) and politicians.office_id must move --
--    that column is populated on every Tarrant-seeded row, so leaving it would make
--    the two disagree.
UPDATE essentials.office_terms ot
   SET office_id = may.id,
       source = 'Euless roster correction 2026-08-08; eulesstx.gov/city-hall/euless-city-council'
  FROM (SELECT o.id FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.name = 'City of Euless, Texas, US' AND o.title = 'Mayor') may
 WHERE ot.politician_id = '79268918-17a1-4698-8307-51d795e4d315';

UPDATE essentials.politicians p
   SET office_id = may.id
  FROM (SELECT o.id FROM essentials.offices o
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.name = 'City of Euless, Texas, US' AND o.title = 'Mayor') may
 WHERE p.id = '79268918-17a1-4698-8307-51d795e4d315';

-- 2. Seed the four members 1628 missed. office_id is set ON THE INSERT: data-modifying
--    CTEs cannot see each other's rows, so a follow-up UPDATE would scan a stale
--    snapshot and match zero rows (same trap documented in 1628).
--    party NULL (antipartisan), role_canonical NULL, external_id NULL, term dates NULL
--    -- matches every existing Tarrant TX city row.
WITH seats(title, full_name, first_name, last_name) AS (VALUES
  ('Council Member Place 1', 'Zariyan Stark',   'Zariyan', 'Stark'),
  ('Council Member Place 2', 'Jeremy Tompkins', 'Jeremy',  'Tompkins'),
  ('Council Member Place 4', 'Perry Bynum',     'Perry',   'Bynum'),
  ('Council Member Place 5', 'Annabel Eads',    'Annabel', 'Eads')
), tgt AS (
  SELECT s.full_name, s.first_name, s.last_name, o.id AS office_id
    FROM seats s
    JOIN essentials.offices o ON o.title = s.title
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Euless, Texas, US' AND c.name = 'City Council'
), pol AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_incumbent, is_vacant,
     office_id, data_source)
  SELECT gen_random_uuid(), t.full_name, t.first_name, t.last_name, NULL,
         true, true, false, t.office_id,
         'Euless roster correction 2026-08-08; eulesstx.gov/city-hall/euless-city-council'
    FROM tgt t
  RETURNING id, office_id
)
INSERT INTO essentials.office_terms
  (id, office_id, politician_id, term_start, term_end, start_precision, source)
SELECT gen_random_uuid(), p.office_id, p.id, NULL, NULL, 'day',
       'Euless roster correction 2026-08-08; eulesstx.gov/city-hall/euless-city-council'
  FROM pol p;

-- 3. All seven seats are now filled.
UPDATE essentials.offices o
   SET is_vacant = false, vacant_since = NULL
  FROM essentials.chambers c, essentials.governments g
 WHERE c.id = o.chamber_id AND g.id = c.government_id
   AND g.name = 'City of Euless, Texas, US'
   AND o.is_vacant;

-- Post-check: 7 seats, 7 distinct holders, 0 vacant, and the two seats that were
-- already correct still point at the same people.
DO $$
DECLARE
  v_seats int; v_held int; v_vac int; v_may text; v_p1 text;
BEGIN
  SELECT count(*),
         count(*) FILTER (WHERE och.politician_id IS NOT NULL),
         count(*) FILTER (WHERE o.is_vacant)
    INTO v_seats, v_held, v_vac
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Euless, Texas, US';

  IF v_seats <> 7 OR v_held <> 7 OR v_vac <> 0 THEN
    RAISE EXCEPTION 'Post-check FAILED: seats=% held=% vacant=% (want 7/7/0)',
      v_seats, v_held, v_vac;
  END IF;

  SELECT p.full_name INTO v_may
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'City of Euless, Texas, US' AND o.title = 'Mayor';
  SELECT p.full_name INTO v_p1
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'City of Euless, Texas, US' AND o.title = 'Council Member Place 1';

  IF v_may <> 'Tim Stinneford' OR v_p1 <> 'Zariyan Stark' THEN
    RAISE EXCEPTION 'Post-check FAILED: Mayor=% Place1=%', v_may, v_p1;
  END IF;
END $$;

COMMIT;
