import { useState, FormEvent } from 'react';
import { Link, useSearchParams } from 'react-router';
import AuthShell from '../components/AuthShell';

const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

export default function ForgotPassword() {
  const [searchParams] = useSearchParams();
  const [email, setEmail] = useState(searchParams.get('email') ?? '');
  const [submitting, setSubmitting] = useState(false);
  const [sent, setSent] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    await fetch(`${API_BASE}/auth/forgot-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    }).catch(() => {});
    setSubmitting(false);
    setSent(true);
  }

  return (
    <AuthShell heading={sent ? 'Check your email' : 'Reset your password'}>
      <div className="space-y-5">

        {sent ? (
          <>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              If <strong className="text-gray-900 dark:text-white">{email}</strong> is registered,
              a password reset link is on its way. Check your spam folder if it doesn't arrive
              within a few minutes.
            </p>
            <Link
              to="/login"
              className="block text-center text-sm text-ev-teal dark:text-ev-teal-light hover:underline font-medium"
            >
              Back to login
            </Link>
          </>
        ) : (
          <>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Enter your email and we'll send you a reset link.
            </p>

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

              <button
                type="submit"
                disabled={submitting}
                className="w-full py-3 px-4 bg-ev-teal dark:bg-ev-teal-light hover:bg-ev-teal/90 disabled:opacity-60 text-white dark:text-ev-black font-semibold rounded-xl text-sm transition-colors"
              >
                {submitting ? 'Sending…' : 'Send reset link'}
              </button>
            </form>

            <p className="text-center text-sm text-gray-600 dark:text-gray-400">
              Remember it?{' '}
              <Link to="/login" className="text-ev-teal dark:text-ev-teal-light hover:underline font-medium">
                Back to login
              </Link>
            </p>
          </>
        )}
      </div>
    </AuthShell>
  );
}
