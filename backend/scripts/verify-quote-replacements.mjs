#!/usr/bin/env node
/**
 * Confirm that every replacement quote a correction migration intends to write is VERBATIM on the
 * page that row cites -- before the migration is written, and again before it is applied.
 *
 * 🔴 THE WHOLE POINT OF THE CORRECTION PASS IS THAT THE NEW TEXT IS EXACTLY WHAT THE SOURCE SAYS.
 * A pass that replaces one inexact quotation with another inexact quotation has done nothing except
 * move the fabrication, and `inform.politician_context.reasoning` is voter-facing -- Citations.jsx
 * renders it under "Why this position?". So each proposed string is checked against the live page
 * with the same normalisation the matchers use, and anything that does not verify is REFUSED rather
 * than downgraded to a warning.
 *
 * Input is the hand-written proposals file; this script never invents a replacement.
 *
 * Usage (from backend/):  node scripts/verify-quote-replacements.mjs data/stance-retirement/<file>.json
 */
import { readFileSync } from 'node:fs';
import { crawlSite } from './lib/site-crawl.mjs';
import { norm } from './lib/claim-match.mjs';

const file = process.argv[2];
if (!file) { console.error('usage: verify-quote-replacements.mjs <proposals.json>'); process.exit(2); }
const proposals = JSON.parse(readFileSync(file, 'utf8')).proposals;

const CRAWL = { hostDelay: 900, maxPages: 8, minBody: 600, cacheTtlHours: 24 };

const bySite = new Map();
for (const p of proposals) {
  if (!bySite.has(p.cited)) bySite.set(p.cited, []);
  bySite.get(p.cited).push(p);
}

let ok = 0; const bad = [];
for (const [site, rows] of bySite) {
  const s = await crawlSite(site, CRAWL);
  if (!s.ok) {
    for (const r of rows) bad.push({ ...r, why: `site unreadable: ${s.reason}` });
    continue;
  }
  // Body AND chrome: a campaign-finance disclaimer lives outside <main>. See lib/site-crawl.mjs.
  const hay = norm(s.pages.map((p) => `${p.body} ${p.chrome ?? ''}`).join(' '));
  for (const r of rows) {
    for (const q of r.verbatim) {
      if (hay.includes(norm(q))) { ok += 1; continue; }
      bad.push({ ...r, why: `NOT verbatim on site: "${q}"` });
    }
  }
}

console.log(`verbatim strings checked: ${ok + bad.length} — verified ${ok}, FAILED ${bad.length}`);
for (const b of bad) console.log(`  ✗ ${b.name} / ${b.topic}: ${b.why}`);
if (bad.length) { console.error('\nREFUSED — do not write a migration until every string verifies.'); process.exit(1); }
console.log('\nAll replacement quotes verified verbatim against the cited sites.');
