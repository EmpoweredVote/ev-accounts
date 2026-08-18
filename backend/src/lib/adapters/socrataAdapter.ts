/**
 * socrataAdapter — LA City Socrata SODA v2.0 adapter implementing SourceAdapter.
 *
 * Ported from:
 *   EV-Backend/internal/campaign_finance/adapter/socrata/adapter.go
 *   EV-Backend/internal/campaign_finance/adapter/socrata/client.go
 *
 * Contains three layers in one file:
 *   1. SODA HTTP Client   — $limit/$offset pagination, 429 retry with exponential backoff
 *   2. Normalizer         — con_amount string→number, composite source_transaction_id
 *   3. Upsert             — ON CONFLICT (data_source, source_transaction_id) DO UPDATE
 *
 * CRITICAL PITFALL: con_amount arrives as a JSON string (not a number).
 * A direct `as number` type assertion returns silent zero. Always use parseFloat().
 *
 * Export: createSocrataAdapter() — factory function.
 */

import { pool } from '../db.js';
import type {
  SourceAdapter,
  FetchResult,
  NormalizeResult,
  UpsertResult,
  ContributionInsert,
} from './adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';
import { normalizeDonorName } from './normalizeDonorName.js';

// ---------------------------------------------------------------------------
// Socrata SODA API constants — dataset m6g2-gc6c (LA City contributions)
// ---------------------------------------------------------------------------

const SODA_BASE_URL = 'https://data.lacity.org/resource/m6g2-gc6c.json';
const PAGE_LIMIT = 50000; // SODA hard cap per request
const MAX_RETRIES = 3;

// ---------------------------------------------------------------------------
// SODA HTTP Client — ported from client.go
// ---------------------------------------------------------------------------

/**
 * fetchAllPages retrieves all contribution records for the given committee ID.
 * If `since` is provided, adds a con_date filter for delta-fetch.
 * Paginates via $limit/$offset until a page returns fewer than PAGE_LIMIT rows.
 *
 * SOCRATA_APP_TOKEN: logged as warning at adapter invocation if absent.
 * Without a token requests still work but are rate-limited more aggressively.
 */
async function fetchAllPages(
  cmtId: string,
  appToken: string | undefined,
  since: Date | null
): Promise<Record<string, unknown>[]> {
  let where = `cmt_id='${cmtId}'`;
  if (since !== null) {
    const sinceStr = since.toISOString().replace('Z', '').slice(0, 19) + '.000';
    where += ` AND con_date>'${sinceStr}'`;
  }

  const allRecords: Record<string, unknown>[] = [];
  let offset = 0;

  for (;;) {
    const page = await fetchPage(where, offset, appToken);
    allRecords.push(...page);

    if (page.length < PAGE_LIMIT) {
      // Last page — done.
      break;
    }

    offset += PAGE_LIMIT;

    // Courtesy throttle between pages.
    await sleep(100);
  }

  return allRecords;
}

/**
 * fetchPage retrieves a single page with exponential backoff retry.
 * Retries on HTTP 429 (rate limit) and 5xx (server errors).
 * Fails immediately on other 4xx errors.
 */
async function fetchPage(
  where: string,
  offset: number,
  appToken: string | undefined
): Promise<Record<string, unknown>[]> {
  const backoffMs = [2000, 4000, 8000];

  let lastErr: Error | null = null;

  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    if (attempt > 0) {
      await sleep(backoffMs[attempt - 1] ?? 8000);
    }

    const params = new URLSearchParams({
      $where: where,
      $limit: String(PAGE_LIMIT),
      $offset: String(offset),
    });

    const reqUrl = `${SODA_BASE_URL}?${params.toString()}`;

    const headers: Record<string, string> = {};
    if (appToken) {
      headers['X-App-Token'] = appToken;
    }

    let resp: Response;
    try {
      resp = await fetch(reqUrl, { headers });
    } catch (err) {
      lastErr = err instanceof Error ? err : new Error(String(err));
      continue; // retry on network error
    }

    if (resp.status === 200) {
      const records = (await resp.json()) as Record<string, unknown>[];
      return records;
    }

    // Retry on 429 and 5xx.
    if (resp.status === 429 || resp.status >= 500) {
      lastErr = new Error(`fetchPage: HTTP ${resp.status} (retryable)`);
      continue;
    }

    // Non-retryable 4xx — fail immediately.
    throw new Error(`fetchPage (offset=${offset}): HTTP ${resp.status} (non-retryable)`);
  }

  throw new Error(
    `fetchPage (offset=${offset}): exhausted ${MAX_RETRIES} retries: ${lastErr?.message ?? 'unknown'}`
  );
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------------------
// Delta-fetch helper — queries ingestion_runs for last completed la_socrata run
// ---------------------------------------------------------------------------

/**
 * getLastRunDate queries transparent_motivations.ingestion_runs for the most
 * recent completed la_socrata run for this politician source.
 * Returns null if no prior run exists (triggers full fetch).
 */
async function getLastRunDate(politicianSourceId: string): Promise<Date | null> {
  const result = await pool.query<{ completed_at: Date }>(
    `SELECT completed_at
     FROM transparent_motivations.ingestion_runs
     WHERE politician_source_id = $1
       AND adapter_name = 'la_socrata'
       AND status = 'completed'
     ORDER BY completed_at DESC
     LIMIT 1`,
    [politicianSourceId]
  );

  if (result.rows.length === 0 || result.rows[0].completed_at == null) {
    return null;
  }

  return new Date(result.rows[0].completed_at);
}

// ---------------------------------------------------------------------------
// Normalizer — ported from adapter.go Normalize()
// ---------------------------------------------------------------------------

/**
 * normalizeRecords converts raw Socrata JSON records into ContributionInsert structs.
 *
 * CRITICAL: con_amount is a JSON string in Socrata responses.
 * parseFloat() is required — direct `as number` type assertion returns silent zero.
 *
 * source_transaction_id is a composite: `cmt_id|con_date|con_name|con_amount`
 * con_name is truncated to keep total within 128-char DB limit.
 *
 * ElectionCycle rounds UP to next even year from con_date (odd years +1, even unchanged).
 * Confidence level: 'MEDIUM' for LA Socrata (city-level data source).
 */
function normalizeRecords(
  records: Record<string, unknown>[],
  ps: PoliticianSource
): { contributions: ContributionInsert[]; skipped: number } {
  const contributions: ContributionInsert[] = [];
  let skipped = 0;

  for (const rec of records) {
    const cmtId = (rec['cmt_id'] as string | undefined) ?? '';
    const conName = (rec['con_name'] as string | undefined) ?? '';

    // CRITICAL: con_amount is a JSON string — use parseFloat(), not type assertion.
    const amountStr = (rec['con_amount'] as string | undefined) ?? '';
    if (amountStr === '') {
      skipped++;
      continue;
    }
    const amount = parseFloat(amountStr);
    if (!isFinite(amount)) {
      console.warn(
        `[socrataAdapter] skip record — con_amount parse failed (value=${JSON.stringify(amountStr)})`
      );
      skipped++;
      continue;
    }

    // con_date parsing — Socrata format: "2006-01-02T15:04:05.000"
    const dateStr = (rec['con_date'] as string | undefined) ?? '';
    if (dateStr === '') {
      skipped++;
      continue;
    }
    const conDate = new Date(dateStr);
    if (isNaN(conDate.getTime())) {
      console.warn(
        `[socrataAdapter] skip record — con_date parse failed (value=${JSON.stringify(dateStr)})`
      );
      skipped++;
      continue;
    }

    // Election cycle: round UP to next even year.
    let year = conDate.getFullYear();
    if (year % 2 !== 0) {
      year += 1;
    }
    const electionCycle = String(year);

    // Build composite source_transaction_id, capped at 128 chars total.
    // Format: cmt_id|con_date|con_name|con_amount (3 pipe separators)
    const maxNameLen = 128 - cmtId.length - dateStr.length - amountStr.length - 3;
    const conNameForId =
      maxNameLen > 0
        ? conName.slice(0, maxNameLen)
        : '';
    const sourceTransactionId = `${cmtId}|${dateStr}|${conNameForId}|${amountStr}`;

    // Extract optional fields.
    const conCityNm = (rec['con_city_nm'] as string | undefined) ?? '';
    const conStateNm = (rec['con_state_nm'] as string | undefined) ?? '';
    const conOccp = (rec['con_occp'] as string | undefined) ?? '';
    const conEmpr = (rec['con_empr'] as string | undefined) ?? '';

    // Enrich raw record with optional fields for storage.
    // Standard field names (contributor_*) are aliases so campaignFinanceService
    // can extract them without source-specific knowledge.
    const enrichedRec: Record<string, unknown> = {
      ...rec,
      con_city_nm: conCityNm,
      con_state_nm: conStateNm,
      con_occp: conOccp,
      con_empr: conEmpr,
      contributor_name: conName,
      contributor_occupation: conOccp,
      contributor_employer: conEmpr,
      contributor_city: conCityNm,
      contributor_state: conStateNm,
    };

    contributions.push({
      politician_source_id: ps.id,
      donor_id: null,
      committee_id: null,
      amount,
      contribution_date: conDate,
      election_cycle: electionCycle,
      confidence_level: 'MEDIUM',
      data_source: 'la_socrata',
      source_transaction_id: sourceTransactionId,
      raw_record: enrichedRec,
      donor_name_normalized: normalizeDonorName(conName || null),
    });
  }

  return { contributions, skipped };
}

// ---------------------------------------------------------------------------
// Upsert — ported from adapter.go Upsert()
// ---------------------------------------------------------------------------

/**
 * upsertContributions writes normalized contributions to the DB idempotently.
 * Uses ON CONFLICT (data_source, source_transaction_id) DO UPDATE SET updated_at = NOW().
 * Processes in batches of 100 for per-batch error isolation.
 */
async function upsertContributions(contributions: ContributionInsert[]): Promise<UpsertResult> {
  if (contributions.length === 0) {
    return { inserted: 0, updated: 0, skipped: 0, unresolved: 0, errors: 0 };
  }

  // Deduplicate by source_transaction_id. Socrata data can have duplicate rows
  // that produce the same composite key. PostgreSQL throws "ON CONFLICT DO UPDATE
  // command cannot affect row a second time" when two rows in the same batch share
  // a conflict key — dedup before batching to prevent this.
  const seen = new Map<string, ContributionInsert>();
  for (const c of contributions) {
    seen.set(c.source_transaction_id, c);
  }
  const deduped = Array.from(seen.values());
  // Collapsed duplicates reach the database nowhere — the only genuine "skipped" here,
  // and previously uncounted.
  const totalDropped = contributions.length - deduped.length;
  contributions = deduped;

  let totalInserted = 0;
  let totalUpdated = 0;
  let totalErrors = 0;

  const BATCH_SIZE = 100;

  for (let i = 0; i < contributions.length; i += BATCH_SIZE) {
    const batch = contributions.slice(i, i + BATCH_SIZE);

    try {
      // Build multi-row INSERT with numbered $N params.
      // 9 columns per row.
      const cols = 9;
      const valuePlaceholders = batch.map((_, rowIdx) => {
        const base = rowIdx * cols;
        return `($${base + 1},$${base + 2},$${base + 3},$${base + 4},$${base + 5},$${base + 6},$${base + 7},$${base + 8},$${base + 9})`;
      });

      const params: unknown[] = [];
      for (const c of batch) {
        params.push(
          c.politician_source_id,
          c.donor_id,
          c.committee_id,
          c.amount,
          c.contribution_date ? c.contribution_date.toISOString() : null,
          c.election_cycle,
          c.confidence_level,
          c.data_source,
          c.source_transaction_id
          // raw_record inserted below via jsonb cast
        );
      }

      // raw_record needs its own set of params with jsonb cast.
      // Rebuild: interleave raw_record as $10, donor_name_normalized as $11, etc.
      const params2: unknown[] = [];
      const valuePlaceholders2 = batch.map((_, rowIdx) => {
        const base = rowIdx * 11;
        return `($${base + 1},$${base + 2},$${base + 3},$${base + 4},$${base + 5},$${base + 6},$${base + 7},$${base + 8},$${base + 9},$${base + 10},$${base + 11})`;
      });

      for (const c of batch) {
        params2.push(
          c.politician_source_id,
          c.donor_id,
          c.committee_id,
          c.amount,
          c.contribution_date ? c.contribution_date.toISOString() : null,
          c.election_cycle,
          c.confidence_level,
          c.data_source,
          c.source_transaction_id,
          JSON.stringify(c.raw_record),
          c.donor_name_normalized
        );
      }

      const sql = `
        INSERT INTO transparent_motivations.contributions
          (politician_source_id, donor_id, committee_id, amount, contribution_date,
           election_cycle, confidence_level, data_source, source_transaction_id, raw_record,
           donor_name_normalized)
        VALUES ${valuePlaceholders2.join(',')}
        ON CONFLICT (data_source, source_transaction_id)
          DO UPDATE SET
            updated_at = NOW(),
            donor_name_normalized = EXCLUDED.donor_name_normalized
        RETURNING (xmax = 0) AS inserted`;

      const result = await pool.query<{ inserted: boolean }>(sql, params2);

      // Count inserts vs updates via xmax trick.
      let batchInserted = 0;
      let batchSkipped = 0;
      for (const row of result.rows) {
        if (row.inserted) {
          batchInserted++;
        } else {
          batchSkipped++;
        }
      }

      totalInserted += batchInserted;
      totalUpdated += batchSkipped; // ON CONFLICT rows were REFRESHED, not skipped
    } catch (err) {
      console.error(`[socrataAdapter] upsert batch error (i=${i}): ${err instanceof Error ? err.message : String(err)}`);
      totalErrors++;
    }
  }

  return {
    inserted: totalInserted,
    updated: totalUpdated,
    skipped: totalDropped,
    unresolved: 0,
    errors: totalErrors,
  };
}

// ---------------------------------------------------------------------------
// SocrataAdapter class — implements SourceAdapter
// ---------------------------------------------------------------------------

class SocrataAdapter implements SourceAdapter {
  name(): string {
    return 'la_socrata';
  }

  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    // Log warning at invocation time if token is absent — server does NOT crash.
    const appToken = process.env.SOCRATA_APP_TOKEN;
    if (!appToken) {
      console.warn(
        '[socrataAdapter] SOCRATA_APP_TOKEN is not set — requests will be throttled. ' +
          'Obtain a free token at https://data.lacity.org/profile/edit/developer_settings'
      );
    }

    // Delta-fetch: query ingestion_runs for last completed la_socrata run.
    let since: Date | null = null;
    try {
      since = await getLastRunDate(ps.id);
    } catch (err) {
      // Non-fatal: fall back to full fetch if delta-query fails.
      console.warn(
        `[socrataAdapter] delta-fetch query failed, falling back to full fetch: ${err instanceof Error ? err.message : String(err)}`
      );
    }

    const records = await fetchAllPages(ps.external_id, appToken, since);

    return {
      records,
      totalExpected: records.length,
      totalFetched: records.length,
    };
  }

  async normalize(raw: FetchResult, ps: PoliticianSource): Promise<NormalizeResult> {
    const { contributions, skipped } = normalizeRecords(raw.records, ps);

    return {
      contributions,
      skipped,
      totalParsed: raw.records.length,
    };
  }

  async upsert(normalized: NormalizeResult): Promise<UpsertResult> {
    return upsertContributions(normalized.contributions);
  }
}

// ---------------------------------------------------------------------------
// Factory export
// ---------------------------------------------------------------------------

/**
 * createSocrataAdapter returns a new SocrataAdapter instance implementing SourceAdapter.
 * The adapter reads SOCRATA_APP_TOKEN from process.env at fetch time (not construction),
 * so the warning is deferred to actual invocation — server startup is not affected.
 */
export function createSocrataAdapter(): SourceAdapter {
  return new SocrataAdapter();
}
