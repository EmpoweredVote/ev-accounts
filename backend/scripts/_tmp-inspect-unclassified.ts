import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// Get all committee names from unclassified politicians to understand the patterns
const { rows } = await pool.query(`
  SELECT p.full_name, ps.notes
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = o.politician_id
  WHERE o.title = 'Indiana Elected Official'
    AND ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
  ORDER BY p.last_name, p.first_name
`);

// Extract committee names
const committees: string[] = [];
for (const r of rows) {
  const m = r.notes?.match(/Committee:\s*(.+?)\.\s*Office type/i);
  if (m) committees.push(m[1].trim());
}

console.log(`Total unclassified: ${rows.length}`);
console.log(`With committee names: ${committees.length}`);
console.log('\nSample committee names (first 50):');
for (const c of committees.slice(0, 50)) {
  console.log(`  "${c}"`);
}

// Look for any with state/senate/house keywords we might have missed
const withKeywords = committees.filter(c =>
  /senate|senator|house|representative|state rep|congress/i.test(c)
);
console.log(`\nCommittees with chamber keywords: ${withKeywords.length}`);
for (const c of withKeywords.slice(0, 20)) console.log(`  "${c}"`);

// See what "for" patterns look like
const forPatterns = committees.filter(c => /\bfor\b/i.test(c));
console.log(`\nCommittees with "for": ${forPatterns.length}`);
// Sample the non-obvious ones
const nonObvious = forPatterns.filter(c =>
  !/state rep|state senator|senate|house|governor|attorney general|secretary|treasurer|auditor/i.test(c)
);
console.log(`Non-obvious "for" patterns: ${nonObvious.length}`);
for (const c of nonObvious.slice(0, 20)) console.log(`  "${c}"`);

await pool.end();
