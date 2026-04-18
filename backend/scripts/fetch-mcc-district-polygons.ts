/**
 * fetch-mcc-district-polygons.ts — Fetch 4 Monroe County Council district polygons
 * from the Monroe County GIS FeatureServer and write them to disk as GeoJSON.
 *
 * Source: https://gis.co.monroe.in.us/server/rest/services/MoCo_Council_Districts/FeatureServer/0
 * Output: .planning/phases/121-county-council-d1-d4-geofence-repair/evidence/mcc-district-polygons.geojson
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/fetch-mcc-district-polygons.ts           # Fetch + validate + write file
 *   npx tsx scripts/fetch-mcc-district-polygons.ts --dry-run # Fetch + validate only (no file write)
 *
 * Exit codes:
 *   0 — success
 *   2 — validation failure (wrong count, wrong SRS, missing district, non-200 HTTP)
 *
 * IMPORTANT: Do NOT fall back to the Indiana statewide FeatureServer
 * (gisdata.in.gov) without human approval — the statewide service only returned
 * 3/4 districts in initial testing. See 121-RESEARCH.md "Alternatives Considered".
 *
 * References:
 *   - 121-RESEARCH.md § Authoritative Polygon Source (D-04)
 *   - 121-CONTEXT.md D-04 — Monroe County GIS is authoritative
 */

import https from 'https';
import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

// Monroe County GIS FeatureServer — all 4 MCC Council District polygons
// outSR=4326 ensures coordinates are in WGS84 EPSG:4326 (required for PostGIS insert)
const FEATURE_SERVER_URL =
  'https://gis.co.monroe.in.us/server/rest/services/MoCo_Council_Districts/FeatureServer/0/query' +
  '?where=1%3D1&outFields=OBJECTID,CountyCouncil,Council,Rep&outSR=4326&f=geojson';

// Output path: evidence/ directory relative to the repo root
// scripts/ -> backend/ -> ev-accounts/ -> repo root (3 levels up)
const EVIDENCE_DIR = path.resolve(
  __dirname,
  '..',
  '..',
  '..',
  '.planning',
  'phases',
  '121-county-council-d1-d4-geofence-repair',
  'evidence',
);
const OUTPUT_PATH = path.join(EVIDENCE_DIR, 'mcc-district-polygons.geojson');

const DRY_RUN = process.argv.includes('--dry-run');

// Monroe County approximate bbox for sanity-check:
// Longitudes between -87.0 and -86.0, latitudes between 39.0 and 39.4
const MONROE_BBOX = {
  minLng: -87.0,
  maxLng: -86.0,
  minLat: 39.0,
  maxLat: 39.4,
};

const EXPECTED_DISTRICTS = new Set(['1', '2', '3', '4']);

// ---------------------------------------------------------------------------
// HTTP fetch helper (follows one redirect)
// ---------------------------------------------------------------------------

interface HttpResponse {
  statusCode: number;
  body: string;
}

function fetchUrl(url: string): Promise<HttpResponse> {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const lib = parsed.protocol === 'https:' ? https : http;

    const req = lib.get(url, (res) => {
      // Follow one redirect (301 / 302 / 307 / 308)
      if (
        res.statusCode &&
        res.statusCode >= 300 &&
        res.statusCode < 400 &&
        res.headers.location
      ) {
        const redirectUrl = res.headers.location.startsWith('http')
          ? res.headers.location
          : `${parsed.protocol}//${parsed.host}${res.headers.location}`;
        console.error(`[121-fetch] Following redirect ${res.statusCode} → ${redirectUrl}`);
        res.resume(); // Drain the original response
        fetchUrl(redirectUrl).then(resolve).catch(reject);
        return;
      }

      let data = '';
      res.setEncoding('utf8');
      res.on('data', (chunk: string) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({ statusCode: res.statusCode ?? 0, body: data });
      });
      res.on('error', reject);
    });

    req.on('error', reject);
    req.setTimeout(30_000, () => {
      req.destroy(new Error('Request timeout after 30s'));
    });
  });
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

interface GeoJsonFeature {
  type: string;
  geometry: {
    type: string;
    coordinates: unknown;
  };
  properties: Record<string, unknown>;
}

interface GeoJsonFeatureCollection {
  type: string;
  features: GeoJsonFeature[];
}

function getFirstCoordinate(geometry: GeoJsonFeature['geometry']): [number, number] | null {
  // Extract the first coordinate from a Polygon or MultiPolygon
  const coords = geometry.coordinates as number[][][][];
  if (geometry.type === 'Polygon') {
    const ring = (coords as unknown as number[][][])[0];
    if (ring && ring[0]) return [ring[0][0], ring[0][1]];
  } else if (geometry.type === 'MultiPolygon') {
    const firstPoly = (coords as unknown as number[][][][])[0];
    if (firstPoly && firstPoly[0] && firstPoly[0][0]) {
      return [firstPoly[0][0][0], firstPoly[0][0][1]];
    }
  }
  return null;
}

function validate(parsed: unknown): asserts parsed is GeoJsonFeatureCollection {
  if (typeof parsed !== 'object' || parsed === null) {
    console.error('[121-fetch] FAIL: Response is not a JSON object');
    process.exit(2);
  }

  const fc = parsed as Record<string, unknown>;

  // Validate FeatureCollection type
  if (fc['type'] !== 'FeatureCollection') {
    console.error(`[121-fetch] FAIL: Expected type=FeatureCollection, got type=${fc['type']}`);
    process.exit(2);
  }

  // Validate features array
  if (!Array.isArray(fc['features'])) {
    console.error('[121-fetch] FAIL: Missing or non-array features field');
    process.exit(2);
  }

  const features = fc['features'] as GeoJsonFeature[];

  // Validate exactly 4 features
  if (features.length !== 4) {
    console.error(`[121-fetch] FAIL: Expected exactly 4 features, got ${features.length}`);
    process.exit(2);
  }

  // Validate each feature
  const districtsSeen = new Set<string>();

  for (let i = 0; i < features.length; i++) {
    const feat = features[i];

    // Geometry type
    if (!feat.geometry || !['Polygon', 'MultiPolygon'].includes(feat.geometry.type)) {
      console.error(
        `[121-fetch] FAIL: Feature ${i} has unexpected geometry type: ${feat.geometry?.type}`,
      );
      process.exit(2);
    }

    // CountyCouncil property
    const cc = feat.properties?.CountyCouncil;
    if (typeof cc !== 'string' || !EXPECTED_DISTRICTS.has(cc)) {
      console.error(
        `[121-fetch] FAIL: Feature ${i} has invalid CountyCouncil value: ${cc}`,
      );
      process.exit(2);
    }
    districtsSeen.add(cc);

    // Spot-check first coordinate bbox (Monroe County plausibility check)
    const firstCoord = getFirstCoordinate(feat.geometry);
    if (firstCoord) {
      const [lng, lat] = firstCoord;
      if (
        lng < MONROE_BBOX.minLng ||
        lng > MONROE_BBOX.maxLng ||
        lat < MONROE_BBOX.minLat ||
        lat > MONROE_BBOX.maxLat
      ) {
        console.error(
          `[121-fetch] FAIL: Feature ${i} (D${cc}) first coordinate [${lng}, ${lat}] is outside Monroe County bbox`,
        );
        process.exit(2);
      }
    }
  }

  // Validate all 4 districts are present
  const missing = [...EXPECTED_DISTRICTS].filter((d) => !districtsSeen.has(d));
  if (missing.length > 0) {
    console.error(`[121-fetch] FAIL: Missing districts: ${missing.join(', ')}`);
    process.exit(2);
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  console.error('[121-fetch] Fetching Monroe County Council District polygons...');
  console.error(`[121-fetch] URL: ${FEATURE_SERVER_URL}`);
  if (DRY_RUN) {
    console.error('[121-fetch] DRY-RUN mode: will validate but not write file');
  }

  // Fetch
  let response: HttpResponse;
  try {
    response = await fetchUrl(FEATURE_SERVER_URL);
  } catch (err) {
    console.error(`[121-fetch] FAIL: HTTP request failed: ${(err as Error).message}`);
    process.exit(2);
  }

  // Check HTTP status
  if (response.statusCode !== 200) {
    console.error(
      `[121-fetch] FAIL: FeatureServer returned HTTP ${response.statusCode} (expected 200)`,
    );
    process.exit(2);
  }

  // Parse JSON
  let parsed: unknown;
  try {
    parsed = JSON.parse(response.body);
  } catch (err) {
    console.error(`[121-fetch] FAIL: Response body is not valid JSON: ${(err as Error).message}`);
    process.exit(2);
  }

  // Validate structure
  validate(parsed);

  // All 4 features confirmed — collect district numbers for summary
  const districtNumbers = (parsed as GeoJsonFeatureCollection).features
    .map((f) => f.properties.CountyCouncil as string)
    .sort()
    .join(',');

  console.error(`[121-fetch] features_count=4`);
  console.error(`[121-fetch] districts_present=${districtNumbers}`);
  console.error(`[121-fetch] srs=EPSG:4326`);

  if (DRY_RUN) {
    console.error('[121-fetch] DRY-RUN: Skipping file write.');
    console.error('[121-fetch] output=<skipped (dry-run)>');
    return;
  }

  // Write verbatim to evidence/
  const pretty = JSON.stringify(parsed, null, 2);

  try {
    fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
    fs.writeFileSync(OUTPUT_PATH, pretty, 'utf8');
  } catch (err) {
    console.error(`[121-fetch] FAIL: Could not write output file: ${(err as Error).message}`);
    process.exit(2);
  }

  console.error(`[121-fetch] output=${OUTPUT_PATH}`);
  console.error('[121-fetch] Success — 4 MCC district polygons saved to disk.');
}

main().catch((err) => {
  console.error(`[121-fetch] FAIL: Unexpected error: ${(err as Error).message}`);
  process.exit(2);
});
