#!/usr/bin/env node
/**
 * verify-sc-columbia-districts.mjs — Knight program, wave SC-3.
 *
 * Tests Columbia's council-district polygons against a source that is NOT the polygon layer.
 *
 * 🔴 WHY THIS IS NEEDED. The layer (`CouncilDistrict`, ColaCityGIS) publishes four polygons and
 * ONE attribute, `LABEL`. There is no adoption date, no plan name and no second GIS publisher —
 * so nothing inside the layer can say whether it carries the map adopted after the 2020 census or
 * an older one. A count of four is true of every Columbia map ever drawn, exactly as 124/46 is
 * true of every South Carolina legislative plan.
 *
 * THE TEST: the city council's own Districts page lists, in text, the NEIGHBOURHOOD ASSOCIATIONS
 * in each district. That list is published by the council, not by GIS, and it is independent of
 * the geometry. Each neighbourhood is geocoded with OpenStreetMap Nominatim — a third party —
 * and the resulting point is tested against the polygon the page assigns it to.
 *
 * THE CONTROL: the same neighbourhoods are then tested against the WRONG district. Every one must
 * fail. A verifier that cannot fail has proved nothing.
 *
 * ⚠ WHAT THIS DOES AND DOES NOT PROVE. Agreement means the polygons match the council's own
 * published description of its districts TODAY. It does not date the map, and it cannot: Columbia
 * publishes no dated boundary. Recorded as a limitation rather than dressed up.
 *
 * Usage: node scripts/verify-sc-columbia-districts.mjs
 * Exit:  0 every anchor agrees and every control fails; 1 otherwise.
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const GEOJSON = path.join(HERE, '..', 'data', 'seed-sc-cities-2026', 'columbia-council-districts.geojson');
const UA = { 'User-Agent': 'ev-accounts-knight/1.0 (civic data seeding; chris@empowered.vote)' };

/** Neighbourhoods taken verbatim from the council's Districts page, with the district that page
 *  assigns them to. Chosen because each is a named place a geocoder can resolve. */
const ANCHORS = [
  ['DISTRICT 1', 'Earlewood, Columbia, South Carolina'],
  ['DISTRICT 1', 'Eau Claire, Columbia, South Carolina'],
  ['DISTRICT 2', 'Arsenal Hill, Columbia, South Carolina'],
  ['DISTRICT 2', 'Booker Washington Heights, Columbia, South Carolina'],
  ['DISTRICT 3', 'Rosewood, Columbia, South Carolina'],
  ['DISTRICT 3', 'Melrose Heights, Columbia, South Carolina'],
  ['DISTRICT 4', 'Heathwood, Columbia, South Carolina'],
  ['DISTRICT 4', 'Forest Hills, Columbia, South Carolina'],
];

/** Ray casting on a GeoJSON Polygon, outer ring minus holes. No dependency, and the control
 *  below is what proves it works. */
function inRing(pt, ring) {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i];
    const [xj, yj] = ring[j];
    if (yi > pt[1] !== yj > pt[1] && pt[0] < ((xj - xi) * (pt[1] - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}
export function inFeature(pt, feature) {
  const polys = feature.geometry.type === 'Polygon' ? [feature.geometry.coordinates] : feature.geometry.coordinates;
  for (const rings of polys) {
    if (!inRing(pt, rings[0])) continue;
    let hole = false;
    for (let k = 1; k < rings.length; k++) if (inRing(pt, rings[k])) hole = true;
    if (!hole) return true;
  }
  return false;
}

async function geocode(q) {
  const url = `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(q)}`;
  const r = await fetch(url, { headers: UA });
  const t = await r.text();
  if (!t.trim().startsWith('[')) throw new Error(`Nominatim did not return JSON (HTTP ${r.status})`);
  const j = JSON.parse(t);
  if (!j.length) return null;
  return [Number(j[0].lon), Number(j[0].lat)];
}

/** Read the polygons from the LIVE layer, so a re-run tests what Columbia publishes today. The
 *  local copy is only a cache: if the fetch fails, the run says so rather than quietly grading a
 *  stale file. */
async function districts() {
  const url =
    'https://services1.arcgis.com/Mnt8FoJcogKtoVBs/arcgis/rest/services/CouncilDistrict/FeatureServer/0' +
    '/query?where=1%3D1&outFields=LABEL&outSR=4326&f=geojson';
  try {
    const r = await fetch(url, { headers: UA });
    const t = await r.text();
    if (!t.trim().startsWith('{')) throw new Error(`not JSON (HTTP ${r.status})`);
    const g = JSON.parse(t);
    if (g.error) throw new Error(JSON.stringify(g.error).slice(0, 120));
    fs.mkdirSync(path.dirname(GEOJSON), { recursive: true });
    fs.writeFileSync(GEOJSON, JSON.stringify(g));
    console.log('source: the live CouncilDistrict layer');
    return g;
  } catch (e) {
    if (!fs.existsSync(GEOJSON)) throw new Error(`the layer is unreachable (${e.message}) and no local copy exists`);
    console.log(`⚠ the live layer is unreachable (${e.message}) — grading the local copy instead`);
    return JSON.parse(fs.readFileSync(GEOJSON, 'utf8'));
  }
}

const geo = await districts();
const byLabel = new Map(geo.features.map((f) => [f.properties.LABEL, f]));
console.log(`layer: ${geo.features.length} district(s) — ${[...byLabel.keys()].sort().join(', ')}\n`);

let failed = false;
let agreed = 0;
let controlled = 0;
let tested = 0;

for (const [label, place] of ANCHORS) {
  const pt = await geocode(place);
  await new Promise((r) => setTimeout(r, 1100)); // Nominatim asks for one request a second
  if (!pt) {
    console.log(`  ⚠ ${place}: the geocoder returned nothing — not counted either way`);
    continue;
  }
  tested++;
  const hit = [...byLabel.entries()].filter(([, f]) => inFeature(pt, f)).map(([l]) => l);
  const ok = hit.length === 1 && hit[0] === label;
  if (ok) agreed++;
  else failed = true;
  console.log(
    `  ${ok ? '✅' : '🔴'} ${place.split(',')[0].padEnd(26)} council page: ${label}  ·  polygons: ${hit.join('|') || 'none'}  (${pt.map((n) => n.toFixed(4)).join(', ')})`,
  );
  // The failing half: the same point against a district the page does NOT assign it to.
  const wrong = [...byLabel.keys()].find((l) => l !== label);
  if (!inFeature(pt, byLabel.get(wrong))) controlled++;
  else console.log(`     🔴 CONTROL FAILED: this point also falls inside ${wrong}`);
}

// 🔴 The hard negative control. The per-anchor check above only ever tests a point against a
// district that does not overlap the right one, so it cannot fail while the districts are
// disjoint — it proves the test is not answering "yes" to everything, and nothing more. These
// two points are outside Columbia entirely and must match NOTHING.
for (const [label, place] of [
  ['(outside)', 'Charleston City Hall, Charleston, South Carolina'],
  ['(outside)', 'Myrtle Beach City Hall, Myrtle Beach, South Carolina'],
]) {
  const pt = await geocode(place);
  await new Promise((r) => setTimeout(r, 1100));
  if (!pt) continue;
  const hit = [...byLabel.entries()].filter(([, f]) => inFeature(pt, f)).map(([l]) => l);
  const ok = hit.length === 0;
  if (!ok) failed = true;
  console.log(`  ${ok ? '✅' : '🔴'} NEGATIVE ${place.split(',')[0]} ${label}: matched ${hit.join('|') || 'nothing'}`);
}

console.log(`\n${agreed}/${tested} anchors agree with the council's own district lists`);
console.log(`${controlled}/${tested} control checks rejected the wrong district as required`);
if (tested < 4) {
  console.log('🔴 too few anchors resolved to call this a test');
  failed = true;
}
if (controlled !== tested) failed = true;
console.log(failed ? '\nFAIL' : '\nOK — the polygons agree with the council page, and the control rejects the wrong district');
process.exit(failed ? 1 : 0);
