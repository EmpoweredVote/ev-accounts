#!/usr/bin/env node
/**
 * Load the nine City and County of Honolulu council district polygons.
 *
 *   essentials.geofence_boundaries  geo_id='honolulu-hi-council-district-1'..'-9', mtfcc='X0082'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0304 creates the districts, offices and
 * seatings, and REFUSES to run until these nine rows exist — an office on a district with no
 * polygon is unreachable by any address and nothing errors.
 *
 * ═══ SOURCE ═══
 *
 * HoLIS (Honolulu Land Information System) — the City and County of Honolulu's OWN GIS:
 *   https://services.arcgis.com/tNJpAOha4mODLkXz/arcgis/rest/services/City_Council_2023/FeatureServer/0
 *   serviceDescription: "CityCouncilDistrictBoundaries (HoLIS) - January 2023"
 *
 * These are the boundaries adopted by the 2021 Honolulu Council Reapportionment Commission, which
 * govern until the next reapportionment after the 2030 census.
 *
 * 🔴 TWO OTHER LAYERS PUBLISH THE SAME DISTRICTS AND ONE OF THEM IS WRONG. The Hawaii Office of
 *    Elections layer (services6.arcgis.com/2cZSk3EXXiOHcbOl, "Honolulu 2021 Council Districts with
 *    Northwestern Hawaiian Islands") labels district 4 as Roman numeral "IIII", which cascades:
 *    its district 5 is labelled "IV" and its district 6 is labelled "V". Its numeric DIST_NUM is
 *    correct throughout. Anyone keying on the Roman-numeral string would silently hand District V's
 *    ground to District IV and District VI's to District V, and District VI would appear not to
 *    exist. HoLIS carries no Roman numerals at all, which is one reason it is preferred here.
 *
 * ⚠ The state layer (geodata.hawaii.gov AdminBnd/11) is a third copy with correct numerals. It was
 *   returning HTTP 503 for every request — including its own service root, which is how that was
 *   established to be the host and not us — when this script was written.
 *
 * ⚠ HoLIS covers OAHU ONLY. The City and County of Honolulu legally includes the Northwestern
 *   Hawaiian Islands, which are uninhabited. No address is affected. GATE 4 measures the shortfall
 *   rather than asserting the districts tile the county, because they do not and should not.
 *
 * ═══ USAGE ═══
 *
 *   node scripts/load-honolulu-council-districts.mjs --dry-run     # gates + preview, no write
 *   node scripts/load-honolulu-council-districts.mjs --emit-sql=f  # gates, write SQL to a file
 *   node scripts/load-honolulu-council-districts.mjs               # gates, then write
 */
import fs from 'node:fs';
import pg from 'pg';

const ARGV = process.argv.slice(2);
const DRY = ARGV.includes('--dry-run');
const EMIT = (ARGV.find((a) => a.startsWith('--emit-sql=')) || '').split('=')[1] || null;

const MTFCC = 'X0082';
const STATE_FIPS = '15';
const EXPECTED = 9;
const COUNTY_GEOID = '15003';
const COUNTY_MTFCC = 'G4020';
const LAYER =
  'https://services.arcgis.com/tNJpAOha4mODLkXz/arcgis/rest/services/City_Council_2023/FeatureServer/0';
const SOURCE =
  'HoLIS (City and County of Honolulu GIS), City_Council_2023/FeatureServer/0 — boundaries adopted ' +
  'by the 2021 Honolulu Council Reapportionment Commission. Retrieved 2026-10-28 by ' +
  'scripts/load-honolulu-council-districts.mjs (CC_0304).';

/**
 * The council member HoLIS names for each district, as read from the layer on 2026-10-28, checked
 * against the council's own nine per-member pages (honolulucitycouncil.org). GATE 6 re-reads the
 * layer and fails if it has moved: a changed name means a seat turned over, and this script must
 * not quietly load a new map under an old roster, nor an old map under a new one.
 *
 * 🔴 This is a DETECTOR, not the occupancy source. Occupancy is CC_0304's, from certified results.
 */
const HOLIS_MEMBERS = {
  1: 'Andria Tupola',
  2: 'Matt Weyer',
  3: 'Esther Kia‘āina',
  4: 'Tommy Waters',
  5: 'Scott Nishimoto',
  6: 'Tyler Dos Santos-Tam',
  7: 'Radiant Cordero',
  8: 'Val Aquino Okimoto',
  9: 'Augie Tulba',
};

/**
 * Point tests, taken from the `Neighborhoods` field HoLIS publishes for each district, so the
 * expectation comes from the city's own description of its own districts rather than from me.
 * The last entry is the negative control and is NOT on Oahu.
 */
const PROBES = [
  { name: 'Honolulu Hale (city hall)', lon: -157.85785, lat: 21.30737, expect: 6 },
  { name: 'Kapolei', lon: -158.05811, lat: 21.33562, expect: 1 },
  { name: 'Kane‘ohe', lon: -157.79891, lat: 21.40216, expect: 3 },
  { name: 'Hawai‘i Kai Towne Center', lon: -157.71660, lat: 21.29560, expect: 4 },
  { name: 'Waipahū', lon: -158.00921, lat: 21.38667, expect: 9 },
  { name: 'Mililani', lon: -158.01440, lat: 21.45080, expect: 8 },
  { name: 'Hilo (Hawai‘i island)', lon: -155.08978, lat: 19.72991, expect: null },
];

const fail = (msg) => {
  console.error(`\n❌ ${msg}\n`);
  process.exit(1);
};
const lit = (s) => `'${String(s).replace(/'/g, "''")}'`;

// ── Fetch ────────────────────────────────────────────────────────────────────
const url =
  `${LAYER}/query?where=1%3D1&outFields=district_number,cmember_name` +
  `&returnGeometry=true&outSR=4326&f=geojson`;
console.log(`Reading ${LAYER}`);
const res = await fetch(url, {
  headers: {
    'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
      'Chrome/131.0.0.0 Safari/537.36',
  },
});
if (!res.ok) fail(`HoLIS returned HTTP ${res.status}`);
const fc = await res.json();
if (fc.type !== 'FeatureCollection') {
  fail(`HoLIS did not return GeoJSON — got ${JSON.stringify(fc).slice(0, 200)}`);
}

// ── GATE 1: nine districts, numbered 1..9, each with geometry ────────────────
const byNum = new Map();
for (const f of fc.features || []) {
  const n = f.properties?.district_number;
  if (!Number.isInteger(n)) fail(`GATE 1: a feature has a non-integer district_number: ${n}`);
  if (byNum.has(n)) fail(`GATE 1: district ${n} appears twice in the layer`);
  if (!f.geometry) fail(`GATE 1: district ${n} has no geometry`);
  byNum.set(n, f);
}
if (byNum.size !== EXPECTED) fail(`GATE 1: expected ${EXPECTED} districts, got ${byNum.size}`);
for (let n = 1; n <= EXPECTED; n += 1) {
  if (!byNum.has(n)) fail(`GATE 1: district ${n} is missing from the layer`);
}
console.log(`  GATE 1 PASSED: ${EXPECTED} districts, numbered 1..9, all with geometry`);

// ── GATE 6: the roster the layer carries still matches the one CC_0304 seats ─
// Run BEFORE any geometry work, like Anchorage's: if the map has moved under the roster, stop.
{
  const drift = [];
  for (let n = 1; n <= EXPECTED; n += 1) {
    const got = (byNum.get(n).properties.cmember_name || '').trim();
    if (got !== HOLIS_MEMBERS[n]) drift.push(`D${n}: layer says ${got || '(blank)'}, expected ${HOLIS_MEMBERS[n]}`);
  }
  if (drift.length) {
    fail(
      `GATE 6: HoLIS no longer names the councilmembers CC_0304 seats:\n    ${drift.join('\n    ')}\n` +
        `  A changed name means a seat turned over. Re-read the roster and the certified results\n` +
        `  before loading this map.`,
    );
  }
  console.log('  GATE 6 PASSED: all 9 HoLIS member names match the seated roster');
}

const parts = [...byNum.entries()]
  .sort((a, b) => a[0] - b[0])
  .map(([district, f]) => ({
    district,
    geoms:
      f.geometry.type === 'MultiPolygon'
        ? f.geometry.coordinates.map((c) => ({ type: 'Polygon', coordinates: c }))
        : [f.geometry],
  }));

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 2 });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const rowsJson = () =>
  JSON.stringify(
    parts.map((p) => ({
      district: p.district,
      geo_id: `honolulu-hi-council-district-${p.district}`,
      name: `Honolulu City Council District ${p.district}`,
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
    fail(`GATE 2: ${ov.pairs} pair(s) of council districts overlap by over 1000 m² — is this one map?`);
  }
  console.log('  GATE 2 PASSED: no two districts overlap');
}

// ── GATE 3: the county polygon the citywide offices hang on is in production ─
// 🔴 MATCHED ON (geo_id, mtfcc) AND state, NEVER on geo_id alone. Production holds a SECOND row
//    with geo_id '15003' — mtfcc G6350, state 42 — which is 16 km² of Pennsylvania. geo_id is not
//    a key here; the pair is.
{
  const [c] = await q(
    `SELECT count(*)::int AS n,
            round((max(ST_Area(geometry::geography))/1e6)::numeric, 1) AS km2
       FROM essentials.geofence_boundaries
      WHERE geo_id = $1 AND mtfcc = $2 AND state = $3`,
    [COUNTY_GEOID, COUNTY_MTFCC, STATE_FIPS],
  );
  if (c.n !== 1) {
    fail(
      `GATE 3: expected exactly 1 TIGER polygon ${COUNTY_GEOID}/${COUNTY_MTFCC} in state ${STATE_FIPS} ` +
        `for the Mayor and Prosecuting Attorney, found ${c.n}`,
    );
  }
  console.log(`  GATE 3 PASSED: county polygon ${COUNTY_GEOID}/${COUNTY_MTFCC} present, ${c.km2} km²`);
}

// ── GATE 4: the districts sit INSIDE the county, and the shortfall is water ──
// Deliberately NOT a tiling assertion. The county polygon includes open ocean and the
// Northwestern Hawaiian Islands; HoLIS is Oahu land only. Demanding 100% would fail on a correct
// map. What must hold is that nothing spills OUT of the county.
{
  const [cov] = await q(
    `WITH d AS (${DISSOLVED}),
          u AS (SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM d),
          p AS (SELECT geometry AS geom FROM essentials.geofence_boundaries
                 WHERE geo_id = $2 AND mtfcc = $3 AND state = $4)
     SELECT round((ST_Area(u.geom::geography)/1e6)::numeric, 1)                       AS districts_km2,
            round((ST_Area(p.geom::geography)/1e6)::numeric, 1)                       AS county_km2,
            round((ST_Area(ST_Difference(u.geom, p.geom)::geography)/1e6)::numeric, 3) AS outside_km2,
            round((100 * ST_Area(ST_Intersection(u.geom, p.geom)::geography)
                       / NULLIF(ST_Area(p.geom::geography), 0))::numeric, 2)          AS pct_of_county
       FROM u, p`,
    [rowsJson(), COUNTY_GEOID, COUNTY_MTFCC, STATE_FIPS],
  );
  if (Number(cov.outside_km2) > 5) {
    fail(
      `GATE 4: ${cov.outside_km2} km² of council district sits OUTSIDE Honolulu County — ` +
        `that is not this county's map`,
    );
  }
  console.log(
    `  GATE 4 PASSED: districts ${cov.districts_km2} km² inside a ${cov.county_km2} km² county ` +
      `(${cov.pct_of_county}% of it; the rest is ocean and the Northwestern Hawaiian Islands), ` +
      `${cov.outside_km2} km² outside`,
  );
}

// ── GATE 5: real points land in the district the city says they do ───────────
{
  const [hit] = await q(
    `WITH d AS (${DISSOLVED}),
          probe AS (SELECT * FROM jsonb_to_recordset($2::jsonb)
                      AS t(name text, lon double precision, lat double precision, expect int))
     SELECT jsonb_agg(jsonb_build_object(
              'name', probe.name, 'expect', probe.expect,
              'got', (SELECT jsonb_agg(d.district ORDER BY d.district) FROM d
                       WHERE ST_Contains(d.geom, ST_SetSRID(ST_MakePoint(probe.lon, probe.lat), 4326)))
            ) ORDER BY probe.name) AS rows
       FROM probe`,
    [rowsJson(), JSON.stringify(PROBES)],
  );
  const bad = [];
  for (const r of hit.rows) {
    const got = r.got === null ? null : r.got;
    if (r.expect === null) {
      if (got !== null) bad.push(`${r.name}: expected NO district, got ${JSON.stringify(got)}`);
    } else if (!Array.isArray(got) || got.length !== 1 || got[0] !== r.expect) {
      bad.push(`${r.name}: expected exactly D${r.expect}, got ${JSON.stringify(got)}`);
    }
  }
  if (bad.length) fail(`GATE 5:\n    ${bad.join('\n    ')}`);
  console.log(
    `  GATE 5 PASSED: ${hit.rows.map((r) => `${r.name}→${r.expect === null ? 'none' : `D${r.expect}`}`).join('; ')}`,
  );
}

// ── Nobody else is using this code ───────────────────────────────────────────
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
    `-- ${MTFCC} — Honolulu City Council districts, ${EXPECTED} of them.\n` +
    `-- GENERATED by scripts/load-honolulu-council-districts.mjs on ${new Date().toISOString()}.\n` +
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
            round((ST_Area(geom::geography)/1e6)::numeric, 3) AS km2
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
console.log(`\n✅ wrote ${written} polygon(s) as ${MTFCC}`);

const [final] = await q(
  `SELECT count(*)::int AS n FROM essentials.geofence_boundaries
    WHERE mtfcc = $1 AND geo_id LIKE 'honolulu-hi-council-district-%'`,
  [MTFCC],
);
if (final.n !== EXPECTED) fail(`post-check: expected ${EXPECTED} ${MTFCC} rows, found ${final.n}`);
console.log(`  post-check: ${final.n} ${MTFCC} rows present. CC_0304 can now run.`);
await pool.end();
