import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '252_multnomah_discovery.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 252 applied successfully');

  // Post-apply verification queries
  const r1 = await pool.query(
    `SELECT COUNT(*) as cnt FROM essentials.discovery_jurisdictions
     WHERE jurisdiction_geoid = '41051' AND election_date = '2026-11-03'`
  );
  console.log('Discovery jurisdiction rows:', r1.rows[0].cnt, '(expected 1)');

  const r2 = await pool.query(
    `SELECT jurisdiction_geoid, jurisdiction_name, source_url, allowed_domains, election_date
     FROM essentials.discovery_jurisdictions
     WHERE jurisdiction_geoid = '41051'`
  );
  console.log('Discovery row:', JSON.stringify(r2.rows[0]));

  const r3 = await pool.query(
    `SELECT COUNT(*) as cnt FROM supabase_migrations.schema_migrations WHERE version = '252'`
  );
  console.log('Ledger entry:', r3.rows[0].cnt, '(expected 1)');

} catch (e: any) {
  console.error('Error applying migration 252:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
