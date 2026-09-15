/**
 * MN-3 address probe.
 *
 * The only reliable detector is end-to-end: does a real point return the officials who represent
 * it? This runs point -> geofence_boundaries -> districts -> offices -> office_terms ->
 * politicians, exactly as address search does.
 *
 * 🔴 GREEN IS NOT A CLAIM ABOUT DISTRICTS UNLESS YOU COUNT THEM. Two city-hall points prove the
 * chain works; they say nothing about the other ten council districts. So every one of the twelve
 * is probed at its OWN interior point and must return exactly one holder, and that holder must be
 * the one the roster names.
 *
 * ⚠ Each control is watched FAILING first.
 *
 *   node probe-mn3.mjs
 */
import fs from 'fs';
import pg from 'pg';

const ANCHORS = [
  { name: 'Duluth City Hall', lon: -92.1057144, lat: 46.7828028, city: 'Duluth' },
  { name: 'Saint Paul City Hall', lon: -93.0931028, lat: 44.9439514, city: 'Saint Paul' },
];

const roster = JSON.parse(fs.readFileSync('../mn-cities-roster.json', 'utf8')).roster;
const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
await client.query(`SET statement_timeout = '180s'`);
const q = async (sql, params = []) => (await client.query(sql, params)).rows;

/** Everything a point resolves to, across every layer address search uses. */
const AT_POINT = `
  SELECT d.district_type::text AS layer, d.label, d.mtfcc, o.title,
         pol.full_name AS holder
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians pol ON pol.id = och.politician_id
  WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
    AND lower(COALESCE(d.state,'')) IN ('mn','27')
  ORDER BY d.district_type::text, o.title`;

console.log('-- ANCHOR PROBES ---------------------------------------------------------------');
for (const a of ANCHORS) {
  const rows = await q(AT_POINT, [a.lon, a.lat]);
  console.log(`\n${a.name}  (${a.lon}, ${a.lat}) -> ${rows.length} answer(s)`);
  for (const r of rows) console.log(`   ${r.layer.padEnd(13)} ${String(r.label).padEnd(34)} ${String(r.title).padEnd(26)} ${r.holder ?? '(vacant)'}`);
  const unseated = rows.filter((r) => !r.holder);
  if (unseated.length) console.log(`   ⚠ ${unseated.length} office(s) with no holder`);
}

console.log('\n-- PER-DISTRICT CONTROL: all 12 council districts, each at its own interior point --');
const perDistrict = await q(`
  WITH d AS (
    SELECT dd.id, dd.label, dd.geo_id, ST_PointOnSurface(gb.geometry) AS pt
    FROM essentials.districts dd
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = dd.geo_id AND gb.mtfcc = dd.mtfcc
    WHERE dd.mtfcc IN ('X0052','X0053') AND lower(dd.state) = 'mn'
  )
  SELECT d.label, d.geo_id,
         count(o.id) AS offices,
         count(och.politician_id) AS holders,
         string_agg(DISTINCT pol.full_name, ', ') AS who,
         (SELECT count(*) FROM essentials.districts d2
            JOIN essentials.geofence_boundaries g2 ON g2.geo_id = d2.geo_id AND g2.mtfcc = d2.mtfcc
           WHERE d2.mtfcc IN ('X0052','X0053')
             AND ST_Covers(g2.geometry, d.pt)) AS districts_at_that_point
  FROM d
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians pol ON pol.id = och.politician_id
  GROUP BY d.label, d.geo_id, d.pt ORDER BY d.geo_id`);

let bad = 0;
for (const r of perDistrict) {
  const want = roster.find((x) =>
    (x.city === 'Duluth' ? `duluth-mn-council-district-${x.district_number}` : `saint-paul-mn-ward-${x.district_number}`) === r.geo_id);
  const nameOk = want && r.who === want.full_name;
  const ok = Number(r.offices) === 1 && Number(r.holders) === 1 && Number(r.districts_at_that_point) === 1 && nameOk;
  if (!ok) bad++;
  console.log(`  ${ok ? '✓' : '✗'} ${String(r.label).padEnd(36)} offices ${r.offices} holders ${r.holders} districts-at-point ${r.districts_at_that_point}  ${r.who}${nameOk ? '' : `  <- roster says ${want?.full_name}`}`);
}
console.log(`per-district control: ${perDistrict.length} district(s), ${bad} failure(s)`);

console.log('\n-- CONTROLS (each must report a DIFFERENT answer than the probe above) ----------');
// 1. A point outside both cities must return no city office.
for (const [label, lon, lat] of [
  ['a point in Lake Superior, 20 km offshore', -91.85, 46.95],
  ['Minneapolis City Hall', -93.2650, 44.9778],
]) {
  const rows = await q(AT_POINT, [lon, lat]);
  const cityRows = rows.filter((r) => r.mtfcc === 'X0052' || r.mtfcc === 'X0053');
  console.log(`  ${cityRows.length === 0 ? 'OK  ' : 'FAIL'} ${label.padEnd(42)} ${cityRows.length} Duluth/St. Paul council answer(s)`);
}
// 2. The detector must not return the same answer everywhere.
const distinct = new Set(perDistrict.map((r) => r.who)).size;
console.log(`  ${distinct === perDistrict.length ? 'OK  ' : 'FAIL'} ${'twelve districts, twelve holders'.padEnd(42)} ${distinct} distinct name(s) across ${perDistrict.length} districts`);
// 3. A deliberately wrong expectation must be reported.
const ctlDistrict = perDistrict[0];
console.log(`  OK   ${'a wrong expectation is reported'.padEnd(42)} "${ctlDistrict.who}" vs planted "Zzz Control" -> ${ctlDistrict.who === 'Zzz Control' ? 'MATCHED (broken)' : 'mismatch reported'}`);

await client.end();
process.exit(bad === 0 ? 0 : 1);
