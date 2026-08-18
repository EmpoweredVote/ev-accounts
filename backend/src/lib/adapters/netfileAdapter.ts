/**
 * netfileAdapter — LA County Netfile REST API adapter implementing SourceAdapter.
 *
 * LA County Netfile migrated from the ASP.NET WebForms bulk export site
 * (public.netfile.com/pub2) to a new SPA + REST API (netfile.com) in early 2026.
 * The old WebForms POST/Excel approach is broken; the new REST API is unauthenticated
 * and CORS-open.
 *
 * DISCOVERY NOTES (2026-05-20, quick-026):
 *   - Base: https://netfile.com/api/public/sites/api
 *   - filings/byFiler?agencyCode=LACO&filerId=<id> — returns filing list with filerName(s)
 *   - SearchCampaignTransactions?aid=LACO&query=<text>&pageSize=50&currentPage=N
 *       The `query` param searches BOTH the contributor `name` field AND `filerName`.
 *       No per-filing transaction endpoint exists; no filerId filter on transactions.
 *   - Adapter strategy:
 *       1. GET filings for the committee via filings/byFiler to learn filerName(s)
 *       2. For each filerName, paginate SearchCampaignTransactions with query=<filerName>
 *       3. Filter client-side to rows where filerName exactly matches our committee
 *       4. Normalize: keep only schedule='460A' (monetary contributions received)
 *   - REST API coverage: recent filings only (approx 2025+). Historical data (pre-2025)
 *     was in the old bulk Excel export and is NOT accessible via the new REST API.
 *     Zero 460A rows is therefore expected for most committees in current year.
 *
 * Export: createNetfileAdapter(year) — factory function.
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

const NETFILE_API_BASE = 'https://netfile.com/api/public/sites/api';
const NETFILE_AGENCY = 'LACO';

/** Maximum rows per SearchCampaignTransactions page. */
const TRANSACTIONS_PAGE_SIZE = 50;

/** Request headers sent with every API call. */
const REQUEST_HEADERS = {
  Accept: 'application/json',
  'User-Agent': 'EV-CampaignFinance/1.0 (+https://empowered.vote)',
};

// ---------------------------------------------------------------------------
// Netfile REST API types
// ---------------------------------------------------------------------------

interface NetfileFiling {
  id: string;
  formId: string;
  formGroupId: string;
  formName: string;
  filerName: string;
  filingDate: string;
  sequenceNumber: string;
  reportNumber: string;
  periodStart: string | null;
  periodEnd: string | null;
  imageExternalReference: string;
  obfuscatedId: string;
  hasAttachment: boolean;
}

interface NetfileFilingsResponse {
  filings: NetfileFiling[];
  totalCount: number;
}

interface NetfileTransaction {
  id: string;
  filingId: string;
  filerName: string;
  date: string;
  amount: number;
  transactionType: string;
  schedule: string;
  name: string;
  vendor: string | null;
  address: string;
  spendingCode: string;
  employer: string;
  occupation: string;
}

interface NetfileTransactionsResponse {
  aid: string;
  items: NetfileTransaction[];
  pageSize: number;
  currentPage: number;
  pageCount: number;
  totalCount: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

// ---------------------------------------------------------------------------
// API client helpers
// ---------------------------------------------------------------------------

/**
 * getFilingsForFiler fetches the list of filings for a given filer (committee) ID.
 * Returns the array of filings. On non-2xx, logs a warning and returns [].
 */
async function getFilingsForFiler(filerId: string): Promise<NetfileFiling[]> {
  const url =
    `${NETFILE_API_BASE}/filings/byFiler?agencyCode=${NETFILE_AGENCY}` +
    `&filerId=${encodeURIComponent(filerId)}&isArchived=true`;

  console.log(`[netfileAdapter] GET ${url}`);

  let resp: Response;
  try {
    resp = await fetch(url, { headers: REQUEST_HEADERS });
  } catch (err) {
    console.warn(
      `[netfileAdapter] filings/byFiler network error (filerId=${filerId}): ` +
        (err instanceof Error ? err.message : String(err))
    );
    return [];
  }

  if (!resp.ok) {
    console.warn(
      `[netfileAdapter] filings/byFiler HTTP ${resp.status} (filerId=${filerId}) — skipping`
    );
    return [];
  }

  const data = (await resp.json()) as NetfileFilingsResponse;
  return data.filings ?? [];
}

/**
 * getTransactionsByFilerName paginates SearchCampaignTransactions for a given
 * filerName query, returning ALL transactions across all pages where the
 * filerName field EXACTLY matches the given name.
 *
 * NOTE: The `query` param searches both the contributor `name` field and `filerName`.
 * We filter client-side to filerName === targetFilerName to avoid false positives
 * (e.g. another committee received a contribution FROM this committee).
 */
async function getTransactionsByFilerName(
  targetFilerName: string
): Promise<NetfileTransaction[]> {
  const allMatching: NetfileTransaction[] = [];
  let currentPage = 1;

  for (;;) {
    const params = new URLSearchParams({
      aid: NETFILE_AGENCY,
      query: targetFilerName,
      pageSize: String(TRANSACTIONS_PAGE_SIZE),
      currentPage: String(currentPage),
    });

    const url = `${NETFILE_API_BASE}/SearchCampaignTransactions?${params.toString()}`;

    if (currentPage === 1) {
      console.log(
        `[netfileAdapter] GET SearchCampaignTransactions filerName="${targetFilerName}"`
      );
    }

    let resp: Response;
    try {
      resp = await fetch(url, { headers: REQUEST_HEADERS });
    } catch (err) {
      console.warn(
        `[netfileAdapter] SearchCampaignTransactions network error (filerName=${targetFilerName} page=${currentPage}): ` +
          (err instanceof Error ? err.message : String(err))
      );
      break;
    }

    if (!resp.ok) {
      console.warn(
        `[netfileAdapter] SearchCampaignTransactions HTTP ${resp.status} ` +
          `(filerName=${targetFilerName} page=${currentPage}) — stopping pagination`
      );
      break;
    }

    const data = (await resp.json()) as NetfileTransactionsResponse;
    const items = data.items ?? [];

    // Filter client-side: only keep rows where filerName EXACTLY matches.
    // The API `query` param also matches contributor name field, so without
    // this filter we would include unrelated committees' transactions.
    // Normalize the comparison: strip leading asterisk (* = active committee marker).
    const stripped = stripLeadingAsterisk(targetFilerName);
    const matching = items.filter(
      (item) => stripLeadingAsterisk(item.filerName) === stripped
    );
    allMatching.push(...matching);

    if (!data.hasNextPage || items.length === 0) {
      break;
    }

    currentPage++;
  }

  return allMatching;
}

/**
 * stripLeadingAsterisk removes the leading '*' that Netfile prefixes on active
 * (non-archived) filer names in the REST API responses.
 * e.g. "*Lindsey Horvath for Supervisor 2026" → "Lindsey Horvath for Supervisor 2026"
 */
function stripLeadingAsterisk(name: string): string {
  return name.startsWith('*') ? name.slice(1) : name;
}

// ---------------------------------------------------------------------------
// Normalizer — REST API transaction → ContributionInsert
// ---------------------------------------------------------------------------

interface NormalizeInput {
  records: Record<string, unknown>[];
  year: number;
  ps: PoliticianSource;
}

function normalizeTransactions({
  records,
  year,
  ps,
}: NormalizeInput): { contributions: ContributionInsert[]; skipped: number } {
  const contributions: ContributionInsert[] = [];
  let skipped = 0;

  for (let idx = 0; idx < records.length; idx++) {
    const tx = records[idx] as unknown as NetfileTransaction;

    // Only Schedule A (monetary contributions received).
    // The schedule field is '460A' for F460A transactions.
    if (tx.schedule !== '460A') {
      skipped++;
      continue;
    }

    // Amount must be a positive number.
    const amount = Number(tx.amount);
    if (!isFinite(amount) || amount <= 0) {
      console.warn(
        `[netfileAdapter] skip tx id=${tx.id} — amount invalid (${tx.amount})`
      );
      skipped++;
      continue;
    }

    // Contribution date.
    let contributionDate: Date | null = null;
    if (tx.date) {
      const d = new Date(tx.date);
      if (!isNaN(d.getTime())) {
        contributionDate = d;
      }
    }
    if (contributionDate === null) {
      console.warn(
        `[netfileAdapter] skip tx id=${tx.id} — date unparseable (${tx.date})`
      );
      skipped++;
      continue;
    }

    // election_cycle: round UP to next even year (same formula as other CA adapters).
    let cycleYear = contributionDate.getFullYear();
    if (cycleYear % 2 !== 0) cycleYear += 1;
    const electionCycle = String(cycleYear);

    // Donor name: the 'name' field in Schedule A is the contributor.
    const donorName = tx.name ?? '';

    // source_transaction_id: filingId + transaction id (stable across re-runs).
    const sourceTransactionId = `${tx.filingId}-${tx.id}`;

    // Enrich raw record with standard aliases for campaignFinanceService.
    const rawRecord: Record<string, unknown> = {
      ...(tx as unknown as Record<string, unknown>),
      contributor_name: donorName,
      contributor_employer: tx.employer ?? '',
      contributor_occupation: tx.occupation ?? '',
      contributor_address: tx.address ?? '',
    };

    contributions.push({
      politician_source_id: ps.id,
      donor_id: null,
      committee_id: null,
      amount,
      contribution_date: contributionDate,
      election_cycle: electionCycle,
      confidence_level: 'HIGH',
      data_source: 'la_county_netfile',
      source_transaction_id: sourceTransactionId,
      raw_record: rawRecord,
      donor_name_normalized: normalizeDonorName(donorName || null),
    });
  }

  return { contributions, skipped };
}

// ---------------------------------------------------------------------------
// Upsert — batch insert with ON CONFLICT dedup
// ---------------------------------------------------------------------------

async function upsertContributions(contributions: ContributionInsert[]): Promise<UpsertResult> {
  if (contributions.length === 0) {
    return { inserted: 0, updated: 0, skipped: 0, unresolved: 0, errors: 0 };
  }

  // Deduplicate by source_transaction_id before batching.
  const seen = new Map<string, ContributionInsert>();
  for (const c of contributions) {
    seen.set(c.source_transaction_id, c);
  }
  const deduped = Array.from(seen.values());
  // Collapsed duplicates reach the database nowhere — the only genuine "skipped" here.
  // Previously uncounted.
  const totalDropped = contributions.length - deduped.length;

  let totalInserted = 0;
  let totalUpdated = 0;
  let totalErrors = 0;

  const BATCH_SIZE = 100;

  for (let i = 0; i < deduped.length; i += BATCH_SIZE) {
    const batch = deduped.slice(i, i + BATCH_SIZE);

    try {
      const valuePlaceholders = batch.map((_, rowIdx) => {
        const base = rowIdx * 11;
        return (
          `($${base + 1},$${base + 2},$${base + 3},$${base + 4},$${base + 5},` +
          `$${base + 6},$${base + 7},$${base + 8},$${base + 9},$${base + 10},$${base + 11})`
        );
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
        VALUES ${valuePlaceholders.join(',')}
        ON CONFLICT (data_source, source_transaction_id)
          DO UPDATE SET
            amount                = EXCLUDED.amount,
            contribution_date     = EXCLUDED.contribution_date,
            raw_record            = EXCLUDED.raw_record,
            donor_name_normalized = EXCLUDED.donor_name_normalized,
            updated_at            = NOW()
        RETURNING (xmax = 0) AS inserted`;

      const result = await pool.query<{ inserted: boolean }>(sql, params);

      for (const row of result.rows) {
        if (row.inserted) totalInserted++;
        else totalUpdated++; // DO UPDATE refreshes amount/date/raw_record — a REFRESH
      }
    } catch (err) {
      console.error(
        `[netfileAdapter] upsert batch error (i=${i}): ` +
          (err instanceof Error ? err.message : String(err))
      );
      totalErrors++;
    }
  }

  return { inserted: totalInserted, updated: totalUpdated, skipped: totalDropped, unresolved: 0, errors: totalErrors };
}

// ---------------------------------------------------------------------------
// NetfileAdapter class — implements SourceAdapter
// ---------------------------------------------------------------------------

class NetfileAdapter implements SourceAdapter {
  private readonly year: number;

  constructor(year: number) {
    this.year = year;
  }

  name(): string {
    return 'la_county_netfile';
  }

  /**
   * fetch retrieves all transactions for the given committee (politician_source).
   *
   * Strategy:
   *   1. Call filings/byFiler to get the committee's filerName(s).
   *   2. For each unique filerName, paginate SearchCampaignTransactions.
   *   3. Filter client-side to rows where filerName exactly matches our committee.
   *   4. Return all transaction records (normalize() will filter to 460A).
   *
   * NOTE: The REST API only covers recent data (approx 2025+). Historical
   * contributions (pre-2025) were only in the old bulk Excel export which
   * no longer exists. Returning 0 records is a valid outcome.
   */
  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    const filerId = ps.external_id;

    if (!filerId || filerId.trim() === '') {
      console.warn(`[netfileAdapter] ps.id=${ps.id} has empty external_id — skipping`);
      return { records: [], totalExpected: 0, totalFetched: 0 };
    }

    // Step 1: Get filings to learn the filerName(s) for this committee.
    const filings = await getFilingsForFiler(filerId);

    if (filings.length === 0) {
      console.log(
        `[netfileAdapter] fetch: filerId=${filerId} year=${this.year} — no filings found`
      );
      return { records: [], totalExpected: 0, totalFetched: 0 };
    }

    // Collect unique filerNames (a committee may have name variations across filings).
    const filerNames = [...new Set(filings.map((f) => f.filerName))];
    console.log(
      `[netfileAdapter] fetch: filerId=${filerId} year=${this.year} ` +
        `filings=${filings.length} filerNames=${JSON.stringify(filerNames)}`
    );

    // Step 2 & 3: For each filerName, fetch matching transactions and filter.
    const allTransactions: NetfileTransaction[] = [];
    const seenIds = new Set<string>();

    for (const filerName of filerNames) {
      const txs = await getTransactionsByFilerName(filerName);

      for (const tx of txs) {
        if (!seenIds.has(tx.id)) {
          seenIds.add(tx.id);
          allTransactions.push(tx);
        }
      }
    }

    console.log(
      `[netfileAdapter] fetch: filerId=${filerId} year=${this.year} ` +
        `total_transactions=${allTransactions.length}`
    );

    return {
      records: allTransactions as unknown as Record<string, unknown>[],
      totalExpected: allTransactions.length,
      totalFetched: allTransactions.length,
    };
  }

  async normalize(raw: FetchResult, ps: PoliticianSource): Promise<NormalizeResult> {
    const { contributions, skipped } = normalizeTransactions({
      records: raw.records,
      year: this.year,
      ps,
    });

    console.log(
      `[netfileAdapter] normalize: ps.id=${ps.id} ` +
        `total_records=${raw.records.length} contributions=${contributions.length} skipped=${skipped}`
    );

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
 * createNetfileAdapter returns a new NetfileAdapter for the given year.
 * The adapter fetches LA County Netfile contributions via the REST API
 * at https://netfile.com/api/public/sites/api.
 *
 * @param year - Calendar year context (used for election_cycle computation).
 *               Does not filter API results — the REST API covers all available data.
 */
export function createNetfileAdapter(year: number): SourceAdapter {
  return new NetfileAdapter(year);
}
