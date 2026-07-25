/**
 * import-bend-geofences.ts
 * Idempotently imports the two boundaries Bend, OR needs that were NOT already loaded
 * (Bend place 4105800 / G4110 and Deschutes County 41017 / G4020 already exist from
 * census_tiger_2024):
 *   - Bend-La Pine Administrative School District 1: GEOID 4101980, mtfcc G5420 -> SCHOOL
 *   - Bend Metro Park & Recreation District: custom mtfcc X0024 -> LOCAL
 *     (X% MTFCCs join to LOCAL/COUNTY districts via the essentialsService fallback branch;
 *      X0024 is the next free code after X0023 = indio-ca-council-district)
 *
 * NOTE essentials.geofence_boundaries.state holds the state FIPS ('41'), not 'OR'.
 *
 * Source polygons (fetched 2026-07-24, outSR=4326), see sibling geojson files in
 * ../data/stance-research/bend-or/:
 *   - school: Census TIGERweb School/MapServer/0 GEOID=4101980
 *   - park:   Deschutes County GIS OpenData/BoundaryFD/MapServer/7 ("Tax Districts - Park"),
 *             NAME LIKE 'BEND METRO%' -> 2 esri features / 6 rings, converted to a 5-polygon
 *             MultiPolygon (one interior hole) by scripts-side shoelace orientation test.
 *
 * Run: node --import tsx scripts/import-bend-geofences.ts
 */
import 'dotenv/config';
import { readFileSync } from 'fs';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const DATA_DIR = `${import.meta.dirname}/../data/stance-research/bend-or`;

const ITEMS = [
  {
    geo_id: '4101980',
    mtfcc: 'G5420',
    name: 'Bend-La Pine Administrative School District 1',
    file: 'bendlapine-school-4101980.geojson',
    source: 'tiger_unsd_or_2024_bend',
  },
  {
    geo_id: 'bend-or-park-rec-district',
    mtfcc: 'X0024',
    name: 'Bend Metro Park & Recreation District',
    file: 'bprd-park-district.geojson',
    source: 'maps.deschutes.org-opendata-boundaryfd-mapserver7-park-2026',
  },
];

async function main() {
  for (const it of ITEMS) {
    const exists = await pool.query(
      `SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = $2`,
      [it.geo_id, it.mtfcc],
    );
    if (exists.rows.length) {
      console.log(`${it.geo_id}/${it.mtfcc} already present — skip.`);
      continue;
    }
    const gj = JSON.parse(readFileSync(`${DATA_DIR}/${it.file}`, 'utf8'));
    const geom = JSON.stringify(gj.features[0].geometry);
    const r = await pool.query(
      `INSERT INTO essentials.geofence_boundaries (id, geo_id, mtfcc, state, name, geometry, source)
       VALUES (gen_random_uuid(), $1, $2, '41', $3,
               public.ST_Multi(public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($4), 4326))), $5)
       RETURNING public.ST_GeometryType(geometry) AS gtype,
                 public.ST_IsValid(geometry) AS valid,
                 round((public.ST_Area(geometry::public.geography) / 2589988.11)::numeric, 2) AS sq_mi,
                 public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint(-121.3153, 44.0582), 4326)) AS covers_downtown_bend`,
      [it.geo_id, it.mtfcc, it.name, geom, it.source],
    );
    console.log(`Inserted ${it.geo_id}/${it.mtfcc}:`, JSON.stringify(r.rows[0]));
  }
}
main()
  .then(() => pool.end())
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
