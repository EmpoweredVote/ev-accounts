import { useEffect, useState, useCallback } from 'react';
import { apiFetch } from '../../lib/api';

interface CronRun {
  id: string;
  run_date: string;
  started_at: string;
  finished_at: string | null;
  warned_25d: number;
  warned_30d: number;
  demoted_count: number;
  error: string | null;
}

interface CronLogResponse {
  runs: CronRun[];
  total: number;
  page: number;
  pages: number;
}

export function CronLogPage() {
  const [data, setData] = useState<CronLogResponse | null>(null);
  const [page, setPage] = useState(1);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchLog = useCallback(() => {
    setLoading(true);
    setError(null);
    apiFetch<CronLogResponse>(`/admin/cron-log?page=${page}`)
      .then(setData)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(() => {
    fetchLog();
  }, [fetchLog]);

  function getRowClass(run: CronRun): string {
    if (run.error) return 'bg-red-50';
    if (!run.finished_at) return 'bg-yellow-50';
    return '';
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">Calibration Cron Log</h1>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded text-red-700 text-sm dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
          {error}
        </div>
      )}

      <div className="bg-white dark:bg-gray-900 rounded-lg shadow overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Run Date</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Started</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Finished</th>
              <th className="text-right px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Warned (25d)</th>
              <th className="text-right px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Warned (30d)</th>
              <th className="text-right px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Demoted</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Error</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {loading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <tr key={i} className="animate-pulse">
                  <td colSpan={7} className="px-4 py-3">
                    <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-full"></div>
                  </td>
                </tr>
              ))
            ) : data?.runs?.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-gray-400 dark:text-gray-500">
                  No cron runs recorded yet.
                </td>
              </tr>
            ) : (
              data?.runs.map((run) => (
                <tr key={run.id} className={`${getRowClass(run)} hover:bg-opacity-80`}>
                  <td className="px-4 py-3 font-medium text-gray-900 dark:text-white">
                    {new Date(run.run_date).toLocaleDateString()}
                  </td>
                  <td className="px-4 py-3 text-gray-600 dark:text-gray-400">
                    {new Date(run.started_at).toLocaleTimeString()}
                  </td>
                  <td className="px-4 py-3 text-gray-600 dark:text-gray-400">
                    {run.finished_at ? (
                      new Date(run.finished_at).toLocaleTimeString()
                    ) : (
                      <span className="text-yellow-600 font-medium">In progress</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-right text-gray-900 dark:text-white">{run.warned_25d}</td>
                  <td className="px-4 py-3 text-right text-gray-900 dark:text-white">{run.warned_30d}</td>
                  <td className="px-4 py-3 text-right font-medium">
                    <span className={run.demoted_count > 0 ? 'text-orange-600 dark:text-orange-400' : 'text-gray-900 dark:text-white'}>
                      {run.demoted_count}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-red-600 dark:text-red-400 text-xs max-w-xs truncate">
                    {run.error ?? <span className="text-gray-300 dark:text-gray-600">—</span>}
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
