#!/usr/bin/env node
/**
 * check-council-district-vintage.mjs
 *
 * Catches a STALE BOUNDARY: a council-district polygon layer we serve that no longer matches the
 * authority that draws it. This is the defect CA_0317 repaired -- Los Angeles shipped the
 * 2012-adopted council map for years under a source tag that said 2024, because the loader pointed
 * at a third-party ArcGIS Online copy that had been frozen since 2021-03-22.
 *
 * Why the obvious checks do not catch it:
 *   - Row counts pass. All 15 districts were present the whole time.
 *   - `backend/scripts/check-la-council-bounds.ts` passes. It asserts the rows EXIST.
 *   - A ROSTER cross-check passes. The stale layer carried a councilmember name per polygon and
 *     every name was a sitting member -- the boundaries were stale while the names were current.
 *   - Reachability passes. Every district resolved to someone; just the wrong someone.
 *
 * The only thing that exposes it is comparing GEOMETRY against an independent authority, which is
 * what this does: per-district area (a redistricting moves districts while preserving their union
 * -- the Lexington signature) plus interior-point agreement (catches drift an area test can miss,
 * e.g. two districts that trade equal-sized areas).
 *
 * Usage:
 *   node scripts/check-council-district-vintage.mjs            # gate every registered layer
 *   node scripts/check-council-district-vintage.mjs --key la   # one layer
 *   node scripts/check-council-district-vintage.mjs --json
 *
 * Exit 0 = every registered layer matches its authority. Exit 1 = a registered layer has drifted.
 *
 * Layers with no registry entry are UNGATED: they are printed on every run but do not fail the
 * build unless --strict is passed. That is deliberate -- a check that is red from the day it lands
 * teaches people to ignore it, and "nobody has verified this yet" is a backlog item, not a
 * regression. The printed count is what keeps it from going quiet.
 */
import 'dotenv/config';
import pg from 'pg';

/**
 * Each entry names the AUTHORITY for one council-district layer -- preferably the body that builds
 * ballots from it, never a re-publication we cannot date. `district` reads the district number out
 * of an upstream feature's properties.
 *
 * To add a layer: find the authority, prove the vintage against it BEFORE adding the entry (an
 * entry here asserts "this upstream is correct"), then add it. Do not point one of these at an
 * arcgis.com item unless you have checked `editingInfo.lastEditDate` on the service itself.
 */
const REGISTRY = [
  {
    key: 'la',
    label: 'Los Angeles city council',
    ocdPrefix: 'ocd-division/country:us/state:ca/place:los_angeles/council_district:',
    url:
      'https://maps.lacity.org/lahub/rest/services/Boundaries/MapServer/13/query' +
      '?where=1%3D1&outFields=District&returnGeometry=true&outSR=4326&f=geojson',
    district: (props) => Number(props.District),
    expect: 15,
    // Proved 2026-10-20 against LA County Registrar-Recorder precincts (Political_Boundaries
    // MapServer 34, DST_CITY=LS / DIV_CITY), 25 of 25 disputed cells. See CA_0317.
  },
];

/**
 * Council-district layers that exist in geofence_boundaries but have NO authority registered, so
 * nothing here can vouch for them. They are listed rather than ignored: an ungated layer is the
 * state Los Angeles was in. Each one needs its authority identified and its vintage proved, then an
 * entry in REGISTRY above. Printed on every run; fails the build only under --strict.
 */
const KNOWN_UNGATED = [
  'sf_supervisor_districts_2022',
  'sj_city_council_districts_2022',
  'sd_city_council_districts_2022',
  'boston_city_council_districts_2023',
];

const argv = process.argv.slice(2);
const asJson = argv.includes('--json');
const strict = argv.includes('--strict');
const onlyKey = argv.includes('--key') ? argv[argv.indexOf('--key') + 1] : null;
const AREA_TOLERANCE = 0.005; // 0.5% per district
const POINTS_PER_DISTRICT = 60;

// ---------- geometry helpers (no turf dependency) ----------
function inRing(x, y, ring) {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i];
    const [xj, yj] = ring[j];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}
function inPolygon(x, y, poly) {
  if (!inRing(x, y, poly[0])) return false;
  for (let h = 1; h < poly.length; h++) if (inRing(x, y, poly[h])) return false;
  return true;
}
function toPolys(geometry) {
  return geometry.type === 'Polygon' ? [geometry.coordinates] : geometry.coordinates;
}
function bboxOf(polys) {
  let a = Infinity, b = Infinity, c = -Infinity, d = -Infinity;
  for (const p of polys) for (const [x, y] of p[0]) {
    if (x < a) a = x; if (x > c) c = x; if (y < b) b = y; if (y > d) d = y;
  }
  return [a, b, c, d];
}
// spherical excess; good to ~0.1% at city scale, and we only ever compare it to itself
function ringArea(ring) {
  const R = 6378137;
  let total = 0;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i];
    const [xj, yj] = ring[j];
    total += ((xi - xj) * Math.PI) / 180 *
      (2 + Math.sin((yj * Math.PI) / 180) + Math.sin((yi * Math.PI) / 180));
  }
  return Math.abs((total * R * R) / 2);
}
function polysArea(polys) {
  let a = 0;
  for (const poly of polys) {
    a += ringArea(poly[0]);
    for (let h = 1; h < poly.length; h++) a -= ringArea(poly[h]);
  }
  return a;
}
function lookup(index, x, y) {
  for (const entry of index) {
    const [a, b, c, d] = entry.bbox;
    if (x < a || x > c || y < b || y > d) continue;
    for (const p of entry.polys) if (inPolygon(x, y, p)) return entry.district;
  }
  return null;
}
// deterministic interior sample: walk the polygon's bbox on a grid, keep points inside
function samplePoints(polys, bbox, want) {
  const [minX, minY, maxX, maxY] = bbox;
  const pts = [];
  const steps = Math.ceil(Math.sqrt(want) * 4);
  for (let i = 1; i < steps && pts.length < want; i++) {
    for (let j = 1; j < steps && pts.length < want; j++) {
      const x = minX + ((maxX - minX) * i) / steps;
      const y = minY + ((maxY - minY) * j) / steps;
      for (const p of polys) if (inPolygon(x, y, p)) { pts.push([x, y]); break; }
    }
  }
  return pts;
}

/** Transport-level failure: the authority is unreachable, which says nothing about our data. */
class UpstreamUnavailable extends Error {}

async function fetchUpstream(entry) {
  let res;
  try {
    res = await fetch(entry.url, { headers: { accept: 'application/json' }, signal: AbortSignal.timeout(60_000) });
  } catch (err) {
    throw new UpstreamUnavailable(`could not reach the authority: ${err.message}`);
  }
  if (!res.ok) throw new UpstreamUnavailable(`authority returned HTTP ${res.status}`);
  const fc = await res.json();
  if (!fc.features?.length) throw new Error(`upstream returned no features for ${entry.key}`);
  return fc.features.map((f) => {
    const polys = toPolys(f.geometry);
    return { district: entry.district(f.properties), polys, bbox: bboxOf(polys), area: polysArea(polys) };
  });
}

async function checkEntry(pool, entry) {
  const { rows } = await pool.query(
    `SELECT split_part(ocd_id, ':', 5) AS district,
            public.ST_AsGeoJSON(geometry) AS gj,
            source
       FROM essentials.geofence_boundaries
      WHERE ocd_id LIKE $1 || '%'`,
    [entry.ocdPrefix]
  );
  const problems = [];
  if (!rows.length) return { key: entry.key, ok: false, problems: ['no rows in geofence_boundaries'] };

  const ours = rows.map((r) => {
    const polys = toPolys(JSON.parse(r.gj));
    return { district: Number(r.district), polys, bbox: bboxOf(polys), area: polysArea(polys) };
  });
  const theirs = await fetchUpstream(entry);

  if (entry.expect && ours.length !== entry.expect) {
    problems.push(`we hold ${ours.length} districts, expected ${entry.expect}`);
  }
  if (theirs.length !== ours.length) {
    problems.push(`authority publishes ${theirs.length} districts, we hold ${ours.length}`);
  }

  // 1. per-district area
  const theirsByNum = new Map(theirs.map((t) => [t.district, t]));
  let worst = 0;
  for (const o of ours) {
    const t = theirsByNum.get(o.district);
    if (!t) { problems.push(`district ${o.district} is absent from the authority's layer`); continue; }
    const delta = Math.abs(o.area - t.area) / t.area;
    if (delta > worst) worst = delta;
    if (delta > AREA_TOLERANCE) {
      problems.push(
        `district ${o.district} area differs by ${(delta * 100).toFixed(2)}% ` +
        `(ours ${(o.area / 1e6).toFixed(2)} sq km, authority ${(t.area / 1e6).toFixed(2)} sq km)`
      );
    }
  }

  // 2. interior-point agreement -- catches an equal-area trade an area test cannot see
  let tested = 0, disagreed = 0;
  const firstFew = [];
  for (const o of ours) {
    for (const [x, y] of samplePoints(o.polys, o.bbox, POINTS_PER_DISTRICT)) {
      const got = lookup(theirs, x, y);
      tested++;
      if (got !== o.district) {
        disagreed++;
        if (firstFew.length < 5) firstFew.push(`${x.toFixed(5)},${y.toFixed(5)}: ours ${o.district}, authority ${got ?? 'none'}`);
      }
    }
  }
  if (tested === 0) problems.push('no interior points could be sampled');
  const rate = tested ? disagreed / tested : 1;
  // a handful of boundary-hugging points can legitimately differ; a vintage mismatch is wholesale
  if (rate > 0.01) {
    problems.push(
      `${disagreed} of ${tested} interior points (${(rate * 100).toFixed(1)}%) land in a different ` +
      `district upstream -- this is what a stale map looks like. e.g. ${firstFew.join(' | ')}`
    );
  }

  return {
    key: entry.key,
    label: entry.label,
    ok: problems.length === 0,
    districts: ours.length,
    worstAreaDelta: `${(worst * 100).toFixed(2)}%`,
    pointsTested: tested,
    pointsDisagreed: disagreed,
    source: rows[0].source?.slice(0, 80),
    problems,
  };
}

// Forks get no secrets. Mirror check-address-reachability.mjs: skip rather than fail.
if (!process.env.DATABASE_URL) {
  console.log('check-council-district-vintage: DATABASE_URL is not set — skipping.');
  process.exit(0);
}

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

let failed = false;
const results = [];
try {
  const entries = onlyKey ? REGISTRY.filter((e) => e.key === onlyKey) : REGISTRY;
  if (!entries.length) {
    console.error(`No registry entry for --key ${onlyKey}`);
    process.exit(1);
  }
  for (const entry of entries) {
    try {
      const r = await checkEntry(pool, entry);
      results.push(r);
      if (!r.ok) failed = true;
    } catch (err) {
      if (err instanceof UpstreamUnavailable) {
        // A green skip beats a red build nobody can fix. We gate DRIFT, not the authority's uptime.
        results.push({ key: entry.key, label: entry.label, ok: true, skipped: true, problems: [`SKIPPED — ${err.message}`] });
      } else {
        results.push({ key: entry.key, ok: false, problems: [`check could not run: ${err.message}`] });
        failed = true;
      }
    }
  }

  // Ungated layers: only meaningful on a full run.
  let ungated = [];
  if (!onlyKey) {
    const { rows } = await pool.query(
      `SELECT DISTINCT source FROM essentials.geofence_boundaries
        WHERE mtfcc LIKE 'X%' AND source = ANY($1)`,
      [KNOWN_UNGATED]
    );
    ungated = rows.map((r) => r.source);
  }

  if (asJson) {
    console.log(JSON.stringify({ ok: !failed, results, ungated }, null, 2));
  } else {
    for (const r of results) {
      const tag = r.skipped ? 'SKIP' : r.ok ? 'OK  ' : 'FAIL';
      console.log(`${tag}  ${r.key.padEnd(6)} ${r.label ?? ''}`);
      if (r.districts) {
        console.log(`        ${r.districts} districts · worst area delta ${r.worstAreaDelta} · ` +
                    `${r.pointsDisagreed}/${r.pointsTested} interior points disagree`);
      }
      for (const p of r.problems) console.log(`        ! ${p}`);
    }
    if (ungated.length) {
      console.log(`\nUNGATED council-district layers (${ungated.length}) — no authority registered, ` +
                  `so nothing here vouches for them:`);
      for (const s of ungated) console.log(`        ? ${s}`);
      console.log(`        Identify each one's authority, prove the vintage against it, then add a`);
      console.log(`        REGISTRY entry in this file. This is the state Los Angeles was in (CA_0317).`);
      console.log(`        (--strict makes this fail the build.)`);
    }
  }
  if (ungated.length && strict) failed = true;
} finally {
  await pool.end();
}

process.exit(failed ? 1 : 0);
