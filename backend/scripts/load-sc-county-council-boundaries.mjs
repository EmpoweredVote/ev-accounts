#!/usr/bin/env node
/**
 * load-sc-county-council-boundaries.mjs — Knight program, wave SC-4.
 *
 * Loads the council-district polygons for Richland (45079) and Horry (45051) into
 *
 *   essentials.geofence_boundaries  mtfcc='X0060'  geo_id='richland-sc-council-district-1'..'-11'
 *   essentials.geofence_boundaries  mtfcc='X0061'  geo_id='horry-sc-council-district-1'..'-11'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0129 creates the districts and their offices
 * and REFUSES TO RUN if these 22 boundaries are absent — an office on a district with no polygon is
 * unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🟢 THE SOURCE IS THE STATE'S OWN, AND UNLIKE COLUMBIA'S IT CARRIES A DATE.
 * `Boundaries_Districts/County_Council_Districts` on gis.state.sc.us is published by the SC
 * Revenue and Fiscal Affairs Office — the same server SC-1 used to prove the legislative vintage on
 * all 170 polygons, not a Census mirror. Every feature carries the COUNTY'S OWN ORDINANCE NUMBER
 * and its EFFECTIVE DATE:
 *
 *   Richland  ordinance 001.22HR  effective 2022-02-08   (the county's page: "On Feb. 8, 2022,
 *                                                         Richland County Council approved an
 *                                                         ordinance establishing new districts")
 *   Horry     ordinance 01-2022   effective 2022-02-15
 *
 * So SC-3's limitation does not recur here. GATE 2 asserts that every polygon in a county names
 * ONE ordinance and ONE effective date — a layer that has quietly mixed two adoptions fails there.
 *
 * 🔴 GATE 3 IS STATUTORY, NOT A HOUSE RULE. S.C. Code § 4-9-90: "The population variance between
 * defined election districts shall not exceed ten percent." The layer publishes Pop_2020 per
 * district, so a map that is not the adopted one usually fails this before it fails anything else.
 *
 * ⚠ GATE 5 IS A TILING GATE AND IT IS RIGHT FOR A COUNTY. Fort Wayne's six districts correctly
 * leave 1.13 sq mi of its city uncovered, so a coverage gate is a per-jurisdiction decision — but
 * county council districts are a partition of the county by construction, so anything under 99.5%
 * is a defect.
 *
 *   node scripts/load-sc-county-council-boundaries.mjs --dry-run
 *   node scripts/load-sc-county-council-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };
const SERVICE =
  'https://gis.state.sc.us/arcgis/rest/services/Boundaries_Districts/County_Council_Districts/FeatureServer/0';

const COUNTIES = [
  { fips: '45079', name: 'Richland', mtfcc: 'X0060', slug: 'richland-sc', ordinance: '001.22HR', effective: '2022-02-08' },
  { fips: '45051', name: 'Horry',    mtfcc: 'X0061', slug: 'horry-sc',    ordinance: '01-2022',  effective: '2022-02-15' },
];
const EXPECTED = 11;              // both councils are 11 single-member districts
const MAX_VARIANCE_PCT = 10;      // S.C. Code § 4-9-90
const MIN_COVERAGE_PCT = 99.5;

const DRY = process.argv.includes('--dry-run');

// 🔴 A GATE THAT HAS NEVER BEEN WATCHED FAILING IS NOT A GATE. --control=N plants the defect gate N
// exists to catch, in memory, and the run is expected to die with that gate's message. Kept in the
// tool so the controls are re-runnable rather than a one-off done by editing constants:
//   1 a district deleted · 2 one polygon re-stamped with a second ordinance ·
//   3 one district's population inflated past the § 4-9-90 variance · 4 a district duplicated onto
//   its neighbour's geometry · 5 the coverage gate pointed at the WRONG county's polygon.
const CONTROL = Number((process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || 0);
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

// ── fetch ────────────────────────────────────────────────────────────────────
const fetched = [];
for (const c of COUNTIES) {
  const url = `${SERVICE}/query?where=${encodeURIComponent(`FIPS='${c.fips}'`)}&outFields=*&outSR=4326&f=geojson`;
  const r = await fetch(url, { headers: UA });
  const t = await r.text();
  if (!t.trim().startsWith('{')) fail(`${c.name}: not JSON (HTTP ${r.status}) from County_Council_Districts`);
  const j = JSON.parse(t);
  if (j.error) fail(`${c.name}: ArcGIS error ${JSON.stringify(j.error).slice(0, 160)}`);
  fetched.push({ ...c, feats: j.features ?? [] });
  console.log(`${c.name} (${c.fips}): ${j.features?.length ?? 0} features`);
}

// ── plant the control defect, if one was asked for ───────────────────────────
if (CONTROL) {
  const c = fetched[0]; // Richland
  if (CONTROL === 1) c.feats.splice(3, 1);
  if (CONTROL === 2) c.feats[2].properties.Ordinance = '002.24HR';
  if (CONTROL === 3) c.feats[0].properties.Pop_2020 = 60000;
  if (CONTROL === 4) c.feats[5].geometry = c.feats[6].geometry;
  if (CONTROL === 5) c.fips = '45051'; // point the coverage gate at Horry's polygon
  console.log(`⚠ CONTROL ${CONTROL} PLANTED in ${c.name} — this run is EXPECTED to fail.`);
}

// ── GATE 1: the shape of each layer ──────────────────────────────────────────
for (const c of fetched) {
  if (c.feats.length !== EXPECTED) fail(`GATE 1 (${c.name}): expected ${EXPECTED} features, got ${c.feats.length}`);
  const nums = c.feats.map((f) => Number(String(f.properties.District).match(/\d+/)?.[0]));
  const sorted = [...nums].sort((a, b) => a - b);
  if (new Set(nums).size !== EXPECTED || sorted[0] !== 1 || sorted[EXPECTED - 1] !== EXPECTED) {
    fail(`GATE 1 (${c.name}): districts are not 1..${EXPECTED} exactly — got ${sorted.join(',')}`);
  }
  console.log(`  GATE 1 PASSED (${c.name}): districts ${sorted.join(',')}`);
}

// ── GATE 2: one ordinance and one effective date per county ──────────────────
// 🔴 This is the gate SC-3 could not have. A layer that has absorbed a second adoption without
// replacing the first shows up here as two ordinance strings, long before any geometry check.
for (const c of fetched) {
  const ords = new Set(c.feats.map((f) => String(f.properties.Ordinance ?? '').trim()));
  const effs = new Set(c.feats.map((f) => (f.properties.EffectiveDate ? new Date(f.properties.EffectiveDate).toISOString().slice(0, 10) : 'null')));
  if (ords.size !== 1) fail(`GATE 2 (${c.name}): ${ords.size} different ordinances in one layer — ${[...ords].join(' | ')}`);
  if (effs.size !== 1) fail(`GATE 2 (${c.name}): ${effs.size} different effective dates — ${[...effs].join(' | ')}`);
  const [ord] = [...ords];
  const [eff] = [...effs];
  if (ord !== c.ordinance || eff !== c.effective) {
    fail(`GATE 2 (${c.name}): the published plan has MOVED — expected ordinance ${c.ordinance} effective ${c.effective}, found ${ord} effective ${eff}. Re-read the county's redistricting record before loading.`);
  }
  console.log(`  GATE 2 PASSED (${c.name}): ordinance ${ord}, effective ${eff}, on all ${EXPECTED} polygons`);
}

// ── GATE 3: the statutory population variance ────────────────────────────────
for (const c of fetched) {
  const pops = c.feats.map((f) => Number(f.properties.Pop_2020));
  if (pops.some((p) => !Number.isFinite(p) || p <= 0)) fail(`GATE 3 (${c.name}): a district has no usable Pop_2020`);
  const mean = pops.reduce((a, b) => a + b, 0) / pops.length;
  const variance = ((Math.max(...pops) - Math.min(...pops)) / mean) * 100;
  if (variance > MAX_VARIANCE_PCT) {
    fail(`GATE 3 (${c.name}): population variance ${variance.toFixed(2)}% exceeds the § 4-9-90 limit of ${MAX_VARIANCE_PCT}% — this is not an adopted plan`);
  }
  console.log(`  GATE 3 PASSED (${c.name}): total ${mean * pops.length}, variance ${variance.toFixed(2)}% (§ 4-9-90 allows ${MAX_VARIANCE_PCT}%)`);
}

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const byCounty = fetched.map((c) => ({
  ...c,
  rows: c.feats.map((f) => {
    const n = Number(String(f.properties.District).match(/\d+/)[0]);
    return {
      geo_id: `${c.slug}-council-district-${n}`,
      name: `${c.name} County Council District ${n}`,
      geom: JSON.stringify(f.geometry),
    };
  }),
}));

for (const c of byCounty) {
  // ── GATE 4: the districts of one county do not overlap each other ──────────
  const [ov] = await q(
    `WITH d AS (SELECT r.geo_id,
                       ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)               AS raw,
                       ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS geom
                  FROM jsonb_to_recordset($1::jsonb) AS r(geo_id text, name text, geom text))
     SELECT (SELECT count(*) FROM d a JOIN d b ON a.geo_id < b.geo_id
              WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 1000)::int AS pairs,
            (SELECT count(*) FROM d WHERE NOT ST_IsValid(raw))::int                  AS invalid_as_published`,
    [JSON.stringify(c.rows)],
  );
  if (ov.pairs > 0) fail(`GATE 4 (${c.name}): ${ov.pairs} pair(s) of districts overlap by more than 1000 m² — is this one map?`);
  console.log(`  GATE 4 PASSED (${c.name}): no two districts overlap (${ov.invalid_as_published} polygon(s) invalid as published, repaired on write)`);

  // ── GATE 5: the districts tile the county ─────────────────────────────────
  const [cov] = await q(
    `WITH u AS (
       SELECT ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g), 4326))) AS geom
         FROM unnest($1::text[]) AS t(g)
     ), county AS (
       SELECT geometry AS geom FROM essentials.geofence_boundaries
        WHERE geo_id = $2 AND mtfcc = 'G4020' AND state = '45'
     )
     SELECT round((ST_Area(county.geom::geography)/2589988.11)::numeric, 3) AS county_sq_mi,
            round((ST_Area(u.geom::geography)/2589988.11)::numeric, 3)      AS districts_sq_mi,
            round((100 * ST_Area(ST_Intersection(county.geom, u.geom)::geography)
                       / ST_Area(county.geom::geography))::numeric, 3)      AS pct_covered,
            round((ST_Area(ST_Difference(u.geom, county.geom)::geography)/2589988.11)::numeric, 3) AS outside_county_sq_mi
       FROM u, county`,
    [c.rows.map((x) => x.geom), c.fips],
  );
  if (!cov) fail(`GATE 5 (${c.name}): the county polygon ${c.fips} (G4020) is not in production`);
  console.log(
    `  county ${cov.county_sq_mi} sq mi · districts ${cov.districts_sq_mi} sq mi · ${cov.pct_covered}% covered · ${cov.outside_county_sq_mi} sq mi outside the county polygon`,
  );
  if (Number(cov.pct_covered) < MIN_COVERAGE_PCT) {
    fail(`GATE 5 (${c.name}): the ${EXPECTED} districts cover only ${cov.pct_covered}% of the county`);
  }
  console.log(`  GATE 5 PASSED (${c.name}): the districts tile the county`);
}

if (DRY) {
  console.log('\n--dry-run complete, nothing written.');
  await pool.end();
  process.exit(0);
}

// ── write ────────────────────────────────────────────────────────────────────
await q('BEGIN');
let total = 0;
for (const c of byCounty) {
  const source =
    `SC Revenue and Fiscal Affairs Office, Boundaries_Districts/County_Council_Districts ` +
    `(gis.state.sc.us); ${c.name} County ordinance ${c.ordinance}, effective ${c.effective} (SC-4)`;
  const inserted = await q(
    `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
     SELECT r.geo_id, r.name, '45', $1,
            ST_MakeValid(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON(r.geom)), 4326)), $2, now()
       FROM jsonb_to_recordset($3::jsonb) AS r(geo_id text, name text, geom text)
     ON CONFLICT (geo_id, mtfcc) DO NOTHING
     RETURNING geo_id`,
    [c.mtfcc, source, JSON.stringify(c.rows)],
  );
  console.log(`${c.name}: inserted ${inserted.length} boundary row(s) into ${c.mtfcc}`);
  total += inserted.length;
}

for (const c of byCounty) {
  const [after] = await q(
    `SELECT count(*)::int AS n, count(*) FILTER (WHERE ST_IsValid(geometry))::int AS ok,
            count(DISTINCT ST_SRID(geometry))::int AS srids
       FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
    [c.mtfcc],
  );
  if (after.n !== EXPECTED || after.ok !== EXPECTED || after.srids !== 1) {
    await q('ROLLBACK');
    fail(`post-write (${c.name}): ${c.mtfcc} holds ${after.n} rows, ${after.ok} valid, ${after.srids} SRID(s) — expected ${EXPECTED}/${EXPECTED}/1`);
  }
  console.log(`post-write (${c.name}): ${after.ok}/${after.n} valid geometries, 1 SRID`);
}
await q('COMMIT');
console.log(`\ncommitted — ${total} boundary row(s) written this run.`);
await pool.end();
