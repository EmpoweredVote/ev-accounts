/**
 * gen-miami-dade-migrations.mjs
 *
 * Turns data/seed-miami-dade-2026/ROSTERS.md into THREE migrations:
 *
 *   CC_0015_miami_structure.sql      city districts + government + chambers + offices
 *   CC_0016_miami_people.sql         city politicians + occupancy
 *   CC_0017_miami_dade_county.sql    county districts + government + chambers +
 *                                   offices + politicians + occupancy, in ONE file
 *
 * Reads NOTHING from the database. Everything it asserts comes from the roster
 * file, and the migrations it emits re-assert those numbers against prod.
 *
 * Wave FL-6 of the Knight Foundation cities program.
 * Plan: docs/superpowers/plans/2026-08-29-knight-fl-wave-6-miami-miami-dade.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THREE MIGRATIONS, BECAUSE THERE IS A CITY HALF AGAIN.
 *
 * FL-5 (Palm Beach) had no municipal wave and DELETED renderCityStructure() and
 * renderCityPeople(). This generator takes FL-5's fixes -- the parameterised
 * HEADER, the widened suffix regex, the fourth-shape band guard -- and restores
 * the city half from FL-4's generator.
 *
 * ⚠ FL-4 IS ENTIRELY AT-LARGE and has NO city district layer, so there was no
 * 'ward' branch to bring back (that is FL-3's, X0036). Miami's five commission
 * districts are a NEW anchor, 'commdist_city' on X0041.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE SAME TITLE EXISTS IN BOTH GOVERNMENTS. 'Office of the Mayor' is a
 * chamber in the city AND the county; 'Mayor' and 'Commissioner, District 1'
 * through 'District 5' are office titles in both. chambers.slug is generated from
 * name_formal, which differs ('City of Miami Office of the Mayor' vs 'Miami-Dade
 * County Office of the Mayor'), so the rows cannot collide -- but ANY lookup on
 * c.name alone matches two chambers and the office insert fans out. Every chamber
 * lookup and every gate below is scoped by government.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 ONE PERSON IS REUSED, NOT INSERTED.
 *
 * Oliver Gilbert already exists as external_id -1212402, seeded by the FL 2026
 * US House wave as a candidate for FL-24 with no office. He is the same person as
 * the Miami-Dade District 1 commissioner -- established from biography, not from
 * a name match. This wave gives him an office_terms row and NO new politician row.
 *
 * So the county emits 19 terms from 18 new politician rows. The band guard is
 * SPLIT in two because of him -- see occupancySql(): an ABSENCE assertion over
 * this wave's new sub-range, and a POSITIVE assertion that the reused row exists
 * and is the expected person.
 *
 * ⚠ His alternate_names are NOT written. The published county form is
 * 'Oliver G. Gilbert, III' and ROSTERS.md records it, but adding it would mean
 * UPDATEing a row another wave owns. Out of scope, deliberately.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 splitName() CANNOT HANDLE A TWO-WORD SURNAME AND THIS WAVE HAS TWO.
 *
 * 'Danielle Cohen Higgins' yields last = Higgins, middle = Cohen, and because
 * "Cohen" is not a single initial the middleInitial is dropped -- "Cohen" simply
 * disappears. 'Daniella Levine Cava' loses "Levine" the same way. SURNAME_OVERRIDES
 * fixes those two by name rather than widening the heuristic, which would break
 * 'Juan Carlos' next.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 FOUR APPOINTMENTS, NOT THE TWO THE PLAN PREDICTED.
 *
 * The SOE marks only D5 (Lopez) and D6 (Milian Orbis) as 'Appointed', because
 * only they are still serving under one. But term_start is the start of
 * CONTINUOUS OCCUPANCY, so two more spans began with an appointment and are
 * invisible in the SOE: D8 Cohen Higgins (2020-12-07, Commission vote) and D11
 * Gonzalez (2022-11-23, appointed by GOV. DeSANTIS after Commissioner Martinez
 * was suspended). Both have since won ordinary four-year terms.
 * The gates assert 4, by title.
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROSTER = join(HERE, '..', 'data', 'seed-miami-dade-2026', 'ROSTERS.md');
const MIGRATIONS = join(HERE, '..', 'migrations');

// ── Identity of the jurisdiction ────────────────────────────────────────────

const WAVE = 'FL-6';
const PLAN = 'docs/superpowers/plans/2026-08-29-knight-fl-wave-6-miami-miami-dade.md';
const ROSTER_REL = 'data/seed-miami-dade-2026/ROSTERS.md';
const GENERATOR = 'scripts/gen-miami-dade-migrations.mjs';

/** ⚠ _wip_ until Task 5 renames them. Take the migration NUMBER last. */
const CITY_STRUCTURE_FILE = 'CC_0015_miami_structure.sql';
const CITY_PEOPLE_FILE = 'CC_0016_miami_people.sql';
const COUNTY_FILE = 'CC_0017_miami_dade_county.sql';

const CITY_MTFCC = 'X0041';
const COUNTY_MTFCC = 'X0040';
const PLACE_GEO_ID = '1245000'; // TIGER place, Miami city (G4110). Loaded by FL-1.
const COUNTY_GEO_ID = '12086'; // TIGER county, Miami-Dade (G4020). Pre-existing.
const CITY_DIST_PREFIX = 'miami-fl-commission-district-';
const COUNTY_DIST_PREFIX = 'miami-dade-fl-commissioner-district-';
const CITY_GOV = 'City of Miami, Florida, US';
const COUNTY_GOV = 'Miami-Dade County, Florida, US';

const N_CITY_DISTRICTS = 5;
const N_COUNTY_DISTRICTS = 13;
const N_OFFICERS = 5;

/** The shared Florida LOCAL band. FL-3/4/5 own -1240075..-1240001. */
const BAND_LO = -1249999;
const BAND_HI = -1240000;

/** This wave's own sub-range of NEW ids. Excludes the reuse, which is outside it. */
const OWNED_LO = -1240109;
const OWNED_HI = -1240081;

/**
 * 🔴 THE REUSE. Oliver Gilbert III already exists as a 2026 US House candidate
 * for FL-24 (race row: U.S. Representative / Congressional District 24 / geo_id
 * 1224 / G5200 / is_incumbent = false). Same person as the District 1
 * commissioner; verified from biography, not a name match. He gets an
 * office_terms row and NO new politician row.
 */
const REUSED_IDS = {
  '-1212402': { slug: 'mdc-commissioner-1', expectFullName: 'Oliver Gilbert' },
};

/**
 * Slug -> (title, chamber, which district it hangs off).
 *
 * `on` is 'citywide' (TIGER place, G4110), 'commdist_city' (X0041),
 * 'countywide' (the PRE-EXISTING TIGER county district, G4020) or
 * 'commdist' (X0040).
 */
const CITY_SEATS = {
  'mia-mayor': { title: 'Mayor', chamber: 'Office of the Mayor', on: 'citywide' },
  'mia-commissioner-1': { title: 'Commissioner, District 1', chamber: 'City Commission', on: 'commdist_city', n: 1 },
  'mia-commissioner-2': { title: 'Commissioner, District 2', chamber: 'City Commission', on: 'commdist_city', n: 2 },
  'mia-commissioner-3': { title: 'Commissioner, District 3', chamber: 'City Commission', on: 'commdist_city', n: 3 },
  'mia-commissioner-4': { title: 'Commissioner, District 4', chamber: 'City Commission', on: 'commdist_city', n: 4 },
  'mia-commissioner-5': { title: 'Commissioner, District 5', chamber: 'City Commission', on: 'commdist_city', n: 5 },
};

const COUNTY_SEATS = {
  'mdc-mayor': { title: 'Mayor', chamber: 'Office of the Mayor', on: 'countywide' },
  'mdc-commissioner-1': { title: 'Commissioner, District 1', chamber: 'Board of County Commissioners', on: 'commdist', n: 1 },
  'mdc-commissioner-2': { title: 'Commissioner, District 2', chamber: 'Board of County Commissioners', on: 'commdist', n: 2 },
  'mdc-commissioner-3': { title: 'Commissioner, District 3', chamber: 'Board of County Commissioners', on: 'commdist', n: 3 },
  'mdc-commissioner-4': { title: 'Commissioner, District 4', chamber: 'Board of County Commissioners', on: 'commdist', n: 4 },
  'mdc-commissioner-5': { title: 'Commissioner, District 5', chamber: 'Board of County Commissioners', on: 'commdist', n: 5 },
  'mdc-commissioner-6': { title: 'Commissioner, District 6', chamber: 'Board of County Commissioners', on: 'commdist', n: 6 },
  'mdc-commissioner-7': { title: 'Commissioner, District 7', chamber: 'Board of County Commissioners', on: 'commdist', n: 7 },
  'mdc-commissioner-8': { title: 'Commissioner, District 8', chamber: 'Board of County Commissioners', on: 'commdist', n: 8 },
  'mdc-commissioner-9': { title: 'Commissioner, District 9', chamber: 'Board of County Commissioners', on: 'commdist', n: 9 },
  'mdc-commissioner-10': { title: 'Commissioner, District 10', chamber: 'Board of County Commissioners', on: 'commdist', n: 10 },
  'mdc-commissioner-11': { title: 'Commissioner, District 11', chamber: 'Board of County Commissioners', on: 'commdist', n: 11 },
  'mdc-commissioner-12': { title: 'Commissioner, District 12', chamber: 'Board of County Commissioners', on: 'commdist', n: 12 },
  'mdc-commissioner-13': { title: 'Commissioner, District 13', chamber: 'Board of County Commissioners', on: 'commdist', n: 13 },

  // 🔴 FIVE OFFICERS, the Amendment 10 offices. No Superintendent of Schools
  //    (the School Board appoints one), no State Attorney and no Public Defender
  //    -- those are officers of the 11th JUDICIAL CIRCUIT, the same exclusion
  //    FL-5 made for Palm Beach's 15th.
  // ⚠ 'Clerk of the Court and Comptroller' -- the form HIS OWN SITE uses. The SOE
  //    PDF prints 'Clerk of the Circuit Court and Comptroller' and Palm Beach's
  //    office brands itself 'Clerk of the Circuit Court & Comptroller'. Three
  //    counties, three titles; never inherit one.
  'mdc-clerk-of-court': { title: 'Clerk of the Court and Comptroller', chamber: 'Elected Officials', on: 'countywide' },
  'mdc-sheriff': { title: 'Sheriff', chamber: 'Elected Officials', on: 'countywide' },
  'mdc-property-appraiser': { title: 'Property Appraiser', chamber: 'Elected Officials', on: 'countywide' },
  'mdc-tax-collector': { title: 'Tax Collector', chamber: 'Elected Officials', on: 'countywide' },
  'mdc-supervisor-of-elections': { title: 'Supervisor of Elections', chamber: 'Elected Officials', on: 'countywide' },
};

/** 🔴 Titles that must match ZERO offices in BOTH governments. */
const FORBIDDEN_TITLES = ['Superintendent of Schools', 'State Attorney', 'Public Defender'];

/**
 * 🔴 TWO-WORD SURNAMES. splitName() takes the LAST token; these need two.
 * An override is honest; a cleverer heuristic would break 'Juan Carlos' next.
 */
const SURNAME_OVERRIDES = {
  'mdc-commissioner-8': { firstName: 'Danielle', lastName: 'Cohen Higgins' },
  'mdc-mayor': { firstName: 'Daniella', lastName: 'Levine Cava' },
};

/**
 * alternate_names, keyed by slug. full_name keeps the publisher's form; the
 * alternate carries what a later dedupe or headshot search is likely to hit.
 *
 * ⚠ NOTHING INVENTED, and mdc-commissioner-1 is DELIBERATELY ABSENT: Gilbert's
 * row belongs to another wave and this migration does not UPDATE it.
 */
const ALIASES = {
  'mia-commissioner-1': ['Miguel Gabela'],
  'mia-commissioner-4': ['Ralph Rosado', 'Rafael Rosado'],
  'mdc-mayor': ['Daniella Cava'],
  'mdc-commissioner-8': ['Danielle Higgins'],
  'mdc-commissioner-12': ['Juan Carlos Bermudez', 'JC Bermudez'],
  'mdc-commissioner-13': ['Rene Garcia'],
  'mdc-sheriff': ['Rosie Cordero-Stutz', 'Rosanna Cordero-Stutz'],
};

/** offices.description, keyed by slug. This wave needs none. */
const DESCRIPTIONS = {};

/** Filled by main(); the NEW ids only, never the reuse. */
let ALL_NEW_IDS = [];

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
    const [seat, slug, name, externalIdRaw, termStart, precision, howStarted, source] = cells;
    // ⚠ ROSTERS.md bolds the reused id (**-1212402**) to make it visible to a
    //   human reader. Strip markdown emphasis before it becomes a number.
    const externalId = externalIdRaw.replace(/\*/g, '').trim();
    rows.push({ seat, slug, name, externalId, termStart, precision, howStarted, source });
  }
  return rows;
}

/**
 * Split a display name into first/last. Strips a quoted nickname and a trailing
 * suffix first.
 *
 * ⚠ FL-5's WIDENED SUFFIX REGEX, which does NOT require a comma. This wave needs
 * both forms: the county publishes 'Oliver G. Gilbert, III' (comma) and the SOE
 * PDF prints 'Steve Gallon, III' the same way, while FL-5's 'Bobby Powell Jr.'
 * has none. FL-3's and FL-4's comma-required regex puts 'III' in last_name.
 *
 * 🔴 IT STILL CANNOT DO A TWO-WORD SURNAME. See SURNAME_OVERRIDES.
 */
function splitName(full) {
  const suffixMatch = full.match(/,?\s+(Jr\.?|Sr\.?|II|III|IV)\s*$/i);
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
  const city = parseTable(md, 'City of Miami');
  const county = parseTable(md, 'Miami-Dade County');

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
    if (/\((R|D|DEM|REP|NPA|IND|LPF|GRE|WRI|I)\)|republican|democrat|\s-\s(REP|DEM)\b/i.test(r.name)) {
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
    const reuse = REUSED_IDS[r.externalId];
    return {
      ...r, ...def, ...splitName(r.name), ...(SURNAME_OVERRIDES[r.slug] ?? {}),
      isVacant, isReused: Boolean(reuse),
      aliases: ALIASES[r.slug] ?? [], description: DESCRIPTIONS[r.slug] ?? '',
    };
  }).filter(Boolean);

  const cityRows = decorate(city, CITY_SEATS, 'city');
  const countyRows = decorate(county, COUNTY_SEATS, 'county');
  const allRows = [...cityRows, ...countyRows];

  const ids = allRows.map((r) => r.externalId).filter(Boolean);
  const dupIds = ids.filter((x, i) => ids.indexOf(x) !== i);
  if (dupIds.length) problems.push(`duplicate external_id(s): ${[...new Set(dupIds)].join(', ')}`);

  // 🔴 THE REUSE IS THE ONLY LEGITIMATE ESCAPE FROM THE SUB-RANGE, and it must be
  //    the DECLARED one on the DECLARED slug. An id outside the range that is not
  //    a declared reuse is a collision with another wave.
  for (const r of allRows) {
    if (!r.externalId) continue;
    const n = Number(r.externalId);
    const reuse = REUSED_IDS[r.externalId];
    if (reuse) {
      if (reuse.slug !== r.slug) {
        problems.push(`external_id ${r.externalId} is a declared reuse for "${reuse.slug}", but appears on "${r.slug}"`);
      }
      continue;
    }
    if (!(n >= BAND_LO && n <= BAND_HI)) {
      problems.push(`external_id ${r.externalId} is outside the Florida LOCAL band ${BAND_LO}..${BAND_HI} and is not a declared reuse`);
    } else if (!(n >= OWNED_LO && n <= OWNED_HI)) {
      problems.push(`external_id ${r.externalId} is outside THIS WAVE's sub-range ${OWNED_LO}..${OWNED_HI} and is not a declared reuse — FL-3/4/5 own -1240075..-1240001`);
    }
  }
  for (const [id, def] of Object.entries(REUSED_IDS)) {
    if (!allRows.some((r) => r.externalId === id && r.slug === def.slug)) {
      problems.push(`declared reuse ${id} (${def.slug}) does not appear in the roster`);
    }
  }

  // 🔴 SHAPE ASSERTIONS. A correct TOTAL is reachable with a commissioner mapped
  //    countywide, which would put that one person on every address in the county.
  const cityComm = cityRows.filter((r) => r.chamber === 'City Commission');
  const cityMayor = cityRows.filter((r) => r.chamber === 'Office of the Mayor');
  const comm = countyRows.filter((r) => r.chamber === 'Board of County Commissioners');
  const countyMayor = countyRows.filter((r) => r.chamber === 'Office of the Mayor');
  const officers = countyRows.filter((r) => r.chamber === 'Elected Officials');
  if (cityComm.length !== N_CITY_DISTRICTS) problems.push(`expected ${N_CITY_DISTRICTS} city commission seats, got ${cityComm.length}`);
  if (cityMayor.length !== 1) problems.push(`expected exactly 1 city Mayor, got ${cityMayor.length}`);
  if (comm.length !== N_COUNTY_DISTRICTS) problems.push(`expected ${N_COUNTY_DISTRICTS} county commission seats, got ${comm.length}`);
  if (countyMayor.length !== 1) problems.push(`expected exactly 1 county Mayor, got ${countyMayor.length}`);
  if (officers.length !== N_OFFICERS) problems.push(`expected ${N_OFFICERS} constitutional officers, got ${officers.length}`);
  if (cityComm.some((r) => r.on !== 'commdist_city')) problems.push(`every city commission seat must be 'commdist_city': ${cityComm.filter((r) => r.on !== 'commdist_city').map((r) => r.slug).join(', ')}`);
  if (comm.some((r) => r.on !== 'commdist')) problems.push(`Miami-Dade has NO at-large commissioner — every commission seat must be 'commdist': ${comm.filter((r) => r.on !== 'commdist').map((r) => r.slug).join(', ')}`);
  if (officers.some((r) => r.on !== 'countywide')) problems.push(`every constitutional officer must be 'countywide': ${officers.filter((r) => r.on !== 'countywide').map((r) => r.slug).join(', ')}`);
  for (const t of FORBIDDEN_TITLES) {
    if (allRows.some((r) => r.title === t)) problems.push(`"${t}" must not be seated in this wave — see the file header`);
  }

  // 🔴 The two-word surnames must have survived the override.
  for (const [slug, want] of Object.entries(SURNAME_OVERRIDES)) {
    const row = allRows.find((r) => r.slug === slug);
    if (row && row.lastName !== want.lastName) {
      problems.push(`${slug}: last_name is "${row.lastName}", expected the override "${want.lastName}"`);
    }
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
    case 'citywide': return { geoId: PLACE_GEO_ID, mtfcc: 'G4110', type: 'LOCAL' };
    case 'commdist_city': return { geoId: `${CITY_DIST_PREFIX}${seat.n}`, mtfcc: CITY_MTFCC, type: 'LOCAL' };
    case 'countywide': return { geoId: COUNTY_GEO_ID, mtfcc: 'G4020', type: 'COUNTY' };
    case 'commdist': return { geoId: `${COUNTY_DIST_PREFIX}${seat.n}`, mtfcc: COUNTY_MTFCC, type: 'COUNTY' };
    default: throw new Error(`unknown district anchor "${seat.on}"`);
  }
}

/**
 * 🔴 Every district lookup pairs geo_id WITH mtfcc AND district_type. 12086 is
 * Miami-Dade County (G4020) AND a New York ZIP code in geofence_boundaries; the
 * three preceding waves each hit the same class (12081/HD-81, 12073/HD-73,
 * 12099/HD-99). An unpaired join returns extra district rows and nothing errors.
 */
function districtLookupSql(seat, alias = 'dd') {
  const r = districtRef(seat);
  return `SELECT ${alias}.id FROM essentials.districts ${alias}
   WHERE ${alias}.geo_id = ${q(r.geoId)} AND ${alias}.mtfcc = ${q(r.mtfcc)}
     AND ${alias}.district_type = ${q(r.type)} AND lower(${alias}.state) = 'fl'`;
}

/**
 * ⚠ The chamber is resolved through its GOVERNMENT, never by name alone.
 * 'Office of the Mayor' is a chamber in BOTH governments in this wave.
 */
function officeInsertSql(seat, govGeoId, govType, state, city) {
  const hasDesc = Boolean(seat.description);
  const extra = hasDesc ? ', description' : '';
  const extraVal = hasDesc ? `, ${q(seat.description)}` : '';
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

/** ⚠ PARAMETERISED. FL-4 shipped three migrations to prod citing FL-3's plan. */
const HEADER = (file, companion, what) => `-- ${file}
-- Knight Foundation cities program, wave ${WAVE}${companion ? `. Companion: ${companion}.` : '.'}
--
-- ${what}
--
-- Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
-- Plan:   ${PLAN}
-- Slice:  .planning/knight-foundation/fl.md
-- Roster: ${ROSTER_REL}
-- Generated by: ${GENERATOR}
--
-- ---------------------------------------------------------------------------
-- 🔴 EVERY DISTRICT LOOKUP PAIRS geo_id WITH mtfcc AND district_type, and every
-- CHAMBER lookup is scoped by its GOVERNMENT. This wave seats TWO governments
-- over one anchor: 'Office of the Mayor' is a chamber in both, and 'Mayor' and
-- 'Commissioner, District 1'..'District 5' are office titles in both. A lookup
-- on name alone matches two rows and the insert fans out.
--
-- ---------------------------------------------------------------------------
-- No party affiliation is recorded. Party lives on races.primary_party.
--
-- No term_end is written. A future term_end makes a seat silently self-vacate,
-- and office_terms has no end_precision, so a published expiry cannot become a
-- term_end without inventing a day. The SOE's "Current Term Ends" column is
-- deliberately NOT written.
`;

// ── Occupancy ───────────────────────────────────────────────────────────────

function seedRowsSql(rows) {
  return rows.filter((r) => !r.isVacant).map((r) => {
    const d = districtRef(r);
    return `  (${q(d.geoId)}, ${q(d.mtfcc)}, ${q(d.type)}, ${q(r.title)}, ${r.externalId}, ` +
      `${q(r.name)}, ${qn(r.firstName)}, ${qn(r.lastName)}, ${qn(r.middleInitial)}, ${qn(r.nameSuffix)}, ` +
      `${r.aliases.length ? `ARRAY[${r.aliases.map(q).join(', ')}]::text[]` : `'{}'::text[]`}, ` +
      `${qn(r.termStart)}::date, ${q(r.precision)}, ${q(r.howStarted)}, ${q(r.source)})`;
  }).join(',\n');
}

function occupancySql(rows, tmp, label, newIds) {
  const seated = rows.filter((r) => !r.isVacant);
  const reusedHere = seated.filter((r) => r.isReused);
  const newList = newIds.join(', ');
  const reusedList = reusedHere.map((r) => r.externalId).join(', ');
  const nOnDistricts = seated.filter((r) => r.on === 'commdist' || r.on === 'commdist_city').length;
  const nOnWide = seated.filter((r) => r.on === 'countywide' || r.on === 'citywide').length;

  return `
-- --- Politician identity band ----------------------------------------------
-- 🔴 (a) ABSENCE, over THIS WAVE'S NEW SUB-RANGE ONLY.
--
-- FOUR versions of this guard were wrong before FL-5's; this is the FIFTH shape,
-- and the reuse is why. FL-5 asserted "nothing inside [min..max] of this wave's
-- ids is owned by anything else". Adding -1212402 to that list stretches max from
-- ${OWNED_HI} to -1212402 and sweeps in the entire congressional band plus every
-- earlier Florida local wave -- the guard would refuse on legitimate rows.
--
-- So the range is the CONSTANT sub-range of NEW ids, and the reuse is excluded
-- from it entirely and asserted positively in (b).
DO $$
DECLARE v_n int; v_foreign text;
BEGIN
  SELECT count(*), string_agg(external_id::text, ', ' ORDER BY external_id)
    INTO v_n, v_foreign
    FROM essentials.politicians
   WHERE external_id BETWEEN ${OWNED_LO} AND ${OWNED_HI}
     AND external_id NOT IN (${newList});
  IF v_n <> 0 THEN
    RAISE EXCEPTION '${label}: % row(s) inside this wave''s new id range ${OWNED_LO}..${OWNED_HI} are owned by something else (%). Pick another sub-range rather than colliding.', v_n, v_foreign;
  END IF;
END $$;
${reusedHere.map((r) => `
-- 🔴 (b) PRESENCE, for the reused id. The OPPOSITE assertion, and it must be
--        positive: the row MUST already exist and MUST be the expected person.
--        ⚠ unaccent is NOT installed on prod -- normalize(lower(x), NFD).
DO $$
DECLARE v_name text;
BEGIN
  SELECT full_name INTO v_name FROM essentials.politicians WHERE external_id = ${r.externalId};
  IF v_name IS NULL THEN
    RAISE EXCEPTION '${label}: reused id ${r.externalId} does not exist. It should hold ${REUSED_IDS[r.externalId].expectFullName}, seeded by the FL 2026 US House wave. Do NOT insert a new row for him -- establish what happened to that one first.';
  END IF;
  IF normalize(lower(v_name), NFD) <> normalize(lower(${q(REUSED_IDS[r.externalId].expectFullName)}), NFD) THEN
    RAISE EXCEPTION '${label}: reused id ${r.externalId} holds "%", expected "${REUSED_IDS[r.externalId].expectFullName}". Refusing to seat a stranger on ${r.title}.', v_name;
  END IF;
END $$;`).join('\n')}

-- 🔴 IDENTITY IS KEYED ON external_id, NEVER ON NAME.
--
-- ⚠ THIS WAVE HAS FOUR IN-ROSTER SURNAME PAIRS, and one is a PREFIX rather than
-- an equality: 'Dariel Fernandez' (Tax Collector) and 'Juan Fernandez-Barquin'
-- (Clerk) both match full_name ILIKE '%Fernandez%', and both are constitutional
-- officers of this same county, so no state or body filter separates them. The
-- others are Higgins (Eileen, city Mayor / Danielle Cohen Higgins, county D8),
-- Regalado (Raquel, D7 / Tomas, Property Appraiser -- daughter and father) and
-- Garcia (Rene, D13 / Alina, Supervisor of Elections).
--
-- ⚠ AND THE BOUNDARY LAYERS LIE. Miami-Dade's 2011 vintage and its geometry-less
-- TBLCOMMISSIONDISTRICT both still name Keon Hardemon as a CITY of Miami
-- commissioner; he is County District 3 today. Never read a roster out of a
-- boundary layer.

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
${seedRowsSql(rows)};

-- --- Payload guard ----------------------------------------------------------
DO $$
DECLARE v_n int; v_dup int;
BEGIN
  SELECT count(*) INTO v_n FROM ${tmp};
  IF v_n <> ${seated.length} THEN RAISE EXCEPTION '${label} payload: expected ${seated.length} rows, got %', v_n; END IF;

  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM ${tmp} GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION '${label} payload: % duplicate external_id(s)', v_dup; END IF;

  -- Every id is either inside this wave's new sub-range or a DECLARED reuse.
  SELECT count(*) INTO v_n FROM ${tmp}
   WHERE ext_id NOT BETWEEN ${OWNED_LO} AND ${OWNED_HI}${reusedList ? `
     AND ext_id NOT IN (${reusedList})` : ''};
  IF v_n <> 0 THEN RAISE EXCEPTION '${label} payload: % external_id(s) outside this wave''s sub-range and not a declared reuse', v_n; END IF;

  -- Every (geo_id, mtfcc, district_type, title) is a single seat in this wave.
  SELECT count(*) INTO v_dup FROM (
    SELECT geo_id, mtfcc, district_type, office_title FROM ${tmp}
    GROUP BY geo_id, mtfcc, district_type, office_title HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION '${label} payload: % duplicate seat key(s)', v_dup; END IF;

  SELECT count(*) INTO v_n FROM ${tmp} WHERE term_start IS NULL AND start_precision <> 'unknown';
  IF v_n <> 0 THEN RAISE EXCEPTION '${label} payload: % row(s) have no term_start but claim a precision', v_n; END IF;

  -- 🔴 THE SPLIT, not just the total. A seat mis-mapped to the wide district would
  -- still total correctly and would put one person on EVERY address.
  SELECT count(*) INTO v_n FROM ${tmp} WHERE mtfcc IN ('${CITY_MTFCC}', '${COUNTY_MTFCC}');
  IF v_n <> ${nOnDistricts} THEN RAISE EXCEPTION '${label} payload: expected ${nOnDistricts} rows on single-member districts, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM ${tmp} WHERE mtfcc IN ('G4020', 'G4110');
  IF v_n <> ${nOnWide} THEN RAISE EXCEPTION '${label} payload: expected ${nOnWide} rows on the wide district, got %', v_n; END IF;

  -- And every seat named must resolve to exactly one office in prod.
  SELECT count(*) INTO v_n FROM ${tmp} s
   WHERE (SELECT count(*) FROM essentials.offices o
            JOIN essentials.districts d ON d.id = o.district_id
           WHERE d.geo_id = s.geo_id AND d.mtfcc = s.mtfcc
             AND d.district_type = s.district_type AND lower(d.state) = 'fl'
             AND o.title = s.office_title) <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION '${label} payload: % seat(s) do not resolve to exactly one office', v_n; END IF;
END $$;

-- --- Politicians ------------------------------------------------------------
-- 🔴 REUSED IDS ARE EXCLUDED FROM THE INSERT, not left to ON CONFLICT DO NOTHING.
-- The conflict clause would protect the existing row, but silently -- and silence
-- is what let FL-2 seat 166 people on other people's ids. The exclusion is
-- explicit so a reader can see that Gilbert's row is deliberately untouched.
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name,
       nullif(s.middle_initial, ''), nullif(s.name_suffix, ''),
       s.aliases, true, true, s.source
FROM ${tmp} s
${reusedList ? `WHERE s.ext_id NOT IN (${reusedList})\n` : ''}ON CONFLICT (external_id) DO NOTHING;

-- --- Occupancy --------------------------------------------------------------
-- 🔴 TWO PATHS, AND THE SECOND IS NOT A SHORTCUT. seat_officeholder() refuses a
-- NULL term_start outright. This wave has none -- all 25 are dated -- so only the
-- first path fires; the second is kept so a later wave inherits it.
--
-- ⚠ THE REUSED PERSON IS IN THIS LOOP. The office term is exactly what the wave
-- adds for him.
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
        RAISE EXCEPTION '${label}: office % already carries % term row(s), so an undated open term cannot be inserted directly', r.office_id, v_prior;
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

/** Shared precision/how_started histogram, computed from the roster. */
function histogram(rows) {
  const live = rows.filter((r) => !r.isVacant);
  return {
    nAppointed: live.filter((r) => r.howStarted === 'appointed').length,
    nDay: live.filter((r) => r.precision === 'day').length,
    nMonth: live.filter((r) => r.precision === 'month').length,
    nYear: live.filter((r) => r.precision === 'year').length,
    nUnknown: live.filter((r) => r.precision === 'unknown').length,
    appointedTitles: live.filter((r) => r.howStarted === 'appointed').map((r) => q(r.title)).join(', '),
  };
}

// ── Migration 1: City of Miami, structure ───────────────────────────────────

function renderCityStructure(city, counts) {
  const parts = [];
  const commSeats = city.filter((s) => s.on === 'commdist_city');

  parts.push(HEADER(
    CITY_STRUCTURE_FILE,
    CITY_PEOPLE_FILE,
    `Creates the geography-and-seats half of the City of Miami:\n` +
    `--   * ${N_CITY_DISTRICTS} new LOCAL districts (mtfcc ${CITY_MTFCC}) + 1 citywide LOCAL district (TIGER place ${PLACE_GEO_ID})\n` +
    `--   * 1 government, 2 chambers -- the Mayor is NOT a member of the Commission\n` +
    `--   * ${counts.cityOffices} offices -- ${N_CITY_DISTRICTS} single-member commissioners + the Mayor`,
  ));

  parts.push(`
-- ---------------------------------------------------------------------------
-- 🔴 THE MAYOR IS NOT A COMMISSIONER, WHICH INVERTS FL-4's SHAPE.
--
-- Tallahassee's mayor is SEAT 4 of a five-member at-large commission -- one
-- chamber, five seats on one district. Miami's Mayor is a separate executive
-- elected citywide, and the five commissioners are elected from single-member
-- districts. So: TWO chambers, and the citywide district carries exactly ONE
-- office where Tallahassee's carries five.
--
-- ⚠ Chair and Vice Chair ARE NOT OFFICES. The Commission elects them from among
-- its own members; Christine King (D5) was reappointed Chair on 2025-12-22. Same
-- ruling as Bradenton's and Asheville's Vice Mayor.
--
-- ⚠ City Manager, City Clerk and City Attorney are APPOINTED. miami.gov lists
-- them beside the six elected officials; they are not offices in this wave.
--
-- ---------------------------------------------------------------------------
-- 🔴 THE FIVE DISTRICTS ARE THE MAY 2024 SETTLEMENT MAP.
--
-- Miami's 2022 and 2023 commission maps were BOTH held unconstitutionally
-- racially gerrymandered by Judge K. Michael Moore in April 2024. The map in
-- force is the one the Commission adopted 4-1 in a May 2024 settlement, drawn by
-- the plaintiffs. ${CITY_MTFCC} carries that map, and its loader refuses to run against
-- the 2017 "Enriched Commission Districts" vintage that is still published with
-- identical field names.

BEGIN;

-- --- 0. Pre-flight ----------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries
     WHERE geo_id = '${PLACE_GEO_ID}' AND mtfcc = 'G4110'
  ) THEN
    RAISE EXCEPTION 'miami structure: TIGER place ${PLACE_GEO_ID}/G4110 is missing -- FL-1 must be applied first; the Mayor hangs off it';
  END IF;

  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = '${CITY_MTFCC}';
  IF v_n <> ${N_CITY_DISTRICTS} THEN
    RAISE EXCEPTION 'miami structure: expected ${N_CITY_DISTRICTS} ${CITY_MTFCC} boundaries, found % -- run scripts/load-miami-city-commission-boundaries.ts first', v_n;
  END IF;
END $$;

-- --- 1. The citywide district (the Mayor only) ------------------------------
-- ⚠ num_officials is 1, NOT Tallahassee's 5. Only the Mayor is elected citywide.

INSERT INTO essentials.districts (district_type, label, state, geo_id, mtfcc, num_officials)
SELECT 'LOCAL', 'Miami Citywide', 'fl', '${PLACE_GEO_ID}', 'G4110', 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '${PLACE_GEO_ID}' AND mtfcc = 'G4110' AND district_type = 'LOCAL'
);

-- --- 2. The five single-member commission districts -------------------------
`);

  for (const s of commSeats) {
    parts.push(`INSERT INTO essentials.districts (district_type, label, state, geo_id, mtfcc, num_officials)
SELECT 'LOCAL', 'Miami City Commission District ${s.n}', 'fl', '${CITY_DIST_PREFIX}${s.n}', '${CITY_MTFCC}', 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '${CITY_DIST_PREFIX}${s.n}' AND mtfcc = '${CITY_MTFCC}' AND district_type = 'LOCAL'
);`);
  }

  parts.push(`
-- --- 3. Government ----------------------------------------------------------

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT ${q(CITY_GOV)}, 'City', 'FL', 'Miami', '${PLACE_GEO_ID}'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '${PLACE_GEO_ID}' AND type = 'City'
);

-- --- 4. Chambers ------------------------------------------------------------
-- chambers.slug is GENERATED from name_formal and cannot be inserted.
-- ⚠ 'Office of the Mayor' also exists in the COUNTY government. name_formal
--    differs, so the generated slugs differ and the rows cannot collide.

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'City Commission', 'Miami City Commission', ${N_CITY_DISTRICTS}, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${PLACE_GEO_ID}' AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
     WHERE c.government_id = g.id AND c.name = 'City Commission'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Office of the Mayor', 'City of Miami Office of the Mayor', 1, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${PLACE_GEO_ID}' AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
     WHERE c.government_id = g.id AND c.name = 'Office of the Mayor'
  );

-- --- 5. Offices -------------------------------------------------------------
`);

  for (const s of city) parts.push(officeInsertSql(s, PLACE_GEO_ID, 'City', 'FL', 'Miami'));

  parts.push(`
-- --- 6. Post-verify gate ----------------------------------------------------
DO $$
DECLARE v_n int; v_gov uuid; v_d text; v_t text;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE mtfcc = '${CITY_MTFCC}' AND district_type = 'LOCAL' AND lower(state) = 'fl';
  IF v_n <> ${N_CITY_DISTRICTS} THEN RAISE EXCEPTION 'miami structure: expected ${N_CITY_DISTRICTS} ${CITY_MTFCC} districts, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = '${PLACE_GEO_ID}' AND mtfcc = 'G4110' AND district_type = 'LOCAL';
  IF v_n <> 1 THEN RAISE EXCEPTION 'miami structure: expected exactly 1 citywide district, got %', v_n; END IF;

  SELECT id INTO v_gov FROM essentials.governments
   WHERE geo_id = '${PLACE_GEO_ID}' AND type = 'City';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'miami structure: the government row is missing'; END IF;

  -- 🔴 TWO chambers, not Tallahassee's one. The Mayor is not a commissioner.
  SELECT count(*) INTO v_n FROM essentials.chambers WHERE government_id = v_gov;
  IF v_n <> 2 THEN RAISE EXCEPTION 'miami structure: expected 2 chambers, got % -- Miami''s Mayor is a separate executive, not a seat on the Commission', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers
   WHERE government_id = v_gov AND ((name = 'City Commission' AND official_count = ${N_CITY_DISTRICTS})
                                 OR (name = 'Office of the Mayor' AND official_count = 1));
  IF v_n <> 2 THEN RAISE EXCEPTION 'miami structure: chamber names or official_counts are wrong'; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_n <> ${counts.cityOffices} THEN RAISE EXCEPTION 'miami structure: expected ${counts.cityOffices} offices, got %', v_n; END IF;

  -- PER DISTRICT: exactly one commissioner on each of the five.
  FOR v_d IN SELECT '${CITY_DIST_PREFIX}' || g FROM generate_series(1,${N_CITY_DISTRICTS}) g LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = v_d AND d.mtfcc = '${CITY_MTFCC}' AND d.district_type = 'LOCAL';
    IF v_n <> 1 THEN RAISE EXCEPTION 'miami structure: city district % carries % offices, expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- 🔴 EXACTLY ONE OFFICE ON THE CITYWIDE DISTRICT -- the Mayor, and nothing else.
  -- Tallahassee's equivalent expects 5. If this reads 2 a commissioner was mapped
  -- citywide and now appears for every address in Miami.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND d.geo_id = '${PLACE_GEO_ID}'
     AND d.mtfcc = 'G4110' AND d.district_type = 'LOCAL';
  IF v_n <> 1 THEN RAISE EXCEPTION 'miami structure: expected exactly 1 office on the citywide district (the Mayor), got %', v_n; END IF;

  -- ...and no commissioner may be among them, stated directly.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'City Commission'
     AND d.geo_id = '${PLACE_GEO_ID}' AND d.mtfcc = 'G4110';
  IF v_n <> 0 THEN RAISE EXCEPTION 'miami structure: % commissioner office(s) landed on the citywide district -- Miami has no at-large commissioner', v_n; END IF;

  SELECT count(DISTINCT o.title) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_n <> ${counts.cityOffices} THEN RAISE EXCEPTION 'miami structure: expected ${counts.cityOffices} DISTINCT seat titles, got %', v_n; END IF;

  -- 🔴 THE THREE FORBIDDEN TITLES, IN THE CITY GOVERNMENT TOO. This generator
  -- descends from Leon's, where Superintendent of Schools is a live entry.
  FOR v_t IN SELECT unnest(ARRAY[${FORBIDDEN_TITLES.map(q).join(', ')}]) LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = v_gov AND o.title = v_t;
    IF v_n <> 0 THEN RAISE EXCEPTION 'miami structure: % must NOT be seated, found % office(s)', v_t, v_n; END IF;
  END LOOP;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov AND lower(d.state) <> 'fl';
  IF v_n <> 0 THEN RAISE EXCEPTION 'miami structure: % office(s) landed outside Florida', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_n <> 0 THEN RAISE EXCEPTION 'miami structure: % office(s) sit on a district with no matching boundary', v_n; END IF;

  RAISE NOTICE 'miami structure OK: ${N_CITY_DISTRICTS} district + 1 citywide, 1 government, 2 chambers, ${counts.cityOffices} offices';
END $$;

COMMIT;
`);
  return parts.join('\n');
}

// ── Migration 2: City of Miami, people ──────────────────────────────────────

function renderCityPeople(city, counts) {
  const cityIds = city.map((r) => r.externalId).filter(Boolean).join(', ');
  const h = histogram(city);
  const parts = [];

  parts.push(HEADER(
    CITY_PEOPLE_FILE,
    CITY_STRUCTURE_FILE,
    `Seats the ${counts.cityPeople} elected officials of the City of Miami:\n` +
    `--   * ${counts.cityPeople} politicians in the -(1240000 + n) band\n` +
    `--   * ${counts.cityPeople} office_terms rows -- ${N_CITY_DISTRICTS} on ${CITY_MTFCC}, 1 citywide`,
  ));

  parts.push(`
-- ---------------------------------------------------------------------------
-- 🔴 MIAMI HAS NO UNIFORM TAKE-OFFICE RULE, AND THAT IS THE FINDING.
--
-- Miami-Dade's Charter fixes one for the county (art. 3 ss. 3.01(A) and (D): the
-- second Tuesday after the November general). Miami has none: each of these six
-- was sworn in after their own election or runoff resolved, on four dates across
-- seven months --
--   2021-11-10  King (D5), after unseating the incumbent on 2021-11-02
--   2023-12     Gabela (D1) and Pardo (D2), after the 2023-11-21 runoff
--   2025-06-10  Rosado (D4), a SPECIAL election to fill a seat left by a death
--   2025-12-17  Escalona (D3), after the 2025-12-09 runoff
--   2025-12-18  Higgins (Mayor), after the same runoff
--
-- ⚠ DO NOT DERIVE A MIAMI DATE FROM A CYCLE. Miami's elections run in ODD years
-- and terms are four years with a two-term lifetime limit since a November 2024
-- charter amendment, but none of that fixes a swearing-in day.
--
-- ⚠ GABELA AND PARDO ARE AT MONTH PRECISION DELIBERATELY. Two ceremonies are
-- reported -- a private oath on 2023-12-02 and a public ceremony for Pardo on
-- 2023-12-16 -- and choosing between them would be inventing a day.
--
-- ⚠ KING IS 2021, NOT 2025. term_start is the start of CONTINUOUS OCCUPANCY; she
-- was re-elected on 2025-11-04 with 84.4% and the span did not break.

BEGIN;
${occupancySql(city, 'miami_city_seed', 'miami people', ALL_NEW_IDS)}
-- --- Post-verify gate ------------------------------------------------------
DO $$
DECLARE v_gov uuid; v_pol int; v_seated int; v_n int; v_d text;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '${PLACE_GEO_ID}' AND type = 'City';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'miami people: the government row is missing -- apply the structure half first'; END IF;

  -- ⚠ THIS MIGRATION'S OWN IDS, not the band: a band count is non-idempotent.
  SELECT count(*) INTO v_pol FROM essentials.politicians WHERE external_id IN (${cityIds});
  IF v_pol <> ${counts.cityPeople} THEN RAISE EXCEPTION 'miami people: expected ${counts.cityPeople} of this wave''s politicians, got %', v_pol; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs from
  -- offices, so a vacancy is a NULL politician_id and count(*) passes vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov;
  IF v_seated <> ${counts.cityPeople} THEN RAISE EXCEPTION 'miami people: expected ${counts.cityPeople} seated officials, found %', v_seated; END IF;

  -- One seated commissioner per single-member district -- ALL FIVE.
  FOR v_d IN SELECT '${CITY_DIST_PREFIX}' || g FROM generate_series(1,${N_CITY_DISTRICTS}) g LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id = v_d AND d.mtfcc = '${CITY_MTFCC}' AND d.district_type = 'LOCAL';
    IF v_n <> 1 THEN RAISE EXCEPTION 'miami people: city district % has % seated member(s), expected 1', v_d, v_n; END IF;
  END LOOP;

  -- The Mayor, and ONLY the Mayor, on the citywide district.
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov AND d.geo_id = '${PLACE_GEO_ID}'
     AND d.mtfcc = 'G4110' AND d.district_type = 'LOCAL';
  IF v_n <> 1 THEN RAISE EXCEPTION 'miami people: expected exactly 1 seated citywide official (the Mayor), got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.is_vacant = true;
  IF v_n <> 0 THEN RAISE EXCEPTION 'miami people: % office(s) flagged vacant, expected 0', v_n; END IF;

  -- The precision histogram, per bucket: day ${h.nDay} / month ${h.nMonth} / year ${h.nYear} / unknown ${h.nUnknown}.
  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.start_precision = 'day';
  IF v_n <> ${h.nDay} THEN RAISE EXCEPTION 'miami people: expected ${h.nDay} day-precision terms, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.start_precision = 'month';
  IF v_n <> ${h.nMonth} THEN RAISE EXCEPTION 'miami people: expected ${h.nMonth} month-precision terms (Gabela and Pardo, 2023-12), got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND (t.start_precision = 'unknown' OR t.term_start IS NULL);
  IF v_n <> ${h.nUnknown} THEN RAISE EXCEPTION 'miami people: expected ${h.nUnknown} unknown-precision or undated terms, got %', v_n; END IF;

  -- 🔴 EVERY CITY TERM IS 'elected'. Miami has no appointment in this wave; the
  -- four appointments are all on the COUNTY side.
  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.how_started <> 'elected';
  IF v_n <> 0 THEN RAISE EXCEPTION 'miami people: % city term(s) are not how_started = elected, expected 0', v_n; END IF;

  -- No office with neither a term row nor a vacancy flag: the one failure mode CI
  -- cannot catch.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_terms t ON t.office_id = o.id
   WHERE c.government_id = v_gov AND t.id IS NULL AND o.is_vacant = false;
  IF v_n <> 0 THEN RAISE EXCEPTION 'miami people: % office(s) have no term row and no vacancy flag', v_n; END IF;

  RAISE NOTICE 'miami people OK: ${counts.cityPeople} politicians, ${counts.cityPeople} seated, 0 vacant, ${h.nUnknown} unknown-precision';
END $$;

COMMIT;
`);
  return parts.join('\n');
}

// ── Migration 3: Miami-Dade County, offices AND people ──────────────────────

function renderCounty(county, counts) {
  const countyIds = county.map((r) => r.externalId).filter(Boolean).join(', ');
  const newCountyIds = county.filter((r) => !r.isReused).map((r) => r.externalId).filter(Boolean);
  const commSeats = county.filter((s) => s.on === 'commdist');
  const h = histogram(county);
  const nWide = county.filter((r) => r.on === 'countywide').length; // Mayor + 5 officers
  const parts = [];

  parts.push(HEADER(
    COUNTY_FILE,
    null,
    `Creates Miami-Dade County whole -- offices AND people in ONE migration, per spec section 3:\n` +
    `--   * ${N_COUNTY_DISTRICTS} new COUNTY districts (mtfcc ${COUNTY_MTFCC}); the countywide district ALREADY EXISTS\n` +
    `--   * 1 government, 3 chambers\n` +
    `--   * ${counts.countyOffices} offices -- ${N_COUNTY_DISTRICTS} commissioners + the Mayor + ${N_OFFICERS} constitutional officers\n` +
    `--   * ${counts.countyPeople} terms from ${newCountyIds.length} NEW politician rows -- one person is REUSED\n` +
    `--\n` +
    `-- ⚠ Companion migrations ${CITY_STRUCTURE_FILE} and ${CITY_PEOPLE_FILE} seat the CITY of Miami.\n` +
    `-- This file has no ordering dependency on them.`,
  ));

  parts.push(`
-- ---------------------------------------------------------------------------
-- 🔴 THIRTEEN SINGLE-MEMBER DISTRICTS AND NO AT-LARGE COMMISSIONER.
--
-- Manatee has 5 + 2, Leon 5 + 2, Palm Beach 7 + 0, Miami-Dade 13 + 0. Four
-- counties, four shapes -- never inherit the template. The Mayor is elected
-- COUNTYWIDE and is NOT a member of the Board, so the pre-existing countywide
-- district carries ${nWide} offices: the Mayor plus the ${N_OFFICERS} officers.
--
-- 🔴 The gates assert the ${N_COUNTY_DISTRICTS}/${nWide} SPLIT, not just the total of ${counts.countyOffices}. A commission
-- seat mis-mapped countywide would still total ${counts.countyOffices}, would pass a total-only gate,
-- and would put that one commissioner on EVERY Miami-Dade address.
--
-- ---------------------------------------------------------------------------
-- 🔴 FIVE CONSTITUTIONAL OFFICERS, ALL SEATED ON 2025-01-07.
--
-- Amendment 10 (adopted 2018-11-06) required charter counties to create or
-- re-establish the five independent offices. The county's own page: "In Nov.
-- 2024, County residents elected the new constitutional officers, which assumed
-- their role on Jan. 7, 2025." Five people sharing one published date is a strong
-- invariant and a cheap gate; it is asserted explicitly below.
--
-- ⚠ THE PROPERTY APPRAISER IS THE ODD ONE. Miami-Dade had an elected Property
-- Appraiser BEFORE Amendment 10 -- it was simply not independent of the County.
-- Tomas Regalado's occupancy still begins 2025-01-07: he was elected in Nov 2024
-- and took office with the other four.
--
-- 🔴 NO STATE ATTORNEY AND NO PUBLIC DEFENDER. Officers of the 11th JUDICIAL
-- CIRCUIT, the same exclusion FL-5 made for Palm Beach's 15th. And no
-- Superintendent of Schools -- the School Board appoints one. All three are
-- asserted to match ZERO offices, because this generator descends from Leon's,
-- where the Superintendent is a live entry.
--
-- ⚠ Also excluded: 9 School Board members, 4 South Dade Soil & Water seats, and
-- 60 elected Community Council members (10 councils x 6). See ROSTERS.md.
--
-- ---------------------------------------------------------------------------
-- 🔴 THE TAKE-OFFICE RULE IS FROM THE CHARTER, AND IT IS CORROBORATED BOTH WAYS.
--
-- Miami-Dade County Charter art. 3 s. 3.01(A) (commissioners) and s. 3.01(D)
-- (Mayor), quoted in the county's own candidate qualifying handbooks: "the term
-- ... shall commence on the second Tuesday next succeeding the date of the
-- General Election in November (November 17, 2020)."
--   2020 general 11-03 -> 2020-11-17     2022 general 11-08 -> 2022-11-22
--   2024 general 11-05 -> 2024-11-19
-- FORWARDS it reproduces the SOE's own "Current Term Ends" values (11/17/2026 for
-- the 2022 cohort, 11/21/2028 for the 2024 cohort). BACKWARDS it matches published
-- assumed-office dates for Gilbert, Regalado, McGhee and Steinberg.
--
-- ⚠ "Current Term Ends" is NOT term_end and is NOT written.
--
-- ---------------------------------------------------------------------------
-- 🔴 ${h.nAppointed} APPOINTMENTS, NOT TWO -- AND ONE IS BY THE GOVERNOR.
--
-- The SOE marks only D5 and D6 'Appointed' because only they still serve under
-- one. term_start is the start of CONTINUOUS OCCUPANCY, so two more spans began
-- with an appointment and are invisible in the SOE:
--   D5  Vicki L. Lopez        2025-11-19  Commission, 7-5, after Eileen Higgins
--                                         resigned to run for Mayor of Miami
--   D6  Natalie Milian Orbis  2025-05-06  Commission, replacing Kevin Marino
--                                         Cabrera (US Ambassador to Panama)
--   D8  Danielle Cohen Higgins 2020-12-07 Commission, 10-1, for the last two years
--                                         of Levine Cava's term; ELECTED 2022
--   D11 Roberto J. Gonzalez   2022-11-23  🔴 GOV. DeSANTIS, after Commissioner
--                                         Martinez was suspended; ELECTED 2024
-- "Appointed" does not imply the same appointing authority. The gates assert ${h.nAppointed}
-- and check the titles, because a count alone passes if one is mislabelled.
--
-- ---------------------------------------------------------------------------
-- 🔴 ONE PERSON IS REUSED. Oliver Gilbert already exists as external_id -1212402,
-- a 2026 US House candidate for FL-24 with no office. This migration gives him an
-- office_terms row and inserts NO politician row for him -- ${counts.countyPeople} terms from ${newCountyIds.length}
-- new people. His published county form is 'Oliver G. Gilbert, III'; that is NOT
-- written, because it would mean UPDATEing a row another wave owns.
-- ▶ If he wins in November he resigns District 1.

BEGIN;

-- --- 0. Pre-flight ----------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = '${COUNTY_MTFCC}';
  IF v_n <> ${N_COUNTY_DISTRICTS} THEN
    RAISE EXCEPTION 'miami-dade county: expected ${N_COUNTY_DISTRICTS} ${COUNTY_MTFCC} boundaries, found % -- run scripts/load-miami-dade-commission-boundaries.ts first', v_n;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '${COUNTY_GEO_ID}' AND mtfcc = 'G4020'
  ) THEN
    RAISE EXCEPTION 'miami-dade county: TIGER county ${COUNTY_GEO_ID}/G4020 is missing';
  END IF;

  -- The countywide district must ALREADY exist. This migration must not create a
  -- second one: ${nWide} of its ${counts.countyOffices} offices hang off it.
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = '${COUNTY_GEO_ID}' AND mtfcc = 'G4020' AND district_type = 'COUNTY' AND lower(state) = 'fl';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'miami-dade county: expected exactly 1 pre-existing COUNTY district for ${COUNTY_GEO_ID}, found %', v_n;
  END IF;
END $$;

-- --- 1. The thirteen single-member commission districts ---------------------
`);

  for (const s of commSeats) {
    parts.push(`INSERT INTO essentials.districts (district_type, label, state, geo_id, mtfcc, num_officials)
SELECT 'COUNTY', 'Miami-Dade County Commission District ${s.n}', 'fl', '${COUNTY_DIST_PREFIX}${s.n}', '${COUNTY_MTFCC}', 1
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
-- THREE chambers. ⚠ 'Office of the Mayor' also exists in the CITY government;
-- name_formal differs, so the generated slugs differ.

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Board of County Commissioners', 'Miami-Dade Board of County Commissioners', ${N_COUNTY_DISTRICTS}, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${COUNTY_GEO_ID}' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
     WHERE c.government_id = g.id AND c.name = 'Board of County Commissioners'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Office of the Mayor', 'Miami-Dade County Office of the Mayor', 1, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${COUNTY_GEO_ID}' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
     WHERE c.government_id = g.id AND c.name = 'Office of the Mayor'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Elected Officials', 'Miami-Dade County Elected Officials', ${N_OFFICERS}, 'full'
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
DECLARE v_gov uuid; v_n int; v_d text; v_t text;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE mtfcc = '${COUNTY_MTFCC}' AND district_type = 'COUNTY' AND lower(state) = 'fl';
  IF v_n <> ${N_COUNTY_DISTRICTS} THEN RAISE EXCEPTION 'miami-dade county: expected ${N_COUNTY_DISTRICTS} ${COUNTY_MTFCC} districts, got %', v_n; END IF;

  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '${COUNTY_GEO_ID}' AND type = 'County';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'miami-dade county: the government row is missing'; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers WHERE government_id = v_gov;
  IF v_n <> 3 THEN RAISE EXCEPTION 'miami-dade county: expected 3 chambers, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers
   WHERE government_id = v_gov AND ((name = 'Board of County Commissioners' AND official_count = ${N_COUNTY_DISTRICTS})
                                 OR (name = 'Office of the Mayor' AND official_count = 1)
                                 OR (name = 'Elected Officials' AND official_count = ${N_OFFICERS}));
  IF v_n <> 3 THEN RAISE EXCEPTION 'miami-dade county: chamber names or official_counts are wrong -- Elected Officials must be ${N_OFFICERS}, not Leon''s 6'; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_n <> ${counts.countyOffices} THEN RAISE EXCEPTION 'miami-dade county: expected ${counts.countyOffices} offices, got %', v_n; END IF;

  -- PER CHAMBER, not just in total.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Board of County Commissioners';
  IF v_n <> ${N_COUNTY_DISTRICTS} THEN RAISE EXCEPTION 'miami-dade county: expected ${N_COUNTY_DISTRICTS} commissioner offices, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Elected Officials';
  IF v_n <> ${N_OFFICERS} THEN RAISE EXCEPTION 'miami-dade county: expected ${N_OFFICERS} constitutional officer offices, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Office of the Mayor';
  IF v_n <> 1 THEN RAISE EXCEPTION 'miami-dade county: expected 1 Mayor office, got %', v_n; END IF;

  -- 🔴 THE FIVE OFFICERS BY TITLE. A count of ${N_OFFICERS} is reachable by duplicating one.
  FOR v_t IN SELECT unnest(ARRAY[${county.filter((r) => r.chamber === 'Elected Officials').map((r) => q(r.title)).join(', ')}]) LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = v_gov AND o.title = v_t;
    IF v_n <> 1 THEN RAISE EXCEPTION 'miami-dade county: expected exactly 1 office titled %, got %', v_t, v_n; END IF;
  END LOOP;

  -- 🔴 AND THE THREE THAT MUST NOT EXIST.
  FOR v_t IN SELECT unnest(ARRAY[${FORBIDDEN_TITLES.map(q).join(', ')}]) LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = v_gov AND o.title = v_t;
    IF v_n <> 0 THEN RAISE EXCEPTION 'miami-dade county: % must NOT be seated in this wave, found % office(s)', v_t, v_n; END IF;
  END LOOP;

  -- PER DISTRICT: exactly one commissioner on each of the thirteen.
  FOR v_d IN SELECT '${COUNTY_DIST_PREFIX}' || g FROM generate_series(1,${N_COUNTY_DISTRICTS}) g LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = v_d AND d.mtfcc = '${COUNTY_MTFCC}' AND d.district_type = 'COUNTY';
    IF v_n <> 1 THEN RAISE EXCEPTION 'miami-dade county: commission district % carries % offices, expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- 🔴 ...AND EXACTLY ${nWide} ON THE COUNTYWIDE DISTRICT -- the Mayor and the ${N_OFFICERS} officers.
  -- Palm Beach's equivalent expects 5, Leon's 8, Manatee's 7. If this reads ${nWide + 1} a
  -- commission seat was mapped 'countywide'.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND d.geo_id = '${COUNTY_GEO_ID}'
     AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY';
  IF v_n <> ${nWide} THEN RAISE EXCEPTION 'miami-dade county: expected ${nWide} offices on the countywide district (Mayor + ${N_OFFICERS} officers), got %', v_n; END IF;

  -- ⚠ AND NO COMMISSIONER MAY BE AMONG THEM, stated directly.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Board of County Commissioners'
     AND d.geo_id = '${COUNTY_GEO_ID}' AND d.mtfcc = 'G4020';
  IF v_n <> 0 THEN RAISE EXCEPTION 'miami-dade county: % commissioner office(s) landed on the countywide district -- Miami-Dade has no at-large seat', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov AND lower(d.state) <> 'fl';
  IF v_n <> 0 THEN RAISE EXCEPTION 'miami-dade county: % office(s) landed outside Florida', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_n <> 0 THEN RAISE EXCEPTION 'miami-dade county: % office(s) sit on a district with no matching boundary', v_n; END IF;

  RAISE NOTICE 'miami-dade county structure OK: ${N_COUNTY_DISTRICTS} new districts, 1 government, 3 chambers, ${counts.countyOffices} offices (${N_COUNTY_DISTRICTS} district + ${nWide} countywide)';
END $$;
${occupancySql(county, 'miami_dade_seed', 'miami-dade county', ALL_NEW_IDS)}
-- --- 6. Occupancy post-verify gate ----------------------------------------
DO $$
DECLARE v_gov uuid; v_pol int; v_seated int; v_n int; v_d text; v_t text;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '${COUNTY_GEO_ID}' AND type = 'County';

  -- ⚠ THIS MIGRATION'S OWN IDS, not the band. ${counts.countyPeople} rows from ${newCountyIds.length} inserts plus the reuse.
  SELECT count(*) INTO v_pol FROM essentials.politicians WHERE external_id IN (${countyIds});
  IF v_pol <> ${counts.countyPeople} THEN
    RAISE EXCEPTION 'miami-dade county: expected ${counts.countyPeople} of this wave''s politicians, got %', v_pol;
  END IF;

  -- 🔴 THE REUSE LANDED AS A TERM, NOT AS A NEW PERSON. A duplicate row named
  -- Oliver Gilbert means the exclusion in the politician insert failed and the
  -- District 1 seat is held by a copy rather than by the existing record.
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE normalize(lower(full_name), NFD) = normalize(lower('Oliver Gilbert'), NFD);
  IF v_n <> 1 THEN RAISE EXCEPTION 'miami-dade county: % politician row(s) named Oliver Gilbert, expected exactly 1 -- a duplicate means the reuse failed', v_n; END IF;

  -- ...and it is the ORIGINAL row, still carrying its congressional candidacy.
  SELECT count(*) INTO v_n FROM essentials.politicians p
    JOIN essentials.office_terms t ON t.politician_id = p.id
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE p.external_id = -1212402
     AND d.geo_id = '${COUNTY_DIST_PREFIX}1' AND d.mtfcc = '${COUNTY_MTFCC}';
  IF v_n <> 1 THEN RAISE EXCEPTION 'miami-dade county: external_id -1212402 does not hold Commission District 1'; END IF;

  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov;
  IF v_seated <> ${counts.countyPeople} THEN RAISE EXCEPTION 'miami-dade county: expected ${counts.countyPeople} seated officials, found %', v_seated; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.is_vacant = true;
  IF v_n <> 0 THEN RAISE EXCEPTION 'miami-dade county: % office(s) flagged vacant, expected 0', v_n; END IF;

  -- One seated commissioner per single-member district -- ALL THIRTEEN.
  FOR v_d IN SELECT '${COUNTY_DIST_PREFIX}' || g FROM generate_series(1,${N_COUNTY_DISTRICTS}) g LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id = v_d AND d.mtfcc = '${COUNTY_MTFCC}' AND d.district_type = 'COUNTY';
    IF v_n <> 1 THEN RAISE EXCEPTION 'miami-dade county: commission district % has % seated member(s), expected 1', v_d, v_n; END IF;
  END LOOP;

  SELECT count(och.politician_id) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov AND d.geo_id = '${COUNTY_GEO_ID}'
     AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY';
  IF v_n <> ${nWide} THEN RAISE EXCEPTION 'miami-dade county: expected ${nWide} seated countywide officials, got %', v_n; END IF;

  -- 🔴 ALL FIVE OFFICERS ON 2025-01-07, AT DAY PRECISION. Amendment 10's five
  -- independent offices began on one published date.
  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Elected Officials'
     AND t.term_start = DATE '2025-01-07' AND t.start_precision = 'day';
  IF v_n <> ${N_OFFICERS} THEN RAISE EXCEPTION 'miami-dade county: expected ${N_OFFICERS} officers seated on 2025-01-07 (Amendment 10), got %', v_n; END IF;

  -- The precision histogram, per bucket: day ${h.nDay} / month ${h.nMonth} / year ${h.nYear} / unknown ${h.nUnknown}.
  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.start_precision = 'day';
  IF v_n <> ${h.nDay} THEN RAISE EXCEPTION 'miami-dade county: expected ${h.nDay} day-precision terms, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND (t.start_precision = 'unknown' OR t.term_start IS NULL);
  IF v_n <> ${h.nUnknown} THEN RAISE EXCEPTION 'miami-dade county: expected ${h.nUnknown} unknown-precision or undated terms, got %', v_n; END IF;

  -- 🔴 ${h.nAppointed} APPOINTMENTS, AND THE RIGHT ${h.nAppointed}. A count alone would pass if an elected
  -- member were mislabelled, so assert the titles. The plan predicted TWO; the SOE
  -- hides D8 and D11 because both have since won ordinary terms.
  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.how_started = 'appointed';
  IF v_n <> ${h.nAppointed} THEN RAISE EXCEPTION 'miami-dade county: expected ${h.nAppointed} appointed terms, got %', v_n; END IF;

  FOR v_t IN SELECT unnest(ARRAY[${h.appointedTitles}]) LOOP
    SELECT count(*) INTO v_n FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = v_gov AND o.title = v_t AND t.how_started = 'appointed';
    IF v_n <> 1 THEN RAISE EXCEPTION 'miami-dade county: % should carry an appointed term, got %', v_t, v_n; END IF;
  END LOOP;

  -- No office with neither a term row nor a vacancy flag.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_terms t ON t.office_id = o.id
   WHERE c.government_id = v_gov AND t.id IS NULL AND o.is_vacant = false;
  IF v_n <> 0 THEN RAISE EXCEPTION 'miami-dade county: % office(s) have no term row and no vacancy flag', v_n; END IF;

  RAISE NOTICE 'miami-dade county OK: ${counts.countyOffices} offices, ${counts.countyPeople} seated (${newCountyIds.length} new + 1 reused), 0 vacant, ${h.nAppointed} appointed, ${h.nUnknown} unknown-precision';
END $$;

COMMIT;
`);
  return parts.join('\n');
}

// ── Main ────────────────────────────────────────────────────────────────────

function main() {
  const md = readFileSync(ROSTER, 'utf8');
  const { city, county, counts } = parseRosters(md);

  // 🔴 NEW ids only. The reuse is asserted positively, never allowlisted into the
  //    absence guard's range.
  ALL_NEW_IDS = [...city, ...county]
    .filter((r) => !r.isReused)
    .map((r) => r.externalId).filter(Boolean)
    .map(Number).sort((a, b) => a - b);

  const files = [
    [CITY_STRUCTURE_FILE, renderCityStructure(city, counts)],
    [CITY_PEOPLE_FILE, renderCityPeople(city, counts)],
    [COUNTY_FILE, renderCounty(county, counts)],
  ];
  for (const [name, body] of files) {
    writeFileSync(join(MIGRATIONS, name), body.replace(/\n{3,}/g, '\n\n'));
    console.log(`wrote migrations/${name}  (${body.split('\n').length} lines)`);
  }
  const reused = [...city, ...county].filter((r) => r.isReused).length;
  console.log(
    `\n${counts.cityOffices} city + ${counts.countyOffices} county offices / ` +
    `${counts.cityPeople + counts.countyPeople} people / ${counts.vacancies} vacancies. ` +
    `${ALL_NEW_IDS.length} new politician rows, ${reused} reused.`,
  );
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) main();
