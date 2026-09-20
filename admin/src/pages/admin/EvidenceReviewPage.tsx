import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { apiFetch } from '../../lib/api';
import { statusBadge, flagReasons, pct, REJECT_REASONS } from './evidenceReviewFormat';

type RejectReason = (typeof REJECT_REASONS)[number];

interface PendingCandidate {
  politicianId: string;
  name: string;
  pendingGreen: number;
  pendingFlagged: number;
}

interface EvidenceRow {
  id: string;
  issue: string;
  topicId: string | null;
  evidenceType: string;
  verbatimText: string;
  sourceUrl: string;
  deepLink: string | null;
  context: string | null;
  sourceType: string;
  machineStatus: string;
  gateFlags: unknown;
  provenance: unknown;
  createdAt: string;
}

interface PrecisionRow {
  precision: number | null;
  accepted: number;
  rejected: number;
}
interface ByStatusRow extends PrecisionRow { machineStatus: string; }
interface ByIssueRow extends PrecisionRow { issue: string; }
interface ByModelRow extends PrecisionRow { model: string | null; }
interface RejectReasonRow { reason: string; n: number; }

interface EvidenceMetrics {
  byStatus: ByStatusRow[];
  byIssue: ByIssueRow[];
  byModel: ByModelRow[];
  topRejectReasons: RejectReasonRow[];
}

interface Topic {
  id: string;
  title: string;
  short_title: string | null;
  question_text: string;
  is_live: boolean;
  created_at: string;
}

type StatusFilter = 'all' | 'green' | 'flagged';

const BADGE_STYLE: Record<'green' | 'flagged', string> = {
  green: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
  flagged: 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300',
};

function LoadError({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="text-center py-8">
      <p className="text-sm text-amber-700 dark:text-amber-400">Could not load this.</p>
      <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">{message}</p>
      <button onClick={onRetry} className="mt-2 text-sm underline text-gray-600 dark:text-gray-300">
        Retry
      </button>
    </div>
  );
}

export function EvidenceReviewPage() {
  const [candidates, setCandidates] = useState<PendingCandidate[]>([]);
  const [candidatesLoading, setCandidatesLoading] = useState(true);
  const [candidatesError, setCandidatesError] = useState<string | null>(null);

  const [metrics, setMetrics] = useState<EvidenceMetrics | null>(null);
  const [metricsLoading, setMetricsLoading] = useState(true);
  const [metricsError, setMetricsError] = useState<string | null>(null);

  const [topics, setTopics] = useState<Topic[]>([]);
  const topicById = useMemo(() => {
    const m = new Map<string, string>();
    for (const t of topics) m.set(t.id, t.title);
    return m;
  }, [topics]);

  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [items, setItems] = useState<EvidenceRow[]>([]);
  const [itemsLoading, setItemsLoading] = useState(false);
  const [itemsError, setItemsError] = useState<string | null>(null);

  const [issueInput, setIssueInput] = useState('');
  const [appliedIssue, setAppliedIssue] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');

  const [savingId, setSavingId] = useState<string | null>(null);
  const [cardErrors, setCardErrors] = useState<Record<string, string>>({});

  async function loadCandidates() {
    setCandidatesLoading(true);
    setCandidatesError(null);
    try {
      setCandidates(await apiFetch<PendingCandidate[]>('/admin/evidence/candidates'));
    } catch (err) {
      setCandidatesError(err instanceof Error ? err.message : 'Failed to load candidates');
    } finally {
      setCandidatesLoading(false);
    }
  }

  async function loadMetrics() {
    setMetricsLoading(true);
    setMetricsError(null);
    try {
      setMetrics(await apiFetch<EvidenceMetrics>('/admin/evidence/metrics'));
    } catch (err) {
      setMetricsError(err instanceof Error ? err.message : 'Failed to load metrics');
    } finally {
      setMetricsLoading(false);
    }
  }

  useEffect(() => {
    loadCandidates();
    loadMetrics();
    // Topic picker degrades to "no topic" if this fails — non-fatal, so no
    // error state of its own.
    apiFetch<{ topics: Topic[] }>('/admin/compass/topics')
      .then((d) => setTopics(d.topics))
      .catch(() => {});
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function loadItems(politicianId: string, issue: string, status: StatusFilter) {
    setItemsLoading(true);
    setItemsError(null);
    try {
      const qs = new URLSearchParams({ politician_id: politicianId });
      if (issue) qs.set('issue', issue);
      if (status !== 'all') qs.set('machine_status', status);
      setItems(await apiFetch<EvidenceRow[]>(`/admin/evidence?${qs.toString()}`));
    } catch (err) {
      setItemsError(err instanceof Error ? err.message : 'Failed to load evidence');
    } finally {
      setItemsLoading(false);
    }
  }

  // Filters are read here, not inside selectCandidate — one effect owns every
  // reason the item list can change, so an action's refresh and a filter edit
  // can't race and leave items and filters showing different candidates.
  useEffect(() => {
    if (!selectedId) { setItems([]); return; }
    loadItems(selectedId, appliedIssue, statusFilter);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedId, appliedIssue, statusFilter]);

  function selectCandidate(politicianId: string) {
    setSelectedId(politicianId);
    setIssueInput('');
    setAppliedIssue('');
    setStatusFilter('all');
  }

  function applyIssueFilter(e: FormEvent) {
    e.preventDefault();
    setAppliedIssue(issueInput.trim());
  }

  // Shared tail of every accept/reject/re-home: the item leaves the pending
  // set, so re-fetching (rather than splicing local state) is what actually
  // removes its card, and the candidate list / metrics panel move in lockstep
  // with it instead of quietly going stale.
  async function refreshAfterAction() {
    const tasks: Promise<unknown>[] = [loadCandidates(), loadMetrics()];
    if (selectedId) tasks.push(loadItems(selectedId, appliedIssue, statusFilter));
    await Promise.all(tasks);
  }

  function setCardError(id: string, message: string | null) {
    setCardErrors((prev) => {
      const next = { ...prev };
      if (message) next[id] = message; else delete next[id];
      return next;
    });
  }

  async function handleAccept(id: string) {
    setSavingId(id);
    setCardError(id, null);
    try {
      await apiFetch(`/admin/evidence/${id}/accept`, { method: 'POST' });
      await refreshAfterAction();
    } catch (err) {
      setCardError(id, err instanceof Error ? err.message : 'Failed to accept');
    } finally {
      setSavingId(null);
    }
  }

  async function handleReject(id: string, reason: RejectReason, note: string) {
    setSavingId(id);
    setCardError(id, null);
    try {
      await apiFetch(`/admin/evidence/${id}/reject`, {
        method: 'POST',
        body: JSON.stringify({ reason, note: note.trim() || undefined }),
      });
      await refreshAfterAction();
    } catch (err) {
      setCardError(id, err instanceof Error ? err.message : 'Failed to reject');
    } finally {
      setSavingId(null);
    }
  }

  async function handleRehome(id: string, topicId: string | null, issue: string) {
    setSavingId(id);
    setCardError(id, null);
    try {
      await apiFetch(`/admin/evidence/${id}/rehome`, {
        method: 'POST',
        body: JSON.stringify({ topic_id: topicId, issue }),
      });
      await refreshAfterAction();
    } catch (err) {
      setCardError(id, err instanceof Error ? err.message : 'Failed to re-home');
    } finally {
      setSavingId(null);
    }
  }

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Evidence Review</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Accept, reject, or re-home gathered stance evidence before it reaches Read &amp; Rank.
        </p>
      </div>

      <MetricsPanel metrics={metrics} loading={metricsLoading} error={metricsError} onRetry={loadMetrics} />

      <div className="flex gap-6 items-start">
        <aside className="w-64 shrink-0">
          <h2 className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-2">
            Candidates
          </h2>
          {candidatesLoading ? (
            <p className="text-sm text-gray-500 dark:text-gray-400">Loading…</p>
          ) : candidatesError ? (
            <LoadError message={candidatesError} onRetry={loadCandidates} />
          ) : candidates.length === 0 ? (
            <p className="text-sm text-gray-500 dark:text-gray-400">Nothing pending review.</p>
          ) : (
            <div className="space-y-1">
              {candidates.map((c) => (
                <button
                  key={c.politicianId}
                  onClick={() => selectCandidate(c.politicianId)}
                  className={`w-full text-left px-3 py-2.5 rounded-md border transition-colors ${
                    selectedId === c.politicianId
                      ? 'border-ev-red bg-red-50 dark:bg-ev-red/10 dark:border-ev-red'
                      : 'border-transparent hover:border-gray-200 dark:hover:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800/50'
                  }`}
                >
                  <p className="text-sm font-medium text-gray-900 dark:text-white truncate">{c.name}</p>
                  <div className="mt-1 flex gap-1.5 flex-wrap">
                    {c.pendingGreen > 0 && (
                      <span className="text-xs px-1.5 py-0.5 rounded bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400">
                        {c.pendingGreen} green
                      </span>
                    )}
                    {c.pendingFlagged > 0 && (
                      <span className="text-xs px-1.5 py-0.5 rounded bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300">
                        {c.pendingFlagged} flagged
                      </span>
                    )}
                  </div>
                </button>
              ))}
            </div>
          )}
        </aside>

        <section className="flex-1 min-w-0">
          {!selectedId ? (
            <div className="text-center py-16 text-gray-500 dark:text-gray-400">
              <p className="text-sm">Select a candidate on the left to review their pending evidence.</p>
            </div>
          ) : (
            <>
              <form onSubmit={applyIssueFilter} className="flex flex-wrap items-center gap-3 mb-4">
                <div className="flex-1 min-w-[220px]">
                  <input
                    value={issueInput}
                    onChange={(e) => setIssueInput(e.target.value)}
                    placeholder="Filter by issue…"
                    className="w-full border border-gray-300 dark:border-gray-600 rounded px-3 py-1.5 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-blue"
                  />
                  <p className="mt-0.5 text-[11px] text-gray-400 dark:text-gray-500">Exact match</p>
                </div>
                <button
                  type="submit"
                  className="text-sm px-3 py-1.5 rounded border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:border-ev-blue transition-colors"
                >
                  Apply
                </button>
                {appliedIssue && (
                  <button
                    type="button"
                    onClick={() => { setIssueInput(''); setAppliedIssue(''); }}
                    className="text-xs text-gray-500 dark:text-gray-400 hover:text-ev-red transition-colors"
                  >
                    Clear
                  </button>
                )}
                <div className="flex gap-0.5 ml-auto rounded-md border border-gray-200 dark:border-gray-700 p-0.5 shrink-0">
                  {(['all', 'green', 'flagged'] as const).map((s) => (
                    <button
                      key={s}
                      type="button"
                      onClick={() => setStatusFilter(s)}
                      className={`text-xs px-2.5 py-1 rounded transition-colors ${
                        statusFilter === s
                          ? 'bg-ev-black text-white dark:bg-white dark:text-gray-900'
                          : 'text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800'
                      }`}
                    >
                      {s === 'all' ? 'All' : s === 'green' ? 'Green' : 'Flagged'}
                    </button>
                  ))}
                </div>
              </form>

              {itemsLoading ? (
                <p className="text-sm text-gray-500 dark:text-gray-400">Loading…</p>
              ) : itemsError ? (
                <LoadError message={itemsError} onRetry={() => loadItems(selectedId, appliedIssue, statusFilter)} />
              ) : items.length === 0 ? (
                <div className="text-center py-12 text-gray-500 dark:text-gray-400">
                  <p className="text-sm">No pending evidence matches these filters.</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {items.map((item) => (
                    <EvidenceCard
                      key={item.id}
                      item={item}
                      topicTitle={item.topicId ? topicById.get(item.topicId) ?? item.topicId : null}
                      topics={topics}
                      saving={savingId === item.id}
                      error={cardErrors[item.id]}
                      onAccept={() => handleAccept(item.id)}
                      onReject={(reason, note) => handleReject(item.id, reason, note)}
                      onRehome={(topicId, issue) => handleRehome(item.id, topicId, issue)}
                    />
                  ))}
                </div>
              )}
            </>
          )}
        </section>
      </div>
    </div>
  );
}

function MetricsPanel({
  metrics, loading, error, onRetry,
}: {
  metrics: EvidenceMetrics | null;
  loading: boolean;
  error: string | null;
  onRetry: () => void;
}) {
  return (
    <section className="mb-6 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 p-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">
          Review accuracy
        </h2>
        {loading && <span className="text-xs text-gray-400 dark:text-gray-500">Loading…</span>}
      </div>

      {error && <LoadError message={error} onRetry={onRetry} />}

      {metrics && (
        <div className="mt-3 flex flex-wrap items-start gap-8">
          {metrics.byStatus.length === 0 ? (
            <p className="text-sm text-gray-500 dark:text-gray-400">No accepted or rejected evidence yet.</p>
          ) : (
            metrics.byStatus.map((s) => (
              <div key={s.machineStatus}>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">{pct(s.precision)}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {s.machineStatus} precision · {s.accepted} accepted / {s.rejected} rejected
                </p>
              </div>
            ))
          )}
          {metrics.topRejectReasons.length > 0 && (
            <div className="flex-1 min-w-[240px]">
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-1.5">Top reject reasons</p>
              <div className="flex flex-wrap gap-1.5">
                {metrics.topRejectReasons.map((r) => (
                  <span
                    key={r.reason}
                    className="text-xs px-2 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300"
                  >
                    {r.reason} <span className="text-gray-400 dark:text-gray-500">×{r.n}</span>
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {metrics && (metrics.byIssue.length > 0 || metrics.byModel.length > 0) && (
        <details className="mt-4">
          <summary className="text-xs text-gray-500 dark:text-gray-400 cursor-pointer hover:text-gray-900 dark:hover:text-white transition-colors">
            Detail by issue / model
          </summary>
          <div className="mt-2 grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p className="text-xs font-medium text-gray-500 dark:text-gray-400 mb-1">By issue</p>
              <ul className="space-y-0.5">
                {metrics.byIssue.map((i) => (
                  <li key={i.issue} className="text-xs text-gray-600 dark:text-gray-300 flex justify-between gap-2">
                    <span className="truncate">{i.issue}</span>
                    <span className="shrink-0 text-gray-400 dark:text-gray-500">
                      {pct(i.precision)} · {i.accepted}/{i.rejected}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <p className="text-xs font-medium text-gray-500 dark:text-gray-400 mb-1">By model</p>
              <ul className="space-y-0.5">
                {metrics.byModel.map((m) => (
                  <li key={m.model ?? 'unknown'} className="text-xs text-gray-600 dark:text-gray-300 flex justify-between gap-2">
                    <span className="truncate">{m.model ?? 'unknown'}</span>
                    <span className="shrink-0 text-gray-400 dark:text-gray-500">
                      {pct(m.precision)} · {m.accepted}/{m.rejected}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </details>
      )}
    </section>
  );
}

function EvidenceCard({
  item, topicTitle, topics, saving, error, onAccept, onReject, onRehome,
}: {
  item: EvidenceRow;
  topicTitle: string | null;
  topics: Topic[];
  saving: boolean;
  error?: string;
  onAccept: () => void;
  onReject: (reason: RejectReason, note: string) => void;
  onRehome: (topicId: string | null, issue: string) => void;
}) {
  const [mode, setMode] = useState<'idle' | 'reject' | 'rehome'>('idle');
  const [reason, setReason] = useState<RejectReason>(REJECT_REASONS[0]);
  const [note, setNote] = useState('');
  const [rehomeTopicId, setRehomeTopicId] = useState(item.topicId ?? '');
  const [rehomeIssue, setRehomeIssue] = useState(item.issue);

  const badge = statusBadge(item.machineStatus);
  const reasons = flagReasons(item.gateFlags);
  const hasLink = !!item.deepLink && item.deepLink.startsWith('http');

  return (
    <div className="rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 p-4">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${BADGE_STYLE[badge.kind]}`}>
              {badge.label}
            </span>
            <span className="text-xs px-2 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300">
              {item.sourceType}
            </span>
          </div>
          <p className="mt-1.5 text-sm font-medium text-gray-900 dark:text-white">
            {item.issue}
            {topicTitle && <span className="font-normal text-gray-400 dark:text-gray-500"> · {topicTitle}</span>}
          </p>
        </div>
        <p className="shrink-0 text-xs text-gray-400 dark:text-gray-500">
          {new Date(item.createdAt).toLocaleDateString()}
        </p>
      </div>

      <blockquote className="mt-2 border-l-2 border-gray-200 dark:border-gray-700 pl-3 text-sm text-gray-900 dark:text-white italic">
        &ldquo;{item.verbatimText}&rdquo;
      </blockquote>
      {item.context && <p className="mt-1.5 text-xs text-gray-500 dark:text-gray-400">{item.context}</p>}

      <div className="mt-2 flex items-center gap-3 flex-wrap">
        {hasLink && (
          <a
            href={item.deepLink!}
            target="_blank"
            rel="noopener noreferrer"
            className="text-xs text-ev-blue hover:underline"
          >
            View source ↗
          </a>
        )}
        {reasons.map((r) => (
          <span
            key={r}
            className="text-xs px-1.5 py-0.5 rounded bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400"
          >
            {r}
          </span>
        ))}
      </div>

      {error && <p className="mt-2 text-xs text-ev-red">{error}</p>}

      {mode === 'idle' && (
        <div className="mt-3 flex gap-2">
          <button
            onClick={onAccept}
            disabled={saving}
            className="px-3 py-1.5 rounded bg-green-600 hover:bg-green-700 disabled:opacity-40 text-white text-xs font-medium transition-colors"
          >
            {saving ? 'Saving…' : 'Accept'}
          </button>
          <button
            onClick={() => setMode('reject')}
            disabled={saving}
            className="px-3 py-1.5 rounded bg-red-50 hover:bg-red-100 dark:bg-red-900/20 dark:hover:bg-red-900/40 text-red-700 dark:text-red-400 text-xs font-medium transition-colors"
          >
            Reject
          </button>
          <button
            onClick={() => setMode('rehome')}
            disabled={saving}
            className="px-3 py-1.5 rounded border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:border-ev-blue text-xs font-medium transition-colors"
          >
            Re-home
          </button>
        </div>
      )}

      {mode === 'reject' && (
        <div className="mt-3 space-y-2 border-t border-gray-100 dark:border-gray-800 pt-3">
          <div className="flex gap-2 flex-wrap">
            <select
              value={reason}
              onChange={(e) => setReason(e.target.value as RejectReason)}
              className="text-xs border border-gray-300 dark:border-gray-600 rounded px-2 py-1 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
            >
              {REJECT_REASONS.map((r) => <option key={r} value={r}>{r}</option>)}
            </select>
            <input
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Note (optional)"
              className="flex-1 min-w-[160px] text-xs border border-gray-300 dark:border-gray-600 rounded px-2 py-1 bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
            />
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => onReject(reason, note)}
              disabled={saving}
              className="px-3 py-1.5 rounded bg-red-600 hover:bg-red-700 disabled:opacity-40 text-white text-xs font-medium transition-colors"
            >
              {saving ? 'Rejecting…' : 'Confirm reject'}
            </button>
            <button
              onClick={() => setMode('idle')}
              disabled={saving}
              className="px-3 py-1.5 rounded border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 text-xs font-medium transition-colors"
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      {mode === 'rehome' && (
        <div className="mt-3 space-y-2 border-t border-gray-100 dark:border-gray-800 pt-3">
          <div className="flex gap-2 flex-wrap">
            <select
              value={rehomeTopicId}
              onChange={(e) => setRehomeTopicId(e.target.value)}
              className="text-xs border border-gray-300 dark:border-gray-600 rounded px-2 py-1 bg-white dark:bg-gray-800 text-gray-900 dark:text-white max-w-[220px]"
            >
              <option value="">No topic</option>
              {topics.map((t) => <option key={t.id} value={t.id}>{t.title}</option>)}
            </select>
            <input
              value={rehomeIssue}
              onChange={(e) => setRehomeIssue(e.target.value)}
              placeholder="Issue"
              className="flex-1 min-w-[160px] text-xs border border-gray-300 dark:border-gray-600 rounded px-2 py-1 bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500"
            />
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => onRehome(rehomeTopicId || null, rehomeIssue)}
              disabled={saving || rehomeIssue.trim() === ''}
              className="px-3 py-1.5 rounded bg-ev-blue hover:bg-ev-blue/90 disabled:opacity-40 text-white text-xs font-medium transition-colors"
            >
              {saving ? 'Moving…' : 'Confirm re-home'}
            </button>
            <button
              onClick={() => setMode('idle')}
              disabled={saving}
              className="px-3 py-1.5 rounded border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 text-xs font-medium transition-colors"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
