/**
 * run-fec-auto-match.ts — standalone runner for FEC candidate auto-match.
 *
 * Usage: tsx scripts/run-fec-auto-match.ts
 *
 * Requires environment variables:
 *   DATABASE_URL   — PostgreSQL connection string (in .env)
 *   FEC_API_KEY    — FEC API key (set via env or .env)
 */

import 'dotenv/config';
import { runFecAutoMatch } from '../src/lib/fecResearch.js';

async function main() {
  if (!process.env.FEC_API_KEY) {
    console.error('ERROR: FEC_API_KEY is not set');
    process.exit(1);
  }
  if (!process.env.DATABASE_URL) {
    console.error('ERROR: DATABASE_URL is not set');
    process.exit(1);
  }

  console.log('[run-fec-auto-match] Starting FEC candidate auto-match...');
  console.log(`[run-fec-auto-match] Using FEC API key: ${process.env.FEC_API_KEY?.slice(0, 8)}...`);

  const startMs = Date.now();
  const summary = await runFecAutoMatch();
  const durationMs = Date.now() - startMs;

  console.log('\n=== AUTO-MATCH SUMMARY ===');
  console.log(JSON.stringify(summary, null, 2));
  console.log(`\n[run-fec-auto-match] Completed in ${(durationMs / 1000).toFixed(1)}s`);
  console.log(`[run-fec-auto-match] Processed: ${summary.processed}`);
  console.log(`[run-fec-auto-match] Auto-confirmed: ${summary.auto_confirmed}`);
  console.log(`[run-fec-auto-match] Needs review: ${summary.needs_review}`);
  console.log(`[run-fec-auto-match] Errors: ${summary.errors}`);

  process.exit(0);
}

main().catch(err => {
  console.error('[run-fec-auto-match] Fatal error:', err);
  process.exit(1);
});
