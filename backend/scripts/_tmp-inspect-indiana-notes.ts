import 'dotenv/config';
import { pool } from '../src/lib/db.js';

const { rows } = await pool.query(`
  SELECT p.full_name, ps.notes
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = o.politician_id
  WHERE o.title = 'Indiana Elected Official'
    AND ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
  ORDER BY p.last_name, p.first_name
  LIMIT 10
`);

for (const r of rows) {
  console.log('NAME:', r.full_name);
  console.log('NOTES:', r.notes?.slice(0, 400) ?? '(null)');
  console.log('---');
}

await pool.end();
