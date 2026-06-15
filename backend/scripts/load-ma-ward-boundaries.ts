/**
 * load-ma-ward-boundaries.ts
 *
 * Fetches ward/district precinct polygons from MassGIS WARDSPRECINCTS2022_POLY
 * FeatureServer and inserts dissolved per-ward/district polygons into
 * essentials.geofence_boundaries for Springfield, Lowell, Brockton, and Quincy.
 *
 * CRITICAL: Do NOT use this script for Worcester. Worcester has its own script
 * (load-worcester-council-boundaries.ts) that hits the city's own FeatureServer
 * (Council_Districts_2026), which provides 5 pre-dissolved council district polygons.
 * MassGIS WARDSPRECINCTS2022_POLY has 10 voting wards for Worcester (60 precincts),
 * NOT the 5 council districts. Using this script for Worcester would load wrong data.
 *
 * CRITICAL: TOWN filter must be uppercase: SPRINGFIELD, LOWELL, BROCKTON, QUINCY.
 * MassGIS TOWN field is stored in uppercase. Mixed-case queries return 0 results.
 *
 * CRITICAL: outSR=4326 IS REQUIRED. MassGIS serves Web Mercator (WKID 102100/3857)
 * by default. Omitting outSR causes geometries to be stored in the wrong CRS, which
 * breaks Path 0 geofencing (ST_Contains will silently return no matches).
 *
 * Source: MassGIS WARDSPRECINCTS2022_POLY FeatureServer
 *   https://services6.arcgis.com/hNDcO07QfnsUMldG/arcgis/rest/services/WARDSPRECINCTS2022_POLY/FeatureServer/0
 * Fields: TOWN (String, uppercase), WARD (String, "1".."8"), PRECINCT (String)
 *
 * Ward counts (verified via live MassGIS statistics query):
 *   Springfield: 8 wards, 64 precincts (8 per ward)
 *   Lowell:      8 districts, 32 precincts (4 per ward)
 *   Brockton:    7 wards, 28 precincts (4 per ward)
 *   Quincy:      6 wards, 30 precincts (5 per ward)
 *
 * Dissolution strategy: Fetch all precinct features for the city, group by WARD,
 * then INSERT each ward as a single dissolved polygon using ST_Union inside PostgreSQL
 * (Option B from research — unnest($5::text[]) aggregate). No dynamic SQL in JS.
 *
 * IDEMPOTENCY: ON CONFLICT (geo_id, mtfcc) DO NOTHING ensures safe re-runs.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-ma-ward-boundaries.ts --city SPRINGFIELD --ward-count 8 --dry-run
 *   npx tsx scripts/load-ma-ward-boundaries.ts --city SPRINGFIELD --ward-count 8
 *   npx tsx scripts/load-ma-ward-boundaries.ts --city LOWELL --ward-count 8
 *   npx tsx scripts/load-ma-ward-boundaries.ts --city BROCKTON --ward-count 7
 *   npx tsx scripts/load-ma-ward-boundaries.ts --city QUINCY --ward-count 6
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── MassGIS FeatureServer ───────────────────────────────────────────────────

// CRITICAL: outSR=4326 IS REQUIRED — MassGIS serves Web Mercator by default.
const MASSGIS_BASE_URL =
  'https://services6.arcgis.com/hNDcO07QfnsUMldG/arcgis/rest/services/WARDSPRECINCTS2022_POLY/FeatureServer/0/query';

const MTFCC  = 'X0014';
const STATE  = '25';    // Massachusetts FIPS (NOT 'MA' or 'ma')
const SOURCE = 'massgis_wardsprecincts2022';

// ─── City configuration ──────────────────────────────────────────────────────

interface CityConfig {
  geoIdPrefix: string;
  wardLabel: string;  // 'Ward' or 'District'
}

// CRITICAL: keys must be uppercase — TOWN field in MassGIS is uppercase.
const CITY_CONFIGS: Record<string, CityConfig> = {
  SPRINGFIELD: {
    geoIdPrefix: 'springfield-ma-council-ward-',
    wardLabel: 'Ward',
  },
  LOWELL: {
    geoIdPrefix: 'lowell-ma-council-district-',
    wardLabel: 'District',
  },
  BROCKTON: {
    geoIdPrefix: 'brockton-ma-council-ward-',
    wardLabel: 'Ward',
  },
  QUINCY: {
    geoIdPrefix: 'quincy-ma-council-ward-',
    wardLabel: 'Ward',
  },
};

const ALLOWED_CITIES = Object.keys(CITY_CONFIGS);

// ─── CLI parsing ─────────────────────────────────────────────────────────────

function parseArgs(): { city: string; wardCount: number; dryRun: boolean } {
  const args = process.argv.slice(2);

  const cityIdx = args.indexOf('--city');
  const wardIdx = args.indexOf('--ward-count');
  const dryRun  = args.includes('--dry-run');

  if (cityIdx === -1 || wardIdx === -1) {
    console.error('Usage: npx tsx scripts/load-ma-ward-boundaries.ts --city CITY --ward-count N [--dry-run]');
    console.error('  --city: one of SPRINGFIELD, LOWELL, BROCKTON, QUINCY');
    console.error('  --ward-count: expected number of wards/districts (8, 8, 7, or 6)');
    console.error('  --dry-run: fetch and validate without writing to DB');
    console.error('');
    console.error('WARNING: Do NOT use this script for Worcester.');
    console.error('  Worcester uses load-worcester-council-boundaries.ts (city FeatureServer).');
    process.exit(1);
  }

  const city = (args[cityIdx + 1] ?? '').toUpperCase();
  if (!ALLOWED_CITIES.includes(city)) {
    console.error(`ERROR: --city must be one of ${ALLOWED_CITIES.join(', ')}. Got: '${args[cityIdx + 1]}'`);
    console.error('WARNING: Worcester is NOT supported — use load-worcester-council-boundaries.ts instead.');
    process.exit(1);
  }

  const wardCountStr = args[wardIdx + 1] ?? '';
  const wardCount = parseInt(wardCountStr, 10);
  if (isNaN(wardCount) || wardCount < 1 || wardCount > 20) {
    console.error(`ERROR: --ward-count must be a positive integer (1..20). Got: '${wardCountStr}'`);
    process.exit(1);
  }

  return { city, wardCount, dryRun };
}

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

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  const { city, wardCount, dryRun } = parseArgs();
  const config = CITY_CONFIGS[city]!;

  console.log(`[load-ma-ward-boundaries] City: ${city}, Ward count: ${wardCount}`);
  if (dryRun) console.log('  DRY RUN — no DB writes');

  // ─── Step 1: Fetch all precinct features for this city ────────────────────
  //
  // CRITICAL: TOWN filter must be uppercase (MassGIS stores TOWN in uppercase).
  // CRITICAL: outSR=4326 IS REQUIRED (MassGIS default is Web Mercator WKID 102100).
  //
  // T-119-M2: city arg is validated against allowlist of 4 cities above.
  // T-119-M1: WARD field values validated as integers in range 1..wardCount below.

  const fetchUrl = `${MASSGIS_BASE_URL}?where=TOWN%3D%27${encodeURIComponent(city)}%27&outFields=WARD,PRECINCT&outSR=4326&f=geojson`;
  console.log(`\n  Fetching all precincts for TOWN='${city}': ${fetchUrl}`);

  let geojson: {
    type: string;
    features: Array<{
      type: string;
      geometry: unknown;
      properties: Record<string, unknown>;
    }>;
  };

  try {
    geojson = await fetchJson(fetchUrl) as typeof geojson;
  } catch (err) {
    console.error(`ERROR fetching MassGIS data: ${(err as Error).message}`);
    process.exit(1);
  }

  if (!geojson?.features?.length) {
    console.error(`ERROR: No features returned for TOWN='${city}'. Check TOWN spelling (must be uppercase).`);
    process.exit(1);
  }

  console.log(`  Fetched ${geojson.features.length} precinct features for ${city}`);

  // ─── Step 2: Group precincts by ward number ────────────────────────────────
  //
  // T-119-M1: Validate WARD field as integer in range 1..wardCount before
  // constructing geo_id. Never interpolate WARD field values directly into SQL.

  const wardMap = new Map<number, string[]>(); // wardNum -> array of GeoJSON geometry strings

  for (const feature of geojson.features) {
    const props = feature.properties ?? {};
    const rawWard = props['WARD'];

    // T-119-M1: parseInt + isNaN + range check before any geo_id construction
    const wardNum = parseInt(String(rawWard ?? ''), 10);
    if (isNaN(wardNum) || wardNum < 1 || wardNum > wardCount) {
      console.error(`ERROR: WARD field value '${rawWard}' is out of range 1..${wardCount} for ${city}`);
      console.error(`  If the expected ward count is wrong, adjust --ward-count.`);
      process.exit(1);
    }

    if (!wardMap.has(wardNum)) {
      wardMap.set(wardNum, []);
    }
    wardMap.get(wardNum)!.push(JSON.stringify(feature.geometry));
  }

  console.log(`\n  Ward grouping results:`);
  for (let w = 1; w <= wardCount; w++) {
    const precincts = wardMap.get(w);
    if (precincts) {
      console.log(`    ${config.wardLabel} ${w}: ${precincts.length} precincts`);
    } else {
      console.log(`    ${config.wardLabel} ${w}: MISSING`);
    }
  }

  // T-119-M3: Verify we have exactly wardCount ward groups (not precinct count)
  if (wardMap.size !== wardCount) {
    const missing: number[] = [];
    for (let w = 1; w <= wardCount; w++) {
      if (!wardMap.has(w)) missing.push(w);
    }
    console.error(`ERROR: Expected ${wardCount} ward groups, found ${wardMap.size}.`);
    console.error(`  Missing wards: ${missing.join(', ')}`);
    process.exit(1);
  }

  console.log(`\n  Found exactly ${wardMap.size} ward groups (expected ${wardCount}) ✓`);

  if (dryRun) {
    console.log(`\n  [dry-run] Would insert ${wardCount} dissolved ward polygons for ${city}`);
    for (let w = 1; w <= wardCount; w++) {
      const geoId = `${config.geoIdPrefix}${w}`;
      const precincts = wardMap.get(w)!;
      console.log(`    [dry-run] ${geoId} (dissolving ${precincts.length} precincts)`);
    }
    console.log('\n[load-ma-ward-boundaries] Dry-run complete (no DB writes).');
    return;
  }

  // ─── Step 3: Pre-flight DB check ──────────────────────────────────────────

  const existingCheck = await pool.query<{ cnt: string }>(`
    SELECT COUNT(*) AS cnt
    FROM essentials.geofence_boundaries
    WHERE geo_id LIKE $1 AND mtfcc = $2
  `, [`${config.geoIdPrefix}%`, MTFCC]);
  const existingCount = parseInt(existingCheck.rows[0].cnt, 10);

  if (existingCount > 0) {
    console.log(`\n  Pre-flight: ${existingCount} existing X0014 rows found for ${config.geoIdPrefix}* — re-run OK (ON CONFLICT DO NOTHING)`);
  } else {
    console.log(`\n  Pre-flight: No existing X0014 rows for ${config.geoIdPrefix}* — proceeding with insert`);
  }

  // ─── Step 4: INSERT each ward as a dissolved polygon ──────────────────────
  //
  // Option B (from research): Pass array of GeoJSON geometry strings to PostgreSQL
  // via unnest($5::text[]), then ST_Union aggregates them per INSERT.
  // This avoids dynamic SQL in JS and handles any number of precincts per ward.
  //
  // T-119-M1: All parameters via $N placeholders — never string-interpolate into SQL.
  // T-119-M3: wardMap has exactly wardCount entries verified above.

  let inserted = 0;
  let skipped  = 0;

  for (let wardNum = 1; wardNum <= wardCount; wardNum++) {
    const geoId     = `${config.geoIdPrefix}${wardNum}`;
    const name      = `${config.wardLabel} ${wardNum}`;
    const geometries = wardMap.get(wardNum)!;

    console.log(`\n  Inserting ${geoId} (dissolving ${geometries.length} precincts)...`);

    try {
      // CRITICAL (T-119-M1): All params via $N — NEVER string-interpolate into SQL.
      // ST_Union dissolves precinct polygons into a single ward polygon.
      // ST_MakeValid applied before and after union to handle self-intersections.
      // ST_ForcePolygonCCW ensures correct winding order for PostGIS.
      // ST_SetSRID(ST_Force2D(...), 4326) ensures correct SRID.
      const result = await pool.query(`
        INSERT INTO essentials.geofence_boundaries
          (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
        SELECT $1, $2, $3, $4, $5,
          public.ST_MakeValid(public.ST_Union(
            public.ST_MakeValid(public.ST_ForcePolygonCCW(
              public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON(geom_json)), 4326)
            ))
          )),
          $6, now()
        FROM unnest($7::text[]) AS geom_json
        ON CONFLICT (geo_id, mtfcc) DO NOTHING
      `, [geoId, geoId, name, STATE, MTFCC, SOURCE, geometries]);

      if (result.rowCount && result.rowCount > 0) {
        console.log(`  Inserted: ${geoId}`);
        inserted++;
      } else {
        console.log(`  Skipped (already exists): ${geoId}`);
        skipped++;
      }
    } catch (err) {
      console.error(`  ERROR inserting ${geoId}: ${(err as Error).message}`);
      process.exit(1);
    }
  }

  // ─── Step 5: Post-insert verification ─────────────────────────────────────
  //
  // T-119-M3: Verify total count = wardCount (dissolved wards, not raw precincts).

  console.log('\n  Summary:');
  console.log(`    Inserted: ${inserted}`);
  console.log(`    Skipped (already existed): ${skipped}`);

  const verify = await pool.query<{ cnt: string }>(`
    SELECT COUNT(*) AS cnt
    FROM essentials.geofence_boundaries
    WHERE geo_id LIKE $1
      AND mtfcc = $2
      AND state = $3
  `, [`${config.geoIdPrefix}%`, MTFCC, STATE]);

  const total = parseInt(verify.rows[0].cnt, 10);
  console.log(`\n  Total ${city} X0014 ward rows in geofence_boundaries: ${total}`);

  if (total !== wardCount) {
    console.warn(`  WARNING: Expected ${wardCount} rows, found ${total}`);
    console.warn(`  (This may indicate a partial run or conflict. Re-run to verify.)`);
  } else {
    console.log(`  All ${wardCount} ${city} ward polygons loaded successfully. ✓`);
  }

  console.log('\n[load-ma-ward-boundaries] Done.');
}

main()
  .catch((err) => {
    console.error('[load-ma-ward-boundaries] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
