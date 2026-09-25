/**
 * run-fec-finance-summary.ts — run the federal finance_summary writer by hand.
 *
 * The logic lives in src/lib/fecFinanceSummary.ts (read its header: who is summarised, which
 * committee wins, the crosswalk, the FEC calls and the shared rate limit). The same code runs on a
 * schedule as the job `fec-finance-summary` (stalest first, capped). This wrapper is for a full
 * run, a dry run, or a refresh of named people after an FEC-ID fix.
 *
 * Usage: tsx scripts/run-fec-finance-summary.ts [--dry-run] [--candidates-only] [--politician <uuid> ...]
 *   --dry-run          Resolve every FEC ID and print the plan. No FEC calls, no DB writes.
 *   --candidates-only  Only politicians whose chosen office is sought, not held.
 *   --politician <id>  Only this essentials.politicians id; repeat the flag for several. Each id must
 *                      resolve to an active federal politician the full run would summarise, or the
 *                      script exits before any FEC call.
 *
 * Requires DATABASE_URL, and FEC_API_KEY unless --dry-run. A full run is ~1,500 people and about
 * 5 hours at the shared 15/min FEC limit (2026-09-24).
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { runFecFinanceSummary } from '../src/lib/fecFinanceSummary.js';

const DRY_RUN = process.argv.includes('--dry-run');
const CANDIDATES_ONLY = process.argv.includes('--candidates-only');
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const ONLY_POLITICIANS = process.argv.flatMap((arg, i, argv) => {
  // Anything else starting --politician ("--politician=<id>", or several flags passed as one
  // argument by a shell that does not word-split) would otherwise be ignored, and a filtered run
  // would silently become a full two-hour one.
  if (arg.startsWith('--politician') && arg !== '--politician') {
    console.error(`ERROR: unrecognised argument ${JSON.stringify(arg.slice(0, 60))} — pass "--politician <uuid>" as two arguments`);
    process.exit(1);
  }
  if (arg !== '--politician') return [];
  const id = argv[i + 1];
  if (!id || !UUID_RE.test(id)) {
    console.error(`ERROR: --politician needs an essentials.politicians uuid, got ${id ?? 'nothing'}`);
    process.exit(1);
  }
  return [id.toLowerCase()];
});

runFecFinanceSummary({
  dryRun: DRY_RUN,
  candidatesOnly: CANDIDATES_ONLY,
  onlyPoliticians: ONLY_POLITICIANS,
})
  .then(async () => {
    await pool.end();
    process.exit(0);
  })
  .catch(async (err) => {
    console.error('[run-fec-finance-summary] ERROR:', err instanceof Error ? err.message : err);
    try { await pool.end(); } catch { /* ignore pool close errors on the failure path */ }
    process.exit(1);
  });
