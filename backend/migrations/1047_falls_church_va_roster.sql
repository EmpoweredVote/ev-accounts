-- 1047_falls_church_va_roster.sql
-- Deep-dive seed: City of Falls Church, VA — full elected roster (records only).
-- Mirrors the Alexandria, VA template (City of Alexandria gov 06a88dcd + Alexandria City
-- Public Schools gov 715458de): independent VA city => City Council (LOCAL at-large + a
-- LOCAL_EXEC citywide Mayor seat) + a SEPARATE School Board government, plus the city's
-- 3 elected constitutional officers (Sheriff / Treasurer / Commissioner of the Revenue).
--
-- Falls Church (FIPS): county-equivalent geo_id 51610 (G4020, existing COUNTY district +
-- geofence), place geo_id 5127200 (G4110, geofence has geometry), school division NCES/Census
-- geo_id 5101290. The school division is COTERMINOUS with the city, so the new SCHOOL
-- geofence_boundary copies the place (5127200) polygon — exactly how Alexandria's 5100090
-- G5420 boundary was created.
--
-- Feed surfacing (essentialsService.ts ST_Covers + MTFCC->district_type map):
--   City Council        -> LOCAL/LOCAL_EXEC district @ geo_id 5127200 matches gb G4110  (line 640)
--   Constitutional Offs -> COUNTY district @ geo_id 51610 matches gb G4020               (line 638)
--   School Board        -> SCHOOL district @ geo_id 5101290 matches NEW gb G5420         (line 641)
-- A resident point is covered by ALL THREE polygons -> all 17 surface.
--
-- Roster (DB-verified 2026-06-22; 0 external_id collisions; no name collisions with real rows):
--   Council (Jan 5 2026 reorg, fallschurchpulse.org): Hardi=Mayor, Downs=Vice Mayor.
--   School Board (2026 term, fccps.org): Tysse=Chair, Sherwood=Vice Chair.
--   Const. officers (fallschurchpulse.org 2025): Cay=Sheriff, Acosta=Treasurer, Clinton=Comm. of Revenue.
-- OUT OF SCOPE: Commonwealth's Attorney + Clerk of Circuit Court (shared with Arlington Co. — 17th
--   Judicial Circuit — elected on a combined district, NOT Falls Church-only).
-- external_id scheme = -(government geo_id || 3-digit seq), Alexandria convention.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.

BEGIN;

-- ============================ Part A: governments ============================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Falls Church, Virginia, US', 'LOCAL', 'VA', 'Falls Church', '5127200'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'City of Falls Church, Virginia, US');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Falls Church City Public Schools, Virginia, US', 'LOCAL', 'VA', NULL, '5101290'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Falls Church City Public Schools, Virginia, US');

-- ============================ Part B: chambers ============================
-- City Council
-- NOTE: chambers.slug is a GENERATED column (from name_formal): lower/unaccent/strip => the
-- exact slugs below. Insert name_formal only; slug-based lookups remain valid.
INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)
SELECT gen_random_uuid(), g.id, 'City Council', 'Falls Church City Council', 'full'
FROM essentials.governments g
WHERE g.name = 'City of Falls Church, Virginia, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE slug = 'falls-church-city-council');

-- Constitutional Officers (same City government)
INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)
SELECT gen_random_uuid(), g.id, 'Constitutional Officers', 'Falls Church Constitutional Officers', 'full'
FROM essentials.governments g
WHERE g.name = 'City of Falls Church, Virginia, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE slug = 'falls-church-constitutional-officers');

-- School Board (separate government)
INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)
SELECT gen_random_uuid(), g.id, 'School Board', 'Falls Church City Public Schools Board', 'full'
FROM essentials.governments g
WHERE g.name = 'Falls Church City Public Schools, Virginia, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE slug = 'falls-church-city-public-schools-board');

-- ============================ Part C: districts ============================
-- LOCAL at-large (council members), geo_id 5127200
INSERT INTO essentials.districts (id, label, district_type, geo_id, state, ocd_id)
SELECT gen_random_uuid(), 'Falls Church (At-Large)', 'LOCAL', '5127200', 'va', 'ocd-division/country:us/state:va/place:falls_church'
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label = 'Falls Church (At-Large)' AND geo_id = '5127200');

-- LOCAL_EXEC citywide (Mayor), geo_id 5127200
INSERT INTO essentials.districts (id, label, district_type, geo_id, state, ocd_id)
SELECT gen_random_uuid(), 'Falls Church (Citywide)', 'LOCAL_EXEC', '5127200', 'va', 'ocd-division/country:us/state:va/place:falls_church'
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label = 'Falls Church (Citywide)' AND geo_id = '5127200');

-- SCHOOL district, geo_id 5101290
INSERT INTO essentials.districts (id, label, district_type, geo_id, mtfcc, state, ocd_id)
SELECT gen_random_uuid(), 'Falls Church City Public Schools', 'SCHOOL', '5101290', 'G5420', 'va', 'ocd-division/country:us/state:va/sldu:falls_church_schools'
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label = 'Falls Church City Public Schools' AND geo_id = '5101290');

-- Constitutional officers reuse the EXISTING COUNTY district (geo_id 51610, id 0e2f4e11...). No new district.

-- ============================ Part D: school geofence_boundary (coterminous w/ city place) ============================
INSERT INTO essentials.geofence_boundaries (id, geo_id, mtfcc, state, name, geometry, source)
SELECT gen_random_uuid(), '5101290', 'G5420', '51', 'Falls Church City Public Schools', gb.geometry,
       'derived: coterminous with place 5127200 (FCCPS = City of Falls Church)'
FROM essentials.geofence_boundaries gb
WHERE gb.geo_id = '5127200' AND gb.mtfcc = 'G4110'
  AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '5101290');

-- ============================ Part E: politicians (17) ============================
INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name, party, source, is_active, is_appointed, is_incumbent, is_vacant)
VALUES
  -- City Council
  (gen_random_uuid(), -5127200001, 'Letty Hardi',        'Letty',     'Hardi',     '', 'fallschurchva.gov',   true, false, true, false),
  (gen_random_uuid(), -5127200002, 'Laura Downs',        'Laura',     'Downs',     '', 'fallschurchva.gov',   true, false, true, false),
  (gen_random_uuid(), -5127200003, 'Justine Underhill',  'Justine',   'Underhill', '', 'fallschurchva.gov',   true, false, true, false),
  (gen_random_uuid(), -5127200004, 'Marybeth Connelly',  'Marybeth',  'Connelly',  '', 'fallschurchva.gov',   true, false, true, false),
  (gen_random_uuid(), -5127200005, 'David Snyder',       'David',     'Snyder',    '', 'fallschurchva.gov',   true, false, true, false),
  (gen_random_uuid(), -5127200006, 'Erin Flynn',         'Erin',      'Flynn',     '', 'fallschurchva.gov',   true, false, true, false),
  (gen_random_uuid(), -5127200007, 'Arthur Agin',        'Arthur',    'Agin',      '', 'fallschurchva.gov',   true, false, true, false),
  -- Constitutional officers
  (gen_random_uuid(), -5127200008, 'Metin A. Cay',       'Metin',     'Cay',       '', 'fallschurchva.gov',   true, false, true, false),
  (gen_random_uuid(), -5127200009, 'Jody Acosta',        'Jody',      'Acosta',    '', 'fallschurchva.gov',   true, false, true, false),
  (gen_random_uuid(), -5127200010, 'Thomas D. Clinton',  'Thomas',    'Clinton',   '', 'fallschurchva.gov',   true, false, true, false),
  -- School Board
  (gen_random_uuid(), -5101290001, 'Kathleen Tysse',     'Kathleen',  'Tysse',     '', 'fccps.org',           true, false, true, false),
  (gen_random_uuid(), -5101290002, 'Anne Sherwood',      'Anne',      'Sherwood',  '', 'fccps.org',           true, false, true, false),
  (gen_random_uuid(), -5101290003, 'Jerrod Anderson',    'Jerrod',    'Anderson',  '', 'fccps.org',           true, false, true, false),
  (gen_random_uuid(), -5101290004, 'Bethany Henderson',  'Bethany',   'Henderson', '', 'fccps.org',           true, false, true, false),
  (gen_random_uuid(), -5101290005, 'MaryKate Hughes',    'MaryKate',  'Hughes',    '', 'fccps.org',           true, false, true, false),
  (gen_random_uuid(), -5101290006, 'Amie Murphy',        'Amie',      'Murphy',    '', 'fccps.org',           true, false, true, false),
  (gen_random_uuid(), -5101290007, 'Lori Silverman',     'Lori',      'Silverman', '', 'fccps.org',           true, false, true, false)
ON CONFLICT (external_id) DO NOTHING;

-- ============================ Part F: offices (17) ============================
-- helper CTE-free: scalar subqueries for chamber_id / district_id.
-- F1: Mayor (LOCAL_EXEC citywide)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT p.id,
       (SELECT id FROM essentials.chambers WHERE slug = 'falls-church-city-council'),
       (SELECT id FROM essentials.districts WHERE label = 'Falls Church (Citywide)' AND geo_id = '5127200'),
       'Mayor', 'VA', 'Falls Church', 1, false, false, false
FROM essentials.politicians p WHERE p.external_id = -5127200001
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id
    AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE slug = 'falls-church-city-council'));

-- F2: at-large council (Vice Mayor + 5 members)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT p.id,
       (SELECT id FROM essentials.chambers WHERE slug = 'falls-church-city-council'),
       (SELECT id FROM essentials.districts WHERE label = 'Falls Church (At-Large)' AND geo_id = '5127200'),
       CASE WHEN p.external_id = -5127200002 THEN 'Vice Mayor' ELSE 'Council Member' END,
       'VA', 'Falls Church', 1, false, false, false
FROM essentials.politicians p
WHERE p.external_id IN (-5127200002,-5127200003,-5127200004,-5127200005,-5127200006,-5127200007)
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id
    AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE slug = 'falls-church-city-council'));

-- F3: constitutional officers (COUNTY district 51610)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT p.id,
       (SELECT id FROM essentials.chambers WHERE slug = 'falls-church-constitutional-officers'),
       (SELECT id FROM essentials.districts WHERE geo_id = '51610' AND district_type = 'COUNTY'),
       CASE p.external_id
         WHEN -5127200008 THEN 'Sheriff'
         WHEN -5127200009 THEN 'Treasurer'
         WHEN -5127200010 THEN 'Commissioner of the Revenue'
       END,
       'VA', 'Falls Church', 1, false, false, false
FROM essentials.politicians p
WHERE p.external_id IN (-5127200008,-5127200009,-5127200010)
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id
    AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE slug = 'falls-church-constitutional-officers'));

-- F4: school board (Chair, Vice Chair, 5 members)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT p.id,
       (SELECT id FROM essentials.chambers WHERE slug = 'falls-church-city-public-schools-board'),
       (SELECT id FROM essentials.districts WHERE label = 'Falls Church City Public Schools' AND geo_id = '5101290'),
       CASE p.external_id
         WHEN -5101290001 THEN 'School Board Chair'
         WHEN -5101290002 THEN 'School Board Vice Chair'
         ELSE 'School Board Member'
       END,
       'VA', 'Falls Church', 1, false, false, false
FROM essentials.politicians p
WHERE p.external_id BETWEEN -5101290007 AND -5101290001
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id
    AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE slug = 'falls-church-city-public-schools-board'));

-- ============================ Part G: back-fill politicians.office_id ============================
UPDATE essentials.politicians p
   SET office_id = o.id
  FROM essentials.offices o
 WHERE o.politician_id = p.id
   AND p.external_id IN (-5127200001,-5127200002,-5127200003,-5127200004,-5127200005,-5127200006,-5127200007,
                         -5127200008,-5127200009,-5127200010,
                         -5101290001,-5101290002,-5101290003,-5101290004,-5101290005,-5101290006,-5101290007)
   AND p.office_id IS DISTINCT FROM o.id;

-- ============================ Part H: official_count ============================
UPDATE essentials.chambers SET official_count = 7 WHERE slug = 'falls-church-city-council'                  AND official_count IS DISTINCT FROM 7;
UPDATE essentials.chambers SET official_count = 3 WHERE slug = 'falls-church-constitutional-officers'        AND official_count IS DISTINCT FROM 3;
UPDATE essentials.chambers SET official_count = 7 WHERE slug = 'falls-church-city-public-schools-board'      AND official_count IS DISTINCT FROM 7;

-- ============================ Part I: asserts ============================
DO $$
DECLARE n int;
BEGIN
  SELECT COUNT(*) INTO n FROM essentials.politicians WHERE external_id BETWEEN -5127200010 AND -5127200001;
  IF n <> 10 THEN RAISE EXCEPTION 'Expected 10 City of Falls Church politicians, found %', n; END IF;
  SELECT COUNT(*) INTO n FROM essentials.politicians WHERE external_id BETWEEN -5101290007 AND -5101290001;
  IF n <> 7 THEN RAISE EXCEPTION 'Expected 7 FCCPS politicians, found %', n; END IF;
  SELECT COUNT(*) INTO n FROM essentials.offices o
    JOIN essentials.politicians p ON p.id = o.politician_id
    WHERE (p.external_id BETWEEN -5127200010 AND -5127200001 OR p.external_id BETWEEN -5101290007 AND -5101290001)
      AND p.office_id = o.id;
  IF n <> 17 THEN RAISE EXCEPTION 'Expected 17 bidirectional offices, found %', n; END IF;
  SELECT COUNT(*) INTO n FROM essentials.offices o
    WHERE o.chamber_id = (SELECT id FROM essentials.chambers WHERE slug='falls-church-city-council') AND o.title='Mayor';
  IF n <> 1 THEN RAISE EXCEPTION 'Expected exactly 1 Mayor, found %', n; END IF;
  SELECT COUNT(*) INTO n FROM essentials.geofence_boundaries WHERE geo_id='5101290' AND mtfcc='G5420';
  IF n <> 1 THEN RAISE EXCEPTION 'Expected 1 school geofence_boundary, found %', n; END IF;
END $$;

COMMIT;

INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1047', 'falls_church_va_roster')
ON CONFLICT (version) DO NOTHING;
