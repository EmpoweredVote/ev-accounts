/**
 * Cross-plan numbering check for Jackson's wards.
 *
 * A city ward redraw MOVES boundaries; it does not renumber the wards. So new Ward N and
 * old Ward N must occupy substantially the same part of the city. If the NEW layer's
 * `Ward` attribute were a permutation (the Harrison County DIST_ID defect), the overlap
 * matrix would be strongest OFF the diagonal, and it would say exactly which permutation.
 *
 * The two layers are independent artefacts: the old one is the 2013 plan published in
 * 2023 and never re-labelled, the new one is the 2024 plan.
 *
 * Areas are computed by PostGIS on geography, read-only — no table is created or written.
 */
import * as fs from 'fs';
import { Client } from 'pg';

const argv = process.argv.slice(2);
const arg = (k) => {
  const hit = argv.find((a) => a.startsWith(`--${k}=`));
  if (hit) return hit.slice(k.length + 3);
  const i = argv.indexOf(`--${k}`);
  return i >= 0 ? argv[i + 1] : undefined;
};
const NEW = arg('new');
const OLD = arg('old');
if (!NEW || !OLD) {
  console.error('usage: verify-jackson-ward-numbering.mjs --new <2024.geojson> --old <2013.geojson>');
  console.error('  both are dumps of the city\'s own ArcGIS layers, fetched with outSR=4326.');
  process.exit(2);
}
const neu = JSON.parse(fs.readFileSync(NEW, 'utf8'));
const old = JSON.parse(fs.readFileSync(OLD, 'utf8'));

let nw = neu.features.map((f) => ({ n: Number(f.properties.Ward), g: JSON.stringify(f.geometry) }));
const ow = old.features.map((f) => ({ n: Number(f.properties.Ward_), g: JSON.stringify(f.geometry) }));
console.log('new wards:', nw.map((w) => w.n).sort((a, b) => a - b).join(','));
console.log('old wards:', ow.map((w) => w.n).sort((a, b) => a - b).join(','));

// 🔬 CONTROL. Rotating the labels on the NEW polygons is exactly the Harrison County
// DIST_ID defect: a clean permutation of the right seven values. The matrix must go red
// for every ward. A check that has only ever passed proves nothing, so run this first.
if (arg('control') === 'shuffle') {
  const nums = nw.map((w) => w.n);
  nw = nw.map((w, i) => ({ ...w, n: nums[(i + 1) % nums.length] }));
  console.log(`🔬 CONTROL shuffle: new ward labels rotated -> ${nw.map((w) => w.n).join(',')}`);
}

const c = new Client({ connectionString: process.env.DATABASE_URL });
await c.connect();

// CONTROL: the comparison must be able to report "no overlap at all".
const ctl = await c.query(
  `SELECT ST_Area(ST_Intersection(ST_GeomFromGeoJSON($1), ST_Buffer(ST_SetSRID(ST_Point(-89.09,30.37),4326),0.01))::geography) AS a`,
  [nw[0].g],
);
console.log(`CONTROL new Ward ${nw[0].n} vs a disc over Gulfport -> area ${Number(ctl.rows[0].a).toFixed(1)} m² (must be 0)`);

const area = {};
for (const w of nw) {
  const r = await c.query(`SELECT ST_Area(ST_GeomFromGeoJSON($1)::geography) AS a`, [w.g]);
  area[w.n] = Number(r.rows[0].a);
}

console.log('\n% of each NEW ward covered by each OLD ward');
console.log('new \\ old' + ow.map((o) => o.n).sort((a, b) => a - b).map((n) => String(n).padStart(7)).join(''));
let diag = 0;
for (const w of nw.sort((a, b) => a.n - b.n)) {
  const cells = [];
  let best = { n: null, v: -1 };
  for (const o of ow.slice().sort((a, b) => a.n - b.n)) {
    const r = await c.query(
      `SELECT ST_Area(ST_Intersection(ST_MakeValid(ST_GeomFromGeoJSON($1)), ST_MakeValid(ST_GeomFromGeoJSON($2)))::geography) AS a`,
      [w.g, o.g],
    );
    const pct = (Number(r.rows[0].a) / area[w.n]) * 100;
    cells.push(pct.toFixed(1).padStart(7));
    if (pct > best.v) best = { n: o.n, v: pct };
  }
  const ok = best.n === w.n;
  if (ok) diag++;
  console.log(`Ward ${w.n}  ${cells.join('')}   -> strongest old ward ${best.n} ${ok ? '✅' : '🔴 MISMATCH'}`);
}
console.log(`\ndiagonal strongest for ${diag}/7 wards`);
console.log(diag === 7
  ? '✅ the new layer numbers its wards the same way the previous plan did.'
  : '🔴 the numbering does not carry across the two plans — read the rows before loading.');
await c.end();
