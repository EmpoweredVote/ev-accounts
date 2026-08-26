import { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { apiFetch } from '../lib/api';
import { useTheme } from '../hooks/useTheme';
import ConnectedExplainerModal from '../components/ConnectedExplainerModal';

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
interface MeInformProfile {
  yellow_gem_balance: number;
  last_essentials_location: unknown; // raw JSONB — may be null or an object whose shape is defined by the Essentials app
}
interface MeResponse {
  id: string;
  email: string;
  display_name: string | null;
  tier: 'inform' | 'connected' | 'empowered';
  is_admin: boolean;
  location_consent: boolean;
  connected_profile?: MeConnectedProfile;
  inform_profile?: MeInformProfile | null;
  jurisdiction?: {
    state: string | null;
    county: string | null;
    congressional_district: string | null;
    state_senate_district: string | null;
    state_house_district: string | null;
    city_council_district: string | null;
    city_council_district_name: string | null;
    school_district: string | null;
  } | null;
}
interface SchoolDistrictEntry {
  name: string | null;
  geoid: string;
}

interface SchoolDistrictData {
  school_unified:    SchoolDistrictEntry | null;
  school_elementary: SchoolDistrictEntry | null;
  school_secondary:  SchoolDistrictEntry | null;
}

interface DistrictsData {
  ca_assembly: { district_number: string; name: string | null; tiger_geoid: string } | null;
  ca_senate:   { district_number: string; name: string | null; tiger_geoid: string } | null;
  us_house:    { district_number: string; name: string | null; tiger_geoid: string } | null;
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
interface CompassStats { answered: number; total: number; }
interface ReadRankStats { ranked: number; total: number; }
interface UserRoleGrant {
  id: string;
  slug: string;
  name: string;
  granted_at: string;
  feature_scope: string;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
  granted_by_display_name: string | null;
}

// ── Feature definitions ───────────────────────────────────────────────────────

interface Feature {
  name: string;
  description: string;
  href: string;
  statsKey?: 'vr' | 'election' | 'readrank' | 'compass';
}

// Each entry matches when ANY of the user's jurisdiction geo IDs appears in geoIds.
// geoIds can be state abbreviations (e.g. 'CA'), county FIPS codes (e.g. '18105'),
// or any other geo ID from the jurisdiction object.
// To add a new election: append an entry. Entries are hidden once days reaches 0.
const UPCOMING_ELECTIONS: { date: Date; label: string; geoIds: string[] }[] = [
  { date: new Date('2026-05-05'), label: 'May 5 Primary',  geoIds: ['18105'] },       // Monroe County, IN
  { date: new Date('2026-06-02'), label: 'June 2 Primary', geoIds: ['CA'] },           // California
];

type MeJurisdiction = NonNullable<MeResponse['jurisdiction']>;

function electionForJurisdiction(j: MeJurisdiction | null | undefined): { days: number; label: string } | null {
  if (!j) return null;
  const userIds = new Set(
    [j.state?.toUpperCase(), j.county, j.congressional_district,
     j.state_senate_district, j.state_house_district,
     j.city_council_district, j.school_district]
    .filter(Boolean) as string[]
  );
  const now = Date.now();
  const match = UPCOMING_ELECTIONS
    .filter(e => e.geoIds.some(id => userIds.has(id)))
    .map(e => ({ label: e.label, days: Math.max(0, Math.ceil((e.date.getTime() - now) / 86400000)) }))
    .filter(e => e.days > 0)
    .sort((a, b) => a.days - b.days)[0];
  return match ?? null;
}

const INFORM_FEATURES: Feature[] = [
  { name: 'Essentials', description: 'Find out who represents you and where they stand.', href: 'https://essentials.empowered.vote', statsKey: 'election' },
  { name: 'Compass', description: 'See how your values align with politicians and candidates.', href: 'https://compass.empowered.vote', statsKey: 'compass' },
  { name: 'Treasury Tracker', description: 'Follow the money — public funds allocation and spending.', href: 'https://treasurytracker.empowered.vote' },
  { name: 'Civic Trivia Championships', description: 'Test your knowledge on where politicians really stand.', href: 'https://ctc.empowered.vote' },
  { name: 'Read & Rank', description: 'Put your opinion above party lines — a blind taste test.', href: 'https://readrank.empowered.vote', statsKey: 'readrank' },
];

const CONNECT_FEATURES: Feature[] = [
  { name: 'Validation Quests', description: 'Verify politician stances and earn Red Gems for accuracy.', href: 'https://quests.empowered.vote', statsKey: 'vr' },
  { name: 'Focused Communities', description: 'Join issue-focused civic discussions that matter to you.', href: 'https://fc.empowered.vote' },
  { name: 'Empowered Listening', description: 'Hear diverse perspectives and find common ground.', href: 'https://listening.empowered.vote' },
];

// ── Contributor role metadata ──────────────────────────────────────────────────

const ROLE_META: Record<string, { description: string; href: string }> = {
  compass_stance_editor: {
    description: 'Edit and curate politician stances in the Compass.',
    href: 'https://app.empowered.vote/contributor/compass-editor',
  },
  campaign_manager: {
    description: 'Manage campaign profiles and candidate information.',
    href: 'https://app.empowered.vote/contributor/campaign-manager',
  },
  essentials_data_editor: {
    description: 'Manage representative and office data in Essentials.',
    href: 'https://app.empowered.vote/contributor/essentials-editor',
  },
};

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

// ── Gem pip (small, inline in header) ────────────────────────────────────────

function GemPip({ count, gemStyle, tooltip }: { count: number; gemStyle: React.CSSProperties; tooltip: string }) {
  return (
    <div className="relative group flex items-center gap-1.5">
      <div className="w-5 h-5 flex-shrink-0" style={gemStyle} />
      <span className="text-gray-900 dark:text-white text-sm font-semibold tabular-nums">{count.toLocaleString()}</span>
      <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2.5 py-1.5 bg-gray-800 border border-gray-700 text-white text-xs rounded-lg whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-20">
        {tooltip}
      </div>
    </div>
  );
}

// ── Feature tile ──────────────────────────────────────────────────────────────

interface FeatureTileProps {
  feature: Feature;
  href: string;
  dotClass: string;
  borderHover: string;
  vr: number | null;
  vrPercent: number;
  readRankStats: ReadRankStats | null;
  compassStats: CompassStats | null;
  jurisdiction?: MeJurisdiction | null;
  lastEssentialsLocation?: unknown;
  locked?: boolean;
}

function FeatureTile({ feature, href, dotClass, borderHover, vr, vrPercent, readRankStats, compassStats, jurisdiction, lastEssentialsLocation, locked }: FeatureTileProps) {
  const election = feature.statsKey === 'election' ? electionForJurisdiction(jurisdiction) : null;
  const showVr = feature.statsKey === 'vr' && vr !== null;
  const showElection = election !== null;
  const showReadRank = feature.statsKey === 'readrank' && readRankStats !== null;
  const showCompass = feature.statsKey === 'compass' && compassStats !== null;
  const rrPct = readRankStats && readRankStats.total > 0
    ? Math.round((readRankStats.ranked / readRankStats.total) * 100)
    : 0;
  const compassPct = compassStats && compassStats.total > 0
    ? Math.round((compassStats.answered / compassStats.total) * 100)
    : 0;

  const locationLabel = (() => {
    if (feature.statsKey !== 'election') return null;
    if (!lastEssentialsLocation) return null;
    const loc = lastEssentialsLocation as Record<string, unknown>;
    return (typeof loc.city === 'string' && loc.city)
      || (typeof loc.name === 'string' && loc.name)
      || (typeof loc.label === 'string' && loc.label)
      || 'Location saved';
  })();

  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      className={`relative bg-gray-50 dark:bg-gray-800/60 rounded-xl border border-gray-200 dark:border-gray-700 p-3 flex flex-col gap-1.5 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors min-h-[13rem] ${borderHover}`}
    >
      {locked && (
        <span
          className="absolute top-2 right-2 inline-flex items-center justify-center w-5 h-5 rounded-full bg-ev-yellow/20 dark:bg-ev-yellow/15 border border-ev-yellow/50 text-yellow-700 dark:text-ev-yellow"
          aria-label="Observe access only — Connect your account to participate"
          title="Observe access only"
        >
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <rect x="4" y="11" width="16" height="10" rx="2" />
            <path d="M8 11V7a4 4 0 0 1 8 0v4" />
          </svg>
        </span>
      )}
      <span className={`w-2 h-2 rounded-full flex-shrink-0 ${dotClass}`} />
      <p className="text-sm font-semibold text-gray-900 dark:text-white leading-snug">{feature.name}</p>
      <p className="text-xs text-gray-600 dark:text-gray-400 leading-relaxed">{feature.description}</p>

      {(showVr || showElection || showReadRank || showCompass || (!showElection && locationLabel)) && (
        <div className="mt-auto pt-2 border-t border-gray-200 dark:border-gray-700/60 space-y-1">
          {showElection && election && (
            <p className="text-xs text-gray-600 dark:text-gray-400">
              <span className="text-gray-900 dark:text-white font-semibold tabular-nums">{election.days}</span>
              {' '}days until {election.label}
            </p>
          )}
          {!showElection && locationLabel && (
            <p className="text-xs text-gray-600 dark:text-gray-400">
              <span className="text-gray-900 dark:text-white font-semibold">{locationLabel}</span>
              {' '}— last searched
            </p>
          )}
          {showVr && (
            <>
              <p className="text-xs text-gray-400">
                <span className="text-white font-semibold tabular-nums">{vr}</span>
                <span> / 150 verification rating</span>
              </p>
              <div className="h-1 rounded-full bg-gray-200 dark:bg-gray-700 overflow-hidden">
                <div className="bg-ev-teal-light h-full rounded-full" style={{ width: `${vrPercent}%` }} />
              </div>
            </>
          )}
          {showReadRank && readRankStats && (
            <>
              <p className="text-xs text-gray-400">
                <span className="text-white font-semibold tabular-nums">{readRankStats.ranked}</span>
                <span> / {readRankStats.total} stances ranked</span>
              </p>
              <div className="h-1 rounded-full bg-gray-200 dark:bg-gray-700 overflow-hidden">
                <div className="bg-ev-yellow h-full rounded-full" style={{ width: `${rrPct}%` }} />
              </div>
            </>
          )}
          {showCompass && compassStats && (
            <>
              <p className="text-xs text-gray-400">
                <span className="text-gray-900 dark:text-white font-semibold tabular-nums">{compassStats.answered}</span>
                <span> / {compassStats.total} stances calibrated</span>
              </p>
              <div className="h-1 rounded-full bg-gray-200 dark:bg-gray-700 overflow-hidden">
                <div className="bg-ev-yellow h-full rounded-full" style={{ width: `${compassPct}%` }} />
              </div>
            </>
          )}
        </div>
      )}
    </a>
  );
}

// ── Civic Spaces tile ─────────────────────────────────────────────────────────

interface CivicSpacesTileProps {
  accessToken: string | null;
  city: string | null;
  showForm: boolean;
  onToggleForm: () => void;
  address: string;
  onAddressChange: (v: string) => void;
  onSubmit: (e: React.FormEvent) => void;
  locationLoading: boolean;
  locationSuccess: boolean;
  locationError: string | null;
}

function CivicSpacesTile({
  accessToken, city, showForm, onToggleForm, address, onAddressChange, onSubmit,
  locationLoading, locationSuccess, locationError,
}: CivicSpacesTileProps) {
  const href = `https://civicspaces.empowered.vote${accessToken ? `#access_token=${accessToken}` : ''}`;
  return (
    <div className="bg-gray-50 dark:bg-gray-800/60 rounded-xl border border-gray-200 dark:border-gray-700 flex flex-col min-h-[13rem] hover:border-ev-blue/50 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors overflow-hidden">
      <a href={href} target="_blank" rel="noopener noreferrer" className="flex flex-col gap-1.5 p-3 flex-1">
        <span className="w-2 h-2 rounded-full flex-shrink-0 bg-ev-blue" />
        <p className="text-sm font-semibold text-gray-900 dark:text-white leading-snug">Civic Spaces</p>
        <p className="text-xs text-gray-600 dark:text-gray-400 leading-relaxed">Engage with your local civic community online.</p>
      </a>

      <div className="px-3 pb-3 pt-2 border-t border-gray-200 dark:border-gray-700/60 space-y-1.5">
        {!showForm ? (
          <div className="flex items-center justify-between">
            <span className="text-xs text-gray-600 dark:text-gray-300 font-medium">{city ?? 'Set your location'}</span>
            <div className="relative group">
              <button
                onClick={onToggleForm}
                className="flex items-center justify-center w-6 h-6 opacity-70 hover:opacity-100 transition-opacity"
                aria-label="Update your location"
              >
                <svg width="16" height="16" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
                  <path d="m118.22 175.74c0-76.098 61.68-137.8 137.78-137.8s137.78 61.699 137.78 137.78c0 73.062-75.82 162.42-128.86 212.7-5 4.7383-12.84 4.7383-17.84 0-53.039-50.281-128.86-139.64-128.86-212.68zm217.02 166.36c-2.9414 3.5586-5.8984 7.0586-8.8594 10.5 50.602 7.3398 85.301 22.34 85.301 39.641 0 24.539-69.699 44.422-155.66 44.422-85.961 0-155.66-19.879-155.66-44.422 0-17.301 34.68-32.301 85.277-39.641-2.9805-3.4414-5.918-6.9414-8.8594-10.5-67.359 10.801-114.28 34.922-114.28 62.961 0 38.102 86.621 69.004 193.5 69.004 106.86 0 193.5-30.898 193.5-69.004 0-28.039-46.922-52.164-114.26-62.961zm-79.242-229.5c-34.859 0-63.141 28.262-63.141 63.141 0 34.859 28.262 63.141 63.141 63.141 34.859 0 63.141-28.262 63.141-63.141 0-34.879-28.281-63.141-63.141-63.141z" fill="#ff563f" fillRule="evenodd"/>
                </svg>
              </button>
              <div className="absolute bottom-full right-0 mb-2 px-2.5 py-1.5 bg-gray-800 border border-gray-700 text-white text-xs rounded-lg whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-20">
                Update your location
              </div>
            </div>
          </div>
        ) : (
          <form onSubmit={onSubmit} className="space-y-1.5">
            <input
              type="text"
              value={address}
              onChange={(e) => onAddressChange(e.target.value)}
              placeholder="Enter your address"
              className="w-full px-2 py-1.5 border border-gray-300 dark:border-gray-600 rounded-lg text-xs bg-white dark:bg-gray-900 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:border-ev-teal-light"
            />
            <div className="flex gap-1.5">
              <button
                type="submit"
                disabled={address.trim().length === 0 || locationLoading}
                className="bg-ev-teal-light text-white text-xs font-medium px-2.5 py-1 rounded-lg disabled:opacity-50 transition-colors"
              >
                {locationLoading ? 'Setting…' : 'Set'}
              </button>
              <button
                type="button"
                onClick={() => onToggleForm()}
                className="text-xs text-gray-400 hover:text-white px-1.5 py-1"
              >
                Cancel
              </button>
            </div>
            {locationSuccess && <p className="text-[11px] text-green-400">Updated!</p>}
            {locationError && <p className="text-[11px] text-ev-red">{locationError}</p>}
          </form>
        )}
      </div>
    </div>
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

  if (loadState === 'loading' && posts.length === 0)
    return <div className="bg-gray-900 rounded-2xl border border-gray-800 p-5 flex items-center justify-center"><p className="text-sm text-gray-400">Loading posts…</p></div>;
  if (loadState === 'error-access')
    return <div className="bg-gray-900 rounded-2xl border border-gray-800 p-5"><p className="text-sm font-medium text-ev-red">Access denied</p></div>;
  if (loadState === 'error-generic')
    return <div className="bg-gray-900 rounded-2xl border border-gray-800 p-5"><p className="text-sm font-medium text-white">Failed to load posts</p><button onClick={() => { setLoadState('loading'); loadPage(null); }} className="mt-3 px-4 py-2 bg-ev-teal text-white rounded-xl text-sm font-semibold hover:bg-ev-teal/90 transition-colors">Retry</button></div>;
  if (loadState === 'loaded' && posts.length === 0)
    return <div className="bg-gray-900 rounded-2xl border border-gray-800 p-5"><p className="text-sm text-gray-400">No posts yet</p></div>;

  return (
    <div className="space-y-3">
      {posts.length > 0 && (
        <div className="bg-gray-900 rounded-2xl border border-gray-800 divide-y divide-gray-800">
          {posts.map((post) => (
            <div key={post.postId} className="p-4 space-y-1">
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">{post.communityName}</p>
              <a href={`https://fc.empowered.vote/communities/${post.communitySlug}/threads/${post.threadId}`} target="_blank" rel="noopener noreferrer" className="block text-sm font-semibold text-ev-teal-light hover:underline">{post.threadTitle}</a>
              <p className="text-sm text-white leading-snug">{post.postExcerpt}</p>
              <div className="flex items-center gap-2 text-xs text-gray-500 pt-0.5">
                <span className="font-medium">{post.authorPseudonym}</span>
                <span className="text-gray-700">&bull;</span>
                <time dateTime={post.createdAt} className="tabular-nums">{new Date(post.createdAt).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })}</time>
                {post.isEdited && <span className="ml-1 text-[11px] font-medium text-gray-400 italic">(edited)</span>}
              </div>
            </div>
          ))}
        </div>
      )}
      {hasMore && posts.length > 0 && (
        <button onClick={handleLoadMore} disabled={loadingMore} className="w-full py-2 px-4 bg-gray-900 border border-gray-800 text-ev-teal-light rounded-xl text-sm font-semibold hover:border-gray-600 transition-colors disabled:opacity-50">
          {loadingMore ? 'Loading…' : 'Load more'}
        </button>
      )}
    </div>
  );
}

// ── SchoolDistrictSection ─────────────────────────────────────────────────────

function SchoolDistrictSection({ data }: { data: SchoolDistrictData | null }) {
  if (!data) return null;
  const { school_unified, school_elementary, school_secondary } = data;
  if (!school_unified && !school_elementary && !school_secondary) return null;

  const makeLink = (name: string | null, geoid: string) => {
    const label = name ?? `School District ${geoid}`;
    const url = `https://www.google.com/search?q=${encodeURIComponent(label)}`;
    return (
      <a
        href={url}
        target="_blank"
        rel="noopener noreferrer"
        className="text-ev-teal dark:text-ev-teal-light hover:underline text-sm"
      >
        {label}
      </a>
    );
  };

  // CONTEXT decision: unified district takes precedence — single combined entry
  if (school_unified) {
    return (
      <div>
        <p className="text-xs font-medium text-gray-500 dark:text-gray-400">School District</p>
        {makeLink(school_unified.name, school_unified.geoid)}
      </div>
    );
  }

  // Elementary + secondary (no unified) — two labeled sub-entries
  return (
    <div className="space-y-1.5">
      {school_elementary && (
        <div>
          <p className="text-xs font-medium text-gray-500 dark:text-gray-400">
            Elementary School District
          </p>
          {makeLink(school_elementary.name, school_elementary.geoid)}
        </div>
      )}
      {school_secondary && (
        <div>
          <p className="text-xs font-medium text-gray-500 dark:text-gray-400">
            Secondary School District
          </p>
          {makeLink(school_secondary.name, school_secondary.geoid)}
        </div>
      )}
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
  const [inviteesData, setInviteesData] = useState<InviteesData | null>(null);
  const [generatingCode, setGeneratingCode] = useState(false);
  const [labelInput, setLabelInput] = useState('');
  const [copiedCode, setCopiedCode] = useState<string | null>(null);
  const [compassStats, setCompassStats] = useState<CompassStats | null>(null);
  const [readRankStats, setReadRankStats] = useState<ReadRankStats | null>(null);
  const [roles, setRoles] = useState<UserRoleGrant[]>([]);
  const [activeTab, setActiveTab] = useState<'profile' | 'location' | 'referrals' | 'posts' | 'contributor'>('profile');

  const [city, setCity] = useState<string | null>(null);
  const [address, setAddress] = useState('');
  const [locationLoading, setLocationLoading] = useState(false);
  const [locationSuccess, setLocationSuccess] = useState(false);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [showLocationForm, setShowLocationForm] = useState(false);
  const [explainerOpen, setExplainerOpen] = useState(false);
  const [districts, setDistricts] = useState<DistrictsData | null>(null);
  const [schoolDistrict, setSchoolDistrict] = useState<SchoolDistrictData | null>(null);

  useEffect(() => {
    apiFetch<MeResponse>('/account/me')
      .then((data) => {
        setProfile(data);
        if (data.location_consent) {
          apiFetch<{ jurisdiction: { city: string | null } }>('/account/me/jurisdiction')
            .then((j) => setCity(j.jurisdiction.city))
            .catch(() => {});
        }
        apiFetch<DistrictsData>('/account/districts')
          .then(setDistricts)
          .catch(() => {}); // 204 throws SyntaxError (no body) — leaves state null, section hidden
        apiFetch<SchoolDistrictData>('/account/school-district')
          .then(setSchoolDistrict)
          .catch(() => {}); // 204 throws SyntaxError (no body) — leaves state null, section hidden
        if (data.connected_profile) {
          apiFetch<InviteesData>('/invites/my-invitees').then(setInviteesData).catch(() => {});
          apiFetch<{ roles: UserRoleGrant[] }>('/roles/me')
            .then((r) => setRoles(r.roles))
            .catch(() => {});
          const token = useAuthStore.getState().accessToken;
          if (token && data.id) {
            fetch(`https://readrank.empowered.vote/api/users/${data.id}/stats`, {
              headers: { Authorization: `Bearer ${token}` },
            })
              .then((r) => r.ok ? r.json() as Promise<ReadRankStats> : null)
              .then((d) => { if (d && typeof d.ranked === 'number') setReadRankStats(d); })
              .catch(() => {});
          }
        }
        if (data.connected_profile || data.tier === 'inform') {
          Promise.all([
            apiFetch<unknown>('/compass/answers'),
            apiFetch<unknown>('/compass/topics'),
          ]).then(([answersData, topicsData]) => {
            const answered = Array.isArray(answersData)
              ? answersData.length
              : ((answersData as { answers?: unknown[] })?.answers?.length ?? 0);
            const total = Array.isArray(topicsData)
              ? topicsData.length
              : ((topicsData as { topics?: unknown[] })?.topics?.length ?? 21);
            setCompassStats({ answered, total });
          }).catch(() => {});
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
      const result = await apiFetch<{ jurisdiction: { city: string | null } }>('/connect/set-location', {
        method: 'POST',
        body: JSON.stringify({ address: address.trim(), force: true }),
      });
      setCity(result.jurisdiction.city);
      setLocationSuccess(true);
      setAddress('');
      setShowLocationForm(false);
      // Refetch districts + school district after location update
      apiFetch<DistrictsData>('/account/districts').then(setDistricts).catch(() => {});
      apiFetch<SchoolDistrictData>('/account/school-district').then(setSchoolDistrict).catch(() => {});
    } catch (err: unknown) {
      setLocationError((err instanceof Error ? err.message : null) || 'Failed to set location');
    } finally {
      setLocationLoading(false);
    }
  }

  const handleGenerate = useCallback(async () => {
    setGeneratingCode(true);
    try {
      await apiFetch<{ code: string; active_count: number; cap: number }>(
        '/invites/generate',
        { method: 'POST', body: JSON.stringify({ label: labelInput.trim() || null }) },
      );
      setLabelInput('');
      const updated = await apiFetch<InviteesData>('/invites/my-invitees');
      setInviteesData(updated);
    } catch { /* CAP_REACHED or rate limit */ }
    finally { setGeneratingCode(false); }
  }, [labelInput]);

  const copyPendingCode = useCallback((code: string) => {
    navigator.clipboard.writeText(code).then(() => { setCopiedCode(code); setTimeout(() => setCopiedCode(null), 2000); }).catch(() => {});
  }, []);

  const cp = profile?.connected_profile;
  const xp = cp?.xp ?? null;
  const xpPercent = xp && xp.xp_to_next_level > 0
    ? Math.min(100, Math.round((xp.xp_in_level / xp.xp_to_next_level) * 100))
    : 0;
  const xpLevelTotal = xp ? xp.xp_in_level + xp.xp_to_next_level : 0;
  const vrPercent = cp ? Math.min(100, Math.round((cp.verification_rating / 150) * 100)) : 0;
  const displayName = profile?.display_name ?? user?.email?.split('@')[0] ?? 'Member';

  const sharedTileProps = { vr: cp?.verification_rating ?? null, vrPercent, readRankStats, compassStats, jurisdiction: profile?.jurisdiction ?? null, lastEssentialsLocation: profile?.inform_profile?.last_essentials_location ?? null };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950 transition-colors duration-200">

      {/* Nav */}
      <nav className="bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800 px-4 sm:px-8 lg:px-16 py-3 flex items-center justify-between sticky top-0 z-10">
        <span className="font-semibold text-gray-900 dark:text-white">Empowered Vote</span>
        <div className="flex items-center gap-3">
          <button onClick={toggle} aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'} className="text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 transition-colors p-1 rounded-md">
            {isDark ? <SunIcon /> : <MoonIcon />}
          </button>
          {user?.isAdmin && (
            <div className="relative group">
              <a href="/admin" className="flex items-center justify-center w-8 h-8 rounded-full hover:bg-ev-red/10 transition-colors">
                <img src="/Red_Admin.png" alt="Admin Hub" className="w-5 h-5 object-contain" />
              </a>
              <div className="absolute right-0 top-full mt-2 px-2.5 py-1 bg-gray-800 text-white text-xs rounded-lg whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">Admin Hub</div>
            </div>
          )}
          <button onClick={handleSignOut} className="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 transition-colors">Sign out</button>
        </div>
      </nav>

      {profileError && (
        <div className="px-4 sm:px-8 lg:px-16 pt-6">
          <p className="text-sm text-gray-400 italic">Could not load profile details. Try refreshing.</p>
        </div>
      )}

      {profile && (
        <div className="px-4 sm:px-8 lg:px-16 py-5">

          {/* Tab bar — tabs left, Connected Account pill right */}
          <div className="flex items-center justify-between border-b border-gray-200 dark:border-gray-800 mb-5">
            <nav className="flex gap-1">
              {(['profile', 'location', 'referrals', 'posts', 'contributor'] as const).map((tab) => {
                if (tab === 'location' && !cp && !profile.inform_profile?.last_essentials_location) return null;
                if ((tab === 'referrals' || tab === 'posts' || tab === 'contributor') && !cp) return null;
                const isActive = activeTab === tab;
                return (
                  <button
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors ${
                      isActive
                        ? profile.tier === 'inform'
                          ? 'border-ev-yellow text-ev-black dark:text-ev-yellow'
                          : 'border-ev-teal-light text-ev-teal dark:text-ev-teal-light'
                        : 'border-transparent text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300'
                    }`}
                  >
                    {tab === 'referrals' ? 'Referrals' : tab === 'posts' ? 'Posts' : tab === 'contributor' ? 'Contributor' : tab === 'location' ? 'Location' : 'Profile'}
                  </button>
                );
              })}
            </nav>
            {profile.tier === 'inform' ? (
              <button
                type="button"
                onClick={() => setExplainerOpen(true)}
                className="border text-xs font-semibold px-3 py-1 rounded-full flex-shrink-0 mb-px cursor-pointer bg-ev-yellow border-ev-yellow text-ev-black dark:bg-ev-yellow/10 dark:border-ev-yellow/50 dark:text-ev-yellow hover:bg-ev-yellow/90 dark:hover:bg-ev-yellow/20 transition-colors"
                aria-label="Learn about Connected Accounts"
              >
                Inform Account
              </button>
            ) : (
              <button
                type="button"
                onClick={() => setExplainerOpen(true)}
                className={`border text-xs font-semibold px-3 py-1 rounded-full flex-shrink-0 mb-px cursor-pointer transition-colors ${
                  profile.tier === 'empowered'
                    ? 'border-ev-red/40 text-ev-red hover:bg-ev-red/10'
                    : 'border-ev-blue/40 text-ev-blue dark:border-ev-blue/30 dark:text-ev-blue/80 hover:bg-ev-blue/10'
                }`}
                aria-label="Learn about account tiers"
              >
                {profile.tier === 'empowered' ? 'Empowered Account' : 'Connected Account'}
              </button>
            )}
          </div>

          {/* ── PROFILE TAB ─────────────────────────────────────────────────── */}
          {activeTab === 'profile' && (
            <div className="space-y-3">

              {/* Header card — width of two feature tiles, height of a feature tile */}
              <div className={`w-full md:w-[30.5rem] bg-white dark:bg-gray-900 rounded-2xl border p-4 min-h-[13rem] flex flex-col justify-between ${
                profile.tier === 'inform'
                  ? 'border-ev-yellow/60 dark:border-ev-yellow/25'
                  : 'border-gray-200 dark:border-gray-800'
              }`}>
                <div>
                  <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-3">{displayName}</h1>
                  {cp && xp ? (
                    <div className="flex items-center justify-between">
                      <span className="bg-ev-blue text-white text-xs font-bold px-2.5 py-1 rounded-full">Level {xp.level}</span>
                      {(cp.gems.yellow > 0 || cp.gems.blue > 0 || cp.gems.red > 0) && (
                        <div className="flex items-center gap-3">
                          {cp.gems.yellow > 0 && <GemPip count={cp.gems.yellow} tooltip="Yellow Gems validate facts." gemStyle={{ borderRadius: '4px', background: 'linear-gradient(145deg, #FFE566 0%, #FFB800 55%, #E07000 100%)', boxShadow: '0 0 8px rgba(255,184,0,0.4)' }} />}
                          {cp.gems.blue > 0 && <GemPip count={cp.gems.blue} tooltip="Blue Gems to vote your values." gemStyle={{ borderRadius: '50%', background: 'radial-gradient(circle at 35% 30%, #BFDBFE 0%, #60A5FA 35%, #3B82F6 65%, #1E40AF 100%)', boxShadow: '0 0 8px rgba(59,130,246,0.4)' }} />}
                          {cp.gems.red > 0 && <GemPip count={cp.gems.red} tooltip="Red Gems amplify your impact." gemStyle={{ borderRadius: '4px', background: 'linear-gradient(145deg, #FF9A8B 0%, #FF5740 50%, #C41E00 100%)', boxShadow: '0 0 8px rgba(255,87,64,0.4)', transform: 'rotate(45deg)' }} />}
                        </div>
                      )}
                    </div>
                  ) : profile.tier === 'inform' && profile.inform_profile != null && profile.inform_profile.yellow_gem_balance > 0 ? (
                    <GemPip
                      count={profile.inform_profile.yellow_gem_balance}
                      tooltip="Yellow Gems amplify ideas."
                      gemStyle={{ borderRadius: '4px', background: 'linear-gradient(145deg, #FFE566 0%, #FFB800 55%, #E07000 100%)', boxShadow: '0 0 8px rgba(255,184,0,0.4)' }}
                    />
                  ) : null}
                </div>
                {cp && xp ? (
                  <div>
                    <div className="h-1.5 rounded-full bg-gray-800 overflow-hidden">
                      <div className="bg-ev-blue h-full rounded-full transition-all duration-700" style={{ width: `${xpPercent}%`, boxShadow: '0 0 10px rgba(59,130,246,0.6)' }} />
                    </div>
                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1.5 tabular-nums text-right">
                      {xp.xp_in_level.toLocaleString()} / {xpLevelTotal.toLocaleString()} XP
                    </p>
                  </div>
                ) : null}
              </div>

              {/* Features — Inform and Connect shown for all tiers */}
              <div className={`bg-white dark:bg-gray-900 rounded-2xl border p-4 space-y-5 ${
                profile.tier === 'inform'
                  ? 'border-ev-yellow/50 dark:border-ev-yellow/20'
                  : 'border-gray-200 dark:border-gray-800'
              }`}>
                <h2 className="text-sm font-semibold text-gray-900 dark:text-white">Empowered Vote Features</h2>

                {/* Inform — always full access */}
                <div className="rounded-xl bg-ev-inform-section/40 dark:bg-ev-inform-section/8 p-3">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="w-2 h-2 rounded-full bg-ev-yellow flex-shrink-0" />
                    <span className="text-xs font-semibold text-gray-600 dark:text-ev-yellow uppercase tracking-widest">Inform</span>
                  </div>
                  <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(auto-fill, 15rem)' }}>
                    {INFORM_FEATURES.map((f) => (
                      <FeatureTile
                        key={f.name}
                        feature={f}
                        href={accessToken ? `${f.href}#access_token=${accessToken}` : f.href}
                        dotClass="bg-ev-yellow"
                        borderHover="hover:border-ev-yellow/50"
                        {...sharedTileProps}
                      />
                    ))}
                  </div>
                </div>

                {/* Connect — full access for Connected+, observe for Inform */}
                <div className="rounded-xl bg-ev-connect-section/40 dark:bg-ev-connect-section/8 p-3">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="w-2 h-2 rounded-full bg-ev-blue flex-shrink-0" />
                    <span className="text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-widest">Connect</span>
                    {!cp && (
                      <span className="text-[10px] font-semibold border px-2 py-0.5 rounded-full bg-ev-yellow border-ev-yellow text-ev-black dark:bg-ev-yellow/10 dark:border-ev-yellow/50 dark:text-ev-yellow">Observe Access</span>
                    )}
                  </div>
                  {!cp && (
                    <p className="text-xs text-gray-600 dark:text-gray-500 mb-3 leading-relaxed">
                      You can browse the below features as an <span className="text-yellow-700 dark:text-ev-yellow font-semibold">observer</span>, but must first <a href="/signup" className="text-ev-teal dark:text-ev-teal-light font-medium hover:underline">authenticate your identity in order to Connect your Account</a>. This unlocks social features, with members able to vote on our internal deliberations.
                    </p>
                  )}
                  <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(auto-fill, 15rem)' }}>
                    <FeatureTile
                      feature={CONNECT_FEATURES[0]}
                      href={accessToken ? `${CONNECT_FEATURES[0].href}#access_token=${accessToken}` : CONNECT_FEATURES[0].href}
                      dotClass="bg-ev-blue"
                      borderHover="hover:border-ev-blue/50"
                      locked={!cp}
                      {...sharedTileProps}
                    />
                    {cp ? (
                      <CivicSpacesTile
                        accessToken={accessToken}
                        city={city}
                        showForm={showLocationForm}
                        onToggleForm={() => setShowLocationForm((v) => !v)}
                        address={address}
                        onAddressChange={setAddress}
                        onSubmit={handleSetLocation}
                        locationLoading={locationLoading}
                        locationSuccess={locationSuccess}
                        locationError={locationError}
                      />
                    ) : (
                      <FeatureTile
                        feature={{ name: 'Civic Spaces', description: 'Engage with your local civic community online.', href: 'https://civicspaces.empowered.vote' }}
                        href={accessToken ? `https://civicspaces.empowered.vote#access_token=${accessToken}` : 'https://civicspaces.empowered.vote'}
                        dotClass="bg-ev-blue"
                        borderHover="hover:border-ev-blue/50"
                        locked={!cp}
                        {...sharedTileProps}
                      />
                    )}
                    {CONNECT_FEATURES.slice(1).map((f) => (
                      <FeatureTile
                        key={f.name}
                        feature={f}
                        href={accessToken ? `${f.href}#access_token=${accessToken}` : f.href}
                        dotClass="bg-ev-blue"
                        borderHover="hover:border-ev-blue/50"
                        locked={!cp}
                        {...sharedTileProps}
                      />
                    ))}
                  </div>
                </div>
              </div>

              {profile.tier === 'inform' && (
                <div className="text-center py-4 space-y-1.5">
                  <p className="text-xs text-gray-500 dark:text-gray-600">
                    Ready to participate? Connect your account when you are —
                  </p>
                  <button
                    type="button"
                    onClick={() => setExplainerOpen(true)}
                    className="text-xs text-ev-teal dark:text-ev-teal-light hover:underline font-medium"
                  >
                    Learn about Connected Accounts →
                  </button>
                </div>
              )}

            </div>
          )}

          {/* ── LOCATION TAB ─────────────────────────────────────────────────── */}
          {activeTab === 'location' && (
            <div className="space-y-6 max-w-lg">
              {/* Legislative districts */}
              {districts && (
                <div className="space-y-3">
                  <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">Your districts</h3>
                  <div className="space-y-2">
                    {districts.ca_assembly && (
                      <div>
                        <p className="text-xs font-medium text-gray-500 dark:text-gray-400">CA Assembly</p>
                        <p className="text-sm text-gray-800 dark:text-gray-200">
                          District {districts.ca_assembly.district_number}
                          {districts.ca_assembly.name ? ` — ${districts.ca_assembly.name}` : ''}
                        </p>
                      </div>
                    )}
                    {districts.ca_senate && (
                      <div>
                        <p className="text-xs font-medium text-gray-500 dark:text-gray-400">CA Senate</p>
                        <p className="text-sm text-gray-800 dark:text-gray-200">
                          District {districts.ca_senate.district_number}
                          {districts.ca_senate.name ? ` — ${districts.ca_senate.name}` : ''}
                        </p>
                      </div>
                    )}
                    {districts.us_house && (
                      <div>
                        <p className="text-xs font-medium text-gray-500 dark:text-gray-400">US House</p>
                        <p className="text-sm text-gray-800 dark:text-gray-200">
                          District {districts.us_house.district_number}
                          {districts.us_house.name ? ` — ${districts.us_house.name}` : ''}
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* City Council — sourced from /account/me jurisdiction, not TIGER cache */}
              {profile.jurisdiction?.city_council_district_name && (
                <div>
                  <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">City Council</h3>
                  <p className="text-sm text-gray-800 dark:text-gray-200 mt-1">
                    {profile.jurisdiction.city_council_district_name}
                  </p>
                </div>
              )}

              {/* School district — hidden entirely when no school rows (SchoolDistrictSection returns null) */}
              <SchoolDistrictSection data={schoolDistrict} />

              {/* Saved location summary */}
              {(city || profile.inform_profile?.last_essentials_location != null) && (
                <div>
                  <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-1">Saved location</h3>
                  {city && (
                    <p className="text-sm text-gray-800 dark:text-gray-200">{city}</p>
                  )}
                  {profile.inform_profile?.last_essentials_location != null && !city && (
                    <p className="text-xs text-gray-500 dark:text-gray-400">Last Essentials search location on file</p>
                  )}
                </div>
              )}

              {/* Location recalibration — Connected tier only */}
              {cp && (
                <div className="pt-4 border-t border-gray-200 dark:border-gray-800">
                  <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-3">Update your location</h3>
                  <form onSubmit={handleSetLocation} className="space-y-1.5">
                    <div className="flex gap-2">
                      <input
                        type="text"
                        value={address}
                        onChange={(e) => setAddress(e.target.value)}
                        placeholder="Enter your address"
                        className="flex-1 bg-gray-100 dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-lg px-3 py-2 text-sm text-gray-900 dark:text-gray-100 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-ev-teal-light"
                      />
                      <button
                        type="submit"
                        disabled={address.trim().length === 0 || locationLoading}
                        className="bg-ev-teal-light text-white text-sm font-medium px-4 py-2 rounded-lg disabled:opacity-50 hover:bg-ev-teal transition-colors"
                      >
                        {locationLoading ? 'Setting…' : 'Set'}
                      </button>
                    </div>
                    {locationSuccess && <p className="text-xs text-green-400 mt-1.5">Updated!</p>}
                    {locationError && <p className="text-xs text-ev-red mt-1.5">{locationError}</p>}
                  </form>
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
                  <p className="text-sm text-gray-400">Loading…</p>
                ) : (
                  <>
                    <div className="flex items-center gap-2">
                      <span className="text-3xl font-bold text-white tabular-nums">{inviteesData.active_count}</span>
                      <span className="text-gray-400 text-sm">/ {inviteesData.cap >= 2147483647 ? 'Unlimited' : inviteesData.cap} active invitees</span>
                    </div>
                    {inviteesData.cap === 0 ? (
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 rounded-xl bg-gray-800 flex items-center justify-center flex-shrink-0 text-gray-400">
                          <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" /></svg>
                        </div>
                        <div>
                          <p className="text-white font-semibold">Reach level 2 to start inviting</p>
                          <p className="text-gray-400 text-sm mt-1">Keep earning XP to unlock your first invite slot.</p>
                        </div>
                      </div>
                    ) : inviteesData.can_generate ? (
                      <div className="space-y-2">
                        <input type="text" value={labelInput} onChange={(e) => setLabelInput(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter' && !generatingCode) handleGenerate(); }} placeholder="Who is this for? (optional)" maxLength={50} className="w-full px-3 py-2.5 text-sm border border-gray-700 rounded-xl bg-gray-800 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-teal/30 focus:border-ev-teal transition-colors"/>
                        <button onClick={handleGenerate} disabled={generatingCode} className="w-full py-2.5 px-4 bg-ev-teal text-white rounded-xl text-sm font-semibold hover:bg-ev-teal/90 transition-colors disabled:opacity-50">{generatingCode ? 'Generating…' : 'Generate Invite Code'}</button>
                      </div>
                    ) : (
                      <p className="text-xs text-gray-500 leading-relaxed">All invite slots filled. Level up to earn more, or wait for an invitee to reach level 2.</p>
                    )}
                    {inviteesData.invitees.some((i) => i.status === 'pending') && (
                      <div className="border-t border-gray-800 -mx-5 px-5 pt-4">
                        <p className="text-xs font-medium text-gray-400 mb-2">Pending Codes</p>
                        <div className="space-y-2">
                          {inviteesData.invitees.filter((i) => i.status === 'pending').map((entry) => (
                            <button key={entry.code} onClick={() => copyPendingCode(entry.code)} className="w-full flex items-center justify-between bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 hover:border-ev-teal-light/50 transition-colors">
                              <div className="flex items-center gap-3 min-w-0">
                                {entry.label && (
                                  <span className="text-sm text-gray-300 truncate">{entry.label}</span>
                                )}
                                <span className="font-mono text-base font-bold tracking-widest text-white flex-shrink-0">{entry.code}</span>
                              </div>
                              <span className="text-xs font-medium text-ev-teal-light ml-3 flex-shrink-0">{copiedCode === entry.code ? 'Copied!' : 'Copy'}</span>
                            </button>
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
                                  <p className={`text-sm font-medium truncate ${invitee.graduated ? 'text-gray-400' : 'text-white'}`}>{invitee.display_name ?? invitee.label ?? '—'}</p>
                                  <div className="flex items-center gap-2 flex-shrink-0">
                                    {invitee.graduated ? <span className="text-xs font-medium text-ev-teal bg-ev-teal/10 px-2 py-0.5 rounded-full">Graduated ✓</span>
                                      : invitee.account_standing === 'suspended' ? <span className="text-xs font-medium text-ev-red bg-ev-red/10 px-2 py-0.5 rounded-full">Suspended</span>
                                      : <span className="flex items-center gap-1 text-xs text-gray-500"><span className="w-1.5 h-1.5 rounded-full bg-green-400" />Active</span>}
                                    {isLocked && <span className="text-xs font-medium text-ev-red bg-ev-red/10 px-2 py-0.5 rounded-full">Slot locked</span>}
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
            <div className="max-w-2xl"><PostHistory /></div>
          )}

          {/* ── CONTRIBUTOR TAB ──────────────────────────────────────────────── */}
          {activeTab === 'contributor' && cp && (
            <div className="max-w-2xl space-y-4">
              <div className="bg-gray-900 rounded-2xl border border-gray-800 p-5">
                <p className="text-xs text-gray-500 uppercase tracking-widest font-medium mb-4">Contributor Roles</p>
                {roles.length === 0 ? (
                  <div className="space-y-1">
                    <p className="text-sm text-gray-400">No contributor roles assigned yet.</p>
                    <p className="text-xs text-gray-600">Roles are granted by the Empowered Vote team.</p>
                  </div>
                ) : (
                  <div className="divide-y divide-gray-800">
                    {roles.map((role) => {
                      const meta = ROLE_META[role.slug];
                      // Plain link, no token in the fragment. These point at
                      // app.empowered.vote, which shares the ev_session cookie
                      // with this app and resolves its own session on load.
                      // Handing it a token in the URL is what made a fragment
                      // token accepted there, and an accepted fragment token
                      // lets any link choose who the visitor is signed in as.
                      const toolHref = meta ? meta.href : null;
                      return (
                        <div key={role.id} className="py-4 first:pt-0 last:pb-0 space-y-1">
                          <div className="flex items-start justify-between gap-3">
                            <div className="space-y-0.5 min-w-0">
                              <p className="text-sm font-semibold text-white">{role.name}</p>
                              <p className="text-xs text-gray-400">
                                {meta?.description ?? role.feature_scope}
                              </p>
                              {role.jurisdiction_geoid && (
                                <p className="text-[11px] text-gray-600">
                                  Jurisdiction: {role.jurisdiction_geoid}
                                </p>
                              )}
                              <p className="text-[11px] text-gray-600 tabular-nums">
                                Granted {new Date(role.granted_at).toLocaleDateString(undefined, { month: 'long', day: 'numeric', year: 'numeric' })}
                                {role.granted_by_display_name && ` by ${role.granted_by_display_name}`}
                              </p>
                            </div>
                            {toolHref && (
                              <a
                                href={toolHref}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex-shrink-0 text-xs text-ev-teal-light hover:text-white border border-ev-teal-light/30 hover:border-ev-teal-light px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap"
                              >
                                Open tool →
                              </a>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>
          )}

        </div>
      )}

      <ConnectedExplainerModal open={explainerOpen} onClose={() => setExplainerOpen(false)} tier={profile?.tier === 'connected' ? 'connect' : profile?.tier === 'empowered' ? 'empower' : profile?.tier} />
    </div>
  );
}
