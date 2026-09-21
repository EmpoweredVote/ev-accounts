/**
 * measure-wayback-cdx.ts — before/after evidence for decision 0003's tier-3
 * upgrade (the /available endpoint → the CDX API). See
 * ev-cto/tasks/2026-09-11-wayback-cdx-tier3.md.
 *
 * WHAT IT MEASURES. On a random 200-URL sample of public.source_verifications —
 * the same population the Playwright-removal STEP 1 used
 * (tasks/2026-09-11-remove-backend-playwright.md) — it runs tier 1 (plain fetch,
 * the legacy extractor that is production's default) and, for every tier-1 MISS,
 * compares two tier-3 implementations on the SAME URLs:
 *   OLD wayback = the /available endpoint only (production BEFORE this change).
 *   NEW wayback = fetchViaWayback (/available first, CDX on miss — this change).
 * "recovered" means the wayback text passes looksLikeRealPage — the exact gate
 * the ladder uses to accept a tier — so this counts real recoveries, not bytes.
 *
 * It also times both wayback paths, so the STOP-AND-ASK question ("negligible
 * recovery AND material added latency") can be answered with numbers.
 *
 * FAITHFUL TO PRODUCTION: tier 1 is fetchViaHttp (no browser — the browser tier
 * was removed in #467); the extractor is legacy (EXTRACTOR unset), so both OLD
 * and NEW strip HTML identically and the only variable is CDX-vs-/available.
 * Read-only over DB and network. Writes one JSON report + a stdout summary;
 * polite, low concurrency to archive.org.
 *
 * Usage:
 *   npx tsx scripts/measure-wayback-cdx.ts [--sample <frozen.json>] [--date YYYY-MM-DD] [--limit 200]
 * With no --sample it draws a fresh random sample and freezes it next to the report.
 */
import 'dotenv/config';
import { writeFileSync, readFileSync, mkdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { performance } from 'node:perf_hooks';
import { Pool } from 'pg';
import {
  fetchViaHttp,
  fetchViaWayback,
  looksLikeRealPage,
  htmlToText,
  EMPOWERED_VOTE_UA,
} from '../src/lib/verificationFetch.js';

const HTTP_TIMEOUT_MS = 12_000;

function opt(name: string, def?: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i !== -1 && i + 1 < process.argv.length ? process.argv[i + 1] : def;
}

const DATE = opt('--date', new Date().toISOString().slice(0, 10))!;
const LIMIT = Number(opt('--limit', '200'));
const SAMPLE_PATH = opt('--sample');
const OUT_DIR = 'data/wayback-cdx';
const TIER1_CONCURRENCY = 8; // distinct hosts — safe to spread
const WAYBACK_CONCURRENCY = 2; // all archive.org — keep it gentle

/**
 * OLD tier 3 — a faithful copy of the pre-CDX fetchViaWayback body: the
 * /available endpoint only, legacy extractor. This is production BEFORE the
 * change, run head-to-head against the new path on the same URL.
 */
async function oldWaybackAvailableOnly(url: string): Promise<string | null> {
  const noProto = url.replace(/^https?:\/\//, '');
  let snapUrl: string | undefined;
  try {
    const avail = await fetch(
      'https://archive.org/wayback/available?url=' + encodeURIComponent(noProto),
      { signal: AbortSignal.timeout(HTTP_TIMEOUT_MS) },
    );
    if (!avail.ok) return null;
    const json: any = await avail.json();
    const snap = json?.archived_snapshots?.closest;
    if (!snap?.url || String(snap.status) !== '200') return null;
    snapUrl = snap.url;
  } catch {
    return null;
  }
  try {
    const res = await fetch(snapUrl!, {
      signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
      headers: { 'user-agent': EMPOWERED_VOTE_UA },
    });
    if (!res.ok) return null;
    return htmlToText(await res.text()); // legacy extractor = production default
  } catch {
    return null;
  }
}

/** Run `fn` over `items` with at most `n` in flight. Order-independent. */
async function mapLimit<T, R>(items: T[], n: number, fn: (t: T, i: number) => Promise<R>): Promise<R[]> {
  const out: R[] = new Array(items.length);
  let next = 0;
  async function worker() {
    while (true) {
      const i = next++;
      if (i >= items.length) return;
      out[i] = await fn(items[i], i);
    }
  }
  await Promise.all(Array.from({ length: Math.min(n, items.length) }, worker));
  return out;
}

async function timed<T>(fn: () => Promise<T>): Promise<{ value: T; ms: number }> {
  const t0 = performance.now();
  const value = await fn();
  return { value, ms: Math.round(performance.now() - t0) };
}

function pct(part: number, whole: number): string {
  return whole === 0 ? '0.0%' : ((100 * part) / whole).toFixed(1) + '%';
}

function stats(xs: number[]) {
  if (xs.length === 0) return { n: 0, median: 0, mean: 0, p90: 0, max: 0 };
  const s = [...xs].sort((a, b) => a - b);
  const at = (q: number) => s[Math.min(s.length - 1, Math.floor(q * s.length))];
  return {
    n: s.length,
    median: at(0.5),
    mean: Math.round(s.reduce((a, b) => a + b, 0) / s.length),
    p90: at(0.9),
    max: s[s.length - 1],
  };
}

async function getSample(): Promise<string[]> {
  if (SAMPLE_PATH && existsSync(SAMPLE_PATH)) {
    console.log('Reusing frozen sample:', SAMPLE_PATH);
    return JSON.parse(readFileSync(SAMPLE_PATH, 'utf8'));
  }
  if (!process.env.DATABASE_URL) {
    console.error('ERROR: DATABASE_URL not set (need it to draw a sample, or pass --sample)');
    process.exit(2);
  }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  try {
    const { rows } = await pool.query(
      `SELECT url FROM (
         SELECT DISTINCT url FROM public.source_verifications
          WHERE url IS NOT NULL AND url <> ''
       ) s ORDER BY random() LIMIT $1`,
      [LIMIT],
    );
    return rows.map((r: { url: string }) => r.url);
  } finally {
    await pool.end();
  }
}

interface MissRow {
  url: string;
  oldRecovered: boolean;
  newRecovered: boolean;
  oldMs: number;
  newMs: number;
  newlyRecovered: boolean; // new got it, old did not — the whole point
  regressed: boolean; // old got it, new did not — must be ~0
}

async function main() {
  const urls = await getSample();
  console.log(`Sample: ${urls.length} distinct URLs from public.source_verifications\n`);

  // ── Tier 1 (plain fetch, legacy extractor). Miss = fails looksLikeRealPage. ──
  const tier1 = await mapLimit(urls, TIER1_CONCURRENCY, async (url) => {
    try {
      const text = await fetchViaHttp(url);
      return { url, hit: looksLikeRealPage(text) };
    } catch {
      return { url, hit: false };
    }
  });
  const tier1Hits = tier1.filter((r) => r.hit).length;
  const misses = tier1.filter((r) => !r.hit).map((r) => r.url);
  console.log(`Tier 1: ${tier1Hits}/${urls.length} hits, ${misses.length} misses → measuring Wayback on the misses\n`);

  // ── For every tier-1 miss: OLD (/available) vs NEW (/available+CDX) head-to-head. ──
  const rows = await mapLimit(misses, WAYBACK_CONCURRENCY, async (url): Promise<MissRow> => {
    const oldR = await timed(() => oldWaybackAvailableOnly(url).catch(() => null));
    const newR = await timed(() => fetchViaWayback(url).catch(() => null));
    const oldRecovered = !!oldR.value && looksLikeRealPage(oldR.value);
    const newRecovered = !!newR.value && looksLikeRealPage(newR.value);
    return {
      url,
      oldRecovered,
      newRecovered,
      oldMs: oldR.ms,
      newMs: newR.ms,
      newlyRecovered: newRecovered && !oldRecovered,
      regressed: oldRecovered && !newRecovered,
    };
  });

  const oldRecovered = rows.filter((r) => r.oldRecovered).length;
  const newRecovered = rows.filter((r) => r.newRecovered).length;
  const newly = rows.filter((r) => r.newlyRecovered);
  const regressed = rows.filter((r) => r.regressed);
  const oldMs = stats(rows.map((r) => r.oldMs));
  const newMs = stats(rows.map((r) => r.newMs));

  const summary = {
    date: DATE,
    sampleSize: urls.length,
    tier1Hits,
    tier1Misses: misses.length,
    waybackOldRecovered: oldRecovered,
    waybackNewRecovered: newRecovered,
    recoveryDelta: newRecovered - oldRecovered,
    newlyRecoveredCount: newly.length,
    regressedCount: regressed.length,
    latencyMsOld: oldMs,
    latencyMsNew: newMs,
    newlyRecoveredUrls: newly.map((r) => r.url),
    regressedUrls: regressed.map((r) => r.url),
  };

  mkdirSync(OUT_DIR, { recursive: true });
  if (!SAMPLE_PATH) {
    writeFileSync(join(OUT_DIR, `sample-${DATE}.json`), JSON.stringify(urls, null, 2));
  }
  writeFileSync(join(OUT_DIR, `report-${DATE}.json`), JSON.stringify({ summary, rows }, null, 2));

  console.log('──────────── RESULT (tier-1 misses only) ────────────');
  console.log(`sample                 ${urls.length}`);
  console.log(`tier-1 hits            ${tier1Hits} (${pct(tier1Hits, urls.length)})`);
  console.log(`tier-1 misses          ${misses.length} (${pct(misses.length, urls.length)})`);
  console.log(`Wayback OLD recovered  ${oldRecovered} of ${misses.length} misses (${pct(oldRecovered, misses.length)})`);
  console.log(`Wayback NEW recovered  ${newRecovered} of ${misses.length} misses (${pct(newRecovered, misses.length)})`);
  console.log(`recovery delta (NEW−OLD) ${summary.recoveryDelta >= 0 ? '+' : ''}${summary.recoveryDelta}  (newly=${newly.length}, regressed=${regressed.length})`);
  console.log(`latency OLD  ms  median=${oldMs.median} mean=${oldMs.mean} p90=${oldMs.p90} max=${oldMs.max}`);
  console.log(`latency NEW  ms  median=${newMs.median} mean=${newMs.mean} p90=${newMs.p90} max=${newMs.max}`);
  if (newly.length) console.log('newly recovered:\n  ' + newly.map((r) => r.url).join('\n  '));
  if (regressed.length) console.log('REGRESSED (old had, new lost):\n  ' + regressed.map((r) => r.url).join('\n  '));
  console.log(`\nreport → ${join(OUT_DIR, `report-${DATE}.json`)}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
