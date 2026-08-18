/**
 * ocpfAdapter — Massachusetts OCPF adapter implementing SourceAdapter.
 * Base URL: https://api.ocpf.us
 * Contributions endpoint: GET /search/items?SearchTypeId=1&SearchTypeCategory=receipts&CpfId={cpfId}&pageSize={n}
 * No auth required.
 *
 * 🔴 THIS ENDPOINT DOES NOT PAGINATE. `pageSize` is honoured; every offset parameter is
 * IGNORED. Verified live against api.ocpf.us on 2026-08-17 for cpfId 12008, window
 * 2005-Q2: pageNumber=1, 2, 3, 50, 298, 500 and 1000 each returned the SAME 250 records
 * (identical leading ids 518289, 518326), and `page`, `PageNumber`, `pageIndex`, `offset`,
 * `skip` and `start` all behaved the same way. Ask for pageSize=1000 and you get the
 * window's true total (289) in one response.
 *
 * So a full page is NOT evidence that another page exists. Issue ONE request with a
 * pageSize above the expected count and read the whole window at once.
 * Because the whole filer fits in one response, there is nothing to chunk. A filer's FULL
 * HISTORY is a single request: measured live 2026-08-17 across all 20 ocpf sources, the
 * largest (cpf 15710, 2001–present) is 89,557 records in ~5 s against a 180 s budget.
 *
 * 🔴 The year/quarter/month/week chunking this adapter used to carry was sized in PAGES of
 * the phantom loop ("~300 pages/month", "75k+ contributions per quarter"). Both numbers were
 * duplicates of the same 250 rows. cpf 15710's true worst QUARTER is 5,754 records, and its
 * true LIFETIME is 89,557 — so the chunking subdivided a 5-second call. It is gone; do not
 * reintroduce date windows without measuring the window first.
 *
 * Export: createOcpfAdapter(signal?: AbortSignal) — factory function.
 *   Pass a signal to cancel an in-flight fetch from an external AbortController.
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

// Single-request window size. Not a page size — this endpoint does not paginate (see the
// file header). It must exceed the largest window any filer can produce, because there is
// no total-count field to check against: `summary` is null on every response.
//
// Sizing evidence, measured live 2026-08-17 across ALL 20 ocpf politician_sources, each
// fetched as full history in one request: the largest filer is cpf 15710 at 89,557 records
// in 3,491 ms, next is 15931 at 32,941. pageSize=100000 returned 89,557 (not truncated), so
// the server imposes no ceiling below that. 250,000 leaves ~2.8x headroom over the current
// worst case while still being a real bound rather than "infinity".
const OCPF_MAX_WINDOW = parseInt(process.env.OCPF_MAX_WINDOW ?? '250000', 10);

// ---------------------------------------------------------------------------
// OCPF API response types
// ---------------------------------------------------------------------------

interface OcpfSearchResponse {
  items: OcpfItem[];
  // No total count, and `summary` is null on every response — so a full window is the
  // only truncation signal there is. See OCPF_MAX_WINDOW.
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
// Fetch — ONE request, full history; this endpoint does not paginate (see file header)
// ---------------------------------------------------------------------------

async function fetchOcpfReceipts(cpfId: string, externalSignal?: AbortSignal): Promise<Record<string, unknown>[]> {
  const allItems: Record<string, unknown>[] = [];

  // ONE request, no date filter — the filer's whole history. See the file header: this
  // endpoint ignores every offset parameter, so the previous `for(;;)` loop — which exited
  // only on `items.length < PAGE_SIZE` — could never terminate for a window holding >= 250
  // records. It re-appended the SAME 250 rows until the scheduler's 180s per-cycle
  // AbortSignal killed it at ~page 300, which is why every failure in prod carried
  // `page=296..300` regardless of filer or cycle.
  const url =
    `${OCPF_BASE}/search/items` +
    `?SearchTypeId=1&SearchTypeCategory=receipts` +
    `&CpfId=${encodeURIComponent(cpfId)}` +
    `&pageSize=${OCPF_MAX_WINDOW}`;

  let response: Response;
  try {
    const requestSignal = externalSignal
      ? AbortSignal.any([externalSignal, AbortSignal.timeout(30_000)])
      : AbortSignal.timeout(30_000);
    response = await fetch(url, { signal: requestSignal });
  } catch (err) {
    throw new Error(
      `[ocpfAdapter] fetch error cpfId=${cpfId}: ${err instanceof Error ? err.message : String(err)}`
    );
  }

  if (response.status !== 200) {
    throw new Error(
      `[ocpfAdapter] HTTP ${response.status} for cpfId=${cpfId}`
    );
  }

  const body = await response.json() as OcpfSearchResponse;
  const items = body.items ?? [];

  for (const item of items) {
    allItems.push(item as unknown as Record<string, unknown>);
  }

  // A response that exactly fills the requested window is the ONLY truncation signal
  // available — there is no total count (`summary` is null on every response). Failing
  // loudly beats silently undercounting a filer's receipts, which is the defect the old
  // loop was originally written to avoid.
  if (items.length >= OCPF_MAX_WINDOW) {
    throw new Error(
      `[ocpfAdapter] possible truncation for cpfId=${cpfId}: ` +
      `received ${items.length} records, which fills the requested window of ${OCPF_MAX_WINDOW}. ` +
      `Raise OCPF_MAX_WINDOW.`
    );
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

/**
 * parseOcpfAmount parses OCPF FORMATTED CURRENCY strings to a number.
 *
 * 🔴 OCPF does not send a bare numeric — it sends presentation text: "$50.00",
 * "$1,000.00", and negatives in ACCOUNTING PARENTHESES, "($1,000.00)". The previous
 * implementation was parseFloat(s.replace(/^\$/, "")), which broke on BOTH:
 *
 *   parseFloat("1,000.00")     === 1     <- SILENT; stops at the thousands separator
 *   parseFloat("($1,000.00)")  === NaN   <- loud; row dropped
 *
 * The comma case is the dangerous one: it returned a plausible small number rather than
 * an error, which capped the entire stored MA corpus at $999.00. 11,672 of 107,698 rows
 * understated by $15,643,496.52 in total, and the largest real contribution, $945,000,
 * was stored as $945. Existing rows were repaired by RE-INGESTING (no migration): the
 * upsert below now refreshes amount on conflict, so a re-read corrects every stored row
 * and rebuilds contribution_summary_agg through the same path.
 *
 * So parse STRICTLY and refuse anything unrecognised. Returning null costs one skipped
 * row plus a warning; guessing costs a wrong dollar figure that looks entirely real.
 */
export function parseOcpfAmount(raw: unknown): number | null {
  if (typeof raw === 'number') return Number.isFinite(raw) ? raw : null;
  if (typeof raw !== 'string') return null;

  let s = raw.trim();
  if (s === '') return null;

  // Accounting negative: "($1,000.00)" — the parentheses wrap the entire value.
  let negative = false;
  if (s.startsWith('(') && s.endsWith(')')) {
    negative = true;
    s = s.slice(1, -1).trim();
  }

  // A sign may also be written plainly, and may sit inside the parentheses.
  if (s.startsWith('-')) {
    negative = !negative;
    s = s.slice(1).trim();
  }

  s = s.replace(/^[$]/, '').replace(/,/g, '').trim();

  // Strict shape check. Stray text, a doubled sign or an empty remainder is REFUSED
  // rather than coerced. This is precisely the guard the old parseFloat lacked.
  if (!/^[0-9]+([.][0-9]+)?$/.test(s)) return null;

  const n = Number(s);
  if (!Number.isFinite(n)) return null;

  return negative ? -n : n;
}

function normalizeOcpfItem(
  item: OcpfItem,
  ps: PoliticianSource
): ContributionInsert | null {
  // --- Amount: OCPF sends formatted currency, not a number. See parseOcpfAmount. ---
  const amount = parseOcpfAmount(item.amount);
  if (amount === null) {
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
): Promise<{ batchInserted: number; batchUpdated: number; batchDropped: number }> {
  if (batch.length === 0) return { batchInserted: 0, batchUpdated: 0, batchDropped: 0 };

  // Deduplicate within batch by source_transaction_id. These rows reach the database
  // NOWHERE, so they are the only genuine "skipped" in this adapter — and they used to
  // vanish uncounted, which is why the taxonomy split below needed them surfaced.
  const seen = new Set<string>();
  const beforeDedup = batch.length;
  batch = batch.filter((c) => {
    if (seen.has(c.source_transaction_id)) return false;
    seen.add(c.source_transaction_id);
    return true;
  });
  const batchDropped = beforeDedup - batch.length;

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
      updated_at            = NOW(),
      donor_name_normalized = EXCLUDED.donor_name_normalized,
      -- 🔴 These four MUST be refreshed, and were not until 2026-08-18. They are derived
      -- from the source record, so leaving them out made re-ingestion incapable of ever
      -- REPAIRING anything: the $15.64M comma-truncation defect would have survived every
      -- future run of a corrected adapter, because the conflicting row was left untouched.
      -- A re-read is only meaningfully idempotent if it also corrects. (Fetch is
      -- all-or-nothing and throws on truncation, so a partial response cannot blank a row.)
      amount                = EXCLUDED.amount,
      contribution_date     = EXCLUDED.contribution_date,
      election_cycle        = EXCLUDED.election_cycle,
      raw_record            = EXCLUDED.raw_record
    RETURNING (xmax = 0) AS is_insert
  `;

  const result = await pool.query<{ is_insert: boolean }>(sql, params);

  let batchInserted = 0;
  let batchUpdated = 0;
  for (const row of result.rows) {
    if (row.is_insert) {
      batchInserted++;
    } else {
      // xmax != 0 means the DO UPDATE fired. Since 2026-08-18 that clause refreshes
      // amount / contribution_date / election_cycle / raw_record, so this is a REPAIR.
      batchUpdated++;
    }
  }

  return { batchInserted, batchUpdated, batchDropped };
}

async function upsertContributions(normalized: NormalizeResult): Promise<UpsertResult> {
  if (normalized.contributions.length === 0) {
    return { inserted: 0, updated: 0, skipped: 0, unresolved: 0, errors: 0 };
  }

  let inserted = 0;
  let updated = 0;
  let skipped = 0;
  let errors = 0;

  const batchSize = 100;
  for (let i = 0; i < normalized.contributions.length; i += batchSize) {
    const batch = normalized.contributions.slice(i, i + batchSize);
    try {
      const { batchInserted, batchUpdated, batchDropped } = await upsertBatch(batch);
      inserted += batchInserted;
      updated += batchUpdated;
      skipped += batchDropped;
    } catch (err) {
      errors += batch.length;
      console.error(`[ocpfAdapter] upsert batch error at offset ${i}:`, err);
    }
  }

  return { inserted, updated, skipped, unresolved: 0, errors };
}

// ---------------------------------------------------------------------------
// OcpfAdapter — implements SourceAdapter
// ---------------------------------------------------------------------------

class OcpfAdapter implements SourceAdapter {
  private readonly externalSignal?: AbortSignal;

  constructor(externalSignal?: AbortSignal) {
    this.externalSignal = externalSignal;
  }

  name(): string {
    return 'ocpf';
  }

  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    const cpfId = ps.external_id;
    const records = await fetchOcpfReceipts(cpfId, this.externalSignal);
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
 * The adapter fetches a filer's ENTIRE receipt history from api.ocpf.us in ONE request,
 * keyed on cpfId (stored as politician_sources.external_id).
 *
 * There is deliberately no year/quarter/month parameter. See the file header: the endpoint
 * does not paginate, and the largest filer's full history is ~5 s. Date windows only ever
 * existed to subdivide the phantom page loop.
 *
 * @param signal - Optional external AbortSignal, combined with the 30-second request timeout
 *   via AbortSignal.any — whichever fires first cancels the in-flight fetch.
 */
export function createOcpfAdapter(signal?: AbortSignal): SourceAdapter {
  return new OcpfAdapter(signal);
}
