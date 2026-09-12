/**
 * run.ts — per-job entry point for the job/API split (ev-cto decision 0002).
 *
 *   node dist/jobs/run.js <job-name>
 *
 * Runs EXACTLY ONE named job to completion, then exits:
 *   exit 0 — job completed
 *   exit 1 — job threw
 *   exit 2 — unknown or missing job name
 *
 * It binds no HTTP port and registers no cron. The schedule lives in the platform
 * (Render cron / Supabase Cron). Model: src/lambda/cron-*.ts — a thin wrapper over a
 * lib run-function.
 *
 * IMPORTANT: this file MUST NOT import ./index.js — that boots the Express server. It
 * imports only ./registry.js, which imports only the individual job libraries. That is
 * what keeps a job run from ever opening a listener.
 */
import 'dotenv/config'; // Load .env exactly as src/index.ts does, before anything reads env.
import { JOBS, JOB_NAMES } from './registry.js';

async function main(): Promise<void> {
  const name = process.argv[2];
  const job = name ? JOBS[name] : undefined;

  if (!job) {
    console.error(`[jobs] unknown job: ${name ?? '(none given)'}`);
    console.error('[jobs] usage: node dist/jobs/run.js <job-name>');
    console.error(`[jobs] available: ${JOB_NAMES.join(', ')}`);
    process.exit(2);
  }

  console.info(`[jobs] running "${name}"`);
  const startedAt = Date.now();
  try {
    await job();
    console.info(`[jobs] "${name}" completed in ${Date.now() - startedAt}ms`);
    process.exit(0);
  } catch (err) {
    console.error(`[jobs] "${name}" failed after ${Date.now() - startedAt}ms:`, err);
    process.exit(1);
  }
}

void main();
