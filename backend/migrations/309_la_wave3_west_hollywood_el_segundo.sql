BEGIN;
-- West Hollywood FIPS: 0684410 (verified via Census Geocoder API per migration 304_la_wave3_preflight_west_hollywood_fips.sql)
-- CORRECTION: RESEARCH.md inferred 0684346 — INCORRECT. Verified code 0684410 used throughout this migration.
-- Source: https://geocoding.geo.census.gov/geocoder/geographies/address?street=8300+Santa+Monica+Blvd&city=West+Hollywood&state=CA&benchmark=Public_AR_Current&vintage=Current_Current&format=json
-- Census place file st06_ca_place2020.txt: CA|06|84410|02412221|West Hollywood city|INCORPORATED PLACE|C1|A|Los Angeles County

-- Migration 309: Wave 3 — West Hollywood (verified FIPS) + El Segundo (at-large)
-- Depends on: 304_la_wave3_preflight_west_hollywood_fips.sql
-- External_id range: West Hollywood -700600..-700604; El Segundo -700650..-700654
-- Applied: 2026-06-08

-- ============================================================
-- SECTION 1: CITY OF WEST HOLLYWOOD
-- At-large council (5 members), NO separately elected Mayor (Mayor rotates by annual council selection)
-- FIPS geo_id: 0684410 (VERIFIED via Census Geocoder API and st06_ca_place2020.txt — see file header)
-- D-04: single LOCAL district; no LOCAL_EXEC district (Mayor is rotational — same pattern as Culver City)
-- External_ids: -700600..-700604
-- ============================================================

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of West Hollywood', 'LOCAL', 'CA', 'West Hollywood', '0684410'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of West Hollywood' AND state = 'CA'
);

-- Step 2: Chamber (City Council ONLY — Mayor is rotational, NOT separately elected per Pitfall 8)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'West Hollywood City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of West Hollywood' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of West Hollywood' AND state = 'CA')
);

-- Step 3: Single LOCAL district for at-large council (geo_id = VERIFIED FIPS 0684410)
-- NO LOCAL_EXEC district (Mayor is rotational — no separately elected Mayor)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0684410', 'LOCAL', 'West Hollywood (At-Large)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0684410' AND district_type = 'LOCAL' AND state = 'CA'
);

-- Step 4: John Heilman (-700600, Mayor 2026 by council rotation — formal title = Council Member)
-- Source: weho.org news Jan 2026 (VERIFIED; 9th rotation as Mayor, began Jan 2026)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'John Heilman', 'John', 'Heilman', NULL,
          true, false, false, true, -700600,
          'https://www.weho.org/government/city-council/john-heilman')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of West Hollywood' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0684410'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 5: Danny Hang (-700601, Vice Mayor — formal title = Council Member)
-- Source: weho.org, Beverly Press Dec 2025 (VERIFIED; first term began ~Jan 2025)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Danny Hang', 'Danny', 'Hang', NULL,
          true, false, false, true, -700601,
          'https://www.weho.org/government/city-council/danny-hang')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of West Hollywood' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0684410'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Chelsea Byers (-700602)
-- Source: weho.org (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Chelsea Byers', 'Chelsea', 'Byers', NULL,
          true, false, false, true, -700602,
          'https://www.weho.org/government/city-council/chelsea-byers')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of West Hollywood' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0684410'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Lauren Meister (-700603)
-- Source: weho.org (VERIFIED; term ends Dec 2026)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Lauren Meister', 'Lauren', 'Meister', NULL,
          true, false, false, true, -700603,
          'https://www.weho.org/government/city-council/lauren-meister')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of West Hollywood' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0684410'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: John Erickson (-700604)
-- Source: weho.org (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'John Erickson', 'John', 'Erickson', NULL,
          true, false, false, true, -700604,
          'https://www.weho.org/government/city-council/john-erickson')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of West Hollywood' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0684410'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION 2: CITY OF EL SEGUNDO
-- At-large council (5 members), NO separately elected Mayor (Mayor rotates by council selection)
-- FIPS geo_id: 0622412 (VERIFIED: Census place file st06_ca_place2020.txt)
-- External_ids: -700650..-700654
-- ============================================================

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of El Segundo', 'LOCAL', 'CA', 'El Segundo', '0622412'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of El Segundo' AND state = 'CA'
);

-- Step 2: Chamber (City Council ONLY — Mayor is rotational, NOT separately elected)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'El Segundo City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of El Segundo' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of El Segundo' AND state = 'CA')
);

-- Step 3: Single LOCAL district for at-large council (NO LOCAL_EXEC — Mayor is rotational)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0622412', 'LOCAL', 'El Segundo (At-Large)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0622412' AND district_type = 'LOCAL' AND state = 'CA'
);

-- Step 4: Chris Pimentel (-700650, Mayor 2026 by council rotation — formal title = Council Member)
-- Source: elsegundo.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Chris Pimentel', 'Chris', 'Pimentel', NULL,
          true, false, false, true, -700650,
          'https://www.elsegundo.org/government/departments/city-council/chris-pimentel')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of El Segundo' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0622412'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 5: Ryan Baldino (-700651, Mayor Pro Tem — formal title = Council Member)
-- Source: elsegundo.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Ryan Baldino', 'Ryan', 'Baldino', NULL,
          true, false, false, true, -700651,
          'https://www.elsegundo.org/government/departments/city-council/ryan-baldino')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of El Segundo' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0622412'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Drew Boyles (-700652)
-- Source: elsegundo.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Drew Boyles', 'Drew', 'Boyles', NULL,
          true, false, false, true, -700652,
          'https://www.elsegundo.org/government/departments/city-council/drew-boyles')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of El Segundo' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0622412'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Lance Giroux (-700653)
-- Source: elsegundo.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Lance Giroux', 'Lance', 'Giroux', NULL,
          true, false, false, true, -700653,
          'https://www.elsegundo.org/government/departments/city-council/lance-giroux')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of El Segundo' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0622412'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Michelle Keldorf (-700654)
-- Source: elsegundo.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Michelle Keldorf', 'Michelle', 'Keldorf', NULL,
          true, false, false, true, -700654,
          'https://www.elsegundo.org/government/departments/city-council/michelle-keldorf')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of El Segundo' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0622412'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION 3: OFFICE_ID BACK-FILL
-- Bounded to West Hollywood + El Segundo external_id range
-- ============================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700654 AND -700600
  AND p.office_id IS NULL;

COMMIT;
