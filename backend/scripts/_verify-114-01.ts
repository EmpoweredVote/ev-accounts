/**
 * _verify-114-01.ts — verification queries for Phase 114-01
 */
import 'dotenv/config';
import { pool } from '../src/lib/db.js';

async function main() {
  // Query 1: finance_summary for 6 targets
  const q1 = await pool.query(`
    SELECT p.full_name,
           p.finance_summary IS NOT NULL AS has_summary,
           p.finance_summary->>'cycle' AS cycle,
           p.finance_summary->>'total_raised' AS total_raised
    FROM essentials.politicians p
    WHERE p.full_name IN (
      'Glenn Ivey', 'Keith Self', 'Raphael Warnock', 'Ted Cruz',
      'Doug LaMalfa', 'Eric Swalwell'
    )
    ORDER BY p.full_name
  `);
  console.log('=== Query 1: finance_summary for 6 targets ===');
  console.table(q1.rows);

  // Query 2: LaMalfa/Swalwell politician_sources rows
  const q2 = await pool.query(`
    SELECT p.full_name, ps.source_system, ps.external_id, ps.research_status
    FROM essentials.politicians p
    JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = p.id
    WHERE p.full_name IN ('Doug LaMalfa', 'Eric Swalwell')
  `);
  console.log('=== Query 2: LaMalfa/Swalwell politician_sources ===');
  console.table(q2.rows);

  // Query 3: NULL count
  const q3 = await pool.query(`
    SELECT COUNT(*) AS null_finance_federal
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER')
      AND p.is_active = true
      AND p.finance_summary IS NULL
  `);
  console.log('=== Query 3: NULL finance count ===');
  console.table(q3.rows);

  await pool.end();
}

main().catch(err => { console.error(err); process.exit(1); });
