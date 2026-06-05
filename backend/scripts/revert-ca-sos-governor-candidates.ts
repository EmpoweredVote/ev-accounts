/**
 * revert-ca-sos-governor-candidates.ts
 *
 * Removes CA SoS long-tail candidates from the CA Governor race.
 *
 * Background: Quick-017 (2026-04-13) loaded all certified CA SoS filers for the
 * CA Governor race, which includes ~54 obscure candidates beyond the 9 prominent
 * Calmatters-tracked ones. This produced an unusable UX on the Elections page.
 *
 * What this script does:
 *   DELETE from essentials.race_candidates
 *   WHERE race = 'CA Governor' (2026 LA County Primary)
 *     AND source = 'ca-sos-2026'
 *
 * What this script preserves:
 *   - source = 'calmatters-2026' candidates (Becerra, Bianco, Hilton, Mahan, Porter,
 *     Steyer, Thurmond, Villaraigosa, Yee)
 *   - Eric Swalwell (source = 'calmatters-2026', candidate_status = 'withdrawn')
 *   - All other races — only CA Governor is touched
 *
 * Usage:
 *   npx tsx scripts/revert-ca-sos-governor-candidates.ts          # dry-run (default)
 *   npx tsx scripts/revert-ca-sos-governor-candidates.ts --commit  # write to DB
 */

import 'dotenv/config';
import path from 'path';
import { fileURLToPath } from 'url';
import { Pool } from 'pg';
import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const args = process.argv.slice(2);
const isCommit = args.includes('--commit');
const isDryRun = !isCommit;

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set. Add it to backend/.env');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function main() {
  console.log(`Mode: ${isDryRun ? 'DRY RUN (pass --commit to write)' : 'COMMIT — writing to DB'}\n`);

  const client = await pool.connect();
  try {
    // 1. Find election
    const electionResult = await client.query<{ id: string }>(
      `SELECT id FROM essentials.elections WHERE name = $1`,
      ['2026 LA County Primary']
    );
    if (electionResult.rows.length === 0) {
      throw new Error("Election '2026 LA County Primary' not found.");
    }
    const electionId = electionResult.rows[0].id;
    console.log(`Election: 2026 LA County Primary (${electionId})`);

    // 2. Find CA Governor race
    const raceResult = await client.query<{ id: string }>(
      `SELECT id FROM essentials.races
       WHERE election_id = $1 AND position_name = $2 AND primary_party IS NULL`,
      [electionId, 'CA Governor']
    );
    if (raceResult.rows.length === 0) {
      throw new Error("Race 'CA Governor' not found in 2026 LA County Primary.");
    }
    const raceId = raceResult.rows[0].id;
    console.log(`Race: CA Governor (${raceId})\n`);

    // 3. Preview: list what would be deleted
    const previewResult = await client.query<{ full_name: string; source: string; candidate_status: string }>(
      `SELECT full_name, source, candidate_status
       FROM essentials.race_candidates
       WHERE race_id = $1 AND source = 'ca-sos-2026'
       ORDER BY full_name`,
      [raceId]
    );
    console.log(`Candidates to remove (source = 'ca-sos-2026'): ${previewResult.rows.length}`);
    for (const row of previewResult.rows) {
      console.log(`  - ${row.full_name} [${row.candidate_status}]`);
    }

    // 4. Preview: list what would be kept
    const keepResult = await client.query<{ full_name: string; source: string; candidate_status: string }>(
      `SELECT full_name, source, candidate_status
       FROM essentials.race_candidates
       WHERE race_id = $1 AND source != 'ca-sos-2026'
       ORDER BY full_name`,
      [raceId]
    );
    console.log(`\nCandidates to keep (source != 'ca-sos-2026'): ${keepResult.rows.length}`);
    for (const row of keepResult.rows) {
      console.log(`  ✓ ${row.full_name} [${row.source}] [${row.candidate_status}]`);
    }

    if (isDryRun) {
      console.log('\nDRY RUN complete — no changes made. Pass --commit to execute.');
      return;
    }

    // 5. Delete ca-sos-2026 governor candidates
    const deleteResult = await client.query(
      `DELETE FROM essentials.race_candidates
       WHERE race_id = $1 AND source = 'ca-sos-2026'`,
      [raceId]
    );
    console.log(`\nDeleted ${deleteResult.rowCount} candidate(s) from CA Governor race.`);
    console.log('Done. CA Governor race now shows Calmatters-sourced candidates only.');

  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
