#!/usr/bin/env node
/**
 * CC_0373-fetch-ne-boards-arcgis.mjs — Nebraska's three elected statewide boards
 * -> one GeoJSON geometry per district, for the three loaders below. One fetcher serves all
 *    three bodies because one ArcGIS service holds all three plans; it carries the first of the
 *    three slot numbers.
 *
 *   --body psc      5 Public Service Commissioner districts   (layer 3) -> CC_0373
 *   --body sboe     8 State Board of Education districts      (layer 6) -> CC_0374
 *   --body regents  8 University of Nebraska Regent districts (layer 5) -> CC_0375
 *
 * PROVENANCE. gis.ne.gov is the State of Nebraska's own enterprise GIS. The service
 *   "PoliticalBoundaries_2021" holds the six plans the Legislature enacted in the 2021 First
 *   Special Session, published by the Legislative Research Office:
 *     https://gis.ne.gov/Enterprise/rest/services/PoliticalBoundaries_2021/FeatureServer
 *   🔴 THE LAYER INDEX IS ENUMERATED, NEVER GUESSED. The service's own layer list reads
 *     1 USCongress_2021 · 2 SupremeCourt_2021 · 3 PublicServiceCommision_2021 (their spelling)
 *     · 4 Legislature_2021 · 5 BoardofRegents_2021 · 6 BoardofEducation_2021.
 *     Regents is 5 and Board of Education is 6, and the two are NOT the same map — see below.
 *
 * WHICH PLAN IS IN FORCE, AND IT PASSED. Three separate acts of the 2021 First Special Session,
 *   each approved by the Governor on 30 September 2021, and each printed as a slip law:
 *     - LB 5  -> Neb. Rev. Stat. 75-101.01,  five  public service commissioner districts,
 *               maps PSC21-39001 … PSC21-39001-5.
 *     - LB 7  -> Neb. Rev. Stat. 79-311,     eight State Board of Education districts,
 *               maps ED21-39003 … ED21-39003-8.
 *     - LB 8  -> Neb. Rev. Stat. 85-103.01,  eight Board of Regents districts,
 *               maps REG21-39003 … REG21-39003-8.
 *   🔴 ALL THREE SET THEIR BOUNDARIES "BY THE ADOPTION OF MAPS BY REFERENCE" AND LIST NO
 *   COUNTIES. There is no statutory county text to gate on, the way Alabama, Louisiana and New
 *   Mexico had. The composition gate is built instead from the Secretary of State's official
 *   canvass books — which counties actually cast votes in each district's race — by
 *   data/state-exec-2026-results/parse-ne-canvass-counties.mjs. See that file.
 *
 * 🔴🔴 THE SERVICE IS WEB MERCATOR AND WOULD BE THE HOLLADAY FAILURE IF TAKEN AS IT STANDS.
 *   The FeatureServer reports spatialReference {wkid: 102100, latestWkid: 3857} — metres. The
 *   query below asks for outSR=4326 so the server reprojects; every coordinate is bounds-checked
 *   against Nebraska here, and each loader checks the bounding boxes again after INSERT.
 *
 * 🟢 THE LAYERS ARE SELF-IDENTIFYING AS THE 2020-CENSUS PLANS. Each body's POPULATION values sum
 *   to 1,961,504 — Nebraska's 2020 census population to the person. A map drawn on any other
 *   census cannot do that, and this script refuses the file otherwise.
 *
 * 🟢 REGENTS AND BOARD OF EDUCATION ARE DIFFERENT MAPS, AND THAT IS MEASURED, NOT ASSUMED. Both
 *   have eight districts, both were enacted the same day, and their plan numbers differ only in
 *   the prefix (REG21-39003 against ED21-39003) — so "they are the same eight districts" is the
 *   obvious guess. It is wrong: district 1 holds 248,649 people on the Regents map and 242,357
 *   on the Board of Education map, and all eight pairs differ. --body regents and --body sboe
 *   therefore cannot be substituted for one another, and each loader checks its own populations.
 *
 * 🔴 NOTHING IS DROPPED SILENTLY: holes and multi-part districts are carried through, and the
 *   parser refuses a ring it cannot close, a non-numeric coordinate, or a district it cannot
 *   number.
 *
 * The ArcGIS responses are downloaded, untrusted data: read as text, parsed as JSON, nothing in
 * them executed. Raw responses are written beside the output and each one's sha256 is printed.
 *
 * Usage (from backend/):
 *   node scripts/CC_0373-fetch-ne-boards-arcgis.mjs --body psc <outdir> <out.json> [--offline]
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const argv = process.argv.slice(2);
const bi = argv.indexOf('--body');
const BODY = bi > -1 ? argv[bi + 1] : undefined;
const rest = argv.filter((a, i) => i !== bi && i !== bi + 1);
const OFFLINE = rest.includes('--offline');
const [OUTDIR, OUT] = rest.filter(a => !a.startsWith('--'));

const BODIES = {
  psc: {
    layer: 3, count: 5, layerName: 'PublicServiceCommision_2021',
    label: 'Public Service Commissioner',
    act: 'LB 5, 2021 First Special Session (Neb. Rev. Stat. 75-101.01), maps PSC21-39001 … PSC21-39001-5',
  },
  regents: {
    layer: 5, count: 8, layerName: 'BoardofRegents_2021',
    label: 'University of Nebraska Regent',
    act: 'LB 8, 2021 First Special Session (Neb. Rev. Stat. 85-103.01), maps REG21-39003 … REG21-39003-8',
  },
  sboe: {
    layer: 6, count: 8, layerName: 'BoardofEducation_2021',
    label: 'State Board of Education',
    act: 'LB 7, 2021 First Special Session (Neb. Rev. Stat. 79-311), maps ED21-39003 … ED21-39003-8',
  },
};

if (!BODY || !BODIES[BODY]) {
  throw new Error(`--body must be one of ${Object.keys(BODIES).join(', ')}`);
}
if (!OUTDIR || !OUT) throw new Error('usage: CC_0373-fetch-ne-boards-arcgis.mjs --body <psc|regents|sboe> <outdir> <out.json> [--offline]');

const B = BODIES[BODY];
const SERVICE = 'https://gis.ne.gov/Enterprise/rest/services/PoliticalBoundaries_2021/FeatureServer';
const QUERY = `${SERVICE}/${B.layer}/query`;

// Nebraska is -104.054..-95.308, 39.999..43.002. A generous box; a Web Mercator metre coordinate
// is in the millions and fails on the first point.
const LON_MIN = -105, LON_MAX = -94.5, LAT_MIN = 39.0, LAT_MAX = 43.5;

const STATE_POP_2020 = 1_961_504;
const IDEAL = Math.round(STATE_POP_2020 / B.count);

fs.mkdirSync(OUTDIR, { recursive: true });

// 🔴 THE LAYER NAME IS VERIFIED BEFORE ANY GEOMETRY IS READ. --body regents and --body sboe
//    differ only in a layer index, and an index typed from memory is the whole failure.
if (!OFFLINE) {
  const metaFile = path.join(OUTDIR, 'layer.json');
  const mr = await fetch(`${SERVICE}/${B.layer}?f=json`, { headers: { 'User-Agent': 'ev-accounts/1.0 (Nebraska board district import)' } });
  if (!mr.ok) throw new Error(`layer ${B.layer}: ArcGIS returned HTTP ${mr.status}`);
  fs.writeFileSync(metaFile, await mr.text());
}
{
  const meta = JSON.parse(fs.readFileSync(path.join(OUTDIR, 'layer.json'), 'utf8'));
  if (meta.name !== B.layerName) {
    throw new Error(`layer ${B.layer} is named "${meta.name}", not "${B.layerName}" — the service has been renumbered`);
  }
  console.log(`layer ${B.layer} is "${meta.name}", native SR ${meta.extent?.spatialReference?.latestWkid ?? meta.extent?.spatialReference?.wkid}`);
}

const url = d => `${QUERY}?where=${encodeURIComponent(`DISTRICT='${d}'`)}` +
  '&outFields=DISTRICT,District_N,POPULATION&returnGeometry=true&outSR=4326&f=geojson&geometryPrecision=7';

const districts = [];
let totalPop = 0;

for (let d = 1; d <= B.count; d++) {
  const file = path.join(OUTDIR, `d${d}.geojson`);
  if (!OFFLINE) {
    const r = await fetch(url(d), { headers: { 'User-Agent': 'ev-accounts/1.0 (Nebraska board district import)' } });
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
  // District_N is a second, independently typed copy of the same number in this service.
  if (Number(f.properties?.District_N) !== d) {
    throw new Error(`District ${d}: DISTRICT and District_N disagree (${f.properties?.DISTRICT} / ${f.properties?.District_N})`);
  }
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
        // 🔴 THE CRS CHECK, AT THE POINT OF PARSING. The service is Web Mercator; this is what
        //    stands between an outSR that silently did nothing and the Holladay failure.
        if (lon < LON_MIN || lon > LON_MAX || lat < LAT_MIN || lat > LAT_MAX) {
          throw new Error(`District ${d}: ${lon},${lat} is outside the Nebraska bounding box — wrong CRS or wrong file`);
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

if (districts.length !== B.count) throw new Error(`expected ${B.count} districts, built ${districts.length}`);
if (totalPop !== STATE_POP_2020) {
  throw new Error(`the ${B.count} districts hold ${totalPop} people, not Nebraska's 2020 population ${STATE_POP_2020}`);
}
const worst = Math.max(...districts.map(d => Math.abs(d.population - IDEAL) / IDEAL));
if (!(worst < 0.06)) throw new Error(`worst population deviation is ${(worst * 100).toFixed(2)}% — not a one-person-one-vote plan`);

fs.writeFileSync(OUT, JSON.stringify({
  body: BODY,
  label: B.label,
  source: `State of Nebraska enterprise GIS (gis.ne.gov), service PoliticalBoundaries_2021, ` +
    `layer ${B.layer} "${B.layerName}", published by the Legislative Research Office — the ` +
    `${B.act} plan. Queried 2026-11-07 with outSR=4326`,
  serviceUrl: QUERY,
  act: B.act,
  crs: 'EPSG:4326, requested from a Web Mercator (EPSG:3857) service via outSR and bounds-checked against Nebraska',
  totalPopulation: totalPop,
  idealDistrict: IDEAL,
  districts,
}));

console.log(`${districts.length} districts · ${districts.reduce((s, d) => s + d.points, 0)} points · ` +
  `${(fs.statSync(OUT).size / 1e6).toFixed(2)} MB · population ${totalPop} (2020 census, ideal ${IDEAL}, ` +
  `worst deviation ${(worst * 100).toFixed(2)}%)`);
