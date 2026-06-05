import { pool } from '../src/lib/db.js';
const { rows } = await pool.query(`
  SELECT id, topic_key, title, short_title, question_text
  FROM inform.compass_topics
  WHERE is_live = true
  ORDER BY topic_key
`);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
