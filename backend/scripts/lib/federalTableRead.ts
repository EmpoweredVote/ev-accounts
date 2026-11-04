/**
 * federalTableRead.ts — read federal roll calls from essentials.legislative_votes (read only).
 *
 * One query per politician id: the table is indexed on politician_id only, so a filter on bill or vote id
 * without it times out. Each query runs inside BEGIN READ ONLY ... ROLLBACK with a 20s statement timeout.
 * Rows from every politician are grouped into roll calls by `groupRollCalls`.
 */
import type { Pool } from 'pg';
import { groupRollCalls, type TableRollCall, type TableVoteRow } from './federalTableVotes.js';

const SQL = `SELECT v.politician_id::text AS politician_id, v.external_vote_id, b.number AS bill_number,
       s.external_id AS congress, to_char(v.vote_date AT TIME ZONE 'UTC', 'YYYY-MM-DD') AS vote_date,
       v.vote_question, v.position, v.yea_count, v.nay_count
  FROM essentials.legislative_votes v
  JOIN essentials.legislative_bills b ON b.id = v.bill_id
  JOIN essentials.legislative_sessions s ON s.id = v.session_id
 WHERE v.politician_id = $1
   AND s.jurisdiction = 'federal'
   AND (s.external_id, b.number) IN (SELECT * FROM unnest($2::text[], $3::text[]))`;

/**
 * Keep only the ids whose politician has a bioguide id. Federal vote loaders link votes by bioguide only, so
 * anyone without one has no federal rows; this still covers former members now at state or local level.
 */
export async function keepBioguideIds(pool: Pool, pids: string[]): Promise<string[]> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN READ ONLY');
    try {
      await client.query("SET LOCAL statement_timeout = '20s'");
      const res = await client.query(
        'SELECT id::text AS id FROM essentials.politicians WHERE id = ANY($1::uuid[]) AND bioguide_id IS NOT NULL',
        [pids],
      );
      const keep = new Set<string>(res.rows.map((r) => r.id));
      return pids.filter((p) => keep.has(p));
    } finally {
      await client.query('ROLLBACK');
    }
  } finally {
    client.release();
  }
}

export async function readTableRollCalls(
  pool: Pool,
  pids: string[],
  bills: Array<{ congress: string; bill_number: string }>,
): Promise<TableRollCall[]> {
  const congresses = bills.map((b) => b.congress);
  const numbers = bills.map((b) => b.bill_number);
  const rows: TableVoteRow[] = [];
  const client = await pool.connect();
  try {
    for (let i = 0; i < pids.length; i++) {
      await client.query('BEGIN READ ONLY');
      try {
        await client.query("SET LOCAL statement_timeout = '20s'");
        const res = await client.query(SQL, [pids[i], congresses, numbers]);
        for (const r of res.rows) {
          rows.push({ ...r, yea_count: Number(r.yea_count), nay_count: Number(r.nay_count) });
        }
      } finally {
        await client.query('ROLLBACK');
      }
      if ((i + 1) % 50 === 0) console.log(`table: read ${i + 1} of ${pids.length} people`);
    }
  } finally {
    client.release();
  }
  return groupRollCalls(rows);
}
