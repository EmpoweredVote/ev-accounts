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

// On every new connection, resolve unqualified spatial functions and operators via
// the search_path so PostGIS can move out of `public` (ev-cto decision 0006, Option B)
// without changing any query text. `public` MUST stay in the list during the
// transition: PostGIS lives there today, so ST_ / && resolve via `public` now and via
// `extensions` once support relocates the extension. `"$user"` keeps the role's own
// schema first, matching the postgres role default. Mirrors the trivia pool's connect
// hook (src/trivia/config/database.ts); SET is more reliable than the `options`
// connection parameter, which Supavisor may not forward on new connections.
pool.on('connect', (client) => {
  client.query('SET search_path TO "$user", public, extensions')
    .catch((err: Error) => console.error('[pool] failed to set search_path:', err.message));
});

pool.on('error', (err) => {
  console.error('[pool] idle client error:', err.message);
});
