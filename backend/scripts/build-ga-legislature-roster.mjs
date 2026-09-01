#!/usr/bin/env node
/**
 * build-ga-legislature-roster.mjs
 *
 * Reconciles the Georgia General Assembly roster and writes data/ga-legislature-roster.json.
 * Reads nothing from the database and writes nothing to it.
 *
 * SOURCES — two different endpoints of legis.ga.gov, over two different records:
 *   A. The district MAP behind Find Your Legislator:
 *        /api/legislatormaps/GoogleMaps/House Map 2023      180 features
 *        /api/legislatormaps/GoogleMaps/Senate Map 2023      56 features
 *      One feature per district, carrying the SITTING member.
 *   B. The member LIST behind /members/{house,senate}:
 *        /api/members/list/1033?chamber=1   (House)
 *        /api/members/list/1033?chamber=2   (Senate)
 *      One row per PERSON, including people who have LEFT.
 *
 * 🔴 BOTH ENDPOINTS RETURN HTTP 401 TO curl AND TO AN IN-PAGE fetch(). They carry a bearer
 * token minted by /api/authentication/token. This script therefore does NOT fetch them: it
 * reads the payloads captured to data/seed-ga-2026/ by loading the pages in a browser and
 * reading the response bodies out of the network log. Re-capture them the same way when the
 * roster needs refreshing; do not add a fetch() here and assume it works.
 *
 * 🔴 THE LIST IS OVER-LONG, EXACTLY AS FLORIDA'S WAS. Measured 2026-08-31: 186 rows for 180
 * House seats and 61 for 56 Senate seats, because a seat that changed hands keeps BOTH people.
 * Georgia annotates it cleanly — the departed row carries `dateVacated`, the sitting row does
 * not — so the rule is `dateVacated == null`. Do NOT de-duplicate on name or on district.
 * Eleven seats turned over in the year to 2026-03-09, so this is the common case here, not an
 * edge case.
 *
 * 🔴 THERE IS NO term_start TO BE HAD, AND NONE IS INVENTED. A Georgia member page carries
 * name, district, party, city, addresses, staff, birthday and spouse — and no service-start of
 * any kind. Checked against a first-term member who arrived after a 2025-10-12 vacancy: the
 * whole About block is "Birthday / Spouse". So every term is written OPEN-ENDED with
 * start_precision 'unknown' (the NC pattern). The 2024 general election date is the start of
 * the current TERM, not of continuous occupancy, and re-election does not end an occupancy.
 * The `vacated` dates below are the PREDECESSOR's end and license nothing for the successor.
 *
 * 🔴 PARTY IS DELIBERATELY DROPPED. Both payloads carry it. Party lives on
 * races.primary_party in this schema, never on a person or an office.
 *
 * 🟢 THE PORTRAIT URL IS KEPT AT FULL RESOLUTION. The payloads give `...jpg?size=mpSm`, which
 * is 90x120. Dropping the query returns the original — measured 1688x2283 on
 * fincher-bill-5092.jpg, 47x the bytes — and that is exactly what each member page links as
 * "High Resolution Photo". Stage 5 needs no upscaling for the legislature.
 *
 * CHANGE-CHECK. Pass --check-openstates to diff the reconciled roster against
 * data.openstates.org/people/current/ga.csv, which is a third party and therefore able to
 * know about a change our source missed. 🔴 IT IS A DETECTOR, NOT AN ORACLE — every hit is a
 * reading queue against the chamber's own page, never a verdict. Same rule as roster-diff.mjs.
 *
 *   node scripts/build-ga-legislature-roster.mjs
 *   node scripts/build-ga-legislature-roster.mjs --check-openstates
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SEED = path.join(HERE, '..', 'data', 'seed-ga-2026');
const OUT = path.join(HERE, '..', 'data', 'ga-legislature-roster.json');

const SOURCES = {
  house: {
    map: path.join(SEED, 'ga_house_map_2023.json'),
    list: path.join(SEED, 'ga_members_list_house.json'),
    seats: 180,
    chamber: 'STATE_LOWER',
    label: (n) => `State House District ${n}`,
  },
  senate: {
    map: path.join(SEED, 'ga_senate_map_2023.json'),
    list: path.join(SEED, 'ga_members_list_senate.json'),
    seats: 56,
    chamber: 'STATE_UPPER',
    label: (n) => `State Senate District ${n}`,
  },
};

/** The captured files may carry a tool preamble before the JSON. Find the real start. */
function readJson(file, opener) {
  const raw = fs.readFileSync(file, 'utf8');
  const i = raw.indexOf(opener);
  if (i === -1) throw new Error(`${path.basename(file)}: no JSON found (looked for ${opener})`);
  return JSON.parse(raw.slice(i));
}

function loadMap(file) {
  const d = readJson(file, '{"chamber"');
  let gj = d.geoJson;
  if (typeof gj === 'string') gj = JSON.parse(gj);
  const feats = gj.features || gj;
  const out = new Map();
  for (const f of feats) {
    const p = f.properties;
    out.set(Number(p.District), { name: String(p.Name || '').trim(), url: p.Url || '' });
  }
  return out;
}

function loadList(file) {
  const rows = readJson(file, '[');
  const byDistrict = new Map();
  for (const r of rows) {
    const d = Number(r.districtNumber);
    if (!byDistrict.has(d)) byDistrict.set(d, []);
    byDistrict.get(d).push(r);
  }
  return { rows, byDistrict };
}

/** 🔴 The full-resolution original is the same URL with the size query removed. */
const fullResPortrait = (u) => (u ? String(u).split('?')[0] : null);

const roster = [];
const departures = [];
const problems = [];

for (const [chamberKey, src] of Object.entries(SOURCES)) {
  const map = loadMap(src.map);
  const { rows, byDistrict } = loadList(src.list);

  if (map.size !== src.seats) problems.push(`${chamberKey}: map has ${map.size} districts, expected ${src.seats}`);
  if (byDistrict.size !== src.seats) problems.push(`${chamberKey}: list covers ${byDistrict.size} districts, expected ${src.seats}`);

  for (let n = 1; n <= src.seats; n++) {
    const listRows = byDistrict.get(n) || [];
    const sitting = listRows.filter((r) => !r.dateVacated);
    const left = listRows.filter((r) => r.dateVacated);
    for (const r of left) {
      departures.push({
        chamber: src.chamber, district: n, name: String(r.fullName || '').trim(),
        member_id: r.id, vacated: String(r.dateVacated).slice(0, 10),
      });
    }
    // 🔴 EXACTLY ONE SITTING ROW, OR STOP. Two would mean the dateVacated discriminator has
    // failed and we would be guessing which of them holds the seat — the Nashville
    // "ranking degrades to first row listed" failure, in a different table.
    if (sitting.length !== 1) {
      problems.push(`${chamberKey} D${n}: ${sitting.length} non-vacated list rows (expected 1)`);
      continue;
    }
    const row = sitting[0];
    const mapEntry = map.get(n);
    if (!mapEntry) { problems.push(`${chamberKey} D${n}: absent from the map payload`); continue; }

    const listName = String(row.fullName || '').trim().replace(/\s+/g, ' ');
    const mapName = mapEntry.name.replace(/\s+/g, ' ');
    // Both sources must name the same person. A mismatch is a human read, never a pick.
    if (listName !== mapName) {
      problems.push(`${chamberKey} D${n}: map says "${mapName}", list says "${listName}"`);
      continue;
    }

    roster.push({
      chamber: src.chamber,
      district: n,
      district_label: src.label(n),
      geo_id: `13${String(n).padStart(3, '0')}`,
      full_name: listName,
      first_name: (row.name?.first || row.firstName || '').trim() || null,
      last_name: (row.name?.last || row.lastName || '').trim() || null,
      middle_name: (row.name?.middle || '').trim() || null,
      suffix: (row.name?.suffix || '').trim() || null,
      nickname: (row.name?.nickname || '').trim() || null,
      member_id: row.id,
      member_url: mapEntry.url || `https://www.legis.ga.gov/members/${chamberKey}/${row.id}`,
      city: row.city || null,
      portrait_url: fullResPortrait(row.photos?.[0]?.url),
      // No date is asserted. Georgia publishes none. See the header.
      term_start: null,
      start_precision: 'unknown',
    });
  }
}

roster.sort((a, b) => (a.chamber === b.chamber ? a.district - b.district : a.chamber < b.chamber ? -1 : 1));
departures.sort((a, b) => (a.chamber === b.chamber ? a.district - b.district : a.chamber < b.chamber ? -1 : 1));

const summary = {
  generated_note: 'Reconciled from two legis.ga.gov endpoints. No term_start is asserted; Georgia publishes none.',
  counts: {
    house: roster.filter((r) => r.chamber === 'STATE_LOWER').length,
    senate: roster.filter((r) => r.chamber === 'STATE_UPPER').length,
    total: roster.length,
    departures_recorded: departures.length,
  },
  roster,
  departures,
};

if (problems.length) {
  console.error(`\n${problems.length} unresolved problem(s) — nothing written:\n`);
  problems.forEach((p) => console.error('  ' + p));
  process.exit(1);
}

fs.writeFileSync(OUT, JSON.stringify(summary, null, 2));
console.log(`wrote ${path.relative(process.cwd(), OUT)}`);
console.log(`  House ${summary.counts.house} · Senate ${summary.counts.senate} · total ${summary.counts.total}`);
console.log(`  ${departures.length} departure(s) recorded from the list payload (predecessors, not starts)`);
const noPortrait = roster.filter((r) => !r.portrait_url).length;
console.log(`  portraits at full resolution: ${roster.length - noPortrait}/${roster.length}`);

if (!process.argv.includes('--check-openstates')) process.exit(0);

// ── Change-check against a third party ───────────────────────────────────────
const norm = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase().replace(/["'’.]/g, '').replace(/\s+/g, ' ').trim();
/** Compare on first + last only. Middle names, nicknames and suffixes differ between any two
 *  rosters and are not evidence of a different person. */
const key = (first, last) => `${norm(first)}|${norm(last)}`;

const url = 'https://data.openstates.org/people/current/ga.csv';
console.log(`\nchange-check: ${url}`);
const res = await fetch(url);
if (!res.ok) { console.error(`  openstates returned HTTP ${res.status} — change-check NOT run`); process.exit(1); }
const csv = await res.text();
const lines = csv.split(/\r?\n/).filter(Boolean);
const head = lines[0].split(',');
const col = (n) => head.indexOf(n);
const iName = col('name'), iGiven = col('given_name'), iFamily = col('family_name');
// 🔴 THE COLUMN IS `current_chamber`, NOT `current_org_classification`. The first version of
// this check named the wrong column, so every row was skipped, `theirs` came back EMPTY, and
// the diff reported all 236 of ours as "missing from Open States" — a UNIFORM answer, which is
// the signature of a broken detector rather than a finding. The assertion below is what turns
// that from a misleading report into a hard stop.
const iChamber = col('current_chamber'), iDist = col('current_district');
for (const [name, ix] of [['name', iName], ['current_chamber', iChamber], ['current_district', iDist]]) {
  if (ix === -1) {
    console.error(`  openstates CSV has no '${name}' column (header changed?) — change-check NOT run`);
    process.exit(1);
  }
}

const theirs = { STATE_LOWER: new Map(), STATE_UPPER: new Map() };
for (const line of lines.slice(1)) {
  // naive CSV split is unsafe for quoted commas; use a small state machine
  const cells = []; let cur = '', q = false;
  for (const ch of line) {
    if (ch === '"') q = !q;
    else if (ch === ',' && !q) { cells.push(cur); cur = ''; }
    else cur += ch;
  }
  cells.push(cur);
  const org = cells[iChamber];
  const chamber = org === 'lower' ? 'STATE_LOWER' : org === 'upper' ? 'STATE_UPPER' : null;
  if (!chamber) continue;
  const first = cells[iGiven] || (cells[iName] || '').split(' ')[0];
  const last = cells[iFamily] || (cells[iName] || '').split(' ').slice(-1)[0];
  theirs[chamber].set(key(first, last), { district: Number(cells[iDist]), name: cells[iName] });
}

// 🔴 POSITIVE CONTROL BEFORE ANY COMPARISON. A detector that measured nothing must refuse to
// report, not report everything as a difference. Georgia has 180 + 56 seats; anything close to
// zero on their side means the parse failed, not that the chamber emptied.
for (const [chamber, min] of [['STATE_LOWER', 150], ['STATE_UPPER', 45]]) {
  if (theirs[chamber].size < min) {
    console.error(`  openstates parsed only ${theirs[chamber].size} ${chamber} rows (expected ~${min}+). ` +
                  'The parse failed; the diff below would be noise. Change-check NOT run.');
    process.exit(1);
  }
}

let flagged = 0;
for (const chamber of ['STATE_LOWER', 'STATE_UPPER']) {
  const ours = new Map();
  for (const r of roster.filter((r) => r.chamber === chamber)) {
    ours.set(key(r.first_name || r.full_name.split(' ')[0], r.last_name || r.full_name.split(' ').slice(-1)[0]), r);
  }
  const t = theirs[chamber];
  const onlyOurs = [...ours.keys()].filter((k) => !t.has(k));
  const onlyTheirs = [...t.keys()].filter((k) => !ours.has(k));
  console.log(`\n  ${chamber}: ours ${ours.size} · openstates ${t.size}`);
  console.log(`    in OURS not theirs  (we may hold someone who LEFT): ${onlyOurs.length}`);
  onlyOurs.forEach((k) => { const r = ours.get(k); console.log(`      D${r.district} ${r.full_name}`); flagged++; });
  console.log(`    in THEIRS not ours  (we may be MISSING someone):    ${onlyTheirs.length}`);
  onlyTheirs.forEach((k) => { const r = t.get(k); console.log(`      D${r.district} ${r.name}`); flagged++; });
  // Second pass: right person, wrong seat.
  let wrongSeat = 0;
  for (const [k, r] of ours) {
    const th = t.get(k);
    if (th && th.district !== r.district) {
      console.log(`      SEAT MISMATCH ${r.full_name}: ours D${r.district}, openstates D${th.district}`);
      wrongSeat++; flagged++;
    }
  }
  console.log(`    seat mismatches: ${wrongSeat}`);
}
console.log(`\nchange-check flagged ${flagged} row(s). A hit is a READING QUEUE against the chamber's own page, not a verdict.`);
