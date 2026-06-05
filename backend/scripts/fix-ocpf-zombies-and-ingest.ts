/**
 * fix-ocpf-zombies-and-ingest.ts
 *
 * 1. Marks any stuck 'running' ingestion_runs rows for ocpf as 'failed'
 *    (these are from prior DNS-failure runs that never completed)
 * 2. Runs runAdapterForAll('ocpf') to ingest contributions for all confirmed sources
 *
 * Usage (from C:\EV-Accounts\backend):
 *   npx tsx scripts/fix-ocpf-zombies-and-ingest.ts
 */

import 'dotenv/config';
import pg from 'pg';
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';

if (!process.env['DATABASE_URL']) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new pg.Pool({ connectionString: process.env['DATABASE_URL'] });

// ---------------------------------------------------------------------------
// Step 1: Clean up zombie runs
// ---------------------------------------------------------------------------

console.log('[fix-ocpf] Step 1: Cleaning up zombie ingestion_runs...');

const zombieResult = await pool.query(`
  UPDATE transparent_motivations.ingestion_runs ir
  SET status = 'failed',
      completed_at = NOW(),
      notes = 'Marked failed by fix-ocpf-zombies-and-ingest.ts — DNS failure during prior run'
  FROM transparent_motivations.politician_sources ps
  WHERE ir.politician_source_id = ps.id
    AND ps.source_system = 'ocpf'
    AND ir.status = 'running'
  RETURNING ir.id, ps.external_id
`);

if (zombieResult.rowCount === 0) {
  console.log('[fix-ocpf] No zombie runs found — already clean.');
} else {
  console.log(`[fix-ocpf] Marked ${zombieResult.rowCount} zombie run(s) as failed:`);
  zombieResult.rows.forEach((r: Record<string, unknown>) => console.log(`  run id=${r['id']} cpfId=${r['external_id']}`));
}

await pool.end();

// ---------------------------------------------------------------------------
// Step 2: Run ingest
// ---------------------------------------------------------------------------

console.log('\n[fix-ocpf] Step 2: Running OCPF ingest for all confirmed sources...');

try {
  await runAdapterForAll('ocpf');
  console.log('[fix-ocpf] Ingest complete.');
} catch (err) {
  console.error('[fix-ocpf] Ingest failed:', err);
  process.exit(1);
}
