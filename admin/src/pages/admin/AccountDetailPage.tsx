import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { apiFetch } from '../../lib/api';

interface Role {
  id: string;
  slug: string;
  name: string;
  granted_at: string;
}

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
  total_xp: number;
  current_level: number;
  gem_balance: number;
  completed_onboarding: boolean;
  created_at: string;
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

const TIER_BADGE: Record<string, string> = {
  inform: 'bg-gray-100 text-gray-700',
  connected: 'bg-blue-100 text-blue-700',
  empowered: 'bg-green-100 text-green-700',
};

const STANDING_BADGE: Record<string, string> = {
  active: 'bg-green-100 text-green-700',
  suspended: 'bg-red-100 text-red-700',
};

export function AccountDetailPage() {
  const { userId } = useParams<{ userId: string }>();
  const [account, setAccount] = useState<AccountDetail | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionError, setActionError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [showDemoteConfirm, setShowDemoteConfirm] = useState(false);

  // XP History state
  const [xpData, setXpData] = useState<XpHistoryResponse | null>(null);
  const [xpError, setXpError] = useState<string | null>(null);
  const [xpLoading, setXpLoading] = useState(false);
  const [xpPage, setXpPage] = useState(1);
  const [expandedId, setExpandedId] = useState<string | null>(null);

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

  async function handleRoleRevoke(roleSlug: string) {
    setActionError(null);
    setActionLoading(true);
    try {
      await apiFetch('/admin/roles/revoke', {
        method: 'POST',
        body: JSON.stringify({ user_id: userId, role_slug: roleSlug }),
      });
      fetchAccount();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Revoke failed');
    } finally {
      setActionLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="animate-pulse space-y-4">
        <div className="h-8 bg-gray-200 rounded w-1/3"></div>
        <div className="bg-white rounded-lg shadow p-6 space-y-3">
          <div className="h-4 bg-gray-200 rounded w-1/2"></div>
          <div className="h-4 bg-gray-200 rounded w-1/3"></div>
        </div>
      </div>
    );
  }

  if (error || !account) {
    return (
      <div className="p-4 bg-red-50 border border-red-200 rounded text-red-700">
        {error || 'Account not found'}
      </div>
    );
  }

  return (
    <div className="max-w-3xl">
      {/* Back link */}
      <Link to="/admin/accounts" className="text-sm text-blue-600 hover:text-blue-800 mb-4 inline-block">
        &larr; Back to Accounts
      </Link>

      {/* Profile header */}
      <div className="bg-white rounded-lg shadow p-6 mb-4">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{account.display_name}</h1>
            <p className="text-gray-500 text-sm mt-1">{account.email}</p>
            <p className="text-gray-400 text-xs mt-1">ID: {account.id}</p>
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
        <p className="text-sm text-gray-500 mt-3">
          Joined {new Date(account.created_at).toLocaleDateString()}
        </p>
        {account.connected_profile && (
          <p className="text-sm text-gray-500 mt-1">
            Level {account.connected_profile.current_level ?? 0}
            {' \u00b7 '}
            {(account.connected_profile.total_xp ?? 0).toLocaleString()} XP
          </p>
        )}
      </div>

      {/* Admin-only sensitive fields */}
      <div className="bg-amber-50 border border-amber-200 rounded-lg p-6 mb-4">
        <h2 className="text-sm font-semibold text-amber-800 uppercase tracking-wide mb-3">
          Admin-Only Fields
        </h2>
        <div className="space-y-2 text-sm">
          <div className="flex">
            <span className="w-36 font-medium text-amber-700">Legal Name:</span>
            <span className="text-amber-900">{account.legal_name ?? 'Not set'}</span>
          </div>
          <div className="flex">
            <span className="w-36 font-medium text-amber-700">Tolerance Rating:</span>
            <span className="text-amber-900">
              {account.tolerance_rating != null ? account.tolerance_rating.toFixed(2) : 'N/A'}
            </span>
          </div>
        </div>
      </div>

      {/* Roles */}
      <div className="bg-white rounded-lg shadow p-6 mb-4">
        <h2 className="text-lg font-semibold text-gray-900 mb-3">Roles</h2>
        {(account.roles?.length ?? 0) === 0 ? (
          <p className="text-sm text-gray-500">No roles assigned.</p>
        ) : (
          <div className="space-y-2">
            {account.roles?.map((role) => (
              <div key={role.id} className="flex items-center justify-between">
                <div>
                  <span className="font-medium text-sm text-gray-900">{role.slug}</span>
                  <span className="text-xs text-gray-400 ml-2">
                    Granted {new Date(role.granted_at).toLocaleDateString()}
                  </span>
                </div>
                <button
                  onClick={() => handleRoleRevoke(role.slug)}
                  disabled={actionLoading}
                  className="text-xs text-red-600 hover:text-red-800 disabled:opacity-50"
                >
                  Revoke
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Invite chain */}
      <div className="bg-white rounded-lg shadow p-6 mb-4">
        <h2 className="text-lg font-semibold text-gray-900 mb-3">Invite Chain</h2>
        <div className="space-y-3 text-sm">
          <div>
            <span className="font-medium text-gray-600">Invited by: </span>
            {account.invited_by ? (
              <Link
                to={`/admin/accounts/${account.invited_by.id}`}
                className="text-blue-600 hover:text-blue-800"
              >
                {account.invited_by.display_name}
              </Link>
            ) : (
              <span className="text-gray-400">Seed account</span>
            )}
          </div>
          <div>
            <span className="font-medium text-gray-600">Invited users: </span>
            {(account.invited_users?.length ?? 0) === 0 ? (
              <span className="text-gray-400">None</span>
            ) : (
              <span className="space-x-2">
                {account.invited_users?.map((u) => (
                  <Link
                    key={u.id}
                    to={`/admin/accounts/${u.id}`}
                    className="text-blue-600 hover:text-blue-800"
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
              className="text-blue-600 hover:text-blue-800 text-sm"
            >
              View subtree &rarr;
            </Link>
          </div>
        </div>
      </div>

      {/* Calibration status (Empowered only) */}
      {account.calibration_status && (
        <div className="bg-white rounded-lg shadow p-6 mb-4">
          <h2 className="text-lg font-semibold text-gray-900 mb-3">Calibration Status</h2>
          <div className="space-y-2 text-sm">
            <div className="flex">
              <span className="w-48 font-medium text-gray-600">Days since last calibration:</span>
              <span className={account.calibration_status.is_at_risk ? 'text-red-600 font-semibold' : 'text-gray-900'}>
                {account.calibration_status.days_since_last_calibration ?? 'Never'}
              </span>
            </div>
            {account.calibration_status.overdue_topics.length > 0 && (
              <div>
                <span className="font-medium text-gray-600">Overdue topics:</span>
                <ul className="mt-1 ml-4 list-disc text-gray-700">
                  {account.calibration_status.overdue_topics.map((t, i) => (
                    <li key={i}>{t}</li>
                  ))}
                </ul>
              </div>
            )}
            {account.calibration_status.is_at_risk && (
              <div className="mt-2 p-2 bg-red-50 border border-red-200 rounded text-red-700 text-xs">
                At risk of demotion
              </div>
            )}
          </div>
        </div>
      )}

      {/* XP History (Connected + Empowered only) */}
      {account.connected_profile && (
        <div className="bg-white rounded-lg shadow p-6 mb-4">
          <h2 className="text-lg font-semibold text-gray-900 mb-3">XP History</h2>

          {xpError && (
            <div className="p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm mb-3">
              Failed to load XP history.
            </div>
          )}

          <div className="overflow-hidden rounded border border-gray-200">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="text-left px-4 py-3 font-medium text-gray-500">Source</th>
                  <th className="text-left px-4 py-3 font-medium text-gray-500">Amount</th>
                  <th className="text-left px-4 py-3 font-medium text-gray-500">Timestamp</th>
                  <th className="text-left px-4 py-3 font-medium text-gray-500">Metadata</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {xpLoading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <tr key={i} className="animate-pulse">
                      <td colSpan={4} className="px-4 py-3">
                        <div className="h-4 bg-gray-200 rounded w-full"></div>
                      </td>
                    </tr>
                  ))
                ) : !xpData || xpData.transactions.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="px-4 py-8 text-center text-gray-400">
                      No XP transactions found.
                    </td>
                  </tr>
                ) : (
                  xpData.transactions.map((tx) => (
                    <React.Fragment key={tx.id}>
                      <tr>
                        <td className="px-4 py-3 text-gray-700">{tx.source}</td>
                        <td className="px-4 py-3 text-gray-900 font-medium">+{tx.amount}</td>
                        <td className="px-4 py-3 text-gray-500">
                          {new Date(tx.created_at).toLocaleString()}
                        </td>
                        <td className="px-4 py-3">
                          {tx.metadata && Object.keys(tx.metadata).length > 0 ? (
                            <button
                              onClick={() => setExpandedId(expandedId === tx.id ? null : tx.id)}
                              className="text-xs text-blue-600 hover:text-blue-800"
                            >
                              {expandedId === tx.id ? 'Hide' : 'View'}
                            </button>
                          ) : (
                            <span className="text-gray-300 text-xs">&mdash;</span>
                          )}
                        </td>
                      </tr>
                      {expandedId === tx.id && tx.metadata && (
                        <tr className="bg-gray-50">
                          <td colSpan={4} className="px-4 py-2">
                            <pre className="text-xs text-gray-600 overflow-auto max-h-32 whitespace-pre-wrap">
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
            <div className="mt-4 flex items-center justify-between text-sm text-gray-600">
              <span>
                Page {xpData.page} of {xpData.pages} ({xpData.total} total)
              </span>
              <div className="flex gap-2">
                <button
                  onClick={() => setXpPage((p) => Math.max(1, p - 1))}
                  disabled={xpPage <= 1}
                  className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => setXpPage((p) => Math.min(xpData.pages, p + 1))}
                  disabled={xpPage >= xpData.pages}
                  className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Actions */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-3">Actions</h2>

        {actionError && (
          <div className="mb-3 p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
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
            <div className="flex items-center gap-2 p-3 bg-orange-50 border border-orange-200 rounded">
              <span className="text-sm text-orange-800">Confirm demotion?</span>
              <button
                onClick={() => handleAction('demote')}
                disabled={actionLoading}
                className="px-3 py-1 bg-orange-600 hover:bg-orange-700 text-white text-sm rounded"
              >
                Confirm
              </button>
              <button
                onClick={() => setShowDemoteConfirm(false)}
                className="px-3 py-1 border border-orange-300 text-orange-700 text-sm rounded hover:bg-orange-100"
              >
                Cancel
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
