import { useState, useMemo } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { apiFetch } from '../lib/api';

const ERROR_MESSAGES: Record<string, string> = {
  INVALID_INVITE_CODE: 'That invite code is invalid or has already been used.',
  EMAIL_EXISTS: 'An account with this email already exists.',
  VALIDATION_ERROR: 'Please check your entries and try again.',
  RATE_LIMIT_EXCEEDED: 'Too many attempts. Please wait a moment and try again.',
  EMAIL_DELIVERY_FAILED: 'Unable to send confirmation email right now. Please try again shortly.',
};

function getValidatedRedirectUrl(): string | null {
  const raw = new URLSearchParams(window.location.search).get('redirect');
  if (!raw) return null;
  // Security: only allow https:// URLs to prevent open redirect attacks
  if (!raw.startsWith('https://')) return null;
  return raw;
}

export default function SignupPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [legalName, setLegalName] = useState('');
  const [inviteCode, setInviteCode] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);

  // Parse redirect URL once on mount — do NOT re-parse on every render
  const redirectUrl = useMemo(() => getValidatedRedirectUrl(), []);

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
      <div className="min-h-screen flex items-center justify-center bg-ev-black px-6">
        <div className="max-w-sm w-full text-center space-y-6">
          <div className="flex justify-center">
            <div className="w-16 h-16 rounded-full bg-ev-teal-light/10 flex items-center justify-center">
              <svg className="w-8 h-8 text-ev-teal-light" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
              </svg>
            </div>
          </div>
          <div className="space-y-2">
            <h1 className="text-2xl font-bold text-white">Check your email.</h1>
            <p className="text-gray-400 leading-relaxed">
              We sent a confirmation link to <span className="font-medium text-white">{email}</span>.
              Click it to activate your account, then come back to sign in.
            </p>
          </div>
          <button
            onClick={handleGoToSignIn}
            className="w-full bg-ev-teal-light text-ev-black rounded-xl py-3 font-bold hover:bg-ev-teal-light/90 transition-colors"
          >
            Go to sign in
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-ev-black px-6 py-12">

      {/* Wordmark */}
      <div className="mb-8 text-center space-y-1">
        <h1 className="text-3xl font-bold text-ev-teal-light tracking-tight">empowered.vote</h1>
        <p className="text-gray-500 text-sm">Your civic profile</p>
      </div>

      <div className="w-full max-w-sm bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5">

        <div className="space-y-1">
          <h2 className="text-lg font-semibold text-white">Create your Connected Account</h2>
          <p className="text-sm text-gray-500">You'll need an invite code to join.</p>
        </div>

        {/* One Account notice */}
        <div className="bg-ev-teal-light/10 border border-ev-teal-light/20 rounded-xl p-4 space-y-1">
          <p className="text-sm font-semibold text-ev-teal-light">One Account, One Voice</p>
          <p className="text-xs text-gray-400 leading-relaxed">
            This will be your only Empowered Vote account — one person, one voice.
            Your data is private by default.
          </p>
        </div>

        {error && (
          <div className="bg-red-950/40 border border-red-800/60 rounded-xl px-4 py-3">
            <p className="text-sm text-ev-red">{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1.5">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
              className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal-light text-base"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1.5">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={8}
              autoComplete="new-password"
              className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal-light text-base"
            />
            <p className="mt-1 text-xs text-gray-500">At least 8 characters.</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1.5">Your full legal name</label>
            <input
              type="text"
              value={legalName}
              onChange={(e) => setLegalName(e.target.value)}
              required
              autoComplete="name"
              className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal-light text-base"
            />
            <p className="mt-1 text-xs text-gray-500">Used for identity verification only. Never shown publicly.</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1.5">Invite code</label>
            <input
              type="text"
              value={inviteCode}
              onChange={(e) => setInviteCode(e.target.value.toUpperCase())}
              required
              placeholder="XXXX-XXXX"
              autoComplete="off"
              spellCheck={false}
              className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal-light text-base font-mono tracking-wider"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-ev-teal-light text-ev-black rounded-xl py-3.5 font-bold text-base hover:bg-ev-teal-light/90 disabled:opacity-40 transition-colors"
          >
            {loading ? 'Creating account…' : 'Create Account'}
          </button>
        </form>

        <p className="text-center text-sm text-gray-500">
          Already have an account?{' '}
          <Link to="/login" className="text-ev-teal-light font-medium hover:underline">
            Sign in
          </Link>
        </p>
      </div>
    </div>
  );
}
