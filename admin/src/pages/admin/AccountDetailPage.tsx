import React, { useEffect, useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router';
import { apiFetch } from '../../lib/api';
import { RolesTab } from '../../components/RolesTab';
import type { Role } from '../../components/RolesTab';

// Role interface imported from RolesTab component

interface CalibrationStatus {
  days_since_last_calibration: number | null;
  overdue_topics: string[];
  is_at_risk: boolean;
}

interface ConnectedProfile {
  user_id: string;
  account_standing: string;
  verification_status: string;
  legal_name: string | null;
  tolerance_rating: number | null;
  verification_rating: number;
  vq_hold_until: string | null;
  total_xp: number;
  current_level: number;
  gem_balance_yellow: number;
  gem_balance_blue: number;
  gem_balance_red: number;
  completed_onboarding: boolean;
  created_at: string;
  invite_cap_override: number | null;
}

interface XpTransaction {
  id: string;
  source: string;
  amount: number;
  metadata: Record<string, unknown> | null;
  created_at: string;
}

interface XpHistoryResponse {
  transactions: XpTransaction[];
  total: number;
  page: number;
  pages: number;
}

interface AccountDetail {
  id: string;
  display_name: string;
  email: string;
  tier: string;
  account_standing: string;
  created_at: string;
  // Admin-only fields
  legal_name: string | null;
  tolerance_rating: number | null;
  // Connected profile (present for connected + empowered tiers)
  connected_profile: ConnectedProfile | null;
  // Roles
  roles: Role[];
  // Invite chain
  invited_by: { id: string; display_name: string } | null;
  invited_users: Array<{ id: string; display_name: string }>;
  // Calibration (Empowered only)
  calibration_status: CalibrationStatus | null;
}

// Profile endpoint shapes (GET /api/account/profile/:userId)
interface CompassAnswer {
  topic_id: string;
  value: number;
  write_in_text: string | null;
  inverted: boolean;
  updated_at: string;
}

interface EmpoweredProfile {
  legal_name: string | null;
  candidate_page_slug: string | null;
  is_active: boolean;
  empowered_at: string | null;
  demoted_at: string | null;
  [key: string]: unknown;
}

interface ProfileData {
  username: string;
  tier: string;
  level: number | null;
  total_xp: number | null;
  selected_topic_ids?: string[];
  compass_answers?: CompassAnswer[];
  empowered_profile?: EmpoweredProfile;
}

// Promotion history shapes
interface PromotionEntry {
  id: string;
  admin_id: string;
  admin_email: string;
  target_user_id: string;
  previous_tier: string;
  new_tier: string;
  note: string | null;
  created_at: string;
}

interface PromotionHistoryResponse {
  entries: PromotionEntry[];
  total: number;
  page: number;
  pages: number;
}

const TIER_BADGE: Record<string, string> = {
  inform: 'bg-gray-100 text-gray-700',
  connected: 'bg-blue-100 text-blue-700',
  empowered: 'bg-green-100 text-green-700',
};

const STANDING_BADGE: Record<string, string> = {
  active: 'bg-green-100 text-green-700',
  suspended: 'bg-red-100 text-red-700',
};

function getInviteCapForLevel(level: number): number {
  if (level <= 1) return 0;
  if (level <= 5) return 3;
  if (level <= 10) return 5;
  if (level <= 20) return 10;
  return 15;
}

export function AccountDetailPage() {
  const { userId } = useParams<{ userId: string }>();
  const navigate = useNavigate();
  const [account, setAccount] = useState<AccountDetail | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionError, setActionError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [showDemoteConfirm, setShowDemoteConfirm] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);

  // XP History state
  const [xpData, setXpData] = useState<XpHistoryResponse | null>(null);
  const [xpError, setXpError] = useState<string | null>(null);
  const [xpLoading, setXpLoading] = useState(false);
  const [xpPage, setXpPage] = useState(1);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  // Profile data state (compass, empowered profile)
  const [profileData, setProfileData] = useState<ProfileData | null>(null);

  // Promotion history state
  const [promotionData, setPromotionData] = useState<PromotionHistoryResponse | null>(null);
  const [promotionHistoryError, setPromotionHistoryError] = useState<string | null>(null);
  const [promotionHistoryLoading, setPromotionHistoryLoading] = useState(false);
  const [promotionPage, setPromotionPage] = useState(1);

  // Promotion flow state
  const [showPromoteModal, setShowPromoteModal] = useState(false);
  const [promoteNote, setPromoteNote] = useState('');
  const [promotionLoading, setPromotionLoading] = useState(false);
  const [promotionSuccess, setPromotionSuccess] = useState<string | null>(null);

  // VR edit state
  const [vrEditMode, setVrEditMode] = useState(false);
  const [vrDraft, setVrDraft] = useState<{ rating: number; clearHold: boolean }>({ rating: 0, clearHold: false });
  const [vrSaving, setVrSaving] = useState(false);
  const [vrError, setVrError] = useState<string | null>(null);

  // Invite cap override state
  const [inviteCapOverride, setInviteCapOverride] = useState<string>('');
  const [inviteCapSaving, setInviteCapSaving] = useState(false);
  const [inviteCapMsg, setInviteCapMsg] = useState<string | null>(null);

  function fetchAccount() {
    setLoading(true);
    apiFetch<AccountDetail>(`/admin/accounts/${userId}`)
      .then(setAccount)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    if (userId) fetchAccount();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId]);

  // Fetch profile data (compass + empowered profile)
  useEffect(() => {
    if (!userId) return;
    apiFetch<ProfileData>(`/account/profile/${userId}`)
      .then(setProfileData)
      .catch(() => {
        // Non-fatal: profile data unavailable
        setProfileData(null);
      });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId]);

  // Fetch XP history
  useEffect(() => {
    if (!userId || !account?.connected_profile) return;
    setXpLoading(true);
    setXpError(null);
    apiFetch<XpHistoryResponse>(`/admin/accounts/${userId}/xp-history?page=${xpPage}`)
      .then(setXpData)
      .catch((err) => setXpError(err.message))
      .finally(() => setXpLoading(false));
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId, xpPage, account?.connected_profile]);

  // Fetch promotion history
  useEffect(() => {
    if (!userId) return;
    setPromotionHistoryLoading(true);
    setPromotionHistoryError(null);
    apiFetch<PromotionHistoryResponse>(`/admin/accounts/${userId}/promotion-history?page=${promotionPage}`)
      .then(setPromotionData)
      .catch((err) => setPromotionHistoryError(err.message))
      .finally(() => setPromotionHistoryLoading(false));
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId, promotionPage]);

  async function handleAction(action: 'suspend' | 'unsuspend' | 'demote') {
    setActionError(null);
    setActionLoading(true);
    try {
      await apiFetch(`/admin/accounts/${userId}/${action}`, { method: 'POST' });
      fetchAccount();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Action failed');
    } finally {
      setActionLoading(false);
      setShowDemoteConfirm(false);
    }
  }

  async function handlePromote() {
    setActionError(null);
    setPromotionLoading(true);
    try {
      await apiFetch(`/admin/accounts/${userId}/promote`, {
        method: 'POST',
        body: JSON.stringify({ note: promoteNote || undefined }),
      });
      setShowPromoteModal(false);
      setPromoteNote('');
      setPromotionSuccess('Account successfully promoted to Connected tier.');
      fetchAccount();
      // Refresh promotion history
      setPromotionPage(1);
      apiFetch<PromotionHistoryResponse>(`/admin/accounts/${userId}/promotion-history?page=1`)
        .then(setPromotionData)
        .catch(() => {});
      // Auto-clear success message after 5 seconds
      setTimeout(() => setPromotionSuccess(null), 5000);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Promotion failed';
      if (message.includes('409') || message.toLowerCase().includes('already')) {
        setActionError('User is already Connected or Empowered.');
      } else if (message.includes('404') || message.toLowerCase().includes('not found')) {
        setActionError('User not found.');
      } else {
        setActionError(message);
      }
    } finally {
      setPromotionLoading(false);
    }
  }

  async function handleVrSave() {
    if (!account?.connected_profile) return;
    const { rating, clearHold } = vrDraft;
    if (rating < 0 || rating > 150) return; // disabled state guard

    setVrSaving(true);
    setVrError(null);
    try {
      const body: Record<string, unknown> = {};
      if (rating !== account.connected_profile.verification_rating) body.verification_rating = rating;
      if (clearHold) body.clear_hold = true;

      if (Object.keys(body).length === 0) {
        setVrEditMode(false);
        return;
      }

      await apiFetch(`/admin/accounts/${userId}/verification-rating`, {
        method: 'PATCH',
        body: JSON.stringify(body),
      });
      setVrEditMode(false);
      fetchAccount();
    } catch (err) {
      setVrError(err instanceof Error ? err.message : 'Save failed');
    } finally {
      setVrSaving(false);
    }
  }

  async function handleDelete() {
    setDeleteLoading(true);
    setActionError(null);
    try {
      await apiFetch(`/admin/accounts/${userId}`, { method: 'DELETE' });
      navigate('/admin/accounts');
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Delete failed');
      setShowDeleteConfirm(false);
    } finally {
      setDeleteLoading(false);
    }
  }

  // Initialize invite cap override state when account loads
  useEffect(() => {
    if (account?.connected_profile) {
      setInviteCapOverride(account.connected_profile.invite_cap_override?.toString() ?? '');
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [account?.connected_profile?.invite_cap_override]);

  const handleSaveInviteCap = async () => {
    if (!userId) return;
    setInviteCapSaving(true);
    setInviteCapMsg(null);
    try {
      const cap = inviteCapOverride === '' ? null : parseInt(inviteCapOverride, 10);
      await apiFetch(`/admin/accounts/${userId}/invite-cap-override`, {
        method: 'POST',
        body: JSON.stringify({ cap }),
      });
      setInviteCapMsg('Override saved');
    } catch {
      setInviteCapMsg('Failed to save override');
    } finally {
      setInviteCapSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="animate-pulse space-y-4">
        <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-1/3"></div>
        <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6 space-y-3">
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/3"></div>
        </div>
      </div>
    );
  }

  if (error || !account) {
    return (
      <div className="p-4 bg-red-50 border border-red-200 rounded text-red-700 dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
        {error || 'Account not found'}
      </div>
    );
  }

  return (
    <div className="max-w-3xl">
      {/* Back link */}
      <Link to="/admin/accounts" className="text-sm text-blue-600 hover:text-blue-800 dark:text-ev-teal-light dark:hover:text-ev-teal-light/80 mb-4 inline-block">
        &larr; Back to Accounts
      </Link>

      {/* Promotion success toast */}
      {promotionSuccess && (
        <div className="mb-4 bg-green-50 border border-green-200 rounded p-3 text-green-700 text-sm dark:bg-green-950/40 dark:border-green-800/60 dark:text-green-400">
          {promotionSuccess}
        </div>
      )}

      {/* Profile header */}
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6 mb-4">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{account.display_name}</h1>
            <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">{account.email}</p>
            <p className="text-gray-400 dark:text-gray-500 text-xs mt-1">ID: {account.id}</p>
          </div>
          <div className="flex gap-2">
            <span className={`px-2 py-1 rounded-full text-xs font-medium capitalize ${TIER_BADGE[account.tier] ?? 'bg-gray-100 text-gray-700'}`}>
              {account.tier}
            </span>
            <span className={`px-2 py-1 rounded-full text-xs font-medium capitalize ${STANDING_BADGE[account.account_standing] ?? 'bg-gray-100 text-gray-700'}`}>
              {account.account_standing}
            </span>
          </div>
        </div>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-3">
          Joined {new Date(account.created_at).toLocaleDateString()}
        </p>
        {account.connected_profile && (
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            Level {account.connected_profile.current_level ?? 0}
            {' \u00b7 '}
            {(account.connected_profile.total_xp ?? 0).toLocaleString()} XP
          </p>
        )}
        {account.connected_profile && (
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            <span className="text-ev-yellow font-medium">Yellow: {account.connected_profile.gem_balance_yellow}</span>
            {' \u00b7 '}
            <span className="text-blue-500 font-medium">Blue: {account.connected_profile.gem_balance_blue}</span>
            {' \u00b7 '}
            <span className="text-ev-red font-medium">Red: {account.connected_profile.gem_balance_red}</span>
          </p>
        )}
      </div>

      {/* Admin-only sensitive fields */}
      <div className="bg-amber-50 border border-amber-200 rounded-lg p-6 mb-4 dark:bg-amber-950/20 dark:border-amber-800/40">
        <h2 className="text-sm font-semibold text-amber-800 dark:text-amber-200 uppercase tracking-wide mb-3">
          Admin-Only Fields
        </h2>
        <div className="space-y-2 text-sm">
          <div className="flex">
            <span className="w-36 font-medium text-amber-700 dark:text-amber-400">Legal Name:</span>
            <span className="text-amber-900 dark:text-amber-200">{account.legal_name ?? 'Not set'}</span>
          </div>
          <div className="flex">
            <span className="w-36 font-medium text-amber-700 dark:text-amber-400">Tolerance Rating:</span>
            <span className="text-amber-900 dark:text-amber-200">
              {account.tolerance_rating != null ? account.tolerance_rating.toFixed(2) : 'N/A'}
            </span>
          </div>

          {/* VR section — Connected and Empowered only */}
          {account.connected_profile && (
            <>
              <div className="pt-2 border-t border-amber-200 dark:border-amber-800/40 mt-2" />

              {/* Status badges (view and edit mode) */}
              <div className="flex gap-2 flex-wrap mb-1">
                {account.connected_profile.verification_rating >= 90 && (
                  <span className="px-2 py-0.5 rounded text-xs font-medium bg-ev-red/10 text-ev-red border border-ev-red/20">
                    Red Gems unlocked
                  </span>
                )}
                {account.connected_profile.vq_hold_until &&
                  new Date(account.connected_profile.vq_hold_until) > new Date() && (
                    <span className="px-2 py-0.5 rounded text-xs font-medium bg-orange-100 text-orange-700 border border-orange-200">
                      Hold active
                    </span>
                  )}
              </div>

              {!vrEditMode ? (
                /* View mode */
                <>
                  <div className="flex items-center">
                    <span className="w-36 font-medium text-amber-700 dark:text-amber-400">Verification Rating:</span>
                    <span className="text-amber-900 dark:text-amber-200 mr-3">{account.connected_profile.verification_rating}</span>
                    <button
                      onClick={() => {
                        setVrDraft({ rating: account.connected_profile!.verification_rating, clearHold: false });
                        setVrEditMode(true);
                        setVrError(null);
                      }}
                      className="text-xs text-blue-600 hover:text-blue-800 dark:text-ev-teal-light dark:hover:text-ev-teal-light/80"
                    >
                      Edit
                    </button>
                  </div>
                  <div className="flex">
                    <span className="w-36 font-medium text-amber-700 dark:text-amber-400">Hold Until:</span>
                    <span className="text-amber-900 dark:text-amber-200">
                      {account.connected_profile.vq_hold_until
                        ? new Date(account.connected_profile.vq_hold_until).toLocaleDateString()
                        : 'None'}
                    </span>
                  </div>
                </>
              ) : (
                /* Edit mode */
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <span className="w-36 font-medium text-amber-700 dark:text-amber-400">Verification Rating:</span>
                    <input
                      type="number"
                      min={0}
                      max={150}
                      value={vrDraft.rating}
                      onChange={(e) => setVrDraft((d) => ({ ...d, rating: parseInt(e.target.value, 10) || 0 }))}
                      className="w-24 px-2 py-1 border border-amber-300 rounded text-sm focus:outline-none focus:ring-1 focus:ring-amber-400 dark:bg-gray-800 dark:border-gray-600 dark:text-white"
                    />
                  </div>

                  {(vrDraft.rating < 0 || vrDraft.rating > 150) && (
                    <p className="text-red-600 text-xs mt-1">Must be between 0 and 150</p>
                  )}

                  {account.connected_profile.vq_hold_until &&
                    new Date(account.connected_profile.vq_hold_until) > new Date() && (
                      <div>
                        {!vrDraft.clearHold ? (
                          <button
                            onClick={() => setVrDraft((d) => ({ ...d, clearHold: true }))}
                            className="text-xs px-2 py-1 border border-orange-300 text-orange-700 dark:text-orange-400 rounded hover:bg-orange-50"
                          >
                            Clear hold
                          </button>
                        ) : (
                          <span className="text-xs text-orange-700 italic">Hold will be cleared</span>
                        )}
                      </div>
                    )}

                  {vrError && <p className="text-red-600 text-xs mt-1">{vrError}</p>}

                  <div className="flex gap-2 mt-2">
                    <button
                      onClick={handleVrSave}
                      disabled={vrSaving || vrDraft.rating < 0 || vrDraft.rating > 150}
                      className="px-3 py-1 bg-ev-teal hover:bg-ev-teal/90 disabled:opacity-50 text-white text-sm rounded"
                    >
                      {vrSaving ? 'Saving...' : 'Save'}
                    </button>
                    <button
                      onClick={() => { setVrEditMode(false); setVrError(null); }}
                      className="px-3 py-1 border border-amber-300 text-amber-700 dark:text-amber-400 text-sm rounded hover:bg-amber-100"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>

      {/* Roles */}
      <RolesTab
        userId={userId!}
        displayName={account.display_name}
        roles={(account.roles ?? []) as Role[]}
        onRefresh={fetchAccount}
      />

      {/* Invite chain */}
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6 mb-4">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">Invite Chain</h2>
        <div className="space-y-3 text-sm">
          <div>
            <span className="font-medium text-gray-600 dark:text-gray-400">Invited by: </span>
            {account.invited_by ? (
              <Link
                to={`/admin/accounts/${account.invited_by.id}`}
                className="text-blue-600 hover:text-blue-800 dark:text-ev-teal-light dark:hover:text-ev-teal-light/80"
              >
                {account.invited_by.display_name}
              </Link>
            ) : (
              <span className="text-gray-400 dark:text-gray-500">Seed account</span>
            )}
          </div>
          <div>
            <span className="font-medium text-gray-600 dark:text-gray-400">Invited users: </span>
            {(account.invited_users?.length ?? 0) === 0 ? (
              <span className="text-gray-400 dark:text-gray-500">None</span>
            ) : (
              <span className="space-x-2">
                {account.invited_users?.map((u) => (
                  <Link
                    key={u.id}
                    to={`/admin/accounts/${u.id}`}
                    className="text-blue-600 hover:text-blue-800 dark:text-ev-teal-light dark:hover:text-ev-teal-light/80"
                  >
                    {u.display_name}
                  </Link>
                ))}
              </span>
            )}
          </div>
          <div>
            <Link
              to={`/admin/invites/tree/${account.id}`}
              className="text-blue-600 hover:text-blue-800 dark:text-ev-teal-light dark:hover:text-ev-teal-light/80 text-sm"
            >
              View subtree &rarr;
            </Link>
          </div>
        </div>
      </div>

      {/* Calibration status (Empowered only) */}
      {account.calibration_status && (
        <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6 mb-4">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">Calibration Status</h2>
          <div className="space-y-2 text-sm">
            <div className="flex">
              <span className="w-48 font-medium text-gray-600 dark:text-gray-400">Days since last calibration:</span>
              <span className={account.calibration_status.is_at_risk ? 'text-red-600 font-semibold' : 'text-gray-900 dark:text-white'}>
                {account.calibration_status.days_since_last_calibration ?? 'Never'}
              </span>
            </div>
            {account.calibration_status.overdue_topics.length > 0 && (
              <div>
                <span className="font-medium text-gray-600 dark:text-gray-400">Overdue topics:</span>
                <ul className="mt-1 ml-4 list-disc text-gray-700 dark:text-gray-300">
                  {account.calibration_status.overdue_topics.map((t, i) => (
                    <li key={i}>{t}</li>
                  ))}
                </ul>
              </div>
            )}
            {account.calibration_status.is_at_risk && (
              <div className="mt-2 p-2 bg-red-50 border border-red-200 rounded text-red-700 text-xs dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
                At risk of demotion
              </div>
            )}
          </div>
        </div>
      )}

      {/* Compass Section (Connected + Empowered only) */}
      {profileData?.selected_topic_ids !== undefined && (
        <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6 mb-4">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">Compass</h2>
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
            <span className="font-medium">{profileData.selected_topic_ids.length}</span> selected topic{profileData.selected_topic_ids.length !== 1 ? 's' : ''}
          </p>

          {profileData.compass_answers ? (
            profileData.compass_answers.length === 0 ? (
              <p className="text-sm text-gray-400 dark:text-gray-500">No compass answers recorded.</p>
            ) : (
              <div className="overflow-hidden rounded border border-gray-200 dark:border-gray-700">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
                    <tr>
                      <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Topic ID</th>
                      <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Value</th>
                      <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Write-in Text</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                    {profileData.compass_answers.map((answer) => (
                      <tr key={answer.topic_id}>
                        <td className="px-4 py-3 text-gray-500 dark:text-gray-400 font-mono text-xs">
                          {answer.topic_id.slice(0, 8)}&hellip;
                        </td>
                        <td className="px-4 py-3 text-gray-900 dark:text-white font-medium">{answer.value}</td>
                        <td className="px-4 py-3 text-gray-600 dark:text-gray-400">
                          {answer.write_in_text ?? <span className="text-gray-300">&mdash;</span>}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )
          ) : (
            <p className="text-sm text-gray-400 dark:text-gray-500 italic">
              Compass answers are private for Connected-tier users.
            </p>
          )}
        </div>
      )}

      {/* Empowered Profile Section (Empowered only) */}
      {profileData?.empowered_profile && (
        <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6 mb-4">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">Empowered Profile</h2>
          <div className="space-y-2 text-sm">
            <div className="flex">
              <span className="w-44 font-medium text-gray-600 dark:text-gray-400">Legal Name:</span>
              <span className="text-gray-900 dark:text-white">{profileData.empowered_profile.legal_name ?? 'Not set'}</span>
            </div>
            <div className="flex items-center">
              <span className="w-44 font-medium text-gray-600 dark:text-gray-400">Candidate Page Slug:</span>
              {profileData.empowered_profile.candidate_page_slug ? (
                <a
                  href={`/candidates/${profileData.empowered_profile.candidate_page_slug}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:text-blue-800 dark:text-ev-teal-light dark:hover:text-ev-teal-light/80"
                >
                  {profileData.empowered_profile.candidate_page_slug}
                </a>
              ) : (
                <span className="text-gray-400 dark:text-gray-500">Not set</span>
              )}
            </div>
            <div className="flex items-center">
              <span className="w-44 font-medium text-gray-600 dark:text-gray-400">Status:</span>
              <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${profileData.empowered_profile.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                {profileData.empowered_profile.is_active ? 'Active' : 'Inactive'}
              </span>
            </div>
            <div className="flex">
              <span className="w-44 font-medium text-gray-600 dark:text-gray-400">Empowered At:</span>
              <span className="text-gray-900 dark:text-white">
                {profileData.empowered_profile.empowered_at
                  ? new Date(profileData.empowered_profile.empowered_at as string).toLocaleDateString()
                  : 'Unknown'}
              </span>
            </div>
            {profileData.empowered_profile.demoted_at && (
              <div className="flex">
                <span className="w-44 font-medium text-gray-600 dark:text-gray-400">Demoted At:</span>
                <span className="text-red-600">
                  {new Date(profileData.empowered_profile.demoted_at as string).toLocaleDateString()}
                </span>
              </div>
            )}
          </div>
        </div>
      )}

      {/* XP History (Connected + Empowered only) */}
      {account.connected_profile && (
        <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6 mb-4">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">XP History</h2>

          {xpError && (
            <div className="p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm mb-3 dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
              Failed to load XP history.
            </div>
          )}

          <div className="overflow-hidden rounded border border-gray-200 dark:border-gray-700">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
                <tr>
                  <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Source</th>
                  <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Amount</th>
                  <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Timestamp</th>
                  <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Metadata</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {xpLoading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <tr key={i} className="animate-pulse">
                      <td colSpan={4} className="px-4 py-3">
                        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-full"></div>
                      </td>
                    </tr>
                  ))
                ) : !xpData || xpData.transactions.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="px-4 py-8 text-center text-gray-400 dark:text-gray-500">
                      No XP transactions found.
                    </td>
                  </tr>
                ) : (
                  xpData.transactions.map((tx) => (
                    <React.Fragment key={tx.id}>
                      <tr>
                        <td className="px-4 py-3 text-gray-700 dark:text-gray-300">{tx.source}</td>
                        <td className="px-4 py-3 text-gray-900 dark:text-white font-medium">+{tx.amount}</td>
                        <td className="px-4 py-3 text-gray-500 dark:text-gray-400">
                          {new Date(tx.created_at).toLocaleString()}
                        </td>
                        <td className="px-4 py-3">
                          {tx.metadata && Object.keys(tx.metadata).length > 0 ? (
                            <button
                              onClick={() => setExpandedId(expandedId === tx.id ? null : tx.id)}
                              className="text-xs text-blue-600 hover:text-blue-800 dark:text-ev-teal-light dark:hover:text-ev-teal-light/80"
                            >
                              {expandedId === tx.id ? 'Hide' : 'View'}
                            </button>
                          ) : (
                            <span className="text-gray-300 text-xs">&mdash;</span>
                          )}
                        </td>
                      </tr>
                      {expandedId === tx.id && tx.metadata && (
                        <tr className="bg-gray-50 dark:bg-gray-800">
                          <td colSpan={4} className="px-4 py-2">
                            <pre className="text-xs text-gray-600 dark:text-gray-300 overflow-auto max-h-32 whitespace-pre-wrap">
                              {JSON.stringify(tx.metadata, null, 2)}
                            </pre>
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {xpData && xpData.pages > 1 && (
            <div className="mt-4 flex items-center justify-between text-sm text-gray-600 dark:text-gray-400">
              <span>
                Page {xpData.page} of {xpData.pages} ({xpData.total} total)
              </span>
              <div className="flex gap-2">
                <button
                  onClick={() => setXpPage((p) => Math.max(1, p - 1))}
                  disabled={xpPage <= 1}
                  className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
                >
                  Previous
                </button>
                <button
                  onClick={() => setXpPage((p) => Math.min(xpData.pages, p + 1))}
                  disabled={xpPage >= xpData.pages}
                  className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Promotion History Section (always shown) */}
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6 mb-4">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">Promotion History</h2>

        {promotionHistoryError && (
          <div className="p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm mb-3 dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
            Failed to load promotion history.
          </div>
        )}

        <div className="overflow-hidden rounded border border-gray-200 dark:border-gray-700">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Date</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Admin</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Previous Tier</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">New Tier</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Note</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {promotionHistoryLoading ? (
                Array.from({ length: 3 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={5} className="px-4 py-3">
                      <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-full"></div>
                    </td>
                  </tr>
                ))
              ) : !promotionData || promotionData.entries.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-gray-400 dark:text-gray-500">
                    No promotions recorded.
                  </td>
                </tr>
              ) : (
                promotionData.entries.map((entry) => (
                  <tr key={entry.id}>
                    <td className="px-4 py-3 text-gray-500 dark:text-gray-400">
                      {new Date(entry.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-4 py-3 text-gray-700 dark:text-gray-300">{entry.admin_email}</td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${TIER_BADGE[entry.previous_tier] ?? 'bg-gray-100 text-gray-700'}`}>
                        {entry.previous_tier}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${TIER_BADGE[entry.new_tier] ?? 'bg-gray-100 text-gray-700'}`}>
                        {entry.new_tier}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-600 dark:text-gray-400">
                      {entry.note ?? <span className="text-gray-300 dark:text-gray-600">&mdash;</span>}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {promotionData && promotionData.pages > 1 && (
          <div className="mt-4 flex items-center justify-between text-sm text-gray-600 dark:text-gray-400">
            <span>
              Page {promotionData.page} of {promotionData.pages} ({promotionData.total} total)
            </span>
            <div className="flex gap-2">
              <button
                onClick={() => setPromotionPage((p) => Math.max(1, p - 1))}
                disabled={promotionPage <= 1}
                className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
              >
                Previous
              </button>
              <button
                onClick={() => setPromotionPage((p) => Math.min(promotionData.pages, p + 1))}
                disabled={promotionPage >= promotionData.pages}
                className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Invite Cap Override */}
      {account.connected_profile && (
        <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6 mb-4">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">Invite Cap Override</h2>
          <div className="space-y-3">
            <div>
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">
                Level {account.connected_profile.current_level} &rarr; base cap {getInviteCapForLevel(account.connected_profile.current_level)}
                {account.connected_profile.invite_cap_override != null && (
                  <span className="ml-2 text-ev-red font-medium">
                    Override: {account.connected_profile.invite_cap_override === -1 ? 'Unlimited' : account.connected_profile.invite_cap_override}
                  </span>
                )}
              </p>
            </div>
            <div className="flex gap-3 items-end">
              <div className="flex-1">
                <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Override value (blank = default, -1 = unlimited, or positive integer)
                </label>
                <input
                  type="text"
                  value={inviteCapOverride}
                  onChange={(e) => setInviteCapOverride(e.target.value)}
                  placeholder="blank = level default"
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400"
                />
              </div>
              <button
                onClick={handleSaveInviteCap}
                disabled={inviteCapSaving}
                className="px-4 py-2 bg-ev-teal hover:bg-ev-teal/90 disabled:opacity-50 text-white text-sm font-medium rounded-md transition-colors"
              >
                {inviteCapSaving ? 'Saving\u2026' : 'Save'}
              </button>
            </div>
            {inviteCapMsg && (
              <p className={`text-xs font-medium ${inviteCapMsg.includes('Failed') ? 'text-ev-red' : 'text-ev-teal'}`}>
                {inviteCapMsg}
              </p>
            )}
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">Actions</h2>

        {actionError && (
          <div className="mb-3 p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
            {actionError}
          </div>
        )}

        <div className="flex gap-3 flex-wrap">
          {account.account_standing === 'active' ? (
            <button
              onClick={() => handleAction('suspend')}
              disabled={actionLoading}
              className="px-4 py-2 bg-red-600 hover:bg-red-700 disabled:bg-red-400 text-white text-sm font-medium rounded-md transition-colors"
            >
              Suspend Account
            </button>
          ) : (
            <button
              onClick={() => handleAction('unsuspend')}
              disabled={actionLoading}
              className="px-4 py-2 bg-green-600 hover:bg-green-700 disabled:bg-green-400 text-white text-sm font-medium rounded-md transition-colors"
            >
              Unsuspend Account
            </button>
          )}

          {account.tier === 'inform' && (
            <button
              onClick={() => setShowPromoteModal(true)}
              disabled={actionLoading}
              className="px-4 py-2 bg-ev-teal hover:bg-ev-teal/90 disabled:opacity-50 text-white text-sm font-medium rounded-md transition-colors"
            >
              Promote to Connected
            </button>
          )}

          {account.tier === 'empowered' && !showDemoteConfirm && (
            <button
              onClick={() => setShowDemoteConfirm(true)}
              disabled={actionLoading}
              className="px-4 py-2 bg-orange-600 hover:bg-orange-700 disabled:bg-orange-400 text-white text-sm font-medium rounded-md transition-colors"
            >
              Demote Account
            </button>
          )}

          {showDemoteConfirm && (
            <div className="flex items-center gap-2 p-3 bg-orange-50 border border-orange-200 rounded dark:bg-orange-950/20 dark:border-orange-800/40">
              <span className="text-sm text-orange-800 dark:text-orange-300">Confirm demotion?</span>
              <button
                onClick={() => handleAction('demote')}
                disabled={actionLoading}
                className="px-3 py-1 bg-orange-600 hover:bg-orange-700 text-white text-sm rounded"
              >
                Confirm
              </button>
              <button
                onClick={() => setShowDemoteConfirm(false)}
                className="px-3 py-1 border border-orange-300 text-orange-700 dark:text-orange-400 text-sm rounded hover:bg-orange-100"
              >
                Cancel
              </button>
            </div>
          )}

          {!showDeleteConfirm ? (
            <button
              onClick={() => setShowDeleteConfirm(true)}
              disabled={actionLoading || deleteLoading}
              className="px-4 py-2 bg-gray-800 hover:bg-gray-900 disabled:opacity-50 text-white text-sm font-medium rounded-md transition-colors"
            >
              Delete Account
            </button>
          ) : (
            <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded dark:bg-red-950/40 dark:border-red-800/60">
              <span className="text-sm text-red-800 dark:text-red-400">
                Permanently delete <strong>{account.display_name}</strong>? This cannot be undone.
              </span>
              <button
                onClick={handleDelete}
                disabled={deleteLoading}
                className="px-3 py-1 bg-red-700 hover:bg-red-800 text-white text-sm rounded disabled:opacity-50"
              >
                {deleteLoading ? 'Deleting...' : 'Delete'}
              </button>
              <button
                onClick={() => setShowDeleteConfirm(false)}
                disabled={deleteLoading}
                className="px-3 py-1 border border-red-300 text-red-700 text-sm rounded hover:bg-red-100"
              >
                Cancel
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Promote to Connected Modal */}
      {showPromoteModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center">
          <div className="bg-white dark:bg-gray-900 rounded-lg shadow-xl p-6 max-w-md w-full mx-4">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">Promote to Connected</h2>
            <p className="text-sm text-gray-700 dark:text-gray-300 mb-4">
              Promote <strong>{account.display_name}</strong> from Inform to Connected tier?
            </p>
            <textarea
              value={promoteNote}
              onChange={(e) => setPromoteNote(e.target.value)}
              maxLength={500}
              placeholder="Add a note (optional)"
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-ev-teal focus:border-transparent resize-none mb-4 dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
            />
            <div className="flex justify-end gap-3">
              <button
                onClick={() => {
                  setShowPromoteModal(false);
                  setPromoteNote('');
                }}
                disabled={promotionLoading}
                className="px-4 py-2 border border-gray-300 text-gray-700 dark:text-gray-300 dark:border-gray-600 text-sm font-medium rounded-md hover:bg-gray-50 dark:hover:bg-gray-800 disabled:opacity-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handlePromote}
                disabled={promotionLoading}
                className="px-4 py-2 bg-ev-teal hover:bg-ev-teal/90 disabled:opacity-50 text-white text-sm font-medium rounded-md transition-colors"
              >
                {promotionLoading ? 'Promoting...' : 'Promote to Connected'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
