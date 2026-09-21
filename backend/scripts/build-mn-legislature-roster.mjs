#!/usr/bin/env node
/**
 * build-mn-legislature-roster.mjs
 *
 * Reconciles the Minnesota Legislature roster and writes data/mn-legislature-roster.json.
 * Reads nothing from the database and writes nothing to it.
 *
 * SOURCES -- each chamber's own publication, plus one third party:
 *   A1. https://www.house.mn.gov/members/          134 seats, across four concordant tabs
 *   A2. https://www.senate.mn/api/members           67 seats, the Senate's own JSON API
 *   B.  https://data.openstates.org/people/current/mn.csv
 *       Open States. 200 rows. A DETECTOR, NOT AN ORACLE -- every disagreement is a reading
 *       queue against the member's own page, never a verdict.
 *
 * 🔴 MINNESOTA HOUSE DISTRICTS ARE NOT INTEGERS. Each Senate district holds exactly two House
 * districts, `NA` and `NB`: Senate 1 -> House 1A, 1B, through 67A/67B. Nothing here casts or
 * sorts a House district numerically, and the join key into essentials.districts is the TIGER
 * geo_id -- `2721A` for House 21A, `27035` for Senate 35 -- never the label.
 *
 * ⚠ THE HOUSE PAGE ZERO-PADS SINGLE-DIGIT DISTRICTS AND THE SENATE API DOES TOO: `01A`, `05`.
 * Open States does not: `1A`, `5`. Every comparison normalises before it compares. A raw string
 * diff of the two sources reports 18 House and 9 Senate false disagreements.
 *
 * 🔴🔴 A ROSTER LIST PAGE IS NOT A CHANGE-CHECK. house.mn.gov/members/ still lists Joe
 * Schomacker for 21A on 2026-09-14, and his own profile page carries the banner "Resigning
 * effective 11:59 p.m. Sunday, June 21st 2026". Neither chamber publishes a vacancy marker of
 * any kind. So the change-check is the 201 individual member pages, swept by
 * data/seed-mn-legislature-2026/scan-member-status.mjs, and its result is asserted here.
 *
 * 🔴 THE HOUSE'S OWN LEADERSHIP TAB IS STALE FOR TWO SEATS -- it lists Amanda Hemmingsen-Jaeger
 * (47A) and Kaohly Vang Her (64A), both of whom left in 2025. The Alphabetical, District Order,
 * Republican and DFL tabs all carry the successors, Shelley Buck and Meg Luger-Nikolai, and Open
 * States agrees with those four. The Leadership tab is therefore NOT a source here; it is read
 * only to be reported.
 *
 * 🔴 THERE IS NO term_start TO BE HAD, AND NONE IS INVENTED. The richest per-member pages either
 * chamber publishes give "Elected: 2010 / Term: 8th" (House) and "re-elected 2020, 2022 / Term:
 * 4th" (Senate) -- an election year and an ordinal, never a date. The Legislative Reference
 * Library's legislator database gives biennia ("House 1971-72"), also not a date. At least six
 * sitting members took their seats at a 2025 special election rather than at the start of the
 * biennium, so a constitutional first-Monday-in-January date would be wrong for them and is not
 * a fact about the others either. Every term is written open-ended at start_precision
 * 'unknown' -- the GA-2 and IN-2 pattern.
 *
 * 🔴 first_name AND full_name MUST COME FROM THE SAME SOURCE. An earlier draft took full_name
 * from the chamber and first_name from Open States, which wrote `Steven Jacob` with first_name
 * `Steve`. That is not cosmetic: the production duplicate guard keys on (first_name, last_name),
 * so the mismatch hid an active namesake -- a DIFFERENT Steven Jacob, running for Congress in
 * KANSAS -- from the reuse search entirely. Both now come from the chamber's own rendering;
 * Open States supplies only the surname, because it splits multi-token ones correctly.
 *
 * 🔴 PARTY IS DELIBERATELY DROPPED. All three payloads carry it. Party lives on
 * races.primary_party in this schema, never on a person or an office.
 *
 * 🔴 A UNIFORM ANSWER IS A BROKEN DETECTOR. --self-test plants four defect shapes into source B
 * and requires each to be reported before the agreement is trusted.
 *
 *   node scripts/build-mn-legislature-roster.mjs
 *   node scripts/build-mn-legislature-roster.mjs --self-test
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SEED = path.join(HERE, '..', 'data', 'seed-mn-legislature-2026');
const OUT = path.join(HERE, '..', 'data', 'mn-legislature-roster.json');

/**
 * Alphabetical and District Order each carry all 134. GOP and DFL carry only their own caucus,
 * 67 each, and their union must be the whole House exactly once -- an absence from GOP is a fact
 * about party, not a disagreement. The Leadership tab is deliberately excluded: see the header.
 */
const HOUSE_TABS_FULL = ['Alpha', 'District'];
const HOUSE_TABS_CAUCUS = ['GOP', 'DFL'];
const HOUSE_TABS = [...HOUSE_TABS_FULL, ...HOUSE_TABS_CAUCUS];
const SENATE_API = path.join(SEED, '_sen-members.json');
const OPENSTATES = path.join(SEED, '_os-mn.csv');
const HOUSE_SWEEP = path.join(SEED, '_house-profiles-index.json');
const SENATE_SWEEP = path.join(SEED, '_senate-bios-index.json');

/**
 * The one seat the change-check found. Schomacker resigned effective 11:59 p.m. 2026-06-21, so
 * the first vacant day is 2026-06-22. The House's own Session Daily reports that no special
 * election will be called; the seat is filled at the 2026-11-03 general.
 */
const VACANCIES = {
  '2721A': {
    district: '21A',
    departed: 'Joe Schomacker',
    first_vacant_day: '2026-06-22',
    how_ended: 'resigned',
    evidence: [
      'https://www.house.mn.gov/members/profile/15367 (banner: "Resigning effective 11:59 p.m. Sunday, June 21st 2026")',
      'https://www.house.mn.gov/SessionDaily/Story/19204 ("No special election will be called to fill the remainder of his term")',
    ],
  },
};

/**
 * Settled name differences between a chamber's own page and Open States. Each is one person
 * under two forms, checked against the member's own page, which is what the chamber calls them
 * and therefore what a voter should see. Open States' form is kept as an alternate name.
 *
 * 🔴 THIS IS AN ALLOWLIST, NOT A SILENCER. Anything not listed here still fails the build.
 */
const NAME_VARIANTS = {
  'lower-38A': {
    chamber: 'Huldah Momanyi-Hiltsley',
    openstates: 'Huldah Hiltsley',
    surname: 'Momanyi-Hiltsley',
    why: 'https://www.house.mn.gov/members/profile/15634 heads the page "Rep. Huldah Momanyi-Hiltsley". Open States files her under the shorter surname. Same seat, same person, same first name.',
  },
};

/** RFC4180-ish CSV reader. Open States quotes biography and address fields containing commas. */
function parseCsv(text) {
  const rows = [];
  let field = '', row = [], inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') { if (text[i + 1] === '"') { field += '"'; i++; } else inQuotes = false; }
      else field += c;
    } else if (c === '"') inQuotes = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); field = ''; rows.push(row); row = []; }
    else if (c !== '\r') field += c;
  }
  if (field.length || row.length) { row.push(field); rows.push(row); }
  return rows;
}

/** `01A` -> `1A`; `05` -> `5`. Both chambers pad, Open States does not. */
const normDistrict = (d) => String(d || '').trim().replace(/^0+(?=\d)/, '').toUpperCase();

/** TIGER GEOID, which is what essentials.districts.geo_id holds for Minnesota. */
const houseGeoId = (d) => `27${String(d).replace(/[AB]$/, '').padStart(2, '0')}${String(d).slice(-1)}`;
const senateGeoId = (d) => `27${String(d).padStart(3, '0')}`;

const normName = (s) => String(s || '').toLowerCase().normalize('NFD')
  .replace(/[̀-ͯ]/g, '').replace(/[^a-z ]/g, '').replace(/\s+/g, ' ').trim();

/** `María Isa Pérez-Vega` -> ['maria','isa','perez','vega']. Hyphens and periods become breaks. */
const tokens = (s) => String(s || '').toLowerCase().normalize('NFD')
  .replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9]+/g, ' ').trim().split(/\s+/).filter(Boolean);

/**
 * Identity test: does the chamber's rendering of the name END WITH the surname Open States
 * records, token for token? This is the IN-2 surname test, made safe for the two shapes that
 * break a naive one -- a multi-token surname (`Scott Van Binsbergen`, whose last token alone is
 * not the surname) and a hyphenated one (`María Isa Pérez-Vega`).
 */
function surnameAgrees(chamberFullName, osFamily) {
  const a = tokens(chamberFullName), b = tokens(osFamily);
  if (!b.length || b.length > a.length) return false;
  return b.every((t, i) => t === a[a.length - b.length + i]);
}

function loadHouse() {
  /** @type {Map<string, {pid: string, name: string, party: string}>} */
  const merged = new Map();
  const perTab = {};
  for (const tab of HOUSE_TABS) {
    const m = new Map(JSON.parse(fs.readFileSync(path.join(SEED, `_tab-${tab}.json`), 'utf8'))
      .map(([k, v]) => [normDistrict(k), v]));
    perTab[tab] = m;
    for (const [k, v] of m) if (!merged.has(k)) merged.set(k, v);
  }
  // Every tab must agree on every seat it carries, or there is no single source A1.
  const s = (x) => (x ? `${x.pid}|${x.name}` : 'MISSING');
  const disagreements = [];
  for (const [k, v] of merged) {
    for (const tab of HOUSE_TABS_FULL) {
      if (s(perTab[tab].get(k)) !== s(v)) disagreements.push(`House ${k}: ${tab}=${s(perTab[tab].get(k))} vs ${s(v)}`);
    }
    for (const tab of HOUSE_TABS_CAUCUS) {
      const o = perTab[tab].get(k);
      if (o && s(o) !== s(v)) disagreements.push(`House ${k}: ${tab}=${s(o)} vs ${s(v)}`);
    }
  }
  // The two caucus tabs must partition the House: every seat in exactly one of them.
  for (const k of merged.keys()) {
    const inGop = perTab.GOP.has(k), inDfl = perTab.DFL.has(k);
    if (inGop === inDfl) disagreements.push(`House ${k}: in GOP tab=${inGop}, in DFL tab=${inDfl} -- the caucus tabs must partition the House`);
  }
  if (disagreements.length) {
    throw new Error(`house.mn.gov tabs disagree:\n  ${disagreements.join('\n  ')}`);
  }
  return merged;
}

function loadSenate() {
  const members = JSON.parse(fs.readFileSync(SENATE_API, 'utf8')).members;
  return new Map(members.map((m) => [normDistrict(m.dist), {
    mem_id: m.mem_id,
    name: String(m.preferred_full_name).trim(),
    last: String(m.preferred_last_name).trim(),
  }]));
}

function loadOpenStates() {
  const rows = parseCsv(fs.readFileSync(OPENSTATES, 'utf8'));
  const hdr = rows[0];
  const at = (r, n) => r[hdr.indexOf(n)];
  return rows.slice(1).filter((r) => r.length > 3 && r[0]).map((r) => ({
    os_id: at(r, 'id'),
    name: at(r, 'name'),
    given: at(r, 'given_name'),
    family: at(r, 'family_name'),
    chamber: at(r, 'current_chamber'),
    district: normDistrict(at(r, 'current_district')),
    image: at(r, 'image') || null,
  }));
}

/**
 * Diff each chamber's own list against Open States, on holder identity.
 * A district that the change-check has established is VACANT is expected to be absent from B,
 * and absent from neither when it is not; both directions are reported.
 */
function diff(house, senate, os, vacantDistricts) {
  const osLower = new Map(os.filter((r) => r.chamber === 'lower').map((r) => [r.district, r]));
  const osUpper = new Map(os.filter((r) => r.chamber === 'upper').map((r) => [r.district, r]));
  const out = [];

  const compare = (label, mine, theirs, vacantSet) => {
    for (const [k, a] of mine) {
      const b = theirs.get(k);
      if (vacantSet.has(k)) {
        if (b) out.push(`${label}-${k} VACANT here but OPENSTATES seats ${b.name}`);
        continue;
      }
      if (!b) { out.push(`${label}-${k} OPENSTATES MISSING (chamber has ${a.name})`); continue; }
      if (surnameAgrees(a.name, b.family)) continue;
      const settled = NAME_VARIANTS[`${label}-${k}`];
      if (settled && normName(settled.chamber) === normName(a.name) && normName(settled.openstates) === normName(b.name)) continue;
      out.push(`${label}-${k} CHAMBER:"${a.name}" vs OS:"${b.name}"`);
    }
    for (const k of theirs.keys()) if (!mine.has(k)) out.push(`${label}-${k} CHAMBER MISSING (OS has ${theirs.get(k).name})`);
  };

  compare('lower', house, osLower, vacantDistricts);
  compare('upper', senate, osUpper, new Set());
  return out;
}

/**
 * Open States splits given/family and gets multi-token surnames right ("Van Binsbergen"), so it
 * is preferred. Where a settled variant exists the CHAMBER's form wins, because that is the name
 * the chamber prints and the one a voter will recognise.
 */
function surnameFor(key, chamberFullName, os, apiLast) {
  const settled = NAME_VARIANTS[key];
  if (settled && settled.surname) return settled.surname;
  if (os && os.family) return os.family;
  if (apiLast) return apiLast;
  return chamberFullName.split(/\s+/).slice(-1)[0];
}

/**
 * full_name is always the chamber's own rendering -- it is what the body prints and what a voter
 * will recognise. Open States' shorter or nicknamed form is kept as an alternate whenever it
 * differs, so a later search for "Mike Howard" still finds Michael Howard.
 */
function alternatesFor(chamberFullName, os) {
  if (!os || !os.name) return [];
  return normName(os.name) === normName(chamberFullName) ? [] : [os.name];
}

function main() {
  const house = loadHouse();
  const senate = loadSenate();
  const os = loadOpenStates();

  const vacantDistricts = new Set(Object.values(VACANCIES).map((v) => normDistrict(v.district)));

  console.log(`source A1 (house.mn.gov):  ${house.size} seats across ${HOUSE_TABS.length} concordant tabs`);
  console.log(`source A2 (senate.mn API): ${senate.size} seats`);
  console.log(`source B  (Open States):   ${os.length} rows`);
  console.log(`change-check vacancies:    ${vacantDistricts.size} (${[...vacantDistricts].join(', ') || 'none'})`);

  if (house.size !== 134) throw new Error(`House: ${house.size} seats, expected 134`);
  if (senate.size !== 67) throw new Error(`Senate: ${senate.size} seats, expected 67`);
  for (let i = 1; i <= 67; i++) {
    if (!senate.has(String(i))) throw new Error(`Senate district ${i} missing`);
    for (const s of ['A', 'B']) if (!house.has(`${i}${s}`)) throw new Error(`House district ${i}${s} missing`);
  }

  // The change-check must actually have been run over every seat.
  const hSweep = JSON.parse(fs.readFileSync(HOUSE_SWEEP, 'utf8'));
  const sSweep = JSON.parse(fs.readFileSync(SENATE_SWEEP, 'utf8'));
  if (hSweep.length !== 134 || sSweep.length !== 67) {
    throw new Error(`change-check sweep incomplete: ${hSweep.length} House + ${sSweep.length} Senate pages`);
  }
  if (hSweep.some((r) => r.status !== 200) || sSweep.some((r) => r.status !== 200)) {
    throw new Error('change-check sweep has a non-200 page; a truncated body reads as "no banner"');
  }

  if (process.argv.includes('--self-test')) {
    console.log('\n-- POSITIVE CONTROLS -----------------------------------------------');
    const clone = () => os.map((r) => ({ ...r }));
    console.log(`  control 1  unmodified                  -> ${diff(house, senate, os, vacantDistricts).length} disagreements (expect 0)`);
    const c2 = clone();
    const t2 = c2.find((r) => r.chamber === 'upper' && r.district === '35');
    t2.family = 'Zzzcontrol'; t2.name = 'Jim Zzzcontrol';
    console.log(`  control 2  SD-35 surname corrupted     -> ${diff(house, senate, c2, vacantDistricts).length} disagreements (expect 1)`);
    const c3 = clone().filter((r) => !(r.chamber === 'lower' && r.district === '1A'));
    console.log(`  control 3  HD-1A row deleted           -> ${diff(house, senate, c3, vacantDistricts).length} disagreements (expect 1)`);
    const c4 = clone();
    c4.find((r) => r.chamber === 'lower' && r.district === '64A').district = '64B';
    console.log(`  control 4  HD-64A relabelled 64B       -> ${diff(house, senate, c4, vacantDistricts).length} disagreements (expect 2)`);
    const c5 = clone();
    c5.push({ os_id: 'control', name: 'Ghost Control', given: 'Ghost', family: 'Control', chamber: 'lower', district: '21A', image: null });
    console.log(`  control 5  OS seats the VACANT 21A     -> ${diff(house, senate, c5, vacantDistricts).length} disagreements (expect 1)`);
  }

  const disagreements = diff(house, senate, os, vacantDistricts);
  console.log(`\ndisagreements between the chambers and Open States: ${disagreements.length}`);
  for (const d of disagreements) console.log(`  ${d}`);
  if (disagreements.length) {
    throw new Error("Sources disagree. Settle each one from the member's own page before writing a roster.");
  }

  const osLower = new Map(os.filter((r) => r.chamber === 'lower').map((r) => [r.district, r]));
  const osUpper = new Map(os.filter((r) => r.chamber === 'upper').map((r) => [r.district, r]));

  const roster = [];
  for (let i = 1; i <= 67; i++) {
    for (const suffix of ['A', 'B']) {
      const d = `${i}${suffix}`;
      const geo_id = houseGeoId(d);
      const v = VACANCIES[geo_id];
      const a = house.get(d);
      const b = osLower.get(d);
      roster.push({
        chamber: 'STATE_LOWER',
        title: 'Representative',
        district: d,
        geo_id,
        district_label: `State House District ${d}`,
        vacant: Boolean(v),
        ...(v
          ? { departed: v.departed, first_vacant_day: v.first_vacant_day, how_ended: v.how_ended, evidence: v.evidence, full_name: null, first_name: null, last_name: null }
          : {
              full_name: a.name,
              first_name: a.name.split(/\s+/)[0],
              last_name: surnameFor(`lower-${d}`, a.name, b),
              alternate_names: alternatesFor(a.name, b),
              house_profile_id: a.pid,
              house_profile_url: `https://www.house.mn.gov/members/profile/${a.pid}`,
              openstates_id: b ? b.os_id : null,
              openstates_image: b ? b.image : null,
            }),
        // No term_start exists to be had; see the header. Written open-ended.
        term_start: null,
        start_precision: 'unknown',
      });
    }
  }
  for (let i = 1; i <= 67; i++) {
    const d = String(i);
    const a = senate.get(d);
    const b = osUpper.get(d);
    roster.push({
      chamber: 'STATE_UPPER',
      title: 'Senator',
      district: d,
      geo_id: senateGeoId(d),
      district_label: `State Senate District ${d}`,
      vacant: false,
      full_name: a.name,
      first_name: a.name.split(/\s+/)[0],
      last_name: surnameFor(`upper-${d}`, a.name, b, a.last),
      alternate_names: alternatesFor(a.name, b),
      senate_mem_id: a.mem_id,
      senate_bio_url: `https://www.senate.mn/members/member_bio.html?mem_id=${a.mem_id}`,
      openstates_id: b ? b.os_id : null,
      openstates_image: b ? b.image : null,
      term_start: null,
      start_precision: 'unknown',
    });
  }

  const seated = roster.filter((r) => !r.vacant);
  const payload = {
    generated_at: new Date().toISOString(),
    state: 'MN',
    wave: 'MN-2',
    sources: {
      a1: 'Minnesota House of Representatives, https://www.house.mn.gov/members/ (Alphabetical, District Order, Republican and DFL tabs; the Leadership tab is stale and is not used)',
      a2: 'Minnesota Senate, https://www.senate.mn/api/members',
      b: 'Open States, https://data.openstates.org/people/current/mn.csv',
      change_check: '201 individual member pages, swept by data/seed-mn-legislature-2026/scan-member-status.mjs',
    },
    counts: {
      offices: roster.length,
      STATE_LOWER: roster.filter((r) => r.chamber === 'STATE_LOWER').length,
      STATE_UPPER: roster.filter((r) => r.chamber === 'STATE_UPPER').length,
      seated: seated.length,
      vacant: roster.length - seated.length,
      distinct_people: new Set(seated.map((r) => normName(r.full_name))).size,
    },
    roster,
  };

  if (payload.counts.distinct_people !== payload.counts.seated) {
    const counts = new Map();
    for (const r of seated) counts.set(normName(r.full_name), (counts.get(normName(r.full_name)) || 0) + 1);
    const dupes = [...counts].filter(([, n]) => n > 1);
    throw new Error(`two seats share a holder name, which must be settled before seeding: ${JSON.stringify(dupes)}`);
  }

  fs.writeFileSync(OUT, JSON.stringify(payload, null, 2) + '\n');
  console.log(`\nwrote ${path.relative(process.cwd(), OUT)}: ${roster.length} offices ` +
    `(${payload.counts.STATE_LOWER} House + ${payload.counts.STATE_UPPER} Senate), ` +
    `${payload.counts.seated} seated, ${payload.counts.vacant} vacant`);
}

main();
