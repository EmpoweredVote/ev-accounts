/**
 * 164-coordinate-smoke.ts — Phase 164 read-only coordinate-surfacing smoke (8 states).
 *
 * Proves that for one contested in-district US House coordinate per Phase-164 state
 * (KY/OR/CT/OK/AR/IA/KS/MS), the live getElectionsByCoordinate surfacing join
 * (geofence ST_Covers point -> district -> office -> race within each state's election,
 * NATIONAL_LOWER) returns the resident's House race with the full challenger-inclusive
 * candidate field -- >= minActive active candidates AND >= 1 challenger (is_incumbent=false),
 * not just the incumbent (Pitfall-5 two-path guard).
 *
 * This group has ZERO redistricting -> NO severe/negative-sample block. 8 positive samples.
 *
 * Positive samples (contested districts; open seats preferred where present):
 *   KY '2104' (KY-4 OPEN: Gallrein + 3)          surfaces via 'KY 2026 Statewide General'
 *   OR '4104' (OR-4: Hoyle + DeSpain + Filip)     surfaces via 'OR 2026 General' (reused)
 *   CT '0901' (CT-1: Larson + Bronin + 3)         surfaces via 'CT 2026 Statewide General'
 *   OK '4001' (OK-1 OPEN: Tedford + Croisant)     surfaces via 'OK 2026 Statewide General'
 *   AR '0502' (AR-2: Hill + Chris Jones)          surfaces via 'AR 2026 Statewide General'
 *   IA '1902' (IA-2 OPEN: Mitchell + 3)           surfaces via 'IA 2026 Statewide General'
 *   KS '2004' (KS-4: Estes + 10)                  surfaces via 'KS 2026 Statewide General'
 *   MS '2802' (MS-2: Thompson + Eller + Foster)   surfaces via 'MS 2026 Statewide General'
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A (ST_Covers).
 * All PostGIS calls use the public. schema prefix.
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/164-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface Sample { state: string; geoId: string; minActive: number; }

const STATE_CONFIG: Record<string, { election: string; geoPrefix: string }> = {
  KY: { election: 'KY 2026 Statewide General', geoPrefix: '21' },
  OR: { election: 'OR 2026 General',           geoPrefix: '41' }, // pre-existing races reused (164-03)
  CT: { election: 'CT 2026 Statewide General', geoPrefix: '09' },
  OK: { election: 'OK 2026 Statewide General', geoPrefix: '40' },
  AR: { election: 'AR 2026 Statewide General', geoPrefix: '05' },
  IA: { election: 'IA 2026 Statewide General', geoPrefix: '19' },
  KS: { election: 'KS 2026 Statewide General', geoPrefix: '20' },
  MS: { election: 'MS 2026 Statewide General', geoPrefix: '28' },
};

const SAMPLES: Sample[] = [
  { state: 'KY', geoId: '2104', minActive: 2 }, // KY-4 open (Gallrein + 3)
  { state: 'OR', geoId: '4104', minActive: 2 }, // OR-4 (Hoyle + DeSpain + Filip)
  { state: 'CT', geoId: '0901', minActive: 2 }, // CT-1 (Larson + Bronin + 3)
  { state: 'OK', geoId: '4001', minActive: 2 }, // OK-1 open (Tedford + Croisant)
  { state: 'AR', geoId: '0502', minActive: 2 }, // AR-2 (Hill + Chris Jones)
  { state: 'IA', geoId: '1902', minActive: 2 }, // IA-2 open (Mitchell + 3)
  { state: 'KS', geoId: '2004', minActive: 2 }, // KS-4 (Estes + 10)
  { state: 'MS', geoId: '2802', minActive: 2 }, // MS-2 (Thompson + Eller + Foster)
];

const MIN_DISTRICTS = 8;

async function main() {
  const eids: Record<string, string> = {};
  for (const [st, cfg] of Object.entries(STATE_CONFIG)) {
    const row = (await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [cfg.election])).rows[0];
    if (!row) throw new Error(`FAIL: election not found: ${cfg.election}`);
    eids[st] = row.id;
  }

  const failures: string[] = [];
  let surfaced = 0;

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

    if (surf.rows.length > 1) { failures.push(`${s.state} ${s.geoId}: matched ${surf.rows.length} House races (expected 1)`); ok = false; }
    if (active < s.minActive) { failures.push(`${s.state} ${s.geoId}: only ${active} active candidate(s) (expected >= ${s.minActive})`); ok = false; }
    if (chal < 1) { failures.push(`${s.state} ${s.geoId}: 0 challengers -- only incumbent surfaced (Pitfall-5)`); ok = false; }
    if (nullpid > 0) { failures.push(`${s.state} ${s.geoId}: ${nullpid} active candidate(s) with NULL politician_id`); ok = false; }

    if (ok) {
      surfaced++;
      console.log(`PASS ${s.state} ${s.geoId}: 1 House race -- ${active} active, ${chal} challenger(s), 0 null pid [contested]`);
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
  console.log(`\nCOORDINATE SMOKE GREEN: ${surfaced}/8 states surface their US House race with full challenger-inclusive field (KY/OR/CT/OK/AR/IA/KS/MS).`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
