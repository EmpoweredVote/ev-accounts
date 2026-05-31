import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

// politician_id map from the research-stances command input (SLC City Council)
const POLITICIAN_IDS: Record<string, string> = {
  'Victoria Petro': '7fa1fd18-c121-49e1-912a-67889f574f13',
  'Alejandro Puy': 'a404d8a7-9c7d-4c46-b6e6-ba713276e2bc',
  'Chris Wharton': '4736a4ec-b8b0-4faa-9528-c547493b5d5f',
  'Erika Carlsen': 'd0d3ef6a-2b8d-4df0-8553-9530a3963d83',
  'Dan Dugan': 'e386fec1-559d-4446-bb7e-daee4d2a014c',
  'Sarah Young': '83e3f56b-7db0-46b0-9a35-650867bcb48d',
};

type Row = {
  full_name: string;
  topic_key: string;
  value: string;
  reasoning: string;
  source_url_1: string;
  source_url_2: string;
  source_url_3: string;
};

const CSV = join(process.cwd(), 'data/stance-research/2026-05-31-slc-city-council.csv');
const rows = parse(readFileSync(CSV, 'utf8'), {
  columns: true,
  skip_empty_lines: true,
  relax_column_count: true,
}) as Row[];

// Resolve topic_key -> topic_id (live topics only)
const { rows: topicRows } = await pool.query<{ id: string; topic_key: string }>(
  `SELECT id, topic_key FROM inform.compass_topics WHERE is_live = true`
);
const TOPIC_ID = new Map(topicRows.map((t) => [t.topic_key, t.id]));

let answers = 0;
let contexts = 0;
const touched = new Set<string>();
const errors: string[] = [];

for (const r of rows) {
  const pid = POLITICIAN_IDS[r.full_name];
  const tid = TOPIC_ID.get(r.topic_key);
  if (!pid) { errors.push(`No politician_id for ${r.full_name}`); continue; }
  if (!tid) { errors.push(`No topic_id for ${r.topic_key} (${r.full_name})`); continue; }

  const value = Number(r.value);
  if (!(value >= 1 && value <= 5)) { errors.push(`Bad value ${r.value} ${r.full_name}/${r.topic_key}`); continue; }

  const sources = [r.source_url_1, r.source_url_2, r.source_url_3]
    .map((s) => s?.trim())
    .filter(Boolean);

  try {
    await pool.query(
      `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
       VALUES ($1, $2, $3)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
      [pid, tid, value]
    );
    answers++;

    await pool.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (politician_id, topic_id)
       DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [pid, tid, r.reasoning, sources]
    );
    contexts++;
    touched.add(pid);
    console.log(`OK ${r.full_name} / ${r.topic_key} = ${value}`);
  } catch (e: any) {
    errors.push(`${r.full_name}/${r.topic_key}: ${e.message}`);
  }
}

// Stamp last_stances_researched_at for every politician who got at least one stance
if (touched.size) {
  await pool.query(
    `UPDATE essentials.politicians SET last_stances_researched_at = NOW() WHERE id = ANY($1::uuid[])`,
    [[...touched]]
  );
}

console.log(`\nSUMMARY: answers=${answers} contexts=${contexts} stamped=${touched.size} errors=${errors.length}`);
if (errors.length) { errors.forEach((e) => console.log('  ERR ' + e)); process.exitCode = 1; }
await pool.end();
