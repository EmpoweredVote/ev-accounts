-- 1048_greene_county_mo_roster.sql
-- Deep-dive seed: Greene County, Missouri — full elected roster (records only).
-- Mirrors the Los Angeles County template (gov 06037, type LOCAL): a county government
-- with a County Commission chamber + separate chambers for Sheriff, Prosecuting Attorney,
-- and the administrative "County Officers". All offices sit on ONE shared COUNTY district
-- at the county FIPS geo_id 29077 so they surface BOTH ways:
--   * location feed (essentialsService): geofence 29077/G4020 -> COUNTY district (MTFCC map line 638)
--   * county browse (COVERAGE_COUNTIES, browse_government_list=['29077'], skip_overlap):
--     direct government -> chamber -> office path (boundary not required for this path).
-- The 29077 G4020 geofence_boundary is imported separately (no MO county geofences were loaded).
--
-- Roster (DB-verified 2026-06-23 from greenecountymo.gov/about/elected_officials.php;
--   0 external_id collisions; no active name collisions; no existing Greene County MO gov):
--   Commission: Dixon (Presiding), MacLachlan (1st Dist), Russell (2nd Dist).
--   Sheriff Arnott (still serving — U.S. Marshal nominee, not yet confirmed).
--   Prosecuting Attorney Patterson. Officers: Johnson/Icet/Schoeller/Feemster/Dawson-Spaulding/
--   Hill/Stein/Martin. No elected coroner (Greene uses a medical examiner) -> excluded.
-- external_id scheme = -(county geo_id 29077 || 3-digit seq) -> -29077001..-29077013.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- chambers.slug is GENERATED (from name_formal) — do NOT insert it; slug lookups still valid.

BEGIN;

-- ============================ Part A: government ============================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Greene County, Missouri, US', 'LOCAL', 'MO', NULL, '29077'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Greene County, Missouri, US');

-- ============================ Part B: chambers (4) ============================
INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)
SELECT gen_random_uuid(), g.id, 'County Commission', 'Greene County Commission', 'full'
FROM essentials.governments g WHERE g.name='Greene County, Missouri, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE slug='greene-county-commission');

INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)
SELECT gen_random_uuid(), g.id, 'Office of the Sheriff', 'Greene County Sheriff', 'full'
FROM essentials.governments g WHERE g.name='Greene County, Missouri, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE slug='greene-county-sheriff');

INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)
SELECT gen_random_uuid(), g.id, 'Office of the Prosecuting Attorney', 'Greene County Prosecuting Attorney', 'full'
FROM essentials.governments g WHERE g.name='Greene County, Missouri, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE slug='greene-county-prosecuting-attorney');

INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)
SELECT gen_random_uuid(), g.id, 'County Officers', 'Greene County Officers', 'full'
FROM essentials.governments g WHERE g.name='Greene County, Missouri, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE slug='greene-county-officers');

-- ============================ Part C: shared COUNTY district ============================
INSERT INTO essentials.districts (id, label, district_type, geo_id, mtfcc, state, ocd_id)
SELECT gen_random_uuid(), 'Greene County', 'COUNTY', '29077', 'G4020', 'mo', 'ocd-division/country:us/state:mo/county:greene'
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label='Greene County' AND geo_id='29077' AND district_type='COUNTY');

-- ============================ Part D: politicians (13) ============================
INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name, party, source, is_active, is_appointed, is_incumbent, is_vacant)
VALUES
  (gen_random_uuid(), -29077001, 'Bob Dixon',               'Bob',    'Dixon',            '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077002, 'Rusty MacLachlan',        'Rusty',  'MacLachlan',       '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077003, 'John C. Russell',         'John',   'Russell',          '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077004, 'Jim Arnott',              'Jim',    'Arnott',           '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077005, 'Dan Patterson',           'Dan',    'Patterson',        '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077006, 'Brent Johnson',           'Brent',  'Johnson',          '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077007, 'Allen Icet',              'Allen',  'Icet',             '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077008, 'Shane Schoeller',         'Shane',  'Schoeller',        '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077009, 'Bryan Feemster',          'Bryan',  'Feemster',         '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077010, 'Cheryl Dawson-Spaulding', 'Cheryl', 'Dawson-Spaulding', '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077011, 'Justin Hill',             'Justin', 'Hill',             '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077012, 'Cindy Stein',             'Cindy',  'Stein',            '', 'greenecountymo.gov', true, false, true, false),
  (gen_random_uuid(), -29077013, 'Sherri Martin',           'Sherri', 'Martin',           '', 'greenecountymo.gov', true, false, true, false)
ON CONFLICT (external_id) DO NOTHING;

-- ============================ Part E: offices (13) ============================
-- helper: shared county district id + per-chamber ids resolved via scalar subqueries.
-- E1: County Commission (3)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT p.id,
       (SELECT id FROM essentials.chambers WHERE slug='greene-county-commission'),
       (SELECT id FROM essentials.districts WHERE label='Greene County' AND geo_id='29077' AND district_type='COUNTY'),
       CASE p.external_id
         WHEN -29077001 THEN 'Presiding Commissioner'
         WHEN -29077002 THEN 'Commissioner, 1st District'
         WHEN -29077003 THEN 'Commissioner, 2nd District'
       END,
       'MO', 'Springfield', 1, false, false, false
FROM essentials.politicians p WHERE p.external_id IN (-29077001,-29077002,-29077003)
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id=p.id
    AND o.chamber_id=(SELECT id FROM essentials.chambers WHERE slug='greene-county-commission'));

-- E2: Sheriff (1)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT p.id,
       (SELECT id FROM essentials.chambers WHERE slug='greene-county-sheriff'),
       (SELECT id FROM essentials.districts WHERE label='Greene County' AND geo_id='29077' AND district_type='COUNTY'),
       'Sheriff', 'MO', 'Springfield', 1, false, false, false
FROM essentials.politicians p WHERE p.external_id=-29077004
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id=p.id
    AND o.chamber_id=(SELECT id FROM essentials.chambers WHERE slug='greene-county-sheriff'));

-- E3: Prosecuting Attorney (1)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT p.id,
       (SELECT id FROM essentials.chambers WHERE slug='greene-county-prosecuting-attorney'),
       (SELECT id FROM essentials.districts WHERE label='Greene County' AND geo_id='29077' AND district_type='COUNTY'),
       'Prosecuting Attorney', 'MO', 'Springfield', 1, false, false, false
FROM essentials.politicians p WHERE p.external_id=-29077005
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id=p.id
    AND o.chamber_id=(SELECT id FROM essentials.chambers WHERE slug='greene-county-prosecuting-attorney'));

-- E4: County Officers (8)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT p.id,
       (SELECT id FROM essentials.chambers WHERE slug='greene-county-officers'),
       (SELECT id FROM essentials.districts WHERE label='Greene County' AND geo_id='29077' AND district_type='COUNTY'),
       CASE p.external_id
         WHEN -29077006 THEN 'Assessor'
         WHEN -29077007 THEN 'Collector of Revenue'
         WHEN -29077008 THEN 'County Clerk'
         WHEN -29077009 THEN 'Circuit Clerk'
         WHEN -29077010 THEN 'Recorder of Deeds'
         WHEN -29077011 THEN 'Treasurer'
         WHEN -29077012 THEN 'Auditor'
         WHEN -29077013 THEN 'Public Administrator'
       END,
       'MO', 'Springfield', 1, false, false, false
FROM essentials.politicians p WHERE p.external_id BETWEEN -29077013 AND -29077006
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id=p.id
    AND o.chamber_id=(SELECT id FROM essentials.chambers WHERE slug='greene-county-officers'));

-- ============================ Part F: back-fill office_id ============================
UPDATE essentials.politicians p SET office_id = o.id
  FROM essentials.offices o
 WHERE o.politician_id=p.id AND p.external_id BETWEEN -29077013 AND -29077001
   AND p.office_id IS DISTINCT FROM o.id;

-- ============================ Part G: official_count ============================
UPDATE essentials.chambers SET official_count=3 WHERE slug='greene-county-commission'            AND official_count IS DISTINCT FROM 3;
UPDATE essentials.chambers SET official_count=1 WHERE slug='greene-county-sheriff'                AND official_count IS DISTINCT FROM 1;
UPDATE essentials.chambers SET official_count=1 WHERE slug='greene-county-prosecuting-attorney'   AND official_count IS DISTINCT FROM 1;
UPDATE essentials.chambers SET official_count=8 WHERE slug='greene-county-officers'               AND official_count IS DISTINCT FROM 8;

-- ============================ Part H: asserts ============================
DO $$
DECLARE n int;
BEGIN
  SELECT COUNT(*) INTO n FROM essentials.politicians WHERE external_id BETWEEN -29077013 AND -29077001;
  IF n <> 13 THEN RAISE EXCEPTION 'Expected 13 Greene County politicians, found %', n; END IF;
  SELECT COUNT(*) INTO n FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id
    WHERE p.external_id BETWEEN -29077013 AND -29077001 AND p.office_id=o.id;
  IF n <> 13 THEN RAISE EXCEPTION 'Expected 13 bidirectional offices, found %', n; END IF;
  SELECT COUNT(DISTINCT o.chamber_id) INTO n FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id
    WHERE p.external_id BETWEEN -29077013 AND -29077001;
  IF n <> 4 THEN RAISE EXCEPTION 'Expected 4 chambers, found %', n; END IF;
END $$;

COMMIT;

INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1048', 'greene_county_mo_roster')
ON CONFLICT (version) DO NOTHING;
