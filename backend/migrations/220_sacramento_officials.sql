-- Migration 220: Sacramento Officials Seed — 9 Sacramento politicians + offices
-- Applied 2026-05-23
--
-- Seeds 9 Sacramento officials:
--   8 City Council Members (external_ids -660010..-660017, one per council district D1-D8)
--   1 Mayor (external_id -660001, linked to geo_id=0664000 LOCAL_EXEC)
--
-- Pattern: WITH ins_p AS (INSERT ... ON CONFLICT DO NOTHING RETURNING id)
--          INSERT INTO offices ... FROM districts CROSS JOIN ins_p WHERE NOT EXISTS (...)
--
-- Sacramento government: 'City of Sacramento', state='CA', geo_id='0664000'
-- district_type='LOCAL' for sacramento-council-district-N rows
-- district_type='LOCAL_EXEC' for geo_id='0664000' (Mayor, citywide)
--
-- TITLE FORMAT: 'Council Member (District N)' — includes district number in parentheses
-- This matches Berkeley/SJ convention
--
-- CONSTRAINTS:
--   party = NULL (antipartisan design — never set a party value)
--   is_appointed_position = false for ALL 9 officials (all are elected)
--   is_appointed = false for ALL 9 politicians
--   NO City Attorney (Gustavo Martinez) — appointed; confirmed Feb 2026 appointment records
--   NO City Auditor (Farishta Ahrary) — appointed; confirmed Oct 2024 appointment records
--   NO City Treasurer (John Colville) — appointed
--   NO City Clerk (Mindy Cuppy) — appointed
--
-- Pre-flight confirmed 2026-05-23:
--   SELECT COUNT(*) FROM essentials.politicians WHERE external_id BETWEEN -660020 AND -660001
--   returned 0 rows — external_id range is clear
--   Name collision check returned 0 rows — all 9 names are unique in DB

BEGIN;

-- =============================================================================
-- SECTION 1: City Council Members (Districts 1-8)
-- =============================================================================

-- District 1: Lisa Kaplan (-660010)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa Kaplan', 'Lisa', 'Kaplan', NULL,
          true, false, false, true, -660010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Sacramento' AND state='CA')),
       p.id,
       'Council Member (District 1)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sacramento-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 2: Roger Dickinson (-660011)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roger Dickinson', 'Roger', 'Dickinson', NULL,
          true, false, false, true, -660011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Sacramento' AND state='CA')),
       p.id,
       'Council Member (District 2)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sacramento-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 3: Karina Talamantes (-660012)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Karina Talamantes', 'Karina', 'Talamantes', NULL,
          true, false, false, true, -660012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Sacramento' AND state='CA')),
       p.id,
       'Council Member (District 3)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sacramento-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 4: Phil Pluckebaum (-660013)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Phil Pluckebaum', 'Phil', 'Pluckebaum', NULL,
          true, false, false, true, -660013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Sacramento' AND state='CA')),
       p.id,
       'Council Member (District 4)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sacramento-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 5: Caity Maple (-660014)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Caity Maple', 'Caity', 'Maple', NULL,
          true, false, false, true, -660014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Sacramento' AND state='CA')),
       p.id,
       'Council Member (District 5)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sacramento-council-district-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 6: Eric Guerra (-660015)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eric Guerra', 'Eric', 'Guerra', NULL,
          true, false, false, true, -660015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Sacramento' AND state='CA')),
       p.id,
       'Council Member (District 6)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sacramento-council-district-6'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 7: Rick Jennings II (-660016)
-- NOTE: Full name includes 'II' suffix — confirmed by ArcGIS COUNCIL field
-- Use last_name='Jennings II' (not 'Jennings') to preserve the generational suffix
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rick Jennings II', 'Rick', 'Jennings II', NULL,
          true, false, false, true, -660016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Sacramento' AND state='CA')),
       p.id,
       'Council Member (District 7)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sacramento-council-district-7'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 8: Mai Vang (-660017)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mai Vang', 'Mai', 'Vang', NULL,
          true, false, false, true, -660017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Sacramento' AND state='CA')),
       p.id,
       'Council Member (District 8)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sacramento-council-district-8'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- SECTION 2: Mayor (citywide, linked to geo_id='0664000' LOCAL_EXEC)
-- =============================================================================

-- Mayor: Kevin McCarty (-660001)
-- Elected Nov 2024; took office Dec 2024; former CA Assembly Member
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin McCarty', 'Kevin', 'McCarty', NULL,
          true, false, false, true, -660001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='Mayor'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Sacramento' AND state='CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0664000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- SECTION 3: Back-fill politicians.office_id for all 9 Sacramento officials
-- =============================================================================
-- REQUIRED: plan 66-03 queries politicians JOIN offices ON o.id = p.office_id
-- to build the headshot work-list. Without this UPDATE, that query returns 0 rows.

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -660020 AND -660001
  AND p.office_id IS NULL;

COMMIT;
