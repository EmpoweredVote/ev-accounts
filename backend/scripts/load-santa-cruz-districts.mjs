#!/usr/bin/env node
/**
 * load-santa-cruz-districts.mjs — Santa Cruz CA deep seed, stage 1 geography.
 *
 * Fetches TWO district layers and inserts them into essentials.geofence_boundaries:
 *
 *   X0089  santa-cruz-ca-council-district-1..6              (City of Santa Cruz)
 *   X0090  santa-cruz-county-ca-supervisorial-district-1..5 (Santa Cruz County)
 *
 * Writes ONLY to essentials.geofence_boundaries. The structure migration (CC_0404) creates
 * the districts and their offices and REFUSES TO RUN if these boundaries are absent — an
 * office on a district with no polygon is unreachable by any address, and NOTHING ERRORS.
 *
 *   node scripts/load-santa-cruz-districts.mjs --dry-run
 *   node scripts/load-santa-cruz-districts.mjs --control=scramble   (gate 4 must FAIL twice)
 *   node scripts/load-santa-cruz-districts.mjs
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THE CITY LAYER RETURNS **SEVEN ROWS FOR SIX DISTRICTS**. DISTRICT 6 IS TWO POLYGONS.
 *
 *   OBJECTID_1=6  District 6  4,163 vertices  1,773.53 acres  centroid 36.95967,-122.05148
 *   OBJECTID_1=7  District 6     36 vertices     98.24 acres  centroid 36.97471,-122.10509
 *
 * The second is the detached west-side parcel out by the Coastal Science Campus. A loader
 * that treats rows as districts gives Santa Cruz a PHANTOM SEVENTH COUNCIL DISTRICT, and
 * nothing downstream errors — the office count gate in CC_0404 would pass, the roster would
 * have six people for seven districts, and one polygon would route voters to nobody. So this
 * script DISSOLVES ON THE `District` ATTRIBUTE before anything else looks at the data, and
 * GATE 1 asserts both numbers: 7 raw parts in, 6 districts out.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴 THE CITY LAYER'S `NameCouncil` COLUMN CARRIES A STALE TITLE. GEOMETRY IS TAKEN FROM IT;
 *    OCCUPANCY AND TITLES ARE NOT.
 *
 * Its District 6 rows read "Vice Mayor Renee Golder". Golder holds District 6, but the Vice
 * Mayor for this term is Shebreh Kalantari-Johnson of District 3 (santacruzca.gov Meet the
 * Mayor and City Council, read 2026-11-11). Vice Mayor is a title the Council rotates; a
 * boundary layer records whoever held it when the layer was last touched. The Marin lesson
 * repeating: a name field dates the ROSTER, never the BOUNDARY.
 *
 * ⚖ Its `TermEnd` column is a different matter and IS used here, as a cross-check only. All
 *   six values match the council page independently — which is how the off-by-one trap on
 *   that page (the "Term Expires" line is the last child of the PREVIOUS member's <article>)
 *   was caught. GATE 5 re-runs that comparison so a future reader sees it fail if either side
 *   moves. It gates nothing; it prints.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * THE ARBITER IS THE COUNTY'S OWN PRECINCT LAYER, AND IT ADJUDICATES BOTH MAPS AT ONCE.
 *
 * Santa Cruz County's Elections Department builds ballots from precincts, so that layer is
 * the authority on where a district line actually runs (the Columbus arbiter rule). Unlike
 * Marin's subprecincts it needs no numbering trick: every precinct carries its districts as
 * ATTRIBUTES, including both of the ones this script loads.
 *
 *   Precincts                  lastEditDate 2026-06-23   (built for the June 2 2026 primary)
 *   County Supervisor Districts lastEditDate 2026-10-21
 *   City Council Districts      MapServer layer, no editingInfo published
 *
 *   SUPDIST     692 precincts  "Supervisorial District 1".."5"
 *   SCCC         97 precincts  "Santa Cruz City Council District 1".."6"  (n/a elsewhere)
 *   CITYLIMITS   97 precincts  "City of Santa Cruz"  — matches the SCCC count exactly
 *
 * GATE 4A: every precinct's interior point must land in the supervisorial district its own
 * SUPDIST says it votes in. GATE 4B: the same for the 97 city precincts against SCCC. This is
 * what a wrong-vintage map cannot survive — redistricting renumbers precincts, so a 2026
 * ballot layer read against a superseded district map disagrees in bulk.
 *
 * GATE 4-CONTROL (`--control=scramble`) swaps two districts' geometry in EACH set and
 * requires BOTH halves of gate 4 to fail. A gate that cannot tell the real map from a
 * scrambled one is not a gate.
 *
 * ⚠ The city council layer publishes NO vintage of its own (MapServer layers carry no
 *   editingInfo, and its `description` and `copyrightText` are both empty). Its vintage is
 *   therefore established ONLY by GATE 4B — against a ballot layer the county rebuilt for the
 *   June 2026 primary. That is the stronger evidence anyway, but it is the only evidence, so
 *   do not weaken gate 4B.
 */
import pg from 'pg';

const DRY = process.argv.includes('--dry-run');
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';

const STATE_FIPS = '06';
const CC_MTFCC = 'X0089';
const SUP_MTFCC = 'X0090';
const CITY_GEOID = '0669112';
const CITY_MTFCC = 'G4110';
const COUNTY_GEOID = '06087';
const COUNTY_MTFCC = 'G4020';

const CC_URL =
  'https://vwgisportal2.santacruzca.gov/arcgis/rest/services/Basemap/MapServer/22';
const SUP_URL =
  'https://services1.arcgis.com/jJfZghspGKh8J9Jm/arcgis/rest/services/County_Supervisor_Districts/FeatureServer/18';
const PREC_URL =
  'https://services1.arcgis.com/jJfZghspGKh8J9Jm/arcgis/rest/services/Precincts/FeatureServer/4';

const CC_SOURCE =
  'City of Santa Cruz GIS — Basemap/MapServer layer 22 "Council Districts" ' +
  '(vwgisportal2.santacruzca.gov), read 2026-11-11. District 6 is published as TWO polygons ' +
  '(1,773.53 + 98.24 acres) and is dissolved on the District attribute before loading. ' +
  'Vintage proved against the County Precincts layer (lastEditDate 2026-06-23) via its SCCC ' +
  'column, 97 of 97 city precincts agreeing. Geometry only: the layer’s NameCouncil column ' +
  'carries a stale Vice Mayor title and is not read.';
const SUP_SOURCE =
  'County of Santa Cruz open data — County_Supervisor_Districts FeatureServer layer 18 ' +
  '(services1.arcgis.com/jJfZghspGKh8J9Jm), copyrightText "County of Santa Cruz", ' +
  'lastEditDate 2026-10-21. Vintage proved against the County Precincts layer ' +
  '(lastEditDate 2026-06-23) via its SUPDIST column, 692 of 692 precincts agreeing. ' +
  'Its SName and District columns are blank (" ") and are not read; the district number ' +
  'comes from Super_Dist ("SUPER-N").';

const lit = (s) => `'${String(s).replace(/'/g, "''")}'`;
const fail = (msg) => {
  console.error(`\n❌ ${msg}`);
  process.exitCode = 1;
};

async function getJson(url, what) {
  const res = await fetch(url, { signal: AbortSignal.timeout(180_000) });
  if (!res.ok) throw new Error(`${what}: HTTP ${res.status} for ${url}`);
  return res.json();
}
const qs = (o) => Object.entries(o).map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join('&');

// ── Fetch ────────────────────────────────────────────────────────────────────
console.log('Fetching the two Santa Cruz district layers and the precinct arbiter...');

const ccRaw = await getJson(
  `${CC_URL}/query?${qs({
    where: '1=1',
    outFields: 'OBJECTID_1,District,NAME,TermEnd,NameCouncil',
    returnGeometry: 'true', outSR: '4326', f: 'geojson',
  })}`,
  'city council districts',
);
const supRaw = await getJson(
  `${SUP_URL}/query?${qs({
    where: '1=1', outFields: 'Super_Dist,NAME',
    returnGeometry: 'true', outSR: '4326', f: 'geojson',
  })}`,
  'county supervisorial districts',
);
const precRaw = await getJson(
  `${PREC_URL}/query?${qs({
    where: '1=1', outFields: 'Precinct,CITYLIMITS,SUPDIST,SCCC',
    returnGeometry: 'true', outSR: '4326', f: 'geojson',
  })}`,
  'precincts',
);

// 🔴 The ONLY place row count and district count are allowed to differ. `num` is parsed from
//    the attribute, never from the row's position or its OBJECTID.
const ccParts = (ccRaw.features || []).map((f) => ({
  num: Number(f.properties.District),
  termEnd: String(f.properties.TermEnd ?? '').trim(),
  geom: f.geometry,
}));
const supParts = (supRaw.features || []).map((f) => ({
  num: Number(String(f.properties.Super_Dist ?? '').replace(/^SUPER-/, '')),
  geom: f.geometry,
}));
const supdistNum = (s) => {
  const m = /Supervisorial District (\d+)/.exec(String(s ?? ''));
  return m ? Number(m[1]) : null;
};
const scccNum = (s) => {
  const m = /Santa Cruz City Council District (\d+)/.exec(String(s ?? ''));
  return m ? Number(m[1]) : null;
};
const precincts = (precRaw.features || []).map((f) => ({
  prec: String(f.properties.Precinct ?? ''),
  city: String(f.properties.CITYLIMITS ?? ''),
  sup: supdistNum(f.properties.SUPDIST),
  cc: scccNum(f.properties.SCCC),
  geom: f.geometry,
}));
const cityPrecincts = precincts.filter((p) => p.cc !== null);

console.log(`  city council parts=${ccParts.length}  supervisorial=${supParts.length}  ` +
            `precincts=${precincts.length} (${cityPrecincts.length} with a council district)`);

// ⚠ CITYLIMITS and SCCC must agree on which precincts are in the city. If they stop agreeing,
//   one of the two columns has been re-cut and the city half of gate 4 is measuring the wrong
//   set — report it loudly rather than quietly testing 90 of 97.
const inCityLimits = precincts.filter((p) => /City of Santa Cruz/i.test(p.city)).length;
if (inCityLimits !== cityPrecincts.length) {
  fail(`PRE-FLIGHT: ${inCityLimits} precincts say CITYLIMITS="City of Santa Cruz" but ` +
       `${cityPrecincts.length} carry an SCCC council district. The two columns disagree.`);
}

if (CONTROL === 'scramble') {
  const swap = (arr, a, b) => {
    const x = arr.find((d) => d.num === a);
    const y = arr.find((d) => d.num === b);
    const t = x.geom; x.geom = y.geom; y.geom = t;
  };
  // District 6 is the split one; swapping 1 and 3 keeps the dissolve honest while still
  // guaranteeing gate 4 has something to catch.
  swap(ccParts, 1, 3);
  swap(supParts, 1, 3);
  console.log('  ⚠ --control=scramble: districts 1 and 3 swapped in BOTH sets. ' +
              'GATE 4A AND GATE 4B MUST BOTH FAIL.');
}

// ── Connect ──────────────────────────────────────────────────────────────────
// ⚠ A pooled connection ignores libpq startup `options`, so the timeout is raised as a
//   statement on one dedicated client. The arbiter intersects 692 precincts against 5
//   districts, one of which (D5, San Lorenzo Valley) is a large polygon.
const db = new pg.Client({ connectionString: process.env.DATABASE_URL });
await db.connect();
await db.query("SET statement_timeout = '600s'");
const q = async (sql, params = []) => (await db.query(sql, params)).rows;

const ccJson = JSON.stringify(ccParts.map((d) => ({ num: d.num, geom: d.geom })));
const supJson = JSON.stringify(supParts.map((d) => ({ num: d.num, geom: d.geom })));
const precJson = JSON.stringify(
  precincts.map((p) => ({ prec: p.prec, sup: p.sup, cc: p.cc, geom: p.geom })),
);

// The dissolve lives here, once, and every gate reads the dissolved CTE.
const PARTS = `
  SELECT r.num,
         ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(r.geom #>> '{}'), 4326)) AS geom
    FROM jsonb_to_recordset($1::jsonb) AS r(num int, geom jsonb)`;
const DISSOLVED = `
  SELECT num, ST_Multi(ST_UnaryUnion(ST_Collect(geom))) AS geom
    FROM (${PARTS}) p GROUP BY num`;
const PRECS = `
  SELECT x.prec, x.sup, x.cc,
         ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(x.geom #>> '{}'), 4326)) AS geom
    FROM jsonb_to_recordset($2::jsonb) AS x(prec text, sup int, cc int, geom jsonb)`;

// ── GATE 1: the right number of districts, numbered without gaps ─────────────
console.log('\nGATE 1 — districts present, dissolved and numbered');
async function gate1(label, json, parts, expected) {
  const rows = await q(
    `WITH d AS (${DISSOLVED})
     SELECT num, round((ST_Area(geom::geography)/2589988.11)::numeric, 3) AS sq_mi,
            ST_NumGeometries(geom)::int AS parts FROM d ORDER BY num`,
    [json],
  );
  console.log(`  ${label}: ${parts.length} raw row(s) in → ${rows.length} district(s) out`);
  for (const r of rows) {
    console.log(`    District ${r.num}: ${r.sq_mi} sq mi` +
                (r.parts > 1 ? `  (${r.parts} disjoint parts)` : ''));
  }
  const nums = rows.map((r) => Number(r.num)).sort((a, b) => a - b);
  const want = Array.from({ length: expected }, (_, i) => i + 1).join(',');
  if (rows.length !== expected || nums.join(',') !== want) {
    fail(`GATE 1 (${label}): expected districts 1-${expected}, got [${nums.join(',')}]`);
  }
  if (parts.some((p) => !Number.isInteger(p.num) || p.num < 1 || p.num > expected)) {
    fail(`GATE 1 (${label}): a raw row carries a district number outside 1-${expected} — ` +
         'the attribute did not parse');
  }
  return rows;
}
const ccRows = await gate1('city council', ccJson, ccParts, 6);
const supRows = await gate1('supervisorial', supJson, supParts, 5);

// 🔴 The split-district assertion, stated as a number rather than a comment. If the city ever
//    merges its two District 6 polygons upstream this fails loudly and a human re-reads the
//    layer — which is the right outcome, because the dissolve would then be hiding nothing.
if (ccParts.length !== 7) {
  fail(`GATE 1: the city layer returned ${ccParts.length} rows, not the 7 this script was ` +
       'written against (District 6 published as two polygons). Re-read the layer before loading.');
}
const d6parts = Number((ccRows.find((r) => Number(r.num) === 6) || {}).parts || 0);
if (d6parts !== 2) {
  fail(`GATE 1: District 6 dissolved to ${d6parts} part(s); 2 were expected ` +
       '(main body plus the detached Coastal Science Campus parcel).');
}

// ── GATE 2: districts within a set do not overlap each other ─────────────────
console.log('\nGATE 2 — overlapping pairs (>0.1 km²)');
for (const [label, json] of [['city council', ccJson], ['supervisorial', supJson]]) {
  const r = await q(
    `WITH d AS (${DISSOLVED})
     SELECT count(*)::int AS pairs FROM d a JOIN d b ON a.num < b.num
      WHERE ST_Area(ST_Intersection(a.geom, b.geom)::geography) > 100000`,
    [json],
  );
  console.log(`  ${label}: ${r[0].pairs}`);
  if (r[0].pairs !== 0) fail(`GATE 2 (${label}): ${r[0].pairs} district pair(s) overlap`);
}

// ── GATE 3A: the districts claim the ground their own BALLOT LAYER votes ─────
//
// 🔴 A PERCENTAGE-OF-TIGER-POLYGON GATE ASKS THE WRONG QUESTION HERE, TWICE OVER.
//
// First, Santa Cruz is COASTAL and both TIGER polygons reach far into Monterey Bay — measured
// 2026-11-11, the county's districts cover 73.3% of place 06087/G4020 and the city's cover
// 79.9% of place 0669112/G4110, and both numbers are almost exactly (100% − water):
//
//   county  TIGER 607.17 sq mi = ALAND 445.11 + AWATER 162.06;  uncovered 419.74 km² vs
//           AWATER 419.72 km², one dominant piece of 416.06 km² at 36.9635,-122.1660 (the bay)
//   city    TIGER  15.83 sq mi = ALAND  12.74 + AWATER   3.09;  uncovered 8.22 km² vs
//           AWATER 8.00 km², dominant piece 7.94 km² at 36.9540,-122.0137 (the bay)
//
// Second — and this is the part a water correction alone would still get wrong — THE TIGER
// PLACE POLYGON AND THE CITY'S OWN LIMITS DISAGREE ON LAND. Two land pieces inside place
// 0669112 are claimed by no council district: 0.19475 km² at 36.9921,-122.0697 and 0.02322 km²
// at 37.0018,-122.0410. The second sits in precinct 50521, which the county marks
// CITYLIMITS="n/a" — the county does not put it in the city at all. Of the first, only
// 0.018 km² falls inside any city precinct.
//
// So the question that matters is not "do the districts fill a Census polygon" but "could a
// CITY VOTER live on ground that resolves to no council seat". The county's precinct layer is
// what ballots are built from, so it answers that directly: take the precincts, subtract the
// districts, and look at the remainder.
//
//   city     97 precincts, 32.4520 km²  →  99.868% claimed, 0.0430 km² left over
//   worst single precinct 31600 at 97.685%; the rest are shared lines digitised twice
//
// This gate also still catches a MISSING district, harder than the polygon version did: drop
// one and a fifth to a sixth of the precinct area goes unclaimed at once.
console.log('\nGATE 3A — do the districts claim the ground their own ballot layer votes?');
async function gate3a(label, json, filterSql, floor) {
  const r = await q(
    `WITH d AS (${DISSOLVED}),
          u AS (SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM d),
          s AS (SELECT geom FROM (${PRECS}) z WHERE ${filterSql}),
          su AS (SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM s)
     SELECT (SELECT count(*)::int FROM s) AS n,
            round((ST_Area(su.geom::geography)/1e6)::numeric, 4) AS precinct_km2,
            round((100 * ST_Area(ST_Intersection(su.geom, u.geom)::geography)
                       / NULLIF(ST_Area(su.geom::geography), 0))::numeric, 4) AS pct,
            round((ST_Area(ST_Difference(su.geom, u.geom)::geography)/1e6)::numeric, 4)
              AS unclaimed_km2
       FROM u, su`,
    [json, precJson],
  );
  const x = r[0];
  console.log(`  ${label}: ${x.n} precincts, ${x.precinct_km2} km² — ${x.pct}% claimed, ` +
              `${x.unclaimed_km2} km² unclaimed`);
  if (Number(x.pct) < floor) {
    fail(`GATE 3A (${label}): only ${x.pct}% of the precinct area is claimed by a district ` +
         `(floor ${floor}%) — a voter could resolve to no seat`);
  }
}
await gate3a('supervisorial', supJson, 'z.sup IS NOT NULL', 99.0);
await gate3a('city council', ccJson, 'z.cc IS NOT NULL', 99.0);

// ── GATE 3B: reconcile against Census land area ──────────────────────────────
//
// The second half of the Anchorage test, kept because it is the one that would catch a
// district layer that quietly lost territory to a re-digitised shoreline. Constants are
// TIGERweb tigerWMS_Current, read 2026-11-11 — authoritative values, not measurements of our
// own polygons. Both reconcile to the stored polygon exactly (ALAND + AWATER = polygon area).
const CENSUS = {
  county: { aland_m2: 1_152_818_024, awater_m2: 419_720_239, floor_pct: 99.9 },
  // ⚠ 98% rather than 99.9% for the city, for the land disagreement described above and for
  //   no other reason. The measured figure is 99.312%. The smallest council district is
  //   3.23 km², 9.8% of the city's land, so a dropped district lands near 89% and still fails.
  city: { aland_m2: 32_998_564, awater_m2: 7_998_698, floor_pct: 98.0 },
};
console.log('\nGATE 3B — reconcile the covered ground against Census land area');
async function gate3b(label, json, geoId, mtfcc, c) {
  const r = await q(
    `WITH d AS (${DISSOLVED}),
          u AS (SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM d),
          p AS (SELECT geometry AS geom FROM essentials.geofence_boundaries
                 WHERE geo_id = $2 AND mtfcc = $3)
     SELECT round((ST_Area(ST_Intersection(u.geom, p.geom)::geography))::numeric, 0) AS covered_m2,
            round((ST_Area(ST_Difference(p.geom, u.geom)::geography))::numeric, 0) AS uncovered_m2,
            round((ST_Area(ST_Difference(u.geom, p.geom)::geography))::numeric, 0) AS outside_m2
       FROM u, p`,
    [json, geoId, mtfcc],
  );
  if (!r.length || r[0].covered_m2 === null) {
    fail(`GATE 3B (${label}): the parent polygon ${geoId}/${mtfcc} is missing from ` +
         'essentials.geofence_boundaries');
    return;
  }
  const covered = Number(r[0].covered_m2);
  const pct = (100 * covered) / c.aland_m2;
  console.log(`  ${label}: covered ${(covered / 1e6).toFixed(3)} km² = ${pct.toFixed(3)}% of ` +
              `census land ${(c.aland_m2 / 1e6).toFixed(3)} km²; uncovered inside the polygon ` +
              `${(Number(r[0].uncovered_m2) / 1e6).toFixed(3)} km² vs census water ` +
              `${(c.awater_m2 / 1e6).toFixed(3)} km²; outside the polygon ` +
              `${(Number(r[0].outside_m2) / 1e6).toFixed(3)} km²`);
  if (pct < c.floor_pct) {
    fail(`GATE 3B (${label}): the districts cover ${pct.toFixed(3)}% of the census land area ` +
         `(floor ${c.floor_pct}%). Inhabited ground may sit outside every district.`);
  }
  // The uncovered ground is supposed to BE the water. If it grows past it, the shoreline has
  // been redrawn or a district has shrunk, and either way a human should look.
  const ceiling = c.awater_m2 * 1.1;
  if (Number(r[0].uncovered_m2) > ceiling) {
    fail(`GATE 3B (${label}): ${(Number(r[0].uncovered_m2) / 1e6).toFixed(3)} km² of the parent ` +
         `polygon is uncovered, more than 110% of its census water area ` +
         `(${(c.awater_m2 / 1e6).toFixed(3)} km²). That is more than the bay can explain.`);
  }
}
await gate3b('supervisorial', supJson, COUNTY_GEOID, COUNTY_MTFCC, CENSUS.county);
await gate3b('city council', ccJson, CITY_GEOID, CITY_MTFCC, CENSUS.city);

// ── GATE 4: THE ARBITER — the ballot layer's own district attributes ─────────
console.log('\nGATE 4 — the arbiter: does each precinct sit in the district its BALLOT says?');
async function gate4(label, json, col, filterSql) {
  const rows = await q(
    `WITH d AS (${DISSOLVED}),
          s AS (SELECT prec, ${col} AS claim, ST_PointOnSurface(geom) AS pt
                  FROM (${PRECS}) z WHERE ${filterSql})
     SELECT count(*)::int AS total,
            count(*) FILTER (WHERE found IS NOT DISTINCT FROM claim)::int AS agree,
            count(*) FILTER (WHERE found IS DISTINCT FROM claim)::int AS disagree
       FROM (SELECT s.prec, s.claim,
                    (SELECT d.num FROM d WHERE ST_Contains(d.geom, s.pt) LIMIT 1) AS found
               FROM s) t`,
    [json, precJson],
  );
  const r = rows[0];
  console.log(`  ${label}: tested ${r.total}, agree ${r.agree}, DISAGREE ${r.disagree}`);
  if (r.total === 0) {
    fail(`GATE 4 (${label}): zero precincts tested — the arbiter returned nothing, so this ` +
         'gate proved nothing');
    return;
  }
  if (r.disagree > 0) {
    const bad = await q(
      `WITH d AS (${DISSOLVED}),
            s AS (SELECT prec, ${col} AS claim, ST_PointOnSurface(geom) AS pt
                    FROM (${PRECS}) z WHERE ${filterSql})
       SELECT prec, claim, found FROM (
         SELECT s.prec, s.claim,
                (SELECT d.num FROM d WHERE ST_Contains(d.geom, s.pt) LIMIT 1) AS found
           FROM s) t
        WHERE found IS DISTINCT FROM claim ORDER BY prec LIMIT 12`,
      [json, precJson],
    );
    for (const b of bad) {
      console.log(`    precinct ${b.prec}: ballot says D${b.claim}, polygon says ` +
                  `D${b.found ?? 'NONE'}`);
    }
    fail(`GATE 4 (${label}): ${r.disagree} precinct(s) sit outside the district their own ` +
         'ballot attribute claims — the district map and the ballot map disagree. ' +
         'Do NOT load this layer.');
  }
}
await gate4('supervisorial vs SUPDIST', supJson, 'sup', 'z.sup IS NOT NULL');
await gate4('city council vs SCCC', ccJson, 'cc', 'z.cc IS NOT NULL');

// ── GATE 5 (prints, does not gate): the term cross-check ────────────────────
//
// The council roster page's "Term Expires" line is the LAST child of each member's own
// <article>, so reading that page linearly misassigns every term by one. The city's own GIS
// layer carries TermEnd independently. These are the values that agreed on 2026-11-11.
const EXPECTED_TERMS = {
  1: 'December 2028', 2: 'December 2028', 3: 'December 2028',
  4: 'December 2026', 5: 'December 2028', 6: 'December 2026',
};
console.log('\nGATE 5 (diagnostic) — TermEnd on the boundary layer vs the roster read 2026-11-11');
let termDrift = 0;
for (const num of Object.keys(EXPECTED_TERMS).map(Number).sort((a, b) => a - b)) {
  const got = (ccParts.find((p) => p.num === num) || {}).termEnd || '(none)';
  const want = EXPECTED_TERMS[num];
  const ok = got === want;
  if (!ok) termDrift += 1;
  console.log(`  District ${num}: layer "${got}"  roster "${want}"  ${ok ? 'agree' : '⚠ DRIFT'}`);
}
if (termDrift > 0) {
  console.log(`  ⚠ ${termDrift} district(s) drifted. This does not block the load — geometry is ` +
              'what is being loaded — but the roster migration should be re-read before it runs.');
}

// ── Control / dry-run / write ────────────────────────────────────────────────
if (CONTROL === 'scramble') {
  const failed = process.exitCode === 1;
  console.log('\n--control=scramble summary: GATE 4 ' +
    (failed ? '✅ FAILED as required — the gate can tell a wrong map from the right one.'
            : '❌ PASSED on a scrambled map — THE GATE IS VACUOUS.'));
  await db.end();
  process.exit(failed ? 0 : 1);
}

if (process.exitCode === 1) {
  console.error('\nGates failed; nothing written.');
  await db.end();
  process.exit(1);
}

if (DRY) {
  console.log('\n--dry-run: all gates passed, nothing written.');
  await db.end();
  process.exit(0);
}

async function load(label, json, mtfcc, geoIdPrefix, namePrefix, source) {
  const before = await q(
    `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1`, [mtfcc]);
  await q(
    `WITH d AS (${DISSOLVED})
     INSERT INTO essentials.geofence_boundaries
            (geo_id, name, state, mtfcc, geometry, source, imported_at)
     SELECT ${lit(geoIdPrefix)} || d.num, ${lit(namePrefix)} || d.num,
            ${lit(STATE_FIPS)}, ${lit(mtfcc)}, d.geom, ${lit(source)}, now()
       FROM d
     ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
    [json],
  );
  const after = await q(
    `SELECT geo_id, name, round((ST_Area(geometry::geography)/2589988.11)::numeric,3) AS sq_mi
       FROM essentials.geofence_boundaries WHERE mtfcc = $1 ORDER BY geo_id`, [mtfcc]);
  console.log(`\nLoaded ${mtfcc} (${label}): ${before[0].n} rows before, ${after.length} after`);
  for (const r of after) console.log(`  ${r.geo_id}  ${r.sq_mi} sq mi  ${r.name}`);
}

await load('city council', ccJson, CC_MTFCC,
           'santa-cruz-ca-council-district-', 'Santa Cruz City Council District ', CC_SOURCE);
await load('supervisorial', supJson, SUP_MTFCC,
           'santa-cruz-county-ca-supervisorial-district-',
           'Santa Cruz County Supervisorial District ', SUP_SOURCE);

await db.end();
