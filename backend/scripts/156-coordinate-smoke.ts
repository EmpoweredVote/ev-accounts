/**
 * 156-coordinate-smoke.ts — Phase 156 read-only coordinate-surfacing smoke (OH + GA + NC).
 *
 * Proves that for in-district OH, GA, and NC House coordinates, the live getElectionsByCoordinate
 * surfacing join (geofence ST_Covers point -> district -> office -> race within the named state
 * election, NATIONAL_LOWER) returns the resident's House race with its FULL field — >=1 challenger
 * (is_incumbent=false), not just the incumbent (two-path-confusion guard).
 *   - GA-13 (geo 1313) is a TRUE VACANCY: assert Clark + Chavez both active, 0 is_incumbent rows.
 *   - GA-10 (geo 1310) is an OPEN seat: assert certified nominee Houston Gaines active + retired
 *     incumbent Mike Collins ABSENT (D-04).
 *   - NC-6 (geo 3706) samples the McDowell (reused incumbent) + Jefferson field.
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A. Interior point
 * per sample district via ST_PointOnSurface(gb.geometry).
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/156-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface WinnerCheck { geoId: string; winner: string; lostIncumbent: string }
interface VacancyCheck { geoId: string; names: string[] }
interface StateCfg {
  st: string;
  election: string;
  geoPrefix: string;
  sampleGeoIds: string[];
  minActive: Record<string, number>;
  winners: WinnerCheck[];
  vacancies: VacancyCheck[];
}

const STATES: StateCfg[] = [
  {
    st: 'OH',
    election: 'OH 2026 Statewide General',
    geoPrefix: '39',
    sampleGeoIds: ['3901', '3904', '3909'], // OH-1 (Landsman+Conroy+Hancock), OH-4 (Jordan+Kolasinski+Wilson), OH-9 (Kaptur+Merrin+Althaus)
    minActive: {},
    winners: [],
    vacancies: [],
  },
  {
    st: 'GA',
    election: 'GA 2026 Statewide General',
    geoPrefix: '13',
    sampleGeoIds: ['1305', '1310', '1313'], // GA-5 (renominated Williams+Salvesen), GA-10 (open Gaines+DeLancy), GA-13 (VACANCY Clark+Chavez)
    minActive: {},
    winners: [{ geoId: '1310', winner: 'Houston Gaines', lostIncumbent: 'Mike Collins' }],
    vacancies: [{ geoId: '1313', names: ['Jasmine Clark', 'Jonathan Chavez'] }],
  },
  {
    st: 'NC',
    election: 'NC 2026 Statewide General',
    geoPrefix: '37',
    sampleGeoIds: ['3701', '3706', '3709'], // NC-1 (Davis+Buckhout+Bailey), NC-6 (McDowell+Jefferson), NC-9 (Hudson+Ojeda)
    minActive: {},
    winners: [],
    vacancies: [],
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
                COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.is_incumbent = true) AS incumbents,
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
      const active = +row.active_cands, chal = +row.challengers, inc = +row.incumbents, nullpid = +row.null_pid;
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
        if (names.includes(wc.lostIncumbent.toLowerCase())) { failures.push(`${cfg.st} ${geoId}: retired/open incumbent "${wc.lostIncumbent}" present as active (D-04)`); ok = false; }
      }

      const vc = cfg.vacancies.find((v) => v.geoId === geoId);
      if (vc) {
        if (inc !== 0) { failures.push(`${cfg.st} ${geoId}: VACANCY but ${inc} active is_incumbent=true row(s) (D-04-GA13)`); ok = false; }
        for (const n of vc.names) {
          if (!names.includes(n.toLowerCase())) { failures.push(`${cfg.st} ${geoId}: vacancy nominee "${n}" NOT active (D-04-GA13)`); ok = false; }
        }
      }

      if (ok) {
        surfaced++;
        const tag = wc ? ` [nominee=${wc.winner}, ${wc.lostIncumbent} absent]` : vc ? ` [VACANCY: ${vc.names.join('+')}, 0 incumbent]` : '';
        console.log(`PASS ${cfg.st} ${geoId}: surfaced 1 House race — ${active} active, ${chal} challenger(s), ${inc} incumbent, 0 null pid${tag}`);
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
  console.log(`\nCOORDINATE SMOKE GREEN: ${totalSurfaced} OH+GA+NC House districts surface their full field (>=1 challenger; GA-10 open-seat nominee present + retired incumbent absent; GA-13 vacancy Clark+Chavez active with 0 incumbent).`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
