#!/usr/bin/env node
/**
 * Resolve the named Acts cited by Massachusetts Tier-A rows to REAL malegislature.gov bills.
 *
 * 🔴 WHY THIS IS NOT A SEARCH SCRIPT: searching "Affordable Homes Act" returns /Bills/194/H1551,
 * "An Act relative to the Affordable Homes Act" -- a LATER bill referencing the Act, not the Act.
 * Same shape as the CROWN Act -> "Crown and Care Act" trap (MD mig 1686). So this script only
 * GATHERS candidates; a human picks, and every pick is confirmed by fetching the bill page.
 *
 * ⚠ A MA BILL NUMBER IS MEANINGLESS WITHOUT ITS GENERAL COURT. H.4805 is "work and family mobility"
 * in the 192nd and "Boston property tax classification" in the 193rd. Same trap as MD bare numbers.
 * Sessions: 191st = 2019-20 · 192nd = 2021-22 · 193rd = 2023-24 · 194th = 2025-26.
 *
 * 🔴 Reads only.
 *   node scripts/ma-resolve-acts.mjs --worklist <tier-a.json> --cache <dir> --out <candidates.json>
 */
import fs from 'node:fs';
import path from 'node:path';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const WL = flag('--worklist'), CACHE = flag('--cache'), OUT = flag('--out');
if (!WL || !CACHE || !OUT) { console.error('need --worklist --cache --out'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function get(url, file) {
  const f = path.join(CACHE, file);
  if (fs.existsSync(f) && fs.statSync(f).size > 5_000) return fs.readFileSync(f, 'utf8');
  const res = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
  const body = await res.text();
  fs.writeFileSync(f, body);
  await sleep(1300);
  return body;
}

const strip = (h) => h.replace(/<script[\s\S]*?<\/script>/g, ' ').replace(/<style[\s\S]*?<\/style>/g, ' ')
  .replace(/<[^>]+>/g, ' ').replace(/&#\d+;/g, ' ').replace(/\s+/g, ' ');

const wl = JSON.parse(fs.readFileSync(WL, 'utf8'));
const maRows = wl.rows.filter((r) => r.state === 'MA' && r.has_instrument);
const acts = new Map();
for (const r of maRows) for (const i of r.instruments) acts.set(i, (acts.get(i) || 0) + 1);
const ordered = [...acts.entries()].sort((a, b) => b[1] - a[1]);
console.log(`${maRows.length} MA rows name ${ordered.length} distinct instruments\n`);

const out = [];
for (const [act, n] of ordered) {
  const html = await get(
    `https://malegislature.gov/Bills/Search?SearchTerms=${encodeURIComponent(act)}&Page=1`,
    `search-${act.replace(/[^A-Za-z0-9]+/g, '_')}.html`);
  const seen = new Map();
  for (const m of html.matchAll(/href="(\/Bills\/(\d+)\/([A-Z]+\d+))"[^>]*>\s*([^<]{6,150})</g)) {
    const [, href, gc, num, label] = m;
    const title = label.trim().replace(/\s+/g, ' ');
    if (/^[A-Z]\.\d+$/.test(title)) continue;          // the bare "H.1551" link, not the title
    if (!seen.has(href)) seen.set(href, { gc: Number(gc), num, title, url: `https://malegislature.gov${href}` });
  }
  const cands = [...seen.values()].sort((a, b) => b.gc - a.gc).slice(0, 8);
  out.push({ act, rows_citing: n, candidates: cands });
  console.log(`### "${act}"  (${n} row${n > 1 ? 's' : ''})`);
  if (!cands.length) console.log('    (no candidates -- may predate the site index, or be a budget amendment)');
  for (const c of cands) console.log(`    ${c.gc}th ${c.num.padEnd(7)} ${c.title.slice(0, 92)}`);
  console.log('');
}

fs.writeFileSync(OUT, JSON.stringify({
  note: 'CANDIDATES ONLY. A search hit whose title merely CONTAINS the act name is not the act '
      + '(e.g. "An Act relative to the Affordable Homes Act" is a later bill referencing it). '
      + 'A human must pick, and each pick must be confirmed by fetching the bill page.',
  acts: out,
}, null, 1));
