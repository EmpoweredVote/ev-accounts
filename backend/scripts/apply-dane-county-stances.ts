import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

// Dane County WI stance push (2026-07-29): county executive + row officers + County Board.
// Evidence-only rows from WisPolitics, Cap Times, WPR, Madison365, Channel3000, county press
// releases, Legistar records, and campaign sites. Judges are out of scope (judicial compass is
// a separate design). Run with:
//   npx tsx --env-file=.env scripts/apply-dane-county-stances.ts

const NAME_TO_ID: Record<string, string> = {
  // countywide
  'Melissa Agard': 'd0f404ea-5074-4f6b-b87f-83bf20294ae8',
  'Scott McDonell': '08555a95-9b5a-40cf-982f-88d4fd9c47d3',
  'Adam Gallagher': '9ce325b4-5f8a-4182-9ee0-e83993bd4dd7',
  'Kristi Chlebowski': 'f625b721-0bd5-413e-83ad-45f2c8a9d439',
  'Kalvin D. Barrett': '24b26b30-e763-4b18-a422-b3e1b321ffaa',
  'Ismael R. Ozanne': 'a8a4a392-37c8-470a-a389-889f4f41911e',
  'Jeff Okazaki': '1b6b526e-ffe6-45b6-9c74-8f929a6aa4e1',
  // County Board, D1-D37
  'Colin Barushok': '3e43448d-b2de-42ee-b4b1-54f05c5f92be',
  'Heidi Wegleitner': '0adaafe7-d821-4eaf-8fb6-f934adeb11e6',
  'Analiese Eicher': '184ffdfb-7026-4d65-8916-3bc31bf14d2a',
  'Matt Veldran': '1b2c1f20-db03-49a9-9571-b64a1a04d856',
  'Henry Fries': '538155a9-784c-43e7-ac8d-fc012fb98654',
  'Yogesh Chawla': 'c442e47e-8f45-4e63-b130-72f920226209',
  'Erin Welsh': '194fe3b3-4648-4c05-af61-7574249b2822',
  'Jeffrey Glazer': 'ddd5628a-2b8e-4279-9379-75d1444df3bf',
  'Aria Trucios': '8c393cfe-0b4b-4512-8bc4-b95f266c30a0',
  'Keith Furman': 'da4e453f-3417-4b2e-b2d0-58322b9345b8',
  'Richelle Andrae': '85f785f3-08c3-4d80-ba9a-96b81be758c0',
  'Tommy Rylander': 'b31007df-0b71-42ae-b4dd-d897e502c372',
  'Jay Brower': '68e65a7c-8b61-4c6b-8016-2732daf2ff15',
  'Anthony Gray': '9b8d7e73-9185-4365-85d2-3ca2889fbdc6',
  'Amy Larson': 'a05002ce-6e0d-4e6a-9fa1-5bc54ac92042',
  'Goodwill Obieze': 'c2c9fde2-8a99-4d59-88ea-0b8910a3fce0',
  'Dan Blazewicz': 'e36cb175-2fa4-4cbf-b329-4e7ed159e63e',
  'Michele Ritt': '7c4bcaeb-b38e-416c-89ed-a2965f875674',
  'Brenda Yang': 'bf7c9921-6711-4d56-b7d8-a98ed1199931',
  'Paula Brandmeier': '1c940fd9-14fe-4666-ba45-c4a862c2cbf7',
  'Jeffrey Kroning': '379fca24-7658-4683-a1b2-06371177d9d7',
  'Gussie Lewis': '6946870d-9319-4a9e-8762-4dd7bc4df3c9',
  'Chuck Erickson': '3b74fd16-420b-4a13-9252-393fef2fdf22',
  'Sarah Smith': '100f6747-cd59-4e08-b021-0d4c853ce99c',
  'David Boetcher': '7748ffef-2ed8-4cd0-8914-a7fd0c1737b9',
  'Lisa Jackson': '560d30c0-6904-4a3e-a4c5-4294d5ff87dd',
  'Kierstin Huelsemann': 'a7d28222-72e6-4fb5-befd-74b6ef664cd0',
  'Michele Doolan': 'b47b26a2-ef64-42d2-b3e8-d076d4ecd1df',
  'Don Postler': '27033804-17b9-4aed-9d27-e6b31d2ada80',
  'Patrick Downing': '1ff55ff7-c617-42cf-864e-a0d788815c43',
  'Jerry Bollig': '13ebfaf6-3fc1-4448-a034-8b6bb6eade65',
  'Chad Kemp': 'fc67428c-f769-47ca-9004-0f68bc917409',
  'Donald D. Dantzler, Jr.': '766208bb-6ecd-4382-ae66-b703c80c1a14',
  'Patrick Miles': 'ee52f7fe-8923-4ac7-85b4-7bd9ea68389c',
  'Michael Engelberger': '86da37db-5df9-43ad-ae54-fa2273ed3cb0',
  'David Peterson': '26e2d1ad-130f-4794-83e9-82b341644cc9',
  'Kerry Marren': '5587e9e4-0bfe-40d7-97a0-5a736fd7b5b7',
};

type Row = {
  full_name: string; topic_key: string; value: string; reasoning: string;
  source_url_1: string; source_url_2: string; source_url_3: string;
};

const csvPath = join(process.cwd(), 'data/stance-research/2026-07-29-wi-dane-county.csv');
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
