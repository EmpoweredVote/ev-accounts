import pg from 'pg';
import { env } from '../../lib/env.js';

// Dedicated pg pool for the folded Civic Spaces slice-assignment module (engine
// consolidation — ev-cto decision 0018). Kept SEPARATE from the engine pool
// (src/lib/db.ts) and the trivia pool for one reason above sizing: ISOLATION.
//
// 🔴 PRIVACY WALL. This pool connects as `civic_spaces_app`, a dedicated login role that
// holds grants on ONLY civic_spaces.{slices, slice_members, connected_profiles} — nothing
// else in the database. connected_profiles.user_id joins to identity
// (PRIVACY-ARCHITECTURE property A), so the module MUST NOT be able to reach identity or any
// other schema. The engine pool (role ev_api) and the broad service_role key both can; this
// one deliberately cannot. See migration CA_0111 for the role + grants.
//
// The role bypasses RLS (like the standalone service's per-service key did), but that only
// matters for the three tables it is granted — the wall is the grant set, not RLS.
//
// Not process-wide: the standalone service called setDefaultResultOrder('ipv4first') at
// import. That is a whole-process side effect and must NOT run inside the engine (the engine
// pool reaches the Supabase session pooler over IPv6 by design). Both pools point at a
// Supabase session pooler reachable over both families, so this pool works with the process
// default. See src/trivia/config/database.ts for the same note.

const { Pool } = pg;

if (!env.CIVIC_SPACES_DATABASE_URL) {
  // Non-fatal: the engine boots without it, but POST /api/civic-spaces/assign will 500 until
  // the founder sets the scoped connection string. Loud so a misconfigured deploy is obvious.
  console.warn(
    '[civic_spaces] CIVIC_SPACES_DATABASE_URL is not set — slice assignment will fail until it is configured'
  );
}

const pool = new Pool({
  connectionString: env.CIVIC_SPACES_DATABASE_URL,
  // Small share of the shared session pooler (engine 10 + trivia 5 + civic_spaces 5).
  max: 5,
  ssl: { rejectUnauthorized: false },
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10_000,
});

// On every new connection: pin search_path to civic_spaces so the module's unqualified SQL
// resolves there, and a short statement timeout. SET is more reliable than the `options`
// connection parameter, which Supabase's Supavisor pooler may not forward on new connections.
// (The role also has search_path set at the DB level in CA_0111; this makes it explicit and
// survives any future connection-parameter drift.)
pool.on('connect', (client) => {
  client
    .query("SET search_path TO civic_spaces, public; SET statement_timeout TO '10s'")
    .catch((err: Error) => console.error('[civic_spaces] failed to set session parameters:', err.message));
});

pool.on('error', (err: Error & { code?: string }) => {
  // 57P01 = admin_shutdown (Supabase closed an idle connection); 57014 = statement_timeout.
  // Both recoverable — the pool reconnects on the next query. Never exit on an idle error.
  if (err.code === '57P01' || err.code === '57014') {
    console.warn(`[civic_spaces] pool connection event (${err.code}), pool will recover automatically.`);
  } else {
    console.error('[civic_spaces] pool error (pool will attempt recovery):', err.message);
  }
});

export { pool };
