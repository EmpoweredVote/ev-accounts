import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '280_md_2026_legislative_races.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 280 applied successfully');

  // Smoke test 1: Senate race count
  const r1 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD' AND r.position_name LIKE 'MD State Senate%'
  `);
  console.log('MD State Senate race rows:', r1.rows[0].cnt, '(expected 47)');

  // Smoke test 2: House whole-district count
  const r2 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD' AND r.position_name LIKE 'MD House Delegate District%'
  `);
  console.log('MD House Delegate District rows:', r2.rows[0].cnt, '(expected 29)');

  // Smoke test 3: House sub-district count
  const r3 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD' AND r.position_name LIKE 'MD House Delegate Subdistrict%'
  `);
  console.log('MD House Delegate Subdistrict rows:', r3.rows[0].cnt, '(expected 42)');

  // Smoke test 4: Total MD race count
  const r4 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD'
  `);
  console.log('Total MD race rows:', r4.rows[0].cnt, '(expected 130)');

  // Smoke test 5: office_id NULL detector — must be 0
  const r5 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD' AND r.office_id IS NULL
  `);
  console.log('MD races with NULL office_id:', r5.rows[0].cnt, '(expected 0)');

  // Smoke test 6: Seats sum sanity for house delegate races
  const r6 = await pool.query(`
    SELECT SUM(seats) as total FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD' AND r.position_name LIKE 'MD House Delegate%'
  `);
  console.log('Total seats across MD House Delegate races:', r6.rows[0].total, '(expected 141)');

  // Smoke test 7: Spot-check Subdistrict 11B seats = 2
  const r7 = await pool.query(`
    SELECT seats FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD' AND r.position_name = 'MD House Delegate Subdistrict 11B'
  `);
  console.log('MD House Delegate Subdistrict 11B seats:', r7.rows[0]?.seats, '(expected 2)');

  // Smoke test 8: Spot-check Senate District 1 seats = 1
  const r8 = await pool.query(`
    SELECT seats FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD' AND r.position_name = 'MD State Senate District 1'
  `);
  console.log('MD State Senate District 1 seats:', r8.rows[0]?.seats, '(expected 1)');

  // Smoke test 9: Spot-check House District 3 seats = 3
  const r9 = await pool.query(`
    SELECT seats FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE e.state = 'MD' AND r.position_name = 'MD House Delegate District 3'
  `);
  console.log('MD House Delegate District 3 seats:', r9.rows[0]?.seats, '(expected 3)');

  // Smoke test 10: Ledger entry
  const r10 = await pool.query(`
    SELECT version FROM supabase_migrations.schema_migrations WHERE version = '280'
  `);
  console.log('Ledger entry 280:', r10.rows.length > 0 ? 'PRESENT' : 'MISSING');

} catch (e: any) {
  console.error('Error applying migration 280:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
