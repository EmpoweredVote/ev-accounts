/**
 * audit-112-stances.ts — Compass stance coverage audit for Monroe County May 5 2026 primary.
 *
 * Reports stance coverage as a ratio (answered_topic_count / live_topic_count) per candidate.
 * Stub candidates (no politician record) are labeled "stub" — stance data is not applicable to them.
 *
 * Output: CSV to stdout with columns: full_name,politician_id,is_linked,live_topic_count,answered_topic_count,pct
 * Progress messages go to stderr.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/audit-112-stances.ts             # Full audit (CSV to stdout)
 *   npx tsx scripts/audit-112-stances.ts --dry-run   # Summary only, no CSV rows
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

interface StanceRow {
  full_name: string;
  politician_id: number | null;
  is_linked: 'linked' | 'stub';
  answered_topic_count: string; // pg returns numeric as string
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

  // 2. Get total live topic count
  const topicCountResult = await pool.query<{ cnt: string }>(
    `SELECT COUNT(*) AS cnt FROM inform.compass_topics WHERE is_live = true`
  );
  const liveTopicCount = parseInt(topicCountResult.rows[0].cnt, 10);
  console.error(`Live compass topics: ${liveTopicCount}`);

  // 3. Query stance coverage per candidate
  const result = await pool.query<StanceRow>(`
    SELECT
      rc.full_name,
      rc.politician_id,
      CASE WHEN rc.politician_id IS NOT NULL THEN 'linked' ELSE 'stub' END AS is_linked,
      COUNT(DISTINCT pa.topic_id) AS answered_topic_count
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN inform.politician_answers pa ON pa.politician_id = rc.politician_id
    LEFT JOIN inform.compass_topics ct ON ct.id = pa.topic_id AND ct.is_live = true
    WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
      AND rc.candidate_status = 'active'
    GROUP BY rc.full_name, rc.politician_id
    ORDER BY answered_topic_count DESC, rc.full_name
  `);

  const rows = result.rows;
  const linkedRows = rows.filter((r) => r.politician_id !== null);
  const stubRows = rows.filter((r) => r.politician_id === null);
  const rowsWithStances = linkedRows.filter((r) => parseInt(r.answered_topic_count, 10) > 0);

  if (DRY_RUN) {
    console.error(`Total candidates: ${rows.length}`);
    console.error(`Linked (has politician record): ${linkedRows.length}`);
    console.error(`Stubs (no politician record): ${stubRows.length}`);
    console.error(`Linked candidates with any stances: ${rowsWithStances.length}`);
    console.error(`Candidates with stances: ${rowsWithStances.length}/${linkedRows.length} linked, Stubs (no politician record): ${stubRows.length}`);
    await pool.end();
    return;
  }

  // CSV header
  process.stdout.write('full_name,politician_id,is_linked,live_topic_count,answered_topic_count,pct\n');

  // 4. Output CSV rows
  for (const row of rows) {
    const answered = parseInt(row.answered_topic_count, 10);
    const isLinked = row.politician_id !== null;

    // Escape name for CSV (handle commas)
    const escapedName = `"${row.full_name.replace(/"/g, '""')}"`;
    const politicianId = row.politician_id ?? '';
    const liveCount = isLinked ? liveTopicCount : '';
    const answeredCount = isLinked ? answered : 0;
    const pct = isLinked
      ? (liveTopicCount > 0 ? (answered / liveTopicCount * 100).toFixed(1) : '0.0')
      : 'N/A';

    process.stdout.write(
      `${escapedName},${politicianId},${row.is_linked},${liveCount},${answeredCount},${pct}\n`
    );
  }

  // 5. Summary to stderr
  console.error(`Candidates with stances: ${rowsWithStances.length}/${linkedRows.length} linked, Stubs (no politician record): ${stubRows.length}`);

  await pool.end();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});
