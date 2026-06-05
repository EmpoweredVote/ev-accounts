/**
 * run-cal-access-local.mjs
 *
 * One-off script to run the Cal-Access ingest locally against the production DB.
 * Used because Render's dyno doesn't have enough RAM for the 1.5GB ZIP.
 *
 * Run from the backend directory: node --max-old-space-size=12288 run-cal-access-local.mjs
 * (Loads .env from the current directory automatically via dotenv/config)
 */

import 'dotenv/config';
import { runAdapterForAll } from './dist/lib/campaignFinanceScheduler.js';

console.log('[local-ingest] Starting Cal-Access ingest against production DB...');
console.log('[local-ingest] This will download the 1.5GB Cal-Access ZIP — estimated 10-20 minutes.');

const start = Date.now();
try {
  await runAdapterForAll('cal_access');
  const elapsed = Math.round((Date.now() - start) / 1000);
  console.log(`[local-ingest] Cal-Access ingest completed in ${elapsed}s`);
} catch (err) {
  console.error('[local-ingest] Cal-Access ingest failed:', err);
  process.exit(1);
}
