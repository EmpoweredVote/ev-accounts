-- CC_0371 — Louisiana's Public Service Commission: all 5 seats created and seated on the
--           Act 2 (2022 1st ES) district map, and the 2 results Ballotpedia has called.
--
-- 🔴🔴 THE POLYGONS ARE NOT IN THIS FILE. 80,808 coordinate pairs across 5 districts is 1.8 MB
--   of geometry, so they are loaded by scripts/CC_0371-la-psc-geofences.mjs, which MUST RUN
--   FIRST — the same split CC_0369 and CC_0370 used. This file asserts the rows are there, are
--   the right shape, are the map Act 2 describes, and reach the right member.
--
-- WHICH MAP. Act 2 (HB2) of the 2022 First Extraordinary Session, published by the Legislature
--   as HB2_PSC_221ES. ⚠ Louisiana's 2026 Regular Session DID redistrict — SB121 became Act 2
--   of 2026 — but that is the CONGRESSIONAL map. All nine redistricting bills filed that
--   session were congressional, House or Senate; none touched the PSC. Checked bill by bill on
--   legis.la.gov, 2026-11-07.
--
-- 🟢 THE SHAPEFILE IN THE SAME FOLDER IS NOT A CRS TRAP, AND THAT WAS READ RATHER THAN ASSUMED.
--   HB2_PSC_221ES.prj is GEOGCS["GCS_North_American_1983", ... UNIT["Degree", ...]] — geographic
--   degrees, not a projected plane. Texas's PLANE2106.prj in exactly this role was Lambert
--   Conformal Conic in METRES, which loaded as 4326 is the Holladay failure. Same kind of file,
--   opposite answer. The KML is used anyway (WGS84 by specification), and the parser
--   bounds-checks all 80,808 coordinate pairs against Louisiana.
--
-- 🔴 THE LAYER IS X-ST-BOARD, NOT X0003. A Public Service Commission is not a board of
--   education, so these districts are district_type STATE_BOARD on layer X-ST-BOARD — the pair
--   CC_0366 added to districtQueries.ts and geoIdGuard.ts for the University of Colorado
--   Regents. ⚠ THAT READ-PATH LINE IS ON THIS BRANCH AND NOT YET DEPLOYED, so these seats
--   answer an address only after it merges and the backend deploys. Colorado's regents are in
--   the same position and CC_0366 measured it.
--
-- WHAT IT WRITES:
--   1 chamber · 5 districts · 5 offices · 5 office_terms · 2 races · 10 politicians · 5 candidacies
--
--   District 1  holder Eric Skrmetta       anchor St. Tammany Parish  🏆 Stephanie Hilferty won the seat
--   District 2  holder Jean-Paul Coussan   anchor Lafayette Parish    
--   District 3  holder Davante Lewis       anchor St. James Parish    
--   District 4  holder Mike Francis        anchor Calcasieu Parish    
--   District 5  holder Foster Campbell     anchor Caddo Parish        🏆 John Atkins won the seat
--
-- 🔴 AN OFFICE WITH NO office_terms ROW RAISES THE DRIFT BASELINE, so all 5 are created WITH
--   their current member seated from the commission's own pages, and the post-verify asserts
--   the unflagged baseline is still exactly 238.
--   ⚠ NEITHER WINNER IS THE HOLDER. Eric Skrmetta (D1, in office since 2009-01-01) and Foster
--   Campbell (D5, since 2003-01-01) are the sitting commissioners and were not on the November
--   ballot.
--   ▶ 2027-01-01 — the winners take office. Terms run whole calendar years and the commission's
--     own pages give Districts 1 and 5 as ending December 31, 2026. On that date, seat
--     Stephanie Hilferty in District 1 and John Atkins in District 5.
--
-- 🔴 LOUISIANA'S NOVEMBER CONTEST USED TO BE A JUNGLE PRIMARY, AND FOR THIS BODY IT IS NOT ANY
--   MORE. From the 2026 elections Louisiana runs Congress, the Supreme Court, BESE and the PSC
--   through a CLOSED PARTISAN PRIMARY and runoff, so November is a true general election and
--   "under 50% means a runoff" does not apply. The emitter asserts the winner's share is over
--   50% anyway, so the claim is testable rather than remembered: 58.9% and 59.2%.
--
-- 🟢🟢 THE MAP IS CHECKED AGAINST THE PLAN'S OWN PARISH COMPOSITION, STATED TWICE OVER.
--   data/state-exec-2026-results/la-psc-parishes-2026-11-07.json is built by
--   reconcile-la-psc-parishes.mjs from TWO independent official statements, and it refuses to
--   emit unless they agree on all 64 parishes:
--     1. the Legislature's BLOCK EQUIVALENCY FILE for Act 2 — 142,874 rows of
--        <2020 census block GEOID> <district>, the plan as enacted at the finest grain there is;
--     2. the COMMISSION'S OWN DISTRICT PAGES, lpsc.louisiana.gov/District1..5, each listing its
--        parishes and starring the divided ones.
--   They agree: 54 parishes whole, 10 split. The gate then requires each whole parish to lie in
--   exactly its own district and each split parish to be shared by exactly the districts named.
--   Measured against production: every whole parish is 100.0000% inside its own district with
--   nothing anywhere else, and the smallest true share on a split parish is 15.14% (St. Martin
--   in District 4), far above the 0.5% floor.
--   ▶ THIS IS THE ONLY CHECK THAT CAN SEE TWO DISTRICTS' GEOMETRIES SWAPPED. A label swap
--     passes the coverage test, the overlap test and the ZCTA test — CC_0369's control C.
--   Also measured: the union covers 99.743% of our TIGER Louisiana outline, no two districts
--   overlap at all, the five areas total 52,377 sq mi (which is Louisiana's), and all 539
--   Louisiana ZCTAs resolve to exactly one district.
--   ⚠ Louisiana, like Alabama, has NO incorporated places (G4110) in production.
--
-- IDENTITY. All 10 people are new. A sweep of all 91,748 politicians on both full name and
--   (first, last) returned nothing for any of them — including John Atkins, James Green,
--   Chris Justin and Connie Norris, which is why it was run. 🟢 The sweep is not blind: its
--   positive control found Jeff Landry.
--
-- 🔴 EVERY SOURCE URL WAS FETCHED AND READ, NOT COMPOSED FROM THE NAME. /Mike_Francis returns
--   HTTP 200, contains "Mike Francis", and is a DISAMBIGUATION page listing an Arizona and a
--   Louisiana Mike Francis; his page is /Mike_Francis_(Louisiana). That is the second time in
--   two files — /Allen_Long did it in CC_0370 — so the check is not incidental.
--
-- 🔴 NO TERM START IS INVENTED HERE. The commission publishes each member's term END, not its
--   start, so every term is open-ended with start_precision 'unknown'. (The dates in this
--   header — Skrmetta from 2009-01-01, Campbell from 2003-01-01 — are what their own pages say
--   and are recorded as prose, not written into office_terms, because the pages give the year
--   of assuming office and not a sourced day for the CURRENT term.)
--
-- Applied to production 2026-11-07 by Chris Cantrell. Slot reserved via steward.

BEGIN;

CREATE TEMP TABLE seat (
  d int PRIMARY KEY, who text NOT NULL,
  on_ballot_2026 boolean NOT NULL, race_recorded boolean NOT NULL
) ON COMMIT DROP;
INSERT INTO seat VALUES
  (1, 'Eric Skrmetta', true, true),
  (2, 'Jean-Paul Coussan', false, false),
  (3, 'Davante Lewis', false, false),
  (4, 'Mike Francis', false, false),
  (5, 'Foster Campbell', true, true);

-- One parish per district that Act 2 assigns WHOLE to it.
-- 🔴 THE MEMBER'S NAME IS WRITTEN OUT HERE ON PURPOSE, not read from the seat table (CC_0369
--   control C: a gate that reads its expectation from the thing it is checking is not a gate).
CREATE TEMP TABLE anchor (d int PRIMARY KEY, parish text NOT NULL, member text NOT NULL) ON COMMIT DROP;
INSERT INTO anchor VALUES
  (1, 'St. Tammany Parish', 'Eric Skrmetta'),
  (2, 'Lafayette Parish', 'Jean-Paul Coussan'),
  (3, 'St. James Parish', 'Davante Lewis'),
  (4, 'Calcasieu Parish', 'Mike Francis'),
  (5, 'Caddo Parish', 'Foster Campbell');

-- The parish composition of Act 2, reconciled from the Legislature's block equivalency file and
-- the commission's own district pages. 54 whole, 10 split.
CREATE TEMP TABLE plan_whole (parish text PRIMARY KEY, d int NOT NULL) ON COMMIT DROP;
INSERT INTO plan_whole VALUES
  ('Acadia Parish', 4),
  ('Allen Parish', 4),
  ('Avoyelles Parish', 4),
  ('Beauregard Parish', 4),
  ('Bienville Parish', 5),
  ('Bossier Parish', 5),
  ('Caddo Parish', 5),
  ('Calcasieu Parish', 4),
  ('Caldwell Parish', 5),
  ('Cameron Parish', 4),
  ('Catahoula Parish', 5),
  ('Claiborne Parish', 5),
  ('Concordia Parish', 5),
  ('De Soto Parish', 5),
  ('East Carroll Parish', 5),
  ('East Feliciana Parish', 2),
  ('Evangeline Parish', 4),
  ('Franklin Parish', 5),
  ('Grant Parish', 4),
  ('Iberia Parish', 4),
  ('Jackson Parish', 5),
  ('Jefferson Davis Parish', 4),
  ('Lafayette Parish', 2),
  ('Lafourche Parish', 2),
  ('LaSalle Parish', 4),
  ('Lincoln Parish', 5),
  ('Madison Parish', 5),
  ('Morehouse Parish', 5),
  ('Natchitoches Parish', 5),
  ('Ouachita Parish', 5),
  ('Plaquemines Parish', 1),
  ('Pointe Coupee Parish', 2),
  ('Rapides Parish', 4),
  ('Red River Parish', 5),
  ('Richland Parish', 5),
  ('Sabine Parish', 5),
  ('St. Bernard Parish', 1),
  ('St. Helena Parish', 1),
  ('St. James Parish', 3),
  ('St. John the Baptist Parish', 3),
  ('St. Landry Parish', 4),
  ('St. Mary Parish', 4),
  ('St. Tammany Parish', 1),
  ('Tangipahoa Parish', 1),
  ('Tensas Parish', 5),
  ('Terrebonne Parish', 2),
  ('Union Parish', 5),
  ('Vermilion Parish', 4),
  ('Vernon Parish', 4),
  ('Washington Parish', 1),
  ('Webster Parish', 5),
  ('West Carroll Parish', 5),
  ('West Feliciana Parish', 2),
  ('Winn Parish', 5);

CREATE TEMP TABLE plan_split (parish text PRIMARY KEY, ds text NOT NULL) ON COMMIT DROP;
INSERT INTO plan_split VALUES
  ('Ascension Parish', '2,3'),
  ('Assumption Parish', '2,3'),
  ('East Baton Rouge Parish', '2,3'),
  ('Iberville Parish', '2,3'),
  ('Jefferson Parish', '1,3'),
  ('Livingston Parish', '1,2'),
  ('Orleans Parish', '1,3'),
  ('St. Charles Parish', '1,3'),
  ('St. Martin Parish', '2,4'),
  ('West Baton Rouge Parish', '2,3');

-- ─── Pre-gates ───
DO $$ DECLARE txt text; n int; v numeric; BEGIN
  SELECT count(*) INTO n FROM seat; IF n <> 5 THEN RAISE EXCEPTION 'expected 5 seats, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE race_recorded; IF n <> 2 THEN RAISE EXCEPTION 'expected 2 races, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE on_ballot_2026; IF n <> 2 THEN RAISE EXCEPTION 'expected 2 seats on the ballot, found %', n; END IF;
  SELECT string_agg('D' || d, ', ') INTO txt FROM seat WHERE race_recorded AND NOT on_ballot_2026;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race is recorded for a seat that was not on the ballot: %', txt; END IF;
  SELECT count(*) INTO n FROM plan_whole; IF n <> 54 THEN RAISE EXCEPTION 'the plan table holds % whole parishes, expected 54', n; END IF;
  SELECT count(*) INTO n FROM plan_split; IF n <> 10 THEN RAISE EXCEPTION 'the plan table holds % split parishes, expected 10', n; END IF;
  SELECT count(*) INTO n FROM (SELECT parish FROM plan_whole UNION SELECT parish FROM plan_split) z;
  IF n <> 64 THEN RAISE EXCEPTION 'the plan table names % parishes, and Louisiana has 64', n; END IF;
  SELECT string_agg(z.parish, ', ') INTO txt FROM (SELECT parish FROM plan_whole UNION SELECT parish FROM plan_split) z
   WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries co
                      WHERE co.state = '22' AND co.mtfcc = 'G4020' AND co.name = z.parish);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the plan table names parishes we hold no polygon for: %', txt; END IF;

  SELECT string_agg('D' || a.d || ' ' || a.parish, '; ') INTO txt FROM anchor a
   WHERE NOT EXISTS (SELECT 1 FROM plan_whole w WHERE w.parish = a.parish AND w.d = a.d);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor parish is not assigned whole to its district by Act 2: %', txt; END IF;

  -- 🔴 the two independent statements of the roster must agree before either is used
  SELECT string_agg('D' || a.d || ': anchor says ' || a.member || ', seat says ' || s.who, '; ') INTO txt
    FROM anchor a JOIN seat s ON s.d = a.d WHERE a.member <> s.who;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the anchor table and the seat table name different members: %', txt; END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = '9f0eeee7-0763-44b5-905d-6c584f0eff70'::uuid)
    THEN RAISE EXCEPTION 'the Louisiana government row does not exist'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.elections
                  WHERE id = '635930f4-f5af-4793-ba97-691ceca28114'::uuid AND election_date = DATE '2026-11-03' AND state = 'LA')
    THEN RAISE EXCEPTION 'the election row is not the 2026-11-03 Louisiana general'; END IF;

  IF EXISTS (SELECT 1 FROM essentials.chambers WHERE name_formal = 'Louisiana Public Service Commission')
    THEN RAISE EXCEPTION 'the chamber this file creates already exists'; END IF;
  SELECT string_agg(o.title || ' (' || coalesce(d.district_type, 'no district') || ' ' || o.id || ')', '; ') INTO txt
    FROM essentials.offices o LEFT JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.representing_state = 'LA' AND o.title ILIKE '%Public Service Commission%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file would duplicate an office we already hold: %', txt; END IF;
  SELECT count(*) INTO n FROM essentials.districts WHERE district_type = 'STATE_BOARD' AND lower(state) = 'la';
  IF n <> 0 THEN RAISE EXCEPTION '% Louisiana STATE_BOARD district(s) already exist', n; END IF;

  -- 🔴🔴 THE POLYGONS MUST ALREADY BE LOADED, AND BE THE RIGHT ONES.
  SELECT count(*) INTO n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X-ST-BOARD' AND state = '22'
     AND geo_id = ANY (SELECT 'ocd-division/country:us/state:la/psc:' || s.d FROM seat s);
  IF n <> 5 THEN RAISE EXCEPTION 'only % of the 5 Louisiana PSC polygons are loaded — run scripts/CC_0371-la-psc-geofences.mjs first', n; END IF;

  SELECT string_agg(gb.geo_id || ' srid=' || public.ST_SRID(gb.geometry) || ' valid=' || public.ST_IsValid(gb.geometry), '; ') INTO txt
    FROM essentials.geofence_boundaries gb WHERE gb.mtfcc = 'X-ST-BOARD' AND gb.state = '22'
     AND (public.ST_SRID(gb.geometry) <> 4326 OR NOT public.ST_IsValid(gb.geometry) OR public.ST_IsEmpty(gb.geometry)
          OR public.ST_XMin(gb.geometry) < -95 OR public.ST_XMax(gb.geometry) > -88
          OR public.ST_YMin(gb.geometry) < 28 OR public.ST_YMax(gb.geometry) > 34);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a loaded polygon is not a valid 4326 Louisiana polygon: %', txt; END IF;

  -- The union must reproduce our own TIGER Louisiana outline. The loader measured 99.743% on
  -- the geodesic area. ⚠ NO ::geography CAST HERE or below — ev-cto decision 0006. These are
  -- planar areas over the same patch of Louisiana and the gate needs only their ratio.
  SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g))
                     / public.ST_Area(s.g) * 100)::numeric, 3) INTO v
    FROM (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries WHERE mtfcc='X-ST-BOARD' AND state='22') u,
         (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='22') s;
  IF v < 99.5 THEN RAISE EXCEPTION 'the 5 districts cover only %%% of the Louisiana outline', v; END IF;

  -- 🟢🟢 THE PARISH GATE. The only thing here that can catch two districts' geometries being
  --   swapped, because it brings in evidence from outside the map — twice over.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.parish || ' is only ' ||
           round((public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
                  / public.ST_Area(co.geometry) * 100)::numeric, 4) || '% in D' || w.d AS msg
      FROM plan_whole w
      JOIN essentials.geofence_boundaries co ON co.state='22' AND co.mtfcc='G4020' AND co.name=w.parish
      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X-ST-BOARD' AND gb.state='22'
       AND gb.geo_id = 'ocd-division/country:us/state:la/psc:' || w.d::text
     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
           < public.ST_Area(co.geometry) * 0.999) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'Act 2 puts these parishes wholly in one district and the map does not: %', txt; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.parish || ' (Act 2 D' || w.d || ') also reaches D' || replace(gb.geo_id, 'ocd-division/country:us/state:la/psc:', '') AS msg
      FROM plan_whole w
      JOIN essentials.geofence_boundaries co ON co.state='22' AND co.mtfcc='G4020' AND co.name=w.parish
      JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X-ST-BOARD' AND gb.state='22'
       AND gb.geo_id <> 'ocd-division/country:us/state:la/psc:' || w.d::text
     WHERE public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
           > public.ST_Area(co.geometry) * 0.0001) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a parish Act 2 assigns whole reaches into another district: %', txt; END IF;

  SELECT string_agg(z.parish || ' -> ' || coalesce(z.got, 'nothing') || ', Act 2 says ' || z.ds, '; ') INTO txt FROM (
    SELECT sp.parish, sp.ds,
           (SELECT string_agg(replace(gb.geo_id, 'ocd-division/country:us/state:la/psc:', ''), ',' ORDER BY gb.geo_id)
              FROM essentials.geofence_boundaries gb
             WHERE gb.mtfcc='X-ST-BOARD' AND gb.state='22'
               AND public.ST_Area(public.ST_Intersection(gb.geometry, co.geometry))
                   > public.ST_Area(co.geometry) * 0.005) AS got
      FROM plan_split sp
      JOIN essentials.geofence_boundaries co ON co.state='22' AND co.mtfcc='G4020' AND co.name=sp.parish) z
   WHERE z.got IS DISTINCT FROM z.ds;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a parish Act 2 splits is shared with the wrong districts: %', txt; END IF;

  SELECT count(*) INTO n FROM (
    SELECT (SELECT count(*) FROM essentials.geofence_boundaries s
             WHERE s.mtfcc='X-ST-BOARD' AND s.state='22'
               AND public.ST_Covers(s.geometry, public.ST_PointOnSurface(z.geometry))) k
      FROM essentials.geofence_boundaries z WHERE z.state='22' AND z.mtfcc='G6350') y WHERE y.k <> 1;
  IF n <> 0 THEN RAISE EXCEPTION '% Louisiana ZCTA(s) do not resolve to exactly one PSC district', n; END IF;
END $$;

-- ─── Chamber, districts, offices ───
CREATE TEMP TABLE made_chamber (chamber_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.chambers (name, name_formal, government_id, policy_engagement_level,
                                   official_count, term_length, staggered_term, website_url,
                                   inauguration_rules, election_rules, remarks)
  VALUES ('Public Service Commission', 'Louisiana Public Service Commission', '9f0eeee7-0763-44b5-905d-6c584f0eff70'::uuid, 'full', 5, '6 years', true, 'https://www.lpsc.louisiana.gov/Commissioners',
          'Terms run whole calendar years. The commission''s own pages give the sitting members'' terms as ending December 31 — 2026 for Districts 1 and 5, 2028 for 3 and 4, 2030 for 2 — so the 2026 winners take office on 2027-01-01.',
          '🔴 From the 2026 elections, Louisiana elects the Public Service Commission (with Congress, the Supreme Court and BESE) through a CLOSED PARTISAN PRIMARY and runoff, not the majority-vote "jungle" primary it used before. So the November contest is a true general election and the usual Louisiana hazard — a November result that is really a primary, where anything under 50% means a runoff — does not apply to these two races. Both winners cleared 50% in any case.',
          'Five commissioners, each elected from a single district to a six-year term. Districts 1 and 5 were on the 2026 ballot; 2 was last elected in 2024 and 3 and 4 in 2022.')
  RETURNING id)
INSERT INTO made_chamber SELECT id FROM ins;

CREATE TEMP TABLE made_district (d int PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)
  SELECT 'STATE_BOARD', 'la',
         'ocd-division/country:us/state:la/psc:' || s.d, 'ocd-division/country:us/state:la/psc:' || s.d,
         'Louisiana Public Service Commission' || ' District ' || s.d, 'X-ST-BOARD', s.d::text, 'residency'
    FROM seat s RETURNING id, geo_id)
INSERT INTO made_district
SELECT replace(ins.geo_id, 'ocd-division/country:us/state:la/psc:', '')::int, ins.id FROM ins;

CREATE TEMP TABLE made_office (d int PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, voting_powers,
                                  is_vacant, faces_retention_vote, is_appointed_position, description)
  SELECT 'Public Service Commissioner, District ' || s.d, mc.chamber_id, md.district_id, 'LA', 'full',
         false, false, false, 'seat:' || s.d
    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc
  RETURNING id, description)
INSERT INTO made_office SELECT replace(ins.description, 'seat:', '')::int, ins.id FROM ins;
UPDATE essentials.offices o SET description = NULL FROM made_office mo WHERE o.id = mo.office_id;

DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM made_district; IF n <> 5 THEN RAISE EXCEPTION 'only % districts were created', n; END IF;
  SELECT count(*) INTO n FROM made_office;   IF n <> 5 THEN RAISE EXCEPTION 'only % offices were created', n; END IF;
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id WHERE o.description IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% office(s) kept the seat key in description', n; END IF;
  SELECT count(*) INTO n FROM made_district md JOIN essentials.districts d ON d.id = md.district_id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc;
  IF n <> 5 THEN RAISE EXCEPTION 'only % of the 5 districts meet a geofence row on (geo_id, mtfcc)', n; END IF;
END $$;

-- ─── The people ───
CREATE TEMP TABLE seed_people (
  full_name text PRIMARY KEY, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people VALUES
  ('Eric Skrmetta', 'Eric', 'Skrmetta',
   'https://ballotpedia.org/Eric_Skrmetta (Ballotpedia, fetched and checked 2026-11-07); CC_0371'),
  ('Stephanie Hilferty', 'Stephanie', 'Hilferty',
   'https://ballotpedia.org/Stephanie_Hilferty (Ballotpedia, fetched and checked 2026-11-07); CC_0371'),
  ('Connie Norris', 'Connie', 'Norris',
   'https://ballotpedia.org/Connie_Norris (Ballotpedia, fetched and checked 2026-11-07); CC_0371'),
  ('Chris Justin', 'Chris', 'Justin',
   'https://ballotpedia.org/Chris_Justin (Ballotpedia, fetched and checked 2026-11-07); CC_0371'),
  ('Jean-Paul Coussan', 'Jean-Paul', 'Coussan',
   'https://ballotpedia.org/Jean-Paul_Coussan (Ballotpedia, fetched and checked 2026-11-07); CC_0371'),
  ('Davante Lewis', 'Davante', 'Lewis',
   'https://ballotpedia.org/Davante_Lewis (Ballotpedia, fetched and checked 2026-11-07); CC_0371'),
  ('Mike Francis', 'Mike', 'Francis',
   'https://ballotpedia.org/Mike_Francis_(Louisiana) (Ballotpedia, fetched and checked 2026-11-07); CC_0371'),
  ('Foster Campbell', 'Foster', 'Campbell',
   'https://ballotpedia.org/Foster_Campbell (Ballotpedia, fetched and checked 2026-11-07); CC_0371'),
  ('John Atkins', 'John', 'Atkins',
   'https://ballotpedia.org/John_Atkins_(Louisiana) (Ballotpedia, fetched and checked 2026-11-07); CC_0371'),
  ('James Green', 'James', 'Green',
   'https://ballotpedia.org/James_Green_(Louisiana) (Ballotpedia, fetched and checked 2026-11-07); CC_0371');

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
  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Jeff Landry');
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
  IF n <> 10 THEN RAISE EXCEPTION 'only % of the 10 people resolved to exactly one row', n; END IF; END $$;

-- ─── Seat every current member ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT mo.office_id, pe.pid, NULL, NULL, 'unknown', 'unknown',
       'https://www.lpsc.louisiana.gov/District' || s.d || ' (the commission''s own district page, read 2026-11-07) — CC_0371'
  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who;

-- ─── The races and their results ───
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT '635930f4-f5af-4793-ba97-691ceca28114'::uuid, mo.office_id, 'Louisiana Public Service Commission' || ' District ' || s.d, NULL, 1,
       'The seat held by ' || s.who || '.'
  FROM seat s JOIN made_office mo ON mo.d = s.d WHERE s.race_recorded;

CREATE TEMP TABLE calls (
  d int NOT NULL, who text NOT NULL, result text NOT NULL, is_write_in boolean NOT NULL,
  is_incumbent boolean NOT NULL, PRIMARY KEY (d, who)
) ON COMMIT DROP;
INSERT INTO calls VALUES
  (1, 'Stephanie Hilferty', 'won', false, false),
  (1, 'Connie Norris', 'lost', false, false),
  (1, 'Chris Justin', 'lost', false, false),
  (5, 'John Atkins', 'won', false, false),
  (5, 'James Green', 'lost', false, false);

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
  -- ⚠ neither sitting commissioner ran, so NO candidacy may carry the incumbent flag
  SELECT count(*) INTO n FROM calls WHERE is_incumbent;
  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) claim to be the sitting commissioner, and neither ran', n; END IF;
END $$;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   is_write_in, source, result, result_certainty, result_source, result_recorded_at)
SELECT r.id, pl.id, pl.full_name, pl.first_name, pl.last_name, c.is_incumbent, 'active', c.is_write_in,
       'Ballotpedia, "Louisiana Public Service Commission election, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0371',
       c.result, 'called',
       'Ballotpedia, "Louisiana Public Service Commission election, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0371', now()
  FROM calls c JOIN made_office mo ON mo.d = c.d
  JOIN essentials.races r ON r.office_id = mo.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN person pe ON pe.who = c.who JOIN essentials.politicians pl ON pl.id = pe.pid;

-- ─── Post-verify ───
DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.d = s.d
    JOIN essentials.races r ON r.office_id = mo.office_id WHERE s.race_recorded;
  IF n <> 2 THEN RAISE EXCEPTION 'expected 2 new races, found %', n; END IF;
  SELECT count(*) INTO n FROM calls c JOIN made_office mo ON mo.d = c.d
    JOIN essentials.races r ON r.office_id = mo.office_id
    JOIN person pe ON pe.who = c.who
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = pe.pid
   WHERE rc.result = c.result AND rc.result_certainty = 'called' AND rc.is_write_in = c.is_write_in;
  IF n <> 5 THEN RAISE EXCEPTION 'only % of the 5 candidacies hold their stated result', n; END IF;

  -- 🔴🔴 EVERY NEW OFFICE IS SEATED AND THE DRIFT BASELINE HAS NOT MOVED
  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 5 offices have no term and would raise the drift metric', n; END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;
  IF n <> 238 THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — it was 238 and must never be raised', n; END IF;

  SELECT count(*) INTO n FROM made_chamber mc JOIN essentials.offices o ON o.chamber_id = mc.chamber_id;
  IF n <> 5 THEN RAISE EXCEPTION 'the chamber holds % offices, not 5', n; END IF;
  SELECT official_count INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id;
  IF n <> 5 THEN RAISE EXCEPTION 'official_count is %, not 5', n; END IF;
  SELECT count(*) INTO n FROM essentials.chambers ch JOIN made_chamber mc ON mc.chamber_id = ch.id
   WHERE ch.election_rules ILIKE '%closed partisan primary%' AND ch.inauguration_rules ILIKE '%2027-01-01%';
  IF n <> 1 THEN RAISE EXCEPTION 'the chamber does not record the closed-primary change and the 2027-01-01 handover'; END IF;

  -- 🔴🔴 THE WHOLE CHAIN, FROM A POINT ON THE GROUND TO A NAMED MEMBER. The point is taken
  --   inside a parish Act 2 assigns WHOLE to that district, and compared with the member named
  --   in the anchor table, not in the seat table the seating came from.
  SELECT string_agg(a.parish || ' -> ' || coalesce(x.who, 'nobody') || ' (expected ' || a.member || ')', '; ') INTO txt
    FROM anchor a
    LEFT JOIN LATERAL (
      SELECT string_agg(DISTINCT pl.full_name, ', ') AS who
        FROM essentials.geofence_boundaries co
        JOIN essentials.geofence_boundaries gb
          ON gb.mtfcc = 'X-ST-BOARD' AND gb.state = '22'
         AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(co.geometry))
        JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc
         AND dd.district_type = 'STATE_BOARD'
        JOIN essentials.offices o ON o.district_id = dd.id
        JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
        JOIN essentials.politicians pl ON pl.id = och.politician_id
       WHERE co.state = '22' AND co.mtfcc = 'G4020' AND co.name = a.parish) x ON true
   WHERE x.who IS DISTINCT FROM a.member;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor parish does not reach its commissioner: %', txt; END IF;

  SELECT count(*) INTO n FROM made_office mo JOIN essentials.office_terms t ON t.office_id = mo.office_id
   WHERE t.term_start IS NOT NULL OR t.term_end IS NOT NULL OR t.start_precision <> 'unknown';
  IF n <> 0 THEN RAISE EXCEPTION '% term(s) claim a date this file cannot source', n; END IF;

  RAISE NOTICE 'CC_0371 OK — 5 Louisiana PSC seats created and seated, 2 races, 5 candidacies, 10 people seeded.';
END $$;

COMMIT;
