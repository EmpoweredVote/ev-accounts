/**
 * run-fec-auto-match-batched.ts — drain the unmatched-federal queue in batches.
 *
 * Why batched: the FEC free API key allows 1,000 requests/hour and
 * searchFecCandidates() has no 429 retry. runFecAutoMatch({limit}) processes a
 * bounded chunk; because getUnmatchedFederalPoliticians only returns politicians
 * WITHOUT an fec source, successive calls drain the queue. We checkpoint after
 * each batch and abort early if a batch only produces errors (rate-limit / network),
 * so a resume next hour picks up exactly where we stopped.
 *
 * Usage: tsx scripts/run-fec-auto-match-batched.ts [batchSize] [maxBatches]
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { getUnmatchedFederalPoliticians, runFecAutoMatch } from '../src/lib/fecResearch.js';

const BATCH_SIZE = parseInt(process.argv[2] ?? '120', 10);
const MAX_BATCHES = parseInt(process.argv[3] ?? '6', 10);
const SLEEP_BETWEEN_BATCHES_MS = 15_000;

const sleep = (ms: number): Promise<void> => new Promise(r => setTimeout(r, ms));

async function main() {
  if (!process.env.FEC_API_KEY) {
    console.error('ERROR: FEC_API_KEY is not set');
    process.exit(1);
  }
  if (!process.env.DATABASE_URL) {
    console.error('ERROR: DATABASE_URL is not set');
    process.exit(1);
  }

  console.log(`[batched] batchSize=${BATCH_SIZE} maxBatches=${MAX_BATCHES}`);

  const totals = { processed: 0, auto_confirmed: 0, needs_review: 0, errors: 0 };

  for (let batch = 1; batch <= MAX_BATCHES; batch++) {
    const startMs = Date.now();
    const summary = await runFecAutoMatch({ limit: BATCH_SIZE });
    const dur = ((Date.now() - startMs) / 1000).toFixed(0);

    totals.processed += summary.processed;
    totals.auto_confirmed += summary.auto_confirmed;
    totals.needs_review += summary.needs_review;
    totals.errors += summary.errors;

    console.log(
      `[batched] batch ${batch}: processed=${summary.processed} ` +
      `confirmed=${summary.auto_confirmed} needs_review=${summary.needs_review} ` +
      `errors=${summary.errors} (${dur}s)`
    );

    // Queue drained — nothing left to match.
    if (summary.processed === 0) {
      console.log('[batched] queue empty — done.');
      break;
    }

    // A batch that produced ONLY errors (no confirmed, no needs_review rows written)
    // means every FEC call failed — almost always rate-limiting or a network fault.
    // Those politicians got no source row, so they stay in the queue; bail and resume
    // next hour rather than spin the remaining batches into the same wall.
    if (summary.errors === summary.processed && summary.processed > 0) {
      console.warn(
        '[batched] batch produced only errors (likely FEC rate-limit). ' +
        'Stopping — re-run this script later to resume the remainder.'
      );
      break;
    }

    if (batch < MAX_BATCHES) await sleep(SLEEP_BETWEEN_BATCHES_MS);
  }

  // Report how many federal politicians still have no fec source. Ask the queue
  // itself rather than re-deriving it, so this count cannot drift from what
  // runFecAutoMatch actually drains (ADR 0002 phase 5 dropped the column the old
  // copy of this query joined on).
  const remaining = (await getUnmatchedFederalPoliticians()).length;

  console.log('\n=== BATCHED AUTO-MATCH TOTALS ===');
  console.log(JSON.stringify(totals, null, 2));
  console.log(`Federal politicians still unmatched: ${remaining}`);

  await pool.end();
  process.exit(0);
}

main().catch(err => {
  console.error('[batched] Fatal error:', err);
  process.exit(1);
});
