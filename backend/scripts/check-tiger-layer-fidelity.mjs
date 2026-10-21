#!/usr/bin/env node
/**
 * check-tiger-layer-fidelity.mjs
 *
 * 73,021 of the 74,615 polygons that route a voter (97.9%) come from Census TIGER. Unlike the
 * hand-picked local layers that check-council-district-vintage.mjs gates, TIGER needs no judgement
 * about who the authority is: it IS the authority, it is versioned, and every vintage stays
 * queryable. So this checks it WHOLESALE rather than sampling — every GEOID, every area.
 *
 * WHAT IT ASKS: inside each state we have ADOPTED, does the authority list a polygon we do not
 * hold? That is the question with signal. "Do we hold everything TIGER has nationally" has none:
 * coverage is deliberately state-by-state (for incorporated places, 29 states in full and 22 not at
 * all), so a national count reports tens of thousands of non-defects.
 *
 * 🔴 THE FIRST VERSION OF THIS CHECK WAS WRONG THREE TIMES, and each correction lives in the code
 * below. It reported 6,335 missing places and 23,338 missing county subdivisions as "addresses that
 * route nowhere". The real number across both layers is eight. Before trusting any count this
 * prints, know what it already nets out:
 *
 *   1. ADOPTED-STATE SCOPING. A state where we hold under half the polygons was never loaded on
 *      purpose. 6,335 -> 11 for places.
 *   2. TIGER DUAL-LISTING. A municipality is published in BOTH the place layer and the county
 *      subdivision layer — Milwaukee is 5553000 as a place and 5513153000 as a subdivision. We load
 *      it once, as a place. 672 of 1,088 subdivision differences were exactly this.
 *   3. PLACEHOLDERS. "not defined" polygons (water a district layer does not cover), and
 *      non-functioning or statistical units. 413 more.
 *
 * Pennsylvania adds a fourth wrinkle, handled by rule 2's net: a home-rule municipality carries one
 * GEOID as a municipality and another as a township (Penn Hills 4259040 / 4200359032), and we hold
 * the township.
 *
 * WHAT IT FINDS when all that is netted out: newly incorporated municipalities. A snapshot cannot
 * know about a town that incorporated after it was taken, so this is caught by re-running, not by
 * fixing an import. As of 2026-10-20 that was San Tan Valley AZ (~100k residents), Mountain House
 * CA, Mulberry GA, Keystone CO, Starbase TX, Bloomington TX, Baldwin MN and Greenleaf WI.
 *
 * Usage:
 *   node scripts/check-tiger-layer-fidelity.mjs
 *   node scripts/check-tiger-layer-fidelity.mjs --mtfcc G4110
 *   node scripts/check-tiger-layer-fidelity.mjs --json
 */
import 'dotenv/config';
import pg from 'pg';

const CLAIMED = 'tigerWMS_ACS2024'; // the vintage `census_tiger_2024` means
const BASE = 'https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb';

const LAYERS = [
  // `governed: true` = this layer's FUNCSTAT distinguishes units with a government from units
  // without, so the placeholder filter may read it. On a DISTRICT layer it must NOT: TIGER marks
  // congressional and legislative districts FUNCSTAT 'N', because a district is not a legal entity
  // in the Census sense, and filtering on it drops every district and leaves the check blind.
  { mtfcc: 'G6350', layer: 2, label: 'ZIP Code Tabulation Areas' },
  { mtfcc: 'G4110', layer: 28, label: 'Incorporated Places', governed: true },
  { mtfcc: 'G4040', layer: 22, label: 'County Subdivisions', netAgainst: 'G4110', governed: true },
  { mtfcc: 'G4210', layer: 30, label: 'Census Designated Places', governed: true },
  { mtfcc: 'G5220', layer: 58, label: 'State Legislative - Lower' },
  { mtfcc: 'G4020', layer: 82, label: 'Counties' },
  { mtfcc: 'G5210', layer: 56, label: 'State Legislative - Upper' },
  { mtfcc: 'G5420', layer: 14, label: 'Unified School Districts' },
  { mtfcc: 'G5400', layer: 18, label: 'Elementary School Districts' },
  { mtfcc: 'G5200', layer: 54, label: 'Congressional Districts' },
  { mtfcc: 'G5410', layer: 16, label: 'Secondary School Districts' },
  // G4000 (state outlines) is deliberately NOT here: those rows are `census_cb_2010_20m`, a
  // generalised 1:20m cartographic file from 2010, not a TIGER vintage. Comparing it to
  // full-resolution 2024 reports 17 polygons "wrong" by up to 41%, all of them generalisation.
  // Give it its own check against its own file if it ever needs one.
];

const ADOPTED_THRESHOLD = 0.5;
const AREA_TOLERANCE = 0.05;

const argv = process.argv.slice(2);
const asJson = argv.includes('--json');
const onlyMtfcc = argv.includes('--mtfcc') ? argv[argv.indexOf('--mtfcc') + 1] : null;

if (!process.env.DATABASE_URL) {
  console.log('check-tiger-layer-fidelity: DATABASE_URL is not set — skipping.');
  process.exit(0);
}

class UpstreamUnavailable extends Error {}

async function fetchLayer(layerId, governed) {
  const out = new Map();
  for (let offset = 0; ; offset += 1000) {
    const url = `${BASE}/${CLAIMED}/MapServer/${layerId}/query?where=1%3D1` +
      `&outFields=GEOID,NAME,FUNCSTAT,AREALAND,AREAWATER&returnGeometry=false` +
      `&resultOffset=${offset}&resultRecordCount=1000&f=json`;
    let json;
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(120_000) });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      json = await res.json();
    } catch (err) { throw new UpstreamUnavailable(`layer ${layerId}: ${err.message}`); }
    if (json.error) throw new UpstreamUnavailable(`layer ${layerId}: ${json.error.message}`);
    const feats = json.features ?? [];
    for (const f of feats) {
      const a = f.attributes;
      if (!a?.GEOID) continue;
      const land = Number(a.AREALAND) || 0;
      // Correction 3: placeholders. Zero land = water nobody lives on. "not defined" = TIGER's
      // filler for area a district layer does not cover. FUNCSTAT other than A(ctive)/F = a unit
      // with no government. Keyed on the properties that make them irrelevant, never on the 'ZZ'
      // in the id — a string shape differs per layer and would swallow a real loss.
      if (land === 0) continue;
      if (/not defined/i.test(String(a.NAME ?? ''))) continue;
      const fs = String(a.FUNCSTAT ?? '');
      if (governed && fs && fs !== 'A' && fs !== 'F' && fs !== 'S') continue;
      out.set(String(a.GEOID), {
        area: land + (Number(a.AREAWATER) || 0),
        name: String(a.NAME ?? ''),
        statistical: fs === 'S',
      });
    }
    if (feats.length < 1000) break;
    if (offset > 200_000) break;
  }
  return out;
}

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

/** Keyset-paged, NOT OFFSET — a growing OFFSET re-sorts the layer each page and blows the 30s
 *  statement timeout around the 30,000th ZCTA. */
async function ourRows(mtfcc, withArea) {
  const m = new Map();
  let after = '';
  for (;;) {
    const { rows } = await pool.query(
      `SELECT geo_id${withArea ? ', public.ST_Area(geometry::public.geography) AS area' : ''}
         FROM essentials.geofence_boundaries
        WHERE mtfcc = $1 AND geo_id > $2 ORDER BY geo_id LIMIT 2000`,
      [mtfcc, after]
    );
    for (const r of rows) m.set(String(r.geo_id), withArea ? Number(r.area) : 0);
    if (rows.length < 2000) break;
    after = rows[rows.length - 1].geo_id;
  }
  return m;
}

let failed = false;
const results = [];
try {
  const layers = onlyMtfcc ? LAYERS.filter((l) => l.mtfcc === onlyMtfcc) : LAYERS;
  if (!layers.length) { console.error(`No TIGER layer registered for ${onlyMtfcc}`); process.exit(1); }

  for (const spec of layers) {
    const entry = { mtfcc: spec.mtfcc, label: spec.label };
    try {
      const ours = await ourRows(spec.mtfcc, true);
      // Correction 2: a municipality published in two layers is held once. Net the other layer in.
      const netSet = spec.netAgainst ? await ourRows(spec.netAgainst, false) : null;
      const theirs = await fetchLayer(spec.layer, spec.governed);
      entry.ours = ours.size;
      entry.authority = theirs.size;

      // A BLIND CHECK MUST NOT PASS. If the authority comes back empty or implausibly small, the
      // fault is in this script or in the service, and every comparison below is meaningless — but
      // it would compute cleanly and print OK, which is worse than failing. This caught a real
      // bug: a FUNCSTAT filter written for the place layer dropped all 441 congressional districts
      // and the layer reported "OK, 0 gaps".
      if (theirs.size === 0 || theirs.size < ours.size * 0.5) {
        entry.ok = false;
        entry.note = `authority returned ${theirs.size} features against our ${ours.size} — ` +
                     `the check is BLIND here, not clean; fix it before reading anything else`;
        failed = true;
        results.push(entry);
        if (!asJson) print(entry);
        continue;
      }

      // Correction 1: score per state, and only inside states we adopted.
      const byState = new Map();
      for (const [geoid] of theirs) {
        const st = geoid.slice(0, 2);
        const e = byState.get(st) ?? { have: 0, total: 0, missing: [] };
        e.total++;
        if (ours.has(geoid)) e.have++; else e.missing.push(geoid);
        byState.set(st, e);
      }
      const adopted = [...byState.entries()].filter(([, e]) => e.have / e.total >= ADOPTED_THRESHOLD);
      entry.adoptedStates = adopted.length;

      const real = [];
      let netted = 0;
      for (const [st, e] of adopted) {
        for (const geoid of e.missing) {
          if (netSet && netSet.has(st + geoid.slice(5))) { netted++; continue; }
          const t = theirs.get(geoid);
          real.push({ geoid, name: t.name, statistical: t.statistical });
        }
      }
      entry.nettedAsDualListed = netted;
      // A CDP has no government, so a missing one cannot strand an officeholder. Reported apart.
      entry.gaps = real.filter((r) => !r.statistical);
      entry.statisticalGaps = real.filter((r) => r.statistical).length;

      const offenders = [];
      for (const [geoid, ourArea] of ours) {
        const t = theirs.get(geoid);
        if (!t?.area || !ourArea) continue;
        const d = Math.abs(ourArea - t.area) / t.area;
        if (d > AREA_TOLERANCE) {
          offenders.push({ geoid, name: t.name, delta: d, ourKm2: ourArea / 1e6, theirKm2: t.area / 1e6 });
        }
      }
      offenders.sort((a, b) => b.delta - a.delta);
      entry.areaOff = offenders.length;
      entry.worstArea = offenders.length ? `${(offenders[0].delta * 100).toFixed(2)}%` : '0%';
      entry.worstOffenders = offenders.slice(0, 5);
      entry.ok = entry.gaps.length === 0 && offenders.length === 0;
      if (!entry.ok) failed = true;
    } catch (err) {
      if (err instanceof UpstreamUnavailable) { entry.ok = true; entry.skipped = true; entry.note = `SKIPPED — ${err.message}`; }
      else { entry.ok = false; entry.note = `could not run: ${err.message}`; failed = true; }
    }
    results.push(entry);
    if (!asJson) print(entry);
  }
  if (asJson) console.log(JSON.stringify({ ok: !failed, vintage: CLAIMED, results }, null, 2));
} finally {
  await pool.end();
}

function print(r) {
  const tag = r.skipped ? 'SKIP' : r.ok ? 'OK  ' : 'FAIL';
  console.log(`${tag}  ${r.mtfcc.padEnd(6)} ${r.label.padEnd(28)}` +
    (r.ours !== undefined ? ` ours ${String(r.ours).padStart(6)} · authority ${String(r.authority).padStart(6)} · ${r.adoptedStates} adopted states` : ''));
  if (r.note) console.log(`        ! ${r.note}`);
  if (r.nettedAsDualListed) console.log(`        · ${r.nettedAsDualListed} netted as TIGER dual-listings already held in the sibling layer`);
  if (r.statisticalGaps) console.log(`        · ${r.statisticalGaps} statistical-only units absent (no government; not a routing defect)`);
  if (r.gaps?.length) {
    console.log(`        ! ${r.gaps.length} GOVERNED polygons the authority has and we do not:`);
    for (const g of r.gaps.slice(0, 10)) console.log(`            ${g.geoid}  ${g.name}`);
    if (r.gaps.length > 10) console.log(`            … and ${r.gaps.length - 10} more`);
  }
  if (r.areaOff) {
    console.log(`        ! ${r.areaOff} polygons differ in area by >5% (worst ${r.worstArea}):`);
    for (const o of r.worstOffenders) {
      console.log(`            ${o.geoid}  ${o.name}: ours ${o.ourKm2.toFixed(1)} km2, authority ${o.theirKm2.toFixed(1)} km2`);
    }
  }
}

// exitCode, not exit(): let the pool's handles close or Windows libuv asserts on teardown
process.exitCode = failed ? 1 : 0;
