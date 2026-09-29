-- CC_0181_stlouis_county_structure.sql
-- St. Louis MO deep seed, wave 4 (structure half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0182, which seats all 10 officials.
--
-- Creates the St. Louis County government, 4 chambers, 7 council districts and 10 offices,
-- and repairs one pre-existing ocd_id. Creates NO people and NO terms.
--
-- REQUIRES the geography load to have run first, and REFUSES TO RUN without it:
--   scripts/load-stlouis-county-council-boundaries.mjs -> 7 rows, mtfcc X0076
-- An office on a district with no polygon is unreachable by any address and NOTHING ERRORS.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE OFFICE LIST IS TEN SEATS, AND THE CHARTER SAYS SO NEGATIVELY. Section 6.010 of the
-- St. Louis County Charter (adopted by voters 2020-08-04):
--
--     "There shall be no elective county officers other than county executive, council members,
--      prosecuting attorney and assessor."
--
-- A negative enumeration is exhaustive, which is what makes this list closed rather than merely
-- long. Read as searchable text on Municode, codified through Ordinance 29,532 of 2026-02-17:
-- library.municode.com/mo/st._louis_county/codes/code_of_ordinances?nodeId=STLOCOCH2020
--   ⚠ The spec said the charter was published ONLY through a Yudu web reader. It is not.
--   ⚠ api.municode.com/CodesContent returns 401 to curl; read the page in Playwright.
--
-- 🟢 CERTIFIED RESULTS AGREE, and they were enumerated CONTEST BY CONTEST rather than searched by
-- office name. Both four-year cohorts were read in full from the county's own election authority
-- (the county has its OWN Board of Elections, separate from the CITY's Board of Election
-- Commissioners that wave 3 used):
--
--   Nov 8 2022  county executive · prosecuting attorney · county assessor · council 1, 3, 5, 7
--   Nov 5 2024  council 2, 4, 6
--   Aug 4 2026  (primary, mirrors the Nov 2026 ballot) re-states the 2022 cohort
--   Nov 3 2020  cross-check of the 2024 cohort, one cycle back
--
-- 🔴🔴 THE COUNTY ELECTS NONE OF THE SEVEN OFFICES THE CITY ELECTS. Wave 3 seated a Sheriff, a
-- Treasurer, a Collector of Revenue, a Recorder of Deeds, a License Collector, a Circuit Attorney
-- and a Comptroller for the City of St. Louis. St. Louis County elects NOT ONE of them. The
-- charter appoints every equivalent, and two of them do not exist at all:
--
--   County Auditor          § 2.200  appointed by the council
--   County Clerk            § 2.240  appointed by the administrative director
--   Treasurer               § 4.060  appointed by the director of administration
--   Collector, Recorder     § 4.350  appointed by the director of revenue
--   Circuit Clerk           § 4.450  appointed by the director of judicial administration
--   County Counselor        § 5.020  appointed by the county executive
--   Public Administrator    § 6.020  appointed by a majority of the circuit judges
--   Sheriff                 —        NO SUCH OFFICE; § 4.270 gives a board of police commissioners
--   Coroner                 —        NO SUCH OFFICE; § 4.150 gives a chief medical examiner
--
-- Each of those strings returns ZERO hits across all four complete certified files. That absence
-- was CONTROLLED three ways, because a detector that only ever says "absent" proves nothing:
-- `TREASURER` returns 4,942 hits in Nov 2020 and 3,860 in Nov 2024 (STATE TREASURER) and 0 in
-- Nov 2022 and Aug 2026; `COUNTY ASSESSOR` returns 0 in Nov 2020 and Nov 2024 and thousands in
-- Nov 2022 and Aug 2026 — exactly what § 6.050's 2014 + 4n cycle predicts; and `COUNTY EXECUTIVE`
-- returns 0 in Nov 2024, as § 3.010's 1982 + 4n predicts.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 A TRUNCATED CSV NAMED THE RUNNER-UP, UNDER A CLEAN HTTP 200. curl wrote a short body and
-- EXITED 0 for three of five certified files. The partial Nov 2024 file held only part of County
-- Council District 6, so aggregating it named KEVIN SCHARTNER the winner at 53.13%. The complete
-- file names G. MICHAEL ARCHER at 52.50%. The runner-up, at a believable margin, correctly
-- formatted, with nothing erroring. It also hid SIX CONTESTS from that election's enumeration, so
-- this office list was itself at risk.
--   🔴 It was caught only by cross-checking against the council's own roster page. A certified
--   tally verifies nothing about itself.
--   Guards: county-results/fetch.sh loops on Content-Length; derive_roster.py asserts every byte
--   count before reading a vote. Both were watched failing first. See county-results/FETCH.md.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 `St. Louis County` ALREADY EXISTS IN PRODUCTION IN MINNESOTA, AND IT ALSO HAS A
-- SEVEN-MEMBER ELECTED BOARD. geo_id 27137, government `St. Louis County, Minnesota, US`,
-- 10 offices, 7 commissioner districts keyed `st-louis-mn-commissioner-district-N`. Missouri's is
-- geo_id 29189 with a seven-member County Council. IDENTICAL district label, IDENTICAL seat count.
-- Nothing below matches on a label; every key is (geo_id, district_type), and the gate asserts as
-- an ABSENCE that Minnesota gained nothing — 10 offices before, 10 after.
--
-- 🔴 THE CITY IS NOT IN THE COUNTY. St. Louis city seceded in 1876. The boundary loader's GATE 5
-- asserts that 1200 Market St (CITY Hall) falls in ZERO county council districts.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THIS MIGRATION REPAIRS THE ocd_id COLLISION WAVE 3 DELIBERATELY LEFT. Production's
-- `St. Louis city` COUNTY row (geo_id 29510) carries
-- `ocd-division/country:us/state:mo/county:st_louis` — which is ST. LOUIS COUNTY's identifier, and
-- 29189 carries it too. Two governments on different ground sharing one id, and ocd_id ROLLS UP.
-- Wave 3 seated nothing on 29510 so it did not need fixing; wave 4 seats the county, so it does.
--
-- The registry answers this itself, and even warns about it. From
-- opencivicdata/ocd-division-ids identifiers/country-us.csv, read 2026-09-29:
--
--   ocd-division/country:us/state:mo/county:st_louis,St. Louis County,,,,place-29189
--   ocd-division/country:us/state:mo/county:st_louis_city,St. Louis city,
--     ocd-division/country:us/state:mo/place:st_louis,
--     "St Louis (City) MO is an independent city: not a county; do not confuse with St Louis County"
--
-- So 29189 is ALREADY correct and is NOT touched. 29510 moves to `county:st_louis_city`, which is
-- the registry's own id for the independent city as a county-equivalent — not `place:st_louis`,
-- which is the registry's id for the PLACE and is already carried by 2965000 (wave 3).
--
-- 🟢 THE SEVEN COUNCIL DISTRICT ocd_ids ARE THE REGISTRY'S OWN, verified against
-- identifiers/country-us/state-mo-local_gov.csv rather than composed:
--   ocd-division/country:us/state:mo/county:st_louis/council_district:1 .. :7
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 REACHABILITY, CHECKED AGAINST THE ACTUAL JOIN rather than assumed:
--   districtQueries.GEOFENCE_DISTRICT_JOIN carries
--     (gb.mtfcc LIKE 'X%' AND gb.mtfcc NOT IN ('X0001'..'X0004') AND d.district_type IN
--      ('LOCAL','COUNTY','JUDICIAL'))
--   and geoIdGuard.MTFCC_DISTRICT_TYPE_GUARD the same for ('LOCAL','COUNTY'). So X0076 reaches
--   COUNTY with NO code change. G4020 maps to ('COUNTY','JUDICIAL'), so the three countywide seats
--   sit on the EXISTING 29189 COUNTY district and are reachable there.
--   X0076 was measured free: X0075 (wave 3's city wards) is the highest in use.
--
-- 🔴 THE COUNCIL MAP IS THE 2021 COMMISSION'S, AND THE COUNT CANNOT PROVE IT — 7 is 7 under the
-- superseded 2019 plan too. The loader establishes vintage GEOMETRICALLY and in both directions:
-- it must AGREE with Council_District_Plan_2022 (measured 0.0000% symmetric difference) and must
-- DISAGREE with County_Council_Districts_2019 (measured 12.1460%, six of seven districts moved).
-- All six loader gates were watched failing on their own control.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded and the UPDATE is value-guarded. Ends with a
-- post-verify gate.

BEGIN;

-- ─── 0. Refuse to run without the geography ───────────────────────────────────

DO $$
DECLARE v_council int; v_county int;
BEGIN
  SELECT count(*) INTO v_council FROM essentials.geofence_boundaries WHERE mtfcc = 'X0076';
  SELECT count(*) INTO v_county  FROM essentials.geofence_boundaries
   WHERE geo_id = '29189' AND mtfcc = 'G4020';
  IF v_council <> 7 THEN
    RAISE EXCEPTION 'MO-4 pre-flight: expected 7 X0076 council boundaries, found % — run scripts/load-stlouis-county-council-boundaries.mjs first', v_council;
  END IF;
  IF v_county <> 1 THEN
    RAISE EXCEPTION 'MO-4 pre-flight: the TIGER county polygon 29189/G4020 is not in production; without it the three countywide seats are unreachable by any address and nothing would error';
  END IF;
END $$;

-- ─── 1. Repair the ocd_id collision on the CITY's county-equivalent row ───────
-- 🔴 29510 only. 29189's id is the registry's own and is correct; touching it would be the bug.
-- Value-guarded, so re-running is a no-op and a row already repaired is left alone.

UPDATE essentials.districts
   SET ocd_id = 'ocd-division/country:us/state:mo/county:st_louis_city'
 WHERE geo_id = '29510'
   AND district_type::text = 'COUNTY'
   AND lower(state) = 'mo'
   AND ocd_id = 'ocd-division/country:us/state:mo/county:st_louis';

-- ─── 2. The government ────────────────────────────────────────────────────────
-- 🔴 The name MUST carry ", Missouri, US". `St. Louis County, Minnesota, US` is already here.

INSERT INTO essentials.governments (name, type, state)
SELECT 'St. Louis County, Missouri, US', 'County', 'MO'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'St. Louis County, Missouri, US');

-- ─── 3. The four chambers ─────────────────────────────────────────────────────
-- Shaped after Greene County MO and St. Louis County MN: a named body for the legislature, and
-- "Office of the X" for each single-holder office.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.n
FROM essentials.governments g
CROSS JOIN (VALUES
  ('County Council',                     7),
  ('Office of the County Executive',     1),
  ('Office of the Prosecuting Attorney', 1),
  ('Office of the Assessor',             1)
) AS v(name, n)
WHERE g.name = 'St. Louis County, Missouri, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 4. The seven council districts ───────────────────────────────────────────
-- 🔴 geo_id `stlouis-county-mo-council-N`, distinct from Minnesota's
-- `st-louis-mn-commissioner-district-N`. The labels would otherwise be confusable by eye.

INSERT INTO essentials.districts (geo_id, mtfcc, label, district_type, state, ocd_id, representation_basis)
SELECT 'stlouis-county-mo-council-' || n, 'X0076', 'St. Louis County Council District ' || n,
       'COUNTY', 'MO',
       'ocd-division/country:us/state:mo/county:st_louis/council_district:' || n, 'residency'
FROM generate_series(1, 7) AS n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.geo_id = 'stlouis-county-mo-council-' || n AND d.district_type::text = 'COUNTY');

-- ─── 5. The seven Council Member offices ──────────────────────────────────────
-- 🔴 The title is bare `Council Member`, matching wave 2's bare `Representative`/`Senator` and
-- wave 3's bare `Alderman`. The county writes "Councilwoman Days" and "Councilman Harder"; the
-- office is the same office whoever holds it, and the district number lives on the district.
-- representing_city is the county seat, Clayton (charter § 1.020), matching Greene County MO.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Council Member', 'MO', 'Clayton', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.governments g ON g.name = 'St. Louis County, Missouri, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'County Council'
WHERE d.mtfcc = 'X0076' AND d.district_type::text = 'COUNTY' AND lower(d.state) = 'mo'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── 6. The three countywide offices ──────────────────────────────────────────
-- 🔴 On the EXISTING 29189 COUNTY district, which already has a polygon. No new district row.
-- Titles match the certified ballot's contest names, which is what a voter sees.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, v.title, 'MO', 'Clayton', 1, false, 'full'
FROM (VALUES
  ('County Executive',     'Office of the County Executive'),
  ('Prosecuting Attorney', 'Office of the Prosecuting Attorney'),
  ('County Assessor',      'Office of the Assessor')
) AS v(title, chamber)
JOIN essentials.governments g ON g.name = 'St. Louis County, Missouri, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = v.chamber
JOIN essentials.districts d ON d.geo_id = '29189' AND d.district_type::text = 'COUNTY' AND lower(d.state) = 'mo'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch int; v_cd int; v_cm int; v_cw int; v_tot int;
  v_one int; v_outside int; v_unreach int; v_vac int; v_note int; v_dupe int; v_ocd int;
  v_mn_off int; v_mn_dist int; v_city_ocd text; v_county_ocd text; v_shared int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'St. Louis County, Missouri, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'MO-4 structure gate: expected 1 St. Louis County MO government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'St. Louis County, Missouri, US';
  IF v_ch <> 4 THEN RAISE EXCEPTION 'MO-4 structure gate: expected 4 chambers, found %', v_ch; END IF;

  SELECT count(*) INTO v_cd FROM essentials.districts
   WHERE mtfcc = 'X0076' AND district_type::text = 'COUNTY' AND lower(state) = 'mo';
  IF v_cd <> 7 THEN RAISE EXCEPTION 'MO-4 structure gate: expected 7 council districts, found %', v_cd; END IF;

  SELECT count(*) INTO v_cm FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0076' AND o.title = 'Council Member';
  IF v_cm <> 7 THEN RAISE EXCEPTION 'MO-4 structure gate: expected 7 Council Member offices, found %', v_cm; END IF;

  SELECT count(*) INTO v_cw FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'St. Louis County, Missouri, US' AND d.geo_id = '29189';
  IF v_cw <> 3 THEN RAISE EXCEPTION 'MO-4 structure gate: expected 3 countywide offices on 29189, found %', v_cw; END IF;

  SELECT count(*) INTO v_tot FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'St. Louis County, Missouri, US';
  IF v_tot <> 10 THEN
    RAISE EXCEPTION 'MO-4 structure gate: expected 10 offices (charter § 6.010 enumerates exactly these), found %', v_tot;
  END IF;

  -- The council is single-member by district.
  SELECT count(*) INTO v_one FROM essentials.districts d
   WHERE d.mtfcc = 'X0076'
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 1;
  IF v_one <> 0 THEN RAISE EXCEPTION 'MO-4 structure gate: % council district(s) do not hold exactly 1 office', v_one; END IF;

  -- 🔴🔴 NOTHING OF THIS GOVERNMENT MAY SIT OUTSIDE MISSOURI.
  SELECT count(*) INTO v_outside FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'St. Louis County, Missouri, US' AND lower(coalesce(d.state, '')) <> 'mo';
  IF v_outside <> 0 THEN RAISE EXCEPTION 'MO-4 structure gate: % office(s) sit on a district outside Missouri', v_outside; END IF;

  -- 🔴🔴 AND MINNESOTA MUST HAVE GAINED NOTHING. Asserted as an ABSENCE, both on the government
  -- and on the 27137 district, because the two counties share a label AND a seat count.
  SELECT count(*) INTO v_mn_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'St. Louis County, Minnesota, US';
  IF v_mn_off <> 10 THEN
    RAISE EXCEPTION 'MO-4 structure gate: St. Louis County MINNESOTA holds % offices, expected its unchanged 10 — a Missouri seat landed on the homonym', v_mn_off;
  END IF;
  SELECT count(*) INTO v_mn_dist FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '27137';
  IF v_mn_dist <> 3 THEN
    RAISE EXCEPTION 'MO-4 structure gate: the MINNESOTA county district 27137 holds % offices, expected its unchanged 3', v_mn_dist;
  END IF;

  -- 🔴 Every district this wave touches must have a polygon, or its offices are invisible to
  -- address search and nothing errors.
  SELECT count(*) INTO v_unreach FROM essentials.districts d
   WHERE (d.mtfcc = 'X0076' OR (d.geo_id = '29189' AND d.district_type::text = 'COUNTY'))
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_unreach <> 0 THEN
    RAISE EXCEPTION 'MO-4 structure gate: % St. Louis County district(s) have NO geofence boundary — their offices would be unreachable by any address', v_unreach;
  END IF;

  SELECT count(*) INTO v_vac FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'St. Louis County, Missouri, US' AND o.is_vacant IS true;
  IF v_vac <> 0 THEN RAISE EXCEPTION 'MO-4 structure gate: expected 0 vacant flags, found %', v_vac; END IF;

  -- ADR 0003: all 10 are full/residency, so no representation_note is required.
  SELECT count(*) INTO v_note FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'St. Louis County, Missouri, US'
     AND (o.voting_powers <> 'full' OR d.representation_basis::text <> 'residency');
  IF v_note <> 0 THEN RAISE EXCEPTION 'MO-4 structure gate: % seat(s) are not full/residency and would REQUIRE a representation_note', v_note; END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT o.chamber_id, o.district_id, o.title FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'St. Louis County, Missouri, US'
     GROUP BY 1,2,3 HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'MO-4 structure gate: % duplicate (chamber, district, title)', v_dupe; END IF;

  -- The seven council districts carry the registry's own council_district ids.
  SELECT count(*) INTO v_ocd FROM essentials.districts d
   WHERE d.mtfcc = 'X0076'
     AND d.ocd_id NOT LIKE 'ocd-division/country:us/state:mo/county:st_louis/council_district:%';
  IF v_ocd <> 0 THEN RAISE EXCEPTION 'MO-4 structure gate: % council district(s) do not carry a council_district ocd_id', v_ocd; END IF;

  -- 🔴 THE REPAIR, ASSERTED IN BOTH DIRECTIONS. The city must have moved to st_louis_city, the
  -- county must still hold st_louis, and no two Missouri districts may now share either id.
  SELECT ocd_id INTO v_city_ocd FROM essentials.districts
   WHERE geo_id = '29510' AND district_type::text = 'COUNTY' AND lower(state) = 'mo';
  IF v_city_ocd IS DISTINCT FROM 'ocd-division/country:us/state:mo/county:st_louis_city' THEN
    RAISE EXCEPTION 'MO-4 structure gate: 29510 (the CITY) carries ocd_id %, expected county:st_louis_city', coalesce(v_city_ocd, 'NULL');
  END IF;
  SELECT ocd_id INTO v_county_ocd FROM essentials.districts
   WHERE geo_id = '29189' AND district_type::text = 'COUNTY' AND lower(state) = 'mo';
  IF v_county_ocd IS DISTINCT FROM 'ocd-division/country:us/state:mo/county:st_louis' THEN
    RAISE EXCEPTION 'MO-4 structure gate: 29189 (the COUNTY) carries ocd_id %, expected county:st_louis — this migration must not have touched it', coalesce(v_county_ocd, 'NULL');
  END IF;
  SELECT count(*) INTO v_shared FROM (
    SELECT ocd_id FROM essentials.districts
     WHERE lower(state) = 'mo' AND district_type::text = 'COUNTY'
       AND ocd_id IN ('ocd-division/country:us/state:mo/county:st_louis',
                      'ocd-division/country:us/state:mo/county:st_louis_city')
     GROUP BY ocd_id HAVING count(*) > 1) x;
  IF v_shared <> 0 THEN
    RAISE EXCEPTION 'MO-4 structure gate: % St. Louis ocd_id(s) are still shared by more than one Missouri COUNTY district', v_shared;
  END IF;

  RAISE NOTICE 'MO-4 structure gate PASSED: 1 government, 4 chambers, 7 council districts, 10 offices (7 Council Members + County Executive + Prosecuting Attorney + County Assessor), every district has a polygon, Minnesota unchanged at 10 offices / 3 on 27137, 29510 repaired to county:st_louis_city and 29189 untouched.';
END $$;

COMMIT;
