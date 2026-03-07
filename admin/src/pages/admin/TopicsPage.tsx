import { useEffect, useState } from 'react';
import { apiFetch } from '../../lib/api';

export function TopicsPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    apiFetch<{ topics: unknown[] }>('/admin/compass/topics')
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Topics</h1>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded text-red-700 text-sm">{error}</div>
      )}

      {loading ? (
        <div className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="animate-pulse h-10 bg-gray-200 rounded w-full"></div>
          ))}
        </div>
      ) : (
        <p className="text-gray-500">No topics yet.</p>
      )}
    </div>
  );
}
