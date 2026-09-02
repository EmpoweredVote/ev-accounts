import { useAuthStore } from '../store/authStore';
import { embeddedAuthEnabled, hasWorkosSession, refreshWorkosToken, workosEnabled } from './workosAuth';

const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

// Deduplicate concurrent refresh attempts — all waiters share one request.
let refreshPromise: Promise<string | null> | null = null;

async function refreshAccessToken(): Promise<string | null> {
  if (refreshPromise) return refreshPromise;
  // A WorkOS session (decision 0002 transition) refreshes through the AuthKit
  // SDK — the ev_session cookie belongs to the classic Supabase flow only.
  // When embedded auth is on, the WorkOS session itself is carried in the
  // httpOnly ev_wos_session cookie, so /auth/session (Task 6) reads it
  // instead — the SDK branch stays only for the non-embedded rollout window.
  refreshPromise = (workosEnabled && hasWorkosSession() && !embeddedAuthEnabled
    ? refreshWorkosToken().then((token) => {
        if (token) {
          useAuthStore.setState({ accessToken: token });
          localStorage.setItem('ev_token', token);
        }
        return token;
      })
    : fetch(`${API_BASE}/auth/session`, { credentials: 'include' })
        .then(async (res) => {
          // 401 is terminal — the session is genuinely over; the caller clears it.
          if (res.status === 401) return null;
          // 503/5xx is a transient WorkOS blip. Keep the session and signal the
          // caller to retry instead of signing out (WorkOS session-resilience
          // guidance). Throwing — rather than returning null — is what separates
          // "retry" from "log out" in apiFetch below.
          if (!res.ok) throw new Error('refresh_unavailable');
          const data = await res.json() as { access_token: string };
          useAuthStore.setState({ accessToken: data.access_token });
          localStorage.setItem('ev_token', data.access_token);
          return data.access_token;
        })
  ).finally(() => { refreshPromise = null; });
  return refreshPromise;
}

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const token = useAuthStore.getState().accessToken;
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (res.status === 401) {
    let newToken: string | null;
    try {
      newToken = await refreshAccessToken();
    } catch {
      // Transient refresh failure (WorkOS 5xx/timeout). Do NOT clear the
      // session — keep it and let the caller retry (WorkOS guidance). Only
      // this one request fails.
      throw new Error('Session temporarily unavailable, please try again');
    }
    if (!newToken) {
      useAuthStore.getState().clearAuth();
      throw new Error('Session expired');
    }
    const retry = await fetch(`${API_BASE}${path}`, {
      ...options,
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${newToken}`,
        ...options.headers,
      },
    });
    if (!retry.ok) {
      const body = await retry.json().catch(() => ({ error: retry.statusText }));
      throw new Error(body.code || body.error || `API error: ${retry.status}`);
    }
    return retry.json();
  }

  if (!res.ok) {
    const body = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(body.code || body.error || `API error: ${res.status}`);
  }

  return res.json();
}
