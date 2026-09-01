/**
 * load-columbus-council-boundaries.ts
 *
 * Fetches the 8 single-member Council district boundaries for Columbus, GA
 * (Columbus Consolidated Government) and inserts them into:
 *
 *   essentials.geofence_boundaries  geo_id='columbus-ga-council-district-1'..'-8',
 *                                   mtfcc='X0044', state='ga'
 *
 * Writes ONLY to essentials.geofence_boundaries. The GA-4 structure migration
 * creates the district rows, the government, the chambers and the offices; the
 * occupancy migration the people. They refuse to run if these 8 are absent.
 *
 * Wave GA-4 of the Knight Foundation cities program.
 * Spec:   docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
 * Plan:   docs/superpowers/plans/2026-09-01-knight-ga-wave-4-columbus-muscogee.md
 * Roster: backend/data/seed-columbus-2026/ROSTERS.md
 * Slice:  .planning/knight-foundation/ga.md
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴🔴🔴 TWO LAYERS PUBLISH COLUMBUS COUNCIL DISTRICTS AND THEY *INVERT*: THE ONE
 *      WITH THE CURRENT ROSTER HAS THE SUPERSEDED GEOMETRY.
 *
 * One ArcGIS service carries both:
 *
 *   /MapServer/3  "Council/School Board Districts"   ← PRIMARY. This loader.
 *                 Geometry matches the county's ballot-building record EXACTLY.
 *                 🔴 Its REPNAME1 still says BYRON HICKEY in District 1 — the
 *                    appointed predecessor who left in May 2026.
 *
 *   /MapServer/10 "Council Districts"                🔴 SUPERSEDED GEOMETRY.
 *                 Named more precisely, listed second, and its REPNAME is
 *                 CURRENT (SIMI BARNES in D1) — and every one of its boundaries
 *                 is wrong.
 *
 * Measured 2026-09-01, per-district symmetric difference in sq mi:
 *
 *              layer 3    layer 10   they differ by   vs ballot record
 *   D1          9.3133      9.7065        0.394       layer 3 = 0.000
 *   D2         41.9732     41.1184        1.587       layer 3 = 0.000
 *   D3          7.8994      8.4781        0.894       layer 3 = 0.000
 *   D4          9.9978      9.8638        0.136       layer 3 = 0.000
 *   D5          9.4093     10.0783        2.493       layer 3 = 0.000
 *   D6         47.2617     45.6025        1.747       layer 3 = 0.000
 *   D7         12.0524     12.8354        1.358       layer 3 = 0.000
 *   D8          8.3326      8.8785        3.639       layer 3 = 0.000   ← 41% of itself
 *
 * GA-3 learned that geometry vintage and attribute vintage are different
 * questions about one row. Here they do not merely differ, they point in
 * OPPOSITE directions, so picking one layer for both answers gets one of them
 * wrong whichever you pick.
 *
 * ⚠ Layer 3's *school board* field (REPNAME2) names 2026 winners while its
 *   *council* field names a predecessor. Freshness is not a property of a layer,
 *   nor even of a row. It is a property of a FIELD.
 *
 * ⚠ NEVER READ A ROSTER OUT OF A BOUNDARY LAYER. This loader requests
 *   DISTRICTID and nothing else. The roster comes from the city's own council
 *   pages and the Secretary of State's certified returns.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE ARBITER IS THE COUNTY'S OWN BALLOT-BUILDING TABLE, AND IT IS GATE 1.
 *
 *   /MapServer/8  "Elections Combinations"  — one row per
 *                 precinct × congress × senate × house × council combination,
 *                 which is what the county builds its ballots from.
 *
 * Dissolved by COUNCIL_SCHOOL and compared district by district, it agrees with
 * layer 3 at 0.000 sq mi on all eight and with layer 10 on none. That is a
 * stronger vintage test than any anchor sweep, because it is not a second
 * cartographer's opinion — it is the record the election was actually run from.
 *
 * ▶ LOOK FOR A COMBINATIONS/BALLOT-BUILDING LAYER FIRST IN EVERY FUTURE WAVE.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 GATE ORDER IS LOAD-BEARING (the FL-6 rule, restated by GA-3).
 *
 * GATE 1 is the discriminator and runs first. GATE 5's failure message invites
 * re-measuring EXPECTED_SQ_MI, which — followed at the wrong moment — would
 * re-baseline this loader onto the wrong map and make every later gate agree
 * with it. A gate that invites re-baselining must never fire first.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE 8 DISTRICTS DO NOT TILE THE COUNTY, AND THAT IS CORRECT. DO NOT GATE
 *      ON FULL COVERAGE — IT FAILS ON CORRECT DATA.
 *
 * Columbus city (TIGER place 1319000) and Muscogee County (13215) are the same
 * 221.011 sq mi: consolidation, measured not assumed. The 8 council districts
 * cover 146.2397, leaving 74.79 sq mi — a third of the county — in no district.
 *
 * That is not a hole. Layer 8 carries five rows reading
 *
 *     "Precinct N/A; Congress 0NN; Senate 0NN; House 1NN; Council & School Board N/A"
 *
 * totalling 74.7669 sq mi, whose symmetric difference against the council-district
 * gap is 0.770 sq mi. THE COUNTY ITSELF records that ground as belonging to no
 * precinct and no council district. It is the Fort Benning reservation; state
 * House and Senate districts do cover it.
 *
 * This is FL-5's "155.54 sq mi of 12099 is the Atlantic" in a new dress — except
 * the excluded ground here is LAND, and the authority is not geography but the
 * county's own ballot record. GATE 6 therefore asserts the STRUCTURE: the union,
 * and that the gap equals the N/A area within tolerance.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 EVERY NEGATIVE CONTROL'S COUNTY IS ASSERTED, NOT LABELLED.
 *
 * GA-3 shipped a control point labelled "Rural Baldwin County" that was really in
 * Hancock County: the gate passed, for a true reason, while testing nothing it
 * claimed to test. A mislabelled control reads as covered.
 *
 * So GATE 4 resolves each negative control against TIGER G4020 and fails if the
 * county it lands in is not the county its label names. All four were verified
 * 2026-09-01. The discriminating one is INSIDE Muscogee County and inside the
 * city — the Fort Benning gap — because city and county are the same ground here
 * and "outside the city" is therefore not available as a control at all.
 *
 * 🔴 geo_id IS A SLUG, NOT A NUMBER. Georgia's geo_id collision is THREE-WAY:
 *    13215 is Muscogee County, and 89 of 159 county ids fall inside the sldl
 *    range. A slug cannot collide. Matches X0042 (milledgeville-ga-council-…)
 *    and X0043 (baldwin-ga-commission-…).
 *
 * 🔴 outSR=4326 IS LOAD-BEARING, as in every loader in this slice.
 * ⚠ ccggisprod.columbusga.org serves a VALID certificate — no TLS workaround is
 *   needed. (`curl -k` in the measuring session was habit, not necessity.)
 * 🔴 `gis.columbus.gov` is COLUMBUS, OHIO. It has a plausible service name and a
 *    live Redistricting layer. Georgia's host is ccggisprod.columbusga.org.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const SERVICE =
  'https://ccggisprod.columbusga.org/server/rest/services/Elections/Districts/MapServer';

/**
 * PRIMARY — layer 3. Proven against the ballot record by GATE 1.
 * ⚠ REPNAME1/REPNAME2 are deliberately NOT requested. See the header.
 */
const PRIMARY_URL =
  `${SERVICE}/3/query?where=1%3D1&outFields=DISTRICTID` +
  '&returnGeometry=true&outSR=4326&f=geojson';

/** 🔴 THE SUPERSEDED COPY — layer 10. Negative control for GATE 2 only. */
const SUPERSEDED_URL =
  `${SERVICE}/10/query?where=1%3D1&outFields=DISTRICTID` +
  '&returnGeometry=true&outSR=4326&f=geojson';

/** THE ARBITER — layer 8, the precinct × district ballot-building table. */
const ARBITER_URL =
  `${SERVICE}/8/query?where=1%3D1&outFields=COUNCIL_SCHOOL,PRECINCT` +
  '&returnGeometry=true&outSR=4326&f=geojson';

const MTFCC = 'X0044';
const STATE_CODE = 'ga';
const SOURCE = 'columbus-ccggisprod-Elections-Districts-3-2026-09-01';
const GEO_ID_PREFIX = 'columbus-ga-council-district-';

/** TIGER. ⚠ Always paired with its mtfcc — Georgia's collision is three-way. */
const PLACE_GEO_ID = '1319000';
const PLACE_MTFCC = 'G4110';
const COUNTY_GEO_ID = '13215';
const COUNTY_MTFCC = 'G4020';

const EXPECTED_COUNT = 8;
const DISTRICTS = ['1', '2', '3', '4', '5', '6', '7', '8'] as const;
const DISTRICT_KEY_RE = /^[1-8]$/;

/** Measured 2026-09-01 from the reprojected 4326 geometry via ::geography. */
const EXPECTED_SQ_MI: Record<string, number> = {
  '1': 9.3133,
  '2': 41.9732,
  '3': 7.8994,
  '4': 9.9978,
  '5': 9.4093,
  '6': 47.2617,
  '7': 12.0524,
  '8': 8.3326,
};

/**
 * Each district's own guaranteed-interior point (ST_PointOnSurface), measured
 * 2026-09-01. ⚠ These prove correct KEYING, not correct vintage — GATE 1 is what
 * establishes vintage. No street address is used: geocoding one would mean
 * inventing a coordinate, and the address probe belongs to the acceptance step
 * after the migrations, where it can be resolved properly.
 */
const CONTROL_POINTS: Array<{ name: string; lon: number; lat: number; district: string }> = [
  { name: 'District 1 interior', lon: -84.920387, lat: 32.481267, district: '1' },
  { name: 'District 2 interior', lon: -84.986661, lat: 32.557699, district: '2' },
  { name: 'District 3 interior', lon: -84.935057, lat: 32.441950, district: '3' },
  { name: 'District 4 interior', lon: -84.884219, lat: 32.476340, district: '4' },
  { name: 'District 5 interior', lon: -84.935172, lat: 32.510322, district: '5' },
  { name: 'District 6 interior', lon: -84.865382, lat: 32.543388, district: '6' },
  { name: 'District 7 interior', lon: -84.960539, lat: 32.436357, district: '7' },
  { name: 'District 8 interior', lon: -84.972930, lat: 32.508291, district: '8' },
];

/**
 * 🔴 Each carries the county it must resolve to, and GATE 4 asserts it against
 *    TIGER. All four verified 2026-09-01.
 */
const NEGATIVE_CONTROLS: Array<{ name: string; lon: number; lat: number; county: string }> = [
  // 🔴 THE DISCRIMINATING ONE. Inside Muscogee County AND inside Columbus city —
  //    the two are the same ground — but inside NO council district. This is the
  //    Fort Benning gap, and it is the only control that can catch a layer which
  //    has quietly been made to tile the whole county.
  { name: 'Fort Benning gap — in Muscogee, in NO council district', lon: -84.808221, lat: 32.462937, county: '13215' },
  { name: 'Harris County, adjacent north', lon: -84.9, lat: 32.7, county: '13145' },
  { name: 'Milledgeville / Baldwin (GA-3 jurisdiction)', lon: -83.240614, lat: 33.087945, county: '13009' },
  { name: 'Macon-Bibb (GA-5 jurisdiction)', lon: -83.69406, lat: 32.80899, county: '13021' },
];

const AREA_TOLERANCE_PCT = 2;

/** GATE 1. The ballot record and layer 3 measured 0.000 on all eight. */
const MAX_ARBITER_SYMDIFF_SQ_MI = 0.01;

/**
 * GATE 2. Total symmetric difference against layer 10 measured 12.248 sq mi
 * across the eight. At or below this floor the two fetches returned the SAME
 * layer, i.e. this loader is pointed at one URL twice.
 * ⚠ It does NOT fail if Columbus one day syncs layer 10 to the operative map —
 *   a gate must not break on good news.
 */
const MIN_TOTAL_SYMDIFF_SQ_MI = 0.01;

/** GATE 6. Measured 2026-09-01: union 146.2397, N/A area 74.7669, symdiff 0.770. */
const EXPECTED_UNION_SQ_MI = 146.2397;
const UNION_TOLERANCE_SQ_MI = 1.5;
const MAX_GAP_VS_NA_SYMDIFF_SQ_MI = 1.5;

const DRY_RUN = process.argv.includes('--dry-run');

type Feature = { properties: Record<string, unknown>; geometry: unknown };

async function fetchLayer(
  url: string,
  label: string,
  keyOf: (p: Record<string, unknown>) => string | null,
  opts: { allowDuplicateKeys?: boolean } = {},
) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${label}: HTTP ${res.status} ${res.statusText}`);
  const body = (await res.json()) as { features?: Feature[]; error?: unknown };
  if (body.error) throw new Error(`${label}: ArcGIS error ${JSON.stringify(body.error)}`);
  const feats = body.features ?? [];
  const out = new Map<string, Feature[]>();
  for (const f of feats) {
    const k = keyOf(f.properties ?? {});
    if (k === null || !DISTRICT_KEY_RE.test(k)) continue;
    if (!f.geometry) throw new Error(`${label}: district ${k} has a row with no geometry`);
    const bucket = out.get(k);
    if (bucket) {
      if (!opts.allowDuplicateKeys) throw new Error(`${label}: duplicate district key ${k}`);
      bucket.push(f);
    } else {
      out.set(k, [f]);
    }
  }
  return { all: feats.length, keyed: out };
}

/** Strips ArcGIS's zero-padded DISTRICTID ('003' -> '3'). */
const distId = (p: Record<string, unknown>): string | null => {
  const raw = p.DISTRICTID;
  if (raw === undefined || raw === null) return null;
  const s = String(raw).replace(/^0+/, '');
  return s === '' ? null : s;
};

function fail(msg: string): never {
  console.error(`\nERROR: ${msg}`);
  process.exit(1);
}

const SQM_PER_SQMI = 2589988.110336;

async function main() {
  console.log('[load-columbus-council-boundaries] Columbus Consolidated Government, GA — 8 council districts');
  console.log(`  Primary:    ${SERVICE}/3   (Council/School Board Districts)`);
  console.log(`  Arbiter:    ${SERVICE}/8   (Elections Combinations — the ballot record)`);
  console.log(`  Superseded: ${SERVICE}/10  (Council Districts — WRONG geometry, current roster)`);
  console.log(`  Target:     mtfcc=${MTFCC} state=${STATE_CODE}${DRY_RUN ? '   [DRY RUN]' : ''}\n`);
  console.log('  ⚠ Districts 9 and 10 are AT LARGE and have no geometry. 8 polygons is correct.\n');

  const primary = await fetchLayer(PRIMARY_URL, 'primary (layer 3)', distId);
  console.log(`  Primary returned ${primary.all} features, ${primary.keyed.size} keyed 1..${EXPECTED_COUNT}`);
  if (primary.keyed.size !== EXPECTED_COUNT) {
    fail(`expected ${EXPECTED_COUNT} districts, got ${primary.keyed.size}.`);
  }
  const missing = DISTRICTS.filter((d) => !primary.keyed.has(d));
  if (missing.length) fail(`districts ${missing.join(', ')} are absent.`);
  for (const d of DISTRICTS) {
    if (primary.keyed.get(d)!.length !== 1) fail(`district ${d} returned ${primary.keyed.get(d)!.length} rows, expected 1.`);
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const geomOf = (d: string) => JSON.stringify(primary.keyed.get(d)![0].geometry);

  // Stage the three layers once, in one session, so every gate compares the same bytes.
  await pool.query('CREATE TEMP TABLE IF NOT EXISTS _cbs(src text, did text, geom geometry)');
  await pool.query('TRUNCATE _cbs');
  const stage = async (src: string, did: string, geojson: string) =>
    pool.query(
      `INSERT INTO _cbs VALUES ($1, $2,
         public.ST_MakeValid(public.ST_SetSRID(public.ST_GeomFromGeoJSON($3), 4326)))`,
      [src, did, geojson],
    );
  for (const d of DISTRICTS) await stage('primary', d, geomOf(d));

  const arbiter = await fetchLayer(ARBITER_URL, 'arbiter (layer 8)', (p) => {
    const v = p.COUNCIL_SCHOOL;
    if (v === undefined || v === null) return null;
    const s = String(v).replace(/^0+/, '');
    return s === '' || s === 'N/A' ? null : s;
  }, { allowDuplicateKeys: true });
  console.log(`  Arbiter returned ${arbiter.all} combination rows, keyed into ${arbiter.keyed.size} districts`);
  if (arbiter.keyed.size !== EXPECTED_COUNT) {
    fail(`the ballot record dissolves to ${arbiter.keyed.size} districts, expected ${EXPECTED_COUNT}.`);
  }
  for (const d of DISTRICTS) {
    for (const f of arbiter.keyed.get(d)!) await stage('arbiter', d, JSON.stringify(f.geometry));
  }

  // ─── GATE 1: THE BALLOT RECORD — the discriminator, and it runs first ───────
  console.log('\nGATE 1 — per-district agreement with the county\'s ballot-building record (layer 8)');
  {
    const r = await pool.query<{ did: string; symdiff: string }>(
      `SELECT p.did,
              round((public.ST_Area(public.ST_SymDifference(p.g, a.g)::geography)/${SQM_PER_SQMI})::numeric, 4) AS symdiff
         FROM (SELECT did, public.ST_Union(geom) g FROM _cbs WHERE src='primary' GROUP BY did) p
         JOIN (SELECT did, public.ST_Union(geom) g FROM _cbs WHERE src='arbiter' GROUP BY did) a
           ON a.did = p.did
        ORDER BY p.did::int`,
    );
    if (r.rowCount !== EXPECTED_COUNT) fail(`GATE 1 compared ${r.rowCount} districts, expected ${EXPECTED_COUNT}.`);
    let worst = 0;
    for (const row of r.rows) {
      const v = Number(row.symdiff);
      worst = Math.max(worst, v);
      console.log(`  D${row.did}: symdiff ${v.toFixed(4)} sq mi`);
    }
    if (worst > MAX_ARBITER_SYMDIFF_SQ_MI) {
      fail(
        `GATE 1: worst symdiff ${worst.toFixed(4)} sq mi exceeds ${MAX_ARBITER_SYMDIFF_SQ_MI}. ` +
          `This layer is NOT the map the county built its ballots from. ` +
          `Do NOT re-baseline the area constants — find the right layer.`,
      );
    }
    console.log(`  ✓ worst ${worst.toFixed(4)} sq mi — this is the operative map`);
  }

  // ─── GATE 2: the superseded copy must not BE the primary ───────────────────
  console.log('\nGATE 2 — divergence from the superseded layer 10');
  {
    const superseded = await fetchLayer(SUPERSEDED_URL, 'superseded (layer 10)', distId);
    console.log(`  Superseded returned ${superseded.all} features, ${superseded.keyed.size} keyed`);
    for (const d of DISTRICTS) {
      const f = superseded.keyed.get(d);
      if (f) await stage('superseded', d, JSON.stringify(f[0].geometry));
    }
    const r = await pool.query<{ total: string }>(
      `SELECT round(sum(public.ST_Area(public.ST_SymDifference(p.g, s.g)::geography)/${SQM_PER_SQMI})::numeric, 4) AS total
         FROM (SELECT did, public.ST_Union(geom) g FROM _cbs WHERE src='primary' GROUP BY did) p
         JOIN (SELECT did, public.ST_Union(geom) g FROM _cbs WHERE src='superseded' GROUP BY did) s
           ON s.did = p.did`,
    );
    const total = Number(r.rows[0]?.total ?? 0);
    if (total <= MIN_TOTAL_SYMDIFF_SQ_MI) {
      fail(
        `GATE 2: layers 3 and 10 differ by only ${total.toFixed(4)} sq mi. Either this loader fetched ` +
          `the same URL twice, or Columbus has synced them — check by hand before trusting either.`,
      );
    }
    console.log(`  ✓ ${total.toFixed(4)} sq mi total divergence — they are genuinely different maps`);
  }

  // ─── GATE 3: control points ────────────────────────────────────────────────
  console.log('\nGATE 3 — control points (each district\'s own interior point)');
  for (const c of CONTROL_POINTS) {
    const r = await pool.query<{ did: string }>(
      `SELECT did FROM (SELECT did, public.ST_Union(geom) g FROM _cbs WHERE src='primary' GROUP BY did) p
        WHERE public.ST_Covers(p.g, public.ST_SetSRID(public.ST_MakePoint($1,$2),4326))`,
      [c.lon, c.lat],
    );
    const got = r.rows.map((x) => x.did);
    if (got.length !== 1 || got[0] !== c.district) {
      fail(`GATE 3: ${c.name} resolved to [${got.join(', ') || 'nothing'}], expected exactly District ${c.district}.`);
    }
    console.log(`  ✓ ${c.name} → District ${got[0]}`);
  }

  // ─── GATE 4: negative controls, with their county ASSERTED not labelled ────
  console.log('\nGATE 4 — negative controls (must match NO council district, and be where the label says)');
  for (const c of NEGATIVE_CONTROLS) {
    const county = await pool.query<{ geo_id: string; name: string }>(
      `SELECT geo_id, name FROM essentials.geofence_boundaries
        WHERE mtfcc=$1 AND state='13'
          AND public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint($2,$3),4326))`,
      [COUNTY_MTFCC, c.lon, c.lat],
    );
    const landedIn = county.rows[0]?.geo_id ?? null;
    if (landedIn !== c.county) {
      fail(
        `GATE 4: "${c.name}" claims county ${c.county} but TIGER puts it in ${landedIn ?? 'no county'}. ` +
          `A mislabelled control reads as covered — fix the point or the label (the GA-3 Hancock defect).`,
      );
    }
    const hit = await pool.query<{ did: string }>(
      `SELECT did FROM (SELECT did, public.ST_Union(geom) g FROM _cbs WHERE src='primary' GROUP BY did) p
        WHERE public.ST_Covers(p.g, public.ST_SetSRID(public.ST_MakePoint($1,$2),4326))`,
      [c.lon, c.lat],
    );
    if (hit.rowCount !== 0) {
      fail(`GATE 4: ${c.name} matched District ${hit.rows.map((x) => x.did).join(', ')} — it must match none.`);
    }
    console.log(`  ✓ ${c.name} → no district (county ${landedIn} confirmed)`);
  }

  // ─── GATE 5: per-district area ─────────────────────────────────────────────
  console.log(`\nGATE 5 — per-district area (±${AREA_TOLERANCE_PCT}% of the 2026-09-01 measurement)`);
  {
    const r = await pool.query<{ did: string; sq_mi: string }>(
      `SELECT did, round((public.ST_Area(public.ST_Union(geom)::geography)/${SQM_PER_SQMI})::numeric, 4) AS sq_mi
         FROM _cbs WHERE src='primary' GROUP BY did ORDER BY did::int`,
    );
    for (const row of r.rows) {
      const got = Number(row.sq_mi);
      const want = EXPECTED_SQ_MI[row.did];
      const devPct = Math.abs((got - want) / want) * 100;
      if (devPct > AREA_TOLERANCE_PCT) {
        fail(
          `GATE 5: District ${row.did} is ${got} sq mi, expected ~${want} (${devPct.toFixed(2)}% off). ` +
            `⚠ GATE 1 passed, so the map is right — re-measure and update EXPECTED_SQ_MI only after ` +
            `confirming GATE 1 is still green.`,
        );
      }
      console.log(`  ✓ D${row.did}: ${got.toFixed(4)} sq mi (${devPct.toFixed(2)}% from expected)`);
    }
  }

  // ─── GATE 6: STRUCTURE, not coverage ───────────────────────────────────────
  console.log('\nGATE 6 — structure: the union, and the gap that is SUPPOSED to be there');
  {
    // Stage the N/A ("no precinct, no council district") combination rows.
    const naRes = await fetch(ARBITER_URL);
    const naBody = (await naRes.json()) as { features?: Feature[] };
    let naRows = 0;
    for (const f of naBody.features ?? []) {
      if (String((f.properties ?? {}).COUNCIL_SCHOOL ?? '') !== 'N/A') continue;
      if (!f.geometry) continue;
      await stage('na', '0', JSON.stringify(f.geometry));
      naRows++;
    }
    console.log(`  Ballot record carries ${naRows} rows with COUNCIL_SCHOOL='N/A'`);
    if (naRows === 0) fail('GATE 6: the ballot record carries no N/A rows — the Fort Benning exclusion is unverifiable.');

    const r = await pool.query<{
      union_sq_mi: string; na_sq_mi: string; gap_vs_na: string; overlaps: string; beyond_county: string;
    }>(
      `WITH u AS (SELECT public.ST_Union(geom) g FROM _cbs WHERE src='primary'),
            na AS (SELECT public.ST_Union(geom) g FROM _cbs WHERE src='na'),
            c AS (SELECT geometry g FROM essentials.geofence_boundaries
                   WHERE geo_id=$1 AND mtfcc=$2)
       SELECT round((public.ST_Area(u.g::geography)/${SQM_PER_SQMI})::numeric,4) AS union_sq_mi,
              round((public.ST_Area(na.g::geography)/${SQM_PER_SQMI})::numeric,4) AS na_sq_mi,
              round((public.ST_Area(public.ST_SymDifference(
                       public.ST_Difference(c.g, u.g), na.g)::geography)/${SQM_PER_SQMI})::numeric,4) AS gap_vs_na,
              (SELECT count(*) FROM _cbs a JOIN _cbs b
                 ON a.src='primary' AND b.src='primary' AND a.did < b.did
                WHERE public.ST_Area(public.ST_Intersection(a.geom,b.geom)::geography)/${SQM_PER_SQMI} > 0.001
              )::text AS overlaps,
              round((public.ST_Area(public.ST_Difference(u.g, c.g)::geography)/${SQM_PER_SQMI})::numeric,4) AS beyond_county
         FROM u, na, c`,
      [COUNTY_GEO_ID, COUNTY_MTFCC],
    );
    const g = r.rows[0];
    if (!g) fail(`GATE 6: county ${COUNTY_GEO_ID}/${COUNTY_MTFCC} is not in geofence_boundaries.`);
    const unionSqMi = Number(g.union_sq_mi);
    console.log(`  Union of the 8:        ${unionSqMi.toFixed(4)} sq mi (expected ~${EXPECTED_UNION_SQ_MI})`);
    console.log(`  N/A area:              ${Number(g.na_sq_mi).toFixed(4)} sq mi`);
    console.log(`  gap vs N/A symdiff:    ${Number(g.gap_vs_na).toFixed(4)} sq mi`);
    console.log(`  District overlaps:     ${g.overlaps}`);
    console.log(`  Beyond the county:     ${Number(g.beyond_county).toFixed(4)} sq mi`);

    if (Math.abs(unionSqMi - EXPECTED_UNION_SQ_MI) > UNION_TOLERANCE_SQ_MI) {
      fail(`GATE 6: union ${unionSqMi} sq mi is more than ${UNION_TOLERANCE_SQ_MI} from the expected ${EXPECTED_UNION_SQ_MI}.`);
    }
    if (Number(g.gap_vs_na) > MAX_GAP_VS_NA_SYMDIFF_SQ_MI) {
      fail(
        `GATE 6: the uncovered ground disagrees with the ballot record's N/A area by ` +
          `${g.gap_vs_na} sq mi. The gap is only legitimate while the county itself says that ground ` +
          `is in no council district.`,
      );
    }
    if (Number(g.overlaps) !== 0) fail(`GATE 6: ${g.overlaps} district pair(s) overlap by more than 0.001 sq mi.`);
    console.log('  ✓ 8 districts, no overlaps, and the gap is the ground the county excludes');
  }

  // ─── GATE 7: the slot is free ──────────────────────────────────────────────
  console.log(`\nGATE 7 — ${MTFCC} is unclaimed`);
  {
    const claimed = await pool.query<{ n: number; example: string | null }>(
      `SELECT count(*)::int AS n, min(geo_id) AS example
         FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
      [MTFCC],
    );
    const { n: claimedN, example } = claimed.rows[0]!;
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
  }

  // Also confirm the TIGER place exists — the structure migration hangs the
  // citywide district on it, and it is the one district GA-1 did NOT create.
  {
    const place = await pool.query<{ n: number }>(
      `SELECT count(*)::int AS n FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc=$2`,
      [PLACE_GEO_ID, PLACE_MTFCC],
    );
    if (place.rows[0]!.n !== 1) {
      fail(`TIGER place ${PLACE_GEO_ID}/${PLACE_MTFCC} is missing — the citywide district has nothing to hang on.`);
    }
    console.log(`  ✓ TIGER place ${PLACE_GEO_ID} present for the citywide district`);
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
    const name = `Columbus Council District ${d}`;
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
