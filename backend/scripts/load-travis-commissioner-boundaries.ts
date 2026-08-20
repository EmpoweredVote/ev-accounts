/**
 * load-travis-commissioner-boundaries.ts
 *
 * Fetches the 4 Travis County Commissioner precinct boundaries from Travis
 * County's OWN GIS server and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='travis-tx-commissioner-precinct-1'..'-4',
 *                                   mtfcc='X0031', state='tx'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structural migration
 * creates the LOCAL district rows and REPOINTS the existing commissioner offices.
 *
 * SOURCE CHOICE — several copies of this layer are published on ArcGIS Online
 * by third parties (a groundwater district, a tax-map vendor, individual
 * accounts), each a snapshot of unknown vintage. This loader uses the layer
 * served by TravisCountyGIS_TNR on gis.traviscountytx.gov, which is the county's
 * own authoritative service.
 *
 * COMMISSIONER PRECINCTS ARE NOT VOTER PRECINCTS. The City of Austin org
 * republishes `EXTERNAL_travis_voter_precincts` and `Travis_County_Election_Precincts`,
 * which hold HUNDREDS of small polygons. Those are election administration units;
 * the four commissioner precincts are unions of them. Loading the wrong one
 * would produce hundreds of districts for four seats.
 *
 * CRITICAL: outSR=4326 is mandatory. CRITICAL: f=geojson (NOT f=json).
 * CRITICAL: state='tx' LOWERCASE — LOCAL-tier routing join key.
 *
 * PRECINCT is an INTEGER field holding 1..4 and is the ONLY key used. The layer
 * also carries a COMMISSIONER name field; that is read as a staleness control
 * ONLY (see below) and never as an identity key, because it changes with
 * elections and appointments.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/load-travis-commissioner-boundaries.ts --dry-run
 *   npx tsx scripts/load-travis-commissioner-boundaries.ts
 */

import 'dotenv/config';
import { Pool } from 'pg';

const TRAVIS_PRECINCT_URL =
  'https://gis.traviscountytx.gov/server1/rest/services/Boundaries_and_Jurisdictions/' +
  'Travis_County_Commissioner_Precincts/FeatureServer/0/query' +
  '?where=1%3D1&outFields=PRECINCT,COMMISSIONER' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC          = 'X0031';
const STATE_CODE     = 'tx';
const SOURCE         = 'traviscountytx.gov-gis-Travis_County_Commissioner_Precincts-2026';
const GEO_ID_PREFIX  = 'travis-tx-commissioner-precinct-';
const EXPECTED_COUNT = 4;

/**
 * Positive controls — one point per precinct, so a uniform or collapsed answer
 * cannot pass. Established 2026-08-19 against the county service.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; precinct: number }> = [
  { name: 'Pflugerville (north)',    lon: -97.6200, lat: 30.4400, precinct: 1 },
  { name: 'The Domain (northwest)',  lon: -97.7256, lat: 30.4009, precinct: 2 },
  { name: 'Austin City Hall',        lon: -97.7470, lat: 30.2649, precinct: 3 },
  { name: 'Del Valle (southeast)',   lon: -97.6100, lat: 30.2000, precinct: 4 },
];

/**
 * Staleness control. These are the commissioners WE hold as seated. The layer
 * publishing a DIFFERENT name means one of the two is out of date and the load
 * should be re-verified by hand — it does not by itself say which. Precinct 4
 * is the sensitive one: George Morales holds it by APPOINTMENT, and Ballotpedia
 * was measured stale on exactly this seat, so a layer still naming the
 * predecessor is a layer that predates the appointment.
 *
 * A mismatch WARNS and does not abort: the geometry can be current while the
 * decorative name field lags.
 */
const EXPECTED_COMMISSIONERS: Record<number, string> = {
  1: 'Travillion',
  2: 'Shea',
  3: 'Howard',
  4: 'Morales',
};

const DRY_RUN = process.argv.includes('--dry-run');

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

type Feature = { properties: Record<string, unknown>; geometry: object | null };

/** Ray-cast point-in-polygon over a GeoJSON Polygon/MultiPolygon, holes honoured. */
function pointInGeometry(geom: any, lon: number, lat: number): boolean {
  const polys: number[][][][] = geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
  for (const poly of polys) {
    let inOuter = false;
    let inHole = false;
    poly.forEach((ring, idx) => {
      let hit = false;
      for (let a = 0, b = ring.length - 1; a < ring.length; b = a++) {
        const [xi, yi] = ring[a];
        const [xj, yj] = ring[b];
        if ((yi > lat) !== (yj > lat) && lon < ((xj - xi) * (lat - yi)) / (yj - yi) + xi) hit = !hit;
      }
      if (idx === 0) inOuter = hit;
      else if (hit) inHole = true;
    });
    if (inOuter && !inHole) return true;
  }
  return false;
}

async function main() {
  console.log('[load-travis-commissioner-boundaries] Fetching Travis County commissioner precincts');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  const response = (await (await fetch(TRAVIS_PRECINCT_URL)).json()) as { features?: Feature[] };

  if (!response?.features?.length) {
    console.error('ERROR: No features returned from the Travis County server. Check the URL.');
    process.exit(1);
  }
  console.log(`  Received ${response.features.length} features`);

  const precMap = new Map<number, { geoId: string; name: string; geomStr: string; geom: any; commissioner: string }>();
  for (const feature of response.features) {
    const raw = String(feature.properties['PRECINCT'] ?? '');
    const prec = parseInt(raw.replace(/\D+/g, ''), 10);
    if (isNaN(prec) || prec < 1 || prec > EXPECTED_COUNT) {
      console.warn(`  WARNING: PRECINCT '${raw}' out of range — skipping`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING: precinct ${prec} has no geometry — skipping`);
      continue;
    }
    if (precMap.has(prec)) {
      console.error(`ERROR: precinct ${prec} appeared twice. Aborting rather than guessing.`);
      process.exit(1);
    }
    precMap.set(prec, {
      geoId: `${GEO_ID_PREFIX}${prec}`,
      name: `Travis County Commissioner Precinct ${prec}`,
      geomStr: JSON.stringify(feature.geometry),
      geom: feature.geometry,
      commissioner: String(feature.properties['COMMISSIONER'] ?? ''),
    });
  }

  if (precMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} precincts, got ${precMap.size}. Aborting.`);
    process.exit(1);
  }
  console.log(`  Parsed precincts: ${[...precMap.keys()].sort((a, b) => a - b).join(', ')}`);

  // ─── Positive control: one point per precinct ─────────────────────────────
  console.log('\n  Positive control (one point per precinct):');
  let controlFailures = 0;
  for (const cp of CONTROL_POINTS) {
    const found = [...precMap.entries()]
      .filter(([, v]) => pointInGeometry(v.geom, cp.lon, cp.lat))
      .map(([p]) => p);
    const ok = found.length === 1 && found[0] === cp.precinct;
    if (!ok) controlFailures++;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  ${cp.name}: expected P${cp.precinct}, got ${found.length ? found.map((p) => 'P' + p).join('+') : 'none'}`,
    );
  }
  if (controlFailures > 0) {
    console.error(`\nERROR: ${controlFailures} control point(s) failed. Refusing to write.`);
    await pool.end();
    process.exit(1);
  }

  // ─── Staleness control: warn only ─────────────────────────────────────────
  console.log('\n  Staleness control (name field vs our seated holders — warn only):');
  for (const [prec, v] of [...precMap.entries()].sort((a, b) => a[0] - b[0])) {
    const expect = EXPECTED_COMMISSIONERS[prec];
    const match = v.commissioner.toLowerCase().includes(expect.toLowerCase());
    console.log(`    ${match ? 'match' : 'MISMATCH'}  P${prec}: layer says "${v.commissioner}", we hold "${expect}"`);
    if (!match) {
      console.warn(
        `    WARNING: P${prec} name disagrees. Geometry may still be current — verify by hand before trusting.`,
      );
    }
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — no database writes made.');
    await pool.end();
    process.exit(0);
  }

  let inserted = 0, alreadyExists = 0, repaired = 0;
  for (const [prec, { geoId, name, geomStr }] of [...precMap.entries()].sort((a, b) => a[0] - b[0])) {
    const result = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (id, geo_id, mtfcc, state, name, geometry, source)
       VALUES (gen_random_uuid(), $1, '${MTFCC}', '${STATE_CODE}', $2,
         public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)), $4)
       ON CONFLICT (geo_id, mtfcc) DO NOTHING
       RETURNING public.ST_GeometryType(geometry) AS gtype, public.ST_IsValid(geometry) AS valid`,
      [geoId, name, geomStr, SOURCE],
    );

    if ((result.rowCount ?? 0) === 0) {
      alreadyExists++;
      console.log(`  Precinct ${prec} (${geoId}): skipped (already exists)`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean };
    if (row.valid !== true) {
      console.error(`  Precinct ${prec} (${geoId}): ST_IsValid=false — applying ST_MakeValid`);
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
        console.error(`  ERROR: Precinct ${prec} still invalid after ST_MakeValid. Aborting.`);
        await pool.end();
        process.exit(1);
      }
      repaired++;
      console.log(`  Precinct ${prec} (${geoId}): repaired via ST_MakeValid`);
    } else {
      console.log(`  Precinct ${prec} (${geoId}): inserted (${row.gtype}, valid)`);
    }
    inserted++;
  }

  console.log(`\n=== Summary ===`);
  console.log(`  Inserted:        ${inserted}`);
  console.log(`  Already existed: ${alreadyExists}`);
  console.log(`  Repaired:        ${repaired}`);

  const check = await pool.query(
    `SELECT COUNT(*)::int AS n,
            COUNT(*) FILTER (WHERE NOT public.ST_IsValid(geometry))::int AS invalid
       FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`,
  );
  const { n, invalid } = check.rows[0] as { n: number; invalid: number };
  console.log(`  In DB now:       ${n} rows (${invalid} invalid)`);
  await pool.end();
  if (n !== EXPECTED_COUNT || invalid !== 0) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} valid rows, got ${n} with ${invalid} invalid.`);
    process.exit(1);
  }
  console.log('OK');
}

main().catch((err) => {
  console.error('[load-travis-commissioner-boundaries] Fatal error:', err);
  process.exit(1);
});
