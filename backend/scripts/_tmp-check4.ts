import 'dotenv/config';
import { Pool } from 'pg';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

async function run() {
  // Check the specific politician
  const res = await pool.query(`
    SELECT p.id, p.full_name, p.is_active
    FROM essentials.politicians p
    WHERE p.id = '7157dd95-0f1b-4e05-bd4f-39317345b47c'
  `);
  console.log('Marissa Roy politician row:', res.rows);

  // Check her offices
  const offs = await pool.query(`SELECT * FROM essentials.offices WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c'`);
  console.log('Offices:', offs.rows);

  // Check her politician_sources
  const ps = await pool.query(`SELECT * FROM transparent_motivations.politician_sources WHERE essentials_politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c'`);
  console.log('politician_sources:', ps.rows);

  await pool.end();
}
run().catch(console.error);
