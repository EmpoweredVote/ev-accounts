// Controls on CC_0369-tx-sboe-geofences.mjs. Each writes a tampered GeoJSON, asserts the tamper
// is PRESENT, and the caller then runs the loader against it and watches the guard fail.
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const [, , SRC, OUTDIR] = process.argv;
const base = JSON.parse(fs.readFileSync(SRC, 'utf8'));
const write = (name, obj, checks) => {
  const p = `${OUTDIR}/${name}`;
  fs.writeFileSync(p, JSON.stringify(obj));
  const back = JSON.parse(fs.readFileSync(p, 'utf8'));
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${(fs.statSync(p).size / 1e6).toFixed(2)} MB)`);
};

// A — 🔴🔴 THE CRS CONTROL. Reproject every ring to Web Mercator METRES and label it 4326 — the
//     exact shape of the Holladay failure, and of what the shapefile in this very dataset would
//     have given. The polygons stay valid and correctly shaped; only the units are wrong.
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
write('t369A-web-mercator-metres.json', merc, [
  ['coordinates are not in metres', o => Math.abs(o.districts[0].geojson.coordinates[0][0][0]) > 1000],
  ['still 15 districts', o => o.districts.length === 15],
]);

// B — lose one district. Target: the count guard. A 14-district map leaves a hole the size of a
//     Texas SBOE district and would answer "no board member" for everyone in it.
const missing = JSON.parse(JSON.stringify(base));
missing.districts = missing.districts.filter(d => d.district !== 7);
write('t369B-district-7-missing.json', missing, [
  ['district 7 is still present', o => !o.districts.some(d => d.district === 7)],
  ['14 districts remain', o => o.districts.length === 14],
]);

// C — swap the geometry of districts 2 and 15 (Corpus Christi and Midland), keeping both numbers.
//     Every polygon is still real, valid, 4326 Texas geometry; the set still tiles the state and
//     no two overlap. Only the LABELS are wrong. Target: the anchor guard — the board's own
//     roster puts its District 2 member in Corpus Christi and its District 15 member in Midland.
const swapped = JSON.parse(JSON.stringify(base));
const d2 = swapped.districts.find(d => d.district === 2);
const d15 = swapped.districts.find(d => d.district === 15);
[d2.geojson, d15.geojson] = [d15.geojson, d2.geojson];
write('t369C-districts-2-and-15-swapped.json', swapped, [
  ['the geometries were not swapped', o => {
    const a = o.districts.find(d => d.district === 2), b = base.districts.find(d => d.district === 15);
    return JSON.stringify(a.geojson.coordinates[0][0]) === JSON.stringify(b.geojson.coordinates[0][0]);
  }],
  ['still 15 districts', o => o.districts.length === 15],
]);
