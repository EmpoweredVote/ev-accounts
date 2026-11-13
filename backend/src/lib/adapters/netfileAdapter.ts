/**
 * netfileAdapter — NetFile campaign-finance adapter (LA County, West Hollywood) implementing SourceAdapter.
 *
 * SOURCE: NetFile's Connect2 public API, base https://netfile.com/Connect2/api/public. Unauthenticated JSON.
 *
 * 🔴 HISTORY. From 2026-05-21 the adapter read the REST API behind NetFile's new SPA
 * (https://netfile.com/api/public/sites/api: IdSearch, filings/byFiler, SearchCampaignTransactions). Some time
 * between the 2026-10-01 run (186/186 sources, 17,791 rows) and the 2026-11-01 run, every endpoint there started
 * answering `401 Unauthorized: A valid session is required.` The 11-01 run failed all 186 sources at the first call.
 * Connect2 is the older API the WebForms portal used; it still answers without a session, and it serves the SAME
 * filing ids and transaction ids. Measured 2026-11-12 against the 17,791 stored rows: every one is in Connect2 under
 * its stored key `<filingId>-<id>`, with the same amount, instant, donor name, employer and occupation. So the
 * stored keys carry over, and the prune in upsert() removes only rows a later report replaced.
 * Bulk exports on either site demand a Cloudflare Turnstile token, so a job may only use the JSON reads below.
 *
 * AGENCY: NetFile hosts many filing officers. The link names its agency code (politician_sources.netfile_agency,
 * CA_0224: LACO = LA County, WEHO = City of West Hollywood). Connect2's transaction search takes the agency's NUMBER
 * instead (AGENCY_NUMBERS); an agency with no number fails the source rather than searching every agency.
 *
 * ENDPOINTS (measured 2026-11-12):
 *   - campaign/list/filer?AID=<code>&pageSize=N&currentPageIndex=N — every committee of the agency:
 *       { fppcId, localAgencyId, name }. fppcId is the state (FPPC/SOS) id, or "Pending" / "" before the state
 *       assigns one. localAgencyId ("LACO-113718") is NetFile's own committee id and is always set.
 *   - campaign/search/transaction/query?Agency=<number>&QueryString=<words>&ShowSuperceded=false&pageSize=N
 *       &currentPageIndex=N — a WORD search (every word must match) over the contributor name and the filer name.
 *       There is no filer filter, so rows are matched to the committee afterwards by filerLocalId / filerFppcId.
 *       ShowSuperceded=false leaves out the rows of a report a formal amendment replaced. pageSize 5,000 is honoured.
 *       🔴 A word the site's profanity filter dislikes fails the whole query with HTTP 400 ProfaneSearchException —
 *       "Assessor" (Prang's committees) and "Gaylord" both do. Such words are dropped from the query.
 *       transactionType 0 = Schedule A (monetary contributions received): all 17,791 stored Schedule A rows are type
 *       0, and no other type holds any of them.
 *     Not usable: list/filing answers an empty list for every agency, and there is no per-filing or per-filer export.
 *
 * WHICH COMMITTEE: politician_sources.external_id is either an FPPC id (172 links) or a NetFile local committee id
 * like "LACO-113718" (15 links, CA_0375). Before CA_0375 those 15 stored the old REST API's 9-digit filer id, which
 * Connect2 does not know; such an id now fails its source with a pointer to CA_0375 instead of reading nothing.
 * An FPPC id is matched to its committee(s) through the filer list, and rows are then taken by the committee's
 * localAgencyId OR its FPPC id. Both are needed: a committee's first reports are often filed while its FPPC id is
 * still "Pending" (Darlene Trevino, LACO-112910: 25 of 31 stored rows), and only the local id is on them.
 *
 * WHICH WORDS: each row carries the committee name AS IT WAS when the report was filed, and committees get renamed
 * ("Henderson for LA Community College Board 2024" → "... 2028"). The current name alone found 0 of Henderson's 187
 * stored rows. So each committee is searched twice: its current name without digits, and the one word of that name
 * that matches the fewest rows (normally the surname). Rows are matched by committee id afterwards, so a looser
 * query can only cost time, never admit another committee's rows.
 *
 * WHICH REPORTS: ShowSuperceded=false handles formal amendments. It does not handle a report whose rows another,
 * later report repeats in full: Horvath's consolidated full-year 2023 report repeats the 160 rows of his
 * 2023-01-01..06-30 report under a new filing id (the old adapter dropped the inner report by its period; Connect2
 * gives no periods). Rule here: a report whose Schedule A rows ALL reappear (same day, amount and donor) on a later
 * report of the same committee is dropped. Filing ids are issued in order, so "later" = higher filing id.
 *
 * Validation 2026-11-12 (all 187 links, this exact method, vs the rows stored by the 2026-10-01 run): 172 links
 * identical; every other difference is a report filed or amended after 10-01 — 476 new rows on 14 new reports, and
 * 161 rows on 2 reports since amended. Paging returned every counted row in all 595 searches.
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

const NETFILE_API_BASE = 'https://netfile.com/Connect2/api/public';

/**
 * Connect2's number for each agency code a link may name. Read off the transaction search's `agency` field for rows
 * of known LACO and WEHO committees (2026-11-12). Add a code here before linking a committee of a new agency.
 */
export const AGENCY_NUMBERS: Readonly<Record<string, number>> = { LACO: 625, WEHO: 197 };

/** Rows per transaction-search page. The largest query measured (Horvath's) holds 4,158 rows: one page. */
const SEARCH_PAGE_SIZE = 5_000;

/** Committees per filer-list page. LACO holds 1,767 (2026-11-12): two pages. */
const FILER_PAGE_SIZE = 1_000;

/** Schedule A — monetary contributions received — in Connect2's transactionType. */
const SCHEDULE_A = 0;

/** Request headers sent with every API call. */
const REQUEST_HEADERS = {
  Accept: 'application/json',
  'User-Agent': 'EV-CampaignFinance/1.0 (+https://empowered.vote)',
};

// ---------------------------------------------------------------------------
// Connect2 API types
// ---------------------------------------------------------------------------

interface Connect2Filer {
  id: string;
  agency: string;
  fppcId: string;
  localAgencyId: string;
  name: string;
}

interface Connect2FilerList {
  totalMatchingCount: number;
  filers: Connect2Filer[];
}

export interface Connect2Transaction {
  id: string;
  filingId: string;
  agency: number;
  filerFppcId: string;
  filerLocalId: string;
  filerName: string;
  date: string;
  amount: number;
  transactionType: number;
  name: string;
  occupation: string;
  employer: string;
  line1: string;
  line2: string;
  city: string;
  state: string;
  zip: string;
}

interface Connect2Search {
  totalMatchingCount: number;
  totalMatchingPages: number;
  results: Connect2Transaction[];
}

/** The committee a link names, as the filer list knows it. */
interface Committee {
  fppcId: string | null;
  localIds: Set<string>;
  names: string[];
}

// ---------------------------------------------------------------------------
// API client
// ---------------------------------------------------------------------------

/** A query the site's profanity filter refused (HTTP 400, ProfaneSearchException). */
class ProfaneSearchError extends Error {}

/**
 * getJson GETs one Connect2 endpoint and parses the body.
 *
 * 🔴 Throws on a network error or any non-2xx status, so runIngestion records the source as 'failed'. An error must
 * never read as an empty answer: that is how five monthly runs (2026-05-21..09-01) "completed" with 0 rows.
 */
async function getJson<T>(path: string, params: Record<string, string>): Promise<T> {
  const url = `${NETFILE_API_BASE}/${path}?${new URLSearchParams({ format: 'json', ...params }).toString()}`;
  let resp: Response;
  try {
    resp = await fetch(url, { headers: REQUEST_HEADERS });
  } catch (err) {
    throw new Error(`NetFile ${path} network error: ${err instanceof Error ? err.message : String(err)}`, {
      cause: err,
    });
  }
  if (!resp.ok) {
    const body = await resp.text().catch(() => '');
    if (resp.status === 400 && body.includes('ProfaneSearchException')) {
      throw new ProfaneSearchError(`NetFile ${path}: query refused by the profanity filter (${url})`);
    }
    throw new Error(`NetFile ${path} HTTP ${resp.status} (${url})`);
  }
  return (await resp.json()) as T;
}

/** listFilers reads every committee of one agency, checking the walk against the count. */
async function listFilers(agency: string): Promise<Connect2Filer[]> {
  const byId = new Map<string, Connect2Filer>();
  let total: number;
  for (let page = 0; ; page++) {
    const data = await getJson<Connect2FilerList>('campaign/list/filer', {
      AID: agency,
      pageSize: String(FILER_PAGE_SIZE),
      currentPageIndex: String(page),
    });
    total = data.totalMatchingCount ?? 0;
    const filers = data.filers ?? [];
    for (const f of filers) byId.set(f.id, f);
    if (filers.length === 0 || (page + 1) * FILER_PAGE_SIZE >= total) break;
  }
  if (byId.size < total) {
    throw new Error(`NetFile filer list ${agency}: ${total} counted, ${byId.size} read — the page walk lost committees`);
  }
  return [...byId.values()];
}

/** A NetFile local committee id, e.g. "LACO-113718". */
const LOCAL_ID = /^[A-Z0-9]{2,12}-\d+$/;
/** An FPPC id. They run to 7 digits today; the old REST filer ids are 9. */
const FPPC_ID = /^\d{1,8}$/;

/**
 * findCommittee matches a link's external_id to the agency's committee(s). Returns null when the agency lists none:
 * the link then reads no rows, as a committee that never filed would.
 */
export function findCommittee(filers: Connect2Filer[], externalId: string): Committee | null {
  let matched: Connect2Filer[];
  let fppcId: string | null = null;
  if (LOCAL_ID.test(externalId)) {
    matched = filers.filter((f) => f.localAgencyId === externalId);
  } else if (FPPC_ID.test(externalId)) {
    fppcId = externalId;
    matched = filers.filter((f) => f.fppcId === externalId);
  } else if (/^\d{9}$/.test(externalId)) {
    throw new Error(
      `external_id ${externalId} is a filer id of NetFile's retired REST API, which Connect2 does not know — ` +
        `store the committee's NetFile local id (e.g. "LACO-113718") instead, as CA_0375 did`
    );
  } else {
    throw new Error(`external_id "${externalId}" is neither an FPPC id nor a NetFile local committee id`);
  }
  if (matched.length === 0) return null;
  return {
    fppcId,
    localIds: new Set(matched.map((f) => f.localAgencyId)),
    names: [...new Set(matched.map((f) => f.name))],
  };
}

/** queryWords reduces a committee name to the words a search can take: letters only, no years or punctuation. */
export function queryWords(name: string): string[] {
  return name.replace(/[^A-Za-z]+/g, ' ').trim().split(' ').filter((w) => w !== '');
}

/**
 * dropRepeatedReports removes the rows of every report whose Schedule A rows all reappear — same day, amount and
 * donor, counted with multiplicity — on a later report (higher filing id) of the same committee. See the header
 * (WHICH REPORTS). A report with no Schedule A row is never dropped: it has nothing to repeat.
 */
export function dropRepeatedReports(rows: Connect2Transaction[]): Connect2Transaction[] {
  const byFiling = new Map<string, Map<string, number>>();
  for (const r of rows) {
    if (r.transactionType !== SCHEDULE_A) continue;
    const sig = `${r.date.slice(0, 10)}|${Number(r.amount).toFixed(2)}|${(r.name ?? '').trim().toLowerCase()}`;
    const counts = byFiling.get(r.filingId) ?? new Map<string, number>();
    counts.set(sig, (counts.get(sig) ?? 0) + 1);
    byFiling.set(r.filingId, counts);
  }
  const order = (id: string) => parseFloat(id);
  const contains = (outer: Map<string, number>, inner: Map<string, number>) =>
    [...inner].every(([sig, n]) => (outer.get(sig) ?? 0) >= n);

  const dropped = new Set<string>();
  for (const [filing, counts] of byFiling) {
    for (const [later, laterCounts] of byFiling) {
      if (order(later) > order(filing) && contains(laterCounts, counts)) {
        dropped.add(filing);
        break;
      }
    }
  }
  return dropped.size === 0 ? rows : rows.filter((r) => !dropped.has(r.filingId));
}

/**
 * Connect2Client wraps the API for one run. It reads each agency's filer list once and remembers how many rows each
 * single word matches, since the same surnames recur across links.
 */
class Connect2Client {
  private readonly filers = new Map<string, Promise<Connect2Filer[]>>();
  private readonly wordCounts = new Map<string, Promise<number>>();

  filersOf(agency: string): Promise<Connect2Filer[]> {
    let p = this.filers.get(agency);
    if (!p) {
      p = listFilers(agency);
      p.catch(() => this.filers.delete(agency)); // a failed read is retried by the next source
      this.filers.set(agency, p);
    }
    return p;
  }

  /** count returns how many rows a query matches; a query the profanity filter refuses throws ProfaneSearchError. */
  private async count(agency: number, query: string): Promise<number> {
    const data = await getJson<Connect2Search>('campaign/search/transaction/query', {
      Agency: String(agency),
      QueryString: query,
      ShowSuperceded: 'false',
      pageSize: '1',
      currentPageIndex: '0',
    });
    return data.totalMatchingCount ?? 0;
  }

  /** wordCount is count() for one word, remembered; a refused word counts as 0 (never searched). */
  private wordCount(agency: number, word: string): Promise<number> {
    const key = `${agency}|${word.toLowerCase()}`;
    let p = this.wordCounts.get(key);
    if (!p) {
      p = this.count(agency, word).catch((err) => {
        if (err instanceof ProfaneSearchError) return 0;
        this.wordCounts.delete(key);
        throw err;
      });
      this.wordCounts.set(key, p);
    }
    return p;
  }

  /**
   * queriesFor returns the searches for one committee name: the name's words minus any the profanity filter
   * refuses, and the single word matching the fewest rows. See the header (WHICH WORDS).
   */
  async queriesFor(agency: number, name: string): Promise<string[]> {
    let words = queryWords(name);
    if (words.length === 0) return [];
    try {
      await this.count(agency, words.join(' '));
    } catch (err) {
      if (!(err instanceof ProfaneSearchError)) throw err;
      const kept: string[] = [];
      for (const w of words) {
        if (await this.isRefused(agency, w)) {
          console.log(`[netfileAdapter] "${w}" dropped from the search for "${name}": the profanity filter refuses it`);
        } else {
          kept.push(w);
        }
      }
      words = kept;
    }
    const queries = new Set<string>();
    if (words.length > 0) queries.add(words.join(' '));
    let rarest: { word: string; n: number } | null = null;
    for (const w of new Set(words)) {
      if (w.length < 3) continue;
      const n = await this.wordCount(agency, w);
      if (n > 0 && (rarest === null || n < rarest.n)) rarest = { word: w, n };
    }
    if (rarest) queries.add(rarest.word);
    return [...queries];
  }

  private async isRefused(agency: number, word: string): Promise<boolean> {
    try {
      await this.count(agency, word);
      return false;
    } catch (err) {
      if (err instanceof ProfaneSearchError) return true;
      throw err;
    }
  }

  /**
   * search walks every page of one query and returns all its rows. Fails when the walk read fewer distinct rows than
   * the search counted, so a page that shifted between calls can never drop a row silently.
   */
  async search(agency: number, query: string): Promise<Connect2Transaction[]> {
    const byKey = new Map<string, Connect2Transaction>();
    let total = 0;
    let pages = 1;
    for (let page = 0; page < pages; page++) {
      const data = await getJson<Connect2Search>('campaign/search/transaction/query', {
        Agency: String(agency),
        QueryString: query,
        ShowSuperceded: 'false',
        pageSize: String(SEARCH_PAGE_SIZE),
        currentPageIndex: String(page),
      });
      total = data.totalMatchingCount ?? 0;
      pages = data.totalMatchingPages ?? 0;
      for (const r of data.results ?? []) byKey.set(`${r.filingId}-${r.id}`, r);
    }
    if (byKey.size < total) {
      throw new Error(`NetFile search "${query}": ${total} counted, ${byKey.size} read — the page walk lost rows`);
    }
    return [...byKey.values()];
  }
}

// ---------------------------------------------------------------------------
// Normalizer — Connect2 transaction → ContributionInsert
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
    const tx = records[idx] as unknown as Connect2Transaction;

    // Only Schedule A (monetary contributions received). Every other schedule is a deliberate omission, never a
    // defect: expenditures, loans, non-monetary gifts, and the 497 late reports, whose gifts the next 460
    // re-reports on Schedule A.
    if (tx.transactionType !== SCHEDULE_A) {
      excluded++;
      continue;
    }

    // Any finite amount. A negative Schedule A line is a real adjustment, and the Cal-Access and OCPF adapters keep
    // it too.
    const amount = Number(tx.amount);
    if (!isFinite(amount)) {
      console.warn(`[netfileAdapter] skip tx id=${tx.id} — amount invalid (${tx.amount})`);
      skipped++;
      continue;
    }

    // Contribution date: local midnight with its offset ("2025-07-01T00:00:00.0000000-07:00"), the same instant the
    // REST API gave as "2025-07-01T07:00:00Z".
    let contributionDate: Date | null = null;
    if (tx.date) {
      const d = new Date(tx.date);
      if (!isNaN(d.getTime())) contributionDate = d;
    }
    if (contributionDate === null) {
      console.warn(`[netfileAdapter] skip tx id=${tx.id} — date unparseable (${tx.date})`);
      skipped++;
      continue;
    }

    // election_cycle: round UP to next even year (same formula as other CA adapters).
    let cycleYear = contributionDate.getUTCFullYear();
    if (cycleYear % 2 !== 0) cycleYear += 1;
    const electionCycle = String(cycleYear);

    const donorName = tx.name ?? '';
    const cityLine = [tx.city, [tx.state, tx.zip].filter(Boolean).join(' ')].filter(Boolean).join(', ');
    const address = [tx.line1, tx.line2, cityLine].filter(Boolean).join(', ');

    // source_transaction_id: filingId + transaction id — the same ids the REST API served, so the key of every row
    // loaded before 2026-11 is unchanged.
    const sourceTransactionId = `${tx.filingId}-${tx.id}`;

    // Raw record plus the aliases campaignFinanceService reads. `schedule` keeps the REST API's label, so rows from
    // both APIs read alike.
    const rawRecord: Record<string, unknown> = {
      ...(tx as unknown as Record<string, unknown>),
      schedule: '460A',
      address,
      contributor_name: donorName,
      contributor_employer: tx.employer ?? '',
      contributor_occupation: tx.occupation ?? '',
      contributor_address: address,
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
 * API stops showing keeps its rows.
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
  private readonly api = new Connect2Client();
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
   * fetch reads every row of the committee's current reports. normalize() then keeps Schedule A.
   * See the header for the endpoints and their traps.
   */
  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    const externalId = ps.external_id?.trim() ?? '';

    if (externalId === '') {
      console.warn(`[netfileAdapter] ps.id=${ps.id} has empty external_id — skipping`);
      return { records: [], totalExpected: 0, totalFetched: 0 };
    }

    // Which filing officer holds this committee. Never defaulted: under the wrong agency every read answers nothing,
    // which is indistinguishable from a quiet committee.
    const agency = ps.netfile_agency?.trim() ?? '';
    if (agency === '') {
      throw new Error(
        `[netfileAdapter] ps.id=${ps.id} (id=${externalId}) has no netfile_agency — cannot tell which NetFile agency files it`
      );
    }
    const agencyNumber = AGENCY_NUMBERS[agency];
    if (agencyNumber === undefined) {
      throw new Error(`[netfileAdapter] ps.id=${ps.id}: no Connect2 agency number for "${agency}" — add it to AGENCY_NUMBERS`);
    }

    const committee = findCommittee(await this.api.filersOf(agency), externalId);
    if (committee === null) {
      console.log(`[netfileAdapter] fetch: id=${externalId} — NetFile ${agency} lists no committee for it`);
      return { records: [], totalExpected: 0, totalFetched: 0 };
    }

    // Every row filed by the committee, whichever query found it.
    const queries = new Set<string>();
    for (const name of committee.names) {
      for (const q of await this.api.queriesFor(agencyNumber, name)) queries.add(q);
    }
    const byKey = new Map<string, Connect2Transaction>();
    for (const query of queries) {
      for (const r of await this.api.search(agencyNumber, query)) {
        const own =
          committee.localIds.has(r.filerLocalId) || (committee.fppcId !== null && r.filerFppcId === committee.fppcId);
        if (own) byKey.set(`${r.filingId}-${r.id}`, r);
      }
    }

    const all = [...byKey.values()];
    const records = dropRepeatedReports(all);
    this.fetched += records.length;
    console.log(
      `[netfileAdapter] fetch: id=${externalId} agency=${agency} year=${this.year} ` +
        `committees=${JSON.stringify([...committee.localIds])} queries=${JSON.stringify([...queries])} ` +
        `rows=${all.length} repeated=${all.length - records.length}`
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
 * createNetfileAdapter returns a new NetfileAdapter, which reads NetFile's Connect2 public API
 * (https://netfile.com/Connect2/api/public). Use one adapter per run: it reads each agency's filer list once.
 *
 * @param year - Calendar year context, for logs and the run's election_cycle label only.
 *               It filters nothing: each run reads a committee's whole filed history.
 */
export function createNetfileAdapter(year: number): SourceAdapter & { fetchedRowCount(): number } {
  return new NetfileAdapter(year);
}
