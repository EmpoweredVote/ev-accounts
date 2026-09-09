#!/usr/bin/env node
/**
 * check-lens-freshness.mjs — does each curated lens still hold topics the OPEN
 * SEASON asks, and does the Federal Lens still match its own promise?
 *
 * 🔴 WHY THIS EXISTS. `immigration` sat in the Federal Lens from the day Season 2
 * opened until 2026-09-08 — a spoke with no question behind it, because Season 2
 * dropped exactly one of the 44 topics it carried forward and that was the one.
 * Nothing noticed. It was found by hand, while answering a question about
 * something else. CC_0086 fixed the membership; this is what makes the next one
 * visible.
 *
 * TWO CHECKS, AND ONLY THE FIRST IS A FAILURE:
 *
 *   1. UNASKED (fails). A lens topic the open season does not ask cannot render.
 *      This is not a matter of taste and there is no tolerance for it. All four
 *      curated lenses are checked, not just Federal — Education was seeded
 *      2026-08-31 and has never been audited against a season rollover.
 *
 *   2. DRIFT (warns). Migration 1337's description promises the Federal Lens is
 *      "8 issues most U.S. House & Senate members and candidates have answered".
 *      That is a measurable claim, so it is measured. But coverage moves every
 *      time research lands, and a batch of 12 rows must not turn CI red — so
 *      drift REPORTS and exits 0. A human decides whether the lens should follow.
 *
 * ⚠ THE FEDERAL COHORT COMES FROM office-tiers.mjs AND IS NOT RESTATED HERE. That
 * module exists because this CASE kept being re-derived slightly differently, most
 * consequentially over the two title formats sitting senators carry.
 *
 * ⚠ TIES BREAK ON topic_key. `deportation` and `taxes` sat at 488 apiece when
 * CC_0086 was written; without a stable tie-break this would report drift on a
 * coin toss. Change the rule here and in the migration comment together.
 *
 * RUN:
 *   npm run check:lens-freshness
 *   node scripts/check-lens-freshness.mjs --allow-skip   # local, no DATABASE_URL
 */
import 'dotenv/config';
import pg from 'pg';
import { COMPASS_TIER_SQL } from './lib/office-tiers.mjs';

const ALLOW_SKIP = process.argv.includes('--allow-skip');

/** The lens whose membership is a measurable claim, and the size of that claim. */
const DERIVED_LENS = 'federal';
const DERIVED_SIZE = 8;

const UNASKED_SQL = `
  SELECT l.key AS lens, t.topic_key, lt.sort_order
    FROM inform.compass_lenses l
    JOIN inform.compass_lens_topics lt ON lt.lens_id = l.id
    JOIN inform.compass_topics t ON t.id = lt.topic_id
   WHERE l.is_active
     AND NOT EXISTS (
       SELECT 1 FROM inform.compass_topics_promoted pr
         JOIN inform.season_questions sq ON sq.topic_id = pr.id
         JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
        WHERE pr.id = lt.topic_id)
   ORDER BY l.sort_order NULLS LAST, lt.sort_order`;

// Coverage over the federal cohort, restricted to topics the open season asks that
// admit the federal tier. A blank (value 0) is a researched refusal and is NOT
// coverage — it renders as an empty spoke, which is what the promise is about.
const COVERAGE_SQL = `
  WITH fed AS (
    SELECT DISTINCT p.id
      FROM essentials.politicians p
      LEFT JOIN essentials.office_terms ot ON ot.politician_id = p.id
      LEFT JOIN essentials.offices o  ON o.id = ot.office_id
      LEFT JOIN essentials.districts d ON d.id = o.district_id
     WHERE p.is_active AND (${COMPASS_TIER_SQL}) = 'federal'
  ), asked AS (
    SELECT pr.id, pr.topic_key
      FROM inform.compass_topics_promoted pr
      JOIN inform.season_questions sq ON sq.topic_id = pr.id
      JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
     WHERE EXISTS (SELECT 1 FROM inform.compass_topic_roles r
                    WHERE r.topic_id = pr.id AND r.role_scope = 'federal')
  )
  SELECT a.topic_key,
         count(DISTINCT ans.politician_id)::int AS answered,
         (SELECT count(*)::int FROM fed) AS cohort
    FROM asked a
    LEFT JOIN inform.politician_answers ans
      ON ans.topic_id = a.id AND ans.value <> 0
     AND ans.politician_id IN (SELECT id FROM fed)
     AND EXISTS (SELECT 1 FROM inform.seasons s2 WHERE s2.id = ans.season_id AND s2.status <> 'draft')
   GROUP BY a.topic_key
   ORDER BY count(DISTINCT ans.politician_id) DESC, a.topic_key`;

const COMMITTED_SQL = `
  SELECT t.topic_key, lt.sort_order
    FROM inform.compass_lenses l
    JOIN inform.compass_lens_topics lt ON lt.lens_id = l.id
    JOIN inform.compass_topics t ON t.id = lt.topic_id
   WHERE l.key = $1
   ORDER BY lt.sort_order`;

async function main() {
  if (!process.env.DATABASE_URL) {
    if (ALLOW_SKIP) {
      console.log('lens freshness SKIPPED — no DATABASE_URL, and --allow-skip was passed. NOTHING WAS MEASURED. This is not a pass.');
      return 0;
    }
    // Same reasoning as season-corpus-floor: this is a single membership read, and
    // a green "skip" is indistinguishable from a green "the lenses are intact".
    console.error('🔴 lens freshness FAILED — no DATABASE_URL. A tripwire that never runs reads healthy forever. Use --allow-skip locally.');
    return 1;
  }

  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  try {
    const [{ rows: unasked }, { rows: coverage }, { rows: committed }] = await Promise.all([
      pool.query(UNASKED_SQL),
      pool.query(COVERAGE_SQL),
      pool.query(COMMITTED_SQL, [DERIVED_LENS]),
    ]);

    let failures = 0;

    // ── 1. unasked topics, all active lenses ──────────────────────────────────
    if (unasked.length) {
      console.error(`🔴 FAIL ${unasked.length} lens topic(s) are NOT asked by the open season and cannot render:`);
      for (const r of unasked) console.error(`     ${r.lens} lens, slot ${r.sort_order}: ${r.topic_key}`);
      console.error('     A season may drop a topic; a lens pointing at one is a spoke with no question.');
      failures++;
    } else {
      console.log('✅ every active lens topic is asked by the open season');
    }

    // ── 2. drift in the derived lens (reports, never fails) ───────────────────
    const cohort = coverage.length ? coverage[0].cohort : 0;
    const want = coverage.slice(0, DERIVED_SIZE).map((r) => r.topic_key);
    const have = committed.map((r) => r.topic_key);

    const pct = (n) => (cohort ? Math.round((n / cohort) * 100) : 0);
    const cov = new Map(coverage.map((r) => [r.topic_key, r.answered]));

    const sameSet = want.length === have.length && want.every((k) => have.includes(k));
    const sameOrder = want.length === have.length && want.every((k, i) => have[i] === k);

    if (sameOrder) {
      console.log(`✅ the ${DERIVED_LENS} lens matches the top ${DERIVED_SIZE} by federal coverage (${cohort} people)`);
    } else {
      console.log(`\n⚠ the ${DERIVED_LENS} lens has DRIFTED from the top ${DERIVED_SIZE} by coverage — reporting, not failing.`);
      console.log(`  Migration 1337 promises "8 issues most U.S. House & Senate members and candidates have answered".`);
      console.log(`  Cohort: ${cohort} federal people. Ties break on topic_key.\n`);
      console.log('  derived                          committed');
      for (let i = 0; i < Math.max(want.length, have.length); i++) {
        const w = want[i], h = have[i];
        const mark = w === h ? ' ' : '≠';
        const wl = w ? `${w} (${cov.get(w)}, ${pct(cov.get(w))}%)` : '—';
        console.log(`  ${mark} ${String(i).padStart(1)} ${wl.padEnd(30)} ${h || '—'}`);
      }
      if (!sameSet) {
        const gained = want.filter((k) => !have.includes(k));
        const lost = have.filter((k) => !want.includes(k));
        if (gained.length) console.log(`\n  would gain: ${gained.join(', ')}`);
        if (lost.length) console.log(`  would lose: ${lost.join(', ')}`);
      } else {
        console.log('\n  Same eight topics, different order.');
      }
      console.log('\n  Coverage moves whenever research lands, so this is a prompt and not a defect.');
      console.log('  If the lens should follow, write a CC_ migration the way CC_0086 did.');
    }

    if (failures) {
      console.error(`\n🔴 ${failures} failure(s)`);
      return 1;
    }
    console.log('\nlens freshness OK');
    return 0;
  } finally {
    await pool.end();
  }
}

process.exit(await main());
