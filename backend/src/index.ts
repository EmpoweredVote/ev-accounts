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
import empowerRouter from './routes/empower.js';
import gemsRouter from './routes/gems.js';
import profileRouter from './routes/profile.js';
import xpRouter from './routes/xp.js';
import rolesRouter from './routes/roles.js';
import socialRouter from './routes/social.js';
import adminRouter from './routes/admin.js';
import candidatesRouter from './routes/candidates.js';
import essentialsCandidatesRouter from './routes/essentialsCandidates.js';
import essentialsPoliticiansRouter from './routes/essentialsPoliticians.js';
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
app.use('/api/empower', empowerRouter);
app.use('/api/gems', gemsRouter);
app.use('/api/xp', xpRouter);
app.use('/api/roles', rolesRouter);
app.use('/api/social', socialRouter);
app.use('/api/admin', adminRouter);
app.use('/api/candidates', candidatesRouter);
app.use('/api/essentials/candidates', essentialsCandidatesRouter);
app.use('/api/essentials/politicians', essentialsPoliticiansRouter);

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
