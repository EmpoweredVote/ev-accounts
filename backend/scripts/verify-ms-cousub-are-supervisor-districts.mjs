#!/usr/bin/env node
/**
 * verify-ms-cousub-are-supervisor-districts.mjs
 *
 * ESTABLISHES A CLAIM ABOUT MISSISSIPPI, not about one county: that TIGER's COUNTY SUBDIVISION
 * layer (MTFCC G4040) IS the county's Board of Supervisors district map, and that its `NAMELSAD`
 * ("District N") carries the real district number.
 *
 * 🔴 WHY IT NEEDS PROVING. Harrison County's own ArcGIS supervisor layer carried a `DIST_ID` that
 * was a CLEAN PERMUTATION of exactly the right five values (MS-4), which would have sent voters in
 * four of five districts to the wrong supervisor, judge, constable and election commissioner at
 * once. A field that names a district cannot be trusted because it looks right.
 *
 * 🟢 THE CONTROL IS A COUNTY WE HAVE ALREADY ANCHORED THE HARD WAY. MS-4 loaded Harrison County's
 * five supervisor districts onto X0085's predecessor X0074 and anchored them against 18 precincts
 * whose district the CERTIFIED 2023 results state, 49 of the county's own polling places, and the
 * layer's own DIST_NAME against the certified winners. Those polygons are in production and their
 * numbering is established independently of TIGER.
 *
 * So: overlap TIGER's five Harrison subdivisions against production's five Harrison supervisor
 * districts. If "District N" in TIGER is the same ground as supervisor district N in a dataset
 * anchored on certified results, the method is sound and can be applied to Hinds.
 *
 *   node scripts/verify-ms-cousub-are-supervisor-districts.mjs --shp <tl_2024_28_cousub.shp>
 *   node scripts/verify-ms-cousub-are-supervisor-districts.mjs --shp <...> --control=shuffle
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
const SHUFFLE = arg('control') === 'shuffle';
if (!SHP) {
  console.error('usage: --shp <tl_2024_28_cousub.shp>  [--control=shuffle]');
  process.exit(2);
}

const CONTROL_COUNTY = '047'; // Harrison — anchored by MS-4 against certified results
const CONTROL_MTFCC = 'X0074';

const src = await shapefile.open(SHP.replace(/\.shp$/, '.shp'), SHP.replace(/\.shp$/, '.dbf'));
const byCounty = new Map();
let total = 0;
for (;;) {
  const { done, value } = await src.read();
  if (done) break;
  total++;
  const p = value.properties;
  if (p.STATEFP !== '28') continue;
  const m = String(p.NAMELSAD || '').match(/^District (\d+)$/);
  if (!m) continue;
  if (!byCounty.has(p.COUNTYFP)) byCounty.set(p.COUNTYFP, []);
  byCounty.get(p.COUNTYFP).push({ n: Number(m[1]), geoid: p.GEOID, geom: value.geometry });
}
console.log(`shapefile records: ${total}; MS counties with "District N" subdivisions: ${byCounty.size}`);

// 🔴 A UNIFORM ANSWER IS A BROKEN DETECTOR. If every county had five, that could be the parser
// defaulting. Report the distribution instead of asserting a number.
const sizes = {};
for (const [, v] of byCounty) sizes[v.length] = (sizes[v.length] || 0) + 1;
console.log('subdivisions per county:', JSON.stringify(sizes));

let ctl = byCounty.get(CONTROL_COUNTY);
if (!ctl || ctl.length !== 5) {
  console.error(`🔴 Harrison County (28${CONTROL_COUNTY}) has ${ctl ? ctl.length : 0} "District N" subdivisions, expected 5`);
  process.exit(1);
}
ctl = ctl.slice().sort((a, b) => a.n - b.n);
if (SHUFFLE) {
  const nums = ctl.map((c) => c.n);
  ctl = ctl.map((c, i) => ({ ...c, n: nums[(i + 1) % nums.length] }));
  console.log(`🔬 CONTROL shuffle: TIGER district numbers rotated -> ${ctl.map((c) => c.n).join(',')}`);
}

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

const { rows: prod } = await client.query(
  `SELECT geo_id, name FROM essentials.geofence_boundaries WHERE mtfcc = $1 ORDER BY geo_id`,
  [CONTROL_MTFCC],
);
if (prod.length !== 5) {
  console.error(`🔴 production holds ${prod.length} ${CONTROL_MTFCC} rows, expected Harrison's 5`);
  process.exit(1);
}
const prodNum = (r) => {
  const m = `${r.geo_id} ${r.name}`.match(/(\d)\s*$/) || `${r.geo_id} ${r.name}`.match(/district[^0-9]*(\d)/i);
  return m ? Number(m[1]) : null;
};
console.log(`\nproduction ${CONTROL_MTFCC} rows: ${prod.map((r) => `${r.geo_id}=${prodNum(r)}`).join(', ')}`);

console.log('\n% of each TIGER subdivision covered by each production supervisor district');
console.log('TIGER \\ prod' + prod.map((r) => String(prodNum(r)).padStart(7)).join(''));
let diag = 0;
for (const c of ctl.slice().sort((a, b) => a.n - b.n)) {
  const self = await client.query('SELECT public.ST_Area(public.ST_GeomFromGeoJSON($1)::geography) AS a', [
    JSON.stringify(c.geom),
  ]);
  const cells = [];
  let best = { n: null, v: -1 };
  for (const r of prod) {
    const q = await client.query(
      `SELECT public.ST_Area(public.ST_Intersection(
         public.ST_MakeValid(public.ST_GeomFromGeoJSON($1)),
         public.ST_MakeValid(b.geometry))::geography) AS a
         FROM essentials.geofence_boundaries b WHERE b.mtfcc = $2 AND b.geo_id = $3`,
      [JSON.stringify(c.geom), CONTROL_MTFCC, r.geo_id],
    );
    const pct = (Number(q.rows[0].a) / Number(self.rows[0].a)) * 100;
    cells.push(pct.toFixed(1).padStart(7));
    if (pct > best.v) best = { n: prodNum(r), v: pct };
  }
  const ok = best.n === c.n;
  if (ok) diag++;
  console.log(`District ${c.n} ${cells.join('')}   -> strongest prod district ${best.n}${ok ? ' ✅' : ' 🔴'}`);
}
await client.end();

console.log(`\ndiagonal strongest for ${diag}/5`);
if (SHUFFLE) {
  console.log('🔬 SHUFFLE control — a high number here would mean the test cannot discriminate.');
  process.exit(diag === 5 ? 1 : 0);
}
if (diag !== 5) {
  console.error('🔴 TIGER "District N" does NOT match the independently anchored Harrison numbering.');
  process.exit(1);
}
console.log('✅ TIGER COUSUB "District N" IS the Mississippi supervisor district, number and all,');
console.log('   checked against a county anchored on certified election results.');
