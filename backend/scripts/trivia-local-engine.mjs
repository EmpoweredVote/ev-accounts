// Local in-process stand-in for the merged engine, for pre-deploy parity checking.
// Replicates the engine's GLOBAL middleware chain (index.ts) exactly — trust proxy,
// helmet, cookieParser, cors, express.json — then mounts the six folded CTC routers
// under the same dual prefixes index.ts uses. Boots with DUMMY env so it runs with no
// secrets: auth-gated routes (401) and /health/live (200) behave identically to the
// real engine; the DB-backed public routes cannot connect and will differ (expected).
//
// Usage: node scripts/trivia-local-engine.mjs [port]   (default 3999)
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import cookieParser from 'cookie-parser';

process.env.SUPABASE_URL ||= 'https://dummy.supabase.co';
process.env.SUPABASE_SERVICE_ROLE_KEY ||= 'dummy-service-role-key';
process.env.DATABASE_URL ||= 'postgresql://u:p@127.0.0.1:5432/postgres';
process.env.NODE_ENV ||= 'development';
// TRIVIA_REDIS_URL intentionally unset -> in-memory session storage.

const {
  ctcGameRouter, ctcProfileRouter, ctcHealthRouter,
  ctcAdminRouter, ctcFeedbackRouter, ctcLeaderboardRouter, initTrivia,
} = await import('../dist/trivia/app.js');

const app = express();
app.set('trust proxy', 1);
app.use(helmet());
app.use(cookieParser());
app.use(cors({
  origin: (origin, cb) => cb(null, true), // dev: allow any (matches engine dev behaviour)
  credentials: true,
}));
app.use(express.json());

app.use(['/ctc/api/game', '/api/trivia/game'], ctcGameRouter);
app.use(['/ctc/api/users/profile', '/api/trivia/users/profile'], ctcProfileRouter);
app.use(['/ctc/api/admin', '/api/trivia/admin'], ctcAdminRouter);
app.use(['/ctc/api/feedback', '/api/trivia/feedback'], ctcFeedbackRouter);
app.use(['/ctc/api/leaderboard', '/api/trivia/leaderboard'], ctcLeaderboardRouter);
app.use(['/ctc/health', '/api/trivia/health'], ctcHealthRouter);

await initTrivia().catch(() => {});

const port = parseInt(process.argv[2] || '3999', 10);
const server = app.listen(port, () => console.log(`LOCAL_ENGINE_LISTENING ${port}`));
process.once('SIGTERM', () => server.close(() => process.exit(0)));
process.once('SIGINT', () => server.close(() => process.exit(0)));
