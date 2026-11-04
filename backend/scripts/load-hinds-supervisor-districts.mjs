#!/usr/bin/env node
/**
 * load-hinds-supervisor-districts.mjs — Hinds County, Mississippi deep seed.
 *
 * Inserts Hinds County's five Board of Supervisors districts into
 *
 *   essentials.geofence_boundaries  mtfcc='G4040', geo_id='2804990225' … '2804993177'
 *
 * Writes ONLY to essentials.geofence_boundaries.
 *
 * ── 🟢🟢 THESE ARE TIGER COUNTY SUBDIVISIONS, NOT A HAND-DIGITISED LAYER ──────────────────────
 * In Mississippi the county subdivisions ARE the supervisor districts (the old "beats"). Measured
 * across the whole state: all 82 counties have exactly five G4040 subdivisions, named "District 1"
 * … "District 5". That is Miss. Const. art. 6 s 170, which fixes five supervisor districts per
 * county — so the uniform answer here is the law, not a parser default, and the distribution is
 * printed rather than asserted.
 *
 * ▶ SO THIS NEEDS NO `X` CODE. The geo_ids are the Census Bureau's own COUSUB GEOIDs.
 *
 * ⚠ HARRISON COUNTY (MS-4) HAND-LOADED ITS FIVE SUPERVISOR DISTRICTS ONTO X0074 from the county's
 * own ArcGIS service. That was before anyone noticed TIGER already carried them. Harrison's rows
 * are correct and anchored and are NOT being changed here — but the two counties now hold the same
 * kind of thing two different ways, and that is written down in the slice record as a debt rather
 * than quietly normalised.
 *
 * ── 🔴 THE NUMBERING IS PROVED, NOT READ OFF THE ATTRIBUTE ────────────────────────────────────
 * Harrison's own layer carried a `DIST_ID` that was a CLEAN PERMUTATION of exactly the right five
 * values and looked perfect. So before trusting TIGER's "District N" anywhere,
 * scripts/verify-ms-cousub-are-supervisor-districts.mjs overlaps TIGER's five HARRISON
 * subdivisions against the X0074 polygons already in production — a dataset MS-4 anchored against
 * 18 precincts from the certified 2023 results, the county's own 49 polling places and the
 * certified winners. Result: diagonal strongest 5/5; with the labels rotated, 0/5.
 * ▶ The method is validated on a county we anchored the hard way, then applied to Hinds.
 *
 * Controls, all of which must fire before any row is written:
 *   1. the shapefile must yield exactly 5 "District N" subdivisions for 28049, numbered 1..5;
 *   2. the population identity — the five must sum to Hinds County's 2020 POP100, fetched live
 *      from TIGERweb rather than hard-coded;
 *   3. the coordinate range, because a polygon can be valid, correctly shaped and in the wrong CRS;
 *   4. the five must tile the county: their union must match the county polygon already in
 *      production, within tolerance;
 *   5. out-of-county probes return nothing, and each district's interior point returns only itself.
 *
 *   node scripts/load-hinds-supervisor-districts.mjs --shp <tl_2024_28_cousub.shp> --dry-run
 *   node scripts/load-hinds-supervisor-districts.mjs --shp <...> --control=<n>
 */
import * as shapefile from 'shapefile';
import pg from 'pg';

const argv = process.argv.slice(2);
const arg = (k) => {
  const hit = argv.find((a) => a.startsWith(`--${k}=`));
  if (hit) return hit.slice(k.length + 3);
  const i = argv.indexOf(`--${k}`);
  return i >= 0 ? argv[i + 1] : undefined;
};
const SHP = arg('shp');
const DRY_RUN = argv.includes('--dry-run');
const CONTROL = arg('control') || '';
if (!SHP) {
  console.error('usage: --shp <tl_2024_28_cousub.shp> [--dry-run] [--control=<n>]');
  process.exit(2);
}

const MTFCC = 'G4040';
const STATE_FIPS = '28';
const COUNTY = '049';
const SOURCE = 'US Census Bureau TIGER/Line 2024, county subdivisions (COUSUB) for Mississippi — in Mississippi the county subdivisions are the Board of Supervisors districts; loaded 2026-10-31';
const TIGERWEB_COUNTIES =
  'https://tigerweb.geo.census.gov/arcgis/rest/services/Census2020/State_County/MapServer/1';

/** Points that must NOT fall in any Hinds supervisor district. */
const PROBES = [
  { label: 'CONTROL: Gulfport City Hall (Harrison)', lon: -89.080122, lat: 30.378061 },
  { label: 'CONTROL: Mobile, Alabama', lon: -88.0399, lat: 30.6954 },
  { label: 'CONTROL: Vicksburg, Warren County MS', lon: -90.8779, lat: 32.3526 },
];

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0.0.0 Safari/537.36';
async function getJson(url) {
  const r = await fetch(url, { headers: { 'User-Agent': UA } });
  const t = await r.text();
  try { return JSON.parse(t); } catch { throw new Error(`not JSON from ${url} (HTTP ${r.status}): ${t.slice(0, 120)}`); }
}

const ringsOf = (g) => (g.type === 'Polygon' ? g.coordinates : g.type === 'MultiPolygon' ? g.coordinates.flat() : (() => { throw new Error(g.type); })());
function pointInRings(x, y, rings) {
  let inside = false;
  for (const ring of rings) {
    for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      const xi = ring[i][0], yi = ring[i][1], xj = ring[j][0], yj = ring[j][1];
      if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
    }
  }
  return inside;
}

// ── read the shapefile ────────────────────────────────────────────────────────
const src = await shapefile.open(SHP.replace(/\.shp$/, '.shp'), SHP.replace(/\.shp$/, '.dbf'));
const perCounty = new Map();
const hinds = [];
let total = 0;
for (;;) {
  const { done, value } = await src.read();
  if (done) break;
  total++;
  const p = value.properties;
  if (p.STATEFP !== STATE_FIPS) continue;
  const m = String(p.NAMELSAD || '').match(/^District (\d+)$/);
  if (!m) continue;
  perCounty.set(p.COUNTYFP, (perCounty.get(p.COUNTYFP) || 0) + 1);
  if (p.COUNTYFP === COUNTY) hinds.push({ n: Number(m[1]), geoid: p.GEOID, pop: null, geom: value.geometry, aland: Number(p.ALAND) });
}
const dist = {};
for (const [, c] of perCounty) dist[c] = (dist[c] || 0) + 1;
console.log(`shapefile records: ${total}; MS counties by subdivision count: ${JSON.stringify(dist)}`);
console.log('(five per county is Miss. Const. art. 6 s 170, not a parser default)');

if (CONTROL === '1') hinds.pop();
if (CONTROL === '3') for (const h of hinds) { const w = (c) => (typeof c[0] === 'number' ? ((c[0] *= 100000), (c[1] *= 100000)) : c.forEach(w)); w(h.geom.coordinates); }
if (CONTROL === '5') for (const h of hinds) { const w = (c) => (typeof c[0] === 'number' ? ((c[0] -= 0.75)) : c.forEach(w)); w(h.geom.coordinates); }

// ── CONTROL 1 ────────────────────────────────────────────────────────────────
hinds.sort((a, b) => a.n - b.n);
if (hinds.length !== 5 || hinds.map((h) => h.n).join(',') !== '1,2,3,4,5') {
  console.error(`🔴 CONTROL 1: Hinds has ${hinds.length} "District N" subdivisions numbered ${hinds.map((h) => h.n).join(',')}, expected 1..5`);
  process.exit(1);
}
console.log(`CONTROL 1 ✅ 5 Hinds subdivisions numbered 1..5: ${hinds.map((h) => h.geoid).join(', ')}`);

// ── CONTROL 2: the population identity, measured against the county ──────────
const tw = await getJson(
  `${TIGERWEB_COUNTIES}/query?where=STATE%3D%2728%27+AND+COUNTY%3D%27049%27&outFields=BASENAME,POP100&returnGeometry=false&f=json`,
);
const countyPop = Number(tw.features && tw.features[0] && tw.features[0].attributes.POP100);
const subs = await getJson(
  `https://tigerweb.geo.census.gov/arcgis/rest/services/Census2020/Places_CouSub_ConCity_SubMCD/MapServer/1/query?where=STATE%3D%2728%27+AND+COUNTY%3D%27049%27&outFields=GEOID,POP100&returnGeometry=false&f=json`,
);
const popByGeoid = new Map((subs.features || []).map((f) => [f.attributes.GEOID, Number(f.attributes.POP100)]));
hinds.forEach((h) => { h.pop = popByGeoid.get(h.geoid); });
const sum = hinds.reduce((s, h) => s + (h.pop || 0), 0);
if (!Number.isFinite(countyPop) || countyPop <= 0) {
  console.error('🔴 CONTROL 2: TIGERweb gave no county population — a connection failure is not an absence');
  process.exit(1);
}
if (CONTROL === '2') hinds[0].pop += 1;
const sum2 = hinds.reduce((s, h) => s + (h.pop || 0), 0);
if (sum2 !== countyPop) {
  console.error(`🔴 CONTROL 2: the five districts sum to ${sum2.toLocaleString()} but Hinds County's 2020 POP100 is ${countyPop.toLocaleString()}`);
  process.exit(1);
}
console.log(`CONTROL 2 ✅ districts sum to ${sum.toLocaleString()} = Hinds County 2020 POP100`);

// ── CONTROL 3: coordinate range ──────────────────────────────────────────────
const coords = [];
for (const h of hinds) { const w = (c) => (typeof c[0] === 'number' ? coords.push(c) : c.forEach(w)); w(h.geom.coordinates); }
const lons = coords.map((c) => c[0]), lats = coords.map((c) => c[1]);
const lo = Math.min(...lons), hi = Math.max(...lons), la = Math.min(...lats), lb = Math.max(...lats);
if (lo < -180 || hi > 180 || la < -90 || lb > 90) {
  console.error(`🔴 CONTROL 3: coordinates out of degree range (lon ${lo}..${hi}, lat ${la}..${lb}) — projected, not WGS84`);
  process.exit(1);
}
if (lo < -91.5 || hi > -89.5 || la < 31.8 || lb > 32.8) {
  console.error(`🔴 CONTROL 3: degrees, but not Hinds County (lon ${lo}..${hi}, lat ${la}..${lb})`);
  process.exit(1);
}
console.log(`CONTROL 3 ✅ lon ${lo.toFixed(4)}..${hi.toFixed(4)}, lat ${la.toFixed(4)}..${lb.toFixed(4)} — real degrees over Hinds County`);

// ── CONTROL 5a (in memory): the out-of-county probes ─────────────────────────
const polys = hinds.map((h) => ({ n: h.n, rings: ringsOf(h.geom) }));
const which = (lon, lat) => polys.filter((p) => pointInRings(lon, lat, p.rings)).map((p) => p.n);
for (const p of PROBES) {
  const got = which(p.lon, p.lat);
  if (got.length) { console.error(`🔴 CONTROL 5a: ${p.label} fell in district(s) ${JSON.stringify(got)}`); process.exit(1); }
}
console.log(`CONTROL 5a ✅ ${PROBES.length} out-of-county probes return no district`);

// 🔴 THE PER-DISTRICT IDENTITY CHECK MOVED INTO POSTGIS, AND THE REASON IS A CONTROL THAT FAILED
// A CLEAN RUN. It first used the mean of the largest ring's vertices as an "interior point". THE
// CENTROID OF A RING IS NOT GUARANTEED TO BE INSIDE IT: for Jackson's compact wards it happened to
// land inside every time, and for Hinds's large irregular District 5 it landed inside District 4 —
// reporting a defect in data that was correct. ST_PointOnSurface is guaranteed to be inside the
// polygon, so it is used instead, below, once the database is open.

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
try {
  // ── CONTROL 4: the five must tile the county polygon already in production ──
  const { rows: cty } = await client.query(
    `SELECT public.ST_Area(geometry::geography) AS a FROM essentials.geofence_boundaries
      WHERE mtfcc='G4020' AND geo_id='28049'`,
  );
  if (!cty.length) { console.error('🔴 CONTROL 4: Hinds County G4020 polygon not in production'); process.exit(1); }
  // 🔴 THE TAMPER IS APPLIED HERE, NOT AT PARSE TIME, SO IT CANNOT BE SHADOWED. Dropping a district
  // earlier would trip CONTROL 1 (the number set) and CONTROL 2 (the population identity) first,
  // and control 4 would never be reached — the shadowing failure this repo has met many times.
  const forUnion = CONTROL === '4' ? hinds.slice(0, -1) : hinds;
  if (CONTROL === '4') console.log('🔬 CONTROL 4 tamper: one district withheld from the union only');
  let union = null;
  for (const h of forUnion) {
    const r = await client.query(
      union
        ? `SELECT public.ST_AsGeoJSON(public.ST_Union(public.ST_MakeValid(public.ST_GeomFromGeoJSON($1)), public.ST_MakeValid(public.ST_GeomFromGeoJSON($2)))) AS g`
        : `SELECT public.ST_AsGeoJSON(public.ST_MakeValid(public.ST_GeomFromGeoJSON($1))) AS g`,
      union ? [union, JSON.stringify(h.geom)] : [JSON.stringify(h.geom)],
    );
    union = r.rows[0].g;
  }
  const { rows: ua } = await client.query('SELECT public.ST_Area(public.ST_GeomFromGeoJSON($1)::geography) AS a', [union]);
  const ratio = Number(ua[0].a) / Number(cty[0].a);
  console.log(`CONTROL 4 — union of the five / county polygon = ${(ratio * 100).toFixed(2)}%`);
  if (ratio < 0.98 || ratio > 1.02) {
    console.error(`🔴 CONTROL 4: the five districts do not tile Hinds County (${(ratio * 100).toFixed(2)}%)`);
    process.exit(1);
  }
  console.log('CONTROL 4 ✅ the five tile the county');

  // ── CONTROL 5b: per-district identity, using a point PostGIS guarantees is inside ──
  for (const h of hinds) {
    const { rows: pos } = await client.query(
      `SELECT public.ST_X(p) AS x, public.ST_Y(p) AS y
         FROM public.ST_PointOnSurface(public.ST_MakeValid(public.ST_GeomFromGeoJSON($1))) AS p`,
      [JSON.stringify(h.geom)],
    );
    const got = which(Number(pos[0].x), Number(pos[0].y));
    if (got.length !== 1 || got[0] !== h.n) {
      throw new Error(`🔴 CONTROL 5b: district ${h.n}'s surface point resolved to ${JSON.stringify(got)}`);
    }
  }
  console.log('CONTROL 5b ✅ all 5 ST_PointOnSurface points return only their own district');

  if (DRY_RUN) {
    console.log('\n[dry-run] all controls passed — would write:');
    for (const h of hinds) console.log(`  ${MTFCC}  ${h.geoid}  "Hinds County Supervisor District ${h.n}"  pop ${h.pop.toLocaleString()}`);
    console.log('[dry-run] no DB writes made.');
    process.exit(0);
  }

  const { rows: pre } = await client.query(
    `SELECT count(*)::int AS n FROM essentials.geofence_boundaries
      WHERE mtfcc=$1 AND geo_id LIKE '28049%'`, [MTFCC],
  );
  if (pre[0].n !== 0 && pre[0].n !== 5) {
    console.error(`🔴 pre-flight: ${pre[0].n} Hinds G4040 rows already present, expected 0 or 5`);
    process.exit(1);
  }

  await client.query('BEGIN');
  let inserted = 0, existed = 0;
  for (const h of hinds) {
    const r = await client.query(
      `WITH src AS (SELECT public.ST_SetSRID(public.ST_GeomFromGeoJSON($4::text), 4326) AS raw),
            fixed AS (SELECT raw, public.ST_MakeValid(raw) AS geom FROM src)
       INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source)
       SELECT $1::text, $2::text, $6::text, $3::text, f.geom, $5::text
       FROM fixed f
       WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id=$1::text AND mtfcc=$3::text)
         AND public.ST_GeometryType(f.geom) IN ('ST_Polygon','ST_MultiPolygon')
         AND abs(public.ST_Area(f.raw::geography) - public.ST_Area(f.geom::geography)) < 1.0
       RETURNING id`,
      [h.geoid, `Hinds County Supervisor District ${h.n}`, MTFCC, JSON.stringify(h.geom), SOURCE, STATE_FIPS],
    );
    if (r.rowCount) { inserted++; continue; }
    const { rows: chk } = await client.query(
      `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE geo_id=$1::text AND mtfcc=$2::text`,
      [h.geoid, MTFCC],
    );
    if (chk[0].n > 0) existed++;
    else throw new Error(`🔴 district ${h.n}: not inserted and not present — ST_MakeValid changed the area or returned a non-polygon`);
  }

  const { rows: g } = await client.query(
    `SELECT count(*)::int AS n, count(*) FILTER (WHERE public.ST_IsValid(geometry))::int AS valid,
            count(DISTINCT public.ST_SRID(geometry))::int AS srids
       FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND geo_id LIKE '28049%'`, [MTFCC],
  );
  if (g[0].n !== 5 || g[0].valid !== 5 || g[0].srids !== 1) {
    throw new Error(`🔴 post-write gate: ${g[0].n} rows, ${g[0].valid} valid, ${g[0].srids} SRIDs — expected 5/5/1`);
  }
  // 🔴 ST_PointOnSurface on the STORED geometry, not a ring centroid — see CONTROL 5b above.
  for (const h of hinds) {
    const { rows: hit } = await client.query(
      `WITH p AS (
         SELECT public.ST_PointOnSurface(geometry) AS g
           FROM essentials.geofence_boundaries WHERE mtfcc=$1 AND geo_id=$2)
       SELECT b.geo_id FROM essentials.geofence_boundaries b, p
        WHERE b.mtfcc=$1 AND b.geo_id LIKE '28049%'
          AND public.ST_Contains(b.geometry, p.g)`,
      [MTFCC, h.geoid],
    );
    if (hit.length !== 1 || hit[0].geo_id !== h.geoid) {
      throw new Error(`🔴 post-write: district ${h.n}'s surface point returned ${JSON.stringify(hit.map((x) => x.geo_id))}`);
    }
  }
  console.log('post-write OK — 5 surface points re-checked in PostGIS');
  await client.query('COMMIT');
  console.log(`\n✅ inserted ${inserted}, already existed ${existed}; Hinds now holds 5 valid G4040 polygons.`);
} catch (e) {
  await client.query('ROLLBACK').catch(() => {});
  console.error(e.message);
  process.exit(1);
} finally {
  await client.end();
}
