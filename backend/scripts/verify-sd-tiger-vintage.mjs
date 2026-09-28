#!/usr/bin/env node
/**
 * verify-sd-tiger-vintage.mjs — Knight program, slice 15 (SD), wave SD-1.
 *
 * Proves WHICH redistricting plan the TIGER FIPS 46 legislative layers carry, against an
 * authority that is not the Census Bureau.
 *
 * ── THE AUTHORITY IS THE LEGISLATURE'S OWN MAP LAYER, AND IT PUBLISHES BOTH PLANS ───────────
 * sdlegislature.gov's "Find My Legislators" viewer is an ArcGIS map whose district geometry is
 * served as plain GeoJSON straight from the Legislature's own host. Its redistricting page links
 * the live layer as "2021 Adopted Map" (Legislators/Find?activeLayer=2021), and the viewer loads
 * BOTH layers:
 *   current  https://sdlegislature.gov/redistrictingFeatureLayer.geojson       (the adopted plan)
 *   prior    https://sdlegislature.gov/2010redistrictingFeatureLayer.geojson   (the 2010 plan)
 * Publishing the superseded plan beside the live one is what makes this a real test rather than a
 * single-sided check: the SAME comparison is run against both, and only one may return zero.
 * 🔴 The site is a JavaScript SPA. A plain fetch of the HTML returns a "use a modern browser"
 *    shell that reads like a real page — the GeoJSON URLs were found by rendering the viewer and
 *    reading its network traffic, not by scraping the HTML.
 *
 * ── 🔴🔴 WHY THIS SCRIPT EXISTS: NOTHING IN THE TIGER FILE DATES AN SD MAP ───────────────────
 * Measured 2026-09-28 by parsing the .dbf inside each zip (see measure-sd-tiger-legislative.mjs):
 * TIGER 2020, 2022, 2024 and 2025 are ALL sldl 37 / sldu 35 with the IDENTICAL code set
 * (001..025, 027, 029..035, 26A, 26B, 28A, 28B). South Dakota's subdistrict structure survived
 * the 2021 redistricting unchanged, so a count check, a letter check and a code-set check all
 * pass on a decade-old superseded map.
 * ⚠ LSY LOOKS LIKE A DISCRIMINATOR AND IS NOT (2018 / 2022 / 2024 / 2024) — it tracks the Census
 *   refresh, not the plan. The same trap KS-1 and KY-1 documented.
 * ⚠ AND A THRESHOLD TEST PASSES THE SUPERSEDED MAP HERE TOO. TIGER 2020 against the adopted plan
 *   still agrees on 28 of 35 Senate and 30 of 37 House districts — 80% and 81%. Anyone relaxing
 *   MOVED === 0 to "most districts agree" re-admits the 2010 plan.
 *
 * ── 🔴🔴 THE AUTHORITY LAYER HAS 39 FEATURES, AND THE OVERLAP IS THE WHOLE POINT ─────────────
 * Both GeoJSON files carry 39 districts: 1..35 PLUS 26A, 26B, 28A, 28B. That is ONE layer serving
 * BOTH chambers — 26 and 28 are whole SENATE districts that split into single-member HOUSE
 * subdistricts. So 26A and 26B lie INSIDE 26, and a naive point-in-polygon lookup returns two
 * answers for any point in them.
 * ▶ The comparison therefore restricts the authority per chamber before locating anything:
 *     against sldu (35) — districts 1..35, subdistricts EXCLUDED
 *     against sldl (37) — districts 1..35 minus 26 and 28, subdistricts INCLUDED
 *   Those two subsets are 35 and 37, which is an independent confirmation of the TIGER counts
 *   from a source that has never seen a TIGER file.
 *
 * ── HOW THE TEST WORKS ──────────────────────────────────────────────────────────────────────
 * For each TIGER district, take its own internal point (INTPTLAT/INTPTLON) and ask which
 * authority district contains it. MOVED is the number whose label differs.
 *   correct plan  => MOVED === 0
 *   wrong plan    => MOVED > 0
 * The script asserts zero against one plan and NON-zero against the other. An assertion that only
 * ever checks for zero cannot tell a passing test from a broken one.
 *
 * Controls, all of which must fire before any verdict is printed:
 *   1. bogus FIPS 99 must fail to download;
 *   2. each authority layer's own features must locate to themselves;
 *   3. the wrong-plan comparison must return MOVED > 0.
 *
 * Usage:
 *   node scripts/verify-sd-tiger-vintage.mjs               # TIGER 2024 (the load vintage)
 *   VINTAGE=2020 node scripts/verify-sd-tiger-vintage.mjs  # expect the verdict to invert
 */
import fs from 'node:fs';
import path from 'node:path';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

const WORKDIR = process.env.WORKDIR || path.join(process.cwd(), '_sd-vintage');
fs.mkdirSync(WORKDIR, { recursive: true });
const VINTAGE = process.env.VINTAGE || '2024';
const FIPS = '46';

const AUTHORITY = {
  adopted: {
    url: 'https://sdlegislature.gov/redistrictingFeatureLayer.geojson',
    label: '2021 Adopted Map (SD Legislature)',
    field: 'DISTRICT',
  },
  prior: {
    url: 'https://sdlegislature.gov/2010redistrictingFeatureLayer.geojson',
    label: '2010 plan (SD Legislature)',
    field: 'District_Name',
  },
};

async function fetchBuffer(url) {
  const res = await fetch(url, { redirect: 'follow' });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${res.statusText} for ${url}`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.length < 10_000) throw new Error(`suspiciously small body (${buf.length} bytes) for ${url}`);
  return buf;
}

/** TIGER codes are zero-padded ('004') and the authority is not ('4'). Letters must survive. */
function normalise(raw, where) {
  const s = String(raw).trim().toUpperCase();
  const m = /^(\d+)([A-Z]*)$/.exec(s);
  if (!m) throw new Error(`${where}: unparseable district code ${JSON.stringify(raw)}`);
  return String(parseInt(m[1], 10)) + m[2];
}

async function loadAuthority(which) {
  const { url, label, field } = AUTHORITY[which];
  const file = path.join(WORKDIR, `authority-${which}.geojson`);
  if (!fs.existsSync(file)) fs.writeFileSync(file, await fetchBuffer(url));
  const json = JSON.parse(fs.readFileSync(file, 'utf8'));
  const rows = json.features.map((f) => ({
    code: normalise(f.properties[field], `${label} ${field}`),
    geom: f.geometry,
  }));
  return { label, url, rows };
}

async function loadTiger(layer) {
  const base = `tl_${VINTAGE}_${FIPS}_${layer}`;
  const zipPath = path.join(WORKDIR, `${base}.zip`);
  if (!fs.existsSync(zipPath)) {
    const url = `https://www2.census.gov/geo/tiger/TIGER${VINTAGE}/${layer.toUpperCase()}/${base}.zip`;
    const buf = await fetchBuffer(url);
    if (buf[0] !== 0x50 || buf[1] !== 0x4b) throw new Error(`not a zip: ${url}`);
    fs.writeFileSync(zipPath, buf);
  }
  const zip = new AdmZip(zipPath);
  for (const ext of ['.shp', '.dbf', '.shx']) {
    const e = zip.getEntry(base + ext);
    if (!e) throw new Error(`${base}${ext} missing from ${base}.zip`);
    fs.writeFileSync(path.join(WORKDIR, base + ext), e.getData());
  }
  const field = layer === 'sldu' ? 'SLDUST' : 'SLDLST';
  const src = await shapefile.open(path.join(WORKDIR, base + '.shp'), path.join(WORKDIR, base + '.dbf'));
  const rows = [];
  for (;;) {
    const r = await src.read();
    if (r.done) break;
    const p = r.value.properties;
    rows.push({
      code: normalise(p[field], `TIGER ${VINTAGE} ${field}`),
      // INTPTLAT/INTPTLON carry a leading '+'. Strip it rather than trust parseFloat to.
      lat: parseFloat(String(p.INTPTLAT).replace(/^\+/, '')),
      lon: parseFloat(String(p.INTPTLON).replace(/^\+/, '')),
      geom: r.value.geometry,
    });
  }
  return rows;
}

// ── point in polygon, ray casting, holes respected ──────────────────────────────────────────
const ringHas = ([x, y], ring) => {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i];
    const [xj, yj] = ring[j];
    if (yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
};
const polyHas = (pt, poly) => {
  if (!ringHas(pt, poly[0])) return false;
  for (let k = 1; k < poly.length; k++) if (ringHas(pt, poly[k])) return false;
  return true;
};
const geomHas = (pt, g) => {
  if (!g) return false;
  if (g.type === 'Polygon') return polyHas(pt, g.coordinates);
  if (g.type === 'MultiPolygon') return g.coordinates.some((p) => polyHas(pt, p));
  return false;
};
const locate = (pt, rows) => rows.filter((r) => geomHas(pt, r.geom)).map((r) => r.code);

/**
 * A point GUARANTEED to lie inside the polygon — the equivalent of PostGIS ST_PointOnSurface.
 *
 * 🔴 A MEAN OF THE VERTICES IS NOT AN INTERIOR POINT, and using one is how this script's own
 * control first failed: South Dakota's districts are concave enough that district 25's vertex
 * mean lands inside district 8. Scan a horizontal line across the middle of the bounding box,
 * collect every boundary crossing, and take the midpoint of the widest span that is actually
 * inside. That is inside by construction, for any concave or multi-part shape.
 */
function pointOnSurface(geom) {
  const parts = geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
  // Use the part with the most vertices — for a multi-part district that is the mainland.
  const poly = parts.reduce((a, b) => (b[0].length > a[0].length ? b : a));
  let ymin = Infinity;
  let ymax = -Infinity;
  for (const [, y] of poly[0]) {
    if (y < ymin) ymin = y;
    if (y > ymax) ymax = y;
  }
  const y = (ymin + ymax) / 2;
  const xs = [];
  for (const ring of poly) {
    for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      const [xi, yi] = ring[i];
      const [xj, yj] = ring[j];
      if (yi > y !== yj > y) xs.push(((xj - xi) * (y - yi)) / (yj - yi) + xi);
    }
  }
  xs.sort((a, b) => a - b);
  let best = null;
  for (let i = 0; i + 1 < xs.length; i++) {
    const mid = (xs[i] + xs[i + 1]) / 2;
    if (!polyHas([mid, y], poly)) continue;
    const width = xs[i + 1] - xs[i];
    if (!best || width > best.width) best = { pt: [mid, y], width };
  }
  if (!best) throw new Error('pointOnSurface found no interior span');
  return best.pt;
}

/**
 * 🔴 26A/26B lie INSIDE 26, so the authority layer must be narrowed to one chamber before any
 * point is located. Senate: 1..35, no letters. House: the same minus 26 and 28, plus the four
 * subdistricts.
 */
function chamberSubset(rows, layer) {
  const lettered = (c) => /[A-Z]/.test(c);
  if (layer === 'sldu') return rows.filter((r) => !lettered(r.code));
  const split = new Set(
    rows.filter((r) => lettered(r.code)).map((r) => r.code.replace(/[A-Z]+$/, '')),
  );
  return rows.filter((r) => lettered(r.code) || !split.has(r.code));
}

function compare(tiger, authRows, layer) {
  const subset = chamberSubset(authRows, layer);
  const moved = [];
  let same = 0;
  let outside = 0;
  let ambiguous = 0;
  for (const d of tiger) {
    const hits = locate([d.lon, d.lat], subset);
    if (hits.length === 0) outside++;
    else if (hits.length > 1) {
      ambiguous++;
      moved.push({ code: d.code, was: `AMBIGUOUS(${hits.join('/')})`, lat: d.lat, lon: d.lon });
    } else if (hits[0] === d.code) same++;
    else moved.push({ code: d.code, was: hits[0], lat: d.lat, lon: d.lon });
  }
  return { subsetSize: subset.length, same, moved, outside, ambiguous, total: tiger.length };
}

// ── CONTROL 1: the fetch path must be able to fail. ─────────────────────────────────────────
let fetchControl = false;
try {
  await fetchBuffer(`https://www2.census.gov/geo/tiger/TIGER${VINTAGE}/SLDL/tl_${VINTAGE}_99_sldl.zip`);
} catch (err) {
  fetchControl = true;
  console.log(`control 1 OK — bogus FIPS 99 refused: ${err.message.split(' for ')[0]}`);
}
if (!fetchControl) {
  console.error('🔴 CONTROL 1 DID NOT FIRE — a bogus FIPS downloaded. Nothing below proves anything.');
  process.exit(1);
}

const adopted = await loadAuthority('adopted');
const prior = await loadAuthority('prior');
console.log(`authority ADOPTED  ${adopted.rows.length} features — ${adopted.url}`);
console.log(`authority PRIOR    ${prior.rows.length} features — ${prior.url}`);

// ── CONTROL 2: each authority layer must locate its own features to themselves. ─────────────
for (const [name, auth] of [['adopted', adopted], ['prior', prior]]) {
  for (const layer of ['sldu', 'sldl']) {
    const subset = chamberSubset(auth.rows, layer);
    const bad = [];
    for (const r of subset) {
      const hits = locate(pointOnSurface(r.geom), subset);
      if (!hits.includes(r.code)) bad.push(`${r.code}->${hits.join('/') || 'NOTHING'}`);
    }
    console.log(
      `control 2 ${name}/${layer}: subset ${subset.length} features, self-location conflicts ${bad.length}${bad.length ? ` 🔴 ${bad.join(', ')}` : ' ✅'}`,
    );
    if (bad.length) process.exitCode = 1;
  }
}

// ── The comparison itself. ──────────────────────────────────────────────────────────────────
const results = {};
for (const layer of ['sldu', 'sldl']) {
  const tiger = await loadTiger(layer);
  results[layer] = {};
  for (const [name, auth] of [['adopted', adopted], ['prior', prior]]) {
    const r = compare(tiger, auth.rows, layer);
    results[layer][name] = r;
    const pct = ((r.same / r.total) * 100).toFixed(1);
    console.log(
      `\nTIGER ${VINTAGE} ${layer} (${r.total}) vs ${auth.label} [subset ${r.subsetSize}]:` +
        `  same ${r.same}  MOVED ${r.moved.length}  outside ${r.outside}  ambiguous ${r.ambiguous}   (${pct}% agree)`,
    );
    for (const m of r.moved.slice(0, 10)) {
      console.log(`    district ${m.code.padEnd(4)} authority says ${String(m.was).padEnd(18)} at ${m.lat.toFixed(5)}, ${m.lon.toFixed(5)}`);
    }
  }
}

// ── Verdict. Zero against one plan AND non-zero against the other. ──────────────────────────
console.log(`\n${'='.repeat(78)}`);
const clean = (l, which) => results[l][which].moved.length === 0 && results[l][which].outside === 0;
const zeroAdopted = ['sldu', 'sldl'].every((l) => clean(l, 'adopted'));
const zeroPrior = ['sldu', 'sldl'].every((l) => clean(l, 'prior'));
const movedPrior = `${results.sldu.prior.moved.length} Senate / ${results.sldl.prior.moved.length} House`;
const movedAdopted = `${results.sldu.adopted.moved.length} Senate / ${results.sldl.adopted.moved.length} House`;

// 🔴 EVERY BRANCH MUST NAME THE REASON IT ACTUALLY FOUND. An earlier version reported a matched
// superseded vintage as "control 3 did not fire", which is a gate aborting for the wrong reason.
if (zeroAdopted && !zeroPrior) {
  console.log(`✅ TIGER ${VINTAGE} FIPS 46 CARRIES THE ${adopted.label.toUpperCase()}.`);
  console.log(`   Every district's internal point lands in the same-numbered adopted district — 0 moved —`);
  console.log(`   and the SAME test against the ${prior.label} moves ${movedPrior},`);
  console.log(`   so the test can fail and did.`);
} else if (zeroPrior && !zeroAdopted) {
  console.error(`🔴 TIGER ${VINTAGE} FIPS 46 CARRIES THE SUPERSEDED ${prior.label.toUpperCase()} — DO NOT LOAD IT.`);
  console.error(`   It matches the prior plan exactly (0 moved) and moves ${movedAdopted} against the adopted plan.`);
  console.error(`   The test is working; this vintage is the wrong one.`);
  process.exitCode = 1;
} else if (zeroAdopted && zeroPrior) {
  console.error('🔴 CONTROL 3 DID NOT FIRE — BOTH plans return 0 moved.');
  console.error('   The two plans are indistinguishable by this test, so a pass means nothing.');
  process.exitCode = 1;
} else {
  console.error(`🔴 TIGER ${VINTAGE} FIPS 46 MATCHES NEITHER PLAN.`);
  console.error(`   adopted moved ${movedAdopted} (outside ${results.sldu.adopted.outside}/${results.sldl.adopted.outside});` +
    ` prior moved ${movedPrior} (outside ${results.sldu.prior.outside}/${results.sldl.prior.outside}).`);
  process.exitCode = 1;
}
console.log('='.repeat(78));
