/**
 * Trigger la_socrata ingest for all confirmed sources.
 * One-shot script — does not seed any new sources, just ingests.
 * Usage: npx tsx scripts/run-la-socrata-ingest.ts
 */
import 'dotenv/config';
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

console.log('[run-la-socrata-ingest] Starting la_socrata ingest for all confirmed sources...');

try {
  await runAdapterForAll('la_socrata');
  console.log('[run-la-socrata-ingest] Ingest complete.');
} catch (err) {
  console.error('[run-la-socrata-ingest] Ingest failed:', err);
  process.exit(1);
}
