import { Pool } from 'pg';
import { setDefaultResultOrder } from 'dns';
import { env } from './env.js';

// Force IPv4 — Render free tier has no IPv6 routing to Supabase hosts.
// setDefaultResultOrder affects all DNS lookups in this process.
// ssl: rejectUnauthorized false required for Supabase SSL cert chain.
setDefaultResultOrder('ipv4first');

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const pool = new Pool({
  connectionString: env.DATABASE_URL,
  max: 5,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  ssl: { rejectUnauthorized: false },
} as any);

pool.on('error', (err) => {
  console.error('[pool] idle client error:', err.message);
});
