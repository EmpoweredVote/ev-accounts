// Proper CSV ingest using csv-parse — handles both quoted and unquoted rows
// Usage: node ingest-politician-csv.mjs <csv-path> <politician-id>
import { pool } from '../src/lib/db.js';
import { parse } from 'csv-parse';
import { createReadStream } from 'fs';

const [,, csvPath, politicianId] = process.argv;
if (!csvPath || !politicianId) { console.error('Usage: node ingest-politician-csv.mjs <csv-path> <politician-id>'); process.exit(1); }

const parser = createReadStream(csvPath).pipe(parse({ columns: true, skip_empty_lines: true, relax_quotes: true, trim: true }));

let count = 0;
for await (const row of parser) {
  if (row.politician_id !== politicianId) continue;
  const sources = [row.source_url_1, row.source_url_2, row.source_url_3].map(s => s?.trim()).filter(Boolean);
  await pool.query(
    `INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ($1,$2,$3) ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value`,
    [row.politician_id, row.topic_id, parseInt(row.value)]
  );
  await pool.query(
    `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ($1,$2,$3,$4) ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources`,
    [row.politician_id, row.topic_id, row.notes, sources]
  );
  console.log(`OK: ${row.topic_key} = ${row.value}`);
  count++;
}
console.log(`\nDone: ${count} stances upserted for ${politicianId}`);
await pool.end();
