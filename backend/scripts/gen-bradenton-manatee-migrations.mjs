/**
 * gen-bradenton-manatee-migrations.mjs
 *
 * Turns data/seed-bradenton-manatee-2026/ROSTERS.md into three migrations:
 *
 *   CC_0008_bradenton_structure.sql   districts + government + chambers + offices (city)
 *   CC_0009_bradenton_people.sql      politicians + occupancy (city)
 *   CC_0010_manatee_county.sql        districts + government + chambers + offices
 *                                    + politicians + occupancy (county), in ONE
 *                                    migration per spec section 3
 *
 * Reads NOTHING from the database. Everything it asserts comes from the roster
 * file, and the migrations it emits re-assert those numbers against prod.
 *
 * Wave FL-3 of the Knight Foundation cities program.
 * Plan: docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md
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
const ROSTER = join(HERE, '..', 'data', 'seed-bradenton-manatee-2026', 'ROSTERS.md');
const MIGRATIONS = join(HERE, '..', 'migrations');

// ── Identity of the two jurisdictions ───────────────────────────────────────
const CITY_MTFCC = 'X0036';
const COUNTY_MTFCC = 'X0037';
const PLACE_GEO_ID = '1207950';   // TIGER place, Bradenton city (G4110). Loaded by FL-1.
const COUNTY_GEO_ID = '12081';    // TIGER county, Manatee County (G4020). Pre-existing.
const CITY_WARD_PREFIX = 'bradenton-fl-council-ward-';
const COUNTY_DIST_PREFIX = 'manatee-fl-commissioner-district-';

/** Measured empty in prod 2026-08-28: 0 rows between these bounds. */
const BAND_LO = -1249999;
const BAND_HI = -1240000;

const CITY_GOV = 'City of Bradenton, Florida, US';
const COUNTY_GOV = 'Manatee County, Florida, US';

/**
 * Slug -> (title, which district it hangs off). The ONLY place the mapping
 * lives, so the two migrations and the tests cannot drift apart.
 *
 * `on` is 'citywide' (TIGER place polygon), 'ward' (X0036), 'countywide' (the
 * pre-existing TIGER county district) or 'commdist' (X0037).
 */
const CITY_SEATS = {
  'mayor':  { title: 'Mayor', chamber: 'Office of the Mayor', on: 'citywide' },
  'ward-1': { title: 'Council Member, Ward 1', chamber: 'City Council', on: 'ward', n: 1 },
  'ward-2': { title: 'Council Member, Ward 2', chamber: 'City Council', on: 'ward', n: 2 },
  'ward-3': { title: 'Council Member, Ward 3', chamber: 'City Council', on: 'ward', n: 3 },
  'ward-4': { title: 'Council Member, Ward 4', chamber: 'City Council', on: 'ward', n: 4 },
  'ward-5': { title: 'Council Member, Ward 5', chamber: 'City Council', on: 'ward', n: 5 },
};

const COUNTY_SEATS = {
  'commissioner-1': { title: 'Commissioner, District 1', chamber: 'Board of County Commissioners', on: 'commdist', n: 1 },
  'commissioner-2': { title: 'Commissioner, District 2', chamber: 'Board of County Commissioners', on: 'commdist', n: 2 },
  'commissioner-3': { title: 'Commissioner, District 3', chamber: 'Board of County Commissioners', on: 'commdist', n: 3 },
  'commissioner-4': { title: 'Commissioner, District 4', chamber: 'Board of County Commissioners', on: 'commdist', n: 4 },
  'commissioner-5': { title: 'Commissioner, District 5', chamber: 'Board of County Commissioners', on: 'commdist', n: 5 },
  'commissioner-6': { title: 'Commissioner, District 6 (At-Large)', chamber: 'Board of County Commissioners', on: 'countywide' },
  'commissioner-7': { title: 'Commissioner, District 7 (At-Large)', chamber: 'Board of County Commissioners', on: 'countywide' },
  'sheriff': { title: 'Sheriff', chamber: 'Elected Officials', on: 'countywide' },
  'tax-collector': { title: 'Tax Collector', chamber: 'Elected Officials', on: 'countywide' },
  'property-appraiser': { title: 'Property Appraiser', chamber: 'Elected Officials', on: 'countywide' },
  'supervisor-of-elections': { title: 'Supervisor of Elections', chamber: 'Elected Officials', on: 'countywide' },
  'clerk-of-circuit-court': { title: 'Clerk of the Circuit Court and Comptroller', chamber: 'Elected Officials', on: 'countywide' },
};

/**
 * Charter ruling R2, from ROSTERS.md. The tie-break lives in offices.description
 * and NOT in representation_note, because both read paths hide the note when
 * voting_powers = 'full', and the mayoralty itself is a full-powered executive
 * office. See ROSTERS.md for the full reasoning and for the alternative.
 */
const MAYOR_DESCRIPTION =
  'Ex officio president of the City Council. Votes only to break a tie among the five ward ' +
  'council members; the mayoralty itself is a full-powered elected executive office. A charter ' +
  'amendment on the November 2026 ballot would remove the ex officio presidency and the ' +
  'tie-breaking vote.';

/** 🔴 offices.vacant_since, from ROSTERS.md defect D2. The county's own announcement. */
const D1_VACANT_SINCE = '2026-02-24';
const D1_VACANCY_SOURCE = 'mymanatee-d1-vacant-2026-02-24';

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
  'sheriff': ['Rick Wells'],
  'clerk-of-circuit-court': ['Angel Colonneso'],
  'commissioner-5': ['Robert McCann', 'Bob McCann'],
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
  const city = parseTable(md, 'City of Bradenton');
  const county = parseTable(md, 'Manatee County');

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
    if (/\((R|D|NPA|I)\)|republican|democrat/i.test(r.name)) {
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
    case 'ward':       return { geoId: `${CITY_WARD_PREFIX}${seat.n}`, mtfcc: CITY_MTFCC, type: 'LOCAL' };
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
  const extra = seat.slug === 'mayor'
    ? `, description`
    : '';
  const extraVal = seat.slug === 'mayor' ? `, ${q(MAYOR_DESCRIPTION)}` : '';
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
  const wardSeats = city.filter((s) => s.on === 'ward');
  const parts = [];

  parts.push(HEADER(
    'CC_0008_bradenton_structure.sql',
    'CC_0009_bradenton_people.sql',
    `Creates the geography-and-seats half of the City of Bradenton:\n--   * 6 LOCAL districts -- 1 citywide (TIGER place ${PLACE_GEO_ID}) + 5 wards (mtfcc ${CITY_MTFCC})\n--   * 1 government, 2 chambers\n--   * ${counts.cityOffices} offices -- 1 Mayor + 5 ward council members`,
  ));

  parts.push(`
-- ---------------------------------------------------------------------------
-- 🔴 THE MAYOR IS voting_powers 'full', AND NASHVILLE'S VICE MAYOR WAS NOT.
-- Bradenton's Mayor is ex officio president of the council and votes only to
-- break a tie -- the same charter shape as Nashville sec. 3.03, which CC_0004
-- wrote 'non_voting'. This wave rules the other way on purpose. Nashville's Vice
-- Mayor exists ONLY to preside over the council, so "no vote in it" is the whole
-- truth about that seat. Bradenton's Mayor is the chief executive, elected
-- citywide on their own ballot line, in an Office of the Mayor chamber of one:
-- the tie-break is a council procedure, not a limit on the mayoralty, and
-- 'non_voting' would tell a voter this executive has no vote.
--
-- The rule is carried in offices.description, because BOTH read paths hide
-- representation_note when voting_powers = 'full'. Full reasoning, and the
-- one-line alternative, in ROSTERS.md ruling R2.
--
-- ---------------------------------------------------------------------------
-- ⚠ Vice Mayor and Second Vice Mayor are council-elected ANNUAL ROLES here, not
-- offices -- the council chose them at the 2025-01-06 swearing-in and they
-- rotate. Same disposition as Asheville (CA_0009), opposite of Nashville, where
-- the Vice Mayor is separately elected countywide. No office rows. ROSTERS.md
-- ruling R3.
--
-- ⚠ The City Clerk is appointed staff, not an elected office. Ruling R4.

BEGIN;

-- --- 0. Pre-flight: refuse to create offices whose district has no polygon ---
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = '${CITY_MTFCC}';
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'bradenton structure: expected 5 ${CITY_MTFCC} boundaries, found % -- run scripts/load-bradenton-ward-boundaries.ts first', v_n;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries
     WHERE geo_id = '${PLACE_GEO_ID}' AND mtfcc = 'G4110'
  ) THEN
    RAISE EXCEPTION 'bradenton structure: TIGER place ${PLACE_GEO_ID}/G4110 is missing -- FL-1 must be applied first';
  END IF;
END $$;

-- --- 1. Districts -----------------------------------------------------------
-- Synthetic districts carry no ocd_id and no government_id, matching X0032-X0035
-- and Asheville Citywide. state is LOWER case here and UPPER case on
-- governments/offices; both conventions are live in prod.

INSERT INTO essentials.districts (district_type, label, state, geo_id, mtfcc, num_officials)
SELECT 'LOCAL', 'Bradenton Citywide', 'fl', '${PLACE_GEO_ID}', 'G4110', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '${PLACE_GEO_ID}' AND mtfcc = 'G4110' AND district_type = 'LOCAL'
);
`);

  for (const s of wardSeats) {
    parts.push(`INSERT INTO essentials.districts (district_type, label, state, geo_id, mtfcc, num_officials)
SELECT 'LOCAL', 'Bradenton City Council Ward ${s.n}', 'fl', '${CITY_WARD_PREFIX}${s.n}', '${CITY_MTFCC}', 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '${CITY_WARD_PREFIX}${s.n}' AND mtfcc = '${CITY_MTFCC}' AND district_type = 'LOCAL'
);`);
  }

  parts.push(`
-- --- 2. Government ----------------------------------------------------------

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT ${q(CITY_GOV)}, 'City', 'FL', 'Bradenton', '${PLACE_GEO_ID}'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '${PLACE_GEO_ID}' AND type = 'City'
);

-- --- 3. Chambers ------------------------------------------------------------
-- chambers.slug is GENERATED from name_formal and cannot be inserted. Getting
-- name_formal wrong silently yields a different slug.
--
-- official_count is 5 for the council: the charter body is five ward members.
-- The Mayor sits in a chamber of one, which is what ruling R2 turns on.

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'City Council', 'Bradenton City Council', 5, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${PLACE_GEO_ID}' AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'City Council'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Office of the Mayor', 'Office of the Mayor of Bradenton', 1, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${PLACE_GEO_ID}' AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Office of the Mayor'
  );

-- --- 4. Offices -------------------------------------------------------------
-- Every title is distinct, so a NOT EXISTS-on-title guard is correct here and
-- cannot collapse rows.
`);

  for (const s of city) parts.push(officeInsertSql(s, PLACE_GEO_ID, 'City', 'FL', 'Bradenton'));

  parts.push(`
-- --- 5. Post-verify gate ----------------------------------------------------
-- 🔴 COUNTS ARE PER DISTRICT, NOT JUST IN TOTAL. A total-only assertion is
-- exactly what the CA_0006 multi-seat bug satisfied while landing seats on the
-- wrong districts.
DO $$
DECLARE v_n int; v_gov uuid; v_d text; v_desc int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE mtfcc = '${CITY_MTFCC}' AND district_type = 'LOCAL' AND lower(state) = 'fl';
  IF v_n <> 5 THEN RAISE EXCEPTION 'bradenton structure: expected 5 ${CITY_MTFCC} districts, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = '${PLACE_GEO_ID}' AND mtfcc = 'G4110' AND district_type = 'LOCAL';
  IF v_n <> 1 THEN RAISE EXCEPTION 'bradenton structure: expected exactly 1 citywide district, got %', v_n; END IF;

  SELECT id INTO v_gov FROM essentials.governments
   WHERE geo_id = '${PLACE_GEO_ID}' AND type = 'City';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'bradenton structure: the government row is missing'; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers WHERE government_id = v_gov;
  IF v_n <> 2 THEN RAISE EXCEPTION 'bradenton structure: expected 2 chambers, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers
   WHERE government_id = v_gov AND ((name = 'City Council' AND official_count = 5)
                                 OR (name = 'Office of the Mayor' AND official_count = 1));
  IF v_n <> 2 THEN RAISE EXCEPTION 'bradenton structure: chamber names or official_counts are wrong'; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_n <> ${counts.cityOffices} THEN RAISE EXCEPTION 'bradenton structure: expected ${counts.cityOffices} offices, got %', v_n; END IF;

  -- Exactly one council member per ward, counted PER WARD.
  FOR v_d IN SELECT '${CITY_WARD_PREFIX}' || g FROM generate_series(1,5) g LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = v_d AND d.mtfcc = '${CITY_MTFCC}' AND d.district_type = 'LOCAL';
    IF v_n <> 1 THEN RAISE EXCEPTION 'bradenton structure: ward district % carries % offices, expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- The Mayor is on the CITYWIDE district, and is the only office there.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND d.geo_id = '${PLACE_GEO_ID}' AND d.mtfcc = 'G4110'
     AND d.district_type = 'LOCAL' AND o.title = 'Mayor';
  IF v_n <> 1 THEN RAISE EXCEPTION 'bradenton structure: expected 1 Mayor office on the citywide district, got %', v_n; END IF;

  -- 🔴 Ruling R2 must have SURVIVED generation: the Mayor is 'full' and the
  -- tie-break text is present. A generator that dropped the description would
  -- pass every count above.
  SELECT count(*) INTO v_desc FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.title = 'Mayor'
     AND o.voting_powers = 'full' AND o.description ILIKE '%tie%';
  IF v_desc <> 1 THEN RAISE EXCEPTION 'bradenton structure: the Mayor office lost its voting_powers ruling or its tie-break description'; END IF;

  -- No office may sit on a district with no matching boundary: that is an
  -- office nobody can reach by address, and nothing else errors.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_n <> 0 THEN RAISE EXCEPTION 'bradenton structure: % office(s) sit on a district with no matching boundary', v_n; END IF;

  RAISE NOTICE 'bradenton structure OK: 6 districts, 1 government, 2 chambers, ${counts.cityOffices} offices';
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
  return `
-- --- Politician identity band ----------------------------------------------
-- 🔴 THE BAND MUST HOLD NOTHING THIS WAVE DOES NOT OWN. The obvious FL band was
-- TAKEN in FL-2: -(1210000 + n) collided with 166 existing rows, the 2026 US
-- House candidates, and ON CONFLICT DO NOTHING would have absorbed that in
-- silence and left seats held by whoever already owned those ids.
-- -1249999..-1240000 was measured EMPTY on 2026-08-28.
--
-- ⚠ THIS IS AN ALLOWLIST, NOT A COUNT, AND THE DIFFERENCE IS TWO BUGS.
-- The first version asserted "the band holds exactly N rows before this runs".
-- That is NOT IDEMPOTENT -- a re-run of an applied migration counts its own rows
-- and refuses, which a migration in this repo is required not to do (measured:
-- it refused with "found 17"). It is also WEAKER: a foreign row that happened to
-- make the count match would pass. Naming the ids this wave owns fixes both.
DO $$
DECLARE v_n int; v_foreign text;
BEGIN
  SELECT count(*), string_agg(external_id::text, ', ' ORDER BY external_id)
    INTO v_n, v_foreign
    FROM essentials.politicians
   WHERE external_id BETWEEN ${BAND_LO} AND ${BAND_HI}
     AND external_id NOT IN (${owned});
  IF v_n <> 0 THEN
    RAISE EXCEPTION '${label}: the external_id band ${BAND_LO}..${BAND_HI} holds % row(s) this wave does not own (%). The band was measured EMPTY on 2026-08-28 -- pick another band rather than colliding.', v_n, v_foreign;
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

  -- A row with no term_start MUST declare 'unknown'. Three Bradenton council
  -- members are in exactly this position: no publisher gives a start date, and
  -- a guessed-late term_start is a false statement about history that no
  -- end_precision exists to soften.
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
    'CC_0009_bradenton_people.sql',
    'CC_0008_bradenton_structure.sql',
    `Seats the ${counts.cityPeople} elected officials of the City of Bradenton:\n--   * ${counts.cityPeople} politicians in the -(1240000 + n) band\n--   * ${counts.cityPeople} office_terms rows via essentials.seat_officeholder()`,
  ));

  parts.push(`
-- ---------------------------------------------------------------------------
-- 🔴 term_start IS THE START OF CONTINUOUS OCCUPANCY, NOT OF THE CURRENT TERM,
-- AND A PUBLISHED EXPIRY IS NOT AN ELECTION DATE.
--
-- Mayor Brown's term expires January 2029, and he "has served as Mayor since
-- January 2021" -- his own page. Kocher and Coachman also expire January 2029
-- and were RE-ELECTED in November 2024, per the city's own 2025-01-06 press
-- release. Deriving a start from an expiry would have been wrong for three of
-- these six people. The same reading error was wrong for 5 of 17 in the NC wave.
--
-- TWO OF THE SIX WERE APPOINTED, NOT ELECTED:
--   Ward 2  Marianne Barnebey  appointed 2020-06-24, after four elected terms
--                              that ended when she resigned in 2012 -- so the
--                              GAP means continuous occupancy starts in 2020.
--   Ward 3  Kemp Schuessler    appointed 2025-07-23, filling the vacancy left
--                              when Councilman Josh Cramer became Chief of
--                              Police.
--
-- THREE HAVE start_precision 'unknown' AND NO term_start: Kocher, Moore and
-- Coachman. No publisher gives a start date, and the Supervisor of Elections'
-- results archive exposes only 2004-2007 outside its JavaScript file manager.
-- An open-ended term at 'unknown' precision is the honest record; a guessed
-- date is a false statement about history that no end_precision can soften.
-- ROSTERS.md carries the follow-up.

BEGIN;
${occupancySql(city, 'brad_seed', 'bradenton people', ALL_OWNED_IDS)}
-- --- Post-verify gate ------------------------------------------------------
DO $$
DECLARE v_gov uuid; v_pol int; v_seated int; v_appt int; v_unknown int; v_n int; v_d text;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '${PLACE_GEO_ID}' AND type = 'City';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'bradenton people: the government row is missing -- apply the structure half first'; END IF;

  -- ⚠ COUNT THIS MIGRATION'S OWN IDS, NOT THE WHOLE BAND. Counting the band
  -- made this migration non-idempotent: once CC_0010 adds its eleven, a re-run
  -- of this one saw 17 and refused. Measured 2026-08-28.
  SELECT count(*) INTO v_pol FROM essentials.politicians
   WHERE external_id IN (${cityIds});
  IF v_pol <> ${counts.cityPeople} THEN RAISE EXCEPTION 'bradenton people: expected ${counts.cityPeople} of this wave''s politicians, got %', v_pol; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs
  -- from offices, so a vacancy is a NULL politician_id, never an absent row,
  -- and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov;
  IF v_seated <> ${counts.cityPeople} THEN RAISE EXCEPTION 'bradenton people: expected ${counts.cityPeople} seated officials, found %', v_seated; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.is_vacant = true;
  IF v_n <> 0 THEN RAISE EXCEPTION 'bradenton people: % Bradenton office(s) flagged vacant, expected 0', v_n; END IF;

  -- One seated member per ward, counted PER WARD.
  FOR v_d IN SELECT '${CITY_WARD_PREFIX}' || g FROM generate_series(1,5) g LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id = v_d AND d.mtfcc = '${CITY_MTFCC}' AND d.district_type = 'LOCAL';
    IF v_n <> 1 THEN RAISE EXCEPTION 'bradenton people: ward % has % seated member(s), expected 1', v_d, v_n; END IF;
  END LOOP;

  -- 🔴 THE TWO APPOINTMENTS MUST HAVE SURVIVED. A generator that quietly
  -- defaulted how_started to 'elected' passes every count above.
  SELECT count(*) INTO v_appt
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.how_started = 'appointed';
  IF v_appt <> 2 THEN RAISE EXCEPTION 'bradenton people: expected 2 appointed terms (Wards 2 and 3), got %', v_appt; END IF;

  -- 🔴 AND THE THREE HONEST BLANKS MUST STILL BE BLANK. If a later pass
  -- invents dates for them, this gate is where that shows up.
  SELECT count(*) INTO v_unknown
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.start_precision = 'unknown' AND t.term_start IS NULL;
  IF v_unknown <> 3 THEN RAISE EXCEPTION 'bradenton people: expected 3 unknown-precision open-ended terms, got %', v_unknown; END IF;

  -- No office in this government may lack a term row while unflagged: that is
  -- the one failure mode CI cannot catch.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_terms t ON t.office_id = o.id
   WHERE c.government_id = v_gov AND t.id IS NULL AND o.is_vacant = false;
  IF v_n <> 0 THEN RAISE EXCEPTION 'bradenton people: % office(s) have no term row and no vacancy flag', v_n; END IF;

  RAISE NOTICE 'bradenton people OK: ${counts.cityPeople} politicians, ${counts.cityPeople} seated, 2 appointed, 3 unknown-precision';
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
    'CC_0010_manatee_county.sql',
    null,
    `Creates Manatee County whole -- offices AND people in ONE migration, per spec section 3:\n--   * 5 new COUNTY districts (mtfcc ${COUNTY_MTFCC}); the countywide district ALREADY EXISTS\n--   * 1 government, 2 chambers\n--   * ${counts.countyOffices} offices -- 7 commissioners + 5 constitutional officers\n--   * ${counts.countyPeople} politicians and ${counts.countyPeople} terms; District 1 is VACANT`,
  ));

  parts.push(`
-- ---------------------------------------------------------------------------
-- 🔴 MANATEE IS A NON-CHARTER COUNTY, so Fla. Const. art. VIII sec. 1(d)
-- applies unmodified and the five constitutional officers are Sheriff, Tax
-- Collector, Property Appraiser, Supervisor of Elections and Clerk of the
-- Circuit Court. The county's own page agrees: "the Board of County
-- Commissioners, together with Manatee County's FIVE constitutional officers,
-- comprise Manatee County Government." A charter was still only being explored
-- as of January 2026.
-- ⚠ NOTHING here may be inherited by Leon, Palm Beach or Miami-Dade. Charter
-- counties vary, and those three are confirmed separately in FL-4, FL-5, FL-6.
--
-- ---------------------------------------------------------------------------
-- 🔴 SEVEN COMMISSIONERS, FIVE POLYGONS. Districts 1-5 are single-member.
-- Districts 6 and 7 are elected COUNTYWIDE and hang off the PRE-EXISTING COUNTY
-- district for TIGER county ${COUNTY_GEO_ID}, together with all five constitutional
-- officers -- 7 offices on that one district. The at-large seats are numbered 6
-- and 7 by the Supervisor of Elections; the county's own board page labels both
-- rows merely "At Large District", with no number.
--
-- ---------------------------------------------------------------------------
-- 🔴 DISTRICT 1 IS VACANT, AND FLAGGING IT IS LOAD-BEARING TWICE OVER.
-- Commissioner Carol Ann Felts DIED on ${D1_VACANT_SINCE} -- the county's own
-- announcement of that date. Governor DeSantis declared the vacancy by Executive
-- Order 26-76 and then left the seat empty, which is why it reaches the 2026
-- ballot as a TWO-YEAR unexpired term. Note that a county commission vacancy is
-- filled by GUBERNATORIAL APPOINTMENT (Fla. Const. art. IV sec. 1(f)), unlike a
-- LEGISLATIVE vacancy, which Florida fills by special election -- so FL-2's five
-- vacancies and this one are not the same mechanism.
--
--   1. check-address-reachability.mjs classifies DEAD_GEOGRAPHY as
--      reachable AND offices > 0 AND active_holders = 0 AND vacant_offices = 0.
--      The baseline holds NO fl| bucket in any check, so one unflagged empty
--      office creates a NEW fl|COUNTY bucket and fails CI.
--   2. essentials.offices_missing_terms counts only UNFLAGGED rows as drift.
--
-- ⚠ Felts' own closed term is deliberately NOT written, though every date for it
-- is known. FL-2 wrote no predecessor terms for any of its five legislative
-- vacancies, and doing it for one county seat here would leave Florida
-- internally inconsistent. ROSTERS.md records the evidence so all six can be
-- done together, deliberately.

BEGIN;

-- --- 0. Pre-flight ----------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = '${COUNTY_MTFCC}';
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'manatee county: expected 5 ${COUNTY_MTFCC} boundaries, found % -- run scripts/load-manatee-commission-boundaries.ts first', v_n;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '${COUNTY_GEO_ID}' AND mtfcc = 'G4020'
  ) THEN
    RAISE EXCEPTION 'manatee county: TIGER county ${COUNTY_GEO_ID}/G4020 is missing';
  END IF;

  -- The countywide district must ALREADY exist. This migration must not create a
  -- second one: 7 of its 12 offices hang off it.
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = '${COUNTY_GEO_ID}' AND mtfcc = 'G4020' AND district_type = 'COUNTY' AND lower(state) = 'fl';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'manatee county: expected exactly 1 pre-existing COUNTY district for ${COUNTY_GEO_ID}, found %', v_n;
  END IF;
END $$;

-- --- 1. The five single-member commission districts ------------------------
`);

  for (const s of commSeats) {
    parts.push(`INSERT INTO essentials.districts (district_type, label, state, geo_id, mtfcc, num_officials)
SELECT 'COUNTY', 'Manatee County Commissioner District ${s.n}', 'fl', '${COUNTY_DIST_PREFIX}${s.n}', '${COUNTY_MTFCC}', 1
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
SELECT g.id, 'Board of County Commissioners', 'Manatee County Board of County Commissioners', 7, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${COUNTY_GEO_ID}' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
     WHERE c.government_id = g.id AND c.name = 'Board of County Commissioners'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Elected Officials', 'Manatee County Elected Officials', 5, 'full'
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
-- --- 5. Flag District 1 vacant --------------------------------------------
-- Guarded UPDATE, so a re-run is a no-op and an appointee seated later is not
-- silently un-seated.
UPDATE essentials.offices o
   SET is_vacant = true,
       vacant_since = ${q(D1_VACANT_SINCE)}::timestamptz
  FROM essentials.districts d, essentials.chambers c
 WHERE d.id = o.district_id AND c.id = o.chamber_id
   AND d.geo_id = '${COUNTY_DIST_PREFIX}1' AND d.mtfcc = '${COUNTY_MTFCC}' AND d.district_type = 'COUNTY'
   AND o.title = 'Commissioner, District 1'
   AND o.is_vacant = false
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);

-- --- 6. Structure post-verify gate ----------------------------------------
DO $$
DECLARE v_gov uuid; v_n int; v_d text;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE mtfcc = '${COUNTY_MTFCC}' AND district_type = 'COUNTY' AND lower(state) = 'fl';
  IF v_n <> 5 THEN RAISE EXCEPTION 'manatee county: expected 5 ${COUNTY_MTFCC} districts, got %', v_n; END IF;

  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '${COUNTY_GEO_ID}' AND type = 'County';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'manatee county: the government row is missing'; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers WHERE government_id = v_gov;
  IF v_n <> 2 THEN RAISE EXCEPTION 'manatee county: expected 2 chambers, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_n <> ${counts.countyOffices} THEN RAISE EXCEPTION 'manatee county: expected ${counts.countyOffices} offices, got %', v_n; END IF;

  -- PER CHAMBER, not just in total.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Board of County Commissioners';
  IF v_n <> 7 THEN RAISE EXCEPTION 'manatee county: expected 7 commissioner offices, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Elected Officials';
  IF v_n <> 5 THEN RAISE EXCEPTION 'manatee county: expected 5 constitutional officer offices, got %', v_n; END IF;

  -- PER DISTRICT: one commissioner per single-member district...
  FOR v_d IN SELECT '${COUNTY_DIST_PREFIX}' || g FROM generate_series(1,5) g LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = v_d AND d.mtfcc = '${COUNTY_MTFCC}' AND d.district_type = 'COUNTY';
    IF v_n <> 1 THEN RAISE EXCEPTION 'manatee county: commission district % carries % offices, expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- ...and exactly 7 on the countywide district: 2 at-large + 5 officers.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND d.geo_id = '${COUNTY_GEO_ID}'
     AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY';
  IF v_n <> 7 THEN RAISE EXCEPTION 'manatee county: expected 7 offices on the countywide district, got %', v_n; END IF;

  -- 🔴 No office may have landed on a Manatee County in ANOTHER state, and none
  -- may sit on a district with no boundary.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov AND lower(d.state) <> 'fl';
  IF v_n <> 0 THEN RAISE EXCEPTION 'manatee county: % office(s) landed outside Florida', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_n <> 0 THEN RAISE EXCEPTION 'manatee county: % office(s) sit on a district with no matching boundary', v_n; END IF;

  RAISE NOTICE 'manatee county structure OK: 5 new districts, 1 government, 2 chambers, ${counts.countyOffices} offices';
END $$;
${occupancySql(county, 'man_seed', 'manatee county', ALL_OWNED_IDS)}
-- --- 7. Occupancy post-verify gate ----------------------------------------
DO $$
DECLARE v_gov uuid; v_pol int; v_seated int; v_vac int; v_appt int; v_n int; v_d text;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '${COUNTY_GEO_ID}' AND type = 'County';

  -- ⚠ COUNT THIS MIGRATION'S OWN IDS, NOT THE WHOLE BAND. The band version also
  -- gave this migration a hidden ORDERING DEPENDENCY on CC_0009: it asserted the
  -- city's six were already present, so applying the county first would have
  -- failed for no real reason.
  SELECT count(*) INTO v_pol FROM essentials.politicians
   WHERE external_id IN (${countyIds});
  IF v_pol <> ${counts.countyPeople} THEN
    RAISE EXCEPTION 'manatee county: expected ${counts.countyPeople} of this wave''s politicians, got %', v_pol;
  END IF;

  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov;
  IF v_seated <> ${counts.countyPeople} THEN RAISE EXCEPTION 'manatee county: expected ${counts.countyPeople} seated officials, found %', v_seated; END IF;

  -- 🔴 EXACTLY ONE VACANCY, AND IT IS DISTRICT 1.
  SELECT count(*) INTO v_vac FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.is_vacant = true;
  IF v_vac <> ${counts.vacancies} THEN RAISE EXCEPTION 'manatee county: expected ${counts.vacancies} flagged vacancy, got %', v_vac; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '${COUNTY_DIST_PREFIX}1' AND d.mtfcc = '${COUNTY_MTFCC}'
     AND d.district_type = 'COUNTY'
     AND o.is_vacant = true AND o.vacant_since = ${q(D1_VACANT_SINCE)}::timestamptz;
  IF v_n <> 1 THEN RAISE EXCEPTION 'manatee county: District 1 is not flagged vacant since ${D1_VACANT_SINCE}'; END IF;

  -- One seated commissioner per single-member district, EXCEPT District 1.
  FOR v_d IN SELECT '${COUNTY_DIST_PREFIX}' || g FROM generate_series(2,5) g LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id = v_d AND d.mtfcc = '${COUNTY_MTFCC}' AND d.district_type = 'COUNTY';
    IF v_n <> 1 THEN RAISE EXCEPTION 'manatee county: commission district % has % seated member(s), expected 1', v_d, v_n; END IF;
  END LOOP;

  SELECT count(och.politician_id) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.geo_id = '${COUNTY_DIST_PREFIX}1' AND d.mtfcc = '${COUNTY_MTFCC}'
     AND d.district_type = 'COUNTY';
  IF v_n <> 0 THEN RAISE EXCEPTION 'manatee county: District 1 has % seated member(s), expected 0', v_n; END IF;

  -- 🔴 THE CLERK'S APPOINTMENT MUST HAVE SURVIVED. Colonneso was sworn in by
  -- appointment in September 2015 after her predecessor died in office; a
  -- generator that defaulted how_started to 'elected' passes every count above.
  SELECT count(*) INTO v_appt
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.how_started = 'appointed';
  IF v_appt <> 1 THEN RAISE EXCEPTION 'manatee county: expected 1 appointed term (the Clerk), got %', v_appt; END IF;

  -- No office with neither a term row nor a vacancy flag.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_terms t ON t.office_id = o.id
   WHERE c.government_id = v_gov AND t.id IS NULL AND o.is_vacant = false;
  IF v_n <> 0 THEN RAISE EXCEPTION 'manatee county: % office(s) have no term row and no vacancy flag', v_n; END IF;

  RAISE NOTICE 'manatee county OK: ${counts.countyOffices} offices, ${counts.countyPeople} seated, ${counts.vacancies} vacant';
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
    ['CC_0008_bradenton_structure.sql', renderCityStructure(city, counts)],
    ['CC_0009_bradenton_people.sql', renderCityPeople(city, counts)],
    ['CC_0010_manatee_county.sql', renderCounty(county, counts)],
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
