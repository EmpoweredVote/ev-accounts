#!/usr/bin/env node
/**
 * verify-mi-tiger-vintage.mjs — Knight program, wave MI-1.
 *
 * Proves which redistricting plan each TIGER FIPS 26 legislative layer carries, against an
 * authority that is not the Census Bureau, and proves it SEPARATELY for each chamber.
 *
 * 🔴 WHY A COUNT CANNOT DO THIS. Michigan has had 110 House and 38 Senate seats since 1964.
 * Every plan ever drawn — the 2021 MICRC plans and both 2024 remedial plans — has exactly the
 * shape TIGER has. A count, a "no ZZZ pseudo-district" check and a contiguous-range check pass
 * on all four maps. Detroit is the reason it matters: in Agee v. Benson (W.D. Mich.,
 * 2023-12-21) a three-judge panel held that the MICRC drew 13 Detroit-area districts
 * predominantly on the basis of race and enjoined them.
 *
 * 🔴 AND THE TWO CHAMBERS MOVED ON DIFFERENT DATES, WHICH IS THE WHOLE TRAP.
 *   - House: remedial plan "Motown Sound FC E1", approved by the panel 2024-03-27, used from
 *     the 2024 election onward. The sitting House was elected under it.
 *   - Senate: remedial plan "Crane A1", adopted by the MICRC 2024-06-26 and approved by the
 *     panel 2024-07-26 FOR THE 2026 ELECTIONS. Michigan senators serve four-year terms and
 *     were last elected in November 2022, so the sitting Senate was elected under — and
 *     represents — the ORIGINAL 2021 "Linden" plan, and will until the term ends 2026-12-31.
 * ▶ So the correct map is NOT "the newest one" for both chambers. It is the map the sitting
 *   member was elected under, and that is a different plan per chamber.
 *
 * 🔴 LSY IS A LABEL, NOT A VINTAGE. TIGER 2024 and 2025 both stamp the Senate layer LSY=2024,
 * and both carry the pre-remedial Linden map: measured here, no TIGER vintage through 2025
 * carries Crane A1 at all. Reading LSY would have asserted the opposite.
 *
 * THE AUTHORITY: the State of Michigan's own ArcGIS organisation (dxRQUfTDNtfqZ301), which
 * the MICRC's own mapping-data page names as the publisher of the 2024 maps — that page links
 * out to searches for "crane a1" and "motown sound" rather than hosting them itself. Four
 * layers, the two adopted 2021 plans and the two 2024 remedial plans:
 *     MI_State_House_Districts_2021/FeatureServer/25   (Hickory,  2021 House)
 *     MI_State_Senate_Districts_2021/FeatureServer/24  (Linden,   2021 Senate)
 *     Remedial_State_House_2021/FeatureServer/0        (Motown Sound FC E1)
 *     Remedial_State_Senate_2021/FeatureServer/0       (Crane A1)
 * ⚠ A GLOBAL SEARCH FOR THESE PLAN NAMES IS A JURISDICTION-COLLISION TRAP: ArcGIS Hub's
 * unscoped search for "motown sound" returns a Detroit history story map, and "crane a1"
 * returns sandhill crane hunting zones in Texas, North Dakota and Montana. Scope to the org.
 * ⚠ AND `Layout` IS NOT THE PLAN NAME — it reads "Landscape". It is a print-layout field.
 *
 * THE TEST, run for every (TIGER vintage x authority plan) pair, on both:
 *   (a) topology — each TIGER polygon's own published internal point (INTPTLAT/INTPTLON) is
 *       located in the authority plan and the district number must match;
 *   (b) territory — all 3,017 Michigan census tract internal points (2020 gazetteer) are
 *       located in BOTH the TIGER layer and the authority plan, and the district must match.
 * 🔴 (a) ALONE IS NOT ENOUGH AND THIS SCRIPT WOULD LIE WITHOUT (b). Across TIGER 2023 -> 2024
 * the House remedial plan changed 18 of 110 districts, by up to 35.6% of area — and moved only
 * 7 of 110 internal points. An internal point sits in a district's core, which a remedial
 * redraw is least likely to touch. A Senate check that found "0 disagreements" on internal
 * points alone would be a detector that cannot fail. 3,017 tract points is ~27 per House
 * district and ~79 per Senate district, so a redraw cannot hide between them.
 *
 * 🔴 AND (b) WAS A PER-DISTRICT AREA COMPARISON FIRST, WHICH DID NOT SEPARATE — IT MEASURED
 * THE GREAT LAKES. TIGER's legislative polygons carry Great Lakes water; the State of
 * Michigan's layers are drawn to a different shoreline. So the shoreline districts differed by
 * 931% (House 88) and 450% (Senate 31) between two digitisations OF THE SAME PLAN, swamping
 * the 1.2%-to-35% signal a real redraw produces. The claim and the control both "failed" by
 * hundreds of percent on the same districts, which is the tell: a metric that does not
 * separate is a ranking, not a gate. Tract internal points are on land and have no such term.
 *
 * THE CONTROL is built in and is not a stale vintage: it is the OTHER REAL PLAN for the same
 * chamber. The pair must split — the claimed plan agrees and the competing plan does not — or
 * this script exits non-zero. Both directions are exercised, because the House's competitor is
 * older and the Senate's competitor is newer.
 *
 * Usage:  node scripts/verify-mi-tiger-vintage.mjs [--fetch] [--self-test]
 *                                                 [--tiger-dir <dir>] [--authority-dir <dir>]
 * Exit:   0 iff every chamber's claimed plan agrees completely AND its control disagreed.
 *
 * The 67 MB of inputs are NOT committed — `--fetch` downloads them (4 TIGER zips, 4 authority
 * layers, 1 gazetteer) so this runs from a clean checkout. ⚠ The authority hosts answer a
 * plain request; it is michigan.gov itself that 403s a bare request, and this script never
 * needs michigan.gov — the MICRC page is where the service URLs were READ, not fetched from.
 */
import https from 'https';
import fs from 'fs';
import os from 'os';
import path from 'path';
import AdmZip from 'adm-zip';
import * as shapefile from 'shapefile';

const argv = process.argv.slice(2);
const argOf = (f, d) => {
  const i = argv.indexOf(f);
  return i >= 0 ? argv[i + 1] : d;
};
const TIGER_DIR = argOf('--tiger-dir', 'data/seed-mi-2026/_tiger');
const AUTH_DIR = argOf('--authority-dir', 'data/seed-mi-2026/_authority');
/**
 * --self-test swaps each chamber's claim and control, so the script asserts the WRONG plan.
 * A verifier nobody has watched fail is not evidence. Every chamber must report failure and
 * the process must exit 1; run it before trusting a green run.
 */
const SELF_TEST = argv.includes('--self-test');
const FETCH = argv.includes('--fetch');

const ARCGIS = 'https://services3.arcgis.com/dxRQUfTDNtfqZ301/arcgis/rest/services';
const AUTHORITY_SOURCES = {
  // The State of Michigan's own org. The MICRC's mapping-data page names this as the publisher
  // of the 2024 maps; it links out to searches for "crane a1" and "motown sound" rather than
  // hosting them. Service + layer id, because the 2021 pair live at layer 25 and 24 of their
  // services and only the remedial pair are at layer 0.
  house_2021_hickory: `${ARCGIS}/MI_State_House_Districts_2021/FeatureServer/25`,
  senate_2021_linden: `${ARCGIS}/MI_State_Senate_Districts_2021/FeatureServer/24`,
  house_2024_remedial: `${ARCGIS}/Remedial_State_House_2021/FeatureServer/0`,
  senate_2024_remedial: `${ARCGIS}/Remedial_State_Senate_2021/FeatureServer/0`,
};
const GAZ_URL = 'https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_tracts_national.zip';
const tigerUrl = (v, l) => `https://www2.census.gov/geo/tiger/TIGER${v}/${l.toUpperCase()}/tl_${v}_26_${l}.zip`;

const get = (url, dest) =>
  new Promise((resolve, reject) => {
    const req = https.get(url, { headers: { 'User-Agent': 'ev-accounts knight-mi1 vintage verifier' } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        res.resume();
        return get(res.headers.location, dest).then(resolve, reject);
      }
      if (res.statusCode !== 200) {
        res.resume();
        return reject(new Error(`${url} -> HTTP ${res.statusCode}`));
      }
      const out = fs.createWriteStream(dest);
      res.pipe(out);
      out.on('finish', () => out.close(() => resolve()));
      out.on('error', reject);
    });
    req.on('error', reject);
  });

async function fetchInputs() {
  fs.mkdirSync(TIGER_DIR, { recursive: true });
  fs.mkdirSync(AUTH_DIR, { recursive: true });
  for (const v of ['2022', '2023', '2024', '2025'])
    for (const l of ['sldu', 'sldl']) {
      const dest = path.join(TIGER_DIR, `tl_${v}_26_${l}.zip`);
      if (fs.existsSync(dest)) continue;
      console.log(`  fetching TIGER ${v} ${l}`);
      await get(tigerUrl(v, l), dest);
    }
  for (const [name, svc] of Object.entries(AUTHORITY_SOURCES)) {
    const dest = path.join(AUTH_DIR, `${name}.geojson`);
    if (fs.existsSync(dest)) continue;
    console.log(`  fetching authority ${name}`);
    await get(`${svc}/query?where=1%3D1&outFields=*&outSR=4326&f=geojson`, dest);
    // 🔴 A 200 THAT IS TRUNCATED IS THE FAILURE MODE HERE — ArcGIS pages silently.
    const j = JSON.parse(fs.readFileSync(dest, 'utf8'));
    if (j.exceededTransferLimit === true || !(j.features || []).length) {
      fs.rmSync(dest);
      throw new Error(`${name}: server paged or returned nothing — refusing to keep a truncated authority layer`);
    }
  }
  const gaz = path.join(AUTH_DIR, TRACT_FILE);
  if (!fs.existsSync(gaz)) {
    console.log('  fetching 2020 tract gazetteer');
    const zip = path.join(AUTH_DIR, '_gaz.zip');
    await get(GAZ_URL, zip);
    new AdmZip(zip).extractAllTo(AUTH_DIR, true);
    fs.rmSync(zip);
  }
  console.log('');
}

// 2020 census tract internal points for FIPS 26, from the national gazetteer. Land-based,
// so unlike polygon area they carry no Great Lakes term. See the header for why area failed.
const TRACT_FILE = '2020_Gaz_tracts_national.txt';

// Seats whose TIGER internal point falls outside the State of Michigan layers ENTIRELY, with
// the reason. This is declared, not tolerated: the run fails if the off-map set is anything
// other than exactly this, so a new one cannot slip through as "one of the known ones".
const KNOWN_OFFMAP = {
  sldl: {
    109:
      'internal point 46.720711,-87.411743 is in Lake Superior about 20 km north of Marquette. ' +
      'TIGER legislative polygons carry Great Lakes water; the State of Michigan layers are ' +
      'clipped to the shoreline, so the point is in no state polygon. Same cause as the area ' +
      'metric this script had to abandon. HD-109 is scored by its 27 tract points instead.',
  },
  sldu: {},
};

const CHAMBERS = [
  {
    label: 'House',
    layer: 'sldl',
    codeField: 'SLDLST',
    expect: 110,
    claim: { file: 'house_2024_remedial', name: 'Motown Sound FC E1 (remedial, 2024-03-27)' },
    control: { file: 'house_2021_hickory', name: 'Hickory (2021 MICRC, superseded 2024)' },
    why: 'the sitting House was elected in November 2024 under the remedial plan',
  },
  {
    label: 'Senate',
    layer: 'sldu',
    codeField: 'SLDUST',
    expect: 38,
    claim: { file: 'senate_2021_linden', name: 'Linden (2021 MICRC, in force for the sitting Senate)' },
    control: { file: 'senate_2024_remedial', name: 'Crane A1 (remedial, first used November 2026)' },
    why: 'senators serve four-year terms and were last elected in November 2022 under Linden',
  },
];

// ── geometry helpers ────────────────────────────────────────────────────────
function pointInRing(x, y, ring) {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i];
    const [xj, yj] = ring[j];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}
const pointInPolygon = (x, y, poly) => {
  if (!pointInRing(x, y, poly[0])) return false;
  for (let k = 1; k < poly.length; k++) if (pointInRing(x, y, poly[k])) return false;
  return true;
};
const polysOf = (g) => (!g ? [] : g.type === 'Polygon' ? [g.coordinates] : g.type === 'MultiPolygon' ? g.coordinates : []);
const pointInGeom = (x, y, g) => polysOf(g).some((p) => pointInPolygon(x, y, p));
function bboxOf(g) {
  let [x0, y0, x1, y1] = [Infinity, Infinity, -Infinity, -Infinity];
  for (const poly of polysOf(g))
    for (const [x, y] of poly[0]) {
      if (x < x0) x0 = x;
      if (y < y0) y0 = y;
      if (x > x1) x1 = x;
      if (y > y1) y1 = y;
    }
  return [x0, y0, x1, y1];
}
const num = (v) => {
  const n = parseInt(String(v), 10);
  return Number.isFinite(n) ? n : null;
};

// ── loaders ─────────────────────────────────────────────────────────────────
async function loadTiger(vintage, layer, codeField) {
  const zip = path.join(TIGER_DIR, `tl_${vintage}_26_${layer}.zip`);
  if (!fs.existsSync(zip)) throw new Error(`missing TIGER file ${zip}`);
  const work = fs.mkdtempSync(path.join(os.tmpdir(), `mi-v-${vintage}-${layer}-`));
  new AdmZip(zip).extractAllTo(work, true);
  const shp = fs.readdirSync(work).find((f) => f.toLowerCase().endsWith('.shp'));
  const src = await shapefile.open(path.join(work, shp), path.join(work, shp.replace(/\.shp$/i, '.dbf')));
  const out = [];
  for (let r = await src.read(); !r.done; r = await src.read()) {
    out.push({
      district: num(r.value.properties[codeField]),
      lon: Number(r.value.properties.INTPTLON),
      lat: Number(r.value.properties.INTPTLAT),
      lsy: String(r.value.properties.LSY ?? ''),
      geometry: r.value.geometry,
      bbox: bboxOf(r.value.geometry),
    });
  }
  fs.rmSync(work, { recursive: true, force: true });
  return out;
}

/** Michigan tract internal points — the land-based sample that replaced the area test. */
function loadTractPoints() {
  const p = path.join(AUTH_DIR, TRACT_FILE);
  if (!fs.existsSync(p)) throw new Error(`missing tract gazetteer ${p}`);
  const pts = [];
  const lines = fs.readFileSync(p, 'utf8').split(/\r?\n/);
  for (let i = 1; i < lines.length; i++) {
    const c = lines[i].split('\t');
    if (c.length < 8 || !c[1] || !c[1].startsWith('26')) continue;
    pts.push({ geoid: c[1], lat: Number(c[6]), lon: Number(c[7].trim()) });
  }
  return pts;
}

/** Locate a point in a set of {district, geometry, bbox}; null when it falls outside all. */
const locate = (lon, lat, set) => {
  for (const f of set) {
    if (lon < f.bbox[0] || lon > f.bbox[2] || lat < f.bbox[1] || lat > f.bbox[3]) continue;
    if (pointInGeom(lon, lat, f.geometry)) return f.district;
  }
  return null;
};

function loadAuthority(file) {
  const p = path.join(AUTH_DIR, `${file}.geojson`);
  if (!fs.existsSync(p)) throw new Error(`missing authority file ${p}`);
  const j = JSON.parse(fs.readFileSync(p, 'utf8'));
  if (j.exceededTransferLimit === true) throw new Error(`${file}: exceededTransferLimit — the download is TRUNCATED`);
  return (j.features || []).map((f) => {
    const props = f.properties || {};
    const nameKey = 'Name' in props ? 'Name' : 'NAME';
    return { district: num(props[nameKey]), geometry: f.geometry, bbox: bboxOf(f.geometry) };
  });
}

function compare(tiger, authority, tracts) {
  // (a) each TIGER polygon's own internal point, located in the authority plan
  let seatAgree = 0;
  let seatDiffer = 0;
  const seatOffMap = [];
  for (const t of tiger) {
    const d = locate(t.lon, t.lat, authority);
    if (d === null) seatOffMap.push(t.district);
    else if (d === t.district) seatAgree++;
    else seatDiffer++;
  }
  const seatMissing = seatOffMap.length;

  // (b) every Michigan tract internal point, located in BOTH layers
  let tractAgree = 0;
  const tractDiffer = new Map(); // "tigerDistrict->authorityDistrict" -> count
  let tractSkipped = 0;
  for (const p of tracts) {
    const a = locate(p.lon, p.lat, tiger);
    const b = locate(p.lon, p.lat, authority);
    if (a === null || b === null) {
      tractSkipped++;
      continue;
    }
    if (a === b) tractAgree++;
    else {
      const k = `${String(a).padStart(3, '0')}->${String(b).padStart(3, '0')}`;
      tractDiffer.set(k, (tractDiffer.get(k) ?? 0) + 1);
    }
  }
  const tractDifferN = [...tractDiffer.values()].reduce((s, n) => s + n, 0);
  return {
    seatAgree,
    seatDiffer,
    seatMissing,
    seatOffMap,
    n: tiger.length,
    tractAgree,
    tractDifferN,
    tractSkipped,
    tractDiffer,
    tractN: tractAgree + tractDifferN,
  };
}

// ── run ─────────────────────────────────────────────────────────────────────
const VINTAGES = ['2022', '2023', '2024', '2025'];
const LOAD_VINTAGE = '2025'; // the vintage this wave actually loads
let failures = 0;

console.log('Knight MI-1 — TIGER vintage proof for Michigan legislative districts');
console.log(`TIGER dir: ${TIGER_DIR}   authority dir: ${AUTH_DIR}`);
if (FETCH) await fetchInputs();
const TRACTS = loadTractPoints();
console.log(`sample: ${TRACTS.length} Michigan census tract internal points (2020 gazetteer)\n`);
if (TRACTS.length < 3000) {
  console.log(`🔴 only ${TRACTS.length} tract points loaded — the sample is broken, refusing to judge.`);
  process.exit(1);
}

if (SELF_TEST) {
  console.log('🧪 --self-test: claim and control are SWAPPED. Every chamber must FAIL and the exit code must be 1.\n');
  for (const ch of CHAMBERS) {
    const t = ch.claim;
    ch.claim = ch.control;
    ch.control = t;
    // The off-map declaration belongs to the real pairing; swapped, HD-109's point lands in
    // Hickory's Lake-Superior-clipped layer no differently, so keep it declared.
  }
}

for (const ch of CHAMBERS) {
  console.log(`${'='.repeat(78)}\n${ch.label} (${ch.layer}) — claim: ${ch.claim.name}`);
  console.log(`  because ${ch.why}`);
  console.log(`  control: ${ch.control.name}\n`);

  const claim = loadAuthority(ch.claim.file);
  const control = loadAuthority(ch.control.file);
  for (const [nm, set] of [
    [ch.claim.file, claim],
    [ch.control.file, control],
  ]) {
    if (set.length !== ch.expect) {
      console.log(`  🔴 authority ${nm} holds ${set.length} districts, expected ${ch.expect}`);
      failures++;
    }
  }

  const rows = [];
  for (const v of VINTAGES) {
    const tiger = await loadTiger(v, ch.layer, ch.codeField);
    if (tiger.length !== ch.expect) {
      console.log(`  🔴 TIGER ${v} holds ${tiger.length} polygons, expected ${ch.expect}`);
      failures++;
    }
    rows.push({
      v,
      lsy: [...new Set(tiger.map((t) => t.lsy))].join('/'),
      claim: compare(tiger, claim, TRACTS),
      control: compare(tiger, control, TRACTS),
    });
  }

  const fmt = (c) =>
    `seats ${String(c.seatAgree).padStart(3)}/${c.n}${c.seatMissing ? `+${c.seatMissing}?` : '  '}` +
    ` · tracts ${String(c.tractAgree).padStart(4)}/${c.tractN} (${((c.tractAgree / c.tractN) * 100).toFixed(2).padStart(6)}%)`;
  console.log(`  TIGER  LSY    vs CLAIM                                 vs CONTROL`);
  for (const r of rows) console.log(`   ${r.v}  ${r.lsy.padEnd(5)}  ${fmt(r.claim).padEnd(40)} ${fmt(r.control)}`);

  const loaded = rows.find((r) => r.v === LOAD_VINTAGE);
  const declared = Object.keys(KNOWN_OFFMAP[ch.layer]).map(Number).sort((a, b) => a - b);
  const observed = [...loaded.claim.seatOffMap].sort((a, b) => a - b);
  const offMapAsDeclared = JSON.stringify(declared) === JSON.stringify(observed);
  const okClaim =
    loaded.claim.seatAgree === ch.expect - declared.length && loaded.claim.seatDiffer === 0 && loaded.claim.tractDifferN === 0 && offMapAsDeclared;

  console.log('');
  if (!offMapAsDeclared) {
    console.log(`  🔴 OFF-MAP SEATS ARE NOT THE DECLARED SET — declared [${declared}], observed [${observed}].`);
    console.log(`     Every seat whose internal point lands in no state polygon must be named and explained in KNOWN_OFFMAP.`);
  } else if (declared.length) {
    for (const d of declared) console.log(`  ⚠ ${ch.label} ${d} internal point is off-map, as declared: ${KNOWN_OFFMAP[ch.layer][d]}`);
  }
  const controlFailed = loaded.control.seatDiffer > 0 || loaded.control.tractDifferN > 0;

  if (okClaim) {
    console.log(
      `  ✅ TIGER ${LOAD_VINTAGE} ${ch.layer} IS ${ch.claim.name}\n` +
        `     ${loaded.claim.seatAgree}/${ch.expect - declared.length} locatable seats and ` +
        `${loaded.claim.tractAgree}/${loaded.claim.tractN} tracts agree, 0 differ` +
        `${loaded.claim.tractSkipped ? ` (${loaded.claim.tractSkipped} tract points outside one of the two layers, not counted)` : ''}`
    );
  } else {
    console.log(`  🔴 TIGER ${LOAD_VINTAGE} ${ch.layer} DOES NOT MATCH ${ch.claim.name}`);
    console.log(`     seats differ ${loaded.claim.seatDiffer}, off-map ${loaded.claim.seatMissing}, tracts differ ${loaded.claim.tractDifferN}`);
    const top = [...loaded.claim.tractDiffer.entries()].sort((a, b) => b[1] - a[1]).slice(0, 12);
    if (top.length) console.log(`     worst moves (tiger->authority): ${top.map(([k, n]) => `${k}x${n}`).join(' ')}`);
    failures++;
  }
  if (controlFailed) {
    const top = [...loaded.control.tractDiffer.entries()].sort((a, b) => b[1] - a[1]).slice(0, 12);
    console.log(
      `  ✅ control failed as required — ${ch.control.name} disagrees on ${loaded.control.seatDiffer} seats ` +
        `and ${loaded.control.tractDifferN} of ${loaded.control.tractN} tracts\n` +
        `     worst moves (tiger->control): ${top.map(([k, n]) => `${k}x${n}`).join(' ')}`
    );
  } else {
    console.log(`  🔴 CONTROL DID NOT FAIL — ${ch.control.name} is indistinguishable from the claim, so this test proves nothing.`);
    failures++;
  }
  console.log('');
}

console.log('='.repeat(78));
if (SELF_TEST) {
  if (failures >= CHAMBERS.length) {
    console.log(`🧪 SELF-TEST PASSED — ${failures} failure(s) with the plans swapped, from ${CHAMBERS.length} chamber(s). The gate can fail.`);
    process.exit(1);
  }
  console.log(`🔴 SELF-TEST FAILED — only ${failures} failure(s) with the plans swapped. The gate cannot tell the maps apart; it proves nothing.`);
  process.exit(2);
}
if (failures === 0) {
  console.log('✅ Every chamber: claimed plan agrees completely and its control failed as required.');
  process.exit(0);
}
console.log(`🔴 ${failures} check(s) failed.`);
process.exit(1);
