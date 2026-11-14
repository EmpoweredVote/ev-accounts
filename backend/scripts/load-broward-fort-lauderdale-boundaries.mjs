#!/usr/bin/env node
/**
 * load-broward-fort-lauderdale-boundaries.mjs
 *
 * Loads the nine Broward County Commission districts and the four Fort Lauderdale City Commission
 * districts into essentials.geofence_boundaries:
 *
 *   mtfcc 'X0040', state 'fl', geo_id 'broward-fl-commissioner-district-N'        (9 rows)
 *   mtfcc 'X0041', state 'fl', geo_id 'fort-lauderdale-fl-commission-district-N'  (4 rows)
 *
 * Those geo_ids are the ones CC_0420 already put on the districts, and the mtfcc/state pair is the
 * one Miami-Dade's 13 and Miami's 5 districts carry, so no migration is needed: the address join
 * matches on geo_id + mtfcc and starts resolving the moment these rows exist.
 *
 * Writes ONLY to essentials.geofence_boundaries.
 *
 * ── WHY (measured 2026-11-13) ──────────────────────────────────────────────────────────────────
 * CC_0420 seeded both governments and turned MASTER red on `address-search reachability` with NEW
 * buckets UNREACHABLE fl|COUNTY 9 and fl|LOCAL 3: twelve seated officeholders no address could
 * reach. PR #1452 baselined that as an explicit debt. This script is the payment.
 *
 * 🔴 THE MISTAKE THAT CAUSED IT, SO NOBODY REPEATS IT. The author checked essentials.geo_districts,
 * found it empty for Miami-Dade and the City of Miami as well, and concluded Florida carried no
 * district geometry. WRONG TABLE. Reachability — and the address path generally — reads
 * essentials.GEOFENCE_BOUNDARIES, where Miami-Dade and Miami both have polygons.
 *
 * ── WHY THIS LAYER, AND NOT BROWARD COUNTY GIS'S OWN ───────────────────────────────────────────
 * 🔴 The obvious source is a trap. Broward County GIS publishes
 * `bcgis_Commission_Districts_View`, and its own description reads "Redistricting occured Sept
 * 2011-Dec 2011 ... Commissioners approved new commission boundaries Dec. 13, 2011 ... Reviewed:
 * 05/15/2015" — while its lastEditDate is 2022-12-13 and Broward adopted FIU's Map C on
 * 2021-12-07. The prose and the timestamp disagree about which decade's map the layer holds, and a
 * 2011 map would pass every gate in this repo while telling residents the wrong commissioner
 * represents them. That is exactly what the boundary vintage gate exists to prevent.
 *
 * 🔑 So the source here is the SUPERVISOR OF ELECTIONS' OWN LAYER — the one behind
 * browardvotes.gov/find-my-representative, found by reading that app's web map
 * (bcgis.maps.arcgis.com item b15dadff7f9841a0a2adfc86d4bcd9d4) rather than by searching a catalog.
 * It is the map the county uses to decide which ballot a voter gets, so by construction it is the
 * map that elected the roster CC_0420 seeded. Its lastEditDate was 2026-11-12 — the day before
 * this was written.
 *
 * 🔑🔑 AND IT CARRIES THE REPRESENTATIVES' NAMES, which turns vintage from an argument into a
 * measurement. GATE 1 below checks all nine county polygons against the nine commissioners in
 * production and all four city polygons against the four Fort Lauderdale seats. A 2011 map would
 * still have districts numbered 1-9; it would not have Caryl Shuham's predecessor sitting in the
 * right one.
 *
 * ⚠ ONE LAYER HOLDS EVERY MUNICIPALITY IN THE COUNTY, AND FIVE OF THEM ARE NAMED "LAUDERDALE".
 * North Lauderdale's City Commission districts A-D are in the same `electedoffice = 'City
 * Commission'` bucket, and Lauderdale Lakes, Lauderdale-by-the-Sea and Lauderhill all appear too.
 * The city query filters `district LIKE 'Fort Lauderdale%'`, never `LIKE '%Lauderdale%'`.
 *
 * ⚠ FORT LAUDERDALE DISTRICT 1 SHOWS "John C. Herbst", WHO RESIGNED ON 2026-11-02. That is correct
 * for a layer keyed to the term, not to today, and it matches CC_0420's own closed Herbst row. The
 * roster gate expects him there and says so.
 *
 * ── GATES ──────────────────────────────────────────────────────────────────────────────────────
 *   1  exactly 9 + 4 features, district ids 1-9 and 1-4 once each, and every repname1 matches the
 *      holder essentials.office_terms gives for that seat (surname + first initial, because the
 *      layer writes "Steve Geller" and "Michael Udine" where the roster has "Steven Anthony
 *      Geller" and "Michael I. Udine")
 *   2  every geometry valid and non-empty after ST_MakeValid
 *   3  no two districts in the same set overlap by more than 0.01 sq mi
 *   4  CLOSURE, county set: >= 99.5% of the union's area lies inside Broward's own G4020 polygon,
 *      and the union covers >= 99.5% of the Fort Lauderdale G4110 place polygon. ⚠ Coverage of the
 *      county polygon itself CANNOT be gated: TIGER's 12011 is 1,308 sq mi including ocean and
 *      Everglades water, so a land-only district set can never cover it. A whole city known to sit
 *      inside the county is the honest closure probe.
 *   5  CLOSURE, city set: >= 99% of the Fort Lauderdale place polygon covered, and >= 99% of the
 *      union inside it
 *   6  CONTROL, reported not enforced: symmetric difference per county district against Broward
 *      County GIS's bcgis_Commission_Districts_View. If that layer is the same map the numbers are
 *      tiny; if it is the 2011 map they are not, and either way the SOE layer wins because GATE 1
 *      measured it against the sitting commissioners. The number is printed so the next person can
 *      see which it was.
 *
 * Usage (DATABASE_URL from backend/.env, or in the environment):
 *   node scripts/load-broward-fort-lauderdale-boundaries.mjs --dry-run
 *   node scripts/load-broward-fort-lauderdale-boundaries.mjs
 */
import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

const SOE_LAYER =
  'https://services.arcgis.com/JMAJrTsHNLrSsWf5/arcgis/rest/services/'
  + 'ElectionGeography_public_25135677cecf426483e4c6d93e58db0a/FeatureServer/2';
const CONTROL_LAYER =
  'https://services.arcgis.com/JMAJrTsHNLrSsWf5/arcgis/rest/services/'
  + 'bcgis_Commission_Districts_View/FeatureServer/0';

const READ_DATE = '2026-11-13';
const SOURCE_COUNTY =
  `browardsoe-agol-ElectionGeography_public-2-${READ_DATE}`;
const SOURCE_CITY = SOURCE_COUNTY;

const COUNTY_MTFCC = 'X0040';
const CITY_MTFCC = 'X0041';
const STATE = 'fl';
const COUNTY_GEOFENCE = '12011';
const CITY_GEOFENCE = '1224000';

const MAX_OVERLAP_SQ_MI = 0.01;
const MIN_COUNTY_UNION_INSIDE_PCT = 99.5;
const MIN_CITY_COVERED_BY_COUNTY_PCT = 99.5;
const MIN_CITY_COVERED_PCT = 99.0;
const MIN_CITY_UNION_INSIDE_PCT = 99.0;

const DRY_RUN = process.argv.includes('--dry-run');

const fail = (msg) => { console.error(`\nFAIL — ${msg}`); process.exit(1); };

/** Surname + first initial. The layer and the roster spell middle names differently. */
function nameKey(s) {
  const clean = String(s || '').replace(/"[^"]*"/g, ' ').replace(/[.,]/g, ' ')
    .replace(/\s+/g, ' ').trim();
  const parts = clean.split(' ').filter(Boolean);
  if (parts.length < 2) return clean.toLowerCase();
  return `${parts[parts.length - 1].toLowerCase()}|${parts[0][0].toLowerCase()}`;
}

/**
 * GATE 6's control is informative, never fatal, so it must not go through fetchGeoJson() —
 * that one calls fail(), which process.exit()s straight past any try/catch around it.
 */
async function tryFetchGeoJson(layer, where) {
  try {
    const u = new URL(`${layer}/query`);
    u.searchParams.set('where', where);
    u.searchParams.set('outFields', '*');
    u.searchParams.set('returnGeometry', 'true');
    u.searchParams.set('outSR', '4326');
    u.searchParams.set('f', 'geojson');
    const r = await fetch(u, { headers: { 'User-Agent': 'EmpoweredVote/1.0' } });
    if (!r.ok) return null;
    const j = await r.json();
    return Array.isArray(j.features) ? j.features : null;
  } catch {
    return null;
  }
}

async function fetchGeoJson(layer, where) {
  const u = new URL(`${layer}/query`);
  u.searchParams.set('where', where);
  u.searchParams.set('outFields', 'district,districtid,repname1');
  u.searchParams.set('returnGeometry', 'true');
  u.searchParams.set('outSR', '4326');
  u.searchParams.set('f', 'geojson');
  const r = await fetch(u, { headers: { 'User-Agent': 'EmpoweredVote/1.0' } });
  if (!r.ok) fail(`${layer} returned HTTP ${r.status}`);
  const j = await r.json();
  if (!Array.isArray(j.features)) fail(`${layer} returned no feature array`);
  return j.features;
}

async function main() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) fail('DATABASE_URL is not set.');
  const pool = new Pool({ connectionString, ssl: { rejectUnauthorized: false } });
  const client = await pool.connect();

  try {
    const county = await fetchGeoJson(SOE_LAYER, "electedoffice='County Commissioner'");
    const city = await fetchGeoJson(SOE_LAYER, "electedoffice='City Commission' AND district LIKE 'Fort Lauderdale%'");
    console.log(`fetched ${county.length} county + ${city.length} Fort Lauderdale polygons from the SOE layer`);

    // ── GATE 1a — shape of the two sets ──────────────────────────────────────────────────────
    if (county.length !== 9) fail(`GATE 1: expected 9 county districts, got ${county.length}`);
    if (city.length !== 4) fail(`GATE 1: expected 4 Fort Lauderdale districts, got ${city.length}`);
    const ids = (fs) => fs.map((f) => String(f.properties.districtid)).sort();
    const cIds = ids(county); const tIds = ids(city);
    if (cIds.join(',') !== '1,2,3,4,5,6,7,8,9') fail(`GATE 1: county district ids are ${cIds.join(',')}`);
    if (tIds.join(',') !== '1,2,3,4') fail(`GATE 1: city district ids are ${tIds.join(',')}`);
    // Guard the namesake trap explicitly rather than trusting the WHERE clause.
    for (const f of city) {
      if (!String(f.properties.district).startsWith('Fort Lauderdale')) {
        fail(`GATE 1: a non-Fort-Lauderdale district slipped through: ${f.properties.district}`);
      }
    }

    // ── GATE 1b — the vintage proof: the polygons carry the sitting members ───────────────────
    const { rows: roster } = await client.query(
      `SELECT o.title, p.full_name,
              CASE WHEN c.slug = 'broward-board-of-county-commissioners' THEN 'county' ELSE 'city' END AS tier
         FROM essentials.office_terms t
         JOIN essentials.offices o ON o.id = t.office_id
         JOIN essentials.chambers c ON c.id = o.chamber_id
         JOIN essentials.politicians p ON p.id = t.politician_id
        WHERE c.slug IN ('broward-board-of-county-commissioners','fort-lauderdale-city-commission')
          AND t.term_start <= DATE '2026-11-02'
          AND (t.term_end IS NULL OR t.term_end >= DATE '2026-11-02')`,
    );
    if (roster.length !== 13) {
      fail(`GATE 1: expected 13 seated commission rows in production on 2026-11-02, got ${roster.length}. `
        + 'CC_0420 must be applied before this runs.');
    }
    const want = new Map();
    for (const r of roster) {
      const n = r.title.match(/District (\d+)/);
      if (n) want.set(`${r.tier}|${n[1]}`, r.full_name);
    }
    for (const [tier, feats] of [['county', county], ['city', city]]) {
      for (const f of feats) {
        const k = `${tier}|${f.properties.districtid}`;
        const expected = want.get(k);
        if (!expected) fail(`GATE 1: production has no seated holder for ${k}`);
        if (nameKey(expected) !== nameKey(f.properties.repname1)) {
          fail(`GATE 1 (VINTAGE): ${k} — the layer says "${f.properties.repname1}" but production `
            + `says "${expected}". A boundary whose own representative is wrong is the wrong map.`);
        }
      }
    }
    console.log('GATE 1 ok — all 13 polygons name the member production has in that seat on 2026-11-02');

    await client.query('BEGIN');
    await client.query(
      `CREATE TEMP TABLE bfl_load (
         geo_id text, name text, mtfcc text, tier text, dnum int, geom geometry(MultiPolygon, 4326)
       ) ON COMMIT DROP`,
    );
    for (const [tier, feats, mtfcc, pre, label] of [
      ['county', county, COUNTY_MTFCC, 'broward-fl-commissioner-district-', 'Broward County Commission District '],
      ['city', city, CITY_MTFCC, 'fort-lauderdale-fl-commission-district-', 'Fort Lauderdale City Commission District '],
    ]) {
      for (const f of feats) {
        const n = Number(f.properties.districtid);
        await client.query(
          `INSERT INTO bfl_load (geo_id, name, mtfcc, tier, dnum, geom)
           VALUES ($1, $2, $3, $4, $5,
                   ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($6), 4326))))`,
          [`${pre}${n}`, `${label}${n}`, mtfcc, tier, n, JSON.stringify(f.geometry)],
        );
      }
    }

    // ── GATE 2 — valid, non-empty ────────────────────────────────────────────────────────────
    const { rows: bad } = await client.query(
      'SELECT geo_id FROM bfl_load WHERE geom IS NULL OR ST_IsEmpty(geom) OR NOT ST_IsValid(geom)',
    );
    if (bad.length) fail(`GATE 2: invalid or empty geometry: ${bad.map((b) => b.geo_id).join(', ')}`);

    // ── GATE 3 — no mutual overlap inside a set ──────────────────────────────────────────────
    const { rows: ov } = await client.query(
      `SELECT a.geo_id AS a, b.geo_id AS b,
              round((ST_Area(ST_Intersection(a.geom, b.geom)::geography)/2589988.110336)::numeric, 4) AS sq_mi
         FROM bfl_load a JOIN bfl_load b ON a.tier = b.tier AND a.dnum < b.dnum
        WHERE ST_Intersects(a.geom, b.geom)
          AND ST_Area(ST_Intersection(a.geom, b.geom)::geography)/2589988.110336 > $1`,
      [MAX_OVERLAP_SQ_MI],
    );
    if (ov.length) {
      fail(`GATE 3: districts overlap: ${ov.map((o) => `${o.a}/${o.b} ${o.sq_mi} sq mi`).join('; ')}`);
    }

    // ── GATE 4 — county closure ──────────────────────────────────────────────────────────────
    const { rows: [c4] } = await client.query(
      `WITH u AS (SELECT ST_Union(geom) AS g FROM bfl_load WHERE tier = 'county'),
            cty AS (SELECT geometry AS g FROM essentials.geofence_boundaries
                     WHERE geo_id = $1 AND mtfcc = 'G4020'),
            cit AS (SELECT geometry AS g FROM essentials.geofence_boundaries
                     WHERE geo_id = $2 AND mtfcc = 'G4110')
       SELECT round((100 * ST_Area(ST_Intersection(u.g, cty.g)::geography)
                       / NULLIF(ST_Area(u.g::geography), 0))::numeric, 3) AS union_inside_county_pct,
              round((100 * ST_Area(ST_Intersection(u.g, cit.g)::geography)
                       / NULLIF(ST_Area(cit.g::geography), 0))::numeric, 3) AS city_covered_pct,
              round((ST_Area(u.g::geography)/2589988.110336)::numeric, 1) AS union_sq_mi
         FROM u, cty, cit`,
      [COUNTY_GEOFENCE, CITY_GEOFENCE],
    );
    console.log(`GATE 4 — county union ${c4.union_sq_mi} sq mi; ${c4.union_inside_county_pct}% inside `
      + `Broward's G4020; covers ${c4.city_covered_pct}% of the Fort Lauderdale place polygon`);
    if (Number(c4.union_inside_county_pct) < MIN_COUNTY_UNION_INSIDE_PCT) {
      fail(`GATE 4: only ${c4.union_inside_county_pct}% of the county union lies inside 12011`);
    }
    if (Number(c4.city_covered_pct) < MIN_CITY_COVERED_BY_COUNTY_PCT) {
      fail(`GATE 4: the county union covers only ${c4.city_covered_pct}% of Fort Lauderdale`);
    }

    // ── GATE 5 — city closure ────────────────────────────────────────────────────────────────
    const { rows: [c5] } = await client.query(
      `WITH u AS (SELECT ST_Union(geom) AS g FROM bfl_load WHERE tier = 'city'),
            cit AS (SELECT geometry AS g FROM essentials.geofence_boundaries
                     WHERE geo_id = $1 AND mtfcc = 'G4110')
       SELECT round((100 * ST_Area(ST_Intersection(u.g, cit.g)::geography)
                       / NULLIF(ST_Area(cit.g::geography), 0))::numeric, 3) AS place_covered_pct,
              round((100 * ST_Area(ST_Intersection(u.g, cit.g)::geography)
                       / NULLIF(ST_Area(u.g::geography), 0))::numeric, 3) AS union_inside_place_pct,
              round((ST_Area(u.g::geography)/2589988.110336)::numeric, 1) AS union_sq_mi
         FROM u, cit`,
      [CITY_GEOFENCE],
    );
    console.log(`GATE 5 — city union ${c5.union_sq_mi} sq mi; covers ${c5.place_covered_pct}% of the `
      + `place polygon; ${c5.union_inside_place_pct}% of it lies inside`);
    if (Number(c5.place_covered_pct) < MIN_CITY_COVERED_PCT) {
      fail(`GATE 5: the four districts cover only ${c5.place_covered_pct}% of Fort Lauderdale`);
    }
    if (Number(c5.union_inside_place_pct) < MIN_CITY_UNION_INSIDE_PCT) {
      fail(`GATE 5: only ${c5.union_inside_place_pct}% of the city union lies inside the place polygon`);
    }

    // ── GATE 6 — control, reported not enforced ──────────────────────────────────────────────
    try {
      const ctrl = await tryFetchGeoJson(CONTROL_LAYER, '1=1');
      if (ctrl === null) {
        console.log('GATE 6 — control layer returned no usable features, skipped. Not fatal: GATE 1 '
          + 'already measured this map against the sitting commissioners.');
      } else if (ctrl.length === 9) {
        await client.query('CREATE TEMP TABLE bfl_ctrl (dnum int, geom geometry(MultiPolygon,4326)) ON COMMIT DROP');
        for (const f of ctrl) {
          const n = Number(f.properties.DISTRICT ?? f.properties.district ?? f.properties.DISTRICTID);
          if (!n) continue;
          await client.query(
            `INSERT INTO bfl_ctrl VALUES ($1, ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON($2), 4326))))`,
            [n, JSON.stringify(f.geometry)],
          );
        }
        const { rows: cmp } = await client.query(
          `SELECT a.dnum,
                  round((100 * ST_Area(ST_SymDifference(a.geom, b.geom)::geography)
                           / NULLIF(ST_Area(a.geom::geography), 0))::numeric, 2) AS symdiff_pct
             FROM bfl_load a JOIN bfl_ctrl b ON b.dnum = a.dnum
            WHERE a.tier = 'county' ORDER BY a.dnum`,
        );
        console.log('GATE 6 — control vs Broward County GIS bcgis_Commission_Districts_View, '
          + 'symmetric difference per district (%):');
        console.log(`  ${cmp.map((r) => `D${r.dnum} ${r.symdiff_pct}`).join('  ')}`);
        const worst = Math.max(...cmp.map((r) => Number(r.symdiff_pct)));
        console.log(worst < 2
          ? `  → worst ${worst}% — the two layers are the SAME map.`
          : `  → worst ${worst}% — the two layers are DIFFERENT maps. The SOE layer is the one that `
            + 'names the sitting commissioners (GATE 1), so it is the one loaded.');
      } else {
        console.log(`GATE 6 — control layer returned ${ctrl.length} features, skipped.`);
      }
    } catch (e) {
      console.log(`GATE 6 — control layer unavailable (${e.message}), skipped. Not fatal.`);
    }

    // ── WRITE ────────────────────────────────────────────────────────────────────────────────
    const { rows: existing } = await client.query(
      `SELECT count(*)::int AS n FROM essentials.geofence_boundaries
        WHERE geo_id IN (SELECT geo_id FROM bfl_load) AND mtfcc IN ($1, $2)`,
      [COUNTY_MTFCC, CITY_MTFCC],
    );
    if (existing[0].n > 0) fail(`${existing[0].n} of these geofence rows already exist — nothing written.`);

    const { rowCount } = await client.query(
      `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source)
       SELECT geo_id, name, $1, mtfcc, geom, $2 FROM bfl_load`,
      [STATE, SOURCE_COUNTY],
    );
    console.log(`inserted ${rowCount} geofence rows (source: ${SOURCE_COUNTY})`);

    const { rows: [post] } = await client.query(
      `SELECT count(*)::int AS reachable
         FROM essentials.districts d
         JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
        WHERE d.geo_id LIKE 'broward-fl-%' OR d.geo_id LIKE 'fort-lauderdale-fl-%'`,
    );
    if (post.reachable !== 13) fail(`post: expected 13 districts matched to a geofence, got ${post.reachable}`);
    console.log('post ok — all 13 districts now join a geofence row on geo_id + mtfcc');

    if (DRY_RUN) {
      await client.query('ROLLBACK');
      console.log('\n--dry-run: rolled back, nothing written.');
    } else {
      await client.query('COMMIT');
      console.log('\ncommitted.');
    }
  } catch (e) {
    try { await client.query('ROLLBACK'); } catch { /* ignore */ }
    throw e;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
