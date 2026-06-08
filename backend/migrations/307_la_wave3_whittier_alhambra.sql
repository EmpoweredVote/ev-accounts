BEGIN;

-- Migration 307: Wave 3 — Whittier (by-district + Mayor) + Alhambra (5 districts, NO Mayor — Pitfall 7)
-- Depends on: 304_la_wave3_preflight_west_hollywood_fips.sql
-- External_id range: Whittier -700400..-700404; Alhambra -700450..-700454
-- Applied: 2026-06-08

-- ============================================================
-- SECTION 1: CITY OF WHITTIER
-- By-district council (4 districts) + separately elected Mayor
-- FIPS geo_id: 0685292 (VERIFIED: census.gov QuickFacts URL 0685292)
-- External_ids: Mayor -700400; D1-D4 -700401..-700404
-- ============================================================

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Whittier', 'LOCAL', 'CA', 'Whittier', '0685292'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Whittier' AND state = 'CA'
);

-- Step 2: Chambers
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Whittier City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Whittier' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Whittier' AND state = 'CA')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of Whittier',
       (SELECT id FROM essentials.governments WHERE name = 'City of Whittier' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Whittier' AND state = 'CA')
);

-- Step 3: 4 LOCAL district rows
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('whittier-council-district-1', 'LOCAL', 'District 1', 'CA'),
  ('whittier-council-district-2', 'LOCAL', 'District 2', 'CA'),
  ('whittier-council-district-3', 'LOCAL', 'District 3', 'CA'),
  ('whittier-council-district-4', 'LOCAL', 'District 4', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);

-- Step 4: LOCAL_EXEC district for Mayor (citywide)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0685292', 'LOCAL_EXEC', 'Whittier (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0685292' AND district_type = 'LOCAL_EXEC' AND state = 'CA'
);

-- Step 5: Mayor — James Becerra (-700400)
-- Source: cityofwhittier.org (VERIFIED; sworn in April 2026 after April 14, 2026 election)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'James Becerra', 'James', 'Becerra', NULL,
          true, false, false, true, -700400,
          'https://www.cityofwhittier.org/government/city-council/james-becerra')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Whittier' AND state = 'CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0685292'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: District 1 — Fernando Dutra (-700401, Assumption A4 — not up until 2028)
-- Source: cityofwhittier.org (VERIFIED for D1: Fernando Dutra, term through 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Fernando Dutra', 'Fernando', 'Dutra', NULL,
          true, false, false, true, -700401,
          'https://www.cityofwhittier.org/government/city-council/fernando-dutra')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Whittier' AND state = 'CA')),
       p.id,
       'Council Member (District 1)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'whittier-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: District 2 — Vicky Santana (-700402)
-- Source: cityofwhittier.org (VERIFIED; elected April 2026)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Vicky Santana', 'Vicky', 'Santana', NULL,
          true, false, false, true, -700402,
          'https://www.cityofwhittier.org/government/city-council/vicky-santana')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Whittier' AND state = 'CA')),
       p.id,
       'Council Member (District 2)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'whittier-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: District 3 — Octavio Cesar Martinez (-700403, Assumption A4 — not up until 2028)
-- Source: RESEARCH.md (Assumption A4 — listed as not up until 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Octavio Cesar Martinez', 'Octavio', 'Martinez', NULL,
          true, false, false, true, -700403,
          'https://en.wikipedia.org/wiki/Whittier,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Whittier' AND state = 'CA')),
       p.id,
       'Council Member (District 3)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'whittier-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: District 4 — Aida Susana Macedo (-700404)
-- Source: cityofwhittier.org (VERIFIED; elected April 2026)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Aida Susana Macedo', 'Aida', 'Macedo', NULL,
          true, false, false, true, -700404,
          'https://www.cityofwhittier.org/government/city-council/aida-macedo')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Whittier' AND state = 'CA')),
       p.id,
       'Council Member (District 4)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'whittier-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION 2: CITY OF ALHAMBRA
-- 5 by-district seats, NO separately elected Mayor (Pitfall 7)
-- FIPS geo_id: 0600884 (VERIFIED: Census place file st06_ca_place2020.txt)
-- NOTE: Alhambra Mayor is a ROTATIONAL title (9-month rotation among council members).
-- DO NOT create a Mayor chamber or LOCAL_EXEC district — Pitfall 7 strictly enforced.
-- External_ids: D1-D5: -700450..-700454
-- ============================================================

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Alhambra', 'LOCAL', 'CA', 'Alhambra', '0600884'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Alhambra' AND state = 'CA'
);

-- Step 2: Chamber — City Council ONLY (NO Mayor chamber per Pitfall 7)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Alhambra City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Alhambra' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Alhambra' AND state = 'CA')
);
-- NOTE: Alhambra Mayor is rotational (Pitfall 7); no Mayor chamber or LOCAL_EXEC district created.

-- Step 3: 5 LOCAL district rows (one per council district)
-- NO LOCAL_EXEC district — Pitfall 7 strictly enforced
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('alhambra-council-district-1', 'LOCAL', 'District 1', 'CA'),
  ('alhambra-council-district-2', 'LOCAL', 'District 2', 'CA'),
  ('alhambra-council-district-3', 'LOCAL', 'District 3', 'CA'),
  ('alhambra-council-district-4', 'LOCAL', 'District 4', 'CA'),
  ('alhambra-council-district-5', 'LOCAL', 'District 5', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);

-- Step 4: District 1 — Katherine Lee (-700450)
-- Source: alhambraca.gov city council page (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Katherine Lee', 'Katherine', 'Lee', NULL,
          true, false, false, true, -700450,
          'https://www.alhambraca.gov/297/City-Council')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Alhambra' AND state = 'CA')),
       p.id,
       'Council Member (District 1)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'alhambra-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 5: District 2 — Ross J. Maza (-700451)
-- Source: alhambraca.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Ross J. Maza', 'Ross', 'Maza', NULL,
          true, false, false, true, -700451,
          'https://www.alhambraca.gov/297/City-Council')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Alhambra' AND state = 'CA')),
       p.id,
       'Council Member (District 2)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'alhambra-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: District 3 — Jeff Maloney (-700452)
-- Source: alhambraca.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Jeff Maloney', 'Jeff', 'Maloney', NULL,
          true, false, false, true, -700452,
          'https://www.alhambraca.gov/297/City-Council')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Alhambra' AND state = 'CA')),
       p.id,
       'Council Member (District 3)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'alhambra-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: District 4 — Noya Wang (-700453)
-- Source: alhambraca.gov (VERIFIED; current rotational Mayor 2025-2026, but formal office = Council Member D4)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Noya Wang', 'Noya', 'Wang', NULL,
          true, false, false, true, -700453,
          'https://www.alhambraca.gov/297/City-Council')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Alhambra' AND state = 'CA')),
       p.id,
       'Council Member (District 4)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'alhambra-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: District 5 — Adele Andrade-Stadler (-700454)
-- Source: alhambraca.gov (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Adele Andrade-Stadler', 'Adele', 'Andrade-Stadler', NULL,
          true, false, false, true, -700454,
          'https://www.alhambraca.gov/297/City-Council')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Alhambra' AND state = 'CA')),
       p.id,
       'Council Member (District 5)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'alhambra-council-district-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION 3: OFFICE_ID BACK-FILL
-- Bounded to Whittier + Alhambra external_id range
-- ============================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700454 AND -700400
  AND p.office_id IS NULL;

COMMIT;
