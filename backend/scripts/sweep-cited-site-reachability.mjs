#!/usr/bin/env node
/**
 * Reachability sweep over every distinct host cited by the PRIMARY_SITE_NO_PATH bucket.
 *
 * WHY. Working the top of the calibrated queue found 3 of 12 sites unusable, stranding 9 rows --
 * against a DEAD_SITE backlog item that claims 16 rows in total. If that rate is representative, a
 * large share of this bucket is not "suspect reasoning" at all but "citation a voter cannot open",
 * which is a different and cheaper remedy: re-source to an archive, as 1519 did for neighbors4faye.
 *
 * 🔴 CLASSIFY EVERY NON-200 SEPARATELY. This has bitten the workstream three times; once, 214
 * HTTP-202s nearly recorded 168 correctly-sourced rows as unsupported. A 403 is a bot block and the
 * page renders fine in a browser; 202/429/503 are throttling and say nothing; 404/410 and DNS
 * failure are the only ones that mean gone. They are never merged here.
 *
 * 🔴 A THIN BODY IS NOT AN ABSENT CLAIM, AND NOT A DEAD SITE EITHER. A React/Vue campaign site
 * serves an empty shell to a plain fetch (moforla.com: 180 chars). That is its own class.
 *
 * 🔴 TRANSIENT FAILURES ARE RETRIED ONCE. A single connection reset is not evidence of anything, and
 * this sweep's output will be used to decide whether rows get re-sourced.
 *
 * Usage (from backend/):
 *   node scripts/sweep-cited-site-reachability.mjs --out data/stance-retirement/2026-08-01-reachability.json
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { Pool } from 'pg';
import { fetchPage, pooled, sleep } from './lib/site-crawl.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-01-reachability.json');
const MD = flag('--md');
const CONCURRENCY = parseInt(flag('--concurrency', '8'), 10);
const MIN_BODY = 600;

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

/** One fetch, classified. Never returns a bare boolean -- the class is the whole point. */
async function probe(url) {
  const p = await fetchPage(url, { minBody: MIN_BODY, cacheTtlHours: 24 });
  if (p.status === 200 && p.body.length >= MIN_BODY) return { cls: 'OK', status: 200, body: p.body.length };
  if (p.status === 200) return { cls: 'THIN_SHELL', status: 200, body: p.body.length, note: p.notHtml ?? null };
  if (p.status === 403) return { cls: 'BOT_BLOCKED', status: 403 };
  if ([202, 429, 503, 500, 502, 504].includes(p.status)) return { cls: 'THROTTLED_OR_ERROR', status: p.status };
  if (p.status === 404 || p.status === 410) return { cls: 'GONE', status: p.status };
  if (p.status === 0 && /ENOTFOUND|EAI_AGAIN|ERR_NAME|ECONNREFUSED|certificate/i.test(p.error ?? '')) {
    return { cls: 'DNS_OR_TLS_FAIL', status: 0, error: p.error };
  }
  return { cls: 'FETCH_FAILED', status: p.status, error: p.error ?? null };
}

/**
 * Is there anything in the Wayback Machine to re-source to?
 * ⚠ NO `collapse=urlkey`. On neighbors4faye.com it reported 2 snapshots where there are 46, which
 * nearly justified retiring four correctly-sourced rows. Also: the `host*` wildcard form returned an
 * EMPTY body for erinforutah.com while the exact-host form found the capture -- an empty CDX response
 * is a query-form artifact as often as it is an absence, so both forms are tried.
 */
async function wayback(host) {
  for (const u of [`http://web.archive.org/cdx/search/cdx?url=${host}&output=json&fl=timestamp,statuscode&limit=200`,
    `http://web.archive.org/cdx/search/cdx?url=${host}/*&output=json&fl=timestamp,statuscode&limit=200`]) {
    try {
      const res = await fetch(u, { signal: AbortSignal.timeout(45000) });
      if (!res.ok) continue;
      const txt = await res.text();
      if (!txt.trim()) continue;
      const rows = JSON.parse(txt);
      const body = Array.isArray(rows) && rows.length > 1 ? rows.slice(1) : [];
      const ok = body.filter((r) => String(r[1]).startsWith('2'));
      if (body.length) return { snapshots: body.length, usable: ok.length, latest: ok.at(-1)?.[0] ?? null };
    } catch { /* try the next form */ }
    await sleep(400);
  }
  return { snapshots: 0, usable: 0, latest: null };
}

(async () => {
  if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }

  const { rows } = await pool.query(`
    SELECT pa.politician_id::text AS pid, pa.topic_id::text AS tid,
           p.first_name || ' ' || p.last_name AS name,
           coalesce(t.short_title, t.title) AS topic, pc.sources
      FROM inform.politician_answers pa
      JOIN inform.politician_context pc
        ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
      JOIN essentials.politicians p ON p.id = pa.politician_id
      LEFT JOIN inform.compass_topics t ON t.id = pa.topic_id
     WHERE pa.value <> 0
       AND pc.sources IS NOT NULL AND array_length(pc.sources, 1) > 0
       AND NOT EXISTS (
             SELECT 1 FROM unnest(pc.sources) s
              WHERE btrim(regexp_replace(btrim(s, '/'), '^https?://(www\\.)?', '')) LIKE '%/%')
       AND NOT EXISTS (
             SELECT 1 FROM unnest(pc.sources) s
              WHERE lower(regexp_replace(btrim(s, '/'), '^https?://(www\\.)?', '')) IN (
                'ballotpedia.org','wikipedia.org','en.wikipedia.org','vote411.org','votesmart.org',
                'ontheissues.org','opensecrets.org','followthemoney.org','govtrack.us',
                'legiscan.com','congress.gov','senate.gov','house.gov','ourcampaigns.com'))`);
  await pool.end();

  const norm = (s) => { const t = s.trim(); return /^https?:\/\//i.test(t) ? t : `https://${t}`; };
  const byHost = new Map();
  for (const r of rows) {
    const u = norm(r.sources[0]);
    let h; try { h = new URL(u).hostname; } catch { h = u; }
    if (!byHost.has(h)) byHost.set(h, { host: h, url: u, rows: [] });
    byHost.get(h).rows.push({ pid: r.pid, tid: r.tid, name: r.name, topic: r.topic });
  }
  const hosts = [...byHost.values()];
  console.log(`${rows.length} rows across ${hosts.length} distinct hosts\n`);

  let done = 0;
  const results = await pooled(hosts, CONCURRENCY, async (h) => {
    let res = await probe(h.url);
    // Retry transient shapes once, on the other scheme, before recording anything as unreachable.
    if (['FETCH_FAILED', 'THROTTLED_OR_ERROR', 'DNS_OR_TLS_FAIL'].includes(res.cls)) {
      await sleep(1200);
      const alt = h.url.startsWith('https://') ? h.url.replace('https://', 'http://') : h.url;
      const again = await probe(alt);
      if (again.cls === 'OK' || again.cls === 'THIN_SHELL') res = { ...again, note: 'recovered on retry' };
      else res = { ...res, retried: true, retryCls: again.cls };
    }
    done += 1;
    if (done % 25 === 0) console.log(`  ${done}/${hosts.length} hosts`);
    return { ...h, ...res };
  });

  // Only the unreachable classes need an archive check.
  const broken = results.filter((r) => ['GONE', 'DNS_OR_TLS_FAIL', 'THIN_SHELL', 'FETCH_FAILED'].includes(r.cls));
  console.log(`\nchecking Wayback for ${broken.length} unreachable host(s)…`);
  await pooled(broken, 4, async (r) => { r.wayback = await wayback(r.host); });

  const byCls = {};
  for (const r of results) {
    byCls[r.cls] ??= { hosts: 0, rows: 0 };
    byCls[r.cls].hosts += 1;
    byCls[r.cls].rows += r.rows.length;
  }
  console.log('\n=== reachability of cited sites ===');
  console.log('  class                 hosts   rows');
  for (const [c, v] of Object.entries(byCls).sort((a, b) => b[1].rows - a[1].rows)) {
    console.log(`  ${c.padEnd(20)} ${String(v.hosts).padStart(5)}  ${String(v.rows).padStart(5)}`);
  }
  const resourceable = broken.filter((r) => r.wayback?.usable > 0);
  console.log(`\nunreachable hosts with a usable Wayback capture: ${resourceable.length}/${broken.length}`
    + `  (${resourceable.reduce((n, r) => n + r.rows.length, 0)} rows re-sourceable)`);

  writeFileSync(OUT, `${JSON.stringify({ generated: { rows: rows.length, hosts: hosts.length }, byCls, sites: results }, null, 2)}\n`);
  console.log(`\nwritten to ${OUT}`);
})().catch(async (e) => { console.error('FAIL:', e); try { await pool.end(); } catch {} process.exit(2); });
