// Ingest stances for a single politician_id from the CSV file
// Usage: node ingest-from-csv.mjs <csv-path> <politician-id>
import { pool } from '../src/lib/db.js';
import { createReadStream } from 'fs';
import { createInterface } from 'readline';

const [,, csvPath, politicianId] = process.argv;
if (!csvPath || !politicianId) {
  console.error('Usage: node ingest-from-csv.mjs <csv-path> <politician-id>');
  process.exit(1);
}

const rl = createInterface({ input: createReadStream(csvPath) });
const rows = [];
let header = true;

for await (const line of rl) {
  if (header) { header = false; continue; }
  // Match both quoted ("uuid,...") and unquoted (uuid,...) formats
  const lineId = line.startsWith('"') ? line.slice(1, 37) : line.slice(0, 36);
  if (lineId !== politicianId) continue;

  // Parse CSV row (simple split — notes field may contain commas in quotes)
  const match = line.match(/^([^,]+),([^,]+),([^,]+),([^,]+),"(.*?)",(.*)$/s);
  if (!match) {
    // No-quotes fallback
    const parts = line.split(',');
    rows.push({ pid: parts[0], topic_id: parts[1], topic_key: parts[2], value: parseInt(parts[3]), notes: parts[4], sources: parts.slice(5).filter(Boolean) });
    continue;
  }
  const [, pid, topic_id, topic_key, value, notes, rest] = match;
  const sources = rest.split(',').map(s => s.replace(/^"|"$/g, '').trim()).filter(Boolean);
  rows.push({ pid, topic_id, topic_key, value: parseInt(value), notes, sources });
}

if (rows.length === 0) {
  console.log(`No rows found for politician_id=${politicianId}`);
  await pool.end();
  process.exit(0);
}

for (const r of rows) {
  await pool.query(
    `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
     VALUES ($1, $2, $3)
     ON CONFLICT (politician_id, topic_id)
     DO UPDATE SET value = EXCLUDED.value`,
    [r.pid, r.topic_id, r.value]
  );
  await pool.query(
    `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (politician_id, topic_id)
     DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
    [r.pid, r.topic_id, r.notes, r.sources]
  );
  console.log(`OK: ${r.topic_key} = ${r.value}`);
}

console.log(`\nDone: ${rows.length} stances upserted for ${politicianId}`);
await pool.end();
