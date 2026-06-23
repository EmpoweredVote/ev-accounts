-- 1049_springfield_mo_roster.sql
-- Deep-dive seed: Springfield, Missouri (Greene County seat, MO's 3rd-largest city) —
-- City Council + Springfield R-XII School Board (records only). Council-Manager form:
-- directly-elected Mayor + 8 council (4 General at-large seats A-D + 4 Zone seats 1-4);
-- City Manager is APPOINTED (out of scope). County constitutional officers belong to the
-- Greene County build (migration 1048), not the city.
-- Mirrors the Alexandria/Falls Church city template: Mayor in a LOCAL_EXEC citywide district,
-- council in a LOCAL district (both at place FIPS 2970000 / G4110), + a SEPARATE school
-- government for the R-XII board (SCHOOL district at school FIPS 2928860 / G5420).
-- Place 2970000 + school 2928860 geofence_boundaries imported separately from TIGERweb
-- (import-springfield-geofences.ts) — R-XII is NOT coterminous with the city, so its real
-- boundary is fetched (not copied).
--
-- ⚠ SLUG-COLLISION TRAP: chambers.slug is GENERATED from name_formal, and "Springfield City
-- Council" collides with the EXISTING Springfield, MASSACHUSETTS council (slug
-- springfield-city-council, gov 'City of Springfield, Massachusetts, US'). So every chamber
-- lookup here is scoped by the (unique) GOVERNMENT NAME + chamber name — NEVER by slug.
--
-- Roster (DB-verified 2026-06-23; springfieldmo.gov/145/City-Council + sps.org/about/board;
--   0 external_id collisions; no active name collisions; no existing Springfield MO gov):
--   Mayor Schrag; General A Hardinger / B Hosmer / C Carroll / D Lee; Zone 1 Horton /
--   2 McGull / 3 Jenson / 4 Adib-Yazdi. SPS board: Brunner (Pres), Hough (VP), Kincaid,
--   Mohammadkhani, Provance, Smart, Thomas-Tate.
-- external_id = -(government geo_id || 3-digit seq): city -2970000001..009, SPS -2928860001..007.
-- STRUCTURAL migration. Idempotent.

BEGIN;

-- ============================ Part A: governments ============================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Springfield, Missouri, US', 'LOCAL', 'MO', 'Springfield', '2970000'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name='City of Springfield, Missouri, US');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Springfield R-XII School District, Missouri, US', 'LOCAL', 'MO', NULL, '2928860'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name='Springfield R-XII School District, Missouri, US');

-- ============================ Part B: chambers (gov-scoped guards) ============================
INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)
SELECT gen_random_uuid(), g.id, 'City Council', 'Springfield City Council', 'full'
FROM essentials.governments g WHERE g.name='City of Springfield, Missouri, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch WHERE ch.government_id=g.id AND ch.name='City Council');

INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)
SELECT gen_random_uuid(), g.id, 'School Board', 'Springfield R-XII Board of Education', 'full'
FROM essentials.governments g WHERE g.name='Springfield R-XII School District, Missouri, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch WHERE ch.government_id=g.id AND ch.name='School Board');

-- ============================ Part C: districts ============================
INSERT INTO essentials.districts (id, label, district_type, geo_id, state, ocd_id)
SELECT gen_random_uuid(), 'Springfield (Citywide)', 'LOCAL_EXEC', '2970000', 'mo', 'ocd-division/country:us/state:mo/place:springfield'
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label='Springfield (Citywide)' AND geo_id='2970000');

INSERT INTO essentials.districts (id, label, district_type, geo_id, state, ocd_id)
SELECT gen_random_uuid(), 'Springfield (Council)', 'LOCAL', '2970000', 'mo', 'ocd-division/country:us/state:mo/place:springfield'
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label='Springfield (Council)' AND geo_id='2970000');

INSERT INTO essentials.districts (id, label, district_type, geo_id, mtfcc, state, ocd_id)
SELECT gen_random_uuid(), 'Springfield R-XII School District', 'SCHOOL', '2928860', 'G5420', 'mo', 'ocd-division/country:us/state:mo/sldu:springfield_r12'
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label='Springfield R-XII School District' AND geo_id='2928860');

-- ============================ Part D: politicians (16) ============================
INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name, party, source, is_active, is_appointed, is_incumbent, is_vacant)
VALUES
  (gen_random_uuid(), -2970000001, 'Jeff Schrag',        'Jeff',    'Schrag',      '', 'springfieldmo.gov', true, false, true, false),
  (gen_random_uuid(), -2970000002, 'Heather Hardinger',  'Heather', 'Hardinger',   '', 'springfieldmo.gov', true, false, true, false),
  (gen_random_uuid(), -2970000003, 'Craig Hosmer',       'Craig',   'Hosmer',      '', 'springfieldmo.gov', true, false, true, false),
  (gen_random_uuid(), -2970000004, 'Callie Carroll',     'Callie',  'Carroll',     '', 'springfieldmo.gov', true, false, true, false),
  (gen_random_uuid(), -2970000005, 'Derek Lee',          'Derek',   'Lee',         '', 'springfieldmo.gov', true, false, true, false),
  (gen_random_uuid(), -2970000006, 'Monica Horton',      'Monica',  'Horton',      '', 'springfieldmo.gov', true, false, true, false),
  (gen_random_uuid(), -2970000007, 'Abe McGull',         'Abe',     'McGull',      '', 'springfieldmo.gov', true, false, true, false),
  (gen_random_uuid(), -2970000008, 'Brandon Jenson',     'Brandon', 'Jenson',      '', 'springfieldmo.gov', true, false, true, false),
  (gen_random_uuid(), -2970000009, 'Bruce Adib-Yazdi',   'Bruce',   'Adib-Yazdi',  '', 'springfieldmo.gov', true, false, true, false),
  (gen_random_uuid(), -2928860001, 'Judy Brunner',       'Judy',    'Brunner',     '', 'sps.org',           true, false, true, false),
  (gen_random_uuid(), -2928860002, 'Sarah Hough',        'Sarah',   'Hough',       '', 'sps.org',           true, false, true, false),
  (gen_random_uuid(), -2928860003, 'Danielle Kincaid',   'Danielle','Kincaid',     '', 'sps.org',           true, false, true, false),
  (gen_random_uuid(), -2928860004, 'Maryam Mohammadkhani','Maryam', 'Mohammadkhani','', 'sps.org',          true, false, true, false),
  (gen_random_uuid(), -2928860005, 'Susan Provance',     'Susan',   'Provance',    '', 'sps.org',           true, false, true, false),
  (gen_random_uuid(), -2928860006, 'Gail Smart',         'Gail',    'Smart',       '', 'sps.org',           true, false, true, false),
  (gen_random_uuid(), -2928860007, 'Shurita Thomas-Tate','Shurita', 'Thomas-Tate', '', 'sps.org',           true, false, true, false)
ON CONFLICT (external_id) DO NOTHING;

-- ============================ Part E: offices (16) — chamber resolved by GOV NAME ============================
-- E1: Mayor (LOCAL_EXEC citywide)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT p.id,
       (SELECT ch.id FROM essentials.chambers ch JOIN essentials.governments g ON g.id=ch.government_id
         WHERE g.name='City of Springfield, Missouri, US' AND ch.name='City Council'),
       (SELECT id FROM essentials.districts WHERE label='Springfield (Citywide)' AND geo_id='2970000'),
       'Mayor', 'MO', 'Springfield', 1, false, false, false
FROM essentials.politicians p WHERE p.external_id=-2970000001
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id=p.id
    AND o.chamber_id=(SELECT ch.id FROM essentials.chambers ch JOIN essentials.governments g ON g.id=ch.government_id
                       WHERE g.name='City of Springfield, Missouri, US' AND ch.name='City Council'));

-- E2: 8 council (General A-D + Zone 1-4) on the LOCAL council district
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT p.id,
       (SELECT ch.id FROM essentials.chambers ch JOIN essentials.governments g ON g.id=ch.government_id
         WHERE g.name='City of Springfield, Missouri, US' AND ch.name='City Council'),
       (SELECT id FROM essentials.districts WHERE label='Springfield (Council)' AND geo_id='2970000'),
       CASE p.external_id
         WHEN -2970000002 THEN 'Council Member, General Seat A'
         WHEN -2970000003 THEN 'Council Member, General Seat B'
         WHEN -2970000004 THEN 'Council Member, General Seat C'
         WHEN -2970000005 THEN 'Council Member, General Seat D'
         WHEN -2970000006 THEN 'Council Member, Zone 1'
         WHEN -2970000007 THEN 'Council Member, Zone 2'
         WHEN -2970000008 THEN 'Council Member, Zone 3'
         WHEN -2970000009 THEN 'Council Member, Zone 4'
       END,
       'MO', 'Springfield', 1, false, false, false
FROM essentials.politicians p WHERE p.external_id BETWEEN -2970000009 AND -2970000002
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id=p.id
    AND o.chamber_id=(SELECT ch.id FROM essentials.chambers ch JOIN essentials.governments g ON g.id=ch.government_id
                       WHERE g.name='City of Springfield, Missouri, US' AND ch.name='City Council'));

-- E3: SPS board (7)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT p.id,
       (SELECT ch.id FROM essentials.chambers ch JOIN essentials.governments g ON g.id=ch.government_id
         WHERE g.name='Springfield R-XII School District, Missouri, US' AND ch.name='School Board'),
       (SELECT id FROM essentials.districts WHERE label='Springfield R-XII School District' AND geo_id='2928860'),
       CASE p.external_id
         WHEN -2928860001 THEN 'Board President'
         WHEN -2928860002 THEN 'Board Vice President'
         ELSE 'Board Member'
       END,
       'MO', 'Springfield', 1, false, false, false
FROM essentials.politicians p WHERE p.external_id BETWEEN -2928860007 AND -2928860001
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id=p.id
    AND o.chamber_id=(SELECT ch.id FROM essentials.chambers ch JOIN essentials.governments g ON g.id=ch.government_id
                       WHERE g.name='Springfield R-XII School District, Missouri, US' AND ch.name='School Board'));

-- ============================ Part F: back-fill office_id ============================
UPDATE essentials.politicians p SET office_id=o.id FROM essentials.offices o
 WHERE o.politician_id=p.id
   AND (p.external_id BETWEEN -2970000009 AND -2970000001 OR p.external_id BETWEEN -2928860007 AND -2928860001)
   AND p.office_id IS DISTINCT FROM o.id;

-- ============================ Part G: official_count (gov-scoped) ============================
UPDATE essentials.chambers ch SET official_count=9
  FROM essentials.governments g WHERE g.id=ch.government_id
   AND g.name='City of Springfield, Missouri, US' AND ch.name='City Council' AND ch.official_count IS DISTINCT FROM 9;
UPDATE essentials.chambers ch SET official_count=7
  FROM essentials.governments g WHERE g.id=ch.government_id
   AND g.name='Springfield R-XII School District, Missouri, US' AND ch.name='School Board' AND ch.official_count IS DISTINCT FROM 7;

-- ============================ Part H: asserts ============================
DO $$
DECLARE n int; city_chamber uuid;
BEGIN
  SELECT ch.id INTO city_chamber FROM essentials.chambers ch JOIN essentials.governments g ON g.id=ch.government_id
    WHERE g.name='City of Springfield, Missouri, US' AND ch.name='City Council';
  SELECT COUNT(*) INTO n FROM essentials.politicians WHERE external_id BETWEEN -2970000009 AND -2970000001;
  IF n <> 9 THEN RAISE EXCEPTION 'Expected 9 Springfield city politicians, found %', n; END IF;
  SELECT COUNT(*) INTO n FROM essentials.politicians WHERE external_id BETWEEN -2928860007 AND -2928860001;
  IF n <> 7 THEN RAISE EXCEPTION 'Expected 7 SPS board politicians, found %', n; END IF;
  SELECT COUNT(*) INTO n FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id
    WHERE (p.external_id BETWEEN -2970000009 AND -2970000001 OR p.external_id BETWEEN -2928860007 AND -2928860001)
      AND p.office_id=o.id;
  IF n <> 16 THEN RAISE EXCEPTION 'Expected 16 bidirectional offices, found %', n; END IF;
  SELECT COUNT(*) INTO n FROM essentials.offices WHERE chamber_id=city_chamber AND title='Mayor';
  IF n <> 1 THEN RAISE EXCEPTION 'Expected exactly 1 Mayor in the MO city chamber, found %', n; END IF;
  -- guard: all 9 city offices really landed in the MO chamber (not MA's)
  SELECT COUNT(*) INTO n FROM essentials.offices WHERE chamber_id=city_chamber;
  IF n <> 9 THEN RAISE EXCEPTION 'Expected 9 offices in the MO city chamber, found %', n; END IF;
END $$;

COMMIT;

INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1049', 'springfield_mo_roster')
ON CONFLICT (version) DO NOTHING;
