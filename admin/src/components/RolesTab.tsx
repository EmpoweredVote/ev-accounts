import { useState } from 'react';
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';
import { apiFetch } from '../lib/api';
import { GrantRoleModal } from './GrantRoleModal';

// ── Types ─────────────────────────────────────────────────────────────────────

export interface Role {
  slug: string;
  name: string;
  granted_at: string;
  feature_scope: string;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function scopeLabel(role: Role): React.ReactNode {
  if (role.jurisdiction_geoid) {
    return <span>Jurisdiction: <span className="font-mono text-xs">{role.jurisdiction_geoid}</span></span>;
  }
  if (role.resource_id) {
    return <span>Politician ID: <span className="font-mono text-xs">{role.resource_id}</span></span>;
  }
  return <span className="text-gray-400 dark:text-gray-500">Platform-wide</span>;
}

// ── RolesTab ──────────────────────────────────────────────────────────────────

interface RolesTabProps {
  userId: string;
  displayName: string;
  roles: Role[];
  onRefresh: () => void;
}

export function RolesTab({ userId, displayName, roles, onRefresh }: RolesTabProps) {
  const [grantModalOpen, setGrantModalOpen] = useState(false);
  const [revokeTarget, setRevokeTarget] = useState<Role | null>(null);
  const [revoking, setRevoking] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  function showSuccess(msg: string) {
    setSuccessMessage(msg);
    setTimeout(() => setSuccessMessage(null), 2000);
  }

  async function handleRevoke() {
    if (!revokeTarget) return;
    setRevoking(true);
    setErrorMessage(null);
    try {
      await apiFetch('/admin/roles/revoke', {
        method: 'POST',
        body: JSON.stringify({
          user_id: userId,
          role_slug: revokeTarget.slug,
          feature_scope: revokeTarget.feature_scope,
          jurisdiction_geoid: revokeTarget.jurisdiction_geoid,
          resource_id: revokeTarget.resource_id,
        }),
      });
      setRevokeTarget(null);
      showSuccess('Role revoked successfully.');
      onRefresh();
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : 'Revoke failed');
    } finally {
      setRevoking(false);
    }
  }

  return (
    <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6 mb-4">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Roles</h2>
        <button
          onClick={() => setGrantModalOpen(true)}
          className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded"
        >
          Grant Role
        </button>
      </div>

      {/* Inline feedback messages */}
      {successMessage && (
        <div className="mb-3 px-3 py-2 bg-green-50 border border-green-200 text-green-700 text-sm rounded dark:bg-green-950/40 dark:border-green-800/60 dark:text-green-400">
          {successMessage}
        </div>
      )}
      {errorMessage && (
        <div className="mb-3 px-3 py-2 bg-red-50 border border-red-200 text-red-700 text-sm rounded dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
          {errorMessage}
        </div>
      )}

      {roles.length === 0 ? (
        <p className="text-sm text-gray-500 dark:text-gray-400">No roles assigned.</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left border-b border-gray-100 dark:border-gray-800">
                <th className="pb-2 font-medium text-gray-500 dark:text-gray-400 pr-4">Role</th>
                <th className="pb-2 font-medium text-gray-500 dark:text-gray-400 pr-4">Scope</th>
                <th className="pb-2 font-medium text-gray-500 dark:text-gray-400 pr-4">Granted</th>
                <th className="pb-2 font-medium text-gray-500 dark:text-gray-400 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
              {roles.map((role) => (
                <tr key={`${role.slug}-${role.feature_scope}-${role.jurisdiction_geoid ?? ''}-${role.resource_id ?? ''}`}>
                  <td className="py-2.5 pr-4">
                    <div className="font-medium text-gray-900 dark:text-white">{role.name}</div>
                    <div className="font-mono text-xs text-gray-400 dark:text-gray-500">{role.slug}</div>
                  </td>
                  <td className="py-2.5 pr-4 text-sm text-gray-700 dark:text-gray-300">
                    {scopeLabel(role)}
                  </td>
                  <td className="py-2.5 pr-4 text-sm text-gray-500 dark:text-gray-400">
                    {new Date(role.granted_at).toLocaleDateString()}
                  </td>
                  <td className="py-2.5 text-right">
                    <button
                      onClick={() => { setErrorMessage(null); setRevokeTarget(role); }}
                      className="text-xs text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300"
                    >
                      Revoke
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Grant Role Modal */}
      <GrantRoleModal
        open={grantModalOpen}
        onClose={() => setGrantModalOpen(false)}
        userId={userId}
        onGranted={() => {
          setGrantModalOpen(false);
          showSuccess('Role granted successfully.');
          onRefresh();
        }}
      />

      {/* Revoke Confirmation Dialog */}
      <Dialog
        open={revokeTarget !== null}
        onClose={() => { if (!revoking) setRevokeTarget(null); }}
        className="relative z-50"
      >
        <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
        <div className="fixed inset-0 flex items-center justify-center p-4">
          <DialogPanel className="w-full max-w-md bg-white dark:bg-gray-900 rounded-lg shadow-xl p-6">
            <DialogTitle className="text-lg font-semibold text-gray-900 dark:text-white mb-3">
              Revoke role
            </DialogTitle>
            <p className="text-sm text-gray-700 dark:text-gray-300 mb-5">
              Revoke <span className="font-medium">{revokeTarget?.name}</span> for{' '}
              <span className="font-medium">{displayName}</span>? This cannot be undone.
            </p>
            {errorMessage && (
              <p className="mb-3 text-sm text-red-600 dark:text-red-400">{errorMessage}</p>
            )}
            <div className="flex gap-3 justify-end">
              <button
                onClick={() => setRevokeTarget(null)}
                disabled={revoking}
                className="px-3 py-1.5 text-sm border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-50 dark:hover:bg-gray-800 disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                onClick={handleRevoke}
                disabled={revoking}
                className="px-3 py-1.5 text-sm bg-red-600 hover:bg-red-700 text-white rounded disabled:opacity-50"
              >
                {revoking ? 'Revoking...' : 'Confirm Revoke'}
              </button>
            </div>
          </DialogPanel>
        </div>
      </Dialog>
    </div>
  );
}
