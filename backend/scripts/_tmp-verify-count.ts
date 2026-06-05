import 'dotenv/config';
import { pool } from '../src/lib/db.js';
const { rows } = await pool.query(`SELECT COUNT(*) as cnt FROM essentials.offices WHERE title='Indiana Elected Official'`);
console.log('Indiana Elected Official count:', rows[0].cnt);
await pool.end();
