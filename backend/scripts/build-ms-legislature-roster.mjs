#!/usr/bin/env node
/**
 * build-ms-legislature-roster.mjs — Knight program, slice 16 (MS), wave MS-2.
 *
 * Reconciles the Mississippi Legislature roster and writes data/ms-legislature-roster.json.
 * Reads nothing from the database and writes nothing to it.
 *
 * ── SOURCES ─────────────────────────────────────────────────────────────────────────────────
 *   A. https://billstatus.ls.state.ms.us/members/{ss,hr}_membs.xml
 *      The Legislature's own list. A presentation document: a grid of names with links to each
 *      member's page, plus a header naming the presiding officers.
 *      🔴 IT CARRIES NO DISTRICT NUMBER AT ALL, so it can supply membership but never the seat.
 *   B. https://billstatus.ls.state.ms.us/members/{senate,house}/<slug>.xml
 *      Each member's OWN page. <DISTRICT> lives here, so the seat comes from the member's own
 *      document. Also <DISP_NAME>, <LEG_EXP><STRETCH> service history and <CNTY_INFO> counties.
 *   C. https://data.openstates.org/people/current/ms.csv
 *      Open States. A DETECTOR, NOT AN ORACLE — it opens a reading queue, it never decides.
 *
 * ── 🔴🔴 THE TRAP THIS WAVE PAID FOR: THE LIST IS STALE AND THE PAGES ARE CURRENT ───────────
 * The usual programme finding is the opposite — MN-2 and MI-2 both had a fresh-looking list that
 * had not noticed a departure. Mississippi inverts it, and only `Last-Modified` could tell:
 *     ss_membs.xml  last modified 2025-07-01
 *     hr_membs.xml  last modified 2025-10-14
 * Both PREDATE the court-ordered special elections of **2025-11-04**, while individual member
 * pages are current to 2026-08-18. So the Senate list still declares "Vacancy - District 24"
 * and "Vacancy - District 26" — seats that were vacant in July 2025 and have been filled since
 * — and still carries a senator who has retired.
 * ▶ **A DOCUMENT'S CONTENT CANNOT TELL YOU ITS AGE; ASK THE SERVER.** Justin Pope's page looks
 *   exactly like a sitting member's (six committees, a capitol phone, "2026-present") because he
 *   IS one. The list that calls his seat vacant is fourteen months old.
 * ⚠ AND A PAGE EXISTING IS NOT MEMBERSHIP EITHER. `senate/polk.xml` resolves HTTP 200 with full
 *   detail and John Polk retired in 2025; the site keeps former members in the same namespace as
 *   sitting ones. Probing for a page therefore proves nothing on its own.
 * ⚠ AND STALENESS IS NOT DEPARTURE. 13 of 170 member pages predate the specials, and 8 of those
 *   are sitting members in districts the remedy never touched — a page is only edited when
 *   something about it changes. Staleness is one half of a two-part test, never a verdict.
 *
 * ── HOW A TURNOVER IS ESTABLISHED: TWO INDEPENDENT HALVES, BOTH REQUIRED ────────────────────
 * A seat is treated as having turned over ONLY when BOTH hold:
 *   (1) the list's holder has a member page last modified BEFORE 2025-11-04, and
 *   (2) Open States names a different person in that district AND does not name the list's
 *       holder in ANY district.
 * Then the successor's own page is fetched and must itself carry the expected <DISTRICT>.
 * 🟢 The correlation is the evidence: every seat where Open States names a different surname is
 * also a seat whose page predates the specials. Five of five, in both chambers.
 * 🟢 AND THE ARITHMETIC CLOSES EXACTLY, which is the real control. ⚠ Miss. Const. art. 13 § 254
 * CAPS the chambers at 52 and 122 rather than fixing them ("not more than", the number "to be
 * determined by the Legislature"), so 52 and 122 are what the current apportionment chose, not a
 * constant — but they ARE what it chose, so the reconciliation must land on both without slack.
 *
 * ── 🔴 THE PRESIDING OFFICERS ARE IN THE HEADER, NOT THE GRID — AND THE CHAMBERS DIFFER ─────
 * The House's <CHAIR> (Speaker Jason White, HD-48) and <PROTEMP> (Manly Barton, HD-109) are
 * members and appear NOWHERE in the member grid. The Senate's <CHAIR> is the LIEUTENANT
 * GOVERNOR, who is not a senator at all — he already exists in production as a statewide
 * executive — while its <PROTEMP> is in the grid like everyone else.
 * ▶ Blindly adding CHAIR+PROTEMP for both chambers seats a 53rd senator. The discriminator is
 *   the LINK SHAPE: a presiding officer is a member iff their link is a member page in this
 *   document family. Hosemann's is `http://ltgovhosemann.ms.gov/`; White's is `house/White.xml`.
 *
 * ── 🔴 THE COLUMN COUNT IS DISCOVERED, NEVER ASSUMED ────────────────────────────────────────
 * The Senate list is a FOUR-column grid and the House list a FIVE-column one, in the same
 * document family from the same publisher. A hard-coded four silently dropped every M5 slot —
 * 24 House members — which read as "the list is 96 long" and produced 26 districts that looked
 * unaccounted for. A LAYOUT IS NOT A SCHEMA.
 *
 * ── 🔴 ENCODING: THESE FILES ARE ISO-8859-1 AND SAY SO ──────────────────────────────────────
 * Decoding them as UTF-8 writes mojibake into a voter-facing name (MN-2's trap, eight names).
 * Latin-1 is a total decoding and can never throw, so the declaration is read and asserted.
 *
 * ── 🔴 A CONNECTION FAILURE IS NOT AN ABSENCE ───────────────────────────────────────────────
 * Both hosts serve ONLY their leaf certificate, so Node and curl die with
 * UNABLE_TO_VERIFY_LEAF_SIGNATURE while a browser succeeds via the certificate's own AIA
 * extension — the Michigan MI-2 defect exactly. The fix adds the one intermediate both leaves
 * name. It does NOT disable verification, and `--tls-control` proves it necessary, sufficient
 * and masking nothing.
 *
 * ── 🔴 PARTY IS CARRIED INTERNALLY AND NEVER WRITTEN ────────────────────────────────────────
 * Party lives on races.primary_party in this schema, never on a person or an office.
 *
 * ── 🔴 NO term_start IS INVENTED ────────────────────────────────────────────────────────────
 * <STRETCH> is a SERVICE HISTORY and a CAREER, not a term start and not a seat — MI-4 paid for
 * this when two commissioners were dated to the year they CHANGED DISTRICT NUMBER. Stretches
 * are recorded as evidence for a later reader and are never promoted to a date here.
 *
 * ── 🔴🔴 THE MISSISSIPPI-SPECIFIC WARNING NO OTHER SLICE HAS NEEDED ─────────────────────────
 * MS-1 loaded the 2022 lines, because the Supreme Court vacated the judgment approving the 2025
 * remedial plans on 2026-05-18, the Secretary of State reverted the State's own SEMS to the 2022
 * lines on 2026-07-24, and the three-judge court held on 2026-09-11 that the 2025 Joint
 * Resolutions "are not operative" (Doc 318, 3:22-cv-734-DPJ-HSO-LHS). BUT the members seated by
 * the 2025-11-04 specials were elected under the 2025 lines, and the same order records that
 * "the Legislature's current composition will remain unchanged until the 2027 election."
 * ▶ SO IN DeSOTO, HATTIESBURG AND NORTHEAST MISSISSIPPI THE HOLDER OF DISTRICT N MAY HAVE BEEN
 *   ELECTED BY A DIFFERENTLY-SHAPED DISTRICT N. Flagged in the output, never normalised away.
 *
 *   node scripts/build-ms-legislature-roster.mjs
 *   node scripts/build-ms-legislature-roster.mjs --tls-control
 *   node scripts/build-ms-legislature-roster.mjs --self-test
 *   node scripts/build-ms-legislature-roster.mjs --refresh     (ignore the page cache)
 */
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import * as http from 'http';
import * as tls from 'tls';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DATA = path.join(HERE, '..', 'data');
const OUT = path.join(DATA, 'ms-legislature-roster.json');
const CACHE = path.join(DATA, 'seed-ms-2026', '_pages');
const CA_DIR = path.join(DATA, 'seed-ms-2026', '_ca');
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

const argv = process.argv.slice(2);
const TLS_CONTROL = argv.includes('--tls-control');
const SELF_TEST = argv.includes('--self-test');
const REFRESH = argv.includes('--refresh');

const SRC = {
  upperList: 'https://billstatus.ls.state.ms.us/members/ss_membs.xml',
  lowerList: 'https://billstatus.ls.state.ms.us/members/hr_membs.xml',
  memberBase: 'https://billstatus.ls.state.ms.us/members/',
  openStates: 'https://data.openstates.org/people/current/ms.csv',
};
const DIR = { upper: 'senate', lower: 'house' };

// The one intermediate BOTH hosts omit, from each leaf certificate's own AIA "CA Issuers" URL.
const INTERMEDIATES = ['http://secure.globalsign.com/cacert/gsrsaovsslca2018.crt'];

const EXPECT = { upper: 52, lower: 122 };

/** The court-ordered special general election. The freshness line for the staleness half. */
const SPECIALS_DAY = new Date('2025-11-04T00:00:00Z');

/**
 * Districts where the 2022 lines (loaded by MS-1) and the 2025 remedial lines materially
 * disagree. MEASURED by verify-ms-tiger-vintage.mjs over all 112,241 census blocks, as the set
 * whose disagreement exceeds 1,000 people; everything else differs only by zero-population
 * boundary artefacts. Not taken from any summary.
 */
const MAP_MEMBER_SPLIT = {
  upper: [1, 2, 10, 11, 19, 34, 41, 42, 44, 45],
  lower: [16, 22, 36, 39, 41],
};

/**
 * Slug candidates for a member whose page the list does not link. Derived from the surname,
 * with the shapes this site actually uses. 🔴 EVERY CANDIDATE IS VALIDATED, NEVER TRUSTED: the
 * fetched page must carry the expected <DISTRICT>, or it is rejected and the next is tried.
 * Observed shapes: `polk`, `turner-ford`, `butler-washington`, `gillespie_isom`,
 * `holloway_(76th)`, `creekmore_iv`.
 */
function slugCandidates(name, district) {
  const clean = name.replace(/[.,]/g, '').trim();
  const parts = clean.split(/\s+/).filter((p) => !/^(jr|sr|ii|iii|iv|v)$/i.test(p));
  const last = parts[parts.length - 1].toLowerCase();
  const last2 = parts.length >= 2 ? `${parts[parts.length - 2]}_${parts[parts.length - 1]}`.toLowerCase() : null;
  const last2h = parts.length >= 2 ? `${parts[parts.length - 2]}-${parts[parts.length - 1]}`.toLowerCase() : null;
  return [last, last2, last2h, `${last}_(${district}th)`].filter(Boolean);
}

const findings = [];
const finding = (code, detail) => {
  findings.push({ code, detail });
  console.log(`  ${code}: ${detail}`);
};

// ── transport ───────────────────────────────────────────────────────────────────────────────
const derToPem = (der) =>
  `-----BEGIN CERTIFICATE-----\n${Buffer.from(der).toString('base64').match(/.{1,64}/g).join('\n')}\n-----END CERTIFICATE-----\n`;

function rawGet(url, agent, method = 'GET', redirects = 5) {
  return new Promise((resolve, reject) => {
    // 🔴 The agent exists ONLY to add the missing intermediate, which is a TLS concern, so a
    // plain-HTTP request must not receive it — MI-2 shipped an https.Agent into http.get and got
    // 48 uniform "unreachable" findings, twice in a row, from two different versions of the bug.
    const isHttp = url.startsWith('http://');
    const mod = isHttp ? http : https;
    const req = mod.request(url, { method, agent: isHttp ? undefined : agent, headers: { 'User-Agent': UA } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location && redirects > 0) {
        res.resume();
        return rawGet(new URL(res.headers.location, url).toString(), agent, method, redirects - 1).then(resolve, reject);
      }
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => resolve({ status: res.statusCode, body: Buffer.concat(chunks), lastModified: res.headers['last-modified'] || null }));
    });
    req.on('error', reject);
    req.setTimeout(60000, () => req.destroy(new Error('timeout')));
    req.end();
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

/** 🔴 Decode as the document says, and assert the declaration. Latin-1 can never throw. */
function decodeXml(buf, label) {
  const m = buf.subarray(0, 120).toString('latin1').match(/encoding="([^"]+)"/i);
  const enc = (m ? m[1] : '').toUpperCase();
  if (enc !== 'ISO-8859-1') {
    throw new Error(`[encoding assertion] ${label}: declares encoding="${m ? m[1] : '(none)'}", expected ISO-8859-1. ` +
      'A silent switch to UTF-8 would write mojibake into member names. Refusing to guess.');
  }
  return buf.toString('latin1');
}

/** Cache key is lower-cased: the server is case-insensitive (`house/White.xml` == `white.xml`) and Windows is too. */
const cacheName = (link) => link.replace(/\//g, '_').toLowerCase();

async function fetchDoc(url, name, { xml = true, optional = false } = {}) {
  fs.mkdirSync(CACHE, { recursive: true });
  const file = path.join(CACHE, name);
  const meta = path.join(CACHE, `${name}.lastmod`);
  if (!fs.existsSync(file) || REFRESH) {
    const r = await rawGet(url, AGENT);
    if (r.status !== 200) {
      if (optional) return null;
      throw new Error(`${url} -> HTTP ${r.status}`);
    }
    // 🔴 A clean 200 lies in several ways. This host answers a missing path with HTTP 404 and a
    // 1,245-byte body, but a length floor also catches a truncation or a challenge page.
    if (r.body.length < 300) throw new Error(`${url} -> HTTP 200 but only ${r.body.length} bytes — suspect a soft failure`);
    fs.writeFileSync(file, r.body);
    fs.writeFileSync(meta, r.lastModified || '');
    await new Promise((res) => setTimeout(res, 120)); // deliberately unhurried
  }
  const buf = fs.readFileSync(file);
  const lm = fs.existsSync(meta) ? (fs.readFileSync(meta, 'utf8') || null) : null;
  if (xml && !buf.subarray(0, 400).toString('latin1').includes('MEMBINFO') && name.startsWith('senate_')) {
    // a member URL that resolves to something that is not a member page
    if (optional) return null;
  }
  return { text: xml ? decodeXml(buf, name) : buf.toString('utf8'), lastModified: lm };
}

const tag = (xml, name) => {
  const m = xml.match(new RegExp(`<${name}>([\\s\\S]*?)</${name}>`));
  return m ? m[1].trim() : null;
};
const tagAll = (xml, name) => [...xml.matchAll(new RegExp(`<${name}>([\\s\\S]*?)</${name}>`, 'g'))].map((m) => m[1].trim());
const unent = (s) => (s || '')
  .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
  .replace(/&quot;/g, '"').replace(/&#39;|&apos;/g, "'")
  .replace(/&#(\d+);/g, (_, d) => String.fromCharCode(Number(d)))
  .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCharCode(parseInt(h, 16)));
const tidy = (s) => unent(s).replace(/\s+/g, ' ').trim();
/**
 * 🔴🔴 A HYPHEN IS A NAME VARIANT, NOT A DIFFERENT PERSON — AND A SURNAME-ONLY TEST GETS IT
 * BACKWARDS. "Theresa Gillespie-Isom" has the surname "gillespie-isom"; the same woman written
 * "Theresa Gillespie Isom" has the surname "isom". A last-token comparison calls them different
 * people, and it did: the successor for SD-2 was reported NOT FOUND while her page was sitting
 * right there. The same defect flagged three sitting members as unexplained disagreements
 * ("Angela Turner Ford"/"Angela Turner-Ford", "Hester Jackson McCray"/"Hester Jackson-McCray",
 * "Joel R.Carter, Jr."/"Joel Carter").
 * ▶ MI-2's rule: SPLIT THE CLASS, do not loosen the detector. Matching normalises hyphens,
 * punctuation, suffixes and bare initials; a surviving difference in the DISPLAY strings is
 * still reported, as NAME_VARIANT, so nothing is silently normalised away.
 */
const nameTokens = (s) => tidy(s).toLowerCase()
  .replace(/[.,]/g, ' ')          // "R.Carter" -> "r carter"
  .replace(/-/g, ' ')             // hyphen is a separator for MATCHING only
  .replace(/[^a-z ]/g, ' ')
  .split(/\s+/)
  .filter((t) => t && !/^(jr|sr|ii|iii|iv|v)$/.test(t) && t.length > 1);
const isSubsequence = (a, b) => {
  let i = 0;
  for (const t of b) if (i < a.length && a[i] === t) i += 1;
  return i === a.length;
};
/** Compatible when the token lists are equal, or one is a subsequence of the other. */
const namesCompatible = (x, y) => {
  const a = nameTokens(x); const b = nameTokens(y);
  if (!a.length || !b.length) return false;
  return isSubsequence(a, b) || isSubsequence(b, a);
};
const surname = (s) => { const t = nameTokens(s); return t[t.length - 1] || ''; };
/**
 * 🔴🔴 WHEN THE SURNAME MATCHES AND ONLY THE GIVEN NAME DIFFERS, IT IS A NICKNAME, NOT A
 * DIFFERENT PERSON — MI-2's rule, and Mississippi pays for it twelve times over. Open States
 * writes the name people use and the Legislature writes the name on the roll: Chuck/Charles
 * Younger, Bubba/Joseph Tubb, Hank/Henry Zuber, Zack/Zachary Grady, Bubba/Lester Carpenter,
 * Jeff/Jeffrey Guice, Greg/Gregory Holloway, Sam/Samuel Creekmore. None is a prefix rule —
 * "Bubba" is not short for "Lester" — so nothing but the surname can carry this test.
 * ▶ SPLIT THE CLASS, DO NOT LOOSEN THE DETECTOR. Twelve nickname findings hide the five real
 * turnovers, and it was a REAL turnover this had to keep visible: Polk -> Johnson, Parker ->
 * Gillespie-Isom, Robinson -> Hartness, Lancaster -> Crosby, Paden -> Williams, every one of
 * them a surname change.
 * ⚠ The cost of this rule is that a member who CHANGED SURNAME would read as a different
 * person. That is the safer direction — it raises a finding rather than silently keeping a
 * departed member — and the hyphen normalisation above already covers the common case.
 */
const samePerson = (x, y) => namesCompatible(x, y) || (surname(x) && surname(x) === surname(y));

function parseList(xml, label) {
  const blocks = [...xml.matchAll(/<MEMBER>([\s\S]*?)<\/MEMBER>/g)].map((m) => m[1]);
  const members = [];
  const vacancies = [];
  // 🔴 Discover the column count; the two chambers differ. A LAYOUT IS NOT A SCHEMA.
  const slots = [...new Set([...xml.matchAll(/<M(\d+)_NAME>/g)].map((m) => Number(m[1])))].sort((a, b) => a - b);
  if (!slots.length) throw new Error(`[list parse] ${label}: no M<n>_NAME slots found at all`);
  for (const b of blocks) {
    for (const i of slots) {
      const nm = (b.match(new RegExp(`<M${i}_NAME>([\\s\\S]*?)</M${i}_NAME>`)) || [])[1];
      const lk = (b.match(new RegExp(`<M${i}_LINK>([\\s\\S]*?)</M${i}_LINK>`)) || [])[1];
      if (nm === undefined && lk === undefined) continue;
      const name = tidy(nm || '');
      const link = (lk || '').trim();
      const vac = name.match(/^Vacancy\s*[-–]\s*District\s*(\d+)$/i);
      if (vac) { vacancies.push(Number(vac[1])); continue; }
      if (!name) continue;
      if (!link) { finding('LIST_ODDITY', `${label}: name "${name}" has no member link`); continue; }
      members.push({ name, link });
    }
  }
  // 🔴 The presiding officers, and ONLY when their link is a member page in this family.
  const presiding = [];
  for (const role of ['CHAIR', 'PROTEMP']) {
    const nm = tag(xml, `${role}_NAME`);
    const lk = tag(xml, `${role}_LINK`);
    if (!nm || !lk) continue;
    if (/^https?:/i.test(lk)) {
      finding('PRESIDING_NOT_A_MEMBER', `${label}: ${role} "${tidy(nm)}" links off-site (${lk}) — not a member of this chamber`);
      continue;
    }
    presiding.push({ name: tidy(nm), link: lk, role });
  }
  return { members, vacancies, presiding, rows: blocks.length, cols: slots.length };
}

function parseMember(xml, link, lastModified) {
  const d = tag(xml, 'DISTRICT');
  return {
    link,
    lastModified,
    stale: lastModified ? new Date(lastModified) < SPECIALS_DAY : null,
    district: d === null || d === '' ? null : Number(d),
    name: tidy(tag(xml, 'DISP_NAME') || ''),
    party: tag(xml, 'PARTY'),           // internal only — never written
    stretches: tagAll(xml, 'STRETCH').map(tidy),
    counties: tagAll(xml, 'COUNTY').map(tidy),
  };
}

function parseOpenStates(csv) {
  const lines = csv.split(/\r?\n/).filter(Boolean);
  const split = (l) => {
    const out = []; let cur = ''; let q = false;
    for (const ch of l) {
      if (ch === '"') q = !q;
      else if (ch === ',' && !q) { out.push(cur); cur = ''; }
      else cur += ch;
    }
    out.push(cur); return out;
  };
  const hdr = split(lines[0]);
  const ix = (k) => hdr.indexOf(k);
  return lines.slice(1).map(split)
    .map((c) => ({ name: c[ix('name')], district: Number(c[ix('current_district')]), chamber: c[ix('current_chamber')] }))
    .filter((r) => (r.chamber === 'upper' || r.chamber === 'lower') && !Number.isNaN(r.district));
}

// ── run ─────────────────────────────────────────────────────────────────────────────────────
AGENT = await buildAgent();

if (TLS_CONTROL) {
  const bare = new https.Agent();
  const probe = async (host, agent) => {
    try { const r = await rawGet(`https://${host}/`, agent); return `HTTP ${r.status}`; }
    catch (e) { return `ERROR ${e.code || e.message}`; }
  };
  let ok = true;
  for (const host of ['legislature.ms.gov', 'billstatus.ls.state.ms.us']) {
    const d = await probe(host, bare); const f = await probe(host, AGENT);
    console.log(`  ${host}: default roots ${d} · with intermediate ${f}`);
    if (!d.startsWith('ERROR') || !f.startsWith('HTTP 200')) { ok = false; console.log('    🔴 expected default to FAIL and the fix to succeed'); }
  }
  // ⚠ The masking control asserts SAMENESS, not success. www.sos.ms.gov answers 403 to this
  // client either way — it refuses a Chrome UA arriving on a Node TLS fingerprint, the
  // half-impersonation refusal waynecountymi.gov taught the programme. A 403 that does not move
  // is still a perfectly good control that the added root changed nothing elsewhere.
  const d = await probe('www.sos.ms.gov', bare); const f = await probe('www.sos.ms.gov', AGENT);
  console.log(`  www.sos.ms.gov: default ${d} · with intermediate ${f}  (must be IDENTICAL, not 200)`);
  if (d !== f) { ok = false; console.log('    🔴 the control host answered differently — the added root changes something it should not'); }
  console.log(ok ? '\n✅ TLS control passed — the chain fix is necessary, sufficient, and masks nothing.' : '\n🔴 TLS control FAILED.');
  process.exit(ok ? 0 : 1);
}

if (SELF_TEST) {
  console.log('--self-test: planting one defect per detector\n');
  let all = true;
  const fired = (label, fn) => {
    const n = findings.length;
    try { fn(); } catch (e) { finding('SELFTEST_THREW', `${label}: ${e.message.split('\n')[0]}`); }
    const ok = findings.length > n;
    console.log(`  ${ok ? '✅' : '🔴'} ${label} ${ok ? 'reported' : 'DID NOT REPORT'}`);
    all = all && ok;
  };
  fired('encoding assertion', () => {
    try { decodeXml(Buffer.from(`<?xml version="1.0" encoding="UTF-8"?>${' '.repeat(90)}`), 'planted'); }
    catch (e) { finding('SELFTEST_ENCODING', e.message.split('.')[0]); }
  });
  fired('vacancy parser', () => {
    const r = parseList('<MEMBER><M1_NAME>Vacancy - District 99</M1_NAME><M1_LINK></M1_LINK></MEMBER>', 'planted');
    if (r.vacancies[0] === 99) finding('SELFTEST_VACANCY', 'planted "Vacancy - District 99" parsed as a vacancy, not dropped');
  });
  fired('linkless-name detector', () => {
    parseList('<MEMBER><M1_NAME>Planted Person</M1_NAME><M1_LINK></M1_LINK></MEMBER>', 'planted');
  });
  fired('off-site presiding officer', () => {
    parseList('<CHAIR><CHAIR_NAME>Planted Officer</CHAIR_NAME><CHAIR_LINK>http://example.gov/</CHAIR_LINK></CHAIR>' +
      '<MEMBER><M1_NAME>A B</M1_NAME><M1_LINK>senate/ab.xml</M1_LINK></MEMBER>', 'planted');
  });
  fired('column-count discovery', () => {
    const r = parseList('<MEMBER><M1_NAME>A A</M1_NAME><M1_LINK>x/a.xml</M1_LINK>' +
      '<M5_NAME>E E</M5_NAME><M5_LINK>x/e.xml</M5_LINK></MEMBER>', 'planted');
    if (r.members.length === 2) finding('SELFTEST_COLUMNS', 'planted M5 slot was read, not dropped by a hard-coded M1..M4');
  });
  fired('staleness clock', () => {
    const m = parseMember('<DISTRICT>9</DISTRICT><DISP_NAME>X Y</DISP_NAME>', 'x/y.xml', 'Tue, 01 Jul 2025 00:00:00 GMT');
    if (m.stale === true) finding('SELFTEST_STALE', 'a 2025-07-01 page is correctly classified stale against the 2025-11-04 specials');
  });
  fired('surname comparison', () => {
    if (surname('John A. Polk') !== surname('Chris Johnson')) finding('SELFTEST_SURNAME', 'distinct surnames compare unequal');
  });
  console.log(all ? '\n✅ every detector fired' : '\n🔴 A DETECTOR DID NOT FIRE — its silence elsewhere proves nothing');
  process.exit(all ? 0 : 1);
}

console.log('Mississippi Legislature roster\n');

const lists = {};
for (const ch of ['upper', 'lower']) {
  const doc = await fetchDoc(SRC[`${ch}List`], `${ch === 'upper' ? 'ss' : 'hr'}_membs.xml`);
  lists[ch] = parseList(doc.text, `${ch} list`);
  lists[ch].lastModified = doc.lastModified;
  console.log(`  ${ch} list: ${lists[ch].rows} rows x ${lists[ch].cols} columns, ${lists[ch].members.length} named, ` +
    `${lists[ch].vacancies.length} declared vacant${lists[ch].vacancies.length ? ` (${lists[ch].vacancies.join(', ')})` : ''}, ` +
    `${lists[ch].presiding.length} presiding officer(s) in the header`);
  console.log(`    last modified: ${doc.lastModified}`);
}

// 🔴🔴 THE LIST'S OWN AGE IS A FINDING, NOT A FOOTNOTE.
for (const ch of ['upper', 'lower']) {
  const lm = lists[ch].lastModified;
  if (lm && new Date(lm) < SPECIALS_DAY) {
    finding('LIST_PREDATES_SPECIALS', `${ch} list last modified ${lm}, which is BEFORE the 2025-11-04 special elections ` +
      '— its membership and its vacancy markers cannot be current');
  }
}

console.log('\nreading each linked member page (district comes from the member\'s own document)');
const pages = { upper: [], lower: [] };
for (const ch of ['upper', 'lower']) {
  // 🟢 The Senate's PROTEMP is ALSO in the grid (Dean Kirby), so the header and the grid overlap
  // in one chamber and not the other. De-duplicate on the link — reading him twice produced a
  // "district 30 claimed by Dean Kirby and Dean Kirby" duplicate that no evidence could resolve.
  const seenLinks = new Set();
  const queue = [...lists[ch].members, ...lists[ch].presiding]
    .filter((m) => { const k = m.link.toLowerCase(); if (seenLinks.has(k)) return false; seenLinks.add(k); return true; });
  for (const m of queue) {
    const doc = await fetchDoc(SRC.memberBase + m.link, cacheName(m.link));
    const rec = parseMember(doc.text, m.link, doc.lastModified);
    if (rec.district === null) { finding('NO_DISTRICT', `${ch} ${m.link}: member page carries no <DISTRICT>`); continue; }
    if (rec.name && m.name && !samePerson(rec.name, m.name)) {
      finding('LIST_PAGE_DIFFERENT_PERSON', `${ch} ${m.link}: list "${m.name}" vs page "${rec.name}" — surnames differ`);
    } else if (rec.name && m.name && rec.name !== m.name) {
      finding(namesCompatible(rec.name, m.name) ? 'NAME_VARIANT' : 'NAME_NICKNAME',
        `${ch} ${m.link}: list "${m.name}" vs page "${rec.name}" — same person, page wins`);
    }
    pages[ch].push({ ...rec, listName: m.name, fromHeader: !!m.role });
  }
  console.log(`  ${ch}: ${pages[ch].length} member pages read ` +
    `(${pages[ch].filter((p) => p.stale).length} last modified before the specials)`);
}

const os = parseOpenStates((await fetchDoc(SRC.openStates, 'openstates_ms.csv', { xml: false })).text);
const osBy = { upper: new Map(), lower: new Map() };
const osSurnames = { upper: new Set(), lower: new Set() };
for (const r of os) { osBy[r.chamber].set(r.district, r.name); osSurnames[r.chamber].add(surname(r.name)); }
console.log(`\nOpen States (detector): upper ${osBy.upper.size}, lower ${osBy.lower.size}`);

// ── resolve each seat ───────────────────────────────────────────────────────────────────────
console.log('\nresolving seats');
const roster = { generated: new Date().toISOString().slice(0, 10), source: SRC, chambers: {} };

for (const ch of ['upper', 'lower']) {
  const held = new Map();       // district -> page record
  const superseded = [];        // { district, was, why }

  for (const p of pages[ch]) {
    const prev = held.get(p.district);
    if (!prev) { held.set(p.district, p); continue; }
    // Two pages claim one district. Resolve ONLY on the two-part test; never on freshness alone.
    const decide = (a, b) => {
      // 🔴 "Open States does not name this person ANYWHERE in the chamber" is the second half of
      // the test, and it keys on the SURNAME so a nickname cannot fake a departure.
      const aGone = a.stale === true && !osSurnames[ch].has(surname(a.name));
      const bGone = b.stale === true && !osSurnames[ch].has(surname(b.name));
      if (aGone && !bGone) return { keep: b, drop: a };
      if (bGone && !aGone) return { keep: a, drop: b };
      return null;
    };
    const r = decide(prev, p);
    if (!r) {
      finding('DUPLICATE_DISTRICT_UNRESOLVED', `${ch} ${p.district}: "${prev.name}" and "${p.name}" both claim it and ` +
        'the two-part test does not separate them. Refusing to guess.');
      continue;
    }
    held.set(p.district, r.keep);
    superseded.push({
      district: p.district, was: r.drop.name, link: r.drop.link,
      why: `page last modified ${r.drop.lastModified} (before the 2025-11-04 specials) AND Open States names no "${surname(r.drop.name)}" in this chamber; "${r.keep.name}" holds the seat`,
    });
    finding('SUPERSEDED', `${ch} ${p.district}: "${r.drop.name}" -> "${r.keep.name}" (${r.drop.link} last modified ${r.drop.lastModified})`);
  }

  // Seats the list gives us where Open States names someone else AND the page predates the
  // specials: fetch the successor's own page and require it to carry this district.
  for (const [d, p] of [...held]) {
    const osName = osBy[ch].get(d);
    if (!osName) continue;
    if (samePerson(osName, p.name)) {
      if (tidy(osName) !== p.name) {
        finding(namesCompatible(osName, p.name) ? 'NAME_VARIANT' : 'OPENSTATES_NICKNAME',
          `${ch} ${d}: Open States "${osName}" vs page "${p.name}" — same person, page wins`);
      }
      continue;
    }
    if (p.stale !== true) {
      finding('OPENSTATES_DISAGREES_FRESH', `${ch} ${d}: page "${p.name}" (modified ${p.lastModified}, AFTER the specials) ` +
        `vs Open States "${osName}". Keeping the Legislature's own page — but this seat is UNEXPLAINED.`);
      continue;
    }
    if (osSurnames[ch].has(surname(p.name))) {
      finding('STALE_BUT_STILL_SERVING', `${ch} ${d}: page "${p.name}" is stale, but Open States still lists that surname ` +
        'elsewhere in the chamber. Not treated as a departure.');
      continue;
    }
    let found = null;
    for (const cand of slugCandidates(osName, d)) {
      const link = `${DIR[ch]}/${cand}.xml`;
      const doc = await fetchDoc(SRC.memberBase + link, cacheName(link), { optional: true });
      if (!doc || !doc.text.includes('MEMBINFO')) continue;
      const rec = parseMember(doc.text, link, doc.lastModified);
      // 🔴 VALIDATE, NEVER TRUST: the page must carry the district we expected AND the surname.
      if (rec.district !== d || !samePerson(rec.name, osName)) continue;
      found = rec; break;
    }
    if (!found) {
      finding('SUCCESSOR_NOT_FOUND', `${ch} ${d}: "${p.name}" page predates the specials and Open States names "${osName}", ` +
        'but no member page for that person carrying this district could be found. Left as the list has it.');
      continue;
    }
    held.set(d, found);
    superseded.push({
      district: d, was: p.name, link: p.link,
      why: `page last modified ${p.lastModified} (before the 2025-11-04 specials) AND Open States names "${osName}" here and no "${surname(p.name)}" anywhere in the chamber; successor page ${found.link} carries <DISTRICT>${d}</DISTRICT>`,
    });
    finding('SUPERSEDED', `${ch} ${d}: "${p.name}" -> "${found.name}" via ${found.link} (modified ${found.lastModified})`);
  }

  // Seats nobody holds: the list's declared vacancies are 14 months old, so each is re-tested.
  for (let d = 1; d <= EXPECT[ch]; d += 1) {
    if (held.has(d)) continue;
    const osName = osBy[ch].get(d);
    if (!osName) {
      finding('UNHELD_AND_UNNAMED', `${ch} ${d}: no member page and Open States names nobody. ` +
        `${lists[ch].vacancies.includes(d) ? 'The list declares it vacant, but that list predates the specials.' : 'Nothing explains it.'}`);
      continue;
    }
    let found = null;
    for (const cand of slugCandidates(osName, d)) {
      const link = `${DIR[ch]}/${cand}.xml`;
      const doc = await fetchDoc(SRC.memberBase + link, cacheName(link), { optional: true });
      if (!doc || !doc.text.includes('MEMBINFO')) continue;
      const rec = parseMember(doc.text, link, doc.lastModified);
      if (rec.district !== d || !samePerson(rec.name, osName)) continue;
      found = rec; break;
    }
    if (!found) {
      finding('UNFILLED_SEAT', `${ch} ${d}: Open States names "${osName}" but no member page carrying this district was found`);
      continue;
    }
    held.set(d, found);
    finding('FILLED_FROM_PAGE', `${ch} ${d}: not in the list${lists[ch].vacancies.includes(d) ? ' (list declares it VACANT — stale)' : ''}; ` +
      `"${found.name}" holds it per ${found.link} (modified ${found.lastModified})`);
  }

  const missing = [];
  for (let d = 1; d <= EXPECT[ch]; d += 1) if (!held.has(d)) missing.push(d);
  console.log(`\n  ${ch.toUpperCase()} — ${held.size} of ${EXPECT[ch]} seats resolved` +
    `${missing.length ? `, MISSING ${missing.join(', ')}` : ''}`);

  roster.chambers[ch] = {
    expected: EXPECT[ch],
    resolved: held.size,
    missing,
    listLastModified: lists[ch].lastModified,
    superseded,
    members: [...held.entries()].sort((a, b) => a[0] - b[0]).map(([d, m]) => ({
      district: d,
      name: m.name,
      link: m.link,
      pageLastModified: m.lastModified,
      stretches: m.stretches,
      counties: m.counties,
      arrivedThisTerm: m.stretches.some((s) => /^2026[-–]present$/i.test(s)) || undefined,
      mapMemberSplit: MAP_MEMBER_SPLIT[ch].includes(d) || undefined,
    })),
  };
}

// ── the arithmetic control ──────────────────────────────────────────────────────────────────
// 🟢 The reconciliation must land on 52 and 122 with no slack; anything else means a seat was
// invented or lost. ⚠ Those two numbers are the CEILING art. 13 § 254 allows and the size the
// current apportionment chose — not a constitutional constant. Re-read the apportionment before
// changing them.
let ok = true;
for (const ch of ['upper', 'lower']) {
  const c = roster.chambers[ch];
  if (c.resolved !== c.expected) { ok = false; console.log(`  🔴 ${ch}: resolved ${c.resolved}, the current apportionment seats ${c.expected}`); }
}
console.log(ok ? '\n✅ both chambers reconcile exactly to the apportioned count (52 + 122 = 174).'
               : '\n🔴 THE RECONCILIATION DOES NOT CLOSE — do not write this roster.');

fs.writeFileSync(OUT, `${JSON.stringify(roster, null, 2)}\n`);
console.log(`\nwrote ${OUT}`);
const byCode = findings.reduce((a, f) => ({ ...a, [f.code]: (a[f.code] || 0) + 1 }), {});
console.log(`findings: ${findings.length}`);
for (const [c, n] of Object.entries(byCode).sort()) console.log(`  ${c}: ${n}`);
process.exitCode = ok ? 0 : 1;
