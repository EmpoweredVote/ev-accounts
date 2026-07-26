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

// One window per (committee, period, date); a window can serve several politician_sources.
const windows = new Map<string, { cmte: string; period: number; date: string; sources: Set<string> }>();
for (const f of det.findings) {
  for (const g of f.detail) {
    const date = String(g.date).slice(0, 10);
    const y = parseInt(date.slice(0, 4), 10);
    const period = y % 2 === 0 ? y : y + 1;
    const k = `${g.cmte}|${period}|${date}`;
    if (!windows.has(k)) windows.set(k, { cmte: g.cmte, period, date, sources: new Set() });
    windows.get(k)!.sources.add(f.politician_source_id);
  }
}
const pending = [...windows.entries()].filter(([k]) => !done.has(k));
console.log(`${windows.size} date window(s) implicated; ${done.size} already done`);
console.log(`processing ${Math.min(MAX, pending.length)} of ${pending.length} pending`);
console.log(APPLY ? 'MODE: APPLY\n' : 'MODE: DRY RUN (pass --apply to write)\n');

let updated = 0, unresolvable = 0, processed = 0, failed = 0;

for (const [k, w] of pending) {
  if (processed >= MAX) break;
  processed++;

  let rows;
  try {
    rows = await fetchWindow(w.cmte, w.period, w.date);
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
    continue;
  }

  const subIds = [...patch.keys()];
  const patches = subIds.map((s) => patch.get(s)!);
  let wUpdated = 0, wOrphan = 0;

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

  updated += wUpdated;
  unresolvable += wOrphan;
  console.log(`  ${APPLY ? '✓' : '·'} ${k}: ${rows.length} API row(s), `
            + `${APPLY ? `updated ${wUpdated}` : `would fill ${wUpdated}`}`
            + (wOrphan ? `, ${wOrphan} row(s) the API no longer returns — left alone` : ''));
  done.add(k);

  if (APPLY && processed % 25 === 0) {
    writeFileSync(STATE, JSON.stringify({ done: [...done], updated: state.updated + updated, unresolvable }, null, 2));
  }
}

console.log(`\nwindows processed : ${processed}${failed ? ` (${failed} fetch failure(s), will retry)` : ''}`);
console.log(`rows ${APPLY ? 'updated' : 'fillable (dry run)'} : ${updated}`);
console.log(`rows the API cannot resolve (left alone) : ${unresolvable}`);
if (APPLY) {
  state.done = [...done];
  state.updated += updated;
  state.unresolvable = unresolvable;
  writeFileSync(STATE, JSON.stringify(state, null, 2));
  console.log(`state -> ${STATE} (${done.size} window(s) done, ${state.updated} cumulative row(s))`);
}
await pool.end();
