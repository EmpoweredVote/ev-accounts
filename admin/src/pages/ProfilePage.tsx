import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { apiFetch } from '../lib/api';

interface GemBalances {
  yellow: number;
  blue: number;
  red: number;
}

interface OwnerProfile {
  username: string;
  tier: 'inform' | 'connected' | 'empowered';
  level: number | null;
  total_xp: number | null;
  email: string;
  gem_balances: GemBalances;
  location_consent: boolean;
}

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
  const [profile, setProfile] = useState<OwnerProfile | null>(null);
  const [profileError, setProfileError] = useState(false);

  useEffect(() => {
    apiFetch<OwnerProfile>('/account/profile/me')
      .then((data) => setProfile(data))
      .catch(() => setProfileError(true));
  }, []);

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

      <div className="max-w-lg mx-auto px-4 py-10">
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
              {profile.level != null && (
                <div className="flex items-center gap-4">
                  <div className="text-center">
                    <p className="text-2xl font-bold text-gray-900">{profile.level}</p>
                    <p className="text-xs text-gray-500">Level</p>
                  </div>
                  {profile.total_xp != null && (
                    <div className="text-center">
                      <p className="text-2xl font-bold text-gray-900">
                        {profile.total_xp.toLocaleString()}
                      </p>
                      <p className="text-xs text-gray-500">XP</p>
                    </div>
                  )}
                </div>
              )}

              {/* Gems — Connected and above */}
              {(profile.tier === 'connected' || profile.tier === 'empowered') && (
                <div className="pt-3 border-t border-gray-100">
                  <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                    Gems
                  </p>
                  <div className="flex gap-4">
                    <GemPip
                      count={profile.gem_balances.yellow}
                      color="bg-ev-yellow"
                      label="Yellow"
                    />
                    <GemPip count={profile.gem_balances.blue} color="bg-blue-500" label="Blue" />
                    <GemPip count={profile.gem_balances.red} color="bg-ev-red" label="Red" />
                  </div>
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
      </div>
    </div>
  );
}
