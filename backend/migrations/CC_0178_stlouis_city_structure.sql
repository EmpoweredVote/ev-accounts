-- CC_0178_stlouis_city_structure.sql
-- St. Louis MO deep seed, wave 3 (structure half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0179, which seats 22 of the 23 officials.
--
-- Creates the City of St. Louis government, 6 chambers, 16 districts and 23 offices.
-- Creates NO people and NO terms.
--
-- REQUIRES the two geography loads to have run first, and REFUSES TO RUN without them:
--   scripts/load-stlouis-ward-boundaries.mjs  -> 14 rows, mtfcc X0075 (the city's own GIS)
--   scripts/load-stlouis-place-boundary.mjs   -> 1 row, 2965000/G4110 (TIGERweb)
-- An office on a district with no polygon is unreachable by any address and NOTHING ERRORS.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE OFFICE LIST COMES FROM CERTIFIED BALLOTS, NOT FROM THE CITY'S OWN ROSTER PAGE, BECAUSE
-- THAT PAGE IS INCOMPLETE. Measured 2026-09-28: on stlouis-mo.gov/government/elected-officials.cfm
-- the strings `Sheriff`, `Public Administrator`, `Circuit Clerk`, `Assessor` and `Coroner` each
-- appear ZERO times. The page lists 22 people. The city elects 23.
--
-- Eight certified summaries from the Board of Election Commissioners were read — Nov 2020,
-- Apr 2021, Nov 2022, Apr 2023, Nov 2024, Apr 2025, Apr 2026 and the Aug 2026 primary — and each
-- office below appears on at least one of them:
--
--   Mayor, Comptroller                         Apr 2021, Apr 2025          (municipal, 4-year)
--   President of the Board of Aldermen         Nov 2022 (special), Apr 2023
--   Alderman x14                               Apr 2023 (all 14), Apr 2025 (the 7 odd wards)
--   Sheriff, Treasurer                         Nov 2020, Nov 2024          (county-tier, 4-year)
--   Circuit Attorney                           Nov 2024
--   Collector of Revenue, License Collector,
--   Recorder of Deeds                          Nov 2022, and Aug 2026 primary
--
-- 🔴 PUBLIC ADMINISTRATOR, CIRCUIT CLERK, ASSESSOR AND CORONER ARE **NOT** SEATED, AND THAT IS A
-- MEASURED ABSENCE RATHER THAN AN OVERSIGHT. A 4-year county-tier office must appear in one of the
-- two November cohorts (2020/2024 or 2022/2026). None of the four appears in EITHER. The search was
-- whitespace-flattened, because pypdf injects spaces mid-word in these PDFs (`US SENA TOR`,
-- `EDUCA TION`), and it was controlled in both directions — SHERIFF found in Nov 2024 and absent
-- from Nov 2022; LICENSE COLLECTOR the reverse; RECORDER matched under BOTH its spellings,
-- `REC OF DEEDS` (2022) and `RECORDER OF DEEDS` (2026).
--   ⚠ Sean Rapp DOES hold the office of Public Administrator and has his own city department page.
--   Nothing found elects him. If a later pass finds the ballot, add the office then.
--   ⚠ The contests are ABBREVIATED — `PRES OF BOA`, `COL OF REVENUE`, `REC OF DEEDS`. A search for
--   the full office name returns FALSE ABSENCES; the office list here came from reading every
--   contest heading instead.
--
-- 🔴 THE SHERIFF SEAT IS CREATED AND DELIBERATELY LEFT UNSEATED, WITH NO VACANCY FLAG.
-- Ruled 2026-09-28 (Cantrell). Alfred Montgomery won the seat in Nov 2024 with 85.90%. The
-- Missouri Attorney General's own statement says a judge ordered him "immediately and completely
-- removed from the position of Sheriff"; that removal was later halted, a new-trial motion was
-- denied in April 2026, and an interim sheriff runs the office. The city publishes NO sheriff —
-- neither on the roster page nor on the Sheriff's Office department page, whose leadership block
-- names nobody (controlled: the Public Administrator's block does name Sean Rapp).
--   So: the office exists and is evidenced, and any occupancy claim would be a claim about
--   contested facts concerning a named person. It carries no term row and no is_vacant flag, which
--   is what essentials.offices_missing_terms exists to show.
--   🔴 THIS MOVES THAT BASELINE FROM 238 TO 239 UNFLAGGED. That is this migration's doing and is
--   NOT drift. CLAUDE.md's baseline should be read as 239 from here.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THREE DIFFERENT PUBLISHERS STILL CARRY THE SUPERSEDED 28-WARD MAP. The Board of Aldermen
-- went from 28 wards to 14 at the April 2023 election. Still publishing 28, measured 2026-09-28:
--   · the city's own Planning department, "Census Data by Ward" (wards 1..28);
--   · the city charter PDF on the city site (28 wards, odd/even stagger);
--   · the national Open Civic Data registry, which lists place:st_louis/ward:1 .. ward:28.
-- Only the GIS layer, the Board's own representation page, the April 2023 certified ballot and the
-- Board's 2023-2024 session roster agree on 14. **Do not reach for a ward list without checking
-- which map it is.**
--
-- 🟢 OCD IDS ARE THE REGISTRY'S OWN, VERIFIED AGAINST IT rather than composed:
--   ocd-division/country:us/state:mo/place:st_louis          -> "St. Louis city", place-2965000
--   ocd-division/country:us/state:mo/place:st_louis/ward:N   -> "St Louis City MO - ward N"
--
-- 🔴🔴 NOTHING HERE TOUCHES THE EXISTING COUNTY DISTRICT 29510, AND THAT IS DELIBERATE.
-- Production's `St. Louis city` COUNTY row (geo_id 29510) carries
-- `ocd-division/country:us/state:mo/county:st_louis` — WHICH IS ST. LOUIS COUNTY'S IDENTIFIER, and
-- geo_id 29189 carries it too. Two different governments on two different pieces of ground sharing
-- one ocd_id, and ocd_id ROLLS UP. That is a real defect. It is NOT fixed here: this wave seats
-- nothing on 29510, so fixing it is not needed to make wave 3 correct, and it belongs to the county
-- wave, where the collision actually bites. Recorded so it is not lost.
--
-- 🔴 THE CITY IS NOT IN ST. LOUIS COUNTY. It seceded in 1876. Two separate governments, two sets of
-- elected officials, and an address is in exactly one of them. And `St. Louis County` ALREADY
-- EXISTS IN PRODUCTION IN MINNESOTA (geo_id 27137, also a 7-member board). Nothing below matches on
-- a label; the gate asserts that no office of this government landed outside Missouri.
--
-- 🟢 REACHABILITY, CHECKED AGAINST THE ACTUAL JOIN rather than assumed:
--   districtQueries.GEOFENCE_DISTRICT_JOIN and geoIdGuard.MTFCC_DISTRICT_TYPE_GUARD both carry an
--   X catch-all — `mtfcc LIKE 'X%' AND mtfcc NOT IN (X0001..X0004) AND district_type IN
--   ('LOCAL','COUNTY',…)` — so X0075 reaches LOCAL with NO code change, and G4110 already maps to
--   LOCAL and LOCAL_EXEC. G4020 maps only to COUNTY/JUDICIAL (LOCAL_EXEC is PR-scoped), which is
--   precisely why the citywide seats sit on place 2965000 and not on the county polygon.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Refuse to run without the geography ───────────────────────────────────

DO $$
DECLARE v_wards int; v_place int;
BEGIN
  SELECT count(*) INTO v_wards FROM essentials.geofence_boundaries WHERE mtfcc = 'X0075';
  SELECT count(*) INTO v_place FROM essentials.geofence_boundaries WHERE geo_id = '2965000' AND mtfcc = 'G4110';
  IF v_wards <> 14 THEN
    RAISE EXCEPTION 'MO-3 pre-flight: expected 14 X0075 ward boundaries, found % — run scripts/load-stlouis-ward-boundaries.mjs first', v_wards;
  END IF;
  IF v_place <> 1 THEN
    RAISE EXCEPTION 'MO-3 pre-flight: place 2965000/G4110 is not loaded — run scripts/load-stlouis-place-boundary.mjs first; without it the citywide seats are unreachable by any address and nothing would error';
  END IF;
END $$;

-- ─── 1. The government ────────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state)
SELECT 'City of St. Louis, Missouri, US', 'LOCAL', 'MO'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'City of St. Louis, Missouri, US');

-- ─── 2. The five chambers ─────────────────────────────────────────────────────
-- Shaped after Springfield and Greene County: a named body for the legislature, and
-- "Office of the X" for a single-holder office, with the remaining officers grouped.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.n
FROM essentials.governments g
CROSS JOIN (VALUES
  ('Board of Aldermen',            15),
  ('Office of the Mayor',           1),
  ('Office of the Comptroller',     1),
  ('Office of the Circuit Attorney', 1),
  ('Office of the Sheriff',         1),
  ('City Officers',                 4)
) AS v(name, n)
WHERE g.name = 'City of St. Louis, Missouri, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. The 14 ward districts ─────────────────────────────────────────────────

INSERT INTO essentials.districts (geo_id, mtfcc, label, district_type, state, ocd_id, representation_basis)
SELECT 'stlouis-mo-ward-' || n, 'X0075', 'St. Louis Ward ' || n, 'LOCAL', 'MO',
       'ocd-division/country:us/state:mo/place:st_louis/ward:' || n, 'residency'
FROM generate_series(1, 14) AS n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.geo_id = 'stlouis-mo-ward-' || n AND d.district_type::text = 'LOCAL');

-- ─── 4. The two citywide districts ────────────────────────────────────────────
-- 🔴 geo_id 2965000, NOT 29510. The place polygon (G4110) maps to LOCAL and LOCAL_EXEC; the
-- county-equivalent polygon (G4020) does not, so a citywide seat on 29510 would be unreachable.

INSERT INTO essentials.districts (geo_id, mtfcc, label, district_type, state, ocd_id, representation_basis)
SELECT '2965000', 'G4110', v.label, v.dt, 'MO',
       'ocd-division/country:us/state:mo/place:st_louis', 'residency'
FROM (VALUES
  ('St. Louis (Board of Aldermen, Citywide)', 'LOCAL'),
  ('St. Louis (Citywide)',                    'LOCAL_EXEC')
) AS v(label, dt)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = '2965000' AND d.district_type::text = v.dt);

-- ─── 5. The 14 ward Alderman offices ──────────────────────────────────────────
-- 🔴 The title is bare `Alderman`, matching wave 2's bare `Representative`/`Senator`. The city's
-- roster page writes "Ward 03 Alderman" and "Ward 01 Alderwoman"; the office is the same office
-- whoever holds it, and the ward lives on the district.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Alderman', 'MO', 'St. Louis', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.governments g ON g.name = 'City of St. Louis, Missouri, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Board of Aldermen'
WHERE d.mtfcc = 'X0075' AND d.district_type::text = 'LOCAL' AND lower(d.state) = 'mo'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── 6. The 9 citywide offices ────────────────────────────────────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, v.title, 'MO', 'St. Louis', 1, false, 'full'
FROM (VALUES
  ('President of the Board of Aldermen', 'Board of Aldermen',             'LOCAL'),
  ('Mayor',                              'Office of the Mayor',           'LOCAL_EXEC'),
  ('Comptroller',                        'Office of the Comptroller',     'LOCAL_EXEC'),
  ('Circuit Attorney',                   'Office of the Circuit Attorney','LOCAL_EXEC'),
  ('Sheriff',                            'Office of the Sheriff',         'LOCAL_EXEC'),
  ('Treasurer',                          'City Officers',                 'LOCAL_EXEC'),
  ('Collector of Revenue',               'City Officers',                 'LOCAL_EXEC'),
  ('License Collector',                  'City Officers',                 'LOCAL_EXEC'),
  ('Recorder of Deeds',                  'City Officers',                 'LOCAL_EXEC')
) AS v(title, chamber, dt)
JOIN essentials.governments g ON g.name = 'City of St. Louis, Missouri, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = v.chamber
JOIN essentials.districts d ON d.geo_id = '2965000' AND d.district_type::text = v.dt AND lower(d.state) = 'mo'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch int; v_wd int; v_cw int; v_ald int; v_city int; v_tot int;
  v_one int; v_outside int; v_unreach int; v_vac int; v_note int; v_dupe int; v_ocd int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'City of St. Louis, Missouri, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'MO-3 structure gate: expected 1 City of St. Louis government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of St. Louis, Missouri, US';
  IF v_ch <> 6 THEN RAISE EXCEPTION 'MO-3 structure gate: expected 6 chambers, found %', v_ch; END IF;

  SELECT count(*) INTO v_wd FROM essentials.districts
   WHERE mtfcc = 'X0075' AND district_type::text = 'LOCAL' AND lower(state) = 'mo';
  IF v_wd <> 14 THEN RAISE EXCEPTION 'MO-3 structure gate: expected 14 ward districts, found %', v_wd; END IF;

  SELECT count(*) INTO v_cw FROM essentials.districts
   WHERE geo_id = '2965000' AND district_type::text IN ('LOCAL', 'LOCAL_EXEC') AND lower(state) = 'mo';
  IF v_cw <> 2 THEN RAISE EXCEPTION 'MO-3 structure gate: expected 2 citywide districts on place 2965000, found %', v_cw; END IF;

  SELECT count(*) INTO v_ald FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0075' AND o.title = 'Alderman';
  IF v_ald <> 14 THEN RAISE EXCEPTION 'MO-3 structure gate: expected 14 ward Alderman offices, found %', v_ald; END IF;

  SELECT count(*) INTO v_city FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '2965000' AND d.district_type::text IN ('LOCAL', 'LOCAL_EXEC');
  IF v_city <> 9 THEN RAISE EXCEPTION 'MO-3 structure gate: expected 9 citywide offices, found %', v_city; END IF;

  SELECT count(*) INTO v_tot FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of St. Louis, Missouri, US';
  IF v_tot <> 23 THEN RAISE EXCEPTION 'MO-3 structure gate: expected 23 City of St. Louis offices, found %', v_tot; END IF;

  -- Exactly one office per ward district: the Board is single-member by ward.
  SELECT count(*) INTO v_one FROM essentials.districts d
   WHERE d.mtfcc = 'X0075'
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 1;
  IF v_one <> 0 THEN RAISE EXCEPTION 'MO-3 structure gate: % ward district(s) do not hold exactly 1 office', v_one; END IF;

  -- 🔴🔴 Nothing of this government may sit outside Missouri — the St. Louis County homonym
  -- (MN 27137) has the same label AND the same seat count as Missouri's 29189.
  SELECT count(*) INTO v_outside FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'City of St. Louis, Missouri, US' AND lower(coalesce(d.state, '')) <> 'mo';
  IF v_outside <> 0 THEN RAISE EXCEPTION 'MO-3 structure gate: % office(s) sit on a district outside Missouri', v_outside; END IF;

  -- 🔴 THE ASSERTION THAT ACTUALLY MATTERS: every district this wave created must have a polygon,
  -- or its office is invisible to address search and nothing errors.
  SELECT count(*) INTO v_unreach FROM essentials.districts d
   WHERE (d.mtfcc = 'X0075' OR (d.geo_id = '2965000' AND d.district_type::text IN ('LOCAL','LOCAL_EXEC')))
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_unreach <> 0 THEN
    RAISE EXCEPTION 'MO-3 structure gate: % St. Louis district(s) have NO geofence boundary — their offices would be unreachable by any address', v_unreach;
  END IF;

  -- Vacancy flags are CC_0179's business, and the Sheriff gets none there either.
  SELECT count(*) INTO v_vac FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of St. Louis, Missouri, US' AND o.is_vacant IS true;
  IF v_vac <> 0 THEN RAISE EXCEPTION 'MO-3 structure gate: expected 0 vacant flags, found %', v_vac; END IF;

  -- ADR 0003: all 23 are full/residency, so no representation_note is required.
  SELECT count(*) INTO v_note FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'City of St. Louis, Missouri, US'
     AND (o.voting_powers <> 'full' OR d.representation_basis::text <> 'residency');
  IF v_note <> 0 THEN RAISE EXCEPTION 'MO-3 structure gate: % seat(s) are not full/residency and would REQUIRE a representation_note', v_note; END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT o.chamber_id, o.district_id, o.title FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of St. Louis, Missouri, US'
     GROUP BY 1,2,3 HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'MO-3 structure gate: % duplicate (chamber, district, title)', v_dupe; END IF;

  -- 🔴 The city's own ocd_id must NOT be St. Louis COUNTY's. The 14 wards and the 2 citywide rows
  -- all carry place:st_louis, verified against the Open Civic Data registry.
  SELECT count(*) INTO v_ocd FROM essentials.districts d
   WHERE (d.mtfcc = 'X0075' OR (d.geo_id = '2965000' AND d.district_type::text IN ('LOCAL','LOCAL_EXEC')))
     AND d.ocd_id NOT LIKE 'ocd-division/country:us/state:mo/place:st_louis%';
  IF v_ocd <> 0 THEN RAISE EXCEPTION 'MO-3 structure gate: % St. Louis district(s) do not carry a place:st_louis ocd_id', v_ocd; END IF;

  RAISE NOTICE 'MO-3 structure gate PASSED: 1 government, 6 chambers, 16 districts, 23 offices (14 ward Aldermen + 9 citywide), every district has a polygon, 0 outside Missouri, 0 vacant flags, all full/residency, all place:st_louis.';
END $$;

COMMIT;
