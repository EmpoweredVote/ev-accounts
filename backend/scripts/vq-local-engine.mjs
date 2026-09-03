// Local in-process stand-in for the merged engine, VQ side, for pre-deploy parity
// checking. Replicates the engine's global middleware chain and mounts the folded VQ
// parent router under the dual prefixes index.ts uses. Boots with DUMMY env so it runs
// with no secrets: the gated routes (401) behave identically to the real engine; the DB
// -backed public routes cannot connect and will differ (expected). Usage: node scripts/vq-local-engine.mjs [port]
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import cookieParser from 'cookie-parser';

process.env.SUPABASE_URL ||= 'https://dummy.supabase.co';
process.env.SUPABASE_ANON_KEY ||= 'dummy-anon-key';
process.env.SUPABASE_SERVICE_ROLE_KEY ||= 'dummy-service-role-key';
process.env.UPSTASH_REDIS_REST_URL ||= 'https://dummy.upstash.io';
process.env.UPSTASH_REDIS_REST_TOKEN ||= 'dummy-token';
process.env.NODE_ENV ||= 'development';

const { validationQuestsRouter } = await import('../dist/vq/app.js');

const app = express();
app.set('trust proxy', 1);
app.use(helmet());
app.use(cookieParser());
app.use(cors({ origin: (o, cb) => cb(null, true), credentials: true }));
app.use(express.json());

app.use(['/vq/api', '/api/vq'], validationQuestsRouter);

const port = parseInt(process.argv[2] || '3998', 10);
const server = app.listen(port, () => console.log(`VQ_LOCAL_ENGINE_LISTENING ${port}`));
process.once('SIGTERM', () => server.close(() => process.exit(0)));
process.once('SIGINT', () => server.close(() => process.exit(0)));
