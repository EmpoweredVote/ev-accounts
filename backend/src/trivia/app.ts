// Civic Trivia Championships (CTC) sub-app — folded into the engine (engine
// consolidation, Phase 1). This module is the single seam between the engine and the
// ported CTC backend under ./ (routes/, services/, config/, db/, middleware/).
//
// The six routers are mounted by src/index.ts under BOTH shapes:
//   /ctc/api/...      — byte-for-byte alias of the old civic-trivia-backend paths;
//                       the CTC frontend cuts over to these with one env var + rebuild.
//   /api/trivia/...   — the tidy engine-native paths (adopted in Phase 1c, after the
//                       old service is retired).
//
// CTC's own auth (middleware/auth.ts) and data access (its own pg pool with
// search_path=trivia, and its own supabaseAdmin over PostgREST/public) are kept
// unchanged so behaviour is identical to the standalone service. The engine's
// middleware/auth.ts is NOT touched.
//
// CTC's cron scheduler (expiration sweep hourly, election detection daily 06:00 ET,
// pipeline daily 02:00 ET) IS now folded in, but gated OFF behind TRIVIA_CRONS_ENABLED
// (see startTriviaCrons below): the standalone civic-trivia-backend still owns them during
// the parallel window, so running them here too would double-execute (double expiration
// writes, double generation spend). Flip the flag on at the same moment the old service is
// retired (gate G6). cron/electionDetection.ts already carries the real side-effecting
// runElectionDetection AND the lastCronRun value routes/admin.ts reads; importing it still
// schedules nothing on its own.

import { storageFactory } from './config/redis.js';
import { initializeSessionManager } from './services/sessionService.js';
import {
  startExpirationCron,
  startElectionDetectionCron,
  startPipelineCron,
} from './cron/startCron.js';

export { router as ctcGameRouter } from './routes/game.js';
export { router as ctcProfileRouter } from './routes/profile.js';
export { router as ctcHealthRouter } from './routes/health.js';
export { router as ctcAdminRouter } from './routes/admin.js';
export { default as ctcFeedbackRouter } from './routes/feedback.js';
export { router as ctcLeaderboardRouter } from './routes/leaderboard.js';

/**
 * Perform CTC's boot sequence: bring up the session storage backend (Redis via
 * TRIVIA_REDIS_URL, or in-memory fallback) and initialise the session manager the
 * game routes depend on. Mirrors what the standalone server.ts did before app.listen.
 * Safe to call once at engine startup. Never throws on missing Redis — it degrades.
 */
export async function initTrivia(): Promise<void> {
  await storageFactory.initialize();
  initializeSessionManager(storageFactory.getStorage());
  console.info(
    `[trivia] session storage: ${storageFactory.isDegradedMode() ? 'in-memory (TRIVIA_REDIS_URL unset or unreachable)' : 'redis'}`
  );
}

/**
 * Start CTC's cron jobs — but ONLY when TRIVIA_CRONS_ENABLED === 'true'. They are OFF by
 * default because the standalone civic-trivia-backend service still runs them during the
 * parallel window; running them here too would double-execute (double expiration/archival
 * writes, double election + pipeline generation spend). Flip the flag on at the same moment
 * the old service is retired (gate G6). Schedules and timezones are preserved verbatim from
 * the standalone service:
 *   - expiration sweep: hourly at :00
 *   - election detection: daily 06:00 America/New_York
 *   - pipeline: daily 02:00 America/New_York
 */
export function startTriviaCrons(): void {
  if (process.env.TRIVIA_CRONS_ENABLED !== 'true') {
    console.info(
      '[trivia] crons disabled (set TRIVIA_CRONS_ENABLED=true to run them here) — the standalone service still owns them during the parallel run'
    );
    return;
  }
  startExpirationCron();
  startElectionDetectionCron();
  startPipelineCron();
  console.info('[trivia] expiration + election-detection + pipeline crons started in-engine');
}
