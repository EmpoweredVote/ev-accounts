#!/usr/bin/env node
/**
 * READ-ONLY audit of every stance row that cites a Ballotpedia #Campaign_themes anchor.
 *
 * WHY. Migration 1514 (2026-07-31) anchored 443 rows after deep-link-candidate-connection.mjs said the
 * claim was "inside the survey section". On 2026-10-07 Season 2 coder snapshots showed that 10 of 13 such
 * pages say "has not yet completed Ballotpedia's ... Candidate Connection survey" under that heading, next to
 * an editorial summary of the campaign site that the term matcher had matched. This re-checks every anchored
 * row against the live page with the corrected rule (lib/candidate-connection.mjs NO_SURVEY_NOTICE).
 *
 * VERDICTS (per row)
 *   NO_SURVEY      section carries the not-completed notice            -> anchor does not point at own words
 *   NO_SECTION     page has no Campaign_themes section at all
 *   SURVEY_CLAIM   survey text present AND the row's claim is in it    -> anchor stands
 *   SURVEY_NOCLAIM survey text present but the claim is not in it      -> anchor stands for the page, not the claim
 *   UNKNOWN        non-200 / thin body / rate limit                    -> re-run, never a miss
 *
 * Writes nothing to the database. Fetches serially (Ballotpedia answers HTTP 202 + empty body when rushed).
 *   node scripts/audit-cc-anchors.mjs --out <file.json> [--delay 2500] [--limit N]
 */
import 'dotenv/config';
import { writeFileSync, readFileSync, statSync, mkdirSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { Pool } from 'pg';
import { parse } from 'node-html-parser';
import { sectionText, NO_SURVEY_NOTICE, CC_ANCHOR_PATTERN, withoutFragment } from './lib/candidate-connection.mjs';
import { extractQuotes, quotePresent, looseIncludes, candidateTerms, identityTerms } from './lib/claim-match.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out'); const DELAY = parseInt(flag('--delay', '2500'), 10); const LIMIT = parseInt(flag('--limit', '0'), 10);
const MIN_BODY = 3000;
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const CACHE = path.join(os.tmpdir(), 'ballotpedia-cc-audit-cache');
const cpath = (u) => path.join(CACHE, `${Buffer.from(u).toString('base64url').slice(0, 180)}.json`);

async function fetchPage(url) {
  try { const c = JSON.parse(readFileSync(cpath(url), 'utf8')); if (Date.now() - statSync(cpath(url)).mtimeMs < 864e5) return { ...c, cached: true }; } catch {}
  let res;
  try { res = await fetch(url, { headers: { 'User-Agent': UA, Accept: 'text/html' }, redirect: 'follow', signal: AbortSignal.timeout(45000) }); }
  catch (e) { return { status: 0, body: '', section: null }; }
  if (res.status !== 200) return { status: res.status, body: '', section: null };
  const root = parse(await res.text()); const c = root.querySelector('#mw-content-text');
  if (!c) return { status: 200, body: '', section: null };
  c.querySelectorAll('script,style').forEach((n) => n.remove());
  const page = { status: 200, body: c.textContent.replace(/\s+/g, ' ').trim(), section: sectionText(c) };
  if (page.body.length >= MIN_BODY) { mkdirSync(CACHE, { recursive: true }); writeFileSync(cpath(url), JSON.stringify(page)); }
  return page;
}

(async () => {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  await pool.query('BEGIN READ ONLY');
  const { rows } = await pool.query(`
    SELECT pc.politician_id::text AS pid, pc.topic_id::text AS tid, pc.season_id::text AS sid, s.number AS season,
           pc.reasoning, pc.sources, p.first_name, p.last_name
      FROM inform.politician_context pc
      JOIN inform.seasons s ON s.id = pc.season_id
      JOIN essentials.politicians p ON p.id = pc.politician_id
     WHERE EXISTS (SELECT 1 FROM unnest(pc.sources) u WHERE u ~* '${CC_ANCHOR_PATTERN}')`);
  await pool.end();
  const byUrl = new Map();
  for (const r of rows) {
    const u = withoutFragment(r.sources.find((x) => new RegExp(CC_ANCHOR_PATTERN, 'i').test(x))).replace(/\/$/, '');
    if (!byUrl.has(u)) byUrl.set(u, []); byUrl.get(u).push(r);
  }
  let list = [...byUrl.entries()]; if (LIMIT) list = list.slice(0, LIMIT);
  console.log(`${rows.length} anchored rows on ${byUrl.size} pages; reading ${list.length} serially at ${DELAY}ms`);
  const results = []; let n = 0;
  for (const [url, prs] of list) {
    const page = await fetchPage(url); if (!page.cached) await sleep(DELAY);
    if (++n % 25 === 0) console.log(`  ${n}/${list.length}`);
    for (const r of prs) {
      const base = { pid: r.pid, tid: r.tid, season: r.season, name: `${r.first_name} ${r.last_name}`, url, only_ballotpedia: r.sources.every((s) => /ballotpedia/i.test(s)) };
      if (page.status !== 200 || page.body.length < MIN_BODY) { results.push({ ...base, verdict: 'UNKNOWN', why: `status ${page.status}, ${page.body.length}c` }); continue; }
      if (!page.section) { results.push({ ...base, verdict: 'NO_SECTION' }); continue; }
      if (NO_SURVEY_NOTICE.test(page.section)) { results.push({ ...base, verdict: 'NO_SURVEY' }); continue; }
      const ident = identityTerms(r); const quotes = extractQuotes(r.reasoning);
      const terms = candidateTerms(r.reasoning).filter((t) => !ident.has(t.toLowerCase()));
      const hit = quotes.length ? quotes.some((q) => quotePresent(page.section, q) === true)
        : terms.filter((t) => looseIncludes(page.section, t)).length >= Math.min(2, terms.length) && terms.length > 0;
      results.push({ ...base, verdict: hit ? 'SURVEY_CLAIM' : 'SURVEY_NOCLAIM' });
    }
  }
  const tally = {}; for (const r of results) tally[r.verdict] = (tally[r.verdict] ?? 0) + 1;
  console.log('\nverdicts (rows)'); for (const [k, v] of Object.entries(tally).sort((a, b) => b[1] - a[1])) console.log(`  ${k.padEnd(16)} ${v}`);
  const bad = results.filter((r) => r.verdict === 'NO_SURVEY' || r.verdict === 'NO_SECTION');
  console.log(`\nanchors that do not point at survey text: ${bad.length}; of those, Ballotpedia is the ONLY source: ${bad.filter((r) => r.only_ballotpedia).length}`);
  if (OUT) writeFileSync(OUT, `${JSON.stringify({ generated: { rows: results.length, pages: list.length, tally }, rows: results }, null, 2)}\n`);
})().catch((e) => { console.error('FAIL:', e); process.exit(2); });
