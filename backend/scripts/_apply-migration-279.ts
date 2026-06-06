import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '279_md_2026_statewide_races.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 279 applied successfully');

  // Smoke test 1: Statewide race count (just the 12 non-legislative races from this migration)
  const r1 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD' AND e.name = '2026 Maryland General Election'
      AND r.position_name IN (
        'Governor of Maryland',
        'Attorney General of Maryland',
        'Comptroller of Maryland',
        'U.S. Senate Maryland',
        'U.S. House MD-01', 'U.S. House MD-02', 'U.S. House MD-03', 'U.S. House MD-04',
        'U.S. House MD-05', 'U.S. House MD-06', 'U.S. House MD-07', 'U.S. House MD-08'
      )
  `);
  console.log('MD statewide race rows (this migration):', r1.rows[0].cnt, '(expected 12)');

  // Smoke test 2: office_id NULL detector — must be 0
  const r2 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD' AND r.office_id IS NULL
  `);
  console.log('MD races with NULL office_id:', r2.rows[0].cnt, '(expected 0)');

  // Smoke test 3: Spot-check distinct position_names — expect 12 entries
  const r3 = await pool.query(`
    SELECT position_name FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD'
    ORDER BY position_name
  `);
  console.log('MD race position_names (expect 12):');
  r3.rows.forEach((row: { position_name: string }) => console.log(' -', row.position_name));

  // Smoke test 4: Ledger entry
  const r4 = await pool.query(`
    SELECT version FROM supabase_migrations.schema_migrations WHERE version = '279'
  `);
  console.log('Ledger entry 279:', r4.rows.length > 0 ? 'PRESENT' : 'MISSING');

} catch (e: any) {
  console.error('Error applying migration 279:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
