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
export function findDrift({ politicians, currentHolders, raceCandidates }) {
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
    // The deprecated snapshot asserts a seat. If the person holds nothing, it asserts a lie.
    if (p.office_id && !expected) {
      drift.push({
        politicianId: p.id,
        column: 'politicians.office_id',
        current: p.office_id,
        expected: null,
      });
    }
  }

  for (const rc of raceCandidates) {
    if (!rc.politician_id) continue;
    const expected = holds.has(rc.politician_id);
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

export async function computeIncumbencyDrift(client) {
  const [politicians, currentHolders, raceCandidates] = await Promise.all([
    client.query(
      `SELECT id, is_incumbent, office_id FROM essentials.politicians WHERE is_active = true`),
    client.query(
      `SELECT DISTINCT politician_id FROM essentials.office_current_holder
        WHERE politician_id IS NOT NULL`),
    client.query(
      `SELECT rc.id, rc.politician_id, rc.is_incumbent
         FROM essentials.race_candidates rc
         JOIN essentials.races r ON r.id = rc.race_id
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
    if (row.column === 'politicians.is_incumbent') {
      await client.query(
        `UPDATE essentials.politicians SET is_incumbent = $2 WHERE id = $1 AND is_incumbent IS DISTINCT FROM $2`,
        [row.politicianId, row.expected]);
      applied += 1;
    } else if (row.column === 'politicians.office_id') {
      await client.query(
        `UPDATE essentials.politicians SET office_id = NULL WHERE id = $1 AND office_id IS NOT NULL`,
        [row.politicianId]);
      applied += 1;
    } else if (row.column === 'race_candidates.is_incumbent') {
      await client.query(
        `UPDATE essentials.race_candidates SET is_incumbent = $2 WHERE id = $1 AND is_incumbent IS DISTINCT FROM $2`,
        [row.raceCandidateId, row.expected]);
      applied += 1;
    }
  }
  return applied;
}

// 🔴 COMPARE RESOLVED URLS, NOT A FILENAME SUFFIX. An earlier version tested
// `process.argv[1].endsWith('reconcile-incumbency.mjs')`, and `control-reconcile-incumbency.mjs`
// ends with that string too — so importing this module from its own control ran the CLI, hit
// production and printed a report nobody asked for. A suffix is not an identity.
const invokedDirectly = process.argv[1]
  && import.meta.url === pathToFileURL(process.argv[1]).href;
if (invokedDirectly) {
  const apply = process.argv.includes('--apply');
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
  } finally {
    await pool.end();
  }
}
