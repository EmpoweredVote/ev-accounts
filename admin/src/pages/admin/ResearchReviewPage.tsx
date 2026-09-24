import { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router';
import { apiFetch } from '../../lib/api';
import { overrideNeedsReasoning } from './researchReviewApproval';

interface EvidenceSnippet {
  snippet_index: number;
  snippet: string;
  verdict: 'verified' | 'not_found' | 'url_broken' | 'span_too_short' | 'url_not_cited' | string;
  reason?: string;
  /**
   * I6 (ruling 2026-09-24): the matched on-page span — the ONLY text approval publishes as the
   * citation. Absent on rows queued before 2026-09-24; such a snippet is not published.
   */
  matched_span?: string;
}

/** A snippet that approval will publish: machine-verified AND carrying its matched span. */
const isPublishable = (s: EvidenceSnippet) => s.verdict === 'verified' && !!s.matched_span?.trim();

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
  /**
   * I2: what voters see NOW — the newest published season's answer (the Season 1 chair when the
   * open season has none). value 0 = a blank. null = nothing shown. text = that rung's served text.
   */
  displayed: { value: number; seasonNumber: number; text: string | null } | null;
  /** CA_0285: why the row was queued, and its evidence class. null = not recorded. */
  queueReasons: string[] | null;
  evidenceType: string | null;
  /** The ladder revision the row was researched against (CA_0264). null = unknown (legacy row). */
  topicRevisionId: string | null;
  /** The open season's current pin for this topic. null = the open season does not ask it. */
  openTopicRevisionId: string | null;
  /** Queued before CA_0264 recorded a revision — approvable, but nobody checked which ladder it answers. */
  ladderRevisionUnknown: boolean;
  /** Known revision that is not the open pin — the server refuses approval (409). */
  ladderChanged: boolean;
  /** The body/chamber of the politician's current office (list-view cohort grouping). */
  bodyLabel: string | null;
  /** The full ladder text for this row's revision (or the open pin, for a legacy row). */
  ladder: {
    /** The SERVED revision (ADR 0006) — the text voters read. */
    revisionId: string;
    /** The pin it resolves from. */
    pinRevisionId: string;
    questionText: string;
    rungs: Array<{ value: number; text: string }>;
    usingOpenPin: boolean;
  } | null;
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
          .filter((e) => e.snippets.some(isPublishable))
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
  // I6: only a snippet with a stored page span is a machine citation.
  const hasMachineVerified = row.evidence.some((e) => e.snippets.some(isPublishable));
  const hasSource = hasMachineVerified || humanVerified.size > 0;
  // The value is a chair 1-5, never anything else — the server refuses the same case (400), so
  // this only saves a round trip.
  const numericValue = Number(editValue);
  const isValidValue = editValue !== '' && Number.isInteger(numericValue) && numericValue >= 1 && numericValue <= 5;
  // Task 5, requirement 3: a value override with no changed reasoning is refused by the server
  // (422); this only saves the round trip. The server is the source of truth either way.
  const needsReasoningForOverride = overrideNeedsReasoning({
    proposedValue: row.proposedValue,
    proposedReasoning: row.proposedReasoning,
    editedValue: isValidValue ? numericValue : null,
    editedReasoning: editReasoning,
  });
  // A row researched against a ladder the open season no longer pins is refused by the server
  // (409); this only saves the round trip.
  const canApprove = !!row.politicianId && !!row.topicId && !row.ladderChanged
    && isValidValue && hasSource && !needsReasoningForOverride;
  const totalVerified = humanVerified.size;
  const meetsThreshold = totalVerified >= row.threshold;
  const currentValueText =
    row.currentValue === null ? 'none'
    : row.currentValue === 0 ? 'blank (an editor cleared it)'
    : String(row.currentValue);
  // I2: the open season can hold nothing while voters still see a Season 1 chair — approving
  // replaces THAT, so the reviewer must see it.
  const displayedText =
    row.displayed === null ? 'nothing (no chair shown)'
    : row.displayed.value === 0 ? `a blank (Season ${row.displayed.seasonNumber}) — no chair shown`
    : `chair ${row.displayed.value} (Season ${row.displayed.seasonNumber})${row.displayed.text ? `: “${row.displayed.text}”` : ''}`;
  const replacesShownChair = row.displayed !== null && row.displayed.value !== 0 && row.currentValue === null;

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

      {row.ladderChanged && (
        <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 rounded-md text-sm">
          The ladder changed since this row was researched — re-research it. Researched against revision{' '}
          <code className="text-xs">{row.topicRevisionId}</code>; the open season{' '}
          {row.openTopicRevisionId
            ? <>now pins <code className="text-xs">{row.openTopicRevisionId}</code>.</>
            : 'no longer asks this topic.'}
        </div>
      )}

      {row.ladderRevisionUnknown && (
        <div className="mb-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 text-yellow-800 dark:text-yellow-300 rounded-md text-sm">
          Ladder revision unknown (queued before 2026-09-24). Check the value against the ladder the open season asks now.
        </div>
      )}

      {!canApprove && !row.ladderChanged && (
        <div className="mb-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 text-yellow-800 dark:text-yellow-300 rounded-md text-sm">
          {!row.politicianId
            ? 'Politician could not be matched to a DB record — approve is disabled.'
            : !row.topicId
            ? 'Topic could not be matched — approve is disabled.'
            : !isValidValue
            ? 'Enter a whole number from 1 to 5 to enable approve.'
            : needsReasoningForOverride
            ? 'The value differs from the proposal — edit the reasoning to explain the new value before approving.'
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
          <span>
            Evidence: <strong className="text-gray-700 dark:text-gray-300">{row.evidenceType ?? 'not recorded'}</strong>
          </span>
          <span>
            Queued because:{' '}
            <strong className="text-gray-700 dark:text-gray-300">
              {row.queueReasons && row.queueReasons.length ? row.queueReasons.join(', ') : 'reasons not recorded (queued before CA_0285)'}
            </strong>
          </span>
        </div>

        {/* I2: what voters see right now, which approval replaces. */}
        <div className={`rounded-md px-3 py-2 text-sm ${
          replacesShownChair
            ? 'bg-yellow-50 dark:bg-yellow-900/20 text-yellow-800 dark:text-yellow-300'
            : 'bg-gray-50 dark:bg-gray-800/50 text-gray-700 dark:text-gray-300'
        }`}>
          Voters see now: {displayedText}
          {replacesShownChair && ' — approving replaces this chair, although the open season holds no value.'}
        </div>

        {/* Ladder — task 5, requirement 1: the question and all five rungs for the row's own
            revision (or the open season's pin, for a legacy row), so the reviewer checks the
            proposed chair against the ladder text itself rather than trusting the topic key. */}
        {row.ladder && (
          <div>
            <p className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-1">
              Ladder — the text voters read (served revision <code className="normal-case">{row.ladder.revisionId.slice(0, 8)}</code>)
              {row.ladder.usingOpenPin && (
                <span className="normal-case font-normal text-yellow-700 dark:text-yellow-400">
                  {' '}(open season's ladder — this row's revision is unknown)
                </span>
              )}
            </p>
            <p className="text-sm text-gray-700 dark:text-gray-300 mb-2">{row.ladder.questionText}</p>
            <ol className="space-y-1">
              {row.ladder.rungs.map((rung) => {
                const isProposed = row.proposedValue === rung.value;
                return (
                  <li
                    key={rung.value}
                    className={`flex gap-2 rounded-md px-2 py-1 text-sm ${
                      isProposed
                        ? 'bg-ev-red/10 border border-ev-red/40 text-gray-900 dark:text-white font-medium'
                        : 'text-gray-600 dark:text-gray-400'
                    }`}
                  >
                    <span className="shrink-0 w-4 text-right">{rung.value}</span>
                    <span>{rung.text}</span>
                    {isProposed && <span className="ml-auto shrink-0 text-xs text-ev-red">proposed</span>}
                  </li>
                );
              })}
            </ol>
          </div>
        )}

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
  const publishable = isPublishable(snip);
  const color =
    publishable
      ? 'text-green-700 dark:text-green-400'
      : snip.verdict === 'url_broken' || snip.verdict === 'url_not_cited'
      ? 'text-red-600 dark:text-red-400'
      : 'text-gray-500 dark:text-gray-400';

  return (
    <div className="text-xs space-y-0.5">
      <span className={`font-medium ${color}`}>
        {publishable
          ? '✓ auto-verified — the citation below is published on approval'
          : snip.verdict === 'verified'
          ? '– verified before 2026-09-24, with no page span stored — not published as a citation'
          : snip.verdict === 'url_broken'
          ? `✗ broken${snip.reason ? `: ${snip.reason}` : ''}`
          : snip.verdict === 'url_not_cited'
          ? '✗ not one of the row’s cited sources — not verified, not published'
          : snip.verdict === 'span_too_short'
          ? '– fewer than 25 contiguous words are on the page — not verified'
          : '– snippet not found'}
      </span>
      {/* I6: the citation is the matched page span only; the researcher's full snippet is context. */}
      {publishable && (
        <p className="text-gray-800 dark:text-gray-200">
          <span className="not-italic font-semibold">Citation: </span>"{snip.matched_span}"
        </p>
      )}
      {snip.snippet && (
        <p className="text-gray-500 dark:text-gray-400 italic">
          {publishable ? 'Researcher’s snippet (not published): ' : ''}"{snip.snippet}"
        </p>
      )}
    </div>
  );
}
