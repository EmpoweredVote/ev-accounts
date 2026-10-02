#!/usr/bin/env node
/**
 * load-aberdeen-council-boundaries.mjs — Knight program, wave SD-3.
 *
 * Builds Aberdeen's four City Council district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='aberdeen-sd-council-district-northwest' (and -northeast,
 *                                   -southeast, -southwest), mtfcc='X0072'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structure migration creates the districts and
 * their offices and REFUSES TO RUN if these four boundaries are absent — an office on a district
 * with no polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THE DISTRICTS ARE NAMED, NOT NUMBERED. Northwest, Northeast, Southeast, Southwest. Nothing
 * here may be cast to an integer or sorted as one, and the geo_id carries the word.
 *
 * 🔴 THE COUNCIL IS MULTI-MEMBER: FOUR POLYGONS CARRY EIGHT SEATS. Aberdeen Home Rule Charter
 * § 2.02(a) — "a city council composed of the mayor and eight members" — over § 6.03(a)'s "four (4)
 * city council districts", so each district elects TWO. The polygon count is not the seat count,
 * exactly as with the South Dakota House in the same slice.
 * ⚠ THE MAYOR NEEDS NO POLYGON. Aberdeen's mayor is elected citywide, so the structure migration
 * hangs that office on the TIGER place boundary 4600100 / G4110 already in production — the pattern
 * every other LOCAL_EXEC mayor in this database uses.
 *
 * ── WHERE THE GEOMETRY COMES FROM, AND WHY THIS SOURCE ───────────────────────────────────────
 * `aberdeengis.com` offers the districts two ways: a PDF, and an ArcGIS Experience app. The PDF is
 * the Gary dead end and is NOT the route. The app's layer was found by rendering it and reading its
 * network traffic, then confirmed through an AGOL item search.
 *
 * ⚠ THE AGOL ITEM IS TITLED "New Final Districts", WHICH READS LIKE A DRAFT. THE SERVICE IS NOT.
 * The layer's own name is "City Council Districts (2021 Finalized)", which is what the districting
 * commission of charter § 6.03 produced. Judge the service, not the item title.
 *
 * ⚠ THE SERVICE PUBLISHES IN EPSG:4269 (NAD83). This loader requests outSR=4326 explicitly rather
 * than relying on a default, and asserts the returned CRS.
 *
 * ── THE GATE IS A POPULATION IDENTITY, AND IT USES A NUMBER FROM OUTSIDE THE LAYER ────────────
 * Each feature carries its own 2020 population. Measured 2026-09-28:
 *   Northwest 6,981 · Northeast 7,220 · Southeast 7,146 · Southwest 7,148  =  28,495
 * which is Aberdeen city's population. That total came from somewhere else entirely, so a layer
 * that had been redrawn, truncated or swapped for a draft would have to reproduce it by accident.
 *
 * 🔴 THE EXTRA RINGS ARE HOLES, NOT PARTS, AND GETTING THAT BACKWARDS WOULD SILENTLY PUNCH THE
 * DISTRICTS. Northwest returns FIVE rings, Northeast three, Southwest two. In GeoJSON that means
 * one exterior and N holes — but ArcGIS also emits multi-part shapes as multiple rings, and reading
 * a part as a hole would cut real territory out of a district with nothing erroring. Measured: in
 * every feature, ring 0 is CLOCKWISE with a large area (the ESRI exterior convention) and every
 * later ring is COUNTER-CLOCKWISE, tiny, and has its first vertex INSIDE ring 0. They are genuine
 * interior holes — unincorporated in-holdings. The loader asserts that shape rather than assuming it.
 *
 * Controls, all of which must fire before any row is written:
 *   1. a bogus layer id must fail to return features;
 *   2. the four district names must be exactly the expected set;
 *   3. the populations must sum to 28,495;
 *   4. the ring orientation/containment test above;
 *   5. Aberdeen City Hall must fall in EXACTLY ONE district, and two out-of-city points in NONE.
 *
 * Usage:
 *   node scripts/load-aberdeen-council-boundaries.mjs --dry-run
 *   node scripts/load-aberdeen-council-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const DRY_RUN = process.argv.includes('--dry-run');
const LAYER =
  'https://services5.arcgis.com/H3Xuuu0h4PaTeWwU/arcgis/rest/services/New_Final_Districts/FeatureServer/1';
const MTFCC = 'X0072';
const SOURCE =
  'City of Aberdeen GIS, layer "City Council Districts (2021 Finalized)", ' +
  'services5.arcgis.com/H3Xuuu0h4PaTeWwU/.../New_Final_Districts/FeatureServer/1, ' +
  'reached from the ArcGIS Experience app linked by aberdeengis.com; read 2026-09-28 (SD-3)';

const EXPECTED = ['Northeast', 'Northwest', 'Southeast', 'Southwest'];
const EXPECTED_POP_TOTAL = 28495;
const PROBES = [
  { label: 'Aberdeen City Hall', lat: 45.4639, lon: -98.4865, want: 1 },
  { label: 'CONTROL: SD Capitol, Pierre', lat: 44.3662, lon: -100.3464, want: 0 },
  { label: 'CONTROL: 20km north of Aberdeen', lat: 45.65, lon: -98.4865, want: 0 },
];

const slug = (d) => `aberdeen-sd-council-district-${d.toLowerCase()}`;

async function fetchLayer(url) {
  const q = `${url}/query?where=1%3D1&outFields=District,Population&returnGeometry=true&outSR=4326&f=geojson`;
  const res = await fetch(q, { headers: { 'User-Agent': 'ev-accounts/sd-slice15' } });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${q}`);
  const j = await res.json();
  if (!j || j.type !== 'FeatureCollection' || !Array.isArray(j.features) || j.features.length === 0) {
    throw new Error(`no FeatureCollection returned from ${q}`);
  }
  const crs = j.crs?.properties?.name;
  if (crs && !/4326/.test(crs)) throw new Error(`expected EPSG:4326, got ${crs}`);
  return j;
}

// ── ring geometry helpers ────────────────────────────────────────────────────
const signedArea = (r) => {
  let s = 0;
  for (let i = 0, n = r.length; i < n; i++) {
    const [x1, y1] = r[i];
    const [x2, y2] = r[(i + 1) % n];
    s += x1 * y2 - x2 * y1;
  }
  return s / 2;
};
const ringHas = ([x, y], r) => {
  let inside = false;
  for (let i = 0, k = r.length - 1; i < r.length; k = i++) {
    const [xi, yi] = r[i];
    const [xj, yj] = r[k];
    if (yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
};
const polyHas = (p, rings) => {
  if (!ringHas(p, rings[0])) return false;
  for (let k = 1; k < rings.length; k++) if (ringHas(p, rings[k])) return false;
  return true;
};

async function run() {
  // ── CONTROL 1: a bogus layer must fail. ────────────────────────────────────
  let control = false;
  try {
    await fetchLayer(LAYER.replace(/\/1$/, '/999'));
  } catch {
    control = true;
    console.log('control 1 OK — bogus layer id returned no features');
  }
  if (!control) throw new Error('🔴 CONTROL 1 DID NOT FIRE — a bogus layer returned features. Nothing below proves anything.');

  const fc = await fetchLayer(LAYER);
  console.log(`fetched ${fc.features.length} features from ${LAYER}`);

  // ── CONTROL 2: the district name set. ──────────────────────────────────────
  const names = fc.features.map((f) => String(f.properties.District)).sort();
  if (names.join(',') !== EXPECTED.join(',')) {
    throw new Error(`🔴 district names ${JSON.stringify(names)}, expected ${JSON.stringify(EXPECTED)}`);
  }
  console.log(`control 2 OK — districts are exactly ${names.join(', ')}`);

  // ── CONTROL 3: the population identity. ────────────────────────────────────
  const pop = fc.features.reduce(
    (a, f) => a + parseInt(String(f.properties.Population).replace(/,/g, ''), 10),
    0,
  );
  if (pop !== EXPECTED_POP_TOTAL) {
    throw new Error(`🔴 populations sum to ${pop}, expected ${EXPECTED_POP_TOTAL} (Aberdeen city)`);
  }
  console.log(`control 3 OK — populations sum to ${pop.toLocaleString()}, which is Aberdeen's`);

  // ── CONTROL 4: rings are exterior + holes, not multiple parts. ─────────────
  for (const f of fc.features) {
    if (f.geometry.type !== 'Polygon') {
      throw new Error(`🔴 ${f.properties.District} is ${f.geometry.type}; ring test assumes Polygon`);
    }
    const rings = f.geometry.coordinates;
    if (signedArea(rings[0]) >= 0) {
      throw new Error(`🔴 ${f.properties.District} ring 0 is not clockwise — exterior/hole convention broken`);
    }
    for (let i = 1; i < rings.length; i++) {
      if (signedArea(rings[i]) <= 0) {
        throw new Error(`🔴 ${f.properties.District} ring ${i} is clockwise — it is a PART, not a hole, and would be punched out`);
      }
      if (!ringHas(rings[i][0], rings[0])) {
        throw new Error(`🔴 ${f.properties.District} ring ${i} lies OUTSIDE ring 0 — it is a separate part, not a hole`);
      }
    }
  }
  console.log('control 4 OK — every extra ring is CCW and inside ring 0, so they are holes');

  // ── CONTROL 5: the probes. ─────────────────────────────────────────────────
  for (const p of PROBES) {
    const hits = fc.features.filter((f) => polyHas([p.lon, p.lat], f.geometry.coordinates));
    if (hits.length !== p.want) {
      throw new Error(`🔴 ${p.label}: matched ${hits.length} district(s), expected ${p.want}`);
    }
    console.log(`control 5 OK — ${p.label}: ${hits.length ? hits[0].properties.District : 'no district'}`);
  }

  if (DRY_RUN) {
    console.log('\n[dry-run] all controls passed — would write:');
    for (const f of fc.features) {
      console.log(`  ${MTFCC}  ${slug(f.properties.District)}  "${f.properties.District} District"`);
    }
    console.log('[dry-run] no DB writes made.');
    return;
  }

  const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();
  try {
    await client.query('BEGIN');
    let inserted = 0;
    let existed = 0;
    for (const f of fc.features) {
      const d = String(f.properties.District);
      const r = await client.query(
        // 🔴 Every parameter is cast explicitly. Postgres deduces a parameter's type from its
        // first use, and $1/$3 appear both in the SELECT list and in the NOT EXISTS comparison —
        // without the casts it fails with "inconsistent types deduced for parameter $1".
        //
        // 🔴 ST_MakeValid IS APPLIED, AND THE REPAIR IS GATED RATHER THAN TRUSTED. The city's
        // NORTHWEST polygon arrives INVALID — "Ring Self-intersection" at
        // (-98.5069610644335, 45.4842403902356), a zero-area spike in the digitising. Measured
        // 2026-09-28: the repair keeps it a single Polygon, takes 316 points to 319, and changes
        // the area by 0.000000 m2 of 11,515,275.41 — an exact renoding, not a boundary edit.
        // The assertion below refuses any repair that moves more than 1 m2, so a MakeValid that
        // actually redrew a district would abort instead of passing silently.
        `WITH src AS (
           SELECT public.ST_SetSRID(public.ST_GeomFromGeoJSON($4::text), 4326) AS raw),
         fixed AS (
           SELECT raw, public.ST_MakeValid(raw) AS geom FROM src)
         INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source)
         SELECT $1::text, $2::text, '46', $3::text, f.geom, $5::text
         FROM fixed f
         WHERE NOT EXISTS (
           SELECT 1 FROM essentials.geofence_boundaries
            WHERE geo_id = $1::text AND mtfcc = $3::text)
           AND public.ST_GeometryType(f.geom) = 'ST_Polygon'
           AND abs(public.ST_Area(f.raw::geography) - public.ST_Area(f.geom::geography)) < 1.0
         RETURNING id`,
        [slug(d), `${d} District`, MTFCC, JSON.stringify(f.geometry), SOURCE],
      );
      if (r.rowCount) {
        inserted++;
        continue;
      }
      // 🔴 A ZERO ROWCOUNT HAS TWO CAUSES AND THEY ARE NOT THE SAME FACT. Either the row was
      // already there (idempotent re-run), or the MakeValid area guard rejected it. Counting both
      // as "already existed" would hide a repair that redrew a district. Ask which.
      const { rows: chk } = await client.query(
        `SELECT count(*)::int AS n FROM essentials.geofence_boundaries
          WHERE geo_id = $1::text AND mtfcc = $2::text`,
        [slug(d), MTFCC],
      );
      if (chk[0].n > 0) existed++;
      else {
        throw new Error(
          `🔴 ${d}: not inserted and not present — ST_MakeValid changed the area by more than 1 m2, ` +
          `or returned something other than a single Polygon. The repair is NOT a renoding here; refusing to write.`,
        );
      }
    }
    const { rows } = await client.query(
      `SELECT count(*) AS n,
              count(*) FILTER (WHERE public.ST_IsValid(geometry)) AS valid,
              count(DISTINCT public.ST_SRID(geometry)) AS srids
         FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
      [MTFCC],
    );
    const g = rows[0];
    if (Number(g.n) !== 4 || Number(g.valid) !== 4 || Number(g.srids) !== 1) {
      throw new Error(`🔴 post-write gate: ${g.n} rows, ${g.valid} valid, ${g.srids} distinct SRIDs — expected 4/4/1`);
    }
    await client.query('COMMIT');
    console.log(`\n✅ inserted ${inserted}, already existed ${existed}; ${MTFCC} now holds 4 valid polygons in one SRID.`);
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    await client.end();
  }
}

run().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
