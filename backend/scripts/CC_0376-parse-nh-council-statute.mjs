#!/usr/bin/env node
/**
 * CC_0376-parse-nh-council-statute.mjs — New Hampshire's five Executive Council districts,
 * as the STATUTE defines them, resolved to counties and to a test point per town.
 *
 * This file builds the ANCHOR. It never reads the NHGRANIT map, and nothing in it derives from
 * that map, which is the whole point: the geometric gates in CC_0376-nh-exec-geofences.mjs can
 * see a torn or misprojected polygon but they cannot see two districts' LABELS swapped. Only
 * evidence from outside the map can, and this is it.
 *
 * TWO INDEPENDENT SOURCES, NEITHER OF THEM THE MAP:
 *
 *   1. RSA 662:2 "Councilor Districts" — the General Court's own merged RSA text at
 *      https://gc.nh.gov/rsa/html/LXIII/662/662-mrg.htm. 🟢 NEW HAMPSHIRE STATES THE WHOLE
 *      COMPOSITION IN WORDS: every town, city and unincorporated place is named, in exactly one
 *      of the five districts. This is a better anchor than Alabama's (62 of 67 counties) or
 *      Louisiana's (parish lists), because it is COMPLETE and it is at a FINER grain than the
 *      geography production holds.
 *      🔴 THE SOURCE LINE IS THE PROOF OF VINTAGE: "2022, 46:1, eff. May 6, 2022" — chapter 46
 *      of the 2022 session laws (SB 241), the act that replaced the 2012 map (2012, 170:1).
 *      This script REFUSES the file unless that line is present and is the LAST one, so a
 *      reverted, cached or superseded RSA page cannot be read as the current one. ▶ When New
 *      Hampshire next redistricts this gate fires, and that is correct — re-source the map,
 *      do not widen the gate.
 *
 *   2. The U.S. Census Bureau's 2024 Gazetteer of New Hampshire COUNTY SUBDIVISIONS,
 *      https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2024_Gazetteer/2024_gaz_cousubs_33.txt
 *      — which gives every MCD its county FIPS (inside the GEOID) and an INTERNAL POINT
 *      guaranteed to lie within it. The statute says which district a town is in; the Census
 *      says where that town is. Neither knows about the other, and neither is the plan.
 *
 * WHAT THIS BUYS, AND IT IS MORE THAN THE EARLIER STATES GOT:
 *   - a COUNTY composition for all 10 New Hampshire counties, derived rather than asserted;
 *   - one point-in-polygon test point per town, each labelled by the statute. Swapping any two
 *     districts moves dozens of them at once. Nebraska had no such source and had to leave two
 *     pairs of districts unpinned; New Hampshire leaves none.
 *
 * 🔴 NOTHING IS DROPPED SILENTLY, IN EITHER DIRECTION. Every statute name must match exactly one
 *   Census subdivision AND every Census subdivision must be claimed by exactly one district. An
 *   unmatched name on either side is a hard error, never a skip: a parser that quietly loses
 *   towns weakens the anchor in the exact direction that hides a mislabelled district.
 *
 * 🔴🔴 `FUNCSTAT` IS NOT THE FILTER, AND THE OBVIOUS READING OF IT THROWS AWAY EVERY NEW HAMPSHIRE
 *   CITY. All 13 cities — Manchester, Nashua, Concord, Portsmouth, Keene, Dover, Rochester,
 *   Berlin, Claremont, Franklin, Laconia, Lebanon, Somersworth — are coded `FUNCSTAT = 'F'` in
 *   the county-subdivision file, because the Census carries a New Hampshire city as an
 *   incorporated PLACE and leaves a coextensive shell in the MCD layer. They have real land
 *   (Manchester 85.7 km²) and real internal points. `Livermore town` is `FUNCSTAT = 'I'`, an
 *   inactive unit that the statute still names. The only genuinely empty row in the file is
 *   `County subdivisions not defined` (GEOID 3301500000), whose `ALAND` is 0 and whose internal
 *   point is in the Atlantic. So the discriminator is **`ALAND = 0`**, read off the rows, not a
 *   status letter read off its name. Filtering on `FUNCSTAT <> 'F'` was tried first and silently
 *   dropped 13 of the state's largest towns; it only surfaced because the both-directions join
 *   below refuses to lose a statute name.
 *
 * 🔴 THE SPELLING ALIAS IS DECLARED, NOT INFERRED. The Census writes "Wentworth location" where
 *   the RSA writes "Wentworth's Location". That is the only divergence beyond punctuation and the
 *   generic type word, and it is listed below so a reviewer can see it. A fuzzy matcher is
 *   deliberately NOT used — it would paper over exactly the disagreement this file exists to find.
 *
 * Downloaded pages are untrusted data: read as text, parsed with regexes, nothing executed.
 *
 * Usage (from backend/):
 *   node scripts/CC_0376-parse-nh-council-statute.mjs <outdir> <out.json> [--offline]
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const argv = process.argv.slice(2);
const OFFLINE = argv.includes('--offline');
const [OUTDIR, OUT] = argv.filter(a => !a.startsWith('--'));
if (!OUTDIR || !OUT) throw new Error('usage: CC_0376-parse-nh-council-statute.mjs <outdir> <out.json> [--offline]');

const RSA_URL = 'https://gc.nh.gov/rsa/html/LXIII/662/662-mrg.htm';
const GAZ_URL = 'https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2024_Gazetteer/2024_gaz_cousubs_33.txt';
const UA = 'ev-accounts/1.0 (New Hampshire Executive Council district import)';

// 🔴 The act that put the current map in force. Absent => the page is not the map we think it is.
const REQUIRED_SOURCE_LINE = '2022, 46:1, eff. May 6, 2022';
const SUPERSEDED_SOURCE_LINE = '2012, 170:1';   // must still be present, as history, BEFORE the 2022 entry

// The only name the two sources spell differently beyond punctuation and the generic type word.
const ALIASES = new Map([['wentworths location', 'wentworth location']]);

const COUNTY_NAMES = {
  '001': 'Belknap', '003': 'Carroll', '005': 'Cheshire', '007': 'Coos', '009': 'Grafton',
  '011': 'Hillsborough', '013': 'Merrimack', '015': 'Rockingham', '017': 'Strafford', '019': 'Sullivan',
};

// New Hampshire is roughly -72.56..-70.70 east-west and 42.70..45.31 north-south. Generous.
const LON_MIN = -72.8, LON_MAX = -70.4, LAT_MIN = 42.5, LAT_MAX = 45.5;

fs.mkdirSync(OUTDIR, { recursive: true });

function norm(s) {
  const k = s.toLowerCase()
    .replace(/&/g, 'and')
    .replace(/['‘’]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/\s+(town|city|township)$/, '');
  return ALIASES.get(k) ?? k;
}

async function grab(url, file) {
  if (!OFFLINE) {
    const r = await fetch(url, { headers: { 'User-Agent': UA } });
    if (!r.ok) throw new Error(`${url}: HTTP ${r.status}`);
    const body = await r.text();
    // A soft 404 or a WAF challenge is a 200 with the wrong body; assert on content, not status.
    if (body.length < 2000) throw new Error(`${url}: body is only ${body.length} bytes — not the document`);
    fs.writeFileSync(file, body);
  }
  if (!fs.existsSync(file)) throw new Error(`${file} does not exist — run without --offline`);
  const raw = fs.readFileSync(file, 'utf8');
  return { raw, sha256: crypto.createHash('sha256').update(raw).digest('hex') };
}

// ------------------------------------------------------------------ 1. the statute
const rsa = await grab(RSA_URL, path.join(OUTDIR, 'rsa-662.html'));

const text = rsa.raw
  .replace(/<br\s*\/?>/gi, '\n')
  .replace(/<[^>]+>/g, '')
  .replace(/&#150;|&#8211;|&ndash;/g, '-')
  .replace(/&nbsp;/g, ' ')
  .replace(/&amp;/g, '&')
  .replace(/&#39;|&rsquo;|&#8217;/g, "'");

const start = text.indexOf('662:2 Councilor Districts');
if (start < 0) throw new Error('RSA 662:2 "Councilor Districts" was not found on the page');
const end = text.indexOf('662:3 State Senate Districts', start);
if (end < 0) throw new Error('RSA 662:3 was not found — the section is unbounded');
const section = text.slice(start, end);

if (!section.includes(REQUIRED_SOURCE_LINE)) {
  throw new Error(
    `RSA 662:2 does not carry the source line "${REQUIRED_SOURCE_LINE}". New Hampshire has ` +
    `amended its councilor districts since this script was written — RE-SOURCE the map; do not ` +
    `relax this check.`);
}
if (!section.includes(SUPERSEDED_SOURCE_LINE)) {
  throw new Error(`RSA 662:2 no longer lists ${SUPERSEDED_SOURCE_LINE} in its history — this is not the expected page`);
}
// The source line is chronological, so the 2022 act must come last.
if (section.indexOf(SUPERSEDED_SOURCE_LINE) > section.indexOf(REQUIRED_SOURCE_LINE)) {
  throw new Error('the RSA source line is not in chronological order — read it by hand');
}
const tail = section.slice(section.indexOf(REQUIRED_SOURCE_LINE) + REQUIRED_SOURCE_LINE.length);
if (/\b20[2-9]\d,\s*\d+:\d+/.test(tail)) {
  throw new Error(`a later session law follows ${REQUIRED_SOURCE_LINE}: ${tail.trim().slice(0, 160)}`);
}

const ROMAN = ['I', 'II', 'III', 'IV', 'V'];
const statute = new Map();        // normalised name -> district
const statuteRaw = new Map();     // normalised name -> the name as the RSA prints it
for (let i = 0; i < 5; i++) {
  const d = i + 1;
  const re = new RegExp(`\\n\\s*${ROMAN[i]}\\.\\s*Councilor district number ${d} is constituted of the ([^.]*?)\\.`, 's');
  const m = section.match(re);
  if (!m) throw new Error(`district ${d}: the "Councilor district number ${d} is constituted of" clause was not found`);
  let body = m[1].replace(/\s+/g, ' ').trim();
  const of = body.indexOf(' of ');     // "towns, cities, and unincorporated places of X, Y, and Z"
  if (of < 0) throw new Error(`district ${d}: the clause names no list`);
  body = body.slice(of + 4);
  const names = body.split(',').map(s => s.trim().replace(/^and\s+/i, '')).filter(Boolean);
  if (names.length < 10) throw new Error(`district ${d}: only ${names.length} names parsed — the clause did not split`);
  for (const name of names) {
    if (!/^[A-Z]/.test(name)) throw new Error(`district ${d}: "${name}" does not look like a place name`);
    const key = norm(name);
    if (statute.has(key)) {
      throw new Error(`"${name}" is in councilor district ${statute.get(key)} AND ${d} — the statute cannot assign a place twice`);
    }
    statute.set(key, d);
    statuteRaw.set(key, name);
  }
  console.log(`  RSA 662:2 ${ROMAN[i].padEnd(3)} — district ${d}: ${String(names.length).padStart(3)} towns, cities and places`);
}
console.log(`RSA 662:2 names ${statute.size} places across 5 districts · sha256 ${rsa.sha256.slice(0, 16)}`);

// ------------------------------------------------------------------ 2. the Census gazetteer
const gaz = await grab(GAZ_URL, path.join(OUTDIR, 'gaz-cousubs-33.txt'));

const lines = gaz.raw.trim().split(/\r?\n/);
const header = lines[0].split('\t').map(s => s.trim());
for (const need of ['USPS', 'GEOID', 'NAME', 'FUNCSTAT', 'INTPTLAT', 'INTPTLONG']) {
  if (!header.includes(need)) throw new Error(`the gazetteer has no ${need} column — its format has changed`);
}
const mcds = lines.slice(1).map(l => {
  const c = l.split('\t');
  const o = {};
  header.forEach((h, i) => { o[h] = (c[i] ?? '').trim(); });
  return o;
}).filter(r => r.GEOID);
if (mcds.some(r => r.USPS !== 'NH')) throw new Error('the gazetteer file holds a state other than NH');

// 🔴 NOT a FUNCSTAT filter — see the header. Every row with land is a real place the statute must
//    name; the only row without land is the "not defined" remainder. The statuses are printed so
//    the distribution is on the record rather than assumed.
const byFuncstat = mcds.reduce((a, r) => { a[r.FUNCSTAT] = (a[r.FUNCSTAT] ?? 0) + 1; return a; }, {});
const real = mcds.filter(r => Number(r.ALAND) > 0);
const empty = mcds.filter(r => !(Number(r.ALAND) > 0));
console.log(`Census 2024 gazetteer: ${mcds.length} NH county subdivisions · FUNCSTAT ${JSON.stringify(byFuncstat)} · ` +
  `${real.length} with land, ${empty.length} without · sha256 ${gaz.sha256.slice(0, 16)}`);
if (empty.length !== 1 || empty[0].NAME !== 'County subdivisions not defined') {
  throw new Error(`expected exactly one landless subdivision ("County subdivisions not defined"), got ` +
    `${empty.length}: ${empty.map(r => `${r.NAME} (${r.GEOID})`).join('; ')}`);
}

// ------------------------------------------------------------------ 3. join, both directions
const towns = [];
const unmatchedCensus = [];
const claimed = new Set();
for (const r of real) {
  const key = norm(r.NAME);
  const d = statute.get(key);
  if (!d) { unmatchedCensus.push(`${r.NAME} (${r.GEOID}, FUNCSTAT ${r.FUNCSTAT}, ALAND ${r.ALAND})`); continue; }
  if (claimed.has(key)) throw new Error(`two Census subdivisions normalise to "${key}"`);
  claimed.add(key);
  if (r.GEOID.length !== 10 || !r.GEOID.startsWith('33')) throw new Error(`GEOID ${r.GEOID} is not a New Hampshire county subdivision`);
  if (!COUNTY_NAMES[r.GEOID.slice(2, 5)]) throw new Error(`GEOID ${r.GEOID} carries county ${r.GEOID.slice(2, 5)}, which is not a New Hampshire county`);
  const lat = Number(r.INTPTLAT), lon = Number(r.INTPTLONG);
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) throw new Error(`${r.NAME}: internal point is "${r.INTPTLAT}","${r.INTPTLONG}"`);
  if (lon < LON_MIN || lon > LON_MAX || lat < LAT_MIN || lat > LAT_MAX) {
    throw new Error(`${r.NAME}: internal point ${lon},${lat} is outside New Hampshire`);
  }
  towns.push({
    geoid: r.GEOID,
    county: r.GEOID.slice(2, 5),
    countyName: COUNTY_NAMES[r.GEOID.slice(2, 5)],
    censusName: r.NAME,
    statuteName: statuteRaw.get(key),
    funcstat: r.FUNCSTAT,
    district: d,
    lat, lon,
  });
}
const unmatchedStatute = [...statute.keys()].filter(k => !claimed.has(k)).map(k => statuteRaw.get(k));

if (unmatchedCensus.length) {
  throw new Error(`${unmatchedCensus.length} Census subdivision(s) are in no councilor district: ${unmatchedCensus.join('; ')}`);
}
if (unmatchedStatute.length) {
  throw new Error(`${unmatchedStatute.length} statute name(s) match no Census subdivision: ${unmatchedStatute.join('; ')}`);
}
for (const c of Object.keys(COUNTY_NAMES)) {
  if (!towns.some(t => t.county === c)) throw new Error(`no town resolved into ${COUNTY_NAMES[c]} County (${c})`);
}
console.log(`${towns.length} places matched in BOTH directions — no statute name and no Census subdivision is unaccounted for`);

// ------------------------------------------------------------------ 4. the county composition
const counties = Object.keys(COUNTY_NAMES).sort().map(fips => {
  const mine = towns.filter(t => t.county === fips);
  const townsByDistrict = {};
  for (const t of mine) townsByDistrict[t.district] = (townsByDistrict[t.district] ?? 0) + 1;
  const districts = Object.keys(townsByDistrict).map(Number).sort((a, b) => a - b);
  return {
    geoId: `33${fips}`, fips, name: COUNTY_NAMES[fips],
    towns: mine.length,
    districts,
    whole: districts.length === 1,
    district: districts.length === 1 ? districts[0] : null,
    townsByDistrict,
  };
});
const whole = counties.filter(c => c.whole);
const split = counties.filter(c => !c.whole);
console.log('\ncounty composition, derived from the statute and the Census, not from the map:');
for (const c of counties) {
  console.log(`  ${c.name.padEnd(14)} ${c.geoId}  ${String(c.towns).padStart(3)} towns  ` +
    (c.whole ? `WHOLLY in district ${c.district}` : `SPLIT ${JSON.stringify(c.townsByDistrict)}`));
}
console.log(`  -> ${whole.length} whole, ${split.length} split`);

// 🔴🔴 MEASURED, AND IT CONTRADICTS WHAT WAS EXPECTED: ONLY **ONE** OF THE TEN COUNTIES LIES
//    WHOLLY IN ONE DISTRICT (Carroll, district 1). The tier-3 inventory predicted that "the five
//    districts are large enough that several counties should fall wholly inside one"; they do
//    not. Nine of ten are split, four ways in Hillsborough's case. So **the county anchor that
//    carried Alabama and Louisiana is nearly empty here**, and a file that leaned on it would
//    have one usable row and would look anchored.
//    🟢 THE TOWN ANCHOR REPLACES IT AND IS STRICTLY STRONGER: 259 internal points, one per place,
//    every one labelled by the statute, every district carrying at least 20 of them. Nebraska and
//    New Mexico each had to record districts no evidence could separate; New Hampshire has none —
//    no permutation of these five districts survives 259 point tests. The county table below is
//    kept as a second, coarser view of the same evidence, not as the gate.
if (whole.length < 1) throw new Error('not one county lies wholly in a district — the county table is empty, use the town points');
const MIN_TOWNS_PER_DISTRICT = 15;

const perDistrict = [1, 2, 3, 4, 5].map(d => ({
  district: d,
  towns: towns.filter(t => t.district === d).length,
  counties: [...new Set(towns.filter(t => t.district === d).map(t => t.countyName))].sort(),
  wholeCounties: whole.filter(c => c.district === d).map(c => c.name),
}));
console.log('');
for (const p of perDistrict) {
  // Every district must carry enough test points that a label swap cannot hide in the noise.
  if (p.towns < MIN_TOWNS_PER_DISTRICT) {
    throw new Error(`district ${p.district} has only ${p.towns} test points (floor ${MIN_TOWNS_PER_DISTRICT}) — too few to pin it`);
  }
  console.log(`  district ${p.district}: ${String(p.towns).padStart(3)} towns · touches ${p.counties.join(', ')}` +
    (p.wholeCounties.length ? ` · WHOLE: ${p.wholeCounties.join(', ')}` : ''));
}
console.log(`\nevery district is pinned by at least ${MIN_TOWNS_PER_DISTRICT} statute-labelled test points; ` +
  `${whole.length} of ${counties.length} counties lie wholly in one district`);

fs.writeFileSync(OUT, JSON.stringify({
  body: 'New Hampshire Executive Council',
  act: 'RSA 662:2, as amended by 2022 N.H. Laws ch. 46 (SB 241), eff. May 6, 2022',
  sources: [
    { what: 'RSA 662:2 Councilor Districts', url: RSA_URL, sha256: rsa.sha256, sourceLine: REQUIRED_SOURCE_LINE },
    { what: 'U.S. Census Bureau 2024 Gazetteer, New Hampshire county subdivisions', url: GAZ_URL, sha256: gaz.sha256 },
  ],
  fetchedAt: new Date().toISOString().slice(0, 10),
  towns, counties, perDistrict,
}, null, 1));
console.log(`\nwrote ${OUT} — ${towns.length} test points, ${whole.length} whole-county anchors`);
