/**
 * write-la-county-city-finance-summary.ts — write essentials.politicians.finance_summary for LA County city
 * officials from their confirmed own la_county_netfile committees. All rules live in
 * scripts/lib/localFinanceSummary.ts: own committees only, raised = gross, returned contributions as
 * total_refunded, stale summaries cleared.
 *
 * Usage:
 *   cd backend && npx tsx scripts/write-la-county-city-finance-summary.ts [--dry-run]
 *
 * Requires DATABASE_URL (backend/.env). Idempotent: re-running writes only what changed.
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { runLocalFinanceSummary } from './lib/localFinanceSummary.js';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

runLocalFinanceSummary({ sourceSystem: 'la_county_netfile', label: 'LA_COUNTY_NETFILE' }, process.argv.includes('--dry-run'))
  .then(() => pool.end())
  .catch(async (err) => {
    console.error('[write-la-county-city-finance-summary] Fatal:', err);
    await pool.end();
    process.exit(1);
  });
