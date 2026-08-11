#!/usr/bin/env node
/**
 * PASS 6 -- the 29 PRE-TENURE rows: look for IN-TENURE evidence before retiring any of them.
 *
 * 🔑 THE STANDARD, set by Guzzone (migs 1690 vs 1692): same politician, same pre-tenure prose, OPPOSITE
 * dispositions, because the evidence differed. Her Climate row was RE-SOURCED to three real in-tenure
 * sponsorships; her Vouchers and Taxation rows had no substitute and were retired. So: search first,
 * retire only where nothing is found.
 *
 * Two ways a pre-tenure flag can be wrong rather than right:
 *  1. THE CLAIM NAMES A YEAR INSIDE TENURE and the matcher resolved older bills of the same name
 *     (Odom's "Voting Rights Act of 2026" matched a 2017 Pat Young bill). Check the stated year first.
 *  2. The member has their OWN in-tenure bill on the same subject, which carries the position honestly.
 *
 * 🔴 Reads only. Emits a worklist; retirement is a separate, operator-authorised step.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), CORPUS = flag('--corpus'), CACHE = flag('--cache'), OUT = flag('--out');
if (!IN || !CORPUS || !CACHE || !OUT) { console.error('need --in --corpus --cache --out'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Narrow, topic-specific title vocabularies. Deliberately tight: a wide net returns bills the member
// sponsored that have nothing to do with the chair, which is how a "supporting" citation becomes noise.
const TOPIC_RE = {
  'School Vouchers & Public Education Funding': /voucher|BOOST|nonpublic school|blueprint for maryland/i,
  'Taxation and Public Spending': /income tax|millionaire|capital gains|sales and use tax|tax rate|tax bracket/i,
  'Public Safety Approach': /police accountability|public safety|law enforcement/i,
  'Police Accountability': /police accountability|police discipline|police misconduct/i,
  'Reproductive Rights and Abortion Access': /abortion|reproductive|pregnan/i,
  'Voting Rights and Electoral Integrity': /voting rights|election law|ballot|voter/i,
  'Childcare Affordability & Access': /child care|childcare/i,
  'Climate Change and Environmental Protection': /climate|greenhouse gas|renewable energy/i,
  'Immigration and Treatment of Immigrants': /immigration|immigrant|sanctuary/i,
};

const { bills } = JSON.parse(fs.readFileSync(CORPUS, 'utf8'));
const best = new Map();
for (const b of bills) {
  const k = `${b.session}|${b.number.toUpperCase()}`;
  if (!best.has(k) || b.title.length > best.get(k).title.length) best.set(k, b);
}
const allBills = [...best.values()];

const sponsorCache = new Map();
async function sponsors(slug, session) {
  const key = `${slug}|${session}`;
  if (sponsorCache.has(key)) return sponsorCache.get(key);
  const f = path.join(CACHE, `${slug}-${session}.html`);
  let html = null;
  if (fs.existsSync(f) && fs.statSync(f).size > 20_000) html = fs.readFileSync(f, 'utf8');
  else {
    const res = await fetch(`https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${session}`, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    const body = await res.text();
    await sleep(900);
    if (/Error\/NotFound/i.test(res.url) || body.length < 20_000) { sponsorCache.set(key, null); return null; }
    html = body; fs.writeFileSync(f, html);
  }
  const root = parse(html);
  let dd = null;
  for (const dt of root.querySelectorAll('dt')) if (/sponsored by/i.test(dt.text)) { dd = dt.nextElementSibling; break; }
  const list = dd ? dd.querySelectorAll('a[href*="Members/Details/"]')
    .map((a) => (a.getAttribute('href') || '').match(/Details\/([A-Za-z0-9%]+)/)?.[1]?.toLowerCase()).filter(Boolean) : [];
  sponsorCache.set(key, list);
  return list;
}

const tenure = JSON.parse(fs.readFileSync(IN, 'utf8'));
const rows = tenure.rows.filter((r) => (r.verdict === 'PRE_TENURE_ALL_BILLS' || r.verdict === 'PRE_TENURE_CONFIRMED' || !r.verdict));

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const dburl = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: dburl, ssl: { rejectUnauthorized: false } });
const { rows: slugRows } = await pool.query(`
  SELECT DISTINCT c.politician_id, substring(s from 'Members/Details/([^?#]+)') AS slug
  FROM inform.politician_context c CROSS JOIN LATERAL unnest(c.sources) AS s
  WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Members/Details/%'`);
await pool.end();
const slugBy = new Map(slugRows.filter((r) => r.slug).map((r) => [r.politician_id, decodeURIComponent(r.slug)]));

const out = [];
for (const r of rows) {
  const slug = slugBy.get(r.politician_id);
  const re = TOPIC_RE[r.topic];
  const found = [];
  let checked = 0;
  if (slug && re) {
    const cands = allBills
      .filter((b) => parseInt(b.session, 10) >= r.service_start && re.test(b.title))
      .sort((a, b) => parseInt(b.session, 10) - parseInt(a.session, 10))
      .slice(0, 70);
    for (const b of cands) {
      if (found.length >= 3) break;
      checked++;
      const sp = await sponsors(b.slug, b.session);
      if (sp && sp.includes(slug.toLowerCase())) {
        found.push({ session: b.session, number: b.number, title: b.title,
          url: `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${b.slug}?ys=${b.session}` });
      }
    }
  }
  out.push({
    politician: r.politician, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
    service_start: r.service_start, cited_slug: slug ?? null, reasoning: r.reasoning,
    pre_tenure_bills: r.bills.map((b) => `${b.session} ${b.number}`),
    candidates_checked: checked, in_tenure_sponsorships: found,
    disposition: found.length ? 'RESOURCE_IN_TENURE' : 'NO_IN_TENURE_EVIDENCE',
  });
  console.log(`${found.length ? '✅' : '❌'} ${r.politician} / ${r.topic}  (from ${r.service_start}, checked ${checked})`);
  for (const f of found) console.log(`      ${f.session} ${f.number} :: ${f.title.slice(0, 88)}`);
}

const tally = out.reduce((m, x) => { m[x.disposition] = (m[x.disposition] || 0) + 1; return m; }, {});
console.log('\n' + JSON.stringify(tally, null, 2));
fs.writeFileSync(OUT, JSON.stringify({ pass: 'MD pass 6 - in-tenure evidence for pre-tenure rows', tally, rows: out }, null, 1));
