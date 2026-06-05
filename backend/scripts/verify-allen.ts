import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const res = await pool.query(`
  SELECT politician_id, topic_id, value FROM inform.politician_answers
  WHERE politician_id IN (
    'c7a0ecf6-b416-474b-9647-a25e404f4bc4',
    '3e616ef8-0ca7-4171-8d73-2cbb61d696f6'
  )
  AND topic_id IN (
    '669cac97-66a6-4087-b036-936fbe62efb3',
    'f7e5678d-dadd-4556-a2fc-446e24642ceb'
  )
  ORDER BY politician_id, topic_id
`);
console.log('Allen rows:', res.rows.length);
console.log(JSON.stringify(res.rows, null, 2));
await pool.end();
