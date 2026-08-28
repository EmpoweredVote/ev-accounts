import { useMemo } from 'react';
import { diffWords, hasChanged } from '../lib/wordDiff';

/**
 * The rendering half of wordDiff.ts, extracted once it grew a third consumer
 * (TopicRevisionReviewPage, SeasonCompositionPage, ProposeRevisionPage).
 * Reviewers read "what changed" on all three screens; they must mark the same
 * change the same way, so the classes live here and nowhere else.
 *
 * Accessibility: real <ins>/<del> elements, highlight rather than bold, and
 * never color alone (the underline/strikethrough carry the meaning).
 */

export const INS =
  'bg-amber-200/80 text-gray-900 underline decoration-amber-700 decoration-1 ' +
  'underline-offset-2 rounded-sm px-0.5 dark:bg-amber-500/30 dark:text-amber-50 ' +
  'dark:decoration-amber-400';

export const DEL = 'line-through decoration-1 text-gray-500 dark:text-gray-400 px-0.5';

export function InlineDiff({ prev, next }: { prev: string | null; next: string | null }) {
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

export function FieldDiff({ label, prev, next }: {
  label: string;
  prev: string | null;
  next: string | null;
}) {
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
