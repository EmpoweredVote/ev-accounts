import { useEffect, useState, useCallback } from 'react';
import { Link } from 'react-router';
import { apiFetch } from '../../lib/api';

interface InviteCode {
  id: string;
  code: string;
  created_by_id: string;
  created_by_name: string;
  claimed_by_id: string | null;
  claimed_by_name: string | null;
  is_claimed: boolean;
  created_at: string;
}

interface InvitesResponse {
  codes: InviteCode[];
  total: number;
  page: number;
  pages: number;
}

export function InvitesPage() {
  const [data, setData] = useState<InvitesResponse | null>(null);
  const [page, setPage] = useState(1);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionError, setActionError] = useState<string | null>(null);
  const [creating, setCreating] = useState(false);

  const fetchInvites = useCallback(() => {
    setLoading(true);
    setError(null);
    apiFetch<InvitesResponse>(`/admin/invites?page=${page}`)
      .then(setData)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(() => {
    fetchInvites();
  }, [fetchInvites]);

  async function handleCreate() {
    setActionError(null);
    setCreating(true);
    try {
      await apiFetch('/admin/invites', { method: 'POST' });
      fetchInvites();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to create invite');
    } finally {
      setCreating(false);
    }
  }

  async function handleRevoke(codeId: string) {
    setActionError(null);
    try {
      await apiFetch(`/admin/invites/${codeId}`, { method: 'DELETE' });
      fetchInvites();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to revoke invite');
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Invite Codes</h1>
        <div className="flex gap-3">
          <Link
            to="/admin/invites/tree"
            className="px-4 py-2 border border-gray-300 text-gray-700 dark:border-gray-600 dark:text-gray-300 text-sm font-medium rounded-md hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
          >
            View Full Tree
          </Link>
          <button
            onClick={handleCreate}
            disabled={creating}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white text-sm font-medium rounded-md transition-colors"
          >
            {creating ? 'Creating...' : 'Create Invite'}
          </button>
        </div>
      </div>

      {(error || actionError) && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded text-red-700 text-sm dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
          {error || actionError}
        </div>
      )}

      <div className="bg-white dark:bg-gray-900 rounded-lg shadow overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Code</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Created By</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Claimed By</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Status</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Created</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {loading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <tr key={i} className="animate-pulse">
                  <td colSpan={6} className="px-4 py-3">
                    <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-full"></div>
                  </td>
                </tr>
              ))
            ) : data?.codes?.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-gray-400 dark:text-gray-500">
                  No invite codes found.
                </td>
              </tr>
            ) : (
              data?.codes.map((code) => (
                <tr key={code.id} className="hover:bg-gray-50 dark:hover:bg-gray-800">
                  <td className="px-4 py-3 font-mono text-gray-900 dark:text-white">{code.code}</td>
                  <td className="px-4 py-3">
                    <Link
                      to={`/admin/accounts/${code.created_by_id}`}
                      className="text-blue-600 hover:text-blue-800 dark:text-ev-teal-light dark:hover:text-ev-teal-light/80"
                    >
                      {code.created_by_name}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-gray-600 dark:text-gray-400">
                    {code.claimed_by_id ? (
                      <Link
                        to={`/admin/accounts/${code.claimed_by_id}`}
                        className="text-blue-600 hover:text-blue-800 dark:text-ev-teal-light dark:hover:text-ev-teal-light/80"
                      >
                        {code.claimed_by_name}
                      </Link>
                    ) : (
                      <span className="text-gray-400 dark:text-gray-500">Unclaimed</span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                        code.is_claimed
                          ? 'bg-green-100 text-green-700'
                          : 'bg-yellow-100 text-yellow-700'
                      }`}
                    >
                      {code.is_claimed ? 'Claimed' : 'Active'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-500 dark:text-gray-400">
                    {new Date(code.created_at).toLocaleDateString()}
                  </td>
                  <td className="px-4 py-3">
                    {!code.is_claimed && (
                      <button
                        onClick={() => handleRevoke(code.id)}
                        className="text-xs text-red-600 hover:text-red-800"
                      >
                        Revoke
                      </button>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {data && data.pages > 1 && (
        <div className="mt-4 flex items-center justify-between text-sm text-gray-600 dark:text-gray-400">
          <span>
            Page {data.page} of {data.pages} ({data.total} total)
          </span>
          <div className="flex gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page <= 1}
              className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              Previous
            </button>
            <button
              onClick={() => setPage((p) => Math.min(data.pages, p + 1))}
              disabled={page >= data.pages}
              className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
