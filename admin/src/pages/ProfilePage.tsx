import { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { apiFetch } from '../lib/api';
import { useTheme } from '../hooks/useTheme';

// ── Types ─────────────────────────────────────────────────────────────────────

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
  location_consent: boolean;
  connected_profile?: MeConnectedProfile;
}
interface Jurisdiction {
  city: string | null;
  state: string | null;
  city_council_district_name: string | null;
  congressional_district_name: string | null;
  state_senate_district_name: string | null;
  state_house_district_name: string | null;
  county_name: string | null;
  school_district_name: string | null;
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
interface ActivityEntry {
  source: string;
  amount: number;
  description: string;
  created_at: string;
}
interface FCPost {
  postId: string;
  threadId: string;
  threadTitle: string;
  communityId: string;
  communityName: string;
  communitySlug: string;
  postExcerpt: string;
  createdAt: string;
  isEdited: boolean;
  authorPseudonym: string;
}
interface FCPostsResponse {
  data: FCPost[];
  meta: { cursor: string | null; hasMore: boolean };
}

// ── Constants ─────────────────────────────────────────────────────────────────

const DISTRICT_LABELS: { key: keyof Jurisdiction; label: string }[] = [
  { key: 'city_council_district_name', label: 'City Council' },
  { key: 'congressional_district_name', label: 'U.S. Congress' },
  { key: 'state_senate_district_name', label: 'State Senate' },
  { key: 'state_house_district_name', label: 'State House' },
  { key: 'county_name', label: 'County' },
  { key: 'school_district_name', label: 'School District' },
];

// All features in a single grid — dot color distinguishes Inform (yellow) vs Connect (blue)
const ALL_FEATURES = [
  { name: 'Essentials', description: 'Find out who represents you and where they stand.', href: 'https://essentials.empowered.vote', dot: 'bg-ev-yellow', border: 'hover:border-ev-yellow/40' },
  { name: 'Empowered Compass', description: 'See how your values align with politicians.', href: 'https://compass.empowered.vote', dot: 'bg-ev-yellow', border: 'hover:border-ev-yellow/40' },
  { name: 'Treasury Tracker', description: 'Follow the money — public funds allocation.', href: 'https://treasurytracker.empowered.vote', dot: 'bg-ev-yellow', border: 'hover:border-ev-yellow/40' },
  { name: 'Civic Trivia Championships', description: 'Test your knowledge on where politicians stand.', href: 'https://ctc.empowered.vote', dot: 'bg-ev-yellow', border: 'hover:border-ev-yellow/40' },
  { name: 'Read & Rank', description: 'Put your opinion above party lines.', href: 'https://readrank.empowered.vote', dot: 'bg-ev-yellow', border: 'hover:border-ev-yellow/40' },
  { name: 'Validation Quests', description: 'Verify politician stances and earn Red Gems.', href: 'https://quests.empowered.vote', dot: 'bg-ev-blue', border: 'hover:border-ev-blue/40' },
  { name: 'Civic Spaces', description: 'Engage with your local civic community.', href: 'https://civicspaces.empowered.vote', dot: 'bg-ev-blue', border: 'hover:border-ev-blue/40' },
  { name: 'Focused Communities', description: 'Join issue-focused civic discussions.', href: 'https://fc.empowered.vote', dot: 'bg-ev-blue', border: 'hover:border-ev-blue/40' },
  { name: 'Empowered Listening', description: 'Hear diverse perspectives and find common ground.', href: 'https://listening.empowered.vote', dot: 'bg-ev-blue', border: 'hover:border-ev-blue/40' },
] as const;

// ── Helpers ───────────────────────────────────────────────────────────────────

function titleCase(str: string): string {
  return str.split('_').map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
}

// ── Icons ─────────────────────────────────────────────────────────────────────

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

// ── Inline PostHistory (adapted for admin authStore) ──────────────────────────

function PostHistory() {
  const { user, accessToken } = useAuthStore();
  const [posts, setPosts] = useState<FCPost[]>([]);
  const [cursor, setCursor] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [loadState, setLoadState] = useState<'idle' | 'loading' | 'loaded' | 'error-access' | 'error-generic'>('idle');
  const [loadingMore, setLoadingMore] = useState(false);

  const loadPage = useCallback(async (afterCursor: string | null) => {
    if (!user || !accessToken) return;
    let url = `https://fc.empowered.vote/api/users/${user.id}/posts`;
    if (afterCursor) url += `?cursor=${encodeURIComponent(afterCursor)}`;
    try {
      const res = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });
      if (res.status === 401) { useAuthStore.getState().clearAuth(); return; }
      if (res.status === 403) { setLoadState('error-access'); return; }
      if (!res.ok) { setLoadState('error-generic'); return; }
      const json = await res.json() as FCPostsResponse;
      if (afterCursor === null) setPosts(json.data);
      else setPosts((prev) => [...prev, ...json.data]);
      setCursor(json.meta.cursor);
      setHasMore(json.meta.hasMore);
      setLoadState('loaded');
    } catch {
      setLoadState('error-generic');
    }
  }, [user, accessToken]);

  useEffect(() => {
    setLoadState('loading');
    loadPage(null);
  }, [user?.id]); // eslint-disable-line react-hooks/exhaustive-deps

  const handleLoadMore = useCallback(async () => {
    setLoadingMore(true);
    await loadPage(cursor);
    setLoadingMore(false);
  }, [cursor, loadPage]);

  if (loadState === 'loading' && posts.length === 0) {
    return (
      <div className="bg-gray-900 rounded-2xl border border-gray-800 p-5 flex items-center justify-center">
        <p className="text-sm text-gray-400">Loading your posts&hellip;</p>
      </div>
    );
  }
  if (loadState === 'error-access') {
    return (
      <div className="bg-gray-900 rounded-2xl border border-gray-800 p-5">
        <p className="text-sm font-medium text-ev-red">Access denied</p>
        <p className="text-xs text-gray-500 mt-1">You don&apos;t have permission to view post history.</p>
      </div>
    );
  }
  if (loadState === 'error-generic') {
    return (
      <div className="bg-gray-900 rounded-2xl border border-gray-800 p-5">
        <p className="text-sm font-medium text-white">Failed to load post history</p>
        <button
          onClick={() => { setLoadState('loading'); loadPage(null); }}
          className="mt-3 px-4 py-2 bg-ev-teal text-white rounded-xl text-sm font-semibold hover:bg-ev-teal/90 transition-colors"
        >
          Retry
        </button>
      </div>
    );
  }
  if (loadState === 'loaded' && posts.length === 0) {
    return (
      <div className="bg-gray-900 rounded-2xl border border-gray-800 p-5">
        <p className="text-sm text-gray-400">No posts yet</p>
        <p className="text-xs text-gray-500 mt-1">When you post in a community, it&apos;ll show up here.</p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {posts.length > 0 && (
        <div className="bg-gray-900 rounded-2xl border border-gray-800 divide-y divide-gray-800">
          {posts.map((post) => (
            <div key={post.postId} className="p-4 space-y-1">
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">{post.communityName}</p>
              <a
                href={`https://fc.empowered.vote/communities/${post.communitySlug}/threads/${post.threadId}`}
                target="_blank"
                rel="noopener noreferrer"
                className="block text-sm font-semibold text-ev-teal-light hover:underline"
              >
                {post.threadTitle}
              </a>
              <p className="text-sm text-white leading-snug">{post.postExcerpt}</p>
              <div className="flex items-center gap-2 text-xs text-gray-500 pt-0.5">
                <span className="font-medium">{post.authorPseudonym}</span>
                <span className="text-gray-700">&bull;</span>
                <time dateTime={post.createdAt} className="tabular-nums">
                  {new Date(post.createdAt).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })}
                </time>
                {post.isEdited && <span className="ml-1 text-[11px] font-medium text-gray-400 italic">(edited)</span>}
              </div>
            </div>
          ))}
        </div>
      )}
      {hasMore && posts.length > 0 && (
        <button
          onClick={handleLoadMore}
          disabled={loadingMore}
          className="w-full py-2 px-4 bg-gray-900 border border-gray-800 text-ev-teal-light rounded-xl text-sm font-semibold hover:border-gray-600 transition-colors disabled:opacity-50"
        >
          {loadingMore ? 'Loading…' : 'Load more'}
        </button>
      )}
    </div>
  );
}

// ── Small gem for header row ──────────────────────────────────────────────────

function GemPip({ count, style }: { count: number; style: React.CSSProperties; shape: 'square' | 'circle' }) {
  return (
    <div className="flex items-center gap-1.5">
      <div className="w-5 h-5 flex-shrink-0" style={style} />
      <span className="text-white text-sm font-semibold tabular-nums">{count.toLocaleString()}</span>
    </div>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function ProfilePage() {
  const navigate = useNavigate();
  const { user, accessToken, clearAuth } = useAuthStore();
  const { isDark, toggle } = useTheme();

  const [profile, setProfile] = useState<MeResponse | null>(null);
  const [profileError, setProfileError] = useState(false);
  const [jurisdiction, setJurisdiction] = useState<Jurisdiction | null>(null);
  const [inviteesData, setInviteesData] = useState<InviteesData | null>(null);
  const [generatingCode, setGeneratingCode] = useState(false);
  const [newCode, setNewCode] = useState<string | null>(null);
  const [newCodeCopied, setNewCodeCopied] = useState(false);
  const [labelInput, setLabelInput] = useState('');
  const [copiedCode, setCopiedCode] = useState<string | null>(null);
  const [activity, setActivity] = useState<ActivityEntry[]>([]);
  const [activeTab, setActiveTab] = useState<'profile' | 'referrals' | 'posts'>('profile');

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
          apiFetch<InviteesData>('/invites/my-invitees').then(setInviteesData).catch(() => {});
          apiFetch<{ activity: ActivityEntry[] }>('/account/me/activity')
            .then((r) => setActivity(r.activity))
            .catch(() => setActivity([]));
        }
      })
      .catch(() => setProfileError(true));
  }, []);

  useEffect(() => {
    if (locationSuccess) {
      const t = setTimeout(() => setLocationSuccess(false), 5000);
      return () => clearTimeout(t);
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
    try {
      const result = await apiFetch<{ jurisdiction: Jurisdiction }>('/connect/set-location', {
        method: 'POST',
        body: JSON.stringify({ address: address.trim() }),
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
    } catch { /* CAP_REACHED or rate limit */ }
    finally { setGeneratingCode(false); }
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

  const cp = profile?.connected_profile;
  const xp = cp?.xp ?? null;
  const xpPercent = xp && xp.xp_to_next_level > 0
    ? Math.min(100, Math.round((xp.xp_in_level / xp.xp_to_next_level) * 100))
    : 0;
  const vrPercent = cp ? Math.min(100, Math.round((cp.verification_rating / 150) * 100)) : 0;
  const displayName = profile?.display_name ?? user?.email?.split('@')[0] ?? 'Member';
  const hasDistricts = jurisdiction && DISTRICT_LABELS.some(({ key }) => jurisdiction[key]);

  return (
    <div className="min-h-screen bg-gray-950 transition-colors duration-200">

      {/* Nav */}
      <nav className="bg-gray-900 border-b border-gray-800 px-4 sm:px-8 lg:px-16 py-3 flex items-center justify-between sticky top-0 z-10">
        <span className="font-semibold text-white">Empowered Vote</span>
        <div className="flex items-center gap-3">
          <button
            onClick={toggle}
            aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
            className="text-gray-400 hover:text-gray-200 transition-colors p-1 rounded-md"
          >
            {isDark ? <SunIcon /> : <MoonIcon />}
          </button>
          {user?.isAdmin && (
            <div className="relative group">
              <a
                href="/admin"
                className="flex items-center justify-center w-8 h-8 rounded-full hover:bg-ev-red/10 transition-colors"
              >
                <img src="/Red_Admin.png" alt="Admin Hub" className="w-5 h-5 object-contain" />
              </a>
              <div className="absolute right-0 top-full mt-2 px-2.5 py-1 bg-gray-800 text-white text-xs rounded-lg whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
                Admin Hub
              </div>
            </div>
          )}
          <button onClick={handleSignOut} className="text-sm text-gray-400 hover:text-gray-200 transition-colors">
            Sign out
          </button>
        </div>
      </nav>

      {profileError && (
        <div className="px-4 sm:px-8 lg:px-16 pt-6">
          <p className="text-sm text-gray-400 italic">Could not load profile details. Try refreshing.</p>
        </div>
      )}

      {profile && (
        <div className="px-4 sm:px-8 lg:px-16 py-5">

          {/* Tab bar */}
          <nav className="flex gap-1 border-b border-gray-800 mb-5">
            {(['profile', 'referrals', 'posts'] as const).map((tab) => {
              if ((tab === 'referrals' || tab === 'posts') && !cp) return null;
              return (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors ${
                    activeTab === tab
                      ? 'border-ev-teal-light text-ev-teal-light'
                      : 'border-transparent text-gray-500 hover:text-gray-300'
                  }`}
                >
                  {tab === 'referrals' ? 'Referrals' : tab === 'posts' ? 'Posts' : 'Profile'}
                </button>
              );
            })}
            <a
              href={`https://app.empowered.vote/contributor${accessToken ? `#access_token=${accessToken}` : ''}`}
              target="_blank"
              rel="noopener noreferrer"
              className="px-4 py-2.5 text-sm font-medium border-b-2 border-transparent text-gray-500 hover:text-gray-300 -mb-px transition-colors"
            >
              Contributor ↗
            </a>
          </nav>

          {/* ── PROFILE TAB ─────────────────────────────────────────────────── */}
          {activeTab === 'profile' && (
            <div className="space-y-3">

              {/* Header card — name + XP + inline gems */}
              <div className="bg-gray-900 rounded-2xl border border-gray-800 p-4">
                <div className="flex items-start justify-between mb-2">
                  <h1 className="text-2xl font-bold text-white">{displayName}</h1>
                  <span className="border border-gray-700 text-gray-400 text-xs px-3 py-1 rounded-full flex-shrink-0 ml-4">
                    Connected Account
                  </span>
                </div>

                {cp && xp ? (
                  <>
                    {/* Level + XP text | Gems (right) */}
                    <div className="flex items-center justify-between mt-2">
                      <div className="flex items-center gap-2">
                        <span className="bg-ev-blue text-white text-xs font-bold px-2.5 py-1 rounded-full">
                          Level {xp.level}
                        </span>
                        <span className="text-gray-300 text-sm tabular-nums">
                          {xp.xp_in_level.toLocaleString()} / {xp.xp_to_next_level.toLocaleString()} XP
                        </span>
                      </div>
                      {/* Small gems */}
                      <div className="flex items-center gap-4">
                        <GemPip
                          count={cp.gems.yellow}
                          shape="square"
                          style={{ borderRadius: '4px', background: 'linear-gradient(145deg, #FFE566 0%, #FFB800 55%, #E07000 100%)', boxShadow: '0 0 8px rgba(255,184,0,0.4)' }}
                        />
                        <GemPip
                          count={cp.gems.blue}
                          shape="circle"
                          style={{ borderRadius: '50%', background: 'radial-gradient(circle at 35% 30%, #BFDBFE 0%, #60A5FA 35%, #3B82F6 65%, #1E40AF 100%)', boxShadow: '0 0 8px rgba(59,130,246,0.4)' }}
                        />
                        <GemPip
                          count={cp.gems.red}
                          shape="square"
                          style={{ borderRadius: '4px', background: 'linear-gradient(145deg, #FF9A8B 0%, #FF5740 50%, #C41E00 100%)', boxShadow: '0 0 8px rgba(255,87,64,0.4)' }}
                        />
                      </div>
                    </div>
                    {/* XP bar */}
                    <div className="mt-3 h-1.5 rounded-full bg-gray-800 overflow-hidden">
                      <div
                        className="bg-ev-blue h-full rounded-full transition-all duration-700"
                        style={{ width: `${xpPercent}%`, boxShadow: '0 0 10px rgba(59,130,246,0.6)' }}
                      />
                    </div>
                    <p className="text-xs text-gray-500 mt-1.5 tabular-nums">
                      {xp.total.toLocaleString()} total XP earned
                    </p>
                  </>
                ) : null}
              </div>

              {/* Features — square uniform tiles, wide enough for longest name */}
              <div className="bg-gray-900 rounded-2xl border border-gray-800 p-4">
                <div className="flex items-center gap-4 mb-3">
                  <h2 className="text-sm font-semibold text-white">Empowered Vote Features</h2>
                  <div className="flex items-center gap-3 text-xs text-gray-500">
                    <span className="flex items-center gap-1.5">
                      <span className="w-2 h-2 rounded-full bg-ev-yellow inline-block" />Inform
                    </span>
                    <span className="flex items-center gap-1.5">
                      <span className="w-2 h-2 rounded-full bg-ev-blue inline-block" />Connect
                    </span>
                  </div>
                </div>
                {/* minmax(14rem) ensures "Civic Trivia Championships" fits on one line at text-sm */}
                <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(14rem, 1fr))' }}>
                  {ALL_FEATURES.map((f) => {
                    const href = accessToken ? `${f.href}#access_token=${accessToken}` : f.href;
                    return (
                      <a
                        key={f.name}
                        href={href}
                        target="_blank"
                        rel="noopener noreferrer"
                        className={`bg-gray-800/60 rounded-xl border border-gray-700 p-3 flex flex-col gap-1.5 hover:bg-gray-800 transition-colors ${f.border}`}
                      >
                        <span className={`w-2 h-2 rounded-full flex-shrink-0 ${f.dot}`} />
                        <p className="text-sm font-semibold text-white leading-snug whitespace-nowrap overflow-hidden text-ellipsis">{f.name}</p>
                        <p className="text-xs text-gray-400 leading-relaxed">{f.description}</p>
                      </a>
                    );
                  })}
                </div>
              </div>

              {/* Three-col row: Verification Rating | Civic Spaces | Recent Activity */}
              {cp && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-3">

                  {/* Verification Rating */}
                  <div className="bg-gray-900 rounded-2xl border border-gray-800 p-4 flex flex-col gap-2">
                    <p className="text-xs text-gray-500 uppercase tracking-widest font-medium">Verification Rating</p>
                    <div className="flex items-baseline gap-1.5">
                      <span className="text-3xl font-bold text-ev-teal-light tabular-nums">{cp.verification_rating}</span>
                      <span className="text-base font-medium text-gray-400">/ 150</span>
                    </div>
                    <div className="h-1.5 rounded-full bg-gray-800 overflow-hidden">
                      <div
                        className="bg-ev-teal-light h-full rounded-full transition-all duration-700"
                        style={{ width: `${vrPercent}%` }}
                      />
                    </div>
                    <p className="text-xs text-gray-400">Keep validating to increase your credibility score</p>
                    {cp.vq_hold_active && (
                      <p className="text-xs text-ev-red font-medium">VQ hold active — paused 30 days</p>
                    )}
                  </div>

                  {/* Civic Spaces */}
                  <div className="bg-gray-900 rounded-2xl border border-gray-800 p-4 flex flex-col gap-2">
                    <div className="flex items-center justify-between">
                      <p className="text-xs text-gray-500 uppercase tracking-widest font-medium">Civic Spaces</p>
                      <a
                        href="https://civicspaces.empowered.vote"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-xs text-ev-teal-light hover:underline"
                      >
                        Open &rarr;
                      </a>
                    </div>

                    {hasDistricts ? (
                      <>
                        {(jurisdiction.city || jurisdiction.state) && (
                          <p className="text-sm font-semibold text-white">
                            {[jurisdiction.city, jurisdiction.state].filter(Boolean).join(', ')}
                          </p>
                        )}
                        <div className="divide-y divide-gray-800 flex-1">
                          {DISTRICT_LABELS.filter(({ key }) => jurisdiction && jurisdiction[key]).map(({ key, label }) => (
                            <div key={key} className="flex items-center justify-between py-1.5 first:pt-0">
                              <span className="text-xs text-gray-400 flex-shrink-0">{label}</span>
                              <span className="text-xs font-medium text-white text-right ml-2 truncate max-w-[60%]">
                                {jurisdiction![key]}
                              </span>
                            </div>
                          ))}
                        </div>
                        <button
                          onClick={() => setShowLocationForm(!showLocationForm)}
                          className="text-xs text-ev-teal-light hover:underline text-left"
                        >
                          Update location &rarr;
                        </button>
                      </>
                    ) : (
                      <>
                        <p className="text-sm text-white font-medium">
                          {profile.location_consent ? 'Locating your civic spaces…' : 'No location set'}
                        </p>
                        {!profile.location_consent && (
                          <p className="text-xs text-gray-400">Add your address to find your representatives.</p>
                        )}
                        <button
                          onClick={() => setShowLocationForm(!showLocationForm)}
                          className="text-xs text-ev-teal-light hover:underline text-left"
                        >
                          {profile.location_consent ? 'Update location →' : 'Set your location →'}
                        </button>
                      </>
                    )}

                    {showLocationForm && (
                      <form onSubmit={handleSetLocation} className="space-y-2 mt-1 border-t border-gray-800 pt-2">
                        <input
                          type="text"
                          value={address}
                          onChange={(e) => setAddress(e.target.value)}
                          placeholder="Enter your address"
                          className="w-full px-3 py-2 border border-gray-700 rounded-lg text-xs bg-gray-800 text-white placeholder-gray-500 focus:outline-none focus:border-ev-teal-light"
                        />
                        <div className="flex gap-2">
                          <button
                            type="submit"
                            disabled={address.trim().length === 0 || locationLoading}
                            className="bg-ev-teal-light text-white text-xs font-medium px-3 py-1.5 rounded-lg hover:bg-ev-teal-light/90 disabled:opacity-50 transition-colors"
                          >
                            {locationLoading ? 'Setting…' : 'Set'}
                          </button>
                          <button
                            type="button"
                            onClick={() => setShowLocationForm(false)}
                            className="text-xs text-gray-400 hover:text-white px-2 py-1.5 transition-colors"
                          >
                            Cancel
                          </button>
                        </div>
                        {locationSuccess && <p className="text-xs text-green-400">Updated!</p>}
                        {locationError && <p className="text-xs text-ev-red">{locationError}</p>}
                      </form>
                    )}
                  </div>

                  {/* Recent Activity */}
                  <div className="bg-gray-900 rounded-2xl border border-gray-800 p-4 flex flex-col gap-2">
                    <p className="text-xs text-gray-500 uppercase tracking-widest font-medium">Recent Activity</p>
                    {activity.length === 0 ? (
                      <p className="text-xs text-gray-400">
                        No XP earned yet — explore a feature to get started.
                      </p>
                    ) : (
                      <div className="divide-y divide-gray-800 flex-1">
                        {activity.slice(0, 5).map((entry, i) => (
                          <div key={i} className="flex items-center justify-between py-1.5 first:pt-0 gap-2">
                            <div className="min-w-0">
                              <p className="text-xs font-medium text-white truncate">{titleCase(entry.description)}</p>
                              <p className="text-[11px] text-gray-500 tabular-nums">
                                {new Date(entry.created_at).toLocaleDateString(undefined, {
                                  month: 'short', day: 'numeric',
                                })}
                              </p>
                            </div>
                            <span className="bg-ev-teal-light/15 text-ev-teal-light text-xs font-semibold px-2 py-0.5 rounded-full tabular-nums flex-shrink-0">
                              +{entry.amount}
                            </span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                </div>
              )}

            </div>
          )}

          {/* ── REFERRALS TAB ────────────────────────────────────────────────── */}
          {activeTab === 'referrals' && cp && (
            <div className="max-w-2xl space-y-4">
              <div className="bg-gray-900 rounded-2xl border border-gray-800 p-5 space-y-5">
                <p className="text-xs text-gray-500 uppercase tracking-widest font-medium">Invite Friends</p>

                {!inviteesData ? (
                  <p className="text-sm text-gray-400">Loading&hellip;</p>
                ) : (
                  <>
                    <div className="flex items-center gap-2">
                      <span className="text-3xl font-bold text-white tabular-nums">{inviteesData.active_count}</span>
                      <span className="text-gray-400 text-sm">
                        / {inviteesData.cap >= 2147483647 ? 'Unlimited' : inviteesData.cap} active invitees
                      </span>
                    </div>

                    {inviteesData.cap === 0 ? (
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 rounded-xl bg-gray-800 flex items-center justify-center flex-shrink-0 text-gray-400">
                          <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
                          </svg>
                        </div>
                        <div>
                          <p className="text-white font-semibold">Reach level 2 to start inviting</p>
                          <p className="text-gray-400 text-sm mt-1">Keep earning XP to unlock your first invite slot.</p>
                        </div>
                      </div>
                    ) : inviteesData.can_generate ? (
                      <div className="space-y-2">
                        <input
                          type="text"
                          value={labelInput}
                          onChange={(e) => setLabelInput(e.target.value)}
                          onKeyDown={(e) => { if (e.key === 'Enter' && !generatingCode) handleGenerate(); }}
                          placeholder="Who is this for? (optional)"
                          maxLength={50}
                          className="w-full px-3 py-2.5 text-sm border border-gray-700 rounded-xl bg-gray-800 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal/30 focus:border-ev-teal transition-colors"
                        />
                        <button
                          onClick={handleGenerate}
                          disabled={generatingCode}
                          className="w-full py-2.5 px-4 bg-ev-teal text-white rounded-xl text-sm font-semibold hover:bg-ev-teal/90 transition-colors disabled:opacity-50"
                        >
                          {generatingCode ? 'Generating…' : 'Generate Invite Code'}
                        </button>
                      </div>
                    ) : (
                      <p className="text-xs text-gray-500 leading-relaxed">
                        All invite slots filled. Level up to earn more, or wait for an invitee to reach level 2.
                      </p>
                    )}

                    {newCode && (
                      <button
                        onClick={copyNewCode}
                        className="w-full flex items-center justify-between bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 hover:border-ev-teal-light/50 transition-colors"
                      >
                        <span className="font-mono text-lg font-bold tracking-widest text-white">{newCode}</span>
                        <span className="text-xs font-medium text-ev-teal-light">{newCodeCopied ? 'Copied!' : 'Copy'}</span>
                      </button>
                    )}

                    {inviteesData.invitees.some((i) => i.status === 'pending') && (
                      <div className="border-t border-gray-800 -mx-5 px-5 pt-4">
                        <p className="text-xs font-medium text-gray-400 mb-2">Pending Codes</p>
                        <div className="space-y-2">
                          {inviteesData.invitees.filter((i) => i.status === 'pending').map((entry) => (
                            <div key={entry.code}>
                              {entry.label && <p className="text-xs text-gray-400 mb-1 px-1">{entry.label}</p>}
                              <button
                                onClick={() => copyPendingCode(entry.code)}
                                className="w-full flex items-center justify-between bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 hover:border-ev-teal-light/50 transition-colors"
                              >
                                <span className="font-mono text-base font-bold tracking-widest text-white">{entry.code}</span>
                                <span className="text-xs font-medium text-ev-teal-light">
                                  {copiedCode === entry.code ? 'Copied!' : 'Copy'}
                                </span>
                              </button>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    {inviteesData.invitees.some((i) => i.status === 'claimed') && (
                      <div className="border-t border-gray-800 -mx-5 px-5 pt-4">
                        <p className="text-xs font-medium text-gray-400 mb-2">Your Invitees</p>
                        <div className="divide-y divide-gray-800">
                          {inviteesData.invitees.filter((i) => i.status === 'claimed').map((invitee) => {
                            const isLocked = invitee.slot_locked_until && new Date(invitee.slot_locked_until) > new Date();
                            const xpTotal = (invitee.xp_in_level ?? 0) + (invitee.xp_to_next_level ?? 0);
                            const xpPct = xpTotal > 0 ? Math.round(((invitee.xp_in_level ?? 0) / xpTotal) * 100) : 0;
                            return (
                              <div key={invitee.invitee_id} className="py-3">
                                <div className="flex items-center justify-between gap-2">
                                  <p className={`text-sm font-medium truncate ${invitee.graduated ? 'text-gray-400' : 'text-white'}`}>
                                    {invitee.display_name ?? invitee.label ?? '—'}
                                  </p>
                                  <div className="flex items-center gap-2 flex-shrink-0">
                                    {invitee.graduated ? (
                                      <span className="text-xs font-medium text-ev-teal bg-ev-teal/10 px-2 py-0.5 rounded-full">Graduated ✓</span>
                                    ) : invitee.account_standing === 'suspended' ? (
                                      <span className="text-xs font-medium text-ev-red bg-ev-red/10 px-2 py-0.5 rounded-full">Suspended</span>
                                    ) : (
                                      <span className="flex items-center gap-1 text-xs text-gray-500">
                                        <span className="w-1.5 h-1.5 rounded-full bg-green-400" />Active
                                      </span>
                                    )}
                                    {isLocked && (
                                      <span className="text-xs font-medium text-ev-red bg-ev-red/10 px-2 py-0.5 rounded-full">Slot locked</span>
                                    )}
                                  </div>
                                </div>
                                {!invitee.graduated && invitee.xp_in_level !== null && invitee.xp_to_next_level !== null && (
                                  <div className="mt-2 space-y-1">
                                    <div className="flex items-center justify-between text-xs text-gray-400">
                                      <span>Lv {invitee.current_level}</span>
                                      <span className="tabular-nums">{invitee.xp_in_level.toLocaleString()} / {xpTotal.toLocaleString()} XP</span>
                                    </div>
                                    <div className="h-1.5 rounded-full bg-gray-800 overflow-hidden">
                                      <div className="h-full rounded-full bg-ev-teal-light transition-all duration-700" style={{ width: `${xpPct}%` }} />
                                    </div>
                                  </div>
                                )}
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}
                  </>
                )}
              </div>
            </div>
          )}

          {/* ── POSTS TAB ────────────────────────────────────────────────────── */}
          {activeTab === 'posts' && cp && (
            <div className="max-w-2xl">
              <PostHistory />
            </div>
          )}

        </div>
      )}
    </div>
  );
}
