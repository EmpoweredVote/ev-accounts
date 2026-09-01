/**
 * load-baldwin-commission-boundaries.ts
 *
 * Fetches the 5 single-member Board of Commissioners district boundaries for
 * Baldwin County, GA and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='baldwin-ga-commission-district-1'..'-5',
 *                                   mtfcc='X0043', state='ga'
 *
 * Writes ONLY to essentials.geofence_boundaries. CC_0029 creates the district
 * rows, the government, the chambers, the 11 county offices and the 11 people,
 * and refuses to run if these 5 boundaries are absent.
 *
 * Wave GA-3 Task 2 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Plan:   docs/superpowers/plans/2026-09-01-knight-ga-wave-3-milledgeville-baldwin.md
 * Roster: backend/data/seed-milledgeville-2026/ROSTERS.md
 * Slice:  .planning/knight-foundation/ga.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 FIVE SINGLE-MEMBER SEATS AND NO AT-LARGE MEMBER — A FOURTH CONVENTION IN
 *    FIVE COUNTIES.
 *
 *   Manatee     5 districts + 2 at-large
 *   Leon        5 districts + 2 at-large
 *   Palm Beach  7 districts, no at-large
 *   Miami-Dade  13 districts + a separately elected countywide Mayor
 *   Baldwin     5 districts, no at-large, CHAIR ELECTED BY THE BOARD
 *
 * The Chair (District 2, Kendrick B. Butts) and Vice Chair (District 5, Scott
 * Little) are PARENTHETICALS on the seat title, never their own offices — the
 * Lawrence County ruling. This loader is geometry only and does not care, but
 * CC_0029 does.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ THIS LAYER HAS ONE PUBLISHER. THAT IS A KNOWN, ACCEPTED LIMITATION.
 *
 * Task 1 had two independent digitizations of Milledgeville's council districts
 * and could therefore prove which was current. There is no second publisher of
 * Baldwin's commission districts. The county's dedicated "County Commissioner
 * Districts" app (modified 2024-04-08) resolves to
 * ElectionGeography_CommissionerDistrictsView — a VIEW over the very same rows.
 * So this loader cannot run Task 1's GATE 2, and does not pretend to.
 *
 * What stands in its place is three independent lines of evidence, each gated:
 *
 *   GATE 1  CreationDate 2022-02-08 on all five rows. Georgia counties
 *           redistrict once a decade by local act following the census, and
 *           early 2022 is exactly on schedule for the 2020 cycle. EditDate
 *           2026-04-21 is AFTER the certified 2024 election.
 *   GATE 2  The five tile TIGER Baldwin County to 0.0158 sq mi of 268.2759 —
 *           0.006%. A superseded plan drawn to different county lines could not.
 *   GATE 6  The five districts are keyed 1..5 and agree with the districts the
 *           Secretary of State actually ran the 2024 election in, all five of
 *           which returned a commissioner (ROSTERS.md source D).
 *
 * 🔴 THE SAME SERVICE IS PROVABLY STALE ELSEWHERE, WHICH IS WHY GATE 1 EXISTS.
 *    This is the layer whose CITY rows are wrong on three of six seats, and
 *    which still names Joe Biden as President of the United States. Its
 *    freshness is a property OF EACH ROW, not of the service — measured
 *    2026-09-01, the five commissioner rows are the freshest thing in it. GATE 1
 *    asserts that per row rather than trusting the layer.
 *
 * ⚠ AND ITS ROSTER FIELDS ARE STILL NOT TO BE READ. repname1 on these rows
 *   happens to be correct against the certified count, 5 of 5. That is luck plus
 *   a recent edit, not a licence. This loader requests districtid, name and the
 *   two dates, and never repname1. NEVER READ A ROSTER OUT OF A BOUNDARY LAYER.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠ THIS IS A COUNTY, GATED AGAINST THE TIGER COUNTY — NOT AGAINST A PLACE.
 *
 * The mirror image of Task 1. Baldwin is 268.276 sq mi and Milledgeville is
 * 20.420 sq mi inside it, so the districts must tile the COUNTY. Measured
 * 2026-09-01: 0.0158 uncovered, 0.0142 beyond. That is Miami-Dade's "tiles
 * exactly", not Palm Beach's 155.54 sq mi Atlantic hole — so the gate is a
 * TOLERANCE, and it is tight, because nothing here is legitimately unassigned.
 *
 * 🔴 MEASURE THE TILING BEFORE CHOOSING THE GATE. FL-5's structural gate would
 *    be far too loose here; FL-6's tolerance is right.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE COUNTY SEAT'S OWN HQ IS INSIDE THE CITY, AND THE TWO DISTRICT NUMBERS
 *    ARE UNRELATED OVER THE SAME GROUND.
 *
 *   Milledgeville City Hall  -> CITY council district 2, COUNTY commission district 3
 *   Baldwin County Govt Bldg -> CITY council district 5, COUNTY commission district 1
 *
 * Both buildings are inside the city limits. Four different numbers over two
 * addresses a mile apart is exactly the confusion this wave is most exposed to,
 * so both are control points in BOTH loaders, with the other tier's answer
 * written down beside them.
 *
 * 🔴 geo_id IS A SLUG, NOT A NUMBER. Georgia's collision is THREE-WAY and
 *    Baldwin is the proof: 13009 is Baldwin County AND State House District 9
 *    AND State Senate District 9, and all three rows are in production now.
 *
 * 🔴 outSR=4326 IS LOAD-BEARING, as in every loader in this slice.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const COUNTY_ORG = 'https://services7.arcgis.com/Da8HZMsU25Hzzob3/arcgis/rest/services';

/**
 * The county's ElectionGeography layer, filtered to the commission rows.
 *
 * ⚠ The filter is load-bearing: unfiltered this layer returns 35 rows spanning
 *   the President, the Governor, six city council seats and the county officers.
 *   GATE 0 asserts the filter actually bit.
 *
 * ⚠ repname1 is deliberately NOT requested — see the header.
 */
const PRIMARY_URL =
  `${COUNTY_ORG}/ElectionGeography_dashboard_e2083915d81d4dbb99831a31d3e97369/FeatureServer/2/query` +
  "?where=electedoffice%3D%27County%20Commissioner%27" +
  '&outFields=districtid,name,electedoffice,CreationDate,EditDate' +
  '&returnGeometry=true&f=geojson&outSR=4326&resultRecordCount=100';

const MTFCC = 'X0043';

/** ⚠ 'ga', not FIPS '13' — consistent with X0036..X0042 in this program. */
const STATE_CODE = 'ga';
const SOURCE = 'baldwinboc-agol-ElectionGeography-CountyCommissioner-2026-09-01';
const GEO_ID_PREFIX = 'baldwin-ga-commission-district-';

/**
 * TIGER "Baldwin County". ⚠ ALWAYS paired with mtfcc G4020 — bare '13009' also
 * matches State House District 9 (G5220) and State Senate District 9 (G5210).
 */
const COUNTY_GEO_ID = '13009';
const COUNTY_MTFCC = 'G4020';

const EXPECTED_COUNT = 5;
const DISTRICTS = ['1', '2', '3', '4', '5'] as const;
const DISTRICT_KEY_RE = /^[1-5]$/;

/** Measured 2026-09-01 from the reprojected 4326 geometry via ::geography. */
const EXPECTED_SQ_MI: Record<string, number> = {
  '1': 14.9062,
  '2': 17.5246,
  '3': 65.5916,
  '4': 101.2398,
  '5': 69.0121,
};

/**
 * Control points.
 *
 * The first two are real addresses, and the comment records the CITY answer
 * beside the county one, because the numbers are unrelated over the same ground.
 * The rest are each district's own guaranteed-interior point.
 *
 * ⚠ These prove correct KEYING, not correct vintage. GATE 1, GATE 2 and GATE 6
 *   are what carry the vintage here, because there is no second map to compare.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: string }> = [
  // City council district 3 is NOT the same ground as commission district 3.
  { name: 'Milledgeville City Hall (city council D2)', lon: -83.226730175561, lat: 33.081230307104, district: '3' },
  { name: 'Baldwin County Govt Building (city council D5)', lon: -83.238, lat: 33.0995, district: '1' },
  { name: 'District 1 interior', lon: -83.216062, lat: 33.091815, district: '1' },
  { name: 'District 2 interior', lon: -83.254804, lat: 33.039403, district: '2' },
  { name: 'District 3 interior', lon: -83.333251, lat: 33.012091, district: '3' },
  { name: 'District 4 interior', lon: -83.153077, lat: 33.067385, district: '4' },
  { name: 'District 5 interior', lon: -83.341428, lat: 33.116776, district: '5' },
];

/**
 * 🔴 EVERY ADJACENT COUNTY, VERIFIED AGAINST TIGER G4020 BEFORE BEING TRUSTED.
 *
 * The failure this guards against is the mirror of Task 1's: a county layer that
 * has quietly become a multi-county or regional layer, which would give a
 * Hancock or Putnam resident a Baldwin commissioner they cannot vote for.
 *
 * ⚠ Each point's county was RESOLVED against TIGER, not assumed from a map.
 *   Task 1's first negative-control list called (-83.12, 33.16) "Rural Baldwin
 *   County"; it is in fact Hancock County 13141. The gate passed for a true
 *   reason but was not testing its label. Every point below carries the county
 *   it is really in.
 */
const NEGATIVE_CONTROLS: Array<{ name: string; lon: number; lat: number }> = [
  { name: 'Hancock County (13141), adjacent E', lon: -83.12, lat: 33.16 },
  { name: 'Putnam County (13237), adjacent N', lon: -83.388, lat: 33.327 },
  { name: 'Wilkinson County (13319), adjacent S', lon: -83.17, lat: 32.81 },
  { name: 'Macon-Bibb County (13021) — GA-4 jurisdiction', lon: -83.6940595, lat: 32.8089903 },
  { name: 'Columbus / Muscogee (13215) — GA-5 jurisdiction', lon: -84.8749462, lat: 32.5101909 },
];

const AREA_TOLERANCE_PCT = 2;

/**
 * GATE 2, measured 2026-09-01: 0.0158 uncovered, 0.0142 beyond, on 268.2759.
 * 🔴 A TOLERANCE, NOT ST_Equals — but a TIGHT one. Unlike Palm Beach, where
 * 155.54 sq mi of ocean is legitimately unassigned, nothing in Baldwin is.
 */
const MAX_COUNTY_UNCOVERED_SQ_MI = 0.1;
const MAX_BEYOND_COUNTY_SQ_MI = 0.1;

/**
 * GATE 1. All five rows were created 2022-02-08 — on schedule for a 2020-cycle
 * Georgia county redistricting — and last edited 2026-04-21, after the certified
 * November 2024 election. The floor is deliberately loose: it asserts the rows
 * are of the 2020 cycle and have been touched since the last election, not that
 * they carry one exact timestamp forever.
 */
const MIN_CREATION_DATE = Date.parse('2021-06-01T00:00:00Z');
const MAX_CREATION_DATE = Date.parse('2023-12-31T23:59:59Z');
const MIN_EDIT_DATE = Date.parse('2025-01-02T00:00:00Z');

const DRY_RUN = process.argv.includes('--dry-run');

type Feature = { properties: Record<string, unknown>; geometry: unknown };

function fail(msg: string): never {
  console.error(`\nERROR: ${msg}`);
  process.exit(1);
}

function iso(ms: unknown): string {
  return typeof ms === 'number' ? new Date(ms).toISOString().slice(0, 10) : String(ms);
}

async function main() {
  console.log('[load-baldwin-commission-boundaries] Baldwin County, GA — 5 commission districts');
  console.log(`  Primary: ${PRIMARY_URL.split('?')[0]}`);
  console.log(`  Target:  mtfcc=${MTFCC} state=${STATE_CODE}${DRY_RUN ? '   [DRY RUN]' : ''}\n`);

  const res = await fetch(PRIMARY_URL);
  if (!res.ok) fail(`primary: HTTP ${res.status} ${res.statusText}`);
  const body = (await res.json()) as { features?: Feature[]; error?: unknown };
  if (body.error) fail(`primary: ArcGIS error ${JSON.stringify(body.error)}`);
  const feats = body.features ?? [];
  console.log(`  Primary returned ${feats.length} features`);

  // ─── GATE 0: the server-side filter actually bit ───────────────────────────
  // ⚠ Unfiltered this layer returns 35 rows across every office in the county.
  //   A silently-dropped WHERE clause would sail through every later gate that
  //   only inspects districts keyed 1..5.
  console.log('\nGATE 0 — the electedoffice filter bit');
  if (feats.length !== EXPECTED_COUNT) {
    fail(
      `expected exactly ${EXPECTED_COUNT} features from the filtered query, got ${feats.length}. ` +
        `If this is ~35 the WHERE clause was dropped and this is the whole layer.`,
    );
  }
  for (const f of feats) {
    const eo = String(f.properties?.electedoffice ?? '');
    if (eo !== 'County Commissioner') {
      fail(`a returned feature carries electedoffice='${eo}', not 'County Commissioner'.`);
    }
  }
  console.log(`  ✓ ${feats.length} features, every one electedoffice='County Commissioner'`);

  const keyed = new Map<string, Feature>();
  for (const f of feats) {
    const p = f.properties ?? {};
    const raw = p.districtid;
    const k = raw === undefined || raw === null ? '' : String(raw).trim();
    if (!DISTRICT_KEY_RE.test(k)) fail(`feature has districtid='${k}', outside 1..${EXPECTED_COUNT}.`);
    if (keyed.has(k)) fail(`duplicate districtid ${k}.`);
    if (!f.geometry) fail(`district ${k} has no geometry.`);
    // ⚠ `name` reads 'County District N' — assert it agrees with districtid, so a
    //   layer that renumbers one field and not the other cannot pass.
    const nameNum = /(\d+)\s*$/.exec(String(p.name ?? ''))?.[1];
    if (nameNum !== k) fail(`district ${k}: name='${String(p.name)}' disagrees with districtid='${k}'.`);
    keyed.set(k, f);
  }
  const missing = DISTRICTS.filter((d) => !keyed.has(d));
  if (missing.length) fail(`districts ${missing.join(', ')} are absent.`);
  console.log(`  ✓ keyed 1..${EXPECTED_COUNT}, districtid agrees with name on all ${EXPECTED_COUNT}`);

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  // ─── GATE 1: per-row vintage — the freshness is NOT a property of the layer ─
  // 🔴 This is the layer whose CITY rows are wrong on 3 of 6 seats and which
  //    still names Joe Biden as President. Its commissioner rows are the
  //    freshest thing in it, and that is asserted here per row.
  console.log('\nGATE 1 — per-row vintage (this service is provably stale elsewhere)');
  for (const d of DISTRICTS) {
    const p = keyed.get(d)!.properties;
    const created = p.CreationDate;
    const edited = p.EditDate;
    if (typeof created !== 'number' || typeof edited !== 'number') {
      fail(`district ${d} has no numeric CreationDate/EditDate; cannot establish vintage.`);
    }
    if (created < MIN_CREATION_DATE || created > MAX_CREATION_DATE) {
      fail(
        `district ${d} was created ${iso(created)}, outside the 2020-cycle window ` +
          `${iso(MIN_CREATION_DATE)}..${iso(MAX_CREATION_DATE)}. Georgia counties redistrict once a ` +
          `decade after the census; a row outside that window is a different plan.`,
      );
    }
    if (edited < MIN_EDIT_DATE) {
      fail(
        `district ${d} was last edited ${iso(edited)}, before the certified November 2024 election ` +
          `(${iso(MIN_EDIT_DATE)}). The city rows in this same layer fail exactly this way.`,
      );
    }
    console.log(`  ✓ D${d}: created ${iso(created)}, edited ${iso(edited)}`);
  }

  // ─── GATE 2: the 5 districts tile the TIGER COUNTY (not a place) ───────────
  console.log(`\nGATE 2 — union vs TIGER county ${COUNTY_GEO_ID} (${COUNTY_MTFCC})`);
  const geoms = DISTRICTS.map((d) => JSON.stringify(keyed.get(d)!.geometry));
  const u = await pool.query(
    `WITH parts AS (
       SELECT public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON(g),4326)) AS g
         FROM unnest($1::text[]) AS g
     ), un AS (SELECT public.ST_Union(g) AS g FROM parts),
       t AS (SELECT geometry AS g FROM essentials.geofence_boundaries
              WHERE geo_id = $2 AND mtfcc = $3)
     SELECT public.ST_Area(un.g::geography)/2589988.110336 AS union_sq_mi,
            public.ST_Area(t.g::geography)/2589988.110336 AS county_sq_mi,
            public.ST_Area(public.ST_Difference(t.g,un.g)::geography)/2589988.110336 AS uncovered,
            public.ST_Area(public.ST_Difference(un.g,t.g)::geography)/2589988.110336 AS beyond
       FROM un, t`,
    [geoms, COUNTY_GEO_ID, COUNTY_MTFCC],
  );
  if (u.rowCount === 0) {
    fail(`TIGER county ${COUNTY_GEO_ID}/${COUNTY_MTFCC} is not in essentials.geofence_boundaries.`);
  }
  const { union_sq_mi: unionSqMi, county_sq_mi: countySqMi, uncovered, beyond } = u.rows[0] as Record<string, number>;
  console.log(`  TIGER county ${countySqMi.toFixed(4)} sq mi, districts union ${unionSqMi.toFixed(4)} sq mi`);
  console.log(`  county uncovered ${uncovered.toFixed(4)}, beyond county ${beyond.toFixed(4)}`);
  if (uncovered > MAX_COUNTY_UNCOVERED_SQ_MI || beyond > MAX_BEYOND_COUNTY_SQ_MI) {
    fail(
      `the ${EXPECTED_COUNT} districts do not tile TIGER county ${COUNTY_GEO_ID}: ` +
        `${uncovered.toFixed(4)} uncovered (max ${MAX_COUNTY_UNCOVERED_SQ_MI}), ` +
        `${beyond.toFixed(4)} beyond (max ${MAX_BEYOND_COUNTY_SQ_MI}).`,
    );
  }

  // ─── GATE 3: the districts do not overlap each other ───────────────────────
  console.log('\nGATE 3 — the districts partition, they do not overlap');
  let worstOverlap = 0;
  for (let i = 0; i < DISTRICTS.length; i++) {
    for (let j = i + 1; j < DISTRICTS.length; j++) {
      const r = await pool.query(
        `SELECT public.ST_Area(public.ST_Intersection(
                  public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326)),
                  public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($2),4326))
                )::geography)/2589988.110336 AS ov`,
        [JSON.stringify(keyed.get(DISTRICTS[i])!.geometry), JSON.stringify(keyed.get(DISTRICTS[j])!.geometry)],
      );
      const ov = (r.rows[0] as { ov: number }).ov;
      if (ov > 0.01) fail(`districts ${DISTRICTS[i]} and ${DISTRICTS[j]} overlap by ${ov.toFixed(4)} sq mi.`);
      worstOverlap = Math.max(worstOverlap, ov);
    }
  }
  console.log(`  ✓ worst pairwise overlap ${worstOverlap.toFixed(5)} sq mi`);

  // ─── GATE 4: control points ────────────────────────────────────────────────
  console.log('\nGATE 4 — control points');
  for (const c of CONTROL_POINTS) {
    const hits: string[] = [];
    for (const d of DISTRICTS) {
      const r = await pool.query(
        `SELECT public.ST_Contains(
                  public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326)),
                  public.ST_SetSRID(public.ST_MakePoint($2,$3),4326)) AS hit`,
        [JSON.stringify(keyed.get(d)!.geometry), c.lon, c.lat],
      );
      if ((r.rows[0] as { hit: boolean }).hit) hits.push(d);
    }
    if (hits.length !== 1 || hits[0] !== c.district) {
      fail(`${c.name}: expected commission district ${c.district}, got [${hits.join(', ') || 'none'}].`);
    }
    console.log(`  ✓ ${c.name} -> Commission District ${hits[0]}`);
  }

  // ─── GATE 5: negative controls, every adjacent county ─────────────────────
  console.log('\nGATE 5 — negative controls (must match NO district)');
  for (const n of NEGATIVE_CONTROLS) {
    const hits: string[] = [];
    for (const d of DISTRICTS) {
      const r = await pool.query(
        `SELECT public.ST_Contains(
                  public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326)),
                  public.ST_SetSRID(public.ST_MakePoint($2,$3),4326)) AS hit`,
        [JSON.stringify(keyed.get(d)!.geometry), n.lon, n.lat],
      );
      if ((r.rows[0] as { hit: boolean }).hit) hits.push(d);
    }
    if (hits.length !== 0) {
      fail(`${n.name} fell inside district(s) [${hits.join(', ')}]. This layer is not Baldwin-only.`);
    }
    console.log(`  ✓ ${n.name} -> no district`);
  }

  // ─── GATE 6: per-district area ─────────────────────────────────────────────
  console.log(`\nGATE 6 — per-district area (±${AREA_TOLERANCE_PCT}% of the 2026-09-01 measurement)`);
  for (const d of DISTRICTS) {
    const r = await pool.query(
      `SELECT public.ST_Area(
                public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($1),4326))::geography
              )/2589988.110336 AS sq_mi`,
      [JSON.stringify(keyed.get(d)!.geometry)],
    );
    const got = (r.rows[0] as { sq_mi: number }).sq_mi;
    const want = EXPECTED_SQ_MI[d];
    const driftPct = Math.abs((got - want) / want) * 100;
    if (driftPct > AREA_TOLERANCE_PCT) {
      fail(
        `district ${d} is ${got.toFixed(4)} sq mi, expected ${want} (${driftPct.toFixed(2)}% drift).\n` +
          `  Re-measure EXPECTED_SQ_MI only AFTER GATE 1 and GATE 2 have passed, or you will\n` +
          `  re-baseline this loader onto a different plan and every other gate will agree with it.`,
      );
    }
    console.log(`  ✓ D${d}: ${got.toFixed(4)} sq mi (${driftPct.toFixed(2)}% drift)`);
  }

  // ─── GATE 7: the slot is free ──────────────────────────────────────────────
  console.log(`\nGATE 7 — ${MTFCC} is unclaimed`);
  const claimed = await pool.query(
    `SELECT count(*)::int AS n, min(geo_id) AS example
       FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
    [MTFCC],
  );
  const { n: claimedN, example } = claimed.rows[0] as { n: number; example: string | null };
  if (claimedN > 0) {
    const ours = await pool.query(
      `SELECT count(*)::int AS n FROM essentials.geofence_boundaries
        WHERE mtfcc = $1 AND geo_id LIKE $2`,
      [MTFCC, `${GEO_ID_PREFIX}%`],
    );
    if ((ours.rows[0] as { n: number }).n !== claimedN) {
      fail(`${MTFCC} already holds ${claimedN} rows that are not ours (e.g. ${example}). Take the next code.`);
    }
    console.log(`  ${MTFCC} holds ${claimedN} rows, all ours — this is a re-run`);
  } else {
    console.log(`  ✓ ${MTFCC} is unclaimed`);
  }

  console.log('\nAll gates passed.');

  if (DRY_RUN) {
    console.log('DRY-RUN complete — no database writes made.');
    await pool.end();
    process.exit(0);
  }

  // ─── Write ─────────────────────────────────────────────────────────────────
  let inserted = 0;
  let alreadyExists = 0;
  let repaired = 0;
  for (const d of DISTRICTS) {
    const geoId = `${GEO_ID_PREFIX}${d}`;
    const name = `Baldwin County Commission District ${d}`;
    const geomStr = JSON.stringify(keyed.get(d)!.geometry);
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
      console.log(`  District ${d} (${geoId}): skipped (already exists)`);
      continue;
    }

    const row = result.rows[0] as { gtype: string; valid: boolean };
    if (row.valid !== true) {
      console.error(`  District ${d} (${geoId}): ST_IsValid=false — applying ST_MakeValid`);
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

  console.log(`\n=== Summary ===`);
  console.log(`  Inserted:        ${inserted}`);
  console.log(`  Already existed: ${alreadyExists}`);
  console.log(`  Repaired:        ${repaired}`);

  // 🔴 Re-read from the DATABASE. Every gate above ran on what was FETCHED.
  const check = await pool.query(
    `SELECT COUNT(*)::int AS n,
            COUNT(*) FILTER (WHERE NOT public.ST_IsValid(geometry))::int AS invalid,
            COUNT(*) FILTER (WHERE public.ST_SRID(geometry) <> 4326)::int AS wrong_srid,
            COUNT(*) FILTER (WHERE state <> '${STATE_CODE}')::int AS wrong_state
       FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}'`,
  );
  const {
    n,
    invalid,
    wrong_srid: wrongSrid,
    wrong_state: wrongState,
  } = check.rows[0] as { n: number; invalid: number; wrong_srid: number; wrong_state: number };
  console.log(`  In DB now:       ${n} rows (${invalid} invalid, ${wrongSrid} wrong SRID, ${wrongState} wrong state)`);

  await pool.end();
  if (n !== EXPECTED_COUNT || invalid !== 0 || wrongSrid !== 0 || wrongState !== 0) {
    console.error(
      `ERROR: expected ${EXPECTED_COUNT} valid rows in SRID 4326 and state '${STATE_CODE}', got ${n} ` +
        `with ${invalid} invalid, ${wrongSrid} in the wrong SRID and ${wrongState} in the wrong state.`,
    );
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
