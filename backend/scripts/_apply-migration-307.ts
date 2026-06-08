import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '307_va_state_senators.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 307 applied successfully');

  // Smoke test 1: 40 senator offices linked to Virginia Senate chamber
  const r1 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE c.name = 'Virginia Senate' AND o.representing_state = 'VA'
  `);
  console.log('Senator offices (Virginia Senate chamber):', r1.rows[0].cnt, '(expected 40)');

  // Smoke test 2: 40 politicians with external_id in range
  const r2 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.politicians
    WHERE external_id BETWEEN -5110040 AND -5110001
  `);
  console.log('Politician rows in range:', r2.rows[0].cnt, '(expected 40)');

  // Smoke test 3: All 40 have office_id back-filled
  const r3 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.politicians
    WHERE external_id BETWEEN -5110040 AND -5110001 AND office_id IS NOT NULL
  `);
  console.log('Politicians with office_id back-filled:', r3.rows[0].cnt, '(expected 40)');

  // Smoke test 4: All offices linked to STATE_UPPER districts with state='va'
  const r4 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE c.name = 'Virginia Senate'
      AND d.district_type = 'STATE_UPPER'
      AND d.state = 'va'
  `);
  console.log('Offices linked to STATE_UPPER districts (state=va):', r4.rows[0].cnt, '(expected 40)');

  // Spot-check SD-01 Timmy French
  const r5 = await pool.query(`
    SELECT p.full_name, p.external_id, d.geo_id, d.district_type, d.state
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE p.external_id = -5110001
  `);
  console.log('\nSpot-check SD-01:', JSON.stringify(r5.rows[0]));

  // Spot-check SD-20 Bill DeSteph
  const r6 = await pool.query(`
    SELECT p.full_name, p.external_id, d.geo_id, d.district_type, d.state
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE p.external_id = -5110020
  `);
  console.log('Spot-check SD-20:', JSON.stringify(r6.rows[0]));

  // Spot-check SD-40 Barbara A. Favola
  const r7 = await pool.query(`
    SELECT p.full_name, p.external_id, d.geo_id, d.district_type, d.state
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE p.external_id = -5110040
  `);
  console.log('Spot-check SD-40:', JSON.stringify(r7.rows[0]));

  // NULL office_id check
  const r8 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.politicians
    WHERE external_id BETWEEN -5110040 AND -5110001 AND office_id IS NULL
  `);
  console.log('\nNULL office_id count (expected 0):', r8.rows[0].cnt);

  // Party split verification
  const r9 = await pool.query(`
    SELECT party, COUNT(*)::int as cnt
    FROM essentials.politicians
    WHERE external_id BETWEEN -5110040 AND -5110001
    GROUP BY party
    ORDER BY party
  `);
  console.log('\nParty split:');
  r9.rows.forEach(row => console.log(' ', row.party, '=', row.cnt));

} catch (e: any) {
  console.error('Error applying migration 307:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
