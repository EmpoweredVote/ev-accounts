import 'dotenv/config';
import { Pool } from 'pg';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

async function run() {
  // Check all sources for politician 7157dd95 (Marissa Roy)
  const src = await pool.query(`
    SELECT ps.source_system, ps.external_id, ps.research_status, ps.notes
    FROM transparent_motivations.politician_sources ps
    WHERE ps.essentials_politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c'
  `);
  console.log('All sources for Marissa Roy (7157dd95):', src.rows);

  // Check what la_socrata politicians exist
  const ls = await pool.query(`
    SELECT p.id, p.full_name, ps.source_system, ps.external_id, ps.research_status
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    WHERE ps.source_system = 'la_socrata' AND p.is_active = true
    ORDER BY p.full_name
    LIMIT 20
  `);
  console.log('LA Socrata politicians (active):', ls.rows.slice(0, 5));

  // How many LA politicians have la_socrata sources?
  const laCount = await pool.query(`
    SELECT COUNT(DISTINCT ps.essentials_politician_id)
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    WHERE ps.source_system = 'la_socrata' AND p.is_active = true
  `);
  console.log('Active politicians with la_socrata:', laCount.rows[0]);

  await pool.end();
}
run().catch(console.error);
