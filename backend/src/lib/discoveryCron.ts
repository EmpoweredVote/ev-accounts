/**
 * discoveryCron — sweep orchestrator for the weekly candidate discovery pipeline.
 *
 * Exports:
 *   acquireRunLock()    — atomic check-and-set; returns false if already held
 *   releaseRunLock()    — releases the lock (call in finally blocks)
 *   isRunLockHeld()     — read-only debugging aid; routes must use acquireRunLock(), not this
 *   runDiscoverySweep() — orchestrates the full weekly sweep across all eligible jurisdictions
 *
 * Lock design: in-process module-level boolean with 2-hour TTL timer.
 * Correct for single-instance Render deployment (no Redis needed).
 * Process restart clears the lock naturally — the 2h TTL guards against slow sweeps,
 * not process crashes (which are already handled by Render's restart policy).
 *
 * Sequential jurisdiction processing: jurisdictions are processed one at a time (for...of,
 * never Promise.all) to avoid exhausting the Anthropic API rate limit quota.
 *
 * Email behavior:
 *   - Per-run review email: suppressed during sweep (suppressRunEmail=true passed to service)
 *   - Zero-candidate regression alert: still fires per jurisdiction (not gated by suppressRunEmail)
 *   - Sweep-summary email: sent ONCE at sweep end when at least one outcome list is non-empty
 */

import { pool } from './db.js';
import { runDiscoveryForJurisdiction } from './discoveryService.js';
import { sendEmail } from './emailService.js';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const SWEEP_HORIZON_DAYS = 180;
const LOCK_TTL_MS = 2 * 60 * 60 * 1000; // 2 hours
const RETRY_DELAYS_MS = [1_000, 2_000, 4_000]; // 3 retry attempts, exponential backoff

// ---------------------------------------------------------------------------
// In-process lock state
// ---------------------------------------------------------------------------

let lockHeld = false;
let lockTimer: ReturnType<typeof setTimeout> | null = null;

// ---------------------------------------------------------------------------
// Lock API — exported
// ---------------------------------------------------------------------------

/**
 * Atomically acquire the run lock.
 * Returns true if acquired, false if already held by another run.
 * Callers MUST use this (not isRunLockHeld + acquireRunLock) to avoid race conditions.
 */
export function acquireRunLock(): boolean {
  if (lockHeld) return false;
  lockHeld = true;
  lockTimer = setTimeout(() => {
    lockHeld = false;
    lockTimer = null;
    console.warn('[discoveryCron] Run lock auto-expired after 2h TTL');
  }, LOCK_TTL_MS);
  return true;
}

/**
 * Release the run lock. Safe to call in finally blocks — clears the TTL timer.
 */
export function releaseRunLock(): void {
  lockHeld = false;
  if (lockTimer) {
    clearTimeout(lockTimer);
    lockTimer = null;
  }
}

/**
 * Read-only check — exported as a debugging aid only.
 * API routes MUST call acquireRunLock() (atomic), not this + acquireRunLock() separately.
 */
export function isRunLockHeld(): boolean {
  return lockHeld;
}

// ---------------------------------------------------------------------------
// Retry helpers
// ---------------------------------------------------------------------------

function isTransient(err: unknown): boolean {
  const msg = err instanceof Error ? err.message : String(err);
  return /\b429\b|\b5\d\d\b|ECONNRESET|ETIMEDOUT|ENOTFOUND|fetch failed|rate.?limit/i.test(msg);
}

const sleep = (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms));

async function withRetry<T>(fn: () => Promise<T>, label: string): Promise<T> {
  let lastErr: unknown;
  for (let attempt = 0; attempt <= RETRY_DELAYS_MS.length; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      if (attempt < RETRY_DELAYS_MS.length && isTransient(err)) {
        const delay = RETRY_DELAYS_MS[attempt];
        console.warn(`[discoveryCron] ${label}: transient error, retrying in ${delay}ms`, err);
        await sleep(delay);
        continue;
      }
      break;
    }
  }
  throw lastErr;
}

// ---------------------------------------------------------------------------
// Sweep-summary email builder
// ---------------------------------------------------------------------------

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function buildSweepSummaryEmail(args: {
  autoUpserted: Array<{ jurisdictionName: string; candidates: Array<{ name: string; race: string; confidence: string }> }>;
  uncertainPending: Array<{ jurisdictionName: string; count: number }>;
  failedJurisdictions: Array<{ jurisdictionName: string; error: string }>;
  reviewUrl: string;
}): string {
  const sections: string[] = [];

  if (args.autoUpserted.length > 0) {
    const items = args.autoUpserted.map((j) => {
      const candidates = j.candidates
        .map((c) => `<li>${escapeHtml(c.name)} — ${escapeHtml(c.race)} (${escapeHtml(c.confidence)})</li>`)
        .join('');
      return `<h3 style="margin: 12px 0 4px 0;">${escapeHtml(j.jurisdictionName)}</h3><ul>${candidates}</ul>`;
    }).join('');
    sections.push(`
      <h2 style="margin: 16px 0 8px 0;">Auto-upserted to race_candidates</h2>
      ${items}
    `);
  }

  if (args.uncertainPending.length > 0) {
    const items = args.uncertainPending
      .map((j) => `<li>${escapeHtml(j.jurisdictionName)}: ${j.count}</li>`)
      .join('');
    sections.push(`
      <h2 style="margin: 16px 0 8px 0;">Uncertain candidates pending review</h2>
      <ul>${items}</ul>
      <p><a href="${escapeHtml(args.reviewUrl)}" style="display:inline-block;padding:10px 16px;background:#1f6feb;color:#fff;border-radius:6px;text-decoration:none;">Review queue</a></p>
    `);
  }

  if (args.failedJurisdictions.length > 0) {
    const items = args.failedJurisdictions
      .map((j) => `<li><strong>${escapeHtml(j.jurisdictionName)}:</strong> ${escapeHtml(j.error.slice(0, 200))}</li>`)
      .join('');
    sections.push(`
      <h2 style="margin: 16px 0 8px 0;">Failed jurisdictions</h2>
      <ul>${items}</ul>
    `);
  }

  return `
    <div style="font-family: system-ui, sans-serif; max-width: 560px;">
      <h1 style="margin: 0 0 8px 0;">Discovery sweep complete</h1>
      ${sections.join('')}
    </div>
  `;
}

// ---------------------------------------------------------------------------
// Main sweep orchestrator
// ---------------------------------------------------------------------------

/**
 * Run the weekly discovery sweep for all jurisdictions with elections within SWEEP_HORIZON_DAYS.
 *
 * Acquires the run lock atomically before starting. If the lock is already held (cron collision
 * or concurrent manual trigger), logs a warning and returns without doing any work.
 * Lock is always released in a finally block — no leak on error.
 *
 * Processes jurisdictions sequentially (for...of, never parallel) to avoid exhausting
 * the Anthropic API rate limit.
 *
 * Sends ONE sweep-summary email at the end — only when at least one outcome list is non-empty.
 */
export async function runDiscoverySweep(): Promise<void> {
  if (!acquireRunLock()) {
    console.warn('[discoveryCron] Skipping sweep — another run is already in progress');
    return;
  }

  try {
    const horizon = new Date();
    horizon.setUTCDate(horizon.getUTCDate() + SWEEP_HORIZON_DAYS);

    const jurisdictionsResult = await pool.query<{ id: string; jurisdiction_name: string }>(
      `SELECT id, jurisdiction_name
         FROM essentials.discovery_jurisdictions
        WHERE election_date > now()
          AND election_date <= $1
        ORDER BY election_date ASC`,
      [horizon]
    );

    const jurisdictions = jurisdictionsResult.rows;

    if (jurisdictions.length === 0) {
      console.info('[discoveryCron] No jurisdictions in sweep horizon; nothing to do');
      return;
    }

    console.info(`[discoveryCron] Sweep starting: ${jurisdictions.length} jurisdiction(s) in horizon`);

    const autoUpsertedByJurisdiction: Array<{
      jurisdictionName: string;
      candidates: Array<{ name: string; race: string; confidence: string }>;
    }> = [];
    const uncertainPending: Array<{ jurisdictionName: string; count: number }> = [];
    const failedJurisdictions: Array<{ jurisdictionName: string; error: string }> = [];

    for (const j of jurisdictions) {
      try {
        const summary = await withRetry(
          () => runDiscoveryForJurisdiction(j.id, {
            triggeredBy: 'cron',
            autoUpsert: true,
            suppressRunEmail: true,
          }),
          `jurisdiction ${j.jurisdiction_name}`
        );

        if (summary.autoUpserted > 0) {
          // Fetch candidate details from staging for the email (staging has race_hint + confidence)
          const detailRows = await pool.query<{ full_name: string; race_hint: string; confidence: string }>(
            `SELECT full_name, race_hint, confidence
               FROM essentials.candidate_staging
              WHERE run_id = $1 AND reviewed_by = 'cron' AND status = 'approved'
              ORDER BY created_at ASC`,
            [summary.runId]
          );
          autoUpsertedByJurisdiction.push({
            jurisdictionName: j.jurisdiction_name,
            candidates: detailRows.rows.map((r) => ({
              name: r.full_name,
              race: r.race_hint,
              confidence: r.confidence,
            })),
          });
        }

        if (summary.uncertainStaged > 0) {
          uncertainPending.push({
            jurisdictionName: j.jurisdiction_name,
            count: summary.uncertainStaged,
          });
        }
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        console.error(`[discoveryCron] Jurisdiction "${j.jurisdiction_name}" failed after retries:`, err);
        failedJurisdictions.push({
          jurisdictionName: j.jurisdiction_name,
          error: msg.slice(0, 500),
        });
      }
    }

    const adminEmail = process.env.ADMIN_EMAIL;
    const reviewUrl = process.env.ADMIN_REVIEW_URL ?? 'https://essentials.empowered.vote/admin/staging';

    const hasContent =
      autoUpsertedByJurisdiction.length > 0 ||
      uncertainPending.length > 0 ||
      failedJurisdictions.length > 0;

    if (adminEmail && hasContent) {
      const html = buildSweepSummaryEmail({
        autoUpserted: autoUpsertedByJurisdiction,
        uncertainPending,
        failedJurisdictions,
        reviewUrl,
      });
      const totalUpserted = autoUpsertedByJurisdiction.reduce((n, j) => n + j.candidates.length, 0);
      const totalUncertain = uncertainPending.reduce((n, j) => n + j.count, 0);
      const subject = `Discovery sweep complete — ${totalUpserted} auto-upserted, ${totalUncertain} need review, ${failedJurisdictions.length} failed`;
      await sendEmail({ to: adminEmail, subject, html });
    } else if (!adminEmail) {
      console.info('[discoveryCron] ADMIN_EMAIL not set; skipping sweep-summary email');
    } else {
      console.info('[discoveryCron] Sweep had no upserts, no uncertain items, no failures — no email sent');
    }

    console.info('[discoveryCron] Sweep complete', {
      jurisdictions: jurisdictions.length,
      autoUpserted: autoUpsertedByJurisdiction.reduce((n, j) => n + j.candidates.length, 0),
      uncertain: uncertainPending.reduce((n, j) => n + j.count, 0),
      failed: failedJurisdictions.length,
    });
  } finally {
    releaseRunLock();
  }
}
