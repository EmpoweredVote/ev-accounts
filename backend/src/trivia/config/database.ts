import pg from 'pg';

// NOTE (engine fold-in, Phase 1): the standalone CTC service called
// `setDefaultResultOrder('ipv4first')` here. That is a PROCESS-WIDE side effect and
// must not be re-applied inside the engine — the engine's own pool (src/lib/db.ts)
// deliberately reaches the Supabase session pooler over IPv6, and flipping the whole
// process to IPv4-first would silently change that. Both pools point at the same
// session pooler (DATABASE_URL), which is reachable over both families, so this pool
// works with the process default. The engine's Render start command already governs
// DNS order for the whole process; the sub-app does not.

const { Pool } = pg;

// Dedicated pg pool for the CTC (trivia) schema. Kept SEPARATE from the engine's
// pool (src/lib/db.ts) so its `search_path TO trivia` connect hook — which the raw
// SQL in these routes relies on — cannot leak into engine connections. Sized small
// (max 5) so the combined footprint (engine 10 + trivia 5 = 15) stays inside the
// session pooler's limit.
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Cap trivia's share of the shared session pooler. See sizing note above.
  max: 5,
  // SSL configuration for production
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : undefined,
  // Drop idle connections after 30s so Supabase never gets the chance to terminate them
  idleTimeoutMillis: 30_000,
  // Fail fast if a connection can't be acquired — prevents indefinite hangs on cold start
  connectionTimeoutMillis: 10_000,
});

// On every new connection: set search_path and statement_timeout explicitly.
// Using SET commands here is more reliable than the `options` connection parameter,
// which Supabase's Supavisor pooler may not consistently forward on new connections.
pool.on('connect', (client) => {
  console.log('PostgreSQL connected');
  client.query("SET search_path TO trivia, public; SET statement_timeout TO '10s'")
    .catch((err: Error) => console.error('Failed to set session parameters:', err));
});

// Keep-alive: prevent Supavisor from dropping the idle connection.
// Runs every 20s — under the 30s idleTimeoutMillis — so there's always
// a warm connection ready and the first real query never pays reconnect cost.
setInterval(() => {
  pool.query('SELECT 1').catch(() => {});
}, 20_000);

pool.on('error', (err: Error & { code?: string }) => {
  // 57P01 = admin_shutdown: Supabase closed an idle connection — recoverable
  // 57014 = query_canceled: statement_timeout fired — recoverable
  // All other errors (network timeouts, infra blips) are also recoverable —
  // the pool will reconnect on the next query. Never exit: a transient Supabase
  // outage should degrade gracefully, not crash the process.
  if (err.code === '57P01' || err.code === '57014') {
    console.warn(`PostgreSQL connection event (${err.code}), pool will recover automatically.`);
  } else {
    console.error('PostgreSQL pool error (pool will attempt recovery):', err);
  }
});

export { pool };