import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

const POLITICIAN_IDS: Record<string, string> = {
  'Spencer Cox':     'b86213f8-abd8-46e7-80b6-3ae7bd2bf1a6',
  'Deidre Henderson':'f72689da-fe02-4bdd-977f-bb7760a42fb2',
  'Derek Brown':     '1844a5e3-8ea5-4ee5-9377-066378b25b49',
  'Marlo Oaks':      '919b82e8-bac3-428f-9896-423832e4538f',
  'Tina Cannon':     '9eac661a-e4c5-4bdf-9883-ee612dab53a8',
};

// Rows to exclude (full_name + topic_key)
const EXCLUDE = new Set([
  'Spencer Cox|campaign-finance',
  'Tina Cannon|ai-regulation',
]);

const CSV_DIR = join(process.cwd(), 'data/stance-research');
const FILES = [
  '2026-05-28-ut-state-exec-cox.csv',
  '2026-05-28-ut-state-exec-henderson.csv',
  '2026-05-28-ut-state-exec-brown.csv',
  '2026-05-28-ut-state-exec-oaks.csv',
  '2026-05-28-ut-state-exec-cannon.csv',
];

type Row = {
  full_name: string;
  topic_key: string;
  value: string;
  reasoning: string;
  source_url_1: string;
  source_url_2: string;
  source_url_3: string;
};

// Fetch all topic IDs
const { rows: topicRows } = await pool.query(
  `SELECT id, topic_key FROM inform.compass_topics WHERE is_live = true`
);
const topicMap: Record<string, string> = {};
for (const t of topicRows) topicMap[t.topic_key] = t.id;

const allRows: Row[] = [];
for (const file of FILES) {
  const content = readFileSync(join(CSV_DIR, file), 'utf8');
  const rows = parse(content, { columns: true, skip_empty_lines: true, relax_column_count: true }) as Row[];
  allRows.push(...rows);
}

let answered = 0;
let contexted = 0;
const errors: string[] = [];
const skipped: string[] = [];

for (const r of allRows) {
  const key = `${r.full_name}|${r.topic_key}`;
  if (EXCLUDE.has(key)) {
    skipped.push(key);
    continue;
  }

  const politicianId = POLITICIAN_IDS[r.full_name];
  if (!politicianId) {
    errors.push(`No politician_id for "${r.full_name}"`);
    continue;
  }

  const topicId = topicMap[r.topic_key];
  if (!topicId) {
    errors.push(`Unknown topic_key "${r.topic_key}" for ${r.full_name}`);
    continue;
  }

  const value = Number(r.value);
  if (isNaN(value) || value < 1 || value > 5) {
    errors.push(`Invalid value "${r.value}" for ${r.full_name}/${r.topic_key}`);
    continue;
  }

  const sources = [r.source_url_1, r.source_url_2, r.source_url_3]
    .map(s => s?.trim()).filter(Boolean);

  try {
    await pool.query(
      `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
       VALUES ($1, $2, $3)
       ON CONFLICT (politician_id, topic_id)
       DO UPDATE SET value = EXCLUDED.value`,
      [politicianId, topicId, value]
    );
    answered++;
  } catch (e: any) {
    errors.push(`answer upsert ${r.full_name}/${r.topic_key}: ${e.message}`);
    continue;
  }

  try {
    await pool.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (politician_id, topic_id)
       DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [politicianId, topicId, r.reasoning, sources]
    );
    contexted++;
  } catch (e: any) {
    errors.push(`context upsert ${r.full_name}/${r.topic_key}: ${e.message}`);
  }
}

console.log(`\nSUMMARY`);
console.log(`  politician_answers upserted : ${answered}`);
console.log(`  politician_context upserted : ${contexted}`);
console.log(`  skipped (excluded)          : ${skipped.length}`);
if (skipped.length) skipped.forEach(s => console.log(`    - ${s}`));
console.log(`  errors                      : ${errors.length}`);
if (errors.length) { errors.forEach(e => console.log(`    ERROR: ${e}`)); process.exitCode = 1; }

await pool.end();
