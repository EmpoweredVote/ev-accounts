/**
 * 157-coordinate-smoke.ts — Phase 157 read-only coordinate-surfacing smoke (NJ).
 *
 * Proves that for in-district NJ House coordinates, the live getElectionsByCoordinate surfacing join
 * (geofence ST_Covers point -> district -> office -> race within the NJ 2026 Statewide General
 * election, NATIONAL_LOWER) returns the resident's House race with its FULL field. Samples the three
 * NJ wrinkles + one standard contested district:
 *   - NJ-6  (geo 3406): standard renominated contested (Pallone incumbent + Herzig challenger) —
 *                       >=2 active, >=1 challenger.
 *   - NJ-8  (geo 3408): UNCONTESTED single-candidate general — exactly 1 active = Robert Menendez,
 *                       is_incumbent=true, 0 challengers (documented allowance, D-04).
 *   - NJ-11 (geo 3411): special-seated — Analilia Mejia reused active is_incumbent=true + Joe Hathaway
 *                       active challenger.
 *   - NJ-12 (geo 3412): OPEN SEAT (retirement) — Adam Hamawy + Gregg Mele both active, 0 is_incumbent
 *                       rows, retired incumbent Bonnie Watson Coleman ABSENT (retirement, not vacancy —
 *                       no office created).
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A. Interior point per
 * sample district via ST_PointOnSurface(gb.geometry).
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/157-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface Uncontested { geoId: string; who: string }
interface OpenSeat { geoId: string; names: string[]; absent: string }
interface PresentCheck { geoId: string; names: string[] }

const ELECTION = 'NJ 2026 Statewide General';
const GEO_PREFIX = '34';
const SAMPLE_GEO_IDS = ['3406', '3408', '3411', '3412'];
const UNCONTESTED: Uncontested[] = [{ geoId: '3408', who: 'Robert Menendez' }];
const OPEN_SEATS: OpenSeat[] = [
  { geoId: '3412', names: ['Adam Hamawy', 'Gregg Mele'], absent: 'Bonnie Watson Coleman' },
];
const PRESENT: PresentCheck[] = [
  { geoId: '3411', names: ['Analilia Mejia', 'Joe Hathaway'] },
  { geoId: '3406', names: ['Frank Pallone, Jr.', 'Hillary Herzig'] },
];
const MIN_DISTRICTS = 3;

async function main() {
  const failures: string[] = [];
  let surfaced = 0;

  const eid = (
    await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [ELECTION])
  ).rows[0]?.id;
  if (!eid) throw new Error(`FAIL: ${ELECTION} election not found`);

  for (const geoId of SAMPLE_GEO_IDS) {
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
      failures.push(`NJ ${geoId}: no NATIONAL_LOWER geofence boundary found`);
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
      [eid, lng, lat, GEO_PREFIX]
    );

    if (!surf.rows.length) {
      failures.push(`NJ ${geoId}: coordinate (${(+lat).toFixed(4)},${(+lng).toFixed(4)}) surfaced NO House race`);
      continue;
    }
    const row = surf.rows[0];
    const active = +row.active_cands, chal = +row.challengers, inc = +row.incumbents, nullpid = +row.null_pid;
    const names: string[] = row.active_names || [];
    let ok = true;
    if (surf.rows.length > 1) { failures.push(`NJ ${geoId}: matched ${surf.rows.length} House races (expected 1)`); ok = false; }
    if (nullpid > 0) { failures.push(`NJ ${geoId}: ${nullpid} active candidate(s) with NULL politician_id`); ok = false; }

    const unc = UNCONTESTED.find((u) => u.geoId === geoId);
    const open = OPEN_SEATS.find((o) => o.geoId === geoId);

    if (unc) {
      // Uncontested single-candidate general: exactly 1 active = the pinned incumbent, 0 challengers.
      if (active !== 1) { failures.push(`NJ ${geoId}: uncontested expected exactly 1 active, got ${active}`); ok = false; }
      if (inc !== 1) { failures.push(`NJ ${geoId}: uncontested expected 1 is_incumbent=true, got ${inc}`); ok = false; }
      if (!names.includes(unc.who.toLowerCase())) { failures.push(`NJ ${geoId}: uncontested candidate "${unc.who}" NOT active`); ok = false; }
    } else if (open) {
      // Open-seat retirement: >=2 active, 0 incumbents, retired incumbent absent, both nominees present.
      if (active < 2) { failures.push(`NJ ${geoId}: open seat only ${active} active (expected >= 2)`); ok = false; }
      if (inc !== 0) { failures.push(`NJ ${geoId}: open seat but ${inc} active is_incumbent=true row(s) (D-04-NJ12)`); ok = false; }
      if (names.includes(open.absent.toLowerCase())) { failures.push(`NJ ${geoId}: retired incumbent "${open.absent}" present as active (D-04-NJ12)`); ok = false; }
      for (const n of open.names) {
        if (!names.includes(n.toLowerCase())) { failures.push(`NJ ${geoId}: open-seat nominee "${n}" NOT active (D-04-NJ12)`); ok = false; }
      }
    } else {
      // Standard contested: >=2 active, >=1 challenger.
      if (active < 2) { failures.push(`NJ ${geoId}: only ${active} active candidate(s) (expected >= 2)`); ok = false; }
      if (chal < 1) { failures.push(`NJ ${geoId}: 0 challengers — only incumbent surfaced`); ok = false; }
    }

    const pres = PRESENT.find((p) => p.geoId === geoId);
    if (pres) {
      for (const n of pres.names) {
        if (!names.includes(n.toLowerCase())) { failures.push(`NJ ${geoId}: expected active candidate "${n}" NOT in field`); ok = false; }
      }
    }

    if (ok) {
      surfaced++;
      const tag = unc ? ` [UNCONTESTED: ${unc.who} only]`
        : open ? ` [OPEN SEAT: ${open.names.join('+')}, 0 incumbent, ${open.absent} absent]`
        : ` [contested]`;
      console.log(`PASS NJ ${geoId}: surfaced 1 House race — ${active} active, ${chal} challenger(s), ${inc} incumbent, 0 null pid${tag}`);
    }
  }

  if (surfaced < MIN_DISTRICTS) {
    failures.push(`NJ: only ${surfaced} district(s) surfaced cleanly (need >= ${MIN_DISTRICTS})`);
  }

  if (failures.length) {
    console.error('FAIL coordinate smoke:\n  ' + failures.join('\n  '));
    process.exit(1);
  }
  console.log(`\nCOORDINATE SMOKE GREEN: ${surfaced} NJ House districts surface their full field (NJ-6 contested; NJ-8 uncontested Menendez-only; NJ-11 special-seated Mejia+Hathaway; NJ-12 open-seat Hamawy+Mele with 0 incumbent + Watson Coleman absent).`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
