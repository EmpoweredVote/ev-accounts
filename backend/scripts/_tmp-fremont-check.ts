import 'dotenv/config';
import { Pool } from 'pg';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

async function run() {
  const r = await pool.query(`
    SELECT p.id, p.external_id, p.full_name, ch.name AS chamber, o.title, p.photo_origin_url
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.id = p.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.politician_images pi ON pi.politician_id = p.id
    WHERE g.name = 'City of Fremont' AND g.state = 'CA'
      AND p.external_id BETWEEN -670015 AND -670001
      AND p.is_active = true
      AND p.is_vacant = false
      AND pi.id IS NULL
    ORDER BY ch.name, o.title, p.full_name
  `);
  console.log(JSON.stringify(r.rows, null, 2));
  await pool.end();
}
run().catch(console.error);
