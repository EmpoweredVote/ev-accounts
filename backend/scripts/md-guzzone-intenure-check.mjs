#!/usr/bin/env node
/**
 * Pam Lanman Guzzone took office 2023-01-11. Her School-Vouchers and Taxation rows both rest on the
 * Blueprint for Maryland's Future (2019/2020) -- PRE-TENURE, so she cannot have supported it.
 * Before treating those rows as unsupported, check the narrow in-tenure bill sets that match each topic.
 * 🔴 Reads only.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';

const SP = 'C:/Users/Chris/AppData/Local/Temp/claude/C--Transparent-Motivations-essentials/e4020c4c-d50e-4836-a8c8-b0f2054682dc/scratchpad';
const CACHE = SP + '/mga-bills';
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const SLUG = 'guzzone01';

const { bills } = JSON.parse(fs.readFileSync(SP + '/md-bill-corpus.json', 'utf8'));
const best = new Map();
for (const b of bills) {
  const k = `${b.session}|${b.number.toUpperCase()}`;
  if (!best.has(k) || b.title.length > best.get(k).title.length) best.set(k, b);
}
const all = [...best.values()].filter((b) => parseInt(b.session, 10) >= 2023);

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
    .map((a) => (a.getAttribute('href') || '').match(/Details\/([A-Za-z0-9%]+)/)?.[1]?.toLowerCase()).filter(Boolean);
}

for (const [label, re] of [
  ['School Vouchers & Public Education Funding', /voucher|BOOST|nonpublic school/i],
  ['Taxation and Public Spending', /income tax.{0,40}(rate|bracket)|millionaire|capital gains/i],
]) {
  const cands = all.filter((b) => re.test(b.title));
  console.log(`\n=== ${label}: checking ${cands.length} in-tenure bills for ${SLUG}`);
  let found = 0;
  for (const b of cands) {
    const sp = await sponsors(b.slug, b.session);
    if (sp && sp.includes(SLUG)) {
      found++;
      console.log(`  ✅ SPONSOR ${b.session} ${b.number} :: ${b.title.slice(0, 95)}`);
    }
  }
  if (!found) console.log(`  ❌ NOT a sponsor of any of the ${cands.length}`);
}
