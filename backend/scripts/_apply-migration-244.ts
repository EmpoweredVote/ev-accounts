import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '244_multnomah_county_government.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 244 applied successfully');

  // Post-apply verification queries
  const r1 = await pool.query("SELECT COUNT(*) as cnt FROM essentials.governments WHERE name = 'Multnomah County, Oregon, US'");
  console.log('Government rows:', r1.rows[0].cnt, '(expected 1)');

  const r2 = await pool.query("SELECT COUNT(*) as cnt FROM essentials.chambers WHERE name = 'Board of Commissioners' AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Multnomah County, Oregon, US')");
  console.log('Chamber rows:', r2.rows[0].cnt, '(expected 1)');

  const r3 = await pool.query("SELECT COUNT(*) as cnt FROM essentials.districts WHERE geo_id = '41051' AND district_type = 'COUNTY' AND state = 'or'");
  console.log('COUNTY district rows:', r3.rows[0].cnt, '(expected 1)');

  const r4 = await pool.query("SELECT COUNT(*) as cnt FROM essentials.politicians WHERE external_id IN (-410001, -410010, -410011, -410012, -410013)");
  console.log('Politician rows:', r4.rows[0].cnt, '(expected 5)');

  const r5 = await pool.query("SELECT COUNT(*) as cnt FROM essentials.offices o JOIN essentials.districts d ON o.district_id = d.id WHERE d.geo_id = '41051' AND d.district_type = 'COUNTY'");
  console.log('Office rows linked to COUNTY district:', r5.rows[0].cnt, '(expected 5)');

  const r6 = await pool.query("SELECT COUNT(*) as cnt FROM essentials.politicians WHERE external_id IN (-410001, -410010, -410011, -410012, -410013) AND office_id IS NOT NULL");
  console.log('Politicians with office_id back-filled:', r6.rows[0].cnt, '(expected 5)');

  const r7 = await pool.query("SELECT COUNT(*) as cnt FROM supabase_migrations.schema_migrations WHERE version = '244'");
  console.log('Ledger entry:', r7.rows[0].cnt, '(expected 1)');

  // Section-split check
  const r8 = await pool.query(`SELECT COUNT(*) as cnt FROM essentials.geofence_boundaries gb WHERE gb.geo_id = '41051' AND gb.mtfcc = 'G4020' AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.geo_id = gb.geo_id AND d.district_type = 'COUNTY' AND d.state = 'or')`);
  console.log('Section-split orphans:', r8.rows[0].cnt, '(expected 0)');

  // Show politician IDs
  const r9 = await pool.query("SELECT external_id, id, full_name, office_id FROM essentials.politicians WHERE external_id IN (-410001, -410010, -410011, -410012, -410013) ORDER BY external_id");
  console.log('\nPolitician records:');
  for (const row of r9.rows) {
    console.log(`  external_id=${row.external_id}  id=${row.id}  name=${row.full_name}  office_id=${row.office_id}`);
  }

  // Show office IDs
  const r10 = await pool.query("SELECT o.id as office_id, o.title, p.external_id FROM essentials.offices o JOIN essentials.politicians p ON p.id = o.politician_id WHERE p.external_id IN (-410001, -410010, -410011, -410012, -410013) ORDER BY p.external_id");
  console.log('\nOffice records:');
  for (const row of r10.rows) {
    console.log(`  office_id=${row.office_id}  title=${row.title}  external_id=${row.external_id}`);
  }

  // Show government + district IDs
  const r11 = await pool.query("SELECT id, name, geo_id FROM essentials.governments WHERE name = 'Multnomah County, Oregon, US'");
  console.log('\nGovernment:', JSON.stringify(r11.rows[0]));

  const r12 = await pool.query("SELECT id, district_type, state, geo_id, label FROM essentials.districts WHERE geo_id = '41051' AND district_type = 'COUNTY'");
  console.log('COUNTY district:', JSON.stringify(r12.rows[0]));

  const r13 = await pool.query("SELECT id, name FROM essentials.chambers WHERE name = 'Board of Commissioners' AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Multnomah County, Oregon, US')");
  console.log('Chamber:', JSON.stringify(r13.rows[0]));

} catch (e: any) {
  console.error('Error applying migration 244:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
