/**
 * audit-112-races.ts — Audit race coverage for Monroe County May 5, 2026 primary.
 *
 * Reports how many races are in the DB vs how many should exist per the
 * BALLOT-BASELINE-2026-05-05.md denominator (~43 distinct race slots).
 *
 * Output: CSV to stdout with columns: position_name,primary_party,candidate_count,linked_to_geofence,office_id
 * Progress messages go to stderr.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/audit-112-races.ts             # Full CSV report
 *   npx tsx scripts/audit-112-races.ts --dry-run   # Election and race count only
 *
 * IMPORTANT: Do NOT query essentials.election_records — that is the legacy BallotReady table.
 * Only use essentials.elections + essentials.races + essentials.race_candidates.
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

interface ElectionRow {
  id: number;
  name: string;
}

interface RaceRow {
  position_name: string;
  primary_party: string | null;
  candidate_count: string;
  linked_to_geofence: string;
  office_id: number | null;
}

// ---------------------------------------------------------------------------
// CSV helpers
// ---------------------------------------------------------------------------

function escapeCsv(value: string | null | undefined): string {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  // Step 1: Validate election exists (assumption A4 from research)
  const electionResult = await pool.query<ElectionRow>(`
    SELECT id, name
    FROM essentials.elections
    WHERE election_date = '2026-05-05' AND state = 'IN'
  `);

  const elections = electionResult.rows;
  console.error(`Found ${elections.length} election(s) for 2026-05-05 IN`);

  if (elections.length === 0) {
    console.error('ERROR: No election found for election_date=2026-05-05, state=IN. Aborting.');
    await pool.end();
    process.exit(1);
  }

  if (elections.length > 1) {
    console.error(`WARNING: Found ${elections.length} elections. Continuing with all matching rows.`);
    for (const e of elections) {
      console.error(`  Election: id=${e.id}, name=${e.name}`);
    }
  } else {
    console.error(`  Election: id=${elections[0].id}, name=${elections[0].name}`);
  }

  // Step 2: Query race data
  const raceResult = await pool.query<RaceRow>(`
    SELECT
      r.position_name,
      r.primary_party,
      COUNT(rc.id) AS candidate_count,
      CASE WHEN r.office_id IS NOT NULL THEN 'Y' ELSE 'N' END AS linked_to_geofence,
      r.office_id
    FROM essentials.races r
    LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.candidate_status = 'active'
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
    GROUP BY r.id, r.position_name, r.primary_party, r.office_id
    ORDER BY r.position_name, r.primary_party
  `);

  const races = raceResult.rows;
  const linkedCount = races.filter((r) => r.linked_to_geofence === 'Y').length;
  const unlinkedCount = races.filter((r) => r.linked_to_geofence === 'N').length;

  console.error(`Total races: ${races.length}, Linked to geofence: ${linkedCount}, Unlinked: ${unlinkedCount}`);

  // Step 3: Dry-run exits here
  if (DRY_RUN) {
    console.log(`Elections found: ${elections.length}`);
    console.log(`Total races in DB for 2026-05-05 IN: ${races.length}`);
    console.log(`  Linked to geofence: ${linkedCount}`);
    console.log(`  Unlinked: ${unlinkedCount}`);
    console.log(`Expected denominator per BALLOT-BASELINE-2026-05-05.md: ~43 distinct race slots`);
    await pool.end();
    return;
  }

  // Step 4: Write CSV to stdout
  process.stdout.write('position_name,primary_party,candidate_count,linked_to_geofence,office_id\n');

  for (const row of races) {
    const line = [
      escapeCsv(row.position_name),
      escapeCsv(row.primary_party),
      escapeCsv(row.candidate_count),
      escapeCsv(row.linked_to_geofence),
      escapeCsv(row.office_id !== null ? String(row.office_id) : null),
    ].join(',');
    process.stdout.write(line + '\n');
  }

  console.error('Race audit complete.');
  await pool.end();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});
