import { useState, FormEvent } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { getValidRedirect, getAppNameFromRedirect } from '../lib/redirect';

const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

export default function Login() {
  const navigate = useNavigate();
  const { setAuth } = useAuthStore();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const validRedirect = getValidRedirect();
  const appName = validRedirect ? getAppNameFromRedirect(validRedirect) : null;

  // Preserve ?redirect= when linking to /signup
  const signupHref = validRedirect
    ? `/signup?redirect=${encodeURIComponent(validRedirect)}`
    : '/signup';

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      // Step 1: authenticate
      const loginRes = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      if (!loginRes.ok) {
        const body = await loginRes.json().catch(() => ({ error: 'Login failed' }));
        throw new Error(body.error || 'Login failed');
      }

      const loginData = await loginRes.json();
      const token: string = loginData.access_token;

      // Step 2: get full user info (tier, onboarding, admin status)
      const meRes = await fetch(`${API_BASE}/account/me`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!meRes.ok) {
        throw new Error('Failed to load account information.');
      }

      const meData = await meRes.json();

      setAuth(token, {
        id: meData.id ?? '',
        email: meData.email ?? email,
        isAdmin: meData.is_admin ?? false,
        tier: meData.tier ?? 'inform',
        completedOnboarding: meData.completed_onboarding ?? false,
      });

      // Step 3: route
      if (validRedirect) {
        window.location.href = validRedirect;
      } else {
        window.location.href = 'https://profile.empowered.vote';
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unexpected error occurred');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="bg-white rounded-lg shadow-md p-8 w-full max-w-md">
        <div className="flex justify-center mb-6">
          <img
            src="/Empowered_Vote_Logo_2026.png"
            alt="Empowered Vote"
            className="h-12 object-contain"
          />
        </div>

        <h1 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          Sign in to Empowered Vote
        </h1>

        {appName && (
          <div className="mb-4 p-3 bg-ev-teal/10 border border-ev-teal/20 rounded text-sm text-ev-teal text-center">
            You'll be returned to {appName} after signing in
          </div>
        )}

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
              Email
            </label>
            <input
              id="email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-ev-teal focus:border-transparent"
              placeholder="you@example.com"
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
              Password
            </label>
            <input
              id="password"
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-ev-teal focus:border-transparent"
            />
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full py-2 px-4 bg-ev-teal hover:bg-ev-teal/90 disabled:opacity-60 text-white font-medium rounded-md text-sm transition-colors"
          >
            {isSubmitting ? 'Signing in...' : 'Sign in'}
          </button>
        </form>

        <p className="mt-4 text-center text-sm text-gray-500">
          Don't have an account?{' '}
          <Link to={signupHref} className="text-ev-teal hover:underline font-medium">
            Create one
          </Link>
        </p>
      </div>
    </div>
  );
}
