#!/usr/bin/env node
/**
 * diff-ms-tiger-vintages.mjs — Knight program, slice 16 (MS), wave MS-1, step 2.
 *
 * measure-ms-tiger-legislative.mjs established that Mississippi is sldl 122 / sldu 52 in EVERY
 * TIGER vintage 2022-2025, with an identical code set, so neither a count nor a code set can date
 * the map — while all four file HASHES differ, so geometry moved somewhere. This asks WHERE, and
 * how many PEOPLE it moves.
 *
 * 🔴 WHY THIS MATTERS. The programme's standing rule, paid for in Michigan, is that
 * **THE CORRECT MAP IS THE ONE THE SITTING MEMBER WAS ELECTED UNDER**, and that two chambers of
 * one legislature can sit on different plans. Mississippi is the one Knight state with a known
 * mid-decade, court-ordered PARTIAL remap, so "which districts changed, between which vintages"
 * is the whole question.
 *
 * ── METHOD: CENSUS TRACT INTERNAL POINTS, NOT AREA ──────────────────────────────────────────
 * 🔴🔴 A PER-DISTRICT AREA TEST MEASURED THE GREAT LAKES in MI-1: TIGER legislative polygons
 * carry water, so two digitisations of ONE plan differed by hundreds of percent on coastal
 * districts. Mississippi has 90 miles of Gulf coast, the Mississippi Sound, and the slice's own
 * city sits on it — Harrison County's TIGER polygon is 984.69 sq mi against roughly 574 of land.
 * So area is the wrong instrument here for exactly the reason MI-1 recorded.
 *
 * The instrument is instead the one MI-1 replaced it with, and that PA-1 and OH-1 used: locate a
 * dense set of points that are ON LAND, and ask which district each falls in under each vintage.
 * Census TRACT internal points are guaranteed to lie inside their own tract and are placed on
 * land. A tract that answers district 42 under one vintage and district 43 under another is a
 * real person's representation moving; a shoreline re-digitisation moves none of them.
 *
 * Two sweeps run, and both are reported, because they fail differently:
 *   (a) DISTRICT internal points  — 122 + 52 points, one per district. Cheap, and it catches a
 *       wholesale renumbering. ⚠ It is INSENSITIVE to a boundary that moves without crossing the
 *       district's own centre, which is most partial remaps.
 *   (b) TRACT internal points     — every Mississippi census tract. This is the sensitive one.
 *
 * ── CONTROLS ────────────────────────────────────────────────────────────────────────────────
 * 🔴 A DETECTOR REPORTING "NOTHING FOUND" NEEDS A POSITIVE CONTROL, and a control that passes
 *    can pass for the wrong reason, so both controls here are WATCHED FAILING:
 *   1. point-in-polygon must place every district's own internal point inside its own polygon,
 *      in every vintage. If it cannot do that, every "unchanged" below is a broken detector.
 *   2. a deliberately WRONG pairing — vintage A's districts compared against vintage B's
 *      polygons shifted by one code — must report a large number of moves.
 *
 * ⚠ AND A CLEAN ZERO IS A STATEMENT ABOUT THE QUERY. If a pair reports 0 tracts moved, that
 *   means these two TIGER vintages carry the same plan. It does NOT say which plan.
 *
 * Usage:
 *   WORKDIR=<dir holding the zips measure-ms-tiger-legislative.mjs downloaded> \
 *     node scripts/diff-ms-tiger-vintages.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

const WORKDIR = process.env.WORKDIR || path.join(process.cwd(), '_ms-tiger');
fs.mkdirSync(WORKDIR, { recursive: true });
const VINTAGES = (process.env.VINTAGES || '2022,2023,2024,2025').split(',').map((s) => s.trim());
const FIPS = '28';
const TRACT_VINTAGE = process.env.TRACT_VINTAGE || '2024';

async function fetchBuffer(url) {
  const res = await fetch(url, { redirect: 'follow' });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${res.statusText} for ${url}`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.length < 10_000) throw new Error(`suspiciously small body (${buf.length} bytes) for ${url}`);
  if (buf[0] !== 0x50 || buf[1] !== 0x4b) throw new Error(`not a zip for ${url}`);
  return buf;
}

async function openLayer(base, url) {
  const zipPath = path.join(WORKDIR, `${base}.zip`);
  if (!fs.existsSync(zipPath)) fs.writeFileSync(zipPath, await fetchBuffer(url));
  const zip = new AdmZip(zipPath);
  for (const ext of ['.shp', '.dbf', '.shx']) {
    fs.writeFileSync(path.join(WORKDIR, base + ext), zip.getEntry(base + ext).getData());
  }
  return shapefile.open(path.join(WORKDIR, base + '.shp'), path.join(WORKDIR, base + '.dbf'));
}

function tigerUrl(layer, vintage) {
  return `https://www2.census.gov/geo/tiger/TIGER${vintage}/${layer.toUpperCase()}/tl_${vintage}_${FIPS}_${layer}.zip`;
}

/**
 * Even-odd ray casting over every ring of a polygon. A hole is just another ring, so the
 * even-odd rule handles it without special-casing — a point inside a hole crosses the outer
 * ring once and the hole once, an even count, and is correctly reported OUTSIDE.
 */
function pointInRings(rings, x, y) {
  let inside = false;
  for (const ring of rings) {
    for (let i = 0, j = ring.length - 1; i < ring.length; j = i, i += 1) {
      const [xi, yi] = ring[i];
      const [xj, yj] = ring[j];
      if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
    }
  }
  return inside;
}

function pointInFeature(geom, x, y) {
  if (!geom) return false;
  if (geom.type === 'Polygon') return pointInRings(geom.coordinates, x, y);
  if (geom.type === 'MultiPolygon') return geom.coordinates.some((poly) => pointInRings(poly, x, y));
  return false;
}

/** Cheap reject before the ray cast. TIGER polygons are big; this makes the sweep tractable. */
function bbox(geom) {
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  const walk = (rings) => {
    for (const ring of rings) for (const [x, y] of ring) {
      if (x < minX) minX = x; if (x > maxX) maxX = x;
      if (y < minY) minY = y; if (y > maxY) maxY = y;
    }
  };
  if (geom.type === 'Polygon') walk(geom.coordinates);
  else if (geom.type === 'MultiPolygon') for (const poly of geom.coordinates) walk(poly);
  return [minX, minY, maxX, maxY];
}

async function loadDistricts(layer, vintage) {
  const base = `tl_${vintage}_${FIPS}_${layer}`;
  const src = await openLayer(base, tigerUrl(layer, vintage));
  const field = layer === 'sldu' ? 'SLDUST' : 'SLDLST';
  const out = [];
  for (;;) {
    const r = await src.read();
    if (r.done) break;
    const p = r.value.properties;
    out.push({
      code: String(p[field]),
      geom: r.value.geometry,
      bbox: bbox(r.value.geometry),
      intpt: [parseFloat(p.INTPTLON), parseFloat(p.INTPTLAT)],
    });
  }
  return out;
}

async function loadTracts() {
  const base = `tl_${TRACT_VINTAGE}_${FIPS}_tract`;
  const url = `https://www2.census.gov/geo/tiger/TIGER${TRACT_VINTAGE}/TRACT/${base}.zip`;
  const src = await openLayer(base, url);
  const out = [];
  for (;;) {
    const r = await src.read();
    if (r.done) break;
    const p = r.value.properties;
    out.push({
      geoid: String(p.GEOID),
      aland: Number(p.ALAND),
      pt: [parseFloat(p.INTPTLON), parseFloat(p.INTPTLAT)],
    });
  }
  return out;
}

function locate(districts, [x, y]) {
  for (const d of districts) {
    if (x < d.bbox[0] || x > d.bbox[2] || y < d.bbox[1] || y > d.bbox[3]) continue;
    if (pointInFeature(d.geom, x, y)) return d.code;
  }
  return null;
}

// ────────────────────────────────────────────────────────────────────────────────────────────
console.log('loading TIGER …');
const sets = {};
for (const layer of ['sldu', 'sldl']) {
  sets[layer] = {};
  for (const v of VINTAGES) sets[layer][v] = await loadDistricts(layer, v);
}
const tracts = await loadTracts();
console.log(`Mississippi census tracts (${TRACT_VINTAGE}): ${tracts.length}  ` +
  `(${tracts.filter((t) => t.aland === 0).length} with ALAND = 0)`);

// ── CONTROL 1: every district's own internal point must land in its own polygon. ─────────────
{
  let bad = 0;
  for (const layer of ['sldu', 'sldl']) {
    for (const v of VINTAGES) {
      for (const d of sets[layer][v]) {
        if (locate(sets[layer][v], d.intpt) !== d.code) {
          bad += 1;
          console.log(`  🔴 ${layer} ${v} district ${d.code}: own internal point does not resolve to itself`);
        }
      }
    }
  }
  if (bad) {
    console.error(`🔴 CONTROL 1 FAILED on ${bad} districts — point-in-polygon is broken, so every ` +
      'result below is meaningless.');
    process.exit(1);
  }
  const n = VINTAGES.length * (sets.sldu[VINTAGES[0]].length + sets.sldl[VINTAGES[0]].length);
  console.log(`✅ control 1 — all ${n} district internal points resolve to their own district.`);
}

// ── CONTROL 2: a deliberately wrong pairing must report a large number of moves. ─────────────
{
  const v = VINTAGES[VINTAGES.length - 1];
  const real = sets.sldl[v];
  const shifted = real.map((d, i) => ({ ...d, code: real[(i + 1) % real.length].code }));
  let moved = 0;
  for (const t of tracts) {
    const a = locate(real, t.pt);
    const b = locate(shifted, t.pt);
    if (a !== b) moved += 1;
  }
  if (moved < tracts.length * 0.5) {
    console.error(`🔴 CONTROL 2 FAILED — a deliberately mis-labelled map moved only ${moved} of ` +
      `${tracts.length} tracts. The comparison cannot see a move, so a zero below proves nothing.`);
    process.exit(1);
  }
  console.log(`✅ control 2 — a deliberately mis-labelled map moves ${moved} of ${tracts.length} ` +
    'tracts, so the comparison CAN report a move.');
}

// ────────────────────────────────────────────────────────────────────────────────────────────
for (const layer of ['sldu', 'sldl']) {
  console.log(`\n${'='.repeat(78)}`);
  console.log(`${layer.toUpperCase()} — which districts move between TIGER vintages`);
  console.log('='.repeat(78));

  for (let i = 1; i < VINTAGES.length; i += 1) {
    const [va, vb] = [VINTAGES[i - 1], VINTAGES[i]];
    const A = sets[layer][va];
    const B = sets[layer][vb];

    // (a) district internal points
    let dMoved = 0;
    for (const d of A) if (locate(B, d.intpt) !== d.code) dMoved += 1;

    // (b) tract internal points — the sensitive sweep
    const changed = new Map(); // "a->b" -> count
    let unresolved = 0;
    for (const t of tracts) {
      const a = locate(A, t.pt);
      const b = locate(B, t.pt);
      if (a === null || b === null) { unresolved += 1; continue; }
      if (a !== b) changed.set(`${a}->${b}`, (changed.get(`${a}->${b}`) || 0) + 1);
    }
    const tractsMoved = [...changed.values()].reduce((s, n) => s + n, 0);
    const districtsTouched = new Set();
    for (const k of changed.keys()) { const [a, b] = k.split('->'); districtsTouched.add(a); districtsTouched.add(b); }

    console.log(`\n  ${va} -> ${vb}`);
    console.log(`    district internal points moving : ${dMoved} of ${A.length}`);
    console.log(`    TRACT internal points moving    : ${tractsMoved} of ${tracts.length}` +
      `${unresolved ? `   (${unresolved} unresolved in one or both vintages)` : ''}`);
    console.log(`    distinct districts touched      : ${districtsTouched.size}`);
    if (changed.size === 0) {
      console.log('    ▶ NO TRACT CHANGES DISTRICT — these two vintages carry the SAME PLAN.');
    } else {
      const top = [...changed.entries()].sort((a, b) => b[1] - a[1]);
      console.log('    tract movements, largest first:');
      for (const [k, n] of top.slice(0, 25)) console.log(`      ${k.padEnd(12)} ${n} tract${n === 1 ? '' : 's'}`);
      if (top.length > 25) console.log(`      … and ${top.length - 25} more movements`);
      console.log(`    ▶ ${districtsTouched.size} of ${A.length} districts are involved — ` +
        `${districtsTouched.size < A.length / 3 ? 'a PARTIAL remap' : 'a WHOLESALE change'}.`);
      console.log(`    districts involved: ${[...districtsTouched].sort((x, y) => Number(x) - Number(y)).join(' ')}`);
    }
  }
}

console.log(`\n${'='.repeat(78)}`);
console.log('READING THIS');
console.log('='.repeat(78));
console.log('A pair where NO tract changes district carries the same plan.');
console.log('A pair where a SMALL, NAMED set of districts exchanges tracts is a PARTIAL REMAP,');
console.log('and it is that pair which dates the plan the sitting members were elected under.');
console.log('🔴 This names the pair and the districts. It is NOT the proof — the proof is the');
console.log('   court order or the Legislature\'s own published plan, read against these numbers.');
