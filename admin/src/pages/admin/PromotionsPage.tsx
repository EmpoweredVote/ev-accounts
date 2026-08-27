import { useEffect, useState } from 'react';
import { Link } from 'react-router';
import { apiFetch } from '../../lib/api';

interface PromotionEntry {
  id: string;
  admin_email: string;
  target_user_id: string;
  target_display_name: string;
  previous_tier: string;
  new_tier: string;
  note: string | null;
  created_at: string;
}

interface PromotionsResponse {
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

export function PromotionsPage() {
  const [data, setData] = useState<PromotionsResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);

  useEffect(() => {
    setLoading(true);
    setError(null);
    apiFetch<PromotionsResponse>(`/admin/promotions?page=${page}`)
      .then(setData)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [page]);

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-1">Tier Promotions</h1>
      <p className="text-sm text-gray-500 dark:text-gray-400 mb-6">All tier promotion events across all users.</p>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded text-red-700 text-sm dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
          {error}
        </div>
      )}

      <div className="bg-white dark:bg-gray-900 rounded-lg shadow overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Date</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Target User</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Admin</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Previous Tier</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">New Tier</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Note</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {loading ? (
              <tr>
                <td colSpan={6} className="px-4 py-6 text-center text-gray-400 dark:text-gray-500 text-sm">
                  Loading...
                </td>
              </tr>
            ) : data?.entries?.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-gray-400 dark:text-gray-500">
                  No promotions recorded yet.
                </td>
              </tr>
            ) : (
              data?.entries.map((entry) => (
                <tr key={entry.id} className="hover:bg-gray-50 dark:hover:bg-gray-800">
                  <td className="px-4 py-3 text-gray-500 dark:text-gray-400 whitespace-nowrap">
                    {new Date(entry.created_at).toLocaleString()}
                  </td>
                  <td className="px-4 py-3">
                    <Link
                      to={`/admin/accounts/${entry.target_user_id}`}
                      className="text-blue-600 hover:underline font-medium dark:text-ev-teal-light dark:hover:text-ev-teal-light/80"
                    >
                      {entry.target_display_name}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-gray-600 dark:text-gray-400">{entry.admin_email}</td>
                  <td className="px-4 py-3">
                    <span
                      className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${TIER_BADGE[entry.previous_tier] ?? 'bg-gray-100 text-gray-700'}`}
                    >
                      {entry.previous_tier}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${TIER_BADGE[entry.new_tier] ?? 'bg-gray-100 text-gray-700'}`}
                    >
                      {entry.new_tier}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-500 dark:text-gray-400">{entry.note ?? '—'}</td>
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
