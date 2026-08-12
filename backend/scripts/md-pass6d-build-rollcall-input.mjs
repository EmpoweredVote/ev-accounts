#!/usr/bin/env node
/**
 * PASS 6d -- build the roll-call input for the 11 IN_TENURE rows left by pass 6b.
 *
 * md-pass5-rollcall.mjs consumes a tenure-screen-shaped file and, importantly, only opens bill pages
 * that are ALREADY CACHED (it fetches vote PDFs, not bill pages). So this script does two jobs:
 * pick the in-tenure candidate bills per row, and pre-fetch their pages.
 *
 * ⚠ Candidate bills are chosen from a CURATED instrument->matcher map, not from the pass-6 resolver,
 * because that resolver is what produced the wrong-session bills in the first place (mig 1700).
 *
 * 🔴 Reads only.
 */
import fs from 'node:fs';
import path from 'node:path';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const RESCREEN = flag('--rescreen'), TENURE = flag('--tenure'), CORPUS = flag('--corpus');
const CACHE = flag('--cache'), OUT = flag('--out');
if (!RESCREEN || !TENURE || !CORPUS || !CACHE || !OUT) { console.error('need --rescreen --tenure --corpus --cache --out'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Already applied by mig 1700 -- do not re-work.
const APPLIED = new Set(['Mark Edelson|Fossil Fuel Policy', 'Derrick Coley|Voting Rights and Electoral Integrity']);

// Curated: instrument -> which corpus titles count as that instrument.
const MATCH = {
  "Blueprint for Maryland's Future": /Blueprint for Maryland/i,
  'Maryland Abortion Care Access Act': /^Abortion Care Access Act$/i,
  'Maryland RELIEF Act': /Entrepreneurs, and Families \(RELIEF\) Act/i,
};

const { bills } = JSON.parse(fs.readFileSync(CORPUS, 'utf8'));
// The corpus holds two rows per bill; the real title is the longer one.
const best = new Map();
for (const b of bills) {
  const k = `${b.session}|${b.number.toUpperCase()}`;
  if (!best.has(k) || b.title.length > best.get(k).title.length) best.set(k, b);
}
const allBills = [...best.values()];

const rescreen = JSON.parse(fs.readFileSync(RESCREEN, 'utf8'));
const tenureFile = JSON.parse(fs.readFileSync(TENURE, 'utf8'));
const tenureBy = new Map((tenureFile.rows || tenureFile).map((r) => [`${r.politician_id}|${r.topic_id}`, r]));

const targets = rescreen.rows.filter((r) => r.verdict === 'IN_TENURE_RESCREENED' && !APPLIED.has(`${r.politician}|${r.topic}`));
console.log(`building input for ${targets.length} rows`);

const rows = [];
const wanted = new Map();
for (const r of targets) {
  const re = MATCH[r.instrument];
  if (!re) { console.log(`  ⚠ no matcher for "${r.instrument}" (${r.politician})`); continue; }
  const cands = allBills
    .filter((b) => r.sessions_in_tenure.includes(b.session.slice(0, 4)) && re.test(b.title))
    .sort((a, b) => parseInt(b.session, 10) - parseInt(a.session, 10))
    .slice(0, 12);
  for (const b of cands) wanted.set(`${b.slug}|${b.session}`, b);
  const t = tenureBy.get(`${r.politician_id}|${r.topic_id}`);
  rows.push({
    politician: r.politician, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
    cited_slug: r.cited_slug, reasoning: r.reasoning, claim_verb: r.claim_verb,
    service_lines: t?.service_lines || [],
    verdict: 'IN_TENURE_NEEDS_ROLLCALL',
    bills_in_tenure: cands.map((b) => ({ session: b.session, number: b.number, slug: b.slug, title: b.title })),
  });
  console.log(`  ${r.politician} / ${r.topic}: ${cands.length} candidate bill(s)`);
}

// Pre-fetch bill pages the roll-call reader will need.
let fetched = 0, cached = 0, failed = 0;
for (const [, b] of wanted) {
  const f = path.join(CACHE, `${b.slug}-${b.session}.html`);
  if (fs.existsSync(f) && fs.statSync(f).size > 20_000) { cached++; continue; }
  const res = await fetch(`https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${b.slug}?ys=${b.session}`,
    { headers: { 'User-Agent': UA }, redirect: 'follow' });
  const body = await res.text();
  // 🔴 mgaleg answers 200 on its own NotFound page -- trust the landing URL, never the status.
  if (/Error\/NotFound/i.test(res.url) || body.length < 20_000) { failed++; await sleep(1200); continue; }
  fs.writeFileSync(f, body); fetched++; await sleep(1300);
}
console.log(`bill pages: ${cached} cached, ${fetched} fetched, ${failed} unavailable`);

fs.writeFileSync(OUT, JSON.stringify({ rows }, null, 1));
console.log(`wrote ${rows.length} rows -> ${OUT}`);
