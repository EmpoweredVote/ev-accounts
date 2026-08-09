-- 1634: correct the City of Arlington, Texas, US council roster seeded by 1624.
--
-- WHAT WAS WRONG
-- 1624 seeded 2 of Arlington's 9 seats VACANT. Both are in fact filled:
--
--   seat                                 1624 seeded   actually holds (arlingtontx.gov, 2026-08-08)
--   Council Member District 3            vacant        Nikkie Hunter      (elected June 2021)
--   Council Member District 8 (At-Large) vacant        Dr. Jason Shelton  (first elected June 2026)
--
-- SAME ROOT CAUSE AS 1632 (Euless). The Tarrant seed wave derived occupancy from
-- published Tarrant County ELECTION RESULTS. Texas cities cancel the election when a
-- candidate is unopposed, so an unopposed winner leaves no results row at all and the
-- seed read that absence as a vacancy. The city's own council page lists NINE members
-- against our 7-filled/2-vacant.
--   -> Seed occupancy from the jurisdiction's roster page. Use election results only
--      for margins and dates.
--
-- Checked at the same time: Fort Worth, Grapevine, Mansfield, North Richland Hills and
-- Tarrant County all report 0 vacant seats, so the wave has no other instance of this.
--
-- Headshots are NOT touched here; politician_images keys on politician_id. Portraits for
-- both members exist on the council page under the same
-- /files/assets/city/v/1/city-council/images/ path as the other seven and are a follow-on.
--
-- Source: https://www.arlingtontx.gov/Government/City-Government/City-Council/City-Council-Members

BEGIN;

DO $$
DECLARE
  v_gov uuid; v_vac int; v_seats int;
BEGIN
  SELECT g.id INTO v_gov FROM essentials.governments g
    WHERE g.name = 'City of Arlington, Texas, US';
  IF v_gov IS NULL THEN
    RAISE EXCEPTION 'Pre-flight FAILED: City of Arlington government row not found';
  END IF;

  SELECT count(*), count(*) FILTER (WHERE o.is_vacant) INTO v_seats, v_vac
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;

  IF v_seats <> 9 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 9 Arlington seats, found %', v_seats;
  END IF;
  IF v_vac <> 2 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 2 vacant Arlington seats, found % - already fixed?', v_vac;
  END IF;

  IF EXISTS (
    SELECT 1 FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = v_gov
       AND o.title IN ('Council Member District 3', 'Council Member District 8 (At-Large)')
  ) THEN
    RAISE EXCEPTION 'Pre-flight FAILED: a term row already exists on D3 or D8';
  END IF;
END $$;

-- office_id is set ON THE INSERT: data-modifying CTEs cannot see each other's rows, so a
-- follow-up UPDATE would scan a stale snapshot and match zero rows (trap documented in 1628).
-- party NULL (antipartisan), term dates NULL - matches every existing Tarrant TX city row.
-- "Dr. Jason Shelton" keeps the honorific the city itself uses, consistent with the existing
-- "Dr. Jim Vaszauskas" row in Mansfield; first/last stay Jason/Shelton for matching.
WITH seats(title, full_name, first_name, last_name) AS (VALUES
  ('Council Member District 3',            'Nikkie Hunter',     'Nikkie', 'Hunter'),
  ('Council Member District 8 (At-Large)', 'Dr. Jason Shelton', 'Jason',  'Shelton')
), tgt AS (
  SELECT s.full_name, s.first_name, s.last_name, o.id AS office_id
    FROM seats s
    JOIN essentials.offices o ON o.title = s.title
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Arlington, Texas, US' AND c.name = 'City Council'
), pol AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_incumbent, is_vacant,
     office_id, data_source)
  SELECT gen_random_uuid(), t.full_name, t.first_name, t.last_name, NULL,
         true, true, false, t.office_id,
         'Arlington roster correction 2026-08-08; arlingtontx.gov City Council Members'
    FROM tgt t
  RETURNING id, office_id
)
INSERT INTO essentials.office_terms
  (id, office_id, politician_id, term_start, term_end, start_precision, source)
SELECT gen_random_uuid(), p.office_id, p.id, NULL, NULL, 'day',
       'Arlington roster correction 2026-08-08; arlingtontx.gov City Council Members'
  FROM pol p;

UPDATE essentials.offices o
   SET is_vacant = false, vacant_since = NULL
  FROM essentials.chambers c, essentials.governments g
 WHERE c.id = o.chamber_id AND g.id = c.government_id
   AND g.name = 'City of Arlington, Texas, US'
   AND o.is_vacant;

DO $$
DECLARE
  v_seats int; v_held int; v_vac int; v_d3 text; v_d8 text;
BEGIN
  SELECT count(*),
         count(*) FILTER (WHERE och.politician_id IS NOT NULL),
         count(*) FILTER (WHERE o.is_vacant)
    INTO v_seats, v_held, v_vac
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Arlington, Texas, US';

  IF v_seats <> 9 OR v_held <> 9 OR v_vac <> 0 THEN
    RAISE EXCEPTION 'Post-check FAILED: seats=% held=% vacant=% (want 9/9/0)', v_seats, v_held, v_vac;
  END IF;

  SELECT p.full_name INTO v_d3
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'City of Arlington, Texas, US' AND o.title = 'Council Member District 3';
  SELECT p.full_name INTO v_d8
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'City of Arlington, Texas, US' AND o.title = 'Council Member District 8 (At-Large)';

  IF v_d3 <> 'Nikkie Hunter' OR v_d8 <> 'Dr. Jason Shelton' THEN
    RAISE EXCEPTION 'Post-check FAILED: D3=% D8=%', v_d3, v_d8;
  END IF;
END $$;

COMMIT;
