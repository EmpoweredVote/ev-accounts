/**
 * fecAdapter — FEC Schedule A adapter implementing SourceAdapter.
 *
 * Ported from:
 *   EV-Backend/internal/campaign_finance/adapter/fec/adapter.go
 *   EV-Backend/internal/campaign_finance/adapter/fec/client.go
 *   EV-Backend/internal/campaign_finance/adapter/fec/normalizer.go
 *
 * Contains three layers in one file:
 *   1. FEC HTTP Client    — keyset pagination, 429 retry with exponential backoff
 *   2. FEC Normalizer     — memo/amendment filtering, field mapping
 *   3. FEC Upsert         — ON CONFLICT (data_source, source_transaction_id) DO UPDATE
 *
 * Export: createFecAdapter(cycle) — factory function that injects cycle at construction.
 * Fetch signature stays clean; RunIngestion creates a new adapter per cycle.
 */

import { pool } from '../db.js';
import type { SourceAdapter, FetchResult, NormalizeResult, UpsertResult, ContributionInsert } from './adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';

// Per-politician record cap — prevents timeout on high-volume candidates (e.g. CA House members).
// At 100 records/page + 4s sleep, 2500 records ≈ 25 pages ≈ 100s — well under Redis lock TTL.
// Override via MAX_RECORDS_PER_POLITICIAN env var.
const MAX_RECORDS_PER_POLITICIAN = parseInt(process.env.MAX_RECORDS_PER_POLITICIAN ?? '2500', 10);

// ---------------------------------------------------------------------------
// FEC API response types
// ---------------------------------------------------------------------------

interface FecLastIndexes {
  last_index: string;
  last_contribution_receipt_date: string;
}

interface FecPagination {
  per_page: number;
  count: number;
  pages: number;
  last_indexes: FecLastIndexes | null;
}

interface FecScheduleAResponse {
  pagination: FecPagination;
  results: Record<string, unknown>[];
}

interface FecPrincipalCommittee {
  committee_id: string;
}

interface FecCandidateSearchResponse {
  results: Array<{
    candidate_id: string;
    principal_committees: FecPrincipalCommittee[];
  }>;
}

// ---------------------------------------------------------------------------
// FEC HTTP Client — ported from client.go
// ---------------------------------------------------------------------------

/**
 * resolveCommitteeIds looks up the principal committee IDs for a given FEC candidate ID.
 * The FEC schedule_a endpoint filters by committee_id, not candidate_id.
 * Returns an empty array (with a warning) if the candidate is not found.
 */
async function resolveCommitteeIds(candidateId: string, apiKey: string): Promise<string[]> {
  const url = `https://api.open.fec.gov/v1/candidates/search/?api_key=${apiKey}&candidate_id=${candidateId}`;
  const response = await fetch(url, { signal: AbortSignal.timeout(60_000) });
  if (!response.ok) {
    throw new Error(`FEC candidate lookup failed: HTTP ${response.status} for ${candidateId}`);
  }
  const data = await response.json() as FecCandidateSearchResponse;
  const committees = data.results.flatMap((c) => c.principal_committees.map((p) => p.committee_id));
  if (committees.length === 0) {
    console.warn(`[fecAdapter] No principal committees found for candidate ${candidateId}`);
  }
  return committees;
}

/**
 * fetchAllPagesForCommittee fetches all Schedule A pages for a single committee_id.
 * Uses keyset pagination — stops on null last_indexes, not page count (FEC overcount bug).
 * Stops early if allRecords reaches the cap (passed in to enforce cross-committee limit).
 */
async function fetchAllPagesForCommittee(
  committeeId: string,
  cycle: string,
  apiKey: string,
  allRecords: Record<string, unknown>[]
): Promise<number> {
  const baseUrl = 'https://api.open.fec.gov/v1/schedules/schedule_a/';
  let totalExpected = 0;
  let firstPage = true;
  let lastIndex = '';
  let lastContributionReceiptDate = '';

  for (;;) {
    const params = new URLSearchParams({
      api_key: apiKey,
      committee_id: committeeId,
      two_year_transaction_period: cycle,
      per_page: '100',
      sort: '-contribution_receipt_date',
    });

    if (!firstPage) {
      params.set('last_index', lastIndex);
      params.set('last_contribution_receipt_date', lastContributionReceiptDate);
    }

    const page = await fetchWithRetry(`${baseUrl}?${params.toString()}`);

    if (firstPage) {
      totalExpected = page.pagination.count;
      firstPage = false;
    }

    allRecords.push(...page.results);

    if (allRecords.length >= MAX_RECORDS_PER_POLITICIAN) {
      console.warn(
        `[fecAdapter] Record cap reached at committee ${committeeId}: ${allRecords.length} records. ` +
        `Capping at ${MAX_RECORDS_PER_POLITICIAN}.`
      );
      break;
    }

    if (page.results.length === 0 || page.pagination.last_indexes == null) {
      break;
    }

    lastIndex = page.pagination.last_indexes.last_index;
    lastContributionReceiptDate = page.pagination.last_indexes.last_contribution_receipt_date;

    await sleep(4000);
  }

  return totalExpected;
}

/**
 * fetchAllPages resolves a candidate ID to its principal committee IDs, then fetches
 * all Schedule A contributions across those committees for the given election cycle.
 *
 * FEC schedule_a does not filter by candidate_id — it requires committee_id.
 * This function does the two-step lookup transparently.
 */
async function fetchAllPages(
  candidateId: string,
  cycle: string
): Promise<{ records: Record<string, unknown>[]; totalExpected: number }> {
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) {
    console.warn('[fecAdapter] FEC_API_KEY environment variable is not set — fetches will fail');
  }

  const committeeIds = await resolveCommitteeIds(candidateId, apiKey ?? '');
  if (committeeIds.length === 0) {
    return { records: [], totalExpected: 0 };
  }

  const allRecords: Record<string, unknown>[] = [];
  let totalExpected = 0;

  for (const committeeId of committeeIds) {
    if (allRecords.length >= MAX_RECORDS_PER_POLITICIAN) break;
    console.log(`[fecAdapter] Fetching committee ${committeeId} for candidate ${candidateId} cycle ${cycle}`);
    const count = await fetchAllPagesForCommittee(committeeId, cycle, apiKey ?? '', allRecords);
    totalExpected += count;
  }

  return { records: allRecords, totalExpected };
}

/**
 * fetchWithRetry wraps native fetch() with 429 exponential backoff.
 * Start delay: 1s, max delay: 60s, max retries: 3.
 */
async function fetchWithRetry(url: string, maxRetries = 3): Promise<FecScheduleAResponse> {
  let delayMs = 1000;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    const response = await fetch(url, {
      signal: AbortSignal.timeout(60_000),
    });

    if (response.status === 429) {
      if (attempt === maxRetries) {
        throw new Error(`FEC API rate limited (429) after ${maxRetries} retries`);
      }
      console.warn(`[fecAdapter] 429 rate limit — retrying in ${delayMs}ms (attempt ${attempt + 1}/${maxRetries})`);
      await sleep(delayMs);
      delayMs = Math.min(delayMs * 2, 60_000);
      continue;
    }

    if (!response.ok) {
      throw new Error(`FEC API request failed: HTTP ${response.status} ${response.statusText}`);
    }

    const data = await response.json() as FecScheduleAResponse;
    return data;
  }

  // Should never reach here
  throw new Error('FEC API fetchWithRetry: unexpected loop exit');
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------------------
// FEC Normalizer — ported from normalizer.go
// ---------------------------------------------------------------------------

/**
 * shouldSkipRecord returns true for records that must not be written to the contributions table:
 *   - memo_code="X": memo item, not incorporated into FEC totals per FEC documentation
 *   - is_amended=true: superseded filing, replaced by a later amendment
 */
function shouldSkipRecord(record: Record<string, unknown>): boolean {
  if (record['memo_code'] === 'X') return true;
  if (record['is_amended'] === true) return true;
  return false;
}

/**
 * normalizeRecords converts raw FEC Schedule A records into ContributionInsert structs.
 * Memo items and superseded amendments are counted in NormalizeResult.skipped
 * and excluded from the contributions slice.
 *
 * ElectionCycle: stored as number in JSON — convert to 4-digit string.
 * Amount: FEC returns as number — passed through directly.
 * ContributionDate: take first 10 chars of the date string (YYYY-MM-DD).
 * SourceTransactionID: built from FEC's sub_id field.
 * Confidence: always HIGH for FEC data.
 * RawRecord: full FEC response row preserved as-is for entity resolution in Phase 5+.
 */
function normalizeRecords(
  records: Record<string, unknown>[],
  ps: PoliticianSource
): NormalizeResult {
  const contributions: ContributionInsert[] = [];
  let skipped = 0;
  const totalParsed = records.length;

  for (const record of records) {
    if (shouldSkipRecord(record)) {
      skipped++;
      continue;
    }

    const contribution = normalizeRecord(record, ps);
    contributions.push(contribution);
  }

  return { contributions, skipped, totalParsed };
}

function normalizeRecord(
  record: Record<string, unknown>,
  ps: PoliticianSource
): ContributionInsert {
  // Amount — FEC returns as number
  let amount = 0;
  if (typeof record['contribution_receipt_amount'] === 'number') {
    amount = record['contribution_receipt_amount'] as number;
  }

  // Contribution date: take first 10 chars of the date string (YYYY-MM-DD)
  let contributionDate: Date | null = null;
  if (typeof record['contribution_receipt_date'] === 'string') {
    const dateStr = (record['contribution_receipt_date'] as string).slice(0, 10);
    const parsed = new Date(dateStr + 'T00:00:00Z');
    if (!isNaN(parsed.getTime())) {
      contributionDate = parsed;
    }
  }

  // Election cycle: stored as number in JSON, format as 4-digit string
  // Rounds UP to next even year from contribution date (odd +1, even unchanged)
  let electionCycle = '';
  if (typeof record['two_year_transaction_period'] === 'number') {
    electionCycle = String(Math.round(record['two_year_transaction_period'] as number));
  } else if (contributionDate !== null) {
    // Fallback: derive from contribution date
    const year = contributionDate.getUTCFullYear();
    electionCycle = String(year % 2 !== 0 ? year + 1 : year);
  }

  // Source transaction ID from FEC's sub_id field
  const sourceTransactionId =
    typeof record['sub_id'] === 'string' ? (record['sub_id'] as string) : '';

  return {
    politician_source_id: ps.id,
    donor_id: null,        // Phase 5+ entity resolution
    committee_id: null,    // Phase 5+ entity resolution
    amount,
    contribution_date: contributionDate,
    election_cycle: electionCycle,
    confidence_level: 'HIGH',
    data_source: 'fec',
    source_transaction_id: sourceTransactionId,
    raw_record: record,
  };
}

// ---------------------------------------------------------------------------
// FEC Upsert — ON CONFLICT (data_source, source_transaction_id) DO UPDATE
// ---------------------------------------------------------------------------

/**
 * upsertContributions writes contributions to the DB idempotently in batches of 100.
 * Uses ON CONFLICT (data_source, source_transaction_id) DO UPDATE SET updated_at = NOW()
 * to handle re-ingestion of existing records gracefully.
 *
 * CRITICAL:
 *   - Amount is decimal(14,2) — pg returns as string on read; Number() on read side.
 *   - Use numbered $N params. NEVER interpolate values into SQL.
 *   - Donors upsert: INSERT ... ON CONFLICT (normalized_name) DO UPDATE.
 */
async function upsertContributions(
  normalized: NormalizeResult
): Promise<UpsertResult> {
  if (normalized.contributions.length === 0) {
    return { inserted: 0, skipped: 0, unresolved: 0, errors: 0 };
  }

  let inserted = 0;
  let skipped = 0;
  let errors = 0;

  // Process in batches of 100
  const batchSize = 100;
  for (let i = 0; i < normalized.contributions.length; i += batchSize) {
    const batch = normalized.contributions.slice(i, i + batchSize);

    try {
      const { batchInserted, batchSkipped } = await upsertBatch(batch);
      inserted += batchInserted;
      skipped += batchSkipped;
    } catch (err) {
      // Count batch as errors but continue with next batch
      errors += batch.length;
      console.error(`[fecAdapter] upsert batch error at offset ${i}:`, err);
    }
  }

  return { inserted, skipped, unresolved: 0, errors };
}

/**
 * upsertBatch inserts one batch of contributions using a multi-row VALUES insert.
 * ON CONFLICT (data_source, source_transaction_id) DO UPDATE SET updated_at = NOW()
 * so we can distinguish inserts from updates via xmax trick.
 * Returns count of newly inserted vs skipped (already existed).
 */
async function upsertBatch(
  batch: ContributionInsert[]
): Promise<{ batchInserted: number; batchSkipped: number }> {
  if (batch.length === 0) return { batchInserted: 0, batchSkipped: 0 };

  // Build multi-row parameterized VALUES clause
  // Each row: (politician_source_id, amount, contribution_date, election_cycle,
  //            confidence_level, data_source, source_transaction_id, raw_record)
  const params: unknown[] = [];
  const valuePlaceholders: string[] = [];
  const COLS_PER_ROW = 8;

  for (let idx = 0; idx < batch.length; idx++) {
    const c = batch[idx];
    const base = idx * COLS_PER_ROW + 1;
    valuePlaceholders.push(
      `($${base}, $${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5}, $${base + 6}, $${base + 7}::jsonb)`
    );
    params.push(
      c.politician_source_id,
      c.amount,
      c.contribution_date ? c.contribution_date.toISOString() : null,
      c.election_cycle,
      c.confidence_level,
      c.data_source,
      c.source_transaction_id,
      JSON.stringify(c.raw_record)
    );
  }

  const sql = `
    INSERT INTO transparent_motivations.contributions
      (politician_source_id, amount, contribution_date, election_cycle,
       confidence_level, data_source, source_transaction_id, raw_record)
    VALUES ${valuePlaceholders.join(', ')}
    ON CONFLICT (data_source, source_transaction_id)
    DO UPDATE SET updated_at = NOW()
    RETURNING (xmax = 0) AS is_insert
  `;

  const result = await pool.query<{ is_insert: boolean }>(sql, params);

  // xmax = 0 means the row was inserted (not updated)
  let batchInserted = 0;
  let batchSkipped = 0;
  for (const row of result.rows) {
    if (row.is_insert) {
      batchInserted++;
    } else {
      batchSkipped++;
    }
  }

  return { batchInserted, batchSkipped };
}

// ---------------------------------------------------------------------------
// FECAdapter — implements SourceAdapter
// ---------------------------------------------------------------------------

/**
 * FECAdapter implements SourceAdapter for the FEC Schedule A API.
 * Cycle must be set before calling fetch — use createFecAdapter(cycle) to construct.
 */
class FECAdapter implements SourceAdapter {
  private readonly cycle: string;

  constructor(cycle: string) {
    this.cycle = cycle;
  }

  name(): string {
    return 'fec';
  }

  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    const { records, totalExpected } = await fetchAllPages(ps.external_id, this.cycle);
    return {
      records,
      totalExpected,
      totalFetched: records.length,
    };
  }

  async normalize(raw: FetchResult, ps: PoliticianSource): Promise<NormalizeResult> {
    return normalizeRecords(raw.records, ps);
  }

  async upsert(normalized: NormalizeResult): Promise<UpsertResult> {
    return upsertContributions(normalized);
  }
}

// ---------------------------------------------------------------------------
// Factory function
// ---------------------------------------------------------------------------

/**
 * createFecAdapter creates a FECAdapter configured for the given election cycle (e.g. "2024").
 * Factory function injects cycle at construction — Fetch signature stays clean.
 * RunIngestion creates a new adapter per cycle per politician.
 */
export function createFecAdapter(cycle: string): SourceAdapter {
  return new FECAdapter(cycle);
}
