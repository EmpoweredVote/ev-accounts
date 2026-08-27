import { useState, FormEvent, Fragment } from 'react';
import { Link, useNavigate } from 'react-router';
import { Dialog, Transition } from '@headlessui/react';
import { getValidRedirect, getAppNameFromRedirect } from '../lib/redirect';

const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

export default function Signup() {
  const navigate = useNavigate();

  const validRedirect = getValidRedirect();
  const appName = validRedirect ? getAppNameFromRedirect(validRedirect) : null;

  // Preserve ?redirect= when linking back to /login
  const loginHref = validRedirect
    ? `/login?redirect=${encodeURIComponent(validRedirect)}`
    : '/login';

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [displayName, setDisplayName] = useState('');
  const [legalName, setLegalName] = useState('');
  const [inviteCode, setInviteCode] = useState('');
  const [resendSent, setResendSent] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Request access modal state
  const [modalOpen, setModalOpen] = useState(false);
  const [requestEmail, setRequestEmail] = useState('');
  const [requestStatus, setRequestStatus] = useState<'idle' | 'submitting' | 'done'>('idle');
  const [requestError, setRequestError] = useState<string | null>(null);

  async function handleResend() {
    await fetch(`${API_BASE}/auth/resend-confirmation`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    }).catch(() => {});
    setResendSent(true);
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
      let normalizedCode = inviteCode.toUpperCase().trim();
      if (normalizedCode.length === 8 && !normalizedCode.includes('-')) {
        normalizedCode = normalizedCode.slice(0, 4) + '-' + normalizedCode.slice(4);
      }

      const res = await fetch(`${API_BASE}/auth/signup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email,
          password,
          display_name: displayName,
          legal_name: legalName,
          invite_code: normalizedCode,
        }),
      });

      if (res.status === 201) {
        setSuccess(true);
        return;
      }

      const body = await res.json().catch(() => ({ error: 'An unexpected error occurred' }));

      if (res.status === 422) {
        const code = body.code ?? '';
        if (code === 'INVALID_INVITE_CODE') {
          throw new Error('Invalid or already claimed invite code');
        }
        if (code === 'SELF_INVITE_BLOCKED') {
          throw new Error('You cannot use your own invite code');
        }
        throw new Error(body.message || body.error || 'Validation error');
      }

      if (res.status === 409) {
        throw new Error('An account with this email already exists');
      }

      throw new Error(body.message || body.error || 'An unexpected error occurred');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unexpected error occurred');
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleRequestAccess(e: FormEvent) {
    e.preventDefault();
    setRequestError(null);
    setRequestStatus('submitting');

    try {
      const res = await fetch(`${API_BASE}/auth/request-access`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: requestEmail }),
      });

      if (res.status === 201) {
        setRequestStatus('done');
        setTimeout(() => {
          setModalOpen(false);
          setRequestStatus('idle');
          setRequestEmail('');
        }, 2000);
        return;
      }

      const body = await res.json().catch(() => ({ error: 'An unexpected error occurred' }));
      throw new Error(body.error || 'An unexpected error occurred');
    } catch (err) {
      setRequestError(err instanceof Error ? err.message : 'An unexpected error occurred');
      setRequestStatus('idle');
    }
  }

  if (success) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-950">
        <div className="bg-white dark:bg-gray-900 rounded-lg shadow-md p-8 w-full max-w-md text-center">
          <div className="flex justify-center mb-6">
            <img
              src="/Empowered_Vote_Logo_2026.png"
              alt="Empowered Vote"
              className="h-12 object-contain"
            />
          </div>
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-2">Check your email</h2>
          <p className="text-gray-600 dark:text-gray-400 text-sm">
            We sent a confirmation link to <strong>{email}</strong>. Click it to activate your
            account.
          </p>
          <p className="mt-3 text-sm text-gray-500 dark:text-gray-400">
            {resendSent ? (
              <span className="text-green-700 dark:text-green-400">Another email is on its way.</span>
            ) : (
              <>Didn't get it?{' '}
                <button type="button" onClick={handleResend} className="text-ev-teal hover:underline font-medium">
                  Resend email
                </button>
              </>
            )}
          </p>
          <p className="mt-3 text-sm text-gray-500 dark:text-gray-400">
            Already confirmed?{' '}
            <button
              onClick={() => navigate(loginHref)}
              className="text-ev-teal hover:underline font-medium"
            >
              Sign in
            </button>
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-950">
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow-md p-8 w-full max-w-md">
        <div className="flex justify-center mb-6">
          <img
            src="/Empowered_Vote_Logo_2026.png"
            alt="Empowered Vote"
            className="h-12 object-contain"
          />
        </div>

        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6 text-center">
          Create your Connected Account
        </h1>

        {appName && (
          <div className="mb-4 p-3 bg-ev-teal/10 border border-ev-teal/20 rounded text-sm text-ev-teal text-center">
            You'll be returned to {appName} after signing in
          </div>
        )}

        {/* Covenant callout */}
        <div className="mb-5 p-4 bg-ev-teal-light/10 border border-ev-teal-light/30 rounded-md">
          <p className="text-sm font-semibold text-ev-teal mb-1">One Account, One Voice</p>
          <p className="text-xs text-gray-600 dark:text-gray-400">
            This will be your only Empowered Vote account — one person, one voice. Your data is
            private by default.
          </p>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Email
            </label>
            <input
              id="email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-ev-teal focus:border-transparent dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
              placeholder="you@example.com"
            />
          </div>

          <div>
            <div className="flex justify-between items-center mb-1">
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Password
              </label>
              <button type="button" onClick={() => setShowPassword(v => !v)} className="text-xs text-ev-teal hover:underline">
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
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-ev-teal focus:border-transparent dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
              placeholder="At least 8 characters"
            />
          </div>

          <div>
            <div className="flex justify-between items-center mb-1">
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Confirm password
              </label>
              <button type="button" onClick={() => setShowConfirmPassword(v => !v)} className="text-xs text-ev-teal hover:underline">
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
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-ev-teal focus:border-transparent dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
              placeholder="Repeat your password"
            />
          </div>

          <div>
            <label htmlFor="displayName" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
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
              autoComplete="nickname"
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-ev-teal focus:border-transparent dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
              placeholder="What should we call you?"
            />
          </div>

          <div>
            <label htmlFor="legalName" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Your full legal name
            </label>
            <input
              id="legalName"
              type="text"
              required
              value={legalName}
              onChange={(e) => setLegalName(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-ev-teal focus:border-transparent dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
              placeholder="First Last"
            />
          </div>

          <div>
            <label htmlFor="inviteCode" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Invite code
            </label>
            <input
              id="inviteCode"
              type="text"
              required
              value={inviteCode}
              onChange={(e) => setInviteCode(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-ev-teal focus:border-transparent font-mono dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
              placeholder="XXXX-XXXX"
            />
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full py-2 px-4 bg-ev-teal hover:bg-ev-teal/90 disabled:opacity-60 text-white font-medium rounded-md text-sm transition-colors"
          >
            {isSubmitting ? 'Creating account...' : 'Create Account'}
          </button>
        </form>

        <div className="mt-4 space-y-2 text-center">
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Don't have a code?{' '}
            <button
              type="button"
              onClick={() => setModalOpen(true)}
              className="text-ev-teal hover:underline font-medium"
            >
              Request access
            </button>
          </p>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Already have an account?{' '}
            <Link to={loginHref} className="text-ev-teal hover:underline font-medium">
              Sign in
            </Link>
          </p>
          <p className="text-sm text-gray-400 dark:text-gray-500">
            <Link to="/privacy" className="hover:underline">Privacy Policy</Link>
          </p>
        </div>
      </div>

      {/* Request Access Modal */}
      <Transition appear show={modalOpen} as={Fragment}>
        <Dialog as="div" className="relative z-50" onClose={() => setModalOpen(false)}>
          <Transition.Child
            as={Fragment}
            enter="ease-out duration-200"
            enterFrom="opacity-0"
            enterTo="opacity-100"
            leave="ease-in duration-150"
            leaveFrom="opacity-100"
            leaveTo="opacity-0"
          >
            <div className="fixed inset-0 bg-black/30" />
          </Transition.Child>

          <div className="fixed inset-0 flex items-center justify-center p-4">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-200"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-150"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="bg-white dark:bg-gray-900 rounded-lg shadow-xl p-6 w-full max-w-sm">
                <Dialog.Title className="text-lg font-bold text-gray-900 dark:text-white mb-2">
                  Request Access
                </Dialog.Title>
                <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                  Don't have an invite code? Enter your email and we'll notify you when access
                  becomes available.
                </p>

                {requestStatus === 'done' ? (
                  <p className="text-sm text-green-700 font-medium text-center py-2">
                    Request submitted! We'll be in touch.
                  </p>
                ) : (
                  <form onSubmit={handleRequestAccess} className="space-y-3">
                    {requestError && (
                      <div className="p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
                        {requestError}
                      </div>
                    )}
                    <input
                      type="email"
                      required
                      value={requestEmail}
                      onChange={(e) => setRequestEmail(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-ev-teal focus:border-transparent dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
                      placeholder="you@example.com"
                    />
                    <div className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => setModalOpen(false)}
                        className="flex-1 py-2 px-4 border border-gray-300 text-gray-700 dark:border-gray-600 dark:text-gray-300 font-medium rounded-md text-sm hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
                      >
                        Cancel
                      </button>
                      <button
                        type="submit"
                        disabled={requestStatus === 'submitting'}
                        className="flex-1 py-2 px-4 bg-ev-teal hover:bg-ev-teal/90 disabled:opacity-60 text-white font-medium rounded-md text-sm transition-colors"
                      >
                        {requestStatus === 'submitting' ? 'Submitting...' : 'Submit'}
                      </button>
                    </div>
                  </form>
                )}
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </Dialog>
      </Transition>
    </div>
  );
}
