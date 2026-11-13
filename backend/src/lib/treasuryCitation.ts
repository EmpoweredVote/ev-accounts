/**
 * ⚠⚠⚠ WHAT THE READER IS TOLD TO GO AND CHECK.
 *
 * `data_source_info` becomes the href under every chart in Treasury Tracker, so
 * it carries the one claim a reader can verify for themselves. It lives in its
 * own module, apart from `treasuryService.ts`, for a reason worth keeping:
 * importing that file pulls in `db.ts` → `env.ts`, which calls `process.exit(1)`
 * when the environment is not configured. A rule this consequential must be
 * testable with no database and no credentials, or it is only ever checked by
 * the `skipIf(!hasLiveDb)` suites — which is to say, sometimes.
 *
 * ── THE RULE ───────────────────────────────────────────────────────────────
 *
 * THE MOST PRECISE THING WE HOLD WINS. Never the registry's landing page when
 * the row itself names a document.
 *
 * This used to take the registry branch WHOLE whenever a budget carried a
 * `data_source_id`, and `budgets.source_url` never entered into it. That sent
 * **704 budgets to a portal root while the row beside them held the exact
 * dataset page their figures were parsed from**:
 *
 *     CA State Controller   696 budgets / 87 entities
 *        reader was sent to   https://bythenumbers.sco.ca.gov
 *        the row already held .../d/ju3w-4gxp  and  .../d/rrtv-rsj9
 *     West Hollywood          8 budgets, EIGHT distinct dataset pages
 *        reader was sent to   https://data.weho.org
 *
 * ⭐ Found by treasury-tracker#381, which had just finished repairing the same
 * defect in a loader (#380 — eleven South Carolina cities citing one finance
 * landing page for ten fiscal years, 186 budgets). The lesson transfers
 * exactly: **a landing page is not a lesser citation, it is a wrong one.** It
 * answers 200, so no liveness gate can object; the reader simply arrives at a
 * list instead of at the statements, and after a CMS move not even that.
 *
 * ⚠ `displayName` stays the REGISTRY's on purpose. "CA State Controller" names
 * the publisher, which is what the chip is for; `data_source` on the row is an
 * internal dataset label ("CA State Controller - Expenditures").
 *
 * ⚠⚠ `fetchedAt` is a HISTORICAL FIELD NAME — the client renders it "as of".
 * `source_date` is what the figures are AS OF (period end / publication);
 * `ds_last_synced_at` is merely when a job last ran. Preferring `source_date`
 * is part of this fix, not a bonus: of the 937 registry-attributed budgets, 696
 * carry a `source_date` and every one of them was being labelled with a sync
 * timestamp instead. ⭐ No budget has a `source_date` without a `source_url`
 * (measured 2026-11-10: 704 with a URL, 696 of those dated, 0 the other way),
 * so this cannot pair one row's as-of date with another row's link.
 *
 * ⛔ A budget with NO `source_url` still gets the registry entry — that is the
 * best thing we hold for it, and 233 budgets depend on it. This NARROWS the
 * fallback; it must never remove it, or those pages lose their chip entirely.
 */

export interface DataSourceInfo {
  displayName: string;
  url: string;
  datasetUrl: string | null;
  /** Historical name. Rendered "as of" — see the module header. */
  fetchedAt: string | null;
}

/**
 * Only the attribution columns. Declared narrowly so `BudgetRow` satisfies it
 * structurally without this module knowing anything about the rest of a budget
 * — and so a test can build one without a database row.
 */
export interface BudgetAttribution {
  data_source: string | null;
  source_url: string | null;
  source_date: string | null;
  ds_display_name: string | null;
  ds_url: string | null;
  ds_base_url: string | null;
  ds_last_synced_at: string | null;
}

export function dataSourceInfoFor(row: BudgetAttribution): DataSourceInfo | null {
  // The budget is attributed to a registered publisher (`data_source_id`).
  // ⚠ BOTH halves are required: a half-filled registry entry must fall through
  // rather than serve a chip with an empty href.
  if (row.ds_display_name && row.ds_url) {
    return {
      displayName: row.ds_display_name,
      url: row.source_url ?? row.ds_url,
      datasetUrl: row.source_url ?? row.ds_base_url ?? null,
      fetchedAt: row.source_date ?? row.ds_last_synced_at ?? null,
    };
  }

  // Municipal attribution, straight off the row.
  if (row.data_source && row.source_url && row.source_date) {
    return {
      displayName: row.data_source,
      url: row.source_url,
      datasetUrl: row.source_url,
      fetchedAt: row.source_date,
    };
  }

  // ⚠ Not an oversight. A row with no attributable source must serve NO chip
  // rather than an invented one — Treasury Tracker counts these (24,938
  // budgets against a declared baseline that may not grow) precisely so they
  // stay visible as missing instead of being papered over here.
  return null;
}
