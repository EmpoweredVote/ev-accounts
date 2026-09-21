/**
 * internalJobs — HTTP trigger for background jobs, for a scheduler that cannot exec a
 * Node CLI.
 *
 * Part of the job/API split Move 2 (ev-cto decision 0002 / hosting-decision-followup
 * step 5). The heavy/long jobs run as Render cron services that invoke
 * `node dist/jobs/run.js <name>` directly. The light/frequent jobs run from Supabase Cron,
 * which can only run SQL or make an HTTP call (via pg_net) — it cannot start a Node
 * process. This route is that HTTP entry point: it runs the SAME registry job the CLI
 * runner (src/jobs/run.ts) and the in-process cron call, so behaviour and DB writes are
 * identical.
 *
 *   POST /internal/jobs/:name      (header: X-Admin-Token: <ADMIN_INGEST_TOKEN>)
 *
 * Auth: requireAdminToken — the existing pre-shared machine token. ADMIN_INGEST_TOKEN is a
 * REQUIRED env var (see src/lib/env.ts), so it is always set in production; this route adds
 * no new secret. Same trust class as POST /admin/ingest/:adapter, and callable by Supabase
 * Cron / curl without a user session.
 *
 * Fire-and-forget: the route returns 202 immediately and the job continues in the
 * background. pg_net does not wait on the response body, and each job's success is observed
 * through its durable "proof it ran" signal (the manifest in docs/JOB-API-SPLIT.md), not
 * through this HTTP response. A per-process guard rejects a second start of the same job
 * with 409 while the first is still running — this instance never runs the same job twice
 * at once. (Cross-instance serialisation is out of scope until a second API copy exists;
 * that is on the "blocks two copies" list in docs/JOB-API-SPLIT.md.)
 *
 * IMPORTANT: this router imports the JOBS registry, which pulls in the job libraries. Do
 * NOT import this module from anything that must stay registry-free (e.g. the unit-test
 * import chain — see docs/JOB-API-SPLIT.md "Verification").
 */
import { Router, Request, Response } from 'express';
import { requireAdminToken } from '../middleware/adminTokenAuth.js';
import { JOBS, JOB_NAMES } from '../jobs/registry.js';

const router = Router();

/** Jobs currently running in THIS process — guards against an overlapping start. */
const inFlight = new Set<string>();

/**
 * POST /internal/jobs/:name — start one registered job by name.
 *   202 { status: 'started' }        — accepted, running in the background
 *   409 { status: 'already-running' } — this instance is already running that job
 *   404 { error: 'unknown job' }      — name not in the registry
 *   401                               — missing/incorrect X-Admin-Token (requireAdminToken)
 */
router.post('/jobs/:name', requireAdminToken, (req: Request, res: Response): void => {
  const name = req.params.name as string;
  const job = JOBS[name];

  if (!job) {
    res.status(404).json({ error: 'unknown job', job: name, available: JOB_NAMES });
    return;
  }

  if (inFlight.has(name)) {
    res.status(409).json({ status: 'already-running', job: name });
    return;
  }

  inFlight.add(name);
  const startedAt = Date.now();
  console.info(`[internal-jobs] running "${name}"`);

  // Fire-and-forget: respond now, run in the background. Errors are logged, never rethrown
  // — an unhandled rejection here would be an unrelated job taking down the login API.
  void (async () => {
    try {
      await job();
      console.info(`[internal-jobs] "${name}" completed in ${Date.now() - startedAt}ms`);
    } catch (err) {
      console.error(`[internal-jobs] "${name}" failed after ${Date.now() - startedAt}ms:`, err);
    } finally {
      inFlight.delete(name);
    }
  })();

  res.status(202).json({ status: 'started', job: name });
});

export default router;
