/**
 * 152-coordinate-smoke.ts — Phase 152 read-only coordinate-surfacing smoke (4 states).
 *
 * Proves that for one in-district US House coordinate per Wave-1 state (CA/TX/FL/NY),
 * the live getElectionsByCoordinate surfacing join (geofence ST_Covers point -> district
 * -> office -> race within each state's 2026 Statewide General election, NATIONAL_LOWER)
 * returns the resident's House race with the full challenger-inclusive candidate field —
 * >= minActive active candidates AND (for contested seats) >= 1 challenger
 * (is_incumbent=false), not just the incumbent (Pitfall-5 two-path guard).
 *
 * All four samples are contested districts (challengers confirmed live 2026-06-30):
 *   CA geoId '0602' (CA-2 Huffman, contested — from 149 smoke)
 *   TX geoId '4807' (TX-7 Fletcher, contested — from 150 smoke precedent)
 *   FL geoId '1201' (FL-1, crowded ~5 — from 151 smoke)
 *   NY geoId '3617' (NY-17 Lawler, contested — from 150 smoke precedent)
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A:
 *   JOIN geofence_boundaries gb ON gb.geo_id=d.geo_id
 *     AND (d.mtfcc IS NULL OR d.mtfcc='' OR gb.mtfcc=d.mtfcc)
 *   WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(lng,lat),4326))
 * Centroid per sample district via ST_PointOnSurface(gb.geometry) (a guaranteed
 * interior point), so the point is always covered by its own geofence.
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/152-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface Sample {
  state: 'CA' | 'TX' | 'NY' | 'FL';
  geoId: string;
  minActive: number;
  contains?: string[];
}

const STATE_CONFIG: Record<string, { election: string; geoPrefix: string }> = {
  CA: { election: 'CA 2026 Statewide General', geoPrefix: '06' },
  TX: { election: 'TX 2026 Statewide General', geoPrefix: '48' },
  FL: { election: 'FL 2026 Statewide General', geoPrefix: '12' },
  NY: { election: 'NY 2026 Statewide General', geoPrefix: '36' },
};

const SAMPLES: Sample[] = [
  { state: 'CA', geoId: '0602', minActive: 2 },   // CA-2 Huffman, contested (from 149 smoke)
  { state: 'TX', geoId: '4807', minActive: 2 },   // TX-7 Fletcher, contested (live-confirmed 2026-06-30: Fletcher + Hale)
  { state: 'FL', geoId: '1201', minActive: 2 },   // FL-1 crowded (~5, from 151 smoke)
  { state: 'NY', geoId: '3617', minActive: 2 },   // NY-17 Lawler, contested (live-confirmed 2026-06-30: Lawler + Conley)
];

const MIN_DISTRICTS = 4;

async function main() {
  // Resolve all four election ids up front by exact name.
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

    // Mirror getElectionsByCoordinate Part A — ST_Covers join, scoped to this state's election.
    const surf = await pool.query(
      `SELECT r.id AS race_id,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active') AS active_cands,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.is_incumbent = false) AS challengers,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.politician_id IS NULL) AS null_pid,
              array_agg(lower(rc.full_name)) FILTER (WHERE rc.candidate_status = 'active') AS active_names
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
    const names: string[] = row.active_names || [];
    let ok = true;

    if (surf.rows.length > 1) {
      failures.push(`${s.state} ${s.geoId}: matched ${surf.rows.length} House races (expected 1)`);
      ok = false;
    }
    if (active < s.minActive) {
      failures.push(`${s.state} ${s.geoId}: only ${active} active candidate(s) (expected >= ${s.minActive})`);
      ok = false;
    }
    if (s.minActive >= 2 && chal < 1) {
      failures.push(`${s.state} ${s.geoId}: 0 challengers — only incumbent surfaced (Pitfall-5)`);
      ok = false;
    }
    if (nullpid > 0) {
      failures.push(`${s.state} ${s.geoId}: ${nullpid} active candidate(s) with NULL politician_id`);
      ok = false;
    }
    for (const want of s.contains || []) {
      if (!names.includes(want.toLowerCase())) {
        failures.push(`${s.state} ${s.geoId}: expected "${want}" in active field, absent`);
        ok = false;
      }
    }

    if (ok) {
      surfaced++;
      const tag = s.contains ? ` [incl. ${s.contains.join(' + ')}]` : (s.minActive === 1 ? ' [uncontested]' : '');
      console.log(`PASS ${s.state} ${s.geoId}: 1 House race — ${active} active, ${chal} challenger(s), 0 null pid${tag}`);
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
  console.log(`\nCOORDINATE SMOKE GREEN: ${surfaced}/4 states surface their US House race with full challenger-inclusive field (CA/TX/NY/FL).`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
