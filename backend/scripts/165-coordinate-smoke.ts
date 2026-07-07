/**
 * 165-coordinate-smoke.ts — Phase 165 read-only coordinate-surfacing smoke (17 states).
 *
 * Proves that for one contested in-district US House coordinate per Phase-165 state
 * (NV/UT/AK/NM/NE/WV/ID/HI/ME/NH/RI/MT/DE/ND/SD/VT/WY), the live getElectionsByCoordinate
 * surfacing join (geofence ST_Covers point -> district -> office -> race within each state's
 * election, NATIONAL_LOWER) returns the resident's House race with the full challenger-
 * inclusive candidate field — >= minActive active candidates AND >= 1 challenger
 * (is_incumbent=false), not just the incumbent (Pitfall-5 two-path guard).
 *
 * This group has ZERO routine redistricting -> NO severe/negative-sample block. 17 positive
 * samples. UT is the dual-map exception: its samples are anchored on the court-ordered
 * G5200V26 boundaries (mtfcc pinned) under 'UT 2026 Statewide General' — races were born on
 * the 2026 map (164.1-ut-wiring-contract; D-11 resolution prefers V26 for UT).
 * NV and ME surface via their PRE-EXISTING election names (reconciliation reuse, 165-01).
 *
 * Positive samples (contested districts; open seats preferred):
 *   NV '3202' open (Flippo/Benitez-Thompson/Chapman)  UT '4901' open new-SLC (McAdams + 3, V26)
 *   AK '0200' jungle (15)                             NM '3501' (Stansbury + Okpareke)
 *   NE '3102' open (Harding/Powell/Foreman)           WV '5402' (Moore + 3)
 *   ID '1602' (Simpson + 5)                           HI '1501' (Case + 7)
 *   ME '2302' open (Dunlap + LePage)                  NH '3301' open (14)
 *   RI '4402' (Magaziner + 2)                         MT '3001' open (Flint/Forstag/Sheedy)
 *   DE '1000' (McBride + Cooper)                      ND '3800' (Fedorchak + Hammer)
 *   SD '4600' open (Jackley + Gronli)                 VT '5000' (Balint + 3)
 *   WY '5600' open (14)
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A (ST_Covers).
 * All PostGIS calls use the public. schema prefix.
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/165-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface Sample { state: string; geoId: string; minActive: number; }

const STATE_CONFIG: Record<string, { election: string; geoPrefix: string; mtfcc?: string }> = {
  NV: { election: 'NV 2026 Statewide General', geoPrefix: '32' }, // pre-existing races reused (165-01)
  UT: { election: 'UT 2026 Statewide General', geoPrefix: '49', mtfcc: 'G5200V26' }, // dual-map: 2026 court-ordered shapes
  AK: { election: 'AK 2026 Statewide General', geoPrefix: '02' },
  NM: { election: 'NM 2026 Statewide General', geoPrefix: '35' },
  NE: { election: 'NE 2026 Statewide General', geoPrefix: '31' },
  WV: { election: 'WV 2026 Statewide General', geoPrefix: '54' },
  ID: { election: 'ID 2026 Statewide General', geoPrefix: '16' },
  HI: { election: 'HI 2026 Statewide General', geoPrefix: '15' },
  ME: { election: '2026 Maine General Election', geoPrefix: '23' }, // pre-existing election reused (165-01)
  NH: { election: 'NH 2026 Statewide General', geoPrefix: '33' },
  RI: { election: 'RI 2026 Statewide General', geoPrefix: '44' },
  MT: { election: 'MT 2026 Statewide General', geoPrefix: '30' },
  DE: { election: 'DE 2026 Statewide General', geoPrefix: '10' },
  ND: { election: 'ND 2026 Statewide General', geoPrefix: '38' },
  SD: { election: 'SD 2026 Statewide General', geoPrefix: '46' },
  VT: { election: 'VT 2026 Statewide General', geoPrefix: '50' },
  WY: { election: 'WY 2026 Statewide General', geoPrefix: '56' },
};

const SAMPLES: Sample[] = [
  { state: 'NV', geoId: '3202', minActive: 2 }, // NV-2 open (Amodei retired; Chapman pid fixed)
  { state: 'UT', geoId: '4901', minActive: 2 }, // new UT-1 open SLC district (McAdams + 3, G5200V26)
  { state: 'AK', geoId: '0200', minActive: 2 }, // at-large jungle (15)
  { state: 'NM', geoId: '3501', minActive: 2 }, // NM-1 (Stansbury + Okpareke)
  { state: 'NE', geoId: '3102', minActive: 2 }, // NE-2 open (Bacon retired)
  { state: 'WV', geoId: '5402', minActive: 2 }, // WV-2 (Moore + 3)
  { state: 'ID', geoId: '1602', minActive: 2 }, // ID-2 (Simpson + 5)
  { state: 'HI', geoId: '1501', minActive: 2 }, // HI-1 (Case + 7, PROVISIONAL field)
  { state: 'ME', geoId: '2302', minActive: 2 }, // ME-2 open (Dunlap + LePage)
  { state: 'NH', geoId: '3301', minActive: 2 }, // NH-1 open (14)
  { state: 'RI', geoId: '4402', minActive: 2 }, // RI-2 (Magaziner + 2)
  { state: 'MT', geoId: '3001', minActive: 2 }, // MT-1 open (Zinke retired)
  { state: 'DE', geoId: '1000', minActive: 2 }, // at-large (McBride + Cooper)
  { state: 'ND', geoId: '3800', minActive: 2 }, // at-large (Fedorchak + Hammer)
  { state: 'SD', geoId: '4600', minActive: 2 }, // at-large open (Jackley + Gronli)
  { state: 'VT', geoId: '5000', minActive: 2 }, // at-large (Balint + 3)
  { state: 'WY', geoId: '5600', minActive: 2 }, // at-large open (14)
];

const MIN_DISTRICTS = 17;

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
    // UT: pin the boundary vintage to the court-ordered 2026 shapes (G5200V26); others use the
    // standard district-mtfcc join.
    const mtfccJoin = cfg.mtfcc
      ? `gb.mtfcc = '${cfg.mtfcc}'`
      : `(d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)`;

    const pt = await pool.query(
      `SELECT public.ST_X(public.ST_PointOnSurface(gb.geometry)) AS lng,
              public.ST_Y(public.ST_PointOnSurface(gb.geometry)) AS lat
       FROM essentials.geofence_boundaries gb
       JOIN essentials.districts d
         ON d.geo_id = gb.geo_id AND ${mtfccJoin}
       WHERE gb.geo_id = $1 AND d.district_type = 'NATIONAL_LOWER' AND gb.geometry IS NOT NULL
       LIMIT 1`,
      [s.geoId]
    );
    if (!pt.rows.length) {
      failures.push(`${s.state} ${s.geoId}: no NATIONAL_LOWER geofence boundary${cfg.mtfcc ? ` (${cfg.mtfcc})` : ''}`);
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
         ON gb.geo_id = d.geo_id AND ${mtfccJoin}
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
      console.log(`PASS ${s.state} ${s.geoId}: 1 House race -- ${active} active, ${chal} challenger(s), 0 null pid [contested${cfg.mtfcc ? ', ' + cfg.mtfcc : ''}]`);
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
  console.log(`\nCOORDINATE SMOKE GREEN: ${surfaced}/17 states surface their US House race with full challenger-inclusive field (NV/UT/AK/NM/NE/WV/ID/HI/ME/NH/RI/MT/DE/ND/SD/VT/WY).`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
