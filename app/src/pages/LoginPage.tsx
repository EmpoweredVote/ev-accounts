import { useState, useMemo, useEffect, useRef } from 'react';
import { useNavigate, Link } from 'react-router';
import { apiFetch } from '../lib/api';
import { getValidRedirect, validateRedirectUrl } from '../lib/redirect';
import {
  workosEnabled,
  authkitOnly,
  startWorkosSignIn,
  completeWorkosLogin,
  consumeWorkosRedirectState,
} from '../lib/workosAuth';
import { useAuthStore, type User } from '../store/authStore';
import { AuthPageLayout } from '../components/AuthPageLayout';
import { AuthCard } from '../components/AuthCard';
import { AuthInput } from '../components/AuthInput';
import { PrimaryButton } from '../components/PrimaryButton';

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

// allowClassic — break-glass route /login/classic forces the classic form
// visible even under AuthKit-only mode (decision 0002).
export default function LoginPage({ allowClassic = false }: { allowClassic?: boolean }) {
  const showClassic = allowClassic || !authkitOnly;
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { setAuth } = useAuthStore();
  const navigate = useNavigate();

  // Parse redirect URL once on mount — do NOT re-parse on every render
  const redirectUrl = useMemo(() => getValidRedirect(), []);

  // WorkOS AuthKit return leg (decision 0002): the hosted page redirects back
  // here with ?code=. The redirect target round-trips through OAuth state and
  // is UNTRUSTED, so it goes through the same allowlist as ?redirect=. Note:
  // the WorkOS path never appends the #access_token fragment — that handoff
  // belongs to the classic flow only.
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
        useAuthStore.setState({ accessToken: token });
        const me = await apiFetch<MeResponse>('/account/me');
        const user: User = {
          id: me.id,
          email: me.email,
          tier: me.tier,
          displayName: me.display_name,
          completedOnboarding: me.completed_onboarding,
          locationConsent: me.location_consent,
        };
        setAuth(useAuthStore.getState().accessToken ?? token, user);
        const target = validateRedirectUrl(
          typeof state?.redirect === 'string' ? state.redirect : null
        );
        if (target) {
          window.location.href = target;
        } else {
          navigate('/');
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Sign-in failed');
        setWorkosCompleting(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function handleWorkosSignIn() {
    setError('');
    try {
      await startWorkosSignIn(redirectUrl ? { redirect: redirectUrl } : undefined);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not start sign-in');
    }
  }

  // Auto-forward (decision 0002): under AuthKit-only the classic form is hidden
  // and AuthKit's hosted page offers sign-in AND sign-up, so this landing is a
  // redundant click. Skip straight to AuthKit — except on /login/classic
  // (allowClassic) and except while completing a ?code= callback.
  const [autoForwarding, setAutoForwarding] = useState(
    () =>
      authkitOnly &&
      !allowClassic &&
      !(workosEnabled && new URLSearchParams(window.location.search).has('code'))
  );
  const autoForwardStarted = useRef(false);

  useEffect(() => {
    if (!autoForwarding || autoForwardStarted.current) return;
    autoForwardStarted.current = true;
    (async () => {
      try {
        await startWorkosSignIn(redirectUrl ? { redirect: redirectUrl } : undefined);
      } catch (err) {
        // AuthKit unreachable — fall back to the full landing.
        setError(err instanceof Error ? err.message : 'Could not start sign-in');
        setAutoForwarding(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

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

  if (autoForwarding) {
    return (
      <AuthPageLayout>
        <p className="text-sm text-gray-400 text-center">Redirecting to sign in…</p>
      </AuthPageLayout>
    );
  }

  return (
    <AuthPageLayout>
      <div className="space-y-6">
        {redirectUrl && (
          <div className="p-3 bg-ev-blue/10 border border-ev-blue/30 rounded-lg text-sm text-gray-300 text-center">
            We've made some improvements. Please log in again to continue.
          </div>
        )}

        <AuthCard>
          <h2 className="text-lg font-semibold text-white">Log in</h2>

          {showClassic && (
          <form onSubmit={handleSubmit} className="space-y-4">
            <AuthInput
              label="Email"
              type="email"
              value={email}
              onChange={setEmail}
              autoComplete="email"
              required
            />

            <AuthInput
              label="Password"
              type="password"
              value={password}
              onChange={setPassword}
              autoComplete="current-password"
              required
            />

            {error && <p className="text-ev-red text-sm">{error}</p>}

            <PrimaryButton type="submit" disabled={loading}>
              {loading ? 'Logging in…' : 'Log in'}
            </PrimaryButton>
          </form>
          )}

          {workosEnabled && (
            <div className="space-y-3">
              {showClassic && (
                <div className="flex items-center gap-3">
                  <div className="flex-1 h-px bg-gray-700" />
                  <span className="text-xs text-gray-500">or</span>
                  <div className="flex-1 h-px bg-gray-700" />
                </div>
              )}
              {!showClassic && error && <p className="text-ev-red text-sm">{error}</p>}
              <button
                type="button"
                onClick={handleWorkosSignIn}
                disabled={workosCompleting}
                className={
                  showClassic
                    ? 'w-full py-3 px-4 bg-transparent border border-ev-teal-light text-ev-teal-light hover:bg-ev-teal-light/10 disabled:opacity-60 font-semibold rounded-lg text-sm transition-colors'
                    : 'w-full py-3 px-4 bg-ev-teal-light text-ev-black hover:bg-ev-teal-light/90 disabled:opacity-60 font-semibold rounded-lg text-sm transition-colors'
                }
              >
                {workosCompleting ? 'Completing sign-in…' : showClassic ? 'Sign in with the new login (beta)' : 'Sign in'}
              </button>
            </div>
          )}

          <p className="text-center text-sm text-gray-500">
            Don't have an account?{' '}
            <Link to="/signup" className="text-ev-teal-light font-medium hover:underline">
              Create account
            </Link>
          </p>
        </AuthCard>
      </div>
    </AuthPageLayout>
  );
}
