import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { apiFetch } from '../../lib/api';

interface StagingStance {
  id: string;
  politician_name: string;
  topic_key: string;
  value: number;
  review_count: number;
  added_by: string;
}

interface StagingPolitician {
  id: string;
  full_name: string;
  office: string;
  state: string;
  office_level: string;
  review_count: number;
  added_by: string;
}

export function ReviewQueuePage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const tab = searchParams.get('tab') === 'politicians' ? 'politicians' : 'stances';

  const [stances, setStances] = useState<StagingStance[]>([]);
  const [politicians, setPoliticians] = useState<StagingPolitician[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    setError(null);
    try {
      const [stancesData, politiciansData] = await Promise.all([
        apiFetch<StagingStance[]>('/staging/stances?status=needs_review'),
        apiFetch<StagingPolitician[]>('/staging/politicians?status=needs_review'),
      ]);
      setStances(stancesData);
      setPoliticians(politiciansData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load queue');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Review Queue</h1>
        <button
          onClick={loadData}
          className="text-sm text-gray-500 hover:text-gray-900 dark:hover:text-white transition-colors"
        >
          Refresh
        </button>
      </div>

      <div className="flex gap-1 mb-6 border-b border-gray-200 dark:border-gray-700">
        <button
          onClick={() => setSearchParams({})}
          className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors ${
            tab === 'stances'
              ? 'border-ev-red text-ev-red'
              : 'border-transparent text-gray-500 hover:text-gray-900 dark:hover:text-white'
          }`}
        >
          Stances
          {!loading && (
            <span className="ml-1.5 text-xs bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 px-1.5 py-0.5 rounded">
              {stances.length}
            </span>
          )}
        </button>
        <button
          onClick={() => setSearchParams({ tab: 'politicians' })}
          className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors ${
            tab === 'politicians'
              ? 'border-ev-red text-ev-red'
              : 'border-transparent text-gray-500 hover:text-gray-900 dark:hover:text-white'
          }`}
        >
          Politicians
          {!loading && (
            <span className="ml-1.5 text-xs bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 px-1.5 py-0.5 rounded">
              {politicians.length}
            </span>
          )}
        </button>
      </div>

      {loading ? (
        <p className="text-sm text-gray-500 dark:text-gray-400">Loading...</p>
      ) : error ? (
        <div className="text-red-600 dark:text-red-400">
          <p className="text-sm">{error}</p>
          <button onClick={loadData} className="mt-2 text-sm underline">
            Retry
          </button>
        </div>
      ) : tab === 'stances' ? (
        stances.length === 0 ? (
          <div className="text-center py-12 text-gray-500 dark:text-gray-400">
            <p className="text-sm">No stances pending review.</p>
          </div>
        ) : (
          <div className="space-y-2">
            {stances.map((stance) => (
              <Link
                key={stance.id}
                to={`/admin/review/stances/${stance.id}`}
                className="flex items-center justify-between p-4 bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-ev-red dark:hover:border-ev-red transition-colors"
              >
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">{stance.politician_name}</p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">{stance.topic_key}</p>
                </div>
                <div className="text-right text-sm text-gray-500 dark:text-gray-400">
                  <p>by {stance.added_by}</p>
                  {stance.review_count > 0 && (
                    <p className="text-xs">{stance.review_count}/2 approvals</p>
                  )}
                </div>
              </Link>
            ))}
          </div>
        )
      ) : politicians.length === 0 ? (
        <div className="text-center py-12 text-gray-500 dark:text-gray-400">
          <p className="text-sm">No politicians pending review.</p>
        </div>
      ) : (
        <div className="space-y-2">
          {politicians.map((politician) => (
            <Link
              key={politician.id}
              to={`/admin/review/politicians/${politician.id}`}
              className="flex items-center justify-between p-4 bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-ev-red dark:hover:border-ev-red transition-colors"
            >
              <div>
                <p className="font-medium text-gray-900 dark:text-white">{politician.full_name}</p>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {politician.office}
                  {politician.state ? ` — ${politician.state}` : ''}
                </p>
              </div>
              <div className="text-right text-sm text-gray-500 dark:text-gray-400">
                <p>by {politician.added_by}</p>
                {politician.review_count > 0 && (
                  <p className="text-xs">{politician.review_count}/2 approvals</p>
                )}
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
