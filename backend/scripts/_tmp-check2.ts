import 'dotenv/config';
import { Pool } from 'pg';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

async function run() {
  // Check Marissa Roy's government data
  const res = await pool.query(`
    SELECT p.id, p.full_name, p.is_active, o.title, c.name as chamber, g.name as govt, g.state
    FROM essentials.politicians p
    LEFT JOIN essentials.offices o ON o.politician_id = p.id
    LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = c.government_id
    WHERE p.id = '7157dd95-0f1b-4e05-bd4f-39317345b47c'
  `);
  console.log('Marissa Roy detail:', res.rows);

  // Count CA politicians total
  const ca = await pool.query(`
    SELECT COUNT(DISTINCT p.id) 
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.state = 'CA' AND p.is_active = true AND p.full_name IS NOT NULL
  `);
  console.log('Total active CA politicians with offices:', ca.rows[0]);

  await pool.end();
}
run().catch(console.error);
