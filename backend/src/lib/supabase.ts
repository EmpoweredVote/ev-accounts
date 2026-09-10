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
    // No `global.headers.Authorization` override. supabase-js already sends the
    // key, and the new sb_secret_... keys are NOT JWTs -- passing one as
    // `Authorization: Bearer` makes the platform try to parse it as a JWT and
    // reject the request. It belongs on the `apikey` header, which the client
    // sets itself. The override was redundant for legacy JWT keys and becomes a
    // hard failure the moment this value is a new-format key.
  }
);

/**
 * supabaseAuth — a SEPARATE client dedicated to GoTrue session operations
 * (signInWithPassword, signUp, refreshSession, verifyOtp).
 *
 * WHY THIS EXISTS — the 2026-09-10 compass-write outage:
 *   supabase-js stores the session returned by a sign-in / refresh / verify on
 *   the CLIENT that made the call. After that, every PostgREST request from that
 *   client sends the stored user's access_token as `Authorization` instead of
 *   the API key — the session token wins over the key in the client's own
 *   `_getAccessToken()`. Running these auth calls on `supabaseAdmin` therefore
 *   turned the shared admin singleton into a user-scoped client for the rest of
 *   the process: every `adminRpc()` after a login ran as the last-logged-in user
 *   (role `authenticated`), which lacks EXECUTE on the service-role-only write
 *   RPCs (upsert_compass_answer, reset_compass_answers, promote_compass_import_draft)
 *   -> "permission denied for function". It stayed hidden while supabaseAdmin
 *   carried a forced `Authorization: Bearer <service key>` header (which overrode
 *   the polluting session); removing that header unmasked it.
 *
 * The fix is isolation, not a header trick: sign-in / refresh / verify run HERE,
 * and this client is NEVER used for `.from()` / `.rpc()`, so the session it
 * accumulates is inert. supabaseAdmin stays pristine and always authenticates as
 * service_role. Admin GoTrue calls (`auth.admin.*`) and token introspection
 * (`auth.getUser(token)`) do NOT store a session, so they stay on supabaseAdmin.
 *
 * Uses the service key so behaviour is otherwise identical to the previous
 * supabaseAdmin path; the only change is that the session lives off to the side.
 */
export const supabaseAuth = createClient<Database>(
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
 * Public key used by the RLS-enforcing clients below.
 *
 * Prefers SUPABASE_PUBLISHABLE_KEY (sb_publishable_...) and falls back to the
 * legacy SUPABASE_ANON_KEY. Both work at the same time on the project, so the
 * publishable key can be set in Render whenever, independently of any deploy;
 * when it is present it simply wins. Legacy anon is removed by Supabase in late
 * 2026, at which point the fallback stops being reachable.
 *
 * Note this key is public either way -- it is compiled into browser bundles.
 * It is not a secret and is not what enforces access; RLS and the user's JWT are.
 */
const PUBLIC_API_KEY = (env.SUPABASE_PUBLISHABLE_KEY ?? env.SUPABASE_ANON_KEY).trim();

/**
 * Anon client — uses the public anon key, RLS enforced.
 * Use for reading public reference data (inform schema) that is accessible
 * to any role (anon or authenticated). Never use for user-owned data.
 */
export const supabaseAnon = createClient<Database>(
  env.SUPABASE_URL.trim(),
  PUBLIC_API_KEY,
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
    PUBLIC_API_KEY,
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
