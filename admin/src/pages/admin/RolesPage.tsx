import { useEffect, useState } from 'react';
import { apiFetch } from '../../lib/api';

interface Role {
  id: string;
  slug: string;
  name: string;
  is_active: boolean;
}

export function RolesPage() {
  const [roles, setRoles] = useState<Role[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const [grantUserId, setGrantUserId] = useState('');
  const [grantRoleSlug, setGrantRoleSlug] = useState('');
  const [revokeUserId, setRevokeUserId] = useState('');
  const [revokeRoleSlug, setRevokeRoleSlug] = useState('');
  const [actionError, setActionError] = useState<string | null>(null);
  const [actionSuccess, setActionSuccess] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    apiFetch<{ roles: Role[] }>('/roles')
      .then((data) => setRoles(data.roles))
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  async function handleGrant(e: React.FormEvent) {
    e.preventDefault();
    setActionError(null);
    setActionSuccess(null);
    setActionLoading(true);
    try {
      await apiFetch('/admin/roles/grant', {
        method: 'POST',
        body: JSON.stringify({ userId: grantUserId, roleSlug: grantRoleSlug }),
      });
      setActionSuccess(`Role "${grantRoleSlug}" granted to ${grantUserId}`);
      setGrantUserId('');
      setGrantRoleSlug('');
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Grant failed');
    } finally {
      setActionLoading(false);
    }
  }

  async function handleRevoke(e: React.FormEvent) {
    e.preventDefault();
    setActionError(null);
    setActionSuccess(null);
    setActionLoading(true);
    try {
      await apiFetch('/admin/roles/revoke', {
        method: 'POST',
        body: JSON.stringify({ userId: revokeUserId, roleSlug: revokeRoleSlug }),
      });
      setActionSuccess(`Role "${revokeRoleSlug}" revoked from ${revokeUserId}`);
      setRevokeUserId('');
      setRevokeRoleSlug('');
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Revoke failed');
    } finally {
      setActionLoading(false);
    }
  }

  const activeRoles = roles.filter((r) => r.is_active);

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Roles</h1>

      {/* Available roles */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-3">Available Roles</h2>
        {error && (
          <div className="mb-3 text-sm text-red-600">{error}</div>
        )}
        {loading ? (
          <div className="animate-pulse space-y-2">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="h-4 bg-gray-200 rounded w-1/3"></div>
            ))}
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="border-b border-gray-200">
              <tr>
                <th className="text-left py-2 font-medium text-gray-500">Slug</th>
                <th className="text-left py-2 font-medium text-gray-500">Display Name</th>
                <th className="text-left py-2 font-medium text-gray-500">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {roles.map((role) => (
                <tr key={role.id}>
                  <td className="py-2 font-mono text-gray-700">{role.slug}</td>
                  <td className="py-2 text-gray-900">{role.name}</td>
                  <td className="py-2">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${role.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                      {role.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {(actionError || actionSuccess) && (
        <div className={`mb-4 p-3 rounded text-sm ${actionError ? 'bg-red-50 border border-red-200 text-red-700' : 'bg-green-50 border border-green-200 text-green-700'}`}>
          {actionError || actionSuccess}
        </div>
      )}

      <div className="grid grid-cols-2 gap-6">
        {/* Grant form */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Grant Role</h2>
          <form onSubmit={handleGrant} className="space-y-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">User ID</label>
              <input
                type="text"
                value={grantUserId}
                onChange={(e) => setGrantUserId(e.target.value)}
                required
                placeholder="UUID"
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Role</label>
              <select
                value={grantRoleSlug}
                onChange={(e) => setGrantRoleSlug(e.target.value)}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Select a role...</option>
                {activeRoles.map((r) => (
                  <option key={r.id} value={r.slug}>{r.name}</option>
                ))}
              </select>
            </div>
            <button
              type="submit"
              disabled={actionLoading}
              className="w-full py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white text-sm font-medium rounded-md"
            >
              Grant Role
            </button>
          </form>
        </div>

        {/* Revoke form */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Revoke Role</h2>
          <form onSubmit={handleRevoke} className="space-y-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">User ID</label>
              <input
                type="text"
                value={revokeUserId}
                onChange={(e) => setRevokeUserId(e.target.value)}
                required
                placeholder="UUID"
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Role</label>
              <select
                value={revokeRoleSlug}
                onChange={(e) => setRevokeRoleSlug(e.target.value)}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Select a role...</option>
                {activeRoles.map((r) => (
                  <option key={r.id} value={r.slug}>{r.name}</option>
                ))}
              </select>
            </div>
            <button
              type="submit"
              disabled={actionLoading}
              className="w-full py-2 bg-red-600 hover:bg-red-700 disabled:bg-red-400 text-white text-sm font-medium rounded-md"
            >
              Revoke Role
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
