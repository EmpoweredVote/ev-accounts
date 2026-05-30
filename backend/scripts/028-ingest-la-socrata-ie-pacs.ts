/**
 * 028-ingest-la-socrata-ie-pacs.ts — Run Socrata ingest for all confirmed la_socrata sources.
 *
 * Runs after 028-confirm-la-socrata-ie-pacs.ts has promoted the 10 IE committee
 * rows to ie_committee/confirmed.
 *
 * NOTE: runAdapterForSources() in campaignFinanceScheduler only supports cal_access.
 * For la_socrata, the correct function is runAdapterForAll('la_socrata'), which
 * processes all confirmed la_socrata sources (candidate + ie_committee both).
 * This is idempotent — previously ingested sources are skipped by source_transaction_id
 * deduplication in runIngestion.
 *
 * Usage:
 *   npx tsx scripts/028-ingest-la-socrata-ie-pacs.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';

if (!process.env.DATABASE_URL) {
  console.error('[028-ingest] ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function main(): Promise<void> {
  const startMs = Date.now();

  // List the 10 IE sources we are ingesting
  const ieSourcesResult = await pool.query<{
    id: string;
    essentials_politician_id: string;
    external_id: string;
    notes: string;
  }>(
    `SELECT id, essentials_politician_id, external_id, notes
     FROM transparent_motivations.politician_sources
     WHERE source_system = 'la_socrata'
       AND source_type = 'ie_committee'
       AND research_status = 'confirmed'
     ORDER BY external_id, essentials_politician_id`
  );

  const ieSources = ieSourcesResult.rows;

  if (ieSources.length === 0) {
    console.error('[028-ingest] ERROR: No confirmed ie_committee la_socrata sources found. Run 028-confirm-la-socrata-ie-pacs.ts first.');
    await pool.end();
    process.exit(1);
  }

  console.log(`[028-ingest] Found ${ieSources.length} confirmed ie_committee sources to ingest:`);
  for (const s of ieSources) {
    let cmtNm = '';
    try { cmtNm = (JSON.parse(s.notes) as { cmt_nm?: string }).cmt_nm ?? ''; } catch { /* ignore */ }
    console.log(`  source=${s.id} cmt_id=${s.external_id} cmt_nm="${cmtNm}" politician=${s.essentials_politician_id}`);
  }

  // runAdapterForAll processes ALL confirmed la_socrata sources (candidate + ie_committee).
  // IE committee contributions will be linked via politician_source_id = source.id.
  // Previously ingested candidate sources are skipped by source_transaction_id dedup.
  console.log('\n[028-ingest] Running runAdapterForAll("la_socrata") ...');
  await pool.end(); // Close pool before runAdapterForAll (which uses its own pool)

  try {
    await runAdapterForAll('la_socrata');
    console.log('[028-ingest] Ingest complete.');
  } catch (err) {
    console.error('[028-ingest] Ingest failed:', err);
    process.exit(1);
  }

  const durationMs = Date.now() - startMs;
  console.log(`[028-ingest] Duration: ${(durationMs / 1000).toFixed(1)}s`);
  process.exit(0);
}

main().catch(async (err) => {
  console.error('[028-ingest] Fatal error:', err);
  process.exit(1);
});
