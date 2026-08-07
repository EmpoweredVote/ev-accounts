#!/usr/bin/env node
/**
 * Re-probe the NO_ANSWER findings from sweep-fabricated-articles.mjs, one host at a time.
 *
 * WHY THIS IS NECESSARY, NOT OPTIONAL. The widened sweep put 505 URLs in NO_ANSWER, and 439 of them are
 * a SINGLE host — leginfo.legislature.ca.gov — which answers HTTP 200 when asked once. It rate-limited
 * us under a burst of 187 back-to-back requests inside one chunk. The curl fallback in the sweep does
 * not help, because the block is by request rate, not by client fingerprint.
 *
 * 🔴 So NO_ANSWER is NOT a verdict, it is an un-evaluated URL. Left alone it reads as "nothing found",
 * which is the failure direction that matters: a fabricated citation sitting behind a rate limit is
 * invisible and the run still looks clean. Every NO_ANSWER must be re-asked before totals are reported.
 *
 * WHAT IT DOES DIFFERENTLY FROM THE SWEEP:
 *   - Groups by host and paces WITHIN a host (--host-pace, default 3s), so 439 URLs on one host are no
 *     longer a burst. Hosts are processed sequentially for the same reason.
 *   - SKIPS web.archive.org citations entirely. 47 NO_ANSWER URLs are Wayback captures — several of them
 *     ours, written by migrations 1557 and 1559. Asking "is this archived?" of an archive URL is
 *     meaningless, and hammering archive.org to find out is actively harmful.
 *
 * Usage (from backend/):
 *   node scripts/reprobe-no-answer.mjs                       # every NO_ANSWER in every sweep artifact
 *   node scripts/reprobe-no-answer.mjs --host leginfo.legislature.ca.gov
 *   node scripts/reprobe-no-answer.mjs --host-pace 5000
 *
 * Reads the sweep artifacts, writes reprobe-no-answer-results.json. Touches no database.
 */
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { cdxSiblingPages } from './sweep-fabricated-articles.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DIR = path.join(HERE, '..', 'data', 'stance-retirement');
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';

const argv = process.argv.slice(2);
const arg = (n, d) => { const i = argv.indexOf(`--${n}`); return i !== -1 && argv[i + 1] ? argv[i + 1] : d; };
const HOST_PACE = Number(arg('host-pace', '3000'));
const ONLY_HOST = arg('host', null);
const EXCLUDE_HOSTS = new Set((arg('exclude-host', '') || '').split(',').map((s) => s.trim()).filter(Boolean));
const CDX_PACE = Number(arg('cdx-pace', '1500'));
const OUT_NAME = arg('out', 'reprobe-no-answer-results.json');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Archive URLs are excluded by design — see the header. */
const isArchiveUrl = (u) => /(^|\.)web\.archive\.org/.test(u) || /(^|\.)archive\.org/.test(u);

/**
 * 🔴 READ STDOUT EVEN WHEN curl EXITS NON-ZERO. This is a false-negative bug that invalidated an entire
 * re-probe pass before it was caught. curl can return HTTP 200 on stdout and STILL exit non-zero — with
 * `-L --compressed` a content-decoding or stream quirk does exactly that — and execFileSync throws on a
 * non-zero exit. The old `catch { return 0 }` therefore recorded a perfectly good 200 as "nothing
 * answered". 362 leginfo URLs were confirmed dead this way while plain curl returned 200 in 0.2s.
 *
 * The failure direction is the dangerous one: it manufactures NO_ANSWER, and NO_ANSWER is the bucket
 * that silently looks clean. The written status code is authoritative; the exit code is not.
 */
function statusOf(url) {
  const args = ['-s', '-o', '/dev/null', '-L', '--compressed', '--max-time', '25',
                '-A', UA, '-w', '%{http_code}', url];
  let out;
  try {
    out = execFileSync('curl', args, { encoding: 'utf8', timeout: 30_000 });
  } catch (e) {
    out = String(e.stdout ?? '');   // curl printed the code, then exited non-zero. Trust the code.
  }
  const c = Number(String(out).trim());
  return Number.isFinite(c) ? c : 0;
}

async function cdxCount(pattern, extra = '') {
  const u = `http://web.archive.org/cdx/search/cdx?url=${encodeURIComponent(pattern)}&output=text&fl=timestamp&limit=200${extra}`;
  for (let attempt = 0; attempt < 3; attempt += 1) {
    if (attempt > 0) await sleep(CDX_PACE * attempt * 2);
    try {
      const res = await fetch(u, { headers: { 'User-Agent': UA }, signal: AbortSignal.timeout(60_000) });
      if (!res.ok) continue;
      const body = await res.text();
      // Never test for a bare "504" — CDX timestamps contain it. Markup only. (sweep script, same trap.)
      if (/<html|<head|Gateway Time-?out|Too Many Requests/i.test(body)) continue;
      return body.split('\n').filter((l) => l.trim()).length;
    } catch { /* retry */ }
  }
  return null;
}

function controlPrefix(u) {
  let host, segs;
  try { const x = new URL(u); host = x.host.replace(/^www\./, '').toLowerCase(); segs = x.pathname.split('/').filter(Boolean); }
  catch { return null; }
  const m = u.match(/\/((?:19|20)\d{2})\/(\d{1,2})\//);
  if (m) return `${host}/${m[1]}/${m[2].padStart(2, '0')}*`;
  return `${host}/${segs.slice(0, -1).join('/')}*`;
}

// ---- collect every NO_ANSWER from every sweep artifact ----
const byHost = new Map();
let skippedArchive = 0;
for (const f of readdirSync(DIR).filter((x) => /^fabricated-article-sweep-.*\.json$/.test(x))) {
  const d = JSON.parse(readFileSync(path.join(DIR, f), 'utf8'));
  for (const x of d.findings.filter((y) => y.verdict === 'NO_ANSWER')) {
    if (isArchiveUrl(x.url)) { skippedArchive += 1; continue; }
    const h = x.host ?? 'unknown';
    if (ONLY_HOST && h !== ONLY_HOST) continue;
    if (EXCLUDE_HOSTS.has(h)) continue;
    if (!byHost.has(h)) byHost.set(h, []);
    byHost.get(h).push(x);
  }
}

const totalUrls = [...byHost.values()].reduce((a, v) => a + v.length, 0);
console.log(`${totalUrls} NO_ANSWER urls across ${byHost.size} hosts to re-probe`);
console.log(`(${skippedArchive} archive.org citations skipped by design)\n`);

// RESUMABLE. This pass now covers ~1,000 urls at a deliberate pace, so a run that dies partway must not
// start over — and results were previously written only at the very end, so a kill lost everything.
// Cache per URL, flushed as we go; re-running the same command resumes.
const CACHE_PATH = path.join(DIR, `_${OUT_NAME.replace(/\.json$/, '')}-cache.json`);
let cache = {};
try { cache = JSON.parse(readFileSync(CACHE_PATH, 'utf8')); } catch { /* first run */ }

const results = [];
const controlCache = new Map();

for (const [host, items] of [...byHost.entries()].sort((a, b) => b[1].length - a[1].length)) {
  const pending = items.filter((it) => !cache[it.url]);
  for (const it of items) if (cache[it.url]) results.push(cache[it.url]);
  if (!pending.length) { console.log(`--- ${host}  (${items.length} urls, all cached)`); continue; }
  console.log(`--- ${host}  (${pending.length} of ${items.length} to probe, ${HOST_PACE}ms apart)`);
  let stillDead = 0;
  const record = (r) => { cache[r.url] = r; results.push(r); writeFileSync(CACHE_PATH, `${JSON.stringify(cache)}\n`); };
  for (const [i, it] of pending.entries()) {
    if (i > 0) await sleep(HOST_PACE);
    const status = statusOf(it.url);

    if (status === 0) { stillDead += 1; record({ ...it, reprobe_status: 0, verdict: 'NO_ANSWER_CONFIRMED' }); continue; }
    if (status !== 404 && status !== 410) { record({ ...it, reprobe_status: status, verdict: 'LIVE' }); continue; }

    // It answered, and said the page is gone — now the archive questions apply.
    await sleep(CDX_PACE);
    const exact = await cdxCount(it.url);
    if (exact === null)  { record({ ...it, reprobe_status: status, verdict: 'INCONCLUSIVE', why: 'CDX did not answer' }); continue; }
    if (exact > 0)       { record({ ...it, reprobe_status: status, verdict: 'EXISTS', captures: exact }); continue; }

    // 🔴 Use the SHARED, FIXED control. The local version counted distinct archived urls, which includes
    // crawler asset paths and section indexes — pressley.house.gov/issues* read as 200 siblings when it
    // has 6 real pages. A re-probe running the old control would mint new findings carrying a defect
    // that was just corrected everywhere else.
    const key = controlPrefix(it.url);
    let ctl = controlCache.get(key);
    if (ctl === undefined) {
      await sleep(CDX_PACE);
      ctl = await cdxSiblingPages(key);
      if (ctl !== null) controlCache.set(key, ctl);
    }
    if (ctl === null)        record({ ...it, reprobe_status: status, verdict: 'INCONCLUSIVE', why: 'control did not answer', control: key });
    else if (ctl.pages === 0) record({ ...it, reprobe_status: status, verdict: 'INCONCLUSIVE', why: `no ${key} sibling pages`, control: key, control_urls: ctl.total });
    else if (ctl.pages < 5)  record({ ...it, reprobe_status: status, verdict: 'WEAK_CONTROL', control_siblings: ctl.pages, control_urls: ctl.total, control: key });
    else {
      record({ ...it, reprobe_status: status, verdict: 'FABRICATED', control_siblings: ctl.pages, control_urls: ctl.total, control: key });
      console.log(`    🔴 FABRICATED  ${it.url}  (${it.rows_citing} rows, ${ctl.pages} sibling pages)`);
    }
  }
  const live = items.length - stillDead;
  console.log(`    ${live} answered on re-probe, ${stillDead} still no answer`);
}

const tally = {};
for (const r of results) tally[r.verdict] = (tally[r.verdict] ?? 0) + 1;
writeFileSync(path.join(DIR, OUT_NAME),
  `${JSON.stringify({ generated_by: 'scripts/reprobe-no-answer.mjs', args: argv.join(' '),
                      skipped_archive_urls: skippedArchive, tally, results }, null, 2)}\n`);

console.log('\n--- re-probe tally ---');
for (const [k, n] of Object.entries(tally).sort((a, b) => b[1] - a[1])) console.log(`  ${k.padEnd(22)} ${n}`);
const fab = results.filter((r) => r.verdict === 'FABRICATED');
if (fab.length) console.log(`\n🔴 ${fab.length} fabricated found HIDING in NO_ANSWER, covering ${fab.reduce((a, f) => a + Number(f.rows_citing), 0)} row-citations`);
console.log(`\nwrote data/stance-retirement/${OUT_NAME}`);
