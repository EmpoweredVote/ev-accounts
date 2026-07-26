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

import Anthropic from '@anthropic-ai/sdk';
import { pool } from './db.js';
import { runDiscoveryForJurisdiction } from './discoveryService.js';
import { checkAnthropicAvailability, isAccountUnusableError } from './discoveryAgentRunner.js';
import { sendEmail } from './emailService.js';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

// OPS-04: SWEEP_HORIZON_DAYS + the weekly Sunday-02:00-UTC cadence (registered
// in discoverySweep.ts's node-cron expression) are a DELIBERATE cost choice,
// not an arbitrary default. Each sweep spends paid Anthropic calls (the OPS-01
// canary + one runDiscoveryAgent call per in-horizon jurisdiction) proportional
// to how many discovery_jurisdictions.election_date rows fall within this
// window; the weekly cadence bounds total spend to once per horizon-refresh
// rather than re-scanning the same jurisdictions more often than useful.
// Widening the horizon or shortening the cadence directly increases weekly
// Anthropic spend — treat either change as a deliberate cost decision, not a
// routine tuning knob.
//
// 180 is EVIDENCE-BACKED, not a guess: as of 2026-07, 77 completed runs found
// candidates while >90 days out, and Frisco / Princeton / Nevada / Lowry Crossing
// each first returned candidates at 170 days. Narrowing the horizon to 90 days
// would silently discard all of that. Cost is instead controlled per-jurisdiction
// by the OPS-06 backoff below, which suppresses only jurisdictions that have
// actually proven empty. Override for experiments without a code change.
const SWEEP_HORIZON_DAYS = Number(process.env.DISCOVERY_SWEEP_HORIZON_DAYS ?? 180);

// OPS-06 per-jurisdiction backoff. 161 of 296 completed runs (2026-04..07) found
// nothing, and the empties concentrate in specific jurisdictions (Richardson 8
// runs / 0 found, Plano 7/0, Blue Ridge 6/0, Josephine 5/0) rather than in a
// far-out date band. So back off by observed emptiness, never by date alone.
//
// A backed-off jurisdiction is NEVER silenced: it drops to a probe every
// BACKOFF_PROBE_DAYS instead of weekly (~4x cheaper), and backoff is disabled
// outright inside BACKOFF_MIN_DAYS_OUT so a filing window is never missed.
const BACKOFF_EMPTY_STREAK = Number(process.env.DISCOVERY_BACKOFF_EMPTY_STREAK ?? 3);
const BACKOFF_MIN_DAYS_OUT = Number(process.env.DISCOVERY_BACKOFF_MIN_DAYS_OUT ?? 90);
const BACKOFF_PROBE_DAYS = Number(process.env.DISCOVERY_BACKOFF_PROBE_DAYS ?? 28);
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

/**
 * isRetryable — typed classification replacing the old message-regex isTransient().
 *
 * Anthropic.APIError instances are classified by their typed `.status`:
 *   - 401 (auth), 402 (billing), 403 (permission) — NEVER retryable. Retrying spends
 *     money on a call guaranteed to fail identically (OPS-02).
 *   - 429 (rate limit) or >=500 (server error) — retryable (existing backoff).
 *   - Any other 4xx (400/404/409/422/etc.) — not transient, a retry fails identically.
 * Non-APIError errors (DB connection, fetchPageContent, etc.) fall back to the
 * existing network-fault message regex — unchanged from the prior isTransient().
 */
export function isRetryable(err: unknown): boolean {
  if (err instanceof Anthropic.APIError) {
    if (err.status === 401 || err.status === 402 || err.status === 403) return false;
    if (err.status === 429 || (typeof err.status === 'number' && err.status >= 500)) return true;
    return false;
  }
  const msg = err instanceof Error ? err.message : String(err);
  return /ECONNRESET|ETIMEDOUT|ENOTFOUND|fetch failed/i.test(msg);
}

// ---------------------------------------------------------------------------
// OPS-06 backoff decision
// ---------------------------------------------------------------------------

/**
 * leadingEmptyStreak — how many of the most-recent completed runs found zero
 * candidates, counting back from the latest. `foundSeries` must be ordered
 * newest-first. A single non-zero run resets the streak, so one hit re-arms
 * weekly scanning immediately.
 */
export function leadingEmptyStreak(foundSeries: number[] | null | undefined): number {
  if (!foundSeries) return 0;
  let streak = 0;
  for (const found of foundSeries) {
    if (found !== 0) break;
    streak += 1;
  }
  return streak;
}

/**
 * shouldSkipForBackoff — true when a jurisdiction has proven empty enough that
 * scanning it this week is not worth a paid agent run.
 *
 * Deliberately conservative, in this order:
 *   1. Inside BACKOFF_MIN_DAYS_OUT of the election, NEVER skip. This is the
 *      filing window; missing a filing is far more costly than a wasted run.
 *   2. Fewer than BACKOFF_EMPTY_STREAK consecutive empty runs — not enough
 *      evidence, keep scanning. A brand-new jurisdiction is never skipped.
 *   3. Otherwise skip, EXCEPT once every BACKOFF_PROBE_DAYS so a backed-off
 *      jurisdiction still gets probed and can re-arm itself. Without this a
 *      jurisdiction whose filing opens at, say, 150 days out could stay dark
 *      from its third empty run until BACKOFF_MIN_DAYS_OUT.
 */
export function shouldSkipForBackoff(args: {
  daysUntilElection: number;
  emptyStreak: number;
  daysSinceLastRun: number | null;
}): boolean {
  if (args.daysUntilElection <= BACKOFF_MIN_DAYS_OUT) return false;
  if (args.emptyStreak < BACKOFF_EMPTY_STREAK) return false;
  if (args.daysSinceLastRun === null) return false;
  if (args.daysSinceLastRun >= BACKOFF_PROBE_DAYS) return false;
  return true;
}

const sleep = (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms));

export async function withRetry<T>(fn: () => Promise<T>, label: string): Promise<T> {
  let lastErr: unknown;
  for (let attempt = 0; attempt <= RETRY_DELAYS_MS.length; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      if (attempt < RETRY_DELAYS_MS.length && isRetryable(err)) {
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
  // OPS-05 circuit breaker: set when the sweep stopped early because the Anthropic
  // account became unusable mid-run. `skipped` lists jurisdictions never attempted.
  abortDetail?: string | null;
  skipped?: string[];
  // OPS-06: jurisdictions not scanned because they have proven empty. Reported for
  // transparency but deliberately NOT part of the send decision — a week whose only
  // news is "backoff working as designed" should stay quiet.
  backedOff?: string[];
}): string {
  const sections: string[] = [];

  if (args.abortDetail) {
    const skipped = args.skipped ?? [];
    const skippedList = skipped.length > 0
      ? `<p><strong>${skipped.length} jurisdiction(s) not attempted:</strong> ${escapeHtml(skipped.join(', '))}</p>`
      : '';
    sections.push(`
      <div style="border-left:4px solid #d1242f;padding:8px 12px;background:#fff5f5;">
        <h2 style="margin: 0 0 8px 0;">Sweep ABORTED — Anthropic account unusable</h2>
        <p>The sweep stopped early to avoid spending on calls guaranteed to fail. Resolve the account issue, then trigger a manual sweep.</p>
        <pre style="background:#f5f5f5;padding:10px;border-radius:4px;white-space:pre-wrap;">${escapeHtml(args.abortDetail)}</pre>
        ${skippedList}
      </div>
    `);
  }

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

  const backedOff = args.backedOff ?? [];
  if (backedOff.length > 0) {
    sections.push(`
      <h2 style="margin: 16px 0 8px 0;">Not scanned — backoff (${backedOff.length})</h2>
      <p style="color:#57606a;font-size:13px;margin:0 0 4px 0;">Skipped to save cost: no candidates in their last ${BACKOFF_EMPTY_STREAK} runs and more than ${BACKOFF_MIN_DAYS_OUT} days to their election. Each is still probed every ${BACKOFF_PROBE_DAYS} days, and resumes weekly scanning inside ${BACKOFF_MIN_DAYS_OUT} days.</p>
      <p style="color:#57606a;font-size:13px;margin:0;">${escapeHtml(backedOff.join(', '))}</p>
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
 *
 * OPS-01 pre-flight: before touching any jurisdiction, runs checkAnthropicAvailability()
 * exactly once. A conclusive-unusable result (missing key, or a canary failure that
 * isAccountUnusableError classifies as conclusive — 401 / 403 / a credit-exhaustion
 * 400) aborts the sweep with exactly one operator alert and zero jurisdiction
 * queries. An inconclusive canary failure (thrown 529/network error) is logged and
 * the sweep proceeds normally — only a returned {available:false} result aborts.
 *
 * OPS-06 backoff: jurisdictions whose last BACKOFF_EMPTY_STREAK completed runs all
 * found zero candidates are skipped while more than BACKOFF_MIN_DAYS_OUT days from
 * their election, dropping to a probe every BACKOFF_PROBE_DAYS instead of weekly.
 * Skips are always logged and reported in the summary email — never silent.
 *
 * OPS-05 circuit breaker: the pre-flight cannot catch credit running out MID-sweep,
 * so the per-jurisdiction catch also checks isAccountUnusableError and breaks out of
 * the loop, folding the skipped jurisdictions into the single summary email instead
 * of emitting one failure email per remaining jurisdiction.
 */
export async function runDiscoverySweep(): Promise<void> {
  if (!acquireRunLock()) {
    console.warn('[discoveryCron] Skipping sweep — another run is already in progress');
    return;
  }

  try {
    let availability: Awaited<ReturnType<typeof checkAnthropicAvailability>> | undefined;
    try {
      availability = await checkAnthropicAvailability();
    } catch (err) {
      // Inconclusive canary failure (529, network fault, non-APIError, etc.) —
      // log and PROCEED. Only a returned conclusive-unusable result aborts the
      // sweep (see checkAnthropicAvailability's own doc comment / RESEARCH Pitfall 3).
      console.warn('[discoveryCron] Anthropic pre-flight canary was inconclusive; proceeding with sweep', err);
    }

    if (availability && !availability.available) {
      // availability.detail is already key-free by construction (checkAnthropicAvailability
      // only builds it from .status/.type/.message) — never log/email env.ANTHROPIC_API_KEY.
      console.error('[discoveryCron] Aborting sweep — Anthropic unavailable:', availability.detail);
      const adminEmail = process.env.ADMIN_EMAIL;
      if (adminEmail) {
        await sendEmail({
          to: adminEmail,
          subject: `Discovery sweep SKIPPED — Anthropic unavailable (${availability.reason})`,
          html: `<div style="font-family: system-ui, sans-serif; max-width: 560px;">
            <h2>Discovery sweep skipped</h2>
            <p>The weekly discovery sweep did not run because Anthropic is currently unusable:</p>
            <pre style="background:#f5f5f5;padding:10px;border-radius:4px;white-space:pre-wrap;">${escapeHtml(availability.detail)}</pre>
            <p>No jurisdictions were processed — no paid calls were made.</p>
          </div>`,
        });
      } else {
        console.warn('[discoveryCron] ADMIN_EMAIL not set; skip-alert not sent (see error log above)');
      }
      return; // finally block below still releases the lock
    }

    const horizon = new Date();
    horizon.setUTCDate(horizon.getUTCDate() + SWEEP_HORIZON_DAYS);

    // The LATERAL pulls each jurisdiction's most-recent completed runs so OPS-06
    // can decide backoff without a second query per jurisdiction. It rides
    // idx_discovery_runs_jurisdiction_started (discovery_jurisdiction_id,
    // started_at DESC) — hence ordering by started_at, not completed_at.
    const jurisdictionsResult = await pool.query<{
      id: string;
      jurisdiction_name: string;
      days_until_election: number;
      found_series: number[] | null;
      days_since_last_run: number | null;
    }>(
      `SELECT j.id,
              j.jurisdiction_name,
              (j.election_date - CURRENT_DATE)                       AS days_until_election,
              recent.found_series,
              CASE WHEN recent.last_started_at IS NULL THEN NULL
                   ELSE (CURRENT_DATE - recent.last_started_at::date)
              END                                                    AS days_since_last_run
         FROM essentials.discovery_jurisdictions j
         LEFT JOIN LATERAL (
           SELECT array_agg(r.candidates_found ORDER BY r.started_at DESC) AS found_series,
                  max(r.started_at)                                       AS last_started_at
             FROM (
               SELECT candidates_found, started_at
                 FROM essentials.discovery_runs
                WHERE discovery_jurisdiction_id = j.id
                  AND status = 'completed'
                ORDER BY started_at DESC
                LIMIT $2
             ) r
         ) recent ON true
        WHERE j.election_date > now()
          AND j.election_date <= $1
        ORDER BY j.election_date ASC`,
      [horizon, BACKOFF_EMPTY_STREAK]
    );

    // OPS-06: partition before spending anything. Skipped jurisdictions cost nothing.
    const skippedForBackoff: string[] = [];
    const jurisdictions = jurisdictionsResult.rows.filter((j) => {
      const emptyStreak = leadingEmptyStreak(j.found_series);
      const skip = shouldSkipForBackoff({
        daysUntilElection: Number(j.days_until_election),
        emptyStreak,
        daysSinceLastRun: j.days_since_last_run === null ? null : Number(j.days_since_last_run),
      });
      if (skip) skippedForBackoff.push(j.jurisdiction_name);
      return !skip;
    });

    if (skippedForBackoff.length > 0) {
      // Never a silent cap — always log what was dropped and why.
      console.info(
        `[discoveryCron] OPS-06 backoff skipped ${skippedForBackoff.length} jurisdiction(s) ` +
          `with >=${BACKOFF_EMPTY_STREAK} consecutive empty runs and >${BACKOFF_MIN_DAYS_OUT}d to election: ` +
          skippedForBackoff.join(', ')
      );
    }

    if (jurisdictions.length === 0) {
      console.info(
        skippedForBackoff.length > 0
          ? `[discoveryCron] No jurisdictions to scan; all ${skippedForBackoff.length} in horizon are backed off`
          : '[discoveryCron] No jurisdictions in sweep horizon; nothing to do'
      );
      return;
    }

    console.info(
      `[discoveryCron] Sweep starting: ${jurisdictions.length} jurisdiction(s) to scan ` +
        `(${skippedForBackoff.length} backed off)`
    );

    const autoUpsertedByJurisdiction: Array<{
      jurisdictionName: string;
      candidates: Array<{ name: string; race: string; confidence: string }>;
    }> = [];
    const uncertainPending: Array<{ jurisdictionName: string; count: number }> = [];
    const failedJurisdictions: Array<{ jurisdictionName: string; error: string }> = [];

    // OPS-05 circuit breaker. The OPS-01 pre-flight only proves the account was usable
    // BEFORE the sweep; credit can run out partway through (as on 2026-07-26, where 25
    // jurisdictions completed and the remaining 21 each failed and each emailed). Once a
    // conclusive account-level failure appears, every remaining jurisdiction is guaranteed
    // to fail identically — stop, and report once.
    let abortDetail: string | null = null;
    let abortedAtIndex = -1;

    for (const [index, j] of jurisdictions.entries()) {
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

        if (isAccountUnusableError(err)) {
          abortDetail = msg.slice(0, 500);
          abortedAtIndex = index;
          console.error(
            `[discoveryCron] Aborting sweep after "${j.jurisdiction_name}" — Anthropic account unusable; ` +
              `${jurisdictions.length - index - 1} jurisdiction(s) skipped`
          );
          break;
        }
      }
    }

    const skipped =
      abortedAtIndex >= 0
        ? jurisdictions.slice(abortedAtIndex + 1).map((j) => j.jurisdiction_name)
        : [];

    const adminEmail = process.env.ADMIN_EMAIL;
    const reviewUrl = process.env.ADMIN_REVIEW_URL ?? 'https://essentials.empowered.vote/admin/staging';

    const hasContent =
      autoUpsertedByJurisdiction.length > 0 ||
      uncertainPending.length > 0 ||
      failedJurisdictions.length > 0 ||
      abortDetail !== null;

    if (adminEmail && hasContent) {
      const html = buildSweepSummaryEmail({
        autoUpserted: autoUpsertedByJurisdiction,
        uncertainPending,
        failedJurisdictions,
        reviewUrl,
        abortDetail,
        skipped,
        backedOff: skippedForBackoff,
      });
      const totalUpserted = autoUpsertedByJurisdiction.reduce((n, j) => n + j.candidates.length, 0);
      const totalUncertain = uncertainPending.reduce((n, j) => n + j.count, 0);
      const subject = abortDetail
        ? `Discovery sweep ABORTED — Anthropic account unusable, ${skipped.length} jurisdiction(s) skipped`
        : `Discovery sweep complete — ${totalUpserted} auto-upserted, ${totalUncertain} need review, ${failedJurisdictions.length} failed`;
      await sendEmail({ to: adminEmail, subject, html });
    } else if (!adminEmail) {
      console.info('[discoveryCron] ADMIN_EMAIL not set; skipping sweep-summary email');
    } else {
      console.info('[discoveryCron] Sweep had no upserts, no uncertain items, no failures — no email sent');
    }

    console.info(abortDetail ? '[discoveryCron] Sweep ABORTED' : '[discoveryCron] Sweep complete', {
      jurisdictions: jurisdictions.length,
      autoUpserted: autoUpsertedByJurisdiction.reduce((n, j) => n + j.candidates.length, 0),
      uncertain: uncertainPending.reduce((n, j) => n + j.count, 0),
      failed: failedJurisdictions.length,
      skipped: skipped.length,
      backedOff: skippedForBackoff.length,
    });
  } finally {
    releaseRunLock();
  }
}
