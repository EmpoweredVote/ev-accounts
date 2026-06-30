/**
 * 150-coordinate-smoke.ts — Phase 150 read-only coordinate-surfacing smoke (TX + NY).
 *
 * Proves that for in-district TX and NY House coordinates, the live getElectionsByCoordinate
 * surfacing join (geofence ST_Covers point -> district -> office -> race within the named
 * state election, NATIONAL_LOWER) returns the resident's House race with its FULL field —
 * >= 2 active candidates AND >= 1 challenger (is_incumbent=false), not just the incumbent
 * (RESEARCH Pitfall-5 / two-path-confusion guard, T-150-32). For the lost-primary seats
 * (TX-2 geo 4802, NY-10 geo 3610, NY-13 geo 3613) it additionally asserts the primary WINNER
 * is the active candidate and the lost incumbent is ABSENT (D-05 / T-150-35).
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A:
 *   JOIN geofence_boundaries gb ON gb.geo_id=d.geo_id
 *     AND (d.mtfcc IS NULL OR d.mtfcc='' OR gb.mtfcc=d.mtfcc)
 *   WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(lng,lat),4326))
 * Centroid per sample district via ST_PointOnSurface(gb.geometry) (a guaranteed interior
 * point), so the point is always covered by its own geofence.
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/150-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface WinnerCheck { geoId: string; winner: string; lostIncumbent: string }
interface StateCfg {
  st: string;
  election: string;
  geoPrefix: string;      // FIPS prefix discriminating this state's House districts
  sampleGeoIds: string[]; // >= 3 spread House districts to surface
  minActive: Record<string, number>; // per-geo override (default 2)
  winners: WinnerCheck[]; // lost-primary seats: winner present, lost incumbent absent
}

const STATES: StateCfg[] = [
  {
    st: 'TX',
    election: 'TX 2026 Statewide General',
    geoPrefix: '48',
    sampleGeoIds: ['4802', '4823', '4838'], // TX-2 (lost-incumbent), TX-23 (open seat), TX-38
    minActive: {},
    winners: [{ geoId: '4802', winner: 'Steve Toth', lostIncumbent: 'Dan Crenshaw' }],
  },
  {
    st: 'NY',
    election: 'NY 2026 Statewide General',
    geoPrefix: '36',
    sampleGeoIds: ['3601', '3610', '3613', '3621'], // NY-1, NY-10 (lost-incumbent), NY-13 (3-cand), NY-21 (3-cand)
    minActive: { '3613': 3, '3621': 3 },
    winners: [
      { geoId: '3610', winner: 'Brad Lander', lostIncumbent: 'Daniel S. Goldman' },
      { geoId: '3613', winner: 'Darializa Avila Chevalier', lostIncumbent: 'Adriano Espaillat' },
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
      // Interior centroid of this state's House district geofence boundary.
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

      // Mirror getElectionsByCoordinate Part A, scoped to this state's House field.
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
      if (chal < 1) { failures.push(`${cfg.st} ${geoId}: 0 challengers — only incumbent surfaced (Pitfall-5)`); ok = false; }
      if (nullpid > 0) { failures.push(`${cfg.st} ${geoId}: ${nullpid} active candidate(s) with NULL politician_id`); ok = false; }

      // D-05: lost-primary seat — winner active, lost incumbent absent.
      const wc = cfg.winners.find((w) => w.geoId === geoId);
      if (wc) {
        if (!names.includes(wc.winner.toLowerCase())) { failures.push(`${cfg.st} ${geoId}: primary winner "${wc.winner}" NOT in active field (D-05)`); ok = false; }
        if (names.includes(wc.lostIncumbent.toLowerCase())) { failures.push(`${cfg.st} ${geoId}: lost incumbent "${wc.lostIncumbent}" present as active (D-05)`); ok = false; }
      }

      if (ok) {
        surfaced++;
        const tag = wc ? ` [winner=${wc.winner}, ${wc.lostIncumbent} absent]` : '';
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
  console.log(`\nCOORDINATE SMOKE GREEN: ${totalSurfaced} TX+NY House districts surface their full field (>=2 active incl. >=1 challenger; lost-primary winners present, lost incumbents absent).`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
