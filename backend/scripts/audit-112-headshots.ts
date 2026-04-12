/**
 * audit-112-headshots.ts — Headshot coverage audit for Monroe County May 5 2026 primary.
 *
 * Classifies photo source for each candidate as:
 *   - cdn: politician_images record exists with a URL (hosted on Supabase Storage)
 *   - local: race_candidates.photo_url is set (local/scraped URL)
 *   - none: no photo in either location
 *
 * No HTTP checks are performed — classification is DB-only.
 *
 * Output: CSV to stdout with columns: full_name,politician_id,is_linked,photo_source,cdn_url,stub_photo_url
 * Progress messages go to stderr.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/audit-112-headshots.ts             # Full audit (CSV to stdout)
 *   npx tsx scripts/audit-112-headshots.ts --dry-run   # Summary only, no CSV rows
 */

import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const DRY_RUN = process.argv.includes('--dry-run');

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface HeadshotRow {
  full_name: string;
  politician_id: number | null;
  is_linked: 'linked' | 'stub';
  cdn_photo: string | null;
  stub_photo: string | null;
  photo_source: 'cdn' | 'local' | 'none';
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  // 1. Election validation
  const electionCheck = await pool.query<{ cnt: string }>(
    `SELECT COUNT(*) AS cnt FROM essentials.elections WHERE election_date = '2026-05-05' AND state = 'IN'`
  );
  const electionCount = parseInt(electionCheck.rows[0].cnt, 10);
  console.error(`Elections found for 2026-05-05 IN: ${electionCount}`);
  if (electionCount === 0) {
    console.error('ERROR: No election found for 2026-05-05 IN. Aborting.');
    await pool.end();
    process.exit(1);
  }

  // 2. Query headshot coverage per candidate
  const result = await pool.query<HeadshotRow>(`
    SELECT
      rc.full_name,
      rc.politician_id,
      CASE WHEN rc.politician_id IS NOT NULL THEN 'linked' ELSE 'stub' END AS is_linked,
      pi.url AS cdn_photo,
      rc.photo_url AS stub_photo,
      CASE
        WHEN pi.url IS NOT NULL THEN 'cdn'
        WHEN rc.photo_url IS NOT NULL THEN 'local'
        ELSE 'none'
      END AS photo_source
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN essentials.politician_images pi
      ON pi.politician_id = rc.politician_id AND pi.type = 'default'
    WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
      AND rc.candidate_status = 'active'
    ORDER BY rc.full_name
  `);

  const rows = result.rows;
  const cdnCount = rows.filter((r) => r.photo_source === 'cdn').length;
  const localCount = rows.filter((r) => r.photo_source === 'local').length;
  const noneCount = rows.filter((r) => r.photo_source === 'none').length;

  if (DRY_RUN) {
    console.error(`Total candidates: ${rows.length}`);
    console.error(`CDN photos: ${cdnCount}`);
    console.error(`Local photos: ${localCount}`);
    console.error(`No photo: ${noneCount}`);
    console.error(`Photos: ${cdnCount} cdn, ${localCount} local, ${noneCount} none (of ${rows.length} total candidates)`);
    await pool.end();
    return;
  }

  // CSV header
  process.stdout.write('full_name,politician_id,is_linked,photo_source,cdn_url,stub_photo_url\n');

  // 3. Output CSV rows
  for (const row of rows) {
    // Escape name for CSV (handle commas)
    const escapedName = `"${row.full_name.replace(/"/g, '""')}"`;
    const politicianId = row.politician_id ?? '';
    const cdnUrl = row.cdn_photo ?? '';
    const stubPhotoUrl = row.stub_photo ?? '';

    process.stdout.write(
      `${escapedName},${politicianId},${row.is_linked},${row.photo_source},${cdnUrl},${stubPhotoUrl}\n`
    );
  }

  // 4. Summary to stderr
  console.error(`Photos: ${cdnCount} cdn, ${localCount} local, ${noneCount} none (of ${rows.length} total candidates)`);

  await pool.end();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});
