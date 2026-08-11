#!/usr/bin/env node
/**
 * The 11 REJECT rows named a bill NUMBER together with a YEAR ("HB0480 (2026)"). Pass 4b resolved bare
 * numbers across ALL sessions and landed on 2013-2015 bills sponsored by a different same-surname member.
 * That may have wronged the row: check the SESSION THE REASONING ACTUALLY STATES.
 *
 * 🔴 Reads only.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const CORPUS = flag('--corpus'), CACHE = flag('--cache');
if (!CORPUS || !CACHE) { console.error('need --corpus --cache'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const { bills } = JSON.parse(fs.readFileSync(CORPUS, 'utf8'));
// The corpus holds two rows per bill; the real title is the longer one.
const best = new Map();
for (const b of bills) {
  const k = `${b.session}|${b.number.toUpperCase()}`;
  if (!best.has(k) || b.title.length > best.get(k).title.length) best.set(k, b);
}
const byTitle = [...best.values()];

async function sponsorsOf(slug, session) {
  const f = path.join(CACHE, `${slug}-${session}.html`);
  let html = null;
  if (fs.existsSync(f) && fs.statSync(f).size > 20_000) html = fs.readFileSync(f, 'utf8');
  else {
    const res = await fetch(`https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${session}`, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    const body = await res.text();
    await sleep(1300);
    if (/Error\/NotFound/i.test(res.url) || body.length < 20_000) return null;
    html = body; fs.writeFileSync(f, html);
  }
  const root = parse(html);
  let dd = null;
  for (const dt of root.querySelectorAll('dt')) if (/sponsored by/i.test(dt.text)) { dd = dt.nextElementSibling; break; }
  if (!dd) return [];
  return dd.querySelectorAll('a[href*="Members/Details/"]').map((a) => ({
    slug: (a.getAttribute('href') || '').match(/Details\/([A-Za-z0-9%]+)/)?.[1]?.toLowerCase() ?? null,
    name: a.text.trim(),
  }));
}

// What each row CLAIMS, with the year it states.
const CLAIMS = [
  { who: 'Caylin Young', slug: 'young05', topic: 'Voting Rights and Electoral Integrity', session: '2026RS', titleLike: /voting rights act/i, num: null,
    claim: 'sponsored Voting Rights Act of 2026 - Counties and Municipal Corporations' },
  { who: 'Veronica Turner', slug: 'turner01', topic: 'Affordable Housing', session: '2026RS', titleLike: null, num: 'HB0480',
    claim: 'Sponsored HB0480 (2026) Fair Housing / discrimination reform' },
  { who: 'Veronica Turner', slug: 'turner01', topic: 'Criminal Justice Approach', session: '2026RS', titleLike: /exonerated/i, num: 'HB0574',
    claim: 'Sponsored Exonerated 5 Act (HB0574, 2026)' },
  { who: 'Veronica Turner', slug: 'turner01', topic: 'Criminal Justice Approach', session: '2026RS', titleLike: /racial disparit/i, num: 'HB0810',
    claim: 'sponsored HB0810 commission on racial disparities' },
];

for (const c of CLAIMS) {
  console.log(`\n=== ${c.who} / ${c.topic}`);
  console.log(`    claim: ${c.claim}`);
  const cands = [];
  if (c.num) { const b = best.get(`${c.session}|${c.num}`); if (b) cands.push(b); }
  if (c.titleLike) cands.push(...byTitle.filter((b) => b.session === c.session && c.titleLike.test(b.title)));
  if (!cands.length) { console.log(`    ⚠ nothing in ${c.session} matches`); continue; }
  for (const b of [...new Map(cands.map((b) => [b.number, b])).values()].slice(0, 4)) {
    const sp = await sponsorsOf(b.slug, b.session);
    const hit = sp && sp.some((s) => s.slug === c.slug);
    const names = sp ? sp.slice(0, 4).map((s) => s.name).join(', ') : 'PAGE UNAVAILABLE';
    console.log(`    ${b.session} ${b.number} :: ${b.title.slice(0, 95)}`);
    console.log(`      sponsors: ${names}${sp && sp.length > 4 ? ` …+${sp.length - 4}` : ''}`);
    console.log(`      ${hit ? '✅ THE ROW IS RIGHT — ' + c.slug + ' IS a sponsor' : '❌ ' + c.slug + ' is NOT a sponsor of this bill'}`);
  }
}
