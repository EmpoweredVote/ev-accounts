#!/usr/bin/env node
/**
 * Probe EVERY distinct URL cited by a published stance row -- deep paths included.
 *
 * WHY, AND WHY THE EARLIER SWEEP WAS NOT ENOUGH. 2026-08-01's reachability sweep only probed the bare
 * HOSTS of the PRIMARY_SITE_NO_PATH bucket. A citation that parses as a perfectly valid URL but 404s
 * is invisible to it, and invisible to every gate branch too, because they all classify by the SHAPE
 * of the URL. Three turned up by accident in one evening:
 *   - Mónica García x3 -> a renamed Ballotpedia page (found only because two rows reached it by
 *     different routes, one of them split on a comma)
 *   - Colter Carlisle -> theeastsiderla.com interview, 404, and it is the ONLY substantive source on
 *     several of his rows
 * There is no reason to think those three are special, which is the whole point of sweeping.
 *
 * 🔴 CLASSIFY EVERY NON-200; NEVER COLLAPSE THEM. 403 is a bot block and the page is fine for a
 * voter; 429/503 is throttling and says nothing at all; only 404/410 and DNS failure mean gone. This
 * workstream has been bitten three times by treating a non-200 as absence, once nearly recording 168
 * correctly-sourced rows as unsupported.
 *
 * 🔴 BE POLITE. 590 of these are Ballotpedia and thousands share a handful of hosts. URLs are bucketed
 * BY HOST and each host is walked sequentially with a delay; only different hosts run concurrently.
 * HEAD first, GET only if the server rejects HEAD.
 *
 * Usage (from backend/):
 *   node scripts/sweep-deep-url-reachability.mjs --out data/stance-retirement/2026-08-02-deep-url-reachability.json
 */
import 'dotenv/config';
import { writeFileSync, appendFileSync, readFileSync, existsSync } from 'node:fs';
import { Pool } from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-02-deep-url-reachability.json');
/**
 * 🔴 CHECKPOINT EVERY RESULT AS IT ARRIVES, AND RESUME FROM IT.
 * The first version of this script wrote its JSON only at the end. It was killed at 11,500 of 17,888
 * URLs -- roughly an hour of probing -- and every result was lost, which also means re-running hits
 * 11,500 third-party servers a second time for nothing. An interruptible job measured in hours must
 * be restartable, and re-probing someone else's site because WE lost the answer is not acceptable.
 * Results are appended here one JSON object per line; a restart skips whatever is already recorded.
 */
const JSONL = flag('--jsonl', 'data/stance-retirement/2026-08-02-deep-url-reachability.jsonl');
const HOST_CONCURRENCY = parseInt(flag('--hosts', '8'), 10);
const HOST_DELAY = parseInt(flag('--delay', '700'), 10);
const LIMIT = parseInt(flag('--limit', '0'), 10);

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function classify(status, err) {
  if (status === 200 || status === 206) return 'OK';
  if (status >= 300 && status < 400) return 'OK';               // redirect chains resolve for a reader
  if (status === 401 || status === 403) return 'BOT_BLOCKED';
  if (status === 404 || status === 410) return 'GONE';
  if ([408, 429, 500, 502, 503, 504].includes(status)) return 'THROTTLED_OR_ERROR';
  if (status === 0 && /ENOTFOUND|EAI_AGAIN|ERR_NAME|ECONNREFUSED|certificate|altnames/i.test(err ?? '')) return 'DNS_OR_TLS_FAIL';
  if (status === 0) return 'FETCH_FAILED';
  return `HTTP_${status}`;
}

async function probe(url) {
  for (const method of ['HEAD', 'GET']) {
    try {
      const res = await fetch(url, {
        method, headers: { 'User-Agent': UA, Accept: 'text/html,*/*' },
        redirect: 'follow', signal: AbortSignal.timeout(25000),
      });
      // Some servers reject HEAD outright; that is not information about the page.
      if (method === 'HEAD' && [400, 405, 501].includes(res.status)) continue;
      return { status: res.status, finalUrl: res.url || url };
    } catch (e) {
      if (method === 'GET') return { status: 0, error: e.message };
    }
  }
  return { status: 0, error: 'both methods failed' };
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

(async () => {
  if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }
  const { rows } = await pool.query(`
    SELECT btrim(x) AS url, count(*)::int AS n_rows
      FROM inform.politician_context pc
      JOIN inform.politician_answers pa
        ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
      CROSS JOIN LATERAL unnest(pc.sources) x
     WHERE pa.value <> 0 AND pc.sources IS NOT NULL
       AND btrim(x) ~* '^https?://'
     GROUP BY 1 ORDER BY 1`);
  await pool.end();

  const allRows = LIMIT ? rows.slice(0, LIMIT) : rows;

  // Resume: anything already recorded in the checkpoint is not probed again.
  const results = [];
  const done = new Set();
  if (existsSync(JSONL)) {
    for (const line of readFileSync(JSONL, 'utf8').split('\n')) {
      if (!line.trim()) continue;
      try { const r = JSON.parse(line); if (!done.has(r.url)) { done.add(r.url); results.push(r); } } catch { /* skip a torn final line */ }
    }
    console.log(`resuming — ${done.size} URL(s) already probed, skipping them`);
  }
  const all = allRows.filter((r) => !done.has(r.url));

  const byHost = new Map();
  for (const r of all) {
    let h; try { h = new URL(r.url).hostname; } catch { h = 'UNPARSEABLE'; }
    if (!byHost.has(h)) byHost.set(h, []);
    byHost.get(h).push(r);
  }
  const hosts = [...byHost.entries()].sort((a, b) => b[1].length - a[1].length);
  console.log(`${all.length} distinct URLs across ${hosts.length} hosts`);
  console.log(`biggest: ${hosts.slice(0, 5).map(([h, u]) => `${h}(${u.length})`).join(' ')}`);
  console.log('probing — HEAD first, per-host serialised…\n');

  let n = 0; let started = 0;
  const t0 = Date.now();
  const worker = async () => {
    while (started < hosts.length) {
      const [host, urls] = hosts[started++];
      for (const u of urls) {
        const p = await probe(u.url);
        const cls = classify(p.status, p.error);
        const rec = { url: u.url, host, n_rows: u.n_rows, status: p.status, cls, error: p.error ?? null };
        results.push(rec);
        appendFileSync(JSONL, `${JSON.stringify(rec)}\n`);   // checkpoint before anything else can go wrong
        n += 1;
        if (n % 250 === 0) {
          const rate = n / ((Date.now() - t0) / 1000);
          const eta = Math.round((all.length - n) / rate / 60);
          console.log(`  ${n}/${all.length}  (${rate.toFixed(1)}/s, ~${eta}m left)`);
        }
        if (urls.length > 1) await sleep(HOST_DELAY);
      }
    }
  };
  await Promise.all(Array.from({ length: Math.min(HOST_CONCURRENCY, hosts.length) }, worker));

  const byCls = {};
  for (const r of results) {
    byCls[r.cls] ??= { urls: 0, rows: 0 };
    byCls[r.cls].urls += 1;
    byCls[r.cls].rows += r.n_rows;
  }
  console.log('\n=== deep URL reachability ===');
  console.log('  class                  urls    row-citations');
  for (const [c, v] of Object.entries(byCls).sort((a, b) => b[1].rows - a[1].rows)) {
    console.log(`  ${c.padEnd(20)} ${String(v.urls).padStart(6)}  ${String(v.rows).padStart(8)}`);
  }
  const gone = results.filter((r) => r.cls === 'GONE' || r.cls === 'DNS_OR_TLS_FAIL');
  console.log(`\n🔴 dead citations: ${gone.length} URLs across ${gone.reduce((n, r) => n + r.n_rows, 0)} row-citations`);
  console.log('top dead hosts:');
  const deadByHost = {};
  for (const r of gone) deadByHost[r.host] = (deadByHost[r.host] ?? 0) + r.n_rows;
  for (const [h, n] of Object.entries(deadByHost).sort((a, b) => b[1] - a[1]).slice(0, 15)) {
    console.log(`  ${String(n).padStart(4)} rows  ${h}`);
  }

  writeFileSync(OUT, `${JSON.stringify({ generated: { urls: all.length, hosts: hosts.length }, byCls, results }, null, 2)}\n`);
  console.log(`\nwritten to ${OUT}`);
})().catch(async (e) => { console.error('FAIL:', e); try { await pool.end(); } catch {} process.exit(2); });
