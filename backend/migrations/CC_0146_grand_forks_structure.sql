-- CC_0146_grand_forks_structure.sql
-- Knight Foundation program, wave ND-3 (structure half). Slot RESERVED from the allocator.
--
-- Creates the City of Grand Forks and its NINE elected offices:
--
--   1 government   City of Grand Forks, North Dakota, US
--   3 chambers     Grand Forks City Council (7) · Office of the Mayor (1) · Grand Forks Municipal Court (1)
--   8 districts    7 wards on X0067 + 1 citywide row on the TIGER place polygon 3832060
--   9 offices      7 ward council members + Mayor + Municipal Judge
--
-- Creates NO people and NO terms — CC_0147 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 GRAND FORKS ELECTS NINE OFFICES, NOT EIGHT, AND THE NINTH IS EASY TO MISS.
--
-- The office inventory is the city's own sentences, and they are in three different places:
--
--   · "The Grand Forks City Council consists of 7 members, each representing one of the city's
--     7 wards."  → seven single-member wards, and NO at-large seat. (city council page)
--   · "This is different from the Mayor, who is the head administrator of the city."  → the
--     Mayor is a separate citywide executive, not a council member. (same page)
--   · "The Municipal Judge is elected for a four-year term."  → AN ELECTED JUDGE.
--     (Municipal Court "Our Judges and Staff" page, under City Departments)
--
-- 🔴 THE JUDGE IS ON NONE OF THE OBVIOUS PAGES. Not City Leadership, not the City Council page,
-- not any roster. It sits on a court staff page, and the inclusion ruling is that an office is
-- seated if the VOTERS elect it — so it is in scope, exactly as Gary's Judge of the City Court
-- was at IN-4, and exactly as Fort Wayne's absent one was not.
-- ⚠ AND THE SAME PARAGRAPH EXCLUDES TWO PEOPLE: "two Alternate Municipal Judges as recommended
-- by the court and APPOINTED by the City Council." Elected judge in, appointed alternates out.
-- The distinction exists in that one paragraph and nowhere else on the site.
-- 🟢 The judge is confirmed in office by the city's own record: the Organizational Meeting
-- minutes of 2026-07-06 have the City Auditor administering his oath, after which HE administers
-- the council's. He is also not an afterthought in the court's future — those same minutes record
-- the Municipal Court "becoming a court of record, due to action approved in the 2025 State
-- Legislative Session".
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 GEOMETRY MUST EXIST FIRST. The pre-flight refuses to run without the seven X0067 ward
-- polygons. An office on a district with no polygon is unreachable by every resident of that
-- ward and NOTHING ERRORS — the one failure mode CI cannot catch.
-- Run scripts/load-grand-forks-ward-boundaries.mjs first.
--
-- 🟢 THE WARDS COME FROM THE STATE, NOT THE CITY, AND THAT WAS NOT A PREFERENCE. The city's own
-- "Ward & Precinct Map" is a PDF dated to early 2022 — the Gary problem. `NDGISHUB Voter
-- Precincts` ("...splits for the 2026 election...by...City, Ward,...", modified 2026-05-05)
-- carries all seven as 11 precinct parts, which the loader dissolves. They cover 99.351% of the
-- TIGER place; the missing 0.1904 sq mi is 88 separate ribbon-shaped pieces along the Red River,
-- which is the city's eastern boundary and the state line.
--
-- 🔴 THE CITYWIDE DISTRICT CARRIES TWO OFFICES, AND THEY ARE NOT INTERCHANGEABLE. The Mayor and
-- the Municipal Judge are both elected citywide, so both hang on the TIGER place row 3832060 —
-- but unlike ND-2's paired House seats these are DIFFERENT offices in different chambers, and the
-- gate asserts one of each rather than a count of two.
--
-- 🔴 PARTY IS NOT WRITTEN. Grand Forks city elections are non-partisan and no source names one;
-- party lives on races.primary_party in any case.
--
-- 🟢 NO SEAT IS VACANT, AND THAT IS FROM THE COUNCIL'S OWN ROLL CALL. The minutes of 2026-08-17
-- record "Present at roll call were Council Members Weigel, Osowski, Berg, Salentiny, Sande and
-- Vein - 6; absent: Fridolfs - 1", with Mayor Bochenski presiding. All seven wards and the Mayor
-- are accounted for BY NAME five weeks before this wave.
-- ⚠ Note what makes that a change-check rather than a roster: an ABSENCE NAMES THE HOLDER. A
-- roster that simply omitted Fridolfs would be indistinguishable from a vacancy; "absent:
-- Fridolfs" positively asserts that he still holds Ward 5.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the ward geometry must already be loaded ─────────────────

DO $$
DECLARE v_wards int;
BEGIN
  SELECT count(*) INTO v_wards FROM essentials.geofence_boundaries WHERE mtfcc = 'X0067';
  IF v_wards <> 7 THEN
    RAISE EXCEPTION 'ND-3 pre-flight: expected 7 X0067 Grand Forks ward boundaries, found %. Run scripts/load-grand-forks-ward-boundaries.mjs first.', v_wards;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries
                  WHERE geo_id = '3832060' AND mtfcc = 'G4110' AND state = '38') THEN
    RAISE EXCEPTION 'ND-3 pre-flight: the TIGER place polygon 3832060 (Grand Forks city) is not in production';
  END IF;
END $$;

-- ─── 1. Government ───────────────────────────────────────────────────────────
-- ⚠ The state suffix is deliberate and load-bearing. East Grand Forks is a SEPARATE city in
-- MINNESOTA across the Red River, and Grand Forks COUNTY is a separate government seeded by ND-4.

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Grand Forks, North Dakota, US', 'City', 'ND', 'Grand Forks', '3832060'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Grand Forks, North Dakota, US');

-- ─── 2. Three chambers ───────────────────────────────────────────────────────
-- The third is the Municipal Court, on the Gary precedent. Grand Forks elects no city auditor —
-- Maureen Storstad is City Auditor/Director of Finance and is staff, not an elected officer.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.official_count
FROM essentials.governments g
JOIN (VALUES
  ('Grand Forks City Council', 7),
  ('Office of the Mayor', 1),
  ('Grand Forks Municipal Court', 1)
) AS v(name, official_count) ON true
WHERE g.name = 'City of Grand Forks, North Dakota, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Eight districts ──────────────────────────────────────────────────────

CREATE TEMP TABLE gf_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO gf_districts(geo_id, label, mtfcc) VALUES
  ('grand-forks-nd-ward-1', 'Grand Forks City Council Ward 1', 'X0067'),
  ('grand-forks-nd-ward-2', 'Grand Forks City Council Ward 2', 'X0067'),
  ('grand-forks-nd-ward-3', 'Grand Forks City Council Ward 3', 'X0067'),
  ('grand-forks-nd-ward-4', 'Grand Forks City Council Ward 4', 'X0067'),
  ('grand-forks-nd-ward-5', 'Grand Forks City Council Ward 5', 'X0067'),
  ('grand-forks-nd-ward-6', 'Grand Forks City Council Ward 6', 'X0067'),
  ('grand-forks-nd-ward-7', 'Grand Forks City Council Ward 7', 'X0067'),
  ('3832060',               'Grand Forks Citywide',            'G4110');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'nd', n.mtfcc
FROM gf_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.district_type = 'LOCAL');

-- ─── 4. Nine offices ─────────────────────────────────────────────────────────

CREATE TEMP TABLE gf_offices(geo_id text, chamber_name text, title text) ON COMMIT DROP;
INSERT INTO gf_offices(geo_id, chamber_name, title) VALUES
  ('grand-forks-nd-ward-1', 'Grand Forks City Council', 'Council Member, Ward 1'),
  ('grand-forks-nd-ward-2', 'Grand Forks City Council', 'Council Member, Ward 2'),
  ('grand-forks-nd-ward-3', 'Grand Forks City Council', 'Council Member, Ward 3'),
  ('grand-forks-nd-ward-4', 'Grand Forks City Council', 'Council Member, Ward 4'),
  ('grand-forks-nd-ward-5', 'Grand Forks City Council', 'Council Member, Ward 5'),
  ('grand-forks-nd-ward-6', 'Grand Forks City Council', 'Council Member, Ward 6'),
  ('grand-forks-nd-ward-7', 'Grand Forks City Council', 'Council Member, Ward 7'),
  ('3832060',               'Office of the Mayor',        'Mayor'),
  ('3832060',               'Grand Forks Municipal Court','Municipal Judge');

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, 'ND', 'Grand Forks', 1, false, 'full'
FROM gf_offices n
JOIN essentials.districts d ON d.geo_id = n.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'nd'
JOIN essentials.governments g ON g.name = 'City of Grand Forks, North Dakota, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov       int;
  v_chambers  int;
  v_districts int;
  v_nogeom    int;
  v_offices   int;
  v_ward_off  int;
  v_mayor     int;
  v_judge     int;
  v_vacant    int;
  v_multi     int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'City of Grand Forks, North Dakota, US';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'ND-3 gate: expected exactly 1 City of Grand Forks government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_chambers FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Grand Forks, North Dakota, US';
  IF v_chambers <> 3 THEN
    RAISE EXCEPTION 'ND-3 gate: expected 3 chambers (Council, Mayor, Municipal Court), found %', v_chambers;
  END IF;

  SELECT count(*) INTO v_districts FROM essentials.districts d
   WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'nd'
     AND (d.mtfcc = 'X0067' OR d.geo_id = '3832060');
  IF v_districts <> 8 THEN
    RAISE EXCEPTION 'ND-3 gate: expected 8 Grand Forks LOCAL districts (7 wards + citywide), found %', v_districts;
  END IF;

  -- 🔴 Every district must have geometry. This is the failure CI cannot catch.
  SELECT count(*) INTO v_nogeom
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'nd'
     AND (d.mtfcc = 'X0067' OR d.geo_id = '3832060')
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'ND-3 gate: % Grand Forks district(s) have no matching boundary — unreachable by address', v_nogeom;
  END IF;

  SELECT count(*) INTO v_offices
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Grand Forks, North Dakota, US';
  IF v_offices <> 9 THEN
    RAISE EXCEPTION 'ND-3 gate: expected 9 Grand Forks offices (7 wards + Mayor + Municipal Judge), found %', v_offices;
  END IF;

  SELECT count(*) FILTER (WHERE o.title LIKE 'Council Member, Ward %'),
         count(*) FILTER (WHERE o.title = 'Mayor'),
         count(*) FILTER (WHERE o.title = 'Municipal Judge')
    INTO v_ward_off, v_mayor, v_judge
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Grand Forks, North Dakota, US';
  IF v_ward_off <> 7 THEN
    RAISE EXCEPTION 'ND-3 gate: expected 7 ward council offices, found %', v_ward_off;
  END IF;
  IF v_mayor <> 1 THEN
    RAISE EXCEPTION 'ND-3 gate: expected exactly 1 Mayor office, found %', v_mayor;
  END IF;
  -- 🔴 The elected Municipal Judge. If this is 0, the wave read the roster and not the charter.
  IF v_judge <> 1 THEN
    RAISE EXCEPTION 'ND-3 gate: expected exactly 1 elected Municipal Judge office, found % — the two ALTERNATE judges are appointed and must not be seated', v_judge;
  END IF;

  -- No ward district may carry more than one office: Grand Forks is single-member by ward, and
  -- this is the assertion ND-2 could NOT make about the multi-member House.
  SELECT count(*) INTO v_multi
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'nd' AND d.mtfcc = 'X0067'
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 1;
  IF v_multi <> 0 THEN
    RAISE EXCEPTION 'ND-3 gate: % Grand Forks ward(s) do not hold exactly 1 office', v_multi;
  END IF;

  SELECT count(*) INTO v_vacant
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Grand Forks, North Dakota, US' AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'ND-3 gate: expected 0 vacant Grand Forks offices, found %', v_vacant;
  END IF;

  RAISE NOTICE 'ND-3 structure gate PASSED: 1 government, 3 chambers, 8 districts all with geometry, 9 offices (7 wards + Mayor + Municipal Judge), 0 vacant.';
END $$;

COMMIT;
