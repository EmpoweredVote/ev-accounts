import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

const DATE_TAG = '2026-04-13';
const CSV_DIR = join(process.cwd(), 'data/stance-research');
const CSV_PREFIX = `${DATE_TAG}-bcbf-`;
const CONFLICT_LOG = join(CSV_DIR, `${DATE_TAG}-bcbf-conflicts.log`);

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

if (!existsSync(CSV_DIR)) {
  console.error(`CSV dir missing: ${CSV_DIR}`);
  process.exit(1);
}

const files = readdirSync(CSV_DIR)
  .filter(f => f.startsWith(CSV_PREFIX) && f.endsWith('.csv'))
  .sort();
console.log(`Reading ${files.length} CSV files from ${CSV_DIR}`);

const allRows: Row[] = [];
for (const f of files) {
  const content = readFileSync(join(CSV_DIR, f), 'utf8');
  const rows = parse(content, { columns: true, skip_empty_lines: true, relax_column_count: true }) as Row[];
  allRows.push(...rows);
}
console.log(`Parsed ${allRows.length} total rows`);

const { rows: topicRows } = await pool.query(
  `SELECT id, topic_key FROM inform.compass_topics WHERE is_live = true`
);
const topicIdByKey = new Map<string, string>(topicRows.map(t => [t.topic_key, t.id]));

let upserted = 0;
let skippedNull = 0;
let conflicts = 0;
const errors: string[] = [];
const conflictLines: string[] = [];

for (const r of allRows) {
  const topicId = topicIdByKey.get(r.topic_key);
  if (!topicId) {
    errors.push(`${r.full_name}/${r.topic_key}: topic_key not found in live topics`);
    continue;
  }

  if (!r.value || r.value.trim() === '' || r.value === 'null') {
    console.log(`SKIP ${r.full_name}/${r.topic_key} (null value)`);
    skippedNull++;
    continue;
  }

  const newValue = Number(r.value);

  const { rows: currentRows } = await pool.query(
    `SELECT value::float AS value FROM inform.politician_answers WHERE politician_id=$1 AND topic_id=$2`,
    [r.politician_id, topicId]
  );
  const currentValue = currentRows[0]?.value;

  if (currentValue != null && Number(currentValue) !== newValue) {
    conflicts++;
    const line = `${r.full_name} (${r.politician_id}) / ${r.topic_key}: db=${currentValue} → agent=${newValue}\n  reasoning: ${r.reasoning.slice(0, 200)}\n`;
    conflictLines.push(line);
    console.log(`CONFLICT ${r.full_name}/${r.topic_key} db=${currentValue} agent=${newValue} (value NOT overwritten)`);
  }

  const sources = [r.source_url_1, r.source_url_2, r.source_url_3].map(s => s?.trim()).filter(Boolean);
  try {
    await pool.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (politician_id, topic_id)
       DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [r.politician_id, topicId, r.reasoning, sources]
    );
    upserted++;
    console.log(`OK ${r.full_name}/${r.topic_key}`);
  } catch (e: any) {
    errors.push(`${r.full_name}/${r.topic_key}: ${e.message}`);
    console.error(`FAIL ${r.full_name}/${r.topic_key}: ${e.message}`);
  }
}

if (conflictLines.length) {
  writeFileSync(CONFLICT_LOG, conflictLines.join('\n'));
  console.log(`\nConflicts logged to: ${CONFLICT_LOG}`);
}

console.log(`\nSUMMARY: upserted=${upserted} skipped_null=${skippedNull} conflicts=${conflicts} errors=${errors.length}`);
if (errors.length) {
  console.log('ERRORS:');
  errors.forEach(e => console.log('  ' + e));
  process.exitCode = 1;
}

await pool.end();
