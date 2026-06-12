/**
 * _verify-114-01b.ts — check for duplicate Swalwell records
 */
import 'dotenv/config';
import { pool } from '../src/lib/db.js';

async function main() {
  const q = await pool.query(`
    SELECT p.id, p.full_name, p.is_active, p.finance_summary IS NOT NULL AS has_summary,
           d.district_type
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE p.full_name = 'Eric Swalwell'
    ORDER BY p.id
  `);
  console.log('All Eric Swalwell records:');
  console.table(q.rows);
  await pool.end();
}

main().catch(err => { console.error(err); process.exit(1); });
