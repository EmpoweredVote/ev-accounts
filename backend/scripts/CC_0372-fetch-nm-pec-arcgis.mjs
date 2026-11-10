#!/usr/bin/env node
/**
 * CC_0372-fetch-nm-pec-arcgis.mjs — New Mexico's ten Public Education Commission districts
 * -> one GeoJSON geometry per district, for CC_0372-nm-pec-geofences.mjs.
 *
 * PROVENANCE. The New Mexico Secretary of State's redistricting GIS, published by the
 *   Earth Data Analysis Center at the University of New Mexico — the same body that drew the
 *   official 2021 district map sheets for the Secretary of State. The service folder is "SOS",
 *   and layer 8 is "Public Education Commission District (PEC)":
 *     https://edacarcweb.unm.edu/arcgis/rest/services/SOS/Education/MapServer/8
 *   It is the layer the Secretary of State's own "New Mexico Political Subdivisions" web map
 *   loads (ArcGIS item 9790b79e1c1646729b370b9b3de70747, owner EDAC_staff_gen).
 *
 *   🟢 THE LAYER IS SELF-IDENTIFYING AS THE 2020-CENSUS PLAN. Its ten POPULATION values sum to
 *   2,117,522 — New Mexico's 2020 apportionment population to the person — and IDEAL_VALU is
 *   211,752, which is that number divided by ten. A map drawn on any other census cannot do
 *   that, and the check below refuses the file otherwise.
 *
 * WHICH MAP IS IN FORCE — 🔴 AND THE FIRST BILL I READ WAS NOT THE LAW. The 2021 Second Special
 *   Session filed two PEC redistricting bills, HB 6 and HB 7, and BOTH DIED; HB 6's action line
 *   reads "Action Postponed Indefinitely". The act in force is **HB 9, Laws 2021 (2nd S.S.),
 *   Chapter 3** — the 2021 Educational Redistricting Act, signed 17 December 2021. Its precinct
 *   lists are not HB 6's: HB 6 would have put Torrance county in District 8, and HB 9 puts the
 *   whole of it in District 6. ▶ A bill page is not evidence that a bill became law; read the
 *   action line. The county composition the loader gates on is parsed from HB 9's FINAL text by
 *   data/state-exec-2026-results/parse-nm-pec-statute.mjs.
 *
 * 🔴🔴 THE SERVICE IS NAD83 / UTM ZONE 13N AND WOULD BE THE HOLLADAY FAILURE IF TAKEN AS IT
 *   STANDS. MapServer reports spatialReference {wkid: 26913} — metres. The query below asks for
 *   outSR=4326 so the server reprojects, every coordinate is bounds-checked against New Mexico
 *   here, and the loader checks each bounding box again after INSERT.
 *
 * 🔴 NOTHING IS DROPPED SILENTLY: holes and multi-part districts are carried through, and the
 *   parser refuses a ring it cannot close, a non-numeric coordinate, or a district it cannot
 *   number.
 *
 * The ArcGIS responses are downloaded, untrusted data: read as text, parsed as JSON, nothing in
 * them executed. Raw responses are written beside the output and each one's sha256 is printed.
 *
 * Usage (from backend/):
 *   node scripts/CC_0372-fetch-nm-pec-arcgis.mjs <outdir> <out.json> [--offline]
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const [, , OUTDIR, OUT, ...rest] = process.argv;
if (!OUTDIR || !OUT) throw new Error('usage: CC_0372-fetch-nm-pec-arcgis.mjs <outdir> <out.json> [--offline]');
const OFFLINE = rest.includes('--offline');

const SERVICE = 'https://edacarcweb.unm.edu/arcgis/rest/services/SOS/Education/MapServer/8/query';

// New Mexico is -109.05..-103.00, 31.33..37.00. A generous box; a UTM metre coordinate is in the
// hundreds of thousands to millions and fails on the first point.
const LON_MIN = -110, LON_MAX = -102, LAT_MIN = 30.5, LAT_MAX = 37.5;

const STATE_POP_2020 = 2_117_522;
const IDEAL = 211_752;

fs.mkdirSync(OUTDIR, { recursive: true });

const url = d => `${SERVICE}?where=${encodeURIComponent(`DISTRICT='${d}'`)}` +
  '&outFields=DISTRICT,POPULATION&returnGeometry=true&outSR=4326&f=geojson&geometryPrecision=7';

const districts = [];
let totalPop = 0;

for (let d = 1; d <= 10; d++) {
  const file = path.join(OUTDIR, `d${d}.geojson`);
  if (!OFFLINE) {
    const r = await fetch(url(d), { headers: { 'User-Agent': 'ev-accounts/1.0 (public education commission district import)' } });
    if (!r.ok) throw new Error(`District ${d}: ArcGIS returned HTTP ${r.status}`);
    fs.writeFileSync(file, await r.text());
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
          throw new Error(`District ${d}: ${lon},${lat} is outside the New Mexico bounding box — wrong CRS or wrong file`);
        }
        points++;
      }
      const a = ring[0], b = ring[ring.length - 1];
      if (a[0] !== b[0] || a[1] !== b[1]) throw new Error(`District ${d}: a ring is not closed`);
    }
  }

  districts.push({ district: d, population: pop, parts: parts.length, rings, holes, points, sha256: sha, geojson: g });
  console.log(`  District ${String(d).padStart(2)}: ${String(points).padStart(6)} points · ${parts.length} part(s) · ${holes} hole(s) · pop ${pop} · sha256 ${sha.slice(0, 16)}`);
}

if (districts.length !== 10) throw new Error(`expected 10 districts, built ${districts.length}`);
if (totalPop !== STATE_POP_2020) {
  throw new Error(`the ten districts hold ${totalPop} people, not New Mexico's 2020 population ${STATE_POP_2020}`);
}
const worst = Math.max(...districts.map(d => Math.abs(d.population - IDEAL) / IDEAL));
if (!(worst < 0.06)) throw new Error(`worst population deviation is ${(worst * 100).toFixed(2)}% — not a one-person-one-vote plan`);

fs.writeFileSync(OUT, JSON.stringify({
  source: 'New Mexico Secretary of State redistricting GIS, published by UNM\'s Earth Data Analysis ' +
    'Center: SOS/Education/MapServer layer 8, "Public Education Commission District (PEC)" — the ' +
    'HB 9 (Laws 2021 2nd S.S. Ch. 3) plan. Queried 2026-11-07 with outSR=4326',
  serviceUrl: SERVICE,
  crs: 'EPSG:4326, requested from a NAD83 / UTM 13N (EPSG:26913) service via outSR and bounds-checked against New Mexico',
  totalPopulation: totalPop,
  idealDistrict: IDEAL,
  districts,
}));

console.log(`${districts.length} districts · ${districts.reduce((s, d) => s + d.points, 0)} points · ` +
  `${(fs.statSync(OUT).size / 1e6).toFixed(2)} MB · population ${totalPop} (2020 census, ideal ${IDEAL}, ` +
  `worst deviation ${(worst * 100).toFixed(2)}%)`);
