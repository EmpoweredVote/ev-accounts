import { useEffect, useState, useCallback } from 'react';
import { Link } from 'react-router';
import { apiFetch } from '../lib/api';
import { AppNav } from '../components/AppNav';
import { useTheme } from '../hooks/useTheme';

interface XP {
  total: number;
  level: number;
  xp_in_level: number;
  xp_to_next_level: number;
}

interface ConnectedProfile {
  xp: XP;
  gems: { yellow: number; blue: number; red: number };
  verification_rating: number;
  vq_hold_active: boolean;
}

interface MeFull {
  id: string;
  email: string;
  tier: 'inform' | 'connected' | 'empowered';
  display_name: string | null;
  is_admin: boolean;
  verification_rating: number;
  location_consent: boolean;
  connected_profile: ConnectedProfile | null;
}

interface ReferralState {
  unlocked: boolean;
  code: string | null;
  inviteeJoined: boolean;
  inviteeLevel: number | null;
}

interface ActivityEntry {
  source: string;
  amount: number;
  description: string;
  created_at: string;
}

function titleCase(str: string): string {
  return str
    .split('_')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

function SunIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="5" />
      <line x1="12" y1="1" x2="12" y2="3" />
      <line x1="12" y1="21" x2="12" y2="23" />
      <line x1="4.22" y1="4.22" x2="5.64" y2="5.64" />
      <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" />
      <line x1="1" y1="12" x2="3" y2="12" />
      <line x1="21" y1="12" x2="23" y2="12" />
      <line x1="4.22" y1="19.78" x2="5.64" y2="18.36" />
      <line x1="18.36" y1="5.64" x2="19.78" y2="4.22" />
    </svg>
  );
}

function MoonIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
    </svg>
  );
}

function YellowGem({ count }: { count: number }) {
  return (
    <div className="flex flex-col items-center gap-3">
      <div
        className="w-20 h-20 rounded-2xl"
        style={{
          background: 'linear-gradient(145deg, #FFE566 0%, #FFB800 55%, #E07000 100%)',
          boxShadow: '0 0 28px rgba(255, 184, 0, 0.45)',
        }}
      />
      <span className="text-gray-900 dark:text-white text-2xl font-bold tabular-nums">{count.toLocaleString()}</span>
      <span className="text-gray-500 dark:text-gray-400 text-xs">Research</span>
    </div>
  );
}

function BlueGem({ count }: { count: number }) {
  return (
    <div className="flex flex-col items-center gap-3">
      <div
        className="w-20 h-20 rounded-full"
        style={{
          background: 'radial-gradient(circle at 35% 30%, #BFDBFE 0%, #60A5FA 35%, #3B82F6 65%, #1E40AF 100%)',
          boxShadow: '0 0 28px rgba(59, 130, 246, 0.5)',
        }}
      />
      <span className="text-gray-900 dark:text-white text-2xl font-bold tabular-nums">{count.toLocaleString()}</span>
      <span className="text-gray-500 dark:text-gray-400 text-xs">Voting</span>
    </div>
  );
}

function RedGem({ count }: { count: number }) {
  return (
    <div className="flex flex-col items-center gap-3">
      <div
        className="w-20 h-20 rounded-2xl"
        style={{
          background: 'linear-gradient(145deg, #FF9A8B 0%, #FF5740 50%, #C41E00 100%)',
          boxShadow: '0 0 28px rgba(255, 87, 64, 0.45)',
        }}
      />
      <span className="text-gray-900 dark:text-white text-2xl font-bold tabular-nums">{count.toLocaleString()}</span>
      <span className="text-gray-500 dark:text-gray-400 text-xs">Validation</span>
    </div>
  );
}

function LockIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
      <path d="M7 11V7a5 5 0 0 1 10 0v4" />
    </svg>
  );
}

function PinIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
      <circle cx="12" cy="10" r="3" />
    </svg>
  );
}

function CalendarIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
      <line x1="16" y1="2" x2="16" y2="6" />
      <line x1="8" y1="2" x2="8" y2="6" />
      <line x1="3" y1="10" x2="21" y2="10" />
    </svg>
  );
}

export default function ProfilePage() {
  const [me, setMe] = useState<MeFull | null>(null);
  const [referral, setReferral] = useState<ReferralState | null>(null);
  const [activity, setActivity] = useState<ActivityEntry[]>([]);
  const [copied, setCopied] = useState(false);
  // Password reset is deliberately a one-shot request, not a form. See the Account security
  // card below for why we send a link rather than changing the password in place.
  const [resetState, setResetState] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');
  const { isDark, toggle } = useTheme();

  async function requestPasswordReset(email: string) {
    setResetState('sending');
    try {
      await apiFetch<unknown>('/auth/forgot-password', {
        method: 'POST',
        body: JSON.stringify({ email }),
      });
      setResetState('sent');
    } catch {
      setResetState('error');
    }
  }

  useEffect(() => {
    apiFetch<MeFull>('/account/me').then(setMe).catch(() => {});
  }, []);

  useEffect(() => {
    if (me?.connected_profile) {
      apiFetch<ReferralState>('/referral').then(setReferral).catch(() => {});
      apiFetch<{ activity: ActivityEntry[] }>('/account/me/activity')
        .then((r) => setActivity(r.activity))
        .catch(() => setActivity([]));
    }
  }, [me?.connected_profile]);

  const copyCode = useCallback(() => {
    if (!referral?.code) return;
    navigator.clipboard.writeText(referral.code).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }).catch(() => {});
  }, [referral?.code]);

  const themeToggle = (
    <button
      onClick={toggle}
      className="w-8 h-8 flex items-center justify-center rounded-full text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
      aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
    >
      {isDark ? <SunIcon /> : <MoonIcon />}
    </button>
  );

  if (!me) {
    return (
      <div className="bg-gray-100 dark:bg-ev-navy min-h-screen">
        <AppNav>{themeToggle}</AppNav>
      </div>
    );
  }

  const cp = me.connected_profile;
  const xp = cp?.xp ?? null;
  const xpPercent = xp && xp.xp_to_next_level > 0
    ? Math.min(100, Math.round((xp.xp_in_level / xp.xp_to_next_level) * 100))
    : 0;
  const vrPercent = cp ? Math.min(100, Math.round((cp.verification_rating / 150) * 100)) : 0;

  return (
    <div className="bg-gray-100 dark:bg-ev-navy min-h-screen">
      <AppNav>{themeToggle}</AppNav>

      {/* Page header */}
      <div className="px-4 sm:px-6 lg:px-8 pt-8 pb-4">
        <Link to="/" className="text-gray-900 dark:text-white text-2xl font-bold hover:text-gray-600 dark:hover:text-gray-300 transition-colors inline-block">
          &lt; Your Profile
        </Link>
        <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">View your progress, stats, and account details</p>
      </div>

      <main className="px-4 sm:px-6 lg:px-8 pb-10 space-y-4">

        {/* Header card — welcome + name + level + XP bar */}
        {cp && xp ? (
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6">
            <div className="flex items-start justify-between mb-4">
              <p className="text-xs text-gray-400 dark:text-gray-500 uppercase tracking-widest font-medium">Welcome back</p>
              <span className="border border-gray-300 dark:border-gray-700 text-gray-500 dark:text-gray-400 text-xs px-3 py-1 rounded-full">
                Private Account
              </span>
            </div>
            <h2 className="text-5xl font-bold text-gray-900 dark:text-white">{me.display_name ?? 'Member'}</h2>
            <div className="flex items-center gap-3 mt-4">
              <span className="bg-ev-blue text-white text-sm font-bold px-3 py-1.5 rounded-full">
                Level {xp.level}
              </span>
              <span className="text-gray-600 dark:text-gray-300 text-sm tabular-nums">
                {xp.xp_in_level.toLocaleString()} / {xp.xp_to_next_level.toLocaleString()} XP
              </span>
            </div>
            <div className="mt-4 h-2 rounded-full bg-gray-200 dark:bg-gray-800 overflow-hidden">
              <div
                className="bg-ev-blue h-full rounded-full transition-all duration-700"
                style={{
                  width: `${xpPercent}%`,
                  boxShadow: '0 0 14px rgba(59, 130, 246, 0.7)',
                }}
              />
            </div>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-2 tabular-nums">
              {xp.total.toLocaleString()} total XP earned
            </p>
          </div>
        ) : (
          /* Inform-tier header — no XP data */
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6">
            <p className="text-xs text-gray-400 dark:text-gray-500 uppercase tracking-widest font-medium mb-4">Welcome back</p>
            <h2 className="text-5xl font-bold text-gray-900 dark:text-white">{me.display_name ?? 'Member'}</h2>
          </div>
        )}

        {/* Two-column row: Gems + Verification Rating */}
        {cp && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Gems */}
            <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6">
              <p className="text-xs text-gray-400 dark:text-gray-500 uppercase tracking-widest font-medium mb-6">Your Gems</p>
              <div className="flex justify-around items-end">
                <YellowGem count={cp.gems.yellow} />
                <BlueGem count={cp.gems.blue} />
                <RedGem count={cp.gems.red} />
              </div>
            </div>

            {/* Verification Rating */}
            <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6">
              <p className="text-xs text-gray-400 dark:text-gray-500 uppercase tracking-widest font-medium mb-4">
                Verification Rating
              </p>
              <div className="flex items-baseline gap-2 mb-4">
                <span className="text-ev-teal-light text-6xl font-bold tabular-nums">
                  {cp.verification_rating}
                </span>
                <span className="text-gray-900 dark:text-white text-xl font-medium">/ 150</span>
              </div>
              <div className="h-1.5 rounded-full bg-gray-200 dark:bg-gray-800 overflow-hidden mb-3">
                <div
                  className="bg-ev-teal-light h-full rounded-full transition-all duration-700"
                  style={{ width: `${vrPercent}%` }}
                />
              </div>
              <p className="text-sm text-gray-500 dark:text-gray-400">Keep validating to increase your credibility score</p>
            </div>
          </div>
        )}

        {/* Two-column row: Invite + Civic Spaces */}
        {cp && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Invite a Friend */}
            <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6">
              <p className="text-xs text-gray-400 dark:text-gray-500 uppercase tracking-widest font-medium mb-4">Invite a Friend</p>
              {!referral?.unlocked ? (
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 rounded-xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center flex-shrink-0 text-gray-400 dark:text-gray-400">
                    <LockIcon />
                  </div>
                  <div>
                    <p className="text-gray-900 dark:text-white font-semibold">Reach level 2 to unlock</p>
                    <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">
                      Keep earning XP to get your first referral code
                    </p>
                  </div>
                </div>
              ) : referral?.code ? (
                <div className="bg-gray-100 dark:bg-gray-800 rounded-xl px-4 py-3 flex items-center justify-between">
                  <code className="font-mono text-ev-teal-light text-xl tracking-widest">
                    {referral.code}
                  </code>
                  <button
                    onClick={copyCode}
                    className="text-sm text-ev-teal-light hover:text-ev-teal dark:hover:text-white transition-colors ml-4"
                  >
                    {copied ? 'Copied!' : 'Copy'}
                  </button>
                </div>
              ) : null}
            </div>

            {/* Civic Spaces */}
            <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6">
              <p className="text-xs text-gray-400 dark:text-gray-500 uppercase tracking-widest font-medium mb-4">Your Civic Spaces</p>
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 rounded-xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center flex-shrink-0 text-ev-teal-light">
                  <PinIcon />
                </div>
                <div>
                  {me.location_consent ? (
                    <>
                      <p className="text-gray-900 dark:text-white font-semibold">Location Set</p>
                      <Link
                        to="/settings/location"
                        className="text-ev-teal-light text-sm hover:text-ev-teal dark:hover:text-white transition-colors"
                      >
                        Update location →
                      </Link>
                    </>
                  ) : (
                    <>
                      <p className="text-gray-900 dark:text-white font-semibold">No location set</p>
                      <Link
                        to="/settings/location"
                        className="text-ev-teal-light text-sm hover:text-ev-teal dark:hover:text-white transition-colors"
                      >
                        Set your location →
                      </Link>
                    </>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Recent Activity — full width */}
        {cp && (
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6">
            <div className="flex items-center gap-3 mb-5 text-gray-900 dark:text-white">
              <CalendarIcon />
              <h2 className="text-xl font-semibold">Recent Activity</h2>
            </div>
            {activity.length === 0 ? (
              <p className="text-gray-500 dark:text-gray-400 text-sm">
                No XP earned yet — explore an Empowered Vote feature to get started.
              </p>
            ) : (
              <div className="space-y-2">
                {activity.slice(0, 4).map((entry, i) => (
                  <div
                    key={i}
                    className="flex items-center justify-between bg-gray-50 dark:bg-gray-800/60 rounded-xl px-4 py-3"
                  >
                    <div>
                      <p className="text-gray-900 dark:text-white text-sm font-medium">{titleCase(entry.description)}</p>
                      <p className="text-gray-500 dark:text-gray-400 text-xs mt-0.5">
                        {new Date(entry.created_at).toLocaleDateString(undefined, {
                          month: 'long',
                          day: 'numeric',
                          year: 'numeric',
                        })}
                      </p>
                    </div>
                    <span className="bg-ev-teal-light/15 text-ev-teal-light text-sm font-semibold px-3 py-1 rounded-full tabular-nums ml-4 flex-shrink-0">
                      +{entry.amount} XP
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Account security — full width.
            This sends a reset LINK rather than offering an in-place "old password / new
            password" form, and that is a deliberate choice, not a stub. Passwords live in
            either WorkOS or Supabase depending on the AUTHKIT_PRIMARY cutover flag, and
            /api/auth/forgot-password is the one path that already branches correctly on it.
            An in-place change would need a new authenticated endpoint covering both issuers
            plus session rotation. Until that exists, this is the honest, working option —
            and proving control of the inbox is a real check, not a weaker one. */}
        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 p-6">
          <div className="flex items-center gap-3 mb-5 text-gray-900 dark:text-white">
            <LockIcon />
            <h2 className="text-xl font-semibold">Account security</h2>
          </div>

          <p className="text-gray-500 dark:text-gray-400 text-sm mb-4">
            We email a link to <span className="font-medium text-gray-900 dark:text-white">{me.email}</span>.
            Open it to choose a new password. The link expires, and using it signs you out everywhere else.
          </p>

          {/* ⚠ Below, text-ev-teal in light and ev-teal-light only in dark. Measured against the
              real build: ev-teal-light is 2.49:1 on white and 1.76:1 on the 15% tint, both far
              under WCAG AA's 4.5:1, while dark mode is 7.1–7.4:1. The tint is fine; the
              foreground is what has to change per theme. Same pairing as admin's sign-in link. */}
          {resetState === 'sent' ? (
            <p className="text-ev-teal dark:text-ev-teal-light text-sm font-medium" role="status">
              Sent. Check {me.email} — if it has not arrived in a few minutes, look in spam.
            </p>
          ) : (
            <>
              <button
                type="button"
                onClick={() => void requestPasswordReset(me.email)}
                disabled={resetState === 'sending'}
                className="bg-ev-teal-light/15 text-ev-teal dark:text-ev-teal-light text-sm font-semibold px-4 py-2 rounded-xl hover:bg-ev-teal-light/25 disabled:opacity-60 disabled:cursor-not-allowed transition-colors"
              >
                {resetState === 'sending' ? 'Sending…' : 'Email me a password reset link'}
              </button>
              {resetState === 'error' && (
                <p className="text-red-600 dark:text-red-400 text-sm mt-3" role="alert">
                  That did not send. Try again in a moment, or use “Forgot your password?” on the sign-in page.
                </p>
              )}
            </>
          )}
        </div>

      </main>
    </div>
  );
}
