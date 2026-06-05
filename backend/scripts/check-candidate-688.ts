import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const id = '688dd4cd-8b75-4935-96a4-e0aec5b345f8';

const pol = await pool.query(`
  SELECT p.id, p.full_name, p.slug, p.is_active, p.office_id,
         o.title, d.district_type, d.geo_id
  FROM essentials.politicians p
  LEFT JOIN essentials.offices o ON o.id = p.office_id
  LEFT JOIN essentials.districts d ON d.id = o.district_id
  WHERE p.id = $1
`, [id]);
console.log('Politician:', JSON.stringify(pol.rows, null, 2));

// Check if they appear in race_candidates
const races = await pool.query(`
  SELECT rc.*, r.position_name, r.seats
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  WHERE rc.politician_id = $1
`, [id]);
console.log('Race candidates:', JSON.stringify(races.rows, null, 2));

await pool.end();
