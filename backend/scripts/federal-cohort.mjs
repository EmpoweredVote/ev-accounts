#!/usr/bin/env node
/**
 * federal-cohort.mjs — who "all federal officers" actually is, and a tripwire
 * that refuses to answer quietly when the roster changes shape.
 *
 * WHY A SCRIPT AND NOT A QUERY. The Season 2 federal research pass needs one
 * settled answer to "which people get the 9 federally-applicable topics", and
 * the honest answer is not reachable by the obvious query:
 *
 *   · Sitting senators carry TWO title formats. `title = 'Senator'` finds 86 of
 *     100 and reports success. See office-tiers.mjs.
 *   · `politicians.office_id` is NULL for most sitting members — Maxine Waters
 *     and Brad Sherman among them. The live seat comes from
 *     essentials.office_current_holder, and a query that joins only office_id
 *     drops around 40% of the people it is counting.
 *   · DC's two shadow senators sit at a /cd: district with "Senator" in the
 *     title and hold no seat in Congress.
 *
 * Each of those fails toward a SMALLER cohort that still looks plausible, which
 * is the failure mode worth a committed script: nobody notices a research pass
 * that quietly skipped 14 senators.
 *
 * 🔴 THE TRIPWIRE IS THE POINT. `--check` subtracts the canonical senator
 * predicate from a deliberately broad net and FAILS on the difference. Today
 * they agree exactly. If a third title format lands — the way
 * `U.S. Senate - <State>` once did — this says so on the next run, naming the
 * titles, instead of being discovered whenever somebody next counts by hand.
 * It does NOT assert "exactly 100": a real vacancy is not a defect, and an
 * assertion that cries wolf on vacancies gets deleted.
 *
 * RUN: node scripts/federal-cohort.mjs            # breakdown + tripwire
 *      node scripts/federal-cohort.mjs --check    # tripwire only, exit 1 on drift
 *      node scripts/federal-cohort.mjs --names    # one full_name per line, for a CSV
 *
 * Needs DATABASE_URL (session pooler string; the direct host is IPv6-only).
 */
import 'dotenv/config';
import pg from 'pg';
import { SITTING_SENATOR_SQL, SENATOR_BROAD_NET_SQL } from './lib/office-tiers.mjs';

const args = process.argv.slice(2);
const CHECK_ONLY = args.includes('--check');
const NAMES = args.includes('--names');

if (!process.env.DATABASE_URL) {
  console.error('federal-cohort: DATABASE_URL is not set. The database is the whole script.');
  process.exit(1);
}

/**
 * The live seat, from either link. office_current_holder is the one that is
 * actually maintained; politicians.office_id is kept in the COALESCE because
 * some rows only have that.
 */
const SEAT_JOIN = `
       LEFT JOIN essentials.office_current_holder h ON h.politician_id = p.id
       LEFT JOIN essentials.offices  o ON o.id = COALESCE(p.office_id, h.office_id)
       LEFT JOIN essentials.districts d ON d.id = o.district_id`;

const IS_ACTIVE = `p.is_active AND NOT COALESCE(p.is_vacant, false)`;

const COHORT_SQL = `
  SELECT DISTINCT ON (p.id) p.id, p.full_name, o.title,
         CASE
           WHEN o.title ILIKE '%shadow senator%' THEN 'excluded: shadow senator'
           WHEN d.ocd_id LIKE '%/cd:%' THEN 'House'
           WHEN ${SITTING_SENATOR_SQL} THEN 'Senate'
           WHEN d.ocd_id = 'ocd-division/country:us'
                AND o.title IN ('President', 'Vice President') THEN 'President / VP'
         END AS seat
    FROM essentials.politicians p ${SEAT_JOIN}
   WHERE ${IS_ACTIVE}
     AND (d.ocd_id LIKE '%/cd:%'
          OR ${SITTING_SENATOR_SQL}
          OR (d.ocd_id = 'ocd-division/country:us' AND o.title IN ('President', 'Vice President')))
   ORDER BY p.id, o.title`;

/** Senators the broad net sees that the canonical predicate does not. */
const DRIFT_SQL = `
  SELECT DISTINCT o.title, count(*) OVER (PARTITION BY o.title) AS people
    FROM essentials.politicians p ${SEAT_JOIN}
   WHERE ${IS_ACTIVE} AND ${SENATOR_BROAD_NET_SQL} AND NOT ${SITTING_SENATOR_SQL}`;

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

try {
  const { rows: drift } = await pool.query(DRIFT_SQL);
  if (drift.length > 0) {
    console.error('\nfederal-cohort FAILED — a senator title the canonical predicate does not match:\n');
    for (const d of drift) console.error(`    · ${d.people} × "${d.title}"`);
    console.error(
      '\n  These people ARE sitting senators by every signal except the title format, so any\n' +
      '  cohort built on the canonical predicate is silently missing them. Add the format to\n' +
      '  SITTING_SENATOR_SQL in scripts/lib/office-tiers.mjs — and check whether\n' +
      '  federalCoverage.ts TIER_CASE_SQL needs the same addition, since the two must agree.\n'
    );
    process.exit(1);
  }

  if (CHECK_ONLY) {
    console.log('federal-cohort OK — the canonical senator predicate matches every senator the broad net finds.');
    process.exit(0);
  }

  const { rows } = await pool.query(COHORT_SQL);
  const seated = rows.filter((r) => r.seat && !r.seat.startsWith('excluded'));

  if (NAMES) {
    for (const r of seated) console.log(r.full_name);
    process.exit(0);
  }

  const bySeat = new Map();
  for (const r of seated) bySeat.set(r.seat, (bySeat.get(r.seat) ?? 0) + 1);
  const excluded = rows.length - seated.length;

  console.log('\nFederal cohort — sitting officeholders:\n');
  for (const [seat, n] of [...bySeat].sort((a, b) => b[1] - a[1])) {
    console.log(`  ${String(n).padStart(4)}  ${seat}`);
  }
  console.log(`  ${String(seated.length).padStart(4)}  TOTAL`);
  if (excluded) console.log(`\n  (${excluded} excluded — shadow senators, who hold no seat in Congress)`);
  console.log('\n  × 9 federally-applicable Season 2 topics =', seated.length * 9, 'answer rows\n');
  console.log('  Candidates for these seats are a separate cohort — essentials.race_candidates\n' +
              '  on U.S. House / U.S. Senate races. They are NOT counted above.\n');
} finally {
  await pool.end();
}
