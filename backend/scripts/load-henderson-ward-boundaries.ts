/**
 * load-henderson-ward-boundaries.ts
 *
 * Fetches the 4 City of Henderson council ward boundaries from the City of
 * Henderson GIS MapServer (OpenDataAdministrativeBoundaries, Layer 2) and
 * inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='henderson-nv-council-ward-1'..'-4',
 *                                   mtfcc='X0016', state='nv'
 *
 * Like load-lv-ward-boundaries.ts, this loader writes ONLY to
 * essentials.geofence_boundaries — it does NOT touch geo_districts.
 *
 * The Henderson MapServer (f=json) returns ArcGIS JSON (feature.geometry.rings),
 * so we convert rings to a GeoJSON Polygon before handing them to
 * ST_GeomFromGeoJSON.
 *
 * CRITICAL: resultRecordCount=100 is mandatory — the Henderson MapServer default
 * page size returns only 3 of the 4 wards.
 * CRITICAL: outSR=4326 is mandatory — the MapServer default spatial reference is
 * a projected CRS, which ST_GeomFromGeoJSON cannot consume as lon/lat.
 * CRITICAL: f=json (NOT f=geojson) — the layer returns ArcGIS rings, not GeoJSON.
 *
 * The Henderson WARD attribute is esriFieldTypeString ("1".."4"), NOT an integer
 * like LV — parseInt(String(...)) handles both. WARDNAME ("WARD I".."WARD IV")
 * is used as the geofence display name.
 *
 * Ward III carries 4 rings (multi-body); ST_Multi() wraps it, ST_IsValid is
 * asserted in the RETURNING clause, and an ST_MakeValid fallback re-runs any
 * ward that comes back invalid.
 *
 * ORCHESTRATION: running this script is an INLINE-ORCHESTRATOR step performed
 * by execute-phase (it reads C:/EV-Accounts/backend/.env DATABASE_URL). The
 * executor only writes this file to disk; it does NOT run the loader.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-henderson-ward-boundaries.ts --dry-run
 *   npx tsx scripts/load-henderson-ward-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// CRITICAL: resultRecordCount=100 required — Henderson default returns only 3 of 4 wards.
// CRITICAL: outSR=4326 required — Henderson MapServer default CRS is projected.
// CRITICAL: f=json (NOT f=geojson) — returns ArcGIS JSON rings, not GeoJSON.
const HENDERSON_WARD_URL =
  'https://maps.cityofhenderson.com/arcgis/rest/services/public/' +
  'OpenDataAdministrativeBoundaries/MapServer/2/query' +
  '?where=1%3D1&outFields=WARD,WARDNAME,COUNCILMAN' +
  '&returnGeometry=true&f=json&outSR=4326' +
  '&resultOffset=0&resultRecordCount=100';

const MTFCC          = 'X0016';    // Wave-0 confirmed unclaimed (next after X0015/LV)
const STATE_CODE     = 'nv';       // CRITICAL: lowercase — required for LOCAL-tier routing
const SOURCE         = 'cityofhenderson.com-arcgis-opendata-admin-boundaries-ward-2026';
const GEO_ID_PREFIX  = 'henderson-nv-council-ward-';
const EXPECTED_COUNT = 4;          // Henderson has 4 wards (LV had 6)

const DRY_RUN = process.argv.includes('--dry-run');

// ─── DB Pool ──────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

function fetchJson(url: string): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? https : http;
    lib.get(url, (res) => {
      if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return fetchJson(res.headers.location).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`HTTP ${res.statusCode} fetching ${url}`));
      }
      const chunks: Buffer[] = [];
      res.on('data', (c: Buffer) => chunks.push(c));
      res.on('end', () => {
        try { resolve(JSON.parse(Buffer.concat(chunks).toString('utf8'))); }
        catch (e) { reject(new Error(`JSON parse error: ${(e as Error).message}`)); }
      });
    }).on('error', reject);
  });
}

// ArcGIS JSON rings → GeoJSON Polygon string.
// The Henderson MapServer (f=json) returns feature.geometry.rings as number[][][]
// (an array of rings, each ring an array of [lon, lat] pairs). A GeoJSON
// Polygon's coordinates field has the identical shape, so the rings array
// passes through directly. ST_Multi (in the INSERT) wraps multi-body wards.
function arcgisRingsToGeoJson(rings: number[][][]): string {
  return JSON.stringify({ type: 'Polygon', coordinates: rings });
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-henderson-ward-boundaries] Fetching City of Henderson council ward boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const response = await fetchJson(HENDERSON_WARD_URL) as {
    features?: Array<{
      attributes: { WARD?: string | number; WARDNAME?: string; [key: string]: unknown };
      geometry: { rings: number[][][] };
    }>;
  };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from Henderson MapServer. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${response.features.length} features`);

  // Build ward map keyed by WARD number (feature.attributes.WARD, STRING "1".."4")
  const wardMap = new Map<number, { geoId: string; name: string; rings: number[][][] }>();

  for (const feature of response.features) {
    const attrs = feature.attributes || {};
    // Henderson WARD attribute is esriFieldTypeString ("1".."4"), not integer.
    // WARDNAME stores the Roman numeral display name ("WARD I".."WARD IV").
    const rawWard = attrs['WARD'] ?? attrs['WARDNAME'];
    const ward = parseInt(String(rawWard ?? ''), 10);
    if (isNaN(ward) || ward < 1 || ward > EXPECTED_COUNT) {
      console.warn(`  WARNING: WARD '${rawWard}' out of range — skipping`);
      continue;
    }
    const rings = feature.geometry?.rings;
    if (!Array.isArray(rings) || rings.length === 0) {
      console.warn(`  WARNING: ward ${ward} has no rings — skipping`);
      continue;
    }
    const geoId = `${GEO_ID_PREFIX}${ward}`;
    // wardName from WARDNAME field (e.g., "WARD I") — used as the geofence display name
    const wardName = String(attrs['WARDNAME'] ?? `Ward ${ward}`);
    wardMap.set(ward, { geoId, name: wardName, rings });
    const firstCoord = rings[0]?.[0];
    console.log(`  Ward ${ward}: rings=${rings.length} geo_id=${geoId} name="${wardName}" firstCoord=${JSON.stringify(firstCoord)}`);
  }

  if (wardMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} wards, got ${wardMap.size}. Aborting.`);
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    console.log('  (sanity check: first coords should be ~-115° lon, ~36° lat for Henderson, NV)');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;

  for (const [ward, { geoId, name, rings }] of Array.from(wardMap.entries()).sort((a, b) => a[0] - b[0])) {
    const geomJson = arcgisRingsToGeoJson(rings);

    // INSERT into geofence_boundaries (X0016, state='nv'); ST_Multi wraps multi-body wards.
    const result = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (id, geo_id, mtfcc, state, name, geometry, source)
       VALUES (gen_random_uuid(), $1, '${MTFCC}', '${STATE_CODE}', $2,
         public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)),
         $4)
       ON CONFLICT (geo_id, mtfcc) DO NOTHING
       RETURNING public.ST_GeometryType(geometry) AS gtype, public.ST_IsValid(geometry) AS valid`,
      [geoId, name, geomJson, SOURCE],
    );

    if ((result.rowCount ?? 0) === 0) {
      alreadyExists++;
      console.log(`  Ward ${ward} (${geoId}): skipped (already exists)`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean };
    if (row.valid !== true) {
      // ST_MakeValid fallback — re-run this ward through ST_MakeValid.
      // Ward III (Cox) has 4 rings — this path handles it identically to LV wards 4/5/6.
      console.error(`  Ward ${ward} (${geoId}): ST_IsValid=false (gtype=${row.gtype}) — applying ST_MakeValid`);
      await pool.query(
        `UPDATE essentials.geofence_boundaries
           SET geometry = public.ST_Multi(public.ST_MakeValid(
             public.ST_SetSRID(public.ST_GeomFromGeoJSON($2), 4326)))
         WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId, geomJson],
      );
      const recheck = await pool.query(
        `SELECT public.ST_IsValid(geometry) AS valid
           FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId],
      );
      if ((recheck.rows[0] as { valid: boolean })?.valid !== true) {
        console.error(`  ERROR: Ward ${ward} (${geoId}) still invalid after ST_MakeValid. Aborting.`);
        await pool.end();
        process.exit(1);
      }
      repaired++;
      console.log(`  Ward ${ward} (${geoId}): repaired via ST_MakeValid (now valid)`);
    } else {
      console.log(`  Ward ${ward} (${geoId}): inserted (${row.gtype}, valid)`);
    }
    inserted++;
  }

  await pool.end();

  console.log('\n=== Summary ===');
  console.log(`  geofence_boundaries inserted: ${inserted}`);
  console.log(`  geofence_boundaries already existed: ${alreadyExists}`);
  console.log(`  repaired via ST_MakeValid: ${repaired}`);

  console.log('\nVerify with:');
  console.log(`  SELECT COUNT(*), bool_and(public.ST_IsValid(geometry)) FROM essentials.geofence_boundaries WHERE state='nv' AND mtfcc='X0016'; -- expect (4, true)`);
}

main().catch((err) => {
  console.error('[load-henderson-ward-boundaries] Fatal error:', err);
  process.exit(1);
});
