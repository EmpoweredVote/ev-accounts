#!/usr/bin/env node
/**
 * Does each Maryland stance's cited mgaleg MEMBER slug actually belong to the politician it is filed under?
 *
 * Found while adjudicating pass 4c: `jones01` is **Dana Jones**, but it is cited by every stance of
 * **Adrienne A. Jones**. That is a citation to a DIFFERENT POLITICIAN -- a strictly worse defect than
 * the generic-page problem this workstream started on, and invisible to every check so far because the
 * page resolves, is a real member page, and carries the right surname.
 *
 * Verdicts: OK | WRONG_PERSON | DEAD_SLUG | UNRESOLVED
 * 🔴 Reads only. Writes no DB changes.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const MEMCACHE = flag('--members'), OUT = flag('--out');
if (!MEMCACHE) { console.error('need --members'); process.exit(2); }
fs.mkdirSync(MEMCACHE, { recursive: true });
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

// Every politician whose stances cite an mgaleg member page, and the slug(s) they cite.
const { rows } = await pool.query(`
  SELECT p.full_name, c.politician_id,
         count(*) AS row_ct,
         array_agg(DISTINCT substring(s from 'Members/Details/([A-Za-z0-9]+)')) AS slugs
  FROM inform.politician_context c
  JOIN essentials.politicians p ON p.id = c.politician_id
  CROSS JOIN LATERAL unnest(c.sources) AS s
  WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Members/Details/%'
  GROUP BY p.full_name, c.politician_id
  ORDER BY p.full_name`);
await pool.end();

const SESSIONS = ['2026RS', '2025RS', '2023RS', '2021RS', '2019RS'];
const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim().split(/\s+/).pop().toLowerCase();
const firstOf = (n) => n.trim().split(/\s+/)[0].toLowerCase();

const cache = new Map();
async function nameFor(slug) {
  if (cache.has(slug)) return cache.get(slug);
  const file = path.join(MEMCACHE, `${slug}.html`);
  let html = null;
  if (fs.existsSync(file) && fs.statSync(file).size > 10_000) {
    const c = fs.readFileSync(file, 'utf8');
    if (!/Error\/NotFound/.test(c.slice(0, 4000))) html = c;
  }
  if (!html) {
    const tries = [`https://mgaleg.maryland.gov/mgawebsite/Members/Details/${slug}`,
      ...SESSIONS.map((s) => `https://mgaleg.maryland.gov/mgawebsite/Members/Details/${slug}?ys=${s}`)];
    for (const u of tries) {
      const res = await fetch(u, { headers: { 'User-Agent': UA }, redirect: 'follow' });
      const body = await res.text();
      await sleep(1400);
      if (/Error\/NotFound/i.test(res.url) || body.length < 10_000) continue;
      html = body; fs.writeFileSync(file, html); break;
    }
  }
  if (!html) { cache.set(slug, null); return null; }
  const t = parse(html).querySelector('title')?.text ?? '';
  const nm = t.replace(/^\s*Members\s*-\s*/i, '').replace(/^(Senator|Delegate)\s+/i, '').trim();
  const val = nm && !/^NotFound$/i.test(nm) ? nm : null;
  cache.set(slug, val);
  return val;
}

const out = [];
for (const r of rows) {
  for (const slug of r.slugs.filter(Boolean)) {
    const nm = await nameFor(slug);
    let verdict;
    if (nm === null) verdict = 'DEAD_SLUG';
    else if (surnameOf(nm) === surnameOf(r.full_name) && firstOf(nm) === firstOf(r.full_name)) verdict = 'OK';
    else if (surnameOf(nm) === surnameOf(r.full_name)) verdict = 'WRONG_PERSON_SAME_SURNAME';
    else verdict = 'WRONG_PERSON';
    out.push({ politician: r.full_name, politician_id: r.politician_id, rows: Number(r.row_ct), cited_slug: slug, slug_belongs_to: nm, verdict });
  }
}

const tally = out.reduce((m, x) => { m[x.verdict] = (m[x.verdict] || 0) + 1; return m; }, {});
console.log('politicians citing an mgaleg member page:', rows.length);
console.log(JSON.stringify(tally, null, 2));
console.log('\n=== NOT OK ===');
for (const x of out.filter((y) => y.verdict !== 'OK')) {
  console.log(`  [${x.verdict}] ${x.politician} (${x.rows} rows) cites ${x.cited_slug} -> ${x.slug_belongs_to ?? 'DOES NOT RESOLVE'}`);
}
if (OUT) fs.writeFileSync(OUT, JSON.stringify({ audit: 'MD cited member-slug identity', tally, rows: out }, null, 1));
