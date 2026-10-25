#!/usr/bin/env node
/**
 * check-chamberless-orphans — tell an ORPHANED office with no chamber apart from a
 * LEGITIMATE one, which is the distinction nothing in this repo could make.
 *
 * THE FAILURE THIS WATCHES. The landing-page browse query reaches an office only through
 * `governments → chambers → offices`, and that middle join is INNER:
 *
 *     FROM essentials.governments g
 *     JOIN essentials.chambers ch ON ch.government_id = g.id
 *     JOIN essentials.offices   o  ON o.chamber_id = ch.id
 *     WHERE g.geo_id = ANY($1)
 *
 * So an office with `chamber_id IS NULL` is invisible to it — silently, with nothing
 * erroring. That is what happened to Wichita: its government row existed, reported 0
 * chambers and 0 offices, and its seven seated officials were dropped from the browse
 * list while address search kept answering perfectly (`CC_0183` attached them).
 *
 * 🔴 BUT A NULL `chamber_id` IS NOT ITSELF A DEFECT, AND MOST OF THEM ARE CORRECT.
 * Measured 2026-10-25: 349 offices carry one. The whole DC Council, DC's State Board of
 * Education, Puerto Rico's 78 municipal mayors and its legislature, the five territory
 * delegates and the two DC shadow senators are all chamber-less and all render. The
 * address and coordinate paths run `districts → offices → office_current_holder` and
 * `LEFT JOIN` the chamber, so they never needed one.
 *
 * ⚠ THE OBVIOUS QUERY IS NOT THE CHECK, AND THE BACKLOG ITEM SAYS SO. "A government with
 * no chambers at all" returns exactly one row — `District of Columbia` — and that is a
 * FALSE POSITIVE. The test has to be about whether a government that SHOULD reach a seat
 * actually can.
 *
 * THE PREDICATE. An office is an orphan when all three hold:
 *   1. `chamber_id IS NULL`               — the browse join cannot reach it;
 *   2. somebody is SEATED in it           — an empty office drops no one;
 *   3. its district's `(mtfcc, geo_id)` matches a `governments` row — i.e. a government
 *      exists that this seat belongs to, so a chip for it SHOULD list this person.
 *
 * Condition 3 is what excludes the legitimate cases without a carve-out, and that is the
 * point: no `governments` row matches Puerto Rico's municipal districts or DC's council
 * districts, so neither was ever going to appear through a chamber and neither is flagged.
 * Wichita satisfied all three. 🔴 The pair `(mtfcc, geo_id)` is the key, never `geo_id`
 * alone — 1,159 geo_id values collide across 13 states.
 *
 * ◐ LATENT ORPHANS ARE REPORTED, NOT FAILED. An UNSEATED chamber-less office whose
 * government exists becomes an orphan the moment anyone seats it. Measured 2026-10-25
 * there are 117, nearly all Monroe County IN. They are printed as a count so the number
 * is watched; they do not fail the check, because nothing is being dropped today.
 *
 * 🔴 POSITIVE CONTROL — THE PROJECT'S RULE FOR ANY DETECTOR THAT REPORTS "NOTHING FOUND",
 * AND THERE IS NO STANDING EXAMPLE TO LEAN ON. Unlike check-rls-coverage, which always has
 * spatial_ref_sys sitting there, a healthy database contains zero orphans — so the control
 * has to be MANUFACTURED. Inside a transaction this script takes a real seated office that
 * HAS a chamber and whose district matches its government, sets `chamber_id = NULL`, and
 * re-runs the detector. If the planted orphan does not appear, the detector is blind and
 * the check ERRORS (exit 2) rather than passing. The transaction is ALWAYS rolled back;
 * this script cannot write.
 *
 * Live-DB check, so like check-rls-coverage and check-spatial-ref-baseline it runs on the
 * daily SCHEDULE, not on push/PR: a commit here applies no migration, so a per-push run
 * would re-read unchanged prod and flag drift the push did not cause. It SKIPS itself
 * green without DATABASE_URL (forks).
 *
 * Exit 0 = no seated office is hidden from its own government (or skipped).
 * Exit 1 = at least one is. Exit 2 = error, including a blind detector.
 *
 * Usage:
 *   node scripts/check-chamberless-orphans.mjs
 *   node scripts/check-chamberless-orphans.mjs --verbose   # also list the latent ones
 */
import 'dotenv/config';
import { Pool } from 'pg';

const VERBOSE = process.argv.includes('--verbose');

/** The detector. `seated` decides fail vs latent; everything else is identical. */
const DETECT_SQL = `
  SELECT o.id            AS office_id,
         o.title,
         g.name          AS government,
         g.geo_id        AS government_geo_id,
         d.label         AS district_label,
         d.district_type,
         p.full_name     AS holder
    FROM essentials.offices o
    JOIN essentials.districts d   ON d.id = o.district_id
    JOIN essentials.governments g ON g.geo_id = d.geo_id
                                 AND g.mtfcc IS NOT DISTINCT FROM d.mtfcc
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.chamber_id IS NULL
     AND och.politician_id IS NOT NULL
   ORDER BY g.name, o.title`;

const LATENT_SQL = `
  SELECT g.name AS government, count(*)::int AS offices
    FROM essentials.offices o
    JOIN essentials.districts d   ON d.id = o.district_id
    JOIN essentials.governments g ON g.geo_id = d.geo_id
                                 AND g.mtfcc IS NOT DISTINCT FROM d.mtfcc
   WHERE o.chamber_id IS NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = o.id AND och.politician_id IS NOT NULL)
   GROUP BY g.name
   ORDER BY offices DESC, g.name`;

/** A seated office that HAS a chamber and whose district matches its government. */
const CONTROL_PICK_SQL = `
  SELECT o.id, o.title, g.name AS government
    FROM essentials.offices o
    JOIN essentials.districts d   ON d.id = o.district_id
    JOIN essentials.governments g ON g.geo_id = d.geo_id
                                 AND g.mtfcc IS NOT DISTINCT FROM d.mtfcc
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.chamber_id IS NOT NULL
     AND och.politician_id IS NOT NULL
   ORDER BY o.id
   LIMIT 1`;

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

(async () => {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    process.exit(0);
  }

  const client = await pool.connect();
  let offenders = [];
  let latent = [];
  let control = null;
  let controlSaw = false;

  try {
    // Everything happens inside one transaction that is ALWAYS rolled back, because the
    // positive control has to write in order to exist.
    await client.query('BEGIN');

    offenders = (await client.query(DETECT_SQL)).rows;
    latent = (await client.query(LATENT_SQL)).rows;

    // ── Positive control: manufacture an orphan and prove the detector sees it.
    const pick = (await client.query(CONTROL_PICK_SQL)).rows[0];
    if (!pick) {
      console.error(
        'FAIL (no control available): could not find a single seated office that has a chamber and\n' +
        'whose district matches a government row. That combination is the normal case, so its absence\n' +
        'means the join itself is wrong. Refusing to report a result.',
      );
      await client.query('ROLLBACK');
      client.release();
      await pool.end();
      process.exit(2);
    }
    control = pick;
    await client.query('UPDATE essentials.offices SET chamber_id = NULL WHERE id = $1', [pick.id]);
    const after = (await client.query(DETECT_SQL)).rows;
    controlSaw = after.some((r) => r.office_id === pick.id);
  } finally {
    // Unconditional: the control must never survive, on any path.
    try { await client.query('ROLLBACK'); } catch { /* connection already gone */ }
    client.release();
  }

  if (!controlSaw) {
    console.error(
      'FAIL (blind detector): a chamber was removed from a real seated office\n' +
      `  ${control.title} — ${control.government}\n` +
      'and the detector did not report it. An empty result therefore says nothing about the database.\n' +
      'Fix the query before trusting a green run. (The change was rolled back; prod is unchanged.)',
    );
    await pool.end();
    process.exit(2);
  }

  const latentTotal = latent.reduce((n, r) => n + r.offices, 0);
  const latentNote = latentTotal === 0
    ? 'no latent ones either'
    : `◐ ${latentTotal} LATENT in ${latent.length} government(s) — unseated today, orphaned the moment anyone seats them`;

  if (offenders.length === 0) {
    console.log(
      `Chamber-less orphans OK — 0 seated office is hidden from its own government; ${latentNote}.\n` +
      `  (control passed: planting one made the detector report it, then rolled back.)`,
    );
    if (VERBOSE && latentTotal > 0) {
      for (const r of latent) console.log(`    ${String(r.offices).padStart(4)}  ${r.government}`);
    }
    await pool.end();
    process.exit(0);
  }

  const lines = offenders.map(
    (r) => `  ${r.holder} — ${r.title}\n      government ${r.government} (${r.government_geo_id}) · district ${r.district_label} [${r.district_type}]`,
  );
  console.error(
    `FAIL: ${offenders.length} SEATED office(s) carry no chamber while a government exists that should\n` +
    `list them, so the landing-page browse join drops them silently:\n${lines.join('\n')}\n\n` +
    'Address and coordinate search still answer for these people — that is why this hides. Fix by\n' +
    'attaching each office to a chamber of its government in a forward migration, the way CC_0183\n' +
    "attached Wichita's seven. Do NOT fix it by deleting the government row.\n" +
    `  (${latentNote}.)`,
  );
  await pool.end();
  process.exit(1);
})().catch(async (err) => {
  console.error('FAIL: check-chamberless-orphans errored:', err.message);
  try { await pool.end(); } catch { /* already closed */ }
  process.exit(2);
});
