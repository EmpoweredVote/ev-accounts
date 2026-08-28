import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router';
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';
import { apiFetch } from '../../lib/api';
import { diffWords, hasChanged } from '../../lib/wordDiff';
import {
  classifyAll,
  statCounts,
  type Classified,
  type CompositionPayload,
  type CompositionTopic,
  type RevisionContent,
  type SeasonRow,
} from './seasonComposition';

/**
 * Season composition — one screen, two modes (decision with Chris, 2026-08-28):
 * an operational compose screen (carry / drop / add / re-pin against a draft
 * season) and a board-facing presentation view of the same draft. One payload,
 * one classification (seasonComposition.ts), so the visual cannot drift from
 * the plan. Pins are set at COMPOSE time; a newer published revision shows as
 * a stale-pin flag with an explicit re-pin action while the season is draft.
 */

const OPT_COLORS = ['#2f6fb0', '#59B0C4', '#9ca3af', '#e0a63a', '#FF5740'];

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

/** Five-segment mini bar of the open season's answer mix. */
function SparkBar({ topic }: { topic: CompositionTopic }) {
  if (!topic.answer_total) {
    return <span className="ml-auto shrink-0 text-[10px] text-gray-400 dark:text-gray-500">no data</span>;
  }
  return (
    <span
      className="ml-auto flex h-3 w-20 shrink-0 overflow-hidden rounded-sm"
      title={`${topic.answer_total.toLocaleString()} Season answers`}
    >
      {[1, 2, 3, 4, 5].map((v) => {
        const pct = (100 * (topic.distribution[v] ?? 0)) / topic.answer_total;
        return pct > 0
          ? <span key={v} style={{ width: `${pct}%`, background: OPT_COLORS[v - 1] }} />
          : null;
      })}
    </span>
  );
}

const STATUS_BADGE: Record<string, { label: string; cls: string }> = {
  changed: { label: 'Changed', cls: 'bg-ev-yellow text-yellow-900' },
  dropped: { label: 'Retired', cls: 'bg-gray-200 text-gray-600 dark:bg-gray-700 dark:text-gray-300' },
  added: { label: 'New', cls: 'bg-ev-teal text-white' },
};

function StatusBadge({ status }: { status: string }) {
  const b = STATUS_BADGE[status];
  if (!b) return null;
  return (
    <span className={`shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wide ${b.cls}`}>
      {b.label}
    </span>
  );
}

/** Option rows with the open season's distribution bars. */
function OptionList({ ladder, topic, withDist }: {
  ladder: { value: number; text: string }[];
  topic: CompositionTopic;
  withDist: boolean;
}) {
  return (
    <div>
      {ladder.map((opt) => {
        const count = topic.distribution[opt.value] ?? 0;
        const pct = topic.answer_total ? Math.round((1000 * count) / topic.answer_total) / 10 : 0;
        return (
          <div
            key={opt.value}
            className="grid grid-cols-[26px_1fr] items-center gap-3 border-b border-gray-100 py-2 last:border-0 dark:border-gray-800 sm:grid-cols-[26px_1fr_200px]"
          >
            <span
              className="flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold text-gray-950"
              style={{ background: OPT_COLORS[opt.value - 1] }}
            >
              {opt.value}
            </span>
            <span className="text-sm leading-snug text-gray-700 dark:text-gray-300">{opt.text}</span>
            {withDist && (
              <span className="col-start-2 flex items-center gap-2 sm:col-start-3">
                <span className="h-3 flex-1 overflow-hidden rounded bg-gray-200 dark:bg-gray-700">
                  <span
                    className="block h-full rounded-l"
                    style={{ width: `${pct}%`, background: OPT_COLORS[opt.value - 1] }}
                  />
                </span>
                <span className="w-20 shrink-0 text-right text-xs tabular-nums text-gray-600 dark:text-gray-300">
                  {pct}% · {count.toLocaleString()}
                </span>
              </span>
            )}
          </div>
        );
      })}
    </div>
  );
}

/**
 * Ladder diff for a changed/stale topic: rung-by-rung, word-level. Rungs pair
 * by VALUE, never by array position — the guard and the render must use the
 * same pairing or a ladder that gained/lost a rung reads as "unchanged".
 */
function LadderDiff({ prev, next }: { prev: RevisionContent; next: RevisionContent }) {
  const removed = prev.ladder.filter((p) => !next.ladder.some((n) => n.value === p.value));
  const anyChanged =
    removed.length > 0 ||
    next.ladder.some((n) =>
      hasChanged(prev.ladder.find((x) => x.value === n.value)?.text ?? null, n.text));
  if (!anyChanged) {
    return <p className="text-sm italic text-gray-500 dark:text-gray-400">The options are unchanged.</p>;
  }
  return (
    <div>
      {next.ladder.map((n) => {
        const p = prev.ladder.find((x) => x.value === n.value);
        return (
          <div key={n.value} className="grid grid-cols-[26px_1fr] items-start gap-3 border-b border-gray-100 py-2 last:border-0 dark:border-gray-800">
            <span
              className="flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold text-gray-950"
              style={{ background: OPT_COLORS[n.value - 1] }}
            >
              {n.value}
            </span>
            <span className="text-sm leading-snug text-gray-700 dark:text-gray-300">
              {hasChanged(p?.text ?? null, n.text)
                ? <InlineDiff prev={p?.text ?? null} next={n.text} />
                : n.text}
            </span>
          </div>
        );
      })}
      {removed.map((p) => (
        <div key={p.value} className="grid grid-cols-[26px_1fr] items-start gap-3 border-b border-gray-100 py-2 last:border-0 dark:border-gray-800">
          <span
            className="flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold text-gray-950 opacity-50"
            style={{ background: OPT_COLORS[p.value - 1] }}
          >
            {p.value}
          </span>
          <del className={`${DEL} text-sm leading-snug`}>{p.text}</del>
        </div>
      ))}
    </div>
  );
}

const CATEGORY_CHIP: Record<string, { label: string; cls: string }> = {
  carried: { label: 'Carried forward unchanged', cls: 'bg-green-100 text-green-800 dark:bg-green-900/60 dark:text-green-200' },
  changed: { label: 'Changed for the draft season', cls: 'bg-ev-yellow text-yellow-900' },
  dropped: { label: 'Retired in the draft season', cls: 'bg-gray-200 text-gray-600 dark:bg-gray-700 dark:text-gray-300' },
  added: { label: 'New in the draft season', cls: 'bg-ev-teal text-white' },
  available: { label: 'In the topic pool (not asked)', cls: 'bg-gray-200 text-gray-600 dark:bg-gray-700 dark:text-gray-300' },
};

function TopicDetailModal({ item, openSeason, onClose }: {
  item: Classified | null;
  openSeason: SeasonRow | null;
  onClose: () => void;
}) {
  if (!item) return <Dialog open={false} onClose={onClose} className="relative z-50"><span /></Dialog>;
  const t = item.topic;
  const chip = CATEGORY_CHIP[item.status];
  // What to show as "the" content: the draft pin when present, else open pin, else current.
  const main = t.in_draft?.pin ?? t.in_open?.pin ?? t.current;
  const isChanged = item.status === 'changed' && t.in_open && t.in_draft;
  return (
    <Dialog open onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/50" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <DialogPanel className="max-h-[90vh] w-full max-w-3xl overflow-y-auto rounded-lg bg-white p-6 shadow-xl dark:bg-gray-900">
          <span className={`inline-block rounded px-2 py-0.5 text-[11px] font-bold uppercase tracking-wide ${chip.cls}`}>
            {chip.label}
          </span>
          <DialogTitle className="mt-2 text-xl font-semibold text-gray-900 dark:text-white">
            {main?.title ?? t.topic_key}
          </DialogTitle>
          <p className="mb-4 text-xs text-gray-500 dark:text-gray-400">
            {t.in_open
              ? `${openSeason?.name ?? 'Open season'} · question ${t.in_open.question_number}`
              : 'Not asked in the open season'}
            {item.pin_is_stale && t.in_draft && t.current && (
              <span className="ml-2 rounded bg-amber-100 px-1.5 py-0.5 font-semibold text-amber-800 dark:bg-amber-950/60 dark:text-amber-200">
                newer revision available: rev {t.in_draft.pin.revision} → {t.current.revision}
              </span>
            )}
          </p>

          {isChanged && t.in_open && t.in_draft ? (
            <div className="mb-4 space-y-3 rounded-lg border border-amber-300 bg-amber-50 p-4 dark:border-amber-700 dark:bg-amber-950/40">
              <p className="text-xs font-bold uppercase tracking-wide text-amber-800 dark:text-amber-300">
                What changes (rev {t.in_open.pin.revision} → {t.in_draft.pin.revision})
              </p>
              <FieldDiff label="Title" prev={t.in_open.pin.title} next={t.in_draft.pin.title} />
              <FieldDiff label="Short title" prev={t.in_open.pin.short_title} next={t.in_draft.pin.short_title} />
              <FieldDiff label="Question" prev={t.in_open.pin.question_text} next={t.in_draft.pin.question_text} />
              <div>
                <span className="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
                  Options
                </span>
                <LadderDiff prev={t.in_open.pin} next={t.in_draft.pin} />
              </div>
            </div>
          ) : (
            main && (
              <blockquote className="mb-4 rounded-r-lg border-l-4 border-ev-teal-light bg-gray-50 px-4 py-3 text-gray-800 dark:bg-gray-800 dark:text-gray-100">
                “{main.question_text}”
              </blockquote>
            )
          )}

          {main && !isChanged && (
            <>
              <p className="mb-2 text-xs font-bold uppercase tracking-wide text-gray-500 dark:text-gray-400">
                {t.in_open && t.answer_total > 0
                  ? `The five options, and where ${t.answer_total.toLocaleString()} politicians' most recent answers landed`
                  : 'The five options'}
              </p>
              <OptionList ladder={main.ladder} topic={t} withDist={Boolean(t.in_open && t.answer_total > 0)} />
              {!t.in_open && (
                <p className="mt-3 rounded border border-ev-teal/40 bg-cyan-50 px-3 py-2 text-sm text-ev-teal dark:bg-cyan-950/40 dark:text-ev-teal-light">
                  No answer data yet — no politician has a recorded answer on this topic.
                </p>
              )}
            </>
          )}

          {isChanged && t.in_open && t.answer_total > 0 && (
            <>
              <p className="mb-2 mt-2 text-xs font-bold uppercase tracking-wide text-gray-500 dark:text-gray-400">
                Where {t.answer_total.toLocaleString()} politicians' most recent answers landed (given against the old wording)
              </p>
              <OptionList ladder={t.in_open.pin.ladder} topic={t} withDist />
            </>
          )}

          <div className="mt-5 text-right">
            <button
              onClick={onClose}
              className="rounded bg-gray-200 px-4 py-2 text-sm font-semibold text-gray-800 hover:bg-gray-300 dark:bg-gray-700 dark:text-gray-100 dark:hover:bg-gray-600"
            >
              Close
            </button>
          </div>
        </DialogPanel>
      </div>
    </Dialog>
  );
}

function ConfirmDialog({ open, title, body, confirmLabel, danger, busy, error, onConfirm, onClose }: {
  open: boolean;
  title: string;
  body: React.ReactNode;
  confirmLabel: string;
  danger?: boolean;
  busy: boolean;
  error: string | null;
  onConfirm: () => void;
  onClose: () => void;
}) {
  return (
    <Dialog open={open} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <DialogPanel className="w-full max-w-md rounded-lg bg-white p-6 shadow-xl dark:bg-gray-900">
          <DialogTitle className="mb-3 text-lg font-semibold text-gray-900 dark:text-white">
            {title}
          </DialogTitle>
          <div className="mb-4 text-sm text-gray-600 dark:text-gray-300">{body}</div>
          {error && (
            <p role="alert" className="mb-4 rounded border border-amber-600 bg-amber-50 px-3 py-2 text-sm text-amber-900 dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-100">
              {error}
            </p>
          )}
          <div className="flex justify-end gap-2">
            <button
              onClick={onClose}
              className="rounded px-4 py-2 text-sm font-semibold text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              Cancel
            </button>
            <button
              onClick={onConfirm}
              disabled={busy}
              className={`rounded px-4 py-2 text-sm font-semibold text-white transition-colors hover:opacity-90 disabled:opacity-50 ${danger ? 'bg-ev-red' : 'bg-ev-teal'}`}
            >
              {busy ? 'Working…' : confirmLabel}
            </button>
          </div>
        </DialogPanel>
      </div>
    </Dialog>
  );
}

function CreateDraftModal({ open, nextNumber, busy, error, onCreate, onClose }: {
  open: boolean;
  nextNumber: number;
  busy: boolean;
  error: string | null;
  onCreate: (name: string, note: string, carry: boolean) => void;
  onClose: () => void;
}) {
  const [name, setName] = useState(`Season ${nextNumber}`);
  const [note, setNote] = useState('');
  const [carry, setCarry] = useState(true);
  useEffect(() => {
    if (open) setName(`Season ${nextNumber}`);
  }, [open, nextNumber]);
  return (
    <Dialog open={open} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <DialogPanel className="w-full max-w-lg rounded-lg bg-white p-6 shadow-xl dark:bg-gray-900">
          <DialogTitle className="mb-4 text-lg font-semibold text-gray-900 dark:text-white">
            Start a draft season
          </DialogTitle>
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Name
          </label>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="mb-3 w-full rounded border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
          />
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Public note (transparency surface — why this season exists)
          </label>
          <textarea
            value={note}
            onChange={(e) => setNote(e.target.value)}
            rows={4}
            placeholder="e.g. Season 2 retires settled questions and adds the issues this cycle is actually contesting."
            className="mb-3 w-full rounded border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
          />
          <label className="mb-4 flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
            <input type="checkbox" checked={carry} onChange={(e) => setCarry(e.target.checked)} />
            Carry every topic from the open season (pinned to today's revisions)
          </label>
          {error && (
            <p role="alert" className="mb-4 rounded border border-amber-600 bg-amber-50 px-3 py-2 text-sm text-amber-900 dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-100">
              {error}
            </p>
          )}
          <div className="flex justify-end gap-2">
            <button
              onClick={onClose}
              className="rounded px-4 py-2 text-sm font-semibold text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              Cancel
            </button>
            <button
              onClick={() => onCreate(name, note, carry)}
              disabled={busy || !name.trim() || !note.trim()}
              className="rounded bg-ev-red px-4 py-2 text-sm font-semibold text-white transition-colors hover:opacity-90 disabled:opacity-50"
            >
              {busy ? 'Creating…' : 'Create draft'}
            </button>
          </div>
        </DialogPanel>
      </div>
    </Dialog>
  );
}

/** Edit a draft's name and public note (PATCH /admin/seasons/draft/:id). */
function EditDraftModal({ open, draft, busy, error, onSave, onClose }: {
  open: boolean;
  draft: SeasonRow | null;
  busy: boolean;
  error: string | null;
  onSave: (name: string, note: string) => void;
  onClose: () => void;
}) {
  const [name, setName] = useState('');
  const [note, setNote] = useState('');
  useEffect(() => {
    if (open && draft) {
      setName(draft.name);
      setNote(draft.public_note);
    }
  }, [open, draft]);
  return (
    <Dialog open={open} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <DialogPanel className="w-full max-w-lg rounded-lg bg-white p-6 shadow-xl dark:bg-gray-900">
          <DialogTitle className="mb-4 text-lg font-semibold text-gray-900 dark:text-white">
            Edit draft season
          </DialogTitle>
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Name
          </label>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="mb-3 w-full rounded border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
          />
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            Public note
          </label>
          <textarea
            value={note}
            onChange={(e) => setNote(e.target.value)}
            rows={4}
            className="mb-3 w-full rounded border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
          />
          {error && (
            <p role="alert" className="mb-4 rounded border border-amber-600 bg-amber-50 px-3 py-2 text-sm text-amber-900 dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-100">
              {error}
            </p>
          )}
          <div className="flex justify-end gap-2">
            <button
              onClick={onClose}
              className="rounded px-4 py-2 text-sm font-semibold text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              Cancel
            </button>
            <button
              onClick={() => onSave(name, note)}
              disabled={busy || !name.trim() || !note.trim()}
              className="rounded bg-ev-teal px-4 py-2 text-sm font-semibold text-white transition-colors hover:opacity-90 disabled:opacity-50"
            >
              {busy ? 'Saving…' : 'Save'}
            </button>
          </div>
        </DialogPanel>
      </div>
    </Dialog>
  );
}

/** Stat block shared by both modes (presentation renders it on dark). */
function StatBand({ counts, dark }: {
  counts: { carried: number; changed: number; dropped: number; added: number };
  dark?: boolean;
}) {
  const blocks = [
    { n: counts.carried, label: 'Carried forward', hint: 'same question, same ladder', cls: dark ? 'bg-[#0d3321] text-green-400' : 'bg-green-50 text-green-700 border border-green-200 dark:bg-[#0d3321] dark:text-green-400 dark:border-transparent' },
    { n: counts.changed, label: 'Changed', hint: 'carried with revised wording', cls: dark ? 'bg-[#3d2c07] text-ev-yellow' : 'bg-amber-50 text-amber-700 border border-amber-200 dark:bg-[#3d2c07] dark:text-ev-yellow dark:border-transparent' },
    { n: counts.dropped, label: 'Retired', hint: 'previous season only', cls: dark ? 'bg-[#26282c] text-gray-400' : 'bg-gray-50 text-gray-500 border border-gray-200 dark:bg-[#26282c] dark:text-gray-400 dark:border-transparent' },
    { n: counts.added, label: 'New', hint: 'first asked in the draft', cls: dark ? 'bg-[#04303c] text-ev-teal-light' : 'bg-cyan-50 text-ev-teal border border-cyan-200 dark:bg-[#04303c] dark:text-ev-teal-light dark:border-transparent' },
  ];
  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
      {blocks.map((b) => (
        <div key={b.label} className={`rounded-xl p-4 ${b.cls}`}>
          <div className={`font-extrabold leading-none ${dark ? 'text-5xl' : 'text-4xl'}`}>{b.n}</div>
          <div className="mt-2 text-xs font-bold uppercase tracking-wider">{b.label}</div>
          <div className="mt-0.5 text-xs opacity-75">{b.hint}</div>
        </div>
      ))}
    </div>
  );
}

interface MutationTarget {
  kind: 'delete-draft' | 'open-season' | null;
}

export function SeasonCompositionPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const presentation = searchParams.get('view') === 'presentation';

  const [data, setData] = useState<CompositionPayload | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [detail, setDetail] = useState<Classified | null>(null);
  const [createOpen, setCreateOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  // The RPC assigns max(number)+1 over ALL seasons; open.number+1 is wrong the
  // moment history holds a closed season above the open one (CA_0020 happened).
  const [nextNumber, setNextNumber] = useState<number | null>(null);
  const [confirm, setConfirm] = useState<MutationTarget>({ kind: null });

  const load = useCallback(async () => {
    setError(null);
    try {
      setData(await apiFetch<CompositionPayload>('/admin/seasons/composition'));
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load composition';
      // A failed RELOAD must not blank a working page: keep the (stale) data
      // and surface the failure beside it. Only the initial load may take
      // over the whole page.
      setData((prev) => {
        if (prev) setActionError(`Reload failed — showing possibly stale data. ${message}`);
        else setError(message);
        return prev;
      });
    } finally {
      setLoading(false);
    }
  }, []);
  useEffect(() => { void load(); }, [load]);

  // Presentation mode is board-facing and always dark. Dark is a global .dark
  // class on <html> (HeadlessUI portals to <body>, so forcing it at the root
  // is what keeps the modal dark too). Restore the previous state on exit.
  useEffect(() => {
    if (!presentation) return;
    const el = document.documentElement;
    const wasDark = el.classList.contains('dark');
    el.classList.add('dark');
    return () => { if (!wasDark) el.classList.remove('dark'); };
  }, [presentation]);

  const open = data?.open_season ?? null;
  const draft = data?.draft_season ?? null;

  const openCreateModal = useCallback(async () => {
    setActionError(null);
    let next = (open?.number ?? 0) + 1;
    try {
      const { seasons } = await apiFetch<{ seasons: SeasonRow[] }>('/admin/seasons');
      next = seasons.reduce((m, s) => Math.max(m, s.number), 0) + 1;
    } catch {
      // fall back to the open season's number; the RPC assigns the real one
    }
    setNextNumber(next);
    setCreateOpen(true);
  }, [open]);
  const classified = useMemo(
    () => classifyAll(data?.topics ?? [], Boolean(draft)),
    [data, draft],
  );
  const counts = useMemo(() => statCounts(classified), [classified]);
  const openRows = useMemo(
    () => classified.filter((c) => c.topic.in_open)
      .sort((a, b) => (a.topic.in_open?.display_order ?? 0) - (b.topic.in_open?.display_order ?? 0)),
    [classified],
  );
  const draftRows = useMemo(
    () => classified.filter((c) => c.topic.in_draft)
      .sort((a, b) => (a.topic.in_draft?.display_order ?? 0) - (b.topic.in_draft?.display_order ?? 0)),
    [classified],
  );
  const droppedRows = useMemo(() => classified.filter((c) => c.status === 'dropped'), [classified]);
  const poolRows = useMemo(() => classified.filter((c) => c.status === 'available'), [classified]);
  const draftCount = draftRows.length;

  /** Run a mutation, surface its server message, reload on success. */
  const act = useCallback(async (fn: () => Promise<unknown>) => {
    setBusy(true);
    setActionError(null);
    try {
      await fn();
      await load();
      return true;
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Action failed');
      return false;
    } finally {
      setBusy(false);
    }
  }, [load]);

  const dropTopic = (topicId: string) => draft && act(() =>
    apiFetch(`/admin/seasons/draft/${draft.id}/topics/${topicId}`, { method: 'DELETE' }));
  const addTopic = (topicId: string) => draft && act(() =>
    apiFetch(`/admin/seasons/draft/${draft.id}/topics`, {
      method: 'POST', body: JSON.stringify({ topic_id: topicId }),
    }));
  const repin = (topicId: string) => draft && act(() =>
    apiFetch(`/admin/seasons/draft/${draft.id}/topics/${topicId}/repin`, { method: 'POST' }));

  if (loading) return <p className="text-sm text-gray-500 dark:text-gray-400">Loading…</p>;
  if (error) {
    return (
      <p role="alert" className="rounded border border-amber-600 bg-amber-50 px-3 py-2 text-sm text-amber-900 dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-100">
        {error}
      </p>
    );
  }
  if (!data) return null;

  // ------------------------------------------------------------------
  // Presentation mode — the board visual (always dark, read-only)
  // ------------------------------------------------------------------
  if (presentation) {
    return (
      <div className="-m-8 min-h-screen bg-[#17181a] p-8 text-gray-100">
        <div className="mx-auto max-w-6xl">
          <p className="text-xs font-bold uppercase tracking-[0.14em] text-ev-yellow">
            Empowered Compass · Board review
          </p>
          <h1 className="mt-2 text-4xl font-bold tracking-tight text-white">
            {draft ? `${draft.name}: what's changing` : open ? `${open.name}: the question set` : 'Seasons'}
          </h1>
          <p className="mt-2 max-w-3xl text-sm text-gray-400">
            {open
              ? `${open.name} asks ${open.question_count} questions. `
              : ''}
            {draft?.public_note
              ? draft.public_note + ' Click any topic — even an unchanged one — for its question, its five options, and how politicians actually answered.'
              : 'Click any topic for its question, its five options, and how politicians answered.'}
          </p>

          <div className="mt-8">
            <StatBand counts={counts} dark />
          </div>
          {draft && open && (
            <p className="mt-6 text-center text-sm text-gray-300">
              <b className="text-lg text-white">{open.question_count}</b> questions in {open.name}
              {' '}−{' '}<b className="text-lg text-white">{counts.dropped}</b> retired
              {' '}+{' '}<b className="text-lg text-white">{counts.added}</b> new
              {' '}={' '}<b className="text-lg text-white">{draftCount}</b> questions in {draft.name}
            </p>
          )}

          <div className="mt-4 flex flex-wrap items-center justify-center gap-4 text-xs text-gray-400">
            <span>Season answer mix per topic:</span>
            {[1, 2, 3, 4, 5].map((v) => (
              <span key={v} className="flex items-center gap-1.5">
                <span className="h-2.5 w-2.5 rounded-sm" style={{ background: OPT_COLORS[v - 1] }} />
                {v === 1 ? 'Option 1' : v === 5 ? 'Option 5' : v}
              </span>
            ))}
          </div>

          <div className={`mt-6 grid gap-6 ${draft ? 'lg:grid-cols-2' : ''}`}>
            <section className="overflow-hidden rounded-xl border border-[#35373d] bg-[#212226]">
              <h2 className="flex items-center gap-2 bg-black px-4 py-3 text-white">
                <span className="font-semibold">{open?.name ?? 'No open season'}</span>
                {open && (
                  <span className="rounded-full bg-ev-teal-light px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-cyan-950">
                    Open
                  </span>
                )}
                <span className="ml-auto text-xs text-gray-400">{openRows.length} questions</span>
              </h2>
              {openRows.map((c) => (
                <button
                  key={c.topic.topic_id}
                  onClick={() => setDetail(c)}
                  className={`flex w-full items-center gap-2 border-b border-[#2c2d32] px-4 py-1.5 text-left text-sm last:border-0 hover:bg-[#313238] ${c.status === 'changed' ? 'bg-[#2e2609]' : ''}`}
                >
                  <span className="w-6 shrink-0 text-right text-xs tabular-nums text-gray-500">
                    {c.topic.in_open?.question_number}
                  </span>
                  <span className={`truncate ${c.status === 'dropped' ? 'text-gray-500 line-through' : 'text-gray-200'}`}>
                    {c.topic.in_open?.pin.title}
                  </span>
                  <StatusBadge status={c.status} />
                  <SparkBar topic={c.topic} />
                </button>
              ))}
            </section>

            {draft && (
              <section className="overflow-hidden rounded-xl border border-[#35373d] bg-[#212226]">
                <h2 className="flex items-center gap-2 bg-black px-4 py-3 text-white">
                  <span className="font-semibold">{draft.name}</span>
                  <span className="rounded-full bg-ev-yellow px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-yellow-950">
                    Draft
                  </span>
                  <span className="ml-auto text-xs text-gray-400">{draftCount} questions</span>
                </h2>
                {draftRows.map((c, i) => (
                  <button
                    key={c.topic.topic_id}
                    onClick={() => setDetail(c)}
                    className={`flex w-full items-center gap-2 border-b border-[#2c2d32] px-4 py-1.5 text-left text-sm last:border-0 hover:bg-[#313238] ${c.status === 'changed' ? 'bg-[#2e2609]' : c.status === 'added' ? 'bg-[#0b3441]' : ''}`}
                  >
                    <span className="w-6 shrink-0 text-right text-xs tabular-nums text-gray-500">{i + 1}</span>
                    <span className={`truncate ${c.status === 'added' ? 'font-semibold text-cyan-200' : 'text-gray-200'}`}>
                      {c.topic.in_draft?.pin.title}
                    </span>
                    <StatusBadge status={c.status} />
                  </button>
                ))}
              </section>
            )}
          </div>
        </div>

        <button
          onClick={() => setSearchParams({})}
          className="fixed bottom-6 right-6 rounded-full bg-white px-4 py-2 text-sm font-semibold text-gray-900 shadow-lg hover:bg-gray-200"
        >
          Exit presentation
        </button>

        <TopicDetailModal item={detail} openSeason={open} onClose={() => setDetail(null)} />
      </div>
    );
  }

  // ------------------------------------------------------------------
  // Compose mode
  // ------------------------------------------------------------------
  return (
    <div>
      <div className="mb-6 flex flex-wrap items-center gap-3">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Season composition</h1>
        <button
          onClick={() => setSearchParams({ view: 'presentation' })}
          className="ml-auto rounded bg-ev-black px-4 py-2 text-sm font-semibold text-white hover:opacity-90 dark:bg-gray-700"
        >
          Presentation view
        </button>
      </div>

      {actionError && (
        <p role="alert" className="mb-4 rounded border border-amber-600 bg-amber-50 px-3 py-2 text-sm text-amber-900 dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-100">
          {actionError}
        </p>
      )}

      <div className="mb-6 grid gap-4 lg:grid-cols-2">
        <div className="rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-900">
          <p className="font-mono text-xs uppercase tracking-widest text-gray-500 dark:text-gray-400">Open season</p>
          {open ? (
            <>
              <p className="mt-1 text-lg font-semibold text-gray-900 dark:text-white">
                {open.name}
                <span className="ml-2 rounded-full bg-ev-teal-light px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-cyan-950">Open</span>
              </p>
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                {open.question_count} questions · open since {open.opened_at ? new Date(open.opened_at).toLocaleDateString() : '—'}
              </p>
            </>
          ) : (
            <p className="mt-1 text-sm text-amber-700 dark:text-amber-300">
              No season is open — compass writes are refusing until one opens.
            </p>
          )}
        </div>

        <div className="rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-900">
          <p className="font-mono text-xs uppercase tracking-widest text-gray-500 dark:text-gray-400">Draft season</p>
          {draft ? (
            <>
              <p className="mt-1 text-lg font-semibold text-gray-900 dark:text-white">
                {draft.name}
                <span className="ml-2 rounded-full bg-ev-yellow px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-yellow-950">Draft</span>
              </p>
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{draftCount} questions · pending board sign-off</p>
              <p className="mt-2 border-l-2 border-gray-300 pl-2 text-xs italic text-gray-500 dark:border-gray-600 dark:text-gray-400">
                {draft.public_note}
              </p>
              <div className="mt-3 flex gap-2">
                <button
                  onClick={() => { setActionError(null); setEditOpen(true); }}
                  disabled={busy}
                  className="rounded px-3 py-1.5 text-sm font-semibold text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                >
                  Edit name / note
                </button>
                <button
                  onClick={() => setConfirm({ kind: 'open-season' })}
                  disabled={busy}
                  className="rounded bg-ev-red px-3 py-1.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50"
                >
                  Open season…
                </button>
                <button
                  onClick={() => setConfirm({ kind: 'delete-draft' })}
                  disabled={busy}
                  className="rounded px-3 py-1.5 text-sm font-semibold text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
                >
                  Delete draft
                </button>
              </div>
            </>
          ) : (
            <>
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                No draft yet. Composing one does not affect the open season.
              </p>
              <button
                onClick={() => { void openCreateModal(); }}
                disabled={busy}
                className="mt-3 rounded bg-ev-red px-3 py-1.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50"
              >
                Start a new season draft
              </button>
            </>
          )}
        </div>
      </div>

      {draft && (
        <div className="mb-6">
          <StatBand counts={counts} />
        </div>
      )}

      <div className={`grid gap-6 ${draft ? 'lg:grid-cols-2' : ''}`}>
        <section className="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-700">
          <h2 className="bg-gray-900 px-4 py-2.5 text-sm font-semibold text-white dark:bg-black">
            {open?.name ?? 'No open season'} <span className="ml-1 font-normal text-gray-400">{openRows.length} questions</span>
          </h2>
          <div className="bg-white dark:bg-gray-900">
            {openRows.map((c) => (
              <button
                key={c.topic.topic_id}
                onClick={() => setDetail(c)}
                className={`flex w-full items-center gap-2 border-b border-gray-100 px-3 py-1.5 text-left text-sm last:border-0 hover:bg-gray-50 dark:border-gray-800 dark:hover:bg-gray-800 ${c.status === 'changed' ? 'bg-amber-50 dark:bg-amber-950/30' : ''}`}
              >
                <span className="w-6 shrink-0 text-right text-xs tabular-nums text-gray-400">
                  {c.topic.in_open?.question_number}
                </span>
                <span className={`truncate ${c.status === 'dropped' ? 'text-gray-400 line-through' : 'text-gray-800 dark:text-gray-200'}`}>
                  {c.topic.in_open?.pin.title}
                </span>
                <StatusBadge status={c.status} />
                <SparkBar topic={c.topic} />
              </button>
            ))}
          </div>
        </section>

        {draft && (
          <section className="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-700">
            <h2 className="bg-gray-900 px-4 py-2.5 text-sm font-semibold text-white dark:bg-black">
              {draft.name} <span className="ml-1 font-normal text-gray-400">{draftCount} questions</span>
            </h2>
            <div className="bg-white dark:bg-gray-900">
              {draftRows.map((c, i) => (
                <div
                  key={c.topic.topic_id}
                  className={`flex items-center gap-2 border-b border-gray-100 px-3 py-1.5 text-sm last:border-0 dark:border-gray-800 ${c.status === 'changed' ? 'bg-amber-50 dark:bg-amber-950/30' : c.status === 'added' ? 'bg-cyan-50 dark:bg-cyan-950/30' : ''}`}
                >
                  <span className="w-6 shrink-0 text-right text-xs tabular-nums text-gray-400">{i + 1}</span>
                  <button
                    onClick={() => setDetail(c)}
                    className="min-w-0 flex-1 truncate text-left text-gray-800 hover:underline dark:text-gray-200"
                  >
                    {c.topic.in_draft?.pin.title}
                  </button>
                  {c.pin_is_stale && (
                    <button
                      onClick={() => repin(c.topic.topic_id)}
                      disabled={busy}
                      title={`Pinned rev ${c.topic.in_draft?.pin.revision}; rev ${c.topic.current?.revision} is now current. Re-pin to pick it up.`}
                      className="shrink-0 rounded bg-amber-100 px-1.5 py-0.5 text-[10px] font-bold uppercase text-amber-800 hover:bg-amber-200 disabled:opacity-50 dark:bg-amber-950/60 dark:text-amber-200 dark:hover:bg-amber-900"
                    >
                      Re-pin rev {c.topic.current?.revision}
                    </button>
                  )}
                  <StatusBadge status={c.status} />
                  <button
                    onClick={() => dropTopic(c.topic.topic_id)}
                    disabled={busy}
                    className="shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold uppercase text-gray-400 hover:bg-red-50 hover:text-ev-red dark:hover:bg-red-950/40"
                  >
                    Drop
                  </button>
                </div>
              ))}

              {droppedRows.length > 0 && (
                <div className="border-t border-gray-200 dark:border-gray-700">
                  <p className="px-3 pb-1 pt-2 text-[10px] font-bold uppercase tracking-wide text-gray-400">
                    Retired from {open?.name}
                  </p>
                  {droppedRows.map((c) => (
                    <div key={c.topic.topic_id} className="flex items-center gap-2 px-3 py-1.5 text-sm">
                      <span className="w-6 shrink-0" />
                      <button
                        onClick={() => setDetail(c)}
                        className="min-w-0 flex-1 truncate text-left text-gray-400 line-through hover:underline"
                      >
                        {c.topic.in_open?.pin.title}
                      </button>
                      <button
                        onClick={() => addTopic(c.topic.topic_id)}
                        disabled={busy}
                        className="shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold uppercase text-ev-teal hover:bg-cyan-50 dark:hover:bg-cyan-950/40"
                      >
                        Re-add
                      </button>
                    </div>
                  ))}
                </div>
              )}

              {poolRows.length > 0 && (
                <div className="border-t border-gray-200 dark:border-gray-700">
                  <p className="px-3 pb-1 pt-2 text-[10px] font-bold uppercase tracking-wide text-gray-400">
                    Topic pool — has a published ladder, not asked in either season
                  </p>
                  {poolRows.map((c) => (
                    <div key={c.topic.topic_id} className="flex items-center gap-2 px-3 py-1.5 text-sm">
                      <span className="w-6 shrink-0" />
                      <button
                        onClick={() => setDetail(c)}
                        className="min-w-0 flex-1 truncate text-left text-gray-600 hover:underline dark:text-gray-400"
                      >
                        {c.topic.current?.title ?? c.topic.topic_key}
                      </button>
                      <button
                        onClick={() => addTopic(c.topic.topic_id)}
                        disabled={busy}
                        className="shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold uppercase text-ev-teal hover:bg-cyan-50 dark:hover:bg-cyan-950/40"
                      >
                        Add
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </section>
        )}
      </div>

      <TopicDetailModal item={detail} openSeason={open} onClose={() => setDetail(null)} />

      <CreateDraftModal
        open={createOpen}
        nextNumber={nextNumber ?? (open?.number ?? 0) + 1}
        busy={busy}
        error={actionError}
        onClose={() => setCreateOpen(false)}
        onCreate={(name, note, carry) => {
          void act(() => apiFetch('/admin/seasons/draft', {
            method: 'POST',
            body: JSON.stringify({ name, public_note: note, carry_from_open: carry }),
          })).then((ok) => { if (ok) setCreateOpen(false); });
        }}
      />

      <EditDraftModal
        open={editOpen}
        draft={draft}
        busy={busy}
        error={actionError}
        onClose={() => setEditOpen(false)}
        onSave={(name, note) => {
          if (!draft) return;
          void act(() => apiFetch(`/admin/seasons/draft/${draft.id}`, {
            method: 'PATCH',
            body: JSON.stringify({ name, public_note: note }),
          })).then((ok) => { if (ok) setEditOpen(false); });
        }}
      />

      <ConfirmDialog
        open={confirm.kind === 'delete-draft'}
        title="Delete this draft?"
        body={<p>The draft season and its {draftCount} question rows are removed. The open season is untouched. This cannot be undone.</p>}
        confirmLabel="Delete draft"
        danger
        busy={busy}
        error={actionError}
        onClose={() => setConfirm({ kind: null })}
        onConfirm={() => {
          if (!draft) return;
          void act(() => apiFetch(`/admin/seasons/draft/${draft.id}`, { method: 'DELETE' }))
            .then((ok) => { if (ok) setConfirm({ kind: null }); });
        }}
      />

      <ConfirmDialog
        open={confirm.kind === 'open-season'}
        title={`Open ${draft?.name ?? 'this season'}?`}
        body={
          <div className="space-y-2">
            <p>This is the changeover, in one transaction:</p>
            <ul className="list-disc pl-5">
              <li><b>{open?.name ?? 'The open season'}</b> closes. Its record is sealed.</li>
              <li><b>{draft?.name}</b> opens with {draftCount} questions, renumbered 1–{draftCount}.</li>
              <li>Every pin freezes — wording changes after this point need a new season.</li>
            </ul>
            <p>The board should have signed off on the presentation view before this.</p>
          </div>
        }
        confirmLabel="Open season"
        danger
        busy={busy}
        error={actionError}
        onClose={() => setConfirm({ kind: null })}
        onConfirm={() => {
          if (!draft) return;
          void act(() => apiFetch(`/admin/seasons/draft/${draft.id}/open`, { method: 'POST' }))
            .then((ok) => { if (ok) setConfirm({ kind: null }); });
        }}
      />
    </div>
  );
}
