import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

// Madison WI stance push (2026-07-29): Mayor Rhodes-Conway + all 20 alders.
// Evidence-only rows from Cap Times / WSJ 2025 spring-election Q&As, Isthmus,
// Madison365, WORT, campaign platforms, and city records. Run with:
//   npx tsx --env-file=.env scripts/apply-madison-stances.ts

const NAME_TO_ID: Record<string, string> = {
  'Satya Rhodes-Conway': '37505cfb-0a31-43d3-9154-c56963036311',
  'John W. Duncan': 'cd1b447a-2193-4e90-86a6-77fcccdcd4bf',
  'Will Ochowicz': '1512eb0b-df87-4288-a598-0212d5520d02',
  'Derek Field': '3b1c5861-8c9c-4360-84f8-099ab1835df4',
  'Michael E. Verveer': 'c7ee1c03-63d7-4107-b076-72b1f059b0f7',
  'Regina M. Vidaver': '927ed263-d3f6-4222-829a-e60146ee627a',
  'Davy Mayer': '188c6816-2e22-433a-8bff-fc020ca2da0e',
  'Badri Lankella': '86c3a5c2-cf35-49e5-b329-ca811712fb7b',
  'Ellen Zhang': '9ba2fd8c-7c37-474b-b05c-41ce75d00ca8',
  'Joann Pritchett': '9bd09271-c3ca-4fc2-a573-c1f16455e37b',
  'Yannette Figueroa Cole': 'f29c9754-363f-48ad-96f4-5773d2a29aa3',
  'Bill Tishler': '77796735-bc75-40f8-baea-5263a027df09',
  'Julia Matthews': '07fd1bbc-a95d-4f85-8d24-67e8f2e0ef3a',
  'Tag Evers': '10e69d7b-dc44-4c93-bcdf-53c778b9ffcc',
  'Noah L. Lieberman': '907f798a-e4db-4130-8a9b-80c99818f007',
  'Dina Nina Martinez-Rutherford': 'ac7636a5-edf2-4f32-b712-1fdd5a8909f9',
  "Sean O'Brien": '6ced47ca-3da5-4ca4-a828-953c41aa5229',
  'Sabrina V. Madison': 'baf31b38-4e8a-40d9-880d-a164a43c4bc4',
  'Carmella Glenn': '6651ce10-36f8-4d46-a584-b268fd8c52eb',
  'John P. Guequierre': '741070fb-a565-4b5f-af70-312733956cbb',
  'Barbara Harrington-McKinney': 'a7dcaafd-75fa-43d7-b400-65a077cedb5b',
};

type Row = {
  full_name: string; topic_key: string; value: string; reasoning: string;
  source_url_1: string; source_url_2: string; source_url_3: string;
};

const csvPath = join(process.cwd(), 'data/stance-research/2026-07-29-wi-madison.csv');
const rows = parse(readFileSync(csvPath, 'utf8'), {
  columns: true, skip_empty_lines: true, relax_column_count: true, bom: true,
}) as Row[];

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
  if (!Number.isInteger(value) || value < 1 || value > 5) {
    errors.push(`${r.full_name}/${r.topic_key}: bad value "${r.value}"`);
    continue;
  }
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

if (stampedIds.size > 0) {
  await pool.query(
    'UPDATE essentials.politicians SET last_stances_researched_at = NOW() WHERE id = ANY($1::uuid[])',
    [[...stampedIds]]
  );
}

console.log(`rows parsed: ${rows.length}`);
console.log(`answers upserted: ${answers}`);
console.log(`context upserted: ${contexts}`);
console.log(`politicians stamped: ${stampedIds.size}`);
console.log(`errors: ${errors.length}`);
errors.forEach(e => console.log('  ' + e));
if (errors.length) process.exitCode = 1;
await pool.end();
