/**
 * load-buncombe-commissioner-boundaries.ts
 *
 * Fetches the 3 Buncombe County (NC) Board of Commissioners district boundaries
 * and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='buncombe-nc-commissioner-district-1'..'-3',
 *                                   mtfcc='X0034', state='nc'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structural migration
 * (CA_0009) creates the COUNTY district rows, the commissioner offices and,
 * with CA_0010, the terms. The at-large chair, Sheriff, Register of Deeds and
 * Clerk of Superior Court are NOT here — they hang off the county polygon,
 * TIGER G4020 geo_id '37021', which is already loaded.
 *
 * Wave 3 of the NC deep-seed program.
 * Spec: .planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md
 * Plan: docs/superpowers/plans/2026-08-23-nc-wave-3-asheville-buncombe.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * WHY THESE POLYGONS ARE NOT JUST "SOME COUNTY LAYER"
 *
 * A 2011 local act took Buncombe from 5 commissioners to 7, made six of them
 * elected BY DISTRICT, and set the district lines EQUAL TO THE THREE NC HOUSE
 * DISTRICTS, two commissioners each. Buncombe is the only one of NC's 100
 * counties with this arrangement.
 *
 * 🔴 That makes this a LIVE COUPLING, not a coincidence. A future NC House
 * redraw silently moves Buncombe's commission lines. So this loader refuses to
 * write unless each fetched polygon still agrees with its NC House twin, and
 * scripts/verify-buncombe-commission-coupling.sql re-checks it on demand
 * afterwards. Run that script after any NC `sldl` reload.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * LAYER CHOICE — unusually, there is NO trap here, and that is measured.
 *
 * Buncombe publishes three commissioner-district layers:
 *
 *     bcmap_VotingDistricts3/7   "County Commissioner Districts"   <- CHOSEN
 *     bcmap_VotingDistricts3/14  "Bun.DBO.Cty_Commish_Dist"
 *     ElectionPrecinct/1         "County Commissioners"
 *
 * Measured 2026-08-23, all three are BYTE-IDENTICAL — same Shape.STArea(),
 * Shape.STLength() and PL20AA_TOT on all 3 features — and all three match
 * bcmap_VotingDistricts3/5 ("State House Districts") exactly, which is the
 * statutory coupling visible in the county's own data.
 *
 * ⚠ None of them publishes a `lastEditDate`. So the El Paso discriminator
 * (compare edit dates, distrust the plainly-named layer) is UNAVAILABLE here.
 * Layer 7 is chosen as the plainly-named one, and for this county that is safe —
 * but it is safe because of the coupling gate below, NOT because of the name.
 * If these three layers ever diverge, this comment is void: re-measure.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 `outSR=4326` IS LOAD-BEARING. The layer's native units are NC state-plane
 * feet — that is why Shape.STArea() reads ~652,739,949 for a 653 km2 district.
 * Dropping outSR writes projected coordinates into a geographic column. No row
 * count, and no NOT NULL, would catch it; the polygons would simply sit off the
 * coast of Africa and every address probe would return nothing.
 */

import { Pool } from 'pg';

const BC_DISTRICT_URL =
  'https://gis.buncombecounty.org/arcgis/rest/services/' +
  'bcmap_VotingDistricts3/MapServer/7/query' +
  '?where=1%3D1&outFields=DISTRICT%2CPL20AA_TOT' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC          = 'X0034';
const STATE_CODE     = 'nc';
const SOURCE         = 'buncombegov-arcgis-bcmap_VotingDistricts3-7-2026-08-23';
const GEO_ID_PREFIX  = 'buncombe-nc-commissioner-district-';
const COUNTY_GEO_ID  = '37021';
const EXPECTED_COUNT = 3;

/**
 * The statutory twin of each commission district, and the 2020 population the
 * county publishes for it. Both measured from the county's own service
 * 2026-08-23. The population is a cheap attribute tripwire; the geometry gate
 * below is the real check.
 */
const DISTRICT_SPEC: Record<number, { houseGeoId: string; pop: number }> = {
  1: { houseGeoId: '37114', pop: 91120 },
  2: { houseGeoId: '37115', pop: 88875 },
  3: { houseGeoId: '37116', pop: 89457 },
};

/**
 * 🔴 A TOLERANCE, NOT EQUALITY — and this is the whole subtlety of this loader.
 *
 * The spec records the commission districts as byte-identical to the state House
 * districts. True, but that is BUNCOMBE'S layer vs BUNCOMBE'S layer. Our House
 * polygons are TIGER 2024 `sldl`: an independent digitization of the same legal
 * boundary. Measured 2026-08-23, against TIGER:
 *
 *   D1 vs 37114:  ST_Equals FALSE, IoU 99.681%, symdiff 2.09 km2
 *   D2 vs 37115:  ST_Equals FALSE, IoU 99.883%, symdiff 1.07 km2
 *   D3 vs 37116:  ST_Equals FALSE, IoU 99.969%, symdiff 0.04 km2
 *
 * An ST_Equals gate would fail permanently on correct data, and the obvious fix
 * for a permanently-red gate is to delete it — losing the only check there is.
 *
 * The tolerance is not a rubber stamp. Every WRONG pairing was measured too:
 *
 *            37114     37115     37116
 *   D1      99.681%    0.002%    0.002%
 *   D2       0.000%   99.883%    0.001%
 *   D3       0.001%    0.002%   99.969%
 *
 * Correct ~99.7-100%, wrong ~0%. 99.0% leaves 0.68pp of headroom below the worst
 * correct pairing for a TIGER vintage change, while a real redraw moves whole
 * precincts and cannot hide underneath it.
 */
const MIN_IOU_PCT = 99.0;

/**
 * The three districts must tile the county, once. Measured 2026-08-23 against
 * TIGER county 37021 (1709.24 km2): 0.047 km2 spills outside, 3.004 km2 of
 * county is uncovered, and self-overlap is EXACTLY 0.000. The 3 km2 is edge
 * digitizing between the county's GIS and TIGER's county outline, not a hole.
 *
 * 6 km2 leaves headroom above that baseline while staying two orders of
 * magnitude below the smallest district (D3, 143 km2) — so a genuinely missing
 * or duplicated district cannot pass.
 */
const COUNTY_FIT_TOLERANCE_SQ_KM = 6.0;

const DRY_RUN = process.argv.includes('--dry-run');

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

type Feature = { properties: Record<string, unknown>; geometry: any | null };

/**
 * Positive controls, measured against the ALREADY-LOADED TIGER G5220 polygons
 * on 2026-08-23 — not against the layer being tested, which would be circular.
 * Asheville City Hall is in HD-116 so it must be commission D3; Black Mountain
 * is in HD-114 so it must be D1. Between them they exercise two of the three
 * districts and both ends of the county.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: number }> = [
  { name: 'Asheville City Hall', lon: -82.5554, lat: 35.5967, district: 3 },
  { name: 'Black Mountain',      lon: -82.3200, lat: 35.6197, district: 1 },
];

/** Ray-cast point-in-polygon over a GeoJSON Polygon/MultiPolygon, holes honoured. */
function pointInGeometry(geom: any, lon: number, lat: number): boolean {
  const polys: number[][][][] = geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
  for (const poly of polys) {
    let inOuter = false;
    let inHole = false;
    poly.forEach((ring, idx) => {
      let hit = false;
      for (let a = 0, b = ring.length - 1; a < ring.length; b = a++) {
        const [xi, yi] = ring[a];
        const [xj, yj] = ring[b];
        if ((yi > lat) !== (yj > lat) && lon < ((xj - xi) * (lat - yi)) / (yj - yi) + xi) hit = !hit;
      }
      if (idx === 0) inOuter = hit;
      else if (hit) inHole = true;
    });
    if (inOuter && !inHole) return true;
  }
  return false;
}

async function main() {
  console.log('[load-buncombe-commissioner-boundaries] Fetching Buncombe County commissioner districts');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes (every gate below still runs for real)');

  const response = (await (await fetch(BC_DISTRICT_URL)).json()) as { features?: Feature[] };
  if (!response?.features?.length) {
    console.error('ERROR: No features returned from the Buncombe County MapServer. Check the URL.');
    process.exit(1);
  }
  console.log(`  Received ${response.features.length} features`);

  const distMap = new Map<number, { geoId: string; name: string; geomStr: string; geom: any; pop: number }>();
  for (const feature of response.features) {
    const raw = String(feature.properties['DISTRICT'] ?? '');
    const dist = parseInt(raw.replace(/\D+/g, ''), 10);
    if (isNaN(dist) || dist < 1 || dist > EXPECTED_COUNT) {
      console.warn(`  WARNING: DISTRICT '${raw}' out of range — skipping`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING: district ${dist} has no geometry — skipping`);
      continue;
    }
    if (distMap.has(dist)) {
      console.error(`ERROR: district ${dist} appeared twice. Aborting rather than guessing.`);
      process.exit(1);
    }
    distMap.set(dist, {
      geoId: `${GEO_ID_PREFIX}${dist}`,
      name: `Buncombe County Commissioner District ${dist}`,
      geomStr: JSON.stringify(feature.geometry),
      geom: feature.geometry,
      pop: Number(feature.properties['PL20AA_TOT'] ?? -1),
    });
  }

  if (distMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${distMap.size}. Aborting.`);
    process.exit(1);
  }
  const sorted = [...distMap.entries()].sort((a, b) => a[0] - b[0]);
  console.log(`  Parsed districts: ${sorted.map(([d]) => d).join(', ')}`);

  // ─── Gate 1: attribute tripwire ────────────────────────────────────────────
  console.log('\n  Population tripwire (county-published 2020 PL94-171 totals):');
  let popFailures = 0;
  for (const [dist, v] of sorted) {
    const want = DISTRICT_SPEC[dist].pop;
    const ok = v.pop === want;
    if (!ok) popFailures++;
    console.log(`    ${ok ? 'PASS' : 'FAIL'}  D${dist}: expected ${want}, got ${v.pop}`);
  }
  if (popFailures > 0) {
    console.error(
      `\nERROR: ${popFailures} population mismatch(es). The layer's contents changed — ` +
        `re-verify against the county before loading, and re-measure the coupling.`,
    );
    await pool.end();
    process.exit(1);
  }

  // ─── Gate 2: positive control against the loaded TIGER House polygons ──────
  console.log('\n  Positive control (expectations measured against loaded TIGER G5220, not this layer):');
  let controlFailures = 0;
  for (const cp of CONTROL_POINTS) {
    const found = sorted.filter(([, v]) => pointInGeometry(v.geom, cp.lon, cp.lat)).map(([d]) => d);
    const ok = found.length === 1 && found[0] === cp.district;
    if (!ok) controlFailures++;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  ${cp.name}: expected D${cp.district}, got ${found.length ? found.map((d) => 'D' + d).join('+') : 'none'}`,
    );
  }
  if (controlFailures > 0) {
    console.error(`\nERROR: ${controlFailures} control point(s) failed. Refusing to write.`);
    await pool.end();
    process.exit(1);
  }

  // ─── Gate 3: THE COUPLING GATE. Runs pre-insert, so --dry-run exercises it ──
  console.log(`\n  Coupling gate — each district vs its NC House twin (need IoU >= ${MIN_IOU_PCT}%):`);
  let couplingFailures = 0;
  for (const [dist, v] of sorted) {
    const { houseGeoId } = DISTRICT_SPEC[dist];
    const res = await pool.query(
      `WITH bc AS (
         SELECT public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1), 4326)) g
       ), hd AS (
         SELECT geometry g FROM essentials.geofence_boundaries
          WHERE geo_id = $2 AND mtfcc = 'G5220' AND state = '37'
       )
       SELECT (100.0 * public.ST_Area(public.ST_Intersection(bc.g, hd.g)::geography)
                     / public.ST_Area(public.ST_Union(bc.g, hd.g)::geography))::numeric(8,3) AS iou
         FROM bc, hd`,
      [v.geomStr, houseGeoId],
    );
    const iou = res.rows.length ? Number((res.rows[0] as { iou: string }).iou) : NaN;
    if (!res.rows.length) {
      couplingFailures++;
      console.log(`    FAIL  D${dist} vs NC House ${houseGeoId}: house polygon NOT LOADED — run wave 1's sldl load first`);
      continue;
    }
    const ok = iou >= MIN_IOU_PCT;
    if (!ok) couplingFailures++;
    console.log(`    ${ok ? 'PASS' : 'FAIL'}  D${dist} vs NC House ${houseGeoId}: IoU ${iou}%`);
  }
  if (couplingFailures > 0) {
    console.error(
      `\nERROR: the 2011 statutory coupling to NC House 114/115/116 does not hold for ` +
        `${couplingFailures} district(s). Either NC redistricted and the county's lines moved with ` +
        `it (in which case reload sldl first, then re-run), or this is the wrong layer. ` +
        `Refusing to write.`,
    );
    await pool.end();
    process.exit(1);
  }

  // ─── Gate 4: the districts must tile the county, once ──────────────────────
  const tileRes = await pool.query(
    `WITH d AS (
       SELECT public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON(gj), 4326)) g
         FROM unnest($1::text[]) AS gj
     ), u AS (SELECT public.ST_Union(g) g FROM d),
        c AS (SELECT geometry g FROM essentials.geofence_boundaries
               WHERE geo_id = $2 AND mtfcc = 'G4020')
     SELECT (public.ST_Area(public.ST_Difference(u.g, c.g)::geography) / 1e6)::numeric(10,3) AS outside_county,
            (public.ST_Area(public.ST_Difference(c.g, u.g)::geography) / 1e6)::numeric(10,3) AS county_uncovered,
            (SELECT coalesce(sum(public.ST_Area(public.ST_Intersection(x.g, y.g)::geography) / 1e6), 0)::numeric(10,3)
               FROM d x JOIN d y ON public.ST_AsBinary(x.g) < public.ST_AsBinary(y.g)
              WHERE public.ST_Intersects(x.g, y.g)) AS self_overlap
       FROM u, c`,
    [sorted.map(([, v]) => v.geomStr), COUNTY_GEO_ID],
  );
  const t = tileRes.rows[0] as Record<string, string>;
  console.log(
    `\n  Tiling vs county ${COUNTY_GEO_ID}: outside ${t.outside_county} km2, ` +
      `uncovered ${t.county_uncovered} km2, overlap ${t.self_overlap} km2 ` +
      `(tolerance ${COUNTY_FIT_TOLERANCE_SQ_KM})`,
  );
  if (
    Number(t.outside_county) > COUNTY_FIT_TOLERANCE_SQ_KM ||
    Number(t.county_uncovered) > COUNTY_FIT_TOLERANCE_SQ_KM ||
    Number(t.self_overlap) > COUNTY_FIT_TOLERANCE_SQ_KM
  ) {
    console.error(
      `ERROR: the commissioner districts do not tile Buncombe County within ` +
        `${COUNTY_FIT_TOLERANCE_SQ_KM} km2. Uncovered county means residents with no ` +
        `commissioner; overlap means two. Investigate before trusting this load.`,
    );
    await pool.end();
    process.exit(1);
  }

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — all gates passed, no database writes made.');
    await pool.end();
    process.exit(0);
  }

  // ─── Write ─────────────────────────────────────────────────────────────────
  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;
  for (const [dist, { geoId, name, geomStr }] of sorted) {
    const result = await pool.query(
      `INSERT INTO essentials.geofence_boundaries
         (id, geo_id, mtfcc, state, name, geometry, source)
       VALUES (gen_random_uuid(), $1, '${MTFCC}', '${STATE_CODE}', $2,
         public.ST_Multi(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)), $4)
       ON CONFLICT (geo_id, mtfcc) DO NOTHING
       RETURNING public.ST_GeometryType(geometry) AS gtype, public.ST_IsValid(geometry) AS valid`,
      [geoId, name, geomStr, SOURCE],
    );

    if ((result.rowCount ?? 0) === 0) {
      alreadyExists++;
      console.log(`  District ${dist} (${geoId}): skipped (already exists)`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean };
    if (row.valid !== true) {
      console.error(`  District ${dist} (${geoId}): ST_IsValid=false — applying ST_MakeValid`);
      await pool.query(
        `UPDATE essentials.geofence_boundaries
           SET geometry = public.ST_Multi(public.ST_MakeValid(
             public.ST_SetSRID(public.ST_GeomFromGeoJSON($2), 4326)))
         WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId, geomStr],
      );
      const recheck = await pool.query(
        `SELECT public.ST_IsValid(geometry) AS valid
           FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
        [geoId],
      );
      if ((recheck.rows[0] as { valid: boolean })?.valid !== true) {
        console.error(`  ERROR: District ${dist} still invalid after ST_MakeValid. Aborting.`);
        await pool.end();
        process.exit(1);
      }
      repaired++;
      console.log(`  District ${dist} (${geoId}): repaired via ST_MakeValid`);
    } else {
      console.log(`  District ${dist} (${geoId}): inserted (${row.gtype}, valid)`);
    }
    inserted++;
  }

  console.log(`\n=== Summary ===`);
  console.log(`  Inserted:        ${inserted}`);
  console.log(`  Already existed: ${alreadyExists}`);
  console.log(`  Repaired:        ${repaired}`);

  const check = await pool.query(
    `SELECT COUNT(*)::int AS n,
            COUNT(*) FILTER (WHERE NOT public.ST_IsValid(geometry))::int AS invalid
       FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`,
  );
  const { n, invalid } = check.rows[0] as { n: number; invalid: number };
  console.log(`  In DB now:       ${n} rows (${invalid} invalid)`);

  await pool.end();
  if (n !== EXPECTED_COUNT || invalid !== 0) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} valid rows, got ${n} with ${invalid} invalid.`);
    process.exit(1);
  }
  console.log(
    'OK — now run scripts/verify-buncombe-commission-coupling.sql to confirm the coupling ' +
      'from the database side.',
  );
}

main().catch((err) => {
  console.error('[load-buncombe-commissioner-boundaries] Fatal error:', err);
  process.exit(1);
});
