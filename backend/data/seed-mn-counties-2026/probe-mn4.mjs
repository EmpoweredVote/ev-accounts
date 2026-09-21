/**
 * MN-4 address probe.
 *
 * The only reliable detector is end-to-end: does a real point return the officials who represent
 * it? This runs point -> geofence_boundaries -> districts -> offices -> office_terms ->
 * politicians, exactly as address search does.
 *
 * 🔴 GREEN IS NOT A CLAIM ABOUT DISTRICTS UNLESS YOU COUNT THEM. Two city-hall points prove the
 * chain works; they say nothing about the other twelve commissioner districts. So every one of
 * the fourteen is probed at its OWN interior point and must return exactly one holder, and that
 * holder must be the one the roster names.
 *
 * 🟢 THE TWO WAVES MUST STACK. MN-3 seated Duluth and Saint Paul; MN-4 seats the counties they
 * sit in. A Duluth address should now return its councilor AND its county commissioner AND the
 * three St. Louis countywide officers -- the county seats reuse the G4020 COUNTY polygon that
 * was in production before this wave opened.
 *
 * ⚠ Each control is watched reporting a DIFFERENT answer than the probe.
 *
 *   node probe-mn4.mjs
 */
import fs from 'fs';
import pg from 'pg';

const ANCHORS = [
  { name: 'Duluth City Hall', lon: -92.1057144, lat: 46.7828028, county: 'St. Louis' },
  { name: 'Saint Paul City Hall', lon: -93.0931028, lat: 44.9439514, county: 'Ramsey' },
  // A third point well away from either city hall, inside the county but not inside the seat.
  { name: 'Hibbing City Hall', lon: -92.9377, lat: 47.4272, county: 'St. Louis' },
];

const roster = JSON.parse(fs.readFileSync('../mn-counties-roster.json', 'utf8')).roster;
const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
await client.query(`SET statement_timeout = '180s'`);
const q = async (sql, params = []) => (await client.query(sql, params)).rows;

const AT_POINT = `
  SELECT d.district_type::text AS layer, d.label, d.mtfcc, o.title, pol.full_name AS holder
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians pol ON pol.id = och.politician_id
  WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
    AND lower(COALESCE(d.state,'')) IN ('mn','27')
  ORDER BY d.district_type::text, o.title`;

const COUNTY_MTFCC = ['X0054', 'X0055', 'G4020'];
let bad = 0;

console.log('-- ANCHOR PROBES ---------------------------------------------------------------');
for (const a of ANCHORS) {
  const rows = await q(AT_POINT, [a.lon, a.lat]);
  const countyRows = rows.filter((r) => COUNTY_MTFCC.includes(r.mtfcc));
  console.log(`\n${a.name}  (${a.lon}, ${a.lat}) -> ${rows.length} answer(s), ${countyRows.length} from MN-4`);
  for (const r of rows) {
    const mine = COUNTY_MTFCC.includes(r.mtfcc);
    console.log(`   ${mine ? '▶' : ' '} ${r.layer.padEnd(13)} ${String(r.label).padEnd(42)} ${String(r.title).padEnd(26)} ${r.holder ?? '(vacant)'}`);
  }
  const unseated = rows.filter((r) => !r.holder);
  if (unseated.length) {
    console.log(`   ⚠ ${unseated.length} office(s) with no holder`);
    bad++;
  }
  // St. Louis elects an Auditor/Treasurer and Ramsey does not. The probe must SEE the difference.
  const hasAuditor = countyRows.some((r) => /auditor/i.test(r.title));
  const wantAuditor = a.county === 'St. Louis';
  if (hasAuditor !== wantAuditor) {
    console.log(`   ✗ ${a.county}: auditor seat ${hasAuditor ? 'returned' : 'absent'}, expected ${wantAuditor ? 'returned' : 'absent'}`);
    bad++;
  }
  const commissioners = countyRows.filter((r) => /^Commissioner/.test(r.title));
  if (commissioners.length !== 1) {
    console.log(`   ✗ ${commissioners.length} commissioner(s) returned, expected exactly 1`);
    bad++;
  }
}

console.log('\n-- PER-DISTRICT CONTROL: all 14 commissioner districts at their own interior points --');
const perDistrict = await q(`
  WITH d AS (
    SELECT dd.id, dd.label, dd.geo_id, ST_PointOnSurface(gb.geometry) AS pt
    FROM essentials.districts dd
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = dd.geo_id AND gb.mtfcc = dd.mtfcc
    WHERE dd.mtfcc IN ('X0054','X0055') AND lower(dd.state) = 'mn'
  )
  SELECT d.label, d.geo_id,
         count(o.id) AS offices,
         count(och.politician_id) AS holders,
         string_agg(DISTINCT pol.full_name, ', ') AS who,
         (SELECT count(*) FROM essentials.districts d2
            JOIN essentials.geofence_boundaries g2 ON g2.geo_id = d2.geo_id AND g2.mtfcc = d2.mtfcc
           WHERE d2.mtfcc IN ('X0054','X0055') AND ST_Covers(g2.geometry, d.pt)) AS districts_at_that_point
  FROM d
  JOIN essentials.offices o ON o.district_id = d.id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians pol ON pol.id = och.politician_id
  GROUP BY d.label, d.geo_id, d.pt ORDER BY d.geo_id`);

for (const r of perDistrict) {
  const want = roster.find(
    (x) =>
      x.district_number &&
      `${x.county === 'St. Louis' ? 'st-louis' : 'ramsey'}-mn-commissioner-district-${x.district_number}` === r.geo_id,
  );
  const nameOk = want && r.who === want.full_name;
  const ok = Number(r.offices) === 1 && Number(r.holders) === 1 && Number(r.districts_at_that_point) === 1 && nameOk;
  if (!ok) bad++;
  console.log(
    `  ${ok ? '✓' : '✗'} ${String(r.label).padEnd(42)} offices ${r.offices} holders ${r.holders} ` +
      `districts-at-point ${r.districts_at_that_point}  ${r.who}${nameOk ? '' : `  <- roster says ${want?.full_name}`}`,
  );
}
console.log(`per-district control: ${perDistrict.length} district(s) probed`);
if (perDistrict.length !== 14) {
  console.log(`  ✗ expected 14 districts, probed ${perDistrict.length}`);
  bad++;
}

console.log('\n-- CONTROLS (each must report a DIFFERENT answer than the probe above) ----------');
// ⚠ MN-3's offshore control point DOES NOT TRANSFER. (-91.85, 46.95) is 20 km out in Lake
//   Superior and returns no CITY council district -- but it sits inside ST. LOUIS COUNTY, whose
//   commissioner districts run out into the lake, so returning a commissioner there is the right
//   answer. A negative control has to be outside the thing being tested, not outside the last
//   thing that was tested. These three are in Ashland WI, Keweenaw MI and Hennepin MN.
for (const [label, lon, lat] of [
  ['Lake Superior, Ashland County WI waters', -90.5, 47.3],
  ['Lake Superior, Keweenaw County MI waters', -88.5, 47.3],
  ['Minneapolis City Hall (Hennepin County)', -93.265, 44.9778],
  ['Madison, Wisconsin', -89.3838, 43.0747],
]) {
  const rows = await q(AT_POINT, [lon, lat]);
  const countyRows = rows.filter((r) => ['X0054', 'X0055'].includes(r.mtfcc));
  const ok = countyRows.length === 0;
  if (!ok) bad++;
  console.log(`  ${ok ? 'OK  ' : 'FAIL'} ${label.padEnd(44)} ${countyRows.length} commissioner answer(s)`);
}

// 🔴 THE KNOWN GAP, CHARACTERISED RATHER THAN HIDDEN. The loader accepted St. Louis at 98.220%
//    because the uncovered 120.593 sq mi is one edge wedge of Lake Superior holding no
//    incorporated place. This asserts exactly what that costs: a point in the wedge is INSIDE
//    the county and returns the three countywide officers but NO commissioner. That is the
//    honest consequence of the measurement, and it is stated here so nobody rediscovers it as a bug.
{
  const wedge = await q(AT_POINT, [-91.8825, 46.8566]);
  const comm = wedge.filter((r) => ['X0054', 'X0055'].includes(r.mtfcc)).length;
  const countywide = wedge.filter((r) => r.mtfcc === 'G4020').length;
  const ok = comm === 0 && countywide === 3;
  if (!ok) bad++;
  console.log(
    `  ${ok ? 'OK  ' : 'FAIL'} ${'the known lake wedge: 0 commissioners, 3 officers'.padEnd(44)} ` +
      `${comm} commissioner(s), ${countywide} countywide officer(s)`,
  );
}

// The detector must not return the same answer everywhere.
const distinct = new Set(perDistrict.map((r) => r.who)).size;
const distinctOk = distinct === perDistrict.length;
if (!distinctOk) bad++;
console.log(`  ${distinctOk ? 'OK  ' : 'FAIL'} ${'fourteen districts, fourteen holders'.padEnd(44)} ${distinct} distinct name(s)`);

// 🔴 A POSITIVE CONTROL ON THE NEGATIVE CONTROLS. If AT_POINT returned nothing for ANY point,
//    the three "0 commissioner answers" above would be vacuous passes.
const mplsAll = await q(AT_POINT, [-93.265, 44.9778]);
const nonVacuous = mplsAll.length > 0;
if (!nonVacuous) bad++;
console.log(
  `  ${nonVacuous ? 'OK  ' : 'FAIL'} ${'the probe is not simply blind'.padEnd(44)} Minneapolis returns ${mplsAll.length} answer(s) from other layers`,
);

console.log(`\n${bad === 0 ? '✓ PROBE GREEN' : `✗ ${bad} failure(s)`}`);
await client.end();
process.exit(bad === 0 ? 0 : 1);
