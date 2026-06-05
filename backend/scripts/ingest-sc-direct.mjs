// Direct ingest for Sharp-Collins rows that are in quoted CSV format
import { pool } from '../src/lib/db.js';
import { readFileSync } from 'fs';

const politicianId = 'cb2ae7a3-3b6a-462b-8fe8-47f3ce4cb7a2';
const csvPath = 'data/stance-research/2026-05-29-ca-assembly-remaining.csv';

const content = readFileSync(csvPath, 'utf8');
const lines = content.split('\n').filter(l => l.includes(politicianId));

let count = 0;
for (const line of lines) {
  // Strip outer quotes and split on ","
  const stripped = line.trim().replace(/^"|"$/g, '');
  const parts = stripped.split('","');
  if (parts.length < 5) continue;
  const [pid, topic_id, topic_key, value, notes, src1 = '', src2 = '', src3 = ''] = parts;
  const sources = [src1, src2, src3].map(s => s.replace(/^"|"$/g, '').trim()).filter(Boolean);

  await pool.query(
    `INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ($1,$2,$3) ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value`,
    [politicianId, topic_id, parseInt(value)]
  );
  await pool.query(
    `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ($1,$2,$3,$4) ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources`,
    [politicianId, topic_id, notes, sources]
  );
  console.log(`OK: ${topic_key} = ${value}`);
  count++;
}
console.log(`\nDone: ${count} stances for ${politicianId}`);
await pool.end();
