#!/usr/bin/env node
/**
 * Deep-link the BALLOTPEDIA_ONLY cohort to the section that actually carries the claim.
 *
 * WHY THIS IS NOT A RETIREMENT OR A RE-POINT. 231 of these 557 rows rest on the candidate's own
 * Ballotpedia Candidate Connection survey. Those answers are written by the candidate and published
 * nowhere else -- Ballotpedia is the PRIMARY source there, not a conduit, so "cite the primary behind
 * Ballotpedia" has no referent and the row cannot be re-pointed off-site. What it can be is precise:
 * ballotpedia.org/Name#Campaign_themes instead of ballotpedia.org/Name. Measured 2026-07-31, only 5 of
 * 557 URLs carried an anchor of any kind.
 *
 * 🔴 DO NOT APPEND THE ANCHOR BECAUSE THE REASONING SAYS "CANDIDATE CONNECTION". That is a claim about
 * how the row was written, not about the page. An anchor that does not resolve to the quoted passage
 * is WORSE than no anchor -- it reads as a dead citation. So every row is tested against the section
 * TEXT, and the anchor is only proposed when the claim is found inside it. Rows are not filtered by
 * reasoning wording at all: if the claim verifies in Campaign_themes it gets the anchor regardless of
 * how the researcher described it, and if it does not, it does not.
 *
 * 🔴 THE SECTION ID WAS VERIFIED AGAINST LIVE PAGES. It is #Campaign_themes. There is NO
 * #Candidate_Connection section id, despite that being the survey's name -- assuming it would produce
 * 200-with-no-anchor on every row.
 *
 * VERDICTS
 *   CC_VERIFIED         claim is inside the Campaign_themes section    -> propose #Campaign_themes  (apply)
 *   ELSEWHERE_ON_PAGE   claim is on the page but NOT in that section   -> anchoring there would lie
 *   NO_CC_SECTION       page has no Campaign_themes section at all
 *   NOT_ON_PAGE         claim is nowhere in the article body           -> the citation audit's problem
 *   UNKNOWN             non-200, thin body, or rate-limited            -> NEVER a miss, re-run
 *
 * 🔴 BALLOTPEDIA RATE-LIMITS SILENTLY: parallel fetches return HTTP 202 with an empty body and r.ok is
 * TRUE for 202. Fetch serially at ~1.3s and treat status<>200 or a short body as UNKNOWN, never as
 * absence. This already produced one wrong sweep on this project.
 *
 * Usage (from backend/):
 *   node scripts/deep-link-candidate-connection.mjs --limit 15
 *   node scripts/deep-link-candidate-connection.mjs --out data/stance-retirement/2026-07-31-cc-deeplinks.json
 */
import 'dotenv/config';
import { writeFileSync, readFileSync, statSync, mkdirSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { Pool } from 'pg';
import { parse } from 'node-html-parser';
import { extractQuotes, quotePresent, looseIncludes, candidateTerms, identityTerms } from './lib/claim-match.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const LIMIT = parseInt(flag('--limit', '0'), 10);
const OUT = flag('--out');
const DELAY = parseInt(flag('--delay', '1300'), 10);
const MIN_BODY = parseInt(flag('--min-body', '3000'), 10);
const NO_CACHE = argv.includes('--no-cache');

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Mirrors check-stance-sources.mjs BALLOTPEDIA_ONLY, including the survey carve-out. */
const QUERY = `
  SELECT pa.politician_id::text AS pid, pa.topic_id::text AS tid, pa.value,
         pc.reasoning, pc.sources,
         p.first_name, p.last_name,
         coalesce(t.short_title, t.title, pa.topic_id::text) AS topic,
         lower(coalesce(seat.state, seat.representing_state, cand.state, '')) AS st,
         coalesce(seat.title, '') AS office_title,
         coalesce(seat.label, '') AS district_label,
         coalesce(seat.city, '')  AS office_city
  FROM inform.politician_answers pa
  JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = pa.topic_id
  LEFT JOIN LATERAL (
    SELECT o.representing_state, o.title, d.state, d.label, d.city
    FROM essentials.office_current_holder och
    JOIN essentials.offices o        ON o.id = och.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    WHERE och.politician_id = pa.politician_id ORDER BY o.title LIMIT 1
  ) seat ON true
  LEFT JOIN LATERAL (
    SELECT lower(e.state::text) AS state
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE rc.politician_id = pa.politician_id AND rc.candidate_status = 'active'
    ORDER BY e.election_date DESC LIMIT 1
  ) cand ON true
  WHERE pa.value <> 0
    AND cardinality(pc.sources) > 0
    -- The gate classifies bare-domain and proxy rows BEFORE it gets to BALLOTPEDIA_ONLY, so they are
    -- not in this cohort. Without these two exclusions the query returns 555 against the gate's 552
    -- and this tool would try to hang a #Campaign_themes anchor off an r.jina.ai wrapper.
    AND EXISTS (
      SELECT 1 FROM unnest(pc.sources) s WHERE btrim(s, '/') !~* '^https?://(www\\.)?[a-z0-9.-]+$')
    AND NOT EXISTS (
      SELECT 1 FROM unnest(pc.sources) s
       WHERE s ILIKE '%r.jina.ai%' OR s ILIKE '%webcache.googleusercontent%'
          OR s ILIKE '%translate.goog%' OR s ILIKE '%12ft.io%')
    AND NOT EXISTS (
      SELECT 1 FROM unnest(pc.sources) s
       WHERE s NOT ILIKE '%ballotpedia%'
          OR s ~* 'ballotpedia\\.org/[^#]+#Campaign_themes'
          OR s ILIKE '%Candidate_Connection%')
  ORDER BY pa.politician_id, pa.topic_id`;

// ---------------------------------------------------------------------------- fetching

const CACHE_DIR = path.join(os.tmpdir(), 'ballotpedia-section-cache');
const CACHE_TTL_MS = parseInt(flag('--cache-ttl-hours', '24'), 10) * 3600 * 1000;
const cachePath = (u) => path.join(CACHE_DIR, `${Buffer.from(u).toString('base64url').slice(0, 180)}.json`);

function cacheGet(u) {
  if (NO_CACHE) return null;
  try {
    if (Date.now() - statSync(cachePath(u)).mtimeMs > CACHE_TTL_MS) return null;
    return JSON.parse(readFileSync(cachePath(u), 'utf8'));
  } catch { return null; }
}
function cachePut(u, page) {
  if (NO_CACHE) return;
  try {
    mkdirSync(CACHE_DIR, { recursive: true });
    // Caching a 202 or a thin body would freeze the silent rate limit in place forever.
    if (page.status === 200 && page.body.length >= MIN_BODY) writeFileSync(cachePath(u), JSON.stringify(page));
  } catch { /* best effort */ }
}

const HEADING = /^h[1-6]$/i;

/**
 * The text of the section introduced by the element carrying `id`, up to the next heading of the same
 * or higher rank. MediaWiki nests the id on a <span> inside the heading in one skin and on the heading
 * itself in another, so ascend to the heading before walking siblings rather than assuming either.
 */
function sectionText(root, id) {
  const marker = root.querySelector(`#${id}`);
  if (!marker) return null;
  let heading = marker;
  while (heading && !HEADING.test(heading.tagName ?? '')) heading = heading.parentNode;
  if (!heading) heading = marker;
  const rank = HEADING.test(heading.tagName ?? '') ? parseInt(heading.tagName[1], 10) : 2;
  const sibs = heading.parentNode?.childNodes ?? [];
  const start = sibs.indexOf(heading);
  if (start < 0) return null;
  const out = [];
  for (let i = start + 1; i < sibs.length; i++) {
    const n = sibs[i];
    const tag = n.tagName ?? '';
    if (HEADING.test(tag) && parseInt(tag[1], 10) <= rank) break;
    out.push(n.textContent ?? '');
  }
  return out.join(' ').replace(/\s+/g, ' ').trim();
}

async function fetchPage(url) {
  const hit = cacheGet(url);
  if (hit) return { ...hit, cached: true };
  let res;
  try {
    res = await fetch(url, { headers: { 'User-Agent': UA, Accept: 'text/html' }, redirect: 'follow', signal: AbortSignal.timeout(45000) });
  } catch (e) { return { status: 0, error: e.message, body: '', section: null, finalUrl: url }; }
  if (res.status !== 200) return { status: res.status, body: '', section: null, finalUrl: res.url || url };
  let html;
  try { html = await res.text(); }
  catch (e) { return { status: 0, error: `body read failed: ${e.message}`, body: '', section: null, finalUrl: res.url || url }; }
  const root = parse(html);
  const content = root.querySelector('#mw-content-text');
  if (!content) return { status: 200, body: '', section: null, finalUrl: res.url || url, noContentDiv: true };
  content.querySelectorAll('script,style').forEach((n) => n.remove());
  const page = {
    status: 200,
    body: content.textContent.replace(/\s+/g, ' ').trim(),
    section: sectionText(content, 'Campaign_themes'),
    finalUrl: res.url || url,
  };
  cachePut(url, page);
  return page;
}

// ---------------------------------------------------------------------------- run

(async () => {
  if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }
  const { rows } = await pool.query(QUERY);
  await pool.end();

  const byUrl = new Map();
  for (const r of rows) {
    const url = r.sources.find((s) => /ballotpedia\.org\//i.test(s))?.trim().replace(/#.*$/, '').replace(/\/$/, '');
    if (!url) continue;
    if (!byUrl.has(url)) byUrl.set(url, []);
    byUrl.get(url).push(r);
  }
  let list = [...byUrl.entries()];
  if (LIMIT) list = list.slice(0, LIMIT);
  console.log(`${rows.length} rows across ${byUrl.size} Ballotpedia pages; reading ${list.length} serially at ${DELAY}ms`);

  const results = [];
  let n = 0;
  for (const [url, pageRows] of list) {
    const page = await fetchPage(url);
    if (!page.cached) await sleep(DELAY);
    n += 1;
    if (n % 25 === 0) console.log(`  ${n}/${list.length} pages`);

    const unknown = page.status !== 200 || page.body.length < MIN_BODY;
    for (const r of pageRows) {
      const base = {
        pid: r.pid, tid: r.tid, name: `${r.first_name} ${r.last_name}`, st: r.st, topic: r.topic,
        cited: url, section_chars: page.section?.length ?? 0, body_chars: page.body.length,
        reasoning: r.reasoning,
      };
      if (unknown) { results.push({ ...base, verdict: 'UNKNOWN', why: `status ${page.status}, ${page.body.length}c` }); continue; }

      const ident = identityTerms(r);
      const quotes = extractQuotes(r.reasoning);
      const terms = candidateTerms(r.reasoning).filter((t) => !ident.has(t.toLowerCase()));
      const hit = (text) => {
        if (!text) return false;
        const qf = quotes.filter((q) => quotePresent(text, q) === true);
        if (quotes.length) return qf.length > 0;
        const tf = terms.filter((t) => looseIncludes(text, t));
        return tf.length >= Math.min(2, terms.length) && tf.length > 0;
      };

      if (!page.section) { results.push({ ...base, verdict: 'NO_CC_SECTION' }); continue; }
      if (hit(page.section)) {
        results.push({ ...base, verdict: 'CC_VERIFIED', url: `${url}#Campaign_themes`,
          evidence: (quotes.find((q) => quotePresent(page.section, q) === true)
            ?? terms.find((t) => looseIncludes(page.section, t)) ?? '').slice(0, 160) });
      } else if (hit(page.body)) {
        results.push({ ...base, verdict: 'ELSEWHERE_ON_PAGE' });
      } else {
        results.push({ ...base, verdict: 'NOT_ON_PAGE' });
      }
    }
  }

  const tally = {};
  for (const r of results) tally[r.verdict] = (tally[r.verdict] ?? 0) + 1;
  console.log('\nverdicts');
  for (const [k, v] of Object.entries(tally).sort((a, b) => b[1] - a[1])) console.log(`  ${k.padEnd(20)} ${String(v).padStart(4)}`);
  console.log(`\napplyable (claim verified INSIDE the Campaign_themes section): ${tally.CC_VERIFIED ?? 0}`);
  console.log('ELSEWHERE_ON_PAGE must NOT be anchored there -- the anchor would point away from the claim.');
  console.log('NOT_ON_PAGE is the citation audit\'s problem, not this tool\'s. UNKNOWN needs a re-run.');

  if (OUT) {
    writeFileSync(OUT, `${JSON.stringify({
      _comment: 'Candidate Connection deep-link proposal. Only CC_VERIFIED is applyable: the claim was '
        + 'found INSIDE the #Campaign_themes section text, not merely somewhere on the page and not '
        + 'inferred from the reasoning mentioning a survey. UNKNOWN is a fetch failure or a rate limit, '
        + 'never evidence of absence.',
      generated: { rows: results.length, pages: list.length, tally },
      rows: results,
    }, null, 2)}\n`);
    console.log(`\nwritten to ${OUT}`);
  }
})().catch(async (e) => { console.error('FAIL:', e); try { await pool.end(); } catch {} process.exit(2); });
