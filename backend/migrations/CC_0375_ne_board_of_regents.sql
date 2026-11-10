-- CC_0375 — University of Nebraska Board of Regents: all 8 seats created and seated on the 2021 district map,
--           and the 3 results of the 2026 general election.
--
-- 🔴🔴 THE POLYGONS ARE NOT IN THIS FILE. They are loaded by
--   scripts/CC_0373-ne-boards-geofences.mjs --body regents, WHICH MUST RUN FIRST. This file
--   asserts the rows are there, are the right shape, are the map the enacted plan describes,
--   and reach the right member.
--
-- 🔴🔴 NEBRASKA REDISTRICTS BY MAP REFERENCE, SO THERE IS NO STATUTORY COUNTY TEXT TO GATE ON.
--   
--   Eight regents, one per district, elected on the NONPARTISAN ballot to
--   six-year terms (Neb. Const. Art. VII-10; Neb. Rev. Stat. 32-510). 🔴 The
--   districts are set by LB 8 of the 2021 First Special Session 'by the adoption
--   of maps by reference' — maps REG21-39003-1 through REG21-39003-8 — and Neb.
--   Rev. Stat. 85-103.01 lists no county. ⚠ The file the Legislature publishes
--   as reg_lb8_final.pdf is NOT the enacted plan: its sheets were drawn on
--   2021-09-25, three days before AM41 was adopted, and four of its eight
--   districts are pre-amendment. ⚠ The board also seats four NON-VOTING student
--   regents, one from each campus, who serve while they are their campus's
--   student body president. They hold no district, are not elected by the
--   public, and are not created here.
--
-- 🟢🟢 SO THE COMPOSITION GATE COMES FROM THE SECRETARY OF STATE'S CERTIFIED CANVASS BOOKS.
--   A county that cast votes in a district's race is in that district, and a county split
--   between two districts casts votes in both. Three canvasses — the 2022 general, the 2024
--   general and the 2026 primary — cover all 8 districts, and the districts that appear in
--   two of them must read the same in both. 90 counties are assigned whole and 3 are split.
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
--   🔴🔴 AND IT CAUGHT A REAL ONE. The file the Legislature publishes as reg_lb8_final.pdf
--     carries sheets drawn on 2021-09-25 — three days before AM41 was filed and adopted on
--     the 28th, and five before the bill passed 46-2-1 on the 30th. Four of its eight
--     districts are pre-amendment: it gives District 1 as 242,357 against the enacted
--     248,649 and District 4 as 234,292 against 237,525, with the differences traded to 5
--     and 8. reg_lb8_am41.pdf has the enacted figures and the State of Nebraska's own GIS
--     agrees with it on all eight. ▶ A sheet titled "Final Reading" can predate the
--     amendment that passed — and because LB 8 adopts the plan by the map NAME, which AM41
--     did not change, the statute cannot tell the two versions apart either.
--
-- WHAT IT WRITES:
--   1 chamber · 8 districts · 8 offices · 8 office_terms · 3 races · 14 politicians · 6 candidacies
--
--   District  1  holder Timothy Clare          anchor — none possible   🏆 Brent Comstock won the seat
--   District  2  holder Jack Stark             anchor — none possible   🏆 Elizabeth Butler won the seat
--   District  3  holder Jim Scheer             anchor Madison County    
--   District  4  holder Joel Makovicka         anchor — none possible   🏆 Justin Solomon won the seat
--   District  5  holder Robert Schafer         anchor Gage County       
--   District  6  holder Paul Kenney            anchor Hall County       
--   District  7  holder Kathy Wilmot           anchor Lincoln County    
--   District  8  holder Barbara Weitz          anchor — none possible   
--
-- 🔴 AN OFFICE WITH NO office_terms ROW RAISES THE DRIFT BASELINE, so all 8 are created WITH
--   their current member seated, and the post-verify asserts the unflagged baseline is still
--   exactly 238.
--   ▶ 2027-01-07 — the winners take office. Neb. Const. Art. XVII-5: terms begin on the first
--     Thursday after the first Tuesday in January next succeeding the election, which in
--     2027 is Thursday 7 January. On that date, seat:
--       District 1: Brent Comstock replaces Timothy Clare
--       District 2: Elizabeth Butler replaces Jack Stark
--       District 4: Justin Solomon replaces Joel Makovicka
--
-- 🔴 4 OF THE 8 DISTRICTS CANNOT BE ANCHORED ON A WHOLE COUNTY.
--   District 1 is wholly inside Lancaster County, districts 4 and 8 wholly
--   inside Douglas, and district 2 is made only of parts of Douglas and Sarpy.
--   Districts 1 and 2 are still pinned, because {Lancaster} and {Douglas,
--   Sarpy} are each a county set no other Regents district has. 🔴 DISTRICTS 4
--   AND 8 ARE NOT PINNED BY COUNTY: both have the county set {Douglas}, and
--   only the enacted plan's population separates them — District 4 holds
--   237,525 people and District 8 holds 245,234.
--
-- IDENTITY. All 14 people are new. A sweep of all 91,770 politicians on both full name
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
  (1, 'Timothy Clare', true, true),
  (2, 'Jack Stark', true, true),
  (3, 'Jim Scheer', false, false),
  (4, 'Joel Makovicka', true, true),
  (5, 'Robert Schafer', false, false),
  (6, 'Paul Kenney', false, false),
  (7, 'Kathy Wilmot', false, false),
  (8, 'Barbara Weitz', false, false);

-- One county per district that the canvass assigns WHOLE to it.
-- 🔴 THE MEMBER'S NAME IS WRITTEN OUT HERE ON PURPOSE, not read from the seat table.
CREATE TEMP TABLE anchor (d int PRIMARY KEY, county text NOT NULL, member text NOT NULL) ON COMMIT DROP;
INSERT INTO anchor VALUES
  (3, 'Madison County', 'Jim Scheer'),
  (5, 'Gage County', 'Robert Schafer'),
  (6, 'Hall County', 'Paul Kenney'),
  (7, 'Lincoln County', 'Kathy Wilmot');

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
  ('Burt County', 3),
  ('Butler County', 3),
  ('Cass County', 5),
  ('Cedar County', 3),
  ('Chase County', 7),
  ('Cherry County', 7),
  ('Cheyenne County', 7),
  ('Clay County', 6),
  ('Colfax County', 3),
  ('Cuming County', 3),
  ('Custer County', 7),
  ('Dakota County', 3),
  ('Dawes County', 7),
  ('Dawson County', 7),
  ('Deuel County', 7),
  ('Dixon County', 3),
  ('Dodge County', 3),
  ('Dundy County', 7),
  ('Fillmore County', 6),
  ('Franklin County', 6),
  ('Frontier County', 7),
  ('Furnas County', 7),
  ('Gage County', 5),
  ('Garden County', 7),
  ('Garfield County', 7),
  ('Gosper County', 7),
  ('Grant County', 7),
  ('Greeley County', 7),
  ('Hall County', 6),
  ('Hamilton County', 6),
  ('Harlan County', 7),
  ('Hayes County', 7),
  ('Hitchcock County', 7),
  ('Holt County', 7),
  ('Hooker County', 7),
  ('Howard County', 6),
  ('Jefferson County', 5),
  ('Johnson County', 5),
  ('Kearney County', 6),
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
  ('Nemaha County', 5),
  ('Nuckolls County', 6),
  ('Otoe County', 5),
  ('Pawnee County', 5),
  ('Perkins County', 7),
  ('Phelps County', 7),
  ('Pierce County', 6),
  ('Platte County', 3),
  ('Polk County', 3),
  ('Red Willow County', 7),
  ('Richardson County', 5),
  ('Rock County', 7),
  ('Saline County', 5),
  ('Saunders County', 3),
  ('Scotts Bluff County', 7),
  ('Seward County', 5),
  ('Sheridan County', 7),
  ('Sherman County', 7),
  ('Sioux County', 7),
  ('Stanton County', 3),
  ('Thayer County', 5),
  ('Thomas County', 7),
  ('Thurston County', 3),
  ('Valley County', 7),
  ('Washington County', 3),
  ('Wayne County', 3),
  ('Webster County', 6),
  ('Wheeler County', 7),
  ('York County', 6);

CREATE TEMP TABLE plan_split (county text PRIMARY KEY, ds text NOT NULL) ON COMMIT DROP;
INSERT INTO plan_split VALUES
  ('Douglas County', '2,4,8'),
  ('Lancaster County', '1,5'),
  ('Sarpy County', '2,5');

-- ─── Pre-gates ───
DO $$ DECLARE txt text; n int; v numeric; BEGIN
  SELECT count(*) INTO n FROM seat; IF n <> 8 THEN RAISE EXCEPTION 'expected 8 seats, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE race_recorded; IF n <> 3 THEN RAISE EXCEPTION 'expected 3 races, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE on_ballot_2026; IF n <> 3 THEN RAISE EXCEPTION 'expected 3 seats on the ballot, found %', n; END IF;
  SELECT string_agg('D' || d, ', ') INTO txt FROM seat WHERE race_recorded <> on_ballot_2026;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seat disagrees with itself about the ballot and the race: %', txt; END IF;
  SELECT count(*) INTO n FROM plan_whole; IF n <> 90 THEN RAISE EXCEPTION 'the plan table holds % whole counties, expected 90', n; END IF;
  SELECT count(*) INTO n FROM plan_split; IF n <> 3 THEN RAISE EXCEPTION 'the plan table holds % split counties, expected 3', n; END IF;
  SELECT count(*) INTO n FROM (SELECT county FROM plan_whole UNION SELECT county FROM plan_split) z;
  IF n <> 93 THEN RAISE EXCEPTION 'the plan table names % counties, and Nebraska has 93', n; END IF;
  SELECT string_agg(z.county, ', ') INTO txt FROM (SELECT county FROM plan_whole UNION SELECT county FROM plan_split) z
   WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries co
                      WHERE co.state = '31' AND co.mtfcc = 'G4020' AND co.name = z.county);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the plan table names counties we hold no polygon for: %', txt; END IF;

  SELECT count(*) INTO n FROM anchor; IF n <> 4 THEN RAISE EXCEPTION 'expected 4 anchors, found %', n; END IF;
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

  IF EXISTS (SELECT 1 FROM essentials.chambers WHERE name_formal = 'University of Nebraska Board of Regents')
    THEN RAISE EXCEPTION 'the chamber this file creates already exists'; END IF;
  SELECT string_agg(o.title || ' (' || coalesce(d.district_type, 'no district') || ' ' || o.id || ')', '; ') INTO txt
    FROM essentials.offices o LEFT JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.representing_state = 'NE' AND o.title ILIKE '%University of Nebraska Regent%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file would duplicate an office we already hold: %', txt; END IF;

  -- 🔴🔴 SCOPED BY THE GEO_ID PREFIX, NOT JUST BY (district_type, state). The Public Service
  --   Commission and the Board of Regents are BOTH STATE_BOARD in Nebraska, so a count of all
  --   Nebraska STATE_BOARD districts is not a count of this body's.
  SELECT count(*) INTO n FROM essentials.districts
   WHERE district_type = 'STATE_BOARD' AND lower(state) = 'ne' AND geo_id LIKE 'ocd-division/country:us/state:ne/regents:%';
  IF n <> 0 THEN RAISE EXCEPTION '% Nebraska district(s) with this body''s geo_id prefix already exist', n; END IF;

  -- 🔴🔴 THE POLYGONS MUST ALREADY BE LOADED, AND BE THE RIGHT ONES.
  SELECT count(*) INTO n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X-ST-BOARD' AND state = '31'
     AND geo_id = ANY (SELECT 'ocd-division/country:us/state:ne/regents:' || s.d FROM seat s);
  IF n <> 8 THEN RAISE EXCEPTION 'only % of the 8 University of Nebraska Board of Regents polygons are loaded — run scripts/CC_0373-ne-boards-geofences.mjs --body regents first', n; END IF;

  SELECT string_agg(gb.geo_id || ' srid=' || public.ST_SRID(gb.geometry) || ' valid=' || public.ST_IsValid(gb.geometry), '; ') INTO txt
    FROM essentials.geofence_boundaries gb WHERE gb.mtfcc = 'X-ST-BOARD' AND gb.state = '31'
     AND gb.geo_id LIKE 'ocd-division/country:us/state:ne/regents:%'
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
           WHERE mtfcc='X-ST-BOARD' AND state='31' AND geo_id LIKE 'ocd-division/country:us/state:ne/regents:%') u,
         (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='31') s;
  IF v < 99.5 THEN RAISE EXCEPTION 'the 8 districts cover only %%% of the Nebraska outline', v; END IF;

  -- 🟢🟢 THE CANVASS GATE.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.county || ' is only ' ||
           round((public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
                  / public.ST_Area(co.geometry) * 100)::numeric, 4) || '% in D' || w.d AS msg
      FROM plan_whole w
      JOIN essentials.geofence_boundaries co ON co.state='31' AND co.mtfcc='G4020' AND co.name=w.county
      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X-ST-BOARD' AND gb.state='31'
       AND gb.geo_id = 'ocd-division/country:us/state:ne/regents:' || w.d::text
     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
           < public.ST_Area(co.geometry) * 0.999) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the canvass puts these counties wholly in one district and the map does not: %', txt; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.county || ' (canvass D' || w.d || ') also reaches D' || replace(gb.geo_id, 'ocd-division/country:us/state:ne/regents:', '') AS msg
      FROM plan_whole w
      JOIN essentials.geofence_boundaries co ON co.state='31' AND co.mtfcc='G4020' AND co.name=w.county
      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X-ST-BOARD' AND gb.state='31'
       AND gb.geo_id LIKE 'ocd-division/country:us/state:ne/regents:%' AND gb.geo_id <> 'ocd-division/country:us/state:ne/regents:' || w.d::text
     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
           > public.ST_Area(co.geometry) * 0.0001) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a county the canvass assigns whole reaches into another district: %', txt; END IF;

  -- ⚠ the split floor is 0.1%, measured against Nebraska: the smallest real share is 1.8769%
  SELECT string_agg(z.county || ' -> ' || coalesce(z.got, 'nothing') || ', the canvass says ' || z.ds, '; ') INTO txt FROM (
    SELECT sp.county, sp.ds,
           (SELECT string_agg(replace(gb.geo_id, 'ocd-division/country:us/state:ne/regents:', ''), ',' ORDER BY (replace(gb.geo_id, 'ocd-division/country:us/state:ne/regents:', ''))::int)
              FROM essentials.geofence_boundaries gb
             WHERE gb.mtfcc='X-ST-BOARD' AND gb.state='31' AND gb.geo_id LIKE 'ocd-division/country:us/state:ne/regents:%'
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
             WHERE s.mtfcc='X-ST-BOARD' AND s.state='31' AND s.geo_id LIKE 'ocd-division/country:us/state:ne/regents:%'
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
  VALUES ('Board of Regents', 'University of Nebraska Board of Regents', 'bb004e64-eeb4-4605-b062-ea991e7ad38b'::uuid, 'full', 8, '6 years', true, 'https://nebraska.edu/regents/board-members/index',
          'Neb. Const. Art. XVII-5: the terms of all elected officers begin on the first Thursday after the first Tuesday in January next succeeding their election, so the 2026 winners take office on 2027-01-07. The Governor''s office used the same date independently when it announced that Joel Makovicka, appointed to the District 4 vacancy on 2026-02-03, would ''serve through Jan. 7, 2027''.',
          'Neb. Rev. Stat. 32-510 sets the stagger by district number: districts 1 and 2 were elected in 1996 and every six years after (2026, next 2032); districts 6 and 7 in 1992 and every six years after (2022, next 2028); districts 3, 4, 5 and 8 in 1994 and every six years after (2024, next 2030). Districts 1 and 2 were on the 2026 ballot for full six-year terms. ⚠ District 4 was ALSO on the 2026 ballot, for the unexpired remainder of the term elected in 2024, and that seat is next up in 2030 with the rest of its class.',
          'Eight regents, one per district, elected on the NONPARTISAN ballot to six-year terms (Neb. Const. Art. VII-10; Neb. Rev. Stat. 32-510). 🔴 The districts are set by LB 8 of the 2021 First Special Session ''by the adoption of maps by reference'' — maps REG21-39003-1 through REG21-39003-8 — and Neb. Rev. Stat. 85-103.01 lists no county. ⚠ The file the Legislature publishes as reg_lb8_final.pdf is NOT the enacted plan: its sheets were drawn on 2021-09-25, three days before AM41 was adopted, and four of its eight districts are pre-amendment. ⚠ The board also seats four NON-VOTING student regents, one from each campus, who serve while they are their campus''s student body president. They hold no district, are not elected by the public, and are not created here.')
  RETURNING id)
INSERT INTO made_chamber SELECT id FROM ins;

CREATE TEMP TABLE made_district (d int PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)
  SELECT 'STATE_BOARD', 'ne',
         'ocd-division/country:us/state:ne/regents:' || s.d, 'ocd-division/country:us/state:ne/regents:' || s.d,
         'University of Nebraska Board of Regents' || ' District ' || s.d, 'X-ST-BOARD', s.d::text, 'residency'
    FROM seat s RETURNING id, geo_id)
INSERT INTO made_district
SELECT replace(ins.geo_id, 'ocd-division/country:us/state:ne/regents:', '')::int, ins.id FROM ins;

CREATE TEMP TABLE made_office (d int PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, voting_powers,
                                  is_vacant, faces_retention_vote, is_appointed_position, description)
  SELECT 'University of Nebraska Regent, District ' || s.d, mc.chamber_id, md.district_id, 'NE', 'full',
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
  ('Timothy Clare', 'Timothy', 'Clare',
   'https://nebraska.edu/regents/board-members/index (the body''s own roster, read 2026-11-07) — CC_0375'),
  ('Jack Stark', 'Jack', 'Stark',
   'https://nebraska.edu/regents/board-members/index (the body''s own roster, read 2026-11-07) — CC_0375'),
  ('Jim Scheer', 'Jim', 'Scheer',
   'https://nebraska.edu/regents/board-members/index (the body''s own roster, read 2026-11-07) — CC_0375'),
  ('Joel Makovicka', 'Joel', 'Makovicka',
   'https://nebraska.edu/regents/board-members/index (the body''s own roster, read 2026-11-07) — CC_0375'),
  ('Robert Schafer', 'Robert', 'Schafer',
   'https://nebraska.edu/regents/board-members/index (the body''s own roster, read 2026-11-07) — CC_0375'),
  ('Paul Kenney', 'Paul', 'Kenney',
   'https://nebraska.edu/regents/board-members/index (the body''s own roster, read 2026-11-07) — CC_0375'),
  ('Kathy Wilmot', 'Kathy', 'Wilmot',
   'https://nebraska.edu/regents/board-members/index (the body''s own roster, read 2026-11-07) — CC_0375'),
  ('Barbara Weitz', 'Barbara', 'Weitz',
   'https://nebraska.edu/regents/board-members/index (the body''s own roster, read 2026-11-07) — CC_0375'),
  ('Brent Comstock', 'Brent', 'Comstock',
   'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=RG&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0375'),
  ('Jeremy Hosein', 'Jeremy', 'Hosein',
   'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=RG&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0375'),
  ('Elizabeth Butler', 'Elizabeth', 'Butler',
   'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=RG&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0375'),
  ('Jill Wolfe', 'Jill', 'Wolfe',
   'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=RG&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0375'),
  ('Justin Solomon', 'Justin', 'Solomon',
   'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=RG&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0375'),
  ('Susanne Shore', 'Susanne', 'Shore',
   'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=RG&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0375');

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
  IF n <> 14 THEN RAISE EXCEPTION 'only % of the 14 people resolved to exactly one row', n; END IF; END $$;

-- ─── Seat every current member ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT mo.office_id, pe.pid, NULL, NULL, 'unknown', 'unknown',
       CASE s.d
         WHEN 4 THEN 'https://nebraska.edu/regents/board-members/index (the body''s own roster, read 2026-11-07). Joel Makovicka was APPOINTED by Governor Jim Pillen on 2026-02-03 to fill the vacancy left when Elizabeth O''Connor, elected to this seat in 2024, resigned after being charged over a crash that seriously injured a woman. He serves through 2027-01-07, and the 2026 contest for this district was for the unexpired remainder of O''Connor''s term. — CC_0375'
         ELSE 'https://nebraska.edu/regents/board-members/index (the body''s own roster, read 2026-11-07) — CC_0375' END
  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who;

-- ─── The races and their results ───
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT '1224487f-4f73-4048-b553-5629ee19b512'::uuid, mo.office_id, 'University of Nebraska Board of Regents' || ' District ' || s.d, NULL, 1,
       CASE s.d
         WHEN 1 THEN 'The seat held by Timothy Clare. Brent Comstock (Nonpartisan) 41,300, Jeremy Hosein (Nonpartisan) 30,987; 199 / 199 fully reported.'
         WHEN 2 THEN 'The seat held by Jack Stark. Elizabeth Butler (Nonpartisan) 46,014, Jill Wolfe (Nonpartisan) 37,910; 315 / 315 fully reported.'
         WHEN 4 THEN 'The seat held by Joel Makovicka. A special election for an unexpired term. Justin Solomon (Nonpartisan) 32,857, Susanne Shore (Nonpartisan) 20,766; 234 / 234 fully reported. A special election for the remainder of the term Elizabeth O''Connor won in 2024 and resigned in January 2026. The Secretary of State''s contest heading carries no ''Six Year Term'' label, which is how the state marks an unexpired term.'
         ELSE NULL END
  FROM seat s JOIN made_office mo ON mo.d = s.d WHERE s.race_recorded;

CREATE TEMP TABLE calls (
  d int NOT NULL, who text NOT NULL, result text NOT NULL, votes int NOT NULL,
  is_incumbent boolean NOT NULL, PRIMARY KEY (d, who)
) ON COMMIT DROP;
INSERT INTO calls VALUES
  (1, 'Brent Comstock', 'won', 41300, false),
  (1, 'Jeremy Hosein', 'lost', 30987, false),
  (2, 'Elizabeth Butler', 'won', 46014, false),
  (2, 'Jill Wolfe', 'lost', 37910, false),
  (4, 'Justin Solomon', 'won', 32857, false),
  (4, 'Susanne Shore', 'lost', 20766, false);

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM calls; IF n <> 6 THEN RAISE EXCEPTION 'expected 6 candidacies, found %', n; END IF;
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
       'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=RG&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0375',
       c.result, 'called',
       'Nebraska Secretary of State, 2026 General Election results, https://electionresults.nebraska.gov/resultsSW.aspx?type=RG&map=DIST, read 2026-11-07, all precincts fully reported. ⚠ Not yet certified by the Board of State Canvassers — CC_0375', now()
  FROM calls c JOIN made_office mo ON mo.d = c.d
  JOIN essentials.races r ON r.office_id = mo.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN person pe ON pe.who = c.who JOIN essentials.politicians pl ON pl.id = pe.pid;

-- ─── Post-verify ───
DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.d = s.d
    JOIN essentials.races r ON r.office_id = mo.office_id WHERE s.race_recorded;
  IF n <> 3 THEN RAISE EXCEPTION 'expected 3 new races, found %', n; END IF;
  SELECT count(*) INTO n FROM calls c JOIN made_office mo ON mo.d = c.d
    JOIN essentials.races r ON r.office_id = mo.office_id
    JOIN person pe ON pe.who = c.who
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = pe.pid
   WHERE rc.result = c.result AND rc.result_certainty = 'called';
  IF n <> 6 THEN RAISE EXCEPTION 'only % of the 6 candidacies hold their stated result', n; END IF;

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

  -- 🔴🔴 THE WHOLE CHAIN, FROM A POINT ON THE GROUND TO A NAMED MEMBER, for the 4 districts
  --   the canvass gives a whole county. Districts 1, 2, 4, 8 have none; see the header.
  SELECT string_agg(a.county || ' -> ' || coalesce(x.who, 'nobody') || ' (expected ' || a.member || ')', '; ') INTO txt
    FROM anchor a
    LEFT JOIN LATERAL (
      SELECT string_agg(DISTINCT pl.full_name, ', ') AS who
        FROM essentials.geofence_boundaries co
        JOIN essentials.geofence_boundaries gb
          ON gb.mtfcc = 'X-ST-BOARD' AND gb.state = '31' AND gb.geo_id LIKE 'ocd-division/country:us/state:ne/regents:%'
         AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(co.geometry))
        JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc
         AND dd.district_type = 'STATE_BOARD'
        JOIN essentials.offices o ON o.district_id = dd.id
        JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
        JOIN essentials.politicians pl ON pl.id = och.politician_id
       WHERE co.state = '31' AND co.mtfcc = 'G4020' AND co.name = a.county) x ON true
   WHERE x.who IS DISTINCT FROM a.member;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor county does not reach its member: %', txt; END IF;

  SELECT count(*) INTO n FROM made_office mo JOIN essentials.office_terms t ON t.office_id = mo.office_id
   WHERE t.term_start IS NOT NULL OR t.term_end IS NOT NULL OR t.start_precision <> 'unknown';
  IF n <> 0 THEN RAISE EXCEPTION '% term(s) claim a date this file cannot source', n; END IF;

  RAISE NOTICE 'CC_0375 OK — 8 University of Nebraska Board of Regents seats created and seated, 3 races, 6 candidacies, 14 people seeded.';
END $$;

COMMIT;
