/**
 * registry.ts — the catalogue of background jobs that can run as their OWN process.
 *
 * Part of the job/API split (ev-cto decision 0002 / hosting-decision-followup step 5).
 * The login API (`ev-accounts-api`) used to run every scheduled job in the SAME process
 * that serves logins; that mix blocks a second API copy and caused the 2026-07-22 P1.
 *
 * Each entry maps a stable job name to the SAME run-function the in-process node-cron
 * schedule calls in src/index.ts, so running a job here does EXACTLY what the cron did —
 * no behaviour change, no different DB writes. The schedule itself lives in the platform
 * (Render cron / Supabase Cron), not in this process.
 *
 * This module is deliberately side-effect free (no argv parsing, no process.exit, no
 * listener) so it can be imported and asserted in isolation. The executable wrapper that
 * actually runs a job and exits is src/jobs/run.ts.
 *
 * Deliberately NOT here:
 *  - `discovery-sweep` — default-OFF (DISCOVERY_SWEEP_ENABLED) and on-demand only, so it
 *    has no active schedule to move out.
 *  - the SQS ingestion worker — a long-poll LOOP, not a run-to-completion job; it runs as
 *    `EV_ROLE=worker` (see src/index.ts) until the Lambda SQS event-source mapping is
 *    confirmed live.
 *  - boot-recovery (reap-on-boot, FEC burst/backfill resume) — these exist only because
 *    the always-on API restarts mid-job; once a job owns its own process they are moot.
 *    (`reap-stale-ingestion-runs` is still exposed here for on-demand use.)
 */
import { runCalibrationLapseJob } from '../lib/cronService.js';
import { runFecScheduledJob, runAdapterForAll } from '../lib/campaignFinanceScheduler.js';
import { runDistrictStalenessCheck } from '../lib/districtStalenessService.js';
import { reapStaleIngestionRuns } from '../lib/reapStaleIngestionRuns.js';
import { runConsensusPass } from '../vq/jobs/consensusBatchJob.js';
import { runRotationPass } from '../vq/services/questRotation.js';
import { runExpirationSweep } from '../trivia/cron/expirationSweep.js';
import { runElectionDetection } from '../trivia/cron/electionDetection.js';
import { runPipelineCron } from '../trivia/cron/pipelineCron.js';

export type JobFn = () => Promise<unknown>;

/**
 * Stable job name → run-function. The name is the CLI contract:
 *   node dist/jobs/run.js <name>
 * Keep names kebab-case and stable — a platform schedule (Render cron / Supabase Cron)
 * will reference them by string.
 */
export const JOBS: Record<string, JobFn> = {
  // Core (backend/src/cron/) — the always-on jobs the API ran in-process.
  'calibration-lapse': () => runCalibrationLapseJob(),
  'fec-burst': () => runFecScheduledJob(),
  'la-county-netfile': () => runAdapterForAll('la_county_netfile'),
  'ocpf': () => runAdapterForAll('ocpf'),
  'district-staleness': () => runDistrictStalenessCheck(),
  'reap-stale-ingestion-runs': () => reapStaleIngestionRuns(),
  // Validation Quests (folded in) — no Lambda handler existed, so these are new entries.
  'vq-consensus': () => runConsensusPass(),
  'vq-rotation': () => runRotationPass(),
  // Civic Trivia (folded in) — likewise new entries.
  'trivia-expiration': () => runExpirationSweep(),
  'trivia-election-detection': () => runElectionDetection(),
  'trivia-pipeline': () => runPipelineCron(),
};

/** Sorted job names, for help text and tests. */
export const JOB_NAMES: string[] = Object.keys(JOBS).sort();
