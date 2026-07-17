/**
 * 030-completeness-sweep.ts — re-ingest TRUNCATED FEC (source,cycle) pairs to full
 * itemized coverage, biggest-money races first, at a raised cap, rate-safe and resumable.
 *
 * Part of quick-030 (FEC completeness sweep), Task 3. Depends on Task 1 (incremental
 * per-window commit — so a restart mid-mega-pair does not lose the pull) and Task 2
 * (getTruncatedPairs work-list + runFecForcedReingest forced path).
 *
 * How it satisfies the plan's constraints:
 *   - Cap raised: forces MAX_RECORDS_PER_POLITICIAN very high (rely on windowing +
 *     keyset end) unless SWEEP_MAX_RECORDS is set. Set BEFORE importing the adapter
 *     (the cap is read at adapter module-load), hence the dynamic imports below.
 *   - Largest-first: FEC_SORT stays -contribution_receipt_amount, so even a partial
 *     capture favors the biggest donors.
 *   - Biggest races first: getTruncatedPairs() is ranked by expected DESC.
 *   - Rate-safe: FEC_PER_PAGE_SLEEP_MS defaults to 2000ms (~30 pages/min, under the
 *     60/min shared-key ceiling) and 3s between pairs; holds the FEC Redis lock so the
 *     6-hourly cron skips while the sweep runs (single consumer on the shared key).
 *   - Resumable: re-running recomputes getTruncatedPairs(), which already drops pairs
 *     now at >= threshold; Task 1's window-progress skips finished windows within a pair.
 *   - Durable: designed to run on Render, not a fragile local job. A wall-clock budget
 *     (maxMinutes) releases the lock between sessions so the cron is not starved.
 *
 * Usage (on Render shell / durable worker):
 *   tsx scripts/030-completeness-sweep.ts [limit] [maxMinutes] [threshold]
 *     limit       — max pairs this session (default: all remaining)
 *     maxMinutes  — wall-clock budget; abort cleanly between pairs (default: 300)
 *     threshold   — coverage bar (default: 0.95)
 *   env overrides: SWEEP_MAX_RECORDS, FEC_PER_PAGE_SLEEP_MS, SWEEP_SLEEP_BETWEEN_MS
 */

import 'dotenv/config';

// Raise the cap + set safe pacing BEFORE the adapter module loads (it reads these at
// import time). Real env vars set by the operator win; otherwise these defaults apply.
process.env.MAX_RECORDS_PER_POLITICIAN = process.env.SWEEP_MAX_RECORDS ?? '100000000';
process.env.FEC_PER_PAGE_SLEEP_MS = process.env.FEC_PER_PAGE_SLEEP_MS ?? '2000';
process.env.FEC_SORT = process.env.FEC_SORT ?? '-contribution_receipt_amount';

const { pool } = await import('../src/lib/db.js');
const { getTruncatedPairs } = await import('./030-find-truncated-fec-pairs.js');
const {
  runFecForcedReingest,
  acquireLock,
  renewLock,
  releaseLock,
  FEC_LOCK_KEY,
} = await import('../src/lib/campaignFinanceScheduler.js');

const LIMIT = process.argv[2] ? parseInt(process.argv[2], 10) : Infinity;
const MAX_MINUTES = process.argv[3] ? parseInt(process.argv[3], 10) : 300;
const THRESHOLD = process.argv[4] ? parseFloat(process.argv[4]) : 0.95;
const SLEEP_BETWEEN_MS = process.env.SWEEP_SLEEP_BETWEEN_MS ? parseInt(process.env.SWEEP_SLEEP_BETWEEN_MS, 10) : 3000;

// Supabase Pro: first 8GB included in $25/mo, then $0.125/GB-mo.
const SUPABASE_FREE_GB = 8;
const SUPABASE_PER_GB = 0.125;

async function dbSizeGB(): Promise<number> {
  const r = await pool.query<{ b: string }>(`SELECT pg_database_size(current_database()) AS b`);
  return Number(r.rows[0]!.b) / 1024 ** 3;
}
async function contribCount(): Promise<number> {
  const r = await pool.query<{ n: string }>(
    `SELECT count(*) n FROM transparent_motivations.contributions WHERE data_source='fec'`
  );
  return Number(r.rows[0]!.n);
}

async function main(): Promise<void> {
  if (!process.env.FEC_API_KEY) { console.error('ERROR: FEC_API_KEY not set'); process.exit(1); }
  if (!process.env.DATABASE_URL) { console.error('ERROR: DATABASE_URL not set'); process.exit(1); }

  // Single consumer on the shared FEC key: hold the same lock the cron uses.
  const locked = await acquireLock(FEC_LOCK_KEY);
  if (!locked) {
    console.error('[030-sweep] FEC lock held by another consumer (cron or another sweep) — exiting. Retry later.');
    await pool.end();
    process.exit(0);
  }
  const renewTimer = setInterval(() => {
    renewLock(FEC_LOCK_KEY).catch((e) => console.warn('[030-sweep] lock renew failed:', e instanceof Error ? e.message : e));
  }, 5 * 60 * 1000);

  // Wall-clock budget: abort cleanly between pairs so the lock is released and the cron
  // gets a window. Task 1's incremental commit means an in-flight pair is not lost.
  const controller = new AbortController();
  const budgetTimer = setTimeout(() => {
    console.log(`[030-sweep] wall-clock budget (${MAX_MINUTES}m) reached — aborting after current pair.`);
    controller.abort();
  }, MAX_MINUTES * 60 * 1000);

  let ok = 0, failed = 0;
  const startGB = await dbSizeGB();
  const startCount = await contribCount();

  try {
    const pairs = await getTruncatedPairs(THRESHOLD);
    const todo = pairs.slice(0, LIMIT === Infinity ? pairs.length : LIMIT);
    console.log(`[030-sweep] truncated pairs remaining: ${pairs.length} | processing this session: ${todo.length}`);
    console.log(`[030-sweep] cap=${process.env.MAX_RECORDS_PER_POLITICIAN} pageSleep=${process.env.FEC_PER_PAGE_SLEEP_MS}ms betweenPairs=${SLEEP_BETWEEN_MS}ms budget=${MAX_MINUTES}m`);
    console.log(`[030-sweep] DB now ${startGB.toFixed(2)} GB, ${startCount.toLocaleString()} FEC rows`);

    const t0 = Date.now();
    const result = await runFecForcedReingest(
      todo.map((p) => ({ sourceId: p.sourceId, cycle: p.cycle })),
      {
        sleepBetweenMs: SLEEP_BETWEEN_MS,
        signal: controller.signal,
        onProgress: (info) => {
          const src = todo[info.index];
          const exp = src?.expected != null ? `/${src.expected.toLocaleString()}` : '';
          const mins = ((Date.now() - t0) / 60000).toFixed(1);
          if (info.error) {
            console.error(`[030-sweep] ✗ ${info.index + 1}/${info.total} [${info.pair.cycle}] ${info.fullName}: ${info.error}`);
          } else {
            console.log(`[030-sweep] ✓ ${info.index + 1}/${info.total} [${info.pair.cycle}] ${info.fullName} → ${info.rows.toLocaleString()}${exp} rows [${mins}m]`);
          }
        },
      }
    );
    ok = result.ok; failed = result.failed;
  } finally {
    clearInterval(renewTimer);
    clearTimeout(budgetTimer);
    await releaseLock(FEC_LOCK_KEY).catch(() => {});
  }

  const endGB = await dbSizeGB();
  const endCount = await contribCount();
  const remaining = await getTruncatedPairs(THRESHOLD);

  const addedGB = endGB - startGB;
  const billableGB = Math.max(endGB - SUPABASE_FREE_GB, 0);
  const monthly = billableGB * SUPABASE_PER_GB;

  console.log(`\n=== 030 COMPLETENESS SWEEP SUMMARY ===`);
  console.log(`Pairs OK: ${ok}  Failed: ${failed}`);
  console.log(`FEC rows: ${startCount.toLocaleString()} → ${endCount.toLocaleString()} (+${(endCount - startCount).toLocaleString()})`);
  console.log(`DB size:  ${startGB.toFixed(2)} GB → ${endGB.toFixed(2)} GB (+${addedGB.toFixed(2)} GB this session)`);
  console.log(`Est. Supabase storage cost @ current size: $${monthly.toFixed(2)}/mo (${billableGB.toFixed(1)} GB billable over the ${SUPABASE_FREE_GB}GB Pro allowance)`);
  console.log(`Truncated pairs still below ${(THRESHOLD * 100).toFixed(0)}%: ${remaining.length}`);
  if (remaining.length > 0) console.log(`Re-run this script to continue (resumable — finished pairs are skipped).`);

  await pool.end();
  process.exit(0);
}

main().catch((err) => { console.error('[030-sweep] Fatal:', err); process.exit(1); });
