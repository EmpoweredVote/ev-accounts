-- CC_0322_hinds_county_structure.sql
-- Hinds County, Mississippi deep seed (structure half). Slot RESERVED from the allocator.
--
-- Hinds County exists in production ONLY as a TIGER county polygon (28049 / G4020) and a districts
-- row carrying ZERO offices. This migration creates:
--
--   1. one government, 'Hinds County, Mississippi, US';
--   2. five chambers -- Board of Supervisors, Constables, Elected Officials, Election Commission,
--      Justice Court -- the same five MS-4 created for Harrison County;
--   3. five LOCAL districts for the supervisor districts, ADOPTING the county row for countywide;
--   4. twenty-eight offices -- 8 countywide + 4 each on the five supervisor districts.
--
-- Creates NO people and NO terms -- CC_0323 does that, and the two are applied back to back.
-- Record: backend/data/seed-jackson-ms-2026/ROSTERS.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE INVENTORY IS 28, FROM THE SECRETARY-CERTIFIED COUNTY RESULTS.
--
-- Hinds County's own website publishes certified results back to 1999. The 2023 county cycle is
-- the inventory. 🔴 THE LINK LABEL AND THE FILENAME DISAGREE AND THE DOCUMENT SETTLES IT: the row
-- headed "Tuesday, November 07, 2023 - Hinds County General Election" links to files named
-- "20230711 ...", and the PDF's own first page reads "Summary Results Report Official Election
-- Results - 2023 General Election Hinds County - November 7, 2023". The digits are transposed.
--
--   countywide (8)  Chancery Clerk, Circuit Clerk, Coroner, County Attorney, COUNTY SURVEYOR,
--                   Sheriff, Tax Assessor, Tax Collector
--   per district    Supervisor 1-5, Justice Court Judge 1-5, Constable 1-5,
--                   Election Commissioner 1-5
--
-- 🔴🔴 HINDS IS NOT HARRISON, AND THE DIFFERENCES ARE REAL OFFICES. Harrison has NO County
-- Surveyor and elects no school board; Hinds elects both. Harrison's countywide office is a
-- "County Prosecuting Attorney"; Hinds's is a "County Attorney". Reusing MS-4's 27-office template
-- would have missed two kinds of office outright. This is feedback_describe_offices_dont_standardise
-- paying for itself inside one state, one wave apart.
--
-- ⚠ ONE BALLOT DOES NOT ENUMERATE A MISSISSIPPI COUNTY. Only Election Commissioners 2 and 4 were on
-- the 2023 ballot, and only one school board seat. MS-4 recorded this for Harrison and it holds
-- again. The full Election Commission comes from the county's own published phone book, which names
-- all five; see CC_0323.
--
-- ⚠ TWO OFFICES ARE DELIBERATELY NOT SEATED, AND BOTH ARE RECORDED RATHER THAN QUIETLY DROPPED:
--   ▶ DISTRICT ATTORNEY, Circuit Court District 7. Elected by a multi-county circuit, exactly like
--     Harrison's Second Circuit DA. Hanging it on a one-county polygon would be wrong.
--   ▶ THE HINDS COUNTY SCHOOL DISTRICT BOARD. It is a DIFFERENT GOVERNMENT with its own boundary
--     (a TIGER unified school district), serving the county outside Jackson. It is not a county
--     office and this wave has not loaded its geometry.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢🟢 THE SUPERVISOR DISTRICTS ARE TIGER COUNTY SUBDIVISIONS, SO THERE IS NO `X` CODE HERE.
--
-- In Mississippi the county subdivisions ARE the supervisor districts (the old "beats"). Measured
-- statewide: all 82 counties have exactly five G4040 subdivisions named "District 1" .. "District
-- 5", which is Miss. Const. art. 6 s 170. The geo_ids below are the Census Bureau's own COUSUB
-- GEOIDs.
--
-- 🔴 AND THE NUMBERING WAS PROVED BEFORE IT WAS USED. Harrison's own ArcGIS layer carried a
-- `DIST_ID` that was a CLEAN PERMUTATION of exactly the right five values (MS-4).
-- scripts/verify-ms-cousub-are-supervisor-districts.mjs therefore overlaps TIGER's five HARRISON
-- subdivisions against the X0074 polygons MS-4 anchored on 18 certified precincts, the county's own
-- 49 polling places and the certified winners: diagonal strongest 5/5, and 0/5 with the labels
-- rotated. The method is validated on a county anchored the hard way, then applied to Hinds.
--
-- ⚠ HARRISON'S FIVE ARE ON X0074 AND HINDS'S ARE ON G4040. Two counties now hold the same kind of
-- thing two different ways. Harrison's rows are correct and anchored and are NOT touched here; the
-- inconsistency is a debt in the slice record, not something to normalise in a seeding migration.
--
-- 🔴 EVERY JOIN PAIRS geo_id WITH mtfcc. '28049' is Hinds County (G4020), State Senate District 49
-- (G5210) AND State House District 49 (G5220) -- three rows in production differing only by mtfcc.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_sup   int;
  v_cty   int;
  v_exist int;
BEGIN
  SELECT count(*) INTO v_sup FROM essentials.geofence_boundaries
   WHERE mtfcc = 'G4040' AND geo_id IN ('2804990225','2804990963','2804991701','2804992439','2804993177');
  IF v_sup <> 5 THEN
    RAISE EXCEPTION 'Hinds pre-flight: expected 5 G4040 supervisor-district polygons from the loader, found %', v_sup;
  END IF;

  SELECT count(*) INTO v_cty FROM essentials.geofence_boundaries
   WHERE geo_id = '28049' AND mtfcc = 'G4020';
  IF v_cty <> 1 THEN
    RAISE EXCEPTION 'Hinds pre-flight: expected the TIGER county polygon 28049/G4020, found %', v_cty;
  END IF;

  SELECT count(*) INTO v_exist FROM essentials.governments
   WHERE geo_id = '28049' OR name ILIKE '%Hinds County, Mississippi%';
  IF v_exist <> 0 THEN
    RAISE EXCEPTION 'Hinds pre-flight: % government row(s) for Hinds already exist — merge, do not duplicate', v_exist;
  END IF;
END $$;

-- ─── 1. The government ───────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Hinds County, Mississippi, US', 'County', 'MS', NULL, '28049'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Hinds County, Mississippi, US');

-- ─── 2. Five chambers ────────────────────────────────────────────────────────
-- Four-year terms throughout: Miss. Code s 19-3-1 (supervisors) and the Board's own organising
-- minute of 2024-01-02, which resolves "to approve the Bonds of the Board of Supervisors for the
-- four-year term ... per Section 25-1-19".

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, '4'
FROM essentials.governments g
JOIN (VALUES
  ('Hinds County Board of Supervisors', 5),
  ('Hinds County Constables',           5),
  ('Hinds County Elected Officials',    8),
  ('Hinds County Election Commission',  5),
  ('Hinds County Justice Court',        5)
) AS v(name, official_count) ON true
WHERE g.name = 'Hinds County, Mississippi, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Five supervisor districts; the county row is ADOPTED, not created ────

CREATE TEMP TABLE hc_districts(geo_id text, label text) ON COMMIT DROP;
INSERT INTO hc_districts(geo_id, label) VALUES
  ('2804990225', 'Hinds County Supervisor District 1'),
  ('2804990963', 'Hinds County Supervisor District 2'),
  ('2804991701', 'Hinds County Supervisor District 3'),
  ('2804992439', 'Hinds County Supervisor District 4'),
  ('2804993177', 'Hinds County Supervisor District 5');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'ms', 'G4040'
FROM hc_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = 'G4040' AND d.district_type = 'LOCAL');

-- ─── 4. Twenty-eight offices ─────────────────────────────────────────────────

CREATE TEMP TABLE hc_offices(geo_id text, mtfcc text, chamber_name text, title text) ON COMMIT DROP;

-- 8 countywide, on the county polygon
INSERT INTO hc_offices(geo_id, mtfcc, chamber_name, title) VALUES
  ('28049','G4020','Hinds County Elected Officials','Chancery Clerk'),
  ('28049','G4020','Hinds County Elected Officials','Circuit Clerk'),
  ('28049','G4020','Hinds County Elected Officials','Coroner'),
  ('28049','G4020','Hinds County Elected Officials','County Attorney'),
  ('28049','G4020','Hinds County Elected Officials','County Surveyor'),
  ('28049','G4020','Hinds County Elected Officials','Sheriff'),
  ('28049','G4020','Hinds County Elected Officials','Tax Assessor'),
  ('28049','G4020','Hinds County Elected Officials','Tax Collector');

-- 20 district offices: four sets of five, all on the SAME five polygons.
-- ⚠ THE JUSTICE COURT JUDGES ARE JUDICIAL AND THEIR DISTRICTS ARE NOT FLAGGED is_judicial. The flag
-- lives on the district, and these districts also carry supervisors, constables and election
-- commissioners; marking it would mislabel the other fifteen. MS-4's finding, unchanged.
INSERT INTO hc_offices(geo_id, mtfcc, chamber_name, title)
SELECT d.geo_id, 'G4040', v.chamber, v.prefix || ', District ' || right(d.label, 1)
FROM hc_districts d
JOIN (VALUES
  ('Hinds County Board of Supervisors', 'Supervisor'),
  ('Hinds County Justice Court',        'Justice Court Judge'),
  ('Hinds County Constables',           'Constable'),
  ('Hinds County Election Commission',  'Election Commissioner')
) AS v(chamber, prefix) ON true;

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, 'MS', NULL, 1, false, 'full'
FROM hc_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND lower(d.state) = 'ms'
 AND d.district_type = (CASE WHEN n.mtfcc = 'G4020' THEN 'COUNTY' ELSE 'LOCAL' END)
JOIN essentials.governments g ON g.name = 'Hinds County, Mississippi, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = n.title);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov    int;
  v_ch     int;
  v_dist   int;
  v_off    int;
  v_county int;
  v_perdis int;
  v_titles int;
  v_vacant int;
  v_nogeom int;
  v_leg    int;
  v_harr   int;
  v_jxn    int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'Hinds County, Mississippi, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'Hinds gate: expected 1 government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Hinds County, Mississippi, US';
  IF v_ch <> 5 THEN RAISE EXCEPTION 'Hinds gate: expected 5 chambers, found %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE mtfcc = 'G4040' AND lower(state) = 'ms' AND district_type = 'LOCAL'
     AND geo_id IN ('2804990225','2804990963','2804991701','2804992439','2804993177');
  IF v_dist <> 5 THEN RAISE EXCEPTION 'Hinds gate: expected 5 supervisor districts, found %', v_dist; END IF;

  SELECT count(*) INTO v_off
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Hinds County, Mississippi, US';
  IF v_off <> 28 THEN RAISE EXCEPTION 'Hinds gate: expected 28 offices, found %', v_off; END IF;

  SELECT count(*) INTO v_county
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'Hinds County, Mississippi, US' AND d.mtfcc = 'G4020';
  IF v_county <> 8 THEN RAISE EXCEPTION 'Hinds gate: expected 8 countywide offices, found %', v_county; END IF;

  -- 🔴 FOUR OFFICES PER SUPERVISOR DISTRICT, ASSERTED PER DISTRICT. A total of 20 is also what one
  -- district with eight and one with none would give, and the empty one would answer no address.
  SELECT count(*) INTO v_perdis
    FROM essentials.districts d
   WHERE d.mtfcc = 'G4040' AND lower(d.state) = 'ms'
     AND d.geo_id IN ('2804990225','2804990963','2804991701','2804992439','2804993177')
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 4;
  IF v_perdis <> 0 THEN
    RAISE EXCEPTION 'Hinds gate: % supervisor district(s) do not hold exactly 4 offices', v_perdis;
  END IF;

  SELECT count(DISTINCT o.title) INTO v_titles
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Hinds County, Mississippi, US';
  IF v_titles <> 28 THEN
    RAISE EXCEPTION 'Hinds gate: expected 28 distinct office titles, found % — a title collision means two seats share one name', v_titles;
  END IF;

  SELECT count(*) INTO v_vacant
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Hinds County, Mississippi, US' AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN RAISE EXCEPTION 'Hinds gate: expected 0 vacant offices, found %', v_vacant; END IF;

  SELECT count(*) INTO v_nogeom
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'Hinds County, Mississippi, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'Hinds gate: % office(s) sit on a district with NO polygon — unreachable by any address', v_nogeom;
  END IF;

  -- 🔴 CONTROLS, IN THE SAME TRANSACTION.
  SELECT count(*) INTO v_leg FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc IN ('G5210','G5220') AND lower(d.state) = 'ms';
  IF v_leg <> 174 THEN RAISE EXCEPTION 'Hinds gate CONTROL: expected 174 MS legislative offices, found %', v_leg; END IF;

  SELECT count(*) INTO v_harr FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Harrison County, Mississippi, US';
  IF v_harr <> 27 THEN RAISE EXCEPTION 'Hinds gate CONTROL: expected Harrison to still hold 27 offices, found %', v_harr; END IF;

  SELECT count(*) INTO v_jxn FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US';
  IF v_jxn <> 8 THEN RAISE EXCEPTION 'Hinds gate CONTROL: expected Jackson to still hold 8 offices, found %', v_jxn; END IF;

  RAISE NOTICE 'Hinds structure gate PASSED: 1 government, 5 chambers, 5 supervisor districts, 28 offices (8 countywide + 4 per district), 28 distinct titles, 0 vacant, every office on a district with geometry; 174 MS legislative, 27 Harrison and 8 Jackson offices unmoved.';
END $$;

COMMIT;
