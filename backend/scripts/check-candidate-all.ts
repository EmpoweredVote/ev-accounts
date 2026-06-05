import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const id = '688dd4cd-8b75-4935-96a4-e0aec5b345f8';

// Search in all tables that might have this ID
const searches = [
  `SELECT 'politicians' as tbl, id, full_name FROM essentials.politicians WHERE id = '${id}'`,
  `SELECT 'race_candidates' as tbl, id::text, politician_id::text FROM essentials.race_candidates WHERE id = '${id}' OR politician_id = '${id}'`,
  `SELECT 'elections' as tbl, id, name FROM essentials.elections WHERE id = '${id}'`,
  `SELECT 'races' as tbl, id::text, position_name FROM essentials.races WHERE id = '${id}'`,
  `SELECT 'candidate_staging' as tbl, id::text, full_name FROM essentials.candidate_staging WHERE id = '${id}'`,
];

for (const q of searches) {
  const r = await pool.query(q);
  if (r.rows.length > 0) console.log(r.rows);
}

// Search election_records
const erCols = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_schema='essentials' AND table_name='election_records' ORDER BY ordinal_position`);
console.log('election_records cols:', erCols.rows.map((r: any) => r.column_name));

const er = await pool.query(`SELECT * FROM essentials.election_records WHERE candidate_id = '${id}' OR id = '${id}' LIMIT 3`).catch(() => null);
if (er) console.log('election_records:', er.rows);

await pool.end();
