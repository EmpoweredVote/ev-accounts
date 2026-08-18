/**
 * adapterInterface — SourceAdapter contract for all campaign finance ingestion adapters.
 *
 * Ported from:
 *   EV-Backend/internal/campaign_finance/adapter/adapter.go
 *
 * All data source adapters (FEC, Cal-Access, Indiana, LA Socrata) implement
 * the SourceAdapter interface. Adding a new source means implementing this
 * interface — no existing adapter code changes.
 */

import type { PoliticianSource } from '../campaignFinanceService.js';

// ---------------------------------------------------------------------------
// Pipeline result types — ported field-for-field from adapter.go
// ---------------------------------------------------------------------------

/**
 * FetchResult is returned by the Fetch phase of the adapter pipeline.
 * TotalExpected comes from pagination.count on the first FEC API page.
 * TotalFetched is the actual number of records received across all pages.
 */
export interface FetchResult {
  records: Record<string, unknown>[];
  totalExpected: number;
  totalFetched: number;
}

/**
 * NormalizeResult is returned by the Normalize phase.
 * Skipped counts memo items (memo_code="X").
 * TotalParsed is the number of rows the parser examined for this politician (used by callers
 * to compute >1% skip threshold).
 * SupersededSubIds (FEC-04, optional — only the FEC adapter populates it) lists the OLD
 * source_transaction_id values that an amended row's original_sub_id points at; the Upsert
 * phase retires those rows so amended transactions don't double-count. Additive field — other
 * adapters (Cal-Access, Indiana, LA Socrata) never set it and are unaffected.
 */
/**
 * SupersededFiling identifies one FEC report whose EARLIER versions must be retired.
 *
 * FEC amendments supersede a whole report, not individual lines: an amended filing re-reports
 * every Schedule A line for its coverage period under a NEW file_number and NEW sub_ids. So the
 * unit of supersession is (committee, report_year, report_type) and the discriminator is
 * file_number — the highest file_number for that triple is the current version.
 *
 * Verified live 2026-07-25 on committee C00256925, report 12P/2020, which was double-counted in
 * prod: the same $250 2020-05-07 contribution appears under file 1409022 (load 2020-05-30) and
 * again under file 1484476 (load 2020-12-30). Note `transaction_id` DIFFERS between the two
 * versions (`VSHCSM0N319` vs `2208859`), so it cannot be used as a stable dedup key, and
 * `original_sub_id` is null on both — which is why the (committee, year, type) + file_number
 * rule is the one that works.
 */
export interface SupersededFiling {
  politicianSourceId: string;
  committeeId: string;
  reportYear: number;
  reportType: string;
  /** Highest file_number seen for this report in the incoming batch. */
  maxFileNumber: number;
}

export interface NormalizeResult {
  contributions: ContributionInsert[];
  /**
   * Rows the normalizer could NOT use — a DEFECT signal. Missing required fields,
   * unparseable amounts, malformed dates. runIngestion warns above 1% of totalParsed.
   *
   * 🔴 Do NOT put deliberate, rule-based omissions here; use `excluded`. Conflating the
   * two is what produced 9,636 false "skip threshold exceeded" warnings on FEC in 60
   * days (median 42%, p95 71%): FEC's only omission is `memo_code === 'X'`, an
   * intentional exclusion, while Cal-Access's are genuine parse failures. One field,
   * two opposite meanings, so the 1% alarm could never mean anything on FEC — and would
   * have stayed silent about a real FEC defect hiding under the memo noise.
   */
  skipped: number;
  /**
   * Rows deliberately omitted by a business rule and working exactly as intended —
   * NOT a defect and never a warning. FEC memo items (`memo_code === 'X'`) live here:
   * they are sub-itemizations of earmarked/conduit contributions, and counting them
   * would double-count ActBlue money.
   *
   * Still added to `ingestion_runs.records_skipped` so that column keeps meaning
   * "rows fetched but not inserted" and stays continuous with historical rows.
   */
  excluded?: number;
  totalParsed: number;
  supersededSubIds?: string[];
  /** FEC-04b: reports whose earlier filings should be retired. See SupersededFiling. */
  supersededFilings?: SupersededFiling[];
}

/**
 * UpsertResult is returned by the Upsert phase.
 * Inserted: rows newly written to contributions table.
 * Updated: rows that already existed and were REFRESHED from the source.
 * Skipped: rows fetched but written nowhere at all.
 * Unresolved: records with no matching PoliticianSource (logged but not inserted).
 * Errors: count of records that failed for unexpected reasons.
 */
export interface UpsertResult {
  inserted: number;

  /**
   * Pre-existing rows whose stored values were REFRESHED by the ON CONFLICT DO UPDATE.
   *
   * 🔴 Split out from `skipped` on 2026-08-18 because the two had become opposites while
   * sharing one field. ocpf and netfile refresh amount / contribution_date / raw_record on
   * conflict, so re-reading a filer's history REPAIRS its rows — that is the mechanism that
   * corrected a $15.6M amount defect. Reporting 89,557 repaired rows as "skipped" states
   * the reverse of what happened, and made a successful repair indistinguishable from a
   * run that declined to write anything.
   *
   * Same failure shape as the `NormalizeResult.skipped`/`excluded` conflation below: one
   * field, two opposite meanings, so neither number could be trusted.
   */
  updated: number;

  /**
   * Rows fetched but written NOWHERE — not inserted and not updated. Today this is
   * within-batch duplicate keys dropped before the INSERT (two source records colliding on
   * one source_transaction_id); those were previously discarded uncounted.
   *
   * A conflict row that got refreshed is NOT this. See `updated`.
   */
  skipped: number;
  unresolved: number;
  errors: number;
}

/**
 * ContributionInsert is the shape of a contribution ready for DB upsert.
 * Mirrors transparent_motivations.contributions columns.
 * politician_source_id is required; donor_id and committee_id are nil in Phase 2
 * (entity resolution in Phase 5+).
 */
export interface ContributionInsert {
  politician_source_id: string;
  donor_id: string | null;
  committee_id: string | null;
  amount: number;
  contribution_date: Date | null;
  election_cycle: string;
  confidence_level: 'HIGH' | 'MEDIUM' | 'ESTIMATED';
  data_source: string;
  source_transaction_id: string;
  raw_record: Record<string, unknown>;
  donor_name_normalized: string;
}

// ---------------------------------------------------------------------------
// SourceAdapter interface
// ---------------------------------------------------------------------------

/**
 * SourceAdapter is the contract all ingestion adapters must implement.
 * Adding a new data source means implementing this interface — no existing
 * adapter code changes.
 */
export interface SourceAdapter {
  /**
   * name returns the data_source value used in contributions.data_source.
   * Must match the CHECK constraint values:
   *   fec | indiana | cal_access | la_socrata | community_verified
   */
  name(): string;

  /**
   * fetch retrieves all raw records for the given politician source.
   * For FEC: fetches all Schedule A pages via keyset pagination.
   */
  fetch(ps: PoliticianSource): Promise<FetchResult>;

  /**
   * normalize converts raw records into ContributionInsert structs ready for upsert.
   * Filtering of memo items and amended filings happens here.
   */
  normalize(raw: FetchResult, ps: PoliticianSource): Promise<NormalizeResult>;

  /**
   * upsert writes normalized contributions to the DB idempotently.
   * Uses ON CONFLICT (data_source, source_transaction_id) DO UPDATE.
   */
  upsert(normalized: NormalizeResult): Promise<UpsertResult>;
}

// ---------------------------------------------------------------------------
// StreamingAdapter — optional capability for incremental (per-window) persistence
// ---------------------------------------------------------------------------

/**
 * BatchSink receives one batch of raw source records as they arrive during fetch,
 * so the caller (runIngestion) can normalize + upsert incrementally rather than
 * buffering an entire (source, cycle) pair in memory and committing once at the end.
 */
export type BatchSink = (records: Record<string, unknown>[]) => Promise<void>;

/**
 * StreamingAdapter is an optional capability an adapter may implement (duck-typed,
 * same pattern as ETagProvider). When present, runIngestion drives the adapter via
 * fetchStream — normalizing and upserting each batch as it is fetched — instead of
 * the buffer-everything fetch → normalize → upsert path.
 *
 * This is what lets a 500k+ record mega-committee pull survive a mid-pair dyno
 * restart: each date-window's records are persisted as the window completes, so a
 * restart preserves already-fetched windows instead of losing the whole pull.
 *
 * fetchStream MUST call onBatch for every batch it fetches and return a FetchResult
 * whose records array is EMPTY (records were streamed, not buffered) but whose
 * totalExpected / totalFetched counters are accurate for the completeness check.
 */
export interface StreamingAdapter {
  /**
   * fetchStream streams records to onBatch as they are fetched. An optional AbortSignal
   * lets a caller (e.g. the sweep's wall-clock budget) stop the fetch mid-pair; already-
   * streamed batches stay persisted and the pair resumes on a later run.
   */
  fetchStream(ps: PoliticianSource, onBatch: BatchSink, signal?: AbortSignal): Promise<FetchResult>;
}

// ---------------------------------------------------------------------------
// ETagProvider — duck-typed inline interface for Cal-Access ETag tracking
// Ported from run.go etagProvider inline interface (Go duck typing).
// ---------------------------------------------------------------------------

/**
 * ETagProvider is an optional capability an adapter may implement.
 * Cal-Access implements this to track ZIP file ETag and download time.
 * RunIngestion checks for this interface at runtime via duck typing.
 */
export interface ETagProvider {
  getETag(): string | null;
  getZIPDownloadedAt(): Date | null;
}
