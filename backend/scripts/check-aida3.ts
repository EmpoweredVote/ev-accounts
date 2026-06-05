import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// Check notes column type
const noteType = await pool.query(`
  SELECT column_name, data_type, udt_name
  FROM information_schema.columns
  WHERE table_schema='essentials' AND table_name='politicians' AND column_name='notes'
`);
console.log('notes column type:', JSON.stringify(noteType.rows, null, 2));

// Check what UPCOMING_ELECTIONS_LATERAL returns for Aida
const polId = '0f6484bd-2fc1-4071-9648-d7b8a950d29c';
const lateral = await pool.query(`
  SELECT
    MIN(CASE WHEN e.election_type = 'primary' THEN e.election_date END)::text AS next_primary_date,
    MIN(CASE WHEN e.election_type = 'general' THEN e.election_date END)::text AS next_general_date
  FROM essentials.elections e
  JOIN essentials.races r ON r.election_id = e.id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = $1
  LEFT JOIN essentials.offices o ON o.politician_id = $1
  WHERE e.election_date >= CURRENT_DATE
    AND (r.office_id = o.id OR (rc.politician_id IS NOT NULL AND rc.candidate_status = 'active'))
`, [polId]);
console.log('LATERAL result:', JSON.stringify(lateral.rows, null, 2));

await pool.end();
