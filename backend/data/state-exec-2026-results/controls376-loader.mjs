// Controls on CC_0376-nh-exec-geofences.mjs, the loader for New Hampshire's Executive Council.
// Each tamper is asserted PRESENT before it is run — a sed that silently produced a 0-byte file
// once got "DRY RUN OK" out of an empty migration, and an empty tamper proves nothing.
// ⚠ Read the message each one produces, never the exit code: CC_0370 had a control that failed
//   for the wrong reason and one that fired on an earlier gate than the one under test.
// 🔴🔴 RUN THESE BEFORE THE REAL LOAD. The loader inserts ON CONFLICT DO NOTHING, so once the
//   correct polygons are committed a tampered dry run inserts nothing and every gate checks the
//   rows that were already there. CC_0372's CRS control and its label-swap control both reported
//   "DRY RUN OK" that way.
//
// 🔴🔴 CONTROL B IS THE ONE THIS BODY EXISTS TO SURVIVE. It is not a synthetic tamper: it loads
//   the REAL superseded 2012 councilor map — five valid, disjoint polygons covering the whole of
//   New Hampshire, published in the same service, under the 2022 map's labels. Every structural
//   gate passes on it. Only the statute anchor can tell it apart, and this measures by how much.
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const [, , SRC, OUTDIR] = process.argv;
if (!SRC || !OUTDIR) throw new Error('usage: controls376-loader.mjs <nh-exec-districts.json> <outdir>');
fs.mkdirSync(OUTDIR, { recursive: true });

const base = JSON.parse(fs.readFileSync(SRC, 'utf8'));
if (base.layerName !== 'NHExecDists2022' || base.districts.length !== 5) {
  throw new Error(`${SRC} is not the five-district 2022 plan`);
}

const clone = o => JSON.parse(JSON.stringify(o));
const firstPoint = g => (g.type === 'Polygon' ? g.coordinates : g.coordinates[0])[0][0];
const write = (name, obj, checks) => {
  const p = `${OUTDIR}/${name}`;
  fs.writeFileSync(p, JSON.stringify(obj));
  const back = JSON.parse(fs.readFileSync(p, 'utf8'));
  if (fs.statSync(p).size < 1000) throw new Error(`${name}: TAMPER FILE IS ${fs.statSync(p).size} BYTES — it proves nothing`);
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${(fs.statSync(p).size / 1e6).toFixed(2)} MB)`);
  return p;
};
const swapGeom = (obj, a, b) => {
  const x = obj.districts.find(d => d.district === a);
  const y = obj.districts.find(d => d.district === b);
  [x.geojson, y.geojson] = [y.geojson, x.geojson];
};
const movedTo = (o, n, m) => JSON.stringify(firstPoint(o.districts.find(d => d.district === n).geojson))
  === JSON.stringify(firstPoint(base.districts.find(d => d.district === m).geojson));

const c = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await c.connect();

// A — 🔴🔴 THE CRS CONTROL, and it is the faithful one: the NHGRANIT layer's native spatial
//     reference really is EPSG:3437, NAD83 New Hampshire State Plane in US SURVEY FEET. This is
//     exactly what we would hold if outSR=4326 were ever dropped from the query — a valid,
//     correctly shaped map whose coordinates are in the hundreds of thousands and which matches
//     no address on Earth. The Holladay failure, reproduced from the real source.
const plane = clone(base);
for (const d of plane.districts) {
  const r = await c.query(
    `SELECT public.ST_AsGeoJSON(public.ST_Transform(
        public.ST_SetSRID(public.ST_GeomFromGeoJSON($1), 4326), 3437)) AS g`, [JSON.stringify(d.geojson)]);
  d.geojson = JSON.parse(r.rows[0].g);
}
write('t376A-state-plane-feet.json', plane, [
  ['coordinates are not in State Plane feet', o => firstPoint(o.districts[0].geojson)[0] > 100000],
  ['still 5 districts', o => o.districts.length === 5],
]);

// B — 🔴🔴 THE 2012 DECOY, FETCHED FOR REAL. Layer 1 of the same service, `NHExecCo2012`, under
//     the 2022 plan's labels. Not a synthetic tamper: a genuine, complete, legally-real map of
//     the same five districts, a decade out of date.
const SERVICE = 'https://nhgeodata.unh.edu/hosting/rest/services/Hosted/APB_ElectoralDistricts/FeatureServer';
const decoy = clone(base);
decoy.source = '2012 DECOY — NHExecCo2012, the superseded councilor map. CONTROL ONLY.';
for (const d of decoy.districts) {
  const u = `${SERVICE}/1/query?where=${encodeURIComponent(`execco2012=${d.district}`)}` +
    '&outFields=execco2012&returnGeometry=true&outSR=4326&f=geojson&geometryPrecision=7';
  const r = await fetch(u, { headers: { 'User-Agent': 'ev-accounts/1.0 (control: superseded NH map)' } });
  if (!r.ok) throw new Error(`decoy district ${d.district}: HTTP ${r.status}`);
  const fc = JSON.parse(await r.text());
  if (fc.error) throw new Error(`decoy district ${d.district}: ${JSON.stringify(fc.error).slice(0, 160)}`);
  if (fc.features?.length !== 1) throw new Error(`decoy district ${d.district}: ${fc.features?.length} features`);
  d.geojson = fc.features[0].geometry;
}
write('t376B-2012-superseded-map.json', decoy, [
  ['the 2012 geometry is identical to the 2022 geometry — there would be no trap',
    o => o.districts.some((d, i) => JSON.stringify(d.geojson) !== JSON.stringify(base.districts[i].geojson))],
  ['still 5 districts', o => o.districts.length === 5],
]);

// 🟢 HOW BIG IS THE TRAP? Measured rather than asserted: how many of the 259 statute-named towns
//    the 2012 map puts in a different district from the 2022 map. A small number would mean the
//    decoy is nearly harmless and the town gate barely separates them; print it either way.
{
  const comp = JSON.parse(fs.readFileSync('data/state-exec-2026-results/nh-exec-composition.json', 'utf8'));
  const vals = comp.towns.map((_, i) => `($${i * 3 + 1}::int,$${i * 3 + 2}::float8,$${i * 3 + 3}::float8)`).join(',');
  const params = comp.towns.flatMap(t => [t.district, t.lon, t.lat]);
  const geoms = decoy.districts.map(d => JSON.stringify(d.geojson));
  const r = await c.query(
    `WITH t(expect, lon, lat) AS (VALUES ${vals}),
          g(d, geom) AS (SELECT * FROM unnest($${params.length + 1}::int[],
              (SELECT array_agg(public.ST_Multi(public.ST_CollectionExtract(public.ST_MakeValid(
                   public.ST_SetSRID(public.ST_GeomFromGeoJSON(x), 4326)), 3)))
                 FROM unnest($${params.length + 2}::text[]) x)))
     SELECT count(*) n,
            count(*) FILTER (WHERE (SELECT g.d FROM g WHERE public.ST_Covers(g.geom,
              public.ST_SetSRID(public.ST_MakePoint(t.lon, t.lat), 4326)) LIMIT 1) IS DISTINCT FROM t.expect) moved
       FROM t`,
    [...params, [1, 2, 3, 4, 5], geoms]);
  console.log(`  -> the 2012 map puts ${r.rows[0].moved} of ${r.rows[0].n} statute-named towns in a ` +
    `different district from the 2022 map`);
}

// C — 🔴 swap districts 1 and 2. Both are large and both touch several counties, so the split-county
//     arm has plenty to say; this is the tamper the COARSE gate should also catch.
const swap12 = clone(base);
swapGeom(swap12, 1, 2);
write('t376C-1-and-2-swapped.json', swap12, [
  ['the geometries were not swapped', o => movedTo(o, 1, 2) && movedTo(o, 2, 1)],
  ['still 5 districts', o => o.districts.length === 5],
]);

// D — 🔴 swap districts 3 and 4. NEITHER holds a whole county — Carroll, the only one, is in
//     district 1 — so the whole-county arm has nothing to say about either. This is the tamper
//     the TOWN gate has to catch on its own, and C cannot reach it because the gates run in
//     order and a tamper that trips an earlier one tells you nothing about a later one.
const swap34 = clone(base);
swapGeom(swap34, 3, 4);
write('t376D-3-and-4-swapped.json', swap34, [
  ['the geometries were not swapped', o => movedTo(o, 3, 4) && movedTo(o, 4, 3)],
  ['still 5 districts', o => o.districts.length === 5],
]);

// E — lose a district: the count gate.
const missing = clone(base);
missing.districts = missing.districts.filter(d => d.district !== 5);
write('t376E-district-5-missing.json', missing, [
  ['district 5 is still present', o => !o.districts.some(d => d.district === 5)],
  ['4 districts remain', o => o.districts.length === 4],
]);

// F — 🔴 the layer-provenance gate on the loader itself. The loader refuses a file that was not
//     fetched from NHExecDists2022; this proves that check is not decorative.
const wrongLayer = clone(base);
wrongLayer.layerName = 'NHExecCo2012';
write('t376F-claims-the-2012-layer.json', wrongLayer, [
  ['layerName was not changed', o => o.layerName === 'NHExecCo2012'],
  ['still 5 districts', o => o.districts.length === 5],
]);

// G — 🟢 A CONTROL THAT MUST PASS. The same five polygons, re-serialised through PostGIS, so the
//     bytes differ and the map does not. If this one went red the suite would be rejecting
//     everything and the four above would mean nothing.
const roundtrip = clone(base);
for (const d of roundtrip.districts) {
  const r = await c.query(
    `SELECT public.ST_AsGeoJSON(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1), 4326)) AS g`,
    [JSON.stringify(d.geojson)]);
  d.geojson = JSON.parse(r.rows[0].g);
}
write('t376G-roundtripped-unchanged.json', roundtrip, [
  ['the bytes are identical, so this is not a round trip',
    o => JSON.stringify(o.districts[0].geojson) !== JSON.stringify(base.districts[0].geojson)],
  ['still 5 districts', o => o.districts.length === 5],
]);

await c.end();
console.log('\nall tampers written and asserted present. Run each through the loader with --dry-run:');
console.log('  A, B, C, D, E, F must FAIL (read the message, not the exit code); G must PASS.');
