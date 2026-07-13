/**
 * load-palmsprings-council-boundaries.ts
 *
 * Fetches the 5 official City of Palm Springs City Council district boundaries
 * from the city GIS-maintained ArcGIS FeatureServer
 * (Palm_Springs_Voting_Districts_2022_(View)/FeatureServer/0, the 2021 "Map L"
 * boundaries adopted via Ordinance 2060) and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='palm-springs-ca-council-district-1'..'-5',
 *                                   mtfcc='X0022', state='ca'
 *
 * This loader writes ONLY to essentials.geofence_boundaries — it does NOT touch
 * essentials.districts or essentials.offices. The structural migration (Plan 02)
 * creates the LOCAL district rows and offices that reference these geofences, and
 * refuses to apply until 5 valid X0022 rows exist here (pre-flight gate).
 *
 * The FeatureServer returns a GeoJSON FeatureCollection directly when queried with
 * f=geojson — no ArcGIS-rings conversion helper is needed. Use
 * JSON.stringify(feature.geometry) directly. (RESEARCH-confirmed this session:
 * 5 valid Polygon features, DISTRICT attribute string "1".."5", CouncilName present.)
 *
 * CRITICAL: outSR=4326 is mandatory — the FeatureServer's native SRID is a
 * California state-plane projection, not WGS 84. Without outSR=4326,
 * ST_GeomFromGeoJSON would store garbage coordinates that never match an address.
 * CRITICAL: request the GeoJSON format (f=geojson), never the default Esri format —
 * this returns a GeoJSON FeatureCollection directly.
 * CRITICAL: the URL-encoded parentheses %28View%29 are part of the REST path segment
 * (the literal service name is "Palm_Springs_Voting_Districts_2022_(View)").
 * CRITICAL: state='ca' lowercase — required for LOCAL-tier routing join key.
 * CRITICAL: do NOT point at the 2018 ArcGIS Experience app — it references a
 * draft/superseded map (superseded by 2021 Map L). This loader uses ONLY the
 * maintained 2022 (View) FeatureServer.
 *
 * DISTRICT is a STRING ("1".."5") — parse with parseInt and range-reject (1-5)
 * BEFORE forming geo_id. CouncilName (Garner D1 / Bernstein D2 / deHarte D3 /
 * Soto D4 / Ready D5) is LOGGED as a free roster cross-check only — never used to
 * build geo_id.
 *
 * ORCHESTRATION: running this script is an ORCHESTRATOR-RUN step (it reads
 * C:/EV-Accounts/backend/.env DATABASE_URL). The executor only writes this file
 * to disk; it does NOT run the loader (no Supabase MCP / DB / GIS-network access).
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-palmsprings-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-palmsprings-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// CRITICAL: request the GeoJSON format (f=geojson), never the default Esri format —
// this FeatureServer returns a GeoJSON FeatureCollection directly. CRITICAL:
// outSR=4326 mandatory — native SRID is a state-plane projection, not WGS84.
// CRITICAL: %28View%29 is part of the REST path.
const PALM_SPRINGS_COUNCIL_URL =
  'https://services.arcgis.com/f48yV21HSEYeCYMI/arcgis/rest/services/' +
  'Palm_Springs_Voting_Districts_2022_%28View%29/FeatureServer/0/query' +
  '?where=1%3D1&outFields=*&returnGeometry=true&f=geojson&outSR=4326';

const MTFCC          = 'X0022';   // next unused custom LOCAL X-code — DB-verify unused at execute time
const STATE_CODE     = 'ca';      // CRITICAL: lowercase — required for LOCAL-tier routing
const SOURCE         = 'services.arcgis.com-palm-springs-voting-districts-2022-featureserver0-2026';
const GEO_ID_PREFIX  = 'palm-springs-ca-council-district-';
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
  console.log('[load-palmsprings-council-boundaries] Fetching Palm Springs City Council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  console.log(`\n  Fetching: ${PALM_SPRINGS_COUNCIL_URL}`);
  const response = await fetchJson(PALM_SPRINGS_COUNCIL_URL) as {
    features?: Array<{
      properties: Record<string, unknown>;
      geometry: object;  // GeoJSON Polygon or MultiPolygon
    }>;
  };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from Palm Springs ArcGIS FeatureServer. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${response.features.length} features`);
  if (response.features.length > 0) {
    console.log(`  Available fields: ${Object.keys(response.features[0]?.properties || {}).join(', ')}`);
  }

  // Build district map keyed by integer district number (1–5).
  // DISTRICT is the confirmed attribute (STRING "1".."5"). Reject any out-of-range
  // (not 1-5) value before forming geo_id (T-202-01 mitigation). CouncilName is
  // logged as a free roster cross-check only — never used to build geo_id.
  const distMap = new Map<number, { geoId: string; name: string; geomStr: string }>();

  for (const feature of response.features) {
    const props = feature.properties || {};

    const rawDist = props['DISTRICT'];
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
    const distName = `Palm Springs City Council District ${dist}`;
    // Free roster cross-check only — CouncilName is NOT used to form geo_id.
    const councilName = props['CouncilName'] ?? props['COUNCILNAME'] ?? props['Council_Member'] ?? '(no CouncilName attr)';
    console.log(`  District ${dist}: geo_id=${geoId} CouncilName cross-check="${String(councilName)}"`);
    // FeatureServer returns GeoJSON directly (f=geojson) — no rings conversion needed.
    const geomStr = JSON.stringify(feature.geometry);
    distMap.set(dist, { geoId, name: distName, geomStr });
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
    console.log('  (sanity check: centroid should be ~-116.5° lon, ~33.8° lat for Palm Springs, CA)');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;

  for (const [dist, { geoId, name, geomStr }] of Array.from(distMap.entries()).sort((a, b) => a[0] - b[0])) {
    // Parameterized INSERT (T-202-SQLI mitigation): geo_id/name/geomJson/source all bind params.
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
      // Conditional ST_MakeValid repair guard (T-202-01 mitigation) — defensive
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
  // centroid) so the orchestrator can confirm the Palm-Springs WGS84 range.
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
  console.log(`  SELECT COUNT(*), bool_and(public.ST_IsValid(geometry)) FROM essentials.geofence_boundaries WHERE state='ca' AND mtfcc='X0022'; -- expect (5, true)`);
}

main().catch((err) => {
  console.error('[load-palmsprings-council-boundaries] Fatal error:', err);
  process.exit(1);
});
