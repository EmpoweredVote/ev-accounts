#!/usr/bin/env node
/**
 * build-pa-cities-roster.mjs — Knight program, wave PA-3.
 *
 * Reconciles the Philadelphia and State College rosters and writes
 * data/pa-cities-roster.json. Reads nothing from the database and writes nothing to it.
 *
 * TWO JURISDICTIONS, TWO DIFFERENT SHAPES, AND THEY ARE NOT MADE UNIFORM:
 *
 *   Philadelphia — a consolidated city-county whose place polygon (142.422 sq mi) equals its
 *   county's to three decimal places. Home Rule Charter: a Mayor elected citywide and a Council
 *   of SEVENTEEN — 10 from districts and 7 AT-LARGE. The at-large seats are unnumbered, the
 *   Fort Wayne and Duluth convention.
 *   ▶ Philadelphia's separately elected ROW OFFICERS (District Attorney, City Controller,
 *   Sheriff, Register of Wills, three City Commissioners) are stage 4, not this wave: they are
 *   the county officers a consolidated city keeps (spec §3.2).
 *   ▶ Philadelphia also ELECTS ITS JUDGES. Under the NC-3 inclusion ruling (an office is seated
 *   if the voters of that jurisdiction elect it) they belong in the data, and like North
 *   Carolina's they are deferred to the judges wave rather than smuggled into a city wave.
 *
 *   State College — a borough of 4.578 sq mi in Centre County. Home Rule Charter: "there is a
 *   seven-member Council, elected at large, for four-year, overlapping terms", plus a Mayor.
 *   NO WARD LAYER EXISTS OR IS NEEDED — the Tallahassee and Boulder shape.
 *
 * 🔴 A ROSTER LIST PAGE IS NOT A CHANGE-CHECK (MN-2), so --change-check reads each member's own
 * page and asserts it NAMES that member. phlcouncil.com keeps FORMER members' pages live at the
 * same URL shape — Darrell Clarke, Helen Gym, Bobby Henon and others are all still served — so
 * "the URL 200s" proves nothing whatever here.
 *
 * 🔴 PARTY IS DROPPED. It lives on races.primary_party, never on a person or an office.
 *
 *   node scripts/build-pa-cities-roster.mjs [--change-check]
 *   node scripts/build-pa-cities-roster.mjs --self-test
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, '..', 'data', 'pa-cities-roster.json');
const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };

const PHL_LIST = 'https://phlcouncil.com/council-members/';
const PHL_MAYOR_PAGE = 'https://www.phila.gov/departments/mayor/';
const SC_LIST = 'https://statecollegepa.us/603/Borough-Council-Mayor';

const NAMED = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', rsquo: '’', lsquo: '‘', ndash: '–', mdash: '—' };
export const decodeEntities = (s) => String(s)
  .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
  .replace(/&#x([0-9a-fA-F]+);/g, (_, h) => String.fromCodePoint(parseInt(h, 16)))
  .replace(/&([a-zA-Z]+);/g, (_, n) => (n in NAMED ? NAMED[n] : `&${n};`));

const norm = (s) => String(s).toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
  .replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();

const strip = (html) => decodeEntities(String(html)
  .replace(/<script[\s\S]*?<\/script>/g, ' ')
  .replace(/<style[\s\S]*?<\/style>/g, ' ')
  .replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ');

async function getText(url, tries = 3) {
  for (let i = 0; i < tries; i++) {
    try {
      const r = await fetch(url, { headers: UA });
      // 🔴 READ THE STATUS. phila.gov serves its full site chrome on a 404, and that chrome
      // contains the phrase "Mayor Cherelle L. Parker" — so a body match on a 404 page would
      // have "confirmed" the mayor from a page that does not exist.
      if (r.status !== 200) throw new Error(`HTTP ${r.status}`);
      return await r.text();
    } catch (e) {
      if (i === tries - 1) throw new Error(`${url}: ${e.message}`, { cause: e });
      await new Promise((res) => setTimeout(res, 400 * (i + 1)));
    }
  }
}

// ── Philadelphia ─────────────────────────────────────────────────────────────

const PHL_CARD = /<a[^>]+href="(https:\/\/phlcouncil\.com\/([a-z0-9-]+)\/)"[^>]*>[\s\S]{0,400}?<\/a>/g;

/**
 * 🔴🔴 THE LISTING CARRIES A `Past Council Members` SECTION IN THE IDENTICAL FORMAT. Measured
 * 2026-09-18: a sweep of the whole page reads 14 district members, because the archive supplies
 * `Councilmember Jannie Blackwell | District 3` (left 2020) and `Council President Darrell L.
 * Clarke | District 5` (left 2024) in exactly the shape a current member takes, and seven former
 * at-large members including Helen Gym. Nothing about those rows looks wrong.
 *
 * So the archive heading is LOAD-BEARING: the text is cut at it, and a page that no longer
 * contains it THROWS rather than quietly returning a roster with the past in it. A parser that
 * cannot find its own boundary must not guess where the boundary was.
 */
export const PHL_ARCHIVE_HEADING = 'Past Council Members';

export function parsePhlCouncil(html) {
  const text = strip(html);
  const cut = text.indexOf(PHL_ARCHIVE_HEADING);
  if (cut < 0) {
    throw new Error(`the council listing no longer contains "${PHL_ARCHIVE_HEADING}" — the boundary `
      + 'between sitting and former members cannot be found, and everything past it would be seated');
  }
  const current = text.slice(0, cut);
  const out = [];
  const seen = new Set();
  const push = (full_name, seat_kind, district) => {
    const name = full_name.replace(/\s+/g, ' ').trim();
    const key = norm(name);
    if (seen.has(key)) return;
    seen.add(key);
    out.push({ full_name: name, seat_kind, district });
  };
  // "Councilmember Mark Squilla | District 1" and "Council President Kenyatta Johnson | District 2",
  // with the suffix forms the page really uses ("Curtis Jones, Jr.").
  const dist = /Council(?:member|\s+President)\s+([A-Z][A-Za-z'’. -]{2,34}?(?:,\s*(?:Jr|Sr|II|III)\.?)?)\s*\|\s*District\s+(\d{1,2})/g;
  let m;
  while ((m = dist.exec(current)) !== null) push(m[1], 'district', Number(m[2]));
  // "Councilmember At-Large Katherine Gilmore Richardson" — the name FOLLOWS the label here, and
  // the names run one after another with no separator but the next label.
  const large = /Councilmember At-Large\s+((?:[A-Z][A-Za-z'’.-]+\s+){1,3}[A-Z][A-Za-z'’.-]+)(?=\s+Councilmember|\s+Council |\s*$)/g;
  while ((m = large.exec(current)) !== null) push(m[1], 'at_large', null);
  return out;
}

export function phlFindings(members) {
  const findings = [];
  const districts = members.filter((m) => m.seat_kind === 'district');
  const atLarge = members.filter((m) => m.seat_kind === 'at_large');
  if (districts.length !== 10) findings.push(`PHL_DISTRICT_COUNT ${districts.length}, expected 10`);
  if (atLarge.length !== 7) findings.push(`PHL_AT_LARGE_COUNT ${atLarge.length}, expected 7`);
  const nums = new Set(districts.map((d) => d.district));
  for (let i = 1; i <= 10; i++) if (!nums.has(i)) findings.push(`PHL_NO_MEMBER district ${i}`);
  if (nums.size !== districts.length) findings.push('PHL_DUPLICATE_DISTRICT two members on one district');
  const names = new Set();
  for (const m of members) {
    if (names.has(norm(m.full_name))) findings.push(`PHL_DUPLICATE_NAME ${m.full_name}`);
    names.add(norm(m.full_name));
    if (/&[a-zA-Z#0-9]+;/.test(m.full_name)) findings.push(`UNDECODED_ENTITY ${m.full_name}`);
  }
  return findings;
}

// ── State College ────────────────────────────────────────────────────────────

/**
 * 🔴🔴 THE BOROUGH LIST PUTS EACH PERSON'S TITLE AFTER THEIR NAME, SO A NAIVE READ IS OFF BY ONE.
 * The page renders:
 *
 *   "Members Ezra Nanes , Mayor Evan Myers, Council President Gopal Balachandran, Council Member …"
 *
 * Split on commas and element k holds the PREVIOUS person's title followed by THIS person's name.
 * The first draft of this parser returned `Members Ezra Nanes` as the mayor and `Mayor Evan Myers`
 * as a council member — two voter-facing names with a heading welded to the front, and both would
 * have been written to production looking like ordinary data. The labels are stripped explicitly
 * and the result is asserted in the self-test against this exact fragment.
 */
const SC_LABELS = ['Members', 'Mayor', 'Council President', 'Council Member', 'Council Vice President'];

export function parseStateCollege(html) {
  const text = strip(html);
  const i = text.indexOf('Members ');
  const window = i >= 0 ? text.slice(i, i + 600) : text;
  const parts = window.split(/\s*,\s*/).map((x) => x.trim()).filter(Boolean);
  const labelOf = (chunk) => SC_LABELS.find((l) => chunk.startsWith(l)) ?? null;
  const nameOf = (chunk) => {
    const l = labelOf(chunk);
    return (l ? chunk.slice(l.length) : chunk).trim();
  };
  const out = [];
  for (let k = 0; k < parts.length; k++) {
    const name = nameOf(parts[k]);
    // the title for THIS person is the label that opens the NEXT chunk
    const title = k + 1 < parts.length ? labelOf(parts[k + 1]) : null;
    if (!title) break;
    if (!/^[A-Z][A-Za-z'’.-]+(?:\s+[A-Z][A-Za-z'’.-]+){1,3}$/.test(name)) break;
    out.push({ full_name: name, seat_kind: title === 'Mayor' ? 'mayor' : 'at_large' });
  }
  const seen = new Set();
  return out.filter((r) => (seen.has(r.full_name) ? false : (seen.add(r.full_name), true)));
}

export function scFindings(members) {
  const findings = [];
  const mayors = members.filter((m) => m.seat_kind === 'mayor');
  const council = members.filter((m) => m.seat_kind === 'at_large');
  // "there is a seven-member Council, elected at large" — Home Rule Charter, quoted on the page.
  if (council.length !== 7) findings.push(`SC_COUNCIL_COUNT ${council.length}, expected 7`);
  if (mayors.length !== 1) findings.push(`SC_MAYOR_COUNT ${mayors.length}, expected 1`);
  for (const m of members) if (/&[a-zA-Z#0-9]+;/.test(m.full_name)) findings.push(`UNDECODED_ENTITY ${m.full_name}`);
  return findings;
}

// ── self-test ────────────────────────────────────────────────────────────────

function selfTest() {
  let ok = true;
  const say = (pass, what) => { if (!pass) ok = false; console.log(`  ${pass ? 'PASS' : '🔴 FAIL'}  ${what}`); };

  // ⚠ The names must be distinct UNDER THE NORMALISER, which drops digits. An earlier fixture used
  // 'Dist 1'..'Dist 10' and every one of them normalised to 'dist', so the complete roster reported
  // ten duplicate names — the self-test failing on its own fixture, which is the self-test working.
  const WORDS = ['Ann Alpha', 'Ben Bravo', 'Cara Charlie', 'Dan Delta', 'Eve Echo', 'Fay Foxtrot',
                 'Gil Golf', 'Hal Hotel', 'Ida India', 'Joe Juliett', 'Kay Kilo', 'Lou Lima',
                 'Mia Mike', 'Ned November', 'Ola Oscar', 'Pat Papa', 'Quin Quebec'];
  const good = [];
  for (let i = 1; i <= 10; i++) good.push({ full_name: WORDS[i - 1], seat_kind: 'district', district: i });
  for (let i = 1; i <= 7; i++) good.push({ full_name: WORDS[9 + i], seat_kind: 'at_large', district: null });
  say(phlFindings(good).length === 0, 'a complete Philadelphia roster raises nothing');
  say(phlFindings(good.filter((m) => m.district !== 4)).some((f) => f.startsWith('PHL_NO_MEMBER district 4')),
      'a missing council district is reported');
  say(phlFindings(good.slice(0, 16)).some((f) => f.startsWith('PHL_AT_LARGE_COUNT 6')),
      'a missing at-large seat is reported');
  const dupe = good.concat([{ full_name: 'Dist 1', seat_kind: 'district', district: 1 }]);
  say(phlFindings(dupe).some((f) => f.startsWith('PHL_DUPLICATE_DISTRICT') || f.startsWith('PHL_DUPLICATE_NAME')),
      'a duplicated member is reported');

  const sc = [{ full_name: 'A Mayor', seat_kind: 'mayor' }];
  for (let i = 1; i <= 7; i++) sc.push({ full_name: `C ${i}`, seat_kind: 'at_large' });
  say(scFindings(sc).length === 0, 'a complete State College roster raises nothing');
  say(scFindings(sc.slice(0, 7)).some((f) => f.startsWith('SC_COUNCIL_COUNT 6')), 'a short borough council is reported');
  say(scFindings(sc.filter((m) => m.seat_kind !== 'mayor')).some((f) => f.startsWith('SC_MAYOR_COUNT 0')), 'a missing mayor is reported');

  // The parsers must survive the real page shapes, not idealised ones.
  const listing = '<p>Councilmember Mark Squilla | District 1</p>'
    + '<p>Councilmember At-Large Rue Landau Councilmember At-Large Kendra Brooks</p>'
    + '<p>Past Council Members</p><p>Councilmember Jannie Blackwell | District 3</p>'
    + '<p>Councilmember At-Large Helen Gym</p>';
  const parsed = parsePhlCouncil(listing);
  say(parsed.length === 3, 'the listing parser reads a district member and both at-large members');
  say(!parsed.some((x) => /Blackwell|Gym/.test(x.full_name)),
      'a PAST member in the identical format is EXCLUDED by the archive boundary');
  let threw = false;
  try { parsePhlCouncil('<p>Councilmember Mark Squilla | District 1</p>'); } catch { threw = true; }
  say(threw, 'a listing with no archive heading THROWS rather than guessing where the past begins');
  // The exact shape the borough really publishes, labels trailing their person.
  const scParsed = parseStateCollege('<p>Members Ezra Nanes , Mayor Evan Myers, Council President '
    + 'Gopal Balachandran, Council Member John Hayes, Council Member Susan Venegoni, Council Member About Borough Council</p>');
  say(scParsed.length === 5, `the borough parser reads all five entries (got ${scParsed.length})`);
  say(scParsed[0] && scParsed[0].full_name === 'Ezra Nanes' && scParsed[0].seat_kind === 'mayor',
      'the mayor is "Ezra Nanes", NOT "Members Ezra Nanes"');
  say(scParsed[1] && scParsed[1].full_name === 'Evan Myers' && scParsed[1].seat_kind === 'at_large',
      'the council president is "Evan Myers", NOT "Mayor Evan Myers"');
  say(scParsed.every((x) => !SC_LABELS.some((l) => x.full_name.startsWith(l))),
      'no parsed name begins with one of the page labels');
  say(decodeEntities('Di&#233;go') === 'Diégo', 'HTML entities are decoded');
  say(DEPARTURE.test(deChrome('Councilmember Smith has resigned effective June 21')),
      'the departure scanner fires on real departure language after the chrome is removed');
  say(!DEPARTURE.test(deChrome('serves on the Vacant Property Review Committee')),
      'the standing committee in every page navigation no longer fires it');
  say(DEPARTURE.test(deChrome('the seat is vacant after the Vacant Property Review Committee met')),
      'removing the committee name does NOT blind it to a real vacancy in the same sentence');
  return ok;
}

// ── change-check ─────────────────────────────────────────────────────────────

/**
 * 🔴 A UNIFORM ANSWER IS A BROKEN DETECTOR. Run raw, this scanner fired on 17 of 17
 * Philadelphia member pages — every one, on the same words: the site navigation carries
 * "Vacant Property Review Committee", a standing committee of Council. A hit on every page is
 * not 17 findings, it is one piece of furniture. That committee is excluded BY NAME, narrowly,
 * and the self-test proves the scanner still fires on real departure language — including in a
 * sentence that also mentions the committee.
 */
const CHROME = [/Vacant Property Review Committee/gi];
const DEPARTURE = /\b(resign\w*|vacan\w*|no longer (?:serv|represent)\w*|former (?:council|member)\w*|stepped down|passed away|died in office)\b/i;
const deChrome = (t) => CHROME.reduce((acc, re) => acc.replace(re, ' '), t);

async function changeCheck(people, label) {
  const res = { tested: 0, named: 0, notNamed: [], departure: [], errors: [] };
  for (const p of people) {
    if (!p.page_url) continue;
    try {
      const text = strip(await getText(p.page_url));
      res.tested++;
      if (norm(text).includes(norm(p.full_name))) res.named++;
      else res.notNamed.push(`${p.full_name}: their own page does not name them — ${p.page_url}`);
      const scanned = deChrome(text);
      const i = scanned.search(DEPARTURE);
      if (i >= 0) res.departure.push(`${p.full_name}: "${scanned.slice(Math.max(0, i - 70), i + 130).trim()}" ${p.page_url}`);
    } catch (e) {
      res.errors.push(`${p.full_name}: ${e.message}`);
    }
  }
  const skipped = people.filter((x) => !x.page_url).length;
  res.skipped = skipped;
  console.log(`  ${label}: ${res.named}/${res.tested} named by their own page · departure language ${res.departure.length} · errors ${res.errors.length}`
    + (skipped ? ` 🔴 ${skipped} member(s) HAVE NO PAGE and were not tested` : ''));
  if (res.tested === 0) {
    console.log(`    🔴 NOTHING WAS TESTED for ${label}. A 0/0 is not a pass — this publisher has no`);
    console.log('      per-member page, so the instrument used instead is recorded in pa.md.');
  }
  res.notNamed.forEach((n) => console.log(`    🔴 ${n}`));
  res.departure.forEach((n) => console.log(`    ⚠ ${n}`));
  res.errors.forEach((n) => console.log(`    🔴 ${n}`));
  return res;
}

// ── main ─────────────────────────────────────────────────────────────────────

const argv = process.argv.slice(2);
if (argv.includes('--self-test')) {
  console.log('self-test — each detector must report the defect planted for it:');
  process.exit(selfTest() ? 0 : 1);
}

const out = { generated_at: new Date().toISOString(), jurisdictions: {}, findings: [] };

// Philadelphia
const phlHtml = await getText(PHL_LIST);
const phlMembers = parsePhlCouncil(phlHtml);
const phlFind = phlFindings(phlMembers);
// member page URLs, taken from the same listing
const urls = new Map();
let m;
PHL_CARD.lastIndex = 0;
while ((m = PHL_CARD.exec(phlHtml)) !== null) {
  const slug = m[2];
  urls.set(slug, m[1]);
}
/**
 * 🔴 THE MEMBER-PAGE SLUG DROPS MIDDLE INITIALS AND SUFFIXES, AND THE COUNT IS THE TELL. The first
 * matcher paired 16 of 17 members with a page: `Brian J. O'Neill` normalises to `brianjoneill`
 * while his page is `/brianoneill/`. A change-check that silently tests 16 of 17 reports a clean
 * sweep for a roster it never fully read — MN-6 again. Every variant is tried, and an unmatched
 * member is a FINDING, not a quietly skipped row.
 */
const slugVariants = (name) => {
  // ⚠ AN INITIAL IS A TOKEN WRITTEN "J.", NOT MERELY A SHORT ONE. Dropping every one-letter token
  // turned `Brian J. O’Neill` into `brianneill`, because the particle in O’Neill is one letter
  // once the apostrophe is stripped. His page is /brianoneill/.
  const raw = String(name).split(/\s+/).filter(Boolean);
  const letters = (arr) => arr.join(' ').toLowerCase().normalize('NFD')
    .replace(/[̀-ͯ]/g, '').replace(/[^a-z]/g, '');
  const isInitial = (t) => /^[A-Za-z]\.$/.test(t);
  const isSuffix = (t) => /^(jr|sr|ii|iii)\.?,?$/i.test(t);
  const noInitials = raw.filter((t) => !isInitial(t));
  const noSuffix = raw.filter((t) => !isSuffix(t));
  const neither = raw.filter((t) => !isInitial(t) && !isSuffix(t));
  return [...new Set([raw, noInitials, noSuffix, neither].map(letters))];
};
for (const p of phlMembers) {
  const want = slugVariants(p.full_name);
  const key = [...urls.keys()].find((s) => want.includes(s.replace(/[^a-z]/g, '')));
  p.page_url = key ? urls.get(key) : null;
  if (!p.page_url) phlFind.push(`PHL_NO_MEMBER_PAGE ${p.full_name} — the change-check cannot read a page it cannot find`);
}

const mayorHtml = await getText(PHL_MAYOR_PAGE);
const mayorMatch = strip(mayorHtml).match(/Mayor (Cherelle [A-Z]\.? Parker|[A-Z][A-Za-z'.-]+ [A-Z]\.? ?[A-Z][A-Za-z'.-]+)/);
const phlMayor = mayorMatch ? mayorMatch[1].replace(/\s+/g, ' ').trim() : null;
if (!phlMayor) phlFind.push('PHL_MAYOR_NOT_FOUND on the city\'s own mayor page');

out.jurisdictions.philadelphia = {
  place_geo_id: '4260000',
  county_geo_id: '42101',
  consolidated: true,
  seats: { mayor: 1, council_district: 10, council_at_large: 7 },
  mayor: phlMayor && { full_name: phlMayor, seat_kind: 'mayor', page_url: PHL_MAYOR_PAGE },
  council: phlMembers,
};
out.findings.push(...phlFind.map((f) => `philadelphia: ${f}`));

// State College
const scHtml = await getText(SC_LIST);
const scMembers = parseStateCollege(scHtml);
const scFind = scFindings(scMembers);
out.jurisdictions.state_college = {
  place_geo_id: '4273808',
  county_geo_id: '42027',
  consolidated: false,
  seats: { mayor: 1, council_at_large: 7 },
  members: scMembers,
};
out.findings.push(...scFind.map((f) => `state_college: ${f}`));

console.log(`philadelphia: ${phlMembers.filter((p) => p.seat_kind === 'district').length} district + ${phlMembers.filter((p) => p.seat_kind === 'at_large').length} at-large + mayor ${phlMayor ?? '(NOT FOUND)'}`);
console.log(`state_college: ${scMembers.filter((p) => p.seat_kind === 'at_large').length} at-large council + ${scMembers.filter((p) => p.seat_kind === 'mayor').length} mayor`);
out.findings.forEach((f) => console.log(`  ${f}`));

if (argv.includes('--change-check')) {
  console.log('\nchange-check — reading each member\'s own page:');
  out.jurisdictions.philadelphia.change_check = await changeCheck(phlMembers, 'philadelphia council');
  out.jurisdictions.state_college.change_check = await changeCheck(scMembers, 'state college');
}

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(out, null, 2) + '\n');
console.log(`\nwrote ${OUT} — ${out.findings.length} finding(s)`);
