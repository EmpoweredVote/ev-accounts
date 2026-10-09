// Build a Saint Paul news corpus for one member, across the outlets that WORK here.
// Usage: node sweep_stpaul.mjs <slug> "Primary Name" ["Alias" ...]
//        FULLNAME_ONLY=1 node sweep_stpaul.mjs kher "Kaohly Her" "Kaohly Vang Her"
//
// 🔴🔴 WHY THIS EXISTS: the first Saint Paul sweep ran BEFORE the corpus-key fix, so it wrote
// base64url(url).slice(0,60) filenames. Measured 2026-10-05, across all eight members:
//
//     named by the sweep: 342   ·   written to disk: 256   ·   LOST TO COLLISIONS: 86 (25%)
//
// Noecker lost 26 of 77, Her 24 of 96, Yang 11 of 50. Every member was affected and nothing
// warned — the corpus looked complete. The four members who scored ZERO chairs were read from a
// corpus a quarter of which was never on disk. That is why these four are re-swept rather than
// re-read. corpusKey below hashes the WHOLE url.
//
// It also carries the two fixes sweep_member.mjs still lacks:
//  1. The UA is the VERIFIER's. Minnesota Reformer 403s a Chrome UA, which sweep_member.mjs sends,
//     so Reformer contributed NOTHING to the original Saint Paul sweep and no error was raised.
//  2. Every fetch has a timeout, progress is flushed to a file, and pages are scrubbed on write.
//
// 🔴 FULLNAME_ONLY=1 exists for Kaohly Her. The keep-filter matches the bare SURNAME, and "Her" is
// an English pronoun: it matches essentially every page ever fetched, which turns the filter into a
// no-op and the corpus into "everything". Her surname cannot be used as a token. This is the Janet
// Kennedy lesson (a corpus 94% other Kennedys) at its limit — here the ratio would be ~100%.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { scrubText } from './scrub_corpus.mjs';

const corpusKey = (url) => crypto.createHash('sha1').update(url).digest('hex').slice(0, 24);

const UA = 'EmpoweredVoteBot/1.0 (+https://empowered.vote/crawler; nonprofit civic citation verification; contact info@empowered.vote)';
const SLUG = process.argv[2];
const NAMES = process.argv.slice(3);
if (!SLUG || !NAMES.length) { console.error('usage: sweep_stpaul.mjs <slug> "Name" [alias ...]'); process.exit(1); }
const FULLNAME_ONLY = process.env.FULLNAME_ONLY === '1';

const SURNAMES = FULLNAME_ONLY ? [] : [...new Set(NAMES.map((n) => n.split(/\s+/).pop()))];
const OUT = path.join(process.env.SWEEP_OUT || 'data/stance-news', SLUG);
fs.mkdirSync(OUT, { recursive: true });
const LOG = path.join(OUT, '_progress.log');
const log = (s) => { fs.appendFileSync(LOG, s + '\n'); console.log(s); };
fs.writeFileSync(LOG, `sweep ${SLUG} :: ${NAMES.join(' | ')} :: fullname_only=${FULLNAME_ONLY} :: ${new Date().toISOString()}\n`);

// One discriminating word, not a phrase — DNT taught that a longer query can LOSE the corpus.
// `ranked` not `ranked choice`: Saint Paul's own ordinances say "ranked voting", and a search for
// the ladder's words returned a FALSE zero in this slice.
const TOPICS = ['tenant', 'rent', 'housing', 'homeless', 'encampment', 'zoning', 'police', 'safety',
  'immigration', 'ICE', 'budget', 'levy', 'climate', 'energy', 'transit', 'trash', 'garbage',
  'childcare', 'subsidy', 'development', 'wage', 'ranked', 'environment', 'sanitation'];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const get = async (u) => {
  try {
    const r = await fetch(u, { headers: { 'user-agent': UA }, signal: AbortSignal.timeout(25000) });
    return r.ok ? await r.text() : '';
  } catch { return ''; }
};
const getJson = async (u) => { const t = await get(u); try { return JSON.parse(t); } catch { return []; } };

// No URL-shape requirement: a 24-hex-id filter once returned 0 on five rich queries.
const links = (html, host) => {
  const out = new Set();
  for (const m of html.matchAll(/href="([^"#]+)"/g)) {
    let h = m[1];
    try { h = new URL(h, `https://${host}/`).toString().split('?')[0]; } catch { continue; }
    if (!h.includes(host)) continue;
    const p = new URL(h).pathname;
    if (p === '/' || p.length < 12) continue;
    if (/\/(tag|category|author|page|wp-|feed|search|video|weather|obituaries|sports)\b/.test(p)) continue;
    out.add(h);
  }
  return out;
};

// Profiled in outlets.md. MPR News and Racket are JS-rendered and remain UNSOLVED — they are not
// listed here, and no reasoning written from this corpus may claim to have covered them.
// 🔴🔴 MINNESOTA REFORMER IS DELIBERATELY ABSENT. Cloudflare fingerprints the TLS handshake, not
// the UA: this file's `fetch` gets HTTP 403 and 5,795 bytes where `curl` with the SAME user-agent
// gets 200 and 150,559 bytes. Keeping it here would re-create the silent zero that cost this slice
// every Reformer article in all six Duluth corpora and all eight Saint Paul ones, while 490 rows
// of reasoning named it as searched. ▶ Run `sweep_reformer.mjs <slug> "<Name>"` after this — it
// uses curl and merges into the same corpus.
const OUTLETS = [
  { name: 'minnpost.com',          kind: 'wp',   host: 'www.minnpost.com',      gap: 500 },
  { name: 'sahanjournal.com',      kind: 'wp',   host: 'sahanjournal.com',      gap: 500 },
  { name: 'twincities.com',        kind: 'html', host: 'www.twincities.com',    gap: 1200, url: (q) => `https://www.twincities.com/?s=${encodeURIComponent(q)}` },
];

// A baseline per HTML outlet: whatever a nonsense query returns is navigation, not results.
const baseline = new Map();
for (const o of OUTLETS) {
  if (o.kind !== 'html') continue;
  baseline.set(o.name, links(await get(o.url('qzxwvplmdk')), o.host));
  log(`baseline ${o.name}: ${baseline.get(o.name).size} nav links`);
  await sleep(o.gap);
}

const all = new Map();
const perQuery = [];
const perOutlet = new Map(OUTLETS.map((o) => [o.name, 0]));
const runQuery = async (q, label) => {
  let n = 0;
  for (const o of OUTLETS) {
    const found = new Set();
    if (o.kind === 'wp') {
      const a = await getJson(`https://${o.host}/wp-json/wp/v2/search?search=${encodeURIComponent(q)}&per_page=20`);
      for (const x of Array.isArray(a) ? a : []) if (x.url) found.add(x.url);
    } else {
      const base = baseline.get(o.name);
      for (const u of links(await get(o.url(q)), o.host)) if (!base.has(u)) found.add(u);
    }
    for (const u of found) if (!all.has(u)) { all.set(u, { url: u, outlet: o.name, via: label }); perOutlet.set(o.name, perOutlet.get(o.name) + 1); }
    n += found.size;
    await sleep(o.gap);
  }
  perQuery.push({ q, n });
  log(`  [${perQuery.length}] "${q}" -> ${n} hits (corpus ${all.size})`);
};

for (const n of NAMES) await runQuery(n, 'name');
const nameOnly = all.size;
// With FULLNAME_ONLY the topic loop still runs — on the FULL name, which keeps recall without
// making the query a pronoun.
const stems = SURNAMES.length ? SURNAMES : NAMES;
for (const s of stems) for (const t of TOPICS) await runQuery(`${s} ${t}`, 'stem+topic');

log(`\nspellings: ${NAMES.join(' | ')}`);
log(`name-only: ${nameOnly} | corpus unique: ${all.size}`);
// A uniform answer is a broken detector. Print the distribution and the per-outlet contribution.
const zero = perQuery.filter((p) => p.n === 0).length;
log(`queries: ${perQuery.length} | returning zero: ${zero} | max from one query: ${Math.max(...perQuery.map((p) => p.n))}`);
for (const [k, v] of perOutlet) log(`  outlet ${k}: ${v} unique urls contributed${v === 0 ? '  <-- 🔴 CONTRIBUTED NOTHING — treat as blind, not empty' : ''}`);
if (zero === perQuery.length) log('🔴 EVERY QUERY RETURNED ZERO — that is a broken detector, not a finding.');

const queue = [...all.values()];
const named = [];
let ok = 0, bad = 0, done = 0;
const strip = (h) => h.replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, '')
  .replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ')
  .replace(/&#x27;|&#8217;|&rsquo;/g, "'").replace(/&quot;|&#8220;|&#8221;|&ldquo;|&rdquo;/g, '"')
  .replace(/&amp;/g, '&').replace(/&#8212;|&mdash;/g, '—').replace(/\s+/g, ' ').trim();
async function worker() {
  while (queue.length) {
    const a = queue.shift();
    const h = await get(a.url);
    done++;
    if (done % 10 === 0) log(`  fetched ${done}/${all.size}`);
    if (!h) { bad++; continue; }
    ok++;
    const t = strip(h);
    // 🔴 With FULLNAME_ONLY the bare surname is NEVER a keep token — see the header.
    if (NAMES.some((n) => t.includes(n)) || SURNAMES.some((sn) => t.includes(sn))) {
      named.push(a);
      fs.writeFileSync(path.join(OUT, corpusKey(a.url) + '.txt'), scrubText(t).text);
    }
  }
}
await Promise.all([...Array(4)].map(worker));
log(`fetched ${ok} | failed ${bad} | naming the member: ${named.length}`);
fs.writeFileSync(path.join(OUT, '_index.json'), JSON.stringify(named, null, 1));

// 🔴 The key fix is the whole point of this re-sweep, so assert it rather than assume it.
const onDisk = fs.readdirSync(OUT).filter((f) => f.endsWith('.txt')).length;
log(`named ${named.length} | on disk ${onDisk} | ${named.length === onDisk ? '✅ no key collisions' : `🔴 ${named.length - onDisk} LOST — the key is still colliding`}`);
log(`corpus: ${OUT}`);
