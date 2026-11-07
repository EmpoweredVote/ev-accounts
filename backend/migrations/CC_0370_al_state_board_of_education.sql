-- CC_0370 — Alabama's State Board of Education: all 8 seats created and seated on the 2021
--           district map, and the 4 results Ballotpedia has called.
--
-- 🔴🔴 THE POLYGONS ARE NOT IN THIS FILE. 71,244 coordinate pairs across 8 districts is
--   1.8 MB of geometry, so they are loaded by scripts/CC_0370-al-sboe-geofences.mjs, which
--   MUST RUN FIRST — the same split CC_0369 used for Texas and CA_0205 for California's
--   Board of Equalization. This file asserts the rows are there, are the right shape, are
--   the map the STATUTE describes, and reach the right member.
--
-- 🔴🔴 THE SERVICE THIS MAP COMES FROM IS WEB MERCATOR. The Alabama Legislative
--   Reapportionment Office's ArcGIS layer _2021_Alabama_State_Bd_of_Education reports
--   {wkid: 102100, latestWkid: 3857} and an extent in metres. Taken as served and labelled
--   4326 those numbers are valid, correctly shaped polygons that match no address on Earth —
--   the Holladay failure. The fetch asks for outSR=4326, the parser bounds-checks all 71,244
--   coordinate pairs against Alabama, and the loader checks each bounding box again after
--   INSERT. A control that reprojects the real data back to metres is refused on District 1.
--
-- WHICH MAP. The 2021 plan, enacted in the 2021 First Special Session as the "McClendon SBOE
--   Plan 1" and codified whole as Code of Alabama § 16-3-1.1. Alabama redistricts only in the
--   first session after each decennial census (Const. 1901, Art. IX §§ 197-200); the 2023
--   remedial litigation redrew the CONGRESSIONAL map and, separately, state Senate districts,
--   and left this one alone. It took effect for the 2022 board elections and governed the
--   2026 ones. ⚠ The Legislature's own /reapportionment-board-education-state-map page is
--   STALE — it still offers "Board of Education State Map: 2011 State Education Districts".
--   🟢 The layer identifies itself: its eight populations sum to 5,024,279, Alabama's 2020
--   apportionment population to the person, and its ideal district is that over eight.
--
-- 🟢 NO READ-PATH CHANGE. districtQueries.ts and geoIdGuard.ts already admit
--   (X0003, STATE_BOARD_EDUCATION) for Utah's, Colorado's and Texas's boards and the rule is
--   NOT state-scoped, so Alabama's rows join as they are. The geo_id carries the state.
--
-- WHAT IT WRITES:
--   1 chamber · 8 districts · 8 offices · 8 office_terms · 4 races · 13 politicians · 7 candidacies
--
--   District 1  holder Jackie Zeigler        anchor Baldwin County    
--   District 2  holder Tracie West           anchor Houston County    🏆 re-elected
--   District 3  holder Kelly Mooney          anchor Shelby County     
--   District 4  holder Yvette Richardson     anchor Greene County     🏆 re-elected
--   District 5  holder Tonya Smith Chestnut  anchor Dallas County     
--   District 6  holder Marie Manning         anchor Calhoun County    🏆 Cathi Bradford won the seat
--   District 7  holder Allen Long            anchor Lauderdale County 
--   District 8  holder Wayne Reynolds        anchor Madison County    🏆 Emily Jones won the seat
--
-- 🔴 AN OFFICE WITH NO office_terms ROW RAISES THE DRIFT BASELINE, so all 8 are created WITH
--   their current member seated from the board's own roster, and the post-verify asserts the
--   unflagged baseline is still exactly 238.
--   ⚠ THE HOLDER IS NOT THE WINNER IN TWO OF THE FOUR. Tracie West and Yvette Richardson were
--   re-elected. Marie Manning (D6) and Wayne Reynolds (D8) are the sitting members and were
--   not on the November ballot; Cathi Bradford and Emily Jones won those seats.
--   ▶ 2027-01-18 — the winners take office. Code of Alabama § 16-3-1: a member holds office
--     "from the first Monday after the second Tuesday in January next after" the election.
--     In January 2027 the second Tuesday is the 12th, so the first Monday after it is the
--     18th. On that date, seat Bradford in District 6 and Jones in District 8.
--
-- ⚠ THE BOARD HAS NINE MEMBERS AND THIS FILE CREATES EIGHT OFFICES. The ninth is the Governor
--   of Alabama, who is the board's president ex officio (§ 16-3-1). That is a power of the
--   Governor's office, which production already holds, and not a seat of its own, so no row
--   is created for it. official_count is 9 and the office count is 8; the post-verify asserts
--   both, so the gap is a recorded decision and not something to rediscover.
--
-- 🟢🟢 THE MAP IS CHECKED AGAINST THE STATUTE ITSELF, NOT JUST AGAINST OTHER GEOMETRY.
--   § 16-3-1.1 lists each district as a set of whole counties plus the tracts and blocks of
--   the counties it splits. 62 of Alabama's 67 counties are assigned whole and 5 are split.
--   The loader and this file both assert: each of the 62 is at least 99.9% inside the one
--   district the statute names and at most 0.01% in any other, and each of the 5 is shared by
--   EXACTLY the districts the statute names. Measured against production, the worst whole
--   county is 99.9966% in its own district and the largest stray sliver is 0.0034%, so the
--   thresholds sit about 30x clear of the data. The splits come out Mobile 1/5, Jefferson
--   3/4/7, Montgomery 3/5, Talladega 3/6, Tuscaloosa 4/7 — which also settles the one
--   ambiguity in the published bill text, where District 5's county list reads "Mo County".
--   ▶ THIS IS THE ONLY CHECK THAT CAN SEE TWO DISTRICTS' GEOMETRIES SWAPPED. A label swap
--     passes the coverage test, the overlap test and the ZCTA test — CC_0369's control C.
--   Also measured: the union covers 99.939% of our TIGER Alabama outline, no two districts
--   overlap at all, the eight areas total 52,420 sq mi (which is Alabama's), and all 656
--   Alabama ZCTAs resolve to exactly one district.
--   ⚠ Alabama has NO incorporated places (G4110) in production, so the place-resolution gate
--     Texas used does not exist here. Counties are the better test anyway: they tile the
--     state exactly and the statute speaks in them.
--
-- IDENTITY. All 13 people are new. A sweep of all 91,735 politicians on both full name and
--   (first, last) returned nothing for any of them — including Emily Jones, Angela Morgan and
--   Allen Long, which is why it was run. 🟢 The sweep is not blind: its positive control found
--   Tommy Tuberville.
--
-- 🔴 EVERY SOURCE URL WAS FETCHED AND READ, NOT COMPOSED FROM THE NAME. /Allen_Long returns
--   HTTP 200, contains the words "Allen Long", and is a DISAMBIGUATION page listing two
--   different men; his page is /Allen_Long_(Alabama). Emily Jones's is /Emily_Jones_(Alabama).
--   resolve-al-sboe.mjs asserts of every one of the 13 that it names the person, mentions the
--   Alabama State Board of Education, and is not a disambiguation page.
--
-- 🔴 NO TERM START IS INVENTED. Neither roster publishes one, so every term is open-ended
--   with start_precision 'unknown'.
--
-- Applied to production 2026-11-07 by Chris Cantrell. Slot reserved via steward.

BEGIN;

CREATE TEMP TABLE seat (
  d int PRIMARY KEY, who text NOT NULL,
  on_ballot_2026 boolean NOT NULL, race_recorded boolean NOT NULL
) ON COMMIT DROP;
INSERT INTO seat VALUES
  (1, 'Jackie Zeigler', false, false),
  (2, 'Tracie West', true, true),
  (3, 'Kelly Mooney', false, false),
  (4, 'Yvette Richardson', true, true),
  (5, 'Tonya Smith Chestnut', false, false),
  (6, 'Marie Manning', true, true),
  (7, 'Allen Long', false, false),
  (8, 'Wayne Reynolds', true, true);

-- One county per district that § 16-3-1.1 assigns WHOLE to it. The anchor is therefore a
-- statement of the law, made before this GIS file existed.
-- 🔴 THE MEMBER'S NAME IS WRITTEN OUT HERE ON PURPOSE, not read from the seat table. A control
--   that put two members in each other's seat PASSED against the first version of CC_0369's
--   equivalent gate, because the chain resolved the holder the seat table had just seated and
--   then compared it with that same seat table — the gate was asking the data to agree with
--   itself. Two independent statements of the roster, and a gate that they match, is the fix.
CREATE TEMP TABLE anchor (d int PRIMARY KEY, county text NOT NULL, member text NOT NULL) ON COMMIT DROP;
INSERT INTO anchor VALUES
  (1, 'Baldwin County', 'Jackie Zeigler'),
  (2, 'Houston County', 'Tracie West'),
  (3, 'Shelby County', 'Kelly Mooney'),
  (4, 'Greene County', 'Yvette Richardson'),
  (5, 'Dallas County', 'Tonya Smith Chestnut'),
  (6, 'Calhoun County', 'Marie Manning'),
  (7, 'Lauderdale County', 'Allen Long'),
  (8, 'Madison County', 'Wayne Reynolds');

-- Code of Alabama § 16-3-1.1, transcribed from the Legislature's own bill text
-- (2021_Alabama_State_Bd_of_Education_Bill_Text.pdf, sha256 a227996ae40943a8fca4fe33b99adb67a
--  734993955b3690be9ba5a4c44b38ab9). 62 counties assigned whole, 5 split.
CREATE TEMP TABLE statute_whole (county text PRIMARY KEY, d int NOT NULL) ON COMMIT DROP;
INSERT INTO statute_whole VALUES
  ('Baldwin County', 1),
  ('Butler County', 1),
  ('Coffee County', 1),
  ('Conecuh County', 1),
  ('Covington County', 1),
  ('Crenshaw County', 1),
  ('Escambia County', 1),
  ('Barbour County', 2),
  ('Chambers County', 2),
  ('Clay County', 2),
  ('Cleburne County', 2),
  ('Dale County', 2),
  ('Geneva County', 2),
  ('Henry County', 2),
  ('Houston County', 2),
  ('Lee County', 2),
  ('Pike County', 2),
  ('Randolph County', 2),
  ('Russell County', 2),
  ('Tallapoosa County', 2),
  ('Bibb County', 3),
  ('Chilton County', 3),
  ('Coosa County', 3),
  ('Elmore County', 3),
  ('Shelby County', 3),
  ('Greene County', 4),
  ('Hale County', 4),
  ('Pickens County', 4),
  ('Autauga County', 5),
  ('Bullock County', 5),
  ('Choctaw County', 5),
  ('Clarke County', 5),
  ('Dallas County', 5),
  ('Lowndes County', 5),
  ('Macon County', 5),
  ('Marengo County', 5),
  ('Monroe County', 5),
  ('Perry County', 5),
  ('Sumter County', 5),
  ('Washington County', 5),
  ('Wilcox County', 5),
  ('Blount County', 6),
  ('Calhoun County', 6),
  ('Cherokee County', 6),
  ('Cullman County', 6),
  ('Etowah County', 6),
  ('Marshall County', 6),
  ('St. Clair County', 6),
  ('Colbert County', 7),
  ('Fayette County', 7),
  ('Franklin County', 7),
  ('Lamar County', 7),
  ('Lauderdale County', 7),
  ('Lawrence County', 7),
  ('Marion County', 7),
  ('Morgan County', 7),
  ('Walker County', 7),
  ('Winston County', 7),
  ('DeKalb County', 8),
  ('Jackson County', 8),
  ('Limestone County', 8),
  ('Madison County', 8);

CREATE TEMP TABLE statute_split (county text PRIMARY KEY, ds text NOT NULL) ON COMMIT DROP;
INSERT INTO statute_split VALUES
  ('Mobile County', '1,5'),
  ('Jefferson County', '3,4,7'),
  ('Montgomery County', '3,5'),
  ('Talladega County', '3,6'),
  ('Tuscaloosa County', '4,7');

-- ─── Pre-gates ───
DO $$ DECLARE txt text; n int; v numeric; BEGIN
  SELECT count(*) INTO n FROM seat; IF n <> 8 THEN RAISE EXCEPTION 'expected 8 seats, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE race_recorded; IF n <> 4 THEN RAISE EXCEPTION 'expected 4 races, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE on_ballot_2026; IF n <> 4 THEN RAISE EXCEPTION 'expected 4 seats on the ballot, found %', n; END IF;
  SELECT string_agg('D' || d, ', ') INTO txt FROM seat WHERE race_recorded AND NOT on_ballot_2026;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race is recorded for a seat that was not on the ballot: %', txt; END IF;
  SELECT count(*) INTO n FROM statute_whole; IF n <> 62 THEN RAISE EXCEPTION 'the statute table holds % whole counties, expected 62', n; END IF;
  SELECT count(*) INTO n FROM statute_split; IF n <> 5 THEN RAISE EXCEPTION 'the statute table holds % split counties, expected 5', n; END IF;
  SELECT count(*) INTO n FROM (SELECT county FROM statute_whole UNION SELECT county FROM statute_split) z;
  IF n <> 67 THEN RAISE EXCEPTION 'the statute table names % counties, and Alabama has 67', n; END IF;
  SELECT string_agg(z.county, ', ') INTO txt FROM (SELECT county FROM statute_whole UNION SELECT county FROM statute_split) z
   WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries co
                      WHERE co.state = '01' AND co.mtfcc = 'G4020' AND co.name = z.county);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the statute table names counties we hold no polygon for: %', txt; END IF;

  -- every anchor must be a county the statute assigns WHOLE to that district
  SELECT string_agg('D' || a.d || ' ' || a.county, '; ') INTO txt FROM anchor a
   WHERE NOT EXISTS (SELECT 1 FROM statute_whole w WHERE w.county = a.county AND w.d = a.d);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor county is not assigned whole to its district by the statute: %', txt; END IF;

  -- 🔴 the two independent statements of the roster must agree before either is used
  SELECT string_agg('D' || a.d || ': anchor says ' || a.member || ', seat says ' || s.who, '; ') INTO txt
    FROM anchor a JOIN seat s ON s.d = a.d WHERE a.member <> s.who;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the anchor table and the seat table name different members: %', txt; END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = 'f427572f-d37a-4828-b68b-7f2c4e6ee4cd'::uuid)
    THEN RAISE EXCEPTION 'the Alabama government row does not exist'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.elections
                  WHERE id = '4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid AND election_date = DATE '2026-11-03' AND state = 'AL')
    THEN RAISE EXCEPTION 'the election row is not the 2026-11-03 Alabama general'; END IF;

  -- nothing this file creates may already exist
  IF EXISTS (SELECT 1 FROM essentials.chambers WHERE name_formal = 'Alabama State Board of Education')
    THEN RAISE EXCEPTION 'the chamber this file creates already exists'; END IF;
  SELECT string_agg(o.title || ' (' || coalesce(d.district_type, 'no district') || ' ' || o.id || ')', '; ') INTO txt
    FROM essentials.offices o LEFT JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.representing_state = 'AL' AND o.title ILIKE '%State Board of Education%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file would duplicate an office we already hold: %', txt; END IF;
  SELECT count(*) INTO n FROM essentials.districts WHERE district_type = 'STATE_BOARD_EDUCATION' AND lower(state) = 'al';
  IF n <> 0 THEN RAISE EXCEPTION '% Alabama STATE_BOARD_EDUCATION district(s) already exist', n; END IF;

  -- 🔴🔴 THE POLYGONS MUST ALREADY BE LOADED, AND BE THE RIGHT ONES. This file is useless
  --   without scripts/CC_0370-al-sboe-geofences.mjs having run first.
  SELECT count(*) INTO n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0003' AND state = '01'
     AND geo_id = ANY (SELECT 'ocd-division/country:us/state:al/sboe:' || s.d FROM seat s);
  IF n <> 8 THEN RAISE EXCEPTION 'only % of the 8 Alabama SBOE polygons are loaded — run scripts/CC_0370-al-sboe-geofences.mjs first', n; END IF;

  SELECT string_agg(gb.geo_id || ' srid=' || public.ST_SRID(gb.geometry) || ' valid=' || public.ST_IsValid(gb.geometry), '; ') INTO txt
    FROM essentials.geofence_boundaries gb WHERE gb.mtfcc = 'X0003' AND gb.state = '01'
     AND (public.ST_SRID(gb.geometry) <> 4326 OR NOT public.ST_IsValid(gb.geometry) OR public.ST_IsEmpty(gb.geometry)
          OR public.ST_XMin(gb.geometry) < -89 OR public.ST_XMax(gb.geometry) > -84.5
          OR public.ST_YMin(gb.geometry) < 29.5 OR public.ST_YMax(gb.geometry) > 35.5);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a loaded polygon is not a valid 4326 Alabama polygon: %', txt; END IF;

  -- The union must reproduce our own TIGER Alabama outline. Independent geometry; the loader
  -- measured 99.939% on the geodesic area.
  -- ⚠ NO ::geography CAST HERE, in this gate or any below. A geography cast reads
  --   public.spatial_ref_sys, which anon can write, and check-postgis-spatial-ref-guard.mjs
  --   refuses it in any migration — ev-cto decision 0006, an accepted risk this file will not
  --   re-open. Every area below is planar and every test is a RATIO over the same patch of
  --   Alabama, so the projection distortion cancels.
  SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g))
                     / public.ST_Area(s.g) * 100)::numeric, 3) INTO v
    FROM (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries WHERE mtfcc='X0003' AND state='01') u,
         (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='01') s;
  IF v < 99.5 THEN RAISE EXCEPTION 'the 8 districts cover only %%% of the Alabama outline', v; END IF;

  -- 🟢🟢 THE STATUTE GATE. The only thing here that can catch two districts' geometries being
  --   swapped, because it brings in evidence from outside the map.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.county || ' is only ' ||
           round((public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
                  / public.ST_Area(co.geometry) * 100)::numeric, 4) || '% in D' || w.d AS msg
      FROM statute_whole w
      JOIN essentials.geofence_boundaries co ON co.state='01' AND co.mtfcc='G4020' AND co.name=w.county
      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X0003' AND gb.state='01'
       AND gb.geo_id = 'ocd-division/country:us/state:al/sboe:' || w.d::text
     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
           < public.ST_Area(co.geometry) * 0.999) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the statute puts these counties wholly in one district and the map does not: %', txt; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.county || ' (statute D' || w.d || ') also reaches D' || replace(gb.geo_id, 'ocd-division/country:us/state:al/sboe:', '') AS msg
      FROM statute_whole w
      JOIN essentials.geofence_boundaries co ON co.state='01' AND co.mtfcc='G4020' AND co.name=w.county
      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X0003' AND gb.state='01'
       AND gb.geo_id <> 'ocd-division/country:us/state:al/sboe:' || w.d::text
     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
           > public.ST_Area(co.geometry) * 0.0001) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a county the statute assigns whole reaches into another district: %', txt; END IF;

  SELECT string_agg(z.county || ' -> ' || coalesce(z.got, 'nothing') || ', statute says ' || z.ds, '; ') INTO txt FROM (
    SELECT sp.county, sp.ds,
           (SELECT string_agg(replace(gb.geo_id, 'ocd-division/country:us/state:al/sboe:', ''), ',' ORDER BY gb.geo_id)
              FROM essentials.geofence_boundaries gb
             WHERE gb.mtfcc='X0003' AND gb.state='01'
               AND public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
                   > public.ST_Area(co.geometry) * 0.005) AS got
      FROM statute_split sp
      JOIN essentials.geofence_boundaries co ON co.state='01' AND co.mtfcc='G4020' AND co.name=sp.county) z
   WHERE z.got IS DISTINCT FROM z.ds;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a county the statute splits is shared with the wrong districts: %', txt; END IF;

  -- and every Alabama ZCTA must land in exactly one of them
  SELECT count(*) INTO n FROM (
    SELECT (SELECT count(*) FROM essentials.geofence_boundaries s
             WHERE s.mtfcc='X0003' AND s.state='01'
               AND public.ST_Covers(s.geometry, public.ST_PointOnSurface(z.geometry))) k
      FROM essentials.geofence_boundaries z WHERE z.state='01' AND z.mtfcc='G6350') y WHERE y.k <> 1;
  IF n <> 0 THEN RAISE EXCEPTION '% Alabama ZCTA(s) do not resolve to exactly one SBOE district', n; END IF;
END $$;

-- ─── Chamber, districts, offices ───
CREATE TEMP TABLE made_chamber (chamber_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.chambers (name, name_formal, government_id, policy_engagement_level,
                                   official_count, term_length, staggered_term, website_url,
                                   inauguration_rules, election_rules, remarks)
  VALUES ('State Board of Education', 'Alabama State Board of Education', 'f427572f-d37a-4828-b68b-7f2c4e6ee4cd'::uuid, 'full', 9, '4 years', true, 'https://www.alabamaachieves.org/state-board-of-education/',
          'Code of Alabama § 16-3-1: a member holds office from the first Monday after the second Tuesday in January next after their election. For the 2026 winners that is 2027-01-18.',
          'Four-year terms, staggered: districts 2, 4, 6 and 8 are elected in midterm years and districts 1, 3, 5 and 7 in presidential years. Members must be eligible voters living in the district they represent (§ 16-3-3).',
          'Nine members. The Governor of Alabama is the ninth, ex officio, and is the board''s president (Code of Alabama § 16-3-1); that is a power of the Governor''s office and not a seat of its own, so this chamber holds the eight elected district seats and no row is created for it.')
  RETURNING id)
INSERT INTO made_chamber SELECT id FROM ins;

CREATE TEMP TABLE made_district (d int PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)
  SELECT 'STATE_BOARD_EDUCATION', 'al',
         'ocd-division/country:us/state:al/sboe:' || s.d, 'ocd-division/country:us/state:al/sboe:' || s.d,
         'Alabama State Board of Education' || ' District ' || s.d, 'X0003', s.d::text, 'residency'
    FROM seat s RETURNING id, geo_id)
INSERT INTO made_district
SELECT replace(ins.geo_id, 'ocd-division/country:us/state:al/sboe:', '')::int, ins.id FROM ins;

CREATE TEMP TABLE made_office (d int PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, voting_powers,
                                  is_vacant, faces_retention_vote, is_appointed_position, description)
  SELECT 'State Board of Education Member, District ' || s.d, mc.chamber_id, md.district_id, 'AL', 'full',
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
  -- 🔴 each district must MEET its polygon on (geo_id, mtfcc), or it is a key nothing matches
  SELECT count(*) INTO n FROM made_district md JOIN essentials.districts d ON d.id = md.district_id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc;
  IF n <> 8 THEN RAISE EXCEPTION 'only % of the 8 districts meet a geofence row on (geo_id, mtfcc)', n; END IF;
END $$;

-- ─── The people ───
CREATE TEMP TABLE seed_people (
  full_name text PRIMARY KEY, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people VALUES
  ('Jackie Zeigler', 'Jackie', 'Zeigler',
   'https://ballotpedia.org/Jackie_Zeigler (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Tracie West', 'Tracie', 'West',
   'https://ballotpedia.org/Tracie_West (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Jamie McCurry', 'Jamie', 'McCurry',
   'https://ballotpedia.org/Jamie_McCurry (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Kelly Mooney', 'Kelly', 'Mooney',
   'https://ballotpedia.org/Kelly_Mooney (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Yvette Richardson', 'Yvette', 'Richardson',
   'https://ballotpedia.org/Yvette_Richardson (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Tonya Smith Chestnut', 'Tonya Smith', 'Chestnut',
   'https://ballotpedia.org/Tonya_Smith_Chestnut (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Marie Manning', 'Marie', 'Manning',
   'https://ballotpedia.org/Marie_Manning (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Cathi Bradford', 'Cathi', 'Bradford',
   'https://ballotpedia.org/Cathi_Bradford (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Angela Morgan', 'Angela', 'Morgan',
   'https://ballotpedia.org/Angela_Morgan (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Allen Long', 'Allen', 'Long',
   'https://ballotpedia.org/Allen_Long_(Alabama) (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Wayne Reynolds', 'Wayne', 'Reynolds',
   'https://ballotpedia.org/Wayne_Reynolds (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Emily Jones', 'Emily', 'Jones',
   'https://ballotpedia.org/Emily_Jones_(Alabama) (Ballotpedia, fetched and checked 2026-11-07); CC_0370'),
  ('Shatika Armstrong', 'Shatika', 'Armstrong',
   'https://ballotpedia.org/Shatika_Armstrong (Ballotpedia, fetched and checked 2026-11-07); CC_0370');

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
  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Tommy Tuberville');
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
  IF n <> 13 THEN RAISE EXCEPTION 'only % of the 13 people resolved to exactly one row', n; END IF; END $$;

-- ─── Seat every current member ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT mo.office_id, pe.pid, NULL, NULL, 'unknown', 'unknown',
       'https://www.alabamaachieves.org/state-board-of-education/' || ' (the board''s own members page, read 2026-11-07) — CC_0370'
  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who;

-- ─── The races and their results ───
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT '4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid, mo.office_id, 'Alabama State Board of Education' || ' District ' || s.d, NULL, 1,
       'The seat held by ' || s.who || '.'
  FROM seat s JOIN made_office mo ON mo.d = s.d WHERE s.race_recorded;

CREATE TEMP TABLE calls (
  d int NOT NULL, who text NOT NULL, result text NOT NULL, is_write_in boolean NOT NULL,
  is_incumbent boolean NOT NULL, PRIMARY KEY (d, who)
) ON COMMIT DROP;
INSERT INTO calls VALUES
  (2, 'Tracie West', 'won', false, true),
  (2, 'Jamie McCurry', 'lost', false, false),
  (4, 'Yvette Richardson', 'won', false, true),
  (6, 'Cathi Bradford', 'won', false, false),
  (6, 'Angela Morgan', 'lost', false, false),
  (8, 'Emily Jones', 'won', false, false),
  (8, 'Shatika Armstrong', 'lost', false, false);

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM calls; IF n <> 7 THEN RAISE EXCEPTION 'expected 7 candidacies, found %', n; END IF;
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
       'Ballotpedia, "Alabama State Board of Education election, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0370',
       c.result, 'called',
       'Ballotpedia, "Alabama State Board of Education election, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0370', now()
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
  IF n <> 7 THEN RAISE EXCEPTION 'only % of the 7 candidacies hold their stated result', n; END IF;

  -- 🔴🔴 EVERY NEW OFFICE IS SEATED AND THE DRIFT BASELINE HAS NOT MOVED
  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 8 offices have no term and would raise the drift metric', n; END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;
  IF n <> 238 THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — it was 238 and must never be raised', n; END IF;

  -- ⚠ nine members, eight offices, on purpose: the ninth is the Governor, ex officio
  SELECT count(*) INTO n FROM made_chamber mc JOIN essentials.offices o ON o.chamber_id = mc.chamber_id;
  IF n <> 8 THEN RAISE EXCEPTION 'the chamber holds % offices, not 8', n; END IF;
  SELECT official_count INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id;
  IF n <> 9 THEN RAISE EXCEPTION 'official_count is %, not 9 — the board has 9 members and the Governor is the ninth', n; END IF;
  SELECT count(*) INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id
   WHERE ch.remarks ILIKE '%ex officio%' AND ch.inauguration_rules ILIKE '%2027-01-18%';
  IF n <> 1 THEN RAISE EXCEPTION 'the chamber does not record the ex officio ninth member and the 2027-01-18 inauguration'; END IF;

  -- 🔴🔴 THE WHOLE CHAIN, FROM A POINT ON THE GROUND TO A NAMED MEMBER. This is the only
  --   question a voter asks, and it is answered here against the rows just written: the SQL
  --   twin of (gb.mtfcc = 'X0003' AND d.district_type = 'STATE_BOARD_EDUCATION'). The point is
  --   taken inside a county § 16-3-1.1 assigns WHOLE to that district, and compared with the
  --   member named in the anchor table, not in the seat table the seating came from.
  SELECT string_agg(a.county || ' -> ' || coalesce(x.who, 'nobody') || ' (expected ' || a.member || ')', '; ') INTO txt
    FROM anchor a
    LEFT JOIN LATERAL (
      SELECT string_agg(DISTINCT pl.full_name, ', ') AS who
        FROM essentials.geofence_boundaries co
        JOIN essentials.geofence_boundaries gb
          ON gb.mtfcc = 'X0003' AND gb.state = '01'
         AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(co.geometry))
        JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc
         AND dd.district_type = 'STATE_BOARD_EDUCATION'
        JOIN essentials.offices o ON o.district_id = dd.id
        JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
        JOIN essentials.politicians pl ON pl.id = och.politician_id
       WHERE co.state = '01' AND co.mtfcc = 'G4020' AND co.name = a.county) x ON true
   WHERE x.who IS DISTINCT FROM a.member;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor county does not reach its board member: %', txt; END IF;

  -- no term claims a date
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.office_terms t ON t.office_id = mo.office_id
   WHERE t.term_start IS NOT NULL OR t.term_end IS NOT NULL OR t.start_precision <> 'unknown';
  IF n <> 0 THEN RAISE EXCEPTION '% term(s) claim a date this file cannot source', n; END IF;

  RAISE NOTICE 'CC_0370 OK — 8 Alabama SBOE seats created and seated, 4 races, 7 candidacies, 13 people seeded.';
END $$;

COMMIT;
