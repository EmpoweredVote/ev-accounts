-- CC_0129_sc_counties_structure.sql
-- Knight Foundation program, wave SC-4 (structure half). Slot RESERVED from the allocator.
-- Applied immediately before CC_0130, which puts people in these offices.
--
-- Stage 4 for South Carolina: Richland County (45079) and Horry County (45051).
-- Seats nobody. Creates two county governments, six chambers, the 22 council districts they need,
-- and 41 offices.
--
-- Production held NOTHING for either county before this wave: no government row, no local
-- district, no county office. Measured 2026-09-20 — SC held 189 offices, all of them the state's
-- 170 legislative seats, five statewide executives and SC-3's 14 city seats.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE TWO COUNCILS ARE NOT THE SAME SHAPE, AND THE STATUTE SAYS WHY.
--   Richland — ELEVEN single-member districts and NO at-large chairman. The chair and vice chair
--   are chosen by the Council each January, so the chairmanship is not an office: Chair Mackey
--   holds District 9 and nothing else.
--   Horry — eleven single-member districts PLUS a CHAIRMAN ELECTED AT LARGE, twelve seats. The
--   county's own words: "The Horry County Council represents 11 different districts in the County,
--   and the chairman is elected at-large."
--   S.C. Code § 4-9-90 is what makes both true at once: "In those counties in which the chairman
--   of the governing body was elected at large as a separate office prior to the adoption of one
--   of the alternate forms of government provided for in this chapter, the chairman shall continue
--   to be so elected." It is a fact about each county's history, never a state template.
--
-- 🔴 NEITHER COUNTY ELECTS A REGISTER OF DEEDS, AND BOTH HAVE ONE. Horry's own officials page
-- lists Marion Foxworth as Register of Deeds; he was APPOINTED (2015). Richland's Register of
-- Deeds, John Hopkins, appears in the SC Association of Counties directory, on no ballot, and not
-- on Richland's own Elected Offices page. The South Carolina Election Commission's candidate
-- record has NO Register of Deeds contest in either county in 2020, 2022, 2024 or 2026. Neither
-- is seated. A Pennsylvania-style "counties elect a Recorder of Deeds" template would have created
-- two offices the voters do not fill.
--
-- 🔴 THE SOLICITORS ARE MULTI-COUNTY AND ARE NOT SEATED. Richland's Elected Offices page lists a
-- Solicitor, and the SEC confirms Solicitor Circuit 5 and Solicitor Circuit 15 on these ballots.
-- But the FIFTH CIRCUIT IS RICHLAND + KERSHAW and the FIFTEENTH IS HORRY + GEORGETOWN. NC-3 seated
-- a District Attorney BECAUSE NC Prosecutorial District 26 is coterminous with Mecklenburg County;
-- that condition fails here twice. This is the Georgia ruling (the Ocmulgee Circuit DA excluded as
-- MULTI-COUNTY) and the Palm Beach precedent (the 15th Judicial Circuit State Attorney, not
-- seated). Recorded as program-level open work, not fixed here.
--
-- ⚠ HORRY'S FIVE WATERSHED CONSERVATION DISTRICTS ARE DEFERRED. Buck Creek, Crabtree Swamp,
-- Gapway Swamp, Simpson Creek and Todd Swamp each elect three commissioners — 15 seats the voters
-- genuinely fill. They are watersheds, not the county; we hold no polygon for any of them, and
-- hanging them on the county polygon would answer them for every Horry address. Same class as
-- Gary's deferred district seats. School boards go with the question North Carolina already owes.
--
-- ⚠ SOIL AND WATER GETS ITS OWN CHAMBER IN EACH COUNTY, exactly as Mecklenburg's does, because
-- the district is a governmental subdivision of the State and not a department of county
-- government — and official_count is THREE, the number the voters elect, not the board of five.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 GEOMETRY COMES FROM scripts/load-sc-county-council-boundaries.mjs (X0060 Richland, X0061
-- Horry), NOT from here, and the pre-flight below FAILS HARD if those 22 boundaries are absent —
-- an office on a district with no polygon is unreachable by address and nothing errors.
--
-- 🔴 THE JOIN KEY IS (geo_id, mtfcc), NEVER geo_id ALONE. '45079' is Richland County AND State
-- House District 79; '45051' is Horry County AND State House District 51. Both of this slice's
-- counties sit inside that collision. The gate asserts that no legislative district picked up a
-- county office.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded or counted. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the polygons every office in this wave hangs on ───────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = 'X0060' AND state = '45';
  IF v_n <> 11 THEN
    RAISE EXCEPTION 'SC-4 structure: expected 11 X0060 Richland council-district boundaries, found % — run scripts/load-sc-county-council-boundaries.mjs first', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = 'X0061' AND state = '45';
  IF v_n <> 11 THEN
    RAISE EXCEPTION 'SC-4 structure: expected 11 X0061 Horry council-district boundaries, found % — run scripts/load-sc-county-council-boundaries.mjs first', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'G4020' AND state = '45' AND geo_id IN ('45079','45051');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'SC-4 structure: expected the Richland and Horry county polygons, found %', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE lower(state) = 'sc' AND mtfcc = 'G4020' AND geo_id IN ('45079','45051');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'SC-4 structure: expected the two countywide DISTRICT rows, found %', v_n;
  END IF;
END $$;

-- ─── 1. The two county governments ────────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT v.name, 'County', 'SC', v.geo_id
FROM (VALUES
  ('Richland County, South Carolina, US', '45079'),
  ('Horry County, South Carolina, US',    '45051')
) AS v(name, geo_id)
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.state = 'SC' AND g.geo_id = v.geo_id);

-- ─── 2. Six chambers ──────────────────────────────────────────────────────────
-- official_count is what the county or the statute says the body holds, not what we seat.
-- Soil and Water is 3 because three is what the voters elect; the board of five is not this
-- chamber.
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, remarks)
SELECT g.id, v.name, v.name_formal, v.official_count, v.remarks
FROM (VALUES
  ('45079', 'Richland County Council', 'Richland County Council', 11,
   'Eleven single-member districts. No at-large chairman: the chair and vice chair are elected by the Council for a one-year term at its first meeting each January, so the chairmanship is not a separate office.'),
  ('45079', 'Elected Officials', 'Richland County Elected Officials', 6,
   'Auditor, Clerk of Court, Coroner, Probate Judge, Sheriff and Treasurer, each elected countywide. The Fifth Circuit Solicitor is NOT here: the circuit is Richland and Kershaw counties together.'),
  ('45079', 'Soil and Water Conservation District', 'Richland Soil and Water Conservation District', 3,
   'A governmental subdivision of the State of South Carolina, not a department of county government. Its board holds five commissioners; three are elected countywide on a nonpartisan ballot and two are appointed by the SC Department of Natural Resources. Only the three ELECTED seats are carried here.'),
  ('45051', 'Horry County Council', 'Horry County Council', 12,
   'Eleven single-member districts PLUS a chairman elected at large as a separate office, preserved by S.C. Code § 4-9-90 for counties that elected one before adopting a Home Rule form.'),
  ('45051', 'Elected Officials', 'Horry County Elected Officials', 6,
   'Auditor, Clerk of Court, Coroner, Probate Judge, Sheriff and Treasurer, each elected countywide. The Register of Deeds is APPOINTED in Horry County and is not here; the Fifteenth Circuit Solicitor covers Horry and Georgetown counties together and is not here either.'),
  ('45051', 'Soil and Water Conservation District', 'Horry Soil and Water Conservation District', 3,
   'A governmental subdivision of the State of South Carolina, not a department of county government. Its board holds five commissioners; three are elected countywide on a nonpartisan ballot and two are appointed by the SC Department of Natural Resources. Only the three ELECTED seats are carried here. The county''s five WATERSHED conservation districts elect fifteen more commissioners and are deliberately absent: they are sub-county and we hold no polygon for any of them.')
) AS v(gov_geo_id, name, name_formal, official_count, remarks)
JOIN essentials.governments g ON g.state = 'SC' AND g.geo_id = v.gov_geo_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. The 22 council districts ──────────────────────────────────────────────
-- The two COUNTYWIDE district rows (45079 / 45051, G4020, COUNTY) ALREADY EXIST and are reused
-- untouched — every countywide office in this wave hangs on them.
INSERT INTO essentials.districts (geo_id, mtfcc, district_type, label, state, government_id)
SELECT v.geo_id, v.mtfcc, 'LOCAL', v.label, 'sc', gov.id
FROM (VALUES
  ('richland-sc-council-district-1',  'X0060', 'Richland County Council District 1',  '45079'),
  ('richland-sc-council-district-2',  'X0060', 'Richland County Council District 2',  '45079'),
  ('richland-sc-council-district-3',  'X0060', 'Richland County Council District 3',  '45079'),
  ('richland-sc-council-district-4',  'X0060', 'Richland County Council District 4',  '45079'),
  ('richland-sc-council-district-5',  'X0060', 'Richland County Council District 5',  '45079'),
  ('richland-sc-council-district-6',  'X0060', 'Richland County Council District 6',  '45079'),
  ('richland-sc-council-district-7',  'X0060', 'Richland County Council District 7',  '45079'),
  ('richland-sc-council-district-8',  'X0060', 'Richland County Council District 8',  '45079'),
  ('richland-sc-council-district-9',  'X0060', 'Richland County Council District 9',  '45079'),
  ('richland-sc-council-district-10', 'X0060', 'Richland County Council District 10', '45079'),
  ('richland-sc-council-district-11', 'X0060', 'Richland County Council District 11', '45079'),
  ('horry-sc-council-district-1',     'X0061', 'Horry County Council District 1',     '45051'),
  ('horry-sc-council-district-2',     'X0061', 'Horry County Council District 2',     '45051'),
  ('horry-sc-council-district-3',     'X0061', 'Horry County Council District 3',     '45051'),
  ('horry-sc-council-district-4',     'X0061', 'Horry County Council District 4',     '45051'),
  ('horry-sc-council-district-5',     'X0061', 'Horry County Council District 5',     '45051'),
  ('horry-sc-council-district-6',     'X0061', 'Horry County Council District 6',     '45051'),
  ('horry-sc-council-district-7',     'X0061', 'Horry County Council District 7',     '45051'),
  ('horry-sc-council-district-8',     'X0061', 'Horry County Council District 8',     '45051'),
  ('horry-sc-council-district-9',     'X0061', 'Horry County Council District 9',     '45051'),
  ('horry-sc-council-district-10',    'X0061', 'Horry County Council District 10',    '45051'),
  ('horry-sc-council-district-11',    'X0061', 'Horry County Council District 11',    '45051')
) AS v(geo_id, mtfcc, label, gov_geo_id)
JOIN essentials.governments gov ON gov.geo_id = v.gov_geo_id AND gov.state = 'SC'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = v.geo_id AND d.mtfcc = v.mtfcc);

-- ─── 4. The 41 offices ────────────────────────────────────────────────────────
-- ⚠ Three Soil and Water Commissioner offices per county share one title on one countywide
-- district. The seats are NOT numbered on any ballot, so the COUNT distinguishes them — the
-- Mecklenburg, Fort Wayne and Philadelphia convention. The guard counts how many of that
-- (chamber, district, title) triple already exist, so a re-run adds none and a missing one is
-- still added.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers, description)
SELECT c.id, d.id, v.title, 'SC', 1, v.is_vacant, 'full', v.description
FROM (VALUES
  -- Richland County Council — 11 single-member districts
  ( 0, 'Council Member, District 1',  'Richland County Council', '45079', 'richland-sc-council-district-1',  'X0060', false, NULL),
  ( 1, 'Council Member, District 2',  'Richland County Council', '45079', 'richland-sc-council-district-2',  'X0060', false, NULL),
  ( 2, 'Council Member, District 3',  'Richland County Council', '45079', 'richland-sc-council-district-3',  'X0060', false, NULL),
  ( 3, 'Council Member, District 4',  'Richland County Council', '45079', 'richland-sc-council-district-4',  'X0060', false, NULL),
  ( 4, 'Council Member, District 5',  'Richland County Council', '45079', 'richland-sc-council-district-5',  'X0060', false, NULL),
  ( 5, 'Council Member, District 6',  'Richland County Council', '45079', 'richland-sc-council-district-6',  'X0060', false, NULL),
  ( 6, 'Council Member, District 7',  'Richland County Council', '45079', 'richland-sc-council-district-7',  'X0060', false, NULL),
  ( 7, 'Council Member, District 8',  'Richland County Council', '45079', 'richland-sc-council-district-8',  'X0060', false, NULL),
  ( 8, 'Council Member, District 9',  'Richland County Council', '45079', 'richland-sc-council-district-9',  'X0060', false, NULL),
  ( 9, 'Council Member, District 10', 'Richland County Council', '45079', 'richland-sc-council-district-10', 'X0060', false, NULL),
  (10, 'Council Member, District 11', 'Richland County Council', '45079', 'richland-sc-council-district-11', 'X0060', false, NULL),
  -- Richland countywide officers
  (11, 'Auditor',        'Elected Officials', '45079', '45079', 'G4020', false, 'Elected countywide. S.C. Code § 4-11-10 commences an auditor''s term on the first day of July following the election, not in January.'),
  (12, 'Clerk of Court', 'Elected Officials', '45079', '45079', 'G4020', false, NULL),
  (13, 'Coroner',        'Elected Officials', '45079', '45079', 'G4020', false, NULL),
  (14, 'Probate Judge',  'Elected Officials', '45079', '45079', 'G4020', false, 'A judicial-branch officer whom county voters elect, seated under the inclusion ruling of 2026-09-17.'),
  (15, 'Sheriff',        'Elected Officials', '45079', '45079', 'G4020', false, NULL),
  (16, 'Treasurer',      'Elected Officials', '45079', '45079', 'G4020', false, 'Elected countywide. S.C. Code § 4-11-10 commences a treasurer''s term on the first day of July following the election, not in January.'),
  -- Richland soil and water — the three ELECTED seats; the two DNR-appointed ones are absent
  (17, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45079', '45079', 'G4020', false, 'Internal ordinal 1 of 3. Elected countywide on a nonpartisan ballot; the seats are not numbered. Not a ballot designation.'),
  (18, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45079', '45079', 'G4020', false, 'Internal ordinal 2 of 3. Elected countywide on a nonpartisan ballot; the seats are not numbered. Not a ballot designation.'),
  (19, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45079', '45079', 'G4020', true,  'Internal ordinal 3 of 3. VACANT: the SC Department of Natural Resources board record lists this elected seat as "Vacant", term expiring 2027-01-31. The date it fell vacant is not published, so no vacancy span is written — only this flag.'),
  -- Horry County Council — an at-large chairman plus 11 single-member districts
  (20, 'Chairman',                    'Horry County Council', '45051', '45051', 'G4020', false, 'Elected at large by the voters of the whole county as a separate office, preserved by S.C. Code § 4-9-90. Richland has no equivalent seat.'),
  (21, 'Council Member, District 1',  'Horry County Council', '45051', 'horry-sc-council-district-1',  'X0061', false, NULL),
  (22, 'Council Member, District 2',  'Horry County Council', '45051', 'horry-sc-council-district-2',  'X0061', false, NULL),
  (23, 'Council Member, District 3',  'Horry County Council', '45051', 'horry-sc-council-district-3',  'X0061', false, NULL),
  (24, 'Council Member, District 4',  'Horry County Council', '45051', 'horry-sc-council-district-4',  'X0061', false, NULL),
  (25, 'Council Member, District 5',  'Horry County Council', '45051', 'horry-sc-council-district-5',  'X0061', false, NULL),
  (26, 'Council Member, District 6',  'Horry County Council', '45051', 'horry-sc-council-district-6',  'X0061', false, NULL),
  (27, 'Council Member, District 7',  'Horry County Council', '45051', 'horry-sc-council-district-7',  'X0061', false, NULL),
  (28, 'Council Member, District 8',  'Horry County Council', '45051', 'horry-sc-council-district-8',  'X0061', false, NULL),
  (29, 'Council Member, District 9',  'Horry County Council', '45051', 'horry-sc-council-district-9',  'X0061', false, NULL),
  (30, 'Council Member, District 10', 'Horry County Council', '45051', 'horry-sc-council-district-10', 'X0061', false, NULL),
  (31, 'Council Member, District 11', 'Horry County Council', '45051', 'horry-sc-council-district-11', 'X0061', false, NULL),
  -- Horry countywide officers
  (32, 'Auditor',        'Elected Officials', '45051', '45051', 'G4020', false, 'Elected countywide. S.C. Code § 4-11-10 commences an auditor''s term on the first day of July following the election, not in January.'),
  (33, 'Clerk of Court', 'Elected Officials', '45051', '45051', 'G4020', false, NULL),
  (34, 'Coroner',        'Elected Officials', '45051', '45051', 'G4020', false, NULL),
  (35, 'Probate Judge',  'Elected Officials', '45051', '45051', 'G4020', false, 'A judicial-branch officer whom county voters elect, seated under the inclusion ruling of 2026-09-17.'),
  (36, 'Sheriff',        'Elected Officials', '45051', '45051', 'G4020', false, NULL),
  (37, 'Treasurer',      'Elected Officials', '45051', '45051', 'G4020', false, 'Elected countywide. S.C. Code § 4-11-10 commences a treasurer''s term on the first day of July following the election, not in January.'),
  -- Horry soil and water — the three ELECTED seats
  (38, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45051', '45051', 'G4020', false, 'Internal ordinal 1 of 3. Elected countywide on a nonpartisan ballot; the seats are not numbered. Not a ballot designation.'),
  (39, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45051', '45051', 'G4020', false, 'Internal ordinal 2 of 3. Elected countywide on a nonpartisan ballot; the seats are not numbered. Not a ballot designation.'),
  (40, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45051', '45051', 'G4020', false, 'Internal ordinal 3 of 3. Elected countywide on a nonpartisan ballot; the seats are not numbered. Not a ballot designation.')
) AS v(ord, title, chamber_name, gov_geo_id, district_geo_id, district_mtfcc, is_vacant, description)
JOIN essentials.governments g ON g.state = 'SC' AND g.geo_id = v.gov_geo_id
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = v.chamber_name
JOIN essentials.districts d ON d.geo_id = v.district_geo_id AND d.mtfcc = v.district_mtfcc AND lower(d.state) = 'sc'
WHERE (
  SELECT count(*) FROM essentials.offices o
   WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title
) < (
  -- how many offices this wave wants with exactly this (title, chamber, government), counting only
  -- as far as this row. One for every office except the two Soil and Water triples.
  SELECT count(*) FROM (VALUES
    ( 0, 'Council Member, District 1',  'Richland County Council', '45079'),
    ( 1, 'Council Member, District 2',  'Richland County Council', '45079'),
    ( 2, 'Council Member, District 3',  'Richland County Council', '45079'),
    ( 3, 'Council Member, District 4',  'Richland County Council', '45079'),
    ( 4, 'Council Member, District 5',  'Richland County Council', '45079'),
    ( 5, 'Council Member, District 6',  'Richland County Council', '45079'),
    ( 6, 'Council Member, District 7',  'Richland County Council', '45079'),
    ( 7, 'Council Member, District 8',  'Richland County Council', '45079'),
    ( 8, 'Council Member, District 9',  'Richland County Council', '45079'),
    ( 9, 'Council Member, District 10', 'Richland County Council', '45079'),
    (10, 'Council Member, District 11', 'Richland County Council', '45079'),
    (11, 'Auditor',        'Elected Officials', '45079'),
    (12, 'Clerk of Court', 'Elected Officials', '45079'),
    (13, 'Coroner',        'Elected Officials', '45079'),
    (14, 'Probate Judge',  'Elected Officials', '45079'),
    (15, 'Sheriff',        'Elected Officials', '45079'),
    (16, 'Treasurer',      'Elected Officials', '45079'),
    (17, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45079'),
    (18, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45079'),
    (19, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45079'),
    (20, 'Chairman',                    'Horry County Council', '45051'),
    (21, 'Council Member, District 1',  'Horry County Council', '45051'),
    (22, 'Council Member, District 2',  'Horry County Council', '45051'),
    (23, 'Council Member, District 3',  'Horry County Council', '45051'),
    (24, 'Council Member, District 4',  'Horry County Council', '45051'),
    (25, 'Council Member, District 5',  'Horry County Council', '45051'),
    (26, 'Council Member, District 6',  'Horry County Council', '45051'),
    (27, 'Council Member, District 7',  'Horry County Council', '45051'),
    (28, 'Council Member, District 8',  'Horry County Council', '45051'),
    (29, 'Council Member, District 9',  'Horry County Council', '45051'),
    (30, 'Council Member, District 10', 'Horry County Council', '45051'),
    (31, 'Council Member, District 11', 'Horry County Council', '45051'),
    (32, 'Auditor',        'Elected Officials', '45051'),
    (33, 'Clerk of Court', 'Elected Officials', '45051'),
    (34, 'Coroner',        'Elected Officials', '45051'),
    (35, 'Probate Judge',  'Elected Officials', '45051'),
    (36, 'Sheriff',        'Elected Officials', '45051'),
    (37, 'Treasurer',      'Elected Officials', '45051'),
    (38, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45051'),
    (39, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45051'),
    (40, 'Soil and Water Conservation District Commissioner', 'Soil and Water Conservation District', '45051')
  ) AS w(ord, title, chamber_name, gov_geo_id)
   WHERE w.title = v.title AND w.chamber_name = v.chamber_name AND w.gov_geo_id = v.gov_geo_id
     AND w.ord <= v.ord
);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE
  v_gov int; v_ch int; v_dist int; v_off int; v_rich int; v_horry int;
  v_vacant int; v_leak int; v_nogeom int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE state = 'SC' AND geo_id IN ('45079','45051') AND type = 'County';
  IF v_gov <> 2 THEN RAISE EXCEPTION 'SC-4 structure: expected 2 county governments, got %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051');
  IF v_ch <> 6 THEN RAISE EXCEPTION 'SC-4 structure: expected 6 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE lower(state) = 'sc' AND mtfcc IN ('X0060','X0061');
  IF v_dist <> 22 THEN RAISE EXCEPTION 'SC-4 structure: expected 22 council-district rows, got %', v_dist; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051');
  IF v_off <> 41 THEN RAISE EXCEPTION 'SC-4 structure: expected 41 county offices, got %', v_off; END IF;

  SELECT count(*) INTO v_rich FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'SC' AND g.geo_id = '45079';
  IF v_rich <> 20 THEN RAISE EXCEPTION 'SC-4 structure: expected 20 Richland offices, got %', v_rich; END IF;

  SELECT count(*) INTO v_horry FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'SC' AND g.geo_id = '45051';
  IF v_horry <> 21 THEN RAISE EXCEPTION 'SC-4 structure: expected 21 Horry offices, got %', v_horry; END IF;

  -- 🔴 Exactly ONE office is created vacant: the Richland soil-and-water seat the DNR board record
  -- shows as vacant. No vacancy SPAN is written for it, because the date it fell vacant is not
  -- published, so it is legitimately flagged in essentials.offices_missing_terms.
  SELECT count(*) INTO v_vacant FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051') AND o.is_vacant;
  IF v_vacant <> 1 THEN RAISE EXCEPTION 'SC-4 structure: expected exactly 1 vacant office, got %', v_vacant; END IF;

  -- 🔴 45079 is also House District 79 and 45051 is also House District 51. If anything matched on
  -- geo_id alone, a legislative or congressional district now carries a county office.
  SELECT count(DISTINCT d.id) INTO v_leak FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051')
     AND d.district_type NOT IN ('LOCAL','COUNTY');
  IF v_leak <> 0 THEN
    RAISE EXCEPTION 'SC-4 structure: % legislative/congressional district(s) picked up a county office — the join matched on geo_id alone', v_leak;
  END IF;

  -- 🔴 Every office must sit on a district that HAS a polygon. An office on a district with no
  -- geometry is unreachable by address and nothing errors.
  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('45079','45051')
     AND NOT EXISTS (
       SELECT 1 FROM essentials.geofence_boundaries b
        WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'SC-4 structure: % office(s) hang on a district with no polygon', v_nogeom;
  END IF;

  RAISE NOTICE 'SC-4 structure OK: 2 governments, 6 chambers, 22 districts, 41 offices (Richland 20, Horry 21), 1 flagged vacant, 0 district leaks, 0 offices without geometry';
END $$;

COMMIT;
