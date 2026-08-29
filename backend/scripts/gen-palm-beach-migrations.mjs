/**
 * gen-palm-beach-migrations.mjs
 *
 * Turns data/seed-palm-beach-2026/ROSTERS.md into ONE migration:
 *
 *   CC_0014_palm_beach_county.sql   districts + government + chambers + offices
 *                                   + politicians + occupancy, in ONE migration
 *                                   per spec section 3
 *
 * Reads NOTHING from the database. Everything it asserts comes from the roster
 * file, and the migration it emits re-asserts those numbers against prod.
 *
 * Wave FL-5 of the Knight Foundation cities program.
 * Plan: docs/superpowers/plans/2026-08-28-knight-fl-wave-5-palm-beach-county.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 ONE MIGRATION, BECAUSE THERE IS NO CITY HALF.
 *
 * Palm Beach County is the only Knight jurisdiction in Florida with no municipal
 * wave. FL-3 and FL-4 each emitted city structure + city occupancy + county;
 * this emits only the county file, which already carries offices and people
 * together.
 *
 * ⚠ FL-4's renderCityStructure() and renderCityPeople() are DELETED here, not
 * left dormant. FL-6 (Miami + Miami-Dade) DOES have a city half and should copy
 * gen-tallahassee-leon-migrations.mjs, NOT this file.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THREE SHAPE DIFFERENCES FROM FL-4, AND EACH ONE INVERTS AN ASSERTION.
 *
 * 1. SEVEN SINGLE-MEMBER DISTRICTS AND NO AT-LARGE SEAT. Manatee has 5 + 2
 *    ("District 6"/"District 7"); Leon has 5 + 2 ("At Large, Group 1"/"Group 2");
 *    Palm Beach has 7 + 0. So the pre-existing countywide district carries ONLY
 *    the five constitutional officers -- FIVE offices, where Leon's carries eight
 *    and Manatee's seven. A gate copied from FL-4 that asserts at-large seats on
 *    the countywide district has nothing to assert here.
 *
 * 2. FIVE CONSTITUTIONAL OFFICERS, NOT LEON'S SIX. Palm Beach is a CHARTER county
 *    -- home rule charter effective 1985 -- and still has NO elected
 *    Superintendent of Schools; its school superintendent is appointed by the
 *    School Board. Leon is chartered and elects six. Manatee is non-chartered and
 *    elects five. 🔴 CHARTER STATUS PREDICTS NOTHING. Never inherit the template.
 *
 * 3. 🔴 STATE ATTORNEY AND PUBLIC DEFENDER ARE DELIBERATELY ABSENT. The county's
 *    own Overview of County Government lists SEVEN "constitutional officers",
 *    including both. They are officers of the 15th JUDICIAL CIRCUIT (Fla. Const.
 *    art. V sections 17-18) and look countywide only because that circuit is
 *    coterminous with Palm Beach County -- Leon's 2nd Circuit spans six counties,
 *    which is why FL-4 never met the question. Seating them on 12099/G4020 would
 *    assert that the circuit equals the county: true today, a fact about CIRCUIT
 *    boundaries, and it would make Florida internally inconsistent because Leon's
 *    voters elect a State Attorney too and FL-4 seated neither.
 *    The post-verify asserts all three of Superintendent of Schools, State
 *    Attorney and Public Defender match ZERO offices, so a copy-paste from FL-4
 *    cannot quietly reintroduce Leon's sixth officer.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 FIRST FLORIDA WAVE WITH TWO APPOINTED STARTS AND ZERO UNKNOWN PRECISIONS.
 *
 * FL-2, FL-3 and FL-4 wrote how_started = 'elected' for all 190 people between
 * them, and FL-4 left nine of eighteen at 'unknown' precision. Here: elected 10 /
 * appointed 2, and day 2 / month 9 / year 1 / unknown 0.
 *
 * The undated direct-insert path is therefore NOT exercised by this wave. It is
 * kept anyway, so FL-6 inherits it, and the post-verify asserts zero
 * unknown-precision terms rather than assuming none were written.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE COUNTS COMMENT IN ROSTERS.md IS THE FL-2 GUARD.
 *
 * FL-2 assumed 160 people for 160 offices and found 155. Nothing errored, because
 * ON CONFLICT DO NOTHING absorbs a missing person in silence. So the roster file
 * states its own counts, parseRosters() refuses a file whose table disagrees with
 * them, and every emitted post-verify gate is written from those same numbers.
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROSTER = join(HERE, '..', 'data', 'seed-palm-beach-2026', 'ROSTERS.md');
const MIGRATIONS = join(HERE, '..', 'migrations');

// ── Identity of the jurisdiction ────────────────────────────────────────────

const WAVE = 'FL-5';
const PLAN = 'docs/superpowers/plans/2026-08-28-knight-fl-wave-5-palm-beach-county.md';
const ROSTER_REL = 'data/seed-palm-beach-2026/ROSTERS.md';
const GENERATOR = 'scripts/gen-palm-beach-migrations.mjs';

const OUT_FILE = 'CC_0014_palm_beach_county.sql';

const COUNTY_MTFCC = 'X0039';
const COUNTY_GEO_ID = '12099'; // TIGER county, Palm Beach County (G4020). Pre-existing.
const COUNTY_DIST_PREFIX = 'palm-beach-fl-commissioner-district-';
const COUNTY_GOV = 'Palm Beach County, Florida, US';
const N_COMM_DISTRICTS = 7;
const N_OFFICERS = 5;

/** The shared Florida LOCAL band. FL-3 and FL-4 own -1240056..-1240001. */
const BAND_LO = -1249999;
const BAND_HI = -1240000;

/**
 * 🔴 THIS WAVE'S OWN CONTIGUOUS SUB-RANGE of that shared band.
 *
 * The band guard allowlists ONLY these. Four versions of that guard were wrong;
 * see occupancySql(). Commission n = 61..67, officers n = 71..75.
 */
const OWNED_LO = -1240075;
const OWNED_HI = -1240061;

/**
 * Slug -> (title, chamber, which district it hangs off). The ONLY place the
 * mapping lives, so the migration and the tests cannot drift apart.
 *
 * `on` is 'countywide' (the pre-existing TIGER county district) or 'commdist'
 * (X0039). There is no 'citywide' or 'ward' here -- no city half.
 */
const COUNTY_SEATS = {
  // 🔴 ALL SEVEN ARE SINGLE-MEMBER. Not one is countywide. Leon's
  //    at-large-group-1 / at-large-group-2 have NO equivalent here, and
  //    commissioner-6 / commissioner-7 mean DISTRICT seats in this wave where
  //    Leon's equivalents were at-large.
  'commissioner-1': { title: 'Commissioner, District 1', chamber: 'Board of County Commissioners', on: 'commdist', n: 1 },
  'commissioner-2': { title: 'Commissioner, District 2', chamber: 'Board of County Commissioners', on: 'commdist', n: 2 },
  'commissioner-3': { title: 'Commissioner, District 3', chamber: 'Board of County Commissioners', on: 'commdist', n: 3 },
  'commissioner-4': { title: 'Commissioner, District 4', chamber: 'Board of County Commissioners', on: 'commdist', n: 4 },
  'commissioner-5': { title: 'Commissioner, District 5', chamber: 'Board of County Commissioners', on: 'commdist', n: 5 },
  'commissioner-6': { title: 'Commissioner, District 6', chamber: 'Board of County Commissioners', on: 'commdist', n: 6 },
  'commissioner-7': { title: 'Commissioner, District 7', chamber: 'Board of County Commissioners', on: 'commdist', n: 7 },

  // 🔴 FIVE OFFICERS. No Superintendent of Schools (appointed by the School
  //    Board here, elected in Leon), no State Attorney, no Public Defender.
  'sheriff':                 { title: 'Sheriff', chamber: 'Elected Officials', on: 'countywide' },
  'tax-collector':           { title: 'Tax Collector', chamber: 'Elected Officials', on: 'countywide' },
  'property-appraiser':      { title: 'Property Appraiser', chamber: 'Elected Officials', on: 'countywide' },
  'supervisor-of-elections': { title: 'Supervisor of Elections', chamber: 'Elected Officials', on: 'countywide' },
  // ⚠ AMPERSAND, not "and". Leon's title is spelled out; Palm Beach's office
  //   brands itself with "&". Follow the publisher -- nothing joins on title.
  'clerk-of-circuit-court':  { title: 'Clerk of the Circuit Court & Comptroller', chamber: 'Elected Officials', on: 'countywide' },
};

/**
 * 🔴 TITLES THAT MUST MATCH ZERO OFFICES IN THIS GOVERNMENT.
 *
 * Two are circuit offices the county's own page miscategorises; the third is
 * Leon's sixth officer, and this generator was copied from Leon's. A negative
 * assertion is what stops a copy-paste from reintroducing it.
 */
const FORBIDDEN_TITLES = ['Superintendent of Schools', 'State Attorney', 'Public Defender'];

/**
 * offices.description, keyed by slug.
 *
 * 🔴 THE ONLY DESCRIPTION IN THIS WAVE, and it exists because the seat's
 * OCCUPANCY needs explaining, not because the seat has unusual powers.
 *
 * ⚠ It goes in `description` and NOT in representation_note, because
 * voting_powers is 'full' for all twelve offices and BOTH read paths hide
 * representation_note when voting_powers = 'full'. Same ruling as FL-3 made for
 * Bradenton's mayor.
 *
 * ⚠ Factual and brief. The record must explain why the ELECTED officer is not
 * seated, and nothing more; the criminal allegations are not restated here.
 */
const DESCRIPTIONS = {
  'clerk-of-circuit-court':
    'The elected Clerk, Michael A. Caruso (appointed 2025-08-19), was suspended by the Governor on ' +
    '2026-08-18. He is suspended, not removed: under Fla. Const. art. IV s. 7 the Senate ultimately ' +
    'removes or reinstates. On the same day, the Chief Judge of the 15th Judicial Circuit appointed ' +
    'the Chief Deputy Clerk as Clerk Ad Interim by administrative order, and she holds the office now.',
};

/**
 * alternate_names, keyed by slug. full_name keeps the form the publisher uses,
 * because that is what a voter sees; the alternate carries the form a later
 * dedupe pass or headshot search is likely to hit. The Ben/Benjamin Nadolski rule.
 *
 * ⚠ NOTHING INVENTED. Ramsey-Chessman, Jacks and Sachs get no alternate because
 * their publisher and their ballot name agree, and a guessed variant is a claim
 * about a real person. Sources per row are in ROSTERS.md.
 */
const ALIASES = {
  'commissioner-1': ['Maria Marino'],
  'commissioner-2': ['Gregg Weiss'],
  'commissioner-3': ['Joel Flores'],
  'commissioner-6': ['Sara Marie Baxter'],
  'commissioner-7': ['Bobby Powell'],
  'sheriff': ['Ric Bradshaw'],
  'supervisor-of-elections': ['Wendy Link'],
  'tax-collector': ['Anne Gannon'],
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
 *
 * ⚠ 'Bobby Powell Jr.' has an UNCOMMA'D suffix, unlike FL-3's 'Wells, Jr.'.
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
  const county = parseTable(md, 'Palm Beach County');

  // ⚠ NO city_offices / city_people keys -- this wave has no city half.
  const m = md.match(
    /<!--\s*COUNTS:\s*county_offices=(\d+)\s+county_people=(\d+)\s+vacancies=(\d+)\s*-->/,
  );
  if (!m) throw new Error('ROSTERS.md is missing its COUNTS comment — refusing to generate');
  const counts = {
    countyOffices: Number(m[1]), countyPeople: Number(m[2]), vacancies: Number(m[3]),
  };

  const problems = [];
  const rows = county.map((r) => {
    const def = COUNTY_SEATS[r.slug];
    if (!def) { problems.push(`county: unrecognised slug "${r.slug}"`); return null; }
    const isVacant = r.name === 'VACANT';
    // ⚠ WIDENED AGAIN FOR FL-5. FL-3 tested \((R|D|NPA|I)\) and missed "(DEM)";
    //    FL-4 widened it. Palm Beach's own filing report prints (REP)/(DEM)/(WRI)
    //    and its election feed suffixes contest names with "- REP" / "- DEM".
    if (/\((R|D|DEM|REP|NPA|IND|LPF|GRE|WRI|I)\)|republican|democrat|\s-\s(REP|DEM)\b/i.test(r.name)) {
      problems.push(`county: party marking left in the name "${r.name}" — party lives on races.primary_party`);
    }
    if (!isVacant) {
      if (!VALID_PRECISION.has(r.precision)) problems.push(`county ${r.slug}: precision "${r.precision}" is not one of day/month/year/unknown`);
      if (!VALID_HOW_STARTED.has(r.howStarted)) problems.push(`county ${r.slug}: how_started "${r.howStarted}" is not one the CHECK accepts`);
      if (!r.termStart && r.precision !== 'unknown') problems.push(`county ${r.slug}: no term_start but precision is "${r.precision}" — a missing date must declare precision 'unknown'`);
      if (r.termStart && !/^\d{4}-\d{2}-\d{2}$/.test(r.termStart)) problems.push(`county ${r.slug}: term_start "${r.termStart}" is not YYYY-MM-DD`);
      if (!r.externalId) problems.push(`county ${r.slug}: seated person with no external_id`);
      if (!r.source) problems.push(`county ${r.slug}: no source`);
    }
    return { ...r, ...def, ...splitName(r.name), isVacant, aliases: ALIASES[r.slug] ?? [], description: DESCRIPTIONS[r.slug] ?? '' };
  }).filter(Boolean);

  const ids = rows.map((r) => r.externalId).filter(Boolean);
  const dupIds = ids.filter((x, i) => ids.indexOf(x) !== i);
  if (dupIds.length) problems.push(`duplicate external_id(s): ${[...new Set(dupIds)].join(', ')}`);
  for (const id of ids) {
    const n = Number(id);
    if (!(n >= BAND_LO && n <= BAND_HI)) problems.push(`external_id ${id} is outside the Florida LOCAL band ${BAND_LO}..${BAND_HI}`);
    if (!(n >= OWNED_LO && n <= OWNED_HI)) problems.push(`external_id ${id} is outside THIS WAVE's sub-range ${OWNED_LO}..${OWNED_HI} — FL-3 and FL-4 own -1240056..-1240001`);
  }

  // 🔴 SHAPE ASSERTIONS. A count of 12 is reachable by mapping a commission seat
  //    to 'countywide', which would put that commissioner on every Palm Beach
  //    address. Assert the split, not just the total.
  const comm = rows.filter((r) => r.chamber === 'Board of County Commissioners');
  const officers = rows.filter((r) => r.chamber === 'Elected Officials');
  if (comm.length !== N_COMM_DISTRICTS) problems.push(`expected ${N_COMM_DISTRICTS} commission seats, got ${comm.length}`);
  if (officers.length !== N_OFFICERS) problems.push(`expected ${N_OFFICERS} constitutional officers, got ${officers.length}`);
  if (comm.some((r) => r.on !== 'commdist')) problems.push(`Palm Beach has NO at-large commissioner — every commission seat must be 'commdist': ${comm.filter((r) => r.on !== 'commdist').map((r) => r.slug).join(', ')}`);
  if (officers.some((r) => r.on !== 'countywide')) problems.push(`every constitutional officer must be 'countywide': ${officers.filter((r) => r.on !== 'countywide').map((r) => r.slug).join(', ')}`);
  for (const t of FORBIDDEN_TITLES) {
    if (rows.some((r) => r.title === t)) problems.push(`"${t}" must not be seated in this wave — see the file header`);
  }

  const seated = rows.filter((r) => !r.isVacant).length;
  const vacant = rows.filter((r) => r.isVacant).length;
  if (rows.length !== counts.countyOffices) problems.push(`COUNTS: table has ${rows.length} rows, COUNTS says ${counts.countyOffices}`);
  if (seated !== counts.countyPeople) problems.push(`COUNTS: table has ${seated} people, COUNTS says ${counts.countyPeople}`);
  if (vacant !== counts.vacancies) problems.push(`COUNTS: table marks ${vacant} vacancies, COUNTS says ${counts.vacancies}`);

  if (problems.length) throw new Error(`ROSTERS.md is not usable:\n  - ${problems.join('\n  - ')}`);
  return { county: rows, counts };
}

// ── SQL helpers ─────────────────────────────────────────────────────────────

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const qn = (s) => (s === '' || s === null || s === undefined ? 'NULL' : q(s));

function districtRef(seat) {
  switch (seat.on) {
    case 'countywide': return { geoId: COUNTY_GEO_ID, mtfcc: 'G4020', type: 'COUNTY' };
    case 'commdist':   return { geoId: `${COUNTY_DIST_PREFIX}${seat.n}`, mtfcc: COUNTY_MTFCC, type: 'COUNTY' };
    default: throw new Error(`unknown district anchor "${seat.on}"`);
  }
}

/**
 * 🔴 Every district lookup pairs geo_id WITH mtfcc AND district_type, and Palm
 * Beach is the third county in three waves to need it: 12099 is Palm Beach County
 * (G4020) AND State House District 99 (G5220), after 12081/HD-81 (Manatee) and
 * 12073/HD-73 (Leon). Measured at the county Governmental Center 2026-08-28, an
 * unpaired join returned SIX district rows where three were correct -- Monroe
 * County via HD-87's sldl polygon, HD-24 via SD-24's sldu polygon, and HD-99 via
 * Palm Beach County's own G4020 polygon. Nothing errored.
 */
function districtLookupSql(seat, alias = 'dd') {
  const r = districtRef(seat);
  return `SELECT ${alias}.id FROM essentials.districts ${alias}
   WHERE ${alias}.geo_id = ${q(r.geoId)} AND ${alias}.mtfcc = ${q(r.mtfcc)}
     AND ${alias}.district_type = ${q(r.type)} AND lower(${alias}.state) = 'fl'`;
}

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

/**
 * ⚠ PARAMETERISED, AND FL-4's WAS NOT.
 *
 * FL-4 copied FL-3's generator and never re-pointed this template, so all three
 * of CC_0011, CC_0012 and CC_0013 were APPLIED to prod carrying "wave FL-3",
 * FL-3's plan path, FL-3's roster path and FL-3's generator name in their
 * headers. Comment-only, but it points a reader at the wrong plan. Every
 * jurisdiction-specific string here comes from a constant.
 */
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
-- 🔴 EVERY DISTRICT LOOKUP PAIRS geo_id WITH mtfcc AND district_type.
-- ${COUNTY_GEO_ID} is Palm Beach County (G4020) AND State House District 99
-- (G5220) -- the third instance in three waves, after 12081/HD-81 and
-- 12073/HD-73. Measured at the county Governmental Center 2026-08-28, an
-- unpaired join returned SIX district rows of which three were wrong, including
-- Monroe County (200 miles away) and two representatives from other counties.
-- Nothing errored.
--
-- ---------------------------------------------------------------------------
-- No party affiliation is recorded. The Supervisor of Elections' filing report
-- prints (DEM)/(REP)/(WRI) beside every name; it is discarded. Party lives on
-- races.primary_party.
--
-- No term_end is written. A future term_end makes a seat silently self-vacate,
-- and office_terms has no end_precision, so a published expiry YEAR cannot
-- become a term_end without inventing a day.
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

function occupancySql(rows, tmp, label, ownedIds) {
  const seated = rows.filter((r) => !r.isVacant);
  const owned = ownedIds.join(', ');
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
-- FOUR versions of this guard were wrong before this one:
--   1. "the band holds exactly N rows before this runs" -- NOT IDEMPOTENT: a
--      re-run of an applied migration counts its own rows and refuses. Measured.
--   2. The same count, in the post-verify -- gave the county migration a false
--      ORDERING DEPENDENCY on the city one.
--   3. "the whole band holds nothing this wave owns" -- correct within one wave,
--      but -(1240000 + n) is the SHARED Florida LOCAL band, so FL-4 saw FL-3's
--      seventeen legitimate rows as foreign and refused. It would also have
--      broken FL-3's OWN re-run once FL-4 applied. Measured 2026-08-28.
--   4. The fix, used here: assert that nothing inside [min..max] of THIS wave's
--      ids is owned by anything else. FL-3 owns -1240025..-1240001 and FL-4 owns
--      -1240056..-1240031; both keep re-running clean.
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
-- 2026-08-28: exactly ONE of this wave's twelve names matches an existing
-- politician -- and it is MACK BERNARD, who is NOT on this roster. He was the
-- District 7 commissioner and is now State Senator SD-24, seated by FL-2 as
-- -1230024. Bobby Powell Jr., who now holds District 7, was the SD-24 senator and
-- is a fresh insert. They traded seats.
--
-- ⚠ THE STALE County_Commission_Districts GIS LAYER STILL NAMES "MACK BERNARD"
-- FOR DISTRICT 7. A name-based reuse step reading that layer would seat a sitting
-- state senator on the county commission, and office_terms would accept it. A
-- name-based guard is what seated a Wisconsin village trustee on the Nashville
-- council. Never read a roster out of a boundary layer.

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

  SELECT count(*) INTO v_n FROM ${tmp} WHERE ext_id NOT BETWEEN ${ownedLo} AND ${ownedHi};
  IF v_n <> 0 THEN RAISE EXCEPTION '${label} payload: % external_id(s) outside this wave''s sub-range', v_n; END IF;

  -- Every (geo_id, mtfcc, district_type, title) is a single seat in this wave.
  SELECT count(*) INTO v_dup FROM (
    SELECT geo_id, mtfcc, district_type, office_title FROM ${tmp}
    GROUP BY geo_id, mtfcc, district_type, office_title HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION '${label} payload: % duplicate seat key(s)', v_dup; END IF;

  -- A row with no term_start MUST declare 'unknown'. This wave has NONE -- every
  -- one of the twelve is dated -- but the guard stays: it is what makes the
  -- direct-insert path below safe if a later re-seat introduces one.
  SELECT count(*) INTO v_n FROM ${tmp} WHERE term_start IS NULL AND start_precision <> 'unknown';
  IF v_n <> 0 THEN RAISE EXCEPTION '${label} payload: % row(s) have no term_start but claim a precision', v_n; END IF;

  -- 🔴 SEVEN ROWS MUST BE ON X0039 AND FIVE ON THE COUNTYWIDE DISTRICT. A total of
  -- twelve is reachable by mapping a commissioner countywide, which would put that
  -- one person on EVERY Palm Beach address and still pass a total-only gate.
  SELECT count(*) INTO v_n FROM ${tmp} WHERE mtfcc = '${COUNTY_MTFCC}';
  IF v_n <> ${N_COMM_DISTRICTS} THEN RAISE EXCEPTION '${label} payload: expected ${N_COMM_DISTRICTS} rows on ${COUNTY_MTFCC}, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM ${tmp} WHERE geo_id = '${COUNTY_GEO_ID}' AND mtfcc = 'G4020';
  IF v_n <> ${N_OFFICERS} THEN RAISE EXCEPTION '${label} payload: expected ${N_OFFICERS} countywide rows, got %', v_n; END IF;

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
-- 2026-08-28. Prod nonetheless holds 81,676 'unknown'-precision office_terms rows
-- with a NULL start, written by the ADR 0002 phase-2 backfill by direct insert --
-- so "open-ended term" in CLAUDE.md means term_end IS NULL, not an unbounded
-- start. Only the HELPER refuses it.
--
-- ⚠ THIS WAVE EXERCISES ONLY THE FIRST PATH. All twelve people are dated, so the
-- direct-insert branch never fires. It is kept so FL-6 inherits it, and the
-- post-verify asserts ZERO unknown-precision terms rather than assuming none.
--
-- The undated branch inserts ONLY into an office with zero existing term rows.
-- That condition is what makes bypassing the helper safe: the helper's two-step
-- exists to close a predecessor before an open-ended range overlaps it, and with
-- no predecessor there is nothing to close and the exclusion constraint cannot
-- fire. The guard refuses rather than guesses if that stops being true.
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

// ── The migration: Palm Beach County, offices AND people ────────────────────

function renderCounty(county, counts) {
  const countyIds = county.map((r) => r.externalId).filter(Boolean).join(', ');
  const commSeats = county.filter((s) => s.on === 'commdist');
  const nAppointed = county.filter((r) => !r.isVacant && r.howStarted === 'appointed').length;
  const nDay = county.filter((r) => !r.isVacant && r.precision === 'day').length;
  const nMonth = county.filter((r) => !r.isVacant && r.precision === 'month').length;
  const nYear = county.filter((r) => !r.isVacant && r.precision === 'year').length;
  const nUnknown = county.filter((r) => !r.isVacant && r.precision === 'unknown').length;
  const appointedSlugTitles = county
    .filter((r) => r.howStarted === 'appointed')
    .map((r) => q(r.title)).join(', ');
  const parts = [];

  parts.push(HEADER(
    OUT_FILE,
    null,
    `Creates Palm Beach County whole -- offices AND people in ONE migration, per spec section 3:\n` +
    `--   * ${N_COMM_DISTRICTS} new COUNTY districts (mtfcc ${COUNTY_MTFCC}); the countywide district ALREADY EXISTS\n` +
    `--   * 1 government, 2 chambers\n` +
    `--   * ${counts.countyOffices} offices -- ${N_COMM_DISTRICTS} single-member commissioners + ${N_OFFICERS} constitutional officers\n` +
    `--   * ${counts.countyPeople} politicians and ${counts.countyPeople} terms; NO vacancies\n` +
    `--\n` +
    `-- ⚠ THERE IS NO CITY HALF. This is the whole wave -- no companion migration.`,
  ));

  parts.push(`
-- ---------------------------------------------------------------------------
-- 🔴 SEVEN SINGLE-MEMBER DISTRICTS AND NO AT-LARGE COMMISSIONER.
--
-- The county's own page: "One commissioner residing in each of seven districts
-- shall be elected by the qualified electors residing within that district."
--
-- ⚠ MANATEE HAS 5 + 2 ("District 6"/"District 7") AND LEON HAS 5 + 2
-- ("At Large, Group 1"/"Group 2"). PALM BEACH HAS 7 + 0. So the PRE-EXISTING
-- countywide district for TIGER county ${COUNTY_GEO_ID} carries ONLY the ${N_OFFICERS} constitutional
-- officers -- FIVE offices, where Leon's carries eight and Manatee's seven.
--
-- 🔴 The gates below assert the 7/5 SPLIT, not just the total of ${counts.countyOffices}. A commission
-- seat mis-mapped to the countywide district would still total ${counts.countyOffices}, would pass a
-- total-only gate, and would put that one commissioner on EVERY Palm Beach address.
--
-- ---------------------------------------------------------------------------
-- 🔴 FIVE CONSTITUTIONAL OFFICERS, NOT LEON'S SIX -- AND PALM BEACH IS ALSO A
-- CHARTER COUNTY (home rule charter effective 1985).
--
-- It has NO elected Superintendent of Schools; its school superintendent is
-- APPOINTED by the School Board. Leon, chartered, elects six including that
-- office. Manatee, non-chartered, elects five. 🔴 CHARTER STATUS PREDICTS NOTHING.
--
-- 🔴 THE COUNTY'S OWN PAGE LISTS SEVEN "CONSTITUTIONAL OFFICERS", including the
-- STATE ATTORNEY and the PUBLIC DEFENDER. Those are officers of the 15th JUDICIAL
-- CIRCUIT (Fla. Const. art. V ss. 17-18) and look countywide only because that
-- circuit is coterminous with Palm Beach County. Leon's 2nd Circuit spans SIX
-- counties, which is why FL-4 never met the question. They are NOT seated here:
-- doing so would assert that the circuit equals the county, and would leave
-- Florida internally inconsistent because Leon's voters elect a State Attorney
-- too and FL-4 seated neither.
--
-- The post-verify asserts ZERO offices titled 'Superintendent of Schools',
-- 'State Attorney' or 'Public Defender'. This generator was copied from Leon's,
-- where the Superintendent is a live entry, so the negative assertion is what
-- stops a copy-paste from reintroducing it.
--
-- ⚠ The school BOARD stays out of scope, as Manatee's and Leon's did.
--
-- ---------------------------------------------------------------------------
-- ⚠ MAYOR AND VICE MAYOR ARE NOT OFFICES. The Board elects them annually from
-- among its own members: "The BCC elects a mayor to preside over commission
-- meetings and serve as the ceremonial head... A vice mayor is also selected."
-- Sara Baxter (D6) is Mayor and Marci Woodward (D4) Vice Mayor as of 2026-08-28,
-- and Commissioner Marino's own bio records the rotation -- she "served as Mayor
-- of Palm Beach County from November 2024 to November 2025". Same ruling as
-- Bradenton's and Asheville's Vice Mayor, opposite of Nashville's.
--
-- ---------------------------------------------------------------------------
-- ⚠ NO VACANCY IN THIS WAVE, so nothing is flagged is_vacant -- which means every
-- one of the ${counts.countyOffices} offices MUST end with a term row. The reachability baseline holds
-- no fl| bucket in any check, so a single office with neither a term row nor a
-- flag creates a NEW fl|COUNTY DEAD_GEOGRAPHY bucket and fails CI.
--
-- ---------------------------------------------------------------------------
-- 🔴 TWO APPOINTMENTS AND ZERO UNKNOWN PRECISIONS -- BOTH FIRSTS FOR FLORIDA.
--
-- FL-2, FL-3 and FL-4 wrote how_started = 'elected' for all 190 people between
-- them; FL-4 left nine of eighteen at 'unknown' precision. Here: elected ${counts.countyPeople - nAppointed} /
-- appointed ${nAppointed}, and day ${nDay} / month ${nMonth} / year ${nYear} / unknown ${nUnknown}.
--
--   Supervisor of Elections  first APPOINTED in 2019, then elected 2020 and 2024.
--                            'year' precision: no month is published, and a month
--                            derived from the news cycle would be invented.
--   Clerk Ad Interim         appointed 2026-08-18 by administrative order of the
--                            Chief Judge of the 15th Judicial Circuit, after the
--                            Governor SUSPENDED the elected Clerk the same day.
--                            Suspended, NOT removed. See offices.description.
--
-- ⚠ The elected Clerk's own closed term is deliberately NOT written, though every
-- date for it is known. FL-2 wrote no predecessor terms for its five legislative
-- vacancies and FL-3 wrote none for Carol Ann Felts; writing one here would leave
-- Florida internally inconsistent, and how_ended offers only 'removed' for
-- someone who was suspended. Open item: write predecessor terms for all Florida
-- vacancies and interruptions together.
--
-- ---------------------------------------------------------------------------
-- 🔴 THE SEVEN SEATS STAGGER ODD / EVEN, and it is why the term_start years do.
--   Districts 1, 3, 5, 7  presidential years -- 2020, 2024
--   Districts 2, 4, 6     gubernatorial years -- 2018, 2022, 2026
-- Confirmed against the Supervisor of Elections' candidate filing report for the
-- 2022, 2024 and 2026 cycles. All five constitutional officers were on the 2024
-- ballot and are next up in 2028.
--
-- Take-office rules: commissioners are "sworn into office two weeks after being
-- elected in the November general election"; the five officers take office on the
-- 1st Tuesday after the 1st Monday in January. The commissioners' months come
-- from the filing report plus the first rule and are stored at 'month' precision
-- -- the county publishes no per-person swearing-in date, and a mis-stated rule
-- would produce a confidently wrong day.

BEGIN;

-- --- 0. Pre-flight ----------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = '${COUNTY_MTFCC}';
  IF v_n <> ${N_COMM_DISTRICTS} THEN
    RAISE EXCEPTION 'palm beach county: expected ${N_COMM_DISTRICTS} ${COUNTY_MTFCC} boundaries, found % -- run scripts/load-palm-beach-commission-boundaries.ts first', v_n;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '${COUNTY_GEO_ID}' AND mtfcc = 'G4020'
  ) THEN
    RAISE EXCEPTION 'palm beach county: TIGER county ${COUNTY_GEO_ID}/G4020 is missing';
  END IF;

  -- The countywide district must ALREADY exist. This migration must not create a
  -- second one: ${N_OFFICERS} of its ${counts.countyOffices} offices hang off it.
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = '${COUNTY_GEO_ID}' AND mtfcc = 'G4020' AND district_type = 'COUNTY' AND lower(state) = 'fl';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'palm beach county: expected exactly 1 pre-existing COUNTY district for ${COUNTY_GEO_ID}, found %', v_n;
  END IF;
END $$;

-- --- 1. The seven single-member commission districts -----------------------
`);

  for (const s of commSeats) {
    parts.push(`INSERT INTO essentials.districts (district_type, label, state, geo_id, mtfcc, num_officials)
SELECT 'COUNTY', 'Palm Beach County Commissioner District ${s.n}', 'fl', '${COUNTY_DIST_PREFIX}${s.n}', '${COUNTY_MTFCC}', 1
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
SELECT g.id, 'Board of County Commissioners', 'Palm Beach County Board of County Commissioners', ${N_COMM_DISTRICTS}, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${COUNTY_GEO_ID}' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
     WHERE c.government_id = g.id AND c.name = 'Board of County Commissioners'
  );

-- ⚠ FIVE, not Leon's six.
INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Elected Officials', 'Palm Beach County Elected Officials', ${N_OFFICERS}, 'full'
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
  IF v_n <> ${N_COMM_DISTRICTS} THEN RAISE EXCEPTION 'palm beach county: expected ${N_COMM_DISTRICTS} ${COUNTY_MTFCC} districts, got %', v_n; END IF;

  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '${COUNTY_GEO_ID}' AND type = 'County';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'palm beach county: the government row is missing'; END IF;

  SELECT count(*) INTO v_n FROM essentials.chambers WHERE government_id = v_gov;
  IF v_n <> 2 THEN RAISE EXCEPTION 'palm beach county: expected 2 chambers, got %', v_n; END IF;

  -- 🔴 FIVE, NOT LEON'S SIX. Palm Beach is chartered and still elects no
  -- Superintendent of Schools.
  SELECT count(*) INTO v_n FROM essentials.chambers
   WHERE government_id = v_gov AND ((name = 'Board of County Commissioners' AND official_count = ${N_COMM_DISTRICTS})
                                 OR (name = 'Elected Officials' AND official_count = ${N_OFFICERS}));
  IF v_n <> 2 THEN RAISE EXCEPTION 'palm beach county: chamber names or official_counts are wrong -- Elected Officials must be ${N_OFFICERS}, not Leon''s 6'; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_n <> ${counts.countyOffices} THEN RAISE EXCEPTION 'palm beach county: expected ${counts.countyOffices} offices, got %', v_n; END IF;

  -- PER CHAMBER, not just in total.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Board of County Commissioners';
  IF v_n <> ${N_COMM_DISTRICTS} THEN RAISE EXCEPTION 'palm beach county: expected ${N_COMM_DISTRICTS} commissioner offices, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Elected Officials';
  IF v_n <> ${N_OFFICERS} THEN RAISE EXCEPTION 'palm beach county: expected ${N_OFFICERS} constitutional officer offices, got %', v_n; END IF;

  -- 🔴 THE FIVE OFFICERS BY TITLE. A count of ${N_OFFICERS} is reachable by duplicating one.
  FOR v_t IN SELECT unnest(ARRAY['Sheriff','Tax Collector','Property Appraiser','Supervisor of Elections','Clerk of the Circuit Court & Comptroller']) LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = v_gov AND o.title = v_t;
    IF v_n <> 1 THEN RAISE EXCEPTION 'palm beach county: expected exactly 1 office titled %, got %', v_t, v_n; END IF;
  END LOOP;

  -- 🔴 AND THE THREE THAT MUST NOT EXIST. Superintendent of Schools is Leon's
  -- sixth officer and this generator was copied from Leon's; State Attorney and
  -- Public Defender are 15th Judicial Circuit offices the county's own page
  -- miscategorises as county constitutional officers.
  FOR v_t IN SELECT unnest(ARRAY[${FORBIDDEN_TITLES.map(q).join(', ')}]) LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = v_gov AND o.title = v_t;
    IF v_n <> 0 THEN RAISE EXCEPTION 'palm beach county: % must NOT be seated in this wave, found % office(s) -- see the file header', v_t, v_n; END IF;
  END LOOP;

  -- PER DISTRICT: exactly one commissioner on each of the seven.
  FOR v_d IN SELECT '${COUNTY_DIST_PREFIX}' || g FROM generate_series(1,${N_COMM_DISTRICTS}) g LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = v_d AND d.mtfcc = '${COUNTY_MTFCC}' AND d.district_type = 'COUNTY';
    IF v_n <> 1 THEN RAISE EXCEPTION 'palm beach county: commission district % carries % offices, expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- 🔴 ...AND EXACTLY ${N_OFFICERS} ON THE COUNTYWIDE DISTRICT -- the officers, and NOTHING
  -- else. Leon's equivalent expects 8 (2 at-large + 6 officers) and Manatee's 7.
  -- If this reads ${N_OFFICERS + 1} a commission seat was mapped 'countywide', and that
  -- commissioner now appears for every address in the county.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND d.geo_id = '${COUNTY_GEO_ID}'
     AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY';
  IF v_n <> ${N_OFFICERS} THEN RAISE EXCEPTION 'palm beach county: expected ${N_OFFICERS} offices on the countywide district (the officers, no at-large commissioner), got %', v_n; END IF;

  -- ⚠ AND NO COMMISSIONER MAY BE AMONG THEM, stated directly rather than inferred
  -- from the count.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Board of County Commissioners'
     AND d.geo_id = '${COUNTY_GEO_ID}' AND d.mtfcc = 'G4020';
  IF v_n <> 0 THEN RAISE EXCEPTION 'palm beach county: % commissioner office(s) landed on the countywide district -- Palm Beach has no at-large seat', v_n; END IF;

  -- The Clerk's description must be present: it is the only record of why the
  -- ELECTED Clerk is not the seated holder.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.title = 'Clerk of the Circuit Court & Comptroller'
     AND o.description IS NOT NULL AND o.description <> '';
  IF v_n <> 1 THEN RAISE EXCEPTION 'palm beach county: the Clerk office has no description -- the suspension and interim appointment must be recorded'; END IF;

  -- 🔴 No office may have landed on a Palm Beach County in ANOTHER state, and none
  -- may sit on a district with no boundary.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov AND lower(d.state) <> 'fl';
  IF v_n <> 0 THEN RAISE EXCEPTION 'palm beach county: % office(s) landed outside Florida', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_n <> 0 THEN RAISE EXCEPTION 'palm beach county: % office(s) sit on a district with no matching boundary', v_n; END IF;

  RAISE NOTICE 'palm beach county structure OK: ${N_COMM_DISTRICTS} new districts, 1 government, 2 chambers, ${counts.countyOffices} offices (${N_COMM_DISTRICTS} district + ${N_OFFICERS} countywide)';
END $$;
${occupancySql(county, 'palm_beach_seed', 'palm beach county', ALL_OWNED_IDS)}
-- --- 6. Occupancy post-verify gate ----------------------------------------
DO $$
DECLARE v_gov uuid; v_pol int; v_seated int; v_n int; v_d text; v_t text;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments WHERE geo_id = '${COUNTY_GEO_ID}' AND type = 'County';

  -- ⚠ THIS MIGRATION'S OWN IDS, not the band: a band count is non-idempotent.
  SELECT count(*) INTO v_pol FROM essentials.politicians
   WHERE external_id IN (${countyIds});
  IF v_pol <> ${counts.countyPeople} THEN
    RAISE EXCEPTION 'palm beach county: expected ${counts.countyPeople} of this wave''s politicians, got %', v_pol;
  END IF;

  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov;
  IF v_seated <> ${counts.countyPeople} THEN RAISE EXCEPTION 'palm beach county: expected ${counts.countyPeople} seated officials, found %', v_seated; END IF;

  -- 🔴 NO VACANCY. Every office must carry a term row. Manatee's equivalent gate
  -- expects exactly 1 vacancy; Leon's and this one expect 0.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.is_vacant = true;
  IF v_n <> 0 THEN RAISE EXCEPTION 'palm beach county: % office(s) flagged vacant, expected 0', v_n; END IF;

  -- One seated commissioner per single-member district -- ALL SEVEN.
  FOR v_d IN SELECT '${COUNTY_DIST_PREFIX}' || g FROM generate_series(1,${N_COMM_DISTRICTS}) g LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id = v_d AND d.mtfcc = '${COUNTY_MTFCC}' AND d.district_type = 'COUNTY';
    IF v_n <> 1 THEN RAISE EXCEPTION 'palm beach county: commission district % has % seated member(s), expected 1', v_d, v_n; END IF;
  END LOOP;

  -- All ${N_OFFICERS} countywide seats filled: the officers, and no at-large commissioner.
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov AND d.geo_id = '${COUNTY_GEO_ID}'
     AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY';
  IF v_n <> ${N_OFFICERS} THEN RAISE EXCEPTION 'palm beach county: expected ${N_OFFICERS} seated countywide officials, got %', v_n; END IF;

  -- 🔴 ZERO UNKNOWN-PRECISION TERMS -- the first Florida wave that can assert this.
  -- FL-4 wrote nine. If a later re-seat drops a date, this is where it shows up.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND (t.start_precision = 'unknown' OR t.term_start IS NULL);
  IF v_n <> ${nUnknown} THEN RAISE EXCEPTION 'palm beach county: expected ${nUnknown} unknown-precision or undated terms, got %', v_n; END IF;

  -- The precision histogram, per bucket. Measured from ROSTERS.md:
  -- day ${nDay} / month ${nMonth} / year ${nYear} / unknown ${nUnknown}.
  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.start_precision = 'day';
  IF v_n <> ${nDay} THEN RAISE EXCEPTION 'palm beach county: expected ${nDay} day-precision terms, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.start_precision = 'year';
  IF v_n <> ${nYear} THEN RAISE EXCEPTION 'palm beach county: expected ${nYear} year-precision term(s), got %', v_n; END IF;

  -- All ${N_COMM_DISTRICTS} commissioners dated at month precision, in November -- the
  -- take-office rule is two weeks after the November general.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name = 'Board of County Commissioners'
     AND t.start_precision = 'month' AND extract(month FROM t.term_start) = 11;
  IF v_n <> ${N_COMM_DISTRICTS} THEN RAISE EXCEPTION 'palm beach county: expected ${N_COMM_DISTRICTS} month-precision November commissioner terms, got %', v_n; END IF;

  -- 🔴 ${nAppointed} APPOINTMENTS, AND THE RIGHT TWO. A count alone would pass if an elected
  -- officer were mislabelled, so assert the titles.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND t.how_started = 'appointed';
  IF v_n <> ${nAppointed} THEN RAISE EXCEPTION 'palm beach county: expected ${nAppointed} appointed terms, got %', v_n; END IF;

  FOR v_t IN SELECT unnest(ARRAY[${appointedSlugTitles}]) LOOP
    SELECT count(*) INTO v_n
      FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = v_gov AND o.title = v_t AND t.how_started = 'appointed';
    IF v_n <> 1 THEN RAISE EXCEPTION 'palm beach county: % should carry an appointed term, got %', v_t, v_n; END IF;
  END LOOP;

  -- No office with neither a term row nor a vacancy flag.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_terms t ON t.office_id = o.id
   WHERE c.government_id = v_gov AND t.id IS NULL AND o.is_vacant = false;
  IF v_n <> 0 THEN RAISE EXCEPTION 'palm beach county: % office(s) have no term row and no vacancy flag', v_n; END IF;

  RAISE NOTICE 'palm beach county OK: ${counts.countyOffices} offices, ${counts.countyPeople} seated, 0 vacant, ${nAppointed} appointed, ${nUnknown} unknown-precision';
END $$;

COMMIT;
`);
  return parts.join('\n');
}

// ── Main ────────────────────────────────────────────────────────────────────

function main() {
  const md = readFileSync(ROSTER, 'utf8');
  const { county, counts } = parseRosters(md);

  ALL_OWNED_IDS = county
    .map((r) => r.externalId).filter(Boolean)
    .map(Number).sort((a, b) => a - b);

  const body = renderCounty(county, counts);
  writeFileSync(join(MIGRATIONS, OUT_FILE), body.replace(/\n{3,}/g, '\n\n'));
  console.log(`wrote migrations/${OUT_FILE}  (${body.split('\n').length} lines)`);
  console.log(
    `\n${counts.countyOffices} offices / ${counts.countyPeople} people / ${counts.vacancies} vacancy. ` +
    `ONE migration -- Palm Beach County has no city half.`,
  );
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) main();
