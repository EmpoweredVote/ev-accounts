import { useAuthStore } from '../store/authStore';
import { hasWorkosSession, refreshWorkosToken, workosEnabled } from './workosAuth';

const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

// Deduplicate concurrent refresh attempts — all waiters share one request.
let refreshPromise: Promise<string | null> | null = null;

async function refreshAccessToken(): Promise<string | null> {
  if (refreshPromise) return refreshPromise;
  // A WorkOS session (decision 0002 transition) refreshes through the AuthKit
  // SDK — the ev_session cookie belongs to the classic Supabase flow only.
  refreshPromise = (workosEnabled && hasWorkosSession()
    ? refreshWorkosToken().then((token) => {
        if (token) useAuthStore.setState({ accessToken: token });
        return token;
      })
    : fetch(`${API_BASE}/auth/session`, { credentials: 'include' })
        .then(async (res) => {
          if (!res.ok) return null;
          const data = await res.json() as { access_token: string };
          useAuthStore.setState({ accessToken: data.access_token });
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
    credentials: 'include',
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (res.status === 401) {
    const newToken = await refreshAccessToken();
    if (!newToken) {
      useAuthStore.getState().clearAuth();
      throw new Error('Session expired');
    }
    const retry = await fetch(`${API_BASE}${path}`, {
      credentials: 'include',
      ...options,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${newToken}`,
        ...options.headers,
      },
    });
    if (!retry.ok) {
      const body = await retry.json().catch(() => ({ error: retry.statusText }));
      throw new Error(body.error || body.message || `API error: ${retry.status}`);
    }
    return retry.json();
  }

  if (!res.ok) {
    const body = await res.json().catch(() => ({ error: res.statusText }));
    // Some routers reply { code, message } rather than { error } — the message
    // is written for a human (e.g. the season RPCs name the unblocking step),
    // so it must not collapse to "API error: 409".
    throw new Error(body.error || body.message || `API error: ${res.status}`);
  }

  return res.json();
}
