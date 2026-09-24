#!/usr/bin/env node
/**
 * load-summit-council-boundaries.mjs — Knight program, wave OH-4.
 *
 * Fetches Summit County's eight council-district polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='summit-oh-council-district-1'..'-8', mtfcc='X0064'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0136 creates the districts and their offices
 * and REFUSES TO RUN if these eight boundaries are absent.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 SUMMIT COUNTY PUBLISHES TWO DIFFERENT COUNCIL MAPS FROM THE SAME GIS ORG, AND THEY
 * DISAGREE ABOUT AKRON. Measured 2026-09-24:
 *
 *   Summit_County_Council_2025  layer "Plan A4"   — 11 features (8 districts + 3 at-large with
 *                                                   NULL geometry), created 2025-02-18,
 *                                                   last edited 2026-03-02
 *   County_Council_2023         field `Dist2013`  — 8 features, last edited 2025-02-06
 *
 * They are not two renderings of one map. Per-district symmetric difference runs from 5% to
 * **209%** of district area, and **Akron City Hall is District 5 under County_Council_2023 and
 * District 4 under Plan A4** — so the choice decides which real person is shown as the county
 * council member for this slice's own city.
 *
 * ⚠ NEITHER NAME NOR CLOSURE CAN SETTLE IT. "County_Council_2023" sounds current and carries a
 * field named for 2013; "Plan A4" is a districting-commission plan label, and SC-4 learned that a
 * commission org also publishes drafts and staff plans that were never adopted. BOTH maps close
 * on the county — 99.937% and 99.996% — which is CA-2's lesson exactly: closure is a property of
 * the REFERENCE, never an arbitration between vintages.
 *
 * 🟢 WHAT SETTLED IT, in order of weight:
 *   1. THE ARBITER — each council member's OWN page names the communities they represent. Tested
 *      against both maps at each place's TIGER interior point: **Plan A4 agrees on 17 of 18,
 *      County_Council_2023 on 15 of 18.** Plan A4 wins Cuyahoga Falls (Schmidt, D2), Boston
 *      Heights and Munroe Falls (Licate, D3). GATE 5 below re-runs this.
 *   2. The council's own "Find Your Council Member" page redirects to an ArcGIS app whose webmap
 *      (ffa2eae4ceb342e382938c3014d4b1e3) has exactly ONE operational layer: Plan A4. A second
 *      council lookup app uses the same webmap. This is CA-2's "the body's own lookup app".
 *   3. The council publishes `district-map-february-2025.pdf`; the Plan A4 layer was created
 *      2025-02-18, the same month.
 *   4. Plan A4 carries all ELEVEN members with current leadership roles (President Dickinson,
 *      Vice President Higham); the 2023 layer carries only the 8 districts and one stale email.
 *
 * 🔴 THE ONE PIECE OF EVIDENCE POINTING THE OTHER WAY IS RECORDED, NOT BURIED. Jeff Wilhite's own
 * council page says his District 4 covers **Bath Township**, and under Plan A4 Bath is District 5.
 * Under County_Council_2023 Bath is District 4, matching his page. That is the single place out of
 * eighteen where Plan A4 loses, and three other members' pages contradict the 2023 map in return.
 * The reading is that Wilhite's bio was not updated when the boundaries moved — mixed staleness
 * across bios is what a boundary change looks like. ▶ If a later session finds an instrument that
 * overturns this, District 4 vs District 5 for Akron is the thing to re-check first.
 * ⚠ And the Bath test itself needed scoping: **Ohio has three townships named "Bath"**, and a
 * join on name alone returned all three. Summit's is geo_id 3915304248.
 *
 *   node scripts/load-summit-council-boundaries.mjs --dry-run
 *   node scripts/load-summit-council-boundaries.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/140.0' };
const SERVICE =
  'https://services3.arcgis.com/3Ukh5HzAdI6WZ3KP/arcgis/rest/services/Summit_County_Council_2025/FeatureServer/0';
const MTFCC = 'X0064';
const EXPECTED = 8;
const COUNTY_GEO_ID = '39153'; // TIGER county, Summit — already in production (420.1321 sq mi)
const STATE_FIPS = '39';
const SOURCE =
  'Summit County GIS, Summit_County_Council_2025 layer 0 "Plan A4" ' +
  '(services3.arcgis.com/3Ukh5HzAdI6WZ3KP, owner Summit_Admin, created 2025-02-18, ' +
  'last edited 2026-03-02); the layer the county council\'s own "Find Your Council Member" app ' +
  'serves, matching its published district-map-february-2025.pdf; chosen over the superseded ' +
  'County_Council_2023 layer, which disagrees about Akron, by a 17-of-18 arbiter against the ' +
  "members' own published community lists; read 2026-09-24 (OH-4)";

// The eight district members, from the layer itself and from each member's own council page.
const COUNCIL_PAGE = {
  1: 'Rita Darrow', 2: 'John N. Schmidt', 3: 'David Licate', 4: 'Jeff Wilhite',
  5: 'Brandon Ford', 6: 'Christine Wiedie Higham', 7: 'Bethany McKenney', 8: 'Joseph Kacyon',
};

// GATE 5's arbiter. Each row is a community a member names on their OWN council page, paired
// with the district that member holds. `name`/`mtfcc` are how TIGER spells the place.
// 🔴 Bath is the known exception and is listed so the gate's arithmetic stays honest.
const CLAIMS = [
  [1, 'Twinsburg city', 'G4110'], [1, 'Macedonia city', 'G4110'], [1, 'Northfield village', 'G4110'],
  [1, 'Reminderville village', 'G4110'], [1, 'Richfield village', 'G4110'], [1, 'Peninsula village', 'G4110'],
  [2, 'Cuyahoga Falls city', 'G4110'],
  [3, 'Hudson city', 'G4110'], [3, 'Munroe Falls city', 'G4110'], [3, 'Silver Lake village', 'G4110'],
  [3, 'Boston Heights village', 'G4110'],
  [4, 'Bath township', 'G4040'],
  [5, 'Copley township', 'G4040'],
  [6, 'Tallmadge city', 'G4110'],
  [7, 'Barberton city', 'G4110'], [7, 'Norton city', 'G4110'], [7, 'New Franklin city', 'G4110'],
  [7, 'Clinton village', 'G4110'],
  [8, 'Green city', 'G4110'],
];
const MIN_AGREE = 17; // measured 17/18 distinct places; 15/18 for the superseded layer

const DRY = process.argv.includes('--dry-run');
const fail = (m) => { console.error(`\n🔴 ${m}`); process.exit(1); };

const r = await fetch(`${SERVICE}/query?where=PA4%3E0&outFields=PA4,Name&outSR=4326&f=geojson`, { headers: UA });
const t = await r.text();
if (!t.trim().startsWith('{')) fail(`not JSON (HTTP ${r.status}) from Summit_County_Council_2025`);
const j = JSON.parse(t);
if (j.error) fail(`ArcGIS error: ${JSON.stringify(j.error).slice(0, 160)}`);
const feats = j.features;
console.log(`Summit_County_Council_2025 (Plan A4): ${feats.length} district features`);

// ── GATE 1: the shape of the layer ───────────────────────────────────────────
if (feats.length !== EXPECTED) fail(`GATE 1: expected ${EXPECTED} districts, got ${feats.length}`);
const nums = feats.map((f) => Number(f.properties.PA4));
const sorted = [...nums].sort((a, b) => a - b);
if (new Set(nums).size !== EXPECTED || sorted[0] !== 1 || sorted[EXPECTED - 1] !== EXPECTED) {
  fail(`GATE 1: districts are not 1..${EXPECTED} exactly — got ${sorted.join(',')}`);
}
console.log(`  GATE 1 PASSED: districts ${sorted.join(',')}`);

// ── GATE 2: the layer's member names agree with the council's own pages ──────
const mism = [];
for (const f of feats) {
  const n = Number(f.properties.PA4);
  const got = String(f.properties.Name ?? '').trim();
  if (got !== COUNCIL_PAGE[n]) mism.push(`district ${n}: layer "${got}" vs council page "${COUNCIL_PAGE[n]}"`);
}
if (mism.length) fail(`GATE 2: layer and council pages disagree on ${mism.length} district(s) —\n    ${mism.join('\n    ')}`);
console.log(`  GATE 2 PASSED: all ${EXPECTED} member names match the council's own pages`);

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const q = async (sql, params = []) => (await pool.query(sql, params)).rows;

const rows = feats.map((f) => {
  const n = Number(f.properties.PA4);
  return {
    geo_id: `summit-oh-council-district-${n}`,
    name: `Summit County Council District ${n}`,
    dist: n,
    geom: JSON.stringify(f.geometry),
  };
});

// ── GATE 3: no two districts overlap ─────────────────────────────────────────
const [ov] = await q(
  `WITH d AS (SELECT r.geo_id,
                     ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)               AS raw,
                     ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS geom
                FROM jsonb_to_recordset($1::jsonb) AS r(geo_id text, name text, dist int, geom text))
   SELECT (SELECT count(*) FROM d a JOIN d b ON a.geo_id < b.geo_id
            WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 1000)::int AS pairs,
          (SELECT count(*) FROM d WHERE NOT ST_IsValid(raw))::int                  AS invalid_as_published`,
  [JSON.stringify(rows)],
);
if (ov.pairs > 0) fail(`GATE 3: ${ov.pairs} pair(s) of districts overlap by more than 1000 m² — is this one map?`);
console.log(`  GATE 3 PASSED: no two districts overlap (${ov.invalid_as_published} invalid as published)`);

// ── GATE 4: the eight districts tile the county ──────────────────────────────
// ⚠ This CANNOT date the map — the superseded layer closes at 99.937% and this one at 99.996%.
// It is a sanity bound, and GATE 5 is the arbitration. (CA-2's rule.)
const [cov] = await q(
  `WITH u AS (SELECT ST_Union(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(g), 4326))) AS geom
                FROM unnest($1::text[]) AS t(g)),
        cty AS (SELECT ST_MakeValid(geometry) AS geom FROM essentials.geofence_boundaries
                 WHERE geo_id = $2 AND mtfcc = 'G4020' AND state = $3)
   SELECT round((ST_Area(cty.geom::geography)/2589988.11)::numeric, 4) AS county_sq_mi,
          round((ST_Area(u.geom::geography)/2589988.11)::numeric, 4)   AS districts_sq_mi,
          round((100 * ST_Area(ST_Intersection(cty.geom, u.geom)::geography)
                     / ST_Area(cty.geom::geography))::numeric, 3)      AS pct_covered
     FROM u, cty`,
  [rows.map((x) => x.geom), COUNTY_GEO_ID, STATE_FIPS],
);
if (!cov) fail(`GATE 4: the TIGER county polygon ${COUNTY_GEO_ID} is not in production`);
console.log(`  county ${cov.county_sq_mi} sq mi · districts ${cov.districts_sq_mi} sq mi · ${cov.pct_covered}% covered`);
if (Number(cov.pct_covered) < 99.5) fail(`GATE 4: the eight districts cover only ${cov.pct_covered}% of Summit County`);
console.log('  GATE 4 PASSED: the districts tile the county');

// ── GATE 5: THE ARBITER — the members' own community lists ───────────────────
// 🔴 This is the gate that chooses between the two published maps. It must be scoped to Summit
// County: Ohio has THREE townships named "Bath", and a join on name alone returns all three.
const [arb] = await q(
  `WITH d AS (SELECT r.dist, ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom), 4326)) AS geom
                FROM jsonb_to_recordset($1::jsonb) AS r(geo_id text, name text, dist int, geom text)),
        cty AS (SELECT ST_MakeValid(geometry) AS geom FROM essentials.geofence_boundaries
                 WHERE geo_id = $3 AND mtfcc = 'G4020' AND state = $4),
        claims(dist, placename, mt) AS (SELECT c.dist, c.placename, c.mt
                FROM jsonb_to_recordset($2::jsonb) AS c(dist int, placename text, mt text)),
        pts AS (SELECT DISTINCT c.dist, c.placename, ST_PointOnSurface(b.geometry) AS pt
                  FROM claims c
                  JOIN essentials.geofence_boundaries b
                    ON b.name = c.placename AND b.mtfcc = c.mt AND b.state = $4
                  JOIN cty ON ST_Contains(cty.geom, ST_PointOnSurface(b.geometry)))
   SELECT count(*)::int AS tested,
          count(*) FILTER (WHERE (SELECT d.dist FROM d WHERE ST_Contains(d.geom, p.pt) LIMIT 1) = p.dist)::int AS agree
     FROM pts p`,
  [JSON.stringify(rows), JSON.stringify(CLAIMS.map(([dist, placename, mt]) => ({ dist, placename, mt }))),
   COUNTY_GEO_ID, STATE_FIPS],
);
console.log(`  arbiter: ${arb.agree}/${arb.tested} communities fall in the district whose member names them`);
if (arb.tested < CLAIMS.length - 1) fail(`GATE 5: only ${arb.tested} of ${CLAIMS.length} claim places resolved inside Summit County — the place join is broken, not the map`);
if (arb.agree < MIN_AGREE) {
  fail(`GATE 5: only ${arb.agree} of ${arb.tested} agree, expected at least ${MIN_AGREE}. ` +
       `This is the gate that chose Plan A4 over County_Council_2023 (15/18). Do NOT load — ` +
       `re-run the two-map comparison before trusting either.`);
}
console.log(`  GATE 5 PASSED: the arbiter clears ${MIN_AGREE} (Bath township is the known single miss)`);

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
     FROM jsonb_to_recordset($3::jsonb) AS r(geo_id text, name text, dist int, geom text)
   ON CONFLICT (geo_id, mtfcc) DO NOTHING
   RETURNING geo_id`,
  [MTFCC, SOURCE, JSON.stringify(rows), STATE_FIPS],
);
console.log(`\ninserted ${inserted.length} boundary row(s)`);

const [after] = await q('SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1', [MTFCC]);
if (after.n !== EXPECTED) { await q('ROLLBACK'); fail(`post-write: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED}`); }
const [valid] = await q(
  `SELECT count(*)::int AS n, count(*) FILTER (WHERE ST_IsValid(geometry))::int AS ok,
          count(DISTINCT ST_SRID(geometry))::int AS srids
     FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
  [MTFCC],
);
if (valid.ok !== EXPECTED || valid.srids !== 1) { await q('ROLLBACK'); fail(`post-write: ${valid.ok}/${valid.n} valid, ${valid.srids} SRID(s)`); }
await q('COMMIT');
console.log(`post-write: ${valid.ok}/${valid.n} valid geometries, 1 SRID — committed.`);
await pool.end();
