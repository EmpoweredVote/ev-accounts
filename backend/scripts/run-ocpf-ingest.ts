/**
 * Trigger OCPF ingest for all confirmed sources.
 * One-shot script — does not seed any new sources, just ingests.
 * Usage: npx tsx scripts/run-ocpf-ingest.ts
 */
import 'dotenv/config';
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

console.log('[run-ocpf-ingest] Starting OCPF ingest for all confirmed sources...');

try {
  await runAdapterForAll('ocpf');
  console.log('[run-ocpf-ingest] Ingest complete.');
} catch (err) {
  console.error('[run-ocpf-ingest] Ingest failed:', err);
  process.exit(1);
}
