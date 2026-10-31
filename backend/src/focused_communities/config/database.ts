import pg from 'pg';
import { env } from '../../lib/env.js';

// Dedicated pg pool for the folded Focused Communities backend (engine consolidation —
// same shape as src/civic_spaces/config/database.ts). Kept SEPARATE from the engine pool
// (src/lib/db.ts) for ISOLATION, not sizing.
//
// 🔴 PRIVACY WALL. This pool connects as `focused_communities_app`, a dedicated login role
// granted access to ONLY the five connect tables the module reads or writes —
// communities (read), threads + posts (read/insert/update), thread_edits + post_edits (read) —
// plus EXECUTE on connect.get_stances_for_community. Nothing else: NOT
// connect.connected_profiles (identity, PRIVACY-ARCHITECTURE property A), NOT the gem/XP/invite
// tables that share the schema, NOT any other schema. The standalone service used the broad
// service_role key, which reaches all of them. See migration CA_0323.
//
// The two triggers that need identity (snapshot_author_display_name reads
// connected_profiles; log_*_edit writes the edit tables) are SECURITY DEFINER, so they run
// with their owner's rights and keep working without widening this role.

const { Pool } = pg;

if (!env.FOCUSED_COMMUNITIES_DATABASE_URL) {
  // Non-fatal: the engine boots without it, but every /fc/api route that touches the database
  // will 500 until the founder sets the scoped connection string. Loud so it is obvious.
  console.warn(
    '[focused_communities] FOCUSED_COMMUNITIES_DATABASE_URL is not set — Focused Communities routes will fail until it is configured'
  );
}

const pool = new Pool({
  connectionString: env.FOCUSED_COMMUNITIES_DATABASE_URL,
  // Small share of the shared session pooler (engine 10 + trivia 5 + civic_spaces 5 + fc 3).
  // Production traffic is tiny (1 thread, 3 posts on 2026-10-26).
  max: 3,
  ssl: { rejectUnauthorized: false },
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10_000,
});

// Pin search_path to connect so the module's SQL resolves there, and a short statement
// timeout. SET is more reliable than the `options` connection parameter through Supavisor.
pool.on('connect', (client) => {
  client
    .query("SET search_path TO connect, public; SET statement_timeout TO '10s'")
    .catch((err: Error) => console.error('[focused_communities] failed to set session parameters:', err.message));
});

pool.on('error', (err: Error & { code?: string }) => {
  // 57P01 = admin_shutdown (Supabase closed an idle connection); 57014 = statement_timeout.
  if (err.code === '57P01' || err.code === '57014') {
    console.warn(`[focused_communities] pool connection event (${err.code}), pool will recover automatically.`);
  } else {
    console.error('[focused_communities] pool error (pool will attempt recovery):', err.message);
  }
});

export { pool };
