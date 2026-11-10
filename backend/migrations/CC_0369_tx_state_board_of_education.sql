-- CC_0369 — Texas's State Board of Education: all 15 seats created and seated on the
--           PLANE2106 district map, and the 7 results Ballotpedia has called.
--
-- 🔴🔴 THE POLYGONS ARE NOT IN THIS FILE. 263,933 coordinate pairs across 15 districts is
--   7.9 MB of geometry, so they are loaded by scripts/CC_0369-tx-sboe-geofences.mjs, which
--   MUST RUN FIRST — the same split CA_0205 used for California's Board of Equalization.
--   This file asserts the rows are there, are the right shape, and reach the right member.
--
-- 🔴🔴 THE SHAPEFILE IN THE SAME DATASET WOULD HAVE BEEN THE HOLLADAY FAILURE AGAIN.
--   PLANE2106.prj reads PROJCS["NAD_1983_Lambert_Conformal_Conic", ...
--   PARAMETER["False_Easting",1000000.0], ... UNIT["Meter",1.0]] — Texas-centric Lambert
--   Conformal Conic in METRES. Loaded as SRID 4326 those numbers make valid, correctly shaped
--   polygons that match no address on Earth, and every geometric check passes. The KML in the
--   same dataset is WGS84 lon/lat BY SPECIFICATION, so it is the one used, and the loader
--   still bounds-checks every ring against Texas. A control that reprojects the real data to
--   Web Mercator metres and relabels it 4326 is refused on the first district.
--
-- WHICH MAP. The Texas Legislative Council's Capitol Data Portal carries exactly four SBOE
--   plans; the other three state their own end dates in their titles ("2013-2022" twice,
--   "2003-2012"). PLANE2106, "STATE BOARD OF EDUCATION DISTRICTS, JANUARY 2023", is the only
--   one still open, and Texas's 2025 mid-decade redistricting did not redraw this map.
--
-- 🟢 NO READ-PATH CHANGE. districtQueries.ts and geoIdGuard.ts already admit
--   (X0003, STATE_BOARD_EDUCATION) for Utah's board and the rule is NOT state-scoped, so
--   Texas's rows join as they are. The geo_id carries the state, so nothing collides.
--
-- WHAT IT WRITES:
--   1 chamber · 15 districts · 15 offices · 15 office_terms · 7 races · 28 politicians · 15 candidacies
--
--   District  1  holder Gustavo Reveles        (El Paso)        
--   District  2  holder LJ Francis             (Corpus Christi) 🏆 Thomas Garcia
--   District  3  holder Marisa B. Perez-Diaz   (San Antonio)    
--   District  4  holder Tammie Nielsen         (Pasadena)       
--   District  5  holder Rebecca Bell-Metereau  (San Marcos)     🏆 Allison Bush
--   District  6  holder Will Hickman           (Houston)        🏆 Michelle Palmer
--   District  7  holder Julie Pickren          (Pearland)       🏆 Julie Pickren
--   District  8  holder Audrey Young           (Trinity)        ⏳ on the ballot, uncalled
--   District  9  holder Keven Ellis            (Lufkin)         🏆 Kason Huddleston
--   District 10  holder Tom Maynard            (Florence)       
--   District 11  holder Brandon Hall           (Aledo)          
--   District 12  holder Pam Little             (Fairview)       
--   District 13  holder Tiffany Clark          (DeSoto)         🏆 Tiffany Clark
--   District 14  holder Evelyn Brooks          (Frisco)         🏆 Mindy Bumgarner
--   District 15  holder Aaron Kinsey           (Midland)        
--
-- 🔴 AN OFFICE WITH NO office_terms ROW RAISES THE DRIFT BASELINE, so all 15 are created WITH
--   their current member seated from the board's own roster, and the post-verify asserts the
--   unflagged baseline is still exactly 238.
--   ⚠ THE HOLDER IS NOT THE WINNER: 5 of the 7 winners replace the sitting member.
--
-- ⚠ DISTRICT 8 IS CREATED AND SEATED BUT CARRIES NO RACE. Eight districts were on the 2026
--   ballot — 2, 5, 6, 7, 8, 9, 13 and 14, each with a Ballotpedia votebox — and District 8 is
--   the one with no winner called. It belongs to the uncalled pass. The seat table keeps
--   on_ballot_2026 and race_recorded in separate columns and a gate refuses a race on a seat
--   that was not on the ballot.
--
-- 🟢 THE MAP IS CHECKED AGAINST GEOMETRY PRODUCTION ALREADY TRUSTS, AND AGAINST THE BOARD'S
--   OWN ROSTER. Measured by the loader and asserted again here: the union covers 99.89% of
--   our TIGER Texas outline; no two districts overlap (0.000000%); all 1,228 Texas
--   incorporated places resolve to EXACTLY ONE district, none to zero and none to two; and
--   nine board members' home towns lie wholly inside the district they represent. Texas law
--   requires a member to be a bona fide resident of their district, so the roster's home town
--   is evidence independent of the map. ⚠ Six members' towns straddle a district line and
--   anchor nothing — Houston touches districts 4, 6, 7 and 8.
--
-- IDENTITY. All 28 people are new; nothing is pinned and no collision is excused. Both sweeps
--   returned only different people (Mike Diaz, Travis Nelson, Muriel Jordan, Aleem and Andrew
--   Young, Bob and Brandi Hall, Tim J Clark and Tracy Clark, Everlla Brooks, Angela Taylor).
--   🟢 The sweep is not blind: production holds 180 sitting Texas House members.
--
-- 🔴 NO TERM START IS INVENTED. The board's roster publishes none, so every term is open-ended
--   with start_precision 'unknown'.
--
-- ⚠ AMENDED AFTER APPLYING, GATE ONLY. The coverage gate first measured the union against the
--   state outline with a ::geography cast. CI's check-postgis-spatial-ref-guard.mjs refuses
--   that in any migration, because a geography cast reads public.spatial_ref_sys and anon can
--   write it (ev-cto decision 0006, an accepted risk). The gate now takes the ratio of two
--   PLANAR areas instead, which is the same test. NO WRITTEN DATA CHANGED — the version that
--   ran and this one insert exactly the same rows, and the edited file was dry-run again.
--
-- Applied to production 2026-11-07 by Chris Cantrell. Slot reserved via steward.

BEGIN;

CREATE TEMP TABLE seat (
  d int PRIMARY KEY, who text NOT NULL, town text NOT NULL,
  on_ballot_2026 boolean NOT NULL, race_recorded boolean NOT NULL
) ON COMMIT DROP;
INSERT INTO seat VALUES
  (1, 'Gustavo Reveles', 'El Paso', false, false),
  (2, 'LJ Francis', 'Corpus Christi', true, true),
  (3, 'Marisa B. Perez-Diaz', 'San Antonio', false, false),
  (4, 'Tammie Nielsen', 'Pasadena', false, false),
  (5, 'Rebecca Bell-Metereau', 'San Marcos', true, true),
  (6, 'Will Hickman', 'Houston', true, true),
  (7, 'Julie Pickren', 'Pearland', true, true),
  (8, 'Audrey Young', 'Trinity', true, false),
  (9, 'Keven Ellis', 'Lufkin', true, true),
  (10, 'Tom Maynard', 'Florence', false, false),
  (11, 'Brandon Hall', 'Aledo', false, false),
  (12, 'Pam Little', 'Fairview', false, false),
  (13, 'Tiffany Clark', 'DeSoto', true, true),
  (14, 'Evelyn Brooks', 'Frisco', true, true),
  (15, 'Aaron Kinsey', 'Midland', false, false);

-- The nine member towns that lie WHOLLY inside one district, and so can anchor the map.
-- 🔴 THE MEMBER'S NAME IS WRITTEN OUT HERE ON PURPOSE, not read from the seat table. A control
--   that put two members in each other's seat PASSED against the first version of this gate,
--   because the chain resolved the holder the seat table had just seated and then compared it
--   with that same seat table — the gate was asking the data to agree with itself. Two
--   independent statements of the roster, and a gate that they match, is what fixes it.
CREATE TEMP TABLE anchor (d int PRIMARY KEY, town text NOT NULL, member text NOT NULL) ON COMMIT DROP;
INSERT INTO anchor VALUES
  (2, 'Corpus Christi city', 'LJ Francis'),
  (5, 'San Marcos city', 'Rebecca Bell-Metereau'),
  (8, 'Trinity city', 'Audrey Young'),
  (9, 'Lufkin city', 'Keven Ellis'),
  (10, 'Florence city', 'Tom Maynard'),
  (11, 'Aledo city', 'Brandon Hall'),
  (12, 'Fairview town', 'Pam Little'),
  (13, 'DeSoto city', 'Tiffany Clark'),
  (15, 'Midland city', 'Aaron Kinsey');

-- ─── Pre-gates ───
DO $$ DECLARE txt text; n int; v numeric; BEGIN
  SELECT count(*) INTO n FROM seat; IF n <> 15 THEN RAISE EXCEPTION 'expected 15 seats, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE race_recorded; IF n <> 7 THEN RAISE EXCEPTION 'expected 7 races, found %', n; END IF;
  SELECT count(*) INTO n FROM seat WHERE on_ballot_2026; IF n <> 8 THEN RAISE EXCEPTION 'expected 8 seats on the ballot, found %', n; END IF;
  SELECT string_agg('D' || d, ', ') INTO txt FROM seat WHERE race_recorded AND NOT on_ballot_2026;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race is recorded for a seat that was not on the ballot: %', txt; END IF;

  -- 🔴 the two independent statements of the roster must agree before either is used
  SELECT string_agg('D' || a.d || ': anchor says ' || a.member || ', seat says ' || s.who, '; ') INTO txt
    FROM anchor a JOIN seat s ON s.d = a.d WHERE a.member <> s.who;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the anchor table and the seat table name different members: %', txt; END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'::uuid)
    THEN RAISE EXCEPTION 'the Texas government row does not exist'; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.elections
                  WHERE id = '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid AND election_date = DATE '2026-11-03' AND state = 'TX')
    THEN RAISE EXCEPTION 'the election row is not the 2026-11-03 Texas general'; END IF;

  -- nothing this file creates may already exist
  IF EXISTS (SELECT 1 FROM essentials.chambers WHERE name_formal = 'Texas State Board of Education')
    THEN RAISE EXCEPTION 'the chamber this file creates already exists'; END IF;
  SELECT string_agg(o.title || ' (' || d.district_type || ' ' || o.id || ')', '; ') INTO txt
    FROM essentials.districts d JOIN essentials.offices o ON o.district_id = d.id
   WHERE upper(d.state) = 'TX' AND o.title ILIKE '%State Board of Education%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file would duplicate an office we already hold: %', txt; END IF;
  SELECT count(*) INTO n FROM essentials.districts WHERE district_type = 'STATE_BOARD_EDUCATION' AND lower(state) = 'tx';
  IF n <> 0 THEN RAISE EXCEPTION '% Texas STATE_BOARD_EDUCATION district(s) already exist', n; END IF;

  -- 🔴🔴 THE POLYGONS MUST ALREADY BE LOADED, AND BE THE RIGHT ONES. This file is useless
  --   without scripts/CC_0369-tx-sboe-geofences.mjs having run first.
  SELECT count(*) INTO n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0003' AND state = '48'
     AND geo_id = ANY (SELECT 'ocd-division/country:us/state:tx/sboe:' || s.d FROM seat s);
  IF n <> 15 THEN RAISE EXCEPTION 'only % of the 15 Texas SBOE polygons are loaded — run scripts/CC_0369-tx-sboe-geofences.mjs first', n; END IF;

  SELECT string_agg(gb.geo_id || ' srid=' || public.ST_SRID(gb.geometry) || ' valid=' || public.ST_IsValid(gb.geometry), '; ') INTO txt
    FROM essentials.geofence_boundaries gb WHERE gb.mtfcc = 'X0003' AND gb.state = '48'
     AND (public.ST_SRID(gb.geometry) <> 4326 OR NOT public.ST_IsValid(gb.geometry) OR public.ST_IsEmpty(gb.geometry)
          OR public.ST_XMin(gb.geometry) < -107 OR public.ST_XMax(gb.geometry) > -93
          OR public.ST_YMin(gb.geometry) < 25 OR public.ST_YMax(gb.geometry) > 37);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a loaded polygon is not a valid 4326 Texas polygon: %', txt; END IF;

  -- The union must reproduce our own TIGER Texas outline. Independent geometry; the loader
  -- measured 99.890% on the geodesic area.
  -- ⚠ NO ::geography CAST HERE. A geography cast reads public.spatial_ref_sys, which anon can
  --   write, and check-postgis-spatial-ref-guard.mjs refuses it in any migration — ev-cto
  --   decision 0006, an accepted risk this file will not re-open. These are two PLANAR areas
  --   in square degrees over the same patch of Texas, and the gate only needs their RATIO, so
  --   the projection distortion cancels. (The loader, which is a script and not scanned, does
  --   the same measurement on the geography and reports the true 99.890%.)
  SELECT round((100 - public.ST_Area(public.ST_Difference(s.g, u.g))
                     / public.ST_Area(s.g) * 100)::numeric, 3) INTO v
    FROM (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries WHERE mtfcc='X0003' AND state='48') u,
         (SELECT geometry g FROM essentials.geofence_boundaries WHERE mtfcc='G4000' AND geo_id='48') s;
  IF v < 99.5 THEN RAISE EXCEPTION 'the 15 districts cover only %%% of the Texas outline', v; END IF;

  -- and every Texas incorporated place must land in exactly one of them
  SELECT count(*) INTO n FROM (
    SELECT (SELECT count(*) FROM essentials.geofence_boundaries s
             WHERE s.mtfcc='X0003' AND s.state='48'
               AND public.ST_Covers(s.geometry, public.ST_PointOnSurface(pl.geometry))) k
      FROM essentials.geofence_boundaries pl WHERE pl.state='48' AND pl.mtfcc='G4110') z WHERE z.k <> 1;
  IF n <> 0 THEN RAISE EXCEPTION '% Texas place(s) do not resolve to exactly one SBOE district', n; END IF;
END $$;

-- ─── Chamber, districts, offices ───
CREATE TEMP TABLE made_chamber (chamber_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.chambers (name, name_formal, government_id, policy_engagement_level,
                                   official_count, term_length, staggered_term, website_url)
  VALUES ('State Board of Education', 'Texas State Board of Education', '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'::uuid, 'full', 15, '4 years', true, 'https://sboe.texas.gov/state-board-of-education/sboe-board-members/sboe-members')
  RETURNING id)
INSERT INTO made_chamber SELECT id FROM ins;

CREATE TEMP TABLE made_district (d int PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id, representation_basis)
  SELECT 'STATE_BOARD_EDUCATION', 'tx',
         'ocd-division/country:us/state:tx/sboe:' || s.d, 'ocd-division/country:us/state:tx/sboe:' || s.d,
         'Texas State Board of Education' || ' District ' || s.d, 'X0003', s.d::text, 'residency'
    FROM seat s RETURNING id, geo_id)
INSERT INTO made_district
SELECT replace(ins.geo_id, 'ocd-division/country:us/state:tx/sboe:', '')::int, ins.id FROM ins;

CREATE TEMP TABLE made_office (d int PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, voting_powers,
                                  is_vacant, faces_retention_vote, is_appointed_position, description)
  SELECT 'State Board of Education Member, District ' || s.d, mc.chamber_id, md.district_id, 'TX', 'full',
         false, false, false, 'seat:' || s.d
    FROM seat s JOIN made_district md ON md.d = s.d CROSS JOIN made_chamber mc
  RETURNING id, description)
INSERT INTO made_office SELECT replace(ins.description, 'seat:', '')::int, ins.id FROM ins;
UPDATE essentials.offices o SET description = NULL FROM made_office mo WHERE o.id = mo.office_id;

DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM made_district; IF n <> 15 THEN RAISE EXCEPTION 'only % districts were created', n; END IF;
  SELECT count(*) INTO n FROM made_office;   IF n <> 15 THEN RAISE EXCEPTION 'only % offices were created', n; END IF;
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id WHERE o.description IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% office(s) kept the seat key in description', n; END IF;
  -- 🔴 each district must MEET its polygon on (geo_id, mtfcc), or it is a key nothing matches
  SELECT count(*) INTO n FROM made_district md JOIN essentials.districts d ON d.id = md.district_id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc;
  IF n <> 15 THEN RAISE EXCEPTION 'only % of the 15 districts meet a geofence row on (geo_id, mtfcc)', n; END IF;
END $$;

-- ─── The people ───
CREATE TEMP TABLE seed_people (
  full_name text PRIMARY KEY, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people VALUES
  ('Gustavo Reveles', 'Gustavo', 'Reveles',
   'https://ballotpedia.org/Gustavo_Reveles (Ballotpedia, read 2026-11-07); CC_0369'),
  ('LJ Francis', 'LJ', 'Francis',
   'https://ballotpedia.org/LJ_Francis (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Thomas Garcia', 'Thomas', 'Garcia',
   'https://ballotpedia.org/Thomas_Garcia (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Victoria Hinojosa', 'Victoria', 'Hinojosa',
   'https://ballotpedia.org/Victoria_Hinojosa (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Marisa B. Perez-Diaz', 'Marisa B.', 'Perez-Diaz',
   'https://ballotpedia.org/Marisa_B._Perez-Diaz (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Tammie Nielsen', 'Tammie', 'Nielsen',
   'https://ballotpedia.org/Tammie_Nielsen (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Rebecca Bell-Metereau', 'Rebecca', 'Bell-Metereau',
   'https://ballotpedia.org/Rebecca_Bell-Metereau (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Allison Bush', 'Allison', 'Bush',
   'https://ballotpedia.org/Allison_Bush (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Mica Arellano', 'Mica', 'Arellano',
   'https://ballotpedia.org/Mica_Arellano (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Will Hickman', 'Will', 'Hickman',
   'https://ballotpedia.org/Will_Hickman (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Michelle Palmer', 'Michelle', 'Palmer',
   'https://ballotpedia.org/Michelle_Palmer (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Tiffany Nelson', 'Tiffany', 'Nelson',
   'https://ballotpedia.org/Tiffany_Nelson (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Margo Jordan', 'Margo', 'Jordan',
   'https://ballotpedia.org/Margo_Jordan (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Julie Pickren', 'Julie', 'Pickren',
   'https://ballotpedia.org/Julie_Pickren (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Tiffany Perkinz', 'Tiffany', 'Perkinz',
   'https://ballotpedia.org/Tiffany_Perkinz (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Audrey Young', 'Audrey', 'Young',
   'https://ballotpedia.org/Audrey_Young (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Keven Ellis', 'Keven', 'Ellis',
   'https://ballotpedia.org/Keven_Ellis (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Kason Huddleston', 'Kason', 'Huddleston',
   'https://ballotpedia.org/Kason_Huddleston (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Ericka Ledferd', 'Ericka', 'Ledferd',
   'https://ballotpedia.org/Ericka_Ledferd (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Tom Maynard', 'Tom', 'Maynard',
   'https://ballotpedia.org/Tom_Maynard (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Brandon Hall', 'Brandon', 'Hall',
   'https://ballotpedia.org/Brandon_Hall (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Pam Little', 'Pam', 'Little',
   'https://ballotpedia.org/Pam_Little (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Tiffany Clark', 'Tiffany', 'Clark',
   'https://ballotpedia.org/Tiffany_Clark (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Carlos Garza', 'Carlos', 'Garza',
   'https://ballotpedia.org/Carlos_Garza (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Evelyn Brooks', 'Evelyn', 'Brooks',
   'https://ballotpedia.org/Evelyn_Brooks (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Mindy Bumgarner', 'Mindy', 'Bumgarner',
   'https://ballotpedia.org/Mindy_Bumgarner (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Amy Taylor', 'Amy', 'Taylor',
   'https://ballotpedia.org/Amy_Taylor (Ballotpedia, read 2026-11-07); CC_0369'),
  ('Aaron Kinsey', 'Aaron', 'Kinsey',
   'https://ballotpedia.org/Aaron_Kinsey (Ballotpedia, read 2026-11-07); CC_0369');

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
  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Jon Rosenthal');
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
  IF n <> 28 THEN RAISE EXCEPTION 'only % of the 28 people resolved to exactly one row', n; END IF; END $$;

-- ─── Seat every current member ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT mo.office_id, pe.pid, NULL, NULL, 'unknown', 'unknown',
       'https://sboe.texas.gov/state-board-of-education/sboe-board-members/sboe-members' || ' (the board''s own members page, read 2026-11-07) — CC_0369'
  FROM seat s JOIN made_office mo ON mo.d = s.d JOIN person pe ON pe.who = s.who;

-- ─── The races and their results ───
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid, mo.office_id, 'Texas State Board of Education District ' || s.d, NULL, 1,
       'The seat held by ' || s.who || ' of ' || s.town || '.'
  FROM seat s JOIN made_office mo ON mo.d = s.d WHERE s.race_recorded;

CREATE TEMP TABLE calls (
  d int NOT NULL, who text NOT NULL, result text NOT NULL, is_write_in boolean NOT NULL,
  is_incumbent boolean NOT NULL, PRIMARY KEY (d, who)
) ON COMMIT DROP;
INSERT INTO calls VALUES
  (2, 'Thomas Garcia', 'won', false, false),
  (2, 'Victoria Hinojosa', 'lost', false, false),
  (5, 'Allison Bush', 'won', false, false),
  (5, 'Mica Arellano', 'lost', false, false),
  (6, 'Michelle Palmer', 'won', false, false),
  (6, 'Tiffany Nelson', 'lost', false, false),
  (6, 'Margo Jordan', 'lost', true, false),
  (7, 'Julie Pickren', 'won', false, true),
  (7, 'Tiffany Perkinz', 'lost', false, false),
  (9, 'Kason Huddleston', 'won', false, false),
  (9, 'Ericka Ledferd', 'lost', false, false),
  (13, 'Tiffany Clark', 'won', false, true),
  (13, 'Carlos Garza', 'lost', false, false),
  (14, 'Mindy Bumgarner', 'won', false, false),
  (14, 'Amy Taylor', 'lost', false, false);

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM calls; IF n <> 15 THEN RAISE EXCEPTION 'expected 15 candidacies, found %', n; END IF;
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
       'Ballotpedia, "Texas state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0369',
       c.result, 'called',
       'Ballotpedia, "Texas state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0369', now()
  FROM calls c JOIN made_office mo ON mo.d = c.d
  JOIN essentials.races r ON r.office_id = mo.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN person pe ON pe.who = c.who JOIN essentials.politicians pl ON pl.id = pe.pid;

-- ─── Post-verify ───
DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.d = s.d
    JOIN essentials.races r ON r.office_id = mo.office_id WHERE s.race_recorded;
  IF n <> 7 THEN RAISE EXCEPTION 'expected 7 new races, found %', n; END IF;
  SELECT count(*) INTO n FROM calls c JOIN made_office mo ON mo.d = c.d
    JOIN essentials.races r ON r.office_id = mo.office_id
    JOIN person pe ON pe.who = c.who
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = pe.pid
   WHERE rc.result = c.result AND rc.result_certainty = 'called' AND rc.is_write_in = c.is_write_in;
  IF n <> 15 THEN RAISE EXCEPTION 'only % of the 15 candidacies hold their stated result', n; END IF;

  -- 🔴🔴 EVERY NEW OFFICE IS SEATED AND THE DRIFT BASELINE HAS NOT MOVED
  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 15 offices have no term and would raise the drift metric', n; END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;
  IF n <> 238 THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — it was 238 and must never be raised', n; END IF;

  SELECT count(*) INTO n FROM made_chamber mc JOIN essentials.offices o ON o.chamber_id = mc.chamber_id;
  IF n <> 15 THEN RAISE EXCEPTION 'the chamber holds % offices, not 15', n; END IF;

  -- 🔴🔴 THE WHOLE CHAIN, FROM A POINT ON THE GROUND TO A NAMED MEMBER. This is the only
  --   question a voter asks, and it is answered here against the rows just written: the SQL
  --   twin of (gb.mtfcc = 'X0003' AND d.district_type = 'STATE_BOARD_EDUCATION').
  SELECT string_agg(a.town || ' -> ' || coalesce(x.who, 'nobody') || ' (expected ' || a.member || ')', '; ') INTO txt
    FROM anchor a
    LEFT JOIN LATERAL (
      SELECT string_agg(DISTINCT pl.full_name, ', ') AS who
        FROM essentials.geofence_boundaries place
        JOIN essentials.geofence_boundaries gb
          ON gb.mtfcc = 'X0003' AND gb.state = '48'
         AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(place.geometry))
        JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc
         AND dd.district_type = 'STATE_BOARD_EDUCATION'
        JOIN essentials.offices o ON o.district_id = dd.id
        JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
        JOIN essentials.politicians pl ON pl.id = och.politician_id
       WHERE place.state = '48' AND place.mtfcc = 'G4110' AND place.name = a.town) x ON true
   WHERE x.who IS DISTINCT FROM a.member;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an anchor town does not reach its board member: %', txt; END IF;

  -- no term claims a date
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.office_terms t ON t.office_id = mo.office_id
   WHERE t.term_start IS NOT NULL OR t.term_end IS NOT NULL OR t.start_precision <> 'unknown';
  IF n <> 0 THEN RAISE EXCEPTION '% term(s) claim a date this file cannot source', n; END IF;

  RAISE NOTICE 'CC_0369 OK — 15 Texas SBOE seats created and seated, 7 races, 15 candidacies, 28 people seeded.';
END $$;

COMMIT;
