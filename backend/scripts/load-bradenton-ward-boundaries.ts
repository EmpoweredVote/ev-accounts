/**
 * load-bradenton-ward-boundaries.ts
 *
 * Fetches the 5 City Council ward boundaries for Bradenton, FL and inserts them
 * into:
 *
 *   essentials.geofence_boundaries  geo_id='bradenton-fl-council-ward-1'..'-5',
 *                                   mtfcc='X0036', state='fl'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0008 creates the district
 * rows, the government, the chambers and the offices; it refuses to run if these
 * 5 boundaries are absent.
 *
 * Wave FL-3 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Plan:   docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md
 * Slice:  .planning/knight-foundation/fl.md
 * Roster: data/seed-bradenton-manatee-2026/ROSTERS.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE TILING GATE IS AGAINST TIGER's AREALAND, NOT AGAINST THE PLACE POLYGON.
 *
 * The ward layer is LAND ONLY. Measured 2026-08-28: the ward union is 14.397 sq
 * mi, TIGER place 1207950 is 17.505 sq mi, and 3.211 sq mi of the place falls in
 * no ward at all. That gap is the Manatee River, not unassigned neighbourhoods --
 * TIGERweb's own attributes for 1207950 are AREALAND 37,152,499 m2 (14.344 sq mi)
 * and AREAWATER 8,185,647 m2 (3.160 sq mi). The ward union matches AREALAND to
 * 0.37%.
 *
 * So a gate demanding that the wards tile the place polygon FAILS ON A CORRECT
 * LAYER, and a red build on correct data is how a gate gets muted. This one
 * compares the ward union to AREALAND, with a 3% tolerance.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 outSR=4326 IS LOAD-BEARING. Dropping it writes projected metres into a
 * geographic column. No row count and no NOT NULL catches it; the polygons just
 * sit in the wrong hemisphere and every address probe comes back empty.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ WARD IS TEXT, AND WARD 4 HAS 36 PARTS. The WARD field is '1'..'5' as
 * strings, not integers -- a `=== 1` comparison silently matches nothing. And
 * the geometries are MultiPolygons following annexation slivers (W1 15 parts,
 * W2 10, W3 3, W4 36, W5 14), so any single-ring assumption drops most of the
 * city.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ ON THE CONTROL POINTS. There is no second digitization of Bradenton's wards
 * anywhere -- the city publishes one layer and nobody else publishes any. So the
 * three positive controls are SELF-CONSISTENCY checks: each point must fall in
 * exactly one ward, and in the ward this same layer reported on 2026-08-28. They
 * would not catch a wholesale re-digitization.
 *
 * The two gates that ARE independent follow them: Palmetto City Hall must fall
 * in no ward, and the ward union must match TIGER's AREALAND, which is a
 * different agency's measurement of the same city.
 */

/*
 * ⚠ MEASURED ON THE REAL LOAD, 2026-08-28: FOUR OF THE FIVE SOURCE POLYGONS FAIL
 * ST_IsValid. Wards 1, 2, 4 and 5 all needed ST_MakeValid; only Ward 3 landed
 * clean. That is what the annexation slivers cost -- W4 has 36 parts.
 *
 * The repair path is therefore LOAD-BEARING here, not a formality, and its
 * output must be checked from the DATABASE rather than from the fetched GeoJSON:
 * every gate above runs on the pre-repair geometry, so none of them can see what
 * ST_MakeValid did. Verified after the load: the five stored areas are 3.813 /
 * 2.454 / 1.735 / 3.398 / 2.996 sq mi, which match the layer's own ACRES field
 * to three decimals, the union is still 14.397 sq mi (0.364% from AREALAND),
 * self-overlap is 0.0000 sq mi, and exactly one ward still covers city hall.
 * So the repair changed nothing material.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const WARDS_URL =
  'https://services6.arcgis.com/wl0q8tN2gn8MMx1p/arcgis/rest/services/' +
  'WardsCityCouncil_CoB/FeatureServer/0/query' +
  '?where=1%3D1&outFields=WARD' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0036';
const STATE_CODE = 'fl';
const SOURCE = 'cityofbradenton-arcgis-WardsCityCouncil_CoB-0-2026-08-28';
const GEO_ID_PREFIX = 'bradenton-fl-council-ward-';
const PLACE_GEO_ID = '1207950';
/** TIGERweb 2024 AREALAND for place 1207950, in square metres. Read 2026-08-28. */
const PLACE_ALAND_SQM = 37_152_499;
const EXPECTED_COUNT = 5;

/**
 * Self-consistency controls, measured against this layer on 2026-08-28. City
 * hall is the anchor the whole wave is judged on, and all three of these agreed
 * on all four answers (Ward 3, Commission District 3, HD-71, SD-20).
 *
 * ⚠ City hall's published address is "101 Old Main Street", which the CENSUS
 * GEOCODER DOES NOT RESOLVE -- 0 matches. Old Main Street is the ceremonial name
 * for 12th Street West. Any probe must use the address that geocodes.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; ward: string }> = [
  { name: 'Bradenton City Hall (101 12th St W, a.k.a. 101 Old Main St)', lon: -82.5733305, lat: 27.5000582, ward: '3' },
  { name: 'Manatee County BOCC building (1112 Manatee Ave W)', lon: -82.5728299, lat: 27.4954786, ward: '3' },
  { name: 'TIGER place 1207950 interior point', lon: -82.5768045, lat: 27.4897985, ward: '3' },
];

/**
 * 🔴 THE CONTROL OF THE CONTROL. Palmetto City Hall is across the Manatee River
 * in a different municipality -- but still inside Manatee County, which makes it
 * a sharper control than an out-of-county point: it separates "in Bradenton" from
 * "near Bradenton". It must fall in NO Bradenton ward.
 *
 * Without a negative control, a query that cannot fire at all still passes every
 * positive control, because a geometry test that never runs returns "not found"
 * for the negative case and nobody reads the negative case.
 */
const NEGATIVE_CONTROL = { name: 'Palmetto City Hall (516 8th Ave W)', lon: -82.5728926, lat: 27.5153915 };

/**
 * The wards must not overlap each other. Measured on the 2026-08-28 dry run the
 * self-overlap is reported below; 0.05 sq mi is the tolerance -- 22x smaller than
 * the smallest ward (Ward 3, 1110 acres = 1.735 sq mi), so a duplicated ward
 * cannot hide underneath it.
 */
const SELF_OVERLAP_TOLERANCE_SQ_MI = 0.05;

/** AREALAND tolerance, per cent. Measured 0.37% on 2026-08-28. */
const ALAND_TOLERANCE_PCT = 3;

const SQ_M_PER_SQ_MI = 2_589_988.11;

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
  console.log('[load-bradenton-ward-boundaries] Fetching Bradenton City Council wards');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes (every gate below still runs for real)');

  const response = (await (await fetch(WARDS_URL)).json()) as { features?: Feature[] };
  if (!response?.features?.length) {
    console.error('ERROR: No features returned from the City of Bradenton FeatureServer. Check the URL.');
    process.exit(1);
  }
  console.log(`  Received ${response.features.length} features`);

  const wardMap = new Map<string, { geoId: string; name: string; geomStr: string; geom: any; parts: number }>();
  for (const feature of response.features) {
    // ⚠ WARD is TEXT. Normalise, do not parseInt-and-compare.
    const ward = String(feature.properties['WARD'] ?? '').trim();
    if (!/^[1-5]$/.test(ward)) {
      console.warn(`  WARNING: WARD '${ward}' out of range — skipping`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING: ward ${ward} has no geometry — skipping`);
      continue;
    }
    if (wardMap.has(ward)) {
      console.error(`ERROR: ward ${ward} appeared twice. Aborting rather than guessing.`);
      process.exit(1);
    }
    const parts = feature.geometry.type === 'MultiPolygon' ? feature.geometry.coordinates.length : 1;
    wardMap.set(ward, {
      geoId: `${GEO_ID_PREFIX}${ward}`,
      name: `Bradenton City Council Ward ${ward}`,
      geomStr: JSON.stringify(feature.geometry),
      geom: feature.geometry,
      parts,
    });
  }

  if (wardMap.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} wards, got ${wardMap.size}. Aborting.`);
    process.exit(1);
  }
  const missing = ['1', '2', '3', '4', '5'].filter((w) => !wardMap.has(w));
  if (missing.length) {
    console.error(`ERROR: wards ${missing.join(', ')} are absent. Aborting.`);
    process.exit(1);
  }
  const sorted = [...wardMap.entries()].sort((a, b) => Number(a[0]) - Number(b[0]));
  console.log(
    `  Parsed wards 1..5, none missing, none duplicated ` +
      `(parts: ${sorted.map(([w, v]) => `W${w}=${v.parts}`).join(' ')})`,
  );

  // ─── Gate 1: self-consistency controls ─────────────────────────────────────
  console.log('\n  Control points (self-consistency; city hall is the wave anchor):');
  let controlFailures = 0;
  for (const cp of CONTROL_POINTS) {
    const found = sorted.filter(([, v]) => pointInGeometry(v.geom, cp.lon, cp.lat)).map(([w]) => w);
    const ok = found.length === 1 && found[0] === cp.ward;
    if (!ok) controlFailures++;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  ${cp.name}: expected W${cp.ward}, got ${
        found.length ? found.map((w) => 'W' + w).join('+') : 'none'
      }`,
    );
  }

  // ─── Gate 2: the control of the control ────────────────────────────────────
  const outside = sorted.filter(([, v]) =>
    pointInGeometry(v.geom, NEGATIVE_CONTROL.lon, NEGATIVE_CONTROL.lat),
  );
  const negOk = outside.length === 0;
  if (!negOk) controlFailures++;
  console.log(
    `    ${negOk ? 'PASS' : 'FAIL'}  ${NEGATIVE_CONTROL.name}: expected no ward, got ${
      outside.length ? outside.map(([w]) => 'W' + w).join('+') : 'none'
    }`,
  );
  if (controlFailures > 0) {
    console.error(`\nERROR: ${controlFailures} control(s) failed. Refusing to write.`);
    await pool.end();
    process.exit(1);
  }

  // ─── Gate 3: the ward union must match TIGER's AREALAND, and not self-overlap ──
  const tileRes = await pool.query(
    `WITH d AS (
       SELECT public.ST_Multi(public.ST_MakeValid(
                public.ST_SetSRID(public.ST_GeomFromGeoJSON(gj), 4326))) g
         FROM unnest($1::text[]) AS gj
     ), u AS (SELECT public.ST_UnaryUnion(public.ST_Collect(g)) g FROM d)
     SELECT (public.ST_Area(u.g::geography) / $2)::numeric(12,3)              AS union_sq_mi,
            (abs(public.ST_Area(u.g::geography) - $3::numeric)
               / $3::numeric * 100)::numeric(12,3)                           AS aland_pct_diff,
            (SELECT coalesce(sum(public.ST_Area(public.ST_Intersection(x.g, y.g)::geography) / $2), 0)::numeric(12,3)
               FROM d x JOIN d y ON public.ST_AsBinary(x.g) < public.ST_AsBinary(y.g)
              WHERE public.ST_Intersects(x.g, y.g))                          AS self_overlap_sq_mi
       FROM u`,
    [sorted.map(([, v]) => v.geomStr), SQ_M_PER_SQ_MI, PLACE_ALAND_SQM],
  );
  const t = tileRes.rows[0] as Record<string, string>;
  console.log(
    `\n  Tiling gate: ward union ${t.union_sq_mi} sq mi vs TIGER AREALAND ` +
      `${(PLACE_ALAND_SQM / SQ_M_PER_SQ_MI).toFixed(3)} sq mi ` +
      `(${t.aland_pct_diff}% apart, tolerance ${ALAND_TOLERANCE_PCT}%); ` +
      `self-overlap ${t.self_overlap_sq_mi} sq mi (tolerance ${SELF_OVERLAP_TOLERANCE_SQ_MI})`,
  );
  if (Number(t.aland_pct_diff) > ALAND_TOLERANCE_PCT) {
    console.error(
      `ERROR: the ward union differs from TIGER AREALAND by ${t.aland_pct_diff}%, over the ` +
        `${ALAND_TOLERANCE_PCT}% tolerance. Measured 0.37% on 2026-08-28. A jump here means the ` +
        `layer was re-digitized, the city annexed, or outSR was dropped. Do NOT widen this ` +
        `tolerance to get green.`,
    );
    await pool.end();
    process.exit(1);
  }
  if (Number(t.self_overlap_sq_mi) > SELF_OVERLAP_TOLERANCE_SQ_MI) {
    console.error(
      `ERROR: the wards overlap each other by ${t.self_overlap_sq_mi} sq mi. Overlap means an ` +
        `address returns two council members.`,
    );
    await pool.end();
    process.exit(1);
  }

  // ─── Gate 4: the place polygon FL-1 loaded must exist ──────────────────────
  const placeRes = await pool.query(
    `SELECT public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint($2, $3), 4326)) AS covers
       FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = 'G4110'`,
    [PLACE_GEO_ID, CONTROL_POINTS[0].lon, CONTROL_POINTS[0].lat],
  );
  if (!placeRes.rows.length) {
    console.error(
      `ERROR: TIGER place ${PLACE_GEO_ID}/G4110 is not loaded. FL-1 must be applied first — ` +
        `CC_0008 hangs the Mayor's citywide district off it.`,
    );
    await pool.end();
    process.exit(1);
  }
  if ((placeRes.rows[0] as { covers: boolean }).covers !== true) {
    console.error(
      `ERROR: TIGER place ${PLACE_GEO_ID}/G4110 does not cover Bradenton City Hall. The place ` +
        `polygon in prod is not Bradenton.`,
    );
    await pool.end();
    process.exit(1);
  }
  console.log(`  TIGER place ${PLACE_GEO_ID}/G4110 present and covers city hall`);

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete — all gates passed, no database writes made.');
    await pool.end();
    process.exit(0);
  }

  // ─── Write ─────────────────────────────────────────────────────────────────
  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;
  for (const [ward, { geoId, name, geomStr }] of sorted) {
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
      console.log(`  Ward ${ward} (${geoId}): skipped (already exists)`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean };
    if (row.valid !== true) {
      console.error(`  Ward ${ward} (${geoId}): ST_IsValid=false — applying ST_MakeValid`);
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
        console.error(`  ERROR: Ward ${ward} still invalid after ST_MakeValid. Aborting.`);
        await pool.end();
        process.exit(1);
      }
      repaired++;
      console.log(`  Ward ${ward} (${geoId}): repaired via ST_MakeValid`);
    } else {
      console.log(`  Ward ${ward} (${geoId}): inserted (${row.gtype}, valid)`);
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
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
