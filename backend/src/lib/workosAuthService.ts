/**
 * workosAuthService — the one place that drives the WorkOS Authentication API
 * for the HEADLESS login flow (decision 0002 headless-login project). The
 * password and refresh grants send client_secret (= WORKOS_API_KEY) in the body,
 * so this MUST run server-side. Mirrors workosProvisionService's raw-fetch,
 * discriminated-union style.
 */
import { env } from './env.js';
import { sendEmail } from './emailService.js';

const WORKOS_API = 'https://api.workos.com';
const AUTH_URL = `${WORKOS_API}/user_management/authenticate`;

export type AuthOutcome =
  | { status: 'authenticated'; accessToken: string; refreshToken: string }
  | { status: 'email_verification_required'; pendingToken: string }
  | { status: 'mfa_required'; pendingToken: string; challengeId: string | null }
  | { status: 'invalid_credentials' }
  // Terminal for a refresh grant: the refresh token is spent (replayed past
  // WorkOS's 30s rotation grace), expired, or revoked. The session is genuinely
  // over — the caller must clear it and re-authenticate. Kept DISTINCT from the
  // transient `error` below, which must NOT end a session. See WorkOS "Session
  // resilience": destroy a session only on a terminal invalid_grant.
  | { status: 'session_expired' }
  | { status: 'error'; code: 'NOT_CONFIGURED' | 'WORKOS_ERROR' };

type Grant = Record<string, string | undefined>;

// Field names on WorkOS pending/error bodies are read defensively: WorkOS uses
// `code` on error bodies, but we also accept `error` so a field rename cannot
// silently turn a pending state into a 500. Confirmed shapes: Task 12 (staging).
async function callAuthenticate(grant: Grant): Promise<AuthOutcome> {
  if (!env.WORKOS_CLIENT_ID || !env.WORKOS_API_KEY) {
    return { status: 'error', code: 'NOT_CONFIGURED' };
  }
  const body = { client_id: env.WORKOS_CLIENT_ID, client_secret: env.WORKOS_API_KEY, ...grant };

  try {
    const res = await fetch(AUTH_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    const parsed = (await res.json().catch(() => ({}))) as Record<string, unknown>;

    if (res.ok && typeof parsed.access_token === 'string' && typeof parsed.refresh_token === 'string') {
      return { status: 'authenticated', accessToken: parsed.access_token, refreshToken: parsed.refresh_token };
    }

    const disc = (parsed.code ?? parsed.error) as string | undefined;
    const pendingToken = parsed.pending_authentication_token as string | undefined;

    if (disc === 'email_verification_required' && pendingToken) {
      return { status: 'email_verification_required', pendingToken };
    }
    if ((disc === 'mfa_enrollment' || disc === 'mfa_challenge') && pendingToken) {
      return {
        status: 'mfa_required',
        pendingToken,
        challengeId: (parsed.authentication_challenge_id as string | undefined) ?? null,
      };
    }
    // `invalid_one_time_code` is WorkOS's rejection of a wrong/expired
    // email-verification or MFA code; fold it into the same invalid outcome so
    // callers surface a clean "that code is wrong" instead of a 502.
    if (
      disc === 'invalid_credentials' ||
      disc === 'password_incorrect' ||
      disc === 'invalid_one_time_code' ||
      res.status === 401
    ) {
      return { status: 'invalid_credentials' };
    }
    // `invalid_grant` (HTTP 400) is WorkOS's terminal verdict on a refresh token
    // that is spent, expired or revoked. Report it distinctly so the /session
    // route ends the session ONLY here — never on the transient failure below.
    if (disc === 'invalid_grant') {
      return { status: 'session_expired' };
    }

    console.error('[workosAuth] authenticate failed:', res.status, JSON.stringify(parsed));
    return { status: 'error', code: 'WORKOS_ERROR' };
  } catch (err) {
    console.error('[workosAuth] network error:', err instanceof Error ? err.message : String(err));
    return { status: 'error', code: 'WORKOS_ERROR' };
  }
}

export function authenticateWithPassword(
  email: string,
  password: string,
  ctx?: { ipAddress?: string; userAgent?: string }
): Promise<AuthOutcome> {
  return callAuthenticate({
    grant_type: 'password',
    email,
    password,
    ip_address: ctx?.ipAddress,
    user_agent: ctx?.userAgent,
  });
}

export function authenticateWithEmailCode(code: string, pendingToken: string): Promise<AuthOutcome> {
  return callAuthenticate({
    grant_type: 'urn:workos:oauth:grant-type:email-verification:code',
    code,
    pending_authentication_token: pendingToken,
  });
}

export function refreshWorkosSession(refreshToken: string): Promise<AuthOutcome> {
  return callAuthenticate({ grant_type: 'refresh_token', refresh_token: refreshToken });
}

export type ResetOutcome =
  | { ok: true }
  | { ok: false; code: 'NOT_CONFIGURED' | 'INVALID_TOKEN' | 'WEAK_PASSWORD' | 'WORKOS_ERROR' };

function apiKeyHeaders() {
  return { Authorization: `Bearer ${env.WORKOS_API_KEY}`, 'Content-Type': 'application/json' };
}

export async function sendWorkosPasswordReset(email: string): Promise<ResetOutcome> {
  if (!env.WORKOS_API_KEY) return { ok: false, code: 'NOT_CONFIGURED' };
  try {
    const res = await fetch(`${WORKOS_API}/user_management/password_reset`, {
      method: 'POST',
      headers: apiKeyHeaders(),
      body: JSON.stringify({ email }),
    });
    // A 404 (no such user) is expected and must NOT leak — send no email, but
    // still report ok so the caller's OWASP always-200 response can't be used
    // to enumerate accounts.
    if (!res.ok) {
      if (res.status === 404) return { ok: true };
      console.error('[workosAuth] password_reset send failed:', res.status, await res.text());
      return { ok: false, code: 'WORKOS_ERROR' };
    }

    // Send OUR OWN reset email pointing at login.empowered.vote, built from the
    // token WorkOS returns. We deliberately IGNORE the response's
    // `password_reset_url` — it points at the hosted *.authkit.app page, the very
    // foreign-domain link this project exists to avoid. WorkOS's API-initiated
    // create does NOT send its own email, so there is no duplicate. The token is
    // one-time and short-lived; `/reset-password` confirms it via
    // `password_reset/confirm`. sendEmail never throws and no-ops without
    // RESEND_API_KEY, so a delivery miss still returns ok (OWASP).
    const body = (await res.json().catch(() => ({}))) as { password_reset_token?: string };
    const token = body.password_reset_token;
    if (!token) {
      console.error('[workosAuth] password_reset send: response carried no token');
      return { ok: true };
    }
    const link = `${env.LOGIN_URL}/reset-password?token_hash=${encodeURIComponent(token)}`;
    await sendEmail({
      to: email,
      subject: 'Reset your Empowered Vote password',
      html: `<p>We received a request to reset your Empowered Vote password.</p>
             <p><a href="${link}">Reset your password</a></p>
             <p>This link can be used once and expires soon. If you didn't request a reset, you can ignore this email — your password will not change.</p>`,
    });
    return { ok: true };
  } catch (err) {
    console.error('[workosAuth] password_reset send network error:', err instanceof Error ? err.message : String(err));
    return { ok: false, code: 'WORKOS_ERROR' };
  }
}

export async function confirmWorkosPasswordReset(token: string, newPassword: string): Promise<ResetOutcome> {
  if (!env.WORKOS_API_KEY) return { ok: false, code: 'NOT_CONFIGURED' };
  try {
    const res = await fetch(`${WORKOS_API}/user_management/password_reset/confirm`, {
      method: 'POST',
      headers: apiKeyHeaders(),
      body: JSON.stringify({ token, new_password: newPassword }),
    });
    if (res.ok) return { ok: true };
    const body = (await res.json().catch(() => ({}))) as Record<string, unknown>;
    const disc = (body.code ?? body.error) as string | undefined;
    if (disc && /token|expired/i.test(disc)) return { ok: false, code: 'INVALID_TOKEN' };
    if (disc && /invalid|password/i.test(disc)) {
      // "invalid_password" → WEAK_PASSWORD; "password_reset_token_invalid" → already caught above by token check
      return /password/i.test(disc) ? { ok: false, code: 'WEAK_PASSWORD' } : { ok: false, code: 'INVALID_TOKEN' };
    }
    console.error('[workosAuth] password_reset confirm failed:', res.status, JSON.stringify(body));
    return { ok: false, code: 'WORKOS_ERROR' };
  } catch (err) {
    console.error('[workosAuth] password_reset confirm network error:', err instanceof Error ? err.message : String(err));
    return { ok: false, code: 'WORKOS_ERROR' };
  }
}
