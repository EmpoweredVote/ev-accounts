import { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router';
import { apiFetch } from '../../lib/api';

interface EvidenceSnippet {
  snippet_index: number;
  snippet: string;
  verdict: 'verified' | 'not_found' | 'url_broken' | string;
  reason?: string;
}

interface EvidenceSource {
  url: string;
  snippets: EvidenceSnippet[];
}

interface ResearchReviewRow {
  id: string;
  batchId: string;
  politicianId: string | null;
  fullNameRaw: string;
  topicId: string | null;
  topicKey: string;
  proposedValue: number | null;
  proposedReasoning: string;
  evidence: EvidenceSource[];
  verifiedSourceCount: number;
  threshold: number;
  status: string;
  reResearchAttempted: boolean;
  createdAt: string;
  /** The pair's value in the OPEN season — what approving replaces. 0 = an editor's blank; null = none. */
  currentValue: number | null;
}

export function ResearchReviewPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [row, setRow] = useState<ResearchReviewRow | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [rejectNote, setRejectNote] = useState('');
  const [showReject, setShowReject] = useState(false);
  const [humanVerified, setHumanVerified] = useState<Set<string>>(new Set());
  const [editValue, setEditValue] = useState<string>('');
  const [editReasoning, setEditReasoning] = useState<string>('');

  useEffect(() => {
    if (id) load();
  }, [id]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const data = await apiFetch<ResearchReviewRow>(`/admin/research-review/${id}`);
      setRow(data);
      setEditValue(data.proposedValue !== null ? String(data.proposedValue) : '');
      setEditReasoning(data.proposedReasoning);
      // Pre-check any sources the machine already verified
      const preVerified = new Set(
        data.evidence
          .filter((e) => e.snippets.some((s) => s.verdict === 'verified'))
          .map((e) => e.url),
      );
      setHumanVerified(preVerified);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load');
    } finally {
      setLoading(false);
    }
  }

  function toggleVerified(url: string) {
    setHumanVerified((prev) => {
      const next = new Set(prev);
      next.has(url) ? next.delete(url) : next.add(url);
      return next;
    });
  }

  async function handleApprove() {
    if (!id) return;
    setSaving(true);
    setError(null);
    try {
      const parsedValue = editValue !== '' ? Number(editValue) : null;
      await apiFetch(`/admin/research-review/${id}/resolve`, {
        method: 'POST',
        body: JSON.stringify({
          humanVerifiedUrls: [...humanVerified],
          valueOverride: parsedValue,
          reasoningOverride: editReasoning || undefined,
        }),
      });
      navigate('/admin/review?tab=research');
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
      await apiFetch(`/admin/research-review/${id}/reject`, {
        method: 'POST',
        body: JSON.stringify({ notes: rejectNote || undefined }),
      });
      navigate('/admin/review?tab=research');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to reject');
      setSaving(false);
    }
  }

  if (loading) return <p className="text-sm text-gray-500 dark:text-gray-400">Loading...</p>;
  if (!row) {
    return (
      <div>
        <p className="text-sm text-red-600 dark:text-red-400">{error ?? 'Not found'}</p>
        <Link to="/admin/review?tab=research" className="mt-2 text-sm text-gray-500 underline">
          Back to queue
        </Link>
      </div>
    );
  }

  // A stance is never published without a citation: at least one machine-verified source (a
  // snippet the verifier found on the page) or one the reviewer ticked by hand. The server
  // refuses the same case (422), so this only saves a round trip.
  const hasMachineVerified = row.evidence.some((e) => e.snippets.some((s) => s.verdict === 'verified'));
  const hasSource = hasMachineVerified || humanVerified.size > 0;
  const canApprove = !!row.politicianId && !!row.topicId && editValue !== '' && !isNaN(Number(editValue)) && hasSource;
  const totalVerified = humanVerified.size;
  const meetsThreshold = totalVerified >= row.threshold;
  const currentValueText =
    row.currentValue === null ? 'none'
    : row.currentValue === 0 ? 'blank (an editor cleared it)'
    : String(row.currentValue);

  return (
    <div className="max-w-2xl">
      <div className="mb-6">
        <Link
          to="/admin/review?tab=research"
          className="text-sm text-gray-500 hover:text-gray-900 dark:hover:text-white transition-colors"
        >
          ← Research Review
        </Link>
        <h1 className="mt-2 text-2xl font-bold text-gray-900 dark:text-white">{row.fullNameRaw}</h1>
        <p className="text-gray-500 dark:text-gray-400 text-sm">{row.topicKey}</p>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 rounded-md text-sm">
          {error}
        </div>
      )}

      {!canApprove && (
        <div className="mb-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 text-yellow-800 dark:text-yellow-300 rounded-md text-sm">
          {!row.politicianId
            ? 'Politician could not be matched to a DB record — approve is disabled.'
            : !row.topicId
            ? 'Topic could not be matched — approve is disabled.'
            : editValue === '' || isNaN(Number(editValue))
            ? 'Enter a valid value to enable approve.'
            : 'No source is verified — check a source URL and mark it verified to enable approve.'}
        </div>
      )}

      <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 p-6 space-y-5">
        {/* Meta */}
        <div className="flex flex-wrap gap-3 text-sm text-gray-500 dark:text-gray-400 pb-4 border-b border-gray-100 dark:border-gray-800">
          <span>Batch <strong className="text-gray-700 dark:text-gray-300">{row.batchId}</strong></span>
          <span className={meetsThreshold ? 'text-green-600 dark:text-green-400 font-medium' : ''}>
            {totalVerified}/{row.threshold} sources verified
          </span>
          {row.reResearchAttempted && (
            <span className="text-yellow-600 dark:text-yellow-400">Re-research attempted</span>
          )}
          <span className={row.currentValue !== null ? 'text-yellow-700 dark:text-yellow-300 font-medium' : ''}>
            Current value in the open season: {currentValueText}
          </span>
        </div>

        {/* Proposed stance */}
        <div>
          <label className="block text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-1">
            Value
          </label>
          <input
            type="number"
            value={editValue}
            onChange={(e) => setEditValue(e.target.value)}
            className="w-24 px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-2xl font-bold text-gray-900 dark:text-white focus:outline-none focus:ring-1 focus:ring-ev-red"
          />
        </div>

        {/* Reasoning */}
        <div>
          <label className="block text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-1">
            Reasoning
          </label>
          <textarea
            value={editReasoning}
            onChange={(e) => setEditReasoning(e.target.value)}
            rows={4}
            className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-sm text-gray-700 dark:text-gray-300 resize-y focus:outline-none focus:ring-1 focus:ring-ev-red"
          />
        </div>

        {/* Sources */}
        {row.evidence.length > 0 && (
          <div>
            <p className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-2">
              Sources — click a URL to check it, then toggle verified
            </p>
            <div className="space-y-2">
              {row.evidence.map((src, i) => (
                <SourceBlock
                  key={i}
                  src={src}
                  verified={humanVerified.has(src.url)}
                  onToggle={() => toggleVerified(src.url)}
                />
              ))}
            </div>
          </div>
        )}

        {/* Actions */}
        {!showReject ? (
          <div className="flex gap-3 pt-2">
            <button
              onClick={handleApprove}
              disabled={saving || !canApprove}
              className="px-4 py-2 bg-green-600 hover:bg-green-700 disabled:opacity-40 text-white text-sm font-medium rounded-md transition-colors"
            >
              {saving ? 'Saving...' : `Approve & publish${totalVerified > 0 ? ` (${totalVerified} source${totalVerified !== 1 ? 's' : ''})` : ''}`}
            </button>
            <button
              onClick={() => setShowReject(true)}
              disabled={saving}
              className="px-4 py-2 bg-red-50 hover:bg-red-100 dark:bg-red-900/20 dark:hover:bg-red-900/40 text-red-700 dark:text-red-400 text-sm font-medium rounded-md transition-colors"
            >
              Reject
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            <div>
              <label className="block text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-1">
                Note (optional)
              </label>
              <textarea
                value={rejectNote}
                onChange={(e) => setRejectNote(e.target.value)}
                rows={2}
                placeholder="Why is this stance being rejected?"
                className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-sm resize-y focus:outline-none focus:ring-1 focus:ring-ev-red"
              />
            </div>
            <div className="flex gap-3">
              <button
                onClick={() => setShowReject(false)}
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
          </div>
        )}
      </div>
    </div>
  );
}

function SourceBlock({
  src,
  verified,
  onToggle,
}: {
  src: EvidenceSource;
  verified: boolean;
  onToggle: () => void;
}) {
  return (
    <div className={`rounded-md border p-3 space-y-2 transition-colors ${
      verified
        ? 'border-green-300 dark:border-green-700 bg-green-50 dark:bg-green-900/10'
        : 'border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50'
    }`}>
      <div className="flex items-start justify-between gap-3">
        <a
          href={src.url}
          target="_blank"
          rel="noopener noreferrer"
          className="text-xs text-blue-600 dark:text-blue-400 hover:underline break-all flex-1"
        >
          {src.url}
        </a>
        <button
          onClick={onToggle}
          className={`shrink-0 px-2.5 py-1 rounded text-xs font-medium transition-colors ${
            verified
              ? 'bg-green-600 hover:bg-green-700 text-white'
              : 'bg-gray-200 hover:bg-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300'
          }`}
        >
          {verified ? '✓ Verified' : 'Mark verified'}
        </button>
      </div>
      {src.snippets.map((snip, i) => (
        <SnippetRow key={i} snip={snip} />
      ))}
    </div>
  );
}

function SnippetRow({ snip }: { snip: EvidenceSnippet }) {
  const color =
    snip.verdict === 'verified'
      ? 'text-green-700 dark:text-green-400'
      : snip.verdict === 'url_broken'
      ? 'text-red-600 dark:text-red-400'
      : 'text-gray-500 dark:text-gray-400';

  return (
    <div className="text-xs space-y-0.5">
      <span className={`font-medium ${color}`}>
        {snip.verdict === 'verified'
          ? '✓ auto-verified'
          : snip.verdict === 'url_broken'
          ? `✗ broken${snip.reason ? `: ${snip.reason}` : ''}`
          : '– snippet not found'}
      </span>
      {snip.snippet && (
        <p className="text-gray-600 dark:text-gray-400 italic">"{snip.snippet}"</p>
      )}
    </div>
  );
}
