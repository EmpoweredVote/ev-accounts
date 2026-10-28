#!/usr/bin/env node
/**
 * load-anchorage-assembly-districts.mjs — Anchorage full seed, stage 1 geography.
 *
 * Fetches the Municipality of Anchorage's six Assembly district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='anchorage-ak-assembly-1'..'-6', mtfcc='X0081'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structure migration creates the districts
 * and their offices and REFUSES TO RUN if these six boundaries are absent — an office on a
 * district with no polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * THE SOURCE IS THE MUNICIPALITY'S OWN GIS, WHICH IS ALSO THE BALLOT AUTHORITY HERE.
 *
 * Anchorage is a UNIFIED HOME RULE MUNICIPALITY: the borough and the city are one government,
 * and that government runs its own elections (the Municipal Clerk's office), so there is no
 * county layer above it to arbitrate between. MOAGIS — ArcGIS org Ce3DhLRthdwbHlfF — publishes
 * `AssemblyDistrict_Links`, described by the service itself as "Assembly Districts - April
 * 2022", the post-2020-census reapportionment the April 2026 election was run under.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THIS LAYER CARRIES AN INCUMBENT COLUMN. GEOMETRY IS TAKEN FROM IT; OCCUPANCY IS NOT.
 *
 * Each feature carries INCUMBENT1/INCUMBENT2 beside SEAT1/SEAT2. Measured 2026-10-27, all
 * twelve names agree with the Clerk's own contact list (rev. 04/29/2026) and with the Assembly
 * member profile pages — this layer is, today, fresh. It is still not read for occupancy, for
 * the Atlanta reason (`load-atlanta-council-districts.mjs`): freshness is a property of a field
 * at a moment, and Atlanta's equivalent column was correct on 9 of 12 while carrying two
 * different stale vintages. **Geometry from here. Occupancy from the Clerk's roster. Never
 * mixed.**
 *
 * 🟢 THE SEAT LETTERS *ARE* READ, AND THEY ARE GEOGRAPHY, NOT OCCUPANCY. SEAT1/SEAT2 say which
 * lettered seats a district elects (D1 → B and L, D2 → A and C, …). That mapping is a fact
 * about the district, it is what the structure migration titles its offices from, and GATE 6
 * asserts it against the Clerk's list rather than trusting either source alone.
 *
 *   node scripts/load-anchorage-assembly-districts.mjs --dry-run
 *   node scripts/load-anchorage-assembly-districts.mjs --control=count
 *   node scripts/load-anchorage-assembly-districts.mjs
 */
import pg from 'pg';
import fs from 'node:fs';
import * as dotenv from 'dotenv';
dotenv.config();

const EMIT = (process.argv.find((a) => a.startsWith('--emit-sql=')) || '').split('=').slice(1).join('=');
const lit = (s) => `'${String(s).replace(/'/g, "''")}'`;

const UA = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0',
  Accept: 'application/json,text/plain,*/*',
};

const LAYER =
  'https://services2.arcgis.com/Ce3DhLRthdwbHlfF/arcgis/rest/services/' +
  'AssemblyDistrict_Links/FeatureServer/0';

const MTFCC = 'X0081';
const EXPECTED = 6;
const PLACE_GEO_ID = '0203000'; // TIGER place, Anchorage municipality — already in production.
const PLACE_MTFCC = 'G4110';
const STATE_FIPS = '02';

// 🔴 THE SEAT MAP IS AN ASSERTION, NOT A READING. These twelve letters come from the Municipal
// Clerk's "Assembly Members - Public Contact List", revised 04/29/2026, read 2026-10-27 — a
// document with no GIS in it. GATE 6 fails if the layer disagrees, so the two sources have to
// agree before any geometry is written.
const CLERK_SEATS = {
  1: ['B', 'L'],
  2: ['A', 'C'],
  3: ['D', 'E'],
  4: ['F', 'G'],
  5: ['H', 'I'],
  6: ['J', 'K'],
};

// 🔴 PROBES ARE REAL ADDRESSES, GEOCODED BY THE CENSUS GEOCODER ON 2026-10-27, NOT TYPED IN.
// The expectation for each is the Municipality's own district description on the Assembly
// member-profile page: "District 2 | Chugiak, Eagle River, JBER" and "District 6 | South
// Anchorage, Girdwood, Turnagain Arm".
const PROBES = {
  // 632 W 6th Ave — Anchorage City Hall. Expectation: exactly one district, whichever it is.
  cityHall: [-149.894191, 61.216527],
  // 12001 Business Blvd, Eagle River — the page puts Eagle River in District 2.
  eagleRiver: [-149.571909, 61.329168],
  // 195 Olympic Cir, Girdwood — the page puts Girdwood in District 6. 55km down Turnagain Arm
  // from downtown, so this is the gate that proves the layer carries the whole municipality
  // and not just the urban bowl.
  girdwood: [-149.110917, 60.960787],
  // 290 E Herning Ave, Wasilla — Matanuska-Susitna Borough, OUTSIDE the municipality entirely.
  // Negative control: must fall in ZERO Anchorage assembly districts.
  wasilla: [-149.444003, 61.582214],
};
const EAGLE_RIVER_DISTRICT = 2;
const GIRDWOOD_DISTRICT = 6;

// ─────────────────────────────────────────────────────────────────────────────────────────
// 🔴🔴 THE ASSEMBLY DISTRICTS DO NOT TILE THE PLACE POLYGON, AND THAT IS CORRECT.
//
// The first version of GATE 4 asserted that the six districts cover 99% of TIGER place 0203000.
// It fired at 90.672% — and the GATE was wrong, not the data. Anchorage's place polygon includes
// the tidal water of Knik Arm and Turnagain Arm; the Municipality's districts are drawn over
// land. Measured 2026-10-27, three ways that agree:
//
//   place polygon, measured in production   5036.3 km²
//   Census 2020 PL, place 02/03000 ALAND    4420.6 km²   (87.78%)
//   Census 2020 PL, place 02/03000 AWATER    615.7 km²   (12.22%)
//   ALAND + AWATER                          5036.3 km²   ← reconciles to the polygon exactly
//   covered by the six districts            4566.5 km²   (90.672%)
//   uncovered                                469.8 km²
//
// So the districts cover 145.9 km² MORE than the municipality's entire land area. The uncovered
// 469.8 km² is one dominant piece in Turnagain Arm (469.2 km², point-on-surface 61.0554,
// -149.8865) plus two slivers of 0.3 and 0.2 km². The Census geocoder places NONE of the three
// in any census block, while a City Hall control resolves to block 1047 — so the uncovered
// ground is not addressable and no voter lives in it.
//
// ▶ A PERCENTAGE-OF-POLYGON GATE ASKS THE WRONG QUESTION. What matters is "could a real address
//   fall outside every district", so the gate now asserts (4a) that the districts cover at least
//   the Census land area, and (4b) that every uncovered piece over 1 km² fails to geocode, with
//   a land control in the same run so a blind geocoder cannot pass it silently.
//
// Census 2020 PL 94-171, table P1, state:02 place:03000. An authoritative constant, not a
// measurement of our own polygon.
const CENSUS_ALAND_M2 = 4_420_579_222;
const CENSUS_AWATER_M2 = 615_674_126;
// The biggest uncovered piece a load may carry without being looked at again. Set from the
// measurement above: the real figure is 469.8 km², so this leaves headroom for a redigitised
// shoreline and still fails long before a missing district (the smallest district is far larger).
const UNCOVERED_MAX_KM2 = 600.0;
// Any uncovered piece at least this large gets geocoded in GATE 4b.
const GAP_PROBE_MIN_KM2 = 1.0;

const SOURCE =
  'Municipality of Anchorage GIS (MOAGIS), ArcGIS org Ce3DhLRthdwbHlfF, feature service ' +
  'AssemblyDistrict_Links layer 0 "Assembly Districts", service description "Assembly ' +
  'Districts - April 2022", read 2026-10-27. Anchorage is a unified home rule municipality and ' +
  'runs its own elections, so its own GIS is the ballot authority — there is no county layer ' +
  'above it. The 2022 reapportionment is the one the April 2026 municipal election was run ' +
  'under. Seat letters (SEAT1/SEAT2) are taken from this layer and were cross-checked against ' +
  'the Municipal Clerk\'s Assembly Members Public Contact List rev. 04/29/2026 before loading. ' +
  '🔴 The layer\'s INCUMBENT1/INCUMBENT2 columns are NOT read — occupancy comes from the Clerk.';

const DRY = process.argv.includes('--dry-run');
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

// 🔴 A GATE NOBODY HAS WATCHED FAIL IS NOT A GATE. --control=<name> tampers so that exactly one
// gate must fire. Run every one of these after any edit to this file.
//   count     -> GATE 1  drop district 4
//   overlap   -> GATE 2  duplicate district 1's geometry onto district 3
//   coverage  -> GATE 4a shrink district 2 (the largest) to a sliver
//   gap       -> GATE 4b geocode City Hall in place of each gap piece, so the gap looks inhabited
//   probe     -> GATE 5  move the Girdwood district's geometry off Girdwood
//   seats     -> GATE 6  swap district 3's seat letters
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';

const districtOf = (p) => {
  const raw = String(p.ASSEMBLY_SECTION ?? p.assembly_section ?? '');
  const m = raw.match(/(\d+)/);
  return m ? Number(m[1]) : NaN;
};
const seatsOf = (p) => [p.SEAT1 ?? p.seat1, p.SEAT2 ?? p.seat2].filter(Boolean).map((s) => String(s).trim());

const getLayer = async () => {
  const url = `${LAYER}/query?where=1%3D1&outFields=*&returnGeometry=true&outSR=4326&f=geojson`;
  const r = await fetch(url, { headers: UA });
  const t = await r.text();
  // 🔴 A CLEAN HTTP 200 LIES IN FIVE WAYS. Parse before trusting the status.
  if (!t.trim().startsWith('{')) fail(`layer 0: not JSON (HTTP ${r.status}, ${t.length} bytes)`);
  const j = JSON.parse(t);
  if (j.error) fail(`layer 0: ArcGIS error ${JSON.stringify(j.error).slice(0, 180)}`);
  const feats = j.features ?? [];
  if (!feats.length) fail('layer 0: ZERO features — this load would be blind. Fix it before loading.');
  const bad = feats.filter((f) => !Number.isInteger(districtOf(f.properties)));
  if (bad.length) fail(`layer 0: ${bad.length} feature(s) carry no readable ASSEMBLY_SECTION — blind`);
  return feats;
};

const raw = await getLayer();
console.log(`layer 0 "Assembly Districts": ${raw.length} rows`);

// ── Dissolve rows to districts (one row per district today; dissolve anyway) ──
const byDistrict = new Map();
const seatsByDistrict = new Map();
for (const f of raw) {
  const n = districtOf(f.properties);
  if (!byDistrict.has(n)) byDistrict.set(n, []);
  byDistrict.get(n).push(f.geometry);
  if (!seatsByDistrict.has(n)) seatsByDistrict.set(n, seatsOf(f.properties));
}
let parts = [...byDistrict.entries()].map(([district, geoms]) => ({ district, geoms }));

if (CONTROL) {
  console.log(`\n⚠ CONTROL "${CONTROL}" ACTIVE — a gate MUST fail below, or the gate is worthless.\n`);
  if (CONTROL === 'count') parts = parts.filter((p) => p.district !== 4);
  if (CONTROL === 'seats') seatsByDistrict.set(3, ['Z', 'Y']);
  if (CONTROL === 'overlap') {
    const one = parts.find((p) => p.district === 1);
    parts.find((p) => p.district === 3).geoms = one.geoms;
  }
}

// ── GATE 1: six districts, numbered 1..6, after dissolve ─────────────────────
{
  const nums = parts.map((p) => p.district).sort((a, b) => a - b);
  if (parts.length !== EXPECTED || nums[0] !== 1 || nums[EXPECTED - 1] !== EXPECTED) {
    fail(`GATE 1: expected districts 1..${EXPECTED} after dissolve, got [${nums.join(',')}]`);
  }
  console.log(`  GATE 1 PASSED: ${raw.length} rows dissolved to districts ${nums.join(',')}`);
}

// ── GATE 6: the layer's seat letters agree with the Clerk's contact list ─────
// 🔴 Run BEFORE any geometry work: if the two sources disagree about which seats a district
// elects, nothing downstream is trustworthy, and the office titles would be wrong.
{
  const disagree = [];
  for (const n of Object.keys(CLERK_SEATS).map(Number)) {
    const want = [...CLERK_SEATS[n]].sort();
    const got = [...(seatsByDistrict.get(n) ?? [])].sort();
    if (want.join(',') !== got.join(',')) disagree.push(`D${n}: clerk [${want}] vs layer [${got}]`);
  }
  if (disagree.length) {
    fail(
      `GATE 6: the MOAGIS layer and the Municipal Clerk's contact list disagree about seat ` +
        `letters — ${disagree.join('; ')}. One of them has been reapportioned and the other has ` +
        `not. Re-read both before loading any geometry.`,
    );
  }
  console.log(
    '  GATE 6 PASSED: seat letters agree with the Clerk\'s list on all 6 districts — ' +
      Object.keys(CLERK_SEATS).map((n) => `D${n}:${CLERK_SEATS[n].join('+')}`).join(' '),
  );
}

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 2 });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const rowsJson = () =>
  JSON.stringify(
    parts.map((p) => ({
      district: p.district,
      geo_id: `anchorage-ak-assembly-${p.district}`,
      name: `Anchorage Assembly District ${p.district}`,
      geoms: p.geoms,
    })),
  );

const DISSOLVED = `
  SELECT r.district, r.geo_id, r.name,
         ST_Multi(ST_UnaryUnion(ST_Collect(
           ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g.value #>> '{}'), 4326))
         ))) AS geom
    FROM jsonb_to_recordset($1::jsonb) AS r(district int, geo_id text, name text, geoms jsonb)
    CROSS JOIN LATERAL jsonb_array_elements(r.geoms) AS g(value)
   GROUP BY r.district, r.geo_id, r.name`;

// ── GATE 2: no two districts overlap ─────────────────────────────────────────
{
  const [ov] = await q(
    `WITH d AS (${DISSOLVED})
     SELECT (SELECT count(*) FROM d a JOIN d b ON a.district < b.district
              WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 1000)::int AS pairs`,
    [rowsJson()],
  );
  if (ov.pairs > 0) {
    fail(`GATE 2: ${ov.pairs} pair(s) of assembly districts overlap by over 1000 m² — is this one map?`);
  }
  console.log('  GATE 2 PASSED: no two districts overlap');
}

// ── GATE 3: the place polygon these must tile is actually in production ──────
{
  const [place] = await q(
    `SELECT round((ST_Area(geometry::geography)/1e6)::numeric, 3) AS km2
       FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = $2`,
    [PLACE_GEO_ID, PLACE_MTFCC],
  );
  if (!place) fail(`GATE 3: TIGER place ${PLACE_GEO_ID}/${PLACE_MTFCC} is not in production`);
  console.log(`  GATE 3 PASSED: Anchorage place polygon present, ${place.km2} km²`);
}

// ── GATE 4a: the districts cover at least the municipality's LAND ────────────
let gapPieces = [];
{
  let json = rowsJson();
  if (CONTROL === 'coverage') {
    const o = JSON.parse(json);
    const two = o.find((r) => r.district === 2);
    two.geoms = [{ type: 'Polygon', coordinates: [[[-149.9, 61.21], [-149.9, 61.211], [-149.899, 61.211], [-149.899, 61.21], [-149.9, 61.21]]] }];
    json = JSON.stringify(o);
  }
  const [cov] = await q(
    `WITH d AS (${DISSOLVED}),
          u AS (SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM d),
          p AS (SELECT geometry AS geom FROM essentials.geofence_boundaries
                 WHERE geo_id = $2 AND mtfcc = $3)
     SELECT round(ST_Area(ST_Intersection(u.geom, p.geom)::geography)::numeric, 0) AS covered_m2,
            round(ST_Area(ST_Difference(p.geom, u.geom)::geography)::numeric, 0)   AS uncovered_m2,
            round((100 * ST_Area(ST_Intersection(u.geom, p.geom)::geography)
                       / NULLIF(ST_Area(p.geom::geography), 0))::numeric, 3)       AS pct_of_place
       FROM u, p`,
    [json, PLACE_GEO_ID, PLACE_MTFCC],
  );
  const coveredKm2 = Number(cov.covered_m2) / 1e6;
  const uncoveredKm2 = Number(cov.uncovered_m2) / 1e6;
  console.log(
    `  GATE 4a: districts cover ${coveredKm2.toFixed(1)} km² (${cov.pct_of_place}% of the place ` +
      `polygon); census land is ${(CENSUS_ALAND_M2 / 1e6).toFixed(1)} km², water ` +
      `${(CENSUS_AWATER_M2 / 1e6).toFixed(1)} km²; uncovered ${uncoveredKm2.toFixed(1)} km²`,
  );
  if (Number(cov.covered_m2) < CENSUS_ALAND_M2) {
    fail(
      `GATE 4a: the districts cover ${coveredKm2.toFixed(1)} km², LESS than Anchorage's census land ` +
        `area of ${(CENSUS_ALAND_M2 / 1e6).toFixed(1)} km². Some inhabited ground is outside every ` +
        `assembly district, and an address there would resolve to no assembly seat.`,
    );
  }
  if (uncoveredKm2 > UNCOVERED_MAX_KM2) {
    fail(
      `GATE 4a: ${uncoveredKm2.toFixed(1)} km² of the place polygon is outside every district, over ` +
        `the ${UNCOVERED_MAX_KM2} km² ceiling. The expected uncovered ground is tidal water ` +
        `(~469.8 km² measured 2026-10-27); this is more than that and needs looking at.`,
    );
  }
  gapPieces = await q(
    `WITH d AS (${DISSOLVED}),
          u AS (SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM d),
          p AS (SELECT geometry AS geom FROM essentials.geofence_boundaries
                 WHERE geo_id = $2 AND mtfcc = $3),
          parts AS (SELECT (ST_Dump(ST_Difference(p.geom, u.geom))).geom AS geom FROM p, u)
     SELECT round((ST_Area(geom::geography)/1e6)::numeric, 3) AS km2,
            round(ST_Y(ST_PointOnSurface(geom))::numeric, 6)  AS lat,
            round(ST_X(ST_PointOnSurface(geom))::numeric, 6)  AS lon
       FROM parts
      WHERE ST_Area(geom::geography) >= $4
      ORDER BY 1 DESC`,
    [json, PLACE_GEO_ID, PLACE_MTFCC, GAP_PROBE_MIN_KM2 * 1e6],
  );
  console.log('  GATE 4a PASSED');
}

// ── GATE 4b: nothing uncovered is addressable ────────────────────────────────
// 🔴 THE POSITIVE CONTROL RUNS IN THE SAME PASS. A geocoder that has started refusing every
// request answers "no census block" for water and for City Hall alike, and without the control
// that reads as a clean pass over unrepresented neighbourhoods.
{
  // 🔴 `layers=all`, NOT a numeric layer id. The first version of this gate passed `layers=10`
  // believing it to be the blocks layer; it returns NOTHING for every point in this vintage,
  // including City Hall. The control is the only reason that was caught rather than being read
  // as "the whole gap is water" — which is the answer it would have produced.
  const geocode = async (lon, lat) => {
    const url =
      'https://geocoding.geo.census.gov/geocoder/geographies/coordinates' +
      `?x=${lon}&y=${lat}&benchmark=Public_AR_Current&vintage=Current_Current&layers=all&format=json`;
    const r = await fetch(url, { headers: UA });
    const t = await r.text();
    if (!t.trim().startsWith('{')) return { ok: false, blocks: [] };
    const j = JSON.parse(t);
    const g = j?.result?.geographies ?? {};
    const blocks = g['2020 Census Blocks'] ?? g['Census Blocks'] ?? [];
    return { ok: true, blocks };
  };

  const control = await geocode(...PROBES.cityHall);
  if (!control.ok || control.blocks.length !== 1) {
    fail(
      `GATE 4b CONTROL: Anchorage City Hall resolved to ${control.blocks.length} census block(s) ` +
        `(reachable=${control.ok}). The geocoder is not answering, so "the gap is water" would be ` +
        `an untested claim. Fix this before loading.`,
    );
  }
  console.log(
    `  GATE 4b control PASSED: City Hall → census block ${control.blocks[0].GEOID ?? control.blocks[0].BASENAME}`,
  );

  const addressable = [];
  for (const g of gapPieces) {
    const lon = CONTROL === 'gap' ? PROBES.cityHall[0] : Number(g.lon);
    const lat = CONTROL === 'gap' ? PROBES.cityHall[1] : Number(g.lat);
    const res = await geocode(lon, lat);
    const land = res.blocks.filter((b) => Number(b.AREALAND ?? 0) > 0);
    console.log(
      `    gap ${String(g.km2).padStart(8)} km² at ${g.lat},${g.lon} → ` +
        `${res.blocks.length} block(s), ${land.length} with land`,
    );
    if (land.length) addressable.push(`${g.km2} km² at ${g.lat},${g.lon}`);
  }
  if (addressable.length) {
    fail(
      `GATE 4b: ${addressable.length} uncovered piece(s) sit on addressable land — ` +
        `${addressable.join('; ')}. That is not tidal water; those addresses would resolve to no ` +
        `assembly seat. Do not load until the layer covers them.`,
    );
  }
  console.log(`  GATE 4b PASSED: all ${gapPieces.length} uncovered piece(s) over ${GAP_PROBE_MIN_KM2} km² are unaddressable`);
}

// ── GATE 5: the address probes the product actually runs ─────────────────────
{
  let json = rowsJson();
  if (CONTROL === 'probe') {
    const o = JSON.parse(json);
    const six = o.find((r) => r.district === GIRDWOOD_DISTRICT);
    six.geoms = [{ type: 'Polygon', coordinates: [[[-149.9, 61.21], [-149.9, 61.212], [-149.898, 61.212], [-149.898, 61.21], [-149.9, 61.21]]] }];
    json = JSON.stringify(o);
  }
  const [p] = await q(
    `WITH d AS (${DISSOLVED})
     SELECT (SELECT count(*)            FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3),4326)))::int AS city_hall,
            (SELECT string_agg(district::text,',') FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3),4326))) AS city_hall_d,
            (SELECT string_agg(district::text,',') FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($4,$5),4326))) AS eagle_river_d,
            (SELECT string_agg(district::text,',') FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($6,$7),4326))) AS girdwood_d,
            (SELECT count(*)            FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($8,$9),4326)))::int AS wasilla`,
    [json, ...PROBES.cityHall, ...PROBES.eagleRiver, ...PROBES.girdwood, ...PROBES.wasilla],
  );
  if (p.city_hall !== 1) {
    fail(`GATE 5: Anchorage City Hall falls in ${p.city_hall} assembly district(s), expected exactly 1`);
  }
  if (String(p.eagle_river_d) !== String(EAGLE_RIVER_DISTRICT)) {
    fail(
      `GATE 5: an Eagle River address falls in district ${p.eagle_river_d}; the Municipality's own ` +
        `page says "District ${EAGLE_RIVER_DISTRICT} | Chugiak, Eagle River, JBER"`,
    );
  }
  if (String(p.girdwood_d) !== String(GIRDWOOD_DISTRICT)) {
    fail(
      `GATE 5: a Girdwood address falls in district ${p.girdwood_d}; the Municipality's own page ` +
        `says "District ${GIRDWOOD_DISTRICT} | South Anchorage, Girdwood, Turnagain Arm". ` +
        `If this is 0 the layer does not carry Turnagain Arm and the seed would leave Girdwood unrepresented.`,
    );
  }
  if (p.wasilla !== 0) {
    fail(
      `GATE 5: CONTROL FAILED — a Wasilla address (Matanuska-Susitna Borough, outside the ` +
        `municipality) falls in ${p.wasilla} Anchorage assembly district(s). The layer is not clipped ` +
        `to Anchorage and would hand Mat-Su voters an Anchorage ballot.`,
    );
  }
  console.log(
    `  GATE 5 PASSED: City Hall → D${p.city_hall_d}; Eagle River → D${p.eagle_river_d}; ` +
      `Girdwood → D${p.girdwood_d}; Wasilla → none`,
  );
}

const [existing] = await q(
  `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
  [MTFCC],
);
console.log(`\n  ${MTFCC} currently holds ${existing.n} row(s) in production`);
if (existing.n !== 0 && existing.n !== EXPECTED) {
  fail(`${MTFCC} already holds ${existing.n} row(s) that are not this load — somebody else took this code`);
}

if (EMIT) {
  const sql =
    `-- ${MTFCC} — Anchorage Assembly districts, ${EXPECTED} of them.\n` +
    `-- GENERATED by scripts/load-anchorage-assembly-districts.mjs on ${new Date().toISOString()}.\n` +
    `-- Every gate in that script passed before this file was written. Do not hand-edit.\n` +
    `WITH d AS (\n` +
    DISSOLVED.replace('$1::jsonb', `${lit(rowsJson())}::jsonb`) +
    `\n)\n` +
    `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)\n` +
    `SELECT d.geo_id, d.name, ${lit(STATE_FIPS)}, ${lit(MTFCC)}, d.geom, ${lit(SOURCE)}, now() FROM d\n` +
    `ON CONFLICT (geo_id, mtfcc) DO NOTHING;\n`;
  fs.writeFileSync(EMIT, sql);
  console.log(`  --emit-sql: wrote ${sql.length.toLocaleString('en-US')} bytes to ${EMIT}; nothing written to the database.`);
  await pool.end();
  process.exit(0);
}

if (DRY) {
  const preview = await q(
    `WITH d AS (${DISSOLVED})
     SELECT geo_id, name, ST_NumGeometries(geom) AS parts,
            round((ST_Area(geom::geography)/1e6)::numeric,3) AS km2
       FROM d ORDER BY district`,
    [rowsJson()],
  );
  console.table(preview);
  console.log('\n--dry-run: nothing written.');
  await pool.end();
  process.exit(0);
}

const [{ written }] = await q(
  `WITH d AS (${DISSOLVED}),
        ins AS (
    INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
    SELECT d.geo_id, d.name, $2, $3, d.geom, $4, now() FROM d
    ON CONFLICT (geo_id, mtfcc) DO NOTHING
    RETURNING 1)
   SELECT count(*)::int AS written FROM ins`,
  [rowsJson(), STATE_FIPS, MTFCC, SOURCE],
);
console.log(`  inserted ${written} boundary row(s) (idempotent: a re-run inserts 0)`);

const [after] = await q(
  `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
  [MTFCC],
);
if (after.n !== EXPECTED) fail(`POST: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED}`);
console.log(`  POST PASSED: ${MTFCC} holds ${after.n} rows`);
await pool.end();
