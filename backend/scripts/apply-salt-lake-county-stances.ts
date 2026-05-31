import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

// research-stances push for Salt Lake County officials (2026-05-30).
// Maps by politician_id (resolved in STEP 0) to avoid name-variant mismatch
// (CSV "Carlos Moreno" vs DB "Carlos A. Moreno").

const NAME_TO_ID: Record<string, string> = {
  'Aimee Winder Newton': '13752a3e-8159-4569-ac16-3736c16c96be',
  'Carlos Moreno': 'd077198d-0013-420d-9603-81cf6f2e7316',
  'Carlos A. Moreno': 'd077198d-0013-420d-9603-81cf6f2e7316',
  'Dea Theodore': 'dd90ac18-7613-4a2f-bfc1-2eddfebb4daf',
  'Jiro Johnson': '261b4428-3b92-4d3f-a013-00c4b10a7925',
  'Laurie Stringham': '9519acd5-1df8-48af-a6fb-0d40ed02c94d',
  'Natalie Pinkney': '63534729-c022-4305-bef1-e29d4464f719',
  'Ross Romero': '2ec55690-4c8a-4e9e-934b-f0f945947721',
  'Sheldon Stewart': 'bc7cdf2d-2ee7-404f-b6be-286bf4252dc5',
  'Suzanne Harrison': 'f414070c-662c-4cf9-a7d2-28a642a3fd03',
  'Jenny Wilson': '1e25123b-7f6c-47c3-b597-bbd626c185ae',
  'Rosie Rivera': '8c34f0b8-4201-49b4-95a2-d043e99a3eef',
  'Sim Gill': '77256186-0ce8-4069-9d06-1d2fd5b4b622',
};

type Row = {
  full_name: string; topic_key: string; value: string; reasoning: string;
  source_url_1: string; source_url_2: string; source_url_3: string;
};

const csvPath = join(process.cwd(), 'data/stance-research/2026-05-30-salt-lake-county.csv');
const rows = parse(readFileSync(csvPath, 'utf8'), {
  columns: true, skip_empty_lines: true, relax_column_count: true,
}) as Row[];

// Resolve topic_key -> topic_id for live topics
const { rows: topics } = await pool.query(
  "SELECT id, topic_key FROM inform.compass_topics WHERE is_live = true"
);
const topicMap = new Map<string, string>(topics.map((t: any) => [t.topic_key, t.id]));

let answers = 0, contexts = 0;
const errors: string[] = [];
const stampedIds = new Set<string>();

for (const r of rows) {
  const politicianId = NAME_TO_ID[r.full_name.trim()];
  const topicId = topicMap.get(r.topic_key.trim());
  if (!politicianId) { errors.push(`No politician_id for "${r.full_name}"`); continue; }
  if (!topicId) { errors.push(`No topic_id for "${r.topic_key}"`); continue; }

  const value = Number(r.value);
  const sources = [r.source_url_1, r.source_url_2, r.source_url_3]
    .map(s => s?.trim()).filter(Boolean);

  try {
    await pool.query(
      `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
       VALUES ($1, $2, $3)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
      [politicianId, topicId, value]
    );
    answers++;
    await pool.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (politician_id, topic_id)
       DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [politicianId, topicId, r.reasoning, sources]
    );
    contexts++;
    stampedIds.add(politicianId);
  } catch (e: any) {
    errors.push(`${r.full_name}/${r.topic_key}: ${e.message}`);
  }
}

// Stamp last_stances_researched_at for every politician with >=1 upsert
if (stampedIds.size > 0) {
  await pool.query(
    'UPDATE essentials.politicians SET last_stances_researched_at = NOW() WHERE id = ANY($1::uuid[])',
    [[...stampedIds]]
  );
}

console.log(`answers upserted: ${answers}`);
console.log(`context upserted: ${contexts}`);
console.log(`politicians stamped: ${stampedIds.size}`);
console.log(`errors: ${errors.length}`);
errors.forEach(e => console.log('  ' + e));
if (errors.length) process.exitCode = 1;
await pool.end();
