/**
 * load-tucson-ward-boundaries.ts
 *
 * Fetches the 6 City of Tucson ward boundaries from the Pima-County-hosted
 * ArcGIS MapServer (GISOpenData/Boundaries2, Layer 3) and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='tucson-az-ward-1'..'-6',
 *                                   mtfcc='X0020', state='az'
 *
 * Like load-pima-supervisor-boundaries.ts, this loader writes ONLY to
 * essentials.geofence_boundaries — it does NOT touch essentials.districts or
 * any government/office table. The pre-existing whole-city G4110 row
 * (geo_id='0477000', written by Phase 190) is untouched.
 *
 * The endpoint is an ArcGIS MapServer (NOT a FeatureServer), so f=json
 * returns ArcGIS JSON (feature.geometry.rings), NOT GeoJSON. We convert rings
 * to a GeoJSON Polygon / MultiPolygon before handing them to ST_GeomFromGeoJSON.
 * (The GeoJSON output format is not available on a MapServer — do not request it.)
 *
 * CRITICAL DELTA FROM PIMA: two of the six Tucson wards are genuinely
 * multi-ring — Ward 4 has 2 constituent polygons and Ward 5 has 7 (live-verified
 * 2026-07-10, all confirmed exterior/clockwise). So the FULL winding-classification
 * branch of arcgisRingsToGeoJson (below the single-ring fast path) is LOAD-BEARING
 * here, not dead defensive code. Do NOT copy the LV loader's naive
 * `{type:'Polygon', coordinates: rings}` pass-through (WR-01) — it silently
 * mis-encodes every ring past the first as a "hole" regardless of winding,
 * under-sizing Ward 4/5 and mis-routing addresses in the dropped parcels.
 *
 * CRITICAL: outSR=4326 is mandatory — the native spatial reference is SRID 2868
 * (AZ State Plane). Without outSR=4326 the coordinates come back in state-plane
 * units and store as garbage that never matches an address (RESEARCH Pitfall 1).
 * CRITICAL: use f=json — the layer returns ArcGIS rings, not GeoJSON.
 * CRITICAL: state='az' lowercase — required for LOCAL-tier routing join key
 * (RESEARCH Pitfall 3).
 *
 * All 6 wards must be present: a shortfall is a hard failure (D-01 PAUSE+flag —
 * never silently load a partial set).
 *
 * ORCHESTRATION: running this script is an INLINE-ORCHESTRATOR step performed
 * by execute-phase (it reads C:/EV-Accounts/backend/.env DATABASE_URL). The
 * executor only writes this file to disk; it does NOT run the loader.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-tucson-ward-boundaries.ts --dry-run
 *   npx tsx scripts/load-tucson-ward-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// CRITICAL: outSR=4326 required — native SRID is 2868 (AZ State Plane).
// CRITICAL: use f=json — returns ArcGIS JSON rings, not GeoJSON.
const TUCSON_WARD_URL =
  'https://gisdata.pima.gov/arcgis1/rest/services/' +
  'GISOpenData/Boundaries2/MapServer/3/query' +
  '?where=1%3D1&outFields=WARD,NAME&returnGeometry=true&f=json&outSR=4326';

const MTFCC          = 'X0020';   // next unused X-code (DB-verified unused, above the Pima supervisor range)
const STATE_CODE     = 'az';      // CRITICAL: lowercase — required for LOCAL-tier routing
const SOURCE         = 'gisdata.pima.gov-boundaries2-mapserver3-2026';
const GEO_ID_PREFIX  = 'tucson-az-ward-';
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

// ArcGIS JSON rings → GeoJSON Polygon / MultiPolygon string.
//
// The MapServer (f=json) returns feature.geometry.rings as number[][][]
// (an array of rings, each ring an array of [lon, lat] pairs). ArcGIS and
// GeoJSON rings are NOT interchangeable once a feature has more than one ring:
//
//   - ArcGIS packs ALL rings — multiple disjoint exterior rings (a
//     multipolygon) AND holes — into one flat `rings` array, distinguishing
//     them ONLY by winding order: an exterior ring is CLOCKWISE (negative
//     signed area, math y-up convention) and a hole is COUNTER-CLOCKWISE
//     (positive signed area).
//   - A GeoJSON Polygon, by contrast, treats coordinates[0] as the single
//     exterior ring and EVERY subsequent ring as a HOLE of that exterior.
//
// So blindly assigning the ArcGIS `rings` array to a GeoJSON Polygon's
// `coordinates` silently mis-encodes any multi-body or holed ward (a
// detached parcel becomes a hole; a hole may be mis-oriented). ST_Multi in the
// INSERT CANNOT repair this — it only promotes a geometry to a MULTI type, it
// does not reinterpret extra polygon rings as separate polygons.
//
// This function therefore converts by orientation: it computes each ring's
// signed area, starts a new GeoJSON polygon at every clockwise (exterior)
// ring, and appends every counter-clockwise (hole) ring to the most recent
// exterior polygon. It emits a Polygon when there is exactly one exterior ring
// and a MultiPolygon when there is more than one. (Either feeds the existing
// INSERT fine — ST_Multi still promotes Polygon→MultiPolygon.)
//
// Tucson's Ward 4 (2 rings) and Ward 5 (7 rings) EXERCISE the multi-ring
// branch — it is load-bearing here, not dead code. Wards 1/2/3/6 are
// single-ring and take the fast path. Function is pure and returns a JSON string.

// Signed area of a ring via the shoelace formula. Positive => counter-clockwise
// (a GeoJSON/ArcGIS hole); negative => clockwise (an ArcGIS exterior ring).
// Magnitude near zero => degenerate (collinear / zero-area) ring.
function ringSignedArea(ring: number[][]): number {
  let sum = 0;
  const n = ring.length;
  for (let i = 0; i < n; i++) {
    const [x1, y1] = ring[i];
    const [x2, y2] = ring[(i + 1) % n];
    sum += x1 * y2 - x2 * y1;
  }
  return sum / 2;
}

function arcgisRingsToGeoJson(rings: number[][][]): string {
  // Single-ring fast path: Wards 1/2/3/6 are single-ring.
  if (rings.length === 1) {
    return JSON.stringify({ type: 'Polygon', coordinates: [rings[0]] });
  }

  // Multi-ring: classify each ring by winding order and group into polygons.
  const AREA_EPS = 1e-12; // below this magnitude a ring is treated as degenerate
  // Each entry is one GeoJSON polygon: [exteriorRing, ...holeRings].
  const polygons: number[][][][] = [];

  for (const ring of rings) {
    const area = ringSignedArea(ring);
    if (Math.abs(area) <= AREA_EPS) {
      // Ambiguous winding — cannot tell exterior from hole. Fail loudly rather
      // than silently store wrong geometry.
      throw new Error(
        `arcgisRingsToGeoJson: degenerate ring with ~zero signed area (${area}); ` +
          `ambiguous winding, cannot classify exterior vs hole. Aborting.`,
      );
    }
    if (area < 0) {
      // Clockwise → ArcGIS exterior ring → begins a new GeoJSON polygon.
      polygons.push([ring]);
    } else {
      // Counter-clockwise → ArcGIS hole → belongs to the most recent exterior.
      if (polygons.length === 0) {
        // A hole with no preceding exterior means zero detected exterior rings
        // so far — malformed/ambiguous input. Hard-fail (defensive guard).
        throw new Error(
          'arcgisRingsToGeoJson: encountered a hole ring before any exterior ring ' +
            '(zero detected exterior rings); ArcGIS rings malformed or winding inverted. Aborting.',
        );
      }
      polygons[polygons.length - 1].push(ring);
    }
  }

  if (polygons.length === 0) {
    // rings.length > 1 but nothing classified as exterior — e.g. all holes.
    throw new Error(
      `arcgisRingsToGeoJson: no exterior rings detected among ${rings.length} rings. Aborting.`,
    );
  }

  // One exterior ring (+ optional holes) → Polygon; more than one → MultiPolygon.
  if (polygons.length === 1) {
    return JSON.stringify({ type: 'Polygon', coordinates: polygons[0] });
  }
  return JSON.stringify({ type: 'MultiPolygon', coordinates: polygons });
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-tucson-ward-boundaries] Fetching City of Tucson ward boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const response = await fetchJson(TUCSON_WARD_URL) as {
    features?: Array<{
      attributes: { WARD?: number | string; NAME?: string; [key: string]: unknown };
      geometry: { rings: number[][][] };
    }>;
  };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from Tucson wards MapServer. Check the URL.');
    process.exit(1);
  }

  console.log(`  Received ${response.features.length} features`);

  // Build ward map keyed by WARD number (feature.attributes.WARD, integer 1-6).
  // Input-validation (T-194-SQLI defense-in-depth): reject any WARD outside 1-6 before forming geo_id.
  const wardMap = new Map<number, { geoId: string; name: string; rings: number[][][] }>();

  for (const feature of response.features) {
    const attrs = feature.attributes || {};
    const rawWard = attrs['WARD'];
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
    const name = String(attrs['NAME'] ?? `Ward ${ward}`);
    wardMap.set(ward, { geoId, name, rings });
    const firstCoord = rings[0]?.[0];
    console.log(`  WARD ${ward}: rings=${rings.length} geo_id=${geoId} name="${name}" firstCoord=${JSON.stringify(firstCoord)}`);
  }

  // D-01 PAUSE+flag: never silently load a partial set. A shortfall is a hard failure.
  if (wardMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} Tucson wards, got ${wardMap.size}. Aborting (D-01 PAUSE+flag — never load a partial set).`);
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    console.log('  (sanity check: first coords should be ~-111° lon, ~32° lat for Tucson, AZ)');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;

  for (const [ward, { geoId, name, rings }] of Array.from(wardMap.entries()).sort((a, b) => a[0] - b[0])) {
    const geomJson = arcgisRingsToGeoJson(rings);

    // INSERT into geofence_boundaries (X0020, state='az'); ST_Multi wraps single- or multi-body wards.
    // T-194-SQLI: all GIS attribute/geometry values pass as bind params ($1 geo_id / $2 name / $3 GeoJSON / $4 source)
    // — never string-concatenate GIS response data into SQL.
    // RETURNING includes ST_NumGeometries so multi-ring wards (Ward 4=2, Ward 5=7) are observable.
    const result = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (id, geo_id, mtfcc, state, name, geometry, source)
       VALUES (gen_random_uuid(), $1, '${MTFCC}', '${STATE_CODE}', $2,
         public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)),
         $4)
       ON CONFLICT (geo_id, mtfcc) DO NOTHING
       RETURNING public.ST_GeometryType(geometry) AS gtype,
                 public.ST_IsValid(geometry) AS valid,
                 public.ST_NumGeometries(geometry) AS numgeom`,
      [geoId, name, geomJson, SOURCE],
    );

    if ((result.rowCount ?? 0) === 0) {
      alreadyExists++;
      // Report existing geometry shape so re-runs still surface the multi-ring self-check.
      const existing = await pool.query(
        `SELECT public.ST_GeometryType(geometry) AS gtype,
                public.ST_IsValid(geometry) AS valid,
                public.ST_NumGeometries(geometry) AS numgeom
           FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId],
      );
      const er = existing.rows[0] as { gtype: string; valid: boolean; numgeom: number } | undefined;
      const firstCoord = rings[0]?.[0];
      console.log(`  Ward ${ward} (${geoId}, "${name}"): skipped (already exists) gtype=${er?.gtype} ST_IsValid=${er?.valid} ST_NumGeometries=${er?.numgeom} firstCoord=${JSON.stringify(firstCoord)}`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean; numgeom: number };
    const firstCoord = rings[0]?.[0];
    if (row.valid !== true) {
      // ST_MakeValid fallback — re-run this ward through ST_MakeValid.
      // More likely to trigger here than in Pima given the multi-ring geometry.
      console.error(`  Ward ${ward} (${geoId}): ST_IsValid=false (gtype=${row.gtype}) — applying ST_MakeValid`);
      await pool.query(
        `UPDATE essentials.geofence_boundaries
           SET geometry = public.ST_Multi(public.ST_MakeValid(
             public.ST_SetSRID(public.ST_GeomFromGeoJSON($2), 4326)))
         WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId, geomJson],
      );
      const recheck = await pool.query(
        `SELECT public.ST_IsValid(geometry) AS valid,
                public.ST_NumGeometries(geometry) AS numgeom
           FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId],
      );
      const rc = recheck.rows[0] as { valid: boolean; numgeom: number } | undefined;
      if (rc?.valid !== true) {
        console.error(`  ERROR: Ward ${ward} (${geoId}) still invalid after ST_MakeValid. Aborting.`);
        await pool.end();
        process.exit(1);
      }
      repaired++;
      console.log(`  Ward ${ward} (${geoId}, "${name}"): repaired via ST_MakeValid (now valid) ST_NumGeometries=${rc?.numgeom} firstCoord=${JSON.stringify(firstCoord)}`);
    } else {
      console.log(`  Ward ${ward} (${geoId}, "${name}"): inserted (${row.gtype}, ST_IsValid=true, ST_NumGeometries=${row.numgeom}) firstCoord=${JSON.stringify(firstCoord)}`);
    }
    inserted++;
  }

  await pool.end();

  console.log('\n=== Summary ===');
  console.log(`  geofence_boundaries inserted: ${inserted}`);
  console.log(`  geofence_boundaries already existed: ${alreadyExists}`);
  console.log(`  repaired via ST_MakeValid: ${repaired}`);

  console.log('\nExpected multi-ring shape: Ward 4 ST_NumGeometries=2, Ward 5 ST_NumGeometries=7, Wards 1/2/3/6 = 1.');
  console.log('\nVerify with:');
  console.log(`  SELECT COUNT(*), bool_and(public.ST_IsValid(geometry)) FROM essentials.geofence_boundaries WHERE state='az' AND mtfcc='X0020'; -- expect (6, true)`);
}

main().catch((err) => {
  console.error('[load-tucson-ward-boundaries] Fatal error:', err);
  process.exit(1);
});
