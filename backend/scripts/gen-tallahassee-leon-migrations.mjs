/**
 * gen-tallahassee-leon-migrations.mjs
 *
 * Turns data/seed-tallahassee-leon-2026/ROSTERS.md into three migrations:
 *
 *   CC_0011_tallahassee_structure.sql  district + government + chamber + offices (city)
 *   CC_0012_tallahassee_people.sql     politicians + occupancy (city)
 *   CC_0013_leon_county.sql            districts + government + chambers + offices
 *                                      + politicians + occupancy (county), in ONE
 *                                      migration per spec section 3
 *
 * Reads NOTHING from the database. Everything it asserts comes from the roster
 * file, and the migrations it emits re-assert those numbers against prod.
 *
 * Wave FL-4 of the Knight Foundation cities program.
 * Plan: docs/superpowers/plans/2026-08-28-knight-fl-wave-4-tallahassee-leon.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 TWO SHAPE DIFFERENCES FROM FL-3, AND BOTH INVERT AN ASSERTION.
 *
 * 1. TALLAHASSEE'S COMMISSION IS ENTIRELY AT-LARGE. All five seats share the ONE
 *    citywide district (TIGER place 1270600), and the Mayor is SEAT 4 inside that
 *    numbering rather than a separate office. So there is no ward layer, ONE
 *    chamber instead of two, num_officials is 5 rather than 1, and the structure
 *    gate asserts "exactly 5 offices on one district" -- the OPPOSITE shape from
 *    Bradenton's "exactly 1 per ward".
 *
 * 2. LEON IS A CHARTER COUNTY AND ELECTS SIX CONSTITUTIONAL OFFICERS, not five:
 *    it elects a Superintendent of Schools. So the Elected Officials chamber has
 *    official_count 6, and the countywide district carries EIGHT offices (2
 *    at-large + 6 officers) rather than seven.
 *
 * Also: no vacancy anywhere in this wave, so nothing is flagged is_vacant and
 * every one of the 18 offices must end with a term row.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 WHY THE COUNTY WAVE IS ONE MIGRATION AND THE CITY WAVE IS TWO.
 *
 * An office with no office_terms row is INVISIBLE: no holder, so the official
 * never appears anywhere, and nothing errors. Shipping county offices in one
 * migration and county people in the next would push
 * essentials.offices_missing_terms above its 699-unflagged baseline for the days
 * between the two applies. Spec section 3 therefore requires county offices and
 * people together. The city split is deliberate for a different reason: a
 * re-seat must never re-run office creation.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE COUNTS COMMENT IN ROSTERS.md IS THE FL-2 GUARD.
 *
 * FL-2 assumed 160 people for 160 offices and found 155. Nothing errored,
 * because ON CONFLICT DO NOTHING absorbs a missing person in silence. So the
 * roster file states its own counts, parseRosters() refuses a file whose tables
 * disagree with them, and every emitted post-verify gate is written from those
 * same numbers.
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROSTER = join(HERE, '..', 'data', 'seed-tallahassee-leon-2026', 'ROSTERS.md');
const MIGRATIONS = join(HERE, '..', 'migrations');

// ── Identity of the two jurisdictions ───────────────────────────────────────
// 🔴 THERE IS NO CITY MTFCC. Tallahassee's commission is entirely at-large, so
// the city has no district layer of its own -- FL-3's CITY_MTFCC and
// CITY_WARD_PREFIX are deliberately absent rather than left unused.
const COUNTY_MTFCC = 'X0038';
const PLACE_GEO_ID = '1270600';   // TIGER place, Tallahassee city (G4110). Loaded by FL-1.
const COUNTY_GEO_ID = '12073';    // TIGER county, Leon County (G4020). Pre-existing.
const COUNTY_DIST_PREFIX = 'leon-fl-commissioner-district-';

/** Measured empty in prod 2026-08-28: 0 rows between these bounds. */
const BAND_LO = -1249999;
const BAND_HI = -1240000;

const CITY_GOV = 'City of Tallahassee, Florida, US';
const COUNTY_GOV = 'Leon County, Florida, US';

/**
 * Slug -> (title, which district it hangs off). The ONLY place the mapping
 * lives, so the two migrations and the tests cannot drift apart.
 *
 * `on` is 'citywide' (TIGER place polygon), 'ward' (X0036), 'countywide' (the
 * pre-existing TIGER county district) or 'commdist' (X0037).
 */
const CITY_SEATS = {
  'seat-1':       { title: 'City Commissioner, Seat 1', chamber: 'City Commission', on: 'citywide' },
  'seat-2':       { title: 'City Commissioner, Seat 2', chamber: 'City Commission', on: 'citywide' },
  'seat-3':       { title: 'City Commissioner, Seat 3', chamber: 'City Commission', on: 'citywide' },
  'seat-4-mayor': { title: 'Mayor (Seat 4)',            chamber: 'City Commission', on: 'citywide' },
  'seat-5':       { title: 'City Commissioner, Seat 5', chamber: 'City Commission', on: 'citywide' },
};

const COUNTY_SEATS = {
  'commissioner-1': { title: 'Commissioner, District 1', chamber: 'Board of County Commissioners', on: 'commdist', n: 1 },
  'commissioner-2': { title: 'Commissioner, District 2', chamber: 'Board of County Commissioners', on: 'commdist', n: 2 },
  'commissioner-3': { title: 'Commissioner, District 3', chamber: 'Board of County Commissioners', on: 'commdist', n: 3 },
  'commissioner-4': { title: 'Commissioner, District 4', chamber: 'Board of County Commissioners', on: 'commdist', n: 4 },
  'commissioner-5': { title: 'Commissioner, District 5', chamber: 'Board of County Commissioners', on: 'commdist', n: 5 },
  // ⚠ "At Large, Group N" is LEON'S OWN naming. Manatee numbers its two at-large
  //    seats District 6 and District 7. Two counties in one state, two
  //    conventions -- follow the publisher, do not normalise.
  'at-large-group-1': { title: 'Commissioner, At Large Group 1', chamber: 'Board of County Commissioners', on: 'countywide' },
  'at-large-group-2': { title: 'Commissioner, At Large Group 2', chamber: 'Board of County Commissioners', on: 'countywide' },
  'sheriff':                 { title: 'Sheriff', chamber: 'Elected Officials', on: 'countywide' },
  'tax-collector':           { title: 'Tax Collector', chamber: 'Elected Officials', on: 'countywide' },
  'property-appraiser':      { title: 'Property Appraiser', chamber: 'Elected Officials', on: 'countywide' },
  'supervisor-of-elections': { title: 'Supervisor of Elections', chamber: 'Elected Officials', on: 'countywide' },
  'clerk-of-circuit-court':  { title: 'Clerk of the Circuit Court and Comptroller', chamber: 'Elected Officials', on: 'countywide' },
  // 🔴 THE SIXTH OFFICER, AND THE REASON THE COUNTS DIFFER FROM MANATEE'S.
  //    Leon is a CHARTER county (Home Rule Charter, 2002-11-12) and elects its
  //    Superintendent of Schools. Manatee, non-charter, does not have this office.
  //    The school BOARD remains out of scope -- see ROSTERS.md ruling R2.
  'superintendent-of-schools': { title: 'Superintendent of Schools', chamber: 'Elected Officials', on: 'countywide' },
};

/**
 * 🔴 NO MAYOR DESCRIPTION AND NO VACANCY CONSTANTS, DELIBERATELY.
 *
 * Bradenton needed both: its mayor presides over the council without a vote
 * except to break a tie (FL-3 ruling R2), and its county had a seat vacated by a
 * death. Tallahassee's mayor is Seat 4 of five equal commissioners with a full
 * vote, so there is no voting_powers ruling to carry; and no seat in this wave is
 * vacant, so nothing is flagged.
 */

/**
 * alternate_names, keyed by slug.
 *
 * 🔴 THREE OF THE SEVENTEEN ARE PUBLISHED UNDER A NICKNAME OR AN HONORIFIC, and
 * that is precisely the shape that breaks name matching later -- the Ben /
 * Benjamin Nadolski failure. full_name keeps the form the publisher uses, because
 * that is what a voter sees; the alternate carries the form a future dedupe pass
 * or headshot search is likely to hit.
 *
 *   sheriff                 'Charles R. "Rick" Wells'      -> Rick Wells
 *   clerk-of-circuit-court  'Angelina "Angel" Colonneso'   -> Angel Colonneso
 *   commissioner-5          'Dr. Bob McCann'               -> Robert McCann, Bob McCann
 *
 * McCann gets BOTH: the county and the Supervisor of Elections publish "Dr. Bob
 * McCann", while his 2024 ballot name was Robert McCann.
 */
const ALIASES = {
  // Published under a nickname by both the city and the Supervisor of Elections.
  'seat-1': ['Jack Porter'],
  // The Supervisor of Elections publishes the middle initial; the city does not.
  'supervisor-of-elections': ['Mark Earley'],
};

/** Filled by main() from the roster; see the band assertion in occupancySql(). */
let ALL_OWNED_IDS = [];

const VALID_PRECISION = new Set(['day', 'month', 'year', 'unknown']);
const VALID_HOW_STARTED = new Set(['elected', 'appointed', 'succeeded', 'redistricted', 'unknown']);

// ── Parsing ─────────────────────────────────────────────────────────────────

function parseTable(md, heading) {
  const start = md.indexOf(`### ${heading}`);
  if (start < 0) throw new Error(`ROSTERS.md has no "### ${heading}" section`);
  const rows = [];
  for (const line of md.slice(start).split('\n').slice(1)) {
    if (line.startsWith('###') || line.startsWith('<!--')) break;
    if (!line.trim().startsWith('|')) continue;
    const cells = line.split('|').slice(1, -1).map((c) => c.trim());
    if (cells.length !== 8) continue;
    if (cells[0] === 'Seat' || /^-+$/.test(cells[0])) continue;
    const [seat, slug, name, externalId, termStart, precision, howStarted, source] = cells;
    rows.push({ seat, slug, name, externalId, termStart, precision, howStarted, source });
  }
  return rows;
}

/**
 * Split a display name into first/last. The quoted-nickname case is the one that
 * matters: 'Charles R. "Rick" Wells' must give Charles / Wells, not Charles /
 * '"Rick"'. Strips any quoted nickname and any trailing suffix first.
 */
function splitName(full) {
  const suffixMatch = full.match(/,\s*(Jr\.?|Sr\.?|II|III|IV)\s*$/i);
  const nameSuffix = suffixMatch ? suffixMatch[1] : '';
  let base = suffixMatch ? full.slice(0, suffixMatch.index) : full;
  base = base.replace(/"[^"]*"/g, ' ').replace(/\s+/g, ' ').trim();
  const parts = base.split(' ').filter(Boolean);
  const honorific = /^(Dr|Mr|Mrs|Ms|Rev)\.?$/i;
  while (parts.length > 2 && honorific.test(parts[0])) parts.shift();
  const firstName = parts[0] ?? '';
  const lastName = parts.length > 1 ? parts[parts.length - 1] : '';
  const middle = parts.slice(1, -1).join(' ');
  const middleInitial = /^[A-Z]\.?$/.test(middle) ? middle.replace('.', '') : '';
  return { firstName, lastName, middleInitial, nameSuffix };
}

export function parseRosters(md) {
  const city = parseTable(md, 'City of Tallahassee');
  const county = parseTable(md, 'Leon County');

  const m = md.match(
    /<!--\s*COUNTS:\s*city_offices=(\d+)\s+city_people=(\d+)\s+county_offices=(\d+)\s+county_people=(\d+)\s+vacancies=(\d+)\s*-->/,
  );
  if (!m) throw new Error('ROSTERS.md is missing its COUNTS comment — refusing to generate');
  const counts = {
    cityOffices: Number(m[1]), cityPeople: Number(m[2]),
    countyOffices: Number(m[3]), countyPeople: Number(m[4]), vacancies: Number(m[5]),
  };

  const problems = [];
  const decorate = (rows, known, which) => rows.map((r) => {
    const def = known[r.slug];
    if (!def) { problems.push(`${which}: unrecognised slug "${r.slug}"`); return null; }
    const isVacant = r.name === 'VACANT';
    // ⚠ WIDENED FOR FL-4. FL-3's guard tested \((R|D|NPA|I)\), which does NOT match
    //    "(DEM)" -- and (DEM) is exactly what the LEON SOE prints beside all six
    //    constitutional officers. The narrower guard would have let it through.
    if (/\((R|D|DEM|REP|NPA|IND|LPF|GRE|I)\)|republican|democrat/i.test(r.name)) {
      problems.push(`${which}: party marking left in the name "${r.name}" — party lives on races.primary_party`);
    }
    if (!isVacant) {
      if (!VALID_PRECISION.has(r.precision)) problems.push(`${which} ${r.slug}: precision "${r.precision}" is not one of day/month/year/unknown`);
      if (!VALID_HOW_STARTED.has(r.howStarted)) problems.push(`${which} ${r.slug}: how_started "${r.howStarted}" is not one the CHECK accepts`);
      if (!r.termStart && r.precision !== 'unknown') problems.push(`${which} ${r.slug}: no term_start but precision is "${r.precision}" — a missing date must declare precision 'unknown'`);
      if (r.termStart && !/^\d{4}-\d{2}-\d{2}$/.test(r.termStart)) problems.push(`${which} ${r.slug}: term_start "${r.termStart}" is not YYYY-MM-DD`);
      if (!r.externalId) problems.push(`${which} ${r.slug}: seated person with no external_id`);
      if (!r.source) problems.push(`${which} ${r.slug}: no source`);
    }
    return { ...r, ...def, ...splitName(r.name), isVacant, aliases: ALIASES[r.slug] ?? [] };
  }).filter(Boolean);

  const cityRows = decorate(city, CITY_SEATS, 'city');
  const countyRows = decorate(county, COUNTY_SEATS, 'county');

  const ids = [...cityRows, ...countyRows].map((r) => r.externalId).filter(Boolean);
  const dupIds = ids.filter((x, i) => ids.indexOf(x) !== i);
  if (dupIds.length) problems.push(`duplicate external_id(s): ${[...new Set(dupIds)].join(', ')}`);
  for (const id of ids) {
    const n = Number(id);
    if (!(n >= BAND_LO && n <= BAND_HI)) problems.push(`external_id ${id} is outside the measured-empty band ${BAND_LO}..${BAND_HI}`);
  }

  const seated = (rows) => rows.filter((r) => !r.isVacant).length;
  const vacant = (rows) => rows.filter((r) => r.isVacant).length;
  if (cityRows.length !== counts.cityOffices) problems.push(`COUNTS: city table has ${cityRows.length} rows, COUNTS says ${counts.cityOffices}`);
  if (seated(cityRows) !== counts.cityPeople) problems.push(`COUNTS: city table has ${seated(cityRows)} people, COUNTS says ${counts.cityPeople}`);
  if (countyRows.length !== counts.countyOffices) problems.push(`COUNTS: county table has ${countyRows.length} rows, COUNTS says ${counts.countyOffices}`);
  if (seated(countyRows) !== counts.countyPeople) problems.push(`COUNTS: county table has ${seated(countyRows)} people, COUNTS says ${counts.countyPeople}`);
  if (vacant(cityRows) + vacant(countyRows) !== counts.vacancies) problems.push(`COUNTS: tables mark ${vacant(cityRows) + vacant(countyRows)} vacancies, COUNTS says ${counts.vacancies}`);

  if (problems.length) throw new Error(`ROSTERS.md is not usable:\n  - ${problems.join('\n  - ')}`);
  return { city: cityRows, county: countyRows, counts };
}

// ── SQL helpers ─────────────────────────────────────────────────────────────

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const qn = (s) => (s === '' || s === null || s === undefined ? 'NULL' : q(s));

function districtRef(seat) {
  switch (seat.on) {
    case 'citywide':   return { geoId: PLACE_GEO_ID, mtfcc: 'G4110', type: 'LOCAL' };
    case 'countywide': return { geoId: COUNTY_GEO_ID, mtfcc: 'G4020', type: 'COUNTY' };
    case 'commdist':   return { geoId: `${COUNTY_DIST_PREFIX}${seat.n}`, mtfcc: COUNTY_MTFCC, type: 'COUNTY' };
    default: throw new Error(`unknown district anchor "${seat.on}"`);
  }
}

/**
 * 🔴 Every district lookup pairs geo_id WITH mtfcc AND district_type, and
 * Florida is why. 12081 is both Manatee County (G4020) and State House District
 * 81 (G5220); 12020 is both SD-20 (G5210) and HD-20 (G5220). A bare geo_id
 * match at Bradenton City Hall returned four rows on 2026-08-28, two of them
 * officials in other counties, and nothing errored.
 */
function districtLookupSql(seat, alias = 'dd') {
  const r = districtRef(seat);
  return `SELECT ${alias}.id FROM essentials.districts ${alias}
   WHERE ${alias}.geo_id = ${q(r.geoId)} AND ${alias}.mtfcc = ${q(r.mtfcc)}
     AND ${alias}.district_type = ${q(r.type)} AND lower(${alias}.state) = 'fl'`;
}

function officeInsertSql(seat, govGeoId, govType, state, city) {
  // No per-seat description in FL-4: Tallahassee's mayor is Seat 4 of five equal
  // commissioners, so there is no tie-break rule to carry. See ROSTERS.md R5.
  const extra = '';
  const extraVal = '';
  return `INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, voting_powers${extra})
SELECT c.id, d.id, ${q(seat.title)}, ${q(state)}, ${qn(city)}, 'full'${extraVal}
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  ${districtLookupSql(seat)}
) d
WHERE g.geo_id = ${q(govGeoId)} AND g.type = ${q(govType)} AND c.name = ${q(seat.chamber)}
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = ${q(seat.title)}
  );`;
}

const HEADER = (file, companion, what) => `-- ${file}
-- Knight Foundation cities program, wave FL-3${companion ? `. Companion: ${companion}.` : '.'}
--
-- ${what}
--
-- Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
-- Plan:   docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md
-- Slice:  .planning/knight-foundation/fl.md
-- Roster: data/seed-bradenton-manatee-2026/ROSTERS.md
-- Generated by: scripts/gen-bradenton-manatee-migrations.mjs
--
-- ---------------------------------------------------------------------------
-- 🔴 EVERY DISTRICT LOOKUP PAIRS geo_id WITH mtfcc AND district_type.
-- In Florida the geo_id collision reaches the COUNTY layer: 12081 is Manatee
-- County (G4020) AND State House District 81 (G5220), and 12020 is SD-20
-- (G5210) AND HD-20 (G5220). Measured 2026-08-28, an unpaired join at Bradenton
-- City Hall returned four rows, two of them officials in other counties, with no
-- error. fl.md documented only the sldl/sldu half of this.
--
-- ---------------------------------------------------------------------------
-- No party affiliation is recorded. The Supervisor of Elections prints (R)
-- beside all seventeen names; it is discarded. Party lives on
-- races.primary_party.
--
-- No term_end is written. A future term_end makes a seat silently self-vacate,
-- and office_terms has no end_precision, so a published expiry YEAR cannot
-- become a term_end without inventing a day.
`;

// ── Migration 1: Bradenton structure ────────────────────────────────────────

function renderCityStructure(city, counts) {
  const parts = [];

  parts.push(HEADER(
    'CC_0011_tallahassee_structure.sql',
    'CC_0012_tallahassee_people.sql',
    `Creates the geography-and-seats half of the City of Tallahassee:\n--   * 1 LOCAL district -- citywide only (TIGER place ${PLACE_GEO_ID}); the commission is ENTIRELY AT-LARGE\n--   * 1 government, 1 chamber\n--   * ${counts.cityOffices} offices -- 4 City Commissioners + the Mayor, who is SEAT 4 of the same body`,
  ));

  parts.push(`
-- ---------------------------------------------------------------------------
-- 🔴 THE COMMISSION IS ENTIRELY AT-LARGE, WHICH INVERTS TWO ASSERTIONS.
-- The Supervisor of Elections: "City Commissioners and Mayor do not have
-- districts. Instead, all voters who live in Tallahassee can vote each of the
-- City Commissioner contests." And the city's own page is titled "Mayor John E.
-- Dailey - Seat 4".
--
-- So: ONE district for all five seats, num_officials 5 rather than 1, ONE chamber
-- rather than Bradenton's two, and the post-verify asserts "exactly 5 offices on
-- ONE district" -- the OPPOSITE of Bradenton's "exactly 1 per ward". Every
-- Tallahassee address returns all five commissioners.
--
-- ⚠ NO ward layer exists or is needed, so nothing here refers to an X-code.
--
-- ---------------------------------------------------------------------------
-- 🔴 NO voting_powers RULING IS REQUIRED, and that is a real difference from
-- FL-3. Bradenton's mayor presides over its council without a vote except to
-- break a tie, which forced a ruling. Tallahassee's mayor is Seat 4 of five equal
-- commissioners with a full vote -- one of the body, not presiding over it.
--
-- ⚠ Mayor Pro Tem IS NOT AN OFFICE. The commission elects one annually and it
-- rotates; Richardson holds it now and Williams-Cox has held it before. Same
-- disposition as Bradenton's Vice Mayor and Asheville's. ROSTERS.md ruling R3.

BEGIN;

-- --- 0. Pre-flight ----------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries
     WHERE geo_id = '${PLACE_GEO_ID}' AND mtfcc = 'G4110'
  ) THEN
    RAISE EXCEPTION 'tallahassee structure: TIGER place ${PLACE_GEO_ID}/G4110 is missing -- FL-1 must be applied first; ALL FIVE city seats hang off it';
  END IF;
END $$;

-- --- 1. The one citywide district ------------------------------------------
-- num_officials is 5, not 1: five seats really do share this district. Bradenton's
-- citywide district carries one office; Buncombe's X0034 rows carry 2 for the same
-- reason.

INSERT INTO essentials.districts (district_type, label, state, geo_id, mtfcc, num_officials)
SELECT 'LOCAL', 'Tallahassee Citywide', 'fl', '${PLACE_GEO_ID}', 'G4110', 5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '${PLACE_GEO_ID}' AND mtfcc = 'G4110' AND district_type = 'LOCAL'
);

-- --- 2. Government ----------------------------------------------------------

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT ${q(CITY_GOV)}, 'City', 'FL', 'Tallahassee', '${PLACE_GEO_ID}'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '${PLACE_GEO_ID}' AND type = 'City'
);

-- --- 3. Chamber -------------------------------------------------------------
-- ONE chamber. chambers.slug is GENERATED from name_formal and cannot be
-- inserted; a wrong name_formal silently yields a different slug.

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'City Commission', 'Tallahassee City Commission', 5, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${PLACE_GEO_ID}' AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'City Commission'
  );

-- --- 4. Offices -------------------------------------------------------------
-- Every title is distinct, so a NOT EXISTS-on-title guard is correct here and
-- cannot collapse rows.
`);

  for (const s of city) parts.push(officeInsertSql(s, PLACE_GEO_ID, 'City', 'FL', 'Tallahassee'));

  parts.push(`
-- --- 5. Post-verify gate ----------------------------------------------------
DO $$
DECLARE v_n int; v_gov uuid;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = '${PLACE_GEO_ID}' AND mtfcc = 'G4110' AND district_type = 'LOCAL';
  IF v_n <> 1 THEN RAISE EXCEPTION 'tallahassee structure: expected exactly 1 citywide district, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = '${PLACE_GEO_ID}' AND mtfcc = 'G4110' AND district_type = 'LOCAL'
     AND num_officials = 5;
  IF v_n <> 1 THEN RAISE EXCEPTION 'tallahassee structure: the citywide district does not carry num_officials = 5'; END IF;

  SELECT id INTO v_gov FROM essentials.governments
   WHERE geo_id = '${PLACE_GEO_ID}' AND type = 'City';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'tallahassee structure: the government row is missing'; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers WHERE government_id = v_gov;
  IF v_n <> 1 THEN RAISE EXCEPTION 'tallahassee structure: expected 1 chamber, got % -- Tallahassee''s mayor is Seat 4 of the commission, not a separate body', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers
   WHERE government_id = v_gov AND name = 'City Commission' AND official_count = 5;
  IF v_n <> 1 THEN RAISE EXCEPTION 'tallahassee structure: the chamber name or official_count is wrong'; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_n <> ${counts.cityOffices} THEN RAISE EXCEPTION 'tallahassee structure: expected ${counts.cityOffices} offices, got %', v_n; END IF;

  -- 🔴 ALL FIVE SEATS ON THE ONE CITYWIDE DISTRICT. This is the inverse of
  -- Bradenton's per-ward assertion, and it is the shape that makes an at-large
  -- body correct rather than five seats accidentally sharing a district.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND d.geo_id = '${PLACE_GEO_ID}' AND d.mtfcc = 'G4110'
     AND d.district_type = 'LOCAL';
  IF v_n <> ${counts.cityOffices} THEN RAISE EXCEPTION 'tallahassee structure: expected ${counts.cityOffices} offices on the citywide district, got %', v_n; END IF;

  -- ...and all five titles distinct, or two seats collapsed into one. A total-only
  -- count cannot see that.
  SELECT count(DISTINCT o.title) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_n <> ${counts.cityOffices} THEN RAISE EXCEPTION 'tallahassee structure: expected ${counts.cityOffices} DISTINCT seat titles, got %', v_n; END IF;

  -- The Mayor must be one of them, and must be full-voting with no note.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.title = 'Mayor (Seat 4)'
     AND o.voting_powers = 'full' AND o.representation_note IS NULL;
  IF v_n <> 1 THEN RAISE EXCEPTION 'tallahassee structure: the Mayor (Seat 4) office is missing or is not plain full-voting'; END IF;

  -- No office may sit on a district with no matching boundary.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_n <> 0 THEN RAISE EXCEPTION 'tallahassee structure: % office(s) sit on a district with no matching boundary', v_n; END IF;

  RAISE NOTICE 'tallahassee structure OK: 1 citywide district, 1 government, 1 chamber, ${counts.cityOffices} at-large offices';
END $$;

COMMIT;
`);
  return parts.join('\n');
}

// ── Occupancy blocks, shared by migrations 2 and 3 ──────────────────────────

function seedRowsSql(rows, tmp) {
  return rows.filter((r) => !r.isVacant).map((r) => {
    const d = districtRef(r);
    return `  (${q(d.geoId)}, ${q(d.mtfcc)}, ${q(d.type)}, ${q(r.title)}, ${r.externalId}, ` +
      `${q(r.name)}, ${qn(r.firstName)}, ${qn(r.lastName)}, ${qn(r.middleInitial)}, ${qn(r.nameSuffix)}, ` +
      `${r.aliases.length ? `ARRAY[${r.aliases.map(q).join(', ')}]::text[]` : `'{}'::text[]`}, ` +
      `${qn(r.termStart)}::date, ${q(r.precision)}, ${q(r.howStarted)}, ${q(r.source)})`;
  }).join(',\n');
}

function occupancySql(rows, tmp, label, ownedIds) {
  const seated = rows.filter((r) => !r.isVacant);
  const owned = ownedIds.join(', ');
  // The contiguous range this wave claims. Scoping the band guard to it lets
  // neighbouring Florida waves share -(1240000 + n) without seeing each other
  // as foreign, while still refusing an id somebody else already holds.
  const ownedLo = Math.min(...ownedIds);
  const ownedHi = Math.max(...ownedIds);
  return `
-- --- Politician identity band ----------------------------------------------
-- 🔴 NOBODY ELSE MAY ALREADY OWN THE IDS THIS WAVE IS ABOUT TO INSERT. That is
-- the FL-2 failure exactly: -(1210000 + n) collided with 166 existing rows, the
-- 2026 US House candidates, and ON CONFLICT DO NOTHING would have absorbed the
-- collision in silence and left seats held by whoever already owned those ids.
--
-- ⚠ THIS ASSERTION IS SCOPED TO THIS WAVE'S OWN SUB-RANGE, AND THAT MATTERS.
-- Three versions of this guard were wrong before this one:
--   1. "the band holds exactly N rows before this runs" -- NOT IDEMPOTENT: a
--      re-run of an applied migration counts its own rows and refuses. Measured.
--   2. The same count, in the post-verify -- gave the county migration a false
--      ORDERING DEPENDENCY on the city one.
--   3. "the whole band holds nothing this wave owns" -- correct within one wave,
--      but -(1240000 + n) is the SHARED Florida LOCAL band, so FL-4 saw FL-3's
--      seventeen legitimate rows as foreign and refused. It would also have
--      broken FL-3's OWN re-run once FL-4 applied. Measured 2026-08-28.
-- Scoping to [min..max] of this wave's ids catches the real risk -- an id already
-- taken -- while letting neighbouring waves share the band, and stays idempotent.
DO $$
DECLARE v_n int; v_foreign text;
BEGIN
  SELECT count(*), string_agg(external_id::text, ', ' ORDER BY external_id)
    INTO v_n, v_foreign
    FROM essentials.politicians
   WHERE external_id BETWEEN ${ownedLo} AND ${ownedHi}
     AND external_id NOT IN (${owned});
  IF v_n <> 0 THEN
    RAISE EXCEPTION '${label}: % row(s) inside this wave''s id range ${ownedLo}..${ownedHi} are owned by something else (%). Pick another sub-range rather than colliding.', v_n, v_foreign;
  END IF;
END $$;

-- 🔴 IDENTITY IS KEYED ON external_id, NEVER ON NAME. Checked in prod
-- 2026-08-28: none of the seventeen names in this wave matches any existing
-- politician row, so all are fresh inserts and nothing is reused. A name-based
-- guard is what seated a Wisconsin village trustee on the Nashville council.

CREATE TEMP TABLE ${tmp} (
  geo_id          text,
  mtfcc           text,
  district_type   text,
  office_title    text,
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  middle_initial  text,
  name_suffix     text,
  aliases         text[],
  term_start      date,
  start_precision text,
  how_started     text,
  source          text
) ON COMMIT DROP;

INSERT INTO ${tmp} VALUES
${seedRowsSql(rows, tmp)};

-- --- Payload guard ----------------------------------------------------------
DO $$
DECLARE v_n int; v_dup int;
BEGIN
  SELECT count(*) INTO v_n FROM ${tmp};
  IF v_n <> ${seated.length} THEN RAISE EXCEPTION '${label} payload: expected ${seated.length} rows, got %', v_n; END IF;

  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM ${tmp} GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION '${label} payload: % duplicate external_id(s)', v_dup; END IF;

  SELECT count(*) INTO v_n FROM ${tmp} WHERE ext_id NOT BETWEEN ${BAND_LO} AND ${BAND_HI};
  IF v_n <> 0 THEN RAISE EXCEPTION '${label} payload: % out-of-band external_id(s)', v_n; END IF;

  -- Every (geo_id, mtfcc, district_type, title) is a single seat in this wave.
  SELECT count(*) INTO v_dup FROM (
    SELECT geo_id, mtfcc, district_type, office_title FROM ${tmp}
    GROUP BY geo_id, mtfcc, district_type, office_title HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION '${label} payload: % duplicate seat key(s)', v_dup; END IF;

  -- A row with no term_start MUST declare 'unknown'. Nine of this wave's
  -- eighteen people are in exactly this position: no reachable publisher gives a
  -- start date, and a guessed term_start is a false statement about history that
  -- no end_precision exists to soften.
  SELECT count(*) INTO v_n FROM ${tmp} WHERE term_start IS NULL AND start_precision <> 'unknown';
  IF v_n <> 0 THEN RAISE EXCEPTION '${label} payload: % row(s) have no term_start but claim a precision', v_n; END IF;

  -- And every seat named must resolve to exactly one office in prod.
  SELECT count(*) INTO v_n FROM ${tmp} s
   WHERE (SELECT count(*) FROM essentials.offices o
            JOIN essentials.districts d ON d.id = o.district_id
           WHERE d.geo_id = s.geo_id AND d.mtfcc = s.mtfcc
             AND d.district_type = s.district_type AND lower(d.state) = 'fl'
             AND o.title = s.office_title) <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION '${label} payload: % seat(s) do not resolve to exactly one office -- run the structure half first', v_n; END IF;
END $$;

-- --- Politicians ------------------------------------------------------------
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name,
       nullif(s.middle_initial, ''), nullif(s.name_suffix, ''),
       s.aliases, true, true, s.source
FROM ${tmp} s
ON CONFLICT (external_id) DO NOTHING;

-- --- Occupancy --------------------------------------------------------------
-- 🔴 TWO PATHS, AND THE SECOND ONE IS NOT A SHORTCUT.
--
-- essentials.seat_officeholder() REFUSES a NULL term_start outright: "pass Jan 1
-- with p_start_precision => 'year' rather than NULL." Measured against prod
-- 2026-08-28. But this wave has three people for whom NO publisher gives any
-- start date at all, and inventing Jan 1 of a guessed year would be a false
-- statement about history that no end_precision exists to soften.
--
-- The schema itself allows the honest record, and prod is full of it: all 81,676
-- 'unknown'-precision office_terms rows carry term_start IS NULL, written by the
-- ADR 0002 phase-2 backfill. Only the HELPER refuses it.
--
-- So the dated rows go through the helper, as the house rule requires, and the
-- undated rows are inserted directly -- but ONLY into an office that has zero
-- existing term rows. That condition is what makes bypassing the helper safe:
-- the helper's two-step exists to close a predecessor before an open-ended range
-- overlaps it, and with no predecessor there is nothing to close and the
-- exclusion constraint cannot fire. The guard below refuses rather than guesses
-- if that stops being true.
DO $$
DECLARE r record; v_seated int := 0; v_blank int := 0; v_prior int;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, s.how_started, s.source,
           o.id AS office_id, p.id AS politician_id
      FROM ${tmp} s
      JOIN essentials.districts d
        ON d.geo_id = s.geo_id AND d.mtfcc = s.mtfcc
       AND d.district_type = s.district_type AND lower(d.state) = 'fl'
      JOIN essentials.offices o ON o.district_id = d.id AND o.title = s.office_title
      JOIN essentials.politicians p ON p.external_id = s.ext_id
     WHERE NOT EXISTS (
       SELECT 1 FROM essentials.office_terms t
        WHERE t.office_id = o.id AND t.politician_id = p.id
     )
  LOOP
    IF r.term_start IS NOT NULL THEN
      PERFORM essentials.seat_officeholder(
        r.office_id, r.politician_id, r.term_start, r.source, r.how_started, r.start_precision
      );
      v_seated := v_seated + 1;
    ELSE
      IF r.start_precision <> 'unknown' THEN
        RAISE EXCEPTION '${label}: office % has no term_start but claims precision % -- refusing', r.office_id, r.start_precision;
      END IF;
      SELECT count(*) INTO v_prior FROM essentials.office_terms t WHERE t.office_id = r.office_id;
      IF v_prior <> 0 THEN
        RAISE EXCEPTION '${label}: office % already carries % term row(s), so an undated open term cannot be inserted directly -- close the predecessor and give this person a real date', r.office_id, v_prior;
      END IF;
      INSERT INTO essentials.office_terms
        (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
      VALUES (r.office_id, r.politician_id, NULL, NULL, 'unknown', r.how_started, r.source);
      v_blank := v_blank + 1;
    END IF;
  END LOOP;
  RAISE NOTICE '${label}: seated % dated official(s) via the helper, % with an honest unknown start', v_seated, v_blank;
END $$;
`;
}

// ── Migration 2: Bradenton people ──────────────────────────────────────────

function renderCityPeople(city, counts) {
  const cityIds = city.map((r) => r.externalId).filter(Boolean).join(', ');
  const parts = [];
  parts.push(HEADER(
    'CC_0012_tallahassee_people.sql',
    'CC_0011_tallahassee_structure.sql',
    `Seats the ${counts.cityPeople} elected officials of the City of Tallahassee:\n--   * ${counts.cityPeople} politicians in the -(1240000 + n) band\n--   * ${counts.cityPeople} office_terms rows, all on the ONE citywide district`,
  ));

  parts.push(`
-- ---------------------------------------------------------------------------
-- 🔴 term_start IS THE START OF CONTINUOUS OCCUPANCY, NOT OF THE CURRENT TERM.
--
-- Mayor Dailey's own page: "John was elected Mayor of the City of Tallahassee in
-- 2018." Members take office on the 13th day after the General Election, so
-- November 2018 at MONTH precision. ⚠ His EARLIER service was on the LEON COUNTY
-- COMMISSION, District 3, 2006-2018 -- a different office, so the mayoralty starts
-- in 2018, not 2006. Commissioner Matlow is dated the same way from his own page.
--
-- 🔴 THREE OF THE FIVE HAVE start_precision 'unknown' AND NO term_start:
-- Porter (Seat 1), Richardson (Seat 2) and Williams-Cox (Seat 5). No reachable
-- publisher gives a start date -- their own city pages carry none, and the
-- Supervisor of Elections publishes only a "next election" year.
--
-- ⚠ THE CERTIFIED-RESULTS PDFs WERE REJECTED AS A DATE SOURCE. A parser slicing
-- each race's candidates came out SHIFTED BY ONE RACE and reported
-- "Mayor -> Jeremy Matlow" for 2018, when Dailey won the mayoralty and Matlow won
-- Seat 3. Plausible, wrong, and it would have seated two people on each other's
-- dates. An honest blank beats a confident error, and there is no end_precision to
-- soften a wrong start. ROSTERS.md defects D4 and D5 carry the detail and the
-- follow-up (the city clerk's organisational minutes would date all three).

BEGIN;
${occupancySql(city, 'tlh_seed', 'tallahassee people', ALL_OWNED_IDS)}
-- --- Post-verify gate ------------------------------------------------------
DO $$
DECLARE v_gov uuid; v_pol int; v_seated int; v_unknown int; v_n int;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '${PLACE_GEO_ID}' AND type = 'City';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'tallahassee people: the government row is missing -- apply the structure half first'; END IF;

  -- ⚠ COUNT THIS MIGRATION'S OWN IDS, NOT THE WHOLE BAND. Counting the band makes
  -- the migration non-idempotent once a later wave adds to it, and it is weaker:
  -- a foreign row that happens to make the count match would pass.
  SELECT count(*) INTO v_pol FROM essentials.politicians
   WHERE external_id IN (${cityIds});
  IF v_pol <> ${counts.cityPeople} THEN RAISE EXCEPTION 'tallahassee people: expected ${counts.cityPeople} of this wave''s politicians, got %', v_pol; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs from
  -- offices, so a vacancy is a NULL politician_id and count(*) passes vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov;
  IF v_seated <> ${counts.cityPeople} THEN RAISE EXCEPTION 'tallahassee people: expected ${counts.cityPeople} seated officials, found %', v_seated; END IF;

  -- 🔴 ALL FIVE SEATED ON THE ONE CITYWIDE DISTRICT. An at-large body is only
  -- correct if every seat resolves from the same polygon.
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.geo_id = '${PLACE_GEO_ID}' AND d.mtfcc = 'G4110' AND d.district_type = 'LOCAL';
  IF v_n <> ${counts.cityPeople} THEN RAISE EXCEPTION 'tallahassee people: the citywide district has % seated member(s), expected ${counts.cityPeople}', v_n; END IF;

  -- No vacancy anywhere in this wave.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.is_vacant = true;
  IF v_n <> 0 THEN RAISE EXCEPTION 'tallahassee people: % office(s) flagged vacant, expected 0', v_n; END IF;

  -- 🔴 THE THREE HONEST BLANKS MUST STILL BE BLANK. If a later pass invents dates
  -- for Porter, Richardson or Williams-Cox, this gate is where that shows up.
  SELECT count(*) INTO v_unknown
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.start_precision = 'unknown' AND t.term_start IS NULL;
  IF v_unknown <> 3 THEN RAISE EXCEPTION 'tallahassee people: expected 3 unknown-precision open-ended terms, got %', v_unknown; END IF;

  -- And the two dated ones must still be dated, at month precision.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.start_precision = 'month' AND t.term_start = DATE '2018-11-01';
  IF v_n <> 2 THEN RAISE EXCEPTION 'tallahassee people: expected 2 month-precision 2018-11 terms (Mayor Dailey and Seat 3 Matlow), got %', v_n; END IF;

  -- No office with neither a term row nor a vacancy flag: the one failure mode CI
  -- cannot catch.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_terms t ON t.office_id = o.id
   WHERE c.government_id = v_gov AND t.id IS NULL AND o.is_vacant = false;
  IF v_n <> 0 THEN RAISE EXCEPTION 'tallahassee people: % office(s) have no term row and no vacancy flag', v_n; END IF;

  RAISE NOTICE 'tallahassee people OK: ${counts.cityPeople} politicians, ${counts.cityPeople} seated on one at-large district, 3 unknown-precision, 0 vacant';
END $$;

COMMIT;
`);
  return parts.join('\n');
}

// ── Migration 3: Manatee County, offices AND people ────────────────────────

function renderCounty(county, counts) {
  const countyIds = county.map((r) => r.externalId).filter(Boolean).join(', ');
  const commSeats = county.filter((s) => s.on === 'commdist');
  const parts = [];

  parts.push(HEADER(
    'CC_0013_leon_county.sql',
    null,
    `Creates Leon County whole -- offices AND people in ONE migration, per spec section 3:\n--   * 5 new COUNTY districts (mtfcc ${COUNTY_MTFCC}); the countywide district ALREADY EXISTS\n--   * 1 government, 2 chambers\n--   * ${counts.countyOffices} offices -- 7 commissioners + SIX constitutional officers\n--   * ${counts.countyPeople} politicians and ${counts.countyPeople} terms; NO vacancies`,
  ));

  parts.push(`
-- ---------------------------------------------------------------------------
-- 🔴 LEON IS A CHARTER COUNTY AND ELECTS *SIX* CONSTITUTIONAL OFFICERS.
-- Its Home Rule Charter has been in force since 2002-11-12 (the county's own
-- "Leading the Way" page). The sixth office is the SUPERINTENDENT OF SCHOOLS,
-- which the Supervisor of Elections lists under "Leon County Constitutional
-- Offices" with its own four-year term.
--
-- ⚠ MANATEE, WHICH IS NON-CHARTER, ELECTS FIVE (CC_0010). This is the variation
-- fl.md warns against inheriting, and it is a real seat rather than a naming
-- difference. So the Elected Officials chamber is official_count 6 here, and the
-- countywide district carries EIGHT offices, not seven.
-- ⚠ NOTHING here may be inherited by Palm Beach or Miami-Dade. Miami-Dade is also
-- a charter county and is read separately at FL-6.
--
-- ⚠ The school BOARD stays out of scope, as Manatee's did: a board is a separate
-- legislative body, and spec section 3 stage 4 is "commission layer + county
-- officers". ROSTERS.md ruling R2.
--
-- ---------------------------------------------------------------------------
-- 🔴 SEVEN COMMISSIONERS, FIVE POLYGONS. Districts 1-5 are single-member. The
-- other two are elected COUNTYWIDE and hang off the PRE-EXISTING COUNTY district
-- for TIGER county ${COUNTY_GEO_ID}, together with all six constitutional officers.
--
-- ⚠ LEON CALLS THEM "At Large, Group 1" AND "At Large, Group 2". MANATEE CALLS
-- ITS TWO "District 6" AND "District 7". Two counties in one state, two
-- conventions, both as published. Do not normalise either.
--
-- ---------------------------------------------------------------------------
-- ⚠ NO VACANCY IN THIS WAVE, so nothing is flagged is_vacant -- which means every
-- one of the ${counts.countyOffices} offices MUST end with a term row. The reachability baseline
-- holds no fl| bucket in any check, so a single office with neither a term row nor
-- a flag creates a NEW fl|COUNTY DEAD_GEOGRAPHY bucket and fails CI.
--
-- ---------------------------------------------------------------------------
-- 🔴 FIVE DIFFERENT TAKE-OFFICE RULES SPAN THIS WAVE, and they are why the
-- term_start months differ:
--   City Commission          13th day after the General Election
--   County Commission        2nd Tuesday after the General Election
--   Superintendent           2nd Tuesday after the General Election
--   The other five officers  1st Tuesday after the 1st Monday in January
-- The commissioners' months come from the county's published service-year ranges
-- plus the second rule. The six officers have NO published start at all and are
-- written at 'unknown' precision -- see ROSTERS.md defect D5.

BEGIN;

-- --- 0. Pre-flight ----------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = '${COUNTY_MTFCC}';
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'leon county: expected 5 ${COUNTY_MTFCC} boundaries, found % -- run scripts/load-leon-commission-boundaries.ts first', v_n;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '${COUNTY_GEO_ID}' AND mtfcc = 'G4020'
  ) THEN
    RAISE EXCEPTION 'leon county: TIGER county ${COUNTY_GEO_ID}/G4020 is missing';
  END IF;

  -- The countywide district must ALREADY exist. This migration must not create a
  -- second one: 7 of its 12 offices hang off it.
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = '${COUNTY_GEO_ID}' AND mtfcc = 'G4020' AND district_type = 'COUNTY' AND lower(state) = 'fl';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'leon county: expected exactly 1 pre-existing COUNTY district for ${COUNTY_GEO_ID}, found %', v_n;
  END IF;
END $$;

-- --- 1. The five single-member commission districts ------------------------
`);

  for (const s of commSeats) {
    parts.push(`INSERT INTO essentials.districts (district_type, label, state, geo_id, mtfcc, num_officials)
SELECT 'COUNTY', 'Leon County Commissioner District ${s.n}', 'fl', '${COUNTY_DIST_PREFIX}${s.n}', '${COUNTY_MTFCC}', 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '${COUNTY_DIST_PREFIX}${s.n}' AND mtfcc = '${COUNTY_MTFCC}' AND district_type = 'COUNTY'
);`);
  }

  parts.push(`
-- --- 2. Government ----------------------------------------------------------

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT ${q(COUNTY_GOV)}, 'County', 'FL', NULL, '${COUNTY_GEO_ID}'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '${COUNTY_GEO_ID}' AND type = 'County'
);

-- --- 3. Chambers ------------------------------------------------------------
-- chambers.slug is GENERATED from name_formal and cannot be inserted.

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Board of County Commissioners', 'Leon County Board of County Commissioners', 7, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${COUNTY_GEO_ID}' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
     WHERE c.government_id = g.id AND c.name = 'Board of County Commissioners'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Elected Officials', 'Leon County Elected Officials', 6, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${COUNTY_GEO_ID}' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
     WHERE c.government_id = g.id AND c.name = 'Elected Officials'
  );

-- --- 4. Offices -------------------------------------------------------------
`);

  for (const s of county) parts.push(officeInsertSql(s, COUNTY_GEO_ID, 'County', 'FL', null));

  parts.push(`
-- --- 5. Structure post-verify gate ----------------------------------------
DO $$
DECLARE v_gov uuid; v_n int; v_d text;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE mtfcc = '${COUNTY_MTFCC}' AND district_type = 'COUNTY' AND lower(state) = 'fl';
  IF v_n <> 5 THEN RAISE EXCEPTION 'leon county: expected 5 ${COUNTY_MTFCC} districts, got %', v_n; END IF;

  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '${COUNTY_GEO_ID}' AND type = 'County';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'leon county: the government row is missing'; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers WHERE government_id = v_gov;
  IF v_n <> 2 THEN RAISE EXCEPTION 'leon county: expected 2 chambers, got %', v_n; END IF;

  -- 🔴 SIX, NOT FIVE. Leon is a charter county and elects a Superintendent of
  -- Schools. Manatee's equivalent assertion is 5.
  SELECT count(*) INTO v_n FROM essentials.chambers
   WHERE government_id = v_gov AND ((name = 'Board of County Commissioners' AND official_count = 7)
                                 OR (name = 'Elected Officials' AND official_count = 6));
  IF v_n <> 2 THEN RAISE EXCEPTION 'leon county: chamber names or official_counts are wrong -- Elected Officials must be 6, not 5'; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_n <> ${counts.countyOffices} THEN RAISE EXCEPTION 'leon county: expected ${counts.countyOffices} offices, got %', v_n; END IF;

  -- PER CHAMBER, not just in total.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Board of County Commissioners';
  IF v_n <> 7 THEN RAISE EXCEPTION 'leon county: expected 7 commissioner offices, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Elected Officials';
  IF v_n <> 6 THEN RAISE EXCEPTION 'leon county: expected 6 constitutional officer offices, got %', v_n; END IF;

  -- The Superintendent specifically, because a count of 6 could be reached by
  -- duplicating another officer.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.title = 'Superintendent of Schools';
  IF v_n <> 1 THEN RAISE EXCEPTION 'leon county: the Superintendent of Schools office is missing'; END IF;

  -- PER DISTRICT: one commissioner per single-member district...
  FOR v_d IN SELECT '${COUNTY_DIST_PREFIX}' || g FROM generate_series(1,5) g LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = v_d AND d.mtfcc = '${COUNTY_MTFCC}' AND d.district_type = 'COUNTY';
    IF v_n <> 1 THEN RAISE EXCEPTION 'leon county: commission district % carries % offices, expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- ...and exactly 8 on the countywide district: 2 at-large + 6 officers.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND d.geo_id = '${COUNTY_GEO_ID}'
     AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY';
  IF v_n <> 8 THEN RAISE EXCEPTION 'leon county: expected 8 offices on the countywide district (2 at-large + 6 officers), got %', v_n; END IF;

  -- 🔴 No office may have landed on a Leon County in ANOTHER state, and none may
  -- sit on a district with no boundary.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov AND lower(d.state) <> 'fl';
  IF v_n <> 0 THEN RAISE EXCEPTION 'leon county: % office(s) landed outside Florida', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_n <> 0 THEN RAISE EXCEPTION 'leon county: % office(s) sit on a district with no matching boundary', v_n; END IF;

  RAISE NOTICE 'leon county structure OK: 5 new districts, 1 government, 2 chambers, ${counts.countyOffices} offices';
END $$;
${occupancySql(county, 'leon_seed', 'leon county', ALL_OWNED_IDS)}
-- --- 6. Occupancy post-verify gate ----------------------------------------
DO $$
DECLARE v_gov uuid; v_pol int; v_seated int; v_n int; v_d text;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '${COUNTY_GEO_ID}' AND type = 'County';

  -- ⚠ THIS MIGRATION'S OWN IDS, not the band: a band count is non-idempotent and
  -- would also give this migration a false ordering dependency on the city half.
  SELECT count(*) INTO v_pol FROM essentials.politicians
   WHERE external_id IN (${countyIds});
  IF v_pol <> ${counts.countyPeople} THEN
    RAISE EXCEPTION 'leon county: expected ${counts.countyPeople} of this wave''s politicians, got %', v_pol;
  END IF;

  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov;
  IF v_seated <> ${counts.countyPeople} THEN RAISE EXCEPTION 'leon county: expected ${counts.countyPeople} seated officials, found %', v_seated; END IF;

  -- 🔴 NO VACANCY. Manatee's equivalent gate expects exactly 1; Leon expects 0,
  -- which means every office must carry a term row.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.is_vacant = true;
  IF v_n <> 0 THEN RAISE EXCEPTION 'leon county: % office(s) flagged vacant, expected 0', v_n; END IF;

  -- One seated commissioner per single-member district -- ALL FIVE, unlike
  -- Manatee's loop which had to skip its vacant District 1.
  FOR v_d IN SELECT '${COUNTY_DIST_PREFIX}' || g FROM generate_series(1,5) g LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id = v_d AND d.mtfcc = '${COUNTY_MTFCC}' AND d.district_type = 'COUNTY';
    IF v_n <> 1 THEN RAISE EXCEPTION 'leon county: commission district % has % seated member(s), expected 1', v_d, v_n; END IF;
  END LOOP;

  -- All eight countywide seats filled: 2 at-large + 6 officers.
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov AND d.geo_id = '${COUNTY_GEO_ID}'
     AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY';
  IF v_n <> 8 THEN RAISE EXCEPTION 'leon county: expected 8 seated countywide officials, got %', v_n; END IF;

  -- 🔴 THE SIX HONEST BLANKS MUST STILL BE BLANK -- the constitutional officers,
  -- for whom no publisher gives a start date. If a later pass invents dates, this
  -- is where it shows up.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Elected Officials'
     AND t.start_precision = 'unknown' AND t.term_start IS NULL;
  IF v_n <> 6 THEN RAISE EXCEPTION 'leon county: expected 6 unknown-precision officer terms, got %', v_n; END IF;

  -- And all seven commissioners dated at month precision, in November.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Board of County Commissioners'
     AND t.start_precision = 'month' AND extract(month FROM t.term_start) = 11;
  IF v_n <> 7 THEN RAISE EXCEPTION 'leon county: expected 7 month-precision November commissioner terms, got %', v_n; END IF;

  -- No office with neither a term row nor a vacancy flag.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_terms t ON t.office_id = o.id
   WHERE c.government_id = v_gov AND t.id IS NULL AND o.is_vacant = false;
  IF v_n <> 0 THEN RAISE EXCEPTION 'leon county: % office(s) have no term row and no vacancy flag', v_n; END IF;

  RAISE NOTICE 'leon county OK: ${counts.countyOffices} offices, ${counts.countyPeople} seated, 0 vacant, 6 unknown-precision officers';
END $$;

COMMIT;
`);
  return parts.join('\n');
}

// ── Main ────────────────────────────────────────────────────────────────────

function main() {
  const md = readFileSync(ROSTER, 'utf8');
  const { city, county, counts } = parseRosters(md);

  // The full set of external_ids this wave owns, shared by both occupancy
  // migrations so each can refuse a foreign row in the band while staying
  // idempotent about its own.
  ALL_OWNED_IDS = [...city, ...county]
    .map((r) => r.externalId).filter(Boolean)
    .map(Number).sort((a, b) => a - b);

  const files = [
    ['CC_0011_tallahassee_structure.sql', renderCityStructure(city, counts)],
    ['CC_0012_tallahassee_people.sql', renderCityPeople(city, counts)],
    ['CC_0013_leon_county.sql', renderCounty(county, counts)],
  ];
  for (const [name, body] of files) {
    writeFileSync(join(MIGRATIONS, name), body.replace(/\n{3,}/g, '\n\n'));
    console.log(`wrote migrations/${name}  (${body.split('\n').length} lines)`);
  }
  console.log(
    `\n${counts.cityOffices} city offices / ${counts.cityPeople} city people, ` +
    `${counts.countyOffices} county offices / ${counts.countyPeople} county people, ` +
    `${counts.vacancies} vacancy.`,
  );
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) main();
