/**
 * authService — thin wrapper around supabaseAdmin auth operations.
 *
 * WHY THIS FILE EXISTS:
 * The project architecture test enforces that no file in src/routes/ may
 * reference supabaseAdmin directly. This is a security/clarity constraint:
 * routes should operate via RLS-enforced user clients, not bypass all policies
 * with the service role key.
 *
 * Auth operations (signup, login, signOut) are a legitimate exception because
 * they need to operate at the admin level — but the exception lives here in
 * src/lib/, not in src/routes/. Route files import these named functions and
 * never touch supabaseAdmin directly.
 *
 * Each function returns the raw { data, error } result from Supabase.
 * Error mapping (Supabase error codes → project { code, message } contract)
 * happens in the route handler, not here.
 */

import { supabaseAdmin, supabaseAuth } from './supabase.js';
import { classifyToken } from './tokenIdentity.js';
import { cache } from './cache.js';

// ---------------------------------------------------------------------------
// Logout revocation helpers
// ---------------------------------------------------------------------------

/**
 * recordLogout
 *
 * Stores the current Unix timestamp as the user's last logout time in cache.
 * TTL is set to cover the remaining lifetime of the current access token
 * (plus a 60-second buffer for clock skew).
 *
 * Any token with iat < this timestamp will be rejected by requireAuth, even
 * if it is still cryptographically valid. This closes the ~1h window where a
 * signed-out token could still be used against the API.
 *
 * Errors are swallowed: if the cache write fails, the logout still succeeds
 * from the client's perspective. The token will expire naturally within ~1h.
 */
export async function recordLogout(userId: string, tokenExpAt: number): Promise<void> {
  const now = Math.floor(Date.now() / 1000);
  const ttl = Math.max(tokenExpAt - now, 0) + 60;
  try {
    await cache.set(`last_logout:${userId}`, now, ttl);
  } catch (err) {
    console.error('[recordLogout] cache write failed — token will expire naturally:', err);
  }
}

/**
 * isTokenRevoked
 *
 * Returns true if the token was issued before the user's last recorded logout.
 * A false return means the token is not in the revocation window (allow through).
 */
export async function isTokenRevoked(userId: string, tokenIat: number): Promise<boolean> {
  try {
    const lastLogout = await cache.get<number>(`last_logout:${userId}`);
    if (lastLogout === null) return false;
    return tokenIat < lastLogout;
  } catch {
    // Cache read failure — fail open (do not block legitimate requests)
    return false;
  }
}

/**
 * Sign up a new user with email and password.
 *
 * When email confirmation is enabled (Supabase default), the returned
 * data.session will be null — this is NOT an error. Route handlers must
 * check data.user (not data.session) to determine success.
 *
 * Runs on supabaseAuth, NOT supabaseAdmin: signUp can return a session (when
 * auto-confirm is on), which supabase-js would then store on the client and
 * attach to every later PostgREST call. See the supabaseAuth comment in
 * lib/supabase.ts (2026-09-10 outage).
 */
export async function signUpWithEmail(email: string, password: string, emailRedirectTo?: string) {
  return supabaseAuth.auth.signUp({ email, password, options: { emailRedirectTo } });
}

/**
 * Sign in an existing user with email and password.
 *
 * On success, data.session contains access_token, refresh_token, expires_in,
 * and expires_at. On failure, error.code identifies the type of failure
 * (e.g., 'invalid_credentials', 'email_not_confirmed').
 *
 * Runs on supabaseAuth, NOT supabaseAdmin. signInWithPassword stores the new
 * session on the client; on supabaseAdmin that made every later adminRpc() run
 * as the just-logged-in user and denied the compass write RPCs. See the
 * supabaseAuth comment in lib/supabase.ts (2026-09-10 outage).
 */
export async function signInWithEmail(email: string, password: string) {
  return supabaseAuth.auth.signInWithPassword({ email, password });
}

/**
 * Sign out a user by their access token, revoking all sessions globally.
 *
 * Uses scope 'global' so all active sessions across devices are invalidated,
 * not just the current session. This is appropriate for a civic auth platform
 * where account security is paramount.
 *
 * The route handler should return 200 even if this call fails — the access
 * token has a short TTL and will expire naturally. Log the error but do not
 * block the client.
 */
export async function signOutUser(accessToken: string) {
  return supabaseAdmin.auth.admin.signOut(accessToken, 'global');
}

/**
 * getRequestAuthUser — the auth.users record behind a request.
 *
 * Supabase-issued tokens: introspected via auth.getUser(token), unchanged.
 * WorkOS-issued tokens (decision 0002 transition): Supabase Auth cannot
 * introspect them; requireAuth already resolved the internal user id, so the
 * row is fetched by id with the admin client instead.
 */
export async function getRequestAuthUser(accessToken: string, userId: string) {
  if (classifyToken(accessToken) === 'workos') {
    const { data, error } = await supabaseAdmin.auth.admin.getUserById(userId);
    return { user: data?.user ?? null, error };
  }
  const { data, error } = await supabaseAdmin.auth.getUser(accessToken);
  return { user: data?.user ?? null, error };
}
