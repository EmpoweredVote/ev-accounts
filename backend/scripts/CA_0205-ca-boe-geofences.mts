/**
 * CA_0205-ca-boe-geofences.mts — California's four State Board of Equalization districts
 * -> essentials.geofence_boundaries as mtfcc='X-CA-SBOE', geo_id '06-sboe-d1'..'06-sboe-d4'.
 * Run BEFORE migration CA_0205, whose districts point at these rows.
 *
 * PROVENANCE: the 2021 Citizens Redistricting Commission BOE map (in force 2023-2032), as served by
 *   the State of California GIS service, layer 3 "Board of Equalization":
 *     https://services.gis.ca.gov/arcgis/rest/services/Government/CaliforniaDistricts/MapServer/3
 *   Fetched 2026-09-23 as GeoJSON in EPSG:4326 (4 features, field DISTRICT "1".."4"):
 *     .../MapServer/3/query?where=1%3D1&outFields=DISTRICT,NAME,POPULATION&returnGeometry=true
 *       &outSR=4326&geometryPrecision=6&f=geojson          (1,383,333 bytes, sha256 prefix e7060eef4c3c4f48)
 *
 * WHY A POLYGON AND NOT A UNION OF COUNTIES. BOE-2 and BOE-3 are whole counties, but San Bernardino
 * County is split between BOE-1 (99% of its area) and BOE-4 (1%) — the SoS BOE page lists it under
 * both. A county union would put the voters in one part of it in the wrong district.
 *
 * STOP GUARDS (all inside the insert transaction, against the inserted rows):
 *   - exactly 4 features, districts 1..4, each once;
 *   - BOE-3 equals our LA County geofence (06037 G4020), and BOE-2 equals the union of its 19
 *     counties' G4020 geofences — each within 0.1% symmetric difference. These are the positive
 *     controls: independent geometry (Census TIGER) that the official map must reproduce;
 *   - no two districts overlap (intersection < 0.01% of the smaller);
 *   - city anchors land in their published district: Sacramento 1, Fresno 1, San Francisco 2,
 *     Santa Barbara 2, Los Angeles 3, San Diego 4, Riverside 4.
 *
 * Usage (from backend/):
 *   npx tsx scripts/CA_0205-ca-boe-geofences.mts --geojson <path> --dry-run   # runs every guard, then ROLLBACK
 *   npx tsx scripts/CA_0205-ca-boe-geofences.mts --geojson <path>             # same, then COMMIT
 *
 * ON CONFLICT (geo_id, mtfcc) DO NOTHING, so a re-run inserts nothing.
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as fs from 'fs';

const MTFCC = 'X-CA-SBOE';
const SOURCE = 'ca_crc_boe_2021';
const DRY_RUN = process.argv.includes('--dry-run');
const pathIdx = process.argv.indexOf('--geojson');
const GEOJSON_PATH = pathIdx > -1 ? process.argv[pathIdx + 1] : undefined;

const GEOM_EXPR = (i: number) =>
  `public.ST_CollectionExtract(public.ST_MakeValid(` +
  `public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($${i})),4326)),3)`;

const BOE2_COUNTIES = [
  'Alameda', 'Contra Costa', 'Del Norte', 'Humboldt', 'Lake', 'Marin', 'Mendocino', 'Monterey', 'Napa',
  'San Benito', 'San Francisco', 'San Luis Obispo', 'San Mateo', 'Santa Barbara', 'Santa Clara',
  'Santa Cruz', 'Sonoma', 'Trinity', 'Ventura',
];

const ANCHORS: Array<[string, number, number, number]> = [
  ['Sacramento', 1, -121.4944, 38.5816], ['Fresno', 1, -119.7871, 36.7378],
  ['San Francisco', 2, -122.4194, 37.7749], ['Santa Barbara', 2, -119.6982, 34.4208],
  ['Los Angeles', 3, -118.2437, 34.0522], ['San Diego', 4, -117.1611, 32.7157],
  ['Riverside', 4, -117.3962, 33.9533],
];

function fail(msg: string): never {
  throw new Error(`STOP: ${msg}`);
}

async function main(): Promise<void> {
  if (!GEOJSON_PATH) fail('pass --geojson <path to the fetched FeatureCollection>');
  const fc = JSON.parse(fs.readFileSync(GEOJSON_PATH, 'utf8')) as {
    type: string; features: Array<{ geometry: unknown; properties: Record<string, unknown> }>;
  };
  if (fc.type !== 'FeatureCollection') fail(`expected a FeatureCollection, got ${fc.type}`);
  if (fc.features.length !== 4) fail(`expected 4 features, got ${fc.features.length}`);
  const rows = fc.features.map((f) => ({ n: Number(f.properties.DISTRICT), geom: JSON.stringify(f.geometry) }));
  const nums = rows.map((r) => r.n).sort();
  if (nums.join(',') !== '1,2,3,4') fail(`expected districts 1,2,3,4 once each, got ${nums.join(',')}`);

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    let inserted = 0;
    for (const r of rows) {
      const res = await client.query(
        `INSERT INTO essentials.geofence_boundaries (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
         VALUES ($1, $2, $3, '06', $4, ${GEOM_EXPR(5)}, $6, now())
         ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
        [`06-sboe-d${r.n}`, `ocd-division/country:us/state:ca/sboe:${r.n}`,
         `California Board of Equalization District ${r.n}`, MTFCC, r.geom, SOURCE],
      );
      inserted += res.rowCount ?? 0;
    }
    console.log(`inserted ${inserted} of 4 (the rest already existed)`);

    const boe = `SELECT substring(geo_id from 'd([0-9])$')::int AS n, geometry AS g
                   FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`;

    const { rows: [cnt] } = await client.query(`SELECT count(*)::int AS c FROM (${boe}) b`);
    if (cnt.c !== 4) fail(`expected 4 ${MTFCC} rows after insert, found ${cnt.c}`);

    const { rows: [c3] } = await client.query(
      `SELECT public.ST_Area(public.ST_SymDifference(b.g, c.geometry)) / public.ST_Area(c.geometry) AS s
         FROM (${boe}) b, essentials.geofence_boundaries c
        WHERE b.n = 3 AND c.geo_id = '06037' AND c.mtfcc = 'G4020'`);
    const { rows: [c2] } = await client.query(
      `WITH u AS (SELECT public.ST_Union(geometry) g FROM essentials.geofence_boundaries
                   WHERE mtfcc = 'G4020' AND state = '06' AND name = ANY($1))
       SELECT public.ST_Area(public.ST_SymDifference(b.g, u.g)) / public.ST_Area(u.g) AS s
         FROM (${boe}) b, u WHERE b.n = 2`, [BOE2_COUNTIES.map((c) => `${c} County`)]);
    console.log(`control BOE-3 vs LA County: ${Number(c3.s).toFixed(5)}   BOE-2 vs 19 counties: ${Number(c2.s).toFixed(5)}`);
    if (!(Number(c3.s) < 0.001)) fail(`BOE-3 does not reproduce LA County (symdiff ${c3.s})`);
    if (!(Number(c2.s) < 0.001)) fail(`BOE-2 does not reproduce its 19 counties (symdiff ${c2.s})`);

    const { rows: [ov] } = await client.query(
      `SELECT max(public.ST_Area(public.ST_Intersection(a.g, b.g)) / least(public.ST_Area(a.g), public.ST_Area(b.g))) AS m
         FROM (${boe}) a JOIN (${boe}) b ON a.n < b.n`);
    console.log(`max pairwise overlap share: ${Number(ov.m).toFixed(7)}`);
    if (!(Number(ov.m) < 0.0001)) fail(`districts overlap (share ${ov.m})`);

    for (const [city, expect, lon, lat] of ANCHORS) {
      const { rows: hit } = await client.query(
        `SELECT n FROM (${boe}) b WHERE public.ST_Covers(b.g, public.ST_SetSRID(public.ST_MakePoint($1, $2), 4326))`,
        [lon, lat]);
      const got = hit.map((h) => h.n).join(',');
      console.log(`anchor ${city}: BOE-${got || 'none'} (expect ${expect})`);
      if (got !== String(expect)) fail(`${city} resolves to BOE-${got || 'none'}, expected ${expect}`);
    }

    await client.query(DRY_RUN ? 'ROLLBACK' : 'COMMIT');
    console.log(DRY_RUN ? 'DRY-RUN: every guard passed; rolled back.' : 'COMMITTED: every guard passed.');
  } catch (e) {
    await client.query('ROLLBACK').catch(() => undefined);
    throw e;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : e);
  process.exit(1);
});
