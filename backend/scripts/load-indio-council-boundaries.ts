/**
 * load-indio-council-boundaries.ts
 *
 * Fetches the 5 official City of Indio City Council district boundaries and
 * inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='indio-ca-council-district-1'..'-5',
 *                                   mtfcc='X0023', state='ca'
 *
 * This loader writes ONLY to essentials.geofence_boundaries — it does NOT touch
 * essentials.districts or essentials.offices. The structural migration (Plan 02)
 * creates the LOCAL district rows and offices that reference these geofences, and
 * refuses to apply until 5 valid X0023 rows exist here (pre-flight gate).
 *
 * ── SOURCE DEVIATION (execute-time, 2026-07-13) ─────────────────────────────
 * CONTEXT.md D-07 named a city self-hosted ArcGIS server at gis.indio.org as the
 * primary source. At execute time gis.indio.org does NOT resolve (NXDOMAIN) — the
 * host does not exist. The adopted current districts (2022 redistricting, "Indio
 * Approved Map 108") are published by National Demographics Corporation (NDC —
 * Indio's official districting vendor, ArcGIS owner NDCuser1) as the "Indio Plan
 * 108" hosted FeatureServer. That web map's single operational layer is the
 * INDIO_PLAN_108 FeatureServer/0 used below. This is the officially adopted map,
 * cross-checked to feature count = 5, DISTRICT string "1".."5", balanced
 * populations (~17-19k each, ~89.5k total ≈ Indio), centroids in the Indio WGS84
 * range. Equivalent situation to how the prior Coachella Valley city loader used a
 * hosted services.arcgis.com FeatureServer rather than a city-owned server.
 *
 * The layer's NAME attribute is blank on this layer, so — unlike the prior CV city
 * whose layer carried a CouncilName — there is NO councilmember name cross-check
 * available from the geometry source. Roster cross-check happens in Plan 02 against
 * the live city profile instead.
 *
 * CRITICAL: outSR=4326 is mandatory — the FeatureServer's native SRID is Web
 * Mercator (3857), not WGS 84. Without outSR=4326, ST_GeomFromGeoJSON would store
 * garbage coordinates that never match an address.
 * CRITICAL: request the GeoJSON format (f=geojson), never the default Esri format.
 * When f=geojson is honored the server returns a GeoJSON FeatureCollection directly
 * (use JSON.stringify(feature.geometry) pass-through). A defensive Esri-rings →
 * GeoJSON conversion fallback is included in case the layer ever returns Esri rings
 * despite f=geojson (CONTEXT.md D-09).
 * CRITICAL: state='ca' lowercase — required for LOCAL-tier routing join key.
 *
 * DISTRICT is a STRING ("1".."5") — the attribute name is probed defensively across
 * candidate names, parsed with parseInt, and range-rejected (1-5) BEFORE forming
 * geo_id. Any name/officeholder attribute the layer carries is LOGGED only — never
 * used to build geo_id.
 *
 * ORCHESTRATION: running this script is an ORCHESTRATOR-RUN step (it reads
 * C:/EV-Accounts/backend/.env DATABASE_URL). The executor only writes this file
 * to disk; it does NOT run the loader (no Supabase MCP / DB / GIS-network access).
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-indio-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-indio-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// CRITICAL: f=geojson + outSR=4326. See SOURCE DEVIATION header — gis.indio.org
// (CONTEXT D-07) is a non-existent domain; the adopted "Indio Approved Map 108"
// operational layer is this NDC-hosted Plan 108 FeatureServer/0.
const INDIO_COUNCIL_URL =
  'https://services8.arcgis.com/fpjs8A5Vtkshblnd/arcgis/rest/services/' +
  'Indio_Plan_108/FeatureServer/0/query' +
  '?where=1%3D1&outFields=*&returnGeometry=true&f=geojson&outSR=4326';

const MTFCC          = 'X0023';   // next unused custom LOCAL X-code — DB-verified unused (0 rows) at execute time
const STATE_CODE     = 'ca';      // CRITICAL: lowercase — required for LOCAL-tier routing
const SOURCE         = 'services8.arcgis.com-indio-plan-108-featureserver0-2026';
const GEO_ID_PREFIX  = 'indio-ca-council-district-';
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

// Defensive Esri-rings → GeoJSON conversion fallback (CONTEXT.md D-09). Only used
// if the server returns an Esri geometry (a `rings` array) despite f=geojson.
// Esri polygon rings: outer rings are clockwise, holes counter-clockwise; GeoJSON
// wants [ [ring], ... ] per polygon. We emit a single Polygon/MultiPolygon by
// treating each ring set conservatively — real use here is the pass-through path.
function esriRingsToGeoJson(geom: { rings?: number[][][] }): object | null {
  if (!geom?.rings?.length) return null;
  // Simplest safe conversion: wrap all rings as one Polygon (outer + holes). The
  // adopted layer returns GeoJSON directly so this branch is defensive only.
  return { type: 'Polygon', coordinates: geom.rings };
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-indio-council-boundaries] Fetching Indio City Council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  console.log(`\n  Fetching: ${INDIO_COUNCIL_URL}`);
  const response = await fetchJson(INDIO_COUNCIL_URL) as {
    features?: Array<{
      properties?: Record<string, unknown>;
      attributes?: Record<string, unknown>;
      geometry: object;  // GeoJSON Polygon/MultiPolygon (f=geojson) or Esri rings (fallback)
    }>;
  };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from the Indio ArcGIS FeatureServer. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${response.features.length} features`);
  if (response.features.length > 0) {
    const p0 = response.features[0]?.properties || response.features[0]?.attributes || {};
    console.log(`  Available fields: ${Object.keys(p0).join(', ')}`);
  }

  // Build district map keyed by integer district number (1–5). The district
  // attribute NAME is probed defensively (do not assume DISTRICT). Reject any
  // out-of-range value before forming geo_id (T-203-01 mitigation). Any name
  // attribute is logged as a free cross-check only — never used to build geo_id.
  const distMap = new Map<number, { geoId: string; name: string; geomStr: string }>();

  for (const feature of response.features) {
    // f=geojson uses `properties`; a raw Esri response uses `attributes`.
    const props = feature.properties || feature.attributes || {};

    const rawDist = props['DISTRICT'] ?? props['District'] ?? props['DIST_NUM'] ?? props['DISTRICTNO'];
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
    const distName = `Indio City Council District ${dist}`;
    // Free roster cross-check log only — NOT used to form geo_id. (This layer's
    // NAME is blank; logged anyway in case a future layer revision populates it.)
    const rosterName = props['NAME'] ?? props['CouncilName'] ?? props['COUNCILNAME'] ?? props['MEMBER'] ?? '(no name attr)';
    console.log(`  District ${dist}: geo_id=${geoId} name cross-check="${String(rosterName)}"`);

    // Primary path: f=geojson returns GeoJSON geometry directly — pass through.
    // Fallback: convert Esri rings if the server ignored f=geojson (D-09).
    const rawGeom = feature.geometry as { type?: string; rings?: number[][][] };
    let geom: object | null;
    if (typeof rawGeom.type === 'string') {
      geom = rawGeom;                         // GeoJSON pass-through (adopted path)
    } else if (Array.isArray(rawGeom.rings)) {
      geom = esriRingsToGeoJson(rawGeom);     // Esri-rings fallback branch (D-09)
    } else {
      console.warn(`  WARNING: district ${dist} geometry is neither GeoJSON nor Esri rings — skipping`);
      continue;
    }
    if (!geom) {
      console.warn(`  WARNING: district ${dist} geometry could not be parsed — skipping`);
      continue;
    }
    const geomStr = JSON.stringify(geom);
    distMap.set(dist, { geoId, name: distName, geomStr });
  }

  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${distMap.size}. Aborting — never load a partial set.`);
    if (response.features.length > 0) {
      const p0 = response.features[0]?.properties || response.features[0]?.attributes || {};
      console.error('First feature properties for diagnosis:', JSON.stringify(p0, null, 2));
    }
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    console.log('  (sanity check: centroid should be ~-116.2° lon, ~33.7° lat for Indio, CA)');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;

  for (const [dist, { geoId, name, geomStr }] of Array.from(distMap.entries()).sort((a, b) => a[0] - b[0])) {
    // Parameterized INSERT (T-203-SQLI mitigation): geo_id/name/geomJson/source all bind params.
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
      // Conditional ST_MakeValid repair guard (T-203-01 mitigation) — defensive
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
  // centroid) so the orchestrator can confirm the Indio WGS84 range.
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
  console.log(`  SELECT COUNT(*), bool_and(public.ST_IsValid(geometry)) FROM essentials.geofence_boundaries WHERE state='ca' AND mtfcc='X0023'; -- expect (5, true)`);
}

main().catch((err) => {
  console.error('[load-indio-council-boundaries] Fatal error:', err);
  process.exit(1);
});
