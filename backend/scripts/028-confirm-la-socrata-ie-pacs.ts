/**
 * 028-confirm-la-socrata-ie-pacs.ts — Promote 10 LA Socrata PAC rows from
 * not_applicable to ie_committee/confirmed.
 *
 * These are 5 IE committees linked to 10 politician_sources rows:
 *   1340101 — Angelenos for Safe Transportation PAC (3 politicians)
 *   1405775 — California Apartment Association Housing Solutions Committee (1 politician)
 *   1413452 — American Federation of Teachers Solidarity Committee (1 politician)
 *   1465492 — Californians to Preserve and Protect Local Jobs (Hawaiian Gardens Casino) (4 politicians)
 *   1474094 — The Mexican & Asian American Leadership PAC (De Leon) (1 politician)
 *
 * Exclusions:
 *   - external_id = '1459184' for politician 41ef8aaa-b604-4725-b46d-dab1656cc198 (Fiona Ma false positive — remains not_applicable)
 *   - external_id = 'Pending' (Mervin Evans — invalid, no Socrata data)
 *
 * Usage:
 *   npx tsx scripts/028-confirm-la-socrata-ie-pacs.ts
 *
 * Idempotent: re-running after all 10 are confirmed updates 0 rows and exits 0.
 */

import 'dotenv/config';
import { Pool } from 'pg';

if (!process.env.DATABASE_URL) {
  console.error('[028-confirm] ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// The 5 IE committee cmt_ids to promote (stored as external_id)
const IE_CMT_IDS = ['1340101', '1465492', '1405775', '1474094', '1413452'];

// Fiona Ma false positive — exclude even if IN-list is ever broadened
const FIONA_MA_POLITICIAN_ID = '41ef8aaa-b604-4725-b46d-dab1656cc198';
const FIONA_MA_CMT_ID = '1459184';

async function main(): Promise<void> {
  const startMs = Date.now();
  console.log('[028-confirm] Starting IE PAC confirmation...');

  // Step 1: Check how many are already confirmed (idempotency check)
  const alreadyConfirmedResult = await pool.query<{ cnt: string }>(
    `SELECT COUNT(*) AS cnt
     FROM transparent_motivations.politician_sources
     WHERE source_system = 'la_socrata'
       AND source_type = 'ie_committee'
       AND research_status = 'confirmed'
       AND external_id = ANY($1::text[])`,
    [IE_CMT_IDS]
  );
  const alreadyConfirmed = Number(alreadyConfirmedResult.rows[0]?.cnt ?? 0);

  if (alreadyConfirmed === 10) {
    console.log('[028-confirm] All 10 IE PAC rows are already confirmed. Nothing to do.');
    await pool.end();
    process.exit(0);
  }

  if (alreadyConfirmed > 0) {
    console.log(`[028-confirm] ${alreadyConfirmed} rows already confirmed; updating the remaining...`);
  }

  // Step 2: Transactional UPDATE — flip not_applicable PAC rows to ie_committee/confirmed
  // Uses external_id (= cmt_id) since politician_sources has no raw_record column.
  // Explicit NOT clause guards against the Fiona Ma false positive even if IN-list changes.
  const updateResult = await pool.query<{
    id: string;
    essentials_politician_id: string;
    cmt_id: string;
    cmt_nm: string;
  }>(
    `UPDATE transparent_motivations.politician_sources
        SET source_type = 'ie_committee',
            research_status = 'confirmed',
            updated_at = NOW()
      WHERE source_system = 'la_socrata'
        AND research_status = 'not_applicable'
        AND external_id = ANY($1::text[])
        AND NOT (
              essentials_politician_id = $2
          AND external_id = $3
        )
      RETURNING id,
                essentials_politician_id,
                external_id AS cmt_id,
                notes::jsonb->>'cmt_nm' AS cmt_nm`,
    [IE_CMT_IDS, FIONA_MA_POLITICIAN_ID, FIONA_MA_CMT_ID]
  );

  const updated = updateResult.rows;
  const expectedNew = 10 - alreadyConfirmed;

  console.log(`[028-confirm] Updated ${updated.length} rows (expected ${expectedNew} new):`);
  for (const row of updated) {
    console.log(`  [CONFIRMED] id=${row.id} cmt_id=${row.cmt_id} cmt_nm="${row.cmt_nm}" politician=${row.essentials_politician_id}`);
  }

  const totalConfirmed = alreadyConfirmed + updated.length;

  if (totalConfirmed !== 10) {
    console.error(
      `[028-confirm] ERROR: Expected 10 total confirmed rows, got ${totalConfirmed}.` +
      ` alreadyConfirmed=${alreadyConfirmed}, updated=${updated.length}. Aborting.`
    );
    await pool.end();
    process.exit(1);
  }

  // Step 3: Verify Fiona Ma false positive is untouched
  const fionaResult = await pool.query<{ research_status: string; source_type: string }>(
    `SELECT research_status, source_type
     FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = $1
       AND external_id = $2
       AND source_system = 'la_socrata'`,
    [FIONA_MA_POLITICIAN_ID, FIONA_MA_CMT_ID]
  );

  if (fionaResult.rows.length > 0) {
    const fRow = fionaResult.rows[0];
    if (fRow.research_status !== 'not_applicable') {
      console.error(
        `[028-confirm] ERROR: Fiona Ma false positive was modified! research_status=${fRow.research_status}. This is wrong.`
      );
      await pool.end();
      process.exit(1);
    }
    console.log(`[028-confirm] Fiona Ma false positive verified: research_status=${fRow.research_status}, source_type=${fRow.source_type} (untouched — correct).`);
  } else {
    console.warn('[028-confirm] Fiona Ma row not found — may have been deleted previously.');
  }

  const durationMs = Date.now() - startMs;
  console.log(`\n[028-confirm] SUCCESS: 10/10 IE PAC rows confirmed. Duration: ${(durationMs / 1000).toFixed(1)}s`);

  await pool.end();
  process.exit(0);
}

main().catch(async (err) => {
  console.error('[028-confirm] Fatal error:', err);
  await pool.end();
  process.exit(1);
});
