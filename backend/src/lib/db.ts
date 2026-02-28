import { Pool } from 'pg';
import { env } from './env.js';

// Force IPv4 — Render free tier has no IPv6 routing to Supabase hosts.
// pg types don't expose 'family' but the underlying net.connect accepts it.
// ssl: rejectUnauthorized false required for Supabase pooler SSL cert.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const pool = new Pool({
  connectionString: env.DATABASE_URL,
  max: 5,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  family: 4,
  ssl: { rejectUnauthorized: false },
} as any);

pool.on('error', (err) => {
  console.error('[pool] idle client error:', err.message);
});
