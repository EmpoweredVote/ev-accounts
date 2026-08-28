import { useState, FormEvent } from 'react';
import { Link, useNavigate } from 'react-router';
import { getValidRedirect, getAppNameFromRedirect } from '../lib/redirect';
import { useAuthStore } from '../store/authStore';
import { embeddedAuthEnabled, loginWithPassword, verifyEmailCode } from '../lib/workosAuth';

const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

export default function InformSignup() {
  const navigate = useNavigate();
  const { setAuth } = useAuthStore();

  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [resendSent, setResendSent] = useState(false);

  // Embedded WorkOS flow (flag-gated): a brand-new account's email is always
  // unverified, so the signup response routes straight into the same
  // on-page code step Login.tsx uses, instead of the "check your email" card.
  const [codeStep, setCodeStep] = useState(false);
  const [code, setCode] = useState('');

  const validRedirect = getValidRedirect();
  const appName = validRedirect ? getAppNameFromRedirect(validRedirect) : null;
  const loginHref = validRedirect ? `/login?redirect=${encodeURIComponent(validRedirect)}` : '/login';
  const connectedSignupHref = validRedirect ? `/signup?redirect=${encodeURIComponent(validRedirect)}` : '/signup';

  async function handleResend() {
    await fetch(`${API_BASE}/auth/resend-confirmation`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    }).catch(() => {});
    setResendSent(true);
  }

  // Shared post-login continuation (mirrors Login.tsx's finishLogin): hydrate
  // identity, persist the token, honor a validated redirect target or land on
  // /profile.
  async function finishLogin(token: string, redirectTarget: string | null, fallbackEmail = '') {
    const meRes = await fetch(`${API_BASE}/account/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (!meRes.ok) {
      throw new Error('Failed to load account information.');
    }

    const meData = await meRes.json();

    setAuth(token, {
      id: meData.id ?? '',
      email: meData.email ?? fallbackEmail,
      isAdmin: meData.is_admin ?? false,
      tier: meData.tier ?? 'inform',
      completedOnboarding: meData.completed_onboarding ?? false,
    });

    sessionStorage.setItem('admin_token', token);

    if (redirectTarget) {
      window.location.href = redirectTarget;
    } else {
      navigate('/profile');
    }
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }
    setIsSubmitting(true);
    try {
      const res = await fetch(`${API_BASE}/auth/signup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email,
          password,
          display_name: displayName,
        }),
      });

      if (res.status === 201) {
        if (embeddedAuthEnabled) {
          // Brand-new account, unverified email: this always comes back
          // pending. Route straight into the on-page code step instead of
          // the "check your email" card.
          const result = await loginWithPassword(email, password);
          if (result.status === 'authenticated') {
            await finishLogin(result.token, validRedirect, email);
          } else {
            setCodeStep(true);
          }
        } else {
          setSuccess(true);
        }
        return;
      }

      const body = await res.json().catch(() => ({ error: 'An unexpected error occurred' }));

      if (res.status === 422) {
        throw new Error(body.message ?? body.error ?? 'Validation error');
      }
      if (res.status === 409) {
        throw new Error('An account with this email already exists');
      }
      if (res.status === 429) {
        throw new Error('Too many requests — please try again in a few minutes');
      }
      if (res.status === 503) {
        throw new Error('Unable to send confirmation email right now. Please try again shortly.');
      }
      throw new Error(body.message ?? body.error ?? 'An unexpected error occurred');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unexpected error occurred');
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleCodeSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      const token = await verifyEmailCode(code);
      await finishLogin(token, validRedirect, email);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Verification failed');
    } finally {
      setIsSubmitting(false);
    }
  }

  if (codeStep) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-ev-black px-4 py-12">
        <div className="mb-8 text-center space-y-1">
          <h1 className="text-3xl font-bold text-ev-teal dark:text-ev-teal-light tracking-tight">
            empowered.vote
          </h1>
        </div>
        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-ev-yellow/30 shadow-sm p-6 w-full max-w-sm space-y-5">
          <span className="inline-block px-3 py-1 rounded-full bg-ev-yellow text-ev-black text-xs font-semibold tracking-wide">
            Inform Account
          </span>
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Enter your code</h2>

          {error && (
            <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800/60 rounded-xl text-red-700 dark:text-ev-red text-sm">
              {error}
            </div>
          )}

          <form onSubmit={handleCodeSubmit} className="space-y-4">
            <div>
              <label htmlFor="code" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                Verification code
              </label>
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-1.5">
                Enter the 6-digit verification code to continue.
              </p>
              <input
                id="code"
                type="text"
                required
                inputMode="numeric"
                autoComplete="one-time-code"
                minLength={6}
                maxLength={6}
                pattern="[0-9]{6}"
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                placeholder="123456"
                className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-yellow focus:border-transparent text-center tracking-[0.5em]"
              />
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full py-3 px-4 bg-ev-yellow hover:bg-ev-yellow/90 disabled:opacity-60 text-ev-black font-semibold rounded-xl text-sm transition-colors"
            >
              {isSubmitting ? 'Verifying…' : 'Verify'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  if (success) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-ev-black px-4 py-12">
        <div className="mb-8 text-center space-y-1">
          <h1 className="text-3xl font-bold text-ev-teal dark:text-ev-teal-light tracking-tight">
            empowered.vote
          </h1>
        </div>
        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-ev-yellow/30 shadow-sm p-6 w-full max-w-sm space-y-5 text-center">
          <span className="inline-block px-3 py-1 rounded-full bg-ev-yellow text-ev-black text-xs font-semibold tracking-wide">
            Inform Account
          </span>
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Check your email</h2>
          <p className="text-sm text-gray-600 dark:text-gray-400">
            We sent a confirmation link to <strong className="text-gray-900 dark:text-white">{email}</strong>.
            Click it to activate your Inform Account.
          </p>
          {resendSent ? (
            <p className="text-sm text-green-700 dark:text-green-400">Another confirmation email is on its way.</p>
          ) : (
            <p className="text-sm text-gray-500 dark:text-gray-500">
              Didn't get it?{' '}
              <button type="button" onClick={handleResend} className="text-ev-teal dark:text-ev-teal-light hover:underline font-medium">
                Resend email
              </button>
            </p>
          )}
          <p className="text-sm text-gray-500 dark:text-gray-500">
            Already confirmed?{' '}
            <Link to={loginHref} className="text-ev-teal dark:text-ev-teal-light hover:underline font-medium">
              Sign in
            </Link>
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-ev-black px-4 py-12">

      {/* Wordmark */}
      <div className="mb-8 text-center space-y-1">
        <h1 className="text-3xl font-bold text-ev-teal dark:text-ev-teal-light tracking-tight">
          empowered.vote
        </h1>
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-ev-yellow/30 shadow-sm p-6 w-full max-w-sm space-y-5">

        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Create your Inform Account</h2>

        <p className="text-sm text-gray-500 dark:text-gray-400">
          Read civic data. Explore your representatives. No invite required.
        </p>

        {appName && (
          <div className="p-3 bg-ev-teal/10 dark:bg-ev-teal-light/10 border border-ev-teal/20 dark:border-ev-teal-light/20 rounded-xl text-sm text-ev-teal dark:text-ev-teal-light text-center">
            You'll be returned to {appName} after signing in
          </div>
        )}

        {error && (
          <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800/60 rounded-xl text-red-700 dark:text-ev-red text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="displayName" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
              Display name
            </label>
            <input
              id="displayName"
              type="text"
              required
              minLength={1}
              maxLength={100}
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              autoComplete="name"
              placeholder="What should we call you?"
              className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-yellow focus:border-transparent"
            />
          </div>

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
              className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-yellow focus:border-transparent"
            />
          </div>

          <div>
            <div className="flex justify-between items-center mb-1.5">
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Password
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
              className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-yellow focus:border-transparent"
            />
          </div>

          <div>
            <div className="flex justify-between items-center mb-1.5">
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Confirm password
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
              className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-yellow focus:border-transparent"
            />
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full py-3 px-4 bg-ev-yellow hover:bg-ev-yellow/90 disabled:opacity-60 text-ev-black font-semibold rounded-xl text-sm transition-colors"
          >
            {isSubmitting ? 'Creating account…' : 'Create my Inform Account'}
          </button>
        </form>

        <p className="text-center text-sm text-gray-500 dark:text-gray-500">
          Already have an account?{' '}
          <Link to={loginHref} className="text-ev-teal dark:text-ev-teal-light hover:underline font-medium">
            Sign in
          </Link>
        </p>
        <p className="text-center text-xs text-gray-500 dark:text-gray-500">
          Have an invite code?{' '}
          <Link to={connectedSignupHref} className="text-ev-teal dark:text-ev-teal-light hover:underline font-medium">
            Create a Connected Account
          </Link>
        </p>
        <p className="text-center text-xs text-gray-400 dark:text-gray-600">
          <Link to="/privacy" className="hover:underline">Privacy Policy</Link>
        </p>
      </div>
    </div>
  );
}
