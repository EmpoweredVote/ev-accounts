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

/**
 * Sign up a new user with email and password.
 *
 * When email confirmation is enabled (Supabase default), the returned
 * data.session will be null — this is NOT an error. Route handlers must
 * check data.user (not data.session) to determine success.
 */
export async function signUpWithEmail(email: string, password: string) {
  return supabaseAdmin.auth.signUp({ email, password });
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
