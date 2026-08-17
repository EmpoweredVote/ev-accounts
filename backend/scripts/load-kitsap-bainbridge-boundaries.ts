/**
 * load-kitsap-bainbridge-boundaries.ts
 *
 * Fetches two REFERENCE boundary sets from the publishing jurisdictions' own
 * ArcGIS Online FeatureServers and inserts them into
 * essentials.geofence_boundaries:
 *
 *   mtfcc='X0027'  Kitsap County Commissioner Districts 1-3
 *                  geo_id='kitsapcounty-wa-commissioner-district-1'..'-3'
 *   mtfcc='X0028'  City of Bainbridge Island Council Wards (North/Central/South)
 *                  geo_id='bainbridgeisland-wa-ward-north' | '-central' | '-south'
 *
 * This loader writes ONLY to essentials.geofence_boundaries. Migration 1801
 * creates the matching essentials.districts rows.
 *
 * ============================================================================
 * !! READ THIS BEFORE ATTACHING ANY OFFICE TO THESE POLYGONS !!
 * ============================================================================
 * These six polygons are REFERENCE DATA. No office points at them, and that is
 * deliberate, not an unfinished step.
 *
 * NEITHER BODY IS ELECTED BY DISTRICT. Both nominate by district in the primary
 * and then elect JURISDICTION-WIDE in the general:
 *
 *   Kitsap commissioners  RCW 36.32.040(1): "the qualified electors of each
 *                         county commissioner district, and they only, shall
 *                         nominate ... candidates". RCW 36.32.050(1): those
 *                         candidates "shall be elected by the qualified voters
 *                         of THE COUNTY", with the winner "for the district in
 *                         which he or she resides". RCW 36.32.052's mandatory
 *                         district-based ELECTION binds only noncharter counties
 *                         of 400,000+; Kitsap is ~276,000 and noncharter, so it
 *                         stays on the countywide general.
 *   Bainbridge council    BIMC 2.06 + bainbridgewa.gov/219/Council-Representation:
 *                         ward voters nominate in the primary; ALL city voters
 *                         vote every position in the general. Position 1 is
 *                         at-large outright.
 *
 * So a commissioner district is a RESIDENCY + NOMINATION district, never an
 * election district. Migration 1800 attaches all 9 Kitsap offices to the county
 * polygon (53035/G4020) and all 7 Bainbridge offices to the city polygon
 * (5303736/G4110), because that is who actually votes on them. Re-pointing an
 * office at one of these six polygons would hide two of three commissioners --
 * and four of seven councilmembers -- from every address, and would hide the
 * countywide Commissioner District 3 race from roughly two thirds of Kitsap
 * voters on the elections surface.
 *
 * ============================================================================
 * LAYER CHOICE -- the vintage trap, same shape as King County's KCCDST_AREA_185
 * ============================================================================
 * ArcGIS Online carries FOUR Kitsap commissioner-district services. Three load
 * without error and would silently seed obsolete boundaries:
 *     KitsapCountyGIS / County_Commissioner_District_Outlines  <- CURRENT (2025-10-09)
 *         snippet: "the Kitsap County Commissioner District boundaries for
 *         voting purposes"; owned by the county's GIS account.
 *     KitsapCountyDCD / Commissioner_Districts                 <- 2019-03-27, stale
 *     wec.staff / Commissioner_Districts                       <- 2022-01-19, third party
 *     kevin_genasys / commdist                                 <- third party
 * The current layer was cross-checked point-in-polygon against kevin_genasys/
 * commdist at four addresses and agreed on all four: Bainbridge Island and
 * Poulsbo -> D1, Port Orchard and Bremerton -> D2, Silverdale -> D3.
 * NOTE press coverage loosely describes D3 as "Bremerton and Central Kitsap";
 * both published layers put central Bremerton in D2. Trust the layers.
 *
 * Bainbridge publishes exactly one: cobiuser1 / Council_Districts, whose single
 * layer is named Council_Wards ("City of Bainbridge Island Council Districts and
 * voting districts", updated 2025-05-28).
 *
 * !! THE SOUTH WARD IS NOT SHAPED LIKE ITS NAME. It reaches up the WEST shore to
 * about 47.67N -- precincts 320 and 333, the Battle Point / Arrow Point /
 * Fletcher Bay area -- which is well NORTH of the Central Ward. Central Ward is
 * only the compact Winslow core (~3.5 sq mi against North 11.5 and South 12.2).
 * A point at 47.6497N, -122.5628W really does return South Ward. This was
 * confirmed against the city's own published map before loading:
 * bainbridgewa.gov/DocumentCenter/View/18763/Current-Wards-with-Precincts
 * Do not "fix" this against a north/central/south intuition.
 *
 * ============================================================================
 * CRITICAL, inherited verbatim from load-kingcounty-council-boundaries.ts
 * ============================================================================
 * CRITICAL: outSR=4326 is mandatory. Kitsap's native CRS is WKID 2285 and
 * Bainbridge's is WKID 6597 -- both projected State Plane feet. Without
 * outSR=4326, ST_GeomFromGeoJSON stores feet, not degrees, and every
 * point-in-polygon lookup silently misses.
 * CRITICAL: f=geojson (NOT f=json) -- yields a FeatureCollection whose
 * feature.geometry goes straight into ST_GeomFromGeoJSON.
 * CRITICAL: state='wa' LOWERCASE -- required for the LOCAL-tier routing join key.
 *
 * Identity comes from the STABLE CODE FIELD (Kitsap DISTRICT '1'..'3';
 * Bainbridge COUNCIL 'N'/'C'/'S'), never from a member name -- the San Diego
 * lesson. Neither layer carries a member name, which is the good case.
 *
 * SIZE: these are shoreline-detailed, land-only polygons and they are big.
 * Kitsap D1 alone is ~146k vertices (King County's worst is ~30k). They are
 * loaded unsimplified to match house style; the browse-overlap resolver is
 * bounding-box pre-filtered per branch (see project_geofence_overlap_perf), so
 * the cost lands only on queries whose bbox already touches Kitsap.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-kitsap-bainbridge-boundaries.ts --dry-run
 *   npx tsx scripts/load-kitsap-bainbridge-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as https from 'https';
import * as http from 'http';

// ─── Config ───────────────────────────────────────────────────────────────────

interface LayerSpec {
  key: string;
  url: string;
  mtfcc: string;
  source: string;
  expected: number;
  /** Maps a feature's attributes to a stable (geo_id, name) pair, or null to skip. */
  identify: (props: Record<string, unknown>) => { geoId: string; name: string } | null;
}

const KITSAP_COMMISSIONER: LayerSpec = {
  key: 'kitsap-commissioner',
  url:
    'https://services6.arcgis.com/qt3UCV9x5kB4CwRA/arcgis/rest/services/' +
    'County_Commissioner_District_Outlines/FeatureServer/0/query' +
    '?where=1%3D1&outFields=DISTRICT' +
    '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100',
  mtfcc: 'X0027', // next unclaimed after X0026 (King County council)
  source: 'kitsapgov-arcgis-County_Commissioner_District_Outlines-2025-10-09',
  expected: 3,
  identify: (props) => {
    const raw = String(props['DISTRICT'] ?? '').trim();
    if (!/^[123]$/.test(raw)) return null;
    return {
      geoId: `kitsapcounty-wa-commissioner-district-${raw}`,
      name: `Kitsap County Commissioner District ${raw}`,
    };
  },
};

const BAINBRIDGE_WARD: LayerSpec = {
  key: 'bainbridge-ward',
  url:
    'https://services5.arcgis.com/0Q6HuHqqcg7Zo8zH/arcgis/rest/services/' +
    'Council_Districts/FeatureServer/0/query' +
    '?where=1%3D1&outFields=COUNCIL,DIMS' +
    '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100',
  mtfcc: 'X0028',
  source: 'bainbridgewa-arcgis-Council_Wards-2025-05-28',
  expected: 3,
  identify: (props) => {
    const code = String(props['COUNCIL'] ?? '').trim().toUpperCase();
    const WARDS: Record<string, string> = { N: 'North', C: 'Central', S: 'South' };
    const ward = WARDS[code];
    if (!ward) return null;
    return {
      geoId: `bainbridgeisland-wa-ward-${ward.toLowerCase()}`,
      name: `Bainbridge Island ${ward} Ward`,
    };
  },
};

const LAYERS: LayerSpec[] = [KITSAP_COMMISSIONER, BAINBRIDGE_WARD];

const STATE_CODE = 'wa'; // CRITICAL: lowercase — LOCAL-tier routing key
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

interface Loaded { geoId: string; name: string; geomStr: string }

async function collect(spec: LayerSpec): Promise<Loaded[]> {
  console.log(`\n[${spec.key}] fetching ${spec.mtfcc}`);
  const response = await fetchJson(spec.url) as {
    features?: Array<{ properties: Record<string, unknown>; geometry: object | null }>;
  };

  if (!response?.features?.length) {
    console.error(`ERROR: no features returned for ${spec.key}. Check the URL.`);
    process.exit(1);
  }
  console.log(`  received ${response.features.length} features`);

  const byGeoId = new Map<string, Loaded>();
  for (const feature of response.features) {
    const id = spec.identify(feature.properties ?? {});
    if (!id) {
      console.warn(`  WARNING: unrecognised attributes ${JSON.stringify(feature.properties)} — skipping`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING: ${id.geoId} has no geometry — skipping`);
      continue;
    }
    if (byGeoId.has(id.geoId)) {
      console.error(`ERROR: duplicate geo_id ${id.geoId} in source layer. Aborting.`);
      process.exit(1);
    }
    byGeoId.set(id.geoId, { ...id, geomStr: JSON.stringify(feature.geometry) });
    console.log(`  ${id.geoId}  ->  ${id.name}`);
  }

  if (byGeoId.size !== spec.expected) {
    console.error(`ERROR: expected ${spec.expected} features for ${spec.key}, got ${byGeoId.size}. Aborting.`);
    process.exit(1);
  }
  return Array.from(byGeoId.values()).sort((a, b) => a.geoId.localeCompare(b.geoId));
}

async function insertLayer(spec: LayerSpec, rows: Loaded[]): Promise<void> {
  let inserted = 0, alreadyExists = 0, repaired = 0;

  for (const { geoId, name, geomStr } of rows) {
    const result = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (id, geo_id, mtfcc, state, name, geometry, source)
       VALUES (gen_random_uuid(), $1, $2, $3, $4,
         public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($5), 4326)),
         $6)
       ON CONFLICT (geo_id, mtfcc) DO NOTHING
       RETURNING public.ST_GeometryType(geometry) AS gtype,
                 public.ST_IsValid(geometry)      AS valid,
                 public.ST_NPoints(geometry)      AS npoints`,
      [geoId, spec.mtfcc, STATE_CODE, name, geomStr, spec.source],
    );

    if ((result.rowCount ?? 0) === 0) {
      alreadyExists++;
      console.log(`  ${geoId}: skipped (already exists)`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean; npoints: number };
    if (row.valid !== true) {
      console.error(`  ${geoId}: ST_IsValid=false (${row.gtype}) — applying ST_MakeValid`);
      await pool.query(
        `UPDATE essentials.geofence_boundaries
            SET geometry = public.ST_Multi(public.ST_MakeValid(
              public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)))
          WHERE geo_id = $1 AND mtfcc = $2`,
        [geoId, spec.mtfcc, geomStr],
      );
      const recheck = await pool.query(
        `SELECT public.ST_IsValid(geometry) AS valid
           FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = $2`,
        [geoId, spec.mtfcc],
      );
      if ((recheck.rows[0] as { valid: boolean })?.valid !== true) {
        console.error(`  ERROR: ${geoId} still invalid after ST_MakeValid. Aborting.`);
        await pool.end();
        process.exit(1);
      }
      repaired++;
      console.log(`  ${geoId}: repaired via ST_MakeValid (now valid)`);
    } else {
      console.log(`  ${geoId}: inserted (${row.gtype}, valid, ${row.npoints} vertices)`);
    }
    inserted++;
  }

  console.log(`  --- ${spec.key}: inserted ${inserted}, already existed ${alreadyExists}, repaired ${repaired}`);

  const check = await pool.query(
    `SELECT COUNT(*)::int AS n,
            COUNT(*) FILTER (WHERE NOT public.ST_IsValid(geometry))::int AS invalid
       FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
    [spec.mtfcc],
  );
  const { n, invalid } = check.rows[0] as { n: number; invalid: number };
  console.log(`  --- ${spec.key}: in DB now ${n} rows (${invalid} invalid)`);
  if (n !== spec.expected || invalid !== 0) {
    console.error(`ERROR: expected ${spec.expected} valid ${spec.mtfcc} rows, got ${n} with ${invalid} invalid.`);
    await pool.end();
    process.exit(1);
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('[load-kitsap-bainbridge-boundaries] Kitsap commissioner districts + Bainbridge council wards');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const collected: Array<{ spec: LayerSpec; rows: Loaded[] }> = [];
  for (const spec of LAYERS) {
    collected.push({ spec, rows: await collect(spec) });
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    console.log('  (sanity check: coords should be ~-122.5° lon, ~47.6° lat for Kitsap County, WA)');
    await pool.end();
    process.exit(0);
  }

  for (const { spec, rows } of collected) {
    await insertLayer(spec, rows);
  }

  console.log('\nOK');
  await pool.end();
}

main().catch((err) => {
  console.error('[load-kitsap-bainbridge-boundaries] Fatal error:', err);
  process.exit(1);
});
