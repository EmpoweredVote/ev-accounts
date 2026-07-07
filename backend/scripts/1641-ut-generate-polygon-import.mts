/**
 * 1641-ut-generate-polygon-import.mts — Phase 164.1-03: Utah 2026-2032 congressional
 * district polygons → essentials.geofence_boundaries as mtfcc='G5200V26'.
 *
 * PROVENANCE: Utah AGRC/SGID ArcGIS REST FeatureServer
 *   political_us_congress_districts_2026_to_2032 (LWV v. Utah Legislature remedial
 *   map, effective 2025-11-10, in force for the 2026-2032 cycles). Served as
 *   GeoJSON (WGS84) directly over HTTPS — no shapefile/adm-zip needed for UT.
 *
 * geo_ids 4901-4904 PERSIST (state FIPS 49 + 2-digit district); only the shapes
 * change. Rows carry MTFCC='G5200V26' (the D-01 vintage discriminator) and
 * SOURCE='ut_agrc_2026', so only the elections opt-in join (electionService.ts)
 * ever resolves against them — the reps feed stays on G5200.
 *
 * D-04 / Pitfall 2: the essentials.geo_districts insert that the analog
 * (load-national-house-districts.ts) performs is INTENTIONALLY OMITTED here.
 * This import touches ONLY essentials.geofence_boundaries; geo_districts,
 * offices, and connect.user_districts must be byte-identical afterwards
 * (asserted by 1641-verify.sql's D04-NOTOUCH md5 blocks).
 *
 * Idempotent: ON CONFLICT (geo_id, mtfcc) DO NOTHING — re-runs are no-ops.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/1641-ut-generate-polygon-import.mts --dry-run
 *   npx tsx scripts/1641-ut-generate-polygon-import.mts
 */

import 'dotenv/config';
import { Pool } from 'pg';

// ─── Constants ────────────────────────────────────────────────────────────────

const FEED_URL =
  'https://services1.arcgis.com/99lidPhWCzftIe9K/ArcGIS/rest/services/' +
  'political_us_congress_districts_2026_to_2032/FeatureServer/0/query' +
  '?where=1%3D1&outFields=*&f=geojson';

const MTFCC      = 'G5200V26';
const SOURCE     = 'ut_agrc_2026';
const STATE_FIPS = '49';
const EXPECTED   = 4;

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

// ─── Column resolver (cloned from load-national-house-districts.ts) ──────────

function resolveColumn(record: Record<string, unknown>, candidates: string[]): string {
  for (const c of candidates) {
    if (c in record) return c;
  }
  throw new Error(
    `Column resolution failed: none of [${candidates.join(', ')}] present in record. ` +
    `Available: [${Object.keys(record).join(', ')}]. ` +
    `Add the feed's district-number field variant to the candidate list.`
  );
}

const DISTRICT_CANDIDATES = ['DISTRICT', 'District', 'district', 'DISTRICTNO', 'DIST_NUM'];

// ─── Main ─────────────────────────────────────────────────────────────────────

interface GeoJsonFeature {
  type: string;
  geometry: unknown;
  properties: Record<string, unknown>;
}

async function main() {
  console.log('[1641-ut-generate-polygon-import] UT AGRC 2026-2032 congressional districts → G5200V26');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const res = await fetch(FEED_URL);
  if (!res.ok) {
    throw new Error(`ArcGIS REST fetch failed: HTTP ${res.status} for ${FEED_URL}`);
  }
  const fc = (await res.json()) as { type: string; features: GeoJsonFeature[] };
  if (fc.type !== 'FeatureCollection' || !Array.isArray(fc.features)) {
    throw new Error('Unexpected feed shape: expected a GeoJSON FeatureCollection');
  }
  if (fc.features.length !== EXPECTED) {
    throw new Error(`Expected exactly ${EXPECTED} UT district features, got ${fc.features.length}`);
  }

  let inserted = 0;
  let alreadyExists = 0;

  for (const feature of fc.features) {
    const props = feature.properties ?? {};
    const districtCol = resolveColumn(props, DISTRICT_CANDIDATES);
    const districtNum = Number(props[districtCol]);
    if (!Number.isInteger(districtNum) || districtNum < 1 || districtNum > EXPECTED) {
      throw new Error(`Bad district number ${String(props[districtCol])} (expected 1-${EXPECTED})`);
    }
    const geoId = STATE_FIPS + String(districtNum).padStart(2, '0'); // 4901-4904
    const name  = `Congressional District ${districtNum}`;

    if (!feature.geometry) {
      throw new Error(`District ${districtNum}: feature has no geometry`);
    }

    if (DRY_RUN) {
      console.log(`  [dry-run] geo_id=${geoId} name=${name} mtfcc=${MTFCC} source=${SOURCE}`);
      continue;
    }

    const geomJson = JSON.stringify(feature.geometry);
    const result = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
       VALUES ($1, NULL, $2, $3, $4,
         ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($5)), 4326),
         $6, now())
       ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
      [geoId, name, STATE_FIPS, MTFCC, geomJson, SOURCE],
    );
    if ((result.rowCount ?? 0) > 0) {
      inserted++;
      console.log(`  inserted geo_id=${geoId} (${name})`);
    } else {
      alreadyExists++;
      console.log(`  already_exists geo_id=${geoId} (${name})`);
    }
  }

  if (DRY_RUN) {
    console.log(`\nDRY-RUN complete — ${fc.features.length} UT districts (expected ${EXPECTED}).`);
  } else {
    console.log(`\n=== Summary ===`);
    console.log(`  geofence_boundaries inserted:        ${inserted}`);
    console.log(`  geofence_boundaries already existed: ${alreadyExists}`);
    console.log(`  geo_districts: INTENTIONALLY UNTOUCHED (D-04 no-touch)`);
    console.log(`\nVerify with:`);
    console.log(`  SELECT count(*) FROM essentials.geofence_boundaries WHERE mtfcc='G5200V26' AND state='49';  -- expect 4`);
  }

  await pool.end();
}

main().catch((err) => {
  console.error('[1641-ut-generate-polygon-import] Fatal error:', err);
  process.exit(1);
});
