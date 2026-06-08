BEGIN;

-- Migration 305: Wave 3 — South Gate (at-large) + Compton (by-district + Mayor)
-- Depends on: 304_la_wave3_preflight_west_hollywood_fips.sql
-- External_id range: South Gate -700200..-700204; Compton -700250..-700254 (+ -700255..-700257 reserved, VERIFICATION-PENDING)
-- Applied: 2026-06-08

-- ============================================================
-- SECTION 1: CITY OF SOUTH GATE
-- At-large council, 5 members, rotating Mayor (no separately elected Mayor per RESEARCH.md Assumption A2)
-- FIPS geo_id: 0673080 (VERIFIED: census.gov QuickFacts)
-- External_ids: -700200..-700204
-- ============================================================

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of South Gate', 'LOCAL', 'CA', 'South Gate', '0673080'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA'
);

-- Step 2: Chamber (slug is GENERATED ALWAYS AS — never include in INSERT column list)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'South Gate City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA')
);

-- Step 3: Single LOCAL district (at-large; geo_id = FIPS code)
-- NOTE: South Gate has no separately elected Mayor (rotates) — NO LOCAL_EXEC district
-- CRITICAL: NO ON CONFLICT — constraint (geo_id, district_type) does not exist
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0673080', 'LOCAL', 'South Gate (At-Large)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0673080' AND district_type = 'LOCAL' AND state = 'CA'
);

-- Step 4: Politicians + offices (5 at-large council members)
-- Source: cityofsouthgate.org/elected-officials (VERIFIED)

WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Maria Davila', 'Maria', 'Davila', NULL,
          true, false, false, true, -700200,
          'https://www.cityofsouthgate.org/gov/elected_officials/mayor_and_council/maria_davila.asp')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0673080'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Joshua Barron', 'Joshua', 'Barron', NULL,
          true, false, false, true, -700201,
          'https://www.cityofsouthgate.org/gov/elected_officials/mayor_and_council/joshua_barron.asp')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0673080'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Maria del Pilar Avalos', 'Maria del Pilar', 'Avalos', NULL,
          true, false, false, true, -700202,
          'https://www.cityofsouthgate.org/gov/elected_officials/mayor_and_council/maria_avalos.asp')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0673080'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Gil Hurtado', 'Gil', 'Hurtado', NULL,
          true, false, false, true, -700203,
          'https://www.cityofsouthgate.org/gov/elected_officials/mayor_and_council/gil_hurtado.asp')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0673080'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Al Rios', 'Al', 'Rios', NULL,
          true, false, false, true, -700204,
          'https://www.cityofsouthgate.org/gov/elected_officials/mayor_and_council/al_rios.asp')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0673080'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION 2: CITY OF COMPTON
-- By-district council (4 districts) + separately elected Mayor
-- FIPS geo_id: 0615044 (VERIFIED: Census place file st06_ca_place2020.txt)
-- External_ids: Mayor -700250; Districts -700251..-700254
-- ============================================================

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Compton', 'LOCAL', 'CA', 'Compton', '0615044'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA'
);

-- Step 2: Chambers
-- City Council chamber (for 4 district members)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Compton City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')
);

-- Mayor chamber (separately elected citywide)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of Compton',
       (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')
);

-- Step 3: 4 LOCAL district rows (one per council district)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('compton-council-district-1', 'LOCAL', 'District 1', 'CA'),
  ('compton-council-district-2', 'LOCAL', 'District 2', 'CA'),
  ('compton-council-district-3', 'LOCAL', 'District 3', 'CA'),
  ('compton-council-district-4', 'LOCAL', 'District 4', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);

-- Step 4: LOCAL_EXEC district for Mayor (citywide; geo_id = city FIPS)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0615044', 'LOCAL_EXEC', 'Compton (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0615044' AND district_type = 'LOCAL_EXEC' AND state = 'CA'
);

-- Step 5: Mayor — Emma Sharif (external_id -700250, LOCAL_EXEC district)
-- Source: Wikipedia, comptoncity.org (VERIFIED)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Emma Sharif', 'Emma', 'Sharif', NULL,
          true, false, false, true, -700250,
          'https://en.wikipedia.org/wiki/Emma_Sharif')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0615044'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: District 1 — Deidre Duhart (external_id -700251)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Deidre Duhart', 'Deidre', 'Duhart', NULL,
          true, false, false, true, -700251,
          'https://en.wikipedia.org/wiki/Compton,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')),
       p.id,
       'Council Member (District 1)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'compton-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: District 2 — Andre Spicer (external_id -700252)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Andre Spicer', 'Andre', 'Spicer', NULL,
          true, false, false, true, -700252,
          'https://en.wikipedia.org/wiki/Compton,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')),
       p.id,
       'Council Member (District 2)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'compton-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: District 3 — Jonathan Bowers (external_id -700253)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Jonathan Bowers', 'Jonathan', 'Bowers', NULL,
          true, false, false, true, -700253,
          'https://en.wikipedia.org/wiki/Compton,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')),
       p.id,
       'Council Member (District 3)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'compton-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: District 4 — Lillie P. Darden (external_id -700254)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Lillie P. Darden', 'Lillie', 'Darden', NULL,
          true, false, false, true, -700254,
          'https://en.wikipedia.org/wiki/Compton,_California')
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
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')),
       p.id,
       'Council Member (District 4)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'compton-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION 2b: COMPTON ELECTED CITYWIDE OFFICERS (CONDITIONAL)
-- Per D-03 conservative default: names not confirmed from official source.
-- Compton City Clerk, Treasurer, and Attorney are ELECTED per charter (Art V) — VERIFIED.
-- Current officer names were NOT verified (comptoncity.org access denied; Wikipedia stale).
-- ============================================================

-- VERIFICATION-PENDING: Compton City Clerk elected per charter but incumbent name not confirmed; deferred per D-03.
--   Slot reserved: external_id -700255
--   When verified, create 'City Clerk' chamber + insert politician + link to LOCAL_EXEC district (geo_id=0615044)

-- VERIFICATION-PENDING: Compton City Treasurer elected per charter but incumbent name not confirmed; deferred per D-03.
--   Wikipedia lists "Brandon Mims" but this is unconfirmed from official source.
--   Slot reserved: external_id -700256
--   When verified, create 'City Treasurer' chamber + insert politician + link to LOCAL_EXEC district

-- Compton City Attorney: VACANT per Wikipedia (retrieved 2026-06-08). Do NOT insert a politician.
--   Slot reserved: external_id -700257 (if/when a City Attorney is elected and confirmed)

-- ============================================================
-- SECTION 3: OFFICE_ID BACK-FILL
-- Bounded to Wave 3 South Gate + Compton range only
-- ============================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700254 AND -700200
  AND p.office_id IS NULL;

COMMIT;
