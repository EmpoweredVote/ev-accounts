/**
 * 1641-coordinate-smoke.ts — Phase 164.1 dual-map coordinate smoke (TN/MO/AL/LA/UT).
 *
 * Fully data-driven D-10 Layer-2/Layer-3 harness. NO hardcoded coordinates and NO
 * per-state edits needed as later plans land polygons / flip withholding:
 *   - A state is processed only if it has mtfcc='G5200V26' rows (skip → GREEN no-op today).
 *   - Layer-2: every V26 district's anchor (public.ST_PointOnSurface of the V26 geometry)
 *     must resolve back to that district under G5200V26-explicit resolution.
 *   - Layer-3 GUARANTEED differential (severe-set-aware — never spuriously fails pre-flip):
 *     auto-discovers a point in NEW district A (A OUTSIDE the state's severe set) that lies
 *     in OLD district B (A != B, non-trivial overlap). Asserts through the UNCACHED LIVE
 *     coordinate shape (the V26-preferring LATERAL, cloned from electionService.ts):
 *     NEW A's race surfaces on /elections, AND the reps-feed live G5200 ST_Covers query
 *     surfaces OLD B (old rep) for the SAME coordinate. Race-level asserts are conditional
 *     on the state's general election existing (UT has no races until Phase 165 — for UT
 *     the boundary-level differential + D-11 RPC probe still run).
 *   - Layer-3 SEVERE differential (auto-conditional on DB-detected withholding state):
 *     if a severe NEW district A yields a differential point: when its race is SURFACING
 *     (post-flip: race points at '{ST} 2026 Statewide General'), assert the full
 *     differential; when WITHHELD (race points at '{ST} 2026 Congressional Redistricting -
 *     Polygon Pending', a past-dated special the visibility window excludes), assert the
 *     BOUNDARY differential only + that ZERO House races surface at the point.
 *   - Layer-3 CONNECTED-TIER geo-id path (D-11): feed the corrected (NEW A, 'G5200') pair
 *     through a getElectionsByGeoIds-equivalent query and assert NEW A's race surfaces.
 *   - Layer-3 D-11 RPC DIRECT INVOCATION: the ONLY assertion that runs
 *     connect.resolve_congressional_2026's actual code path. Inside ONE always-ROLLBACK'd
 *     transaction on a dedicated pooled client: insert a fixed-sentinel-UUID auth.users row
 *     (a trigger auto-creates public.users) + connect.connected_profiles row, encrypt the
 *     differential coords via connect.upsert_user_location (canonical Vault-backed
 *     SECURITY DEFINER encryptor — the app role has no Vault access), then assert
 *     SELECT connect.resolve_congressional_2026(sentinel) = NEW A geo_id. HARD FAIL on
 *     NULL/mismatch while V26 rows exist (catches decrypt / ST_Covers arg-order /
 *     FIPS-filter / search_path bugs). ROLLBACK in finally — NOTHING persists, no real
 *     user row is ever touched.
 *
 * SELECT-only apart from the always-rolled-back sentinel probe. All PostGIS via public.
 * All inputs parameterized — never string-interpolated.
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/1641-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface StateCfg {
  fips: string;
  abbr: string;
  expected: number;      // full district count — partial imports are a hard fail
  severe: string[];      // NEW-district geo_ids whose races may still be withheld
}

const STATES: StateCfg[] = [
  { fips: '47', abbr: 'TN', expected: 9, severe: ['4704', '4705', '4706', '4708', '4709'] },
  { fips: '29', abbr: 'MO', expected: 8, severe: ['2902', '2903', '2904', '2905', '2906'] },
  { fips: '01', abbr: 'AL', expected: 7, severe: ['0102'] },
  { fips: '22', abbr: 'LA', expected: 6, severe: ['2202', '2206'] },
  { fips: '49', abbr: 'UT', expected: 4, severe: [] },
];

// Fixed sentinel UUID for the D-11 RPC probe (never committed; rollback-only).
const SENTINEL_UUID = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

// Non-trivial overlap threshold for differential-zone discovery (deg^2; ~1 km^2
// at CONUS latitudes) — avoids boundary-sliver points that flap under ST_Covers.
const MIN_DIFF_AREA = 1e-4;

const VISIBILITY_WINDOW = `(
  (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
  OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
)`;

// The V26-preferring LATERAL, cloned from electionService.ts getElectionsByCoordinate
// Part A — the live uncached coordinate path this smoke re-validates.
const VINTAGE_LATERAL = `
  JOIN LATERAL (
    SELECT geometry FROM essentials.geofence_boundaries gbv
     WHERE gbv.geo_id = d.geo_id AND gbv.mtfcc = 'G5200V26'
       AND d.district_type = 'NATIONAL_LOWER'
    UNION ALL
    SELECT geometry FROM essentials.geofence_boundaries gbo
     WHERE gbo.geo_id = d.geo_id
       AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gbo.mtfcc = d.mtfcc)
       AND NOT EXISTS (
         SELECT 1 FROM essentials.geofence_boundaries x
          WHERE x.geo_id = d.geo_id AND x.mtfcc = 'G5200V26'
       )
    LIMIT 1
  ) gb ON true`;

interface Differential {
  newGeoId: string;
  oldGeoId: string;
  lng: number;
  lat: number;
}

/**
 * Discover a differential point: interior point of ST_Intersection(NEW A, OLD B),
 * A != B, largest such overlap first. severeMode='exclude' → A outside the severe
 * set (guaranteed pre-flip-safe); 'only' → A inside the severe set.
 * Post-verifies the point really flips sides (covers B under G5200, A under V26).
 */
async function discoverDifferential(
  cfg: StateCfg,
  severeMode: 'exclude' | 'only'
): Promise<Differential | null> {
  const severeCond = severeMode === 'exclude'
    ? 'AND NOT (nw.geo_id = ANY($2::text[]))'
    : 'AND nw.geo_id = ANY($2::text[])';
  const { rows } = await pool.query(
    `SELECT nw.geo_id AS new_geo_id, old.geo_id AS old_geo_id,
            public.ST_X(public.ST_PointOnSurface(public.ST_Intersection(nw.geometry, old.geometry))) AS lng,
            public.ST_Y(public.ST_PointOnSurface(public.ST_Intersection(nw.geometry, old.geometry))) AS lat,
            public.ST_Area(public.ST_Intersection(nw.geometry, old.geometry)) AS diff_area
     FROM essentials.geofence_boundaries nw
     JOIN essentials.geofence_boundaries old
       ON old.mtfcc = 'G5200'
      AND length(old.geo_id) = 4
      AND substr(old.geo_id, 1, 2) = $1
      AND old.geo_id <> nw.geo_id
      AND public.ST_Intersects(nw.geometry, old.geometry)
     WHERE nw.mtfcc = 'G5200V26'
       AND length(nw.geo_id) = 4
       AND substr(nw.geo_id, 1, 2) = $1
       ${severeCond}
       AND public.ST_Area(public.ST_Intersection(nw.geometry, old.geometry)) > $3
     ORDER BY diff_area DESC
     LIMIT 5`,
    [cfg.fips, cfg.severe.length ? cfg.severe : ['__none__'], MIN_DIFF_AREA]
  );

  for (const r of rows) {
    // Post-verify the candidate point genuinely flips sides under both vintages.
    const chk = await pool.query(
      `SELECT
         (SELECT gb.geo_id FROM essentials.geofence_boundaries gb
           WHERE gb.mtfcc = 'G5200' AND length(gb.geo_id) = 4 AND substr(gb.geo_id, 1, 2) = $3
             AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326))
           LIMIT 1) AS old_covering,
         (SELECT gb.geo_id FROM essentials.geofence_boundaries gb
           WHERE gb.mtfcc = 'G5200V26' AND length(gb.geo_id) = 4 AND substr(gb.geo_id, 1, 2) = $3
             AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326))
           LIMIT 1) AS new_covering`,
      [r.lng, r.lat, cfg.fips]
    );
    const { old_covering, new_covering } = chk.rows[0];
    if (new_covering === r.new_geo_id && old_covering === r.old_geo_id && old_covering !== new_covering) {
      return { newGeoId: r.new_geo_id, oldGeoId: r.old_geo_id, lng: +r.lng, lat: +r.lat };
    }
  }
  return null;
}

/** House races surfacing at a coordinate via the live V26-preferring coordinate shape. */
async function surfacingRacesAt(lng: number, lat: number, fips: string): Promise<{ geo_id: string; race_id: string; election_name: string }[]> {
  const { rows } = await pool.query(
    `SELECT DISTINCT d.geo_id, r.id AS race_id, e.name AS election_name
     FROM essentials.elections e
     JOIN essentials.races r ON r.election_id = e.id
     JOIN essentials.offices o ON o.id = r.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     ${VINTAGE_LATERAL}
     WHERE d.district_type = 'NATIONAL_LOWER'
       AND length(d.geo_id) = 4
       AND substr(d.geo_id, 1, 2) = $3
       AND gb.geometry IS NOT NULL
       AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326))
       AND ${VISIBILITY_WINDOW}`,
    [lng, lat, fips]
  );
  return rows;
}

async function main() {
  const failures: string[] = [];
  let processed = 0;
  let skipped = 0;

  for (const cfg of STATES) {
    const v26 = await pool.query(
      `SELECT geo_id FROM essentials.geofence_boundaries
       WHERE mtfcc = 'G5200V26' AND length(geo_id) = 4 AND substr(geo_id, 1, 2) = $1
       ORDER BY geo_id`,
      [cfg.fips]
    );
    if (v26.rows.length === 0) {
      console.log(`SKIP ${cfg.abbr}: no G5200V26 rows yet — no-op`);
      skipped++;
      continue;
    }
    if (v26.rows.length !== cfg.expected) {
      failures.push(`${cfg.abbr}: ${v26.rows.length} G5200V26 rows, expected ${cfg.expected} (partial import)`);
      continue;
    }
    processed++;

    // Does this state have a surfacing general election (race-level asserts possible)?
    const gen = await pool.query(
      `SELECT id FROM essentials.elections WHERE name = $1`,
      [`${cfg.abbr} 2026 Statewide General`]
    );
    const generalEid: string | null = gen.rows[0]?.id ?? null;

    // ------------------------------------------------------------------
    // Layer-2: every V26 district anchor resolves back to itself under
    // explicit G5200V26 resolution.
    // ------------------------------------------------------------------
    for (const { geo_id } of v26.rows) {
      const anchor = await pool.query(
        `SELECT public.ST_X(public.ST_PointOnSurface(geometry)) AS lng,
                public.ST_Y(public.ST_PointOnSurface(geometry)) AS lat
         FROM essentials.geofence_boundaries
         WHERE mtfcc = 'G5200V26' AND geo_id = $1`,
        [geo_id]
      );
      const { lng, lat } = anchor.rows[0];
      const res = await pool.query(
        `SELECT gb.geo_id
         FROM essentials.geofence_boundaries gb
         WHERE gb.mtfcc = 'G5200V26' AND length(gb.geo_id) = 4 AND substr(gb.geo_id, 1, 2) = $3
           AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326))`,
        [lng, lat, cfg.fips]
      );
      if (res.rows.length !== 1 || res.rows[0].geo_id !== geo_id) {
        failures.push(`${cfg.abbr} L2 ${geo_id}: anchor resolved to [${res.rows.map((r) => r.geo_id).join(',')}] (expected exactly ${geo_id})`);
      }
    }
    console.log(`PASS ${cfg.abbr} L2: ${v26.rows.length}/${cfg.expected} V26 district anchors self-resolve`);

    // ------------------------------------------------------------------
    // Layer-3 GUARANTEED differential (NEW district outside the severe set)
    // ------------------------------------------------------------------
    const guaranteed = await discoverDifferential(cfg, 'exclude');
    if (!guaranteed) {
      failures.push(`${cfg.abbr} L3: no non-severe differential point found (old/new maps identical or discovery failed)`);
    } else {
      const { newGeoId, oldGeoId, lng, lat } = guaranteed;
      console.log(`INFO ${cfg.abbr} L3 differential: (${lat.toFixed(4)},${lng.toFixed(4)}) NEW=${newGeoId} OLD=${oldGeoId}`);

      // (b) Reps feed stays OLD vintage: G5200 covering district = OLD B, with a seated rep.
      const reps = await pool.query(
        `SELECT d.geo_id, count(o.id) FILTER (WHERE o.politician_id IS NOT NULL) AS reps
         FROM essentials.geofence_boundaries gb
         JOIN essentials.districts d
           ON d.geo_id = gb.geo_id AND d.district_type = 'NATIONAL_LOWER'
         LEFT JOIN essentials.offices o ON o.district_id = d.id
         WHERE gb.mtfcc = 'G5200' AND length(gb.geo_id) = 4 AND substr(gb.geo_id, 1, 2) = $3
           AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326))
         GROUP BY d.geo_id`,
        [lng, lat, cfg.fips]
      );
      if (reps.rows.length !== 1 || reps.rows[0].geo_id !== oldGeoId) {
        failures.push(`${cfg.abbr} L3 reps-feed: covering OLD district = [${reps.rows.map((r) => r.geo_id).join(',')}] (expected ${oldGeoId})`);
      } else if (+reps.rows[0].reps < 1) {
        failures.push(`${cfg.abbr} L3 reps-feed: OLD ${oldGeoId} has no seated representative office`);
      } else {
        console.log(`PASS ${cfg.abbr} L3 reps-feed: same point still shows OLD ${oldGeoId}'s representative (dual-map holds)`);
      }

      if (generalEid) {
        // (a) Uncached live coordinate path surfaces NEW A's race.
        const races = await surfacingRacesAt(lng, lat, cfg.fips);
        if (races.length !== 1 || races[0].geo_id !== newGeoId) {
          failures.push(`${cfg.abbr} L3 elections: coordinate surfaced [${races.map((r) => `${r.geo_id}@${r.election_name}`).join('; ')}] (expected exactly NEW ${newGeoId})`);
        } else {
          console.log(`PASS ${cfg.abbr} L3 elections: coordinate surfaces NEW ${newGeoId}'s race (${races[0].election_name})`);
        }

        // (c) Connected-tier geo-id path (D-11): corrected (NEW A,'G5200') pair surfaces the race.
        const geoIdPath = await pool.query(
          `SELECT DISTINCT r.id
           FROM essentials.elections e
           JOIN essentials.races r ON r.election_id = e.id
           JOIN essentials.offices o ON o.id = r.office_id
           JOIN essentials.districts d ON d.id = o.district_id
           JOIN unnest($1::text[], $2::text[]) AS gp(geo_id, mtfcc)
             ON gp.geo_id = d.geo_id AND gp.mtfcc = 'G5200' AND d.district_type = 'NATIONAL_LOWER'
           WHERE ${VISIBILITY_WINDOW}`,
          [[newGeoId], ['G5200']]
        );
        if (geoIdPath.rows.length !== 1) {
          failures.push(`${cfg.abbr} L3 Connected geo-id path: corrected (${newGeoId},'G5200') surfaced ${geoIdPath.rows.length} races (expected 1)`);
        } else {
          console.log(`PASS ${cfg.abbr} L3 Connected geo-id path: corrected geo_id ${newGeoId} surfaces the NEW race (D-11)`);
        }
      } else {
        console.log(`INFO ${cfg.abbr} L3: no '${cfg.abbr} 2026 Statewide General' election yet — race-level asserts deferred (boundary differential + RPC probe still run)`);
      }

      // (d) D-11 RPC direct invocation — sentinel row, always ROLLBACK.
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        await client.query(`INSERT INTO auth.users (id) VALUES ($1)`, [SENTINEL_UUID]);
        // A trigger on auth.users auto-creates public.users; guard both anyway.
        await client.query(`INSERT INTO public.users (id) VALUES ($1) ON CONFLICT (id) DO NOTHING`, [SENTINEL_UUID]);
        await client.query(
          `INSERT INTO connect.connected_profiles (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`,
          [SENTINEL_UUID]
        );
        await client.query(`SELECT connect.upsert_user_location($1, $2::float8, $3::float8)`, [SENTINEL_UUID, lat, lng]);
        const rpc = await client.query(`SELECT connect.resolve_congressional_2026($1) AS geo`, [SENTINEL_UUID]);
        const got = rpc.rows[0]?.geo ?? null;
        if (got !== newGeoId) {
          failures.push(`${cfg.abbr} L3 D-11 RPC probe: resolve_congressional_2026 returned ${got === null ? 'NULL' : got} (expected ${newGeoId}) — decrypt/ST_Covers/FIPS-filter/search_path bug`);
        } else {
          console.log(`PASS ${cfg.abbr} L3 D-11 RPC probe: resolve_congressional_2026(sentinel) = ${got} (actual RPC code path, rolled back)`);
        }
      } finally {
        try { await client.query('ROLLBACK'); } catch { /* connection-level failure only */ }
        client.release();
      }
    }

    // ------------------------------------------------------------------
    // Layer-3 SEVERE differential (auto-conditional on withholding state)
    // ------------------------------------------------------------------
    if (cfg.severe.length > 0) {
      const severeDiff = await discoverDifferential(cfg, 'only');
      if (!severeDiff) {
        console.log(`INFO ${cfg.abbr} L3 severe: no severe-district differential point found — skipping severe assertion`);
      } else {
        const { newGeoId, oldGeoId, lng, lat } = severeDiff;
        // Detect the severe race's withholding state from the DB.
        const wh = await pool.query(
          `SELECT e.name
           FROM essentials.races r
           JOIN essentials.elections e ON e.id = r.election_id
           JOIN essentials.offices o ON o.id = r.office_id
           JOIN essentials.districts d ON d.id = o.district_id
           WHERE d.district_type = 'NATIONAL_LOWER' AND d.geo_id = $1`,
          [newGeoId]
        );
        const electionNames: string[] = wh.rows.map((r) => r.name);
        const isSurfacing = electionNames.includes(`${cfg.abbr} 2026 Statewide General`);
        const isWithheld = electionNames.some((n) => n.includes('Polygon Pending'));

        if (isSurfacing) {
          // Post-flip: full differential — NEW severe race surfaces at the point.
          const races = await surfacingRacesAt(lng, lat, cfg.fips);
          if (races.length !== 1 || races[0].geo_id !== newGeoId) {
            failures.push(`${cfg.abbr} L3 severe (post-flip): expected NEW severe ${newGeoId}'s race, surfaced [${races.map((r) => r.geo_id).join(',')}]`);
          } else {
            console.log(`PASS ${cfg.abbr} L3 severe (post-flip): NEW severe ${newGeoId}'s race surfaces at the differential point (OLD ${oldGeoId})`);
          }
        } else if (isWithheld) {
          // Pre-flip: boundary differential only + ZERO surfacing races at the point.
          const races = await surfacingRacesAt(lng, lat, cfg.fips);
          if (races.length !== 0) {
            failures.push(`${cfg.abbr} L3 severe (withheld): expected ZERO surfacing races at severe differential point, got [${races.map((r) => `${r.geo_id}@${r.election_name}`).join('; ')}] (withholding leaked)`);
          } else {
            console.log(`PASS ${cfg.abbr} L3 severe (withheld): boundary differential NEW=${newGeoId}/OLD=${oldGeoId} proven, zero races surface (correctly withheld)`);
          }
        } else {
          console.log(`INFO ${cfg.abbr} L3 severe: district ${newGeoId} has no race yet — severe assertion deferred`);
        }
      }
    }
  }

  if (failures.length) {
    console.error('FAIL 1641 coordinate smoke:\n  ' + failures.join('\n  '));
    process.exit(1);
  }
  console.log(`\n1641 COORDINATE SMOKE GREEN: ${processed} state(s) fully asserted, ${skipped} skipped (no G5200V26 rows yet).`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
