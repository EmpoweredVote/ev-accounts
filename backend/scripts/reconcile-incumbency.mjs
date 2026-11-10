#!/usr/bin/env node
/**
 * reconcile-incumbency.mjs — recompute the cached columns that do NOT move when the calendar
 * does.
 *
 * WHY THIS EXISTS. `essentials.office_terms` is self-executing: a future-dated term starts
 * resolving as current on its own date, with no trigger and no deploy. Three cached columns do
 * not follow it:
 *
 *   politicians.is_incumbent        read by four filters in essentialsBrowseService.ts and a
 *                                   fifth at essentialsService.ts:360. It defaulted to true
 *                                   until CA_0188, which left 1,817 active "incumbents" with no
 *                                   seat. Left stale, a departing holder stays an incumbent with
 *                                   no seat AND the arriving one is HIDDEN FROM ADDRESS SEARCH.
 *   politicians.office_id           the deprecated point-in-time snapshot. It has NO foreign
 *                                   key, so it can point at a deleted office and nothing
 *                                   complains.
 *   race_candidates.is_incumbent    its own column, filtered at compassService.ts:629 as the
 *                                   "challengers only" read.
 *
 * At one seat the fix is a dated companion migration (CC_0202 is the worked example, with a
 * guard refusing to run before its date). At 2,159 seats that is thousands of files, so this
 * reconciles instead.
 *
 * 🔴 RECONCILING IS ONLY HALF. `stagingService` used to force `is_incumbent = true` on every
 * ON CONFLICT promotion, so a scheduled reconciler was silently undone by the next promotion.
 * The obvious control — plant drift, run this, watch it get fixed — PASSES while that is true,
 * because it never exercises the writer that reverts it. That line is gone, and
 * `reconcile-incumbency.test.ts` guards its absence by SQL text.
 *
 * Read-only unless `--apply` is passed.
 */
import 'dotenv/config';
import { Pool } from 'pg';
import { pathToFileURL } from 'node:url';

/**
 * The pure core: given the three row sets, what disagrees with office_terms?
 *
 * Truth is `currentHolders` — whoever resolves as holding an office TODAY.
 *
 * ⚠ A person can hold two seats (27 active people do), so the holder set is collapsed to
 * distinct politician ids before comparing. Counting rows instead of people would report the
 * same person twice.
 */
export function findDrift({ politicians, currentHolders, raceCandidates = [] }) {
  // 🔴 A PLACEHOLDER OFFICE IS NOT A SEAT. `currentHolders` must already exclude
  // 'Candidate for ...' offices (migration 196) — the caller's SQL does it, and so does the read
  // path this flag feeds (essentialsService.ts:360). The first version of this function did not,
  // and reported 25 "missing incumbents" of whom 22 were CANDIDATES holding only a placeholder:
  // Roy Cooper, Sherrod Brown, Mary Peltola and 19 others. Applying that would have published
  // them as sitting incumbents. See CC_0342.
  const holds = new Set();
  for (const h of currentHolders) if (h.politician_id) holds.add(h.politician_id);

  const drift = [];

  for (const p of politicians) {
    const expected = holds.has(p.id);
    if (Boolean(p.is_incumbent) !== expected) {
      drift.push({
        politicianId: p.id,
        column: 'politicians.is_incumbent',
        current: Boolean(p.is_incumbent),
        expected,
      });
    }
  }

  // race_candidates.is_incumbent — RULED 2026-11-04: it means "incumbent OF THE SEAT THIS RACE
  // IS FOR". Each row therefore carries its own expected value, computed by the caller's SQL
  // against the RACE'S OWN OFFICE as of the RACE'S OWN ELECTION DATE; this function only compares.
  //
  // 🔴 ELECTION DATE, NOT TODAY, AND THE DIFFERENCE IS NOT THEORETICAL. Three rows in production
  // hold the contested seat today but took office AFTER the election they appear in — Chris
  // Jamieson and Brandon Smith won as challengers and were seated weeks later. A "holds it today"
  // rule relabels those three winners as the incumbents of races they won as challengers.
  for (const rc of raceCandidates) {
    if (!rc.politician_id) continue;
    const expected = Boolean(rc.expected_is_incumbent);
    if (Boolean(rc.is_incumbent) !== expected) {
      drift.push({
        raceCandidateId: rc.id,
        politicianId: rc.politician_id,
        column: 'race_candidates.is_incumbent',
        current: Boolean(rc.is_incumbent),
        expected,
      });
    }
  }

  return drift;
}

/**
 * 🔴 ONE COLUMN THIS DELIBERATELY DOES NOT RECONCILE, BECAUSE RECONCILING IT WAS WRONG.
 *
 *   politicians.office_id         A DEPRECATED POINT-IN-TIME SNAPSHOT (ADR 0002). It was never
 *                                 meant to equal the current holder — that is why the view
 *                                 replaced it. An earlier version of this script reported 101
 *                                 of them as drift and would have nulled every one. All 101
 *                                 point at real offices, none dangling, and there is no history
 *                                 table, so the values would have existed nowhere afterwards.
 *
 * Adding it back needs a ruling first, not a predicate.
 *
 * ✅ race_candidates.is_incumbent WAS such a ruling, and it is now reconciled. An earlier version
 * used the GLOBAL rule ("holds office somewhere") and reported 297 rows, 234 of which were
 * cross-office candidates — a state senator running for the U.S. House, a Lt. Governor running
 * for Treasurer — that the rule would have relabelled as incumbents of races they were
 * challenging. The data carried both conventions, so the script refused to touch it until the
 * operator ruled on 2026-11-04: the column means "incumbent OF THE SEAT THIS RACE IS FOR",
 * measured on the race's own election date. CC_0343 applied that to 292 rows.
 */

export async function computeIncumbencyDrift(client) {
  const [politicians, currentHolders, raceCandidates] = await Promise.all([
    client.query(
      `SELECT id, is_incumbent FROM essentials.politicians WHERE is_active = true`),
    // 🔴 NOT ILIKE 'Candidate for%' — A PLACEHOLDER OFFICE IS NOT A SEAT. Without this clause
    // the query calls 22 Senate CANDIDATES incumbents, Roy Cooper and Sherrod Brown among them.
    // It mirrors the filter the read path already applies at essentialsService.ts:360.
    client.query(
      `SELECT DISTINCT och.politician_id
         FROM essentials.office_current_holder och
         JOIN essentials.offices o ON o.id = och.office_id
        WHERE och.politician_id IS NOT NULL
          AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'`),
    // Seat-scoped and measured AT THE ELECTION DATE — see findDrift. The expected value is
    // computed here, in SQL, because it is a fact about this row's own race and office.
    //
    // 🔴 A MULTI-SEAT RACE IS FOR SEVERAL SEATS BUT POINTS AT ONE. A race with seats > 1 (a
    // council electing three, a state board electing two) hangs off ONE of the body's offices,
    // chosen arbitrarily or as "the seat that was up". The seat-only rule therefore called every
    // other sitting member defending a seat in that same race a challenger: 128 rows in 87 races
    // on 2026-11-07, and CC_0364's four correctly-marked board members turned master CI red.
    // RULED 2026-11-07 (Chris Andrews): in a race with seats > 1, a candidate who holds ANY
    // office of the race office's chamber on election day is an incumbent. Single-seat races keep
    // the 2026-11-04 rule exactly — a state senator running for the U.S. House is still a
    // challenger, because a different body is a different chamber. CC_0367 applied it.
    client.query(
      `SELECT rc.id, rc.politician_id, rc.is_incumbent,
              EXISTS (SELECT 1 FROM essentials.office_terms t
                        JOIN essentials.offices o2 ON o2.id = t.office_id
                       WHERE t.politician_id = rc.politician_id
                         AND (t.office_id = r.office_id
                              OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                         AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                         AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                     ) AS expected_is_incumbent
         FROM essentials.race_candidates rc
         JOIN essentials.races r ON r.id = rc.race_id
         JOIN essentials.offices ro ON ro.id = r.office_id
         JOIN essentials.elections e ON e.id = r.election_id
        WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
          AND rc.politician_id IS NOT NULL`),
  ]);

  return findDrift({
    politicians: politicians.rows,
    currentHolders: currentHolders.rows,
    raceCandidates: raceCandidates.rows,
  });
}

export async function applyIncumbencyFixes(client, rows) {
  let applied = 0;
  for (const row of rows) {
    // ⚠ COUNT WHAT THE DATABASE DID, NOT HOW MANY TIMES WE ASKED. Every UPDATE is guarded on the
    // value it changes, so a row already correct writes nothing — `applied += 1` would have
    // reported work that never happened.
    if (row.column === 'politicians.is_incumbent') {
      const res = await client.query(
        `UPDATE essentials.politicians SET is_incumbent = $2 WHERE id = $1 AND is_incumbent IS DISTINCT FROM $2`,
        [row.politicianId, row.expected]);
      applied += res.rowCount ?? 0;
    } else if (row.column === 'race_candidates.is_incumbent') {
      const res = await client.query(
        `UPDATE essentials.race_candidates SET is_incumbent = $2 WHERE id = $1 AND is_incumbent IS DISTINCT FROM $2`,
        [row.raceCandidateId, row.expected]);
      applied += res.rowCount ?? 0;
    }
  }
  return applied;
}

// 🔴 COMPARE RESOLVED URLS, NOT A FILENAME SUFFIX. An earlier version tested
// `process.argv[1].endsWith('reconcile-incumbency.mjs')`, and `control-reconcile-incumbency.mjs`
// ends with that string too — so importing this module from its own control ran the CLI, hit
// production and printed a report nobody asked for. A suffix is not an identity.
/**
 * Does a --check run fail? Extracted so the decision can be WATCHED FAILING in a test: the
 * script's own exit path needs a live database with real drift, which is not reproducible, and
 * a gate nobody has seen go red is not a gate.
 */
export function driftExitCode({ check, driftCount }) {
  return check && driftCount > 0 ? 1 : 0;
}

const invokedDirectly = process.argv[1]
  && import.meta.url === pathToFileURL(process.argv[1]).href;
if (invokedDirectly) {
  const apply = process.argv.includes('--apply');
  // 🔴 --check EXISTS BECAUSE THIS SCRIPT RAN NOWHERE. It was built, tested and controlled, and
  // nothing invoked it — so incumbency drift would have accumulated silently again, which is the
  // single thing it exists to stop. CI runs it daily in this mode.
  //
  // It REPORTS and does not write. Correcting drift means deciding what each row is, and the
  // first attempt at that proved 420 of 429 "drift rows" were correct as they stood — so an
  // automatic --apply on a schedule would write exactly the kind of change nobody read.
  const check = process.argv.includes('--check');

  // 🔴 NO DATABASE_URL -> SKIP, exit 0, and SAY SO. Forks get no secrets, and a check that skips
  // without printing why is the shape of a detector that has quietly stopped working.
  if (!process.env.DATABASE_URL) {
    console.log(
      'SKIPPED: DATABASE_URL is not set, so incumbency drift could not be measured. Forks get ' +
        'no secrets; this is a deliberate green skip, not a pass.',
    );
    process.exit(0);
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  try {
    const drift = await computeIncumbencyDrift(pool);
    const byColumn = drift.reduce((a, d) => ({ ...a, [d.column]: (a[d.column] ?? 0) + 1 }), {});
    console.log(`drift rows: ${drift.length}`);
    for (const [col, n] of Object.entries(byColumn)) console.log(`  ${col}: ${n}`);
    if (!drift.length) {
      // 🔴 A uniform answer is a broken detector until a control passes. Say so rather than
      // letting "0" read as proof.
      console.log('0 is only meaningful if this script read the right rows — run control-reconcile-incumbency.mjs.');
    }
    if (apply) console.log(`applied: ${await applyIncumbencyFixes(pool, drift)}`);
    else console.log('read-only; pass --apply to write');

    if (check && drift.length) {
      console.error(
        `\n${drift.length} row(s) disagree with essentials.office_terms.\n` +
          'Do NOT just run --apply: read the rows first. A predicate reads the SHAPE of a value, ' +
          'never what it is, and the first measurement of this reported 429 rows of which only 9 ' +
          'were real — applying the rest would have published 22 Senate CANDIDATES as sitting ' +
          'incumbents (see CC_0342).',
      );
      process.exitCode = driftExitCode({ check, driftCount: drift.length });
    }
  } finally {
    await pool.end();
  }
}
