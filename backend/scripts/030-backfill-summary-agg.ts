/**
 * 030-backfill-summary-agg.ts — one-time backfill of transparent_motivations.contribution_summary_agg
 * for every existing (politician_source_id, election_cycle) pair. quick-030 Task 4.
 *
 * After this runs (and migration 193 is applied), getSummary serves from the agg table
 * instead of scanning contributions. New ingests keep the agg fresh automatically
 * (runIngestion -> refreshSummaryAggForSource). Safe/idempotent and resumable: by default
 * it processes only pairs not yet in the agg table; pass --force to recompute all.
 *
 * Run durably (Render) after / alongside the completeness sweep — recompute is cheap per
 * pair (grouped queries), but there are thousands of pairs over a multi-GB table.
 *
 * Usage:
 *   tsx scripts/030-backfill-summary-agg.ts [limit] [maxMinutes] [--force | --gross-missing]
 *     limit           — max pairs this session (default: all pending)
 *     maxMinutes      — soft wall-clock budget (default: none)
 *     --force         — recompute pairs already present in the agg table
 *     --gross-missing — recompute only agg rows whose gross_amount IS NULL, i.e. rows last written
 *                       before CA_0255 (gross receipts + refunds on their own line). Reads only the
 *                       small agg table to find them, so it never scans contributions. Resumable.
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { refreshSummaryAgg } from '../src/lib/campaignFinanceService.js';

const LIMIT = process.argv[2] && !process.argv[2].startsWith('--') ? parseInt(process.argv[2], 10) : Infinity;
const MAX_MINUTES = process.argv[3] && !process.argv[3].startsWith('--') ? parseInt(process.argv[3], 10) : Infinity;
const FORCE = process.argv.includes('--force');
const GROSS_MISSING = process.argv.includes('--gross-missing');

interface Pair { politician_source_id: string; election_cycle: string }

async function getPending(): Promise<Pair[]> {
  if (GROSS_MISSING) {
    const r = await pool.query<Pair>(
      `SELECT politician_source_id, election_cycle
         FROM transparent_motivations.contribution_summary_agg
        WHERE gross_amount IS NULL
        ORDER BY election_cycle DESC`
    );
    return r.rows;
  }
  // All distinct (source, cycle) pairs present in contributions, minus those already
  // aggregated (unless --force). DISTINCT over the big table is a one-time cost.
  const sql = FORCE
    ? `SELECT DISTINCT politician_source_id, election_cycle
         FROM transparent_motivations.contributions
        ORDER BY election_cycle DESC`
    : `SELECT c.politician_source_id, c.election_cycle
         FROM (SELECT DISTINCT politician_source_id, election_cycle
                 FROM transparent_motivations.contributions) c
         LEFT JOIN transparent_motivations.contribution_summary_agg a
           ON a.politician_source_id = c.politician_source_id
          AND a.election_cycle = c.election_cycle
        WHERE a.politician_source_id IS NULL
        ORDER BY c.election_cycle DESC`;
  const r = await pool.query<Pair>(sql);
  return r.rows;
}

async function main(): Promise<void> {
  if (!process.env.DATABASE_URL) { console.error('ERROR: DATABASE_URL not set'); process.exit(1); }

  if (FORCE && GROSS_MISSING) { console.error('ERROR: --force and --gross-missing are exclusive'); process.exit(1); }
  const mode = FORCE ? 'ALL' : GROSS_MISSING ? 'gross-missing (pre-CA_0255)' : 'un-aggregated';
  console.log(`[030-backfill-agg] scanning for ${mode} (source,cycle) pairs...`);
  const pending = await getPending();
  const todo = pending.slice(0, LIMIT === Infinity ? pending.length : LIMIT);
  console.log(`[030-backfill-agg] pairs pending=${pending.length} processing=${todo.length} force=${FORCE} maxMinutes=${MAX_MINUTES}`);

  const start = Date.now();
  let ok = 0, failed = 0;
  for (let i = 0; i < todo.length; i++) {
    if ((Date.now() - start) / 60000 >= MAX_MINUTES) {
      console.log(`[030-backfill-agg] wall-clock budget reached — stopping after ${i} pairs.`);
      break;
    }
    const p = todo[i]!;
    try {
      await refreshSummaryAgg(p.politician_source_id, p.election_cycle);
      ok++;
    } catch (err) {
      failed++;
      console.error(`[030-backfill-agg] ✗ ${p.politician_source_id} [${p.election_cycle}]: ${err instanceof Error ? err.message : String(err)}`);
    }
    if ((i + 1) % 200 === 0 || i === todo.length - 1) {
      console.log(`[030-backfill-agg] ${i + 1}/${todo.length} (ok=${ok} failed=${failed}) [${((Date.now() - start) / 60000).toFixed(1)}m]`);
    }
  }

  const remaining = FORCE ? 0 : (await getPending()).length;
  console.log(`\n=== 030 SUMMARY-AGG BACKFILL ===`);
  console.log(`Pairs OK: ${ok}  Failed: ${failed}`);
  if (!FORCE) console.log(`Pairs still ${GROSS_MISSING ? 'without gross_amount' : 'un-aggregated'}: ${remaining}${remaining > 0 ? ' (re-run to continue)' : ''}`);
  console.log(`Elapsed: ${((Date.now() - start) / 60000).toFixed(1)} min`);

  await pool.end();
  process.exit(0);
}

main().catch((err) => { console.error('[030-backfill-agg] Fatal:', err); process.exit(1); });
