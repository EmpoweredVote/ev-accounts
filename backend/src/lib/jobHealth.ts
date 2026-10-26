/**
 * jobHealth — the alarm for scheduled jobs that fail or stop running.
 *
 * ev-cto task 2026-09-14-cron-failure-alerting. The donor-name refresh failed 54 nights
 * in a row (2026-07-23 → 2026-09-14) and nothing said a word. This reads every job's run
 * history once a day and sends ONE email when something is wrong. On a healthy day it
 * sends nothing and writes nothing — a daily "all fine" email is how alarms get ignored.
 *
 * WHAT WATCHES WHAT
 *   - Render cron services: Render itself emails every workspace admin when a cron run
 *     exits non-zero (workspace notification setting "failure", email on; every
 *     ev-jobs-* service inherits it). This check adds proof-of-run staleness on top, for
 *     the failure Render cannot see: a job that stopped being scheduled, or that exits 0
 *     having done nothing.
 *   - pg_cron (Supabase Cron): Supabase has no built-in alert, so this is the only
 *     watcher. Read through ops.pg_cron_health() / ops.http_trigger_health() (CA_0332),
 *     because ev_api cannot read the cron schema.
 *
 * The check is itself scheduled by pg_cron (job `ev-job-health`), so its own run history
 * sits in cron.job_run_details — and a stall of it trips rule (b) for everyone else's
 * next look. Proof-of-run signals come from the manifest in docs/JOB-API-SPLIT.md; keep
 * RENDER_PROOFS in step with it.
 */
import { pool } from './db.js';
import { sendEmail } from './emailService.js';
import {
  evaluate,
  formatProblemLine,
  type HttpRow,
  type PgCronRow,
  type Problem,
  type ProofRow,
  type StrandedRow,
} from './jobHealthRules.js';

const HOURS = 60;
const DAYS = 24 * HOURS;

/**
 * Render cron jobs and the durable write that proves each one ran.
 *
 * Deliberately NOT here — Render's own failure email is their only watcher:
 *  - ev-jobs-trivia-election-detection: writes nothing on a day with zero races.
 *  - ev-jobs-legiscan: writes only when a state's dataset changed; out of session that
 *    can be weeks, so a staleness rule would cry wolf.
 */
const RENDER_PROOFS: Array<{ job: string; maxAgeMinutes: number; sql: string }> = [
  {
    job: 'ev-jobs-fec-burst',
    maxAgeMinutes: 48 * HOURS,
    sql: `SELECT max(completed_at) AS newest FROM transparent_motivations.ingestion_runs
          WHERE adapter_name = 'fec' AND status IN ('completed', 'completed_with_warning')
            AND started_at > now() - interval '60 days'`,
  },
  {
    job: 'ev-jobs-trivia-pipeline',
    maxAgeMinutes: 48 * HOURS,
    sql: `SELECT max(created_at) AS newest FROM trivia.generation_jobs`,
  },
  {
    // Advances on an unchanged (304) day too: markNotModified sets last_sync_at.
    job: 'ev-jobs-cal-access (cal-access)',
    maxAgeMinutes: 48 * HOURS,
    sql: `SELECT max(last_sync_at) AS newest FROM transparent_motivations.data_source_metadata
          WHERE source_system = 'cal_access_zip_etag'`,
  },
  {
    // The Indiana download is unconditional, so its per-year ETag row is written every run.
    job: 'ev-jobs-cal-access (indiana)',
    maxAgeMinutes: 48 * HOURS,
    sql: `SELECT max(last_sync_at) AS newest FROM transparent_motivations.data_source_metadata
          WHERE source_system LIKE 'indiana_zip_etag_%'`,
  },
  {
    job: 'ev-jobs-la-county-netfile',
    maxAgeMinutes: 40 * DAYS,
    sql: `SELECT max(completed_at) AS newest FROM transparent_motivations.ingestion_runs
          WHERE adapter_name = 'la_county_netfile' AND status = 'completed'`,
  },
  {
    job: 'ev-jobs-ocpf',
    maxAgeMinutes: 40 * DAYS,
    sql: `SELECT max(completed_at) AS newest FROM transparent_motivations.ingestion_runs
          WHERE adapter_name = 'ocpf' AND status = 'completed'`,
  },
];

export interface JobHealthResult {
  problems: Problem[];
  lines: string[];
  emailed: boolean;
}

/**
 * Run every check; email once if anything is wrong.
 * JOB_HEALTH_STALE_OVERRIDE_MINUTES (testing only) replaces every staleness threshold.
 * Throws if there are problems and the email could not be sent — an alarm that cannot
 * ring must fail loudly in the job log.
 */
export async function runJobHealthCheck(): Promise<JobHealthResult> {
  const now = new Date();
  const overrideRaw = process.env.JOB_HEALTH_STALE_OVERRIDE_MINUTES;
  const staleOverrideMinutes = overrideRaw ? Number(overrideRaw) : undefined;
  if (staleOverrideMinutes !== undefined && !(staleOverrideMinutes > 0)) {
    throw new Error(`JOB_HEALTH_STALE_OVERRIDE_MINUTES must be a positive number, got "${overrideRaw}"`);
  }

  const pgCron = (await pool.query<PgCronRow>(`SELECT * FROM ops.pg_cron_health()`)).rows;
  const http = (await pool.query<HttpRow>(`SELECT * FROM ops.http_trigger_health()`)).rows;
  const stranded = (
    await pool.query<StrandedRow>(
      `SELECT adapter_name, count(*)::int AS runs, min(started_at) AS oldest_start
       FROM transparent_motivations.ingestion_runs
       WHERE status = 'running' AND started_at < now() - interval '24 hours'
       GROUP BY adapter_name ORDER BY adapter_name`,
    )
  ).rows;
  const proofs: ProofRow[] = [];
  for (const p of RENDER_PROOFS) {
    const { rows } = await pool.query<{ newest: Date | null }>(p.sql);
    proofs.push({ job: p.job, newest: rows[0]?.newest ?? null, maxAgeMinutes: p.maxAgeMinutes });
  }

  const problems = evaluate({ now, pgCron, proofs, http, stranded, staleOverrideMinutes });
  const lines = problems.map((p) => formatProblemLine(p, now));
  console.info(
    `[job-health] checked ${pgCron.length} pg_cron jobs, ${proofs.length} Render proofs` +
      `${staleOverrideMinutes !== undefined ? ` (TEST: stale after ${staleOverrideMinutes}m)` : ''}` +
      ` — ${problems.length} problem(s)`,
  );
  for (const line of lines) console.warn(`[job-health] ${line}`);

  if (problems.length === 0) return { problems, lines, emailed: false };

  const to = process.env.JOB_HEALTH_ALERT_TO || process.env.ADMIN_EMAIL;
  if (!to) throw new Error('[job-health] problems found but neither JOB_HEALTH_ALERT_TO nor ADMIN_EMAIL is set');

  const subject =
    `${staleOverrideMinutes !== undefined ? '[TEST] ' : ''}` +
    `Scheduled jobs: ${problems.length} problem${problems.length === 1 ? '' : 's'}`;
  const sent = await sendEmail({ to, subject, html: renderEmail(lines, now, staleOverrideMinutes) });
  if (!sent) throw new Error(`[job-health] ${problems.length} problem(s) found but the alert email was not sent`);
  console.info(`[job-health] alert emailed to ${to}`);
  return { problems, lines, emailed: true };
}

const escapeHtml = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function renderEmail(lines: string[], now: Date, staleOverrideMinutes?: number): string {
  const test =
    staleOverrideMinutes !== undefined
      ? `<p><strong>TEST RUN:</strong> every staleness threshold was set to ${staleOverrideMinutes} minute(s), so healthy jobs are listed too.</p>`
      : '';
  return `${test}<p>The daily job-health check (${now.toISOString()}) found:</p>
<ul>${lines.map((l) => `<li>${escapeHtml(l)}</li>`).join('\n')}</ul>
<p>Where to look: pg_cron jobs in <code>cron.job_run_details</code>; Render cron jobs in the
Render dashboard run history; proof-of-run signals in <code>docs/JOB-API-SPLIT.md</code>
(ev-accounts).</p>`;
}
