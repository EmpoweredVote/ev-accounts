// Controls on CC_0370-al-sboe-geofences.mjs. Each writes a tampered GeoJSON, asserts the tamper
// is PRESENT, and the caller then runs the loader against it and watches the guard fail.
//
// ⚠ A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, and it looks like a pass —
//   an empty or unchanged file sails through every gate it does not contain. So every tamper is
//   read back off disk and checked before the loader is ever pointed at it.
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const [, , SRC, OUTDIR] = process.argv;
if (!SRC || !OUTDIR) throw new Error('usage: controls370-loader.mjs <al-sboe-polygons.json> <outdir>');
fs.mkdirSync(OUTDIR, { recursive: true });
const base = JSON.parse(fs.readFileSync(SRC, 'utf8'));
if (base.districts.length !== 8) throw new Error(`the source holds ${base.districts.length} districts, not 8`);

const write = (name, obj, checks) => {
  const p = `${OUTDIR}/${name}`;
  fs.writeFileSync(p, JSON.stringify(obj));
  const back = JSON.parse(fs.readFileSync(p, 'utf8'));
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${(fs.statSync(p).size / 1e6).toFixed(2)} MB)`);
};
const firstPoint = g => (g.type === 'Polygon' ? g.coordinates : g.coordinates[0])[0][0];

// A — 🔴🔴 THE CRS CONTROL. Reproject every ring to Web Mercator METRES and label it 4326. This
//     is not hypothetical here: the ArcGIS service IS Web Mercator, and this is exactly what we
//     would hold if the outSR=4326 on the query were ever dropped. The polygons stay valid and
//     correctly shaped; only the units are wrong — the Holladay failure.
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
write('t370A-web-mercator-metres.json', merc, [
  ['coordinates are not in metres', o => Math.abs(firstPoint(o.districts[0].geojson)[0]) > 1000],
  ['still 8 districts', o => o.districts.length === 8],
]);

// B — lose one district. Target: the count guard. A 7-district map leaves a hole the size of an
//     Alabama SBOE district, and everyone inside it would be told they have no board member.
const missing = JSON.parse(JSON.stringify(base));
missing.districts = missing.districts.filter(d => d.district !== 7);
write('t370B-district-7-missing.json', missing, [
  ['district 7 is still present', o => !o.districts.some(d => d.district === 7)],
  ['7 districts remain', o => o.districts.length === 7],
]);

// C — 🔴 THE ONE WORTH READING. Swap the geometry of districts 2 and 6, keeping both numbers.
//     Every polygon is still real, valid, 4326 Alabama geometry; the eight still tile the state,
//     none overlap, and all 656 ZCTAs still resolve to exactly one district. ONLY THE LABELS ARE
//     WRONG, and no structural test can see it. Target: the statute gate — § 16-3-1.1 puts
//     Houston County in District 2 and Calhoun County in District 6, and the law was written
//     before this GIS file existed.
const swapped = JSON.parse(JSON.stringify(base));
const a = swapped.districts.find(d => d.district === 2);
const b = swapped.districts.find(d => d.district === 6);
[a.geojson, b.geojson] = [b.geojson, a.geojson];
write('t370C-districts-2-and-6-swapped.json', swapped, [
  ['the geometries were not swapped', o => JSON.stringify(firstPoint(o.districts.find(d => d.district === 2).geojson))
    === JSON.stringify(firstPoint(base.districts.find(d => d.district === 6).geojson))],
  ['the swap is not symmetric', o => JSON.stringify(firstPoint(o.districts.find(d => d.district === 6).geojson))
    === JSON.stringify(firstPoint(base.districts.find(d => d.district === 2).geojson))],
  ['still 8 districts', o => o.districts.length === 8],
]);

// D — swap districts 4 and 7, which share Tuscaloosa and (with 3) Jefferson. Target: the SPLIT
//     arm of the statute gate, which control C does not exercise — C's two districts split
//     nothing with each other, so only the whole-county arm fires there. Change one thing per
//     tamper, and this is the other thing.
const splitSwap = JSON.parse(JSON.stringify(base));
const x = splitSwap.districts.find(d => d.district === 4);
const y = splitSwap.districts.find(d => d.district === 7);
[x.geojson, y.geojson] = [y.geojson, x.geojson];
write('t370D-districts-4-and-7-swapped.json', splitSwap, [
  ['the geometries were not swapped', o => JSON.stringify(firstPoint(o.districts.find(d => d.district === 4).geojson))
    === JSON.stringify(firstPoint(base.districts.find(d => d.district === 7).geojson))],
  ['still 8 districts', o => o.districts.length === 8],
]);

// E — ⚠ THE SPLIT ARM OF THE STATUTE GATE IS STILL UNWATCHED AFTER C AND D. Both of those fire
//     on the WHOLE-county arm, which runs first, so the split arm has only ever been seen to
//     pass — and a gate that has only passed proves nothing. There is no geometry tamper that
//     breaks a split while leaving all 62 whole counties right, so this one tampers the STATUTE
//     TABLE instead: it claims Tuscaloosa is shared by districts 4 and 6 rather than 4 and 7.
//     The target is the arm that confirmed the riskiest reading in the transcription — that
//     District 5's "Mo County" is Mobile.
//     The tampered copy lives in backend/scripts/ so that 'pg' and 'dotenv' still resolve.
const loader = 'scripts/CC_0370-al-sboe-geofences.mjs';
const src = fs.readFileSync(loader, 'utf8');
const FROM = '  Tuscaloosa: [4, 7],';
const TO = '  Tuscaloosa: [4, 6],';
if (!src.includes(FROM)) throw new Error(`control E: cannot find ${JSON.stringify(FROM)} in ${loader}`);
const tampered = src.replace(FROM, TO);
const ePath = 'scripts/_t370E-tuscaloosa-claimed-for-6.mjs';
fs.writeFileSync(ePath, tampered);
const eBack = fs.readFileSync(ePath, 'utf8');
if (!eBack.includes(TO) || eBack.includes(FROM) || eBack.length !== src.length) {
  throw new Error('t370E: TAMPER DID NOT APPLY');
}
console.log(`t370E (${ePath}): PRESENT — the statute table now claims Tuscaloosa for districts 4 and 6`);
