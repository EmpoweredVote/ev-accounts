#!/usr/bin/env node
/**
 * Fail if essentials.geofence_child_county is behind essentials.geofence_boundaries.
 *
 * WHY THIS EXISTS. Migration 1696 persisted the child -> county spatial assignment into a
 * materialized view, because recomputing it per request was 15.9 s of ST_Area(ST_Intersection(...))
 * across the 13 tracked states and the largest single cost in /api/admin/coverage/map (cold load
 * 24.7 s -> 0.7 s in prod). The assignment depends only on geometry, so it is correct until
 * boundaries are loaded — and then it is stale until somebody runs:
 *
 *     REFRESH MATERIALIZED VIEW CONCURRENTLY essentials.geofence_child_county;
 *
 * NOTHING ENFORCED THAT, AND ASKING NICELY FAILED TWICE. 52 scripts insert into
 * essentials.geofence_boundaries, so there is no single loader to hook, and a trigger on a bulk
 * geometry load is its own problem. The read path already degrades safely — an unmapped child gets
 * a NULL county rather than being dropped — and warns in the API log. But a warning in a log
 * nobody tails is not a guard, and the symptom is quiet: a newly loaded city silently sits outside
 * its county on the coverage dashboard.
 *
 * ⭐ SINCE CC_0135 the main offender refreshes itself: load-state-tiger-boundaries calls
 * essentials.refresh_geofence_child_county() (SECURITY DEFINER, because loaders connect as ev_api
 * and REFRESH needs ownership) whenever a run inserted a boundary. The other 51 scripts still do
 * not, which is why this check remains the backstop rather than being retired.
 *
 * 🔴 WHAT IT COST BEFORE THAT: the 2026-09-18..20 loads added 5,155 children and this job failed
 * SIX consecutive nightlies (09-18..09-23) before anyone refreshed. It was reporting correctly the
 * whole time. The 2026-08-14 Washington load did the same on a smaller scale.
 *
 * So this asks the only question that matters: does every child boundary have a mapping row?
 *
 * ZERO TOLERANCE, NO BASELINE FILE. Unlike check:reachability, which is baselined per
 * state|district_type because it guards a known backlog, the correct value here is 0 and it is
 * achievable in one command. A baseline would just be somewhere to hide a stale view.
 *
 * ⚠ NIGHTLY ONLY — NOT ON PUSH. This header used to say "it runs on master pushes and on the daily
 * schedule"; the job moved to schedule-only on 2026-08-26 (.github/workflows/ci.yml, job
 * `child-county`) because what makes the matview stale is a boundary load, which happens on the
 * calendar and not on our commits. The practical consequence is worth stating plainly: after a
 * load, nothing tells you for up to a day. Run it yourself — `npm run check:child-county`.
 * It skips itself green when DATABASE_URL is absent (forks) rather than failing.
 *
 * Usage:
 *   node scripts/check-child-county-mapping.mjs              # gate
 *   node scripts/check-child-county-mapping.mjs --verbose    # list every unmapped child
 */
import 'dotenv/config';
import { Pool } from 'pg';

const VERBOSE = process.argv.includes('--verbose');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const REFRESH_HINT =
  // ⚠ Both halves of the old note were wrong, measured 2026-09-24 on prod: it takes ~31 s, not
  //   ~17 s (that figure is migration 1696's and is what makes ev_api's 30 s statement_timeout
  //   look like headroom), and CONCURRENTLY runs fine inside a transaction — that restriction
  //   belongs to CREATE INDEX CONCURRENTLY. Run it as postgres, which owns the matview.
  'REFRESH MATERIALIZED VIEW CONCURRENTLY essentials.geofence_child_county;   -- ~31 s, as postgres';

(async () => {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    process.exit(0);
  }

  // The view existing at all is a precondition, not a detail: if it were dropped, the coverage
  // read path would 500 on a missing relation. Say that plainly rather than erroring on a query.
  const { rows: exists } = await pool.query(`
    SELECT
      (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'essentials' AND c.relname = 'geofence_child_county'
          AND c.relkind = 'm')                                              AS matview,
      (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'essentials' AND c.relname = 'geofence_child_county_stale'
          AND c.relkind = 'v')                                              AS stale_view`);

  if (Number(exists[0].matview) === 0) {
    console.error(
      'FAIL: essentials.geofence_child_county (materialized view) does not exist.\n' +
      'The coverage map read path joins it, so it will 500. Re-apply migration 1696.',
    );
    await pool.end();
    process.exit(1);
  }
  if (Number(exists[0].stale_view) === 0) {
    console.error(
      'FAIL: essentials.geofence_child_county_stale (view) does not exist — this check cannot run.\n' +
      'Re-apply migration 1696.',
    );
    await pool.end();
    process.exit(1);
  }

  const { rows: counts } = await pool.query(`
    SELECT
      (SELECT count(*) FROM essentials.geofence_boundaries
        WHERE mtfcc IN ('G4110','G5420','G5400','G5410'))                   AS children,
      (SELECT count(*) FROM essentials.geofence_child_county)               AS mapped,
      (SELECT count(county_geo_id) FROM essentials.geofence_child_county)    AS assigned,
      (SELECT count(*) FROM essentials.geofence_child_county_stale)          AS stale,
      -- Mapping rows whose child is gone. Harmless (the read path joins FROM boundaries, so these
      -- are never read) but a signal the view predates a boundary deletion. Reported, never fatal.
      (SELECT count(*) FROM essentials.geofence_child_county m
        WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries child
                           WHERE child.geo_id = m.child_geo_id
                             AND child.mtfcc = m.child_mtfcc))              AS orphans`);

  const c = counts[0];
  const stale = Number(c.stale);
  const orphans = Number(c.orphans);

  console.log(
    `children ${c.children} · mapped ${c.mapped} · assigned a county ${c.assigned} · ` +
    `stale ${stale} · orphaned mapping rows ${orphans}`,
  );

  if (orphans > 0) {
    console.log(
      `NOTE: ${orphans} mapping row(s) reference a child boundary that no longer exists. Not a\n` +
      '      failure — the read path never reads them — but a refresh would tidy it up.',
    );
  }

  if (stale === 0) {
    console.log('\nOK — every child boundary has a county mapping.');
    await pool.end();
    process.exit(0);
  }

  const { rows: offenders } = await pool.query(
    `SELECT state, mtfcc, geo_id, name FROM essentials.geofence_child_county_stale
      ORDER BY state, mtfcc, geo_id ${VERBOSE ? '' : 'LIMIT 20'}`,
  );

  console.error(`\nFAIL — ${stale} child boundary/ies have no essentials.geofence_child_county row:\n`);
  for (const o of offenders) {
    console.error(`  state ${o.state}  ${o.mtfcc}  ${o.geo_id}  ${o.name ?? '(no name)'}`);
  }
  if (!VERBOSE && stale > offenders.length) {
    console.error(`  ... and ${stale - offenders.length} more (re-run with --verbose)`);
  }
  console.error(
    '\nThese jurisdictions will show with NO county on the coverage dashboard. Boundaries were\n' +
    'loaded without refreshing the persisted mapping. Fix:\n\n' +
    `  ${REFRESH_HINT}\n`,
  );
  await pool.end();
  process.exit(1);
})().catch(async (err) => {
  console.error('FAIL: check-child-county-mapping errored:', err.message);
  try { await pool.end(); } catch { /* already closed */ }
  process.exit(2);
});
