import { useEffect, useState, useCallback } from 'react';
import { apiFetch } from '../lib/api';
import { AppNav } from '../components/AppNav';

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

const GEM_IMAGES: Record<string, string> = {
  Yellow: '/Yellow_Gem.png',
  Blue: '/Blue_Gem.png',
  Red: '/Red_Gem.png',
};

function GemTile({ label, count }: { label: string; count: number }) {
  const src = GEM_IMAGES[label];
  return (
    <div className="flex flex-col items-center gap-2">
      <div className="w-16 h-16 flex items-center justify-center">
        {src ? (
          <img src={src} alt={`${label} Gem`} className="w-full h-full object-contain" />
        ) : (
          <div className="w-16 h-16 rounded-full bg-gray-700" />
        )}
      </div>
      <span className="text-white text-xl font-bold tabular-nums">{count.toLocaleString()}</span>
    </div>
  );
}

function titleCase(str: string): string {
  return str
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

export default function ProfilePage() {
  const [me, setMe] = useState<MeFull | null>(null);
  const [referral, setReferral] = useState<ReferralState | null>(null);
  const [activity, setActivity] = useState<ActivityEntry[]>([]);
  const [copied, setCopied] = useState(false);

  // Fetch /account/me on mount
  useEffect(() => {
    apiFetch<MeFull>('/account/me').then(setMe).catch(() => {});
  }, []);

  // When connected_profile is present, fetch /referral and /account/me/activity
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

  if (!me) {
    return (
      <div className="bg-ev-navy min-h-screen">
        <AppNav />
      </div>
    );
  }

  const cp = me.connected_profile;
  const xp = cp?.xp ?? null;
  const xpPercent = xp && xp.xp_to_next_level > 0
    ? Math.min(100, Math.round((xp.xp_in_level / xp.xp_to_next_level) * 100))
    : 0;

  return (
    <div className="bg-ev-navy min-h-screen">
      <AppNav />
      <main className="max-w-lg mx-auto px-4 py-6 space-y-4">

        {/* Header card — display name + level badge + XP bar */}
        <div className="bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-4">
          <div className="flex items-start justify-between gap-3">
            <h1 className="text-3xl font-bold text-white">
              {me.display_name ?? 'Member'}
            </h1>
            {cp && xp && (
              <span className="bg-ev-teal-light/15 text-ev-teal-light px-2 py-0.5 rounded-full text-xs font-semibold flex-shrink-0 mt-1">
                Level {xp.level}
              </span>
            )}
          </div>

          {cp && xp && (
            <div className="space-y-1.5">
              <p className="text-sm text-gray-400 tabular-nums">
                Level {xp.level} — {xp.xp_in_level.toLocaleString()} / {xp.xp_to_next_level.toLocaleString()} XP
              </p>
              <div className="h-2 rounded-full bg-gray-800 overflow-hidden">
                <div
                  className="bg-ev-teal-light h-full rounded-full transition-all duration-700"
                  style={{ width: `${xpPercent}%` }}
                />
              </div>
            </div>
          )}
        </div>

        {/* Gems card */}
        {cp && (
          <div className="bg-gray-900 rounded-2xl border border-gray-800 p-6">
            <div className="flex justify-around items-end gap-4">
              <GemTile label="Yellow" count={cp.gems.yellow} />
              <GemTile label="Blue" count={cp.gems.blue} />
              <GemTile label="Red" count={cp.gems.red} />
            </div>
          </div>
        )}

        {/* Recent Activity card */}
        {cp && (
          <div className="bg-gray-900 rounded-2xl border border-gray-800 p-6">
            <h2 className="text-white text-lg font-semibold mb-4">Recent Activity</h2>
            {activity.length === 0 ? (
              <p className="text-gray-400 text-sm">
                No XP earned yet — explore an Empowered Vote feature to get started.
              </p>
            ) : (
              <ul className="divide-y divide-gray-800">
                {activity.slice(0, 4).map((entry, i) => (
                  <li key={i} className="flex items-center justify-between py-3 first:pt-0 last:pb-0">
                    <div>
                      <p className="text-white text-sm font-medium">{titleCase(entry.description)}</p>
                      <p className="text-xs text-gray-400 mt-0.5">
                        {new Date(entry.created_at).toLocaleDateString(undefined, {
                          month: 'short',
                          day: 'numeric',
                          year: 'numeric',
                        })}
                      </p>
                    </div>
                    <span className="text-ev-teal-light font-semibold tabular-nums text-sm ml-4">
                      +{entry.amount} XP
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}

        {/* Invite card */}
        {cp && (
          <div className="bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-3">
            <h2 className="text-white text-lg font-semibold">Your Invite Code</h2>
            {!referral?.unlocked ? (
              <p className="text-gray-400 text-sm">
                Reach level 2 to unlock your first referral code
              </p>
            ) : referral.code ? (
              <div className="bg-gray-800 rounded-xl px-4 py-3 flex items-center justify-between">
                <code className="font-mono text-ev-teal-light text-2xl tracking-widest">
                  {referral.code}
                </code>
                <button
                  onClick={copyCode}
                  className="text-sm text-ev-teal-light hover:text-white transition-colors ml-4"
                >
                  {copied ? 'Copied!' : 'Copy'}
                </button>
              </div>
            ) : null}
          </div>
        )}

        {/* Verification Rating card */}
        {cp && (
          <div className="bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-2">
            <h2 className="text-white text-lg font-semibold">Verification Rating</h2>
            <p className="text-white text-2xl font-bold tabular-nums">
              {cp.verification_rating} / 150
            </p>
            <p className="text-sm text-gray-400">
              Your VR reflects how reliably you participate in civic verification. Earn more by completing Validation Quests.
            </p>
          </div>
        )}

      </main>
    </div>
  );
}
