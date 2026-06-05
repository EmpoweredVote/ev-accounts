import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// Check specifically housing topic for McKinney politicians
const housing_topic = '669cac97-66a6-4087-b036-936fbe62efb3';
const res = await pool.query(`
  SELECT politician_id, topic_id, value FROM inform.politician_answers
  WHERE politician_id IN (
    '1c31b159-d4c1-4756-ba81-a247dbf0af8f',
    'c3e2d7a6-8096-4e91-9ee0-3cca445af72e',
    '23ba75d2-6eed-4b71-9669-78ab3bb82e98',
    'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723',
    '27578980-2e6c-4639-879a-70b510566d0f',
    '6ee726c1-79af-4fef-abb8-fa7f4208ae14'
  )
  AND topic_id = $1
  ORDER BY politician_id
`, [housing_topic]);
console.log('McKinney housing rows:', res.rows.length);
console.log(JSON.stringify(res.rows, null, 2));
await pool.end();
