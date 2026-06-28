/**
 * load-lv-ward-boundaries.ts
 *
 * Fetches the 6 City of Las Vegas council ward boundaries from the City of
 * Las Vegas GIS MapServer (AdministrativeBoundaries/CityCouncilWards, Layer 0)
 * and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='las-vegas-nv-council-ward-1'..'-6',
 *                                   mtfcc='X0015', state='nv'
 *
 * Unlike load-dc-ward-boundaries.ts, this loader writes ONLY to
 * essentials.geofence_boundaries — it does NOT touch geo_districts.
 *
 * The DC loader requests true GeoJSON via f=geojson; the LV MapServer instead
 * returns ArcGIS JSON (feature.geometry.rings) via f=json, so we convert rings
 * to a GeoJSON Polygon before handing them to ST_GeomFromGeoJSON.
 *
 * CRITICAL: outSR=4326 is mandatory — the LV MapServer default spatial
 * reference is WKID 3421 (NV state plane), which ST_GeomFromGeoJSON cannot
 * consume as lon/lat.
 * CRITICAL: f=json (NOT f=geojson) — the layer returns ArcGIS rings, not GeoJSON.
 *
 * Ward ring counts vary (Ward 1=4, 2=1, 3=2, 4=30, 5=21, 6=22): wards 4/5/6
 * carry many non-contiguous annexed parcels and enclaves. ST_Multi() wraps the
 * multi-body cases; ST_IsValid is asserted in the RETURNING clause and an
 * ST_MakeValid fallback re-runs any ward that comes back invalid.
 *
 * ORCHESTRATION: running this script is an INLINE-ORCHESTRATOR step performed
 * by execute-phase (it reads C:/EV-Accounts/backend/.env DATABASE_URL). The
 * executor only writes this file to disk; it does NOT run the loader.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-lv-ward-boundaries.ts --dry-run
 *   npx tsx scripts/load-lv-ward-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// CRITICAL: outSR=4326 required — LV MapServer default is WKID 3421 (state plane).
// CRITICAL: f=json (NOT f=geojson) — returns ArcGIS JSON rings, not GeoJSON.
const LV_WARD_URL =
  'https://mapdata.lasvegasnevada.gov/clvgis/rest/services/' +
  'AdministrativeBoundaries/CityCouncilWards/MapServer/0/query' +
  '?where=1%3D1&outFields=CLV_WARDS.WARD&returnGeometry=true&f=json&outSR=4326';

const MTFCC          = 'X0015';
const STATE_CODE     = 'nv';    // CRITICAL: lowercase — required for LOCAL-tier routing
const SOURCE         = 'lasvegasnevada.gov-gis-citcouncilwards-mapserver-2026';
const GEO_ID_PREFIX  = 'las-vegas-nv-council-ward-';
const EXPECTED_COUNT = 6;

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
// The LV MapServer (f=json) returns feature.geometry.rings as number[][][]
// (an array of rings, each ring an array of [lon, lat] pairs). A GeoJSON
// Polygon's coordinates field has the identical shape, so the rings array
// passes through directly. ST_Multi (in the INSERT) wraps multi-body wards.
function arcgisRingsToGeoJson(rings: number[][][]): string {
  return JSON.stringify({ type: 'Polygon', coordinates: rings });
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-lv-ward-boundaries] Fetching City of Las Vegas council ward boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const response = await fetchJson(LV_WARD_URL) as {
    features?: Array<{
      attributes: { WARD?: number; [key: string]: unknown };
      geometry: { rings: number[][][] };
    }>;
  };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from LV MapServer. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${response.features.length} features`);

  // Build ward map keyed by WARD number (feature.attributes.WARD, integer 1-6)
  const wardMap = new Map<number, { geoId: string; name: string; rings: number[][][] }>();

  for (const feature of response.features) {
    const attrs = feature.attributes || {};
    // ArcGIS prefixes outFields with the table name (CLV_WARDS.WARD); accept either form.
    const rawWard = attrs['WARD'] ?? attrs['CLV_WARDS.WARD'];
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
    const name = `Ward ${ward}`;
    wardMap.set(ward, { geoId, name, rings });
    const firstCoord = rings[0]?.[0];
    console.log(`  Ward ${ward}: rings=${rings.length} geo_id=${geoId} firstCoord=${JSON.stringify(firstCoord)}`);
  }

  if (wardMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} wards, got ${wardMap.size}. Aborting.`);
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    console.log('  (sanity check: first coords should be ~-115° lon, ~36° lat for Las Vegas, NV)');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;

  for (const [ward, { geoId, name, rings }] of Array.from(wardMap.entries()).sort((a, b) => a[0] - b[0])) {
    const geomJson = arcgisRingsToGeoJson(rings);

    // INSERT into geofence_boundaries (X0015, state='nv'); ST_Multi wraps multi-body wards.
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
  console.log(`  SELECT COUNT(*), bool_and(public.ST_IsValid(geometry)) FROM essentials.geofence_boundaries WHERE state='nv' AND mtfcc='X0015'; -- expect (6, true)`);
}

main().catch((err) => {
  console.error('[load-lv-ward-boundaries] Fatal error:', err);
  process.exit(1);
});
