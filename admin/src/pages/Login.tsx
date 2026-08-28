import { useState, useEffect, useRef, FormEvent } from 'react';
import { useNavigate, Link } from 'react-router';
import { useAuthStore } from '../store/authStore';
import { getValidRedirect, getAppNameFromRedirect, validateRedirectUrl } from '../lib/redirect';
import {
  workosEnabled,
  authkitOnly,
  startWorkosSignIn,
  completeWorkosLogin,
  consumeWorkosRedirectState,
} from '../lib/workosAuth';
import InformConstraintsModal from '../components/InformConstraintsModal';

const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

/**
 * allowClassic — break-glass. The /login/classic route renders this with the
 * classic email/password form forced visible even under AuthKit-only mode.
 */
export default function Login({ allowClassic = false }: { allowClassic?: boolean }) {
  // Classic form shows unless AuthKit-only mode has hidden it — and always on
  // the break-glass route.
  const showClassic = allowClassic || !authkitOnly;
  const navigate = useNavigate();
  const { setAuth } = useAuthStore();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [signupModalOpen, setSignupModalOpen] = useState(false);
  const [showUnverifiedResend, setShowUnverifiedResend] = useState(false);
  const [resendSent, setResendSent] = useState(false);

  const validRedirect = getValidRedirect();
  const appName = validRedirect ? getAppNameFromRedirect(validRedirect) : null;

  const signupHref = validRedirect
    ? `/signup?redirect=${encodeURIComponent(validRedirect)}`
    : '/signup';

  const informSignupHref = validRedirect
    ? `/signup/inform?redirect=${encodeURIComponent(validRedirect)}`
    : '/signup/inform';

  const forgotHref = email
    ? `/forgot-password?email=${encodeURIComponent(email)}`
    : '/forgot-password';

  // Shared post-login continuation for both flows: hydrate identity, persist
  // the token, honor a validated redirect target or land on /profile.
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

    // After login, honor an explicit (validated) redirect target; otherwise
    // navigate to /profile on the CURRENT origin. Previously this hard-coded
    // https://login.empowered.vote/profile, which threw users who logged in on
    // another origin (e.g. accounts.empowered.vote) off-origin — their
    // just-saved session lived in this origin's storage, not login's, so they
    // landed logged-out and had to sign in a second time.
    if (redirectTarget) {
      window.location.href = redirectTarget;
    } else {
      navigate('/profile');
    }
  }

  // WorkOS AuthKit return leg (decision 0002): the hosted page redirects back
  // here with ?code=. The SDK exchanges it inside completeWorkosLogin; the
  // redirect target round-trips through OAuth state and is UNTRUSTED, so it
  // goes through the same allowlist as ?redirect=.
  const [workosCompleting, setWorkosCompleting] = useState(
    () => workosEnabled && new URLSearchParams(window.location.search).has('code')
  );
  const workosCallbackStarted = useRef(false);

  useEffect(() => {
    if (!workosCompleting || workosCallbackStarted.current) return;
    workosCallbackStarted.current = true; // StrictMode re-runs effects — exchange once
    (async () => {
      try {
        const state = await consumeWorkosRedirectState();
        const token = await completeWorkosLogin();
        const target = validateRedirectUrl(
          typeof state?.redirect === 'string' ? state.redirect : null
        );
        await finishLogin(token, target);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Sign-in failed');
        setWorkosCompleting(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function handleWorkosSignIn() {
    setError(null);
    try {
      await startWorkosSignIn(validRedirect ? { redirect: validRedirect } : undefined);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not start sign-in');
    }
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      const loginRes = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      if (!loginRes.ok) {
        const body = await loginRes.json().catch(() => ({ message: 'Login failed' }));
        if (body.code === 'EMAIL_NOT_VERIFIED') {
          setShowUnverifiedResend(true);
        }
        throw new Error(body.message || body.error || 'Login failed');
      }

      const loginData = await loginRes.json();
      await finishLogin(loginData.access_token, validRedirect, email);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unexpected error occurred');
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleResendConfirmation() {
    await fetch(`${API_BASE}/auth/resend-confirmation`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    }).catch(() => {});
    setResendSent(true);
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-ev-black px-4 py-12">

      <div className="mb-8 text-center">
        <h1 className="text-3xl font-bold text-ev-teal dark:text-ev-teal-light tracking-tight">
          empowered.vote
        </h1>
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-sm p-6 w-full max-w-sm space-y-5">

        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Log in</h2>

        {workosCompleting && (
          <div className="p-3 bg-ev-teal/10 dark:bg-ev-teal-light/10 border border-ev-teal/20 dark:border-ev-teal-light/20 rounded-xl text-sm text-ev-teal dark:text-ev-teal-light text-center">
            Completing sign-in…
          </div>
        )}

        {appName && (
          <div className="p-3 bg-ev-teal/10 dark:bg-ev-teal-light/10 border border-ev-teal/20 dark:border-ev-teal-light/20 rounded-xl text-sm text-ev-teal dark:text-ev-teal-light text-center">
            You'll be returned to {appName} after logging in
          </div>
        )}

        {error && (
          <div className="p-3 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800/60 rounded-xl text-red-700 dark:text-ev-red text-sm space-y-2">
            <p>{error}</p>
            {showUnverifiedResend && (
              resendSent
                ? <p className="text-green-700 dark:text-green-400 font-medium">Confirmation email sent — check your inbox.</p>
                : <button type="button" onClick={handleResendConfirmation} className="underline font-medium hover:no-underline">
                    Resend confirmation email
                  </button>
            )}
          </div>
        )}

        {showClassic && (
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
            <div className="flex justify-between items-center mb-1.5">
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Password
              </label>
              <Link to={forgotHref} className="text-xs text-ev-teal dark:text-ev-teal-light hover:underline">
                Forgot your password?
              </Link>
            </div>
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
        )}

        {workosEnabled && (
          <div className="space-y-3">
            {showClassic && (
              <div className="flex items-center gap-3">
                <div className="flex-1 h-px bg-gray-200 dark:bg-gray-800" />
                <span className="text-xs text-gray-400 dark:text-gray-600">or</span>
                <div className="flex-1 h-px bg-gray-200 dark:bg-gray-800" />
              </div>
            )}
            <button
              type="button"
              onClick={handleWorkosSignIn}
              disabled={workosCompleting}
              className={
                showClassic
                  ? 'w-full py-3 px-4 bg-white dark:bg-gray-800 border border-ev-teal dark:border-ev-teal-light text-ev-teal dark:text-ev-teal-light hover:bg-ev-teal/5 dark:hover:bg-ev-teal-light/10 disabled:opacity-60 font-semibold rounded-xl text-sm transition-colors'
                  : 'w-full py-3 px-4 bg-ev-teal dark:bg-ev-teal-light hover:bg-ev-teal/90 dark:hover:bg-ev-teal-light/90 disabled:opacity-60 text-white dark:text-ev-black font-semibold rounded-xl text-sm transition-colors'
              }
            >
              {workosCompleting ? 'Signing in…' : showClassic ? 'Sign in with the new login (beta)' : 'Sign in'}
            </button>
          </div>
        )}

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

        <p className="text-center text-xs text-gray-400 dark:text-gray-600">
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
