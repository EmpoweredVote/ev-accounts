import 'dotenv/config';
import { Pool } from 'pg';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

async function run() {
  // Find all politicians named Marissa Roy  
  const res = await pool.query(`
    SELECT p.id, p.full_name, p.is_active,
      (SELECT COUNT(*) FROM essentials.offices o WHERE o.politician_id = p.id) as office_count,
      (SELECT COUNT(*) FROM transparent_motivations.politician_sources ps WHERE ps.essentials_politician_id = p.id) as source_count
    FROM essentials.politicians p
    WHERE p.full_name ILIKE '%marissa%'
    ORDER BY p.full_name
  `);
  console.log('All Marissa politicians:', res.rows);

  // Check if any government is 'LA' related
  const govt = await pool.query(`
    SELECT g.id, g.name, g.state, g.city
    FROM essentials.governments g
    WHERE g.name ILIKE '%angeles%' OR g.city ILIKE '%angeles%'
    LIMIT 5
  `);
  console.log('LA governments:', govt.rows);

  // Check what politician_sources exist for la_socrata
  const laPs = await pool.query(`
    SELECT ps.essentials_politician_id, p.full_name, ps.source_system, ps.research_status
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    WHERE ps.source_system = 'la_socrata' AND p.full_name ILIKE '%marissa%'
  `);
  console.log('LA Socrata Marissa sources:', laPs.rows);

  await pool.end();
}
run().catch(console.error);
