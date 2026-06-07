-- =============================================================================
-- Migration 288: DC School Board of Education (SBOE) — 9 Members
-- DCOF-03, DCOF-04
-- External IDs: -600019 (Patterson) through -600027 (Johnson-Law)
--
-- District FKs (all district_type = 'SCHOOL_BOARD', state = 'DC'):
--   Patterson: dc-sboe-at-large (tiger_geoid = NULL per D-07)
--   Williams–Johnson-Law: dc-sboe-ward-1 through dc-sboe-ward-8
-- =============================================================================

BEGIN;

-- -600019: Jacque Patterson — SBOE Member (At-Large), President
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Jacque Patterson', 'Jacque', 'Patterson', 'Democratic',
          true, false, false, true, -600019,
          'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Patterson%20Headshot%202025.jpeg')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'SBOE Member (At-Large)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-sboe-at-large'
  AND d.district_type = 'SCHOOL_BOARD'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600020: Ben Williams — SBOE Member (Ward 1)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Ben Williams', 'Ben', 'Williams', 'Democratic',
          true, false, false, true, -600020,
          'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Williams%20Headshot%202025.jpeg')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'SBOE Member (Ward 1)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-sboe-ward-1'
  AND d.district_type = 'SCHOOL_BOARD'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600021: Allister Chang — SBOE Member (Ward 2)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Allister Chang', 'Allister', 'Chang', 'Democratic',
          true, false, false, true, -600021,
          'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Chang%20Headshot%202025.jpeg')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'SBOE Member (Ward 2)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-sboe-ward-2'
  AND d.district_type = 'SCHOOL_BOARD'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600022: Eric Goulet — SBOE Member (Ward 3), Vice President
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Eric Goulet', 'Eric', 'Goulet', 'Democratic',
          true, false, false, true, -600022,
          'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/photobatch-27-2.jpg')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'SBOE Member (Ward 3)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-sboe-ward-3'
  AND d.district_type = 'SCHOOL_BOARD'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600023: T. Michelle Colson — SBOE Member (Ward 4)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'T. Michelle Colson', 'T. Michelle', 'Colson', 'Democratic',
          true, false, false, true, -600023,
          'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Colson%20Headshot%202025.jpeg')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'SBOE Member (Ward 4)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-sboe-ward-4'
  AND d.district_type = 'SCHOOL_BOARD'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600024: Robert Henderson — SBOE Member (Ward 5)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Robert Henderson', 'Robert', 'Henderson', 'Democratic',
          true, false, false, true, -600024,
          'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Henderson%20Headshot%202025.jpeg')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'SBOE Member (Ward 5)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-sboe-ward-5'
  AND d.district_type = 'SCHOOL_BOARD'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600025: Brandon Best — SBOE Member (Ward 6)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Brandon Best', 'Brandon', 'Best', 'Democratic',
          true, false, false, true, -600025,
          'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Best%20Headshot%202025.jpeg')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'SBOE Member (Ward 6)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-sboe-ward-6'
  AND d.district_type = 'SCHOOL_BOARD'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600026: Eboni-Rose Thompson — SBOE Member (Ward 7)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Eboni-Rose Thompson', 'Eboni-Rose', 'Thompson', 'Democratic',
          true, false, false, true, -600026,
          'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Thompson%20Headshot%202025.jpeg')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'SBOE Member (Ward 7)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-sboe-ward-7'
  AND d.district_type = 'SCHOOL_BOARD'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600027: LaJoy Johnson-Law — SBOE Member (Ward 8)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'LaJoy Johnson-Law', 'LaJoy', 'Johnson-Law', 'Democratic',
          true, false, false, true, -600027,
          'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Johnson-Law%20Headshot%202025.jpeg')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'SBOE Member (Ward 8)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-sboe-ward-8'
  AND d.district_type = 'SCHOOL_BOARD'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

COMMIT;
