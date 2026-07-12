/**
 * load-riverside-supervisor-boundaries.ts
 *
 * Fetches the 5 Riverside County Board of Supervisors district boundaries from
 * the official Riverside County GIS ArcGIS OpenData service
 * (gis.countyofriverside.us) and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='riverside-ca-supervisor-district-1'..'-5',
 *                                   mtfcc='X0021', state='ca'
 *
 * This loader writes ONLY to essentials.geofence_boundaries — it does NOT touch
 * essentials.districts or essentials.offices. The structural migration (Plan 02)
 * creates the LOCAL district rows and offices that reference these geofences, and
 * refuses to apply until 5 valid X0021 rows exist here (pre-flight gate).
 *
 * The Riverside OpenData endpoint (`OpenData/SupervisorialDistricts/MapServer/0`)
 * returns a GeoJSON FeatureCollection directly when queried with f=geojson — no
 * ArcGIS-rings conversion helper is needed (matches LA County / WashCo, NOT Pima's
 * f=json + ArcGIS-rings-conversion shape). Use JSON.stringify(feature.geometry) directly.
 *
 * CRITICAL: outSR=4326 is mandatory — the county's native ArcGIS SRID is a
 * California state-plane projection, not WGS 84. Without outSR=4326,
 * ST_GeomFromGeoJSON would store garbage coordinates that never match an address.
 * CRITICAL: f=geojson (NOT f=json) — returns a GeoJSON FeatureCollection directly.
 * CRITICAL: state='ca' lowercase — required for LOCAL-tier routing join key.
 *
 * The exact district-number attribute is UNCONFIRMED (RESEARCH was skipped for
 * this phase) — a defensive fallback chain (DISTRICT, then SUPERVISORIAL_DISTRICT /
 * SUP_DIST / DISTRICT_NUM / DIST) mirrors the LA County loader. Any out-of-range
 * (not 1-5) district number is rejected before forming geo_id (T-201-COUNT).
 *
 * ORCHESTRATION: running this script is an ORCHESTRATOR-RUN step (it reads
 * C:/EV-Accounts/backend/.env DATABASE_URL). The executor only writes this file
 * to disk; it does NOT run the loader (no Supabase MCP / DB / GIS-network access).
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-riverside-supervisor-boundaries.ts --dry-run
 *   npx tsx scripts/load-riverside-supervisor-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// CRITICAL: f=geojson (NOT f=json) — Riverside's SupervisorialDistricts/MapServer/0
// endpoint returns a GeoJSON FeatureCollection directly when f=geojson is requested.
// CRITICAL: outSR=4326 mandatory — county ArcGIS native SRID is a state-plane
// projection, not WGS84.
const RIVERSIDE_SUPERVISOR_URL =
  'https://gis.countyofriverside.us/arcgis_mapping/rest/services/' +
  'OpenData/SupervisorialDistricts/MapServer/0/query' +
  '?where=1%3D1&outFields=*&returnGeometry=true&f=geojson&outSR=4326';

const MTFCC          = 'X0021';   // next unused X-code (max seen is the Tucson wards code one below this) — DB-verify unused at execute time
const STATE_CODE     = 'ca';      // CRITICAL: lowercase — required for LOCAL-tier routing
const SOURCE         = 'gis.countyofriverside.us-supervisorialdistricts-mapserver0-2026';
const GEO_ID_PREFIX  = 'riverside-ca-supervisor-district-';
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

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-riverside-supervisor-boundaries] Fetching Riverside County Supervisorial District boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  console.log(`\n  Fetching: ${RIVERSIDE_SUPERVISOR_URL}`);
  const response = await fetchJson(RIVERSIDE_SUPERVISOR_URL) as {
    features?: Array<{
      properties: Record<string, unknown>;
      geometry: object;  // GeoJSON Polygon or MultiPolygon
    }>;
  };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from Riverside ArcGIS OpenData service. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${response.features.length} features`);
  if (response.features.length > 0) {
    console.log(`  Available fields: ${Object.keys(response.features[0]?.properties || {}).join(', ')}`);
  }

  // Build district map keyed by integer district number (1–5).
  // Defensive fallback chain (district attribute name UNCONFIRMED, RESEARCH skipped):
  // try DISTRICT, then SUPERVISORIAL_DISTRICT / SUP_DIST / DISTRICT_NUM / DIST.
  // T-201-COUNT mitigation: reject any out-of-range (not 1-5) district number
  // BEFORE forming geo_id.
  const distMap = new Map<number, { geoId: string; name: string; geomStr: string }>();

  for (const feature of response.features) {
    const props = feature.properties || {};

    let rawDist = props['DISTRICT'];
    if (rawDist == null) {
      rawDist = props['SUPERVISORIAL_DISTRICT'] ?? props['SUP_DIST'] ?? props['DISTRICT_NUM'] ?? props['DIST'];
    }

    const dist = parseInt(String(rawDist ?? ''), 10);
    if (isNaN(dist) || dist < 1 || dist > EXPECTED_COUNT) {
      console.warn(`  WARNING: district value '${String(rawDist)}' out of range 1-${EXPECTED_COUNT} — skipping. properties: ${JSON.stringify(props)}`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING: district ${dist} has no geometry — skipping`);
      continue;
    }
    if (distMap.has(dist)) {
      console.warn(`  WARNING: duplicate feature for district ${dist} — keeping first`);
      continue;
    }

    const geoId = `${GEO_ID_PREFIX}${dist}`;
    const rawName = props['NAME'] ?? props['DISTRICT_NAME'] ?? props['LABEL'];
    const distName = rawName ? String(rawName) : `Riverside County Supervisor District ${dist}`;
    // Riverside returns GeoJSON directly (f=geojson) — no rings conversion needed.
    const geomStr = JSON.stringify(feature.geometry);
    distMap.set(dist, { geoId, name: distName, geomStr });
    console.log(`  District ${dist}: geo_id=${geoId} name="${distName}"`);
  }

  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${distMap.size}. Aborting — never load a partial set.`);
    if (response.features.length > 0) {
      console.error('First feature properties for diagnosis:', JSON.stringify(response.features[0]?.properties, null, 2));
    }
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    console.log('  (sanity check: centroid should be ~-116/-117° lon, ~33/34° lat for Riverside County, CA)');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;

  for (const [dist, { geoId, name, geomStr }] of Array.from(distMap.entries()).sort((a, b) => a[0] - b[0])) {
    // Parameterized INSERT (T-201-SQLI mitigation): geo_id/name/geomJson/source all bind params.
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
      // Conditional ST_MakeValid repair guard (T-201-GEOM mitigation) — defensive
      // insurance for any invalid/self-intersecting multipolygon.
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

  // Per-district summary line (district number, geo_id, geometry type, ST_IsValid,
  // first-coordinate sanity value) so the orchestrator can confirm the
  // Riverside-County WGS84 range.
  const summary = await pool.query(
    `SELECT geo_id, public.ST_GeometryType(geometry) AS gtype, public.ST_IsValid(geometry) AS valid,
            public.ST_X(public.ST_Centroid(geometry)) AS lon, public.ST_Y(public.ST_Centroid(geometry)) AS lat
       FROM essentials.geofence_boundaries
      WHERE mtfcc = '${MTFCC}' AND state = '${STATE_CODE}'
      ORDER BY geo_id`,
  );
  console.log('\n=== Per-district geometry summary ===');
  for (const row of summary.rows as Array<{ geo_id: string; gtype: string; valid: boolean; lon: number; lat: number }>) {
    console.log(`  ${row.geo_id}: ${row.gtype}, valid=${row.valid}, centroid=(${row.lon.toFixed(4)}, ${row.lat.toFixed(4)})`);
  }

  await pool.end();

  console.log('\n=== Summary ===');
  console.log(`  geofence_boundaries inserted: ${inserted}`);
  console.log(`  geofence_boundaries already existed: ${alreadyExists}`);
  console.log(`  repaired via ST_MakeValid: ${repaired}`);

  console.log('\nVerify with:');
  console.log(`  SELECT COUNT(*), bool_and(public.ST_IsValid(geometry)) FROM essentials.geofence_boundaries WHERE state='ca' AND mtfcc='X0021'; -- expect (5, true)`);
}

main().catch((err) => {
  console.error('[load-riverside-supervisor-boundaries] Fatal error:', err);
  process.exit(1);
});
