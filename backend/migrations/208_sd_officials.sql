-- Migration 208: SD Officials Seed — 11 San Diego politicians + offices
-- Applied 2026-05-22
--
-- Seeds 11 SD officials:
--   9 City Council Members (external_ids -650010..-650018, one per council district)
--   1 Mayor (external_id -650001, linked to geo_id=0666000 LOCAL_EXEC)
--   1 City Attorney (external_id -650002, linked to geo_id=0666000 LOCAL_EXEC)
--
-- Pattern: WITH ins_p AS (INSERT ... ON CONFLICT DO NOTHING RETURNING id)
--          INSERT INTO offices ... FROM districts CROSS JOIN ins_p WHERE NOT EXISTS (...)
--
-- SD government: 'City of San Diego', state='CA'
-- SD government UUID: 7efdfa12-88b2-482d-9379-84a7341bebc5
-- district_type='LOCAL' for sd-council-district-N rows
-- district_type='LOCAL_EXEC' for geo_id='0666000' (SD-wide Mayor + City Attorney)
--
-- CONSTRAINTS:
--   party = NULL (antipartisan design)
--   is_appointed_position = false for ALL 11 officials
--   title = 'Council Member' (two words, not Supervisor)
--   Henry L. Foster III: full_name includes middle initial (ignores ArcGIS 'Henry Foster III')
--   Joe LaCava: EXACTLY 1 office (Council President is governance role, not a separate office)
--   Jennifer Campbell (D2) + Vivian Moreno (D8): seeded as incumbents (term-limited Jun 2026
--     but remain in office through certification)

BEGIN;

-- =============================================================================
-- SECTION 1: City Council Members (Districts 1-9)
-- =============================================================================

-- District 1: Joe LaCava (Council President — only 1 office row)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joe LaCava', 'Joe', 'LaCava', NULL, true, false, false, true, -650010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sd-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 2: Jennifer Campbell (term-limited Jun 2026; remains incumbent through certification)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jennifer Campbell', 'Jennifer', 'Campbell', NULL, true, false, false, true, -650011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sd-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 3: Stephen Whitburn
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stephen Whitburn', 'Stephen', 'Whitburn', NULL, true, false, false, true, -650012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sd-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 4: Henry L. Foster III (middle initial required; ArcGIS omits it — ignore that)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Henry L. Foster III', 'Henry', 'Foster III', NULL, true, false, false, true, -650013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sd-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 5: Marni von Wilpert
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marni von Wilpert', 'Marni', 'von Wilpert', NULL, true, false, false, true, -650014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sd-council-district-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 6: Kent Lee
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kent Lee', 'Kent', 'Lee', NULL, true, false, false, true, -650015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sd-council-district-6'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 7: Raul Campillo
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Raul Campillo', 'Raul', 'Campillo', NULL, true, false, false, true, -650016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sd-council-district-7'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 8: Vivian Moreno (term-limited Jun 2026; remains incumbent through certification)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vivian Moreno', 'Vivian', 'Moreno', NULL, true, false, false, true, -650017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sd-council-district-8'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 9: Sean Elo-Rivera
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sean Elo-Rivera', 'Sean', 'Elo-Rivera', NULL, true, false, false, true, -650018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')),
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sd-council-district-9'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- =============================================================================
-- SECTION 2: Citywide Officials (Mayor + City Attorney, linked to geo_id='0666000')
-- =============================================================================

-- Mayor: Todd Gloria
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Todd Gloria', 'Todd', 'Gloria', NULL, true, false, false, true, -650001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='Mayor'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0666000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- City Attorney: Heather Ferbert
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Heather Ferbert', 'Heather', 'Ferbert', NULL, true, false, false, true, -650002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Attorney'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of San Diego' AND state='CA')),
       p.id,
       'City Attorney', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0666000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- =============================================================================
-- SECTION 3: Back-fill politicians.office_id for all 11 SD officials
-- =============================================================================

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -650018 AND -650001
  AND p.office_id IS NULL;

COMMIT;
