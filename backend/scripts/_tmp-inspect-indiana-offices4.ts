import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// Check contributions raw_record for Indiana politicians still at 'Indiana Elected Official'
// The raw_record might contain office_type or committee_type
const { rows } = await pool.query(`
  SELECT DISTINCT
    p.full_name,
    c.raw_record
  FROM transparent_motivations.contributions c
  JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
  JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
  JOIN essentials.offices o ON o.politician_id = ps.essentials_politician_id
  WHERE ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
    AND o.title = 'Indiana Elected Official'
    AND c.data_source = 'indiana'
  ORDER BY p.full_name
  LIMIT 10
`);

console.log('Sample raw_records:');
for (const r of rows) {
  console.log('NAME:', r.full_name);
  const rr = r.raw_record;
  if (rr) {
    console.log('RAW_RECORD:', JSON.stringify(rr, null, 2).slice(0, 500));
  } else {
    console.log('RAW_RECORD: null');
  }
  console.log('---');
}

// Check how many Indiana contributions have type field in raw_record
const { rows: typeCheck } = await pool.query(`
  SELECT
    c.raw_record->>'type' AS rec_type,
    COUNT(*) as cnt
  FROM transparent_motivations.contributions c
  JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
  JOIN essentials.offices o ON o.politician_id = ps.essentials_politician_id
  WHERE ps.source_system = 'indiana'
    AND o.title = 'Indiana Elected Official'
    AND c.data_source = 'indiana'
    AND c.raw_record IS NOT NULL
  GROUP BY c.raw_record->>'type'
  ORDER BY cnt DESC
  LIMIT 10
`);
console.log('Type field distribution in raw_record:');
for (const r of typeCheck) console.log(`  ${r.rec_type ?? 'null'}: ${r.cnt}`);

await pool.end();
