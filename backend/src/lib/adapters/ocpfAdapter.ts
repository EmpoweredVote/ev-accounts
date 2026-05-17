/**
 * ocpfAdapter — Massachusetts OCPF adapter implementing SourceAdapter.
 * Base URL: https://api.ocpf.us
 * Contributions endpoint: GET /search/items?SearchTypeId=1&SearchTypeCategory=receipts&CpfId={cpfId}&pageNumber={n}&pageSize=250
 * No auth required. Paginate until items.length < pageSize.
 * Export: createOcpfAdapter() — factory function.
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
// Constants
// ---------------------------------------------------------------------------

const OCPF_BASE = 'https://api.ocpf.us';
const PAGE_SIZE = 250;

const sleep = (ms: number): Promise<void> => new Promise(resolve => setTimeout(resolve, ms));

// ---------------------------------------------------------------------------
// OCPF API response types
// ---------------------------------------------------------------------------

interface OcpfSearchResponse {
  items: OcpfItem[];
  // No total count — paginate until items.length < pageSize
}

interface OcpfItem {
  id: number;                       // unique transaction id
  cpfId: number;                    // filer's CPF ID (matches external_id in politician_sources)
  amount: string;                   // "$50.00" — strip "$", parse to Number
  date: string;                     // "MM/DD/YYYY"
  firstName: string;
  lastName: string;
  contributorAddress: string;
  contributorCity: string;
  contributorState: string;
  contributorZip: string;
  recordTypeDescription: string;    // "Individual", "Committee", "PAC", etc.
  officeDescription: string;
  electionYear: number;
}

// ---------------------------------------------------------------------------
// Fetch — paginate OCPF receipts endpoint until items.length < PAGE_SIZE
// ---------------------------------------------------------------------------

async function fetchOcpfReceipts(cpfId: string): Promise<Record<string, unknown>[]> {
  const allItems: Record<string, unknown>[] = [];
  let pageNumber = 1;

  for (;;) {
    const url =
      `${OCPF_BASE}/search/items` +
      `?SearchTypeId=1&SearchTypeCategory=receipts` +
      `&CpfId=${encodeURIComponent(cpfId)}` +
      `&pageNumber=${pageNumber}&pageSize=${PAGE_SIZE}`;

    let response: Response;
    try {
      response = await fetch(url, {
        signal: AbortSignal.timeout(30_000),
      });
    } catch (err) {
      throw new Error(
        `[ocpfAdapter] fetch error cpfId=${cpfId} page=${pageNumber}: ${err instanceof Error ? err.message : String(err)}`
      );
    }

    if (response.status !== 200) {
      throw new Error(
        `[ocpfAdapter] HTTP ${response.status} for cpfId=${cpfId} page=${pageNumber}`
      );
    }

    const body = await response.json() as OcpfSearchResponse;
    const items = body.items ?? [];

    for (const item of items) {
      allItems.push(item as unknown as Record<string, unknown>);
    }

    if (items.length < PAGE_SIZE) {
      // Last page
      break;
    }

    pageNumber++;
    // Polite delay between pages — no documented rate limit, be conservative
    await sleep(500);
  }

  return allItems;
}

// ---------------------------------------------------------------------------
// Normalize — convert OcpfItem fields to ContributionInsert
// ---------------------------------------------------------------------------

/**
 * parseOcpfDate parses OCPF "MM/DD/YYYY" date strings.
 * Returns null on parse failure.
 */
function parseOcpfDate(dateStr: string): Date | null {
  if (!dateStr) return null;
  const parts = dateStr.split('/');
  if (parts.length !== 3) return null;
  const month = parseInt(parts[0], 10);
  const day = parseInt(parts[1], 10);
  const year = parseInt(parts[2], 10);
  if (isNaN(month) || isNaN(day) || isNaN(year)) return null;
  const d = new Date(Date.UTC(year, month - 1, day));
  if (isNaN(d.getTime())) return null;
  return d;
}

/**
 * nextEvenYear rounds a year up to the next even year.
 * Used for election_cycle derivation when electionYear is absent.
 * e.g. 2025 → 2026, 2026 → 2026
 */
function nextEvenYear(year: number): number {
  return year % 2 !== 0 ? year + 1 : year;
}

function normalizeOcpfItem(
  item: OcpfItem,
  ps: PoliticianSource
): ContributionInsert | null {
  // --- Amount: strip leading "$", parse float ---
  const rawAmount = typeof item.amount === 'string'
    ? item.amount.replace(/^\$/, '')
    : String(item.amount ?? '');
  const amount = parseFloat(rawAmount);
  if (isNaN(amount)) {
    console.warn(`[ocpfAdapter] normalize: skip item id=${item.id} — cannot parse amount "${item.amount}"`);
    return null;
  }

  // --- Date: parse MM/DD/YYYY ---
  const contributionDate = parseOcpfDate(item.date);

  // --- Election cycle ---
  let electionCycle: string;
  if (item.electionYear && item.electionYear > 0) {
    electionCycle = String(item.electionYear);
  } else {
    // Derive from contribution date year, round up to next even year
    const baseYear = contributionDate
      ? contributionDate.getUTCFullYear()
      : new Date().getUTCFullYear();
    electionCycle = String(nextEvenYear(baseYear));
  }

  // --- Source transaction ID: ocpf|{id}, truncated to 128 chars ---
  let sourceTxId = `ocpf|${item.id}`;
  if (sourceTxId.length > 128) {
    sourceTxId = sourceTxId.slice(0, 128);
  }

  // --- Donor name ---
  const rawName = `${item.firstName ?? ''} ${item.lastName ?? ''}`.trim();
  const donorNameNormalized = normalizeDonorName(rawName);

  return {
    politician_source_id: ps.id,
    donor_id: null,
    committee_id: null,
    amount,
    contribution_date: contributionDate,
    election_cycle: electionCycle,
    confidence_level: 'HIGH', // OCPF is the authoritative MA state system
    data_source: 'ocpf',
    source_transaction_id: sourceTxId,
    raw_record: item as unknown as Record<string, unknown>,
    donor_name_normalized: donorNameNormalized,
  };
}

// ---------------------------------------------------------------------------
// Upsert — ON CONFLICT (data_source, source_transaction_id) DO UPDATE
// ---------------------------------------------------------------------------

async function upsertBatch(
  batch: ContributionInsert[]
): Promise<{ batchInserted: number; batchSkipped: number }> {
  if (batch.length === 0) return { batchInserted: 0, batchSkipped: 0 };

  // Deduplicate within batch by source_transaction_id
  const seen = new Set<string>();
  batch = batch.filter((c) => {
    if (seen.has(c.source_transaction_id)) return false;
    seen.add(c.source_transaction_id);
    return true;
  });

  const params: unknown[] = [];
  const valuePlaceholders: string[] = [];
  const COLS_PER_ROW = 9;

  for (let idx = 0; idx < batch.length; idx++) {
    const c = batch[idx];
    const base = idx * COLS_PER_ROW + 1;
    valuePlaceholders.push(
      `($${base}, $${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5}, $${base + 6}, $${base + 7}::jsonb, $${base + 8})`
    );
    params.push(
      c.politician_source_id,
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
      (politician_source_id, amount, contribution_date, election_cycle,
       confidence_level, data_source, source_transaction_id, raw_record,
       donor_name_normalized)
    VALUES ${valuePlaceholders.join(', ')}
    ON CONFLICT (data_source, source_transaction_id)
    DO UPDATE SET
      updated_at = NOW(),
      donor_name_normalized = EXCLUDED.donor_name_normalized
    RETURNING (xmax = 0) AS is_insert
  `;

  const result = await pool.query<{ is_insert: boolean }>(sql, params);

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

async function upsertContributions(normalized: NormalizeResult): Promise<UpsertResult> {
  if (normalized.contributions.length === 0) {
    return { inserted: 0, skipped: 0, unresolved: 0, errors: 0 };
  }

  let inserted = 0;
  let skipped = 0;
  let errors = 0;

  const batchSize = 100;
  for (let i = 0; i < normalized.contributions.length; i += batchSize) {
    const batch = normalized.contributions.slice(i, i + batchSize);
    try {
      const { batchInserted, batchSkipped } = await upsertBatch(batch);
      inserted += batchInserted;
      skipped += batchSkipped;
    } catch (err) {
      errors += batch.length;
      console.error(`[ocpfAdapter] upsert batch error at offset ${i}:`, err);
    }
  }

  return { inserted, skipped, unresolved: 0, errors };
}

// ---------------------------------------------------------------------------
// OcpfAdapter — implements SourceAdapter
// ---------------------------------------------------------------------------

class OcpfAdapter implements SourceAdapter {
  name(): string {
    return 'ocpf';
  }

  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    const cpfId = ps.external_id;
    const records = await fetchOcpfReceipts(cpfId);
    return {
      records,
      totalExpected: 0, // OCPF does not return a total count
      totalFetched: records.length,
    };
  }

  async normalize(raw: FetchResult, ps: PoliticianSource): Promise<NormalizeResult> {
    const contributions: ContributionInsert[] = [];
    let skipped = 0;
    const totalParsed = raw.records.length;

    for (const rec of raw.records) {
      const item = rec as unknown as OcpfItem;
      const contrib = normalizeOcpfItem(item, ps);
      if (contrib === null) {
        skipped++;
        continue;
      }
      contributions.push(contrib);
    }

    return { contributions, skipped, totalParsed };
  }

  async upsert(normalized: NormalizeResult): Promise<UpsertResult> {
    return upsertContributions(normalized);
  }
}

// ---------------------------------------------------------------------------
// Factory function
// ---------------------------------------------------------------------------

/**
 * createOcpfAdapter returns an OcpfAdapter implementing SourceAdapter.
 * The adapter fetches OCPF receipts from api.ocpf.us for the given cpfId
 * (stored as politician_sources.external_id).
 */
export function createOcpfAdapter(): SourceAdapter {
  return new OcpfAdapter();
}
