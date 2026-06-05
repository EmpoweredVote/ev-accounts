import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const res = await pool.query(`SELECT id, name, type, geo_id FROM essentials.governments WHERE name ILIKE 'Los Angeles%' ORDER BY name`);
console.log(JSON.stringify(res.rows, null, 2));
await pool.end();
