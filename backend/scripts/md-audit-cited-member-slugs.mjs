#!/usr/bin/env node
/**
 * Does every Maryland stance's cited mgaleg MEMBER-PAGE URL actually resolve, and name the politician it
 * is filed under?
 *
 * 🔴 THIS FILE WAS REWRITTEN 2026-08-11 BECAUSE ITS FIRST VERSION FAKED EVIDENCE. Two bugs, both of which
 * produced verdicts about URLs nobody stores:
 *   1. CACHE KEY DID NOT RECORD WHICH URL WON. It tried the bare slug and then session-qualified variants,
 *      writing them all to `<slug>.html`. So `king01` was recorded as "James M. King" -- a name only
 *      reachable WITH a session -- while the stored bare URL is NotFound. That inflated "cites a different
 *      person" from 3 politicians to 10.
 *   2. SLUG REGEX `[A-Za-z0-9]+` TRUNCATED AT `%`. Slugs may contain SPACES (`jacobs j`, `miller a`,
 *      `davis d`); truncation turned Jay A. Jacobs into *Nancy* Jacobs.
 *
 * The fix is the rule: **judge a citation by fetching it in the EXACT FORM IT IS STORED, and make the
 * cache key the full URL.** No fallbacks, no variants -- a voter clicks what is stored.
 *
 * Verdicts: OK | WRONG_PERSON | DEAD
 * ⚠ Name comparison tolerates abbreviation/nickname ("Dan Cox" IS "Daniel L. Cox") -- a strict first-name
 *   equality test reported that real person as an impostor.
 * 🔴 Reads only. Writes a report.
 *
 *   node scripts/md-audit-cited-member-slugs.mjs --cache <dir> --out <report.json>
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const CACHE = flag('--cache'), OUT = flag('--out');
if (!CACHE) { console.error('need --cache'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const strip = (s) => s.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
const clean = (s) => strip(s).toLowerCase().replace(/[^a-z\- ]/g, ' ').replace(/\s+/g, ' ').trim();
const dropSuffix = (s) => s.replace(/,?\s+(jr|sr|ii|iii|iv)\b\.?/gi, '').trim();
const lastOf = (f) => dropSuffix(clean(f)).split(' ').pop();
const firstOf = (f) => dropSuffix(clean(f)).split(' ')[0];
const firstAgrees = (a, b) => a === b || (a.length >= 3 && b.length >= 3 && (a.startsWith(b) || b.startsWith(a)));

/** Fetch EXACTLY this URL. Cache key is the whole URL, so a verdict can never be about a different one. */
const nameCache = new Map();
async function nameAt(url) {
  if (nameCache.has(url)) return nameCache.get(url);
  const file = path.join(CACHE, Buffer.from(url).toString('base64url').slice(-120) + '.html');
  let html = null;
  if (fs.existsSync(file)) {
    const c = fs.readFileSync(file, 'utf8');
    if (c === '<DEAD>') { nameCache.set(url, null); return null; }
    if (c.length > 5_000) html = c;
  }
  if (!html) {
    const res = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    const body = await res.text();
    await sleep(1300);
    // mgaleg answers 200 on its own NotFound page -- judge by the landing URL, never the status code.
    if (/Error\/NotFound/i.test(res.url) || body.length < 10_000) {
      fs.writeFileSync(file, '<DEAD>'); nameCache.set(url, null); return null;
    }
    html = body; fs.writeFileSync(file, html);
  }
  const t = parse(html).querySelector('title')?.text ?? '';
  const nm = t.replace(/^\s*Members\s*-\s*/i, '').replace(/^(Senator|Delegate)\s+/i, '').trim();
  const val = nm && !/^NotFound$/i.test(nm) ? nm : null;
  nameCache.set(url, val);
  return val;
}

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

// Every (politician, stored member-page URL) pair -- the URL verbatim, query string and all.
const { rows } = await pool.query(`
  SELECT p.full_name, c.politician_id, s AS cited_url, count(*) AS rows_ct
  FROM inform.politician_context c
  JOIN essentials.politicians p ON p.id = c.politician_id
  CROSS JOIN LATERAL unnest(c.sources) AS s
  WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Members/Details/%'
  GROUP BY p.full_name, c.politician_id, s
  ORDER BY p.full_name`);
await pool.end();

console.log(`checking ${rows.length} (politician, cited URL) pairs…`);
const out = [];
let n = 0;
for (const r of rows) {
  const nm = await nameAt(r.cited_url);
  const verdict = nm === null ? 'DEAD'
    : (lastOf(nm) === lastOf(r.full_name) && firstAgrees(firstOf(nm), firstOf(r.full_name))) ? 'OK'
    : 'WRONG_PERSON';
  out.push({ politician: r.full_name, politician_id: r.politician_id, rows: Number(r.rows_ct), cited_url: r.cited_url, url_names: nm, verdict });
  if (++n % 40 === 0) console.log(`  …${n}/${rows.length}`);
}

const tally = out.reduce((m, x) => { m[x.verdict] = (m[x.verdict] || 0) + 1; return m; }, {});
const rowTally = out.reduce((m, x) => { m[x.verdict] = (m[x.verdict] || 0) + x.rows; return m; }, {});
console.log('\npairs by verdict :', JSON.stringify(tally));
console.log('stance rows by verdict:', JSON.stringify(rowTally));
const bad = out.filter((x) => x.verdict !== 'OK');
if (!bad.length) console.log('\n✅ CLEAN — every stored member-page citation resolves and names its own politician.');
else {
  console.log('\n=== NOT OK ===');
  for (const x of bad) console.log(`  [${x.verdict}] ${x.politician} (${x.rows} rows) -> ${x.cited_url}  names: ${x.url_names ?? 'DOES NOT RESOLVE'}`);
}
if (OUT) fs.writeFileSync(OUT, JSON.stringify({ audit: 'MD cited member-page URLs, judged as stored', tally, rowTally, rows: out }, null, 1));
