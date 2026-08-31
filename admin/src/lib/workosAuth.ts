/**
 * workosAuth — WorkOS AuthKit login path (Supabase → WorkOS migration,
 * decision 0002). Compiled in only when VITE_WORKOS_CLIENT_ID is set at build
 * time; without it workosEnabled is false and the classic flow is untouched.
 *
 * Session model during the transition:
 * - The AuthKit SDK owns the WorkOS session: redirect to the hosted, branded
 *   login page, then silent refresh. Classic Supabase sessions keep using the
 *   ev_session cookie exactly as before.
 * - completeWorkosLogin() guarantees the access token resolves to an internal
 *   account (external_id claim), provisioning brand-new AuthKit signups via
 *   POST /api/auth/workos/provision, and returns a token the rest of the app
 *   treats like any classic access token.
 * - localStorage['ev_auth_provider'] = 'workos' is a HINT that the active
 *   session is a WorkOS one, so bootstrap and the 401-refresh path ask the
 *   SDK instead of the ev_session cookie. It grants nothing by itself.
 *
 * NOTE: keep this file in sync with app/src/lib/workosAuth.ts (same
 * do-not-drift policy as lib/redirect.ts).
 */
import { createClient, getClaims } from '@workos-inc/authkit-js';

type Client = Awaited<ReturnType<typeof createClient>>;

const clientId: string | undefined = import.meta.env.VITE_WORKOS_CLIENT_ID;
const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

export const workosEnabled = Boolean(clientId);

/**
 * AuthKit-only mode (decision 0002 cutover). When set AND WorkOS is enabled,
 * the login page hides the classic Supabase email/password form and presents
 * AuthKit as the only way in. Gated on workosEnabled so a misconfiguration
 * (flag on, client id absent) can never hide the only working path — it fails
 * back to the classic form. The break-glass route /login/classic ignores this
 * and always shows the form; it is unadvertised and slated for removal once
 * Supabase Auth sign-ins are disabled.
 */
export const authkitOnly = workosEnabled && import.meta.env.VITE_AUTHKIT_ONLY === 'true';

// VITE_EMBEDDED_AUTH turns on our own headless form instead of the hosted
// AuthKit redirect. Requires VITE_WORKOS_CLIENT_ID (workosEnabled) so we never
// lock everyone out of a build that has no WorkOS at all.
export const embeddedAuthEnabled =
  workosEnabled && import.meta.env.VITE_EMBEDDED_AUTH === 'true';

const PROVIDER_KEY = 'ev_auth_provider';

export function hasWorkosSession(): boolean {
  return localStorage.getItem(PROVIDER_KEY) === 'workos';
}
function markWorkosSession(): void {
  localStorage.setItem(PROVIDER_KEY, 'workos');
}
function clearWorkosSession(): void {
  localStorage.removeItem(PROVIDER_KEY);
}

let clientPromise: Promise<Client> | null = null;
// State round-tripped through the OAuth redirect; the SDK consumes the
// callback URL itself, so this is the only way to receive it.
let capturedRedirectState: Record<string, unknown> | null = null;

/**
 * Lazily create the SDK client. createClient() also completes a pending
 * ?code= redirect callback, so the login page calls this on mount.
 */
export function getWorkosClient(): Promise<Client> {
  if (!clientId) {
    return Promise.reject(new Error('WorkOS login is not enabled in this build'));
  }
  clientPromise ??= createClient(clientId, {
    // Must be registered as a redirect URI in the WorkOS dashboard for every
    // deployed origin of this app.
    redirectUri: `${window.location.origin}/login`,
    onRedirectCallback: ({ state }) => {
      capturedRedirectState = (state as Record<string, unknown> | null | undefined) ?? null;
    },
  });
  return clientPromise;
}

/**
 * Redirect to the hosted AuthKit page. `state` round-trips through the OAuth
 * redirect and comes back UNTRUSTED — anything read from it on return must be
 * re-validated (see redirect.ts).
 */
export async function startWorkosSignIn(state?: Record<string, unknown>): Promise<void> {
  const client = await getWorkosClient();
  return client.signIn(state ? { state } : undefined);
}

/**
 * The state the login page put into signIn(), or null. One-shot read.
 * UNTRUSTED: it traveled as plaintext through the redirect — validate
 * anything read from it (redirect targets go through validateRedirectUrl).
 */
export async function consumeWorkosRedirectState(): Promise<Record<string, unknown> | null> {
  await getWorkosClient(); // ensures the pending callback has been processed
  const state = capturedRedirectState;
  capturedRedirectState = null;
  return state;
}

/**
 * After the SDK holds a WorkOS session: make sure the token resolves to an
 * internal account, provisioning a brand-new AuthKit signup when needed.
 * Returns a ready-to-use access token. Throws when there is no session.
 */
export async function completeWorkosLogin(): Promise<string> {
  const client = await getWorkosClient();
  let token = await client.getAccessToken();
  const claims = getClaims<{ external_id?: string }>(token);
  if (!claims.external_id) {
    const res = await fetch(`${API_BASE}/auth/workos/provision`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) {
      const body = await res.json().catch(() => ({} as { message?: string }));
      throw new Error(body.message || 'Account linking failed, please try again');
    }
    // The external_id claim only exists in tokens minted after the link.
    token = await client.getAccessToken({ forceRefresh: true });
  }
  markWorkosSession();
  return token;
}

/**
 * SDK-side token refresh for the 401 path in api.ts and for bootstrap
 * restore. Null = no restorable WorkOS session (fall back to logged-out).
 */
export async function refreshWorkosToken(): Promise<string | null> {
  if (!workosEnabled) return null;
  try {
    const client = await getWorkosClient();
    return await client.getAccessToken({ forceRefresh: true });
  } catch {
    clearWorkosSession();
    return null;
  }
}

/** Ends the WorkOS session without navigating away. Safe to call always. */
export async function workosSignOut(): Promise<void> {
  if (!workosEnabled || !hasWorkosSession()) return;
  clearWorkosSession();
  try {
    const client = await getWorkosClient();
    await client.signOut({ navigate: false });
  } catch {
    // No SDK session — nothing to end on the WorkOS side.
  }
}

/**
 * Embedded login (decision 0002 headless variant, gated on embeddedAuthEnabled):
 * our own email/password form posts straight to the backend instead of
 * redirecting to the hosted AuthKit page. A pending status means the backend
 * needs a follow-up step (email verification code, or MFA) before it will
 * issue a token — the caller switches to the on-page code step.
 */
type EmbeddedResult =
  | { status: 'authenticated'; token: string }
  | { status: 'email_verification_required' }
  | { status: 'mfa_required' };

export async function loginWithPassword(email: string, password: string): Promise<EmbeddedResult> {
  const res = await fetch(`${API_BASE}/auth/workos/authenticate`, {
    method: 'POST',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const body = await res.json().catch(() => ({}));
  if (res.status === 401) throw new Error(body.message || 'Invalid email or password');
  if (!res.ok) throw new Error(body.message || 'Sign-in failed');
  if (body.access_token) {
    markWorkosSession();
    return { status: 'authenticated', token: body.access_token };
  }
  return { status: body.status };
}

/** Completes the pending email-verification (or MFA) step of loginWithPassword. */
export async function verifyEmailCode(code: string): Promise<string> {
  const res = await fetch(`${API_BASE}/auth/workos/verify-email`, {
    method: 'POST',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code }),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(body.message || 'Verification failed');
  markWorkosSession();
  return body.access_token as string;
}
