import { Pool } from 'pg';
import { env } from './env.js';

// Session Pooler (pooler.supabase.com:5432) — sticky sessions, compatible with
// pg.Pool BEGIN/COMMIT and SET search_path. Routes over IPv6 (no Render IPv4 add-on needed).
// Transaction Pooler (port 6543) is NOT safe here — PgBouncer resets sessions between transactions.
// ssl: rejectUnauthorized false required for Supabase's self-signed cert chain.
export const pool = new Pool({
  connectionString: env.DATABASE_URL,
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10_000,
  ssl: { rejectUnauthorized: false },
});

pool.on('error', (err) => {
  console.error('[pool] idle client error:', err.message);
});
