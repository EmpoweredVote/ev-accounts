import { useEffect, useState, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { apiFetch } from '../lib/api';
import { useTheme } from '../hooks/useTheme';

interface MeGems { yellow: number; blue: number; red: number; }
interface MeXp { total: number; level: number; xp_in_level: number; xp_to_next_level: number; }
interface MeConnectedProfile {
  xp: MeXp;
  gems: MeGems;
  verification_rating: number;
  vq_hold_active: boolean;
  completed_onboarding: boolean;
}
interface MeResponse {
  id: string;
  email: string;
  display_name: string | null;
  tier: 'inform' | 'connected' | 'empowered';
  is_admin: boolean;
  verification_rating: number;
  location_consent: boolean;
  gems?: MeGems;
  connected_profile?: MeConnectedProfile;
}
interface Jurisdiction {
  congressional_district: string | null;
  congressional_district_name: string | null;
  state_senate_district: string | null;
  state_senate_district_name: string | null;
  state_house_district: string | null;
  state_house_district_name: string | null;
  county: string | null;
  county_name: string | null;
  school_district: string | null;
  school_district_name: string | null;
}
interface ReferralState {
  unlocked: boolean;
  code: string | null;
}
interface ActivityEntry {
  source: string;
  amount: number;
  description: string;
  created_at: string;
}

function buildSlices(j: Jurisdiction): { label: string; name: string }[] {
  const slices: { label: string; name: string }[] = [];
  if (j.school_district_name) slices.push({ label: 'Civic Space', name: j.school_district_name });
  if (j.county_name) slices.push({ label: 'Local Slice', name: j.county_name });
  const stateName = j.state_senate_district_name ?? j.state_house_district_name;
  if (stateName) slices.push({ label: 'State Slice', name: stateName });
  if (j.congressional_district_name) slices.push({ label: 'Federal Slice', name: j.congressional_district_name });
  return slices;
}

function titleCase(str: string): string {
  return str.split('_').map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
}

const FEATURES = [
  { name: 'Civic Trivia Championships', description: 'Test your knowledge of where politicians really stand on the issues.', color: 'bg-ev-teal', href: 'https://ctc.empowered.vote' },
  { name: 'Validation Quests', description: 'Help verify politician stances and earn Red Gems for accuracy.', color: 'bg-ev-red', href: 'https://quests.empowered.vote' },
  { name: 'Essentials', description: 'Find out who represents you.', color: 'bg-ev-yellow', href: 'https://essentials.empowered.vote' },
  { name: 'Read & Rank', description: "It's like a blind taste test, where we put your opinion above either political party.", color: 'bg-ev-teal-light', href: 'https://readrank.empowered.vote' },
  { name: 'Empowered Compass', description: 'See how your values align with politicians and candidates on the issues.', color: 'bg-ev-yellow', href: 'https://compass.empowered.vote' },
  { name: 'Treasury Tracker', description: 'Follow the money — see how public funds are allocated and spent.', color: 'bg-gray-500', href: 'https://treasurytracker.netlify.app/' },
] as const;

function SunIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/>
      <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
      <line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/>
      <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
    </svg>
  );
}

function MoonIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
    </svg>
  );
}

function LockIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
      <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
    </svg>
  );
}

function PinIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
      <circle cx="12" cy="10" r="3"/>
    </svg>
  );
}

function CalendarIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
      <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
    </svg>
  );
}

function YellowGem({ count }: { count: number }) {
  return (
    <div className="flex flex-col items-center gap-3">
      <div className="w-20 h-20 rounded-2xl" style={{ background: 'linear-gradient(145deg, #FFE566 0%, #FFB800 55%, #E07000 100%)', boxShadow: '0 0 28px rgba(255,184,0,0.4)' }} />
      <span className="text-white text-2xl font-bold tabular-nums">{count.toLocaleString()}</span>
      <span className="text-gray-400 text-xs">Research</span>
    </div>
  );
}

function BlueGem({ count }: { count: number }) {
  return (
    <div className="flex flex-col items-center gap-3">
      <div className="w-20 h-20 rounded-full" style={{ background: 'radial-gradient(circle at 35% 30%, #BFDBFE 0%, #60A5FA 35%, #3B82F6 65%, #1E40AF 100%)', boxShadow: '0 0 28px rgba(59,130,246,0.45)' }} />
      <span className="text-white text-2xl font-bold tabular-nums">{count.toLocaleString()}</span>
      <span className="text-gray-400 text-xs">Voting</span>
    </div>
  );
}

function RedGem({ count }: { count: number }) {
  return (
    <div className="flex flex-col items-center gap-3">
      <div className="w-20 h-20 rounded-2xl" style={{ background: 'linear-gradient(145deg, #FF9A8B 0%, #FF5740 50%, #C41E00 100%)', boxShadow: '0 0 28px rgba(255,87,64,0.4)' }} />
      <span className="text-white text-2xl font-bold tabular-nums">{count.toLocaleString()}</span>
      <span className="text-gray-400 text-xs">Validation</span>
    </div>
  );
}

export default function ProfilePage() {
  const navigate = useNavigate();
  const { user, clearAuth } = useAuthStore();
  const { isDark, toggle } = useTheme();

  const [profile, setProfile] = useState<MeResponse | null>(null);
  const [profileError, setProfileError] = useState(false);
  const [jurisdiction, setJurisdiction] = useState<Jurisdiction | null>(null);
  const [referral, setReferral] = useState<ReferralState | null>(null);
  const [activity, setActivity] = useState<ActivityEntry[]>([]);
  const [copied, setCopied] = useState(false);

  const [address, setAddress] = useState('');
  const [locationLoading, setLocationLoading] = useState(false);
  const [locationSuccess, setLocationSuccess] = useState(false);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [showLocationForm, setShowLocationForm] = useState(false);

  useEffect(() => {
    apiFetch<MeResponse>('/account/me')
      .then((data) => {
        setProfile(data);
        if (data.location_consent) {
          apiFetch<{ jurisdiction: Jurisdiction }>('/account/me/jurisdiction')
            .then((j) => setJurisdiction(j.jurisdiction))
            .catch(() => {});
        }
        if (data.connected_profile) {
          apiFetch<ReferralState>('/referral').then(setReferral).catch(() => {});
          apiFetch<{ activity: ActivityEntry[] }>('/account/me/activity')
            .then((r) => setActivity(r.activity))
            .catch(() => setActivity([]));
        }
      })
      .catch(() => setProfileError(true));
  }, []);

  useEffect(() => {
    if (locationSuccess) {
      const timer = setTimeout(() => setLocationSuccess(false), 5000);
      return () => clearTimeout(timer);
    }
  }, [locationSuccess]);

  async function handleSignOut() {
    try { await apiFetch('/auth/logout', { method: 'POST' }); } catch { /* ignore */ }
    clearAuth();
    sessionStorage.removeItem('admin_token');
    navigate('/login');
  }

  async function handleSetLocation(e: React.FormEvent) {
    e.preventDefault();
    setLocationLoading(true);
    setLocationSuccess(false);
    setLocationError(null);
    const trimmed = address.trim();
    try {
      const result = await apiFetch<{ jurisdiction: Jurisdiction }>('/connect/set-location', {
        method: 'POST',
        body: JSON.stringify({ address: trimmed }),
      });
      setJurisdiction(result.jurisdiction);
      setProfile((prev) => prev ? { ...prev, location_consent: true } : prev);
      setLocationSuccess(true);
      setAddress('');
      setShowLocationForm(false);
    } catch (err: unknown) {
      setLocationError((err instanceof Error ? err.message : null) || 'Failed to set location');
    } finally {
      setLocationLoading(false);
    }
  }

  const copyCode = useCallback(() => {
    if (!referral?.code) return;
    navigator.clipboard.writeText(referral.code).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }).catch(() => {});
  }, [referral?.code]);

  const cp = profile?.connected_profile;
  const xp = cp?.xp ?? null;
  const xpPercent = xp && xp.xp_to_next_level > 0
    ? Math.min(100, Math.round((xp.xp_in_level / xp.xp_to_next_level) * 100))
    : 0;
  const vrPercent = cp ? Math.min(100, Math.round((cp.verification_rating / 150) * 100)) : 0;
  const displayName = profile?.display_name ?? user?.email?.split('@')[0] ?? 'Member';
  const slices = jurisdiction ? buildSlices(jurisdiction) : [];

  return (
    <div className="min-h-screen bg-gray-950 transition-colors duration-200">

      {/* Nav */}
      <nav className="bg-gray-900 border-b border-gray-800 px-6 py-3 flex items-center justify-between">
        <span className="font-semibold text-white">Empowered Vote</span>
        <div className="flex items-center gap-3">
          <button onClick={toggle} aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'} className="text-gray-400 hover:text-gray-200 transition-colors p-1 rounded-md">
            {isDark ? <SunIcon /> : <MoonIcon />}
          </button>
          <button onClick={handleSignOut} className="text-sm text-gray-400 hover:text-gray-200 transition-colors">
            Sign out
          </button>
        </div>
      </nav>

      {/* Page header */}
      <div className="px-4 sm:px-8 lg:px-12 pt-8 pb-4">
        <h1 className="text-white text-2xl font-bold">&lt; Your Profile</h1>
        <p className="text-gray-400 text-sm mt-1">View your progress, stats, and account details</p>
      </div>

      {profileError && (
        <div className="px-4 sm:px-8 lg:px-12">
          <p className="text-sm text-gray-400 italic">Could not load profile details. Try refreshing.</p>
        </div>
      )}

      {profile && (
        <main className="px-4 sm:px-8 lg:px-12 pb-12 space-y-4">

          {/* Header card — welcome + name + level + XP */}
          <div className="bg-gray-900 rounded-2xl border border-gray-800 p-6">
            <div className="flex items-start justify-between mb-4">
              <p className="text-xs text-gray-500 uppercase tracking-widest font-medium">Welcome back</p>
              <div className="flex items-center gap-2 flex-shrink-0">
                <span className="border border-gray-700 text-gray-400 text-xs px-3 py-1 rounded-full">
                  Private Account
                </span>
                {user?.isAdmin && (
                  <Link to="/admin" className="bg-ev-red text-white text-xs font-medium px-3 py-1 rounded-full hover:bg-ev-red/90 transition-colors">
                    Admin Panel
                  </Link>
                )}
              </div>
            </div>
            <h2 className="text-5xl font-bold text-white">{displayName}</h2>
            {cp && xp && (
              <>
                <div className="flex items-center gap-3 mt-4">
                  <span className="bg-ev-blue text-white text-sm font-bold px-3 py-1.5 rounded-full">
                    Level {xp.level}
                  </span>
                  <span className="text-gray-300 text-sm tabular-nums">
                    {xp.xp_in_level.toLocaleString()} / {xp.xp_to_next_level.toLocaleString()} XP
                  </span>
                </div>
                <div className="mt-4 h-2 rounded-full bg-gray-800 overflow-hidden">
                  <div
                    className="bg-ev-blue h-full rounded-full transition-all duration-700"
                    style={{ width: `${xpPercent}%`, boxShadow: '0 0 14px rgba(59,130,246,0.7)' }}
                  />
                </div>
                <p className="text-xs text-gray-500 mt-2 tabular-nums">
                  {xp.total.toLocaleString()} total XP earned
                </p>
              </>
            )}
          </div>

          {/* Two-column: Gems + Verification Rating */}
          {cp && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="bg-gray-900 rounded-2xl border border-gray-800 p-6">
                <p className="text-xs text-gray-500 uppercase tracking-widest font-medium mb-6">Your Gems</p>
                <div className="flex justify-around items-end">
                  <YellowGem count={cp.gems.yellow} />
                  <BlueGem count={cp.gems.blue} />
                  <RedGem count={cp.gems.red} />
                </div>
              </div>

              <div className="bg-gray-900 rounded-2xl border border-gray-800 p-6">
                <p className="text-xs text-gray-500 uppercase tracking-widest font-medium mb-4">Verification Rating</p>
                <div className="flex items-baseline gap-2 mb-4">
                  <span className="text-ev-teal-light text-6xl font-bold tabular-nums">{cp.verification_rating}</span>
                  <span className="text-white text-xl font-medium">/ 150</span>
                </div>
                <div className="h-1.5 rounded-full bg-gray-800 overflow-hidden mb-3">
                  <div className="bg-ev-teal-light h-full rounded-full transition-all duration-700" style={{ width: `${vrPercent}%` }} />
                </div>
                <p className="text-sm text-gray-400">Keep validating to increase your credibility score</p>
                {cp.vq_hold_active && (
                  <p className="text-xs text-ev-red mt-2">VQ hold active</p>
                )}
              </div>
            </div>
          )}

          {/* Two-column: Invite + Civic Spaces */}
          {cp && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Invite */}
              <div className="bg-gray-900 rounded-2xl border border-gray-800 p-6">
                <p className="text-xs text-gray-500 uppercase tracking-widest font-medium mb-4">Invite a Friend</p>
                {!referral?.unlocked ? (
                  <div className="flex items-start gap-4">
                    <div className="w-10 h-10 rounded-xl bg-gray-800 flex items-center justify-center flex-shrink-0 text-gray-400">
                      <LockIcon />
                    </div>
                    <div>
                      <p className="text-white font-semibold">Reach level 2 to unlock</p>
                      <p className="text-gray-400 text-sm mt-1">Keep earning XP to get your first referral code</p>
                    </div>
                  </div>
                ) : referral?.code ? (
                  <div className="bg-gray-800 rounded-xl px-4 py-3 flex items-center justify-between">
                    <code className="font-mono text-ev-teal-light text-xl tracking-widest">{referral.code}</code>
                    <button onClick={copyCode} className="text-sm text-ev-teal-light hover:text-white transition-colors ml-4">
                      {copied ? 'Copied!' : 'Copy'}
                    </button>
                  </div>
                ) : null}
              </div>

              {/* Civic Spaces */}
              <div className="bg-gray-900 rounded-2xl border border-gray-800 p-6">
                <p className="text-xs text-gray-500 uppercase tracking-widest font-medium mb-4">Your Civic Spaces</p>
                {slices.length > 0 ? (
                  <div className="space-y-2 mb-4">
                    {slices.map((slice) => (
                      <div key={slice.label} className="flex items-center gap-2">
                        <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-gray-800 text-gray-400">{slice.label}</span>
                        <span className="text-sm text-gray-200">{slice.name}</span>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="flex items-center gap-4 mb-4">
                    <div className="w-10 h-10 rounded-xl bg-gray-800 flex items-center justify-center flex-shrink-0 text-ev-teal-light">
                      <PinIcon />
                    </div>
                    <div>
                      <p className="text-white font-semibold">{profile.location_consent ? 'Location Set' : 'No location set'}</p>
                    </div>
                  </div>
                )}

                {/* Location update */}
                {!showLocationForm ? (
                  <button onClick={() => setShowLocationForm(true)} className="text-ev-teal-light text-sm hover:text-white transition-colors">
                    {profile.location_consent ? 'Update location →' : 'Set your location →'}
                  </button>
                ) : (
                  <form onSubmit={handleSetLocation} className="space-y-2 mt-2">
                    <input
                      type="text"
                      value={address}
                      onChange={(e) => setAddress(e.target.value)}
                      placeholder="Enter your address"
                      className="w-full px-3 py-2 border border-gray-700 rounded-lg text-sm bg-gray-800 text-white placeholder-gray-500 focus:outline-none focus:border-ev-teal-light"
                    />
                    <div className="flex gap-2">
                      <button
                        type="submit"
                        disabled={address.trim().length === 0 || locationLoading}
                        className="bg-ev-teal-light text-white text-sm font-medium px-4 py-2 rounded-lg hover:bg-ev-teal-light/90 disabled:opacity-50 transition-colors"
                      >
                        {locationLoading ? 'Setting...' : 'Set Location'}
                      </button>
                      <button type="button" onClick={() => setShowLocationForm(false)} className="text-sm text-gray-400 hover:text-white px-3 py-2 transition-colors">
                        Cancel
                      </button>
                    </div>
                    {locationSuccess && <p className="text-sm text-green-400">Location updated successfully</p>}
                    {locationError && <p className="text-sm text-ev-red">{locationError}</p>}
                  </form>
                )}
              </div>
            </div>
          )}

          {/* Recent Activity — full width */}
          {cp && (
            <div className="bg-gray-900 rounded-2xl border border-gray-800 p-6">
              <div className="flex items-center gap-3 mb-5 text-white">
                <CalendarIcon />
                <h2 className="text-xl font-semibold">Recent Activity</h2>
              </div>
              {activity.length === 0 ? (
                <p className="text-gray-400 text-sm">No XP earned yet — explore an Empowered Vote feature to get started.</p>
              ) : (
                <div className="space-y-2">
                  {activity.slice(0, 4).map((entry, i) => (
                    <div key={i} className="flex items-center justify-between bg-gray-800/60 rounded-xl px-4 py-3">
                      <div>
                        <p className="text-white text-sm font-medium">{titleCase(entry.description)}</p>
                        <p className="text-gray-400 text-xs mt-0.5">
                          {new Date(entry.created_at).toLocaleDateString(undefined, { month: 'long', day: 'numeric', year: 'numeric' })}
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

          {/* Feature hub */}
          <div className="pt-4">
            <h2 className="text-lg font-semibold text-white mb-1">Empowered Vote Features</h2>
            <p className="text-sm text-gray-400 mb-4">Explore freely. Connect to save your progress.</p>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {FEATURES.map((feature) => (
                <a
                  key={feature.name}
                  href={feature.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="bg-gray-900 rounded-xl border border-gray-800 p-4 hover:border-gray-600 transition-colors block"
                >
                  <div className="flex items-center gap-2 mb-1.5">
                    <span className={`w-2.5 h-2.5 rounded-full flex-shrink-0 ${feature.color}`} />
                    <span className="text-sm font-semibold text-white">{feature.name}</span>
                  </div>
                  <p className="text-xs text-gray-400 leading-relaxed">{feature.description}</p>
                  <p className="text-xs text-ev-teal font-medium mt-2">Explore &rarr;</p>
                </a>
              ))}
            </div>
          </div>

        </main>
      )}
    </div>
  );
}
