/**
 * audit-112-profile.ts — Profile completeness audit for Monroe County May 5 2026 primary.
 *
 * Reports individual profile fields for LINKED candidates only (politician_id IS NOT NULL).
 * Stub candidates are skipped — they have no politician record to measure.
 *
 * Fields reported per candidate (per D-08 — NOT rolled-up percentage):
 *   - has_bio: Y/N (bio_text is non-null and non-empty)
 *   - contact_count: number of contact records
 *   - degree_count: number of education/degree records
 *   - experience_count: number of work/office experience records
 *
 * Output: CSV to stdout with columns: full_name,politician_id,has_bio,contact_count,degree_count,experience_count
 * Progress messages go to stderr.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/audit-112-profile.ts             # Full audit (CSV to stdout)
 *   npx tsx scripts/audit-112-profile.ts --dry-run   # Summary only, no CSV rows
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

interface ProfileRow {
  id: number;
  full_name: string;
  has_bio: 'Y' | 'N';
  contact_count: string; // pg returns numeric as string
  degree_count: string;
  experience_count: string;
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

  // Log how many stubs will be skipped
  const stubCheck = await pool.query<{ cnt: string }>(`
    SELECT COUNT(*) AS cnt
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
      AND rc.candidate_status = 'active'
      AND rc.politician_id IS NULL
  `);
  const stubCount = parseInt(stubCheck.rows[0].cnt, 10);
  console.error(`Stub candidates skipped (no politician record): ${stubCount}`);

  // 2. Query profile completeness for linked candidates only
  const result = await pool.query<ProfileRow>(`
    SELECT
      p.id,
      p.full_name,
      CASE WHEN p.bio_text IS NOT NULL AND p.bio_text != '' THEN 'Y' ELSE 'N' END AS has_bio,
      COUNT(DISTINCT pc.id) AS contact_count,
      COUNT(DISTINCT d.id) AS degree_count,
      COUNT(DISTINCT ex.id) AS experience_count
    FROM essentials.race_candidates rc
    JOIN essentials.politicians p ON p.id = rc.politician_id
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN essentials.politician_contacts pc ON pc.politician_id = p.id
    LEFT JOIN essentials.degrees d ON d.politician_id = p.id
    LEFT JOIN essentials.experiences ex ON ex.politician_id = p.id
    WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
      AND rc.candidate_status = 'active'
      AND rc.politician_id IS NOT NULL
    GROUP BY p.id, p.full_name, p.bio_text
    ORDER BY p.full_name
  `);

  const rows = result.rows;
  const linkedCount = rows.length;
  const withBio = rows.filter((r) => r.has_bio === 'Y').length;
  const withContacts = rows.filter((r) => parseInt(r.contact_count, 10) > 0).length;
  const withDegrees = rows.filter((r) => parseInt(r.degree_count, 10) > 0).length;
  const withExperiences = rows.filter((r) => parseInt(r.experience_count, 10) > 0).length;

  if (DRY_RUN) {
    console.error(`Linked candidates: ${linkedCount}`);
    console.error(`With bio: ${withBio}/${linkedCount}`);
    console.error(`With contacts: ${withContacts}/${linkedCount}`);
    console.error(`With education: ${withDegrees}/${linkedCount}`);
    console.error(`With experience: ${withExperiences}/${linkedCount}`);
    await pool.end();
    return;
  }

  // CSV header
  process.stdout.write('full_name,politician_id,has_bio,contact_count,degree_count,experience_count\n');

  // 3. Output CSV rows
  for (const row of rows) {
    // Escape name for CSV (handle commas)
    const escapedName = `"${row.full_name.replace(/"/g, '""')}"`;

    process.stdout.write(
      `${escapedName},${row.id},${row.has_bio},${row.contact_count},${row.degree_count},${row.experience_count}\n`
    );
  }

  // 4. Summary to stderr
  console.error(`Linked candidates: ${linkedCount}`);
  console.error(`With bio: ${withBio}/${linkedCount}`);
  console.error(`With contacts: ${withContacts}/${linkedCount}`);
  console.error(`With education: ${withDegrees}/${linkedCount}`);
  console.error(`With experience: ${withExperiences}/${linkedCount}`);

  await pool.end();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});
