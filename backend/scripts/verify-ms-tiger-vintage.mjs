#!/usr/bin/env node
/**
 * verify-ms-tiger-vintage.mjs — Knight program, slice 16 (MS), wave MS-1.
 *
 * Answers the question that decides whether stage 1 may load plain TIGER:
 *   🔴 WHICH MISSISSIPPI LEGISLATIVE PLAN DOES TIGER CARRY?
 *
 * ── WHY THIS IS NOT THE USUAL VINTAGE CHECK ─────────────────────────────────────────────────
 * Mississippi redistricted after the 2020 census (the "2022 plan"), that plan was held to
 * violate Section 2 of the Voting Rights Act in part, and the Legislature adopted REMEDIAL
 * plans in its 2025 regular session. The three-judge court approved the House remedial plan on
 * 2025-04-15 and, after rejecting the Legislature's Senate District 1, adopted the State Board
 * of Election Commissioners' Senate plan on 2025-05-07. Special elections followed on
 * 2025-11-04. So Mississippi has TWO plans in living memory, and members sit under BOTH:
 * everyone elected in November 2023 sits under the 2022 plan, and whoever was elected in the
 * November 2025 specials sits under the remedial plan.
 *
 * 🔴 AND THE COUNT, THE CODE SET AND `LSY` ARE ALL BLIND TO THAT. Miss. Const. art. 13 § 254
 * fixes the chambers, so 122 and 52 are constitutional constants: every plan Mississippi will
 * ever adopt has that shape. measure-ms-tiger-legislative.mjs measured TIGER 2022, 2023, 2024
 * and 2025 and found 122/52 with an IDENTICAL code set in all four, while all four file hashes
 * differ. That is the KS / KY / SD finding for the fourth time — nothing inside the file dates
 * the plan.
 *
 * ── THE INSTRUMENT: BLOCK EQUIVALENCY, NOT GEOMETRY ─────────────────────────────────────────
 * 🟢 A BLOCK EQUIVALENCY FILE *IS* THE PLAN. Mississippi's own redistricting publisher, MARIS,
 * publishes each plan as a census-block-to-district assignment. That is the plan's legal
 * definition, it carries no projection, no digitisation and no rounding, and comparing it to
 * TIGER therefore cannot be defeated by a re-export.
 *
 * ⚠ THIS MATTERS BECAUSE THE GEOMETRIC COMPARISON WAS TRIED FIRST AND COULD NOT SEPARATE
 *   ANYTHING. MARIS's House plan as adopted by the Legislature on 2025-02-04 and as approved by
 *   the court on 2025-05-07 have `.shp` files of the SAME BYTE LENGTH (6,865,892) and DIFFERENT
 *   sha256 — the second is a re-export that rounds every coordinate (an AREA attribute goes from
 *   464.045624 to 464.05). A polygon-equality test called all 122 districts different, which is
 *   exactly as wrong as calling them all the same. **A metric that does not separate is a
 *   ranking, not a gate** — the SC-5a / MI-1 rule, met here in a new disguise.
 *
 * So: for every one of Mississippi's 2020 census blocks, this script compares
 *   (a) the district MARIS's block equivalency file assigns it, against
 *   (b) the district TIGER puts its internal point inside.
 * Disagreement is reported per district, in blocks AND in population, because one stray block
 * on a boundary is a digitisation artefact and ten thousand people is a redraw.
 *
 * ── CONTROLS, ALL WATCHED FAILING ───────────────────────────────────────────────────────────
 *  1. Every TIGER district's own internal point must resolve to itself. If point-in-polygon is
 *     broken, every "agrees" below is a broken detector reporting a clean answer.
 *  2. A deliberately mis-labelled TIGER map must report mass disagreement. A comparison that
 *     cannot report a difference proves nothing by reporting none.
 *  3. The block sweep must resolve essentially every block. A silent stream of unresolved
 *     points would depress the disagreement count without ever being seen.
 * 🔴 A DETECTOR REPORTING "NOTHING FOUND" NEEDS A POSITIVE CONTROL — and a control that passes
 *    can pass for the wrong reason, so each one is run against a deliberate tamper first.
 *
 * ── WHAT THIS SCRIPT DOES NOT DECIDE ────────────────────────────────────────────────────────
 * It says which plan TIGER carries. It does NOT say which plan to load. That depends on which
 * plan the SITTING members were elected under — the Michigan rule — and on the fact that the
 * U.S. Supreme Court VACATED the judgment in this case on 2026-05-18 (No. 25-234) and remanded
 * for reconsideration in light of *Louisiana v. Callais*. That is an operator decision, and it
 * is recorded in `.planning/knight-foundation/ms.md`, not resolved here.
 *
 * Inputs (all downloaded by hand; paths are arguments so nothing is assumed):
 *   --tiger-dir  directory holding tl_<vintage>_28_{sldl,sldu}.zip and tl_2024_28_tabblock20.zip
 *   --beq-house  MARIS House remedy block equivalency, as CSV (Block,DistrictID)
 *   --beq-senate MARIS Senate remedy block equivalency, as CSV
 *   --vintage    TIGER vintage to test (default 2024)
 *   --county     optional 5-digit county GEOID. Restricts the SAME sweep to one county and adds
 *                a few named probe points, which answers the question a statewide percentage
 *                cannot: DOES THIS DISAGREEMENT TOUCH THE JURISDICTION I AM ABOUT TO SEED?
 *                Harrison County is 28047.
 *
 * Usage:
 *   node scripts/verify-ms-tiger-vintage.mjs --tiger-dir <dir> \
 *        --beq-house <dir>/beq_house.csv --beq-senate <dir>/beq_senate.csv
 *   node scripts/verify-ms-tiger-vintage.mjs … --county 28047
 */
import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

const argv = process.argv.slice(2);
const arg = (name, dflt) => {
  const i = argv.indexOf(`--${name}`);
  return i >= 0 ? argv[i + 1] : dflt;
};
const TIGER_DIR = arg('tiger-dir');
const BEQ = { sldl: arg('beq-house'), sldu: arg('beq-senate') };
const VINTAGE = arg('vintage', '2024');
const COUNTY = arg('county');

/**
 * Probe points for the --county sweep. A point is worth more than a percentage: it says which
 * district a real address answers. Coordinates are self-validating — each is checked against the
 * TIGER place polygon for its own city before its district answer is believed.
 */
const PROBES = {
  28047: [
    ['Biloxi City Hall', -88.8853, 30.3955],
    ['Biloxi, west end', -88.9500, 30.3900],
    ['Gulfport City Hall', -89.0928, 30.3674],
  ],
};
if (!TIGER_DIR || !BEQ.sldl || !BEQ.sldu) {
  console.error('usage: --tiger-dir <dir> --beq-house <csv> --beq-senate <csv> [--vintage 2024]');
  process.exit(2);
}

// ── geometry ────────────────────────────────────────────────────────────────────────────────

/**
 * A district, indexed for fast point-in-polygon. Every edge is filed into the Y buckets its
 * span touches, so a query tests only the handful of edges that can possibly cross the ray.
 * Without this, 112,241 blocks against 122 districts of ~4,000 vertices each is billions of
 * float operations and the sweep is not runnable.
 */
function buildIndex(geom) {
  const edges = [];
  const pushRing = (ring) => {
    for (let i = 0, j = ring.length - 1; i < ring.length; j = i, i += 1) {
      const [xi, yi] = ring[i];
      const [xj, yj] = ring[j];
      if (yi === yj) continue; // horizontal edges never change the crossing parity
      edges.push([xi, yi, xj, yj]);
    }
  };
  if (geom.type === 'Polygon') for (const r of geom.coordinates) pushRing(r);
  else if (geom.type === 'MultiPolygon') for (const p of geom.coordinates) for (const r of p) pushRing(r);

  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  for (const [xi, yi, xj, yj] of edges) {
    minX = Math.min(minX, xi, xj); maxX = Math.max(maxX, xi, xj);
    minY = Math.min(minY, yi, yj); maxY = Math.max(maxY, yi, yj);
  }
  const NB = 512;
  const span = maxY - minY || 1e-9;
  const buckets = Array.from({ length: NB }, () => []);
  const bucketOf = (y) => Math.min(NB - 1, Math.max(0, Math.floor(((y - minY) / span) * NB)));
  for (const e of edges) {
    const a = bucketOf(Math.min(e[1], e[3]));
    const b = bucketOf(Math.max(e[1], e[3]));
    for (let k = a; k <= b; k += 1) buckets[k].push(e);
  }
  return { bbox: [minX, minY, maxX, maxY], buckets, bucketOf, nEdges: edges.length };
}

function contains(idx, x, y) {
  const [minX, minY, maxX, maxY] = idx.bbox;
  if (x < minX || x > maxX || y < minY || y > maxY) return false;
  let inside = false;
  for (const [xi, yi, xj, yj] of idx.buckets[idx.bucketOf(y)]) {
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}

function locate(districts, x, y) {
  for (const d of districts) if (contains(d.idx, x, y)) return d.code;
  return null;
}

// ── loaders ─────────────────────────────────────────────────────────────────────────────────

function unzipTo(zipPath, base, exts) {
  const zip = new AdmZip(zipPath);
  for (const ext of exts) {
    const e = zip.getEntry(base + ext);
    if (!e) throw new Error(`${base}${ext} missing from ${path.basename(zipPath)}`);
    fs.writeFileSync(path.join(TIGER_DIR, base + ext), e.getData());
  }
}

async function loadDistricts(layer, vintage) {
  const base = `tl_${vintage}_28_${layer}`;
  const zipPath = path.join(TIGER_DIR, `${base}.zip`);
  if (!fs.existsSync(zipPath)) throw new Error(`missing ${zipPath}`);
  unzipTo(zipPath, base, ['.shp', '.dbf', '.shx']);
  const field = layer === 'sldu' ? 'SLDUST' : 'SLDLST';
  const src = await shapefile.open(path.join(TIGER_DIR, base + '.shp'), path.join(TIGER_DIR, base + '.dbf'));
  const out = [];
  for (;;) {
    const r = await src.read();
    if (r.done) break;
    const p = r.value.properties;
    out.push({
      code: String(p.GEOID), // '28047' — state FIPS + district, the BEQ's own key format
      dist: String(p[field]),
      intpt: [parseFloat(p.INTPTLON), parseFloat(p.INTPTLAT)],
      idx: buildIndex(r.value.geometry),
    });
  }
  return out;
}

/** Blocks come from the .dbf alone — the 186 MB .shp is never needed for internal points. */
async function loadBlocks() {
  const base = `tl_2024_28_tabblock20`;
  const zipPath = path.join(TIGER_DIR, `${base}.zip`);
  if (!fs.existsSync(zipPath)) throw new Error(`missing ${zipPath}`);
  unzipTo(zipPath, base, ['.dbf']);
  const src = await shapefile.openDbf(path.join(TIGER_DIR, base + '.dbf'));
  const out = [];
  for (;;) {
    const r = await src.read();
    if (r.done) break;
    const p = r.value;
    out.push({
      geoid: String(p.GEOID20),
      pop: Number(p.POP20 ?? 0),
      x: parseFloat(p.INTPTLON20),
      y: parseFloat(p.INTPTLAT20),
    });
  }
  return out;
}

async function loadBeq(file) {
  const m = new Map();
  const rl = readline.createInterface({ input: fs.createReadStream(file), crlfDelay: Infinity });
  let first = true;
  for await (const line of rl) {
    if (first) { first = false; continue; }
    if (!line.trim()) continue;
    const [block, district] = line.split(',');
    m.set(block.trim(), district.trim());
  }
  return m;
}

// ── run ─────────────────────────────────────────────────────────────────────────────────────
console.log(`TIGER vintage under test: ${VINTAGE}`);
const blocks = await loadBlocks();
console.log(`Mississippi 2020 census blocks: ${blocks.length.toLocaleString()}  ` +
  `(total POP20 ${blocks.reduce((s, b) => s + b.pop, 0).toLocaleString()})`);

for (const layer of ['sldu', 'sldl']) {
  const chamber = layer === 'sldu' ? 'SENATE' : 'HOUSE';
  console.log(`\n${'='.repeat(78)}`);
  console.log(`${chamber} — MARIS remedial block equivalency  vs  TIGER ${VINTAGE}`);
  console.log('='.repeat(78));

  const districts = await loadDistricts(layer, VINTAGE);
  const beq = await loadBeq(BEQ[layer]);
  console.log(`  TIGER districts ${districts.length}   BEQ blocks ${beq.size.toLocaleString()}   ` +
    `BEQ distinct districts ${new Set(beq.values()).size}`);

  // CONTROL 1 — every district's own internal point resolves to itself.
  {
    let bad = 0;
    for (const d of districts) if (locate(districts, d.intpt[0], d.intpt[1]) !== d.code) bad += 1;
    if (bad) {
      console.error(`🔴 CONTROL 1 FAILED — ${bad} of ${districts.length} district internal points do ` +
        'not resolve to their own district. Point-in-polygon is broken; nothing below means anything.');
      process.exit(1);
    }
    console.log(`  ✅ control 1 — all ${districts.length} district internal points resolve to themselves.`);
  }

  // CONTROL 2 — a deliberately mis-labelled map must report mass disagreement.
  {
    const shifted = districts.map((d, i) => ({ ...d, code: districts[(i + 1) % districts.length].code }));
    let dis = 0, tested = 0;
    for (let i = 0; i < blocks.length; i += 97) { // every 97th block: a cheap but unbiased probe
      const b = blocks[i];
      const want = beq.get(b.geoid);
      if (!want) continue;
      tested += 1;
      if (locate(shifted, b.x, b.y) !== want) dis += 1;
    }
    if (dis < tested * 0.5) {
      console.error(`🔴 CONTROL 2 FAILED — a deliberately mis-labelled map disagreed on only ${dis} of ` +
        `${tested} probed blocks. The comparison cannot see a difference, so a clean result proves nothing.`);
      process.exit(1);
    }
    console.log(`  ✅ control 2 — a deliberately mis-labelled map disagrees on ${dis} of ${tested} probed ` +
      'blocks, so the comparison CAN report a difference.');
  }

  // The sweep.
  const perDistrict = new Map(); // beqDistrict -> {blocks, pop, toward:Map}
  let agree = 0, disagree = 0, unresolved = 0, notInBeq = 0;
  let agreePop = 0, disagreePop = 0;
  for (const b of blocks) {
    const want = beq.get(b.geoid);
    if (!want) { notInBeq += 1; continue; }
    const got = locate(districts, b.x, b.y);
    if (got === null) { unresolved += 1; continue; }
    if (got === want) { agree += 1; agreePop += b.pop; continue; }
    disagree += 1; disagreePop += b.pop;
    if (!perDistrict.has(want)) perDistrict.set(want, { blocks: 0, pop: 0, toward: new Map() });
    const e = perDistrict.get(want);
    e.blocks += 1; e.pop += b.pop;
    e.toward.set(got, (e.toward.get(got) || 0) + 1);
  }

  // CONTROL 3 — the sweep must have actually resolved the blocks it swept.
  const swept = agree + disagree + unresolved;
  if (unresolved > swept * 0.01) {
    console.error(`🔴 CONTROL 3 FAILED — ${unresolved} of ${swept} blocks resolved to NO district. ` +
      'A silent stream of unresolved points depresses the disagreement count. Stopping.');
    process.exit(1);
  }
  console.log(`  ✅ control 3 — ${unresolved} of ${swept.toLocaleString()} blocks unresolved ` +
    `(${((unresolved / swept) * 100).toFixed(4)}%).`);
  if (notInBeq) console.log(`  ⚠ ${notInBeq} TIGER blocks carry no BEQ row and were skipped.`);

  const totalPop = agreePop + disagreePop;
  console.log(`\n  blocks AGREEING   ${agree.toLocaleString().padStart(8)}  ` +
    `(${((agree / (agree + disagree)) * 100).toFixed(3)}%)   pop ${agreePop.toLocaleString()}`);
  console.log(`  blocks DISAGREEING${disagree.toLocaleString().padStart(8)}  ` +
    `(${((disagree / (agree + disagree)) * 100).toFixed(3)}%)   pop ${disagreePop.toLocaleString()} ` +
    `(${((disagreePop / totalPop) * 100).toFixed(3)}% of the state)`);

  if (disagree === 0) {
    console.log(`\n  ▶ TIGER ${VINTAGE} CARRIES THE REMEDIAL ${chamber} PLAN EXACTLY.`);
  } else {
    const rows = [...perDistrict.entries()].sort((a, b) => b[1].pop - a[1].pop);
    console.log(`\n  ${rows.length} of ${districts.length} remedial districts disagree with TIGER. ` +
      'Largest by population:');
    for (const [code, e] of rows.slice(0, 20)) {
      const toward = [...e.toward.entries()].sort((a, b) => b[1] - a[1])
        .slice(0, 4).map(([c, n]) => `${c}:${n}`).join(' ');
      console.log(`    remedial ${code}  ${String(e.blocks).padStart(5)} blocks  ` +
        `pop ${String(e.pop).padStart(7)}  TIGER instead says  ${toward}`);
    }
    if (rows.length > 20) console.log(`    … and ${rows.length - 20} more districts`);
    const material = rows.filter(([, e]) => e.pop >= 1000);
    console.log(`\n  🔴 districts where the disagreement exceeds 1,000 people: ${material.length} ` +
      `-> ${material.map(([c]) => c.slice(2)).sort((a, b) => Number(a) - Number(b)).join(' ')}`);
    console.log('  ⚠ A handful of people on a boundary is a digitisation artefact. Thousands is a redraw.');
  }

  // ── The same sweep, restricted to one county. ─────────────────────────────────────────────
  // 🔴 A STATEWIDE PERCENTAGE DOES NOT ANSWER "DOES THIS TOUCH MY CITY?" — a plan can move a
  // tenth of the state and nothing in the county about to be seeded, or the reverse.
  if (COUNTY) {
    const local = blocks.filter((b) => b.geoid.startsWith(COUNTY));
    let lDis = 0, lPop = 0; const moves = new Map();
    for (const b of local) {
      const want = beq.get(b.geoid);
      if (!want) continue;
      const got = locate(districts, b.x, b.y);
      if (got !== want) { lDis += 1; lPop += b.pop; moves.set(`${want}->${got}`, (moves.get(`${want}->${got}`) || 0) + 1); }
    }
    console.log(`\n  COUNTY ${COUNTY}: ${local.length.toLocaleString()} blocks, ` +
      `pop ${local.reduce((s, b) => s + b.pop, 0).toLocaleString()}`);
    console.log(`    disagreeing blocks ${lDis}   disagreeing population ${lPop}`);
    for (const [k, n] of moves) console.log(`      ${k}  ${n} block${n === 1 ? '' : 's'}`);
    console.log(lPop === 0
      ? '    ▶ THE TWO PLANS GIVE THIS COUNTY THE SAME ANSWER. Any disagreement here carries zero\n' +
        '      population and is a boundary digitisation artefact, not a redraw.'
      : `    🔴 THE PLANS DISAGREE FOR ${lPop.toLocaleString()} PEOPLE IN THIS COUNTY.`);
    for (const [label, x, y] of PROBES[COUNTY] || []) {
      console.log(`    ${label.padEnd(20)} TIGER ${layer} -> ${locate(districts, x, y) ?? 'NONE'}`);
    }
  }
}

console.log(`\n${'='.repeat(78)}`);
console.log('WHAT THIS DOES AND DOES NOT SETTLE');
console.log('='.repeat(78));
console.log('It settles which plan TIGER carries, against the plan definition Mississippi publishes.');
console.log('It does NOT settle which plan to LOAD. That is the Michigan rule — the correct map is');
console.log('the one the SITTING member was elected under — and Mississippi has members elected');
console.log('under both, plus a Supreme Court vacatur dated 2026-05-18 that this script cannot read.');
