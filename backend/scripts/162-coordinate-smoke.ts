/**
 * 162-coordinate-smoke.ts — Phase 162 read-only coordinate-surfacing smoke (IN/MD/MN/MO).
 *
 * Proves that for one in-district US House coordinate per Phase-162 state (IN/MD/MN/MO), the
 * live getElectionsByCoordinate surfacing join (geofence ST_Covers point -> district -> office
 * -> race within each state's election, NATIONAL_LOWER) returns the resident's House race with
 * the full challenger-inclusive candidate field -- >= minActive active candidates AND >= 1
 * challenger (is_incumbent=false), not just the incumbent (Pitfall-5 two-path guard).
 *
 * Positive samples (contested, surfacing districts):
 *   IN geoId '1801' (IN-1, Mrvan + Regnitz)                    surfaces via 'IN 2026 Statewide General'
 *   MD geoId '2408' (MD-8, Raskin + Riley + Wallace)           surfaces via '2026 Maryland General Election'
 *   MN geoId '2701' (MN-1, Finstad + 4 challengers)            surfaces via 'MN 2026 Statewide General'
 *   MO geoId '2901' (MO-1, NON-SEVERE, contested)              surfaces via 'MO 2026 Statewide General'
 *
 * NEW negative sample (mirrors 161's TN-severe test): a coordinate inside a SEVERE MO district
 * (MO-5, geo_id '2905', the dismantled Cleaver seat -- one of the 5 severity-routed districts
 * per 162-mo-correspondence-audit.md's "Severe geo_id list: 2902, 2903, 2904, 2905, 2906") must
 * surface ZERO House races when scoped to the surfacing 'MO 2026 Statewide General' election
 * (its real election_id is the withheld 'MO 2026 Congressional Redistricting - Polygon Pending'
 * row, which electionService.ts's ELECTION_VISIBILITY_WINDOW never returns).
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A (ST_Covers).
 * All PostGIS calls use the public. schema prefix.
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/162-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface Sample {
  state: 'IN' | 'MD' | 'MN' | 'MO';
  geoId: string;
  minActive: number;
}

const STATE_CONFIG: Record<string, { election: string; geoPrefix: string }> = {
  IN: { election: 'IN 2026 Statewide General', geoPrefix: '18' },
  MD: { election: '2026 Maryland General Election', geoPrefix: '24' },
  MN: { election: 'MN 2026 Statewide General', geoPrefix: '27' },
  MO: { election: 'MO 2026 Statewide General', geoPrefix: '29' }, // surfacing election only (severe races live on the withheld election)
};

const SAMPLES: Sample[] = [
  { state: 'IN', geoId: '1801', minActive: 2 }, // IN-1, Mrvan + Regnitz
  { state: 'MD', geoId: '2408', minActive: 2 }, // MD-8, Raskin + challengers
  { state: 'MN', geoId: '2701', minActive: 2 }, // MN-1, Finstad + challengers
  { state: 'MO', geoId: '2901', minActive: 2 }, // MO-1, NON-SEVERE, contested
];

// Severe MO negative sample: MO-5 (dismantled Cleaver seat), one of the 5 severity-routed districts.
const SEVERE_MO_GEO_ID = '2905';

const MIN_DISTRICTS = 4;

async function main() {
  const eids: Record<string, string> = {};
  for (const [st, cfg] of Object.entries(STATE_CONFIG)) {
    const row = (await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [cfg.election])).rows[0];
    if (!row) throw new Error(`FAIL: election not found: ${cfg.election}`);
    eids[st] = row.id;
  }

  const failures: string[] = [];
  let surfaced = 0;

  // ==========================================================================
  // Positive samples: IN / MD / MN / MO(non-severe) each surface their House race with a
  // challenger-inclusive field.
  // ==========================================================================
  for (const s of SAMPLES) {
    const cfg = STATE_CONFIG[s.state];
    const eid = eids[s.state];

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
  // NEW negative sample: a coordinate inside a SEVERE MO district (MO-5, geo_id 2905) must
  // surface ZERO House races when scoped to the surfacing MO election. Proves the D-01b
  // election_id-substitution withholding mechanism works end-to-end via the coordinate path.
  // ==========================================================================
  const negPt = await pool.query(
    `SELECT public.ST_X(public.ST_PointOnSurface(gb.geometry)) AS lng,
            public.ST_Y(public.ST_PointOnSurface(gb.geometry)) AS lat
     FROM essentials.geofence_boundaries gb
     JOIN essentials.districts d
       ON d.geo_id = gb.geo_id AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
     WHERE gb.geo_id = $1 AND d.district_type = 'NATIONAL_LOWER' AND gb.geometry IS NOT NULL
     LIMIT 1`,
    [SEVERE_MO_GEO_ID]
  );
  if (!negPt.rows.length) {
    failures.push(`MO ${SEVERE_MO_GEO_ID} (severe negative sample): no NATIONAL_LOWER geofence boundary`);
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
         AND substr(d.geo_id, 1, 2) = '29'
         AND gb.geometry IS NOT NULL
         AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($2::float8, $3::float8), 4326))`,
      [eids.MO, lng, lat]
    );
    if (negSurf.rows.length > 0) {
      failures.push(`MO ${SEVERE_MO_GEO_ID} (severe negative sample): expected ZERO House races on the surfacing election, got ${negSurf.rows.length} (withholding leaked)`);
    } else {
      console.log(`PASS MO ${SEVERE_MO_GEO_ID} (severe negative sample): coordinate (${(+lat).toFixed(4)},${(+lng).toFixed(4)}) surfaced ZERO House races on MO 2026 Statewide General -- D-01b withholding confirmed end-to-end`);
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
  console.log(`\nCOORDINATE SMOKE GREEN: ${surfaced}/4 states surface their US House race with full challenger-inclusive field (IN/MD/MN/MO), AND the severe MO negative sample correctly surfaces zero races.`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
