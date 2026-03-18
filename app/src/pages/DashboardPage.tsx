import { useEffect, useState, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { apiFetch } from '../lib/api';

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

interface Jurisdiction {
  congressional_district_name: string | null;
  state_senate_district_name: string | null;
  state_house_district_name: string | null;
  county_name: string | null;
  school_district_name: string | null;
}

interface ReferralState {
  unlocked: boolean;
  code: string | null;
  inviteeJoined: boolean;
  inviteeLevel: number | null;
}

interface MeFull {
  id: string;
  email: string;
  tier: 'inform' | 'connected' | 'empowered';
  display_name: string | null;
  completed_onboarding: boolean;
  location_consent: boolean;
  is_admin: boolean;
  verification_rating: number;
  vq_hold_active: boolean;
  red_gem_quests_unlocked: boolean;
  connected_profile: ConnectedProfile | null;
}

const TIER_LABEL: Record<string, string> = {
  inform: 'Inform',
  connected: 'Connected',
  empowered: 'Empowered',
};

const TIER_COLOR: Record<string, string> = {
  inform: 'bg-ev-yellow/20 text-ev-black dark:text-ev-yellow',
  connected: 'bg-ev-teal/15 text-ev-teal',
  empowered: 'bg-ev-red/15 text-ev-red',
};

const FEATURES = [
  {
    name: 'Civic Trivia',
    description: 'Test your civic knowledge and earn XP.',
    url: 'https://ctc.empowered.vote',
    dot: 'bg-ev-yellow',
  },
  {
    name: 'Validation Quests',
    description: 'Validate political stances and earn Red Gems.',
    url: 'https://quests.empowered.vote',
    dot: 'bg-ev-red',
  },
  {
    name: 'Essentials',
    description: 'Explore your representatives\' positions.',
    url: 'https://essentials.empowered.vote',
    dot: 'bg-ev-teal',
  },
  {
    name: 'Empowered Compass',
    description: 'Map your political values.',
    url: 'https://compass.empowered.vote',
    dot: 'bg-ev-teal-light',
  },
];

const DISTRICT_LABELS: { key: keyof Jurisdiction; label: string }[] = [
  { key: 'congressional_district_name', label: 'U.S. Congress' },
  { key: 'state_senate_district_name', label: 'State Senate' },
  { key: 'state_house_district_name', label: 'State House' },
  { key: 'county_name', label: 'County' },
  { key: 'school_district_name', label: 'School District' },
];

function GemBadge({ count, color, label }: { count: number; color: string; label: string }) {
  return (
    <div className="flex flex-col items-center gap-1">
      <div className={`w-9 h-9 rounded-full ${color} flex items-center justify-center`}>
        <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
        </svg>
      </div>
      <span className="text-sm font-semibold text-ev-black dark:text-white tabular-nums">{count.toLocaleString()}</span>
      <span className="text-xs text-gray-400">{label}</span>
    </div>
  );
}

export default function DashboardPage() {
  const { user, clearAuth } = useAuthStore();
  const [me, setMe] = useState<MeFull | null>(null);
  const [jurisdiction, setJurisdiction] = useState<Jurisdiction | null>(null);
  const [referral, setReferral] = useState<ReferralState | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    apiFetch<MeFull>('/account/me').then(setMe).catch(() => {});
  }, []);

  useEffect(() => {
    if (me?.location_consent) {
      apiFetch<{ jurisdiction: Jurisdiction }>('/account/me/jurisdiction')
        .then((r) => setJurisdiction(r.jurisdiction))
        .catch(() => {});
    }
  }, [me?.location_consent]);

  useEffect(() => {
    if (me?.connected_profile) {
      apiFetch<ReferralState>('/referral').then(setReferral).catch(() => {});
    }
  }, [me?.connected_profile]);

  const copyCode = useCallback(() => {
    if (!referral?.code) return;
    navigator.clipboard.writeText(referral.code).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }).catch(() => {});
  }, [referral?.code]);

  const cp = me?.connected_profile ?? null;
  const xp = cp?.xp ?? null;
  const xpPercent = xp && xp.xp_to_next_level > 0
    ? Math.round((xp.xp_in_level / xp.xp_to_next_level) * 100)
    : 0;
  const vrPercent = cp ? Math.round((cp.verification_rating / 150) * 100) : 0;

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-ev-black">
      {/* Nav */}
      <header className="bg-white dark:bg-gray-950 border-b border-gray-100 dark:border-gray-800 sticky top-0 z-10">
        <div className="max-w-lg mx-auto px-4 h-14 flex items-center justify-between">
          <span className="font-bold text-ev-teal text-lg">profile.empowered.vote</span>
          <button
            onClick={clearAuth}
            className="text-sm text-gray-400 hover:text-ev-red transition-colors"
          >
            Sign out
          </button>
        </div>
      </header>

      <main className="max-w-lg mx-auto px-4 py-6 space-y-4">

        {/* Admin Hub button */}
        {me?.is_admin && (
          <a
            href="https://accounts.empowered.vote/admin"
            className="flex items-center justify-between bg-ev-red/10 border border-ev-red/30 rounded-2xl p-4 group"
          >
            <div>
              <p className="text-sm font-semibold text-ev-red">Admin Hub</p>
              <p className="text-xs text-gray-500 mt-0.5">Manage users, invites, and platform settings.</p>
            </div>
            <svg className="w-4 h-4 text-ev-red group-hover:translate-x-0.5 transition-transform" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
            </svg>
          </a>
        )}

        {/* Identity card */}
        <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 space-y-4">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-xs text-gray-400 mb-1">Welcome back</p>
              <h2 className="text-xl font-bold text-ev-black dark:text-white">
                {user?.displayName ?? user?.email}
              </h2>
            </div>
            {me && (
              <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${TIER_COLOR[me.tier]}`}>
                {TIER_LABEL[me.tier]}
              </span>
            )}
          </div>

          {xp && (
            <div className="space-y-1.5">
              <div className="flex items-center justify-between text-sm">
                <span className="font-medium text-ev-black dark:text-white">Level {xp.level}</span>
                <span className="text-gray-400 text-xs tabular-nums">
                  {xp.xp_in_level.toLocaleString()} / {xp.xp_to_next_level.toLocaleString()} XP
                </span>
              </div>
              <div className="h-2 rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden">
                <div
                  className="h-full rounded-full bg-ev-teal transition-all duration-700"
                  style={{ width: `${xpPercent}%` }}
                />
              </div>
              <p className="text-xs text-gray-400 tabular-nums">{xp.total.toLocaleString()} total XP</p>
            </div>
          )}
        </div>

        {/* Gems */}
        {cp && (
          <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4">Gems</p>
            <div className="flex justify-around">
              <GemBadge count={cp.gems.yellow} color="bg-ev-yellow" label="Yellow" />
              <GemBadge count={cp.gems.blue} color="bg-ev-teal" label="Blue" />
              <GemBadge count={cp.gems.red} color="bg-ev-red" label="Red" />
            </div>
          </div>
        )}

        {/* Verification Rating */}
        {cp && (
          <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 space-y-3">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Verification Rating</p>
              {cp.verification_rating >= 90 && (
                <span className="text-xs font-semibold text-ev-red bg-ev-red/10 px-2 py-0.5 rounded-full">
                  Red Gems unlocked
                </span>
              )}
            </div>
            <div className="flex items-end gap-1.5">
              <span className="text-3xl font-bold text-ev-black dark:text-white tabular-nums">{cp.verification_rating}</span>
              <span className="text-gray-400 mb-1 text-sm">/ 150</span>
            </div>
            <div className="h-2 rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden">
              <div
                className="h-full rounded-full bg-ev-teal transition-all duration-700"
                style={{ width: `${vrPercent}%` }}
              />
            </div>
            {cp.vq_hold_active && (
              <p className="text-xs text-ev-red font-medium">VQ hold active — participation paused for 30 days.</p>
            )}
          </div>
        )}

        {/* Referral Code */}
        {cp && referral && (
          <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 space-y-3">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Invite a Friend</p>

            {!referral.unlocked ? (
              /* Locked state */
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center flex-shrink-0">
                  <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
                  </svg>
                </div>
                <div>
                  <p className="text-sm font-medium text-ev-black dark:text-white">Reach level 2 to unlock</p>
                  <p className="text-xs text-gray-400 mt-0.5">Keep earning XP to get your first referral code.</p>
                </div>
              </div>
            ) : referral.inviteeJoined && (referral.inviteeLevel ?? 0) < 2 ? (
              /* Code used — waiting for invitee to hit level 2 */
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-ev-teal-light animate-pulse" />
                  <p className="text-sm font-medium text-ev-black dark:text-white">Friend joined!</p>
                </div>
                <p className="text-xs text-gray-400 leading-relaxed">
                  When they reach level 2, you'll get a fresh referral code to share with someone new.
                </p>
                <div className="flex items-center justify-between pt-1">
                  <span className="text-xs text-gray-400">Their level</span>
                  <span className="text-sm font-semibold text-ev-black dark:text-white tabular-nums">
                    {referral.inviteeLevel ?? 1}
                  </span>
                </div>
              </div>
            ) : (
              /* Code available — show and copy */
              <div className="space-y-3">
                <p className="text-xs text-gray-400 leading-relaxed">
                  Share this code with one friend. You'll get a new one when they reach level 2.
                </p>
                <button
                  onClick={copyCode}
                  className="w-full flex items-center justify-between bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded-xl px-4 py-3 group hover:border-ev-teal-light/50 transition-colors"
                >
                  <span className="font-mono text-lg font-bold tracking-widest text-ev-black dark:text-white">
                    {referral.code}
                  </span>
                  <span className="text-xs font-medium text-ev-teal-light">
                    {copied ? 'Copied!' : 'Copy'}
                  </span>
                </button>
              </div>
            )}
          </div>
        )}

        {/* Civic Spaces */}
        {jurisdiction && (
          <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 space-y-3">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Your Civic Spaces</p>
            <div className="-mx-5 px-5 divide-y divide-gray-100 dark:divide-gray-800">
              {DISTRICT_LABELS.filter((d) => jurisdiction[d.key]).map(({ key, label }) => (
                <div key={key} className="flex items-center justify-between py-2.5 first:pt-0 last:pb-0">
                  <span className="text-xs text-gray-400">{label}</span>
                  <span className="text-sm font-medium text-ev-black dark:text-white text-right max-w-[60%]">
                    {jurisdiction[key]}
                  </span>
                </div>
              ))}
            </div>
            <Link to="/settings/location" className="inline-block text-xs text-ev-teal hover:underline">
              Update location →
            </Link>
          </div>
        )}

        {/* CTA to add location if not set */}
        {me && !me.location_consent && (
          <Link
            to="/settings/location"
            className="flex items-center justify-between bg-ev-teal/5 border border-ev-teal/20 rounded-2xl p-4 group"
          >
            <div>
              <p className="text-sm font-semibold text-ev-teal">Connect to your community</p>
              <p className="text-xs text-gray-500 mt-0.5">Add your address to find your representatives.</p>
            </div>
            <svg className="w-4 h-4 text-ev-teal group-hover:translate-x-0.5 transition-transform" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
            </svg>
          </Link>
        )}

        {/* Feature hub */}
        <div className="space-y-2 pb-8">
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider px-1">
            Explore freely. Connect to save your progress.
          </p>
          <div className="grid grid-cols-2 gap-3">
            {FEATURES.map((f) => (
              <a
                key={f.name}
                href={f.url}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 space-y-2 hover:border-ev-teal/40 transition-colors group"
              >
                <div className={`w-2 h-2 rounded-full ${f.dot}`} />
                <p className="text-sm font-semibold text-ev-black dark:text-white leading-snug">{f.name}</p>
                <p className="text-xs text-gray-400 leading-snug">{f.description}</p>
                <p className="text-xs text-ev-teal font-medium group-hover:underline">Explore →</p>
              </a>
            ))}
          </div>
        </div>

      </main>
    </div>
  );
}
