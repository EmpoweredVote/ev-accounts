-- Migration 199 (file): SF Officials Seed — 20 San Francisco politicians + offices
-- Applied to DB as migration 206 (next after 205_sf_government_structure)
--
-- Seeds 20 SF officials:
--   11 Board of Supervisors (external_ids -630001..-630011, one per supervisor district)
--   7 citywide elected (external_ids -630020..-630026, all linked to geo_id=0667000 LOCAL_EXEC)
--   2 appointed (external_ids -630027..-630028, is_appointed_position=true)
--
-- Pattern: WITH ins_p AS (INSERT ... ON CONFLICT DO NOTHING RETURNING id)
--          INSERT INTO offices ... FROM districts CROSS JOIN ins_p WHERE NOT EXISTS (...)
--
-- SF government: 'City and County of San Francisco', state='CA'
-- SF government UUID: bc3d780d-941e-475b-b07f-bc8dbcd300d3
-- districts.label column used (not name); geo_id is the FK join column
-- district_type='LOCAL' for sf-supervisor-district-N rows
-- district_type='LOCAL_EXEC' for geo_id='0667000' (SF-wide)

BEGIN;

-- =============================================================================
-- SECTION 1: Board of Supervisors (Districts 1-11)
-- =============================================================================

-- District 1: Connie Chan
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Connie Chan', 'Connie', 'Chan', NULL, true, false, false, true, -630001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Board of Supervisors' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Supervisor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sf-supervisor-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 2: Stephen Sherrill
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stephen Sherrill', 'Stephen', 'Sherrill', NULL, true, false, false, true, -630002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Board of Supervisors' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Supervisor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sf-supervisor-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 3: Danny Sauter
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Danny Sauter', 'Danny', 'Sauter', NULL, true, false, false, true, -630003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Board of Supervisors' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Supervisor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sf-supervisor-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 4: Alan Wong
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alan Wong', 'Alan', 'Wong', NULL, true, false, false, true, -630004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Board of Supervisors' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Supervisor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sf-supervisor-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 5: Bilal Mahmood
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bilal Mahmood', 'Bilal', 'Mahmood', NULL, true, false, false, true, -630005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Board of Supervisors' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Supervisor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sf-supervisor-district-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 6: Matt Dorsey
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt Dorsey', 'Matt', 'Dorsey', NULL, true, false, false, true, -630006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Board of Supervisors' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Supervisor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sf-supervisor-district-6'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 7: Myrna Melgar
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Myrna Melgar', 'Myrna', 'Melgar', NULL, true, false, false, true, -630007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Board of Supervisors' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Supervisor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sf-supervisor-district-7'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 8: Rafael Mandelman (Board President — only 1 office: District 8 Supervisor)
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rafael Mandelman', 'Rafael', 'Mandelman', NULL, true, false, false, true, -630008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Board of Supervisors' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Supervisor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sf-supervisor-district-8'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 9: Jackie Fielder
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jackie Fielder', 'Jackie', 'Fielder', NULL, true, false, false, true, -630009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Board of Supervisors' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Supervisor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sf-supervisor-district-9'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 10: Shamann Walton
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shamann Walton', 'Shamann', 'Walton', NULL, true, false, false, true, -630010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Board of Supervisors' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Supervisor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sf-supervisor-district-10'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District 11: Chyanne Chen
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chyanne Chen', 'Chyanne', 'Chen', NULL, true, false, false, true, -630011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Board of Supervisors' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Supervisor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'sf-supervisor-district-11'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- =============================================================================
-- SECTION 2: Citywide Elected Officials (7 — linked to geo_id='0667000')
-- =============================================================================

-- Mayor: Daniel Lurie
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Daniel Lurie', 'Daniel', 'Lurie', NULL, true, false, false, true, -630020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Mayor' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0667000'
  AND d.district_type IN ('LOCAL','LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- City Attorney: David Chiu
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Chiu', 'David', 'Chiu', NULL, true, false, false, true, -630021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='City Attorney' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'City Attorney', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0667000'
  AND d.district_type IN ('LOCAL','LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- District Attorney: Brooke Jenkins
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brooke Jenkins', 'Brooke', 'Jenkins', NULL, true, false, false, true, -630022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='District Attorney' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'District Attorney', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0667000'
  AND d.district_type IN ('LOCAL','LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- Sheriff: Paul Miyamoto
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Miyamoto', 'Paul', 'Miyamoto', NULL, true, false, false, true, -630023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Sheriff' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Sheriff', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0667000'
  AND d.district_type IN ('LOCAL','LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- Assessor-Recorder: Joaquín Torres
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joaquín Torres', 'Joaquín', 'Torres', NULL, true, false, false, true, -630024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Assessor-Recorder' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Assessor-Recorder', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0667000'
  AND d.district_type IN ('LOCAL','LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- Treasurer: José Cisneros
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'José Cisneros', 'José', 'Cisneros', NULL, true, false, false, true, -630025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Treasurer' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Treasurer', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0667000'
  AND d.district_type IN ('LOCAL','LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- Public Defender: Manohar Raju
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Manohar Raju', 'Manohar', 'Raju', NULL, true, false, false, true, -630026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Public Defender' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Public Defender', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0667000'
  AND d.district_type IN ('LOCAL','LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- =============================================================================
-- SECTION 3: Appointed Officials (2 — is_appointed_position=true)
-- =============================================================================

-- Controller: Greg Wagner (appointed)
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Greg Wagner', 'Greg', 'Wagner', NULL, true, false, false, true, -630027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='Controller' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'Controller', 'CA', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0667000'
  AND d.district_type IN ('LOCAL','LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- City Administrator: Carmen Chu (appointed)
WITH ins_p AS (
  INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carmen Chu', 'Carmen', 'Chu', NULL, true, false, false, true, -630028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='City Administrator' AND government_id=(SELECT id FROM essentials.governments WHERE name='City and County of San Francisco' AND state='CA')),
       p.id,
       'City Administrator', 'CA', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0667000'
  AND d.district_type IN ('LOCAL','LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id);

-- =============================================================================
-- SECTION 4: Back-fill politicians.office_id for all 20 SF officials
-- =============================================================================

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -630028 AND -630001
  AND p.office_id IS NULL;

COMMIT;
