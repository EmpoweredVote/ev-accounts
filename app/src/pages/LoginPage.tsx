import { useState, useMemo } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { apiFetch } from '../lib/api';
import { getValidRedirect } from '../lib/redirect';
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

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { setAuth } = useAuthStore();
  const navigate = useNavigate();

  // Parse redirect URL once on mount — do NOT re-parse on every render
  const redirectUrl = useMemo(() => getValidRedirect(), []);

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
    <AuthPageLayout>
      <div className="space-y-6">
        {redirectUrl && (
          <div className="p-3 bg-ev-blue/10 border border-ev-blue/30 rounded-lg text-sm text-gray-300 text-center">
            We've made some improvements. Please log in again to continue.
          </div>
        )}

        <AuthCard>
          <h2 className="text-lg font-semibold text-white">Log in</h2>

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
