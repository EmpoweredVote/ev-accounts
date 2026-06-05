import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const res = await pool.query(`
  SELECT p.full_name, t.topic_key, pa.value
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  JOIN inform.compass_topics t ON t.id = pa.topic_id
  WHERE pa.politician_id IN (
    'da010ea4-257d-4582-98cb-ee90063aa31d',
    '5b346b19-d6ee-47e2-acbf-5780ca423264',
    'c11bf372-8190-4b45-b80a-cbd0fb2ba401',
    '76c3fa35-a286-4fa1-b6da-40300d91f33e',
    'b39524df-ef91-48dc-a1a8-1880c271bd7c',
    'ac1ed3c9-db6c-4931-bc55-4d53c6c81b35',
    'e9b9877d-c4dc-482e-b52a-cd015a4a6850'
  )
  ORDER BY p.full_name, t.topic_key
`);

console.log('Total rows:', res.rows.length);
res.rows.forEach(r => console.log(`${r.full_name} | ${r.topic_key} | ${r.value}`));
await pool.end();
