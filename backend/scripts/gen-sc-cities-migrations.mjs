#!/usr/bin/env node
/**
 * gen-sc-cities-migrations.mjs — Knight program, wave SC-3.
 *
 * Reads data/sc-cities-roster.json and emits the two migrations:
 *
 *   migrations/CC_0127_sc_cities_structure.sql     2 governments, 4 chambers, 6 districts, 14 offices
 *   migrations/CC_0128_sc_cities_incumbents.sql    14 seated, 14 people created
 *
 * Both slots were RESERVED from the allocator (`steward slot CC`). Reads nothing from the
 * database and writes nothing to it.
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'sc-cities-roster.json');
const MIGRATIONS = path.join(HERE, '..', 'migrations');

const BAND_FROM = -2745400;
const BAND_TO = -2745301;
const SOURCE =
  "Columbia and Myrtle Beach city council pages (citycouncil.columbiasc.gov; " +
  'cityofmyrtlebeach.com/government/mayor___city_council), cross-checked against the Municipal ' +
  "Association of South Carolina's directory (masc.sc); arrivals from the cities' own records, " +
  'read 2026-09-20 (SC-3)';

/** Seats whose name collides with a DIFFERENT person's active row. Read before classified. */
const NAMESAKES = {
  'columbia:Sam P. Johnson':
    'The existing Sam Johnson (external_id -880002) holds BOARD MEMBER, PLACE 2 on a TEXAS school board. The roster Sam P. Johnson is the at-large councilman for Columbia, South Carolina, sworn in 2026-01-05. Different state, different office, different person. ' +
    'A surname pass over rows with any South Carolina connection also found three Johnsons and one Bailey — all state legislators seated by SC-2, all different people.',
};

const q = (s) => String(s).replace(/'/g, "''");
const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8'));

const seats = [];
for (const city of roster.cities) {
  for (const m of city.members) {
    seats.push({ ...m, cityKey: city.key, cityName: city.name, placeGeoId: city.place_geo_id });
  }
}
if (seats.length !== 14) throw new Error(`expected 14 seats, roster has ${seats.length}`);

// 🔴 The armed set must not collide with itself — SC-2 was bitten by two sitting legislators
// sharing a name, and a pre-flight against PRODUCTION cannot see that.
const seen = new Map();
for (const s of seats) {
  const key = `${s.first_name} ${s.last_name}`.toLowerCase();
  if (seen.has(key) && !NAMESAKES[`${s.cityKey}:${s.full_name}`]) {
    throw new Error(`two rows share (first_name, last_name) "${key}": ${seen.get(key)} and ${s.full_name}`);
  }
  seen.set(key, s.full_name);
}

let next = BAND_TO;
for (const s of seats) s.external_id = next--;
if (next < BAND_FROM) throw new Error('external_id band exhausted');
const armed = seats.filter((s) => !NAMESAKES[`${s.cityKey}:${s.full_name}`]);
const lifted = seats.filter((s) => NAMESAKES[`${s.cityKey}:${s.full_name}`]);
const dated = seats.filter((s) => s.term_start);

const COL = roster.cities.find((c) => c.key === 'columbia');
const MB = roster.cities.find((c) => c.key === 'myrtle-beach');

// ── districts ────────────────────────────────────────────────────────────────
const districts = [
  ...[1, 2, 3, 4].map((n) => ({
    geo_id: `cola-council-district-${n}`,
    mtfcc: 'X0059',
    label: `Columbia City Council District ${n}`,
    gov: COL.place_geo_id,
  })),
  { geo_id: COL.place_geo_id, mtfcc: 'G4110', label: 'Columbia Citywide', gov: COL.place_geo_id },
  { geo_id: MB.place_geo_id, mtfcc: 'G4110', label: 'Myrtle Beach Citywide', gov: MB.place_geo_id },
];

const offices = seats.map((s) => ({
  title: s.title,
  district_geo_id: s.district_geo_id,
  district_mtfcc: s.district_mtfcc,
  chamber: s.chamber,
  gov: s.placeGeoId,
}));

const officeCountPerKey = new Map();
for (const o of offices) {
  const k = `${o.gov}|${o.chamber}|${o.district_geo_id}|${o.district_mtfcc}|${o.title}`;
  officeCountPerKey.set(k, (officeCountPerKey.get(k) ?? 0) + 1);
}

// ── CC_0127: structure ───────────────────────────────────────────────────────

const structure = `-- CC_0127_sc_cities_structure.sql
-- Knight Foundation program, wave SC-3 (structure half). Slot RESERVED from the allocator.
--
-- Seats nobody. Creates the two city governments, their four chambers, the six districts they
-- need and the 14 offices. CC_0128 puts people in them, and the two are applied back to back.
--
-- Production held NOTHING for either city before this wave: one South Carolina government row
-- (the state), no city government, no local district, no city office. Measured 2026-09-20.
--
-- 🔴 THE TWO JURISDICTIONS ARE NOT MADE UNIFORM, AND THE DIFFERENCE IS THE POINT:
--   Columbia — Mayor + SIX council members: 4 on single-member district polygons and 2 AT-LARGE,
--   unnumbered, on the citywide polygon. The council's own page: "City Council consists of the
--   Mayor, Council District members (4), and At-Large Council members (2)" — so the council of
--   SEVEN counts the mayor, and official_count carries the city's own number.
--   Myrtle Beach — Mayor + SIX council members, ALL AT LARGE. The Municipal Association of South
--   Carolina's directory states the method in one word, "At large". NO ward or district layer
--   exists and none is invented: Tallahassee, State College and Boulder again.
--
-- 🔴 COLUMBIA'S FOUR DISTRICT POLYGONS MUST ALREADY EXIST. scripts/load-columbia-council-boundaries.mjs
-- loads them as X0059; this migration ABORTS if they are absent, because an office on a district
-- with no polygon is unreachable by any address and NOTHING ERRORS.
--
-- 🔴 THE JOIN KEY IS (geo_id, mtfcc). '45079' is Richland County AND State House District 79 —
-- Richland is Columbia's county — and '45051' is Horry County AND House District 51. Nothing here
-- matches on a geo_id alone, and the gate asserts that no county or legislative district picked
-- up a city office.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the polygons every office in this wave hangs on ───────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = 'X0059' AND state = '45';
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'SC-3 structure: expected 4 X0059 council-district boundaries, found % — run scripts/load-columbia-council-boundaries.mjs first', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'G4110' AND state = '45' AND geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'SC-3 structure: expected the Columbia and Myrtle Beach place polygons, found %', v_n;
  END IF;
END $$;

-- ─── 1. The two governments ───────────────────────────────────────────────────
${roster.cities
  .map(
    (c) => `INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT '${q(c.name)}', 'City', 'SC', '${c.place_geo_id}'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '${c.place_geo_id}' AND state = 'SC');`,
  )
  .join('\n\n')}

-- ─── 2. The four chambers ─────────────────────────────────────────────────────
-- official_count is each city's OWN number, not a house convention: Columbia says seven
-- (counting the mayor), Myrtle Beach's charter seats a mayor and six councilmembers.
${roster.cities
  .flatMap((c) => [
    `INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, '${q(c.council_chamber)}', '${q(c.council_chamber)}', ${c.council_official_count}
FROM essentials.governments g
WHERE g.geo_id = '${c.place_geo_id}' AND g.state = 'SC'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch WHERE ch.government_id = g.id AND ch.name = '${q(c.council_chamber)}');`,
    `INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Office of the Mayor', 'Office of the Mayor of ${q(c.key === 'columbia' ? 'Columbia' : 'Myrtle Beach')}', 1
FROM essentials.governments g
WHERE g.geo_id = '${c.place_geo_id}' AND g.state = 'SC'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch WHERE ch.government_id = g.id AND ch.name = 'Office of the Mayor');`,
  ])
  .join('\n\n')}

-- ─── 3. The six districts ─────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, mtfcc, district_type, label, state, government_id)
SELECT v.geo_id, v.mtfcc, 'LOCAL', v.label, 'sc', gov.id
FROM (VALUES
${districts.map((d) => `  ('${d.geo_id}', '${d.mtfcc}', '${q(d.label)}', '${d.gov}')`).join(',\n')}
) AS v(geo_id, mtfcc, label, gov_geo_id)
JOIN essentials.governments gov ON gov.geo_id = v.gov_geo_id AND gov.state = 'SC'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = v.geo_id AND d.mtfcc = v.mtfcc);

-- ─── 4. The 14 offices ────────────────────────────────────────────────────────
-- ⚠ The at-large seats are UNNUMBERED: two Columbia offices and six Myrtle Beach offices share a
-- title on their own citywide polygon. The COUNT is what distinguishes them, not a seat number
-- the cities do not use — the Fort Wayne, Duluth and Philadelphia convention.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, v.title, 'SC', v.city, 1, false, 'full'
FROM (VALUES
${offices
  .map(
    (o, i) =>
      `  (${i}, '${q(o.title)}', '${o.district_geo_id}', '${o.district_mtfcc}', '${q(o.chamber)}', '${o.gov}', '${o.gov === COL.place_geo_id ? 'Columbia' : 'Myrtle Beach'}')`,
  )
  .join(',\n')}
) AS v(ord, title, district_geo_id, district_mtfcc, chamber_name, gov_geo_id, city)
JOIN essentials.governments gov ON gov.geo_id = v.gov_geo_id AND gov.state = 'SC'
JOIN essentials.chambers c ON c.government_id = gov.id AND c.name = v.chamber_name
JOIN essentials.districts d ON d.geo_id = v.district_geo_id AND d.mtfcc = v.district_mtfcc AND lower(d.state) = 'sc'
WHERE (
  SELECT count(*) FROM essentials.offices o
   WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title
) < (
  -- how many offices this wave wants with exactly this (chamber, district, title)
  SELECT count(*) FROM (VALUES
${offices.map((o, i) => `    (${i}, '${q(o.title)}', '${o.district_geo_id}', '${o.district_mtfcc}', '${q(o.chamber)}', '${o.gov}')`).join(',\n')}
  ) AS w(ord, title, district_geo_id, district_mtfcc, chamber_name, gov_geo_id)
  WHERE w.title = v.title AND w.district_geo_id = v.district_geo_id
    AND w.district_mtfcc = v.district_mtfcc AND w.chamber_name = v.chamber_name
    AND w.gov_geo_id = v.gov_geo_id
);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE
  v_gov      int;
  v_ch       int;
  v_d        int;
  v_col      int;
  v_mb       int;
  v_leak     int;
  v_nodist   int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE state = 'SC' AND geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}') AND type = 'City';
  IF v_gov <> 2 THEN RAISE EXCEPTION 'SC-3 structure: expected 2 city governments, got %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers ch
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}');
  IF v_ch <> 4 THEN RAISE EXCEPTION 'SC-3 structure: expected 4 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_d FROM essentials.districts
   WHERE lower(state) = 'sc' AND (mtfcc = 'X0059' OR (mtfcc = 'G4110' AND geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}')));
  IF v_d <> 6 THEN RAISE EXCEPTION 'SC-3 structure: expected 6 districts, got %', v_d; END IF;

  SELECT count(*) INTO v_col FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '${COL.place_geo_id}' AND g.state = 'SC';
  SELECT count(*) INTO v_mb FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '${MB.place_geo_id}' AND g.state = 'SC';
  IF v_col <> 7 OR v_mb <> 7 THEN
    RAISE EXCEPTION 'SC-3 structure: expected 7 Columbia and 7 Myrtle Beach offices, got % and %', v_col, v_mb;
  END IF;

  -- Every Columbia district polygon carries exactly one district office; the citywide polygons
  -- carry the mayor plus the at-large seats.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
     LEFT JOIN essentials.offices o ON o.district_id = d.id
     WHERE d.mtfcc = 'X0059' AND lower(d.state) = 'sc'
     GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'SC-3 structure: a Columbia council district does not carry exactly one office';
  END IF;

  -- 🔴 THE COLLISION GATE. Nothing in this wave may have landed on a county or a legislative
  -- district: '45079' is Richland County AND House District 79.
  SELECT count(*) INTO v_leak FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'sc'
     AND d.district_type::text IN ('COUNTY','STATE_LOWER','STATE_UPPER')
     AND o.title LIKE 'Council Member%';
  IF v_leak <> 0 THEN
    RAISE EXCEPTION 'SC-3 structure: % county/legislative district(s) picked up a city office — a geo_id-only join', v_leak;
  END IF;

  -- No city office may hang on a district with no polygon.
  SELECT count(*) INTO v_nodist FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}')
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc AND b.state = '45');
  IF v_nodist <> 0 THEN
    RAISE EXCEPTION 'SC-3 structure: % city office(s) sit on a district with no polygon — unreachable by address', v_nodist;
  END IF;

  RAISE NOTICE 'SC-3 structure OK: 2 governments, 4 chambers, 6 districts, 7 + 7 offices, 0 on a county';
END $$;

COMMIT;
`;

// ── CC_0128: occupancy ───────────────────────────────────────────────────────

const peopleRow = (s) =>
  `  (${s.external_id}, '${q(s.full_name)}', '${q(s.first_name)}', '${q(s.last_name)}', '{}'::text[])`;
const termRow = (s) =>
  `  ('${s.district_geo_id}', '${s.district_mtfcc}', '${q(s.title)}', '${s.placeGeoId}', ${s.external_id}::bigint, ` +
  `${s.term_start ? `'${s.term_start}'::date` : 'NULL::date'}, '${s.start_precision}', '${s.how_started ?? 'unknown'}')`;

const datedList = dated
  .map((s) => `--     ${s.cityKey === 'columbia' ? 'COL' : 'MB '} ${s.term_start} (${s.start_precision.padEnd(5)}) ${s.full_name}`)
  .join('\n');
const namesakeNotes = Object.entries(NAMESAKES)
  .map(([k, why]) => `--     ${k}\n--       ${why}`)
  .join('\n');

const occupancy = `-- CC_0128_sc_cities_incumbents.sql
-- Knight Foundation program, wave SC-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0127, which creates the governments, chambers, districts and the
-- 14 offices.
--
-- Seats all 14 Columbia and Myrtle Beach city offices:
--    ${seats.length} people created here, external_id band ${BAND_FROM} .. ${BAND_TO}
--    0 people reused — no roster name matched an existing South Carolina row
--    0 offices left unseated — neither council has a vacancy today
--
-- 🔴🔴 EIGHT TERMS ARE DATED AND SIX ARE NOT, AND THE SPLIT IS NOT ABOUT EFFORT. Myrtle Beach
-- publishes a "Who Served When" history giving each member's service by month; Columbia
-- publishes election YEARS on member profiles and nothing else. An election year is not a term
-- start, so Columbia's six continuing members are written open-ended at 'unknown'.
${datedList}
--
-- 🔴 A RE-ELECTION DOES NOT RESTART AN OCCUPANCY, AND THREE SEATS HERE WOULD HAVE BEEN WRONG.
-- Columbia's mayor, its District 1 and its District 4 members were all sworn in on 2026-01-05,
-- and Myrtle Beach's Lowder and Hatley on 2026-01-13 — every one of them a RE-election. Writing
-- the swearing-in would have restarted occupancies that never stopped: Lowder has served since
-- January 2010 and Hatley since January 2018.
--
-- 🔴 AND THE OPPOSITE CASE IS IN THE SAME WAVE. Myrtle Beach's Philip N. Render served from
-- January 2004 to December 2023, was OUT for the 2024-2025 term, and returned on 2026-01-13.
-- "First elected" would overstate his current occupancy by 22 years; the gap is why his date is
-- the swearing-in and not his first election.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
--
-- 🔴 PARTY IS NOT WRITTEN. Both councils are elected non-partisan; party lives on
-- races.primary_party in any case.
--
-- 🔴 ONE ROSTER NAME MATCHES AN EXISTING ROW, AND IT IS A DIFFERENT PERSON:
${namesakeNotes}
--
-- ⚠ THE GUARD IS LIFTED FOR ${lifted.length} ROW, NOT FOR THE MIGRATION. The other ${armed.length} rows are inserted with
-- essentials.politicians' duplicate-name trigger ARMED, so a namesake nobody anticipated still
-- stops this migration.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*).

BEGIN;

-- ─── ${armed.length} people with no active namesake — guard ARMED ──────────────────────────────
CREATE TEMP TABLE sc3_new_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO sc3_new_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
${armed.map(peopleRow).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '${q(SOURCE)} (CC_0128, SC-3)', n.alternate_names
FROM sc3_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── ${lifted.length} person who shares a name with a DIFFERENT person — guard lifted ─────────
SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE sc3_namesake_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO sc3_namesake_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
${lifted.map(peopleRow).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '${q(SOURCE)} (CC_0128, SC-3)', n.alternate_names
FROM sc3_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 14 terms, one per office ─────────────────────────────────────────────────
-- ⚠ The at-large offices are indistinguishable by (district, title): six Myrtle Beach rows share
-- one. They are matched to people by ROW NUMBER within the group, which is why this table carries
-- the office title AND the government, and why the gate below counts holders per office.
CREATE TEMP TABLE sc3_terms(district_geo_id text, district_mtfcc text, title text, gov_geo_id text,
                            external_id bigint, term_start date, start_precision text, how_started text)
  ON COMMIT DROP;
INSERT INTO sc3_terms(district_geo_id, district_mtfcc, title, gov_geo_id, external_id, term_start, start_precision, how_started) VALUES
${seats.map(termRow).join(',\n')};

WITH office_slot AS (
  SELECT o.id AS office_id, d.geo_id AS district_geo_id, d.mtfcc AS district_mtfcc, o.title,
         g.geo_id AS gov_geo_id,
         row_number() OVER (PARTITION BY g.geo_id, d.geo_id, d.mtfcc, o.title ORDER BY o.id) AS slot
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}')
), term_slot AS (
  SELECT t.*, row_number() OVER (PARTITION BY t.gov_geo_id, t.district_geo_id, t.district_mtfcc, t.title
                                 ORDER BY t.external_id DESC) AS slot
    FROM sc3_terms t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT os.office_id, p.id, ts.term_start, NULL, ts.start_precision, ts.how_started, '${q(SOURCE)} (CC_0128, SC-3)'
FROM term_slot ts
JOIN office_slot os
  ON os.gov_geo_id = ts.gov_geo_id AND os.district_geo_id = ts.district_geo_id
 AND os.district_mtfcc = ts.district_mtfcc AND os.title = ts.title AND os.slot = ts.slot
JOIN essentials.politicians p ON p.external_id = ts.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = os.office_id AND ot.politician_id = p.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE
  v_people int; v_offices int; v_terms int; v_seated int; v_dated int; v_ended int;
  v_fanout int; v_double int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN ${BAND_FROM} AND ${BAND_TO};
  IF v_people <> ${seats.length} THEN
    RAISE EXCEPTION 'SC-3 occupancy: expected ${seats.length} people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}');
  IF v_offices <> 14 THEN RAISE EXCEPTION 'SC-3 occupancy: expected 14 city offices, got %', v_offices; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}');
  IF v_terms <> 14 THEN RAISE EXCEPTION 'SC-3 occupancy: expected 14 terms, got %', v_terms; END IF;

  -- 🔴 count och.politician_id, never count(*) — office_current_holder LEFT JOINs from offices.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.state = 'SC' AND g.geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}');
  IF v_seated <> 14 THEN RAISE EXCEPTION 'SC-3 occupancy: expected 14 seated offices, got %', v_seated; END IF;

  SELECT count(*) INTO v_dated FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}')
     AND ot.term_start IS NOT NULL;
  IF v_dated <> ${dated.length} THEN
    RAISE EXCEPTION 'SC-3 occupancy: expected ${dated.length} dated term(s), got %', v_dated;
  END IF;

  -- The two dates that carry a rule. Render returned after a gap; Lowder never left.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot
      JOIN essentials.politicians p ON p.id = ot.politician_id
     WHERE p.full_name = 'Philip N. Render' AND ot.term_start = DATE '2026-01-13' AND ot.start_precision = 'day'
  ) THEN
    RAISE EXCEPTION 'SC-3 occupancy: Render is not seated from 2026-01-13 — the return after a gap, not his 2004 arrival';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot
      JOIN essentials.politicians p ON p.id = ot.politician_id
     WHERE p.last_name = 'Lowder' AND ot.term_start = DATE '2010-01-01' AND ot.start_precision = 'month'
  ) THEN
    RAISE EXCEPTION 'SC-3 occupancy: Lowder is not seated from January 2010 — a re-election does not restart an occupancy';
  END IF;

  SELECT count(*) INTO v_ended FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}')
     AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'SC-3 occupancy: % term(s) carry a term_end', v_ended; END IF;

  -- Nobody holds two of these 14 seats, and no office has two holders.
  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers ch ON ch.id = o.chamber_id
      JOIN essentials.governments g ON g.id = ch.government_id
     WHERE g.state = 'SC' AND g.geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}')
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_fanout <> 0 THEN
    RAISE EXCEPTION 'SC-3 occupancy: % person(s) hold more than one of these city seats', v_fanout;
  END IF;

  SELECT count(*) INTO v_double FROM (
    SELECT ot.office_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers ch ON ch.id = o.chamber_id
      JOIN essentials.governments g ON g.id = ch.government_id
     WHERE g.state = 'SC' AND g.geo_id IN ('${COL.place_geo_id}','${MB.place_geo_id}')
     GROUP BY ot.office_id HAVING count(*) > 1) y;
  IF v_double <> 0 THEN
    RAISE EXCEPTION 'SC-3 occupancy: % office(s) carry more than one term', v_double;
  END IF;

  RAISE NOTICE 'SC-3 occupancy OK: 14 offices, 14 terms, 14 seated, ${dated.length} dated, 0 ended';
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(MIGRATIONS, 'CC_0127_sc_cities_structure.sql'), structure);
fs.writeFileSync(path.join(MIGRATIONS, 'CC_0128_sc_cities_incumbents.sql'), occupancy);
console.log('CC_0127: 2 governments, 4 chambers, 6 districts, 14 offices');
console.log(`CC_0128: ${armed.length} guard-armed + ${lifted.length} guard-lifted = ${seats.length} seats, ${dated.length} dated`);
console.log(`         external_id band ${BAND_FROM} .. ${BAND_TO}, ${seats.length} used`);
