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
import sourceVerificationsRouter from './routes/sourceVerifications.js';
import compassContributorRouter from './routes/compassContributor.js';
import compassRevisionsRouter from './routes/compassRevisions.js';
import empowerRouter from './routes/empower.js';
import gemsRouter from './routes/gems.js';
import profileRouter from './routes/profile.js';
import xpRouter from './routes/xp.js';
import referralRouter from './routes/referral.js';
import rolesRouter from './routes/roles.js';
import contributorRouter from './routes/contributor.js';
import socialRouter from './routes/social.js';
import adminRouter from './routes/admin.js';
import seasonsAdminRouter from './routes/seasonsAdmin.js';
import essentialsDiscoveryRouter from './routes/essentialsDiscovery.js';
import stagingQueueAdminRouter from './routes/stagingQueueAdmin.js';
import discoveryDashboardRouter from './routes/discoveryDashboard.js';
import candidatesRouter from './routes/candidates.js';
import essentialsCandidatesRouter from './routes/essentialsCandidates.js';
import essentialsEditorRouter from './routes/essentialsEditor.js';
import essentialsPoliticiansRouter from './routes/essentialsPoliticians.js';
import essentialsRouter from './routes/essentials.js';
import readrankRouter from './routes/readrank.js';
import informRouter from './routes/inform.js';
import readrankQuotesAdminRouter from './routes/readrankQuotesAdmin.js';
import readrankCoverageAdminRouter from './routes/readrankCoverageAdmin.js';
import compassStatsAdminRouter from './routes/compassStatsAdmin.js';
import essentialsBrowseRouter from './routes/essentialsBrowse.js';
import essentialsLocationSearchRouter from './routes/essentialsLocationSearch.js';
import essentialsCoordinateLookupRouter from './routes/essentialsCoordinateLookup.js';
import essentialsBodiesRouter from './routes/essentialsBodies.js';
import treasuryRouter from './routes/treasury.js';
import campaignFinanceRouter from './routes/campaignFinance.js';
import campaignFinanceAdminRouter, { batchIngestHandler } from './routes/campaignFinanceAdmin.js';
import internalJobsRouter from './routes/internalJobs.js';
import councilFilesRouter from './routes/councilFiles.js';
import { requireAdminToken } from './middleware/adminTokenAuth.js';
import { requireAuth } from './middleware/auth.js';
import { requireAdmin } from './middleware/requireAdmin.js';
import meetingsRouter from './routes/meetings.js';
import adminMeetingsRouter from './routes/adminMeetings.js';
import agendaItemsRouter from './routes/agendaItems.js';
import peopleRouter from './routes/people.js';
import searchRouter from './routes/search.js';
import topicsRouter from './routes/topics.js';
import stagingRouter from './routes/staging.js';
import triviaRouter from './routes/trivia.js';
import feedbackRouter from './routes/feedback.js';
import eventsRouter from './routes/events.js';
// Civic Trivia Championships (CTC) sub-app — folded in (engine consolidation, Phase 1).
// See src/trivia/app.ts for the seam and rationale.
import {
  ctcGameRouter,
  ctcProfileRouter,
  ctcHealthRouter,
  ctcAdminRouter,
  ctcFeedbackRouter,
  ctcLeaderboardRouter,
  initTrivia,
  startTriviaCrons,
} from './trivia/app.js';
// Validation Quests (VQ) sub-app — folded in (engine consolidation, Phase 2).
// See src/vq/app.ts for the seam and rationale.
import { validationQuestsRouter, startVqCrons } from './vq/app.js';
import { startCalibrationLapseCron } from './cron/calibrationLapse.js';
import { startCampaignFinanceCron } from './cron/campaignFinanceCron.js';
import { startDistrictStalenessCron } from './cron/districtStaleness.js';
import { startReapStaleRunsCron } from './cron/reapStaleRuns.js';
import { reapStaleIngestionRuns } from './lib/reapStaleIngestionRuns.js';
import { startDiscoverySweepCron } from './cron/discoverySweep.js';
import { campaignFinanceInit } from './lib/campaignFinanceService.js';
import { startSqsWorker } from './lib/campaignFinanceScheduler.js';
import { maybeResumeBackfillOnBoot } from './lib/fecBackfill.js';
import { maybeResumeFecBurstOnBoot } from './lib/fecBurstResume.js';

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
      // Disallowed origin: respond WITHOUT CORS headers so the browser blocks
      // it client-side. Passing an Error here surfaced as a 500 (including on
      // OPTIONS preflights, e.g. an app loaded via its onrender.com URL); a
      // clean rejection blocks cross-origin access without the 500 noise.
      console.warn('[cors] blocked origin:', origin);
      callback(null, false);
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
app.use('/api/compass/revisions', compassRevisionsRouter);
app.use('/api/compass', compassContributorRouter);
app.use('/api/compass', compassRouter);
// Dual-router pattern: compassAdminRouter shares the /api/compass prefix with compassRouter.
// Express tries compassRouter first (public routes); admin-only mutations fall through to here.
// No URL+method collisions exist between the two routers.
app.use('/api/compass', compassAdminRouter);
app.use('/api/empower', empowerRouter);
app.use('/api/gems', gemsRouter);
app.use('/api/xp', xpRouter);
app.use('/api/referral', referralRouter);
app.use('/api/roles', rolesRouter);
app.use('/api/contributor', contributorRouter);
app.use('/api/social', socialRouter);
// Season composition (reviewer-gated). Mounted before the bare /api/admin
// routers so nothing generic can shadow /api/admin/seasons/*.
app.use('/api/admin/seasons', seasonsAdminRouter);
// Project-2 House-floor review panel (authenticated). Mounted before the bare
// /api/admin routers so the specific prefix is not shadowed.
app.use('/api/admin/meetings', adminMeetingsRouter);
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
app.use('/api/admin/source-verifications', sourceVerificationsRouter);
app.use('/api/admin/readrank-quotes', readrankQuotesAdminRouter);
app.use('/api/admin/readrank-coverage', readrankCoverageAdminRouter);
app.use('/api/admin/compass-stats', compassStatsAdminRouter);
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
app.use('/api/essentials/browse', essentialsBrowseRouter);
app.use('/api/essentials/bodies', essentialsBodiesRouter);
// Phase 212-05: place-name resolver + national-fallback floor. Must be
// mounted BEFORE the '/api/essentials' catch-all (essentialsRouter, below)
// so '/api/essentials/location-search' and its '/resolve' sub-route are not
// swallowed by that router's own path matching.
app.use('/api/essentials/location-search', essentialsLocationSearchRouter);
// 213-02: anonymous coordinate-lookup — mounted BEFORE the '/api/essentials'
// catch-all (essentialsRouter, below) for the same path-capture reason as
// location-search above.
app.use('/api/essentials/coordinate-lookup', essentialsCoordinateLookupRouter);
app.use('/api/essentials/candidates', essentialsCandidatesRouter);
// Dual-router pattern: PATCH (essentialsEditorRouter) before GET (essentialsPoliticiansRouter)
app.use('/api/essentials/politicians', essentialsEditorRouter);
app.use('/api/essentials/politicians', essentialsPoliticiansRouter);
app.use('/api/essentials', essentialsRouter);
app.use('/api/readrank', readrankRouter);
app.use('/api/inform', informRouter);
app.use('/api/treasury', treasuryRouter);
app.use('/api/campaign-finance', campaignFinanceRouter);
// Dual-router pattern for campaign finance: public reads on campaignFinanceRouter,
// admin CRUD + ingest triggers on campaignFinanceAdminRouter (both at /api/campaign-finance).
app.use('/api/campaign-finance', campaignFinanceAdminRouter);
// Batch ingest trigger: registered directly on app — path is /admin/ingest/:adapter
// (no /api/campaign-finance prefix). Auth via X-Admin-Token (not JWT).
// Used by SQS workers, EventBridge, curl, and manual one-off triggers.
app.post('/admin/ingest/:adapter', requireAdminToken, batchIngestHandler);
// Internal job trigger: POST /internal/jobs/:name (X-Admin-Token). Mounted on the request
// path so it is served under EV_ROLE=api. Lets Supabase Cron — which can only run SQL or
// make an HTTP call (pg_net), never exec a Node CLI — start the light/frequent jobs that the
// per-job runner (dist/jobs/run.js) runs for the Render crons. Job/API split Move 2.
app.use('/internal', internalJobsRouter);
app.use('/api/council-files', councilFilesRouter);
app.use('/api/meetings', meetingsRouter);
app.use('/api/agenda-items', agendaItemsRouter);
app.use('/api/people', peopleRouter);
app.use('/api/search', searchRouter);
app.use('/api/topics', topicsRouter);
app.use('/api/staging', stagingRouter);
app.use('/api/trivia', triviaRouter); // Trivia leaderboard (Phase 41)
app.use('/api/feedback', feedbackRouter); // Feedback pipeline (quick-260428-fp1)
app.use('/api/events', eventsRouter);   // CTA event telemetry

// === Civic Trivia Championships (CTC) — folded in (engine consolidation, Phase 1) ===
// Each router is mounted under BOTH the /ctc/... alias (byte-for-byte with the old
// civic-trivia-backend so the CTC frontend cuts over with one env var) and the tidy
// /api/trivia/... path (adopted in Phase 1c after the old service is retired).
//
// These sub-paths do not collide with the existing triviaRouter above, which only
// serves the literals /api/trivia/collections and /api/trivia/leaderboard-profiles.
// CTC's /health is NOT under /api, so its alias is /ctc/health (tidy: /api/trivia/health).
app.use(['/ctc/api/game', '/api/trivia/game'], ctcGameRouter);
app.use(['/ctc/api/users/profile', '/api/trivia/users/profile'], ctcProfileRouter);
app.use(['/ctc/api/admin', '/api/trivia/admin'], ctcAdminRouter);
app.use(['/ctc/api/feedback', '/api/trivia/feedback'], ctcFeedbackRouter);
app.use(['/ctc/api/leaderboard', '/api/trivia/leaderboard'], ctcLeaderboardRouter);
app.use(['/ctc/health', '/api/trivia/health'], ctcHealthRouter);

// === Validation Quests (VQ) — folded in (engine consolidation, Phase 2) ===
// One parent router (src/vq/app.ts) holds all 11 VQ routers in their load-bearing
// order plus VQ's own error handler, mounted under BOTH the /vq/api alias (byte-for-byte
// with the old service, for a one-env-var frontend cutover) and the tidy /api/vq path.
// Mounted AFTER the engine's own /api/vq router above (line ~124), whose two literal
// routes (/confirm-stance, /adjust-vr) therefore keep precedence; everything else under
// /api/vq falls through to the folded VQ routes.
app.use(['/vq/api', '/api/vq'], validationQuestsRouter);

export { app }; // For testing

const port = parseInt(env.PORT, 10);

const isLambda = !!process.env.AWS_LAMBDA_FUNCTION_NAME;

// EV_ROLE splits what this process does (job/API split — ev-cto decision 0002 /
// hosting-decision-followup step 5). See src/lib/env.ts for the full contract.
//   unset (default) — today's EXACT behaviour: Express + every cron + SQS worker + boot
//                     recovery. This branch is unchanged so nothing breaks until a later
//                     move sets EV_ROLE=api.
//   'api'           — Express only: no crons, no SQS worker, no boot recovery.
//   'worker'        — the SQS ingestion long-poll loop only, no HTTP listener. Kept
//                     because the Lambda SQS event-source mapping is NOT confirmed
//                     deployed (docs/infra/lib/infra-stack.ts is wired by no CI).
// Per-job runs use a separate entry (src/jobs/run.ts) and never reach this file.
const role = env.EV_ROLE;

if (env.NODE_ENV !== 'test' && !isLambda) {
  if (role === 'worker') {
    void (async () => {
      // The worker drains the campaign-finance ingestion queue. Warm the schema
      // (non-fatal) exactly as the always-on process did, then start the loop.
      try {
        await campaignFinanceInit();
      } catch (e) {
        console.warn('[startup] campaign-finance schema unreachable — continuing anyway:', e);
      }
      console.info('[server] EV_ROLE=worker — SQS ingestion worker only; no HTTP listener, no crons, no boot recovery');
      startSqsWorker();
      // A worker binds no port; on SIGTERM just end the process.
      process.once('SIGTERM', () => process.exit(0));
    })();
  } else {
    void (async () => {
      // Non-fatal startup check — pg-pool can timeout intermittently at deploy time.
      // A timeout here must not prevent the server from starting.
      try {
        await campaignFinanceInit();
      } catch (e) {
        console.warn('[startup] campaign-finance schema unreachable — continuing anyway:', e);
      }

      // CTC (trivia) session storage + session manager. Non-fatal: initTrivia degrades to
      // in-memory storage if TRIVIA_REDIS_URL is unset/unreachable, so a Redis blip must
      // not stop the engine from starting.
      try {
        await initTrivia();
      } catch (e) {
        console.warn('[startup] trivia sub-app init failed — continuing anyway:', e);
      }

      const server = app.listen(port, () => {
        console.info(`[server] listening on port ${port}`);
        console.info(`[server] environment: ${env.NODE_ENV}`);
      });

      if (role === 'api') {
        // Requests only. The always-on jobs run from their own entry points now
        // (src/jobs/run.ts, EV_ROLE=worker) — not in the process that serves logins.
        console.info('[server] EV_ROLE=api — serving requests only; no crons, no SQS worker, no boot recovery');
      } else {
        // Default (EV_ROLE unset): today's exact behaviour — every cron + the SQS worker
        // + boot recovery, all in this process.
        startCalibrationLapseCron();
        startCampaignFinanceCron();
        startDistrictStalenessCron();
        startDiscoverySweepCron();   // Phase 7 — weekly candidate discovery sweep
        startReapStaleRunsCron();
        startSqsWorker();
        startVqCrons();  // VQ consensus + rotation — no-op unless VQ_CRONS_ENABLED=true (see vq/app.ts)
        startTriviaCrons();  // CTC expiration + election-detection + pipeline — no-op unless TRIVIA_CRONS_ENABLED=true (see trivia/app.ts)

        // A restart is precisely what strands ingestion_runs rows in 'running' (this
        // service auto-deploys on every push to master, and the FEC burst runs 33+
        // minutes), so sweep once at boot rather than waiting for 05:30. Non-fatal.
        void reapStaleIngestionRuns().catch((e) =>
          console.warn('[startup] stale ingestion-run reap failed — continuing anyway:', e)
        );
        maybeResumeBackfillOnBoot();  // self-heals the FEC historical backfill across dyno restarts (gated by FEC_BACKFILL_AUTORESUME)
        maybeResumeFecBurstOnBoot();  // finishes a DAILY burst this restart cut short (see fecBurstResume.ts)
      }

      // Graceful shutdown — Render sends SIGTERM before replacing instances.
      // Without this, the pg pool and cron job keep the event loop alive and
      // Render marks deploys as "Timed Out" after the grace period.
      process.once('SIGTERM', () => {
        server.close(() => process.exit(0));
      });
    })();
  }
}
