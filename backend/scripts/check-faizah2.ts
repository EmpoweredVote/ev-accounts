import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// Find compass table name
const tables = await pool.query(`
  SELECT table_name FROM information_schema.tables
  WHERE table_schema = 'essentials' AND table_name ILIKE '%compass%'
  ORDER BY table_name
`);
console.log('Compass tables:', tables.rows.map((r: any) => r.table_name));

// Find Faizah Malik's actual ID
const faizah = await pool.query(`
  SELECT p.id, p.full_name, p.office_id, p.is_active
  FROM essentials.politicians p
  WHERE p.full_name ILIKE '%faizah%'
`);
console.log('Faizah:', JSON.stringify(faizah.rows, null, 2));

// Check if there's a candidates table or race entries for her
const candidateTables = await pool.query(`
  SELECT table_name FROM information_schema.tables
  WHERE table_schema = 'essentials' AND table_name ILIKE '%candid%' OR
        (table_schema = 'essentials' AND table_name ILIKE '%race%') OR
        (table_schema = 'essentials' AND table_name ILIKE '%election%')
  ORDER BY table_name
`);
console.log('Election/candidate tables:', candidateTables.rows.map((r: any) => r.table_name));

// Check District 11 boundary in geofence_boundaries
const d11 = await pool.query(`
  SELECT geo_id, name, mtfcc FROM essentials.geofence_boundaries
  WHERE geo_id ILIKE '%council_district:11%' OR geo_id ILIKE '%los_angeles%'
  LIMIT 10
`);
console.log('District 11 geofence:', JSON.stringify(d11.rows, null, 2));

await pool.end();
