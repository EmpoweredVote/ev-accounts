import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { apiFetch } from '../lib/api';

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
  tier: 'inform' | 'connected' | 'empowered';
  is_admin: boolean;
  verification_rating: number;
  location_consent: boolean;
  gems?: MeGems;
  connected_profile?: MeConnectedProfile;
}

const FEATURES = [
  {
    name: 'Civic Trivia Championships',
    abbr: 'CTC',
    description: 'Test your knowledge of where politicians really stand on the issues.',
    color: 'bg-ev-teal',
    href: 'https://ctc.empowered.vote',
  },
  {
    name: 'Validation Quests',
    abbr: 'VQ',
    description: 'Help verify politician stances and earn Red Gems for accuracy.',
    color: 'bg-ev-red',
    href: 'https://quests.empowered.vote',
  },
  {
    name: 'Essentials',
    abbr: 'ESS',
    description: 'Find out who represents you.',
    color: 'bg-ev-yellow',
    href: 'https://essentials.empowered.vote',
  },
  {
    name: 'Read & Rank',
    abbr: 'R&R',
    description: "It's like a blind taste test, where we put your opinion above either political party.",
    color: 'bg-ev-teal-light',
    href: 'https://readrank.empowered.vote',
  },
  {
    name: 'Empowered Compass',
    abbr: 'EC',
    description: 'See how your values align with politicians and candidates on the issues.',
    color: 'bg-ev-yellow',
    href: 'https://compass.empowered.vote',
  },
  {
    name: 'Treasury Tracker',
    abbr: 'TT',
    description: 'Follow the money — see how public funds are allocated and spent.',
    color: 'bg-gray-700',
    href: 'https://treasurytracker.netlify.app/',
  },
] as const;

const TIER_LABELS: Record<string, string> = {
  inform: 'Inform',
  connected: 'Connected',
  empowered: 'Empowered',
};

const TIER_BADGE_CLASS: Record<string, string> = {
  inform: 'bg-gray-100 text-gray-700',
  connected: 'bg-ev-teal/10 text-ev-teal',
  empowered: 'bg-ev-red/10 text-ev-red',
};

function GemPip({
  count,
  color,
  label,
}: {
  count: number;
  color: string;
  label: string;
}) {
  return (
    <div className="flex items-center gap-1.5">
      <span className={`inline-block w-3 h-3 rounded-full ${color}`} />
      <span className="text-sm text-gray-700 font-medium">{count}</span>
      <span className="text-xs text-gray-400">{label}</span>
    </div>
  );
}

export default function ProfilePage() {
  const navigate = useNavigate();
  const { user, clearAuth } = useAuthStore();
  const [profile, setProfile] = useState<MeResponse | null>(null);
  const [profileError, setProfileError] = useState(false);

  const [address, setAddress] = useState('');
  const [locationLoading, setLocationLoading] = useState(false);
  const [locationSuccess, setLocationSuccess] = useState(false);
  const [locationError, setLocationError] = useState<string | null>(null);

  useEffect(() => {
    apiFetch<MeResponse>('/account/me')
      .then((data) => setProfile(data))
      .catch(() => setProfileError(true));
  }, []);

  useEffect(() => {
    if (locationSuccess) {
      const timer = setTimeout(() => setLocationSuccess(false), 5000);
      return () => clearTimeout(timer);
    }
  }, [locationSuccess]);

  async function handleSignOut() {
    try {
      await apiFetch('/auth/logout', { method: 'POST' });
    } catch {
      // Ignore errors — clear client state regardless
    }
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
      await apiFetch('/connect/set-location', {
        method: 'POST',
        body: JSON.stringify({ address: address.trim() }),
      });
      setLocationSuccess(true);
      setAddress('');
    } catch (err: any) {
      setLocationError(err.message || 'Failed to set location');
    } finally {
      setLocationLoading(false);
    }
  }

  const displayEmail = profile?.email ?? user?.email ?? '';
  const displayTier = profile?.tier ?? user?.tier ?? 'inform';
  const initials = displayEmail.slice(0, 2).toUpperCase();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Nav bar */}
      <nav className="bg-white border-b border-gray-200 px-6 py-3 flex items-center justify-between">
        <span className="font-semibold text-gray-900">Empowered Vote</span>
        <button
          onClick={handleSignOut}
          className="text-sm text-gray-500 hover:text-gray-800 transition-colors"
        >
          Sign out
        </button>
      </nav>

      <div className="max-w-2xl mx-auto px-4 py-10">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          {/* Avatar + email */}
          <div className="flex items-center gap-4 mb-6">
            <div className="w-14 h-14 rounded-full bg-ev-teal flex items-center justify-center text-white font-bold text-lg flex-shrink-0">
              {initials}
            </div>
            <div className="min-w-0">
              <p className="text-sm text-gray-500 truncate">{displayEmail}</p>
              <span
                className={`inline-block mt-1 px-2 py-0.5 rounded-full text-xs font-semibold ${TIER_BADGE_CLASS[displayTier]}`}
              >
                {TIER_LABELS[displayTier] ?? displayTier}
              </span>
            </div>
          </div>

          {/* Admin Panel link — only for admin users */}
          {user?.isAdmin && (
            <div className="mb-5">
              <Link
                to="/admin"
                className="inline-flex items-center gap-2 px-4 py-2 bg-ev-red text-white text-sm font-medium rounded-md hover:bg-ev-red/90 transition-colors"
              >
                Admin Panel
              </Link>
            </div>
          )}

          {/* Profile data */}
          {profile && !profileError && (
            <div className="space-y-4">
              {/* Level + XP — Connected and above */}
              {profile.connected_profile != null && (
                <div className="flex items-center gap-4">
                  <div className="text-center">
                    <p className="text-2xl font-bold text-gray-900">
                      {profile.connected_profile.xp.level}
                    </p>
                    <p className="text-xs text-gray-500">Level</p>
                  </div>
                  <div className="text-center">
                    <p className="text-2xl font-bold text-gray-900">
                      {profile.connected_profile.xp.total.toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-500">XP</p>
                  </div>
                </div>
              )}

              {/* Gems — Connected and above */}
              {profile.connected_profile != null && (
                <div className="pt-3 border-t border-gray-100">
                  <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                    Gems
                  </p>
                  <div className="flex gap-4">
                    <GemPip
                      count={profile.connected_profile.gems.yellow ?? 0}
                      color="bg-ev-yellow"
                      label="Yellow"
                    />
                    <GemPip
                      count={profile.connected_profile.gems.blue ?? 0}
                      color="bg-blue-500"
                      label="Blue"
                    />
                    <GemPip
                      count={profile.connected_profile.gems.red ?? 0}
                      color="bg-ev-red"
                      label="Red"
                    />
                  </div>
                </div>
              )}

              {/* Verification Rating — Connected and above */}
              {profile.connected_profile != null && (
                <div className="pt-3 border-t border-gray-100">
                  <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                    Verification Rating
                  </p>
                  <div className="flex items-baseline gap-1.5">
                    <p className="text-2xl font-bold text-gray-900">
                      {profile.connected_profile.verification_rating}
                    </p>
                    <span className="text-sm text-gray-400">/ 150</span>
                  </div>
                  {profile.connected_profile.vq_hold_active && (
                    <p className="text-xs text-ev-red mt-1">VQ hold active</p>
                  )}
                </div>
              )}

              {/* Location form — Connected and above */}
              {profile.connected_profile != null && (
                <div className="pt-4 border-t border-gray-100">
                  <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                    Location
                  </p>
                  {profile.location_consent && (
                    <p className="text-sm text-green-600 mb-2 flex items-center gap-1">
                      <span>&#10003;</span> Location set
                    </p>
                  )}
                  <form onSubmit={handleSetLocation} className="space-y-2">
                    <input
                      type="text"
                      value={address}
                      onChange={(e) => setAddress(e.target.value)}
                      placeholder="Enter your address"
                      className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
                    />
                    <button
                      type="submit"
                      disabled={address.trim().length === 0 || locationLoading}
                      className="bg-ev-teal text-white text-sm font-medium px-4 py-2 rounded-md hover:bg-ev-teal/90 disabled:opacity-50"
                    >
                      {locationLoading ? 'Setting...' : 'Set Location'}
                    </button>
                  </form>
                  {locationSuccess && (
                    <p className="text-sm text-green-600 mt-2">Location updated successfully</p>
                  )}
                  {locationError && (
                    <p className="text-sm text-ev-red mt-2">{locationError}</p>
                  )}
                </div>
              )}
            </div>
          )}

          {profileError && (
            <p className="text-sm text-gray-400 italic">
              Could not load profile details. Try refreshing.
            </p>
          )}
        </div>

        {/* Feature hub — visible to all tiers */}
        <div className="mt-8" data-testid="feature-hub">
          <h2 className="text-lg font-semibold text-gray-900 mb-1">
            Empowered Vote Features
          </h2>
          <p className="text-sm text-gray-500 mb-4">
            Explore freely. Connect to save your progress.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {FEATURES.map((feature) => (
              <a
                key={feature.abbr}
                href={feature.href}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition-shadow block"
              >
                <div className="flex items-center gap-2">
                  <span className={`w-2.5 h-2.5 rounded-full flex-shrink-0 ${feature.color}`} />
                  <span className="text-sm font-semibold text-gray-900">{feature.name}</span>
                </div>
                <p className="text-xs text-gray-500 mt-1.5 leading-relaxed">
                  {feature.description}
                </p>
                <p className="text-xs text-ev-teal font-medium mt-2">Explore &rarr;</p>
              </a>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
