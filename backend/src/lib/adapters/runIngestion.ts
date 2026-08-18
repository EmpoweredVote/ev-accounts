/**
 * runIngestion — orchestrator for the Fetch → Normalize → Upsert adapter pipeline.
 *
 * Ported from:
 *   EV-Backend/internal/campaign_finance/adapter/run.go
 *
 * Creates an ingestion_runs row at start, runs the three-phase pipeline,
 * and finalizes the row with counters and status at completion.
 * Every adapter execution produces exactly one ingestion_runs audit record.
 */

import { pool } from '../db.js';
import type { SourceAdapter, ETagProvider, StreamingAdapter, NormalizeResult } from './adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';
import { refreshSummaryAggForSource } from '../campaignFinanceService.js';

// ---------------------------------------------------------------------------
// runIngestion — main orchestrator
// ---------------------------------------------------------------------------

/**
 * runIngestion executes the full Fetch → Normalize → Upsert pipeline for one
 * politician/cycle pair. It creates an ingestion_runs row at start and finalizes
 * it with all counters at completion.
 *
 * If TotalFetched < 95% of TotalExpected the run is marked completed_with_warning
 * rather than completed — this signals a potential truncation in the FEC data feed.
 *
 * CRITICAL: pg returns numeric IDs as strings from INSERT RETURNING — Number() them.
 * RecordsSkipped is additive: normalizer skips + upsert duplicate skips combined.
 */
export async function runIngestion(
  adapter: SourceAdapter,
  ps: PoliticianSource,
  cycle = '',
  signal?: AbortSignal
): Promise<void> {
  const startedAt = new Date();

  // Create ingestion_runs row with status='running'
  const insertResult = await pool.query<{ id: string }>(
    `INSERT INTO transparent_motivations.ingestion_runs
       (adapter_name, politician_source_id, election_cycle, started_at, status)
     VALUES ($1, $2, $3, $4, 'running')
     RETURNING id`,
    [adapter.name(), ps.id, cycle, startedAt.toISOString()]
  );

  // CRITICAL: pg returns numeric ID as string — Number() it
  const runId = Number(insertResult.rows[0].id);

  try {
    // Counters shared by both execution paths and fed into the completeness check.
    let totalFetched = 0;
    let totalExpected = 0;
    let normalizeSkipped = 0;
    let normalizeExcluded = 0;
    let normalizeTotalParsed = 0;
    let upsertInserted = 0;
    let upsertSkipped = 0;
    let upsertUnresolved = 0;
    let upsertErrors = 0;

    if (isStreamingAdapter(adapter)) {
      // Streaming path (FEC mega-committees): normalize + upsert each batch as it is
      // fetched, so a mid-pair restart preserves already-persisted windows rather than
      // losing the whole pull. Because upsert is idempotent (ON CONFLICT DO UPDATE),
      // re-processing a batch is safe. Counters accumulate across all batches.
      const fetchResult = await adapter.fetchStream(ps, async (records) => {
        if (records.length === 0) return;
        const norm: NormalizeResult = await adapter.normalize(
          { records, totalExpected: 0, totalFetched: records.length },
          ps
        );
        const up = await adapter.upsert(norm);
        normalizeSkipped += norm.skipped;
        normalizeExcluded += norm.excluded ?? 0;
        normalizeTotalParsed += norm.totalParsed;
        upsertInserted += up.inserted;
        upsertSkipped += up.skipped;
        upsertUnresolved += up.unresolved;
        upsertErrors += up.errors;
      }, signal);
      totalFetched = fetchResult.totalFetched;
      totalExpected = fetchResult.totalExpected;
    } else {
      // Buffered path (all other adapters): fetch everything, then normalize, then
      // upsert once — unchanged behavior.
      const fetchResult = await adapter.fetch(ps);
      const normalizeResult = await adapter.normalize(fetchResult, ps);
      const upsertResult = await adapter.upsert(normalizeResult);
      totalFetched = fetchResult.totalFetched;
      totalExpected = fetchResult.totalExpected;
      normalizeSkipped = normalizeResult.skipped;
      normalizeExcluded = normalizeResult.excluded ?? 0;
      normalizeTotalParsed = normalizeResult.totalParsed;
      upsertInserted = upsertResult.inserted;
      upsertSkipped = upsertResult.skipped;
      upsertUnresolved = upsertResult.unresolved;
      upsertErrors = upsertResult.errors;
    }

    // Compute duration
    const completedAt = new Date();
    const durationMs = completedAt.getTime() - startedAt.getTime();

    // RecordsSkipped is additive and keeps its historical meaning — "fetched but not
    // inserted" — so it stays continuous across this change: normalizer DEFECTS +
    // deliberate EXCLUSIONS (e.g. FEC memo items) + upsert duplicate skips.
    const recordsSkipped = normalizeSkipped + normalizeExcluded + upsertSkipped;

    // Determine initial status
    let status = 'completed';
    let notes = '';

    // Completeness check: warn if fetched < 95% of expected
    if (
      totalExpected > 0 &&
      totalFetched < totalExpected * 0.95
    ) {
      status = 'completed_with_warning';
      const pct = Math.round((totalFetched / totalExpected) * 100);
      notes = `fetched ${totalFetched} of expected ${totalExpected} (${pct}%)`;
    }

    // Skip threshold: warn if >1% of examined rows were skipped (Cal-Access locked decision).
    //
    // 🔴 DEFECTS ONLY. `normalizeExcluded` is deliberately NOT counted here. Deliberate,
    // rule-based omissions are not defects, and folding them in made this alarm useless
    // on FEC — 9,636 warnings in 60 days (median 42%, p95 71%, max 100%) purely because
    // FEC excludes memo items, while in the same window NO other adapter tripped it once.
    // The 1% figure is unchanged and still exactly right for what it actually measures:
    // Cal-Access's missing_required_field / amount_parse_error rows.
    if (normalizeTotalParsed > 0 && normalizeSkipped > 0) {
      const skipRate = normalizeSkipped / normalizeTotalParsed;
      if (skipRate > 0.01) {
        status = 'completed_with_warning';
        const skipNote = `skip threshold exceeded: ${normalizeSkipped}/${normalizeTotalParsed} rows skipped (${(skipRate * 100).toFixed(1)}%)`;
        notes = notes ? `${notes}; ${skipNote}` : skipNote;
      }
    }

    // Populate ETag/download metadata if adapter provides it (Cal-Access does).
    // Duck-typed ETagProvider — same pattern as Go's etagProvider inline interface.
    let sourceETag = '';
    let zipDownloadedAt: Date | null = null;
    if (isETagProvider(adapter)) {
      sourceETag = adapter.getETag() ?? '';
      zipDownloadedAt = adapter.getZIPDownloadedAt();
    }

    // Finalize run row with all counters
    await pool.query(
      `UPDATE transparent_motivations.ingestion_runs SET
         completed_at      = $1,
         duration_ms       = $2,
         status            = $3,
         records_fetched   = $4,
         records_inserted  = $5,
         records_skipped   = $6,
         records_unresolved= $7,
         errors            = $8,
         notes             = $9,
         source_e_tag       = $10,
         z_ip_downloaded_at = $11
       WHERE id = $12`,
      [
        completedAt.toISOString(),
        durationMs,
        status,
        totalFetched,
        upsertInserted,
        recordsSkipped,
        upsertUnresolved,
        upsertErrors,
        notes,
        sourceETag,
        zipDownloadedAt ? zipDownloadedAt.toISOString() : null,
        runId,
      ]
    );

    // Refresh the pre-aggregated summary for this source so the public read path stays
    // fast as the contributions table grows (quick-030 Task 4). Non-fatal: an agg refresh
    // failure must never fail an otherwise-successful ingest.
    try {
      await refreshSummaryAggForSource(ps.id);
    } catch (aggErr) {
      console.warn(
        `[runIngestion] summary agg refresh skipped for source=${ps.id}: ${aggErr instanceof Error ? aggErr.message : String(aggErr)}`
      );
    }
  } catch (err) {
    // On any error: mark run as failed, write error to notes, re-throw
    const completedAt = new Date();
    const durationMs = completedAt.getTime() - startedAt.getTime();
    const errMessage = err instanceof Error ? err.message : String(err);

    await pool.query(
      `UPDATE transparent_motivations.ingestion_runs SET
         completed_at = $1,
         duration_ms  = $2,
         status       = 'failed',
         notes        = $3
       WHERE id = $4`,
      [completedAt.toISOString(), durationMs, errMessage, runId]
    );

    throw err;
  }
}

// ---------------------------------------------------------------------------
// Duck-type guard for ETagProvider
// ---------------------------------------------------------------------------

function isETagProvider(adapter: unknown): adapter is ETagProvider {
  return (
    typeof adapter === 'object' &&
    adapter !== null &&
    typeof (adapter as ETagProvider).getETag === 'function' &&
    typeof (adapter as ETagProvider).getZIPDownloadedAt === 'function'
  );
}

// ---------------------------------------------------------------------------
// Duck-type guard for StreamingAdapter
// ---------------------------------------------------------------------------

function isStreamingAdapter(adapter: unknown): adapter is SourceAdapter & StreamingAdapter {
  return (
    typeof adapter === 'object' &&
    adapter !== null &&
    typeof (adapter as StreamingAdapter).fetchStream === 'function'
  );
}
