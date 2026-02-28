import { Pool } from 'pg';
import { env } from './env.js';

// Direct connection to Supabase database (bypasses Supavisor pooler).
// IPv4 add-on required — Render free tier has no IPv6 routing.
// --dns-result-order=ipv4first set in Node start command (package.json).
// ssl: rejectUnauthorized false required for Supabase's self-signed cert chain.
export const pool = new Pool({
  connectionString: env.DATABASE_URL,
  max: 5,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  ssl: { rejectUnauthorized: false },
});

pool.on('error', (err) => {
  console.error('[pool] idle client error:', err.message);
});
