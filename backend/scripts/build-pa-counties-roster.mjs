#!/usr/bin/env node
/**
 * build-pa-counties-roster.mjs — Knight program, wave PA-4 (stage 4, the county half).
 *
 * Writes data/pa-counties-roster.json. Reads nothing from the database and writes nothing to it.
 *
 * TWO JURISDICTIONS THAT DO NOT ELECT THE SAME OFFICES, AND NEITHER MATCHES A STATE TEMPLATE —
 * MN-4's rule, which this wave confirms twice over:
 *
 *   Philadelphia — consolidated, so there is NO county commission: the City Council already is
 *   it. What survives is the separately elected ROW OFFICES (spec §3.2): District Attorney, City
 *   Controller, Sheriff, Register of Wills and THREE City Commissioners. Seven seats.
 *
 *   Centre County — an ordinary Pennsylvania county, and its own page lists offices a template
 *   would not predict:
 *     · a CONTROLLER rather than three Auditors (PA counties elect one or the other);
 *     · a combined PROTHONOTARY & CLERK OF COURTS, and a combined REGISTER OF WILLS & CLERK OF
 *       THE ORPHANS' COURT — two offices where a template would write four;
 *     · 🔴 TWO JURY COMMISSIONERS. Act 2013-11 let counties abolish the office and many did.
 *       Centre did not. Nothing but the county's own page would have told us.
 *   Three commissioners plus ten others: thirteen seats.
 *
 * 🔴 JUDGES ARE ELECTED HERE AND ARE STILL NOT IN THIS WAVE. Centre County's page also lists
 * Court of Common Pleas judges and six Magisterial District Judges, and Philadelphia elects its
 * judiciary too. Under the NC-3 inclusion ruling (an office is seated if the voters of that
 * jurisdiction elect it) they belong in the data — in the JUDGES WAVE, which North Carolina
 * already owes. Excluding them here is a scheduling decision, recorded, not a judgement that
 * they do not count.
 *
 * Every name below was read off the office's OWN page, and --verify re-reads each of those pages
 * and asserts that it still names that person. A name in this file with no live page naming them
 * is a finding, not a row.
 *
 *   node scripts/build-pa-counties-roster.mjs --verify
 *   node scripts/build-pa-counties-roster.mjs --self-test
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, '..', 'data', 'pa-counties-roster.json');
const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };

const CENTRE_PAGE = 'https://centrecountypa.gov/2007/Elected-OfficialsOffices';
const PHL_COMMISSIONERS = 'https://vote.phila.gov/about-us/commissioners/';

/** Philadelphia's seven row offices. One source page each, and they are not all the same site. */
const PHILADELPHIA = [
  { title: 'District Attorney', full_name: 'Larry Krasner', source: 'https://phillyda.org/' },
  { title: 'City Controller', full_name: 'Christy Brady', source: 'https://controller.phila.gov/' },
  { title: 'Sheriff', full_name: 'Rochelle Bilal', source: 'https://www.phillysheriff.com/' },
  { title: 'Register of Wills', full_name: 'John P. Sabatina', source: 'https://www.phila.gov/departments/register-of-wills/' },
  { title: 'City Commissioner', full_name: 'Omar Sabir', source: PHL_COMMISSIONERS },
  { title: 'City Commissioner', full_name: 'Lisa M. Deeley', source: PHL_COMMISSIONERS },
  { title: 'City Commissioner', full_name: 'Seth Bluestein', source: PHL_COMMISSIONERS },
];

/** Centre County's thirteen non-judicial elected offices, all from the county's own index. */
const CENTRE = [
  { title: 'County Commissioner', full_name: 'Mark Higgins', source: CENTRE_PAGE },
  { title: 'County Commissioner', full_name: 'Amber Concepcion', source: CENTRE_PAGE },
  { title: 'County Commissioner', full_name: 'Steven G. Dershem', source: CENTRE_PAGE },
  { title: 'Controller', full_name: 'Jason Moser', source: CENTRE_PAGE },
  { title: 'Coroner', full_name: 'Scott A. Sayers', source: CENTRE_PAGE },
  { title: 'District Attorney', full_name: 'Bernie Cantorna', source: CENTRE_PAGE },
  { title: 'Jury Commissioner', full_name: 'Hope P. Miller', source: CENTRE_PAGE },
  { title: 'Jury Commissioner', full_name: 'Shelley Thompson', source: CENTRE_PAGE },
  { title: 'Prothonotary and Clerk of Courts', full_name: 'Jeremy S. Breon', source: CENTRE_PAGE },
  { title: 'Recorder of Deeds', full_name: 'Joseph L. Davidson', source: CENTRE_PAGE },
  { title: "Register of Wills and Clerk of the Orphans' Court", full_name: 'Christine Millinder', source: CENTRE_PAGE },
  { title: 'Sheriff', full_name: 'Bryan Sampsel', source: CENTRE_PAGE },
  { title: 'Treasurer', full_name: 'Colleen Kennedy', source: CENTRE_PAGE },
];

const norm = (s) => String(s).toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
  .replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();

const strip = (html) => String(html)
  .replace(/<script[\s\S]*?<\/script>/g, ' ')
  .replace(/<style[\s\S]*?<\/style>/g, ' ')
  .replace(/<[^>]+>/g, ' ')
  .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
  .replace(/&nbsp;?/g, ' ')
  .replace(/\s+/g, ' ');

async function getText(url, tries = 3) {
  for (let i = 0; i < tries; i++) {
    try {
      const r = await fetch(url, { headers: UA });
      // 🔴 READ THE STATUS, NOT THE LENGTH. Both of these publishers serve a full-size, fully
      // styled page on a 404 — centrecountypa.gov returns 83 KB of chrome for a path that does
      // not exist, and phila.gov's 404 carries the phrase "Mayor Cherelle L. Parker".
      if (r.status !== 200) throw new Error(`HTTP ${r.status}`);
      return await r.text();
    } catch (e) {
      if (i === tries - 1) throw new Error(`${url}: ${e.message}`, { cause: e });
      await new Promise((res) => setTimeout(res, 500 * (i + 1)));
    }
  }
}

/**
 * 🔴 A NAME MUST BE FOUND AS A WHOLE, NOT AS TWO WORDS SOMEWHERE ON A PAGE. The check is a
 * substring of the normalised text, so "Mark Higgins" matches only where those two words are
 * adjacent — and the self-test proves it rejects a person the page does not carry.
 */
export function pageNames(text, fullName) {
  return norm(text).includes(norm(fullName));
}

/** Counts the wave asserts, each from a reading of the body's own publication. */
export const EXPECTED = {
  philadelphia: { total: 7, city_commissioners: 3 },
  centre: { total: 13, commissioners: 3, others: 10 },
};

export function rosterFindings(phl, centre) {
  const f = [];
  if (phl.length !== EXPECTED.philadelphia.total) f.push(`PHL_ROW_OFFICE_COUNT ${phl.length}, expected ${EXPECTED.philadelphia.total}`);
  const comms = phl.filter((o) => o.title === 'City Commissioner').length;
  if (comms !== EXPECTED.philadelphia.city_commissioners) f.push(`PHL_CITY_COMMISSIONER_COUNT ${comms}, expected 3`);
  if (centre.length !== EXPECTED.centre.total) f.push(`CENTRE_OFFICE_COUNT ${centre.length}, expected ${EXPECTED.centre.total}`);
  const cc = centre.filter((o) => o.title === 'County Commissioner').length;
  if (cc !== EXPECTED.centre.commissioners) f.push(`CENTRE_COMMISSIONER_COUNT ${cc}, expected 3`);
  const jury = centre.filter((o) => o.title === 'Jury Commissioner').length;
  if (jury !== 2) f.push(`CENTRE_JURY_COMMISSIONER_COUNT ${jury}, expected 2 — Centre is a county that did NOT abolish the office`);
  for (const o of [...phl, ...centre]) {
    if (/&[a-zA-Z#0-9]+;/.test(o.full_name)) f.push(`UNDECODED_ENTITY ${o.full_name}`);
    if (!/^[A-Z]/.test(o.full_name)) f.push(`SUSPECT_NAME ${o.full_name}`);
  }
  const names = new Set();
  for (const o of [...phl, ...centre]) {
    const k = `${o.title}|${norm(o.full_name)}`;
    if (names.has(k)) f.push(`DUPLICATE_ROW ${o.title} ${o.full_name}`);
    names.add(k);
  }
  return f;
}

function selfTest() {
  let ok = true;
  const say = (p, w) => { if (!p) ok = false; console.log(`  ${p ? 'PASS' : '🔴 FAIL'}  ${w}`); };
  say(rosterFindings(PHILADELPHIA, CENTRE).length === 0, 'the real roster raises no finding');
  say(rosterFindings(PHILADELPHIA.slice(0, 6), CENTRE).some((x) => x.startsWith('PHL_ROW_OFFICE_COUNT 6')), 'a missing row office is reported');
  say(rosterFindings(PHILADELPHIA, CENTRE.slice(0, 12)).some((x) => x.startsWith('CENTRE_OFFICE_COUNT 12')), 'a missing county office is reported');
  say(rosterFindings(PHILADELPHIA, CENTRE.filter((o) => o.title !== 'Jury Commissioner')).some((x) => x.startsWith('CENTRE_JURY_COMMISSIONER_COUNT 0')),
      'dropping the jury commissioners — the office a template would omit — is reported');
  say(rosterFindings(PHILADELPHIA, CENTRE.concat([CENTRE[0]])).some((x) => x.startsWith('DUPLICATE_ROW')), 'a duplicated row is reported');
  say(pageNames('Commissioner Mark Higgins, Chair', 'Mark Higgins'), 'a name the page carries is found');
  say(!pageNames('Commissioner Mark Higgins, Chair', 'Amber Concepcion'), 'a name the page does NOT carry is rejected');
  say(!pageNames('Higgins was elected. Mark returned.', 'Mark Higgins'), 'two words that are not adjacent do NOT count as the name');
  return ok;
}

const argv = process.argv.slice(2);
if (argv.includes('--self-test')) {
  console.log('self-test — each detector must report the defect planted for it:');
  process.exit(selfTest() ? 0 : 1);
}

const findings = rosterFindings(PHILADELPHIA, CENTRE);
console.log(`philadelphia: ${PHILADELPHIA.length} row offices · centre county: ${CENTRE.length} elected offices`);

let verify = null;
if (argv.includes('--verify')) {
  console.log('\nverify — re-reading every source page and asserting it names the officeholder:');
  verify = { tested: 0, named: 0, notNamed: [], errors: [] };
  const cache = new Map();
  for (const o of [...PHILADELPHIA, ...CENTRE]) {
    try {
      if (!cache.has(o.source)) cache.set(o.source, strip(await getText(o.source)));
      verify.tested++;
      if (pageNames(cache.get(o.source), o.full_name)) verify.named++;
      else verify.notNamed.push(`${o.title}: ${o.full_name} is not named by ${o.source}`);
    } catch (e) {
      verify.errors.push(`${o.title} ${o.full_name}: ${e.message}`);
    }
  }
  console.log(`  ${verify.named}/${verify.tested} named by their own source page · ${verify.errors.length} error(s)`);
  verify.notNamed.forEach((n) => console.log(`    🔴 ${n}`));
  verify.errors.forEach((n) => console.log(`    🔴 ${n}`));
  if (verify.named !== verify.tested) findings.push(`VERIFY_FAILED ${verify.tested - verify.named} officeholder(s) are not named by their own source`);
}

findings.forEach((f) => console.log(`  ${f}`));

const out = {
  generated_at: new Date().toISOString(),
  jurisdictions: {
    philadelphia: {
      government_geo_id: '4260000',      // the CITY row created by PA-3 — one government, city and county
      district_geo_id: '42101',          // the countywide polygon; coterminous with the place to 3 dp
      district_mtfcc: 'G4020',
      chamber: 'City and County Elected Officials',
      consolidated: true,
      note: 'No county commission: the City Council is it. These are the row offices a consolidated city keeps.',
      offices: PHILADELPHIA,
    },
    centre: {
      government_name: 'Centre County, Pennsylvania, US',
      government_geo_id: '42027',
      district_geo_id: '42027',
      district_mtfcc: 'G4020',
      chambers: { board: 'Board of County Commissioners', officers: 'County Elected Officials' },
      consolidated: false,
      offices: CENTRE,
    },
  },
  excluded_judicial: {
    reason: 'Elected, and therefore in scope under the NC-3 inclusion ruling, but deferred to the judges wave North Carolina already owes.',
    centre_county: ['Court of Common Pleas judges', 'six Magisterial District Judges'],
    philadelphia: ['Court of Common Pleas', 'Municipal Court'],
  },
  verify,
  findings,
};
fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(out, null, 2) + '\n');
console.log(`\nwrote ${OUT} — ${PHILADELPHIA.length + CENTRE.length} offices, ${findings.length} finding(s)`);
process.exit(findings.length ? 1 : 0);
