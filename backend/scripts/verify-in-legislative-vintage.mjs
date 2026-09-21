#!/usr/bin/env node
/**
 * verify-in-legislative-vintage.mjs
 *
 * Proves that the Indiana sldl/sldu polygons in production are the enacted 2021 plan, by the
 * GA-1 method: test EVERY district at its own interior point against the Indiana General
 * Assembly's own published geometry. Reads nothing from the database itself -- it consumes a
 * CSV of interior points produced by this query:
 *
 *   SELECT mtfcc, geo_id, ST_X(ST_PointOnSurface(geometry)), ST_Y(ST_PointOnSurface(geometry))
 *   FROM essentials.geofence_boundaries
 *   WHERE state='18' AND mtfcc IN ('G5210','G5220') ORDER BY mtfcc, geo_id;
 *
 * SOURCES
 *   A. Production, census_tiger_2024, loaded 2026-02-11/12. 150 polygons.
 *   B. The General Assembly's own district maps, linked from its Find Your Legislator page and
 *      drawn there as a Google KML overlay:
 *        /publications/maps/senate-districts/senate_2021.kmz   50 placemarks
 *        /publications/maps/house-districts/house_2021.kmz    100 placemarks
 *      Both KML payloads are dated 2022-04-29 and named for the 2021 plan.
 *
 * 🔴 THE KMZ URLS RETURN HTTP 200 AND 691 BYTES OF REACT SHELL TO curl -- with a browser user
 * agent, with a Referer, and with X-Requested-With. The same URLs return 1,694,603 and
 * 2,430,264 bytes of real ZIP to an in-page fetch(). There is no error code anywhere in the
 * failing path, so ONLY A FULL DECODE CATCHES IT: check the PK magic bytes and the byte count,
 * never r.ok. Re-capture the same way (Playwright, in-page fetch, base64 out); do not add a
 * curl here and assume it works.
 *
 * 🔴 A UNIFORM ANSWER IS A BROKEN DETECTOR. --self-test plants four defects into the parsed
 * geometry and requires each to be reported before any real verdict is trusted. Control 3 is
 * the "two GIS layers can invert" failure, planted deliberately.
 *
 *   node scripts/verify-in-legislative-vintage.mjs
 *   node scripts/verify-in-legislative-vintage.mjs --self-test
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SEED = path.join(HERE, '..', 'data', 'seed-in-legislature-2026');
const POINTS = path.join(SEED, '_tiger_interior_points.csv');

const LAYERS = {
  G5210: { kml: '_kml_iga_senate_2021/doc.kml', re: /^State Senate District (\d+)$/, seats: 50, name: 'Senate' },
  G5220: { kml: '_kml_iga_house_2021/doc.kml', re: /^State House District (\d+)$/, seats: 100, name: 'House' },
};

/** Parse a KML into Map<districtNumber, Array<rings>>; within a polygon, ring 0 is the outer. */
function parseKml(file, re) {
  const text = fs.readFileSync(file, 'utf8');
  const out = new Map();
  for (const pm of text.split('<Placemark').slice(1)) {
    const nm = /<name>([^<]*)<\/name>/.exec(pm);
    if (!nm) continue;
    const m = re.exec(nm[1].trim());
    if (!m) continue;
    const district = Number(m[1]);
    const polys = [];
    for (const poly of pm.split('<Polygon>').slice(1)) {
      const outer = /<outerBoundaryIs>[\s\S]*?<coordinates>([\s\S]*?)<\/coordinates>/.exec(poly);
      if (!outer) continue;
      const rings = [parseRing(outer[1])];
      for (const inner of poly.matchAll(/<innerBoundaryIs>[\s\S]*?<coordinates>([\s\S]*?)<\/coordinates>/g)) {
        rings.push(parseRing(inner[1]));
      }
      polys.push(rings);
    }
    if (!out.has(district)) out.set(district, []);
    out.get(district).push(...polys);
  }
  return out;
}

function parseRing(blob) {
  const pts = [];
  for (const tok of blob.trim().split(/\s+/)) {
    if (!tok) continue;
    const p = tok.split(',');
    pts.push([Number(p[0]), Number(p[1])]);
  }
  return pts;
}

/** Ray casting. rings[0] is the outer boundary; any further ring is a hole. */
function inRing(ring, x, y) {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const xi = ring[i][0], yi = ring[i][1], xj = ring[j][0], yj = ring[j][1];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}

function inPolygon(rings, x, y) {
  if (!inRing(rings[0], x, y)) return false;
  for (let k = 1; k < rings.length; k++) if (inRing(rings[k], x, y)) return false;
  return true;
}

function whichDistrict(layer, x, y) {
  const hits = [];
  for (const [district, polys] of layer) {
    for (const rings of polys) {
      if (inPolygon(rings, x, y)) { hits.push(district); break; }
    }
  }
  return hits;
}

function loadPoints() {
  return fs.readFileSync(POINTS, 'utf8').trim().split('\n').map((line) => {
    const [mtfcc, geo_id, x, y] = line.split(',');
    return { mtfcc, geo_id, district: Number(geo_id.replace(/^18/, '')), x: Number(x), y: Number(y) };
  });
}

function run(layers, points) {
  const agree = [], disagree = [];
  for (const p of points) {
    const hits = whichDistrict(layers[p.mtfcc], p.x, p.y);
    if (hits.length === 1 && hits[0] === p.district) agree.push(p);
    else disagree.push({ ...p, hits });
  }
  return { agree, disagree };
}

function main() {
  const selfTest = process.argv.includes('--self-test');
  const points = loadPoints();
  const layers = {};
  for (const [mtfcc, cfg] of Object.entries(LAYERS)) {
    layers[mtfcc] = parseKml(path.join(SEED, cfg.kml), cfg.re);
    const got = layers[mtfcc].size;
    console.log(`${cfg.name}: parsed ${got} districts (expect ${cfg.seats})`);
    if (got !== cfg.seats) throw new Error(`${cfg.name}: parsed ${got} districts, expected ${cfg.seats}`);
  }
  console.log(`interior points: ${points.length} (expect 150)\n`);

  if (selfTest) {
    console.log('-- POSITIVE CONTROLS ------------------------------------------');
    const clone = () => {
      const c = {};
      for (const k of Object.keys(layers)) c[k] = new Map([...layers[k]]);
      return c;
    };
    console.log(`  control 1  unmodified                -> ${run(layers, points).disagree.length} disagreements (expect 0)`);
    const c2 = clone(); c2.G5220.delete(45);
    console.log(`  control 2  HD-45 geometry removed    -> ${run(c2, points).disagree.length} disagreements (expect 1)`);
    const c3 = clone(); const a = c3.G5210.get(17), b = c3.G5210.get(18);
    c3.G5210.set(17, b); c3.G5210.set(18, a);
    console.log(`  control 3  SD-17 and SD-18 swapped   -> ${run(c3, points).disagree.length} disagreements (expect 2)`);
    const c4 = clone(); c4.G5220.set(99, [...c4.G5220.get(99), ...c4.G5220.get(100)]);
    console.log(`  control 4  HD-99 overlaps HD-100     -> ${run(c4, points).disagree.length} disagreements (expect 1)`);
    console.log('');
  }

  const { agree, disagree } = run(layers, points);
  const byLayer = (m) => agree.filter((p) => p.mtfcc === m).length;
  console.log('-- VERDICT ----------------------------------------------------');
  console.log(`  House  ${byLayer('G5220')} / 100 agree`);
  console.log(`  Senate ${byLayer('G5210')} / 50 agree`);
  console.log(`  total  ${agree.length} / ${points.length} agree, ${disagree.length} disagree`);
  for (const d of disagree) {
    console.log(`  DISAGREE ${d.mtfcc} ${d.geo_id}: TIGER says district ${d.district}, IGA geometry says ${JSON.stringify(d.hits)}`);
  }
  if (disagree.length) process.exitCode = 1;
}

main();
