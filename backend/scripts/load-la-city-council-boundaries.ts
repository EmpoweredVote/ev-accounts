/**
 * load-la-city-council-boundaries.ts
 *
 * Fetches the 15 LA City Council district boundaries from the City of Los Angeles'
 * own NavigateLA Boundaries service and inserts them into essentials.geofence_boundaries.
 *
 * 🔴 2026-10-20 — THIS SCRIPT SHIPPED THE WRONG MAP FOR YEARS. It pointed at
 * services5.arcgis.com/7nsPwEMP38bSkCjy, a third-party ArcGIS Online COPY of the council
 * districts whose editingInfo.lastEditDate is 2021-03-22 — months before the current
 * post-redistricting map took effect. Every address in 6.1% of the city was shown the wrong
 * councilmember until CA_0317 repaired the rows. The copy even carried a councilmember NAME per
 * polygon, and every name was a sitting member, so nothing looked wrong.
 *   - Take boundaries from the government that draws them, never from a re-publication.
 *   - A name field on a boundary layer dates the ROSTER, not the BOUNDARY. It is corroboration
 *     only; it cannot establish vintage.
 *   - Verify with `npm run check:district-vintage` (scripts/check-council-district-vintage.mjs),
 *     which compares our polygons against the LA County Registrar-Recorder precinct layer's
 *     authority and fails on a stale map.
 *
 * Each district is stored with:
 *   geo_id  = 'ocd-division/country:us/state:ca/place:los_angeles/council_district:{N}'
 *   mtfcc   = 'X0001'
 *   state   = '06'
 *   source  = the NavigateLA provenance string in SOURCE below (was the bare, undated tag
 *             'la_city_geohub_council_districts_2024' — a tag that names a publisher and a year
 *             but proves nothing is how this went unnoticed)
 *
 * These geo_ids match existing rows in essentials.districts (district_type='LOCAL'),
 * so resolve_user_jurisdiction will immediately find the correct council district
 * for any address that falls within LA City limits.
 *
 * Re-running only ever ADDS missing districts: ON CONFLICT (geo_id, mtfcc) DO NOTHING means it
 * will NOT refresh a row whose geometry has gone stale — re-running was never a repair path, which
 * is part of how the 2012 map survived. To replace existing boundaries, write a numbered migration
 * (see CA_0317_la_council_district_current_map.sql) so the change is reviewable and reversible.
 *
 * Usage (from backend/):
 *   npx tsx scripts/load-la-city-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-la-city-council-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

// City of Los Angeles, NavigateLA "Boundaries" MapServer layer 13 — Council Districts.
// This is the city's own live service (the one its NavigateLA / district-lookup tools read).
// ⚠ Do NOT swap this for an arcgis.com item without checking that service's
// editingInfo.lastEditDate and proving the vintage — that is the mistake CA_0317 repaired.
const ARCGIS_URL =
  'https://maps.lacity.org/lahub/rest/services/Boundaries/MapServer/13/query' +
  '?where=1%3D1&outFields=District&returnGeometry=true&outSR=4326&f=geojson';

const MTFCC   = 'X0001';
const STATE   = '06';
// Kept in step with the source string written by CA_0317, which carries the full vintage proof.
const SOURCE  =
  'City of Los Angeles, NavigateLA Boundaries MapServer layer 13 "Council Districts" ' +
  '(maps.lacity.org/lahub/rest/services/Boundaries/MapServer/13); vintage proved against the LA ' +
  'County Registrar-Recorder precinct layer (Political_Boundaries MapServer 34, DST_CITY=LS / ' +
  'DIV_CITY), the layer the county builds ballots from — see CA_0317.';

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
        try {
          resolve(JSON.parse(Buffer.concat(chunks).toString('utf8')));
        } catch (e) {
          reject(new Error(`JSON parse error: ${(e as Error).message}`));
        }
      });
    }).on('error', reject);
  });
}

/** Extract district number from a feature's properties.
 *  Tries common field names used in LA City ArcGIS exports. */
function extractDistrictNumber(props: Record<string, unknown>): number | null {
  // 'District' is the field NavigateLA layer 13 uses, and it must be tried BEFORE 'NAME' —
  // on that layer NAME holds the councilmember, not the number.
  for (const field of ['District', 'CD', 'DISTRICT', 'DISTNUM', 'NAME', 'LABEL', 'district', 'cd']) {
    const v = props[field];
    if (v == null) continue;
    const n = parseInt(String(v), 10);
    if (!isNaN(n) && n >= 1 && n <= 15) return n;
  }
  // Try extracting a number from any string field value
  for (const v of Object.values(props)) {
    if (typeof v === 'string') {
      const m = v.match(/\b(\d{1,2})\b/);
      if (m) {
        const n = parseInt(m[1], 10);
        if (n >= 1 && n <= 15) return n;
      }
    }
  }
  return null;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-la-city-council-boundaries] Fetching LA City Council district boundaries');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  // Step 1: Fetch GeoJSON from ArcGIS
  console.log(`\n  Fetching: ${ARCGIS_URL}`);
  let geojson: { type: string; features: Array<{ type: string; geometry: unknown; properties: Record<string, unknown> }> };
  try {
    geojson = await fetchJson(ARCGIS_URL) as typeof geojson;
  } catch (err) {
    console.error('ERROR fetching council districts:', (err as Error).message);
    process.exit(1);
  }

  if (!geojson?.features?.length) {
    console.error('ERROR: No features returned from ArcGIS. Check the URL or try the alternate source below.');
    console.error('  Alternate: https://data.lacity.org/resource/yuhs-atbe.geojson');
    process.exit(1);
  }

  console.log(`  Received ${geojson.features.length} features`);

  // Step 2: Map features to district numbers
  const districtMap = new Map<number, string>(); // distNum -> GeoJSON geometry string

  for (const feature of geojson.features) {
    const props = feature.properties || {};
    const distNum = extractDistrictNumber(props);
    if (distNum === null) {
      console.warn(`  WARNING: Could not extract district number from properties: ${JSON.stringify(props)}`);
      continue;
    }
    if (districtMap.has(distNum)) {
      console.warn(`  WARNING: Duplicate features for district ${distNum} — keeping first`);
      continue;
    }
    districtMap.set(distNum, JSON.stringify(feature.geometry));
    console.log(`  District ${distNum}: found (fields: ${Object.keys(props).join(', ')})`);
  }

  if (districtMap.size === 0) {
    console.error('ERROR: Could not extract any district numbers. Dumping first feature properties for diagnosis:');
    console.error(JSON.stringify(geojson.features[0]?.properties, null, 2));
    process.exit(1);
  }

  console.log(`\n  Mapped ${districtMap.size} / 15 districts`);

  // Step 3: Insert into geofence_boundaries
  let inserted = 0;
  let skipped  = 0;

  for (const [distNum, geometryJson] of Array.from(districtMap.entries()).sort((a, b) => a[0] - b[0])) {
    const geoId = `ocd-division/country:us/state:ca/place:los_angeles/council_district:${distNum}`;
    const name  = `Los Angeles City Council District ${distNum}`;

    if (DRY_RUN) {
      console.log(`  [dry-run] Would insert: geo_id=${geoId}`);
      inserted++;
      continue;
    }

    try {
      const result = await pool.query(`
        INSERT INTO essentials.geofence_boundaries
          (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
        VALUES (
          $1, $2, $3, $4, $5,
          public.ST_ForcePolygonCCW(
            public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326)
          ),
          $7, now()
        )
        ON CONFLICT (geo_id, mtfcc) DO NOTHING
      `, [
        geoId,
        geoId,   // ocd_id same as geo_id for OCD-format ids
        name,
        STATE,
        MTFCC,
        geometryJson,
        SOURCE,
      ]);

      if (result.rowCount && result.rowCount > 0) {
        console.log(`  Inserted: District ${distNum} (${geoId})`);
        inserted++;
      } else {
        console.log(`  Skipped (already exists): District ${distNum}`);
        skipped++;
      }
    } catch (err) {
      console.error(`  ERROR inserting District ${distNum}:`, (err as Error).message);
      process.exit(1);
    }
  }

  // Step 4: Verify
  console.log('\n  Summary:');
  console.log(`    Inserted: ${inserted}`);
  console.log(`    Skipped (already existed): ${skipped}`);

  if (!DRY_RUN) {
    const verify = await pool.query(`
      SELECT COUNT(*) AS cnt
      FROM essentials.geofence_boundaries
      WHERE mtfcc = $1 AND state = $2 AND geo_id LIKE '%place:los_angeles/council_district:%'
    `, [MTFCC, STATE]);
    const total = parseInt(verify.rows[0].cnt, 10);
    console.log(`    Total LA City Council rows in geofence_boundaries: ${total}`);
    if (total < 15) {
      console.warn(`  WARNING: Only ${total}/15 districts loaded. Missing districts may have had no matching feature.`);
    } else {
      console.log('  All 15 districts loaded successfully.');
    }
  }

  console.log('\n[load-la-city-council-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-la-city-council-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
