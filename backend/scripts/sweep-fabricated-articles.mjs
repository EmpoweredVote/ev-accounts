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

/**
 * Dated article shape. Still special-cased because a YYYY/MM control is the tightest one available.
 *
 * 🔴 THIS USED TO BE THE ELIGIBILITY FILTER AND THAT WAS A REAL GAP. Requiring a date in the path meant
 * the first full sweep probed 1,977 of 17,492 distinct cited URLs — 11%. Four more fabricated URLs were
 * then found by hand among the CO-SOURCES of the rows it did flag, every one undated:
 * latimes.com/socal/daily-pilot/news/story/carson-economic-development-council,
 * two lynnma.gov/news/* pages, and a medfordma.org page. Eligibility is now DEPTH, not a date.
 */
const DATED_RE = /\/(19|20)\d{2}\/\d{1,2}\/(\d{1,2}\/)?/;

/**
 * Minimum sibling captures before absence is allowed to mean "never published". A parent-directory
 * control on a thin section (lynnma.gov/news has 7 archived URLs) is much weaker evidence than a
 * newspaper month with 200, so anything under this reports WEAK_CONTROL and is NOT called fabricated.
 */
const MIN_SIBLINGS = 5;

function hostOf(u) {
  try { return new URL(u).host.replace(/^www\./, '').toLowerCase(); } catch { return null; }
}

/** Path segments, empty ones dropped. */
function segs(u) {
  try { return new URL(u).pathname.split('/').filter(Boolean); } catch { return []; }
}

/**
 * Eligible = a SPECIFIC page, i.e. at least two path segments. One segment (or none) is a section or
 * landing page: its only available control is the whole host, and a richly-archived host proves nothing
 * about one unvisited page. Those are the nav-page defect, which has its own remedy.
 */
function isEligible(u) {
  return segs(u).length >= 2;
}

/**
 * The control prefix for a URL — the tightest sibling set the archive can be asked about.
 *   dated   → host/YYYY/MM*      (a newspaper's month; usually hundreds of captures)
 *   undated → host/<parent dir>* (the section the page claims to live in)
 * Returning the parent rather than the full path is the point: siblings must EXCLUDE the URL itself.
 */
function controlPrefix(u) {
  const host = hostOf(u);
  const m = u.match(/\/((?:19|20)\d{2})\/(\d{1,2})\//);
  if (m) return `${host}/${m[1]}/${m[2].padStart(2, '0')}*`;
  const s = segs(u);
  return `${host}/${s.slice(0, -1).join('/')}*`;
}

/**
 * HTTP status, with a curl fallback.
 *
 * 🔴 WHY THE FALLBACK. The first full sweep put 55 URLs in NO_ANSWER, and five of those hosts —
 * azcentral.com, detroitnews.com, freep.com, indystar.com, ktlo.com — answer HTTP 200 to curl. Node's
 * fetch fails on them (TLS/HTTP2 negotiation, or bot protection that fingerprints the client), so
 * NO_ANSWER was partly a tooling artifact rather than a finding. Any host that answers curl must be
 * classified on that answer.
 *
 * ⚠ This cannot create a false FABRICATED: that verdict requires a 404, which means a server answered.
 * A fetch failure can only ever land in NO_ANSWER, so the artifact was never able to invent a finding —
 * it could only hide one.
 */
async function fetchStatus(url) {
  try {
    const res = await fetch(url, { method: 'GET', redirect: 'follow', headers: { 'User-Agent': UA },
                                   signal: AbortSignal.timeout(30_000) });
    return res.status;
  } catch { /* fall through to curl */ }
  try {
    const { execFileSync } = await import('node:child_process');
    const out = execFileSync('curl', ['-s', '-o', '/dev/null', '-L', '--compressed', '--max-time', '25',
                                      '-A', UA, '-w', '%{http_code}', url],
                             { encoding: 'utf8', timeout: 30_000 });
    const code = Number(out.trim());
    return Number.isFinite(code) ? code : 0;
  } catch { return 0; }   // 0 = genuinely nothing answered: dead host, DNS, TLS.
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
  FABRICATED:    `path 404s, never archived, and >=${MIN_SIBLINGS} sibling pages in the same section/month ARE archived`,
  EXISTS:        'the archive holds a capture of this exact path',
  LIVE:          'the path answers with something other than 404/410',
  WEAK_CONTROL:  `path 404s and is unarchived, but the control has <${MIN_SIBLINGS} siblings — suggestive, NOT proven`,
  INCONCLUSIVE:  'no sibling coverage at all for that control, so absence proves nothing',
  NO_ANSWER:     'nothing answered, curl included — invented-host territory, not this defect',
};

/** The three-step test for one URL, shared by --url mode and the DB sweep. */
async function classify(url, controlCache = new Map()) {
  const host = hostOf(url);
  const key = controlPrefix(url);

  const status = await fetchStatus(url);
  if (status !== 404 && status !== 410) {
    return { host, status, verdict: status === 0 ? 'NO_ANSWER' : 'LIVE' };
  }

  await sleep(PACE);
  const exact = await cdxCount(url);
  if (exact === null) return { host, status, verdict: 'INCONCLUSIVE', why: 'CDX did not answer for the exact path', control: key };
  if (exact > 0)      return { host, status, verdict: 'EXISTS', captures: exact };

  let siblings = controlCache.get(key);
  if (siblings === undefined) {
    await sleep(PACE);
    siblings = await cdxCount(key, '&collapse=urlkey');
    // Only cache a real answer. Caching a null would poison every later URL in the same section with
    // one transient throttle — turning one unanswered probe into a whole section of false INCONCLUSIVE.
    if (siblings !== null) controlCache.set(key, siblings);
  }

  if (siblings === null) return { host, status, verdict: 'INCONCLUSIVE', why: 'control did not answer', control: key };
  if (siblings === 0)    return { host, status, verdict: 'INCONCLUSIVE', why: `archive holds no ${key} siblings either`, control: key };
  if (siblings < MIN_SIBLINGS) {
    return { host, status, verdict: 'WEAK_CONTROL', control_siblings: siblings, control: key,
             why: `only ${siblings} siblings — below the ${MIN_SIBLINGS} needed to call absence proof` };
  }
  return { host, status, verdict: 'FABRICATED', control_siblings: siblings, control: key, dated: DATED_RE.test(url) };
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

  // Eligibility is DEPTH, not a date: a specific page has >=2 path segments. Enforced in SQL so the
  // slice indices used for --from/--to chunking match what isEligible() would keep.
  const params = [];
  let where = `WHERE s ~* '^https?://[^/]+/[^/]+/.+'`;
  // --skip-dated excludes the dated URLs already swept and second-method verified, so a widening run
  // probes only the gap instead of redoing 1,977 URLs.
  if (argv.includes('--skip-dated')) where += ` AND s !~ '/(19|20)[0-9]{2}/[0-9]{1,2}/'`;
  if (argv.includes('--dated-only')) where += ` AND s ~ '/(19|20)[0-9]{2}/[0-9]{1,2}/'`;
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
  console.log(`${cites.length} specific-page cited URLs match; probing ${slice.length} (from ${FROM})\n`);

  const findings = [];
  // Control results are cached per prefix so one archive query serves every URL in the same
  // section/month — the single biggest saving against archive.org's rate limit.
  const controlCache = new Map();

  for (const [i, c] of slice.entries()) {
    const label = `[${FROM + i + 1}/${cites.length}]`;
    // classify() is shared with --url mode ON PURPOSE. The loop used to inline its own copy of the same
    // three steps, which is how the two paths would silently drift apart the next time one is changed.
    const r = await classify(c.url, controlCache);
    findings.push({ ...c, ...r });

    const note = r.verdict === 'FABRICATED'   ? `404 + 0 captures, ${r.control_siblings} siblings in ${r.control}`
               : r.verdict === 'EXISTS'       ? `404 now but ${r.captures} captures`
               : r.verdict === 'WEAK_CONTROL' ? r.why
               : r.verdict === 'INCONCLUSIVE' ? r.why
               : String(r.status);
    console.log(`${label} ${(r.verdict === 'FABRICATED' ? '🔴 FABRICATED' : r.verdict).padEnd(14)} ${note}  ${c.url}`);
  }

  const tally = {};
  for (const f of findings) tally[f.verdict] = (tally[f.verdict] ?? 0) + 1;

  // Tag the artifact with which slice of the corpus it covers. The dated and undated runs are disjoint
  // URL sets probed under different filters, and an untagged name makes a merged aggregate impossible to
  // audit — you cannot tell whether two files overlap or complement each other.
  const tag = argv.includes('--skip-dated') ? 'undated'
            : argv.includes('--dated-only') ? 'dated'
            : HOST ? `host-${HOST.replace(/[^a-z0-9]+/gi, '-')}`
            : 'all';
  const stampless = { generated_by: 'scripts/sweep-fabricated-articles.mjs', args: argv.join(' '), slice: tag };
  const out = path.join(OUTDIR, `fabricated-article-sweep-${tag}-${FROM}-${FROM + slice.length}.json`);
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
