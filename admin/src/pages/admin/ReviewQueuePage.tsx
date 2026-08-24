import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { apiFetch } from '../../lib/api';

interface StagingStance {
  id: string;
  politicianName: string;
  topicKey: string;
  value: number;
  reviewCount: number;
  addedBy: string;
}

interface StagingPolitician {
  id: string;
  fullName: string;
  office: string;
  state: string;
  officeLevel: string;
  reviewCount: number;
  addedBy: string;
}

interface ResearchReviewRow {
  id: string;
  fullNameRaw: string;
  topicKey: string;
  proposedValue: number | null;
  verifiedSourceCount: number;
  threshold: number;
  batchId: string;
}

interface TopicRevisionRow {
  id: string;
  topicKey: string;
  revision: number;
  version: number;
  changeClass: string;
  status: string;
  title: string;
  publicNote: string;
  proposedByName: string | null;
  ladderChanged: boolean;
}

type Tab = 'stances' | 'politicians' | 'research' | 'topics';

function Badge({ n }: { n: number }) {
  return (
    <span className="ml-1.5 text-xs bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 px-1.5 py-0.5 rounded">
      {n}
    </span>
  );
}

export function ReviewQueuePage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const rawTab = searchParams.get('tab');
  const tab: Tab =
    rawTab === 'politicians' ? 'politicians'
    : rawTab === 'research' ? 'research'
    : rawTab === 'topics' ? 'topics'
    : 'stances';

  const [stances, setStances] = useState<StagingStance[]>([]);
  const [politicians, setPoliticians] = useState<StagingPolitician[]>([]);
  const [research, setResearch] = useState<ResearchReviewRow[]>([]);
  const [topicRevisions, setTopicRevisions] = useState<TopicRevisionRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    setError(null);
    try {
      const [stancesData, politiciansData, researchData] = await Promise.all([
        apiFetch<StagingStance[]>('/staging/stances?status=needs_review'),
        apiFetch<StagingPolitician[]>('/staging/politicians?status=needs_review'),
        apiFetch<ResearchReviewRow[]>('/admin/research-review'),
      ]);
      setStances(stancesData);
      setPoliticians(politiciansData);
      setResearch(researchData);

      // Deliberately NOT in the Promise.all above. apiFetch throws on a non-2xx,
      // so folding a fourth endpoint into that array would let one failure blank
      // the entire queue — including the three tabs that loaded fine. This tab
      // degrades to empty on its own.
      try {
        const { revisions } = await apiFetch<{ revisions: TopicRevisionRow[] }>(
          '/compass/revisions/queue'
        );
        setTopicRevisions(revisions);
      } catch {
        setTopicRevisions([]);
      }
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
        {([
          { key: 'stances', label: 'Stances', count: stances.length, params: {} },
          { key: 'politicians', label: 'Politicians', count: politicians.length, params: { tab: 'politicians' } },
          { key: 'research', label: 'Research Review', count: research.length, params: { tab: 'research' } },
          { key: 'topics', label: 'Topic Revisions', count: topicRevisions.length, params: { tab: 'topics' } },
        ] as const).map(({ key, label, count, params }) => (
          <button
            key={key}
            onClick={() => setSearchParams(params)}
            className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors ${
              tab === key
                ? 'border-ev-red text-ev-red'
                : 'border-transparent text-gray-500 hover:text-gray-900 dark:hover:text-white'
            }`}
          >
            {label}
            {!loading && <Badge n={count} />}
          </button>
        ))}
      </div>

      {loading ? (
        <p className="text-sm text-gray-500 dark:text-gray-400">Loading...</p>
      ) : error ? (
        <div className="text-red-600 dark:text-red-400">
          <p className="text-sm">{error}</p>
          <button onClick={loadData} className="mt-2 text-sm underline">Retry</button>
        </div>
      ) : tab === 'stances' ? (
        stances.length === 0 ? (
          <Empty message="No stances pending review." />
        ) : (
          <div className="space-y-2">
            {stances.map((stance) => (
              <Link
                key={stance.id}
                to={`/admin/review/stances/${stance.id}`}
                className="flex items-center justify-between p-4 bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-ev-red dark:hover:border-ev-red transition-colors"
              >
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">{stance.politicianName}</p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">{stance.topicKey}</p>
                </div>
                <div className="text-right text-sm text-gray-500 dark:text-gray-400">
                  <p>by {stance.addedBy}</p>
                  {stance.reviewCount > 0 && <p className="text-xs">{stance.reviewCount}/2 approvals</p>}
                </div>
              </Link>
            ))}
          </div>
        )
      ) : tab === 'politicians' ? (
        politicians.length === 0 ? (
          <Empty message="No politicians pending review." />
        ) : (
          <div className="space-y-2">
            {politicians.map((politician) => (
              <Link
                key={politician.id}
                to={`/admin/review/politicians/${politician.id}`}
                className="flex items-center justify-between p-4 bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-ev-red dark:hover:border-ev-red transition-colors"
              >
                <div>
                  <p className="font-medium text-gray-900 dark:text-white">{politician.fullName}</p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    {politician.office}{politician.state ? ` — ${politician.state}` : ''}
                  </p>
                </div>
                <div className="text-right text-sm text-gray-500 dark:text-gray-400">
                  <p>by {politician.addedBy}</p>
                  {politician.reviewCount > 0 && <p className="text-xs">{politician.reviewCount}/2 approvals</p>}
                </div>
              </Link>
            ))}
          </div>
        )
      ) : tab === 'topics' ? (
        topicRevisions.length === 0 ? (
          <Empty message="No topic revisions pending review." />
        ) : (
          <div className="space-y-2">
            {topicRevisions.map((rev) => (
              <Link
                key={rev.id}
                to={`/admin/review/topics/${rev.id}`}
                className="flex items-center justify-between p-4 bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-ev-red dark:hover:border-ev-red transition-colors"
              >
                <div className="min-w-0 pr-4">
                  <p className="font-medium text-gray-900 dark:text-white">{rev.topicKey}</p>
                  <p className="text-sm text-gray-500 dark:text-gray-400 line-clamp-2">{rev.publicNote}</p>
                </div>
                <div className="text-right text-sm text-gray-500 dark:text-gray-400 whitespace-nowrap">
                  <p className="font-medium text-gray-700 dark:text-gray-300">v{rev.version} · {rev.status}</p>
                  <p className="text-xs">
                    {rev.changeClass}{rev.ladderChanged ? ' · ladder changed' : ''}
                  </p>
                </div>
              </Link>
            ))}
          </div>
        )
      ) : research.length === 0 ? (
        <Empty message="No research stances pending review." />
      ) : (
        <div className="space-y-2">
          {research.map((row) => (
            <Link
              key={row.id}
              to={`/admin/review/research/${row.id}`}
              className="flex items-center justify-between p-4 bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-ev-red dark:hover:border-ev-red transition-colors"
            >
              <div>
                <p className="font-medium text-gray-900 dark:text-white">{row.fullNameRaw}</p>
                <p className="text-sm text-gray-500 dark:text-gray-400">{row.topicKey}</p>
              </div>
              <div className="text-right text-sm text-gray-500 dark:text-gray-400">
                {row.proposedValue !== null && (
                  <p className="font-medium text-gray-700 dark:text-gray-300">value {row.proposedValue}</p>
                )}
                <p className="text-xs">
                  {row.verifiedSourceCount}/{row.threshold} sources verified
                </p>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

function Empty({ message }: { message: string }) {
  return (
    <div className="text-center py-12 text-gray-500 dark:text-gray-400">
      <p className="text-sm">{message}</p>
    </div>
  );
}
