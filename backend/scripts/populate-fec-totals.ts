/**
 * populate-fec-totals.ts — CLI for populateFecCandidateTotals (quick-032).
 *
 * Fills transparent_motivations.fec_candidate_totals (authoritative per-cycle receipts +
 * composition columns: itemized/unitemized/pac/party/self) for every confirmed FEC candidate,
 * from FEC's candidate totals endpoint. One API call per candidate (all cycles at once).
 * Resumable + idempotent — a re-run only fills candidates missing the composition columns.
 * Needs FEC_API_KEY (personal key: 1000/hr). Run as a Render one-off Job or locally.
 *
 * usage: tsx scripts/populate-fec-totals.ts
 */
import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { populateFecCandidateTotals } from '../src/lib/fecBackfill.js';

async function main(): Promise<void> {
  if (!process.env.FEC_API_KEY) { console.error('ERROR: FEC_API_KEY not set'); process.exit(1); }
  const res = await populateFecCandidateTotals();
  console.log(`[populate-fec-totals] done: candidates=${res.candidates} rows=${res.rows} failed=${res.failed}`);
  await pool.end();
  process.exit(0);
}

main().catch(async (err) => { console.error('[populate-fec-totals] Fatal:', err); try { await pool.end(); } catch { /* noop */ } process.exit(1); });
