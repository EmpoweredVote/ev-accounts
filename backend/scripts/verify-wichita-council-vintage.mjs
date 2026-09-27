#!/usr/bin/env node
/**
 * verify-wichita-council-vintage.mjs — Knight program, wave KS-3.
 *
 * Answers ONE question: are the six polygons served by the City of Wichita's council-district
 * layer the map adopted as "Map B" in 2022, or a superseded one? Needs no database.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * WHY THIS TOOL EXISTS AND WHY IT IS NOT A GEOMETRY COMPARISON.
 *
 * Every earlier slice proved vintage by comparing the live map against a prior one — Lexington
 * against `Council_District_2012`, Kansas against TIGER 2020 carrying the 2012 court plan. THAT
 * IS NOT AVAILABLE HERE, and it was not assumed to be missing, it was searched for:
 *   * all 23 layers of COWGIS/Districts enumerated — exactly one is council districts, no `_2012`
 *     twin, so nothing to compare against;
 *   * city ArcGIS folders COWGIS, OpenData, MISC, CSEAM and the root enumerated — no redistricting
 *     or historical service;
 *   * the Wayback Machine holds 4 captures of the layer endpoint, ALL in 2026;
 *   * wichita.gov/998 (Redistricting Dashboard) and /997 (Map B) are hard 404s;
 *   * the county's Hosted/Redistricting_2022 and its 2020 population layers are access-restricted
 *     — and Playwright gets the same rejection, so it is a real restriction, not a UA block.
 *
 * 🔴 AND THE COUNTY IS NOT AN INDEPENDENT CHECK, WHICH ONLY MEASURING SHOWED. Sedgwick County's
 * election service publishes its own Wichita council layer with the same six districts and the same
 * six member names. Reprojected to 4326 its per-district areas agree with the city's to NINE
 * DECIMAL PLACES and its vertex counts match one for one across all 24,716 vertices. It is the same
 * source geometry reprojected from EPSG:3420 instead of 3857. "Two independent sources agree" would
 * have been a false claim that the count-and-name match alone would have supported.
 *
 * 🔴🔴 A COUNCIL BOUNDARY IS NOT FIXED BETWEEN REDISTRICTINGS, SO A GEOMETRY MATCH WOULD BE THE
 * WRONG TEST EVEN WITH THE FILE. Comparing the 2026-05-09 Wayback capture with today: every
 * district's area moved and the TOTAL GREW by 0.211%. A redistricting redistributes area and
 * preserves the total (Lexington's did, to 0.03%); a growing total is ANNEXATION. Map B as adopted
 * no longer equals the operative boundary, so the question is not "does this byte-match Map B" but
 * "is this the boundary in force".
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * SO THE TEST IS POPULATION DEVIATION, AND IT IS FALSIFIABLE.
 *
 * The City's own interoffice memorandum of 2022-09-19 (DAB Feedback on redistricting) records Map B
 * — "this map (which was 2H)" — as "the first map that did not split any new neighborhood
 * associations. It has a total deviation with all six districts and 3.55%."
 *
 * Total deviation is the redistricting term of art: (max district deviation from ideal) minus (min
 * district deviation from ideal), as a percentage of ideal.
 *
 * ▶ THE PREDECESSOR CANNOT PRODUCE THAT NUMBER. It was drawn on 2010 counts and was out of balance
 * on 2020 counts — that is WHY it was replaced. The Commission of Electors was appointed in July
 * 2022 precisely to bring the six districts within five percent of each other.
 *
 * 🔴 WHAT THE GATE ASSERTS, AND WHY IT IS NOT 3.55%. The first version failed unless the figure
 * landed within +/-1.5pp of 3.55%. That window was mine, it happened to pass, and it claimed more
 * than the evidence carries. The 3.55% comes from a TRANSCRIBED DAB discussion whose sentence is
 * garbled, not from a formal apportionment report; the measured figure is 2.40% and does not
 * reproduce it; and ⚠ MAP A WAS DRAWN TO THE SAME STANDARD, so no deviation figure can separate
 * Map A from Map B. The gate therefore asserts the Commission of Electors' own five percent, which
 * the SUPERSEDED map fails by construction — it was drawn on 2010 counts and was out of balance on
 * 2020 counts, which is why it was replaced. That is the failure mode that matters, because Map A
 * was never adopted and so is never what the city publishes.
 *
 * CONTROLS, each of which must FAIL when asked to:
 *   --control=strips   partition the same blocks into six equal-width longitude strips. A valid
 *                      partition that is NOT the map. If this lands near 3.55% the metric is
 *                      measuring nothing and the pass above is worthless.
 *   --control=target   move the expected deviation to a value the real map cannot have.
 *   --control=blocks   drop every block in one district, simulating a broken point-in-polygon.
 * And one positive control that must PASS: the population assigned to the six districts must come
 * within 2% of Wichita city's own 2020 census count of 397,532 (TIGERweb Incorporated Places, layer
 * 26 — ⚠ layer 28 is Census Designated Places and returns a CLEAN EMPTY RESULT for Wichita, which
 * is the TIGERweb wrong-layer trap).
 *
 * ⚠ THE CENSUS DATA API NOW ANSWERS A KEYLESS REQUEST WITH HTTP 200, text/html, and a page titled
 * "Missing Key". Population here comes from TIGERweb's own POP100, never from api.census.gov.
 *
 * Usage:
 *   node scripts/verify-wichita-council-vintage.mjs
 *   node scripts/verify-wichita-council-vintage.mjs --control=strips
 *   node scripts/verify-wichita-council-vintage.mjs --self-test     (runs every control)
 */

const UA = { 'User-Agent': 'ev-accounts/ks-slice14' };
const CITY_LAYER =
  'https://gismaps.wichita.gov/ageweb/rest/services/COWGIS/Districts/MapServer/3';
const TIGER_BLOCKS =
  'https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/tigerWMS_Census2020/MapServer/10';
const TIGER_PLACES =
  'https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/tigerWMS_Census2020/MapServer/26';

const EXPECTED_DISTRICTS = 6;
const MAP_B_DEVIATION = 3.55;       // City of Wichita interoffice memo, 2022-09-19
const COMMISSION_CEILING = 5.0;     // the Commission of Electors' own target
const WICHITA_POP_2020 = 397532;    // TIGERweb Incorporated Places, GEOID 2079000
const POP_TOLERANCE_PCT = 2.0;

const arg = (k) => process.argv.find((a) => a.startsWith(`--${k}=`))?.split('=')[1];
const CONTROL = arg('control') ?? null;
const SELF_TEST = process.argv.includes('--self-test');

const fail = (m) => { console.error(`\n🔴 ${m}`); process.exitCode = 1; throw new Error(m); };

async function getJson(url, label) {
  const r = await fetch(url, { headers: UA });
  const text = await r.text();
  // 🔴 A CLEAN HTTP 200 LIES. Judge by the body, never by r.ok — census.gov returns an HTML
  // "Missing Key" page with status 200, and the county's WAF returns "Request Rejected" the same way.
  if (/^\s*</.test(text)) fail(`${label}: got HTML, not JSON (${r.status}) — ${text.slice(0, 120)}`);
  let j;
  try { j = JSON.parse(text); } catch { fail(`${label}: unparseable body (${r.status})`); }
  if (j.error) fail(`${label}: ${JSON.stringify(j.error)}`);
  // A truncated answer is also a clean 200.
  if (j.exceededTransferLimit) fail(`${label}: the service paged — refusing a partial answer`);
  return j;
}

/** Ray casting against one ring. */
function inRing(ring, x, y) {
  let c = false;
  for (let i = 0, n = ring.length - 1; i < n; i++) {
    const [x1, y1] = ring[i], [x2, y2] = ring[i + 1];
    if ((y1 > y) !== (y2 > y) && x < ((x2 - x1) * (y - y1)) / (y2 - y1) + x1) c = !c;
  }
  return c;
}

function polygons(geom) {
  return geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
}

function contains(geom, x, y) {
  let inside = false;
  for (const poly of polygons(geom)) {
    if (inRing(poly[0], x, y)) {
      let inHole = false;
      for (let h = 1; h < poly.length; h++) if (inRing(poly[h], x, y)) { inHole = true; break; }
      if (!inHole) inside = !inside;
    }
  }
  return inside;
}

function bbox(geom) {
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  for (const poly of polygons(geom)) for (const [x, y] of poly[0]) {
    if (x < x0) x0 = x; if (x > x1) x1 = x;
    if (y < y0) y0 = y; if (y > y1) y1 = y;
  }
  return [x0, y0, x1, y1];
}

/** Total deviation: (max - min) spread around the ideal, as a percentage of ideal. */
function totalDeviation(pops) {
  const total = pops.reduce((a, b) => a + b, 0);
  const ideal = total / pops.length;
  const devs = pops.map((p) => ((p - ideal) / ideal) * 100);
  return { total, ideal, devs, spread: Math.max(...devs) - Math.min(...devs) };
}

async function load() {
  const districts = await getJson(
    `${CITY_LAYER}/query?where=1%3D1&outFields=COUNCIL&outSR=4326&returnGeometry=true&f=geojson`,
    'city council layer',
  );
  const feats = districts.features ?? [];
  if (feats.length !== EXPECTED_DISTRICTS) {
    fail(`city layer: ${feats.length} districts, expected ${EXPECTED_DISTRICTS}`);
  }
  const nums = feats.map((f) => Number(f.properties.COUNCIL)).sort((a, b) => a - b);
  if (nums.join() !== [1, 2, 3, 4, 5, 6].join()) {
    fail(`city layer: district numbers are ${nums.join()}, expected 1..6 contiguous`);
  }

  const blocks = await getJson(
    `${TIGER_BLOCKS}/query?where=STATE%3D%2720%27+AND+COUNTY%3D%27173%27` +
      `&outFields=GEOID,POP100,INTPTLAT,INTPTLON&returnGeometry=false&f=json&resultRecordCount=100000`,
    'TIGERweb 2020 blocks',
  );

  const place = await getJson(
    `${TIGER_PLACES}/query?where=STATE%3D%2720%27+AND+BASENAME%3D%27Wichita%27` +
      `&outFields=GEOID,NAME,POP100&returnGeometry=false&f=json`,
    'TIGERweb incorporated places',
  );
  const wichita = (place.features ?? []).find((f) => f.attributes.GEOID === '2079000');
  if (!wichita) fail('TIGERweb: Wichita city (GEOID 2079000) not found in layer 26');

  return { feats, blocks: blocks.features ?? [], placePop: wichita.attributes.POP100 };
}

function assign(feats, blocks, mode) {
  const geoms = new Map(feats.map((f) => [Number(f.properties.COUNCIL), f.geometry]));
  const boxes = new Map([...geoms].map(([d, g]) => [d, bbox(g)]));
  const pops = new Map([...geoms.keys()].map((d) => [d, 0]));
  let assigned = 0, multi = 0, outside = 0;

  // The strips control needs the same blocks partitioned a DIFFERENT way, so it shares the
  // city-wide bbox rather than inventing its own extent.
  let lo = Infinity, hi = -Infinity;
  for (const [, b] of boxes) { if (b[0] < lo) lo = b[0]; if (b[2] > hi) hi = b[2]; }

  for (const b of blocks) {
    const a = b.attributes;
    const x = Number(a.INTPTLON), y = Number(a.INTPTLAT);
    const pop = Number(a.POP100) || 0;
    if (!Number.isFinite(x) || !Number.isFinite(y)) continue;

    if (mode === 'strips') {
      // Six equal-width longitude strips across the city's own extent. A real partition, wrong map.
      let inAny = false;
      for (const [, g] of geoms) if (contains(g, x, y)) { inAny = true; break; }
      if (!inAny) { outside++; continue; }
      const k = Math.min(5, Math.floor(((x - lo) / (hi - lo)) * 6));
      pops.set(k + 1, pops.get(k + 1) + pop);
      assigned++;
      continue;
    }

    const hits = [];
    for (const [d, g] of geoms) {
      const bx = boxes.get(d);
      if (x < bx[0] || x > bx[2] || y < bx[1] || y > bx[3]) continue;
      if (contains(g, x, y)) hits.push(d);
    }
    if (hits.length === 0) { outside++; continue; }
    if (hits.length > 1) multi++;
    if (mode === 'blocks' && hits[0] === 1) continue; // tamper: lose district 1 entirely
    pops.set(hits[0], pops.get(hits[0]) + pop);
    assigned++;
  }
  return { pops, assigned, multi, outside };
}

async function run(mode) {
  const { feats, blocks, placePop } = await load();
  console.log(`districts: ${feats.length} · blocks in Sedgwick County: ${blocks.length.toLocaleString()}`);
  console.log(`Wichita city 2020 population (TIGERweb layer 26): ${placePop.toLocaleString()}`);
  if (placePop !== WICHITA_POP_2020) {
    fail(`Wichita place population is ${placePop}, expected ${WICHITA_POP_2020} — the constant is stale`);
  }

  const { pops, assigned, multi, outside } = assign(feats, blocks, mode);
  const ordered = [1, 2, 3, 4, 5, 6].map((d) => pops.get(d));
  const { total, ideal, devs, spread } = totalDeviation(ordered);

  console.log(`\nblocks assigned ${assigned.toLocaleString()} · outside the city ${outside.toLocaleString()} · in two districts ${multi}`);
  if (multi > 0) fail(`${multi} block(s) fell in more than one district — the polygons overlap`);

  console.log(`\n${'dist'.padStart(5)} ${'population'.padStart(12)} ${'deviation'.padStart(11)}`);
  ordered.forEach((p, i) => {
    console.log(`${String(i + 1).padStart(5)} ${p.toLocaleString().padStart(12)} ${devs[i].toFixed(2).padStart(10)}%`);
  });
  console.log(`${'TOT'.padStart(5)} ${total.toLocaleString().padStart(12)}   ideal ${Math.round(ideal).toLocaleString()}`);
  console.log(`\ntotal deviation: ${spread.toFixed(2)}%   (Map B as adopted: ${MAP_B_DEVIATION}%)`);

  // ── positive control: the six districts must account for Wichita ───────────────────────────
  const popDiffPct = Math.abs(total - WICHITA_POP_2020) / WICHITA_POP_2020 * 100;
  console.log(`assigned vs Wichita city 2020: ${(total - WICHITA_POP_2020).toLocaleString()} (${popDiffPct.toFixed(2)}%)`);
  if (mode === null && popDiffPct > POP_TOLERANCE_PCT) {
    fail(`the six districts account for ${total.toLocaleString()} against the city's ${WICHITA_POP_2020.toLocaleString()} ` +
         `— ${popDiffPct.toFixed(2)}% apart, over the ${POP_TOLERANCE_PCT}% tolerance. The point-in-polygon or the ` +
         `block set is wrong, so NOTHING below can be trusted.`);
  }

  // 🔴 THE GATE ASSERTS WHAT THE TEST ACTUALLY PROVES, WHICH IS NOT "THIS IS MAP B".
  //
  // The first version of this file failed unless the figure landed within +/-1.5pp of 3.55%. That
  // window was chosen by me, it happened to pass, and it claimed more than the evidence carries:
  //   * the 3.55% comes from a TRANSCRIBED DAB discussion whose sentence is garbled — "It has a
  //     total deviation with all six districts and 3.55%" — not from a formal apportionment report;
  //   * the measured figure is 2.40%, which does NOT reproduce 3.55%, and the residual is explained
  //     but not eliminated (whole-block assignment by internal point, against a boundary that has
  //     annexed land since adoption);
  //   * ⚠ and MAP A WAS DRAWN TO THE SAME STANDARD, so no deviation figure can separate Map A from
  //     Map B. What it CAN separate is a post-2020 map from the pre-2023 one.
  //
  // So the assertion is the Commission of Electors' own standard, which the superseded map fails by
  // construction: it was drawn on 2010 counts and was out of balance on 2020 counts, which is why it
  // was replaced. `--control=target` tightens the gate onto 3.55% to prove the looser one still bites.
  const ceiling = mode === 'target' ? 1.0 : COMMISSION_CEILING;
  if (spread > ceiling) {
    fail(`total deviation ${spread.toFixed(2)}% exceeds the ${ceiling}% ceiling.\n` +
         `   The Commission of Electors was appointed to bring the six districts within five percent on\n` +
         `   2020 counts. A map this far out was not drawn on 2020 data — check whether the layer is\n` +
         `   serving the pre-2023 boundary before loading anything.`);
  }

  console.log(`\n🟢 PASS — the six polygons are balanced on 2020 counts to ${spread.toFixed(2)}% total deviation, ` +
              `inside the ${COMMISSION_CEILING}% the Commission of Electors worked to,`);
  console.log(`   and they account for Wichita city to ${popDiffPct.toFixed(2)}%.`);
  console.log(`   ▶ That is a POST-2020 map. Reported for context, not asserted: Map B was discussed at ` +
              `${MAP_B_DEVIATION}%; this measures ${spread.toFixed(2)}%.`);
  console.log(`   ⚠ This CANNOT distinguish Map A from Map B — both were drawn to the same standard. It ` +
              `rules out the superseded map, which is the failure mode that matters.`);
  return spread;
}

if (SELF_TEST) {
  console.log('=== SELF-TEST: every control must FAIL ===\n');
  let failures = 0;
  for (const c of ['strips', 'target', 'blocks']) {
    console.log(`\n--- control=${c} ---`);
    try { await run(c); console.error(`🔴 control ${c} PASSED — it must fail`); }
    catch { failures++; console.log(`✅ control ${c} failed as required`); }
  }
  process.exitCode = failures === 3 ? 0 : 1;
  console.log(`\n${failures}/3 controls failed as required`);
} else {
  await run(CONTROL);
}
