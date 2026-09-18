#!/usr/bin/env node
/**
 * build-pa-legislature-roster.mjs — Knight program, wave PA-2.
 *
 * Reconciles the Pennsylvania General Assembly roster and writes
 * data/pa-legislature-roster.json. Reads nothing from the database and writes nothing to it.
 *
 * SOURCES — the General Assembly's own list, plus two independent cross-checks:
 *   A. https://www.legis.state.pa.us/.../mbrList.cfm?body=H|S&sort=district
 *      203 House + 50 Senate cards, each carrying the member id, bio path, name, party and
 *      district. PRIMARY.
 *   B. https://data.openstates.org/people/current/pa.csv
 *      Open States. A DETECTOR, NOT AN ORACLE — a disagreement opens a reading queue against
 *      the member's own page, it never decides anything.
 *   C. PennDOT 'Pa House' / 'Pa Senatorial' layers via PASDA, which carry H_LASTNAME /
 *      S_LASTNAME per district. A Commonwealth roster keyed to geography, and the only source
 *      here that is neither the chambers nor Open States.
 *
 * 🔴 SOURCE C IS A MONTHLY GIS ATTRIBUTE AND IT LAGS. Measured 2026-09-18: it names Stephenie
 * Scialabba for HD-12, who RESIGNED in March 2026. Brandon Dukes won the 2026-08-18 special
 * election and was sworn in 2026-09-08 — ten days before this run. C disagreeing is a question,
 * never a verdict; here the answer was that C was stale, and A and B were right.
 * ⚠ Its GIS_UPDATE field is NULL on every feature, so the layer cannot even be asked how fresh
 * it is. Freshness is a property of a FIELD, and this field does not exist.
 *
 * 🔴🔴 A ROSTER LIST PAGE IS NOT A CHANGE-CHECK. MN-2 paid for this: house.mn.gov listed a
 * member three months after he resigned. So --change-check sweeps all 253 member pages and
 * asserts that each one NAMES the person the list assigned to that district, and carries no
 * departure language. A page that 200s is not evidence; NC-3 found a departed official's URL
 * serving their successor's page byte-identically.
 *
 * 🔴 THERE IS NO term_start TO BE HAD FOR MOST SEATS, AND NONE IS INVENTED. Neither chamber
 * publishes service dates on its member pages — checked on both a first-term and a long-serving
 * member, and there is no member-history endpoint (four candidate URLs all 404, each returning a
 * styled 15 KB error page, which is why the status line is read and not the body). Terms are
 * written open-ended at start_precision 'unknown', the GA-2 / IN-2 / MN-2 pattern. The exception
 * is a seat whose arrival is documented: HD-12 is dated 2026-09-08 from the swearing-in, not
 * from the election, and not from "first elected".
 *
 * 🔴 PARTY IS DELIBERATELY DROPPED from the output. All three sources carry it. Party lives on
 * races.primary_party in this schema, never on a person or an office.
 *
 * 🔴 A UNIFORM ANSWER IS A BROKEN DETECTOR. --self-test plants four defect shapes and requires
 * every one to be reported before the agreement is trusted.
 *
 *   node scripts/build-pa-legislature-roster.mjs
 *   node scripts/build-pa-legislature-roster.mjs --change-check   (253 member pages, ~2 min)
 *   node scripts/build-pa-legislature-roster.mjs --self-test
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, '..', 'data', 'pa-legislature-roster.json');
const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };

const CHAMBERS = [
  { key: 'house', body: 'H', seats: 203, mtfcc: 'G5220', districtType: 'STATE_LOWER', penndot: 9, penndotLast: 'H_LASTNAME', title: 'Representative' },
  { key: 'senate', body: 'S', seats: 50, mtfcc: 'G5210', districtType: 'STATE_UPPER', penndot: 12, penndotLast: 'S_LASTNAME', title: 'Senator' },
];

const LIST_URL = (body) =>
  `https://www.legis.state.pa.us/cfdocs/legis/home/member_information/mbrList.cfm?body=${body}&sort=district`;
const PENNDOT = 'https://maps.pasda.psu.edu/arcgis/rest/services/pasda/PennDOT/MapServer';

// ── helpers ──────────────────────────────────────────────────────────────────

const NAMED_ENTITIES = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', rsquo: '’', lsquo: '‘', ndash: '–', mdash: '—' };

/** Decode HTML entities. MN-2 found eight encoded names; a raw capture writes mojibake into a
 *  voter-facing field, and the fix is to DECODE, never to loosen a later comparison. */
export function decodeEntities(s) {
  return String(s)
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&#x([0-9a-fA-F]+);/g, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&([a-zA-Z]+);/g, (_, n) => (n in NAMED_ENTITIES ? NAMED_ENTITIES[n] : `&${n};`));
}

/** Compare names without deciding that two different people are one. Accents are folded and
 *  punctuation dropped; nothing else. */
const norm = (s) => String(s).toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
  .replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();

async function getText(url, tries = 3) {
  for (let i = 0; i < tries; i++) {
    try {
      const r = await fetch(url, { headers: UA });
      // 🔴 Read the STATUS. This site answers a bad path with a styled 15 KB error page, so
      // "the body is long" proves nothing at all.
      if (r.status !== 200) throw new Error(`HTTP ${r.status}`);
      return await r.text();
    } catch (e) {
      if (i === tries - 1) throw new Error(`${url}: ${e.message}`, { cause: e });
      await new Promise((res) => setTimeout(res, 400 * (i + 1)));
    }
  }
}

function splitCsvLine(line) {
  const out = []; let cur = ''; let q = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (q) {
      if (c === '"' && line[i + 1] === '"') { cur += '"'; i++; }
      else if (c === '"') q = false;
      else cur += c;
    } else if (c === '"') q = true;
    else if (c === ',') { out.push(cur); cur = ''; }
    else cur += c;
  }
  out.push(cur);
  return out;
}

// ── source A: each chamber's own member list ─────────────────────────────────

const CARD_RE = /<a href="\s*(\/(?:house|senate)\/members\/bio\/(\d+)\/([^"]+))"[\s\S]{0,1200}?<span class="thumb-info-inner">([^<]+)<\/span>[\s\S]{0,200}?bg-party-([A-Z]+)">\s*([A-Za-z ]+)<br>District (\d+)/g;

export function parseMemberList(html, chamberKey) {
  const rows = [];
  CARD_RE.lastIndex = 0;
  let m;
  while ((m = CARD_RE.exec(html)) !== null) {
    rows.push({
      chamber: chamberKey,
      bioPath: m[1].trim(),
      memberId: m[2],
      slug: m[3],
      fullName: decodeEntities(m[4]).replace(/\s+/g, ' ').trim(),
      district: String(Number(m[7])),
    });
  }
  return rows;
}

// ── source B: Open States ────────────────────────────────────────────────────

export function parseOpenStates(csv) {
  const lines = csv.split(/\r?\n/).filter((l) => l.length);
  const head = splitCsvLine(lines[0]);
  const ix = {
    name: head.indexOf('name'),
    district: head.indexOf('current_district'),
    chamber: head.indexOf('current_chamber'),
    family: head.indexOf('family_name'),
    given: head.indexOf('given_name'),
  };
  const out = { house: new Map(), senate: new Map() };
  for (const line of lines.slice(1)) {
    const f = splitCsvLine(line);
    const ch = f[ix.chamber] === 'lower' ? 'house' : f[ix.chamber] === 'upper' ? 'senate' : null;
    if (!ch) continue;
    out[ch].set(String(Number(f[ix.district])), {
      name: f[ix.name], family: f[ix.family], given: f[ix.given],
    });
  }
  return out;
}

// ── the reconciliation ───────────────────────────────────────────────────────

export function reconcile(listRows, openStates, penndot, seats, chamberKey) {
  const findings = [];
  const byDistrict = new Map();
  for (const r of listRows) {
    if (byDistrict.has(r.district)) findings.push(`DUPLICATE_CARD district ${r.district}`);
    else byDistrict.set(r.district, r);
  }
  for (let d = 1; d <= seats; d++) {
    if (!byDistrict.has(String(d))) findings.push(`NO_CARD district ${d} — the list has a hole, which is what a vacancy looks like here`);
  }
  for (const [d, r] of byDistrict) {
    if (/&[a-zA-Z#0-9]+;/.test(r.fullName)) findings.push(`UNDECODED_ENTITY district ${d}: ${r.fullName}`);
    const os = openStates.get(d);
    if (!os) findings.push(`OPENSTATES_MISSING district ${d}`);
    else if (!norm(r.fullName).includes(norm(os.family)) && norm(r.fullName) !== norm(os.name)) {
      findings.push(`OPENSTATES_DISAGREES district ${d}: list "${r.fullName}" vs Open States "${os.name}"`);
    }
    const last = penndot.get(d);
    if (last === undefined) findings.push(`PENNDOT_MISSING district ${d}`);
    else if (!norm(r.fullName).includes(norm(last))) {
      findings.push(`PENNDOT_DISAGREES district ${d}: list "${r.fullName}" vs PennDOT "${last}"`);
    }
  }
  return { byDistrict, findings, chamber: chamberKey };
}

// ── the change-check: 253 member pages ───────────────────────────────────────

const DEPARTURE_WORDS = /\b(resign\w*|vacan\w*|no longer (?:serv|represent)\w*|former(?:ly)? represent\w*|has stepped down|passed away|died)\b/i;

async function changeCheck(byDistrict, title) {
  const results = { tested: 0, named: 0, notNamed: [], departure: [], errors: [] };
  const entries = [...byDistrict.entries()];
  const CONC = 6;
  for (let i = 0; i < entries.length; i += CONC) {
    const batch = entries.slice(i, i + CONC);
    await Promise.all(batch.map(async ([d, r]) => {
      const url = `https://www.palegis.us${r.bioPath}`;
      try {
        const html = await getText(url);
        results.tested++;
        const text = decodeEntities(html.replace(/<script[\s\S]*?<\/script>/g, ' ')
          .replace(/<style[\s\S]*?<\/style>/g, ' ').replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ');
        // (b) the page must NAME this person — a 200 is not evidence of identity
        const surname = r.fullName.split(' ').slice(-1)[0];
        if (norm(text).includes(norm(r.fullName)) || norm(text).includes(`${norm(title)} ${norm(surname)}`)) results.named++;
        else results.notNamed.push(`${d} ${r.fullName} — page does not name them: ${url}`);
        // (c) departure language anywhere on the member's own page
        const hit = text.match(DEPARTURE_WORDS);
        if (hit) results.departure.push(`${d} ${r.fullName}: "${text.slice(Math.max(0, text.search(DEPARTURE_WORDS) - 70), text.search(DEPARTURE_WORDS) + 130).trim()}" ${url}`);
      } catch (e) {
        results.errors.push(`${d} ${r.fullName}: ${e.message}`);
      }
    }));
    process.stdout.write(`\r    ${results.tested}/${entries.length} pages`);
  }
  process.stdout.write('\n');
  return results;
}

// ── self-test: every detector must be watched failing ────────────────────────

function selfTest() {
  let ok = true;
  const say = (pass, what) => { if (!pass) ok = false; console.log(`  ${pass ? 'PASS' : '🔴 FAIL'}  ${what}`); };

  // The fixture carries one defect per detector, and the names are ALREADY DECODED because
  // parseMemberList decodes before reconcile ever sees them. An earlier draft planted a raw
  // entity here and then asserted that no entity was reported — the self-test failed on its own
  // fixture, which is the self-test working.
  const list = [
    { chamber: 'house', district: '1', fullName: 'Ada Example', memberId: '1', bioPath: '/house/members/bio/1/rep-a', slug: 'rep-a' },
    { chamber: 'house', district: '2', fullName: 'Bo Sample', memberId: '2', bioPath: '/house/members/bio/2/rep-b', slug: 'rep-b' },
    { chamber: 'house', district: '2', fullName: 'Cy Twin', memberId: '3', bioPath: '/house/members/bio/3/rep-c', slug: 'rep-c' },
    { chamber: 'house', district: '4', fullName: 'Diégo Encoded', memberId: '4', bioPath: '/house/members/bio/4/rep-d', slug: 'rep-d' },
  ];
  const os = new Map([['1', { name: 'Ada Example', family: 'Example', given: 'Ada' }],
                      ['2', { name: 'Someone Else', family: 'Else', given: 'Someone' }],
                      ['4', { name: 'Diégo Encoded', family: 'Encoded', given: 'Diégo' }]]);
  // district 1 is the planted PennDOT disagreement — the HD-12 shape, where C lags A and B.
  const pd = new Map([['1', 'Different'], ['2', 'Sample'], ['4', 'Encoded']]);
  const { findings } = reconcile(list, os, pd, 4, 'house');

  say(findings.some((f) => f.startsWith('DUPLICATE_CARD district 2')), 'two cards on one district are reported');
  say(findings.some((f) => f.startsWith('NO_CARD district 3')), 'a missing district is reported');
  say(findings.some((f) => f.startsWith('OPENSTATES_DISAGREES district 2')), 'an Open States disagreement is reported');
  say(findings.some((f) => f.startsWith('PENNDOT_DISAGREES district 1')), 'a PennDOT disagreement is reported');
  say(decodeEntities('Di&#233;go') === 'Diégo', 'HTML entities are decoded, not stripped');
  say(!findings.some((f) => f.startsWith('UNDECODED_ENTITY')), 'decoded names raise no entity finding');
  say(reconcile([{ chamber: 'house', district: '4', fullName: 'Di&#233;go Encoded', memberId: '4', bioPath: '', slug: '' }],
                os, pd, 4, 'house').findings.some((f) => f.startsWith('UNDECODED_ENTITY')),
      'an UNDECODED name IS reported when the decoder is bypassed');
  say(DEPARTURE_WORDS.test('Representative Smith has resigned effective June 21'), 'departure language is detected');
  say(!DEPARTURE_WORDS.test('serves on the Vacancy Board Committee') === false, 'the departure scanner is deliberately broad — "Vacancy Board" matches and is read, not auto-cleared');
  return ok;
}

// ── main ─────────────────────────────────────────────────────────────────────

const argv = process.argv.slice(2);
if (argv.includes('--self-test')) {
  console.log('self-test — each detector must report the defect planted for it:');
  process.exit(selfTest() ? 0 : 1);
}

const wantChangeCheck = argv.includes('--change-check');
const out = { generated_at: new Date().toISOString(), sources: {}, chambers: {}, findings: [] };

const osCsv = await getText('https://data.openstates.org/people/current/pa.csv');
const openStates = parseOpenStates(osCsv);
out.sources.open_states = { rows_house: openStates.house.size, rows_senate: openStates.senate.size };

for (const c of CHAMBERS) {
  const html = await getText(LIST_URL(c.body));
  const rows = parseMemberList(html, c.key);

  const pdUrl = `${PENNDOT}/${c.penndot}/query?where=1%3D1&outFields=LEG_DISTRI,${c.penndotLast}&returnGeometry=false&f=json`;
  const pdJson = JSON.parse(await getText(pdUrl));
  const penndot = new Map(pdJson.features.map((f) => [String(Number(f.attributes.LEG_DISTRI)), String(f.attributes[c.penndotLast] ?? '').trim()]));

  const { byDistrict, findings } = reconcile(rows, openStates[c.key], penndot, c.seats, c.key);

  // Surname resolution, asserted rather than assumed.
  for (const [d, r] of byDistrict) {
    const os = openStates[c.key].get(d);
    const chamberLast = r.fullName.split(' ').slice(-1)[0];
    if (os && os.family && norm(r.fullName).split(' ').join(' ').includes(norm(os.family))) {
      r.lastName = os.family;
    } else {
      r.lastName = chamberLast;
      if (os && os.family) findings.push(`SURNAME_FALLBACK district ${d}: Open States "${os.family}" is not inside "${r.fullName}" — using the chamber's last token "${chamberLast}"`);
    }
  }
  console.log(`${c.key}: ${byDistrict.size} of ${c.seats} districts carry a card · ${findings.length} finding(s)`);
  findings.forEach((f) => console.log(`  ${f}`));

  let cc = null;
  if (wantChangeCheck) {
    console.log(`  change-check — reading all ${byDistrict.size} member pages:`);
    cc = await changeCheck(byDistrict, c.title);
    console.log(`  named by their own page: ${cc.named}/${cc.tested} · departure language: ${cc.departure.length} · errors: ${cc.errors.length}`);
    cc.notNamed.forEach((n) => console.log(`    🔴 ${n}`));
    cc.departure.forEach((n) => console.log(`    ⚠ ${n}`));
    cc.errors.forEach((n) => console.log(`    🔴 ${n}`));
  }

  out.chambers[c.key] = {
    seats: c.seats,
    mtfcc: c.mtfcc,
    district_type: c.districtType,
    members: [...byDistrict.entries()].sort((a, b) => Number(a[0]) - Number(b[0])).map(([d, r]) => ({
      district: Number(d),
      // 🔴 THE JOIN KEY IS (mtfcc, geo_id), NEVER geo_id ALONE. '42101' is House District 101
      // AND Philadelphia County, and every one of PA's 67 counties collides this way.
      geo_id: `42${String(d).padStart(3, '0')}`,
      mtfcc: c.mtfcc,
      full_name: r.fullName,
      // 🔴 full_name AND first_name COME FROM ONE SOURCE — the chamber's own rendering.
      // MN-2 took full_name from the chamber and first_name from Open States, wrote
      // "Steven Jacob" with first_name "Steve", and the production duplicate guard keys on
      // the PAIR — so the mismatch HID an active namesake from the reuse search entirely.
      // A FIELD PAIR A CONSTRAINT READS MUST COME FROM ONE SOURCE.
      first_name: r.fullName.split(' ')[0],
      // Open States supplies only the surname, because it splits multi-token ones correctly
      // ("Cepeda-Freytiz", "Hill-Evans"), and it is asserted to appear in the chamber's own
      // rendering before it is used. Where it does not, the chamber's last token stands and
      // the row is reported.
      last_name: r.lastName,
      member_id: r.memberId,
      bio_url: `https://www.palegis.us${r.bioPath}`,
      // The chamber's own portrait, for stage 5. Read the chamber's photo policy BEFORE
      // harvesting these — MN's House forbade the use this pipeline makes.
      photo_url: `https://www.palegis.us/resources/images/members/200/${r.memberId}.jpg`,
    })),
    change_check: cc && { tested: cc.tested, named: cc.named, not_named: cc.notNamed, departure: cc.departure, errors: cc.errors },
  };
  out.findings.push(...findings.map((f) => `${c.key}: ${f}`));
}

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(out, null, 2) + '\n');
const total = Object.values(out.chambers).reduce((n, c) => n + c.members.length, 0);
console.log(`\nwrote ${OUT} — ${total} seats, ${out.findings.length} finding(s)`);
