/**
 * backfill-fec-file-numbers.ts — put `file_number` (+ report_year / report_type) onto FEC
 * contributions rows ingested BEFORE the FEC-04b fix shipped.
 *
 * Why this exists
 * ---------------
 * FEC-04b retires superseded filings using `file_number`, but guards on
 * `raw_record ? 'file_number'` so it never touches pre-fix rows — for those we cannot tell which
 * version a row is. That left a backlog only resolvable one-group-at-a-time against the live API,
 * where 31% of groups came back UNRESOLVABLE. Backfilling the field makes the backlog resolvable
 * with local SQL instead: no per-group API calls and no unresolvable bucket.
 *
 * ⚠ ORDERING REQUIREMENT — read before running with --apply
 * ---------------------------------------------------------
 * `raw_record ? 'file_number'` is currently the ONLY thing protecting 26.7M pre-fix rows from
 * whatever retirement rule the adapter applies. Backfilling the field REMOVES that protection.
 * So this must not be applied until the adapter's retirement is per-LINE (committed alongside
 * this script). Under the original whole-report rule, backfilling would have armed a live
 * data-loss bug across the entire backlog: measured on 24 sampled superseded filings, ZERO were
 * supersets of their successor — C00574889 Q1/2016 on 2016-03-11 has 114 lines in the original
 * filing and 2 in the amendment, all 114 of which the whole-report rule would delete.
 *
 * Work unit: (committee_id, two_year_transaction_period, contribution_date)
 * -----------------------------------------------------------------------
 * `sub_id -> file_number` is many-to-one and one page carries 100 of both, so the naive unit is
 * the committee-period. Measured, that is unaffordable: C00742007/2024 is 102,312 rows = 1,024
 * pages, ~68 min at the shared 15/min budget; across 268 implicated periods it runs to days.
 * The duplicate groups are extremely sparse in DATE, so narrowing to the group's own date cuts
 * that period to 497 rows / 5 pages — a ~200x reduction — while still returning every filing's
 * version of the lines on that date, which is all that deciding supersession needs.
 *
 * Safety
 * ------
 *   - Every UPDATE is scoped by `politician_source_id` FIRST so it rides idx_contrib_src_cycle.
 *     An unscoped JSONB predicate would seq-scan 26.7M rows — the 2026-07-22 P1 incident shape.
 *   - `NOT (raw_record ? 'file_number')` — never overwrites a value already there, so re-running
 *     is a no-op and post-fix rows are left exactly as the adapter wrote them.
 *   - Writes ONLY those three keys, merged into raw_record. Deletes nothing; retirement is a
 *     separate explicit step (retire-fec-superseded-local.ts).
 *   - Rows whose sub_id the API no longer returns stay un-backfilled and are counted, not guessed.
 *   - Coverage is PARTIAL by construction (only the dates that carry a detected group). That is
 *     safe for per-line retirement but means a report's other dates keep any duplicates.
 *   - A per-window DB error is counted and retried, never fatal. The first 24h run died 40 times
 *     over on ONE slow window because only fetch failures were caught; see the statement_timeout
 *     note below. A resumable long-running job must not let a single window end the run.
 *
 * Usage:
 *   tsx scripts/backfill-fec-file-numbers.ts <detector.json> [--windows N] [--apply]
 *
 * Dry run by default. Resumable via data/fec-file-number-backfill-state.json.
 */

import 'dotenv/config';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { pool } from '../src/lib/db.js';
import { fetchWindow } from './lib/fecScheduleAWindow.js';

const reportPath = process.argv[2];
if (!reportPath) {
  console.error('usage: tsx scripts/backfill-fec-file-numbers.ts <detector.json> [--windows N] [--apply]');
  process.exit(2);
}
const wIdx = process.argv.indexOf('--windows');
const MAX = wIdx > -1 ? parseInt(process.argv[wIdx + 1]!, 10) : 50;
const APPLY = process.argv.includes('--apply');
if (!process.env.FEC_API_KEY) { console.error('FEC_API_KEY not set'); process.exit(2); }

// The `ev_api` role carries `statement_timeout=30s` (role-level, set during the 2026-07-22 P1
// finance incident). The cycle probe below legitimately exceeds it — measured 39.4s on
// C00736876|2022-11-11 and 34.9s on C00736876|2020-06-11 — so the first run hit that window and
// died, 40 times over. A retry loop cannot clear a deterministic wall.
//
// A non-superuser may raise its OWN session value, so this needs no grant and no privileged
// connection string. Deliberately NOT set in src/lib/db.ts: the 30s role default is what protects
// the API from the P1 incident shape, and only this batch job should opt out of it. Applied on the
// `connect` event rather than once up front so it survives the pool reconnecting mid-run — pg
// queues per-client, so this SET always lands before the first query on that connection.
pool.on('connect', (c) => {
  c.query("SET statement_timeout = '300s'").catch((e: Error) => {
    console.error(`[pool] could not raise statement_timeout — window scans may abort: ${e.message}`);
  });
});

const STATE = 'data/fec-file-number-backfill-state.json';
interface State { done: string[]; updated: number; unresolvable: number }
const state: State = existsSync(STATE)
  ? JSON.parse(readFileSync(STATE, 'utf8'))
  : { done: [], updated: 0, unresolvable: 0 };
const done = new Set(state.done);

interface Detail { cmte: string; donor: string; amount: number; date: string }
const det = JSON.parse(readFileSync(reportPath, 'utf8')) as {
  findings: { politician_source_id: string; detail: Detail[] }[];
};

// One target per (committee, date); a target can serve several politician_sources.
//
// The two_year_transaction_period is NOT derived from the contribution date. It looked safe
// (2020-12-31 -> 2020) and is wrong: FEC assigns some contributions to the FOLLOWING cycle, so
// committee C00718866 on 2020-12-31 has 154 rows in cycle 2020 and **9,150 in cycle 2022**.
// Deriving the period from the date fetched only the 2020 window and reported all 9,150 as
// "the API no longer returns this sub_id" — they were simply never asked for. So the periods to
// fetch come from the rows' own stored `election_cycle`, and a date can need more than one.
const windows = new Map<string, { cmte: string; date: string; sources: Set<string> }>();
for (const f of det.findings) {
  for (const g of f.detail) {
    const date = String(g.date).slice(0, 10);
    const k = `${g.cmte}|${date}`;
    if (!windows.has(k)) windows.set(k, { cmte: g.cmte, date, sources: new Set() });
    windows.get(k)!.sources.add(f.politician_source_id);
  }
}
const pending = [...windows.entries()].filter(([k]) => !done.has(k));
console.log(`${windows.size} date window(s) implicated; ${done.size} already done`);
console.log(`processing ${Math.min(MAX, pending.length)} of ${pending.length} pending`);
console.log(APPLY ? 'MODE: APPLY\n' : 'MODE: DRY RUN (pass --apply to write)\n');

let updated = 0, unresolvable = 0, processed = 0, failed = 0;

// Persist after every window that resolves. The first run checkpointed every 25 and crashed, so
// each of the 40 retries re-walked up to 25 already-answered windows before reaching the poison
// one. `done` is the expensive thing to lose; a ~100KB local write per window is not.
const checkpoint = () => {
  if (!APPLY) return;
  writeFileSync(STATE, JSON.stringify({
    done: [...done],
    updated: state.updated + updated,
    unresolvable: state.unresolvable + unresolvable,
  }, null, 2));
};

for (const [k, w] of pending) {
  if (processed >= MAX) break;
  processed++;

  // Which two-year periods do OUR un-backfilled rows for this (committee, date) actually claim?
  let cycles: { election_cycle: string }[];
  try {
    ({ rows: cycles } = await pool.query<{ election_cycle: string }>(
      `SELECT DISTINCT election_cycle
         FROM transparent_motivations.contributions
        WHERE politician_source_id = ANY($1::uuid[])
          AND data_source = 'fec'
          AND NOT (raw_record ? 'file_number')
          AND raw_record->>'committee_id' = $2
          AND contribution_date = $3::date
          AND election_cycle ~ '^[0-9]{4}$'`,
      [[...w.sources], w.cmte, w.date]
    ));
  } catch (e) {
    // Not marked done — same contract as a fetch failure: retry it, never silently skip it.
    failed++;
    console.log(`  ! ${k}: cycle probe failed (${(e as Error).message}) — will retry`);
    continue;
  }
  if (cycles.length === 0) {
    console.log(`  - ${k}: nothing left to fill`);
    done.add(k);
    checkpoint();
    continue;
  }

  let rows: Awaited<ReturnType<typeof fetchWindow>> = [];
  try {
    for (const c of cycles) {
      rows.push(...await fetchWindow(w.cmte, parseInt(c.election_cycle, 10), w.date));
    }
  } catch (e) {
    // Not marked done — a fetch failure must retry, never silently skip a window.
    failed++;
    console.log(`  ! ${k}: fetch failed (${(e as Error).message}) — will retry`);
    continue;
  }

  const patch = new Map<string, string>();
  for (const r of rows) {
    if (!r.sub_id || r.file_number == null || r.report_year == null || r.report_type == null) continue;
    patch.set(r.sub_id, JSON.stringify({
      file_number: r.file_number, report_year: r.report_year, report_type: r.report_type,
    }));
  }
  if (patch.size === 0) {
    console.log(`  - ${k}: API returned no usable file_number — skipped`);
    done.add(k);
    checkpoint();
    continue;
  }

  const subIds = [...patch.keys()];
  const patches = subIds.map((s) => patch.get(s)!);
  let wUpdated = 0, wOrphan = 0;

  try {
    for (const ps of w.sources) {
      // How many of OUR pre-fix rows in this window the map can fill, and how many it cannot.
      const { rows: cnt } = await pool.query<{ fillable: string; missing_total: string }>(
        `SELECT count(*) FILTER (WHERE c.source_transaction_id = ANY($2::text[])) AS fillable,
                count(*) AS missing_total
           FROM transparent_motivations.contributions c
          WHERE c.politician_source_id = $1
            AND c.data_source = 'fec'
            AND NOT (c.raw_record ? 'file_number')
            AND c.raw_record->>'committee_id' = $3
            AND c.contribution_date = $4::date`,
        [ps, subIds, w.cmte, w.date]
      );
      const fillable = Number(cnt[0]?.fillable ?? 0);
      wOrphan += Number(cnt[0]?.missing_total ?? 0) - fillable;

      if (!APPLY) { wUpdated += fillable; continue; }   // dry run reports what it WOULD fill
      if (fillable === 0) continue;

      // politician_source_id first so the UPDATE rides idx_contrib_src_cycle.
      const { rowCount } = await pool.query(
        `UPDATE transparent_motivations.contributions c
            SET raw_record = c.raw_record || v.patch,
                updated_at = NOW()
           FROM (SELECT * FROM unnest($2::text[], $3::jsonb[]) AS t(sub_id, patch)) v
          WHERE c.politician_source_id = $1
            AND c.data_source = 'fec'
            AND c.source_transaction_id = v.sub_id
            AND NOT (c.raw_record ? 'file_number')`,
        [ps, subIds, patches]
      );
      wUpdated += rowCount ?? 0;
    }
  } catch (e) {
    // Not marked done, and safe to retry even if some sources already committed: the UPDATE is
    // guarded by `NOT (raw_record ? 'file_number')`, so a redo fills only what is still empty.
    // Discard this window's partial tallies rather than double-count them on the retry.
    failed++;
    console.log(`  ! ${k}: fill failed (${(e as Error).message}) — will retry`);
    continue;
  }

  updated += wUpdated;
  unresolvable += wOrphan;
  console.log(`  ${APPLY ? '✓' : '·'} ${k}: ${rows.length} API row(s), `
            + `${APPLY ? `updated ${wUpdated}` : `would fill ${wUpdated}`}`
            + (wOrphan ? `, ${wOrphan} row(s) the API no longer returns — left alone` : ''));
  done.add(k);
  checkpoint();
}

console.log(`\nwindows processed : ${processed}${failed ? ` (${failed} failure(s), will retry)` : ''}`);
console.log(`rows ${APPLY ? 'updated' : 'fillable (dry run)'} : ${updated}`);
console.log(`rows the API cannot resolve (left alone) : ${unresolvable}`);
if (APPLY) {
  state.done = [...done];
  state.updated += updated;
  // ACCUMULATE, don't overwrite. This read `= unresolvable` (the per-run counter), so every resume
  // clobbered the cumulative total — the 145 recorded mid-run had been reset to 0 by the time the
  // run died. A window is counted once, when it is marked done, so summing is correct.
  state.unresolvable += unresolvable;
  writeFileSync(STATE, JSON.stringify(state, null, 2));
  console.log(`state -> ${STATE} (${done.size} window(s) done, ${state.updated} cumulative row(s))`);
}
await pool.end();

// Exit non-zero while windows remain unfinished, so `_bf-wrapper.ps1`'s retry loop picks them up.
// Before the per-window failures were caught, the loop only ever re-ran because the script CRASHED;
// a pass that skipped windows and exited 0 would have stranded them silently. Resuming is cheap now
// that `done` is checkpointed every window — a retry re-walks only what is genuinely left.
if (APPLY && failed > 0) {
  console.log(`\n${failed} window(s) still unfinished — exiting 1 so the wrapper retries them.`);
  process.exit(1);
}
