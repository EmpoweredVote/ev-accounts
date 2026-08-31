import { useCallback, useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router';
import { apiFetch } from '../../lib/api';
import { InlineDiff } from '../../components/wordDiffView';
import {
  buildProposalPayload,
  changedFields,
  seedEdited,
  validateProposal,
  type ChangeClass,
  type CurrentTopicContent,
  type EditedContent,
} from './proposeRevision';

/**
 * The revision editor: edit a topic's wording with the current text and a live
 * word-diff always in view, then file the result into the review queue
 * (propose → approve → publish → re-pin on /admin/seasons).
 *
 * Chairs are reworded IN PLACE. Moving, merging, or removing a chair is
 * refused at publish (answer re-pointing is not built — ADR 0004 §4), so this
 * editor does not offer it.
 */

const OPT_COLORS = ['#2f6fb0', '#59B0C4', '#9ca3af', '#e0a63a', '#FF5740'];

const CHANGE_CLASSES: { value: ChangeClass; label: string; hint: string }[] = [
  { value: 'editorial', label: 'Editorial', hint: 'Typos and formatting. Meaning untouched. No version bump.' },
  { value: 'clarifying', label: 'Clarifying', hint: 'Clearer wording, same position. No version bump.' },
  { value: 'substantive', label: 'Substantive', hint: 'Changes what a position means or covers. Version bumps.' },
];

const FIELD_INPUT =
  'w-full rounded border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 ' +
  'dark:border-gray-600 dark:bg-gray-800 dark:text-white';

function DiffPreview({ prev, next, changed }: { prev: string; next: string; changed: boolean }) {
  if (!changed) return null;
  return (
    <p className="mt-1.5 rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm leading-relaxed text-gray-900 dark:border-amber-800 dark:bg-amber-950/30 dark:text-gray-100">
      <InlineDiff prev={prev} next={next} />
    </p>
  );
}

export function ProposeRevisionPage() {
  const { topicKey } = useParams<{ topicKey: string }>();
  const navigate = useNavigate();

  const [current, setCurrent] = useState<CurrentTopicContent | null>(null);
  const [edited, setEdited] = useState<EditedContent | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [problems, setProblems] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!topicKey) return;
    apiFetch<CurrentTopicContent>(`/compass/revisions/current/${topicKey}`)
      .then((c) => {
        setCurrent(c);
        setEdited(seedEdited(c));
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load topic'))
      .finally(() => setLoading(false));
  }, [topicKey]);

  const set = useCallback(<K extends keyof EditedContent>(key: K, value: EditedContent[K]) => {
    setEdited((e) => (e ? { ...e, [key]: value } : e));
  }, []);

  if (loading) return <p className="text-sm text-gray-500 dark:text-gray-400">Loading…</p>;
  if (error || !current || !edited) {
    return (
      <p role="alert" className="rounded border border-amber-600 bg-amber-50 px-3 py-2 text-sm text-amber-900 dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-100">
        {error ?? 'Topic not found'}
      </p>
    );
  }

  const changes = changedFields(current, edited);
  const nextVersion = edited.changeClass === 'substantive' ? current.version + 1 : current.version;

  const submit = async () => {
    const found = validateProposal(current, edited);
    setProblems(found);
    if (found.length > 0) return;
    setBusy(true);
    setError(null);
    try {
      await apiFetch('/compass/revisions', {
        method: 'POST',
        body: JSON.stringify(buildProposalPayload(current, edited)),
      });
      navigate('/admin/review?tab=topics');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to file the proposal');
      setBusy(false);
    }
  };

  return (
    <div className="max-w-4xl">
      <div className="mb-1 flex flex-wrap items-baseline gap-3">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Propose a revision</h1>
        <span className="font-mono text-xs uppercase tracking-widest text-gray-500 dark:text-gray-400">
          {current.topicKey} · editing from rev {current.revision} (v{current.version}) → will file as v{nextVersion}
        </span>
      </div>
      <p className="mb-4 max-w-2xl text-sm text-gray-500 dark:text-gray-400">
        Edit the wording below. Every change shows as a live diff — exactly what the reviewer
        and the season composer will see. Filing does not change anything voters see; the
        proposal goes to the <Link to="/admin/review?tab=topics" className="text-ev-teal underline dark:text-ev-teal-light">Review Queue</Link> for
        approval and publish first.
      </p>

      <p className="mb-6 rounded border border-cyan-200 bg-cyan-50 px-3 py-2 text-sm text-ev-teal dark:border-cyan-900 dark:bg-cyan-950/40 dark:text-ev-teal-light">
        Chairs keep their positions: option 1 stays option 1. Moving, merging, or removing a
        chair is not supported yet — existing recorded stances point at chair positions, and
        the machinery to move them is not built (ADR 0004 §4).
      </p>

      <div className="space-y-5">
        <div>
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Title
          </label>
          <input value={edited.title} onChange={(e) => set('title', e.target.value)} className={FIELD_INPUT} />
          <DiffPreview prev={current.title} next={edited.title} changed={changes.title} />
        </div>

        <div>
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Short title
          </label>
          <input value={edited.shortTitle} onChange={(e) => set('shortTitle', e.target.value)} className={FIELD_INPUT} />
          <DiffPreview prev={current.shortTitle ?? ''} next={edited.shortTitle} changed={changes.shortTitle} />
        </div>

        <div>
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Question
          </label>
          <textarea rows={2} value={edited.questionText} onChange={(e) => set('questionText', e.target.value)} className={FIELD_INPUT} />
          <DiffPreview prev={current.questionText} next={edited.questionText} changed={changes.questionText} />
        </div>

        <div>
          <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            The five options
          </p>
          <div className="space-y-3">
            {edited.rungs.map((text, i) => (
              <div key={i} className="grid grid-cols-[26px_1fr] gap-3">
                <span
                  className="mt-1.5 flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold text-gray-950"
                  style={{ background: OPT_COLORS[i] }}
                >
                  {i + 1}
                </span>
                <div>
                  <textarea
                    rows={2}
                    value={text}
                    onChange={(e) => {
                      const rungs = [...edited.rungs];
                      rungs[i] = e.target.value;
                      set('rungs', rungs);
                    }}
                    className={FIELD_INPUT}
                  />
                  <DiffPreview
                    prev={current.ladder.find((r) => r.value === i + 1)?.text ?? ''}
                    next={text}
                    changed={changes.rungs[i]}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        <div>
          <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Change class
          </p>
          <div className="grid gap-2 sm:grid-cols-3">
            {CHANGE_CLASSES.map((c) => (
              <label
                key={c.value}
                className={`cursor-pointer rounded-lg border p-3 text-sm ${edited.changeClass === c.value
                  ? 'border-ev-teal bg-cyan-50 dark:border-ev-teal-light dark:bg-cyan-950/40'
                  : 'border-gray-200 dark:border-gray-700'}`}
              >
                <input
                  type="radio"
                  name="change_class"
                  className="mr-2"
                  checked={edited.changeClass === c.value}
                  onChange={() => set('changeClass', c.value)}
                />
                <span className="font-semibold text-gray-900 dark:text-white">{c.label}</span>
                <span className="mt-1 block text-xs text-gray-500 dark:text-gray-400">{c.hint}</span>
              </label>
            ))}
          </div>
        </div>

        <div>
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Rationale (for the reviewer — why this change, with evidence)
          </label>
          <textarea rows={3} value={edited.rationale} onChange={(e) => set('rationale', e.target.value)} className={FIELD_INPUT} />
        </div>

        <div>
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Public note (voter-facing — what changed and why, in plain language)
          </label>
          <textarea rows={2} value={edited.publicNote} onChange={(e) => set('publicNote', e.target.value)} className={FIELD_INPUT} />
        </div>

        <div>
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Review reference (optional — a document or link backing the change)
          </label>
          <input value={edited.reviewRef} onChange={(e) => set('reviewRef', e.target.value)} className={FIELD_INPUT} />
        </div>

        {problems.length > 0 && (
          <ul role="alert" className="list-disc rounded border border-amber-600 bg-amber-50 py-2 pl-8 pr-3 text-sm text-amber-900 dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-100">
            {problems.map((p) => <li key={p}>{p}</li>)}
          </ul>
        )}
        {error && (
          <p role="alert" className="rounded border border-amber-600 bg-amber-50 px-3 py-2 text-sm text-amber-900 dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-100">
            {error}
          </p>
        )}

        <div className="flex items-center gap-3 border-t border-gray-200 pt-4 dark:border-gray-700">
          <button
            onClick={() => void submit()}
            disabled={busy}
            className="rounded bg-ev-red px-4 py-2 font-semibold text-white transition-colors hover:opacity-90 disabled:opacity-50"
          >
            {busy ? 'Filing…' : 'File for review'}
          </button>
          <button
            onClick={() => navigate(-1)}
            className="rounded px-4 py-2 text-sm font-semibold text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
          >
            Cancel
          </button>
          {changes.anyChanged && (
            <span className="text-xs text-gray-500 dark:text-gray-400">
              {[
                changes.title && 'title',
                changes.shortTitle && 'short title',
                changes.questionText && 'question',
                changes.ladderChanged && `${changes.rungs.filter(Boolean).length} option(s)`,
              ].filter(Boolean).join(', ')} changed
            </span>
          )}
        </div>
      </div>
    </div>
  );
}
