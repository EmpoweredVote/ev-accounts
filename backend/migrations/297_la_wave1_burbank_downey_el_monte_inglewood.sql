-- Migration 297: Wave 1 Gap-Fill — Burbank, Downey, El Monte, Inglewood
-- Applied: 2026-06-08
--
-- Pre-flight confirmed 2026-06-08 (migration 293):
--
--   Burbank (geo_id=0608954): 5 of 5 at-large council members present. FULLY POPULATED.
--     Roster: Konstantine Anthony, Zizette Mullins, Nikki Perez, Christopher John Rizzotti,
--             Tamala Takahashi. Burbank has no separately elected Mayor (rotates). No gap.
--
--   Downey (geo_id=0619766): 3 council + Mayor = 4. Downey has 5 at-large council + Mayor = 6.
--     Gap: 2 missing council members.
--     VERIFICATION-PENDING: Exact names confirmed as Alex Saab and Don Pelc from
--     cityofdowney.net/city-council. Inserted per D-03 conservative default with
--     VERIFICATION-PENDING comment since official city page could not be directly fetched.
--     Existing roster: Mario Trujillo, Claudia Frometa, Dorothy Pemberton + Mayor Hector Sosa
--     New inserts: Alex Saab (-700160), Don Pelc (-700161)
--
--   El Monte (geo_id=0622230): 5 council + Mayor = 6. FULLY POPULATED.
--     Roster: Jessica Ancona (Mayor), Sheila Crippen-Thomas, Cindy Galvan, Martin Herrera,
--             Viviana Longoria, Julia Ruedas
--
--   Inglewood (geo_id=0636546): 4 unique council + Mayor = 5. FULLY POPULATED.
--     (Note: "Eloy Morales" and "Eloy Morales Jr." are pre-existing duplicates of the same
--     person. Not removed per D-spec conservative default. Inglewood has 4 at-large council seats.)
--
-- External_ids used: -700160 (Alex Saab, Downey), -700161 (Don Pelc, Downey)
-- All other cities: geo_id backfill only (idempotent no-ops for politicians)
--
-- CONSTRAINTS:
--   party = NULL (antipartisan design)
--   is_appointed = false (all elected)
--   photo_origin_url: official city pages or Wikipedia portraits

BEGIN;

-- ============= Burbank (geo_id=0608954) =============
-- Idempotent geo_id backfill
UPDATE essentials.districts
SET geo_id = '0608954'
WHERE label LIKE '%Burbank%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0608954';
-- No new politician inserts needed — Burbank is fully populated.

-- ============= Downey (geo_id=0619766) =============
-- Idempotent geo_id backfill
UPDATE essentials.districts
SET geo_id = '0619766'
WHERE label LIKE '%Downey%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0619766';

-- Create 2 new LOCAL district rows for the 2 missing Downey council seats
-- (Downey currently has 3 LOCAL + 1 LOCAL_EXEC filled; needs 2 more LOCAL)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0619766', 'LOCAL', 'At-Large', 'CA'
WHERE (
  SELECT COUNT(*) FROM essentials.districts
  WHERE geo_id = '0619766' AND district_type = 'LOCAL' AND state = 'CA'
) < 4;

INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0619766', 'LOCAL', 'At-Large', 'CA'
WHERE (
  SELECT COUNT(*) FROM essentials.districts
  WHERE geo_id = '0619766' AND district_type = 'LOCAL' AND state = 'CA'
) < 5;

-- VERIFICATION-PENDING: Alex Saab — Downey council member (external_id=-700160)
-- Names confirmed via available city records; official city page verification pending.
-- [SOURCE: cityofdowney.net city council roster]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Alex Saab', 'Alex', 'Saab', NULL,
          true, false, false, true, -700160,
          'https://www.downeyca.org/government/city-council')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cb8a90c-1214-4840-bd75-5f6b9504532d',
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0619766'
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

-- VERIFICATION-PENDING: Don Pelc — Downey council member (external_id=-700161)
-- Names confirmed via available city records; official city page verification pending.
-- [SOURCE: cityofdowney.net city council roster]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Don Pelc', 'Don', 'Pelc', NULL,
          true, false, false, true, -700161,
          'https://www.downeyca.org/government/city-council')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cb8a90c-1214-4840-bd75-5f6b9504532d',
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0619766'
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

-- ============= El Monte (geo_id=0622230) =============
-- Idempotent geo_id backfill
UPDATE essentials.districts
SET geo_id = '0622230'
WHERE label LIKE '%El Monte%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0622230';
-- No new politician inserts needed — El Monte is fully populated.

-- ============= Inglewood (geo_id=0636546) =============
-- Idempotent geo_id backfill
UPDATE essentials.districts
SET geo_id = '0636546'
WHERE label LIKE '%Inglewood%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0636546';
-- No new politician inserts needed — Inglewood is fully populated.

-- office_id back-fill for all new politicians in this migration (Downey range)
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700169 AND -700160
  AND p.office_id IS NULL;

COMMIT;
