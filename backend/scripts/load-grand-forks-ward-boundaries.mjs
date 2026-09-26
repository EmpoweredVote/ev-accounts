#!/usr/bin/env node
/**
 * load-grand-forks-ward-boundaries.mjs — Knight program, wave ND-3.
 *
 * Builds Grand Forks' seven council-ward polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='grand-forks-nd-ward-1'..'-7', mtfcc='X0067'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0146 creates the districts and their offices
 * and REFUSES TO RUN if these seven boundaries are absent — an office on a district with no
 * polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THE CITY'S OWN WARD MAP IS A PDF, WHICH IS THE GARY PROBLEM. `grandforksgov.com`'s
 * "Ward & Precinct Map" link redirects to `showdocument?id=42167`, a PDF whose `t=` tick
 * parameter dates it to early 2022. A PDF cannot answer "who represents this address".
 *
 * 🟢 THE STATE HAS THE GEOMETRY INSTEAD, AND IT IS THE 2026 ELECTION'S. The North Dakota GIS
 * Hub publishes `NDGISHUB Voter Precincts` — "Voter precinct splits for the 2026 election in
 * North Dakota... by Legislative District, County, City, Ward, School District, Emergency
 * Services, Commissioner District, Park District..." — modified 2026-05-05. Its `Ward` column
 * carries all seven Grand Forks wards, as 11 precinct PARTS which this script dissolves.
 * ▶ The same layer carries `Commissioner District`, which is what ND-4 will read.
 *
 * ⚠ A NAME TRAP SITS BESIDE IT. The same catalogue serves `Ward2015` and `Ward2010`. Those are
 * **Ward COUNTY aerial photography** — Ward is a North Dakota county. A search for "ward"
 * returns the photography before the wards.
 *
 * ⚠ WHAT THIS DOES AND DOES NOT PROVE. The publisher states the layer is for the 2026 election
 * and the catalogue's `modified` is 2026-05-05, which dates the LAYER. Nothing available dates
 * the ward BOUNDARIES themselves — Grand Forks publishes no adoption date and no second ward
 * layer, so there is nothing to diff a map against. That is the same limitation Akron had at
 * OH-3 and Columbia had at SC-3, and it is recorded rather than dressed up as a vintage proof.
 * What IS checkable is the count, and it is checked against the city's own sentence.
 *
 * Usage:
 *   node scripts/load-grand-forks-ward-boundaries.mjs --dry-run
 *   node scripts/load-grand-forks-ward-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'ev-accounts/nd-slice12' };
const SERVICE =
  'https://services1.arcgis.com/GOcSXpzwBHyk2nog/arcgis/rest/services/NDGISHUB_Voter_Precincts/FeatureServer/0';
const MTFCC = 'X0067';
const EXPECTED_WARDS = 7;
const EXPECTED_PARTS = 11;
const PLACE_GEO_ID = '3832060'; // TIGER place, Grand Forks city — already in production
const STATE_FIPS = '38';
const SOURCE =
  'North Dakota GIS Hub, NDGISHUB Voter Precincts layer 0 ' +
  '(services1.arcgis.com/GOcSXpzwBHyk2nog, "Voter precinct splits for the 2026 election in ' +
  'North Dakota... by Legislative District, County, City, Ward, ...", catalogue modified ' +
  '2026-05-05); 11 Grand Forks precinct parts dissolved by the Ward column into 7 wards, ' +
  "which is the count the city's own council page states; read 2026-09-25 (ND-3)";

/**
 * 🔴 THE COUNT IS CHECKED AGAINST THE CITY, NOT AGAINST ITSELF. grandforksgov.com's council
 * page: "The Grand Forks City Council consists of 7 members, each representing one of the
 * city's 7 wards." Seven, single-member, no at-large seat.
 */
const CITY_SENTENCE_WARDS = 7;

/**
 * 🔴 THE CLOSURE THRESHOLD IS NOT AKRON'S, AND A CLOSURE THRESHOLD IS NOT PORTABLE.
 * Akron's ten wards cover 99.971% of the TIGER place. Grand Forks' seven cover 99.351%, which
 * would FAIL Akron's 99.5% gate — and it is not a defect. The city's eastern boundary is the
 * RED RIVER, and the state's precinct digitization and the Census's place digitization trace it
 * differently. Measured 2026-09-25: the uncovered area is 0.1904 sq mi in **88 separate pieces**,
 * with 90 more pieces of ward lying outside the place, and the largest uncovered piece has a
 * compactness of 0.0072 — an extreme ribbon, where a circle is 1.0.
 * ▶ SO A PERCENTAGE IS NOT ENOUGH ON ITS OWN. Duluth's superseded council map left 8.68 SQ MI
 *   uncovered and still passed a plausibility check. The second gate asks how big the LARGEST
 *   SINGLE uncovered piece is, because that is what "a neighbourhood is in no ward" looks like.
 *
 * 🔴🔴 I FIRST WROTE THAT SECOND GATE AS COMPACTNESS, AND THE TAMPER PROVED IT WRONG. Dropping
 *   Ward 3 entirely — a whole missing ward, the exact defect this gate exists for — produced a
 *   largest uncovered piece of 1.90 sq mi at compactness **0.0524**, which sailed through a 0.10
 *   ceiling. The missing ward merges with the river slivers into one connected, ragged piece, so
 *   it is not compact at all. Compactness separates a ribbon from a disc; it does NOT separate a
 *   missing ward from a boundary artefact.
 *   The quantity that does separate them is AREA OF THE LARGEST PIECE: 0.1269 sq mi in the
 *   healthy case against 1.9032 sq mi with a ward missing, a 15x gap with room on both sides.
 *   ▶ Compactness is still PRINTED, because it is genuinely how the healthy case was recognised
 *     as slivers. It is no longer trusted to gate anything.
 *   ▶ AND THE GENERAL LESSON: a gate that has never been watched failing is a guess about what
 *     the defect looks like. This one was written confidently, documented confidently, and was
 *     wrong until it was tampered with.
 */
const MIN_COVERAGE_PCT = 99.0;
const MAX_LARGEST_GAP_SQ_MI = 0.50;

const DRY = process.argv.includes('--dry-run');
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

const url =
  `${SERVICE}/query?where=${encodeURIComponent("Ward LIKE 'Grand Forks Ward %'")}` +
  '&outFields=Ward,PPartID,Precinct,CityDistrict&outSR=4326&f=geojson';
const r = await fetch(url, { headers: UA });
const t = await r.text();
if (!t.trim().startsWith('{')) fail(`not JSON (HTTP ${r.status}) from NDGISHUB_Voter_Precincts`);
const j = JSON.parse(t);
if (j.error) fail(`ArcGIS error: ${JSON.stringify(j.error).slice(0, 160)}`);
// 🔴 A TRUNCATED QUERY IS A SILENT PARTIAL ANSWER. Assert it, never assume it.
if (j.exceededTransferLimit) fail('the query was truncated (exceededTransferLimit) — page it before trusting it');
const feats = j.features ?? [];
console.log(`NDGISHUB_Voter_Precincts, Ward LIKE 'Grand Forks Ward %': ${feats.length} precinct part(s)`);

// ── GATE 1: the parts, and the wards they dissolve to ────────────────────────
if (feats.length !== EXPECTED_PARTS) {
  fail(`GATE 1: expected ${EXPECTED_PARTS} precinct parts, got ${feats.length}`);
}
const wardNums = feats.map((f) => {
  const m = /^Grand Forks Ward (\d+)$/.exec(String(f.properties.Ward ?? '').trim());
  if (!m) fail(`GATE 1: unparseable Ward value ${JSON.stringify(f.properties.Ward)}`);
  return Number(m[1]);
});
const distinct = [...new Set(wardNums)].sort((a, b) => a - b);
if (distinct.length !== EXPECTED_WARDS || distinct[0] !== 1 || distinct[EXPECTED_WARDS - 1] !== EXPECTED_WARDS) {
  fail(`GATE 1: wards are not 1..${EXPECTED_WARDS} exactly — got ${distinct.join(',')}`);
}
console.log(`  GATE 1 PASSED: ${feats.length} parts dissolve to wards ${distinct.join(',')}`);

// ── GATE 2: the count agrees with the city's own sentence ────────────────────
// ⚠ This is a count check, not a vintage check. It would not notice a boundary that moved
// without changing the number of wards, and nothing available would.
if (distinct.length !== CITY_SENTENCE_WARDS) {
  fail(`GATE 2: the state layer has ${distinct.length} wards; the city's council page says ${CITY_SENTENCE_WARDS}`);
}
console.log(`  GATE 2 PASSED: ${distinct.length} wards, which is what the city's own council page states`);

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const parts = feats.map((f, i) => ({
  ward: wardNums[i],
  geom: JSON.stringify(f.geometry),
}));

// ── GATE 3: the seven dissolved wards do not overlap each other ──────────────
// 🔴 A layer that mixes two vintages usually shows up here first: two plans' wards overlap.
const [ov] = await q(
  `WITH p AS (SELECT r.ward, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS g
                FROM jsonb_to_recordset($1::jsonb) AS r(ward int, geom text)),
        w AS (SELECT ward, ST_MakeValid(ST_Union(g)) AS g FROM p GROUP BY ward)
   SELECT (SELECT count(*) FROM w a JOIN w b ON a.ward < b.ward
            WHERE ST_Area(ST_Intersection(a.g, b.g)::geography) > 1000)::int AS pairs,
          (SELECT count(*) FROM w)::int AS wards`,
  [JSON.stringify(parts)],
);
if (ov.wards !== EXPECTED_WARDS) fail(`GATE 3: dissolve produced ${ov.wards} wards, expected ${EXPECTED_WARDS}`);
if (ov.pairs > 0) fail(`GATE 3: ${ov.pairs} pair(s) of wards overlap by more than 1000 m² — is this one map?`);
console.log(`  GATE 3 PASSED: ${ov.wards} dissolved wards, no two overlap`);

// ── GATE 4: coverage, and the SHAPE of whatever is not covered ───────────────
const [cov] = await q(
  `WITH p AS (SELECT r.ward, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS g
                FROM jsonb_to_recordset($1::jsonb) AS r(ward int, geom text)),
        u AS (SELECT ST_MakeValid(ST_Union(g)) AS g FROM p),
        place AS (SELECT ST_MakeValid(geometry) AS g FROM essentials.geofence_boundaries
                   WHERE geo_id = $2 AND mtfcc = 'G4110' AND state = $3),
        gap AS (SELECT (ST_Dump(ST_Difference(place.g, u.g))).geom AS g FROM u, place),
        big AS (SELECT g FROM gap WHERE ST_Area(g::geography) > 1 ORDER BY ST_Area(g) DESC LIMIT 1)
   SELECT round((ST_Area(place.g::geography)/2589988.11)::numeric, 4) AS place_sq_mi,
          round((ST_Area(u.g::geography)/2589988.11)::numeric, 4)     AS wards_sq_mi,
          round((100 * ST_Area(ST_Intersection(place.g, u.g)::geography)
                     / ST_Area(place.g::geography))::numeric, 3)      AS pct_covered,
          round((ST_Area(ST_Difference(u.g, place.g)::geography)/2589988.11)::numeric, 4) AS outside_city_sq_mi,
          (SELECT count(*) FROM gap WHERE ST_Area(g::geography) > 1)::int AS gap_pieces,
          round((SELECT ST_Area(g::geography)/2589988.11 FROM big)::numeric, 5)  AS largest_gap_sq_mi,
          round((SELECT 4*pi()*ST_Area(g::geography)/nullif(power(ST_Perimeter(g::geography),2),0)
                   FROM big)::numeric, 4)                             AS largest_gap_compactness
     FROM u, place`,
  [JSON.stringify(parts), PLACE_GEO_ID, STATE_FIPS],
);
if (!cov) fail(`GATE 4: the TIGER place polygon ${PLACE_GEO_ID} is not in production`);
console.log(
  `  city ${cov.place_sq_mi} sq mi · wards ${cov.wards_sq_mi} sq mi · ${cov.pct_covered}% covered · ` +
  `${cov.outside_city_sq_mi} sq mi of ward area outside the place`,
);
console.log(
  `  uncovered: ${cov.gap_pieces} piece(s), largest ${cov.largest_gap_sq_mi} sq mi at compactness ${cov.largest_gap_compactness}`,
);
if (Number(cov.pct_covered) < MIN_COVERAGE_PCT) {
  fail(`GATE 4: the seven wards cover only ${cov.pct_covered}% of Grand Forks (floor ${MIN_COVERAGE_PCT}%)`);
}
if (Number(cov.largest_gap_sq_mi) >= MAX_LARGEST_GAP_SQ_MI) {
  fail(
    `GATE 4: the largest single uncovered piece is ${cov.largest_gap_sq_mi} sq mi ` +
    `(ceiling ${MAX_LARGEST_GAP_SQ_MI}) — that is a NEIGHBOURHOOD in no ward, not a boundary ` +
    `sliver. Dropping one whole ward produces 1.90 sq mi here. Do NOT load.`,
  );
}
console.log(
  `  GATE 4 PASSED: ${cov.pct_covered}% covered and the largest single gap is ${cov.largest_gap_sq_mi} sq mi ` +
  `(ceiling ${MAX_LARGEST_GAP_SQ_MI}) — edge slivers, not a hole`,
);

if (DRY) {
  console.log('\n--dry-run complete, nothing written.');
  await pool.end();
  process.exit(0);
}

await q('BEGIN');
const inserted = await q(
  `WITH p AS (SELECT r.ward, ST_MakeValid(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON(r.geom)), 4326)) AS g
                FROM jsonb_to_recordset($3::jsonb) AS r(ward int, geom text))
   INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
   SELECT 'grand-forks-nd-ward-' || p.ward,
          'Grand Forks City Council Ward ' || p.ward,
          $4, $1, ST_MakeValid(ST_Union(p.g)), $2, now()
     FROM p GROUP BY p.ward
   ON CONFLICT (geo_id, mtfcc) DO NOTHING
   RETURNING geo_id`,
  [MTFCC, SOURCE, JSON.stringify(parts), STATE_FIPS],
);
console.log(`\ninserted ${inserted.length} boundary row(s)`);

const [after] = await q('SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1', [MTFCC]);
if (after.n !== EXPECTED_WARDS) {
  await q('ROLLBACK');
  fail(`post-write: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED_WARDS}`);
}
const [valid] = await q(
  `SELECT count(*)::int AS n, count(*) FILTER (WHERE ST_IsValid(geometry))::int AS ok,
          count(DISTINCT ST_SRID(geometry))::int AS srids
     FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
  [MTFCC],
);
if (valid.ok !== EXPECTED_WARDS || valid.srids !== 1) {
  await q('ROLLBACK');
  fail(`post-write: ${valid.ok}/${valid.n} valid, ${valid.srids} SRID(s)`);
}
await q('COMMIT');
console.log(`post-write: ${valid.ok}/${valid.n} valid geometries, 1 SRID — committed.`);
await pool.end();
