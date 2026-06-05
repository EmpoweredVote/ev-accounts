-- Migration 214: Berkeley Officials Seed — 10 Berkeley politicians + offices
-- Applied 2026-05-22
--
-- Seeds 10 Berkeley officials:
--   8 City Council Members (external_ids -680010..-680017, one per council district D1-D8)
--   1 Mayor (external_id -680001, linked to geo_id=0606000 LOCAL_EXEC)
--   1 City Auditor (external_id -680002, linked to geo_id=0606000 LOCAL_EXEC)
--
-- Pattern: WITH ins_p AS (INSERT ... ON CONFLICT DO NOTHING RETURNING id)
--          INSERT INTO offices ... FROM districts CROSS JOIN ins_p WHERE NOT EXISTS (...)
--
-- Berkeley government: 'City of Berkeley', state='CA', geo_id='0606000'
-- district_type='LOCAL' for berkeley-council-district-N rows
-- district_type='LOCAL_EXEC' for geo_id='0606000' (Berkeley-wide: Mayor + City Auditor share same row)
--
-- TITLE FORMAT: 'Council Member (District N)' — includes district number in parentheses
-- This is Berkeley convention (distinct from SD/Fremont which use plain 'Council Member')
--
-- CITY AUDITOR: Jenny Wong (NOT Ann-Marie Hogan — Hogan retired; Wong elected Nov 2022)
--
-- RCV NOTE: ALL 10 offices use RCV election method.
-- TODO Phase 69: set election_method='RCV' on all 3 Berkeley chambers.
--
-- CONSTRAINTS:
--   party = NULL (antipartisan design)
--   is_appointed_position = false for ALL 10 officials (all elected via RCV)
--   is_appointed = false for ALL 10 politicians
--   NO City Attorney — Berkeley City Attorney is appointed, not elected

BEGIN;

-- =============================================================================
-- SECTION 1: City Council Members (Districts 1-8)
-- =============================================================================

-- District 1: Rashi Kesarwani (-680010)
-- Term expires Nov 2026
-- TODO Phase 69: RCV election_method on City Council chamber
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rashi Kesarwani', 'Rashi', 'Kesarwani', NULL,
          true, false, false, true, -680010)
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
                             WHERE name='City of Berkeley' AND state='CA')),
       p.id,
       'Council Member (District 1)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'berkeley-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 2: Terry Taplin (-680011)
-- Term expires Nov 2028
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Terry Taplin', 'Terry', 'Taplin', NULL,
          true, false, false, true, -680011)
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
                             WHERE name='City of Berkeley' AND state='CA')),
       p.id,
       'Council Member (District 2)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'berkeley-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 3: Ben Bartlett (-680012)
-- Term expires Nov 2026
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ben Bartlett', 'Ben', 'Bartlett', NULL,
          true, false, false, true, -680012)
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
                             WHERE name='City of Berkeley' AND state='CA')),
       p.id,
       'Council Member (District 3)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'berkeley-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 4: Igor Tregub (-680013)
-- Term expires Nov 2028
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Igor Tregub', 'Igor', 'Tregub', NULL,
          true, false, false, true, -680013)
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
                             WHERE name='City of Berkeley' AND state='CA')),
       p.id,
       'Council Member (District 4)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'berkeley-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 5: Shoshana O'Keefe (-680014)
-- Term expires Nov 2026
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shoshana O''Keefe', 'Shoshana', 'O''Keefe', NULL,
          true, false, false, true, -680014)
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
                             WHERE name='City of Berkeley' AND state='CA')),
       p.id,
       'Council Member (District 5)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'berkeley-council-district-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 6: Brent Blackaby (-680015)
-- Term expires Nov 2028
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brent Blackaby', 'Brent', 'Blackaby', NULL,
          true, false, false, true, -680015)
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
                             WHERE name='City of Berkeley' AND state='CA')),
       p.id,
       'Council Member (District 6)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'berkeley-council-district-6'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 7: Cecilia Lunaparra (-680016)
-- Term expires Nov 2026
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cecilia Lunaparra', 'Cecilia', 'Lunaparra', NULL,
          true, false, false, true, -680016)
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
                             WHERE name='City of Berkeley' AND state='CA')),
       p.id,
       'Council Member (District 7)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'berkeley-council-district-7'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- District 8: Mark Humbert (-680017)
-- Term expires Nov 2028
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Humbert', 'Mark', 'Humbert', NULL,
          true, false, false, true, -680017)
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
                             WHERE name='City of Berkeley' AND state='CA')),
       p.id,
       'Council Member (District 8)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'berkeley-council-district-8'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- SECTION 2: Citywide Officials (Mayor + City Auditor, linked to geo_id='0606000')
-- =============================================================================

-- Mayor: Adena Ishii (-680001)
-- Term expires Nov 2028
-- TODO Phase 69: RCV election_method on Mayor chamber
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Adena Ishii', 'Adena', 'Ishii', NULL,
          true, false, false, true, -680001)
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
                             WHERE name='City of Berkeley' AND state='CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0606000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- City Auditor: Jenny Wong (-680002)
-- NOTE: Jenny Wong replaced Ann-Marie Hogan (retired Nov 2022). Do NOT seed Hogan.
-- Term expires Nov 2026
-- TODO Phase 69: RCV election_method on City Auditor chamber
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jenny Wong', 'Jenny', 'Wong', NULL,
          true, false, false, true, -680002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Auditor'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Berkeley' AND state='CA')),
       p.id,
       'City Auditor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0606000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- SECTION 3: Back-fill politicians.office_id for all 10 Berkeley officials
-- =============================================================================
-- REQUIRED: plan 68-03 queries politicians JOIN offices ON o.id = p.office_id
-- to build the headshot work-list. Without this UPDATE, that query returns 0 rows.

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -680017 AND -680001
  AND p.office_id IS NULL;

COMMIT;
