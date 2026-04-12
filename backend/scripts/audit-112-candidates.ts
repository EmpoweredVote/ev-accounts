/**
 * audit-112-candidates.ts — Audit candidate linkage for Monroe County May 5, 2026 primary.
 *
 * Reports linked vs stub candidates per race. A stub candidate has no linked
 * politician record (race_candidates.politician_id IS NULL). This distinction
 * is critical: stubs are not "politicians with missing data" — they are
 * unlinked entries where stance/quote/profile data is not applicable.
 *
 * Output: CSV to stdout with columns: position_name,primary_party,total_candidates,linked_to_politician,stub_candidates
 * Progress messages go to stderr.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/audit-112-candidates.ts             # Full CSV report
 *   npx tsx scripts/audit-112-candidates.ts --dry-run   # Summary counts only
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
  id: string;
  name: string;
}

interface CandidateRow {
  position_name: string;
  primary_party: string | null;
  total_candidates: string;
  linked_to_politician: string;
  stub_candidates: string;
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
  // Step 1: Validate election exists (same pattern as audit-112-races.ts)
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

  // Step 2: Query candidate linkage per race
  const candidateResult = await pool.query<CandidateRow>(`
    SELECT
      r.position_name,
      r.primary_party,
      COUNT(rc.id) AS total_candidates,
      COUNT(rc.politician_id) AS linked_to_politician,
      COUNT(CASE WHEN rc.politician_id IS NULL THEN 1 END) AS stub_candidates
    FROM essentials.races r
    LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
      AND rc.candidate_status = 'active'
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
    GROUP BY r.id, r.position_name, r.primary_party
    ORDER BY r.position_name, r.primary_party
  `);

  const rows = candidateResult.rows;

  // Aggregate summary counts
  const totalRaces = rows.length;
  const totalCandidates = rows.reduce((sum, r) => sum + parseInt(r.total_candidates, 10), 0);
  const totalLinked = rows.reduce((sum, r) => sum + parseInt(r.linked_to_politician, 10), 0);
  const totalStubs = rows.reduce((sum, r) => sum + parseInt(r.stub_candidates, 10), 0);
  const racesWithZeroCandidates = rows.filter((r) => parseInt(r.total_candidates, 10) === 0).length;

  console.error(`Total races: ${totalRaces}`);
  console.error(`Total candidates: ${totalCandidates} (linked: ${totalLinked}, stubs: ${totalStubs})`);
  console.error(`Races with zero candidates: ${racesWithZeroCandidates}`);

  // Step 3: Dry-run exits here
  if (DRY_RUN) {
    console.log(`Elections found: ${elections.length}`);
    console.log(`Total races: ${totalRaces}`);
    console.log(`Total candidates: ${totalCandidates}`);
    console.log(`  Linked to politician: ${totalLinked}`);
    console.log(`  Stub candidates (no politician link): ${totalStubs}`);
    console.log(`Races with zero candidates: ${racesWithZeroCandidates}`);
    await pool.end();
    return;
  }

  // Step 4: Write CSV to stdout
  process.stdout.write('position_name,primary_party,total_candidates,linked_to_politician,stub_candidates\n');

  for (const row of rows) {
    const line = [
      escapeCsv(row.position_name),
      escapeCsv(row.primary_party),
      escapeCsv(row.total_candidates),
      escapeCsv(row.linked_to_politician),
      escapeCsv(row.stub_candidates),
    ].join(',');
    process.stdout.write(line + '\n');
  }

  console.error('Candidate linkage audit complete.');
  await pool.end();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});
