import { readFileSync } from 'node:fs';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

const CSV_PATH = 'data/stance-research/2026-04-12-backfill-taxes.csv';

type Row = {
  full_name: string;
  politician_id: string;
  topic_key: string;
  value: string;
  reasoning: string;
  source_url_1: string;
  source_url_2: string;
  source_url_3: string;
};

const { rows: topicRows } = await pool.query(
  `SELECT id FROM inform.compass_topics WHERE topic_key='taxes' AND is_live=true`
);
if (topicRows.length !== 1) {
  throw new Error(`Expected 1 live taxes topic, got ${topicRows.length}`);
}
const topicId = topicRows[0].id;
console.log(`Live taxes topic_id: ${topicId}`);

const content = readFileSync(CSV_PATH, 'utf8');
const rows = parse(content, { columns: true, skip_empty_lines: true, relax_column_count: true }) as Row[];
console.log(`Parsed ${rows.length} rows from CSV`);

let answersUpserted = 0;
let contextUpserted = 0;
const errors: string[] = [];

for (const r of rows) {
  if (!r.value || r.value === 'null') {
    console.log(`SKIP ${r.full_name} (null value)`);
    continue;
  }
  const value = Number(r.value);
  const sources = [r.source_url_1, r.source_url_2, r.source_url_3].map(s => s?.trim()).filter(Boolean);

  try {
    await pool.query(
      `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
       VALUES ($1, $2, $3)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
      [r.politician_id, topicId, value]
    );
    answersUpserted++;

    await pool.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [r.politician_id, topicId, r.reasoning, sources]
    );
    contextUpserted++;
    console.log(`OK ${r.full_name} value=${value}`);
  } catch (e: any) {
    errors.push(`${r.full_name}: ${e.message}`);
    console.error(`FAIL ${r.full_name}:`, e.message);
  }
}

console.log(`\nSUMMARY: answers=${answersUpserted} context=${contextUpserted} errors=${errors.length}`);
if (errors.length) errors.forEach(e => console.log('  ' + e));
await pool.end();
