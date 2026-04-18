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
 * Skipped counts memo items (memo_code="X") and superseded amendments (is_amended=true).
 * TotalParsed is the number of rows the parser examined for this politician (used by callers
 * to compute >1% skip threshold).
 */
export interface NormalizeResult {
  contributions: ContributionInsert[];
  skipped: number;
  totalParsed: number;
}

/**
 * UpsertResult is returned by the Upsert phase.
 * Inserted: rows newly written to contributions table.
 * Skipped: rows already present (ON CONFLICT DO UPDATE / DO NOTHING).
 * Unresolved: records with no matching PoliticianSource (logged but not inserted).
 * Errors: count of records that failed for unexpected reasons.
 */
export interface UpsertResult {
  inserted: number;
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
