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
import type { SourceAdapter, ETagProvider } from './adapterInterface.js';
import type { PoliticianSource } from '../campaignFinanceService.js';

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
  cycle = ''
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
    // Phase 1: Fetch
    const fetchResult = await adapter.fetch(ps);

    // Phase 2: Normalize
    const normalizeResult = await adapter.normalize(fetchResult, ps);

    // Phase 3: Upsert
    const upsertResult = await adapter.upsert(normalizeResult);

    // Compute duration
    const completedAt = new Date();
    const durationMs = completedAt.getTime() - startedAt.getTime();

    // RecordsSkipped is additive: normalizer skips + upsert duplicate skips
    const recordsSkipped = normalizeResult.skipped + upsertResult.skipped;

    // Determine initial status
    let status = 'completed';
    let notes = '';

    // Completeness check: warn if fetched < 95% of expected
    if (
      fetchResult.totalExpected > 0 &&
      fetchResult.totalFetched < fetchResult.totalExpected * 0.95
    ) {
      status = 'completed_with_warning';
      const pct = Math.round((fetchResult.totalFetched / fetchResult.totalExpected) * 100);
      notes = `fetched ${fetchResult.totalFetched} of expected ${fetchResult.totalExpected} (${pct}%)`;
    }

    // Skip threshold: warn if >1% of examined rows were skipped (Cal-Access locked decision)
    if (normalizeResult.totalParsed > 0 && normalizeResult.skipped > 0) {
      const skipRate = normalizeResult.skipped / normalizeResult.totalParsed;
      if (skipRate > 0.01) {
        status = 'completed_with_warning';
        const skipNote = `skip threshold exceeded: ${normalizeResult.skipped}/${normalizeResult.totalParsed} rows skipped (${(skipRate * 100).toFixed(1)}%)`;
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
         source_etag       = $10,
         zip_downloaded_at = $11
       WHERE id = $12`,
      [
        completedAt.toISOString(),
        durationMs,
        status,
        fetchResult.totalFetched,
        upsertResult.inserted,
        recordsSkipped,
        upsertResult.unresolved,
        upsertResult.errors,
        notes,
        sourceETag,
        zipDownloadedAt ? zipDownloadedAt.toISOString() : null,
        runId,
      ]
    );
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
