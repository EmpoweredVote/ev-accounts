import { useEffect, useState, useCallback } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { apiFetch } from '../../lib/api';

interface StagingStance {
  id: string;
  context_key: string;
  politician_name: string;
  topic_key: string;
  value: number;
  reasoning: string | null;
  sources: string[];
  status: string;
  added_by: string;
  review_count: number;
  reviewed_by: string[];
}

interface StanceOption {
  id: string;
  value: number;
  text: string;
}

interface CompassTopic {
  id: string;
  topic_key: string;
  title: string;
  short_title: string | null;
  start_phrase: string | null;
}

type Mode = 'view' | 'edit' | 'reject';

export function StanceReviewPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [stance, setStance] = useState<StagingStance | null>(null);
  const [topic, setTopic] = useState<CompassTopic | null>(null);
  const [stanceOptions, setStanceOptions] = useState<StanceOption[]>([]);
  const [lockAcquired, setLockAcquired] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [mode, setMode] = useState<Mode>('view');

  const [editValue, setEditValue] = useState<number>(0);
  const [editReasoning, setEditReasoning] = useState('');
  const [editSources, setEditSources] = useState('');
  const [rejectComment, setRejectComment] = useState('');

  const releaseLock = useCallback(() => {
    if (lockAcquired && id) {
      apiFetch(`/staging/stances/${id}/lock`, { method: 'DELETE' }).catch(() => {});
    }
  }, [lockAcquired, id]);

  useEffect(() => {
    return () => { releaseLock(); };
  }, [releaseLock]);

  useEffect(() => {
    if (id) load();
  }, [id]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const stanceData = await apiFetch<StagingStance>(`/staging/stances/${id}`);
      setStance(stanceData);
      setEditValue(stanceData.value);
      setEditReasoning(stanceData.reasoning ?? '');
      setEditSources(Array.isArray(stanceData.sources) ? stanceData.sources.join('; ') : '');

      try {
        await apiFetch(`/staging/stances/${id}/lock`, { method: 'POST' });
        setLockAcquired(true);
      } catch (lockErr: unknown) {
        setError(lockErr instanceof Error ? lockErr.message : 'Could not acquire lock — stance may be open elsewhere');
      }

      const topicsData = await apiFetch<{ topics: CompassTopic[] }>('/admin/compass/topics');
      const matched = topicsData.topics.find((t) => t.topic_key === stanceData.topic_key);
      if (matched) {
        setTopic(matched);
        const options = await apiFetch<StanceOption[]>(`/admin/compass/topics/${matched.id}/stances`);
        setStanceOptions(options);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load stance');
    } finally {
      setLoading(false);
    }
  }

  async function handleApprove() {
    if (!id) return;
    setSaving(true);
    setError(null);
    try {
      await apiFetch(`/staging/stances/${id}/review`, {
        method: 'POST',
        body: JSON.stringify({ action: 'approve' }),
      });
      setLockAcquired(false);
      navigate('/admin/review');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to approve');
      setSaving(false);
    }
  }

  async function handleReject() {
    if (!id) return;
    setSaving(true);
    setError(null);
    try {
      await apiFetch(`/staging/stances/${id}/review`, {
        method: 'POST',
        body: JSON.stringify({ action: 'reject', comment: rejectComment || undefined }),
      });
      setLockAcquired(false);
      navigate('/admin/review');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to reject');
      setSaving(false);
    }
  }

  async function handleEditAndApprove() {
    if (!id || !editValue) return;
    setSaving(true);
    setError(null);
    try {
      const sources = editSources.split(';').map((s) => s.trim()).filter(Boolean);
      await apiFetch(`/staging/stances/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({ value: editValue, reasoning: editReasoning, sources }),
      });
      await apiFetch(`/staging/stances/${id}/review`, {
        method: 'POST',
        body: JSON.stringify({ action: 'approve' }),
      });
      setLockAcquired(false);
      navigate('/admin/review');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save and approve');
      setSaving(false);
    }
  }

  const getStanceText = (value: number) =>
    stanceOptions.find((s) => s.value === value)?.text ?? `Stance ${value}`;

  if (loading) return <p className="text-sm text-gray-500 dark:text-gray-400">Loading...</p>;

  if (!stance) {
    return (
      <div>
        <p className="text-sm text-red-600 dark:text-red-400">{error ?? 'Stance not found'}</p>
        <Link to="/admin/review" className="mt-2 text-sm text-gray-500 underline">
          Back to queue
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-2xl">
      <div className="mb-6">
        <Link
          to="/admin/review"
          className="text-sm text-gray-500 hover:text-gray-900 dark:hover:text-white transition-colors"
        >
          ← Review Queue
        </Link>
        <h1 className="mt-2 text-2xl font-bold text-gray-900 dark:text-white">
          {stance.politician_name}
        </h1>
        <p className="text-gray-500 dark:text-gray-400 text-sm">
          {topic?.short_title ?? topic?.title ?? stance.topic_key}
        </p>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 rounded-md text-sm">
          {error}
        </div>
      )}

      <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 p-6 space-y-5">
        <div className="flex gap-4 text-sm text-gray-500 dark:text-gray-400 pb-4 border-b border-gray-100 dark:border-gray-800">
          <span>
            Added by{' '}
            <strong className="text-gray-700 dark:text-gray-300">{stance.added_by}</strong>
          </span>
          {stance.review_count > 0 && <span>{stance.review_count}/2 approvals</span>}
          {stance.reviewed_by?.length > 0 && (
            <span>Reviewed by: {stance.reviewed_by.join(', ')}</span>
          )}
        </div>

        {mode === 'view' && (
          <>
            {topic?.start_phrase && (
              <p className="text-sm text-gray-500 dark:text-gray-400 italic">{topic.start_phrase}</p>
            )}
            <div className="flex items-center gap-3">
              <span className="text-3xl font-bold text-gray-900 dark:text-white">{stance.value}</span>
              <span className="text-gray-700 dark:text-gray-300">{getStanceText(stance.value)}</span>
            </div>
            {stance.reasoning && (
              <div>
                <p className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-1">
                  Reasoning
                </p>
                <p className="text-sm text-gray-700 dark:text-gray-300">{stance.reasoning}</p>
              </div>
            )}
            {stance.sources?.length > 0 && (
              <div>
                <p className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-1">
                  Sources
                </p>
                <ul className="space-y-1">
                  {stance.sources.map((src, i) => (
                    <li key={i}>
                      <a
                        href={src}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-sm text-blue-600 dark:text-blue-400 hover:underline break-all"
                      >
                        {src}
                      </a>
                    </li>
                  ))}
                </ul>
              </div>
            )}
            <div className="flex gap-3 pt-2">
              <button
                onClick={handleApprove}
                disabled={saving || !lockAcquired}
                className="px-4 py-2 bg-green-600 hover:bg-green-700 disabled:opacity-40 text-white text-sm font-medium rounded-md transition-colors"
              >
                {saving ? 'Saving...' : 'Approve'}
              </button>
              <button
                onClick={() => setMode('edit')}
                disabled={!lockAcquired}
                className="px-4 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 disabled:opacity-40 text-gray-700 dark:text-gray-300 text-sm font-medium rounded-md transition-colors"
              >
                Edit & Approve
              </button>
              <button
                onClick={() => setMode('reject')}
                disabled={!lockAcquired}
                className="px-4 py-2 bg-red-50 hover:bg-red-100 dark:bg-red-900/20 dark:hover:bg-red-900/40 disabled:opacity-40 text-red-700 dark:text-red-400 text-sm font-medium rounded-md transition-colors"
              >
                Reject
              </button>
            </div>
          </>
        )}

        {mode === 'edit' && (
          <>
            <div>
              <p className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-2">
                Stance
              </p>
              {stanceOptions.length > 0 ? (
                <div className="space-y-2">
                  {stanceOptions.map((opt) => (
                    <label
                      key={opt.value}
                      className={`flex items-center gap-3 p-3 rounded-md border cursor-pointer transition-colors ${
                        editValue === opt.value
                          ? 'border-ev-red bg-red-50 dark:bg-ev-red/10'
                          : 'border-gray-200 dark:border-gray-700 hover:border-gray-400 dark:hover:border-gray-500'
                      }`}
                    >
                      <input
                        type="radio"
                        name="stance"
                        value={opt.value}
                        checked={editValue === opt.value}
                        onChange={() => setEditValue(opt.value)}
                        className="sr-only"
                      />
                      <span className="w-5 text-center font-bold text-gray-900 dark:text-white text-sm">
                        {opt.value}
                      </span>
                      <span className="text-sm text-gray-700 dark:text-gray-300">{opt.text}</span>
                    </label>
                  ))}
                </div>
              ) : (
                <input
                  type="number"
                  value={editValue}
                  onChange={(e) => setEditValue(Number(e.target.value))}
                  className="w-24 px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-sm"
                />
              )}
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-1">
                Reasoning
              </label>
              <textarea
                value={editReasoning}
                onChange={(e) => setEditReasoning(e.target.value)}
                rows={4}
                className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-sm resize-y focus:outline-none focus:ring-1 focus:ring-ev-red"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-1">
                Sources (semicolon-separated URLs)
              </label>
              <textarea
                value={editSources}
                onChange={(e) => setEditSources(e.target.value)}
                rows={2}
                className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-sm resize-y focus:outline-none focus:ring-1 focus:ring-ev-red"
                placeholder="https://example.com/article1; https://example.com/article2"
              />
            </div>
            <div className="flex gap-3">
              <button
                onClick={() => setMode('view')}
                disabled={saving}
                className="px-4 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 text-sm font-medium rounded-md transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleEditAndApprove}
                disabled={saving || !editValue}
                className="px-4 py-2 bg-green-600 hover:bg-green-700 disabled:opacity-40 text-white text-sm font-medium rounded-md transition-colors"
              >
                {saving ? 'Saving...' : 'Save & Approve'}
              </button>
            </div>
          </>
        )}

        {mode === 'reject' && (
          <>
            <div>
              <label className="block text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-1">
                Reason (optional)
              </label>
              <textarea
                value={rejectComment}
                onChange={(e) => setRejectComment(e.target.value)}
                rows={3}
                placeholder="Explain why this stance is being rejected..."
                className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-sm resize-y focus:outline-none focus:ring-1 focus:ring-ev-red"
              />
            </div>
            <div className="flex gap-3">
              <button
                onClick={() => setMode('view')}
                disabled={saving}
                className="px-4 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 text-sm font-medium rounded-md transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleReject}
                disabled={saving}
                className="px-4 py-2 bg-red-600 hover:bg-red-700 disabled:opacity-40 text-white text-sm font-medium rounded-md transition-colors"
              >
                {saving ? 'Rejecting...' : 'Confirm Reject'}
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
