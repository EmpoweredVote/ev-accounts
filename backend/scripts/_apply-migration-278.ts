import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '278_md_2026_elections.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 278 applied successfully');

  // Smoke test 1: Election count
  const r1 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.elections
    WHERE state = 'MD' AND election_date IN ('2026-06-23', '2026-11-03')
  `);
  console.log('MD 2026 election rows:', r1.rows[0].cnt, '(expected 2)');

  // Smoke test 2: Primary date check
  const r2 = await pool.query(`
    SELECT election_date FROM essentials.elections
    WHERE name = '2026 Maryland State Primary' AND state = 'MD'
  `);
  console.log('Primary election_date:', r2.rows[0]?.election_date, '(expected 2026-06-23)');

  // Smoke test 3: General date check
  const r3 = await pool.query(`
    SELECT election_date FROM essentials.elections
    WHERE name = '2026 Maryland General Election' AND state = 'MD'
  `);
  console.log('General election_date:', r3.rows[0]?.election_date, '(expected 2026-11-03)');

  // Smoke test 4: Ledger entry
  const r4 = await pool.query(`
    SELECT version FROM supabase_migrations.schema_migrations WHERE version = '278'
  `);
  console.log('Ledger entry 278:', r4.rows.length > 0 ? 'PRESENT' : 'MISSING');

} catch (e: any) {
  console.error('Error applying migration 278:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
