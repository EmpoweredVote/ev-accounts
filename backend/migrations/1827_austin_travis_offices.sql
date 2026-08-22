-- 1827_austin_travis_offices.sql
--
-- Austin TX / Travis County deep seed, wave 1, PART A — SEATS ONLY. No occupants.
-- Part B (1828_austin_travis_seating.sql) inserts the people and their office_terms.
--
-- WHY TWO MIGRATIONS
-- `essentials.offices` is a SEAT and holds no occupant (ADR 0002). Splitting the seat
-- creation from the seating keeps each post-verify gate able to assert one thing exactly:
-- this one asserts 23 seats exist and are correctly shaped; Part B asserts all 23 resolve
-- to a non-NULL holder. 🔴 An office with no office_terms row is INVISIBLE and NOTHING
-- ERRORS — so Part A landing without Part B is the one failure mode CI cannot catch.
-- Do not ship A without B.
--
-- WHAT ALREADY EXISTED (verified 2026-08-18, nothing here re-creates it)
--   * essentials.districts 'Travis County' — geo_id 48453, correct ocd_id, 0 offices.
--     This migration ADOPTS that row and only backfills its government_id.
--   * essentials.geofence_boundaries for BOTH 'Austin city' (4805000, G4110) and
--     'Travis County' (48453, G4020). No boundary loading is needed; address reachability
--     for these 23 seats works the moment Part B seats them.
--   * All federal and Texas state layers covering Austin (TX-10/17/21/35/37, 150 TX House,
--     31 TX Senate), in both the 2020 and V26 vintages.
--
-- 🔴 THE `austin` NAME COLLISION IS LIVE IN THIS DATABASE, TWICE OVER.
--    1. `Austin County` (geo_id 48015) is a real, different Texas county we already hold.
--    2. geo_id '48015' is ALSO carried by 'TX Senate District 15' and 'TX House District 15',
--       because state-leg geo_ids are synthesised as <state FIPS><district number> and so
--       collide with county FIPS. Three districts, one geo_id.
--    Consequently EVERY statement below keys on (geo_id, district_type) together, and no
--    statement anywhere matches a label against '%austin%'. See the 1,159-collision note in
--    src/lib/geoIdGuard.ts — ad-hoc SQL is NOT covered by that guard, so the discipline has
--    to live in the migration.
--
-- MODEL — matches the Fort Worth / Tarrant County template exactly:
--   governments -> chambers -> offices, with districts carrying the geography.
--   * City of Austin is ONE LOCAL district on the census place polygon, with all 11 offices
--     hanging off it. Austin's 10-1 council map is deliberately NOT modelled as per-district
--     geometry — Fort Worth's 11 seats share one citywide geofence the same way. An Austin
--     address therefore returns all 10 council members, not just the resident's. That is the
--     existing convention; changing it is a separate project, not a side effect of a seed.
--   * Travis County's 12 elected executives split across two chambers, as Tarrant's do:
--     Commissioners Court (5) and Countywide Elected Officials (7).
--
-- SCOPE. Wave 1 is the city plus the county's ELECTED EXECUTIVES. Deliberately excluded, and
-- tracked in .planning/todos/2026-08-18-austin-tx-deep-seed.md:
--   ~30 Travis judicial seats, 5 Justices of the Peace, 5 Constables, Austin ISD (9 trustees,
--   which additionally needs a TIGER school polygon — only 5 G5420 geofences exist in all TX).
--
-- Full roster, per-seat sourcing and the source defects found are in
-- backend/data/seed-austin-2026/ROSTERS.md.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded on a natural key. Re-running changes nothing.
-- There are no UNIQUE constraints on governments, chambers or offices, so the guards are the
-- only thing preventing duplicates — do not convert them to plain INSERTs.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Governments
-- ---------------------------------------------------------------------------
INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Austin, Texas, US', 'LOCAL', 'TX', 'Austin', '4805000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '4805000' AND type = 'LOCAL'
);

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Travis County, Texas, US', 'County', 'TX', NULL, '48453'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '48453' AND type = 'County'
);

-- ---------------------------------------------------------------------------
-- 2. Districts
--    City of Austin is created. Travis County is ADOPTED, not created.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.districts
  (label, district_type, state, geo_id, mtfcc, ocd_id, representation_basis, government_id)
SELECT 'City of Austin', 'LOCAL', 'tx', '4805000', 'G4110',
       'ocd-division/country:us/state:tx/place:austin', 'residency',
       (SELECT id FROM essentials.governments WHERE geo_id = '4805000' AND type = 'LOCAL')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts WHERE geo_id = '4805000' AND district_type = 'LOCAL'
);

-- Travis County already exists with the right geo_id and ocd_id; it is only missing its
-- government link. Guarded UPDATE so a re-run is a no-op.
UPDATE essentials.districts d
   SET government_id = (SELECT id FROM essentials.governments WHERE geo_id = '48453' AND type = 'County')
 WHERE d.geo_id = '48453'
   AND d.district_type = 'COUNTY'
   AND d.government_id IS NULL;

-- ---------------------------------------------------------------------------
-- 3. Chambers
-- ---------------------------------------------------------------------------
-- 🔴 chambers.slug is a GENERATED column — `btrim(regexp_replace(translate(replace(
--    f_unaccent(lower(name_formal)), '&','and'), '''’.',''), '[^a-z0-9]+','-','g'),'-')`.
--    It CANNOT be inserted (Postgres rejects a non-DEFAULT value outright), and it is derived
--    from name_formal, NOT from name. So name_formal is what controls the slug the read path
--    and these guards key on. 'Travis County Elected Officials' is therefore deliberate — it
--    yields 'travis-county-elected-officials', matching Tarrant. Spelling it
--    'Travis County COUNTYWIDE Elected Officials' would silently produce a different slug.
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT (SELECT id FROM essentials.governments WHERE geo_id = '4805000' AND type = 'LOCAL'),
       'City Council', 'Austin City Council', 11, 'full'
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE slug = 'austin-city-council');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT (SELECT id FROM essentials.governments WHERE geo_id = '48453' AND type = 'County'),
       'Commissioners Court', 'Travis County Commissioners Court', 5, 'full'
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE slug = 'travis-county-commissioners-court');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT (SELECT id FROM essentials.governments WHERE geo_id = '48453' AND type = 'County'),
       'Countywide Elected Officials', 'Travis County Elected Officials', 7, 'full'
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE slug = 'travis-county-elected-officials');

-- ---------------------------------------------------------------------------
-- 4. Offices
--    Staged so the guard is one NOT EXISTS on (district_id, title) for all 23 rows.
--    voting_powers is left at its 'full' default and representation_basis stays 'residency',
--    so no representation_note is required (ADR 0003 only demands one when either differs).
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE _seats (
  chamber_slug text NOT NULL,
  district_geo text NOT NULL,
  district_kind text NOT NULL,
  title        text NOT NULL
) ON COMMIT DROP;

INSERT INTO _seats (chamber_slug, district_geo, district_kind, title) VALUES
-- City of Austin (11). Titles copy the Fort Worth form exactly.
('austin-city-council','4805000','LOCAL','Mayor'),
('austin-city-council','4805000','LOCAL','Council Member District 1'),
('austin-city-council','4805000','LOCAL','Council Member District 2'),
('austin-city-council','4805000','LOCAL','Council Member District 3'),
('austin-city-council','4805000','LOCAL','Council Member District 4'),
('austin-city-council','4805000','LOCAL','Council Member District 5'),
('austin-city-council','4805000','LOCAL','Council Member District 6'),
('austin-city-council','4805000','LOCAL','Council Member District 7'),
('austin-city-council','4805000','LOCAL','Council Member District 8'),
('austin-city-council','4805000','LOCAL','Council Member District 9'),
('austin-city-council','4805000','LOCAL','Council Member District 10'),
-- Travis County Commissioners Court (5)
('travis-county-commissioners-court','48453','COUNTY','County Judge'),
('travis-county-commissioners-court','48453','COUNTY','Commissioner, Precinct 1'),
('travis-county-commissioners-court','48453','COUNTY','Commissioner, Precinct 2'),
('travis-county-commissioners-court','48453','COUNTY','Commissioner, Precinct 3'),
('travis-county-commissioners-court','48453','COUNTY','Commissioner, Precinct 4'),
-- Travis County countywide elected executives (7).
-- Tarrant County has NO Sheriff, County Attorney, Tax Assessor-Collector or Treasurer office
-- despite seeding 30 judicial seats, so there is no template for four of these seven titles.
-- The county's own printed titles are used. 'District Attorney' is the short form; votetravis
-- prints the formal 'District Attorney, 53rd Judicial District'.
('travis-county-elected-officials','48453','COUNTY','District Attorney'),
('travis-county-elected-officials','48453','COUNTY','County Attorney'),
('travis-county-elected-officials','48453','COUNTY','Sheriff'),
('travis-county-elected-officials','48453','COUNTY','Tax Assessor-Collector'),
('travis-county-elected-officials','48453','COUNTY','County Clerk'),
('travis-county-elected-officials','48453','COUNTY','District Clerk'),
('travis-county-elected-officials','48453','COUNTY','County Treasurer');

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, is_appointed_position, is_vacant)
SELECT c.id, d.id, s.title, 1, false, false
FROM _seats s
JOIN essentials.chambers c ON c.slug = s.chamber_slug
JOIN essentials.districts d
  ON d.geo_id = s.district_geo AND d.district_type = s.district_kind   -- both, never geo_id alone
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.title = s.title
);

-- ---------------------------------------------------------------------------
-- 5. Post-verify gate
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  city_district   int;
  city_offices    int;
  county_offices  int;
  comm_ct         int;
  exec_ct         int;
  gov_ct          int;
  cham_ct         int;
  orphan_note     int;
  travis_gov      int;
  wrong_geo       int;
BEGIN
  SELECT count(*) INTO city_district
    FROM essentials.districts WHERE geo_id = '4805000' AND district_type = 'LOCAL';
  IF city_district <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 City of Austin LOCAL district, found %', city_district;
  END IF;

  -- The collision guard, asserted rather than assumed: creating the Austin city district
  -- must not have touched Austin County or the two TX district-15 rows on geo_id 48015.
  SELECT count(*) INTO wrong_geo
    FROM essentials.districts WHERE geo_id = '48015';
  IF wrong_geo <> 3 THEN
    RAISE EXCEPTION 'geo_id 48015 should still hold exactly 3 districts (Austin County, TX SD15, TX HD15), found %', wrong_geo;
  END IF;

  SELECT count(*) INTO gov_ct FROM essentials.governments
   WHERE (geo_id = '4805000' AND type = 'LOCAL') OR (geo_id = '48453' AND type = 'County');
  IF gov_ct <> 2 THEN
    RAISE EXCEPTION 'expected 2 governments (Austin, Travis), found %', gov_ct;
  END IF;

  SELECT count(*) INTO cham_ct FROM essentials.chambers
   WHERE slug IN ('austin-city-council','travis-county-commissioners-court','travis-county-elected-officials');
  IF cham_ct <> 3 THEN
    RAISE EXCEPTION 'expected 3 chambers, found %', cham_ct;
  END IF;

  SELECT count(*) INTO travis_gov FROM essentials.districts
   WHERE geo_id = '48453' AND district_type = 'COUNTY' AND government_id IS NOT NULL;
  IF travis_gov <> 1 THEN
    RAISE EXCEPTION 'Travis County district is not linked to its government';
  END IF;

  SELECT count(*) INTO city_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '4805000' AND d.district_type = 'LOCAL';
  IF city_offices <> 11 THEN
    RAISE EXCEPTION 'expected 11 City of Austin offices, found %', city_offices;
  END IF;

  SELECT count(*) INTO county_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '48453' AND d.district_type = 'COUNTY';
  IF county_offices <> 12 THEN
    RAISE EXCEPTION 'expected 12 Travis County offices, found %', county_offices;
  END IF;

  SELECT count(*) INTO comm_ct
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.slug = 'travis-county-commissioners-court';
  IF comm_ct <> 5 THEN
    RAISE EXCEPTION 'expected 5 Commissioners Court seats, found %', comm_ct;
  END IF;

  SELECT count(*) INTO exec_ct
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.slug = 'travis-county-elected-officials';
  IF exec_ct <> 7 THEN
    RAISE EXCEPTION 'expected 7 countywide elected-official seats, found %', exec_ct;
  END IF;

  -- ADR 0003: a note is REQUIRED whenever voting_powers <> 'full' or the district's
  -- representation_basis <> 'residency'. All 23 of these are full-voting residency seats,
  -- so the correct assertion is that none of them needs a note.
  SELECT count(*) INTO orphan_note
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id IN ('4805000','48453')
     AND d.district_type IN ('LOCAL','COUNTY')
     AND (o.voting_powers <> 'full' OR d.representation_basis <> 'residency');
  IF orphan_note <> 0 THEN
    RAISE EXCEPTION '% Austin/Travis seat(s) are not full-voting residency seats and would need representation_note', orphan_note;
  END IF;

  RAISE NOTICE 'OK: Austin/Travis wave 1 Part A — 2 governments, 3 chambers, 1 new district, 23 seats (11 city + 12 county). NO OCCUPANTS YET: Part B must run.';
END $$;

COMMIT;
