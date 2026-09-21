-- CC_0117_nc_charlotte_mecklenburg_structure.sql
-- Knight Foundation program, wave NC-3 (structure half). Slot RESERVED from the allocator.
--
-- Creates BOTH Knight jurisdictions in slice 10, which have nothing in production today -- no
-- government row, no chamber, no district, no office, no official:
--
--   City of Charlotte      2 chambers    8 districts   12 offices  (Mayor + 4 at large + 7 district)
--   Mecklenburg County     3 chambers    6 districts   16 offices  (9 commissioners + 4 officers + 3 supervisors)
--
-- Creates NO people and NO terms -- CC_0118 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 `37119` IS TWO DIFFERENT DISTRICTS AND ONLY THE MTFCC SEPARATES THEM. The same geo_id
-- string carries G4020 (Mecklenburg County) and G5220 (State House District 119, which is
-- Haywood/Swain, three hundred miles west). Every join below keys on (geo_id, mtfcc) or
-- (geo_id, district_type). A join written on geo_id alone would hand a Mecklenburg county office
-- to a mountain House district, or the reverse.
--
-- ⚠ THE COUNTY DISTRICT ROW ALREADY EXISTS and carries no office: `37119`/G4020/COUNTY, label
-- 'Mecklenburg County'. This migration REUSES it and must not create a second.
--
-- ⚠ A name search for Charlotte is safe today and only by luck. `governments.name ILIKE
-- '%charlotte%'` returns ZERO rows nationally -- there is no Charlotte, Vermont or Charlotte,
-- Michigan in production to collide with, as '%Boulder%' and '%St. Paul%' did in slices 9 and 5.
-- Everything here is matched on geo_id anyway, because a later Charlotte elsewhere would turn
-- this into the Boulder trap silently.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE MAYOR IS NOT A COUNCIL MEMBER, AND THE CHARTER IS WHY. Charlotte's city charter
-- (S.L. 2000-26) s 2.03 gives the Council ELEVEN members -- "seven single-member electoral
-- districts" and "four at-large" -- and s 3.23 says of the Mayor: "shall preside, if present,
-- but shall have no vote except in case of a tie, or as provided herein", with a veto that
-- requires "at least seven members voting in the affirmative" to override. The city's public
-- page blends the two ("The mayor and 11 council members make up the Charlotte City Council");
-- the charter does not, and the charter is the authority on power. So the Mayor gets his own
-- chamber, exactly as Duluth's, Saint Paul's and Miami's mayors do.
--
-- 🟢 The charter's tie-breaking rule is not hypothetical: the Clerk's own 1991-2027 history
-- records that "On May 19, 2025, Mayor Lyles voted to break a tie vote of City Council to
-- appoint Edwin Peacock III to the District 6 vacancy." The rule is recorded in the office
-- description rather than in voting_powers, because voting_powers describes an office's standing
-- in ITS OWN chamber and the Mayor holds his own chamber entire.
--
-- 🔴 THE FOUR AT-LARGE COUNCIL SEATS AND THE THREE AT-LARGE COMMISSION SEATS ARE NOT NUMBERED,
-- AND THIS MIGRATION REFUSES TO NUMBER THEM. Each set is elected in ONE countywide or citywide
-- race. Numbering them would describe a ballot that does not exist. All seats in a set therefore
-- carry the IDENTICAL voter-facing title, and the join key lives in `description` as an internal
-- ordinal that is explicitly not a ballot designation. Same treatment as Duluth (4), Fort Wayne
-- (3) and Gary (3).
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE INCLUSION RULING (Cantrell, 2026-09-17): "If you vote on the DA, they should be
-- included, otherwise they should be omitted." An office is seated if the voters of that
-- jurisdiction elect it. That is why this migration creates a DISTRICT ATTORNEY -- which neither
-- Buncombe nor Durham carries -- and THREE Soil and Water supervisors.
--
-- ⚠ THE SOIL AND WATER BOARD HAS FIVE SUPERVISORS AND ONLY THREE ARE ELECTED. The district's
-- own page: "Three of these supervisors are elected at the same time as the regular election of
-- county officers ... Two supervisors are appointed by the North Carolina Soil and Water
-- Conservation Commission". The two appointed supervisors are DELIBERATELY ABSENT, and the
-- post-verify gate asserts the count is three -- not five.
--
-- ⚠ THE DISTRICT ATTORNEY sits in `Elected Officials` beside the Clerk of Superior Court because
-- both are judicial-branch officers whom county voters elect, and the Clerk is already there in
-- Buncombe and Durham. NC Prosecutorial District 26 is coterminous with Mecklenburg County.
-- ⚠ SOIL AND WATER gets its OWN chamber because the district is legally "a governmental
-- subdivision of the state of North Carolina, and a public body, corporate and politic" -- not
-- part of county government -- and the chamber name is where that fact can live.
--
-- ▶ Buncombe and Durham are seated with three officers and no DA, no Soil and Water and no
-- judges, and their voters elect all of them. That debt is RECORDED, not fixed here; it closes
-- in the judges wave. This migration does not touch either county.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 GEOMETRY COMES FROM scripts/load-charlotte-mecklenburg-boundaries.ts (X0056, X0057), NOT
-- from here, and the pre-flight below FAILS HARD if those thirteen boundaries are absent -- an
-- office on a district with no polygon is unreachable by address and nothing errors.
--
-- 🔴 CHARLOTTE PUBLISHES ITS COUNCIL DISTRICTS FOUR TIMES AND ONE COPY IS FROM 2017, returning
-- seven features numbered 1-7 exactly like the live one. A feature count cannot tell them apart;
-- only the roster comparison can. The loader asserts that; this migration asserts the loader ran
-- and left the right `source` behind.
--
-- ⚠ districts.state is written LOWERCASE 'nc', matching every other NC district in production.
-- Always lower(d.state).
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight: the thirteen district boundaries and both parent polygons ───

DO $$
DECLARE v_c int; v_m int; v_bad int;
BEGIN
  SELECT count(*) INTO v_c FROM essentials.geofence_boundaries WHERE mtfcc = 'X0056';
  IF v_c <> 7 THEN
    RAISE EXCEPTION 'NC-3 pre-flight: X0056 holds % Charlotte council boundaries, expected 7. Run scripts/load-charlotte-mecklenburg-boundaries.ts first.', v_c;
  END IF;
  SELECT count(*) INTO v_m FROM essentials.geofence_boundaries WHERE mtfcc = 'X0057';
  IF v_m <> 6 THEN
    RAISE EXCEPTION 'NC-3 pre-flight: X0057 holds % Mecklenburg commissioner boundaries, expected 6. Run scripts/load-charlotte-mecklenburg-boundaries.ts first.', v_m;
  END IF;

  -- The citywide seats (Mayor, 4 at-large) hang on the TIGER place polygon; every countywide
  -- seat hangs on the county polygon. Both must already exist.
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '3712000' AND mtfcc = 'G4110') THEN
    RAISE EXCEPTION 'NC-3 pre-flight: TIGER place 3712000/G4110 (Charlotte) is missing.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '37119' AND mtfcc = 'G4020') THEN
    RAISE EXCEPTION 'NC-3 pre-flight: county polygon 37119/G4020 (Mecklenburg) is missing.';
  END IF;

  -- 🔴 The council boundaries must have come from the CITY's own service. The loader stamps it.
  SELECT count(*) INTO v_bad FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0056' AND source NOT LIKE '%PLN/CouncilDistricts/MapServer/0%';
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'NC-3 pre-flight: % X0056 boundary/ies did not come from the city''s PLN/CouncilDistricts service -- one copy of this map is from 2017 and returns seven features too.', v_bad;
  END IF;

  -- ⚠ The county district row must already exist and must be the COUNTY one, not House 119.
  IF NOT EXISTS (SELECT 1 FROM essentials.districts
                  WHERE geo_id = '37119' AND mtfcc = 'G4020' AND district_type::text = 'COUNTY') THEN
    RAISE EXCEPTION 'NC-3 pre-flight: the Mecklenburg COUNTY district row (37119/G4020) is missing.';
  END IF;
END $$;

-- ─── 1. Two governments ──────────────────────────────────────────────────────
-- ⚠ Matched and guarded on geo_id, never on name.

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Charlotte, North Carolina, US', 'City', 'NC', 'Charlotte', '3712000'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '3712000');

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Mecklenburg County, North Carolina, US', 'County', 'NC', NULL, '37119'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '37119');

-- ─── 2. Five chambers ────────────────────────────────────────────────────────
-- official_count is what the CHARTER or the STATUTE says the body holds, not what we seat.
-- Soil and Water is 3 because three is what the voters elect; the board of five is not this
-- chamber.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Charlotte City Council', 'Charlotte City Council', 11
FROM essentials.governments g
WHERE g.geo_id = '3712000'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Charlotte City Council');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Office of the Mayor', 'Office of the Mayor of Charlotte', 1
FROM essentials.governments g
WHERE g.geo_id = '3712000'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Office of the Mayor');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Board of County Commissioners', 'Mecklenburg Board of County Commissioners', 9
FROM essentials.governments g
WHERE g.geo_id = '37119'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Board of County Commissioners');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Elected Officials', 'Mecklenburg County Elected Officials', 4
FROM essentials.governments g
WHERE g.geo_id = '37119'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Elected Officials');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, remarks)
SELECT g.id, 'Soil and Water Conservation District',
       'Mecklenburg Soil and Water Conservation District Board of Supervisors', 3,
       'A governmental subdivision of the State of North Carolina, not a department of county government. Its board holds five supervisors; three are elected countywide on a nonpartisan ballot at the regular election of county officers and two are appointed by the North Carolina Soil and Water Conservation Commission. Only the three ELECTED seats are carried here.'
FROM essentials.governments g
WHERE g.geo_id = '37119'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Soil and Water Conservation District');

-- ─── 3. Fourteen districts (13 new + 1 reused) ───────────────────────────────
-- Seven council districts on X0056, one citywide row on the TIGER place polygon, six commissioner
-- districts on X0057. The countywide row (37119/G4020/COUNTY) ALREADY EXISTS and is reused.

CREATE TEMP TABLE nc3_districts(geo_id text, label text, mtfcc text, dtype text) ON COMMIT DROP;
INSERT INTO nc3_districts(geo_id, label, mtfcc, dtype) VALUES
  ('charlotte-nc-council-district-1', 'Charlotte City Council District 1', 'X0056', 'LOCAL'),
  ('charlotte-nc-council-district-2', 'Charlotte City Council District 2', 'X0056', 'LOCAL'),
  ('charlotte-nc-council-district-3', 'Charlotte City Council District 3', 'X0056', 'LOCAL'),
  ('charlotte-nc-council-district-4', 'Charlotte City Council District 4', 'X0056', 'LOCAL'),
  ('charlotte-nc-council-district-5', 'Charlotte City Council District 5', 'X0056', 'LOCAL'),
  ('charlotte-nc-council-district-6', 'Charlotte City Council District 6', 'X0056', 'LOCAL'),
  ('charlotte-nc-council-district-7', 'Charlotte City Council District 7', 'X0056', 'LOCAL'),
  ('3712000',                         'Charlotte Citywide',                'G4110', 'LOCAL'),
  ('mecklenburg-nc-commissioner-district-1', 'Mecklenburg County Commissioner District 1', 'X0057', 'COUNTY'),
  ('mecklenburg-nc-commissioner-district-2', 'Mecklenburg County Commissioner District 2', 'X0057', 'COUNTY'),
  ('mecklenburg-nc-commissioner-district-3', 'Mecklenburg County Commissioner District 3', 'X0057', 'COUNTY'),
  ('mecklenburg-nc-commissioner-district-4', 'Mecklenburg County Commissioner District 4', 'X0057', 'COUNTY'),
  ('mecklenburg-nc-commissioner-district-5', 'Mecklenburg County Commissioner District 5', 'X0057', 'COUNTY'),
  ('mecklenburg-nc-commissioner-district-6', 'Mecklenburg County Commissioner District 6', 'X0057', 'COUNTY');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, n.dtype, 'nc', n.mtfcc
FROM nc3_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc);

-- ─── 4. Twenty-eight offices ─────────────────────────────────────────────────

CREATE TEMP TABLE nc3_offices(
  gov_geo_id text, district_geo_id text, district_mtfcc text,
  chamber_name text, title text, description text, city text) ON COMMIT DROP;

INSERT INTO nc3_offices VALUES
  -- Charlotte: the Mayor, in his own chamber, with the charter's vote rule recorded.
  ('3712000','3712000','G4110','Office of the Mayor','Mayor',
   'Elected citywide to a two-year term. Charlotte City Charter (S.L. 2000-26) s 3.23: the Mayor "shall preside, if present, but shall have no vote except in case of a tie, or as provided herein", and may veto an action of the Council, which requires at least seven members voting in the affirmative to override.','Charlotte'),
  -- Charlotte: four UNNUMBERED at-large council seats, one citywide race.
  ('3712000','3712000','G4110','Charlotte City Council','Council Member, At Large',
   'Internal ordinal 1 of 4. Charlotte does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.','Charlotte'),
  ('3712000','3712000','G4110','Charlotte City Council','Council Member, At Large',
   'Internal ordinal 2 of 4. Charlotte does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.','Charlotte'),
  ('3712000','3712000','G4110','Charlotte City Council','Council Member, At Large',
   'Internal ordinal 3 of 4. Charlotte does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.','Charlotte'),
  ('3712000','3712000','G4110','Charlotte City Council','Council Member, At Large',
   'Internal ordinal 4 of 4. Charlotte does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.','Charlotte'),
  -- Charlotte: seven single-member districts.
  ('3712000','charlotte-nc-council-district-1','X0056','Charlotte City Council','Council Member, District 1',NULL,'Charlotte'),
  ('3712000','charlotte-nc-council-district-2','X0056','Charlotte City Council','Council Member, District 2',NULL,'Charlotte'),
  ('3712000','charlotte-nc-council-district-3','X0056','Charlotte City Council','Council Member, District 3',NULL,'Charlotte'),
  ('3712000','charlotte-nc-council-district-4','X0056','Charlotte City Council','Council Member, District 4',NULL,'Charlotte'),
  ('3712000','charlotte-nc-council-district-5','X0056','Charlotte City Council','Council Member, District 5',NULL,'Charlotte'),
  ('3712000','charlotte-nc-council-district-6','X0056','Charlotte City Council','Council Member, District 6',NULL,'Charlotte'),
  ('3712000','charlotte-nc-council-district-7','X0056','Charlotte City Council','Council Member, District 7',NULL,'Charlotte'),
  -- Mecklenburg: three UNNUMBERED at-large commission seats, one countywide race.
  ('37119','37119','G4020','Board of County Commissioners','Commissioner, At Large',
   'Internal ordinal 1 of 3. Mecklenburg does not number its at-large seats; all three are elected in one countywide race. Not a ballot designation.',NULL),
  ('37119','37119','G4020','Board of County Commissioners','Commissioner, At Large',
   'Internal ordinal 2 of 3. Mecklenburg does not number its at-large seats; all three are elected in one countywide race. Not a ballot designation.',NULL),
  ('37119','37119','G4020','Board of County Commissioners','Commissioner, At Large',
   'Internal ordinal 3 of 3. Mecklenburg does not number its at-large seats; all three are elected in one countywide race. Not a ballot designation.',NULL),
  -- Mecklenburg: six single-member commission districts.
  ('37119','mecklenburg-nc-commissioner-district-1','X0057','Board of County Commissioners','Commissioner, District 1',NULL,NULL),
  ('37119','mecklenburg-nc-commissioner-district-2','X0057','Board of County Commissioners','Commissioner, District 2',NULL,NULL),
  ('37119','mecklenburg-nc-commissioner-district-3','X0057','Board of County Commissioners','Commissioner, District 3',NULL,NULL),
  ('37119','mecklenburg-nc-commissioner-district-4','X0057','Board of County Commissioners','Commissioner, District 4',NULL,NULL),
  ('37119','mecklenburg-nc-commissioner-district-5','X0057','Board of County Commissioners','Commissioner, District 5',NULL,NULL),
  ('37119','mecklenburg-nc-commissioner-district-6','X0057','Board of County Commissioners','Commissioner, District 6',NULL,NULL),
  -- ⚠ NO 'Chair, Board of Commissioners' OFFICE. Mecklenburg's chair is elected BY THE BOARD from
  -- among its nine members immediately after the swearing-in, so it is a designation, not a seat.
  -- Buncombe carries a Chair office because BUNCOMBE'S CHAIR IS ELECTED COUNTYWIDE. The template
  -- does not transfer, even inside one state.
  -- Mecklenburg: the separately elected officers.
  ('37119','37119','G4020','Elected Officials','Sheriff',NULL,NULL),
  ('37119','37119','G4020','Elected Officials','Register of Deeds',NULL,NULL),
  ('37119','37119','G4020','Elected Officials','Clerk of Superior Court',NULL,NULL),
  ('37119','37119','G4020','Elected Officials','District Attorney',
   'Elected countywide. North Carolina Prosecutorial District 26 is coterminous with Mecklenburg County. A judicial-branch officer whom county voters elect, seated here under the inclusion ruling of 2026-09-17.',NULL),
  -- Mecklenburg: the three ELECTED soil and water supervisors. The two state-appointed
  -- supervisors are deliberately absent.
  ('37119','37119','G4020','Soil and Water Conservation District','Soil and Water Conservation District Supervisor',
   'Internal ordinal 1 of 3. Elected countywide on a nonpartisan ballot; the seats are not numbered. Not a ballot designation.',NULL),
  ('37119','37119','G4020','Soil and Water Conservation District','Soil and Water Conservation District Supervisor',
   'Internal ordinal 2 of 3. Elected countywide on a nonpartisan ballot; the seats are not numbered. Not a ballot designation.',NULL),
  ('37119','37119','G4020','Soil and Water Conservation District','Soil and Water Conservation District Supervisor',
   'Internal ordinal 3 of 3. Elected countywide on a nonpartisan ballot; the seats are not numbered. Not a ballot designation.',NULL);

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'NC', n.city, 1, false, 'full'
FROM nc3_offices n
JOIN essentials.districts d ON d.geo_id = n.district_geo_id AND d.mtfcc = n.district_mtfcc AND lower(d.state) = 'nc'
JOIN essentials.governments g ON g.geo_id = n.gov_geo_id
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
    AND o.description IS NOT DISTINCT FROM n.description);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch int; v_dist int; v_off int;
  v_clt int; v_meck int; v_al int; v_al_d int; v_cal int; v_cal_d int; v_sw int; v_sw_d int;
  v_buncombe int; v_durham int; v_house119 int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE geo_id IN ('3712000','37119');
  IF v_gov <> 2 THEN RAISE EXCEPTION 'NC-3 structure: expected 2 governments, got %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.geo_id IN ('3712000','37119');
  IF v_ch <> 5 THEN RAISE EXCEPTION 'NC-3 structure: expected 5 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE lower(state) = 'nc' AND mtfcc IN ('X0056','X0057');
  IF v_dist <> 13 THEN RAISE EXCEPTION 'NC-3 structure: expected 13 new districts, got %', v_dist; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('3712000','37119');
  IF v_off <> 28 THEN RAISE EXCEPTION 'NC-3 structure: expected 28 offices, got %', v_off; END IF;

  SELECT count(*) INTO v_clt FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.geo_id = '3712000';
  SELECT count(*) INTO v_meck FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.geo_id = '37119';
  IF v_clt <> 12 OR v_meck <> 16 THEN
    RAISE EXCEPTION 'NC-3 structure: expected Charlotte 12 / Mecklenburg 16, got % / %', v_clt, v_meck;
  END IF;

  -- The unnumbered sets must each hold the right count with DISTINCT internal ordinals, without
  -- which CC_0118 cannot attach a person to a seat deterministically.
  SELECT count(*), count(DISTINCT o.description) INTO v_al, v_al_d
  FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id = '3712000' AND o.title = 'Council Member, At Large';
  IF v_al <> 4 OR v_al_d <> 4 THEN
    RAISE EXCEPTION 'NC-3 structure: Charlotte at-large is % office(s) with % distinct description(s), expected 4 and 4', v_al, v_al_d;
  END IF;

  SELECT count(*), count(DISTINCT o.description) INTO v_cal, v_cal_d
  FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id = '37119' AND o.title = 'Commissioner, At Large';
  IF v_cal <> 3 OR v_cal_d <> 3 THEN
    RAISE EXCEPTION 'NC-3 structure: Mecklenburg at-large is % office(s) with % distinct description(s), expected 3 and 3', v_cal, v_cal_d;
  END IF;

  -- 🔴 THREE soil and water supervisors, not five. The two state-appointed seats are not elected.
  SELECT count(*), count(DISTINCT o.description) INTO v_sw, v_sw_d
  FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id = '37119' AND c.name = 'Soil and Water Conservation District';
  IF v_sw <> 3 OR v_sw_d <> 3 THEN
    RAISE EXCEPTION 'NC-3 structure: soil and water is % office(s) with % distinct description(s), expected 3 and 3 -- the board has five supervisors but only three are elected', v_sw, v_sw_d;
  END IF;

  -- Mecklenburg must have NO separately elected Chair office. Its chair is chosen by the board.
  IF EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.geo_id = '37119' AND o.title ILIKE '%chair%'
  ) THEN
    RAISE EXCEPTION 'NC-3 structure: Mecklenburg has a Chair office; its chair is elected by the board, not by the voters';
  END IF;

  -- Every district-based seat must carry exactly one office.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE d.mtfcc IN ('X0056','X0057') AND lower(d.state) = 'nc'
    GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'NC-3 structure: a council or commissioner district does not carry exactly one office';
  END IF;

  -- 🔴 The two already-seated NC counties must be untouched, and State House District 119 -- which
  -- shares the geo_id 37119 -- must still hold exactly its one office.
  SELECT count(*) INTO v_buncombe FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.geo_id = '37021';
  SELECT count(*) INTO v_durham FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.geo_id = '37063';
  IF v_buncombe <> 10 OR v_durham <> 8 THEN
    RAISE EXCEPTION 'NC-3 structure: Buncombe/Durham office counts moved (% / %), expected 10 / 8', v_buncombe, v_durham;
  END IF;

  SELECT count(*) INTO v_house119 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37119' AND d.mtfcc = 'G5220';
  IF v_house119 <> 1 THEN
    RAISE EXCEPTION 'NC-3 structure: State House District 119 (which shares geo_id 37119) holds % offices, expected 1', v_house119;
  END IF;

  RAISE NOTICE 'NC-3 structure OK: % governments, % chambers, % new districts, % offices (Charlotte % / Mecklenburg %)',
    v_gov, v_ch, v_dist, v_off, v_clt, v_meck;
END $$;

COMMIT;
