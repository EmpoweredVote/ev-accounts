import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// Check notes for already-classified Indiana politicians
// to understand what patterns they contain
const { rows } = await pool.query(`
  SELECT p.full_name, o.title, ps.notes
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = o.politician_id
  WHERE ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
    AND o.title IN ('State Representative', 'State Senator', 'Governor', 'Attorney General', 'Secretary of State')
  ORDER BY o.title, p.last_name
  LIMIT 20
`);

console.log('Already-classified politician notes:');
for (const r of rows) {
  console.log(`[${r.title}] ${r.full_name}`);
  console.log('NOTES:', r.notes?.slice(0, 300) ?? '(null)');
  console.log('---');
}

// Also check the FileNumber field from raw_record for unclassified politicians
// to see if there's a way to bulk-lookup via the Indiana SoS
const { rows: fileNums } = await pool.query(`
  SELECT DISTINCT
    p.full_name,
    c.raw_record->>'FileNumber' AS file_number,
    c.raw_record->>'Committee' AS committee_name
  FROM transparent_motivations.contributions c
  JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
  JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
  JOIN essentials.offices o ON o.politician_id = ps.essentials_politician_id
  WHERE ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
    AND o.title = 'Indiana Elected Official'
    AND c.data_source = 'indiana'
    AND c.raw_record->>'FileNumber' IS NOT NULL
  ORDER BY p.last_name
  LIMIT 15
`);

console.log('\nFileNumber + Committee for unclassified Indiana politicians:');
for (const r of fileNums) {
  console.log(`  ${r.full_name.padEnd(30)} | File# ${r.file_number?.padEnd(8)} | ${r.committee_name}`);
}

await pool.end();
