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
import type { SourceAdapter, StreamingAdapter, BatchSink, FetchResult, NormalizeResult, UpsertResult, ContributionInsert, SupersededFiling } from './adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';
import { normalizeDonorName } from './normalizeDonorName.js';
import { buildCandidateCommitteeMap } from './fecBulkLoader.js';
import { acquireFecSlot } from '../fecRateLimiter.js';

// Per-politician record cap — prevents timeout on high-volume candidates (e.g. CA House members).
// At 100 records/page + 4s sleep, 2500 records ≈ 25 pages ≈ 100s — well under Redis lock TTL.
// Override via MAX_RECORDS_PER_POLITICIAN env var.
// Per-politician record cap. Raised from the old 2500 (which silently truncated
// big raisers and, because total_raised sums ingested rows, undercounted their
// headline totals). With date-window chunking (below) large committees are now
// fetchable, so we keep essentially all itemized records. Still env-overridable
// as a runaway backstop.
const MAX_RECORDS_PER_POLITICIAN = parseInt(process.env.MAX_RECORDS_PER_POLITICIAN ?? '50000', 10);

// Sort order for Schedule A. Sorting by descending amount means that when a
// mega-committee exceeds MAX_RECORDS_PER_POLITICIAN, the records we KEEP are the
// largest donations — the ones a transparency tool most needs to surface — rather
// than merely the most recent. Keyset pagination adapts automatically because we
// forward whatever cursor keys FEC returns in last_indexes.
const FEC_SORT = process.env.FEC_SORT ?? '-contribution_receipt_amount';

// Per-page delay between Schedule A pages. Raised + env-configurable so a long
// backfill can stay well under the shared FEC 1,000 req/hr ceiling (the cron and
// the backfill share one key; near the limit FEC hangs connections rather than
// returning a clean 429, which surfaces as fetch timeouts).
const PER_PAGE_SLEEP_MS = parseInt(process.env.FEC_PER_PAGE_SLEEP_MS ?? '5000', 10);

// ---------------------------------------------------------------------------
// FEC API response types
// ---------------------------------------------------------------------------

// FEC returns whichever cursor keys correspond to the active sort (e.g.
// last_index + last_contribution_receipt_amount for amount sort). Keep it generic
// and forward every key back as a query param on the next page.
type FecLastIndexes = Record<string, string | number | null>;

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
 * parseRetryAfterMs (FEC-03) defensively parses a `Retry-After` header — not
 * documented for api.data.gov/FEC (174-RESEARCH.md Pitfall 1), but free to check
 * since some API-Umbrella deployments do add it. Handles both the numeric-seconds
 * and HTTP-date forms. Returns null when absent or unparseable so callers fall
 * back to the existing exponential delay. The caller MUST clamp the returned
 * value to the existing 120s ceiling before sleeping (V5/DoS) — this function
 * itself does not clamp.
 */
function parseRetryAfterMs(response: Response): number | null {
  const retryAfter = response.headers.get('retry-after');
  if (!retryAfter) return null;
  const asSeconds = Number(retryAfter);
  if (!Number.isNaN(asSeconds)) return asSeconds * 1000;
  const asDate = Date.parse(retryAfter);
  return Number.isNaN(asDate) ? null : Math.max(0, asDate - Date.now());
}

/**
 * readRemaining (FEC-03) defensively reads the documented `X-RateLimit-Remaining`
 * header. Never reads `X-RateLimit-Reset` — that header does not exist for this
 * API (174-RESEARCH.md Pitfall 1). Returns null when absent/unparseable.
 */
function readRemaining(response: Response): number | null {
  const remaining = response.headers.get('x-ratelimit-remaining');
  if (remaining === null) return null;
  const n = Number(remaining);
  return Number.isNaN(n) ? null : n;
}

/**
 * resolveCommitteeIds looks up the principal committee IDs for a given FEC candidate ID.
 * The FEC schedule_a endpoint filters by committee_id, not candidate_id.
 *
 * FEC-01: bulk-first. The free bulk ccl{YY}.zip candidate->committee linkage
 * (buildCandidateCommitteeMap, cached 7 days) is consulted first and, on a hit, this
 * function returns with ZERO FEC API requests. The rate-limited candidates-search API
 * call below only runs as the fallback on a bulk-map miss (new/stale candidate not yet
 * in the bulk file) — and its result is never cached as authoritative, so a miss is
 * re-checked on every call rather than being suppressed (Pitfall 3).
 */
async function resolveCommitteeIds(candidateId: string, cycle: string, apiKey: string, maxRetries = 5): Promise<string[]> {
  const bulkMap = await buildCandidateCommitteeMap(cycle);
  const bulkCommittees = bulkMap.get(candidateId);
  if (bulkCommittees && bulkCommittees.length > 0) {
    return bulkCommittees;
  }

  // Bulk-map miss — fall back to the FEC candidates-search API (unchanged backoff below).
  const url = `https://api.open.fec.gov/v1/candidates/search/?api_key=${apiKey}&candidate_id=${candidateId}`;
  // Same 429 / throttle-timeout exponential backoff as fetchWithRetry (the Schedule A path).
  // Previously this did a bare fetch and threw on the first 429 — with the shared 1,000 req/hr
  // FEC key, the 6-hourly cron looping ~1k sources blew past the limit and mass-failed here
  // ("FEC candidate lookup failed: HTTP 429"). Backing off both recovers the run and throttles
  // the request rate so we stay under the ceiling. See the 2026-07-23 cron audit.
  let delayMs = 2000;
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    await acquireFecSlot(); // FEC-03 — shared limiter gate, before every attempt including retries
    let response: Response;
    try {
      response = await fetch(url, { signal: AbortSignal.timeout(60_000) });
    } catch (err) {
      const isAbort = err instanceof Error && (err.name === 'AbortError' || err.name === 'TimeoutError' || /abort|timeout/i.test(err.message));
      if (isAbort && attempt < maxRetries) {
        console.warn(`[fecAdapter] candidate lookup timed out (likely throttle) — backing off ${delayMs}ms (attempt ${attempt + 1}/${maxRetries})`);
        await sleep(delayMs);
        delayMs = Math.min(delayMs * 2, 120_000);
        continue;
      }
      throw err;
    }

    const remaining = readRemaining(response);
    if (remaining !== null && remaining <= 5) {
      console.warn(`[fecAdapter] FEC X-RateLimit-Remaining low: ${remaining} (candidate lookup)`);
    }

    if (response.status === 429) {
      if (attempt === maxRetries) {
        throw new Error(`FEC candidate lookup rate limited (429) after ${maxRetries} retries for ${candidateId}`);
      }
      // FEC-03: prefer a server-supplied Retry-After (clamped to the existing 120s
      // ceiling — never sleep on an unclamped header value, V5/DoS); fall back to
      // the existing exponential delay when absent.
      const serverDelay = parseRetryAfterMs(response);
      const delay = Math.min(serverDelay ?? delayMs, 120_000);
      console.warn(`[fecAdapter] candidate lookup 429 — retrying in ${delay}ms (attempt ${attempt + 1}/${maxRetries})${serverDelay != null ? ' [server Retry-After honored]' : ''}`);
      await sleep(delay);
      delayMs = Math.min(delayMs * 2, 120_000);
      continue;
    }

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
  throw new Error(`FEC candidate lookup: unexpected loop exit for ${candidateId}`);
}

/**
 * FecQueryTooLargeError signals that a Schedule A query is too big for FEC to
 * compute in time — FEC returns HTTP 504 (or persistently hangs) on whole-cycle
 * queries for mega-committees. The caller responds by subdividing the query into
 * smaller date windows rather than failing the whole (source, cycle) pair.
 */
class FecQueryTooLargeError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'FecQueryTooLargeError';
  }
}

function isTooLarge(err: unknown): boolean {
  return err instanceof FecQueryTooLargeError;
}

// --- Date-window helpers (pure) --------------------------------------------

/** [start, end] ISO dates (YYYY-MM-DD) for a FEC 2-year cycle, e.g. "2018" -> ["2017-01-01","2018-12-31"]. */
function cycleDateRange(cycle: string): [string, string] {
  const even = parseInt(cycle, 10);
  return [`${even - 1}-01-01`, `${even}-12-31`];
}

/** Split an inclusive [minDate, maxDate] range into N roughly-equal windows as [start,end] ISO pairs. */
function splitRange(minDate: string, maxDate: string, parts: number): Array<[string, string]> {
  const startMs = Date.parse(`${minDate}T00:00:00Z`);
  const endMs = Date.parse(`${maxDate}T00:00:00Z`);
  const span = endMs - startMs;
  const dayMs = 86_400_000;
  const iso = (ms: number): string => new Date(ms).toISOString().slice(0, 10);
  const out: Array<[string, string]> = [];
  for (let i = 0; i < parts; i++) {
    const ws = startMs + Math.round((span * i) / parts);
    const weExclusive = startMs + Math.round((span * (i + 1)) / parts);
    // window end is the day before the next window's start (inclusive, non-overlapping)
    const we = i === parts - 1 ? endMs : weExclusive - dayMs;
    if (we < ws) continue;
    out.push([iso(ws), iso(we)]);
  }
  return out;
}

// --- Per-window resume progress (survives dyno restarts mid-mega-pair) ---------
//
// A mega-committee pull is subdivided into date windows. When a window is fully
// fetched we record it in transparent_motivations.fec_ingest_window_progress. On a
// later run (e.g. after a Render restart) we skip windows already recorded complete
// rather than re-hitting the FEC API from page zero. Incremental commit (per page,
// below) is what makes those windows' rows durable; this table is what makes the
// *fetch* resumable. Both reads and writes degrade gracefully (log + continue) if
// the table is missing, so the adapter still works before the migration is applied.

/** Running fetched-record counter shared across a pair's committees/windows (cap math). */
interface StreamCounter { fetched: number }

/** Resume context for one committee: the source-row id + its already-complete windows. */
interface WindowProgress { psId: string; completed: Map<string, number> }

const wkey = (minDate: string, maxDate: string): string => `${minDate}|${maxDate}`;

async function getCompletedWindows(
  psId: string,
  cycle: string,
  committeeId: string
): Promise<Map<string, number>> {
  const m = new Map<string, number>();
  try {
    const r = await pool.query<{ window_start: string; window_end: string; records_fetched: number }>(
      `SELECT to_char(window_start,'YYYY-MM-DD') AS window_start,
              to_char(window_end,'YYYY-MM-DD')   AS window_end,
              records_fetched
       FROM transparent_motivations.fec_ingest_window_progress
       WHERE politician_source_id = $1 AND election_cycle = $2 AND committee_id = $3`,
      [psId, cycle, committeeId]
    );
    for (const row of r.rows) m.set(wkey(row.window_start, row.window_end), Number(row.records_fetched));
  } catch (err) {
    console.warn(`[fecAdapter] window-progress read skipped: ${err instanceof Error ? err.message : String(err)}`);
  }
  return m;
}

async function recordWindowComplete(
  psId: string,
  cycle: string,
  committeeId: string,
  minDate: string,
  maxDate: string,
  count: number
): Promise<void> {
  try {
    await pool.query(
      `INSERT INTO transparent_motivations.fec_ingest_window_progress
         (politician_source_id, election_cycle, committee_id, window_start, window_end, records_fetched, completed_at)
       VALUES ($1, $2, $3, $4::date, $5::date, $6, now())
       ON CONFLICT (politician_source_id, election_cycle, committee_id, window_start, window_end)
       DO UPDATE SET records_fetched = EXCLUDED.records_fetched, completed_at = now()`,
      [psId, cycle, committeeId, minDate, maxDate, count]
    );
  } catch (err) {
    console.warn(`[fecAdapter] window-progress write skipped: ${err instanceof Error ? err.message : String(err)}`);
  }
}

/**
 * getFecLoadCursor (FEC-02) returns a date-only (YYYY-MM-DD) watermark derived from the
 * max started_at of prior successful ('completed'/'completed_with_warning') fec
 * ingestion_runs rows for this (politician_source_id, election_cycle) pair, minus a
 * 2-day safety lookback (absorbs load_date day-boundary/timezone drift and FEC's nightly
 * ~03:05 UTC batch-load timing — 174-RESEARCH-amendments.md A3). Returns null when no
 * prior successful run exists, so the caller falls back to the existing whole-cycle
 * (initial-backfill) path. Reuses the existing ingestion_runs table — no new schema.
 *
 * The row this same call is part of is inserted with status='running' by runIngestion.ts
 * BEFORE fetchStream is invoked, so it is correctly excluded by the status filter here —
 * only a PRIOR run's watermark is ever read.
 */
async function getFecLoadCursor(psId: string, cycle: string): Promise<string | null> {
  const res = await pool.query<{ started_at: string | Date | null }>(
    `SELECT max(started_at) AS started_at
     FROM transparent_motivations.ingestion_runs
     WHERE adapter_name = 'fec'
       AND politician_source_id = $1
       AND election_cycle = $2
       AND status IN ('completed', 'completed_with_warning')`,
    [psId, cycle]
  );
  const startedAt = res.rows[0]?.started_at;
  if (!startedAt) return null;
  const d = new Date(startedAt);
  if (isNaN(d.getTime())) return null;
  d.setUTCDate(d.getUTCDate() - 2);
  // Date-only — min_load_date is date-only granularity; a timestamp is 422-rejected
  // (174-RESEARCH-amendments.md point 1).
  return d.toISOString().slice(0, 10);
}

/**
 * streamPagesForWindow keyset-paginates one committee's Schedule A within an optional
 * [minDate, maxDate] window (null,null = whole cycle) and hands each page to onBatch
 * as it arrives — so records are persisted incrementally, not buffered to end-of-pair.
 * Returns pagination.count for the window (for completeness math).
 *
 * Resume: for real date windows (non-null) with a progress context, a window already
 * recorded complete is skipped (its rows are already in the DB) and its recorded count
 * is added to the shared counter so the completeness ratio stays correct. A window that
 * finishes cleanly (not capped) is recorded complete for future resumes.
 *
 * minLoadDate (FEC-02): when non-null, sets min_load_date on the request so a normal
 * run fetches only rows loaded (incl. amended/re-loaded) since the cursor, instead of
 * re-pulling the whole cycle. Always date-only. null = unchanged whole-cycle behavior.
 *
 * Throws FecQueryTooLargeError if FEC 504s / persistently times out on this window.
 */
async function streamPagesForWindow(
  committeeId: string,
  cycle: string,
  apiKey: string,
  onBatch: BatchSink,
  counter: StreamCounter,
  minDate: string | null,
  maxDate: string | null,
  minLoadDate: string | null,
  progress: WindowProgress | null,
  signal?: AbortSignal
): Promise<number> {
  // Resume fast-exit: this exact committee+window was already fully fetched before.
  if (minDate && maxDate && progress) {
    const prior = progress.completed.get(wkey(minDate, maxDate));
    if (prior !== undefined) {
      counter.fetched += prior;
      console.log(`[fecAdapter] resume: committee ${committeeId} window ${minDate}..${maxDate} already complete (${prior} rows) — skipping fetch`);
      return prior;
    }
  }

  const baseUrl = 'https://api.open.fec.gov/v1/schedules/schedule_a/';
  let totalExpected = 0;
  let firstPage = true;
  let lastIndexes: FecLastIndexes | null = null;
  let cappedOut = false;
  let aborted = false;

  for (;;) {
    const params = new URLSearchParams({
      api_key: apiKey,
      committee_id: committeeId,
      two_year_transaction_period: cycle,
      per_page: '100',
      sort: FEC_SORT,
    });
    if (minDate) params.set('min_date', minDate);
    if (maxDate) params.set('max_date', maxDate);
    if (minLoadDate) params.set('min_load_date', minLoadDate);

    // Forward every cursor key FEC handed back (keys match the active sort), so
    // pagination is correct regardless of FEC_SORT.
    if (!firstPage && lastIndexes) {
      for (const [k, v] of Object.entries(lastIndexes)) {
        if (v != null) params.set(k, String(v));
      }
    }

    const page = await fetchWithRetry(`${baseUrl}?${params.toString()}`);

    if (firstPage) {
      totalExpected = page.pagination.count;
      firstPage = false;
    }

    // Incremental commit: persist this page's records before fetching the next page.
    if (page.results.length > 0) {
      await onBatch(page.results);
      counter.fetched += page.results.length;
    }

    if (counter.fetched >= MAX_RECORDS_PER_POLITICIAN) {
      console.warn(
        `[fecAdapter] Record cap reached at committee ${committeeId}: ${counter.fetched} records. ` +
        `Capping at ${MAX_RECORDS_PER_POLITICIAN}.`
      );
      cappedOut = true;
      break;
    }

    // Wall-clock budget / cancellation: stop fetching mid-window. Rows already streamed
    // stay persisted (incremental commit); the window is NOT marked complete so a later
    // run resumes it. This is what makes the sweep's maxMinutes a real bound even on a
    // single multi-hour mega-pair.
    if (signal?.aborted) {
      console.log(`[fecAdapter] abort signal received — stopping fetch for committee ${committeeId} (${counter.fetched} records so far)`);
      aborted = true;
      break;
    }

    if (page.results.length === 0 || page.pagination.last_indexes == null) {
      break;
    }

    lastIndexes = page.pagination.last_indexes;

    await sleep(PER_PAGE_SLEEP_MS);
  }

  // Record completion only for real date windows that finished WITHOUT hitting the cap
  // or being aborted mid-window (either case = truncated, not complete — never mark it
  // resumable-done).
  if (minDate && maxDate && progress && !cappedOut && !aborted) {
    await recordWindowComplete(progress.psId, cycle, committeeId, minDate, maxDate, totalExpected);
    progress.completed.set(wkey(minDate, maxDate), totalExpected);
  }

  return totalExpected;
}

/** Max recursive subdivisions: quarter (depth 0) -> ~month (1) -> ~10-day (2). */
const MAX_WINDOW_SUBDIVISION_DEPTH = 2;

/**
 * streamWindowAdaptive fetches one date window; if FEC reports the window is still
 * too large (504/timeout), it splits the window in half and recurses, down to
 * MAX_WINDOW_SUBDIVISION_DEPTH. Only the failing window is subdivided. Sub-windows
 * record their own resume progress; the parent (which threw) is not recorded.
 */
async function streamWindowAdaptive(
  committeeId: string,
  cycle: string,
  apiKey: string,
  onBatch: BatchSink,
  counter: StreamCounter,
  minDate: string,
  maxDate: string,
  minLoadDate: string | null,
  depth: number,
  progress: WindowProgress | null,
  signal?: AbortSignal
): Promise<number> {
  try {
    return await streamPagesForWindow(committeeId, cycle, apiKey, onBatch, counter, minDate, maxDate, minLoadDate, progress, signal);
  } catch (err) {
    if (!isTooLarge(err) || depth >= MAX_WINDOW_SUBDIVISION_DEPTH || minDate === maxDate) {
      throw err;
    }
    console.warn(
      `[fecAdapter] window ${minDate}..${maxDate} still too large for ${committeeId} — subdividing (depth ${depth + 1})`
    );
    let total = 0;
    for (const [ws, we] of splitRange(minDate, maxDate, 2)) {
      if (counter.fetched >= MAX_RECORDS_PER_POLITICIAN || signal?.aborted) break;
      total += await streamWindowAdaptive(committeeId, cycle, apiKey, onBatch, counter, ws, we, minLoadDate, depth + 1, progress, signal);
    }
    return total;
  }
}

/**
 * streamAllPagesForCommittee streams all Schedule A pages for a single committee_id.
 * Fast path: one whole-cycle (or, when minLoadDate is set, incremental-since-cursor)
 * keyset-paginated pull — a single window, streamed page-by-page. Fallback: if FEC
 * 504s / persistently times out (mega-committee too large to compute in one query),
 * fall back to quarter date windows, subdividing to months on any window that is
 * itself too large. Dedup via ON CONFLICT (sub_id) makes the (rare) window-boundary
 * re-fetch harmless. minLoadDate (FEC-02) threads through both the fast path and the
 * windowed fallback so an incremental refresh never silently reverts to whole-cycle
 * volume even on a mega-committee.
 */
async function streamAllPagesForCommittee(
  committeeId: string,
  cycle: string,
  apiKey: string,
  onBatch: BatchSink,
  counter: StreamCounter,
  minLoadDate: string | null,
  progress: WindowProgress | null,
  signal?: AbortSignal
): Promise<number> {
  // Fast path — whole cycle (or incremental-since-cursor) in one query. Common case;
  // no window progress tracking (a whole-cycle window that completes means the pair
  // is done anyway).
  try {
    return await streamPagesForWindow(committeeId, cycle, apiKey, onBatch, counter, null, null, minLoadDate, null, signal);
  } catch (err) {
    if (!isTooLarge(err)) throw err;
    console.warn(
      `[fecAdapter] whole-cycle query too large for ${committeeId} cycle ${cycle} — falling back to date windows`
    );
  }

  // Windowed fallback — quarters across the cycle, adaptive subdivision on 504.
  const [cycleStart, cycleEnd] = cycleDateRange(cycle);
  let totalExpected = 0;
  for (const [ws, we] of splitRange(cycleStart, cycleEnd, 8)) {
    if (counter.fetched >= MAX_RECORDS_PER_POLITICIAN || signal?.aborted) break;
    totalExpected += await streamWindowAdaptive(committeeId, cycle, apiKey, onBatch, counter, ws, we, minLoadDate, 0, progress, signal);
  }
  return totalExpected;
}

/**
 * streamAllPages resolves a candidate ID to its principal committee IDs, then streams
 * all Schedule A contributions across those committees for the given election cycle,
 * handing each page to onBatch as it arrives (incremental persistence). Returns the
 * cumulative FEC expected count and the number of records actually fetched (which
 * includes rows skipped-as-already-complete on a resume).
 *
 * FEC schedule_a does not filter by candidate_id — it requires committee_id.
 * This function does the two-step lookup transparently.
 */
async function streamAllPages(
  candidateId: string,
  cycle: string,
  onBatch: BatchSink,
  psId: string,
  signal?: AbortSignal
): Promise<{ totalExpected: number; totalFetched: number }> {
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) {
    console.warn('[fecAdapter] FEC_API_KEY environment variable is not set — fetches will fail');
  }

  const committeeIds = await resolveCommitteeIds(candidateId, cycle, apiKey ?? '');
  if (committeeIds.length === 0) {
    return { totalExpected: 0, totalFetched: 0 };
  }

  // FEC-02: compute the incremental cursor once per (candidate, cycle) — a single
  // watermark shared across every committee in this pair, not re-derived per committee.
  // null (no prior successful run) leaves the whole-cycle initial-backfill path unchanged.
  const minLoadDate = await getFecLoadCursor(psId, cycle);
  if (minLoadDate) {
    console.log(`[fecAdapter] incremental refresh for candidate ${candidateId} cycle ${cycle}: min_load_date=${minLoadDate}`);
  }

  const counter: StreamCounter = { fetched: 0 };
  let totalExpected = 0;

  for (const committeeId of committeeIds) {
    if (counter.fetched >= MAX_RECORDS_PER_POLITICIAN || signal?.aborted) break;
    console.log(`[fecAdapter] Fetching committee ${committeeId} for candidate ${candidateId} cycle ${cycle}`);
    // Load prior completed windows for this committee so a resumed run skips them.
    const progress: WindowProgress = { psId, completed: await getCompletedWindows(psId, cycle, committeeId) };
    const count = await streamAllPagesForCommittee(committeeId, cycle, apiKey ?? '', onBatch, counter, minLoadDate, progress, signal);
    totalExpected += count;
  }

  return { totalExpected, totalFetched: counter.fetched };
}

/**
 * fetchWithRetry wraps native fetch() with 429 exponential backoff.
 * Start delay: 1s, max delay: 60s, max retries: 3.
 */
async function fetchWithRetry(url: string, maxRetries = 5): Promise<FecScheduleAResponse> {
  let delayMs = 2000;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    await acquireFecSlot(); // FEC-03 — shared limiter gate, before every attempt including retries
    let response: Response;
    try {
      response = await fetch(url, { signal: AbortSignal.timeout(60_000) });
    } catch (err) {
      // A timeout/abort here is the throttle signature: near the shared 1,000 req/hr
      // ceiling FEC hangs the connection instead of returning 429, so our 60s
      // AbortSignal fires. Treat it like a 429 — back off and retry — rather than
      // failing the whole (source, cycle) pair.
      const isAbort = err instanceof Error && (err.name === 'AbortError' || err.name === 'TimeoutError' || /abort|timeout/i.test(err.message));
      if (isAbort && attempt < maxRetries) {
        console.warn(`[fecAdapter] request timed out (likely throttle) — backing off ${delayMs}ms (attempt ${attempt + 1}/${maxRetries})`);
        await sleep(delayMs);
        delayMs = Math.min(delayMs * 2, 120_000);
        continue;
      }
      throw err;
    }

    const remaining = readRemaining(response);
    if (remaining !== null && remaining <= 5) {
      console.warn(`[fecAdapter] FEC X-RateLimit-Remaining low: ${remaining} (schedule_a)`);
    }

    if (response.status === 429) {
      if (attempt === maxRetries) {
        throw new Error(`FEC API rate limited (429) after ${maxRetries} retries`);
      }
      // FEC-03: prefer a server-supplied Retry-After (clamped to the existing 120s
      // ceiling — never sleep on an unclamped header value, V5/DoS); fall back to
      // the existing exponential delay when absent.
      const serverDelay = parseRetryAfterMs(response);
      const delay = Math.min(serverDelay ?? delayMs, 120_000);
      console.warn(`[fecAdapter] 429 rate limit — retrying in ${delay}ms (attempt ${attempt + 1}/${maxRetries})${serverDelay != null ? ' [server Retry-After honored]' : ''}`);
      await sleep(delay);
      delayMs = Math.min(delayMs * 2, 120_000);
      continue;
    }

    // 504 (and other gateway timeouts) mean FEC could not compute this query in
    // time — the query is too large. Signal the caller to subdivide by date rather
    // than treating it as a hard failure.
    if (response.status === 504 || response.status === 502 || response.status === 503) {
      throw new FecQueryTooLargeError(`FEC gateway timeout (HTTP ${response.status}) — query too large`);
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
 *
 * FEC-04: a prior `is_amended === true` branch here was dead code — 174-RESEARCH-amendments.md
 * confirmed `is_amended` is not a field on the live ScheduleA response schema (only
 * `amendment_indicator`/`amendment_indicator_desc`/`original_sub_id` exist), so the check never
 * fired. Real amendment-supersession handling is now `original_sub_id` retirement in
 * normalizeRecords/upsertContributions below, not a skip at normalize time — the amended row
 * itself must still be inserted; only the row it supersedes gets retired.
 */
function shouldSkipRecord(record: Record<string, unknown>): boolean {
  if (record['memo_code'] === 'X') return true;
  return false;
}

/**
 * normalizeRecords converts raw FEC Schedule A records into ContributionInsert structs.
 * Memo items are counted in NormalizeResult.skipped and excluded from the contributions slice.
 *
 * FEC-04: every record's non-null `original_sub_id` is collected into
 * NormalizeResult.supersededSubIds — the OLD sub_id an amended row replaces. The amended row
 * itself is still normalized and inserted normally (its own, different, sub_id); the row it
 * supersedes is retired separately in upsertContributions.
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
  const supersededSubIds: string[] = [];
  // FEC-04b: highest file_number per (committee, report_year, report_type) in this batch.
  const filingMax = new Map<string, SupersededFiling>();

  for (const record of records) {
    // FEC-04b: track the newest filing per report, regardless of skip status — a superseded
    // filing must be retired even if the row that revealed it is a memo item.
    const cid = record['committee_id'];
    const ry = record['report_year'];
    const rt = record['report_type'];
    const fn = record['file_number'];
    if (
      typeof cid === 'string' && cid !== '' &&
      typeof ry === 'number' && Number.isFinite(ry) &&
      typeof rt === 'string' && rt !== '' &&
      typeof fn === 'number' && Number.isFinite(fn)
    ) {
      const key = `${cid}|${ry}|${rt}`;
      const prev = filingMax.get(key);
      if (!prev || fn > prev.maxFileNumber) {
        filingMax.set(key, {
          politicianSourceId: ps.id,
          committeeId: cid,
          reportYear: ry,
          reportType: rt,
          maxFileNumber: fn,
        });
      }
    }

    // Collect original_sub_id for every record in the batch regardless of skip status —
    // a superseded row must be retired even if the amended row that supersedes it is
    // itself a memo item (skipped from insert). The retirement DELETE is independently
    // scoped/guarded (data_source='fec', source_transaction_id = original_sub_id) so this
    // is safe to collect unconditionally.
    if (typeof record['original_sub_id'] === 'string' && record['original_sub_id'] !== '') {
      supersededSubIds.push(record['original_sub_id'] as string);
    }

    if (shouldSkipRecord(record)) {
      skipped++;
      continue;
    }

    const contribution = normalizeRecord(record, ps);
    contributions.push(contribution);
  }

  return {
    contributions,
    skipped,
    totalParsed,
    ...(supersededSubIds.length > 0 ? { supersededSubIds } : {}),
    ...(filingMax.size > 0 ? { supersededFilings: [...filingMax.values()] } : {}),
  };
}

// Only these FEC Schedule A fields are ever read back (by campaignFinanceService
// and essentialsProfileService for donor name/type/employer/occupation/city/state
// and sector classification) or needed for audit/traceability. The full FEC record
// has ~50 fields; storing just these cuts per-row JSONB size by ~75%. Add a field
// here if a new query starts reading it. See audit in quick-029.
const FEC_KEPT_FIELDS = [
  // read by donor/sector/breakdown queries
  'contributor_name', 'type', 'entity_type',
  'contributor_occupation', 'contributor_employer',
  'contributor_city', 'contributor_state',
  // identity / audit / re-normalization inputs
  'sub_id', 'committee_id',
  'contribution_receipt_amount', 'contribution_receipt_date',
  'two_year_transaction_period', 'memo_code',
  // FEC-04: original_sub_id drives supersession-retirement (see normalizeRecords /
  // upsertContributions) and is worth retaining on the amended row for audit/traceability.
  'original_sub_id',
  // FEC-04b: filing-level supersession. An amendment re-reports a whole report period under a
  // new file_number, so (committee_id, report_year, report_type) + file_number is what lets us
  // retire the superseded version. `load_date` and `transaction_id` are audit aids only —
  // transaction_id is deliberately NOT used as a dedup key because it is not stable across
  // amendments (verified: same contribution carried 'VSHCSM0N319' then '2208859').
  'file_number', 'report_year', 'report_type', 'load_date', 'transaction_id',
  // quick-260729-0jn (EXPL-A1/EXPL-A3): kept so API-ingested rows carry the same
  // amendment/election fields the bulk path (fecBulkLoader.ts mapBulkRow) now retains.
  // Forward-only — no re-ingest, no backfill, no behavioural change to any existing query.
  'amendment_indicator', 'election_type',
] as const;

/** Keep only the fields we read or need for audit — see FEC_KEPT_FIELDS. */
function slimFecRecord(record: Record<string, unknown>): Record<string, unknown> {
  const slim: Record<string, unknown> = {};
  for (const k of FEC_KEPT_FIELDS) {
    if (record[k] !== undefined) slim[k] = record[k];
  }
  return slim;
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
    raw_record: slimFecRecord(record),
    donor_name_normalized: normalizeDonorName(
      typeof record['contributor_name'] === 'string' ? record['contributor_name'] as string : null
    ),
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
export async function upsertContributions(
  normalized: NormalizeResult
): Promise<UpsertResult> {
  const supersededSubIds = normalized.supersededSubIds ?? [];

  if (normalized.contributions.length === 0 && supersededSubIds.length === 0) {
    return { inserted: 0, skipped: 0, unresolved: 0, errors: 0 };
  }

  let inserted = 0;
  let skipped = 0;
  let errors = 0;

  // Process in batches of 100
  const batchSize = 100;
  for (let i = 0; i < normalized.contributions.length; i += batchSize) {
    const batch = normalized.contributions.slice(i, i + batchSize);

    // Retry on transient connection errors (Supabase pooler drops connections under
    // sustained bulk-write load — quick-031). The pg pool hands out a fresh connection
    // per attempt, so a retry recovers instead of silently dropping the batch.
    let attempt = 0;
    for (;;) {
      try {
        const { batchInserted, batchSkipped } = await upsertBatch(batch);
        inserted += batchInserted;
        skipped += batchSkipped;
        break;
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        const transient = /connection terminated|connection timeout|ECONNRESET|terminated unexpectedly|Client has encountered a connection error|too many clients/i.test(msg);
        if (transient && attempt < 5) {
          attempt++;
          const delay = Math.min(1000 * 2 ** (attempt - 1), 30_000);
          console.warn(`[fecAdapter] upsert batch at offset ${i} transient error (attempt ${attempt}/5) — retrying in ${delay}ms: ${msg}`);
          await sleep(delay);
          continue;
        }
        // Non-transient, or retries exhausted: count as errors and move on.
        errors += batch.length;
        console.error(`[fecAdapter] upsert batch error at offset ${i} (after ${attempt} retr${attempt === 1 ? 'y' : 'ies'}):`, err);
        break;
      }
    }
  }

  // FEC-04: retire rows superseded by an amendment. Runs AFTER the inserts above so the
  // freshly-inserted amended row (its own, different, sub_id) is already committed before
  // its predecessor is retired — order doesn't affect correctness here (the DELETE can never
  // match the new row, only the OLD sub_id it replaces), but inserting first means a crash
  // between insert and retire leaves the old row present (safe, re-run catches it) rather
  // than leaving a gap with neither row present.
  if (supersededSubIds.length > 0) {
    try {
      await retireSupersededRows(supersededSubIds);
    } catch (err) {
      console.error(`[fecAdapter] supersession retirement failed for ${supersededSubIds.length} original_sub_id(s):`, err);
      errors += supersededSubIds.length;
    }
  }

  // FEC-04b: retire EARLIER filings of any report present in this batch. This is the path that
  // actually fires — original_sub_id is null on the live API, so retireSupersededRows above is
  // inert in practice (kept in case FEC starts populating it). Runs after the inserts for the
  // same reason: a crash between insert and retire leaves a duplicate (safe, next run fixes it)
  // rather than a gap with neither version present.
  const filings = normalized.supersededFilings ?? [];
  if (filings.length > 0) {
    try {
      const retired = await retireSupersededFilings(filings);
      if (retired > 0) {
        console.log(`[fecAdapter] retired ${retired} row(s) from superseded filings across ${filings.length} report(s)`);
      }
    } catch (err) {
      console.error(`[fecAdapter] filing-supersession retirement failed for ${filings.length} report(s):`, err);
      errors += filings.length;
    }
  }

  return { inserted, skipped, unresolved: 0, errors };
}

/**
 * retireSupersededFilings deletes contributions belonging to EARLIER versions of a report that
 * the incoming batch has re-reported under a higher file_number.
 *
 * Why this exists (FEC-04b): FEC-04's `original_sub_id` retirement never fires — that field is
 * null on every live Schedule A row observed across three sampling sessions. Meanwhile the
 * double-count it was meant to prevent is REAL and was reproduced in prod: committee C00256925,
 * report 12P/2020, the same $250 2020-05-07 contribution stored twice — once from file 1409022
 * (loaded 2020-05-30) and again from file 1484476 (loaded 2020-12-30), because the amendment
 * re-reported the period with fresh sub_ids and `ON CONFLICT (source_transaction_id)` saw new keys.
 *
 * Why (committee, report_year, report_type) + file_number and nothing else:
 *   - `original_sub_id` — always null. Unusable.
 *   - `transaction_id` — NOT stable across amendments (the same contribution above carried
 *     'VSHCSM0N319' in the original and '2208859' in the amendment, because the filer changed
 *     filing software). Deduping on it would silently fail to merge.
 *   - (contributor, amount, date) alone — WRONG: FEC legitimately reports repeated identical
 *     lines in one filing (e.g. five $1.00 recurring donations from one donor on one day,
 *     carrying consecutive sub_ids). Collapsing those would destroy real data.
 *
 * ⚠ CORRECTED 2026-07-25 — retirement is PER LINE, not per whole report.
 * ------------------------------------------------------------------------------------------
 * The original FEC-04b rule ("delete every row of the report below the report's highest
 * file_number") assumed an amendment RE-REPORTS THE WHOLE REPORT, so that the surviving filing
 * is a superset of the one it supersedes. Measured against live data, that assumption is FALSE:
 * across 24 superseded filings sampled, ZERO were supersets. Many FEC amendments are DELTA
 * filings carrying only the changed lines. The starkest case — committee C00574889, report
 * Q1/2016, contribution date 2016-03-11 — has 114 lines in the original filing 1066886 and just
 * 2 in the amendment 1081569. The whole-report rule would have deleted all 114 and kept 2.
 *
 * So supersession is decided per CONTRIBUTION LINE: a row is retired only when the SAME line
 * (donor, amount, date) is also present in that report under a HIGHER file_number. That is
 * exactly what the double-count is — one line carried by two filings of one report — and it
 * leaves untouched any line that only the earlier filing reports.
 *
 * Why this handles the cases the whole-report rule got wrong or right by luck:
 *   - C00256925 12P/2020 (the real double-count): Chamblee's $250 2020-05-07 appears in BOTH
 *     1409022 and 1484476 → the 1409022 copy is retired. Still fixed.
 *   - C00574889 Q1/2016: PARKER's $50 appears ONLY in 1066886 → nothing retired. No longer
 *     destroys 114 real contributions.
 *   - FEC's legitimate repeated identical lines within ONE filing (five $1.00 recurring
 *     donations on one day, consecutive sub_ids) all share that filing's file_number, so none is
 *     ever the "higher" version of another → never collapsed.
 *   - The same contribution legitimately reported in DIFFERENT reports (C00575209's $2,800 in
 *     both Q1/2020 and Q3/2020) is never touched: the match is scoped within one
 *     (report_year, report_type).
 *
 * Safety properties:
 *   - Scoped to `politician_source_id` FIRST so the DELETE rides idx_contrib_src_cycle. An
 *     unscoped predicate over JSONB paths would seq-scan 26.9M rows — the exact shape of the
 *     2026-07-22 P1 pool-saturation incident.
 *   - `data_source = 'fec'` — never touches another source.
 *   - Both sides require `raw_record ? 'file_number'`: rows ingested before FEC-04b have none, so
 *     they are neither deleted nor used as evidence. Deliberate — for those we cannot tell which
 *     version a row is. They need the separate backfill
 *     (scripts/backfill-fec-file-numbers.ts; see the todo in .planning/todos/).
 *   - A strictly-greater-than file_number must EXIST for a row to be deleted, so the newest
 *     version of any line is always kept and the rows just inserted can never be removed.
 */
async function retireSupersededFilings(filings: SupersededFiling[]): Promise<number> {
  let deleted = 0;
  for (const f of filings) {
    // Per-line supersession via a window MAX, not a self-join. A self-join on these predicates
    // plans as a nested loop with the JSONB extraction in the join filter — both sides index-scan
    // politician_source_id and every pair is compared, so cost is quadratic in the source's row
    // count and it does not complete (measured: >10 min on one committee of one source). The
    // window form is a single pass plus a sort over the same rows.
    const res = await pool.query(
      `WITH slice AS (
         SELECT id, amount, contribution_date, donor_name_normalized,
                (raw_record->>'file_number')::bigint AS fn
           FROM transparent_motivations.contributions
          WHERE politician_source_id = $1
            AND data_source = 'fec'
            AND raw_record ? 'file_number'
            AND raw_record->>'committee_id' = $2
            AND (raw_record->>'report_year')::int = $3
            AND raw_record->>'report_type' = $4
       ), ranked AS (
         SELECT id, fn,
                max(fn) OVER (
                  PARTITION BY donor_name_normalized, amount, contribution_date
                ) AS survivor_fn
           FROM slice
       )
       DELETE FROM transparent_motivations.contributions t
        USING ranked r
        WHERE t.id = r.id
          AND r.fn < r.survivor_fn
          AND r.fn < $5`,
      [f.politicianSourceId, f.committeeId, f.reportYear, f.reportType, f.maxFileNumber]
    );
    deleted += res.rowCount ?? 0;
  }
  return deleted;
}

/**
 * retireSupersededRows deletes contributions rows that an incoming amended Schedule A row's
 * original_sub_id points at — i.e. the OLD transaction the amendment replaces.
 *
 * FEC-04 (Task 1 checkpoint, 174-FEC04-LIVE-CONFIRM.md): the retirement is gated behind
 * schema-level evidence (operator-authorized "proceed") since a live row with a populated
 * original_sub_id was not caught in two sampling sessions; the delete's blast radius is bounded
 * regardless — it can only ever match a row whose source_transaction_id literally equals a
 * value an amended row carries as its OWN original_sub_id, scoped to data_source='fec'. It can
 * never delete the newly-inserted amended row itself (that row's own sub_id differs from
 * original_sub_id by construction — an amendment's new sub_id is never equal to the id it
 * replaces) or touch any other data_source.
 *
 * No `deleted_at` column exists on transparent_motivations.contributions (confirmed via
 * migrations grep) — hard DELETE matches the table's existing convention. If a soft-delete
 * column is added to this table in the future, switch this to `SET deleted_at = NOW()`.
 */
async function retireSupersededRows(originalSubIds: string[]): Promise<void> {
  // Only ever deletes rows where BOTH conditions hold: data_source='fec' AND
  // source_transaction_id = ANY($1) — $1 is exactly the set of OLD sub_ids the incoming
  // batch's amended rows carry as original_sub_id. Parameterized; never interpolated.
  await pool.query(
    `DELETE FROM transparent_motivations.contributions
     WHERE data_source = 'fec' AND source_transaction_id = ANY($1::text[])`,
    [originalSubIds]
  );
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
  //            confidence_level, data_source, source_transaction_id, raw_record,
  //            donor_name_normalized)
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
 * FECAdapter implements SourceAdapter + StreamingAdapter for the FEC Schedule A API.
 * Cycle must be set before calling fetch — use createFecAdapter(cycle) to construct.
 *
 * runIngestion drives the streaming path (fetchStream) so mega-committee pulls persist
 * incrementally per page/window and survive mid-pair restarts. The buffered fetch() is
 * retained for interface compliance / any legacy caller and delegates to the same core.
 */
class FECAdapter implements SourceAdapter, StreamingAdapter {
  private readonly cycle: string;

  constructor(cycle: string) {
    this.cycle = cycle;
  }

  name(): string {
    return 'fec';
  }

  async fetch(ps: PoliticianSource): Promise<FetchResult> {
    // Buffered path: collect every streamed batch into one array. Not the hot path
    // (runIngestion uses fetchStream) but keeps SourceAdapter.fetch() correct.
    const records: Record<string, unknown>[] = [];
    const { totalExpected, totalFetched } = await streamAllPages(
      ps.external_id,
      this.cycle,
      async (batch) => { records.push(...batch); },
      ps.id
    );
    return { records, totalExpected, totalFetched };
  }

  async fetchStream(ps: PoliticianSource, onBatch: BatchSink, signal?: AbortSignal): Promise<FetchResult> {
    const { totalExpected, totalFetched } = await streamAllPages(
      ps.external_id,
      this.cycle,
      onBatch,
      ps.id,
      signal
    );
    // Records were streamed to onBatch, not buffered — return an empty array with
    // accurate counters for runIngestion's completeness check.
    return { records: [], totalExpected, totalFetched };
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
