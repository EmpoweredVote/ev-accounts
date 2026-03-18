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

import { supabaseAdmin } from './supabase.js';
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
 * Uses the admin API with email_confirm: true to skip email confirmation.
 * This is appropriate for invite-only alpha where the invite code is the
 * identity gate. Returns { data: { user }, error } — no session is included;
 * callers should follow up with signInWithEmail to issue a token.
 */
export async function signUpWithEmail(email: string, password: string) {
  return supabaseAdmin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
}

/**
 * Sign in an existing user with email and password.
 *
 * On success, data.session contains access_token, refresh_token, expires_in,
 * and expires_at. On failure, error.code identifies the type of failure
 * (e.g., 'invalid_credentials', 'email_not_confirmed').
 */
export async function signInWithEmail(email: string, password: string) {
  return supabaseAdmin.auth.signInWithPassword({ email, password });
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
