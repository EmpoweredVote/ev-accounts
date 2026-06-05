import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const polId = '0f6484bd-2fc1-4071-9648-d7b8a950d29c';

// Full politician record
const pol = await pool.query(`SELECT * FROM essentials.politicians WHERE id = $1`, [polId]);
console.log('politician:', JSON.stringify(pol.rows, null, 2));

// What does the /essentials/politicians/:id endpoint return?
// Check essentialsPoliticianService
const office = await pool.query(`
  SELECT o.*, d.district_type, d.geo_id, d.label, d.state
  FROM essentials.offices o
  LEFT JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.politician_id = $1
  LIMIT 5
`, [polId]);
console.log('offices:', JSON.stringify(office.rows, null, 2));

// Check election associations
const rcId = '688dd4cd-8b75-4935-96a4-e0aec5b345f8';
const rc = await pool.query(`
  SELECT rc.*, r.position_name, e.election_date, e.election_type
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE rc.id = $1
`, [rcId]);
console.log('full race_candidate:', JSON.stringify(rc.rows, null, 2));

await pool.end();
