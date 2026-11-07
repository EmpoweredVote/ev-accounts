-- CC_0372 — New Mexico's Public Education Commission: all 10 seats created and seated on the
--           HB 9 (2021) district map, and the 4 results Ballotpedia has called.
--
-- 🔴🔴 THE POLYGONS ARE NOT IN THIS FILE. 83,186 coordinate pairs across 10 districts is 2.0 MB
--   of geometry, so they are loaded by scripts/CC_0372-nm-pec-geofences.mjs, which MUST RUN
--   FIRST. This file asserts the rows are there, are the right shape, are the map HB 9
--   describes, and reach the right member.
--
-- 🔴🔴 WHICH MAP — AND THE FIRST BILL I READ WAS NOT THE LAW. The 2021 Second Special Session
--   filed two PEC redistricting bills, HB 6 and HB 7, and BOTH DIED; HB 6's action line reads
--   "Action Postponed Indefinitely". The act in force is HB 9, Laws 2021 (2nd S.S.) Chapter 3,
--   the 2021 Educational Redistricting Act, signed 17 December 2021. Its county lists are not
--   HB 6's — HB 6 would have put Torrance county in District 8, HB 9 puts the whole of it in
--   District 6. ▶ A BILL PAGE IS NOT EVIDENCE THAT A BILL BECAME LAW; READ THE ACTION LINE.
--   ⚠ Three later attempts to replace this commission with an elected state school board by
--   constitutional amendment — SJR 1 (2023), SJR 9 (2024), SJR 3 (2025) — each passed the
--   Senate and each died in the House, so no such measure reached the 2026 ballot.
--
-- 🔴 THE SERVICE IS NAD83 / UTM 13N, IN METRES. The Secretary of State's GIS reports EPSG
--   26913; outSR=4326 makes the server reproject, the parser bounds-checks all 83,186
--   coordinate pairs against New Mexico, and the loader checks each bounding box after INSERT.
--
-- 🟢 NO READ-PATH CHANGE. The Public Education Commission IS a state board of education, so
--   these rows join on the (X0003, STATE_BOARD_EDUCATION) rule already deployed for Utah's,
--   Colorado's, Texas's and Alabama's boards. The geo_id carries the state.
--
-- WHAT IT WRITES:
--   1 chamber · 10 districts · 10 offices · 10 office_terms · 4 races · 12 politicians · 5 candidacies
--
--   District  1  holder Sam S. Obenshain             anchor — none possible    
--   District  2  holder Timothy Beck                 anchor — none possible    🏆 Ken Pascoe won the seat
--   District  3  holder Jacob Trujillo               anchor — none possible    🏆 re-elected
--   District  4  holder Rebekka Burt                 anchor Los Alamos County  
--   District  5  holder Sharon E. Clahchischilliage  anchor McKinley County    🏆 re-elected
--   District  6  holder Stewart Ingham               anchor Catron County      🏆 re-elected
--   District  7  holder Patricia Gipson              anchor — none possible    ⏳ on the ballot, uncalled
--   District  8  holder Michael Taylor               anchor Colfax County      
--   District  9  holder K.T. Manis                   anchor Eddy County        
--   District 10  holder Steven Carrillo              anchor Rio Arriba County  
--
-- 🔴 AN OFFICE WITH NO office_terms ROW RAISES THE DRIFT BASELINE, so all 10 are created WITH
--   their current member seated, and the post-verify asserts the unflagged baseline is still
--   exactly 238.
--   ▶ 2027-01-01 — the winners take office. HB 9 Section 3B: members are elected "for terms
--     commencing on January 1 next succeeding their election". On that date, seat Ken Pascoe
--     in District 2; Trujillo, Clahchischilliage and Ingham were re-elected and stay.
--
-- ⚠ DISTRICT 7 IS CREATED AND SEATED BUT CARRIES NO RACE. Five districts were on the 2026
--   ballot — 2, 3, 5, 6 and 7, exactly the five HB 9 Section 3C names — and District 7 is the
--   one with no winner called: Frederick Parker (D) and John Foreman (R) ran and Ballotpedia
--   reports no result. Neither is seeded. The seat table keeps on_ballot_2026 and
--   race_recorded apart and a gate refuses a race on a seat that was not on the ballot.
--
-- 🟢🟢 THE MAP IS CHECKED AGAINST THE ACT'S OWN COUNTY COMPOSITION, STATED TWICE.
--   HB 9 names each county either whole ("Catron county;") or by precinct ("Cibola county
--   precincts 1, 7 and 15;"), which gives 23 whole counties and 10 split ones.
--   parse-nm-pec-statute.mjs reads that out of the enacted text and then CROSS-CHECKS it
--   against the Legislative Council Service's 2025 handbook page, which lists each district's
--   counties independently; they agree on all ten districts. The gate then requires each whole
--   county to lie in exactly its own district and each split county to be shared by exactly
--   the districts named. Measured against production: every whole county is 99.9992%+ inside
--   its own district with nothing over 0.01% elsewhere, and every split comes out as the act
--   says.
--   🔴 THE SPLIT FLOOR IS 0.05%, NOT THE 0.5% ALABAMA AND LOUISIANA USED. Otero county's
--     District 7 slice is a real 0.4962% of it, and at 0.5% this gate refused a correct map
--     with "Otero County -> 9, HB 9 says 7,9". A threshold carried over from another state is
--     a guess; the distribution was measured and the floor set ten times below the smallest
--     real split.
--   Also measured: the union covers 99.986% of our TIGER New Mexico outline, no two districts
--   overlap, the ten areas total 121,595 sq mi (which is New Mexico's), and all 372 New Mexico
--   ZCTAs resolve to exactly one district.
--
-- 🔴🔴 ONLY 6 OF THE 10 DISTRICTS CAN BE ANCHORED, AND THAT IS A REAL HOLE, NOT AN OVERSIGHT.
--   An anchor has to be a county the act assigns WHOLE to one district. Districts 1, 2 and 3
--   lie entirely inside Bernalillo, which HB 9 splits six ways; District 7 is made only of
--   parts of Doña Ana and Otero, both split. District 7 is still pinned by the split arm —
--   move its geometry and Bernalillo or Doña Ana stops being shared by exactly the districts
--   the act names. DISTRICTS 1, 2 AND 3 ARE NOT: a permutation of those three passes every
--   gate in this file, because all three are Bernalillo-only and the set is unchanged. The
--   controls plant that permutation deliberately and record that it passes.
--
-- IDENTITY. All 12 people are new. A sweep of all 91,758 politicians on both full name and
--   (first, last) returned nothing for any of them, including Michael Taylor and Steven
--   Carrillo. 🟢 The sweep is not blind: its positive control found Michelle Lujan Grisham.
--   ⚠ Ballotpedia and the 2025 handbook disagree on ONE seat: the handbook has District 3 as
--   Alan Lee Brauer Jr. Ballotpedia's 2026 District 3 votebox calls Jacob Trujillo the
--   incumbent, so the handbook is older there. A roster can be right about the body and out of
--   date about a seat.
--
-- 🔴 NO TERM START IS INVENTED. Neither roster publishes one, so every term is open-ended with
--   start_precision 'unknown'.
--
-- Applied to production 2026-11-07 by Chris Cantrell. Slot reserved via steward.

BEGIN;

CREATE TEMP TABLE seat (
  d int PRIMARY KEY, who text NOT NULL,
  on_ballot_2026 boolean NOT NULL, race_recorded boolean NOT NULL
) ON COMMIT DROP;
INSERT INTO seat VALUES
  (1, 'Sam S. Obenshain', false, false),
  (2, 'Timothy Beck', true, true),
  (3, 'Jacob Trujillo', true, true),
  (4, 'Rebekka Burt', false, false),
  (5, 'Sharon E. Clahchischilliage', true, true),
  (6, 'Stewart Ingham', true, true),
  (7, 'Patricia Gipson', true, false),
  (8, 'Michael Taylor', false, false),
  (9, 'K.T. Manis', false, false),
  (10, 'Steven Carrillo', false, false);

-- One county per district that HB 9 assigns WHOLE to it. Only six districts have one.
-- 🔴 THE MEMBER'S NAME IS WRITTEN OUT HERE ON PURPOSE, not read from the seat table.
CREATE TEMP TABLE anchor (d int PRIMARY KEY, county text NOT NULL, member text NOT NULL) ON COMMIT DROP;
INSERT INTO anchor VALUES
  (4, 'Los Alamos County', 'Rebekka Burt'),
  (5, 'McKinley County', 'Sharon E. Clahchischilliage'),
  (6, 'Catron County', 'Stewart Ingham'),
  (8, 'Colfax County', 'Michael Taylor'),
  (9, 'Eddy County', 'K.T. Manis'),
  (10, 'Rio Arriba County', 'Steven Carrillo');

-- HB 9's county composition, parsed from the enacted text and cross-checked against the
-- Legislative Council Service handbook. 23 whole, 10 split.
CREATE TEMP TABLE plan_whole (county text PRIMARY KEY, d int NOT NULL) ON COMMIT DROP;
INSERT INTO plan_whole VALUES
  ('Catron County', 6),
  ('Colfax County', 8),
  ('Curry County', 8),
  ('De Baca County', 8),
  ('Eddy County', 9),
  ('Grant County', 6),
  ('Guadalupe County', 8),
  ('Harding County', 8),
  ('Hidalgo County', 6),
  ('Lea County', 9),
  ('Lincoln County', 8),
  ('Los Alamos County', 4),
  ('Luna County', 6),
  ('McKinley County', 5),
  ('Mora County', 8),
  ('Quay County', 8),
  ('Rio Arriba County', 10),
  ('Roosevelt County', 8),
  ('San Miguel County', 8),
  ('Sierra County', 6),
  ('Torrance County', 6),
  ('Union County', 8),
  ('Valencia County', 6);

CREATE TEMP TABLE plan_split (county text PRIMARY KEY, ds text NOT NULL) ON COMMIT DROP;
INSERT INTO plan_split VALUES
  ('Bernalillo County', '1,2,3,4,5,6'),
  ('Chaves County', '8,9'),
  ('Cibola County', '5,6'),
  ('Doña Ana County', '6,7'),
  ('Otero County', '7,9'),
  ('San Juan County', '5,10'),
  ('Sandoval County', '4,5'),
  ('Santa Fe County', '4,10'),
  ('Socorro County', '5,6'),
  ('Taos County', '8,10');

-- ─── Pre-gates ───
DO $$ DECLARE txt text; n int; v numeric; BEGIN
  SELECT count(*) INTO n FROM seat; IF n <> 10 THEN RAISE EXCEPTION 'expected 10 seats, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE race_recorded; IF n <> 4 THEN RAISE EXCEPTION 'expected 4 races, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE on_ballot_2026; IF n <> 5 THEN RAISE EXCEPTION 'expected 5 seats on the ballot, found %', n; END IF;
  SELECT string_agg('D' || d, ', ') INTO txt FROM seat WHERE race_recorded AND NOT on_ballot_2026;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race is recorded for a seat that was not on the ballot: %', txt; END IF;
  SELECT count(*) INTO n FROM plan_whole; IF n <> 23 THEN RAISE EXCEPTION 'the plan table holds % whole counties, expected 23', n; END IF;
  SELECT count(*) INTO n FROM plan_split; IF n <> 10 THEN RAISE EXCEPTION 'the plan table holds % split counties, expected 10', n; END IF;
  SELECT count(*) INTO n FROM (SELECT county FROM plan_whole UNION SELECT county FROM plan_split) z;
  IF n <> 33 THEN RAISE EXCEPTION 'the plan table names % counties, and New Mexico has 33', n; END IF;
  SELECT string_agg(z.county, ', ') INTO txt FROM (SELECT county FROM plan_whole UNION SELECT county FROM plan_split) z
   WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries co
                      WHERE co.state = '35' AND co.mtfcc = 'G4020' AND co.name = z.county);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the plan table names counties we hold no polygon for: %', txt; END IF;

  SELECT count(*) INTO n FROM anchor; IF n <> 6 THEN RAISE EXCEPTION 'expected 6 anchors, found %', n; END IF;
  SELECT string_agg('D' || a.d || ' ' || a.county, '; ') INTO txt FROM anchor a
   WHERE NOT EXISTS (SELECT 1 FROM plan_whole w WHERE w.county = a.county AND w.d = a.d);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor county is not assigned whole to its district by HB 9: %', txt; END IF;
  -- ⚠ and the four that CANNOT be anchored must be exactly the four with no whole county
  SELECT string_agg('D' || s.d, ', ' ORDER BY s.d) INTO txt FROM seat s
   WHERE NOT EXISTS (SELECT 1 FROM anchor a WHERE a.d = s.d)
     AND EXISTS (SELECT 1 FROM plan_whole w WHERE w.d = s.d);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'these districts have a whole county and no anchor: %', txt; END IF;

  -- 🔴 the two independent statements of the roster must agree before either is used
  SELECT string_agg('D' || a.d || ': anchor says ' || a.member || ', seat says ' || s.who, '; ') INTO txt
    FROM anchor a JOIN seat s ON s.d = a.d WHERE a.member <> s.who;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the anchor table and the seat table name different members: %', txt; END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = '3e3c6584-1400-4f9d-9bfc-8438eac843dd'::uuid)
    THEN RAISE EXCEPTION 'the New Mexico government row does not exist'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.elections
                  WHERE id = '6a560b73-4059-406c-b96a-6fe27073ecc9'::uuid AND election_date = DATE '2026-11-03' AND state = 'NM')
    THEN RAISE EXCEPTION 'the election row is not the 2026-11-03 New Mexico general'; END IF;

  IF EXISTS (SELECT 1 FROM essentials.chambers WHERE name_formal = 'New Mexico Public Education Commission')
    THEN RAISE EXCEPTION 'the chamber this file creates already exists'; END IF;
  SELECT string_agg(o.title || ' (' || coalesce(d.district_type, 'no district') || ' ' || o.id || ')', '; ') INTO txt
    FROM essentials.offices o LEFT JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.representing_state = 'NM' AND o.title ILIKE '%Public Education Commission%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file would duplicate an office we already hold: %', txt; END IF;
  SELECT count(*) INTO n FROM essentials.districts WHERE district_type = 'STATE_BOARD_EDUCATION' AND lower(state) = 'nm';
  IF n <> 0 THEN RAISE EXCEPTION '% New Mexico STATE_BOARD_EDUCATION district(s) already exist', n; END IF;

  -- 🔴🔴 THE POLYGONS MUST ALREADY BE LOADED, AND BE THE RIGHT ONES.
  SELECT count(*) INTO n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0003' AND state = '35'
     AND geo_id = ANY (SELECT 'ocd-division/country:us/state:nm/pec:' || s.d FROM seat s);
  IF n <> 10 THEN RAISE EXCEPTION 'only % of the 10 New Mexico PEC polygons are loaded — run scripts/CC_0372-nm-pec-geofences.mjs first', n; END IF;

  SELECT string_agg(gb.geo_id || ' srid=' || public.ST_SRID(gb.geometry) || ' valid=' || public.ST_IsValid(gb.geometry), '; ') INTO txt
    FROM essentials.geofence_boundaries gb WHERE gb.mtfcc = 'X0003' AND gb.state = '35'
     AND (public.ST_SRID(gb.geometry) <> 4326 OR NOT public.ST_IsValid(gb.geometry) OR public.ST_IsEmpty(gb.geometry)
          OR public.ST_XMin(gb.geometry) < -110 OR public.ST_XMax(gb.geometry) > -102
          OR public.ST_YMin(gb.geometry) < 30.5 OR public.ST_YMax(gb.geometry) > 37.5);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a loaded polygon is not a valid 4326 New Mexico polygon: %', txt; END IF;

  -- The union must reproduce our own TIGER New Mexico outline. The loader measured 99.986% on
  -- the geodesic area. ⚠ NO ::geography CAST HERE or below — ev-cto decision 0006.
  SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g))
                     / public.ST_Area(s.g) * 100)::numeric, 3) INTO v
    FROM (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries WHERE mtfcc='X0003' AND state='35') u,
         (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='35') s;
  IF v < 99.5 THEN RAISE EXCEPTION 'the 10 districts cover only %%% of the New Mexico outline', v; END IF;

  -- 🟢🟢 THE STATUTE GATE.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.county || ' is only ' ||
           round((public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
                  / public.ST_Area(co.geometry) * 100)::numeric, 4) || '% in D' || w.d AS msg
      FROM plan_whole w
      JOIN essentials.geofence_boundaries co ON co.state='35' AND co.mtfcc='G4020' AND co.name=w.county
      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X0003' AND gb.state='35'
       AND gb.geo_id = 'ocd-division/country:us/state:nm/pec:' || w.d::text
     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
           < public.ST_Area(co.geometry) * 0.999) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'HB 9 puts these counties wholly in one district and the map does not: %', txt; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.county || ' (HB 9 D' || w.d || ') also reaches D' || replace(gb.geo_id, 'ocd-division/country:us/state:nm/pec:', '') AS msg
      FROM plan_whole w
      JOIN essentials.geofence_boundaries co ON co.state='35' AND co.mtfcc='G4020' AND co.name=w.county
      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X0003' AND gb.state='35'
       AND gb.geo_id <> 'ocd-division/country:us/state:nm/pec:' || w.d::text
     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
           > public.ST_Area(co.geometry) * 0.0001) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a county HB 9 assigns whole reaches into another district: %', txt; END IF;

  -- ⚠ the split floor is 0.05%, measured: Otero's District 7 slice is a real 0.4962%
  SELECT string_agg(z.county || ' -> ' || coalesce(z.got, 'nothing') || ', HB 9 says ' || z.ds, '; ') INTO txt FROM (
    SELECT sp.county, sp.ds,
           (SELECT string_agg(replace(gb.geo_id, 'ocd-division/country:us/state:nm/pec:', ''), ',' ORDER BY (replace(gb.geo_id, 'ocd-division/country:us/state:nm/pec:', ''))::int)
              FROM essentials.geofence_boundaries gb
             WHERE gb.mtfcc='X0003' AND gb.state='35'
               AND public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
                   > public.ST_Area(co.geometry) * 0.0005) AS got
      FROM plan_split sp
      JOIN essentials.geofence_boundaries co ON co.state='35' AND co.mtfcc='G4020' AND co.name=sp.county) z
   WHERE z.got IS DISTINCT FROM z.ds;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a county HB 9 splits is shared with the wrong districts: %', txt; END IF;

  SELECT count(*) INTO n FROM (
    SELECT (SELECT count(*) FROM essentials.geofence_boundaries s
             WHERE s.mtfcc='X0003' AND s.state='35'
               AND public.ST_Covers(s.geometry, public.ST_PointOnSurface(z.geometry))) k
      FROM essentials.geofence_boundaries z WHERE z.state='35' AND z.mtfcc='G6350') y WHERE y.k <> 1;
  IF n <> 0 THEN RAISE EXCEPTION '% New Mexico ZCTA(s) do not resolve to exactly one PEC district', n; END IF;
END $$;

-- ─── Chamber, districts, offices ───
CREATE TEMP TABLE made_chamber (chamber_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.chambers (name, name_formal, government_id, policy_engagement_level,
                                   official_count, term_length, staggered_term, website_url,
                                   inauguration_rules, election_rules, remarks)
  VALUES ('Public Education Commission', 'New Mexico Public Education Commission', '3e3c6584-1400-4f9d-9bfc-8438eac843dd'::uuid, 'full', 10, '4 years', true, 'https://ballotpedia.org/New_Mexico_Public_Education_Commission',
          'HB 9 (Laws 2021 2nd S.S. Ch. 3) Section 3B: members are elected at the general election ''for terms commencing on January 1 next succeeding their election'', so the 2026 winners take office on 2027-01-01.',
          'Staggered four-year terms. Districts 2, 3, 5, 6 and 7 were on the 2026 ballot; districts 1, 4, 8, 9 and 10 are next up in 2028. A commissioner must reside in their district and is deemed to have resigned on moving out of it (HB 9 Section 4).',
          'Ten members, one per district, elected to staggered four-year terms. HB 9 Section 3 sets the stagger by district number: 2, 3, 5, 6 and 7 are elected in 2022 and every four years after; 1, 4, 8, 9 and 10 in 2024 and every four years after. Established by Article XII, Section 6 of the New Mexico Constitution.')
  RETURNING id)
INSERT INTO made_chamber SELECT id FROM ins;

CREATE TEMP TABLE made_district (d int PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)
  SELECT 'STATE_BOARD_EDUCATION', 'nm',
         'ocd-division/country:us/state:nm/pec:' || s.d, 'ocd-division/country:us/state:nm/pec:' || s.d,
         'New Mexico Public Education Commission' || ' District ' || s.d, 'X0003', s.d::text, 'residency'
    FROM seat s RETURNING id, geo_id)
INSERT INTO made_district
SELECT replace(ins.geo_id, 'ocd-division/country:us/state:nm/pec:', '')::int, ins.id FROM ins;

CREATE TEMP TABLE made_office (d int PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, voting_powers,
                                  is_vacant, faces_retention_vote, is_appointed_position, description)
  SELECT 'Public Education Commissioner, District ' || s.d, mc.chamber_id, md.district_id, 'NM', 'full',
         false, false, false, 'seat:' || s.d
    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc
  RETURNING id, description)
INSERT INTO made_office SELECT replace(ins.description, 'seat:', '')::int, ins.id FROM ins;
UPDATE essentials.offices o SET description = NULL FROM made_office mo WHERE o.id = mo.office_id;

DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM made_district; IF n <> 10 THEN RAISE EXCEPTION 'only % districts were created', n; END IF;
  SELECT count(*) INTO n FROM made_office;   IF n <> 10 THEN RAISE EXCEPTION 'only % offices were created', n; END IF;
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id WHERE o.description IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% office(s) kept the seat key in description', n; END IF;
  SELECT count(*) INTO n FROM made_district md JOIN essentials.districts d ON d.id = md.district_id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc;
  IF n <> 10 THEN RAISE EXCEPTION 'only % of the 10 districts meet a geofence row on (geo_id, mtfcc)', n; END IF;
END $$;

-- ─── The people ───
CREATE TEMP TABLE seed_people (
  full_name text PRIMARY KEY, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people VALUES
  ('Sam S. Obenshain', 'Sam S.', 'Obenshain',
   'https://ballotpedia.org/Sam_Obenshain (Ballotpedia, fetched and checked 2026-11-07); CC_0372'),
  ('Timothy Beck', 'Timothy', 'Beck',
   'https://ballotpedia.org/Timothy_Beck (Ballotpedia, fetched and checked 2026-11-07); CC_0372'),
  ('Ken Pascoe', 'Ken', 'Pascoe',
   'https://ballotpedia.org/Ken_Pascoe (Ballotpedia, fetched and checked 2026-11-07); CC_0372'),
  ('Jacob Trujillo', 'Jacob', 'Trujillo',
   'https://ballotpedia.org/Jacob_Trujillo (Ballotpedia, fetched and checked 2026-11-07); CC_0372'),
  ('Dennis Dinge', 'Dennis', 'Dinge',
   'https://ballotpedia.org/Dennis_Dinge (Ballotpedia, fetched and checked 2026-11-07); CC_0372'),
  ('Rebekka Burt', 'Rebekka', 'Burt',
   'https://ballotpedia.org/Rebekka_Burt (Ballotpedia, fetched and checked 2026-11-07); CC_0372'),
  ('Sharon E. Clahchischilliage', 'Sharon E.', 'Clahchischilliage',
   'https://ballotpedia.org/Sharon_E._Clahchischilliage (Ballotpedia, fetched and checked 2026-11-07); CC_0372'),
  ('Stewart Ingham', 'Stewart', 'Ingham',
   'https://ballotpedia.org/Stewart_Ingham (Ballotpedia, fetched and checked 2026-11-07); CC_0372'),
  ('Patricia Gipson', 'Patricia', 'Gipson',
   'https://ballotpedia.org/Patricia_Gipson (Ballotpedia, fetched and checked 2026-11-07); CC_0372'),
  ('Michael Taylor', 'Michael', 'Taylor',
   'https://ballotpedia.org/Michael_Taylor_(New_Mexico) (Ballotpedia, fetched and checked 2026-11-07); CC_0372'),
  ('K.T. Manis', 'K.T.', 'Manis',
   'https://ballotpedia.org/K.T._Manis (Ballotpedia, fetched and checked 2026-11-07); CC_0372'),
  ('Steven Carrillo', 'Steven', 'Carrillo',
   'https://ballotpedia.org/Steven_Carrillo (Ballotpedia, fetched and checked 2026-11-07); CC_0372');

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
  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Michelle Lujan Grisham');
  IF n < 1 THEN RAISE EXCEPTION 'the name index cannot see a politician known to exist'; END IF;
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

  SELECT count(*) INTO n FROM allowed_name_collisions a JOIN seed_people s ON s.full_name = a.full_name
   WHERE NOT EXISTS (SELECT 1 FROM pol_keys p WHERE p.source IS DISTINCT FROM s.source
                       AND (p.k_full = pg_temp.namekey(s.full_name)
                         OR (p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name))));
  IF n <> 0 THEN RAISE EXCEPTION '% allowed collision(s) no longer collide', n; END IF;

  SELECT string_agg(s.full_name || ' splits to (' || s.first_name || ', ' || s.last_name || ')', '; ') INTO txt
    FROM seed_people s WHERE s.full_name <> s.first_name || ' ' || s.last_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded name does not match its own split: %', txt; END IF;
  SELECT string_agg(s.full_name || ' -> ' || s.source, '; ') INTO txt FROM seed_people s
   WHERE s.source NOT LIKE 'https://ballotpedia.org/%' OR s.source LIKE '%#%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded source is not a plain Ballotpedia page: %', txt; END IF;
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
  IF n <> 12 THEN RAISE EXCEPTION 'only % of the 12 people resolved to exactly one row', n; END IF; END $$;

-- ─── Seat every current member ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT mo.office_id, pe.pid, NULL, NULL, 'unknown', 'unknown',
       'https://ballotpedia.org/New_Mexico_Public_Education_Commission' || ' (Ballotpedia''s officeholder table for the commission, read 2026-11-07) — CC_0372'
  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who;

-- ─── The races and their results ───
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT '6a560b73-4059-406c-b96a-6fe27073ecc9'::uuid, mo.office_id, 'New Mexico Public Education Commission' || ' District ' || s.d, NULL, 1,
       'The seat held by ' || s.who || '.'
  FROM seat s JOIN made_office mo ON mo.d = s.d WHERE s.race_recorded;

CREATE TEMP TABLE calls (
  d int NOT NULL, who text NOT NULL, result text NOT NULL, is_write_in boolean NOT NULL,
  is_incumbent boolean NOT NULL, PRIMARY KEY (d, who)
) ON COMMIT DROP;
INSERT INTO calls VALUES
  (2, 'Ken Pascoe', 'won', false, false),
  (3, 'Jacob Trujillo', 'won', false, true),
  (3, 'Dennis Dinge', 'lost', false, false),
  (5, 'Sharon E. Clahchischilliage', 'won', false, true),
  (6, 'Stewart Ingham', 'won', false, true);

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM calls; IF n <> 5 THEN RAISE EXCEPTION 'expected 5 candidacies, found %', n; END IF;
  SELECT string_agg('D' || z.d || ': ' || z.w || ' winner(s)', '; ') INTO txt FROM (
    SELECT c.d, count(*) FILTER (WHERE c.result = 'won') w FROM calls c GROUP BY c.d) z WHERE z.w <> 1;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a single-seat race does not hold exactly one winner: %', txt; END IF;
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
SELECT r.id, pl.id, pl.full_name, pl.first_name, pl.last_name, c.is_incumbent, 'active', c.is_write_in,
       'Ballotpedia, "New Mexico Public Education Commission election, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0372',
       c.result, 'called',
       'Ballotpedia, "New Mexico Public Education Commission election, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0372', now()
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
   WHERE rc.result = c.result AND rc.result_certainty = 'called' AND rc.is_write_in = c.is_write_in;
  IF n <> 5 THEN RAISE EXCEPTION 'only % of the 5 candidacies hold their stated result', n; END IF;

  -- 🔴🔴 EVERY NEW OFFICE IS SEATED AND THE DRIFT BASELINE HAS NOT MOVED
  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 10 offices have no term and would raise the drift metric', n; END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;
  IF n <> 238 THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — it was 238 and must never be raised', n; END IF;

  SELECT count(*) INTO n FROM made_chamber mc JOIN essentials.offices o ON o.chamber_id = mc.chamber_id;
  IF n <> 10 THEN RAISE EXCEPTION 'the chamber holds % offices, not 10', n; END IF;
  SELECT official_count INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id;
  IF n <> 10 THEN RAISE EXCEPTION 'official_count is %, not 10', n; END IF;
  SELECT count(*) INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id
   WHERE ch.inauguration_rules ILIKE '%2027-01-01%' AND ch.election_rules ILIKE '%2028%';
  IF n <> 1 THEN RAISE EXCEPTION 'the chamber does not record the 2027-01-01 handover and the 2028 half of the stagger'; END IF;

  -- 🔴🔴 THE WHOLE CHAIN, FROM A POINT ON THE GROUND TO A NAMED MEMBER, for the six districts
  --   that HB 9 gives a whole county. Districts 1, 2, 3 and 7 have none; see the header.
  SELECT string_agg(a.county || ' -> ' || coalesce(x.who, 'nobody') || ' (expected ' || a.member || ')', '; ') INTO txt
    FROM anchor a
    LEFT JOIN LATERAL (
      SELECT string_agg(DISTINCT pl.full_name, ', ') AS who
        FROM essentials.geofence_boundaries co
        JOIN essentials.geofence_boundaries gb
          ON gb.mtfcc = 'X0003' AND gb.state = '35'
         AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(co.geometry))
        JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc
         AND dd.district_type = 'STATE_BOARD_EDUCATION'
        JOIN essentials.offices o ON o.district_id = dd.id
        JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
        JOIN essentials.politicians pl ON pl.id = och.politician_id
       WHERE co.state = '35' AND co.mtfcc = 'G4020' AND co.name = a.county) x ON true
   WHERE x.who IS DISTINCT FROM a.member;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor county does not reach its commissioner: %', txt; END IF;

  SELECT count(*) INTO n FROM made_office mo JOIN essentials.office_terms t ON t.office_id = mo.office_id
   WHERE t.term_start IS NOT NULL OR t.term_end IS NOT NULL OR t.start_precision <> 'unknown';
  IF n <> 0 THEN RAISE EXCEPTION '% term(s) claim a date this file cannot source', n; END IF;

  RAISE NOTICE 'CC_0372 OK — 10 New Mexico PEC seats created and seated, 4 races, 5 candidacies, 12 people seeded.';
END $$;

COMMIT;
