import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const rcId = '688dd4cd-8b75-4935-96a4-e0aec5b345f8';
const politicianId = '0f6484bd-2fc1-4071-9648-d7b8a950d29c';

// Check the full race_candidates row
const rc = await pool.query(`SELECT * FROM essentials.race_candidates WHERE id = $1`, [rcId]);
console.log('race_candidates row:', JSON.stringify(rc.rows, null, 2));

// Check the politician
const pol = await pool.query(`SELECT id, full_name, slug, is_active FROM essentials.politicians WHERE id = $1`, [politicianId]);
console.log('politician:', JSON.stringify(pol.rows, null, 2));

// Check fetchRaceCandidate API - what does the backend endpoint do?
// Look for what API endpoint serves race candidates
await pool.end();
