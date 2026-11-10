#!/usr/bin/env node
/**
 * CC_0376-fetch-nh-exec-arcgis.mjs — New Hampshire's five Executive Council districts
 * -> one GeoJSON geometry per district, for CC_0376-nh-exec-geofences.mjs.
 *
 * PROVENANCE. NHGRANIT is New Hampshire's statewide GIS clearinghouse, run by the Earth Systems
 *   Research Center at the University of New Hampshire under the state's GRANIT programme. The
 *   service "APB_ElectoralDistricts" holds the state's electoral plans:
 *     https://nhgeodata.unh.edu/hosting/rest/services/Hosted/APB_ElectoralDistricts/FeatureServer
 *
 * 🔴🔴 THE DECOY IS IN THE SAME SERVICE, AND ONLY THE YEAR TELLS THEM APART.
 *   layer 1 is `NHExecCo2012` — the SUPERSEDED map, drawn on the 2010 census.
 *   layer 7 is `NHExecDists2022` — the map in force.
 *   Both hold five polygons covering the whole state, both report the same extent to the
 *   millimetre, and neither carries a description. Nothing but the layer NAME distinguishes
 *   them, and a wrong index returns a complete, valid, plausible five-district map of New
 *   Hampshire that is a decade out of date. So this script reads BOTH layers' names from the
 *   service and refuses unless layer 7 is the 2022 plan AND layer 1 is still the 2012 one — the
 *   second half matters because if the service is ever renumbered, finding the 2022 name at
 *   index 7 by luck is exactly the failure that check is for.
 *
 * WHICH PLAN IS IN FORCE, AND THE ACT PASSED. RSA 662:2 "Councilor Districts", source line
 *   "2022, 46:1, eff. May 6, 2022" — chapter 46 of the 2022 session laws, SB 241, signed
 *   6 May 2022, replacing the 2012 map (2012, 170:1). The RSA carries no later amendment;
 *   CC_0376-parse-nh-council-statute.mjs asserts that, and refuses if one appears.
 *   ⚠ New Hampshire's 2022 CONGRESSIONAL map went to the state Supreme Court (case 2022-0184)
 *   and is a different plan under RSA 662:1. The councilor map was signed and was not before
 *   that court. Checked rather than assumed, because "the state was in redistricting litigation
 *   in 2022" is true and says nothing about THIS map.
 *
 * 🔴🔴 THE CRS TRAP IS LIVE HERE AND IS THE WORST OF THE SERIES SO FAR. The layer's native
 *   spatial reference is wkid 102710 / latestWkid 3437 — NAD83 New Hampshire State Plane, in
 *   US SURVEY FEET — with extent x 745,474..1,267,014 and y 72,030..1,023,284. Loaded as 4326
 *   that is a valid, correctly shaped, entirely wrong map matching no address on Earth: the
 *   Holladay failure exactly. The query carries outSR=4326 so the SERVER reprojects, and every
 *   coordinate is bounds-checked against New Hampshire here, at parse time, before anything is
 *   written. The loader checks the bounding boxes again after INSERT.
 *
 * ⚠ THERE IS NO POPULATION FIELD. The Nebraska and Texas fetchers could self-identify a plan by
 *   summing district populations to the state's census total; this layer carries only
 *   `execco2022`, an object id and shape measurements. The plan's identity is established
 *   instead by the statute join in CC_0376-parse-nh-council-statute.mjs, which is a stronger
 *   test than a population sum: 259 towns, each named by the act, each with a Census internal
 *   point, all of which must land in the right polygon.
 *
 * 🔴 NOTHING IS DROPPED SILENTLY: holes and multi-part districts are carried through, and the
 *   parser refuses a ring it cannot close, a non-numeric coordinate, or a district it cannot
 *   number.
 *
 * The ArcGIS responses are downloaded, untrusted data: read as text, parsed as JSON, nothing in
 * them executed. Raw responses are written beside the output and each one's sha256 is printed.
 *
 * Usage (from backend/):
 *   node scripts/CC_0376-fetch-nh-exec-arcgis.mjs <outdir> <out.json> [--offline] [--layer N]
 *
 *   --layer N  reads a different layer index. It exists for ONE purpose: control B below plants
 *              the 2012 decoy by passing --layer 1 and the run must fail on the layer name.
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const argv = process.argv.slice(2);
const OFFLINE = argv.includes('--offline');
const li = argv.indexOf('--layer');
const LAYER = li > -1 ? Number(argv[li + 1]) : 7;
const positional = argv.filter((a, i) => !a.startsWith('--') && !(li > -1 && i === li + 1));
const [OUTDIR, OUT] = positional;
if (!OUTDIR || !OUT) throw new Error('usage: CC_0376-fetch-nh-exec-arcgis.mjs <outdir> <out.json> [--offline] [--layer N]');

const SERVICE = 'https://nhgeodata.unh.edu/hosting/rest/services/Hosted/APB_ElectoralDistricts/FeatureServer';
const UA = 'ev-accounts/1.0 (New Hampshire Executive Council district import)';

const EXPECT_LAYER = 7;
const EXPECT_NAME = 'NHExecDists2022';
const DECOY_LAYER = 1;
const DECOY_NAME = 'NHExecCo2012';
const FIELD = 'execco2022';
const COUNT = 5;

// New Hampshire is -72.557..-70.703 east-west and 42.697..45.305 north-south. Generous, and a
// State Plane foot coordinate is in the hundreds of thousands, so it fails on the first point.
const LON_MIN = -72.8, LON_MAX = -70.4, LAT_MIN = 42.5, LAT_MAX = 45.5;

fs.mkdirSync(OUTDIR, { recursive: true });

// --------------------------------------------------------- the layer names, before any geometry
const metaFile = path.join(OUTDIR, `layer-${LAYER}.json`);
const decoyFile = path.join(OUTDIR, `layer-${DECOY_LAYER}.json`);
if (!OFFLINE) {
  for (const [l, f] of [[LAYER, metaFile], [DECOY_LAYER, decoyFile]]) {
    const r = await fetch(`${SERVICE}/${l}?f=json`, { headers: { 'User-Agent': UA } });
    if (!r.ok) throw new Error(`layer ${l}: ArcGIS returned HTTP ${r.status}`);
    const body = await r.text();
    if (!body.trim().startsWith('{')) throw new Error(`layer ${l}: the response is not JSON (${body.slice(0, 80)}…)`);
    fs.writeFileSync(f, body);
  }
}
const meta = JSON.parse(fs.readFileSync(metaFile, 'utf8'));
const decoy = JSON.parse(fs.readFileSync(decoyFile, 'utf8'));

if (meta.name !== EXPECT_NAME) {
  throw new Error(
    `layer ${LAYER} is named "${meta.name}", not "${EXPECT_NAME}". ` +
    (meta.name === DECOY_NAME
      ? `That is the SUPERSEDED 2012 councilor map — five valid polygons covering the whole state, ` +
        `drawn on the 2010 census. It is not the plan in force.`
      : `The service has been renumbered; enumerate it rather than guessing an index.`));
}
if (decoy.name !== DECOY_NAME) {
  throw new Error(
    `layer ${DECOY_LAYER} is named "${decoy.name}", not "${DECOY_NAME}" — the service has been ` +
    `renumbered, so finding "${EXPECT_NAME}" at index ${LAYER} may be luck. Re-enumerate the service.`);
}
const fieldNames = (meta.fields ?? []).map(f => f.name);
if (!fieldNames.includes(FIELD)) {
  throw new Error(`layer ${LAYER} has no "${FIELD}" field — it carries ${fieldNames.join(', ')}`);
}
const nativeWkid = meta.extent?.spatialReference?.latestWkid ?? meta.extent?.spatialReference?.wkid;
console.log(`layer ${LAYER} is "${meta.name}" (layer ${DECOY_LAYER} is "${decoy.name}", the superseded map)`);
console.log(`  native SR ${nativeWkid} — NAD83 New Hampshire State Plane in US survey feet; asking the server for 4326`);

// --------------------------------------------------------- the geometry
const url = d => `${SERVICE}/${LAYER}/query?where=${encodeURIComponent(`${FIELD}=${d}`)}` +
  `&outFields=${FIELD}&returnGeometry=true&outSR=4326&f=geojson&geometryPrecision=7`;

const districts = [];
for (let d = 1; d <= COUNT; d++) {
  const file = path.join(OUTDIR, `d${d}.geojson`);
  if (!OFFLINE) {
    const r = await fetch(url(d), { headers: { 'User-Agent': UA } });
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
  const num = Number(f.properties?.[FIELD]);
  if (num !== d) throw new Error(`District ${d}: the feature says ${FIELD}=${f.properties?.[FIELD]}`);

  const g = f.geometry;
  if (!g || (g.type !== 'Polygon' && g.type !== 'MultiPolygon')) {
    throw new Error(`District ${d}: geometry is ${g?.type}, expected Polygon or MultiPolygon`);
  }
  const parts = g.type === 'Polygon' ? [g.coordinates] : g.coordinates;
  if (!parts.length) throw new Error(`District ${d}: no polygon parts`);

  let points = 0, rings = 0, holes = 0;
  let minLon = Infinity, maxLon = -Infinity, minLat = Infinity, maxLat = -Infinity;
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
        // 🔴 THE CRS CHECK, AT THE POINT OF PARSING. The service is State Plane FEET; this is
        //    what stands between an outSR that silently did nothing and the Holladay failure.
        if (lon < LON_MIN || lon > LON_MAX || lat < LAT_MIN || lat > LAT_MAX) {
          throw new Error(
            `District ${d}: ${lon},${lat} is outside the New Hampshire bounding box — wrong CRS ` +
            `or wrong file. The layer is native wkid ${nativeWkid} (US survey feet); a State Plane ` +
            `coordinate lands in the hundreds of thousands.`);
        }
        if (lon < minLon) minLon = lon;
        if (lon > maxLon) maxLon = lon;
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        points++;
      }
      const a = ring[0], b = ring[ring.length - 1];
      if (a[0] !== b[0] || a[1] !== b[1]) throw new Error(`District ${d}: a ring is not closed`);
    }
  }

  districts.push({
    district: d, parts: parts.length, rings, holes, points, sha256: sha,
    bbox: [minLon, minLat, maxLon, maxLat], geojson: g,
  });
  console.log(`  District ${d}: ${String(points).padStart(6)} points · ${parts.length} part(s) · ${holes} hole(s) · ` +
    `bbox ${minLon.toFixed(3)},${minLat.toFixed(3)}..${maxLon.toFixed(3)},${maxLat.toFixed(3)} · sha256 ${sha.slice(0, 16)}`);
}

if (districts.length !== COUNT) throw new Error(`expected ${COUNT} districts, built ${districts.length}`);
// The five together must span the state; a single district's bbox cannot.
const all = districts.reduce((a, d) => [
  Math.min(a[0], d.bbox[0]), Math.min(a[1], d.bbox[1]), Math.max(a[2], d.bbox[2]), Math.max(a[3], d.bbox[3]),
], [Infinity, Infinity, -Infinity, -Infinity]);
if (!(all[0] < -72.4 && all[2] > -71.0 && all[1] < 43.0 && all[3] > 45.0)) {
  throw new Error(`the five districts together span ${JSON.stringify(all)}, which does not cover New Hampshire`);
}

fs.writeFileSync(OUT, JSON.stringify({
  body: 'New Hampshire Executive Council',
  label: 'Executive Councilor',
  source: `NHGRANIT / University of New Hampshire (nhgeodata.unh.edu), service APB_ElectoralDistricts, ` +
    `layer ${LAYER} "${meta.name}" — the councilor districts enacted by 2022 N.H. Laws ch. 46 (SB 241), ` +
    `RSA 662:2, eff. 6 May 2022. Queried ${new Date().toISOString().slice(0, 10)} with outSR=4326`,
  serviceUrl: `${SERVICE}/${LAYER}/query`,
  layer: LAYER, layerName: meta.name, field: FIELD,
  supersededLayer: `${DECOY_LAYER} "${decoy.name}"`,
  act: 'RSA 662:2, as amended by 2022 N.H. Laws ch. 46 (SB 241), eff. May 6, 2022',
  crs: `EPSG:4326, requested via outSR from a service whose native SR is ${nativeWkid} ` +
    `(NAD83 New Hampshire State Plane, US survey feet), and bounds-checked against New Hampshire`,
  bbox: all,
  districts,
}));

console.log(`${districts.length} districts · ${districts.reduce((s, d) => s + d.points, 0)} points · ` +
  `${(fs.statSync(OUT).size / 1e6).toFixed(2)} MB · union bbox ${all.map(n => n.toFixed(3)).join(', ')}`);
