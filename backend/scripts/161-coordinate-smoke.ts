/**
 * 161-coordinate-smoke.ts — Phase 161 read-only coordinate-surfacing smoke (WA/AZ/TN/MA).
 *
 * Proves that for one in-district US House coordinate per Phase-161 state (AZ/WA/TN/MA),
 * the live getElectionsByCoordinate surfacing join (geofence ST_Covers point -> district ->
 * office -> race within each state's election, NATIONAL_LOWER) returns the resident's House
 * race with the full challenger-inclusive candidate field -- >= minActive active candidates
 * AND >= 1 challenger (is_incumbent=false), not just the incumbent (Pitfall-5 two-path guard).
 *
 * All four positive samples are contested districts (incumbent + >=1 challenger):
 *   AZ geoId '0401' (AZ-1, 9 active / 9 challengers -- open seat, Schweikert retired)
 *   WA geoId '5301' (WA-1, 7 active / 6 challengers)
 *   TN geoId '4701' (TN-1, NON-SEVERE, 9 active / 8 challengers -- surfaces via TN 2026
 *                    Statewide General)
 *   MA geoId '2501' (MA-1, 3 active / 2 challengers -- pre-existing race, reused)
 *
 * NEW this phase (no prior precedent): a negative-result sample proving the TN severe-
 * district withholding mechanism (161-01/161-06, D-01b) works end-to-end -- a coordinate
 * inside TN-9 (geo_id '4709', the dismantled ex-Cohen seat, one of the 5 severity-routed
 * districts per 161-tn-correspondence-audit.md's "Severe geo_id list: 4704, 4705, 4706,
 * 4708, 4709") must surface ZERO House races when the surfacing query is scoped to the
 * live/surfacing 'TN 2026 Statewide General' election (the severe race's real election_id
 * is the withheld 'TN 2026 Congressional Redistricting - Polygon Pending' row, which
 * electionService.ts's ELECTION_VISIBILITY_WINDOW never returns).
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A:
 *   JOIN geofence_boundaries gb ON gb.geo_id=d.geo_id
 *     AND (d.mtfcc IS NULL OR d.mtfcc='' OR gb.mtfcc=d.mtfcc)
 *   WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(lng,lat),4326))
 * Centroid per sample district via ST_PointOnSurface(gb.geometry) (a guaranteed interior
 * point), so the point is always covered by its own geofence.
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/161-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface Sample {
  state: 'AZ' | 'WA' | 'TN' | 'MA';
  geoId: string;
  minActive: number;
}

const STATE_CONFIG: Record<string, { election: string; geoPrefix: string }> = {
  AZ: { election: 'AZ 2026 Statewide General', geoPrefix: '04' },
  WA: { election: 'WA 2026 Statewide General', geoPrefix: '53' },
  TN: { election: 'TN 2026 Statewide General', geoPrefix: '47' }, // surfacing election only (severe races live on the withheld election)
  MA: { election: '2026 Massachusetts General Election', geoPrefix: '25' },
};

const SAMPLES: Sample[] = [
  { state: 'AZ', geoId: '0401', minActive: 2 }, // AZ-1, open seat, contested
  { state: 'WA', geoId: '5301', minActive: 2 }, // WA-1, contested
  { state: 'TN', geoId: '4701', minActive: 2 }, // TN-1, NON-SEVERE, contested
  { state: 'MA', geoId: '2501', minActive: 2 }, // MA-1, contested (pre-existing race)
];

// Severe TN negative sample: TN-9 (ex-Cohen seat), one of the 5 severity-routed districts.
const SEVERE_TN_GEO_ID = '4709';

const MIN_DISTRICTS = 4;

async function main() {
  // Resolve all four state election ids up front by exact name.
  const eids: Record<string, string> = {};
  for (const [st, cfg] of Object.entries(STATE_CONFIG)) {
    const row = (await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [cfg.election])).rows[0];
    if (!row) throw new Error(`FAIL: election not found: ${cfg.election}`);
    eids[st] = row.id;
  }

  const failures: string[] = [];
  let surfaced = 0;

  // ==========================================================================
  // Positive samples: AZ / WA / TN(non-severe) / MA each surface their House race with a
  // challenger-inclusive field.
  // ==========================================================================
  for (const s of SAMPLES) {
    const cfg = STATE_CONFIG[s.state];
    const eid = eids[s.state];

    // Interior centroid of this district's NATIONAL_LOWER geofence boundary.
    const pt = await pool.query(
      `SELECT public.ST_X(public.ST_PointOnSurface(gb.geometry)) AS lng,
              public.ST_Y(public.ST_PointOnSurface(gb.geometry)) AS lat
       FROM essentials.geofence_boundaries gb
       JOIN essentials.districts d
         ON d.geo_id = gb.geo_id AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
       WHERE gb.geo_id = $1 AND d.district_type = 'NATIONAL_LOWER' AND gb.geometry IS NOT NULL
       LIMIT 1`,
      [s.geoId]
    );
    if (!pt.rows.length) {
      failures.push(`${s.state} ${s.geoId}: no NATIONAL_LOWER geofence boundary`);
      continue;
    }
    const { lng, lat } = pt.rows[0];

    // Mirror getElectionsByCoordinate Part A -- ST_Covers join, scoped to this state's election.
    const surf = await pool.query(
      `SELECT r.id AS race_id,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active') AS active_cands,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.is_incumbent = false) AS challengers,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.politician_id IS NULL) AS null_pid
       FROM essentials.races r
       JOIN essentials.offices o ON o.id = r.office_id
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.geofence_boundaries gb
         ON gb.geo_id = d.geo_id AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
       LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
       WHERE r.election_id = $1
         AND d.district_type = 'NATIONAL_LOWER'
         AND substr(d.geo_id, 1, 2) = $4
         AND gb.geometry IS NOT NULL
         AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($2::float8, $3::float8), 4326))
       GROUP BY r.id`,
      [eid, lng, lat, cfg.geoPrefix]
    );

    if (!surf.rows.length) {
      failures.push(`${s.state} ${s.geoId}: coordinate (${(+lat).toFixed(4)},${(+lng).toFixed(4)}) surfaced NO House race`);
      continue;
    }

    const row = surf.rows[0];
    const active = +row.active_cands;
    const chal = +row.challengers;
    const nullpid = +row.null_pid;
    let ok = true;

    if (surf.rows.length > 1) {
      failures.push(`${s.state} ${s.geoId}: matched ${surf.rows.length} House races (expected 1)`);
      ok = false;
    }
    if (active < s.minActive) {
      failures.push(`${s.state} ${s.geoId}: only ${active} active candidate(s) (expected >= ${s.minActive})`);
      ok = false;
    }
    if (chal < 1) {
      failures.push(`${s.state} ${s.geoId}: 0 challengers -- only incumbent surfaced (Pitfall-5)`);
      ok = false;
    }
    if (nullpid > 0) {
      failures.push(`${s.state} ${s.geoId}: ${nullpid} active candidate(s) with NULL politician_id`);
      ok = false;
    }

    if (ok) {
      surfaced++;
      console.log(`PASS ${s.state} ${s.geoId}: 1 House race -- ${active} active, ${chal} challenger(s), 0 null pid [contested]`);
    }
  }

  // ==========================================================================
  // NEW negative sample: a coordinate inside a SEVERE TN district (TN-9, geo_id 4709) must
  // surface ZERO House races when scoped to the surfacing TN election. Proves the D-01b
  // election_id-substitution withholding mechanism works end-to-end (not just verified by
  // SQL inspection in 161-verify.sql, but via the actual coordinate-surfacing query path).
  // ==========================================================================
  const negPt = await pool.query(
    `SELECT public.ST_X(public.ST_PointOnSurface(gb.geometry)) AS lng,
            public.ST_Y(public.ST_PointOnSurface(gb.geometry)) AS lat
     FROM essentials.geofence_boundaries gb
     JOIN essentials.districts d
       ON d.geo_id = gb.geo_id AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
     WHERE gb.geo_id = $1 AND d.district_type = 'NATIONAL_LOWER' AND gb.geometry IS NOT NULL
     LIMIT 1`,
    [SEVERE_TN_GEO_ID]
  );
  if (!negPt.rows.length) {
    failures.push(`TN ${SEVERE_TN_GEO_ID} (severe negative sample): no NATIONAL_LOWER geofence boundary`);
  } else {
    const { lng, lat } = negPt.rows[0];
    const negSurf = await pool.query(
      `SELECT r.id AS race_id
       FROM essentials.races r
       JOIN essentials.offices o ON o.id = r.office_id
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.geofence_boundaries gb
         ON gb.geo_id = d.geo_id AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
       WHERE r.election_id = $1
         AND d.district_type = 'NATIONAL_LOWER'
         AND substr(d.geo_id, 1, 2) = '47'
         AND gb.geometry IS NOT NULL
         AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($2::float8, $3::float8), 4326))`,
      [eids.TN, lng, lat]
    );
    if (negSurf.rows.length > 0) {
      failures.push(`TN ${SEVERE_TN_GEO_ID} (severe negative sample): expected ZERO House races on the surfacing election, got ${negSurf.rows.length} (withholding leaked)`);
    } else {
      console.log(`PASS TN ${SEVERE_TN_GEO_ID} (severe negative sample): coordinate (${(+lat).toFixed(4)},${(+lng).toFixed(4)}) surfaced ZERO House races on TN 2026 Statewide General -- D-01b withholding confirmed end-to-end`);
    }
  }

  if (failures.length) {
    console.error('FAIL coordinate smoke:\n  ' + failures.join('\n  '));
    process.exit(1);
  }
  if (surfaced < MIN_DISTRICTS) {
    console.error(`FAIL: only ${surfaced} of ${MIN_DISTRICTS} states surfaced cleanly (need all ${MIN_DISTRICTS})`);
    process.exit(1);
  }
  console.log(`\nCOORDINATE SMOKE GREEN: ${surfaced}/4 states surface their US House race with full challenger-inclusive field (AZ/WA/TN/MA), AND the severe TN negative sample correctly surfaces zero races.`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
