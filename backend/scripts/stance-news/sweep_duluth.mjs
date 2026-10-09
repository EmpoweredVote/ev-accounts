// Build a Duluth news corpus for one member, across the three outlets that WORK here.
// Usage: node sweep_duluth.mjs <slug> "Primary Name" ["Alias" ...]
//
// Why this exists: sweep_member.mjs hardcodes MinnPost, Sahan Journal and Minnesota Reformer —
// three Twin Cities outlets that barely cover Duluth. Run with those alone it reports a thin
// corpus that is an artifact of its own outlet list. See README "Duluth additions".
//
// Five rules this encodes, each paid for (2026-10-05):
//  1. The UA is the VERIFIER's. Minnesota Reformer 403s a Chrome UA and serves this one a clean 200.
//  2. Link extraction must not require a URL shape. A 24-hex-id filter returned 0 on five DNT
//     queries over a rich corpus — only DNT's *letters* URLs carry an id, its news URLs do not.
//  3. Query breadth must match the SEARCH ENGINE. DNT ORs its terms and ranks badly, so the single
//     word `tenant` found the whole right-to-repair corpus that `right to repair` missed.
//  4. 🔴 EVERY FETCH NEEDS A TIMEOUT. The first version had none; one hung request stalled the whole
//     sweep for 45 minutes with the process alive and flat CPU — indistinguishable from slow work.
//  5. 🔴 PROGRESS MUST BE FLUSHED TO A FILE. Buffered dots are invisible when stdout is redirected,
//     so a stalled run and a working one look identical. Watch <out>/_progress.log.
import fs from 'node:fs';
import path from 'node:path';

import crypto from 'node:crypto';
// 🔴 A scraped news page carries OTHER PEOPLE'S keys. GitHub push protection rejected a whole push
// because a MinnPost election page embedded a Mapbox secret token in its map widget. Redact on write.
import { scrubText } from './scrub_corpus.mjs';
// 🔴🔴 Corpus filenames were base64url(url).slice(0, 60). 45 bytes of URL is not past a shared
// path prefix, so SIXTEEN Duluth News Tribune news articles wrote to ONE file and 50 named
// articles became 26 on disk — a corpus that looked complete and was half gone. Hash the WHOLE
// url. Any truncation of a key derived from a structured string collides where the structure is.
const corpusKey = (url) => crypto.createHash('sha1').update(url).digest('hex').slice(0, 24);

const UA = 'EmpoweredVoteBot/1.0 (+https://empowered.vote/crawler; nonprofit civic citation verification; contact info@empowered.vote)';
const SLUG = process.argv[2];
const NAMES = process.argv.slice(3);
if (!SLUG || !NAMES.length) { console.error('usage: sweep_duluth.mjs <slug> "Name" [alias ...]'); process.exit(1); }
// 🔴 EVERY variant's surname is swept, not just the first one's. WDIO spells Wendy Durrwachter as
// "Durwachter" (one r) throughout its coverage, so a surname+topic loop over NAMES[0] alone misses
// that outlet entirely — and so does the corpus name filter below. This is the HwaJeong / Hwa Jeong
// Kim lesson one layer on: it is not only the full NAME that varies, it is the SURNAME inside it.
const SURNAMES = [...new Set(NAMES.map((n) => n.split(/\s+/).pop()))];
const SURNAME = SURNAMES[0];
const OUT = path.join(process.env.SWEEP_OUT || 'data/stance-news', SLUG);
fs.mkdirSync(OUT, { recursive: true });
const LOG = path.join(OUT, '_progress.log');
const log = (s) => { fs.appendFileSync(LOG, s + '\n'); console.log(s); };
fs.writeFileSync(LOG, `sweep ${SLUG} :: ${NAMES.join(' | ')} :: ${new Date().toISOString()}\n`);

// One discriminating word, not a phrase — rule 3.
const TOPICS = ['tenant', 'housing', 'rent', 'homeless', 'encampment', 'zoning', 'police', 'safety',
  'immigration', 'budget', 'levy', 'climate', 'energy', 'transit', 'garbage', 'childcare',
  'subsidy', 'development', 'wage', 'ranked', 'environment', 'vacation'];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const get = async (u) => {
  try {
    const r = await fetch(u, { headers: { 'user-agent': UA }, signal: AbortSignal.timeout(25000) });
    return r.ok ? await r.text() : '';
  } catch { return ''; }
};
const getJson = async (u) => { const t = await get(u); try { return JSON.parse(t); } catch { return []; } };

// No URL-shape requirement — rule 2. Only drop obvious non-articles.
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

const OUTLETS = [
  { name: 'duluthnewstribune.com', kind: 'html', host: 'www.duluthnewstribune.com', gap: 2500, url: (q) => `https://www.duluthnewstribune.com/search?q=${encodeURIComponent(q)}` },
  { name: 'wdio.com',              kind: 'html', host: 'www.wdio.com',             gap: 800,  url: (q) => `https://www.wdio.com/?s=${encodeURIComponent(q)}` },
  { name: 'duluthmonitor.com',     kind: 'wp',   host: 'duluthmonitor.com',        gap: 500 },
  { name: 'minnpost.com',          kind: 'wp',   host: 'www.minnpost.com',         gap: 500 },
  { name: 'sahanjournal.com',      kind: 'wp',   host: 'sahanjournal.com',         gap: 500 },
  // 🔴🔴 MINNESOTA REFORMER REMOVED 2026-10-05. Rule 1 above says this file sends the verifier's
  // UA because Reformer 403s a Chrome one. That was true and INSUFFICIENT: Cloudflare fingerprints
  // the TLS handshake, so node's `fetch` is refused whatever UA it carries — 403 and 5,795 bytes,
  // where `curl` with the same UA gets 200 and 150,559. The 403 died in `get`'s `catch`, and
  // Reformer supplied ZERO articles to all six Duluth corpora while 109 rows said it was searched.
  // ▶ Run `sweep_reformer.mjs <slug> "<Name>"` — it uses curl, merges into this same corpus, and
  //   runs a differential control at BOTH ends of the run.
  // ▶ A UA IS NOT A CLIENT. Profile with the client that will do the work.
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
    for (const u of found) if (!all.has(u)) all.set(u, { url: u, outlet: o.name, via: label });
    n += found.size;
    await sleep(o.gap);
  }
  perQuery.push({ q, n });
  log(`  [${perQuery.length}] "${q}" -> ${n} hits (corpus ${all.size})`);
};

for (const n of NAMES) await runQuery(n, 'name');
const nameOnly = all.size;
for (const sn of SURNAMES) for (const t of TOPICS) await runQuery(`${sn} ${t}`, 'surname+topic');

log(`\nspellings: ${NAMES.join(' | ')}`);
log(`name-only: ${nameOnly} | corpus unique: ${all.size}`);
// README rule 5: a uniform answer is a broken detector. Print the distribution.
const zero = perQuery.filter((p) => p.n === 0).length;
log(`queries: ${perQuery.length} | returning zero: ${zero} | max from one query: ${Math.max(...perQuery.map((p) => p.n))}`);
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
    if (NAMES.some((n) => t.includes(n)) || SURNAMES.some((sn) => t.includes(sn))) {
      named.push(a);
      fs.writeFileSync(path.join(OUT, corpusKey(a.url) + '.txt'), scrubText(t).text);
    }
  }
}
await Promise.all([...Array(4)].map(worker));
log(`fetched ${ok} | failed ${bad} | naming the member: ${named.length}`);
fs.writeFileSync(path.join(OUT, '_index.json'), JSON.stringify(named, null, 1));
log(`corpus: ${OUT}`);
