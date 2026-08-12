#!/usr/bin/env node
/**
 * Load delegate-district polygons for the five U.S. territories into essentials.geofence_boundaries.
 *
 * WHY THIS EXISTS: ADR 0003 calls the territories a "powers-only" change, which is true of the SEAT
 * but not of the DATA — we held nothing at all for PR, VI, GU, AS or MP, including no geometry. And
 * unlike Maine's tribal seats, a territory delegate is RESIDENCY-based: a San Juan address should
 * return the Resident Commissioner. Without a polygon that can never happen, so seeding the seats
 * without geometry would manufacture exactly the UNREACHABLE defect check:reachability exists to
 * catch.
 *
 * Each territory elects its delegate at large, so the delegate district IS the territory. We load one
 * polygon per territory under the congressional-district geo_id (FIPS + '98', the Census convention
 * for a non-voting delegate district — DC is already '1198' here) with MTFCC G5200, matching how DC's
 * delegate district is already stored.
 *
 * Source is the Census TIGERweb REST service, which returns GeoJSON directly — no shapefile tooling
 * needed. 🔴 It is fetched over the network, so this script VERIFIES what it got rather than trusting
 * it: geometry valid, non-empty, and a known city in each territory actually falls inside the polygon.
 * A silently-wrong or empty polygon is indistinguishable from a working one until a resident gets no
 * representative, which is precisely the failure this repo keeps re-learning.
 *
 *   node scripts/load-territory-boundaries.mjs            # verify only, no writes
 *   node scripts/load-territory-boundaries.mjs --write    # upsert
 */
import 'dotenv/config';
import { Pool } from 'pg';

const WRITE = process.argv.includes('--write');

// FIPS -> everything needed, plus a real place used to prove the polygon covers its own territory.
// Coordinates are lon/lat. AS is in the SOUTHERN hemisphere and near the antimeridian; MP and GU sit
// just west of it. Those are the ones a bad reprojection would quietly ruin, which is why each is
// checked rather than assumed.
const TERRITORIES = [
  { fips: '72', usps: 'pr', name: 'Puerto Rico',                                    city: 'San Juan',        lon: -66.1057, lat: 18.4655 },
  { fips: '78', usps: 'vi', name: 'United States Virgin Islands',                   city: 'Charlotte Amalie', lon: -64.9307, lat: 18.3419 },
  { fips: '66', usps: 'gu', name: 'Guam',                                           city: 'Hagatna',         lon: 144.7502, lat: 13.4745 },
  { fips: '60', usps: 'as', name: 'American Samoa',                                 city: 'Pago Pago',       lon: -170.7020, lat: -14.2756 },
  { fips: '69', usps: 'mp', name: 'Commonwealth of the Northern Mariana Islands',   city: 'Saipan',          lon: 145.7500, lat: 15.1900 },
];

const cdGeoId = (fips) => `${fips}98`;

async function fetchGeo() {
  const url = new URL(
    'https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/State_County/MapServer/0/query',
  );
  url.searchParams.set('where', `GEOID IN (${TERRITORIES.map((t) => `'${t.fips}'`).join(',')})`);
  url.searchParams.set('outFields', 'GEOID,NAME');
  url.searchParams.set('returnGeometry', 'true');
  url.searchParams.set('f', 'geojson');

  const res = await fetch(url);
  if (!res.ok) throw new Error(`TIGERweb HTTP ${res.status}`);
  const body = await res.json();
  // An ArcGIS error comes back as HTTP 200 with an {error:{...}} body — never judge by res.ok alone.
  if (body.error) throw new Error(`TIGERweb error: ${JSON.stringify(body.error).slice(0, 200)}`);
  const feats = body.features || [];
  if (feats.length !== TERRITORIES.length) {
    throw new Error(`expected ${TERRITORIES.length} features, got ${feats.length}`);
  }
  return new Map(feats.map((f) => [f.properties.GEOID, f]));
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const byFips = await fetchGeo();
let failures = 0;

for (const t of TERRITORIES) {
  const feat = byFips.get(t.fips);
  const gj = JSON.stringify(feat.geometry);

  // Validate and prove coverage BEFORE writing anything.
  const { rows: [chk] } = await pool.query(
    `WITH g AS (SELECT public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1), 4326)) AS geom)
     SELECT public.ST_IsValid(geom)                       AS valid,
            public.ST_IsEmpty(geom)                       AS empty,
            public.ST_Covers(geom, public.ST_SetSRID(public.ST_MakePoint($2, $3), 4326)) AS covers_city,
            round(public.ST_Area(geom)::numeric, 6)       AS area
       FROM g`,
    [gj, t.lon, t.lat],
  );

  const ok = chk.valid && !chk.empty && chk.covers_city;
  console.log(
    `${t.usps.toUpperCase()} ${t.name}\n`
    + `   geo_id ${cdGeoId(t.fips)}  valid=${chk.valid} empty=${chk.empty} area=${chk.area}\n`
    + `   ${t.city} inside polygon: ${chk.covers_city ? 'YES' : '** NO **'}  ${ok ? '' : '<-- REJECTED'}`,
  );
  if (!ok) { failures++; continue; }

  if (WRITE) {
    await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (geo_id, name, state, mtfcc, geometry, source, imported_at)
       VALUES ($1, $2, $3, 'G5200',
               public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($4), 4326)),
               $5, now())
       ON CONFLICT DO NOTHING`,
      [cdGeoId(t.fips), `${t.name} Delegate District (at Large)`, t.fips, gj,
       'Census TIGERweb State_County layer, loaded by scripts/load-territory-boundaries.mjs'],
    );
  }
}

if (failures) {
  console.error(`\nFAIL: ${failures} territory polygon(s) rejected — nothing written for those.`);
  await pool.end();
  process.exit(1);
}

if (WRITE) {
  const { rows } = await pool.query(
    `SELECT geo_id, mtfcc, public.ST_IsValid(geometry) AS valid
       FROM essentials.geofence_boundaries
      WHERE geo_id = ANY($1) ORDER BY geo_id`,
    [TERRITORIES.map((t) => cdGeoId(t.fips))],
  );
  console.log(`\nin database now: ${rows.map((r) => `${r.geo_id}(valid=${r.valid})`).join(' ')}`);
  console.log(rows.length === TERRITORIES.length ? 'OK — all five loaded.' : '** not all five present **');
} else {
  console.log('\nverify-only. Re-run with --write to load.');
}

await pool.end();
