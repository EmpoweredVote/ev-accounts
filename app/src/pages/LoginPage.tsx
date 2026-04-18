import { useState, useMemo } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { apiFetch } from '../lib/api';
import { useAuthStore, type User } from '../store/authStore';

interface LoginResponse {
  access_token: string;
}

interface MeResponse {
  id: string;
  email: string;
  tier: 'inform' | 'connected' | 'empowered';
  display_name: string | null;
  completed_onboarding: boolean;
  location_consent: boolean;
}

function getValidatedRedirectUrl(): string | null {
  const raw = new URLSearchParams(window.location.search).get('redirect');
  if (!raw) return null;
  // Security: only allow https:// URLs to prevent open redirect attacks
  if (!raw.startsWith('https://')) return null;
  return raw;
}

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { setAuth } = useAuthStore();
  const navigate = useNavigate();

  // Parse redirect URL once on mount — do NOT re-parse on every render
  const redirectUrl = useMemo(() => getValidatedRedirectUrl(), []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const { access_token } = await apiFetch<LoginResponse>('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });
      useAuthStore.setState({ accessToken: access_token });
      const me = await apiFetch<MeResponse>('/account/me');
      const user: User = {
        id: me.id,
        email: me.email,
        tier: me.tier,
        displayName: me.display_name,
        completedOnboarding: me.completed_onboarding,
        locationConsent: me.location_consent,
      };
      setAuth(access_token, user);
      if (redirectUrl) {
        // Redirect to calling app with token in hash fragment
        window.location.href = `${redirectUrl}#access_token=${access_token}`;
      } else {
        navigate('/');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-ev-black px-4 py-12">
      {/* Wordmark */}
      <div className="mb-8 text-center space-y-1">
        <h1 className="text-3xl font-bold text-ev-teal-light tracking-tight">empowered.vote</h1>
        <p className="text-gray-500 text-sm">Your civic profile</p>
      </div>

      {/* Card */}
      <div className="w-full max-w-sm bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5">
        {redirectUrl && (
          <div className="p-3 bg-ev-teal/10 border border-ev-teal/30 rounded-lg text-sm text-gray-300 text-center">
            We've made some improvements. Please log in again to continue.
          </div>
        )}

        <h2 className="text-lg font-semibold text-white">Log in</h2>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1.5">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
              className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal-light text-base"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1.5">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              autoComplete="current-password"
              className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal-light text-base"
            />
          </div>

          {error && <p className="text-ev-red text-sm">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-ev-teal-light text-ev-black rounded-xl py-3 font-bold text-base hover:bg-ev-teal-light/90 disabled:opacity-40 transition-colors"
          >
            {loading ? 'Logging in…' : 'Log in'}
          </button>
        </form>

        <p className="text-center text-sm text-gray-500">
          Have an invite code?{' '}
          <Link to="/signup" className="text-ev-teal-light font-medium hover:underline">
            Create account
          </Link>
        </p>
      </div>
    </div>
  );
}
