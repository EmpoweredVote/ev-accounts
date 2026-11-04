/**
 * Exports the FIVE Holladay ward polygons exactly as they stand in production BEFORE CC_0319,
 * so the value that migration overwrites exists somewhere after it commits.
 *
 *   node --import ../../scripts/lib/main-checkout-fallback.mjs export-original-geometry.mjs
 *
 * 🔴 WHY THIS FILE EXISTS. CC_0319 rewrites `geofence_boundaries.geometry` for five rows. There is
 *    no history table for that column and no ordered runner to replay, so the moment it commits
 *    the previous value is gone. The inverse transform round-trips to within 3 nanometres, which
 *    is recoverable but NOT byte-exact — so the exact bytes are written here as well, with the
 *    MD5 CC_0319's header asserts against.
 *
 * ⚠ The coordinates in this file are EPSG:3857 metres stored under an SRID of 4326. That is the
 *   defect, preserved deliberately. Do not "fix" this file.
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';

const dir = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(`
  SELECT geo_id, name, state, mtfcc, source,
         ST_NPoints(geometry)                       AS npoints,
         ST_SRID(geometry)                          AS stored_srid,
         md5(ST_AsBinary(geometry)::text)           AS wkb_md5,
         ST_AsText(geometry)                        AS wkt,
         ST_XMin(geometry) AS xmin, ST_YMin(geometry) AS ymin,
         ST_XMax(geometry) AS xmax, ST_YMax(geometry) AS ymax
    FROM essentials.geofence_boundaries
   WHERE geo_id LIKE '%holladay%'
   ORDER BY geo_id`);
await pool.end();

if (rows.length !== 5) { console.error(`expected 5 rows, got ${rows.length}`); process.exit(1); }

const out = {
  captured: new Date().toISOString().slice(0, 10),
  what: 'Holladay UT city-council ward polygons as stored in production BEFORE CC_0319.',
  defect: 'Coordinates are EPSG:3857 (Web Mercator) metres, stored with an SRID of 4326 (WGS84 '
        + 'degrees). Preserved here exactly as-is; this file is the pre-image, not a corrected copy.',
  repair: 'CC_0319 applies ST_Transform(ST_SetSRID(geometry, 3857), 4326).',
  reverse: 'ST_SetSRID(ST_Transform(ST_SetSRID(geometry, 4326), 3857), 4326) — round-trips to '
         + 'within 3e-9 Mercator metres, i.e. recoverable but not byte-exact, which is why the '
         + 'WKT below is kept.',
  rows,
};
const file = path.join(dir, 'original-geometry-3857.json');
fs.writeFileSync(file, JSON.stringify(out, null, 2));
console.log(`wrote ${rows.length} rows -> ${path.basename(file)} (${(fs.statSync(file).size / 1024).toFixed(1)} KB)`);
for (const r of rows) console.log(`  ${r.geo_id}  npoints=${r.npoints}  md5=${r.wkb_md5}`);
