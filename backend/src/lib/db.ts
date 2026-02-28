import { Pool } from 'pg';
import { env } from './env.js';

// Force IPv4 — Render free tier has no IPv6 routing to Supabase hosts.
// --dns-result-order=ipv4first is set in the Node start command (package.json).
// SSL is controlled via ?sslmode=require in DATABASE_URL — do NOT set ssl
// in pool config, as it triggers SCRAM-SHA-256-PLUS channel binding which
// the Supabase Supavisor pooler does not support.
export const pool = new Pool({
  connectionString: env.DATABASE_URL,
  max: 5,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});

pool.on('error', (err) => {
  console.error('[pool] idle client error:', err.message);
});
