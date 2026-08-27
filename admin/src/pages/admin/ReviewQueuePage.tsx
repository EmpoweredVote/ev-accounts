import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router';
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

/**
 * One queue's outcome. `rows` is meaningless unless `error` is null — an empty
 * array and a failed fetch are DIFFERENT states and must not render the same.
 * Collapsing them is how "we could not load this" becomes "there is nothing
 * here", which is the more dangerous of the two because it looks like good news.
 */
interface QueueState<T> {
  rows: T[];
  error: string | null;
}

const EMPTY = <T,>(): QueueState<T> => ({ rows: [], error: null });

function reason(err: unknown, what: string): string {
  return err instanceof Error ? err.message : `Failed to load ${what}`;
}

/** Settle a queue fetch into a QueueState instead of throwing. */
async function settle<T>(what: string, fn: () => Promise<T[]>): Promise<QueueState<T>> {
  try {
    return { rows: await fn(), error: null };
  } catch (err) {
    return { rows: [], error: reason(err, what) };
  }
}

function Badge({ q }: { q: QueueState<unknown> }) {
  // A count of 0 beside a failed fetch would assert something we do not know.
  if (q.error) {
    return (
      <span
        title={q.error}
        className="ml-1.5 text-xs bg-amber-100 dark:bg-amber-900/50 text-amber-800 dark:text-amber-300 px-1.5 py-0.5 rounded"
      >
        !
      </span>
    );
  }
  return (
    <span className="ml-1.5 text-xs bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 px-1.5 py-0.5 rounded">
      {q.rows.length}
    </span>
  );
}

function LoadError({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="text-center py-12">
      <p className="text-sm text-amber-700 dark:text-amber-400">Could not load this queue.</p>
      <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">{message}</p>
      <button onClick={onRetry} className="mt-3 text-sm underline text-gray-600 dark:text-gray-300">
        Retry
      </button>
    </div>
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

  const [stances, setStances] = useState<QueueState<StagingStance>>(EMPTY);
  const [politicians, setPoliticians] = useState<QueueState<StagingPolitician>>(EMPTY);
  const [research, setResearch] = useState<QueueState<ResearchReviewRow>>(EMPTY);
  const [topicRevisions, setTopicRevisions] = useState<QueueState<TopicRevisionRow>>(EMPTY);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadData(); }, []);

  /**
   * Each queue is fetched and settled INDEPENDENTLY.
   *
   * This used to be a Promise.all. apiFetch throws on any non-2xx, and
   * Promise.all rejects on the first rejection — so a single failing endpoint
   * replaced the whole page with one error, hiding the queues that had loaded
   * perfectly well. One backend hiccup made every review queue unreachable.
   *
   * Now a failure is scoped to the tab it belongs to: the other tabs still work,
   * the failed tab says so and offers a retry, and its badge shows "!" rather
   * than a zero it cannot justify.
   */
  async function loadData() {
    setLoading(true);
    const [s, p, r, t] = await Promise.all([
      settle('stances', () => apiFetch<StagingStance[]>('/staging/stances?status=needs_review')),
      settle('politicians', () => apiFetch<StagingPolitician[]>('/staging/politicians?status=needs_review')),
      settle('research review', () => apiFetch<ResearchReviewRow[]>('/admin/research-review')),
      settle('topic revisions', async () =>
        (await apiFetch<{ revisions: TopicRevisionRow[] }>('/compass/revisions/queue')).revisions
      ),
    ]);
    setStances(s);
    setPoliticians(p);
    setResearch(r);
    setTopicRevisions(t);
    setLoading(false);
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
          { key: 'stances', label: 'Stances', queue: stances, params: {} },
          { key: 'politicians', label: 'Politicians', queue: politicians, params: { tab: 'politicians' } },
          { key: 'research', label: 'Research Review', queue: research, params: { tab: 'research' } },
          { key: 'topics', label: 'Topic Revisions', queue: topicRevisions, params: { tab: 'topics' } },
        ] as const).map(({ key, label, queue, params }) => (
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
            {!loading && <Badge q={queue} />}
          </button>
        ))}
      </div>

      {loading ? (
        <p className="text-sm text-gray-500 dark:text-gray-400">Loading...</p>
      ) : tab === 'stances' ? (
        stances.error ? (
          <LoadError message={stances.error} onRetry={loadData} />
        ) : stances.rows.length === 0 ? (
          <Empty message="No stances pending review." />
        ) : (
          <div className="space-y-2">
            {stances.rows.map((stance) => (
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
        politicians.error ? (
          <LoadError message={politicians.error} onRetry={loadData} />
        ) : politicians.rows.length === 0 ? (
          <Empty message="No politicians pending review." />
        ) : (
          <div className="space-y-2">
            {politicians.rows.map((politician) => (
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
        topicRevisions.error ? (
          <LoadError message={topicRevisions.error} onRetry={loadData} />
        ) : topicRevisions.rows.length === 0 ? (
          <Empty message="No topic revisions pending review." />
        ) : (
          <div className="space-y-2">
            {topicRevisions.rows.map((rev) => (
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
      ) : research.error ? (
        <LoadError message={research.error} onRetry={loadData} />
      ) : research.rows.length === 0 ? (
        <Empty message="No research stances pending review." />
      ) : (
        <div className="space-y-2">
          {research.rows.map((row) => (
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
