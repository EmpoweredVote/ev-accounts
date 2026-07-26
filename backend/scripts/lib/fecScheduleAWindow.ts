/**
 * fecScheduleAWindow — cached, rate-limited fetch of one Schedule A DATE WINDOW.
 *
 * Shared by the file_number backfill, its containment validator, and the local retirement step
 * so all three read the SAME cached bytes and the API is paid for once.
 *
 * Why a date window and not a whole (committee, two_year_transaction_period)
 * -------------------------------------------------------------------------
 * The obvious unit of work is the committee-period, since that is what `sub_id -> file_number`
 * pagination is keyed on. Measured, that is unaffordable: C00742007/2024 is 102,312 rows =
 * 1,024 pages, and at the shared 15 req/min budget one such period costs ~68 minutes. Across the
 * implicated periods it runs to days.
 *
 * But the duplicate groups are extremely sparse in DATE — C00742007/2024 has exactly one group on
 * one date. Adding `min_date=max_date=<that date>` cuts that period from 102,312 rows to 497
 * (5 pages): a ~200x reduction, and it still returns EVERY filing's version of the lines on that
 * date, which is precisely what deciding supersession needs.
 *
 * So the work unit is (committee_id, two_year_transaction_period, contribution_date).
 *
 * Consequence to respect downstream: coverage is PARTIAL by construction — a report's rows on
 * other dates are not fetched. Never compute a report's surviving file_number from a partially
 * backfilled DB, or a line whose amendment-side row was never ingested can look superseded and be
 * deleted as the last copy. Decide per LINE, from these rows. See retire-fec-superseded-local.ts.
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { acquireFecSlot } from '../../src/lib/fecRateLimiter.js';

export interface WindowRow {
  sub_id: string;
  file_number: number | null;
  report_year: number | null;
  report_type: string | null;
  name: string | null;
  amount: number;
  date: string;
}

const CACHE_DIR = 'data/fec-period-cache';
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/**
 * Fetch every Schedule A row for one committee/period on one contribution date.
 *
 * Pagination forwards whatever keyset cursors FEC returns in `last_indexes`. The sort is
 * `contribution_receipt_date` deliberately: the ONLY sortable Schedule A keys are
 * contribution_receipt_date and contribution_receipt_amount — `sort=-load_date`, the
 * obvious-looking choice for "newest filing first", returns HTTP 422.
 *
 * Cached on disk, and the cache is written ONLY after a complete walk, so an interrupted or
 * failed fetch leaves no file and the next run refetches rather than backfilling from a
 * truncated map (a truncated map is what would make a real row look unresolvable).
 */
export async function fetchWindow(cmte: string, period: number, date: string): Promise<WindowRow[]> {
  if (!existsSync(CACHE_DIR)) mkdirSync(CACHE_DIR, { recursive: true });
  const cache = `${CACHE_DIR}/${cmte}-${period}-${date}.json`;
  if (existsSync(cache)) return JSON.parse(readFileSync(cache, 'utf8')) as WindowRow[];

  const key = process.env.FEC_API_KEY;
  if (!key) throw new Error('FEC_API_KEY not set');

  const out: WindowRow[] = [];
  let lastIndexes: Record<string, unknown> | null = null;
  for (;;) {
    const params = new URLSearchParams({
      api_key: key,
      committee_id: cmte,
      two_year_transaction_period: String(period),
      min_date: date,
      max_date: date,
      per_page: '100',
      sort: 'contribution_receipt_date',
    });
    if (lastIndexes) {
      for (const [k, v] of Object.entries(lastIndexes)) if (v != null) params.set(k, String(v));
    }

    // Share the production cron's 15/min budget rather than competing with it — that
    // contention is what produced 2,441 FEC failures/day before Phase 174.
    await acquireFecSlot();
    const res = await fetch(`https://api.open.fec.gov/v1/schedules/schedule_a/?${params}`,
      { signal: AbortSignal.timeout(60_000) });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const j = (await res.json()) as {
      results: Record<string, unknown>[];
      pagination: { last_indexes: Record<string, unknown> | null; count: number };
    };

    for (const x of j.results) {
      out.push({
        sub_id: String(x['sub_id'] ?? ''),
        file_number: typeof x['file_number'] === 'number' ? x['file_number'] : null,
        report_year: typeof x['report_year'] === 'number' ? x['report_year'] : null,
        report_type: typeof x['report_type'] === 'string' ? x['report_type'] : null,
        name: typeof x['contributor_name'] === 'string' ? x['contributor_name'] : null,
        amount: Number(x['contribution_receipt_amount'] ?? 0),
        date: String(x['contribution_receipt_date'] ?? '').slice(0, 10),
      });
    }
    if (j.results.length === 0 || j.pagination.last_indexes == null) break;
    lastIndexes = j.pagination.last_indexes;
    await sleep(300);
  }

  writeFileSync(cache, JSON.stringify(out));
  return out;
}

/** Identity of a contribution LINE, for multiset comparison across filings of one report. */
export function lineKey(r: WindowRow): string {
  return `${r.name}|${r.amount}|${r.date}`;
}

/** Group a window's rows by report, then by filing within that report. */
export function byReportAndFiling(rows: WindowRow[]): Map<string, Map<number, WindowRow[]>> {
  const out = new Map<string, Map<number, WindowRow[]>>();
  for (const r of rows) {
    if (r.file_number == null || r.report_year == null || r.report_type == null) continue;
    const rk = `${r.report_year}|${r.report_type}`;
    if (!out.has(rk)) out.set(rk, new Map());
    const files = out.get(rk)!;
    if (!files.has(r.file_number)) files.set(r.file_number, []);
    files.get(r.file_number)!.push(r);
  }
  return out;
}
