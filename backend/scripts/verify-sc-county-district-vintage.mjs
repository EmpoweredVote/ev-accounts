#!/usr/bin/env node
/**
 * verify-sc-county-district-vintage.mjs — Knight program, wave SC-4.
 *
 * Diffs the loaded county-council polygons against a SECOND, INDEPENDENT DIGITISATION published
 * by each county itself — the Philadelphia method, which SC-3 could not use for Columbia because
 * Columbia publishes only one layer.
 *
 *   loaded   X0060 / X0061, from the STATE's Revenue and Fiscal Affairs Office (gis.state.sc.us),
 *            stamped with each county's own ordinance: Richland 001.22HR effective 2022-02-08,
 *            Horry 01-2022 effective 2022-02-15.
 *
 * 🟢 RICHLAND — its own RC_Council_Districts service must AGREE on all eleven internal points.
 *    Two agencies digitising the same adopted ordinance agree district for district.
 *
 * 🔴🔴 HORRY — ITS ONLY PUBLISHED LAYER IS CALLED "CurrentCouncilDistricts" AND IT IS THE
 *    SUPERSEDED PRE-2022 MAP. The name is four years out of date. What dates it is not the title
 *    but the layer's OWN ATTRIBUTES: it carries a CouncilMember field naming HAROLD G. WORLEY in
 *    District 1, ORTON BELLAMY in District 7 and JOHNNY VAUGHT in District 8 — three members the
 *    2022 election replaced with Jenna Dukes, Tom Anderson and Michael Masciarelli — and its
 *    lastEditDate is 2021-11-18, before ordinance 01-2022 took effect on 2022-02-15. It also
 *    covers only 91.26% of the county against the loaded map's 99.99%.
 *    So this half is a SUPERSEDED-MAP CONTROL: it must DIFFER, and it must still name those three
 *    predecessors. The day the county republishes, this check fails loudly instead of quietly
 *    comparing against something new.
 *
 * 🔴 A LAYER'S TITLE IS NOT ITS VINTAGE. Horry's org also publishes a "Staff Plan" and a "Draft"
 * of the same thing. Picking by name similarity would have diffed the live map against a plan
 * that was never adopted — and picking the one called "Current" gets the superseded one.
 *
 *   node scripts/verify-sc-county-district-vintage.mjs
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };

const RICHLAND = {
  name: 'Richland', mtfcc: 'X0060',
  service: 'https://services5.arcgis.com/MsXJUVigv3TfPHYn/arcgis/rest/services/RC_Council_Districts/FeatureServer/0',
  field: 'DISTRICT',
};
const HORRY = {
  name: 'Horry', mtfcc: 'X0061',
  service: 'https://services1.arcgis.com/If0JkGr8ABreBTuS/arcgis/rest/services/CurrentCouncilDistricts/FeatureServer/0',
  field: 'District',
  // the three names that date this layer as the pre-2022 plan
  supersededBy: [[1, 'Worley'], [7, 'Bellamy'], [8, 'Vaught']],
};

if (!process.env.DATABASE_URL) { console.error('DATABASE_URL is not set'); process.exit(1); }
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const j = async (url) => {
  const r = await fetch(url, { headers: UA });
  const t = await r.text();
  // 🔴 A clean HTTP 200 can be an error page or an HTML login wall. Check the shape.
  if (!t.trim().startsWith('{')) throw new Error(`HTTP ${r.status}, not JSON: ${t.slice(0, 80)}`);
  const o = JSON.parse(t);
  if (o.error) throw new Error(`ArcGIS error ${JSON.stringify(o.error).slice(0, 120)}`);
  return o;
};

const loadedPoints = async (mtfcc) =>
  (await pool.query(
    `SELECT geo_id, ST_X(ST_PointOnSurface(geometry)) AS lon, ST_Y(ST_PointOnSurface(geometry)) AS lat
       FROM essentials.geofence_boundaries WHERE mtfcc = $1 ORDER BY length(geo_id), geo_id`,
    [mtfcc],
  )).rows;

const askCounty = async (c, lon, lat) => {
  const g = encodeURIComponent(JSON.stringify({ x: Number(lon), y: Number(lat), spatialReference: { wkid: 4326 } }));
  const q = await j(`${c.service}/query?geometry=${g}&geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=${c.field}&returnGeometry=false&f=json`);
  return (q.features ?? []).map((f) => Number(String(f.attributes[c.field]).match(/\d+/)?.[0]));
};

let bad = 0;

// ── Richland: must agree, 11 of 11 ───────────────────────────────────────────
const rPts = await loadedPoints(RICHLAND.mtfcc);
if (rPts.length !== 11) { console.log(`🔴 Richland: expected 11 loaded polygons, found ${rPts.length}`); bad++; }
let rAgree = 0;
console.log(`\nRichland — against its own RC_Council_Districts (must AGREE)`);
for (const r of rPts) {
  const want = Number(r.geo_id.match(/(\d+)$/)[1]);
  const got = await askCounty(RICHLAND, r.lon, r.lat);
  const ok = got.length === 1 && got[0] === want;
  console.log(`  ${ok ? '✅' : '🔴'} ${r.geo_id} -> county says ${got.join(',') || '(nothing)'}`);
  if (ok) rAgree++; else bad++;
}
console.log(`  Richland: ${rAgree}/11 agree`);

// ── Horry: the county's layer is the SUPERSEDED map and must still look like it ───
console.log(`\nHorry — against its own "CurrentCouncilDistricts", which is the PRE-2022 map (must DIFFER)`);
const hMeta = await j(`${HORRY.service}?f=json`);
const hAll = await j(`${HORRY.service}/query?where=1%3D1&outFields=*&returnGeometry=false&f=json`);
const edited = new Date(hMeta.editingInfo.lastEditDate).toISOString().slice(0, 10);
console.log(`  layer "${hMeta.name}", last edited ${edited}, ${hAll.features.length} features`);
if (edited >= '2022-02-15') {
  console.log(`  🔴 the county layer has been edited on or after ordinance 01-2022 took effect — it may no longer be the superseded map. Re-read it before trusting this control.`);
  bad++;
}
for (const [dist, surname] of HORRY.supersededBy) {
  const f = hAll.features.find((x) => Number(x.attributes[HORRY.field]) === dist);
  const member = String(f?.attributes?.CouncilMember ?? '');
  const ok = member.includes(surname);
  console.log(`  ${ok ? '✅' : '🔴'} District ${dist} still names ${surname} — "${member}"`);
  if (!ok) bad++;
}

const hPts = await loadedPoints(HORRY.mtfcc);
if (hPts.length !== 11) { console.log(`🔴 Horry: expected 11 loaded polygons, found ${hPts.length}`); bad++; }
let differs = 0;
for (const r of hPts) {
  const want = Number(r.geo_id.match(/(\d+)$/)[1]);
  const got = await askCounty(HORRY, r.lon, r.lat);
  const same = got.length === 1 && got[0] === want;
  if (!same) differs++;
  console.log(`  ${same ? '·' : '≠'} ${r.geo_id} -> superseded layer says ${got.join(',') || '(nothing)'}`);
}
console.log(`  Horry: the superseded map differs on ${differs} of 11 internal points`);
if (differs === 0) {
  console.log('  🔴 IT DIFFERS ON NOTHING — the loaded map would then BE the pre-2022 plan. Stop and re-read the source.');
  bad++;
}

console.log(`\n${bad ? `🔴 ${bad} problem(s).` : '✅ Richland agrees 11/11; Horry differs from the superseded plan as a 2022 remap must.'}`);
await pool.end();
process.exit(bad ? 1 : 0);
