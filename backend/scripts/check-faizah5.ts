import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const faizahId = 'a9882d8b-b20d-4b0c-b509-c2883b4352e0';

// Check essentials.politician_stances columns
const polStanceCols = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_schema='essentials' AND table_name='politician_stances' ORDER BY ordinal_position`);
console.log('essentials.politician_stances columns:', polStanceCols.rows.map((r: any) => r.column_name));

const polStances = await pool.query(`SELECT * FROM essentials.politician_stances WHERE politician_id = $1 LIMIT 10`, [faizahId]);
console.log('Faizah essentials.politician_stances:', JSON.stringify(polStances.rows, null, 2));

// Also check staging.stances
const stagingCols = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_schema='staging' AND table_name='stances' ORDER BY ordinal_position`);
console.log('staging.stances columns:', stagingCols.rows.map((r: any) => r.column_name));

const stagingStances = await pool.query(`SELECT * FROM staging.stances WHERE politician_id = $1 LIMIT 10`, [faizahId]);
console.log('Faizah staging.stances:', JSON.stringify(stagingStances.rows, null, 2));

// How does the API serve compass data - look for other schema tables
const verdictCols = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_schema='inform' AND table_name='compass_verdicts' ORDER BY ordinal_position`);
console.log('inform.compass_verdicts columns:', verdictCols.rows.map((r: any) => r.column_name));

const verdicts = await pool.query(`SELECT * FROM inform.compass_verdicts WHERE politician_id = $1 LIMIT 10`, [faizahId]);
console.log('Faizah compass_verdicts:', JSON.stringify(verdicts.rows, null, 2));

await pool.end();
