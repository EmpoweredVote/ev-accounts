BEGIN;

-- Migration 306: Wave 3 — Carson (by-district + Mayor + elected Clerk + Treasurer) + Hawthorne (at-large + Mayor)
-- Depends on: 304_la_wave3_preflight_west_hollywood_fips.sql
-- External_id range: Carson -700300..-700306; Hawthorne -700350..-700354
-- Applied: 2026-06-08

-- ============================================================
-- SECTION 1: CITY OF CARSON
-- By-district council (4 districts) + separately elected Mayor + elected Clerk + elected Treasurer
-- FIPS geo_id: 0611530 (VERIFIED: Census place file st06_ca_place2020.txt)
-- Source: carsonca.gov/government/elected_officials/index.php (VERIFIED)
-- External_ids: Mayor -700300; D1-D4 -700301..-700304; Clerk -700305; Treasurer -700306
-- ============================================================

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Carson', 'LOCAL', 'CA', 'Carson', '0611530'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA'
);

-- Step 2: Chambers (4 chambers: City Council, Mayor, City Clerk, City Treasurer)
-- CRITICAL: slug is GENERATED ALWAYS AS — never include in INSERT column list

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Carson City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of Carson',
       (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Clerk', 'Carson City Clerk',
       (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Clerk'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Treasurer', 'Carson City Treasurer',
       (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Treasurer'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')
);

-- Step 3: 4 LOCAL district rows (one per council district)
-- CRITICAL: NO ON CONFLICT (geo_id, district_type) — constraint does not exist
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('carson-council-district-1', 'LOCAL', 'District 1', 'CA'),
  ('carson-council-district-2', 'LOCAL', 'District 2', 'CA'),
  ('carson-council-district-3', 'LOCAL', 'District 3', 'CA'),
  ('carson-council-district-4', 'LOCAL', 'District 4', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);

-- Step 4: LOCAL_EXEC district for Mayor + elected citywide officers (Clerk, Treasurer)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0611530', 'LOCAL_EXEC', 'Carson (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0611530' AND district_type = 'LOCAL_EXEC' AND state = 'CA'
);

-- Step 5: Mayor — Lula Davis-Holmes (-700300)
-- Source: carsonca.gov (VERIFIED; term expires Nov 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Lula Davis-Holmes', 'Lula', 'Davis-Holmes', NULL,
          true, false, false, true, -700300,
          'https://www.carsonca.gov/government/elected_officials/index.php')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Mayor'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0611530'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: District 1 — Jawane Hilton (-700301)
-- Source: carsonca.gov (VERIFIED; re-elected Nov 2024, term expires Nov 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Jawane Hilton', 'Jawane', 'Hilton', NULL,
          true, false, false, true, -700301,
          'https://www.carsonca.gov/government/elected_officials/index.php')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')),
       p.id,
       'Council Member (District 1)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'carson-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: District 2 — Jim Dear (-700302)
-- Source: carsonca.gov (VERIFIED; elected Nov 2022, term expires Dec 2026)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Jim Dear', 'Jim', 'Dear', NULL,
          true, false, false, true, -700302,
          'https://www.carsonca.gov/government/elected_officials/index.php')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')),
       p.id,
       'Council Member (District 2)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'carson-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: District 3 — Cedric L. Hicks Sr. (-700303, Mayor Pro Tempore — internal council title, not a separate office)
-- Source: carsonca.gov (VERIFIED; re-elected Nov 2024, term expires Nov 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Cedric L. Hicks Sr.', 'Cedric', 'Hicks', NULL,
          true, false, false, true, -700303,
          'https://www.carsonca.gov/government/elected_officials/index.php')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')),
       p.id,
       'Council Member (District 3)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'carson-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: District 4 — Arleen B. Rojas (-700304)
-- Source: carsonca.gov (VERIFIED; elected Nov 2021, term expires Nov 2026)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Arleen B. Rojas', 'Arleen', 'Rojas', NULL,
          true, false, false, true, -700304,
          'https://www.carsonca.gov/government/elected_officials/index.php')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')),
       p.id,
       'Council Member (District 4)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'carson-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 10: City Clerk — Khaleah K. Bradshaw (-700305, ELECTED per carsonca.gov VERIFIED)
-- is_appointed=false on politician; is_appointed_position=false on office (elected, not appointed)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Khaleah K. Bradshaw', 'Khaleah', 'Bradshaw', NULL,
          true, false, false, true, -700305,
          'https://www.carsonca.gov/government/elected_officials/index.php')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Clerk'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')),
       p.id,
       'City Clerk', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0611530'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 11: City Treasurer — Monica Cooper (-700306, ELECTED per carsonca.gov VERIFIED)
-- is_appointed=false on politician; is_appointed_position=false on office (elected, not appointed)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Monica Cooper', 'Monica', 'Cooper', NULL,
          true, false, false, true, -700306,
          'https://www.carsonca.gov/government/elected_officials/index.php')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Treasurer'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Carson' AND state = 'CA')),
       p.id,
       'City Treasurer', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0611530'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION 2: CITY OF HAWTHORNE
-- At-large council (4 members) + separately elected Mayor
-- FIPS geo_id: 0632548 (VERIFIED: Census place file st06_ca_place2020.txt)
-- 5th seat (Faye Johnson) VERIFIED via LA County registrar data (migration 304 T1)
-- External_ids: Mayor -700350; Council members -700351..-700354
-- ============================================================

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Hawthorne', 'LOCAL', 'CA', 'Hawthorne', '0632548'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Hawthorne' AND state = 'CA'
);

-- Step 2: Chambers (City Council + Mayor)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Hawthorne City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Hawthorne' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Hawthorne' AND state = 'CA')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of Hawthorne',
       (SELECT id FROM essentials.governments WHERE name = 'City of Hawthorne' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Hawthorne' AND state = 'CA')
);

-- Step 3: Single LOCAL district for at-large council members
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0632548', 'LOCAL', 'Hawthorne (At-Large)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0632548' AND district_type = 'LOCAL' AND state = 'CA'
);

-- Step 4: LOCAL_EXEC district for separately elected Mayor
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0632548', 'LOCAL_EXEC', 'Hawthorne (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0632548' AND district_type = 'LOCAL_EXEC' AND state = 'CA'
);

-- Step 5: Mayor — Alex Vargas (-700350)
-- Source: LA County registrar data (VERIFIED; term ends December 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Alex Vargas', 'Alex', 'Vargas', NULL,
          true, false, false, true, -700350,
          'https://en.wikipedia.org/wiki/Hawthorne,_California')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Mayor'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Hawthorne' AND state = 'CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0632548'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Katrina Manning (-700351)
-- Source: LA County registrar data (VERIFIED; term ends December 2026)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Katrina Manning', 'Katrina', 'Manning', NULL,
          true, false, false, true, -700351,
          'https://en.wikipedia.org/wiki/Hawthorne,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Hawthorne' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0632548'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Alex Monteiro (-700352)
-- Source: LA County registrar data (VERIFIED; term ends December 2026)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Alex Monteiro', 'Alex', 'Monteiro', NULL,
          true, false, false, true, -700352,
          'https://en.wikipedia.org/wiki/Hawthorne,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Hawthorne' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0632548'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Angie Reyes English (-700353)
-- Source: LA County registrar data — listed as "Angie Reyes-English" (VERIFIED; term ends December 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Angie Reyes English', 'Angie', 'Reyes English', NULL,
          true, false, false, true, -700353,
          'https://en.wikipedia.org/wiki/Hawthorne,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Hawthorne' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0632548'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: Faye Johnson (-700354)
-- 5th at-large seat VERIFIED via LA County registrar data (migration 304 T1; term ends December 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Faye Johnson', 'Faye', 'Johnson', NULL,
          true, false, false, true, -700354,
          'https://en.wikipedia.org/wiki/Hawthorne,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Hawthorne' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0632548'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION 3: OFFICE_ID BACK-FILL
-- Bounded to Carson + Hawthorne external_id range
-- ============================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700354 AND -700300
  AND p.office_id IS NULL;

COMMIT;
