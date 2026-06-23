/**
 * import-greene-county-geofence.ts
 * Idempotently imports the Greene County, MO (FIPS 29077) boundary into
 * essentials.geofence_boundaries as a G4020 (county) polygon, SRID 4326, so the
 * county's officials surface in the location-based feed (ST_Covers + MTFCC map).
 * Source polygon: Census TIGERweb State_County layer 1, GEOID=29077 (see the
 * sibling greene-county-29077.geojson, fetched 2026-06-23, outSR=4326).
 * Run: node --import tsx scripts/import-greene-county-geofence.ts
 */
import 'dotenv/config';
import { readFileSync } from 'fs';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

async function main() {
  const gj = JSON.parse(readFileSync(`${import.meta.dirname}/greene-county-29077.geojson`, 'utf8'));
  const geom = JSON.stringify(gj.features[0].geometry);
  const exists = await pool.query(`SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='29077' AND mtfcc='G4020'`);
  if (exists.rows.length) { console.log('Greene County 29077/G4020 geofence already present — no-op.'); return; }
  const r = await pool.query(`
    INSERT INTO essentials.geofence_boundaries (id, geo_id, mtfcc, state, name, geometry, source)
    VALUES (gen_random_uuid(), '29077', 'G4020', '29', 'Greene County',
            public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1), 4326)),
            'census-tigerweb:State_County/1 GEOID=29077')
    RETURNING id, public.ST_GeometryType(geometry) AS gtype, public.ST_IsValid(geometry) AS valid`, [geom]);
  console.log('Inserted Greene County geofence:', JSON.stringify(r.rows[0]));
}
main().then(() => pool.end()).catch(e => { console.error(e); process.exit(1); });
