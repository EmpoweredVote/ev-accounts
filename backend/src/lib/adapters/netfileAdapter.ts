/**
 * netfileAdapter — LA County Netfile REST API adapter implementing SourceAdapter.
 *
 * LA County Netfile migrated from the ASP.NET WebForms bulk export site
 * (public.netfile.com/pub2) to a new SPA + REST API (netfile.com) in early 2026.
 * The old WebForms POST/Excel approach is broken; the new REST API is unauthenticated
 * and CORS-open. Its bulk exports (`CampaignExport/*`, `.../export`) demand a Cloudflare
 * Turnstile token, so a job may only use the JSON read endpoints below.
 *
 * ENDPOINTS (base https://netfile.com/api/public/sites/api, re-measured 2026-09-24):
 *   - IdSearch?aid=LACO&sosId=<FPPC id> — maps the state (FPPC) committee id we store in
 *       politician_sources.external_id to NetFile's OWN filer id.
 *   - filings/byFiler?agencyCode=LACO&filerId=<NetFile id> — the committee's filings. 🔴 Handed
 *       an FPPC id it answers `{"filings":[],"totalCount":0}` with HTTP 200. That is how every
 *       run from 2026-05-21 to 2026-09-01 "completed" with 0 rows: 172 of the 184 links store
 *       an FPPC id that IdSearch maps. Ten store a 9-digit NetFile id, which IdSearch does not
 *       know; seven of those are LACO filers, three are City of West Hollywood (agency WEHO)
 *       filers that this adapter cannot read.
 *   - SearchCampaignTransactions?aid=LACO&query=<words>&pageSize=N&currentPage=N — a WORD
 *       search over both the contributor `name` and `filerName`. There is no filer or filing
 *       filter. 🔴 A ':' in the query answers HTTP 500 and a ',' matches nothing, so the
 *       committee name is reduced to its letters and digits first. pageSize up to 10,000 is
 *       honoured; the page order is NOT stable between calls, so a multi-page walk can drop
 *       or repeat a row, and the walk is checked against totalCount.
 *
 * Adapter strategy:
 *   1. IdSearch the stored id; if it knows no committee, read the id as a NetFile id.
 *   2. filings/byFiler for each NetFile id.
 *   3. Search each committee name; keep only rows whose filingId is one of the committee's
 *      filings. That is exact, where a name match is not: the query also finds rows on which
 *      this committee is the DONOR to someone else.
 *   4. Keep only the rows of each report's current version (see currentFilings: amendments,
 *      empty imported copies, consolidated reports).
 *   5. Normalize Schedule A ('460A', monetary contributions received) only.
 *
 * Coverage: the REST API holds each committee's whole filed history — the oldest row read on
 * 2026-09-24 is 2014-01-03, from Jeff Prang's imported 2014 committee. The
 * 5,386 rows loaded 2026-04-16 came from the old Excel export, keyed `Filer_ID|Tran_ID`;
 * Tran_ID is the filer software's number and repeats across reports, so that key merged
 * distinct gifts (Micah Ali: 59 stored, 84 filed). The prune in upsert() replaces them.
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

/**
 * Rows per SearchCampaignTransactions page. The largest committee measured on 2026-09-24
 * (Horvath, 4,136 rows) fits one page, and one page cannot suffer the unstable page order.
 */
const TRANSACTIONS_PAGE_SIZE = 10_000;

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

interface NetfileIdSearchResponse {
  committees?: { id: string; name: string }[];
}

// ---------------------------------------------------------------------------
// API client helpers
// ---------------------------------------------------------------------------

/**
 * getJson GETs one NetFile endpoint and parses the body.
 *
 * 🔴 Throws on a network error or any non-2xx status. The previous client turned both into
 * an empty list, so a 500 (every committee name holding a ':') and a 429 were recorded as
 * a 'completed' run with 0 rows — the same shape as a committee with nothing to report.
 * A throw makes runIngestion record the run as 'failed' instead.
 */
async function getJson<T>(path: string, params: Record<string, string>): Promise<T> {
  const url = `${NETFILE_API_BASE}/${path}?${new URLSearchParams(params).toString()}`;
  let resp: Response;
  try {
    resp = await fetch(url, { headers: REQUEST_HEADERS });
  } catch (err) {
    throw new Error(`NetFile ${path} network error: ${err instanceof Error ? err.message : String(err)}`, {
      cause: err,
    });
  }
  if (!resp.ok) {
    throw new Error(`NetFile ${path} HTTP ${resp.status} (${url})`);
  }
  return (await resp.json()) as T;
}

/**
 * resolveFilerIds maps a stored external_id to the NetFile filer id(s) that
 * filings/byFiler accepts.
 *
 * Returns the committees IdSearch finds for it as an FPPC id; if it finds none, the stored
 * id itself, which may already be a NetFile id (e.g. Horvath 216785710).
 * Whether that guess holds is decided by filings/byFiler: an id it does not know answers
 * an empty list.
 */
async function resolveFilerIds(externalId: string): Promise<string[]> {
  const data = await getJson<NetfileIdSearchResponse>('IdSearch', {
    aid: NETFILE_AGENCY,
    sosId: externalId,
  });
  const ids = (data.committees ?? []).map((c) => c.id);
  return ids.length > 0 ? ids : [externalId];
}

async function getFilingsForFiler(filerId: string): Promise<NetfileFiling[]> {
  const data = await getJson<NetfileFilingsResponse>('filings/byFiler', {
    agencyCode: NETFILE_AGENCY,
    filerId,
    isArchived: 'false',
  });
  return data.filings ?? [];
}

/**
 * currentFilings picks the Form 460s whose rows count, from the committee's filings and the
 * set of filing ids that carry at least one row (any schedule) in the search.
 *
 * Newest first (filing date, then sequence number), a Form 460:
 *   - with no row at all is passed over. It cannot be the current version: measured
 *     2026-09-24, Horvath's committee (216785710) holds a second, imported copy of each
 *     report, and for 2025-01-01..06-30 the copy filed LATER holds 0 rows where the other
 *     holds 289. "Latest filing wins" kept the empty one.
 *   - whose period lies inside the period of a newer Form 460 already kept is superseded.
 *     That covers an amendment (same period: an amended 460 re-reports the whole report
 *     under a new filing id, and the search returns both versions' rows) and a consolidated
 *     report (Horvath's full-year 2023 report repeats the 160 rows of its 2023-01-01..06-30
 *     report).
 *   - otherwise is kept. Periods that only partly overlap are both kept: neither contains
 *     the other's report, and dropping one would lose real gifts.
 * Filings that are not Form 460s (497 late reports, 410s, 501s) pass through; normalize()
 * keeps Schedule A only, so their rows never count.
 */
function currentFilings(filings: NetfileFiling[], withRows: ReadonlySet<string>): NetfileFiling[] {
  const rest: NetfileFiling[] = [];
  const reports: NetfileFiling[] = [];
  for (const f of filings) {
    const form = f.formName.replace(/\s*\(Amendment\)\s*$/i, '');
    if (form === 'FPPC 460' && f.periodStart && f.periodEnd) reports.push(f);
    else rest.push(f);
  }
  reports.sort((a, b) => (isLater(a, b) ? -1 : isLater(b, a) ? 1 : 0));

  const kept: NetfileFiling[] = [];
  for (const f of reports) {
    if (!withRows.has(f.id)) continue;
    const start = day(f.periodStart!);
    const end = day(f.periodEnd!);
    const inside = kept.some((k) => day(k.periodStart!) <= start && end <= day(k.periodEnd!));
    if (!inside) kept.push(f);
  }
  return [...rest, ...kept];
}

function isLater(a: NetfileFiling, b: NetfileFiling): boolean {
  if (a.filingDate !== b.filingDate) return a.filingDate > b.filingDate;
  return Number(a.sequenceNumber || 0) > Number(b.sequenceNumber || 0);
}

/** The calendar day of an API timestamp ("2026-04-18T00:00:00+00:00" → "2026-04-18"). */
function day(timestamp: string): string {
  return timestamp.slice(0, 10);
}

/**
 * searchQuery reduces a committee name to the words the search can take. A ':' answers
 * HTTP 500 and a ',' matches nothing (measured 2026-09-24: "Tina Fredericks for PUSD Board
 * Member, 2024" → 0 rows; without the comma → 261). Rows are matched by filingId afterwards,
 * so a looser query can never admit another committee's rows.
 */
function searchQuery(filerName: string): string {
  return filerName.replace(/[^0-9A-Za-z]+/g, ' ').trim();
}

/**
 * searchTransactions walks every page of SearchCampaignTransactions for one query and
 * returns the rows reported on one of `filingIds`.
 *
 * The page order is not stable between calls, so a multi-page walk can drop a row that
 * moved to a page already read. The walk therefore counts the distinct rows it saw and
 * fails if that is short of totalCount (Horvath at pageSize 1,000: 4,135 of 4,136).
 */
async function searchTransactions(
  query: string,
  filingIds: ReadonlySet<string>
): Promise<NetfileTransaction[]> {
  const seen = new Set<string>();
  const matching: NetfileTransaction[] = [];
  let totalCount: number;

  for (let currentPage = 1; ; currentPage++) {
    const data = await getJson<NetfileTransactionsResponse>('SearchCampaignTransactions', {
      aid: NETFILE_AGENCY,
      query,
      pageSize: String(TRANSACTIONS_PAGE_SIZE),
      currentPage: String(currentPage),
      isArchived: 'false',
    });
    totalCount = data.totalCount ?? 0;
    const items = data.items ?? [];
    for (const item of items) {
      if (seen.has(item.id)) continue;
      seen.add(item.id);
      if (filingIds.has(item.filingId)) matching.push(item);
    }
    if (!data.hasNextPage || items.length === 0) break;
  }

  if (seen.size < totalCount) {
    throw new Error(
      `NetFile search "${query}": ${totalCount} counted, ${seen.size} read — the page walk lost rows`
    );
  }
  return matching;
}

// ---------------------------------------------------------------------------
// Normalizer — REST API transaction → ContributionInsert
// ---------------------------------------------------------------------------

interface NormalizeInput {
  records: Record<string, unknown>[];
  ps: PoliticianSource;
}

function normalizeTransactions({
  records,
  ps,
}: NormalizeInput): { contributions: ContributionInsert[]; skipped: number; excluded: number } {
  const contributions: ContributionInsert[] = [];
  let skipped = 0;
  let excluded = 0;

  for (let idx = 0; idx < records.length; idx++) {
    const tx = records[idx] as unknown as NetfileTransaction;

    // Only Schedule A (monetary contributions received); the schedule field is '460A'.
    // Every other schedule is a deliberate omission, never a defect: expenditures (460E),
    // and the 497 late reports, whose gifts the next 460 re-reports on Schedule A.
    if (tx.schedule !== '460A') {
      excluded++;
      continue;
    }

    // Any finite amount. A negative Schedule A line is a real adjustment, and the Cal-Access
    // and OCPF adapters keep it too (11 of the rows the Excel export loaded were negative).
    const amount = Number(tx.amount);
    if (!isFinite(amount)) {
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
    let cycleYear = contributionDate.getUTCFullYear();
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

  return { contributions, skipped, excluded };
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

  // Prune only after a clean write: a failed batch means the keep-set is not all in the table.
  if (totalErrors === 0) {
    await pruneSuperseded(deduped);
  }

  return { inserted: totalInserted, updated: totalUpdated, skipped: totalDropped, unresolved: 0, errors: totalErrors };
}

/**
 * pruneSuperseded deletes this source's la_county_netfile rows that its current filings no
 * longer carry. Two kinds go:
 *   - rows of a Form 460 that an amendment has since replaced, each under a new filingId;
 *   - the rows the old Excel export loaded on 2026-04-16, keyed `Filer_ID|Tran_ID`, which
 *     no REST key can ever match. Measured 2026-09-24: 5,383 of those 5,386 rows have a
 *     REST row with the same date and amount; the other 3 sit in amended reports.
 *
 * Never called with an empty keep-set (upsertContributions returns early), so a source the
 * API stops showing (McKenzie 1450349, Stern 1472646: IdSearch knows neither) keeps its rows.
 *
 * Same query shape as calAccessAdapter's prune: the source's rows through a MATERIALIZED CTE
 * on politician_source_id alone, so the planner cannot pick the (data_source,
 * source_transaction_id) index and read every row of the source system.
 */
async function pruneSuperseded(contributions: ContributionInsert[]): Promise<void> {
  const sourceID = contributions[0].politician_source_id;
  const keep = contributions.map((c) => c.source_transaction_id);
  const res = await pool.query(
    `WITH mine AS MATERIALIZED (
       SELECT id, data_source, source_transaction_id
         FROM transparent_motivations.contributions
        WHERE politician_source_id = $1
     )
     DELETE FROM transparent_motivations.contributions c
      USING mine m
      WHERE c.id = m.id
        AND m.data_source = 'la_county_netfile'
        AND NOT EXISTS (SELECT 1 FROM unnest($2::text[]) AS k(id) WHERE k.id = m.source_transaction_id)`,
    [sourceID, keep]
  );
  if (res.rowCount) {
    console.log(`[netfileAdapter] source=${sourceID}: pruned ${res.rowCount} superseded row(s)`);
  }
}

// ---------------------------------------------------------------------------
// NetfileAdapter class — implements SourceAdapter
// ---------------------------------------------------------------------------

class NetfileAdapter implements SourceAdapter {
  private readonly year: number;
  private fetched = 0;

  constructor(year: number) {
    this.year = year;
  }

  name(): string {
    return 'la_county_netfile';
  }

  /** fetchedRowCount returns how many of its own committees' rows this adapter has read. */
  fetchedRowCount(): number {
    return this.fetched;
  }

  /**
   * fetch reads every transaction reported on the committee's current filings.
   * normalize() then keeps Schedule A. See the header for the endpoints and their traps.
   */
  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    const externalId = ps.external_id?.trim() ?? '';

    if (externalId === '') {
      console.warn(`[netfileAdapter] ps.id=${ps.id} has empty external_id — skipping`);
      return { records: [], totalExpected: 0, totalFetched: 0 };
    }

    // Steps 1-2: the NetFile filer id(s), then their filings.
    const filerIds = await resolveFilerIds(externalId);
    const filings: NetfileFiling[] = [];
    for (const filerId of filerIds) {
      filings.push(...(await getFilingsForFiler(filerId)));
    }

    if (filings.length === 0) {
      console.log(`[netfileAdapter] fetch: id=${externalId} — NetFile LACO knows no committee or filing for it`);
      return { records: [], totalExpected: 0, totalFetched: 0 };
    }

    // Step 3: every row on the committee's own filings, whichever name found it.
    const ownFilingIds = new Set(filings.map((f) => f.id));
    const queries = [...new Set(filings.map((f) => searchQuery(f.filerName)))].filter((q) => q !== '');
    const byId = new Map<string, NetfileTransaction>();
    for (const query of queries) {
      for (const tx of await searchTransactions(query, ownFilingIds)) {
        byId.set(tx.id, tx);
      }
    }

    // Step 4: only the rows of the current version of each report.
    const withRows = new Set([...byId.values()].map((tx) => tx.filingId));
    const current = new Set(currentFilings(filings, withRows).map((f) => f.id));
    const records = [...byId.values()].filter((tx) => current.has(tx.filingId));
    this.fetched += records.length;
    console.log(
      `[netfileAdapter] fetch: id=${externalId} year=${this.year} filerIds=${JSON.stringify(filerIds)} ` +
        `filings=${filings.length} current=${current.size} queries=${JSON.stringify(queries)} ` +
        `rows=${byId.size} superseded=${byId.size - records.length}`
    );

    return {
      records: records as unknown as Record<string, unknown>[],
      totalExpected: records.length,
      totalFetched: records.length,
    };
  }

  async normalize(raw: FetchResult, ps: PoliticianSource): Promise<NormalizeResult> {
    const { contributions, skipped, excluded } = normalizeTransactions({
      records: raw.records,
      ps,
    });

    console.log(
      `[netfileAdapter] normalize: ps.id=${ps.id} total_records=${raw.records.length} ` +
        `contributions=${contributions.length} excluded=${excluded} skipped=${skipped}`
    );

    return {
      contributions,
      skipped,
      excluded,
      totalParsed: raw.records.length,
    };
  }

  async upsert(normalized: NormalizeResult): Promise<UpsertResult> {
    return upsertContributions(normalized.contributions);
  }
}

// ---------------------------------------------------------------------------
// Run health — called by the scheduler after the last source
// ---------------------------------------------------------------------------

/**
 * assertNetfileRunHealthy throws when a whole run should alert rather than exit 0.
 *
 * runAdapterForAll logs a source's error and moves on, and the job then exits 0, so neither
 * a failed source nor a run that read nothing ever reached Render's failure notification.
 * Five monthly runs (2026-05-21 to 2026-09-01, 180-183 sources each) read 0 rows in total,
 * and each looked like a quiet month. A run that reads 0 rows from every source is never a
 * quiet month: 154 of the 184 links carry Schedule A rows.
 */
export function assertNetfileRunHealthy(run: { sources: number; failed: number; fetched: number }): void {
  if (run.failed > 0) {
    throw new Error(`la_county_netfile: ${run.failed} of ${run.sources} source(s) failed — see ingestion_runs`);
  }
  if (run.sources > 0 && run.fetched === 0) {
    throw new Error(
      `la_county_netfile: read 0 rows from all ${run.sources} sources — the NetFile API or the adapter has changed`
    );
  }
}

// ---------------------------------------------------------------------------
// Factory export
// ---------------------------------------------------------------------------

/**
 * createNetfileAdapter returns a new NetfileAdapter.
 * The adapter fetches LA County Netfile contributions via the REST API
 * at https://netfile.com/api/public/sites/api.
 *
 * @param year - Calendar year context, for logs and the run's election_cycle label only.
 *               It filters nothing: each run reads a committee's whole filed history.
 */
export function createNetfileAdapter(year: number): SourceAdapter & { fetchedRowCount(): number } {
  return new NetfileAdapter(year);
}
