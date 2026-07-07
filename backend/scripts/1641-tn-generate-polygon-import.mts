/**
 * 1641-tn-generate-polygon-import.mts — Phase 164.1-04: Tennessee 2026 congressional
 * district polygons → essentials.geofence_boundaries as mtfcc='G5200V26'.
 *
 * PROVENANCE: TNMap (Tennessee STS GIS) ArcGIS REST MapServer, copyright
 * "Tennessee Legislature" — ADMINISTRATIVE_BOUNDARIES/LEGISLATIVE_DISTRICTS
 * layer 2 (Congressional Districts), service-described as "2026 Boundaries".
 * Enactment: HB 7003/SB 7001 (2nd Extraordinary Session), signed 2026-05-07.
 * NEW-map identity verified at execution time (2026-07-07) by differential
 * probe: downtown Nashville (36.1627,-86.7816) → district 6 (new map's TN-6
 * gains downtown Nashville; the old map had it in TN-5), and the layer's NAME
 * field lists Matt Van Epps (TN-7, seated Dec-2025) — a post-2025 update.
 * (The plan's primary source — Comptroller GIS page — returns 404; TNMap is
 * the official state GIS service, satisfying D-08 official-first. SOURCE
 * column records 'tn_tnmap_2026'.)
 *
 * geo_ids 4701-4709 PERSIST; only shapes change. Rows carry MTFCC='G5200V26'
 * (D-01 vintage discriminator) so only the elections opt-in join resolves
 * against them; the reps feed stays on G5200.
 *
 * D-04 / Pitfall 2: the essentials.geo_districts insert of the analog
 * (load-national-house-districts.ts) is INTENTIONALLY OMITTED. This import
 * touches ONLY essentials.geofence_boundaries (1641-verify.sql D04-NOTOUCH
 * md5 blocks assert the rest is byte-identical).
 *
 * Idempotent: ON CONFLICT (geo_id, mtfcc) DO NOTHING.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/1641-tn-generate-polygon-import.mts --dry-run
 *   npx tsx scripts/1641-tn-generate-polygon-import.mts
 */

import 'dotenv/config';
import { Pool } from 'pg';

// ─── Constants ────────────────────────────────────────────────────────────────

const FEED_URL =
  'https://tnmap.tn.gov/arcgis/rest/services/ADMINISTRATIVE_BOUNDARIES/' +
  'LEGISLATIVE_DISTRICTS/MapServer/2/query' +
  '?where=1%3D1&outFields=*&outSR=4326&f=geojson';

const MTFCC      = 'G5200V26';
const SOURCE     = 'tn_tnmap_2026';
const STATE_FIPS = '47';
const EXPECTED   = 9;

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
  console.log('[1641-tn-generate-polygon-import] TN 2026 congressional districts (HB 7003) → G5200V26');
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
    throw new Error(`Expected exactly ${EXPECTED} TN district features, got ${fc.features.length}`);
  }

  let inserted = 0;
  let alreadyExists = 0;
  const seen = new Set<string>();

  for (const feature of fc.features) {
    const props = feature.properties ?? {};
    const districtCol = resolveColumn(props, DISTRICT_CANDIDATES);
    const districtNum = Number(String(props[districtCol]).trim());
    if (!Number.isInteger(districtNum) || districtNum < 1 || districtNum > EXPECTED) {
      throw new Error(`Bad district number ${String(props[districtCol])} (expected 1-${EXPECTED})`);
    }
    const geoId = STATE_FIPS + String(districtNum).padStart(2, '0'); // 4701-4709
    if (seen.has(geoId)) {
      throw new Error(`Duplicate district ${geoId} in feed`);
    }
    seen.add(geoId);
    const name = `Congressional District ${districtNum}`;

    if (!feature.geometry) {
      throw new Error(`District ${districtNum}: feature has no geometry`);
    }

    if (DRY_RUN) {
      console.log(`  [dry-run] geo_id=${geoId} name=${name} mtfcc=${MTFCC} source=${SOURCE}`);
      continue;
    }

    const geomJson = JSON.stringify(feature.geometry);
    // ST_MakeValid + ST_CollectionExtract(…,3): the TNMap feed's district 3 has a
    // ring self-intersection (caught by 1641-verify.sql L2-ANCHOR on first import);
    // repair to valid polygonal geometry at insert time, keeping polygons only.
    const result = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
       VALUES ($1, NULL, $2, $3, $4,
         ST_CollectionExtract(ST_MakeValid(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($5)), 4326)), 3),
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
    console.log(`\nDRY-RUN complete — ${fc.features.length} TN districts (expected ${EXPECTED}).`);
  } else {
    console.log(`\n=== Summary ===`);
    console.log(`  geofence_boundaries inserted:        ${inserted}`);
    console.log(`  geofence_boundaries already existed: ${alreadyExists}`);
    console.log(`  geo_districts: INTENTIONALLY UNTOUCHED (D-04 no-touch)`);
    console.log(`\nVerify with:`);
    console.log(`  SELECT count(*) FROM essentials.geofence_boundaries WHERE mtfcc='G5200V26' AND state='47';  -- expect 9`);
  }

  await pool.end();
}

main().catch((err) => {
  console.error('[1641-tn-generate-polygon-import] Fatal error:', err);
  process.exit(1);
});
