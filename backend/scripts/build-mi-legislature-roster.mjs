#!/usr/bin/env node
/**
 * build-mi-legislature-roster.mjs — Knight program, wave MI-2.
 *
 * Reconciles the Michigan Legislature roster and writes data/mi-legislature-roster.json.
 * Reads nothing from the database and writes nothing to it.
 *
 * SOURCES — the Legislature's own combined list, each chamber's own list, and one aggregator:
 *   A. https://legislature.mi.gov/Legislature/Legislators
 *      PRIMARY. The Legislative Service Bureau's combined list: all 148 seats in one document,
 *      each card carrying the member's name, chamber, district and own web page. It is neither
 *      chamber's roster, which matters here more than usual — see the caucus trap below.
 *   B. https://senate.michigan.gov/senators/all-senators/
 *      The Senate's own list. The roster is a JSON array in the `senatorInfo` attribute of a
 *      <senator-list> element, HTML-entity-encoded in the served markup. Structured first /
 *      last / middle / district, so it checks A's name splitting rather than just its spelling.
 *   C. https://house.mi.gov/AllRepresentatives
 *      The House's own list. 🔴🔴 IT IS THE UNION OF THE TWO CAUCUS LISTS, NOT A ROSTER OF THE
 *      CHAMBER — every row links to gophouse.org or housedems.com. Used as a DETECTOR of
 *      caucus membership, never as the seat count.
 *   D. https://data.openstates.org/people/current/mi.csv
 *      Open States. A DETECTOR, NOT AN ORACLE — a disagreement opens a reading queue against
 *      the member's own page, it never decides anything.
 *
 * 🔴🔴 THE TRAP THIS WAVE PAID FOR: AN ABSENCE ON A CHAMBER'S OWN ROSTER IS NOT A VACANCY.
 * Source C lists 109 of 110 districts. District 4 is missing entirely, and 58 R + 51 D = 109
 * looks exactly like a one-seat vacancy. IT IS NOT. Karen Whitsett (HD-4, Detroit) announced in
 * March 2026 that she was leaving the Democratic Party and would not seek re-election; she
 * still holds the seat until the term ends 2026-12-31. Because C is assembled from the two
 * CAUCUS websites, a member who belongs to neither caucus has no row to render. Source A, which
 * is the Legislature's own list rather than a caucus list, carries her.
 * ▶ Seating HD-4 as vacant would have deleted a sitting representative from every address in
 *   her district. The gate below asserts C's gap is explained, never that C is complete.
 * ⚠ And A still links her to `housedems.com/whitsett`, the caucus she left. A stale link is not
 *   a departure either; the change-check reads for departure LANGUAGE, not for a 404.
 *
 * 🔴 A CONNECTION FAILURE IS NOT AN ABSENCE. `legislature.mi.gov` and `house.mi.gov` serve only
 * their leaf certificate — no intermediate — so Node and curl both fail with
 * UNABLE_TO_VERIFY_LEAF_SIGNATURE while a browser succeeds, because a browser fetches the
 * missing intermediate from the certificate's own AIA extension. This script does the same
 * thing honestly: it adds the two DigiCert intermediates to the system roots. It does NOT
 * disable verification. `--tls-control` proves the point in both directions.
 *
 * 🔴🔴 A ROSTER LIST PAGE IS NOT A CHANGE-CHECK. MN-2 paid for this: house.mn.gov listed a
 * member three months after he resigned. So --change-check reads all 148 member pages and
 * asserts each one NAMES the person the list assigned to that district, and carries no
 * departure language.
 *
 * 🔴 NO term_start IS INVENTED. Michigan's member pages carry biography, not service dates, and
 * "first elected" is not a term start in either direction. Terms are written open-ended at
 * start_precision 'unknown' — the GA-2 / IN-2 / MN-2 / OH-2 pattern — unless a seat has a
 * documented arrival, which goes in DATED_ARRIVALS with its source.
 *
 * 🔴 PARTY IS DELIBERATELY DROPPED from the output. All four sources carry it. Party lives on
 * races.primary_party in this schema, never on a person or an office. It is carried internally
 * only to explain source C's gap, and it is not written to the roster file.
 *
 * 🔴 A UNIFORM ANSWER IS A BROKEN DETECTOR. --self-test plants one defect per detector and
 * requires every one to be reported before any agreement is trusted.
 *
 *   node scripts/build-mi-legislature-roster.mjs
 *   node scripts/build-mi-legislature-roster.mjs --change-check    (148 member pages)
 *   node scripts/build-mi-legislature-roster.mjs --self-test
 *   node scripts/build-mi-legislature-roster.mjs --tls-control
 */
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import * as http from 'http';
import * as tls from 'tls';
import { fileURLToPath } from 'url';
import * as cheerio from 'cheerio';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DATA = path.join(HERE, '..', 'data');
const OUT = path.join(DATA, 'mi-legislature-roster.json');
const CA_DIR = path.join(DATA, 'seed-mi-2026', '_ca');
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

const argv = process.argv.slice(2);
const SELF_TEST = argv.includes('--self-test');
const CHANGE_CHECK = argv.includes('--change-check');
const TLS_CONTROL = argv.includes('--tls-control');

const SRC = {
  A: 'https://legislature.mi.gov/Legislature/Legislators',
  B: 'https://senate.michigan.gov/senators/all-senators/',
  C: 'https://house.mi.gov/AllRepresentatives',
  D: 'https://data.openstates.org/people/current/mi.csv',
};

// The two intermediates these hosts omit, identified from each leaf certificate's own AIA
// "CA Issuers" URL. Downloaded on demand and cached; DER is converted with a pure-JS wrap.
const INTERMEDIATES = [
  'http://cacerts.digicert.com/DigiCertGlobalG2TLSRSASHA2562020CA1-1.crt', // legislature.mi.gov
  'http://cacerts.digicert.com/DigiCertGlobalG3TLSECCSHA3842020CA1-2.crt', // house.mi.gov
];

// 🔴🔴 THE PRIMARY SOURCE IS NOT RIGHT ABOUT EVERYTHING, AND THE DETECTOR CAUGHT IT.
// Source A — the Legislature's own combined list — drops a middle name that the member uses as
// part of her name. Source C, which this script treats only as a caucus detector, had it right.
// Settled where it should be settled: on the member's OWN page, whose <h1> is the evidence.
// An override here must name the district, both readings, and the page that decided it.
const NAME_OVERRIDES = [
  {
    chamber: 'lower', district: 7,
    from: 'Tonya Phillips', to: 'Tonya Myers Phillips',
    why: 'housedems.com/Tonya-Myers-Phillips/ <h1> reads "State Representative Tonya Myers Phillips" and the page names District 7; legislature.mi.gov omits "Myers". Read 2026-09-24.',
  },
];

// 🔴 TWO SEATS WHOSE LINK ON THE LEGISLATURE'S LIST DOES NOT REACH A PAGE ABOUT THE MEMBER.
// Neither is a departure, and each was confirmed from sources that are not the broken link.
// A stale link is a fact about a link.
const WEB_PAGE_OVERRIDES = [
  {
    chamber: 'lower', district: 101,
    to: 'https://gophouse.org/member/RepJosephFox/posts',
    why: 'legislature.mi.gov links HD-101 to house.mi.gov/repdetail/repJosephFox, which returns HTTP 404. The caucus page titled "Joseph Fox Posts | Michigan House Republicans" names him and District 101. Read 2026-09-24.',
  },
  {
    chamber: 'lower', district: 4,
    to: null,
    why: 'Karen Whitsett left the Democratic Party in March 2026, so she has no caucus page; legislature.mi.gov still links her to housedems.com/whitsett, which REDIRECTS TO THE CAUCUS HOME PAGE and answers HTTP 200 with an <h1> of "Michigan House Democrats". She is confirmed to hold HD-4 by the Legislature\'s own list and by Open States, and she is not resigning — she announced she will not seek re-election, with the term ending 2026-12-31. No member page exists to read. Read 2026-09-24.',
  },
];

const findings = [];
const finding = (code, detail) => {
  findings.push({ code, detail });
  console.log(`  ${code}: ${detail}`);
};

// ── transport ───────────────────────────────────────────────────────────────
const derToPem = (der) => {
  const b64 = Buffer.from(der).toString('base64').match(/.{1,64}/g).join('\n');
  return `-----BEGIN CERTIFICATE-----\n${b64}\n-----END CERTIFICATE-----\n`;
};

function rawGet(url, agent, redirects = 5) {
  return new Promise((resolve, reject) => {
    // 🔴 THIS LINE READ `require('http')` AND THIS IS AN ESM MODULE, SO EVERY PLAIN-HTTP URL
    // THREW "require is not defined". The change-check reported 47 member pages as UNREACHABLE
    // — a detector failure wearing the costume of 47 findings. Every one of the 47 was an
    // `http://` Republican member site; the Democratic sites are https and passed, so the
    // failure even looked like a plausible partisan pattern. ▶ A finding that correlates with
    // something structural about the SOURCE is a reason to suspect the DETECTOR.
    // ⚠ AND THE FIRST FIX WAS ALSO WRONG, THE SAME 48 ROWS AGAIN: an https.Agent handed to
    // http.get is rejected with 'Protocol "http:" not supported'. The agent exists only to add
    // the two missing intermediates, which is a TLS concern, so plain-HTTP requests must not
    // carry it. ▶ Two consecutive uniform answers of 48 were two different bugs in the same
    // line; the count not moving is what said the second fix had not landed either.
    const isHttp = url.startsWith('http://');
    const mod = isHttp ? http : https;
    const req = mod.get(url, { agent: isHttp ? undefined : agent, headers: { 'User-Agent': UA } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location && redirects > 0) {
        res.resume();
        return rawGet(new URL(res.headers.location, url).toString(), agent, redirects - 1).then(resolve, reject);
      }
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => resolve({ status: res.statusCode, body: Buffer.concat(chunks) }));
    });
    req.on('error', reject);
    req.setTimeout(60000, () => req.destroy(new Error('timeout')));
  });
}

async function buildAgent() {
  fs.mkdirSync(CA_DIR, { recursive: true });
  const pems = [];
  for (const url of INTERMEDIATES) {
    const cache = path.join(CA_DIR, path.basename(url).replace(/\.crt$/, '.pem'));
    if (!fs.existsSync(cache)) {
      const { status, body } = await rawGet(url, undefined);
      if (status !== 200 || body.length < 200) throw new Error(`intermediate ${url} -> HTTP ${status}, ${body.length} bytes`);
      fs.writeFileSync(cache, derToPem(body));
    }
    pems.push(fs.readFileSync(cache, 'utf8'));
  }
  return new https.Agent({ ca: [...tls.rootCertificates, ...pems], keepAlive: true });
}

let AGENT;
const getText = async (url) => {
  const { status, body } = await rawGet(url, AGENT);
  if (status !== 200) throw new Error(`${url} -> HTTP ${status}`);
  return body.toString('utf8');
};

// ── source A: the Legislature's own combined list (PRIMARY) ─────────────────
function parseA(html) {
  const $ = cheerio.load(html);
  const rows = [];
  $('.micard').each((_, el) => {
    const a = $(el)
      .find('a')
      .filter((__, x) => /^(House|Senate) District\s*\d+$/.test($(x).text().replace(/\s+/g, ' ').trim()))
      .first();
    if (!a.length) return;
    const m = a.text().replace(/\s+/g, ' ').trim().match(/^(House|Senate) District\s*(\d+)$/);
    const name = $(el).parent().parent().prev().text().replace(/\s+/g, ' ').trim();
    const web = $(el)
      .find('a')
      .filter((__, x) => /^Web Page$/i.test($(x).text().trim()))
      .first();
    rows.push({
      chamber: m[1] === 'House' ? 'lower' : 'upper',
      district: parseInt(m[2], 10),
      name,
      webPage: web.length ? (web.attr('href') || '').trim() : null,
    });
  });
  return rows;
}

// ── source B: the Senate's own list, from the senatorInfo attribute ─────────
function parseB(html) {
  const m = html.match(/senatorInfo\s*=\s*"([^"]*)"/i) || html.match(/senatorInfo\s*=\s*'([^']*)'/i);
  if (!m) throw new Error('senatorInfo attribute not found — the Senate page changed shape');
  const decoded = m[1]
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, '&');
  return JSON.parse(decoded).map((s) => ({
    chamber: 'upper',
    district: parseInt(s.district, 10),
    first: (s.firstName || '').trim(),
    last: (s.lastName || '').trim(),
    party: (s.party || '').trim(),
  }));
}

// ── source C: the House list, which is the union of the two caucus lists ────
function parseC(html) {
  const $ = cheerio.load(html);
  const seen = new Map();
  $('a.page-search-target').each((_, el) => {
    const t = $(el).text().replace(/\s+/g, ' ').trim();
    const m = t.match(/^(.+?),\s*Rep\.\s*(.+?)\s*\((Republican|Democrat[a-z]*)\)\s*District-?\s*(\d+)/i);
    if (!m) return;
    const d = parseInt(m[4], 10);
    const host = (($(el).attr('href') || '').match(/^https?:\/\/([^/]+)/) || [])[1] || '';
    seen.set(d, { district: d, last: m[1].trim(), first: m[2].trim(), party: m[3], caucusHost: host });
  });
  return [...seen.values()];
}

// ── source D: Open States ───────────────────────────────────────────────────
function parseD(csv) {
  const lines = csv.split(/\r?\n/).filter((l) => l.trim());
  const head = lines[0].split(',');
  const idx = (n) => head.indexOf(n);
  const splitCsv = (line) => {
    const out = [];
    let cur = '';
    let q = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') {
        if (q && line[i + 1] === '"') { cur += '"'; i++; } else q = !q;
      } else if (ch === ',' && !q) { out.push(cur); cur = ''; } else cur += ch;
    }
    out.push(cur);
    return out;
  };
  const iName = idx('name'), iDist = idx('current_district'), iChamber = idx('current_chamber');
  if (iName < 0 || iDist < 0 || iChamber < 0) throw new Error(`Open States CSV columns changed: ${head.slice(0, 12).join(',')}`);
  return lines.slice(1).map(splitCsv).map((c) => ({
    chamber: c[iChamber],
    district: parseInt(c[iDist], 10),
    name: (c[iName] || '').trim(),
  })).filter((r) => r.chamber === 'lower' || r.chamber === 'upper');
}

// ── name comparison: a detector, deliberately loose on decoration ───────────
const norm = (s) =>
  (s || '')
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/\b(jr|sr|ii|iii|iv|dr|rep|sen)\b\.?/g, '')
    .replace(/[^a-z ]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
const lastOf = (full) => { const p = norm(full).split(' ').filter(Boolean); return p[p.length - 1] || ''; };
// 🔴 `lastOf` TAKES THE LAST TOKEN, WHICH IS NOT A SURNAME. Normalisation turns "Jenkins-Arno"
// into "jenkins arno", "St. Germaine" into "st germaine" and "O'Neal" into "o neal", so
// comparing a last TOKEN against a whole surname FIELD reported three identical names as
// disagreements. Compare the surname field against the TAIL of the full name instead.
const surnameMatches = (fullName, surnameField) => {
  const f = norm(fullName), sn = norm(surnameField);
  return !!sn && (f === sn || f.endsWith(' ' + sn));
};
const firstOf = (full) => { const p = norm(full).split(' ').filter(Boolean); return p[0] || ''; };

// ── run ─────────────────────────────────────────────────────────────────────
console.log('Knight MI-2 — Michigan Legislature roster reconciliation\n');
AGENT = await buildAgent();

if (TLS_CONTROL) {
  // 🔴 A control that proves the chain fix is doing work, in BOTH directions: the two hosts
  // must FAIL on the default trust store and SUCCEED with the intermediates, and a host that
  // is fine either way must stay fine — otherwise the "fix" is masking something.
  const bare = new https.Agent();
  const probe = async (host, agent) => {
    try { const r = await rawGet(`https://${host}/`, agent); return `HTTP ${r.status}`; } catch (e) { return `ERROR ${e.code || e.message}`; }
  };
  let ok = true;
  for (const host of ['legislature.mi.gov', 'house.mi.gov']) {
    const d = await probe(host, bare); const f = await probe(host, AGENT);
    console.log(`  ${host}: default roots ${d} · with intermediates ${f}`);
    if (!d.startsWith('ERROR') || !f.startsWith('HTTP 200')) { ok = false; console.log(`    🔴 expected default to FAIL and the fix to succeed`); }
  }
  const d = await probe('senate.michigan.gov', bare); const f = await probe('senate.michigan.gov', AGENT);
  console.log(`  senate.michigan.gov: default roots ${d} · with intermediates ${f}`);
  if (!d.startsWith('HTTP 200') || !f.startsWith('HTTP 200')) { ok = false; console.log('    🔴 the control host should be fine either way'); }
  console.log(ok ? '\n✅ TLS control passed — the chain fix is necessary, sufficient, and masks nothing.' : '\n🔴 TLS control FAILED.');
  process.exit(ok ? 0 : 1);
}

console.log('fetching sources...');
const [htmlA, htmlB, htmlC, csvD] = await Promise.all([getText(SRC.A), getText(SRC.B), getText(SRC.C), getText(SRC.D)]);

let A = parseA(htmlA);
for (const ov of NAME_OVERRIDES) {
  const row = A.find((r) => r.chamber === ov.chamber && r.district === ov.district);
  if (!row) { console.log(`  🔴 NAME_OVERRIDE for ${ov.chamber}-${ov.district} matches no seat — the roster changed shape`); process.exitCode = 1; }
  else if (row.name !== ov.from) { console.log(`  🔴 NAME_OVERRIDE for ${ov.chamber}-${ov.district} expected "${ov.from}" and source A now says "${row.name}" — re-read before trusting the override`); process.exitCode = 1; }
  else { row.name = ov.to; row.name_override = ov; }
}
let B = parseB(htmlB);
let C = parseC(htmlC);
let D = parseD(csvD);

if (SELF_TEST) {
  console.log('🧪 --self-test: planting one defect per detector. Every one must be reported.\n');
  A = A.filter((r) => !(r.chamber === 'upper' && r.district === 7));          // 1 missing seat
  A = A.map((r) => (r.chamber === 'lower' && r.district === 12 ? { ...r, name: 'Wrongname Person' } : r)); // 2 A/B/D name clash
  B = B.map((r) => (r.district === 3 ? { ...r, district: 5 } : r));            // 3 duplicate district in B
  C = C.filter((r) => r.district !== 77);                                      // 4 a SECOND unexplained C gap
  D = D.map((r) => (r.chamber === 'lower' && r.district === 30 ? { ...r, name: 'Somebody Else' } : r)); // 5 D disagreement
}

console.log(`  A legislature.mi.gov : ${A.length} seats (${A.filter((r) => r.chamber === 'lower').length} House, ${A.filter((r) => r.chamber === 'upper').length} Senate)`);
console.log(`  B senate.michigan.gov: ${B.length} senators`);
console.log(`  C house.mi.gov       : ${C.length} representatives (caucus union)`);
console.log(`  D Open States        : ${D.length} legislators\n`);

console.log('findings:');

// ── 1. A must be complete: 110 + 38, no gaps, no duplicates ────────────────
const EXPECT = { lower: 110, upper: 38 };
const byKey = new Map();
for (const r of A) {
  const k = `${r.chamber}-${r.district}`;
  if (byKey.has(k)) finding('A_DUPLICATE', `source A lists ${k} twice: ${byKey.get(k).name} and ${r.name}`);
  byKey.set(k, r);
}
for (const [chamber, n] of Object.entries(EXPECT)) {
  for (let d = 1; d <= n; d++) if (!byKey.has(`${chamber}-${d}`)) finding('A_MISSING_SEAT', `source A has no ${chamber} district ${d}`);
  const got = A.filter((r) => r.chamber === chamber).length;
  if (got !== n) finding('A_COUNT', `source A has ${got} ${chamber} seats, the constitution fixes ${n}`);
}

// ── 2. B checks A's Senate names, on a structured split ────────────────────
const bByDistrict = new Map();
for (const r of B) {
  if (bByDistrict.has(r.district)) finding('B_DUPLICATE', `source B lists Senate district ${r.district} twice`);
  bByDistrict.set(r.district, r);
}
for (const r of A.filter((x) => x.chamber === 'upper')) {
  const b = bByDistrict.get(r.district);
  if (!b) { finding('B_MISSING', `the Senate's own list has no district ${r.district} (A says ${r.name})`); continue; }
  if (!surnameMatches(r.name, b.last)) finding('AB_NAME_DISAGREES', `Senate ${r.district}: A "${r.name}" vs B "${b.first} ${b.last}"`);
}

// ── 3. C is the caucus union. Its gaps must each be EXPLAINED, one by one ──
// 🔴🔴 This is the assertion that stops HD-4 being seated as vacant. C is allowed to be short,
// but every seat it omits has to be a seat source A fills with a named member. A gap that A
// ALSO cannot fill is a real vacancy and must be investigated, not assumed either way.
const cDistricts = new Set(C.map((r) => r.district));
const cGaps = [];
for (let d = 1; d <= EXPECT.lower; d++) if (!cDistricts.has(d)) cGaps.push(d);
for (const d of cGaps) {
  const a = byKey.get(`lower-${d}`);
  if (!a) finding('REAL_VACANCY_CANDIDATE', `House ${d} is missing from BOTH the caucus union and the Legislature's list — investigate before seating`);
  else finding('CAUCUS_GAP_EXPLAINED', `House ${d} absent from house.mi.gov (the caucus union) but held by ${a.name} per the Legislature's own list — NOT a vacancy`);
}
for (const r of C) {
  const a = byKey.get(`lower-${r.district}`);
  if (!a) { finding('C_EXTRA', `the caucus union lists House ${r.district} (${r.first} ${r.last}) and the Legislature's list does not`); continue; }
  if (!surnameMatches(a.name, r.last)) finding('AC_NAME_DISAGREES', `House ${r.district}: A "${a.name}" vs C "${r.first} ${r.last}"`);
}

// ── 4. D is a detector. A disagreement opens a reading queue. ──────────────
const dByKey = new Map();
for (const r of D) dByKey.set(`${r.chamber}-${r.district}`, r);
for (const [k, a] of byKey) {
  const d = dByKey.get(k);
  if (!d) { finding('OPENSTATES_MISSING', `Open States has no ${k} (A says ${a.name})`); continue; }
  // 🔴 A DETECTOR THAT FIRES 17 TIMES ON "Gregory" vs "Greg" HIDES THE ONE THAT MATTERS.
  // Split the class rather than loosen the test: a shared surname plus a first name that is a
  // prefix, an initial or a common short form is a LABEL difference and is reported without
  // blocking; a different surname, or two unrelated first names, is a PERSON difference.
  const sameLast = lastOf(a.name) === lastOf(d.name);
  const fa = firstOf(a.name), fd = firstOf(d.name);
  const nicknameish = fa.startsWith(fd) || fd.startsWith(fa) || fa[0] === fd[0];
  if (!sameLast || (!nicknameish && fa !== fd)) {
    finding('OPENSTATES_DISAGREES', `${k}: A "${a.name}" vs Open States "${d.name}" — read the member page`);
  } else if (fa !== fd) {
    finding('OPENSTATES_NICKNAME', `${k}: A "${a.name}" vs Open States "${d.name}" — same surname, short form`);
  }
}
for (const [k, d] of dByKey) if (!byKey.has(k)) finding('OPENSTATES_EXTRA', `Open States has ${k} (${d.name}) and the Legislature's list does not`);

// ── 5. Nobody may hold two seats ───────────────────────────────────────────
const byPerson = new Map();
for (const r of A) {
  const k = norm(r.name);
  if (!byPerson.has(k)) byPerson.set(k, []);
  byPerson.get(k).push(`${r.chamber}-${r.district}`);
}
for (const [k, seats] of byPerson) if (seats.length > 1) finding('PERSON_HOLDS_TWO_SEATS', `"${k}" appears on ${seats.join(' and ')}`);

// ── change-check: read every member page ───────────────────────────────────
const DEPARTURE = /\b(resign(ed|ation)?|stepp(ed|ing) down|no longer (serv|represent|a member)|former (state )?(representative|senator)|vacan(t|cy)|succeed(ed|s) (the )?(late|former)|passed away|sworn in as (?!a member))\b/i;
// 🔴 THE MEMBER PAGES EMBED A LIVE SOCIAL FEED, AND IT IS NOT ABOUT THE MEMBER'S TENURE.
// HD-69 Jasper Martus was flagged "passed away" — the phrase belongs to a condolence post about
// a police officer in his Facebook feed. Cut the feed before reading for departure language;
// its own marker is the "See MoreSee Less" control the embed renders on every post.
const stripFeed = (t) => { const i = t.search(/See MoreSee Less|Comments Box SVG icons/i); return i > 0 ? t.slice(0, i) : t; };
// 🔴 AND A DEAD MEMBER LINK CAN RETURN HTTP 200. housedems.com/whitsett REDIRECTS TO THE CAUCUS
// HOME PAGE and answers 200 with a valid page that simply is not hers. Status is not the test;
// whether the page's own title and <h1> name this member is. See the notTheirPage check below.
let changeCheck = null;
if (CHANGE_CHECK) {
  console.log('\nchange-check — reading all 148 member pages (a list page is not a change-check):');

  // 🔴 A POSITIVE CONTROL ON THE MATCHER ITSELF, RUN EVERY TIME. Two successive versions of the
  // name test were broken (an ESM `require`, then a backspace escape) and each reported a large
  // uniform count that looked like a finding about Michigan. This control proves the matcher can
  // say YES and can say NO before a single page is fetched, on the four surname shapes that
  // actually occur here. If it fails, the sweep does not run at all.
  {
    const matches = (pageText, surname) => ` ${norm(pageText)} `.includes(` ${norm(surname)} `);
    const cases = [
      ['State Representative Alicia St. Germaine of District 62', 'St. Germaine', true],
      ['Rep. Amos O’Neal represents the 94th', "O'Neal", true],
      ['State Representative Tonya Myers Phillips', 'Myers Phillips', true],
      ['Senator Joseph N. Bellino Jr. of Monroe', 'Bellino', true],
      ['Welcome to the Michigan House Democrats home page', 'Whitsett', false],
      ['A page about somebody else entirely', 'Albert', false],
    ];
    const bad = cases.filter(([t, s, want]) => matches(t, s) !== want);
    if (bad.length) {
      console.log(`  🔴 MATCHER CONTROL FAILED on ${bad.length} case(s): ${bad.map(([, s]) => s).join(', ')}`);
      console.log('     Refusing to sweep 148 pages with a detector that cannot be trusted.');
      process.exit(2);
    }
    console.log(`  ✅ matcher control: ${cases.length}/${cases.length} (it can say yes, and it can say no)`);
  }

  changeCheck = { read: 0, unreachable: [], noPageByDesign: [], nameNotFound: [], notTheirPage: [], departureLanguage: [] };
  for (const r of A) {
    const ov = WEB_PAGE_OVERRIDES.find((o) => o.chamber === r.chamber && o.district === r.district);
    if (ov) {
      r.web_page_override = ov;
      r.webPage = ov.to;
      if (ov.to === null) { changeCheck.noPageByDesign.push(`${r.chamber}-${r.district} ${r.name}: ${ov.why}`); continue; }
    }
    if (!r.webPage) { changeCheck.unreachable.push(`${r.chamber}-${r.district} ${r.name}: no web page published`); continue; }
    let text;
    let heading;
    try {
      const $p = cheerio.load(await getText(r.webPage));
      text = $p.root().text().replace(/\s+/g, ' ');
      // The page's own title and headings — what the page says it is ABOUT.
      heading = [$p('title').text(), ...$p('h1').map((_, e) => $p(e).text()).get()].join(' ').replace(/\s+/g, ' ');
    } catch (e) {
      changeCheck.unreachable.push(`${r.chamber}-${r.district} ${r.name}: ${r.webPage} ${e.message}`);
      continue;
    }
    changeCheck.read++;
    const surname = r.last_name || lastOf(r.name);
    // 🔴 THIS TEST WAS A RegExp BUILT FROM A TEMPLATE LITERAL AND IT REPORTED 100 OF 100 PAGES
    // AS NOT NAMING THEIR OWN MEMBER. In a template literal `\b` is the BACKSPACE character,
    // not a word boundary, so the pattern searched for an unprintable byte and never matched.
    // 100 of 100 is a uniform answer, which is the tell — the pages were fine. Word boundaries
    // are not worth a backslash that three layers of quoting keep eating: pad both sides with
    // spaces and use a plain substring test on the normalised text instead.
    const hay = ` ${norm(text)} `;
    const needle = ` ${norm(surname)} `;
    if (!hay.includes(needle)) {
      changeCheck.nameNotFound.push(`${r.chamber}-${r.district} ${r.name}: their own page never names them (${r.webPage})`);
    } else if (!` ${norm(heading)} `.includes(needle)) {
      // 🔴 THE FIRST VERSION OF THIS TEST WAS A PROXIMITY REGEX REQUIRING THE LITERAL WORDS
      // "State Senator" or "State Representative" within 40 characters of the surname, and it
      // flagged 88 of 147 — because most member sites write "Senator Albert", not "State
      // Senator Albert". 88 is not a uniform answer, so it was not obviously broken; it was
      // just measuring house style. ▶ A test has to name what it is checking FOR. What matters
      // is whether the page is THAT MEMBER'S page, and a page says that in its own <title> and
      // <h1>. That is also exactly what caught housedems.com/whitsett, whose <h1> reads
      // "Michigan House Democrats".
      changeCheck.notTheirPage.push(`${r.chamber}-${r.district} ${r.name}: page mentions them but its title/h1 is not theirs — "${heading.slice(0, 80)}" (${r.webPage})`);
    }
    const body = stripFeed(text);
    const dm = body.match(DEPARTURE);
    if (dm) {
      const at = body.indexOf(dm[0]);
      changeCheck.departureLanguage.push(
        `${r.chamber}-${r.district} ${r.name}: "${dm[0]}" — context: ...${body.slice(Math.max(0, at - 110), at + 110).trim()}... (${r.webPage})`
      );
    }
    await new Promise((s) => setTimeout(s, 250));
  }
  console.log(`  read ${changeCheck.read} of ${A.length}`);
  for (const k of ['unreachable', 'noPageByDesign', 'nameNotFound', 'notTheirPage', 'departureLanguage']) {
    console.log(`  ${k}: ${changeCheck[k].length}`);
    for (const line of changeCheck[k]) console.log(`    - ${line}`);
  }
}

// ── names: first_name / last_name for the duplicate guard ──────────────────
// 🔴🔴 THE PAIR A CONSTRAINT READS MUST BE INTERNALLY CONSISTENT. essentials'
// politician_name_duplicate_guard keys on (lower(first_name), lower(last_name)) against ACTIVE
// rows. MN-2 was bitten by taking full_name from the chamber and first_name from Open States:
// "Steven Jacob" arrived with first_name "Steve", and the guard could not see the collision.
// So the triple is derived from ONE string — source A's full name — and the structured sources
// are used only to locate the SURNAME BOUNDARY, which is the part a split cannot guess:
// "Tonya Myers Phillips", "Alicia St. Germaine", "Joseph N. Bellino Jr." and "Nancy
// Jenkins-Arno" all break a last-token rule, in four different ways.
const SURNAME_FALLBACK = {
  // Only where no structured source covers the seat. Karen Whitsett sits in neither caucus, so
  // source C has no row for her; her name is two plain tokens and the assertion below proves it.
  'lower-4': 'Whitsett',
};
const cByDistrict = new Map(C.map((r) => [r.district, r]));
for (const r of A) {
  const structured = r.chamber === 'upper' ? bByDistrict.get(r.district)?.last : cByDistrict.get(r.district)?.last;
  const surname = structured ?? SURNAME_FALLBACK[`${r.chamber}-${r.district}`];
  if (!surname) { finding('NO_SURNAME_SOURCE', `${r.chamber}-${r.district} ${r.name}: no structured source gives a surname boundary`); continue; }
  if (!surnameMatches(r.name, surname)) { finding('SURNAME_NOT_A_SUFFIX', `${r.chamber}-${r.district}: "${surname}" is not the tail of "${r.name}"`); continue; }
  // 🔴 THE SURNAME IS NOT ALWAYS AT THE END, AND A TAIL SLICE GETS IT WRONG IN TWO WAYS.
  // "Joseph N. Bellino Jr." sliced one word off the tail yields "Jr."; "Tullio Liberati" against
  // a structured surname of "Liberati Jr." sliced two words yields the whole name. So strip any
  // generational suffix from the structured surname, then LOCATE that string inside the display
  // name and take the span it actually occupies. Four shapes are covered and each broke a
  // different way: a suffix, a two-word surname ("Myers Phillips"), a particle ("St. Germaine")
  // and an apostrophe ("O'Neal").
  const bareSurname = surname.replace(/\s*(jr|sr|ii|iii|iv)\.?\s*$/i, '').trim();
  const at = r.name.toLowerCase().indexOf(bareSurname.toLowerCase());
  if (at < 0) { finding('SURNAME_NOT_LOCATED', `${r.chamber}-${r.district}: "${bareSurname}" does not appear in "${r.name}"`); continue; }
  r.last_name = r.name.slice(at, at + bareSurname.length);
  r.first_name = r.name.trim().split(/\s+/)[0];
  // The triple must be internally consistent: both parts are literal substrings of full_name,
  // and they do not overlap. (endsWith is NOT required — "Joseph N. Bellino Jr." ends in a suffix.)
  if (!r.name.startsWith(r.first_name) || !r.name.includes(r.last_name) || at < r.first_name.length) {
    finding('NAME_TRIPLE_INCONSISTENT', `${r.chamber}-${r.district}: "${r.name}" / first "${r.first_name}" / last "${r.last_name}"`);
  }
}

// ── output ─────────────────────────────────────────────────────────────────
const seats = A.map((r) => ({
  chamber: r.chamber,
  district: r.district,
  geo_id: `26${String(r.district).padStart(3, '0')}`,
  district_type: r.chamber === 'lower' ? 'STATE_LOWER' : 'STATE_UPPER',
  full_name: r.name,
  first_name: r.first_name,
  last_name: r.last_name,
  web_page: r.webPage,
  web_page_override: r.web_page_override ? { to: r.web_page_override.to, why: r.web_page_override.why } : undefined,
  name_override: r.name_override ? { from: r.name_override.from, why: r.name_override.why } : undefined,
  // No party. No term_start: Michigan publishes no arrival date on these pages, and
  // "first elected" is not a term start. Occupancy is written open-ended at 'unknown'.
}));
seats.sort((a, b) => (a.chamber === b.chamber ? a.district - b.district : a.chamber < b.chamber ? -1 : 1));

const out = {
  generated_at: new Date().toISOString(),
  state: 'MI',
  wave: 'MI-2',
  sources: SRC,
  counts: { total: seats.length, lower: seats.filter((s) => s.chamber === 'lower').length, upper: seats.filter((s) => s.chamber === 'upper').length },
  caucus_union_gaps: cGaps,
  findings,
  change_check: changeCheck,
  seats,
};

if (SELF_TEST) {
  const need = ['A_MISSING_SEAT', 'AC_NAME_DISAGREES', 'B_DUPLICATE', 'OPENSTATES_DISAGREES'];
  const got = new Set(findings.map((f) => f.code));
  const gapCodes = findings.filter((f) => f.code === 'CAUCUS_GAP_EXPLAINED').length;
  const missed = need.filter((c) => !got.has(c));
  console.log('');
  if (missed.length === 0 && gapCodes >= 2) {
    console.log(`🧪 SELF-TEST PASSED — every planted defect was reported (${findings.length} findings, ${gapCodes} caucus gaps incl. the planted one).`);
    process.exit(1);
  }
  console.log(`🔴 SELF-TEST FAILED — detectors that stayed silent: ${missed.join(', ') || '(none)'}; caucus gaps seen ${gapCodes}, expected >= 2.`);
  process.exit(2);
}

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(out, null, 2) + '\n');
console.log(`\nwrote ${OUT} — ${seats.length} seats, ${findings.length} finding(s)`);

const blocking = findings.filter((f) => !['CAUCUS_GAP_EXPLAINED', 'OPENSTATES_NICKNAME'].includes(f.code));
if (blocking.length) {
  console.log(`\n🔴 ${blocking.length} finding(s) need reading before the migration is written.`);
  process.exit(1);
}
console.log('\n✅ All four sources agree on all 148 seats, and every caucus-union gap is explained.');
