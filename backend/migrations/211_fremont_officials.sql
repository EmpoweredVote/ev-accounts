-- Migration 211: Fremont Officials Seed — 7 Fremont politicians + offices
-- Applied 2026-05-22
--
-- Seeds 7 Fremont officials:
--   6 City Council Members (external_ids -670010..-670015, one per council district D1-D6)
--   1 Mayor (external_id -670001, linked to geo_id=0626000 LOCAL_EXEC)
--
-- Pattern: WITH ins_p AS (INSERT ... ON CONFLICT DO NOTHING RETURNING id)
--          INSERT INTO offices ... FROM districts CROSS JOIN ins_p WHERE NOT EXISTS (...)
--
-- Fremont government: 'City of Fremont', state='CA'
-- Fremont government geo_id: '0626000'
-- district_type='LOCAL' for fremont-council-district-N rows
-- district_type='LOCAL_EXEC' for geo_id='0626000' (citywide Mayor)
--
-- CONSTRAINTS:
--   party = NULL (antipartisan design)
--   is_appointed_position = false for ALL 7 officials (all popularly elected)
--   is_appointed = false for ALL 7 including Kathy Kimberlin D3
--     (appointed to fill vacancy but holds an elected seat — method of entry NOT modeled)
--   title = 'Council Member' for 6 council members (two words)
--   title = 'Mayor' for Raj Salwan
--   NO City Attorney — Rafael E. Alvarado Jr. is APPOINTED by City Council
--   essentials.offices has NO seat_label, email, or is_active columns
--   chambers.slug is GENERATED — never include in chamber INSERTs
--   governments has NO unique constraint on geo_id — WHERE NOT EXISTS required
--
-- Fremont City Hall smoke test (from Phase 67-01):
--   (-121.9886, 37.5483) → fremont-council-district-3 → Kathy Kimberlin

BEGIN;

-- =============================================================================
-- SECTION 1: City Council Members (Districts 1-6)
-- =============================================================================

-- District 1: Teresa Keng
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Teresa Keng', 'Teresa', 'Keng', NULL, true, false, false, true, -670010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Fremont' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'fremont-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 2: Desrie Campbell
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Desrie Campbell', 'Desrie', 'Campbell', NULL, true, false, false, true, -670011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Fremont' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'fremont-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 3: Kathy Kimberlin
-- NOTE: Kimberlin was appointed to fill a vacancy but holds an elected seat.
-- Method of entry (appointment vs. election) is NOT modeled — is_appointed=false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kathy Kimberlin', 'Kathy', 'Kimberlin', NULL, true, false, false, true, -670012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Fremont' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'fremont-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 4: Yang Shao
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Yang Shao', 'Yang', 'Shao', NULL, true, false, false, true, -670013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Fremont' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'fremont-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 5: Yajing Zhang
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Yajing Zhang', 'Yajing', 'Zhang', NULL, true, false, false, true, -670014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Fremont' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'fremont-council-district-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 6: Raymond Liu
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Raymond Liu', 'Raymond', 'Liu', NULL, true, false, false, true, -670015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Fremont' AND state = 'CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'fremont-council-district-6'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- =============================================================================
-- SECTION 2: Citywide Official (Mayor, linked to geo_id='0626000' LOCAL_EXEC)
-- =============================================================================

-- Mayor: Raj Salwan
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Raj Salwan', 'Raj', 'Salwan', NULL, true, false, false, true, -670001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Mayor'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Fremont' AND state = 'CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0626000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- =============================================================================
-- SECTION 3: Back-fill politicians.office_id for all 7 Fremont officials
-- =============================================================================

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -670015 AND -670001
  AND p.office_id IS NULL;

COMMIT;
