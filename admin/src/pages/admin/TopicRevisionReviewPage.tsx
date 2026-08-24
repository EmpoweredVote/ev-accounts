/**
 * TopicRevisionReviewPage — review one proposed compass content revision.
 *
 * Reached from Review Queue → Topic Revisions. Implements ADR 0004 §7/§9.
 *
 * WHAT A REVIEWER SEES, AND WHAT THEY NEVER SEE
 * Prose. The current wording and the proposed wording, with the differences
 * marked. No YAML, no SQL, no JSON, no ids. Reviewers are non-technical.
 *
 * There is deliberately no authoring form. Migration 061 shipped one — it asked
 * the reviewer to type a title, a question and a stances JSONB blob into a web
 * form — and it was used zero times in four months, because the people who
 * author compass content work in SQL and generator scripts. Drafts arrive from
 * that tooling. This page only reads and decides.
 *
 * HIGHLIGHT, NOT BOLD
 * On a dark ground extra font weight reads mostly as extra brightness, so the
 * gap between regular and bold nearly disappears. Changes get a background
 * highlight instead, which does not depend on weight.
 *
 * AND NEVER HIGHLIGHT ALONE
 * Colour by itself fails for colourblind and low-vision readers and vanishes
 * completely for a screen reader. So changes are real <ins> and <del> elements —
 * which announce themselves as "insertion" and "deletion" — with the highlight
 * and strike-through as the visible layer on top.
 */

import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { apiFetch } from '../../lib/api';
import { diffWords, hasChanged } from '../../lib/wordDiff';

// ---------------------------------------------------------------------------
// Types — mirror lib/compassRevisionService.ts
// ---------------------------------------------------------------------------

type RungDisposition = 'unchanged' | 'reworded' | 'moved' | 'replaced';

interface RungPair {
  value: number;
  currentText: string | null;
  proposedText: string | null;
  currentDescription: string | null;
  proposedDescription: string | null;
  disposition: RungDisposition;
  movesTo: number | null;
}

interface RevisionDetail {
  id: string;
  topicKey: string;
  revision: number;
  version: number;
  changeClass: 'editorial' | 'clarifying' | 'substantive';
  status: 'draft' | 'approved' | 'published' | 'superseded' | 'rejected';
  title: string;
  shortTitle: string | null;
  questionText: string;
  rationale: string;
  publicNote: string;
  reviewRef: string | null;
  proposedByName: string | null;
  approvedByName: string | null;
  currentRevision: number;
  currentVersion: number;
  currentTitle: string;
  currentShortTitle: string | null;
  currentQuestionText: string;
  rungs: RungPair[];
  publishBlockedReason: string | null;
}

// ---------------------------------------------------------------------------
// Diff rendering
// ---------------------------------------------------------------------------

const INS =
  'bg-amber-200/80 text-gray-900 underline decoration-amber-700 decoration-1 ' +
  'underline-offset-2 rounded-sm px-0.5 dark:bg-amber-500/30 dark:text-amber-50 ' +
  'dark:decoration-amber-400';

const DEL = 'line-through decoration-1 text-gray-500 dark:text-gray-400 px-0.5';

function InlineDiff({ prev, next }: { prev: string | null; next: string | null }) {
  const parts = useMemo(() => diffWords(prev, next), [prev, next]);
  return (
    <span>
      {parts.map((p, i) =>
        p.type === 'ins' ? (
          <ins key={i} className={INS}>{p.text}</ins>
        ) : p.type === 'del' ? (
          <del key={i} className={DEL}>{p.text}</del>
        ) : (
          <span key={i}>{p.text}</span>
        )
      )}
    </span>
  );
}

/**
 * Old and new as whole blocks. Used when the server says the rung was REPLACED —
 * marking word by word would be noise when nothing survived. That distinction is
 * semantic and comes from `rung_map`; a text differ cannot make it, because a
 * rewrite and a replacement look identical to one.
 */
function BlockReplace({ prev, next }: { prev: string | null; next: string | null }) {
  return (
    <span className="flex flex-col gap-1">
      {prev ? (
        <del className={`${DEL} block`}>{prev}</del>
      ) : (
        <span className="text-sm italic text-gray-500 dark:text-gray-400">(nothing here before)</span>
      )}
      {next ? (
        <ins className={`${INS} block`}>{next}</ins>
      ) : (
        <span className="text-sm italic text-gray-500 dark:text-gray-400">
          (this option is being removed)
        </span>
      )}
    </span>
  );
}

function FieldDiff({ label, prev, next }: { label: string; prev: string | null; next: string | null }) {
  const changed = hasChanged(prev, next);
  return (
    <div>
      <div className="flex items-baseline gap-2">
        <span className="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
          {label}
        </span>
        {!changed && <span className="text-xs text-gray-400 dark:text-gray-500">unchanged</span>}
      </div>
      <p className="mt-1 leading-relaxed text-gray-900 dark:text-white">
        {changed ? <InlineDiff prev={prev} next={next} /> : <span>{next || prev || '—'}</span>}
      </p>
    </div>
  );
}

const DISPOSITION: Record<RungDisposition, string> = {
  unchanged: 'unchanged',
  reworded: 'reworded',
  moved: 'moved',
  replaced: 'replaced',
};

function RungRow({ rung }: { rung: RungPair }) {
  const { value, currentText, proposedText, disposition, movesTo } = rung;

  const body =
    disposition === 'unchanged' ? (
      <span className="text-gray-600 dark:text-gray-300">{currentText}</span>
    ) : disposition === 'replaced' ? (
      <BlockReplace prev={currentText} next={proposedText} />
    ) : (
      <InlineDiff prev={currentText} next={proposedText} />
    );

  return (
    <div
      className={`grid grid-cols-[2rem_1fr_auto] items-baseline gap-x-3 px-4 py-3 border-b
                  border-gray-200 dark:border-gray-700 last:border-b-0
                  ${disposition === 'unchanged' ? 'opacity-70' : ''}`}
    >
      <span className="font-mono text-xs font-semibold tabular-nums text-gray-500 dark:text-gray-400">
        {value}
      </span>
      <div className="min-w-0 leading-relaxed text-gray-900 dark:text-white">{body}</div>
      <span className="whitespace-nowrap font-mono text-[0.62rem] font-semibold uppercase tracking-widest text-gray-500 dark:text-gray-400">
        {DISPOSITION[disposition]}
        {disposition === 'moved' && movesTo != null && (
          <span className="ml-1 text-amber-700 dark:text-amber-400">&rarr; {movesTo}</span>
        )}
      </span>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

export function TopicRevisionReviewPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [detail, setDetail] = useState<RevisionDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [rejecting, setRejecting] = useState(false);
  const [reason, setReason] = useState('');

  const load = useCallback(async () => {
    if (!id) return;
    setLoading(true);
    setError(null);
    try {
      setDetail(await apiFetch<RevisionDetail>(`/compass/revisions/${id}`));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load proposal');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => { void load(); }, [load]);

  async function act(fn: () => Promise<unknown>, success: string, thenLeave = false) {
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      await fn();
      setNotice(success);
      if (thenLeave) {
        navigate('/admin/review?tab=topics');
        return;
      }
      await load();
    } catch (err) {
      // Surface the server's own message. The RPCs are written for a human —
      // REPOINTING_NOT_IMPLEMENTED explains what is missing and what to do
      // instead, which "Request failed" would throw away.
      setError(err instanceof Error ? err.message : 'Action failed');
    } finally {
      setBusy(false);
    }
  }

  if (loading) return <p className="text-sm text-gray-500 dark:text-gray-400">Loading...</p>;

  if (!detail) {
    return (
      <div>
        <BackLink />
        <p className="text-sm text-red-600 dark:text-red-400">{error ?? 'Proposal not found.'}</p>
      </div>
    );
  }

  const ladderChanges = detail.rungs.filter((r) => r.disposition !== 'unchanged').length;

  return (
    <div className="max-w-4xl">
      <BackLink />

      {error && (
        <div
          role="alert"
          className="mb-4 rounded border border-amber-600 bg-amber-50 px-3 py-2 text-sm text-amber-900
                     dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-100"
        >
          {error}
        </div>
      )}
      {notice && (
        <div
          role="status"
          className="mb-4 rounded border border-green-600 bg-green-50 px-3 py-2 text-sm text-green-900
                     dark:border-green-500 dark:bg-green-950/50 dark:text-green-100"
        >
          {notice}
        </div>
      )}

      <header className="mb-6">
        <p className="font-mono text-xs uppercase tracking-widest text-gray-500 dark:text-gray-400">
          {detail.topicKey} &middot; proposed by {detail.proposedByName ?? 'unknown'}
        </p>
        <h1 className="mt-1 text-2xl font-bold text-gray-900 dark:text-white">
          {detail.changeClass === 'substantive'
            ? `Version ${detail.currentVersion} → ${detail.version}`
            : `Version ${detail.version} (unchanged — ${detail.changeClass})`}
        </h1>
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {ladderChanges === 0
            ? 'Wording only. The five options are untouched.'
            : `${ladderChanges} of 5 options change.`}
        </p>
      </header>

      {/* Why */}
      <section className="mb-6 space-y-3 rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-900">
        <div>
          <h2 className="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            What readers will be told
          </h2>
          <p className="mt-1 leading-relaxed text-gray-900 dark:text-white">{detail.publicNote}</p>
        </div>
        <div>
          <h2 className="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Internal reasoning (never published)
          </h2>
          <p className="mt-1 leading-relaxed text-gray-700 dark:text-gray-300">{detail.rationale}</p>
        </div>
        {detail.reviewRef && (
          <p className="break-all font-mono text-xs text-gray-500 dark:text-gray-400">
            Discussion: {detail.reviewRef}
          </p>
        )}
      </section>

      {/* Framing */}
      <section className="mb-6 space-y-4 rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-900">
        <FieldDiff label="Title" prev={detail.currentTitle} next={detail.title} />
        <FieldDiff label="Short title" prev={detail.currentShortTitle} next={detail.shortTitle} />
        <FieldDiff label="Question" prev={detail.currentQuestionText} next={detail.questionText} />
      </section>

      {/* Ladder */}
      <section className="mb-6 rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
        <header className="border-b border-gray-200 px-4 py-2 dark:border-gray-700">
          <h2 className="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            The five options
          </h2>
        </header>
        {detail.rungs.map((r) => <RungRow key={r.value} rung={r} />)}
      </section>

      {detail.publishBlockedReason && (
        <div
          role="alert"
          className="mb-6 rounded border-l-2 border-amber-600 bg-amber-50 px-3 py-2 text-sm text-amber-900
                     dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-100"
        >
          <strong className="block font-semibold">Cannot be published yet</strong>
          {detail.publishBlockedReason}
        </div>
      )}

      {/* Actions */}
      <footer className="flex flex-wrap items-center gap-3 border-t border-gray-200 pt-4 dark:border-gray-700">
        {detail.status === 'draft' && (
          <>
            <button
              type="button"
              disabled={busy}
              onClick={() => act(() => apiFetch(`/compass/revisions/${detail.id}/approve`, { method: 'POST' }), 'Approved.')}
              className="rounded bg-ev-red px-4 py-2 font-semibold text-white transition-colors hover:opacity-90 disabled:opacity-50"
            >
              Approve
            </button>
            <button
              type="button"
              disabled={busy}
              onClick={() => setRejecting((v) => !v)}
              className="rounded border border-gray-300 px-4 py-2 font-semibold text-gray-700 transition-colors
                         hover:bg-gray-100 disabled:opacity-50 dark:border-gray-600 dark:text-gray-200 dark:hover:bg-gray-800"
            >
              Request changes
            </button>
          </>
        )}

        {detail.status === 'approved' && (
          <button
            type="button"
            disabled={busy || Boolean(detail.publishBlockedReason)}
            onClick={() =>
              act(
                () => apiFetch(`/compass/revisions/${detail.id}/publish`, { method: 'POST' }),
                'Published. The previous version is now part of the public record.',
                true
              )
            }
            className="rounded bg-ev-red px-4 py-2 font-semibold text-white transition-colors hover:opacity-90 disabled:opacity-50"
          >
            Publish
          </button>
        )}

        {(detail.status === 'published' || detail.status === 'rejected' || detail.status === 'superseded') && (
          <p className="text-sm text-gray-600 dark:text-gray-300">
            This proposal is {detail.status}. Nothing further to do.
          </p>
        )}

        <span className="ml-auto font-mono text-[0.65rem] uppercase tracking-widest text-gray-500 dark:text-gray-400">
          {detail.status}
          {detail.approvedByName && ` · approved by ${detail.approvedByName}`}
        </span>
      </footer>

      {rejecting && (
        <div className="mt-4 space-y-2 rounded-lg border border-gray-300 p-4 dark:border-gray-600">
          <label htmlFor="reject-reason" className="block text-sm font-semibold text-gray-900 dark:text-white">
            What needs changing?
          </label>
          <textarea
            id="reject-reason"
            rows={3}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="This is recorded with the proposal, so say enough for the author to act on it."
            className="w-full rounded border border-gray-300 bg-white p-2 text-gray-900
                       dark:border-gray-600 dark:bg-gray-900 dark:text-white"
          />
          <div className="flex gap-2">
            <button
              type="button"
              disabled={busy || reason.trim() === ''}
              onClick={() =>
                act(
                  () =>
                    apiFetch(`/compass/revisions/${detail.id}/reject`, {
                      method: 'POST',
                      body: JSON.stringify({ reason: reason.trim() }),
                    }),
                  'Changes requested.',
                  true
                )
              }
              className="rounded border border-gray-400 px-3 py-1.5 font-semibold text-gray-700 hover:bg-gray-100
                         disabled:opacity-50 dark:border-gray-500 dark:text-gray-200 dark:hover:bg-gray-800"
            >
              Send
            </button>
            <button
              type="button"
              onClick={() => setRejecting(false)}
              className="px-3 py-1.5 text-gray-600 hover:underline dark:text-gray-300"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function BackLink() {
  return (
    <Link
      to="/admin/review?tab=topics"
      className="mb-4 inline-block text-sm text-gray-500 hover:text-gray-900 dark:hover:text-white"
    >
      &larr; Review Queue
    </Link>
  );
}
