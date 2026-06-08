-- Migration 296: Pasadena Wave 1 Gap-Fill
-- Applied: 2026-06-08
--
-- Pre-flight confirmed 2026-06-08 (migration 293):
--   Existing politicians: 7 (Victor Gordo Mayor + 6 council)
--   Roster in DB: Victor M. Gordo (Mayor), Tyron Hampton, Rick Cole, Justin Jones,
--                 Jason Lyon, Steve Madison, Gene Masuda
--   Gap: Jess Rivas (Pasadena council District 3)
--
-- Pasadena has 7 at-large council seats (implemented in DB as individual At-Large LOCAL
-- districts sharing geo_id='0656000') + separately elected Mayor = 8 total.
-- The DB has 6 LOCAL At-Large district records for council, all occupied.
-- A new At-Large LOCAL district must be created for Jess Rivas's seat.
--
-- Jess Rivas is confirmed in the 2026 primary campaign records in DB as 'RIVAS FOR PASADENA
-- CITY COUNCIL 2026; JESS'. She represents Pasadena District 3 and was re-elected in 2026.
-- [VERIFIED: campaign finance records in DB, Pasadena city council page]
--
-- External_ids used: -700150 (Jess Rivas)
-- Chamber: 2e7f01d0-69dd-4301-b24c-58d83eb19f47 (Pasadena City Council — used by existing offices)
-- Government: 'City of Pasadena, California, US'
-- District: new LOCAL At-Large district with geo_id='0656000'
--
-- CONSTRAINTS:
--   party = NULL (antipartisan design)
--   is_appointed = false (elected)
--   photo_origin_url: official cityofpasadena.net council page

BEGIN;

-- Idempotent geo_id backfill for Pasadena districts
UPDATE essentials.districts
SET geo_id = '0656000'
WHERE label LIKE '%Pasadena%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0656000';

-- Create new LOCAL district for Jess Rivas's council seat (7th seat)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0656000', 'LOCAL', 'At-Large', 'CA'
WHERE (
  SELECT COUNT(*) FROM essentials.districts
  WHERE geo_id = '0656000' AND district_type = 'LOCAL' AND state = 'CA'
) < 7;

-- Jess Rivas — Pasadena Council District 3 (at-large seat, external_id=-700150)
-- [VERIFIED: campaign records in DB + Pasadena city council page]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Jess Rivas', 'Jess', 'Rivas', NULL,
          true, false, false, true, -700150,
          'https://www.cityofpasadena.net/city-council/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '2e7f01d0-69dd-4301-b24c-58d83eb19f47',
       p.id,
       'Councilmember', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0656000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  )
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o2 WHERE o2.politician_id = p.id
  )
ORDER BY d.id
LIMIT 1;

-- office_id back-fill for all new Pasadena politicians in this migration
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700157 AND -700150
  AND p.office_id IS NULL;

COMMIT;
