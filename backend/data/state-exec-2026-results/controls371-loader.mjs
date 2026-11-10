// Controls on CC_0371-la-psc-geofences.mjs. Each writes a tampered input, asserts the tamper is
// PRESENT, and the caller then runs the loader against it and watches the guard fail.
//
// ⚠ A TAMPER THAT DID NOT APPLY LOOKS EXACTLY LIKE A PASS, so every file is read back and checked
//   before the loader is pointed at it.
// ⚠ AND A CONTROL CAN FAIL FOR THE WRONG REASON. CC_0370's CRS control died inside PostGIS on a
//   ::geography area in the same SELECT, before the guard it was written to test ever ran. Read
//   the message each one produces, never the exit code.
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const [, , SRC, OUTDIR] = process.argv;
if (!SRC || !OUTDIR) throw new Error('usage: controls371-loader.mjs <la-psc-polygons.json> <outdir>');
fs.mkdirSync(OUTDIR, { recursive: true });
const base = JSON.parse(fs.readFileSync(SRC, 'utf8'));
if (base.districts.length !== 5) throw new Error(`the source holds ${base.districts.length} districts, not 5`);

const write = (name, obj, checks) => {
  const p = `${OUTDIR}/${name}`;
  fs.writeFileSync(p, JSON.stringify(obj));
  const back = JSON.parse(fs.readFileSync(p, 'utf8'));
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${(fs.statSync(p).size / 1e6).toFixed(2)} MB)`);
};
const firstPoint = g => g.coordinates[0][0];

// A — 🔴🔴 THE CRS CONTROL. Reproject every ring to Web Mercator METRES and label it 4326: valid,
//     correctly shaped polygons that match no address on Earth.
const c = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await c.connect();
const merc = JSON.parse(JSON.stringify(base));
for (const d of merc.districts) {
  const r = await c.query(
    `SELECT public.ST_AsGeoJSON(public.ST_Transform(
        public.ST_SetSRID(public.ST_GeomFromGeoJSON($1), 4326), 3857)) AS g`,
    [JSON.stringify(d.geojson)]);
  d.geojson = JSON.parse(r.rows[0].g);
}
await c.end();
write('t371A-web-mercator-metres.json', merc, [
  ['coordinates are not in metres', o => Math.abs(firstPoint(o.districts[0].geojson)[0]) > 1000],
  ['still 5 districts', o => o.districts.length === 5],
]);

// B — lose one district. A 4-district map leaves a hole the size of a PSC district, and everyone
//     inside it is told they have no commissioner.
const missing = JSON.parse(JSON.stringify(base));
missing.districts = missing.districts.filter(d => d.district !== 3);
write('t371B-district-3-missing.json', missing, [
  ['district 3 is still present', o => !o.districts.some(d => d.district === 3)],
  ['4 districts remain', o => o.districts.length === 4],
]);

// C — 🔴 THE ONE WORTH READING. Swap the geometry of districts 4 and 5, keeping both numbers.
//     Every polygon is still real, valid, 4326 Louisiana geometry; the five still tile the state,
//     none overlap, and all 539 ZCTAs still resolve to exactly one district. ONLY THE LABELS ARE
//     WRONG. Target: the parish gate — Act 2 puts Calcasieu in District 4 and Caddo in District 5,
//     and it said so in 2022, before this KML was published.
//     D4 and D5 share no parish with each other, so this exercises the WHOLE-parish arm cleanly.
const swapped = JSON.parse(JSON.stringify(base));
const a = swapped.districts.find(d => d.district === 4);
const b = swapped.districts.find(d => d.district === 5);
[a.geojson, b.geojson] = [b.geojson, a.geojson];
write('t371C-districts-4-and-5-swapped.json', swapped, [
  ['the geometries were not swapped', o => JSON.stringify(firstPoint(o.districts.find(d => d.district === 4).geojson))
    === JSON.stringify(firstPoint(base.districts.find(d => d.district === 5).geojson))],
  ['the swap is not symmetric', o => JSON.stringify(firstPoint(o.districts.find(d => d.district === 5).geojson))
    === JSON.stringify(firstPoint(base.districts.find(d => d.district === 4).geojson))],
  ['still 5 districts', o => o.districts.length === 5],
]);

// D — ⚠ THE SPLIT ARM IS STILL UNWATCHED AFTER C, because the whole-parish arm runs first and no
//     geometry tamper breaks a split while leaving all 54 whole parishes right. So this one
//     tampers the PARISH TABLE: it claims St. Martin is shared by districts 2 and 5 rather than
//     2 and 4. St. Martin is the thinnest split in the plan — 127 of its 1,672 blocks are in
//     District 4 — so it is the one worth pinning.
const PAR = 'data/state-exec-2026-results/la-psc-parishes-2026-11-07.json';
const parishes = JSON.parse(fs.readFileSync(PAR, 'utf8'));
const sm = parishes.split.find(s => s.parish === 'St. Martin Parish');
if (!sm) throw new Error('control D: St. Martin Parish is not in the split list');
if (JSON.stringify(sm.districts) !== '[2,4]') throw new Error(`control D: St. Martin is ${JSON.stringify(sm.districts)}, expected [2,4]`);
sm.districts = [2, 5];
const dPath = `${OUTDIR}/t371D-parishes-st-martin-claimed-for-5.json`;
fs.writeFileSync(dPath, JSON.stringify(parishes, null, 1));
const dBack = JSON.parse(fs.readFileSync(dPath, 'utf8'));
const smBack = dBack.split.find(s => s.parish === 'St. Martin Parish');
if (!smBack || JSON.stringify(smBack.districts) !== '[2,5]') throw new Error('t371D: TAMPER DID NOT APPLY');
if (dBack.whole.length !== 54 || dBack.split.length !== 10) throw new Error('t371D: the table lost rows');
console.log(`t371D (${dPath}): PRESENT — the parish table now claims St. Martin for districts 2 and 5`);

// The loader reads the parish table from a fixed path, so control D needs a copy of the loader
// pointed at the tampered one. It lives in backend/scripts/ so 'pg' and 'dotenv' still resolve.
const loader = 'scripts/CC_0371-la-psc-geofences.mjs';
const src = fs.readFileSync(loader, 'utf8');
const FROM = `const PARISHES = '${PAR}';`;
if (!src.includes(FROM)) throw new Error(`control D: cannot find ${JSON.stringify(FROM)} in ${loader}`);
const TO = `const PARISHES = ${JSON.stringify(dPath)};`;
const ePath = 'scripts/_t371D-la-psc-geofences.mjs';
fs.writeFileSync(ePath, src.replace(FROM, TO));
const eBack = fs.readFileSync(ePath, 'utf8');
if (!eBack.includes(TO) || eBack.includes(FROM)) throw new Error('t371D loader copy: TAMPER DID NOT APPLY');
console.log(`t371D loader copy (${ePath}): PRESENT`);
