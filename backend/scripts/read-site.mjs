#!/usr/bin/env node
/**
 * Read a cited campaign site the way a human would, and grep its RAW HTML for named things.
 *
 * WHY THIS EXISTS. `probe-topic-evidence.mjs` prints only the top-3 passages scored against the
 * COMPASS TOPIC's lexicon. That is deliberate -- it keeps the evidence independent of the row's own
 * claim -- but it means the sentence a row actually rests on is routinely NOT in the output, because
 * the row's supporting line scores 0 or 1 topic terms. Reading "the passages did not mention it" as
 * "the site does not say it" is exactly the false negative that has been corrected eight times on this
 * workstream. So: before any verdict, read the whole page here, and grep the RAW HTML for whatever
 * named thing the row asserts.
 *
 * 🔴 IT SEARCHES THE RAW HTML, NOT JUST THE EXTRACTED BODY, AND PRINTS BOTH LENGTHS. Every
 * false negative found so far came from the extractor silently discarding text -- an unbounded `[...]`
 * strip that deleted 83% of a page, `pageText` scoping to `<main>` and losing the whole issues
 * section, the campaign-finance disclaimer living in the footer. `raw` is tags-stripped HTML with
 * nothing removed but <script>/<style>, so a MISS there is a real absence and a MISS in `body` alone
 * is a report about the extractor. When they disagree, believe `raw`.
 *
 * 🔴 IT PROPOSES NOTHING AND WRITES NOTHING. Output is for a human to read.
 *
 * Usage (from backend/):
 *   node scripts/read-site.mjs --site https://frankbarnitz.com --find "amendment 3|voter id|good enough"
 *   node scripts/read-site.mjs --site https://kirkland2026.com --full
 */
import { parse } from 'node-html-parser';
import { crawlSite } from './lib/site-crawl.mjs';

const argv = process.argv.slice(2);
const many = (n) => argv.reduce((a, v, i) => (v === n && argv[i + 1] ? [...a, argv[i + 1]] : a), []);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const has = (n) => argv.includes(n);

const SITES = [...many('--site'), ...(flag('--sites') ?? '').split(',').filter(Boolean)];
const FIND = (flag('--find') ?? '').split('|').map((s) => s.trim()).filter(Boolean);
const FULL = has('--full');
const CTX = parseInt(flag('--ctx', '160'), 10);
const MAXHITS = parseInt(flag('--maxhits', '4'), 10);
const CRAWL = { hostDelay: 900, maxPages: 8, minBody: 600, cacheTtlHours: 24, noCache: has('--no-cache') };

if (!SITES.length) { console.error('give at least one --site'); process.exit(2); }

/** Everything the page says, with only script/style gone. The maximal honest haystack. */
function rawText(html) {
  const root = parse(html);
  root.querySelectorAll('script,style,noscript').forEach((n) => n.remove());
  return root.textContent.replace(/\s+/g, ' ').trim();
}

const fold = (s) => s.toLowerCase().replace(/[‘’]/g, "'").replace(/[“”]/g, '"').replace(/\s+/g, ' ');

function hits(haystack, needle) {
  const H = fold(haystack); const N = fold(needle);
  const out = []; let i = H.indexOf(N);
  while (i > -1 && out.length < MAXHITS) {
    out.push(haystack.slice(Math.max(0, i - CTX), Math.min(haystack.length, i + N.length + CTX)).trim());
    i = H.indexOf(N, i + N.length);
  }
  return out;
}

for (const site of SITES) {
  console.log(`\n${'='.repeat(100)}\n${site}\n${'='.repeat(100)}`);
  let s;
  try { s = await crawlSite(site, CRAWL); }
  catch (e) { console.log(`crawl threw: ${e.message}`); continue; }
  if (!s.ok) { console.log(`⚠ UNREADABLE: ${s.reason} (dead=${!!s.dead}) — this says nothing about the rows`); continue; }

  const raws = s.pages.map((p) => ({ url: p.url, raw: rawText(p.html), body: p.body, chrome: p.chrome ?? '' }));
  console.log(`${raws.length} page(s):`);
  for (const p of raws) console.log(`  ${p.url}  raw=${p.raw.length}c body=${p.body.length}c chrome=${p.chrome.length}c`);

  for (const needle of FIND) {
    const rHit = raws.flatMap((p) => hits(p.raw, needle).map((h) => ({ url: p.url, h })));
    const bHit = raws.reduce((n, p) => n + hits(p.body, needle).length, 0);
    console.log(`\n  FIND "${needle}": raw=${rHit.length ? `${rHit.length} HIT` : 'MISS'}  body=${bHit ? `${bHit} hit` : 'MISS'}`);
    for (const { url, h } of rHit) console.log(`    · …${h}…\n      ${url}`);
  }

  if (FULL) {
    for (const p of raws) {
      console.log(`\n${'-'.repeat(100)}\n--- BODY ${p.url} (${p.body.length}c)\n${p.body}`);
      if (p.chrome) console.log(`\n--- CHROME (${p.chrome.length}c)\n${p.chrome}`);
    }
  }
}
