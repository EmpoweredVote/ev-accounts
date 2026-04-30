import 'dotenv/config'; // Must be first import
import { env } from './lib/env.js'; // Validates env vars — exits if invalid
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import healthRouter from './routes/health.js';
import authRouter from './routes/auth.js';
import accountRouter from './routes/account.js';
import invitesRouter from './routes/invites.js';
import connectRouter from './routes/connect.js';
import compassRouter from './routes/compass.js';
import compassAdminRouter from './routes/compassAdmin.js';
import topicRewritesRouter from './routes/topicRewrites.js';
import compassContributorRouter from './routes/compassContributor.js';
import empowerRouter from './routes/empower.js';
import gemsRouter from './routes/gems.js';
import vqRouter from './routes/vq.js';
import profileRouter from './routes/profile.js';
import xpRouter from './routes/xp.js';
import referralRouter from './routes/referral.js';
import rolesRouter from './routes/roles.js';
import contributorRouter from './routes/contributor.js';
import socialRouter from './routes/social.js';
import adminRouter from './routes/admin.js';
import essentialsDiscoveryRouter from './routes/essentialsDiscovery.js';
import stagingQueueAdminRouter from './routes/stagingQueueAdmin.js';
import discoveryDashboardRouter from './routes/discoveryDashboard.js';
import candidatesRouter from './routes/candidates.js';
import essentialsCandidatesRouter from './routes/essentialsCandidates.js';
import essentialsEditorRouter from './routes/essentialsEditor.js';
import essentialsPoliticiansRouter from './routes/essentialsPoliticians.js';
import essentialsRouter from './routes/essentials.js';
import essentialsBrowseRouter from './routes/essentialsBrowse.js';
import essentialsBodiesRouter from './routes/essentialsBodies.js';
import essentialsIngestRouter from './routes/essentialsIngest.js';
import treasuryRouter from './routes/treasury.js';
import campaignFinanceRouter from './routes/campaignFinance.js';
import campaignFinanceAdminRouter, { batchIngestHandler } from './routes/campaignFinanceAdmin.js';
import { requireAdminToken } from './middleware/adminTokenAuth.js';
import { requireAuth } from './middleware/auth.js';
import { requireAdmin } from './middleware/requireAdmin.js';
import meetingsRouter from './routes/meetings.js';
import stagingRouter from './routes/staging.js';
import triviaRouter from './routes/trivia.js';
import feedbackRouter from './routes/feedback.js';
import { startCalibrationLapseCron } from './cron/calibrationLapse.js';
import { startCampaignFinanceCron } from './cron/campaignFinanceCron.js';
import { startDistrictStalenessCron } from './cron/districtStaleness.js';
import { startDiscoverySweepCron } from './cron/discoverySweep.js';
import { campaignFinanceInit } from './lib/campaignFinanceService.js';
import { startSqsWorker } from './lib/campaignFinanceScheduler.js';

const app = express();

// Trust Render's proxy so express-rate-limit can read X-Forwarded-For correctly
app.set('trust proxy', 1);

app.use(helmet());
app.use(cookieParser());

const allowedOrigins = env.CORS_ORIGIN
  ? env.CORS_ORIGIN.split(',').map((o) => o.trim())
  : [];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow same-origin / server-to-server (no Origin header)
      if (!origin) return callback(null, true);
      // Dev: allow any origin (Vite proxy + cross-origin testing)
      if (env.NODE_ENV === 'development') return callback(null, true);
      // Prod: exact-match against CORS_ORIGIN list
      if (allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error(`CORS: origin ${origin} not allowed`));
    },
    credentials: true,
    exposedHeaders: ['X-Data-Updated-At', 'X-Data-Status', 'X-Formatted-Address'],
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
app.use('/api/compass', compassContributorRouter);
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
app.use('/api/contributor', contributorRouter);
app.use('/api/social', socialRouter);
// JWT-gated staging review endpoints for the browser admin UI (STAG-06).
// Auth is applied per-route inside stagingQueueAdmin.ts (not at mount) so that
// X-Admin-Token requests to /discover/* fall through to essentialsDiscoveryRouter below.
app.use('/api/admin', stagingQueueAdminRouter);
// JWT-gated discovery dashboard read endpoints for the browser admin UI (Phase 8).
// Auth is applied per-route inside discoveryDashboard.ts (not at mount).
// Must be mounted BEFORE essentialsDiscoveryRouter so JWT-authenticated GETs are
// handled here and do not fall through to the X-Admin-Token route layer.
app.use('/api/admin', discoveryDashboardRouter);
// Discovery routes use X-Admin-Token (not JWT). Auth is applied inside the router
// via router.use(requireAdminToken) — NOT at mount — so it doesn't bleed into other
// /api/admin/* routers that share the same prefix.
app.use('/api/admin', essentialsDiscoveryRouter);
app.use('/api/admin', adminRouter);
app.use('/api/admin/topic-rewrites', topicRewritesRouter);
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
// NOTE: /candidates, /politicians, /browse mounts must come BEFORE /essentials to prevent path capture
app.use('/api/essentials/ingest', essentialsIngestRouter);
app.use('/api/essentials/browse', essentialsBrowseRouter);
app.use('/api/essentials/bodies', essentialsBodiesRouter);
app.use('/api/essentials/candidates', essentialsCandidatesRouter);
// Dual-router pattern: PATCH (essentialsEditorRouter) before GET (essentialsPoliticiansRouter)
app.use('/api/essentials/politicians', essentialsEditorRouter);
app.use('/api/essentials/politicians', essentialsPoliticiansRouter);
app.use('/api/essentials', essentialsRouter);
app.use('/api/treasury', treasuryRouter);
app.use('/api/campaign-finance', campaignFinanceRouter);
// Dual-router pattern for campaign finance: public reads on campaignFinanceRouter,
// admin CRUD + ingest triggers on campaignFinanceAdminRouter (both at /api/campaign-finance).
app.use('/api/campaign-finance', campaignFinanceAdminRouter);
// Batch ingest trigger: registered directly on app — path is /admin/ingest/:adapter
// (no /api/campaign-finance prefix). Auth via X-Admin-Token (not JWT).
// Used by SQS workers, EventBridge, curl, and manual one-off triggers.
app.post('/admin/ingest/:adapter', requireAdminToken, batchIngestHandler);
app.use('/api/meetings', meetingsRouter);
app.use('/api/staging', stagingRouter);
app.use('/api/trivia', triviaRouter); // Trivia leaderboard (Phase 41)
app.use('/api/feedback', feedbackRouter); // Feedback pipeline (quick-260428-fp1)

export { app }; // For testing

const port = parseInt(env.PORT, 10);

const isLambda = !!process.env.AWS_LAMBDA_FUNCTION_NAME;

if (env.NODE_ENV !== 'test' && !isLambda) {
  void (async () => {
    // Non-fatal startup check — pg-pool can timeout intermittently at deploy time.
    // A timeout here must not prevent the server from starting.
    try {
      await campaignFinanceInit();
    } catch (e) {
      console.warn('[startup] campaign-finance schema unreachable — continuing anyway:', e);
    }

    const server = app.listen(port, () => {
      console.info(`[server] listening on port ${port}`);
      console.info(`[server] environment: ${env.NODE_ENV}`);
    });
    startCalibrationLapseCron();
    startCampaignFinanceCron();
    startDistrictStalenessCron();
    startDiscoverySweepCron();   // Phase 7 — weekly candidate discovery sweep
    startSqsWorker();

    // Graceful shutdown — Render sends SIGTERM before replacing instances.
    // Without this, the pg pool and cron job keep the event loop alive and
    // Render marks deploys as "Timed Out" after the grace period.
    process.once('SIGTERM', () => {
      server.close(() => process.exit(0));
    });
  })();
}
