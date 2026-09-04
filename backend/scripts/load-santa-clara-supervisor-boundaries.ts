#!/usr/bin/env -S npx tsx
/**
 * load-santa-clara-supervisor-boundaries.ts
 *
 * Fetches the 5 Santa Clara County supervisorial district boundaries and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='santa-clara-ca-supervisor-district-1'..'-5',
 *                                   mtfcc='X0047', state='ca'
 *
 * Writes ONLY to essentials.geofence_boundaries. The CA-2 structure migration creates the
 * five districts and their offices, and refuses to run if these five boundaries are absent.
 *
 * Wave CA-2 of the Knight Foundation cities program.
 * Spec:    docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Roster:  backend/data/seed-santa-clara-2026/ROSTERS.md
 * Tracker: .planning/knight-foundation/PROGRAM.md
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 SANTA CLARA PUBLISHES FIVE COMPETING SUPERVISOR LAYERS AND THE GA-4 INVERSION IS LIVE
 *    IN BOTH DIRECTIONS. The layer with the FRESHEST edit date carries the OLDEST map.
 *
 * The CA-2 research pass measured all five. The trap is the county Planning layer
 * (PlanningOfficeDataService2/FeatureServer/5): the most recent edit date in the county's
 * entire GIS estate, the correct five names, and boundaries IDENTICAL to the superseded 2011
 * map — 0.000 sq mi difference on all five districts.
 *
 * 🟢 THE ARBITER IS THE BODY'S OWN RESIDENT-FACING LOOKUP. The Board's "Find My Supervisor"
 *    app (appid 5a47e27abd29447d8b6420fded6091af) resolves to webmap
 *    a51f16fac6304375bbe95813670ae6d9, whose ONLY operational layer is the one loaded here.
 *    Re-verified 2026-09-03 by walking appid -> webmap -> layer. That is the map the county
 *    tells voters, which is the question this table has to answer.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────
 * ⚠ THE COUNTY-CLOSURE TEST DOES NOT DISCRIMINATE HERE, AND THE RESEARCH RECORD IMPLIED IT
 *   DID. Measured 2026-09-03 against production's own 06085/G4020 county polygon, the union
 *   of this layer, of the "2021 Final Plan" layer, AND of the superseded 2011 layer all come
 *   out the SAME: 4.63 sq mi outside the county, 3.75 sq mi of county uncovered. So closure
 *   is a property of the REFERENCE — the county's digitisation against TIGER's — not of the
 *   layer, and it cannot tell a current map from a stale one. The research's "closes to
 *   0.0002 sq mi" was measured against some other county boundary.
 *
 *   GATE 6 therefore asserts closure only as a SANITY BOUND, and GATE 5 does the real work:
 *   every district must differ SUBSTANTIALLY from the 2011 map. That is what a load of the
 *   trap layer would fail.
 *
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER. GATE 2 compares this layer's NAME field
 *   against the verified roster purely as a VINTAGE test — a layer naming a departed
 *   supervisor is a layer nobody maintains. The roster that reaches the database comes from
 *   the county's Elected Officials page and the Registrar's own officeholder records.
 *
 * ⚠ POPULATION IS NOT WRITTEN. Layer E carries no population field and nothing else was
 *   sourced, so districts.population stays NULL rather than carrying a guess.
 *
 * Usage:
 *   npx tsx scripts/load-santa-clara-supervisor-boundaries.ts --dry-run
 *   npx tsx scripts/load-santa-clara-supervisor-boundaries.ts
 */
import 'dotenv/config';
import { Pool } from 'pg';

const HOST = 'https://services2.arcgis.com/tcv2cMrq63AgvbHF/arcgis/rest/services';

/** Layer E — what the Board's own "Find My Supervisor" app serves. outSR=4326 is load-bearing. */
const PRIMARY_URL =
  `${HOST}/Supervisorial_Districts_2021_web_app_test/FeatureServer/0` +
  `/query?where=1%3D1&outFields=DISTRICT,NAME&returnGeometry=true&outSR=4326&f=geojson`;

/** Layer I — the superseded 2011 map, used as the anti-trap control. Carries NO district field. */
const CONTROL_2011_URL =
  `${HOST}/Supervisorial_Districts_2011/FeatureServer/0` +
  `/query?where=1%3D1&outFields=OBJECTID&returnGeometry=true&outSR=4326&f=geojson`;

const MTFCC = 'X0047';
/**
 * state = 'ca', not FIPS '06'.
 * ⚠ The column genuinely holds both styles. Every private MTFCC from X0030 up uses lowercase
 * USPS (tx, tn, fl, ga, ca, co, nc); X0001–X0029 and all TIGER layers use 2-digit FIPS —
 * including San José's own X0010 council layer in this very county. Measured 2026-09-03: 352
 * FIPS rows against 215 USPS rows across the X-codes. This follows the modern half and
 * CA-1's X0046 for the same state. Nothing in the address-resolution path reads it —
 * electionService joins geo_id and ST_Covers with no state filter — and the coverage
 * services filter on `state` only for TIGER MTFCCs.
 */
const STATE_CODE = 'ca';
const SOURCE =
  'sccgov-arcgis-Supervisorial_Districts_2021_web_app_test-2026-09-03 (Knight CA-2); ' +
  'arbitrated as the layer served by the Board of Supervisors\' own "Find My Supervisor" ' +
  'app (appid 5a47e27abd29447d8b6420fded6091af -> webmap a51f16fac6304375bbe95813670ae6d9)';
const GEO_ID_PREFIX = 'santa-clara-ca-supervisor-district-';
const OCD_PREFIX = 'ocd-division/country:us/state:ca/county:santa_clara/council_district:';

const COUNTY_GEO_ID = '06085';
const COUNTY_MTFCC = 'G4020';

const EXPECTED_COUNT = 5;
const DISTRICTS = ['1', '2', '3', '4', '5'] as const;

/** GATE 2 — vintage test only. Never the source of the roster. */
const EXPECTED_ROSTER: Record<string, string> = {
  '1': 'Sylvia Arenas',
  '2': 'Betty Duong',
  '3': 'Otto Lee',
  '4': 'Susan Ellenberg',
  '5': 'Margaret Abe-Koga',
};

/**
 * GATE 3 — measured 2026-09-03 against production PostGIS, ST_MakeValid first.
 * ⚠ Districts 1, 3 and 5 are large because they hold the county's rural south and west;
 *   2 and 4 are dense urban San José. A 20x spread between the largest and smallest is
 *   correct here and is not a sign of a bad load.
 */
const EXPECTED_AREA_SQ_MI: Record<string, number> = {
  '1': 723.5228,
  '2': 40.0138,
  '3': 256.6651,
  '4': 48.8806,
  '5': 235.8524,
};
const AREA_TOLERANCE_PCT = 2;

const EXPECTED_UNION_SQ_MI = 1304.9346;
const UNION_TOLERANCE_SQ_MI = 1.0;

/** GATE 4 — measured at exactly 0.000000 sq mi on all ten pairs. */
const MAX_PAIR_OVERLAP_SQ_MI = 0.001;

/**
 * GATE 5 — the anti-trap gate, and the one that actually matters.
 * Measured symmetric difference against the best-matching 2011 polygon:
 *   D1 244.89 · D2 10.13 · D3 145.88 · D4 6.35 · D5 119.36
 * The smallest is D4 at 6.35, so 5.0 leaves headroom while still being far above the
 * 0.000 a load of the trap layer would produce.
 */
const MIN_SYMDIFF_VS_2011_SQ_MI = 5.0;

/** GATE 6 — sanity bound only. See the header: this does NOT discriminate between layers. */
const MAX_OUTSIDE_COUNTY_SQ_MI = 6.0;
const MAX_COUNTY_UNCOVERED_SQ_MI = 5.0;

const DRY_RUN = process.argv.includes('--dry-run');
const SQM_PER_SQMI = 2589988.110336;

interface Feature {
  properties?: Record<string, unknown> | null;
  geometry?: unknown;
}

function fail(msg: string): never {
  console.error(`\n❌ ${msg}`);
  process.exit(1);
}

async function fetchGeoJson(url: string, label: string): Promise<Feature[]> {
  const r = await fetch(url, { headers: { 'User-Agent': 'EmpoweredVote-civic-data/1.0' } });
  if (!r.ok) fail(`${label}: HTTP ${r.status}`);
  const j = (await r.json()) as { features?: Feature[]; error?: unknown };
  // ⚠ ArcGIS reports failures INSIDE a 200 body, so r.ok is not the test.
  if (j.error) fail(`${label}: service returned an error payload: ${JSON.stringify(j.error)}`);
  if (!Array.isArray(j.features)) fail(`${label}: no features array in the response`);
  return j.features;
}

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const q = async (sql: string, params: unknown[] = []) => (await pool.query(sql, params)).rows;

  console.log(`Santa Clara County supervisorial districts -> ${MTFCC}${DRY_RUN ? '  (DRY RUN)' : ''}`);

  // ─── GATE 1: the layer is five single polygons keyed 1..5 ────────────────────────────
  console.log('\nGATE 1 — the layer returns 5 districts, one row each');
  const feats = await fetchGeoJson(PRIMARY_URL, 'primary layer');
  if (feats.length !== EXPECTED_COUNT) {
    fail(`GATE 1: expected ${EXPECTED_COUNT} features, got ${feats.length}.`);
  }
  const byDistrict = new Map<string, Feature>();
  for (const f of feats) {
    const raw = f.properties?.DISTRICT;
    const d = raw == null ? '' : String(raw).trim();
    if (!DISTRICTS.includes(d as (typeof DISTRICTS)[number])) {
      fail(`GATE 1: unexpected DISTRICT value ${JSON.stringify(raw)}.`);
    }
    if (byDistrict.has(d)) fail(`GATE 1: district ${d} appears more than once.`);
    if (!f.geometry) fail(`GATE 1: district ${d} carries no geometry.`);
    byDistrict.set(d, f);
  }
  for (const d of DISTRICTS) if (!byDistrict.has(d)) fail(`GATE 1: district ${d} is missing.`);
  console.log(`  ✓ ${EXPECTED_COUNT} districts, keys 1..5, one row each`);

  // ─── GATE 2: the layer is MAINTAINED (a vintage test, never a roster) ────────────────
  console.log('\nGATE 2 — the layer names the sitting supervisors (vintage test only)');
  const drift: string[] = [];
  for (const d of DISTRICTS) {
    const got = String(byDistrict.get(d)!.properties?.NAME ?? '').trim();
    if (got !== EXPECTED_ROSTER[d]) drift.push(`D${d}: layer says "${got}", roster says "${EXPECTED_ROSTER[d]}"`);
  }
  if (drift.length) {
    fail(
      `GATE 2: the layer's roster field has drifted from the verified roster:\n    ` +
        drift.join('\n    ') +
        `\n  This is a VINTAGE test. Either the layer has gone stale, or a supervisor has left ` +
        `and the roster in ROSTERS.md needs re-checking. Districts 1 and 4 turn over in ` +
        `January 2027 (Arenas and Ellenberg are on the 2026 ballot), at which point this gate ` +
        `must be updated. Do NOT take the new name from here.`,
    );
  }
  console.log('  ✓ all five names match the verified roster');

  // Geometry is handed to PostGIS as GeoJSON literals throughout.
  const geoJsonOf = (d: string) => JSON.stringify(byDistrict.get(d)!.geometry);

  // ─── GATE 3: each polygon is valid and the right size ────────────────────────────────
  console.log('\nGATE 3 — every polygon is valid, and its area matches what was measured');
  for (const d of DISTRICTS) {
    const [row] = await q(
      `SELECT public.ST_IsValid(g) AS valid,
              public.ST_GeometryType(g) AS gtype,
              (public.ST_Area(public.ST_MakeValid(g)::geography) / $2)::numeric(12,4) AS sq_mi
         FROM (SELECT public.ST_SetSRID(public.ST_GeomFromGeoJSON($1), 4326) AS g) t`,
      [geoJsonOf(d), SQM_PER_SQMI],
    );
    if (!row.valid) fail(`GATE 3: district ${d} is not a valid geometry.`);
    const got = Number(row.sq_mi);
    const want = EXPECTED_AREA_SQ_MI[d];
    const driftPct = Math.abs(got - want) / want * 100;
    if (driftPct > AREA_TOLERANCE_PCT) {
      fail(
        `GATE 3: district ${d} is ${got} sq mi against an expected ${want} ` +
          `(${driftPct.toFixed(2)}% drift, tolerance ${AREA_TOLERANCE_PCT}%). ` +
          `The map may have been redrawn — re-measure before widening this.`,
      );
    }
    console.log(`  ✓ D${d}: ${got} sq mi (${row.gtype}, ${driftPct.toFixed(2)}% from measured)`);
  }

  // ─── GATE 4: the five do not overlap ────────────────────────────────────────────────
  console.log('\nGATE 4 — no two districts share ground');
  let worst = 0;
  for (let i = 0; i < DISTRICTS.length; i++) {
    for (let j = i + 1; j < DISTRICTS.length; j++) {
      // ⚠ ST_MakeValid FIRST. Raw sliver noise inflated an off-diagonal ~35x in an earlier
      //   wave, so an overlap taken before MakeValid measures the digitisation, not the map.
      const [row] = await q(
        `SELECT (public.ST_Area(public.ST_Intersection(a, b)::geography) / $3)::numeric(14,6) AS sq_mi
           FROM (SELECT public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326)) AS a,
                        public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($2),4326)) AS b) t`,
        [geoJsonOf(DISTRICTS[i]), geoJsonOf(DISTRICTS[j]), SQM_PER_SQMI],
      );
      const ov = Number(row.sq_mi);
      worst = Math.max(worst, ov);
      if (ov > MAX_PAIR_OVERLAP_SQ_MI) {
        fail(`GATE 4: districts ${DISTRICTS[i]} and ${DISTRICTS[j]} overlap by ${ov} sq mi.`);
      }
    }
  }
  console.log(`  ✓ worst pairwise overlap ${worst.toFixed(6)} sq mi (limit ${MAX_PAIR_OVERLAP_SQ_MI})`);

  // ─── GATE 5: this is NOT the 2011 map ───────────────────────────────────────────────
  console.log('\nGATE 5 — every district differs substantially from the superseded 2011 map');
  const control = await fetchGeoJson(CONTROL_2011_URL, '2011 control layer');
  if (control.length !== EXPECTED_COUNT) {
    fail(`GATE 5: the 2011 control returned ${control.length} polygons, expected ${EXPECTED_COUNT}.`);
  }
  // The control carries NO district attribute — only OBJECTID — so each district is paired
  // with the 2011 polygon it overlaps most, then compared.
  for (const d of DISTRICTS) {
    let best = { idx: -1, overlap: -1, symdiff: -1 };
    for (let k = 0; k < control.length; k++) {
      const [row] = await q(
        `SELECT (public.ST_Area(public.ST_Intersection(a, b)::geography) / $3)::numeric(14,4) AS overlap,
                (public.ST_Area(public.ST_SymDifference(a, b)::geography) / $3)::numeric(14,4) AS symdiff
           FROM (SELECT public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326)) AS a,
                        public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($2),4326)) AS b) t`,
        [geoJsonOf(d), JSON.stringify(control[k].geometry), SQM_PER_SQMI],
      );
      const overlap = Number(row.overlap);
      if (overlap > best.overlap) best = { idx: k, overlap, symdiff: Number(row.symdiff) };
    }
    if (best.symdiff < MIN_SYMDIFF_VS_2011_SQ_MI) {
      fail(
        `GATE 5: district ${d} differs from its nearest 2011 polygon by only ${best.symdiff} sq mi ` +
          `(floor ${MIN_SYMDIFF_VS_2011_SQ_MI}). THIS IS THE TRAP LAYER SIGNATURE — the county ` +
          `Planning layer carries the current roster on 2011 boundaries and would score ~0 here. ` +
          `Do not widen this gate; check which layer is being fetched.`,
      );
    }
    console.log(`  ✓ D${d}: ${best.symdiff} sq mi from the 2011 map`);
  }

  // ─── GATE 6: the union is the right size, and roughly closes on the county ──────────
  console.log('\nGATE 6 — the union matches what was measured, and sits on the county');
  const unionSelect = DISTRICTS.map(
    (_, i) => `SELECT public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($${i + 1}),4326)) AS g`,
  ).join(' UNION ALL ');
  const params = DISTRICTS.map(geoJsonOf);
  const [u] = await q(
    `WITH parts AS (${unionSelect}),
          un AS (SELECT public.ST_Union(g) AS g FROM parts),
          c  AS (SELECT public.ST_MakeValid(geometry) AS g FROM essentials.geofence_boundaries
                  WHERE geo_id = $${DISTRICTS.length + 1} AND mtfcc = $${DISTRICTS.length + 2})
     SELECT (public.ST_Area(un.g::geography) / $${DISTRICTS.length + 3})::numeric(12,4) AS union_sq_mi,
            (public.ST_Area(public.ST_Difference(un.g, c.g)::geography) / $${DISTRICTS.length + 3})::numeric(12,4) AS outside,
            (public.ST_Area(public.ST_Difference(c.g, un.g)::geography) / $${DISTRICTS.length + 3})::numeric(12,4) AS uncovered
       FROM un, c`,
    [...params, COUNTY_GEO_ID, COUNTY_MTFCC, SQM_PER_SQMI],
  );
  if (!u) fail(`GATE 6: the county polygon ${COUNTY_GEO_ID}/${COUNTY_MTFCC} is not in production.`);
  const unionSqMi = Number(u.union_sq_mi);
  if (Math.abs(unionSqMi - EXPECTED_UNION_SQ_MI) > UNION_TOLERANCE_SQ_MI) {
    fail(`GATE 6: union is ${unionSqMi} sq mi against an expected ${EXPECTED_UNION_SQ_MI}.`);
  }
  const outside = Number(u.outside);
  const uncovered = Number(u.uncovered);
  if (outside > MAX_OUTSIDE_COUNTY_SQ_MI) {
    fail(`GATE 6: ${outside} sq mi of the union falls outside the county (bound ${MAX_OUTSIDE_COUNTY_SQ_MI}).`);
  }
  if (uncovered > MAX_COUNTY_UNCOVERED_SQ_MI) {
    fail(`GATE 6: ${uncovered} sq mi of the county is covered by no district (bound ${MAX_COUNTY_UNCOVERED_SQ_MI}).`);
  }
  console.log(
    `  ✓ union ${unionSqMi} sq mi; ${outside} outside the county, ${uncovered} uncovered ` +
      `— a two-digitisation gap, NOT a layer-vintage signal (see the header)`,
  );

  // ─── WRITE ──────────────────────────────────────────────────────────────────────────
  console.log(`\n${DRY_RUN ? 'WOULD WRITE' : 'WRITING'} ${EXPECTED_COUNT} boundaries`);
  if (DRY_RUN) {
    for (const d of DISTRICTS) {
      console.log(`  would insert ${GEO_ID_PREFIX}${d} / ${MTFCC} — District ${d}`);
    }
    console.log('\nDRY RUN — nothing written.');
    await pool.end();
    return;
  }

  let inserted = 0;
  let skipped = 0;
  for (const d of DISTRICTS) {
    // Composite key is (geo_id, mtfcc). ON CONFLICT DO NOTHING makes a re-run a no-op
    // rather than silently replacing geometry someone may have repaired by hand.
    const rows = await q(
      `INSERT INTO essentials.geofence_boundaries
         (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
       VALUES ($1, $2, $3, $4, $5,
               public.ST_Multi(public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($6), 4326))),
               $7, now())
       ON CONFLICT (geo_id, mtfcc) DO NOTHING
       RETURNING geo_id`,
      [
        `${GEO_ID_PREFIX}${d}`,
        `${OCD_PREFIX}${d}`,
        `Supervisorial District ${d}`,
        STATE_CODE,
        MTFCC,
        geoJsonOf(d),
        SOURCE,
      ],
    );
    if (rows.length) {
      inserted++;
      console.log(`  inserted ${GEO_ID_PREFIX}${d}`);
    } else {
      skipped++;
      console.log(`  skipped  ${GEO_ID_PREFIX}${d} (already present)`);
    }
  }

  const [after] = await q(
    `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
    [MTFCC],
  );
  console.log(`\ninserted ${inserted} · skipped ${skipped} · ${MTFCC} now holds ${after.n} rows`);
  if (after.n !== EXPECTED_COUNT) {
    fail(`post-check: ${MTFCC} holds ${after.n} rows, expected ${EXPECTED_COUNT}.`);
  }
  await pool.end();
}

main().catch((e) => fail(String(e?.stack ?? e)));
