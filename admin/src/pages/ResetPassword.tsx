import { useState, FormEvent } from 'react';
import { useNavigate, useSearchParams, Link } from 'react-router';
import AuthShell from '../components/AuthShell';

const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

export default function ResetPassword() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const tokenHash = searchParams.get('token_hash');

  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [done, setDone] = useState(false);

  if (!tokenHash) {
    return (
      <AuthShell heading="Reset link expired" subheading="This reset link is invalid or has expired.">
        <div className="text-center">
          <Link to="/login" className="text-ev-teal dark:text-ev-teal-light hover:underline text-sm font-medium">
            Back to login
          </Link>
        </div>
      </AuthShell>
    );
  }

  if (done) {
    return (
      <AuthShell heading="Password updated">
        <div className="text-center space-y-4">
          <p className="text-sm text-gray-600 dark:text-gray-400">You can now sign in with your new password.</p>
          <button
            onClick={() => navigate('/login')}
            className="w-full py-3 px-4 bg-ev-teal dark:bg-ev-teal-light hover:bg-ev-teal/90 text-white dark:text-ev-black font-semibold rounded-xl text-sm transition-colors"
          >
            Sign in
          </button>
        </div>
      </AuthShell>
    );
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }
    setSubmitting(true);
    try {
      const res = await fetch(`${API_BASE}/auth/reset-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token_hash: tokenHash, password }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(body.message || body.error || 'An unexpected error occurred');
      }
      setDone(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unexpected error occurred');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AuthShell heading="Set a new password">
      <div className="space-y-5">

        {error && (
          <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800/60 rounded-xl text-red-700 dark:text-ev-red text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <div className="flex justify-between items-center mb-1.5">
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                New password
              </label>
              <button type="button" onClick={() => setShowPassword(v => !v)} className="text-xs text-ev-teal dark:text-ev-teal-light hover:underline">
                {showPassword ? 'Hide' : 'Show'}
              </button>
            </div>
            <input
              id="password"
              type={showPassword ? 'text' : 'password'}
              required
              minLength={8}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="new-password"
              placeholder="At least 8 characters"
              className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal dark:focus:ring-ev-teal-light focus:border-transparent"
            />
          </div>

          <div>
            <div className="flex justify-between items-center mb-1.5">
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Confirm new password
              </label>
              <button type="button" onClick={() => setShowConfirmPassword(v => !v)} className="text-xs text-ev-teal dark:text-ev-teal-light hover:underline">
                {showConfirmPassword ? 'Hide' : 'Show'}
              </button>
            </div>
            <input
              id="confirmPassword"
              type={showConfirmPassword ? 'text' : 'password'}
              required
              minLength={8}
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              autoComplete="new-password"
              placeholder="Repeat your password"
              className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal dark:focus:ring-ev-teal-light focus:border-transparent"
            />
          </div>

          <button
            type="submit"
            disabled={submitting}
            className="w-full py-3 px-4 bg-ev-teal dark:bg-ev-teal-light hover:bg-ev-teal/90 disabled:opacity-60 text-white dark:text-ev-black font-semibold rounded-xl text-sm transition-colors"
          >
            {submitting ? 'Updating…' : 'Update password'}
          </button>
        </form>

        <p className="text-center text-xs text-gray-500 dark:text-gray-400">
          <Link to="/login" className="hover:underline">Back to login</Link>
        </p>
      </div>
    </AuthShell>
  );
}
