#!/usr/bin/env node
/**
 * Load Puerto Rico's 78 municipio polygons into essentials.geofence_boundaries.
 *
 * WHY: migration 1720 gave PR its Governor and legislature but no municipal layer at all —
 * we held 52 PR boundaries, every one of them legislative. A municipio is the unit of local
 * government on the island (there are no counties and no separate cities), so without these
 * polygons a San Juan address can never return its alcalde. Seeding the mayors without
 * geometry would manufacture exactly the UNREACHABLE defect check:reachability exists to catch.
 *
 * 🔴 GEO_ID COLLISION, BY DESIGN. Municipio FIPS run 72001..72153 and PR's senatorial (G5210,
 * 72001..72008) and representative (G5220, 72001..72040) districts already occupy the same
 * five-digit space — 72001 is simultaneously Adjuntas, Senate District 1 and House District 1.
 * That is what MTFCC_DISTRICT_TYPE_GUARD is for: these rows carry MTFCC G4020, which resolves
 * only to a LOCAL_EXEC municipio (PR-scoped clause) and never to a legislative district.
 * NEVER join districts to boundaries on geo_id alone for PR.
 *
 * Source: Census TIGERweb, State_County MapServer LAYER 1 (Counties). PR municipios are
 * county-equivalents there, named "<Municipio> Municipio", MTFCC G4020.
 *
 * 🔴 Fetched over the network, so this VERIFIES rather than trusts. A silently-wrong polygon is
 * indistinguishable from a working one until a resident gets no mayor. Three checks:
 *   1. per-polygon: valid, non-empty;
 *   2. structural: the 78 must TILE the territory — no pairwise overlap beyond a sliver, and
 *      their union must match the PR state polygon's area closely. A duplicated or dropped
 *      municipio fails this even when every individual polygon looks fine;
 *   3. spot: eight known coordinates must land in the RIGHT municipio, including Vieques and
 *      Culebra (offshore islands a bad extent would swallow) and Florida/San Sebastián, whose
 *      names collide with places off-island.
 *
 *   node scripts/load-pr-municipio-boundaries.mjs            # verify only, no writes
 *   node scripts/load-pr-municipio-boundaries.mjs --write    # upsert
 */
import 'dotenv/config';
import { Pool } from 'pg';

const WRITE = process.argv.includes('--write');
const LAYER =
  'https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/State_County/MapServer/1/query';
const STATE_LAYER =
  'https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/State_County/MapServer/0/query';
const EXPECTED = 78;

// lon/lat -> the municipio FIPS that must contain it. Chosen to break specific failure modes,
// not just to sample: the two island municipios, the two name-collision municipios, and the
// four largest population centres.
const SPOT = [
  { name: 'San Juan (El Capitolio)', lon: -66.1057, lat: 18.4655, fips: '72127' },
  { name: 'Ponce (Plaza Las Delicias)', lon: -66.6141, lat: 18.0111, fips: '72113' },
  { name: 'Mayagüez (Plaza Colón)', lon: -67.1397, lat: 18.2013, fips: '72097' },
  { name: 'Bayamón (city centre)', lon: -66.1553, lat: 18.3985, fips: '72021' },
  { name: 'Caguas (city centre)', lon: -66.0353, lat: 18.2341, fips: '72025' },
  { name: 'Vieques (Isabel Segunda)', lon: -65.4436, lat: 18.1497, fips: '72147' },
  { name: 'Culebra (Dewey)', lon: -65.3009, lat: 18.3033, fips: '72049' },
  { name: 'San Sebastián (pueblo)', lon: -66.9905, lat: 18.3372, fips: '72131' },
];

async function arc(url, params) {
  const u = new URL(url);
  for (const [k, v] of Object.entries(params)) u.searchParams.set(k, v);
  const res = await fetch(u);
  if (!res.ok) throw new Error(`TIGERweb HTTP ${res.status}`);
  const body = await res.json();
  // An ArcGIS error is HTTP 200 with an {error:{...}} body — never judge by res.ok alone.
  if (body.error) throw new Error(`TIGERweb error: ${JSON.stringify(body.error).slice(0, 200)}`);
  return body;
}

const muni = await arc(LAYER, {
  where: "GEOID LIKE '72%'",
  outFields: 'GEOID,NAME,MTFCC',
  returnGeometry: 'true',
  outSR: '4326',
  f: 'geojson',
});
const feats = muni.features || [];
console.log(`TIGERweb returned ${feats.length} municipio features`);
if (feats.length !== EXPECTED) {
  console.error(`FAIL: expected ${EXPECTED}, got ${feats.length} — refusing to load a partial island.`);
  process.exit(1);
}
const badMtfcc = feats.filter((f) => f.properties.MTFCC !== 'G4020');
if (badMtfcc.length) {
  console.error(`FAIL: ${badMtfcc.length} feature(s) are not G4020.`);
  process.exit(1);
}

const state = await arc(STATE_LAYER, {
  where: "GEOID = '72'",
  outFields: 'GEOID,NAME',
  returnGeometry: 'true',
  outSR: '4326',
  f: 'geojson',
});

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const clean = (n) => n.replace(/\s+Municipio$/i, '').trim();
let failures = 0;

// ---- 1. per-polygon validity
const rows = [];
for (const f of feats) {
  const gj = JSON.stringify(f.geometry);
  const { rows: [c] } = await pool.query(
    `WITH g AS (SELECT public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326)) AS geom)
     SELECT public.ST_IsValid(geom) AS valid, public.ST_IsEmpty(geom) AS empty,
            round(public.ST_Area(geom)::numeric, 8) AS area FROM g`,
    [gj],
  );
  if (!c.valid || c.empty) {
    console.error(`  REJECT ${f.properties.GEOID} ${f.properties.NAME}: valid=${c.valid} empty=${c.empty}`);
    failures++;
    continue;
  }
  rows.push({ geo_id: f.properties.GEOID, name: clean(f.properties.NAME), gj, area: Number(c.area) });
}
console.log(`per-polygon validity: ${rows.length}/${feats.length} usable`);

// ---- 2. structural: do the 78 tile the territory?
const { rows: [tile] } = await pool.query(
  `WITH m AS (SELECT public.ST_Union(public.ST_MakeValid(
                public.ST_SetSRID(public.ST_GeomFromGeoJSON(j),4326))) AS u
              FROM unnest($1::text[]) AS j),
        s AS (SELECT public.ST_MakeValid(
                public.ST_SetSRID(public.ST_GeomFromGeoJSON($2),4326)) AS g)
   SELECT round(public.ST_Area((SELECT u FROM m))::numeric, 8) AS union_area,
          round(public.ST_Area((SELECT g FROM s))::numeric, 8) AS state_area,
          round(public.ST_Area(public.ST_Difference((SELECT g FROM s),(SELECT u FROM m)))::numeric, 8)
            AS uncovered`,
  [rows.map((r) => r.gj), JSON.stringify(state.features[0].geometry)],
);
const sumParts = rows.reduce((s, r) => s + r.area, 0);
const overlap = sumParts - Number(tile.union_area);
const ratio = Number(tile.union_area) / Number(tile.state_area);
console.log(
  `tiling: union=${tile.union_area} state=${tile.state_area} ratio=${ratio.toFixed(6)}\n`
  + `        sum(parts)-union = ${overlap.toFixed(8)} (pairwise overlap)\n`
  + `        state area not covered by any municipio = ${tile.uncovered}`,
);
if (ratio < 0.999 || ratio > 1.001) {
  console.error('FAIL: municipio union does not match the territory area — a municipio is missing or duplicated.');
  failures++;
}
if (Math.abs(overlap) > 1e-4) {
  console.error('FAIL: municipios overlap each other beyond a rounding sliver.');
  failures++;
}

// ---- 3. spot checks against known coordinates
console.log('spot checks:');
for (const s of SPOT) {
  const r = rows.find((x) => x.geo_id === s.fips);
  if (!r) { console.error(`  ${s.name}: FIPS ${s.fips} absent`); failures++; continue; }
  const { rows: [hit] } = await pool.query(
    `SELECT public.ST_Covers(
              public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326),
              public.ST_SetSRID(public.ST_MakePoint($2,$3),4326)) AS inside`,
    [r.gj, s.lon, s.lat],
  );
  // and prove it is inside NO OTHER municipio -- containment alone would pass on a polygon
  // that had swallowed the whole island.
  let others = 0;
  for (const o of rows) {
    if (o.geo_id === s.fips) continue;
    const { rows: [h2] } = await pool.query(
      `SELECT public.ST_Covers(
                public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326),
                public.ST_SetSRID(public.ST_MakePoint($2,$3),4326)) AS inside`,
      [o.gj, s.lon, s.lat],
    );
    if (h2.inside) others++;
  }
  const ok = hit.inside && others === 0;
  console.log(`  ${ok ? 'OK  ' : 'FAIL'} ${s.name.padEnd(26)} -> ${r.name} (${s.fips})`
    + `${hit.inside ? '' : '  NOT INSIDE'}${others ? `  ALSO IN ${others} OTHER(S)` : ''}`);
  if (!ok) failures++;
}

if (failures) {
  console.error(`\nFAIL: ${failures} check(s) failed — nothing written.`);
  await pool.end();
  process.exit(1);
}

if (WRITE) {
  let n = 0;
  for (const r of rows) {
    await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (geo_id, name, state, mtfcc, geometry, source, imported_at)
       VALUES ($1, $2, '72', 'G4020',
               public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3),4326)), $4, now())
       ON CONFLICT DO NOTHING`,
      [r.geo_id, `${r.name} Municipio`, r.gj,
       'Census TIGERweb State_County layer 1, loaded by scripts/load-pr-municipio-boundaries.mjs'],
    );
    n++;
  }
  const { rows: [chk] } = await pool.query(
    `SELECT count(*)::int AS n, count(*) FILTER (WHERE public.ST_IsValid(geometry))::int AS valid
       FROM essentials.geofence_boundaries WHERE state='72' AND mtfcc='G4020'`,
  );
  console.log(`\nwrote/attempted ${n}; in database now: ${chk.n} G4020 rows, ${chk.valid} valid`);
  console.log(chk.n === EXPECTED ? 'OK — all 78 municipio polygons present.' : '** count mismatch **');
} else {
  console.log('\nAll checks passed. verify-only — re-run with --write to load.');
}

await pool.end();
