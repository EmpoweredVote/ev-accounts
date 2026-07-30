#!/usr/bin/env node
/**
 * Fail if a seeded officeholder is unreachable by address search.
 *
 * WHY THIS EXISTS. Between migrations 1495 and 1498 three separate duplicate/reachability defects
 * shipped to prod, and NOT ONE was visible to an existing guard:
 *
 *   1495  LA had two `City Controller` offices; signature was `terms < offices` on one
 *         (district_id, title).
 *   1496  Ten UT cities had two `Mayor` offices each; signature was
 *         `offices > distinct occupants` on one (district_id, title) — the 1495 filter missed it.
 *   1498  28 UT city council seats in six cities (~760k residents) returned NO council member at
 *         all. The duplicates lived on DIFFERENT district_id rows, so BOTH earlier signatures were
 *         blind to it. Geography and occupancy had landed on separate districts rows: the
 *         `council_district:N` row held the active holder but had no geofence, and the `ward:N` row
 *         owned the polygon but its holder was `is_active=false`. Since the reps query filters
 *         `AND (p.is_active = true OR o.is_vacant = true)`, both halves failed independently and
 *         neither row was individually broken enough to notice.
 *
 * `essentials.offices_missing_terms` — the view CLAUDE.md points at for exactly this class — saw
 * none of the three, because in every case the term rows existed and were correct.
 *
 * The only thing that would have caught all three is asking the question a resident asks: does a
 * point inside this district actually return its officeholder? That is what this checks.
 *
 * THE GUARD IS NOT COPIED. The MTFCC → district_type mapping is read out of
 * src/lib/geoIdGuard.ts at runtime, because that mapping is ALREADY duplicated once (geoIdGuard.ts
 * plus an inline copy in getRepresentativesByAddress) and a third copy would rot. If the export
 * cannot be found this script fails loudly rather than guessing.
 *
 * KNOWN DRIFT between those two copies, found while building this (2026-07-30, unfixed): in the
 * `X%` catch-all branch, geoIdGuard.ts allows district_type IN ('LOCAL','COUNTY') while the inline
 * copy at essentialsService.ts:746 also allows 'JUDICIAL' — added for appellate districts whose
 * geometry is a union of counties and so has no TIGER layer (e.g. WI Court of Appeals District II).
 * geoIdGuard.ts is therefore STRICTER than address search, and it backs browse + elections
 * resolution (essentialsBrowseService.ts, electionService.ts), so those paths under-match such
 * districts. This script inherits the stricter mapping, which means an X%-mtfcc JUDICIAL district
 * could in principle be reported UNREACHABLE here while address search resolves it fine. Verified
 * this produces no false positive in the current baseline: the IN judicial rows resolve through the
 * G4000 catch-all, and the two genuinely UNREACHABLE ones (geo_id 1800001/1800002) have no geofence
 * of any kind. Re-check this note if a JUDICIAL bucket ever appears unexpectedly.
 *
 * WHAT IS CHECKED
 *
 *   UNREACHABLE       district has an ACTIVE holder but no geofence row whose mtfcc satisfies the
 *                     guard → nothing a resident types can ever surface this person.
 *                     This is the `council_district:N` half of 1498.   [baselined]
 *   DEAD_GEOGRAPHY    district has a guard-satisfying polygon and offices, but no active holder and
 *                     is not flagged vacant → a polygon that resolves nobody.
 *                     This is the `ward:N` half of 1498.               [baselined]
 *   BAD_GEOMETRY      occupied, reachable district whose polygon is null / invalid / empty.
 *                                                                      [baselined]
 *   REPS_FILTER_HIDDEN  district HAS an active holder, yet the full reps-feed predicate
 *                     (`is_active OR is_vacant`, `is_incumbent`, `NOT ILIKE 'Candidate for%'`)
 *                     returns nothing for it.                          [ZERO TOLERANCE]
 *   ST_COVERS_ROUNDTRIP  the real spatial probe: take ST_PointOnSurface of the district's own
 *                     polygon and run the actual address-search join; the district must come back.
 *                     Exercises guard + geometry + occupancy + reps filters together.
 *                                                                      [ZERO TOLERANCE]
 *
 * WHY SOME CHECKS ARE BASELINED AND NOT ZERO. There is a real pre-existing backlog (40 UNREACHABLE,
 * 28 DEAD_GEOGRAPHY, 5 BAD_GEOMETRY as of 2026-07-30) across CA, IN, DC, MA, FL and UT. Failing red
 * on day one would only train people to ignore this. The baseline is per `state|district_type`, so
 * the gate still fires on GROWTH in a known bucket or on ANY new bucket — which is precisely how
 * 1498 would have been caught (ut|LOCAL would have jumped).
 *
 * A DELIBERATE NON-CHECK: "two districts share a geo_id" looks like the obvious fan-out invariant,
 * and it is NOT usable — ~700 rows match it legitimately (Sacramento keys all 9 council districts
 * to place FIPS 0643000; 504 CA judicial rows carry a NULL geo_id). Measured before writing, not
 * assumed.
 *
 * Needs a live DB, so this does NOT run on every PR like check:migrations / check:occupancy do.
 * See .github/workflows/ci.yml — it runs on master pushes and on a schedule, and skips itself when
 * DATABASE_URL is absent (forks) rather than failing.
 *
 * Usage:
 *   node scripts/check-address-reachability.mjs                  # gate
 *   node scripts/check-address-reachability.mjs --verbose        # list every offending district
 *   node scripts/check-address-reachability.mjs --sample 1000    # widen the spatial probe
 *   node scripts/check-address-reachability.mjs --update-baseline
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const GUARD_SRC = path.join(HERE, '..', 'src', 'lib', 'geoIdGuard.ts');
const BASELINE = path.join(HERE, '..', 'data', 'address-reachability-baseline.json');

const argv = process.argv.slice(2);
const VERBOSE = argv.includes('--verbose');
const UPDATE = argv.includes('--update-baseline');
const sampleIdx = argv.indexOf('--sample');
const SAMPLE = sampleIdx > -1 ? parseInt(argv[sampleIdx + 1], 10) : 500;

// District types that address search resolves GEOGRAPHICALLY. Statewide/national seats
// (STATE_EXEC, NATIONAL_EXEC, NATIONAL_UPPER) are surfaced by the separate statewide branch of
// resolveOfficialsAtPoint and have no district polygon of their own, so including them here would
// report 40+ phantom violations. Learned the hard way while calibrating this.
const ADDRESSABLE = [
  'LOCAL', 'LOCAL_EXEC', 'COUNTY', 'SCHOOL', 'CITY_COUNCIL', 'SCHOOL_BOARD',
  'STATE_UPPER', 'STATE_LOWER', 'NATIONAL_LOWER', 'JUDICIAL', 'STATE_BOARD',
];

/**
 * Pull MTFCC_DISTRICT_TYPE_GUARD out of geoIdGuard.ts so there is exactly one definition of the
 * mapping in play. The fragment expects the (geo_id, mtfcc) source aliased `gp` and
 * essentials.districts aliased `d`.
 */
function loadGuard() {
  const src = readFileSync(GUARD_SRC, 'utf8');
  const m = src.match(/export const MTFCC_DISTRICT_TYPE_GUARD\s*=\s*`([\s\S]*?)`;/);
  if (!m) {
    console.error(
      `FAIL: could not extract MTFCC_DISTRICT_TYPE_GUARD from ${GUARD_SRC}.\n` +
      'Refusing to guess the mapping — re-point this loader at the export instead of copying it.',
    );
    process.exit(2);
  }
  return m[1];
}

const GUARD = loadGuard();
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// One CTE the three baselined checks all read from: per district, is it reachable, does it have a
// usable polygon, and is it occupied?
const CLASSIFY = `
  WITH g AS (
    SELECT d.id, lower(d.state) AS st, d.district_type AS dt, d.label, d.geo_id,
           bool_or(${GUARD}) AS reachable,
           bool_or(gp.geometry IS NOT NULL
                   AND public.ST_IsValid(gp.geometry)
                   AND NOT public.ST_IsEmpty(gp.geometry)) AS good_geom
      FROM essentials.districts d
      LEFT JOIN essentials.geofence_boundaries gp ON gp.geo_id = d.geo_id
     WHERE d.district_type = ANY($1::text[])
     GROUP BY d.id, lower(d.state), d.district_type, d.label, d.geo_id
  ), o AS (
    SELECT g.*,
           count(off.id) AS offices,
           count(*) FILTER (WHERE p.is_active) AS active_holders,
           count(*) FILTER (WHERE off.is_vacant) AS vacant_offices,
           bool_or((p.is_active = true OR off.is_vacant = true)
                   AND coalesce(p.is_incumbent, true) = true
                   AND coalesce(off.title, '') NOT ILIKE 'Candidate for%') AS passes_reps
      FROM g
      JOIN essentials.offices off ON off.district_id = g.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = off.id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id
     GROUP BY g.id, g.st, g.dt, g.label, g.geo_id, g.reachable, g.good_geom
  )
`;

async function classify() {
  const { rows } = await pool.query(
    `${CLASSIFY}
     SELECT 'UNREACHABLE' AS chk, st, dt, label, geo_id FROM o
       WHERE active_holders > 0 AND coalesce(reachable, false) = false
     UNION ALL
     SELECT 'DEAD_GEOGRAPHY', st, dt, label, geo_id FROM o
       WHERE coalesce(reachable, false) = true AND offices > 0
         AND active_holders = 0 AND vacant_offices = 0
     UNION ALL
     SELECT 'BAD_GEOMETRY', st, dt, label, geo_id FROM o
       WHERE active_holders > 0 AND coalesce(reachable, false) = true
         AND coalesce(good_geom, false) = false
     UNION ALL
     SELECT 'REPS_FILTER_HIDDEN', st, dt, label, geo_id FROM o
       WHERE active_holders > 0 AND coalesce(passes_reps, false) = false
     ORDER BY 1, 2, 3, 4`,
    [ADDRESSABLE],
  );
  return rows;
}

/**
 * The spatial probe. For a bounded, deterministic sample of districts that SHOULD be reachable,
 * drop a point inside the district's own polygon and run the real address-search join. Anything
 * that fails to resolve itself is a live hole no set-based check can see.
 */
async function roundTrip() {
  const { rows } = await pool.query(
    `WITH sample AS (
       SELECT d.id AS did, lower(d.state) AS st, d.district_type AS dt, d.label,
              public.ST_PointOnSurface(gp.geometry) AS pt
         FROM essentials.districts d
         JOIN essentials.geofence_boundaries gp ON gp.geo_id = d.geo_id
        WHERE d.district_type = ANY($1::text[])
          AND ${GUARD}
          AND gp.geometry IS NOT NULL
          AND public.ST_IsValid(gp.geometry)
          AND NOT public.ST_IsEmpty(gp.geometry)
          AND EXISTS (SELECT 1 FROM essentials.offices o
                        JOIN essentials.office_current_holder och ON och.office_id = o.id
                        JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active
                       WHERE o.district_id = d.id)
        ORDER BY d.id
        LIMIT $2
     )
     SELECT s.st, s.dt, s.label
       FROM sample s
      WHERE NOT EXISTS (
        SELECT 1
          FROM essentials.geofence_boundaries gp
          JOIN essentials.districts d ON d.geo_id = gp.geo_id AND ${GUARD}
          JOIN essentials.offices o ON o.district_id = d.id
          LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
          LEFT JOIN essentials.politicians p ON p.id = och.politician_id
         WHERE d.id = s.did
           AND (p.is_active = true OR o.is_vacant = true)
           AND coalesce(p.is_incumbent, true) = true
           AND coalesce(o.title, '') NOT ILIKE 'Candidate for%'
           AND public.ST_Covers(gp.geometry, s.pt)
      )
      ORDER BY s.st, s.dt, s.label`,
    [ADDRESSABLE, SAMPLE],
  );
  return rows;
}

const ZERO_TOLERANCE = new Set(['REPS_FILTER_HIDDEN', 'ST_COVERS_ROUNDTRIP']);

function bucketKey(r) {
  return `${r.st || '-'}|${r.dt}`;
}

(async () => {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    process.exit(0);
  }

  const findings = await classify();
  const rt = (await roundTrip()).map((r) => ({ ...r, chk: 'ST_COVERS_ROUNDTRIP' }));
  const all = [...findings, ...rt];

  // observed[check][state|district_type] = count
  const observed = {};
  for (const r of all) {
    observed[r.chk] ??= {};
    observed[r.chk][bucketKey(r)] = (observed[r.chk][bucketKey(r)] ?? 0) + 1;
  }

  if (UPDATE) {
    const payload = {
      _comment:
        'Baseline for check-address-reachability.mjs, keyed check -> "state|district_type" -> count. ' +
        'The gate fires on GROWTH in a bucket or on ANY new bucket. Shrink these numbers as the ' +
        'backlog is worked off; never raise one without saying why in the commit message.',
      _updated: new Date().toISOString().slice(0, 10),
      counts: observed,
    };
    writeFileSync(BASELINE, `${JSON.stringify(payload, null, 2)}\n`);
    console.log(`baseline written to ${path.relative(process.cwd(), BASELINE)}`);
    for (const [chk, buckets] of Object.entries(observed)) {
      const total = Object.values(buckets).reduce((a, b) => a + b, 0);
      console.log(`  ${chk.padEnd(20)} ${String(total).padStart(4)}  ${JSON.stringify(buckets)}`);
    }
    await pool.end();
    process.exit(0);
  }

  let baseline = { counts: {} };
  try {
    baseline = JSON.parse(readFileSync(BASELINE, 'utf8'));
  } catch {
    console.error(
      `FAIL: no baseline at ${path.relative(process.cwd(), BASELINE)}.\n` +
      'Run with --update-baseline once, review the numbers, and commit the file.',
    );
    await pool.end();
    process.exit(2);
  }

  const violations = [];
  const checks = new Set([...Object.keys(observed), ...Object.keys(baseline.counts ?? {})]);

  for (const chk of checks) {
    const obs = observed[chk] ?? {};
    const base = ZERO_TOLERANCE.has(chk) ? {} : (baseline.counts?.[chk] ?? {});
    for (const [bucket, n] of Object.entries(obs)) {
      const allowed = base[bucket] ?? 0;
      if (n > allowed) {
        violations.push({ chk, bucket, n, allowed, isNew: !(bucket in base) });
      }
    }
  }

  console.log(`address reachability — ${all.length} finding(s) across ${checks.size} check(s)`);
  for (const chk of [...checks].sort()) {
    const obs = observed[chk] ?? {};
    const total = Object.values(obs).reduce((a, b) => a + b, 0);
    const baseTotal = Object.values(baseline.counts?.[chk] ?? {}).reduce((a, b) => a + b, 0);
    const tag = ZERO_TOLERANCE.has(chk) ? 'must be 0' : `baseline ${baseTotal}`;
    console.log(`  ${chk.padEnd(20)} observed ${String(total).padStart(4)}   (${tag})`);
  }

  if (VERBOSE) {
    console.log('\nper-district detail:');
    for (const r of all) {
      console.log(`  ${r.chk.padEnd(20)} ${(r.st || '-').padEnd(3)} ${r.dt.padEnd(15)} ${r.label ?? ''}  [${r.geo_id ?? 'geo_id NULL'}]`);
    }
  }

  if (violations.length === 0) {
    console.log('\nOK — nothing regressed. Officeholders reachable by address are at or below baseline.');
    await pool.end();
    process.exit(0);
  }

  console.error('\nFAIL — address-search reachability regressed:\n');
  for (const v of violations) {
    const why = ZERO_TOLERANCE.has(v.chk)
      ? 'zero-tolerance check'
      : v.isNew
        ? 'NEW bucket — this jurisdiction was clean before'
        : `grew from ${v.allowed}`;
    console.error(`  ${v.chk}  ${v.bucket}  observed ${v.n} (${why})`);
  }
  console.error(
    '\nA seeded officeholder that address search cannot reach is invisible to every resident.\n' +
    'Re-run with --verbose to see which districts. If the growth is intentional and understood,\n' +
    'update the baseline in the SAME commit and explain it in the message.',
  );
  await pool.end();
  process.exit(1);
})().catch(async (err) => {
  console.error('FAIL: check-address-reachability errored:', err.message);
  try { await pool.end(); } catch { /* already closed */ }
  process.exit(2);
});
