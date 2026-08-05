#!/usr/bin/env node
/**
 * Find cited ARTICLES that were never published, on hosts that are perfectly real.
 *
 * WHY THIS EXISTS, AND WHY IT IS NOT PART OF THE CI GATE. On 2026-08-05 migration 1562 retired 17
 * Lowell stance rows citing 15 lowellsun.com articles. The Lowell Sun is a real paper, the host serves
 * HTTP 200, and it is exactly who it claims to be — but none of the 15 articles ever existed. Six
 * migrations' worth of this defect (1539, 1540, 1548, 1558, 1562) passed check-stance-sources.mjs green
 * while live, because no URL SHAPE distinguishes a fabricated article from a real one. Deciding it
 * needs a fetch and an archive probe, so it cannot run on every push: archive.org rate-limits hard and
 * returns 504s on the filter= query form. This runs on demand, in chunks; the gate only re-detects what
 * this confirms.
 *
 * THE TEST — three steps, and step 3 is the one that makes it trustworthy:
 *   1. FETCH the cited path. Anything other than 404/410 is not this defect. A 403 is a bot wall, a
 *      200 is fine, a timeout is a timeout. Only "the server says this page is not here" continues.
 *   2. CDX the exact URL. Any capture at all → the article existed. Done, not fabricated.
 *   3. 🔴 CDX A PERIOD CONTROL: sibling paths under the same host and the same YYYY/MM. If the archive
 *      holds many siblings and zero of this path, the article was never published. If the archive holds
 *      NO siblings either, the archive simply does not cover that host/period and the probe is
 *      INCONCLUSIVE — never "fabricated". Without step 3 every citation to a thinly-archived local
 *      paper would read as fabricated, which is exactly the over-fire this audit has hit sixteen times.
 *
 * WHAT IT DELIBERATELY WILL NOT DO:
 *   - It never writes to the database and never edits fabricated-sources.json. It writes a findings
 *     artifact for a human to read. Adding a denylist entry is a decision, not a script's output.
 *   - It skips non-article URLs (no /YYYY/MM/ or /YYYY/MM/DD/ in the path). A landing page returning
 *     404 is a different defect with a different remedy (see the nav-page sweep, 2026-08-04).
 *   - It does not treat a dead HOST as this class. That is the invented-host sweep's job and DNS finds
 *     it cheaply; here the host must answer.
 *
 * Usage (from backend/):
 *   node scripts/sweep-fabricated-articles.mjs --limit 40
 *   node scripts/sweep-fabricated-articles.mjs --host lowellsun.com
 *   node scripts/sweep-fabricated-articles.mjs --state ma --limit 100 --pace 1500
 *   node scripts/sweep-fabricated-articles.mjs --from 100 --to 200      # chunked resume
 *   node scripts/sweep-fabricated-articles.mjs --url <one-url>          # probe one URL, no DB
 *
 * `--url` exists so the detector can be demonstrated against a KNOWN POSITIVE. Every fabricated
 * citation found so far has already been retired, so a DB-driven run can only ever show negatives —
 * and a detector nobody has watched fire is not a verified detector. Regression test:
 *   node scripts/sweep-fabricated-articles.mjs --url https://lowellsun.com/2023/07/08/lowell-homelessness-response/
 * must print FABRICATED (that URL was retired by migration 1562), and
 *   node scripts/sweep-fabricated-articles.mjs --url https://www.lowellsun.com/2023/08/01/arrest-log-257/
 * must NOT (a real story from the same paper and month).
 *
 * Needs DATABASE_URL, except in --url mode. Read-only against prod.
 */
import 'dotenv/config';
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUTDIR = path.join(HERE, '..', 'data', 'stance-retirement');

const argv = process.argv.slice(2);
const arg = (name, dflt) => {
  const i = argv.indexOf(`--${name}`);
  return i !== -1 && argv[i + 1] ? argv[i + 1] : dflt;
};
const LIMIT = Number(arg('limit', '50'));
const FROM = Number(arg('from', '0'));
const TO = arg('to') ? Number(arg('to')) : null;
const HOST = arg('host', null);
const STATE = arg('state', null);
const PACE = Number(arg('pace', '1200'));   // ms between archive.org calls
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Article-shaped: /YYYY/MM/ or /YYYY/MM/DD/ somewhere in the path. */
const ARTICLE_RE = /\/(19|20)\d{2}\/\d{1,2}\/(\d{1,2}\/)?/;

function hostOf(u) {
  try { return new URL(u).host.replace(/^www\./, '').toLowerCase(); } catch { return null; }
}
/** The YYYY/MM prefix of an article URL, used to build the period control. */
function periodOf(u) {
  const m = u.match(/\/((?:19|20)\d{2})\/(\d{1,2})\//);
  return m ? { year: m[1], month: m[2].padStart(2, '0') } : null;
}

async function fetchStatus(url) {
  try {
    const res = await fetch(url, { method: 'GET', redirect: 'follow', headers: { 'User-Agent': UA },
                                   signal: AbortSignal.timeout(30_000) });
    return res.status;
  } catch { return 0; }   // 0 = no answer: DNS, TLS, timeout. NOT this defect.
}

/**
 * CDX capture count. Returns null on a rate-limit / error so callers can tell "no captures" (0) from
 * "the archive did not answer" (null) — conflating those is how a throttled run becomes a false finding.
 */
async function cdxCount(pattern, extra = '') {
  // 🔴 RETRY WITH BACKOFF, ALWAYS. archive.org throttles hard under sustained use, and a single
  // unanswered probe degrades a real FABRICATED verdict to INCONCLUSIVE — a silent false negative that
  // still reads as a clean run. Observed live while testing this script: the same control query returned
  // nothing to attempt 1 and 200 rows to a curl seconds later. Three tries with growing waits turns most
  // of those back into answers. (Same lesson as classify-dead-cited-hosts.mjs.)
  for (let attempt = 0; attempt < 3; attempt += 1) {
    if (attempt > 0) await sleep(PACE * (attempt * 3));
    const n = await cdxOnce(pattern, extra);
    if (n !== null) return n;
  }
  return null;
}

async function cdxOnce(pattern, extra = '') {
  const u = `http://web.archive.org/cdx/search/cdx?url=${encodeURIComponent(pattern)}&output=text&fl=timestamp&limit=200${extra}`;
  try {
    const res = await fetch(u, { headers: { 'User-Agent': UA }, signal: AbortSignal.timeout(60_000) });
    if (!res.ok) return null;
    const body = await res.text();
    // 🔴 DO NOT test the body for the substring "504". The first version did, and CDX returns 14-digit
    // timestamps with fl=timestamp — "20230705043012" contains "504", so a perfectly good control was
    // read as a rate-limit and every FABRICATED verdict silently degraded to INCONCLUSIVE. A detector
    // that fails toward "found nothing" is worse than no detector, because the run still looks clean.
    // Rate limits and gateway errors are HTML; real CDX output is not. Test for markup only.
    if (/<html|<head|Gateway Time-?out|Too Many Requests/i.test(body)) return null;
    return body.split('\n').filter((l) => l.trim()).length;
  } catch { return null; }
}

const VERDICTS = {
  FABRICATED:   'path 404s, never archived, and siblings from the same month ARE archived',
  EXISTS:       'the archive holds a capture of this exact path',
  LIVE:         'the path answers with something other than 404/410',
  INCONCLUSIVE: 'no sibling coverage for that host+month, so absence proves nothing',
  NO_ANSWER:    'host did not answer at all — invented-host sweep territory, not this one',
};

/** The three-step test for one URL, shared by --url mode and the DB sweep. */
async function classify(url) {
  const host = hostOf(url);
  const period = periodOf(url);

  const status = await fetchStatus(url);
  if (status !== 404 && status !== 410) {
    return { host, status, verdict: status === 0 ? 'NO_ANSWER' : 'LIVE' };
  }

  await sleep(PACE);
  const exact = await cdxCount(url);
  if (exact === null) return { host, status, verdict: 'INCONCLUSIVE', why: 'CDX did not answer for the exact path' };
  if (exact > 0)      return { host, status, verdict: 'EXISTS', captures: exact };

  await sleep(PACE);
  const key = period ? `${host}|${period.year}/${period.month}` : `${host}|-`;
  const siblings = period
    ? await cdxCount(`${host}/${period.year}/${period.month}*`, '&collapse=urlkey')
    : null;

  if (siblings === null) return { host, status, verdict: 'INCONCLUSIVE', why: 'control did not answer', control: key };
  if (siblings === 0)    return { host, status, verdict: 'INCONCLUSIVE', why: `archive holds no ${key} siblings either`, control: key };
  return { host, status, verdict: 'FABRICATED', control_siblings: siblings, control: key };
}

(async () => {
  const ONE = arg('url', null);
  if (ONE) {
    const r = await classify(ONE);
    console.log(`\n  ${r.verdict}  (HTTP ${r.status})  ${ONE}`);
    if (r.captures)         console.log(`  captures of this exact path: ${r.captures}`);
    if (r.control_siblings) console.log(`  control: ${r.control_siblings} sibling captures in ${r.control}`);
    if (r.why)              console.log(`  ${r.why}`);
    console.log(`  → ${VERDICTS[r.verdict]}\n`);
    process.exit(r.verdict === 'FABRICATED' ? 1 : 0);
  }

  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set.');
    process.exit(0);
  }

  const params = [];
  let where = `WHERE s ~ '/(19|20)[0-9]{2}/[0-9]{1,2}/'`;
  if (HOST)  { params.push(`%${HOST}%`); where += ` AND s ILIKE $${params.length}`; }
  if (STATE) {
    params.push(STATE.toLowerCase());
    where += ` AND lower(coalesce(seat.state, seat.representing_state, '')) = $${params.length}`;
  }

  // One row per DISTINCT cited URL — the unit of this defect is the citation, not the stance row.
  const { rows: cites } = await pool.query(`
    WITH c AS (
      SELECT DISTINCT s AS url, count(*) OVER (PARTITION BY s) AS rows_citing
        FROM inform.politician_context pc, unnest(pc.sources) s
        LEFT JOIN LATERAL (
          SELECT o.representing_state, d.state
            FROM essentials.office_current_holder och
            JOIN essentials.offices o ON o.id = och.office_id
            LEFT JOIN essentials.districts d ON d.id = o.district_id
           WHERE och.politician_id = pc.politician_id
           ORDER BY o.title LIMIT 1
        ) seat ON true
      ${where}
    )
    SELECT url, rows_citing FROM c ORDER BY rows_citing DESC, url`, params);

  const slice = cites.slice(FROM, TO ?? FROM + LIMIT);
  console.log(`${cites.length} article-shaped cited URLs match; probing ${slice.length} (from ${FROM})\n`);

  const findings = [];
  const controlCache = new Map();   // host|YYYY/MM -> sibling count, so one control serves many URLs

  for (const [i, c] of slice.entries()) {
    const host = hostOf(c.url);
    const period = periodOf(c.url);
    const label = `[${FROM + i + 1}/${cites.length}]`;

    const status = await fetchStatus(c.url);
    if (status !== 404 && status !== 410) {
      findings.push({ ...c, host, status, verdict: status === 0 ? 'NO_ANSWER' : 'LIVE' });
      console.log(`${label} ${status === 0 ? 'NO_ANSWER' : 'LIVE      '} ${status}  ${c.url}`);
      continue;
    }

    await sleep(PACE);
    const exact = await cdxCount(c.url);
    if (exact === null) {
      findings.push({ ...c, host, status, verdict: 'INCONCLUSIVE', why: 'CDX did not answer for the exact path' });
      console.log(`${label} INCONCLUSIVE (cdx throttled)  ${c.url}`);
      continue;
    }
    if (exact > 0) {
      findings.push({ ...c, host, status, verdict: 'EXISTS', captures: exact });
      console.log(`${label} EXISTS     404 now but ${exact} captures  ${c.url}`);
      continue;
    }

    // Step 3 — the period control. Without this, a thinly-archived paper reads as fabricated.
    const key = period ? `${host}|${period.year}/${period.month}` : `${host}|-`;
    let siblings = controlCache.get(key);
    if (siblings === undefined) {
      await sleep(PACE);
      siblings = period
        ? await cdxCount(`${host}/${period.year}/${period.month}*`, '&collapse=urlkey')
        : null;
      controlCache.set(key, siblings);
    }

    if (siblings === null) {
      findings.push({ ...c, host, status, verdict: 'INCONCLUSIVE', why: 'control did not answer' });
      console.log(`${label} INCONCLUSIVE (control throttled)  ${c.url}`);
    } else if (siblings === 0) {
      findings.push({ ...c, host, status, verdict: 'INCONCLUSIVE', why: `archive holds no ${key} siblings either` });
      console.log(`${label} INCONCLUSIVE (no sibling coverage)  ${c.url}`);
    } else {
      findings.push({ ...c, host, status, verdict: 'FABRICATED', control_siblings: siblings, control: key });
      console.log(`${label} 🔴 FABRICATED  404 + 0 captures, ${siblings} siblings in ${key}  ${c.url}`);
    }
  }

  const tally = {};
  for (const f of findings) tally[f.verdict] = (tally[f.verdict] ?? 0) + 1;

  const stampless = { generated_by: 'scripts/sweep-fabricated-articles.mjs', args: argv.join(' ') };
  const out = path.join(OUTDIR, `fabricated-article-sweep-${FROM}-${FROM + slice.length}.json`);
  mkdirSync(OUTDIR, { recursive: true });
  writeFileSync(out, `${JSON.stringify({ ...stampless, verdict_meanings: VERDICTS, tally, findings }, null, 2)}\n`);

  console.log('\n--- tally ---');
  for (const [k, n] of Object.entries(tally).sort((a, b) => b[1] - a[1])) console.log(`  ${k.padEnd(13)} ${n}`);
  const fab = findings.filter((f) => f.verdict === 'FABRICATED');
  if (fab.length) {
    console.log(`\n🔴 ${fab.length} FABRICATED, covering ${fab.reduce((a, f) => a + Number(f.rows_citing), 0)} row-citations:`);
    for (const f of fab) console.log(`   ${f.url}  (${f.rows_citing} rows)`);
    console.log('\nNEXT: verify a sample by hand, then add confirmed URLs to data/fabricated-sources.json');
    console.log('and retire or re-research the rows in a migration. Do NOT auto-add — that is a decision.');
  }
  console.log(`\nwrote ${path.relative(process.cwd(), out)}`);
  await pool.end();
})().catch(async (err) => {
  console.error('FAIL:', err.message);
  try { await pool.end(); } catch { /* already closed */ }
  process.exit(2);
});
