import { useEffect, useState } from 'react';
import { Link } from 'react-router';
import { apiFetch } from '../../lib/api';

interface InviteOverride {
  user_id: string;
  display_name: string;
  email: string;
  current_level: number;
  level_cap: number;
  invite_cap_override: number;
  effective_cap: number;
}

export function InviteOverridesPage() {
  const [overrides, setOverrides] = useState<InviteOverride[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    apiFetch<InviteOverride[]>('/admin/invite-overrides')
      .then(setOverrides)
      .catch((err) => setError(err.message));
  }, []);

  function formatCap(cap: number): string {
    return cap >= 2147483647 ? 'Unlimited' : String(cap);
  }

  function formatOverride(override: number): string {
    return override === -1 ? 'Unlimited' : String(override);
  }

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Invite Overrides</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
          Users with admin-set invite cap overrides.
        </p>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
          {error}
        </div>
      )}

      <div className="bg-white dark:bg-gray-900 rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead className="bg-gray-50 dark:bg-gray-800">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">User</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Email</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Level</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Level Cap</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Override</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Effective Cap</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {overrides === null ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-gray-400 dark:text-gray-500">
                  Loading...
                </td>
              </tr>
            ) : overrides.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-gray-400 dark:text-gray-500">
                  No invite overrides set.
                </td>
              </tr>
            ) : (
              overrides.map((row) => (
                <tr key={row.user_id}>
                  <td className="px-4 py-3 text-sm text-gray-900 dark:text-white">
                    <Link
                      to={`/admin/accounts/${row.user_id}`}
                      className="text-ev-teal hover:underline font-medium"
                    >
                      {row.display_name}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-600 dark:text-gray-300">{row.email}</td>
                  <td className="px-4 py-3 text-sm text-gray-900 dark:text-white">{row.current_level}</td>
                  <td className="px-4 py-3 text-sm text-gray-600 dark:text-gray-300">{row.level_cap}</td>
                  <td className="px-4 py-3 text-sm font-medium text-ev-red">{formatOverride(row.invite_cap_override)}</td>
                  <td className="px-4 py-3 text-sm font-semibold text-gray-900 dark:text-white">{formatCap(row.effective_cap)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
