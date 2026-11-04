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
 * BASELINED, AND BASELINED ON IDENTITIES RATHER THAN COUNTS. There is a real backlog here — eight
 * municipalities to load and 570 shapes to explain — and failing on it every day would only teach
 * people to ignore this check, the way a permanently-red check always does. So the known set is
 * recorded in data/tiger-layer-fidelity-baseline.json and the gate fires on anything NEW.
 *
 * 🔑 The baseline stores GEOIDs, not totals, and that is deliberate. Its sibling
 * check-address-reachability.mjs baselines counts per bucket, which cannot see a defect that
 * replaces another: load San Tan Valley on the same day a different town incorporates and the count
 * is unchanged while the facts are not. GEOIDs are stable identifiers and these sets are small, so
 * there is no reason to accept that blind spot here.
 *
 * A polygon leaving the baseline is reported too — that is somebody fixing something, and the
 * baseline should shrink to match. Never let it grow without saying why in the commit message.
 *
 * Usage:
 *   node scripts/check-tiger-layer-fidelity.mjs
 *   node scripts/check-tiger-layer-fidelity.mjs --mtfcc G4110
 *   node scripts/check-tiger-layer-fidelity.mjs --json
 *   node scripts/check-tiger-layer-fidelity.mjs --update-baseline
 *     ⚠ regenerates EVERY layer from whatever production says today, so it will absorb a real
 *     regression that landed this morning as though it were always known. Prefer hand-editing one
 *     layer's list. If you do run it, read the diff before committing it.
 */
import 'dotenv/config';
import pg from 'pg';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { readFileSync, writeFileSync } from 'node:fs';

const CLAIMED = 'tigerWMS_ACS2024'; // the vintage `census_tiger_2024` means
const BASE = 'https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const BASELINE_PATH = path.join(HERE, '..', 'data', 'tiger-layer-fidelity-baseline.json');

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
const updateBaseline = argv.includes('--update-baseline');
const onlyMtfcc = argv.includes('--mtfcc') ? argv[argv.indexOf('--mtfcc') + 1] : null;

/** Known-and-accepted defects, keyed mtfcc -> { missing: [geoid], areaOff: [geoid] }. */
function loadBaseline() {
  try {
    const raw = JSON.parse(readFileSync(BASELINE_PATH, 'utf8'));
    return raw.layers ?? {};
  } catch {
    // No baseline yet: treat everything as new. Better to be noisy on day one than to
    // silently accept whatever happens to be broken when the file first appears.
    return {};
  }
}
const baseline = loadBaseline();
const asSet = (xs) => new Set(xs ?? []);

if (!process.env.DATABASE_URL) {
  console.log('check-tiger-layer-fidelity: DATABASE_URL is not set — skipping.');
  process.exit(0);
}

class UpstreamUnavailable extends Error {}

async function fetchLayer(layerId, governed) {
  const out = new Map();
  for (let offset = 0; ; offset += 1000) {
    const url = `${BASE}/${CLAIMED}/MapServer/${layerId}/query?where=1%3D1` +
      `&outFields=GEOID,NAME,FUNCSTAT,AREALAND,AREAWATER,CENTLAT,CENTLON&returnGeometry=false` +
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
        // TIGER ships a signed-string centroid ("+38.0537", "-078.5570").
        lat: Number(a.CENTLAT),
        lon: Number(a.CENTLON),
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
async function ourRows(mtfcc, withGeometry) {
  const m = new Map();
  let after = '';
  for (;;) {
    const { rows } = await pool.query(
      `SELECT geo_id${withGeometry ? `,
              public.ST_Area(geometry::public.geography) AS area,
              public.ST_X(public.ST_Centroid(geometry)) AS lon,
              public.ST_Y(public.ST_Centroid(geometry)) AS lat,
              public.ST_XMax(geometry) - public.ST_XMin(geometry) AS lon_span` : ''}
         FROM essentials.geofence_boundaries
        WHERE mtfcc = $1 AND geo_id > $2 ORDER BY geo_id LIMIT 2000`,
      [mtfcc, after]
    );
    for (const r of rows) {
      m.set(String(r.geo_id), withGeometry
        ? { area: Number(r.area), lat: Number(r.lat), lon: Number(r.lon), lonSpan: Number(r.lon_span) }
        : null);
    }
    if (rows.length < 2000) break;
    after = rows[rows.length - 1].geo_id;
  }
  return m;
}

/** Great-circle km. */
function kmBetween(aLat, aLon, bLat, bLon) {
  const R = 6371;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(bLat - aLat);
  const dLon = toRad(bLon - aLon);
  const h = Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
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
      const displaced = [];
      for (const [geoid, mine] of ours) {
        const t = theirs.get(geoid);
        if (!t?.area || !mine?.area) continue;
        const d = Math.abs(mine.area - t.area) / t.area;
        if (d > AREA_TOLERANCE) {
          offenders.push({ geoid, name: t.name, delta: d, ourKm2: mine.area / 1e6, theirKm2: t.area / 1e6 });
        }
        // DISPLACEMENT — a different question from area, and the one that catches the worst
        // defect class: the right GEOID carrying the wrong place's geometry. 5100090 is
        // "Albemarle County Public Schools" and we held ALEXANDRIA CITY under it, 159 km away;
        // area caught that only because the two happened to differ 47-fold. A swap between two
        // similarly sized districts would have passed every area test silently.
        //
        // Scale-free threshold: flag when the centroids are further apart than the authority's
        // own radius (sqrt(area/pi)), floored at 2 km so tiny polygons do not fire on rounding.
        // A boundary revision moves a centroid a fraction of its radius; a swap moves it multiples.
        //
        // ⚠ ANTIMERIDIAN. A centroid is meaningless for a polygon that crosses 180° longitude:
        // the Aleutians West Census Area (02016) reported a 5,228 km displacement — halfway
        // round the planet — because ST_Centroid averaged longitudes either side of the line.
        // That is this method's own false positive, not a defect, so skip anything out there
        // rather than baselining a number that was never true.
        //
        // 🔴 THE CENTROID'S POSITION IS THE WRONG THING TO TEST, AND THAT COST A RED ON MASTER.
        // The ±170 test asks where the centroid LANDED. It catches 02016, whose bogus centroid
        // happens to land out near the line — but it misses a polygon with enough mass on the
        // mainland to drag the average back to an ordinary-looking longitude. Measured
        // 2026-10-31, when Alaska's legislative districts were loaded: House District 37 (02037)
        // and Senate District S (0200S) both reach the WESTERN ALEUTIANS, so their parts run
        // from -179.231 to +179.860 — a longitude span of 359°. Their naive centroids land at
        // -150.7 and -153.2, which the ±170 test waves straight through, and the check then
        // called them 529 km and 414 km out of place. Both polygons are byte-identical to
        // TIGER: same 38 and 41 parts, same 314,305 and 388,713 km², same longitude range.
        // Nothing was wrong with the data.
        //
        // ▶ So ask the GEOMETRY whether it crosses the line, not the centroid where it ended up.
        // No genuine district spans more than 180° of longitude; one that appears to is wrapped.
        // Every other Alaska district spans 12-31°, so this separates cleanly and does NOT widen
        // into a blanket Alaska exemption — the other 58 are still displacement-tested.
        // 🔴 NOT BASELINED. A baseline entry would have recorded these two as REAL defects
        // awaiting repair, which is what that list means, and they are not defects at all.
        const wrapsAntimeridian = Number.isFinite(mine.lonSpan) && mine.lonSpan > 180;
        const nearAntimeridian = wrapsAntimeridian || Math.abs(t.lon) > 170 || Math.abs(mine.lon ?? 0) > 170;
        if (!nearAntimeridian && Number.isFinite(t.lat) && Number.isFinite(t.lon) && Number.isFinite(mine.lat)) {
          const km = kmBetween(mine.lat, mine.lon, t.lat, t.lon);
          const radiusKm = Math.sqrt(t.area / Math.PI) / 1000;
          if (km > Math.max(2, radiusKm)) {
            displaced.push({ geoid, name: t.name, km, radiusKm });
          }
        }
      }
      displaced.sort((a, b) => b.km - a.km);
      offenders.sort((a, b) => b.delta - a.delta);
      entry.areaOff = offenders.length;
      entry.worstArea = offenders.length ? `${(offenders[0].delta * 100).toFixed(2)}%` : '0%';
      entry.worstOffenders = offenders.slice(0, 5);

      // Score against the baseline by IDENTITY. Known defects do not fail; anything new does,
      // and anything that has left the baseline is reported so the file can shrink.
      const known = baseline[spec.mtfcc] ?? {};
      const knownMissing = asSet(known.missing);
      const knownAreaOff = asSet(known.areaOff);
      const knownDisplaced = asSet(known.displaced);

      entry.currentMissing = entry.gaps.map((g) => g.geoid);
      entry.currentAreaOff = offenders.map((o) => o.geoid);
      entry.currentDisplaced = displaced.map((d) => d.geoid);

      entry.newMissing = entry.gaps.filter((g) => !knownMissing.has(g.geoid));
      entry.newAreaOff = offenders.filter((o) => !knownAreaOff.has(o.geoid));
      entry.newDisplaced = displaced.filter((d) => !knownDisplaced.has(d.geoid));
      entry.fixedMissing = [...knownMissing].filter((g) => !entry.currentMissing.includes(g));
      entry.fixedAreaOff = [...knownAreaOff].filter((g) => !entry.currentAreaOff.includes(g));
      entry.knownMissing = entry.gaps.length - entry.newMissing.length;
      entry.knownAreaOff = offenders.length - entry.newAreaOff.length;
      entry.worstDisplaced = displaced.slice(0, 5);

      entry.ok = entry.newMissing.length === 0 && entry.newAreaOff.length === 0 &&
                 entry.newDisplaced.length === 0;
      if (!entry.ok) failed = true;
    } catch (err) {
      if (err instanceof UpstreamUnavailable) { entry.ok = true; entry.skipped = true; entry.note = `SKIPPED — ${err.message}`; }
      else { entry.ok = false; entry.note = `could not run: ${err.message}`; failed = true; }
    }
    results.push(entry);
    if (!asJson) print(entry);
  }
  if (asJson) console.log(JSON.stringify({ ok: !failed, vintage: CLAIMED, results }, null, 2));

  if (updateBaseline) {
    if (onlyMtfcc) {
      console.error('\nRefusing to --update-baseline for a single layer: it would rewrite the whole');
      console.error('file from one layer\'s result and silently empty every other layer. Run it bare,');
      console.error('or hand-edit the one list you mean to change.');
      process.exitCode = 1;
    } else {
      const layers = {};
      for (const r of results) {
        if (r.skipped || r.currentMissing === undefined) {
          // Never write a layer we could not measure: an unreachable authority would otherwise
          // blank its list and silently forgive every known defect in it.
          layers[r.mtfcc] = baseline[r.mtfcc] ?? { missing: [], areaOff: [] };
          continue;
        }
        layers[r.mtfcc] = {
          missing: [...r.currentMissing].sort(),
          areaOff: [...r.currentAreaOff].sort(),
          displaced: [...r.currentDisplaced].sort(),
        };
      }
      const payload = {
        _comment:
          'Baseline for check-tiger-layer-fidelity.mjs, keyed mtfcc -> { missing, areaOff, ' +
          'displaced } as GEOIDs. Identities, NOT counts: a count baseline cannot see a defect ' +
          'that replaces another. `missing` = a governed polygon the authority lists inside a ' +
          'state we have adopted and we do not hold (2026-10-21: eight newly incorporated ' +
          'municipalities, San Tan Valley AZ the largest at ~100k residents). `areaOff` = right ' +
          'GEOID, area off the claimed vintage by >5%, cause not diagnosed. `displaced` = right ' +
          'GEOID, geometry in the WRONG PLACE. ' +
          'THE displaced LIST IS NOT NOISE AND MUST NOT BE TREATED AS ACCEPTED: 5100090 is ' +
          '"Albemarle County Public Schools" and we hold ALEXANDRIA CITY under it, 156 km away, ' +
          'so nobody in Albemarle County reaches their school board and Alexandria residents ' +
          'reach Albemarle\'s. 5513359275 (Oconomowoc town) is 7 km off with a 1 km radius and ' +
          '81 sq km against the authority\'s 1.3. Those two are repairs owed, baselined only to ' +
          'keep the gate green while they are worked. The gate fires on anything NOT in these ' +
          'lists. Shrink them as the backlog is worked off; never grow one without saying why in ' +
          'the commit message.',
        _asOf: new Date().toISOString().slice(0, 10),
        _vintage: CLAIMED,
        layers,
      };
      writeFileSync(BASELINE_PATH, `${JSON.stringify(payload, null, 2)}\n`);
      console.log(`\nBaseline written to ${path.relative(process.cwd(), BASELINE_PATH)}`);
      console.log('Read the diff before committing it — this absorbs whatever is broken today.');
      process.exitCode = 0;
    }
  }
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
  if (r.knownMissing) console.log(`        · ${r.knownMissing} missing polygons, all baselined (known backlog)`);
  if (r.knownAreaOff) console.log(`        · ${r.knownAreaOff} area mismatches, all baselined (known backlog)`);
  if (r.newMissing?.length) {
    console.log(`        ! ${r.newMissing.length} GOVERNED polygons NOT in the baseline — the authority has them, we do not:`);
    for (const g of r.newMissing.slice(0, 10)) console.log(`            ${g.geoid}  ${g.name}`);
    if (r.newMissing.length > 10) console.log(`            … and ${r.newMissing.length - 10} more`);
  }
  if (r.newAreaOff?.length) {
    console.log(`        ! ${r.newAreaOff.length} polygons NOT in the baseline differ in area by >5%:`);
    for (const o of r.newAreaOff.slice(0, 5)) {
      console.log(`            ${o.geoid}  ${o.name}: ours ${o.ourKm2.toFixed(1)} km2, authority ${o.theirKm2.toFixed(1)} km2`);
    }
  }
  // Somebody fixed something. Not a failure, but the baseline should stop claiming it.
  if (r.fixedMissing?.length) {
    console.log(`        ✓ ${r.fixedMissing.length} baselined missing polygon(s) now present — shrink the baseline: ${r.fixedMissing.slice(0, 6).join(', ')}`);
  }
  if (r.fixedAreaOff?.length) {
    console.log(`        ✓ ${r.fixedAreaOff.length} baselined area mismatch(es) resolved — shrink the baseline: ${r.fixedAreaOff.slice(0, 6).join(', ')}`);
  }
  if (r.newDisplaced?.length) {
    console.log(`        🔴 ${r.newDisplaced.length} polygon(s) are IN THE WRONG PLACE — right GEOID, somebody else's geometry:`);
    for (const d of r.newDisplaced.slice(0, 5)) {
      console.log(`            ${d.geoid}  ${d.name}: our centroid is ${d.km.toFixed(0)} km away (its own radius is ${d.radiusKm.toFixed(0)} km)`);
    }
  } else if (r.currentDisplaced?.length) {
    console.log(`        · ${r.currentDisplaced.length} displaced polygon(s), all baselined — these are REAL defects awaiting repair, not noise`);
  }
}

// exitCode, not exit(): let the pool's handles close or Windows libuv asserts on teardown
process.exitCode = failed ? 1 : 0;
