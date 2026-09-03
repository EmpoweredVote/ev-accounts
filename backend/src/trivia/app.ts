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
// NOT folded in Phase 1: CTC's cron scheduler (expiration sweep, election detection,
// pipeline). The old civic-trivia-backend keeps running during the parallel window and
// owns those jobs; running them here too would double-execute them. They transfer when
// the old service is retired (gate G6). cron/electionDetection.ts is present only
// because routes/admin.ts reads its `lastCronRun` value; it schedules nothing on import.

import { storageFactory } from './config/redis.js';
import { initializeSessionManager } from './services/sessionService.js';

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
