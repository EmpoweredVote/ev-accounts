/**
 * workosAuthService — the one place that drives the WorkOS Authentication API
 * for the HEADLESS login flow (decision 0002 headless-login project). The
 * password and refresh grants send client_secret (= WORKOS_API_KEY) in the body,
 * so this MUST run server-side. Mirrors workosProvisionService's raw-fetch,
 * discriminated-union style.
 */
import { env } from './env.js';

const WORKOS_API = 'https://api.workos.com';
const AUTH_URL = `${WORKOS_API}/user_management/authenticate`;

export type AuthOutcome =
  | { status: 'authenticated'; accessToken: string; refreshToken: string }
  | { status: 'email_verification_required'; pendingToken: string }
  | { status: 'mfa_required'; pendingToken: string; challengeId: string | null }
  | { status: 'invalid_credentials' }
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
    if (disc === 'invalid_credentials' || disc === 'password_incorrect' || res.status === 401) {
      return { status: 'invalid_credentials' };
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
