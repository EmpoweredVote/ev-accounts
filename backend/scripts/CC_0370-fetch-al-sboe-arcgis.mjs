#!/usr/bin/env node
/**
 * CC_0370-fetch-al-sboe-arcgis.mjs — Alabama's eight State Board of Education districts
 * -> one GeoJSON geometry per district, for CC_0370-al-sboe-geofences.mjs.
 *
 * PROVENANCE. The Alabama Legislature's Legislative Reapportionment Office publishes its plans
 *   as an ArcGIS Online feature service. The same organisation (tenant jF2q3LPxL7PETdYk) carries
 *   2021_Alabama_House_Plan, 2021_Alabama_Senate_Plan, 2021_Alabama_Congressional_Plan and
 *   2023_Court_Ordered_Congressional_Plan, which is what identifies it: these are the
 *   Reapportionment Office's own plan layers, not a third party's copy.
 *     service: _2021_Alabama_State_Bd_of_Education (ArcGIS item 4b687a30715343e792faafc297c3b4ab,
 *              "This is the newly passed State Board of Education Districts following the
 *              2020 Census", created 2021-11-10)
 *     https://services7.arcgis.com/jF2q3LPxL7PETdYk/ArcGIS/rest/services/
 *       _2021_Alabama_State_Bd_of_Education/FeatureServer/0
 *
 *   🟢 THE LAYER IS SELF-IDENTIFYING AS THE 2020-CENSUS PLAN. Its eight POPULATION values sum to
 *   5,024,279 — Alabama's 2020 apportionment population to the person — and its IDEAL_VALU is
 *   628,035, which is that number divided by eight. A map drawn on any other census cannot do
 *   that. The loader does not rely on this; it is why this service was chosen over the two
 *   unattributed copies of the same plan that also sit on ArcGIS Online.
 *
 * WHICH MAP IS IN FORCE. The plan was enacted in the 2021 First Special Session as the
 *   "McClendon SBOE Plan 1" and is the whole of Code of Alabama § 16-3-1.1. Alabama redistricts
 *   only in the first session after each decennial census (Const. 1901, Art. IX §§ 197-200), the
 *   next being after the 2030 census; the 2023 remedial litigation redrew the CONGRESSIONAL map
 *   and, separately, state Senate districts, and left the board map alone. It took effect for the
 *   2022 board elections and governed the 2026 ones.
 *   ⚠ The Legislature's own page /reapportionment-board-education-state-map is STALE — it still
 *     offers "Board of Education State Map: 2011 State Education Districts". A source can be
 *     authoritative for one field and out of date for another; the operative text is the statute.
 *
 * 🔴🔴 THE SERVICE IS WEB MERCATOR AND WOULD BE THE HOLLADAY FAILURE IF TAKEN AS IT STANDS.
 *   FeatureServer/0 reports spatialReference {wkid: 102100, latestWkid: 3857} and its own extent
 *   is -9848795, 3522128 .. -9449716, 4164973 — metres. Served as SRID 4326 those numbers make
 *   valid, correctly shaped polygons that match no address on Earth. The query below asks for
 *   outSR=4326, so the server reprojects, and every coordinate is then bounds-checked against
 *   Alabama here and the bounding box is checked again after INSERT in the loader.
 *
 * 🔴 NOTHING IS DROPPED SILENTLY. District 6 has one interior ring (a hole) and District 8 is a
 *   two-part MultiPolygon; both are carried through. The parser refuses a ring it cannot close,
 *   a non-numeric coordinate, or a district it cannot number.
 *
 * The ArcGIS responses are downloaded, untrusted data. They are read as text, parsed as JSON,
 * and nothing in them is executed. Raw responses are written beside the output so the run can be
 * audited, and each one's sha256 is printed.
 *
 * Usage (from backend/):
 *   node scripts/CC_0370-fetch-al-sboe-arcgis.mjs <outdir> <out.json>
 *     # <outdir> also receives the eight raw ArcGIS responses, d1.geojson .. d8.geojson
 *   node scripts/CC_0370-fetch-al-sboe-arcgis.mjs <outdir> <out.json> --offline
 *     # re-parse the raw responses already in <outdir>, fetching nothing
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const [, , OUTDIR, OUT, ...rest] = process.argv;
if (!OUTDIR || !OUT) throw new Error('usage: CC_0370-fetch-al-sboe-arcgis.mjs <outdir> <out.json> [--offline]');
const OFFLINE = rest.includes('--offline');

const SERVICE = 'https://services7.arcgis.com/jF2q3LPxL7PETdYk/ArcGIS/rest/services/' +
  '_2021_Alabama_State_Bd_of_Education/FeatureServer/0/query';

// Alabama is -88.47..-84.89, 30.14..35.01. A generous box: a Web Mercator metre coordinate is in
// the millions and fails on the first point, and a lon/lat from any other state fails too.
const LON_MIN = -89, LON_MAX = -84.5, LAT_MIN = 29.5, LAT_MAX = 35.5;

// The 2020 apportionment population of Alabama, and the plan's own ideal district size.
const STATE_POP_2020 = 5_024_279;
const IDEAL = 628_035;

fs.mkdirSync(OUTDIR, { recursive: true });

const url = d => `${SERVICE}?where=${encodeURIComponent(`DISTRICT='${d}'`)}` +
  '&outFields=DISTRICT,POPULATION&returnGeometry=true&outSR=4326&f=geojson&geometryPrecision=7';

const districts = [];
let totalPop = 0;

for (let d = 1; d <= 8; d++) {
  const file = path.join(OUTDIR, `d${d}.geojson`);
  if (!OFFLINE) {
    const r = await fetch(url(d), { headers: { 'User-Agent': 'ev-accounts/1.0 (state board of education district import)' } });
    // ⚠ never judge a fetch by r.ok alone, but a non-200 here is still a hard stop.
    if (!r.ok) throw new Error(`District ${d}: ArcGIS returned HTTP ${r.status}`);
    const body = await r.text();
    // A WAF challenge or an ArcGIS error document is HTML or an {error:...} object, not a
    // FeatureCollection. Both are caught below when the shape is checked.
    fs.writeFileSync(file, body);
  }
  if (!fs.existsSync(file)) throw new Error(`District ${d}: ${file} does not exist — run without --offline`);

  const raw = fs.readFileSync(file, 'utf8');
  const sha = crypto.createHash('sha256').update(raw).digest('hex');
  let fc;
  try { fc = JSON.parse(raw); } catch { throw new Error(`District ${d}: the response is not JSON (${raw.slice(0, 80)}…)`); }
  if (fc.error) throw new Error(`District ${d}: ArcGIS error ${JSON.stringify(fc.error).slice(0, 200)}`);
  if (fc.exceededTransferLimit) throw new Error(`District ${d}: ArcGIS truncated the response`);
  if (fc.type !== 'FeatureCollection' || !Array.isArray(fc.features)) {
    throw new Error(`District ${d}: the response is not a FeatureCollection`);
  }
  if (fc.features.length !== 1) throw new Error(`District ${d}: ${fc.features.length} features, expected 1`);

  const f = fc.features[0];
  const num = Number(f.properties?.DISTRICT);
  if (num !== d) throw new Error(`District ${d}: the feature says DISTRICT=${f.properties?.DISTRICT}`);
  const pop = Number(f.properties?.POPULATION);
  if (!Number.isFinite(pop) || pop <= 0) throw new Error(`District ${d}: POPULATION is ${f.properties?.POPULATION}`);
  totalPop += pop;

  const g = f.geometry;
  if (!g || (g.type !== 'Polygon' && g.type !== 'MultiPolygon')) {
    throw new Error(`District ${d}: geometry is ${g?.type}, expected Polygon or MultiPolygon`);
  }
  const parts = g.type === 'Polygon' ? [g.coordinates] : g.coordinates;
  if (!parts.length) throw new Error(`District ${d}: no polygon parts`);

  let points = 0, rings = 0, holes = 0;
  for (const part of parts) {
    if (!part.length) throw new Error(`District ${d}: a polygon part has no rings`);
    rings += part.length;
    holes += part.length - 1;
    for (const ring of part) {
      if (ring.length < 4) throw new Error(`District ${d}: a ring has only ${ring.length} points`);
      for (const pt of ring) {
        if (!Array.isArray(pt) || pt.length < 2) throw new Error(`District ${d}: malformed coordinate ${JSON.stringify(pt)}`);
        const [lon, lat] = pt;
        if (!Number.isFinite(lon) || !Number.isFinite(lat)) throw new Error(`District ${d}: non-numeric coordinate ${JSON.stringify(pt)}`);
        // 🔴 THE CRS CHECK, AT THE POINT OF PARSING.
        if (lon < LON_MIN || lon > LON_MAX || lat < LAT_MIN || lat > LAT_MAX) {
          throw new Error(`District ${d}: ${lon},${lat} is outside the Alabama bounding box — wrong CRS or wrong file`);
        }
        points++;
      }
      const a = ring[0], b = ring[ring.length - 1];
      if (a[0] !== b[0] || a[1] !== b[1]) throw new Error(`District ${d}: a ring is not closed`);
    }
  }

  districts.push({ district: d, population: pop, parts: parts.length, rings, holes, points, sha256: sha, geojson: g });
  console.log(`  District ${d}: ${String(points).padStart(6)} points · ${parts.length} part(s) · ${holes} hole(s) · pop ${pop} · sha256 ${sha.slice(0, 16)}`);
}

if (districts.length !== 8) throw new Error(`expected 8 districts, built ${districts.length}`);
// 🟢 the positive identification of the plan: it is drawn on the 2020 census and on nothing else.
if (totalPop !== STATE_POP_2020) {
  throw new Error(`the eight districts hold ${totalPop} people, not Alabama's 2020 population ${STATE_POP_2020}`);
}
const worst = Math.max(...districts.map(d => Math.abs(d.population - IDEAL) / IDEAL));
if (!(worst < 0.06)) throw new Error(`worst population deviation is ${(worst * 100).toFixed(2)}% — not a one-person-one-vote plan`);

fs.writeFileSync(OUT, JSON.stringify({
  source: 'Alabama Legislative Reapportionment Office, ArcGIS feature service ' +
    '_2021_Alabama_State_Bd_of_Education (the 2021 plan, Code of Alabama § 16-3-1.1), ' +
    'queried 2026-11-07 with outSR=4326',
  serviceUrl: SERVICE,
  crs: 'EPSG:4326, requested from a Web Mercator (EPSG:3857) service via outSR and bounds-checked against Alabama',
  totalPopulation: totalPop,
  idealDistrict: IDEAL,
  districts,
}));

console.log(`${districts.length} districts · ${districts.reduce((s, d) => s + d.points, 0)} points · ` +
  `${(fs.statSync(OUT).size / 1e6).toFixed(2)} MB · population ${totalPop} (2020 census, ideal ${IDEAL}, ` +
  `worst deviation ${(worst * 100).toFixed(2)}%)`);
