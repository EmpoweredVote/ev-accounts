/**
 * 151-coordinate-smoke.ts — Phase 151 read-only coordinate-surfacing smoke (FL, single-state).
 *
 * Proves that for in-district FL House coordinates, the live getElectionsByCoordinate surfacing
 * join (geofence ST_Covers point -> district -> office -> race within 'FL 2026 Statewide General',
 * NATIONAL_LOWER, geo prefix '12') returns the resident's House race with its full PROVISIONAL
 * candidate field — >= minActive active candidates AND (for contested seats) >= 1 challenger
 * (is_incumbent=false), not just the incumbent (Pitfall-5 two-path guard). FL-10 (Frost) is
 * uncontested -> minActive override = 1, and its challenger check is skipped (minActive < 2).
 * FL-20 (new open-seat office) additionally asserts the field contains the redistricted reuse
 * incumbent Wasserman Schultz + the NEW record Cherfilus-McCormick.
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A. Centroid per
 * sample district via ST_PointOnSurface(gb.geometry).
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/151-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

interface Sample { geoId: string; minActive: number; contains?: string[] }
const ELECTION = 'FL 2026 Statewide General';
const GEO_PREFIX = '12';
const SAMPLES: Sample[] = [
  { geoId: '1201', minActive: 2 },                                  // FL-1  crowded (~5)
  { geoId: '1210', minActive: 1 },                                  // FL-10 Frost UNCONTESTED
  { geoId: '1219', minActive: 2 },                                  // FL-19 crowded (~14)
  { geoId: '1220', minActive: 2, contains: ['Debbie Wasserman Schultz', 'Sheila Cherfilus-McCormick'] }, // FL-20 open seat
];
const MIN_DISTRICTS = 3;

async function main() {
  const eid = (await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [ELECTION])).rows[0]?.id;
  if (!eid) throw new Error(`FAIL: ${ELECTION} election not found`);

  const failures: string[] = [];
  let surfaced = 0;

  for (const s of SAMPLES) {
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
    if (!pt.rows.length) { failures.push(`FL ${s.geoId}: no NATIONAL_LOWER geofence boundary`); continue; }
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
         ON gb.geo_id = d.geo_id AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
       LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
       WHERE r.election_id = $1
         AND d.district_type = 'NATIONAL_LOWER'
         AND substr(d.geo_id, 1, 2) = $4
         AND gb.geometry IS NOT NULL
         AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($2::float8, $3::float8), 4326))
       GROUP BY r.id`,
      [eid, lng, lat, GEO_PREFIX]
    );

    if (!surf.rows.length) { failures.push(`FL ${s.geoId}: coordinate (${(+lat).toFixed(4)},${(+lng).toFixed(4)}) surfaced NO House race`); continue; }
    const row = surf.rows[0];
    const active = +row.active_cands, chal = +row.challengers, nullpid = +row.null_pid;
    const names: string[] = row.active_names || [];
    let ok = true;
    if (surf.rows.length > 1) { failures.push(`FL ${s.geoId}: matched ${surf.rows.length} House races (expected 1)`); ok = false; }
    if (active < s.minActive) { failures.push(`FL ${s.geoId}: only ${active} active candidate(s) (expected >= ${s.minActive})`); ok = false; }
    if (s.minActive >= 2 && chal < 1) { failures.push(`FL ${s.geoId}: 0 challengers — only incumbent surfaced (Pitfall-5)`); ok = false; }
    if (nullpid > 0) { failures.push(`FL ${s.geoId}: ${nullpid} active candidate(s) with NULL politician_id`); ok = false; }
    for (const want of s.contains || []) {
      if (!names.includes(want.toLowerCase())) { failures.push(`FL ${s.geoId}: expected "${want}" in active field, absent`); ok = false; }
    }

    if (ok) {
      surfaced++;
      const tag = s.contains ? ` [incl. ${s.contains.join(' + ')}]` : (s.minActive === 1 ? ' [uncontested]' : '');
      console.log(`PASS FL ${s.geoId}: 1 House race — ${active} active, ${chal} challenger(s), 0 null pid${tag}`);
    }
  }

  if (failures.length) { console.error('FAIL coordinate smoke:\n  ' + failures.join('\n  ')); process.exit(1); }
  if (surfaced < MIN_DISTRICTS) { console.error(`FAIL: only ${surfaced} FL districts surfaced cleanly (need >= ${MIN_DISTRICTS})`); process.exit(1); }
  console.log(`\nCOORDINATE SMOKE GREEN: ${surfaced}/${SAMPLES.length} FL House districts surface their provisional field (incl. FL-10 uncontested + FL-20 open-seat reuse+new).`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
