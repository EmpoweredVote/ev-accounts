// Controls on CC_0373-ne-boards-geofences.mjs, the loader for all three Nebraska boards.
// Each tamper is asserted PRESENT before it is run.
// ⚠ Read the message each one produces, never the exit code: CC_0370 had a control that failed
//   for the wrong reason and one that fired on an earlier gate than the one under test.
// 🔴🔴 RUN THESE BEFORE THE REAL LOAD. The loader inserts ON CONFLICT DO NOTHING, so once the
//   correct polygons are committed a tampered dry run inserts nothing and every gate checks the
//   rows that were already there. CC_0372's CRS control and its label-swap control both reported
//   "DRY RUN OK" that way. The loader now refuses a dry run that does not insert its full set,
//   which turns that silent pass into a loud stop — but the right order is still this one.
import fs from 'node:fs';
import { createRequire } from 'node:module';
const req = createRequire('C:/EV-Accounts/backend/package.json');
const pg = req('pg');
const dotenv = req('dotenv');
dotenv.config({ path: 'C:/EV-Accounts/backend/.env' });

const [, , SRCDIR, OUTDIR] = process.argv;
if (!SRCDIR || !OUTDIR) throw new Error('usage: controls373-loader.mjs <dir with psc.json sboe.json regents.json> <outdir>');
fs.mkdirSync(OUTDIR, { recursive: true });

const load = b => {
  const o = JSON.parse(fs.readFileSync(`${SRCDIR}/${b}.json`, 'utf8'));
  if (o.body !== b) throw new Error(`${SRCDIR}/${b}.json says body=${o.body}`);
  return o;
};
const sboe = load('sboe');
const regents = load('regents');
if (sboe.districts.length !== 8 || regents.districts.length !== 8) throw new Error('expected 8 districts in each');

const write = (name, obj, checks) => {
  const p = `${OUTDIR}/${name}`;
  fs.writeFileSync(p, JSON.stringify(obj));
  const back = JSON.parse(fs.readFileSync(p, 'utf8'));
  for (const [why, ok] of checks) if (!ok(back)) throw new Error(`${name}: TAMPER DID NOT APPLY — ${why}`);
  console.log(`${name}: PRESENT (${(fs.statSync(p).size / 1e6).toFixed(2)} MB)`);
  return p;
};
const firstPoint = g => (g.type === 'Polygon' ? g.coordinates : g.coordinates[0])[0][0];
const clone = o => JSON.parse(JSON.stringify(o));
const swapGeom = (obj, a, b) => {
  const x = obj.districts.find(d => d.district === a);
  const y = obj.districts.find(d => d.district === b);
  [x.geojson, y.geojson] = [y.geojson, x.geojson];
};
const movedTo = (o, n, base, m) => JSON.stringify(firstPoint(o.districts.find(d => d.district === n).geojson))
  === JSON.stringify(firstPoint(base.districts.find(d => d.district === m).geojson));

// A — 🔴🔴 THE CRS CONTROL. The gis.ne.gov service really is Web Mercator (EPSG:3857), so this
//     is exactly what we would hold if outSR=4326 were ever dropped from the query. A Holladay
//     failure: valid, correctly shaped, matches no address.
const c = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await c.connect();
const merc = clone(sboe);
for (const d of merc.districts) {
  const r = await c.query(
    `SELECT public.ST_AsGeoJSON(public.ST_Transform(
        public.ST_SetSRID(public.ST_GeomFromGeoJSON($1), 4326), 3857)) AS g`, [JSON.stringify(d.geojson)]);
  d.geojson = JSON.parse(r.rows[0].g);
}
await c.end();
write('t373A-sboe-web-mercator-metres.json', merc, [
  ['coordinates are not in metres', o => Math.abs(firstPoint(o.districts[0].geojson)[0]) > 1000],
  ['still 8 districts', o => o.districts.length === 8],
]);

// B — lose one district.
const missing = clone(sboe);
missing.districts = missing.districts.filter(d => d.district !== 6);
write('t373B-sboe-district-6-missing.json', missing, [
  ['district 6 is still present', o => !o.districts.some(d => d.district === 6)],
  ['7 districts remain', o => o.districts.length === 7],
]);

// C — 🔴 swap the geometry of State Board of Education districts 3 and 6, keeping both numbers
//     and both populations. Both are anchored on whole counties (6 in District 3, 17 in
//     District 6), so this exercises the WHOLE-COUNTY arm of the canvass gate. Every structural
//     test still passes; only the labels are wrong.
const swapped36 = clone(sboe);
swapGeom(swapped36, 3, 6);
write('t373C-sboe-3-and-6-swapped.json', swapped36, [
  ['the geometries were not swapped', o => movedTo(o, 3, sboe, 6) && movedTo(o, 6, sboe, 3)],
  ['still 8 districts', o => o.districts.length === 8],
]);

// D — 🔴 swap State Board of Education districts 1 and 4. NEITHER has a whole county — 1 is a
//     part of Lancaster and 4 a part of Douglas — so the whole-county arm has nothing to say
//     about either, and this is the tamper the SPLIT arm has to catch on its own. C cannot
//     reach it, because the whole-county arm runs first and stops the run.
const swapped14 = clone(sboe);
swapGeom(swapped14, 1, 4);
write('t373D-sboe-1-and-4-swapped.json', swapped14, [
  ['the geometries were not swapped', o => movedTo(o, 1, sboe, 4) && movedTo(o, 4, sboe, 1)],
  ['still 8 districts', o => o.districts.length === 8],
]);

// E — the enacted-plan anchor. District 5's population is replaced with District 6's, which is
//     the shape of a GIS layer that has been re-cut without the statute changing.
const popTamper = clone(sboe);
popTamper.districts.find(d => d.district === 5).population = 244434;
write('t373E-sboe-population-5-reads-as-6.json', popTamper, [
  ['the population was not changed', o => o.districts.find(d => d.district === 5).population === 244434],
  ['district 6 is untouched', o => o.districts.find(d => d.district === 6).population === 244434],
]);

// F — 🔴🔴 THE REGENTS TRAP, PLANTED. These are the populations the file named
//     reg_lb8_final.pdf prints for districts 1, 4, 5 and 8 — the plan as it stood on
//     25 September 2021, BEFORE AM41 was adopted on the 28th. A pass here would mean the loader
//     cannot tell the enacted Regents map from the one that was amended away.
const preAm41 = clone(regents);
for (const [d, p] of [[1, 242357], [4, 234292], [5, 254335], [8, 248467]]) {
  preAm41.districts.find(x => x.district === d).population = p;
}
write('t373F-regents-pre-am41-populations.json', preAm41, [
  ['district 1 was not set to the pre-AM41 figure', o => o.districts.find(d => d.district === 1).population === 242357],
  ['district 4 was not set to the pre-AM41 figure', o => o.districts.find(d => d.district === 4).population === 234292],
  ['the four still sum to the state total with the other four',
    o => o.districts.reduce((s, d) => s + d.population, 0) === 1961504],
]);

// G — 🔴🔴 THE NEBRASKA-SPECIFIC HAZARD: two bodies share mtfcc X-ST-BOARD in one state. This
//     copy of the loader has the geo_id scoping removed from the row-count query, which is the
//     mistake every earlier state was protected from by accident. Run it for the Regents while
//     the Public Service Commission's five rows are already loaded: the count must come back 13.
const loader = 'scripts/CC_0373-ne-boards-geofences.mjs';
const src = fs.readFileSync(loader, 'utf8');
const FROM = `      WHERE mtfcc = $1 AND state = $2 AND geo_id LIKE $3 || '%' ORDER BY geo_id\`,`;
if (!src.includes(FROM)) throw new Error(`control G: cannot find the scoped row-count query in ${loader}`);
const TO = `      WHERE mtfcc = $1 AND state = $2 AND $3 <> '' ORDER BY geo_id\`,`;
const gPath = 'scripts/_t373G-ne-boards-geofences.mjs';
fs.writeFileSync(gPath, src.replace(FROM, TO));
if (!fs.readFileSync(gPath, 'utf8').includes(TO)) throw new Error('t373G loader copy: TAMPER DID NOT APPLY');
if (fs.readFileSync(gPath, 'utf8').includes(FROM)) throw new Error('t373G loader copy: the scoped query is still there');
console.log(`t373G loader copy (${gPath}): PRESENT — the row-count query no longer filters on the geo_id prefix`);

// H — 🔴🔴 THE KNOWN HOLE, PLANTED ON PURPOSE AND EXPECTED TO **PASS**. State Board of Education
//     districts 4 and 8 both lie wholly inside Douglas County, so the canvass sees the same
//     county set for both and cannot tell them apart; and this tamper moves the GEOMETRY only,
//     leaving each district's number and population alone, so the enacted-plan anchor sees
//     nothing either. Two districts of the Regents, 4 and 8, are open the same way.
//     ⚠ What limits the exposure is that the fetcher asks the service for one district at a
//     time and takes that feature's geometry and population together, so there is no step in
//     the pipeline where a number and a shape can drift apart by accident. A swap here has to
//     be made deliberately, in the intermediate file. The source mislabelling two districts —
//     geometry and attributes moving together — IS caught, by the population anchor, because
//     no two districts of a body hold the same number of people.
//     ▶ A control that passes and is written down is a measured limit; a control nobody ran is
//     a surprise waiting for the next pass.
const swapped48 = clone(sboe);
swapGeom(swapped48, 4, 8);
write('t373H-sboe-4-and-8-swapped-EXPECTED-TO-PASS.json', swapped48, [
  ['the geometries were not swapped', o => movedTo(o, 4, sboe, 8) && movedTo(o, 8, sboe, 4)],
  ['the populations did NOT move', o => o.districts.find(d => d.district === 4).population === 245713
    && o.districts.find(d => d.district === 8).population === 246703],
]);

// I — the same whole-county swap for the Public Service Commission, whose county table is a
//     different file and whose five districts are a different shape of problem: 92 of the 93
//     counties are assigned whole, and only Douglas is split. C and D exercise the Board of
//     Education's table; this one exercises the Commission's.
const psc = load('psc');
if (psc.districts.length !== 5) throw new Error('expected 5 Public Service Commission districts');
const swapped14psc = clone(psc);
swapGeom(swapped14psc, 1, 4);
write('t373I-psc-1-and-4-swapped.json', swapped14psc, [
  ['the geometries were not swapped', o => movedTo(o, 1, psc, 4) && movedTo(o, 4, psc, 1)],
  ['still 5 districts', o => o.districts.length === 5],
]);

console.log('\nAll tampers written. Run each with --dry-run and READ THE MESSAGE:');
console.log('  A  --body sboe     t373A  -> expect: bbox outside Nebraska, WRONG CRS');
console.log('  B  --body sboe     t373B  -> expect: refused before the database, 7 districts');
console.log('  C  --body sboe     t373C  -> expect: whole-county arm, counties not in the district that canvassed them');
console.log('  D  --body sboe     t373D  -> expect: split arm, Lancaster/Douglas shared with the wrong districts');
console.log('  E  --body sboe     t373E  -> expect: the enacted LB 7 sheet says 237994, refused before the database');
console.log('  F  --body regents  t373F  -> expect: the enacted LB 8/AM41 sheet says 248649, refused before the database');
console.log('  G  --body regents  (clean file, tampered loader copy, PSC already loaded) -> expect: 13 rows, expected 8');
console.log('  H  --body sboe     t373H  -> expect: DRY RUN OK. This one PASSES and is the recorded limit.');
console.log('  I  --body psc      t373I  -> expect: whole-county arm, against the Commission own county table');
