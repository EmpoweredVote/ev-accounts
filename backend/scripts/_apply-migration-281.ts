import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '281_md_2026_discovery.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 281 applied successfully');

  // Smoke test 1: Row count — expect 2
  const r1 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.discovery_jurisdictions
    WHERE state = 'MD'
  `);
  console.log('MD discovery_jurisdictions rows:', r1.rows[0].cnt, '(expected 2)');

  // Smoke test 2: Both election dates present
  const r2 = await pool.query(`
    SELECT election_date::text FROM essentials.discovery_jurisdictions
    WHERE state = 'MD'
    ORDER BY election_date
  `);
  console.log('MD election dates:', r2.rows.map((r: any) => r.election_date));
  console.log('(expected: 2026-06-23, 2026-11-03)');

  // Smoke test 3: allowed_domains length for primary row — expect 4
  const r3 = await pool.query(`
    SELECT array_length(allowed_domains, 1) as domain_count
    FROM essentials.discovery_jurisdictions
    WHERE state = 'MD' AND election_date = '2026-06-23'
  `);
  console.log('allowed_domains length (primary):', r3.rows[0]?.domain_count, '(expected 4)');

  // Smoke test 4: source_url for primary row
  const r4 = await pool.query(`
    SELECT source_url FROM essentials.discovery_jurisdictions
    WHERE state = 'MD' AND election_date = '2026-06-23'
  `);
  console.log('source_url (primary):', r4.rows[0]?.source_url);
  console.log('(expected: https://elections.maryland.gov/elections/2026/primary_candidates/index.html)');

  // Smoke test 5: Ledger entry present
  const r5 = await pool.query(`
    SELECT version FROM supabase_migrations.schema_migrations WHERE version = '281'
  `);
  console.log('Ledger entry 281:', r5.rows.length > 0 ? 'PRESENT' : 'MISSING');

} catch (e: any) {
  console.error('Error applying migration 281:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
