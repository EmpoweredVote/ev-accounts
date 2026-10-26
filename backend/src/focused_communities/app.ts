// Focused Communities sub-app — folded into the engine (engine consolidation; same shape as
// src/civic_spaces/ and src/vq/app.ts). The single seam between the engine and the ported
// Focused Communities backend under ./.
//
// Mounted by src/index.ts under BOTH shapes, like VQ:
//   /fc/api/...   — byte-for-byte alias of the old focused-communities service paths. Its
//                   frontend does `${VITE_API_BASE_URL}${path}` with path=`/api/communities…`,
//                   so it cuts over by building with VITE_API_BASE_URL=<engine>/fc.
//   /api/fc/...   — the tidy engine-native paths.
//
// What changed from the standalone, deliberately:
//   - DB: a dedicated least-privilege pg role (config/database.ts, migration CA_0323) instead
//     of the broad service_role key; supabase-js queries ported to parameterised SQL.
//   - Auth: the engine's requireAuth + in-process getAccountMe (middleware/auth.ts) instead of
//     a second dual-issuer verifier and an HTTP call to /api/account/me.
//   - Cache: the engine's shared cache instead of a second Upstash client.
//   - The standalone also served the React build from the same process; the frontend is now a
//     free static site, so nothing here serves HTML.
// No background work: every route is request/reply, so nothing goes in jobs/registry.ts and all
// of it is served under EV_ROLE=api.

import { Router, type Request, type Response, type NextFunction } from 'express';
import { healthRouter } from './routes/health.js';
import { communitiesRouter } from './routes/communities.js';
import { stancesRouter } from './routes/stances.js';
import { threadsRouter } from './routes/threads.js';
import { postsRouter } from './routes/posts.js';
import { usersRouter } from './routes/users.js';

export const focusedCommunitiesRouter = Router();

// Same order as the standalone's createApp().
focusedCommunitiesRouter.use(healthRouter);
focusedCommunitiesRouter.use(communitiesRouter);
focusedCommunitiesRouter.use(stancesRouter);
focusedCommunitiesRouter.use(threadsRouter);
focusedCommunitiesRouter.use(postsRouter);
focusedCommunitiesRouter.use(usersRouter);

// The standalone's global error handler, scoped to these routes.
focusedCommunitiesRouter.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error('[focused_communities] error:', err.message);
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    },
  });
});
