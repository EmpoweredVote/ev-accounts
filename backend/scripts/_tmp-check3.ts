import 'dotenv/config';
import { Pool } from 'pg';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

async function run() {
  const res = await pool.query(`
    SELECT DISTINCT p.id, p.full_name
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.state = 'CA' AND p.is_active = true AND p.full_name IS NOT NULL AND p.full_name != ''
    UNION
    SELECT DISTINCT p.id, p.full_name
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    WHERE o.representing_state = 'CA' AND p.is_active = true AND p.full_name IS NOT NULL AND p.full_name != ''
    UNION
    SELECT DISTINCT p.id, p.full_name
    FROM essentials.politicians p
    JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = p.id
    WHERE ps.source_system = 'cal_access' AND p.is_active = true AND p.full_name IS NOT NULL AND p.full_name != ''
    ORDER BY full_name
  `);
  const marissa = res.rows.filter((r: any) => r.full_name.toLowerCase().includes('marissa'));
  console.log('Marissa in politicians list:', marissa);
  console.log('Total politicians:', res.rows.length);
  await pool.end();
}
run().catch(console.error);
