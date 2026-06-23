/**
 * import-springfield-geofences.ts
 * Idempotently imports two boundaries into essentials.geofence_boundaries (SRID 4326) so
 * Springfield, MO officials surface in the location feed:
 *   - Springfield city place: FIPS 2970000, mtfcc G4110  (City Council — G4110 -> LOCAL/LOCAL_EXEC)
 *   - Springfield R-XII school district: FIPS 2928860, mtfcc G5420 (School Board -> SCHOOL)
 * Source polygons: Census TIGERweb (Places layer 4 / School layer 0), outSR=4326, fetched
 * 2026-06-23 — see sibling springfield-place-2970000.geojson + sps-school-2928860.geojson.
 * Run: node --import tsx scripts/import-springfield-geofences.ts
 */
import 'dotenv/config';
import { readFileSync } from 'fs';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const ITEMS = [
  { geo_id: '2970000', mtfcc: 'G4110', name: 'Springfield city', file: 'springfield-place-2970000.geojson',
    source: 'census-tigerweb:Places/4 GEOID=2970000' },
  { geo_id: '2928860', mtfcc: 'G5420', name: 'Springfield R-XII School District', file: 'sps-school-2928860.geojson',
    source: 'census-tigerweb:School/0 GEOID=2928860' },
];

async function main() {
  for (const it of ITEMS) {
    const exists = await pool.query(`SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc=$2`, [it.geo_id, it.mtfcc]);
    if (exists.rows.length) { console.log(`${it.geo_id}/${it.mtfcc} already present — skip.`); continue; }
    const gj = JSON.parse(readFileSync(`${import.meta.dirname}/${it.file}`, 'utf8'));
    const geom = JSON.stringify(gj.features[0].geometry);
    const r = await pool.query(`
      INSERT INTO essentials.geofence_boundaries (id, geo_id, mtfcc, state, name, geometry, source)
      VALUES (gen_random_uuid(), $1, $2, '29', $3,
              public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($4), 4326)), $5)
      RETURNING public.ST_GeometryType(geometry) AS gtype, public.ST_IsValid(geometry) AS valid`,
      [it.geo_id, it.mtfcc, it.name, geom, it.source]);
    console.log(`Inserted ${it.geo_id}/${it.mtfcc}:`, JSON.stringify(r.rows[0]));
  }
}
main().then(() => pool.end()).catch(e => { console.error(e); process.exit(1); });
