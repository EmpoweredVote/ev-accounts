#!/usr/bin/env node
/**
 * build-sc-legislature-roster.mjs — Knight program, wave SC-2.
 *
 * Reconciles the South Carolina General Assembly roster and writes
 * data/sc-legislature-roster.json. Reads nothing from the database and writes nothing to it.
 *
 * SOURCES — the chambers' own lists, plus two independent cross-checks:
 *   A. https://www.scstatehouse.gov/member.php?chamber=H|S
 *      124 House + 46 Senate cards, each carrying the member code, name, party and district.
 *      PRIMARY.
 *   B. https://data.openstates.org/people/current/sc.csv
 *      Open States. A DETECTOR, NOT AN ORACLE — a disagreement opens a reading queue against
 *      the member's own page, it never decides anything.
 *   C. gis.state.sc.us Boundaries_Districts/House_Districts and /Senate_Districts, run by the
 *      Revenue and Fiscal Affairs Office. Carries Rep_Aff / Senator per district AND a URL
 *      holding that member's scstatehouse.gov CODE. A state roster keyed to geography, and the
 *      only source here that is neither the chambers nor Open States.
 *
 * 🟢 SOURCE C CAN BE CHECKED ON THE CODE, NOT ONLY THE NAME. PA-2 could compare C only by
 * surname, which is why its stale district took reading out. Here C publishes the member's own
 * page URL, so "C names a different PERSON" is a string comparison on an identifier, and a
 * rename, a nickname or a punctuation difference cannot masquerade as a turnover. The name
 * comparison is kept as well, because a code can be right while a label is stale.
 *
 * 🔴 SOURCE C IS STILL A GIS ATTRIBUTE TABLE AND IT CAN LAG. Its editingInfo is absent, so the
 * layer cannot be asked how fresh it is — freshness is a property of a FIELD, and that field
 * does not exist here. C disagreeing is a question, never a verdict.
 *
 * 🔴🔴 A ROSTER LIST PAGE IS NOT A CHANGE-CHECK. MN-2 paid for this: house.mn.gov listed a
 * member three months after he resigned. So --change-check reads all 170 member pages and
 * asserts that each one NAMES the person the list assigned to that district, and carries no
 * departure language. A page that 200s is not evidence; NC-3 found a departed official's URL
 * serving their successor's page byte-identically.
 *
 * 🔴 NO term_start IS INVENTED. The member pages carry biography, not service dates, and
 * "first elected" is not a term start in either direction (it hid a resignation by 9 years and
 * an appointment by 6 weeks in one Knight wave). Terms are written open-ended at
 * start_precision 'unknown', the GA-2 / IN-2 / MN-2 / PA-2 pattern, unless a seat has a
 * documented arrival — those are listed in DATED_ARRIVALS and each one carries its source.
 *
 * 🔴 PARTY IS DELIBERATELY DROPPED from the output. All three sources carry it. Party lives on
 * races.primary_party in this schema, never on a person or an office.
 *
 * 🔴 A UNIFORM ANSWER IS A BROKEN DETECTOR. --self-test plants one defect per detector and
 * requires every one to be reported before the agreement is trusted.
 *
 *   node scripts/build-sc-legislature-roster.mjs
 *   node scripts/build-sc-legislature-roster.mjs --change-check   (170 member pages)
 *   node scripts/build-sc-legislature-roster.mjs --self-test
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, '..', 'data', 'sc-legislature-roster.json');
const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };

const RFA = 'https://gis.state.sc.us/arcgis/rest/services/Boundaries_Districts';

const CHAMBERS = [
  {
    key: 'house',
    body: 'H',
    seats: 124,
    mtfcc: 'G5220',
    districtType: 'STATE_LOWER',
    title: 'Representative',
    rfaService: 'House_Districts',
    rfaMember: 'Rep_Aff',
  },
  {
    key: 'senate',
    body: 'S',
    seats: 46,
    mtfcc: 'G5210',
    districtType: 'STATE_UPPER',
    title: 'Senator',
    rfaService: 'Senate_Districts',
    rfaMember: 'Senator',
  },
];

const LIST_URL = (body) => `https://www.scstatehouse.gov/member.php?chamber=${body}`;
const MEMBER_URL = (code) => `https://www.scstatehouse.gov/member.php?code=${code}`;

/**
 * Seats whose arrival is DOCUMENTED. A seat is listed here only with a source that states the
 * day the person began serving — a swearing-in, not an election night and not "first elected".
 * Everything absent from this map is written open-ended at 'unknown' precision.
 */
const OATHS = path.join(HERE, '..', 'data', 'seed-sc-legislature-2026', 'oath-dates.json');
const DATED_ARRIVALS = {};
if (fs.existsSync(OATHS)) {
  for (const r of JSON.parse(fs.readFileSync(OATHS, 'utf8'))) {
    if (!r.oath_date) continue; // an arrival line the chamber's journal does not confirm
    DATED_ARRIVALS[`${r.chamber}:${r.district}`] = {
      term_start: r.oath_date,
      precision: 'day',
      how_started: 'elected',
      source: r.journal_url,
    };
  }
}

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
const norm = (s) =>
  String(s)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z ]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

async function getText(url, tries = 3) {
  for (let i = 0; i < tries; i++) {
    try {
      const r = await fetch(url, { headers: UA });
      // 🔴 Read the STATUS. A styled error page is long, and length proves nothing.
      if (r.status !== 200) throw new Error(`HTTP ${r.status}`);
      return await r.text();
    } catch (e) {
      if (i === tries - 1) throw new Error(`${url}: ${e.message}`, { cause: e });
      await new Promise((res) => setTimeout(res, 400 * (i + 1)));
    }
  }
}

function splitCsvLine(line) {
  const out = [];
  let cur = '';
  let q = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (q) {
      if (c === '"' && line[i + 1] === '"') {
        cur += '"';
        i++;
      } else if (c === '"') q = false;
      else cur += c;
    } else if (c === '"') q = true;
    else if (c === ',') {
      out.push(cur);
      cur = '';
    } else cur += c;
  }
  out.push(cur);
  return out;
}

// ── source A: each chamber's own member list ─────────────────────────────────

// One card: the district heading carries the member code, and the membername anchor repeats it.
// Both codes are captured and compared, so a card whose two halves disagree is reported rather
// than silently resolved to whichever the regex reached first.
const CARD_RE =
  /<div class="district"><h1><a href="\/member\.php\?code=(\d+)">District (\d+)<\/a><\/h1><\/div>[\s\S]{0,600}?<a class="membername" href="\/member\.php\?code=(\d+)">(Representative|Senator)\s+([^<]+)<\/a>/g;

export function parseMemberList(html, chamberKey) {
  const rows = [];
  const defects = [];
  CARD_RE.lastIndex = 0;
  let m;
  while ((m = CARD_RE.exec(html)) !== null) {
    if (m[1] !== m[3]) {
      defects.push(`CARD_CODE_MISMATCH district ${Number(m[2])}: heading ${m[1]} vs name link ${m[3]}`);
      continue;
    }
    rows.push({
      chamber: chamberKey,
      memberId: m[1],
      district: String(Number(m[2])),
      title: m[4],
      fullName: decodeEntities(m[5]).replace(/\s+/g, ' ').trim(),
    });
  }
  return { rows, defects };
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
    links: head.indexOf('links'),
  };
  const out = { house: new Map(), senate: new Map() };
  for (const line of lines.slice(1)) {
    const f = splitCsvLine(line);
    const ch = f[ix.chamber] === 'lower' ? 'house' : f[ix.chamber] === 'upper' ? 'senate' : null;
    if (!ch) continue;
    // Open States carries the same scstatehouse.gov code in its links column. Pull it when it
    // is there: an identifier beats a name comparison, and a missing one is not an error.
    const code = (f[ix.links] || '').match(/member\.php\?code=(\d+)/)?.[1] ?? null;
    out[ch].set(String(Number(f[ix.district])), {
      name: f[ix.name],
      family: f[ix.family],
      given: f[ix.given],
      code,
    });
  }
  return out;
}

// ── source C: the state's own GIS roster ─────────────────────────────────────

export function parseRfa(json, memberField) {
  const out = new Map();
  for (const f of json.features) {
    const a = f.attributes;
    // "William R \"Bill\" Whitmire (R)" -> name without the trailing party marker.
    const label = String(a[memberField] ?? '').replace(/\s*\([A-Z]\)\s*$/, '').trim();
    out.set(String(Number(a.District_Num)), {
      label,
      code: String(a.URL ?? '').match(/member\.php\?code=(\d+)/)?.[1] ?? null,
    });
  }
  return out;
}

// ── the reconciliation ───────────────────────────────────────────────────────

export function reconcile(listRows, openStates, rfa, seats, chamberKey) {
  const findings = [];
  const byDistrict = new Map();
  for (const r of listRows) {
    if (byDistrict.has(r.district)) findings.push(`DUPLICATE_CARD district ${r.district}`);
    else byDistrict.set(r.district, r);
  }
  for (let d = 1; d <= seats; d++) {
    if (!byDistrict.has(String(d)))
      findings.push(`NO_CARD district ${d} — the list has a hole, which is what a vacancy looks like here`);
  }
  const seenCodes = new Map();
  for (const [d, r] of byDistrict) {
    if (/&[a-zA-Z#0-9]+;/.test(r.fullName)) findings.push(`UNDECODED_ENTITY district ${d}: ${r.fullName}`);
    // One person cannot hold two seats in one chamber. The code is the identity here.
    if (seenCodes.has(r.memberId))
      findings.push(`DUPLICATE_MEMBER_CODE ${r.memberId}: districts ${seenCodes.get(r.memberId)} and ${d}`);
    else seenCodes.set(r.memberId, d);

    const os = openStates.get(d);
    if (!os) findings.push(`OPENSTATES_MISSING district ${d}`);
    else {
      if (os.code && os.code !== r.memberId)
        findings.push(`OPENSTATES_CODE_DISAGREES district ${d}: list ${r.memberId} vs Open States ${os.code} ("${os.name}")`);
      else if (!norm(r.fullName).includes(norm(os.family)) && norm(r.fullName) !== norm(os.name))
        findings.push(`OPENSTATES_DISAGREES district ${d}: list "${r.fullName}" vs Open States "${os.name}"`);
    }

    const c = rfa.get(d);
    if (!c) findings.push(`RFA_MISSING district ${d}`);
    else {
      // 🟢 The identifier check first: C publishes the member's own page URL.
      if (c.code && c.code !== r.memberId)
        findings.push(`RFA_CODE_DISAGREES district ${d}: list ${r.memberId} ("${r.fullName}") vs RFA ${c.code} ("${c.label}")`);
      else if (!norm(c.label).split(' ').some((tok) => tok.length > 2 && norm(r.fullName).includes(tok)))
        findings.push(`RFA_DISAGREES district ${d}: list "${r.fullName}" vs RFA "${c.label}"`);
    }
  }
  return { byDistrict, findings, chamber: chamberKey };
}

// ── the change-check: 170 member pages ───────────────────────────────────────

const DEPARTURE_WORDS =
  /\b(resign\w*|vacan\w*|no longer (?:serv|represent)\w*|former(?:ly)? (?:represent|serv)\w*|has stepped down|passed away|died)\b/i;

async function changeCheck(byDistrict, title) {
  const results = { tested: 0, named: 0, notNamed: [], departure: [], errors: [], wrongDistrict: [] };
  const entries = [...byDistrict.entries()];
  const CONC = 6;
  for (let i = 0; i < entries.length; i += CONC) {
    const batch = entries.slice(i, i + CONC);
    await Promise.all(
      batch.map(async ([d, r]) => {
        const url = MEMBER_URL(r.memberId);
        try {
          const html = await getText(url);
          results.tested++;
          const text = decodeEntities(
            html
              .replace(/<script[\s\S]*?<\/script>/g, ' ')
              .replace(/<style[\s\S]*?<\/style>/g, ' ')
              .replace(/<[^>]+>/g, ' '),
          ).replace(/\s+/g, ' ');
          // (a) the page must NAME this person — a 200 is not evidence of identity
          const surname = r.fullName.split(' ').slice(-1)[0];
          if (norm(text).includes(norm(r.fullName)) || norm(text).includes(`${norm(title)} ${norm(surname)}`))
            results.named++;
          else results.notNamed.push(`${d} ${r.fullName} — page does not name them: ${url}`);
          // (b) the page must claim the district the list assigned
          if (!new RegExp(`District\\s+${Number(d)}\\b`).test(text))
            results.wrongDistrict.push(`${d} ${r.fullName} — page does not say "District ${Number(d)}": ${url}`);
          // (c) departure language anywhere on the member's own page
          if (DEPARTURE_WORDS.test(text)) {
            const at = text.search(DEPARTURE_WORDS);
            results.departure.push(
              `${d} ${r.fullName}: "${text.slice(Math.max(0, at - 70), at + 130).trim()}" ${url}`,
            );
          }
        } catch (e) {
          results.errors.push(`${d} ${r.fullName}: ${e.message}`);
        }
      }),
    );
    process.stdout.write(`\r    ${results.tested}/${entries.length} pages`);
  }
  process.stdout.write('\n');
  return results;
}

// ── self-test: every detector must be watched failing ────────────────────────

function selfTest() {
  let ok = true;
  const say = (pass, what) => {
    if (!pass) ok = false;
    console.log(`  ${pass ? 'PASS' : '🔴 FAIL'}  ${what}`);
  };

  const list = [
    { chamber: 'house', district: '1', memberId: '100', fullName: 'Ada Example', title: 'Representative' },
    { chamber: 'house', district: '2', memberId: '200', fullName: 'Bo Sample', title: 'Representative' },
    { chamber: 'house', district: '2', memberId: '300', fullName: 'Cy Twin', title: 'Representative' },
    { chamber: 'house', district: '4', memberId: '100', fullName: 'Ada Example', title: 'Representative' },
  ];
  const os = new Map([
    ['1', { name: 'Ada Example', family: 'Example', given: 'Ada', code: '100' }],
    ['2', { name: 'Someone Else', family: 'Else', given: 'Someone', code: '999' }],
    ['4', { name: 'Ada Example', family: 'Example', given: 'Ada', code: '100' }],
  ]);
  // district 1 is the planted C disagreement, by CODE — the shape PA-2's stale HD-12 had.
  const rfa = new Map([
    ['1', { label: 'Different Person', code: '111' }],
    ['2', { label: 'Sample', code: '200' }],
    ['4', { label: 'Ada Example', code: '100' }],
  ]);
  const { findings } = reconcile(list, os, rfa, 4, 'house');

  say(findings.some((f) => f.startsWith('DUPLICATE_CARD district 2')), 'two cards on one district are reported');
  say(findings.some((f) => f.startsWith('NO_CARD district 3')), 'a missing district is reported');
  say(
    findings.some((f) => f.startsWith('DUPLICATE_MEMBER_CODE 100')),
    'one person on two seats in one chamber is reported',
  );
  say(
    findings.some((f) => f.startsWith('OPENSTATES_CODE_DISAGREES district 2')),
    'an Open States CODE disagreement is reported',
  );
  say(findings.some((f) => f.startsWith('RFA_CODE_DISAGREES district 1')), 'an RFA CODE disagreement is reported');
  say(
    reconcile(
      [{ chamber: 'house', district: '1', memberId: '100', fullName: 'Ada Example', title: 'Representative' }],
      new Map([['1', { name: 'Ada Example', family: 'Example', given: 'Ada', code: null }]]),
      new Map([['1', { label: 'Nobody Here', code: null }]]),
      1,
      'house',
    ).findings.some((f) => f.startsWith('RFA_DISAGREES district 1')),
    'an RFA NAME disagreement is reported when neither side publishes a code',
  );
  say(decodeEntities('Di&#233;go') === 'Diégo', 'HTML entities are decoded, not stripped');
  say(!findings.some((f) => f.startsWith('UNDECODED_ENTITY')), 'decoded names raise no entity finding');
  say(
    reconcile(
      [{ chamber: 'house', district: '1', memberId: '100', fullName: 'Di&#233;go Encoded', title: 'Representative' }],
      os,
      rfa,
      1,
      'house',
    ).findings.some((f) => f.startsWith('UNDECODED_ENTITY')),
    'an UNDECODED name IS reported when the decoder is bypassed',
  );
  const cardDefect = parseMemberList(
    '<div class="district"><h1><a href="/member.php?code=111">District 5</a></h1></div>' +
      '<a class="membername" href="/member.php?code=222">Representative Split Card</a>',
    'house',
  );
  say(
    cardDefect.rows.length === 0 && cardDefect.defects.some((d) => d.startsWith('CARD_CODE_MISMATCH district 5')),
    'a card whose two codes disagree is reported and NOT used',
  );
  say(DEPARTURE_WORDS.test('Representative Smith has resigned effective June 21'), 'departure language is detected');
  say(
    DEPARTURE_WORDS.test('serves on the Vacancy Board Committee'),
    'the departure scanner is deliberately broad — "Vacancy Board" matches and is read, not auto-cleared',
  );
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

const osCsv = await getText('https://data.openstates.org/people/current/sc.csv');
const openStates = parseOpenStates(osCsv);
out.sources.open_states = { rows_house: openStates.house.size, rows_senate: openStates.senate.size };

for (const c of CHAMBERS) {
  const html = await getText(LIST_URL(c.body));
  const { rows, defects } = parseMemberList(html, c.key);

  const rfaUrl =
    `${RFA}/${c.rfaService}/FeatureServer/0/query?where=1%3D1&outFields=District_Num,${c.rfaMember},URL` +
    `&returnGeometry=false&f=json`;
  const rfaJson = JSON.parse(await getText(rfaUrl));
  const rfa = parseRfa(rfaJson, c.rfaMember);

  const { byDistrict, findings } = reconcile(rows, openStates[c.key], rfa, c.seats, c.key);
  findings.unshift(...defects);

  // Surname resolution, asserted rather than assumed.
  for (const [d, r] of byDistrict) {
    const os = openStates[c.key].get(d);
    const chamberLast = r.fullName.split(' ').slice(-1)[0];
    if (os && os.family && norm(r.fullName).includes(norm(os.family))) {
      r.lastName = os.family;
    } else {
      r.lastName = chamberLast;
      if (os && os.family)
        findings.push(
          `SURNAME_FALLBACK district ${d}: Open States "${os.family}" is not inside "${r.fullName}" — using the chamber's last token "${chamberLast}"`,
        );
    }
  }

  console.log(`${c.key}: ${byDistrict.size} of ${c.seats} districts carry a card · ${findings.length} finding(s)`);
  findings.forEach((f) => console.log(`  ${f}`));

  let cc = null;
  if (wantChangeCheck) {
    console.log(`  change-check — reading all ${byDistrict.size} member pages:`);
    cc = await changeCheck(byDistrict, c.title);
    console.log(
      `  named by their own page: ${cc.named}/${cc.tested} · district agrees: ${cc.tested - cc.wrongDistrict.length}/${cc.tested} · departure language: ${cc.departure.length} · errors: ${cc.errors.length}`,
    );
    cc.notNamed.forEach((n) => console.log(`    🔴 ${n}`));
    cc.wrongDistrict.forEach((n) => console.log(`    🔴 ${n}`));
    cc.departure.forEach((n) => console.log(`    ⚠ ${n}`));
    cc.errors.forEach((n) => console.log(`    🔴 ${n}`));
  }

  out.chambers[c.key] = {
    seats: c.seats,
    mtfcc: c.mtfcc,
    district_type: c.districtType,
    title: c.title,
    members: [...byDistrict.entries()]
      .sort((a, b) => Number(a[0]) - Number(b[0]))
      .map(([d, r]) => {
        const dated = DATED_ARRIVALS[`${c.key}:${d}`] ?? null;
        return {
          district: Number(d),
          // 🔴 THE JOIN KEY IS (mtfcc, geo_id), NEVER geo_id ALONE. '45079' is House District 79
          // AND Richland County, and every one of SC's 46 counties collides this way.
          geo_id: `45${String(d).padStart(3, '0')}`,
          mtfcc: c.mtfcc,
          full_name: r.fullName,
          // 🔴 full_name AND first_name COME FROM ONE SOURCE — the chamber's own rendering.
          // MN-2 took full_name from the chamber and first_name from Open States, wrote
          // "Steven Jacob" with first_name "Steve", and the production duplicate guard keys on
          // the PAIR — so the mismatch HID an active namesake from the reuse search entirely.
          // A FIELD PAIR A CONSTRAINT READS MUST COME FROM ONE SOURCE.
          first_name: r.fullName.split(' ')[0],
          // Open States supplies only the surname, because it splits multi-token ones correctly;
          // it is asserted to appear in the chamber's own rendering before it is used.
          last_name: r.lastName,
          member_id: r.memberId,
          bio_url: MEMBER_URL(r.memberId),
          // The chamber's own portrait, for stage 5. Read the site's photo policy BEFORE
          // harvesting these — MN's House forbade the use this pipeline makes.
          photo_url: `https://www.scstatehouse.gov/images/members/${r.memberId}.jpg`,
          term_start: dated?.term_start ?? null,
          start_precision: dated?.precision ?? 'unknown',
          how_started: dated?.how_started ?? null,
          term_source: dated?.source ?? null,
        };
      }),
    change_check: cc && {
      tested: cc.tested,
      named: cc.named,
      not_named: cc.notNamed,
      wrong_district: cc.wrongDistrict,
      departure: cc.departure,
      errors: cc.errors,
    },
  };
  out.findings.push(...findings.map((f) => `${c.key}: ${f}`));
}

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(out, null, 2) + '\n');
const total = Object.values(out.chambers).reduce((n, c) => n + c.members.length, 0);
console.log(`\nwrote ${OUT} — ${total} seats, ${out.findings.length} finding(s)`);
