/**
 * load-manatee-commission-boundaries.ts
 *
 * Fetches the 5 single-member County Commission district boundaries for Manatee
 * County, FL and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='manatee-fl-commissioner-district-1'..'-5',
 *                                   mtfcc='X0037', state='fl'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0010 creates the district
 * rows, the government, the chambers, the offices and the people; it refuses to
 * run if these 5 boundaries are absent.
 *
 * Wave FL-3 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Plan:   docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md
 * Slice:  .planning/knight-foundation/fl.md
 * Roster: data/seed-bradenton-manatee-2026/ROSTERS.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE BOARD HAS SEVEN MEMBERS AND THIS LOADS FIVE POLYGONS.
 *
 * Districts 1-5 are single-member. Districts 6 and 7 are elected COUNTYWIDE and
 * therefore have no polygon of their own -- their offices hang off the EXISTING
 * COUNTY district for TIGER county 12081. Five polygons for a seven-member board
 * is correct, not a shortfall. The at-large seats are numbered 6 and 7 by the
 * Supervisor of Elections; the county's own board page labels both rows merely
 * "At Large District", with no number, so the numbering comes from the SOE alone.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 FOUR SERVICES CLAIM TO BE THIS LAYER. THEY ARE ALL THE SAME BOUNDARY.
 *
 * Manatee's ArcGIS org publishes BCC_DISTRICTS_LEGAL, BoCC_Districts,
 * CountyCommissionDistricts_CopyFeatures and District_Boundaries (layer 16, not
 * 0), with identical field schemas and THREE different vintages of the COMMNAME
 * field. Measured 2026-08-28, both reprojected to 4326: the symmetric difference
 * between LEGAL and BoCC_Districts is 0.000 sq mi for all five districts.
 *
 * So the choice cannot change an answer, and the other three become free
 * independent controls. This loader reads LEGAL (current names, adopted-plan
 * naming) and CROSS-CHECKS against BoCC_Districts, which is published in a
 * DIFFERENT spatial reference -- 2237, State Plane Florida West feet, against
 * LEGAL's 3857 -- so the cross-check also proves the reprojection.
 *
 * ⚠ NEVER READ A ROSTER OUT OF THIS LAYER. Three of the four services carry
 * COMMNAME values one or two boards out of date (Van Ostenbridge, Satcher, Baugh
 * and Turner have all left office), and even LEGAL still names Carol Ann Felts in
 * District 1, which is VACANT. Same lesson as Miami-Dade's stale REPNAME field in
 * fl.md: a county attribute table can be stale while its geometry is right.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 outSR=4326 IS LOAD-BEARING. This service's native SR is 3857. Dropping
 * outSR writes projected metres into a geographic column; no row count and no
 * NOT NULL catches it, and every address probe simply comes back empty.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const LEGAL_URL =
  'https://services1.arcgis.com/t03WDvnSR7gSDOB2/arcgis/rest/services/' +
  'BCC_DISTRICTS_LEGAL/FeatureServer/0/query' +
  '?where=1%3D1&outFields=COMMDIST' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

/** Independent digitization, native SR 2237. Used only as a cross-check. */
const CROSSCHECK_URL =
  'https://services1.arcgis.com/t03WDvnSR7gSDOB2/arcgis/rest/services/' +
  'BoCC_Districts/FeatureServer/0/query' +
  '?where=1%3D1&outFields=COMMDIST' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0037';
const STATE_CODE = 'fl';
const SOURCE = 'manateegis-arcgis-BCC_DISTRICTS_LEGAL-0-2026-08-28';
const GEO_ID_PREFIX = 'manatee-fl-commissioner-district-';
const COUNTY_GEO_ID = '12081';
const EXPECTED_COUNT = 5;

/**
 * Measured 2026-08-28 against LEGAL, reprojected to 4326 and measured
 * geodesically. COMMDIST is an INTEGER in this service, unlike Bradenton's TEXT
 * WARD field.
 */
const EXPECTED_SQ_MI: Record<number, number> = { 1: 586.09, 2: 35.93, 3: 216.99, 4: 41.33, 5: 83.69 };

/**
 * Self-consistency controls, measured 2026-08-28. All three agreed on all four
 * answers of the wave's acceptance probe (Ward 3, Commission District 3, HD-71,
 * SD-20), and all four of the county's services agreed with each other on them.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: number }> = [
  { name: 'Bradenton City Hall (101 12th St W)', lon: -82.5733305, lat: 27.5000582, district: 3 },
  { name: 'Manatee County BOCC building (1112 Manatee Ave W)', lon: -82.5728299, lat: 27.4954786, district: 3 },
  { name: 'TIGER place 1207950 interior point', lon: -82.5768045, lat: 27.4897985, district: 3 },
];

/**
 * 🔴 THE CONTROL OF THE CONTROL. Sarasota City Hall is in Sarasota County,
 * immediately south of Manatee. It must fall in NO commission district.
 *
 * Verified 2026-08-28 that this point returns no district from the live service,
 * so the control is known to be a real test rather than a hopeful one. Palmetto
 * City Hall would NOT work here: it is in Manatee County and correctly returns
 * District 2.
 */
const NEGATIVE_CONTROL = { name: 'Sarasota City Hall (1565 1st St)', lon: -82.5393411, lat: 27.3373183 };

/**
 * 🔴 A TOLERANCE, NOT ST_Equals. Two digitizations of one boundary are never
 * bit-identical, so an equality test on geometry is a guaranteed false alarm.
 *
 * Measured 2026-08-28: LEGAL against BoCC_Districts is 0.000 sq mi per district;
 * the five districts against TIGER county 12081 leave 0.046 sq mi of county
 * uncovered and overhang it by 0.047 sq mi. 0.25 sq mi is 5x the worst of those
 * and 143x smaller than the SMALLEST district (District 2, 35.93 sq mi), so a
 * genuinely missing or duplicated district cannot hide underneath it.
 */
const TOLERANCE_SQ_MI = 0.25;

/** Per-district area tolerance, per cent. Measured differences were 0.00%. */
const AREA_TOLERANCE_PCT = 1;

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

async function fetchDistricts(url: string, label: string): Promise<Map<number, any>> {
  const response = (await (await fetch(url)).json()) as { features?: Feature[] };
  if (!response?.features?.length) {
    console.error(`ERROR: no features returned from ${label}. Check the URL.`);
    await pool.end();
    process.exit(1);
  }
  const out = new Map<number, any>();
  for (const feature of response.features) {
    const dist = Number(feature.properties['COMMDIST']);
    if (!Number.isInteger(dist) || dist < 1 || dist > EXPECTED_COUNT) {
      console.warn(`  WARNING (${label}): COMMDIST '${feature.properties['COMMDIST']}' out of range — skipping`);
      continue;
    }
    if (!feature.geometry) {
      console.warn(`  WARNING (${label}): district ${dist} has no geometry — skipping`);
      continue;
    }
    if (out.has(dist)) {
      console.error(`ERROR (${label}): district ${dist} appeared twice. Aborting rather than guessing.`);
      await pool.end();
      process.exit(1);
    }
    out.set(dist, feature.geometry);
  }
  return out;
}

async function main() {
  console.log('[load-manatee-commission-boundaries] Fetching Manatee County commission districts');
  if (DRY_RUN) console.log('  DRY RUN — no DB writes (every gate below still runs for real)');

  const legal = await fetchDistricts(LEGAL_URL, 'BCC_DISTRICTS_LEGAL');
  console.log(`  Received ${legal.size} features from BCC_DISTRICTS_LEGAL`);

  if (legal.size !== EXPECTED_COUNT) {
    console.error(`ERROR: expected ${EXPECTED_COUNT} districts, got ${legal.size}. Aborting.`);
    await pool.end();
    process.exit(1);
  }
  const missing = Array.from({ length: EXPECTED_COUNT }, (_, i) => i + 1).filter((n) => !legal.has(n));
  if (missing.length) {
    console.error(`ERROR: districts ${missing.join(', ')} are absent. Aborting.`);
    await pool.end();
    process.exit(1);
  }
  const sorted = [...legal.entries()].sort((a, b) => a[0] - b[0]);
  console.log(`  Parsed districts 1..${EXPECTED_COUNT}, none missing, none duplicated`);

  // ─── Gate 1: self-consistency controls ─────────────────────────────────────
  console.log('\n  Control points (self-consistency):');
  let controlFailures = 0;
  for (const cp of CONTROL_POINTS) {
    const found = sorted.filter(([, g]) => pointInGeometry(g, cp.lon, cp.lat)).map(([d]) => d);
    const ok = found.length === 1 && found[0] === cp.district;
    if (!ok) controlFailures++;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  ${cp.name}: expected D${cp.district}, got ${
        found.length ? found.map((d) => 'D' + d).join('+') : 'none'
      }`,
    );
  }

  // ─── Gate 2: the control of the control ────────────────────────────────────
  const outside = sorted.filter(([, g]) =>
    pointInGeometry(g, NEGATIVE_CONTROL.lon, NEGATIVE_CONTROL.lat),
  );
  const negOk = outside.length === 0;
  if (!negOk) controlFailures++;
  console.log(
    `    ${negOk ? 'PASS' : 'FAIL'}  ${NEGATIVE_CONTROL.name}: expected no district, got ${
      outside.length ? outside.map(([d]) => 'D' + d).join('+') : 'none'
    }`,
  );
  if (controlFailures > 0) {
    console.error(`\nERROR: ${controlFailures} control(s) failed. Refusing to write.`);
    await pool.end();
    process.exit(1);
  }

  // ─── Gate 3: per-district area, against the 2026-08-28 measurement ─────────
  console.log('\n  Per-district areas (vs the 2026-08-28 measurement):');
  for (const [dist, geom] of sorted) {
    const { rows: [a] } = await pool.query(
      `SELECT public.ST_Area(public.ST_MakeValid(
                public.ST_SetSRID(public.ST_GeomFromGeoJSON($1::text), 4326))::geography) / $2 AS sq_mi`,
      [JSON.stringify(geom), SQ_M_PER_SQ_MI],
    );
    const got = Number(a.sq_mi);
    const want = EXPECTED_SQ_MI[dist];
    const pct = (Math.abs(got - want) / want) * 100;
    const ok = pct <= AREA_TOLERANCE_PCT;
    console.log(
      `    ${ok ? 'PASS' : 'FAIL'}  District ${dist}: ${got.toFixed(2)} sq mi ` +
        `(expected ${want.toFixed(2)}, ${pct.toFixed(2)}% apart)`,
    );
    if (!ok) {
      console.error(
        `ERROR: district ${dist} is ${pct.toFixed(2)}% off its 2026-08-28 measurement.\n` +
          'Either the layer was re-digitized, the board redrew the districts, or outSR was ' +
          'dropped. Re-measure deliberately and update EXPECTED_SQ_MI in the same commit, with ' +
          'the reason.',
      );
      await pool.end();
      process.exit(1);
    }
  }

  // ─── Gate 4: cross-check against a second, independently-projected service ──
  console.log('\n  Cross-check vs BoCC_Districts (independent digitization, native SR 2237):');
  const cross = await fetchDistricts(CROSSCHECK_URL, 'BoCC_Districts');
  for (const [dist, geom] of sorted) {
    const other = cross.get(dist);
    if (!other) {
      console.error(`ERROR: the cross-check service has no district ${dist}.`);
      await pool.end();
      process.exit(1);
    }
    const { rows: [d] } = await pool.query(
      `SELECT public.ST_Area(public.ST_SymDifference(
                public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1::text), 4326)),
                public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($2::text), 4326))
              )::geography) / $3 AS symdiff_sq_mi`,
      [JSON.stringify(geom), JSON.stringify(other), SQ_M_PER_SQ_MI],
    );
    const sym = Number(d.symdiff_sq_mi);
    const ok = sym <= TOLERANCE_SQ_MI;
    console.log(`    ${ok ? 'PASS' : 'FAIL'}  District ${dist}: symmetric difference ${sym.toFixed(3)} sq mi`);
    if (!ok) {
      console.error(
        `ERROR: the two services disagree on district ${dist} by ${sym.toFixed(3)} sq mi.\n` +
          'They agreed exactly on 2026-08-28. One of them has been updated. Settle which is the ' +
          'adopted plan, from the county, before loading either.',
      );
      await pool.end();
      process.exit(1);
    }
  }

  // ─── Gate 5: the districts must tile Manatee County, once ──────────────────
  const tileRes = await pool.query(
    `WITH d AS (
       SELECT public.ST_Multi(public.ST_MakeValid(
                public.ST_SetSRID(public.ST_GeomFromGeoJSON(gj), 4326))) g
         FROM unnest($1::text[]) AS gj
     ), u AS (SELECT public.ST_UnaryUnion(public.ST_Collect(g)) g FROM d),
        c AS (SELECT geometry g FROM essentials.geofence_boundaries
               WHERE geo_id = $2 AND mtfcc = 'G4020')
     SELECT (public.ST_Area(public.ST_Difference(c.g, u.g)::geography) / $3)::numeric(12,3) AS county_uncovered,
            (public.ST_Area(public.ST_Difference(u.g, c.g)::geography) / $3)::numeric(12,3) AS overhang,
            (SELECT coalesce(sum(public.ST_Area(public.ST_Intersection(x.g, y.g)::geography) / $3), 0)::numeric(12,4)
               FROM d x JOIN d y ON public.ST_AsBinary(x.g) < public.ST_AsBinary(y.g)
              WHERE public.ST_Intersects(x.g, y.g)) AS self_overlap
       FROM u, c`,
    [sorted.map(([, g]) => JSON.stringify(g)), COUNTY_GEO_ID, SQ_M_PER_SQ_MI],
  );
  if (!tileRes.rows.length) {
    console.error(
      `ERROR: TIGER county polygon ${COUNTY_GEO_ID}/G4020 is not loaded. Refusing to write — ` +
        `CC_0010 hangs the two at-large seats and all five constitutional officers off it.`,
    );
    await pool.end();
    process.exit(1);
  }
  const t = tileRes.rows[0] as Record<string, string>;
  console.log(
    `\n  Tiling vs TIGER county ${COUNTY_GEO_ID}: ${t.county_uncovered} sq mi of county in no ` +
      `district, ${t.overhang} sq mi overhang, ${t.self_overlap} sq mi self-overlap ` +
      `(tolerance ${TOLERANCE_SQ_MI})`,
  );
  if (
    Number(t.county_uncovered) > TOLERANCE_SQ_MI ||
    Number(t.overhang) > TOLERANCE_SQ_MI ||
    Number(t.self_overlap) > TOLERANCE_SQ_MI
  ) {
    console.error(
      `ERROR: the 5 districts do not tile Manatee County within ${TOLERANCE_SQ_MI} sq mi. ` +
        `Measured 0.046 uncovered / 0.047 overhang / 0.000 overlap on 2026-08-28. Uncovered ` +
        `county means residents with NO county commissioner and nothing errors; overlap means two.`,
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
  for (const [dist, geom] of sorted) {
    const geoId = `${GEO_ID_PREFIX}${dist}`;
    const name = `Manatee County Commissioner District ${dist}`;
    const geomStr = JSON.stringify(geom);
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
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
