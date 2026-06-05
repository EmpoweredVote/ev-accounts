import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// Check all schemas for compass tables
const allCompass = await pool.query(`
  SELECT table_schema, table_name FROM information_schema.tables
  WHERE table_name ILIKE '%compass%' OR table_name ILIKE '%stance%' OR table_name ILIKE '%topic%'
  ORDER BY table_schema, table_name
`);
console.log('All compass/stance/topic tables:', JSON.stringify(allCompass.rows, null, 2));

// Check Faizah's race/candidate entries
const faizahId = 'a9882d8b-b20d-4b0c-b509-c2883b4352e0';
const races = await pool.query(`
  SELECT rc.id, rc.politician_id, rc.race_id, r.name, r.office_name, r.district_type,
         r.geo_id, r.election_date
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  WHERE rc.politician_id = $1
`, [faizahId]);
console.log('Faizah race entries:', JSON.stringify(races.rows, null, 2));

await pool.end();
