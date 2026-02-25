import 'dotenv/config'; // Must be first import
import { env } from './lib/env.js'; // Validates env vars — exits if invalid
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import healthRouter from './routes/health.js';
import authRouter from './routes/auth.js';
import accountRouter from './routes/account.js';

const app = express();

app.use(helmet());
app.use(
  cors({
    origin: env.NODE_ENV === 'development' ? '*' : [],
  })
);
app.use(express.json());

// Routes
app.use('/api/health', healthRouter);
app.use('/api/auth', authRouter);
app.use('/api/account', accountRouter);

export { app }; // For testing

const port = parseInt(env.PORT, 10);

if (env.NODE_ENV !== 'test') {
  app.listen(port, () => {
    console.info(`[server] listening on port ${port}`);
    console.info(`[server] environment: ${env.NODE_ENV}`);
  });
}
