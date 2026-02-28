import { createClient } from '@supabase/supabase-js';
import type { Database } from '../types/database.types.js';
import { env } from './env.js';

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
