import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// Check existing office data to understand what we're working with
const { rows: titleDist } = await pool.query(`
  SELECT o.title, COUNT(*) as cnt
  FROM essentials.offices o
  JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = o.politician_id
  WHERE ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
  GROUP BY o.title
  ORDER BY cnt DESC
`);
console.log('Current title distribution for confirmed Indiana politicians:');
for (const r of titleDist) {
  console.log(`  ${String(r.cnt).padStart(4)}  ${r.title}`);
}

// Check if there are any raw_record fields we can use
const { rows: sample } = await pool.query(`
  SELECT p.full_name, ps.notes, ps.raw_record
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = o.politician_id
  WHERE o.title = 'Indiana Elected Official'
    AND ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
  ORDER BY p.last_name, p.first_name
  LIMIT 5
`);

console.log('\nSample rows with raw_record:');
for (const r of sample) {
  console.log('NAME:', r.full_name);
  console.log('NOTES:', r.notes?.slice(0, 200) ?? '(null)');
  const rr = r.raw_record;
  if (rr) {
    const keys = typeof rr === 'object' ? Object.keys(rr) : [];
    console.log('RAW_RECORD keys:', keys);
    if (keys.length > 0) console.log('RAW_RECORD:', JSON.stringify(rr).slice(0, 300));
  } else {
    console.log('RAW_RECORD: null');
  }
  console.log('---');
}

// Check contributions table for office_type or similar
const { rows: contribSample } = await pool.query(`
  SELECT DISTINCT c.filing_type, c.office_sought, c.jurisdiction
  FROM transparent_motivations.contributions c
  JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
  JOIN essentials.offices o ON o.politician_id = ps.essentials_politician_id
  WHERE ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
    AND o.title = 'Indiana Elected Official'
    AND (c.filing_type IS NOT NULL OR c.office_sought IS NOT NULL OR c.jurisdiction IS NOT NULL)
  LIMIT 10
`);
console.log('\nContributions with office info (first 10):');
for (const r of contribSample) {
  console.log(`  filing_type=${r.filing_type} | office_sought=${r.office_sought} | jurisdiction=${r.jurisdiction}`);
}

await pool.end();
