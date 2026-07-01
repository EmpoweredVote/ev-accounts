/**
 * load-washco-commissioner-boundaries.ts
 *
 * Fetches the 4 Washington County commissioner district boundaries from the
 * official Washington County GIS FeatureServer (gispub.co.washington.or.us)
 * and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='washco-or-commissioner-district-1'..'-4',
 *                                   mtfcc='X0018', state='or'
 *
 * This loader writes ONLY to essentials.geofence_boundaries — it does NOT touch
 * essentials.districts or essentials.offices. The structural migration (1120)
 * creates the LOCAL district rows and offices that reference these geofences.
 *
 * The WashCo FeatureServer supports f=geojson natively (FeatureServer, not
 * MapServer), so feature.geometry is already a GeoJSON object — no rings
 * conversion helper is needed. Use JSON.stringify(feature.geometry) directly.
 *
 * CRITICAL: outSR=4326 is mandatory — ArcGIS default CRS is Oregon state plane
 * (a projected CRS), not WGS 84. Without outSR=4326, ST_GeomFromGeoJSON stores
 * wrong coordinates (~400,000 / ~100,000 range instead of ~-123 / ~45).
 * CRITICAL: f=geojson (NOT f=json) — returns a GeoJSON FeatureCollection directly.
 * CRITICAL: resultRecordCount=100 — defensive guard (Henderson needed it; WashCo has 4).
 * CRITICAL: state='or' lowercase — required for LOCAL-tier routing join key.
 *
 * The COMMDIST attribute (integer 1–4) is the key field. Features with COMMDIST
 * outside 1–4 are skipped with a warning (T-175-01 input-validation mitigation).
 *
 * ORCHESTRATION: running this script is an INLINE-ORCHESTRATOR step performed
 * by execute-phase (it reads C:/EV-Accounts/backend/.env DATABASE_URL). The
 * executor only writes this file to disk; it does NOT run the loader.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-washco-commissioner-boundaries.ts --dry-run
 *   npx tsx scripts/load-washco-commissioner-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// CRITICAL: f=geojson (NOT f=json) — WashCo FeatureServer returns GeoJSON directly.
// CRITICAL: outSR=4326 mandatory — ArcGIS default CRS is Oregon state plane, not WGS 84.
// CRITICAL: resultRecordCount=100 included as defensive measure.
const WASHCO_DISTRICT_URL =
  'https://gispub.co.washington.or.us/server/rest/services/BOC_CAO/' +
  'CoCommissioners/FeatureServer/0/query' +
  '?where=1%3D1&outFields=COMMDIST,NAME,Lastname,Firstname' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC          = 'X0018';   // Wave-0 confirmed unclaimed (next after X0017/NLV)
const STATE_CODE     = 'or';      // CRITICAL: lowercase — required for LOCAL-tier routing
const SOURCE         = 'washingtoncountyor.gov-gis-commissioner-districts-2026';
const GEO_ID_PREFIX  = 'washco-or-commissioner-district-';
const EXPECTED_COUNT = 4;

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

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-washco-commissioner-boundaries] Fetching Washington County commissioner district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  // WashCo f=geojson: response is a GeoJSON FeatureCollection.
  // feature.geometry is already a GeoJSON Polygon or MultiPolygon — no conversion needed.
  const response = await fetchJson(WASHCO_DISTRICT_URL) as {
    features?: Array<{
      properties: { COMMDIST?: number | string; NAME?: string; [key: string]: unknown };
      geometry: object;  // GeoJSON Polygon or MultiPolygon
    }>;
  };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from WashCo FeatureServer. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${response.features.length} features`);

  // Build district map keyed by integer COMMDIST (1–4).
  // T-175-01 mitigation: reject any COMMDIST outside 1–4 before forming geo_id.
  const distMap = new Map<number, { geoId: string; name: string; geomStr: string }>();

  for (const feature of response.features) {
    const rawDist = feature.properties['COMMDIST'];
    const dist = parseInt(String(rawDist ?? ''), 10);
    if (isNaN(dist) || dist < 1 || dist > EXPECTED_COUNT) {
      console.warn(`  WARNING: COMMDIST '${rawDist}' out of range — skipping`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING: district ${dist} has no geometry — skipping`);
      continue;
    }
    const geoId    = `${GEO_ID_PREFIX}${dist}`;
    const distName = String(feature.properties['NAME'] ?? `Commissioner District ${dist}`);
    // Already GeoJSON — no conversion needed (FeatureServer with f=geojson)
    const geomStr  = JSON.stringify(feature.geometry);
    distMap.set(dist, { geoId, name: distName, geomStr });
    console.log(`  COMMDIST ${dist}: geo_id=${geoId} name="${distName}"`);
  }

  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${distMap.size}. Aborting.`);
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    console.log('  (sanity check: first coords should be ~-123° lon, ~45° lat for Washington County, OR)');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;

  for (const [dist, { geoId, name, geomStr }] of Array.from(distMap.entries()).sort((a, b) => a[0] - b[0])) {
    // INSERT into geofence_boundaries (X0018, state='or'); ST_Multi wraps single- or multi-polygon.
    const result = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (id, geo_id, mtfcc, state, name, geometry, source)
       VALUES (gen_random_uuid(), $1, '${MTFCC}', '${STATE_CODE}', $2,
         public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)),
         $4)
       ON CONFLICT (geo_id, mtfcc) DO NOTHING
       RETURNING public.ST_GeometryType(geometry) AS gtype, public.ST_IsValid(geometry) AS valid`,
      [geoId, name, geomStr, SOURCE],
    );

    if ((result.rowCount ?? 0) === 0) {
      alreadyExists++;
      console.log(`  District ${dist} (${geoId}): skipped (already exists)`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean };
    if (row.valid !== true) {
      // ST_MakeValid fallback — re-run this district through ST_MakeValid.
      // Handles self-intersecting or multi-ring polygons identically to Henderson Ward III.
      console.error(`  District ${dist} (${geoId}): ST_IsValid=false (gtype=${row.gtype}) — applying ST_MakeValid`);
      await pool.query(
        `UPDATE essentials.geofence_boundaries
           SET geometry = public.ST_Multi(public.ST_MakeValid(
             public.ST_SetSRID(public.ST_GeomFromGeoJSON($2), 4326)))
         WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId, geomStr],
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
      console.log(`  District ${dist} (${geoId}): repaired via ST_MakeValid (now valid)`);
    } else {
      console.log(`  District ${dist} (${geoId}): inserted (${row.gtype}, valid)`);
    }
    inserted++;
  }

  await pool.end();

  console.log('\n=== Summary ===');
  console.log(`  geofence_boundaries inserted: ${inserted}`);
  console.log(`  geofence_boundaries already existed: ${alreadyExists}`);
  console.log(`  repaired via ST_MakeValid: ${repaired}`);

  console.log('\nVerify with:');
  console.log(`  SELECT COUNT(*), bool_and(public.ST_IsValid(geometry)) FROM essentials.geofence_boundaries WHERE state='or' AND mtfcc='X0018'; -- expect (4, true)`);
}

main().catch((err) => {
  console.error('[load-washco-commissioner-boundaries] Fatal error:', err);
  process.exit(1);
});
