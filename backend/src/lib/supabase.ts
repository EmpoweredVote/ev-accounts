import { createClient } from '@supabase/supabase-js';
import type { Database } from '../types/database.types.js';
import { env } from './env.js';
import { classifyToken } from './tokenIdentity.js';

/**
 * Admin client — bypasses RLS.
 * NEVER use for reads that return data to users.
 * Service role bypasses all RLS.
 * Permitted uses: middleware standing checks, tier guard queries (trusted server-side internal checks only).
 */
export const supabaseAdmin = createClient<Database>(
  env.SUPABASE_URL.trim(),
  env.SUPABASE_SERVICE_ROLE_KEY.trim(),
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      headers: {
        Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY.trim()}`,
      },
    },
  }
);

/**
 * adminRpc — call a SECURITY DEFINER RPC function via supabaseAdmin.
 *
 * Used for functions registered in migrations that are not yet reflected in
 * database.types.ts. Bypasses the strict RPC name union type while preserving
 * the {data, error} return shape.
 *
 * Only use this for RPC calls — all .from() queries should use supabaseAdmin
 * directly so that table-level types are enforced.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export async function adminRpc(fn: string, args?: Record<string, unknown>, schema: string = 'public'): Promise<{ data: any; error: any }> {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return (supabaseAdmin as any).schema(schema).rpc(fn, args);
}

/**
 * Anon client — uses the public anon key, RLS enforced.
 * Use for reading public reference data (inform schema) that is accessible
 * to any role (anon or authenticated). Never use for user-owned data.
 */
export const supabaseAnon = createClient<Database>(
  env.SUPABASE_URL.trim(),
  env.SUPABASE_ANON_KEY.trim(),
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

/**
 * Per-request client — user JWT injected, RLS enforced.
 * Use in route handlers for all reads that feed API responses.
 */
export function createUserClient(accessToken: string) {
  return createClient<Database>(
    env.SUPABASE_URL,
    env.SUPABASE_ANON_KEY,
    {
      global: {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      },
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );
}

/**
 * Per-request client chosen by token issuer (decision 0002 transition).
 *
 * Supabase-issued tokens: the user-scoped client above — RLS enforced,
 * behavior unchanged. WorkOS-issued tokens: PostgREST cannot verify a WorkOS
 * JWT until Supabase third-party auth is configured and the auth.uid()
 * policies are rewritten (both scheduled as Phase 4 of the migration), so
 * WorkOS-session requests get the service-role client and the route-level
 * .eq(userId) scoping — which every caller already applies — is the
 * enforcement for them. requireAuth has verified the token and resolved
 * userId before any route can call this.
 *
 * REMOVE in Phase 4: once policies read the internal id from the WorkOS
 * token's external_id claim, WorkOS sessions switch back to the RLS path.
 */
export function requestDb(accessToken: string) {
  return classifyToken(accessToken) === 'workos' ? supabaseAdmin : createUserClient(accessToken);
}
