#!/usr/bin/env node
/**
 * Build the input + HTML cache that `the-197-claim-on-page.mjs --in` consumes, for ANY worklist
 * carrying TOPIC_ABSENT cells.
 *
 * WHY IT IS SEPARATE FROM THE GUARD: the guard is pure (it greps cached HTML and decides nothing
 * about the network). Fetching is the part with rate limits, partial failures and a cache, so it
 * lives here. That split is what lets the guard be re-run freely once the cache exists.
 *
 * 🔴 TOPIC_ABSENT IS A SORT, NOT A VERDICT, AND THE MARGIN IS NOT SMALL. Run over the 92
 * defect-shaped federal keys on 2026-10-06, the guard returned 79 PAGE_NOT_SILENT / 28 WEAK_ONLY /
 * 3 PAGE_SILENT — a ~97% over-fire on the first cut, in line with every other first cut in this
 * workstream. Retiring on the coverage cut alone would have been wrong 79 times out of 110.
 *
 * ⚠ ZERO-BYTE BODY = RATE LIMIT, NOT ABSENCE. Ballotpedia answers HTTP 202 with an empty body after
 * ~50 rapid requests, which scores as "dead" and once produced a bogus 50-dead result. This aborts
 * the whole run on the first one rather than recording a blocking artefact as data; the cache
 * persists, so a re-run resumes.
 *
 * ⚠ Cache file naming must match the guard's `fileFor()` exactly or every row reports NO_CACHE.
 *
 * ⚠ TOPIC LABELS COME FROM `topic_key`, NEVER `compass_topics.title`. That column is the FROZEN v1
 * wording and 29 of 60 topics disagree with their season pin, so a worklist labelled from it can
 * name a question nobody was asked. CI's `frozen ladder text` guard caught exactly that in the
 * first draft of this script. These tools are season-agnostic triage, so the stable key is the
 * right label; anything needing the real wording must read the season's pinned revision.
 *
 * 🔴 Reads only. Writes an input file and a cache, never the DB.
 *   node scripts/claim-on-page-input.mjs --work <worklist.json> --cache <dir> --out <input.json>
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const WORK = flag('--work'), CACHE = flag('--cache'), OUT = flag('--out');
if (!WORK || !CACHE || !OUT) { console.error('need --work --cache --out'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const fileFor = (u) => path.join(CACHE, encodeURIComponent(u).replace(/[^A-Za-z0-9%._-]/g, '_').slice(-180) + '.html');

const work = JSON.parse(fs.readFileSync(WORK, 'utf8')).work;
const defect = work.filter((w) => /TOPIC_ABSENT/.test(w.cell));
console.log(`defect-shaped keys in worklist: ${defect.length}`);

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

// ⚠ A key spans seasons. Pull EVERY context row for it — the guard judges rows, and an S1 and an S2
// row for one key can carry different prose.
const { rows } = await pool.query(`
  SELECT c.politician_id, c.topic_id, p.full_name, t.topic_key, t.topic_key AS topic,
         a.value AS answer_value, c.reasoning, c.sources, s.number AS season
  FROM inform.politician_context c
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
  LEFT JOIN inform.politician_answers a
         ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id AND a.season_id = c.season_id
  LEFT JOIN inform.seasons s ON s.id = c.season_id
  WHERE (c.politician_id::text || '|' || c.topic_id::text) = ANY($1::text[])`,
  [defect.map((d) => `${d.politician_id}|${d.topic_id}`)]);
await pool.end();
console.log(`context rows for those keys (all seasons): ${rows.length}`);

// Only an article ABOUT the person is the one to test. An article about a bill or an election is
// Tier C and a surname test is what separates them (same rule as tier-b-positions-section.mjs).
const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim().split(/\s+/).pop().toLowerCase();
const out = [];
for (const r of rows) {
  const art = (r.sources || []).find((u) => {
    const slug = (u.match(/(?:\/wiki|ballotpedia\.org)\/([^?#]+)$/) || [])[1] || '';
    return slug && slug.toLowerCase().replace(/_/g, ' ').includes(surnameOf(r.full_name));
  });
  if (art) out.push({ ...r, article: art });
}
console.log(`rows with an article about the person: ${out.length}`);

const urls = [...new Set(out.map((r) => r.article))];
console.log(`distinct articles to cache: ${urls.length}\n`);

let fetched = 0, cached = 0;
for (const u of urls) {
  const f = fileFor(u);
  if (fs.existsSync(f) && fs.statSync(f).size > 2000) { cached++; continue; }
  let body;
  try {
    const res = await fetch(u, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    body = await res.text();
  } catch (e) { console.error(`FETCH FAIL ${u}: ${e.message}`); continue; }
  if (body.length === 0) {
    console.error(`\n🔴 ZERO-BYTE BODY at ${u} after ${fetched} fetches — rate limited. Aborting so`);
    console.error('   the run cannot record a block as absence. The cache persists; re-run later.');
    process.exitCode = 3;
    break;
  }
  fs.writeFileSync(f, body);
  fetched++;
  if (fetched % 20 === 0) console.log(`  fetched ${fetched}/${urls.length}`);
  await sleep(/ballotpedia\.org/i.test(u) ? 2200 : 1200);
}
console.log(`\nfetched ${fetched}, already cached ${cached}`);

fs.writeFileSync(OUT, JSON.stringify({
  pass: `claim-on-page input built from ${path.basename(WORK)}`,
  n: out.length, rows: out,
}, null, 2));
console.log(`input -> ${OUT}`);
