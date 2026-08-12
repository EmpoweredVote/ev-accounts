#!/usr/bin/env node
/**
 * CLASS-C SOURCING for the instrument-free rows: what did each member actually sponsor, on topic?
 *
 * 🔑 WHY NOT THE BILL CRAWL. The obvious route — fetch every healthcare/housing/rent/childcare bill
 * in the corpus and read its sponsor list — is 4,713 uncached bill pages, ~86 minutes, and identifies
 * members by SURNAME. mgaleg will instead list a member's own sponsored legislation per session:
 *   /mgawebsite/Members/Details/<slug>?ys=<session>
 * That is ~150 fetches, and it is mgaleg's OWN attribution, so it cannot mis-credit a surname twin.
 *
 * 🔴🔴 THE TRAP THAT MAKES THIS DANGEROUS. A member record is CHAMBER-SCOPED. Ask for a session from
 * before the member switched chambers and mgaleg returns a page of exactly 56,073 bytes with ZERO
 * bills — not an error, just an empty list. Alonzo T. Washington sponsored HB1300 in 2020, yet
 * `washington02?ys=2020RS` lists nothing, because his House-era record is the retired `washington`
 * slug. Treating that empty list as "sponsored nothing" would manufacture a false absence for every
 * chamber-switcher — the exact defect class this workstream exists to clean up. So an empty list is
 * recorded as UNAVAILABLE_SESSION and NEVER as evidence, and those sessions are reported as owed to
 * the bill-crawl fallback.
 *
 * ⚠ A title match is topical, not directional — see lib/md-topic-nets.mjs. Everything this emits is a
 * READING QUEUE. Nothing here decides a chair or writes a citation.
 *
 * 🔴 Reads only.
 *   node scripts/md-member-legislation.mjs --out <report.json> [--only "Name"]
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';
import { chamberSpans, chamberForSession, tenureText } from './lib/md-tenure.mjs';
import { UA } from './lib/md-rollcall.mjs';
import { TOPIC_NETS, TOPIC_EXCLUDE } from './lib/md-topic-nets.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-md-member-legislation.json');
const ONLY = flag('--only');

const CACHE = 'C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/mdcorpus';
const MEMBERS = path.join(CACHE, 'member-cache');
const SESS = path.join(CACHE, 'member-session-cache');
for (const d of [MEMBERS, SESS]) fs.mkdirSync(d, { recursive: true });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const corpus = JSON.parse(fs.readFileSync(path.join(CACHE, 'md-bill-corpus.json'), 'utf8'));
const bills = corpus.bills.filter((x) => x.title && x.title.length > 5);
const titleOf = {};
for (const b of bills) titleOf[`${b.session}:${b.slug}`] = { title: b.title, number: b.number, chamber: b.chamber };
const SESSIONS = [...new Set(bills.map((b) => b.session))].sort();

/** ⚠ the empty-legislation page is a fixed size; treat ANY zero-bill page as unavailable, not empty. */
async function memberSession(slug, ys) {
  const f = path.join(SESS, `${slug}-${ys}.html`);
  let h = fs.existsSync(f) && fs.statSync(f).size > 5000 ? fs.readFileSync(f, 'utf8') : null;
  if (!h) {
    const res = await fetch(`https://mgaleg.maryland.gov/mgawebsite/Members/Details/${slug}?ys=${ys}`, { headers: { 'User-Agent': UA } });
    const body = await res.text();
    await sleep(1100);
    if (!res.ok || body.length < 5000) return { status: 'FETCH_FAILED', bills: [] };
    fs.writeFileSync(f, body); h = body;
  }
  const found = [...new Set([...h.matchAll(/Legislation\/Details\/([a-z]{2}\d{4})\?ys=(\w+)/g)].map((m) => `${m[2]}:${m[1]}`))]
    .filter((k) => k.startsWith(ys + ':'));
  // 🔴 zero bills is NOT "sponsored nothing" — see the header
  if (!found.length) return { status: 'UNAVAILABLE_SESSION', bills: [] };
  return { status: 'OK', bills: found };
}

const REMAINING = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-instrument-free-remaining.json', 'utf8'));
let rows = REMAINING.rows.filter((r) => r.state === 'MD');
if (ONLY) rows = rows.filter((r) => r.name === ONLY);
console.log(`${rows.length} Maryland row(s) across ${new Set(rows.map((r) => r.name)).size} members\n`);

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const dburl = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: dburl, ssl: { rejectUnauthorized: false } });

// ── per member: tenure, then every session we can actually read ─────────────────────────────────
const members = {};
for (const r of rows) {
  if (members[r.name]) continue;
  const slug = ((r.sources || []).map((s) => (s.match(/Members\/Details\/([A-Za-z0-9_-]+)/) || [])[1]).filter(Boolean))[0]
    || ((REMAINING.rows.find((x) => x.name === r.name && (x.sources || []).some((s) => /Members\/Details\//.test(s))) || {}).sources || [])
      .map((s) => (s.match(/Members\/Details\/([A-Za-z0-9_-]+)/) || [])[1]).filter(Boolean)[0] || null;
  members[r.name] = { slug, sessions: {}, spans: [], tenure: null };
}
// Sara Love's page hides her House service; the landmark pass recorded why.
const TENURE_OVERRIDE = {
  'Sara Love': [{ chamber: 'house', from: 2019, to: 2024, src: 'corpus: "Delegate Love" 2019RS-2024RS (mgaleg tenure field omits it)' },
    { chamber: 'senate', from: 2024, to: 9999, src: 'mgaleg: Member of the Maryland Senate since June 13, 2024' }],
};

for (const [name, m] of Object.entries(members)) {
  if (!m.slug) { console.log(`  !! ${name}: no member slug in sources`); continue; }
  const f = path.join(MEMBERS, `${m.slug}.html`);
  let h = fs.existsSync(f) && fs.statSync(f).size > 5000 ? fs.readFileSync(f, 'utf8') : null;
  if (!h) {
    const res = await fetch(`https://mgaleg.maryland.gov/mgawebsite/Members/Details/${m.slug}`, { headers: { 'User-Agent': UA } });
    const body = await res.text(); await sleep(1100);
    if (res.ok && body.length > 5000) { fs.writeFileSync(f, body); h = body; }
  }
  m.tenure = h ? tenureText(h) : null;
  m.spans = TENURE_OVERRIDE[name] || chamberSpans(m.tenure);
  const inTenure = SESSIONS.filter((s) => chamberForSession(m.spans, parseInt(s, 10)));
  process.stdout.write(`  ${name} [${m.slug}] ${inTenure.length} in-tenure session(s): `);
  for (const s of inTenure) {
    const r = await memberSession(m.slug, s);
    m.sessions[s] = r;
    process.stdout.write(r.status === 'OK' ? `${s.slice(0, 4)}✓ ` : `${s.slice(0, 4)}✗ `);
  }
  console.log('');
}

// ── per row: which of that member's bills are on this topic ─────────────────────────────────────
const out = [];
for (const r of rows) {
  const m = members[r.name];
  const net = TOPIC_NETS[r.topic];
  if (!net) throw new Error(`no topic net for "${r.topic}" — the net is the extractor, add it first`);
  const readable = Object.entries(m.sessions).filter(([, v]) => v.status === 'OK').map(([s]) => s);
  const unreadable = Object.entries(m.sessions).filter(([, v]) => v.status !== 'OK').map(([s]) => s);
  const all = readable.flatMap((s) => m.sessions[s].bills);
  const hits = all.map((k) => ({ key: k, ...(titleOf[k] || {}) }))
    .filter((b) => b.title && net.test(b.title) && !(TOPIC_EXCLUDE[r.topic] || /$^/).test(b.title))
    .map((b) => ({ ...b, session: b.key.split(':')[0], slug: b.key.split(':')[1],
      url: `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${b.key.split(':')[1]}?ys=${b.key.split(':')[0]}` }));
  out.push({
    politician_id: r.politician_id, topic_id: r.topic_id, name: r.name, topic: r.topic, chair: r.chair,
    reasoning: r.reasoning, sources: r.sources, member_slug: m.slug, tenure: m.tenure, spans: m.spans,
    sessions_read: readable, sessions_unreadable: unreadable,
    n_bills_seen: all.length, n_on_topic: hits.length, candidates: hits,
  });
  console.log(`  ${String(hits.length).padStart(3)} on-topic / ${String(all.length).padStart(4)} seen   ${r.name} / ${r.topic}`
    + (unreadable.length ? `   ⚠ ${unreadable.length} session(s) unreadable` : ''));
}
await pool.end();

const noCandidates = out.filter((r) => !r.n_on_topic);
console.log(`\n${out.length} rows; ${out.length - noCandidates.length} with candidates, ${noCandidates.length} without.`);
if (noCandidates.length) {
  console.log('⚠ rows with NO on-topic bill from readable sessions (NOT a finding until the unreadable sessions are crawled):');
  for (const r of noCandidates) console.log(`   ${r.name} / ${r.topic}  (unreadable: ${r.sessions_unreadable.join(',') || 'none'})`);
}
fs.writeFileSync(OUT, JSON.stringify({ pass: 'MD member sponsored legislation, on-topic candidates', rows: out }, null, 1));
console.log(`wrote ${OUT}`);
