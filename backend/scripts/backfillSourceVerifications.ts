// ev-accounts/backend/scripts/backfillSourceVerifications.ts
/**
 * Seed public.source_verifications from existing data.
 *
 * Walks every compass stance (inform.politician_context rows with non-empty sources[])
 * and every read-rank quote (essentials.quotes with non-null source_url), inserting
 * one verification row per URL with status='unverified'.
 *
 * Idempotent: uses ON CONFLICT DO NOTHING on the unique partial indexes.
 *
 * Usage:
 *   npx tsx scripts/backfillSourceVerifications.ts --dry-run
 *   npx tsx scripts/backfillSourceVerifications.ts
 */

import { pool } from '../src/lib/db.js';

const dryRun = process.argv.includes('--dry-run');

async function main() {
  console.log(`[backfill] mode: ${dryRun ? 'DRY-RUN' : 'WRITE'}`);

  // ---- Compass stances ----
  const { rows: compassRows } = await pool.query<{
    politician_id: string;
    topic_id: string;
    sources: string[] | null;
  }>(
    `SELECT politician_id, topic_id, sources
     FROM inform.politician_context
     WHERE sources IS NOT NULL AND array_length(sources, 1) > 0`
  );
  console.log(`[backfill] compass rows: ${compassRows.length}`);

  let compassInserted = 0;
  let compassSkipped = 0;
  for (const r of compassRows) {
    for (let i = 0; i < (r.sources ?? []).length; i++) {
      const url = (r.sources ?? [])[i];
      if (!url || url.trim() === '') { compassSkipped++; continue; }
      if (dryRun) { compassInserted++; continue; }
      await pool.query(
        `
        INSERT INTO public.source_verifications
          (entity_type, politician_id, topic_id, url_index, url, status)
        VALUES ('compass_stance', $1, $2, $3, $4, 'unverified')
        ON CONFLICT DO NOTHING
        `,
        [r.politician_id, r.topic_id, i, url.trim()]
      );
      compassInserted++;
    }
  }

  // ---- Read-rank quotes ----
  const { rows: quoteRows } = await pool.query<{
    id: string;
    politician_id: string;
    source_url: string | null;
  }>(
    `SELECT id, politician_id, source_url
     FROM essentials.quotes
     WHERE source_url IS NOT NULL AND source_url <> ''`
  );
  console.log(`[backfill] readrank rows: ${quoteRows.length}`);

  let quoteInserted = 0;
  for (const q of quoteRows) {
    if (dryRun) { quoteInserted++; continue; }
    await pool.query(
      `
      INSERT INTO public.source_verifications
        (entity_type, politician_id, quote_id, url_index, url, status)
      VALUES ('readrank_quote', $1, $2, 0, $3, 'unverified')
      ON CONFLICT DO NOTHING
      `,
      [q.politician_id, q.id, q.source_url!.trim()]
    );
    quoteInserted++;
  }

  console.log(`[backfill] done.`);
  console.log(`  compass: ${compassInserted} urls queued, ${compassSkipped} empty skipped`);
  console.log(`  readrank: ${quoteInserted} urls queued`);

  await pool.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
