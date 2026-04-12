/**
 * audit-112-quotes.ts — Read & Rank quote coverage audit for Monroe County May 5 2026 primary.
 *
 * Reports quote coverage as a count per candidate (not binary).
 * Stub candidates (no politician record) are labeled "stub" — quote data is not applicable to them.
 *
 * Output: CSV to stdout with columns: full_name,politician_id,is_linked,quote_count
 * Progress messages go to stderr.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/audit-112-quotes.ts             # Full audit (CSV to stdout)
 *   npx tsx scripts/audit-112-quotes.ts --dry-run   # Summary only, no CSV rows
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

interface QuoteRow {
  full_name: string;
  politician_id: number | null;
  is_linked: 'linked' | 'stub';
  quote_count: string; // pg returns numeric as string
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

  // 2. Query quote coverage per candidate
  const result = await pool.query<QuoteRow>(`
    SELECT
      rc.full_name,
      rc.politician_id,
      CASE WHEN rc.politician_id IS NOT NULL THEN 'linked' ELSE 'stub' END AS is_linked,
      COUNT(q.id) AS quote_count
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN essentials.quotes q ON q.politician_id = rc.politician_id
    WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
      AND rc.candidate_status = 'active'
    GROUP BY rc.full_name, rc.politician_id
    ORDER BY quote_count DESC, rc.full_name
  `);

  const rows = result.rows;
  const linkedRows = rows.filter((r) => r.politician_id !== null);
  const stubRows = rows.filter((r) => r.politician_id === null);
  const rowsWithQuotes = linkedRows.filter((r) => parseInt(r.quote_count, 10) > 0);

  if (DRY_RUN) {
    console.error(`Total candidates: ${rows.length}`);
    console.error(`Linked (has politician record): ${linkedRows.length}`);
    console.error(`Stubs (no politician record): ${stubRows.length}`);
    console.error(`Linked candidates with any quotes: ${rowsWithQuotes.length}`);
    console.error(`Candidates with quotes: ${rowsWithQuotes.length}/${linkedRows.length} linked, Stubs: ${stubRows.length}`);
    await pool.end();
    return;
  }

  // CSV header
  process.stdout.write('full_name,politician_id,is_linked,quote_count\n');

  // 3. Output CSV rows (stubs get quote_count=0)
  for (const row of rows) {
    const quoteCount = parseInt(row.quote_count, 10);

    // Escape name for CSV (handle commas)
    const escapedName = `"${row.full_name.replace(/"/g, '""')}"`;
    const politicianId = row.politician_id ?? '';

    process.stdout.write(
      `${escapedName},${politicianId},${row.is_linked},${quoteCount}\n`
    );
  }

  // 4. Summary to stderr
  console.error(`Candidates with quotes: ${rowsWithQuotes.length}/${linkedRows.length} linked, Stubs: ${stubRows.length}`);

  await pool.end();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});
