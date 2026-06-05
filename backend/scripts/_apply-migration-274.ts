import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({ connectionString: process.env['DATABASE_URL'], ssl: { rejectUnauthorized: false } });

const sql = readFileSync(path.join(process.cwd(), 'migrations', '274_md_delegates.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log('Migration 274 applied successfully');

  // Smoke test 1: 141 delegate offices linked to Maryland House of Delegates chamber
  const r1 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE c.name = 'Maryland House of Delegates' AND o.representing_state = 'MD'
  `);
  console.log('Delegate offices (Maryland House of Delegates chamber):', r1.rows[0].cnt, '(expected 141)');

  // Smoke test 2: 141 politicians with external_id in range
  const r2 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.politicians
    WHERE external_id BETWEEN -2420141 AND -2420001
  `);
  console.log('Politician rows in range:', r2.rows[0].cnt, '(expected 141)');

  // Smoke test 3: All 141 have office_id back-filled
  const r3 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.politicians
    WHERE external_id BETWEEN -2420141 AND -2420001 AND office_id IS NOT NULL
  `);
  console.log('Politicians with office_id back-filled:', r3.rows[0].cnt, '(expected 141)');

  // Smoke test 4: NULL office_id count (should be 0)
  const r4 = await pool.query(`
    SELECT COUNT(*) as cnt FROM essentials.politicians
    WHERE external_id BETWEEN -2420141 AND -2420001 AND office_id IS NULL
  `);
  console.log('NULL office_id count (expected 0):', r4.rows[0].cnt);

  // Multi-member integrity: whole-district gate (each whole district must have exactly 3 offices)
  const r5 = await pool.query(`
    SELECT d.geo_id, COUNT(*) AS office_count
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE c.name = 'Maryland House of Delegates'
      AND d.district_type = 'STATE_LOWER'
      AND d.state = 'md'
      AND d.geo_id IN ('24003','24004','24005','24006','24008','24010','24013','24014','24015','24016',
                       '24017','24018','24019','24020','24021','24022','24023','24024','24025','24026',
                       '24028','24031','24032','24036','24039','24040','24041','24045','24046')
    GROUP BY d.geo_id
    HAVING COUNT(*) <> 3
  `);
  console.log('\nWhole-district integrity gate (expected 0 rows):', r5.rows.length, 'violation(s)');
  if (r5.rows.length > 0) {
    console.log('Violations:', JSON.stringify(r5.rows));
  }

  // A/B parent integrity: each of the 12 A/B parents must sum to 3 offices
  const r6 = await pool.query(`
    SELECT LEFT(d.geo_id, 4) AS parent, SUM(1) AS office_count
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE c.name = 'Maryland House of Delegates'
      AND d.district_type = 'STATE_LOWER'
      AND d.state = 'md'
      AND d.geo_id IN ('2402A','2402B','2407A','2407B','2409A','2409B','2411A','2411B',
                       '2412A','2412B','2430A','2430B','2434A','2434B','2435A','2435B',
                       '2437A','2437B','2443A','2443B','2444A','2444B','2447A','2447B')
    GROUP BY LEFT(d.geo_id, 4)
    HAVING SUM(1) <> 3
  `);
  console.log('A/B parent integrity gate (expected 0 rows):', r6.rows.length, 'violation(s)');
  if (r6.rows.length > 0) {
    console.log('Violations:', JSON.stringify(r6.rows));
  }

  // A/B/C parent integrity: each of the 6 A/B/C parents has 3 offices (1 per subdistrict)
  const r7 = await pool.query(`
    SELECT LEFT(d.geo_id, 4) AS parent, COUNT(*) AS office_count
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE c.name = 'Maryland House of Delegates'
      AND d.district_type = 'STATE_LOWER'
      AND d.state = 'md'
      AND d.geo_id IN ('2401A','2401B','2401C','2427A','2427B','2427C','2429A','2429B','2429C',
                       '2433A','2433B','2433C','2438A','2438B','2438C','2442A','2442B','2442C')
    GROUP BY LEFT(d.geo_id, 4)
    HAVING COUNT(*) <> 3
  `);
  console.log('A/B/C parent integrity gate (expected 0 rows):', r7.rows.length, 'violation(s)');
  if (r7.rows.length > 0) {
    console.log('Violations:', JSON.stringify(r7.rows));
  }

  // District 42A vacant check
  const r8 = await pool.query(`
    SELECT o.is_vacant, p.full_name, p.is_active, p.is_incumbent
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = o.politician_id
    WHERE d.geo_id = '2442A' AND d.district_type = 'STATE_LOWER' AND d.state = 'md'
  `);
  console.log('\nDistrict 42A office:', JSON.stringify(r8.rows));

  // Spot-check HD-3 (whole district, 3 offices, same geo_id)
  const r9 = await pool.query(`
    SELECT p.full_name, p.external_id, d.geo_id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE c.name = 'Maryland House of Delegates' AND d.geo_id = '24003'
    ORDER BY p.external_id
  `);
  console.log('\nSpot-check HD-3 (3 delegates, same geo_id):', JSON.stringify(r9.rows));

  // Spot-check HD-2A (subdistrict, 2 delegates)
  const r10 = await pool.query(`
    SELECT p.full_name, p.external_id, d.geo_id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE c.name = 'Maryland House of Delegates' AND d.geo_id = '2402A'
    ORDER BY p.external_id
  `);
  console.log('Spot-check HD-2A (2 delegates):', JSON.stringify(r10.rows));

  // Spot-check Pena-Melnyk (HD-21, non-ASCII name)
  const r11 = await pool.query(`
    SELECT p.full_name, p.external_id, d.geo_id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE c.name = 'Maryland House of Delegates' AND p.full_name LIKE 'Joseline%'
  `);
  console.log('Spot-check Pena-Melnyk:', JSON.stringify(r11.rows));

} catch (e: any) {
  console.error('Error applying migration 274:', e.message);
  process.exit(1);
} finally {
  await pool.end();
}
