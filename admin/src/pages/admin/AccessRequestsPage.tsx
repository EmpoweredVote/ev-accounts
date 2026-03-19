import { useEffect, useState, useCallback } from 'react';
import { apiFetch } from '../../lib/api';

interface AccessRequest {
  id: string;
  email: string;
  requested_at: string;
}

interface AccessRequestsResponse {
  requests: AccessRequest[];
}

export function AccessRequestsPage() {
  const [requests, setRequests] = useState<AccessRequest[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchRequests = useCallback(() => {
    setLoading(true);
    setError(null);
    apiFetch<AccessRequestsResponse>('/admin/access-requests')
      .then((data) => setRequests(data.requests))
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    fetchRequests();
  }, [fetchRequests]);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Access Requests
        </h1>
        <span className="text-sm text-gray-500 dark:text-gray-400">
          {requests.length} request{requests.length !== 1 ? 's' : ''}
        </span>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded-md text-sm dark:bg-red-900/20 dark:border-red-800 dark:text-red-400">
          {error}
        </div>
      )}

      {loading ? (
        <p className="text-gray-500 dark:text-gray-400">Loading...</p>
      ) : requests.length === 0 ? (
        <p className="text-gray-500 dark:text-gray-400">No access requests yet.</p>
      ) : (
        <div className="bg-white dark:bg-gray-900 shadow rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead className="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Email
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Requested At
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
              {requests.map((req) => (
                <tr key={req.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    {req.email}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                    {new Date(req.requested_at).toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
