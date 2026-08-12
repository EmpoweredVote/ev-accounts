#!/usr/bin/env node
/**
 * Load Puerto Rico government boundaries into essentials.geofence_boundaries.
 *
 * Four layers, because PR's Legislative Assembly needs all of them:
 *   72       G4000  the territory        -> STATE_EXEC (the Governor), via the guard's catch-all
 *   72001-08 G5210  senatorial districts -> STATE_UPPER  (8 districts, TWO senators each)
 *   72001-40 G5220  representative dists -> STATE_LOWER  (40 districts, one each)
 *   72000    G5210  + G5220              -> the AT-LARGE seats, geometry = the whole territory
 *
 * 🔴 SLDU AND SLDL SHARE GEO_IDS. 72001 is simultaneously Senate District 1 and House District 1.
 * That is the documented `geo_id` collision this repo already carries for 13 states, and it is why
 * MTFCC_DISTRICT_TYPE_GUARD exists — G5210 resolves only to STATE_UPPER, G5220 only to STATE_LOWER.
 * Never join essentials.districts to a boundary on geo_id alone for PR.
 *
 * 🔴 72000 IS SYNTHESIZED. TIGER has no polygon for an at-large seat, but 12 of PR's 28 senators and
 * 13 of its 53 representatives are elected island-wide and genuinely represent every resident — so
 * leaving them geometry-less would hide a third of the legislature from the people they serve. TIGER
 * numbers PR districts from 001, so 000 is free, and the MTFCC keeps the two at-large rows apart.
 * Synthesized ids are sticky: if Census ever publishes an at-large PR geoid, migrate to it.
 *
 * 🔴 TIGER also returns 72ZZZ ("State Senate Districts not defined") in both legislative layers. It
 * is a water/unassigned artifact, NOT a district, and is excluded explicitly. Loading it would create
 * a district nobody lives in that still answers address queries.
 *
 *   node scripts/load-pr-boundaries.mjs           # verify only
 *   node scripts/load-pr-boundaries.mjs --write
 */
import 'dotenv/config';
import { Pool } from 'pg';

const WRITE = process.argv.includes('--write');
const TIGER = 'https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb';

async function arcgis(url, params) {
  const u = new URL(url);
  for (const [k, v] of Object.entries(params)) u.searchParams.set(k, v);
  const res = await fetch(u);
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${u}`);
  const j = await res.json();
  // ArcGIS reports failure as HTTP 200 with an {error} body.
  if (j.error) throw new Error(`ArcGIS error: ${JSON.stringify(j.error).slice(0, 200)}`);
  return j;
}

const territory = await arcgis(`${TIGER}/State_County/MapServer/0/query`, {
  where: "GEOID='72'", outFields: 'GEOID,NAME', returnGeometry: 'true', f: 'geojson',
});
if ((territory.features || []).length !== 1) throw new Error('expected exactly 1 PR territory feature');
const prGeom = JSON.stringify(territory.features[0].geometry);

async function sld(layer, mtfcc, label) {
  const j = await arcgis(`${TIGER}/Legislative/MapServer/${layer}/query`, {
    where: "GEOID LIKE '72%'", outFields: 'GEOID,BASENAME', returnGeometry: 'true', f: 'geojson',
  });
  const feats = (j.features || []).filter((f) => !/ZZZ$/.test(f.properties.GEOID));
  console.log(`${label}: ${feats.length} districts (ZZZ artifact excluded)`);
  return feats.map((f) => ({
    geo_id: f.properties.GEOID,
    name: `PR ${label} ${f.properties.BASENAME}`,
    mtfcc,
    gj: JSON.stringify(f.geometry),
  }));
}

const rows = [
  { geo_id: '72', name: 'Puerto Rico', mtfcc: 'G4000', gj: prGeom },
  ...(await sld(1, 'G5210', 'Senatorial District')),
  ...(await sld(2, 'G5220', 'Representative District')),
  { geo_id: '72000', name: 'PR Senate At-Large', mtfcc: 'G5210', gj: prGeom },
  { geo_id: '72000', name: 'PR House At-Large', mtfcc: 'G5220', gj: prGeom },
];

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// San Juan must land in exactly one senatorial and one representative district. A polygon set that
// is valid but misaligned passes every structural check and still returns nobody a representative.
const SAN_JUAN = [-66.1057, 18.4655];
let bad = 0;

for (const r of rows) {
  const { rows: [c] } = await pool.query(
    `WITH g AS (SELECT public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326)) AS geom)
     SELECT public.ST_IsValid(geom) AS valid, public.ST_IsEmpty(geom) AS empty,
            public.ST_Covers(geom, public.ST_SetSRID(public.ST_MakePoint($2,$3),4326)) AS has_sj
       FROM g`,
    [r.gj, SAN_JUAN[0], SAN_JUAN[1]],
  );
  r.has_sj = c.has_sj;
  if (!c.valid || c.empty) { console.error(`  INVALID/EMPTY: ${r.geo_id} ${r.mtfcc} ${r.name}`); bad++; }
}

const sjUpper = rows.filter((r) => r.mtfcc === 'G5210' && r.geo_id !== '72000' && r.has_sj);
const sjLower = rows.filter((r) => r.mtfcc === 'G5220' && r.geo_id !== '72000' && r.has_sj);
console.log(`San Juan falls in ${sjUpper.length} senatorial district(s): ${sjUpper.map((r) => r.geo_id).join(',') || 'NONE'}`);
console.log(`San Juan falls in ${sjLower.length} representative district(s): ${sjLower.map((r) => r.geo_id).join(',') || 'NONE'}`);
if (sjUpper.length !== 1 || sjLower.length !== 1) {
  console.error('FAIL: San Juan must resolve to exactly one district per chamber.');
  bad++;
}

if (bad) { await pool.end(); process.exit(1); }

if (WRITE) {
  for (const r of rows) {
    await pool.query(
      // Explicit casts: geo_id/mtfcc are varchar, and using the same parameter in both the SELECT
      // list and the NOT EXISTS leaves Postgres unable to deduce one type ("text versus character
      // varying").
      `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
       SELECT $1::varchar, $2::text, '72', $3::varchar,
              public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($4::text),4326)),
              $5::text, now()
        WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                           WHERE b.geo_id = $1::varchar AND b.mtfcc = $3::varchar)`,
      [r.geo_id, r.name, r.mtfcc, r.gj,
       'Census TIGERweb, loaded by scripts/load-pr-boundaries.mjs'],
    );
  }
  const { rows: got } = await pool.query(
    `SELECT mtfcc, count(*)::int n FROM essentials.geofence_boundaries
      WHERE state = '72' GROUP BY mtfcc ORDER BY mtfcc`,
  );
  console.log('\nloaded:', got.map((g) => `${g.mtfcc}=${g.n}`).join(' '));
} else {
  console.log(`\nverify-only: ${rows.length} boundaries ready. Re-run with --write.`);
}

await pool.end();
