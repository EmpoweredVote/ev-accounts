#!/usr/bin/env node
/**
 * check-ocd-suffixes.mjs — the state-legislative OCD-ID suffix guard.
 *
 * 🔴 THE DEFECT THIS WATCHES FOR. `parseInt('01A', 10)` is `1`. A loader that derives an OCD-ID
 * suffix that way drops the subdistrict letter, so `1A`/`1B`/`1C` all collapse onto
 * `.../sldl:1`. It has happened twice: Minnesota (caught before any row was written, 2026-09-12)
 * and Maryland (84 rows across two tables, repaired by `CC_0113` on 2026-09-16).
 *
 * 🔴🔴 NOTHING ELSE IN CI CAN SEE IT, WHICH IS THE WHOLE REASON THIS EXISTS:
 *
 *   - `essentials.districts` has NO unique constraint on `ocd_id`, so duplicates write silently.
 *   - Address search resolves on `geo_id`, never `ocd_id` — `ocd_id` ROLLS UP, `geo_id` LOOKS UP —
 *     so `check:reachability` and every identity anchor stay green either way.
 *   - `geo_id` itself is never affected: it is the raw TIGER `GEOID` ('2401A'), letter intact.
 *
 *   What it breaks is arithmetic. `federalCoverage.ts` `districtTotalsByState()` counts
 *   `COUNT(DISTINCT ocd_id)` as the state-legislative seat denominator, so Maryland reported
 *   **94 seats for a state with 118** until the repair.
 *
 * ▶ NORTH DAKOTA (slice 12) AND SOUTH DAKOTA (slice 15) HAVE THE SAME SUBDISTRICT SHAPE AND ARE
 *   NOT LOADED YET. The loader is fixed; this asserts it STAYS fixed, against the end state
 *   rather than against the code that wrote it.
 *
 * ── THE CHECK ────────────────────────────────────────────────────────────────────────────────
 *
 * Fails if any STATE_LOWER/STATE_UPPER row has a `geo_id` ending in a letter while its `ocd_id`
 * suffix does not. Both `essentials.districts` and `essentials.geofence_boundaries` are scanned —
 * the boundary table carried identical damage in Maryland and was missing from every write-up of
 * the defect, so leaving it out is exactly the mistake this guard should not repeat.
 *
 * 🔴 IT CARRIES ITS OWN POSITIVE CONTROL. A scan that reports "nothing found" is worthless until
 *    it has been shown finding something, and a read-only CI check cannot plant a row. So the
 *    inverse is measured too: the rows that DO carry a correct lettered suffix. If that count is
 *    zero the query is broken, not the data, and the check fails saying so rather than passing.
 *
 * ⚠ MASSACHUSETTS IS OUT OF SCOPE BY DESIGN. Its 40 `sldu:NaN` rows are a different defect — its
 *   Senate districts are named ("First Essex"), not numbered — with its own decision and its own
 *   migration. This guard tests the LETTER-DROPPING rule only and must not be widened to cover
 *   `NaN`; doing so would silently re-key 40 live rows to make a check pass.
 *
 *   npm run check:ocd-suffixes --prefix backend
 */
import pg from 'pg';

const URL = process.env.DATABASE_URL;
if (!URL) {
  // Forks get no secrets. A deliberate green skip, stated out loud — not a pass.
  console.log(
    'SKIPPED: DATABASE_URL is not set, so state-legislative OCD-ID suffixes could not be checked. ' +
      'Forks get no secrets; this is a deliberate green skip, not a pass.',
  );
  process.exit(0);
}

const SLD = `district_type::text IN ('STATE_LOWER','STATE_UPPER')`;
// A geo_id ending in a letter whose ocd_id suffix does not. `ocd_id <> ''` excludes the one
// NATIONAL_JUDICIAL row whose geo_id is literally 'US' and whose ocd_id is empty — it ends in a
// letter for an unrelated reason and is not a district code.
const DROPPED = `geo_id ~ '[A-Za-z]$' AND ocd_id IS NOT NULL AND ocd_id <> ''
                 AND regexp_replace(ocd_id, '^.*:', '') !~ '[A-Za-z]$'`;
const KEPT = `geo_id ~ '[A-Za-z]$' AND ocd_id IS NOT NULL AND ocd_id <> ''
              AND regexp_replace(ocd_id, '^.*:', '') ~ '[A-Za-z]$'`;

const client = new pg.Client({ connectionString: URL });
await client.connect();

const q = async (sql) => (await client.query(sql)).rows;

const offenders = await q(`
  SELECT 'districts' AS src, state, district_type::text AS dtype, geo_id, ocd_id
    FROM essentials.districts WHERE ${SLD} AND ${DROPPED}
  UNION ALL
  SELECT 'geofence_boundaries', state, mtfcc, geo_id, ocd_id
    FROM essentials.geofence_boundaries WHERE mtfcc IN ('G5210','G5220') AND ${DROPPED}
  ORDER BY 1, 2, 4`);

// 🔴 THE POSITIVE CONTROL. These are the rows the same predicate finds when it is working.
const [ctl] = await q(`
  SELECT
    (SELECT count(*) FROM essentials.districts WHERE ${SLD} AND ${KEPT})                       AS districts_ok,
    (SELECT count(*) FROM essentials.geofence_boundaries WHERE mtfcc IN ('G5210','G5220') AND ${KEPT}) AS boundaries_ok`);

await client.end();

const dOk = Number(ctl.districts_ok);
const bOk = Number(ctl.boundaries_ok);

if (dOk === 0 || bOk === 0) {
  console.error(
    `✗ THE DETECTOR IS BLIND, so "no offenders" would prove nothing.\n` +
      `  Rows carrying a CORRECT lettered suffix: ${dOk} districts, ${bOk} boundaries — expected both > 0.\n` +
      `  Minnesota alone has 134 lettered House districts and Maryland 42, so a zero here means the\n` +
      `  query stopped matching (a column renamed, a district_type value changed), not that the data\n` +
      `  is clean. Fix the query before trusting any verdict from it.`,
  );
  process.exit(1);
}

if (offenders.length) {
  console.error(
    `✗ ${offenders.length} state-legislative row(s) carry a geo_id ending in a letter whose ocd_id drops it.\n` +
      `  This is the parseInt('01A') defect: 1A/1B/1C collapse onto .../sldl:1. Nothing else in CI can\n` +
      `  see it — ocd_id has no unique constraint and address search uses geo_id — but it corrupts the\n` +
      `  seat denominator in federalCoverage.ts. Derive the suffix with src/lib/ocdDistrictSuffix.ts,\n` +
      `  and repair existing rows FROM geo_id (which is never damaged), the way CC_0113 did for MD.\n`,
  );
  for (const r of offenders.slice(0, 25)) {
    console.error(`    ${r.src.padEnd(20)} ${String(r.state).padEnd(4)} ${String(r.dtype).padEnd(12)} ${r.geo_id}  ->  ${r.ocd_id}`);
  }
  if (offenders.length > 25) console.error(`    … and ${offenders.length - 25} more`);
  process.exit(1);
}

console.log(
  `State-legislative OCD-ID suffixes OK — 0 rows drop a geo_id letter; ` +
    `detector proved live against ${dOk} district(s) and ${bOk} boundary row(s) that correctly keep one.`,
);
