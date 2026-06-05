import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const faizahId = 'a9882d8b-b20d-4b0c-b509-c2883b4352e0';

// Check inform.politician_answers schema
const cols = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_schema='inform' AND table_name='politician_answers' ORDER BY ordinal_position`);
console.log('inform.politician_answers columns:', cols.rows.map((r: any) => r.column_name));

// Check Faizah's entries
const answers = await pool.query(`SELECT * FROM inform.politician_answers WHERE politician_id = $1`, [faizahId]);
console.log('Faizah answers count:', answers.rowCount);
console.log('Faizah answers:', JSON.stringify(answers.rows, null, 2));

// Also check Traci Park for comparison
const traciId = (await pool.query(`SELECT id FROM essentials.politicians WHERE full_name = 'Traci Park'`)).rows[0]?.id;
console.log('Traci Park id:', traciId);
const traciAnswers = await pool.query(`SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = $1`, [traciId]);
console.log('Traci Park answer count:', traciAnswers.rows[0].count);

// How many total politicians have answers?
const totalWithAnswers = await pool.query(`SELECT COUNT(DISTINCT politician_id) FROM inform.politician_answers WHERE value != 0`);
console.log('Total politicians with answers:', totalWithAnswers.rows[0].count);

await pool.end();
