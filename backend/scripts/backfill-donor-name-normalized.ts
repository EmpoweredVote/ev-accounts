/**
 * backfill-donor-name-normalized.ts — One-time backfill of donor_name_normalized column.
 *
 * Usage:
 *   npx tsx scripts/backfill-donor-name-normalized.ts --dry-run   # preview counts by source, no DB writes
 *   npx tsx scripts/backfill-donor-name-normalized.ts              # live run, updates all NULL rows
 *
 * What it does:
 *   - Dry-run: reports count of rows WHERE donor_name_normalized IS NULL, grouped by data_source.
 *   - Live-run: cursor-based batched UPDATE that normalizes donor names in SQL for all pre-existing
 *     rows that have donor_name_normalized IS NULL.
 *
 * SQL normalization note:
 *   The SQL UPDATE applies a simplified normalization pipeline using public.f_unaccent + regexp_replace.
 *   It intentionally skips the LAST,FIRST reorder step (too complex for SQL; word_similarity handles
 *   token-order variation at query time). Future re-ingestion applies full TypeScript normalization.
 *
 * Connection:
 *   Uses session-mode pooler (port 5432) — same as Plan 25-01 migration.
 *   Set DATABASE_URL to: postgresql://postgres.[project]:[password]@aws-0-us-west-1.pooler.supabase.com:5432/postgres
 */

import 'dotenv/config';
import { Pool } from 'pg';

// ─── Env guard ────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ─── Arg parsing ─────────────────────────────────────────────────────────────

const isDryRun = process.argv.includes('--dry-run');
console.log(`[backfill-donor-name-normalized] Mode: ${isDryRun ? 'DRY-RUN (no DB writes)' : 'LIVE RUN'}`);

// ─── DB Pool ─────────────────────────────────────────────────────────────────

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Constants ────────────────────────────────────────────────────────────────

const BATCH_SIZE = 2000;
const SLEEP_MS = 200;

// ─── Helpers ─────────────────────────────────────────────────────────────────

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const client = await pool.connect();

  try {
    // ── Dry-run: count NULLs by data_source ─────────────────────────────────
    if (isDryRun) {
      const { rows } = await client.query<{ data_source: string; null_count: string }>(`
        SELECT data_source, COUNT(*) AS null_count
        FROM transparent_motivations.contributions
        WHERE donor_name_normalized IS NULL
        GROUP BY data_source
        ORDER BY null_count DESC
      `);

      const totalNulls = rows.reduce((sum, r) => sum + parseInt(r.null_count, 10), 0);

      if (rows.length === 0) {
        console.log('\nNo rows with donor_name_normalized IS NULL — nothing to backfill.');
      } else {
        console.log(`\nRows with donor_name_normalized IS NULL (${totalNulls} total):`);
        for (const r of rows) {
          console.log(`  ${r.data_source.padEnd(25)} ${r.null_count.padStart(8)} rows`);
        }
      }

      console.log('\nDRY-RUN complete — no database writes made.');
      return;
    }

    // ── Live-run: cursor-based batched UPDATE ────────────────────────────────
    // UUID cursor — start before the minimum possible UUID (all zeros)
    let lastId = '00000000-0000-0000-0000-000000000000';
    let totalUpdated = 0;
    let batchNum = 0;

    for (;;) {
      batchNum++;

      const { rows } = await client.query<{ id: string }>(`
        WITH batch AS (
          SELECT id, data_source, raw_record FROM transparent_motivations.contributions
          WHERE id > $1::uuid AND donor_name_normalized IS NULL
          ORDER BY id LIMIT $2
        )
        UPDATE transparent_motivations.contributions c
        SET donor_name_normalized = public.f_unaccent(lower(trim(regexp_replace(
          regexp_replace(
            regexp_replace(
              CASE b.data_source
                WHEN 'fec' THEN
                  COALESCE(NULLIF(trim(b.raw_record->>'contributor_name'), ''), 'anonymous')
                WHEN 'indiana' THEN
                  COALESCE(NULLIF(trim(b.raw_record->>'ContributorName'), ''), 'anonymous')
                WHEN 'cal_access' THEN
                  COALESCE(NULLIF(trim(
                    COALESCE(NULLIF(trim(b.raw_record->>'CTRIB_NAML'), ''), '') || ' ' ||
                    COALESCE(NULLIF(trim(b.raw_record->>'CTRIB_NAMF'), ''), '')
                  ), ''), 'anonymous')
                WHEN 'la_socrata' THEN
                  COALESCE(NULLIF(trim(b.raw_record->>'con_name'), ''), 'anonymous')
                WHEN 'la_county_netfile' THEN
                  COALESCE(NULLIF(trim(
                    COALESCE(NULLIF(trim(b.raw_record->>'Tran_NamL'), ''), '') || ' ' ||
                    COALESCE(NULLIF(trim(b.raw_record->>'Tran_NamF'), ''), '')
                  ), ''), 'anonymous')
                ELSE 'anonymous'
              END,
              's+', ' ', 'g'
            ),
            '.', '', 'g'
          ),
          '-', ' ', 'g'
        ))))
        FROM batch b
        WHERE c.id = b.id
        RETURNING c.id
      `, [lastId, BATCH_SIZE]);

      const batchCount = rows.length;

      if (batchCount === 0) {
        console.log(`[backfill] Batch ${batchNum}: 0 rows — done.`);
        break;
      }

      // Advance cursor to the max UUID in this batch (UUID string sort is valid for v4 UUIDs)
      const maxId = rows.reduce((max, r) => (r.id > max ? r.id : max), '00000000-0000-0000-0000-000000000000');
      lastId = maxId;
      totalUpdated += batchCount;

      console.log(`[backfill] Batch ${batchNum}: Updated ${batchCount} rows (total: ${totalUpdated}, cursor: ${lastId})`);

      await sleep(SLEEP_MS);
    }

    // ── Completion verification ───────────────────────────────────────────────
    const { rows: nullCheck } = await client.query<{ remaining: string }>(`
      SELECT COUNT(*) AS remaining
      FROM transparent_motivations.contributions
      WHERE donor_name_normalized IS NULL
    `);

    const remaining = parseInt(nullCheck[0]?.remaining ?? '0', 10);

    console.log(`\n── Backfill complete ────────────────────────────────────`);
    console.log(`  Total rows updated:    ${totalUpdated}`);
    console.log(`  NULL rows remaining:   ${remaining}`);

    if (remaining > 0) {
      console.error(`ERROR: ${remaining} rows still have donor_name_normalized IS NULL — backfill incomplete!`);
      process.exit(1);
    } else {
      console.log('  Verification passed: zero NULL rows remain.');
    }

  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
