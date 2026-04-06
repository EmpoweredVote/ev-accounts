import { useEffect, useRef, useState } from 'react';
import { apiFetch } from '../../lib/api';

interface Role {
  id: string;
  slug: string;
  name: string;
  is_active: boolean;
}

interface UserResult {
  id: string;
  display_name: string;
  email: string;
}

// ── UserSearch ────────────────────────────────────────────────────────────────
// Typeahead that resolves a display_name / email to a UUID.

interface UserSearchProps {
  value: string;           // the resolved UUID
  displayName: string;     // the resolved display name (shown in the field)
  onChange: (id: string, name: string) => void;
  placeholder?: string;
}

function UserSearch({ value, displayName, onChange, placeholder }: UserSearchProps) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<UserResult[]>([]);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const debounce = useRef<ReturnType<typeof setTimeout> | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // If a user is already selected, show their name; otherwise show the query
  const inputValue = value ? displayName : query;

  function handleInput(e: React.ChangeEvent<HTMLInputElement>) {
    const q = e.target.value;
    // If user edits after a selection, clear the selection
    if (value) onChange('', '');
    setQuery(q);
    setOpen(true);

    if (debounce.current) clearTimeout(debounce.current);
    if (!q.trim()) { setResults([]); return; }

    debounce.current = setTimeout(() => {
      setLoading(true);
      apiFetch<{ accounts: UserResult[] }>(`/admin/accounts?search=${encodeURIComponent(q)}`)
        .then((data) => setResults(data.accounts ?? []))
        .catch(() => setResults([]))
        .finally(() => setLoading(false));
    }, 300);
  }

  function handleSelect(user: UserResult) {
    onChange(user.id, user.display_name);
    setQuery('');
    setResults([]);
    setOpen(false);
  }

  // Close dropdown on outside click
  useEffect(() => {
    function handler(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  return (
    <div ref={containerRef} className="relative">
      <input
        type="text"
        value={inputValue}
        onChange={handleInput}
        onFocus={() => { if (results.length > 0) setOpen(true); }}
        required={!value}
        placeholder={placeholder ?? 'Search by name or email...'}
        className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
      />
      {value && (
        <p className="mt-0.5 text-xs text-gray-400 font-mono">{value}</p>
      )}
      {open && (query.trim() || results.length > 0) && !value && (
        <div className="absolute z-20 w-full mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md shadow-lg max-h-48 overflow-y-auto">
          {loading && (
            <div className="px-3 py-2 text-sm text-gray-400">Searching...</div>
          )}
          {!loading && results.length === 0 && query.trim() && (
            <div className="px-3 py-2 text-sm text-gray-400">No users found</div>
          )}
          {results.map((u) => (
            <button
              key={u.id}
              type="button"
              onMouseDown={() => handleSelect(u)}
              className="w-full text-left px-3 py-2 text-sm hover:bg-gray-50 dark:hover:bg-gray-700 border-b border-gray-100 dark:border-gray-700 last:border-0"
            >
              <span className="font-medium text-gray-900 dark:text-white">{u.display_name}</span>
              <span className="ml-2 text-gray-400 text-xs">{u.email}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

// ── RolesPage ─────────────────────────────────────────────────────────────────

export function RolesPage() {
  const [roles, setRoles] = useState<Role[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const [grantUserId, setGrantUserId] = useState('');
  const [grantUserName, setGrantUserName] = useState('');
  const [grantRoleSlug, setGrantRoleSlug] = useState('');
  const [grantJurisdiction, setGrantJurisdiction] = useState('');

  const [revokeUserId, setRevokeUserId] = useState('');
  const [revokeUserName, setRevokeUserName] = useState('');
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
    if (!grantUserId) return;
    setActionError(null);
    setActionSuccess(null);
    setActionLoading(true);
    try {
      const isCampaignManager = grantRoleSlug === 'campaign_manager';
      const jurisdictionGeoid = (!isCampaignManager && grantJurisdiction.trim()) ? grantJurisdiction.trim() : null;
      const featureScope = jurisdictionGeoid ? 'jurisdiction' : 'platform';
      await apiFetch('/admin/roles/grant', {
        method: 'POST',
        body: JSON.stringify({
          user_id: grantUserId,
          role_slug: grantRoleSlug,
          feature_scope: featureScope,
          jurisdiction_geoid: jurisdictionGeoid,
        }),
      });
      const roleName = activeRoles.find((r) => r.slug === grantRoleSlug)?.name ?? grantRoleSlug;
      setActionSuccess(`Role "${roleName}" granted to ${grantUserName}`);
      setGrantUserId('');
      setGrantUserName('');
      setGrantRoleSlug('');
      setGrantJurisdiction('');
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Grant failed');
    } finally {
      setActionLoading(false);
    }
  }

  async function handleRevoke(e: React.FormEvent) {
    e.preventDefault();
    if (!revokeUserId) return;
    setActionError(null);
    setActionSuccess(null);
    setActionLoading(true);
    try {
      await apiFetch('/admin/roles/revoke', {
        method: 'POST',
        body: JSON.stringify({ user_id: revokeUserId, role_slug: revokeRoleSlug }),
      });
      const roleName = activeRoles.find((r) => r.slug === revokeRoleSlug)?.name ?? revokeRoleSlug;
      setActionSuccess(`Role "${roleName}" revoked from ${revokeUserName}`);
      setRevokeUserId('');
      setRevokeUserName('');
      setRevokeRoleSlug('');
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Revoke failed');
    } finally {
      setActionLoading(false);
    }
  }

  const activeRoles = roles; // /api/roles already returns only active roles server-side

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">Roles</h1>

      {/* Available roles */}
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6 mb-6">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">Available Roles</h2>
        {error && (
          <div className="mb-3 text-sm text-red-600">{error}</div>
        )}
        {loading ? (
          <div className="animate-pulse space-y-2">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/3"></div>
            ))}
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="border-b border-gray-200 dark:border-gray-700">
              <tr>
                <th className="text-left py-2 font-medium text-gray-500 dark:text-gray-400">Slug</th>
                <th className="text-left py-2 font-medium text-gray-500 dark:text-gray-400">Display Name</th>
                <th className="text-left py-2 font-medium text-gray-500 dark:text-gray-400">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {roles.map((role) => (
                <tr key={role.id}>
                  <td className="py-2 font-mono text-gray-700 dark:text-gray-300">{role.slug}</td>
                  <td className="py-2 text-gray-900 dark:text-white">{role.name}</td>
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
        <div className={`mb-4 p-3 rounded text-sm ${actionError ? 'bg-red-50 border border-red-200 text-red-700 dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400' : 'bg-green-50 border border-green-200 text-green-700 dark:bg-green-950/40 dark:border-green-800/60 dark:text-green-400'}`}>
          {actionError || actionSuccess}
        </div>
      )}

      <div className="grid grid-cols-2 gap-6">
        {/* Grant form */}
        <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Grant Role</h2>
          <form onSubmit={handleGrant} className="space-y-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">User</label>
              <UserSearch
                value={grantUserId}
                displayName={grantUserName}
                onChange={(id, name) => { setGrantUserId(id); setGrantUserName(name); }}
                placeholder="Search by name or email..."
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Role</label>
              <select
                value={grantRoleSlug}
                onChange={(e) => { setGrantRoleSlug(e.target.value); setGrantJurisdiction(''); }}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-white"
              >
                <option value="">Select a role...</option>
                {activeRoles.map((r) => (
                  <option key={r.id} value={r.slug}>{r.name}</option>
                ))}
              </select>
            </div>
            {grantRoleSlug && grantRoleSlug !== 'campaign_manager' && (
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Jurisdiction <span className="font-normal text-gray-400">(optional)</span>
                </label>
                <input
                  type="text"
                  value={grantJurisdiction}
                  onChange={(e) => setGrantJurisdiction(e.target.value)}
                  placeholder="e.g., 06037 — leave blank for platform-wide"
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
                />
              </div>
            )}
            <button
              type="submit"
              disabled={actionLoading || !grantUserId}
              className="w-full py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white text-sm font-medium rounded-md"
            >
              Grant Role
            </button>
          </form>
        </div>

        {/* Revoke form */}
        <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Revoke Role</h2>
          <form onSubmit={handleRevoke} className="space-y-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">User</label>
              <UserSearch
                value={revokeUserId}
                displayName={revokeUserName}
                onChange={(id, name) => { setRevokeUserId(id); setRevokeUserName(name); }}
                placeholder="Search by name or email..."
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Role</label>
              <select
                value={revokeRoleSlug}
                onChange={(e) => setRevokeRoleSlug(e.target.value)}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-white"
              >
                <option value="">Select a role...</option>
                {activeRoles.map((r) => (
                  <option key={r.id} value={r.slug}>{r.name}</option>
                ))}
              </select>
            </div>
            <button
              type="submit"
              disabled={actionLoading || !revokeUserId}
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
