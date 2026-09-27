#!/usr/bin/env node
/**
 * verify-sedgwick-bocc-vintage.mjs — Knight program, wave KS-4.
 *
 * Answers ONE question: are the five polygons served as Sedgwick County's commission districts
 * drawn on the 2020 census, or is the service still publishing the pre-2022 plan? Needs no
 * database.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * WHY THIS IS NOT A COMPARISON AGAINST A SECOND SOURCE.
 *
 * 🔴 THREE ORGANISATIONS PUBLISH THIS MAP AND ALL THREE ARE THE SAME DIGITIZATION. The handoff
 * from KS-3 recorded "layer 1 BOCC" as stage 4's geometry; that is the CITY OF WICHITA's copy.
 * The county serves two of its own:
 *
 *     gismaps.wichita.gov      COWGIS/Districts                   layer 1  BOCC
 *     gismaps.sedgwickcounty   Map/Op_ElectionBOCC_Dynamic_SP     layer 0  County Commission Districts
 *     gismaps.sedgwickcounty   Map/Op_Election_Dynamic_SP         layer 6  County Commission
 *
 * All three return 5 features with the same five member names, and their reported Shape.STArea()
 * agrees to ONE PART IN 10^8 per district. A city and a county agreeing looks like independent
 * corroboration and is not: it is one file republished. ⚠ `Map/Op_Election_Dynamic_SP` layer 1 is
 * `Election Dropboxes`, a POINT layer — the handoff pointed at the wrong index on the wrong host.
 *
 * ▶ So the test is population deviation, as in KS-3, and it is falsifiable.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * WHAT THE GATE ASSERTS, AND WHAT IT DOES NOT.
 *
 * KSA 19-204 requires commissioner districts "as compact and equal in population as possible" and
 * subject to alteration at least once every three years. It fixes no percentage, so the ceiling
 * here is the conventional 10% total deviation that local districting works to — NOT a figure
 * transcribed from a county document, because no such figure was found.
 *
 * ▶ WHAT IT PROVES: a plan balanced on 2020 counts. The pre-2022 plan was drawn on 2010 counts and
 *   cannot be balanced on 2020 ones — that is why 19-204 forces reapportionment.
 * ⚠ WHAT IT DOES NOT PROVE: that this is the LATEST resolution. 19-204 allows alteration every
 *   three years, and a 2025 alteration would also be drawn on 2020 counts and would also pass.
 *   Corroboration only, never proof: the layer's own BOCCRepNM attribute names Blubaugh and Wise,
 *   who took office in January 2025, so it was maintained at least that recently. KY-2 found a
 *   state layer carrying a current roster beside stale geometry, so this is recorded and not relied on.
 *
 * THE POSITIVE CONTROL IS AN EXACT EQUALITY, WHICH IS STRONGER THAN KS-3's TOLERANCE.
 * The five districts partition a WHOLE COUNTY, so the population they account for must equal
 * TIGERweb's own county figure exactly — not within 2%. Any point-in-polygon error, any gap and
 * any missing block shows up immediately.
 *
 * CONTROLS, each of which must FAIL when asked to:
 *   --control=strips   five equal-width longitude strips over the same blocks. A valid partition
 *                      that is not the map. If this lands near the real figure the metric is
 *                      measuring nothing.
 *   --control=bands    the same, in latitude — because a county elongated one way could make the
 *                      strips control pass for the wrong reason.
 *   --control=blocks   drop every block in district 3, simulating a broken point-in-polygon.
 *   --control=target   tighten the ceiling to 0.05% to prove the loose ceiling still bites.
 *
 * ⚠ Do not reach for api.census.gov: a keyless request there returns HTTP 200 with an HTML page
 * titled "Missing Key". Population here comes from TIGERweb's own POP100.
 *
 * Usage:
 *   node scripts/verify-sedgwick-bocc-vintage.mjs
 *   node scripts/verify-sedgwick-bocc-vintage.mjs --control=strips
 *   node scripts/verify-sedgwick-bocc-vintage.mjs --self-test     (runs every control)
 */
import { pathToFileURL } from 'node:url';

const UA = { 'User-Agent': 'ev-accounts/ks-slice14' };
const BOCC_LAYER =
  'https://gismaps.sedgwickcounty.org/arcgis/rest/services/Map/Op_ElectionBOCC_Dynamic_SP/MapServer/0';
const TIGER_BLOCKS =
  'https://tigerweb.geo.census.gov/arcgis/rest/services/Census2020/tigerWMS_Census2020/MapServer/10';
const TIGER_COUNTIES =
  'https://tigerweb.geo.census.gov/arcgis/rest/services/Census2020/tigerWMS_Census2020/MapServer/82';

const EXPECTED_DISTRICTS = 5;
export const SEDGWICK_GEOID = '20173';
export const SEDGWICK_POP_2020 = 523824; // TIGERweb Counties layer 82, GEOID 20173
export const DEVIATION_CEILING = 10.0; // the conventional local-districting standard

const arg = (k) => process.argv.find((a) => a.startsWith(`--${k}=`))?.split('=')[1];
const CONTROL = arg('control') ?? null;
const SELF_TEST = process.argv.includes('--self-test');

const fail = (m) => { console.error(`\n🔴 ${m}`); process.exitCode = 1; throw new Error(m); };

async function getJson(url, label) {
  const r = await fetch(url, { headers: UA });
  const text = await r.text();
  // 🔴 A CLEAN HTTP 200 LIES. Judge by the body, never by r.ok — the county's WAF returns
  // "Request Rejected" as HTML with a 200, and census.gov returns a "Missing Key" page the same way.
  if (/^\s*</.test(text)) fail(`${label}: got HTML, not JSON (${r.status}) — ${text.slice(0, 120)}`);
  let j;
  try { j = JSON.parse(text); } catch { fail(`${label}: unparseable body (${r.status})`); }
  if (j.error) fail(`${label}: ${JSON.stringify(j.error)}`);
  if (j.exceededTransferLimit) fail(`${label}: the service paged — refusing a partial answer`);
  return j;
}

function polygons(geom) {
  return geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
}

function inRing(ring, x, y) {
  let c = false;
  for (let i = 0, n = ring.length - 1; i < n; i++) {
    const [x1, y1] = ring[i], [x2, y2] = ring[i + 1];
    if ((y1 > y) !== (y2 > y) && x < ((x2 - x1) * (y - y1)) / (y2 - y1) + x1) c = !c;
  }
  return c;
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
export function totalDeviation(pops) {
  const total = pops.reduce((a, b) => a + b, 0);
  const ideal = total / pops.length;
  const devs = pops.map((p) => ((p - ideal) / ideal) * 100);
  return { total, ideal, devs, spread: Math.max(...devs) - Math.min(...devs) };
}

export async function load() {
  const districts = await getJson(
    `${BOCC_LAYER}/query?where=1%3D1&outFields=BOCCDistNO,BOCCRepNM&outSR=4326&returnGeometry=true&f=geojson`,
    'Sedgwick County BOCC layer',
  );
  const feats = districts.features ?? [];
  if (feats.length !== EXPECTED_DISTRICTS) {
    fail(`BOCC layer: ${feats.length} districts, expected ${EXPECTED_DISTRICTS}`);
  }
  const nums = feats.map((f) => Number(f.properties.BOCCDistNO)).sort((a, b) => a - b);
  if (nums.join() !== [1, 2, 3, 4, 5].join()) {
    fail(`BOCC layer: district numbers are ${nums.join()}, expected 1..5 contiguous`);
  }

  const blocks = await getJson(
    `${TIGER_BLOCKS}/query?where=STATE%3D%2720%27+AND+COUNTY%3D%27173%27` +
      `&outFields=GEOID,POP100,INTPTLAT,INTPTLON&returnGeometry=false&f=json&resultRecordCount=100000`,
    'TIGERweb 2020 blocks',
  );

  const county = await getJson(
    `${TIGER_COUNTIES}/query?where=GEOID%3D%27${SEDGWICK_GEOID}%27&outFields=GEOID,NAME,POP100` +
      `&returnGeometry=false&f=json`,
    'TIGERweb counties',
  );
  const row = (county.features ?? [])[0];
  if (!row) fail(`TIGERweb: county ${SEDGWICK_GEOID} not found in layer 82`);

  return { feats, blocks: blocks.features ?? [], countyPop: row.attributes.POP100 };
}

export function assign(feats, blocks, mode) {
  const geoms = new Map(feats.map((f) => [Number(f.properties.BOCCDistNO), f.geometry]));
  const boxes = new Map([...geoms].map(([d, g]) => [d, bbox(g)]));
  const pops = new Map([...geoms.keys()].map((d) => [d, 0]));
  let assigned = 0, multi = 0, outside = 0;

  // The strips and bands controls need the same blocks partitioned a DIFFERENT way, so they share
  // the county's own extent rather than inventing one.
  let xlo = Infinity, xhi = -Infinity, ylo = Infinity, yhi = -Infinity;
  for (const [, b] of boxes) {
    if (b[0] < xlo) xlo = b[0]; if (b[2] > xhi) xhi = b[2];
    if (b[1] < ylo) ylo = b[1]; if (b[3] > yhi) yhi = b[3];
  }

  for (const b of blocks) {
    const a = b.attributes;
    const x = Number(a.INTPTLON), y = Number(a.INTPTLAT);
    const pop = Number(a.POP100) || 0;
    if (!Number.isFinite(x) || !Number.isFinite(y)) continue;

    if (mode === 'strips' || mode === 'bands') {
      let inAny = false;
      for (const [, g] of geoms) if (contains(g, x, y)) { inAny = true; break; }
      if (!inAny) { outside++; continue; }
      const k = mode === 'strips'
        ? Math.min(4, Math.floor(((x - xlo) / (xhi - xlo)) * 5))
        : Math.min(4, Math.floor(((y - ylo) / (yhi - ylo)) * 5));
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
    if (mode === 'blocks' && hits[0] === 3) continue; // tamper: lose district 3 entirely
    pops.set(hits[0], pops.get(hits[0]) + pop);
    assigned++;
  }
  return { pops, assigned, multi, outside };
}

export async function run(mode) {
  const { feats, blocks, countyPop } = await load();
  const names = feats
    .slice()
    .sort((a, b) => a.properties.BOCCDistNO - b.properties.BOCCDistNO)
    .map((f) => `${f.properties.BOCCDistNO}:${f.properties.BOCCRepNM}`)
    .join(' · ');
  console.log(`districts: ${feats.length} · blocks in Sedgwick County: ${blocks.length.toLocaleString()}`);
  console.log(`layer roster (CORROBORATION ONLY, never a vintage proof): ${names}`);
  if (countyPop !== SEDGWICK_POP_2020) {
    fail(`TIGERweb county population is ${countyPop}, expected ${SEDGWICK_POP_2020} — the constant is stale`);
  }

  const { pops, assigned, multi, outside } = assign(feats, blocks, mode);
  const ordered = [1, 2, 3, 4, 5].map((d) => pops.get(d));
  const { total, ideal, devs, spread } = totalDeviation(ordered);

  console.log(`\nblocks assigned ${assigned.toLocaleString()} · outside every district ${outside.toLocaleString()} · in two districts ${multi}`);
  if (multi > 0) fail(`${multi} block(s) fell in more than one district — the polygons overlap`);

  console.log(`\n${'dist'.padStart(5)} ${'population'.padStart(12)} ${'deviation'.padStart(11)}`);
  ordered.forEach((p, i) => {
    console.log(`${String(i + 1).padStart(5)} ${p.toLocaleString().padStart(12)} ${devs[i].toFixed(2).padStart(10)}%`);
  });
  console.log(`${'TOT'.padStart(5)} ${total.toLocaleString().padStart(12)}   ideal ${Math.round(ideal).toLocaleString()}`);
  console.log(`\ntotal deviation: ${spread.toFixed(2)}%   (ceiling ${DEVIATION_CEILING}%)`);

  // ── positive control: the five districts partition a WHOLE COUNTY, so this is an EQUALITY ────
  console.log(`assigned vs Sedgwick County 2020: ${total.toLocaleString()} vs ${SEDGWICK_POP_2020.toLocaleString()}`);
  if (mode === null && total !== SEDGWICK_POP_2020) {
    fail(`the five districts account for ${total.toLocaleString()} against the county's ` +
         `${SEDGWICK_POP_2020.toLocaleString()}. These must be EQUAL — the districts tile the county. ` +
         `The point-in-polygon or the block set is wrong, so NOTHING below can be trusted.`);
  }

  const ceiling = mode === 'target' ? 0.05 : DEVIATION_CEILING;
  if (spread > ceiling) {
    fail(`total deviation ${spread.toFixed(2)}% exceeds the ${ceiling}% ceiling.\n` +
         `   KSA 19-204 requires districts "as compact and equal in population as possible" and forces\n` +
         `   reapportionment. A map this far out on 2020 counts was not drawn on 2020 data — check whether\n` +
         `   the layer is serving the pre-2022 boundary before loading anything.`);
  }

  console.log(`\n🟢 PASS — the five polygons are balanced on 2020 counts to ${spread.toFixed(2)}% total deviation,`);
  console.log(`   and they account for Sedgwick County EXACTLY (${total.toLocaleString()}).`);
  console.log(`   ▶ That is a POST-2020 map: the pre-2022 plan was drawn on 2010 counts.`);
  console.log(`   ⚠ It CANNOT show this is the latest resolution — 19-204 allows alteration every three`);
  console.log(`     years, and a later alteration would be drawn on 2020 counts too.`);
  return spread;
}

const IS_MAIN = import.meta.url === pathToFileURL(process.argv[1] ?? '').href;

if (IS_MAIN) {
  if (SELF_TEST) {
    // 🔴 A CONTROL THAT PASSES CAN PASS FOR THE WRONG REASON. Every control below must be WATCHED
    // FAILING; a control that never fails proves nothing about the gate it is guarding.
    const controls = ['strips', 'bands', 'blocks', 'target'];
    let ok = true;
    console.log('── the real measurement ──────────────────────────────────────────────');
    await run(null);
    for (const c of controls) {
      console.log(`\n── control: ${c} (MUST FAIL) ─────────────────────────────────────────`);
      let threw = false;
      try {
        await run(c);
      } catch {
        threw = true;
      }
      process.exitCode = 0;
      console.log(threw ? `🟢 control ${c} failed, as required` : `🔴 control ${c} PASSED — the gate is not measuring anything`);
      if (!threw) ok = false;
    }
    if (!ok) { console.error('\n🔴 SELF-TEST FAILED'); process.exitCode = 1; }
    else console.log('\n🟢 SELF-TEST PASSED — every control failed when asked to');
  } else {
    await run(CONTROL);
  }
}
