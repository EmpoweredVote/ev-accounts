import 'dotenv/config';
import { pool } from '../src/lib/db.js';
const { rows } = await pool.query(`
  SELECT COUNT(*) as cnt
  FROM essentials.offices o
  JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = o.politician_id
  WHERE o.title = 'Indiana Elected Official'
    AND ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
`);
console.log('Indiana Elected Official (confirmed indiana scope) count:', rows[0].cnt);
await pool.end();
