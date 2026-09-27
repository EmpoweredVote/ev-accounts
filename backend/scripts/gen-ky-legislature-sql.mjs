#!/usr/bin/env node
/**
 * gen-ky-legislature-sql.mjs — Knight program, wave KY-2.
 *
 * Emits the two migrations from `ky-terms.json`, which gen-ky-legislature-migrations.mjs wrote.
 * Structure first (CC_0150), occupancy second (CC_0151), so a re-seat never re-runs office
 * creation. Both are idempotent and both end in a DO $$ post-verify gate.
 *
 * Usage: node scripts/gen-ky-legislature-sql.mjs --in data/seed-ky-2026 --out migrations
 */
import fs from 'fs';
import path from 'path';

const argv = process.argv.slice(2);
const argOf = (f) => { const i = argv.indexOf(f); return i >= 0 ? argv[i + 1] : undefined; };
const IN = argOf('--in') ?? 'data/seed-ky-2026';
const OUT = argOf('--out') ?? 'migrations';
const STRUCTURE_SLOT = 'CC_0150';
const OCCUPANCY_SLOT = 'CC_0151';

const people = JSON.parse(fs.readFileSync(path.join(IN, 'ky-terms.json'), 'utf8'));
const q = (s) => "'" + String(s).replace(/'/g, "''") + "'";

const SOURCE =
  'Kentucky Legislative Research Commission. Roster read from all 138 individual member profile ' +
  'pages at https://legislature.ky.gov/Legislators/Pages/Legislator-Profile.aspx?DistrictNumber=N ' +
  '(House N=1..100, Senate N=101..138), each of which names its own member and chamber; ' +
  'cross-checked against apps.legislature.ky.gov/Legislators/{h,s}members_district.html and against ' +
  'the Legislator attributes on the LRC GIS layer Ky_Legislative_Districts_WGS84WM, which was found ' +
  'STALE on Senate District 37 (it still named David Yates, who resigned 2025-10-08). Arrival days ' +
  'claimed only where individually sourced; otherwise the year of the last service segment at year ' +
  'precision. Read 2026-09-26 (KY-2) (' + OCCUPANCY_SLOT + ', KY-2)';

const NAMESAKE_NOTE = {
  'Brandon Smith': 'existing row is a Longview, TEXAS city council candidate',
  'Daniel Elliott': 'existing row is the INDIANA State Treasurer (source: cicero)',
  'Matthew Lehman': 'existing row is from the INDIANA discovery cohort, is_active=false',
  'William Lawrence': 'existing row is a MICHIGAN U.S. House District 7 candidate',
};

const GOV = "(SELECT id FROM essentials.governments WHERE name = 'State of Kentucky')";

// ─────────────────────────────── structure ───────────────────────────────────
const S = `-- ${STRUCTURE_SLOT}_ky_general_assembly_structure.sql
-- Knight Foundation program, wave KY-2 (structure half). Slot RESERVED from the allocator.
--
-- Kentucky has NO state legislative offices and NO legislative chambers today: production holds
-- ONE Kentucky government row, 'State of Kentucky', carrying 5 statewide executives (Governor,
-- Lieutenant Governor, Attorney General, Secretary of State, Treasurer), all 5 seated. There is
-- no candidate-office decoy of the kind Ohio carried; that was checked, not assumed.
--
-- KY-1 loaded the geography (38 STATE_UPPER + 100 STATE_LOWER, vintage proved against the
-- Legislative Research Commission's own published districts 138/138, with a cross-chamber control
-- failing as required at 3/100), so this migration is a clean seed. It:
--
--   1. creates the two chambers;
--   2. creates 138 offices -- 100 Representative and 38 Senator.
--
-- Creates NO people and NO terms -- ${OCCUPANCY_SLOT} does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE JOIN KEY IS (geo_id, district_type, state), NEVER geo_id ALONE, AND KENTUCKY IS THE WORST
-- CASE THE PROGRAM HAS MET. TIGER writes legislative GEOIDs as state FIPS + district code, so
-- Senate District 20 is '21020' and House District 20 is '21020' too. Kentucky's 120 counties
-- occupy '21001'..'21239' odd, so 19 counties collide with the Senate range and 50 with the House
-- range -- and '21067' is FAYETTE COUNTY as well as House District 67, the very county this slice
-- exists to seat. Grand Forks escaped the identical collision only by luck of odd numbering.
-- The gate below asserts that no non-legislative district picked up a legislative office.
--
-- Both chambers are SINGLE-MEMBER (Ky. Const. s 33: 100 House districts, 38 Senate districts), so
-- polygon count IS seat count here -- unlike North Dakota and South Dakota. "Exactly one office
-- per district" is TRUE in Kentucky, and the gate asserts it rather than assuming it.
--
-- Party is NOT written. Party is antipartisan in this schema and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length, staggered_term)
SELECT v.government_id, v.name, v.name_formal, v.official_count, v.term_length, v.staggered_term
FROM (VALUES
  (${GOV}, 'Kentucky House of Representatives', 'Kentucky House of Representatives', 100, 2, false),
  (${GOV}, 'Kentucky Senate', 'Kentucky Senate', 38, 4, true)
) AS v(government_id, name, name_formal, official_count, term_length, staggered_term)
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.name_formal = v.name_formal);

-- ─── 2. The 138 offices ───────────────────────────────────────────────────────

CREATE TEMP TABLE ky_seats(geo_id text, district_type text, chamber_formal text, title text)
  ON COMMIT DROP;

INSERT INTO ky_seats(geo_id, district_type, chamber_formal, title) VALUES
${people.map((p) => `  (${q(p.geoId)}, ${q(p.districtType)}, ${q(p.chamberFormal)}, ${q(p.officeTitle)})`).join(',\n')};

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant)
SELECT c.id, d.id, ks.title, 'KY', 1, false
FROM ky_seats ks
JOIN essentials.chambers c ON c.name_formal = ks.chamber_formal
JOIN essentials.districts d
  ON d.geo_id = ks.geo_id AND d.district_type = ks.district_type AND lower(d.state) = 'ky'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.district_id = d.id
);

-- ─── 3. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_house int; v_senate int; v_contam int; v_multi int; v_seats int;
BEGIN
  SELECT count(*) INTO v_house
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Kentucky House of Representatives';
  SELECT count(*) INTO v_senate
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Kentucky Senate';

  IF v_house <> 100 THEN
    RAISE EXCEPTION 'KY-2 structure: expected 100 House offices, got %', v_house;
  END IF;
  IF v_senate <> 38 THEN
    RAISE EXCEPTION 'KY-2 structure: expected 38 Senate offices, got %', v_senate;
  END IF;

  -- The collision gate: no non-legislative district may have picked up a legislative office.
  SELECT count(*) INTO v_contam
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate')
     AND d.district_type NOT IN ('STATE_LOWER','STATE_UPPER');
  IF v_contam <> 0 THEN
    RAISE EXCEPTION 'KY-2 structure: % legislative office(s) landed on a non-legislative district - the 21067 Fayette/House-67 geo_id collision', v_contam;
  END IF;

  -- Kentucky is single-member in both chambers, so exactly one office per district.
  SELECT count(*) INTO v_multi FROM (
    SELECT o.district_id
      FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate')
     GROUP BY o.district_id HAVING count(*) > 1) x;
  IF v_multi <> 0 THEN
    RAISE EXCEPTION 'KY-2 structure: % district(s) carry more than one office; both Kentucky chambers are single-member', v_multi;
  END IF;

  -- Every office must sit on a Kentucky district, not a same-numbered district in another state.
  SELECT count(*) INTO v_seats
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate')
     AND lower(d.state) <> 'ky';
  IF v_seats <> 0 THEN
    RAISE EXCEPTION 'KY-2 structure: % office(s) landed on a district outside Kentucky', v_seats;
  END IF;

  RAISE NOTICE 'KY-2 structure OK: % offices (% House, % Senate), 0 contamination, 1 office per district', v_house + v_senate, v_house, v_senate;
END $$;

COMMIT;
`;

// ─────────────────────────────── occupancy ───────────────────────────────────
const plain = people.filter((p) => !p.namesake);
const names = people.filter((p) => p.namesake);

const peopleRow = (p) => `  (${p.externalId}, ${q(p.name)}, ${q(p.first)}, ${q(p.last)})`;
const termRow = (p) =>
  `  (${q(p.geoId)}, ${q(p.districtType)}, ${p.externalId}, DATE ${q(p.termStart)}, ${q(p.precision)})`;

const O = `-- ${OCCUPANCY_SLOT}_ky_general_assembly_incumbents.sql
-- Knight Foundation program, wave KY-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after ${STRUCTURE_SLOT}, which creates the chambers and the 138 offices.
--
-- Seats all 138 sitting members of the Kentucky General Assembly: 100 Representatives and 38
-- Senators. Creates 138 people and 138 open-ended terms. 0 vacancies.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE ROSTER WAS READ FROM ALL 138 MEMBER PAGES, AND IT HAD TO BE.
--
-- The LRC GIS layer Ky_Legislative_Districts_WGS84WM serves Legislator/Full_Name beside the
-- polygons, and KY-1 used that same layer as its GEOMETRY authority and proved it 138/138. Its
-- ROSTER is STALE: Senate District 37 still reads 'Yates, David', while the chamber's own list and
-- Clemons' own profile both read Gary Clemons. David Yates resigned 2025-10-08 to become Jefferson
-- County Clerk; Clemons won the 2025-12-16 special election.
-- ▶ A SOURCE CAN BE AUTHORITATIVE FOR ONE FIELD AND STALE FOR ANOTHER. Proving a layer's geometry
-- says nothing about the attributes riding along with it.
--
-- A DEPARTED KENTUCKY LEGISLATOR HAS NO PAGE AT ALL. The profile URL is keyed to the SEAT
-- (DistrictNumber only), so a successor replaces the predecessor and a departure marker can never
-- appear. The cross-source diff is the only change-check that works in Kentucky, and it is what
-- caught SD-37.
--
-- ONE MEMBER HAS HELD ONE SEAT UNDER THREE PUBLISHED NAMES. House District 81:
-- 'Frazier, Deanna' (2019-2021) -> 'Frazier Gordon, Deanna' (2021-2025) -> 'Gordon, Deanna'
-- (2025- ). A name-keyed diff reads that as two departures and two arrivals. Matching Kentucky
-- legislators by name across time is unsafe; this migration keys on the SEAT.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- TERM DATES: ${people.filter((p) => p.precision === 'day').length} day, ${people.filter((p) => p.precision === 'year').length} year, 0 unknown, 0 invented.
--
-- Ky. Const. s 30 makes a term begin on 1 January of the year succeeding the election, and an
-- earlier draft of this wave used that as a blanket day for 126 seats. IT WAS WRONG:
--   * the LRC 'Service' string is CHAMBER-scoped, not seat-scoped;
--   * 13 members carry a gap or a chamber switch ('House 1994 - 22, House 2025 - Present'), so the
--     FIRST year can miss by up to 31 years and can name the wrong chamber entirely;
--   * 3 still-serving members changed DISTRICT NUMBER in the 2022 remap (D90->D14, D88->D43,
--     D82->D49), measured against archived 2022 and 2023 LRC rosters;
--   * 9 arrived mid-term by special election;
--   * 8 more were caught by replaying 45 archived LRC rosters -- absent from an early snapshot of
--     their claimed year, present in a later one;
--   * and that detector has blind spots: 40 members predate snapshot coverage, and Peyton Griffee,
--     a confirmed March 2024 arrival, is NOT flagged by it.
-- ▶ So a DAY is claimed only where the arrival was individually sourced. Everything else takes the
-- last service segment's YEAR at year precision, which UNDER-claims rather than over-claims.
-- The gap between a special election and the oath measured 6, 7, 7 and 20 days -- IT IS NOT A RULE
-- AND MUST NOT BE COMPUTED (ND-3's finding, reproduced here). Two January 2014 arrivals (Miles
-- House 7, Thomas Senate 13) are deliberately left at year precision because sources disagree
-- across Jan 2 / Jan 4 / Jan 7 and Kentucky publishes NO House or Senate Journal online.
--
-- external_id block -2763000..-2762601 was measured EMPTY on 2026-09-26; the nearest occupied id
-- below it is -2770001. An external_id collision seats the WRONG person silently.
--
-- Party is NOT written. Party is antipartisan and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 1. The ${plain.length} people whose names collide with nobody ─────────────────────────

CREATE TEMP TABLE ky_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ky_new_people(external_id, full_name, first_name, last_name) VALUES
${plain.map(peopleRow).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, ${q(SOURCE)}, true, true
FROM ky_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The ${names.length} namesakes — guard lifted for this statement only ──────────────
--
-- Each was checked against the existing row and is a DIFFERENT person:
${names.map((p) => `--   ${p.name} (${p.chamber} ${p.district}): ${NAMESAKE_NOTE[p.name]}`).join('\n')}

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE ky_namesake_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ky_namesake_people(external_id, full_name, first_name, last_name) VALUES
${names.map(peopleRow).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, ${q(SOURCE)}, true, true
FROM ky_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 3. The 138 terms ─────────────────────────────────────────────────────────

CREATE TEMP TABLE ky_terms(
  geo_id text, district_type text, external_id bigint, term_start date, start_precision text
) ON COMMIT DROP;

INSERT INTO ky_terms(geo_id, district_type, external_id, term_start, start_precision) VALUES
${people.map(termRow).join(',\n')};

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, 'elected', ${q(SOURCE)}
FROM ky_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type = t.district_type AND lower(d.state) = 'ky'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.chambers c ON c.id = o.chamber_id
 AND c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate')
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── 4. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_terms int; v_seated int; v_day int; v_year int; v_unknown int;
  v_ended int; v_dupes int; v_offices int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2763000 AND -2762601;
  IF v_people <> 138 THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected 138 people in the reserved external_id block, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate');
  IF v_offices <> 138 THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected 138 Kentucky legislative offices, got % - run ${STRUCTURE_SLOT} first', v_offices;
  END IF;

  SELECT count(*), count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'year'),
         count(*) FILTER (WHERE ot.start_precision = 'unknown'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_terms, v_day, v_year, v_unknown, v_ended
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate');

  IF v_terms <> 138 THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected 138 terms, got %', v_terms;
  END IF;
  IF v_day <> ${people.filter((p) => p.precision === 'day').length} THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected ${people.filter((p) => p.precision === 'day').length} day-precision terms, got %', v_day;
  END IF;
  IF v_year <> ${people.filter((p) => p.precision === 'year').length} THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected ${people.filter((p) => p.precision === 'year').length} year-precision terms, got %', v_year;
  END IF;
  IF v_unknown <> 0 THEN
    RAISE EXCEPTION 'KY-2 occupancy: % term(s) have unknown precision; this wave dates every seat', v_unknown;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'KY-2 occupancy: % term(s) already ended; every seat here is currently held', v_ended;
  END IF;

  -- Count och.politician_id, never rows: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate');
  IF v_seated <> 138 THEN
    RAISE EXCEPTION 'KY-2 occupancy: expected 138 seated, got %', v_seated;
  END IF;

  -- Nobody may hold two Kentucky legislative seats.
  SELECT count(*) INTO v_dupes FROM (
    SELECT ot.politician_id
      FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate')
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dupes <> 0 THEN
    RAISE EXCEPTION 'KY-2 occupancy: % person/people hold more than one Kentucky legislative seat', v_dupes;
  END IF;

  RAISE NOTICE 'KY-2 occupancy OK: 138 people, 138 terms, 138 seated, % day / % year / 0 unknown', v_day, v_year;
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(OUT, `${STRUCTURE_SLOT}_ky_general_assembly_structure.sql`), S);
fs.writeFileSync(path.join(OUT, `${OCCUPANCY_SLOT}_ky_general_assembly_incumbents.sql`), O);
console.log(`${STRUCTURE_SLOT} and ${OCCUPANCY_SLOT} written to ${OUT}`);
console.log(`  people: ${plain.length} plain + ${names.length} namesakes = ${people.length}`);
console.log(`  terms : ${people.filter((p) => p.precision === 'day').length} day, ${people.filter((p) => p.precision === 'year').length} year, 0 unknown`);
