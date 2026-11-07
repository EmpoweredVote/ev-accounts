#!/usr/bin/env node
/**
 * CC_0371-parse-la-psc-kml.mjs — the Louisiana Legislature's HB2_PSC_221ES KML
 * -> one GeoJSON Polygon per Public Service Commission district, for CC_0371-la-psc-geofences.mjs.
 *
 * PROVENANCE. Louisiana House/Senate redistricting site, redist.legis.la.gov, under
 *   "Public Service Commission ACT 2 (HB2)" — the plan adopted by **Act 2 (HB2) of the 2022 First
 *   Extraordinary Session**, which is the PSC map in force. Downloaded 2026-11-07:
 *     https://redist.legis.la.gov/2023_07/Adopted%20Plans%20From%20the%202022%201st%20Extraordinary
 *       %20Session/Public%20Service%20Commssion/Shapefiles%20and%20KML%20Files/HB2_PSC_221ES%20KML.zip
 *       (523,915 bytes,
 *        sha256 df0525de5684f6be20ee0dff1e2e51619549f4d97289eeb479a9806b5149745d)
 *   It contains one file, HB2_PSC_221ES.kml (1,849,865 bytes,
 *     sha256 a783429da68b9ce5acd157973b08ef2a1320687591b1d3fc7b26c6c47d957140).
 *   ⚠ The directory name is spelled "Commssion" on the Legislature's server. That is their typo,
 *     not one here; the URL only works with it.
 *
 * WHICH MAP IS IN FORCE. Louisiana's 2026 Regular Session did redistrict — but **congressional**
 *   districts (SB121, Act 2 of 2026, by Sen. Jay Morris), and the other eight plans filed that
 *   session were congressional, House or Senate. None touched the PSC. Checked bill by bill on
 *   legis.la.gov, 2026-11-07: SB116, SB117, SB130 congress; SB136 senate; HB640, HB698, HB700
 *   house; HB642 congress. The PSC map is still Act 2 of 2022.
 *
 * 🟢 THE SHAPEFILE IN THE SAME FOLDER IS *NOT* A CRS TRAP HERE, AND THAT WAS READ, NOT ASSUMED.
 *   HB2_PSC_221ES.prj reads
 *     GEOGCS["GCS_North_American_1983", DATUM["D_North_American_1983",
 *       SPHEROID["GRS_1980",6378137,298.257222101]], PRIMEM["Greenwich",0],
 *       UNIT["Degree",0.017453292519943295]]
 *   — geographic degrees on NAD83, not a projected plane. Texas's PLANE2106.prj in the same role
 *   was Lambert Conformal Conic in METRES, which loaded as 4326 is the Holladay failure. **Same
 *   kind of file, opposite answer: read the .prj every time.** The KML is used anyway, because
 *   KML is WGS84 lon/lat by specification and leaves nothing to decide, and every coordinate is
 *   bounds-checked against Louisiana below.
 *
 * 🔴 NOTHING IS DROPPED SILENTLY. All five districts are a single outer ring with no holes; the
 *   parser refuses a second ring, an inner ring, an unclosed ring or a district it cannot number.
 *
 * The KML is downloaded, untrusted data. It is read from the path given as an argument, parsed as
 * text, and nothing in it is executed.
 *
 * Usage (from backend/):
 *   node scripts/CC_0371-parse-la-psc-kml.mjs <HB2_PSC_221ES.kml> <out.json>
 */
import fs from 'node:fs';

const [, , SRC, OUT] = process.argv;
if (!SRC || !OUT) throw new Error('usage: CC_0371-parse-la-psc-kml.mjs <HB2_PSC_221ES.kml> <out.json>');

// Louisiana is -94.04..-88.76, 28.86..33.02. A generous box: a projected metre coordinate is in
// the millions and fails on the first point.
const LON_MIN = -95, LON_MAX = -88, LAT_MIN = 28, LAT_MAX = 34;

const xml = fs.readFileSync(SRC, 'utf8');
// ⚠ a short or empty file parses cleanly and yields nothing, which reads as "no districts".
if (xml.length < 1_000_000) throw new Error(`the KML is only ${xml.length} bytes — too short to be HB2_PSC_221ES`);

const placemarks = [...xml.matchAll(/<Placemark>([\s\S]*?)<\/Placemark>/g)].map(m => m[1]);
if (placemarks.length !== 5) throw new Error(`expected 5 placemarks, found ${placemarks.length}`);

const out = [];
for (const pm of placemarks) {
  const name = (pm.match(/<name>([^<]*)<\/name>/) || [])[1];
  const m = (name || '').match(/^District (\d)$/);
  if (!m) throw new Error(`cannot read a district number from "${name}"`);
  const n = Number(m[1]);
  if (!(n >= 1 && n <= 5)) throw new Error(`district ${n} is out of range`);

  const outers = [...pm.matchAll(/<outerBoundaryIs>\s*<LinearRing>\s*<coordinates>([\s\S]*?)<\/coordinates>/g)].map(x => x[1]);
  const inners = [...pm.matchAll(/<innerBoundaryIs>/g)];
  if (outers.length !== 1) throw new Error(`District ${n}: ${outers.length} outer rings, expected 1`);
  if (inners.length !== 0) throw new Error(`District ${n}: ${inners.length} inner ring(s) — this parser would drop them`);

  const ring = outers[0].trim().split(/\s+/).filter(Boolean).map(tok => {
    const p = tok.split(',');
    if (p.length < 2) throw new Error(`District ${n}: malformed coordinate "${tok}"`);
    const lon = Number(p[0]), lat = Number(p[1]);
    if (!Number.isFinite(lon) || !Number.isFinite(lat)) throw new Error(`District ${n}: non-numeric coordinate "${tok}"`);
    // 🔴 THE CRS CHECK, AT THE POINT OF PARSING.
    if (lon < LON_MIN || lon > LON_MAX || lat < LAT_MIN || lat > LAT_MAX) {
      throw new Error(`District ${n}: ${lon},${lat} is outside the Louisiana bounding box — wrong CRS or wrong file`);
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
for (let i = 1; i <= 5; i++) if (!seen.has(i)) throw new Error(`District ${i} is missing`);

fs.writeFileSync(OUT, JSON.stringify({
  source: 'HB2_PSC_221ES — Louisiana Public Service Commission districts, Act 2 (HB2) of the 2022 ' +
    'First Extraordinary Session; Louisiana Legislature redistricting site, KML, downloaded 2026-11-07',
  crs: 'WGS84 lon/lat (EPSG:4326) by KML specification',
  districts: out,
}));

console.log(`${out.length} districts · ${out.reduce((s, o) => s + o.points, 0)} points · ${(fs.statSync(OUT).size / 1e6).toFixed(2)} MB`);
for (const o of out) console.log(`  District ${o.district}: ${String(o.points).padStart(6)} points`);
