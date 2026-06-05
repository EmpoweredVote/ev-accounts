import 'dotenv/config';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// All LA-related geofence boundaries
const res = await pool.query(`
  SELECT geo_id, name, mtfcc, state, source,
         ST_IsValid(geometry) as valid,
         ST_GeometryType(geometry) as geom_type
  FROM essentials.geofence_boundaries
  WHERE name ILIKE '%los angeles%'
     OR geo_id ILIKE '%los_angeles%'
     OR (state = '06' AND mtfcc ILIKE 'G6%')
  ORDER BY mtfcc, name
`);
console.log('LA geofence boundaries:', JSON.stringify(res.rows, null, 2));

// Also check what mtfcc values exist in geofence_boundaries
const mtfcc = await pool.query(`
  SELECT mtfcc, COUNT(*) as cnt FROM essentials.geofence_boundaries GROUP BY mtfcc ORDER BY cnt DESC
`);
console.log('All mtfcc values:', JSON.stringify(mtfcc.rows, null, 2));

await pool.end();
