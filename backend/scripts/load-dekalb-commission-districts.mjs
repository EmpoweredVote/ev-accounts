#!/usr/bin/env node
/**
 * load-dekalb-commission-districts.mjs — Atlanta full seed, stage 4b geography.
 *
 * Fetches DeKalb County's SEVEN commission areas — five single-member districts and two SUPER
 * districts that overlay them — and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='dekalb-county-ga-commission-1'..'-5',       mtfcc='X0079'
 *   essentials.geofence_boundaries  geo_id='dekalb-county-ga-super-commission-6'..'-7', mtfcc='X0080'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0242 creates the districts and their
 * offices and REFUSES TO RUN if these seven boundaries are absent.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 EVERY DEKALB ADDRESS HAS **TWO** COMMISSIONERS, AND THAT IS CORRECT.
 *
 * Districts 1-5 are single-member. Super Districts 6 and 7 each overlay roughly half the county.
 * So the two sets DELIBERATELY OVERLAP, and they get SEPARATE MTFCCs for that reason — an
 * address resolves to one of each.
 *
 * 🔴 THE USUAL "exactly one holder" POSITIVE CONTROL IS WRONG HERE and would fail on correct
 *    data. GATE 6 asserts exactly one DISTRICT and exactly one SUPER, separately.
 *
 * 🔴 DO NOT COPY FULTON HERE. Fulton has an at-large CHAIRPERSON who sits on its board and no
 *    super districts; DeKalb has no at-large chair and instead elects a county-wide CEO. The two
 *    counties are structurally opposite (ROSTERS.md R5, R6). Standardising misdescribes both.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 TWO NAME TRAPS IN THIS ORG. A LAYER'S NAME DOES NOT TELL YOU WHAT IT HOLDS.
 *
 * Measured 2026-10-17, feature counts in org IxVN2oUE9EYLSnPE:
 *
 *   DeKalb_County_Commission_District   2 features  ← reads like THE district layer. It is the SUPERS.
 *   Commissioner_Districts           2540 features  ← parcels or blocks, not districts at all.
 *   Commission_Districts                5 features  ← the single-member map (used here as CONFIRM)
 *   Plan_1/2/3_Commissioner_District    5 each      ← redistricting OPTIONS, not the adopted map
 *   Proposed_* (four services)                      ← likewise
 *
 * The county publishes the options and the adopted map side by side, exactly as Columbus did.
 * `Adopted_*` is the pair to load, and the name is the only thing distinguishing them — which is
 * why GATE 3 dates the map geometrically rather than trusting the word "Adopted".
 *
 *   node scripts/load-dekalb-commission-districts.mjs --dry-run
 *   node scripts/load-dekalb-commission-districts.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0',
  Accept: 'application/json,text/plain,*/*',
};

const ORG = 'https://services2.arcgis.com/IxVN2oUE9EYLSnPE/arcgis/rest/services';
const PRIMARY_D = `${ORG}/Adopted_Commissioner_District/FeatureServer/0`;
const CONFIRM_D = `${ORG}/Commission_Districts/FeatureServer/0`;
const PLANS = [1, 2, 3].map((n) => `${ORG}/Plan_${n}_Commissioner_District/FeatureServer/0`);
const PRIMARY_S = `${ORG}/Adopted_Super_Commissioner_District/FeatureServer/0`;
const CONFIRM_S = `${ORG}/Super_Commission_Districts/FeatureServer/0`;

const MTFCC_D = 'X0079';
const MTFCC_S = 'X0080';
const EXPECTED_D = 5;
const EXPECTED_S = 2;
const COUNTY_GEO_ID = '13089';
const COUNTY_MTFCC = 'G4020';
const STATE_FIPS = '13';

const AGREE_PCT = 1.0;
const DIFFER_PCT = 2.0;
const COVERAGE_MIN_PCT = 99.0;

// 🔴 GATE 3 CANNOT SIMPLY REQUIRE DISAGREEMENT WITH EVERY PLAN. One of the three plans is
// presumably the one the county ADOPTED, so agreement with ONE is expected and correct.
// What must never happen is agreement with ALL THREE — that would mean the three "options" are
// one map and the gate can no longer date anything. So: at least this many plans must differ.
const PLANS_MUST_DIFFER = 2;

// 🔴 Each super overlays about half the county. Population carried by the layers themselves,
// measured 2026-10-17: districts 152,106-154,029 each; supers 381,445 and 382,937. The supers
// are ~2.5x a district and together cover the county twice.
const SUPER_MIN_PCT_OF_COUNTY = 35.0;
const SUPER_MAX_PCT_OF_COUNTY = 65.0;

const SOURCE_D =
  'DeKalb County GIS, ArcGIS org IxVN2oUE9EYLSnPE, feature service Adopted_Commissioner_District, ' +
  '5 single-member districts, read 2026-10-17. Vintage established GEOMETRICALLY, not from the word ' +
  '"Adopted": cross-checked live against Commission_Districts (AGREES) and against the three ' +
  'Plan_N_Commissioner_District redistricting options, at least two of which it DISAGREES with. ' +
  'Every DeKalb address also has a SUPER district commissioner (X0080) — two commissioners, by design.';

const SOURCE_S =
  'DeKalb County GIS, ArcGIS org IxVN2oUE9EYLSnPE, feature service Adopted_Super_Commissioner_District, ' +
  '2 SUPER districts (6 and 7) each overlaying about half the county, read 2026-10-17. Cross-checked ' +
  'live against Super_Commission_Districts. These DELIBERATELY OVERLAP the five single-member ' +
  'districts in X0079: every DeKalb address elects one district commissioner AND one super ' +
  'commissioner. 🔴 An "exactly one holder" control is WRONG here.';

const DRY = process.argv.includes('--dry-run');
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

// 🔴 A GATE NOBODY HAS WATCHED FAIL IS NOT A GATE.
//   count     -> GATE 1  drop a district
//   countsuper-> GATE 1  drop a super district
//   agree     -> GATE 2  point the agreement check at Plan_1
//   vintage   -> GATE 3  point all three plan comparisons at the primary layer itself
//   overlap   -> GATE 4  duplicate district 1's polygon onto district 2
//   overlay   -> GATE 5  replace super 6 with district 1, so the overlay stops overlaying
//   probe     -> GATE 6  shift whichever super holds Decatur away from it
//   coverage  -> GATE 7  shrink district 3 to a sliver
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';

const numOf = (p) => {
  const raw = String(p.DISTRICT ?? p.District ?? p.district ?? '');
  const m = raw.match(/(\d+)/);
  return m ? Number(m[1]) : NaN;
};

const getLayer = async (url, label) => {
  const r = await fetch(`${url}/query?where=1%3D1&outFields=*&returnGeometry=true&outSR=4326&f=geojson`, { headers: UA });
  const t = await r.text();
  if (!t.trim().startsWith('{')) fail(`${label}: not JSON (HTTP ${r.status}, ${t.length} bytes)`);
  const j = JSON.parse(t);
  if (j.error) fail(`${label}: ArcGIS error ${JSON.stringify(j.error).slice(0, 180)}`);
  const fs = j.features ?? [];
  if (!fs.length) fail(`${label}: ZERO features — this check would be blind. Fix it before loading.`);
  const bad = fs.filter((f) => !Number.isInteger(numOf(f.properties)));
  if (bad.length) fail(`${label}: ${bad.length} feature(s) carry no readable DISTRICT — blind`);
  return fs;
};

const rawD = await getLayer(PRIMARY_D, 'Adopted_Commissioner_District');
const rawS = await getLayer(PRIMARY_S, 'Adopted_Super_Commissioner_District');
console.log(`Adopted_Commissioner_District: ${rawD.length} features · Adopted_Super_Commissioner_District: ${rawS.length}`);

let featsD = rawD;
let featsS = rawS;
if (CONTROL) {
  console.log(`\n⚠ CONTROL "${CONTROL}" ACTIVE — a gate MUST fail below, or the gate is worthless.\n`);
  if (CONTROL === 'count') featsD = rawD.slice(0, EXPECTED_D - 1);
  if (CONTROL === 'countsuper') featsS = rawS.slice(0, EXPECTED_S - 1);
}

// ── GATE 1: five districts 1..5, two supers 6..7 ─────────────────────────────
{
  const d = featsD.map((f) => numOf(f.properties)).sort((a, b) => a - b);
  const s = featsS.map((f) => numOf(f.properties)).sort((a, b) => a - b);
  if (featsD.length !== EXPECTED_D || d.join(',') !== '1,2,3,4,5') fail(`GATE 1: expected districts 1..5, got [${d.join(',')}]`);
  if (featsS.length !== EXPECTED_S || s.join(',') !== '6,7') fail(`GATE 1: expected SUPER districts 6,7, got [${s.join(',')}]`);
  console.log(`  GATE 1 PASSED: districts ${d.join(',')} and SUPER districts ${s.join(',')}`);
}

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const toRows = (fs, kind) =>
  fs.map((f) => {
    const n = numOf(f.properties);
    return kind === 'd'
      ? { district: n, geo_id: `dekalb-county-ga-commission-${n}`, name: `DeKalb County Commission District ${n}`, geom: JSON.stringify(f.geometry) }
      : { district: n, geo_id: `dekalb-county-ga-super-commission-${n}`, name: `DeKalb County Super Commission District ${n}`, geom: JSON.stringify(f.geometry) };
  });

let rowsD = toRows(featsD, 'd');
let rowsS = toRows(featsS, 's');
const json = (rs) => JSON.stringify(rs.map((r) => ({ district: r.district, geo_id: r.geo_id, name: r.name, geom: r.geom })));
const AS_GEOM = `
  SELECT r.district, r.geo_id, r.name,
         ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326))) AS geom
    FROM jsonb_to_recordset($1::jsonb) AS r(district int, geo_id text, name text, geom text)`;

const compare = async (a, b) =>
  q(
    `WITH x AS (SELECT r.district, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom),4326)) geom
                  FROM jsonb_to_recordset($1::jsonb) AS r(district int, geom text)),
          y AS (SELECT r.district, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom),4326)) geom
                  FROM jsonb_to_recordset($2::jsonb) AS r(district int, geom text))
     SELECT x.district,
            round((100*ST_Area(ST_SymDifference(x.geom,y.geom)::geography)
                     / NULLIF(ST_Area(x.geom::geography),0))::numeric,4) AS pct
       FROM x JOIN y ON y.district = x.district ORDER BY x.district`,
    [JSON.stringify(a.map((r) => ({ district: r.district, geom: r.geom }))),
     JSON.stringify(b.map((r) => ({ district: r.district, geom: r.geom })))],
  );

// ── GATE 2: the adopted maps AGREE with the county's other published copies ──
{
  const otherD = toRows(await getLayer(CONTROL === 'agree' ? PLANS[0] : CONFIRM_D, 'confirm district layer'), 'd');
  const dD = await compare(toRows(rawD, 'd'), otherD);
  if (dD.length !== EXPECTED_D) fail(`GATE 2: only ${dD.length} district(s) paired up — the DISTRICT keys do not match`);
  const worstD = Math.max(...dD.map((x) => Number(x.pct)));
  console.log(`  GATE 2: worst district difference vs Commission_Districts = ${worstD.toFixed(4)}%`);
  if (worstD >= AGREE_PCT) fail(`GATE 2: Adopted_Commissioner_District DISAGREES with Commission_Districts by up to ${worstD.toFixed(4)}% (limit ${AGREE_PCT}%) — two different maps. Do NOT load.`);

  const otherS = toRows(await getLayer(CONFIRM_S, 'confirm super layer'), 's');
  const dS = await compare(toRows(rawS, 's'), otherS);
  if (dS.length !== EXPECTED_S) fail(`GATE 2: only ${dS.length} super district(s) paired up — this check is blind`);
  const worstS = Math.max(...dS.map((x) => Number(x.pct)));
  console.log(`  GATE 2: worst SUPER difference vs Super_Commission_Districts = ${worstS.toFixed(4)}%`);
  if (worstS >= AGREE_PCT) fail(`GATE 2: the adopted SUPER map disagrees with Super_Commission_Districts by up to ${worstS.toFixed(4)}% (limit ${AGREE_PCT}%)`);
  console.log('  GATE 2 PASSED');
}

// ── GATE 3: the adopted map is not merely one of the published OPTIONS ───────
// 🔴 Five is five under every plan, so only geometry can date this. Agreement with ONE plan is
//    expected — that is the plan the county adopted. Agreement with ALL THREE means the options
//    are one map and this gate has gone blind.
{
  const diffs = [];
  for (let i = 0; i < PLANS.length; i++) {
    const url = CONTROL === 'vintage' ? PRIMARY_D : PLANS[i];
    const other = toRows(await getLayer(url, `Plan_${i + 1}`), 'd');
    const d = await compare(toRows(rawD, 'd'), other);
    if (d.length !== EXPECTED_D) fail(`GATE 3: Plan_${i + 1} paired only ${d.length} district(s) — this check is blind`);
    const worst = Math.max(...d.map((x) => Number(x.pct)));
    diffs.push({ plan: i + 1, worst });
  }
  console.log(`  GATE 3: worst difference vs each plan — ${diffs.map((x) => `Plan_${x.plan}=${x.worst.toFixed(2)}%`).join('  ')}`);
  const differing = diffs.filter((x) => x.worst > DIFFER_PCT).map((x) => x.plan);
  if (differing.length < PLANS_MUST_DIFFER) {
    fail(
      `GATE 3: the adopted map differs from only ${differing.length} of ${PLANS.length} redistricting ` +
        `options (need at least ${PLANS_MUST_DIFFER}). Either the published options are all the same map, ` +
        `or this layer is an OPTION rather than the adopted plan. The count (5) cannot tell them apart.`,
    );
  }
  console.log(`  GATE 3 PASSED: differs from plans [${differing.join(',')}] — it is not simply one of the options`);
}

// ── GATE 4: within each set, no two areas overlap ────────────────────────────
{
  if (CONTROL === 'overlap') rowsD = rowsD.map((r) => (r.district === 2 ? { ...r, geom: rowsD.find((x) => x.district === 1).geom } : r));
  for (const [label, rs] of [['districts', rowsD], ['SUPER districts', rowsS]]) {
    const [ov] = await q(
      `WITH d AS (${AS_GEOM})
       SELECT (SELECT count(*) FROM d a JOIN d b ON a.district < b.district
                WHERE ST_Area(ST_Intersection(a.geom,b.geom)::geography) > 1000)::int AS pairs`,
      [json(rs)],
    );
    if (ov.pairs > 0) fail(`GATE 4: ${ov.pairs} pair(s) of ${label} overlap by over 1000 m² — within one set they must not.`);
  }
  console.log('  GATE 4 PASSED: no overlap within the districts, and none within the supers');
}

// ── GATE 5: the SUPERS DO overlay the districts, and each is about half ──────
// 🔴 The positive assertion. If the supers stopped overlapping the districts they would not be
//    an overlay, and every DeKalb address would get one commissioner instead of two.
{
  if (CONTROL === 'overlay') rowsS = rowsS.map((r) => (r.district === 6 ? { ...r, geom: rowsD.find((x) => x.district === 1).geom } : r));
  const cross = await q(
    `WITH s AS (${AS_GEOM}), d AS (SELECT r.district, ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom),4326))) geom
                                     FROM jsonb_to_recordset($2::jsonb) AS r(district int, geo_id text, name text, geom text))
     SELECT s.district AS super, count(*) FILTER (WHERE ST_Area(ST_Intersection(s.geom,d.geom)::geography) > 100000)::int AS districts_touched
       FROM s JOIN d ON true GROUP BY s.district ORDER BY s.district`,
    [json(rowsS), json(rowsD)],
  );
  console.log(`  GATE 5: ${cross.map((c) => `super ${c.super} overlays ${c.districts_touched} district(s)`).join('; ')}`);
  for (const c of cross) {
    if (c.districts_touched < 2) {
      fail(
        `GATE 5: SUPER district ${c.super} overlays only ${c.districts_touched} single-member district(s). ` +
          `A super district spans about half the county and must cross several. This is not an overlay.`,
      );
    }
  }
  const share = await q(
    `WITH s AS (${AS_GEOM}),
          c AS (SELECT geometry geom FROM essentials.geofence_boundaries WHERE geo_id=$2 AND mtfcc=$3 AND state=$4)
     SELECT s.district, round((100*ST_Area(ST_Intersection(s.geom,c.geom)::geography)
                                 / NULLIF(ST_Area(c.geom::geography),0))::numeric,2) AS pct_of_county
       FROM s, c ORDER BY s.district`,
    [json(rowsS), COUNTY_GEO_ID, COUNTY_MTFCC, STATE_FIPS],
  );
  console.log(`  GATE 5: ${share.map((x) => `super ${x.district} = ${x.pct_of_county}% of DeKalb`).join('; ')}`);
  for (const x of share) {
    const p = Number(x.pct_of_county);
    if (p < SUPER_MIN_PCT_OF_COUNTY || p > SUPER_MAX_PCT_OF_COUNTY) {
      fail(`GATE 5: SUPER district ${x.district} covers ${p}% of DeKalb, outside ${SUPER_MIN_PCT_OF_COUNTY}-${SUPER_MAX_PCT_OF_COUNTY}%. Each super should be about half the county.`);
    }
  }
  console.log('  GATE 5 PASSED: the supers are a genuine half-county overlay');
}

// ── GATE 6: the address probe the product actually runs ──────────────────────
// 🔴 EVERY ANCHOR IS GEOCODED (Census onelineaddress, Public_AR_Current, 2026-10-17) and then
//    CHECKED AGAINST PRODUCTION GEOMETRY for which county it falls in.
// 🔴 THE EXPECTATION IS ONE DISTRICT **AND** ONE SUPER — not "exactly one holder".
const DEKALB_GOV = [-84.298959, 33.774513]; // 1300 Commerce Dr, Decatur — DeKalb County HQ. DEKALB.
const ATL_CITY_HALL = [-84.39028, 33.747923]; // 55 Trinity Ave SW — Atlanta City Hall. FULTON, not DeKalb.
{
  if (CONTROL === 'probe') {
    const [hit] = await q(`WITH d AS (${AS_GEOM}) SELECT district FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3),4326))`, [json(rowsS), DEKALB_GOV[0], DEKALB_GOV[1]]);
    if (!hit) fail('CONTROL probe: no SUPER district holds the DeKalb HQ to begin with — nothing to tamper');
    const shift = (co) => (typeof co[0] === 'number' ? [co[0] + 5, co[1]] : co.map(shift));
    rowsS = rowsS.map((r) => (r.district === hit.district
      ? { ...r, geom: JSON.stringify(((g) => ({ ...g, coordinates: shift(g.coordinates) }))(JSON.parse(r.geom))) }
      : r));
  }
  const hits = async (rs, lon, lat) =>
    (await q(`WITH d AS (${AS_GEOM}) SELECT count(*)::int n, string_agg(district::text,',') ds FROM d WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($2,$3),4326))`, [json(rs), lon, lat]))[0];

  const gd = await hits(rowsD, DEKALB_GOV[0], DEKALB_GOV[1]);
  const gs = await hits(rowsS, DEKALB_GOV[0], DEKALB_GOV[1]);
  const ad = await hits(rowsD, ATL_CITY_HALL[0], ATL_CITY_HALL[1]);
  const as_ = await hits(rowsS, ATL_CITY_HALL[0], ATL_CITY_HALL[1]);

  if (gd.n !== 1) fail(`GATE 6: the DeKalb County HQ falls in ${gd.n} single-member district(s), expected exactly 1`);
  if (gs.n !== 1) fail(`GATE 6: the DeKalb County HQ falls in ${gs.n} SUPER district(s), expected exactly 1`);
  if (ad.n !== 0 || as_.n !== 0) {
    fail(
      `GATE 6: CONTROL FAILED — Atlanta City Hall falls in ${ad.n} DeKalb district(s) and ${as_.n} super(s). ` +
        `It is in FULTON County. This layer is the wrong ground.`,
    );
  }
  console.log(`  GATE 6 PASSED: DeKalb HQ → district ${gd.ds} AND super ${gs.ds} (two commissioners, by design); Atlanta City Hall → neither (control)`);
}

// ── GATE 7: each set tiles the county ────────────────────────────────────────
{
  if (CONTROL === 'coverage') {
    rowsD = rowsD.map((r) => {
      if (r.district !== 3) return r;
      const g = JSON.parse(r.geom);
      const ring = g.type === 'Polygon' ? g.coordinates[0] : g.coordinates[0][0];
      const [x, y] = ring[0];
      return { ...r, geom: JSON.stringify({ type: 'Polygon', coordinates: [[[x, y], [x + 0.001, y], [x + 0.001, y + 0.001], [x, y + 0.001], [x, y]]] }) };
    });
  }
  for (const [label, rs] of [['districts', rowsD], ['SUPER districts', rowsS]]) {
    const [cov] = await q(
      `WITH d AS (${AS_GEOM}), u AS (SELECT ST_UnaryUnion(ST_Collect(geom)) geom FROM d),
            c AS (SELECT geometry geom FROM essentials.geofence_boundaries WHERE geo_id=$2 AND mtfcc=$3 AND state=$4)
       SELECT round((100*ST_Area(ST_Intersection(u.geom,c.geom)::geography)
                        / NULLIF(ST_Area(c.geom::geography),0))::numeric,3) pct FROM u,c`,
      [json(rs), COUNTY_GEO_ID, COUNTY_MTFCC, STATE_FIPS],
    );
    if (cov.pct === null) fail(`GATE 7: TIGER county ${COUNTY_GEO_ID}/${COUNTY_MTFCC} is not in production`);
    console.log(`  GATE 7: the ${label} cover ${cov.pct}% of DeKalb County`);
    if (Number(cov.pct) < COVERAGE_MIN_PCT) fail(`GATE 7: the ${label} cover only ${cov.pct}% of DeKalb (floor ${COVERAGE_MIN_PCT}%) — one is missing or this is the wrong ground.`);
  }
  console.log('  GATE 7 PASSED');
}

if (CONTROL) fail(`CONTROL "${CONTROL}" reached the end WITHOUT firing a gate. The gate it targets is worthless. Fix it.`);

// ── Write ────────────────────────────────────────────────────────────────────
for (const [mtfcc, rs] of [[MTFCC_D, rowsD], [MTFCC_S, rowsS]]) {
  const [b] = await q(`SELECT count(*)::int n FROM essentials.geofence_boundaries WHERE mtfcc=$1`, [mtfcc]);
  console.log(`\n  ${mtfcc} currently holds ${b.n} row(s) in production`);
  if (DRY) {
    console.table(await q(`WITH d AS (${AS_GEOM}) SELECT geo_id, name, round((ST_Area(geom::geography)/1e6)::numeric,3) km2 FROM d ORDER BY district`, [json(rs)]));
    continue;
  }
  const source = mtfcc === MTFCC_D ? SOURCE_D : SOURCE_S;
  const [{ written }] = await q(
    `WITH d AS (${AS_GEOM}), ins AS (
       INSERT INTO essentials.geofence_boundaries (geo_id,name,state,mtfcc,geometry,source,imported_at)
       SELECT d.geo_id,d.name,$2,$3,d.geom,$4,now() FROM d
       ON CONFLICT (geo_id,mtfcc) DO NOTHING RETURNING 1)
     SELECT count(*)::int AS written FROM ins`,
    [json(rs), STATE_FIPS, mtfcc, source],
  );
  const want = mtfcc === MTFCC_D ? EXPECTED_D : EXPECTED_S;
  console.log(`  inserted ${written} boundary row(s) into ${mtfcc} (idempotent: a re-run inserts 0)`);
  const [a] = await q(`SELECT count(*)::int n FROM essentials.geofence_boundaries WHERE mtfcc=$1`, [mtfcc]);
  if (a.n !== want) fail(`POST: ${mtfcc} holds ${a.n} rows, expected ${want}`);
  console.log(`  POST PASSED: ${mtfcc} holds ${a.n} rows`);
}

if (DRY) console.log('\n--dry-run: nothing written.');
await pool.end();
