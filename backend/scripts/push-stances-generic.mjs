// Generic stance push script — called with: node push-stances-generic.mjs <json-file>
import { pool } from '../src/lib/db.js';
import { readFileSync } from 'fs';

const { politician_id, stances } = JSON.parse(readFileSync(process.argv[2], 'utf8'));

for (const s of stances) {
  await pool.query(
    `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
     VALUES ($1, $2, $3)
     ON CONFLICT (politician_id, topic_id)
     DO UPDATE SET value = EXCLUDED.value`,
    [politician_id, s.topic_id, s.value]
  );
  await pool.query(
    `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (politician_id, topic_id)
     DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
    [politician_id, s.topic_id, s.reasoning, s.sources]
  );
  console.log(`OK: ${s.topic_key} = ${s.value}`);
}

console.log(`\nDone: ${stances.length} stances upserted`);
await pool.end();
