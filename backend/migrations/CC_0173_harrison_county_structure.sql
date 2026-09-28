-- CC_0173_harrison_county_structure.sql
-- Knight Foundation program, wave MS-4 (structure half). Slot RESERVED from the allocator.
--
-- Harrison County holds NO government row, NO chamber and NO office today. Measured 2026-09-28:
-- production knows it only as a COUNTY districts row (G4020 / 28047, government_id NULL, 0 offices)
-- and the TIGER county polygon. This migration creates:
--
--   1. one government, 'Harrison County, Mississippi, US';
--   2. five chambers -- the Board of Supervisors, the countywide Elected Officials, the Justice
--      Court, the Constables and the Election Commission;
--   3. five new districts -- the supervisor districts -- and adopts the EXISTING county row;
--   4. twenty-seven offices -- 5 supervisors + 7 countywide + 5 justice court judges +
--      5 constables + 5 election commissioners.
--
-- Creates NO people and NO terms -- CC_0174 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE INVENTORY IS THE SECRETARY OF STATE'S CERTIFIED BALLOT, NOT THE COUNTY'S OWN SENTENCE.
--
-- ⚠ THE COUNTY'S OWN "Elected Officials" PAGE IS AN OPEN LIST AND CANNOT BE THE INVENTORY. It
-- reads: "In Harrison County, these elected officials INCLUDE; the Board of Supervisors, Sherriff,
-- Circuit Clerk, Chancery Clerk, Tax Collector, Tax Assessor, District Attorney, Coroner, Election
-- Officials, and County Prosecutor." The word is "include"; it omits the Justice Court Judges and
-- the Constables, both of which Mississippi certainly elects and both of which are on the ballot
-- below. A list that says "include" is a lead, not an enumeration -- and the county's own site
-- files the Justice Court under DEPARTMENTS, beside Mosquito Control, which is exactly the Grand
-- Forks trap: a site's menu grouping is not the elected/appointed line.
--
-- 🟢 THE ENUMERATION IS THE MISSISSIPPI SECRETARY OF STATE'S "Official Recapitulation, 2023 General
-- Election, Harrison County" -- the certification the County Election Commission signed on
-- 2023-11-17 and filed with the Secretary of State, read page by page. Mississippi county offices
-- run on one four-year cycle, so one general election lists them all. Twenty-two county contests
-- appear, and nothing else:
--
--   Chancery Clerk · Circuit Clerk · Coroner · County Attorney · Sheriff · Tax Assessor ·
--   Tax Collector · Supervisor Districts 1-5 · Justice Court Judge Districts 1-5 ·
--   Constable Districts 1-5
--
-- ⚠ THE ELECTION COMMISSION IS THE EXCEPTION THAT BREAKS THE "ONE CYCLE" ARGUMENT, AND IT IS
-- RECORDED RATHER THAN SMOOTHED OVER. Only TWO election commissioner contests were on the 2023
-- ballot -- Districts 2 and 4. The county's own Election Commission page names FIVE sitting
-- commissioners, and the certification page of the recapitulation itself carries five signature
-- lines, one per district. So Biloxi's argument (one ballot enumerates everything) holds for the
-- other twenty-two offices and does NOT hold here. All five are created; CC_0174 dates only the
-- two the certified results cover and leaves the other three honestly unknown.
--
-- ⚠ THE DISTRICT ATTORNEY IS DELIBERATELY NOT CREATED. "District Attorney 02 - District 02"
-- (W. Crosby Parker) is on the same ballot, but the office is elected by the SECOND CIRCUIT COURT
-- DISTRICT, which is Harrison, Hancock and Stone counties together. It is not a Harrison County
-- office, and this database holds no geometry for the circuit court districts, so seating it here
-- would attach a three-county officer to a one-county polygon. Recorded as a debt, not created.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢🟢 ONE GEOMETRY CARRIES TWENTY OFFICES, AND IT WAS PROVED, NOT ASSUMED.
--
-- Four different office sets are elected from five districts each. Miss. Code § 9-11-2 lets the
-- board of supervisors draw the justice court districts, so they need not be the beats -- "they
-- are obviously the same" is precisely the assumption this programme refuses.
-- ▶ The 2023 recapitulation settles it PRECINCT BY PRECINCT: the precincts that cast votes in
-- Supervisor District N are exactly those that cast votes in Justice Court Judge District N and
-- Constable District N, and Election Commissioner Districts 2 and 4 match Supervisor 2 and 4. The
-- county totals corroborate it: Supervisor 4,728 / 7,761 / 9,146 / 5,676 / 7,814 against Constable
-- 4,754 / 7,842 / 9,159 / 5,745 / 7,792 -- one electorate counted twice, not two that are close.
-- ▶ So the twenty district offices hang on FIVE district rows, four offices each.
--
-- ⚠ THE JUSTICE COURT JUDGES ARE JUDICIAL AND THEIR DISTRICTS ARE NOT MARKED is_judicial. The flag
-- lives on the district, and these districts also carry supervisors, constables and election
-- commissioners, who are not judicial. Marking the district would mislabel the other fifteen.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS MIGRATION REFUSES TO RUN IF THE FIVE SUPERVISOR POLYGONS ARE ABSENT. An office on a
-- district with no polygon is unreachable by any address, and NOTHING ERRORS.
-- scripts/load-harrison-supervisor-districts.mjs must have run first; it writes X0074 and carries
-- its own eight controls, every one watched failing.
--
-- 🔴 X0074 IS READ, NOT COUNTED. max(mtfcc) over BOTH essentials.geofence_boundaries and
-- essentials.districts read X0073 (Biloxi, MS-3) on 2026-09-28, in the same session as the write.
--
-- 🔴 THE COUNTY DISTRICT ROW IS ADOPTED, NOT CREATED. (G4020, 28047) already exists with
-- government_id NULL and 0 offices. Creating a second Harrison County row would split the county
-- in two and leave half of it unreachable. The UPDATE below is guarded to touch only a NULL.
-- ⚠ AND 28047 IS THE WORST geo_id IN THE PROGRAMME: Senate District 47, House District 47 and
-- Harrison County are ALL '28047'. Every join pairs geo_id WITH mtfcc.
--
-- 🔴 PARTY IS NOT WRITTEN, though the certified results give it for all 27. Party lives on
-- races.primary_party in this database and never on a person or an office.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded and the one UPDATE is condition-guarded. Ends
-- with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight ───────────────────────────────────────────────────────────

DO $$
DECLARE
  v_sup   int;
  v_alien int;
  v_cty   int;
  v_rows  int;
BEGIN
  SELECT count(*) INTO v_sup FROM essentials.geofence_boundaries WHERE mtfcc = 'X0074';
  IF v_sup <> 5 THEN
    RAISE EXCEPTION 'MS-4 pre-flight: expected 5 X0074 Harrison County supervisor polygons, found % — run scripts/load-harrison-supervisor-districts.mjs first. An office on a district with no polygon is unreachable by any address and nothing errors.', v_sup;
  END IF;

  SELECT count(*) INTO v_alien FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0074' AND geo_id NOT LIKE 'harrison-ms-supervisor-district-%';
  IF v_alien <> 0 THEN
    RAISE EXCEPTION 'MS-4 pre-flight: % X0074 polygon(s) are not Harrison County supervisor districts — somebody else took this code', v_alien;
  END IF;

  SELECT count(*) INTO v_cty FROM essentials.geofence_boundaries
   WHERE geo_id = '28047' AND mtfcc = 'G4020';
  IF v_cty <> 1 THEN
    RAISE EXCEPTION 'MS-4 pre-flight: expected the TIGER county polygon 28047/G4020, found %', v_cty;
  END IF;

  -- 🔴 The county districts row must already exist and must be unique on (geo_id, mtfcc).
  SELECT count(*) INTO v_rows FROM essentials.districts
   WHERE geo_id = '28047' AND mtfcc = 'G4020' AND district_type = 'COUNTY' AND lower(state) = 'ms';
  IF v_rows <> 1 THEN
    RAISE EXCEPTION 'MS-4 pre-flight: expected exactly 1 Harrison County COUNTY districts row (28047/G4020), found %', v_rows;
  END IF;
END $$;

-- ─── 1. The government ───────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Harrison County, Mississippi, US', 'County', 'MS', NULL, '28047'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Harrison County, Mississippi, US');

-- ─── 2. Five chambers ────────────────────────────────────────────────────────
-- term_length 4 for every one: Mississippi county officers serve four-year terms, and the Board's
-- own minutes of 2024-01-02 say so in terms -- "for the term of four years commencing on this date".

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, '4'
FROM essentials.governments g
JOIN (VALUES
  ('Harrison County Board of Supervisors', 5),
  ('Harrison County Elected Officials',    7),
  ('Harrison County Justice Court',        5),
  ('Harrison County Constables',           5),
  ('Harrison County Election Commission',  5)
) AS v(name, official_count) ON true
WHERE g.name = 'Harrison County, Mississippi, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Five supervisor districts, and adopt the existing county row ─────────

CREATE TEMP TABLE hc_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO hc_districts(geo_id, label, mtfcc) VALUES
  ('harrison-ms-supervisor-district-1', 'Harrison County Supervisor District 1', 'X0074'),
  ('harrison-ms-supervisor-district-2', 'Harrison County Supervisor District 2', 'X0074'),
  ('harrison-ms-supervisor-district-3', 'Harrison County Supervisor District 3', 'X0074'),
  ('harrison-ms-supervisor-district-4', 'Harrison County Supervisor District 4', 'X0074'),
  ('harrison-ms-supervisor-district-5', 'Harrison County Supervisor District 5', 'X0074');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'ms', n.mtfcc
FROM hc_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL');

-- 🔴 Guarded: only ever fills a NULL. If some other wave has already claimed this row, this
-- migration must not silently re-point it, and the gate below will notice.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE g.name = 'Harrison County, Mississippi, US'
   AND d.geo_id = '28047' AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY'
   AND d.government_id IS NULL;

-- ─── 4. Twenty-seven offices ─────────────────────────────────────────────────

CREATE TEMP TABLE hc_offices(geo_id text, mtfcc text, chamber_name text, title text) ON COMMIT DROP;
INSERT INTO hc_offices(geo_id, mtfcc, chamber_name, title) VALUES
  -- countywide, on the county polygon
  ('28047', 'G4020', 'Harrison County Elected Officials', 'Chancery Clerk'),
  ('28047', 'G4020', 'Harrison County Elected Officials', 'Circuit Clerk'),
  ('28047', 'G4020', 'Harrison County Elected Officials', 'Coroner'),
  -- ⚠ The ballot prints "County Attorney"; the county's own page and Miss. Code s 19-23-1 both
  -- call the office the County Prosecuting Attorney, which is what a voter is told it does.
  ('28047', 'G4020', 'Harrison County Elected Officials', 'County Prosecuting Attorney'),
  ('28047', 'G4020', 'Harrison County Elected Officials', 'Sheriff'),
  ('28047', 'G4020', 'Harrison County Elected Officials', 'Tax Assessor'),
  ('28047', 'G4020', 'Harrison County Elected Officials', 'Tax Collector'),
  -- four offices on each supervisor district
  ('harrison-ms-supervisor-district-1', 'X0074', 'Harrison County Board of Supervisors', 'Supervisor, District 1'),
  ('harrison-ms-supervisor-district-2', 'X0074', 'Harrison County Board of Supervisors', 'Supervisor, District 2'),
  ('harrison-ms-supervisor-district-3', 'X0074', 'Harrison County Board of Supervisors', 'Supervisor, District 3'),
  ('harrison-ms-supervisor-district-4', 'X0074', 'Harrison County Board of Supervisors', 'Supervisor, District 4'),
  ('harrison-ms-supervisor-district-5', 'X0074', 'Harrison County Board of Supervisors', 'Supervisor, District 5'),
  ('harrison-ms-supervisor-district-1', 'X0074', 'Harrison County Justice Court', 'Justice Court Judge, District 1'),
  ('harrison-ms-supervisor-district-2', 'X0074', 'Harrison County Justice Court', 'Justice Court Judge, District 2'),
  ('harrison-ms-supervisor-district-3', 'X0074', 'Harrison County Justice Court', 'Justice Court Judge, District 3'),
  ('harrison-ms-supervisor-district-4', 'X0074', 'Harrison County Justice Court', 'Justice Court Judge, District 4'),
  ('harrison-ms-supervisor-district-5', 'X0074', 'Harrison County Justice Court', 'Justice Court Judge, District 5'),
  ('harrison-ms-supervisor-district-1', 'X0074', 'Harrison County Constables', 'Constable, District 1'),
  ('harrison-ms-supervisor-district-2', 'X0074', 'Harrison County Constables', 'Constable, District 2'),
  ('harrison-ms-supervisor-district-3', 'X0074', 'Harrison County Constables', 'Constable, District 3'),
  ('harrison-ms-supervisor-district-4', 'X0074', 'Harrison County Constables', 'Constable, District 4'),
  ('harrison-ms-supervisor-district-5', 'X0074', 'Harrison County Constables', 'Constable, District 5'),
  ('harrison-ms-supervisor-district-1', 'X0074', 'Harrison County Election Commission', 'Election Commissioner, District 1'),
  ('harrison-ms-supervisor-district-2', 'X0074', 'Harrison County Election Commission', 'Election Commissioner, District 2'),
  ('harrison-ms-supervisor-district-3', 'X0074', 'Harrison County Election Commission', 'Election Commissioner, District 3'),
  ('harrison-ms-supervisor-district-4', 'X0074', 'Harrison County Election Commission', 'Election Commissioner, District 4'),
  ('harrison-ms-supervisor-district-5', 'X0074', 'Harrison County Election Commission', 'Election Commissioner, District 5');

-- 🔴 The guard keys on (district, chamber, TITLE), not on (district, chamber). Four offices share
-- each supervisor district and each chamber holds five of them, so a (district, chamber) guard
-- would be right here by accident and a (district) guard would seat one office per district and
-- silently drop fifteen. The title is what distinguishes them.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, 'MS', NULL, 1, false, 'full'
FROM hc_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND lower(d.state) = 'ms'
JOIN essentials.governments g ON g.name = 'Harrison County, Mississippi, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = n.title);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov     int;
  v_ch      int;
  v_dist    int;
  v_off     int;
  v_per     int;
  v_county  int;
  v_wrongd  int;
  v_titles  int;
  v_vacant  int;
  v_nogeom  int;
  v_govid   int;
  v_biloxi  int;
  v_leg     int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'Harrison County, Mississippi, US';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'MS-4 gate: expected exactly 1 Harrison County government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Harrison County, Mississippi, US';
  IF v_ch <> 5 THEN
    RAISE EXCEPTION 'MS-4 gate: expected 5 Harrison County chambers, found %', v_ch;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE mtfcc = 'X0074' AND district_type = 'LOCAL' AND lower(state) = 'ms';
  IF v_dist <> 5 THEN
    RAISE EXCEPTION 'MS-4 gate: expected 5 Harrison County supervisor districts, found %', v_dist;
  END IF;

  -- 🔴 The county row must be ADOPTED, not duplicated.
  SELECT count(*) INTO v_county FROM essentials.districts
   WHERE geo_id = '28047' AND mtfcc = 'G4020' AND district_type = 'COUNTY' AND lower(state) = 'ms';
  IF v_county <> 1 THEN
    RAISE EXCEPTION 'MS-4 gate: expected exactly 1 Harrison County COUNTY district row, found % — a second one would split the county', v_county;
  END IF;

  SELECT count(*) INTO v_govid FROM essentials.districts d
    JOIN essentials.governments g ON g.id = d.government_id
   WHERE d.geo_id = '28047' AND d.mtfcc = 'G4020'
     AND g.name = 'Harrison County, Mississippi, US';
  IF v_govid <> 1 THEN
    RAISE EXCEPTION 'MS-4 gate: the Harrison County district row does not point at the Harrison County government';
  END IF;

  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Harrison County, Mississippi, US';
  IF v_off <> 27 THEN
    RAISE EXCEPTION 'MS-4 gate: expected 27 Harrison County offices, found %', v_off;
  END IF;

  -- 🔴 EVERY supervisor district must hold EXACTLY FOUR offices — one supervisor, one justice court
  -- judge, one constable, one election commissioner. A total of 20 is also what four districts with
  -- five and one with none would give, and that last district would be silently unreachable.
  SELECT count(*) INTO v_wrongd
    FROM essentials.districts d
   WHERE d.mtfcc = 'X0074' AND lower(d.state) = 'ms'
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 4;
  IF v_wrongd <> 0 THEN
    RAISE EXCEPTION 'MS-4 gate: % supervisor district(s) do not hold exactly 4 offices', v_wrongd;
  END IF;

  -- 🔴 And each CHAMBER must hold the right number, so that "4 per district" cannot be satisfied by
  -- four supervisors and no constable in one district and the reverse in another.
  SELECT count(*) INTO v_per FROM (
    SELECT c.name, count(*) AS n
      FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Harrison County, Mississippi, US'
     GROUP BY c.name
    HAVING count(*) <> CASE c.name WHEN 'Harrison County Elected Officials' THEN 7 ELSE 5 END) x;
  IF v_per <> 0 THEN
    RAISE EXCEPTION 'MS-4 gate: % Harrison County chamber(s) hold the wrong number of offices', v_per;
  END IF;

  SELECT count(DISTINCT o.title) INTO v_titles
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Harrison County, Mississippi, US';
  IF v_titles <> 27 THEN
    RAISE EXCEPTION 'MS-4 gate: expected 27 distinct Harrison County office titles, found %', v_titles;
  END IF;

  SELECT count(*) INTO v_vacant
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Harrison County, Mississippi, US' AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'MS-4 gate: expected 0 vacant Harrison County offices, found %', v_vacant;
  END IF;

  SELECT count(*) INTO v_nogeom
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'Harrison County, Mississippi, US'
     AND NOT EXISTS (
       SELECT 1 FROM essentials.geofence_boundaries b
        WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'MS-4 gate: % Harrison County office(s) sit on a district with NO polygon — unreachable by any address', v_nogeom;
  END IF;

  -- 🔴 CONTROLS, IN THE SAME TRANSACTION: the two waves this slice already applied must be untouched.
  SELECT count(*) INTO v_biloxi
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US';
  IF v_biloxi <> 8 THEN
    RAISE EXCEPTION 'MS-4 gate CONTROL: expected 8 Biloxi offices from MS-3, found %', v_biloxi;
  END IF;

  SELECT count(*) INTO v_leg
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc IN ('G5210', 'G5220') AND lower(d.state) = 'ms';
  IF v_leg <> 174 THEN
    RAISE EXCEPTION 'MS-4 gate CONTROL: expected 174 Mississippi legislative offices from MS-2, found %', v_leg;
  END IF;

  RAISE NOTICE 'MS-4 structure gate PASSED: 1 government, 5 chambers, 5 supervisor districts + the adopted county row, 27 offices (7 countywide + 4 on each of 5 districts), 27 distinct titles, 0 vacant, every office on a district with geometry; Biloxi 8 and the MS legislature 174 unmoved.';
END $$;

COMMIT;
