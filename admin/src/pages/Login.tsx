import { useState, useEffect, useRef, FormEvent } from 'react';
import { useNavigate, Link } from 'react-router';
import { useAuthStore } from '../store/authStore';
import { getValidRedirect, getAppNameFromRedirect, validateRedirectUrl } from '../lib/redirect';
import {
  workosEnabled,
  authkitOnly,
  embeddedAuthEnabled,
  startWorkosSignIn,
  completeWorkosLogin,
  consumeWorkosRedirectState,
  loginWithPassword,
  verifyEmailCode,
} from '../lib/workosAuth';
import InformConstraintsModal from '../components/InformConstraintsModal';
import AuthShell from '../components/AuthShell';

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
  // When the embedded flag is on, the login form must be available even
  // under AuthKit-only mode — it's our own form now, not the hidden classic
  // Supabase one, so it isn't subject to authkitOnly's hide-the-form rule.
  const showLoginForm = showClassic || embeddedAuthEnabled;
  const navigate = useNavigate();
  const { setAuth, accessToken, isAuthenticated, isLoading } = useAuthStore();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [signupModalOpen, setSignupModalOpen] = useState(false);
  const [showUnverifiedResend, setShowUnverifiedResend] = useState(false);
  const [resendSent, setResendSent] = useState(false);

  // Embedded WorkOS flow (flag-gated): a pending status from
  // loginWithPassword switches the card to this on-page code step instead of
  // the hosted AuthKit redirect.
  const [codeStep, setCodeStep] = useState(false);
  const [code, setCode] = useState('');
  const [codeResent, setCodeResent] = useState(false);

  const validRedirect = getValidRedirect();
  const appName = validRedirect ? getAppNameFromRedirect(validRedirect) : null;
  const isCodeCallback = workosEnabled && new URLSearchParams(window.location.search).has('code');
  const ssoHandledRef = useRef(false);

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
      // Cross-app handoff: feature apps (compass, VQ, essentials, …) read the
      // token from the URL HASH fragment — never a query param, so it stays out
      // of server logs and history. Matches CompassV2's documented contract and
      // the app build's handoff.
      window.location.href = `${redirectTarget}#access_token=${encodeURIComponent(token)}`;
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

  // Auto-forward (decision 0002): under AuthKit-only mode the classic form is
  // hidden and AuthKit's own hosted page already offers sign-in AND sign-up, so
  // this landing is a redundant click. Skip straight to AuthKit — EXCEPT on the
  // break-glass route (allowClassic), EXCEPT while completing a ?code=
  // callback (that would loop), and EXCEPT when the embedded flag is on — the
  // embedded flow renders our own form instead of bouncing to the hosted
  // page, so authkitOnly must not auto-forward past it. Invite-code signup
  // has its own /signup entry, so nothing is lost by not rendering the landing.
  const [autoForwarding, setAutoForwarding] = useState(
    () =>
      authkitOnly &&
      !allowClassic &&
      !embeddedAuthEnabled &&
      !(workosEnabled && new URLSearchParams(window.location.search).has('code'))
  );
  const autoForwardStarted = useRef(false);

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

  useEffect(() => {
    // Wait for bootstrap; never auto-forward an already-signed-in user — the SSO
    // effect below hands them off (or to /profile) instead.
    if (isLoading || isAuthenticated || !autoForwarding || autoForwardStarted.current) return;
    autoForwardStarted.current = true; // StrictMode re-runs effects — start once
    (async () => {
      try {
        await startWorkosSignIn(validRedirect ? { redirect: validRedirect } : undefined);
        // The page redirects to AuthKit; nothing further renders.
      } catch (err) {
        // AuthKit unreachable — fall back to the full landing so the user (and
        // the /login/classic break-glass link) are never stranded on a spinner.
        setError(err instanceof Error ? err.message : 'Could not start sign-in');
        setAutoForwarding(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isLoading, isAuthenticated]);

  // Silent cross-app SSO + already-signed-in handoff. Reuses the session App
  // bootstrap already restored (a second /session call here would race the
  // cookie rotation and could sign the user out). Once bootstrap resolves: if
  // signed in, hand the token to the requesting feature app via the
  // #access_token= fragment it expects, or land on /profile. Break-glass never
  // auto-continues; a ?code= callback has its own effect.
  useEffect(() => {
    if (isLoading || allowClassic || isCodeCallback || ssoHandledRef.current) return;
    if (!isAuthenticated || !accessToken) return; // signed out → show the form
    ssoHandledRef.current = true;
    if (validRedirect) {
      window.location.href = `${validRedirect}#access_token=${encodeURIComponent(accessToken)}`;
    } else {
      navigate('/profile', { replace: true });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isLoading, isAuthenticated, accessToken]);

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

  // Embedded WorkOS flow: the classic form posts here instead of handleSubmit
  // when embeddedAuthEnabled. A pending status (email verification or MFA)
  // switches to the code step rather than treating it as a failure.
  async function handleEmbeddedSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      const result = await loginWithPassword(email, password);
      if (result.status === 'authenticated') {
        await finishLogin(result.token, validRedirect, email);
      } else if (result.status === 'email_verification_required') {
        setCodeStep(true);
      } else {
        // mfa_required: the code step calls verify-email, which uses the
        // email-verification grant and cannot satisfy an MFA challenge —
        // advancing there would just fail on submit. MFA sign-in isn't wired
        // up yet, so stop here with an explanation instead.
        setError("Multi-factor sign-in isn't available yet. Please contact support.");
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sign-in failed');
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

  // Re-run sign-in to have WorkOS issue a fresh code (and a fresh pending
  // cookie) when the first didn't arrive or expired.
  async function handleResendCode() {
    setError(null);
    setCodeResent(false);
    try {
      await loginWithPassword(email, password);
      setCodeResent(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not resend the code');
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

  // While bootstrap is still resolving the session — or we're about to hand an
  // existing one back — show a brief notice instead of flashing the form.
  // Break-glass always shows the form; a ?code= callback renders its own state.
  const showResolving =
    !allowClassic && !isCodeCallback && (isLoading || (isAuthenticated && !!accessToken));
  if (showResolving) {
    return (
      <AuthShell>
        <p className="text-sm text-center text-gray-500 dark:text-gray-400">One moment…</p>
      </AuthShell>
    );
  }

  // While auto-forwarding to AuthKit, show only a redirect notice — the full
  // landing would flash for a frame before the page navigates away.
  if (autoForwarding) {
    return (
      <AuthShell>
        <p className="text-sm text-center text-gray-500 dark:text-gray-400">Redirecting to sign in…</p>
      </AuthShell>
    );
  }

  return (
    <>
    <AuthShell heading={codeStep ? 'Enter your code' : 'Log in'}>
      <div className="space-y-5">

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

        {showLoginForm && !codeStep && (
        <form onSubmit={embeddedAuthEnabled && !allowClassic ? handleEmbeddedSubmit : handleSubmit} className="space-y-4">
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

        {showLoginForm && codeStep && (
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
              className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal dark:focus:ring-ev-teal-light focus:border-transparent text-center tracking-[0.5em]"
            />
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full py-3 px-4 bg-ev-teal dark:bg-ev-teal-light hover:bg-ev-teal/90 dark:hover:bg-ev-teal-light/90 disabled:opacity-60 text-white dark:text-ev-black font-semibold rounded-xl text-sm transition-colors"
          >
            {isSubmitting ? 'Verifying…' : 'Verify'}
          </button>

          <div className="text-center">
            <button type="button" onClick={handleResendCode} className="text-xs text-ev-teal dark:text-ev-teal-light hover:underline">
              Resend code
            </button>
            {codeResent && (
              <p className="mt-1 text-xs text-green-600 dark:text-green-400">A new code is on its way.</p>
            )}
          </div>

          <button
            type="button"
            onClick={() => { setCodeStep(false); setCode(''); setError(null); setCodeResent(false); }}
            className="w-full text-center text-xs text-ev-teal dark:text-ev-teal-light hover:underline"
          >
            Back to email and password
          </button>
        </form>
        )}

        {workosEnabled && !embeddedAuthEnabled && (
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
          <p className="text-center text-xs text-gray-600 dark:text-gray-400">
            Have an invite code?{' '}
            <Link to={signupHref} className="text-ev-teal dark:text-ev-teal-light hover:underline font-medium">
              Create a Connected Account
            </Link>
          </p>
        </div>

        <p className="text-center text-xs text-gray-500 dark:text-gray-400">
          <Link to="/privacy" className="hover:underline">Privacy Policy</Link>
        </p>
      </div>
    </AuthShell>

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
    </>
  );
}
