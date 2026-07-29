import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

// WI Racine-cluster stance push (2026-07-28/29): City of Racine, City of
// Burlington, Mount Pleasant, Caledonia, Wind Point, Sturtevant, Union Grove,
// Raymond, Yorkville, Waterford (village), Rochester, and the Towns of
// Burlington/Dover/Norway/Waterford. Evidence-only rows researched from
// candidate questionnaires (Racine County Eye, Journal Times), council/board
// minutes, and legislative records. North Bay and Elmwood Park yielded zero
// evidence rows (correct blank).
// Maps by politician_id (resolved from essentials.governments roster) to avoid
// name-variant mismatch.

const NAME_TO_ID: Record<string, string> = {
  // City of Racine
  'Cory Mason': '6cd02c2b-6bca-4b74-9703-0917872bf3f7',
  'Malik Frazier': 'c52c91ca-a08f-4b8b-a26e-7971a25b52a0',
  'Alyson Weiss': '21a99682-c016-4eb1-850b-3bf07818596d',
  'Olivia Turquoise Davis': '433fcd8d-29dd-44e9-8d99-5f5a2f72ca7b',
  'David L. Maack': '359c3243-f328-4cfd-b13a-0c319acf1b6d',
  'Jens Jorgensen': 'bc8463aa-5db8-41cd-a3cb-34608e9f9a7c',
  'Sandy Weidner': 'e13f9358-153f-4358-9f31-3238b05f71bb',
  'Maurice Horton': '47cdf9e8-d5f8-4cb3-aeab-8d8ef1be4909',
  'Brittany Hodges': '6bd87474-91f1-4381-bdfe-b54de0477497',
  'Grace Allen': '7cd80dd2-bbc6-4ae0-8445-b8688bf19c47',
  'Sam Peete': 'afcc665d-1d0a-4bc5-a681-b535801aa044',
  'Mary Land': 'a9762952-cb70-4546-8862-a4cba2137c1f',
  'Rocco DeMark': '144aea3e-8903-4a38-b509-d46cc0c47b21',
  'Renee Kelly': '6c040b24-d9cc-48ad-8271-3cfead5a6c5d',
  'Marlo Harmon': 'b9ff7e84-79b3-45a1-b9c6-b6b303771b14',
  'Nathan Pabon': '951d059a-0cf5-46ba-9eda-fb96cbe1da8b',
  // Village of Mount Pleasant
  'David DeGroot': '4bbafa07-020e-4f89-8a72-6f427d47c069',
  'David Karas': '397b57a0-6dfc-41fe-b39f-e42fe0e40f9c',
  'Gina Cefalu-Paulick': '1d3dabab-3ecf-46e0-8a5e-34be8a7d27b9',
  'Nancy Washburn': 'cf909d3f-2395-4a9e-856f-367302829ef5',
  'Denise Anastasio': 'a672a629-7be8-415d-8015-146b4e130685',
  'Ram Bhatia': 'd2fac01d-7489-4932-89e9-e3b0e3640fe7',
  'Jim Venturini': '99f0eae3-5f96-475a-b3c3-b4df2a7695fc',
  // City of Burlington
  'Jon Schultz': '8f00793e-5c19-485d-a3b0-cd7802157608',
  'Shad Branen': '92708732-1257-4f34-9df4-5a8516a0a1dd',
  'Bill Smitz': 'f51c85d1-88b2-4a44-8c68-0cd0e72bd2bd',
  'Tom Preusker': 'f64a25b4-cc2f-48fa-8910-dec51d8bcce9',
  // Village of Caledonia
  'Prescott Balch': '3ea2a666-643d-4518-b19c-81cd3f61fd34',
  'Nancy Pierce': 'b3243e2c-aa25-4be9-b5d1-2061765e0c80',
  'Fran Martin': '3b814fa0-c74e-4915-ae7a-ef826d3300d7',
  'Lee Wishau': '99fa1a17-73b4-418c-b8ac-a942f0c25f84',
  'Holly McManus': '3fa607ac-8824-4bb5-99a8-c5267c41af21',
  // Village of Wind Point
  'Alison McCulloch': 'a516a90f-8c5c-410b-8011-490176f0f423',
  'James Westfall': '0c71e9e8-139e-4354-9f77-8331c4803e72',
  'Charlie Manning': '77112407-ca98-4a56-835d-d113a60127b7',
  'Linda Johnson': 'fd680f3b-0be7-414a-a447-f6effa0e0ee6',
  'Carmen Gaspero': 'c66fa1df-72d8-4ba4-98ea-53e8f617759b',
  'Mary Kay Hall': 'f20f076e-c3cf-4979-9c5d-d63bb229af61',
  // Village of Sturtevant
  'Mike Rosenbaum': '4fa7daa6-2ac5-4b7d-b54c-f7bf0c47bbec',
  'Brittany Welch': '4165290d-132d-4063-93e7-facef421535b',
  'Janet Ruffolo': 'bea5a9c3-479a-490f-8efa-2e7c10e24e69',
  // Village of Union Grove
  'Steve Wicklund': '165d3a2e-5515-4a6e-8c5a-8e2caec579ba',
  // Village of Raymond
  'Douglas White': '9fc9a6c4-919f-4d31-b502-06cbd9d4b273',
  // Village of Yorkville
  'Douglas Nelson': '3c297787-e102-4678-b576-620a1e72ebec',
  // Village of Waterford
  'Adam Jaskie': 'ab035a52-9f7a-4a46-a1a0-f117bbf5bad4',
  'Robert Nash': 'f8fdd78f-8a74-4c70-991c-7f708604fbc2',
  'Pat Goldammer': '5531302c-c3e9-4ba3-9d55-c465e628a876',
  // Village of Rochester
  'Russ Kumbier': '1d77eab3-465c-4b0e-9cda-19d85400a18f',
  // Town of Burlington
  'Neal Czaplewski': 'e56b4563-2b84-452a-acb2-0be3ceba427e',
  'Jason Ketterhagen': '8a2ac0e8-cf73-4ebc-81e5-12e7ef804256',
  // Town of Dover
  'Sam Stratton': '45c30b1e-939b-4163-8bda-ffbb490b1dd2',
  // Town of Norway
  'Jean Jacobson': '4d88b3f6-462e-4d04-9128-d8888d777b80',
  // Town of Waterford
  'Tim Szeklinski': '19158249-4fd5-4d1f-9ee3-a9995e565600',
  'Robert Ulander': '6c14655c-5643-4f0e-8950-a53f60394bf7',
  'Andrew Handeland': 'c078112d-e77d-4caf-bec4-06d0b81827e8',
  'Bill McCormick': 'b0ead048-2752-40f5-b54f-eb0945f0e335',
  'Tom Mroczkowski': '8d78d1b6-3262-444b-a802-cf5ca62003b0',
};

type Row = {
  full_name: string; topic_key: string; value: string; reasoning: string;
  source_url_1: string; source_url_2: string; source_url_3: string;
};

const csvPath = join(process.cwd(), 'data/stance-research/2026-07-28-wi-racine-cluster.csv');
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
