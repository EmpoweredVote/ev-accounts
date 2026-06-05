import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const faizahId = 'a9882d8b-b20d-4b0c-b509-c2883b4352e0';

// Check races columns
const raceCols = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_schema='essentials' AND table_name='races' ORDER BY ordinal_position`);
console.log('races columns:', raceCols.rows.map((r: any) => r.column_name));

// Check inform.compass_stances columns and a sample
const stanceCols = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_schema='inform' AND table_name='compass_stances' ORDER BY ordinal_position`);
console.log('inform.compass_stances columns:', stanceCols.rows.map((r: any) => r.column_name));

// Faizah's stances in inform.compass_stances
const stances = await pool.query(`
  SELECT cs.*, t.question
  FROM inform.compass_stances cs
  JOIN inform.compass_topics t ON t.id = cs.topic_id
  WHERE cs.politician_id = $1
`, [faizahId]);
console.log('Faizah compass stances:', JSON.stringify(stances.rows, null, 2));

// Also check essentials.politician_stances
const polStanceCols = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_schema='essentials' AND table_name='politician_stances' ORDER BY ordinal_position`);
console.log('essentials.politician_stances columns:', polStanceCols.rows.map((r: any) => r.column_name));

const polStances = await pool.query(`SELECT * FROM essentials.politician_stances WHERE politician_id = $1 LIMIT 5`, [faizahId]);
console.log('Faizah essentials.politician_stances:', JSON.stringify(polStances.rows, null, 2));

await pool.end();
