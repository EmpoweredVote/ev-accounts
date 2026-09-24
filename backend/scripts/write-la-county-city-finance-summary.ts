/**
 * write-la-county-city-finance-summary.ts — write essentials.politicians.finance_summary for LA County city
 * officials from their confirmed own la_county_netfile committees. All rules live in
 * src/lib/localFinanceSummary.ts: own committees only, raised = gross, returned contributions as
 * total_refunded, stale summaries cleared.
 *
 * Runs automatically after every NetFile ingest (both writers, city first). Use this for a one-off.
 *
 * Usage:
 *   cd backend && npx tsx scripts/write-la-county-city-finance-summary.ts [--dry-run]
 *
 * Requires DATABASE_URL (backend/.env). Idempotent: re-running writes only what changed.
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { runLocalFinanceSummary, LA_COUNTY_NETFILE } from '../src/lib/localFinanceSummary.js';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

runLocalFinanceSummary(LA_COUNTY_NETFILE, process.argv.includes('--dry-run'))
  .then(() => pool.end())
  .catch(async (err) => {
    console.error('[write-la-county-city-finance-summary] Fatal:', err);
    await pool.end();
    process.exit(1);
  });
