-- =============================================================================
-- Migration 286: DC Mayor + 13 DC Council Members — Politician + Office Records
-- DCOF-01, DCOF-04
-- External IDs: -600001 (Bowser) through -600014 (Trayon White, Sr.)
--
-- District FKs:
--   Bowser + 5 at-large council members → dc-council-at-large (CITY_COUNCIL)
--   Ward 1–8 members → dc-ward-1..dc-ward-8 (CITY_COUNCIL)
--
-- party = 'Democratic' for all DC officials
-- chamber_id = NULL (no chamber records for DC in this phase)
-- photo_origin_url IS NOT NULL for all 14 records
-- =============================================================================

BEGIN;

-- -600001: Muriel Bowser — Mayor
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Muriel Bowser', 'Muriel', 'Bowser', 'Democratic',
          true, false, false, true, -600001, 'https://mayor.dc.gov/biography/muriel-bowser')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Mayor', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-council-at-large'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600002: Phil Mendelson — Council Chairman (At-Large)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Phil Mendelson', 'Phil', 'Mendelson', 'Democratic',
          true, false, false, true, -600002, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Chairman (At-Large)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-council-at-large'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600003: Anita Bonds — Council Member (At-Large)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Anita Bonds', 'Anita', 'Bonds', 'Democratic',
          true, false, false, true, -600003, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (At-Large)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-council-at-large'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600004: Robert C. White, Jr. — Council Member (At-Large)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Robert C. White, Jr.', 'Robert', 'White', 'Democratic',
          true, false, false, true, -600004, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (At-Large)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-council-at-large'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600005: Christina Henderson — Council Member (At-Large)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Christina Henderson', 'Christina', 'Henderson', 'Democratic',
          true, false, false, true, -600005, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (At-Large)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-council-at-large'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600006: Doni Crawford — Council Member (At-Large)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Doni Crawford', 'Doni', 'Crawford', 'Democratic',
          true, false, false, true, -600006, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (At-Large)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-council-at-large'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600007: Brianne K. Nadeau — Council Member (Ward 1)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Brianne K. Nadeau', 'Brianne', 'Nadeau', 'Democratic',
          true, false, false, true, -600007, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (Ward 1)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-ward-1'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600008: Brooke Pinto — Council Member (Ward 2)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Brooke Pinto', 'Brooke', 'Pinto', 'Democratic',
          true, false, false, true, -600008, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (Ward 2)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-ward-2'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600009: Matthew Frumin — Council Member (Ward 3)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Matthew Frumin', 'Matthew', 'Frumin', 'Democratic',
          true, false, false, true, -600009, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (Ward 3)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-ward-3'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600010: Janeese Lewis George — Council Member (Ward 4)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Janeese Lewis George', 'Janeese', 'Lewis George', 'Democratic',
          true, false, false, true, -600010, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (Ward 4)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-ward-4'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600011: Zachary Parker — Council Member (Ward 5)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Zachary Parker', 'Zachary', 'Parker', 'Democratic',
          true, false, false, true, -600011, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (Ward 5)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-ward-5'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600012: Charles Allen — Council Member (Ward 6)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Charles Allen', 'Charles', 'Allen', 'Democratic',
          true, false, false, true, -600012, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (Ward 6)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-ward-6'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600013: Wendell Felder — Council Member (Ward 7)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Wendell Felder', 'Wendell', 'Felder', 'Democratic',
          true, false, false, true, -600013, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (Ward 7)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-ward-7'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600014: Trayon White, Sr. — Council Member (Ward 8)
-- Ward 8: Trayon White Sr. expelled Feb 2025, won special election July 2025, rejoined Aug 2025. Current incumbent as of 2026-06-07.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Trayon White, Sr.', 'Trayon', 'White', 'Democratic',
          true, false, false, true, -600014, 'https://dccouncil.gov/councilmembers/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Council Member (Ward 8)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-ward-8'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

COMMIT;
