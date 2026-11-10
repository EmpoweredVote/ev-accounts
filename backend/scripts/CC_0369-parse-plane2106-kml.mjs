#!/usr/bin/env node
/**
 * CC_0369-parse-plane2106-kml.mjs — the Texas Legislative Council's PlanE2106 KML
 * -> one GeoJSON Polygon per State Board of Education district, for CC_0369-tx-sboe-geofences.mjs.
 *
 * PROVENANCE. Capitol Data Portal dataset `plane2106`, titled
 *   "PLANE2106 — STATE BOARD OF EDUCATION DISTRICTS, JANUARY 2023".
 *   It is the plan in force: the portal carries exactly four SBOE plans and the other three say
 *   so in their own titles ("2013-2022" twice, "2003-2012"). Texas's 2025 mid-decade redistricting
 *   did not redraw the SBOE map.
 *     https://data.capitol.texas.gov/api/3/action/package_show?id=plane2106
 *   KML archive, downloaded 2026-11-07 (1,911,097 bytes,
 *     sha256 5cbe41fe5d1054b3fb0fb9ab536befcb1946a859c0d4afa7d41e3c9d38ec8978):
 *     https://data.capitol.texas.gov/dataset/ad1ae979-6df9-4322-98cf-6771cc67f02d/resource/
 *       a8a7daf2-ab21-4742-bf56-e1ab697580ea/download/plane2106_kml.zip
 *   It contains one file, PlanE2106.kml (8,743,575 bytes,
 *     sha256 a097abc64e0455b7b38b7364fc5dadb4e597009f1009530f7cb86f090cdc6d1b).
 *
 * 🔴🔴 WHY THE KML AND NOT THE SHAPEFILE IN THE SAME DATASET. PLANE2106.prj reads
 *   PROJCS["NAD_1983_Lambert_Conformal_Conic", ... PARAMETER["False_Easting",1000000.0],
 *   PARAMETER["False_Northing",1000000.0], ... UNIT["Meter",1.0]] — Texas-centric Lambert
 *   Conformal Conic in METRES. Loaded as SRID 4326 those coordinates are valid, correctly shaped
 *   polygons that match no address on Earth, which is exactly how Holladay's five wards went in
 *   (CLAUDE.md, "A POLYGON CAN BE VALID, CORRECTLY SHAPED AND IN THE WRONG CRS"). KML is WGS84
 *   lon/lat BY SPECIFICATION, so there is no projection left to get wrong — and the bounding-box
 *   check below would catch it anyway.
 *
 * The KML is downloaded, untrusted data. It is read from the path given as an argument, parsed as
 * text, and nothing in it is executed.
 *
 * Usage (from backend/):
 *   node scripts/CC_0369-parse-plane2106-kml.mjs <PlanE2106.kml> <out.json>
 */
import fs from 'node:fs';

const [, , SRC, OUT] = process.argv;
if (!SRC || !OUT) throw new Error('usage: CC_0369-parse-plane2106-kml.mjs <PlanE2106.kml> <out.json>');

const xml = fs.readFileSync(SRC, 'utf8');
// ⚠ a short or empty file parses cleanly and yields nothing, which reads as "no districts".
if (xml.length < 1_000_000) throw new Error(`the KML is only ${xml.length} bytes — too short to be PlanE2106`);

const placemarks = [...xml.matchAll(/<Placemark>([\s\S]*?)<\/Placemark>/g)].map(m => m[1]);
if (placemarks.length !== 15) throw new Error(`expected 15 placemarks, found ${placemarks.length}`);

const out = [];
for (const pm of placemarks) {
  const name = (pm.match(/<name>([^<]*)<\/name>/) || [])[1];
  const n = Number((name || '').replace(/\D+/g, ''));
  if (!Number.isInteger(n) || n < 1 || n > 15) throw new Error(`cannot read a district number from "${name}"`);

  const outers = [...pm.matchAll(/<outerBoundaryIs>\s*<LinearRing>\s*<coordinates>([\s\S]*?)<\/coordinates>/g)].map(m => m[1]);
  const inners = [...pm.matchAll(/<innerBoundaryIs>/g)];
  if (outers.length !== 1) throw new Error(`District ${n}: ${outers.length} outer rings, expected 1`);
  // 🔴 this parser drops nothing silently: if the plan ever gains a hole or a second ring, it stops.
  if (inners.length !== 0) throw new Error(`District ${n}: ${inners.length} inner ring(s) — this parser would drop them`);

  const ring = outers[0].trim().split(/\s+/).filter(Boolean).map(tok => {
    const p = tok.split(',');
    if (p.length < 2) throw new Error(`District ${n}: malformed coordinate "${tok}"`);
    const lon = Number(p[0]), lat = Number(p[1]);
    if (!Number.isFinite(lon) || !Number.isFinite(lat)) throw new Error(`District ${n}: non-numeric coordinate "${tok}"`);
    // 🔴 THE CRS CHECK, AT THE POINT OF PARSING. Texas lies well inside these bounds; a projected
    //    metre coordinate is in the millions and fails on the first point.
    if (lon < -107 || lon > -93 || lat < 25 || lat > 37) {
      throw new Error(`District ${n}: ${lon},${lat} is outside the Texas bounding box — wrong CRS or wrong file`);
    }
    return [lon, lat];
  });
  if (ring.length < 4) throw new Error(`District ${n}: ring has only ${ring.length} points`);
  const [a, b] = [ring[0], ring[ring.length - 1]];
  if (a[0] !== b[0] || a[1] !== b[1]) throw new Error(`District ${n}: ring is not closed`);

  out.push({ district: n, points: ring.length, geojson: { type: 'Polygon', coordinates: [ring] } });
}

out.sort((x, y) => x.district - y.district);
const seen = new Set(out.map(o => o.district));
for (let i = 1; i <= 15; i++) if (!seen.has(i)) throw new Error(`District ${i} is missing`);

fs.writeFileSync(OUT, JSON.stringify({
  source: 'PLANE2106 — STATE BOARD OF EDUCATION DISTRICTS, JANUARY 2023; Texas Legislative Council Capitol Data Portal, PlanE2106.kml, downloaded 2026-11-07',
  crs: 'WGS84 lon/lat (EPSG:4326) by KML specification',
  districts: out,
}));

console.log(`${out.length} districts · ${out.reduce((s, o) => s + o.points, 0)} points · ${(fs.statSync(OUT).size / 1e6).toFixed(2)} MB`);
for (const o of out) console.log(`  District ${String(o.district).padStart(2)}: ${String(o.points).padStart(6)} points`);
