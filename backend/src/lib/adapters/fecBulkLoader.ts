/**
 * fecBulkLoader — load FEC itemized individual contributions from the free BULK data
 * downloads instead of the rate-limited API. quick-031.
 *
 * The API (60/min key) is the wrong tool for a 40M+ record historical backfill; FEC
 * publishes the entire itemized individual-contributions dataset as free per-cycle bulk
 * files (no key, no rate limit, no ToS gray area). This streams a cycle's `indiv{YY}.zip`,
 * keeps only rows for our confirmed candidates' committees, and upserts them through the
 * SAME dedup path as the API (ON CONFLICT (data_source, source_transaction_id) on SUB_ID),
 * so bulk + API rows never duplicate and the read path / agg are unchanged.
 *
 * Files (https://www.fec.gov/files/bulk-downloads/{CYCLE}/):
 *   indiv{YY}.zip  — itemized individual contributions (pipe-delimited, no header, 21 cols)
 *   ccl{YY}.zip    — candidate→committee linkage (map our candidates to their committees)
 *
 * CAVEAT (documented): the bulk file is not amendment-resolved the way the API is; an
 * amended transaction has a different SUB_ID than its original, so both can load → slight
 * itemized over-count on amended transactions. Headline total_raised is unaffected (it uses
 * authoritative FEC receipts).
 *
 * quick-260729-0jn: the amendment columns (file_number/report_type/amendment_indicator/
 * transaction_id) and election_type are now retained in raw_record (see mapBulkRow) — the
 * precondition for Phase A1 amendment reconciliation. This change is FORWARD-LOOKING ONLY:
 * rows already in production predate it and still need `scripts/backfill-fec-file-numbers.ts`
 * or an A1 re-ingest to gain these fields. No re-ingest is triggered by this change.
 *
 * 2026-09-25: run rows are stamped with the indiv file's Last-Modified, not now() (see
 * bulkRunWatermark — now() skipped every contribution FEC loaded after the file was
 * built), and `newOnly` limits a load to first-time backfills (see newFecSourceIds).
 */

import { Readable } from 'node:stream';
import readline from 'node:readline';
import unzipper from 'unzipper';
import { pool } from '../db.js';
import { upsertContributions } from './fecAdapter.js';
import { normalizeDonorName } from './normalizeDonorName.js';
import { refreshSummaryAggForSource, getConfirmedFecSources } from '../campaignFinanceService.js';
import { cache } from '../cache.js';
import type { ContributionInsert } from './adapterInterface.js';

export interface BulkLoadOptions {
  /** Parse + filter + count only; write nothing to the DB. */
  dry?: boolean;
  /** Restrict to these committee IDs (must still map to a confirmed candidate). For dry runs. */
  committees?: string[];
  /** Stop after this many matched rows. For bounded dry/test loads. */
  limit?: number;
  /** Print the first N raw lines of ccl + indiv (column-position verification), then continue. */
  sample?: number;
  /** 'P' = principal committees only (matches API coverage; default). 'all' = all authorized. */
  designation?: 'P' | 'all';
  /**
   * Load only sources with NO successful FEC run for this cycle yet — the first-time
   * backfills the rate-limited API walks at ~45s each. Leaves every source the daily
   * burst already keeps current alone: no rows, no agg refresh, no run row.
   */
  newOnly?: boolean;
}

const BULK_BASE = 'https://www.fec.gov/files/bulk-downloads';

// indiv column indexes (0-based) per the FEC data dictionary.
const I_CMTE = 0, I_ENTITY = 6, I_NAME = 7, I_CITY = 8, I_STATE = 9,
      I_EMPLOYER = 11, I_OCC = 12, I_DATE = 13, I_AMT = 14, I_MEMO = 18, I_SUB = 20;
// quick-260729-0jn (EXPL-A1/EXPL-A3): amendment + election-designation columns.
const I_AMNDT = 1, I_RPT_TP = 2, I_PGI = 3, I_TRAN_ID = 16, I_FILE_NUM = 17;
// ccl column indexes: CAND_ID | CAND_ELECTION_YR | FEC_ELECTION_YR | CMTE_ID | CMTE_TP | CMTE_DSGN | LINKAGE_ID
const C_CAND = 0, C_CMTE = 3, C_DSGN = 5;

/**
 * Open a remote FEC bulk .zip: its Last-Modified header, plus its lines already split on
 * '|'. Constant memory. The header is read from the FINAL response — fec.gov 302s to S3,
 * and fetch follows the redirect, so this is the file's own date, not the redirect's.
 */
async function openZipLines(url: string): Promise<{ lastModified: string | null; lines: AsyncGenerator<string[]> }> {
  const res = await fetch(url);
  if (!res.ok || !res.body) throw new Error(`bulk download failed: HTTP ${res.status} for ${url}`);
  const body = res.body;
  async function* lines(): AsyncGenerator<string[]> {
    const nodeStream = Readable.fromWeb(body as Parameters<typeof Readable.fromWeb>[0]);
    const entry = nodeStream.pipe(unzipper.ParseOne());
    const rl = readline.createInterface({ input: entry, crlfDelay: Infinity });
    for await (const line of rl) {
      if (line) yield line.split('|');
    }
  }
  return { lastModified: res.headers.get('last-modified'), lines: lines() };
}

/** Stream a remote FEC bulk .zip and yield each line already split on '|'. Constant memory. */
async function* streamZipLines(url: string): AsyncGenerator<string[]> {
  yield* (await openZipLines(url)).lines;
}

/**
 * bulkRunWatermark — the started_at a bulk load may claim for its `fec` run rows.
 *
 * 🔴 NOT now(). The API adapter resumes each pair from max(started_at) of its successful
 * runs, minus a 2-day lookback (getFecLoadCursor). A bulk file is only as current as the
 * day FEC built it — `indiv26.zip` was 5 days old on 2026-09-25 — so stamping now() moves
 * the cursor past every contribution FEC loaded between the file's build and the load.
 * The next API run then starts after them and they are never fetched. Nothing errors.
 *
 * Returns the file's Last-Modified (never later than `now`), or null when the header is
 * missing or unparseable. Null means "write no run rows": the pair then keeps its old
 * cursor (or none), the API re-reads the window, and SUB_ID dedup absorbs the overlap.
 * Re-reading costs rate limit; skipping costs data. Pay the rate limit.
 */
export function bulkRunWatermark(lastModified: string | null, now: Date = new Date()): Date | null {
  if (!lastModified) return null;
  const t = Date.parse(lastModified);
  if (isNaN(t)) return null;
  return new Date(Math.min(t, now.getTime()));
}

/**
 * newFecSourceIds — confirmed FEC sources with no successful `fec` run for this cycle.
 *
 * Per cycle on purpose: the API cursor is per (source, cycle), so a source current for
 * 2024 but never loaded for 2026 is still a whole-cycle backfill for 2026.
 */
export async function newFecSourceIds(cycle: string): Promise<Set<string>> {
  const r = await pool.query<{ id: string }>(
    `SELECT ps.id
       FROM transparent_motivations.politician_sources ps
      WHERE ps.source_system IN ('fec', 'fec_house', 'fec_senate')
        AND ps.research_status = 'confirmed'
        AND NOT EXISTS (
              SELECT 1
                FROM transparent_motivations.ingestion_runs r
               WHERE r.politician_source_id = ps.id
                 AND r.adapter_name = 'fec'
                 AND r.election_cycle = $1
                 AND r.status IN ('completed', 'completed_with_warning')
            )`,
    [cycle]
  );
  return new Set(r.rows.map((row) => row.id));
}

/** FEC bulk date is MMDDYYYY. */
function parseFecBulkDate(s: string | undefined): Date | null {
  if (!s || s.length !== 8) return null;
  const d = new Date(`${s.slice(4, 8)}-${s.slice(0, 2)}-${s.slice(2, 4)}T00:00:00Z`);
  return isNaN(d.getTime()) ? null : d;
}

/** Map one indiv bulk row into the same slim shape the API path stores. */
export function mapBulkRow(c: string[], sourceId: string, cycle: string): ContributionInsert {
  const amount = parseFloat(c[I_AMT] ?? '') || 0;
  const name = c[I_NAME] ?? '';
  const date = parseFecBulkDate(c[I_DATE]);
  return {
    politician_source_id: sourceId,
    donor_id: null,
    committee_id: null,
    amount,
    contribution_date: date,
    election_cycle: cycle,
    confidence_level: 'HIGH',
    data_source: 'fec', // MUST be 'fec' so SUB_ID dedups against API-ingested rows
    source_transaction_id: c[I_SUB] ?? '',
    raw_record: {
      contributor_name: name,
      entity_type: c[I_ENTITY] ?? '',
      contributor_occupation: c[I_OCC] ?? '',
      contributor_employer: c[I_EMPLOYER] ?? '',
      contributor_city: c[I_CITY] ?? '',
      contributor_state: c[I_STATE] ?? '',
      sub_id: c[I_SUB] ?? '',
      committee_id: c[I_CMTE] ?? '',
      contribution_receipt_amount: amount,
      contribution_receipt_date: date ? date.toISOString().slice(0, 10) : '',
      two_year_transaction_period: Number(cycle),
      memo_code: c[I_MEMO] ?? '',
      // quick-260729-0jn (EXPL-A1): retained so amendment reconciliation doesn't have to
      // re-derive these from scratch. Deliberately NO report_year key here — see below.
      file_number: c[I_FILE_NUM] ?? '',
      report_type: c[I_RPT_TP] ?? '',
      amendment_indicator: c[I_AMNDT] ?? '',
      transaction_id: c[I_TRAN_ID] ?? '',
      // quick-260729-0jn (EXPL-A3): raw TRANSACTION_PGI value (e.g. "P2022" — combined
      // designation+year form). The API's `election_type` field may use a different
      // form; nothing reads this key yet — Task 3 of quick-260729-0jn records both
      // observed formats so a later per-election limit engine (A3) normalizes rather
      // than assumes they match.
      election_type: c[I_PGI] ?? '',
      // Deliberately absent: report_year. The bulk `indiv` file has no report-year
      // column, so it is not synthesized here. `retireSupersededFilings` in
      // fecAdapter.ts slices on (committee_id, report_year, report_type) + file_number;
      // a guessed report_year would let bulk rows be matched — and therefore DELETED —
      // by that per-line supersession rule on a fabricated key. Leaving it absent keeps
      // bulk rows inert with respect to per-line retirement, exactly as today. A1 must
      // source the real value from the filing header (FEC `/filings/?file_number=`),
      // never invent it. See fecBulkLoader.test.ts for the regression guard.
    },
    donor_name_normalized: normalizeDonorName(name),
  };
}

/** Build CMTE_ID -> politician_source_id from ccl, restricted to our confirmed candidates. */
async function buildCommitteeMap(cycle: string, yy: string, opts: BulkLoadOptions): Promise<Map<string, string>> {
  let sources = await getConfirmedFecSources();
  if (opts.newOnly) {
    const fresh = await newFecSourceIds(cycle);
    sources = sources.filter((s) => fresh.has(s.id));
    console.log(`[bulk] --new-only: ${sources.length} source(s) with no successful ${cycle} FEC run`);
  }
  const candToSource = new Map<string, string>();
  for (const s of sources) if (s.external_id) candToSource.set(s.external_id, s.id);

  const cmteToSource = new Map<string, string>();
  let cclRows = 0, sampled = 0;
  for await (const c of streamZipLines(`${BULK_BASE}/${cycle}/ccl${yy}.zip`)) {
    cclRows++;
    if (opts.sample && sampled < opts.sample) { console.log('[bulk][ccl sample]', c.join('|')); sampled++; }
    const sourceId = candToSource.get(c[C_CAND] ?? '');
    if (!sourceId) continue;
    if (opts.designation !== 'all' && c[C_DSGN] !== 'P') continue;
    if (c[C_CMTE]) cmteToSource.set(c[C_CMTE], sourceId);
  }
  console.log(`[bulk] ccl${yy}: ${cclRows.toLocaleString()} rows → ${cmteToSource.size} committees for ${new Set(cmteToSource.values()).size} of our sources (designation=${opts.designation ?? 'P'})`);
  return cmteToSource;
}

/** Cache TTL for the CAND_ID -> committee[] map — committee linkages are near-static
 *  within a cycle, so a week-old map is still correct almost all of the time. */
const CAND_CMTE_MAP_TTL_SECONDS = 60 * 60 * 24 * 7;

/**
 * buildCandidateCommitteeMap builds CAND_ID -> principal (DSGN='P') committee IDs from the
 * free bulk ccl{YY}.zip linkage file (FEC-01) — resolving committees without a rate-limited
 * FEC candidates-search API call. Cached via cache.ts for 7 days per cycle; a cache hit
 * returns without re-streaming. An empty map is NEVER cached (Pitfall 3 — a newly-filing
 * candidate absent from the bulk map must be re-checked next run, not suppressed for the TTL).
 */
export async function buildCandidateCommitteeMap(cycle: string): Promise<Map<string, string[]>> {
  const cacheKey = `fec:ccl-cmte-map:${cycle}`;
  const cached = await cache.get<[string, string[]][]>(cacheKey);
  if (cached) {
    return new Map(cached);
  }

  const yy = cycle.slice(-2);
  const map = new Map<string, string[]>();
  for await (const c of streamZipLines(`${BULK_BASE}/${cycle}/ccl${yy}.zip`)) {
    const candId = c[C_CAND];
    const cmteId = c[C_CMTE];
    if (!candId || !cmteId) continue;
    if (c[C_DSGN] !== 'P') continue;
    const existing = map.get(candId);
    if (existing) existing.push(cmteId);
    else map.set(candId, [cmteId]);
  }

  // Never cache an empty map — a bulk-fetch/parse hiccup must not suppress every
  // candidate's committee lookup for the full 7-day TTL (Pitfall 3).
  if (map.size > 0) {
    await cache.set(cacheKey, [...map.entries()], CAND_CMTE_MAP_TTL_SECONDS);
  }

  return map;
}

/** After a real load, record a `fec` ingestion_run per touched pair so the truncation
 *  audit (getTruncatedPairs) reflects the new coverage. Expected = largest expected ever
 *  seen for the pair (from prior run notes); stored = current row count. */
async function finalizePair(sourceId: string, cycle: string, watermark: Date): Promise<void> {
  const storedRes = await pool.query<{ n: string }>(
    `SELECT count(*) n FROM transparent_motivations.contributions
     WHERE data_source='fec' AND politician_source_id=$1 AND election_cycle=$2`,
    [sourceId, cycle]
  );
  const stored = Number(storedRes.rows[0]?.n ?? 0);
  const expRes = await pool.query<{ exp: string | null }>(
    `SELECT max((regexp_match(notes,'expected ([0-9]+)'))[1]::bigint)::text AS exp
     FROM transparent_motivations.ingestion_runs
     WHERE adapter_name='fec' AND politician_source_id=$1 AND election_cycle=$2 AND notes ~ 'expected [0-9]+'`,
    [sourceId, cycle]
  );
  const expected = expRes.rows[0]?.exp ? Number(expRes.rows[0].exp) : stored;
  const pct = expected > 0 ? Math.round((stored / expected) * 100) : 100;
  const status = stored >= expected * 0.95 ? 'completed' : 'completed_with_warning';
  await pool.query(
    `INSERT INTO transparent_motivations.ingestion_runs
       (adapter_name, politician_source_id, election_cycle, started_at, completed_at, status, records_fetched, records_inserted, notes)
     VALUES ('fec', $1, $2, $6, now(), $3, $4, $4, $5)`,
    [sourceId, cycle, status, stored,
     `fetched ${stored} of expected ${expected} (${pct}%) [bulk indiv as of ${watermark.toISOString().slice(0, 10)}]`,
     watermark]
  );
}

/** Load one cycle's itemized individual contributions from FEC bulk data. */
export async function loadFecBulkCycle(cycle: string, opts: BulkLoadOptions = {}): Promise<void> {
  const yy = cycle.slice(-2);
  console.log(`[bulk] === FEC bulk load cycle ${cycle} (dry=${!!opts.dry}${opts.limit ? `, limit=${opts.limit}` : ''}${opts.committees ? `, committees=${opts.committees.join(',')}` : ''}) ===`);

  const cmteMap = await buildCommitteeMap(cycle, yy, opts);
  let allow = cmteMap;
  if (opts.committees?.length) {
    allow = new Map();
    for (const cm of opts.committees) if (cmteMap.has(cm)) allow.set(cm, cmteMap.get(cm)!);
    console.log(`[bulk] restricted to ${allow.size} committee(s): ${[...allow.keys()].join(',') || '(none matched — check they are principal committees of confirmed candidates)'}`);
  }
  if (allow.size === 0) { console.error('[bulk] no committees to load — aborting'); return; }

  const touched = new Set<string>();
  let scanned = 0, matched = 0, written = 0, skippedMemo = 0, sampled = 0;
  let batch: ContributionInsert[] = [];
  const flush = async () => {
    if (!batch.length) return;
    if (!opts.dry) {
      const r = await upsertContributions({ contributions: batch, skipped: 0, totalParsed: batch.length });
      written += r.inserted;
    }
    batch = [];
  };

  const indiv = await openZipLines(`${BULK_BASE}/${cycle}/indiv${yy}.zip`);
  const watermark = bulkRunWatermark(indiv.lastModified);
  console.log(`[bulk] indiv${yy}.zip Last-Modified: ${indiv.lastModified ?? '(missing)'}`);
  for await (const c of indiv.lines) {
    scanned++;
    if (opts.sample && sampled < opts.sample) { console.log('[bulk][indiv sample]', c.slice(0, 21).join('|')); sampled++; }
    if (scanned % 2_000_000 === 0) console.log(`[bulk] scanned ${scanned.toLocaleString()}, matched ${matched.toLocaleString()}...`);

    const sourceId = allow.get(c[I_CMTE] ?? '');
    if (!sourceId) continue;
    if (c[I_MEMO] === 'X') { skippedMemo++; continue; }
    if (!c[I_SUB]) continue;
    matched++;
    touched.add(sourceId);
    batch.push(mapBulkRow(c, sourceId, cycle));
    if (batch.length >= 500) await flush();
    if (opts.limit && matched >= opts.limit) { console.log(`[bulk] reached --limit ${opts.limit}`); break; }
  }
  await flush();

  console.log(`[bulk] cycle ${cycle}: scanned=${scanned.toLocaleString()} matched=${matched.toLocaleString()} written=${written.toLocaleString()} memoSkipped=${skippedMemo} sources=${touched.size}`);

  if (!opts.dry && touched.size > 0) {
    if (!watermark) {
      console.warn(
        `[bulk] 🔴 indiv${yy}.zip has no usable Last-Modified — writing NO run rows. ` +
        `The API will re-read these pairs' whole window (SUB_ID dedup absorbs the overlap).`
      );
    }
    for (const sid of touched) {
      try {
        await refreshSummaryAggForSource(sid);
        if (watermark) await finalizePair(sid, cycle, watermark);
      } catch (e) { console.warn(`[bulk] finalize failed for ${sid}: ${e instanceof Error ? e.message : String(e)}`); }
    }
    console.log(`[bulk] refreshed agg for ${touched.size} source(s); run rows ${watermark ? `stamped ${watermark.toISOString()}` : 'NOT written'}.`);
  }
}
