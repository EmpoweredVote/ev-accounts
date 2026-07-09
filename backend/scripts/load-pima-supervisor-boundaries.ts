/**
 * load-pima-supervisor-boundaries.ts
 *
 * Fetches the 5 Pima County Board of Supervisors district boundaries from the
 * county's ArcGIS MapServer (GISOpenData/Boundaries, Layer 5) and inserts them
 * into:
 *
 *   essentials.geofence_boundaries  geo_id='pima-az-supervisor-district-1'..'-5',
 *                                   mtfcc='X0019', state='az'
 *
 * Like load-lv-ward-boundaries.ts, this loader writes ONLY to
 * essentials.geofence_boundaries — it does NOT touch essentials.districts or
 * any government/office table. The pre-existing whole-county COUNTY row
 * (geo_id='04019') is untouched.
 *
 * Pima's endpoint is an ArcGIS MapServer (NOT a FeatureServer), so f=json
 * returns ArcGIS JSON (feature.geometry.rings), NOT GeoJSON. We convert rings
 * to a GeoJSON Polygon before handing them to ST_GeomFromGeoJSON. (The GeoJSON
 * output format is not available on a MapServer — do not request it.)
 *
 * CRITICAL: outSR=4326 is mandatory — the Pima MapServer native spatial
 * reference is SRID 2868 (AZ State Plane). Without outSR=4326 the coordinates
 * come back in state-plane units and store as garbage that never matches an
 * address (RESEARCH Pitfall 1).
 * CRITICAL: use f=json — the layer returns ArcGIS rings, not GeoJSON.
 * CRITICAL: state='az' lowercase — required for LOCAL-tier routing join key
 * (RESEARCH Pitfall 3).
 *
 * The 5 features are all single-ring (RESEARCH confirmed), so the ST_MakeValid
 * fallback is unlikely to trigger, but it is kept verbatim as defensive
 * insurance. All 5 districts must be present: a shortfall is a hard failure
 * (D-01 PAUSE+flag — never silently load a partial set).
 *
 * ORCHESTRATION: running this script is an INLINE-ORCHESTRATOR step performed
 * by execute-phase (it reads C:/EV-Accounts/backend/.env DATABASE_URL). The
 * executor only writes this file to disk; it does NOT run the loader.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-pima-supervisor-boundaries.ts --dry-run
 *   npx tsx scripts/load-pima-supervisor-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// CRITICAL: outSR=4326 required — Pima MapServer native SRID is 2868 (AZ State Plane).
// CRITICAL: use f=json — returns ArcGIS JSON rings, not GeoJSON.
const PIMA_SUPERVISOR_URL =
  'https://gisdata.pima.gov/arcgis1/rest/services/' +
  'GISOpenData/Boundaries/MapServer/5/query' +
  '?where=1%3D1&outFields=DISTRICT,NAME&returnGeometry=true&f=json&outSR=4326';

const MTFCC          = 'X0019';   // next unused X-code (outside excluded routing range, above WashCo)
const STATE_CODE     = 'az';      // CRITICAL: lowercase — required for LOCAL-tier routing
const SOURCE         = 'gisdata.pima.gov-boundaries-mapserver5-2026';
const GEO_ID_PREFIX  = 'pima-az-supervisor-district-';
const EXPECTED_COUNT = 5;

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
// The Pima MapServer (f=json) returns feature.geometry.rings as number[][][]
// (an array of rings, each ring an array of [lon, lat] pairs). A GeoJSON
// Polygon's coordinates field has the identical shape, so the rings array
// passes through directly. ST_Multi (in the INSERT) wraps multi-body cases.
function arcgisRingsToGeoJson(rings: number[][][]): string {
  return JSON.stringify({ type: 'Polygon', coordinates: rings });
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-pima-supervisor-boundaries] Fetching Pima County Board of Supervisors district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const response = await fetchJson(PIMA_SUPERVISOR_URL) as {
    features?: Array<{
      attributes: { DISTRICT?: number | string; NAME?: string; [key: string]: unknown };
      geometry: { rings: number[][][] };
    }>;
  };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from Pima MapServer. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${response.features.length} features`);

  // Build district map keyed by DISTRICT number (feature.attributes.DISTRICT, integer 1-5).
  // Input-validation (T-193-SQLI defense-in-depth): reject any DISTRICT outside 1-5 before forming geo_id.
  const distMap = new Map<number, { geoId: string; name: string; rings: number[][][] }>();

  for (const feature of response.features) {
    const attrs = feature.attributes || {};
    const rawDist = attrs['DISTRICT'];
    const dist = parseInt(String(rawDist ?? ''), 10);
    if (isNaN(dist) || dist < 1 || dist > EXPECTED_COUNT) {
      console.warn(`  WARNING: DISTRICT '${rawDist}' out of range — skipping`);
      continue;
    }
    const rings = feature.geometry?.rings;
    if (!Array.isArray(rings) || rings.length === 0) {
      console.warn(`  WARNING: district ${dist} has no rings — skipping`);
      continue;
    }
    const geoId = `${GEO_ID_PREFIX}${dist}`;
    const name = String(attrs['NAME'] ?? `Supervisor District ${dist}`);
    distMap.set(dist, { geoId, name, rings });
    const firstCoord = rings[0]?.[0];
    console.log(`  DISTRICT ${dist}: rings=${rings.length} geo_id=${geoId} name="${name}" firstCoord=${JSON.stringify(firstCoord)}`);
  }

  // D-01 PAUSE+flag: never silently load a partial set. A shortfall is a hard failure.
  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} supervisor districts, got ${distMap.size}. Aborting (D-01 PAUSE+flag — never load a partial set).`);
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    console.log('  (sanity check: first coords should be ~-110° lon, ~32° lat for Pima County / Tucson, AZ)');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;

  for (const [dist, { geoId, name, rings }] of Array.from(distMap.entries()).sort((a, b) => a[0] - b[0])) {
    const geomJson = arcgisRingsToGeoJson(rings);

    // INSERT into geofence_boundaries (X0019, state='az'); ST_Multi wraps single- or multi-body districts.
    // T-193-SQLI: all GIS attribute/geometry values pass as bind params ($1 geo_id / $2 name / $3 GeoJSON / $4 source)
    // — never string-concatenate GIS response data into SQL.
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
      const firstCoord = rings[0]?.[0];
      console.log(`  District ${dist} (${geoId}, "${name}"): skipped (already exists) firstCoord=${JSON.stringify(firstCoord)}`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean };
    const firstCoord = rings[0]?.[0];
    if (row.valid !== true) {
      // ST_MakeValid fallback — re-run this district through ST_MakeValid.
      // Pima's single-ring geometry is unlikely to trigger this, but kept as defensive insurance.
      console.error(`  District ${dist} (${geoId}): ST_IsValid=false (gtype=${row.gtype}) — applying ST_MakeValid`);
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
        console.error(`  ERROR: District ${dist} (${geoId}) still invalid after ST_MakeValid. Aborting.`);
        await pool.end();
        process.exit(1);
      }
      repaired++;
      console.log(`  District ${dist} (${geoId}, "${name}"): repaired via ST_MakeValid (now valid) firstCoord=${JSON.stringify(firstCoord)}`);
    } else {
      console.log(`  District ${dist} (${geoId}, "${name}"): inserted (${row.gtype}, ST_IsValid=true) firstCoord=${JSON.stringify(firstCoord)}`);
    }
    inserted++;
  }

  await pool.end();

  console.log('\n=== Summary ===');
  console.log(`  geofence_boundaries inserted: ${inserted}`);
  console.log(`  geofence_boundaries already existed: ${alreadyExists}`);
  console.log(`  repaired via ST_MakeValid: ${repaired}`);

  console.log('\nVerify with:');
  console.log(`  SELECT COUNT(*), bool_and(public.ST_IsValid(geometry)) FROM essentials.geofence_boundaries WHERE state='az' AND mtfcc='X0019'; -- expect (5, true)`);
}

main().catch((err) => {
  console.error('[load-pima-supervisor-boundaries] Fatal error:', err);
  process.exit(1);
});
