// Controls on CC_0372-nm-pec-geofences.mjs. Each tamper is asserted PRESENT before it is run.
// ⚠ Read the message each one produces, never the exit code: CC_0370 had a control that failed
//   for the wrong reason and one that fired on an earlier gate than the one under test.
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const [, , SRC, OUTDIR] = process.argv;
if (!SRC || !OUTDIR) throw new Error('usage: controls372-loader.mjs <nm-pec-polygons.json> <outdir>');
fs.mkdirSync(OUTDIR, { recursive: true });
const base = JSON.parse(fs.readFileSync(SRC, 'utf8'));
if (base.districts.length !== 10) throw new Error(`the source holds ${base.districts.length} districts, not 10`);

const write = (name, obj, checks) => {
  const p = `${OUTDIR}/${name}`;
  fs.writeFileSync(p, JSON.stringify(obj));
  const back = JSON.parse(fs.readFileSync(p, 'utf8'));
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${(fs.statSync(p).size / 1e6).toFixed(2)} MB)`);
};
const firstPoint = g => (g.type === 'Polygon' ? g.coordinates : g.coordinates[0])[0][0];
const swap = (obj, a, b) => {
  const x = obj.districts.find(d => d.district === a);
  const y = obj.districts.find(d => d.district === b);
  [x.geojson, y.geojson] = [y.geojson, x.geojson];
};

// A — 🔴🔴 THE CRS CONTROL. The service really is EPSG:26913 in metres, so this is what we would
//     hold if outSR=4326 were ever dropped from the query.
const c = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await c.connect();
const utm = JSON.parse(JSON.stringify(base));
for (const d of utm.districts) {
  const r = await c.query(
    `SELECT public.ST_AsGeoJSON(public.ST_Transform(
        public.ST_SetSRID(public.ST_GeomFromGeoJSON($1), 4326), 26913)) AS g`, [JSON.stringify(d.geojson)]);
  d.geojson = JSON.parse(r.rows[0].g);
}
await c.end();
write('t372A-utm-metres.json', utm, [
  ['coordinates are not in metres', o => Math.abs(firstPoint(o.districts[0].geojson)[0]) > 1000],
  ['still 10 districts', o => o.districts.length === 10],
]);

// B — lose one district.
const missing = JSON.parse(JSON.stringify(base));
missing.districts = missing.districts.filter(d => d.district !== 6);
write('t372B-district-6-missing.json', missing, [
  ['district 6 is still present', o => !o.districts.some(d => d.district === 6)],
  ['9 districts remain', o => o.districts.length === 9],
]);

// C — 🔴 swap the geometry of districts 8 and 9, keeping both numbers. Both are rural and
//     anchored on whole counties (Colfax in 8, Eddy in 9), so this exercises the whole-county
//     arm cleanly. Every structural test still passes; only the labels are wrong.
const swapped = JSON.parse(JSON.stringify(base));
swap(swapped, 8, 9);
write('t372C-districts-8-and-9-swapped.json', swapped, [
  ['the geometries were not swapped', o => JSON.stringify(firstPoint(o.districts.find(d => d.district === 8).geojson))
    === JSON.stringify(firstPoint(base.districts.find(d => d.district === 9).geojson))],
  ['still 10 districts', o => o.districts.length === 10],
]);

// D — 🔴🔴 THE KNOWN HOLE, PLANTED ON PURPOSE AND EXPECTED TO **PASS**. Districts 1, 2 and 3 lie
//     entirely inside Bernalillo county, which HB 9 splits six ways, so none of them has a whole
//     county to anchor on and the split arm only asserts that Bernalillo is shared by exactly
//     {1,2,3,4,5,6} — a set a permutation of 1, 2 and 3 leaves alone. This control exists to
//     record that, not to be caught. ▶ A control that passes and is written down is a measured
//     limit; a control nobody ran is a surprise waiting for the next pass.
const perm = JSON.parse(JSON.stringify(base));
const [p1, p2, p3] = [1, 2, 3].map(n => perm.districts.find(d => d.district === n));
const g1 = p1.geojson;
p1.geojson = p2.geojson; p2.geojson = p3.geojson; p3.geojson = g1;
write('t372D-districts-1-2-3-rotated.json', perm, [
  ['the rotation did not apply', o => JSON.stringify(firstPoint(o.districts.find(d => d.district === 1).geojson))
    === JSON.stringify(firstPoint(base.districts.find(d => d.district === 2).geojson))],
  ['still 10 districts', o => o.districts.length === 10],
]);

// E — the county table claims Otero for districts 7 and 8 rather than 7 and 9. Target: the split
//     arm, which C does not reach because the whole-county arm runs first. Otero is also the
//     county whose 0.4962% District 7 slice set the floor, so it is the one worth pinning.
const COUNTIES = 'data/state-exec-2026-results/nm-pec-counties-2026-11-07.json';
const counties = JSON.parse(fs.readFileSync(COUNTIES, 'utf8'));
const otero = counties.split.find(s => s.county === 'Otero County');
if (!otero || JSON.stringify(otero.districts) !== '[7,9]') throw new Error(`control E: Otero is ${JSON.stringify(otero?.districts)}, expected [7,9]`);
otero.districts = [7, 8];
const ePath = `${OUTDIR}/t372E-counties-otero-claimed-for-8.json`;
fs.writeFileSync(ePath, JSON.stringify(counties, null, 1));
const eBack = JSON.parse(fs.readFileSync(ePath, 'utf8'));
if (JSON.stringify(eBack.split.find(s => s.county === 'Otero County').districts) !== '[7,8]') throw new Error('t372E: TAMPER DID NOT APPLY');
if (eBack.whole.length !== 23 || eBack.split.length !== 10) throw new Error('t372E: the table lost rows');
console.log(`t372E (${ePath}): PRESENT — the county table now claims Otero for districts 7 and 8`);

const loader = 'scripts/CC_0372-nm-pec-geofences.mjs';
const src = fs.readFileSync(loader, 'utf8');
const FROM = `const COUNTIES = '${COUNTIES}';`;
if (!src.includes(FROM)) throw new Error(`control E: cannot find ${JSON.stringify(FROM)} in ${loader}`);
const TO = `const COUNTIES = ${JSON.stringify(ePath)};`;
fs.writeFileSync('scripts/_t372E-nm-pec-geofences.mjs', src.replace(FROM, TO));
if (!fs.readFileSync('scripts/_t372E-nm-pec-geofences.mjs', 'utf8').includes(TO)) throw new Error('t372E loader copy: TAMPER DID NOT APPLY');
console.log('t372E loader copy (scripts/_t372E-nm-pec-geofences.mjs): PRESENT');
