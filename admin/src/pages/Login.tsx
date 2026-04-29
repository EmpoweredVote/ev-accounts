import { useState, FormEvent } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { getValidRedirect, getAppNameFromRedirect } from '../lib/redirect';
import InformConstraintsModal from '../components/InformConstraintsModal';

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
  const [signupModalOpen, setSignupModalOpen] = useState(false);

  const validRedirect = getValidRedirect();
  const appName = validRedirect ? getAppNameFromRedirect(validRedirect) : null;

  // Preserve ?redirect= when linking to /signup (Connected path)
  const signupHref = validRedirect
    ? `/signup?redirect=${encodeURIComponent(validRedirect)}`
    : '/signup';

  // Preserve ?redirect= when linking to /signup/inform (Inform path)
  const informSignupHref = validRedirect
    ? `/signup/inform?redirect=${encodeURIComponent(validRedirect)}`
    : '/signup/inform';

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      // Step 1: authenticate
      const loginRes = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      if (!loginRes.ok) {
        const body = await loginRes.json().catch(() => ({ message: 'Login failed' }));
        throw new Error(body.message || body.error || 'Login failed');
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

      // Step 3: persist token synchronously before navigating — the useEffect that
      // writes to sessionStorage won't fire before window.location.href tears down the page.
      sessionStorage.setItem('admin_token', token);

      const target = validRedirect || 'https://login.empowered.vote/profile';
      window.location.href = target;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unexpected error occurred');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-ev-black px-4 py-12">

      {/* Wordmark */}
      <div className="mb-8 text-center space-y-1">
        <h1 className="text-3xl font-bold text-ev-teal dark:text-ev-teal-light tracking-tight">
          empowered.vote
        </h1>
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-sm p-6 w-full max-w-sm space-y-5">

        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Log in</h2>

        {appName && (
          <div className="p-3 bg-ev-teal/10 dark:bg-ev-teal-light/10 border border-ev-teal/20 dark:border-ev-teal-light/20 rounded-xl text-sm text-ev-teal dark:text-ev-teal-light text-center">
            You'll be returned to {appName} after logging in
          </div>
        )}

        {error && (
          <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800/60 rounded-xl text-red-700 dark:text-ev-red text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
              Email
            </label>
            <input
              id="email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
              placeholder="you@example.com"
              className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal dark:focus:ring-ev-teal-light focus:border-transparent"
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
              Password
            </label>
            <input
              id="password"
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
              className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal dark:focus:ring-ev-teal-light focus:border-transparent"
            />
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full py-3 px-4 bg-ev-teal dark:bg-ev-teal-light hover:bg-ev-teal/90 dark:hover:bg-ev-teal-light/90 disabled:opacity-60 text-white dark:text-ev-black font-semibold rounded-xl text-sm transition-colors"
          >
            {isSubmitting ? 'Logging in…' : 'Log in'}
          </button>
        </form>

        <div className="space-y-3 pt-2">
          <button
            type="button"
            onClick={() => setSignupModalOpen(true)}
            className="w-full py-3 px-4 bg-ev-yellow hover:bg-ev-yellow/90 text-ev-black font-semibold rounded-xl text-sm transition-colors"
          >
            Create an Account
          </button>
          <p className="text-center text-xs text-gray-500 dark:text-gray-500">
            Have an invite code?{' '}
            <Link to={signupHref} className="text-ev-teal dark:text-ev-teal-light hover:underline font-medium">
              Create a Connected Account
            </Link>
          </p>
        </div>
        <p className="text-center text-xs text-gray-400 dark:text-gray-600 mt-2">
          <Link to="/privacy" className="hover:underline">Privacy Policy</Link>
        </p>
      </div>

      <InformConstraintsModal
        open={signupModalOpen}
        onClose={() => setSignupModalOpen(false)}
        onContinue={() => {
          setSignupModalOpen(false);
          navigate(informSignupHref);
        }}
        onUseInviteCode={() => {
          setSignupModalOpen(false);
          navigate(signupHref);
        }}
      />
    </div>
  );
}
