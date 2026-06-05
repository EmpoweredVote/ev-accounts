import { pool } from '../src/lib/db.js';
const politicianId = process.argv[2];
const { rows } = await pool.query(
  `SELECT COUNT(*) as cnt FROM inform.politician_answers WHERE politician_id = $1`,
  [politicianId]
);
console.log(`Stances in DB for ${politicianId}: ${rows[0].cnt}`);
await pool.end();
