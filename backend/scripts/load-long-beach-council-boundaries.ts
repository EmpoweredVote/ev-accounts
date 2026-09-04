/**
 * load-long-beach-council-boundaries.ts
 *
 * Fetches the 9 single-member Council district boundaries for Long Beach, CA and
 * inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='long-beach-ca-council-district-1'..'-9',
 *                                   mtfcc='X0046', state='ca'
 *
 * Writes ONLY to essentials.geofence_boundaries. The CA-1 repair migration
 * repoints the nine EXISTING district rows onto these geo_ids; it refuses to run
 * if these nine boundaries are absent.
 *
 * Wave CA-1 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Roster: backend/data/seed-long-beach-2026/ROSTERS.md
 * Tracker: .planning/knight-foundation/PROGRAM.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THIS IS A REPAIR, NOT A SEED. THE DISTRICTS ALREADY EXISTED — ON THE WRONG
 *    POLYGON.
 *
 * All nine Long Beach council district rows carried geo_id '0643000', the TIGER
 * place polygon for the whole city. Measured 2026-09-02, the ST_PointOnSurface
 * probe that check-address-reachability.mjs runs returned NINE councilmembers
 * for one Long Beach point. Every address in the city named all nine.
 *
 * ⚠ check-address-reachability.mjs deliberately does NOT flag this. Its header
 *   records that "two districts share a geo_id" was measured and rejected as an
 *   invariant — roughly 700 rows match it legitimately — and it names Long
 *   Beach's own 0643000 as the example. The guard is right; the condition still
 *   needed a per-jurisdiction probe to surface.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 GA-4's ARBITRATION IS NOT AVAILABLE HERE, AND THAT IS A MEASURED FACT.
 *
 * GA-4 arbitrated two competing council-district layers against the county's
 * ballot-building table. Neither half exists for Long Beach:
 *
 *   ONE LAYER, NOT TWO. Three ArcGIS catalogue searches return exactly one
 *   authoritative service. The only other item with the same title is owned by
 *   `CRC.Admin` — the Citizens Redistricting Commission — and resolves to the
 *   SAME FeatureServer URL. The rest are student copies in CSULB accounts. So
 *   the GA-4 inversion (fresh roster on superseded geometry) cannot occur: there
 *   is nothing to invert against.
 *
 *   THE COUNTY PUBLISHES NO DISTRICT ATTRIBUTES. LA County's `Registrar Recorder
 *   Precincts` (Political_Boundaries/MapServer/34) declares DST_CITY and
 *   DIV_CITY — exactly the ballot-building fields GA-4 arbitrated on — and every
 *   row returns NULL for both. Layer 37 carries real precinct IDs and no
 *   district fields at all. The City Clerk's Statement of Votes, which maps
 *   precincts to contests, is a SCANNED PDF with no text layer.
 *
 * What replaces it is a CONTROL SET, and the two are not equivalent. GATE 5
 * below tests the layer against the city's own daily-updated business-licence
 * register, which stamps a COUNCIL_NUMBER on every licensed location. That
 * proves the layer is the map the city's operational systems route work by,
 * across all nine districts. It does NOT arbitrate the boundaries against an
 * outside authority, because no outside authority publishes them.
 *
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER. GATE 2 compares the layer's
 *   REPRESENTATIVE field against the roster as a VINTAGE test on the layer — a
 *   layer naming a departed member is a layer nobody maintains. The roster that
 *   reaches the database comes from the city's council pages, the City Clerk's
 *   certified results and Legistar. Never from here.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE UNCOVERED GROUND IS WATER, AND THAT IS CHECKED, NOT ASSUMED.
 *
 * The nine districts union to 53.06 sq mi. The TIGER place polygon is 77.85.
 * The 24.83 sq mi difference would be alarming if it were land. TIGERweb reports
 * GEOID 0643000 as 50.67 sq mi of LAND and 27.18 of WATER, so the districts
 * cover every acre of land plus about 2.4 sq mi of harbour, and the gap fits
 * inside the water. GATE 6 asserts union >= land area rather than trusting the
 * shape of the number.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * Usage:
 *   npx tsx scripts/load-long-beach-council-boundaries.ts --dry-run
 *   npx tsx scripts/load-long-beach-council-boundaries.ts
 */
import 'dotenv/config';
import { Pool } from 'pg';

const SERVICE =
  'https://services6.arcgis.com/yCArG7wGXGyWLqav/arcgis/rest/services/City_of_Long_Beach_Council_Districts/FeatureServer';

/** outSR=4326 is load-bearing. */
const PRIMARY_URL =
  `${SERVICE}/0/query?where=1%3D1&outFields=COUNCIL_NUMBER,REPRESENTATIVE&returnGeometry=true&outSR=4326&f=geojson`;

const BIZ_SERVICE =
  'https://services6.arcgis.com/yCArG7wGXGyWLqav/arcgis/rest/services/Business_Licenses_Public_View/FeatureServer/0';

const MTFCC = 'X0046';
const STATE_CODE = 'ca';
const SOURCE = 'clb-arcgis-City_of_Long_Beach_Council_Districts-2026-09-02 (Knight CA-1)';
const GEO_ID_PREFIX = 'long-beach-ca-council-district-';

/** The citywide seats (Mayor, City Attorney, City Auditor, City Prosecutor) stay on this. */
const PLACE_GEO_ID = '0643000';
const PLACE_MTFCC = 'G4110';

const EXPECTED_COUNT = 9;
const DISTRICTS = ['1', '2', '3', '4', '5', '6', '7', '8', '9'] as const;
const DISTRICT_KEY_RE = /^[1-9]$/;

/** Measured 2026-09-02 against the fetched layer, geodesic. */
const EXPECTED_SQ_MI: Record<string, number> = {
  '1': 5.0029,
  '2': 2.2316,
  '3': 6.5953,
  '4': 9.781,
  '5': 10.2519,
  '6': 2.5619,
  '7': 7.9146,
  '8': 4.3517,
  '9': 4.3702,
};

/**
 * The layer's own REPRESENTATIVE field, upper-cased, as of 2026-09-02. A VINTAGE
 * test on the layer only — see the header. Tunua Thrash-Ntuk took District 8 on
 * 2024-12-17, so a layer still naming Al Austin would be stale by two years.
 *
 * ⚠ Roberto Uranga is term-limited and Vivian Malauulu takes District 7 on
 *   2026-12-15. AFTER that date this gate must be updated, and its failure will
 *   be correct rather than a defect.
 */
const EXPECTED_REPRESENTATIVE: Record<string, string> = {
  '1': 'MARY ZENDEJAS',
  '2': 'CINDY ALLEN',
  '3': 'KRISTINA DUGGAN',
  '4': 'DARYL SUPERNAW',
  '5': 'MEGAN KERR',
  '6': 'SUELY SARO',
  '7': 'ROBERTO URANGA',
  '8': 'TUNUA THRASH-NTUK',
  '9': 'JONI RICKS-ODDIE',
};

const AREA_TOLERANCE_PCT = 2;

/** Union of the nine, measured 2026-09-02. */
const EXPECTED_UNION_SQ_MI = 53.0611;
const UNION_TOLERANCE_SQ_MI = 1.0;

/** TIGERweb, Places_CouSub_ConCity_SubMCD/MapServer/4, GEOID 0643000. */
const TIGER_LAND_SQ_MI = 50.67;
const TIGER_TOTAL_SQ_MI = 77.85;

/** District ground falling outside the TIGER place polygon — digitisation noise only. */
const MAX_OUTSIDE_PLACE_SQ_MI = 0.25;

/** Two districts may share an edge; they may not share ground. */
const MAX_PAIR_OVERLAP_SQ_MI = 0.001;

/** GATE 5 sample size per district. The wave ran 300/district at 100%. */
const CONTROL_PER_DISTRICT = 100;
/** Zero tolerance. A control point that lands in another district is a boundary defect. */
const MAX_CONTROL_MISMATCH = 0;

const DRY_RUN = process.argv.includes('--dry-run');

type Feature = { properties: Record<string, unknown>; geometry: unknown };

function fail(msg: string): never {
  console.error(`\nERROR: ${msg}`);
  process.exit(1);
}

const SQM_PER_SQMI = 2589988.110336;

async function fetchJson(url: string, label: string): Promise<{ features?: Feature[]; error?: unknown }> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${label}: HTTP ${res.status} ${res.statusText}`);
  const body = (await res.json()) as { features?: Feature[]; error?: unknown };
  if (body.error) throw new Error(`${label}: ArcGIS error ${JSON.stringify(body.error)}`);
  return body;
}

/** COUNCIL_NUMBER is a plain integer here, not a zero-padded string. */
const distId = (p: Record<string, unknown>): string | null => {
  const raw = p.COUNCIL_NUMBER;
  if (raw === undefined || raw === null) return null;
  const s = String(raw).trim();
  return s === '' ? null : s;
};

async function main() {
  console.log('[load-long-beach-council-boundaries] City of Long Beach, CA — 9 council districts');
  console.log(`  Layer:   ${SERVICE}/0   (CouncilDistricts)`);
  console.log(`  Control: Business_Licenses_Public_View/0   (COUNCIL_NUMBER per licensed location)`);
  console.log(`  Target:  mtfcc=${MTFCC} state=${STATE_CODE}${DRY_RUN ? '   [DRY RUN]' : ''}\n`);
  console.log('  ⚠ REPAIR, not a seed: the nine district rows already exist on the place polygon.\n');

  // ─── GATE 1: the layer is nine single polygons keyed 1..9 ──────────────────
  console.log('GATE 1 — the layer returns 9 districts, one row each');
  const body = await fetchJson(PRIMARY_URL, 'council districts');
  const feats = body.features ?? [];
  const keyed = new Map<string, Feature>();
  for (const f of feats) {
    const k = distId(f.properties ?? {});
    if (k === null || !DISTRICT_KEY_RE.test(k)) continue;
    if (!f.geometry) fail(`district ${k} has a row with no geometry`);
    if (keyed.has(k)) fail(`duplicate district key ${k} — the layer returned more than one polygon for it`);
    keyed.set(k, f);
  }
  console.log(`  Returned ${feats.length} features, ${keyed.size} keyed 1..${EXPECTED_COUNT}`);
  if (keyed.size !== EXPECTED_COUNT) fail(`expected ${EXPECTED_COUNT} districts, got ${keyed.size}.`);
  const missing = DISTRICTS.filter((d) => !keyed.has(d));
  if (missing.length) fail(`districts ${missing.join(', ')} are absent.`);
  console.log('  ✓ 9 districts, one polygon each');

  // ─── GATE 2: the layer is MAINTAINED (a vintage test, never a roster) ──────
  console.log('\nGATE 2 — the layer names the sitting councilmembers (vintage test only)');
  {
    const wrong: string[] = [];
    for (const d of DISTRICTS) {
      const got = String(keyed.get(d)!.properties.REPRESENTATIVE ?? '').trim().toUpperCase();
      const want = EXPECTED_REPRESENTATIVE[d]!;
      if (got !== want) wrong.push(`D${d}: layer says "${got}", roster says "${want}"`);
    }
    if (wrong.length) {
      fail(
        `GATE 2: the layer's roster field has drifted from the verified roster:\n    ` +
          wrong.join('\n    ') +
          `\n  Re-run the change-check in backend/data/seed-long-beach-2026/ROSTERS.md before loading. ` +
          `A layer naming someone who has left is a layer nobody maintains — and after 2026-12-15 ` +
          `District 7 legitimately becomes Vivian Malauulu, at which point this gate must be updated.`,
      );
    }
    console.log('  ✓ all 9 REPRESENTATIVE values match the verified roster');
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const geomOf = (d: string) => JSON.stringify(keyed.get(d)!.geometry);

  const geomValues = DISTRICTS.map((d, i) => `($${i * 2 + 1}::int, $${i * 2 + 2}::text)`).join(',');
  const geomParams: unknown[] = [];
  for (const d of DISTRICTS) {
    geomParams.push(Number(d), geomOf(d));
  }
  /** The nine fetched polygons, made valid, as a reusable CTE. */
  const POLY_CTE = `
    WITH src(n, gj) AS (VALUES ${geomValues}),
         g AS (SELECT n, public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON(gj), 4326)) AS geom FROM src)`;

  try {
    // ─── GATE 3: each polygon is valid and the right size ────────────────────
    console.log('\nGATE 3 — every polygon is valid, and its area matches what was measured');
    {
      const r = await pool.query<{ n: number; sq_mi: string; valid: boolean }>(
        `${POLY_CTE}
         SELECT n, (public.ST_Area(geom::geography) / ${SQM_PER_SQMI})::numeric(12,4) AS sq_mi,
                public.ST_IsValid(geom) AS valid
           FROM g ORDER BY n`,
        geomParams,
      );
      for (const row of r.rows) {
        const d = String(row.n);
        const got = Number(row.sq_mi);
        const want = EXPECTED_SQ_MI[d]!;
        const driftPct = Math.abs((got - want) / want) * 100;
        const flag = row.valid && driftPct <= AREA_TOLERANCE_PCT ? '✓' : '✗';
        console.log(`  ${flag} D${d}: ${got.toFixed(4)} sq mi (expected ${want}, drift ${driftPct.toFixed(2)}%)`);
        if (!row.valid) fail(`GATE 3: district ${d} is not a valid geometry.`);
        if (driftPct > AREA_TOLERANCE_PCT) {
          fail(
            `GATE 3: district ${d} is ${got} sq mi against an expected ${want} — ` +
              `${driftPct.toFixed(2)}% drift, over the ${AREA_TOLERANCE_PCT}% tolerance. ` +
              `The city has probably redistricted. Re-measure before loading.`,
          );
        }
      }
    }

    // ─── GATE 4: the nine do not overlap ─────────────────────────────────────
    console.log('\nGATE 4 — no two districts share ground');
    {
      const r = await pool.query<{ an: number; bn: number; sq_mi: string }>(
        `${POLY_CTE}
         SELECT a.n AS an, b.n AS bn,
                (public.ST_Area(public.ST_Intersection(a.geom, b.geom)::geography) / ${SQM_PER_SQMI})::numeric(12,6) AS sq_mi
           FROM g a JOIN g b ON a.n < b.n
          WHERE public.ST_Intersects(a.geom, b.geom)
            AND public.ST_Area(public.ST_Intersection(a.geom, b.geom)::geography) > ${MAX_PAIR_OVERLAP_SQ_MI * SQM_PER_SQMI}
          ORDER BY 3 DESC`,
        geomParams,
      );
      if (r.rowCount) {
        for (const row of r.rows) console.error(`  ✗ D${row.an} and D${row.bn} overlap by ${row.sq_mi} sq mi`);
        fail(`GATE 4: ${r.rowCount} district pair(s) overlap by more than ${MAX_PAIR_OVERLAP_SQ_MI} sq mi.`);
      }
      console.log(`  ✓ no pair overlaps by more than ${MAX_PAIR_OVERLAP_SQ_MI} sq mi`);
    }

    // ─── GATE 5: the control set ─────────────────────────────────────────────
    console.log(`\nGATE 5 — the city's business-licence register agrees, ${CONTROL_PER_DISTRICT} per district`);
    {
      const claimed: number[] = [];
      const lon: number[] = [];
      const lat: number[] = [];
      for (const d of DISTRICTS) {
        const url =
          `${BIZ_SERVICE}/query?where=COUNCIL_NUMBER%3D${d}+AND+LICSTATUS%3D%27ACTIVE%27` +
          `&outFields=COUNCIL_NUMBER&returnGeometry=true&outSR=4326` +
          `&resultRecordCount=${CONTROL_PER_DISTRICT}&resultOffset=0&f=geojson`;
        const b = await fetchJson(url, `business licences D${d}`);
        const rows = (b.features ?? []).filter((f) => f.geometry);
        if (rows.length < CONTROL_PER_DISTRICT) {
          fail(
            `GATE 5: district ${d} returned only ${rows.length} licensed locations, ` +
              `fewer than the ${CONTROL_PER_DISTRICT} the control needs. A short sample is a broken ` +
              `detector, not a pass.`,
          );
        }
        for (const f of rows) {
          const c = (f.geometry as { coordinates: [number, number] }).coordinates;
          claimed.push(Number(f.properties.COUNCIL_NUMBER));
          lon.push(c[0]);
          lat.push(c[1]);
        }
      }
      const r = await pool.query<{ claimed: number; n: string; agree: string; outside: string; wrong: string }>(
        `${POLY_CTE},
         pt AS (SELECT * FROM unnest($${DISTRICTS.length * 2 + 1}::int[], $${DISTRICTS.length * 2 + 2}::float8[], $${DISTRICTS.length * 2 + 3}::float8[]) AS t(claimed, lon, lat)),
         p AS (SELECT claimed, public.ST_SetSRID(public.ST_Point(lon, lat), 4326) AS geom FROM pt),
         m AS (SELECT p.claimed, (SELECT g.n FROM g WHERE public.ST_Covers(g.geom, p.geom) LIMIT 1) AS matched FROM p)
         SELECT claimed, count(*) AS n,
                count(*) FILTER (WHERE matched = claimed) AS agree,
                count(*) FILTER (WHERE matched IS NULL) AS outside,
                count(*) FILTER (WHERE matched IS NOT NULL AND matched <> claimed) AS wrong
           FROM m GROUP BY claimed ORDER BY claimed`,
        [...geomParams, claimed, lon, lat],
      );
      let mismatches = 0;
      for (const row of r.rows) {
        const bad = Number(row.outside) + Number(row.wrong);
        mismatches += bad;
        console.log(
          `  ${bad === 0 ? '✓' : '✗'} D${row.claimed}: ${row.agree}/${row.n} contained` +
            (bad ? `  (${row.outside} outside every district, ${row.wrong} in another)` : ''),
        );
      }
      if (r.rowCount !== EXPECTED_COUNT) {
        fail(`GATE 5: the control covered ${r.rowCount} districts, not ${EXPECTED_COUNT}. A district with no control is untested.`);
      }
      if (mismatches > MAX_CONTROL_MISMATCH) {
        fail(
          `GATE 5: ${mismatches} licensed location(s) are not inside the district the city assigns them to. ` +
            `That is a boundary defect, not a rounding question.`,
        );
      }
      console.log(`  ✓ ${claimed.length}/${claimed.length} licensed locations land in the district the city assigns them to`);
    }

    // ─── GATE 6: the union covers the land, and stays inside the city ────────
    console.log('\nGATE 6 — the union covers every acre of land and nothing beyond the city');
    {
      const r = await pool.query<{ union_sq_mi: string; outside_place: string; uncovered: string; place_sq_mi: string }>(
        `${POLY_CTE},
         u AS (SELECT public.ST_Union(geom) AS geom FROM g),
         place AS (SELECT geometry AS geom FROM essentials.geofence_boundaries
                    WHERE geo_id = '${PLACE_GEO_ID}' AND mtfcc = '${PLACE_MTFCC}')
         SELECT (public.ST_Area(u.geom::geography) / ${SQM_PER_SQMI})::numeric(12,4) AS union_sq_mi,
                (public.ST_Area(place.geom::geography) / ${SQM_PER_SQMI})::numeric(12,4) AS place_sq_mi,
                (public.ST_Area(public.ST_Difference(u.geom, place.geom)::geography) / ${SQM_PER_SQMI})::numeric(12,4) AS outside_place,
                (public.ST_Area(public.ST_Difference(place.geom, u.geom)::geography) / ${SQM_PER_SQMI})::numeric(12,4) AS uncovered
           FROM u, place`,
        geomParams,
      );
      if (!r.rowCount) fail(`GATE 6: TIGER place ${PLACE_GEO_ID}/${PLACE_MTFCC} is missing — nothing to compare against.`);
      const g = r.rows[0]!;
      const unionSqMi = Number(g.union_sq_mi);
      console.log(`  Union of the 9:            ${unionSqMi.toFixed(4)} sq mi (expected ~${EXPECTED_UNION_SQ_MI})`);
      console.log(`  TIGER place total:         ${Number(g.place_sq_mi).toFixed(4)} sq mi (TIGERweb: ${TIGER_TOTAL_SQ_MI})`);
      console.log(`  TIGER place LAND:          ${TIGER_LAND_SQ_MI} sq mi`);
      console.log(`  District ground outside:   ${Number(g.outside_place).toFixed(4)} sq mi`);
      console.log(`  Place covered by nothing:  ${Number(g.uncovered).toFixed(4)} sq mi  (water: ${(TIGER_TOTAL_SQ_MI - TIGER_LAND_SQ_MI).toFixed(2)})`);

      if (Math.abs(unionSqMi - EXPECTED_UNION_SQ_MI) > UNION_TOLERANCE_SQ_MI) {
        fail(`GATE 6: union ${unionSqMi} sq mi is more than ${UNION_TOLERANCE_SQ_MI} from the expected ${EXPECTED_UNION_SQ_MI}.`);
      }
      // The load-bearing one. If the districts cover less ground than the city has
      // LAND, some inhabited ground is in no district and returns no councilmember.
      if (unionSqMi < TIGER_LAND_SQ_MI) {
        fail(
          `GATE 6: the nine districts cover ${unionSqMi} sq mi but Long Beach has ${TIGER_LAND_SQ_MI} sq mi of ` +
            `LAND (TIGERweb). Some inhabited ground would be in no council district and would return ` +
            `no councilmember at all.`,
        );
      }
      if (Number(g.outside_place) > MAX_OUTSIDE_PLACE_SQ_MI) {
        fail(
          `GATE 6: ${g.outside_place} sq mi of district ground falls outside the city limits, over the ` +
            `${MAX_OUTSIDE_PLACE_SQ_MI} sq mi allowed for digitisation noise.`,
        );
      }
      console.log('  ✓ every acre of land is inside a district; the gap is harbour and ocean');
    }

    // ─── GATE 7: the slot is free, and the place polygon is still there ──────
    console.log(`\nGATE 7 — ${MTFCC} is unclaimed`);
    {
      const claimedRows = await pool.query<{ n: number; example: string | null }>(
        `SELECT count(*)::int AS n, min(geo_id) AS example
           FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
        [MTFCC],
      );
      const { n: claimedN, example } = claimedRows.rows[0]!;
      if (claimedN > 0) {
        const ours = await pool.query<{ n: number }>(
          `SELECT count(*)::int AS n FROM essentials.geofence_boundaries
            WHERE mtfcc = $1 AND geo_id LIKE $2`,
          [MTFCC, `${GEO_ID_PREFIX}%`],
        );
        if (ours.rows[0]!.n !== claimedN) {
          fail(`${MTFCC} already holds ${claimedN} rows that are not ours (e.g. ${example}). Take the next code.`);
        }
        console.log(`  ${MTFCC} holds ${claimedN} rows, all ours — this is a re-run`);
      } else {
        console.log(`  ✓ ${MTFCC} is unclaimed`);
      }

      const place = await pool.query<{ n: number }>(
        `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc=$2`,
        [PLACE_GEO_ID, PLACE_MTFCC],
      );
      if (place.rows[0]!.n !== 1) {
        fail(`TIGER place ${PLACE_GEO_ID}/${PLACE_MTFCC} is missing — the four citywide seats have nothing to hang on.`);
      }
      console.log(`  ✓ TIGER place ${PLACE_GEO_ID} present for the four citywide seats`);
    }

    console.log('\nAll gates passed.');

    if (DRY_RUN) {
      console.log('DRY-RUN complete — no database writes made.');
      await pool.end();
      process.exit(0);
    }

    // ─── Write ───────────────────────────────────────────────────────────────
    let inserted = 0;
    let alreadyExists = 0;
    let repaired = 0;
    for (const d of DISTRICTS) {
      const geoId = `${GEO_ID_PREFIX}${d}`;
      const name = `Long Beach City Council District ${d}`;
      const geomStr = geomOf(d);
      const result = await pool.query<{ gtype: string; valid: boolean }>(
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
        console.log(`  District ${d} (${geoId}): skipped (already exists)`);
        continue;
      }

      const row = result.rows[0]!;
      if (row.valid !== true) {
        console.error(`  District ${d} (${geoId}): ST_IsValid=false — applying ST_MakeValid`);
        await pool.query(
          `UPDATE essentials.geofence_boundaries
             SET geometry = public.ST_Multi(public.ST_MakeValid(
               public.ST_SetSRID(public.ST_GeomFromGeoJSON($2), 4326)))
           WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
          [geoId, geomStr],
        );
        const recheck = await pool.query<{ valid: boolean }>(
          `SELECT public.ST_IsValid(geometry) AS valid
             FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = '${MTFCC}'`,
          [geoId],
        );
        if (recheck.rows[0]?.valid !== true) {
          console.error(`  ERROR: District ${d} still invalid after ST_MakeValid. Aborting.`);
          await pool.end();
          process.exit(1);
        }
        repaired++;
        console.log(`  District ${d} (${geoId}): repaired via ST_MakeValid`);
      } else {
        console.log(`  District ${d} (${geoId}): inserted (${row.gtype}, valid)`);
      }
      inserted++;
    }

    console.log('\n=== Summary ===');
    console.log(`  Inserted:        ${inserted}`);
    console.log(`  Already existed: ${alreadyExists}`);
    console.log(`  Repaired:        ${repaired}`);

    // 🔴 Re-read from the DATABASE. Every gate above ran on what was FETCHED.
    const check = await pool.query<{ n: number; invalid: number; wrong_srid: number; wrong_state: number }>(
      `SELECT COUNT(*)::int AS n,
              COUNT(*) FILTER (WHERE NOT public.ST_IsValid(geometry))::int AS invalid,
              COUNT(*) FILTER (WHERE public.ST_SRID(geometry) <> 4326)::int AS wrong_srid,
              COUNT(*) FILTER (WHERE state <> '${STATE_CODE}')::int AS wrong_state
         FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`,
    );
    const { n, invalid, wrong_srid: wrongSrid, wrong_state: wrongState } = check.rows[0]!;
    console.log(`  In DB now:       ${n} rows (${invalid} invalid, ${wrongSrid} wrong SRID, ${wrongState} wrong state)`);

    if (n !== EXPECTED_COUNT || invalid !== 0 || wrongSrid !== 0 || wrongState !== 0) {
      fail(
        `expected ${EXPECTED_COUNT} valid rows in SRID 4326 and state '${STATE_CODE}', got ${n} ` +
          `with ${invalid} invalid, ${wrongSrid} in the wrong SRID and ${wrongState} in the wrong state.`,
      );
    }
    console.log('\n▶ Next: apply the CA-1 repair migration, which repoints the nine district rows onto these geo_ids.');
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
