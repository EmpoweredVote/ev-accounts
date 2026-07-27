/**
 * 1642-coordinate-smoke.ts — Phase 164.2 dual-map coordinate smoke (FL/CA/NC/OH/TX).
 *
 * Clone of 1641-coordinate-smoke.ts retargeted to the five enacted-2026 backfill states
 * (all with EMPTY severe sets — there is no seed-and-withhold this phase, so every state's
 * guaranteed differential covers it and the severe branch never runs). The data-driven
 * engine (VINTAGE_LATERAL, discoverDifferential, surfacingRacesAt, the SENTINEL_UUID D-11
 * RPC probe, MIN_DIFF_AREA, VISIBILITY_WINDOW) is reused verbatim.
 *
 * Per state (all have a live '{ABBR} 2026 Statewide General' with the full district count):
 *   - Layer-2: every V26 district anchor (public.ST_PointOnSurface) self-resolves under
 *     explicit G5200V26 resolution.
 *   - Layer-3 GUARANTEED differential: an auto-discovered point in NEW A / OLD B (A!=B)
 *     surfaces NEW A's race on /elections (V26-preferring LATERAL) while the reps-feed live
 *     G5200 ST_Covers still returns OLD B's seated rep (D-02 dual-map holds).
 *   - Layer-3 CONNECTED-TIER geo-id path (D-11) + the always-ROLLBACK sentinel RPC probe
 *     asserting connect.resolve_congressional_2026 returns NEW A (proves Plan 01's IN-list
 *     extension covers these FIPS).
 *   - EXPLICIT 12-anchor block (CA/NC/OH/TX; FL relies on the auto-discovered differential):
 *     each verified anchor must cover NEW under G5200V26, OLD under G5200, OLD!=NEW, and
 *     (where the general race exists) surface exactly the NEW district's race.
 *
 * SELECT-only apart from the always-rolled-back sentinel probe. All PostGIS via public.
 * All inputs parameterized. Run: cd /c/EV-Accounts/backend && set -a && source .env && \
 *   set +a && node --import tsx scripts/1642-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface StateCfg {
  fips: string;
  abbr: string;
  expected: number;      // full district count — partial imports are a hard fail
  severe: string[];      // NEW-district geo_ids whose races may still be withheld (none this phase)
}

const STATES: StateCfg[] = [
  { fips: '12', abbr: 'FL', expected: 28, severe: [] },
  { fips: '06', abbr: 'CA', expected: 52, severe: [] },
  { fips: '37', abbr: 'NC', expected: 14, severe: [] },
  { fips: '39', abbr: 'OH', expected: 15, severe: [] },
  { fips: '48', abbr: 'TX', expected: 38, severe: [] },
];

// Explicit verified anchors (lon,lat -> expected OLD/NEW geo_id) — positive assertions on
// top of the auto-discovered differential. Verified against the imported polygons 2026-07-22.
interface Anchor { abbr: string; fips: string; name: string; lng: number; lat: number; oldGeoId: string; newGeoId: string; }
const ANCHORS: Anchor[] = [
  { abbr: 'CA', fips: '06', name: 'Redding',          lng: -122.3775, lat: 40.5922, oldGeoId: '0601', newGeoId: '0602' },
  { abbr: 'CA', fips: '06', name: 'Palm Springs',     lng: -116.5072, lat: 33.8216, oldGeoId: '0641', newGeoId: '0648' },
  { abbr: 'CA', fips: '06', name: 'Indian Wells',     lng: -116.3397, lat: 33.7133, oldGeoId: '0641', newGeoId: '0648' },
  { abbr: 'NC', fips: '37', name: 'Snow Hill',        lng: -77.6759,  lat: 35.4515, oldGeoId: '3701', newGeoId: '3703' },
  { abbr: 'NC', fips: '37', name: 'Morehead City',    lng: -76.7261,  lat: 34.7226, oldGeoId: '3703', newGeoId: '3701' },
  { abbr: 'NC', fips: '37', name: 'Kill Devil Hills', lng: -75.6676,  lat: 36.0146, oldGeoId: '3703', newGeoId: '3701' },
  { abbr: 'OH', fips: '39', name: 'Wilmington',       lng: -83.8286,  lat: 39.4453, oldGeoId: '3902', newGeoId: '3901' },
  { abbr: 'OH', fips: '39', name: 'Napoleon',         lng: -84.1258,  lat: 41.3920, oldGeoId: '3905', newGeoId: '3909' },
  { abbr: 'OH', fips: '39', name: 'Kent',             lng: -81.3421,  lat: 41.1489, oldGeoId: '3914', newGeoId: '3913' },
  { abbr: 'TX', fips: '48', name: 'Liberty',          lng: -94.7955,  lat: 30.0577, oldGeoId: '4836', newGeoId: '4809' },
  { abbr: 'TX', fips: '48', name: 'Rockwall',         lng: -96.4591,  lat: 32.9297, oldGeoId: '4804', newGeoId: '4832' },
  { abbr: 'TX', fips: '48', name: 'Mission',          lng: -98.3200,  lat: 26.2073, oldGeoId: '4815', newGeoId: '4828' },
];

// Fixed sentinel UUID for the D-11 RPC probe (never committed; rollback-only).
const SENTINEL_UUID = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

// Non-trivial overlap threshold for differential-zone discovery (deg^2; ~1 km^2).
const MIN_DIFF_AREA = 1e-4;

const VISIBILITY_WINDOW = `(
  (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
  OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
)`;

// The V26-preferring LATERAL, cloned from electionService.ts getElectionsByCoordinate.
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

interface Differential { newGeoId: string; oldGeoId: string; lng: number; lat: number; }

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

/** Covering geo_id at a point for a given vintage (G5200 or G5200V26). */
async function coveringAt(lng: number, lat: number, fips: string, mtfcc: string): Promise<string | null> {
  const { rows } = await pool.query(
    `SELECT geo_id FROM essentials.geofence_boundaries
      WHERE mtfcc = $4 AND length(geo_id) = 4 AND substr(geo_id, 1, 2) = $3
        AND public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326))
      LIMIT 1`,
    [lng, lat, fips, mtfcc]
  );
  return rows[0]?.geo_id ?? null;
}

async function main() {
  const failures: string[] = [];
  /** States whose D-11 RPC probe could not run for lack of `auth` privilege. NOT proven. */
  const d11Skipped: string[] = [];
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

    const gen = await pool.query(`SELECT id FROM essentials.elections WHERE name = $1`, [`${cfg.abbr} 2026 Statewide General`]);
    const generalEid: string | null = gen.rows[0]?.id ?? null;

    // Layer-2: every V26 district anchor self-resolves.
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

    // Layer-3 GUARANTEED differential (severe empty → every state covered).
    const guaranteed = await discoverDifferential(cfg, 'exclude');
    if (!guaranteed) {
      failures.push(`${cfg.abbr} L3: no differential point found (old/new maps identical or discovery failed)`);
    } else {
      const { newGeoId, oldGeoId, lng, lat } = guaranteed;
      console.log(`INFO ${cfg.abbr} L3 differential: (${lat.toFixed(4)},${lng.toFixed(4)}) NEW=${newGeoId} OLD=${oldGeoId}`);

      const reps = await pool.query(
        // Occupancy resolves through essentials.office_current_holder (ADR 0002). This query
        // previously counted essentials.offices.politician_id, dropped by ADR 0002 phase 5 /
        // migration 1463, which left this smoke broken at runtime. The view is exactly one row
        // per office, so it cannot fan the group out.
        `SELECT d.geo_id, count(och.politician_id) AS reps
         FROM essentials.geofence_boundaries gb
         JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.district_type = 'NATIONAL_LOWER'
         LEFT JOIN essentials.offices o ON o.district_id = d.id
         LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
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
        const races = await surfacingRacesAt(lng, lat, cfg.fips);
        if (races.length !== 1 || races[0].geo_id !== newGeoId) {
          failures.push(`${cfg.abbr} L3 elections: coordinate surfaced [${races.map((r) => `${r.geo_id}@${r.election_name}`).join('; ')}] (expected exactly NEW ${newGeoId})`);
        } else {
          console.log(`PASS ${cfg.abbr} L3 elections: coordinate surfaces NEW ${newGeoId}'s race (${races[0].election_name})`);
        }

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
        console.log(`INFO ${cfg.abbr} L3: no '${cfg.abbr} 2026 Statewide General' election — race-level asserts deferred`);
      }

      // D-11 RPC direct invocation — sentinel row, always ROLLBACK.
      //
      // REQUIRES A PRIVILEGED ROLE. The probe mints a throwaway auth.users row so
      // connect.upsert_user_location can encrypt a location for it. The least-privileged
      // application role (ev_api) has no USAGE on schema `auth` — correctly so; an app role that
      // could mint auth users would be a security regression. When the connection cannot reach
      // `auth` the probe SKIPS LOUDLY instead of aborting the whole smoke, so the other layers
      // stay citeable. It does NOT count as proven: the summary line refuses to say
      // "fully asserted" when any D-11 probe was skipped.
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        await client.query(`INSERT INTO auth.users (id) VALUES ($1)`, [SENTINEL_UUID]);
        await client.query(`INSERT INTO public.users (id) VALUES ($1) ON CONFLICT (id) DO NOTHING`, [SENTINEL_UUID]);
        await client.query(`INSERT INTO connect.connected_profiles (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`, [SENTINEL_UUID]);
        await client.query(`SELECT connect.upsert_user_location($1, $2::float8, $3::float8)`, [SENTINEL_UUID, lat, lng]);
        const rpc = await client.query(`SELECT connect.resolve_congressional_2026($1) AS geo`, [SENTINEL_UUID]);
        const got = rpc.rows[0]?.geo ?? null;
        if (got !== newGeoId) {
          failures.push(`${cfg.abbr} L3 D-11 RPC probe: resolve_congressional_2026 returned ${got === null ? 'NULL' : got} (expected ${newGeoId}) — Plan 01 IN-list/deploy or decrypt/ST_Covers/search_path bug`);
        } else {
          console.log(`PASS ${cfg.abbr} L3 D-11 RPC probe: resolve_congressional_2026(sentinel) = ${got} (actual RPC code path, rolled back)`);
        }
      } catch (e) {
        // 42501 = insufficient_privilege. Only this is survivable; anything else is a real defect.
        if ((e as { code?: string })?.code === '42501') {
          d11Skipped.push(cfg.abbr);
          console.log(
            `⚠ SKIP ${cfg.abbr} L3 D-11 RPC probe: connection role lacks privilege on schema 'auth' ` +
              `(cannot mint the sentinel auth.users row). D-11 IS NOT PROVEN for ${cfg.abbr} by this run. ` +
              `Re-run with a privileged DATABASE_URL to restore it.`
          );
        } else {
          throw e;
        }
      } finally {
        try { await client.query('ROLLBACK'); } catch { /* connection-level failure only */ }
        client.release();
      }
    }
  }

  // ------------------------------------------------------------------
  // EXPLICIT 12-anchor positive-assertion block (CA/NC/OH/TX).
  // ------------------------------------------------------------------
  for (const a of ANCHORS) {
    const cfg = STATES.find((s) => s.abbr === a.abbr)!;
    const newCov = await coveringAt(a.lng, a.lat, a.fips, 'G5200V26');
    const oldCov = await coveringAt(a.lng, a.lat, a.fips, 'G5200');
    if (newCov !== a.newGeoId) {
      failures.push(`ANCHOR ${a.abbr} ${a.name}: V26-covering ${newCov} != expected NEW ${a.newGeoId}`);
      continue;
    }
    if (oldCov !== a.oldGeoId) {
      failures.push(`ANCHOR ${a.abbr} ${a.name}: G5200-covering ${oldCov} != expected OLD ${a.oldGeoId}`);
      continue;
    }
    if (newCov === oldCov) {
      failures.push(`ANCHOR ${a.abbr} ${a.name}: NEW == OLD (${newCov}) — no differential`);
      continue;
    }
    // (d) the NEW district's race surfaces at the anchor (all 5 states have races).
    const races = await surfacingRacesAt(a.lng, a.lat, a.fips);
    if (races.length !== 1 || races[0].geo_id !== a.newGeoId) {
      failures.push(`ANCHOR ${a.abbr} ${a.name}: surfaced [${races.map((r) => r.geo_id).join(',')}] (expected exactly NEW ${a.newGeoId}'s race)`);
    } else {
      console.log(`PASS ANCHOR ${a.abbr} ${a.name}: OLD ${a.oldGeoId} -> NEW ${a.newGeoId}, NEW race surfaces`);
    }
  }

  if (failures.length) {
    console.error('FAIL 1642 coordinate smoke:\n  ' + failures.join('\n  '));
    process.exit(1);
  }
  if (d11Skipped.length) {
    // Deliberately NOT the word "fully" — a skipped D-11 must never read as a proven D-11.
    console.log(
      `\n1642 COORDINATE SMOKE GREEN (PARTIAL): ${processed} state(s) asserted (Layer-2 + guaranteed ` +
        `Layer-3 + 12 explicit anchors), ${skipped} skipped.` +
        `\n⚠ D-11 RPC probe NOT PROVEN for: ${d11Skipped.join(', ')} — the connection role lacks ` +
        `privilege on schema 'auth', so resolve_congressional_2026's real code path was never ` +
        `exercised. Every other layer is citeable from this run; D-11 is not.`
    );
  } else {
    console.log(`\n1642 COORDINATE SMOKE GREEN: ${processed} state(s) fully asserted (Layer-2 + guaranteed Layer-3 + 12 explicit anchors + D-11 RPC probe), ${skipped} skipped.`);
  }
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
