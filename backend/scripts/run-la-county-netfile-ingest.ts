/**
 * run-la-county-netfile-ingest.ts
 *
 * One-shot trigger for LA County Netfile ingest.
 * Calls runAdapterForAll('la_county_netfile') which iterates all confirmed
 * politician_sources rows for source_system='la_county_netfile' and runs
 * the REST-based netfileAdapter for each.
 *
 * Run: cd C:/EV-Accounts/backend && npx tsx scripts/run-la-county-netfile-ingest.ts
 */

import 'dotenv/config';
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';
import { pool } from '../src/lib/db.js';

async function main() {
  console.log('[run-la-county-netfile-ingest] starting...');
  await runAdapterForAll('la_county_netfile');
  console.log('[run-la-county-netfile-ingest] done.');
}

main()
  .catch((err) => {
    console.error('[run-la-county-netfile-ingest] FATAL:', err);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
