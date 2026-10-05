// Sweep Minnesota Reformer for one member and MERGE into an existing corpus.
// Usage: node sweep_reformer.mjs <slug> "Full Name" [alias ...]
//
// 🔴🔴 WHY THIS IS A SEPARATE TOOL: CLOUDFLARE FINGERPRINTS THE TLS HANDSHAKE, NOT THE UA.
// Measured 2026-10-05, same URL, same user-agent, same machine, same minute:
//
//     node fetch()  ->  HTTP 403,     5,795 bytes, 0 article links
//     curl          ->  HTTP 200,   150,559 bytes, 6 article links
//
// So Reformer was profiled with curl, recorded as "✅ passed", and then swept with node's fetch,
// which it refuses. The result: **Reformer contributed ZERO articles to every corpus in this
// slice** — randorf 0/50, durrwachter 0/38, forsman 0/79, nephew 0/42, kennedy 0/359,
// reinert 0/146, and all of Saint Paul — while 490 rows of reasoning name it as an outlet that
// was searched. Nothing errored, because the 403 was swallowed by a `catch {}` / `r.ok` test.
//
// ▶ THE RULE: PROFILE WITH THE CLIENT THAT WILL DO THE WORK. A UA is not a client. curl, node
// fetch and a browser present three different TLS fingerprints, and a WAF can accept one and
// refuse another with the same headers. An outlet listed as working that contributes nothing to
// a sweep is the signature — count per-outlet contributions on every run.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { scrubText } from './scrub_corpus.mjs';

const exec = promisify(execFile);
const corpusKey = (url) => crypto.createHash('sha1').update(url).digest('hex').slice(0, 24);
const UA = 'EmpoweredVoteBot/1.0 (+https://empowered.vote/crawler; nonprofit civic citation verification; contact info@empowered.vote)';

const SLUG = process.argv[2];
const NAMES = process.argv.slice(3);
if (!SLUG || !NAMES.length) { console.error('usage: sweep_reformer.mjs <slug> "Name" [alias ...]'); process.exit(1); }
const FULLNAME_ONLY = process.env.FULLNAME_ONLY === '1';
const SURNAMES = FULLNAME_ONLY ? [] : [...new Set(NAMES.map((n) => n.split(/\s+/).pop()))];
const DIR = path.join(process.env.SWEEP_OUT || 'data/stance-news', SLUG);
if (!fs.existsSync(DIR)) { console.error(`no corpus at ${DIR} — run sweep_stpaul.mjs first`); process.exit(1); }

// EXTRA_TOPICS adds city-specific discriminating words, comma-separated. Duluth's own sweep used
// levy, energy, garbage and vacation (its short-term-rental fight), none of which a Saint Paul
// list would carry.
const TOPICS = ['tenant', 'rent', 'housing', 'homeless', 'encampment', 'zoning', 'police', 'safety',
  'immigration', 'ICE', 'budget', 'climate', 'transit', 'trash', 'childcare', 'subsidy',
  'development', 'wage', 'ranked', 'environment',
  ...(process.env.EXTRA_TOPICS ? process.env.EXTRA_TOPICS.split(',').map((s) => s.trim()).filter(Boolean) : [])];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// 🔴🔴 REFORMER RATE-LIMITS, AND A 429 IS A 140-BYTE PAGE THAT PARSES TO ZERO LINKS.
// Measured 2026-10-05: after roughly four members' worth of queries the host began returning
//   <html><head><title>429, Rate Limited</title></head>…<p>Wait a minute and try again</p>
// Returning that body to the caller makes every remaining query record "0 candidates" — the exact
// silent zero this whole tool exists to prevent, reappearing one layer in. So: read the status
// code, back off on 429, and ABORT rather than finish a run on throttled data.
let aborted = null;
const curl = async (url, tries = 4) => {
  for (let i = 0; i < tries; i++) {
    try {
      const { stdout } = await exec('curl', ['-sL', '--compressed', '--max-time', '25',
        '-w', '\\n__HTTP__%{http_code}', '-A', UA, url], { maxBuffer: 32 * 1024 * 1024 });
      const m = /\n__HTTP__(\d{3})$/.exec(stdout);
      const code = m ? Number(m[1]) : 0;
      const body = m ? stdout.slice(0, m.index) : stdout;
      if (code === 429 || /429, Rate Limited/.test(body)) {
        const wait = 20000 * (i + 1);
        console.log(`    ⏳ 429 from Reformer — waiting ${wait / 1000}s (attempt ${i + 1}/${tries})`);
        await sleep(wait);
        continue;
      }
      if (code >= 400) return '';
      return body;
    } catch { return ''; }
  }
  aborted = 'rate-limited after retries';
  return '';
};
const articleLinks = (html) => new Set(
  [...html.matchAll(/href="(https:\/\/minnesotareformer\.com\/20\d\d\/[^"#]+)"/g)].map((m) => m[1].split('?')[0]),
);

// 🔴 Differential control FIRST. A uniform answer is a broken detector until a control proves
// otherwise, and this outlet has already produced one silent zero in this programme.
const ctlReal = articleLinks(await curl('https://minnesotareformer.com/?s=Saint%20Paul'));
await sleep(800);
const ctlJunk = articleLinks(await curl('https://minnesotareformer.com/?s=qzxwvplmdk'));
console.log(`control: "Saint Paul" -> ${ctlReal.size} links | gibberish -> ${ctlJunk.size} links`);
if (ctlReal.size === 0) { console.error('🔴 CONTROL FAILED: a real query returned nothing. Reformer is blind to this client — do NOT record it as searched.'); process.exit(2); }
if (ctlReal.size === ctlJunk.size) { console.error('🔴 CONTROL FAILED: real and gibberish queries agree. The extractor is not discriminating.'); process.exit(2); }

const found = new Map();
const stems = SURNAMES.length ? SURNAMES : NAMES;
const queries = [...NAMES, ...stems.flatMap((s) => TOPICS.map((t) => `${s} ${t}`))];
let qn = 0;
for (const q of queries) {
  const links = articleLinks(await curl(`https://minnesotareformer.com/?s=${encodeURIComponent(q)}`));
  let add = 0;
  for (const u of links) if (!ctlJunk.has(u) && !found.has(u)) { found.set(u, q); add++; }
  qn++;
  if (add) console.log(`  [${qn}/${queries.length}] "${q}" -> +${add} (total ${found.size})`);
  if (aborted) { console.error(`🔴 ABORTING at query ${qn}/${queries.length}: ${aborted}. Nothing recorded — re-run after a cooldown.`); process.exit(3); }
  await sleep(1500);
}
console.log(`reformer candidates: ${found.size}`);

// 🔴 A CONTROL AT THE START PROVES NOTHING ABOUT THE END OF A LONG RUN. The host began throttling
// partway through the Duluth backfill, and an opening control cannot see that. Re-run it.
const ctlEnd = articleLinks(await curl('https://minnesotareformer.com/?s=Saint%20Paul'));
console.log(`closing control: "Saint Paul" -> ${ctlEnd.size} links (opened at ${ctlReal.size})`);
if (ctlEnd.size === 0) {
  console.error('🔴 CLOSING CONTROL FAILED — the host stopped answering during this run, so every');
  console.error('   query after that point recorded a FALSE zero. Nothing recorded. Re-run after a cooldown.');
  process.exit(3);
}

const strip = (h) => h.replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, '')
  .replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ')
  .replace(/&#x27;|&#8217;|&rsquo;/g, "'").replace(/&quot;|&#8220;|&#8221;|&ldquo;|&rdquo;/g, '"')
  .replace(/&amp;/g, '&').replace(/&#8212;|&mdash;/g, '—').replace(/\s+/g, ' ').trim();

const idxPath = path.join(DIR, '_index.json');
const idx = JSON.parse(fs.readFileSync(idxPath, 'utf8'));
const have = new Set(idx.map((e) => e.url));
let added = 0, fetched = 0;
for (const [u, via] of found) {
  const h = await curl(u);
  fetched++;
  if (!h) continue;
  const t = strip(h);
  if (!(NAMES.some((n) => t.includes(n)) || SURNAMES.some((s) => t.includes(s)))) continue;
  fs.writeFileSync(path.join(DIR, corpusKey(u) + '.txt'), scrubText(t).text);
  if (!have.has(u)) { idx.push({ url: u, outlet: 'minnesotareformer.com', via: `reformer:${via}` }); added++; }
  await sleep(400);
}
fs.writeFileSync(idxPath, JSON.stringify(idx, null, 1));
const onDisk = fs.readdirSync(DIR).filter((f) => f.endsWith('.txt')).length;
console.log(`fetched ${fetched} | naming the member and ADDED: ${added}`);
console.log(`corpus index now ${idx.length} | files on disk ${onDisk} | ${idx.length === onDisk ? '✅ consistent' : `🔴 ${idx.length - onDisk} MISSING`}`);
fs.appendFileSync(path.join(DIR, '_progress.log'), `reformer(curl): +${added} articles, index ${idx.length}, disk ${onDisk}\n`);
