import { useEffect, useState, useCallback } from 'react';
import { Link } from 'react-router';
import { useAuthStore } from '../store/authStore';
import { apiFetch } from '../lib/api';
import { workosSignOut } from '../lib/workosAuth';
import PostHistory from '../components/PostHistory';

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
  city_council_district_name: string | null;
  state: string | null;
  city: string | null;
}

interface ReferralState {
  unlocked: boolean;
  code: string | null;
  inviteeJoined: boolean;
  inviteeLevel: number | null;
}

interface InviteeEntry {
  status: 'claimed' | 'pending';
  code: string;
  label: string | null;
  invitee_id: string | null;
  display_name: string | null;
  account_standing: 'active' | 'suspended' | null;
  current_level: number | null;
  graduated: boolean | null;
  slot_locked_until: string | null;
  claimed_at: string | null;
  xp_in_level: number | null;
  xp_to_next_level: number | null;
}

interface InviteesData {
  active_count: number;
  cap: number;
  can_generate: boolean;
  invitees: InviteeEntry[];
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
    name: 'Essentials',
    description: 'Explore your representatives\' positions.',
    baseUrl: 'https://essentials.empowered.vote',
    dot: 'bg-ev-yellow',
  },
  {
    name: 'Empowered Compass',
    description: 'Map your political values.',
    baseUrl: 'https://compass.empowered.vote',
    dot: 'bg-ev-yellow',
  },
  {
    name: 'Civic Trivia Championships',
    description: 'Test your civic knowledge and earn XP.',
    baseUrl: 'https://ctc.empowered.vote',
    dot: 'bg-ev-yellow',
  },
  {
    name: 'Validation Quests',
    description: 'Validate political stances and earn Red Gems.',
    baseUrl: 'https://quests.empowered.vote',
    dot: 'bg-ev-teal-light',
  },
  {
    name: 'Read & Rank',
    description: 'Read civic content and rank what matters.',
    baseUrl: 'https://readrank.empowered.vote',
    dot: 'bg-ev-yellow',
  },
  {
    name: 'Civic Spaces',
    description: 'Engage with your local civic community.',
    baseUrl: 'https://civicspaces.empowered.vote',
    dot: 'bg-ev-teal-light',
  },
  {
    name: 'Treasury Tracker',
    description: 'Track government spending and financial accountability.',
    baseUrl: 'https://treasurytracker.empowered.vote',
    dot: 'bg-ev-yellow',
  },
];

const DISTRICT_LABELS: { key: keyof Jurisdiction; label: string }[] = [
  { key: 'city_council_district_name', label: 'City Council' },
  { key: 'congressional_district_name', label: 'U.S. Congress' },
  { key: 'state_senate_district_name', label: 'State Senate' },
  { key: 'state_house_district_name', label: 'State House' },
  { key: 'county_name', label: 'County' },
  { key: 'school_district_name', label: 'School District' },
];

const GEM_IMAGES: Record<string, string> = {
  Yellow: '/Yellow_Gem.png',
  Blue: '/Blue_Gem.png',
  Red: '/Red_Gem.png',
};

const GEM_TOOLTIPS: Record<string, string> = {
  Yellow: 'Yellow Gems are earned for learning civic facts.',
  Blue: 'Blue Gems are used to vote your values.',
  Red: 'Red Gems make an impact on our priorities.',
};

function GemBadge({ count, label }: { count: number; label: string }) {
  const src = GEM_IMAGES[label];
  const tooltip = GEM_TOOLTIPS[label];
  return (
    <div className="relative group flex flex-col items-center gap-2">
      <div className="w-14 h-14 flex items-center justify-center drop-shadow-lg cursor-default">
        {src ? (
          <img src={src} alt={`${label} Gem`} className="w-full h-full object-contain" />
        ) : (
          <div className="w-14 h-14 rounded-full bg-gray-700" />
        )}
      </div>
      <span className="text-sm font-semibold text-ev-black dark:text-white tabular-nums">{count.toLocaleString()}</span>
      {tooltip && (
        <div className="absolute bottom-full mb-2 left-1/2 -translate-x-1/2 w-44 px-3 py-2 bg-gray-900 dark:bg-gray-700 text-white text-xs rounded-lg text-center leading-snug opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10">
          {tooltip}
          <div className="absolute top-full left-1/2 -translate-x-1/2 border-4 border-transparent border-t-gray-900 dark:border-t-gray-700" />
        </div>
      )}
    </div>
  );
}

export default function DashboardPage() {
  const { user, clearAuth, accessToken } = useAuthStore();
  const [me, setMe] = useState<MeFull | null>(null);
  const [jurisdiction, setJurisdiction] = useState<Jurisdiction | null>(null);
  const [referral, setReferral] = useState<ReferralState | null>(null);
  const [copied, setCopied] = useState(false);
  const [inviteesData, setInviteesData] = useState<InviteesData | null>(null);
  const [generatingCode, setGeneratingCode] = useState(false);
  const [newCode, setNewCode] = useState<string | null>(null);
  const [newCodeCopied, setNewCodeCopied] = useState(false);
  const [labelInput, setLabelInput] = useState('');
  const [copiedCode, setCopiedCode] = useState<string | null>(null);
  const [showSignedOutToast, setShowSignedOutToast] = useState(false);
  const [activeTab, setActiveTab] = useState<'profile' | 'referrals' | 'posts'>('profile');

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
      apiFetch<InviteesData>('/invites/my-invitees').then(setInviteesData).catch(() => {});
    }
  }, [me?.connected_profile]);

  const copyCode = useCallback(() => {
    if (!referral?.code) return;
    navigator.clipboard.writeText(referral.code).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }).catch(() => {});
  }, [referral?.code]);

  const handleGenerate = useCallback(async () => {
    setGeneratingCode(true);
    setNewCode(null);
    try {
      const result = await apiFetch<{ code: string; active_count: number; cap: number }>(
        '/invites/generate',
        { method: 'POST', body: JSON.stringify({ label: labelInput.trim() || null }) },
      );
      setNewCode(result.code);
      setLabelInput('');
      const updated = await apiFetch<InviteesData>('/invites/my-invitees');
      setInviteesData(updated);
    } catch {
      // Error handled — CAP_REACHED or rate limit
    } finally {
      setGeneratingCode(false);
    }
  }, [labelInput]);

  const copyNewCode = useCallback(() => {
    if (!newCode) return;
    navigator.clipboard.writeText(newCode).then(() => {
      setNewCodeCopied(true);
      setTimeout(() => setNewCodeCopied(false), 2000);
    }).catch(() => {});
  }, [newCode]);

  const copyPendingCode = useCallback((code: string) => {
    navigator.clipboard.writeText(code).then(() => {
      setCopiedCode(code);
      setTimeout(() => setCopiedCode(null), 2000);
    }).catch(() => {});
  }, []);

  const handleLogout = async () => {
    const url = `${import.meta.env.VITE_API_URL || ''}/api/auth/logout`;
    try {
      await fetch(url, {
        method: 'POST',
        credentials: 'include',
        headers: accessToken ? { Authorization: `Bearer ${accessToken}` } : {},
      });
    } catch {
      // Ignore — always clear local state
    }
    // Ends the WorkOS session too when this login came through AuthKit
    // (decision 0002 transition); no-op for classic sessions.
    try {
      await workosSignOut();
    } catch {
      // Ignore — always clear local state
    }
    setShowSignedOutToast(true);
    setTimeout(() => {
      clearAuth();
    }, 500);
  };

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
          <span className="font-bold text-ev-teal-light text-lg">profile.empowered.vote</span>
          <div className="flex items-center gap-3">
            {me?.is_admin && (
              <div className="relative group">
                <a
                  href="https://login.empowered.vote/admin"
                  className="flex items-center justify-center w-8 h-8 rounded-full hover:bg-ev-red/10 transition-colors"
                >
                  <img src="/Red_Admin.png" alt="Admin Hub" className="w-5 h-5 object-contain" />
                </a>
                <div className="absolute right-0 top-full mt-2 px-2.5 py-1 bg-gray-900 dark:bg-gray-700 text-white text-xs rounded-lg whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
                  Admin Hub
                </div>
              </div>
            )}
            <button
              onClick={handleLogout}
              className="text-sm text-gray-400 hover:text-ev-red transition-colors"
            >
              Sign out
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-lg mx-auto px-4 py-6 space-y-4">

        {/* Tab bar */}
        <nav className="flex gap-6 border-b border-gray-200 dark:border-gray-800 mb-6">
          <button
            onClick={() => setActiveTab('profile')}
            className={`pb-2 border-b-2 font-medium text-sm transition-colors ${activeTab === 'profile' ? 'border-ev-teal text-ev-teal' : 'border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'}`}
          >
            Profile
          </button>
          {cp && (
            <button
              onClick={() => setActiveTab('referrals')}
              className={`pb-2 border-b-2 font-medium text-sm transition-colors ${activeTab === 'referrals' ? 'border-ev-teal text-ev-teal' : 'border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'}`}
            >
              Referrals
            </button>
          )}
          {cp && (
            <button
              onClick={() => setActiveTab('posts')}
              className={`pb-2 border-b-2 font-medium text-sm transition-colors ${activeTab === 'posts' ? 'border-ev-teal text-ev-teal' : 'border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'}`}
            >
              Posts
            </button>
          )}
          <Link to="/contributor" className="pb-2 border-b-2 border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 font-medium text-sm">Contributor</Link>
        </nav>

        {/* Profile tab content */}
        {activeTab === 'profile' && <>

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
                <span className="font-medium text-ev-black dark:text-white">Level {Math.max(1, xp.level)}</span>
                <span className="text-gray-400 text-xs tabular-nums">
                  {xp.xp_in_level.toLocaleString()} / {(xp.xp_in_level + xp.xp_to_next_level).toLocaleString()} XP
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
              <GemBadge count={cp.gems.yellow} label="Yellow" />
              <GemBadge count={cp.gems.blue} label="Blue" />
              <GemBadge count={cp.gems.red} label="Red" />
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

        </> /* end profile tab */}

        {/* Referrals tab content */}
        {activeTab === 'referrals' && cp && inviteesData && (
          <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 space-y-4">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Invite Friends</p>

            {/* Quota summary */}
            <div className="flex items-center justify-between">
              <div>
                <span className="text-2xl font-bold text-ev-black dark:text-white tabular-nums">
                  {inviteesData.active_count}
                </span>
                <span className="text-gray-400 text-sm ml-1">
                  / {inviteesData.cap >= 2147483647 ? 'Unlimited' : inviteesData.cap} active invitees
                </span>
              </div>
            </div>

            {inviteesData.cap === 0 ? (
              /* Level-1 locked state */
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center flex-shrink-0">
                  <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
                  </svg>
                </div>
                <div>
                  <p className="text-sm font-medium text-ev-black dark:text-white">Reach level 2 to start inviting</p>
                  <p className="text-xs text-gray-400 mt-0.5">Keep earning XP to unlock your first invite slot.</p>
                </div>
              </div>
            ) : inviteesData.can_generate ? (
              /* Under cap — label input + generate button */
              <div className="space-y-2">
                <input
                  type="text"
                  value={labelInput}
                  onChange={e => setLabelInput(e.target.value)}
                  onKeyDown={e => { if (e.key === 'Enter' && !generatingCode) handleGenerate(); }}
                  placeholder="Who is this for? (optional)"
                  maxLength={50}
                  className="w-full px-3 py-2 text-sm border border-gray-200 dark:border-gray-700 rounded-xl bg-white dark:bg-gray-900 text-ev-black dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-ev-teal/30 focus:border-ev-teal transition-colors"
                />
                <button
                  onClick={handleGenerate}
                  disabled={generatingCode}
                  className="w-full py-2.5 px-4 bg-ev-teal text-white rounded-xl text-sm font-semibold hover:bg-ev-teal/90 transition-colors disabled:opacity-50"
                >
                  {generatingCode ? 'Generating\u2026' : 'Generate Invite Code'}
                </button>
              </div>
            ) : (
              /* At capacity */
              <p className="text-xs text-gray-500 leading-relaxed">
                All invite slots filled. Level up to earn more, or wait for an invitee to reach level 2.
              </p>
            )}

            {/* Newly generated code — shown regardless of capacity state */}
            {newCode && (
              <button
                onClick={copyNewCode}
                className="w-full flex items-center justify-between bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded-xl px-4 py-3 hover:border-ev-teal-light/50 transition-colors"
              >
                <span className="font-mono text-lg font-bold tracking-widest text-ev-black dark:text-white">
                  {newCode}
                </span>
                <span className="text-xs font-medium text-ev-teal-light">
                  {newCodeCopied ? 'Copied!' : 'Copy'}
                </span>
              </button>
            )}

            {/* Pending codes */}
            {inviteesData.invitees.some(i => i.status === 'pending') && (
              <div className="-mx-5 px-5 pt-1 border-t border-gray-100 dark:border-gray-800">
                <p className="text-xs font-medium text-gray-400 mt-3 mb-2">Pending Codes</p>
                <div className="space-y-2 py-1">
                  {inviteesData.invitees.filter(i => i.status === 'pending').map((entry) => (
                    <div key={entry.code}>
                      {entry.label && (
                        <p className="text-xs text-gray-400 mb-1 px-1">{entry.label}</p>
                      )}
                      <button
                        onClick={() => copyPendingCode(entry.code)}
                        className="w-full flex items-center justify-between bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded-xl px-4 py-3 hover:border-ev-teal-light/50 transition-colors"
                      >
                        <span className="font-mono text-base font-bold tracking-widest text-ev-black dark:text-white">
                          {entry.code}
                        </span>
                        <span className="text-xs font-medium text-ev-teal-light">
                          {copiedCode === entry.code ? 'Copied!' : 'Copy'}
                        </span>
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Claimed invitees */}
            {inviteesData.invitees.some(i => i.status === 'claimed') && (
              <div className="-mx-5 px-5 pt-1 border-t border-gray-100 dark:border-gray-800">
                <p className="text-xs font-medium text-gray-400 mt-3 mb-2">Your Invitees</p>
                <div className="divide-y divide-gray-100 dark:divide-gray-800">
                  {inviteesData.invitees.filter(i => i.status === 'claimed').map((invitee) => {
                    const isLocked = invitee.slot_locked_until && new Date(invitee.slot_locked_until) > new Date();
                    const xpTotal = (invitee.xp_in_level ?? 0) + (invitee.xp_to_next_level ?? 0);
                    const xpPct = xpTotal > 0 ? Math.round(((invitee.xp_in_level ?? 0) / xpTotal) * 100) : 0;
                    return (
                      <div key={invitee.invitee_id} className="py-2.5">
                        <div className="flex items-center justify-between gap-2">
                          <div className="min-w-0 flex-1">
                            <p className={`text-sm font-medium truncate ${invitee.graduated ? 'text-gray-400' : 'text-ev-black dark:text-white'}`}>
                              {invitee.display_name ?? invitee.label ?? '\u2014'}
                            </p>
                          </div>
                          <div className="flex items-center gap-2 flex-shrink-0">
                            {invitee.graduated ? (
                              <span className="text-xs font-medium text-ev-teal bg-ev-teal/10 px-2 py-0.5 rounded-full">
                                Graduated ✓
                              </span>
                            ) : invitee.account_standing === 'suspended' ? (
                              <span className="text-xs font-medium text-ev-red bg-ev-red/10 px-2 py-0.5 rounded-full">
                                Suspended
                              </span>
                            ) : (
                              <span className="flex items-center gap-1 text-xs text-gray-500">
                                <span className="w-1.5 h-1.5 rounded-full bg-green-400" />
                                Active
                              </span>
                            )}
                            {isLocked && (
                              <span className="text-xs font-medium text-ev-red bg-ev-red/10 px-2 py-0.5 rounded-full">
                                Slot locked
                              </span>
                            )}
                          </div>
                        </div>
                        {!invitee.graduated && invitee.xp_in_level !== null && invitee.xp_to_next_level !== null && (
                          <div className="mt-1.5 space-y-1">
                            <div className="flex items-center justify-between text-xs text-gray-400">
                              <span>Lv {invitee.current_level}</span>
                              <span className="tabular-nums">{invitee.xp_in_level.toLocaleString()} / {xpTotal.toLocaleString()} XP</span>
                            </div>
                            <div className="h-1.5 rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden">
                              <div
                                className="h-full rounded-full bg-ev-teal-light transition-all duration-700"
                                style={{ width: `${xpPct}%` }}
                              />
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Posts tab content */}
        {activeTab === 'posts' && cp && (
          <PostHistory />
        )}

        {/* Connected Spaces — profile tab only */}
        {activeTab === 'profile' && jurisdiction && (
          <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 space-y-3">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Your Connected Spaces</p>
              <a
                href="https://civicspaces.empowered.vote"
                target="_blank"
                rel="noopener noreferrer"
                className="text-xs font-medium text-ev-teal hover:underline"
              >
                Civic Spaces →
              </a>
            </div>
            {(jurisdiction.city || jurisdiction.state) && (
              <p className="text-sm font-semibold text-ev-black dark:text-white">
                {[jurisdiction.city, jurisdiction.state].filter(Boolean).join(', ')}
              </p>
            )}
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

        {/* CTA to add location if not set — profile tab only */}
        {activeTab === 'profile' && me && !me.location_consent && (
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

        {/* Feature hub — profile tab only */}
        {activeTab === 'profile' && <div className="space-y-2 pb-8">
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider px-1">
            Explore freely. Connect to save your progress.
          </p>
          <div className="grid grid-cols-2 gap-3">
            {FEATURES.map((f) => {
              const featureUrl = accessToken
                ? `${f.baseUrl}#access_token=${accessToken}`
                : f.baseUrl;
              return (
              <a
                key={f.name}
                href={featureUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 space-y-2 hover:border-ev-teal/40 transition-colors group"
              >
                <div className={`w-2 h-2 rounded-full ${f.dot}`} />
                <p className="text-sm font-semibold text-ev-black dark:text-white leading-snug">{f.name}</p>
                <p className="text-xs text-gray-400 leading-snug">{f.description}</p>
                <p className="text-xs text-ev-teal font-medium group-hover:underline">Explore →</p>
              </a>
              );
            })}
          </div>
        </div>}

      </main>

      {showSignedOutToast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 bg-gray-900 text-white text-sm font-medium px-5 py-3 rounded-xl shadow-lg">
          You've been signed out
        </div>
      )}
    </div>
  );
}
