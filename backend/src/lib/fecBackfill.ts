/**
 * fecBackfill — server-side historical FEC Schedule A backfill.
 *
 * Runs on the Render backend as the SOLE FEC consumer while active: it holds the
 * shared FEC_LOCK_KEY (with a heartbeat, since the run outlives LOCK_TTL_SECONDS)
 * so the 6h scheduled cron skips its ticks and the two never contend for the
 * shared 1,000 req/hr FEC key.
 *
 * Two steps:
 *   1. populateFecCandidateCycles() — cache each confirmed candidate's active
 *      two-year cycles (one API call per uncached candidate) so the backfill only
 *      ingests cycles a candidate actually filed in.
 *   2. runFecHistoricalBackfill(floor) — iterate pending (source, cycle) pairs from
 *      the current cycle back to `floor`, ingesting each via runIngestion.
 *
 * Resumable: a (source, cycle) pair is skipped once it has a completed ingestion_run,
 * so a restart (deploy, crash) continues where it left off. Order: most-recent cycle
 * first, pilot states (CA, IN) first within a cycle.
 */

import { pool } from './db.js';
import { runIngestion } from './adapters/runIngestion.js';
import { createFecAdapter } from './adapters/fecAdapter.js';
import {
  currentFecCycle,
  acquireLock,
  releaseLock,
  renewLock,
  FEC_LOCK_KEY,
} from './campaignFinanceScheduler.js';
import type { PoliticianSource } from './campaignFinanceService.js';

const PILOT_STATES = ['CA', 'IN'];
const DEFAULT_FLOOR = 1980;
const SLEEP_BETWEEN_PAIRS_MS = parseInt(process.env.FEC_SLEEP_BETWEEN_PAIRS_MS ?? '6000', 10);
const CYCLE_FETCH_SLEEP_MS = 1500;
// Short lock TTL with a fast heartbeat. The heartbeat renews well within the TTL
// during a live run (even a slow ~150s source run gets 3+ renewals), but if the
// process dies the orphaned lock expires in ≤BACKFILL_LOCK_TTL_S instead of the
// global 600s — so a crash-then-reboot resumes quickly instead of being blocked
// by its own dead lock for up to 10 minutes.
const BACKFILL_LOCK_TTL_S = 120;
const HEARTBEAT_MS = 45_000;

const sleep = (ms: number): Promise<void> => new Promise((r) => setTimeout(r, ms));

/** Round any year up to its even FEC cycle (odd -> +1). */
const toCycle = (y: number): number => (y % 2 !== 0 ? y + 1 : y);

// ---------------------------------------------------------------------------
// Step 1: candidate cycle cache
// ---------------------------------------------------------------------------

async function fetchCandidateCycles(candidateId: string, apiKey: string): Promise<number[]> {
  const url = `https://api.open.fec.gov/v1/candidates/?api_key=${apiKey}&candidate_id=${encodeURIComponent(candidateId)}&per_page=1`;
  let delay = 1000;
  for (let attempt = 0; attempt <= 3; attempt++) {
    const resp = await fetch(url, { signal: AbortSignal.timeout(30_000) });
    if (resp.status === 429) {
      if (attempt === 3) throw new Error('429 after retries');
      await sleep(delay);
      delay = Math.min(delay * 2, 60_000);
      continue;
    }
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    const data = (await resp.json()) as {
      results?: Array<{ cycles?: number[]; election_years?: number[] }>;
    };
    const c = data.results?.[0];
    const set = new Set<number>();
    for (const y of c?.cycles ?? []) set.add(toCycle(y));
    for (const y of c?.election_years ?? []) set.add(toCycle(y));
    return [...set].sort((a, b) => b - a);
  }
  return [];
}

/**
 * populateFecCandidateCycles caches active cycles for every confirmed FEC
 * candidate not already cached. Idempotent + resumable (cached IDs skipped).
 */
export async function populateFecCandidateCycles(): Promise<{ fetched: number; failed: number }> {
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) throw new Error('FEC_API_KEY is not set — cannot populate cycle cache');

  const pending = await pool.query<{ external_id: string }>(
    `SELECT DISTINCT ps.external_id
       FROM transparent_motivations.politician_sources ps
      WHERE ps.source_system LIKE 'fec%' AND ps.research_status='confirmed' AND ps.external_id <> ''
        AND NOT EXISTS (
          SELECT 1 FROM transparent_motivations.fec_candidate_cycles cc
          WHERE cc.external_id = ps.external_id
        )`
  );
  const ids = pending.rows.map((r) => r.external_id);
  console.log(`[fecBackfill] cycle cache: ${ids.length} uncached candidate(s)`);

  let fetched = 0;
  let failed = 0;
  for (let i = 0; i < ids.length; i++) {
    if (i > 0) await sleep(CYCLE_FETCH_SLEEP_MS);
    try {
      const cycles = await fetchCandidateCycles(ids[i]!, apiKey);
      await pool.query(
        `INSERT INTO transparent_motivations.fec_candidate_cycles (external_id, election_years, fetched_at)
         VALUES ($1, $2, now())
         ON CONFLICT (external_id) DO UPDATE SET election_years=EXCLUDED.election_years, fetched_at=now()`,
        [ids[i], cycles]
      );
      fetched++;
    } catch (err) {
      failed++;
      console.error(`[fecBackfill] cycle cache ✗ ${ids[i]}: ${err instanceof Error ? err.message : String(err)}`);
    }
  }
  console.log(`[fecBackfill] cycle cache done: fetched=${fetched} failed=${failed}`);
  return { fetched, failed };
}

// ---------------------------------------------------------------------------
// Step 1b: authoritative candidate totals cache (for correct total_raised)
// ---------------------------------------------------------------------------

interface FecTotalsRow {
  cycle: number;
  receipts: number | null;
  // Composition (quick-032) — for the grassroots/small-dollar breakdown bar. All authoritative
  // FEC summary figures; null when the candidate totals row omits them.
  individual_itemized: number | null;   // >$200 named individuals
  individual_unitemized: number | null; // ≤$200 grassroots (never named — see disclosure policy)
  pac_contributions: number | null;     // other_political_committee_contributions
  party_contributions: number | null;   // political_party_committee_contributions
  candidate_self: number | null;        // candidate_contribution (direct self-contribution)
  candidate_loans: number | null;       // loans_made_by_candidate (self-funders usually LOAN)
}

interface FecTotalsApiResult {
  cycle?: number;
  receipts?: number;
  individual_itemized_contributions?: number;
  individual_unitemized_contributions?: number;
  other_political_committee_contributions?: number;
  political_party_committee_contributions?: number;
  candidate_contribution?: number;
  loans_made_by_candidate?: number;
}

const numOrNull = (v: number | undefined): number | null => (typeof v === 'number' ? v : null);

/** Fetch all-cycle authoritative totals for one candidate in a single call. */
async function fetchCandidateTotals(candidateId: string, apiKey: string): Promise<FecTotalsRow[]> {
  const url = `https://api.open.fec.gov/v1/candidate/${encodeURIComponent(candidateId)}/totals/?api_key=${apiKey}&per_page=100`;
  let delay = 1000;
  for (let attempt = 0; attempt <= 3; attempt++) {
    const resp = await fetch(url, { signal: AbortSignal.timeout(30_000) });
    if (resp.status === 429) {
      if (attempt === 3) throw new Error('429 after retries');
      await sleep(delay);
      delay = Math.min(delay * 2, 60_000);
      continue;
    }
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    const data = (await resp.json()) as { results?: FecTotalsApiResult[] };
    return (data.results ?? [])
      .filter((r) => typeof r.cycle === 'number')
      .map((r) => ({
        cycle: r.cycle as number,
        receipts: r.receipts ?? null,
        individual_itemized: numOrNull(r.individual_itemized_contributions),
        individual_unitemized: numOrNull(r.individual_unitemized_contributions),
        pac_contributions: numOrNull(r.other_political_committee_contributions),
        party_contributions: numOrNull(r.political_party_committee_contributions),
        candidate_self: numOrNull(r.candidate_contribution),
        candidate_loans: numOrNull(r.loans_made_by_candidate),
      }));
  }
  return [];
}

/**
 * populateFecCandidateTotals caches FEC's authoritative per-cycle receipts for
 * every confirmed FEC candidate. One API call per candidate (all cycles at once).
 * Idempotent — upserts by (external_id, cycle). Creates the table if absent.
 */
export async function populateFecCandidateTotals(): Promise<{ candidates: number; rows: number; failed: number }> {
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) throw new Error('FEC_API_KEY is not set — cannot populate totals cache');

  await pool.query(`
    CREATE TABLE IF NOT EXISTS transparent_motivations.fec_candidate_totals (
      external_id text NOT NULL,
      cycle       text NOT NULL,
      receipts    numeric(16,2),
      fetched_at  timestamptz NOT NULL DEFAULT now(),
      PRIMARY KEY (external_id, cycle)
    )
  `);
  // Composition columns (quick-032) — additive, idempotent so re-running is safe on old rows.
  await pool.query(`
    ALTER TABLE transparent_motivations.fec_candidate_totals
      ADD COLUMN IF NOT EXISTS individual_itemized   numeric(16,2),
      ADD COLUMN IF NOT EXISTS individual_unitemized numeric(16,2),
      ADD COLUMN IF NOT EXISTS pac_contributions     numeric(16,2),
      ADD COLUMN IF NOT EXISTS party_contributions   numeric(16,2),
      ADD COLUMN IF NOT EXISTS candidate_self        numeric(16,2),
      ADD COLUMN IF NOT EXISTS candidate_loans       numeric(16,2)
  `);

  // Resumable: fetch candidates with NO cached rows, OR whose cached rows predate the newest
  // composition column (candidate_loans IS NULL on every row) — so a re-run backfills new fields.
  const idsResult = await pool.query<{ external_id: string }>(
    `SELECT DISTINCT ps.external_id
       FROM transparent_motivations.politician_sources ps
      WHERE ps.source_system LIKE 'fec%' AND ps.research_status='confirmed' AND ps.external_id <> ''
        AND NOT EXISTS (
          SELECT 1 FROM transparent_motivations.fec_candidate_totals t
          WHERE t.external_id = ps.external_id
            AND t.candidate_loans IS NOT NULL
        )`
  );
  const ids = idsResult.rows.map((r) => r.external_id);
  console.log(`[fecBackfill] totals cache: ${ids.length} uncached confirmed FEC candidate(s)`);

  let candidates = 0;
  let rows = 0;
  let failed = 0;
  for (let i = 0; i < ids.length; i++) {
    if (i > 0) await sleep(CYCLE_FETCH_SLEEP_MS);
    try {
      const totals = await fetchCandidateTotals(ids[i]!, apiKey);
      for (const t of totals) {
        await pool.query(
          `INSERT INTO transparent_motivations.fec_candidate_totals
             (external_id, cycle, receipts, individual_itemized, individual_unitemized,
              pac_contributions, party_contributions, candidate_self, candidate_loans, fetched_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, now())
           ON CONFLICT (external_id, cycle) DO UPDATE SET
             receipts=EXCLUDED.receipts,
             individual_itemized=EXCLUDED.individual_itemized,
             individual_unitemized=EXCLUDED.individual_unitemized,
             pac_contributions=EXCLUDED.pac_contributions,
             party_contributions=EXCLUDED.party_contributions,
             candidate_self=EXCLUDED.candidate_self,
             candidate_loans=EXCLUDED.candidate_loans,
             fetched_at=now()`,
          [ids[i], String(t.cycle), t.receipts, t.individual_itemized, t.individual_unitemized,
           t.pac_contributions, t.party_contributions, t.candidate_self, t.candidate_loans]
        );
        rows++;
      }
      candidates++;
    } catch (err) {
      failed++;
      console.error(`[fecBackfill] totals cache ✗ ${ids[i]}: ${err instanceof Error ? err.message : String(err)}`);
    }
  }
  console.log(`[fecBackfill] totals cache done: candidates=${candidates} rows=${rows} failed=${failed}`);
  return { candidates, rows, failed };
}

// ---------------------------------------------------------------------------
// Step 2: pending (source, cycle) pairs
// ---------------------------------------------------------------------------

interface WorkItem extends PoliticianSource {
  full_name: string;
  representing_state: string;
  cycle: string;
}

async function getPendingPairs(floor: number, current: number): Promise<WorkItem[]> {
  const r = await pool.query<WorkItem>(
    `WITH src AS (
       SELECT ps.id, ps.essentials_politician_id, ps.source_system, ps.external_id,
              ps.research_status, ps.notes, ps.created_at, ps.updated_at,
              p.full_name, o.representing_state, cc.election_years
       FROM transparent_motivations.politician_sources ps
       JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
       JOIN essentials.offices o ON o.politician_id = p.id
       LEFT JOIN transparent_motivations.fec_candidate_cycles cc ON cc.external_id = ps.external_id
       WHERE ps.source_system LIKE 'fec%' AND ps.research_status='confirmed' AND ps.external_id <> ''
       GROUP BY ps.id, p.full_name, o.representing_state, cc.election_years
     ),
     expanded AS (
       SELECT src.*, cyc AS cycle_int
       FROM src
       CROSS JOIN LATERAL unnest(
         CASE WHEN src.election_years IS NULL OR array_length(src.election_years,1) IS NULL
              THEN ARRAY[$2]::int[]
              ELSE src.election_years END
       ) AS cyc
       WHERE cyc BETWEEN $1 AND $2 AND cyc % 2 = 0
     )
     SELECT id, essentials_politician_id, source_system, external_id, research_status,
            notes, created_at, updated_at, full_name, representing_state,
            cycle_int::text AS cycle
     FROM expanded e
     WHERE NOT EXISTS (
       SELECT 1 FROM transparent_motivations.ingestion_runs ir
       WHERE ir.politician_source_id = e.id
         AND ir.adapter_name='fec' AND ir.election_cycle = e.cycle_int::text
         AND ir.status IN ('completed','completed_with_warning')
     )
     ORDER BY cycle_int DESC,
              (representing_state = ANY($3::text[])) DESC,
              representing_state, full_name`,
    [floor, current, PILOT_STATES]
  );
  return r.rows;
}

// ---------------------------------------------------------------------------
// Orchestrator
// ---------------------------------------------------------------------------

/**
 * runFecHistoricalBackfill ingests every confirmed FEC source across all of its
 * active cycles back to `floorYear`. Holds FEC_LOCK_KEY for the duration (with a
 * heartbeat) so it is the sole FEC consumer and never contends with the cron.
 *
 * Non-aborting: per-pair errors are logged and skipped. Safe to call repeatedly —
 * completed pairs are skipped, so a re-trigger resumes.
 */
export async function runFecHistoricalBackfill(floorYear = DEFAULT_FLOOR): Promise<{
  status: 'completed' | 'skipped_locked';
  ok: number;
  failed: number;
}> {
  const lock = await acquireLock(FEC_LOCK_KEY, BACKFILL_LOCK_TTL_S);
  if (!lock) {
    console.log('[fecBackfill] FEC lock held (cron or another backfill running) — skipping');
    return { status: 'skipped_locked', ok: 0, failed: 0 };
  }

  const heartbeat = setInterval(() => {
    renewLock(FEC_LOCK_KEY, BACKFILL_LOCK_TTL_S).catch((e) =>
      console.warn('[fecBackfill] lock heartbeat failed:', e instanceof Error ? e.message : String(e))
    );
  }, HEARTBEAT_MS);

  let ok = 0;
  let failed = 0;
  try {
    // Step 1: ensure the cycle cache is populated.
    await populateFecCandidateCycles();

    // Step 1b: cache FEC authoritative per-cycle receipts (for correct total_raised).
    await populateFecCandidateTotals().catch((e) =>
      console.warn('[fecBackfill] totals cache populate failed (non-fatal):', e instanceof Error ? e.message : String(e))
    );

    // Step 2: iterate pending pairs.
    const current = parseInt(currentFecCycle(), 10);
    const pairs = await getPendingPairs(floorYear, current);
    console.log(`[fecBackfill] floor=${floorYear} current=${current} pending_pairs=${pairs.length}`);

    for (let i = 0; i < pairs.length; i++) {
      const w = pairs[i]!;
      if (i > 0) await sleep(SLEEP_BETWEEN_PAIRS_MS);
      try {
        await runIngestion(createFecAdapter(w.cycle), w, w.cycle);
        ok++;
        if ((i + 1) % 25 === 0 || i === pairs.length - 1) {
          console.log(`[fecBackfill] progress ${i + 1}/${pairs.length} (ok=${ok} failed=${failed})`);
        }
      } catch (err) {
        failed++;
        console.error(
          `[fecBackfill] ✗ [${w.cycle}] ${w.full_name} (${w.external_id}): ${err instanceof Error ? err.message : String(err)}`
        );
      }
    }

    console.log(`[fecBackfill] complete: ok=${ok} failed=${failed}`);
    return { status: 'completed', ok, failed };
  } finally {
    clearInterval(heartbeat);
    await releaseLock(FEC_LOCK_KEY).catch((e) =>
      console.warn('[fecBackfill] releaseLock failed:', e instanceof Error ? e.message : String(e))
    );
  }
}

// ---------------------------------------------------------------------------
// Boot-time auto-resume — makes the multi-day backfill survive dyno restarts
// ---------------------------------------------------------------------------

const AUTORESUME_DELAY_MS = 15_000; // let the server finish booting first

/** Count (source, cycle) pairs in [floor, current] that have no completed run yet. */
export async function countPendingBackfillPairs(floorYear = DEFAULT_FLOOR): Promise<number> {
  const current = parseInt(currentFecCycle(), 10);
  const r = await pool.query<{ n: string }>(
    `WITH expanded AS (
       SELECT ps.id, cyc AS cycle_int
       FROM transparent_motivations.politician_sources ps
       JOIN transparent_motivations.fec_candidate_cycles cc ON cc.external_id = ps.external_id
       CROSS JOIN LATERAL unnest(cc.election_years) AS cyc
       WHERE ps.source_system LIKE 'fec%' AND ps.research_status='confirmed' AND ps.external_id <> ''
         AND cyc BETWEEN $1 AND $2 AND cyc % 2 = 0
     )
     SELECT COUNT(*)::int AS n FROM expanded e
     WHERE NOT EXISTS (
       SELECT 1 FROM transparent_motivations.ingestion_runs ir
       WHERE ir.politician_source_id = e.id AND ir.adapter_name='fec'
         AND ir.election_cycle = e.cycle_int::text
         AND ir.status IN ('completed','completed_with_warning'))`,
    [floorYear, current]
  );
  return Number(r.rows[0]?.n ?? 0);
}

const AUTORESUME_RETRY_MS = 60_000;
const AUTORESUME_MAX_ATTEMPTS = 120; // ~2h of retry budget for lock-contended cycles

/**
 * maybeResumeBackfillOnBoot — called once at server startup. When
 * FEC_BACKFILL_AUTORESUME=1 and pending pairs remain, it drives the backfill to
 * completion across dyno restarts.
 *
 * CRITICAL: it RETRIES rather than firing once. On a crash-then-reboot the dead
 * process's FEC lock can linger in Redis until its TTL expires; a single attempt
 * would hit that stale lock, get skipped_locked, and give up. Retrying every
 * AUTORESUME_RETRY_MS lets the next attempt acquire once the orphan expires (or
 * once the cron releases). Also re-runs after a 'completed' that still left failed
 * pairs pending (transient 429/timeout). Exits when no pending pairs remain.
 */
export function maybeResumeBackfillOnBoot(floorYear = DEFAULT_FLOOR): void {
  if (process.env.FEC_BACKFILL_AUTORESUME !== '1') return;
  setTimeout(() => { void autoResumeLoop(floorYear); }, AUTORESUME_DELAY_MS);
}

async function autoResumeLoop(floorYear: number): Promise<void> {
  for (let attempt = 1; attempt <= AUTORESUME_MAX_ATTEMPTS; attempt++) {
    try {
      const pending = await countPendingBackfillPairs(floorYear);
      if (pending === 0) {
        console.log('[fecBackfill] autoresume: no pending pairs — backfill complete, stopping loop');
        return;
      }
      console.log(`[fecBackfill] autoresume attempt ${attempt}/${AUTORESUME_MAX_ATTEMPTS}: ${pending} pending (floor ${floorYear})`);
      const r = await runFecHistoricalBackfill(floorYear);
      if (r.status === 'skipped_locked') {
        console.log(`[fecBackfill] autoresume: lock held — retry in ${AUTORESUME_RETRY_MS / 1000}s`);
      } else {
        console.log(`[fecBackfill] autoresume pass done: ok=${r.ok} failed=${r.failed}`);
      }
    } catch (err) {
      console.error('[fecBackfill] autoresume error:', err instanceof Error ? err.message : String(err));
    }
    await sleep(AUTORESUME_RETRY_MS);
  }
  console.warn('[fecBackfill] autoresume: max attempts reached — stopping (re-deploy or manual trigger to continue)');
}
