import { useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../../lib/api';

interface StanceCount { id: string; value: number; text: string; count: number; }
interface BetweenCount { value: number; count: number; }
interface TopicBreakdown {
  topicId: string;
  title: string;
  shortTitle: string | null;
  isLive: boolean;
  totalResponses: number;
  writeInCount: number;
  stances: StanceCount[];
  betweens: BetweenCount[];
}
interface StanceBreakdownReport {
  totals: { responses: number; users: number };
  topics: TopicBreakdown[];
}

function pct(count: number, total: number): number {
  return total > 0 ? Math.round((count / total) * 100) : 0;
}

function StanceBar({ stance, total }: { stance: StanceCount; total: number }) {
  const width = total > 0 ? Math.max((stance.count / total) * 100, stance.count > 0 ? 2 : 0) : 0;
  return (
    <div className="flex items-center gap-2 text-sm">
      <span className="w-5 shrink-0 text-center text-xs font-medium text-gray-500 dark:text-gray-400">
        {stance.value}
      </span>
      <span className="w-64 shrink-0 truncate text-gray-700 dark:text-gray-300" title={stance.text}>
        {stance.text}
      </span>
      <div className="flex-1 h-4 rounded-sm bg-gray-100 dark:bg-gray-800">
        <div
          className="h-4 rounded-sm bg-ev-blue"
          style={{ width: `${width}%` }}
        />
      </div>
      <span className="w-20 shrink-0 text-right tabular-nums text-gray-600 dark:text-gray-400">
        {stance.count} · {pct(stance.count, total)}%
      </span>
    </div>
  );
}

function TopicCard({ topic }: { topic: TopicBreakdown }) {
  return (
    <div className="rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 p-4">
      <div className="flex items-baseline justify-between gap-4 mb-3">
        <h2 className="font-medium">
          {topic.title}
          {!topic.isLive && (
            <span className="ml-2 px-2 py-0.5 rounded text-xs bg-gray-200 text-gray-600 dark:bg-gray-700 dark:text-gray-300">
              not live
            </span>
          )}
        </h2>
        <span className="text-sm text-gray-500 dark:text-gray-400 whitespace-nowrap">
          {topic.totalResponses} response{topic.totalResponses === 1 ? '' : 's'}
        </span>
      </div>
      <div className="space-y-1.5">
        {topic.stances.map((s) => (
          <StanceBar key={s.value} stance={s} total={topic.totalResponses} />
        ))}
      </div>
      {(topic.betweens.length > 0 || topic.writeInCount > 0) && (
        <p className="mt-3 text-xs text-gray-500 dark:text-gray-400">
          {topic.betweens.length > 0 && (
            <>
              Between-stance placements:{' '}
              {topic.betweens.map((b) => `${b.value} ×${b.count}`).join(', ')}
              {' — '}
            </>
          )}
          {topic.writeInCount} write-in{topic.writeInCount === 1 ? '' : 's'}
        </p>
      )}
    </div>
  );
}

export function StanceBreakdownPage() {
  const [report, setReport] = useState<StanceBreakdownReport | null>(null);
  const [error, setError] = useState('');
  const [query, setQuery] = useState('');
  const [onlyAnswered, setOnlyAnswered] = useState(true);

  useEffect(() => {
    apiFetch<StanceBreakdownReport>('/admin/compass-stats')
      .then(setReport)
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load'));
  }, []);

  const visible = useMemo(() => {
    if (!report) return [];
    const q = query.trim().toLowerCase();
    return report.topics.filter(
      (t) =>
        (!onlyAnswered || t.totalResponses > 0) &&
        (q === '' ||
          t.title.toLowerCase().includes(q) ||
          (t.shortTitle ?? '').toLowerCase().includes(q))
    );
  }, [report, query, onlyAnswered]);

  const answeredCount = report?.topics.filter((t) => t.totalResponses > 0).length ?? 0;

  return (
    <div className="p-6">
      <h1 className="text-2xl font-semibold mb-1">Compass — Stance Breakdown</h1>
      <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">
        How many users selected each stance, per topic. Half-step values are write-in
        placements between stances and are listed separately, never rounded into a stance.
      </p>

      {error && <p className="text-ev-red mb-4">{error}</p>}
      {!report && !error && <p>Loading…</p>}

      {report && (
        <>
          <div className="flex flex-wrap gap-4 mb-6 text-sm">
            <span className="px-3 py-1.5 rounded bg-gray-100 dark:bg-gray-800">
              <strong>{report.totals.responses}</strong> responses
            </span>
            <span className="px-3 py-1.5 rounded bg-gray-100 dark:bg-gray-800">
              <strong>{report.totals.users}</strong> users
            </span>
            <span className="px-3 py-1.5 rounded bg-gray-100 dark:bg-gray-800">
              <strong>{answeredCount}</strong> of {report.topics.length} topics answered
            </span>
          </div>

          <div className="flex flex-wrap items-center gap-4 mb-4">
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Filter topics…"
              className="border rounded px-3 py-2 w-72 dark:bg-gray-800 dark:border-gray-600"
            />
            <label className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
              <input
                type="checkbox"
                checked={onlyAnswered}
                onChange={(e) => setOnlyAnswered(e.target.checked)}
              />
              Only topics with responses
            </label>
          </div>

          {visible.length === 0 ? (
            <p className="text-gray-500">No topics match.</p>
          ) : (
            <div className="space-y-4">
              {visible.map((t) => (
                <TopicCard key={t.topicId} topic={t} />
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
