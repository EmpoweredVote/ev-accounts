import 'dotenv/config';
import { pool } from '../src/lib/db.js';

async function main() {
  const result = await pool.query(`
    SELECT COUNT(DISTINCT p.id) as cnt
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE p.is_active = true
      AND p.is_vacant = false
      AND (c.name LIKE 'U.S. House%' OR c.name LIKE 'U.S. Senate%')
      AND NOT EXISTS (
        SELECT 1
        FROM transparent_motivations.politician_sources ps
        WHERE ps.essentials_politician_id = p.id
          AND ps.source_system LIKE 'fec%'
      )
  `);
  console.log('Unmatched federal politicians:', result.rows[0].cnt);
  process.exit(0);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
