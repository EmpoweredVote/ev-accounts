/**
 * 163-coordinate-smoke.ts — Phase 163 read-only coordinate-surfacing smoke (WI/CO/AL/SC/LA).
 *
 * Proves that for one in-district US House coordinate per Phase-163 state, the live
 * getElectionsByCoordinate surfacing join (geofence ST_Covers point -> district -> office ->
 * race within each state's SURFACING election, NATIONAL_LOWER) returns the resident's House race
 * with the full challenger-inclusive candidate field -- >= minActive active candidates AND >= 1
 * challenger (is_incumbent=false), not just the incumbent (Pitfall-5 two-path guard).
 *
 * Positive samples (contested, surfacing districts):
 *   WI geoId '5501' (WI-1, Steil + 4 Dem challengers)      surfaces via 'WI 2026 Statewide General'
 *   CO geoId '0808' (CO-8, incumbent + challenger)         surfaces via 'CO 2026 Statewide General'
 *   AL geoId '0101' (AL-1, open, 5 candidates)             surfaces via 'AL 2026 Statewide General'
 *   SC geoId '4501' (SC-1, open, 4 candidates)             surfaces via 'SC 2026 Statewide General'
 *   LA geoId '2205' (LA-5, open jungle field, 12 cands)    surfaces via 'LA 2026 Statewide General'
 *
 * NEW negative samples (mirror 162's MO-severe test): a coordinate inside a SEVERE AL district
 * (AL-2, geo '0102') and a SEVERE LA district (LA-6, geo '2206', Cleo Fields' dissolved
 * majority-Black seat) must each surface ZERO House races when scoped to that state's SURFACING
 * election -- because their real election_id is the withheld 'XX 2026 Congressional Redistricting
 * - Polygon Pending' row, which electionService.ts's ELECTION_VISIBILITY_WINDOW never returns.
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A (ST_Covers).
 * All PostGIS calls use the public. schema prefix.
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/163-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface Sample {
  state: 'WI' | 'CO' | 'AL' | 'SC' | 'LA';
  geoId: string;
  minActive: number;
}

const STATE_CONFIG: Record<string, { election: string; geoPrefix: string }> = {
  WI: { election: 'WI 2026 Statewide General', geoPrefix: '55' },
  CO: { election: 'CO 2026 Statewide General', geoPrefix: '08' },
  AL: { election: 'AL 2026 Statewide General', geoPrefix: '01' }, // surfacing election only (severe AL-2 lives on the withheld election)
  SC: { election: 'SC 2026 Statewide General', geoPrefix: '45' },
  LA: { election: 'LA 2026 Statewide General', geoPrefix: '22' }, // surfacing election only (severe LA-2/LA-6 live on the withheld election)
};

const SAMPLES: Sample[] = [
  { state: 'WI', geoId: '5501', minActive: 2 }, // WI-1, Steil + challengers
  { state: 'CO', geoId: '0808', minActive: 2 }, // CO-8, incumbent + challenger
  { state: 'AL', geoId: '0101', minActive: 2 }, // AL-1, open, contested
  { state: 'SC', geoId: '4501', minActive: 2 }, // SC-1, open, contested
  { state: 'LA', geoId: '2205', minActive: 2 }, // LA-5, open jungle field
];

// Severe negative samples: one severe geo_id per withholding state (AL-2, LA-6).
const SEVERE_NEGATIVES: { state: 'AL' | 'LA'; geoId: string }[] = [
  { state: 'AL', geoId: '0102' }, // AL-2, severity-routed to the withheld election
  { state: 'LA', geoId: '2206' }, // LA-6, Cleo Fields' dissolved seat, severity-routed to the withheld election
];

const MIN_DISTRICTS = 5;

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
  // Positive samples: WI / CO / AL / SC / LA each surface their House race with a
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
  // NEW negative samples: a coordinate inside a SEVERE AL district (0102) and a SEVERE LA
  // district (2206) must each surface ZERO House races when scoped to that state's SURFACING
  // election. Proves the D-01b election_id-substitution withholding works end-to-end via the
  // coordinate path for BOTH AL and LA.
  // ==========================================================================
  for (const neg of SEVERE_NEGATIVES) {
    const cfg = STATE_CONFIG[neg.state];
    const eid = eids[neg.state];

    const negPt = await pool.query(
      `SELECT public.ST_X(public.ST_PointOnSurface(gb.geometry)) AS lng,
              public.ST_Y(public.ST_PointOnSurface(gb.geometry)) AS lat
       FROM essentials.geofence_boundaries gb
       JOIN essentials.districts d
         ON d.geo_id = gb.geo_id AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
       WHERE gb.geo_id = $1 AND d.district_type = 'NATIONAL_LOWER' AND gb.geometry IS NOT NULL
       LIMIT 1`,
      [neg.geoId]
    );
    if (!negPt.rows.length) {
      failures.push(`${neg.state} ${neg.geoId} (severe negative sample): no NATIONAL_LOWER geofence boundary`);
      continue;
    }
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
         AND substr(d.geo_id, 1, 2) = $4
         AND gb.geometry IS NOT NULL
         AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($2::float8, $3::float8), 4326))`,
      [eid, lng, lat, cfg.geoPrefix]
    );
    if (negSurf.rows.length > 0) {
      failures.push(`${neg.state} ${neg.geoId} (severe negative sample): expected ZERO House races on the surfacing election, got ${negSurf.rows.length} (withholding leaked)`);
    } else {
      console.log(`PASS ${neg.state} ${neg.geoId} (severe negative sample): coordinate (${(+lat).toFixed(4)},${(+lng).toFixed(4)}) surfaced ZERO House races on ${cfg.election} -- D-01b withholding confirmed end-to-end`);
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
  console.log(`\nCOORDINATE SMOKE GREEN: ${surfaced}/5 states surface their US House race with full challenger-inclusive field (WI/CO/AL/SC/LA), AND the severe AL (0102) + severe LA (2206) negative samples correctly surface zero races.`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
