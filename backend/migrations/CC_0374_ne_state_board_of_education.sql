-- CC_0374 — Nebraska State Board of Education: all 8 seats created and seated on the 2021 district map,
--           and the 4 results of the 2026 general election.
--
-- 🔴🔴 THE POLYGONS ARE NOT IN THIS FILE. They are loaded by
--   scripts/CC_0373-ne-boards-geofences.mjs --body sboe, WHICH MUST RUN FIRST. This file
--   asserts the rows are there, are the right shape, are the map the enacted plan describes,
--   and reach the right member.
--
-- 🔴🔴 NEBRASKA REDISTRICTS BY MAP REFERENCE, SO THERE IS NO STATUTORY COUNTY TEXT TO GATE ON.
--   
--   Eight members, one per district, elected on the NONPARTISAN ballot to
--   four-year terms (Neb. Const. Art. VII-3; Neb. Rev. Stat. 32-511, 79-313). 🔴
--   The districts are set by LB 7 of the 2021 First Special Session 'by the
--   adoption of maps by reference' — maps ED21-39003-1 through ED21-39003-8 —
--   and Neb. Rev. Stat. 79-311 lists no county. ⚠ LR278CA (2024) proposed a
--   constitutional amendment cutting the board to seven members from the terms
--   commencing in 2027, two of them appointed by the Governor; it was
--   INDEFINITELY POSTPONED on 2024-04-18 and never reached the ballot, so the
--   board remains eight elected members.
--
-- 🟢🟢 SO THE COMPOSITION GATE COMES FROM THE SECRETARY OF STATE'S CERTIFIED CANVASS BOOKS.
--   A county that cast votes in a district's race is in that district, and a county split
--   between two districts casts votes in both. Three canvasses — the 2022 general, the 2024
--   general and the 2026 primary — cover all 8 districts, and the districts that appear in
--   two of them must read the same in both. 89 counties are assigned whole and 4 are split.
--   data/state-exec-2026-results/parse-ne-canvass-counties.mjs does the reading, bounded by
--   each book's own table of contents so that no other office's districts can leak in.
--   🔴 The split floor is 0.1%, measured: the smallest real split share in Nebraska is Burt
--     County's 1.876912% in State Board of Education District 6, and the largest spurious
--     one — a county merely grazing a district it is not in — is 0.006454%.
--
-- 🟢 AND A SECOND ANCHOR: THE ENACTED PLAN'S OWN POPULATION TABLE. The Legislative Research
--   Office prints a population and deviation on each district's map sheet. The loader checks
--   the GIS attribute against it before a row is written. It is the only thing that can
--   separate two districts whose county sets are identical.
--
-- WHAT IT WRITES:
--   1 chamber · 8 districts · 8 offices · 8 office_terms · 4 races · 13 politicians · 7 candidacies
--
--   District  1  holder Kristin Christensen    anchor — none possible   
--   District  2  holder Maggie Douglas         anchor Otoe County       
--   District  3  holder Lisa Schonhoff         anchor Dodge County      
--   District  4  holder Liz Renner             anchor — none possible   
--   District  5  holder Kirk Penner            anchor Gage County       🏆 Angie Eberspacher won the seat
--   District  6  holder Sherry Jones           anchor Hall County       🏆 re-elected
--   District  7  holder Elizabeth Tegtmeier    anchor Lincoln County    🏆 re-elected
--   District  8  holder Deborah Neary          anchor — none possible   🏆 Lou Ann Goding won the seat
--
-- 🔴 AN OFFICE WITH NO office_terms ROW RAISES THE DRIFT BASELINE, so all 8 are created WITH
--   their current member seated, and the post-verify asserts the unflagged baseline is still
--   exactly 238.
--   ▶ 2027-01-07 — the winners take office. Neb. Const. Art. XVII-5: terms begin on the first
--     Thursday after the first Tuesday in January next succeeding the election, which in
--     2027 is Thursday 7 January. On that date, seat:
--       District 5: Angie Eberspacher replaces Kirk Penner
--       District 8: Lou Ann Goding replaces Deborah Neary
--     Sherry Jones (D6), Elizabeth Tegtmeier (D7) were re-elected and stay.
--
-- 🔴 3 OF THE 8 DISTRICTS CANNOT BE ANCHORED ON A WHOLE COUNTY.
--   District 1 is wholly inside Lancaster County and districts 4 and 8 are
--   both wholly inside Douglas County. District 1 is still pinned, because it
--   is the only district whose county set is {Lancaster}. 🔴 DISTRICTS 4 AND 8
--   ARE NOT PINNED BY COUNTY: both have the county set {Douglas}, so the
--   canvass cannot tell them apart, and only the enacted plan's population
--   separates them — District 4 holds 245,713 people and District 8 holds
--   246,703.
--
-- IDENTITY. All 13 people are new. A sweep of all 91,770 politicians on both full name
--   and (first, last) returned nothing for any of the 34 names across the three Nebraska
--   boards. 🟢 The sweep is not blind: its positive control found Pete Ricketts, and its
--   (first, last) arm was shown to work by returning four politicians surnamed Jones whose
--   first name begins with S — just not a Sherry. Production holds only 12 Nebraska
--   officeholders, all statewide executives or members of Congress.
--
-- 🔴 NO TERM START IS INVENTED FOR A SITTING MEMBER. The rosters publish when a member was
--   FIRST elected, which is a different fact, so every term written here is open-ended with
--   start_precision 'unknown'.
--
-- Applied to production 2026-11-07 by Chris Cantrell. Slot reserved via steward.

BEGIN;

CREATE TEMP TABLE seat (
  d int PRIMARY KEY, who text NOT NULL,
  on_ballot_2026 boolean NOT NULL, race_recorded boolean NOT NULL
) ON COMMIT DROP;
INSERT INTO seat VALUES
  (1, 'Kristin Christensen', false, false),
  (2, 'Maggie Douglas', false, false),
  (3, 'Lisa Schonhoff', false, false),
  (4, 'Liz Renner', false, false),
  (5, 'Kirk Penner', true, true),
  (6, 'Sherry Jones', true, true),
  (7, 'Elizabeth Tegtmeier', true, true),
  (8, 'Deborah Neary', true, true);

-- One county per district that the canvass assigns WHOLE to it.
-- 🔴 THE MEMBER'S NAME IS WRITTEN OUT HERE ON PURPOSE, not read from the seat table.
CREATE TEMP TABLE anchor (d int PRIMARY KEY, county text NOT NULL, member text NOT NULL) ON COMMIT DROP;
INSERT INTO anchor VALUES
  (2, 'Otoe County', 'Maggie Douglas'),
  (3, 'Dodge County', 'Lisa Schonhoff'),
  (5, 'Gage County', 'Kirk Penner'),
  (6, 'Hall County', 'Sherry Jones'),
  (7, 'Lincoln County', 'Elizabeth Tegtmeier');

-- The county composition, read from the Secretary of State's canvass books.
CREATE TEMP TABLE plan_whole (county text PRIMARY KEY, d int NOT NULL) ON COMMIT DROP;
INSERT INTO plan_whole VALUES
  ('Adams County', 6),
  ('Antelope County', 6),
  ('Arthur County', 7),
  ('Banner County', 7),
  ('Blaine County', 7),
  ('Boone County', 6),
  ('Box Butte County', 7),
  ('Boyd County', 7),
  ('Brown County', 7),
  ('Buffalo County', 6),
  ('Butler County', 5),
  ('Cass County', 2),
  ('Cedar County', 6),
  ('Chase County', 7),
  ('Cherry County', 7),
  ('Cheyenne County', 7),
  ('Clay County', 5),
  ('Colfax County', 3),
  ('Custer County', 7),
  ('Dakota County', 6),
  ('Dawes County', 7),
  ('Dawson County', 7),
  ('Deuel County', 7),
  ('Dixon County', 6),
  ('Dodge County', 3),
  ('Dundy County', 7),
  ('Fillmore County', 5),
  ('Franklin County', 5),
  ('Frontier County', 7),
  ('Furnas County', 7),
  ('Gage County', 5),
  ('Garden County', 7),
  ('Garfield County', 7),
  ('Gosper County', 7),
  ('Grant County', 7),
  ('Greeley County', 6),
  ('Hall County', 6),
  ('Hamilton County', 5),
  ('Harlan County', 7),
  ('Hayes County', 7),
  ('Hitchcock County', 7),
  ('Holt County', 7),
  ('Hooker County', 7),
  ('Howard County', 6),
  ('Jefferson County', 5),
  ('Johnson County', 2),
  ('Kearney County', 7),
  ('Keith County', 7),
  ('Keya Paha County', 7),
  ('Kimball County', 7),
  ('Knox County', 6),
  ('Lincoln County', 7),
  ('Logan County', 7),
  ('Loup County', 7),
  ('McPherson County', 7),
  ('Madison County', 3),
  ('Merrick County', 6),
  ('Morrill County', 7),
  ('Nance County', 6),
  ('Nemaha County', 2),
  ('Nuckolls County', 5),
  ('Otoe County', 2),
  ('Pawnee County', 5),
  ('Perkins County', 7),
  ('Phelps County', 7),
  ('Pierce County', 6),
  ('Platte County', 3),
  ('Polk County', 5),
  ('Red Willow County', 7),
  ('Richardson County', 5),
  ('Rock County', 7),
  ('Saline County', 5),
  ('Sarpy County', 2),
  ('Saunders County', 5),
  ('Scotts Bluff County', 7),
  ('Seward County', 5),
  ('Sheridan County', 7),
  ('Sherman County', 7),
  ('Sioux County', 7),
  ('Stanton County', 3),
  ('Thayer County', 5),
  ('Thomas County', 7),
  ('Thurston County', 6),
  ('Valley County', 7),
  ('Washington County', 3),
  ('Wayne County', 6),
  ('Webster County', 5),
  ('Wheeler County', 6),
  ('York County', 5);

CREATE TEMP TABLE plan_split (county text PRIMARY KEY, ds text NOT NULL) ON COMMIT DROP;
INSERT INTO plan_split VALUES
  ('Burt County', '3,6'),
  ('Cuming County', '3,6'),
  ('Douglas County', '3,4,8'),
  ('Lancaster County', '1,5');

-- ─── Pre-gates ───
DO $$ DECLARE txt text; n int; v numeric; BEGIN
  SELECT count(*) INTO n FROM seat; IF n <> 8 THEN RAISE EXCEPTION 'expected 8 seats, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE race_recorded; IF n <> 4 THEN RAISE EXCEPTION 'expected 4 races, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE on_ballot_2026; IF n <> 4 THEN RAISE EXCEPTION 'expected 4 seats on the ballot, found %', n; END IF;
  SELECT string_agg('D' || d, ', ') INTO txt FROM seat WHERE race_recorded <> on_ballot_2026;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seat disagrees with itself about the ballot and the race: %', txt; END IF;
  SELECT count(*) INTO n FROM plan_whole; IF n <> 89 THEN RAISE EXCEPTION 'the plan table holds % whole counties, expected 89', n; END IF;
  SELECT count(*) INTO n FROM plan_split; IF n <> 4 THEN RAISE EXCEPTION 'the plan table holds % split counties, expected 4', n; END IF;
  SELECT count(*) INTO n FROM (SELECT county FROM plan_whole UNION SELECT county FROM plan_split) z;
  IF n <> 93 THEN RAISE EXCEPTION 'the plan table names % counties, and Nebraska has 93', n; END IF;
  SELECT string_agg(z.county, ', ') INTO txt FROM (SELECT county FROM plan_whole UNION SELECT county FROM plan_split) z
   WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries co
                      WHERE co.state = '31' AND co.mtfcc = 'G4020' AND co.name = z.county);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the plan table names counties we hold no polygon for: %', txt; END IF;

  SELECT count(*) INTO n FROM anchor; IF n <> 5 THEN RAISE EXCEPTION 'expected 5 anchors, found %', n; END IF;
  SELECT string_agg('D' || a.d || ' ' || a.county, '; ') INTO txt FROM anchor a
   WHERE NOT EXISTS (SELECT 1 FROM plan_whole w WHERE w.county = a.county AND w.d = a.d);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor county is not assigned whole to its district by the canvass: %', txt; END IF;
  -- ⚠ and every district that COULD be anchored must be
  SELECT string_agg('D' || s.d, ', ' ORDER BY s.d) INTO txt FROM seat s
   WHERE NOT EXISTS (SELECT 1 FROM anchor a WHERE a.d = s.d)
     AND EXISTS (SELECT 1 FROM plan_whole w WHERE w.d = s.d);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'these districts have a whole county and no anchor: %', txt; END IF;

  -- 🔴 the two independent statements of the roster must agree before either is used
  SELECT string_agg('D' || a.d || ': anchor says ' || a.member || ', seat says ' || s.who, '; ') INTO txt
    FROM anchor a JOIN seat s ON s.d = a.d WHERE a.member <> s.who;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the anchor table and the seat table name different members: %', txt; END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = 'bb004e64-eeb4-4605-b062-ea991e7ad38b'::uuid)
    THEN RAISE EXCEPTION 'the Nebraska government row does not exist'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.elections
                  WHERE id = '1224487f-4f73-4048-b553-5629ee19b512'::uuid AND election_date = DATE '2026-11-03' AND state = 'NE')
    THEN RAISE EXCEPTION 'the election row is not the 2026-11-03 Nebraska general'; END IF;

  IF EXISTS (SELECT 1 FROM essentials.chambers WHERE name_formal = 'Nebraska State Board of Education')
    THEN RAISE EXCEPTION 'the chamber this file creates already exists'; END IF;
  SELECT string_agg(o.title || ' (' || coalesce(d.district_type, 'no district') || ' ' || o.id || ')', '; ') INTO txt
    FROM essentials.offices o LEFT JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.representing_state = 'NE' AND o.title ILIKE '%Nebraska State Board of Education Member%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file would duplicate an office we already hold: %', txt; END IF;

  -- 🔴🔴 SCOPED BY THE GEO_ID PREFIX, NOT JUST BY (district_type, state). The Public Service
  --   Commission and the Board of Regents are BOTH STATE_BOARD_EDUCATION in Nebraska, so a count of all
  --   Nebraska STATE_BOARD_EDUCATION districts is not a count of this body's.
  SELECT count(*) INTO n FROM essentials.districts
   WHERE district_type = 'STATE_BOARD_EDUCATION' AND lower(state) = 'ne' AND geo_id LIKE 'ocd-division/country:us/state:ne/sboe:%';
  IF n <> 0 THEN RAISE EXCEPTION '% Nebraska district(s) with this body''s geo_id prefix already exist', n; END IF;

  -- 🔴🔴 THE POLYGONS MUST ALREADY BE LOADED, AND BE THE RIGHT ONES.
  SELECT count(*) INTO n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0003' AND state = '31'
     AND geo_id = ANY (SELECT 'ocd-division/country:us/state:ne/sboe:' || s.d FROM seat s);
  IF n <> 8 THEN RAISE EXCEPTION 'only % of the 8 Nebraska State Board of Education polygons are loaded — run scripts/CC_0373-ne-boards-geofences.mjs --body sboe first', n; END IF;

  SELECT string_agg(gb.geo_id || ' srid=' || public.ST_SRID(gb.geometry) || ' valid=' || public.ST_IsValid(gb.geometry), '; ') INTO txt
    FROM essentials.geofence_boundaries gb WHERE gb.mtfcc = 'X0003' AND gb.state = '31'
     AND gb.geo_id LIKE 'ocd-division/country:us/state:ne/sboe:%'
     AND (public.ST_SRID(gb.geometry) <> 4326 OR NOT public.ST_IsValid(gb.geometry) OR public.ST_IsEmpty(gb.geometry)
          OR public.ST_XMin(gb.geometry) < -105 OR public.ST_XMax(gb.geometry) > -94.5
          OR public.ST_YMin(gb.geometry) < 39 OR public.ST_YMax(gb.geometry) > 43.5);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a loaded polygon is not a valid 4326 Nebraska polygon: %', txt; END IF;

  -- The union must reproduce our own TIGER Nebraska outline. ⚠ NO ::geography CAST HERE or
  -- below — ev-cto decision 0006. This is a ratio of planar areas, and the loader's
  -- geodesic measurement of the same thing came out at 99.9019%.
  SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g))
                     / public.ST_Area(s.g) * 100)::numeric, 3) INTO v
    FROM (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries
           WHERE mtfcc='X0003' AND state='31' AND geo_id LIKE 'ocd-division/country:us/state:ne/sboe:%') u,
         (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='31') s;
  IF v < 99.5 THEN RAISE EXCEPTION 'the 8 districts cover only %%% of the Nebraska outline', v; END IF;

  -- 🟢🟢 THE CANVASS GATE.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.county || ' is only ' ||
           round((public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
                  / public.ST_Area(co.geometry) * 100)::numeric, 4) || '% in D' || w.d AS msg
      FROM plan_whole w
      JOIN essentials.geofence_boundaries co ON co.state='31' AND co.mtfcc='G4020' AND co.name=w.county
      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X0003' AND gb.state='31'
       AND gb.geo_id = 'ocd-division/country:us/state:ne/sboe:' || w.d::text
     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
           < public.ST_Area(co.geometry) * 0.999) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the canvass puts these counties wholly in one district and the map does not: %', txt; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.county || ' (canvass D' || w.d || ') also reaches D' || replace(gb.geo_id, 'ocd-division/country:us/state:ne/sboe:', '') AS msg
      FROM plan_whole w
      JOIN essentials.geofence_boundaries co ON co.state='31' AND co.mtfcc='G4020' AND co.name=w.county
      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X0003' AND gb.state='31'
       AND gb.geo_id LIKE 'ocd-division/country:us/state:ne/sboe:%' AND gb.geo_id <> 'ocd-division/country:us/state:ne/sboe:' || w.d::text
     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
           > public.ST_Area(co.geometry) * 0.0001) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a county the canvass assigns whole reaches into another district: %', txt; END IF;

  -- ⚠ the split floor is 0.1%, measured against Nebraska: the smallest real share is 1.8769%
  SELECT string_agg(z.county || ' -> ' || coalesce(z.got, 'nothing') || ', the canvass says ' || z.ds, '; ') INTO txt FROM (
    SELECT sp.county, sp.ds,
           (SELECT string_agg(replace(gb.geo_id, 'ocd-division/country:us/state:ne/sboe:', ''), ',' ORDER BY (replace(gb.geo_id, 'ocd-division/country:us/state:ne/sboe:', ''))::int)
              FROM essentials.geofence_boundaries gb
             WHERE gb.mtfcc='X0003' AND gb.state='31' AND gb.geo_id LIKE 'ocd-division/country:us/state:ne/sboe:%'
               AND public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
                   > public.ST_Area(co.geometry) * 0.001) AS got
      FROM plan_split sp
      JOIN essentials.geofence_boundaries co ON co.state='31' AND co.mtfcc='G4020' AND co.name=sp.county) z
   WHERE z.got IS DISTINCT FROM z.ds;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a county the canvass splits is shared with the wrong districts: %', txt; END IF;

  -- ⚠ each ZCTA is tested at a point inside Nebraska, not at its own centroid: three of the
  --   586 straddle a state line and ST_PointOnSurface lands outside the state.
  SELECT count(*) INTO n FROM (
    SELECT (SELECT count(*) FROM essentials.geofence_boundaries s
             WHERE s.mtfcc='X0003' AND s.state='31' AND s.geo_id LIKE 'ocd-division/country:us/state:ne/sboe:%'
               AND public.ST_Covers(s.geometry, pt)) k
      FROM (SELECT public.ST_PointOnSurface(public.ST_CollectionExtract(
                     public.ST_Intersection(z.geometry, st.geometry), 3)) pt
              FROM essentials.geofence_boundaries z,
                   essentials.geofence_boundaries st
             WHERE z.state='31' AND z.mtfcc='G6350'
               AND st.mtfcc='G4000' AND st.geo_id='31'
               AND NOT public.ST_IsEmpty(public.ST_CollectionExtract(public.ST_Intersection(z.geometry, st.geometry), 3))) w) y
   WHERE y.k <> 1;
  IF n <> 0 THEN RAISE EXCEPTION '% Nebraska ZCTA(s) do not resolve to exactly one district', n; END IF;
END $$;

-- ─── Chamber, districts, offices ───
CREATE TEMP TABLE made_chamber (chamber_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.chambers (name, name_formal, government_id, policy_engagement_level,
                                   official_count, term_length, staggered_term, website_url,
                                   inauguration_rules, election_rules, remarks)
  VALUES ('State Board of Education', 'Nebraska State Board of Education', 'bb004e64-eeb4-4605-b062-ea991e7ad38b'::uuid, 'full', 8, '4 years', true, 'https://www.education.ne.gov/stateboard/members/',
          'Neb. Const. Art. XVII-5: the terms of all elected officers begin on the first Thursday after the first Tuesday in January next succeeding their election, so the 2026 winners take office on 2027-01-07. The Secretary of State''s 2024 canvass book states the same rule''s result for the previous cycle: ''Term Start: January 9, 2025.''',
          'Neb. Rev. Stat. 32-511 sets the stagger by district number: districts 1, 2, 3 and 4 were elected in 1996 and every four years after (2024, next 2028); districts 5, 6, 7 and 8 in 1994 and every four years after (2026, next 2030). All four of districts 5 to 8 were on the 2026 ballot.',
          'Eight members, one per district, elected on the NONPARTISAN ballot to four-year terms (Neb. Const. Art. VII-3; Neb. Rev. Stat. 32-511, 79-313). 🔴 The districts are set by LB 7 of the 2021 First Special Session ''by the adoption of maps by reference'' — maps ED21-39003-1 through ED21-39003-8 — and Neb. Rev. Stat. 79-311 lists no county. ⚠ LR278CA (2024) proposed a constitutional amendment cutting the board to seven members from the terms commencing in 2027, two of them appointed by the Governor; it was INDEFINITELY POSTPONED on 2024-04-18 and never reached the ballot, so the board remains eight elected members.')
  RETURNING id)
INSERT INTO made_chamber SELECT id FROM ins;

CREATE TEMP TABLE made_district (d int PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)
  SELECT 'STATE_BOARD_EDUCATION', 'ne',
         'ocd-division/country:us/state:ne/sboe:' || s.d, 'ocd-division/country:us/state:ne/sboe:' || s.d,
         'Nebraska State Board of Education' || ' District ' || s.d, 'X0003', s.d::text, 'residency'
    FROM seat s RETURNING id, geo_id)
INSERT INTO made_district
SELECT replace(ins.geo_id, 'ocd-division/country:us/state:ne/sboe:', '')::int, ins.id FROM ins;

CREATE TEMP TABLE made_office (d int PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, voting_powers,
                                  is_vacant, faces_retention_vote, is_appointed_position, description)
  SELECT 'Nebraska State Board of Education Member, District ' || s.d, mc.chamber_id, md.district_id, 'NE', 'full',
         false, false, false, 'seat:' || s.d
    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc
  RETURNING id, description)
INSERT INTO made_office SELECT replace(ins.description, 'seat:', '')::int, ins.id FROM ins;
UPDATE essentials.offices o SET description = NULL FROM made_office mo WHERE o.id = mo.office_id;

DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM made_district; IF n <> 8 THEN RAISE EXCEPTION 'only % districts were created', n; END IF;
  SELECT count(*) INTO n FROM made_office;   IF n <> 8 THEN RAISE EXCEPTION 'only % offices were created', n; END IF;
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id WHERE o.description IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% office(s) kept the seat key in description', n; END IF;
  SELECT count(*) INTO n FROM made_district md JOIN essentials.districts d ON d.id = md.district_id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc;
  IF n <> 8 THEN RAISE EXCEPTION 'only % of the 8 districts meet a geofence row on (geo_id, mtfcc)', n; END IF;
END $$;

-- ─── The people ───
CREATE TEMP TABLE seed_people (
  full_name text PRIMARY KEY, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people VALUES
  ('Kristin Christensen', 'Kristin', 'Christensen',
   'https://www.education.ne.gov/stateboard/members/ (the body''s own roster, read 2026-11-07) — CC_0374'),
  ('Maggie Douglas', 'Maggie', 'Douglas',
   'https://www.education.ne.gov/stateboard/members/ (the body''s own roster, read 2026-11-07) — CC_0374'),
  ('Lisa Schonhoff', 'Lisa', 'Schonhoff',
   'https://www.education.ne.gov/stateboard/members/ (the body''s own roster, read 2026-11-07) — CC_0374'),
  ('Liz Renner', 'Liz', 'Renner',
   'https://www.education.ne.gov/stateboard/members/ (the body''s own roster, read 2026-11-07) — CC_0374'),
  ('Kirk Penner', 'Kirk', 'Penner',
   'https://www.education.ne.gov/stateboard/members/ (the body''s own roster, read 2026-11-07) — CC_0374'),
  ('Sherry Jones', 'Sherry', 'Jones',
   'https://www.education.ne.gov/stateboard/members/ (the body''s own roster, read 2026-11-07) — CC_0374'),
  ('Elizabeth Tegtmeier', 'Elizabeth', 'Tegtmeier',
   'https://www.education.ne.gov/stateboard/members/ (the body''s own roster, read 2026-11-07) — CC_0374'),
  ('Deborah Neary', 'Deborah', 'Neary',
   'https://www.education.ne.gov/stateboard/members/ (the body''s own roster, read 2026-11-07) — CC_0374'),
  ('Angie Eberspacher', 'Angie', 'Eberspacher',
   'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=SE&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0374'),
  ('Michaela Conway', 'Michaela', 'Conway',
   'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=SE&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0374'),
  ('Grady Erickson', 'Grady', 'Erickson',
   'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=SE&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0374'),
  ('Lou Ann Goding', 'Lou Ann', 'Goding',
   'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=SE&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0374'),
  ('Sherrye Hutcherson', 'Sherrye', 'Hutcherson',
   'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=SE&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0374');

CREATE TEMP TABLE allowed_name_collisions (full_name text PRIMARY KEY) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT lower(translate(coalesce(t, ''), 'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç',
                                          'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc'))
$f$;

CREATE TEMP TABLE pol_keys ON COMMIT DROP AS
SELECT id, full_name, first_name, last_name, is_active, source,
       pg_temp.namekey(full_name) AS k_full, pg_temp.namekey(first_name) AS k_first, pg_temp.namekey(last_name) AS k_last
  FROM essentials.politicians;
CREATE INDEX ON pol_keys (k_full);
CREATE INDEX ON pol_keys (k_first, k_last);
ANALYZE pol_keys;

DO $$ DECLARE txt text; n int; BEGIN
  -- 🔴 a positive control on BOTH arms, so a sweep that finds nothing is a clean sweep
  --   rather than a blind one.
  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Pete Ricketts');
  IF n < 1 THEN RAISE EXCEPTION 'the full-name index cannot see a politician known to exist'; END IF;
  SELECT count(*) INTO n FROM pol_keys WHERE k_first = pg_temp.namekey('Shevrin') AND k_last = pg_temp.namekey('Jones');
  IF n < 1 THEN RAISE EXCEPTION 'the (first, last) index cannot see a politician known to exist'; END IF;
  SELECT count(*) INTO n FROM pol_keys; IF n < 50000 THEN RAISE EXCEPTION 'the name index holds only % rows', n; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT s.full_name || ' already exists as ' || p.full_name || ' (' || p.id || ')' AS msg
      FROM seed_people s JOIN pol_keys p ON p.k_full = pg_temp.namekey(s.full_name)
     WHERE p.source IS DISTINCT FROM s.source AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)
    UNION
    SELECT s.full_name || ' splits to the same (first, last) as ' || p.full_name || ' (' || p.id || ')'
      FROM seed_people s JOIN pol_keys p ON p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name)
     WHERE p.source IS DISTINCT FROM s.source AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file seeds already exists: %', txt; END IF;

  SELECT string_agg(s.full_name || ' splits to (' || s.first_name || ', ' || s.last_name || ')', '; ') INTO txt
    FROM seed_people s WHERE s.full_name <> s.first_name || ' ' || s.last_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded name does not match its own split: %', txt; END IF;
  SELECT string_agg(s.full_name || ' -> ' || s.source, '; ') INTO txt FROM seed_people s
   WHERE s.source NOT LIKE 'https://%' AND s.source NOT LIKE 'Nebraska Secretary of State%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded source is neither a roster URL nor the Secretary of State: %', txt; END IF;
END $$;

SET LOCAL essentials.allow_duplicate_name = 'on';
INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)
SELECT s.full_name, s.first_name, s.last_name, s.source, true,
       EXISTS (SELECT 1 FROM seat st WHERE st.who = s.full_name)
  FROM seed_people s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.source = s.source);
SET LOCAL essentials.allow_duplicate_name = 'off';

CREATE TEMP TABLE person (who text PRIMARY KEY, pid uuid NOT NULL) ON COMMIT DROP;
INSERT INTO person SELECT s.full_name, p.id FROM seed_people s
  JOIN essentials.politicians p ON p.full_name = s.full_name AND p.source = s.source;
DO $$ DECLARE n int; BEGIN SELECT count(*) INTO n FROM person;
  IF n <> 13 THEN RAISE EXCEPTION 'only % of the 13 people resolved to exactly one row', n; END IF; END $$;

-- ─── Seat every current member ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT mo.office_id, pe.pid, NULL, NULL, 'unknown', 'unknown',
       'https://www.education.ne.gov/stateboard/members/ (the body''s own roster, read 2026-11-07) — CC_0374'
  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who;

-- ─── The races and their results ───
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT '1224487f-4f73-4048-b553-5629ee19b512'::uuid, mo.office_id, 'Nebraska State Board of Education' || ' District ' || s.d, NULL, 1,
       CASE s.d
         WHEN 5 THEN 'The seat held by Kirk Penner. Angie Eberspacher (Nonpartisan) 45,942, Michaela Conway (Nonpartisan) 36,737; 360 / 360 fully reported.'
         WHEN 6 THEN 'The seat held by Sherry Jones. Sherry Jones (Nonpartisan) 41,090, Grady Erickson (Nonpartisan) 24,959; 204 / 204 fully reported.'
         WHEN 7 THEN 'The seat held by Elizabeth Tegtmeier. Elizabeth Tegtmeier (Nonpartisan) 69,508; 286 / 286 fully reported.'
         WHEN 8 THEN 'The seat held by Deborah Neary. Lou Ann Goding (Nonpartisan) 41,772, Sherrye Hutcherson (Nonpartisan) 40,255; 234 / 234 fully reported. The closest of the eight: 1,517 votes, 50.92% to 49.08%. Nebraska''s automatic recount threshold is one percent of the leading candidate''s votes (Neb. Rev. Stat. 32-1119), which is 418 here, so the margin is more than three times too wide to trigger one.'
         ELSE NULL END
  FROM seat s JOIN made_office mo ON mo.d = s.d WHERE s.race_recorded;

CREATE TEMP TABLE calls (
  d int NOT NULL, who text NOT NULL, result text NOT NULL, votes int NOT NULL,
  is_incumbent boolean NOT NULL, PRIMARY KEY (d, who)
) ON COMMIT DROP;
INSERT INTO calls VALUES
  (5, 'Angie Eberspacher', 'won', 45942, false),
  (5, 'Michaela Conway', 'lost', 36737, false),
  (6, 'Sherry Jones', 'won', 41090, true),
  (6, 'Grady Erickson', 'lost', 24959, false),
  (7, 'Elizabeth Tegtmeier', 'won', 69508, true),
  (8, 'Lou Ann Goding', 'won', 41772, false),
  (8, 'Sherrye Hutcherson', 'lost', 40255, false);

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM calls; IF n <> 7 THEN RAISE EXCEPTION 'expected 7 candidacies, found %', n; END IF;
  SELECT string_agg('D' || z.d || ': ' || z.w || ' winner(s)', '; ') INTO txt FROM (
    SELECT c.d, count(*) FILTER (WHERE c.result = 'won') w FROM calls c GROUP BY c.d) z WHERE z.w <> 1;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a single-seat race does not hold exactly one winner: %', txt; END IF;
  -- 🔴 the winner must be the candidate with the most votes. A "won" flag and a vote count
  --   are two separate facts, and this is where they are made to agree.
  SELECT string_agg('D' || z.d, ', ') INTO txt FROM (
    SELECT c.d FROM calls c
     GROUP BY c.d
    HAVING max(c.votes) FILTER (WHERE c.result = 'won') < max(c.votes)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the winner is not the leading candidate in: %', txt; END IF;
  SELECT string_agg(c.who, '; ') INTO txt FROM calls c LEFT JOIN person pe ON pe.who = c.who WHERE pe.pid IS NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidacy resolves to no person: %', txt; END IF;
  SELECT string_agg(c.who || ' in D' || c.d, '; ') INTO txt FROM calls c JOIN seat s ON s.d = c.d
   WHERE c.is_incumbent <> (s.who = c.who);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an incumbent flag disagrees with the seat''s holder: %', txt; END IF;
  SELECT count(*) INTO n FROM calls WHERE NOT EXISTS (SELECT 1 FROM seat s WHERE s.d = calls.d AND s.race_recorded);
  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) sit on a district with no race', n; END IF;
END $$;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   is_write_in, source, result, result_certainty, result_source, result_recorded_at)
SELECT r.id, pl.id, pl.full_name, pl.first_name, pl.last_name, c.is_incumbent, 'active', false,
       'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=SE&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0374',
       c.result, 'called',
       'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=SE&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0374', now()
  FROM calls c JOIN made_office mo ON mo.d = c.d
  JOIN essentials.races r ON r.office_id = mo.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN person pe ON pe.who = c.who JOIN essentials.politicians pl ON pl.id = pe.pid;

-- ─── Post-verify ───
DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.d = s.d
    JOIN essentials.races r ON r.office_id = mo.office_id WHERE s.race_recorded;
  IF n <> 4 THEN RAISE EXCEPTION 'expected 4 new races, found %', n; END IF;
  SELECT count(*) INTO n FROM calls c JOIN made_office mo ON mo.d = c.d
    JOIN essentials.races r ON r.office_id = mo.office_id
    JOIN person pe ON pe.who = c.who
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = pe.pid
   WHERE rc.result = c.result AND rc.result_certainty = 'called';
  IF n <> 7 THEN RAISE EXCEPTION 'only % of the 7 candidacies hold their stated result', n; END IF;

  -- 🔴🔴 EVERY NEW OFFICE IS SEATED AND THE DRIFT BASELINE HAS NOT MOVED
  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 8 offices have no term and would raise the drift metric', n; END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;
  IF n <> 238 THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — it was 238 and must never be raised', n; END IF;

  SELECT count(*) INTO n FROM made_chamber mc JOIN essentials.offices o ON o.chamber_id = mc.chamber_id;
  IF n <> 8 THEN RAISE EXCEPTION 'the chamber holds % offices, not 8', n; END IF;
  SELECT official_count INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id;
  IF n <> 8 THEN RAISE EXCEPTION 'official_count is %, not 8', n; END IF;
  SELECT count(*) INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id
   WHERE ch.inauguration_rules ILIKE '%2027-01-07%';
  IF n <> 1 THEN RAISE EXCEPTION 'the chamber does not record the 2027-01-07 handover'; END IF;

  -- 🔴🔴 THE WHOLE CHAIN, FROM A POINT ON THE GROUND TO A NAMED MEMBER, for the 5 districts
  --   the canvass gives a whole county. Districts 1, 4, 8 have none; see the header.
  SELECT string_agg(a.county || ' -> ' || coalesce(x.who, 'nobody') || ' (expected ' || a.member || ')', '; ') INTO txt
    FROM anchor a
    LEFT JOIN LATERAL (
      SELECT string_agg(DISTINCT pl.full_name, ', ') AS who
        FROM essentials.geofence_boundaries co
        JOIN essentials.geofence_boundaries gb
          ON gb.mtfcc = 'X0003' AND gb.state = '31' AND gb.geo_id LIKE 'ocd-division/country:us/state:ne/sboe:%'
         AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(co.geometry))
        JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc
         AND dd.district_type = 'STATE_BOARD_EDUCATION'
        JOIN essentials.offices o ON o.district_id = dd.id
        JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
        JOIN essentials.politicians pl ON pl.id = och.politician_id
       WHERE co.state = '31' AND co.mtfcc = 'G4020' AND co.name = a.county) x ON true
   WHERE x.who IS DISTINCT FROM a.member;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor county does not reach its member: %', txt; END IF;

  SELECT count(*) INTO n FROM made_office mo JOIN essentials.office_terms t ON t.office_id = mo.office_id
   WHERE t.term_start IS NOT NULL OR t.term_end IS NOT NULL OR t.start_precision <> 'unknown';
  IF n <> 0 THEN RAISE EXCEPTION '% term(s) claim a date this file cannot source', n; END IF;

  RAISE NOTICE 'CC_0374 OK — 8 Nebraska State Board of Education seats created and seated, 4 races, 7 candidacies, 13 people seeded.';
END $$;

COMMIT;
