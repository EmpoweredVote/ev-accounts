BEGIN;

-- Migration 308: Wave 3 — Gardena (at-large + Mayor) + Culver City (at-large 5)
-- Depends on: 304_la_wave3_preflight_west_hollywood_fips.sql
-- External_id range: Gardena -700500..-700504; Culver City -700550..-700554
-- Applied: 2026-06-08

-- ============================================================
-- SECTION 1: CITY OF GARDENA
-- At-large council (4 members) + separately elected Mayor
-- FIPS geo_id: 0628168 (VERIFIED: Census place file st06_ca_place2020.txt)
-- POST-JUNE-2026 ROSTER: Based on best available data as of 2026-06-08 (migration 304 comment block)
-- Tasha Cerda (Mayor) and Rodney Tanaka were up for election June 2, 2026.
-- Wikipedia as of 2026-06-08 still shows pre-election roster (no confirmed result found).
-- VERIFICATION-PENDING on Cerda and Tanaka per D-03 (inserted as is_incumbent=true with best available data).
-- External_ids: Mayor -700500; Council -700501..-700504
-- ============================================================

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Gardena', 'LOCAL', 'CA', 'Gardena', '0628168'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Gardena' AND state = 'CA'
);

-- Step 2: Chambers (City Council + Mayor)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Gardena City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Gardena' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Gardena' AND state = 'CA')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of Gardena',
       (SELECT id FROM essentials.governments WHERE name = 'City of Gardena' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Gardena' AND state = 'CA')
);

-- Step 3: Single LOCAL district for at-large council members
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0628168', 'LOCAL', 'Gardena (At-Large)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0628168' AND district_type = 'LOCAL' AND state = 'CA'
);

-- Step 4: LOCAL_EXEC district for separately elected Mayor
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0628168', 'LOCAL_EXEC', 'Gardena (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0628168' AND district_type = 'LOCAL_EXEC' AND state = 'CA'
);

-- Step 5: Mayor — Tasha Cerda (-700500)
-- VERIFICATION-PENDING: Cerda's seat was up June 2, 2026. Wikipedia still lists her as Mayor.
-- Per D-03: inserting with is_incumbent=true based on best available data (Wikipedia 2026-06-08).
-- If she lost the June 2026 election, update is_incumbent=false in a follow-up migration.
-- Source: Wikipedia — cityofgardena.org (retrieved 2026-06-08)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Tasha Cerda', 'Tasha', 'Cerda', NULL,
          true, false, false, true, -700500,
          'https://en.wikipedia.org/wiki/Gardena,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Gardena' AND state = 'CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0628168'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Mark E. Henderson (-700501, Mayor Pro Tem — NOT up for re-election in June 2026; confirmed incumbent)
-- Source: Wikipedia (CONFIRMED — term not expiring June 2026)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Mark E. Henderson', 'Mark', 'Henderson', NULL,
          true, false, false, true, -700501,
          'https://en.wikipedia.org/wiki/Gardena,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Gardena' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0628168'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Rodney G. Tanaka (-700502)
-- VERIFICATION-PENDING: Tanaka's seat was up June 2, 2026. Wikipedia still lists him.
-- Per D-03: inserting with is_incumbent=true based on best available data.
-- If he lost June 2026 election, update is_incumbent=false in follow-up migration.
-- Source: Wikipedia (VERIFICATION-PENDING for post-June-2026 status)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Rodney G. Tanaka', 'Rodney', 'Tanaka', NULL,
          true, false, false, true, -700502,
          'https://en.wikipedia.org/wiki/Gardena,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Gardena' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0628168'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Paulette C. Francis (-700503, NOT up for re-election in June 2026 — confirmed incumbent)
-- Source: Wikipedia (CONFIRMED — term not expiring June 2026)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Paulette C. Francis', 'Paulette', 'Francis', NULL,
          true, false, false, true, -700503,
          'https://en.wikipedia.org/wiki/Gardena,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Gardena' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0628168'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: Wanda Love (-700504, confirmed incumbent from prior election cycle)
-- Source: Wikipedia (listed as council member in prior cycle)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Wanda Love', 'Wanda', 'Love', NULL,
          true, false, false, true, -700504,
          'https://en.wikipedia.org/wiki/Gardena,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Gardena' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0628168'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION 2: CITY OF CULVER CITY
-- At-large council (5 members), NO separately elected Mayor (Mayor rotates by council vote)
-- FIPS geo_id: 0617568 (VERIFIED: Census place file st06_ca_place2020.txt)
-- D-04: single LOCAL district; no LOCAL_EXEC district (Mayor is rotational — same pattern as Culver City)
-- External_ids: -700550..-700554
-- ============================================================

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Culver City', 'LOCAL', 'CA', 'Culver City', '0617568'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Culver City' AND state = 'CA'
);

-- Step 2: Chamber (City Council ONLY — Mayor is rotational, not separately elected)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Culver City City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Culver City' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Culver City' AND state = 'CA')
);

-- Step 3: Single LOCAL district for at-large council (NO LOCAL_EXEC — Mayor is rotational)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0617568', 'LOCAL', 'Culver City (At-Large)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0617568' AND district_type = 'LOCAL' AND state = 'CA'
);

-- Step 4: Freddy Puza (-700550, Mayor Dec 2024 by council vote — formal office = Council Member)
-- Source: Culver City Crossroads Dec 2024, culvercity.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Freddy Puza', 'Freddy', 'Puza', NULL,
          true, false, false, true, -700550,
          'https://www.culvercity.org/government/city-council/freddy-puza')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Culver City' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0617568'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 5: Bryan Fish (-700551, Vice Mayor — formal office = Council Member; elected Nov 2024)
-- Note: Research lists name as Bryan "Bubba" Fish; using Bryan Fish per culvercity.gov listing convention.
-- Source: Culver City Crossroads Dec 2024 (VERIFIED; sworn in Dec 2024)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Bryan Fish', 'Bryan', 'Fish', NULL,
          true, false, false, true, -700551,
          'https://www.culvercity.org/government/city-council/bryan-fish')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Culver City' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0617568'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Yasmine-Imani McMorrin (-700552)
-- Source: culvercity.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Yasmine-Imani McMorrin', 'Yasmine-Imani', 'McMorrin', NULL,
          true, false, false, true, -700552,
          'https://www.culvercity.org/government/city-council/yasmine-imani-mcmorrin')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Culver City' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0617568'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Dan O'Brien (-700553)
-- Source: culvercity.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Dan O''Brien', 'Dan', 'O''Brien', NULL,
          true, false, false, true, -700553,
          'https://www.culvercity.org/government/city-council/dan-obrien')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Culver City' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0617568'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Albert Vera (-700554)
-- Source: culvercity.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Albert Vera', 'Albert', 'Vera', NULL,
          true, false, false, true, -700554,
          'https://www.culvercity.org/government/city-council/albert-vera')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Culver City' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0617568'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION 3: OFFICE_ID BACK-FILL
-- Bounded to Gardena + Culver City external_id range
-- ============================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700554 AND -700500
  AND p.office_id IS NULL;

COMMIT;
