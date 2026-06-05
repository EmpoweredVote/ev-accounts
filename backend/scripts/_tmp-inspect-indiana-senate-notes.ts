import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// Look for notes that mention Senate, House, Representative, etc.
const { rows } = await pool.query(`
  SELECT p.full_name, ps.notes
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = o.politician_id
  WHERE o.title = 'Indiana Elected Official'
    AND ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
    AND (
      ps.notes ILIKE '%senate%'
      OR ps.notes ILIKE '%house of representatives%'
      OR ps.notes ILIKE '%state rep%'
      OR ps.notes ILIKE '%representative%'
      OR ps.notes ILIKE '%governor%'
      OR ps.notes ILIKE '%attorney general%'
    )
  ORDER BY p.last_name, p.first_name
  LIMIT 20
`);

console.log(`Rows with chamber keywords: ${rows.length}`);
for (const r of rows) {
  console.log('NAME:', r.full_name);
  console.log('NOTES:', r.notes?.slice(0, 300) ?? '(null)');
  console.log('---');
}

// Count total affected rows
const { rows: countRows } = await pool.query(`
  SELECT COUNT(*) as total
  FROM essentials.offices o
  JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = o.politician_id
  WHERE o.title = 'Indiana Elected Official'
    AND ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
`);
console.log('Total affected rows:', countRows[0].total);

await pool.end();
