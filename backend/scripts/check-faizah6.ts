import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const faizahId = 'a9882d8b-b20d-4b0c-b509-c2883b4352e0';

// Check staging.stances by politician_external_id or politician_name
const stagingStances = await pool.query(`
  SELECT * FROM staging.stances
  WHERE politician_name ILIKE '%faizah%' OR politician_name ILIKE '%malik%'
  LIMIT 10
`);
console.log('Faizah staging.stances by name:', JSON.stringify(stagingStances.rows, null, 2));

// Check inform.compass_verdicts columns
const verdictCols = await pool.query(`SELECT column_name FROM information_schema.columns WHERE table_schema='inform' AND table_name='compass_verdicts' ORDER BY ordinal_position`);
console.log('inform.compass_verdicts columns:', verdictCols.rows.map((r: any) => r.column_name));

// Look for Faizah in compass_verdicts using politician_id or external_id
const sample = await pool.query(`SELECT * FROM inform.compass_verdicts LIMIT 2`);
console.log('Sample compass_verdicts:', JSON.stringify(sample.rows, null, 2));

await pool.end();
