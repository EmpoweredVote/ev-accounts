import { useState, useMemo } from 'react';
import { Link, useNavigate } from 'react-router';
import { apiFetch } from '../lib/api';
import { getValidRedirect } from '../lib/redirect';
import { AuthPageLayout } from '../components/AuthPageLayout';
import { AuthCard } from '../components/AuthCard';
import { AuthInput } from '../components/AuthInput';
import { PrimaryButton } from '../components/PrimaryButton';

const ERROR_MESSAGES: Record<string, string> = {
  INVALID_INVITE_CODE: 'That invite code is invalid or has already been used.',
  EMAIL_EXISTS: 'An account with this email already exists.',
  VALIDATION_ERROR: 'Please check your entries and try again.',
  RATE_LIMIT_EXCEEDED: 'Too many attempts. Please wait a moment and try again.',
  EMAIL_DELIVERY_FAILED: 'Unable to send confirmation email right now. Please try again shortly.',
};

export default function SignupPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [legalName, setLegalName] = useState('');
  const [inviteCode, setInviteCode] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);

  // Parse redirect URL once on mount — do NOT re-parse on every render
  const redirectUrl = useMemo(() => getValidRedirect(), []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await apiFetch('/auth/signup', {
        method: 'POST',
        body: JSON.stringify({
          email: email.trim(),
          password,
          display_name: displayName.trim(),
          legal_name: legalName.trim(),
          invite_code: inviteCode.trim().toUpperCase(),
        }),
      });
      setDone(true);
    } catch (err) {
      const code = err instanceof Error ? err.message : '';
      setError(ERROR_MESSAGES[code] ?? 'Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  function handleGoToSignIn() {
    if (redirectUrl) {
      navigate('/login?redirect=' + encodeURIComponent(redirectUrl));
    } else {
      navigate('/login');
    }
  }

  if (done) {
    return (
      <AuthPageLayout>
        <AuthCard>
              <div className="flex justify-center">
                <div className="w-16 h-16 rounded-full bg-ev-blue/10 flex items-center justify-center">
                  <svg
                    className="w-8 h-8 text-ev-blue"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth={2.5}
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75"
                    />
                  </svg>
                </div>
              </div>

              <div className="space-y-2 text-center">
                <h1 className="text-2xl font-bold text-white">Check your email</h1>
                <p className="text-gray-400 leading-relaxed">
                  We sent a magic-link to{' '}
                  <span className="font-medium text-white">{email}</span>.
                  Click the link to confirm your account, then come back to sign in.
                </p>
              </div>

              <PrimaryButton onClick={handleGoToSignIn}>
                Go to sign in
              </PrimaryButton>
            </AuthCard>
      </AuthPageLayout>
    );
  }

  return (
    <AuthPageLayout step={{ current: 1, total: 3 }}>
      <AuthCard>
            <div className="space-y-1">
              <h2 className="text-lg font-semibold text-white">Create your Connected Account</h2>
              <p className="text-sm text-gray-400">Step 1 of 3 — set up your sign-in.</p>
            </div>

            {error && (
              <div className="bg-red-950/40 border border-red-800/60 rounded-xl px-4 py-3">
                <p className="text-sm text-ev-red">{error}</p>
              </div>
            )}

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
                autoComplete="new-password"
                required
                inputProps={{ minLength: 8 }}
              />
              <p className="-mt-2 text-xs text-gray-500">At least 8 characters.</p>

              <div className="space-y-1.5">
                <AuthInput
                  label="Civic name"
                  type="text"
                  value={displayName}
                  onChange={setDisplayName}
                  placeholder="e.g. Alex from Oakland"
                  autoComplete="nickname"
                  required
                />
                <p className="text-xs text-gray-400 leading-relaxed">
                  This is how your voice appears in civic spaces and discussions.
                </p>
              </div>

              <div className="space-y-1.5">
                <AuthInput
                  label="Legal name"
                  type="text"
                  value={legalName}
                  onChange={setLegalName}
                  autoComplete="name"
                  required
                />
                <p className="text-xs text-gray-400 leading-relaxed">
                  During Alpha, your identity is verified through our invite network — one person, one voice.
                </p>
              </div>

              <div className="space-y-1.5">
                <AuthInput
                  label="Invite code"
                  type="text"
                  value={inviteCode}
                  onChange={(value) => setInviteCode(value.toUpperCase())}
                  placeholder="XXXX-XXXX"
                  autoComplete="off"
                  required
                  inputClassName="font-mono tracking-wider"
                  inputProps={{ spellCheck: false }}
                />
                <div className="flex items-start gap-2 text-xs text-gray-400 leading-relaxed">
                  <svg
                    className="w-4 h-4 text-ev-blue flex-shrink-0 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth={2}
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z"
                    />
                  </svg>
                  <span>
                    Access is invite-only during Alpha to ensure trusted participation.
                    This trust-based system builds accountability in our community.
                  </span>
                </div>
              </div>

              <PrimaryButton type="submit" disabled={loading}>
                {loading ? 'Creating account…' : 'Create account'}
              </PrimaryButton>
            </form>

            <p className="text-center text-sm text-gray-500">
              Already have an account?{' '}
              <Link to="/login" className="text-ev-teal-light font-medium hover:underline">
                Sign in
              </Link>
            </p>
      </AuthCard>
    </AuthPageLayout>
  );
}
