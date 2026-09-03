// Validation Quests (VQ) sub-app — folded into the engine (engine consolidation,
// Phase 2). This module is the single seam between the engine and the ported VQ
// backend under ./ (routes/, services/, lib/, middleware/, types/).
//
// It is mounted by src/index.ts under BOTH shapes:
//   /vq/api/...       — byte-for-byte alias of the old empowered-validation-quests
//                       paths (its frontend does `${BASE_URL}${path}` with
//                       path=`/api/quests/…`), so the VQ frontend cuts over with one
//                       env var + rebuild and rolls back the same way.
//   /api/vq/...       — the tidy engine-native paths (adopted after the old service
//                       is retired). These do not collide with the engine's existing
//                       /api/vq router (/confirm-stance, /adjust-vr, both literal),
//                       which stays mounted ahead of this one.
//
// Unlike CTC, VQ has no pg pool and no session store — it talks to Postgres only
// through @supabase/supabase-js (PostgREST), targeting the validation_quests / connect
// / empower schemas with the SAME service-role and anon keys the engine already holds,
// so there is no boot init and no schema grant to apply. VQ's own dual-issuer auth
// (middleware/auth.ts here) is kept as-is; the engine's middleware/auth.ts is untouched.
//
// VQ's cron scheduler (consensus every 5 min, rotation daily) IS now folded in, but gated
// OFF behind VQ_CRONS_ENABLED (see startVqCrons below): the standalone service still owns
// them during the parallel window, so running them here too would double-execute. Its
// finalization callbacks (confirm-stance, adjust-vr, xp) run in-process — no service key.
// VQ's BullMQ worker was never deployed and is not folded (G4).

import { Router, type Request, type Response, type NextFunction } from 'express';
import { logger } from './lib/logger.js';
import healthRouter from './routes/health.js';
import questsRouter from './routes/quests.js';
import submissionsRouter from './routes/submissions.js';
import feedRouter from './routes/feed.js';
import historyRouter from './routes/history.js';
import transparencyRouter from './routes/transparency.js';
import contestsRouter from './routes/contests.js';
import notificationsRouter from './routes/notifications.js';
import notificationPreferencesRouter from './routes/notificationPreferences.js';
import profileRouter from './routes/profile.js';
import adminRouter from './routes/admin.js';
import { startConsensusScheduler, startRotationScheduler } from './scheduler.js';

export const validationQuestsRouter = Router();

// Mount order is preserved verbatim from the standalone service's index.ts and is
// LOAD-BEARING: transparency shares the /quests prefix with quests (so it must come
// after quests), and notifications/preferences must be registered before notifications
// or /preferences would be captured as a notifications sub-path.
//
// Sub-paths are relative to the mount (/vq/api or /api/vq). health.ts owns `/health`,
// so mounting it at `/` yields {mount}/health — matching the old /api/health.
validationQuestsRouter.use('/', healthRouter);
validationQuestsRouter.use('/quests', questsRouter);
validationQuestsRouter.use('/submissions', submissionsRouter);
validationQuestsRouter.use('/feed', feedRouter);
validationQuestsRouter.use('/history', historyRouter);
validationQuestsRouter.use('/quests', transparencyRouter);
validationQuestsRouter.use('/contests', contestsRouter);
validationQuestsRouter.use('/notifications/preferences', notificationPreferencesRouter);
validationQuestsRouter.use('/notifications', notificationsRouter);
validationQuestsRouter.use('/profile', profileRouter);
validationQuestsRouter.use('/admin', adminRouter);

// VQ's own error handler (from its index.ts), scoped to VQ routes via this router so it
// returns VQ's JSON error shape ({ error: 'Internal server error' }) without adding a
// global error handler to the engine.
/**
 * Start VQ's cron jobs (consensus every 5 min, quest rotation daily 04:00 UTC) — but ONLY
 * when VQ_CRONS_ENABLED === 'true'. They are OFF by default because the standalone
 * empowered-validation-quests service still runs them during the parallel window; running
 * them here too would double-execute (double consensus writes, double rotation). Flip the
 * flag on at the same moment the old service is retired (gate G7). The consensus job's
 * finalization callbacks now run in-process (see jobs/consensusBatchJob.ts) — no service key.
 */
export function startVqCrons(): void {
  if (process.env.VQ_CRONS_ENABLED !== 'true') {
    console.info(
      '[vq] crons disabled (set VQ_CRONS_ENABLED=true to run them here) — the standalone service still owns them during the parallel run'
    );
    return;
  }
  startConsensusScheduler();
  startRotationScheduler();
  console.info('[vq] consensus + rotation crons started in-engine');
}

validationQuestsRouter.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});
