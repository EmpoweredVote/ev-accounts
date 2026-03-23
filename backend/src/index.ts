process.stdout.write('[startup] index.ts loading\n'); // Diagnostic: confirm process starts
import 'dotenv/config'; // Must be first import
import { env } from './lib/env.js'; // Validates env vars — exits if invalid
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import healthRouter from './routes/health.js';
import authRouter from './routes/auth.js';
import accountRouter from './routes/account.js';
import invitesRouter from './routes/invites.js';
import connectRouter from './routes/connect.js';
import compassRouter from './routes/compass.js';
import compassAdminRouter from './routes/compassAdmin.js';
import empowerRouter from './routes/empower.js';
import gemsRouter from './routes/gems.js';
import vqRouter from './routes/vq.js';
import profileRouter from './routes/profile.js';
import xpRouter from './routes/xp.js';
import referralRouter from './routes/referral.js';
import rolesRouter from './routes/roles.js';
import socialRouter from './routes/social.js';
import adminRouter from './routes/admin.js';
import candidatesRouter from './routes/candidates.js';
import essentialsCandidatesRouter from './routes/essentialsCandidates.js';
import essentialsPoliticiansRouter from './routes/essentialsPoliticians.js';
import essentialsRouter from './routes/essentials.js';
import treasuryRouter from './routes/treasury.js';
import meetingsRouter from './routes/meetings.js';
import stagingRouter from './routes/staging.js';
import { startCalibrationLapseCron } from './cron/calibrationLapse.js';

const app = express();

// Trust Render's proxy so express-rate-limit can read X-Forwarded-For correctly
app.set('trust proxy', 1);

app.use(helmet());
app.use(
  cors({
    origin:
      env.NODE_ENV === 'development'
        ? '*'
        : env.CORS_ORIGIN
          ? env.CORS_ORIGIN.split(',').map((o) => o.trim())
          : [],
  })
);
app.use(express.json());

// Routes
app.use('/api/health', healthRouter);
app.use('/api/auth', authRouter);
app.use('/api/account/profile', profileRouter);
app.use('/api/account', accountRouter);
app.use('/api/invites', invitesRouter);
app.use('/api/connect', connectRouter);
app.use('/api/compass', compassRouter);
// Dual-router pattern: compassAdminRouter shares the /api/compass prefix with compassRouter.
// Express tries compassRouter first (public routes); admin-only mutations fall through to here.
// No URL+method collisions exist between the two routers.
app.use('/api/compass', compassAdminRouter);
app.use('/api/empower', empowerRouter);
app.use('/api/gems', gemsRouter);
app.use('/api/vq', vqRouter);
app.use('/api/xp', xpRouter);
app.use('/api/referral', referralRouter);
app.use('/api/roles', rolesRouter);
app.use('/api/social', socialRouter);
app.use('/api/admin', adminRouter);
app.use('/api/candidates', candidatesRouter);
// === Essentials Routes (Phase 38 complete — all routes served by ev-accounts, CONS-11 fulfilled) ===
// GET /api/essentials/candidates/:zip
// GET /api/essentials/politicians
// GET /api/essentials/politicians/:id/legislative
// GET /api/essentials/politicians/:id/committees
// GET /api/essentials/politicians/:id/bills
// GET /api/essentials/politicians/:id/votes
// GET /api/essentials/politicians/:id
// GET /api/essentials/address-search
// GET /api/essentials/governments/:id
// GET /api/essentials/chambers/:id
// GET /api/essentials/districts/:id
// NOTE: /candidates and /politicians mounts must come BEFORE /essentials to prevent path capture
app.use('/api/essentials/candidates', essentialsCandidatesRouter);
app.use('/api/essentials/politicians', essentialsPoliticiansRouter);
app.use('/api/essentials', essentialsRouter);
app.use('/api/treasury', treasuryRouter);
app.use('/api/meetings', meetingsRouter);
app.use('/api/staging', stagingRouter);

export { app }; // For testing

const port = parseInt(env.PORT, 10);

if (env.NODE_ENV !== 'test') {
  const server = app.listen(port, () => {
    console.info(`[server] listening on port ${port}`);
    console.info(`[server] environment: ${env.NODE_ENV}`);
  });
  startCalibrationLapseCron();

  // Graceful shutdown — Render sends SIGTERM before replacing instances.
  // Without this, the pg pool and cron job keep the event loop alive and
  // Render marks deploys as "Timed Out" after the grace period.
  process.once('SIGTERM', () => {
    server.close(() => process.exit(0));
  });
}
