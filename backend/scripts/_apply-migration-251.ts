import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '251_multnomah_elections.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 251 applied successfully');

  // Post-apply verification queries
  const r1 = await pool.query(
    `SELECT COUNT(*) as cnt FROM essentials.races r
     JOIN essentials.elections e ON e.id = r.election_id
     WHERE e.name = 'OR 2026 General' AND r.position_name ILIKE '%Multnomah County%'`
  );
  console.log('County race rows:', r1.rows[0].cnt, '(expected 2)');

  const r2 = await pool.query(
    `SELECT COUNT(*) as cnt FROM essentials.races r
     JOIN essentials.elections e ON e.id = r.election_id
     WHERE e.name = 'OR 2026 General'
       AND r.position_name ~ '(Gresham|Troutdale|Fairview|Wood Village|Maywood Park)'`
  );
  console.log('City race rows:', r2.rows[0].cnt, '(expected 16)');

  const r3 = await pool.query(
    `SELECT COUNT(*) as cnt FROM supabase_migrations.schema_migrations WHERE version = '251'`
  );
  console.log('Ledger entry:', r3.rows[0].cnt, '(expected 1)');

} catch (e: any) {
  console.error('Error applying migration 251:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
