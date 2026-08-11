#!/usr/bin/env node
/**
 * For rows whose claim cannot rest on the bill pass 4b matched, look for evidence the politician COULD
 * own: a bill on the same subject, sponsored by them, WITHIN THEIR TENURE.
 *
 * Pam Lanman Guzzone took office 2023-01-11, so the 2019 Blueprint and the 2021/22 Climate Solutions Now
 * Act are pre-tenure and cannot be "supported" by her. But a later Blueprint/climate bill she actually
 * sponsored would carry the same stance honestly. Look before concluding.
 *
 * 🔴 Reads only.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const CORPUS = flag('--corpus'), CACHE = flag('--cache');
fs.mkdirSync(CACHE, { recursive: true });
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const { bills } = JSON.parse(fs.readFileSync(CORPUS, 'utf8'));
const best = new Map();
for (const b of bills) {
  const k = `${b.session}|${b.number.toUpperCase()}`;
  if (!best.has(k) || b.title.length > best.get(k).title.length) best.set(k, b);
}
const all = [...best.values()];

async function sponsors(slug, session) {
  const f = path.join(CACHE, `${slug}-${session}.html`);
  let html = null;
  if (fs.existsSync(f) && fs.statSync(f).size > 20_000) html = fs.readFileSync(f, 'utf8');
  else {
    const res = await fetch(`https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${session}`, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    const body = await res.text();
    await sleep(1200);
    if (/Error\/NotFound/i.test(res.url) || body.length < 20_000) return null;
    html = body; fs.writeFileSync(f, html);
  }
  const root = parse(html);
  let dd = null;
  for (const dt of root.querySelectorAll('dt')) if (/sponsored by/i.test(dt.text)) { dd = dt.nextElementSibling; break; }
  if (!dd) return [];
  return dd.querySelectorAll('a[href*="Members/Details/"]')
    .map((a) => (a.getAttribute('href') || '').match(/Details\/([A-Za-z0-9%]+)/)?.[1]?.toLowerCase())
    .filter(Boolean);
}

const SEARCHES = [
  { who: 'Pam Lanman Guzzone', slug: 'guzzone01', from: 2023, topic: 'Climate', re: /climate|greenhouse gas|renewable energy|solar/i, max: 6 },
  { who: 'Pam Lanman Guzzone', slug: 'guzzone01', from: 2023, topic: 'Blueprint/education funding', re: /blueprint for maryland/i, max: 6 },
  { who: 'Veronica Turner', slug: 'turner01', from: 2023, topic: 'Fair housing / housing discrimination', re: /fair housing|housing discrimination|discriminat.{0,30}housing/i, max: 6 },
];

for (const s of SEARCHES) {
  console.log(`\n=== ${s.who} — in-tenure (${s.from}+) bills on: ${s.topic}`);
  const cands = all.filter((b) => parseInt(b.session, 10) >= s.from && s.re.test(b.title));
  console.log(`    ${cands.length} candidate bill(s) in corpus`);
  let found = 0;
  for (const b of cands) {
    if (found >= s.max) { console.log(`    …stopping after ${s.max} confirmed`); break; }
    const sp = await sponsors(b.slug, b.session);
    if (sp && sp.includes(s.slug)) {
      found++;
      console.log(`    ✅ SPONSOR: ${b.session} ${b.number} :: ${b.title.slice(0, 95)}`);
      console.log(`       https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${b.slug}?ys=${b.session}`);
    }
  }
  if (!found) console.log(`    ❌ no in-tenure sponsorship found on this subject`);
}
