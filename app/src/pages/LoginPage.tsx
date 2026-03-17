import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { apiFetch } from '../lib/api';
import { useAuthStore, User } from '../store/authStore';

interface LoginResponse {
  token: string;
  user: {
    id: string;
    email: string;
    tier: 'inform' | 'connected' | 'empowered';
    display_name: string | null;
    completed_onboarding: boolean;
    location_consent: boolean;
  };
}

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { setAuth } = useAuthStore();
  const navigate = useNavigate();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = await apiFetch<LoginResponse>('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });
      const user: User = {
        id: res.user.id,
        email: res.user.email,
        tier: res.user.tier,
        displayName: res.user.display_name,
        completedOnboarding: res.user.completed_onboarding,
        locationConsent: res.user.location_consent,
      };
      setAuth(res.token, user);
      navigate('/');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-white dark:bg-ev-black px-4">
      <div className="w-full max-w-sm">
        <h1 className="text-2xl font-bold text-ev-teal mb-8 text-center">Empowered Vote</h1>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-ev-black dark:text-white mb-1">
              Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 bg-white dark:bg-gray-900 text-ev-black dark:text-white focus:outline-none focus:ring-2 focus:ring-ev-teal"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-ev-black dark:text-white mb-1">
              Password
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 bg-white dark:bg-gray-900 text-ev-black dark:text-white focus:outline-none focus:ring-2 focus:ring-ev-teal"
            />
          </div>

          {error && <p className="text-ev-red text-sm">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-ev-teal text-white rounded-lg px-4 py-2 font-medium hover:bg-ev-teal/90 disabled:opacity-50 transition-colors"
          >
            {loading ? 'Signing in…' : 'Sign in'}
          </button>
        </form>

        <p className="text-center text-sm text-gray-500 mt-6">
          Have an invite code?{' '}
          <Link to="/signup" className="text-ev-teal font-medium hover:underline">
            Create account
          </Link>
        </p>
      </div>
    </div>
  );
}
