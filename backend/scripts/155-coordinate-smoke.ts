/**
 * 155-coordinate-smoke.ts — Phase 155 read-only coordinate-surfacing smoke (PA + IL).
 *
 * Proves that for in-district PA and IL House coordinates, the live getElectionsByCoordinate
 * surfacing join (geofence ST_Covers point -> district -> office -> race within the named
 * state election, NATIONAL_LOWER) returns the resident's House race with its FULL field —
 * >= 1 challenger (is_incumbent=false), not just the incumbent (two-path-confusion guard).
 * For the retirement/open seats (PA-3 geo 4203, IL-4 geo 1704, IL-9 geo 1709) it additionally
 * asserts the certified NOMINEE is active and the retired incumbent is ABSENT (D-04).
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A. Interior
 * point per sample district via ST_PointOnSurface(gb.geometry).
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/155-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface WinnerCheck { geoId: string; winner: string; lostIncumbent: string }
interface StateCfg {
  st: string;
  election: string;
  geoPrefix: string;
  sampleGeoIds: string[];
  minActive: Record<string, number>;
  winners: WinnerCheck[];
}

const STATES: StateCfg[] = [
  {
    st: 'PA',
    election: 'PA 2026 Statewide General',
    geoPrefix: '42',
    sampleGeoIds: ['4201', '4203', '4210'], // PA-1 (Fitzpatrick+Harvie), PA-3 (open, Rabb unopposed), PA-10 (Perry+Stelson)
    minActive: { '4203': 1 }, // PA-3 Rabb is unopposed-D (no R qualified); independents deferred
    winners: [{ geoId: '4203', winner: 'Chris Rabb', lostIncumbent: 'Dwight Evans' }],
  },
  {
    st: 'IL',
    election: 'IL 2026 Statewide General',
    geoPrefix: '17',
    sampleGeoIds: ['1701', '1704', '1709'], // IL-1 (Jackson+Maxwell), IL-4 (open, 7-way), IL-9 (open, Biss)
    minActive: { '1704': 3 }, // IL-4 crowded certified general (independents petition directly)
    winners: [
      { geoId: '1704', winner: 'Patty Garcia', lostIncumbent: 'Jesús G. "Chuy" García' },
      { geoId: '1709', winner: 'Daniel Biss', lostIncumbent: 'Janice D. Schakowsky' },
    ],
  },
];

const MIN_DISTRICTS_PER_STATE = 3;

async function main() {
  const failures: string[] = [];
  let totalSurfaced = 0;

  for (const cfg of STATES) {
    const eid = (
      await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [cfg.election])
    ).rows[0]?.id;
    if (!eid) throw new Error(`FAIL: ${cfg.election} election not found`);

    let surfaced = 0;
    for (const geoId of cfg.sampleGeoIds) {
      const pt = await pool.query(
        `SELECT public.ST_X(public.ST_PointOnSurface(gb.geometry)) AS lng,
                public.ST_Y(public.ST_PointOnSurface(gb.geometry)) AS lat
         FROM essentials.geofence_boundaries gb
         JOIN essentials.districts d
           ON d.geo_id = gb.geo_id
          AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
         WHERE gb.geo_id = $1
           AND d.district_type = 'NATIONAL_LOWER'
           AND gb.geometry IS NOT NULL
         LIMIT 1`,
        [geoId]
      );
      if (!pt.rows.length) {
        failures.push(`${cfg.st} ${geoId}: no NATIONAL_LOWER geofence boundary found`);
        continue;
      }
      const { lng, lat } = pt.rows[0];

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
           ON gb.geo_id = d.geo_id
          AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
         LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
         WHERE r.election_id = $1
           AND d.district_type = 'NATIONAL_LOWER'
           AND substr(d.geo_id, 1, 2) = $4
           AND gb.geometry IS NOT NULL
           AND public.ST_Covers(
             gb.geometry,
             public.ST_SetSRID(public.ST_MakePoint($2::float8, $3::float8), 4326)
           )
         GROUP BY r.id`,
        [eid, lng, lat, cfg.geoPrefix]
      );

      if (!surf.rows.length) {
        failures.push(`${cfg.st} ${geoId}: coordinate (${(+lat).toFixed(4)},${(+lng).toFixed(4)}) surfaced NO House race`);
        continue;
      }
      const row = surf.rows[0];
      const active = +row.active_cands, chal = +row.challengers, nullpid = +row.null_pid;
      const names: string[] = row.active_names || [];
      const minActive = cfg.minActive[geoId] ?? 2;
      let ok = true;
      if (surf.rows.length > 1) { failures.push(`${cfg.st} ${geoId}: matched ${surf.rows.length} House races (expected 1)`); ok = false; }
      if (active < minActive) { failures.push(`${cfg.st} ${geoId}: only ${active} active candidate(s) (expected >= ${minActive})`); ok = false; }
      if (chal < 1) { failures.push(`${cfg.st} ${geoId}: 0 challengers — only incumbent surfaced`); ok = false; }
      if (nullpid > 0) { failures.push(`${cfg.st} ${geoId}: ${nullpid} active candidate(s) with NULL politician_id`); ok = false; }

      const wc = cfg.winners.find((w) => w.geoId === geoId);
      if (wc) {
        if (!names.includes(wc.winner.toLowerCase())) { failures.push(`${cfg.st} ${geoId}: certified nominee "${wc.winner}" NOT in active field (D-04)`); ok = false; }
        if (names.includes(wc.lostIncumbent.toLowerCase())) { failures.push(`${cfg.st} ${geoId}: retired incumbent "${wc.lostIncumbent}" present as active (D-04)`); ok = false; }
      }

      if (ok) {
        surfaced++;
        const tag = wc ? ` [nominee=${wc.winner}, ${wc.lostIncumbent} absent]` : '';
        console.log(`PASS ${cfg.st} ${geoId}: surfaced 1 House race — ${active} active, ${chal} challenger(s), 0 null pid${tag}`);
      }
    }

    if (surfaced < MIN_DISTRICTS_PER_STATE) {
      failures.push(`${cfg.st}: only ${surfaced} district(s) surfaced cleanly (need >= ${MIN_DISTRICTS_PER_STATE})`);
    }
    totalSurfaced += surfaced;
  }

  if (failures.length) {
    console.error('FAIL coordinate smoke:\n  ' + failures.join('\n  '));
    process.exit(1);
  }
  console.log(`\nCOORDINATE SMOKE GREEN: ${totalSurfaced} PA+IL House districts surface their full field (>=1 challenger; retirement-seat certified nominees present, retired incumbents absent).`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
