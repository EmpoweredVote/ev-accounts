/**
 * 149-coordinate-smoke.ts — Phase 149 read-only coordinate-surfacing smoke.
 *
 * Proves that for in-district CA House coordinates, the live getElectionsByCoordinate
 * surfacing join (geofence ST_Covers point -> district -> office -> race in election
 * 728d0074, NATIONAL_LOWER) returns the resident's House race with its FULL field —
 * >= 2 active candidates AND >= 1 challenger (is_incumbent=false), not just the incumbent
 * (RESEARCH Pitfall-5 / T-149-17 two-path confusion guard).
 *
 * SELECT-only. Mirrors src/lib/electionService.ts getElectionsByCoordinate Part A:
 *   JOIN geofence_boundaries gb ON gb.geo_id=d.geo_id
 *     AND (d.mtfcc IS NULL OR d.mtfcc='' OR gb.mtfcc=d.mtfcc)
 *   WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(lng,lat),4326))
 * Centroid per sample district via ST_PointOnSurface(gb.geometry) (a guaranteed
 * interior point), so the point is always covered by its own geofence.
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/149-coordinate-smoke.ts
 */
import { pool } from '../src/lib/db.js';

const SAMPLE_GEO_IDS = ['0602', '0617', '0625', '0640', '0652']; // spread N->S CA House
const MIN_DISTRICTS = 3;

async function main() {
  const eid = (
    await pool.query("SELECT id FROM essentials.elections WHERE id::text LIKE '728d0074%'")
  ).rows[0]?.id;
  if (!eid) throw new Error('FAIL: CA 2026 Statewide General election (728d0074-...) not found');

  let surfaced = 0;
  const failures: string[] = [];

  for (const geoId of SAMPLE_GEO_IDS) {
    // Interior centroid of this CA House district's geofence boundary.
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
      failures.push(`${geoId}: no NATIONAL_LOWER geofence boundary found`);
      continue;
    }
    const { lng, lat } = pt.rows[0];

    // Mirror getElectionsByCoordinate Part A, scoped to the CA House field.
    const surf = await pool.query(
      `SELECT r.id AS race_id,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active') AS active_cands,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.is_incumbent = false) AS challengers,
              COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.politician_id IS NULL) AS null_pid
       FROM essentials.races r
       JOIN essentials.offices o ON o.id = r.office_id
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.geofence_boundaries gb
         ON gb.geo_id = d.geo_id
        AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
       LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
       WHERE r.election_id = $1
         AND d.district_type = 'NATIONAL_LOWER'
         AND substr(d.geo_id, 1, 2) = '06'
         AND gb.geometry IS NOT NULL
         AND public.ST_Covers(
           gb.geometry,
           public.ST_SetSRID(public.ST_MakePoint($2::float8, $3::float8), 4326)
         )
       GROUP BY r.id`,
      [eid, lng, lat]
    );

    if (!surf.rows.length) {
      failures.push(`${geoId}: coordinate (${(+lat).toFixed(4)},${(+lng).toFixed(4)}) surfaced NO CA House race`);
      continue;
    }
    const row = surf.rows[0];
    const active = +row.active_cands, chal = +row.challengers, nullpid = +row.null_pid;
    if (surf.rows.length > 1) failures.push(`${geoId}: matched ${surf.rows.length} CA House races (expected 1)`);
    if (active < 2) failures.push(`${geoId}: only ${active} active candidate(s) (expected >= 2)`);
    if (chal < 1) failures.push(`${geoId}: 0 challengers — only incumbent surfaced (Pitfall-5)`);
    if (nullpid > 0) failures.push(`${geoId}: ${nullpid} active candidate(s) with NULL politician_id`);
    if (active >= 2 && chal >= 1 && nullpid === 0 && surf.rows.length === 1) {
      surfaced++;
      console.log(`PASS ${geoId}: surfaced 1 CA House race — ${active} active, ${chal} challenger(s), 0 null pid`);
    }
  }

  if (failures.length) {
    console.error('FAIL coordinate smoke:\n  ' + failures.join('\n  '));
    process.exit(1);
  }
  if (surfaced < MIN_DISTRICTS) {
    console.error(`FAIL: only ${surfaced} districts surfaced cleanly (need >= ${MIN_DISTRICTS})`);
    process.exit(1);
  }
  console.log(`\nCOORDINATE SMOKE GREEN: ${surfaced}/${SAMPLE_GEO_IDS.length} CA House districts surface their full field (>=2 active incl. >=1 challenger).`);
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
