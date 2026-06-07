import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '276_stmarys_county_government.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 276 applied successfully');

  // Smoke test 1: St. Mary's County government row count
  const r1 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.governments
    WHERE name = 'St. Mary''s County, Maryland, US'
  `);
  console.log('St. Mary\'s County government rows:', r1.rows[0].cnt, '(expected 1)');

  // Smoke test 2: Offices linked to COUNTY district for geo_id=24037
  const r2 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '24037' AND d.district_type = 'COUNTY' AND d.state = 'md'
  `);
  console.log('St. Mary\'s County offices:', r2.rows[0].cnt, '(expected 5)');

  // Smoke test 3: Politicians with external_id in range
  const r3 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.politicians
    WHERE external_id BETWEEN -24037005 AND -24037001
  `);
  console.log('St. Mary\'s County politicians:', r3.rows[0].cnt, '(expected 5)');

  // Smoke test 4: office_id back-fill complete
  const r4 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.politicians
    WHERE external_id BETWEEN -24037005 AND -24037001 AND office_id IS NOT NULL
  `);
  console.log('Politicians with office_id back-filled:', r4.rows[0].cnt, '(expected 5)');

  // Smoke test 5: Section-split detector = 0
  const r5 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.geofence_boundaries gb
    WHERE gb.geo_id = '24037' AND gb.mtfcc = 'G4020'
      AND NOT EXISTS (
        SELECT 1 FROM essentials.districts d
        WHERE d.geo_id = gb.geo_id AND d.district_type = 'COUNTY' AND d.state = 'md'
      )
  `);
  console.log('Section-split orphans (expected 0):', r5.rows[0].cnt);

  // Smoke test 6: Ledger entry present
  const r6 = await pool.query(`
    SELECT version FROM supabase_migrations.schema_migrations WHERE version = '276'
  `);
  console.log('Ledger entry 276:', r6.rows.length > 0 ? 'PRESENT' : 'MISSING');

  // Spot-check: list all 5 commissioners
  const r7 = await pool.query(`
    SELECT p.full_name, p.external_id, o.title
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '24037' AND d.district_type = 'COUNTY' AND d.state = 'md'
    ORDER BY p.external_id DESC
  `);
  console.log('\nSt. Mary\'s County commissioners:', JSON.stringify(r7.rows, null, 2));

} catch (e: any) {
  console.error('Error applying migration 276:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
