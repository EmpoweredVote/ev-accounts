/**
 * 1642-anon-path-b-check.ts — Phase 164.2-01 Task 2 regression check.
 *
 * Proves the ANONYMOUS Path-B opt-in (the generic V26-preferring JOIN deployed in 164.1,
 * unchanged) resolves the NEW (mtfcc='G5200V26') enacted-2026 congressional district for
 * all five Phase-164.2 states (FL/CA/NC/OH/TX). For each state:
 *   (a) V26 PRESENT + VALID: every G5200V26 district's interior anchor
 *       (public.ST_PointOnSurface) is covered by exactly that same V26 district — the
 *       enacted geometry is resolvable at read time.
 *   (b) GENUINE DIFFERENTIAL: at least one point exists where the V26-covering geo_id
 *       differs from the G5200-covering geo_id — i.e. the enacted map actually moved.
 * Fails hard if any of the five states has 0 (or a partial count of) G5200V26 rows —
 * this check runs AFTER Plan 02's import, so all five must be present.
 *
 * SELECT-only. All PostGIS via public.*; all inputs parameterized. Pool from src/lib/db.
 *
 * Run: cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *   node --import tsx scripts/1642-anon-path-b-check.ts
 */
import { pool } from '../src/lib/db.js';

interface StateCfg { fips: string; abbr: string; expected: number; }

const STATES: StateCfg[] = [
  { fips: '12', abbr: 'FL', expected: 28 },
  { fips: '06', abbr: 'CA', expected: 52 },
  { fips: '37', abbr: 'NC', expected: 14 },
  { fips: '39', abbr: 'OH', expected: 15 },
  { fips: '48', abbr: 'TX', expected: 38 },
];

const MIN_DIFF_AREA = 1e-4; // deg^2 (~1 km^2) — avoids boundary-sliver flapping

async function main() {
  const failures: string[] = [];

  for (const cfg of STATES) {
    const v26 = await pool.query(
      `SELECT geo_id FROM essentials.geofence_boundaries
       WHERE mtfcc = 'G5200V26' AND length(geo_id) = 4 AND substr(geo_id, 1, 2) = $1
       ORDER BY geo_id`,
      [cfg.fips]
    );
    if (v26.rows.length === 0) {
      failures.push(`${cfg.abbr}: 0 G5200V26 rows — Plan 02 import missing for this state`);
      continue;
    }
    if (v26.rows.length !== cfg.expected) {
      failures.push(`${cfg.abbr}: ${v26.rows.length} G5200V26 rows, expected ${cfg.expected} (partial import)`);
      continue;
    }

    // (a) V26 present + valid: each district anchor self-resolves under G5200V26.
    let selfOk = 0;
    for (const { geo_id } of v26.rows) {
      const res = await pool.query(
        `SELECT gb.geo_id
         FROM essentials.geofence_boundaries anchor
         JOIN essentials.geofence_boundaries gb
           ON gb.mtfcc = 'G5200V26' AND length(gb.geo_id) = 4 AND substr(gb.geo_id, 1, 2) = $2
          AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(anchor.geometry))
         WHERE anchor.mtfcc = 'G5200V26' AND anchor.geo_id = $1`,
        [geo_id, cfg.fips]
      );
      if (res.rows.length === 1 && res.rows[0].geo_id === geo_id) selfOk++;
      else failures.push(`${cfg.abbr} (a) ${geo_id}: V26 anchor resolved to [${res.rows.map((r) => r.geo_id).join(',')}] (expected exactly ${geo_id})`);
    }

    // (b) genuine differential: a point where V26-covering != G5200-covering.
    const diff = await pool.query(
      `SELECT nw.geo_id AS new_geo_id, old.geo_id AS old_geo_id,
              public.ST_X(public.ST_PointOnSurface(public.ST_Intersection(nw.geometry, old.geometry))) AS lng,
              public.ST_Y(public.ST_PointOnSurface(public.ST_Intersection(nw.geometry, old.geometry))) AS lat
       FROM essentials.geofence_boundaries nw
       JOIN essentials.geofence_boundaries old
         ON old.mtfcc = 'G5200' AND length(old.geo_id) = 4 AND substr(old.geo_id, 1, 2) = $1
        AND old.geo_id <> nw.geo_id
        AND public.ST_Intersects(nw.geometry, old.geometry)
       WHERE nw.mtfcc = 'G5200V26' AND length(nw.geo_id) = 4 AND substr(nw.geo_id, 1, 2) = $1
         AND public.ST_Area(public.ST_Intersection(nw.geometry, old.geometry)) > $2
       ORDER BY public.ST_Area(public.ST_Intersection(nw.geometry, old.geometry)) DESC
       LIMIT 1`,
      [cfg.fips, MIN_DIFF_AREA]
    );
    if (diff.rows.length === 0) {
      failures.push(`${cfg.abbr} (b): no differential point found — old/new maps identical (wrong-vintage import?)`);
    } else {
      const d = diff.rows[0];
      // Confirm the discovered point genuinely flips under the two vintages.
      const chk = await pool.query(
        `SELECT
           (SELECT geo_id FROM essentials.geofence_boundaries WHERE mtfcc='G5200' AND length(geo_id)=4 AND substr(geo_id,1,2)=$3
              AND public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint($1::float8,$2::float8),4326)) LIMIT 1) AS old_cov,
           (SELECT geo_id FROM essentials.geofence_boundaries WHERE mtfcc='G5200V26' AND length(geo_id)=4 AND substr(geo_id,1,2)=$3
              AND public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint($1::float8,$2::float8),4326)) LIMIT 1) AS new_cov`,
        [d.lng, d.lat, cfg.fips]
      );
      const { old_cov, new_cov } = chk.rows[0];
      if (!new_cov || !old_cov || new_cov === old_cov) {
        failures.push(`${cfg.abbr} (b): differential point did not flip (V26=${new_cov}, G5200=${old_cov})`);
      } else {
        console.log(`PASS ${cfg.abbr}: ${selfOk}/${cfg.expected} V26 anchors self-resolve; differential flips G5200 ${old_cov} -> V26 ${new_cov} at (${(+d.lat).toFixed(4)},${(+d.lng).toFixed(4)})`);
      }
    }
  }

  if (failures.length) {
    console.error('FAIL 1642 anon Path-B check:\n  ' + failures.join('\n  '));
    process.exit(1);
  }
  console.log('\n1642 ANON PATH-B GREEN: all 5 states resolve the enacted (G5200V26) map with a genuine differential.');
  await pool.end();
}

main().catch((e) => { console.error(e); process.exit(1); });
