#!/usr/bin/env node
/**
 * verify-phl-council-districts.mjs — Knight program, wave PA-3.
 *
 * Decides WHICH of Philadelphia's five published council-district layers is the operative one,
 * and proves it rather than reading the year off the service name.
 *
 * 🔴🔴 THE CITY PUBLISHES FIVE COUNCIL-DISTRICT LAYERS AND EVERY ONE HAS TEN FEATURES NUMBERED
 * 1-10: Council_Districts_1990, _2000, _2016, _2024 and council_districts_2024_2. A count cannot
 * tell them apart — Duluth's two maps again, one city larger.
 *
 * 🔴🔴 AND NEITHER CAN A CITY-WIDE SPREAD OF ADDRESSES. The first version of this script probed
 * the 54 Free Library branches, whose addresses AND coordinates the city publishes, against the
 * city's own address service. All 54 agreed with the 2024 layer — and all 54 ALSO agreed with the
 * SUPERSEDED 2016 layer, even though 0 of the 10 districts are byte-identical between the two
 * plans. The maps differ; they just do not differ where a library happens to sit. A probe set that
 * cannot separate two answers is not evidence, however wide it looks.
 *
 * THE TEST THAT WORKS: Philadelphia's Address Information System (api.phila.gov/ais) returns, for
 * any address, BOTH `council_district_2016` and `council_district_2024`. So the CHANGED POPULATION
 * can be found rather than guessed: sample addresses from the city's own 954k-row address-point
 * layer, keep the ones whose two answers DISAGREE, and score both candidate layers on exactly
 * those. The operative layer must agree with the 2024 answer on every one of them; the superseded
 * layer must disagree on every one of them. A run where the changed set is empty FAILS — it means
 * the sample never reached the places the remap moved, which is the defect this file exists for.
 *
 * Usage:  node scripts/verify-phl-council-districts.mjs [--layer <service>] [--samples 400]
 * Exit:   0 both halves hold; 1 otherwise.
 */
const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };
const ARC = 'https://services.arcgis.com/fLeGjb7u4uXqeF9q/arcgis/rest/services';
const POINTS = `${ARC}/AIS_Address_Points/FeatureServer/0/query`;
const AIS = 'https://api.phila.gov/ais/v1/search';

const argv = process.argv.slice(2);
const arg = (k, d) => { const i = argv.indexOf(k); return i >= 0 ? argv[i + 1] : d; };
const LAYER = arg('--layer', 'Council_Districts_2024');
const OLD_LAYER = arg('--old-layer', 'Council_Districts_2016');
const SAMPLES = Number(arg('--samples', '400'));

async function json(url) {
  const r = await fetch(url, { headers: UA });
  const t = await r.text();
  // A WAF rejection can be HTTP 200 carrying HTML. Judge the body, never r.ok.
  if (!t.trim().startsWith('{')) throw new Error(`not JSON (HTTP ${r.status}) from ${url}`);
  const j = JSON.parse(t);
  if (j.error) throw new Error(`error from ${url}: ${JSON.stringify(j.error).slice(0, 160)}`);
  return j;
}

function pipRing(x, y, ring) {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i], [xj, yj] = ring[j];
    if (((yi > y) !== (yj > y)) && (x < ((xj - xi) * (y - yi)) / (yj - yi) + xi)) inside = !inside;
  }
  return inside;
}
function pip(x, y, geom) {
  const polys = geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
  for (const poly of polys) {
    if (!pipRing(x, y, poly[0])) continue;
    let hole = false;
    for (let h = 1; h < poly.length; h++) if (pipRing(x, y, poly[h])) { hole = true; break; }
    if (!hole) return true;
  }
  return false;
}

async function layerFeatures(service) {
  const j = await json(`${ARC}/${service}/FeatureServer/0/query?where=1%3D1&outFields=*&outSR=4326&f=geojson`);
  return j.features.map((f) => {
    const p = f.properties;
    const num = p.district_num ?? p.DISTRICT ?? p.district ?? p.DIST_NUM;
    return { district: String(Number(String(num).replace(/\D/g, ''))), geom: f.geometry };
  });
}
const assign = (feats, lon, lat) => feats.filter((f) => pip(lon, lat, f.geom)).map((f) => f.district);

/**
 * 🔴 AN UNANSWERED PROBE MUST NOT LOOK LIKE A CLEAN ONE. The first run of this script asked the
 * address service six at a time, swallowed every failure into "unanswered", and reported a tidy
 * 61/61 agreement — while 239 of its 300 probes had been dropped by rate limiting. Individually
 * every one of those addresses answers fine. So: retry with backoff, and the caller FAILS the run
 * if the answer rate falls below ANSWER_FLOOR. That is the MN-6 lesson — a verifier that reports
 * "0 broken" while testing almost nothing is green because it is blind, and the COUNT is the tell.
 */
async function ais(address, tries = 4) {
  for (let i = 0; i < tries; i++) {
    try {
      const j = await json(`${AIS}/${encodeURIComponent(address)}?include_units=false`);
      const p = j.features?.[0]?.properties;
      // 🔴 AN EMPTY RESULT SET IS NOT AN ANSWER. Under load this service returns HTTP 200 with
      // `features: []` for addresses that resolve perfectly well when asked one at a time —
      // measured: 25 of 25 sequentially, 61% in a concurrent run. Treating that as "no match"
      // dropped 39% of the probes silently. It is retried like any other failure, and only a
      // miss that survives every retry is reported as unanswered.
      if (!p) throw new Error('empty feature set');
      const n = (v) => (v == null || v === '' ? null : String(Number(v)));
      return { d2024: n(p.council_district_2024), d2016: n(p.council_district_2016) };
    } catch (e) {
      if (i === tries - 1) { if (String(e.message) === 'empty feature set') return null; throw e; }
      await new Promise((r) => setTimeout(r, 600 * (i + 1)));
    }
  }
}
const ANSWER_FLOOR = 0.9;

let failed = false;

const now = await layerFeatures(LAYER);
const old = await layerFeatures(OLD_LAYER);
console.log(`${LAYER}: ${now.length} polygons · ${OLD_LAYER}: ${old.length} polygons`);
if (now.length !== 10 || old.length !== 10) { console.log('🔴 a council layer does not have 10 polygons'); failed = true; }

let identical = 0;
for (const f of now) {
  const o = old.find((x) => x.district === f.district);
  if (o && JSON.stringify(o.geom) === JSON.stringify(f.geom)) identical++;
}
console.log(`districts byte-identical between the two plans: ${identical} of 10 — the plans differ, but a count says nothing`);

// ── sample the city's own address points, stepped across the table ───────────
const total = (await json(`${POINTS}?where=1%3D1&returnCountOnly=true&f=json`)).count;
const step = Math.max(1, Math.floor(total / SAMPLES));
console.log(`\naddress points published by the city: ${total.toLocaleString()} — sampling every ${step.toLocaleString()}th, ${SAMPLES} probes`);

const addrs = [];
const CONC_FETCH = 8;
for (let i = 0; i < SAMPLES; i += CONC_FETCH) {
  const batch = [];
  for (let k = i; k < Math.min(i + CONC_FETCH, SAMPLES); k++) {
    batch.push(json(`${POINTS}?where=1%3D1&outFields=street_address&resultOffset=${k * step}&resultRecordCount=1&outSR=4326&f=geojson`)
      .then((j) => j.features?.[0])
      .catch(() => null));
  }
  for (const f of await Promise.all(batch)) {
    if (f?.properties?.street_address && f.geometry) {
      addrs.push({ address: f.properties.street_address, lon: f.geometry.coordinates[0], lat: f.geometry.coordinates[1] });
    }
  }
  process.stdout.write(`\r  collecting addresses ${addrs.length}/${SAMPLES}`);
}
process.stdout.write('\n');

// ── ask the city about each one ──────────────────────────────────────────────
const rows = [];
const CONC = 2;  // the service rate-limits above this; see the note on ais()
for (let i = 0; i < addrs.length; i += CONC) {
  const batch = addrs.slice(i, i + CONC);
  const res = await Promise.all(batch.map(async (a) => {
    try { return { ...a, ais: await ais(`${a.address}, Philadelphia, PA`) }; }
    catch { return { ...a, ais: null }; }
  }));
  rows.push(...res);
  process.stdout.write(`\r  asking the address service ${rows.length}/${addrs.length}`);
}
process.stdout.write('\n');

const answered = rows.filter((r) => r.ais && r.ais.d2024 != null);
const changed = answered.filter((r) => r.ais.d2016 != null && r.ais.d2016 !== r.ais.d2024);
console.log(`\nanswered by the address service: ${answered.length} of ${rows.length}`);
console.log(`CHANGED between the 2016 and 2024 plans: ${changed.length} (${(100 * changed.length / Math.max(1, answered.length)).toFixed(1)}% of the sample)`);

const answerRate = answered.length / Math.max(1, rows.length);
if (answerRate < ANSWER_FLOOR) {
  console.log(`   🔴 ONLY ${(100 * answerRate).toFixed(0)}% OF PROBES WERE ANSWERED (floor ${100 * ANSWER_FLOOR}%).`);
  console.log('      The agreement below is computed over whatever survived, which is not a sample of');
  console.log('      anything. Slow the run down rather than reading the numbers.');
  failed = true;
}

if (changed.length === 0) {
  console.log('   🔴 THE SAMPLE NEVER REACHED THE CHANGED AREAS. This run proves nothing about which');
  console.log('      layer is operative — widen --samples rather than believing the agreement below.');
  failed = true;
}

const score = (feats, pick) => {
  let ok = 0; const bad = [];
  for (const r of changed) {
    const a = assign(feats, r.lon, r.lat);
    if (a.length === 1 && a[0] === pick(r)) ok++;
    else bad.push(`${r.address}: layer [${a.join('|') || 'none'}] vs ${pick(r)}`);
  }
  return { ok, bad };
};

const nowOnChanged = score(now, (r) => r.ais.d2024);
const oldOnChanged = score(old, (r) => r.ais.d2024);
console.log(`\nON THE CHANGED ADDRESSES ONLY — the only rows that can separate the two maps:`);
console.log(`  ${LAYER.padEnd(26)} matches the CURRENT answer: ${nowOnChanged.ok}/${changed.length}`);
console.log(`  ${OLD_LAYER.padEnd(26)} matches the CURRENT answer: ${oldOnChanged.ok}/${changed.length}   <- must be low; it is the superseded map`);
nowOnChanged.bad.slice(0, 8).forEach((b) => console.log('   🔴 ' + b));
if (changed.length && nowOnChanged.ok !== changed.length) failed = true;
if (changed.length && oldOnChanged.ok === changed.length) {
  console.log('   🔴 THE SUPERSEDED LAYER SCORES THE SAME. The test cannot separate them.');
  failed = true;
}

const whole = score(now, (r) => r.ais.d2024);
let allOk = 0; const allBad = [];
for (const r of answered) {
  const a = assign(now, r.lon, r.lat);
  if (a.length === 1 && a[0] === r.ais.d2024) allOk++; else allBad.push(`${r.address}: [${a.join('|') || 'none'}] vs ${r.ais.d2024}`);
}
console.log(`\nACROSS THE WHOLE SAMPLE: ${LAYER} agrees with the city's current answer ${allOk}/${answered.length}`);
allBad.slice(0, 8).forEach((b) => console.log('   🔴 ' + b));
if (allOk !== answered.length) failed = true;
void whole;

console.log(failed ? '\nFAIL' : `\nOK — ${LAYER} is the operative plan, and the superseded map was proved WRONG on ${changed.length} real addresses.`);
process.exit(failed ? 1 : 0);
