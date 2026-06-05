import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// Check G6350 (council districts) for state 06 (California)
const g6350 = await pool.query(`
  SELECT geo_id, name, state, source FROM essentials.geofence_boundaries
  WHERE mtfcc = 'G6350' AND state = '06'
  LIMIT 20
`);
console.log('G6350 California:', JSON.stringify(g6350.rows, null, 2));

// Also check if there's any geo_id matching the pattern of LA council district
const ocd = await pool.query(`
  SELECT geo_id, name, mtfcc FROM essentials.geofence_boundaries
  WHERE geo_id ILIKE '%place:los_angeles%' OR geo_id ILIKE '%council_district%'
  LIMIT 10
`);
console.log('OCD council district entries:', JSON.stringify(ocd.rows, null, 2));

// Check the districts table for council districts with a G6350 mtfcc
const distCd = await pool.query(`
  SELECT d.geo_id, d.label, d.district_id, d.mtfcc, d.state, d.district_type
  FROM essentials.districts d
  WHERE d.geo_id ILIKE '%council_district%'
  LIMIT 5
`);
console.log('Council district rows in districts table:', JSON.stringify(distCd.rows, null, 2));

await pool.end();
