import 'dotenv/config';
import pg from 'pg';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const sql = fs.readFileSync(path.join(__dirname, '../migrations/114_la_government_geo_ids.sql'), 'utf-8');

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await pool.query(sql);
console.log('Migration 114 applied.');

// Verify
const res = await pool.query(`SELECT name, geo_id FROM essentials.governments WHERE name ILIKE 'Los Angeles%' ORDER BY name`);
console.log('Verification:', JSON.stringify(res.rows, null, 2));
await pool.end();
