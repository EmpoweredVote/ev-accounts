#!/usr/bin/env node
/**
 * load-akron-ward-boundaries.mjs — Knight program, wave OH-3.
 *
 * Fetches Akron's ten council-ward polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='akron-oh-ward-1'..'-10', mtfcc='X0063'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0133 creates the districts and their offices
 * and REFUSES TO RUN if these ten boundaries are absent — an office on a district with no polygon
 * is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🟢 THE SOURCE IS THE CITY'S OWN GIS ORG, AND IT CARRIES ITS OWN CROSS-CHECK. `City of Akron
 * Wards` (owner **AkronGIS**, services1.arcgis.com/8roChjXOF0iBhNoB) publishes ten polygons and,
 * unusually, a `COUNCILPERSON` field. All ten names match the council's own members page exactly
 * — two different city departments agreeing on the same ten people. That is a far better vintage
 * signal than a layer with no attributes at all (Columbia at SC-3 had only a `LABEL`).
 * Layer `editingInfo.dataLastEditDate` = **2025-12-02**.
 *
 * ⚠ THE LAYER IS CURRENT ON NAMES AND STALE ON TITLES, AND THAT IS WHY ONLY THE NAMES ARE USED.
 * Its `TITLE` field calls Ward 6 "President Pro Tem"; the council's own page says Ward 6 is
 * VICE-PRESIDENT and Ward 9 is President Pro-Tem. Leadership titles are not stored on offices
 * here, so nothing downstream is affected — but a layer can be fresh in one column and stale in
 * another, and "the names matched" does not license trusting the rest of the row.
 *
 * 🔴 THE OBVIOUS SEARCH ROUTES ARE BOTH TRAPS, MEASURED 2026-09-23:
 *   · `data-akron.opendata.arcgis.com/api/v3/datasets?q=ward` is a FEDERATED catalogue. Its
 *     "Ward Boundaries" hits resolve to **East Renfrewshire Council, Scotland**, and others to
 *     Sherwood, Milton (Ontario) and Elyria. This is IN-6's Lake County trap — for a generically
 *     named thing, an aggregated source is a JURISDICTION-collision risk, not just a staleness
 *     risk.
 *   · A web summary asserted "Akron has 8 wards". It has TEN, per the city's own government page
 *     and the council's members page. A count from a summary is not a count from the body.
 *   · `gis.akronohio.gov` does not resolve.
 *
 *   node scripts/load-akron-ward-boundaries.mjs --dry-run
 *   node scripts/load-akron-ward-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0' };
const SERVICE =
  'https://services1.arcgis.com/8roChjXOF0iBhNoB/arcgis/rest/services/City_of_Akron_Wards/FeatureServer/0';
const MTFCC = 'X0063';
const EXPECTED = 10;
const PLACE_GEO_ID = '3901000'; // TIGER place, Akron city — already in production (62.2741 sq mi)
const STATE_FIPS = '39';
const SOURCE =
  'City of Akron GIS, City_of_Akron_Wards layer 0 "City of Akron Council Wards" ' +
  '(services1.arcgis.com/8roChjXOF0iBhNoB, owner AkronGIS, dataLastEditDate 2025-12-02); ' +
  "its COUNCILPERSON field agrees with the council's own members page on all 10 wards, " +
  'read 2026-09-23 (OH-3)';

// The council's own members page, akroncitycouncil.org/members, read 2026-09-23. Used as the
// positive control on the layer's COUNCILPERSON field — a DIFFERENT publisher, not a restatement.
const COUNCIL_PAGE = {
  1: 'Fran Wilson', 2: 'Phil Lombardo', 3: 'Margo Sommerville', 4: 'Jan Davis', 5: 'Johnnie Hannah',
  6: 'Brad McKitrick', 7: 'Donnie Kammer', 8: 'Bruce Bolden', 9: 'Tina Boyes', 10: 'Sharon Connor',
};

const DRY = process.argv.includes('--dry-run');
const fail = (m) => {
  console.error(`\n🔴 ${m}`);
  process.exit(1);
};

const r = await fetch(`${SERVICE}/query?where=1%3D1&outFields=WARD_NO,WARD,COUNCILPERSON&outSR=4326&f=geojson`, {
  headers: UA,
});
const t = await r.text();
if (!t.trim().startsWith('{')) fail(`not JSON (HTTP ${r.status}) from City_of_Akron_Wards`);
const j = JSON.parse(t);
if (j.error) fail(`ArcGIS error: ${JSON.stringify(j.error).slice(0, 160)}`);
const feats = j.features;
console.log(`City_of_Akron_Wards: ${feats.length} features`);

// ── GATE 1: the shape of the layer ───────────────────────────────────────────
if (feats.length !== EXPECTED) fail(`GATE 1: expected ${EXPECTED} features, got ${feats.length}`);
const nums = feats.map((f) => Number(f.properties.WARD_NO));
const sorted = [...nums].sort((a, b) => a - b);
if (new Set(nums).size !== EXPECTED || sorted[0] !== 1 || sorted[EXPECTED - 1] !== EXPECTED) {
  fail(`GATE 1: wards are not 1..${EXPECTED} exactly — got ${sorted.join(',')}`);
}
console.log(`  GATE 1 PASSED: wards ${sorted.join(',')}`);

// ── GATE 2: the layer's COUNCILPERSON agrees with the council's own page ─────
// 🔴 THIS IS THE VINTAGE CHECK, AND IT IS THE ONLY ONE AVAILABLE. Akron publishes no adoption
// date and no second ward layer, so — as at Columbia — there is nothing to diff a map against.
// What there IS here is a second publisher naming the same ten people. If the layer had been
// left over from a previous council, this gate would fire.
// ⚠ It proves the layer agrees with the council TODAY. It does not date the boundaries, and
// nothing available does. Recorded as a limitation rather than dressed up as a vintage proof.
const mismatches = [];
for (const f of feats) {
  const n = Number(f.properties.WARD_NO);
  const got = String(f.properties.COUNCILPERSON ?? '').trim();
  if (got !== COUNCIL_PAGE[n]) mismatches.push(`ward ${n}: layer "${got}" vs council page "${COUNCIL_PAGE[n]}"`);
}
if (mismatches.length) {
  fail(`GATE 2: the layer and the council's members page disagree on ${mismatches.length} ward(s) —\n    ` +
       mismatches.join('\n    ') +
       `\n  Do NOT load. Either the layer is stale or the roster moved; find out which.`);
}
console.log(`  GATE 2 PASSED: all ${EXPECTED} COUNCILPERSON values match the council's own members page`);

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const rows = feats.map((f) => {
  const n = Number(f.properties.WARD_NO);
  return {
    geo_id: `akron-oh-ward-${n}`,
    name: `Akron City Council Ward ${n}`,
    geom: JSON.stringify(f.geometry),
  };
});

// ── GATE 3: the ten wards do not overlap each other ──────────────────────────
// 🔴 A layer that mixes two vintages usually shows up here first: two plans' wards overlap.
const [ov] = await q(
  `WITH d AS (SELECT r.geo_id,
                     ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)               AS raw,
                     ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS geom
                FROM jsonb_to_recordset($1::jsonb) AS r(geo_id text, name text, geom text))
   SELECT (SELECT count(*) FROM d a JOIN d b ON a.geo_id < b.geo_id
            WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 1000)::int AS pairs,
          (SELECT count(*) FROM d WHERE NOT ST_IsValid(raw))::int                  AS invalid_as_published`,
  [JSON.stringify(rows)],
);
if (ov.pairs > 0) fail(`GATE 3: ${ov.pairs} pair(s) of wards overlap by more than 1000 m² — is this one map?`);
console.log(`  GATE 3 PASSED: no two wards overlap (${ov.invalid_as_published} polygon(s) invalid as published)`);

// ── GATE 4: the ten wards tile the city ──────────────────────────────────────
// ⚠ Not every city tiles — Fort Wayne's six districts correctly leave 1.13 sq mi uncovered,
// because Fort Wayne also elects at-large seats over the rest. Akron's TEN wards DO partition
// the city, so this gate belongs to Akron and demands closure, not merely a bound.
// 🔴 The threshold is 99.5%, not 100%: the wards and the TIGER place are two DIGITIZATIONS of
// one boundary, so a sliver difference is expected and is not a defect. Measured 2026-09-23:
// 99.971% covered, 0.0181 sq mi of city uncovered and 0.0189 sq mi of ward area outside it.
const [cov] = await q(
  `WITH u AS (
     SELECT ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g), 4326))) AS geom
       FROM unnest($1::text[]) AS t(g)
   ), place AS (
     SELECT ST_MakeValid(geometry) AS geom FROM essentials.geofence_boundaries
      WHERE geo_id = $2 AND mtfcc = 'G4110' AND state = $3
   )
   SELECT round((ST_Area(place.geom::geography)/2589988.11)::numeric, 4) AS place_sq_mi,
          round((ST_Area(u.geom::geography)/2589988.11)::numeric, 4)     AS wards_sq_mi,
          round((100 * ST_Area(ST_Intersection(place.geom, u.geom)::geography)
                     / ST_Area(place.geom::geography))::numeric, 3)      AS pct_covered,
          round((ST_Area(ST_Difference(u.geom, place.geom)::geography)/2589988.11)::numeric, 4) AS outside_city_sq_mi
     FROM u, place`,
  [rows.map((x) => x.geom), PLACE_GEO_ID, STATE_FIPS],
);
if (!cov) fail(`GATE 4: the TIGER place polygon ${PLACE_GEO_ID} is not in production`);
console.log(
  `  city ${cov.place_sq_mi} sq mi · wards ${cov.wards_sq_mi} sq mi · ${cov.pct_covered}% of the city covered · ${cov.outside_city_sq_mi} sq mi of ward area lies outside the TIGER place`,
);
if (Number(cov.pct_covered) < 99.5) fail(`GATE 4: the ten wards cover only ${cov.pct_covered}% of Akron`);
console.log('  GATE 4 PASSED: the wards tile the city');

if (DRY) {
  console.log('\n--dry-run complete, nothing written.');
  await pool.end();
  process.exit(0);
}

await q('BEGIN');
const inserted = await q(
  `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
   SELECT r.geo_id, r.name, $4, $1,
          ST_MakeValid(ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON(r.geom)), 4326)), $2, now()
     FROM jsonb_to_recordset($3::jsonb) AS r(geo_id text, name text, geom text)
   ON CONFLICT (geo_id, mtfcc) DO NOTHING
   RETURNING geo_id`,
  [MTFCC, SOURCE, JSON.stringify(rows), STATE_FIPS],
);
console.log(`\ninserted ${inserted.length} boundary row(s)`);

const [after] = await q('SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1', [MTFCC]);
if (after.n !== EXPECTED) {
  await q('ROLLBACK');
  fail(`post-write: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED}`);
}
const [valid] = await q(
  `SELECT count(*)::int AS n, count(*) FILTER (WHERE ST_IsValid(geometry))::int AS ok,
          count(DISTINCT ST_SRID(geometry))::int AS srids
     FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
  [MTFCC],
);
if (valid.ok !== EXPECTED || valid.srids !== 1) {
  await q('ROLLBACK');
  fail(`post-write: ${valid.ok}/${valid.n} valid, ${valid.srids} SRID(s)`);
}
await q('COMMIT');
console.log(`post-write: ${valid.ok}/${valid.n} valid geometries, 1 SRID — committed.`);
await pool.end();
